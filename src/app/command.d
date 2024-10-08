module app.command;

@safe @nogc pure nothrow:

import frontend.lang : CCompileOptions, JitOptions;
import lib.server : PrintKind;
import model.model : BuildTarget;
import util.alloc.alloc : Alloc;
import util.col.arrayBuilder : addIfNotContains, buildArray, Builder;
import util.string : CString;
import util.exitCode : ExitCode;
import util.union_ : Union;
import util.uri : FilePath, Uri;
import versionInfo : VersionOptions;

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
	immutable struct Aot {
		VersionOptions version_;
		CCompileOptions compileOptions;
	}
	immutable struct Interpret {
		VersionOptions version_;
	}
	immutable struct NodeJs {}
	immutable struct Jit {
		VersionOptions version_;
		JitOptions options;
	}
	mixin Union!(Aot, Interpret, Jit, NodeJs);
}

immutable struct BuildOptions {
	VersionOptions version_;
	SingleBuildOutput[] out_;
	CCompileOptions cCompileOptions;
}

immutable struct SingleBuildOutput {
	enum Kind { c, executable, jsScript, jsModules, nodeJsScript, nodeJsModules }
	Kind kind;
	FilePath path;
}

BuildTarget[] targetsForBuild(ref Alloc alloc, in CommandKind.Build x) =>
	buildArray!BuildTarget(alloc, (scope ref Builder!BuildTarget out_) {
		foreach (SingleBuildOutput output; x.options.out_)
			addIfNotContains!BuildTarget(out_, targetForBuildOutput(output.kind));
	});
private BuildTarget targetForBuildOutput(SingleBuildOutput.Kind a) {
	final switch (a) {
		case SingleBuildOutput.Kind.c:
		case SingleBuildOutput.Kind.executable:
			return BuildTarget.native;
		case SingleBuildOutput.Kind.jsScript:
		case SingleBuildOutput.Kind.jsModules:
		case SingleBuildOutput.Kind.nodeJsScript:
		case SingleBuildOutput.Kind.nodeJsModules:
			return BuildTarget.js;
	}
}
