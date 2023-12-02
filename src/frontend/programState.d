module frontend.programState;

@safe @nogc pure nothrow:

import model.model : FunDeclAndArgs, FunInst, SpecDeclAndArgs, SpecInst, StructDeclAndArgs, StructInst;
import util.alloc.alloc : Alloc;
import util.col.mutMap : MutMap;

struct ProgramState {
	Alloc alloc;
	MutMap!(FunDeclAndArgs, FunInst*) funInsts;
	MutMap!(StructDeclAndArgs, StructInst*) structInsts;
	MutMap!(SpecDeclAndArgs, SpecInst*) specInsts;
}
