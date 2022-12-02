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
	DelayStructInsts, instantiateStruct, instantiateStructNeverDelay, TypeArgsArray, typeArgsArray;
import frontend.parse.ast : NameAndRange, range, rangeOfNameAndRange, symForTypeAstDict, symForTypeAstSuffix, TypeAst;
import frontend.programState : ProgramState;
import model.diag : Diag;
import model.model :
	CommonTypes,
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
import util.col.arrUtil : eachPair, findPtr, mapWithIndex;
import util.col.mutArr : MutArr;
import util.col.mutMaxArr : fillMutMaxArr, mapTo, tempAsArr;
import util.opt : force, has, none, noneMut, Opt, some;
import util.ptr : castNonScope_ref;
import util.sourceRange : RangeWithinFile;
import util.sym : Sym, sym;
import util.util : todo;

private Type instStructFromAst(
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	Sym name,
	RangeWithinFile range,
	in TypeAst[] typeArgAsts,
	in StructsAndAliasesDict structsAndAliasesDict,
	in TypeParam[] typeParamsScope,
	DelayStructInsts delayStructInsts,
) {
	Opt!StructOrAliasAndIndex opDeclFromHere = structsAndAliasesDict[name];
	if (has(opDeclFromHere))
		markUsedStructOrAlias(ctx, force(opDeclFromHere));
	Opt!StructOrAlias here = has(opDeclFromHere)
		? some(force(opDeclFromHere).structOrAlias)
		: none!StructOrAlias;
	Opt!StructOrAlias opDecl = tryFindT!StructOrAlias(
		ctx, name, range, here, Diag.DuplicateImports.Kind.type, Diag.NameNotFound.Kind.type, (in NameReferents nr) =>
			nr.structOrAlias);
	if (!has(opDecl))
		return Type(Type.Bogus());
	else {
		StructOrAlias sOrA = force(opDecl);
		size_t nExpectedTypeArgs = typeParams(sOrA).length;
		TypeArgsArray typeArgs = typeArgsArray();
		getTypeArgsIfNumberMatches(
			typeArgs,
			ctx, commonTypes, range, structsAndAliasesDict,
			sOrA, nExpectedTypeArgs, typeArgAsts, typeParamsScope, delayStructInsts);
		return sOrA.matchWithPointers!Type(
			(StructAlias* a) =>
				nExpectedTypeArgs != 0
					? todo!Type("alias with type params")
					: typeFromOptInst(target(*a)),
			(StructDecl* decl) =>
				Type(instantiateStruct(ctx.alloc, ctx.programState, decl, tempAsArr(typeArgs), delayStructInsts)));
	}
}

private void getTypeArgsIfNumberMatches(
	ref TypeArgsArray res,
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	RangeWithinFile range,
	in StructsAndAliasesDict structsAndAliasesDict,
	StructOrAlias sOrA,
	size_t nExpectedTypeArgs,
	in TypeAst[] typeArgAsts,
	in TypeParam[] typeParamsScope,
	DelayStructInsts delayStructInsts,
) {
	if (typeArgAsts.length != nExpectedTypeArgs) {
		addDiag(ctx, range, Diag(Diag.WrongNumberTypeArgsForStruct(sOrA, nExpectedTypeArgs, typeArgAsts.length)));
		fillMutMaxArr(res, nExpectedTypeArgs, Type(Type.Bogus()));
	} else
		typeArgsFromAsts(res, ctx, commonTypes, typeArgAsts, structsAndAliasesDict, typeParamsScope, delayStructInsts);
}

TypeParam[] checkTypeParams(ref CheckCtx ctx, in NameAndRange[] asts) {
	TypeParam[] res = mapWithIndex!(TypeParam, NameAndRange)(
		ctx.alloc,
		asts,
		(size_t index, scope ref NameAndRange ast) =>
			TypeParam(rangeInFile(ctx, rangeOfNameAndRange(ast, ctx.allSymbols)), ast.name, index));
	eachPair!TypeParam(res, (in TypeParam a, in TypeParam b) {
		if (a.name == b.name)
			addDiag(ctx, b.range, Diag(Diag.DuplicateDeclaration(Diag.DuplicateDeclaration.Kind.typeParam, b.name)));
	});
	return res;
}

Type typeFromAstNoTypeParamsNeverDelay(
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	in TypeAst ast,
	in StructsAndAliasesDict structsAndAliasesDict,
) =>
	typeFromAst(ctx, commonTypes, ast, structsAndAliasesDict, [], noneMut!(MutArr!(StructInst*)*));

Type typeFromAst(
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	in TypeAst ast,
	in StructsAndAliasesDict structsAndAliasesDict,
	in TypeParam[] typeParamsScope,
	DelayStructInsts delayStructInsts,
) =>
	ast.matchIn!Type(
		(in TypeAst.Dict it) =>
			instStructFromAst(
				ctx,
				commonTypes,
				symForTypeAstDict(it.kind),
				range(it),
				[castNonScope_ref(it).k, castNonScope_ref(it).v],
				structsAndAliasesDict,
				typeParamsScope,
				delayStructInsts),
		(in TypeAst.Fun it) =>
			typeFromFunAst(ctx, commonTypes, it, structsAndAliasesDict, typeParamsScope, delayStructInsts),
		(in TypeAst.InstStruct iAst) {
			Opt!(Diag.TypeShouldUseSyntax.Kind) optSyntax = typeSyntaxKind(iAst.name.name);
			if (has(optSyntax))
				addDiag(ctx, iAst.range, Diag(Diag.TypeShouldUseSyntax(force(optSyntax))));

			Opt!(TypeParam*) found = findPtr!TypeParam(typeParamsScope, (in TypeParam x) =>
				x.name == iAst.name.name);
			if (has(found)) {
				if (!empty(iAst.typeArgs))
					addDiag(ctx, iAst.range, Diag(Diag.TypeParamCantHaveTypeArgs()));
				return Type(force(found));
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
		(in TypeAst.Suffix it) =>
			instStructFromAst(
				ctx,
				commonTypes,
				symForTypeAstSuffix(it.kind),
				range(it),
				[castNonScope_ref(it).left],
				structsAndAliasesDict,
				typeParamsScope,
				delayStructInsts),
		(in TypeAst.Tuple it) =>
			instStructFromAst(
				ctx,
				commonTypes,
				sym!"pair",
				range(it),
				[castNonScope_ref(it).a, castNonScope_ref(it).b],
				structsAndAliasesDict,
				typeParamsScope,
				delayStructInsts));

private Opt!(Diag.TypeShouldUseSyntax.Kind) typeSyntaxKind(Sym a) {
	switch (a.value) {
		case sym!"const-pointer".value:
			return some(Diag.TypeShouldUseSyntax.Kind.pointer);
		case sym!"dict".value:
			return some(Diag.TypeShouldUseSyntax.Kind.dict);
		case sym!"future".value:
			return some(Diag.TypeShouldUseSyntax.Kind.future);
		case sym!"list".value:
			return some(Diag.TypeShouldUseSyntax.Kind.list);
		case sym!"mut-dict".value:
			return some(Diag.TypeShouldUseSyntax.Kind.mutDict);
		case sym!"mut-list".value:
			return some(Diag.TypeShouldUseSyntax.Kind.mutList);
		case sym!"mut-pointer".value:
			return some(Diag.TypeShouldUseSyntax.Kind.mutPointer);
		case sym!"option".value:
			return some(Diag.TypeShouldUseSyntax.Kind.opt);
		case sym!"pair".value:
			return some(Diag.TypeShouldUseSyntax.Kind.pair);
		default:
			return none!(Diag.TypeShouldUseSyntax.Kind);
	}
}

private Type typeFromOptInst(Opt!(StructInst*) a) =>
	has(a) ? Type(force(a)) : Type(Type.Bogus());

private Type typeFromFunAst(
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	in TypeAst.Fun ast,
	in StructsAndAliasesDict structsAndAliasesDict,
	in TypeParam[] typeParamsScope,
	DelayStructInsts delayStructInsts,
) {
	immutable StructDecl*[] structs = commonTypes.funStructs[ast.kind];
	if (ast.returnAndParamTypes.length > structs.length)
		// We don't have a fun type big enough
		todo!void("!");
	StructDecl* decl = structs[ast.returnAndParamTypes.length - 1];
	TypeArgsArray typeArgs = typeArgsArray();
	mapTo(typeArgs, ast.returnAndParamTypes, (ref TypeAst x) =>
		typeFromAst(ctx, commonTypes, x, structsAndAliasesDict, typeParamsScope, delayStructInsts));
	return Type(instantiateStruct(ctx.alloc, ctx.programState, decl, tempAsArr(typeArgs), delayStructInsts));
}

Opt!(SpecDecl*) tryFindSpec(ref CheckCtx ctx, NameAndRange name, in SpecsDict specsDict) {
	Opt!SpecDeclAndIndex opDeclFromHere = specsDict[name.name];
	if (has(opDeclFromHere))
		markUsedSpec(ctx, force(opDeclFromHere).index);
	Opt!(SpecDecl*) here = has(opDeclFromHere)
		? some(force(opDeclFromHere).decl)
		: none!(SpecDecl*);
	return tryFindT!(SpecDecl*)(
		ctx,
		name.name,
		rangeOfNameAndRange(name, ctx.allSymbols),
		here,
		Diag.DuplicateImports.Kind.spec,
		Diag.NameNotFound.Kind.spec,
		(in NameReferents nr) =>
			nr.spec);
}

void typeArgsFromAsts(
	ref TypeArgsArray res,
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	in TypeAst[] typeAsts,
	in StructsAndAliasesDict structsAndAliasesDict,
	in TypeParam[] typeParamsScope,
	DelayStructInsts delayStructInsts,
) {
	mapTo(res, typeAsts, (ref TypeAst ast) =>
		typeFromAst(ctx, commonTypes, ast, structsAndAliasesDict, typeParamsScope, delayStructInsts));
}

Type makeFutType(ref Alloc alloc, ref ProgramState programState, ref CommonTypes commonTypes, Type type) =>
	Type(instantiateStructNeverDelay(alloc, programState, commonTypes.future, [type]));

private:

Opt!T tryFindT(T)(
	ref CheckCtx ctx,
	Sym name,
	RangeWithinFile range,
	Opt!T fromThisModule,
	Diag.DuplicateImports.Kind duplicateImportKind,
	Diag.NameNotFound.Kind nameNotFoundKind,
	in Opt!T delegate(in NameReferents) @safe @nogc pure nothrow getFromNameReferents,
) {
	Cell!(Opt!T) res = Cell!(Opt!T)(fromThisModule);
	eachImportAndReExport(ctx, name, (ImportIndex index, in NameReferents referents) {
		Opt!T got = getFromNameReferents(referents);
		if (has(got)) {
			markUsedImport(ctx, index);
			if (has(cellGet(res)))
				// TODO: include both modules in the diag
				addDiag(ctx, range, Diag(Diag.DuplicateImports(duplicateImportKind, name)));
			else
				cellSet(res, got);
		}
	});
	if (!has(cellGet(res)))
		addDiag(ctx, range, Diag(Diag.NameNotFound(nameNotFoundKind, name)));
	return cellGet(res);
}
