module cli;

import core.stdc.stdio : fprintf, printf, stderr;

import compiler :
	buildAndInterpret,
	buildToC,
	DiagsAndResultStrs,
	getAbsolutePathFromStorage,
	print,
	PrintFormat,
	PrintKind;
import frontend.lang : nozeExtension;
import frontend.showDiag : ShowDiagOptions;
import io.io :
	CommandLineArgs,
	Environ,
	getCwd,
	parseCommandLineArgs,
	replaceCurrentProcess,
	spawnAndWaitSync,
	writeFileSync;
import io.mallocator : Mallocator;
import io.realExtern : newRealExtern, RealExtern;
import io.realReadOnlyStorage : RealReadOnlyStorage;
import test.test : test;
import util.bools : Bool, False, True;
import util.collection.arr : Arr, at, begin, empty, emptyArr, first, only, size;
import util.collection.arrUtil : arrLiteral, cat, slice, tail;
import util.collection.str : CStr, emptyStr, endsWith, Str, strLiteral, strEqLiteral;
import util.opt : force, forceOrTodo, has, none, Opt, some;
import util.path :
	AbsolutePath,
	baseName,
	parentStr,
	parseAbsoluteOrRelPath,
	Path,
	pathBaseName,
	pathParent,
	pathToStr,
	rootPath,
	withExtension;
import util.ptr : Ptr, ptrTrustMe_mut;
import util.result : matchResultImpure, Result;
import util.sym : AllSymbols, shortSymAlphaLiteral, Sym;
import util.util : todo, unreachable;

@safe @nogc nothrow: // not pure

int cli(immutable size_t argc, immutable CStr* argv) {
	Mallocator mallocator;
	immutable CommandLineArgs args = parseCommandLineArgs(mallocator, argc, argv);
	AllSymbols!Mallocator allSymbols = AllSymbols!Mallocator(ptrTrustMe_mut(mallocator));
	return go(mallocator, allSymbols, args);
}

private:

immutable(int) go(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref AllSymbols!SymAlloc allSymbols,
	ref immutable CommandLineArgs args,
) {
	immutable Str nozeDir = getNozeDirectory(args.pathToThisExecutable);
	immutable Command command = parseCommand(alloc, allSymbols, getCwd(alloc), args.args);
	immutable Str include = cat(alloc, nozeDir, strLiteral("/include"));
	immutable ShowDiagOptions showDiagOptions = immutable ShowDiagOptions(True);

	return matchCommand!int(
		command,
		(ref immutable Command.Build it) {
			immutable Opt!AbsolutePath exePath =
				buildToCAndCompile(alloc, allSymbols, showDiagOptions, it.programDirAndMain, include, args.environ);
			return has(exePath) ? 0 : 1;
		},
		(ref immutable Command.Help it) =>
			help(it.isDueToCommandParseError),
		(ref immutable Command.HelpBuild) {
			helpBuild();
			return 0;
		},
		(ref immutable Command.HelpRun) {
			helpRun();
			return 0;
		},
		(ref immutable Command.Print it) {
			RealReadOnlyStorage!Alloc storage =
				RealReadOnlyStorage!Alloc(ptrTrustMe_mut(alloc), include, it.programDirAndMain.programDir);
			immutable DiagsAndResultStrs printed =
				print(alloc, allSymbols, storage, showDiagOptions, it.kind, it.format, it.programDirAndMain.mainPath);
			if (!empty(printed.diagnostics)) printErr(printed.diagnostics);
			if (!empty(printed.result)) print(printed.result);
			return empty(printed.diagnostics) ? 0 : 1;
		},
		(ref immutable Command.Run it) {
			RealReadOnlyStorage!Alloc storage =
				RealReadOnlyStorage!Alloc(ptrTrustMe_mut(alloc), include, it.programDirAndMain.programDir);
			if (it.interpret) {
				RealExtern extern_ = newRealExtern();
				return buildAndInterpret(
					alloc,
					allSymbols,
					storage,
					extern_,
					showDiagOptions,
					it.programDirAndMain.mainPath,
					it.programArgs);
			} else {
				immutable Opt!AbsolutePath exePath =
					buildToCAndCompile(alloc, allSymbols, showDiagOptions, it.programDirAndMain, include, args.environ);
				if (!has(exePath))
					return 1;
				else {
					replaceCurrentProcess(alloc, force(exePath), it.programArgs, args.environ);
					return unreachable!int();
				}
			}
		},
		(ref immutable Command.Test it) =>
			test(alloc, it.name),
		(ref immutable Command.Version) {
			printVersion();
			return 0;
		});
}

immutable(Opt!AbsolutePath) buildToCAndCompile(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref AllSymbols!SymAlloc allSymbols,
	ref immutable ShowDiagOptions showDiagOptions,
	ref immutable ProgramDirAndMain programDirAndMain,
	ref immutable Str include,
	ref immutable Environ environ,
) {
	RealReadOnlyStorage!Alloc storage =
		RealReadOnlyStorage!Alloc(ptrTrustMe_mut(alloc), include, programDirAndMain.programDir);
	immutable AbsolutePath cPath =
		getAbsolutePathFromStorage(alloc, storage, programDirAndMain.mainPath, strLiteral(".c"));
	immutable Result!(Str, Str) result =
		buildToC(alloc, allSymbols, storage, showDiagOptions, programDirAndMain.mainPath);
	return matchResultImpure!(immutable Opt!AbsolutePath, Str, Str)(
		result,
		(ref immutable Str cCode) {
			writeFileSync(alloc, cPath, cCode);
			immutable AbsolutePath exePath = withExtension(cPath, emptyStr);
			compileC(alloc, cPath, exePath, environ);
			return some(exePath);
		},
		(ref immutable Str diagnostics) {
			printErr(diagnostics);
			return none!AbsolutePath;
		});
}

void printVersion() {
	print("Approximately 0.000\n");
}

void helpBuild() {
	print("Command: noze build [PATH]\n" ~
		"\tCompiles the program at [PATH] to a '.cpp' and executable file with the same name.\n" ~
		"\tNo options.\n");
}

void helpRun() {
	print("Command: noze run [PATH]\n" ~
		"Command: noze run [PATH] -- args\n" ~
		"\tDoes the same as 'noze build [PATH]', then runs the executable it created.\n" ~
		"\tNo options.\n" ~
		"\tArguments after `--` will be sent to the program.\n");
}

immutable(int) help(immutable Bool isDueToCommandParseError) {
	print("Command: noze [PATH ENDING IN '.nz'] args\n" ~
		"\tSame as `noze run [PATH] -- args\n");
	helpBuild();
	print("\n");
	helpRun();
	return isDueToCommandParseError ? 1 : 0;
}

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

void compileC(Alloc)(
	ref Alloc alloc,
	ref immutable AbsolutePath cPath,
	ref immutable AbsolutePath exePath,
	ref immutable Environ environ,
) {
	immutable AbsolutePath cCompiler =
		AbsolutePath(strLiteral("/usr/bin"), rootPath(alloc, shortSymAlphaLiteral("cc")), emptyStr);
	immutable Arr!Str args = arrLiteral!Str(
		alloc,
		strLiteral("-Werror"),
		strLiteral("-Wextra"),
		strLiteral("-Wall"),
		strLiteral("-ansi"),
		// strLiteral("-pedantic"), // TODO?
		strLiteral("-std=c11"),
		strLiteral("-Wno-unused-parameter"),
		strLiteral("-Wno-unused-but-set-variable"),
		strLiteral("-Wno-unused-variable"),
		strLiteral("-Wno-unused-value"),
		strLiteral("-Wno-builtin-declaration-mismatch"), //TODO:KILL?
		strLiteral("-pthread"),
		strLiteral("-lSDL2"),
		// TODO: configurable whether we want debug or release
		strLiteral("-g"),
		pathToStr(alloc, cPath),
		strLiteral("-o"),
		pathToStr(alloc, exePath));
	immutable int err = spawnAndWaitSync(alloc, cCompiler, args, environ);
	if (err != 0)
		todo!void("C compile error");
}

@trusted void print(immutable Str a) {
	printf("%.*s", cast(int) size(a), begin(a));
}

void print(immutable string a) {
	print(strLiteral(a));
}

@trusted void printErr(immutable Str a) {
	fprintf(stderr, "%.*s", cast(int) size(a), begin(a));
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
	immutable Ptr!Path mainPath;
}

immutable(ProgramDirAndMain) parseProgramDirAndMain(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref AllSymbols!SymAlloc allSymbols,
	immutable Str cwd,
	immutable Str arg,
) {
	immutable Opt!AbsolutePath mainAbsolutePathOption = parseAbsoluteOrRelPath(alloc, allSymbols, cwd, arg);
	immutable AbsolutePath mainAbsolutePath = forceOrTodo(mainAbsolutePathOption);
	immutable Str dir = parentStr(alloc, mainAbsolutePath);
	immutable Sym name = mainAbsolutePath.baseName;
	return ProgramDirAndMain(dir, rootPath(alloc, name));
}

struct FormatAndPath {
	immutable PrintFormat format;
	immutable Str path;
}

immutable(Command) parsePrintCommand(Alloc, SymAlloc)(
	ref Alloc alloc,
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
			parseProgramDirAndMain(alloc, allSymbols, cwd, formatAndPath.path),
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

immutable(Command) parseBuildCommand(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref AllSymbols!SymAlloc allSymbols,
	ref immutable Str cwd,
	ref immutable Arr!Str args,
) {
	return args.size == 1 && !isHelp(args.only)
		? immutable Command(Command.Build(parseProgramDirAndMain(alloc, allSymbols, cwd, args.only)))
		: immutable Command(Command.HelpBuild());
}

immutable(Command) parseRunCommand(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref AllSymbols!SymAlloc allSymbols,
	immutable Str cwd,
	immutable Arr!Str args,
) {
	if (args.size == 0 || isHelp(args.first))
		return immutable Command(Command.HelpRun());
	else {
		immutable ProgramDirAndMain programDirAndMain = parseProgramDirAndMain(alloc, allSymbols, cwd, first(args));
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
			: strEqLiteral(ira.remainingArgs.at(0), "--")
			? immutable Command(Command.Run(ira.interpret, programDirAndMain, ira.remainingArgs.slice(1)))
			: immutable Command(Command.HelpRun());
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
		immutable Str arg0 = first(args);
		immutable Arr!Str cmdArgs = tail(args);
		return isHelp(arg0)
			? Command(Command.Help(False))
			: isSpecialArg(arg0, "version")
			? Command(Command.Version())
			: strEqLiteral(arg0, "print")
			? parsePrintCommand(alloc, allSymbols, cwd, cmdArgs)
			: strEqLiteral(arg0, "build")
			? parseBuildCommand(alloc, allSymbols, cwd, cmdArgs)
			: strEqLiteral(arg0, "run")
			? parseRunCommand(alloc, allSymbols, cwd, cmdArgs)
			: strEqLiteral(arg0, "test")
			? parseTestCommand(alloc, cmdArgs)
			// Allow `noze foo.nz args` to translate to `noze run foo.nz -- args`
			: endsWith(arg0, nozeExtension)
			? immutable Command(Command.Run(True, parseProgramDirAndMain(alloc, allSymbols, cwd, arg0), args.tail))
			: immutable Command(Command.Help(True));
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
