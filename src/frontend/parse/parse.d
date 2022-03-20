module frontend.parse.parse;

@safe @nogc pure nothrow:

import frontend.parse.ast :
	bogusTypeAst,
	FileAst,
	FunBodyAst,
	FunDeclAst,
	FunDeclAstFlags,
	ImportAst,
	ImportsOrExportsAst,
	LiteralIntOrNat,
	ModifierAst,
	NameAndRange,
	ParamAst,
	ParamsAst,
	SigAst,
	SpecBodyAst,
	SpecDeclAst,
	SpecSigAst,
	SpecUseAst,
	StructAliasAst,
	StructDeclAst,
	TestAst,
	TypeAst;
import frontend.parse.lexer :
	addDiagAtChar,
	addDiagUnexpectedCurToken,
	alloc,
	allSymbols,
	createLexer,
	curPos,
	getCurNameAndRange,
	getCurSym,
	getPeekToken,
	Lexer,
	NewlineOrDedent,
	NewlineOrIndent,
	nextToken,
	peekToken,
	range,
	skipBlankLinesAndGetDocComment,
	skipUntilNewlineNoDiag,
	takeDedentFromIndent1,
	takeIndentOrDiagTopLevel,
	takeIntOrNat,
	takeName,
	takeNameAndRange,
	takeNameOrOperator,
	takeNameOrUnderscore,
	takeNewlineOrDedentAmount,
	takeNewlineOrIndent_topLevel,
	takeNewlineOrSingleDedent,
	takeNewline_topLevel,
	takeOrAddDiagExpectedOperator,
	takeOrAddDiagExpectedToken,
	takeQuotedStr,
	takeTypeArgsEnd,
	Token,
	tryTakeIndent,
	tryTakeName,
	tryTakeOperator,
	tryTakeToken;
import frontend.parse.parseExpr : parseFunExprBody;
import frontend.parse.parseType : parseType, tryParseTypeArg, tryParseTypeArgsBracketed;
import model.diag : DiagnosticWithinFile;
import model.model : FieldMutability, Visibility;
import model.parseDiag : ParseDiag;
import util.alloc.alloc : Alloc;
import util.col.arr : emptyArr, emptySmallArray, small;
import util.col.arrBuilder : add, ArrBuilder, finishArr;
import util.col.str : SafeCStr;
import util.conv : safeToUshort;
import util.memory : allocate;
import util.opt : force, has, none, Opt, some;
import util.path : AllPaths, childPath, Path, PathOrRelPath, rootPath;
import util.perf : Perf, PerfMeasure, withMeasure;
import util.ptr : Ptr, ptrTrustMe_mut;
import util.sourceRange : Pos, RangeWithinFile;
import util.sym : AllSymbols, Operator, shortSym, shortSymValue, Sym, symEq, symOfStr;
import util.util : todo, unreachable, verify;

immutable(FileAst) parseFile(
	ref Alloc alloc,
	scope ref Perf perf,
	ref AllPaths allPaths,
	ref AllSymbols allSymbols,
	ref ArrBuilder!DiagnosticWithinFile diagsBuilder,
	immutable SafeCStr source,
) {
	return withMeasure!(immutable FileAst, () {
		Lexer lexer = createLexer(
			ptrTrustMe_mut(alloc),
			ptrTrustMe_mut(allSymbols),
			ptrTrustMe_mut(diagsBuilder),
			source);
		return parseFileInner(allPaths, lexer);
	})(alloc, perf, PerfMeasure.parseFile);
}

private:

immutable(NameAndRange[]) parseTypeParams(ref Lexer lexer) {
	if (tryTakeOperator(lexer, Operator.less)) {
		ArrBuilder!NameAndRange res;
		do {
			add(lexer.alloc, res, takeNameAndRange(lexer));
		} while (tryTakeToken(lexer, Token.comma));
		takeTypeArgsEnd(lexer);
		return finishArr(lexer.alloc, res);
	} else
		return emptyArr!NameAndRange;
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

immutable(PathOrRelPath) parseImportPath(ref AllPaths allPaths, ref Lexer lexer) {
	immutable Opt!ushort nParents = () {
		if (tryTakeToken(lexer, Token.dot)) {
			takeOrAddDiagExpectedOperator(lexer, Operator.divide, ParseDiag.Expected.Kind.slash);
			return some!ushort(0);
		} else if (tryTakeOperator(lexer, Operator.range)) {
			takeOrAddDiagExpectedOperator(lexer, Operator.divide, ParseDiag.Expected.Kind.slash);
			return some(safeToUshort(takeDotDotSlashes(lexer, 1)));
		} else
			return none!ushort;
	}();
	return immutable PathOrRelPath(
		nParents,
		addPathComponents(allPaths, lexer, rootPath(allPaths, takeName(lexer))));
}

immutable(size_t) takeDotDotSlashes(ref Lexer lexer, immutable size_t acc) {
	if (tryTakeOperator(lexer, Operator.range)) {
		takeOrAddDiagExpectedOperator(lexer, Operator.divide, ParseDiag.Expected.Kind.slash);
		return takeDotDotSlashes(lexer, acc + 1);
	} else
		return acc;
}

immutable(Path) addPathComponents(ref AllPaths allPaths, ref Lexer lexer, immutable Path acc) {
	return tryTakeOperator(lexer, Operator.divide)
		? addPathComponents(allPaths, lexer, childPath(allPaths, acc, takeName(lexer)))
		: acc;
}

immutable(ImportAndDedent) parseSingleModuleImportOnOwnLine(ref AllPaths allPaths, ref Lexer lexer) {
	immutable Pos start = curPos(lexer);
	immutable PathOrRelPath path = parseImportPath(allPaths, lexer);
	immutable NamesAndDedent names = () {
		if (tryTakeToken(lexer, Token.colon)) {
			if (tryTakeIndent(lexer, 1))
				return parseIndentedImportNames(lexer, start);
			else {
				immutable Sym[] names = parseSingleImportNamesOnSingleLine(lexer);
				return immutable NamesAndDedent(
					some!(Sym[])(names),
					range(lexer, start),
					takeNewlineOrSingleDedent(lexer));
			}
		}
		return immutable NamesAndDedent(none!(Sym[]), range(lexer, start), takeNewlineOrSingleDedent(lexer));
	}();
	return immutable ImportAndDedent(immutable ImportAst(names.range, path, names.names), names.dedented);
}

immutable(NamesAndDedent) parseIndentedImportNames(ref Lexer lexer, immutable Pos start) {
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
						todo!void("!");
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
	return immutable NamesAndDedent(some!(Sym[])(finishArr(lexer.alloc, names)), res.range, res.newlineOrDedent);
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

struct ParamsAndMaybeDedent {
	immutable ParamsAst params;
	// 0 if we took a newline but it didn't change the indent level from before parsing params.
	immutable Opt!size_t dedents;
}

immutable(ParamAst) parseSingleParam(ref Lexer lexer) {
	immutable Pos start = curPos(lexer);
	immutable Opt!Sym name = takeNameOrUnderscore(lexer);
	immutable TypeAst type = parseType(lexer);
	return immutable ParamAst(range(lexer, start), name, type);
}

immutable(ParamsAst) parseParenthesizedParams(ref Lexer lexer) {
	if (tryTakeToken(lexer, Token.parenRight))
		return immutable ParamsAst(emptySmallArray!ParamAst);
	else if (tryTakeToken(lexer, Token.dot3)) {
		immutable ParamAst param = parseSingleParam(lexer);
		takeOrAddDiagExpectedToken(lexer, Token.parenRight, ParseDiag.Expected.Kind.closingParen);
		return immutable ParamsAst(allocate(lexer.alloc, immutable ParamsAst.Varargs(param)));
	} else {
		ArrBuilder!ParamAst res;
		for (;;) {
			add(lexer.alloc, res, parseSingleParam(lexer));
			if (tryTakeToken(lexer, Token.parenRight))
				break;
			if (!takeOrAddDiagExpectedToken(lexer, Token.comma, ParseDiag.Expected.Kind.comma)) {
				skipUntilNewlineNoDiag(lexer);
				break;
			}
		}
		return immutable ParamsAst(finishArr(lexer.alloc, res));
	}
}

immutable(ParamsAndMaybeDedent) parseIndentedParams(ref Lexer lexer) {
	ArrBuilder!ParamAst res;
	for (;;) {
		add(lexer.alloc, res, parseSingleParam(lexer));
		immutable size_t dedents = takeNewlineOrDedentAmount(lexer, 1);
		if (dedents != 0)
			return immutable ParamsAndMaybeDedent(
				immutable ParamsAst(finishArr(lexer.alloc, res)),
				some(dedents - 1));
	}
}

immutable(ParamsAndMaybeDedent) parseParams(ref Lexer lexer) {
	if (tryTakeToken(lexer, Token.parenLeft))
		return ParamsAndMaybeDedent(parseParenthesizedParams(lexer), none!size_t);
	else
		final switch (takeNewlineOrIndent_topLevel(lexer)) {
			case NewlineOrIndent.newline:
				return immutable ParamsAndMaybeDedent(immutable ParamsAst(emptyArr!ParamAst), some!size_t(0));
			case NewlineOrIndent.indent:
				return parseIndentedParams(lexer);
		}
}

struct SigAstAndMaybeDedent {
	immutable SigAst sig;
	immutable Opt!size_t dedents;
}

struct SpecSigAstAndMaybeDedent {
	immutable SpecSigAst sig;
	immutable Opt!size_t dedents;
}

struct SpecSigAstAndDedent {
	immutable SpecSigAst sig;
	immutable size_t dedents;
}

immutable(SigAstAndMaybeDedent) parseSigAfterNameAndSpace(ref Lexer lexer, immutable Pos start, immutable Sym name) {
	immutable TypeAst returnType = parseType(lexer);
	immutable ParamsAndMaybeDedent params = parseParams(lexer);
	return immutable SigAstAndMaybeDedent(
		immutable SigAst(range(lexer, start), name, returnType, params.params),
		params.dedents);
}

immutable(SpecSigAstAndMaybeDedent) parseSpecSigAfterNameAndSpace(
	ref Lexer lexer,
	immutable SafeCStr comment,
	immutable Pos start,
	immutable Sym name,
) {
	immutable TypeAst returnType = parseType(lexer);
	immutable ParamsAndMaybeDedent params = parseParams(lexer);
	return immutable SpecSigAstAndMaybeDedent(
		immutable SpecSigAst(comment, immutable SigAst(range(lexer, start), name, returnType, params.params)),
		params.dedents);
}

immutable(SpecSigAstAndDedent) parseSpecSig(ref Lexer lexer, immutable uint curIndent) {
	// TODO: this doesn't work because the lexer already skipped comments
	immutable SafeCStr comment = skipBlankLinesAndGetDocComment(lexer);
	immutable Pos start = curPos(lexer);
	immutable Sym sigName = takeNameOrOperator(lexer);
	immutable SpecSigAstAndMaybeDedent s = parseSpecSigAfterNameAndSpace(lexer, comment, start, sigName);
	immutable size_t dedents = has(s.dedents) ? force(s.dedents) : takeNewlineOrDedentAmount(lexer, curIndent);
	return SpecSigAstAndDedent(s.sig, dedents);
}

immutable(SpecSigAst[]) parseIndentedSigs(ref Lexer lexer) {
	final switch (takeNewlineOrIndent_topLevel(lexer)) {
		case NewlineOrIndent.newline:
			return emptyArr!SpecSigAst;
		case NewlineOrIndent.indent:
			ArrBuilder!SpecSigAst res;
			for (;;) {
				immutable SpecSigAstAndDedent sd = parseSpecSig(lexer, 1);
				add(lexer.alloc, res, sd.sig);
				if (sd.dedents != 0) {
					// We started at in indent level of only 1, so can't go down more than 1.
					verify(sd.dedents == 1);
					return finishArr(lexer.alloc, res);
				}
			}

	}
}

immutable(StructDeclAst.Body.Enum.Member[]) parseEnumOrFlagsMembers(ref Lexer lexer) {
	final switch (takeNewlineOrIndent_topLevel(lexer)) {
		case NewlineOrIndent.newline:
			return emptyArr!(StructDeclAst.Body.Enum.Member);
		case NewlineOrIndent.indent:
			ArrBuilder!(StructDeclAst.Body.Enum.Member) res;
			immutable(StructDeclAst.Body.Enum.Member[]) recur() {
				immutable Pos start = curPos(lexer);
				immutable Sym name = takeName(lexer);
				immutable Opt!LiteralIntOrNat value = tryTakeToken(lexer, Token.equal)
					? some(takeIntOrNat(lexer))
					: none!LiteralIntOrNat;
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

struct SpecUsesAndSigFlagsAndKwBody {
	immutable SpecUseAst[] specUses;
	immutable FunDeclAstFlags flags;
	immutable Opt!FunBodyAst body_; // none for 'builtin' or 'extern'
}

immutable(SpecUsesAndSigFlagsAndKwBody) emptySpecUsesAndSigFlagsAndKwBody =
	immutable SpecUsesAndSigFlagsAndKwBody(
		[],
		immutable FunDeclAstFlags(),
		none!FunBodyAst);

immutable(FunBodyAst.Extern) takeExternName(ref Lexer lexer, immutable bool isGlobal) {
	immutable Opt!Sym libraryName = tryTakeOperator(lexer, Operator.less)
		? some(takeExternLibraryName(lexer))
		: none!Sym;
	return immutable FunBodyAst.Extern(isGlobal, libraryName);
}

immutable(Sym) takeExternLibraryName(ref Lexer lexer) {
	immutable string res = takeQuotedStr(lexer);
	takeTypeArgsEnd(lexer);
	return symOfStr(lexer.allSymbols, res);
}

immutable(SpecUsesAndSigFlagsAndKwBody) parseNextSpec(
	ref Lexer lexer,
	ref ArrBuilder!SpecUseAst specUses,
	immutable FunDeclAstFlags flags,
	immutable bool builtin,
	immutable Opt!(FunBodyAst.Extern) extern_,
	scope immutable(bool) delegate() @safe @nogc pure nothrow canTakeNext,
) {
	immutable Pos start = curPos(lexer);
	immutable Token token = nextToken(lexer);

	scope immutable(SpecUsesAndSigFlagsAndKwBody) setExtern(immutable bool isGlobal) {
		if (has(extern_))
			todo!void("duplicate");
		immutable Opt!(FunBodyAst.Extern) extern2 = some(takeExternName(lexer, isGlobal));
		return nextSpecOrStop(lexer, specUses, flags, builtin, extern2, canTakeNext);
	}

	switch (token) {
		case Token.noCtx:
			if (flags.noCtx) todo!void("duplicate");
			return nextSpecOrStop(lexer, specUses, flags.withNoCtx(), builtin, extern_, canTakeNext);
		case Token.noDoc:
			if (flags.noDoc) todo!void("duplicate");
			return nextSpecOrStop(lexer, specUses, flags.withNoDoc(), builtin, extern_, canTakeNext);
		case Token.summon:
			if (flags.summon) todo!void("duplicate");
			return nextSpecOrStop(lexer, specUses, flags.withSummon(), builtin, extern_, canTakeNext);
		case Token.unsafe:
			if (flags.unsafe) todo!void("duplicate");
			return nextSpecOrStop(lexer, specUses, flags.withUnsafe(), builtin, extern_, canTakeNext);
		case Token.trusted:
			if (flags.trusted) todo!void("duplicate");
			return nextSpecOrStop(lexer, specUses, flags.withTrusted(), builtin, extern_, canTakeNext);
		case Token.builtin:
			if (builtin) todo!void("duplicate");
			return nextSpecOrStop(lexer, specUses, flags, true, extern_, canTakeNext);
		case Token.extern_:
			return setExtern(false);
		case Token.global:
			return setExtern(true);
		case Token.name:
			immutable NameAndRange name = getCurNameAndRange(lexer, start);
			immutable TypeAst[] typeArgs = tryParseTypeArgsBracketed(lexer);
			add(lexer.alloc, specUses, immutable SpecUseAst(range(lexer, start), name, small(typeArgs)));
			return nextSpecOrStop(lexer, specUses, flags, builtin, extern_, canTakeNext);
		default:
			addDiagUnexpectedCurToken(lexer, start, token);
			return nextSpecOrStop(lexer, specUses, flags, builtin, extern_, canTakeNext);
	}
}

immutable(SpecUsesAndSigFlagsAndKwBody) nextSpecOrStop(
	ref Lexer lexer,
	ref ArrBuilder!SpecUseAst specUses,
	immutable FunDeclAstFlags flags,
	immutable bool builtin,
	immutable Opt!(FunBodyAst.Extern) extern_,
	scope immutable(bool) delegate() @safe @nogc pure nothrow canTakeNext,
) {
	if (canTakeNext())
		return parseNextSpec(lexer, specUses, flags, builtin, extern_, canTakeNext);
	else {
		if (flags.unsafe && flags.trusted)
			todo!void("'unsafe trusted' is redundant");
		if (builtin && flags.trusted)
			todo!void("'builtin trusted' is silly as builtin fun has no body");
		if (has(extern_) && flags.trusted)
			todo!void("'extern trusted' is silly as extern fun has no body");

		//TODO: assert 'builtin' and 'extern' and 'extern-global' can't be set together.
		//Also, 'extern-global' should always be 'unsafe noctx'
		immutable Opt!FunBodyAst body_ = builtin
			? some(immutable FunBodyAst(immutable FunBodyAst.Builtin()))
			: has(extern_)
			? some(immutable FunBodyAst(extern_.force))
			: none!FunBodyAst;
		return SpecUsesAndSigFlagsAndKwBody(finishArr(lexer.alloc, specUses), flags, body_);
	}
}

// TODO: handle 'noctx' and friends too! (share code with parseSpecUsesAndSigFlagsAndKwBody)
immutable(SpecUsesAndSigFlagsAndKwBody) parseIndentedSpecUses(ref Lexer lexer) {
	if (takeIndentOrDiagTopLevel(lexer)) {
		ArrBuilder!SpecUseAst builder;
		return parseNextSpec(
			lexer,
			builder,
			immutable FunDeclAstFlags(),
			false,
			none!(FunBodyAst.Extern),
			() => takeNewlineOrSingleDedent(lexer) == NewlineOrDedent.newline);
	} else
		return immutable SpecUsesAndSigFlagsAndKwBody(
			emptyArr!SpecUseAst,
			immutable FunDeclAstFlags(),
			none!FunBodyAst);
}

immutable(SpecUsesAndSigFlagsAndKwBody) parseSpecUsesAndSigFlagsAndKwBody(ref Lexer lexer) {
	// Unlike indented specs, we check for a separator on first spec, so use nextSpecOrStop instead of parseNextSpec
	ArrBuilder!SpecUseAst builder;
	return nextSpecOrStop(
		lexer,
		builder,
		immutable FunDeclAstFlags(),
		false,
		none!(FunBodyAst.Extern),
		() => !peekToken(lexer, Token.newline));
}

//TODO:RENAME
struct FunDeclStuff {
	immutable SpecUsesAndSigFlagsAndKwBody extra;
	immutable FunBodyAst body_;
}

immutable(FunDeclAst) parseFun(
	ref Lexer lexer,
	immutable SafeCStr docComment,
	immutable Visibility visibility,
	immutable Pos start,
	immutable Sym name,
	immutable NameAndRange[] typeParams,
) {
	immutable SigAstAndMaybeDedent sig = parseSigAfterNameAndSpace(lexer, start, name);
	immutable FunDeclStuff stuff = () {
		if (has(sig.dedents)) {
			// Started at indent of 0
			verify(force(sig.dedents) == 0);
			immutable SpecUsesAndSigFlagsAndKwBody extra = tryTakeToken(lexer, Token.spec)
				? parseIndentedSpecUses(lexer)
				: emptySpecUsesAndSigFlagsAndKwBody;
			immutable FunBodyAst body_ = has(extra.body_) ? force(extra.body_) : () {
				takeOrAddDiagExpectedToken(lexer, Token.body, ParseDiag.Expected.Kind.bodyKeyword);
				return immutable FunBodyAst(parseFunExprBody(lexer));
			}();
			return immutable FunDeclStuff(extra, body_);
		} else {
			immutable SpecUsesAndSigFlagsAndKwBody extra = parseSpecUsesAndSigFlagsAndKwBody(lexer);
			immutable FunBodyAst body_ = has(extra.body_)
				? force(extra.body_)
				: immutable FunBodyAst(parseFunExprBody(lexer));
			return immutable FunDeclStuff(extra, body_);
		}
	}();
	immutable SpecUsesAndSigFlagsAndKwBody extra = stuff.extra;
	return immutable FunDeclAst(
		range(lexer, start),
		docComment,
		small(typeParams),
		sig.sig,
		extra.specUses,
		visibility,
		extra.flags,
		stuff.body_);
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
			immutable Opt!(Ptr!TypeAst) typeArg = tryParseTypeArg(lexer);
			addStruct(() => immutable StructDeclAst.Body(
				immutable StructDeclAst.Body.Enum(typeArg, small(parseEnumOrFlagsMembers(lexer)))));
			break;
		case Token.externPtr:
			nextToken(lexer);
			addStruct(() => immutable StructDeclAst.Body(immutable StructDeclAst.Body.ExternPtr()));
			takeNewline_topLevel(lexer);
			break;
		case Token.flags:
			nextToken(lexer);
			immutable Opt!(Ptr!TypeAst) typeArg = tryParseTypeArg(lexer);
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
			addStruct(() {
				immutable StructDeclAst.Body.Union.Member[] members = () {
					final switch (takeNewlineOrIndent_topLevel(lexer)) {
						case NewlineOrIndent.newline:
							//TODO: this should be a checker error, not parse error
							addDiagAtChar(lexer, immutable ParseDiag(
								immutable ParseDiag.UnionCantBeEmpty()));
							return emptyArr!(StructDeclAst.Body.Union.Member);
						case NewlineOrIndent.indent:
							return parseUnionMembers(lexer);
					}
				}();
				return immutable StructDeclAst.Body(immutable StructDeclAst.Body.Union(members));
			});
			break;
		default:
			add(lexer.alloc, funs, parseFun(lexer, docComment, visibility, start, name, typeParams));
			break;
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
		if (!has(name) || !symEq(force(name), shortSym("new")))
			todo!void("diagnostic: expected 'new' after '.'");
		return some(ModifierAst.Kind.newPrivate);
	} else {
		immutable Opt!(ModifierAst.Kind) res = () {
			switch (getPeekToken(lexer)) {
				case Token.data:
					return some(ModifierAst.Kind.data);
				case Token.extern_:
					return some(ModifierAst.Kind.extern_);
				case Token.forceData:
					return some(ModifierAst.Kind.forceData);
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
		case shortSymValue("by-val"):
			return some(ModifierAst.Kind.byVal);
		case shortSymValue("by-ref"):
			return some(ModifierAst.Kind.byRef);
		case shortSymValue("new"):
			return some(ModifierAst.Kind.newPublic);
		case shortSymValue("packed"):
			return some(ModifierAst.Kind.packed);
		default:
			return none!(ModifierAst.Kind);
	}
}

immutable(Visibility) tryTakePrivate(ref Lexer lexer) {
	return tryTakeToken(lexer, Token.dot) ? Visibility.private_ : Visibility.public_;
}
immutable(Opt!ImportsOrExportsAst) parseImportsOrExports(
	ref AllPaths allPaths,
	ref Lexer lexer,
	immutable Token keyword,
) {
	immutable Pos start = curPos(lexer);
	if (tryTakeToken(lexer, keyword)) {
		ArrBuilder!ImportAst res;
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
