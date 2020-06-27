module util.io;

@safe @nogc nothrow: // not pure

import util.bools : Bool;
import util.collection.arr : Arr;
import util.collection.dict : KeyValuePair;
import util.collection.str : NulTerminatedStr, Str;
import util.opt : Opt;
import util.path : AbsolutePath;

immutable(Bool) fileExists(immutable AbsolutePath path) {
	assert(0);
}

immutable(Opt!NulTerminatedStr) tryReadFile(Alloc)(ref Alloc alloc, immutable AbsolutePath path) {
	assert(0);
}

void writeFileSync(immutable AbsolutePath path, immutable Str content) {
	assert(0);
}

alias Environ = Arr!(KeyValuePair!(Str, Str));

// Returns the child process' error code.
// WARN: A first arg will be prepended that is the executable path.
int spawnAndWaitSync(
	immutable AbsolutePath executable,
	immutable Arr!Str args,
	immutable Environ environ
) {
	assert(0);
}

// Replaces this process with the given executable.
// DOES NOT RETURN!
void replaceCurrentProcess(
	immutable AbsolutePath executable,
	immutable Arr!Str args,
	immutable Environ environ,
) {
	assert(0);
}

struct CommandLineArgs {
	immutable AbsolutePath pathToThisExecutable;
	immutable Arr!Str args;
	immutable Environ environ;
}

immutable(CommandLineArgs) parseCommandLineArgs(Alloc)(ref Alloc alloc, immutable int argc, immutable CStr* argv) {
	assert(0);
}

immutable(AbsolutePath) getCwd(Alloc)(ref Alloc alloc) {
	assert(0);
}

immutable(Environ) getEnviron(Alloc)(ref Alloc alloc) {
	assert(0);
}




