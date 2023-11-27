module lib.cliParser;

@safe @nogc pure nothrow:

import frontend.lang : cExtension, crowExtension, JitOptions, OptimizationLevel;
import frontend.parse.ast : LiteralNatAst;
import frontend.parse.lexToken : takeNat;
import frontend.parse.lexUtil : isDecimalDigit, tryTakeChar;
import util.alloc.alloc : Alloc;
import util.col.arr : empty, only;
import util.col.arrBuilder : add, ArrBuilder, finishArr;
import util.col.arrUtil : findIndex, foldOrStop, mapOrNone;
import util.col.str : SafeCStr, safeCStr, safeCStrEq, strOfSafeCStr;
import util.conv : isUint, safeToUint;
import util.lineAndColumnGetter : LineAndColumn;
import util.opt : force, has, none, Opt, some;
import util.ptr : castNonScope;
import util.sym : Sym, sym;
import util.union_ : Union;
import util.uri : addExtension, alterExtension, AllUris, getExtension, parseUriWithCwd, Uri;
import util.util : todo;

immutable struct Command {
	immutable struct Build {
		Uri mainUri;
		BuildOptions options;
	}
	immutable struct Document {
		Uri[] rootUris;
	}
	immutable struct Help {
		enum Kind {
			requested,
			error,
		}
		SafeCStr helpText;
		Kind kind;
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
	immutable struct Test {}
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

Command parseCommand(ref Alloc alloc, scope ref AllUris allUris, Uri cwd, return scope SafeCStr[] args) {
	if (empty(args))
		return Command(Command.Help(helpAllText, Command.Help.Kind.error));
	else {
		SafeCStr[] cmdArgs = args[1 .. $];
		switch (strOfSafeCStr(args[0])) {
			case "build":
				return parseBuildCommand(alloc, allUris, cwd, cmdArgs);
			case "document":
				return parseDocumentCommand(alloc, allUris, cwd, cmdArgs);
			case "lsp":
				return empty(cmdArgs)
					? Command(Command.Lsp())
					: Command(Command.Help(safeCStr!"Usage: 'crow lsp' (no args)"));
			case "print":
				return parsePrintCommand(alloc, allUris, cwd, cmdArgs);
			case "run":
				return parseRunCommand(alloc, allUris, cwd, cmdArgs);
			case "test":
				return empty(cmdArgs)
					? Command(Command.Test())
					: Command(Command.Help(safeCStr!"Usage: 'crow test' (no args)"));
			case "version":
				return empty(cmdArgs)
					? Command(Command.Version())
					: Command(Command.Help(safeCStr!"Usage: 'crow version' (no args)"));
			default:
				return Command(Command.Help(
					helpAllText,
					isHelp(args[0]) ? Command.Help.Kind.requested : Command.Help.Kind.error));
		}
	}
}

private:

Sym defaultExeExtension() {
	version (Windows) {
		return sym!".exe";
	} else {
		return sym!"";
	}
}

BuildOut emptyBuildOut() =>
	BuildOut(none!Uri, none!Uri);

bool isHelp(in SafeCStr a) {
	switch (strOfSafeCStr(a)) {
		case "help":
		case "-help":
		case "--help":
			return true;
		default:
			return false;
	}
}

Command withMainUri(
	ref Alloc alloc,
	scope ref AllUris allUris,
	Uri cwd,
	in SafeCStr arg,
	in Command delegate(Uri) @safe pure @nogc nothrow cb,
) {
	Opt!Uri p = tryParseCrowUri(alloc, allUris, cwd, arg);
	return has(p)
		? cb(force(p))
		: Command(Command.Help(safeCStr!"Invalid path", Command.Help.Kind.error));
}

Command withRootUris(
	ref Alloc alloc,
	scope ref AllUris allUris,
	Uri cwd,
	in SafeCStr[] args,
	in Command delegate(Uri[]) @safe pure @nogc nothrow cb,
) {
	Opt!(Uri[]) p = tryParseRootUris(alloc, allUris, cwd, args);
	return has(p)
		? cb(force(p))
		: Command(Command.Help(safeCStr!"Invalid path", Command.Help.Kind.error));
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

Command parsePrintCommand(ref Alloc alloc, scope ref AllUris allUris, Uri cwd, in SafeCStr[] args) {
	Opt!PrintKind kind = args.length >= 2
		? parsePrintKind(args[0], args[2 .. $])
		: none!PrintKind;
	return has(kind)
		? withMainUri(alloc, allUris, cwd, args[1], (Uri uri) =>
			Command(Command.Print(force(kind), uri)))
		: todo!Command("Command.HelpPrint");
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
			Opt!(PrintKind.Ide.Kind) kind = ideKindFromString(strOfSafeCStr(a));
			return has(kind)
				? expectLineAndColumn((in LineAndColumn lc) => PrintKind(PrintKind.Ide(force(kind), lc)))
				: none!PrintKind;
	}
}

Opt!(PrintKind.Ide.Kind) ideKindFromString(in string a) {
	switch (a) {
		case "hover":
			return some(PrintKind.Ide.Kind.hover);
		case "definition":
			return some(PrintKind.Ide.Kind.definition);
		case "rename":
			return some(PrintKind.Ide.Kind.rename);
		case "references":
			return some(PrintKind.Ide.Kind.references);
		default:
			return none!(PrintKind.Ide.Kind);
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

Command parseDocumentCommand(ref Alloc alloc, scope ref AllUris allUris, Uri cwd, in SafeCStr[] args) {
	Command helpDocument = Command(Command.Help(helpDocumentText, Command.Help.Kind.error));
	scope SplitArgs split = splitArgs(alloc, args);
	return withRootUris(
		alloc,
		allUris,
		cwd,
		split.beforeFirstPart,
		(Uri[] x) =>
			empty(split.parts) && empty(split.afterDashDash)
				? Command(Command.Document(x))
				: helpDocument);
}

Command parseBuildCommand(ref Alloc alloc, scope ref AllUris allUris, Uri cwd, in SafeCStr[] args) {
	Command helpBuild = Command(Command.Help(helpBuildText, Command.Help.Kind.error));
	SplitArgs split = splitArgs(alloc, args);
	return split.beforeFirstPart.length != 1
		? helpBuild
		: withMainUri(
			alloc,
			allUris,
			cwd,
			only(split.beforeFirstPart),
			(Uri main) {
				Opt!BuildOptions options = parseBuildOptions(alloc, allUris, cwd, split.parts, main);
				return has(options) && empty(split.afterDashDash)
					? Command(Command.Build(main, force(options)))
					: helpBuild;
			});
}

Command parseRunCommand(ref Alloc alloc, scope ref AllUris allUris, Uri cwd, return scope SafeCStr[] args) {
	if (args.length == 1 && isHelp(only(args)))
		return Command(Command.Help(helpRunText, Command.Help.Kind.requested));
	else {
		SplitArgs split = splitArgs(alloc, args);
		Opt!RunOptions options = parseRunOptions(alloc, allUris, split.parts);
		return split.beforeFirstPart.length == 1 && has(options)
			? withMainUri(
				alloc,
				allUris,
				cwd,
				only(split.beforeFirstPart),
				(Uri x) =>
					Command(Command.Run(x, force(options), castNonScope(split.afterDashDash))))
			: Command(Command.Help(helpRunText, Command.Help.Kind.error));
	}
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
}

SplitArgs splitArgs(ref Alloc alloc, return scope SafeCStr[] args) {
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
			size_t firstAfterDashDash = splitArgsRecur(alloc, parts, args, firstArgIndex, firstArgIndex + 1);
			return SplitArgs(beforeFirstPart, finishArr(alloc, parts), args[firstAfterDashDash .. $]);
		}
	}
}

@trusted bool startsWithDashDash(in SafeCStr a) =>
	a.ptr[0] == '-' && a.ptr[1] == '-';

size_t splitArgsRecur(
	ref Alloc alloc,
	ref ArrBuilder!ArgsPart parts,
	in SafeCStr[] args,
	size_t curPartStart,
	size_t index,
) {
	if (index == args.length) {
		add(alloc, parts, ArgsPart(args[curPartStart], args[curPartStart + 1 .. index]));
		return index;
	} else {
		SafeCStr arg = args[index];
		if (startsWithDashDash(arg)) {
			add(alloc, parts, ArgsPart(args[curPartStart], args[curPartStart + 1 .. index]));
			return safeCStrEq(arg, "--")
				? index + 1
				// Using `index + 0` to avoid dscanner warning about 'index' not being parameter 3
				: splitArgsRecur(alloc, parts, args, index + 0, index + 1);
		} else
			return splitArgsRecur(alloc, parts, args, curPartStart, index + 1);
	}
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
