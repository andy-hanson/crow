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
import util.alloc.alloc : Alloc;
import util.collection.mutDict : MutDict;
import util.memory : allocateMut;
import util.ptr : Ptr;
import util.sym : AllSymbols, symOfStr, MutSymSet, Sym;

struct ProgramState {
	@safe @nogc pure nothrow:

	this(ref Alloc alloc, ref AllSymbols allSymbols) {
		symFlagsMembers = symOfStr(allSymbols, "flags-members");
		names = allocateMut(alloc, ProgramNames(
			allocateMut(alloc, MutSymSet()),
			allocateMut(alloc, MutSymSet()),
			allocateMut(alloc, MutSymSet()),
			allocateMut(alloc, MutSymSet())));
		funInsts = allocateMut(alloc, MutDict!(immutable FunDeclAndArgs, immutable Ptr!FunInst, compareFunDeclAndArgs)());
		structInsts = allocateMut(alloc, MutDict!(immutable StructDeclAndArgs, Ptr!StructInst, compareStructDeclAndArgs)());
		specInsts = allocateMut(alloc, MutDict!(immutable SpecDeclAndArgs, immutable Ptr!SpecInst, compareSpecDeclAndArgs)());
	}

	immutable Sym symFlagsMembers;
	Ptr!ProgramNames names;
	Ptr!(MutDict!(immutable FunDeclAndArgs, immutable Ptr!FunInst, compareFunDeclAndArgs)) funInsts;
	Ptr!(MutDict!(immutable StructDeclAndArgs, Ptr!StructInst, compareStructDeclAndArgs)) structInsts;
	Ptr!(MutDict!(immutable SpecDeclAndArgs, immutable Ptr!SpecInst, compareSpecDeclAndArgs)) specInsts;
}

private struct ProgramNames {
	// These sets store all names seen *so far*.
	Ptr!MutSymSet structAndAliasNames;
	Ptr!MutSymSet specNames;
	Ptr!MutSymSet funNames;
	Ptr!MutSymSet recordFieldNames;
}
