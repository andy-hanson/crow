module frontend.ide.getTokens;

@safe @nogc pure nothrow:

import frontend.parse.ast :
	BogusAst,
	CallAst,
	CreateArrAst,
	exports,
	ExprAst,
	FileAst,
	FunBodyAst,
	FunDeclAst,
	funs,
	IdentifierAst,
	IfAst,
	ImportAst,
	imports,
	ImportsOrExportsAst,
	LambdaAst,
	LetAst,
	LiteralAst,
	MatchAst,
	matchExprAstKind,
	matchFunBodyAst,
	matchLiteralAst,
	matchSpecBodyAst,
	matchStructDeclAstBody,
	matchTypeAst,
	ParamAst,
	rangeOfExplicitByValOrRef,
	rangeOfNameAndRange,
	rangeOfPuritySpecifier,
	SeqAst,
	SigAst,
	SpecBodyAst,
	SpecDeclAst,
	specs,
	SpecUseAst,
	structAliases,
	StructAliasAst,
	StructDeclAst,
	structs,
	ThenAst,
	TypeAst,
	TypeParamAst;
import util.collection.arr : Arr, ArrWithSize, first, range, toArr;
import util.collection.arrBuilder : add, ArrBuilder, finishArr;
import util.collection.arrUtil : tail;
import util.collection.sortUtil : eachSorted, findUnsortedPair, UnsortedPair;
import util.comparison : compareNat32, Comparison;
import util.opt : force, has, Opt;
import util.ptr : Ptr;
import util.sexpr : Sexpr, nameAndTata, tataArr, tataNamedRecord, tataSym;
import util.sourceRange : Pos, rangeOfStartAndName, RangeWithinFile, sexprOfRangeWithinFile;
import util.sym : shortSymAlphaLiteral, Sym, symSize;
import util.types : safeSizeTToU32;
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

immutable(Sexpr) sexprOfTokens(Alloc)(ref Alloc alloc, ref immutable Arr!Token tokens) {
	return tataArr(alloc, tokens, (ref immutable Token it) =>
		sexprOfToken(alloc, it));
}

immutable(Arr!Token) tokensOfAst(Alloc)(ref Alloc alloc, ref immutable FileAst ast) {
	ArrBuilder!Token tokens;

	addImportTokens!Alloc(alloc, tokens, imports(ast), shortSymAlphaLiteral("import"));
	addImportTokens!Alloc(alloc, tokens, exports(ast), shortSymAlphaLiteral("export"));

	eachSorted!(RangeWithinFile, SpecDeclAst, StructAliasAst, StructDeclAst, FunDeclAst)(
		RangeWithinFile.max,
		(ref immutable RangeWithinFile a, ref immutable RangeWithinFile b) =>
			compareRangeWithinFile(a, b),
		specs(ast), (ref immutable SpecDeclAst it) => it.range, (ref immutable SpecDeclAst it) {
			addSpecTokens(alloc, tokens, it);
		},
		structAliases(ast), (ref immutable StructAliasAst it) => it.range, (ref immutable StructAliasAst it) {
			addStructAliasTokens(alloc, tokens, it);
		},
		structs(ast), (ref immutable StructDeclAst it) => it.range, (ref immutable StructDeclAst it) {
			addStructTokens(alloc, tokens, it);
		},
		funs(ast), (ref immutable FunDeclAst it) => it.range, (ref immutable FunDeclAst it) {
			addFunTokens(alloc, tokens, it);
		});
	immutable Arr!Token res = finishArr(alloc, tokens);
	assertTokensSorted(res);
	return res;
}

private:

immutable(RangeWithinFile) rangeAtName(immutable Pos start, immutable Sym name) {
	return immutable RangeWithinFile(start, safeSizeTToU32(start + symSize(name)));
}

void addImportTokens(Alloc)(
	ref Alloc alloc,
	ref ArrBuilder!Token tokens,
	ref immutable Opt!ImportsOrExportsAst a,
	immutable Sym keyword,
) {
	if (has(a)) {
		add(alloc, tokens, immutable Token(Token.Kind.keyword, rangeAtName(force(a).range.start, keyword)));
		foreach (ref immutable ImportAst path; range(force(a).paths))
			add(alloc, tokens, immutable Token(
				Token.Kind.importPath,
				immutable RangeWithinFile(path.range.start + path.nDots, path.range.end)));
	}
}

void addSpecTokens(Alloc)(ref Alloc alloc, ref ArrBuilder!Token tokens, ref immutable SpecDeclAst a) {
	add(alloc, tokens, immutable Token(Token.Kind.specDef, rangeAtName(a.range.start, a.name)));
	addTypeParamsTokens(alloc, tokens, a.typeParams);
	matchSpecBodyAst!void(
		a.body_,
		(ref immutable SpecBodyAst.Builtin) {},
		(ref immutable Arr!SigAst sigs) {
			foreach (ref immutable SigAst sig; range(sigs))
				addSigTokens(alloc, tokens, sig);
		});
}

void addSigTokens(Alloc)(ref Alloc alloc, ref ArrBuilder!Token tokens, ref immutable SigAst a) {
	add(alloc, tokens, immutable Token(Token.Kind.funDef, rangeAtName(a.range.start, a.name)));
	addTypeTokens(alloc, tokens, a.returnType);
	foreach (ref immutable ParamAst param; range(toArr(a.params)))
		addParamTokens(alloc, tokens, param);
}

void addTypeTokens(Alloc)(ref Alloc alloc, ref ArrBuilder!Token tokens, ref immutable TypeAst a) {
	matchTypeAst!void(
		a,
		(ref immutable TypeAst.TypeParam it) {
			add(alloc, tokens, immutable Token(Token.Kind.typeParamRef, it.range));
		},
		(ref immutable TypeAst.InstStruct it) {
			addInstStructTokens(alloc, tokens, it);
		});
}

void addOptTypeTokens(Alloc)(ref Alloc alloc, ref ArrBuilder!Token tokens, ref immutable Opt!(Ptr!TypeAst) a) {
	if (has(a))
		addTypeTokens(alloc, tokens, force(a));
}

void addInstStructTokens(Alloc)(ref Alloc alloc, ref ArrBuilder!Token tokens, ref immutable TypeAst.InstStruct a) {
	add(alloc, tokens, immutable Token(Token.Kind.structRef, rangeOfNameAndRange(a.name)));
	addTypeArgsTokens(alloc, tokens, a.typeArgs);
}

void addTypeArgsTokens(Alloc)(
	ref Alloc alloc,
	ref ArrBuilder!Token tokens,
	ref immutable ArrWithSize!TypeAst typeArgs,
) {
	foreach (ref immutable TypeAst typeArg; range(toArr(typeArgs)))
		addTypeTokens(alloc, tokens, typeArg);
}

void addParamTokens(Alloc)(ref Alloc alloc, ref ArrBuilder!Token tokens, ref immutable ParamAst a) {
	if (has(a.name))
		add(alloc, tokens, immutable Token(Token.Kind.paramDef, rangeOfStartAndName(a.range.start, force(a.name))));
	addTypeTokens(alloc, tokens, a.type);
}

void addTypeParamsTokens(Alloc)(
	ref Alloc alloc,
	ref ArrBuilder!Token tokens,
	ref immutable ArrWithSize!TypeParamAst a,
) {
	foreach (ref immutable TypeParamAst typeParam; range(toArr(a)))
		add(alloc, tokens, immutable Token(Token.Kind.typeParamDef, typeParam.range));
}

void addStructAliasTokens(Alloc)(ref Alloc alloc, ref ArrBuilder!Token tokens, ref immutable StructAliasAst a) {
	add(alloc, tokens, immutable Token(Token.Kind.structDef, rangeAtName(a.range.start, a.name)));
	addTypeParamsTokens(alloc, tokens, a.typeParams);
	addInstStructTokens(alloc, tokens, a.target);
}

void addStructTokens(Alloc)(ref Alloc alloc, ref ArrBuilder!Token tokens, ref immutable StructDeclAst a) {
	add(alloc, tokens, immutable Token(Token.Kind.structDef, rangeAtName(a.range.start, a.name)));
	addTypeParamsTokens(alloc, tokens, a.typeParams);
	if (has(a.purity))
		add(alloc, tokens, immutable Token(Token.Kind.purity, rangeOfPuritySpecifier(force(a.purity))));
	matchStructDeclAstBody!void(
		a.body_,
		(ref immutable StructDeclAst.Body.Builtin) {},
		(ref immutable StructDeclAst.Body.ExternPtr) {},
		(ref immutable StructDeclAst.Body.Record record) {
			if (has(record.explicitByValOrRef))
				add(alloc, tokens, immutable Token(
					Token.Kind.explicitByValOrRef, rangeOfExplicitByValOrRef(force(record.explicitByValOrRef))));
			foreach (ref immutable StructDeclAst.Body.Record.Field field; range(record.fields)) {
				add(alloc, tokens, immutable Token(Token.Kind.fieldDef, rangeAtName(field.range.start, field.name)));
				addTypeTokens(alloc, tokens, field.type);
			}
		},
		(ref immutable StructDeclAst.Body.Union union_) {
			foreach (ref immutable TypeAst.InstStruct member; range(union_.members))
				addInstStructTokens(alloc, tokens, member);
		});
}

void addFunTokens(Alloc)(ref Alloc alloc, ref ArrBuilder!Token tokens, ref immutable FunDeclAst a) {
	addTypeParamsTokens(alloc, tokens, a.typeParams);
	addSigTokens(alloc, tokens, a.sig);
	foreach (ref immutable SpecUseAst specUse; range(a.specUses)) {
		add(alloc, tokens, immutable Token(Token.Kind.specRef, rangeOfNameAndRange(specUse.spec)));
		addTypeArgsTokens(alloc, tokens, specUse.typeArgs);
	}
	matchFunBodyAst!void(
		a.body_,
		(ref immutable FunBodyAst.Builtin) {},
		(ref immutable FunBodyAst.Extern) {},
		(ref immutable ExprAst it) {
			addExprTokens(alloc, tokens, it);
		});
}

void addExprTokens(Alloc)(ref Alloc alloc, ref ArrBuilder!Token tokens, ref immutable ExprAst a) {
	matchExprAstKind!void(
		a.kind,
		(ref immutable BogusAst) {},
		(ref immutable CallAst it) {
			void addName() {
				add(alloc, tokens, immutable Token(Token.Kind.funRef, rangeOfNameAndRange(it.funName)));
				addTypeArgsTokens(alloc, tokens, it.typeArgs);
			}
			final switch (it.style) {
				case CallAst.Style.dot:
				case CallAst.Style.infix:
					addExprTokens(alloc, tokens, first(it.args));
					addName();
					addExprsTokens(alloc, tokens, tail(it.args));
					break;
				case CallAst.Style.prefix:
				case CallAst.Style.single:
					addName();
					addExprsTokens(alloc, tokens, it.args);
					break;
			}
		},
		(ref immutable CreateArrAst it) {
			addOptTypeTokens(alloc, tokens, it.elementType);
			addExprsTokens(alloc, tokens, it.args);
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
		(ref immutable LambdaAst it) {
			foreach (ref immutable LambdaAst.Param param; range(it.params))
				addLambdaAstParam(alloc, tokens, param);
			addExprTokens(alloc, tokens, it.body_);
		},
		(ref immutable LetAst it) {
			add(alloc, tokens, immutable Token(Token.Kind.localDef, rangeOfNameAndRange(it.name)));
			addExprTokens(alloc, tokens, it.initializer);
			addExprTokens(alloc, tokens, it.then);
		},
		(ref immutable LiteralAst literal) {
			immutable Token.Kind kind = matchLiteralAst!(immutable Token.Kind)(
				literal,
				(ref immutable LiteralAst.Float) =>
					Token.Kind.literalNumber,
				(ref immutable LiteralAst.Int) =>
					Token.Kind.literalNumber,
				(ref immutable LiteralAst.Nat) =>
					Token.Kind.literalNumber,
				(ref immutable Str) =>
					Token.Kind.literalString);
			add(alloc, tokens, immutable Token(kind, a.range));
		},
		(ref immutable MatchAst it) {
			addExprTokens(alloc, tokens, it.matched);
			foreach (ref immutable MatchAst.CaseAst case_; range(it.cases)) {
				add(alloc, tokens, immutable Token(Token.Kind.structRef, rangeOfNameAndRange(case_.structName)));
				if (has(case_.local))
					add(alloc, tokens, immutable Token(Token.Kind.localDef, rangeOfNameAndRange(force(case_.local))));
				addExprTokens(alloc, tokens, case_.then);
			}
		},
		(ref immutable SeqAst it) {
			addExprTokens(alloc, tokens, it.first);
			addExprTokens(alloc, tokens, it.then);
		},
		(ref immutable ThenAst it) {
			addLambdaAstParam(alloc, tokens, it.left);
			addExprTokens(alloc, tokens, it.futExpr);
			addExprTokens(alloc, tokens, it.then);
		});
}

void addLambdaAstParam(Alloc)(ref Alloc alloc, ref ArrBuilder!Token tokens, ref immutable LambdaAst.Param param) {
	add(alloc, tokens, immutable Token(Token.Kind.paramDef, rangeOfNameAndRange(param)));
}

void addExprsTokens(Alloc)(ref Alloc alloc, ref ArrBuilder!Token tokens, immutable Arr!ExprAst exprs) {
	foreach (ref immutable ExprAst expr; range(exprs))
		addExprTokens(alloc, tokens, expr);
}

void assertTokensSorted(ref immutable Arr!Token tokens) {
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

immutable(Sexpr) sexprOfToken(Alloc)(ref Alloc alloc, ref immutable Token token) {
	return tataNamedRecord(alloc, "token", [
		nameAndTata("kind", tataSym(symOfTokenKind(token.kind))),
		nameAndTata("range", sexprOfRangeWithinFile(alloc, token.range))]);
}
