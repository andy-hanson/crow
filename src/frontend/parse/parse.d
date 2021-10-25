module frontend.parse.parse;

@safe @nogc pure nothrow:

import frontend.parse.ast :
	ExplicitByValOrRef,
	ExplicitByValOrRefAndRange,
	ExprAst,
	FileAst,
	FunBodyAst,
	FunDeclAst,
	ImportAst,
	ImportsOrExportsAst,
	LiteralIntOrNat,
	NameAndRange,
	ParamAst,
	ParamsAst,
	PuritySpecifier,
	PuritySpecifierAndRange,
	RecordModifiers,
	SigAst,
	SpecBodyAst,
	SpecDeclAst,
	SpecUseAst,
	StructAliasAst,
	StructDeclAst,
	TestAst,
	TypeAst,
	withExplicitByValOrRef,
	withExplicitNewVisibility,
	withPacked;
import frontend.parse.lexer :
	addDiagAtChar,
	addDiagOnReservedName,
	createLexer,
	curChar,
	curPos,
	finishDiags,
	Lexer,
	NewlineOrDedent,
	NewlineOrIndent,
	peekExact,
	range,
	skipBlankLinesAndGetDocComment,
	skipUntilNewlineNoDiag,
	SymAndIsReserved,
	takeDedentFromIndent1,
	takeIndentOrDiagTopLevel,
	takeIndentOrDiagTopLevelAfterNewline,
	takeIndentOrFailGeneric,
	takeIntOrNat,
	takeName,
	takeNameAllowReserved,
	takeNameAndRange,
	takeNameAsTempStr,
	takeNewlineOrDedentAmount,
	takeNewlineOrIndent_topLevel,
	takeNewlineOrSingleDedent,
	takeOrAddDiagExpected,
	takeQuotedStr,
	tryTake,
	tryTakeIndentAfterNewline_topLevel;
import frontend.parse.parseExpr : parseFunExprBody;
import frontend.parse.parseType : parseType, takeTypeArgsEnd, tryParseTypeArgsBracketed;
import model.model : FieldMutability, Visibility;
import model.parseDiag : ParseDiag, ParseDiagnostic;
import util.alloc.alloc : Alloc;
import util.collection.arr : ArrWithSize, emptyArr, emptyArrWithSize;
import util.collection.arrBuilder : add, ArrBuilder, finishArr;
import util.collection.arrWithSizeBuilder : add, ArrWithSizeBuilder, arrWithSizeBuilderIsEmpty, finishArrWithSize;
import util.collection.str : CStr, NulTerminatedStr, SafeCStr;
import util.memory : allocate;
import util.opt : force, has, mapOption, none, nonePtr, Opt, optOr, OptPtr, some, somePtr;
import util.path : AbsOrRelPath, AllPaths, childPath, Path, rootPath;
import util.ptr : Ptr;
import util.sourceRange : Pos, RangeWithinFile;
import util.sym : AllSymbols, isSymOperator, shortSymAlphaLiteral, shortSymAlphaLiteralValue, Sym, symEq;
import util.types : Nat8;
import util.util : todo, unreachable, verify;

struct FileAstAndParseDiagnostics {
	immutable Ptr!FileAst ast;
	immutable ParseDiagnostic[] diagnostics;
}

immutable(FileAstAndParseDiagnostics) parseFile(
	ref Alloc alloc,
	ref AllPaths allPaths,
	ref AllSymbols allSymbols,
	immutable NulTerminatedStr source,
) {
	Lexer lexer = createLexer(alloc, allSymbols, source);
	immutable Ptr!FileAst ast = parseFileInner(alloc, allSymbols, allPaths, lexer);
	return immutable FileAstAndParseDiagnostics(ast, finishDiags(alloc, lexer));
}

private:

immutable(ArrWithSize!NameAndRange) parseTypeParams(
	ref Alloc alloc,
	ref AllSymbols allSymbols,
	ref Lexer lexer,
	immutable bool afterOperator,
) {
	if (afterOperator ? tryTake(lexer, " <") : tryTake(lexer, '<')) {
		ArrWithSizeBuilder!NameAndRange res;
		do {
			add(alloc, res, takeNameAndRange(alloc, allSymbols, lexer));
		} while (tryTake(lexer, ", "));
		takeTypeArgsEnd(alloc, lexer);
		return finishArrWithSize(alloc, res);
	} else
		return emptyArrWithSize!NameAndRange;
}

immutable(Opt!PuritySpecifierAndRange) parsePurity(ref Alloc alloc, ref Lexer lexer) {
	immutable Pos start = curPos(lexer);
	immutable Opt!PuritySpecifier specifier = () {
		if (tryTake(lexer, "data"))
			return some(PuritySpecifier.data);
		else if (tryTake(lexer, "mut"))
			return some(PuritySpecifier.mut);
		else if (tryTake(lexer, "sendable"))
			return some(PuritySpecifier.sendable);
		else if (tryTake(lexer, "force-data"))
			return some(PuritySpecifier.forceData);
		else if (tryTake(lexer, "force-sendable"))
			return some(PuritySpecifier.forceSendable);
		else {
			addDiagAtChar(alloc, lexer, immutable ParseDiag(
				immutable ParseDiag.Expected(ParseDiag.Expected.Kind.purity)));
			return none!PuritySpecifier;
		}
	}();
	return mapOption(specifier, (ref immutable PuritySpecifier it) =>
		immutable PuritySpecifierAndRange(start, it));
}

struct ImportAndDedent {
	immutable ImportAst import_;
	immutable NewlineOrDedent dedented;
}

struct NamesAndDedent {
	immutable Opt!(Sym[]) names;
	immutable RangeWithinFile range;
	immutable NewlineOrDedent dedented;
}

immutable(AbsOrRelPath) parseImportPath(
	ref Alloc alloc,
	ref AllPaths allPaths,
	ref Lexer lexer,
) {
	immutable Opt!Nat8 nParents = tryTake(lexer, "./")
		? some(immutable Nat8(0))
		: tryTake(lexer, "../")
		? some(takeDotDotSlashes(lexer, immutable Nat8(1)))
		: none!Nat8;
	return immutable AbsOrRelPath(
		nParents,
		addPathComponents(alloc, allPaths, lexer, rootPath(allPaths, takeNameAsTempStr(alloc, lexer).str)));
}

immutable(Nat8) takeDotDotSlashes(ref Lexer lexer, immutable Nat8 acc) {
	return tryTake(lexer, "../")
		? takeDotDotSlashes(lexer, acc + immutable Nat8(1))
		: acc;
}

immutable(Path) addPathComponents(
	ref Alloc alloc,
	ref AllPaths allPaths,
	ref Lexer lexer,
	immutable Path acc,
) {
	return tryTake(lexer, '/')
		? addPathComponents(alloc, allPaths, lexer, childPath(allPaths, acc, takeNameAsTempStr(alloc, lexer).str))
		: acc;
}

immutable(ImportAndDedent) parseSingleModuleImportOnOwnLine(
	ref Alloc alloc,
	ref AllSymbols allSymbols,
	ref AllPaths allPaths,
	ref Lexer lexer,
) {
	immutable Pos start = curPos(lexer);
	immutable AbsOrRelPath path = parseImportPath(alloc, allPaths, lexer);
	immutable NamesAndDedent names = () {
		if (tryTake(lexer, ':')) {
			if (tryTake(lexer, ' ')) {
				immutable Sym[] names = parseSingleImportNamesOnSingleLine(alloc, allSymbols, lexer);
				return immutable NamesAndDedent(
					some!(Sym[])(names),
					range(lexer, start),
					takeNewlineOrSingleDedent(alloc, lexer));
			} else
				return takeIndentOrFailGeneric!(immutable NamesAndDedent)(
					alloc,
					lexer,
					1,
					() =>
						parseIndentedImportNames(alloc, allSymbols, lexer, start),
					(immutable RangeWithinFile, immutable uint dedent) =>
						immutable NamesAndDedent(
							none!(Sym[]),
							range(lexer, start),
							newlineOrDedentFromNumber(dedent)));
		}
		return immutable NamesAndDedent(none!(Sym[]), range(lexer, start), takeNewlineOrSingleDedent(alloc, lexer));
	}();
	return immutable ImportAndDedent(immutable ImportAst(names.range, path, names.names), names.dedented);
}

immutable(NewlineOrDedent) newlineOrDedentFromNumber(immutable uint dedent) {
	switch (dedent) {
		case 0:
			return NewlineOrDedent.newline;
		case 1:
			return NewlineOrDedent.dedent;
		default:
			return unreachable!(immutable NewlineOrDedent)();
	}
}

immutable(NamesAndDedent) parseIndentedImportNames(
	ref Alloc alloc,
	ref AllSymbols allSymbols,
	ref Lexer lexer,
	immutable Pos start,
) {
	ArrBuilder!Sym names;
	struct NewlineOrDedentAndRange {
		immutable NewlineOrDedent newlineOrDedent;
		immutable RangeWithinFile range;
	}
	immutable(NewlineOrDedentAndRange) recur() {
		takeCommaSeparatedNames(alloc, allSymbols, lexer, names);
		immutable RangeWithinFile range0 = range(lexer, start);
		immutable bool trailingComma = tryTake(lexer, ',');
		switch (takeNewlineOrDedentAmount(alloc, lexer, 2)) {
			case 0:
				if (!trailingComma)
					todo!void("!");
				return recur();
			case 1:
				if (trailingComma)
					todo!void("!");
				return immutable NewlineOrDedentAndRange(NewlineOrDedent.newline, range0);
			case 2:
				if (trailingComma)
					todo!void("!");
				return immutable NewlineOrDedentAndRange(NewlineOrDedent.dedent, range0);
			default:
				return unreachable!(immutable NewlineOrDedentAndRange)();
		}
	}
	immutable NewlineOrDedentAndRange res = recur();
	return immutable NamesAndDedent(some!(Sym[])(finishArr(alloc, names)), res.range, res.newlineOrDedent);
}

immutable(Sym[]) parseSingleImportNamesOnSingleLine(
	ref Alloc alloc,
	ref AllSymbols allSymbols,
	ref Lexer lexer,
) {
	ArrBuilder!Sym names;
	takeCommaSeparatedNames(alloc, allSymbols, lexer, names);
	return finishArr(alloc, names);
}

void takeCommaSeparatedNames(
	ref Alloc alloc,
	ref AllSymbols allSymbols,
	ref Lexer lexer,
	ref ArrBuilder!Sym names,
) {
	add(alloc, names, takeName(alloc, allSymbols, lexer));
	if (tryTake(lexer, ", "))
		takeCommaSeparatedNames(alloc, allSymbols, lexer, names);
}

struct ParamsAndMaybeDedent {
	immutable ParamsAst params;
	// 0 if we took a newline but it didn't change the indent level from before parsing params.
	immutable Opt!size_t dedents;
}

immutable(ParamAst) parseSingleParam(ref Alloc alloc, ref AllSymbols allSymbols, ref Lexer lexer) {
	immutable Pos start = curPos(lexer);
	immutable Opt!Sym name = tryTake(lexer, '_')
		? none!Sym
		: some(takeName(alloc, allSymbols, lexer));
	takeOrAddDiagExpected(alloc, lexer, ' ', ParseDiag.Expected.Kind.space);
	immutable TypeAst type = parseType(alloc, allSymbols, lexer);
	return immutable ParamAst(range(lexer, start), name, type);
}

immutable(ParamsAst) parseParenthesizedParams(
	ref Alloc alloc,
	ref AllSymbols allSymbols,
	ref Lexer lexer,
) {
	if (tryTake(lexer, ')'))
		return immutable ParamsAst(emptyArrWithSize!ParamAst);
	else if (tryTake(lexer, "...")) {
		immutable ParamAst param = parseSingleParam(alloc, allSymbols, lexer);
		takeOrAddDiagExpected(alloc, lexer, ')', ParseDiag.Expected.Kind.closingParen);
		return immutable ParamsAst(allocate(alloc, immutable ParamsAst.Varargs(param)));
	} else {
		ArrWithSizeBuilder!ParamAst res;
		for (;;) {
			add(alloc, res, parseSingleParam(alloc, allSymbols, lexer));
			if (tryTake(lexer, ')'))
				break;
			if (!takeOrAddDiagExpected(alloc, lexer, ", ", ParseDiag.Expected.Kind.comma)) {
				skipUntilNewlineNoDiag(lexer);
				break;
			}
		}
		return immutable ParamsAst(finishArrWithSize(alloc, res));
	}
}

immutable(ParamsAndMaybeDedent) parseIndentedParams(ref Alloc alloc, ref AllSymbols allSymbols, ref Lexer lexer) {
	ArrWithSizeBuilder!ParamAst res;
	for (;;) {
		add(alloc, res, parseSingleParam(alloc, allSymbols, lexer));
		immutable size_t dedents = takeNewlineOrDedentAmount(alloc, lexer, 1);
		if (dedents != 0)
			return immutable ParamsAndMaybeDedent(
				immutable ParamsAst(finishArrWithSize(alloc, res)),
				some(dedents - 1));
	}
}

immutable(ParamsAndMaybeDedent) parseParams(ref Alloc alloc, ref AllSymbols allSymbols, ref Lexer lexer) {
	if (tryTake(lexer, '('))
		return ParamsAndMaybeDedent(parseParenthesizedParams(alloc, allSymbols, lexer), none!size_t);
	else
		final switch (takeNewlineOrIndent_topLevel(alloc, lexer)) {
			case NewlineOrIndent.newline:
				return immutable ParamsAndMaybeDedent(immutable ParamsAst(emptyArrWithSize!ParamAst), some!size_t(0));
			case NewlineOrIndent.indent:
				return parseIndentedParams(alloc, allSymbols, lexer);
		}
}

struct SigAstAndMaybeDedent {
	immutable Ptr!SigAst sig;
	immutable Opt!size_t dedents;
}

struct SigAstAndDedent {
	immutable SigAst sig;
	immutable size_t dedents;
}

immutable(SigAstAndMaybeDedent) parseSigAfterNameAndSpace(
	ref Alloc alloc,
	ref AllSymbols allSymbols,
	ref Lexer lexer,
	immutable Pos start,
	immutable Sym name,
) {
	immutable TypeAst returnType = parseType(alloc, allSymbols, lexer);
	immutable ParamsAndMaybeDedent params = parseParams(alloc, allSymbols, lexer);
	immutable SigAst sigAst = allocate(alloc, immutable SigAst(range(lexer, start), name, returnType, params.params));
	return immutable SigAstAndMaybeDedent(allocate(alloc, sigAst), params.dedents);
}

immutable(SigAstAndDedent) parseSig(
	ref Alloc alloc,
	ref AllSymbols allSymbols,
	ref Lexer lexer,
	immutable uint curIndent,
) {
	immutable Pos start = curPos(lexer);
	immutable Sym sigName = takeName(alloc, allSymbols, lexer);
	takeOrAddDiagExpected(alloc, lexer, ' ', ParseDiag.Expected.Kind.space);
	immutable SigAstAndMaybeDedent s = parseSigAfterNameAndSpace(alloc, allSymbols, lexer, start, sigName);
	immutable size_t dedents = has(s.dedents) ? force(s.dedents) : takeNewlineOrDedentAmount(alloc, lexer, curIndent);
	return SigAstAndDedent(s.sig, dedents);
}

immutable(SigAst[]) parseIndentedSigs(ref Alloc alloc, ref AllSymbols allSymbols, ref Lexer lexer) {
	ArrBuilder!SigAst res;
	for (;;) {
		immutable SigAstAndDedent sd = parseSig(alloc, allSymbols, lexer, 1);
		add(alloc, res, sd.sig);
		if (sd.dedents != 0) {
			// We started at in indent level of only 1, so can't go down more than 1.
			verify(sd.dedents == 1);
			return finishArr(alloc, res);
		}
	}
}

enum SpaceOrNewlineOrIndent {
	space,
	newline,
	indent,
}

enum NonFunKeyword {
	alias_,
	builtin,
	builtinSpec,
	enum_,
	flags,
	externPtr,
	record,
	spec,
	union_,
}

struct NonFunKeywordAndIndent {
	immutable NonFunKeyword keyword;
	immutable OptPtr!TypeAst typeArgument; // only parsed for enum
	immutable SpaceOrNewlineOrIndent after;
}

SpaceOrNewlineOrIndent spaceOrNewlineOrIndentFromNewlineOrIndent(immutable NewlineOrIndent ni) {
	final switch (ni) {
		case NewlineOrIndent.newline:
			return SpaceOrNewlineOrIndent.newline;
		case NewlineOrIndent.indent:
			return SpaceOrNewlineOrIndent.indent;
	}
}

immutable(Opt!NonFunKeywordAndIndent) tryTakeKw(
	ref Alloc alloc,
	ref Lexer lexer,
	immutable CStr kwSpace,
	immutable CStr kwNl,
	immutable NonFunKeyword keyword
) {
	return tryTake(lexer, kwSpace)
		? some(immutable NonFunKeywordAndIndent(keyword, nonePtr!TypeAst, SpaceOrNewlineOrIndent.space))
		: tryTake(lexer, kwNl)
		? some(immutable NonFunKeywordAndIndent(
			keyword,
			nonePtr!TypeAst,
			spaceOrNewlineOrIndentFromNewlineOrIndent(tryTakeIndentAfterNewline_topLevel(alloc, lexer))))
		: none!NonFunKeywordAndIndent;
}

immutable(Opt!NonFunKeywordAndIndent) parseNonFunKeyword(ref Alloc alloc, ref AllSymbols allSymbols, ref Lexer lexer) {
	switch (curChar(lexer)) {
		case 'a':
			return tryTakeKw(alloc, lexer, "alias ", "alias\n", NonFunKeyword.alias_);
		case 'b':
			immutable Opt!NonFunKeywordAndIndent res =
				tryTakeKw(alloc, lexer, "builtin ", "builtin\n", NonFunKeyword.builtin);
			return has(res)
				? res
				: tryTakeKw(alloc, lexer, "builtin-spec ", "builtin-spec\n", NonFunKeyword.builtinSpec);
		case 'e':
			if (tryTake(lexer, "enum<"))
				return some(parseEnumTypeArgAndAfter(alloc, allSymbols, lexer, NonFunKeyword.enum_));
			else {
				immutable Opt!NonFunKeywordAndIndent res =
					tryTakeKw(alloc, lexer, "enum ", "enum\n", NonFunKeyword.enum_);
				return has(res)
					? res
					: tryTakeKw(alloc, lexer, "extern-ptr ", "extern-ptr\n", NonFunKeyword.externPtr);
			}
		case 'f':
			return tryTake(lexer, "flags<")
				? some(parseEnumTypeArgAndAfter(alloc, allSymbols, lexer, NonFunKeyword.flags))
				: tryTakeKw(alloc, lexer, "flags ", "flags\n", NonFunKeyword.flags);
		case 'r':
			return tryTakeKw(alloc, lexer, "record ", "record\n", NonFunKeyword.record);
		case 's':
			return tryTakeKw(alloc, lexer, "spec ", "spec\n", NonFunKeyword.spec);
		case 'u':
			return tryTakeKw(alloc, lexer, "union ", "union\n", NonFunKeyword.union_);
		default:
			return none!NonFunKeywordAndIndent;
	}
}

immutable(NonFunKeywordAndIndent) parseEnumTypeArgAndAfter(
	ref Alloc alloc,
	ref AllSymbols allSymbols,
	ref Lexer lexer,
	immutable NonFunKeyword kw,
) {
	immutable TypeAst typeArg = parseType(alloc, allSymbols, lexer);
	takeTypeArgsEnd(alloc, lexer);
	immutable SpaceOrNewlineOrIndent after = tryTake(lexer, ' ')
		? SpaceOrNewlineOrIndent.space
		: spaceOrNewlineOrIndentFromNewlineOrIndent(takeNewlineOrIndent_topLevel(alloc, lexer));
	return immutable NonFunKeywordAndIndent(kw, somePtr(allocate(alloc, typeArg)), after);
}

immutable(ArrWithSize!(StructDeclAst.Body.Enum.Member)) parseEnumOrFlagsMembers(
	ref Alloc alloc,
	ref AllSymbols allSymbols,
	ref Lexer lexer,
) {
	ArrWithSizeBuilder!(StructDeclAst.Body.Enum.Member) res;
	immutable(ArrWithSize!(StructDeclAst.Body.Enum.Member)) recur() {
		immutable Pos start = curPos(lexer);
		immutable Sym name = takeName(alloc, allSymbols, lexer);
		immutable Opt!LiteralIntOrNat value = tryTake(lexer, " = ")
			? some(takeIntOrNat(lexer))
			: none!LiteralIntOrNat;
		add(alloc, res, immutable StructDeclAst.Body.Enum.Member(range(lexer, start), name, value));
		final switch (takeNewlineOrSingleDedent(alloc, lexer)) {
			case NewlineOrDedent.newline:
				return recur();
			case NewlineOrDedent.dedent:
				return finishArrWithSize(alloc, res);
		}
	}
	return recur();
}

immutable(StructDeclAst.Body.Record) parseRecordBody(
	ref Alloc alloc,
	ref AllSymbols allSymbols,
	ref Lexer lexer,
) {
	ArrWithSizeBuilder!(StructDeclAst.Body.Record.Field) res;
	pure immutable(StructDeclAst.Body.Record) recur(immutable RecordModifiers prevModifiers) {
		immutable Pos start = curPos(lexer);
		immutable Visibility visibility = tryTakePrivate(lexer);
		immutable Sym name = takeName(alloc, allSymbols, lexer);
		immutable RecordModifiers newModifiers = () {
			switch (name.value) {
				case shortSymAlphaLiteralValue("new"):
					if (!arrWithSizeBuilderIsEmpty(res))
						todo!void("'.new' on later line");
					if (has(prevModifiers.explicitNewVisibility))
						todo!void("specified new visibility multiple times");
					return withExplicitNewVisibility(prevModifiers, visibility);
				case shortSymAlphaLiteralValue("by-val"):
				case shortSymAlphaLiteralValue("by-ref"):
					if (visibility == Visibility.private_) todo!void("diagnostic");
					immutable ExplicitByValOrRef value = name.value == shortSymAlphaLiteralValue("by-val")
						? ExplicitByValOrRef.byVal
						: ExplicitByValOrRef.byRef;
					if (has(prevModifiers.explicitByValOrRef) || !arrWithSizeBuilderIsEmpty(res))
						todo!void("by-val or by-ref on later line");
					return withExplicitByValOrRef(prevModifiers, immutable ExplicitByValOrRefAndRange(start, value));
				case shortSymAlphaLiteralValue("packed"):
					if (visibility == Visibility.private_) todo!void("diagnostic");
					if (has(prevModifiers.packed) || !arrWithSizeBuilderIsEmpty(res))
						todo!void("'packed' on later line");
					return withPacked(prevModifiers, start);
				default:
					takeOrAddDiagExpected(alloc, lexer, ' ', ParseDiag.Expected.Kind.space);
					immutable FieldMutability mutability = parseFieldMutability(lexer);
					immutable TypeAst type = parseType(alloc, allSymbols, lexer);
					add(alloc, res, immutable StructDeclAst.Body.Record.Field(
						range(lexer, start), visibility, name, mutability, type));
					return prevModifiers;
			}
		}();
		final switch (takeNewlineOrSingleDedent(alloc, lexer)) {
			case NewlineOrDedent.newline:
				return recur(newModifiers);
			case NewlineOrDedent.dedent:
				return immutable StructDeclAst.Body.Record(
					newModifiers.any() ? somePtr(allocate(alloc, newModifiers)) : nonePtr!RecordModifiers,
					finishArrWithSize(alloc, res));
		}
	}
	return recur(immutable RecordModifiers(none!Visibility, none!Pos, none!ExplicitByValOrRefAndRange));
}

immutable(FieldMutability) parseFieldMutability(ref Lexer lexer) {
	return tryTake(lexer, "mut ")
		? FieldMutability.public_
		: tryTake(lexer, ".mut ")
		? FieldMutability.private_
		: FieldMutability.const_;
}

immutable(StructDeclAst.Body.Union.Member[]) parseUnionMembers(
	ref Alloc alloc,
	ref AllSymbols allSymbols,
	ref Lexer lexer,
) {
	ArrBuilder!(StructDeclAst.Body.Union.Member) res;
	do {
		immutable Pos start = curPos(lexer);
		immutable Sym name = takeName(alloc, allSymbols, lexer);
		immutable Opt!TypeAst type = tryTake(lexer, ' ') ? some(parseType(alloc, allSymbols, lexer)) : none!TypeAst;
		add(alloc, res, immutable StructDeclAst.Body.Union.Member(range(lexer, start), name, type));
	} while (takeNewlineOrSingleDedent(alloc, lexer) == NewlineOrDedent.newline);
	return finishArr(alloc, res);
}

struct SpecUsesAndSigFlagsAndKwBody {
	immutable SpecUseAst[] specUses;
	immutable bool noCtx;
	immutable bool summon;
	immutable bool unsafe;
	immutable bool trusted;
	immutable Opt!(Ptr!FunBodyAst) body_; // none for 'builtin' or 'extern'
}

immutable(SpecUsesAndSigFlagsAndKwBody) emptySpecUsesAndSigFlagsAndKwBody =
	immutable SpecUsesAndSigFlagsAndKwBody(
		[],
		false,
		false,
		false,
		false,
		none!(Ptr!FunBodyAst));

immutable(FunBodyAst.Extern) takeExternName(
	ref Alloc alloc,
	ref Lexer lexer,
	immutable bool isGlobal,
) {
	immutable Opt!string libraryName = tryTake(lexer, '<') ? some(takeExternLibraryName(alloc, lexer)) : none!string;
	return immutable FunBodyAst.Extern(isGlobal, libraryName);
}

immutable(string) takeExternLibraryName(ref Alloc alloc, ref Lexer lexer) {
	immutable string res = takeQuotedStr(lexer, alloc);
	takeTypeArgsEnd(alloc, lexer);
	return res;
}

immutable(SpecUsesAndSigFlagsAndKwBody) parseNextSpec(
	ref Alloc alloc,
	ref AllSymbols allSymbols,
	ref Lexer lexer,
	ref ArrBuilder!SpecUseAst specUses,
	immutable bool noCtx,
	immutable bool summon,
	immutable bool unsafe,
	immutable bool trusted,
	immutable bool builtin,
	immutable Opt!(FunBodyAst.Extern) extern_,
	immutable Opt!string mangle,
	scope immutable(bool) delegate() @safe @nogc pure nothrow canTakeNext,
) {
	immutable Pos start = curPos(lexer);
	immutable SymAndIsReserved name = takeNameAllowReserved(alloc, allSymbols, lexer);
	if (name.isReserved) {
		scope immutable(SpecUsesAndSigFlagsAndKwBody) setExtern(immutable bool isGlobal) {
			if (has(extern_))
				todo!void("duplicate");
			immutable Opt!(FunBodyAst.Extern) extern2 = some(takeExternName(alloc, lexer, isGlobal));
			return nextSpecOrStop(
				alloc, allSymbols, lexer,
				specUses, noCtx, summon, unsafe, trusted, builtin, extern2, mangle, canTakeNext);
		}
		switch (name.name.name.value) {
			case shortSymAlphaLiteralValue("noctx"):
				if (noCtx) todo!void("duplicate");
				return nextSpecOrStop(
					alloc, allSymbols, lexer,
					specUses, true, summon, unsafe, trusted, builtin, extern_, mangle, canTakeNext);
			case shortSymAlphaLiteralValue("summon"):
				if (summon) todo!void("duplicate");
				return nextSpecOrStop(
					alloc, allSymbols, lexer,
					specUses, noCtx, true, unsafe, trusted, builtin, extern_, mangle, canTakeNext);
			case shortSymAlphaLiteralValue("unsafe"):
				if (unsafe) todo!void("duplicate");
				return nextSpecOrStop(
					alloc, allSymbols,
					lexer, specUses, noCtx, summon, true, trusted, builtin, extern_, mangle, canTakeNext);
			case shortSymAlphaLiteralValue("trusted"):
				if (trusted) todo!void("duplicate");
				return nextSpecOrStop(
					alloc, allSymbols, lexer,
					specUses, noCtx, summon, unsafe, true, builtin, extern_, mangle, canTakeNext);
			case shortSymAlphaLiteralValue("builtin"):
				if (builtin) todo!void("duplicate");
				return nextSpecOrStop(
					alloc, allSymbols, lexer,
					specUses, noCtx, summon, unsafe, trusted, true, extern_, mangle, canTakeNext);
			case shortSymAlphaLiteralValue("extern"):
				return setExtern(false);
			case shortSymAlphaLiteralValue("global"):
				return setExtern(true);
			default: {
				addDiagOnReservedName(alloc, lexer, name.name);
				return nextSpecOrStop(
					alloc, allSymbols, lexer,
					specUses, noCtx, summon, unsafe, trusted, builtin, extern_, mangle, canTakeNext);
			}
		}
	} else {
		immutable ArrWithSize!TypeAst typeArgs = tryParseTypeArgsBracketed(alloc, allSymbols, lexer);
		add(alloc, specUses, immutable SpecUseAst(range(lexer, start), name.name, typeArgs));
		return nextSpecOrStop(
			alloc, allSymbols, lexer, specUses, noCtx, summon, unsafe, trusted, builtin, extern_, mangle, canTakeNext);
	}
}

immutable(SpecUsesAndSigFlagsAndKwBody) nextSpecOrStop(
	ref Alloc alloc,
	ref AllSymbols allSymbols,
	ref Lexer lexer,
	ref ArrBuilder!SpecUseAst specUses,
	immutable bool noCtx,
	immutable bool summon,
	immutable bool unsafe,
	immutable bool trusted,
	immutable bool builtin,
	immutable Opt!(FunBodyAst.Extern) extern_,
	immutable Opt!string mangle,
	scope immutable(bool) delegate() @safe @nogc pure nothrow canTakeNext,
) {
	if (canTakeNext())
		return parseNextSpec(
			alloc, allSymbols, lexer, specUses, noCtx, summon, unsafe, trusted, builtin, extern_, mangle, canTakeNext);
	else {
		if (unsafe && trusted)
			todo!void("'unsafe trusted' is redundant");
		if (builtin && trusted)
			todo!void("'builtin trusted' is silly as builtin fun has no body");
		if (has(extern_) && trusted)
			todo!void("'extern trusted' is silly as extern fun has no body");

		//TODO: assert 'builtin' and 'extern' and 'extern-global' can't be set together.
		//Also, 'extern-global' should always be 'unsafe noctx'
		immutable Opt!(Ptr!FunBodyAst) body_ = builtin
			? some(allocate(alloc, immutable FunBodyAst(immutable FunBodyAst.Builtin())))
			: has(extern_)
			? some(allocate(alloc, immutable FunBodyAst(extern_.force)))
			: none!(Ptr!FunBodyAst);
		return SpecUsesAndSigFlagsAndKwBody(finishArr(alloc, specUses), noCtx, summon, unsafe, trusted, body_);
	}
}

// TODO: handle 'noctx' and friends too! (share code with parseSpecUsesAndSigFlagsAndKwBody)
immutable(SpecUsesAndSigFlagsAndKwBody) parseIndentedSpecUses(
	ref Alloc alloc,
	ref AllSymbols allSymbols,
	ref Lexer lexer,
) {
	if (takeIndentOrDiagTopLevel(alloc, lexer)) {
		ArrBuilder!SpecUseAst builder;
		return parseNextSpec(
			alloc,
			allSymbols,
			lexer,
			builder,
			false,
			false,
			false,
			false,
			false,
			none!(FunBodyAst.Extern),
			none!string,
			() => takeNewlineOrSingleDedent(alloc, lexer) == NewlineOrDedent.newline);
	} else
		return immutable SpecUsesAndSigFlagsAndKwBody(
			emptyArr!SpecUseAst,
			false,
			false,
			false,
			false,
			none!(Ptr!FunBodyAst));
}

immutable(SpecUsesAndSigFlagsAndKwBody) parseSpecUsesAndSigFlagsAndKwBody(
	ref Alloc alloc,
	ref AllSymbols allSymbols,
	ref Lexer lexer,
) {
	// Unlike indented specs, we check for a separator on first spec, so use nextSpecOrStop instead of parseNextSpec
	ArrBuilder!SpecUseAst builder;
	return nextSpecOrStop(
		alloc,
		allSymbols,
		lexer,
		builder,
		false,
		false,
		false,
		false,
		false,
		none!(FunBodyAst.Extern),
		none!string,
		() => tryTake(lexer, ' '));
}

//TODO:RENAME
struct FunDeclStuff {
	immutable SpecUsesAndSigFlagsAndKwBody extra;
	immutable Ptr!FunBodyAst body_;
}

immutable(FunDeclAst) parseFun(
	ref Alloc alloc,
	ref AllSymbols allSymbols,
	ref Lexer lexer,
	immutable SafeCStr docComment,
	immutable Visibility visibility,
	immutable Pos start,
	immutable Sym name,
	immutable ArrWithSize!NameAndRange typeParams,
) {
	immutable SigAstAndMaybeDedent sig = parseSigAfterNameAndSpace(alloc, allSymbols, lexer, start, name);
	immutable FunDeclStuff stuff = () {
		if (has(sig.dedents)) {
			// Started at indent of 0
			verify(force(sig.dedents) == 0);
			immutable SpecUsesAndSigFlagsAndKwBody extra = tryTake(lexer, "spec")
				? parseIndentedSpecUses(alloc, allSymbols, lexer)
				: emptySpecUsesAndSigFlagsAndKwBody;
			immutable Ptr!FunBodyAst body_ = optOr(extra.body_, () {
				takeOrAddDiagExpected(alloc, lexer, "body", ParseDiag.Expected.Kind.bodyKeyword);
				return allocate(alloc, immutable FunBodyAst(parseFunExprBody(alloc, allSymbols, lexer)));
			});
			return immutable FunDeclStuff(extra, body_);
		} else {
			immutable SpecUsesAndSigFlagsAndKwBody extra = parseSpecUsesAndSigFlagsAndKwBody(alloc, allSymbols, lexer);
			immutable Ptr!FunBodyAst body_ = optOr(extra.body_, () =>
				allocate(alloc, immutable FunBodyAst(parseFunExprBody(alloc, allSymbols, lexer))));
			return immutable FunDeclStuff(extra, body_);
		}
	}();
	immutable SpecUsesAndSigFlagsAndKwBody extra = stuff.extra;
	return immutable FunDeclAst(
		range(lexer, start),
		docComment,
		typeParams,
		sig.sig,
		extra.specUses,
		visibility,
		extra.noCtx,
		extra.summon,
		extra.unsafe,
		extra.trusted,
		stuff.body_);
}

void parseSpecOrStructOrFunOrTest(
	ref Alloc alloc,
	ref AllSymbols allSymbols,
	ref Lexer lexer,
	ref ArrBuilder!SpecDeclAst specs,
	ref ArrBuilder!StructAliasAst structAliases,
	ref ArrBuilder!StructDeclAst structs,
	ref ArrBuilder!FunDeclAst funs,
	ref ArrBuilder!TestAst tests,
	immutable SafeCStr docComment,
) {
	immutable Pos start = curPos(lexer);
	// '..' is always public
	immutable Visibility visibility = peekExact(lexer, "..") ? Visibility.public_ : tryTakePrivate(lexer);
	immutable Sym name = takeName(alloc, allSymbols, lexer);
	immutable ArrWithSize!NameAndRange typeParams = parseTypeParams(alloc, allSymbols, lexer, isSymOperator(name));
	if (!tryTake(lexer, ' ')) {
		if (symEq(name, shortSymAlphaLiteral("test"))) {
			immutable ExprAst body_ = parseFunExprBody(alloc, allSymbols, lexer);
			add(alloc, tests, immutable TestAst(body_));
		} else {
			addDiagAtChar(alloc, lexer, immutable ParseDiag(
				immutable ParseDiag.Expected(ParseDiag.Expected.Kind.space)));
			skipUntilNewlineNoDiag(lexer);
		}
	} else {
		immutable Opt!NonFunKeywordAndIndent opKwAndIndent = parseNonFunKeyword(alloc, allSymbols, lexer);
		if (has(opKwAndIndent))
			handleNonFunKeywordAndIndent(
				alloc, allSymbols, lexer, specs, structAliases, structs, docComment, start,
				visibility, name, typeParams, force(opKwAndIndent));
		else
			add(alloc, funs, parseFun(alloc, allSymbols, lexer, docComment, visibility, start, name, typeParams));
	}
}

immutable(Visibility) tryTakePrivate(ref Lexer lexer) {
	return tryTake(lexer, '.') ? Visibility.private_ : Visibility.public_;
}

void handleNonFunKeywordAndIndent(
	ref Alloc alloc,
	ref AllSymbols allSymbols,
	ref Lexer lexer,
	ref ArrBuilder!SpecDeclAst specs,
	ref ArrBuilder!StructAliasAst structAliases,
	ref ArrBuilder!StructDeclAst structs,
	immutable SafeCStr docComment,
	immutable Pos start,
	immutable Visibility visibility,
	immutable Sym name,
	immutable ArrWithSize!NameAndRange typeParams,
	immutable NonFunKeywordAndIndent kwAndIndent,
) {
	immutable NonFunKeyword kw = kwAndIndent.keyword;
	immutable OptPtr!TypeAst typeArg = kwAndIndent.typeArgument;
	immutable SpaceOrNewlineOrIndent after = kwAndIndent.after;
	immutable Opt!PuritySpecifierAndRange purity = after == SpaceOrNewlineOrIndent.space
		? parsePurity(alloc, lexer)
		: none!PuritySpecifierAndRange;

	immutable bool tookIndent = () {
		final switch (after) {
			case SpaceOrNewlineOrIndent.space:
				return takeNewlineOrIndent_topLevel(alloc, lexer) == NewlineOrIndent.indent;
			case SpaceOrNewlineOrIndent.newline:
				return false;
			case SpaceOrNewlineOrIndent.indent:
				return true;
		}
	}();

	final switch (kw) {
		case NonFunKeyword.alias_:
			if (!tookIndent)
				todo!void("always indent alias");
			if (has(purity))
				todo!void("alias shouldn't have purity");
			immutable Ptr!TypeAst target = allocate(alloc, parseType(alloc, allSymbols, lexer));
			takeDedentFromIndent1(alloc, lexer);
			add(
				alloc,
				structAliases,
				immutable StructAliasAst(range(lexer, start), docComment, visibility, name, typeParams, target));
			break;
		case NonFunKeyword.builtinSpec:
			if (tookIndent)
				todo!void("builtin-spec has no body");
			if (has(purity))
				todo!void("spec shouldn't have purity");
			add(alloc, specs, immutable SpecDeclAst(
				range(lexer, start),
				docComment,
				visibility,
				name,
				typeParams,
				SpecBodyAst(SpecBodyAst.Builtin())));
			break;
		case NonFunKeyword.spec:
			if (!tookIndent)
				todo!void("always indent spec");
			if (has(purity))
				todo!void("spec shouldn't have purity");
			immutable SigAst[] sigs = parseIndentedSigs(alloc, allSymbols, lexer);
			add(
				alloc,
				specs,
				immutable SpecDeclAst(
					range(lexer, start),
					docComment,
					visibility,
					name,
					typeParams,
					immutable SpecBodyAst(sigs)));
			break;
		case NonFunKeyword.builtin:
		case NonFunKeyword.enum_:
		case NonFunKeyword.flags:
		case NonFunKeyword.externPtr:
		case NonFunKeyword.record:
		case NonFunKeyword.union_:
			immutable StructDeclAst.Body body_ = () {
				final switch (kw) {
					case NonFunKeyword.alias_:
					case NonFunKeyword.builtinSpec:
					case NonFunKeyword.spec:
						return unreachable!(immutable StructDeclAst.Body);
					case NonFunKeyword.builtin:
						if (tookIndent)
							todo!void("shouldn't indent after builtin");
						return immutable StructDeclAst.Body(immutable StructDeclAst.Body.Builtin());
					case NonFunKeyword.enum_:
						return immutable StructDeclAst.Body(immutable StructDeclAst.Body.Enum(
							typeArg,
							tookIndent
								? parseEnumOrFlagsMembers(alloc, allSymbols, lexer)
								: emptyArrWithSize!(StructDeclAst.Body.Enum.Member)));
					case NonFunKeyword.flags:
						return immutable StructDeclAst.Body(immutable StructDeclAst.Body.Flags(
							typeArg,
							tookIndent
								? parseEnumOrFlagsMembers(alloc, allSymbols, lexer)
								: emptyArrWithSize!(StructDeclAst.Body.Enum.Member)));
					case NonFunKeyword.externPtr:
						if (tookIndent)
							todo!void("shouldn't indent after 'extern'");
						return immutable StructDeclAst.Body(immutable StructDeclAst.Body.ExternPtr());
					case NonFunKeyword.record:
						return immutable StructDeclAst.Body(tookIndent
							? parseRecordBody(alloc, allSymbols, lexer)
							: immutable StructDeclAst.Body.Record(
								nonePtr!RecordModifiers,
								emptyArrWithSize!(StructDeclAst.Body.Record.Field)));
					case NonFunKeyword.union_:
						return immutable StructDeclAst.Body(
							immutable StructDeclAst.Body.Union(() {
								if (tookIndent)
									return parseUnionMembers(alloc, allSymbols, lexer);
								else {
									addDiagAtChar(alloc, lexer, immutable ParseDiag(
										immutable ParseDiag.UnionCantBeEmpty()));
									return emptyArr!(StructDeclAst.Body.Union.Member);
								}
							}()));
				}
			}();
			add(
				alloc,
				structs,
				immutable StructDeclAst(
					range(lexer, start),
					docComment,
					visibility,
					name,
					typeParams,
					purity,
					body_));
			break;
	}
}

immutable(Opt!ImportsOrExportsAst) parseImportsOrExports(
	ref Alloc alloc,
	ref AllSymbols allSymbols,
	ref AllPaths allPaths,
	ref Lexer lexer,
	immutable CStr kwNl,
) {
	immutable Pos start = curPos(lexer);
	if (tryTake(lexer, kwNl)) {
		ArrBuilder!ImportAst res;
		if (takeIndentOrDiagTopLevelAfterNewline(alloc, lexer)) {
			void recur() {
				immutable ImportAndDedent id = parseSingleModuleImportOnOwnLine(alloc, allSymbols, allPaths, lexer);
				add(alloc, res, id.import_);
				if (id.dedented == NewlineOrDedent.newline)
					recur();
			}
			recur();
		}
		return some(immutable ImportsOrExportsAst(range(lexer, start), finishArr(alloc, res)));
	} else
		return none!ImportsOrExportsAst;
}

immutable(Ptr!FileAst) parseFileInner(
	ref Alloc alloc,
	ref AllSymbols allSymbols,
	ref AllPaths allPaths,
	ref Lexer lexer,
) {
	immutable SafeCStr moduleDocComment = skipBlankLinesAndGetDocComment(alloc, lexer);
	immutable bool noStd = tryTake(lexer, "no-std\n");
	immutable Opt!ImportsOrExportsAst imports = parseImportsOrExports(alloc, allSymbols, allPaths, lexer, "import\n");
	immutable Opt!ImportsOrExportsAst exports = parseImportsOrExports(alloc, allSymbols, allPaths, lexer, "export\n");

	ArrBuilder!SpecDeclAst specs;
	ArrBuilder!StructAliasAst structAliases;
	ArrBuilder!StructDeclAst structs;
	ArrBuilder!FunDeclAst funs;
	ArrBuilder!TestAst tests;
	parseFileRecur(alloc, allSymbols, lexer, specs, structAliases, structs, funs, tests);
	return allocate(alloc, immutable FileAst(
		moduleDocComment,
		noStd,
		imports,
		exports,
		finishArr(alloc, specs),
		finishArr(alloc, structAliases),
		finishArr(alloc, structs),
		finishArr(alloc, funs),
		finishArr(alloc, tests)));
}

void parseFileRecur(
	ref Alloc alloc,
	ref AllSymbols allSymbols,
	ref Lexer lexer,
	ref ArrBuilder!SpecDeclAst specs,
	ref ArrBuilder!StructAliasAst structAliases,
	ref ArrBuilder!StructDeclAst structs,
	ref ArrBuilder!FunDeclAst funs,
	ref ArrBuilder!TestAst tests,
) {
	immutable SafeCStr docComment = skipBlankLinesAndGetDocComment(alloc, lexer);
	if (!tryTake(lexer, '\0')) {
		parseSpecOrStructOrFunOrTest(alloc, allSymbols, lexer, specs, structAliases, structs, funs, tests, docComment);
		parseFileRecur(alloc, allSymbols, lexer, specs, structAliases, structs, funs, tests);
	}
}
