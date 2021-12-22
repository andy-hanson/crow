module frontend.check.instantiate;

@safe @nogc pure nothrow:

import frontend.programState : ProgramState;
import model.model :
	bestCasePurity,
	body_,
	bodyIsSet,
	CommonTypes,
	decl,
	FunDeclAndArgs,
	FunInst,
	matchParams,
	matchSpecBody,
	matchStructBody,
	matchType,
	Param,
	Params,
	Purity,
	RecordField,
	setBody,
	Sig,
	SpecBody,
	SpecDeclAndArgs,
	SpecInst,
	StructBody,
	StructDeclAndArgs,
	StructInst,
	Type,
	typeArgs,
	TypeParam,
	typeParams,
	UnionMember,
	withType,
	worsePurity,
	worstCasePurity;
import util.alloc.alloc : Alloc;
import util.col.arr : ptrAt, sizeEq;
import util.col.arrUtil : arrLiteral, fold, map, mapWithSize;
import util.col.mutDict : getOrAdd, getOrAddAndDidAdd, ValueAndDidAdd;
import util.col.mutArr : MutArr, push;
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

immutable(Opt!(Ptr!T)) tryGetTypeArg(T)(
	immutable TypeParam[] typeParams,
	ref immutable T[] typeArgs,
	immutable Ptr!TypeParam typeParam,
) {
	immutable size_t index = typeParam.deref().index;
	immutable bool hasTypeParam = ptrEquals(ptrAt(typeParams, index), typeParam);
	return hasTypeParam
		? some(ptrAt(typeArgs, index))
		: none!(Ptr!T);
}

const(Opt!(Ptr!T)) tryGetTypeArg(T)(
	immutable TypeParam[] typeParams,
	ref const T[] typeArgs,
	immutable Ptr!TypeParam typeParam,
) {
	immutable size_t index = typeParam.deref().index;
	return index < typeParams.length && ptrEquals(ptrAt(typeParams, index), typeParam)
		? someConst(ptrAt(typeArgs, index))
		: none!(Ptr!T);
}

Opt!(Ptr!T) tryGetTypeArg(T)(
	immutable TypeParam[] typeParams,
	ref T[] typeArgs,
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
	return has(t)
		? some(force(t).deref)
		: none!Type;
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
	immutable FunDeclAndArgs declAndArgs,
) {
	return getOrAdd(
		alloc,
		programState.funInsts,
		declAndArgs,
		() => allocate(alloc, immutable FunInst(
			declAndArgs,
			instantiateSig(
				alloc,
				programState,
				declAndArgs.decl.deref().sig,
				immutable TypeParamsAndArgs(declAndArgs.decl.deref().typeParams, declAndArgs.typeArgs)))));
}

immutable(StructBody) instantiateStructBody(
	ref Alloc alloc,
	ref ProgramState programState,
	immutable StructDeclAndArgs declAndArgs,
	DelayStructInsts delayStructInsts,
) {
	immutable TypeParamsAndArgs typeParamsAndArgs =
		immutable TypeParamsAndArgs(typeParams(declAndArgs.decl.deref()), declAndArgs.typeArgs);
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
	immutable StructDeclAndArgs declAndArgs,
	DelayStructInsts delayStructInsts,
) {
	ValueAndDidAdd!(Ptr!StructInst) res = getOrAddAndDidAdd(alloc, programState.structInsts, declAndArgs, () {
		immutable Purity declPurity = declAndArgs.decl.deref().purity;
		immutable Type[] typeArgs = declAndArgs.typeArgs;
		immutable Purity bestPurity = fold(declPurity, typeArgs, (immutable Purity pur, ref immutable Type typeArg) =>
			worsePurity(pur, bestCasePurity(typeArg)));
		immutable Purity worstPurity = fold(declPurity, typeArgs, (immutable Purity pur, ref immutable Type typeArg) =>
			worsePurity(pur, worstCasePurity(typeArg)));
		return allocateMut(alloc, StructInst(declAndArgs, bestPurity, worstPurity));
	});

	if (res.didAdd) {
		if (bodyIsSet(declAndArgs.decl.deref()))
			setBody(res.value.deref(), instantiateStructBody(alloc, programState, declAndArgs, delayStructInsts));
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
	// TODO:PERF don't create the array if we don't need it (`instantiate` could take the callback)
	immutable Type[] itsTypeArgs = map!Type(alloc, typeArgs(structInst.deref()), (ref immutable Type t) =>
		instantiateType(alloc, programState, t, typeParamsAndArgs, delayStructInsts));
	return instantiateStruct(
		alloc, programState, immutable StructDeclAndArgs(decl(structInst.deref()), itsTypeArgs), delayStructInsts);
}

private immutable(Ptr!StructInst) instantiateStructInst(
	ref Alloc alloc,
	ref ProgramState programState,
	immutable Ptr!StructInst structInst,
	ref immutable StructInst contextStructInst,
) {
	immutable TypeParamsAndArgs ta = immutable TypeParamsAndArgs(
		typeParams(contextStructInst.decl.deref()),
		contextStructInst.typeArgs);
	return instantiateStructInst(alloc, programState, structInst, ta, noneMut!(Ptr!(MutArr!(Ptr!StructInst))));
}

immutable(Ptr!StructInst) instantiateStructNeverDelay(
	ref Alloc alloc,
	ref ProgramState programState,
	immutable StructDeclAndArgs declAndArgs,
) {
	return instantiateStruct(alloc, programState, declAndArgs, noneMut!(Ptr!(MutArr!(Ptr!StructInst))));
}

immutable(Ptr!StructInst) makeNamedValType(
	ref Alloc alloc,
	ref ProgramState programState,
	ref immutable CommonTypes commonTypes,
	immutable Type valueType,
) {
	return instantiateStructNeverDelay(
		alloc,
		programState,
		immutable StructDeclAndArgs(commonTypes.namedVal, arrLiteral!Type(alloc, [valueType])));
}

immutable(Ptr!StructInst) makeArrayType(
	ref Alloc alloc,
	ref ProgramState programState,
	ref immutable CommonTypes commonTypes,
	immutable Type elementType,
) {
	return instantiateStructNeverDelay(
		alloc,
		programState,
		immutable StructDeclAndArgs(commonTypes.arr, arrLiteral!Type(alloc, [elementType])));
}

immutable(Ptr!SpecInst) instantiateSpec(
	ref Alloc alloc,
	ref ProgramState programState,
	immutable SpecDeclAndArgs declAndArgs,
) {
	return getOrAdd(
		alloc,
		programState.specInsts,
		declAndArgs,
		() => allocate(alloc, immutable SpecInst(declAndArgs, matchSpecBody!(immutable SpecBody)(
			declAndArgs.decl.deref().body_,
			(immutable SpecBody.Builtin b) =>
				immutable SpecBody(SpecBody.Builtin(b.kind)),
			(immutable Sig[] sigs) =>
				immutable SpecBody(map!Sig(alloc, sigs, (ref immutable Sig sig) =>
					instantiateSig(
						alloc,
						programState,
						sig,
						immutable TypeParamsAndArgs(declAndArgs.decl.deref().typeParams, declAndArgs.typeArgs))))))));
}

immutable(Ptr!SpecInst) instantiateSpecInst(
	ref Alloc alloc,
	ref ProgramState programState,
	immutable Ptr!SpecInst specInst,
	immutable TypeParamsAndArgs typeParamsAndArgs,
) {
	// TODO:PERF don't create the array if we don't need it (`instantiate` could take the callback)
	immutable Type[] itsTypeArgs = map!Type(alloc, specInst.deref().typeArgs, (ref immutable Type t) =>
		instantiateType(alloc, programState, t, typeParamsAndArgs, noneMut!(Ptr!(MutArr!(Ptr!StructInst)))));
	return instantiateSpec(alloc, programState, SpecDeclAndArgs(decl(specInst.deref()), itsTypeArgs));
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
	immutable Params params = matchParams!(
		immutable Params,
		(immutable Param[] params) =>
			immutable Params(mapWithSize!Param(alloc, params, (ref immutable Param p) =>
				instantiateParam(alloc, programState, typeParamsAndArgs, p))),
		(ref immutable Params.Varargs v) =>
			immutable Params(allocate(alloc, immutable Params.Varargs(
				instantiateParam(alloc, programState, typeParamsAndArgs, v.param),
				instantiateTypeNoDelay(alloc, programState, v.elementType, typeParamsAndArgs)))),
	)(sig.params);
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
