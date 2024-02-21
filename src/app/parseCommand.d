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
import util.col.array : copyArray, findIndex, isEmpty, map, only;
import util.col.arrayBuilder : buildArray, Builder, finish;
import util.conv : isUint, safeToUint;
import util.exitCode : ExitCode;
import util.opt : force, has, MutOpt, none, noneMut, Opt, optOrDefault, some, someMut;
import util.sourceRange : LineAndColumn;
import util.string : CString, cString, endsWith, MutCString, stringOfCString;
import util.symbol : Extension, symbol;
import util.union_ : Union;
import util.uri :
	alterExtension,
	AllUris,
	asFilePath,
	childFilePath,
	FilePath,
	getExtension,
	parseFilePathWithCwd,
	parseUriWithCwd,
	toUri,
	Uri,
	uriIsFile;
import util.util : castNonScope, enumEach, optEnumOfString, stringOfEnum, typeAs;
import util.writer : makeStringWithWriter, writeNewline, writeQuotedString, Writer;
import versionInfo : OS;

Command parseCommand(ref Alloc alloc, scope ref AllUris allUris, FilePath cwd, OS os, CString[] args) {
	string arg0 = stringOfCString(args[0]);
	if (endsWith(arg0, ".crow"))
		return Command(
			CommandKind(CommandKind.Run(
				parseUriWithCwd(allUris, cwd, arg0),
				RunOptions(RunOptions.Interpret()),
				args[1 .. $])),
			CommandOptions()) ;
	else {
		Opt!CommandName optName = isEmpty(args) ? none!CommandName : optEnumOfString!CommandName(arg0);
		return has(optName)
			? parseCommandFromName(alloc, allUris, cwd, os, force(optName), args[1 .. $])
			: Command(
				CommandKind(CommandKind.Help(
					helpAllText(alloc),
					!isEmpty(args) && (args[0] == "help" || args[0] == "--help") ? ExitCode.ok : ExitCode.error)),
				CommandOptions(perf: false));
	}
}

private:

Command parseCommandFromName(
	ref Alloc alloc,
	scope ref AllUris allUris,
	FilePath cwd,
	OS os,
	CommandName name,
	CString[] args,
) {
	SplitArgsAndOptions split = splitArgs(alloc, args);
	if (split.help)
		return Command(
			CommandKind(CommandKind.Help(helpForCommand(alloc, name), ExitCode.ok)),
			split.options);
	else {
		Diags diagsBuilder = Diags(&alloc);
		CommandKind res = parseCommandKind(alloc, allUris, cwd, os, name, split.args, diagsBuilder);
		Diag[] diags = finish(diagsBuilder);
		if (isEmpty(diags))
			return Command(res, split.options);
		else {
			string help = makeStringWithWriter(alloc, (scope ref Writer writer) {
				writer ~= "Command syntax error: ";
				foreach (Diag x; diags) {
					writeDiag(writer, allUris, x);
					writeNewline(writer, 0);
				}
				writeNewline(writer, 0);
				writeHelpForCommand(writer, name);
			});
			return Command(CommandKind(CommandKind.Help(help, ExitCode.error)), split.options);
		}
	}
}

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
	immutable struct ExpectedCrowUri { string actual; }
	immutable struct ExpectedPaths { Opt!CString tag; }
	immutable struct NeedsSinglePath { size_t actual; }
	immutable struct ParseFilePath { CString actual; }
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
		ExpectedCrowUri,
		ExpectedPaths,
		NeedsSinglePath,
		ParseFilePath,
		PrintKind,
		UnexpectedPart,
		UnexpectedPartArgs,
		UnexpectedBefore,
		RunAotAndJit,
		RunOptimizeNeedsAotOrJit);
}
alias Diags = Builder!Diag;

void writeDiag(scope ref Writer writer, in AllUris allUris, in Diag a) {
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
		(in Diag.ExpectedCrowUri x) {
			writer ~= "Expected path to a '.crow' file, instead got ";
			writeQuotedString(writer, x.actual);
			writer ~= '.';
		},
		(in Diag.ExpectedPaths x) {
			if (has(x.tag)) {
				writer ~= "Argument ";
				writeQuotedString(writer, force(x.tag));
				writer ~= " expects a list of paths.";
			} else
				writer ~= "This command expects a list of paths.";
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
		(in Diag.ParseFilePath x) {
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
	FilePath cwd,
	OS os,
	CommandName commandName,
	SplitArgs args,
	scope ref Diags diags,
) {
	final switch (commandName) {
		case CommandName.build:
			return parseBuildCommand(alloc, allUris, cwd, diags, getDefaultExeExtension(os), args);
		case CommandName.check:
			expectEmptyParts(diags, args.parts);
			expectEmptyAfterDashDash(diags, args.afterDashDash);
			return CommandKind(CommandKind.Check(parseRootUris(alloc, allUris, cwd, diags, args.beforeFirstPart)));
		case CommandName.document:
			expectEmptyParts(diags, args.parts);
			expectEmptyAfterDashDash(diags, args.afterDashDash);
			return CommandKind(CommandKind.Document(parseRootUris(alloc, allUris, cwd, diags, args.beforeFirstPart)));
		case CommandName.lsp:
			expectAllEmpty(diags, args);
			return CommandKind(CommandKind.Lsp());
		case CommandName.print:
			return parsePrintCommand(alloc, allUris, cwd, diags, args);
		case CommandName.run:
			RunOptions options = parseRunOptions(alloc, allUris, getDefaultExeExtension(os), diags, args.parts);
			return CommandKind(CommandKind.Run(
				parseMainUri(alloc, allUris, cwd, diags, args.beforeFirstPart),
				options,
				optOrDefault!(CString[])(castNonScope(args.afterDashDash), () => typeAs!(CString[])([]))));
		case CommandName.test:
			expectEmptyParts(diags, args.parts);
			expectEmptyAfterDashDash(diags, args.afterDashDash);
			return CommandKind(CommandKind.Test(copyArray(alloc, args.beforeFirstPart)));
		case CommandName.version_:
			expectAllEmpty(diags, args);
			return CommandKind(CommandKind.Version());
	}
}

void expectAllEmpty(scope ref Diags diags, in SplitArgs args) {
	expectEmptyBefore(diags, args.beforeFirstPart);
	expectEmptyParts(diags, args.parts);
	expectEmptyAfterDashDash(diags, args.afterDashDash);
}

void expectEmptyBefore(scope ref Diags diags, in CString[] before) {
	if (!isEmpty(before))
		diags ~= Diag(Diag.UnexpectedBefore(before[0]));
}
void expectEmptyParts(scope ref Diags diags, in ArgsPart[] parts) {
	foreach (ArgsPart part; parts)
		diags ~= Diag(Diag.UnexpectedPart(part.tag));
}
void expectEmptyAfterDashDash(scope ref Diags diags, in Opt!(CString[]) after) {
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

Uri parseMainUri(
	ref Alloc alloc,
	scope ref AllUris allUris,
	FilePath cwd,
	scope ref Diags diags,
	in CString[] args,
) {
	if (args.length != 1) {
		diags ~= Diag(Diag.NeedsSinglePath(args.length));
		return toUri(allUris, cwd); // dummy return value
	} else
		return parseCrowUri(alloc, allUris, cwd, diags, only(args));
}

Uri parseCrowUri(ref Alloc alloc, scope ref AllUris allUris, FilePath cwd, scope ref Diags diags, CString arg) {
	string argStr = stringOfCString(arg);
	Uri uri = parseUriWithCwd(allUris, cwd, argStr);
	if (getExtension(allUris, uri) != Extension.crow)
		diags ~= Diag(Diag.ExpectedCrowUri(argStr));
	return uri;
}

Uri[] parseRootUris(
	ref Alloc alloc,
	scope ref AllUris allUris,
	FilePath cwd,
	scope ref Diags diags,
	in CString[] args,
) {
	if (isEmpty(args))
		diags ~= Diag(Diag.ExpectedPaths(none!CString));
	return map(alloc, args, (ref CString arg) =>
		parseCrowUri(alloc, allUris, cwd, diags, arg));
}

CommandKind parsePrintCommand(
	ref Alloc alloc,
	scope ref AllUris allUris,
	FilePath cwd,
	scope ref Diags diags,
	in SplitArgs args,
) {
	expectEmptyParts(diags, args.parts);
	expectEmptyAfterDashDash(diags, args.afterDashDash);
	Opt!PrintKind kind = args.beforeFirstPart.length >= 2
		? parsePrintKind(args.beforeFirstPart[0], args.beforeFirstPart[2 .. $])
		: none!PrintKind;
	if (has(kind))
		return CommandKind(CommandKind.Print(
			force(kind), parseCrowUri(alloc, allUris, cwd, diags, args.beforeFirstPart[1])));
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
	FilePath cwd,
	scope ref Diags diags,
	Extension defaultExeExtension,
	in SplitArgs args,
) {
	expectEmptyAfterDashDash(diags, args.afterDashDash);
	Uri main = parseMainUri(alloc, allUris, cwd, diags, args.beforeFirstPart);
	return CommandKind(CommandKind.Build(
		main,
		parseBuildOptions(alloc, allUris, cwd, diags, defaultExeExtension, args.parts, main)));
}

RunOptions parseRunOptions(
	ref Alloc alloc,
	scope ref AllUris allUris,
	Extension defaultExeExtension,
	scope ref Diags diags,
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

void expectFlag(scope ref Diags diags, ArgsPart part) {
	if (!isEmpty(part.args))
		diags ~= Diag(Diag.UnexpectedPartArgs(part));
}

BuildOptions parseBuildOptions(
	ref Alloc alloc,
	scope ref AllUris allUris,
	FilePath cwd,
	scope ref Diags diags,
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
			outC: none!FilePath,
			shouldBuildExecutable: true,
			outExecutable: defaultExePath(
				allUris,
				uriIsFile(allUris, mainUri) ? asFilePath(allUris, mainUri) : childFilePath(allUris, cwd, symbol!"main"),
				defaultExeExtension));
	return BuildOptions(resOut, options);
}

BuildOut parseBuildOut(
	ref Alloc alloc,
	scope ref AllUris allUris,
	FilePath cwd,
	Extension defaultExeExtension,
	scope ref Diags diags,
	ArgsPart part,
) {
	Cell!(Opt!FilePath) outC;
	Cell!(Opt!FilePath) outExe;
	foreach (CString arg; part.args) {
		Opt!FilePath opt = parseFilePathWithCwd(allUris, cwd, arg);
		if (has(opt)) {
			FilePath path = force(opt);
			Extension extension = getExtension(allUris, path);
			if (extension == Extension.c) {
				if (has(cellGet(outC)))
					diags ~= Diag(Diag.BuildOutDuplicate());
				cellSet(outC, some(path));
			} else {
				if (has(cellGet(outExe)))
					diags ~= Diag(Diag.BuildOutDuplicate());
				if (extension != defaultExeExtension)
					diags ~= Diag(Diag.BuildOutBadFileExtension(defaultExeExtension));
				cellSet(outExe, some(path));
			}
		} else
			diags ~= Diag(Diag.ParseFilePath(arg));
	}
	if (!has(cellGet(outC)) && !has(cellGet(outExe)))
		diags ~= Diag(Diag.ExpectedPaths(some(part.tag)));
	return BuildOut(
		outC: cellGet(outC),
		shouldBuildExecutable: has(cellGet(outExe)),
		outExecutable: optOrDefault!FilePath(cellGet(outExe), () =>
			defaultExePath(allUris, force(cellGet(outC)), defaultExeExtension)));
}

FilePath defaultExePath(scope ref AllUris allUris, FilePath base, Extension defaultExeExtension) =>
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
		writer ~= "Command must be one of:" ~
			"\n\tcrow hello.crow (or any '.crow' file)";
		enumEach!CommandName((CommandName name) {
			if (!isInternalCommand(name)) {
				writer ~= "\n\t";
				writeCommand(writer, name);
			}
		});
		writer ~= ".\nFor more info, run e.g. 'crow build --help'.";
	});

bool isInternalCommand(CommandName name) {
	final switch (name) {
		case CommandName.build:
		case CommandName.check:
		case CommandName.document:
		case CommandName.lsp:
		case CommandName.run:
		case CommandName.version_:
			return false;
		case CommandName.print:
		case CommandName.test:
			return true;
	}
}

string helpForCommand(ref Alloc alloc, CommandName name) =>
	makeStringWithWriter(alloc, (scope ref Writer writer) {
		writeHelpForCommand(writer, name);
	});

void writeHelpForCommand(scope ref Writer writer, CommandName name) {
	writer ~= "Command: ";
	writeCommand(writer, name);
	writer ~= "\n\n";
	writer ~= commandDescription(name);
}

void writeCommand(scope ref Writer writer, CommandName name) {
	writer ~= "crow ";
	writer ~= stringOfEnum(name);
	string options = describeCommandOptions(name);
	if (!isEmpty(options)) {
		writer ~= ' ';
		writer ~= options;
	}
}

string describeCommandOptions(CommandName name) {
	final switch (name) {
		case CommandName.build:
			return "PATH [--out PATH] [--optimize]";
		case CommandName.check:
			return "PATHS";
		case CommandName.document:
			return "PATHS";
		case CommandName.lsp:
			return "";
		case CommandName.print:
			return "[kind] PATH [LINE:COLUMN]";
		case CommandName.run:
			return "PATH [--aot] [--optimize] -- [program-args]";
		case CommandName.test:
			return "[name]";
		case CommandName.version_:
			return "";
	}
}

string commandDescription(CommandName name) {
	final switch (name) {
		case CommandName.build:
			return "Compiles the program at PATH." ~
				"\nOptions are:" ~
				"\n--out : Output path. Defaults to the input path with the extension changed." ~
				"\n\tIf this has a '.c' extension, it will output C source code instead." ~
				"\n--optimize : Enables optimizations.";
		case CommandName.check:
			return "Prints any diagnostics for the module(s) at PATH(s) or their imports.\nNo options.";
		case CommandName.document:
			return "Generates JSON documentation for the module(s) at PATH(s).\nNo options.";
		case CommandName.lsp:
			return "This runs the Language Server Protocol through stdin/stdout.\nNo options.";
		case CommandName.print:
			return "Internal command for debugging. This should be one of:" ~
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
			return "Runs the program at PATH." ~
				"\nArguments after '--' will be sent to the program." ~
				"\nOptions are:\n" ~
				"\n\t--aot : Instead of interpreting the program, builds an executable, runs it, then deletes it." ~
				"\n\t--optimize : Use with '--aot'. Enables optimizations." ~
				"\nWith no options, 'crow run foo.crow' is equivalent to 'crow foo.crow'.";
		case CommandName.test:
			return "Internal command to run unit tests." ~
				"\nIt optionally takes the name of the test suite to run (see 'test.d' for a list).";
		case CommandName.version_:
			return "Prints information about the version of 'crow'.\nNo options.";
	}
}
