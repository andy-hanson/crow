module concretize.concretizeBuiltin;

@safe @nogc pure nothrow:

import concreteModel : BuiltinFunInfo, ConcreteFunBody, ConcreteType;
import concretize.builtinInfo : getBuiltinFunInfo;
import concretize.concretizeCtx : ConcretizeCtx, ConcreteFunSource, containingFunDecl, typeArgs;
import util.collection.arr : Arr, at, emptyArr, first, empty, only, ptrAt, size;

immutable(ConcreteFunBody) getBuiltinFunBody(Alloc)(
	ref Alloc alloc,
	ref ConcretizeCtx ctx,
	ref immutable ConcreteFunSource source,
) {
	immutable BuiltinFunInfo info = getBuiltinFunInfo(containingFunDecl(source).sig);
	immutable Arr!ConcreteType typeArgs = typeArgs(source);
	return immutable ConcreteFunBody(immutable ConcreteFunBody.Builtin(info, typeArgs));
}
