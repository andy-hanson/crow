module frontend.typeFromAst;

@safe @nogc pure nothrow:

import frontend.ast : matchTypeAst, TypeAst;
import frontend.checkCtx : addDiag, CheckCtx;
import frontend.instantiate : DelayStructInsts, instantiateStruct, instantiateStructNeverDelay, TypeParamsScope;
import frontend.programState : ProgramState;
import model.diag : Diag;
import model.model :
	CommonTypes,
	matchStructOrAlias,
	Module,
	ModuleAndNameReferents,
	NameAndReferents,
	SpecDecl,
	SpecsMap,
	StructAlias,
	StructDecl,
	StructDeclAndArgs,
	StructInst,
	StructOrAlias,
	StructsAndAliasesMap,
	target,
	Type,
	TypeParam,
	typeParams;
import util.collection.arr : Arr, empty, first, range, size, toArr;
import util.collection.arrUtil : arrLiteral, fillArr, findPtr, map, tail;
import util.collection.dict : Dict, getAt;
import util.opt : force, has, none, Opt, some;
import util.ptr : Ptr;
import util.sourceRange : RangeWithinFile;
import util.sym : compareSym, Sym, symEq;
import util.util : todo;

immutable(Opt!(Ptr!StructInst)) instStructFromAst(Alloc)(
	ref Alloc alloc,
	ref CheckCtx ctx,
	ref immutable TypeAst.InstStruct ast,
	ref immutable StructsAndAliasesMap structsAndAliasesMap,
	immutable TypeParamsScope typeParamsScope,
	DelayStructInsts delayStructInsts,
) {
	immutable Opt!StructOrAlias opDecl = tryFindT!(StructOrAlias, Alloc)(
		alloc,
		ctx,
		ast.name.name,
		ast.range,
		structsAndAliasesMap,
		Diag.DuplicateImports.Kind.type,
		Diag.NameNotFound.Kind.type,
		(immutable Ptr!Module m) =>
			m.structsAndAliasesMap,
		(ref immutable NameAndReferents nr) =>
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
					Diag.WrongNumberTypeArgsForStruct(sOrA, nExpectedTypeArgs, nActualTypeArgs)));
				return fillArr!Type(alloc, nExpectedTypeArgs, (immutable size_t) => immutable Type(Type.Bogus()));
			} else
				return typeArgsFromAsts(
					alloc,
					ctx,
					typeArgAsts,
					structsAndAliasesMap,
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
	ref immutable StructsAndAliasesMap structsAndAliasesMap,
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
				instStructFromAst(alloc, ctx, iAst, structsAndAliasesMap, typeParamsScope, delayStructInsts);
			return has(i) ? immutable Type(force(i)) : immutable Type(Type.Bogus());
		});
}

immutable(Opt!(Ptr!SpecDecl)) tryFindSpec(Alloc)(
	ref Alloc alloc,
	ref CheckCtx ctx,
	immutable Sym name,
	immutable RangeWithinFile range,
	ref immutable SpecsMap specsMap,
) {
	return tryFindT(
		alloc,
		ctx,
		name,
		range,
		specsMap,
		Diag.DuplicateImports.Kind.spec,
		Diag.NameNotFound.Kind.spec,
		(immutable Ptr!Module m) =>
			m.specsMap,
		(ref immutable NameAndReferents nr) =>
			nr.spec);
}

immutable(Arr!Type) typeArgsFromAsts(Alloc)(
	ref Alloc alloc,
	ref CheckCtx ctx,
	immutable Arr!TypeAst typeAsts,
	ref immutable StructsAndAliasesMap structsAndAliasesMap,
	ref immutable TypeParamsScope typeParamsScope,
	DelayStructInsts delayStructInsts,
) {
	return map!Type(alloc, typeAsts, (ref immutable TypeAst it) =>
		typeFromAst(alloc, ctx, it, structsAndAliasesMap, typeParamsScope, delayStructInsts));
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
		immutable StructDeclAndArgs(commonTypes.fut, arrLiteral!Type(alloc, type))));
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
	scope immutable(Dict!(Sym, TDecl, compareSym)) delegate(immutable Ptr!Module) @safe @nogc pure nothrow getTMap,
	scope immutable(Opt!TDecl) delegate(ref immutable NameAndReferents) @safe @nogc pure nothrow getFromNameReferents,
) {
	alias DAndM = DeclAndModule!TDecl;

	immutable(Opt!TDecl) recur(immutable Opt!DAndM res, immutable Arr!ModuleAndNameReferents modules) {
		if (empty(modules)) {
			if (has(res))
				return some!TDecl(force(res).decl);
			else {
				addDiag(alloc, ctx, range, immutable Diag(Diag.NameNotFound(nameNotFoundKind, name)));
				return none!TDecl;
			}
		} else {
			immutable ModuleAndNameReferents m = first(modules);
			immutable Opt!TDecl fromModule = has(m.namesAndReferents)
				? getFromNames(force(m.namesAndReferents), name, getFromNameReferents)
				: getAt!(Sym, TDecl, compareSym)(getTMap(m.module_), name);
			if (has(fromModule)) {
				if (has(res)) {
					//TODO: include both modules in the diag
					addDiag(alloc, ctx, range, immutable Diag(Diag.DuplicateImports(duplicateImportKind, name)));
					return none!TDecl;
				} else
					return recur(some(immutable DAndM(force(fromModule), some(m.module_))), tail(modules));
			} else
				return recur(res, tail(modules));
		}
	}

	immutable Opt!TDecl here = getAt(dict, name);
	return recur(
		has(here) ? some(immutable DAndM(force(here), none!(Ptr!Module))) : none!DAndM,
		ctx.allFlattenedImports);
}

immutable(Opt!TDecl) getFromNames(TDecl)(
	ref immutable Arr!NameAndReferents names,
	immutable Sym name,
	scope immutable(Opt!TDecl) delegate(ref immutable NameAndReferents) @safe @nogc pure nothrow getFromNameReferents,
) {
	foreach (ref immutable NameAndReferents nr; range(names))
		if (symEq(nr.name, name))
			return getFromNameReferents(nr);
	return none!TDecl;
}
