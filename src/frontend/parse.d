module frontend.parse;

@safe @nogc pure nothrow:

import parseDiag : ParseDiagnostic;

import frontend.ast :
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
	createLexer,
	curChar,
	curPos,
	Lexer,
	NewlineOrDedent,
	NewlineOrIndent,
	pureSetjmp,
	range,
	skipBlankLines,
	skipShebang,
	SymAndIsReserved,
	take,
	takeDedent,
	takeIndent,
	takeIndentAfterNewline,
	takeName,
	takeNameAllowReserved,
	takeNewlineOrDedentAmount,
	takeNewlineOrIndent,
	takeNewlineOrSingleDedent,
	takeQuotedStr,
	throwAtChar,
	throwOnReservedName,
	tryTake,
	tryTakeIndentAfterNewline,
	tryTakeNewlineOrIndent;
import frontend.parseExpr : parseFunExprBody;
import frontend.parseType : parseStructType, parseType, tryParseTypeArgs;

import parseDiag : ParseDiag;

import util.bools : Bool, False, True;
import util.collection.arr : Arr, ArrWithSize, emptyArr, emptyArrWithSize;
import util.collection.arrBuilder : add, ArrBuilder, ArrWithSizeBuilder, finishArr;
import util.collection.str : CStr, NulTerminatedStr, Str;
import util.memory : nu;
import util.opt : force, has, none, Opt, optOr, some;
import util.path : childPath, Path, rootPath;
import util.ptr : Ptr, ptrTrustMe_mut;
import util.result : fail, Result, success;
import util.sourceRange : Pos;
import util.sym : AllSymbols, shortSymAlphaLiteralValue, Sym;
import util.types : u8;
import util.util : todo, unreachable, verify;

immutable(Result!(FileAst, ParseDiagnostic)) parseFile(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref AllSymbols!SymAlloc allSymbols,
	immutable NulTerminatedStr source,
) {
	Lexer!SymAlloc lexer = createLexer(ptrTrustMe_mut(allSymbols), source);
	immutable int i = pureSetjmp(lexer.jump_buffer);
	return i == 0
		? success!(FileAst, ParseDiagnostic)(parseFileInner(alloc, lexer))
		: fail!(FileAst, ParseDiagnostic)(lexer.diagnostic_);
}

private:

immutable(Arr!TypeParamAst) parseTypeParams(Alloc, SymAlloc)(ref Alloc alloc, ref Lexer!SymAlloc lexer) {
	if (lexer.tryTake('<')) {
		ArrBuilder!TypeParamAst res;
		do {
			immutable Pos start = lexer.curPos;
			lexer.take('?');
			immutable Sym name = lexer.takeName();
			add(alloc, res, TypeParamAst(lexer.range(start), name));
		} while (lexer.tryTake(", "));
		lexer.take('>');
		return finishArr(alloc, res);
	} else
		return emptyArr!TypeParamAst;
}

immutable(PuritySpecifier) parsePurity(SymAlloc)(ref Lexer!SymAlloc lexer) {
	if (lexer.tryTake("data"))
		return PuritySpecifier.data;
	else if (lexer.tryTake("mut"))
		return PuritySpecifier.mut;
	else if (lexer.tryTake("sendable"))
		return PuritySpecifier.sendable;
	else if (lexer.tryTake("force-data"))
		return PuritySpecifier.forceData;
	else if (lexer.tryTake("force-sendable"))
		return PuritySpecifier.forceSendable;
	else
		return lexer.throwAtChar!PuritySpecifier(ParseDiag(ParseDiag.ExpectedPurityAfterSpace()));
}

immutable(ImportAst) parseSingleImport(Alloc, SymAlloc)(ref Alloc alloc, ref Lexer!SymAlloc lexer) {
	immutable Pos start = lexer.curPos;
	u8 nDots = 0;
	while (lexer.tryTake('.')) {
		verify(nDots < 255);
		nDots++;
	}

	immutable(Ptr!Path) addPathComponents(immutable Ptr!Path path) {
		return lexer.tryTake('.')
			? addPathComponents(childPath(alloc, path, lexer.takeName()))
			: path;
	}
	immutable Ptr!Path path = addPathComponents(rootPath(alloc, lexer.takeName()));
	return ImportAst(lexer.range(start), nDots, path);
}

struct ParamsAndMaybeDedent {
	immutable ArrWithSize!ParamAst params;
	// 0 if we took a newline but it didn't change the indent level from before parsing params.
	immutable Opt!size_t dedents;
}

immutable(ParamAst) parseSingleParam(Alloc, SymAlloc)(ref Alloc alloc, ref Lexer!SymAlloc lexer) {
	immutable Pos start = lexer.curPos();
	immutable Sym name = lexer.takeName();
	lexer.take(' ');
	immutable TypeAst type = parseType(alloc, lexer);
	return ParamAst(lexer.range(start), name, type);
}

immutable(ArrWithSize!ParamAst) parseParenthesizedParams(Alloc, SymAlloc)(ref Alloc alloc, ref Lexer!SymAlloc lexer) {
	lexer.take('(');
	if (lexer.tryTake(')'))
		return emptyArrWithSize!ParamAst;
	else {
		ArrWithSizeBuilder!ParamAst res;
		for (;;) {
			add(alloc, res, parseSingleParam(alloc, lexer));
			if (lexer.tryTake(')'))
				break;
			lexer.take(", ");
		}
		return finishArr(alloc, res);
	}
}

immutable(ParamsAndMaybeDedent) parseIndentedParams(Alloc, SymAlloc)(ref Alloc alloc, ref Lexer!SymAlloc lexer) {
	ArrWithSizeBuilder!ParamAst res;
	for (;;) {
		add(alloc, res, parseSingleParam(alloc, lexer));
		immutable size_t dedents = lexer.takeNewlineOrDedentAmount();
		if (dedents != 0)
			return ParamsAndMaybeDedent(finishArr(alloc, res), some(dedents - 1));
	}
}

immutable(ParamsAndMaybeDedent) parseParams(Alloc, SymAlloc)(ref Alloc alloc, ref Lexer!SymAlloc lexer) {
	immutable Opt!NewlineOrIndent opNi = lexer.tryTakeNewlineOrIndent();
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
	immutable SigAst sig;
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
	immutable SigAst sigAst = SigAst(lexer.range(start), name, returnType, params.params);
	return SigAstAndMaybeDedent(sigAst, params.dedents);
}

immutable(SigAstAndDedent) parseSig(Alloc, SymAlloc)(ref Alloc alloc, ref Lexer!SymAlloc lexer) {
	immutable Pos start = lexer.curPos;
	immutable Sym sigName = lexer.takeName();
	lexer.take(' ');
	immutable SigAstAndMaybeDedent s = parseSigAfterNameAndSpace(alloc, lexer, start, sigName);
	immutable size_t dedents = s.dedents.has ? s.dedents.force : lexer.takeNewlineOrDedentAmount();
	return SigAstAndDedent(s.sig, dedents);
}

immutable(Arr!ImportAst) parseImportsNonIndented(Alloc, SymAlloc)(ref Alloc alloc, ref Lexer!SymAlloc lexer) {
	ArrBuilder!ImportAst res;
	do {
		add(alloc, res, parseSingleImport(alloc, lexer));
	} while (lexer.tryTake(' '));
	lexer.take('\n');
	return finishArr(alloc, res);
}

immutable(Arr!ImportAst) parseImportsIndented(Alloc, SymAlloc)(ref Alloc alloc, ref Lexer!SymAlloc lexer) {
	ArrBuilder!ImportAst res;
	lexer.takeIndentAfterNewline();
	do {
		add(alloc, res, parseSingleImport(alloc, lexer));
	} while (lexer.takeNewlineOrSingleDedent() == NewlineOrDedent.newline);
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

immutable(Opt!NonFunKeywordAndIndent) tryTakeKw(SymAlloc)(
	ref Lexer!SymAlloc lexer,
	immutable CStr kwSpace,
	immutable CStr kwNl,
	immutable NonFunKeyword keyword
) {
	return lexer.tryTake(kwSpace)
		? some(NonFunKeywordAndIndent(keyword, SpaceOrNewlineOrIndent.space))
		: lexer.tryTake(kwNl)
		? some(NonFunKeywordAndIndent(
			keyword,
			spaceOrNewlineOrIndentFromNewlineOrIndent(lexer.tryTakeIndentAfterNewline())))
		: none!NonFunKeywordAndIndent;
}

immutable(Opt!NonFunKeywordAndIndent) parseNonFunKeyword(SymAlloc)(ref Lexer!SymAlloc lexer) {
	switch (lexer.curChar) {
		case 'a':
			return tryTakeKw(lexer, "alias ", "alias\n", NonFunKeyword.alias_);
		case 'b':
			immutable Opt!NonFunKeywordAndIndent res = tryTakeKw(lexer, "builtin ", "builtin\n", NonFunKeyword.builtin);
			return res.has ? res : tryTakeKw(lexer, "builtin-spec ", "builtin-spec\n", NonFunKeyword.builtinSpec);
		case 'e':
			return tryTakeKw(lexer, "extern-ptr ", "extern-ptr\n", NonFunKeyword.externPtr);
		case 'r':
			return tryTakeKw(lexer, "record ", "record\n", NonFunKeyword.record);
		case 's':
			return tryTakeKw(lexer, "spec ", "spec\n", NonFunKeyword.spec);
		case 'u':
			return tryTakeKw(lexer, "union ", "union\n", NonFunKeyword.union_);
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
		immutable Pos start = lexer.curPos;
		immutable Sym name = lexer.takeName();
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
				lexer.take(' ');
				immutable Bool isMutable = lexer.tryTake("mut ");
				immutable TypeAst type = parseType(alloc, lexer);
				add(alloc, res, immutable StructDeclAst.Body.Record.Field(lexer.range(start), isMutable, name, type));
		}
		isFirstLine = False;
	} while (lexer.takeNewlineOrSingleDedent() == NewlineOrDedent.newline);
	return StructDeclAst.Body.Record(explicitByValOrRef, finishArr(alloc, res));
}

immutable(Arr!(TypeAst.InstStruct)) parseUnionMembers(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
) {
	ArrBuilder!(TypeAst.InstStruct) res;
	do {
		immutable Pos start = lexer.curPos;
		immutable Sym name = lexer.takeName();
		immutable Arr!TypeAst typeArgs = tryParseTypeArgs(alloc, lexer);
		add(alloc, res, immutable TypeAst.InstStruct(lexer.range(start), name, typeArgs));
	} while (lexer.takeNewlineOrSingleDedent() == NewlineOrDedent.newline);
	return finishArr(alloc, res);
}

struct SpecUsesAndSigFlagsAndKwBody {
	immutable Arr!SpecUseAst specUses;
	immutable Bool noCtx;
	immutable Bool summon;
	immutable Bool unsafe;
	immutable Bool trusted;
	immutable Opt!FunBodyAst body_; // 'builtin' or 'extern'
}

immutable(SpecUsesAndSigFlagsAndKwBody) emptySpecUsesAndSigFlagsAndKwBody =
	SpecUsesAndSigFlagsAndKwBody(
		emptyArr!SpecUseAst,
		False,
		False,
		False,
		False,
		none!FunBodyAst,
	);

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
	if (lexer.tryTake('<')) {
		immutable Str mangledName = lexer.takeQuotedStr(alloc);
		lexer.take('>');
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
	immutable Pos start = lexer.curPos;
	immutable SymAndIsReserved name = lexer.takeNameAllowReserved();
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
			default:
				return lexer.throwOnReservedName!SpecUsesAndSigFlagsAndKwBody(name.range, name.sym);
		}
	} else {
		immutable Arr!TypeAst typeArgs = tryParseTypeArgs(alloc, lexer);
		add(alloc, specUses, immutable SpecUseAst(lexer.range(start), name.sym, typeArgs));
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
		immutable Opt!FunBodyAst body_ = builtin
			? some(immutable FunBodyAst(immutable FunBodyAst.Builtin()))
			: extern_.has
			? some(immutable FunBodyAst(extern_.force))
			: none!FunBodyAst;
		return SpecUsesAndSigFlagsAndKwBody(finishArr(alloc, specUses), noCtx, summon, unsafe, trusted, body_);
	}
}

// TODO: handle 'noctx' and friends too! (share code with parseSpecUsesAndSigFlagsAndKwBody)
immutable(SpecUsesAndSigFlagsAndKwBody) parseIndentedSpecUses(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
) {
	lexer.takeIndent();
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
		() => immutable Bool(lexer.takeNewlineOrSingleDedent() == NewlineOrDedent.newline));
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
		() => lexer.tryTake(' '));
}

//TODO:RENAME
struct FunDeclStuff {
	immutable SpecUsesAndSigFlagsAndKwBody extra;
	immutable FunBodyAst body_;
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
			immutable SpecUsesAndSigFlagsAndKwBody extra = lexer.tryTake("spec")
				? parseIndentedSpecUses(alloc, lexer)
				: emptySpecUsesAndSigFlagsAndKwBody;
			immutable FunBodyAst body_ = extra.body_.optOr(() {
				lexer.take("body");
				return immutable FunBodyAst(parseFunExprBody(alloc, lexer));
			});
			return FunDeclStuff(extra, body_);
		} else {
			immutable SpecUsesAndSigFlagsAndKwBody extra = parseSpecUsesAndSigFlagsAndKwBody(alloc, lexer);
			immutable FunBodyAst body_ = extra.body_.optOr(() =>
				immutable FunBodyAst(parseFunExprBody(alloc, lexer)));
			return FunDeclStuff(extra, body_);
		}
	}();
	immutable SpecUsesAndSigFlagsAndKwBody extra = stuff.extra;
	return FunDeclAst(
		isPublic,
		typeParams,
		sig.sig,
		extra.specUses,
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
	immutable Pos start = lexer.curPos;
	immutable Sym name = lexer.takeName;
	immutable Arr!TypeParamAst typeParams = parseTypeParams(alloc, lexer);
	lexer.take(' ');

	immutable Opt!NonFunKeywordAndIndent opKwAndIndent = parseNonFunKeyword(lexer);
	if (opKwAndIndent.has) {
		immutable NonFunKeywordAndIndent kwAndIndent = opKwAndIndent.force;
		immutable NonFunKeyword kw = kwAndIndent.keyword;
		immutable SpaceOrNewlineOrIndent after = kwAndIndent.after;
		immutable Opt!PuritySpecifier purity = after == SpaceOrNewlineOrIndent.space
			? some(parsePurity(lexer))
			: none!PuritySpecifier;

		immutable Bool tookIndent = () {
			final switch (after) {
				case SpaceOrNewlineOrIndent.space:
					return Bool(lexer.takeNewlineOrIndent() == NewlineOrIndent.indent);
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
				lexer.takeDedent();
				add(
					alloc,
					structAliases,
					immutable StructAliasAst(lexer.range(start), isPublic, name, typeParams, target));
				break;
			case NonFunKeyword.builtinSpec:
				if (tookIndent)
					todo!void("builtin-spec has no body");
				if (purity.has)
					todo!void("spec shouldn't have purity");
				add(alloc, specs, immutable SpecDeclAst(
					lexer.range(start),
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
					immutable SpecDeclAst(lexer.range(start), isPublic, name, typeParams, SpecBodyAst(sigs)));
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
							return tookIndent
								? immutable StructDeclAst.Body(
									immutable StructDeclAst.Body.Union(parseUnionMembers(alloc, lexer)))
								: throwAtChar!(StructDeclAst.Body)(lexer, ParseDiag(ParseDiag.UnionCantBeEmpty()));
					}
				}();
				add(
					alloc,
					structs,
					immutable StructDeclAst(lexer.range(start), isPublic, name, typeParams, purity, body_));
				break;
		}
	} else {
		add(alloc, funs, parseFun(alloc, lexer, isPublic, start, name, typeParams));
	}
}

immutable(FileAst) parseFileInner(Alloc, SymAlloc)(ref Alloc alloc, ref Lexer!SymAlloc lexer) {
	lexer.skipShebang();
	lexer.skipBlankLines();
	immutable Arr!ImportAst imports = lexer.tryTake("import ")
		? parseImportsNonIndented(alloc, lexer)
		: lexer.tryTake("import\n")
		? parseImportsIndented(alloc, lexer)
		: emptyArr!ImportAst;
	immutable Arr!ImportAst exports = lexer.tryTake("export ")
		? parseImportsNonIndented(alloc, lexer)
		: lexer.tryTake("export\n")
		? parseImportsIndented(alloc, lexer)
		: emptyArr!ImportAst;

	ArrBuilder!SpecDeclAst specs;
	ArrBuilder!StructAliasAst structAliases;
	ArrBuilder!StructDeclAst structs;
	ArrBuilder!FunDeclAst funs;

	Bool isPublic = True;
	for (;;) {
		lexer.skipBlankLines();
		if (lexer.tryTake('\0'))
			break;
		if (lexer.tryTake("private\n")) {
			if (!isPublic)
				todo!void("already private");
			isPublic = False;
			lexer.skipBlankLines();
		}
		parseSpecOrStructOrFun!(Alloc, SymAlloc)(alloc, lexer, isPublic, specs, structAliases, structs, funs);
	}

	return immutable FileAst(
		nu!FileAstPart0(alloc, imports, exports, finishArr(alloc, specs)),
		nu!FileAstPart1(alloc, finishArr(alloc, structAliases), finishArr(alloc, structs), finishArr(alloc, funs)));
}
