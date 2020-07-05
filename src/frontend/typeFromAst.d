module frontend.typeFromAst;

@safe @nogc pure nothrow:

import frontend.ast : TypeAst;
import frontend.checkCtx : CheckCtx;
import frontend.instantiate : DelayStructInsts, TypeParamsScope;
import model : SpecDecl, SpecsMap, StructInst, StructsAndAliasesMap, Type;
import util.collection.arr : Arr;
import util.opt : Opt;
import util.ptr : Ptr;
import util.sourceRange : SourceRange;
import util.sym : Sym;
import util.util : todo;

immutable(Opt!(Ptr!StructInst)) instStructFromAst(Alloc)(
	ref Alloc alloc,
	ref CheckCtx ctx,
	ref immutable TypeAst.InstStruct ast,
	ref immutable StructsAndAliasesMap structsAndAliasesMap,
	immutable TypeParamsScope typeParamsScope,
	DelayStructInsts delayStructInsts,
) {
	return todo!(Opt!(Ptr!StructInst))("inststructfromast");
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
	return todo!Type("typeFromAst");
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
	return todo!(Arr!Type)("typeArgsFromAsts");
}

immutable(Type) makeFutType(Alloc)(
	ref Alloc alloc,
	ref immutable CommonTypes commonTypes,
	ref immutable Type type,
) {
	return todo!Type("makeFutType");
}
