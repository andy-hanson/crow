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
	TypeParamIndex,
	TypeParams,
	typeParams,
	UnionMember;
import util.alloc.alloc : Alloc;
import util.col.arr : emptySmallArray, sizeEq, small, SmallArray;
import util.col.arrUtil : copyArr, fold, map, mapWithFirst;
import util.col.hashTable : getOrAdd, getOrAddAndDidAdd, ValueAndDidAdd;
import util.col.mutArr : MutArrWithAlloc, push;
import util.col.mutMaxArr : mapTo, MutMaxArr, mutMaxArr, push, tempAsArr;
import util.memory : allocate;
import util.opt : force, has, MutOpt, none, noneMut, Opt, some, someMut;
import util.perf : Perf, PerfMeasure, withMeasure;
import util.util : typeAs;

// This is a copyable type
struct InstantiateCtx {
	@safe @nogc pure nothrow:

	Perf* perfPtr;
	ProgramState* programStatePtr;

	ref Perf perf() return scope =>
		*perfPtr;
	ref Alloc alloc() =>
		programState.alloc;
	ref ProgramState programState() return scope =>
		*programStatePtr;
}

immutable struct TypeParamsAndArgs {
	@safe @nogc pure nothrow:

	TypeParams typeParams;
	Type[] typeArgs;

	this(TypeParams tp, Type[] ta) {
		typeParams = tp;
		typeArgs = ta;
		assert(sizeEq(typeParams, typeArgs));
	}
}

alias TypeArgsArray = MutMaxArr!(maxTypeParams, Type);
TypeArgsArray typeArgsArray() =>
	mutMaxArr!(maxTypeParams, Type);

alias DelaySpecInsts = MutArrWithAlloc!(SpecInst*);
alias MayDelaySpecInsts = MutOpt!(DelaySpecInsts*); // delayed due to 'parents' referencing other specs
MayDelaySpecInsts noDelaySpecInsts() =>
	noneMut!(DelaySpecInsts*);
alias DelayStructInsts = MutArrWithAlloc!(StructInst*);
alias MayDelayStructInsts = MutOpt!(DelayStructInsts*);
MayDelayStructInsts noDelayStructInsts() =>
	noneMut!(DelayStructInsts*);

private Type instantiateType(
	ref InstantiateCtx ctx,
	Type type,
	in TypeParamsAndArgs typeParamsAndArgs,
	scope MayDelayStructInsts delayStructInsts,
) =>
	type.matchWithPointers!Type(
		(Type.Bogus _) =>
			Type(Type.Bogus()),
		(TypeParamIndex x) =>
			typeParamsAndArgs.typeArgs[x.index],
		(StructInst* x) =>
			Type(instantiateStructInst(ctx, *x, typeParamsAndArgs, delayStructInsts)));

private Type instantiateTypeNoDelay(ref InstantiateCtx ctx, Type type, in TypeParamsAndArgs typeParamsAndArgs) =>
	instantiateType(ctx, type, typeParamsAndArgs, noDelayStructInsts);

FunInst* instantiateFun(ref InstantiateCtx ctx, FunDecl* decl, in Type[] typeArgs, in Called[] specImpls) {
	FunInst* res = withMeasure!(FunInst*, () =>
		getOrAdd(ctx.alloc, ctx.programState.funInsts, FunDeclAndArgs(decl, small(typeArgs), small(specImpls)), () {
			verifySpecs(decl, specImpls);
			FunDeclAndArgs key = FunDeclAndArgs(
				decl, small(copyArr(ctx.alloc, typeArgs)), small(copyArr(ctx.alloc, specImpls)));
			TypeParamsAndArgs typeParamsAndArgs = TypeParamsAndArgs(decl.typeParams, key.typeArgs);
			return allocate(ctx.alloc, FunInst(
				key,
				instantiateReturnAndParamTypes(ctx, decl.returnType, paramsArray(decl.params), typeParamsAndArgs)));
		})
	)(ctx.perf, ctx.alloc, PerfMeasure.instantiateFun);
	verifySpecs(decl, res.declAndArgs.specImpls);
	return res;
}

//TODO:KILL---------------------------------------------------------------------------------------------------------------
void verifySpecs(in FunDecl* decl, in Called[] specImpls) {
	size_t i = 0;
	foreach (SpecInst* spec; decl.specs) {
		eachSpecSig(spec, (in SpecDeclSig sig) {
			assert(sig.name == specImpls[i].name);
			i++;
		});
	}
	assert(i == specImpls.length);
}
//TODO:KILL---------------------------------------------------------------------------------------------------------------
void eachSpecSig(SpecInst* spec, in void delegate(in SpecDeclSig) @safe @nogc pure nothrow cb) {
	foreach (SpecInst* s; spec.parents)
		eachSpecSig(s, cb);
	decl(*spec).body_.matchIn!void(
		(in SpecDeclBody.Builtin) {},
		(in SpecDeclSig[] sigs) {
			foreach (SpecDeclSig sig; sigs) {
				cb(sig);
			}
		});
}


void instantiateStructTypes(ref InstantiateCtx ctx, StructInst* inst, scope MayDelayStructInsts delayStructInsts) {
	TypeParamsAndArgs typeParamsAndArgs = TypeParamsAndArgs(decl(*inst).typeParams, typeArgs(*inst));
	inst.instantiatedTypes = body_(*decl(*inst)).match!(Type[])(
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
			map(ctx.alloc, r.fields, (ref RecordField f) =>
				instantiateType(ctx, f.type, typeParamsAndArgs, delayStructInsts)),
		(StructBody.Union u) =>
			map(ctx.alloc, u.members, (ref UnionMember x) =>
				instantiateType(ctx, x.type, typeParamsAndArgs, delayStructInsts)));
}

StructInst* instantiateStruct(
	ref InstantiateCtx ctx,
	StructDecl* decl,
	in Type[] typeArgs,
	scope MayDelayStructInsts delayStructInsts,
) =>
	withMeasure!(StructInst*, () {
		StructDeclAndArgs tempKey = StructDeclAndArgs(decl, small(typeArgs));
		ValueAndDidAdd!(StructInst*) res = getOrAddAndDidAdd(
			ctx.alloc,
			ctx.programState.structInsts,
			tempKey,
			() =>
				allocate(ctx.alloc, StructInst(
					 StructDeclAndArgs(decl, small(copyArr(ctx.alloc, typeArgs))),
					combinedLinkageRange(decl.linkage, typeArgs),
					combinedPurityRange(decl.purity, typeArgs))));

		if (res.didAdd) {
			if (bodyIsSet(*decl))
				instantiateStructTypes(ctx, res.value, delayStructInsts);
			else {
				// We should only need to do this in the initial phase of settings struct bodies,
				// which is when delayedStructInst is set.
				push(*force(delayStructInsts), res.value);
			}
		}

		return res.value;
	})(ctx.perf, ctx.alloc, PerfMeasure.instantiateStruct);

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
	ref InstantiateCtx ctx,
	ref StructInst structInst,
	in TypeParamsAndArgs typeParamsAndArgs,
	scope MayDelayStructInsts delayStructInsts,
) {
	scope TypeArgsArray itsTypeArgs = typeArgsArray();
	mapTo!(maxTypeParams, Type, Type)(itsTypeArgs, typeArgs(structInst), (ref Type x) =>
		instantiateType(ctx, x, typeParamsAndArgs, delayStructInsts));
	return instantiateStruct(ctx, decl(structInst), tempAsArr(itsTypeArgs), delayStructInsts);
}

StructInst* instantiateStructNeverDelay(ref InstantiateCtx ctx, StructDecl* decl, in Type[] typeArgs) =>
	instantiateStruct(ctx, decl, typeArgs, noDelayStructInsts);

StructInst* makeArrayType(ref InstantiateCtx ctx, ref CommonTypes commonTypes, Type elementType) =>
	instantiateStructNeverDelay(ctx, commonTypes.array, [elementType]);

StructInst* makeConstPointerType(ref InstantiateCtx ctx, ref CommonTypes commonTypes, Type pointeeType) =>
	instantiateStructNeverDelay(ctx, commonTypes.ptrConst, [pointeeType]);

StructInst* makeMutPointerType(ref InstantiateCtx ctx, ref CommonTypes commonTypes, Type pointeeType) =>
	instantiateStructNeverDelay(ctx, commonTypes.ptrMut, [pointeeType]);

SpecInst* instantiateSpec(
	ref InstantiateCtx ctx,
	SpecDecl* decl,
	in Type[] typeArgs,
	scope MayDelaySpecInsts delaySpecInsts,
) =>
	withMeasure!(SpecInst*, () {
		ValueAndDidAdd!(SpecInst*) res = getOrAddAndDidAdd(
			ctx.alloc, ctx.programState.specInsts, SpecDeclAndArgs(decl, small(typeArgs)), () {
				SpecDeclAndArgs key = SpecDeclAndArgs(decl, small(copyArr(ctx.alloc, typeArgs)));
				TypeParamsAndArgs typeParamsAndArgs = TypeParamsAndArgs(decl.typeParams, key.typeArgs);
				return allocate(ctx.alloc, SpecInst(key, decl.body_.match!(SmallArray!ReturnAndParamTypes)(
					(SpecDeclBody.Builtin b) =>
						emptySmallArray!ReturnAndParamTypes,
					(SpecDeclSig[] sigs) =>
						small(map(ctx.alloc, sigs, (ref SpecDeclSig sig) =>
							instantiateReturnAndParamTypes(ctx, sig.returnType, sig.params, typeParamsAndArgs))))));
			});
		if (res.didAdd) {
			if (decl.parentsIsSet)
				instantiateSpecParents(ctx, res.value, delaySpecInsts);
			else
				push(*force(delaySpecInsts), res.value);
		}
		return res.value;
	})(ctx.perf, ctx.alloc, PerfMeasure.instantiateSpec);

void instantiateSpecParents(ref InstantiateCtx ctx, SpecInst* a, scope MayDelaySpecInsts delaySpecInsts) {
	TypeParamsAndArgs typeParamsAndArgs = TypeParamsAndArgs(decl(*a).typeParams, typeArgs(*a));
	a.parents = map!(immutable SpecInst*, immutable SpecInst*)(
		ctx.alloc, decl(*a).parents, (ref immutable SpecInst* parent) =>
			instantiateSpecInst(ctx, parent, typeParamsAndArgs, delaySpecInsts));
}

SpecInst* instantiateSpecInst(
	ref InstantiateCtx ctx,
	SpecInst* specInst,
	in TypeParamsAndArgs typeParamsAndArgs,
	scope MayDelaySpecInsts delaySpecInsts,
) {
	TypeArgsArray itsTypeArgs = typeArgsArray();
	mapTo!(maxTypeParams, Type, Type)(itsTypeArgs, typeArgs(*specInst), (ref Type x) =>
		instantiateType(ctx, x, typeParamsAndArgs, noDelayStructInsts));
	return instantiateSpec(ctx, decl(*specInst), tempAsArr(itsTypeArgs), delaySpecInsts);
}

private:

ReturnAndParamTypes instantiateReturnAndParamTypes(
	ref InstantiateCtx ctx,
	Type declReturnType,
	Destructure[] declParams,
	in TypeParamsAndArgs typeParamsAndArgs,
) =>
	ReturnAndParamTypes(small(mapWithFirst!(Type, Destructure)(
		ctx.alloc,
		instantiateTypeNoDelay(ctx, declReturnType, typeParamsAndArgs),
		declParams,
		(size_t _, ref Destructure x) =>
			instantiateTypeNoDelay(ctx, x.type, typeParamsAndArgs))));
