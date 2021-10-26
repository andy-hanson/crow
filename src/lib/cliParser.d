module lib.cliParser;

import frontend.lang : crowExtension;
import lib.compiler : PrintFormat, PrintKind;
import util.alloc.alloc : Alloc;
import util.collection.arr : at, empty, emptyArr, first, only, size;
import util.collection.arrBuilder : add, ArrBuilder, finishArr;
import util.collection.arrUtil : findIndex, foldOrStop, tail;
import util.collection.str : startsWith, strEq;
import util.opt : force, has, none, Opt, some;
import util.path : AbsolutePath, AllPaths, parseAbsoluteOrRelPath, Path;
import util.util : todo;

@safe @nogc nothrow: // not pure

@trusted Out matchCommand(Out)(
	ref immutable Command a,
	scope Out delegate(ref immutable Command.Build) @safe @nogc nothrow cbBuild,
	scope Out delegate(ref immutable Command.Document) @safe @nogc nothrow cbDocument,
	scope Out delegate(ref immutable Command.Help) @safe @nogc nothrow cbHelp,
	scope Out delegate(ref immutable Command.Print) @safe @nogc nothrow cbPrint,
	scope Out delegate(ref immutable Command.Run) @safe @nogc nothrow cbRun,
	scope Out delegate(ref immutable Command.Test) @safe @nogc nothrow cbTest,
) {
	final switch (a.kind) {
		case Command.Kind.build:
			return cbBuild(a.build);
		case Command.Kind.document:
			return cbDocument(a.document);
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

@trusted Out matchRunOptions(Out)(
	ref immutable RunOptions a,
	scope Out delegate(ref immutable RunOptions.BuildAndRun) @safe @nogc nothrow cbBuildAndRun,
	scope Out delegate(ref immutable RunOptions.Interpret) @safe @nogc nothrow cbInterpret,
) {
	final switch (a.kind) {
		case RunOptions.Kind.buildAndRun:
			return cbBuildAndRun(a.buildAndRun);
		case RunOptions.Kind.interpret:
			return cbInterpret(a.interpret);
	}
}

pure:

struct Command {
	@safe @nogc pure nothrow:
	struct Build {
		immutable ProgramDirAndMain programDirAndMain;
		immutable BuildOptions options;
	}
	struct Document {
		immutable ProgramDirAndMain programDirAndMain;
		immutable Opt!AbsolutePath out_;
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
		immutable ProgramDirAndMain programDirAndMain;
		immutable RunOptions options;
		immutable string[] programArgs;
	}
	struct Test {
		immutable Opt!string name;
	}

	@trusted immutable this(immutable Build a) { kind = Kind.build; build = a; }
	@trusted immutable this(immutable Document a) { kind = Kind.document; document = a; }
	@trusted immutable this(immutable Help a) { kind = Kind.help; help = a; }
	@trusted immutable this(immutable Print a) { kind = Kind.print; print = a; }
	@trusted immutable this(immutable Run a) { kind = Kind.run; run = a; }
	@trusted immutable this(immutable Test a) { kind = Kind.test; test = a; }

	private:
	enum Kind {
		build,
		document,
		help,
		print,
		run,
		test,
	}
	immutable Kind kind;
	union {
		immutable Build build;
		immutable Document document;
		immutable Help help;
		immutable Print print;
		immutable Run run;
		immutable Test test;
	}
}

struct RunOptions {
	@safe @nogc pure nothrow:
	struct BuildAndRun {
		immutable BuildOptions build;
	}
	struct Interpret {}

	@trusted immutable this(immutable BuildAndRun a) { kind = Kind.buildAndRun; buildAndRun = a; }
	immutable this(immutable Interpret a) { kind = Kind.interpret; interpret = a; }

	private:
	enum Kind {
		buildAndRun,
		interpret,
	}
	immutable Kind kind;
	union {
		immutable BuildAndRun buildAndRun;
		immutable Interpret interpret;
	}
}

struct BuildOptions {
	immutable BuildOut out_;
	immutable CCompileOptions cCompileOptions;
}

struct CCompileOptions {
	immutable bool optimize;
}

private struct BuildOut {
	immutable Opt!AbsolutePath outC;
	immutable Opt!AbsolutePath outExecutable;
}

struct ProgramDirAndMain {
	immutable string programDir;
	immutable Path mainPath;
}

immutable(Command) parseCommand(
	ref Alloc alloc,
	ref AllPaths allPaths,
	immutable string cwd,
	immutable string[] args,
) {
	if (size(args) == 0)
		return immutable Command(immutable Command.Help(helpAllText, Command.Help.Kind.error));
	else {
		immutable string arg0 = first(args);
		immutable string[] cmdArgs = tail(args);
		return isHelp(arg0)
			? immutable Command(immutable Command.Help(helpAllText, Command.Help.Kind.requested))
			: isSpecialArg(arg0, "version")
			? immutable Command(immutable Command.Help(versionText, Command.Help.Kind.requested))
			: strEq(arg0, "print")
			? parsePrintCommand(alloc, allPaths, cwd, cmdArgs)
			: strEq(arg0, "build")
			? parseBuildCommand(alloc, allPaths, cwd, cmdArgs)
			: strEq(arg0, "doc")
			? parseDocumentCommand(alloc, allPaths, cwd, cmdArgs)
			: strEq(arg0, "run")
			? parseRunCommand(alloc, allPaths, cwd, cmdArgs)
			: strEq(arg0, "test")
			? parseTestCommand(alloc, cmdArgs)
			: immutable Command(immutable Command.Help(helpAllText, Command.Help.Kind.error));
	}
}

private:

immutable(BuildOptions) emptyBuildOptions() {
	return immutable BuildOptions(emptyBuildOut(), CCompileOptions(false));
}

immutable(BuildOut) emptyBuildOut() {
	return immutable BuildOut(none!AbsolutePath, none!AbsolutePath);
}

immutable(bool) isSpecialArg(immutable string a, immutable string expected) {
	return empty(a) ? true : (at(a, 0) == '-' ? isSpecialArg(tail(a), expected) : strEq(a, expected));
}

immutable(bool) isHelp(immutable string a) {
	return isSpecialArg(a, "help");
}

immutable(Command) useProgramDirAndMain(
	ref Alloc alloc,
	ref AllPaths allPaths,
	immutable string cwd,
	immutable string arg,
	scope immutable(Command) delegate(ref immutable ProgramDirAndMain) @safe pure @nogc nothrow cb,
) {
	immutable Opt!ProgramDirAndMain p = parseProgramDirAndMain(alloc, allPaths, cwd, arg);
	return has(p)
		? cb(force(p))
		: immutable Command(immutable Command.Help("Invalid path", Command.Help.Kind.error));
}

immutable(Opt!ProgramDirAndMain) parseProgramDirAndMain(
	ref Alloc alloc,
	ref AllPaths allPaths,
	immutable string cwd,
	immutable string arg,
) {
	immutable AbsolutePath mainAbsolutePath = parseAbsoluteOrRelPath(allPaths, cwd, arg);
	return empty(mainAbsolutePath.extension) || strEq(mainAbsolutePath.extension, crowExtension())
		? some(immutable ProgramDirAndMain(mainAbsolutePath.root, mainAbsolutePath.path))
		: none!ProgramDirAndMain;
}

struct FormatAndPath {
	immutable PrintFormat format;
	immutable string path;
}

immutable(Command) parsePrintCommand(
	ref Alloc alloc,
	ref AllPaths allPaths,
	immutable string cwd,
	immutable string[] args,
) {
	if (size(args) < 2)
		return todo!Command("Command.HelpPrint");
	else {
		immutable FormatAndPath formatAndPath = size(args) == 2
			? immutable FormatAndPath(PrintFormat.repr, at(args, 1))
			: size(args) == 4 && strEq(at(args, 1), "--format") && strEq(at(args, 2), "json")
			? immutable FormatAndPath(PrintFormat.json, at(args, 3))
			: todo!(immutable FormatAndPath)("Command.HelpPrint");
		return useProgramDirAndMain(
			alloc,
			allPaths,
			cwd,
			formatAndPath.path,
			(ref immutable ProgramDirAndMain it) =>
				immutable Command(immutable Command.Print(
					parsePrintKind(first(args)),
					it,
					formatAndPath.format)));
	}
}

immutable(PrintKind) parsePrintKind(immutable string a) {
	return strEq(a, "tokens")
		? PrintKind.tokens
		: strEq(a, "ast")
		? PrintKind.ast
		: strEq(a, "model")
		? PrintKind.model
		: strEq(a, "concrete-model")
		? PrintKind.concreteModel
		: strEq(a, "low-model")
		? PrintKind.lowModel
		: todo!(immutable PrintKind)("parsePrintKind");
}

immutable(Command) parseDocumentCommand(
	ref Alloc alloc,
	ref AllPaths allPaths,
	immutable string cwd,
	immutable string[] args,
) {
	immutable Command helpDocument = immutable Command(
		immutable Command.Help(helpDocumentText, Command.Help.Kind.error));
	immutable SplitArgs split = splitArgs(alloc, args);
	return size(split.beforeFirstPart) != 1
		? helpDocument
		: useProgramDirAndMain(
			alloc,
			allPaths,
			cwd,
			only(split.beforeFirstPart),
			(ref immutable ProgramDirAndMain it) {
				immutable Opt!(Opt!AbsolutePath) out_ = parseDocumentOut(allPaths, cwd, split.parts);
				return has(out_) && empty(split.afterDashDash)
					? immutable Command(immutable Command.Document(it, force(out_)))
					: helpDocument;
			});
}

immutable(Command) parseBuildCommand(
	ref Alloc alloc,
	ref AllPaths allPaths,
	ref immutable string cwd,
	ref immutable string[] args,
) {
	immutable Command helpBuild = immutable Command(immutable Command.Help(helpBuildText, Command.Help.Kind.error));
	immutable SplitArgs split = splitArgs(alloc, args);
	return size(split.beforeFirstPart) != 1
		? helpBuild
		: useProgramDirAndMain(
			alloc,
			allPaths,
			cwd,
			only(split.beforeFirstPart),
			(ref immutable ProgramDirAndMain it) {
				immutable Opt!BuildOptions options = parseBuildOptions(allPaths, cwd, split.parts, it);
				return has(options) && empty(split.afterDashDash)
					? immutable Command(immutable Command.Build(it, force(options)))
					: helpBuild;
			});
}

immutable(Command) parseRunCommand(
	ref Alloc alloc,
	ref AllPaths allPaths,
	immutable string cwd,
	immutable string[] args,
) {
	if (size(args) == 1 && isHelp(only(args)))
		return immutable Command(immutable Command.Help(helpRunText, Command.Help.Kind.requested));
	else {
		immutable SplitArgs split = splitArgs(alloc, args);
		immutable Opt!RunOptions options = parseRunOptions(alloc, allPaths, cwd, split.parts);
		return size(split.beforeFirstPart) == 1 && has(options)
			? useProgramDirAndMain(
				alloc,
				allPaths,
				cwd,
				only(split.beforeFirstPart),
				(ref immutable ProgramDirAndMain it) =>
					immutable Command(immutable Command.Run(it, force(options), split.afterDashDash)))
			: immutable Command(immutable Command.Help(helpRunText, Command.Help.Kind.error));
	}
}

immutable(Opt!RunOptions) parseRunOptions(
	ref Alloc alloc,
	ref AllPaths allPaths,
	immutable string cwd,
	immutable ArgsPart[] argParts,
) {
	if (empty(argParts))
		return some(immutable RunOptions(immutable RunOptions.BuildAndRun(emptyBuildOptions())));
	else if (size(argParts) != 1)
		// TODO: better message -- can't combine '--interpret' with build options
		return none!RunOptions;
	else {
		immutable ArgsPart part = only(argParts);
		if (strEq(part.tag, "--interpret")) {
			return empty(part.args) ? some(immutable RunOptions(immutable RunOptions.Interpret())) : none!RunOptions;
		} else if (strEq(part.tag, "--out")) {
			immutable Opt!BuildOut buildOut = parseBuildOut(allPaths, cwd, part.args);
			return has(buildOut)
				? some(immutable RunOptions(immutable RunOptions.BuildAndRun(
					immutable BuildOptions(force(buildOut)))))
				: none!RunOptions;
		} else if (strEq(part.tag, "--optimize")) {
			if (!empty(part.args))
				todo!void("!");
			return some(immutable RunOptions(immutable RunOptions.BuildAndRun(
				immutable BuildOptions(
					immutable BuildOut(none!AbsolutePath, none!AbsolutePath),
					immutable CCompileOptions(true)))));
		} else
			return none!RunOptions;
	}
}

// none for error, some(none) for nothing passed
immutable(Opt!(Opt!AbsolutePath)) parseDocumentOut(
	ref AllPaths allPaths,
	immutable string cwd,
	immutable ArgsPart[] argParts,
) {
	if (empty(argParts))
		return some(none!AbsolutePath);
	if (size(argParts) != 1)
		return none!(Opt!AbsolutePath);
	else {
		immutable ArgsPart part = only(argParts);
		return strEq(part.tag, "--out") && size(part.args) == 1
			? some(some(parseAbsoluteOrRelPath(allPaths, cwd, only(part.args))))
			: none!(Opt!AbsolutePath);
	}
}

immutable(Opt!BuildOptions) parseBuildOptions(
	ref AllPaths allPaths,
	immutable string cwd,
	immutable ArgsPart[] argParts,
	ref immutable ProgramDirAndMain programDirAndMain,
) {
	if (empty(argParts))
		return some(immutable BuildOptions(immutable BuildOut(
			none!AbsolutePath,
			some(immutable AbsolutePath(programDirAndMain.programDir, programDirAndMain.mainPath, "")))));
	else if (size(argParts) != 1)
		return none!BuildOptions;
	else {
		immutable ArgsPart part = only(argParts);
		if (strEq(part.tag, "--out")) {
			immutable Opt!BuildOut buildOut = parseBuildOut(allPaths, cwd, part.args);
			return has(buildOut)
				? some(immutable BuildOptions(force(buildOut)))
				: none!BuildOptions;
		} else
			return none!BuildOptions;
	}
}

immutable(Opt!BuildOut) parseBuildOut(
	ref AllPaths allPaths,
	immutable string cwd,
	immutable string[] args,
) {
	return foldOrStop(
		emptyBuildOut(),
		args,
		(immutable BuildOut o, ref immutable string arg) {
			immutable AbsolutePath path = parseAbsoluteOrRelPath(allPaths, cwd, arg);
			if (empty(path.extension)) {
				return has(o.outExecutable)
					? none!BuildOut
					: some(immutable BuildOut(o.outC, some(path)));
			} else if (strEq(path.extension, ".c")) {
				return has(o.outC)
					? none!BuildOut
					: some(immutable BuildOut(some(path), o.outExecutable));
			} else
				return none!BuildOut;
		});
}

struct ArgsPart {
	immutable string tag; // includes the "--"
	immutable string[] args;
}

struct SplitArgs {
	immutable string[] beforeFirstPart;
	immutable ArgsPart[] parts;
	// After seeing a '--' we stop parsing and just return the rest raw.
	immutable string[] afterDashDash;
}

immutable(SplitArgs) splitArgs(ref Alloc alloc, immutable string[] args) {
	immutable Opt!size_t optFirstArgIndex = findIndex!string(args, (ref immutable string arg) =>
		startsWith(arg, "--"));
	if (!has(optFirstArgIndex))
		return immutable SplitArgs(args, emptyArr!ArgsPart, emptyArr!string);
	else {
		immutable size_t firstArgIndex = force(optFirstArgIndex);
		immutable string[] beforeFirstPart = args[0 .. firstArgIndex];
		if (strEq(at(args, firstArgIndex), "--"))
			return immutable SplitArgs(beforeFirstPart, emptyArr!ArgsPart, args[firstArgIndex + 1 .. $]);
		else {
			ArrBuilder!ArgsPart parts;
			immutable size_t firstAfterDashDash =
				splitArgsRecur(alloc, parts, args, firstArgIndex, firstArgIndex + 1);
			return immutable SplitArgs(beforeFirstPart, finishArr(alloc, parts), args[firstAfterDashDash .. $]);
		}
	}
}

immutable(size_t) splitArgsRecur(
	ref Alloc alloc,
	ref ArrBuilder!ArgsPart parts,
	immutable string[] args,
	immutable size_t curPartStart,
	immutable size_t index,
) {
	if (index == size(args)) {
		add(alloc, parts, immutable ArgsPart(at(args, curPartStart), args[curPartStart + 1 .. index]));
		return index;
	} else {
		immutable string arg = at(args, index);
		if (startsWith(arg, "--")) {
			add(alloc, parts, immutable ArgsPart(at(args, curPartStart), args[curPartStart + 1 .. index]));
			return strEq(arg, "--")
				? index + 1
				// Using `index + 0` to avoid dscanner warning about 'index' not being parameter 3
				: splitArgsRecur(alloc, parts, args, index + 0, index + 1);
		} else
			return splitArgsRecur(alloc, parts, args, curPartStart, index + 1);
	}
}

immutable(Command) parseTestCommand(ref Alloc alloc, immutable string[] args) {
	if (empty(args))
		return immutable Command(immutable Command.Test(none!string));
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

immutable string helpDocumentText =
	"Command: crow document PATH --out [OUT.pug]\n" ~
	"\tWrites documentation for the module at PATH to the output.\n";

immutable string helpBuildText =
	"Command: crow build PATH --out OUT\n" ~
	"\tCompiles the program at PATH to an executable OUT.\n" ~
	"\tIf OUT has a '.c' extension, it will be C source code instead.\n";

immutable string helpRunText =
	"Command: crow run [PATH] [build args] -- [programArgs]\n" ~
	"\tBuild args are same as for 'crow build'.\n" ~
	"Arguments after '--' will be sent to the program.";
