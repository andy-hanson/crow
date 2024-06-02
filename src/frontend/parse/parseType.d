module frontend.parse.parseType;

@safe @nogc pure nothrow:

import frontend.parse.lexer :
	addDiag,
	addDiagUnexpectedCurToken,
	curPos,
	getCurIndent,
	getPeekToken,
	getPeekTokenAndData,
	Lexer,
	lookaheadNewVisibility,
	lookaheadOpenBracket,
	lookaheadOpenParen,
	mustTakeToken,
	range,
	rangeAtChar,
	rangeForCurToken,
	skipNewlinesIgnoreIndentation,
	skipUntilNewlineNoDiag,
	takeNextToken,
	Token;
import frontend.parse.lexToken : TokenAndData;
import frontend.parse.parseUtil :
	addDiagExpected,
	peekEndOfLine,
	peekToken,
	takeName,
	takeNameAndRangeAllowUnderscore,
	takeOrAddDiagExpectedToken,
	tryTakeNameAndRange,
	tryTakeNameAndRangeAllowNameLikeKeywords,
	tryTakeOperator,
	tryTakeToken,
	tryTakeTokenAndMayContinueOntoNextLine,
	tryTakeTokenCb;
import model.ast : DestructureAst, ModifierAst, ModifierKeyword, NameAndRange, ParamsAst, SpecUseAst, TypeAst;
import model.model : FunKind, Visibility;
import model.parseDiag : ParseDiag;
import util.col.array : emptySmallArray, only, SmallArray;
import util.col.arrayBuilder : Builder, buildSmallArray;
import util.memory : allocate;
import util.opt : force, has, none, Opt, optIf, optOr, some;
import util.sourceRange : Pos;
import util.symbol : Symbol, symbol;
import util.util : optEnumConvert;

Opt!Visibility tryTakeVisibility(ref Lexer lexer) =>
	tryTakeOperator(lexer, symbol!"-")
		? some(Visibility.private_)
		: tryTakeOperator(lexer, symbol!"+")
		? some(Visibility.public_)
		: tryTakeOperator(lexer, symbol!"~")
		? some(Visibility.internal)
		: none!Visibility;

TypeAst parseTypeArgForVarDecl(ref Lexer lexer) {
	if (takeOrAddDiagExpectedToken(lexer, Token.parenLeft, ParseDiag.Expected.Kind.openParen)) {
		TypeAst res = parseType(lexer);
		takeOrAddDiagExpectedToken(lexer, Token.parenRight, ParseDiag.Expected.Kind.closingParen);
		return res;
	} else
		return TypeAst(TypeAst.Bogus(rangeAtChar(lexer)));
}

Opt!(TypeAst*) tryParseTypeArgForExpr(ref Lexer lexer) =>
	tryTakeToken(lexer, Token.at)
		? some(allocate(lexer.alloc, parseTypeForTypedExpr(lexer)))
		: none!(TypeAst*);

private SmallArray!TypeAst parseTypesWithCommasThenClosingParen(ref Lexer lexer) =>
	buildSmallArray(lexer.alloc, (scope ref Builder!TypeAst out_) {
		parseTypesWithCommasThenClosingParen(lexer, out_);
	});

private void parseTypesWithCommasThenClosingParen(ref Lexer lexer, scope ref Builder!TypeAst res) {
	if (!tryTakeToken(lexer, Token.parenRight)) {
		do {
			res ~= parseType(lexer);
		} while (tryTakeToken(lexer, Token.comma));
		takeOrAddDiagExpectedToken(lexer, Token.parenRight, ParseDiag.Expected.Kind.closingParen);
	}
}

TypeAst parseType(ref Lexer lexer) =>
	parseTypeSuffixes(lexer, parseTypeBeforeSuffixes(lexer, ParenthesesNecessary.unnecessary));

SmallArray!ModifierAst parseModifiers(ref Lexer lexer) =>
	peekEndOfLine(lexer)
		? emptySmallArray!ModifierAst
		: buildSmallArray!ModifierAst(lexer.alloc, (scope ref Builder!ModifierAst res) {
			do {
				res ~= parseModifier(lexer);
			} while (tryTakeTokenAndMayContinueOntoNextLine(lexer, Token.comma));
		});

private ModifierAst parseModifier(ref Lexer lexer) {
	Pos start = curPos(lexer);
	Opt!ModifierKeyword keyword = tryTakeModifierKeyword(lexer);
	if (has(keyword))
		return ModifierAst(ModifierAst.Keyword(none!TypeAst, start, force(keyword)));
	else {
		TypeAst left = parseTypeBeforeSuffixes(lexer, ParenthesesNecessary.unnecessary);
		return parseSpecUseSuffixes(lexer, left);
	}
}

private Opt!ModifierKeyword tryTakeModifierKeyword(ref Lexer lexer) {
	Opt!ModifierKeyword res = tryTakeTokenCb!ModifierKeyword(lexer, (TokenAndData x) => tryGetModifierKeyword(x.token));
	if (has(res))
		return res;
	else if (lookaheadNewVisibility(lexer)) {
		Opt!Visibility opt = tryTakeVisibility(lexer);
		Visibility visibility = force(opt);
		Symbol name = takeName(lexer);
		assert(name == symbol!"new");
		return some(newVisibility(visibility));
	} else
		return none!ModifierKeyword;
}

// Ensures that 't data' or 't shared' parses as a spec and not a modifier
private Opt!ModifierKeyword tryTakeModifierKeywordNonSpec(ref Lexer lexer) =>
	getPeekToken(lexer) == Token.shared_ || getPeekToken(lexer) == Token.data
		? none!ModifierKeyword
		: tryTakeModifierKeyword(lexer);

private ModifierKeyword newVisibility(Visibility a) {
	final switch (a) {
		case Visibility.private_:
			return ModifierKeyword.newPrivate;
		case Visibility.internal:
			return ModifierKeyword.newInternal;
		case Visibility.public_:
			return ModifierKeyword.newPublic;
	}
}

private Opt!ModifierKeyword tryGetModifierKeyword(Token a) {
	bool ok = true;
	ModifierKeyword res = optEnumConvert!(ModifierKeyword, Token)(a, () {
		ok = false;
		return ModifierKeyword.bare;
	});
	return optIf(ok, () => res);
}

TypeAst parseTypeForTypedExpr(ref Lexer lexer) =>
	parseTypeSuffixesNonName(lexer, parseTypeBeforeSuffixes(lexer, ParenthesesNecessary.necessary));

DestructureAst parseDestructureRequireParens(ref Lexer lexer) {
	Pos start = curPos(lexer);
	if (tryTakeToken(lexer, Token.parenLeft)) {
		if (tryTakeToken(lexer, Token.parenRight))
			return DestructureAst(DestructureAst.Void(range(lexer, start)));
		else {
			DestructureAst res = parseDestructureNoRequireParens(lexer);
			takeOrAddDiagExpectedToken(lexer, Token.parenRight, ParseDiag.Expected.Kind.closingParen);
			return res;
		}
	} else {
		NameAndRange name = takeNameAndRangeAllowUnderscore(lexer);
		Pos posForMut = curPos(lexer);
		Opt!Pos mut = tryTakeToken(lexer, Token.mut) ? some(posForMut) : none!Pos;
		Opt!(TypeAst*) type = () {
			switch (getPeekToken(lexer)) {
				case Token.colon:
				case Token.comma:
				case Token.equal:
				case Token.newlineDedent:
				case Token.newlineIndent:
				case Token.newlineSameIndent:
				case Token.parenRight:
				case Token.questionEqual:
					return none!(TypeAst*);
				default:
					return some(allocate(lexer.alloc, parseType(lexer)));
			}
		}();
		return DestructureAst(DestructureAst.Single(name, mut, type));
	}
}

DestructureAst parseDestructureNoRequireParens(ref Lexer lexer) {
	DestructureAst first = parseDestructureRequireParens(lexer);
	if (tryTakeToken(lexer, Token.comma)) {
		return DestructureAst(buildSmallArray!DestructureAst(lexer.alloc, (ref Builder!DestructureAst parts) {
			parts ~= first;
			do {
				parts ~= parseDestructureRequireParens(lexer);
			} while (tryTakeToken(lexer, Token.comma));
		}));
	} else
		return first;
}

Opt!ParamsAst tryParseParams(ref Lexer lexer) =>
	peekToken(lexer, Token.parenLeft)
		? some(parseParams(lexer))
		: none!ParamsAst;

ParamsAst parseParams(ref Lexer lexer) {
	uint indentLevel = getCurIndent(lexer);
	if (!takeOrAddDiagExpectedToken(lexer, Token.parenLeft, ParseDiag.Expected.Kind.openParen)) {
		skipUntilNewlineNoDiag(lexer);
		return ParamsAst([]);
	} else if (tryTakeToken(lexer, Token.parenRight))
		return ParamsAst(emptySmallArray!DestructureAst);
	else if (tryTakeToken(lexer, Token.dot3)) {
		DestructureAst param = parseDestructureRequireParens(lexer);
		takeOrAddDiagExpectedToken(lexer, Token.parenRight, ParseDiag.Expected.Kind.closingParen);
		return ParamsAst(allocate(lexer.alloc, ParamsAst.Varargs(param)));
	} else
		return ParamsAst(buildSmallArray!DestructureAst(lexer.alloc, (scope ref Builder!DestructureAst res) {
			while (true) {
				skipNewlinesIgnoreIndentation(lexer, indentLevel);
				res ~= parseDestructureRequireParens(lexer);
				skipNewlinesIgnoreIndentation(lexer, indentLevel);
				if (tryTakeToken(lexer, Token.parenRight))
					break;
				if (!takeOrAddDiagExpectedToken(lexer, Token.comma, ParseDiag.Expected.Kind.comma)) {
					skipUntilNewlineNoDiag(lexer);
					break;
				}
				skipNewlinesIgnoreIndentation(lexer, indentLevel);
				if (tryTakeToken(lexer, Token.parenRight))
					break;
			}
		}));
}

private:

enum ParenthesesNecessary { unnecessary, necessary }

TypeAst parseTypeBeforeSuffixes(ref Lexer lexer, ParenthesesNecessary parens) {
	Pos start = curPos(lexer);
	switch (getPeekToken(lexer)) {
		case Token.name:
			return TypeAst(NameAndRange(start, takeNextToken(lexer).asSymbol));
		case Token.parenLeft:
			mustTakeToken(lexer, Token.parenLeft);
			return parseTupleType(lexer, start, parens);
		default:
			addDiagUnexpectedCurToken(lexer, start, getPeekTokenAndData(lexer));
			return TypeAst(TypeAst.Bogus(rangeForCurToken(lexer, start)));
	}
}

TypeAst parseTupleType(ref Lexer lexer, Pos start, ParenthesesNecessary parens) {
	SmallArray!TypeAst args = parseTypesWithCommasThenClosingParen(lexer);
	switch (args.length) {
		case 0:
			addDiag(lexer, range(lexer, start), ParseDiag(ParseDiag.TypeEmptyParens()));
			return TypeAst(TypeAst.Bogus());
		case 1:
			if (parens != ParenthesesNecessary.necessary)
				addDiag(lexer, range(lexer, start), ParseDiag(ParseDiag.TypeUnnecessaryParens()));
			return only(args);
		default:
			return TypeAst(allocate(lexer.alloc, TypeAst.Tuple(range(lexer, start), args)));
	}
}

TypeAst parseTypeSuffixes(ref Lexer lexer, TypeAst left) {
	Opt!TypeAst suffix = parseTypeSuffixNonName(lexer, () => left);
	if (has(suffix))
		return parseTypeSuffixes(lexer, force(suffix));
	else {
		Opt!NameAndRange name = tryTakeNameAndRange(lexer);
		return has(name)
			? parseTypeSuffixes(lexer, TypeAst(allocate(lexer.alloc, TypeAst.SuffixName(left, force(name)))))
			: left;
	}
}

ModifierAst parseSpecUseSuffixes(ref Lexer lexer, TypeAst left) { // TODO: RENAME, not just spec uses ---------------------
	Pos keywordPos = curPos(lexer);
	Opt!ModifierKeyword keyword = tryTakeModifierKeywordNonSpec(lexer);
	if (has(keyword))
		return ModifierAst(ModifierAst.Keyword(some(left), keywordPos, force(keyword)));
	else {
		Opt!TypeAst suffix = parseTypeSuffixNonName(lexer, () => left);
		if (has(suffix))
			return parseSpecUseSuffixes(lexer, force(suffix));
		else {
			Opt!NameAndRange name = tryTakeNameAndRangeAllowNameLikeKeywords(lexer);
			if (has(name))
				return parseSpecUseSuffixesAfterName(lexer, left, force(name));
			else if (left.isA!NameAndRange)
				return ModifierAst(SpecUseAst(none!TypeAst, left.as!NameAndRange));
			else {
				addDiagExpected(lexer, ParseDiag.Expected.Kind.name);
				return ModifierAst(SpecUseAst(some(left), NameAndRange(curPos(lexer), symbol!"")));
			}
		}
	}
}

ModifierAst parseSpecUseSuffixesAfterName(ref Lexer lexer, TypeAst left, NameAndRange name) {
	TypeAst nameIsType() =>
		TypeAst(allocate(lexer.alloc, TypeAst.SuffixName(left, name)));

	Pos keywordPos = curPos(lexer);
	Opt!ModifierKeyword keyword = tryTakeModifierKeywordNonSpec(lexer); // TODO: this is similar to 'parseSpecUseSuffixes'....
	if (has(keyword)) {
		return ModifierAst(ModifierAst.Keyword(some(nameIsType()), keywordPos, force(keyword)));
	} else {
		Opt!TypeAst suffix = parseTypeSuffixNonName(lexer, () => nameIsType());
		if (has(suffix))
			return parseSpecUseSuffixes(lexer, force(suffix));
		else {
			Opt!NameAndRange name2 = tryTakeNameAndRange(lexer);
			return has(name2)
				? parseSpecUseSuffixesAfterName(lexer, nameIsType(), force(name2))
				: ModifierAst(SpecUseAst(some(left), name));
		}
	}
}

TypeAst parseTypeSuffixesNonName(ref Lexer lexer, TypeAst left) {
	Opt!TypeAst suffix = parseTypeSuffixNonName(lexer, () => left);
	return has(suffix) ? parseTypeSuffixesNonName(lexer, force(suffix)) : left;
}

Opt!TypeAst parseTypeSuffixNonName(ref Lexer lexer, in TypeAst delegate() @safe @nogc pure nothrow cbLeft) {
	Pos suffixPos = curPos(lexer);
	Opt!TypeAst suffix(TypeAst.SuffixSpecial.Kind kind, TypeAst left = cbLeft()) =>
		some(TypeAst(allocate(lexer.alloc, TypeAst.SuffixSpecial(left, suffixPos, kind))));
	Opt!TypeAst doubleSuffix(TypeAst.SuffixSpecial.Kind kind1, TypeAst.SuffixSpecial.Kind kind2) =>
		some(TypeAst(allocate(lexer.alloc, TypeAst.SuffixSpecial(
			TypeAst(allocate(lexer.alloc, TypeAst.SuffixSpecial(cbLeft(), suffixPos, kind2))),
			suffixPos + 1,
			kind1))));
	Opt!TypeAst mapLike(TypeAst.Map.Kind kind, Pos bracketPos = suffixPos, TypeAst left = cbLeft()) {
		TypeAst key = parseType(lexer);
		takeOrAddDiagExpectedToken(lexer, Token.bracketRight, ParseDiag.Expected.Kind.closingBracket);
		return some(TypeAst(allocate(lexer.alloc, TypeAst.Map(kind, [key, left]))));
	}

	switch (getPeekToken(lexer)) {
		case Token.question:
			mustTakeToken(lexer, Token.question);
			return suffix(TypeAst.SuffixSpecial.Kind.option);
		case Token.bracketLeft:
			mustTakeToken(lexer, Token.bracketLeft);
			return tryTakeToken(lexer, Token.bracketRight)
				? suffix(TypeAst.SuffixSpecial.Kind.list)
				: mapLike(TypeAst.Map.Kind.data);
		case Token.questionBracket:
			mustTakeToken(lexer, Token.questionBracket);
			TypeAst left = force(suffix(TypeAst.SuffixSpecial.Kind.option));
			return tryTakeToken(lexer, Token.bracketRight)
				? some(TypeAst(allocate(lexer.alloc, TypeAst.SuffixSpecial(
					left, suffixPos + 1, TypeAst.SuffixSpecial.Kind.list))))
				: mapLike(TypeAst.Map.Kind.data, suffixPos + 1, left);
		case Token.operator:
			return tryTakeOperator(lexer, symbol!"*")
				? suffix(TypeAst.SuffixSpecial.Kind.ptr)
				: tryTakeOperator(lexer, symbol!"**")
				? doubleSuffix(TypeAst.SuffixSpecial.Kind.ptr, TypeAst.SuffixSpecial.Kind.ptr)
				: none!TypeAst;
		case Token.mut:
			return optOr!TypeAst(tryParseFunType(lexer, suffixPos, Token.mut, FunKind.mut, cbLeft), () {
				Pos mutPos = curPos(lexer);
				mustTakeToken(lexer, Token.mut);
				return tryTakeToken(lexer, Token.bracketLeft)
					? tryTakeToken(lexer, Token.bracketRight)
						? suffix(TypeAst.SuffixSpecial.Kind.mutList)
						: mapLike(TypeAst.Map.Kind.mut)
					: tryTakeOperator(lexer, symbol!"*")
					? suffix(TypeAst.SuffixSpecial.Kind.mutPtr)
					: tryTakeOperator(lexer, symbol!"**")
					? doubleSuffix(TypeAst.SuffixSpecial.Kind.mutPtr, TypeAst.SuffixSpecial.Kind.ptr)
					: () {
						addDiag(lexer, range(lexer, mutPos), ParseDiag(ParseDiag.TypeTrailingMut()));
						return none!TypeAst;
					}();
			});
		case Token.function_:
			return tryParseFunType(lexer, suffixPos, Token.function_, FunKind.function_, cbLeft);
		case Token.data:
			return tryParseFunType(lexer, suffixPos, Token.data, FunKind.data, cbLeft);
		case Token.shared_:
			return optOr!TypeAst(tryParseFunType(lexer, suffixPos, Token.shared_, FunKind.shared_, cbLeft), () {
				if (lookaheadOpenBracket(lexer)) {
					mustTakeToken(lexer, Token.shared_);
					mustTakeToken(lexer, Token.bracketLeft);
					return tryTakeToken(lexer, Token.bracketRight)
						? suffix(TypeAst.SuffixSpecial.Kind.sharedList)
						: mapLike(TypeAst.Map.Kind.shared_);
				} else
					return none!TypeAst;
			});
		default:
			return none!TypeAst;
	}
}

Opt!TypeAst tryParseFunType(
	ref Lexer lexer,
	Pos keywordPos,
	Token keyword,
	FunKind kind,
	in TypeAst delegate() @safe @nogc pure nothrow returnType,
) =>
	optIf(lookaheadOpenParen(lexer), () {
		bool tookToken = tryTakeToken(lexer, keyword);
		assert(tookToken);
		Pos beforeParams = curPos(lexer);
		ParamsAst params = parseParams(lexer);
		return TypeAst(allocate(lexer.alloc,
			TypeAst.Fun(returnType(), keywordPos, kind, range(lexer, beforeParams), params)));
	});
