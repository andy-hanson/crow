module frontend.programState;

@safe @nogc pure nothrow:

import model.model : FunDeclAndArgs, FunInst, SpecDeclAndArgs, SpecInst, StructDeclAndArgs, StructInst;
import util.col.mutDict : MutDict;

struct ProgramState {
	MutDict!(FunDeclAndArgs, FunInst*) funInsts;
	MutDict!(StructDeclAndArgs, StructInst*) structInsts;
	MutDict!(SpecDeclAndArgs, SpecInst*) specInsts;
}
