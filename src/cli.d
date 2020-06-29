module cli;

import core.stdc.stdio : printf;

import compiler : build, buildAndRun;

import util.alloc.stackAlloc : StackAlloc;
import util.bools : Bool, False, True;
import util.collection.arr : Arr, at, empty, emptyArr, first, only, size;
import util.collection.arrUtil : slice, sliceFromTo, tail;
import util.collection.str : CStr, endsWith, Str, strEqLiteral, strLiteral;
import util.io : getCwd, parseCommandLineArgs, CommandLineArgs;
import util.opt : force, forceOrTodo, has, Opt;
import util.path :
	AbsolutePath,
	AbsoluteOrRelPath,
	baseName,
	match,
	parseAbsoluteOrRelPath,
	parent,
	Path,
	RelPath,
	resolvePath,
	rootPath;
import util.ptr : Ptr;
import util.sym : AllSymbols, shortSymAlphaLiteral, Sym, symEq;
import util.util : todo;

@safe @nogc nothrow: // not pure

int cli(immutable size_t argc, immutable CStr* argv) {
	StackAlloc alloc;
	StackAlloc symAlloc;
	AllSymbols!StackAlloc allSymbols = AllSymbols!StackAlloc(symAlloc); // Just for paths
	immutable CommandLineArgs args = parseCommandLineArgs(alloc, allSymbols, argc, argv);
	return go(allSymbols, args);
}

private:

immutable(int) go(SymAlloc)(ref AllSymbols!SymAlloc allSymbols, ref immutable CommandLineArgs args) {
	StackAlloc alloc;
	immutable AbsolutePath nozeDir = getNozeDirectory(args.pathToThisExecutable);
	immutable Command command = parseCommand(alloc, allSymbols, getCwd(alloc, allSymbols), args.args);
	/*
	ref immutable Command a,
	scope immutable(Out) delegate(ref immutable Command.Build) @safe @nogc pure nothrow cbBuild,
	scope immutable(Out) delegate(ref immutable Command.Help) @safe @nogc pure nothrow cbHelp,
	scope immutable(Out) delegate(ref immutable Command.HelpBuild) @safe @nogc pure nothrow cbHelpBuild,
	scope immutable(Out) delegate(ref immutable Command.HelpRun) @safe @nogc pure nothrow cbHelpRun,
	scope immutable(Out) delegate(ref immutable Command.Run) @safe @nogc pure nothrow cbRun,
	scope immutable(Out) delegate(ref immutable Command.Version) @safe @nogc pure nothrow cbVersion,
	*/
	return match!int(
		command,
		(ref immutable Command.Build b) =>
			build(allSymbols, nozeDir, b.programDirAndMain.programDir, b.programDirAndMain.mainPath, args.environ),
		(ref immutable Command.Help h) =>
			help(h.isDueToCommandParseError),
		(ref immutable Command.HelpBuild) =>
			helpBuild(),
		(ref immutable Command.HelpRun) =>
			helpRun(),
		(ref immutable Command.Run r) =>
			buildAndRun(
				allSymbols,
				nozeDir,
				r.programDirAndMain.programDir,
				r.programDirAndMain.mainPath,
				r.programArgs,
				args.environ),
		(ref immutable Command.Version) {
			//printf("Approximately 0.000\n");
			return 0;
		},
	);
}

@trusted immutable(int) helpBuild() {
	printf("Command: noze build [PATH]\n" ~
		"\tCompiles the program at [PATH] to a '.cpp' and executable file with the same name.\n" ~
		"\tNo options.\n");
	return 0;
}

@trusted immutable(int) helpRun() {
	printf("Command: noze run [PATH]\n" ~
		"Command: noze run [PATH] -- args\n" ~
		"\tDoes the same as 'noze build [PATH]', then runs the executable it created.\n" ~
		"\tNo options.\n" ~
		"\tArguments after `--` will be sent to the program.");
	return 0;
}

@trusted immutable(int) help(immutable Bool isDueToCommandParseError) {
	printf("Command: noze [PATH ENDING IN '.nz'] args\n" ~
		"\tSame as `noze run [PATH] -- args\n");
	helpBuild();
	printf("\n");
	helpRun();
	return isDueToCommandParseError ? 1 : 0;
}

@trusted Out match(Out)(
	ref immutable Command a,
	scope immutable(Out) delegate(ref immutable Command.Build) @safe @nogc nothrow cbBuild,
	scope immutable(Out) delegate(ref immutable Command.Help) @safe @nogc nothrow cbHelp,
	scope immutable(Out) delegate(ref immutable Command.HelpBuild) @safe @nogc nothrow cbHelpBuild,
	scope immutable(Out) delegate(ref immutable Command.HelpRun) @safe @nogc nothrow cbHelpRun,
	scope immutable(Out) delegate(ref immutable Command.Run) @safe @nogc nothrow cbRun,
	scope immutable(Out) delegate(ref immutable Command.Version) @safe @nogc nothrow cbVersion,
) {
	final switch (a.kind) {
		case Command.Kind.build:
			return cbBuild(a.build);
		case Command.Kind.help:
			return cbHelp(a.help);
		case Command.Kind.helpBuild:
			return cbHelpBuild(a.helpBuild);
		case Command.Kind.helpRun:
			return cbHelpRun(a.helpRun);
		case Command.Kind.run:
			return cbRun(a.run);
		case Command.Kind.version_:
			return cbVersion(a.version_);
	}
}

pure:

struct ProgramDirAndMain {
	immutable AbsolutePath programDir;
	immutable Ptr!Path mainPath;
}

immutable(Bool) isSpecialArg(immutable Str s, immutable string expected) {
	return Bool(!s.empty &&
		(s.at(0) == '-' ? isSpecialArg(s.tail, expected) : strEqLiteral(s, expected)));
}

immutable(Bool) isHelp(immutable Str s) {
	return isSpecialArg(s, "help");
}

struct Command {
	@safe @nogc pure nothrow:
	struct Build {
		immutable ProgramDirAndMain programDirAndMain;
	}
	struct Help {
		immutable Bool isDueToCommandParseError;
	}
	struct HelpBuild {}
	struct HelpRun {}
	// Also builds first
	struct Run {
		immutable ProgramDirAndMain programDirAndMain;
		immutable Arr!Str programArgs;
	}
	struct Version {}

	@trusted this(immutable Build a) { kind = Kind.build; build = a; }
	@trusted this(immutable Help a) { kind = Kind.help; help = a; }
	@trusted this(immutable HelpBuild a) { kind = Kind.helpBuild; helpBuild = a; }
	@trusted this(immutable HelpRun a) { kind = Kind.helpRun; helpRun = a; }
	@trusted this(immutable Run a) { kind = Kind.run; run = a; }
	@trusted this(immutable Version a) { kind = Kind.version_; version_ = a; }

	private:
	enum Kind {
		build,
		help,
		helpBuild,
		helpRun,
		run,
		version_,
	}
	immutable Kind kind;
	union {
		immutable Build build;
		immutable Help help;
		immutable HelpBuild helpBuild;
		immutable HelpRun helpRun;
		immutable Run run;
		immutable Version version_;
	}
}

immutable(AbsolutePath) parseCwdRelativePath(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref AllSymbols!SymAlloc allSymbols,
	immutable AbsolutePath cwd,
	immutable Str arg,
) {
	immutable AbsoluteOrRelPath a = parseAbsoluteOrRelPath(alloc, allSymbols, arg);
	return a.match(
		(ref immutable AbsolutePath p) => p,
		(ref immutable RelPath p) {
			immutable Opt!AbsolutePath resolved = resolvePath(alloc, cwd, p);
			return forceOrTodo(resolved);
		});
}

immutable(ProgramDirAndMain) parseProgramDirAndMain(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref AllSymbols!SymAlloc allSymbols,
	immutable AbsolutePath cwd,
	immutable Str arg,
) {
	immutable AbsolutePath mainAbsolutePath = parseCwdRelativePath(alloc, allSymbols, cwd, arg);
	immutable Opt!AbsolutePath parent = mainAbsolutePath.parent;
	immutable AbsolutePath dir = forceOrTodo(parent);
	immutable Sym name = mainAbsolutePath.baseName;
	return ProgramDirAndMain(dir, rootPath(alloc, name));
}

immutable(Command) parseBuildCommand(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref AllSymbols!SymAlloc allSymbols,
	immutable AbsolutePath cwd,
	immutable Arr!Str args,
) {
	return args.size == 1 && !isHelp(args.only)
		? Command(Command.Build(parseProgramDirAndMain(alloc, allSymbols, cwd, args.only)))
		: Command(Command.HelpBuild());
}

immutable(Command) parseRunCommand(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref AllSymbols!SymAlloc allSymbols,
	immutable AbsolutePath cwd,
	immutable Arr!Str args,
) {
	if (args.size == 0 || isHelp(args.first))
		return Command(Command.HelpRun());
	else {
		immutable ProgramDirAndMain programDirAndMain = parseProgramDirAndMain(alloc, allSymbols, cwd, args.first);
		return args.size == 1
			? Command(Command.Run(programDirAndMain, emptyArr!Str))
			: strEqLiteral(args.at(1), "--")
			? Command(Command.Run(programDirAndMain, args.slice(2)))
			: Command(Command.HelpRun());
	}
}

immutable(Command) parseCommand(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref AllSymbols!SymAlloc allSymbols,
	immutable AbsolutePath cwd,
	immutable Arr!Str args,
) {
	if (args.size == 0)
		return Command(Command.Help(True));
	else {
		immutable Str arg0 = args.first;
		return isHelp(arg0)
			? Command(Command.Help(False))
			: isSpecialArg(arg0, "version")
			? Command(Command.Version())
			: strEqLiteral(arg0, "build")
			? parseBuildCommand(alloc, allSymbols, cwd, args.tail)
			: strEqLiteral(arg0, "run")
			? parseRunCommand(alloc, allSymbols, cwd, args.tail)
			// Allow `noze foo.nz args` to translate to `noze run foo.nz -- args`
			: arg0.endsWith(".nz")
			? Command(Command.Run(parseProgramDirAndMain(alloc, allSymbols, cwd, arg0), args.tail))
			: Command(Command.Help(True));
	}
}

immutable(AbsolutePath) climbUpToNoze(immutable AbsolutePath p) {
	immutable Opt!AbsolutePath par = p.parent;
	return symEq(p.baseName, shortSymAlphaLiteral("noze"))
		? p
		: par.has
		? climbUpToNoze(par.force)
		: todo!AbsolutePath("no 'noze' directory in path");
}

immutable(AbsolutePath) getNozeDirectory(immutable AbsolutePath pathToThisExecutable) {
	immutable Opt!AbsolutePath parent = pathToThisExecutable.parent;
	return climbUpToNoze(forceOrTodo(parent));
}


