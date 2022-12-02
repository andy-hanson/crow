module lib.cliParser;

@safe @nogc pure nothrow:

import frontend.lang : crowExtension, JitOptions, OptimizationLevel;
import lib.compiler : PrintKind;
import util.alloc.alloc : Alloc;
import util.col.arr : empty, only;
import util.col.arrBuilder : add, ArrBuilder, finishArr;
import util.col.arrUtil : findIndex, foldOrStop, mapOrNone;
import util.col.str : SafeCStr, safeCStr, safeCStrEq, strOfSafeCStr;
import util.opt : force, has, none, Opt, some;
import util.path : AllPaths, parseAbsoluteOrRelPathAndExtension, Path, PathAndExtension;
import util.ptr : castNonScope;
import util.sym : AllSymbols, Sym, sym, symOfSafeCStr, symOfStr;
import util.union_ : Union;
import util.util : todo, verify;

immutable struct Command {
	immutable struct Build {
		Path mainPath;
		BuildOptions options;
	}
	immutable struct Document {
		Path[] rootPaths;
	}
	immutable struct Help {
		enum Kind {
			requested,
			error,
		}
		SafeCStr helpText;
		Kind kind;
	}
	immutable struct Print {
		PrintKind kind;
		Path mainPath;
	}
	immutable struct Run {
		Path mainPath;
		RunOptions options;
		// Does not include executable path
		SafeCStr[] programArgs;
	}
	immutable struct Test {
		Opt!Sym name;
	}
	immutable struct Version {}

	mixin Union!(Build, Document, Help, Print, Run, Test, Version);
}

immutable struct RunOptions {
	immutable struct Interpret {}
	immutable struct Jit {
		JitOptions options;
	}
	mixin Union!(Interpret, Jit);
}

immutable struct BuildOptions {
	BuildOut out_;
	CCompileOptions cCompileOptions;
}

private BuildOptions withBuildOut(BuildOptions a, BuildOut value) =>
	BuildOptions(value, a.cCompileOptions);

private BuildOptions withCCompileOptions(BuildOptions a, CCompileOptions value) =>
	BuildOptions(a.out_, value);

immutable struct CCompileOptions {
	OptimizationLevel optimizationLevel;
}

private immutable struct BuildOut {
	Opt!PathAndExtension outC;
	Opt!PathAndExtension outExecutable;
}

bool hasAnyOut(in BuildOut a) =>
	has(a.outC) || has(a.outExecutable);

Command parseCommand(
	ref Alloc alloc,
	ref AllSymbols allSymbols,
	ref AllPaths allPaths,
	Path cwd,
	return scope SafeCStr[] args,
) {
	if (empty(args))
		return Command(Command.Help(helpAllText, Command.Help.Kind.error));
	else {
		Sym arg0 = symOfStr(allSymbols, strOfSafeCStr(args[0]));
		SafeCStr[] cmdArgs = args[1 .. $];
		switch (arg0.value) {
			case sym!"build".value:
				return parseBuildCommand(alloc, allSymbols, allPaths, cwd, cmdArgs);
			case sym!"doc".value:
				return parseDocumentCommand(alloc, allSymbols, allPaths, cwd, cmdArgs);
			case sym!"print".value:
				return parsePrintCommand(alloc, allSymbols, allPaths, cwd, cmdArgs);
			case sym!"run".value:
				return parseRunCommand(alloc, allSymbols, allPaths, cwd, cmdArgs);
			case sym!"test".value:
				return parseTestCommand(alloc, allSymbols, cmdArgs);
			case sym!"version".value:
				return Command(Command.Version());
			default:
				return Command(Command.Help(
					helpAllText,
					isHelp(arg0) ? Command.Help.Kind.requested : Command.Help.Kind.error));
		}
	}
}

version (Windows) {
	Sym defaultExeExtension() => sym!".exe";
} else {
	Sym defaultExeExtension() => sym!"";
}

private:

BuildOut emptyBuildOut() =>
	BuildOut(none!PathAndExtension, none!PathAndExtension);

bool isHelp(Sym a) {
	switch (a.value) {
		case sym!"help".value:
		case sym!"-help".value:
		case sym!"--help".value:
			return true;
		default:
			return false;
	}
}

Command withMainPath(
	ref Alloc alloc,
	ref AllPaths allPaths,
	Path cwd,
	in SafeCStr arg,
	in Command delegate(Path) @safe pure @nogc nothrow cb,
) {
	Opt!Path p = tryParseCrowPath(alloc, allPaths, cwd, arg);
	return has(p)
		? cb(force(p))
		: Command(Command.Help(safeCStr!"Invalid path", Command.Help.Kind.error));
}

Command withRootPaths(
	ref Alloc alloc,
	ref AllPaths allPaths,
	Path cwd,
	in SafeCStr[] args,
	in Command delegate(Path[]) @safe pure @nogc nothrow cb,
) {
	Opt!(Path[]) p = tryParseRootPaths(alloc, allPaths, cwd, args);
	return has(p)
		? cb(force(p))
		: Command(Command.Help(safeCStr!"Invalid path", Command.Help.Kind.error));
}

Opt!Path tryParseCrowPath(ref Alloc alloc, ref AllPaths allPaths, Path cwd, in SafeCStr arg) {
	PathAndExtension path = parseAbsoluteOrRelPathAndExtension(allPaths, cwd, arg);
	return path.extension == sym!"" || path.extension == crowExtension
		? some(path.path)
		: none!Path;
}

Opt!(Path[]) tryParseRootPaths(ref Alloc alloc, ref AllPaths allPaths, Path cwd, in SafeCStr[] args) {
	verify(!empty(args));
	return mapOrNone!(Path, SafeCStr)(alloc, args, (ref SafeCStr arg) =>
		tryParseCrowPath(alloc, allPaths, cwd, arg));
}

Command parsePrintCommand(
	ref Alloc alloc,
	ref AllSymbols allSymbols,
	ref AllPaths allPaths,
	Path cwd,
	in SafeCStr[] args,
) {
	Opt!PrintKind kind = args.length == 2
		? parsePrintKind(symOfSafeCStr(allSymbols, args[0]))
		: none!PrintKind;
	return has(kind)
		? withMainPath(alloc, allPaths, cwd, args[1], (Path path) =>
			Command(Command.Print(force(kind), path)))
		: todo!Command("Command.HelpPrint");
}

Opt!PrintKind parsePrintKind(Sym a) {
	switch (a.value) {
		case sym!"tokens".value:
			return some(PrintKind.tokens);
		case sym!"ast".value:
			return some(PrintKind.ast);
		case sym!"model".value:
			return some(PrintKind.model);
		case sym!"concrete-model".value:
			return some(PrintKind.concreteModel);
		case sym!"low-model".value:
			return some(PrintKind.lowModel);
		default:
			return none!PrintKind;
	}
}

Command parseDocumentCommand(
	ref Alloc alloc,
	ref AllSymbols allSymbols,
	ref AllPaths allPaths,
	Path cwd,
	in SafeCStr[] args,
) {
	Command helpDocument = Command(Command.Help(helpDocumentText, Command.Help.Kind.error));
	scope SplitArgs split = splitArgs(alloc, allSymbols, args);
	return withRootPaths(
		alloc,
		allPaths,
		cwd,
		split.beforeFirstPart,
		(Path[] it) =>
			empty(split.parts) && empty(split.afterDashDash)
				? Command(Command.Document(it))
				: helpDocument);
}

Command parseBuildCommand(
	ref Alloc alloc,
	ref AllSymbols allSymbols,
	ref AllPaths allPaths,
	Path cwd,
	in SafeCStr[] args,
) {
	Command helpBuild = Command(Command.Help(helpBuildText, Command.Help.Kind.error));
	SplitArgs split = splitArgs(alloc, allSymbols, args);
	return split.beforeFirstPart.length != 1
		? helpBuild
		: withMainPath(
			alloc,
			allPaths,
			cwd,
			only(split.beforeFirstPart),
			(Path it) {
				Opt!BuildOptions options = parseBuildOptions(alloc, allPaths, cwd, split.parts, it);
				return has(options) && empty(split.afterDashDash)
					? Command(Command.Build(it, force(options)))
					: helpBuild;
			});
}

Command parseRunCommand(
	ref Alloc alloc,
	ref AllSymbols allSymbols,
	ref AllPaths allPaths,
	Path cwd,
	return scope SafeCStr[] args,
) {
	if (args.length == 1 && isHelp(symOfSafeCStr(allSymbols, only(args))))
		return Command(Command.Help(helpRunText, Command.Help.Kind.requested));
	else {
		SplitArgs split = splitArgs(alloc, allSymbols, args);
		Opt!RunOptions options = parseRunOptions(alloc, allPaths, split.parts);
		return split.beforeFirstPart.length == 1 && has(options)
			? withMainPath(
				alloc,
				allPaths,
				cwd,
				only(split.beforeFirstPart),
				(Path it) =>
					Command(Command.Run(it, force(options), castNonScope(split.afterDashDash))))
			: Command(Command.Help(helpRunText, Command.Help.Kind.error));
	}
}

Opt!RunOptions parseRunOptions(ref Alloc alloc, ref AllPaths allPaths, in ArgsPart[] argParts) {
	bool jit = false;
	bool optimize = false;
	foreach (ArgsPart part; argParts) {
		switch (part.tag.value) {
			case sym!"--jit".value:
				jit = true;
				break;
			case sym!"--optimize".value:
				optimize = true;
				break;
			default:
				return none!RunOptions;
		}
	}
	return jit
		? some(RunOptions(RunOptions.Jit(optimize ? JitOptions(OptimizationLevel.o2) : JitOptions())))
		: optimize
		? none!RunOptions
		: some(RunOptions(RunOptions.Interpret()));
}

Opt!BuildOptions parseBuildOptions(
	ref Alloc alloc,
	ref AllPaths allPaths,
	Path cwd,
	in ArgsPart[] argParts,
	Path mainPath,
) =>
	foldOrStop!(BuildOptions, ArgsPart)(
		// Default: unoptimized, compiled next to the source file
		BuildOptions(
			BuildOut(none!PathAndExtension, some(PathAndExtension(mainPath, defaultExeExtension))),
			CCompileOptions(OptimizationLevel.none)),
		argParts,
		(BuildOptions cur, ref ArgsPart part) {
			switch (part.tag.value) {
				case sym!"--out".value:
					Opt!BuildOut buildOut = parseBuildOut(alloc, allPaths, cwd, part.args);
					return has(buildOut) ? some(withBuildOut(cur, force(buildOut))) : none!BuildOptions;
				case sym!"--no-out".value:
					return empty(part.args)
						? some(withBuildOut(cur, BuildOut(none!PathAndExtension, none!PathAndExtension)))
						: none!BuildOptions;
				case sym!"--optimize".value:
					return empty(part.args)
						? some(withCCompileOptions(cur, CCompileOptions(OptimizationLevel.o2)))
						: none!BuildOptions;
				default:
					return none!BuildOptions;
			}
		});

Opt!BuildOut parseBuildOut(
	ref Alloc alloc,
	ref AllPaths allPaths,
	Path cwd,
	SafeCStr[] args,
) =>
	foldOrStop!(BuildOut, SafeCStr)(
		emptyBuildOut(),
		args,
		(BuildOut o, ref SafeCStr arg) {
			PathAndExtension path = parseAbsoluteOrRelPathAndExtension(allPaths, cwd, arg);
			return path.extension == sym!""
				? has(o.outExecutable)
					? none!BuildOut
					: some(BuildOut(o.outC, some(path)))
				: path.extension == sym!".c"
					? has(o.outC)
						? none!BuildOut
						: some(BuildOut(some(path), o.outExecutable))
				: none!BuildOut;
		});

immutable struct ArgsPart {
	Sym tag; // includes the "--"
	SafeCStr[] args;
}

immutable struct SplitArgs {
	SafeCStr[] beforeFirstPart;
	ArgsPart[] parts;
	// After seeing a '--' we stop parsing and just return the rest raw.
	SafeCStr[] afterDashDash;
}

SplitArgs splitArgs(ref Alloc alloc, ref AllSymbols allSymbols, return scope SafeCStr[] args) {
	Opt!size_t optFirstArgIndex = findIndex!SafeCStr(args, (in SafeCStr arg) =>
		startsWithDashDash(arg));
	if (!has(optFirstArgIndex))
		return SplitArgs(args, [], []);
	else {
		size_t firstArgIndex = force(optFirstArgIndex);
		SafeCStr[] beforeFirstPart = args[0 .. firstArgIndex];
		if (safeCStrEq(args[firstArgIndex], "--"))
			return SplitArgs(beforeFirstPart, [], args[firstArgIndex + 1 .. $]);
		else {
			ArrBuilder!ArgsPart parts;
			size_t firstAfterDashDash =
				splitArgsRecur(alloc, allSymbols, parts, args, firstArgIndex, firstArgIndex + 1);
			return SplitArgs(beforeFirstPart, finishArr(alloc, parts), args[firstAfterDashDash .. $]);
		}
	}
}

@trusted bool startsWithDashDash(in SafeCStr a) =>
	a.ptr[0] == '-' && a.ptr[1] == '-';

size_t splitArgsRecur(
	ref Alloc alloc,
	ref AllSymbols allSymbols,
	ref ArrBuilder!ArgsPart parts,
	in SafeCStr[] args,
	size_t curPartStart,
	size_t index,
) {
	if (index == args.length) {
		add(alloc, parts, ArgsPart(symOfSafeCStr(allSymbols, args[curPartStart]), args[curPartStart + 1 .. index]));
		return index;
	} else {
		SafeCStr arg = args[index];
		if (startsWithDashDash(arg)) {
			add(alloc, parts, ArgsPart(symOfSafeCStr(allSymbols, args[curPartStart]), args[curPartStart + 1 .. index]));
			return safeCStrEq(arg, "--")
				? index + 1
				// Using `index + 0` to avoid dscanner warning about 'index' not being parameter 3
				: splitArgsRecur(alloc, allSymbols, parts, args, index + 0, index + 1);
		} else
			return splitArgsRecur(alloc, allSymbols, parts, args, curPartStart, index + 1);
	}
}

Command parseTestCommand(ref Alloc alloc, ref AllSymbols allSymbols, in SafeCStr[] args) {
	if (empty(args))
		return Command(Command.Test(none!Sym));
	else if (args.length == 1)
		return Command(Command.Test(some(symOfSafeCStr(allSymbols, args[0]))));
	else
		return Command(Command.Help(helpAllText, Command.Help.Kind.error));
}

SafeCStr helpAllText() =>
	safeCStr!("Commands: (type a command then '--help' to see more)\n" ~
	"\t'crow build'\n" ~
	"\t'crow run'\n" ~
	"\t'crow version'");

SafeCStr helpDocumentText() =>
	safeCStr!("Command: crow document PATH\n" ~
	"\tGenerates JSON documentation for the module at PATH.\n");

SafeCStr helpBuildText() =>
	safeCStr!("Command: crow build PATH --out OUT [options]\n" ~
	"Compiles the program at PATH. The '.crow' extension is optional.\n" ~
	"Writes an executable to OUT. If OUT has a '.c' extension, it will be C source code instead.\n" ~
	"Options are:\n" ~
	"\t--optimize : Enables optimizations.\n");

SafeCStr helpRunText() =>
	safeCStr!("Command: crow run PATH [options] -- [program-args]\n" ~
	"Runs the program at PATH. The '.crow' extension is optional." ~
	"Arguments after '--' will be sent to the program.\n" ~
	"Options are:\n" ~
	"\t--jit : Just-In-Time compile the code (instead of the default interpreter).\n" ~
	"\t--optimize : Use with '--jit'. Enables optimizations.\n");
