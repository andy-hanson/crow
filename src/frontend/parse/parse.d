module frontend.parse.parse;

@safe @nogc pure nothrow:

import frontend.parse.lexer :
	addDiagUnexpectedCurToken,
	alloc,
	allSymbols,
	createLexer,
	curPos,
	finishDiagnostics,
	getPeekToken,
	getPeekTokenAndData,
	Lexer,
	lookaheadNewVisibility,
	range,
	skipNewlinesIgnoreIndentation,
	skipUntilNewlineNoDiag,
	takeNextToken,
	Token,
	TokenAndData;
import frontend.parse.parseExpr : parseDestructureRequireParens, parseFunExprBody;
import frontend.parse.parseImport : parseImportsOrExports;
import frontend.parse.parseType : parseType, parseTypeArgForVarDecl, tryParseTypeArgForEnumOrFlags;
import frontend.parse.parseUtil :
	addDiagExpected,
	NewlineOrDedent,
	peekEndOfLine,
	takeDedent,
	takeIndentOrFailGeneric,
	takeName,
	takeNameAndRange,
	takeNameOrOperator,
	takeNewlineOrDedent,
	takeNewline_topLevel,
	takeOrAddDiagExpectedToken,
	tryTakeOperator,
	tryTakeToken;
import model.ast :
	DestructureAst,
	ExprAst,
	FieldMutabilityAst,
	FileAst,
	FunDeclAst,
	ModifierAst,
	ModifierKeyword,
	ImportsOrExportsAst,
	LiteralIntAst,
	LiteralIntOrNat,
	LiteralIntOrNatKind,
	LiteralNatAst,
	ModifierAst,
	NameAndRange,
	ParamsAst,
	SpecBodyAst,
	SpecDeclAst,
	SpecSigAst,
	StructAliasAst,
	StructBodyAst,
	StructDeclAst,
	TestAst,
	TypeAst,
	VarDeclAst;
import model.model : TypeParams, VarKind, Visibility;
import model.parseDiag : ParseDiag;
import util.alloc.alloc : Alloc;
import util.cell : Cell, cellGet, cellSet;
import util.col.array : emptySmallArray, SmallArray;
import util.col.arrayBuilder : add, ArrayBuilder, smallFinish;
import util.memory : allocate;
import util.opt : force, has, none, Opt, some;
import util.perf : Perf, PerfMeasure, withMeasure;
import util.sourceRange : Pos, Range;
import util.string : CString, emptySmallString, SmallString;
import util.symbol : AllSymbols, Symbol, symbol;
import util.uri : AllUris;
import util.util : castNonScope_ref, ptrTrustMe;

FileAst* parseFile(
	scope ref Perf perf,
	ref Alloc alloc,
	scope ref AllSymbols allSymbols,
	scope ref AllUris allUris,
	scope CString source,
) =>
	withMeasure!(FileAst*, () {
		Lexer lexer = createLexer(ptrTrustMe(alloc), ptrTrustMe(allSymbols), castNonScope_ref(source));
		return parseFileInner(allUris, lexer);
	})(perf, alloc, PerfMeasure.parseFile);

private:

TypeParams parseTypeParams(ref Lexer lexer) {
	if (tryTakeToken(lexer, Token.bracketLeft)) {
		ArrayBuilder!NameAndRange res;
		do {
			add(lexer.alloc, res, takeNameAndRange(lexer));
		} while (tryTakeToken(lexer, Token.comma));
		takeOrAddDiagExpectedToken(lexer, Token.bracketRight, ParseDiag.Expected.Kind.closingBracket);
		return smallFinish(lexer.alloc, res);
	} else
		return emptySmallArray!NameAndRange;
}

ParamsAst parseParams(ref Lexer lexer, bool indentLevel) {
	if (!takeOrAddDiagExpectedToken(lexer, Token.parenLeft, ParseDiag.Expected.Kind.openParen)) {
		skipUntilNewlineNoDiag(lexer);
		return ParamsAst([]);
	} else if (tryTakeToken(lexer, Token.parenRight))
		return ParamsAst(emptySmallArray!DestructureAst);
	else if (tryTakeToken(lexer, Token.dot3)) {
		DestructureAst param = parseDestructureRequireParens(lexer);
		takeOrAddDiagExpectedToken(lexer, Token.parenRight, ParseDiag.Expected.Kind.closingParen);
		return ParamsAst(allocate(lexer.alloc, ParamsAst.Varargs(param)));
	} else {
		ArrayBuilder!DestructureAst res;
		for (;;) {
			skipNewlinesIgnoreIndentation(lexer, indentLevel);
			add(lexer.alloc, res, parseDestructureRequireParens(lexer));
			if (tryTakeToken(lexer, Token.parenRight))
				break;
			if (!takeOrAddDiagExpectedToken(lexer, Token.comma, ParseDiag.Expected.Kind.comma)) {
				skipUntilNewlineNoDiag(lexer);
				break;
			}
			// allow trailing comma
			skipNewlinesIgnoreIndentation(lexer, indentLevel);
			if (tryTakeToken(lexer, Token.parenRight))
				break;
		}
		return ParamsAst(smallFinish(lexer.alloc, res));
	}
}

SpecSigAst parseSpecSig(ref Lexer lexer) {
	// TODO: get doc comment
	SmallString docComment = emptySmallString;
	Pos start = curPos(lexer);
	NameAndRange name = takeNameOrOperator(lexer);
	assert(name.start == start);
	TypeAst returnType = parseType(lexer);
	ParamsAst params = parseParams(lexer, 1);
	return SpecSigAst(docComment, range(lexer, start), name.name, returnType, params);
}

SmallArray!SpecSigAst parseIndentedSigs(ref Lexer lexer) {
	if (tryTakeToken(lexer, Token.newlineIndent)) {
		ArrayBuilder!SpecSigAst res;
		while (true) {
			SpecSigAst sig = parseSpecSig(lexer);
			add(lexer.alloc, res, sig);
			final switch (takeNewlineOrDedent(lexer)) {
				case NewlineOrDedent.newline:
					continue;
				case NewlineOrDedent.dedent:
					return smallFinish(lexer.alloc, res);
			}
		}
	} else
		return emptySmallArray!SpecSigAst;
}

SmallArray!(StructBodyAst.Enum.Member) parseEnumOrFlagsMembers(ref Lexer lexer) {
	if (tryTakeToken(lexer, Token.newlineIndent)) {
		ArrayBuilder!(StructBodyAst.Enum.Member) res;
		SmallArray!(StructBodyAst.Enum.Member) recur() {
			Pos start = curPos(lexer);
			Symbol name = takeName(lexer);
			Opt!LiteralIntOrNat value = () {
				if (tryTakeToken(lexer, Token.equal)) {
					Pos start = curPos(lexer);
					switch (getPeekToken(lexer)) {
						case Token.literalInt:
							LiteralIntAst literal = takeNextToken(lexer).asLiteralInt;
							return some(LiteralIntOrNat(range(lexer, start), LiteralIntOrNatKind(literal)));
						case Token.literalNat:
							LiteralNatAst literal = takeNextToken(lexer).asLiteralNat;
							return some(LiteralIntOrNat(range(lexer, start), LiteralIntOrNatKind(literal)));
						default:
							addDiagExpected(lexer, ParseDiag.Expected.Kind.literalIntOrNat);
							return none!LiteralIntOrNat;
					}
				} else
					return none!LiteralIntOrNat;
			}();
			add(lexer.alloc, res, StructBodyAst.Enum.Member(range(lexer, start), name, value));
			final switch (takeNewlineOrDedent(lexer)) {
				case NewlineOrDedent.newline:
					return recur();
				case NewlineOrDedent.dedent:
					return smallFinish(lexer.alloc, res);
			}
		}
		return recur();
	} else
		return emptySmallArray!(StructBodyAst.Enum.Member);
}

StructBodyAst.Record parseRecordBody(ref Lexer lexer) =>
	StructBodyAst.Record(tryTakeToken(lexer, Token.newlineIndent)
		? parseRecordFields(lexer)
		: emptySmallArray!(StructBodyAst.Record.Field));

SmallArray!(StructBodyAst.Record.Field) parseRecordFields(ref Lexer lexer) {
	ArrayBuilder!(StructBodyAst.Record.Field) fields;
	while (true) {
		Pos start = curPos(lexer);
		Opt!Visibility visibility = tryTakeVisibility(lexer);
		NameAndRange name = takeNameAndRange(lexer);
		Opt!FieldMutabilityAst mutability = parseFieldMutability(lexer);
		TypeAst type = parseType(lexer);
		add(lexer.alloc, fields, StructBodyAst.Record.Field(
			range(lexer, start), visibility, name, mutability, type));
		final switch (takeNewlineOrDedent(lexer)) {
			case NewlineOrDedent.newline:
				continue;
			case NewlineOrDedent.dedent:
				return smallFinish(lexer.alloc, fields);
		}
	}
}

Opt!FieldMutabilityAst parseFieldMutability(ref Lexer lexer) {
	Pos pos = curPos(lexer);
	TokenAndData peek = getPeekTokenAndData(lexer);
	Opt!Visibility visibility = tryTakeVisibility(lexer);
	if (tryTakeToken(lexer, Token.mut))
		return some(FieldMutabilityAst(pos, visibility));
	else {
		if (has(visibility))
			addDiagUnexpectedCurToken(lexer, pos, peek);
		return none!FieldMutabilityAst;
	}
}

SmallArray!(StructBodyAst.Union.Member) parseUnionMembers(ref Lexer lexer) {
	if (!tryTakeToken(lexer, Token.newlineIndent))
		return emptySmallArray!(StructBodyAst.Union.Member);

	ArrayBuilder!(StructBodyAst.Union.Member) res;
	do {
		Pos start = curPos(lexer);
		Symbol name = takeName(lexer);
		Opt!TypeAst type = peekEndOfLine(lexer) ? none!TypeAst : some(parseType(lexer));
		add(lexer.alloc, res, StructBodyAst.Union.Member(range(lexer, start), name, type));
	} while (takeNewlineOrDedent(lexer) == NewlineOrDedent.newline);
	return smallFinish(lexer.alloc, res);
}

FunDeclAst parseFun(
	ref Lexer lexer,
	SmallString docComment,
	Opt!Visibility visibility,
	Pos start,
	NameAndRange name,
	TypeParams typeParams,
) {
	TypeAst returnType = parseType(lexer);
	ParamsAst params = parseParams(lexer, 0);
	SmallArray!ModifierAst modifiers = parseModifiers(lexer);
	ExprAst body_ = parseFunExprBody(lexer);
	return FunDeclAst(
		range(lexer, start), docComment, visibility, name, typeParams, returnType, params, modifiers, body_);
}

SmallArray!ModifierAst parseModifiers(ref Lexer lexer) {
	if (peekEndOfLine(lexer))
		return emptySmallArray!ModifierAst;
	else {
		ArrayBuilder!ModifierAst res;
		do {
			add(lexer.alloc, res, parseModifier(lexer));
		} while (tryTakeToken(lexer, Token.comma));
		return smallFinish(lexer.alloc, res);
	}
}

ModifierAst parseModifier(ref Lexer lexer) {
	Pos start = curPos(lexer);
	Opt!(ModifierKeyword) keyword = tryGetKeywordModifier(getPeekTokenAndData(lexer));
	if (has(keyword)) {
		takeNextToken(lexer);
		return ModifierAst(ModifierAst.Keyword(start, force(keyword)));
	} else {
		if (lookaheadNewVisibility(lexer)) {
			Opt!Visibility opt = tryTakeVisibility(lexer);
			Visibility visibility = force(opt);
			Symbol name = takeName(lexer);
			assert(name == symbol!"new");
			return ModifierAst(ModifierAst.Keyword(start, newVisibility(visibility)));
		} else {
			TypeAst type = parseType(lexer);
			Pos externPos = curPos(lexer);
			return tryTakeToken(lexer, Token.extern_)
				? ModifierAst(ModifierAst.Extern(allocate(lexer.alloc, type), externPos))
				: ModifierAst(type);
		}
	}
}

ModifierKeyword newVisibility(Visibility a) {
	final switch (a) {
		case Visibility.private_:
			return ModifierKeyword.newPrivate;
		case Visibility.internal:
			return ModifierKeyword.newInternal;
		case Visibility.public_:
			return ModifierKeyword.newPublic;
	}
}

SmallArray!TypeAst parseSpecModifiers(ref Lexer lexer) {
	if (peekEndOfLine(lexer))
		return emptySmallArray!TypeAst;
	else {
		ArrayBuilder!TypeAst res;
		add(lexer.alloc, res, parseType(lexer));
		while (tryTakeToken(lexer, Token.comma))
			add(lexer.alloc, res, parseType(lexer));
		return smallFinish(lexer.alloc, res);
	}
}

Opt!ModifierKeyword tryGetKeywordModifier(TokenAndData token) {
	switch (token.token) {
		case Token.bare:
			return some(ModifierKeyword.bare);
		case Token.builtin:
			return some(ModifierKeyword.builtin);
		case Token.extern_:
			return some(ModifierKeyword.extern_);
		case Token.forceCtx:
			return some(ModifierKeyword.forceCtx);
		case Token.mut:
			return some(ModifierKeyword.mut);
		case Token.name:
			Symbol name = token.asSymbol;
			switch (name.value) {
				case symbol!"by-ref".value:
					return some(ModifierKeyword.byRef);
				case symbol!"by-val".value:
					return some(ModifierKeyword.byVal);
				case symbol!"data".value:
					return some(ModifierKeyword.data);
				case symbol!"force-shared".value:
					return some(ModifierKeyword.forceShared);
				case symbol!"packed".value:
					return some(ModifierKeyword.packed);
				case symbol!"shared".value:
					return some(ModifierKeyword.shared_);
				default:
					return none!(ModifierKeyword);
			}
		case Token.summon:
			return some(ModifierKeyword.summon);
		case Token.trusted:
			return some(ModifierKeyword.trusted);
		case Token.unsafe:
			return some(ModifierKeyword.unsafe);
		default:
			return none!(ModifierKeyword);
	}
}


void parseSpecOrStructOrFunOrTest(
	ref Lexer lexer,
	scope ref ArrayBuilder!SpecDeclAst specs,
	scope ref ArrayBuilder!StructAliasAst structAliases,
	scope ref ArrayBuilder!StructDeclAst structs,
	scope ref ArrayBuilder!FunDeclAst funs,
	scope ref ArrayBuilder!TestAst tests,
	scope ref ArrayBuilder!VarDeclAst vars,
	SmallString docComment,
) {
	Pos start = curPos(lexer);
	if (tryTakeToken(lexer, Token.test)) {
		ExprAst body_ = parseFunExprBody(lexer);
		add(lexer.alloc, tests, TestAst(range(lexer, start), body_));
	} else
		parseSpecOrStructOrFun(lexer, specs, structAliases, structs, funs, vars, docComment);
}

void parseSpecOrStructOrFun(
	ref Lexer lexer,
	scope ref ArrayBuilder!SpecDeclAst specs,
	scope ref ArrayBuilder!StructAliasAst structAliases,
	scope ref ArrayBuilder!StructDeclAst structs,
	scope ref ArrayBuilder!FunDeclAst funs,
	scope ref ArrayBuilder!VarDeclAst varDecls,
	SmallString docComment,
) {
	Pos start = curPos(lexer);
	Opt!Visibility visibility = tryTakeVisibility(lexer);
	NameAndRange name = takeNameOrOperator(lexer);
	TypeParams typeParams = parseTypeParams(lexer);
	Pos keywordPos = curPos(lexer);

	void addStruct(in StructBodyAst delegate() @safe @nogc pure nothrow cb) {
		SmallArray!ModifierAst modifiers = parseModifiers(lexer);
		StructBodyAst body_ = cb();
		add(lexer.alloc, structs, StructDeclAst(
			docComment, range(lexer, start), visibility, name, typeParams, keywordPos, modifiers, body_));
	}

	switch (getPeekToken(lexer)) {
		case Token.alias_:
			takeNextToken(lexer);
			TypeAst target = takeIndentOrFailGeneric!TypeAst(lexer,
				() {
					TypeAst res = parseType(lexer);
					takeDedent(lexer);
					return res;
				},
				(in Range range) => TypeAst(TypeAst.Bogus(range)));
			add(lexer.alloc, structAliases, StructAliasAst(
				docComment, range(lexer, start), visibility, name, typeParams, keywordPos, target));
			break;
		case Token.builtin:
			takeNextToken(lexer);
			addStruct(() => StructBodyAst(StructBodyAst.Builtin()));
			break;
		case Token.builtinSpec:
			takeNextToken(lexer);
			add(lexer.alloc, specs, SpecDeclAst(
				range(lexer, start),
				docComment,
				visibility,
				name,
				typeParams,
				keywordPos,
				emptySmallArray!TypeAst,
				SpecBodyAst(SpecBodyAst.Builtin())));
			break;
		case Token.enum_:
			takeNextToken(lexer);
			Opt!(TypeAst*) typeArg = tryParseTypeArgForEnumOrFlags(lexer);
			addStruct(() => StructBodyAst(StructBodyAst.Enum(typeArg, parseEnumOrFlagsMembers(lexer))));
			break;
		case Token.extern_:
			takeNextToken(lexer);
			StructBodyAst.Extern body_ = parseExternType(lexer);
			addStruct(() => StructBodyAst(body_));
			break;
		case Token.flags:
			takeNextToken(lexer);
			Opt!(TypeAst*) typeArg = tryParseTypeArgForEnumOrFlags(lexer);
			addStruct(() => StructBodyAst(StructBodyAst.Flags(typeArg, parseEnumOrFlagsMembers(lexer))));
			break;
		case Token.global:
			Pos pos = curPos(lexer);
			takeNextToken(lexer);
			add(lexer.alloc, varDecls, parseVarDecl(
				lexer, start, docComment, visibility, name, typeParams, pos, VarKind.global));
			break;
		case Token.record:
			takeNextToken(lexer);
			addStruct(() => StructBodyAst(parseRecordBody(lexer)));
			break;
		case Token.spec:
			takeNextToken(lexer);
			SmallArray!TypeAst parents = parseSpecModifiers(lexer);
			SpecBodyAst body_ = SpecBodyAst(parseIndentedSigs(lexer));
			add(lexer.alloc, specs, SpecDeclAst(
				range(lexer, start), docComment, visibility, name, typeParams, keywordPos, parents, body_));
			break;
		case Token.thread_local:
			Pos pos = curPos(lexer);
			takeNextToken(lexer);
			add(lexer.alloc, varDecls, parseVarDecl(
				lexer, start, docComment, visibility, name, typeParams, pos, VarKind.threadLocal));
			break;
		case Token.union_:
			takeNextToken(lexer);
			addStruct(() => StructBodyAst(StructBodyAst.Union(parseUnionMembers(lexer))));
			break;
		default:
			add(lexer.alloc, funs, parseFun(lexer, docComment, visibility, start, name, typeParams));
			break;
	}
}

StructBodyAst.Extern parseExternType(ref Lexer lexer) {
	if (tryTakeToken(lexer, Token.parenLeft)) {
		Opt!(LiteralNatAst*) size = parseNat(lexer);
		Opt!(LiteralNatAst*) alignment = tryTakeToken(lexer, Token.comma)
			? parseNat(lexer)
			: none!(LiteralNatAst*);
		takeOrAddDiagExpectedToken(lexer, Token.parenRight, ParseDiag.Expected.Kind.closingParen);
		return StructBodyAst.Extern(size, alignment);
	} else
		return StructBodyAst.Extern(none!(LiteralNatAst*), none!(LiteralNatAst*));
}
Opt!(LiteralNatAst*) parseNat(ref Lexer lexer) =>
	takeOrAddDiagExpectedToken!(LiteralNatAst*)(lexer, ParseDiag.Expected.Kind.literalNat, (TokenAndData x) =>
		x.token == Token.literalNat ? some(allocate(lexer.alloc, x.asLiteralNat())) : none!(LiteralNatAst*));

VarDeclAst parseVarDecl(
	ref Lexer lexer,
	Pos start,
	SmallString docComment,
	Opt!Visibility visibility,
	NameAndRange name,
	SmallArray!NameAndRange typeParams,
	Pos kindPos,
	VarKind kind,
) {
	TypeAst type = parseTypeArgForVarDecl(lexer);
	SmallArray!ModifierAst modifiers = parseModifiers(lexer);
	return VarDeclAst(range(lexer, start), docComment, visibility, name, typeParams, kindPos, kind, type, modifiers);
}

Opt!Visibility tryTakeVisibility(ref Lexer lexer) =>
	tryTakeOperator(lexer, symbol!"-")
		? some(Visibility.private_)
		: tryTakeOperator(lexer, symbol!"+")
		? some(Visibility.public_)
		: tryTakeOperator(lexer, symbol!"~")
		? some(Visibility.internal)
		: none!Visibility;

FileAst* parseFileInner(scope ref AllUris allUris, ref Lexer lexer) {
	SmallString moduleDocComment = takeNewline_topLevel(lexer);
	Cell!(Opt!SmallString) firstDocComment = Cell!(Opt!SmallString)(some(emptySmallString));
	bool noStd = tryTakeToken(lexer, Token.noStd);
	if (noStd)
		cellSet(firstDocComment, some(takeNewline_topLevel(lexer)));
	Opt!ImportsOrExportsAst imports = parseImportsOrExports(allUris, lexer, Token.import_);
	if (has(imports))
		cellSet(firstDocComment, some(takeNewline_topLevel(lexer)));
	Opt!ImportsOrExportsAst exports = parseImportsOrExports(allUris, lexer, Token.export_);
	if (has(exports))
		cellSet(firstDocComment, some(takeNewline_topLevel(lexer)));

	ArrayBuilder!SpecDeclAst specs;
	ArrayBuilder!StructAliasAst structAliases;
	ArrayBuilder!StructDeclAst structs;
	ArrayBuilder!FunDeclAst funs;
	ArrayBuilder!TestAst tests;
	ArrayBuilder!VarDeclAst vars;

	while (!tryTakeToken(lexer, Token.EOF)) {
		SmallString docComment = () {
			if (has(cellGet(firstDocComment))) {
				SmallString res = force(cellGet(firstDocComment));
				cellSet(firstDocComment, none!SmallString);
				return res;
			} else
				return takeNewline_topLevel(lexer);
		}();
		if (tryTakeToken(lexer, Token.EOF))
			break;
		parseSpecOrStructOrFunOrTest(lexer, specs, structAliases, structs, funs, tests, vars, docComment);
	}

	return allocate(lexer.alloc, FileAst(
		finishDiagnostics(lexer),
		moduleDocComment,
		noStd,
		imports,
		exports,
		smallFinish(lexer.alloc, specs),
		smallFinish(lexer.alloc, structAliases),
		smallFinish(lexer.alloc, structs),
		smallFinish(lexer.alloc, funs),
		smallFinish(lexer.alloc, tests),
		smallFinish(lexer.alloc, vars)));
}
