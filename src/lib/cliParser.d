module lib.cliParser;

@safe @nogc pure nothrow:

import frontend.lang : cExtension, crowExtension, JitOptions, OptimizationLevel;
import frontend.parse.ast : LiteralNatAst;
import frontend.parse.lexToken : takeNat;
import frontend.parse.lexUtil : isDecimalDigit, tryTakeChar;
import util.alloc.alloc : Alloc;
import util.col.arr : empty, only;
import util.col.arrBuilder : add, ArrBuilder, finishArr;
import util.col.arrUtil : copyArr, findIndex, foldOrStop, mapOrNone;
import util.col.str : SafeCStr, safeCStr, safeCStrEq, strOfSafeCStr;
import util.conv : isUint, safeToUint;
import util.lineAndColumnGetter : LineAndColumn;
import util.opt : force, has, MutOpt, none, noneMut, Opt, some, someMut;
import util.ptr : castNonScope;
import util.sym : Sym, sym;
import util.union_ : Union;
import util.uri : addExtension, alterExtension, AllUris, getExtension, parseUriWithCwd, Uri;
import util.util : optEnumOfString, todo;

immutable struct Command {
	CommandKind kind;
	CommandOptions options;
}

// options common to all commands
private immutable struct CommandOptions {
	bool perf;
}

immutable struct CommandKind {
	immutable struct Build {
		Uri mainUri;
		BuildOptions options;
	}
	immutable struct Document {
		Uri[] rootUris;
	}
	immutable struct Help {
		SafeCStr helpText;
		bool requested;
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
		SafeCStr[] programArgs;
	}
	immutable struct Test {
		SafeCStr[] names;
	}
	immutable struct Version {}

	mixin Union!(Build, Document, Help, Lsp, Print, Run, Test, Version);
}

immutable struct PrintKind {
	immutable struct Tokens {}
	immutable struct Ast {}
	immutable struct Model {}
	immutable struct ConcreteModel {}
	immutable struct LowModel {}
	immutable struct Ide {
		enum Kind { hover, definition, rename, references }
		Kind kind;
		LineAndColumn lineAndColumn;
	}

	mixin Union!(Tokens, Ast, Model, ConcreteModel, LowModel, Ide);
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
	Opt!Uri outC;
	Opt!Uri outExecutable;
}

bool hasAnyOut(in BuildOut a) =>
	has(a.outC) || has(a.outExecutable);

Command parseCommand(ref Alloc alloc, scope ref AllUris allUris, Uri cwd, in SafeCStr[] args) {
	if (empty(args))
		return Command(CommandKind(CommandKind.Help(helpAllText)));
	else {
		SplitArgsAndOptions split = splitArgs(alloc, args[1 .. $]);
		return Command(
			parseCommandKind(alloc, allUris, cwd, strOfSafeCStr(args[0]), split.args),
			split.options);
	}
}

private:

CommandKind parseCommandKind(
	ref Alloc alloc,
	scope ref AllUris allUris,
	Uri cwd,
	in string commandName,
	in SplitArgs args,
) {
	switch (commandName) {
		case "build":
			return parseBuildCommand(alloc, allUris, cwd, args);
		case "document":
			return parseDocumentCommand(alloc, allUris, cwd, args);
		case "lsp":
			return isEmpty(args)
				? CommandKind(CommandKind.Lsp())
				: CommandKind(CommandKind.Help(safeCStr!"Usage: 'crow lsp' (no args)", args.help));
		case "print":
			return parsePrintCommand(alloc, allUris, cwd, args);
		case "run":
			return parseRunCommand(alloc, allUris, cwd, args);
		case "test":
			return !args.help && empty(args.parts) && empty(args.afterDashDash)
				? CommandKind(CommandKind.Test(copyArr(alloc, args.beforeFirstPart)))
				: todo!CommandKind("help for 'test'");
		case "version":
			return isEmpty(args)
				? CommandKind(CommandKind.Version())
				: CommandKind(CommandKind.Help(safeCStr!"Usage: 'crow version' (no args)", args.help));
		default:
			return CommandKind(CommandKind.Help(helpAllText, args.help));
	}
}

Sym defaultExeExtension() {
	version (Windows) {
		return sym!".exe";
	} else {
		return sym!"";
	}
}

BuildOut emptyBuildOut() =>
	BuildOut(none!Uri, none!Uri);

CommandKind withMainUri(
	ref Alloc alloc,
	scope ref AllUris allUris,
	Uri cwd,
	in SafeCStr arg,
	in CommandKind delegate(Uri) @safe pure @nogc nothrow cb,
) {
	Opt!Uri p = tryParseCrowUri(alloc, allUris, cwd, arg);
	return has(p) ? cb(force(p)) : CommandKind(CommandKind.Help(safeCStr!"Invalid path"));
}

CommandKind withRootUris(
	ref Alloc alloc,
	scope ref AllUris allUris,
	Uri cwd,
	in SafeCStr[] args,
	in CommandKind delegate(Uri[]) @safe pure @nogc nothrow cb,
) {
	Opt!(Uri[]) p = tryParseRootUris(alloc, allUris, cwd, args);
	return has(p) ? cb(force(p)) : CommandKind(CommandKind.Help(safeCStr!"Invalid path"));
}

Opt!Uri tryParseCrowUri(ref Alloc alloc, scope ref AllUris allUris, Uri cwd, in SafeCStr arg) {
	Uri uri = parseUriWithCwd(allUris, cwd, arg);
	switch (getExtension(allUris, uri).value) {
		case sym!"".value:
			return some(addExtension!crowExtension(allUris, uri));
		case crowExtension.value:
			return some(uri);
		default:
			return none!Uri;
	}
}

Opt!(Uri[]) tryParseRootUris(ref Alloc alloc, scope ref AllUris allUris, Uri cwd, in SafeCStr[] args) {
	assert(!empty(args));
	return mapOrNone!(Uri, SafeCStr)(alloc, args, (ref SafeCStr arg) =>
		tryParseCrowUri(alloc, allUris, cwd, arg));
}

CommandKind parsePrintCommand(ref Alloc alloc, scope ref AllUris allUris, Uri cwd, in SplitArgs args) {
	Opt!PrintKind kind = args.beforeFirstPart.length >= 2 && empty(args.parts) && empty(args.afterDashDash)
		? parsePrintKind(args.beforeFirstPart[0], args.beforeFirstPart[2 .. $])
		: none!PrintKind;
	return !args.help && has(kind)
		? withMainUri(alloc, allUris, cwd, args.beforeFirstPart[1], (Uri uri) =>
			CommandKind(CommandKind.Print(force(kind), uri)))
		: todo!CommandKind("CommandKind.HelpPrint");
}

Opt!PrintKind parsePrintKind(in SafeCStr a, in SafeCStr[] args) {
	Opt!PrintKind expectEmptyArgs(PrintKind x) =>
		empty(args) ? some(x) : none!PrintKind;

	Opt!PrintKind expectLineAndColumn(in PrintKind delegate(in LineAndColumn) @safe @nogc pure nothrow cb) {
		Opt!LineAndColumn lc = args.length == 1 ? parseLineAndColumn(args[0]) : none!LineAndColumn;
		return has(lc) ? some(cb(force(lc))) : none!PrintKind;
	}

	switch (strOfSafeCStr(a)) {
		case "tokens":
			return expectEmptyArgs(PrintKind(PrintKind.Tokens()));
		case "ast":
			return expectEmptyArgs(PrintKind(PrintKind.Ast()));
		case "model":
			return expectEmptyArgs(PrintKind(PrintKind.Model()));
		case "concrete-model":
			return expectEmptyArgs(PrintKind(PrintKind.ConcreteModel()));
		case "low-model":
			return expectEmptyArgs(PrintKind(PrintKind.LowModel()));
		default:
			Opt!(PrintKind.Ide.Kind) kind = optEnumOfString!(PrintKind.Ide.Kind)(strOfSafeCStr(a));
			return has(kind)
				? expectLineAndColumn((in LineAndColumn lc) => PrintKind(PrintKind.Ide(force(kind), lc)))
				: none!PrintKind;
	}
}

@trusted Opt!LineAndColumn parseLineAndColumn(in SafeCStr a) {
	immutable(char)* ptr = a.ptr;
	Opt!uint line = convertFrom1Indexed(tryTakeNat(ptr));
	bool colon = tryTakeChar(ptr, ':');
	Opt!uint column = convertFrom1Indexed(tryTakeNat(ptr));
	return has(line) && colon && has(column) && *ptr == '\0'
		? some(LineAndColumn(force(line), force(column)))
		: none!LineAndColumn;
}

Opt!uint convertFrom1Indexed(in Opt!uint a) =>
	has(a) && force(a) != 0
		? some(force(a) - 1)
		: none!uint;

@system Opt!uint tryTakeNat(ref immutable(char)* ptr) {
	if (isDecimalDigit(*ptr)) {
		LiteralNatAst res = takeNat(ptr, 10);
		return !res.overflow && isUint(res.value)
			? some(safeToUint(res.value))
			: none!uint;
	} else
		return none!uint;
}

CommandKind parseDocumentCommand(ref Alloc alloc, scope ref AllUris allUris, Uri cwd, in SplitArgs args) {
	CommandKind helpDocument = CommandKind(CommandKind.Help(helpDocumentText, args.help));
	return withRootUris(
		alloc,
		allUris,
		cwd,
		args.beforeFirstPart,
		(Uri[] x) =>
			!args.help && empty(args.parts) && empty(args.afterDashDash)
				? CommandKind(CommandKind.Document(x))
				: helpDocument);
}

CommandKind parseBuildCommand(ref Alloc alloc, scope ref AllUris allUris, Uri cwd, in SplitArgs args) {
	CommandKind helpBuild = CommandKind(CommandKind.Help(helpBuildText, args.help));
	return args.help || args.beforeFirstPart.length != 1
		? helpBuild
		: withMainUri(
			alloc,
			allUris,
			cwd,
			only(args.beforeFirstPart),
			(Uri main) {
				Opt!BuildOptions options = parseBuildOptions(alloc, allUris, cwd, args.parts, main);
				return has(options) && empty(args.afterDashDash)
					? CommandKind(CommandKind.Build(main, force(options)))
					: helpBuild;
			});
}

CommandKind parseRunCommand(ref Alloc alloc, scope ref AllUris allUris, Uri cwd, in SplitArgs args) {
	Opt!RunOptions options = parseRunOptions(alloc, allUris, args.parts);
	return !args.help && args.beforeFirstPart.length == 1 && has(options)
		? withMainUri(
			alloc,
			allUris,
			cwd,
			only(args.beforeFirstPart),
			(Uri x) =>
				CommandKind(CommandKind.Run(x, force(options), castNonScope(args.afterDashDash))))
		: CommandKind(CommandKind.Help(helpRunText, args.help));
}

Opt!RunOptions parseRunOptions(ref Alloc alloc, scope ref AllUris allUris, in ArgsPart[] argParts) {
	bool jit = false;
	bool optimize = false;
	foreach (ArgsPart part; argParts) {
		switch (strOfSafeCStr(part.tag)) {
			case "--jit":
				jit = true;
				break;
			case "--optimize":
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
	scope ref AllUris allUris,
	Uri cwd,
	in ArgsPart[] argParts,
	Uri mainUri,
) =>
	foldOrStop!(BuildOptions, ArgsPart)(
		// Default: unoptimized, compiled next to the source file
		BuildOptions(
			BuildOut(none!Uri, some(alterExtension!defaultExeExtension(allUris, mainUri))),
			CCompileOptions(OptimizationLevel.none)),
		argParts,
		(BuildOptions cur, ref ArgsPart part) {
			switch (strOfSafeCStr(part.tag)) {
				case "--out":
					Opt!BuildOut buildOut = parseBuildOut(alloc, allUris, cwd, part.args);
					return has(buildOut) ? some(withBuildOut(cur, force(buildOut))) : none!BuildOptions;
				case "--no-out":
					return empty(part.args)
						? some(withBuildOut(cur, BuildOut(none!Uri, none!Uri)))
						: none!BuildOptions;
				case "--optimize":
					return empty(part.args)
						? some(withCCompileOptions(cur, CCompileOptions(OptimizationLevel.o2)))
						: none!BuildOptions;
				default:
					return none!BuildOptions;
			}
		});

Opt!BuildOut parseBuildOut(ref Alloc alloc, scope ref AllUris allUris, Uri cwd, in SafeCStr[] args) =>
	foldOrStop!(BuildOut, SafeCStr)(
		emptyBuildOut(),
		args,
		(BuildOut o, ref SafeCStr arg) {
			Uri uri = parseUriWithCwd(allUris, cwd, arg);
			switch (getExtension(allUris, uri).value) {
				case sym!"".value:
					return has(o.outExecutable)
						? none!BuildOut
						: some(BuildOut(o.outC, some(uri)));
				case cExtension.value:
					return has(o.outC)
						? none!BuildOut
						: some(BuildOut(some(uri), o.outExecutable));
				default:
					return none!BuildOut;
			}
		});

immutable struct ArgsPart {
	SafeCStr tag; // includes the "--"
	SafeCStr[] args;
}

immutable struct SplitArgs {
	SafeCStr[] beforeFirstPart;
	ArgsPart[] parts;
	// After seeing a '--' we stop parsing and just return the rest raw.
	SafeCStr[] afterDashDash;
	bool help;
}
bool isEmpty(in SplitArgs a) =>
	empty(a.beforeFirstPart) && empty(a.parts) && empty(a.afterDashDash) && !a.help;


immutable struct SplitArgsAndOptions {
	SplitArgs args;
	CommandOptions options;
}

SplitArgsAndOptions splitArgs(ref Alloc alloc, return scope SafeCStr[] args) {
	Opt!size_t optFirstArgIndex = findIndex!SafeCStr(args, (in SafeCStr arg) =>
		startsWithDashDash(arg));
	if (!has(optFirstArgIndex))
		return SplitArgsAndOptions(SplitArgs(args, [], []), CommandOptions());
	else {
		size_t firstArgIndex = force(optFirstArgIndex);
		Opt!size_t dashDash = findIndex!SafeCStr(args[firstArgIndex .. $], (in SafeCStr arg) =>
			safeCStrEq(arg, "--"));
		NamedArgs namedArgs = splitNamedArgs(alloc, has(dashDash) ? args[firstArgIndex .. firstArgIndex + force(dashDash)] : args[firstArgIndex .. $]);
		return SplitArgsAndOptions(
			SplitArgs(args[0 .. firstArgIndex], namedArgs.parts, has(dashDash) ? args[firstArgIndex + force(dashDash) + 1 .. $] : [], namedArgs.help),
			namedArgs.options);
	}
}

@trusted bool startsWithDashDash(in SafeCStr a) =>
	a.ptr[0] == '-' && a.ptr[1] == '-';

struct NamedArgs {
	ArgsPart[] parts;
	CommandOptions options;
	bool help;
}

NamedArgs splitNamedArgs(ref Alloc alloc, in SafeCStr[] args) {
	if (empty(args))
		return NamedArgs([], CommandOptions(), false);

	ArrBuilder!ArgsPart parts;
	bool help = false;
	bool perf = false;
	assert(startsWithDashDash(args[0]));
	MutOpt!size_t curPartStart;

	void finishPart(size_t i) {
		if (has(curPartStart)) {
			add(alloc, parts, ArgsPart(args[force(curPartStart)], args[force(curPartStart) + 1 .. i]));
			curPartStart = noneMut!size_t;
		}
	}

	foreach (size_t i, SafeCStr arg; args) {
		if (startsWithDashDash(arg)) {
			finishPart(i);
			if (safeCStrEq(arg, "--help"))
				help = true;
			else if (safeCStrEq(arg, "--perf"))
				perf = true;
			else
				curPartStart = someMut(i);
		}
	}
	finishPart(args.length);

	return NamedArgs(finishArr(alloc, parts), CommandOptions(perf), help);
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
