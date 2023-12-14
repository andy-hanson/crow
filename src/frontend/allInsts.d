module frontend.allInsts;

@safe @nogc pure nothrow:

import model.model :
	Called,
	CalledSpecSig,
	FunDecl,
	FunInst,
	LinkageRange,
	Module,
	PurityRange,
	ReturnAndParamTypes,
	SpecDecl,
	SpecImpls,
	SpecInst,
	StructDecl,
	StructInst,
	Type,
	TypeArgs;
import util.alloc.alloc : Alloc, free;
import util.col.arr : ptrsRange, SmallArray;
import util.col.arrUtil : arrEqual, copyArr;
import util.col.hashTable : getOrAdd, getOrAddAndDidAdd, mayDeleteValue, MutHashTable, ValueAndDidAdd;
import util.col.mutMap : getOrAdd, getOrAddAndDidAdd;
import util.col.mutMaxSet : has, mayAdd, mustAdd, MutMaxSet, popArbitrary;
import util.col.mutMultiMap : add, mayDeleteAndFree, MutMultiMap;
import util.hash : HashCode, hashTaggedPointer, hashPointerAndTaggedPointers, hashPointerAndTaggedPointersX2;
import util.memory : allocate;
import util.opt : force, has, MutOpt;
import util.union_ : Union;

struct AllInsts {
	@safe @nogc pure nothrow:
	private:
	Alloc* allocPtr;

	MutHashTable!(StructInst*, StructArgs, getStructArgs) structInsts;
	MutHashTable!(SpecInst*, SpecArgs, getSpecArgs) specInsts;
	MutHashTable!(FunInst*, FunArgs, getFunArgs) funInsts;
	MutMultiMap!(AnyDeclOrInst, AnyInst) referencedBy;

	public ref inout(Alloc) alloc() return scope inout =>
		*allocPtr;
}

ValueAndDidAdd!(StructInst*) getOrAddStructInst(
	ref AllInsts a,
	StructDecl* decl,
	in TypeArgs typeArgs,
	in LinkageRange delegate() @safe @nogc pure nothrow cbLinkageRange,
	in PurityRange delegate() @safe @nogc pure nothrow cbPurityRange,
) =>
	getOrAddAndDidAdd!(StructInst*, StructArgs, getStructArgs)(a.alloc, a.structInsts, StructArgs(decl, typeArgs), () {
		StructInst* res = allocate(a.alloc, StructInst(
			decl, copyArr!Type(a.alloc, typeArgs), cbLinkageRange(), cbPurityRange()));
		declReferenced(a, AnyInst(res), decl);
		typeArgsReferenced(a, AnyInst(res), typeArgs);
		return res;
	});

ValueAndDidAdd!(SpecInst*) getOrAddSpecInst(
	ref AllInsts a,
	SpecDecl* decl,
	in TypeArgs typeArgs,
	in SmallArray!ReturnAndParamTypes delegate() @safe @nogc pure nothrow cbInstantiatedSigs,
) =>
	getOrAddAndDidAdd(a.alloc, a.specInsts, SpecArgs(decl, typeArgs), () {
		SpecInst* res = allocate(a.alloc, SpecInst(decl, copyArr!Type(a.alloc, typeArgs), cbInstantiatedSigs()));
		declReferenced(a, AnyInst(res), decl);
		typeArgsReferenced(a, AnyInst(res), typeArgs);
		return res;
	});

FunInst* getOrAddFunInst(
	ref AllInsts a,
	FunDecl* decl,
	in TypeArgs typeArgs,
	in SpecImpls specImpls,
	in ReturnAndParamTypes delegate() @safe @nogc pure nothrow cbReturnAndParamTypes,
) =>
	getOrAdd(a.alloc, a.funInsts, FunArgs(decl, typeArgs, specImpls), () {
		FunInst* res = allocate(a.alloc, FunInst(
			decl, copyArr!Type(a.alloc, typeArgs), copyArr!Called(a.alloc, specImpls), cbReturnAndParamTypes()));
		declReferenced(a, AnyInst(res), decl);
		typeArgsReferenced(a, AnyInst(res), typeArgs);
		specImplsReferenced(a, AnyInst(res), specImpls);
		return res;
	});

// Free all instantiations of structs/specs/funs from the module, as well as anything referencing them.
void freeInstantiationsForModule(ref AllInsts a, in Module module_) {
	ToProcess toProcess;
	// Done processing these, will free at the end.
	getInstsToProcessFromModule(a, toProcess, module_);
	Processed processed;
	while (true) {
		MutOpt!AnyInst opt = popArbitrary(toProcess);
		if (has(opt)) {
			AnyInst inst = force(opt);
			mustAdd(processed, inst);
			deleteAnyInstFromTable(a, inst);
			mayDeleteAndFree(a.alloc, a.referencedBy, inst.asVoidPointer, (AnyInst reference) {
				if (!has(processed, reference))
					mayAdd(toProcess, reference);
			});
		} else
			break;
	}

	foreach (AnyInst inst; processed) {
		() @trusted	 {
			freeAnyInst(a.alloc, inst);
		}();
	}
}

private:

alias ToProcess = MutMaxSet!(0x1000, AnyInst);
alias Processed = MutMaxSet!(0x1000, AnyInst);

alias AnyDeclOrInst = immutable void*;

immutable struct AnyInst {
	@safe @nogc pure nothrow:
	mixin Union!(StructInst*, SpecInst*, FunInst*);
	HashCode hash() =>
		hashTaggedPointer!AnyInst(this);
}
static assert(AnyInst.sizeof == ulong.sizeof);

void getInstsToProcessFromModule(ref AllInsts a, ref ToProcess out_, in Module module_) {
	getInstsToProcessFromDecls!StructDecl(a, out_, module_.structs);
	getInstsToProcessFromDecls!SpecDecl(a, out_, module_.specs);
	getInstsToProcessFromDecls!FunDecl(a, out_, module_.funs);
}

void getInstsToProcessFromDecls(Decl)(ref AllInsts a, ref ToProcess out_, in Decl[] decls) {
	foreach (Decl* decl; ptrsRange(decls))
		mayDeleteAndFree!(AnyDeclOrInst, AnyInst)(a.alloc, a.referencedBy, decl, (AnyInst inst) {
			mustAdd(out_, inst);
		});
}

void deleteAnyInstFromTable(scope ref AllInsts a, AnyInst inst) {
	inst.matchWithPointers!void(
		(StructInst* x) {
			mayDeleteValue(a.structInsts, x);
		},
		(SpecInst* x) {
			mayDeleteValue(a.specInsts, x);
		},
		(FunInst* x) {
			mayDeleteValue(a.funInsts, x);
		});
}

@system void freeAnyInst(ref Alloc alloc, AnyInst inst) {
	inst.matchWithPointers!void(
		(StructInst* x) @trusted {
			free(alloc, x);
		},
		(SpecInst* x) @trusted {
			free(alloc, x);
		},
		(FunInst* x) @trusted {
			free(alloc, x);
		});
}

void declReferenced(ref AllInsts a, AnyInst referencer, AnyDeclOrInst decl) {
	add!(AnyDeclOrInst, AnyInst)(a.alloc, a.referencedBy, decl, referencer);
}

void typeArgsReferenced(ref AllInsts a, AnyInst referencer, TypeArgs typeArgs) {
	foreach (Type x; typeArgs)
		if (x.isA!(StructInst*))
			add!(AnyDeclOrInst, AnyInst)(a.alloc, a.referencedBy, x.as!(StructInst*), referencer);
}

void specImplsReferenced(ref AllInsts a, AnyInst referencer, SpecImpls specImpls) {
	foreach (Called called; specImpls)
		called.matchWithPointers!void(
			(FunInst* x) {
				add(a.alloc, a.referencedBy, x, referencer);
			},
			(CalledSpecSig x) {
				add(a.alloc, a.referencedBy, x.specInst, referencer);
			});
}

immutable struct StructArgs {
	@safe @nogc pure nothrow:
	StructDecl* decl;
	TypeArgs typeArgs;
	bool opEquals(in StructArgs b) scope =>
		decl == b.decl && arrEqual!Type(typeArgs, b.typeArgs);
	HashCode hash() scope =>
		hashPointerAndTaggedPointers!(StructDecl, Type)(decl, typeArgs);
}
StructArgs getStructArgs(in StructInst* a) =>
	StructArgs(a.decl, a.typeArgs);

immutable struct SpecArgs {
	@safe @nogc pure nothrow:
	SpecDecl* decl;
	TypeArgs typeArgs;
	bool opEquals(in SpecArgs b) scope =>
		decl == b.decl && arrEqual!Type(typeArgs, b.typeArgs);
	HashCode hash() scope =>
		hashPointerAndTaggedPointers!(SpecDecl, Type)(decl, typeArgs);
}
SpecArgs getSpecArgs(in SpecInst* a) =>
	SpecArgs(a.decl, a.typeArgs);

immutable struct FunArgs {
	@safe @nogc pure nothrow:
	FunDecl* decl;
	TypeArgs typeArgs;
	SpecImpls specImpls;
	bool opEquals(in FunArgs b) scope =>
		decl == b.decl && arrEqual!Type(typeArgs, b.typeArgs) && arrEqual!Called(specImpls, b.specImpls);
	HashCode hash() scope =>
		hashPointerAndTaggedPointersX2!(FunDecl, Type, Called)(decl, typeArgs, specImpls);
}
FunArgs getFunArgs(in FunInst* a) =>
	FunArgs(a.decl, a.typeArgs, a.specImpls);
