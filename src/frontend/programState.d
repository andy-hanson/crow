module frontend.programState;

@safe @nogc pure nothrow:

import model.model :
	Called,
	FunDecl,
	FunDeclAndArgs,
	FunInst,
	LinkageRange,
	PurityRange,
	ReturnAndParamTypes,
	SpecDecl,
	SpecDeclAndArgs,
	SpecImpls,
	SpecInst,
	StructDecl,
	StructDeclAndArgs,
	StructInst,
	Type,
	TypeArgs;
import util.alloc.alloc : Alloc;
import util.col.arr : small, SmallArray;
import util.col.arrUtil : copyArr;
import util.col.hashTable : getOrAdd, getOrAddAndDidAdd, MutHashTable, ValueAndDidAdd;
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
	in Type[] typeArgs,
	in LinkageRange delegate() @safe @nogc pure nothrow cbLinkageRange,
	in PurityRange delegate() @safe @nogc pure nothrow cbPurityRange,
) =>
	getOrAddAndDidAdd(a.alloc, a.structInsts, StructDeclAndArgs(decl, small!Type(typeArgs)), () =>
		allocate(a.alloc, StructInst(StructDeclAndArgs(decl, small!Type(copyArr(a.alloc, typeArgs))), cbLinkageRange(), cbPurityRange())));

ValueAndDidAdd!(SpecInst*) getOrAddSpecInst(
	ref ProgramState a,
	SpecDecl* decl,
	in TypeArgs typeArgs,
	in SmallArray!ReturnAndParamTypes delegate() @safe @nogc pure nothrow cbInstantiatedSigs,
) =>
	getOrAddAndDidAdd(
		a.alloc, a.specInsts, SpecDeclAndArgs(decl, typeArgs), () {
			SpecDeclAndArgs key = SpecDeclAndArgs(decl, small!Type(copyArr(a.alloc, typeArgs)));
			return allocate(a.alloc, SpecInst(key, cbInstantiatedSigs()));
		});

FunInst* getOrAddFunInst(
	ref ProgramState a,
	FunDecl* decl,
	in TypeArgs typeArgs,
	in SpecImpls specImpls,
	in ReturnAndParamTypes delegate() @safe @nogc pure nothrow cbReturnAndParamTypes,
) =>
	getOrAdd(a.alloc, a.funInsts, FunDeclAndArgs(decl, typeArgs, specImpls), () {
		FunDeclAndArgs key = FunDeclAndArgs(
			decl, small!Type(copyArr(a.alloc, typeArgs)), small!Called(copyArr(a.alloc, specImpls)));
		return allocate(a.alloc, FunInst(key, cbReturnAndParamTypes()));
	});

private:

StructDeclAndArgs getStructDeclAndArgs(in StructInst* a) =>
	a.declAndArgs;

SpecDeclAndArgs getSpecDeclAndArgs(in SpecInst* a) =>
	a.declAndArgs;

FunDeclAndArgs getFunDeclAndArgs(in FunInst* a) =>
	a.declAndArgs;
