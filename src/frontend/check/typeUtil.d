module frontend.check.typeUtil;

@safe @nogc pure nothrow:

import frontend.check.instantiate : InstantiateCtx, instantiateStructNeverDelay;
import model.model : CommonTypes, FunKind, StructDecl, StructInst, Type;
import util.col.array : only2;
import util.col.enumMap : enumMapFindKey;
import util.opt : force, has, none, Opt, some;

immutable struct FunType {
	FunKind kind;
	StructInst* structInst;
	StructDecl* structDecl;
	Type nonInstantiatedNonFutReturnType;
	Type nonInstantiatedParamType;
}
Opt!FunType getFunType(in CommonTypes commonTypes, Type a) {
	if (a.isA!(StructInst*)) {
		StructInst* structInst = a.as!(StructInst*);
		StructDecl* structDecl = structInst.decl;
		Opt!FunKind kind = enumMapFindKey!(FunKind, StructDecl*)(commonTypes.funStructs, (in StructDecl* x) =>
			x == structDecl);
		if (has(kind)) {
			Type[2] typeArgs = only2(structInst.typeArgs);
			return some(FunType(force(kind), structInst, structDecl, typeArgs[0], typeArgs[1]));
		} else
			return none!FunType;
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
