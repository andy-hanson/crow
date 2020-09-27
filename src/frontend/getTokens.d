module frontend.getTokens;

@safe @nogc pure nothrow:

import frontend.ast :
	exports,
	FileAst,
	FunDeclAst,
	funs,
	imports,
	matchSpecBodyAst,
	matchStructDeclAstBody,
	matchTypeAst,
	NameAndRange,
	ParamAst,
	SigAst,
	SpecBodyAst,
	SpecDeclAst,
	specs,
	structAliases,
	StructAliasAst,
	StructDeclAst,
	structs,
	TypeAst,
	TypeParamAst;

import util.collection.arr : Arr, ArrWithSize, range, toArr;
import util.collection.arrBuilder : add, ArrBuilder, finishArr;
import util.collection.sortUtil : eachSorted, findUnsortedPair, UnsortedPair;
import util.comparison : Comparison;
import util.opt : force, has, Opt;
import util.sexpr : Sexpr, tataArr, tataRecord, tataSym;
import util.sourceRange : sexprOfSourceRange, SourceRange;
import util.sym : shortSymAlphaLiteral, Sym;
import util.util : todo;

struct Token {
	enum Kind {
		explicitByValOrRef,
		fieldDef,
		funDef,
		funRef,
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
	immutable SourceRange range;
}

immutable(Sexpr) sexprOfTokens(Alloc)(ref Alloc alloc, ref immutable Arr!Token tokens) {
	return tataArr(alloc, tokens, (ref immutable Token it) =>
		sexprOfToken(alloc, it));
}

immutable(Arr!Token) getTokens(Alloc)(ref Alloc alloc, ref immutable FileAst ast) {
	ArrBuilder!Token tokens;
	eachSorted!(SourceRange, SpecDeclAst, StructAliasAst, StructDeclAst, FunDeclAst)(
		SourceRange.max,
		(ref immutable SourceRange a, ref immutable SourceRange b) =>
			compareSourceRange(a, b),
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

void addSpecTokens(Alloc)(ref Alloc alloc, ref ArrBuilder!Token tokens, ref immutable SpecDeclAst a) {
	add(alloc, tokens, immutable Token(Token.Kind.specDef, a.name.range));
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
	add(alloc, tokens, immutable Token(Token.Kind.funDef, a.name.range));
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

void addInstStructTokens(Alloc)(ref Alloc alloc, ref ArrBuilder!Token tokens, ref immutable TypeAst.InstStruct a) {
	add(alloc, tokens, immutable Token(Token.Kind.structRef, a.name.range));
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
	add(alloc, tokens, immutable Token(Token.Kind.paramDef, a.name.range));
	addTypeTokens(alloc, tokens, a.type);
}

void addTypeParamsTokens(Alloc)(ref Alloc alloc, ref ArrBuilder!Token tokens, ref immutable Arr!TypeParamAst a) {
	foreach (ref immutable TypeParamAst typeParam; range(a))
		add(alloc, tokens, immutable Token(Token.Kind.typeParamDef, typeParam.range));
}

void addStructAliasTokens(Alloc)(ref Alloc alloc, ref ArrBuilder!Token tokens, ref immutable StructAliasAst a) {
	add(alloc, tokens, immutable Token(Token.Kind.structDef, a.name.range));
	addTypeParamsTokens(alloc, tokens, a.typeParams);
	addInstStructTokens(alloc, tokens, a.target);
}

void addStructTokens(Alloc)(ref Alloc alloc, ref ArrBuilder!Token tokens, ref immutable StructDeclAst a) {
	add(alloc, tokens, immutable Token(Token.Kind.structDef, a.name.range));
	addTypeParamsTokens(alloc, tokens, a.typeParams);
	if (has(a.purity))
		add(alloc, tokens, immutable Token(Token.Kind.purity, force(a.purity).range));
	matchStructDeclAstBody!void(
		a.body_,
		(ref immutable StructDeclAst.Body.Builtin) {},
		(ref immutable StructDeclAst.Body.ExternPtr) {},
		(ref immutable StructDeclAst.Body.Record it) {
			if (has(it.explicitByValOrRef))
				add(alloc, tokens, immutable Token(Token.Kind.explicitByValOrRef, force(it.explicitByValOrRef).range));
			foreach (ref immutable StructDeclAst.Body.Record.Field field; range(it.fields)) {
				add(alloc, tokens, immutable Token(Token.Kind.fieldDef, field.name.range));
				addTypeTokens(alloc, tokens, field.type);
			}
		},
		(ref immutable StructDeclAst.Body.Union) {
			todo!void("union tokens");
		});
}

void addFunTokens(Alloc)(ref Alloc alloc, ref ArrBuilder!Token tokens, ref immutable FunDeclAst a) {
	todo!void("getFunTokens");
}

void assertTokensSorted(ref immutable Arr!Token tokens) {
	immutable Opt!UnsortedPair pair = findUnsortedPair!Token(tokens, (ref immutable Token a, ref immutable Token b) =>
		compareSourceRange(a.range, b.range));
	if (has(pair)) {
		todo!void("tokens not sorted!");
	}
}

immutable(Comparison) compareSourceRange(ref immutable SourceRange a, ref immutable SourceRange b) {
	//TODO: should be able to just assert that they don't intersect, and compare the begin
	return todo!(immutable Comparison)("compareSourceRange");
}

immutable(Sym) symOfTokenKind(immutable Token.Kind kind) {
	final switch (kind) {
		case Token.Kind.explicitByValOrRef:
			return shortSymAlphaLiteral("by-val-ref");
		case Token.Kind.fieldDef:
			return shortSymAlphaLiteral("field-def");
		case Token.Kind.funDef:
			return shortSymAlphaLiteral("fun-def");
		case Token.Kind.funRef:
			return shortSymAlphaLiteral("fun-ref");
		case Token.Kind.paramDef:
			return shortSymAlphaLiteral("param-def");
		case Token.Kind.purity:
			return shortSymAlphaLiteral("purity");
		case Token.Kind.specDef:
			return shortSymAlphaLiteral("spec-def");
		case Token.Kind.specRef:
			return shortSymAlphaLiteral("spec-ref");
		case Token.Kind.structDef:
			return shortSymAlphaLiteral("structdef");
		case Token.Kind.structRef:
			return shortSymAlphaLiteral("struct-ref");
		case Token.Kind.typeParamDef:
			return shortSymAlphaLiteral("tparam-def");
		case Token.Kind.typeParamRef:
			return shortSymAlphaLiteral("tparam-ref");
	}
}

immutable(Sexpr) sexprOfToken(Alloc)(ref Alloc alloc, ref immutable Token token) {
	return tataRecord(alloc, "token", tataSym(symOfTokenKind(token.kind)), sexprOfSourceRange(alloc, token.range));
}
