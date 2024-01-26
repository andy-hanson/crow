module lib.cliParser;

@safe @nogc pure nothrow:

import frontend.lang : JitOptions, OptimizationLevel;
import frontend.parse.lexToken : takeNat;
import frontend.parse.lexUtil : isDecimalDigit, startsWith, tryTakeChar;
import model.ast : LiteralNatAst;
import util.alloc.alloc : Alloc;
import util.cell : Cell, cellGet, cellSet;
import util.col.array : copyArray, findIndex, isEmpty, mapOrNone, only;
import util.col.arrayBuilder : add, ArrayBuilder, finish;
import util.conv : isUint, safeToUint;
import util.opt : force, has, MutOpt, none, noneMut, Opt, some, someMut;
import util.sourceRange : LineAndColumn;
import util.string : CString, cString, MutCString, stringOfCString;
import util.symbol : Extension;
import util.union_ : Union;
import util.uri :
	addExtension,
	alterExtension,
	AllUris,
	asFileUri,
	FileUri,
	getExtension,
	isFileUri,
	parseFileUriWithCwd,
	parseUriWithCwd,
	Uri;
import util.util : castNonScope, optEnumOfString, todo;
import versionInfo : OS;

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
		CString helpText;
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
		CString[] programArgs;
	}
	immutable struct Test {
		CString[] names;
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
	immutable struct Aot {
		CCompileOptions compileOptions;
		Extension defaultExeExtension;
	}
	mixin Union!(Interpret, Jit, Aot);
}

immutable struct BuildOptions {
	BuildOut out_;
	CCompileOptions cCompileOptions;
}

immutable struct CCompileOptions {
	OptimizationLevel optimizationLevel;
}

immutable struct BuildOut {
	Opt!FileUri outC;
	bool shouldBuildExecutable;
	// If 'shouldBuildExecutable' is not set, this is hypothetical (used for comment at top of C file)
	Opt!FileUri outExecutable;
}

bool hasAnyOut(in BuildOut a) =>
	has(a.outC) || a.shouldBuildExecutable;

Command parseCommand(ref Alloc alloc, scope ref AllUris allUris, Uri cwd, OS os, in CString[] args) {
	if (isEmpty(args))
		return Command(CommandKind(CommandKind.Help(helpAllText)));
	else {
		SplitArgsAndOptions split = splitArgs(alloc, args[1 .. $]);
		return Command(
			parseCommandKind(alloc, allUris, cwd, os, stringOfCString(args[0]), split.args),
			split.options);
	}
}

private:

CommandKind parseCommandKind(
	ref Alloc alloc,
	scope ref AllUris allUris,
	Uri cwd,
	OS os,
	in string commandName,
	in SplitArgs args,
) {
	Extension defaultExeExtension = getDefaultExeExtension(os);
	switch (commandName) {
		case "build":
			return parseBuildCommand(alloc, allUris, cwd, defaultExeExtension, args);
		case "document":
			return parseDocumentCommand(alloc, allUris, cwd, args);
		case "lsp":
			return isEmpty(args)
				? CommandKind(CommandKind.Lsp())
				: CommandKind(CommandKind.Help(cString!"Usage: 'crow lsp' (no args)", args.help));
		case "print":
			return parsePrintCommand(alloc, allUris, cwd, args);
		case "run":
			return parseRunCommand(alloc, allUris, cwd, defaultExeExtension, args);
		case "test":
			return !args.help && isEmpty(args.parts) && isEmpty(args.afterDashDash)
				? CommandKind(CommandKind.Test(copyArray(alloc, args.beforeFirstPart)))
				: todo!CommandKind("help for 'test'");
		case "version":
			return isEmpty(args)
				? CommandKind(CommandKind.Version())
				: CommandKind(CommandKind.Help(cString!"Usage: 'crow version' (no args)", args.help));
		default:
			return CommandKind(CommandKind.Help(helpAllText, args.help));
	}
}

Extension getDefaultExeExtension(OS os) {
	final switch (os) {
		case OS.linux:
			return Extension.none;
		case OS.web:
			assert(false);
		case OS.windows:
			return Extension.exe;
	}
}

BuildOut emptyBuildOut() =>
	BuildOut(none!FileUri, false, none!FileUri);

CommandKind withMainUri(
	ref Alloc alloc,
	scope ref AllUris allUris,
	Uri cwd,
	in CString arg,
	in CommandKind delegate(Uri) @safe pure @nogc nothrow cb,
) {
	Opt!Uri p = tryParseCrowUri(alloc, allUris, cwd, arg);
	return has(p) ? cb(force(p)) : CommandKind(CommandKind.Help(cString!"Invalid path"));
}

CommandKind withRootUris(
	ref Alloc alloc,
	scope ref AllUris allUris,
	Uri cwd,
	in CString[] args,
	in CommandKind delegate(Uri[]) @safe pure @nogc nothrow cb,
) {
	Opt!(Uri[]) p = tryParseRootUris(alloc, allUris, cwd, args);
	return has(p) ? cb(force(p)) : CommandKind(CommandKind.Help(cString!"Invalid path"));
}

Opt!Uri tryParseCrowUri(ref Alloc alloc, scope ref AllUris allUris, Uri cwd, in CString arg) {
	Uri uri = parseUriWithCwd(allUris, cwd, arg);
	switch (getExtension(allUris, uri)) {
		case Extension.none:
			return some(addExtension(allUris, uri, Extension.crow));
		case Extension.crow:
			return some(uri);
		default:
			return none!Uri;
	}
}

Opt!(Uri[]) tryParseRootUris(ref Alloc alloc, scope ref AllUris allUris, Uri cwd, in CString[] args) {
	assert(!isEmpty(args));
	return mapOrNone!(Uri, CString)(alloc, args, (ref CString arg) =>
		tryParseCrowUri(alloc, allUris, cwd, arg));
}

CommandKind parsePrintCommand(ref Alloc alloc, scope ref AllUris allUris, Uri cwd, in SplitArgs args) {
	Opt!PrintKind kind = args.beforeFirstPart.length >= 2 && isEmpty(args.parts) && isEmpty(args.afterDashDash)
		? parsePrintKind(args.beforeFirstPart[0], args.beforeFirstPart[2 .. $])
		: none!PrintKind;
	return !args.help && has(kind)
		? withMainUri(alloc, allUris, cwd, args.beforeFirstPart[1], (Uri uri) =>
			CommandKind(CommandKind.Print(force(kind), uri)))
		: todo!CommandKind("CommandKind.HelpPrint");
}

Opt!PrintKind parsePrintKind(in CString a, in CString[] args) {
	Opt!PrintKind expectEmptyArgs(PrintKind x) =>
		isEmpty(args) ? some(x) : none!PrintKind;

	Opt!PrintKind expectLineAndColumn(in PrintKind delegate(in LineAndColumn) @safe @nogc pure nothrow cb) {
		Opt!LineAndColumn lc = args.length == 1 ? parseLineAndColumn(args[0]) : none!LineAndColumn;
		return has(lc) ? some(cb(force(lc))) : none!PrintKind;
	}

	switch (stringOfCString(a)) {
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
			Opt!(PrintKind.Ide.Kind) kind = optEnumOfString!(PrintKind.Ide.Kind)(stringOfCString(a));
			return has(kind)
				? expectLineAndColumn((in LineAndColumn lc) => PrintKind(PrintKind.Ide(force(kind), lc)))
				: none!PrintKind;
	}
}

Opt!LineAndColumn parseLineAndColumn(in CString a) {
	MutCString ptr = a;
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

Opt!uint tryTakeNat(ref MutCString ptr) {
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
			!args.help && isEmpty(args.parts) && isEmpty(args.afterDashDash)
				? CommandKind(CommandKind.Document(x))
				: helpDocument);
}

CommandKind parseBuildCommand(
	ref Alloc alloc,
	scope ref AllUris allUris,
	Uri cwd,
	Extension defaultExeExtension,
	in SplitArgs args,
) {
	CommandKind helpBuild = CommandKind(CommandKind.Help(helpBuildText, args.help));
	return args.help || args.beforeFirstPart.length != 1
		? helpBuild
		: withMainUri(
			alloc,
			allUris,
			cwd,
			only(args.beforeFirstPart),
			(Uri main) {
				Opt!BuildOptions options = parseBuildOptions(
					alloc, allUris, cwd, defaultExeExtension, args.parts, main);
				return has(options) && isEmpty(args.afterDashDash)
					? CommandKind(CommandKind.Build(main, force(options)))
					: helpBuild;
			});
}

CommandKind parseRunCommand(
	ref Alloc alloc,
	scope ref AllUris allUris,
	Uri cwd,
	Extension defaultExeExtension,
	in SplitArgs args,
) {
	Opt!RunOptions options = parseRunOptions(alloc, allUris, defaultExeExtension, args.parts);
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

Opt!RunOptions parseRunOptions(
	ref Alloc alloc,
	scope ref AllUris allUris,
	Extension defaultExeExtension,
	in ArgsPart[] argParts,
) {
	bool aot = false;
	bool jit = false;
	bool optimize = false;
	foreach (ArgsPart part; argParts) {
		switch (stringOfCString(part.tag)) {
			case "--aot":
				aot = true;
				break;
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
	if (aot)
		return jit
			? none!RunOptions
			: some(RunOptions(RunOptions.Aot(
				optimize ? CCompileOptions(OptimizationLevel.o2) : CCompileOptions(),
				defaultExeExtension)));
	else if (jit)
		return aot
			? none!RunOptions
			: some(RunOptions(RunOptions.Jit(optimize ? JitOptions(OptimizationLevel.o2) : JitOptions())));
	else
		return optimize
			? none!RunOptions
			: some(RunOptions(RunOptions.Interpret()));
}

Opt!BuildOptions parseBuildOptions(
	ref Alloc alloc,
	scope ref AllUris allUris,
	Uri cwd,
	Extension defaultExeExtension,
	in ArgsPart[] argParts,
	Uri mainUri,
) {
	Cell!(Opt!BuildOut) out_;
	bool optimize = false;
	bool noOut = false;
	bool error = false;
	foreach (ArgsPart part; argParts) {
		switch (stringOfCString(part.tag)) {
			case "--out":
				if (has(cellGet(out_)))
					error = true;
				else
					cellSet(out_, some(parseBuildOut(alloc, allUris, cwd, defaultExeExtension, part.args, error)));
				break;
			case "--no-out":
				error = error || noOut || !isEmpty(part.args);
				noOut = true;
				break;
			case "--optimize":
				error = error || optimize || !isEmpty(part.args);
				optimize = true;
				break;
			default:
				error = true;
		}
	}

	CCompileOptions options = CCompileOptions(optimize ? OptimizationLevel.o2 : OptimizationLevel.none);
	error = error || ((has(cellGet(out_)) || optimize) && noOut);
	if (error)
		return none!BuildOptions;
	else if (noOut)
		return some(BuildOptions(emptyBuildOut, CCompileOptions()));
	else {
		if (has(cellGet(out_)))
			return some(BuildOptions(force(cellGet(out_)), options));
		else if (isFileUri(allUris, mainUri))
			return some(BuildOptions(
				BuildOut(
					outC: none!FileUri,
					shouldBuildExecutable: true,
					outExecutable: some(defaultExeUri(allUris, asFileUri(allUris, mainUri), defaultExeExtension))),
				options));
		else
			return none!BuildOptions;
	}
}

BuildOut parseBuildOut(
	ref Alloc alloc,
	scope ref AllUris allUris,
	Uri cwd,
	Extension defaultExeExtension,
	in CString[] args,
	ref bool error,
) {
	Cell!(Opt!FileUri) outC;
	Cell!(Opt!FileUri) outExe;
	foreach (CString arg; args) {
		Opt!FileUri opt = parseFileUriWithCwd(allUris, cwd, arg);
		if (has(opt)) {
			FileUri uri = force(opt);
			Extension extension = getExtension(allUris, uri);
			if (extension == defaultExeExtension) {
				error = error || has(cellGet(outExe));
				cellSet(outExe, some(uri));
			} else if (extension == Extension.c) {
				error = error || has(cellGet(outC));
				cellSet(outC, some(uri));
			} else
				error = true;
		} else
			error = true;
	}
	if (has(cellGet(outC)) || has(cellGet(outExe)))
		return BuildOut(
			outC: cellGet(outC),
			shouldBuildExecutable: has(cellGet(outExe)),
			outExecutable: some(has(cellGet(outExe))
				? force(cellGet(outExe))
				: defaultExeUri(allUris, force(cellGet(outC)), defaultExeExtension)));
	else {
		error = true;
		return emptyBuildOut;
	}
}

FileUri defaultExeUri(scope ref AllUris allUris, FileUri base, Extension defaultExeExtension) =>
	alterExtension(allUris, base, defaultExeExtension);

immutable struct ArgsPart {
	CString tag; // includes the "--"
	CString[] args;
}

immutable struct SplitArgs {
	CString[] beforeFirstPart;
	ArgsPart[] parts;
	// After seeing a '--' we stop parsing and just return the rest raw.
	CString[] afterDashDash;
	bool help;
}
bool isEmpty(in SplitArgs a) =>
	isEmpty(a.beforeFirstPart) && isEmpty(a.parts) && isEmpty(a.afterDashDash) && !a.help;

immutable struct SplitArgsAndOptions {
	SplitArgs args;
	CommandOptions options;
}

SplitArgsAndOptions splitArgs(ref Alloc alloc, return scope CString[] args) {
	Opt!size_t optFirstArgIndex = findIndex!CString(args, (in CString arg) =>
		startsWithDashDash(arg));
	if (!has(optFirstArgIndex))
		return SplitArgsAndOptions(SplitArgs(args, [], []), CommandOptions());
	else {
		size_t firstArgIndex = force(optFirstArgIndex);
		Opt!size_t dashDash = findIndex!CString(args[firstArgIndex .. $], (in CString arg) =>
			arg == "--");
		NamedArgs namedArgs = splitNamedArgs(
			alloc, has(dashDash) ? args[firstArgIndex .. firstArgIndex + force(dashDash)] : args[firstArgIndex .. $]);
		return SplitArgsAndOptions(
			SplitArgs(
				args[0 .. firstArgIndex],
				namedArgs.parts,
				has(dashDash) ? args[firstArgIndex + force(dashDash) + 1 .. $] : [],
				namedArgs.help),
			namedArgs.options);
	}
}

bool startsWithDashDash(in CString a) =>
	startsWith(a, "--");

struct NamedArgs {
	ArgsPart[] parts;
	CommandOptions options;
	bool help;
}

NamedArgs splitNamedArgs(ref Alloc alloc, in CString[] args) {
	if (isEmpty(args))
		return NamedArgs([], CommandOptions(), false);

	ArrayBuilder!ArgsPart parts;
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

	foreach (size_t i, CString arg; args) {
		if (startsWithDashDash(arg)) {
			finishPart(i);
			if (arg == "--help")
				help = true;
			else if (arg == "--perf")
				perf = true;
			else
				curPartStart = someMut(i);
		}
	}
	finishPart(args.length);

	return NamedArgs(finish(alloc, parts), CommandOptions(perf), help);
}

CString helpAllText() =>
	cString!("Commands: (type a command then '--help' to see more)\n" ~
	"\t'crow build'\n" ~
	"\t'crow run'\n" ~
	"\t'crow version'");

CString helpDocumentText() =>
	cString!("Command: crow document PATH\n" ~
	"\tGenerates JSON documentation for the module at PATH.\n");

CString helpBuildText() =>
	cString!("Command: crow build PATH --out OUT [options]\n" ~
	"Compiles the program at PATH. The '.crow' extension is optional.\n" ~
	"Writes an executable to OUT. If OUT has a '.c' extension, it will be C source code instead.\n" ~
	"Options are:\n" ~
	"\t--optimize : Enables optimizations.\n");

CString helpRunText() =>
	cString!("Command: crow run PATH [options] -- [program-args]\n" ~
	"Runs the program at PATH. The '.crow' extension is optional." ~
	"Arguments after '--' will be sent to the program.\n" ~
	"Options are:\n" ~
	"\t--jit : Just-In-Time compile the code (instead of the default interpreter).\n" ~
	"\t--optimize : Use with '--jit'. Enables optimizations.\n");
