module frontend.parse.parse;

@safe @nogc pure nothrow:

import frontend.parse.ast :
	ExplicitByValOrRef,
	ExplicitByValOrRefAndRange,
	ExprAst,
	FileAst,
	FileAstPart0,
	FileAstPart1,
	FunBodyAst,
	FunDeclAst,
	ImportAst,
	ImportsOrExportsAst,
	ParamAst,
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
	TypeParamAst;
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
	range,
	skipBlankLines,
	skipShebang,
	skipUntilNewlineNoDiag,
	SymAndIsReserved,
	takeDedentFromIndent1,
	takeIndentOrDiagTopLevel,
	takeIndentOrDiagTopLevelAfterNewline,
	takeIndentOrFailGeneric,
	takeName,
	takeNameAllowReserved,
	takeNewlineOrDedentAmount,
	takeNewlineOrIndent_topLevel,
	takeNewlineOrSingleDedent,
	takeOrAddDiagExpected,
	takeQuotedStr,
	tryTake,
	tryTakeIndentAfterNewline_topLevel;
import frontend.parse.parseExpr : parseFunExprBody;
import frontend.parse.parseType : parseType, parseTypeInstStruct, takeTypeArgsEnd, tryParseTypeArgsBracketed;
import model.parseDiag : ParseDiag, ParseDiagnostic;
import util.bools : Bool, False, True;
import util.collection.arr : Arr, ArrWithSize, emptyArr, emptyArrWithSize;
import util.collection.arrBuilder : add, ArrBuilder, arrBuilderIsEmpty, ArrWithSizeBuilder, finishArr;
import util.collection.str : CStr, emptyStr, NulTerminatedStr, Str;
import util.memory : allocate, nu;
import util.opt : force, has, mapOption, none, Opt, optOr, some;
import util.path : AllPaths, childPath, Path, rootPath;
import util.ptr : Ptr, ptrTrustMe_mut;
import util.sourceRange : Pos, RangeWithinFile;
import util.sym : AllSymbols, shortSymAlphaLiteral, shortSymAlphaLiteralValue, Sym, symEq;
import util.types : u8, u32;
import util.util : todo, unreachable, verify;

struct FileAstAndParseDiagnostics {
	immutable Ptr!FileAst ast;
	immutable Arr!ParseDiagnostic diagnostics;
}

immutable(FileAstAndParseDiagnostics) parseFile(Alloc, PathAlloc, SymAlloc)(
	ref Alloc alloc,
	ref AllPaths!PathAlloc allPaths,
	ref AllSymbols!SymAlloc allSymbols,
	immutable NulTerminatedStr source,
) {
	Lexer!SymAlloc lexer = createLexer(alloc, ptrTrustMe_mut(allSymbols), source);
	immutable Ptr!FileAst ast = parseFileInner(alloc, allPaths, lexer);
	return immutable FileAstAndParseDiagnostics(ast, finishDiags(alloc, lexer));
}

private:

immutable(ArrWithSize!TypeParamAst) parseTypeParams(Alloc, SymAlloc)(ref Alloc alloc, ref Lexer!SymAlloc lexer) {
	if (tryTake(lexer, '<')) {
		ArrWithSizeBuilder!TypeParamAst res;
		do {
			immutable Pos start = curPos(lexer);
			takeOrAddDiagExpected(alloc, lexer, '?', ParseDiag.Expected.Kind.typeParamQuestionMark);
			immutable Sym name = takeName(alloc, lexer);
			add(alloc, res, immutable TypeParamAst(range(lexer, start), name));
		} while (tryTake(lexer, ", "));
		takeTypeArgsEnd(alloc, lexer);
		return finishArr(alloc, res);
	} else
		return emptyArrWithSize!TypeParamAst;
}

immutable(Opt!PuritySpecifierAndRange) parsePurity(Alloc, SymAlloc)(ref Alloc alloc, ref Lexer!SymAlloc lexer) {
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
	immutable Opt!(Arr!Sym) names;
	immutable RangeWithinFile range;
	immutable NewlineOrDedent dedented;
}

struct NDotsAndPath {
	immutable u8 nDots;
	immutable Path path;
}

immutable(NDotsAndPath) parseImportPath(Alloc, PathAlloc, SymAlloc)(
	ref Alloc alloc,
	ref AllPaths!PathAlloc allPaths,
	ref Lexer!SymAlloc lexer,
) {
	u8 nDots = 0;
	while (tryTake(lexer, '.')) {
		verify(nDots < 255);
		nDots++;
	}
	immutable(Path) addPathComponents(immutable Path path) {
		return tryTake(lexer, '.')
			? addPathComponents(childPath(allPaths, path, takeName(alloc, lexer)))
			: path;
	}
	immutable Path path = addPathComponents(rootPath(allPaths, takeName(alloc, lexer)));
	return immutable NDotsAndPath(nDots, path);
}

immutable(ImportAndDedent) parseSingleModuleImportOnOwnLine(Alloc, PathAlloc, SymAlloc)(
	ref Alloc alloc,
	ref AllPaths!PathAlloc allPaths,
	ref Lexer!SymAlloc lexer,
) {
	immutable Pos start = curPos(lexer);
	immutable NDotsAndPath path = parseImportPath(alloc, allPaths, lexer);
	immutable NamesAndDedent names = () {
		if (tryTake(lexer, ':')) {
			if (tryTake(lexer, ' ')) {
				immutable Arr!Sym names = parseSingleImportNamesOnSingleLine(alloc, lexer);
				return immutable NamesAndDedent(
					some(names),
					range(lexer, start),
					takeNewlineOrSingleDedent(alloc, lexer));
			} else
				return takeIndentOrFailGeneric!(immutable NamesAndDedent)(
					alloc,
					lexer,
					1,
					() =>
						parseIndentedImportNames(alloc, lexer, start),
					(immutable RangeWithinFile, immutable size_t dedent) =>
						immutable NamesAndDedent(
							none!(Arr!Sym),
							range(lexer, start),
							newlineOrDedentFromNumber(dedent)));
		}
		return immutable NamesAndDedent(none!(Arr!Sym), range(lexer, start), takeNewlineOrSingleDedent(alloc, lexer));
	}();
	return immutable ImportAndDedent(
		immutable ImportAst(names.range, path.nDots, path.path, names.names),
		names.dedented);
}

immutable(NewlineOrDedent) newlineOrDedentFromNumber(immutable size_t dedent) {
	switch (dedent) {
		case 0:
			return NewlineOrDedent.newline;
		case 1:
			return NewlineOrDedent.dedent;
		default:
			return unreachable!(immutable NewlineOrDedent)();
	}
}

immutable(NamesAndDedent) parseIndentedImportNames(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	immutable Pos start,
) {
	ArrBuilder!Sym names;
	struct NewlineOrDedentAndRange {
		immutable NewlineOrDedent newlineOrDedent;
		immutable RangeWithinFile range;
	}
	immutable(NewlineOrDedentAndRange) recur() {
		takeCommaSeparatedNames(alloc, lexer, names);
		immutable RangeWithinFile range0 = range(lexer, start);
		immutable Bool trailingComma = tryTake(lexer, ',');
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
	return immutable NamesAndDedent(some(finishArr(alloc, names)), res.range, res.newlineOrDedent);
}

immutable(Arr!Sym) parseSingleImportNamesOnSingleLine(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
) {
	ArrBuilder!Sym names;
	takeCommaSeparatedNames(alloc, lexer, names);
	return finishArr(alloc, names);
}

void takeCommaSeparatedNames(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	ref ArrBuilder!Sym names,
) {
	add(alloc, names, takeName(alloc, lexer));
	if (tryTake(lexer, ", "))
		takeCommaSeparatedNames(alloc, lexer, names);
}

struct ParamsAndMaybeDedent {
	immutable ArrWithSize!ParamAst params;
	// 0 if we took a newline but it didn't change the indent level from before parsing params.
	immutable Opt!size_t dedents;
}

immutable(ParamAst) parseSingleParam(Alloc, SymAlloc)(ref Alloc alloc, ref Lexer!SymAlloc lexer) {
	immutable Pos start = curPos(lexer);
	immutable Opt!Sym name = tryTake(lexer, '_')
		? none!Sym
		: some(takeName(alloc, lexer));
	takeOrAddDiagExpected(alloc, lexer, ' ', ParseDiag.Expected.Kind.space);
	immutable TypeAst type = parseType(alloc, lexer);
	return immutable ParamAst(range(lexer, start), name, type);
}

immutable(ArrWithSize!ParamAst) parseParenthesizedParams(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
) {
	if (tryTake(lexer, ')'))
		return emptyArrWithSize!ParamAst;
	else {
		ArrWithSizeBuilder!ParamAst res;
		for (;;) {
			add(alloc, res, parseSingleParam(alloc, lexer));
			if (tryTake(lexer, ')'))
				break;
			if (!takeOrAddDiagExpected(alloc, lexer, ", ", ParseDiag.Expected.Kind.comma)) {
				skipUntilNewlineNoDiag(lexer);
				break;
			}
		}
		return finishArr(alloc, res);
	}
}

immutable(ParamsAndMaybeDedent) parseIndentedParams(Alloc, SymAlloc)(ref Alloc alloc, ref Lexer!SymAlloc lexer) {
	ArrWithSizeBuilder!ParamAst res;
	for (;;) {
		add(alloc, res, parseSingleParam(alloc, lexer));
		immutable size_t dedents = takeNewlineOrDedentAmount(alloc, lexer, 1);
		if (dedents != 0)
			return ParamsAndMaybeDedent(finishArr(alloc, res), some(dedents - 1));
	}
}

immutable(ParamsAndMaybeDedent) parseParams(Alloc, SymAlloc)(ref Alloc alloc, ref Lexer!SymAlloc lexer) {
	if (tryTake(lexer, '('))
		return ParamsAndMaybeDedent(parseParenthesizedParams(alloc, lexer), none!size_t);
	else
		final switch (takeNewlineOrIndent_topLevel(alloc, lexer)) {
			case NewlineOrIndent.newline:
				return ParamsAndMaybeDedent(emptyArrWithSize!ParamAst, some!size_t(0));
			case NewlineOrIndent.indent:
				return parseIndentedParams(alloc, lexer);
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

immutable(SigAstAndMaybeDedent) parseSigAfterNameAndSpace(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	immutable Pos start,
	immutable Sym name,
) {
	immutable TypeAst returnType = parseType(alloc, lexer);
	immutable ParamsAndMaybeDedent params = parseParams(alloc, lexer);
	immutable Ptr!SigAst sigAst = nu!SigAst(alloc, range(lexer, start), name, returnType, params.params);
	return SigAstAndMaybeDedent(sigAst, params.dedents);
}

immutable(SigAstAndDedent) parseSig(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	immutable u32 curIndent,
) {
	immutable Pos start = curPos(lexer);
	immutable Sym sigName = takeName(alloc, lexer);
	takeOrAddDiagExpected(alloc, lexer, ' ', ParseDiag.Expected.Kind.space);
	immutable SigAstAndMaybeDedent s = parseSigAfterNameAndSpace(alloc, lexer, start, sigName);
	immutable size_t dedents = has(s.dedents) ? force(s.dedents) : takeNewlineOrDedentAmount(alloc, lexer, curIndent);
	return SigAstAndDedent(s.sig, dedents);
}

immutable(Arr!SigAst) parseIndentedSigs(Alloc, SymAlloc)(ref Alloc alloc, ref Lexer!SymAlloc lexer) {
	ArrBuilder!SigAst res;
	for (;;) {
		immutable SigAstAndDedent sd = parseSig(alloc, lexer, 1);
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
	externPtr,
	record,
	spec,
	union_,
}

struct NonFunKeywordAndIndent {
	immutable NonFunKeyword keyword;
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

immutable(Opt!NonFunKeywordAndIndent) tryTakeKw(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	immutable CStr kwSpace,
	immutable CStr kwNl,
	immutable NonFunKeyword keyword
) {
	return tryTake(lexer, kwSpace)
		? some(NonFunKeywordAndIndent(keyword, SpaceOrNewlineOrIndent.space))
		: tryTake(lexer, kwNl)
		? some(NonFunKeywordAndIndent(
			keyword,
			spaceOrNewlineOrIndentFromNewlineOrIndent(tryTakeIndentAfterNewline_topLevel(alloc, lexer))))
		: none!NonFunKeywordAndIndent;
}

immutable(Opt!NonFunKeywordAndIndent) parseNonFunKeyword(Alloc, SymAlloc)(ref Alloc alloc, ref Lexer!SymAlloc lexer) {
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
			return tryTakeKw(alloc, lexer, "extern-ptr ", "extern-ptr\n", NonFunKeyword.externPtr);
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

immutable(StructDeclAst.Body.Record) parseRecordBody(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
) {
	ArrBuilder!(StructDeclAst.Body.Record.Field) res;
	pure immutable(StructDeclAst.Body.Record) recur(immutable RecordModifiers prevModifiers) {
		immutable Pos start = curPos(lexer);
		immutable Sym name = takeName(alloc, lexer);
		immutable RecordModifiers newModifiers = () {
			switch (name.value) {
				case shortSymAlphaLiteralValue("by-val"):
				case shortSymAlphaLiteralValue("by-ref"):
					immutable ExplicitByValOrRef value = name.value == shortSymAlphaLiteralValue("by-val")
						? ExplicitByValOrRef.byVal
						: ExplicitByValOrRef.byRef;
					if (has(prevModifiers.explicitByValOrRef) || !arrBuilderIsEmpty(res))
						todo!void("by-val or by-ref on later line");
					return immutable RecordModifiers(
						prevModifiers.packed,
						some(immutable ExplicitByValOrRefAndRange(start, value)));
				case shortSymAlphaLiteralValue("packed"):
					if (has(prevModifiers.packed) || !arrBuilderIsEmpty(res))
						todo!void("'packed' on later line");
					return immutable RecordModifiers(some(start), prevModifiers.explicitByValOrRef);
				default:
					takeOrAddDiagExpected(alloc, lexer, ' ', ParseDiag.Expected.Kind.space);
					immutable Bool isMutable = tryTake(lexer, "mut ");
					immutable TypeAst type = parseType(alloc, lexer);
					add(alloc, res, immutable StructDeclAst.Body.Record.Field(
						range(lexer, start), isMutable, name, type));
					return prevModifiers;
			}
		}();
		final switch (takeNewlineOrSingleDedent(alloc, lexer)) {
			case NewlineOrDedent.newline:
				return recur(newModifiers);
			case NewlineOrDedent.dedent:
				return immutable StructDeclAst.Body.Record(
					newModifiers.any() ? some(allocate(alloc, newModifiers)) : none!(Ptr!RecordModifiers),
					finishArr(alloc, res));
		}
	}
	return recur(immutable RecordModifiers(none!Pos, none!ExplicitByValOrRefAndRange));
}

immutable(Arr!(TypeAst.InstStruct)) parseUnionMembers(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
) {
	ArrBuilder!(TypeAst.InstStruct) res;
	do {
		add(alloc, res, parseTypeInstStruct(alloc, lexer));
	} while (takeNewlineOrSingleDedent(alloc, lexer) == NewlineOrDedent.newline);
	return finishArr(alloc, res);
}

struct SpecUsesAndSigFlagsAndKwBody {
	immutable Arr!SpecUseAst specUses;
	immutable Bool noCtx;
	immutable Bool summon;
	immutable Bool unsafe;
	immutable Bool trusted;
	immutable Opt!(Ptr!FunBodyAst) body_; // none for 'builtin' or 'extern'
}

immutable(SpecUsesAndSigFlagsAndKwBody) emptySpecUsesAndSigFlagsAndKwBody =
	SpecUsesAndSigFlagsAndKwBody(
		emptyArr!SpecUseAst,
		False,
		False,
		False,
		False,
		none!(Ptr!FunBodyAst));

immutable(FunBodyAst.Extern) takeExternName(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	immutable Bool isGlobal,
) {
	if (tryTake(lexer, '<')) {
		immutable Str externName = takeQuotedStr(lexer, alloc);
		immutable Opt!Str libraryName = tryTake(lexer, ", ") ? some(takeQuotedStr(lexer, alloc)) : none!Str;
		takeTypeArgsEnd(alloc, lexer);
		return immutable FunBodyAst.Extern(isGlobal, externName, libraryName);
	} else {
		addDiagAtChar(
			alloc,
			lexer,
			immutable ParseDiag(immutable ParseDiag.Expected(ParseDiag.Expected.Kind.externName)));
		return immutable FunBodyAst.Extern(isGlobal, emptyStr, none!Str);
	}
}

immutable(SpecUsesAndSigFlagsAndKwBody) parseNextSpec(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	ref ArrBuilder!SpecUseAst specUses,
	immutable Bool noCtx,
	immutable Bool summon,
	immutable Bool unsafe,
	immutable Bool trusted,
	immutable Bool builtin,
	immutable Opt!(FunBodyAst.Extern) extern_,
	immutable Opt!Str mangle,
	scope immutable(Bool) delegate() @safe @nogc pure nothrow canTakeNext,
) {
	immutable Pos start = curPos(lexer);
	immutable SymAndIsReserved name = takeNameAllowReserved(alloc, lexer);
	if (name.isReserved) {
		scope immutable(SpecUsesAndSigFlagsAndKwBody) setExtern(immutable Bool isGlobal) {
			if (has(extern_))
				todo!void("duplicate");
			immutable Opt!(FunBodyAst.Extern) extern2 = some(takeExternName(alloc, lexer, isGlobal));
			return nextSpecOrStop(
				alloc, lexer, specUses, noCtx, summon, unsafe, trusted, builtin, extern2, mangle, canTakeNext);
		}
		switch (name.name.name.value) {
			case shortSymAlphaLiteralValue("noctx"):
				if (noCtx) todo!void("duplicate");
				return nextSpecOrStop(
					alloc, lexer, specUses, True, summon, unsafe, trusted, builtin, extern_, mangle, canTakeNext);
			case shortSymAlphaLiteralValue("summon"):
				if (summon) todo!void("duplicate");
				return nextSpecOrStop(
					alloc, lexer, specUses, noCtx, True, unsafe, trusted, builtin, extern_, mangle, canTakeNext);
			case shortSymAlphaLiteralValue("unsafe"):
				if (unsafe) todo!void("duplicate");
				return nextSpecOrStop(
					alloc, lexer, specUses, noCtx, summon, True, trusted, builtin, extern_, mangle, canTakeNext);
			case shortSymAlphaLiteralValue("trusted"):
				if (trusted) todo!void("duplicate");
				return nextSpecOrStop(
					alloc, lexer, specUses, noCtx, summon, unsafe, True, builtin, extern_, mangle, canTakeNext);
			case shortSymAlphaLiteralValue("builtin"):
				if (builtin) todo!void("duplicate");
				return nextSpecOrStop(
					alloc, lexer, specUses, noCtx, summon, unsafe, trusted, True, extern_, mangle, canTakeNext);
			case shortSymAlphaLiteralValue("extern"):
				return setExtern(False);
			case shortSymAlphaLiteralValue("global"):
				return setExtern(True);
			default: {
				addDiagOnReservedName(alloc, lexer, name.name);
				return nextSpecOrStop(
					alloc, lexer, specUses, noCtx, summon, unsafe, trusted, builtin, extern_, mangle, canTakeNext);
			}
		}
	} else {
		immutable ArrWithSize!TypeAst typeArgs = tryParseTypeArgsBracketed(alloc, lexer);
		add(alloc, specUses, immutable SpecUseAst(range(lexer, start), name.name, typeArgs));
		return nextSpecOrStop(
			alloc, lexer, specUses, noCtx, summon, unsafe, trusted, builtin, extern_, mangle, canTakeNext);
	}
}

immutable(SpecUsesAndSigFlagsAndKwBody) nextSpecOrStop(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	ref ArrBuilder!SpecUseAst specUses,
	immutable Bool noCtx,
	immutable Bool summon,
	immutable Bool unsafe,
	immutable Bool trusted,
	immutable Bool builtin,
	immutable Opt!(FunBodyAst.Extern) extern_,
	immutable Opt!Str mangle,
	scope immutable(Bool) delegate() @safe @nogc pure nothrow canTakeNext,
) {
	if (canTakeNext())
		return parseNextSpec!(Alloc, SymAlloc)(
			alloc, lexer, specUses, noCtx, summon, unsafe, trusted, builtin, extern_, mangle, canTakeNext);
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
			? some(nu!FunBodyAst(alloc, immutable FunBodyAst.Builtin()))
			: has(extern_)
			? some(nu!FunBodyAst(alloc, extern_.force))
			: none!(Ptr!FunBodyAst);
		return SpecUsesAndSigFlagsAndKwBody(finishArr(alloc, specUses), noCtx, summon, unsafe, trusted, body_);
	}
}

// TODO: handle 'noctx' and friends too! (share code with parseSpecUsesAndSigFlagsAndKwBody)
immutable(SpecUsesAndSigFlagsAndKwBody) parseIndentedSpecUses(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
) {
	if (takeIndentOrDiagTopLevel(alloc, lexer)) {
		ArrBuilder!SpecUseAst builder;
		return parseNextSpec(
			alloc,
			lexer,
			builder,
			False,
			False,
			False,
			False,
			False,
			none!(FunBodyAst.Extern),
			none!Str,
			() => immutable Bool(takeNewlineOrSingleDedent(alloc, lexer) == NewlineOrDedent.newline));
	} else
		return immutable SpecUsesAndSigFlagsAndKwBody(
			emptyArr!SpecUseAst,
			False,
			False,
			False,
			False,
			none!(Ptr!FunBodyAst));
}

immutable(SpecUsesAndSigFlagsAndKwBody) parseSpecUsesAndSigFlagsAndKwBody(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
) {
	// Unlike indented specs, we check for a separator on first spec, so use nextSpecOrStop instead of parseNextSpec
	ArrBuilder!SpecUseAst builder;
	return nextSpecOrStop(
		alloc,
		lexer,
		builder,
		False,
		False,
		False,
		False,
		False,
		none!(FunBodyAst.Extern),
		none!Str,
		() => tryTake(lexer, ' '));
}

//TODO:RENAME
struct FunDeclStuff {
	immutable SpecUsesAndSigFlagsAndKwBody extra;
	immutable Ptr!FunBodyAst body_;
}

immutable(FunDeclAst) parseFun(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	immutable Bool isPublic,
	immutable Pos start,
	immutable Sym name,
	immutable ArrWithSize!TypeParamAst typeParams,
) {
	immutable SigAstAndMaybeDedent sig = parseSigAfterNameAndSpace(alloc, lexer, start, name);
	immutable FunDeclStuff stuff = () {
		if (has(sig.dedents)) {
			// Started at indent of 0
			verify(force(sig.dedents) == 0);
			immutable SpecUsesAndSigFlagsAndKwBody extra = tryTake(lexer, "spec")
				? parseIndentedSpecUses(alloc, lexer)
				: emptySpecUsesAndSigFlagsAndKwBody;
			immutable Ptr!FunBodyAst body_ = optOr(extra.body_, () {
				takeOrAddDiagExpected(alloc, lexer, "body", ParseDiag.Expected.Kind.bodyKeyword);
				return nu!FunBodyAst(alloc, parseFunExprBody(alloc, lexer));
			});
			return immutable FunDeclStuff(extra, body_);
		} else {
			immutable SpecUsesAndSigFlagsAndKwBody extra = parseSpecUsesAndSigFlagsAndKwBody(alloc, lexer);
			immutable Ptr!FunBodyAst body_ = optOr(extra.body_, () =>
				nu!FunBodyAst(alloc, parseFunExprBody(alloc, lexer)));
			return immutable FunDeclStuff(extra, body_);
		}
	}();
	immutable SpecUsesAndSigFlagsAndKwBody extra = stuff.extra;
	return FunDeclAst(
		range(lexer, start),
		typeParams,
		sig.sig,
		extra.specUses,
		isPublic,
		extra.noCtx,
		extra.summon,
		extra.unsafe,
		extra.trusted,
		stuff.body_);
}

void parseSpecOrStructOrFunOrTest(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	ref ArrBuilder!SpecDeclAst specs,
	ref ArrBuilder!StructAliasAst structAliases,
	ref ArrBuilder!StructDeclAst structs,
	ref ArrBuilder!FunDeclAst funs,
	ref ArrBuilder!TestAst tests,
) {
	immutable Pos start = curPos(lexer);
	immutable Bool isPublic = immutable Bool(!tryTake(lexer, '.'));
	immutable Sym name = takeName(alloc, lexer);
	immutable ArrWithSize!TypeParamAst typeParams = parseTypeParams(alloc, lexer);
	if (!tryTake(lexer, ' ')) {
		if (symEq(name, shortSymAlphaLiteral("test"))) {
			immutable ExprAst body_ = parseFunExprBody(alloc, lexer);
			add(alloc, tests, immutable TestAst(body_));
		} else {
			addDiagAtChar(alloc, lexer, immutable ParseDiag(
				immutable ParseDiag.Expected(ParseDiag.Expected.Kind.space)));
			skipUntilNewlineNoDiag(lexer);
		}
	} else {
		immutable Opt!NonFunKeywordAndIndent opKwAndIndent = parseNonFunKeyword(alloc, lexer);
		if (has(opKwAndIndent)) {
			immutable NonFunKeywordAndIndent kwAndIndent = force(opKwAndIndent);
			immutable NonFunKeyword kw = kwAndIndent.keyword;
			immutable SpaceOrNewlineOrIndent after = kwAndIndent.after;
			immutable Opt!PuritySpecifierAndRange purity = after == SpaceOrNewlineOrIndent.space
				? parsePurity(alloc, lexer)
				: none!PuritySpecifierAndRange;

			immutable Bool tookIndent = () {
				final switch (after) {
					case SpaceOrNewlineOrIndent.space:
						return Bool(takeNewlineOrIndent_topLevel(alloc, lexer) == NewlineOrIndent.indent);
					case SpaceOrNewlineOrIndent.newline:
						return False;
					case SpaceOrNewlineOrIndent.indent:
						return True;
				}
			}();

			final switch (kw) {
				case NonFunKeyword.alias_:
					if (!tookIndent)
						todo!void("always indent alias");
					if (has(purity))
						todo!void("alias shouldn't have purity");
					immutable Ptr!TypeAst target = allocate(alloc, parseType(alloc, lexer));
					takeDedentFromIndent1(alloc, lexer);
					add(
						alloc,
						structAliases,
						immutable StructAliasAst(range(lexer, start), isPublic, name, typeParams, target));
					break;
				case NonFunKeyword.builtinSpec:
					if (tookIndent)
						todo!void("builtin-spec has no body");
					if (has(purity))
						todo!void("spec shouldn't have purity");
					add(alloc, specs, immutable SpecDeclAst(
						range(lexer, start),
						isPublic,
						name,
						typeParams,
						SpecBodyAst(SpecBodyAst.Builtin())));
					break;
				case NonFunKeyword.spec:
					if (!tookIndent)
						todo!void("always indent spec");
					if (has(purity))
						todo!void("spec shouldn't have purity");
					immutable Arr!SigAst sigs = parseIndentedSigs(alloc, lexer);
					add(
						alloc,
						specs,
						immutable SpecDeclAst(
							range(lexer, start),
							isPublic,
							name,
							typeParams,
							immutable SpecBodyAst(sigs)));
					break;
				case NonFunKeyword.builtin:
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
							case NonFunKeyword.externPtr:
								if (tookIndent)
									todo!void("shouldn't indent after 'extern'");
								return immutable StructDeclAst.Body(immutable StructDeclAst.Body.ExternPtr());
							case NonFunKeyword.record:
								return immutable StructDeclAst.Body(tookIndent
									? parseRecordBody(alloc, lexer)
									: immutable StructDeclAst.Body.Record(
										none!(Ptr!RecordModifiers),
										emptyArr!(StructDeclAst.Body.Record.Field)));
							case NonFunKeyword.union_:
								return immutable StructDeclAst.Body(
									immutable StructDeclAst.Body.Union(() {
										if (tookIndent)
											return parseUnionMembers(alloc, lexer);
										else {
											addDiagAtChar(alloc, lexer, immutable ParseDiag(
												immutable ParseDiag.UnionCantBeEmpty()));
											return emptyArr!(TypeAst.InstStruct);
										}
									}()));
						}
					}();
					add(
						alloc,
						structs,
						immutable StructDeclAst(range(lexer, start), isPublic, name, typeParams, purity, body_));
					break;
			}
		} else
			add(alloc, funs, parseFun(alloc, lexer, isPublic, start, name, typeParams));
	}
}

immutable(Opt!ImportsOrExportsAst) parseImportsOrExports(Alloc, PathAlloc, SymAlloc)(
	ref Alloc alloc,
	ref AllPaths!PathAlloc allPaths,
	ref Lexer!SymAlloc lexer,
	immutable CStr kwNl,
) {
	immutable Pos start = curPos(lexer);
	if (tryTake(lexer, kwNl)) {
		ArrBuilder!ImportAst res;
		if (takeIndentOrDiagTopLevelAfterNewline(alloc, lexer)) {
			void recur() {
				immutable ImportAndDedent id = parseSingleModuleImportOnOwnLine(alloc, allPaths, lexer);
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

immutable(Ptr!FileAst) parseFileInner(Alloc, PathAlloc, SymAlloc)(
	ref Alloc alloc,
	ref AllPaths!PathAlloc allPaths,
	ref Lexer!SymAlloc lexer,
) {
	skipShebang(lexer);
	skipBlankLines(alloc, lexer);
	immutable Opt!ImportsOrExportsAst imports = parseImportsOrExports(alloc, allPaths, lexer, "import\n");
	immutable Opt!ImportsOrExportsAst exports = parseImportsOrExports(alloc, allPaths, lexer, "export\n");

	ArrBuilder!SpecDeclAst specs;
	ArrBuilder!StructAliasAst structAliases;
	ArrBuilder!StructDeclAst structs;
	ArrBuilder!FunDeclAst funs;
	ArrBuilder!TestAst tests;

	for (;;) {
		skipBlankLines(alloc, lexer);
		if (tryTake(lexer, '\0'))
			break;
		parseSpecOrStructOrFunOrTest(alloc, lexer, specs, structAliases, structs, funs, tests);
	}

	return nu!FileAst(
		alloc,
		nu!FileAstPart0(alloc, imports, exports, finishArr(alloc, specs)),
		nu!FileAstPart1(
			alloc,
			finishArr(alloc, structAliases),
			finishArr(alloc, structs),
			finishArr(alloc, funs),
			finishArr(alloc, tests)));
}
