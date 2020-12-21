module frontend.check.typeFromAst;

@safe @nogc pure nothrow:

import frontend.check.checkCtx : addDiag, CheckCtx, eachImportAndReExport, ImportIndex, markImportUsed;
import frontend.check.dicts : SpecsDict, StructsAndAliasesDict;
import frontend.check.instantiate : DelayStructInsts, instantiateStruct, instantiateStructNeverDelay, TypeParamsScope;
import frontend.parse.ast : matchTypeAst, TypeAst;
import frontend.programState : ProgramState;
import model.diag : Diag;
import model.model :
	CommonTypes,
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
import util.collection.arr : Arr, range, size, toArr;
import util.collection.arrUtil : arrLiteral, fillArr, findPtr, map;
import util.collection.dict : Dict, getAt;
import util.opt : force, has, none, Opt, some;
import util.ptr : Ptr;
import util.sourceRange : RangeWithinFile;
import util.sym : compareSym, Sym, symEq;
import util.types : safeSizeTToU8;
import util.util : todo;

immutable(Opt!(Ptr!StructInst)) instStructFromAst(Alloc)(
	ref Alloc alloc,
	ref CheckCtx ctx,
	ref immutable TypeAst.InstStruct ast,
	ref immutable StructsAndAliasesDict structsAndAliasesDict,
	immutable TypeParamsScope typeParamsScope,
	DelayStructInsts delayStructInsts,
) {
	immutable Opt!StructOrAlias opDecl = tryFindT!(StructOrAlias, Alloc)(
		alloc,
		ctx,
		ast.name.name,
		ast.range,
		structsAndAliasesDict,
		Diag.DuplicateImports.Kind.type,
		Diag.NameNotFound.Kind.type,
		(ref immutable NameReferents nr) =>
			nr.structOrAlias);
	if (!has(opDecl))
		return none!(Ptr!StructInst);
	else {
		immutable StructOrAlias sOrA = force(opDecl);
		immutable size_t nExpectedTypeArgs = size(typeParams(sOrA));
		immutable Arr!TypeAst typeArgAsts = toArr(ast.typeArgs);
		immutable Arr!Type typeArgs = () {
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
	ref immutable TypeAst ast,
	ref immutable StructsAndAliasesDict structsAndAliasesDict,
	immutable TypeParamsScope typeParamsScope,
	DelayStructInsts delayStructInsts,
) {
	return matchTypeAst(
		ast,
		(ref immutable TypeAst.TypeParam p) {
			immutable Opt!(Ptr!TypeParam) found =
				findPtr(typeParamsScope.innerTypeParams, (immutable Ptr!TypeParam it) =>
					symEq(it.name, p.name));
			if (has(found))
				return immutable Type(force(found));
			else {
				addDiag(alloc, ctx, p.range, immutable Diag(
					Diag.NameNotFound(Diag.NameNotFound.Kind.typeParam, p.name)));
				return immutable Type(Type.Bogus());
			}
		},
		(ref immutable TypeAst.InstStruct iAst) {
			immutable Opt!(Ptr!StructInst) i =
				instStructFromAst(alloc, ctx, iAst, structsAndAliasesDict, typeParamsScope, delayStructInsts);
			return has(i) ? immutable Type(force(i)) : immutable Type(Type.Bogus());
		});
}

immutable(Opt!(Ptr!SpecDecl)) tryFindSpec(Alloc)(
	ref Alloc alloc,
	ref CheckCtx ctx,
	immutable Sym name,
	immutable RangeWithinFile range,
	ref immutable SpecsDict specsDict,
) {
	return tryFindT!(Ptr!SpecDecl, Alloc)(
		alloc,
		ctx,
		name,
		range,
		specsDict,
		Diag.DuplicateImports.Kind.spec,
		Diag.NameNotFound.Kind.spec,
		(ref immutable NameReferents nr) =>
			nr.spec);
}

immutable(Arr!Type) typeArgsFromAsts(Alloc)(
	ref Alloc alloc,
	ref CheckCtx ctx,
	immutable Arr!TypeAst typeAsts,
	ref immutable StructsAndAliasesDict structsAndAliasesDict,
	ref immutable TypeParamsScope typeParamsScope,
	DelayStructInsts delayStructInsts,
) {
	return map!Type(alloc, typeAsts, (ref immutable TypeAst it) =>
		typeFromAst(alloc, ctx, it, structsAndAliasesDict, typeParamsScope, delayStructInsts));
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

struct DeclAndModule(TDecl) {
	immutable(TDecl) decl;
	// none for the current module (which isn't created yet)
	immutable Opt!(Ptr!Module) module_;
}

immutable(Opt!TDecl) tryFindT(TDecl, Alloc)(
	ref Alloc alloc,
	ref CheckCtx ctx,
	immutable Sym name,
	immutable RangeWithinFile range,
	immutable Dict!(Sym, TDecl, compareSym) dict,
	immutable Diag.DuplicateImports.Kind duplicateImportKind,
	immutable Diag.NameNotFound.Kind nameNotFoundKind,
	scope immutable(Opt!TDecl) delegate(ref immutable NameReferents) @safe @nogc pure nothrow getFromNameReferents,
) {
	alias DAndM = DeclAndModule!TDecl;

	immutable Opt!TDecl here = getAt(dict, name);
	immutable Opt!DAndM res = eachImportAndReExport!(Opt!DAndM)(
		ctx,
		name,
		has(here) ? some(immutable DAndM(force(here), none!(Ptr!Module))) : none!DAndM,
		(
			immutable Opt!DAndM acc,
			immutable Ptr!Module module_,
			immutable ImportIndex index,
			ref immutable NameReferents referents,
		) {
			immutable Opt!TDecl got = getFromNameReferents(referents);
			if (has(got)) {
				markImportUsed(ctx, index);
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

