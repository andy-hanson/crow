module frontend.programState;

@safe @nogc pure nothrow:

import model.model : FunDeclAndArgs, FunInst, SpecDeclAndArgs, SpecInst, StructDeclAndArgs, StructInst;
import util.alloc.alloc : Alloc, MemorySummary, summarizeMemory;
import util.col.hashTable : HashTable;

struct ProgramState {
	@safe @nogc pure nothrow:
	Alloc* allocPtr;
	HashTable!(StructInst*, StructDeclAndArgs, getStructDeclAndArgs) structInsts;
	HashTable!(SpecInst*, SpecDeclAndArgs, getSpecDeclAndArgs) specInsts;
	HashTable!(FunInst*, FunDeclAndArgs, getFunDeclAndArgs) funInsts;

	ref inout(Alloc) alloc() return scope inout =>
		*allocPtr;
}

MemorySummary summarizeMemory(in ProgramState a) =>
	summarizeMemory(a.alloc);

private:

StructDeclAndArgs getStructDeclAndArgs(in StructInst* a) =>
	a.declAndArgs;

SpecDeclAndArgs getSpecDeclAndArgs(in SpecInst* a) =>
	a.declAndArgs;

FunDeclAndArgs getFunDeclAndArgs(in FunInst* a) =>
	a.declAndArgs;
