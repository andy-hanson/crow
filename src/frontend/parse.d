module frontend.parse;

@safe @nogc pure nothrow:

import parseDiag : ParseDiagnostic;

import frontend.ast :
	emptyFileAst,
	ExplicitByValOrRef,
	FileAst,
	FileAstPart0,
	FileAstPart1,
	FunBodyAst,
	FunDeclAst,
	ImportAst,
	ParamAst,
	PuritySpecifier,
	SigAst,
	SpecBodyAst,
	SpecDeclAst,
	SpecUseAst,
	StructAliasAst,
	StructDeclAst,
	TypeAst,
	TypeParamAst;
import frontend.lexer :
	addDiagAtChar,
	addDiagOnReservedName,
	createLexer,
	curChar,
	curPos,
	finishDiags,
	Lexer,
	NewlineOrDedent,
	NewlineOrIndent,
	pureSetjmp,
	range,
	skipBlankLines,
	skipShebang,
	SymAndIsReserved,
	take,
	takeDedentFromIndent1,
	takeIndentOrDiagTopLevel,
	takeIndentOrDiagTopLevelAfterNewline,
	takeName,
	takeNameAllowReserved,
	takeNewlineOrDedentAmount,
	takeNewlineOrIndent,
	takeNewlineOrSingleDedent,
	takeQuotedStr,
	throwAtChar,
	tryTake,
	tryTakeIndentAfterNewline,
	tryTakeNewlineOrIndent;
import frontend.parseExpr : parseFunExprBody;
import frontend.parseType : parseStructType, parseType, tryParseTypeArgs;

import parseDiag : ParseDiag;

import util.bools : Bool, False, True;
import util.collection.arr : Arr, ArrWithSize, emptyArr, emptyArrWithSize;
import util.collection.arrBuilder : add, ArrBuilder, ArrWithSizeBuilder, finishArr;
import util.collection.arrUtil : arrLiteral;
import util.collection.str : CStr, NulTerminatedStr, Str;
import util.memory : nu;
import util.opt : force, has, none, Opt, optOr, some;
import util.path : childPath, Path, rootPath;
import util.ptr : Ptr, ptrTrustMe_mut;
import util.sourceRange : Pos;
import util.sym : AllSymbols, shortSymAlphaLiteralValue, Sym;
import util.types : u8;
import util.util : todo, unreachable, verify;

struct FileAstAndParseDiagnostics {
	immutable FileAst ast;
	immutable Arr!ParseDiagnostic diagnostics;
}

immutable(FileAstAndParseDiagnostics) parseFile(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref AllSymbols!SymAlloc allSymbols,
	immutable NulTerminatedStr source,
) {
	Lexer!SymAlloc lexer = createLexer(ptrTrustMe_mut(allSymbols), source);
	immutable int i = pureSetjmp(lexer.jump_buffer);
	if (i == 0) {
		immutable FileAst ast = parseFileInner(alloc, lexer);
		return immutable FileAstAndParseDiagnostics(ast, finishDiags(alloc, lexer));
	} else
		return immutable FileAstAndParseDiagnostics(emptyFileAst, arrLiteral(alloc, lexer.diagnostic_));
}

private:

immutable(Arr!TypeParamAst) parseTypeParams(Alloc, SymAlloc)(ref Alloc alloc, ref Lexer!SymAlloc lexer) {
	if (tryTake(lexer, '<')) {
		ArrBuilder!TypeParamAst res;
		do {
			immutable Pos start = curPos(lexer);
			take(lexer, '?');
			immutable Sym name = takeName(alloc, lexer);
			add(alloc, res, TypeParamAst(range(lexer, start), name));
		} while (tryTake(lexer, ", "));
		take(lexer, '>');
		return finishArr(alloc, res);
	} else
		return emptyArr!TypeParamAst;
}

immutable(Opt!PuritySpecifier) parsePurity(Alloc, SymAlloc)(ref Alloc alloc, ref Lexer!SymAlloc lexer) {
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
		addDiagAtChar(alloc, lexer, immutable ParseDiag(immutable ParseDiag.Expected(ParseDiag.Expected.Kind.purity)));
		return none!PuritySpecifier;
	}
}

immutable(ImportAst) parseSingleImport(Alloc, SymAlloc)(ref Alloc alloc, ref Lexer!SymAlloc lexer) {
	immutable Pos start = curPos(lexer);
	u8 nDots = 0;
	while (tryTake(lexer, '.')) {
		verify(nDots < 255);
		nDots++;
	}

	immutable(Ptr!Path) addPathComponents(immutable Ptr!Path path) {
		return tryTake(lexer, '.')
			? addPathComponents(childPath(alloc, path, takeName(alloc, lexer)))
			: path;
	}
	immutable Ptr!Path path = addPathComponents(rootPath(alloc, takeName(alloc, lexer)));
	return ImportAst(range(lexer, start), nDots, path);
}

struct ParamsAndMaybeDedent {
	immutable ArrWithSize!ParamAst params;
	// 0 if we took a newline but it didn't change the indent level from before parsing params.
	immutable Opt!size_t dedents;
}

immutable(ParamAst) parseSingleParam(Alloc, SymAlloc)(ref Alloc alloc, ref Lexer!SymAlloc lexer) {
	immutable Pos start = curPos(lexer);
	immutable Sym name = takeName(alloc, lexer);
	take(lexer, ' ');
	immutable TypeAst type = parseType(alloc, lexer);
	return ParamAst(range(lexer, start), name, type);
}

immutable(ArrWithSize!ParamAst) parseParenthesizedParams(Alloc, SymAlloc)(ref Alloc alloc, ref Lexer!SymAlloc lexer) {
	take(lexer, '(');
	if (tryTake(lexer, ')'))
		return emptyArrWithSize!ParamAst;
	else {
		ArrWithSizeBuilder!ParamAst res;
		for (;;) {
			add(alloc, res, parseSingleParam(alloc, lexer));
			if (tryTake(lexer, ')'))
				break;
			take(lexer, ", ");
		}
		return finishArr(alloc, res);
	}
}

immutable(ParamsAndMaybeDedent) parseIndentedParams(Alloc, SymAlloc)(ref Alloc alloc, ref Lexer!SymAlloc lexer) {
	ArrWithSizeBuilder!ParamAst res;
	for (;;) {
		add(alloc, res, parseSingleParam(alloc, lexer));
		immutable size_t dedents = takeNewlineOrDedentAmount(alloc, lexer);
		if (dedents != 0)
			return ParamsAndMaybeDedent(finishArr(alloc, res), some(dedents - 1));
	}
}

immutable(ParamsAndMaybeDedent) parseParams(Alloc, SymAlloc)(ref Alloc alloc, ref Lexer!SymAlloc lexer) {
	immutable Opt!NewlineOrIndent opNi = tryTakeNewlineOrIndent(alloc, lexer);
	if (opNi.has)
		final switch (opNi.force) {
			case NewlineOrIndent.newline:
				return ParamsAndMaybeDedent(emptyArrWithSize!ParamAst, some!size_t(0));
			case NewlineOrIndent.indent:
				return parseIndentedParams(alloc, lexer);
		}
	else
		return ParamsAndMaybeDedent(parseParenthesizedParams(alloc, lexer), none!size_t);
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

immutable(SigAstAndDedent) parseSig(Alloc, SymAlloc)(ref Alloc alloc, ref Lexer!SymAlloc lexer) {
	immutable Pos start = curPos(lexer);
	immutable Sym sigName = takeName(alloc, lexer);
	take(lexer, ' ');
	immutable SigAstAndMaybeDedent s = parseSigAfterNameAndSpace(alloc, lexer, start, sigName);
	immutable size_t dedents = s.dedents.has ? s.dedents.force : takeNewlineOrDedentAmount(alloc, lexer);
	return SigAstAndDedent(s.sig, dedents);
}

immutable(Arr!ImportAst) parseImportsNonIndented(Alloc, SymAlloc)(ref Alloc alloc, ref Lexer!SymAlloc lexer) {
	ArrBuilder!ImportAst res;
	do {
		add(alloc, res, parseSingleImport(alloc, lexer));
	} while (tryTake(lexer, ' '));
	take(lexer, '\n');
	return finishArr(alloc, res);
}

immutable(Arr!ImportAst) parseImportsIndented(Alloc, SymAlloc)(ref Alloc alloc, ref Lexer!SymAlloc lexer) {
	ArrBuilder!ImportAst res;
	if (takeIndentOrDiagTopLevelAfterNewline(alloc, lexer)) {
		do {
			add(alloc, res, parseSingleImport(alloc, lexer));
		} while (takeNewlineOrSingleDedent(alloc, lexer) == NewlineOrDedent.newline);
	}
	return finishArr(alloc, res);
}

immutable(Arr!SigAst) parseIndentedSigs(Alloc, SymAlloc)(ref Alloc alloc, ref Lexer!SymAlloc lexer) {
	ArrBuilder!SigAst res;
	for (;;) {
		immutable SigAstAndDedent sd = parseSig(alloc, lexer);
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
			spaceOrNewlineOrIndentFromNewlineOrIndent(tryTakeIndentAfterNewline(alloc, lexer))))
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

immutable(StructDeclAst.Body.Record) parseFields(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
) {
	ArrBuilder!(StructDeclAst.Body.Record.Field) res;
	Opt!ExplicitByValOrRef explicitByValOrRef = none!ExplicitByValOrRef;
	Bool isFirstLine = True;
	do {
		immutable Pos start = curPos(lexer);
		immutable Sym name = takeName(alloc, lexer);
		switch (name.value) {
			case shortSymAlphaLiteralValue("by-val"):
				if (!isFirstLine) todo!void("by-val on later line");
				verify(!explicitByValOrRef.has);
				explicitByValOrRef = some(ExplicitByValOrRef.byVal);
				break;
			case shortSymAlphaLiteralValue("by-ref"):
				if (!isFirstLine) todo!void("by-ref on later line");
				verify(!explicitByValOrRef.has);
				explicitByValOrRef = some(ExplicitByValOrRef.byRef);
				break;
			default:
				take(lexer, ' ');
				immutable Bool isMutable = tryTake(lexer, "mut ");
				immutable TypeAst type = parseType(alloc, lexer);
				add(alloc, res, immutable StructDeclAst.Body.Record.Field(range(lexer, start), isMutable, name, type));
		}
		isFirstLine = False;
	} while (takeNewlineOrSingleDedent(alloc, lexer) == NewlineOrDedent.newline);
	return StructDeclAst.Body.Record(explicitByValOrRef, finishArr(alloc, res));
}

immutable(Arr!(TypeAst.InstStruct)) parseUnionMembers(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
) {
	ArrBuilder!(TypeAst.InstStruct) res;
	do {
		immutable Pos start = curPos(lexer);
		immutable Sym name = takeName(alloc, lexer);
		immutable Arr!TypeAst typeArgs = tryParseTypeArgs(alloc, lexer);
		add(alloc, res, immutable TypeAst.InstStruct(range(lexer, start), name, typeArgs));
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

struct SpecUsesAndSigFlagsAndKwBodyBuilder {
	ArrBuilder!SpecUseAst specUses;
	immutable Bool noCtx = False;
	immutable Bool summon = False;
	immutable Bool unsafe = False;
	immutable Bool trusted = False;
	immutable Bool builtin = False;
	immutable Opt!(FunBodyAst.Extern) extern_ = none!(FunBodyAst.Extern);
	immutable Opt!Str mangle = none!Str;
}

immutable(Opt!Str) tryTakeMangledName(Alloc, SymAlloc)(ref Alloc alloc, ref Lexer!SymAlloc lexer) {
	if (tryTake(lexer, '<')) {
		immutable Str mangledName = takeQuotedStr(lexer, alloc);
		take(lexer, '>');
		return some(mangledName);
	} else
		return none!Str;
}

immutable(SpecUsesAndSigFlagsAndKwBody) finishSpecs(Alloc)(
	ref SpecUsesAndSigFlagsAndKwBodyBuilder builder,
	ref Alloc alloc,
) {
}

immutable(SpecUsesAndSigFlagsAndKwBody) parseNextSpec(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	ArrBuilder!SpecUseAst specUses,
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
	immutable SymAndIsReserved name = takeNameAllowReserved(lexer);
	if (name.isReserved) {
		scope immutable(SpecUsesAndSigFlagsAndKwBody) setExtern(immutable Bool isGlobal) {
			if (extern_.has)
				todo!void("duplicate");
			immutable Opt!Str mangledName = tryTakeMangledName(alloc, lexer);
			immutable Opt!(FunBodyAst.Extern) extern2 = some(immutable FunBodyAst.Extern(isGlobal, mangledName));
			return nextSpecOrStop(
				alloc, lexer, specUses, noCtx, summon, unsafe, trusted, builtin, extern2, mangle, canTakeNext);
		}
		switch (name.sym.value) {
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
				addDiagOnReservedName(alloc, lexer, name.range, name.sym);
				return nextSpecOrStop(
					alloc, lexer, specUses, noCtx, summon, unsafe, trusted, builtin, extern_, mangle, canTakeNext);
			}
		}
	} else {
		immutable Arr!TypeAst typeArgs = tryParseTypeArgs(alloc, lexer);
		add(alloc, specUses, immutable SpecUseAst(range(lexer, start), name.sym, typeArgs));
		return nextSpecOrStop(
			alloc, lexer, specUses, noCtx, summon, unsafe, trusted, builtin, extern_, mangle, canTakeNext);
	}
}

immutable(SpecUsesAndSigFlagsAndKwBody) nextSpecOrStop(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	ArrBuilder!SpecUseAst specUses,
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
		return parseNextSpec(
			alloc, lexer, specUses, noCtx, summon, unsafe, trusted, builtin, extern_, mangle, canTakeNext);
	else {
		if (unsafe && trusted)
			todo!void("'unsafe trusted' is redundant");
		if (builtin && trusted)
			todo!void("'builtin trusted' is silly as builtin fun has no body");
		if (extern_.has && trusted)
			todo!void("'extern trusted' is silly as extern fun has no body");

		//TODO: assert 'builtin' and 'extern' and 'extern-global' can't be set together.
		//Also, 'extern-global' should always be 'unsafe noctx'
		immutable Opt!(Ptr!FunBodyAst) body_ = builtin
			? some(nu!FunBodyAst(alloc, immutable FunBodyAst.Builtin()))
			: extern_.has
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
	if (takeIndentOrDiagTopLevel(alloc, lexer))
		return parseNextSpec(
			alloc,
			lexer,
			ArrBuilder!SpecUseAst(),
			False,
			False,
			False,
			False,
			False,
			none!(FunBodyAst.Extern),
			none!Str,
			() => immutable Bool(takeNewlineOrSingleDedent(alloc, lexer) == NewlineOrDedent.newline));
	else
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
	return nextSpecOrStop(
		alloc,
		lexer,
		ArrBuilder!SpecUseAst(),
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
	immutable Arr!TypeParamAst typeParams,
) {
	immutable SigAstAndMaybeDedent sig = parseSigAfterNameAndSpace(alloc, lexer, start, name);
	immutable FunDeclStuff stuff = () {
		if (sig.dedents.has) {
			// Started at indent of 0
			verify(sig.dedents.force == 0);
			immutable SpecUsesAndSigFlagsAndKwBody extra = tryTake(lexer, "spec")
				? parseIndentedSpecUses(alloc, lexer)
				: emptySpecUsesAndSigFlagsAndKwBody;
			immutable Ptr!FunBodyAst body_ = optOr(extra.body_, () {
				take(lexer, "body");
				return nu!FunBodyAst(alloc, parseFunExprBody(alloc, lexer));
			});
			return FunDeclStuff(extra, body_);
		} else {
			immutable SpecUsesAndSigFlagsAndKwBody extra = parseSpecUsesAndSigFlagsAndKwBody(alloc, lexer);
			immutable Ptr!FunBodyAst body_ = optOr(extra.body_, () =>
				nu!FunBodyAst(alloc, parseFunExprBody(alloc, lexer)));
			return FunDeclStuff(extra, body_);
		}
	}();
	immutable SpecUsesAndSigFlagsAndKwBody extra = stuff.extra;
	return FunDeclAst(
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

void parseSpecOrStructOrFun(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	immutable Bool isPublic,
	ref ArrBuilder!SpecDeclAst specs,
	ref ArrBuilder!StructAliasAst structAliases,
	ref ArrBuilder!StructDeclAst structs,
	ref ArrBuilder!FunDeclAst funs,
) {
	immutable Pos start = curPos(lexer);
	immutable Sym name = takeName(alloc, lexer);
	immutable Arr!TypeParamAst typeParams = parseTypeParams(alloc, lexer);
	take(lexer, ' ');

	immutable Opt!NonFunKeywordAndIndent opKwAndIndent = parseNonFunKeyword(alloc, lexer);
	if (opKwAndIndent.has) {
		immutable NonFunKeywordAndIndent kwAndIndent = opKwAndIndent.force;
		immutable NonFunKeyword kw = kwAndIndent.keyword;
		immutable SpaceOrNewlineOrIndent after = kwAndIndent.after;
		immutable Opt!PuritySpecifier purity = after == SpaceOrNewlineOrIndent.space
			? parsePurity(alloc, lexer)
			: none!PuritySpecifier;

		immutable Bool tookIndent = () {
			final switch (after) {
				case SpaceOrNewlineOrIndent.space:
					return Bool(takeNewlineOrIndent(alloc, lexer) == NewlineOrIndent.indent);
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
				if (purity.has)
					todo!void("alias shouldn't have purity");
				immutable TypeAst.InstStruct target = parseStructType(alloc, lexer);
				takeDedentFromIndent1(alloc, lexer);
				add(
					alloc,
					structAliases,
					immutable StructAliasAst(range(lexer, start), isPublic, name, typeParams, target));
				break;
			case NonFunKeyword.builtinSpec:
				if (tookIndent)
					todo!void("builtin-spec has no body");
				if (purity.has)
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
				if (purity.has)
					todo!void("spec shouldn't have purity");
				immutable Arr!SigAst sigs = parseIndentedSigs(alloc, lexer);
				add(
					alloc,
					specs,
					immutable SpecDeclAst(range(lexer, start), isPublic, name, typeParams, SpecBodyAst(sigs)));
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
							return unreachable!(StructDeclAst.Body);
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
								? parseFields(alloc, lexer)
								: immutable StructDeclAst.Body.Record(
									none!ExplicitByValOrRef,
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
	} else {
		add(alloc, funs, parseFun(alloc, lexer, isPublic, start, name, typeParams));
	}
}

immutable(FileAst) parseFileInner(Alloc, SymAlloc)(ref Alloc alloc, ref Lexer!SymAlloc lexer) {
	skipShebang(lexer);
	skipBlankLines(alloc, lexer);
	immutable Arr!ImportAst imports = tryTake(lexer, "import ")
		? parseImportsNonIndented(alloc, lexer)
		: tryTake(lexer, "import\n")
		? parseImportsIndented(alloc, lexer)
		: emptyArr!ImportAst;
	immutable Arr!ImportAst exports = tryTake(lexer, "export ")
		? parseImportsNonIndented(alloc, lexer)
		: tryTake(lexer, "export\n")
		? parseImportsIndented(alloc, lexer)
		: emptyArr!ImportAst;

	ArrBuilder!SpecDeclAst specs;
	ArrBuilder!StructAliasAst structAliases;
	ArrBuilder!StructDeclAst structs;
	ArrBuilder!FunDeclAst funs;

	Bool isPublic = True;
	for (;;) {
		skipBlankLines(alloc, lexer);
		if (tryTake(lexer, '\0'))
			break;
		if (tryTake(lexer, "private\n")) {
			if (!isPublic)
				todo!void("already private");
			isPublic = False;
			skipBlankLines(alloc, lexer);
		}
		parseSpecOrStructOrFun!(Alloc, SymAlloc)(alloc, lexer, isPublic, specs, structAliases, structs, funs);
	}

	return immutable FileAst(
		nu!FileAstPart0(alloc, imports, exports, finishArr(alloc, specs)),
		nu!FileAstPart1(alloc, finishArr(alloc, structAliases), finishArr(alloc, structs), finishArr(alloc, funs)));
}
