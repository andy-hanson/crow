module frontend.instantiate;

@safe @nogc pure nothrow:

import frontend.checkUtil : ptrAsImmutable;
import frontend.programState : ProgramState;
import model :
	asFunInst,
	asSpecSig,
	bestCasePurity,
	body_,
	bodyIsSet,
	Called,
	decl,
	FunDeclAndArgs,
	FunInst,
	isFunInst,
	isSpecSig,
	matchCalled,
	matchSpecBody,
	matchStructBody,
	matchType,
	Param,
	Purity,
	RecordField,
	setBody,
	Sig,
	SpecBody,
	SpecDecl,
	SpecDeclAndArgs,
	SpecInst,
	SpecSig,
	StructBody,
	StructDecl,
	StructDeclAndArgs,
	StructInst,
	Type,
	typeArgs,
	TypeParam,
	withType,
	worsePurity,
	worstCasePurity;

import util.bools : Bool, False;
import util.collection.arr : Arr, begin, emptyArr, ptrAt, size, sizeEq;
import util.collection.arrUtil : fold, map;
import util.collection.mutDict : getOrAdd, getOrAddAndDidAdd, ValueAndDidAdd;
import util.collection.mutArr : MutArr, push;
import util.memory : nu, nuMut;
import util.opt : force, has, none, noneMut, Opt, some, someConst, someMut;
import util.ptr : Ptr, ptrEquals;
import util.util : todo;

import core.stdc.stdio : printf; // TODO:KILL

struct TypeParamsScope {
	// TODO: consistent naming
	immutable Arr!TypeParam innerTypeParams;
}

struct TypeParamsAndArgs {
	@safe @nogc pure nothrow:

	immutable Arr!TypeParam typeParams;
	immutable Arr!Type typeArgs;

	immutable this(immutable Arr!TypeParam tp, immutable Arr!Type ta) {
		typeParams = tp;
		typeArgs = ta;
		assert(sizeEq(typeParams, typeArgs));
	}
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

const(Opt!(Ptr!T)) tryGetTypeArg(T)(
	ref immutable Arr!TypeParam typeParams,
	ref const Arr!T typeArgs,
	immutable Ptr!TypeParam typeParam,
) {
	immutable Bool hasTypeParam = Bool(
		typeParam.index < size(typeParams) &&
		ptrEquals(ptrAt(typeParams, typeParam.index), typeParam));
	return hasTypeParam
		? someConst(ptrAt(typeArgs, typeParam.index))
		: none!(Ptr!T);
}

Opt!(Ptr!T) tryGetTypeArg(T)(
	ref immutable Arr!TypeParam typeParams,
	ref Arr!T typeArgs,
	immutable Ptr!TypeParam typeParam,
) {
	immutable Bool hasTypeParam = Bool(
		typeParam.index < size(typeParams) &&
		ptrEquals(ptrAt(typeParams, typeParam.index), typeParam));
	return hasTypeParam
		? someMut(ptrAt(typeArgs, typeParam.index))
		: noneMut!(Ptr!T);
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
	ref ProgramState programState,
	ref immutable Type type,
	ref immutable TypeParamsAndArgs typeParamsAndArgs,
	DelayStructInsts delayStructInsts,
) {
	return matchType!(immutable Type)(
		type,
		(ref immutable Type.Bogus) =>
			immutable Type(Type.Bogus()),
		(immutable Ptr!TypeParam p) {
			immutable Opt!Type op = tryGetTypeArgFromTypeParamsAndArgs(typeParamsAndArgs, p);
			return has(op) ? force(op) : type;
		},
		(immutable Ptr!StructInst i) =>
			immutable Type(instantiateStructInst(alloc, programState, i, typeParamsAndArgs, delayStructInsts)));
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
	ref ProgramState programState,
	immutable FunDeclAndArgs declAndArgs,
) {
	return getOrAdd(
		alloc,
		programState.funInsts,
		declAndArgs,
		() => nu!FunInst(
			alloc,
			declAndArgs,
			instantiateSig(
				alloc,
				programState,
				declAndArgs.decl.sig,
				immutable TypeParamsAndArgs(declAndArgs.decl.typeParams, declAndArgs.typeArgs))));
}

immutable(StructBody) instantiateStructBody(Alloc)(
	ref Alloc alloc,
	ref ProgramState programState,
	immutable StructDeclAndArgs declAndArgs,
	DelayStructInsts delayStructInsts,
) {
	immutable TypeParamsAndArgs typeParamsAndArgs =
		immutable TypeParamsAndArgs(declAndArgs.decl.typeParams, declAndArgs.typeArgs);
	return matchStructBody(
		body_(declAndArgs.decl),
		(ref immutable StructBody.Bogus) => immutable StructBody(StructBody.Bogus()),
		(ref immutable StructBody.Builtin) => immutable StructBody(StructBody.Builtin()),
		(ref immutable StructBody.Record r) =>
			immutable StructBody(StructBody.Record(
				r.forcedByValOrRef,
				map!RecordField(alloc, r.fields, (ref immutable RecordField f) =>
					withType(f, instantiateType(alloc, programState, f.type, typeParamsAndArgs, delayStructInsts))))),
		(ref immutable StructBody.Union u) =>
			immutable StructBody(StructBody.Union(
				map!(Ptr!StructInst)(alloc, u.members, (ref immutable Ptr!StructInst i) =>
					instantiateStructInst(alloc, programState, i, typeParamsAndArgs, delayStructInsts)))));
}

immutable(Ptr!StructInst) instantiateStruct(Alloc)(
	ref Alloc alloc,
	ref ProgramState programState,
	immutable StructDeclAndArgs declAndArgs,
	DelayStructInsts delayStructInsts,
) {
	ValueAndDidAdd!(Ptr!StructInst) res = getOrAddAndDidAdd(
		alloc,
		programState.structInsts,
		declAndArgs,
		() {
			immutable Purity bestPurity = fold(
				declAndArgs.decl.purity,
				declAndArgs.typeArgs,
				(ref immutable Purity pur, ref immutable Type typeArg) =>
					worsePurity(pur, bestCasePurity(typeArg)));
			immutable Purity worstPurity = fold(
				declAndArgs.decl.purity,
				declAndArgs.typeArgs,
				(ref immutable Purity pur, ref immutable Type typeArg) =>
					worsePurity(pur, worstCasePurity(typeArg)));
			return nuMut!StructInst(alloc, declAndArgs, bestPurity, worstPurity);
		});

	if (res.didAdd) {
		if (bodyIsSet(declAndArgs.decl))
			setBody(res.value, instantiateStructBody(alloc, programState, declAndArgs, delayStructInsts));
		else {
			// We should only need to do this in the initial phase of settings struct bodies,
			// which is when delayedStructInst is set.
			push!(Ptr!StructInst, Alloc)(alloc, force(delayStructInsts).deref, res.value);
		}
	}

	return ptrAsImmutable(res.value);
}

immutable(Ptr!StructInst) instantiateNonTemplateStruct(Alloc)(
	ref Alloc alloc,
	ref ProgramState programState,
	immutable Ptr!StructDecl decl,
) {
	return instantiateStruct(
		alloc,
		programState,
		immutable StructDeclAndArgs(decl, emptyArr!Type),
		noneMut!(Ptr!(MutArr!(Ptr!StructInst))));
}

immutable(Ptr!StructInst) instantiateStructInst(Alloc)(
	ref Alloc alloc,
	ref ProgramState programState,
	immutable Ptr!StructInst structInst,
	ref immutable TypeParamsAndArgs typeParamsAndArgs,
	DelayStructInsts delayStructInsts,
) {
	// TODO:PERF don't create the array if we don't need it (`instantiate` could take the callback)
	immutable Arr!Type itsTypeArgs = map!Type(alloc, typeArgs(structInst), (ref immutable Type t) {
		return instantiateType(alloc, programState, t, typeParamsAndArgs, delayStructInsts);
	});
	return instantiateStruct(
		alloc, programState, immutable StructDeclAndArgs(decl(structInst), itsTypeArgs), delayStructInsts);
}

immutable(Ptr!StructInst) instantiateStructInst(Alloc)(
	ref Alloc alloc,
	ref ProgramState programState,
	immutable Ptr!StructInst structInst,
	ref immutable StructInst contextStructInst,
) {
	immutable TypeParamsAndArgs ta = immutable TypeParamsAndArgs(
		contextStructInst.decl.typeParams,
		contextStructInst.typeArgs);
	return instantiateStructInst(alloc, programState, structInst, ta, noneMut!(Ptr!(MutArr!(Ptr!StructInst))));
}

immutable(Ptr!StructInst) instantiateStructNeverDelay(Alloc)(
	ref Alloc alloc,
	ref ProgramState programState,
	immutable StructDeclAndArgs declAndArgs,
) {
	return instantiateStruct(alloc, programState, declAndArgs, noneMut!(Ptr!(MutArr!(Ptr!StructInst))));
}

immutable(Ptr!SpecInst) instantiateSpec(Alloc)(
	ref Alloc alloc,
	ref ProgramState programState,
	immutable SpecDeclAndArgs declAndArgs,
) {
	return getOrAdd(
		alloc,
		programState.specInsts,
		declAndArgs,
		() => nu!SpecInst(alloc, declAndArgs, matchSpecBody(
				declAndArgs.decl.body_,
				(ref immutable SpecBody.Builtin b) =>
					immutable SpecBody(SpecBody.Builtin(b.kind)),
				(ref immutable Arr!Sig sigs) =>
					immutable SpecBody(map!Sig(alloc, sigs, (ref immutable Sig sig) =>
						instantiateSig(
							alloc,
							programState,
							sig,
							immutable TypeParamsAndArgs(declAndArgs.decl.typeParams, declAndArgs.typeArgs)))))));
}

immutable(Ptr!SpecInst) instantiateSpecInst(Alloc)(
	ref Alloc alloc,
	ref ProgramState programState,
	immutable Ptr!SpecInst specInst,
	ref immutable TypeParamsAndArgs typeParamsAndArgs,
) {
	// TODO:PERF don't create the array if we don't need it (`instantiate` could take the callback)
	immutable Arr!Type itsTypeArgs = map!Type(alloc, specInst.typeArgs, (ref immutable Type t) =>
		instantiateType(alloc, programState, t, typeParamsAndArgs, noneMut!(Ptr!(MutArr!(Ptr!StructInst)))));
	return instantiateSpec(alloc, programState, SpecDeclAndArgs(decl(specInst), itsTypeArgs));
}

private:

immutable(Bool) calledEquals(ref immutable Called a, ref immutable Called b) {
	return matchCalled(
		a,
		(immutable Ptr!FunInst f) =>
			immutable Bool(isFunInst(b) && ptrEquals(f, asFunInst(b))),
		(ref immutable SpecSig s) {
			if (isSpecSig(b)) {
				immutable SpecSig bs = asSpecSig(b);
				if (ptrEquals(s.specInst, bs.specInst)) {
					immutable Bool res = ptrEquals(s.sig, bs.sig);
					assert(res == Bool(s.indexOverAllSpecUses == bs.indexOverAllSpecUses));
					return res;
				} else
					return False;
			} else
				return False;
		});
}

immutable(Sig) instantiateSig(Alloc)(
	ref Alloc alloc,
	ref ProgramState programState,
	ref immutable Sig sig,
	immutable TypeParamsAndArgs typeParamsAndArgs,
) {
	immutable Type returnType = instantiateType(
		alloc, programState, sig.returnType, typeParamsAndArgs, noneMut!(Ptr!(MutArr!(Ptr!StructInst))));
	immutable Arr!Param params = map!Param(alloc, sig.params, (ref immutable Param p) =>
		withType(p, instantiateType(
			alloc,
			programState,
			p.type,
			typeParamsAndArgs,
			noneMut!(Ptr!(MutArr!(Ptr!StructInst))))));
	return immutable Sig(sig.range, sig.name, returnType, params);
}
