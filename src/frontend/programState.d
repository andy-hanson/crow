module frontend.programState;

@safe @nogc pure nothrow:

import model.model :
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
import util.memory : nuMut;
import util.ptr : Ptr;
import util.sym : MutSymSet;

struct ProgramState {
	this(Alloc)(ref Alloc alloc) {
		names = nuMut!ProgramNames(
			alloc,
			nuMut!MutSymSet(alloc),
			nuMut!MutSymSet(alloc),
			nuMut!MutSymSet(alloc),
			nuMut!MutSymSet(alloc));
		funInsts = nuMut!(MutDict!(immutable FunDeclAndArgs, immutable Ptr!FunInst, compareFunDeclAndArgs))(alloc);
		structInsts = nuMut!(MutDict!(immutable StructDeclAndArgs, Ptr!StructInst, compareStructDeclAndArgs))(alloc);
		specInsts = nuMut!(MutDict!(immutable SpecDeclAndArgs, immutable Ptr!SpecInst, compareSpecDeclAndArgs))(alloc);
	}

	Ptr!ProgramNames names;
	Ptr!(MutDict!(immutable FunDeclAndArgs, immutable Ptr!FunInst, compareFunDeclAndArgs)) funInsts;
	Ptr!(MutDict!(immutable StructDeclAndArgs, Ptr!StructInst, compareStructDeclAndArgs)) structInsts;
	Ptr!(MutDict!(immutable SpecDeclAndArgs, immutable Ptr!SpecInst, compareSpecDeclAndArgs)) specInsts;
}
static assert(ProgramState.sizeof <= 32);

private struct ProgramNames {
	// These sets store all names seen *so far*.
	Ptr!MutSymSet structAndAliasNames;
	Ptr!MutSymSet specNames;
	Ptr!MutSymSet funNames;
	Ptr!MutSymSet recordFieldNames;
}
static assert(ProgramNames.sizeof <= 32);
