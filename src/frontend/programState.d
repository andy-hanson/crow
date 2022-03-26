module frontend.programState;

@safe @nogc pure nothrow:

import model.model :
	FunDeclAndArgs,
	funDeclAndArgsEqual,
	FunInst,
	hashFunDeclAndArgs,
	hashSpecDeclAndArgs,
	hashStructDeclAndArgs,
	SpecDeclAndArgs,
	specDeclAndArgsEqual,
	SpecInst,
	StructDeclAndArgs,
	structDeclAndArgsEqual,
	StructInst;
import util.col.mutDict : MutDict;
import util.ptr : Ptr;

struct ProgramState {
	MutDict!(immutable FunDeclAndArgs, immutable Ptr!FunInst, funDeclAndArgsEqual, hashFunDeclAndArgs) funInsts;
	MutDict!(immutable StructDeclAndArgs, Ptr!StructInst, structDeclAndArgsEqual, hashStructDeclAndArgs) structInsts;
	MutDict!(immutable SpecDeclAndArgs, immutable Ptr!SpecInst, specDeclAndArgsEqual, hashSpecDeclAndArgs) specInsts;
}
