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
	range,
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
	skipNewlinesIgnoreIndentation,
	takeDedent,
	takeIndentOrFailGeneric,
	takeName,
	takeNameAndRange,
	takeNameOrOperator,
	takeNewlineOrDedent,
	takeNewline_topLevel,
	takeOrAddDiagExpectedToken,
	tryTakeName,
	tryTakeOperator,
	tryTakeToken;
import model.ast :
	DestructureAst,
	ExplicitVisibility,
	ExprAst,
	FieldMutabilityAst,
	FileAst,
	FunDeclAst,
	FunModifierAst,
	ImportsOrExportsAst,
	LiteralIntOrNat,
	LiteralNatAst,
	ModifierAst,
	NameAndRange,
	ParamsAst,
	SpecBodyAst,
	SpecDeclAst,
	SpecSigAst,
	StructAliasAst,
	StructDeclAst,
	TestAst,
	TypeAst,
	VarDeclAst;
import model.model : TypeParams, VarKind;
import model.parseDiag : ParseDiag;
import util.alloc.alloc : Alloc;
import util.cell : Cell, cellGet, cellSet;
import util.col.array : emptySmallArray, small, SmallArray;
import util.col.arrayBuilder : add, ArrayBuilder, finish;
import util.memory : allocate;
import util.opt : force, has, none, Opt, some;
import util.perf : Perf, PerfMeasure, withMeasure;
import util.sourceRange : Pos, Range;
import util.string : CString, cString;
import util.symbol : AllSymbols, Symbol, symbol;
import util.uri : AllUris;
import util.util : castNonScope_ref, ptrTrustMe, typeAs;

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
		return small!NameAndRange(finish(lexer.alloc, res));
	} else
		return emptySmallArray!NameAndRange;
}

ParamsAst parseParams(ref Lexer lexer) {
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
			skipNewlinesIgnoreIndentation(lexer);
			add(lexer.alloc, res, parseDestructureRequireParens(lexer));
			if (tryTakeToken(lexer, Token.parenRight))
				break;
			if (!takeOrAddDiagExpectedToken(lexer, Token.comma, ParseDiag.Expected.Kind.comma)) {
				skipUntilNewlineNoDiag(lexer);
				break;
			}
			// allow trailing comma
			skipNewlinesIgnoreIndentation(lexer);
			if (tryTakeToken(lexer, Token.parenRight))
				break;
		}
		return ParamsAst(finish(lexer.alloc, res));
	}
}

SpecSigAst parseSpecSig(ref Lexer lexer) {
	// TODO: get doc comment
	CString comment = cString!"";
	Pos start = curPos(lexer);
	NameAndRange name = takeNameOrOperator(lexer);
	assert(name.start == start);
	TypeAst returnType = parseType(lexer);
	ParamsAst params = parseParams(lexer);
	return SpecSigAst(comment, range(lexer, start), name.name, returnType, params);
}

SpecSigAst[] parseIndentedSigs(ref Lexer lexer) {
	if (tryTakeToken(lexer, Token.newlineIndent)) {
		ArrayBuilder!SpecSigAst res;
		while (true) {
			SpecSigAst sig = parseSpecSig(lexer);
			add(lexer.alloc, res, sig);
			final switch (takeNewlineOrDedent(lexer)) {
				case NewlineOrDedent.newline:
					continue;
				case NewlineOrDedent.dedent:
					return finish(lexer.alloc, res);
			}
		}
	} else
		return [];
}

SmallArray!(StructDeclAst.Body.Enum.Member) parseEnumOrFlagsMembers(ref Lexer lexer) {
	if (tryTakeToken(lexer, Token.newlineIndent)) {
		ArrayBuilder!(StructDeclAst.Body.Enum.Member) res;
		SmallArray!(StructDeclAst.Body.Enum.Member) recur() {
			Pos start = curPos(lexer);
			Symbol name = takeName(lexer);
			Opt!LiteralIntOrNat value = () {
				if (tryTakeToken(lexer, Token.equal)) {
					switch (getPeekToken(lexer)) {
						case Token.literalInt:
							return some(LiteralIntOrNat(takeNextToken(lexer).asLiteralInt()));
						case Token.literalNat:
							return some(LiteralIntOrNat(takeNextToken(lexer).asLiteralNat()));
						default:
							addDiagExpected(lexer, ParseDiag.Expected.Kind.literalIntOrNat);
							return none!LiteralIntOrNat;
					}
				} else
					return none!LiteralIntOrNat;
			}();
			add(lexer.alloc, res, StructDeclAst.Body.Enum.Member(range(lexer, start), name, value));
			final switch (takeNewlineOrDedent(lexer)) {
				case NewlineOrDedent.newline:
					return recur();
				case NewlineOrDedent.dedent:
					return small!(StructDeclAst.Body.Enum.Member)(finish(lexer.alloc, res));
			}
		}
		return recur();
	} else
		return emptySmallArray!(StructDeclAst.Body.Enum.Member);
}

StructDeclAst.Body.Record parseRecordBody(ref Lexer lexer) =>
	StructDeclAst.Body.Record(tryTakeToken(lexer, Token.newlineIndent)
		? small!(StructDeclAst.Body.Record.Field)(parseRecordFields(lexer))
		: emptySmallArray!(StructDeclAst.Body.Record.Field));

StructDeclAst.Body.Record.Field[] parseRecordFields(ref Lexer lexer) {
	ArrayBuilder!(StructDeclAst.Body.Record.Field) fields;
	while (true) {
		Pos start = curPos(lexer);
		ExplicitVisibility visibility = tryTakeVisibility(lexer);
		NameAndRange name = takeNameAndRange(lexer);
		Opt!FieldMutabilityAst mutability = parseFieldMutability(lexer);
		TypeAst type = parseType(lexer);
		add(lexer.alloc, fields, StructDeclAst.Body.Record.Field(
			range(lexer, start), visibility, name, mutability, type));
		final switch (takeNewlineOrDedent(lexer)) {
			case NewlineOrDedent.newline:
				continue;
			case NewlineOrDedent.dedent:
				return finish(lexer.alloc, fields);
		}
	}
}

Opt!FieldMutabilityAst parseFieldMutability(ref Lexer lexer) {
	Pos pos = curPos(lexer);
	TokenAndData peek = getPeekTokenAndData(lexer);
	if (tryTakeOperator(lexer, symbol!"-")) {
		if (tryTakeToken(lexer, Token.mut))
			return some(FieldMutabilityAst(pos, FieldMutabilityAst.Kind.private_));
		else {
			addDiagUnexpectedCurToken(lexer, curPos(lexer) - 1, peek);
			return none!FieldMutabilityAst;
		}
	} else
		return tryTakeToken(lexer, Token.mut)
			? some(FieldMutabilityAst(pos, FieldMutabilityAst.Kind.public_))
			: none!FieldMutabilityAst;
}

StructDeclAst.Body.Union.Member[] parseUnionMembers(ref Lexer lexer) {
	ArrayBuilder!(StructDeclAst.Body.Union.Member) res;
	do {
		Pos start = curPos(lexer);
		Symbol name = takeName(lexer);
		Opt!TypeAst type = peekEndOfLine(lexer) ? none!TypeAst : some(parseType(lexer));
		add(lexer.alloc, res, StructDeclAst.Body.Union.Member(range(lexer, start), name, type));
	} while (takeNewlineOrDedent(lexer) == NewlineOrDedent.newline);
	return finish(lexer.alloc, res);
}

FunDeclAst parseFun(
	ref Lexer lexer,
	CString docComment,
	ExplicitVisibility visibility,
	Pos start,
	NameAndRange name,
	NameAndRange[] typeParams,
) {
	TypeAst returnType = parseType(lexer);
	ParamsAst params = parseParams(lexer);
	FunModifierAst[] modifiers = parseFunModifiers(lexer);
	Opt!ExprAst body_ = parseFunExprBody(lexer);
	return FunDeclAst(
		range(lexer, start),
		docComment,
		visibility,
		name,
		small!NameAndRange(typeParams),
		returnType,
		params,
		small!FunModifierAst(modifiers),
		body_);
}

FunModifierAst[] parseFunModifiers(ref Lexer lexer) {
	if (peekEndOfLine(lexer))
		return [];
	else {
		ArrayBuilder!FunModifierAst res;
		add(lexer.alloc, res, parseFunModifier(lexer));
		while (tryTakeToken(lexer, Token.comma))
			add(lexer.alloc, res, parseFunModifier(lexer));
		return finish(lexer.alloc, res);
	}
}

FunModifierAst parseFunModifier(ref Lexer lexer) {
	Pos start = curPos(lexer);
	Opt!(FunModifierAst.Special.Flags) special = tryGetSpecialFunModifier(getPeekToken(lexer));
	if (has(special)) {
		takeNextToken(lexer);
		return FunModifierAst(FunModifierAst.Special(start, force(special)));
	} else {
		TypeAst type = parseType(lexer);
		Pos externPos = curPos(lexer);
		return tryTakeToken(lexer, Token.extern_)
			? FunModifierAst(FunModifierAst.Extern(allocate(lexer.alloc, type), externPos))
			: FunModifierAst(type);
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
		return small!TypeAst(finish(lexer.alloc, res));
	}
}

Opt!(FunModifierAst.Special.Flags) tryGetSpecialFunModifier(Token token) {
	switch (token) {
		case Token.bare:
			return some(FunModifierAst.Special.Flags.bare);
		case Token.builtin:
			return some(FunModifierAst.Special.Flags.builtin);
		case Token.extern_:
			return some(FunModifierAst.Special.Flags.extern_);
		case Token.forceCtx:
			return some(FunModifierAst.Special.Flags.forceCtx);
		case Token.summon:
			return some(FunModifierAst.Special.Flags.summon);
		case Token.trusted:
			return some(FunModifierAst.Special.Flags.trusted);
		case Token.unsafe:
			return some(FunModifierAst.Special.Flags.unsafe);
		default:
			return none!(FunModifierAst.Special.Flags);
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
	CString docComment,
) {
	if (tryTakeToken(lexer, Token.test))
		add(lexer.alloc, tests, TestAst(parseFunExprBody(lexer)));
	else
		parseSpecOrStructOrFun(lexer, specs, structAliases, structs, funs, vars, docComment);
}

void parseSpecOrStructOrFun(
	ref Lexer lexer,
	scope ref ArrayBuilder!SpecDeclAst specs,
	scope ref ArrayBuilder!StructAliasAst structAliases,
	scope ref ArrayBuilder!StructDeclAst structs,
	scope ref ArrayBuilder!FunDeclAst funs,
	scope ref ArrayBuilder!VarDeclAst varDecls,
	CString docComment,
) {
	Pos start = curPos(lexer);
	ExplicitVisibility visibility = tryTakeVisibility(lexer);
	NameAndRange name = takeNameOrOperator(lexer);
	TypeParams typeParams = parseTypeParams(lexer);
	Pos keywordPos = curPos(lexer);

	void addStruct(in StructDeclAst.Body delegate() @safe @nogc pure nothrow cb) {
		SmallArray!ModifierAst modifiers = parseModifiers(lexer);
		StructDeclAst.Body body_ = cb();
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
				docComment, range(lexer, start), visibility, name, small!NameAndRange(typeParams), target));
			break;
		case Token.builtin:
			takeNextToken(lexer);
			addStruct(() => StructDeclAst.Body(StructDeclAst.Body.Builtin()));
			break;
		case Token.builtinSpec:
			takeNextToken(lexer);
			add(lexer.alloc, specs, SpecDeclAst(
				range(lexer, start),
				docComment,
				visibility,
				name,
				small!NameAndRange(typeParams),
				emptySmallArray!TypeAst,
				SpecBodyAst(SpecBodyAst.Builtin())));
			break;
		case Token.enum_:
			takeNextToken(lexer);
			Opt!(TypeAst*) typeArg = tryParseTypeArgForEnumOrFlags(lexer);
			addStruct(() => StructDeclAst.Body(StructDeclAst.Body.Enum(typeArg, parseEnumOrFlagsMembers(lexer))));
			break;
		case Token.extern_:
			takeNextToken(lexer);
			StructDeclAst.Body.Extern body_ = parseExternType(lexer);
			addStruct(() => StructDeclAst.Body(body_));
			break;
		case Token.flags:
			takeNextToken(lexer);
			Opt!(TypeAst*) typeArg = tryParseTypeArgForEnumOrFlags(lexer);
			addStruct(() => StructDeclAst.Body(StructDeclAst.Body.Flags(typeArg, parseEnumOrFlagsMembers(lexer))));
			break;
		case Token.global:
			Pos pos = curPos(lexer);
			takeNextToken(lexer);
			add(lexer.alloc, varDecls, parseVarDecl(
				lexer, start, docComment, visibility, name, typeParams, pos, VarKind.global));
			break;
		case Token.record:
			takeNextToken(lexer);
			addStruct(() => StructDeclAst.Body(parseRecordBody(lexer)));
			break;
		case Token.spec:
			takeNextToken(lexer);
			SmallArray!TypeAst parents = parseSpecModifiers(lexer);
			SpecBodyAst body_ = SpecBodyAst(parseIndentedSigs(lexer));
			add(lexer.alloc, specs, SpecDeclAst(
				range(lexer, start), docComment, visibility, name, typeParams, parents, body_));
			break;
		case Token.thread_local:
			Pos pos = curPos(lexer);
			takeNextToken(lexer);
			add(lexer.alloc, varDecls, parseVarDecl(
				lexer, start, docComment, visibility, name, typeParams, pos, VarKind.threadLocal));
			break;
		case Token.union_:
			takeNextToken(lexer);
			addStruct(() => StructDeclAst.Body(StructDeclAst.Body.Union(parseUnionMembersOrDiag(lexer))));
			break;
		default:
			add(lexer.alloc, funs, parseFun(lexer, docComment, visibility, start, name, typeParams));
			break;
	}
}

StructDeclAst.Body.Extern parseExternType(ref Lexer lexer) {
	if (tryTakeToken(lexer, Token.parenLeft)) {
		Opt!(LiteralNatAst*) size = parseNat(lexer);
		Opt!(LiteralNatAst*) alignment = tryTakeToken(lexer, Token.comma)
			? parseNat(lexer)
			: none!(LiteralNatAst*);
		takeOrAddDiagExpectedToken(lexer, Token.parenRight, ParseDiag.Expected.Kind.closingParen);
		return StructDeclAst.Body.Extern(size, alignment);
	} else
		return StructDeclAst.Body.Extern(none!(LiteralNatAst*), none!(LiteralNatAst*));
}
Opt!(LiteralNatAst*) parseNat(ref Lexer lexer) =>
	takeOrAddDiagExpectedToken!(LiteralNatAst*)(lexer, ParseDiag.Expected.Kind.literalNat, (TokenAndData x) =>
		x.token == Token.literalNat ? some(allocate(lexer.alloc, x.asLiteralNat())) : none!(LiteralNatAst*));

VarDeclAst parseVarDecl(
	ref Lexer lexer,
	Pos start,
	CString docComment,
	ExplicitVisibility visibility,
	NameAndRange name,
	NameAndRange[] typeParams,
	Pos kindPos,
	VarKind kind,
) {
	TypeAst type = parseTypeArgForVarDecl(lexer);
	FunModifierAst[] modifiers = parseFunModifiers(lexer);
	return VarDeclAst(range(lexer, start), docComment, visibility, name, typeParams, kindPos, kind, type, modifiers);
}

StructDeclAst.Body.Union.Member[] parseUnionMembersOrDiag(ref Lexer lexer) =>
	// TODO: This should be a checker error, not a parse error
	takeIndentOrFailGeneric!(StructDeclAst.Body.Union.Member[])(
		lexer,
		() => parseUnionMembers(lexer),
		(in Range _) => typeAs!(StructDeclAst.Body.Union.Member[])([]));

ModifierAst[] parseModifiers(ref Lexer lexer) {
	if (peekEndOfLine(lexer)) return [];
	ArrayBuilder!ModifierAst res;
	while (true) {
		Pos start = curPos(lexer);
		ModifierAst.Kind kind = parseModifierKind(lexer);
		add(lexer.alloc, res, ModifierAst(start, kind));
		if (peekEndOfLine(lexer))
			break;
		else
			takeOrAddDiagExpectedToken(lexer, Token.comma, ParseDiag.Expected.Kind.comma);
	}
	return finish(lexer.alloc, res);
}

ModifierAst.Kind parseModifierKind(ref Lexer lexer) {
	ModifierAst.Kind fail() {
		addDiagExpected(lexer, ParseDiag.Expected.Kind.modifier);
		return ModifierAst.Kind.data;
	}

	TokenAndData token = takeNextToken(lexer);
	switch (token.token) {
		case Token.extern_:
			return ModifierAst.Kind.extern_;
		case Token.mut:
			return ModifierAst.Kind.mut;
		case Token.name:
			Opt!(ModifierAst.Kind) kind = modifierKindFromSymbol(token.asSymbol);
			return has(kind) ? force(kind) : fail();
		case Token.operator:
			switch (token.asSymbol.value) {
				case symbol!"-".value:
					Opt!Symbol name = tryTakeName(lexer);
					return has(name) && force(name) == symbol!"new" ? ModifierAst.Kind.newPrivate : fail();
				case symbol!"+".value:
					Opt!Symbol name = tryTakeName(lexer);
					return has(name) && force(name) == symbol!"new" ? ModifierAst.Kind.newPublic : fail();
				default:
					return fail();
			}
		default:
			return fail();
	}
}

Opt!(ModifierAst.Kind) modifierKindFromSymbol(Symbol a) {
	switch (a.value) {
		case symbol!"by-val".value:
			return some(ModifierAst.Kind.byVal);
		case symbol!"by-ref".value:
			return some(ModifierAst.Kind.byRef);
		case symbol!"data".value:
			return some(ModifierAst.Kind.data);
		case symbol!"force-shared".value:
			return some(ModifierAst.Kind.forceShared);
		case symbol!"packed".value:
			return some(ModifierAst.Kind.packed);
		case symbol!"shared".value:
			return some(ModifierAst.Kind.shared_);
		default:
			return none!(ModifierAst.Kind);
	}
}

ExplicitVisibility tryTakeVisibility(ref Lexer lexer) =>
	tryTakeOperator(lexer, symbol!"-")
		? ExplicitVisibility.private_
		: tryTakeOperator(lexer, symbol!"+")
		? ExplicitVisibility.public_
		: tryTakeOperator(lexer, symbol!"~")
		? ExplicitVisibility.internal
		: ExplicitVisibility.default_;

FileAst* parseFileInner(scope ref AllUris allUris, ref Lexer lexer) {
	CString moduleDocComment = takeNewline_topLevel(lexer);
	Cell!(Opt!CString) firstDocComment = Cell!(Opt!CString)(some(cString!""));
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
		CString docComment = () {
			if (has(cellGet(firstDocComment))) {
				CString res = force(cellGet(firstDocComment));
				cellSet(firstDocComment, none!CString);
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
		finish(lexer.alloc, specs),
		finish(lexer.alloc, structAliases),
		finish(lexer.alloc, structs),
		finish(lexer.alloc, funs),
		finish(lexer.alloc, tests),
		finish(lexer.alloc, vars)));
}
