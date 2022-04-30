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

struct ProgramState {
	MutDict!(immutable FunDeclAndArgs, immutable FunInst*, funDeclAndArgsEqual, hashFunDeclAndArgs) funInsts;
	MutDict!(immutable StructDeclAndArgs, StructInst*, structDeclAndArgsEqual, hashStructDeclAndArgs) structInsts;
	MutDict!(immutable SpecDeclAndArgs, immutable SpecInst*, specDeclAndArgsEqual, hashSpecDeclAndArgs) specInsts;
}
