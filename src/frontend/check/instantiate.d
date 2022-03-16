module frontend.check.instantiate;

@safe @nogc pure nothrow:

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
	Sig,
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
import util.col.arr : ptrAt, sizeEq;
import util.col.arrUtil : copyArr, fold, map;
import util.col.mutDict : getOrAddPair, getOrAddPairAndDidAdd, KeyValuePair, PairAndDidAdd;
import util.col.mutArr : MutArr, push;
import util.col.mutMaxArr : mapTo, MutMaxArr, mutMaxArr, push, tempAsArr;
import util.memory : allocate, allocateMut;
import util.opt : force, has, none, noneMut, Opt, some, someConst, someMut;
import util.ptr : castImmutable, Ptr, ptrEquals;
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

alias TypeArgsArray = MutMaxArr!(8, Type);
TypeArgsArray typeArgsArray() {
	return mutMaxArr!(8, Type);
}

private immutable(Opt!(Ptr!T)) tryGetTypeArg(T)(
	immutable TypeParam[] typeParams,
	immutable T[] typeArgs,
	immutable Ptr!TypeParam typeParam,
) {
	immutable size_t index = typeParam.deref().index;
	immutable bool hasTypeParam = ptrEquals(ptrAt(typeParams, index), typeParam);
	return hasTypeParam
		? some(ptrAt(typeArgs, index))
		: none!(Ptr!T);
}

const(Opt!(Ptr!T)) tryGetTypeArg_const(T)(
	immutable TypeParam[] typeParams,
	const T[] typeArgs,
	immutable Ptr!TypeParam typeParam,
) {
	immutable size_t index = typeParam.deref().index;
	return index < typeParams.length && ptrEquals(ptrAt(typeParams, index), typeParam)
		? someConst(ptrAt(typeArgs, index))
		: none!(Ptr!T);
}

Opt!(Ptr!T) tryGetTypeArg_mut(T)(
	immutable TypeParam[] typeParams,
	T[] typeArgs,
	immutable Ptr!TypeParam typeParam,
) {
	immutable size_t index = typeParam.deref().index;
	return index < typeParams.length && ptrEquals(ptrAt(typeParams, index), typeParam)
		? someMut(ptrAt(typeArgs, index))
		: noneMut!(Ptr!T);
}

private immutable(Opt!Type) tryGetTypeArgFromTypeParamsAndArgs(
	immutable TypeParamsAndArgs typeParamsAndArgs,
	immutable Ptr!TypeParam typeParam,
) {
	immutable Opt!(Ptr!Type) t = tryGetTypeArg(typeParamsAndArgs.typeParams, typeParamsAndArgs.typeArgs, typeParam);
	return has(t) ? some(force(t).deref) : none!Type;
}

alias DelayStructInsts = Opt!(Ptr!(MutArr!(Ptr!StructInst)));

private immutable(Type) instantiateType(
	ref Alloc alloc,
	ref ProgramState programState,
	immutable Type type,
	immutable TypeParamsAndArgs typeParamsAndArgs,
	DelayStructInsts delayStructInsts,
) {
	return matchType!(immutable Type)(
		type,
		(immutable Type.Bogus) =>
			immutable Type(Type.Bogus()),
		(immutable Ptr!TypeParam p) {
			immutable Opt!Type op = tryGetTypeArgFromTypeParamsAndArgs(typeParamsAndArgs, p);
			return has(op) ? force(op) : type;
		},
		(immutable Ptr!StructInst i) =>
			immutable Type(instantiateStructInst(alloc, programState, i, typeParamsAndArgs, delayStructInsts)));
}

private immutable(Type) instantiateTypeNoDelay(
	ref Alloc alloc,
	ref ProgramState programState,
	immutable Type type,
	immutable TypeParamsAndArgs typeParamsAndArgs,
) {
	return instantiateType(alloc, programState, type, typeParamsAndArgs, noneMut!(Ptr!(MutArr!(Ptr!StructInst))));
}

immutable(Ptr!FunInst) instantiateFun(
	ref Alloc alloc,
	ref ProgramState programState,
	immutable Ptr!FunDecl decl,
	scope immutable Type[] typeArgs,
	scope immutable Called[] specImpls,
) {
	scope immutable FunDeclAndArgs tempKey = immutable FunDeclAndArgs(decl, typeArgs, specImpls);
	return getOrAddPair(alloc, programState.funInsts, tempKey, () {
		immutable FunDeclAndArgs key =
			immutable FunDeclAndArgs(decl, copyArr(alloc, typeArgs), copyArr(alloc, specImpls));
		return KeyValuePair!(immutable FunDeclAndArgs, immutable Ptr!FunInst)(key, allocate(alloc, immutable FunInst(
			key,
			instantiateSig(
				alloc,
				programState,
				decl.deref().sig,
				immutable TypeParamsAndArgs(decl.deref().typeParams, key.typeArgs)))));
	}).value;
}

immutable(StructBody) instantiateStructBody(
	ref Alloc alloc,
	ref ProgramState programState,
	immutable StructDeclAndArgs declAndArgs,
	DelayStructInsts delayStructInsts,
) {
	immutable TypeParamsAndArgs typeParamsAndArgs =
		immutable TypeParamsAndArgs(declAndArgs.decl.deref().typeParams, declAndArgs.typeArgs);
	return matchStructBody!(immutable StructBody)(
		body_(declAndArgs.decl.deref()),
		(ref immutable StructBody.Bogus) =>
			immutable StructBody(immutable StructBody.Bogus()),
		(ref immutable StructBody.Builtin) =>
			immutable StructBody(immutable StructBody.Builtin()),
		(ref immutable StructBody.Enum e) =>
			immutable StructBody(e),
		(ref immutable StructBody.Flags f) =>
			immutable StructBody(f),
		(ref immutable StructBody.ExternPtr) =>
			immutable StructBody(immutable StructBody.ExternPtr()),
		(ref immutable StructBody.Record r) =>
			immutable StructBody(immutable StructBody.Record(
				r.flags,
				map!RecordField(alloc, r.fields, (ref immutable RecordField f) =>
					withType(f, instantiateType(alloc, programState, f.type, typeParamsAndArgs, delayStructInsts))))),
		(ref immutable StructBody.Union u) =>
			immutable StructBody(immutable StructBody.Union(
				map!UnionMember(alloc, u.members, (ref immutable UnionMember it) =>
					has(it.type)
						? withType(
							it,
							instantiateType(alloc, programState, force(it.type), typeParamsAndArgs, delayStructInsts))
						: it))));
}

immutable(Ptr!StructInst) instantiateStruct(
	ref Alloc alloc,
	ref ProgramState programState,
	immutable Ptr!StructDecl decl,
	scope immutable Type[] typeArgs,
	DelayStructInsts delayStructInsts,
) {
	scope immutable StructDeclAndArgs tempKey = immutable StructDeclAndArgs(decl, typeArgs);
	PairAndDidAdd!(immutable StructDeclAndArgs, Ptr!StructInst) res = getOrAddPairAndDidAdd(
		alloc,
		programState.structInsts,
		tempKey,
		() {
			immutable Linkage declLinkage = decl.deref().linkage;
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
			immutable Purity declPurity = decl.deref().purity;
			immutable PurityRange purityRange = fold(
				immutable PurityRange(declPurity, declPurity),
				typeArgs,
				(immutable PurityRange cur, ref immutable Type typeArg) =>
					combinePurityRange(cur, purityRange(typeArg)));
			immutable StructDeclAndArgs key = immutable StructDeclAndArgs(decl, copyArr(alloc, typeArgs));
			return KeyValuePair!(immutable StructDeclAndArgs, Ptr!StructInst)(
				key,
				allocateMut(alloc, StructInst(key, linkageRange, purityRange)));
		});

	if (res.didAdd) {
		if (bodyIsSet(decl.deref()))
			setBody(res.value.deref(), instantiateStructBody(alloc, programState, res.key, delayStructInsts));
		else {
			// We should only need to do this in the initial phase of settings struct bodies,
			// which is when delayedStructInst is set.
			push!(Ptr!StructInst)(alloc, force(delayStructInsts).deref, res.value);
		}
	}

	return castImmutable(res.value);
}

private immutable(Ptr!StructInst) instantiateStructInst(
	ref Alloc alloc,
	ref ProgramState programState,
	immutable Ptr!StructInst structInst,
	immutable TypeParamsAndArgs typeParamsAndArgs,
	DelayStructInsts delayStructInsts,
) {
	scope TypeArgsArray itsTypeArgs = typeArgsArray();
	mapTo(itsTypeArgs, typeArgs(structInst.deref()), (ref immutable Type x) =>
		instantiateType(alloc, programState, x, typeParamsAndArgs, delayStructInsts));
	return instantiateStruct(alloc, programState, decl(structInst.deref()), tempAsArr(itsTypeArgs), delayStructInsts);
}

private immutable(Ptr!StructInst) instantiateStructInst(
	ref Alloc alloc,
	ref ProgramState programState,
	immutable Ptr!StructInst structInst,
	ref immutable StructInst contextStructInst,
) {
	immutable TypeParamsAndArgs ta = immutable TypeParamsAndArgs(
		contextStructInst.decl.deref().typeParams,
		contextStructInst.typeArgs);
	return instantiateStructInst(alloc, programState, structInst, ta, noneMut!(Ptr!(MutArr!(Ptr!StructInst))));
}

immutable(Ptr!StructInst) instantiateStructNeverDelay(
	ref Alloc alloc,
	ref ProgramState programState,
	immutable Ptr!StructDecl decl,
	scope immutable Type[] typeArgs,
) {
	return instantiateStruct(alloc, programState, decl, typeArgs, noneMut!(Ptr!(MutArr!(Ptr!StructInst))));
}

immutable(Ptr!StructInst) makeNamedValType(
	ref Alloc alloc,
	ref ProgramState programState,
	ref immutable CommonTypes commonTypes,
	immutable Type valueType,
) {
	return instantiateStructNeverDelay(alloc, programState, commonTypes.namedVal, [valueType]);
}

immutable(Ptr!StructInst) makeArrayType(
	ref Alloc alloc,
	ref ProgramState programState,
	ref immutable CommonTypes commonTypes,
	immutable Type elementType,
) {
	return instantiateStructNeverDelay(alloc, programState, commonTypes.arr, [elementType]);
}

immutable(Ptr!SpecInst) instantiateSpec(
	ref Alloc alloc,
	ref ProgramState programState,
	immutable Ptr!SpecDecl decl,
	scope immutable Type[] typeArgs,
) {
	immutable SpecDeclAndArgs tempKey = immutable SpecDeclAndArgs(decl, typeArgs);
	return getOrAddPair(alloc, programState.specInsts, tempKey, () {
		immutable SpecDeclAndArgs key = immutable SpecDeclAndArgs(decl, copyArr(alloc, typeArgs));
		immutable SpecBody body_ = matchSpecBody!(immutable SpecBody)(
			decl.deref().body_,
			(immutable SpecBody.Builtin b) =>
				immutable SpecBody(SpecBody.Builtin(b.kind)),
			(immutable SpecDeclSig[] sigs) =>
				immutable SpecBody(map!SpecDeclSig(alloc, sigs, (ref immutable SpecDeclSig sig) =>
					immutable SpecDeclSig(sig.docComment, instantiateSig(
						alloc,
						programState,
						sig.sig,
						immutable TypeParamsAndArgs(decl.deref().typeParams, key.typeArgs))))));
		return KeyValuePair!(immutable SpecDeclAndArgs, immutable Ptr!SpecInst)(
			key, allocate(alloc, immutable SpecInst(key, body_)));
	}).value;
}

immutable(Ptr!SpecInst) instantiateSpecInst(
	ref Alloc alloc,
	ref ProgramState programState,
	immutable Ptr!SpecInst specInst,
	immutable TypeParamsAndArgs typeParamsAndArgs,
) {
	TypeArgsArray itsTypeArgs = typeArgsArray();
	mapTo(itsTypeArgs, specInst.deref().typeArgs, (ref immutable Type x) =>
		instantiateType(alloc, programState, x, typeParamsAndArgs, noneMut!(Ptr!(MutArr!(Ptr!StructInst)))));
	return instantiateSpec(alloc, programState, decl(specInst.deref()), tempAsArr(itsTypeArgs));
}

private:

immutable(Sig) instantiateSig(
	ref Alloc alloc,
	ref ProgramState programState,
	ref immutable Sig sig,
	immutable TypeParamsAndArgs typeParamsAndArgs,
) {
	immutable Type returnType = instantiateType(
		alloc, programState, sig.returnType, typeParamsAndArgs, noneMut!(Ptr!(MutArr!(Ptr!StructInst))));
	immutable Params params = matchParams!(immutable Params)(
		sig.params,
		(immutable Param[] params) =>
			immutable Params(map(alloc, params, (ref immutable Param p) =>
				instantiateParam(alloc, programState, typeParamsAndArgs, p))),
		(ref immutable Params.Varargs v) =>
			immutable Params(allocate(alloc, immutable Params.Varargs(
				instantiateParam(alloc, programState, typeParamsAndArgs, v.param),
				instantiateTypeNoDelay(alloc, programState, v.elementType, typeParamsAndArgs)))));
	return immutable Sig(sig.fileAndPos, sig.name, returnType, params);
}

immutable(Param) instantiateParam(
	ref Alloc alloc,
	ref ProgramState programState,
	immutable TypeParamsAndArgs typeParamsAndArgs,
	ref immutable Param a,
) {
	return withType(a, instantiateTypeNoDelay(alloc, programState, a.type, typeParamsAndArgs));
}
