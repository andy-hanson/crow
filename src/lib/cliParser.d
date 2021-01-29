module lib.cliParser;

import frontend.lang : crowExtension;
import lib.compiler : PrintFormat, PrintKind;
import util.bools : Bool, False, True;
import util.collection.arr : Arr, at, empty, emptyArr, first, only, size;
import util.collection.arrUtil : slice, tail;
import util.collection.str : Str, strEq, strEqLiteral;
import util.opt : force, has, none, Opt, some;
import util.path : AbsolutePath, AllPaths, baseName, parentStr, parseAbsoluteOrRelPath, Path, rootPath;
import util.sym : AllSymbols, Sym;
import util.util : todo;

@safe @nogc nothrow: // not pure

@trusted Out matchCommand(Out)(
	ref immutable Command a,
	scope Out delegate(ref immutable Command.Build) @safe @nogc nothrow cbBuild,
	scope Out delegate(ref immutable Command.Help) @safe @nogc nothrow cbHelp,
	scope Out delegate(ref immutable Command.Print) @safe @nogc nothrow cbPrint,
	scope Out delegate(ref immutable Command.Run) @safe @nogc nothrow cbRun,
	scope Out delegate(ref immutable Command.Test) @safe @nogc nothrow cbTest,
) {
	final switch (a.kind) {
		case Command.Kind.build:
			return cbBuild(a.build);
		case Command.Kind.help:
			return cbHelp(a.help);
		case Command.Kind.print:
			return cbPrint(a.print);
		case Command.Kind.run:
			return cbRun(a.run);
		case Command.Kind.test:
			return cbTest(a.test);
	}
}

pure:

struct Command {
	@safe @nogc pure nothrow:
	struct Build {
		immutable ProgramDirAndMain programDirAndMain;
		immutable Arr!Str cFlags;
	}
	struct Help {
		enum Kind {
			requested,
			error,
		}
		immutable string helpText;
		immutable Kind kind;
	}
	struct Print {
		immutable PrintKind kind;
		immutable ProgramDirAndMain programDirAndMain;
		immutable PrintFormat format;
	}
	struct Run {
		immutable Build build;
		immutable Bool interpret;
		immutable Arr!Str programArgs;
	}
	struct Test {
		immutable Opt!Str name;
	}

	@trusted immutable this(immutable Build a) { kind = Kind.build; build = a; }
	@trusted immutable this(immutable Help a) { kind = Kind.help; help = a; }
	@trusted immutable this(immutable Print a) { kind = Kind.print; print = a; }
	@trusted immutable this(immutable Run a) { kind = Kind.run; run = a; }
	@trusted immutable this(immutable Test a) { kind = Kind.test; test = a; }

	private:
	enum Kind {
		build,
		help,
		print,
		run,
		test,
	}
	immutable Kind kind;
	union {
		immutable Build build;
		immutable Help help;
		immutable Print print;
		immutable Run run;
		immutable Test test;
	}
}

struct ProgramDirAndMain {
	immutable Str programDir;
	immutable Path mainPath;
}

immutable(Command) parseCommand(Alloc, PathAlloc, SymAlloc)(
	ref Alloc alloc,
	ref AllPaths!PathAlloc allPaths,
	ref AllSymbols!SymAlloc allSymbols,
	immutable Str cwd,
	immutable Arr!Str args,
) {
	if (size(args) == 0)
		return immutable Command(immutable Command.Help(helpAllText, Command.Help.Kind.error));
	else {
		immutable Str arg0 = first(args);
		immutable Arr!Str cmdArgs = tail(args);
		return isHelp(arg0)
			? immutable Command(immutable Command.Help(helpAllText, Command.Help.Kind.requested))
			: isSpecialArg(arg0, "version")
			? immutable Command(immutable Command.Help(versionText, Command.Help.Kind.requested))
			: strEqLiteral(arg0, "print")
			? parsePrintCommand(alloc, allPaths, allSymbols, cwd, cmdArgs)
			: strEqLiteral(arg0, "build")
			? parseBuildCommand(alloc, allPaths, allSymbols, cwd, cmdArgs)
			: strEqLiteral(arg0, "run")
			? parseRunCommand(alloc, allPaths, allSymbols, cwd, cmdArgs)
			: strEqLiteral(arg0, "test")
			? parseTestCommand(alloc, cmdArgs)
			: immutable Command(immutable Command.Help(helpAllText, Command.Help.Kind.error));
	}
}

private:

immutable(Bool) isSpecialArg(immutable Str a, immutable string expected) {
	return empty(a) ? True : (at(a, 0) == '-' ? isSpecialArg(tail(a), expected) : strEqLiteral(a, expected));
}

immutable(Bool) isHelp(immutable Str a) {
	return isSpecialArg(a, "help");
}

immutable(Command) useProgramDirAndMain(Alloc, PathAlloc, SymAlloc)(
	ref Alloc alloc,
	ref AllPaths!PathAlloc allPaths,
	ref AllSymbols!SymAlloc allSymbols,
	immutable Str cwd,
	immutable Str arg,
	scope immutable(Command) delegate(ref immutable ProgramDirAndMain) @safe pure @nogc nothrow cb,
) {
	immutable Opt!ProgramDirAndMain p = parseProgramDirAndMain(alloc, allPaths, allSymbols, cwd, arg);
	return has(p)
		? cb(force(p))
		: immutable Command(immutable Command.Help("Invalid path", Command.Help.Kind.error));
}

immutable(Opt!ProgramDirAndMain) parseProgramDirAndMain(Alloc, PathAlloc, SymAlloc)(
	ref Alloc alloc,
	ref AllPaths!PathAlloc allPaths,
	ref AllSymbols!SymAlloc allSymbols,
	immutable Str cwd,
	immutable Str arg,
) {
	immutable Opt!AbsolutePath mainAbsolutePathOption = parseAbsoluteOrRelPath(allPaths, allSymbols, cwd, arg);
	if (!has(mainAbsolutePathOption))
		return none!ProgramDirAndMain;
	else {
		immutable AbsolutePath mainAbsolutePath = force(mainAbsolutePathOption);
		immutable Str dir = parentStr(alloc, allPaths, mainAbsolutePath);
		immutable Sym name = baseName(allPaths, mainAbsolutePath);
		return empty(mainAbsolutePath.extension) || strEq(mainAbsolutePath.extension, crowExtension())
			? some(immutable ProgramDirAndMain(dir, rootPath(allPaths, name)))
			: none!ProgramDirAndMain;
	}
}

struct FormatAndPath {
	immutable PrintFormat format;
	immutable Str path;
}

immutable(Command) parsePrintCommand(Alloc, PathAlloc, SymAlloc)(
	ref Alloc alloc,
	ref AllPaths!PathAlloc allPaths,
	ref AllSymbols!SymAlloc allSymbols,
	ref immutable Str cwd,
	ref immutable Arr!Str args,
) {

	if (size(args) < 2)
		return todo!Command("Command.HelpPrint");
	else {
		immutable FormatAndPath formatAndPath = size(args) == 2
			? immutable FormatAndPath(PrintFormat.repr, at(args, 1))
			: size(args) == 4 && strEqLiteral(at(args, 1), "--format") && strEqLiteral(at(args, 2), "json")
			? immutable FormatAndPath(PrintFormat.json, at(args, 3))
			: todo!(immutable FormatAndPath)("Command.HelpPrint");
		return useProgramDirAndMain(
			alloc,
			allPaths,
			allSymbols,
			cwd,
			formatAndPath.path,
			(ref immutable ProgramDirAndMain it) =>
				immutable Command(immutable Command.Print(
					parsePrintKind(first(args)),
					it,
					formatAndPath.format)));
	}
}

immutable(PrintKind) parsePrintKind(immutable Str a) {
	return strEqLiteral(a, "tokens")
		? PrintKind.tokens
		: strEqLiteral(a, "ast")
		? PrintKind.ast
		: strEqLiteral(a, "model")
		? PrintKind.model
		: strEqLiteral(a, "concrete-model")
		? PrintKind.concreteModel
		: strEqLiteral(a, "low-model")
		? PrintKind.lowModel
		: todo!(immutable PrintKind)("parsePrintKind");
}

immutable(Command) parseBuildCommand(Alloc, PathAlloc, SymAlloc)(
	ref Alloc alloc,
	ref AllPaths!PathAlloc allPaths,
	ref AllSymbols!SymAlloc allSymbols,
	ref immutable Str cwd,
	ref immutable Arr!Str args,
) {
	return size(args) == 1 && !isHelp(args.only)
		? useProgramDirAndMain(alloc, allPaths, allSymbols, cwd, args.only, (ref immutable ProgramDirAndMain it) =>
			immutable Command(immutable Command.Build(it, emptyArr!Str)))
		: immutable Command(immutable Command.Help(helpBuildText, Command.Help.Kind.error));
}

immutable(Command) parseRunCommand(Alloc, PathAlloc, SymAlloc)(
	ref Alloc alloc,
	ref AllPaths!PathAlloc allPaths,
	ref AllSymbols!SymAlloc allSymbols,
	immutable Str cwd,
	immutable Arr!Str args,
) {
	return size(args) == 0 || isHelp(args.first)
		? immutable Command(immutable Command.Help(helpRunText, Command.Help.Kind.requested))
		: useProgramDirAndMain(
			alloc,
			allPaths,
			allSymbols,
			cwd,
			first(args),
			(ref immutable ProgramDirAndMain programDirAndMain) {
				immutable Arr!Str argsAfterMain = tail(args);
				struct InterpretAndRemainingArgs {
					immutable Bool interpret;
					immutable Arr!Str remainingArgs;
				}
				immutable InterpretAndRemainingArgs ira =
					!empty(argsAfterMain) && strEqLiteral(at(argsAfterMain, 0), "--interpret")
						? immutable InterpretAndRemainingArgs(True, tail(argsAfterMain))
						: immutable InterpretAndRemainingArgs(False, argsAfterMain);
				return empty(ira.remainingArgs)
					? immutable Command(immutable Command.Run(
						immutable Command.Build(programDirAndMain, emptyArr!Str),
						ira.interpret,
						emptyArr!Str))
					: strEqLiteral(at(ira.remainingArgs, 0), "--")
					? immutable Command(immutable Command.Run(
						immutable Command.Build(programDirAndMain, emptyArr!Str),
						ira.interpret,
						slice(ira.remainingArgs, 1)))
					: immutable Command(immutable Command.Help(helpRunText, Command.Help.Kind.error));
			});
}

immutable(Command) parseTestCommand(Alloc)(ref Alloc alloc, immutable Arr!Str args) {
	if (empty(args))
		return immutable Command(immutable Command.Test(none!Str));
	else if (size(args) == 1)
		return immutable Command(immutable Command.Test(some(first(args))));
	else
		return immutable Command(immutable Command.Help(helpAllText, Command.Help.Kind.error));
}

immutable string versionText =
	"Approximately 0.000";

immutable string helpAllText =
	"Commands: (type a command then '--help' to see more)\n" ~
	"\t'crow build'\n" ~
	"\t'crow run'\n" ~
	"\t'crow version'";

immutable string helpBuildText =
	"Command: crow build [PATH]\n" ~
	"\tCompiles the program at [PATH] to a '.cpp' and executable file with the same name.\n" ~
	"\tNo options.";

immutable string helpRunText =
	"Command: crow run [PATH] [build args] -- [programArgs]\n" ~
	"\tBuild args are same as for 'crow build'.\n" ~
	"Arguments after '--' will be sent to the program.";
