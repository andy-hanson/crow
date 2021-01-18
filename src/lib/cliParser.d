module lib.cliParser;

import lib.compiler : PrintFormat, PrintKind;
import util.bools : Bool, False, True;
import util.collection.arr : Arr, at, empty, emptyArr, first, only, size;
import util.collection.arrUtil : slice, tail;
import util.collection.str : Str, strEqLiteral;
import util.opt : forceOrTodo, none, Opt, some;
import util.path : AbsolutePath, AllPaths, baseName, parentStr, parseAbsoluteOrRelPath, Path, rootPath;
import util.sym : AllSymbols, Sym;
import util.util : todo;

@safe @nogc nothrow: // not pure

@trusted Out matchCommand(Out)(
	ref immutable Command a,
	scope immutable(Out) delegate(ref immutable Command.Build) @safe @nogc nothrow cbBuild,
	scope immutable(Out) delegate(ref immutable Command.Help) @safe @nogc nothrow cbHelp,
	scope immutable(Out) delegate(ref immutable Command.Print) @safe @nogc nothrow cbPrint,
	scope immutable(Out) delegate(ref immutable Command.Run) @safe @nogc nothrow cbRun,
	scope immutable(Out) delegate(ref immutable Command.Test) @safe @nogc nothrow cbTest,
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
		immutable string helpText;
		immutable Bool isDueToCommandParseError;
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
		return immutable Command(immutable Command.Help(helpAllText, True));
	else {
		immutable Str arg0 = first(args);
		immutable Arr!Str cmdArgs = tail(args);
		return isHelp(arg0)
			? immutable Command(immutable Command.Help(helpAllText, False))
			: isSpecialArg(arg0, "version")
			? immutable Command(immutable Command.Help(versionText, False))
			: strEqLiteral(arg0, "print")
			? parsePrintCommand(alloc, allPaths, allSymbols, cwd, cmdArgs)
			: strEqLiteral(arg0, "build")
			? parseBuildCommand(alloc, allPaths, allSymbols, cwd, cmdArgs)
			: strEqLiteral(arg0, "run")
			? parseRunCommand(alloc, allPaths, allSymbols, cwd, cmdArgs)
			: strEqLiteral(arg0, "test")
			? parseTestCommand(alloc, cmdArgs)
			: immutable Command(immutable Command.Help(helpAllText, True));
	}
}

private:

immutable(Bool) isSpecialArg(immutable Str a, immutable string expected) {
	return empty(a) ? True : (at(a, 0) == '-' ? isSpecialArg(tail(a), expected) : strEqLiteral(a, expected));
}

immutable(Bool) isHelp(immutable Str a) {
	return isSpecialArg(a, "help");
}

immutable(ProgramDirAndMain) parseProgramDirAndMain(Alloc, PathAlloc, SymAlloc)(
	ref Alloc alloc,
	ref AllPaths!PathAlloc allPaths,
	ref AllSymbols!SymAlloc allSymbols,
	immutable Str cwd,
	immutable Str arg,
) {
	immutable Opt!AbsolutePath mainAbsolutePathOption = parseAbsoluteOrRelPath(allPaths, allSymbols, cwd, arg);
	immutable AbsolutePath mainAbsolutePath = forceOrTodo(mainAbsolutePathOption);
	immutable Str dir = parentStr(alloc, allPaths, mainAbsolutePath);
	immutable Sym name = baseName(allPaths, mainAbsolutePath);
	return immutable ProgramDirAndMain(dir, rootPath(allPaths, name));
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
			? immutable FormatAndPath(PrintFormat.sexpr, at(args, 1))
			: size(args) == 4 && strEqLiteral(at(args, 1), "--format") && strEqLiteral(at(args, 2), "json")
			? immutable FormatAndPath(PrintFormat.json, at(args, 3))
			: todo!(immutable FormatAndPath)("Command.HelpPrint");
		return immutable Command(Command.Print(
			parsePrintKind(first(args)),
			parseProgramDirAndMain(alloc, allPaths, allSymbols, cwd, formatAndPath.path),
			formatAndPath.format));
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
		? immutable Command(immutable Command.Build(
			parseProgramDirAndMain(alloc, allPaths, allSymbols, cwd, args.only),
			emptyArr!Str))
		: immutable Command(immutable Command.Help(helpBuildText, True));
}

immutable(Command) parseRunCommand(Alloc, PathAlloc, SymAlloc)(
	ref Alloc alloc,
	ref AllPaths!PathAlloc allPaths,
	ref AllSymbols!SymAlloc allSymbols,
	immutable Str cwd,
	immutable Arr!Str args,
) {
	if (size(args) == 0 || isHelp(args.first))
		return immutable Command(immutable Command.Help(helpRunText, False));
	else {
		immutable ProgramDirAndMain programDirAndMain =
			parseProgramDirAndMain(alloc, allPaths, allSymbols, cwd, first(args));
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
			: immutable Command(immutable Command.Help(helpRunText, True));
	}
}

immutable(Command) parseTestCommand(Alloc)(ref Alloc alloc, immutable Arr!Str args) {
	if (empty(args))
		return immutable Command(immutable Command.Test(none!Str));
	else if (size(args) == 1)
		return immutable Command(immutable Command.Test(some(first(args))));
	else
		return immutable Command(immutable Command.Help(helpAllText, True));
}

immutable string versionText =
	"Approximately 0.000\n";

immutable string helpAllText =
	"Commands: (type a command then '--help' to see more)\n" ~
	"\t'noze build'\n" ~
	"\t'noze run'\n" ~
	"\t'noze version'\n";

immutable string helpBuildText =
	"Command: noze build [PATH]\n" ~
	"\tCompiles the program at [PATH] to a '.cpp' and executable file with the same name.\n" ~
	"\tNo options.\n";

immutable string helpRunText =
	"Command: noze run [PATH] [build args] -- [programArgs]\n" ~
	"\tBuild args are same as for 'noze build'.\n" ~
	"Arguments after '--' will be sent to the program.";
