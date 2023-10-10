module frontend.parse.parse;

@safe @nogc pure nothrow:

import frontend.parse.ast :
	DestructureAst,
	ExprAst,
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
import frontend.parse.lexer :
	addDiagUnexpectedCurToken,
	alloc,
	allSymbols,
	createLexer,
	curPos,
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
import model.diag : DiagnosticWithinFile;
import model.model : FieldMutability, VarKind, Visibility;
import model.parseDiag : ParseDiag;
import util.alloc.alloc : Alloc;
import util.cell : Cell, cellGet, cellSet;
import util.col.arr : emptySmallArray, small;
import util.col.arrBuilder : add, ArrBuilder, finishArr;
import util.col.str : SafeCStr, safeCStr;
import util.memory : allocate;
import util.opt : force, has, none, Opt, some;
import util.path : AllPaths;
import util.perf : Perf, PerfMeasure, withMeasure;
import util.ptr : ptrTrustMe;
import util.sourceRange : Pos, RangeWithinFile;
import util.sym : AllSymbols, Sym, sym;
import util.util : typeAs;

FileAst parseFile(
	ref Alloc alloc,
	scope ref Perf perf,
	ref AllPaths allPaths,
	ref AllSymbols allSymbols,
	ref ArrBuilder!DiagnosticWithinFile diagsBuilder,
	scope SafeCStr source,
) =>
	withMeasure!(FileAst, () @trusted {
		Lexer lexer = createLexer(
			ptrTrustMe(alloc),
			ptrTrustMe(allSymbols),
			ptrTrustMe(diagsBuilder),
			source);
		return parseFileInner(allPaths, lexer);
	})(alloc, perf, PerfMeasure.parseFile);

private:

NameAndRange[] parseTypeParams(ref Lexer lexer) {
	if (tryTakeToken(lexer, Token.bracketLeft)) {
		ArrBuilder!NameAndRange res;
		do {
			add(lexer.alloc, res, takeNameAndRange(lexer));
		} while (tryTakeToken(lexer, Token.comma));
		takeOrAddDiagExpectedToken(lexer, Token.bracketRight, ParseDiag.Expected.Kind.closingBracket);
		return finishArr(lexer.alloc, res);
	} else
		return [];
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
		ArrBuilder!DestructureAst res;
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
		return ParamsAst(finishArr(lexer.alloc, res));
	}
}

SpecSigAst parseSpecSig(ref Lexer lexer) {
	// TODO: get doc comment
	SafeCStr comment = safeCStr!"";
	Pos start = curPos(lexer);
	Sym name = takeNameOrOperator(lexer);
	TypeAst returnType = parseType(lexer);
	ParamsAst params = parseParams(lexer);
	return SpecSigAst(comment, range(lexer, start), name, returnType, params);
}

SpecSigAst[] parseIndentedSigs(ref Lexer lexer) {
	if (tryTakeToken(lexer, Token.newlineIndent)) {
		ArrBuilder!SpecSigAst res;
		while (true) {
			SpecSigAst sig = parseSpecSig(lexer);
			add(lexer.alloc, res, sig);
			final switch (takeNewlineOrDedent(lexer)) {
				case NewlineOrDedent.newline:
					continue;
				case NewlineOrDedent.dedent:
					return finishArr(lexer.alloc, res);
			}
		}
	} else
		return [];
}

StructDeclAst.Body.Enum.Member[] parseEnumOrFlagsMembers(ref Lexer lexer) {
	if (tryTakeToken(lexer, Token.newlineIndent)) {
		ArrBuilder!(StructDeclAst.Body.Enum.Member) res;
		StructDeclAst.Body.Enum.Member[] recur() {
			Pos start = curPos(lexer);
			Sym name = takeName(lexer);
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
					return finishArr(lexer.alloc, res);
			}
		}
		return recur();
	} else
		return [];
}

StructDeclAst.Body.Record parseRecordBody(ref Lexer lexer) =>
	StructDeclAst.Body.Record(small(tryTakeToken(lexer, Token.newlineIndent) ? parseRecordFields(lexer) : []));

StructDeclAst.Body.Record.Field[] parseRecordFields(ref Lexer lexer) {
	ArrBuilder!(StructDeclAst.Body.Record.Field) fields;
	while (true) {
		Pos start = curPos(lexer);
		Visibility visibility = tryTakeVisibility(lexer);
		Sym name = takeName(lexer);
		FieldMutability mutability = parseFieldMutability(lexer);
		TypeAst type = parseType(lexer);
		add(lexer.alloc, fields, StructDeclAst.Body.Record.Field(
			range(lexer, start), visibility, name, mutability, type));
		final switch (takeNewlineOrDedent(lexer)) {
			case NewlineOrDedent.newline:
				continue;
			case NewlineOrDedent.dedent:
				return finishArr(lexer.alloc, fields);
		}
	}
}

FieldMutability parseFieldMutability(ref Lexer lexer) {
	TokenAndData peek = getPeekTokenAndData(lexer);
	if (tryTakeOperator(lexer, sym!"-")) {
		if (tryTakeToken(lexer, Token.mut))
			return FieldMutability.private_;
		else {
			addDiagUnexpectedCurToken(lexer, curPos(lexer) - 1, peek);
			return FieldMutability.const_;
		}
	} else
		return tryTakeToken(lexer, Token.mut)
			? FieldMutability.public_
			: FieldMutability.const_;
}

StructDeclAst.Body.Union.Member[] parseUnionMembers(ref Lexer lexer) {
	ArrBuilder!(StructDeclAst.Body.Union.Member) res;
	do {
		Pos start = curPos(lexer);
		Sym name = takeName(lexer);
		Opt!TypeAst type = peekEndOfLine(lexer) ? none!TypeAst : some(parseType(lexer));
		add(lexer.alloc, res, StructDeclAst.Body.Union.Member(range(lexer, start), name, type));
	} while (takeNewlineOrDedent(lexer) == NewlineOrDedent.newline);
	return finishArr(lexer.alloc, res);
}

FunDeclAst parseFun(
	ref Lexer lexer,
	SafeCStr docComment,
	Visibility visibility,
	Pos start,
	Sym name,
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
		small(typeParams),
		returnType,
		params,
		small(modifiers),
		body_);
}

FunModifierAst[] parseFunModifiers(ref Lexer lexer) {
	if (peekEndOfLine(lexer))
		return [];
	else {
		ArrBuilder!FunModifierAst res;
		add(lexer.alloc, res, parseFunModifier(lexer));
		while (tryTakeToken(lexer, Token.comma))
			add(lexer.alloc, res, parseFunModifier(lexer));
		return finishArr(lexer.alloc, res);
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

TypeAst[] parseSpecModifiers(ref Lexer lexer) {
	if (peekEndOfLine(lexer))
		return [];
	else {
		ArrBuilder!TypeAst res;
		add(lexer.alloc, res, parseType(lexer));
		while (tryTakeToken(lexer, Token.comma))
			add(lexer.alloc, res, parseType(lexer));
		return finishArr(lexer.alloc, res);
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
	scope ref ArrBuilder!SpecDeclAst specs,
	scope ref ArrBuilder!StructAliasAst structAliases,
	scope ref ArrBuilder!StructDeclAst structs,
	scope ref ArrBuilder!FunDeclAst funs,
	scope ref ArrBuilder!TestAst tests,
	scope ref ArrBuilder!VarDeclAst vars,
	SafeCStr docComment,
) {
	if (tryTakeToken(lexer, Token.test))
		add(lexer.alloc, tests, TestAst(parseFunExprBody(lexer)));
	else
		parseSpecOrStructOrFun(lexer, specs, structAliases, structs, funs, vars, docComment);
}

void parseSpecOrStructOrFun(
	ref Lexer lexer,
	scope ref ArrBuilder!SpecDeclAst specs,
	scope ref ArrBuilder!StructAliasAst structAliases,
	scope ref ArrBuilder!StructDeclAst structs,
	scope ref ArrBuilder!FunDeclAst funs,
	scope ref ArrBuilder!VarDeclAst varDecls,
	SafeCStr docComment,
) {
	Pos start = curPos(lexer);
	Visibility visibility = tryTakeVisibility(lexer);
	Sym name = takeNameOrOperator(lexer);
	NameAndRange[] typeParams = parseTypeParams(lexer);

	void addStruct(in StructDeclAst.Body delegate() @safe @nogc pure nothrow cb) {
		ModifierAst[] modifiers = parseModifiers(lexer);
		StructDeclAst.Body body_ = cb();
		add(lexer.alloc, structs, StructDeclAst(
			range(lexer, start),
			docComment,
			visibility,
			name,
			small(typeParams),
			small(modifiers),
			body_));
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
				(RangeWithinFile range) => TypeAst(TypeAst.Bogus(range)));
			add(lexer.alloc, structAliases, StructAliasAst(
				range(lexer, start), docComment, visibility, name, small(typeParams), target));
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
				small(typeParams),
				emptySmallArray!TypeAst,
				SpecBodyAst(SpecBodyAst.Builtin())));
			break;
		case Token.enum_:
			takeNextToken(lexer);
			Opt!(TypeAst*) typeArg = tryParseTypeArgForEnumOrFlags(lexer);
			addStruct(() => StructDeclAst.Body(
				StructDeclAst.Body.Enum(typeArg, small(parseEnumOrFlagsMembers(lexer)))));
			break;
		case Token.extern_:
			takeNextToken(lexer);
			StructDeclAst.Body.Extern body_ = parseExternType(lexer);
			addStruct(() => StructDeclAst.Body(body_));
			break;
		case Token.flags:
			takeNextToken(lexer);
			Opt!(TypeAst*) typeArg = tryParseTypeArgForEnumOrFlags(lexer);
			addStruct(() => StructDeclAst.Body(
				StructDeclAst.Body.Flags(typeArg, small(parseEnumOrFlagsMembers(lexer)))));
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
			TypeAst[] parents = parseSpecModifiers(lexer);
			SpecBodyAst body_ = SpecBodyAst(parseIndentedSigs(lexer));
			add(lexer.alloc, specs, SpecDeclAst(
				range(lexer, start), docComment, visibility, name, small(typeParams), small(parents), body_));
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
	SafeCStr docComment,
	Visibility visibility,
	Sym name,
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
		(RangeWithinFile _) => typeAs!(StructDeclAst.Body.Union.Member[])([]));

ModifierAst[] parseModifiers(ref Lexer lexer) {
	if (peekEndOfLine(lexer)) return [];
	ArrBuilder!ModifierAst res;
	while (true) {
		Pos start = curPos(lexer);
		ModifierAst.Kind kind = parseModifierKind(lexer);
		add(lexer.alloc, res, ModifierAst(start, kind));
		if (peekEndOfLine(lexer))
			break;
		else
			takeOrAddDiagExpectedToken(lexer, Token.comma, ParseDiag.Expected.Kind.comma);
	}
	return finishArr(lexer.alloc, res);
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
			Opt!(ModifierAst.Kind) kind = modifierKindFromSym(token.asSym());
			return has(kind) ? force(kind) : fail();
		case Token.operator:
			switch (token.asSym().value) {
				case sym!"-".value:
					Opt!Sym name = tryTakeName(lexer);
					return has(name) && force(name) == sym!"new" ? ModifierAst.Kind.newPrivate : fail();
				case sym!"+".value:
					Opt!Sym name = tryTakeName(lexer);
					return has(name) && force(name) == sym!"new" ? ModifierAst.Kind.newPublic : fail();
				default:
					return fail();
			}
		default:
			return fail();
	}
}

Opt!(ModifierAst.Kind) modifierKindFromSym(Sym a) {
	switch (a.value) {
		case sym!"by-val".value:
			return some(ModifierAst.Kind.byVal);
		case sym!"by-ref".value:
			return some(ModifierAst.Kind.byRef);
		case sym!"data".value:
			return some(ModifierAst.Kind.data);
		case sym!"force-shared".value:
			return some(ModifierAst.Kind.forceShared);
		case sym!"packed".value:
			return some(ModifierAst.Kind.packed);
		case sym!"shared".value:
			return some(ModifierAst.Kind.shared_);
		default:
			return none!(ModifierAst.Kind);
	}
}

Visibility tryTakeVisibility(ref Lexer lexer) =>
	tryTakeOperator(lexer, sym!"-")
		? Visibility.private_
		: tryTakeOperator(lexer, sym!"+")
		? Visibility.public_
		: tryTakeOperator(lexer, sym!"~")
		? Visibility.internal
		: Visibility.internal;

FileAst parseFileInner(ref AllPaths allPaths, ref Lexer lexer) {
	SafeCStr moduleDocComment = takeNewline_topLevel(lexer);
	Cell!(Opt!SafeCStr) firstDocComment = Cell!(Opt!SafeCStr)(some(safeCStr!""));
	bool noStd = tryTakeToken(lexer, Token.noStd);
	if (noStd)
		cellSet(firstDocComment, some(takeNewline_topLevel(lexer)));
	Opt!ImportsOrExportsAst imports = parseImportsOrExports(allPaths, lexer, Token.import_);
	if (has(imports))
		cellSet(firstDocComment, some(takeNewline_topLevel(lexer)));
	Opt!ImportsOrExportsAst exports = parseImportsOrExports(allPaths, lexer, Token.export_);
	if (has(exports))
		cellSet(firstDocComment, some(takeNewline_topLevel(lexer)));

	ArrBuilder!SpecDeclAst specs;
	ArrBuilder!StructAliasAst structAliases;
	ArrBuilder!StructDeclAst structs;
	ArrBuilder!FunDeclAst funs;
	ArrBuilder!TestAst tests;
	ArrBuilder!VarDeclAst vars;

	while (!tryTakeToken(lexer, Token.EOF)) {
		SafeCStr docComment = () {
			if (has(cellGet(firstDocComment))) {
				SafeCStr res = force(cellGet(firstDocComment));
				cellSet(firstDocComment, none!SafeCStr);
				return res;
			} else
				return takeNewline_topLevel(lexer);
		}();
		if (tryTakeToken(lexer, Token.EOF))
			break;
		parseSpecOrStructOrFunOrTest(lexer, specs, structAliases, structs, funs, tests, vars, docComment);
	}

	return FileAst(
		moduleDocComment,
		noStd,
		imports,
		exports,
		finishArr(lexer.alloc, specs),
		finishArr(lexer.alloc, structAliases),
		finishArr(lexer.alloc, structs),
		finishArr(lexer.alloc, funs),
		finishArr(lexer.alloc, tests),
		finishArr(lexer.alloc, vars));
}
