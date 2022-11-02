module frontend.check.typeFromAst;

@safe @nogc pure nothrow:

import frontend.check.checkCtx :
	addDiag,
	CheckCtx,
	eachImportAndReExport,
	ImportIndex,
	markUsedImport,
	markUsedSpec,
	markUsedStructOrAlias,
	rangeInFile;
import frontend.check.dicts : SpecDeclAndIndex, SpecsDict, StructsAndAliasesDict, StructOrAliasAndIndex;
import frontend.check.instantiate :
	DelayStructInsts, instantiateStruct, instantiateStructNeverDelay, TypeArgsArray, typeArgsArray, TypeParamsScope;
import frontend.parse.ast :
	matchTypeAst, NameAndRange, range, rangeOfNameAndRange, symForTypeAstDict, symForTypeAstSuffix, TypeAst;
import frontend.programState : ProgramState;
import model.diag : Diag;
import model.model :
	CommonTypes,
	FunKind,
	FunKindAndStructs,
	matchStructOrAliasPtr,
	NameReferents,
	SpecDecl,
	StructAlias,
	StructDecl,
	StructInst,
	StructOrAlias,
	target,
	Type,
	TypeParam,
	typeParams;
import util.alloc.alloc : Alloc;
import util.cell : Cell, cellGet, cellSet;
import util.col.arr : empty;
import util.col.arrUtil : eachPair, find, findPtr, mapWithIndex_scope;
import util.col.mutArr : MutArr;
import util.col.mutMaxArr : fillMutMaxArr, mapTo, tempAsArr;
import util.opt : force, has, none, noneMut, Opt, some;
import util.sourceRange : RangeWithinFile;
import util.sym : shortSym, shortSymValue, Sym;
import util.util : todo;

private immutable(Type) instStructFromAst(
	ref CheckCtx ctx,
	ref immutable CommonTypes commonTypes,
	immutable Sym name,
	immutable RangeWithinFile range,
	scope immutable TypeAst[] typeArgAsts,
	ref immutable StructsAndAliasesDict structsAndAliasesDict,
	immutable TypeParamsScope typeParamsScope,
	DelayStructInsts delayStructInsts,
) {
	immutable Opt!StructOrAliasAndIndex opDeclFromHere = structsAndAliasesDict[name];
	if (has(opDeclFromHere))
		markUsedStructOrAlias(ctx, force(opDeclFromHere));
	immutable Opt!StructOrAlias here = has(opDeclFromHere)
		? some(force(opDeclFromHere).structOrAlias)
		: none!StructOrAlias;
	immutable Opt!StructOrAlias opDecl = tryFindT!StructOrAlias(
		ctx,
		name,
		range,
		here,
		Diag.DuplicateImports.Kind.type,
		Diag.NameNotFound.Kind.type,
		(ref immutable NameReferents nr) =>
			nr.structOrAlias);
	if (!has(opDecl))
		return immutable Type(Type.Bogus());
	else {
		immutable StructOrAlias sOrA = force(opDecl);
		immutable size_t nExpectedTypeArgs = typeParams(sOrA).length;
		TypeArgsArray typeArgs = typeArgsArray();
		getTypeArgsIfNumberMatches(
			typeArgs,
			ctx, commonTypes, range, structsAndAliasesDict,
			sOrA, nExpectedTypeArgs, typeArgAsts, typeParamsScope, delayStructInsts);
		return matchStructOrAliasPtr!(immutable Type)(
			sOrA,
			(ref immutable StructAlias a) =>
				nExpectedTypeArgs != 0
					? todo!(immutable Type)("alias with type params")
					: typeFromOptInst(target(a)),
			(immutable StructDecl* decl) =>
				immutable Type(instantiateStruct(
					ctx.alloc,
					ctx.programState,
					decl,
					tempAsArr(typeArgs),
					delayStructInsts)));
	}
}

private void getTypeArgsIfNumberMatches(
	ref TypeArgsArray res,
	ref CheckCtx ctx,
	ref immutable CommonTypes commonTypes,
	immutable RangeWithinFile range,
	ref immutable StructsAndAliasesDict structsAndAliasesDict,
	immutable StructOrAlias sOrA,
	immutable size_t nExpectedTypeArgs,
	scope immutable TypeAst[] typeArgAsts,
	immutable TypeParamsScope typeParamsScope,
	DelayStructInsts delayStructInsts,
) {
	if (typeArgAsts.length != nExpectedTypeArgs) {
		addDiag(ctx, range, immutable Diag(
			immutable Diag.WrongNumberTypeArgsForStruct(sOrA, nExpectedTypeArgs, typeArgAsts.length)));
		fillMutMaxArr(res, nExpectedTypeArgs, immutable Type(immutable Type.Bogus()));
	} else
		typeArgsFromAsts(
			res,
			ctx,
			commonTypes,
			typeArgAsts,
			structsAndAliasesDict,
			typeParamsScope,
			delayStructInsts);
}

immutable(TypeParam[]) checkTypeParams(ref CheckCtx ctx, scope immutable NameAndRange[] asts) {
	immutable TypeParam[] res = mapWithIndex_scope!(TypeParam, NameAndRange)(
		ctx.alloc,
		asts,
		(immutable size_t index, scope ref immutable NameAndRange ast) =>
			immutable TypeParam(rangeInFile(ctx, rangeOfNameAndRange(ast, ctx.allSymbols)), ast.name, index));
	eachPair!TypeParam(res, (ref immutable TypeParam a, ref immutable TypeParam b) {
		if (a.name == b.name)
			addDiag(ctx, b.range, immutable Diag(
				immutable Diag.DuplicateDeclaration(Diag.DuplicateDeclaration.Kind.typeParam, b.name)));
	});
	return res;
}

immutable(Type) typeFromAstNoTypeParamsNeverDelay(
	ref CheckCtx ctx,
	ref immutable CommonTypes commonTypes,
	scope ref immutable TypeAst ast,
	scope ref immutable StructsAndAliasesDict structsAndAliasesDict,
) {
	static immutable TypeParamsScope emptyTypeParams = immutable TypeParamsScope([]);
	return typeFromAst(
		ctx, commonTypes, ast, structsAndAliasesDict, emptyTypeParams, noneMut!(MutArr!(StructInst*)*));
}

immutable(Type) typeFromAst(
	ref CheckCtx ctx,
	ref immutable CommonTypes commonTypes,
	scope ref immutable TypeAst ast,
	scope ref immutable StructsAndAliasesDict structsAndAliasesDict,
	immutable TypeParamsScope typeParamsScope,
	DelayStructInsts delayStructInsts,
) =>
	matchTypeAst!(
		immutable Type,
		(immutable TypeAst.Dict it) =>
			instStructFromAst(
				ctx,
				commonTypes,
				symForTypeAstDict(it.kind),
				range(it),
				[it.k, it.v],
				structsAndAliasesDict,
				typeParamsScope,
				delayStructInsts),
		(immutable TypeAst.Fun it) =>
			typeFromFunAst(ctx, commonTypes, it, structsAndAliasesDict, typeParamsScope, delayStructInsts),
		(immutable TypeAst.InstStruct iAst) {
			immutable Opt!(Diag.TypeShouldUseSyntax.Kind) optSyntax = typeSyntaxKind(iAst.name.name);
			if (has(optSyntax))
				addDiag(ctx, iAst.range, immutable Diag(immutable Diag.TypeShouldUseSyntax(force(optSyntax))));

			immutable Opt!(TypeParam*) found =
				findPtr!TypeParam(typeParamsScope.innerTypeParams, (immutable TypeParam* it) =>
					it.name == iAst.name.name);
			if (has(found)) {
				if (!empty(iAst.typeArgs))
					addDiag(ctx, iAst.range, immutable Diag(immutable Diag.TypeParamCantHaveTypeArgs()));
				return immutable Type(force(found));
			} else
				return instStructFromAst(
					ctx,
					commonTypes,
					iAst.name.name,
					iAst.range,
					iAst.typeArgs,
					structsAndAliasesDict,
					typeParamsScope,
					delayStructInsts);
		},
		(immutable TypeAst.Suffix it) =>
			instStructFromAst(
				ctx,
				commonTypes,
				symForTypeAstSuffix(it.kind),
				range(it),
				[it.left],
				structsAndAliasesDict,
				typeParamsScope,
				delayStructInsts),
		(immutable TypeAst.Tuple it) =>
			instStructFromAst(
				ctx,
				commonTypes,
				shortSym("pair"),
				range(it),
				[it.a, it.b],
				structsAndAliasesDict,
				typeParamsScope,
				delayStructInsts),
	)(ast);

private immutable(Opt!(Diag.TypeShouldUseSyntax.Kind)) typeSyntaxKind(immutable Sym a) {
	switch (a.value) {
		case shortSymValue("const-ptr"):
			return some(Diag.TypeShouldUseSyntax.Kind.ptr);
		case shortSymValue("dict"):
			return some(Diag.TypeShouldUseSyntax.Kind.dict);
		case shortSymValue("future"):
			return some(Diag.TypeShouldUseSyntax.Kind.future);
		case shortSymValue("list"):
			return some(Diag.TypeShouldUseSyntax.Kind.list);
		case shortSymValue("mut-dict"):
			return some(Diag.TypeShouldUseSyntax.Kind.mutDict);
		case shortSymValue("mut-list"):
			return some(Diag.TypeShouldUseSyntax.Kind.mutList);
		case shortSymValue("mut-ptr"):
			return some(Diag.TypeShouldUseSyntax.Kind.mutPtr);
		case shortSymValue("opt"):
			return some(Diag.TypeShouldUseSyntax.Kind.opt);
		case shortSymValue("pair"):
			return some(Diag.TypeShouldUseSyntax.Kind.pair);
		default:
			return none!(Diag.TypeShouldUseSyntax.Kind);
	}
}

private immutable(Type) typeFromOptInst(immutable Opt!(StructInst*) a) =>
	has(a) ? immutable Type(force(a)) : immutable Type(Type.Bogus());

private immutable(Type) typeFromFunAst(
	ref CheckCtx ctx,
	ref immutable CommonTypes commonTypes,
	immutable TypeAst.Fun ast,
	ref immutable StructsAndAliasesDict structsAndAliasesDict,
	immutable TypeParamsScope typeParamsScope,
	DelayStructInsts delayStructInsts,
) {
	immutable FunKind funKind = () {
		final switch (ast.kind) {
			case TypeAst.Fun.Kind.act:
				return FunKind.mut;
			case TypeAst.Fun.Kind.fun:
				return FunKind.plain;
			case TypeAst.Fun.Kind.ref_:
				return FunKind.ref_;
		}
	}();
	immutable Opt!FunKindAndStructs optF = find!FunKindAndStructs(
		commonTypes.funKindsAndStructs,
		(ref immutable FunKindAndStructs it) =>
			it.kind == funKind);
	immutable StructDecl*[] structs = force(optF).structs;
	if (ast.returnAndParamTypes.length > structs.length)
		// We don't have a fun type big enough
		todo!void("!");
	immutable StructDecl* decl = structs[ast.returnAndParamTypes.length - 1];
	TypeArgsArray typeArgs = typeArgsArray();
	mapTo(typeArgs, ast.returnAndParamTypes, (ref immutable TypeAst x) =>
		typeFromAst(ctx, commonTypes, x, structsAndAliasesDict, typeParamsScope, delayStructInsts));
	return immutable Type(instantiateStruct(ctx.alloc, ctx.programState, decl, tempAsArr(typeArgs), delayStructInsts));
}

immutable(Opt!(SpecDecl*)) tryFindSpec(
	ref CheckCtx ctx,
	scope immutable NameAndRange name,
	scope ref immutable SpecsDict specsDict,
) {
	immutable Opt!SpecDeclAndIndex opDeclFromHere = specsDict[name.name];
	if (has(opDeclFromHere))
		markUsedSpec(ctx, force(opDeclFromHere).index);
	immutable Opt!(SpecDecl*) here = has(opDeclFromHere) ? some(force(opDeclFromHere).decl) : none!(SpecDecl*);
	return tryFindT!(SpecDecl*)(
		ctx,
		name.name,
		rangeOfNameAndRange(name, ctx.allSymbols),
		here,
		Diag.DuplicateImports.Kind.spec,
		Diag.NameNotFound.Kind.spec,
		(ref immutable NameReferents nr) =>
			nr.spec);
}

void typeArgsFromAsts(
	ref TypeArgsArray res,
	ref CheckCtx ctx,
	ref immutable CommonTypes commonTypes,
	scope immutable TypeAst[] typeAsts,
	scope ref immutable StructsAndAliasesDict structsAndAliasesDict,
	immutable TypeParamsScope typeParamsScope,
	DelayStructInsts delayStructInsts,
) {
	mapTo(res, typeAsts, (ref immutable TypeAst ast) =>
		typeFromAst(ctx, commonTypes, ast, structsAndAliasesDict, typeParamsScope, delayStructInsts));
}

immutable(Type) makeFutType(
	ref Alloc alloc,
	ref ProgramState programState,
	ref immutable CommonTypes commonTypes,
	immutable Type type,
) =>
	immutable Type(instantiateStructNeverDelay(alloc, programState, commonTypes.future, [type]));

private:

immutable(Opt!T) tryFindT(T)(
	ref CheckCtx ctx,
	immutable Sym name,
	immutable RangeWithinFile range,
	ref immutable Opt!T fromThisModule,
	immutable Diag.DuplicateImports.Kind duplicateImportKind,
	immutable Diag.NameNotFound.Kind nameNotFoundKind,
	scope immutable(Opt!T) delegate(ref immutable NameReferents) @safe @nogc pure nothrow getFromNameReferents,
) {
	Cell!(immutable Opt!T) res = Cell!(immutable Opt!T)(fromThisModule);
	eachImportAndReExport(ctx, name, (immutable ImportIndex index, ref immutable NameReferents referents) {
		immutable Opt!T got = getFromNameReferents(referents);
		if (has(got)) {
			markUsedImport(ctx, index);
			if (has(cellGet(res)))
				// TODO: include both modules in the diag
				addDiag(ctx, range, immutable Diag(immutable Diag.DuplicateImports(duplicateImportKind, name)));
			else
				cellSet(res, got);
		}
	});
	if (!has(cellGet(res)))
		addDiag(ctx, range, immutable Diag(immutable Diag.NameNotFound(nameNotFoundKind, name)));
	return cellGet(res);
}
