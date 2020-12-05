module lib.cliParser;

import lib.compiler : PrintFormat, PrintKind;
import frontend.lang : nozeExtension;
import util.bools : Bool, False, True;
import util.collection.arr : Arr, at, empty, emptyArr, first, only, size;
import util.collection.arrUtil : slice, tail;
import util.collection.str : endsWith, Str, strEqLiteral;
import util.opt : forceOrTodo, none, Opt, some;
import util.path : AbsolutePath, AllPaths, baseName, parentStr, parseAbsoluteOrRelPath, Path, rootPath;
import util.sym : AllSymbols, Sym;
import util.util : todo;

@safe @nogc nothrow: // not pure

@trusted Out matchCommand(Out)(
	ref immutable Command a,
	scope immutable(Out) delegate(ref immutable Command.Build) @safe @nogc nothrow cbBuild,
	scope immutable(Out) delegate(ref immutable Command.Help) @safe @nogc nothrow cbHelp,
	scope immutable(Out) delegate(ref immutable Command.HelpBuild) @safe @nogc nothrow cbHelpBuild,
	scope immutable(Out) delegate(ref immutable Command.HelpRun) @safe @nogc nothrow cbHelpRun,
	scope immutable(Out) delegate(ref immutable Command.Print) @safe @nogc nothrow cbPrint,
	scope immutable(Out) delegate(ref immutable Command.Run) @safe @nogc nothrow cbRun,
	scope immutable(Out) delegate(ref immutable Command.Test) @safe @nogc nothrow cbTest,
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
		case Command.Kind.print:
			return cbPrint(a.print);
		case Command.Kind.run:
			return cbRun(a.run);
		case Command.Kind.test:
			return cbTest(a.test);
		case Command.Kind.version_:
			return cbVersion(a.version_);
	}
}

pure:

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
	struct Print {
		immutable PrintKind kind;
		immutable ProgramDirAndMain programDirAndMain;
		immutable PrintFormat format;
	}
	// Also builds first
	struct Run {
		immutable Bool interpret;
		immutable ProgramDirAndMain programDirAndMain;
		immutable Arr!Str programArgs;
	}
	struct Test {
		immutable Opt!Str name;
	}
	struct Version {}

	@trusted immutable this(immutable Build a) { kind = Kind.build; build = a; }
	@trusted immutable this(immutable Help a) { kind = Kind.help; help = a; }
	@trusted immutable this(immutable HelpBuild a) { kind = Kind.helpBuild; helpBuild = a; }
	@trusted immutable this(immutable HelpRun a) { kind = Kind.helpRun; helpRun = a; }
	@trusted immutable this(immutable Print a) { kind = Kind.print; print = a; }
	@trusted immutable this(immutable Run a) { kind = Kind.run; run = a; }
	@trusted immutable this(immutable Test a) { kind = Kind.test; test = a; }
	@trusted immutable this(immutable Version a) { kind = Kind.version_; version_ = a; }

	private:
	enum Kind {
		build,
		help,
		helpBuild,
		helpRun,
		print,
		run,
		test,
		version_,
	}
	immutable Kind kind;
	union {
		immutable Build build;
		immutable Help help;
		immutable HelpBuild helpBuild;
		immutable HelpRun helpRun;
		immutable Print print;
		immutable Run run;
		immutable Test test;
		immutable Version version_;
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
		return Command(Command.Help(True));
	else {
		immutable Str arg0 = first(args);
		immutable Arr!Str cmdArgs = tail(args);
		return isHelp(arg0)
			? Command(Command.Help(False))
			: isSpecialArg(arg0, "version")
			? Command(Command.Version())
			: strEqLiteral(arg0, "print")
			? parsePrintCommand(alloc, allPaths, allSymbols, cwd, cmdArgs)
			: strEqLiteral(arg0, "build")
			? parseBuildCommand(alloc, allPaths, allSymbols, cwd, cmdArgs)
			: strEqLiteral(arg0, "run")
			? parseRunCommand(alloc, allPaths, allSymbols, cwd, cmdArgs)
			: strEqLiteral(arg0, "test")
			? parseTestCommand(alloc, cmdArgs)
			// Allow `noze foo.nz args` to translate to `noze run foo.nz -- args`
			: endsWith(arg0, nozeExtension)
			? immutable Command(immutable Command.Run(
				True,
				parseProgramDirAndMain(alloc, allPaths, allSymbols, cwd, arg0),
				args.tail))
			: immutable Command(immutable Command.Help(True));
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
		? immutable Command(Command.Build(parseProgramDirAndMain(alloc, allPaths, allSymbols, cwd, args.only)))
		: immutable Command(Command.HelpBuild());
}

immutable(Command) parseRunCommand(Alloc, PathAlloc, SymAlloc)(
	ref Alloc alloc,
	ref AllPaths!PathAlloc allPaths,
	ref AllSymbols!SymAlloc allSymbols,
	immutable Str cwd,
	immutable Arr!Str args,
) {
	if (size(args) == 0 || isHelp(args.first))
		return immutable Command(Command.HelpRun());
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
			? immutable Command(Command.Run(ira.interpret, programDirAndMain, emptyArr!Str))
			: strEqLiteral(at(ira.remainingArgs, 0), "--")
			? immutable Command(Command.Run(ira.interpret, programDirAndMain, ira.remainingArgs.slice(1)))
			: immutable Command(Command.HelpRun());
	}
}

immutable(Command) parseTestCommand(Alloc)(ref Alloc alloc, immutable Arr!Str args) {
	if (empty(args))
		return immutable Command(immutable Command.Test(none!Str));
	else if (size(args) == 1)
		return immutable Command(immutable Command.Test(some(first(args))));
	else
		return immutable Command(immutable Command.Help(True));
}
