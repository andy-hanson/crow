module frontend.check.typeFromAst;

@safe @nogc pure nothrow:

import frontend.check.checkCtx :
	addDiag,
	CheckCtx,
	eachImportAndReExport,
	ImportIndex,
	markUsedImport,
	markUsedSpec,
	markUsedStructOrAlias;
import frontend.check.dicts : SpecDeclAndIndex, SpecsDict, StructsAndAliasesDict, StructOrAliasAndIndex;
import frontend.check.instantiate : DelayStructInsts, instantiateStruct, instantiateStructNeverDelay, TypeParamsScope;
import frontend.parse.ast : matchTypeAst, range, symForTypeAstDict, symForTypeAstSuffix, TypeAst;
import frontend.programState : ProgramState;
import model.diag : Diag;
import model.model :
	CommonTypes,
	FunKind,
	FunKindAndStructs,
	matchStructOrAlias,
	Module,
	NameReferents,
	SpecDecl,
	StructAlias,
	StructDecl,
	StructDeclAndArgs,
	StructInst,
	StructOrAlias,
	target,
	Type,
	TypeParam,
	typeParams;
import util.alloc.alloc : Alloc;
import util.collection.arr : at, empty, size, toArr;
import util.collection.arrUtil : arrLiteral, fillArr, findPtr, map;
import util.collection.dict : getAt;
import util.opt : force, has, mapOption, none, Opt, some;
import util.ptr : Ptr;
import util.sourceRange : RangeWithinFile;
import util.sym : shortSymAlphaLiteralValue, Sym, symEq;
import util.types : safeSizeTToU8;
import util.util : todo;

private immutable(Type) instStructFromAst(
	ref Alloc alloc,
	ref CheckCtx ctx,
	ref immutable CommonTypes commonTypes,
	immutable Sym name,
	immutable RangeWithinFile range,
	scope immutable TypeAst[] typeArgAsts,
	ref immutable StructsAndAliasesDict structsAndAliasesDict,
	immutable TypeParamsScope typeParamsScope,
	DelayStructInsts delayStructInsts,
) {
	immutable Opt!StructOrAliasAndIndex opDeclFromHere = getAt(structsAndAliasesDict, name);
	if (has(opDeclFromHere))
		markUsedStructOrAlias(ctx, force(opDeclFromHere));
	immutable Opt!StructOrAlias here = mapOption(opDeclFromHere, (ref immutable StructOrAliasAndIndex it) =>
		it.structOrAlias);
	immutable Opt!StructOrAlias opDecl = tryFindT!StructOrAlias(
		alloc,
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
		immutable size_t nExpectedTypeArgs = size(typeParams(sOrA));
		immutable Type[] typeArgs = getTypeArgsIfNumberMatches(
			alloc, ctx, commonTypes, range, structsAndAliasesDict,
			sOrA, nExpectedTypeArgs, typeArgAsts, typeParamsScope, delayStructInsts);
		return matchStructOrAlias!(immutable Type)(
			sOrA,
			(immutable Ptr!StructAlias a) =>
				nExpectedTypeArgs != 0
					? todo!(immutable Type)("alias with type params")
					: typeFromOptInst(target(a)),
			(immutable Ptr!StructDecl decl) =>
				immutable Type(instantiateStruct(
					alloc,
					ctx.programState,
					immutable StructDeclAndArgs(decl, typeArgs),
					delayStructInsts)));
	}
}

private immutable(Type[]) getTypeArgsIfNumberMatches(
	ref Alloc alloc,
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
	immutable size_t nActualTypeArgs = size(typeArgAsts);
	if (nActualTypeArgs != nExpectedTypeArgs) {
		addDiag(alloc, ctx, range, immutable Diag(
			immutable Diag.WrongNumberTypeArgsForStruct(
				sOrA,
				safeSizeTToU8(nExpectedTypeArgs),
				safeSizeTToU8(nActualTypeArgs))));
		return fillArr!Type(alloc, nExpectedTypeArgs, (immutable size_t) => immutable Type(Type.Bogus()));
	} else
		return typeArgsFromAsts(
			alloc,
			ctx,
			commonTypes,
			typeArgAsts,
			structsAndAliasesDict,
			typeParamsScope,
			delayStructInsts);
}

immutable(Type) typeFromAst(
	ref Alloc alloc,
	ref CheckCtx ctx,
	ref immutable CommonTypes commonTypes,
	immutable TypeAst ast,
	ref immutable StructsAndAliasesDict structsAndAliasesDict,
	immutable TypeParamsScope typeParamsScope,
	DelayStructInsts delayStructInsts,
) {
	return matchTypeAst!(immutable Type)(
		ast,
		(immutable TypeAst.Dict it) =>
			instStructFromAst(
				alloc,
				ctx,
				commonTypes,
				symForTypeAstDict(it.kind),
				range(it),
				[it.k, it.v],
				structsAndAliasesDict,
				typeParamsScope,
				delayStructInsts),
		(immutable TypeAst.Fun it) =>
			typeFromFunAst(alloc, ctx, commonTypes, it, structsAndAliasesDict, typeParamsScope, delayStructInsts),
		(immutable TypeAst.InstStruct iAst) {
			immutable Opt!(Diag.TypeShouldUseSyntax.Kind) optSyntax = typeSyntaxKind(iAst.name.name);
			if (has(optSyntax))
				addDiag(alloc, ctx, iAst.range, immutable Diag(immutable Diag.TypeShouldUseSyntax(force(optSyntax))));

			immutable Opt!(Ptr!TypeParam) found =
				findPtr!TypeParam(typeParamsScope.innerTypeParams, (immutable Ptr!TypeParam it) =>
					symEq(it.name, iAst.name.name));
			if (has(found)) {
				if (!empty(toArr(iAst.typeArgs)))
					addDiag(alloc, ctx, iAst.range, immutable Diag(immutable Diag.TypeParamCantHaveTypeArgs()));
				return immutable Type(force(found));
			} else
				return instStructFromAst(
					alloc,
					ctx,
					commonTypes,
					iAst.name.name,
					iAst.range,
					toArr(iAst.typeArgs),
					structsAndAliasesDict,
					typeParamsScope,
					delayStructInsts);
		},
		(immutable TypeAst.Suffix it) =>
			instStructFromAst(
				alloc,
				ctx,
				commonTypes,
				symForTypeAstSuffix(it.kind),
				range(it),
				[it.left],
				structsAndAliasesDict,
				typeParamsScope,
				delayStructInsts));
}

private immutable(Opt!(Diag.TypeShouldUseSyntax.Kind)) typeSyntaxKind(immutable Sym a) {
	switch (a.value) {
		case shortSymAlphaLiteralValue("arr"):
			return some(Diag.TypeShouldUseSyntax.Kind.arr);
		case shortSymAlphaLiteralValue("const-ptr"):
			return some(Diag.TypeShouldUseSyntax.Kind.ptr);
		case shortSymAlphaLiteralValue("dict"):
			return some(Diag.TypeShouldUseSyntax.Kind.dict);
		case shortSymAlphaLiteralValue("mut-arr"):
			return some(Diag.TypeShouldUseSyntax.Kind.arrMut);
		case shortSymAlphaLiteralValue("mut-dict"):
			return some(Diag.TypeShouldUseSyntax.Kind.dictMut);
		case shortSymAlphaLiteralValue("opt"):
			return some(Diag.TypeShouldUseSyntax.Kind.opt);
		case shortSymAlphaLiteralValue("mut-ptr"):
			return some(Diag.TypeShouldUseSyntax.Kind.ptrMut);
		default:
			return none!(Diag.TypeShouldUseSyntax.Kind);
	}
}

private immutable(Type) typeFromOptInst(immutable Opt!(Ptr!StructInst) a) {
	return has(a) ? immutable Type(force(a)) : immutable Type(Type.Bogus());
}

private immutable(Type) typeFromFunAst(
	ref Alloc alloc,
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
	immutable Opt!(Ptr!FunKindAndStructs) optF = findPtr!FunKindAndStructs(
		commonTypes.funKindsAndStructs,
		(immutable Ptr!FunKindAndStructs it) =>
			it.kind == funKind);
	immutable Ptr!FunKindAndStructs f = force(optF);
	if (size(ast.returnAndParamTypes) > size(f.structs))
		// We don't have a fun type big enough
		todo!void("!");
	immutable Ptr!StructDecl decl = at(f.structs, size(ast.returnAndParamTypes) - 1);
	immutable Type[] typeArgs = map!Type(alloc, ast.returnAndParamTypes, (ref immutable TypeAst it) =>
		typeFromAst(alloc, ctx, commonTypes, it, structsAndAliasesDict, typeParamsScope, delayStructInsts));
	return immutable Type(instantiateStruct(
		alloc,
		ctx.programState,
		immutable StructDeclAndArgs(decl, typeArgs),
		delayStructInsts));
}

immutable(Opt!(Ptr!SpecDecl)) tryFindSpec(
	ref Alloc alloc,
	ref CheckCtx ctx,
	immutable Sym name,
	immutable RangeWithinFile range,
	ref immutable SpecsDict specsDict,
) {
	immutable Opt!SpecDeclAndIndex opDeclFromHere = getAt(specsDict, name);
	if (has(opDeclFromHere))
		markUsedSpec(ctx, force(opDeclFromHere).index);
	immutable Opt!(Ptr!SpecDecl) here = mapOption(opDeclFromHere, (ref immutable SpecDeclAndIndex it) =>
		it.decl);
	return tryFindT!(Ptr!SpecDecl)(
		alloc,
		ctx,
		name,
		range,
		here,
		Diag.DuplicateImports.Kind.spec,
		Diag.NameNotFound.Kind.spec,
		(ref immutable NameReferents nr) =>
			nr.spec);
}

immutable(Type[]) typeArgsFromAsts(
	ref Alloc alloc,
	ref CheckCtx ctx,
	ref immutable CommonTypes commonTypes,
	scope immutable TypeAst[] typeAsts,
	ref immutable StructsAndAliasesDict structsAndAliasesDict,
	immutable TypeParamsScope typeParamsScope,
	DelayStructInsts delayStructInsts,
) {
	return map!Type(alloc, typeAsts, (ref immutable TypeAst it) =>
		typeFromAst(alloc, ctx, commonTypes, it, structsAndAliasesDict, typeParamsScope, delayStructInsts));
}

immutable(Type) makeFutType(
	ref Alloc alloc,
	ref ProgramState programState,
	ref immutable CommonTypes commonTypes,
	immutable Type type,
) {
	return immutable Type(instantiateStructNeverDelay(
		alloc,
		programState,
		immutable StructDeclAndArgs(commonTypes.fut, arrLiteral!Type(alloc, [type]))));
}

private:

immutable(Opt!TDecl) tryFindT(TDecl)(
	ref Alloc alloc,
	ref CheckCtx ctx,
	immutable Sym name,
	immutable RangeWithinFile range,
	ref immutable Opt!TDecl fromThisModule,
	immutable Diag.DuplicateImports.Kind duplicateImportKind,
	immutable Diag.NameNotFound.Kind nameNotFoundKind,
	scope immutable(Opt!TDecl) delegate(ref immutable NameReferents) @safe @nogc pure nothrow getFromNameReferents,
) {
	alias DAndM = DeclAndModule!TDecl;

	immutable Opt!DAndM res = eachImportAndReExport!(Opt!DAndM)(
		ctx,
		name,
		has(fromThisModule) ? some(immutable DAndM(force(fromThisModule), none!(Ptr!Module))) : none!DAndM,
		(
			immutable Opt!DAndM acc,
			immutable Ptr!Module module_,
			immutable ImportIndex index,
			ref immutable NameReferents referents,
		) {
			immutable Opt!TDecl got = getFromNameReferents(referents);
			if (has(got)) {
				markUsedImport(ctx, index);
				if (has(acc))
					// TODO: include both modules in the diag
					addDiag(alloc, ctx, range, immutable Diag(
						immutable Diag.DuplicateImports(duplicateImportKind, name)));
				return some(immutable DAndM(force(got), some(module_)));
			} else
				return acc;
		});
	if (has(res))
		return some!TDecl(force(res).decl);
	else {
		addDiag(alloc, ctx, range, immutable Diag(immutable Diag.NameNotFound(nameNotFoundKind, name)));
		return none!TDecl;
	}
}

struct DeclAndModule(TDecl) {
	immutable(TDecl) decl;
	// none for the current module (which isn't created yet)
	immutable Opt!(Ptr!Module) module_;
}
