module frontend.instantiate;

@safe @nogc pure nothrow:

import frontend.checkCtx : CheckCtx;
import frontend.checkUtil : ptrAsImmutable;
import model :
	asFunInst,
	asSpecSig,
	bestCasePurity,
	body_,
	bodyIsSet,
	Called,
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
	TypeParam,
	withType,
	worsePurity,
	worstCasePurity;

import util.bools : Bool, False;
import util.collection.arr : Arr, begin, ptrAt, sizeEq;
import util.collection.arrUtil : fold, map;
import util.collection.mutDict : getOrAdd;
import util.collection.mutArr : MutArr, push;
import util.memory : nu, nuMut;
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
	return matchType!(immutable Type)(
		type,
		(ref immutable Type.Bogus) =>
			immutable Type(Type.Bogus()),
		(immutable Ptr!TypeParam p) {
			immutable Opt!Type op = tryGetTypeArgFromTypeParamsAndArgs(typeParamsAndArgs, p);
			return has(op) ? force(op) : type;
		},
		(immutable Ptr!StructInst i) =>
			immutable Type(instantiateStructInst(alloc, ctx, i, typeParamsAndArgs)));
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
	immutable FunDeclAndArgs declAndArgs,
) {
	return getOrAdd(
		ctx.funInsts,
		declAndArgs,
		() => nu!FunInst(
			alloc,
			declAndArgs,
			instantiateSig(
				alloc,
				declAndArgs.decl.sig,
				TypeParamsAndArgs(declAndArgs.decl.typeParams, declAndArgs.typeArgs))));
}

immutable(StructBody) instantiateStructBody(Alloc)(
	ref Alloc alloc,
	ref CheckCtx ctx,
	immutable StructDeclAndArgs declAndArgs,
) {
	immutable TypeParamsAndArgs typeParamsAndArgs = TypeParamsAndArgs(declAndArgs.decl.typeParams, declAndArgs.typeArgs);
	return matchStructBody(
		body_(declAndArgs.decl),
		(ref immutable StructBody.Bogus) => immutable StructBody(StructBody.Bogus()),
		(ref immutable StructBody.Builtin) => immutable StructBody(StructBody.Builtin()),
		(ref immutable StructBody.Record r) =>
			immutable StructBody(StructBody.Record(
				r.forcedByValOrRef,
				map!RecordField(alloc, r.fields, (ref immutable RecordField f) =>
					withType(f, instantiateType(alloc, ctx, f.type, typeParamsAndArgs))))),
		(ref immutable StructBody.Union u) =>
			immutable StructBody(StructBody.Union(
				map!(Ptr!StructInst)(alloc, u.members, (ref immutable Ptr!StructInst i) =>
					instantiateStructInst(alloc, ctx, i, typeParamsAndArgs)))));
}

immutable(Ptr!StructInst) instantiateStruct(Alloc)(
	ref Alloc alloc,
	ref CheckCtx ctx,
	immutable StructDeclAndArgs declAndArgs,
	DelayStructInsts delayStructInsts,
) {
	return ptrAsImmutable(getOrAdd(
		alloc,
		ctx.structInsts,
		declAndArgs,
		() {
			immutable Purity bestPurity = fold(declAndArgs.decl.purity, declAndArgs.typeArgs, (ref immutable Purity pur, ref immutable Type typeArg) =>
				worsePurity(pur, bestCasePurity(typeArg)));
			immutable Purity worstPurity = fold(declAndArgs.decl.purity, declAndArgs.typeArgs, (ref immutable Purity pur, ref immutable Type typeArg) =>
				worsePurity(pur, worstCasePurity(typeArg)));

			Ptr!StructInst res = nuMut!StructInst(alloc, declAndArgs, bestPurity, worstPurity);
			if (bodyIsSet(declAndArgs.decl))
				setBody(res, instantiateStructBody(alloc, ctx, declAndArgs));
			else
				// We should only need to do this in the initial phase of settings struct bodies,
				// which is when delayedStructInst is set.
				push!(Ptr!StructInst, Alloc)(alloc, force(delayStructInsts).deref, res);
			return res;
		}));
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
	immutable SpecDeclAndArgs declAndArgs,
) {
	return getOrAdd(
		alloc,
		ctx.specInsts,
		declAndArgs,
		() => nu!SpecInst(alloc, declAndArgs, matchSpecBody(
				declAndArgs.decl.body_,
				(ref immutable SpecBody.Builtin b) =>
					immutable SpecBody(SpecBody.Builtin(b.kind)),
				(ref immutable Arr!Sig sigs) =>
					immutable SpecBody(map!Sig(alloc, sigs, (ref immutable Sig sig) =>
						instantiateSig(alloc, ctx, sig, TypeParamsAndArgs(declAndArgs.decl.typeParams, declAndArgs.typeArgs)))))));
}

immutable(Ptr!SpecInst) instantiateSpecInst(Alloc)(
	ref Alloc alloc,
	ref CheckCtx ctx,
	immutable Ptr!SpecInst specInst,
	ref immutable TypeParamsAndArgs typeParamsAndArgs,
) {
	// TODO:PERF don't create the array if we don't need it (`instantiate` could take the callback)
	immutable Arr!Type itsTypeArgs = map!Type(alloc, specInst.typeArgs, (ref immutable Type t) =>
		instantiateType(alloc, ctx, t, typeParamsAndArgs));
	return instantiateSpec(alloc, decl(specInst), itsTypeArgs);
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
	ref CheckCtx ctx,
	ref immutable Sig sig,
	immutable TypeParamsAndArgs typeParamsAndArgs,
) {
	immutable Type returnType = instantiateType(alloc, ctx, sig.returnType, typeParamsAndArgs);
	immutable Arr!Param params = map!Param(alloc, sig.params, (ref immutable Param p) =>
		withType(p, instantiateType(alloc, ctx, p.type, typeParamsAndArgs)));
	return immutable Sig(sig.range, sig.name, returnType, params);
}
