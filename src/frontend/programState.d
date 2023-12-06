module frontend.programState;

@safe @nogc pure nothrow:

import model.model : FunDeclAndArgs, FunInst, SpecDeclAndArgs, SpecInst, StructDeclAndArgs, StructInst;
import util.alloc.alloc : Alloc;
import util.col.hashTable : MutHashTable;

struct ProgramState {
	@safe @nogc pure nothrow:
	Alloc* allocPtr;
	MutHashTable!(StructInst*, StructDeclAndArgs, getStructDeclAndArgs) structInsts;
	MutHashTable!(SpecInst*, SpecDeclAndArgs, getSpecDeclAndArgs) specInsts;
	MutHashTable!(FunInst*, FunDeclAndArgs, getFunDeclAndArgs) funInsts;

	ref inout(Alloc) alloc() return scope inout =>
		*allocPtr;
}

private:

StructDeclAndArgs getStructDeclAndArgs(in StructInst* a) =>
	a.declAndArgs;

SpecDeclAndArgs getSpecDeclAndArgs(in SpecInst* a) =>
	a.declAndArgs;

FunDeclAndArgs getFunDeclAndArgs(in FunInst* a) =>
	a.declAndArgs;
