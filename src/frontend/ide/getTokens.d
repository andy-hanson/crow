module frontend.ide.getTokens;

@safe @nogc pure nothrow:

import frontend.parse.ast :
	ArrowAccessAst,
	BogusAst,
	CallAst,
	ExplicitByValOrRefAndRange,
	ExprAst,
	FileAst,
	FunBodyAst,
	FunDeclAst,
	IdentifierAst,
	IfAst,
	IfOptionAst,
	ImportAst,
	ImportsOrExportsAst,
	InterpolatedAst,
	LambdaAst,
	LetAst,
	LiteralAst,
	MatchAst,
	matchExprAstKind,
	matchFunBodyAst,
	matchInterpolatedPart,
	matchLiteralAst,
	matchNameOrUnderscoreOrNone,
	matchParamsAst,
	matchSpecBodyAst,
	matchStructDeclAstBody,
	matchTypeAst,
	NameAndRange,
	NameOrUnderscoreOrNone,
	ParamAst,
	ParamsAst,
	ParenthesizedAst,
	range,
	rangeOfExplicitByValOrRef,
	rangeOfNameAndRange,
	rangeOfPuritySpecifier,
	SeqAst,
	SigAst,
	SpecBodyAst,
	SpecDeclAst,
	SpecUseAst,
	StructAliasAst,
	StructDeclAst,
	suffixRange,
	ThenAst,
	ThenVoidAst,
	TypeAst,
	TypedAst;
import model.model : Visibility;
import util.alloc.alloc : Alloc;
import util.collection.arr : ArrWithSize, at, empty, first, last, size, toArr;
import util.collection.arrBuilder : add, ArrBuilder, finishArr;
import util.collection.arrUtil : tail;
import util.collection.sortUtil : eachSorted, findUnsortedPair, UnsortedPair;
import util.comparison : compareNat32, Comparison;
import util.conv : safeToUint;
import util.opt : force, has, Opt, OptPtr, toOpt;
import util.ptr : Ptr;
import util.repr : Repr, nameAndRepr, reprArr, reprNamedRecord, reprSym;
import util.sourceRange : Pos, rangeOfStartAndLength, rangeOfStartAndName, RangeWithinFile, reprRangeWithinFile;
import util.sym : shortSymAlphaLiteral, Sym, symSize;
import util.util : todo;

struct Token {
	enum Kind {
		explicitByValOrRef,
		fieldDef,
		fieldRef,
		funDef,
		funRef,
		identifier,
		importPath,
		keyword,
		localDef,
		literalNumber,
		literalString,
		literalSymbol,
		paramDef,
		purity,
		specDef,
		specRef,
		structDef,
		structRef,
		typeParamDef,
		typeParamRef,
	}
	immutable Kind kind;
	immutable RangeWithinFile range;
}

immutable(Repr) reprTokens(ref Alloc alloc, ref immutable Token[] tokens) {
	return reprArr(alloc, tokens, (ref immutable Token it) =>
		reprToken(alloc, it));
}

immutable(Token[]) tokensOfAst(ref Alloc alloc, ref immutable FileAst ast) {
	ArrBuilder!Token tokens;

	addImportTokens(alloc, tokens, ast.imports, shortSymAlphaLiteral("import"));
	addImportTokens(alloc, tokens, ast.exports, shortSymAlphaLiteral("export"));

	//TODO: also tests...
	eachSorted!(RangeWithinFile, SpecDeclAst, StructAliasAst, StructDeclAst, FunDeclAst)(
		RangeWithinFile.max,
		(ref immutable RangeWithinFile a, ref immutable RangeWithinFile b) =>
			compareRangeWithinFile(a, b),
		ast.specs, (ref immutable SpecDeclAst it) => it.range, (ref immutable SpecDeclAst it) {
			addSpecTokens(alloc, tokens, it);
		},
		ast.structAliases, (ref immutable StructAliasAst it) => it.range, (ref immutable StructAliasAst it) {
			addStructAliasTokens(alloc, tokens, it);
		},
		ast.structs, (ref immutable StructDeclAst it) => it.range, (ref immutable StructDeclAst it) {
			addStructTokens(alloc, tokens, it);
		},
		ast.funs, (ref immutable FunDeclAst it) => it.range, (ref immutable FunDeclAst it) {
			addFunTokens(alloc, tokens, it);
		});
	immutable Token[] res = finishArr(alloc, tokens);
	assertTokensSorted(res);
	return res;
}

private:

immutable(RangeWithinFile) rangeAtName(immutable Visibility visibility, immutable Pos start, immutable Sym name) {
	immutable uint offset = () {
		final switch (visibility) {
			case Visibility.public_:
				return 0;
			case Visibility.private_:
				return 1;
		}
	}();
	immutable Pos afterDot = start + offset;
	return immutable RangeWithinFile(afterDot, afterDot + symSize(name));
}

immutable(RangeWithinFile) rangeAtName(immutable Pos start, immutable Sym name) {
	return rangeAtName(Visibility.public_, start, name);
}

void addImportTokens(
	ref Alloc alloc,
	ref ArrBuilder!Token tokens,
	ref immutable Opt!ImportsOrExportsAst a,
	immutable Sym keyword,
) {
	if (has(a)) {
		add(alloc, tokens, immutable Token(Token.Kind.keyword, rangeAtName(force(a).range.start, keyword)));
		foreach (ref immutable ImportAst path; force(a).paths)
			add(alloc, tokens, immutable Token(
				Token.Kind.importPath,
				path.range));
	}
}

void addSpecTokens(ref Alloc alloc, ref ArrBuilder!Token tokens, ref immutable SpecDeclAst a) {
	add(alloc, tokens, immutable Token(Token.Kind.specDef, rangeAtName(a.visibility, a.range.start, a.name)));
	addTypeParamsTokens(alloc, tokens, a.typeParams);
	matchSpecBodyAst!(
		void,
		(ref immutable SpecBodyAst.Builtin) {},
		(ref immutable SigAst[] sigs) {
			foreach (ref immutable SigAst sig; sigs) {
				add(alloc, tokens, immutable Token(Token.Kind.funDef, rangeAtName(sig.range.start, sig.name)));
				addSigReturnTypeAndParamsTokens(alloc, tokens, sig);
			}
		},
	)(a.body_);
}

void addSigReturnTypeAndParamsTokens(ref Alloc alloc, ref ArrBuilder!Token tokens, ref immutable SigAst a) {
	addTypeTokens(alloc, tokens, a.returnType);
	matchParamsAst!(
		void,
		(immutable ParamAst[] params) {
			foreach (ref immutable ParamAst param; params)
				addParamTokens(alloc, tokens, param);
		},
		(ref immutable ParamsAst.Varargs v) {
			addParamTokens(alloc, tokens, v.param);
		},
	)(a.params);
}

void addTypeTokens(ref Alloc alloc, ref ArrBuilder!Token tokens, immutable TypeAst a) {
	matchTypeAst!(
		void,
		(immutable TypeAst.Dict it) {
			addTypeTokens(alloc, tokens, it.v);
			add(alloc, tokens, immutable Token(
				Token.Kind.keyword,
				immutable RangeWithinFile(range(it.v).end, range(it.k).start)));
			addTypeTokens(alloc, tokens, it.k);
			add(alloc, tokens, immutable Token(
				Token.Kind.keyword,
				rangeOfStartAndLength(range(it.k).end, "]".length)));
		},
		(immutable TypeAst.Fun it) {
			add(alloc, tokens, immutable Token(
				Token.Kind.keyword,
				rangeOfStartAndName(it.range.start, shortSymAlphaLiteral("fun"))));
			foreach (immutable TypeAst t; it.returnAndParamTypes)
				addTypeTokens(alloc, tokens, t);
		},
		(immutable TypeAst.InstStruct it) {
			addInstStructTokens(alloc, tokens, it);
		},
		(immutable TypeAst.Suffix it) {
			addTypeTokens(alloc, tokens, it.left);
			add(alloc, tokens, immutable Token(Token.Kind.keyword, suffixRange(it)));
		},
	)(a);
}

void addInstStructTokens(ref Alloc alloc, ref ArrBuilder!Token tokens, immutable TypeAst.InstStruct a) {
	add(alloc, tokens, immutable Token(Token.Kind.structRef, rangeOfNameAndRange(a.name)));
	addTypeArgsTokens(alloc, tokens, a.typeArgs);
}

void addTypeArgsTokens(
	ref Alloc alloc,
	ref ArrBuilder!Token tokens,
	ref immutable ArrWithSize!TypeAst typeArgs,
) {
	foreach (immutable TypeAst typeArg; toArr(typeArgs))
		addTypeTokens(alloc, tokens, typeArg);
}

void addParamTokens(ref Alloc alloc, ref ArrBuilder!Token tokens, ref immutable ParamAst a) {
	if (has(a.name))
		add(alloc, tokens, immutable Token(Token.Kind.paramDef, rangeOfStartAndName(a.range.start, force(a.name))));
	addTypeTokens(alloc, tokens, a.type);
}

void addTypeParamsTokens(
	ref Alloc alloc,
	ref ArrBuilder!Token tokens,
	ref immutable ArrWithSize!NameAndRange a,
) {
	foreach (ref immutable NameAndRange typeParam; toArr(a))
		add(alloc, tokens, immutable Token(Token.Kind.typeParamDef, rangeOfNameAndRange(typeParam)));
}

void addStructAliasTokens(ref Alloc alloc, ref ArrBuilder!Token tokens, ref immutable StructAliasAst a) {
	add(alloc, tokens, immutable Token(Token.Kind.structDef, rangeAtName(a.visibility, a.range.start, a.name)));
	addTypeParamsTokens(alloc, tokens, a.typeParams);
	addTypeTokens(alloc, tokens, a.target);
}

void addStructTokens(ref Alloc alloc, ref ArrBuilder!Token tokens, ref immutable StructDeclAst a) {
	add(alloc, tokens, immutable Token(Token.Kind.structDef, rangeAtName(a.visibility, a.range.start, a.name)));
	addTypeParamsTokens(alloc, tokens, a.typeParams);
	if (has(a.purity))
		add(alloc, tokens, immutable Token(Token.Kind.purity, rangeOfPuritySpecifier(force(a.purity))));
	matchStructDeclAstBody!(
		void,
		(ref immutable StructDeclAst.Body.Builtin) {},
		(ref immutable StructDeclAst.Body.Enum it) {
			addEnumOrFlagsTokens(alloc, tokens, it.typeArg, it.members);
		},
		(ref immutable StructDeclAst.Body.Flags it) {
			addEnumOrFlagsTokens(alloc, tokens, it.typeArg, it.members);
		},
		(ref immutable StructDeclAst.Body.ExternPtr) {},
		(ref immutable StructDeclAst.Body.Record record) {
			//TODO: add token for 'packed' modifier
			immutable Opt!ExplicitByValOrRefAndRange explicitByValOrRef = record.explicitByValOrRef;
			if (has(explicitByValOrRef)) {
				add(alloc, tokens, immutable Token(
					Token.Kind.explicitByValOrRef, rangeOfExplicitByValOrRef(force(explicitByValOrRef))));
			}
			foreach (ref immutable StructDeclAst.Body.Record.Field field; toArr(record.fields)) {
				add(alloc, tokens, immutable Token(
					Token.Kind.fieldDef,
					rangeAtName(field.range.start, field.name)));
				addTypeTokens(alloc, tokens, field.type);
			}
		},
		(ref immutable StructDeclAst.Body.Union union_) {
			foreach (ref immutable StructDeclAst.Body.Union.Member member; union_.members) {
				add(alloc, tokens, immutable Token(
					Token.Kind.fieldDef, // TODO: Token.Kind.unionMember?
					rangeAtName(member.range.start, member.name)));
				if (has(member.type))
					addTypeTokens(alloc, tokens, force(member.type));
			}
		},
	)(a.body_);
}

void addEnumOrFlagsTokens(
	ref Alloc alloc,
	ref ArrBuilder!Token tokens,
	scope immutable OptPtr!TypeAst ptrTypeArg,
	scope immutable ArrWithSize!(StructDeclAst.Body.Enum.Member) members,
) {
	immutable Opt!(Ptr!TypeAst) typeArg = toOpt(ptrTypeArg);
	if (has(typeArg)) addTypeTokens(alloc, tokens, force(typeArg).deref());
	foreach (ref immutable StructDeclAst.Body.Enum.Member member; toArr(members)) {
		add(alloc, tokens, immutable Token(
			Token.Kind.fieldDef, // TODO: enumMemberREf
			member.range));
		if (has(member.value)) {
			immutable uint addLen = " = ".length;
			immutable Pos pos = member.range.start + symSize(member.name) + addLen;
			add(alloc, tokens, immutable Token(
				Token.Kind.literalNumber,
				immutable RangeWithinFile(pos, member.range.end)));
		}
	}
}

void addFunTokens(ref Alloc alloc, ref ArrBuilder!Token tokens, ref immutable FunDeclAst a) {
	add(alloc, tokens, immutable Token(Token.Kind.funDef, rangeAtName(a.visibility, a.range.start, a.sig.name)));
	addTypeParamsTokens(alloc, tokens, a.typeParams);
	addSigReturnTypeAndParamsTokens(alloc, tokens, a.sig);
	foreach (ref immutable SpecUseAst specUse; a.specUses) {
		add(alloc, tokens, immutable Token(Token.Kind.specRef, rangeOfNameAndRange(specUse.spec)));
		addTypeArgsTokens(alloc, tokens, specUse.typeArgs);
	}
	matchFunBodyAst!(
		void,
		(ref immutable FunBodyAst.Builtin) {},
		(ref immutable FunBodyAst.Extern) {},
		(ref immutable ExprAst it) {
			addExprTokens(alloc, tokens, it);
		},
	)(a.body_);
}

void addExprTokens(ref Alloc alloc, ref ArrBuilder!Token tokens, ref immutable ExprAst a) {
	matchExprAstKind!(
		void,
		(ref immutable ArrowAccessAst it) {
			addExprTokens(alloc, tokens, it.left);
			add(alloc, tokens, immutable Token(Token.Kind.funRef, rangeOfNameAndRange(it.name)));
			addTypeArgsTokens(alloc, tokens, it.typeArgs);
		},
		(ref immutable BogusAst) {},
		(ref immutable CallAst it) {
			immutable ExprAst[] args = toArr(it.args);
			void addName() {
				add(alloc, tokens, immutable Token(Token.Kind.funRef, rangeOfNameAndRange(it.funName)));
				addTypeArgsTokens(alloc, tokens, it.typeArgs);
			}
			final switch (it.style) {
				case CallAst.Style.dot:
				case CallAst.Style.setDot:
				case CallAst.Style.infix:
					addExprTokens(alloc, tokens, first(args));
					addName();
					addExprsTokens(alloc, tokens, tail(args));
					break;
				case CallAst.style.emptyParens:
					break;
				case CallAst.style.prefixOperator:
				case CallAst.Style.prefix:
				case CallAst.Style.setSingle:
				case CallAst.Style.single:
					addName();
					addExprsTokens(alloc, tokens, args);
					break;
				case CallAst.Style.comma:
				case CallAst.Style.setDeref:
				case CallAst.Style.setSubscript:
				case CallAst.Style.subscript:
					addExprsTokens(alloc, tokens, args);
					break;
			}
		},
		(ref immutable FunPtrAst) {
			add(alloc, tokens, immutable Token(Token.Kind.identifier, a.range));
		},
		(ref immutable IdentifierAst) {
			add(alloc, tokens, immutable Token(Token.Kind.identifier, a.range));
		},
		(ref immutable IfAst it) {
			addExprTokens(alloc, tokens, it.cond);
			addExprTokens(alloc, tokens, it.then);
			if (has(it.else_))
				addExprTokens(alloc, tokens, force(it.else_));
		},
		(ref immutable IfOptionAst it) {
			add(alloc, tokens, localDefOfNameAndRange(it.name));
			addExprTokens(alloc, tokens, it.option);
			addExprTokens(alloc, tokens, it.then);
			if (has(it.else_))
				addExprTokens(alloc, tokens, force(it.else_));
		},
		(ref immutable InterpolatedAst it) {
			Pos pos = a.range.start;
			if (!empty(it.parts)) {
				// Ensure opening quote is highlighted
				matchInterpolatedPart!(
					void,
					(ref immutable(string)) {},
					(ref immutable(ExprAst)) {
						add(alloc, tokens, immutable Token(
							Token.Kind.literalString,
							immutable RangeWithinFile(pos, pos + 1)));
					},
				)(it.parts[0]);
				foreach (immutable size_t i; 0..size(it.parts))
					matchInterpolatedPart!(
						void,
						(ref immutable string s) {
							// TODO: length may be wrong if there are escapes
							// Ensure the closing quote is highlighted
							immutable Pos end = safeToUint(pos + s.length) + (i == size(it.parts) - 1 ? 1 : 0);
							add(alloc, tokens, immutable Token(
								Token.Kind.literalString,
								immutable RangeWithinFile(pos, end)));
						},
						(ref immutable ExprAst e) {
							addExprTokens(alloc, tokens, e);
							pos = safeToUint(e.range.end + 1);
						},
					)(at(it.parts, i));
				// Ensure closing quote is highlighted
				matchInterpolatedPart!(
					void,
					(ref immutable(string)) {},
					(ref immutable(ExprAst)) {
						add(alloc, tokens, immutable Token(
							Token.Kind.literalString,
							immutable RangeWithinFile(a.range.end - 1, a.range.end)));
					},
				)(last(it.parts));
			}
		},
		(ref immutable LambdaAst it) {
			foreach (ref immutable LambdaAst.Param param; it.params)
				addLambdaAstParam(alloc, tokens, param);
			addExprTokens(alloc, tokens, it.body_);
		},
		(ref immutable LetAst it) {
			add(alloc, tokens, localDefOfNameAndRange(immutable NameAndRange(a.range.start, it.name)));
			addExprTokens(alloc, tokens, it.initializer);
			addExprTokens(alloc, tokens, it.then);
		},
		(ref immutable LiteralAst literal) {
			immutable Token.Kind kind = matchLiteralAst!(
				immutable Token.Kind,
				(immutable LiteralAst.Float) =>
					Token.Kind.literalNumber,
				(immutable LiteralAst.Int) =>
					Token.Kind.literalNumber,
				(immutable LiteralAst.Nat) =>
					Token.Kind.literalNumber,
				(immutable(string)) =>
					Token.Kind.literalString,
				(immutable(Sym)) =>
					Token.Kind.literalSymbol,
			)(literal);
			add(alloc, tokens, immutable Token(kind, a.range));
		},
		(ref immutable MatchAst it) {
			addExprTokens(alloc, tokens, it.matched);
			foreach (ref immutable MatchAst.CaseAst case_; it.cases) {
				add(alloc, tokens, immutable Token(Token.Kind.structRef, case_.memberNameRange()));
				matchNameOrUnderscoreOrNone!(
					void,
					(immutable(Sym)) {
						add(alloc, tokens, immutable Token(Token.Kind.localDef, case_.localRange()));
					},
					(ref immutable NameOrUnderscoreOrNone.Underscore) {},
					(ref immutable NameOrUnderscoreOrNone.None) {},
				)(case_.local);
				addExprTokens(alloc, tokens, case_.then);
			}
		},
		(ref immutable ParenthesizedAst it) {
			addExprTokens(alloc, tokens, it.inner);
		},
		(ref immutable SeqAst it) {
			addExprTokens(alloc, tokens, it.first);
			addExprTokens(alloc, tokens, it.then);
		},
		(ref immutable ThenAst it) {
			addLambdaAstParam(alloc, tokens, it.left);
			addExprTokens(alloc, tokens, it.futExpr);
			addExprTokens(alloc, tokens, it.then);
		},
		(ref immutable ThenVoidAst it) {
			addExprTokens(alloc, tokens, it.futExpr);
			addExprTokens(alloc, tokens, it.then);
		},
		(ref immutable TypedAst it) {
			addExprTokens(alloc, tokens, it.expr);
			addTypeTokens(alloc, tokens, it.type);
		},
	)(a.kind);
}

immutable(Token) localDefOfNameAndRange(immutable NameAndRange a) {
	return immutable Token(Token.Kind.localDef, rangeOfNameAndRange(a));
}

void addLambdaAstParam(ref Alloc alloc, ref ArrBuilder!Token tokens, ref immutable LambdaAst.Param param) {
	add(alloc, tokens, immutable Token(Token.Kind.paramDef, rangeOfNameAndRange(param)));
}

void addExprsTokens(ref Alloc alloc, ref ArrBuilder!Token tokens, immutable ExprAst[] exprs) {
	foreach (ref immutable ExprAst expr; exprs)
		addExprTokens(alloc, tokens, expr);
}

void assertTokensSorted(ref immutable Token[] tokens) {
	immutable Opt!UnsortedPair pair = findUnsortedPair!Token(tokens, (ref immutable Token a, ref immutable Token b) =>
		compareRangeWithinFile(a.range, b.range));
	if (has(pair))
		// To debug, just disable this assertion and look for the unsorted token in the output
		todo!void("tokens not sorted!");
}

immutable(Comparison) compareRangeWithinFile(ref immutable RangeWithinFile a, ref immutable RangeWithinFile b) {
	return compareNat32(a.start, b.start);
}

immutable(Sym) symOfTokenKind(immutable Token.Kind kind) {
	final switch (kind) {
		case Token.Kind.explicitByValOrRef:
			return shortSymAlphaLiteral("by-val-ref");
		case Token.Kind.fieldDef:
			return shortSymAlphaLiteral("field-def");
		case Token.Kind.fieldRef:
			return shortSymAlphaLiteral("field-ref");
		case Token.Kind.funDef:
			return shortSymAlphaLiteral("fun-def");
		case Token.Kind.funRef:
			return shortSymAlphaLiteral("fun-ref");
		case Token.Kind.identifier:
			return shortSymAlphaLiteral("identifier");
		case Token.Kind.importPath:
			return shortSymAlphaLiteral("import");
		case Token.Kind.keyword:
			return shortSymAlphaLiteral("keyword");
		case Token.Kind.literalNumber:
			return shortSymAlphaLiteral("lit-num");
		case Token.Kind.literalString:
			return shortSymAlphaLiteral("lit-str");
		case Token.Kind.literalSymbol:
			return shortSymAlphaLiteral("lit-sym");
		case Token.Kind.localDef:
			return shortSymAlphaLiteral("local-def");
		case Token.Kind.paramDef:
			return shortSymAlphaLiteral("param-def");
		case Token.Kind.purity:
			return shortSymAlphaLiteral("purity");
		case Token.Kind.specDef:
			return shortSymAlphaLiteral("spec-def");
		case Token.Kind.specRef:
			return shortSymAlphaLiteral("spec-ref");
		case Token.Kind.structDef:
			return shortSymAlphaLiteral("struct-def");
		case Token.Kind.structRef:
			return shortSymAlphaLiteral("struct-ref");
		case Token.Kind.typeParamDef:
			return shortSymAlphaLiteral("tparam-def");
		case Token.Kind.typeParamRef:
			return shortSymAlphaLiteral("tparam-ref");
	}
}

immutable(Repr) reprToken(ref Alloc alloc, ref immutable Token token) {
	return reprNamedRecord(alloc, "token", [
		nameAndRepr("kind", reprSym(symOfTokenKind(token.kind))),
		nameAndRepr("range", reprRangeWithinFile(alloc, token.range))]);
}
