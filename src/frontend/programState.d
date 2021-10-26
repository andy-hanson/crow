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
import util.ptr : Ptr;
import util.sym : AllSymbols, symOfStr, MutSymSet, Sym;

struct ProgramState {
	@safe @nogc pure nothrow:

	this(ref AllSymbols allSymbols) {
		symFlagsMembers = symOfStr(allSymbols, "flags-members");
		names = ProgramNames(
			MutSymSet(),
			MutSymSet(),
			MutSymSet(),
			MutSymSet());
		funInsts = MutDict!(immutable FunDeclAndArgs, immutable Ptr!FunInst, compareFunDeclAndArgs)();
		structInsts = MutDict!(immutable StructDeclAndArgs, Ptr!StructInst, compareStructDeclAndArgs)();
		specInsts = MutDict!(immutable SpecDeclAndArgs, immutable Ptr!SpecInst, compareSpecDeclAndArgs)();
	}

	immutable Sym symFlagsMembers;
	ProgramNames names;
	MutDict!(immutable FunDeclAndArgs, immutable Ptr!FunInst, compareFunDeclAndArgs) funInsts;
	MutDict!(immutable StructDeclAndArgs, Ptr!StructInst, compareStructDeclAndArgs) structInsts;
	MutDict!(immutable SpecDeclAndArgs, immutable Ptr!SpecInst, compareSpecDeclAndArgs) specInsts;
}

private struct ProgramNames {
	// These sets store all names seen *so far*.
	MutSymSet structAndAliasNames;
	MutSymSet specNames;
	MutSymSet funNames;
	MutSymSet recordFieldNames;
}
