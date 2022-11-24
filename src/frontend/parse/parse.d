module frontend.parse.parse;

@safe @nogc pure nothrow:

import frontend.parse.ast :
	bogusTypeAst,
	ExprAst,
	FileAst,
	FunDeclAst,
	FunModifierAst,
	ImportOrExportAst,
	ImportOrExportAstKind,
	ImportsOrExportsAst,
	LiteralIntOrNat,
	LiteralNatAst,
	matchTypeAst,
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
	takeTypeArgsEnd,
	Token,
	tryTakeIndent,
	tryTakeName,
	tryTakeOperator,
	tryTakeToken;
import frontend.parse.parseExpr : parseFunExprBody;
import frontend.parse.parseType : parseType, parseTypeNoTuple, tryParseTypeArg, tryParseTypeArgsBracketed;
import model.diag : DiagnosticWithinFile;
import model.model : FieldMutability, ImportFileType, Visibility;
import model.parseDiag : ParseDiag;
import util.alloc.alloc : Alloc;
import util.col.arr : empty, emptySmallArray, small;
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

immutable(FileAst) parseFile(
	ref Alloc alloc,
	scope ref Perf perf,
	ref AllPaths allPaths,
	ref AllSymbols allSymbols,
	ref ArrBuilder!DiagnosticWithinFile diagsBuilder,
	scope immutable SafeCStr source,
) =>
	withMeasure!(immutable FileAst, () @trusted {
		Lexer lexer = createLexer(
			ptrTrustMe(alloc),
			ptrTrustMe(allSymbols),
			ptrTrustMe(diagsBuilder),
			source);
		return parseFileInner(allPaths, lexer);
	})(alloc, perf, PerfMeasure.parseFile);

private:

immutable(NameAndRange[]) parseTypeParams(ref Lexer lexer) {
	if (tryTakeOperator(lexer, sym!"<")) {
		ArrBuilder!NameAndRange res;
		do {
			add(lexer.alloc, res, takeNameAndRange(lexer));
		} while (tryTakeToken(lexer, Token.comma));
		takeTypeArgsEnd(lexer);
		return finishArr(lexer.alloc, res);
	} else
		return [];
}

struct ImportAndDedent {
	immutable ImportOrExportAst import_;
	immutable NewlineOrDedent dedented;
}

struct ImportOrExportKindAndDedent {
	immutable ImportOrExportAstKind kind;
	immutable RangeWithinFile range;
	immutable NewlineOrDedent dedented;
}

immutable(PathOrRelPath) parseImportPath(ref AllPaths allPaths, ref Lexer lexer) {
	immutable Opt!ushort nParents = () {
		if (tryTakeToken(lexer, Token.dot)) {
			takeOrAddDiagExpectedOperator(lexer, sym!"/", ParseDiag.Expected.Kind.slash);
			return some!ushort(0);
		} else if (tryTakeOperator(lexer, sym!"..")) {
			takeOrAddDiagExpectedOperator(lexer, sym!"/", ParseDiag.Expected.Kind.slash);
			return some(safeToUshort(takeDotDotSlashes(lexer, 1)));
		} else
			return none!ushort;
	}();
	return immutable PathOrRelPath(
		nParents,
		addPathComponents(allPaths, lexer, rootPath(allPaths, takePathComponent(lexer))));
}

immutable(size_t) takeDotDotSlashes(ref Lexer lexer, immutable size_t acc) {
	if (tryTakeOperator(lexer, sym!"..")) {
		takeOrAddDiagExpectedOperator(lexer, sym!"/", ParseDiag.Expected.Kind.slash);
		return takeDotDotSlashes(lexer, acc + 1);
	} else
		return acc;
}

immutable(Path) addPathComponents(ref AllPaths allPaths, ref Lexer lexer, immutable Path acc) =>
	tryTakeOperator(lexer, sym!"/")
		? addPathComponents(allPaths, lexer, childPath(allPaths, acc, takePathComponent(lexer)))
		: acc;

immutable(ImportAndDedent) parseSingleModuleImportOnOwnLine(ref AllPaths allPaths, ref Lexer lexer) {
	immutable Pos start = curPos(lexer);
	immutable PathOrRelPath path = parseImportPath(allPaths, lexer);
	immutable ImportOrExportKindAndDedent kind = parseImportOrExportKind(lexer, start);
	return immutable ImportAndDedent(immutable ImportOrExportAst(kind.range, path, kind.kind), kind.dedented);
}

immutable(ImportOrExportKindAndDedent) parseImportOrExportKind(ref Lexer lexer, immutable Pos start) {
	if (tryTakeToken(lexer, Token.colon)) {
		if (tryTakeIndent(lexer, 1))
			return parseIndentedImportNames(lexer, start);
		else {
			immutable Sym[] names = parseSingleImportNamesOnSingleLine(lexer);
			return immutable ImportOrExportKindAndDedent(
				immutable ImportOrExportAstKind(immutable ImportOrExportAstKind.ModuleNamed(names)),
				range(lexer, start),
				takeNewlineOrSingleDedent(lexer));
		}
	} else if (tryTakeToken(lexer, Token.as)) {
		immutable Sym name = takeName(lexer);
		immutable ImportFileType type = parseImportFileType(lexer);
		return immutable ImportOrExportKindAndDedent(
			immutable ImportOrExportAstKind(
				allocate(lexer.alloc, immutable ImportOrExportAstKind.File(name, type))),
			range(lexer, start),
			takeNewlineOrSingleDedent(lexer));
	}
	return immutable ImportOrExportKindAndDedent(
		immutable ImportOrExportAstKind(immutable ImportOrExportAstKind.ModuleWhole()),
		range(lexer, start),
		takeNewlineOrSingleDedent(lexer));
}

immutable(ImportFileType) parseImportFileType(ref Lexer lexer) {
	immutable Pos start = curPos(lexer);
	immutable TypeAst type = parseType(lexer);
	immutable Opt!(ImportFileType) fileType = toImportFileType(type);
	if (has(fileType))
		return force(fileType);
	else {
		addDiag(lexer, range(lexer, start), immutable ParseDiag(immutable ParseDiag.ImportFileTypeNotSupported()));
		return ImportFileType.str;
	}
}

immutable(Opt!(ImportFileType)) toImportFileType(immutable TypeAst a) =>
	matchTypeAst!(
		immutable Opt!(ImportFileType),
		(immutable(TypeAst.Dict)) =>
			none!(ImportFileType),
		(immutable(TypeAst.Fun)) =>
			none!(ImportFileType),
		(immutable TypeAst.InstStruct x) {
			switch (x.name.name.value) {
				case sym!"string".value:
					return empty(x.typeArgs)
						? some(ImportFileType.str)
						: none!ImportFileType;
				case sym!"array".value:
					return x.typeArgs.length == 1
						? matchTypeAst!(
							immutable Opt!(ImportFileType),
							(immutable(TypeAst.Dict)) =>
								none!(ImportFileType),
							(immutable(TypeAst.Fun)) =>
								none!(ImportFileType),
							(immutable TypeAst.InstStruct y) =>
								y.name.name == sym!"nat8" && empty(y.typeArgs)
									? some(ImportFileType.nat8Array)
									: none!(ImportFileType),
							(immutable(TypeAst.Suffix)) =>
								none!ImportFileType,
							(immutable TypeAst.Tuple) =>
								none!ImportFileType,
							)(x.typeArgs[0])
						: none!ImportFileType;
				default:
					return none!ImportFileType;
			}
		},
		(immutable TypeAst.Suffix) =>
			none!ImportFileType,
		(immutable TypeAst.Tuple) =>
			none!ImportFileType,
	)(a);

immutable(ImportOrExportKindAndDedent) parseIndentedImportNames(ref Lexer lexer, immutable Pos start) {
	ArrBuilder!Sym names;
	struct NewlineOrDedentAndRange {
		immutable NewlineOrDedent newlineOrDedent;
		immutable RangeWithinFile range;
	}
	immutable(NewlineOrDedentAndRange) recur() {
		immutable TrailingComma trailingComma = takeCommaSeparatedNames(lexer, names);
		immutable RangeWithinFile range0 = range(lexer, start);
		switch (takeNewlineOrDedentAmount(lexer, 2)) {
			case 0:
				final switch (trailingComma) {
					case TrailingComma.no:
						addDiag(lexer, range(lexer, start), immutable ParseDiag(
							immutable ParseDiag.Expected(ParseDiag.Expected.Kind.comma)));
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
				return immutable NewlineOrDedentAndRange(NewlineOrDedent.newline, range0);
			case 2:
				final switch (trailingComma) {
					case TrailingComma.no:
						break;
					case TrailingComma.yes:
						todo!void("!");
						break;
				}
				return immutable NewlineOrDedentAndRange(NewlineOrDedent.dedent, range0);
			default:
				return unreachable!(immutable NewlineOrDedentAndRange)();
		}
	}
	immutable NewlineOrDedentAndRange res = recur();
	return immutable ImportOrExportKindAndDedent(
		immutable ImportOrExportAstKind(immutable ImportOrExportAstKind.ModuleNamed(finishArr(lexer.alloc, names))),
		res.range,
		res.newlineOrDedent);
}

immutable(Sym[]) parseSingleImportNamesOnSingleLine(ref Lexer lexer) {
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

immutable(TrailingComma) takeCommaSeparatedNames(ref Lexer lexer, ref ArrBuilder!Sym names) {
	add(lexer.alloc, names, takeNameOrOperator(lexer));
	return tryTakeToken(lexer, Token.comma)
		? peekToken(lexer, Token.newline)
			? TrailingComma.yes
			: takeCommaSeparatedNames(lexer, names)
		: TrailingComma.no;
}

immutable(ParamAst) parseSingleParam(ref Lexer lexer) {
	immutable Pos start = curPos(lexer);
	immutable Opt!Sym name = takeNameOrUnderscore(lexer);
	immutable TypeAst type = parseType(lexer);
	return immutable ParamAst(range(lexer, start), name, type);
}

immutable(ParamsAst) parseParams(ref Lexer lexer) {
	if (!takeOrAddDiagExpectedToken(lexer, Token.parenLeft, ParseDiag.Expected.Kind.openParen)) {
		skipUntilNewlineNoDiag(lexer);
		return immutable ParamsAst([]);
	} else if (tryTakeToken(lexer, Token.parenRight))
		return immutable ParamsAst(emptySmallArray!ParamAst);
	else if (tryTakeToken(lexer, Token.dot3)) {
		immutable ParamAst param = parseSingleParam(lexer);
		takeOrAddDiagExpectedToken(lexer, Token.parenRight, ParseDiag.Expected.Kind.closingParen);
		return immutable ParamsAst(allocate(lexer.alloc, immutable ParamsAst.Varargs(param)));
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
		return immutable ParamsAst(finishArr(lexer.alloc, res));
	}
}

immutable(SpecSigAst) parseSpecSig(ref Lexer lexer) {
	// TODO: this doesn't work because the lexer already skipped comments
	immutable SafeCStr comment = skipBlankLinesAndGetDocComment(lexer);
	immutable Pos start = curPos(lexer);
	immutable Sym name = takeNameOrOperator(lexer);
	immutable TypeAst returnType = parseTypeNoTuple(lexer);
	immutable ParamsAst params = parseParams(lexer);
	return immutable SpecSigAst(comment, range(lexer, start), name, returnType, params);
}

immutable(SpecSigAst[]) parseIndentedSigs(ref Lexer lexer) {
	final switch (takeNewlineOrIndent_topLevel(lexer)) {
		case NewlineOrIndent.newline:
			return [];
		case NewlineOrIndent.indent:
			ArrBuilder!SpecSigAst res;
			for (;;) {
				immutable SpecSigAst sig = parseSpecSig(lexer);
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

immutable(StructDeclAst.Body.Enum.Member[]) parseEnumOrFlagsMembers(ref Lexer lexer) {
	final switch (takeNewlineOrIndent_topLevel(lexer)) {
		case NewlineOrIndent.newline:
			return [];
		case NewlineOrIndent.indent:
			ArrBuilder!(StructDeclAst.Body.Enum.Member) res;
			immutable(StructDeclAst.Body.Enum.Member[]) recur() {
				immutable Pos start = curPos(lexer);
				immutable Sym name = takeName(lexer);
				immutable Opt!LiteralIntOrNat value = () {
					if (tryTakeToken(lexer, Token.equal)) {
						if (tryTakeToken(lexer, Token.literalInt))
							return some(immutable LiteralIntOrNat(getCurLiteralInt(lexer)));
						else if (tryTakeToken(lexer, Token.literalNat))
							return some(immutable LiteralIntOrNat(getCurLiteralNat(lexer)));
						else {
							addDiagExpected(lexer, ParseDiag.Expected.Kind.literalIntOrNat);
							return none!LiteralIntOrNat;
						}
					} else
						return none!LiteralIntOrNat;
				}();
				add(lexer.alloc, res, immutable StructDeclAst.Body.Enum.Member(range(lexer, start), name, value));
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

immutable(StructDeclAst.Body.Record) parseRecordBody(ref Lexer lexer) {
	ArrBuilder!(StructDeclAst.Body.Record.Field) fields;
	final switch (takeNewlineOrIndent_topLevel(lexer)) {
		case NewlineOrIndent.newline:
			break;
		case NewlineOrIndent.indent:
			parseRecordFields(lexer, fields);
			break;
	}
	return immutable StructDeclAst.Body.Record(small(finishArr(lexer.alloc, fields)));
}

void parseRecordFields(ref Lexer lexer, ref ArrBuilder!(StructDeclAst.Body.Record.Field) res) {
	immutable Pos start = curPos(lexer);
	immutable Visibility visibility = tryTakePrivate(lexer);
	immutable Sym name = takeName(lexer);
	immutable FieldMutability mutability = parseFieldMutability(lexer);
	immutable TypeAst type = parseType(lexer);
	add(lexer.alloc, res,
		immutable StructDeclAst.Body.Record.Field(range(lexer, start), visibility, name, mutability, type));
	final switch (takeNewlineOrSingleDedent(lexer)) {
		case NewlineOrDedent.newline:
			parseRecordFields(lexer, res);
			break;
		case NewlineOrDedent.dedent:
			break;
	}
}

immutable(FieldMutability) parseFieldMutability(ref Lexer lexer) {
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

immutable(StructDeclAst.Body.Union.Member[]) parseUnionMembers(ref Lexer lexer) {
	ArrBuilder!(StructDeclAst.Body.Union.Member) res;
	do {
		immutable Pos start = curPos(lexer);
		immutable Sym name = takeName(lexer);
		immutable Opt!TypeAst type = peekToken(lexer, Token.newline) ? none!TypeAst : some(parseType(lexer));
		add(lexer.alloc, res, immutable StructDeclAst.Body.Union.Member(range(lexer, start), name, type));
	} while (takeNewlineOrSingleDedent(lexer) == NewlineOrDedent.newline);
	return finishArr(lexer.alloc, res);
}

immutable(FunDeclAst) parseFun(
	ref Lexer lexer,
	immutable SafeCStr docComment,
	immutable Visibility visibility,
	immutable Pos start,
	immutable Sym name,
	immutable NameAndRange[] typeParams,
) {
	immutable TypeAst returnType = parseTypeNoTuple(lexer);
	immutable ParamsAst params = parseParams(lexer);
	immutable FunModifierAst[] modifiers = parseFunModifiers(lexer.alloc, lexer);
	immutable Opt!ExprAst body_ = parseFunExprBody(lexer);
	return immutable FunDeclAst(
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

//TODO: use alloc from lexer
immutable(FunModifierAst[]) parseFunModifiers(scope ref Alloc alloc, ref Lexer lexer) {
	ArrBuilder!FunModifierAst res;
	while (!peekToken(lexer, Token.newline) && !peekToken(lexer, Token.EOF))
		parseFunModifier(lexer, res);
	return finishArr(lexer.alloc, res);
}

void parseFunModifier(ref Lexer lexer, scope ref ArrBuilder!FunModifierAst res) {
	immutable Pos start = curPos(lexer);
	immutable Token token = nextToken(lexer);
	immutable Opt!Sym name = () {
		switch (token) {
			case Token.builtin:
				return some(sym!"builtin");
			case Token.extern_:
				return some(sym!"extern");
			case Token.global:
				return some(sym!"global");
			case Token.noCtx:
				return some(sym!"noctx");
			case Token.noDoc:
				return some(sym!"no-doc");
			case Token.summon:
				return some(sym!"summon");
			case Token.unsafe:
				return some(sym!"unsafe");
			case Token.thread_local:
				return some(sym!"thread-local");
			case Token.trusted:
				return some(sym!"trusted");
			case Token.name:
				return some(getCurSym(lexer));
			default:
				addDiagUnexpectedCurToken(lexer, start, token);
				return none!Sym;
		}
	}();
	if (has(name)) {
		immutable TypeAst[] typeArgs = tryParseTypeArgsBracketed(lexer);
		return add(lexer.alloc, res, immutable FunModifierAst(
			immutable NameAndRange(start, force(name)),
			small(typeArgs)));
	}
}

void parseSpecOrStructOrFunOrTest(
	ref Lexer lexer,
	ref ArrBuilder!SpecDeclAst specs,
	ref ArrBuilder!StructAliasAst structAliases,
	ref ArrBuilder!StructDeclAst structs,
	ref ArrBuilder!FunDeclAst funs,
	ref ArrBuilder!TestAst tests,
	immutable SafeCStr docComment,
) {
	if (tryTakeToken(lexer, Token.test))
		add(lexer.alloc, tests, immutable TestAst(parseFunExprBody(lexer)));
	else
		parseSpecOrStructOrFun(lexer, specs, structAliases, structs, funs, docComment);
}

void parseSpecOrStructOrFun(
	ref Lexer lexer,
	ref ArrBuilder!SpecDeclAst specs,
	ref ArrBuilder!StructAliasAst structAliases,
	ref ArrBuilder!StructDeclAst structs,
	ref ArrBuilder!FunDeclAst funs,
	immutable SafeCStr docComment,
) {
	immutable Pos start = curPos(lexer);
	immutable Visibility visibility = tryTakePrivate(lexer);
	immutable Sym name = takeNameOrOperator(lexer);
	immutable NameAndRange[] typeParams = parseTypeParams(lexer);

	void addStruct(scope immutable(StructDeclAst.Body) delegate() @safe @nogc pure nothrow cb) {
		immutable ModifierAst[] modifiers = parseModifiers(lexer);
		immutable StructDeclAst.Body body_ = cb();
		add(lexer.alloc, structs, immutable StructDeclAst(
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
			immutable TypeAst target = () {
				final switch (takeNewlineOrIndent_topLevel(lexer)) {
					case NewlineOrIndent.newline:
						return bogusTypeAst(range(lexer, start));
					case NewlineOrIndent.indent:
						immutable TypeAst res = parseType(lexer);
						takeDedentFromIndent1(lexer);
						return res;
				}
			}();
			add(lexer.alloc, structAliases, immutable StructAliasAst(
				range(lexer, start),
				docComment,
				visibility,
				name,
				small(typeParams),
				target));
			break;
		case Token.builtin:
			nextToken(lexer);
			addStruct(() => immutable StructDeclAst.Body(immutable StructDeclAst.Body.Builtin()));
			takeNewline_topLevel(lexer);
			break;
		case Token.builtinSpec:
			nextToken(lexer);
			add(lexer.alloc, specs, immutable SpecDeclAst(
				range(lexer, start),
				docComment,
				visibility,
				name,
				small(typeParams),
				immutable SpecBodyAst(immutable SpecBodyAst.Builtin())));
			takeNewline_topLevel(lexer);
			break;
		case Token.enum_:
			nextToken(lexer);
			immutable Opt!(TypeAst*) typeArg = tryParseTypeArg(lexer);
			addStruct(() => immutable StructDeclAst.Body(
				immutable StructDeclAst.Body.Enum(typeArg, small(parseEnumOrFlagsMembers(lexer)))));
			break;
		case Token.extern_:
			nextToken(lexer);
			immutable StructDeclAst.Body.Extern body_ = parseExternType(lexer);
			addStruct(() => immutable StructDeclAst.Body(body_));
			takeNewline_topLevel(lexer);
			break;
		case Token.flags:
			nextToken(lexer);
			immutable Opt!(TypeAst*) typeArg = tryParseTypeArg(lexer);
			addStruct(() => immutable StructDeclAst.Body(
				immutable StructDeclAst.Body.Flags(typeArg, small(parseEnumOrFlagsMembers(lexer)))));
			break;
		case Token.record:
			nextToken(lexer);
			addStruct(() => immutable StructDeclAst.Body(parseRecordBody(lexer)));
			break;
		case Token.spec:
			nextToken(lexer);
			immutable SpecSigAst[] sigs = parseIndentedSigs(lexer);
			add(lexer.alloc, specs, immutable SpecDeclAst(
				range(lexer, start),
				docComment,
				visibility,
				name,
				small(typeParams),
				immutable SpecBodyAst(sigs)));
			break;
		case Token.union_:
			nextToken(lexer);
			addStruct(() =>
				immutable StructDeclAst.Body(immutable StructDeclAst.Body.Union(parseUnionMembersOrDiag(lexer))));
			break;
		default:
			add(lexer.alloc, funs, parseFun(lexer, docComment, visibility, start, name, typeParams));
			break;
	}
}

immutable(StructDeclAst.Body.Extern) parseExternType(ref Lexer lexer) {
	if (tryTakeToken(lexer, Token.parenLeft)) {
		immutable Opt!(LiteralNatAst*) size = parseNat(lexer);
		immutable Opt!(LiteralNatAst*) alignment = tryTakeToken(lexer, Token.comma)
			? parseNat(lexer)
			: none!(LiteralNatAst*);
		takeOrAddDiagExpectedToken(lexer, Token.parenRight, ParseDiag.Expected.Kind.closingParen);
		return immutable StructDeclAst.Body.Extern(size, alignment);
	} else
		return immutable StructDeclAst.Body.Extern(none!(LiteralNatAst*), none!(LiteralNatAst*));
}
immutable(Opt!(LiteralNatAst*)) parseNat(ref Lexer lexer) =>
	takeOrAddDiagExpectedToken(lexer, Token.literalNat, ParseDiag.Expected.Kind.literalNat)
		? some(allocate(lexer.alloc, getCurLiteralNat(lexer)))
		: none!(LiteralNatAst*);

immutable(StructDeclAst.Body.Union.Member[]) parseUnionMembersOrDiag(ref Lexer lexer) {
	final switch (takeNewlineOrIndent_topLevel(lexer)) {
		case NewlineOrIndent.newline:
			//TODO: this should be a checker error, not parse error
			addDiagAtChar(lexer, immutable ParseDiag(immutable ParseDiag.UnionCantBeEmpty()));
			return [];
		case NewlineOrIndent.indent:
			return parseUnionMembers(lexer);
	}
}

immutable(ModifierAst[]) parseModifiers(ref Lexer lexer) {
	ArrBuilder!ModifierAst res;
	parseModifiersRecur(lexer, res);
	return finishArr(lexer.alloc, res);
}
void parseModifiersRecur(ref Lexer lexer, ref ArrBuilder!ModifierAst res) {
	immutable Pos start = curPos(lexer);
	immutable Opt!(ModifierAst.Kind) kind = tryParseModifierKind(lexer);
	if (has(kind)) {
		add(lexer.alloc, res, immutable ModifierAst(start, force(kind)));
		return parseModifiersRecur(lexer, res);
	}
}

immutable(Opt!(ModifierAst.Kind)) tryParseModifierKind(ref Lexer lexer) {
	if (tryTakeToken(lexer, Token.dot)) {
		immutable Opt!Sym name = tryTakeName(lexer);
		if (!(has(name) && force(name) == sym!"new"))
			todo!void("diagnostic: expected 'new' after '.'");
		return some(ModifierAst.Kind.newPrivate);
	} else {
		immutable Opt!(ModifierAst.Kind) res = () {
			switch (getPeekToken(lexer)) {
				case Token.data:
					return some(ModifierAst.Kind.data);
				case Token.extern_:
					return some(ModifierAst.Kind.extern_);
				case Token.forceSendable:
					return some(ModifierAst.Kind.forceSendable);
				case Token.mut:
					return some(ModifierAst.Kind.mut);
				case Token.sendable:
					return some(ModifierAst.Kind.sendable);
				case Token.name:
					immutable Opt!(ModifierAst.Kind) kind = modifierKindFromSym(getCurSym(lexer));
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

immutable(Opt!(ModifierAst.Kind)) modifierKindFromSym(immutable Sym a) {
	switch (a.value) {
		case sym!"by-val".value:
			return some(ModifierAst.Kind.byVal);
		case sym!"by-ref".value:
			return some(ModifierAst.Kind.byRef);
		case sym!"new".value:
			return some(ModifierAst.Kind.newPublic);
		case sym!"packed".value:
			return some(ModifierAst.Kind.packed);
		default:
			return none!(ModifierAst.Kind);
	}
}

immutable(Visibility) tryTakePrivate(ref Lexer lexer) =>
	tryTakeToken(lexer, Token.dot) ? Visibility.private_ : Visibility.public_;

immutable(Opt!ImportsOrExportsAst) parseImportsOrExports(
	ref AllPaths allPaths,
	ref Lexer lexer,
	immutable Token keyword,
) {
	immutable Pos start = curPos(lexer);
	if (tryTakeToken(lexer, keyword)) {
		ArrBuilder!ImportOrExportAst res;
		if (takeIndentOrDiagTopLevel(lexer)) {
			void recur() {
				immutable ImportAndDedent id = parseSingleModuleImportOnOwnLine(allPaths, lexer);
				add(lexer.alloc, res, id.import_);
				if (id.dedented == NewlineOrDedent.newline)
					recur();
			}
			recur();
		}
		return some(immutable ImportsOrExportsAst(range(lexer, start), finishArr(lexer.alloc, res)));
	} else
		return none!ImportsOrExportsAst;
}

immutable(FileAst) parseFileInner(ref AllPaths allPaths, ref Lexer lexer) {
	immutable SafeCStr moduleDocComment = skipBlankLinesAndGetDocComment(lexer);
	immutable bool noStd = tryTakeToken(lexer, Token.noStd);
	if (noStd)
		takeOrAddDiagExpectedToken(lexer, Token.newline, ParseDiag.Expected.Kind.endOfLine);
	immutable Opt!ImportsOrExportsAst imports = parseImportsOrExports(allPaths, lexer, Token.import_);
	immutable Opt!ImportsOrExportsAst exports = parseImportsOrExports(allPaths, lexer, Token.export_);

	ArrBuilder!SpecDeclAst specs;
	ArrBuilder!StructAliasAst structAliases;
	ArrBuilder!StructDeclAst structs;
	ArrBuilder!FunDeclAst funs;
	ArrBuilder!TestAst tests;
	parseFileRecur(lexer, specs, structAliases, structs, funs, tests);
	return immutable FileAst(
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
	immutable SafeCStr docComment = skipBlankLinesAndGetDocComment(lexer);
	if (!tryTakeToken(lexer, Token.EOF)) {
		parseSpecOrStructOrFunOrTest(lexer, specs, structAliases, structs, funs, tests, docComment);
		parseFileRecur(lexer, specs, structAliases, structs, funs, tests);
	}
}
