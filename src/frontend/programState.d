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
import util.collection.mutDict : MutDict;
import util.collection.mutSet : MutSymSet;
import util.ptr : Ptr;
import util.sym : AllSymbols, symOfStr, Sym;

struct ProgramState {
	@safe @nogc pure nothrow:

	this(ref AllSymbols allSymbols) {
		symFlagsMembers = symOfStr(allSymbols, "flags-members");
		names = ProgramNames(
			MutSymSet(),
			MutSymSet(),
			MutSymSet(),
			MutSymSet());
		funInsts = MutDict!(
			immutable FunDeclAndArgs, immutable Ptr!FunInst, funDeclAndArgsEqual, hashFunDeclAndArgs)();
		structInsts = MutDict!(
			immutable StructDeclAndArgs, Ptr!StructInst, structDeclAndArgsEqual, hashStructDeclAndArgs)();
		specInsts = MutDict!(
			immutable SpecDeclAndArgs, immutable Ptr!SpecInst, specDeclAndArgsEqual, hashSpecDeclAndArgs)();
	}

	immutable Sym symFlagsMembers;
	ProgramNames names;
	MutDict!(immutable FunDeclAndArgs, immutable Ptr!FunInst, funDeclAndArgsEqual, hashFunDeclAndArgs) funInsts;
	MutDict!(immutable StructDeclAndArgs, Ptr!StructInst, structDeclAndArgsEqual, hashStructDeclAndArgs) structInsts;
	MutDict!(immutable SpecDeclAndArgs, immutable Ptr!SpecInst, specDeclAndArgsEqual, hashSpecDeclAndArgs) specInsts;
}

private struct ProgramNames {
	// These sets store all names seen *so far*.
	MutSymSet structAndAliasNames;
	MutSymSet specNames;
	MutSymSet funNames;
	MutSymSet recordFieldNames;
}
