module frontend.check.typeUtil;

@safe @nogc pure nothrow:

import frontend.check.instantiate : InstantiateCtx, instantiateStructNeverDelay;
import model.model : CommonTypes, FunKind, StructDecl, StructInst, Type;
import util.col.array : only2;
import util.col.enumMap : enumMapFindKey;
import util.opt : force, has, none, Opt, some;

immutable struct FunType {
	@safe @nogc pure nothrow:

	FunKind kind;
	StructInst* structInst;

	StructDecl* funStruct() =>
		structInst.decl;
	Type nonInstantiatedNonFutReturnType() =>
		only2(structInst.typeArgs)[0];
	Type nonInstantiatedParamType() =>
		only2(structInst.typeArgs)[1];
}

Opt!FunType getFunType(in CommonTypes commonTypes, Type a) {
	if (a.isA!(StructInst*)) {
		StructInst* structInst = a.as!(StructInst*);
		Opt!FunKind kind = enumMapFindKey!(FunKind, StructDecl*)(commonTypes.funStructs, (in StructDecl* x) =>
			x == structInst.decl);
		return has(kind)
			? some(FunType(force(kind), structInst))
			: none!FunType;
	} else
		return none!FunType;
}

Type nonInstantiatedReturnType(InstantiateCtx ctx, ref CommonTypes commonTypes, ref FunType funType) =>
	funType.kind == FunKind.far
		? makeFutType(ctx, commonTypes, funType.nonInstantiatedNonFutReturnType)
		: funType.nonInstantiatedNonFutReturnType;

private:

Type makeFutType(InstantiateCtx ctx, ref CommonTypes commonTypes, Type type) =>
	Type(instantiateStructNeverDelay(ctx, commonTypes.future, [type]));
