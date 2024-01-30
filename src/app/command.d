module app.command;

@safe @nogc pure nothrow:

import frontend.lang : CCompileOptions, JitOptions;
import lib.server : PrintKind;
import util.opt : Opt;
import util.string : CString;
import util.symbol : Extension;
import util.exitCode : ExitCode;
import util.union_ : Union;
import util.uri : FileUri, Uri;

immutable struct Command {
	CommandKind kind;
	CommandOptions options;
}

// options common to all commands
immutable struct CommandOptions {
	bool perf;
}

immutable struct CommandKind {
	immutable struct Build {
		Uri mainUri;
		BuildOptions options;
	}
	immutable struct Check {
		Uri[] rootUris;
	}
	immutable struct Document {
		Uri[] rootUris;
	}
	// Used for either explicit '--help' or any error using CLI
	immutable struct Help {
		string helpText;
		ExitCode exitCode;
	}
	immutable struct Lsp {}
	immutable struct Print {
		PrintKind kind;
		Uri mainUri;
	}
	immutable struct Run {
		Uri mainUri;
		RunOptions options;
		// Does not include executable path
		CString[] programArgs;
	}
	immutable struct Test {
		CString[] names;
	}
	immutable struct Version {}

	mixin Union!(Build, Check, Document, Help, Lsp, Print, Run, Test, Version);
}

immutable struct RunOptions {
	immutable struct Interpret {}
	immutable struct Jit {
		JitOptions options;
	}
	immutable struct Aot {
		CCompileOptions compileOptions;
		Extension defaultExeExtension;
	}
	mixin Union!(Interpret, Jit, Aot);
}

immutable struct BuildOptions {
	BuildOut out_;
	CCompileOptions cCompileOptions;
}

// Build to C, executable, or both
immutable struct BuildOut {
	Opt!FileUri outC; // If this is 'none', use a temporary file
	bool shouldBuildExecutable;
	// If 'shouldBuildExecutable' is not set, this is hypothetical (used for comment at top of C file)
	FileUri outExecutable;
}
