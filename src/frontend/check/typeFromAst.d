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
import frontend.parse.ast : matchTypeAst, TypeAst;
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
import util.collection.arr : at, size, toArr;
import util.collection.arrUtil : arrLiteral, fillArr, findPtr, map;
import util.collection.dict : getAt;
import util.opt : force, has, mapOption, none, Opt, some;
import util.ptr : Ptr;
import util.sourceRange : RangeWithinFile;
import util.sym : Sym, symEq;
import util.types : safeSizeTToU8;
import util.util : todo;

immutable(Opt!(Ptr!StructInst)) instStructFromAst(Alloc)(
	ref Alloc alloc,
	ref CheckCtx ctx,
	ref immutable CommonTypes commonTypes,
	ref immutable TypeAst.InstStruct ast,
	ref immutable StructsAndAliasesDict structsAndAliasesDict,
	immutable TypeParamsScope typeParamsScope,
	DelayStructInsts delayStructInsts,
) {
	immutable Sym name = ast.name.name;
	immutable Opt!StructOrAliasAndIndex opDeclFromHere = getAt(structsAndAliasesDict, name);
	if (has(opDeclFromHere))
		markUsedStructOrAlias(ctx, force(opDeclFromHere));
	immutable Opt!StructOrAlias here = mapOption(opDeclFromHere, (ref immutable StructOrAliasAndIndex it) =>
		it.structOrAlias);
	immutable Opt!StructOrAlias opDecl = tryFindT!(StructOrAlias, Alloc)(
		alloc,
		ctx,
		name,
		ast.range,
		here,
		Diag.DuplicateImports.Kind.type,
		Diag.NameNotFound.Kind.type,
		(ref immutable NameReferents nr) =>
			nr.structOrAlias);
	if (!has(opDecl))
		return none!(Ptr!StructInst);
	else {
		immutable StructOrAlias sOrA = force(opDecl);
		immutable size_t nExpectedTypeArgs = size(typeParams(sOrA));
		immutable TypeAst[] typeArgAsts = toArr(ast.typeArgs);
		immutable Type[] typeArgs = () {
			immutable size_t nActualTypeArgs = size(typeArgAsts);
			if (nActualTypeArgs != nExpectedTypeArgs) {
				addDiag(alloc, ctx, ast.range, immutable Diag(
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
		}();

		return matchStructOrAlias!(immutable Opt!(Ptr!StructInst))(
			sOrA,
			(immutable Ptr!StructAlias a) =>
				nExpectedTypeArgs != 0
					? todo!(immutable Opt!(Ptr!StructInst))("alias with type params")
					: target(a),
			(immutable Ptr!StructDecl decl) {
				return some!(Ptr!StructInst)(instantiateStruct(
					alloc,
					ctx.programState,
					immutable StructDeclAndArgs(decl, typeArgs),
					delayStructInsts));
			});
	}
}

immutable(Type) typeFromAst(Alloc)(
	ref Alloc alloc,
	ref CheckCtx ctx,
	ref immutable CommonTypes commonTypes,
	ref immutable TypeAst ast,
	ref immutable StructsAndAliasesDict structsAndAliasesDict,
	immutable TypeParamsScope typeParamsScope,
	DelayStructInsts delayStructInsts,
) {
	return matchTypeAst!(immutable Type)(
		ast,
		(ref immutable TypeAst.Fun it) =>
			typeFromFunAst(alloc, ctx, commonTypes, it, structsAndAliasesDict, typeParamsScope, delayStructInsts),
		(ref immutable TypeAst.InstStruct iAst) {
			immutable Opt!(Ptr!StructInst) i = instStructFromAst(
				alloc,
				ctx,
				commonTypes,
				iAst,
				structsAndAliasesDict,
				typeParamsScope,
				delayStructInsts);
			return has(i) ? immutable Type(force(i)) : immutable Type(Type.Bogus());
		},
		(ref immutable TypeAst.TypeParam p) {
			immutable Opt!(Ptr!TypeParam) found =
				findPtr!TypeParam(typeParamsScope.innerTypeParams, (immutable Ptr!TypeParam it) =>
					symEq(it.name, p.name));
			if (has(found))
				return immutable Type(force(found));
			else {
				addDiag(alloc, ctx, p.range, immutable Diag(
					Diag.NameNotFound(Diag.NameNotFound.Kind.typeParam, p.name)));
				return immutable Type(Type.Bogus());
			}
		});
}

private immutable(Type) typeFromFunAst(Alloc)(
	ref Alloc alloc,
	ref CheckCtx ctx,
	ref immutable CommonTypes commonTypes,
	ref immutable TypeAst.Fun ast,
	ref immutable StructsAndAliasesDict structsAndAliasesDict,
	ref immutable TypeParamsScope typeParamsScope,
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

immutable(Opt!(Ptr!SpecDecl)) tryFindSpec(Alloc)(
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
	return tryFindT!(Ptr!SpecDecl, Alloc)(
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

immutable(Type[]) typeArgsFromAsts(Alloc)(
	ref Alloc alloc,
	ref CheckCtx ctx,
	ref immutable CommonTypes commonTypes,
	immutable TypeAst[] typeAsts,
	ref immutable StructsAndAliasesDict structsAndAliasesDict,
	ref immutable TypeParamsScope typeParamsScope,
	DelayStructInsts delayStructInsts,
) {
	return map!Type(alloc, typeAsts, (ref immutable TypeAst it) =>
		typeFromAst(alloc, ctx, commonTypes, it, structsAndAliasesDict, typeParamsScope, delayStructInsts));
}

immutable(Type) makeFutType(Alloc)(
	ref Alloc alloc,
	ref ProgramState programState,
	ref immutable CommonTypes commonTypes,
	ref immutable Type type,
) {
	return immutable Type(instantiateStructNeverDelay(
		alloc,
		programState,
		immutable StructDeclAndArgs(commonTypes.fut, arrLiteral!Type(alloc, [type]))));
}

private:

immutable(Opt!TDecl) tryFindT(TDecl, Alloc)(
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
