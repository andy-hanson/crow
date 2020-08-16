module frontend.typeFromAst;

@safe @nogc pure nothrow:

import diag : Diag;
import frontend.ast : matchTypeAst, TypeAst;
import frontend.checkCtx : addDiag, CheckCtx;
import frontend.instantiate : DelayStructInsts, instantiateStruct, TypeParamsScope;
import model :
	CommonTypes,
	matchStructOrAlias,
	Module,
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
import util.collection.arr : Arr, empty, first, size;
import util.collection.arrUtil : fillArr, findPtr, map, tail;
import util.collection.dict : Dict, getAt;
import util.opt : force, has, none, Opt, some;
import util.ptr : Ptr;
import util.sourceRange : SourceRange;
import util.sym : compareSym, Sym, symEq;
import util.util : todo;

import core.stdc.stdio : printf; // TODO:KILL

immutable(Opt!(Ptr!StructInst)) instStructFromAst(Alloc)(
	ref Alloc alloc,
	ref CheckCtx ctx,
	ref immutable TypeAst.InstStruct ast,
	ref immutable StructsAndAliasesMap structsAndAliasesMap,
	immutable TypeParamsScope typeParamsScope,
	DelayStructInsts delayStructInsts,
) {
	debug { printf("  instStructFromAst has delayStructInsts? %d\n", has(delayStructInsts).value); }

	immutable Opt!StructOrAlias opDecl = tryFindT!(StructOrAlias, Alloc)(
		alloc,
		ctx,
		ast.name,
		ast.range,
		structsAndAliasesMap,
		Diag.DuplicateImports.Kind.structOrAlias,
		Diag.NameNotFound.Kind.struct_,
		(immutable Ptr!Module m) => m.structsAndAliasesMap);
	if (!has(opDecl))
		return none!(Ptr!StructInst);
	else {
		immutable StructOrAlias sOrA = force(opDecl);
		immutable size_t nExpectedTypeArgs = size(typeParams(sOrA));
		immutable Arr!Type typeArgs = () {
			immutable size_t nActualTypeArgs = size(ast.typeArgs);
			if (nActualTypeArgs != nExpectedTypeArgs) {
				addDiag(alloc, ctx, ast.range, immutable Diag(
					Diag.WrongNumberTypeArgsForStruct(sOrA, nExpectedTypeArgs, nActualTypeArgs)));
				return fillArr!Type(alloc, nExpectedTypeArgs, (immutable size_t) => immutable Type(Type.Bogus()));
			} else
				return typeArgsFromAsts(alloc, ctx, ast.typeArgs, structsAndAliasesMap, typeParamsScope, delayStructInsts);
		}();

		return matchStructOrAlias!(immutable Opt!(Ptr!StructInst))(
			sOrA,
			(immutable Ptr!StructAlias a) =>
				nExpectedTypeArgs != 0
					? todo!(immutable Opt!(Ptr!StructInst))("alias with type params")
					: target(a),
			(immutable Ptr!StructDecl decl) {
				assert(size(decl.typeParams) < 10); //TODO:KILL
				return some!(Ptr!StructInst)(
					instantiateStruct(alloc, ctx.programState, immutable StructDeclAndArgs(decl, typeArgs), delayStructInsts));
			});
	}
}

immutable(Opt!(Ptr!StructInst)) instStructFromAstNeverDelay(Alloc)(
	ref Alloc alloc,
	ref CheckCtx ctx,
	ref immutable TypeAst.InstStruct ast,
	ref immutable StructsAndAliasesMap structsAndAliasesMap,
	ref immutable TypeParamsScope typeParamsScope,
) {
	return instStructFromAst(alloc, ctx, ast, structsAndAliasesMap, typeParamsScope, none!(MutArr!(Ptr!StructInst)));
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
			immutable Opt!(Ptr!TypeParam) found = findPtr(typeParamsScope.innerTypeParams, (immutable Ptr!TypeParam it) =>
				symEq(it.name, p.name));
			if (has(found))
				return immutable Type(force(found));
			else {
				addDiag(alloc, ctx, p.range, immutable Diag(Diag.NameNotFound(Diag.NameNotFound.Kind.typeParam, p.name)));
				return immutable Type(Type.Bogus());
			}
		},
		(ref immutable TypeAst.InstStruct iAst) {
			immutable Opt!(Ptr!StructInst) i =
				instStructFromAst(alloc, ctx, iAst, structsAndAliasesMap, typeParamsScope, delayStructInsts);
			return has(i) ? immutable Type(force(i)) : immutable Type(Type.Bogus());
		});
}

immutable(Opt!(Ptr!SpecDecl)) tryFindSpec(
	ref CheckCtx ctx,
	immutable Sym name,
	immutable SourceRange range,
	ref immutable SpecsMap specsMap,
) {
	return todo!(Opt!(Ptr!SpecDecl))("tryFindSpec");
}

immutable(Arr!Type) typeArgsFromAsts(Alloc)(
	ref Alloc alloc,
	ref CheckCtx ctx,
	ref immutable Arr!TypeAst typeAsts,
	ref immutable StructsAndAliasesMap structsAndAliasesMap,
	ref immutable TypeParamsScope typeParamsScope,
	DelayStructInsts delayStructInsts,
) {
	return map!Type(alloc, typeAsts, (ref immutable TypeAst it) =>
		typeFromAst(alloc, ctx, it, structsAndAliasesMap, typeParamsScope, delayStructInsts));
}

immutable(Type) makeFutType(Alloc)(
	ref Alloc alloc,
	ref immutable CommonTypes commonTypes,
	ref immutable Type type,
) {
	return todo!Type("makeFutType");
}

private:

immutable(Opt!(Ptr!T)) findInEither(T)(
	ref immutable Arr!T a,
	ref immutable Arr!T b,
	scope immutable(Bool) delegate(ref immutable T) @safe @nogc pure nothrow cb,
) {
	foreach (immutable size_t i; 0..size(a))
		if (cb(at(a, i)))
			return some(ptrAt(a, i));
	foreach (immutable size_t i; 0..size(b))
		if (cb(at(b, i)))
			return some(ptrAt(b, i));
	return none!(Ptr!T);
}

struct DeclAndModule(TDecl) {
	immutable(TDecl) decl;
	// none for the current module (which isn't created yet)
	immutable Opt!(Ptr!Module) module_;
}

immutable(Opt!TDecl) tryFindT(TDecl, Alloc)(
	ref Alloc alloc,
	ref CheckCtx ctx,
	immutable Sym name,
	immutable SourceRange range,
	immutable Dict!(Sym, TDecl, compareSym) dict,
	immutable Diag.DuplicateImports.Kind duplicateImportKind,
	immutable Diag.NameNotFound.Kind nameNotFoundKind,
	scope immutable(Dict!(Sym, TDecl, compareSym)) delegate(immutable Ptr!Module) @safe @nogc pure nothrow getTMap,
) {
	alias DAndM = DeclAndModule!TDecl;

	immutable(Opt!TDecl) recur(immutable Opt!DAndM res, immutable Arr!(Ptr!Module) modules) {
		if (empty(modules)) {
			if (has(res))
				return some!TDecl(force(res).decl);
			else {
				addDiag(alloc, ctx, range, immutable Diag(Diag.NameNotFound(nameNotFoundKind, name)));
				return none!TDecl;
			}
		} else {
			immutable Ptr!Module m = first(modules);
			immutable Opt!TDecl fromModule = getAt!(Sym, TDecl, compareSym)(getTMap(m), name);
			if (has(fromModule)) {
				if (has(res)) {
					immutable DAndM already = force(res);
					//TODO: include both modules in the diag
					addDiag(alloc, ctx, range, immutable Diag(Diag.DuplicateImports(duplicateImportKind, name)));
					return none!TDecl;
				} else
					return recur(some(immutable DAndM(force(fromModule), some(m))), tail(modules));
			} else
				return recur(res, tail(modules));
		}
	}

	immutable Opt!TDecl here = getAt(dict, name);
	return recur(
		has(here) ? some(immutable DAndM(force(here), none!(Ptr!Module))) : none!DAndM,
		ctx.allFlattenedImports);
}
