module frontend.programState;

@safe @nogc pure nothrow:

import util.sym : MutSymSet;

// "global" state for compiling a whole program.
// global state is bad, mmmkay. Should not affect actual semantics.
// But we can use it to improve error messages.

struct ProgramState {
	// These sets store all names seen *so far*.
	MutSymSet structAndAliasNames;
	MutSymSet specNames;
	MutSymSet funNames;
	MutSymSet recordFieldNames;
}
