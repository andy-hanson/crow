module app.parseCommand;

@safe @nogc pure nothrow:

import app.command : BuildOptions, BuildOut, Command, CommandKind, CommandOptions, RunOptions;
import frontend.lang : CCompileOptions, JitOptions, OptimizationLevel;
import frontend.parse.lexToken : takeNat;
import frontend.parse.lexUtil : isDecimalDigit, startsWith, tryTakeChar;
import lib.server : PrintKind;
import model.ast : LiteralNatAst;
import util.alloc.alloc : Alloc;
import util.cell : Cell, cellGet, cellSet;
import util.col.array : copyArray, findIndex, isEmpty, mapOrNone, only;
import util.col.arrayBuilder : buildArray, Builder, finish;
import util.conv : isUint, safeToUint;
import util.exitCode : ExitCode;
import util.opt : force, has, MutOpt, none, noneMut, Opt, optOrDefault, some, someMut;
import util.sourceRange : LineAndColumn;
import util.string : CString, cString, MutCString, stringOfCString;
import util.symbol : Extension, symbol;
import util.union_ : Union;
import util.uri :
	addExtension,
	alterExtension,
	AllUris,
	asFileUri,
	childFileUri,
	FileUri,
	getExtension,
	isFileUri,
	parseFileUriWithCwd,
	parseUriWithCwd,
	Uri;
import util.util : castNonScope, enumEach, optEnumOfString, stringOfEnum, typeAs;
import util.writer : makeStringWithWriter, writeNewline, writeQuotedString, Writer;
import versionInfo : OS;

Command parseCommand(ref Alloc alloc, scope ref AllUris allUris, FileUri cwd, OS os, in CString[] args) {
	Opt!CommandName optName = isEmpty(args) ? none!CommandName : optEnumOfString!CommandName(stringOfCString(args[0]));
	if (has(optName)) {
		CommandName name = force(optName);
		SplitArgsAndOptions split = splitArgs(alloc, args[1 .. $]);
		if (split.help)
			return Command(
				CommandKind(CommandKind.Help(helpForCommand(name), ExitCode.ok)),
				split.options);
		else {
			Builder!Diag diagsBuilder = Builder!Diag(&alloc);
			CommandKind res = parseCommandKind(alloc, allUris, cwd, os, name, split.args, diagsBuilder);
			Diag[] diags = finish(diagsBuilder);
			if (isEmpty(diags))
				return Command(res, split.options);
			else {
				string help = makeStringWithWriter(alloc, (scope ref Writer writer) {
					writer ~= "Command syntax error: ";
					foreach (Diag x; diags) {
						writeDiag(writer, x);
						writeNewline(writer, 0);
					}
					writeNewline(writer, 0);
					writer ~= helpForCommand(name);
				});
				return Command(CommandKind(CommandKind.Help(help, ExitCode.error)), split.options);
			}
		}
	} else
		return Command(
			CommandKind(CommandKind.Help(
				helpAllText(alloc),
				!isEmpty(args) && (args[0] == "help" || args[0] == "--help") ? ExitCode.ok : ExitCode.error)),
			CommandOptions(perf: false));
}

private:

CommandKind dummyCommand() =>
	CommandKind(CommandKind.Help("This should not appear", ExitCode.error));

enum CommandName {
	build,
	check,
	document,
	lsp,
	print,
	run,
	test,
	version_,
}

// We always combine this with the commandName, so no need to include it here
immutable struct Diag {
	immutable struct BuildOutDuplicate {}
	immutable struct BuildOutBadFileExtension {
		Extension executableExtension;
	}
	immutable struct DuplicatePart { CString tag; }
	immutable struct ExpectedPaths { CString tag; }
	immutable struct NeedsSinglePath { size_t actual; }
	immutable struct ParseFileUri { CString actual; }
	immutable struct PrintKind {}
	immutable struct UnexpectedPart { CString tag; }
	immutable struct UnexpectedPartArgs { ArgsPart part; }
	immutable struct UnexpectedBefore { CString arg; }
	immutable struct RunAotAndJit {}
	immutable struct RunOptimizeNeedsAotOrJit {}

	mixin Union!(
		BuildOutDuplicate,
		BuildOutBadFileExtension,
		DuplicatePart,
		ExpectedPaths,
		NeedsSinglePath,
		ParseFileUri,
		PrintKind,
		UnexpectedPart,
		UnexpectedPartArgs,
		UnexpectedBefore,
		RunAotAndJit,
		RunOptimizeNeedsAotOrJit);
}

void writeDiag(scope ref Writer writer, in Diag a) {
	a.matchIn!void(
		(in Diag.BuildOutDuplicate) {
			writer ~= "Crow does not support building to multiple files (except to both C and executable).";
		},
		(in Diag.BuildOutBadFileExtension x) {
			writer ~= "Build output must be a '.c' or ";
			writeExtension(writer, x.executableExtension);
			writer ~= " file.";
		},
		(in Diag.DuplicatePart x) {
			writer ~= "Argument ";
			writeQuotedString(writer, x.tag);
			writer ~= " appears twice.";
		},
		(in Diag.ExpectedPaths x) {
			writer ~= "Argument ";
			writeQuotedString(writer, x.tag);
			writer ~= " expects a list of paths.";
		},
		(in Diag.NeedsSinglePath x) {
			if (x.actual == 0)
				writer ~= "This command needs a path.";
			else {
				writer ~= "This command expects a single path. Instead got ";
				writer ~= x.actual;
				writer ~= '.';
			}
		},
		(in Diag.ParseFileUri x) {
			writer ~= "Not a valid file path: ";
			writeQuotedString(writer, x.actual);
			writer ~= '.';
		},
		(in Diag.PrintKind) {
			writer ~= "Not a valid print command.";
		},
		(in Diag.UnexpectedPart x) {
			writer ~= "Unexpected argument ";
			writeQuotedString(writer, x.tag);
			writer ~= '.';
		},
		(in Diag.UnexpectedPartArgs x) {
			writer ~= "Argument ";
			writeQuotedString(writer, x.part.tag);
			writer ~= " is a flag and should not have any values (starting with ";
			writeQuotedString(writer, x.part.args[0]);
			writer ~= ".";
		},
		(in Diag.UnexpectedBefore x) {
			writer ~= "*Unexpected un-named argument ";
			writeQuotedString(writer, x.arg);
			writer ~= '.';
		},
		(in Diag.RunAotAndJit) {
			writer ~= "Can't specify both '--aot' and '--jit'.";
		},
		(in Diag.RunOptimizeNeedsAotOrJit) {
			writer ~= "'--optimize' must be combined with '--aot' or '--jit'.";
		});
}

void writeExtension(scope ref Writer writer, Extension a) {
	if (a == Extension.none)
		writer ~= "extensionless";
	else {
		writer ~= "\".";
		writer ~= stringOfEnum(a);
		writer ~= '"';
	}
}

CommandKind parseCommandKind(
	ref Alloc alloc,
	scope ref AllUris allUris,
	FileUri cwd,
	OS os,
	CommandName commandName,
	in SplitArgs args,
	scope ref Builder!Diag diags,
) {
	final switch (commandName) {
		case CommandName.build:
			return parseBuildCommand(alloc, allUris, cwd, diags, getDefaultExeExtension(os), args);
		case CommandName.check:
			expectEmptyParts(diags, args.parts);
			expectEmptyAfterDashDash(diags, args.afterDashDash);
			return withRootUris(alloc, allUris, cwd, args.beforeFirstPart, (Uri[] x) =>
				CommandKind(CommandKind.Check(x)));
		case CommandName.document:
			expectEmptyParts(diags, args.parts);
			expectEmptyAfterDashDash(diags, args.afterDashDash);
			return withRootUris(alloc, allUris, cwd, args.beforeFirstPart, (Uri[] x) =>
				CommandKind(CommandKind.Document(x)));
		case CommandName.lsp:
			expectAllEmpty(diags, args);
			return CommandKind(CommandKind.Lsp());
		case CommandName.print:
			return parsePrintCommand(alloc, allUris, cwd, diags, args);
		case CommandName.run:
			RunOptions options = parseRunOptions(alloc, allUris, getDefaultExeExtension(os), diags, args.parts);
			return withMainUri(alloc, allUris, cwd, diags, args.beforeFirstPart, (Uri x) =>
				CommandKind(CommandKind.Run(
					x,
					options,
					optOrDefault!(CString[])(castNonScope(args.afterDashDash), () => typeAs!(CString[])([])))));
		case CommandName.test:
			expectEmptyParts(diags, args.parts);
			expectEmptyAfterDashDash(diags, args.afterDashDash);
			return CommandKind(CommandKind.Test(copyArray(alloc, args.beforeFirstPart)));
		case CommandName.version_:
			expectAllEmpty(diags, args);
			return CommandKind(CommandKind.Version());
	}
}

void expectAllEmpty(scope ref Builder!Diag diags, in SplitArgs args) {
	expectEmptyBefore(diags, args.beforeFirstPart);
	expectEmptyParts(diags, args.parts);
	expectEmptyAfterDashDash(diags, args.afterDashDash);
}

void expectEmptyBefore(scope ref Builder!Diag diags, in CString[] before) {
	if (!isEmpty(before))
		diags ~= Diag(Diag.UnexpectedBefore(before[0]));
}
void expectEmptyParts(scope ref Builder!Diag diags, in ArgsPart[] parts) {
	foreach (ArgsPart part; parts)
		diags ~= Diag(Diag.UnexpectedPart(part.tag));
}
void expectEmptyAfterDashDash(scope ref Builder!Diag diags, in Opt!(CString[]) after) {
	if (has(after))
		diags ~= Diag(Diag.UnexpectedPart(cString!"--"));
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

CommandKind withMainUri(
	ref Alloc alloc,
	scope ref AllUris allUris,
	FileUri cwd,
	scope ref Builder!Diag diags,
	in CString[] args,
	in CommandKind delegate(Uri) @safe pure @nogc nothrow cb,
) {
	if (args.length != 1) {
		diags ~= Diag(Diag.NeedsSinglePath(args.length));
		return dummyCommand;
	} else {
		Opt!Uri p = tryParseCrowUri(alloc, allUris, cwd, only(args));
		return has(p) ? cb(force(p)) : CommandKind(CommandKind.Help("Invalid path"));
	}
}

CommandKind withRootUris(
	ref Alloc alloc,
	scope ref AllUris allUris,
	FileUri cwd,
	in CString[] args,
	in CommandKind delegate(Uri[]) @safe pure @nogc nothrow cb,
) {
	Opt!(Uri[]) p = tryParseRootUris(alloc, allUris, cwd, args);
	return has(p) ? cb(force(p)) : CommandKind(CommandKind.Help("Invalid path"));
}

Opt!Uri tryParseCrowUri(ref Alloc alloc, scope ref AllUris allUris, FileUri cwd, in CString arg) {
	Uri uri = parseUriWithCwd(allUris, cwd, stringOfCString(arg));
	switch (getExtension(allUris, uri)) {
		case Extension.none:
			return some(addExtension(allUris, uri, Extension.crow));
		case Extension.crow:
			return some(uri);
		default:
			return none!Uri;
	}
}

Opt!(Uri[]) tryParseRootUris(ref Alloc alloc, scope ref AllUris allUris, FileUri cwd, in CString[] args) {
	assert(!isEmpty(args));
	return mapOrNone!(Uri, CString)(alloc, args, (ref CString arg) =>
		tryParseCrowUri(alloc, allUris, cwd, arg));
}

CommandKind parsePrintCommand(
	ref Alloc alloc,
	scope ref AllUris allUris,
	FileUri cwd,
	scope ref Builder!Diag diags,
	in SplitArgs args,
) {
	expectEmptyParts(diags, args.parts);
	expectEmptyAfterDashDash(diags, args.afterDashDash);
	Opt!PrintKind kind = args.beforeFirstPart.length >= 2
		? parsePrintKind(args.beforeFirstPart[0], args.beforeFirstPart[2 .. $])
		: none!PrintKind;
	if (has(kind))
		return withMainUri(alloc, allUris, cwd, diags, args.beforeFirstPart[1 .. $], (Uri uri) =>
			CommandKind(CommandKind.Print(force(kind), uri)));
	else {
		diags ~= Diag(Diag.PrintKind());
		return dummyCommand;
	}
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

CommandKind parseBuildCommand(
	ref Alloc alloc,
	scope ref AllUris allUris,
	FileUri cwd,
	scope ref Builder!Diag diags,
	Extension defaultExeExtension,
	in SplitArgs args,
) {
	expectEmptyAfterDashDash(diags, args.afterDashDash);
	return withMainUri(alloc, allUris, cwd, diags, args.beforeFirstPart, (Uri main) =>
		CommandKind(CommandKind.Build(
			main, parseBuildOptions(alloc, allUris, cwd, diags, defaultExeExtension, args.parts, main))));
}

RunOptions parseRunOptions(
	ref Alloc alloc,
	scope ref AllUris allUris,
	Extension defaultExeExtension,
	scope ref Builder!Diag diags,
	in ArgsPart[] argParts,
) {
	bool aot = false;
	bool jit = false;
	bool optimize = false;
	foreach (ArgsPart part; argParts) {
		expectFlag(diags, part);
		switch (stringOfCString(part.tag)) {
			case "--aot":
				if (aot) diags ~= Diag(Diag.DuplicatePart(part.tag));
				aot = true;
				break;
			case "--jit":
				if (jit) diags ~= Diag(Diag.DuplicatePart(part.tag));
				jit = true;
				break;
			case "--optimize":
				if (optimize) diags ~= Diag(Diag.DuplicatePart(part.tag));
				optimize = true;
				break;
			default:
				diags ~= Diag(Diag.UnexpectedPart(part.tag));
		}
	}

	if (aot && jit)
		diags ~= Diag(Diag.RunAotAndJit());
	if (!aot && !jit && optimize)
		diags ~= Diag(Diag.RunOptimizeNeedsAotOrJit());
	return aot
		? RunOptions(RunOptions.Aot(
			optimize ? CCompileOptions(OptimizationLevel.o2) : CCompileOptions(),
			defaultExeExtension))
		: jit
		? RunOptions(RunOptions.Jit(optimize ? JitOptions(OptimizationLevel.o2) : JitOptions()))
		: RunOptions(RunOptions.Interpret());
}

void expectFlag(scope ref Builder!Diag diags, ArgsPart part) {
	if (!isEmpty(part.args))
		diags ~= Diag(Diag.UnexpectedPartArgs(part));
}

BuildOptions parseBuildOptions(
	ref Alloc alloc,
	scope ref AllUris allUris,
	FileUri cwd,
	scope ref Builder!Diag diags,
	Extension defaultExeExtension,
	in ArgsPart[] argParts,
	Uri mainUri,
) {
	Cell!(Opt!BuildOut) out_;
	bool optimize = false;
	foreach (ArgsPart part; argParts) {
		switch (stringOfCString(part.tag)) {
			case "--out":
				if (has(cellGet(out_)))
					diags ~= Diag(Diag.DuplicatePart(part.tag));
				else
					cellSet(out_, some(parseBuildOut(alloc, allUris, cwd, defaultExeExtension, diags, part)));
				break;
			case "--optimize":
				expectFlag(diags, part);
				if (optimize)
					diags ~= Diag(Diag.DuplicatePart(part.tag));
				optimize = true;
				break;
			default:
				diags ~= Diag(Diag.UnexpectedPart(part.tag));
		}
	}

	CCompileOptions options = CCompileOptions(optimize ? OptimizationLevel.o2 : OptimizationLevel.none);
	BuildOut resOut = has(cellGet(out_))
		? force(cellGet(out_))
		: BuildOut(
			outC: none!FileUri,
			shouldBuildExecutable: true,
			outExecutable: defaultExeUri(
				allUris,
				isFileUri(allUris, mainUri) ? asFileUri(allUris, mainUri) : childFileUri(allUris, cwd, symbol!"main"),
				defaultExeExtension));
	return BuildOptions(resOut, options);
}

BuildOut parseBuildOut(
	ref Alloc alloc,
	scope ref AllUris allUris,
	FileUri cwd,
	Extension defaultExeExtension,
	scope ref Builder!Diag diags,
	ArgsPart part,
) {
	Cell!(Opt!FileUri) outC;
	Cell!(Opt!FileUri) outExe;
	foreach (CString arg; part.args) {
		Opt!FileUri opt = parseFileUriWithCwd(allUris, cwd, arg);
		if (has(opt)) {
			FileUri uri = force(opt);
			Extension extension = getExtension(allUris, uri);
			if (extension == Extension.c) {
				if (has(cellGet(outC)))
					diags ~= Diag(Diag.BuildOutDuplicate());
				cellSet(outC, some(uri));
			} else {
				if (has(cellGet(outExe)))
					diags ~= Diag(Diag.BuildOutDuplicate());
				if (extension != defaultExeExtension)
					diags ~= Diag(Diag.BuildOutBadFileExtension(defaultExeExtension));
				cellSet(outExe, some(uri));
			}
		} else
			diags ~= Diag(Diag.ParseFileUri(arg));
	}
	if (!has(cellGet(outC)) && !has(cellGet(outExe)))
		diags ~= Diag(Diag.ExpectedPaths(part.tag));
	return BuildOut(
		outC: cellGet(outC),
		shouldBuildExecutable: has(cellGet(outExe)),
		outExecutable: optOrDefault!FileUri(cellGet(outExe), () =>
			defaultExeUri(allUris, force(cellGet(outC)), defaultExeExtension)));
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
	Opt!(CString[]) afterDashDash;
}

immutable struct SplitArgsAndOptions {
	SplitArgs args;
	CommandOptions options;
	bool help;
}

SplitArgsAndOptions splitArgs(ref Alloc alloc, return scope CString[] args) {
	Opt!size_t optFirstArgIndex = findIndex!CString(args, (in CString arg) =>
		startsWithDashDash(arg));
	if (!has(optFirstArgIndex))
		return SplitArgsAndOptions(SplitArgs(args, [], none!(CString[])), CommandOptions(perf: false));
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
				has(dashDash) ? some(args[firstArgIndex + force(dashDash) + 1 .. $]) : none!(CString[])),
			namedArgs.options,
			namedArgs.help);
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
	bool help = false;
	bool perf = false;
	ArgsPart[] parts = buildArray!ArgsPart(alloc, (scope ref Builder!ArgsPart res) {
		assert(isEmpty(args) || startsWithDashDash(args[0]));
		MutOpt!size_t curPartStart;

		void finishPart(size_t i) {
			if (has(curPartStart)) {
				res ~= ArgsPart(args[force(curPartStart)], args[force(curPartStart) + 1 .. i]);
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
	});
	return NamedArgs(parts, CommandOptions(perf), help);
}

string helpAllText(ref Alloc alloc) =>
	makeStringWithWriter(alloc, (scope ref Writer writer) {
		writer ~= "Crow is divided into several commands. Type 'crow x --help' where 'x' is one of:";
		enumEach!CommandName((CommandName name) {
			writeNewline(writer, 1);
			writer ~= stringOfEnum(name);
		});
	});

string helpForCommand(CommandName name) {
	final switch (name) {
		case CommandName.build:
			return "Command: crow build PATH --out OUT [options]\n" ~
				"\nCompiles the program at PATH. The '.crow' extension is optional." ~
				"\nWrites an executable to OUT. If OUT has a '.c' extension, it will be C source code instead." ~
				"\nOptions are:\n" ~
				"\n--optimize : Enables optimizations.";
		case CommandName.check:
			return "Command: crow check PATHS\n" ~
				"\nPrints any diagnostics for the module(s) at PATH(s) or their imports.";
		case CommandName.document:
			return "Command: crow document PATHS\n" ~
				"\nGenerates JSON documentation for the module(s) at PATH(s).";
		case CommandName.lsp:
			return "Command: crow lsp\n" ~
				"\nNo arguments. This runs the language server protocol through stdin/stdout.";
		case CommandName.print:
			return "Command: crow print\n" ~
				"\nInternal command for debugging. This should be one of:" ~
				"\ncrow print tokens PATH" ~
				"\ncrow print ast PATH" ~
				"\ncrow print model PATH" ~
				"\ncrow print concrete-model PATH" ~
				"\ncrow print low-model PATH" ~
				"\ncrow print hover PATH LINE:COLUMN" ~
				"\ncrow print definition PATH LINE:COLUMN" ~
				"\ncrow print rename PATH LINE:COLUMN" ~
				"\ncrow print reference PATH LINE:COLUMN";
		case CommandName.run:
			return "Command: crow run PATH [options] -- [program-args]\n" ~
				"\nRuns the program at PATH. The '.crow' extension is optional." ~
				"\nArguments after '--' will be sent to the program." ~
				"\nOptions are:\n" ~
				"\n\t--aot : Builds a temporary executable using the system's C compiler, then runs that." ~
				"\n\t--jit : Just-In-Time compile the code (instead of the default interpreter)." ~
				"\n\t--optimize : Use with '--aot' or '--jit'. Enables optimizations.";
		case CommandName.test:
			return "Command: crow test [name]\n" ~
				"\nInternal command to run unit tests." ~
				"\nIt optionally takes the name of the test suite to run (see 'test.d' for a list).";
		case CommandName.version_:
			return "Command: crow version\n" ~
				"\nPrints information about the version of 'crow'.";
	}
}
