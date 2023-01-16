module frontend.parse.parse;

@safe @nogc pure nothrow:

import frontend.parse.ast :
	ExprAst,
	FileAst,
	FunDeclAst,
	FunModifierAst,
	ImportOrExportAst,
	ImportOrExportAstKind,
	ImportsOrExportsAst,
	LiteralIntOrNat,
	LiteralNatAst,
	ModifierAst,
	NameAndRange,
	ParamAst,
	ParamsAst,
	SpecBodyAst,
	SpecDeclAst,
	SpecSigAst,
	StructAliasAst,
	StructDeclAst,
	TestAst,
	TypeAst;
import frontend.parse.lexer :
	addDiag,
	addDiagAtChar,
	addDiagExpected,
	addDiagUnexpectedCurToken,
	alloc,
	allSymbols,
	createLexer,
	curPos,
	getCurLiteralInt,
	getCurLiteralNat,
	getCurSym,
	getPeekToken,
	Lexer,
	NewlineOrDedent,
	NewlineOrIndent,
	nextToken,
	peekToken,
	range,
	skipBlankLinesAndGetDocComment,
	skipNewlinesIgnoreIndentation,
	skipUntilNewlineNoDiag,
	takeDedentFromIndent1,
	takeIndentOrDiagTopLevel,
	takeName,
	takeNameAndRange,
	takeNameOrOperator,
	takeNameOrUnderscore,
	takeNewlineOrDedentAmount,
	takeNewlineOrIndent_topLevel,
	takeNewlineOrSingleDedent,
	takeNewline_topLevel,
	takePathComponent,
	takeOrAddDiagExpectedOperator,
	takeOrAddDiagExpectedToken,
	Token,
	tryTakeIndent,
	tryTakeName,
	tryTakeOperator,
	tryTakeToken;
import frontend.parse.parseExpr : parseFunExprBody;
import frontend.parse.parseType : parseType, tryParseTypeArgForEnumOrFlags;
import model.diag : DiagnosticWithinFile;
import model.model : FieldMutability, ImportFileType, Visibility;
import model.parseDiag : ParseDiag;
import util.alloc.alloc : Alloc;
import util.col.arr : emptySmallArray, only, small;
import util.col.arrBuilder : add, ArrBuilder, finishArr;
import util.col.str : SafeCStr;
import util.conv : safeToUshort;
import util.memory : allocate;
import util.opt : force, has, none, Opt, some;
import util.path : AllPaths, childPath, Path, PathOrRelPath, rootPath;
import util.perf : Perf, PerfMeasure, withMeasure;
import util.ptr : ptrTrustMe;
import util.sourceRange : Pos, RangeWithinFile;
import util.sym : AllSymbols, Sym, sym;
import util.util : todo, unreachable;

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

immutable struct ImportAndDedent {
	ImportOrExportAst import_;
	NewlineOrDedent dedented;
}

immutable struct ImportOrExportKindAndDedent {
	ImportOrExportAstKind kind;
	RangeWithinFile range;
	NewlineOrDedent dedented;
}

PathOrRelPath parseImportPath(ref AllPaths allPaths, ref Lexer lexer) {
	Opt!ushort nParents = () {
		if (tryTakeToken(lexer, Token.dot)) {
			takeOrAddDiagExpectedOperator(lexer, sym!"/", ParseDiag.Expected.Kind.slash);
			return some!ushort(0);
		} else if (tryTakeOperator(lexer, sym!"..")) {
			takeOrAddDiagExpectedOperator(lexer, sym!"/", ParseDiag.Expected.Kind.slash);
			return some(safeToUshort(takeDotDotSlashes(lexer, 1)));
		} else
			return none!ushort;
	}();
	return PathOrRelPath(
		nParents,
		addPathComponents(allPaths, lexer, rootPath(allPaths, takePathComponent(lexer))));
}

size_t takeDotDotSlashes(ref Lexer lexer, size_t acc) {
	if (tryTakeOperator(lexer, sym!"..")) {
		takeOrAddDiagExpectedOperator(lexer, sym!"/", ParseDiag.Expected.Kind.slash);
		return takeDotDotSlashes(lexer, acc + 1);
	} else
		return acc;
}

Path addPathComponents(ref AllPaths allPaths, ref Lexer lexer, Path acc) =>
	tryTakeOperator(lexer, sym!"/")
		? addPathComponents(allPaths, lexer, childPath(allPaths, acc, takePathComponent(lexer)))
		: acc;

ImportAndDedent parseSingleModuleImportOnOwnLine(ref AllPaths allPaths, ref Lexer lexer) {
	Pos start = curPos(lexer);
	PathOrRelPath path = parseImportPath(allPaths, lexer);
	ImportOrExportKindAndDedent kind = parseImportOrExportKind(lexer, start);
	return ImportAndDedent(ImportOrExportAst(kind.range, path, kind.kind), kind.dedented);
}

ImportOrExportKindAndDedent parseImportOrExportKind(ref Lexer lexer, Pos start) {
	if (tryTakeToken(lexer, Token.colon)) {
		if (tryTakeIndent(lexer, 1))
			return parseIndentedImportNames(lexer, start);
		else {
			Sym[] names = parseSingleImportNamesOnSingleLine(lexer);
			return ImportOrExportKindAndDedent(
				ImportOrExportAstKind(names),
				range(lexer, start),
				takeNewlineOrSingleDedent(lexer));
		}
	} else if (tryTakeToken(lexer, Token.as)) {
		Sym name = takeName(lexer);
		ImportFileType type = parseImportFileType(lexer);
		return ImportOrExportKindAndDedent(
			ImportOrExportAstKind(allocate(lexer.alloc, ImportOrExportAstKind.File(name, type))),
			range(lexer, start),
			takeNewlineOrSingleDedent(lexer));
	}
	return ImportOrExportKindAndDedent(
		ImportOrExportAstKind(ImportOrExportAstKind.ModuleWhole()),
		range(lexer, start),
		takeNewlineOrSingleDedent(lexer));
}

ImportFileType parseImportFileType(ref Lexer lexer) {
	Pos start = curPos(lexer);
	TypeAst type = parseType(lexer);
	Opt!ImportFileType fileType = toImportFileType(type);
	if (has(fileType))
		return force(fileType);
	else {
		addDiag(lexer, range(lexer, start), ParseDiag(ParseDiag.ImportFileTypeNotSupported()));
		return ImportFileType.str;
	}
}

Opt!ImportFileType toImportFileType(in TypeAst a) =>
	isSimpleName(a, sym!"string")
	? some(ImportFileType.str)
	: isInstStructOneArg(a, sym!"nat8", sym!"array")
	? some(ImportFileType.nat8Array)
	: none!ImportFileType;

bool isSimpleName(TypeAst a, Sym name) =>
	a.isA!NameAndRange && a.as!NameAndRange.name == name;

bool isInstStructOneArg(TypeAst a, Sym typeArgName, Sym name) {
	if (a.isA!(TypeAst.SuffixName*)) {
		TypeAst.SuffixName* s = a.as!(TypeAst.SuffixName*);
		return isSimpleName(s.left, typeArgName) && s.name.name == name;
	} else
		return false;
}

ImportOrExportKindAndDedent parseIndentedImportNames(ref Lexer lexer, Pos start) {
	ArrBuilder!Sym names;
	immutable struct NewlineOrDedentAndRange {
		NewlineOrDedent newlineOrDedent;
		RangeWithinFile range;
	}
	NewlineOrDedentAndRange recur() {
		TrailingComma trailingComma = takeCommaSeparatedNames(lexer, names);
		RangeWithinFile range0 = range(lexer, start);
		switch (takeNewlineOrDedentAmount(lexer, 2)) {
			case 0:
				final switch (trailingComma) {
					case TrailingComma.no:
						addDiag(lexer, range(lexer, start), ParseDiag(
							ParseDiag.Expected(ParseDiag.Expected.Kind.comma)));
						break;
					case TrailingComma.yes:
						break;
				}
				return recur();
			case 1:
				final switch (trailingComma) {
					case TrailingComma.no:
						break;
					case TrailingComma.yes:
						todo!void("!");
						break;
				}
				return NewlineOrDedentAndRange(NewlineOrDedent.newline, range0);
			case 2:
				final switch (trailingComma) {
					case TrailingComma.no:
						break;
					case TrailingComma.yes:
						todo!void("!");
						break;
				}
				return NewlineOrDedentAndRange(NewlineOrDedent.dedent, range0);
			default:
				return unreachable!NewlineOrDedentAndRange();
		}
	}
	NewlineOrDedentAndRange res = recur();
	return ImportOrExportKindAndDedent(
		ImportOrExportAstKind(finishArr(lexer.alloc, names)),
		res.range,
		res.newlineOrDedent);
}

Sym[] parseSingleImportNamesOnSingleLine(ref Lexer lexer) {
	ArrBuilder!Sym names;
	final switch (takeCommaSeparatedNames(lexer, names)) {
		case TrailingComma.no:
			break;
		case TrailingComma.yes:
			//TODO: warn and continue
			todo!void("!");
			break;
	}
	return finishArr(lexer.alloc, names);
}

enum TrailingComma { no, yes }

TrailingComma takeCommaSeparatedNames(ref Lexer lexer, ref ArrBuilder!Sym names) {
	add(lexer.alloc, names, takeNameOrOperator(lexer));
	return tryTakeToken(lexer, Token.comma)
		? peekToken(lexer, Token.newline)
			? TrailingComma.yes
			: takeCommaSeparatedNames(lexer, names)
		: TrailingComma.no;
}

ParamAst parseSingleParam(ref Lexer lexer) {
	Pos start = curPos(lexer);
	Opt!Sym name = takeNameOrUnderscore(lexer);
	TypeAst type = parseType(lexer);
	return ParamAst(range(lexer, start), name, type);
}

ParamsAst parseParams(ref Lexer lexer) {
	if (!takeOrAddDiagExpectedToken(lexer, Token.parenLeft, ParseDiag.Expected.Kind.openParen)) {
		skipUntilNewlineNoDiag(lexer);
		return ParamsAst([]);
	} else if (tryTakeToken(lexer, Token.parenRight))
		return ParamsAst(emptySmallArray!ParamAst);
	else if (tryTakeToken(lexer, Token.dot3)) {
		ParamAst param = parseSingleParam(lexer);
		takeOrAddDiagExpectedToken(lexer, Token.parenRight, ParseDiag.Expected.Kind.closingParen);
		return ParamsAst(allocate(lexer.alloc, ParamsAst.Varargs(param)));
	} else {
		ArrBuilder!ParamAst res;
		for (;;) {
			skipNewlinesIgnoreIndentation(lexer);
			add(lexer.alloc, res, parseSingleParam(lexer));
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
	// TODO: this doesn't work because the lexer already skipped comments
	SafeCStr comment = skipBlankLinesAndGetDocComment(lexer);
	Pos start = curPos(lexer);
	Sym name = takeNameOrOperator(lexer);
	TypeAst returnType = parseType(lexer);
	ParamsAst params = parseParams(lexer);
	return SpecSigAst(comment, range(lexer, start), name, returnType, params);
}

SpecSigAst[] parseIndentedSigs(ref Lexer lexer) {
	final switch (takeNewlineOrIndent_topLevel(lexer)) {
		case NewlineOrIndent.newline:
			return [];
		case NewlineOrIndent.indent:
			ArrBuilder!SpecSigAst res;
			for (;;) {
				SpecSigAst sig = parseSpecSig(lexer);
				add(lexer.alloc, res, sig);
				final switch (takeNewlineOrSingleDedent(lexer)) {
					case NewlineOrDedent.newline:
						break;
					case NewlineOrDedent.dedent:
						return finishArr(lexer.alloc, res);
				}
			}
	}
}

StructDeclAst.Body.Enum.Member[] parseEnumOrFlagsMembers(ref Lexer lexer) {
	final switch (takeNewlineOrIndent_topLevel(lexer)) {
		case NewlineOrIndent.newline:
			return [];
		case NewlineOrIndent.indent:
			ArrBuilder!(StructDeclAst.Body.Enum.Member) res;
			StructDeclAst.Body.Enum.Member[] recur() {
				Pos start = curPos(lexer);
				Sym name = takeName(lexer);
				Opt!LiteralIntOrNat value = () {
					if (tryTakeToken(lexer, Token.equal)) {
						if (tryTakeToken(lexer, Token.literalInt))
							return some(LiteralIntOrNat(getCurLiteralInt(lexer)));
						else if (tryTakeToken(lexer, Token.literalNat))
							return some(LiteralIntOrNat(getCurLiteralNat(lexer)));
						else {
							addDiagExpected(lexer, ParseDiag.Expected.Kind.literalIntOrNat);
							return none!LiteralIntOrNat;
						}
					} else
						return none!LiteralIntOrNat;
				}();
				add(lexer.alloc, res, StructDeclAst.Body.Enum.Member(range(lexer, start), name, value));
				final switch (takeNewlineOrSingleDedent(lexer)) {
					case NewlineOrDedent.newline:
						return recur();
					case NewlineOrDedent.dedent:
						return finishArr(lexer.alloc, res);
				}
			}
			return recur();
	}
}

StructDeclAst.Body.Record parseRecordBody(ref Lexer lexer) {
	ArrBuilder!(StructDeclAst.Body.Record.Field) fields;
	final switch (takeNewlineOrIndent_topLevel(lexer)) {
		case NewlineOrIndent.newline:
			break;
		case NewlineOrIndent.indent:
			parseRecordFields(lexer, fields);
			break;
	}
	return StructDeclAst.Body.Record(small(finishArr(lexer.alloc, fields)));
}

void parseRecordFields(ref Lexer lexer, ref ArrBuilder!(StructDeclAst.Body.Record.Field) res) {
	Pos start = curPos(lexer);
	Visibility visibility = tryTakeVisibility(lexer);
	Sym name = takeName(lexer);
	FieldMutability mutability = parseFieldMutability(lexer);
	TypeAst type = parseType(lexer);
	add(lexer.alloc, res, StructDeclAst.Body.Record.Field(range(lexer, start), visibility, name, mutability, type));
	final switch (takeNewlineOrSingleDedent(lexer)) {
		case NewlineOrDedent.newline:
			parseRecordFields(lexer, res);
			break;
		case NewlineOrDedent.dedent:
			break;
	}
}

FieldMutability parseFieldMutability(ref Lexer lexer) {
	if (tryTakeToken(lexer, Token.dot)) {
		// '.' isn't valid at start of a type, so can only be '.mut'
		if (tryTakeToken(lexer, Token.mut))
			return FieldMutability.private_;
		else {
			addDiagUnexpectedCurToken(lexer, curPos(lexer) - 1, Token.dot);
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
		Opt!TypeAst type = peekToken(lexer, Token.newline) ? none!TypeAst : some(parseType(lexer));
		add(lexer.alloc, res, StructDeclAst.Body.Union.Member(range(lexer, start), name, type));
	} while (takeNewlineOrSingleDedent(lexer) == NewlineOrDedent.newline);
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
	if (peekToken(lexer, Token.newline) || peekToken(lexer, Token.EOF))
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
		nextToken(lexer);
		return FunModifierAst(FunModifierAst.Special(start, force(special)));
	} else {
		TypeAst type = parseType(lexer);
		Pos egPos = curPos(lexer);
		Opt!(FunModifierAst.Special.Flags) eg = tryTakeExternOrGlobal(lexer);
		return has(eg)
			? FunModifierAst(FunModifierAst.ExternOrGlobal(allocate(lexer.alloc, type), egPos, force(eg)))
			: FunModifierAst(type);
	}
}

TypeAst[] parseSpecModifiers(ref Lexer lexer) {
	if (peekToken(lexer, Token.newline) || peekToken(lexer, Token.EOF))
		return [];
	else {
		ArrBuilder!TypeAst res;
		add(lexer.alloc, res, parseType(lexer));
		while (tryTakeToken(lexer, Token.comma))
			add(lexer.alloc, res, parseType(lexer));
		return finishArr(lexer.alloc, res);
	}
}

Opt!(FunModifierAst.Special.Flags) tryTakeExternOrGlobal(ref Lexer lexer) =>
	tryTakeToken(lexer, Token.extern_)
		? some(FunModifierAst.Special.Flags.extern_)
		: tryTakeToken(lexer, Token.global)
		? some(FunModifierAst.Special.Flags.global)
		: none!(FunModifierAst.Special.Flags);

Opt!(FunModifierAst.Special.Flags) tryGetSpecialFunModifier(Token token) {
	switch (token) {
		case Token.builtin:
			return some(FunModifierAst.Special.Flags.builtin);
		case Token.extern_:
			return some(FunModifierAst.Special.Flags.extern_);
		case Token.forceCtx:
			return some(FunModifierAst.Special.Flags.forceCtx);
		case Token.global:
			return some(FunModifierAst.Special.Flags.global);
		case Token.noCtx:
			return some(FunModifierAst.Special.Flags.noctx);
		case Token.summon:
			return some(FunModifierAst.Special.Flags.summon);
		case Token.thread_local:
			return some(FunModifierAst.Special.Flags.thread_local);
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
	ref ArrBuilder!SpecDeclAst specs,
	ref ArrBuilder!StructAliasAst structAliases,
	ref ArrBuilder!StructDeclAst structs,
	ref ArrBuilder!FunDeclAst funs,
	ref ArrBuilder!TestAst tests,
	SafeCStr docComment,
) {
	if (tryTakeToken(lexer, Token.test))
		add(lexer.alloc, tests, TestAst(parseFunExprBody(lexer)));
	else
		parseSpecOrStructOrFun(lexer, specs, structAliases, structs, funs, docComment);
}

void parseSpecOrStructOrFun(
	ref Lexer lexer,
	ref ArrBuilder!SpecDeclAst specs,
	ref ArrBuilder!StructAliasAst structAliases,
	ref ArrBuilder!StructDeclAst structs,
	ref ArrBuilder!FunDeclAst funs,
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
			nextToken(lexer);
			TypeAst target = () {
				final switch (takeNewlineOrIndent_topLevel(lexer)) {
					case NewlineOrIndent.newline:
						return TypeAst(TypeAst.Bogus(range(lexer, start)));
					case NewlineOrIndent.indent:
						TypeAst res = parseType(lexer);
						takeDedentFromIndent1(lexer);
						return res;
				}
			}();
			add(lexer.alloc, structAliases, StructAliasAst(
				range(lexer, start), docComment, visibility, name, small(typeParams), target));
			break;
		case Token.builtin:
			nextToken(lexer);
			addStruct(() => StructDeclAst.Body(StructDeclAst.Body.Builtin()));
			takeNewline_topLevel(lexer);
			break;
		case Token.builtinSpec:
			nextToken(lexer);
			add(lexer.alloc, specs, SpecDeclAst(
				range(lexer, start),
				docComment,
				visibility,
				name,
				small(typeParams),
				emptySmallArray!TypeAst,
				SpecBodyAst(SpecBodyAst.Builtin())));
			takeNewline_topLevel(lexer);
			break;
		case Token.enum_:
			nextToken(lexer);
			Opt!(TypeAst*) typeArg = tryParseTypeArgForEnumOrFlags(lexer);
			addStruct(() => StructDeclAst.Body(
				StructDeclAst.Body.Enum(typeArg, small(parseEnumOrFlagsMembers(lexer)))));
			break;
		case Token.extern_:
			nextToken(lexer);
			StructDeclAst.Body.Extern body_ = parseExternType(lexer);
			addStruct(() => StructDeclAst.Body(body_));
			takeNewline_topLevel(lexer);
			break;
		case Token.flags:
			nextToken(lexer);
			Opt!(TypeAst*) typeArg = tryParseTypeArgForEnumOrFlags(lexer);
			addStruct(() => StructDeclAst.Body(
				StructDeclAst.Body.Flags(typeArg, small(parseEnumOrFlagsMembers(lexer)))));
			break;
		case Token.record:
			nextToken(lexer);
			addStruct(() => StructDeclAst.Body(parseRecordBody(lexer)));
			break;
		case Token.spec:
			nextToken(lexer);
			TypeAst[] parents = parseSpecModifiers(lexer);
			SpecBodyAst body_ = SpecBodyAst(parseIndentedSigs(lexer));
			add(lexer.alloc, specs, SpecDeclAst(
				range(lexer, start), docComment, visibility, name, small(typeParams), small(parents), body_));
			break;
		case Token.union_:
			nextToken(lexer);
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
	takeOrAddDiagExpectedToken(lexer, Token.literalNat, ParseDiag.Expected.Kind.literalNat)
		? some(allocate(lexer.alloc, getCurLiteralNat(lexer)))
		: none!(LiteralNatAst*);

StructDeclAst.Body.Union.Member[] parseUnionMembersOrDiag(ref Lexer lexer) {
	final switch (takeNewlineOrIndent_topLevel(lexer)) {
		case NewlineOrIndent.newline:
			//TODO: this should be a checker error, not parse error
			addDiagAtChar(lexer, ParseDiag(ParseDiag.UnionCantBeEmpty()));
			return [];
		case NewlineOrIndent.indent:
			return parseUnionMembers(lexer);
	}
}

ModifierAst[] parseModifiers(ref Lexer lexer) {
	ArrBuilder!ModifierAst res;
	parseModifiersRecur(lexer, res);
	return finishArr(lexer.alloc, res);
}
void parseModifiersRecur(ref Lexer lexer, ref ArrBuilder!ModifierAst res) {
	Pos start = curPos(lexer);
	Opt!(ModifierAst.Kind) kind = tryParseModifierKind(lexer);
	if (has(kind)) {
		add(lexer.alloc, res, ModifierAst(start, force(kind)));
		return parseModifiersRecur(lexer, res);
	}
}

Opt!(ModifierAst.Kind) tryParseModifierKind(ref Lexer lexer) {
	if (tryTakeOperator(lexer, sym!"-")) {
		Opt!Sym name = tryTakeName(lexer);
		if (!(has(name) && force(name) == sym!"new"))
			todo!void("diagnostic: expected 'new' after '-'");
		return some(ModifierAst.Kind.newPrivate);
	} else if (tryTakeOperator(lexer, sym!"+")) {
		Opt!Sym name = tryTakeName(lexer);
		if (!(has(name) && force(name) == sym!"new"))
			todo!void("diagnostic: expected 'new' after '+'");
		return some(ModifierAst.Kind.newPublic);
	} else {
		Opt!(ModifierAst.Kind) res = () {
			switch (getPeekToken(lexer)) {
				case Token.extern_:
					return some(ModifierAst.Kind.extern_);
				case Token.mut:
					return some(ModifierAst.Kind.mut);
				case Token.name:
					Opt!(ModifierAst.Kind) kind = modifierKindFromSym(getCurSym(lexer));
					if (!has(kind))
						todo!void("diagnostic: invalid modifier");
					return kind;
				default:
					return none!(ModifierAst.Kind);
			}
		}();
		if (has(res)) {
			nextToken(lexer);
		}
		return res;
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

Opt!ImportsOrExportsAst parseImportsOrExports(ref AllPaths allPaths, ref Lexer lexer, Token keyword) {
	Pos start = curPos(lexer);
	if (tryTakeToken(lexer, keyword)) {
		ArrBuilder!ImportOrExportAst res;
		if (takeIndentOrDiagTopLevel(lexer)) {
			void recur() {
				ImportAndDedent id = parseSingleModuleImportOnOwnLine(allPaths, lexer);
				add(lexer.alloc, res, id.import_);
				if (id.dedented == NewlineOrDedent.newline)
					recur();
			}
			recur();
		}
		return some(ImportsOrExportsAst(range(lexer, start), finishArr(lexer.alloc, res)));
	} else
		return none!ImportsOrExportsAst;
}

FileAst parseFileInner(ref AllPaths allPaths, ref Lexer lexer) {
	SafeCStr moduleDocComment = skipBlankLinesAndGetDocComment(lexer);
	bool noStd = tryTakeToken(lexer, Token.noStd);
	if (noStd)
		takeOrAddDiagExpectedToken(lexer, Token.newline, ParseDiag.Expected.Kind.endOfLine);
	Opt!ImportsOrExportsAst imports = parseImportsOrExports(allPaths, lexer, Token.import_);
	Opt!ImportsOrExportsAst exports = parseImportsOrExports(allPaths, lexer, Token.export_);

	ArrBuilder!SpecDeclAst specs;
	ArrBuilder!StructAliasAst structAliases;
	ArrBuilder!StructDeclAst structs;
	ArrBuilder!FunDeclAst funs;
	ArrBuilder!TestAst tests;
	parseFileRecur(lexer, specs, structAliases, structs, funs, tests);
	return FileAst(
		moduleDocComment,
		noStd,
		imports,
		exports,
		finishArr(lexer.alloc, specs),
		finishArr(lexer.alloc, structAliases),
		finishArr(lexer.alloc, structs),
		finishArr(lexer.alloc, funs),
		finishArr(lexer.alloc, tests));
}

void parseFileRecur(
	ref Lexer lexer,
	ref ArrBuilder!SpecDeclAst specs,
	ref ArrBuilder!StructAliasAst structAliases,
	ref ArrBuilder!StructDeclAst structs,
	ref ArrBuilder!FunDeclAst funs,
	ref ArrBuilder!TestAst tests,
) {
	SafeCStr docComment = skipBlankLinesAndGetDocComment(lexer);
	if (!tryTakeToken(lexer, Token.EOF)) {
		parseSpecOrStructOrFunOrTest(lexer, specs, structAliases, structs, funs, tests, docComment);
		parseFileRecur(lexer, specs, structAliases, structs, funs, tests);
	}
}
