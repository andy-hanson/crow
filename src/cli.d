module cli;

import core.stdc.stdio : printf;

import compiler : build, buildAndRun, printAst, ProgramDirAndMain;
import frontend.lang : nozeExtension;

import util.alloc.mallocator : Mallocator;
import util.alloc.stackAlloc : SingleHeapAlloc, StackAlloc;
import util.bools : Bool, False, True;
import util.collection.arr : Arr, at, empty, emptyArr, first, only, size;
import util.collection.arrUtil : slice, sliceFromTo, tail;
import util.collection.str : CStr, endsWith, Str, strEqLiteral, strLiteral;
import util.io : getCwd, parseCommandLineArgs, CommandLineArgs;
import util.opt : force, forceOrTodo, has, Opt;
import util.path :
	AbsolutePath,
	baseName,
	parseAbsoluteOrRelPath,
	parent,
	Path,
	pathBaseName,
	pathParent,
	pathToStr,
	RelPath,
	resolvePath,
	rootPath;
import util.ptr : Ptr, ptrTrustMe_mut;
import util.sym : AllSymbols, shortSymAlphaLiteral, Sym, symEq;
import util.util : todo;

@safe @nogc nothrow: // not pure

int cli(immutable size_t argc, immutable CStr* argv) {
	Mallocator mallocator;
	CliAlloc alloc;
	alias SymAlloc = SingleHeapAlloc!(Mallocator, "symAlloc", 1024 * 1024);
	SymAlloc symAlloc = SymAlloc(ptrTrustMe_mut(mallocator));
	immutable CommandLineArgs args = parseCommandLineArgs(alloc, argc, argv);
	AllSymbols!SymAlloc allSymbols = AllSymbols!SymAlloc(symAlloc);
	return go(allSymbols, args);
}

private:

alias CliAlloc = StackAlloc!("commandLineArgs", 32 * 1024);

immutable(int) go(SymAlloc)(ref AllSymbols!SymAlloc allSymbols, ref immutable CommandLineArgs args) {
	StackAlloc!("command", 1024) alloc;
	immutable Str nozeDir = getNozeDirectory(args.pathToThisExecutable);
	immutable Command command = parseCommand(alloc, allSymbols, getCwd(alloc), args.args);
	return match!int(
		command,
		(ref immutable Command.Ast a) =>
			printAst(allSymbols, a.programDirAndMain),
		(ref immutable Command.Build b) =>
			build(allSymbols, nozeDir, b.programDirAndMain, args.environ),
		(ref immutable Command.Help h) =>
			help(h.isDueToCommandParseError),
		(ref immutable Command.HelpBuild) =>
			helpBuild(),
		(ref immutable Command.HelpRun) =>
			helpRun(),
		(ref immutable Command.Run r) =>
			buildAndRun(allSymbols, nozeDir, r.programDirAndMain, r.programArgs, args.environ),
		(ref immutable Command.Version) {
			printVersion();
			return 0;
		},
	);
}

@trusted void printVersion() {
	printf("Approximately 0.000\n");
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
		"\tArguments after `--` will be sent to the program.\n");
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
	scope immutable(Out) delegate(ref immutable Command.Ast) @safe @nogc nothrow cbAst,
	scope immutable(Out) delegate(ref immutable Command.Build) @safe @nogc nothrow cbBuild,
	scope immutable(Out) delegate(ref immutable Command.Help) @safe @nogc nothrow cbHelp,
	scope immutable(Out) delegate(ref immutable Command.HelpBuild) @safe @nogc nothrow cbHelpBuild,
	scope immutable(Out) delegate(ref immutable Command.HelpRun) @safe @nogc nothrow cbHelpRun,
	scope immutable(Out) delegate(ref immutable Command.Run) @safe @nogc nothrow cbRun,
	scope immutable(Out) delegate(ref immutable Command.Version) @safe @nogc nothrow cbVersion,
) {
	final switch (a.kind) {
		case Command.Kind.ast:
			return cbAst(a.ast);
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

immutable(Bool) isSpecialArg(immutable Str s, immutable string expected) {
	return Bool(!s.empty &&
		(s.at(0) == '-' ? isSpecialArg(s.tail, expected) : strEqLiteral(s, expected)));
}

immutable(Bool) isHelp(immutable Str s) {
	return isSpecialArg(s, "help");
}

struct Command {
	@safe @nogc pure nothrow:
	struct Ast {
		immutable ProgramDirAndMain programDirAndMain;
	}
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

	@trusted this(immutable Ast a) { kind = Kind.ast; ast = a; }
	@trusted this(immutable Build a) { kind = Kind.build; build = a; }
	@trusted this(immutable Help a) { kind = Kind.help; help = a; }
	@trusted this(immutable HelpBuild a) { kind = Kind.helpBuild; helpBuild = a; }
	@trusted this(immutable HelpRun a) { kind = Kind.helpRun; helpRun = a; }
	@trusted this(immutable Run a) { kind = Kind.run; run = a; }
	@trusted this(immutable Version a) { kind = Kind.version_; version_ = a; }

	private:
	enum Kind {
		ast,
		build,
		help,
		helpBuild,
		helpRun,
		run,
		version_,
	}
	immutable Kind kind;
	union {
		immutable Ast ast;
		immutable Build build;
		immutable Help help;
		immutable HelpBuild helpBuild;
		immutable HelpRun helpRun;
		immutable Run run;
		immutable Version version_;
	}
}

immutable(ProgramDirAndMain) parseProgramDirAndMain(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref AllSymbols!SymAlloc allSymbols,
	immutable Str cwd,
	immutable Str arg,
) {
	immutable Opt!AbsolutePath mainAbsolutePathOption = parseAbsoluteOrRelPath(alloc, allSymbols, cwd, arg);
	immutable AbsolutePath mainAbsolutePath = forceOrTodo(mainAbsolutePathOption);
	immutable Opt!AbsolutePath parent = mainAbsolutePath.parent;
	immutable Str dir = pathToStr(alloc, forceOrTodo(parent));
	immutable Sym name = mainAbsolutePath.baseName;
	return ProgramDirAndMain(dir, rootPath(alloc, name));
}

immutable(Command) parseAstCommand(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref AllSymbols!SymAlloc allSymbols,
	immutable Str cwd,
	immutable Arr!Str args,
) {
	return args.size == 1 && !isHelp(args.only)
		? Command(Command.Ast(parseProgramDirAndMain(alloc, allSymbols, cwd, args.only)))
		: todo!Command("Command.HelpAst");
}

immutable(Command) parseBuildCommand(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref AllSymbols!SymAlloc allSymbols,
	immutable Str cwd,
	immutable Arr!Str args,
) {
	return args.size == 1 && !isHelp(args.only)
		? Command(Command.Build(parseProgramDirAndMain(alloc, allSymbols, cwd, args.only)))
		: Command(Command.HelpBuild());
}

immutable(Command) parseRunCommand(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref AllSymbols!SymAlloc allSymbols,
	immutable Str cwd,
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
	immutable Str cwd,
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
			: strEqLiteral(arg0, "ast")
			? parseAstCommand(alloc, allSymbols, cwd, args.tail)
			: strEqLiteral(arg0, "build")
			? parseBuildCommand(alloc, allSymbols, cwd, args.tail)
			: strEqLiteral(arg0, "run")
			? parseRunCommand(alloc, allSymbols, cwd, args.tail)
			// Allow `noze foo.nz args` to translate to `noze run foo.nz -- args`
			: endsWith(arg0, nozeExtension)
			? Command(Command.Run(parseProgramDirAndMain(alloc, allSymbols, cwd, arg0), args.tail))
			: Command(Command.Help(True));
	}
}

immutable(Str) climbUpToNoze(immutable Str p) {
	immutable Opt!Str par = pathParent(p);
	immutable Opt!Str bn = pathBaseName(p);
	return strEqLiteral(bn.forceOrTodo, "noze")
		? p
		: par.has
		? climbUpToNoze(par.force)
		: todo!Str("no 'noze' directory in path");
}

immutable(Str) getNozeDirectory(immutable Str pathToThisExecutable) {
	immutable Opt!Str parent = pathParent(pathToThisExecutable);
	return climbUpToNoze(forceOrTodo(parent));
}


