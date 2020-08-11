module frontend.programState;

@safe @nogc pure nothrow:

import model :
	compareFunDeclAndArgs,
	compareSpecDeclAndArgs,
	compareStructDeclAndArgs,
	FunDeclAndArgs,
	FunInst,
	SpecDeclAndArgs,
	SpecInst,
	StructDeclAndArgs,
	StructInst;
import util.collection.mutDict : MutDict;
import util.ptr : Ptr;
import util.sym : MutSymSet;

struct ProgramState {
	MutDict!(immutable FunDeclAndArgs, immutable Ptr!FunInst, compareFunDeclAndArgs) funInsts;
	MutDict!(immutable StructDeclAndArgs, Ptr!StructInst, compareStructDeclAndArgs) structInsts;
	MutDict!(immutable SpecDeclAndArgs, immutable Ptr!SpecInst, compareSpecDeclAndArgs) specInsts;

	// These sets store all names seen *so far*.
	MutSymSet structAndAliasNames;
	MutSymSet specNames;
	MutSymSet funNames;
	MutSymSet recordFieldNames;
}
