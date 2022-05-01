module frontend.programState;

@safe @nogc pure nothrow:

import model.model : FunDeclAndArgs, FunInst, SpecDeclAndArgs, SpecInst, StructDeclAndArgs, StructInst;
import util.col.mutDict : MutDict;

struct ProgramState {
	MutDict!(immutable FunDeclAndArgs, immutable FunInst*) funInsts;
	MutDict!(immutable StructDeclAndArgs, StructInst*) structInsts;
	MutDict!(immutable SpecDeclAndArgs, immutable SpecInst*) specInsts;
}
