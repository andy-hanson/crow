module frontend.parse.parse;

@safe @nogc pure nothrow:

import frontend.parse.lexer :
	addDiagUnexpectedCurToken,
	createLexer,
	curPos,
	finishDiagnostics,
	getPeekToken,
	getPeekTokenAndData,
	Lexer,
	mustTakeToken,
	range,
	Token,
	TokenAndData;
import frontend.parse.parseExpr : parseFunExprBody, parseSingleStatementLine;
import frontend.parse.parseImport : parseImportsOrExports;
import frontend.parse.parseType :
	parseModifiers, parseParams, parseType, parseTypeArgForVarDecl, tryParseParams, tryTakeVisibility;
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
	tryTakeLiteralIntegral,
	tryTakeToken;
import model.ast :
	EnumOrFlagsMemberAst,
	ExprAst,
	FieldMutabilityAst,
	FileAst,
	FunDeclAst,
	ModifierAst,
	ImportsOrExportsAst,
	LiteralIntegral,
	LiteralIntegralAndRange,
	ModifierAst,
	NameAndRange,
	ParamsAst,
	RecordOrUnionMemberAst,
	SpecDeclAst,
	SpecSigAst,
	StructAliasAst,
	StructBodyAst,
	StructDeclAst,
	TestAst,
	TypeAst,
	VarDeclAst;
import model.model : TypeParams, VarKind, Visibility;
import model.parseDiag : ParseDiag, ParseDiagnostic;
import util.alloc.alloc : Alloc;
import util.cell : Cell, cellGet, cellSet;
import util.col.array : contains, emptySmallArray, SmallArray;
import util.col.arrayBuilder : add, ArrayBuilder, buildSmallArray, Builder, smallFinish;
import util.memory : allocate;
import util.opt : force, has, none, Opt, optIf, some;
import util.perf : Perf, PerfMeasure, withMeasure;
import util.sourceRange : Pos, Range;
import util.string : CString, emptySmallString, SmallString, stringOfCString;
import util.symbol : Symbol;
import util.util : castNonScope_ref, ptrTrustMe;

FileAst parseFile(scope ref Perf perf, ref Alloc alloc, in CString source) =>
	withMeasure!(FileAst, () {
		Lexer lexer = createLexer(ptrTrustMe(alloc), castNonScope_ref(source));
		return parseFileInner(lexer);
	})(perf, alloc, PerfMeasure.parseFile);

immutable struct ExprAndDiags {
	ExprAst expr;
	ParseDiagnostic[] diags;
}
ExprAndDiags parseSingleLineExpression(ref Alloc alloc, in CString source) {
	assert(!contains(stringOfCString(source), '\n'));
	Lexer lexer = createLexer(ptrTrustMe(alloc), castNonScope_ref(source));
	mustTakeToken(lexer, Token.newlineSameIndent);
	ExprAst expr = parseSingleStatementLine(lexer);
	takeOrAddDiagExpectedToken(lexer, Token.EOF, ParseDiag.Expected.Kind.endOfLine);
	return ExprAndDiags(expr, finishDiagnostics(lexer));
}

private:

TypeParams parseTypeParams(ref Lexer lexer) =>
	tryTakeToken(lexer, Token.bracketLeft)
		? buildSmallArray!NameAndRange(lexer.alloc, (scope ref Builder!NameAndRange res) {
			do {
				res ~= takeNameAndRange(lexer);
			} while (tryTakeToken(lexer, Token.comma));
			takeOrAddDiagExpectedToken(lexer, Token.bracketRight, ParseDiag.Expected.Kind.closingBracket);
		})
		: emptySmallArray!NameAndRange;

SmallArray!T parseIndentedLines(T)(ref Lexer lexer, in T delegate() @safe @nogc pure nothrow cb) =>
	tryTakeToken(lexer, Token.newlineIndent)
		? buildSmallArray!T(lexer.alloc, (scope ref Builder!T res) {
			do {
				res ~= cb();
			} while (takeNewlineOrDedent(lexer) == NewlineOrDedent.newline);
		})
		: emptySmallArray!T;

SmallArray!SpecSigAst parseIndentedSigs(ref Lexer lexer) =>
	parseIndentedLines!SpecSigAst(lexer, () {
		// TODO: get doc comment
		SmallString docComment = emptySmallString;
		Pos start = curPos(lexer);
		NameAndRange name = takeNameOrOperator(lexer);
		assert(name.start == start);
		TypeAst returnType = parseType(lexer);
		ParamsAst params = parseParams(lexer);
		return SpecSigAst(docComment, range(lexer, start), name.name, returnType, params);
	});

SmallArray!EnumOrFlagsMemberAst parseEnumOrFlagsMembers(ref Lexer lexer) =>
	parseIndentedLines!EnumOrFlagsMemberAst(lexer, () {
		Pos start = curPos(lexer);
		Symbol name = takeName(lexer);
		Opt!LiteralIntegralAndRange value = () {
			if (tryTakeToken(lexer, Token.equal)) {
				Opt!LiteralIntegralAndRange res = tryTakeLiteralIntegral(lexer);
				if (!has(res))
					addDiagExpected(lexer, ParseDiag.Expected.Kind.literalIntegral);
				return res;
			} else
				return none!LiteralIntegralAndRange;
		}();
		return EnumOrFlagsMemberAst(range(lexer, start), name, value);
	});

SmallArray!RecordOrUnionMemberAst parseRecordOrUnionMembers(ref Lexer lexer) =>
	parseIndentedLines!RecordOrUnionMemberAst(lexer, () {
		Pos start = curPos(lexer);
		Opt!Visibility visibility = tryTakeVisibility(lexer);
		NameAndRange name = takeNameAndRange(lexer);
		Opt!FieldMutabilityAst mutability = parseFieldMutability(lexer);
		Opt!TypeAst type = peekEndOfLine(lexer) ? none!TypeAst : some(parseType(lexer));
		return RecordOrUnionMemberAst(range(lexer, start), visibility, name, mutability, type);
	});

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

FunDeclAst parseFun(
	ref Lexer lexer,
	SmallString docComment,
	Opt!Visibility visibility,
	Pos start,
	NameAndRange name,
	TypeParams typeParams,
) {
	TypeAst returnType = parseType(lexer);
	ParamsAst params = parseParams(lexer);
	SmallArray!ModifierAst modifiers = parseModifiers(lexer);
	ExprAst body_ = parseFunExprBody(lexer);
	return FunDeclAst(
		range(lexer, start), docComment, visibility, name, typeParams, returnType, params, modifiers, body_);
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
		SmallArray!ModifierAst modifiers = parseModifiers(lexer);
		ExprAst body_ = parseFunExprBody(lexer);
		add(lexer.alloc, tests, TestAst(range(lexer, start), modifiers, body_));
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
			mustTakeToken(lexer, Token.alias_);
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
			mustTakeToken(lexer, Token.builtin);
			addStruct(() => StructBodyAst(StructBodyAst.Builtin()));
			break;
		case Token.enum_:
			mustTakeToken(lexer, Token.enum_);
			Opt!ParamsAst params = tryParseParams(lexer);
			addStruct(() => StructBodyAst(StructBodyAst.Enum(params, parseEnumOrFlagsMembers(lexer))));
			break;
		case Token.extern_:
			mustTakeToken(lexer, Token.extern_);
			StructBodyAst.Extern body_ = parseExternType(lexer);
			addStruct(() => StructBodyAst(body_));
			break;
		case Token.flags:
			mustTakeToken(lexer, Token.flags);
			Opt!ParamsAst params = tryParseParams(lexer);
			addStruct(() => StructBodyAst(StructBodyAst.Flags(params, parseEnumOrFlagsMembers(lexer))));
			break;
		case Token.global:
			Pos pos = curPos(lexer);
			mustTakeToken(lexer, Token.global);
			add(lexer.alloc, varDecls, parseVarDecl(
				lexer, start, docComment, visibility, name, typeParams, pos, VarKind.global));
			break;
		case Token.record:
			mustTakeToken(lexer, Token.record);
			Opt!ParamsAst params = tryParseParams(lexer);
			addStruct(() => StructBodyAst(StructBodyAst.Record(params, parseRecordOrUnionMembers(lexer))));
			break;
		case Token.spec:
			mustTakeToken(lexer, Token.spec);
			SmallArray!ModifierAst modifiers = parseModifiers(lexer);
			SmallArray!SpecSigAst sigs = parseIndentedSigs(lexer);
			add(lexer.alloc, specs, SpecDeclAst(
				range(lexer, start), docComment, visibility, name, typeParams, keywordPos, modifiers, sigs));
			break;
		case Token.thread_local:
			Pos pos = curPos(lexer);
			mustTakeToken(lexer, Token.thread_local);
			add(lexer.alloc, varDecls, parseVarDecl(
				lexer, start, docComment, visibility, name, typeParams, pos, VarKind.threadLocal));
			break;
		case Token.union_:
			mustTakeToken(lexer, Token.union_);
			Opt!ParamsAst params = tryParseParams(lexer);
			addStruct(() => StructBodyAst(StructBodyAst.Union(params, parseRecordOrUnionMembers(lexer))));
			break;
		default:
			add(lexer.alloc, funs, parseFun(lexer, docComment, visibility, start, name, typeParams));
			break;
	}
}

StructBodyAst.Extern parseExternType(ref Lexer lexer) {
	if (tryTakeToken(lexer, Token.parenLeft)) {
		Opt!(LiteralIntegralAndRange*) size = parseIntegral(lexer);
		Opt!(LiteralIntegralAndRange*) alignment = has(size) && tryTakeToken(lexer, Token.comma)
			? parseIntegral(lexer)
			: none!(LiteralIntegralAndRange*);
		takeOrAddDiagExpectedToken(lexer, Token.parenRight, ParseDiag.Expected.Kind.closingParen);
		return StructBodyAst.Extern(size, alignment);
	} else
		return StructBodyAst.Extern(none!(LiteralIntegralAndRange*), none!(LiteralIntegralAndRange*));
}
Opt!(LiteralIntegralAndRange*) parseIntegral(ref Lexer lexer) {
	Pos start = curPos(lexer);
	Opt!LiteralIntegral res = takeOrAddDiagExpectedToken!LiteralIntegral(
		lexer, ParseDiag.Expected.Kind.literalIntegral, (TokenAndData x) =>
			optIf(x.token == Token.literalIntegral, () => x.asLiteralIntegral));
	return has(res)
		? some(allocate(lexer.alloc, LiteralIntegralAndRange(range(lexer, start), force(res))))
		: none!(LiteralIntegralAndRange*);
}

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

FileAst parseFileInner(ref Lexer lexer) {
	SmallString moduleDocComment = takeNewline_topLevel(lexer);
	Cell!(Opt!SmallString) firstDocComment = Cell!(Opt!SmallString)(some(emptySmallString));
	bool noStd = tryTakeToken(lexer, Token.noStd);
	if (noStd)
		cellSet(firstDocComment, some(takeNewline_topLevel(lexer)));
	Opt!ImportsOrExportsAst imports = parseImportsOrExports(lexer, Token.import_);
	if (has(imports))
		cellSet(firstDocComment, some(takeNewline_topLevel(lexer)));
	Opt!ImportsOrExportsAst exports = parseImportsOrExports(lexer, Token.export_);
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
		if (tryTakeToken(lexer, Token.region))
			continue;
		if (tryTakeToken(lexer, Token.EOF))
			break;
		parseSpecOrStructOrFunOrTest(lexer, specs, structAliases, structs, funs, tests, vars, docComment);
	}

	return FileAst(
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
		smallFinish(lexer.alloc, vars));
}
