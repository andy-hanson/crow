module lib.cliParser;

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
import util.sym :
	AllSymbols, emptySym, shortSymValue, SpecialSym, specialSymValue, Sym, symForSpecial, symOfSafeCStr, symOfStr;
import util.util : todo, verify;

@safe @nogc nothrow: // not pure

@trusted immutable(Out) matchCommand(Out)(
	scope immutable Command a,
	scope immutable(Out) delegate(scope immutable Command.Build) @safe @nogc nothrow cbBuild,
	scope immutable(Out) delegate(scope immutable Command.Document) @safe @nogc nothrow cbDocument,
	scope immutable(Out) delegate(scope immutable Command.Help) @safe @nogc nothrow cbHelp,
	scope immutable(Out) delegate(scope immutable Command.Print) @safe @nogc nothrow cbPrint,
	scope immutable(Out) delegate(scope immutable Command.Run) @safe @nogc nothrow cbRun,
	scope immutable(Out) delegate(scope immutable Command.Test) @safe @nogc nothrow cbTest,
	scope immutable(Out) delegate(scope immutable Command.Version) @safe @nogc nothrow cbVersion,
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
		case Command.Kind.version_:
			return cbVersion(a.version_);
	}
}

@trusted Out matchRunOptions(Out)(
	ref immutable RunOptions a,
	scope Out delegate(ref immutable RunOptions.Interpret) @safe @nogc nothrow cbInterpret,
	scope Out delegate(ref immutable RunOptions.Jit) @safe @nogc nothrow cbJit,
) {
	final switch (a.kind) {
		case RunOptions.Kind.interpret:
			return cbInterpret(a.interpret);
		case RunOptions.Kind.jit:
			return cbJit(a.jit);
	}
}

pure:

struct Command {
	@safe @nogc pure nothrow:
	struct Build {
		immutable Path mainPath;
		immutable BuildOptions options;
	}
	struct Document {
		immutable Path[] rootPaths;
	}
	struct Help {
		enum Kind {
			requested,
			error,
		}
		immutable SafeCStr helpText;
		immutable Kind kind;
	}
	struct Print {
		immutable PrintKind kind;
		immutable Path mainPath;
	}
	struct Run {
		immutable Path mainPath;
		immutable RunOptions options;
		// Does not include executable path
		immutable SafeCStr[] programArgs;
	}
	struct Test {
		immutable Opt!Sym name;
	}
	struct Version {}

	@trusted immutable this(immutable Build a) { kind = Kind.build; build = a; }
	@trusted immutable this(immutable Document a) { kind = Kind.document; document = a; }
	@trusted immutable this(immutable Help a) { kind = Kind.help; help = a; }
	@trusted immutable this(immutable Print a) { kind = Kind.print; print = a; }
	@trusted immutable this(immutable Run a) { kind = Kind.run; run = a; }
	@trusted immutable this(immutable Test a) { kind = Kind.test; test = a; }
	immutable this(immutable Version a) { kind = Kind.version_; version_ = a; }

	private:
	enum Kind {
		build,
		document,
		help,
		print,
		run,
		test,
		version_,
	}
	immutable Kind kind;
	union {
		immutable Build build;
		immutable Document document;
		immutable Help help;
		immutable Print print;
		immutable Run run;
		immutable Test test;
		immutable Version version_;
	}
}

struct RunOptions {
	@safe @nogc pure nothrow:
	struct Interpret {}
	struct Jit {
		immutable JitOptions options;
	}

	immutable this(immutable Interpret a) { kind = Kind.interpret; interpret = a; }
	immutable this(immutable Jit a) { kind = Kind.jit; jit = a; }

	private:
	enum Kind {
		interpret,
		jit,
	}
	immutable Kind kind;
	union {
		immutable Interpret interpret;
		immutable Jit jit;
	}
}

struct BuildOptions {
	immutable BuildOut out_;
	immutable CCompileOptions cCompileOptions;
}

private immutable(BuildOptions) withBuildOut(immutable BuildOptions a, immutable BuildOut value) =>
	immutable BuildOptions(value, a.cCompileOptions);

private immutable(BuildOptions) withCCompileOptions(immutable BuildOptions a, immutable CCompileOptions value) =>
	immutable BuildOptions(a.out_, value);

struct CCompileOptions {
	immutable OptimizationLevel optimizationLevel;
}

private struct BuildOut {
	immutable Opt!PathAndExtension outC;
	immutable Opt!PathAndExtension outExecutable;
}

immutable(bool) hasAnyOut(ref immutable BuildOut a) =>
	has(a.outC) || has(a.outExecutable);

immutable(Command) parseCommand(
	ref Alloc alloc,
	ref AllSymbols allSymbols,
	ref AllPaths allPaths,
	immutable Path cwd,
	scope return immutable SafeCStr[] args,
) {
	if (empty(args))
		return immutable Command(immutable Command.Help(helpAllText, Command.Help.Kind.error));
	else {
		immutable Sym arg0 = symOfStr(allSymbols, strOfSafeCStr(args[0]));
		immutable SafeCStr[] cmdArgs = args[1 .. $];
		switch (arg0.value) {
			case shortSymValue("build"):
				return parseBuildCommand(alloc, allSymbols, allPaths, cwd, cmdArgs);
			case shortSymValue("doc"):
				return parseDocumentCommand(alloc, allSymbols, allPaths, cwd, cmdArgs);
			case shortSymValue("print"):
				return parsePrintCommand(alloc, allSymbols, allPaths, cwd, cmdArgs);
			case shortSymValue("run"):
				return parseRunCommand(alloc, allSymbols, allPaths, cwd, cmdArgs);
			case shortSymValue("test"):
				return parseTestCommand(alloc, allSymbols, cmdArgs);
			case shortSymValue("version"):
				return immutable Command(immutable Command.Version());
			default:
				return immutable Command(immutable Command.Help(
					helpAllText,
					isHelp(arg0) ? Command.Help.Kind.requested : Command.Help.Kind.error));
		}
	}
}

version (Windows) {
	immutable Sym defaultExeExtension = symForSpecial(SpecialSym.dotExe);
} else {
	immutable Sym defaultExeExtension = emptySym;
}

private:

immutable(BuildOut) emptyBuildOut() =>
	immutable BuildOut(none!PathAndExtension, none!PathAndExtension);

immutable(bool) isHelp(immutable Sym a) {
	switch (a.value) {
		case shortSymValue("help"):
		case shortSymValue("-help"):
		case shortSymValue("--help"):
			return true;
		default:
			return false;
	}
}

immutable(Command) withMainPath(
	ref Alloc alloc,
	ref AllPaths allPaths,
	immutable Path cwd,
	scope immutable SafeCStr arg,
	scope immutable(Command) delegate(immutable Path) @safe pure @nogc nothrow cb,
) {
	immutable Opt!Path p = tryParseCrowPath(alloc, allPaths, cwd, arg);
	return has(p)
		? cb(force(p))
		: immutable Command(immutable Command.Help(safeCStr!"Invalid path", Command.Help.Kind.error));
}

immutable(Command) withRootPaths(
	ref Alloc alloc,
	ref AllPaths allPaths,
	immutable Path cwd,
	scope immutable SafeCStr[] args,
	scope immutable(Command) delegate(immutable Path[]) @safe pure @nogc nothrow cb,
) {
	immutable Opt!(Path[]) p = tryParseRootPaths(alloc, allPaths, cwd, args);
	return has(p)
		? cb(force(p))
		: immutable Command(immutable Command.Help(safeCStr!"Invalid path", Command.Help.Kind.error));
}

immutable(Opt!Path) tryParseCrowPath(
	ref Alloc alloc,
	ref AllPaths allPaths,
	immutable Path cwd,
	scope immutable SafeCStr arg,
) {
	immutable PathAndExtension path = parseAbsoluteOrRelPathAndExtension(allPaths, cwd, arg);
	return path.extension == emptySym || path.extension == crowExtension
		? some(path.path)
		: none!Path;
}

immutable(Opt!(Path[])) tryParseRootPaths(
	ref Alloc alloc,
	ref AllPaths allPaths,
	immutable Path cwd,
	scope immutable SafeCStr[] args,
) {
	verify(!empty(args));
	return mapOrNone(alloc, args, (ref immutable SafeCStr arg) =>
		tryParseCrowPath(alloc, allPaths, cwd, arg));
}

immutable(Command) parsePrintCommand(
	ref Alloc alloc,
	ref AllSymbols allSymbols,
	ref AllPaths allPaths,
	immutable Path cwd,
	scope immutable SafeCStr[] args,
) {
	immutable Opt!PrintKind kind = args.length == 2
		? parsePrintKind(symOfSafeCStr(allSymbols, args[0]))
		: none!PrintKind;
	return has(kind)
		? withMainPath(alloc, allPaths, cwd, args[1], (immutable Path path) =>
			immutable Command(immutable Command.Print(force(kind), path)))
		: todo!Command("Command.HelpPrint");
}

immutable(Opt!PrintKind) parsePrintKind(immutable Sym a) {
	switch (a.value) {
		case shortSymValue("tokens"):
			return some(PrintKind.tokens);
		case shortSymValue("ast"):
			return some(PrintKind.ast);
		case shortSymValue("model"):
			return some(PrintKind.model);
		case specialSymValue(SpecialSym.concrete_model):
			return some(PrintKind.concreteModel);
		case shortSymValue("low-model"):
			return some(PrintKind.lowModel);
		default:
			return none!PrintKind;
	}
}

immutable(Command) parseDocumentCommand(
	ref Alloc alloc,
	ref AllSymbols allSymbols,
	ref AllPaths allPaths,
	immutable Path cwd,
	scope immutable SafeCStr[] args,
) {
	immutable Command helpDocument = immutable Command(
		immutable Command.Help(helpDocumentText, Command.Help.Kind.error));
	scope immutable SplitArgs split = splitArgs(alloc, allSymbols, args);
	return withRootPaths(
		alloc,
		allPaths,
		cwd,
		split.beforeFirstPart,
		(immutable Path[] it) =>
			empty(split.parts) && empty(split.afterDashDash)
				? immutable Command(immutable Command.Document(it))
				: helpDocument);
}

immutable(Command) parseBuildCommand(
	ref Alloc alloc,
	ref AllSymbols allSymbols,
	ref AllPaths allPaths,
	immutable Path cwd,
	scope immutable SafeCStr[] args,
) {
	immutable Command helpBuild = immutable Command(immutable Command.Help(helpBuildText, Command.Help.Kind.error));
	immutable SplitArgs split = splitArgs(alloc, allSymbols, args);
	return split.beforeFirstPart.length != 1
		? helpBuild
		: withMainPath(
			alloc,
			allPaths,
			cwd,
			only(split.beforeFirstPart),
			(immutable Path it) {
				immutable Opt!BuildOptions options = parseBuildOptions(alloc, allPaths, cwd, split.parts, it);
				return has(options) && empty(split.afterDashDash)
					? immutable Command(immutable Command.Build(it, force(options)))
					: helpBuild;
			});
}

immutable(Command) parseRunCommand(
	ref Alloc alloc,
	ref AllSymbols allSymbols,
	ref AllPaths allPaths,
	immutable Path cwd,
	scope return immutable SafeCStr[] args,
) {
	if (args.length == 1 && isHelp(symOfSafeCStr(allSymbols, only(args))))
		return immutable Command(immutable Command.Help(helpRunText, Command.Help.Kind.requested));
	else {
		immutable SplitArgs split = splitArgs(alloc, allSymbols, args);
		immutable Opt!RunOptions options = parseRunOptions(alloc, allPaths, split.parts);
		return split.beforeFirstPart.length == 1 && has(options)
			? withMainPath(
				alloc,
				allPaths,
				cwd,
				only(split.beforeFirstPart),
				(immutable Path it) @safe =>
					immutable Command(immutable Command.Run(it, force(options), castNonScope(split.afterDashDash))))
			: immutable Command(immutable Command.Help(helpRunText, Command.Help.Kind.error));
	}
}

immutable(Opt!RunOptions) parseRunOptions(
	ref Alloc alloc,
	ref AllPaths allPaths,
	scope immutable ArgsPart[] argParts,
) {
	bool jit = false;
	bool optimize = false;
	foreach (immutable ArgsPart part; argParts) {
		switch (part.tag.value) {
			case shortSymValue("--jit"):
				jit = true;
				break;
			case shortSymValue("--optimize"):
				optimize = true;
				break;
			default:
				return none!RunOptions;
		}
	}
	return jit
		? some(immutable RunOptions(immutable RunOptions.Jit(optimize
			? immutable JitOptions(OptimizationLevel.o2)
			: immutable JitOptions())))
		: optimize
			? none!RunOptions
			: some(immutable RunOptions(immutable RunOptions.Interpret()));
}

immutable(Opt!BuildOptions) parseBuildOptions(
	ref Alloc alloc,
	ref AllPaths allPaths,
	immutable Path cwd,
	scope immutable ArgsPart[] argParts,
	immutable Path mainPath,
) =>
	foldOrStop!(BuildOptions, ArgsPart)(
		// Default: unoptimized, compiled next to the source file
		immutable BuildOptions(
			immutable BuildOut(
				none!PathAndExtension,
				some(immutable PathAndExtension(mainPath, defaultExeExtension))),
			immutable CCompileOptions(OptimizationLevel.none)),
		argParts,
		(immutable BuildOptions cur, ref immutable ArgsPart part) {
			switch (part.tag.value) {
				case shortSymValue("--out"):
					immutable Opt!BuildOut buildOut = parseBuildOut(alloc, allPaths, cwd, part.args);
					return has(buildOut) ? some(withBuildOut(cur, force(buildOut))) : none!BuildOptions;
				case shortSymValue("--no-out"):
					return empty(part.args)
						? some(withBuildOut(cur, immutable BuildOut(none!PathAndExtension, none!PathAndExtension)))
						: none!BuildOptions;
				case shortSymValue("--optimize"):
					return empty(part.args)
						? some(withCCompileOptions(cur, immutable CCompileOptions(OptimizationLevel.o2)))
						: none!BuildOptions;
				default:
					return none!BuildOptions;
			}
		});

immutable(Opt!BuildOut) parseBuildOut(
	ref Alloc alloc,
	ref AllPaths allPaths,
	immutable Path cwd,
	immutable SafeCStr[] args,
) =>
	foldOrStop(
		emptyBuildOut(),
		args,
		(immutable BuildOut o, ref immutable SafeCStr arg) {
			immutable PathAndExtension path = parseAbsoluteOrRelPathAndExtension(allPaths, cwd, arg);
			return path.extension == emptySym
				? has(o.outExecutable)
					? none!BuildOut
					: some(immutable BuildOut(o.outC, some(path)))
				: path.extension == symForSpecial(SpecialSym.dotC)
					? has(o.outC)
						? none!BuildOut
						: some(immutable BuildOut(some(path), o.outExecutable))
				: none!BuildOut;
		});

struct ArgsPart {
	immutable Sym tag; // includes the "--"
	immutable SafeCStr[] args;
}

struct SplitArgs {
	immutable SafeCStr[] beforeFirstPart;
	immutable ArgsPart[] parts;
	// After seeing a '--' we stop parsing and just return the rest raw.
	immutable SafeCStr[] afterDashDash;
}

immutable(SplitArgs) splitArgs(ref Alloc alloc, ref AllSymbols allSymbols, scope return immutable SafeCStr[] args) {
	immutable Opt!size_t optFirstArgIndex = findIndex!SafeCStr(args, (ref immutable SafeCStr arg) =>
		startsWithDashDash(arg));
	if (!has(optFirstArgIndex))
		return immutable SplitArgs(args, [], []);
	else {
		immutable size_t firstArgIndex = force(optFirstArgIndex);
		immutable SafeCStr[] beforeFirstPart = args[0 .. firstArgIndex];
		if (safeCStrEq(args[firstArgIndex], "--"))
			return immutable SplitArgs(beforeFirstPart, [], args[firstArgIndex + 1 .. $]);
		else {
			ArrBuilder!ArgsPart parts;
			immutable size_t firstAfterDashDash =
				splitArgsRecur(alloc, allSymbols, parts, args, firstArgIndex, firstArgIndex + 1);
			return immutable SplitArgs(beforeFirstPart, finishArr(alloc, parts), args[firstAfterDashDash .. $]);
		}
	}
}

@trusted immutable(bool) startsWithDashDash(immutable SafeCStr a) =>
	a.ptr[0] == '-' && a.ptr[1] == '-';

immutable(size_t) splitArgsRecur(
	ref Alloc alloc,
	ref AllSymbols allSymbols,
	ref ArrBuilder!ArgsPart parts,
	scope immutable SafeCStr[] args,
	immutable size_t curPartStart,
	immutable size_t index,
) {
	if (index == args.length) {
		add(alloc, parts, immutable ArgsPart(
			symOfSafeCStr(allSymbols, args[curPartStart]),
			args[curPartStart + 1 .. index]));
		return index;
	} else {
		immutable SafeCStr arg = args[index];
		if (startsWithDashDash(arg)) {
			add(alloc, parts, immutable ArgsPart(
				symOfSafeCStr(allSymbols, args[curPartStart]),
				args[curPartStart + 1 .. index]));
			return safeCStrEq(arg, "--")
				? index + 1
				// Using `index + 0` to avoid dscanner warning about 'index' not being parameter 3
				: splitArgsRecur(alloc, allSymbols, parts, args, index + 0, index + 1);
		} else
			return splitArgsRecur(alloc, allSymbols, parts, args, curPartStart, index + 1);
	}
}

immutable(Command) parseTestCommand(ref Alloc alloc, ref AllSymbols allSymbols, scope immutable SafeCStr[] args) {
	if (empty(args))
		return immutable Command(immutable Command.Test(none!Sym));
	else if (args.length == 1)
		return immutable Command(immutable Command.Test(some(symOfSafeCStr(allSymbols, args[0]))));
	else
		return immutable Command(immutable Command.Help(helpAllText, Command.Help.Kind.error));
}

immutable SafeCStr helpAllText =
	safeCStr!("Commands: (type a command then '--help' to see more)\n" ~
	"\t'crow build'\n" ~
	"\t'crow run'\n" ~
	"\t'crow version'");

immutable SafeCStr helpDocumentText =
	safeCStr!("Command: crow document PATH\n" ~
	"\tGenerates JSON documentation for the module at PATH.\n");

immutable SafeCStr helpBuildText =
	safeCStr!("Command: crow build PATH --out OUT [options]\n" ~
	"Compiles the program at PATH. The '.crow' extension is optional.\n" ~
	"Writes an executable to OUT. If OUT has a '.c' extension, it will be C source code instead.\n" ~
	"Options are:\n" ~
	"\t--optimize : Enables optimizations.\n");

immutable SafeCStr helpRunText =
	safeCStr!("Command: crow run PATH [options] -- [program-args]\n" ~
	"Runs the program at PATH. The '.crow' extension is optional." ~
	"Arguments after '--' will be sent to the program.\n" ~
	"Options are:\n" ~
	"\t--jit : Just-In-Time compile the code (instead of the default interpreter).\n" ~
	"\t--optimize : Use with '--jit'. Enables optimizations.\n");
