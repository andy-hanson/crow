module frontend.instantiate;

import frontend.checkCtx : CheckCtx;
import model : SpecDecl, SpecInst, StructBody, StructDecl, StructInst, Type, TypeParam;

import util.bools : Bool;
import util.collection.arr : Arr, begin, ptrAt, sizeEq;
import util.collection.mutArr : MutArr;
import util.opt : force, has, none, Opt, some;
import util.ptr : Ptr, ptrEquals;
import util.util : todo;

struct TypeParamsScope {
	// TODO: consistent naming
	immutable Arr!TypeParam innerTypeParams;
}

struct TypeParamsAndArgs {
	immutable Arr!TypeParam typeParams;
	immutable Arr!Type typeArgs;

	invariant(sizeEq(typeParams, typeArgs));
}

immutable(Opt!(Ptr!T)) tryGetTypeArg(T)(
	ref immutable Arr!TypeParam typeParams,
	ref immutable Arr!T typeArgs,
	immutable Ptr!TypeParam typeParam,
) {
	immutable Bool hasTypeParam = ptrEquals(ptrAt(typeParams, typeParam.index), typeParam);
	return hasTypeParam
		? some(ptrAt(typeArgs, typeParam.index))
		: none!(Ptr!T);
}

immutable(Opt!Type) tryGetTypeArgFromTypeParamsAndArgs(
	ref immutable TypeParamsAndArgs typeParamsAndArgs,
	immutable Ptr!TypeParam typeParam,
) {
	immutable Opt!(Ptr!Type) t = tryGetTypeArg(typeParamsAndArgs.typeParams, typeParamsAndArgs.typeArgs, typeParam);
	return has(t)
		? some(force(t).deref)
		: none!Type;
}

alias DelayStructInsts = Opt!(Ptr!(MutArr!(Ptr!StructInst)));

immutable(Type) instantiateType(Alloc)(
	ref Alloc alloc,
	ref CheckCtx ctx,
	ref immutable Type type,
	ref immutable TypeParamsAndArgs typeParamsAndArgs,
) {
	return todo!(immutable Type)("instantiateType");
}

immutable(Type) instantiateType(Alloc)(
	ref Alloc alloc,
	ref immutable Type type,
	ref immutable StructInst structInst,
) {
	return instantiateType(alloc, type, TypeParamsAndArgs(structInst.decl.typeParams, structInst.typeArgs));
}

immutable(Ptr!FunInst) instantiateFun(Alloc)(
	ref Alloc alloc,
	ref CheckCtx ctx,
	immutable Ptr!FunDecl decl,
	ref immutable Arr!Type typeArgs,
	ref immutable Arr!Called specImpls,
) {
	return todo!(immutable Ptr!FunInst)("instantiateFun");
}

immutable(StructBody) instantiateStructBody(Alloc)(
	ref Alloc alloc,
	ref CheckCtx ctx,
	immutable Ptr!StructDecl decl,
	ref immutable Arr!Type typeArgs,
) {
	return todo!(immutable StructBody)("instantiateStructBody");
}

immutable(Ptr!StructInst) instantiateStruct(Alloc)(
	ref Alloc alloc,
	ref CheckCtx ctx,
	immutable Ptr!StructDecl decl,
	immutable Arr!Type typeArgs,
	DelayStructInsts delayStructInsts,
) {
	return todo!(immutable Ptr!StructInst)("instantiateStruct");
}

immutable(Ptr!StructInst) instantiateNonTemplateStruct(Alloc)(
	ref Alloc alloc,
	immutable Ptr!StructDecl decl,
) {
	return todo!(immutable Ptr!StructInst)("instantiateNonTemplateStruct");
}

immutable(Ptr!StructInst) instantiateStructInst(Alloc)(
	ref Alloc alloc,
	ref CheckCtx ctx,
	immutable Ptr!StructInst structInst,
	ref immutable TypeParamsAndArgs typeParamsAndArgs,
) {
	return todo!(immutable Ptr!StructInst)("instantiateStructInst");
}
immutable(Ptr!StructInst) instantiateStructInst(Alloc)(
	ref Alloc alloc,
	ref CheckCtx ctx,
	immutable Ptr!StructInst structInst,
	ref immutable StructInst contextStructInst,
) {
	return instantiateStructInst(
		alloc,
		ctx,
		structInst,
		TypeParamsAndArgs(contextStructInst.decl.typeParams, contextStructInst.typeArgs));
}

immutable(Ptr!StructInst) instantiateStructNeverDelay(Alloc)(
	ref Alloc alloc,
	ref CheckCtx ctx,
	immutable Ptr!StructDecl decl,
	immutable Arr!Type typeArgs,
) {
	return instantiateStruct(alloc, ctx, decl, typeArgs, none!(MutArr!(Ptr!StructInst)));
}

immutable(Ptr!SpecInst) instantiateSpec(Alloc)(
	ref Alloc alloc,
	ref CheckCtx ctx,
	immutable Ptr!SpecDecl decl,
	ref immutable Arr!Type typeArgs,
) {
	return todo!(immutable Ptr!SpecInst)("instantiateSpec");
}

immutable(Ptr!SpecInst) instantiateSpecInst(Alloc)(
	ref Alloc alloc,
	ref CheckCtx ctx,
	immutable Ptr!SpecInst specInst,
	ref immutable TypeParamsAndArgs typeParamsAndArgs,
) {
	return todo!(immutable Ptr!SpecInst)("instantiateSpecInst");
}
