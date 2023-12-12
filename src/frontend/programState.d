module frontend.programState;

@safe @nogc pure nothrow:

import model.model :
	Called,
	FunDecl,
	FunInst,
	LinkageRange,
	PurityRange,
	ReturnAndParamTypes,
	SpecDecl,
	SpecImpls,
	SpecInst,
	StructDecl,
	StructInst,
	Type,
	TypeArgs;
import util.alloc.alloc : Alloc;
import util.col.arr : SmallArray;
import util.col.arrUtil : arrEqual, copyArr;
import util.col.hashTable : getOrAdd, getOrAddAndDidAdd, MutHashTable, ValueAndDidAdd;
import util.hash : HashCode, hashPointerAndTaggedPointers, hashPointerAndTaggedPointersX2;
import util.memory : allocate;

struct ProgramState {
	@safe @nogc pure nothrow:
	private:
	Alloc* allocPtr;
	MutHashTable!(StructInst*, StructDeclAndArgs, getStructDeclAndArgs) structInsts;
	MutHashTable!(SpecInst*, SpecDeclAndArgs, getSpecDeclAndArgs) specInsts;
	MutHashTable!(FunInst*, FunDeclAndArgs, getFunDeclAndArgs) funInsts;

	public ref inout(Alloc) alloc() return scope inout =>
		*allocPtr;
}

ValueAndDidAdd!(StructInst*) getOrAddStructInst(
	ref ProgramState a,
	StructDecl* decl,
	in TypeArgs typeArgs,
	in LinkageRange delegate() @safe @nogc pure nothrow cbLinkageRange,
	in PurityRange delegate() @safe @nogc pure nothrow cbPurityRange,
) =>
	getOrAddAndDidAdd(a.alloc, a.structInsts, StructDeclAndArgs(decl, typeArgs), () =>
		allocate(a.alloc, StructInst(decl, copyArr!Type(a.alloc, typeArgs), cbLinkageRange(), cbPurityRange())));

ValueAndDidAdd!(SpecInst*) getOrAddSpecInst(
	ref ProgramState a,
	SpecDecl* decl,
	in TypeArgs typeArgs,
	in SmallArray!ReturnAndParamTypes delegate() @safe @nogc pure nothrow cbInstantiatedSigs,
) =>
	getOrAddAndDidAdd(
		a.alloc, a.specInsts, SpecDeclAndArgs(decl, typeArgs), () =>
			allocate(a.alloc, SpecInst(decl, copyArr!Type(a.alloc, typeArgs), cbInstantiatedSigs())));

FunInst* getOrAddFunInst(
	ref ProgramState a,
	FunDecl* decl,
	in TypeArgs typeArgs,
	in SpecImpls specImpls,
	in ReturnAndParamTypes delegate() @safe @nogc pure nothrow cbReturnAndParamTypes,
) =>
	getOrAdd(a.alloc, a.funInsts, FunDeclAndArgs(decl, typeArgs, specImpls), () =>
		allocate(a.alloc, FunInst(
			decl, copyArr!Type(a.alloc, typeArgs), copyArr!Called(a.alloc, specImpls), cbReturnAndParamTypes())));

private:

immutable struct StructDeclAndArgs {
	@safe @nogc pure nothrow:

	StructDecl* decl;
	TypeArgs typeArgs;

	bool opEquals(in StructDeclAndArgs b) scope =>
		decl == b.decl && arrEqual!Type(typeArgs, b.typeArgs);

	HashCode hash() scope =>
		hashPointerAndTaggedPointers(decl, typeArgs);
}

StructDeclAndArgs getStructDeclAndArgs(in StructInst* a) =>
	StructDeclAndArgs(a.decl, a.typeArgs);

immutable struct SpecDeclAndArgs {
	@safe @nogc pure nothrow:

	SpecDecl* decl;
	TypeArgs typeArgs;

	bool opEquals(in SpecDeclAndArgs b) scope =>
		decl == b.decl && arrEqual!Type(typeArgs, b.typeArgs);

	HashCode hash() scope =>
		hashPointerAndTaggedPointers(decl, typeArgs);
}

SpecDeclAndArgs getSpecDeclAndArgs(in SpecInst* a) =>
	SpecDeclAndArgs(a.decl, a.typeArgs);

immutable struct FunDeclAndArgs {
	@safe @nogc pure nothrow:

	FunDecl* decl;
	TypeArgs typeArgs;
	SpecImpls specImpls;

	bool opEquals(in FunDeclAndArgs b) scope =>
		decl == b.decl && arrEqual!Type(typeArgs, b.typeArgs) && arrEqual!Called(specImpls, b.specImpls);

	HashCode hash() scope =>
		hashPointerAndTaggedPointersX2(decl, typeArgs, specImpls);
}

FunDeclAndArgs getFunDeclAndArgs(in FunInst* a) =>
	FunDeclAndArgs(a.decl, a.typeArgs, a.specImpls);
