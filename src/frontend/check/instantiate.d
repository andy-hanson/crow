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
	combineLinkageRange,
	combinePurityRange,
	FunDecl,
	FunDeclAndArgs,
	FunInst,
	Linkage,
	LinkageRange,
	linkageRange,
	matchParams,
	matchSpecBody,
	matchStructBody,
	matchType,
	Param,
	Params,
	Purity,
	PurityRange,
	purityRange,
	RecordField,
	setBody,
	SpecBody,
	SpecDecl,
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
	UnionMember,
	withType;
import util.alloc.alloc : Alloc;
import util.col.arr : sizeEq;
import util.col.arrUtil : copyArr, fold, map;
import util.col.mutDict : getOrAddPair, getOrAddPairAndDidAdd, KeyValuePair, PairAndDidAdd;
import util.col.mutArr : MutArr, push;
import util.col.mutMaxArr : mapTo, MutMaxArr, mutMaxArr, push, tempAsArr;
import util.memory : allocate, allocateMut;
import util.opt : force, has, none, noneInout, noneMut, Opt, some;
import util.ptr : castImmutable;
import util.util : verify;

struct TypeParamsScope {
	// TODO: consistent naming
	immutable TypeParam[] innerTypeParams;
}

struct TypeParamsAndArgs {
	@safe @nogc pure nothrow:

	immutable TypeParam[] typeParams;
	immutable Type[] typeArgs;

	immutable this(immutable TypeParam[] tp, immutable Type[] ta) {
		typeParams = tp;
		typeArgs = ta;
		verify(sizeEq(typeParams, typeArgs));
	}
}

alias TypeArgsArray = MutMaxArr!(maxTypeParams, immutable Type);
TypeArgsArray typeArgsArray() =>
	mutMaxArr!(maxTypeParams, immutable Type);

inout(Opt!(T*)) tryGetTypeArg(T)(
	immutable TypeParam[] typeParams,
	return scope inout T[] typeArgs,
	immutable TypeParam* typeParam,
) {
	immutable size_t index = typeParam.index;
	immutable bool hasTypeParam = index < typeParams.length && &typeParams[index] == typeParam;
	return hasTypeParam ? some(&typeArgs[index]) : noneInout!(T*)(typeArgs);
}

private immutable(Opt!Type) tryGetTypeArgFromTypeParamsAndArgs(
	immutable TypeParamsAndArgs typeParamsAndArgs,
	immutable TypeParam* typeParam,
) {
	immutable Opt!(Type*) t = tryGetTypeArg(typeParamsAndArgs.typeParams, typeParamsAndArgs.typeArgs, typeParam);
	return has(t) ? some(*force(t)) : none!Type;
}

alias DelayStructInsts = Opt!(MutArr!(StructInst*)*);

private immutable(Type) instantiateType(
	ref Alloc alloc,
	ref ProgramState programState,
	immutable Type type,
	immutable TypeParamsAndArgs typeParamsAndArgs,
	DelayStructInsts delayStructInsts,
) =>
	matchType!(immutable Type)(
		type,
		(immutable Type.Bogus) =>
			immutable Type(Type.Bogus()),
		(immutable TypeParam* p) {
			immutable Opt!Type op = tryGetTypeArgFromTypeParamsAndArgs(typeParamsAndArgs, p);
			return has(op) ? force(op) : type;
		},
		(immutable StructInst* i) =>
			immutable Type(instantiateStructInst(alloc, programState, i, typeParamsAndArgs, delayStructInsts)));

private immutable(Type) instantiateTypeNoDelay(
	ref Alloc alloc,
	ref ProgramState programState,
	immutable Type type,
	immutable TypeParamsAndArgs typeParamsAndArgs,
) =>
	instantiateType(alloc, programState, type, typeParamsAndArgs, noneMut!(MutArr!(StructInst*)*));

immutable(FunInst*) instantiateFun(
	ref Alloc alloc,
	ref ProgramState programState,
	immutable FunDecl* decl,
	scope immutable Type[] typeArgs,
	scope immutable Called[] specImpls,
) {
	scope immutable FunDeclAndArgs tempKey = immutable FunDeclAndArgs(decl, typeArgs, specImpls);
	return getOrAddPair(alloc, programState.funInsts, tempKey, () {
		immutable FunDeclAndArgs key =
			immutable FunDeclAndArgs(decl, copyArr(alloc, typeArgs), copyArr(alloc, specImpls));
		immutable TypeParamsAndArgs typeParamsAndArgs = immutable TypeParamsAndArgs(decl.typeParams, key.typeArgs);
		return KeyValuePair!(immutable FunDeclAndArgs, immutable FunInst*)(key, allocate(alloc, immutable FunInst(
			key,
			instantiateTypeNoDelay(alloc, programState, decl.returnType, typeParamsAndArgs),
			instantiateParams(alloc, programState, decl.params, typeParamsAndArgs))));
	}).value;
}

immutable(StructBody) instantiateStructBody(
	ref Alloc alloc,
	ref ProgramState programState,
	immutable StructDeclAndArgs declAndArgs,
	DelayStructInsts delayStructInsts,
) {
	immutable TypeParamsAndArgs typeParamsAndArgs =
		immutable TypeParamsAndArgs(declAndArgs.decl.typeParams, declAndArgs.typeArgs);
	return matchStructBody!(immutable StructBody)(
		body_(*declAndArgs.decl),
		(ref immutable StructBody.Bogus) =>
			immutable StructBody(immutable StructBody.Bogus()),
		(ref immutable StructBody.Builtin) =>
			immutable StructBody(immutable StructBody.Builtin()),
		(ref immutable StructBody.Enum e) =>
			immutable StructBody(e),
		(ref immutable StructBody.Flags f) =>
			immutable StructBody(f),
		(ref immutable StructBody.ExternPointer) =>
			immutable StructBody(immutable StructBody.ExternPointer()),
		(ref immutable StructBody.Record r) =>
			immutable StructBody(immutable StructBody.Record(
				r.flags,
				map(alloc, r.fields, (ref immutable RecordField f) =>
					withType(f, instantiateType(alloc, programState, f.type, typeParamsAndArgs, delayStructInsts))))),
		(ref immutable StructBody.Union u) =>
			immutable StructBody(immutable StructBody.Union(map(alloc, u.members, (ref immutable UnionMember it) =>
				has(it.type)
					? withType(
						it,
						instantiateType(alloc, programState, force(it.type), typeParamsAndArgs, delayStructInsts))
					: it))));
}

immutable(StructInst*) instantiateStruct(
	ref Alloc alloc,
	ref ProgramState programState,
	immutable StructDecl* decl,
	scope immutable Type[] typeArgs,
	DelayStructInsts delayStructInsts,
) {
	scope immutable StructDeclAndArgs tempKey = immutable StructDeclAndArgs(decl, typeArgs);
	PairAndDidAdd!(immutable StructDeclAndArgs, StructInst*) res = getOrAddPairAndDidAdd(
		alloc,
		programState.structInsts,
		tempKey,
		() {
			immutable Linkage declLinkage = decl.linkage;
			immutable LinkageRange linkageRange = () {
				final switch (declLinkage) {
					case Linkage.internal:
						return immutable LinkageRange(Linkage.internal, Linkage.internal);
					case Linkage.extern_:
						return fold(
							immutable LinkageRange(Linkage.extern_, Linkage.extern_),
							typeArgs,
							(immutable LinkageRange cur, ref immutable Type typeArg) =>
								combineLinkageRange(cur, linkageRange(typeArg)));
				}
			}();
			immutable Purity declPurity = decl.purity;
			immutable PurityRange purityRange = fold(
				immutable PurityRange(declPurity, declPurity),
				typeArgs,
				(immutable PurityRange cur, ref immutable Type typeArg) =>
					combinePurityRange(cur, purityRange(typeArg)));
			immutable StructDeclAndArgs key = immutable StructDeclAndArgs(decl, copyArr(alloc, typeArgs));
			return KeyValuePair!(immutable StructDeclAndArgs, StructInst*)(
				key,
				allocateMut(alloc, StructInst(key, linkageRange, purityRange)));
		});

	if (res.didAdd) {
		if (bodyIsSet(*decl))
			setBody(*res.value, instantiateStructBody(alloc, programState, res.key, delayStructInsts));
		else {
			// We should only need to do this in the initial phase of settings struct bodies,
			// which is when delayedStructInst is set.
			push!(StructInst*)(alloc, *force(delayStructInsts), res.value);
		}
	}

	return castImmutable(res.value);
}

private immutable(StructInst*) instantiateStructInst(
	ref Alloc alloc,
	ref ProgramState programState,
	immutable StructInst* structInst,
	immutable TypeParamsAndArgs typeParamsAndArgs,
	DelayStructInsts delayStructInsts,
) {
	scope TypeArgsArray itsTypeArgs = typeArgsArray();
	mapTo(itsTypeArgs, typeArgs(*structInst), (ref immutable Type x) =>
		instantiateType(alloc, programState, x, typeParamsAndArgs, delayStructInsts));
	return instantiateStruct(alloc, programState, decl(*structInst), tempAsArr(itsTypeArgs), delayStructInsts);
}

private immutable(StructInst*) instantiateStructInst(
	ref Alloc alloc,
	ref ProgramState programState,
	immutable StructInst* structInst,
	ref immutable StructInst contextStructInst,
) {
	immutable TypeParamsAndArgs ta = immutable TypeParamsAndArgs(
		contextStructInst.decl.typeParams,
		contextStructInst.typeArgs);
	return instantiateStructInst(alloc, programState, structInst, ta, noneMut!(MutArr!(StructInst*)*));
}

immutable(StructInst*) instantiateStructNeverDelay(
	ref Alloc alloc,
	ref ProgramState programState,
	immutable StructDecl* decl,
	scope immutable Type[] typeArgs,
) =>
	instantiateStruct(alloc, programState, decl, typeArgs, noneMut!(MutArr!(StructInst*)*));

immutable(StructInst*) makeNamedValType(
	ref Alloc alloc,
	ref ProgramState programState,
	ref immutable CommonTypes commonTypes,
	immutable Type valueType,
) =>
	instantiateStructNeverDelay(alloc, programState, commonTypes.namedVal, [valueType]);

immutable(StructInst*) makeArrayType(
	ref Alloc alloc,
	ref ProgramState programState,
	ref immutable CommonTypes commonTypes,
	immutable Type elementType,
) =>
	instantiateStructNeverDelay(alloc, programState, commonTypes.array, [elementType]);

immutable(SpecInst*) instantiateSpec(
	ref Alloc alloc,
	ref ProgramState programState,
	immutable SpecDecl* decl,
	scope immutable Type[] typeArgs,
) {
	immutable SpecDeclAndArgs tempKey = immutable SpecDeclAndArgs(decl, typeArgs);
	return getOrAddPair(alloc, programState.specInsts, tempKey, () {
		immutable SpecDeclAndArgs key = immutable SpecDeclAndArgs(decl, copyArr(alloc, typeArgs));
		immutable SpecBody body_ = matchSpecBody!(immutable SpecBody)(
			decl.body_,
			(immutable SpecBody.Builtin b) =>
				immutable SpecBody(SpecBody.Builtin(b.kind)),
			(immutable SpecDeclSig[] sigs) =>
				immutable SpecBody(map(alloc, sigs, (ref immutable SpecDeclSig sig) {
					immutable TypeParamsAndArgs typeParamsAndArgs =
						immutable TypeParamsAndArgs(decl.typeParams, key.typeArgs);
					return immutable SpecDeclSig(
						sig.docComment,
						sig.fileAndPos,
						sig.name,
						instantiateTypeNoDelay(alloc, programState, sig.returnType, typeParamsAndArgs),
						instantiateParams(alloc, programState, sig.params, typeParamsAndArgs));
		 		})));
		return KeyValuePair!(immutable SpecDeclAndArgs, immutable SpecInst*)(
			key, allocate(alloc, immutable SpecInst(key, body_)));
	}).value;
}

immutable(SpecInst*) instantiateSpecInst(
	ref Alloc alloc,
	ref ProgramState programState,
	immutable SpecInst* specInst,
	immutable TypeParamsAndArgs typeParamsAndArgs,
) {
	TypeArgsArray itsTypeArgs = typeArgsArray();
	mapTo(itsTypeArgs, typeArgs(*specInst), (ref immutable Type x) =>
		instantiateType(alloc, programState, x, typeParamsAndArgs, noneMut!(MutArr!(StructInst*)*)));
	return instantiateSpec(alloc, programState, decl(*specInst), tempAsArr(itsTypeArgs));
}

private:

immutable(Params) instantiateParams(
	ref Alloc alloc,
	ref ProgramState programState,
	ref immutable Params params,
	immutable TypeParamsAndArgs typeParamsAndArgs,
) =>
	matchParams!(immutable Params)(
		params,
		(immutable Param[] paramsArray) =>
			immutable Params(map(alloc, paramsArray, (ref immutable Param p) =>
				instantiateParam(alloc, programState, typeParamsAndArgs, p))),
		(ref immutable Params.Varargs v) =>
			immutable Params(allocate(alloc, immutable Params.Varargs(
				instantiateParam(alloc, programState, typeParamsAndArgs, v.param),
				instantiateTypeNoDelay(alloc, programState, v.elementType, typeParamsAndArgs)))));

immutable(Param) instantiateParam(
	ref Alloc alloc,
	ref ProgramState programState,
	immutable TypeParamsAndArgs typeParamsAndArgs,
	ref immutable Param a,
) =>
	withType(a, instantiateTypeNoDelay(alloc, programState, a.type, typeParamsAndArgs));
