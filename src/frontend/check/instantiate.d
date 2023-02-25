module frontend.check.instantiate;

@safe @nogc pure nothrow:

import frontend.lang : maxTypeParams;
import frontend.programState : ProgramState;
import model.model :
	body_,
	bodyIsSet,
	Called,
	CommonTypes,
	decl,
	Destructure,
	combineLinkageRange,
	combinePurityRange,
	FunDecl,
	FunDeclAndArgs,
	FunInst,
	Linkage,
	LinkageRange,
	linkageRange,
	paramsArray,
	Purity,
	PurityRange,
	purityRange,
	RecordField,
	ReturnAndParamTypes,
	SpecDecl,
	SpecDeclBody,
	SpecDeclAndArgs,
	SpecDeclSig,
	SpecInst,
	StructBody,
	StructDecl,
	StructDeclAndArgs,
	StructInst,
	Type,
	typeArgs,
	TypeParam,
	typeParams,
	UnionMember;
import util.alloc.alloc : Alloc;
import util.col.arr : emptySmallArray, sizeEq, small, SmallArray;
import util.col.arrUtil : copyArr, fold, map, mapWithFirst;
import util.col.mutDict : getOrAddPair, getOrAddPairAndDidAdd, KeyValuePair, PairAndDidAdd;
import util.col.mutArr : MutArr, push;
import util.col.mutMaxArr : mapTo, MutMaxArr, mutMaxArr, push, tempAsArr;
import util.memory : allocate;
import util.opt : force, has, MutOpt, none, noneMut, Opt, some, someMut;
import util.util : typeAs, verify;

immutable struct TypeParamsAndArgs {
	@safe @nogc pure nothrow:

	TypeParam[] typeParams;
	Type[] typeArgs;

	this(TypeParam[] tp, Type[] ta) {
		typeParams = tp;
		typeArgs = ta;
		verify(sizeEq(typeParams, typeArgs));
	}
}

alias TypeArgsArray = MutMaxArr!(maxTypeParams, Type);
TypeArgsArray typeArgsArray() =>
	mutMaxArr!(maxTypeParams, Type);

private Opt!(T*) tryGetTypeArg(T)(TypeParam[] typeParams, return scope immutable T[] typeArgs, TypeParam* typeParam) {
	size_t index = typeParam.index;
	bool hasTypeParam = index < typeParams.length && &typeParams[index] == typeParam;
	return hasTypeParam ? some(&typeArgs[index]) : none!(T*);
}
MutOpt!(T*) tryGetTypeArg_mut(T)(TypeParam[] typeParams, return scope T[] typeArgs, TypeParam* typeParam) {
	size_t index = typeParam.index;
	bool hasTypeParam = index < typeParams.length && &typeParams[index] == typeParam;
	return hasTypeParam ? someMut!(T*)(&typeArgs[index]) : noneMut!(T*);
}

private Opt!Type tryGetTypeArgFromTypeParamsAndArgs(TypeParamsAndArgs typeParamsAndArgs, TypeParam* typeParam) {
	Opt!(Type*) t = tryGetTypeArg!Type(typeParamsAndArgs.typeParams, typeParamsAndArgs.typeArgs, typeParam);
	return has(t) ? some(*force(t)) : none!Type;
}

alias DelaySpecInsts = MutOpt!(MutArr!(SpecInst*)*); // delayed due to 'parents' referencing other specs
DelaySpecInsts noDelaySpecInsts() =>
	noneMut!(MutArr!(SpecInst*)*);
alias DelayStructInsts = MutOpt!(MutArr!(StructInst*)*);
DelayStructInsts noDelayStructInsts() =>
	noneMut!(MutArr!(StructInst*)*);

private Type instantiateType(
	ref Alloc alloc,
	ref ProgramState programState,
	Type type,
	in TypeParamsAndArgs typeParamsAndArgs,
	scope DelayStructInsts delayStructInsts,
) =>
	type.matchWithPointers!Type(
		(Type.Bogus _) =>
			Type(Type.Bogus()),
		(TypeParam* p) {
			Opt!Type op = tryGetTypeArgFromTypeParamsAndArgs(typeParamsAndArgs, p);
			return has(op) ? force(op) : type;
		},
		(StructInst* i) =>
			Type(instantiateStructInst(alloc, programState, *i, typeParamsAndArgs, delayStructInsts)));

private Type instantiateTypeNoDelay(
	ref Alloc alloc,
	ref ProgramState programState,
	Type type,
	TypeParamsAndArgs typeParamsAndArgs,
) =>
	instantiateType(alloc, programState, type, typeParamsAndArgs, noDelayStructInsts);

FunInst* instantiateFun(
	ref Alloc alloc,
	ref ProgramState programState,
	FunDecl* decl,
	in Type[] typeArgs,
	in Called[] specImpls,
) {
	FunDeclAndArgs tempKey = FunDeclAndArgs(decl, typeArgs, specImpls);
	return getOrAddPair(alloc, programState.funInsts, tempKey, () {
		FunDeclAndArgs key = FunDeclAndArgs(decl, copyArr(alloc, typeArgs), copyArr(alloc, specImpls));
		TypeParamsAndArgs typeParamsAndArgs = TypeParamsAndArgs(decl.typeParams, key.typeArgs);
		return KeyValuePair!(FunDeclAndArgs, FunInst*)(key, allocate(alloc, FunInst(
			key,
			instantiateReturnAndParamTypes(
				alloc, programState, decl.returnType, paramsArray(decl.params), typeParamsAndArgs))));
	}).value;
}

Type[] instantiateStructTypes(
	ref Alloc alloc,
	ref ProgramState programState,
	StructDeclAndArgs declAndArgs,
	scope DelayStructInsts delayStructInsts,
) {
	TypeParamsAndArgs typeParamsAndArgs = TypeParamsAndArgs(declAndArgs.decl.typeParams, declAndArgs.typeArgs);
	return body_(*declAndArgs.decl).match!(Type[])(
		(StructBody.Bogus) =>
			typeAs!(Type[])([]),
		(StructBody.Builtin) =>
			typeAs!(Type[])([]),
		(StructBody.Enum e) =>
			typeAs!(Type[])([]),
		(StructBody.Extern e) =>
			typeAs!(Type[])([]),
		(StructBody.Flags f) =>
			typeAs!(Type[])([]),
		(StructBody.Record r) =>
			map(alloc, r.fields, (ref RecordField f) =>
				instantiateType(alloc, programState, f.type, typeParamsAndArgs, delayStructInsts)),
		(StructBody.Union u) =>
			map(alloc, u.members, (ref UnionMember x) =>
				instantiateType(alloc, programState, x.type, typeParamsAndArgs, delayStructInsts)));
}

StructInst* instantiateStruct(
	ref Alloc alloc,
	ref ProgramState programState,
	StructDecl* decl,
	in Type[] typeArgs,
	scope DelayStructInsts delayStructInsts,
) {
	StructDeclAndArgs tempKey = StructDeclAndArgs(decl, typeArgs);
	PairAndDidAdd!(StructDeclAndArgs, StructInst*) res = getOrAddPairAndDidAdd(
		alloc,
		programState.structInsts,
		tempKey,
		() {
			StructDeclAndArgs key = StructDeclAndArgs(decl, copyArr(alloc, typeArgs));
			return KeyValuePair!(StructDeclAndArgs, StructInst*)(key, allocate(alloc, StructInst(
				key,
				combinedLinkageRange(decl.linkage, typeArgs),
				combinedPurityRange(decl.purity, typeArgs))));
		});

	if (res.didAdd) {
		if (bodyIsSet(*decl))
			res.value.instantiatedTypes = instantiateStructTypes(alloc, programState, res.key, delayStructInsts);
		else {
			// We should only need to do this in the initial phase of settings struct bodies,
			// which is when delayedStructInst is set.
			push!(StructInst*)(alloc, *force(delayStructInsts), res.value);
		}
	}

	return res.value;
}

private LinkageRange combinedLinkageRange(Linkage declLinkage, in Type[] typeArgs) {
	final switch (declLinkage) {
		case Linkage.internal:
			return LinkageRange(Linkage.internal, Linkage.internal);
		case Linkage.extern_:
			return fold!(LinkageRange, Type)(
				LinkageRange(Linkage.extern_, Linkage.extern_),
				typeArgs,
				(LinkageRange cur, in Type typeArg) => combineLinkageRange(cur, linkageRange(typeArg)));
	}
}

private PurityRange combinedPurityRange(Purity declPurity, in Type[] typeArgs) =>
	fold!(PurityRange, Type)(PurityRange(declPurity, declPurity), typeArgs, (PurityRange cur, in Type typeArg) =>
		combinePurityRange(cur, purityRange(typeArg)));

private StructInst* instantiateStructInst(
	ref Alloc alloc,
	ref ProgramState programState,
	ref StructInst structInst,
	in TypeParamsAndArgs typeParamsAndArgs,
	scope DelayStructInsts delayStructInsts,
) {
	scope TypeArgsArray itsTypeArgs = typeArgsArray();
	mapTo!(maxTypeParams, Type, Type)(itsTypeArgs, typeArgs(structInst), (ref Type x) =>
		instantiateType(alloc, programState, x, typeParamsAndArgs, delayStructInsts));
	return instantiateStruct(alloc, programState, decl(structInst), tempAsArr(itsTypeArgs), delayStructInsts);
}

StructInst* instantiateStructNeverDelay(
	ref Alloc alloc,
	ref ProgramState programState,
	StructDecl* decl,
	in Type[] typeArgs,
) =>
	instantiateStruct(alloc, programState, decl, typeArgs, noDelayStructInsts);

StructInst* makeArrayType(
	ref Alloc alloc,
	ref ProgramState programState,
	ref CommonTypes commonTypes,
	Type elementType,
) =>
	instantiateStructNeverDelay(alloc, programState, commonTypes.array, [elementType]);

SpecInst* instantiateSpec(
	ref Alloc alloc,
	ref ProgramState programState,
	SpecDecl* decl,
	in Type[] typeArgs,
	scope DelaySpecInsts delaySpecInsts,
) {
	SpecDeclAndArgs tempKey = SpecDeclAndArgs(decl, typeArgs);
	return getOrAddPair(alloc, programState.specInsts, tempKey, () {
		SpecDeclAndArgs key = SpecDeclAndArgs(decl, copyArr(alloc, typeArgs));
		TypeParamsAndArgs typeParamsAndArgs = TypeParamsAndArgs(decl.typeParams, key.typeArgs);
		SpecInst* res = allocate(alloc, SpecInst(key, decl.body_.match!(SmallArray!ReturnAndParamTypes)(
			(SpecDeclBody.Builtin b) =>
				emptySmallArray!ReturnAndParamTypes,
			(SpecDeclSig[] sigs) =>
				small(map(alloc, sigs, (ref SpecDeclSig sig) =>
					instantiateReturnAndParamTypes(
						alloc, programState, sig.returnType, sig.params, typeParamsAndArgs))))));
		if (decl.parentsIsSet)
			instantiateSpecParents(alloc, programState, res, delaySpecInsts);
		else
			push(alloc, *force(delaySpecInsts), res);
		return KeyValuePair!(SpecDeclAndArgs, SpecInst*)(key, res);
	}).value;
}

void instantiateSpecParents(
	ref Alloc alloc,
	ref ProgramState programState,
	SpecInst* a, 
	scope DelaySpecInsts delaySpecInsts,
) {
	TypeParamsAndArgs typeParamsAndArgs = TypeParamsAndArgs(decl(*a).typeParams, typeArgs(*a));
	a.parents = map!(immutable SpecInst*, immutable SpecInst*)(
		alloc, decl(*a).parents, (ref immutable SpecInst* parent) =>
			instantiateSpecInst(alloc, programState, parent, typeParamsAndArgs, delaySpecInsts));
}

SpecInst* instantiateSpecInst(
	ref Alloc alloc,
	ref ProgramState programState,
	SpecInst* specInst,
	in TypeParamsAndArgs typeParamsAndArgs,
	scope DelaySpecInsts delaySpecInsts,
) {
	TypeArgsArray itsTypeArgs = typeArgsArray();
	mapTo!(maxTypeParams, Type, Type)(itsTypeArgs, typeArgs(*specInst), (ref Type x) =>
		instantiateType(alloc, programState, x, typeParamsAndArgs, noDelayStructInsts));
	return instantiateSpec(alloc, programState, decl(*specInst), tempAsArr(itsTypeArgs), delaySpecInsts);
}

private:

ReturnAndParamTypes instantiateReturnAndParamTypes(
	ref Alloc alloc,
	ref ProgramState programState,
	Type declReturnType,
	Destructure[] declParams,
	TypeParamsAndArgs typeParamsAndArgs,
) =>
	ReturnAndParamTypes(small(mapWithFirst!(Type, Destructure)(
		alloc,
		instantiateTypeNoDelay(alloc, programState, declReturnType, typeParamsAndArgs),
		declParams,
		(size_t _, ref Destructure x) =>
			instantiateTypeNoDelay(alloc, programState, x.type, typeParamsAndArgs))));
