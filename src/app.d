@safe @nogc nothrow: // not pure

import core.stdc.stdio : fprintf, printf, stderr;

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
import frontend.showDiag : ShowDiagOptions;
import lib.cliParser : Command, matchCommand, parseCommand, ProgramDirAndMain;
import lib.compiler :
	buildAndInterpret,
	buildToC,
	DiagsAndResultStrs,
	getAbsolutePathFromStorage,
	print;
import test.test : test;
import util.bools : Bool, True;
import util.collection.arr : Arr, at, begin, empty, size;
import util.collection.arrUtil : arrLiteral, cat;
import util.collection.str : CStr, emptyStr, Str, strEqLiteral, strLiteral;
import util.opt : force, forceOrTodo, has, none, Opt, some;
import util.path : AbsolutePath, AllPaths, pathBaseName, pathParent, pathToStr, rootPath, withExtension;
import util.ptr : ptrTrustMe_mut;
import util.result : matchResultImpure, Result;
import util.sym : AllSymbols, shortSymAlphaLiteral;
import util.result : Result;
import util.util : NullDebug, todo, unreachable;

extern(C) int main(immutable size_t argc, immutable char** argv) {
	return cli(argc, argv);
}

private:

int cli(immutable size_t argc, immutable CStr* argv) {
	Mallocator mallocator;
	immutable CommandLineArgs args = parseCommandLineArgs(mallocator, argc, argv);
	AllPaths!Mallocator allPaths = AllPaths!Mallocator(ptrTrustMe_mut(mallocator));
	AllSymbols!Mallocator allSymbols = AllSymbols!Mallocator(ptrTrustMe_mut(mallocator));
	return go(mallocator, allPaths, allSymbols, args);
}

immutable(int) go(Alloc, PathAlloc, SymAlloc)(
	ref Alloc alloc,
	ref AllPaths!PathAlloc allPaths,
	ref AllSymbols!SymAlloc allSymbols,
	ref immutable CommandLineArgs args,
) {
	immutable Str nozeDir = getNozeDirectory(args.pathToThisExecutable);
	immutable Command command = parseCommand(alloc, allPaths, allSymbols, getCwd(alloc), args.args);
	immutable Str include = cat(alloc, nozeDir, strLiteral("/include"));
	immutable ShowDiagOptions showDiagOptions = immutable ShowDiagOptions(True);
	NullDebug dbg;

	return matchCommand!int(
		command,
		(ref immutable Command.Build it) {
			immutable Opt!AbsolutePath exePath =
				buildToCAndCompile(
					alloc,
					allPaths,
					allSymbols,
					showDiagOptions,
					it.programDirAndMain,
					include,
					args.environ);
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
			RealReadOnlyStorage!(PathAlloc, Alloc) storage = RealReadOnlyStorage!(PathAlloc, Alloc)(
				ptrTrustMe_mut(allPaths),
				ptrTrustMe_mut(alloc),
				include,
				it.programDirAndMain.programDir);
			immutable DiagsAndResultStrs printed = print(
				alloc,
				allPaths,
				allSymbols,
				storage,
				showDiagOptions,
				it.kind,
				it.format,
				it.programDirAndMain.mainPath);
			if (!empty(printed.diagnostics)) printErr(printed.diagnostics);
			if (!empty(printed.result)) print(printed.result);
			return empty(printed.diagnostics) ? 0 : 1;
		},
		(ref immutable Command.Run it) {
			RealReadOnlyStorage!(PathAlloc, Alloc) storage = RealReadOnlyStorage!(PathAlloc, Alloc)(
				ptrTrustMe_mut(allPaths),
				ptrTrustMe_mut(alloc),
				include,
				it.programDirAndMain.programDir);
			if (it.interpret) {
				RealExtern extern_ = newRealExtern();
				return buildAndInterpret(
					dbg,
					alloc,
					allPaths,
					allSymbols,
					storage,
					extern_,
					showDiagOptions,
					it.programDirAndMain.mainPath,
					it.programArgs);
			} else {
				immutable Opt!AbsolutePath exePath = buildToCAndCompile(
					alloc,
					allPaths,
					allSymbols,
					showDiagOptions,
					it.programDirAndMain,
					include,
					args.environ);
				if (!has(exePath))
					return 1;
				else {
					replaceCurrentProcess(alloc, allPaths, force(exePath), it.programArgs, args.environ);
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

immutable(Str) getNozeDirectory(immutable Str pathToThisExecutable) {
	immutable Opt!Str parent = pathParent(pathToThisExecutable);
	return climbUpToNoze(forceOrTodo(parent));
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

immutable(Opt!AbsolutePath) buildToCAndCompile(Alloc, PathAlloc, SymAlloc)(
	ref Alloc alloc,
	ref AllPaths!PathAlloc allPaths,
	ref AllSymbols!SymAlloc allSymbols,
	ref immutable ShowDiagOptions showDiagOptions,
	ref immutable ProgramDirAndMain programDirAndMain,
	ref immutable Str include,
	ref immutable Environ environ,
) {
	RealReadOnlyStorage!(PathAlloc, Alloc) storage = RealReadOnlyStorage!(PathAlloc, Alloc)(
		ptrTrustMe_mut(allPaths),
		ptrTrustMe_mut(alloc),
		include,
		programDirAndMain.programDir);
	immutable AbsolutePath cPath =
		getAbsolutePathFromStorage(alloc, storage, programDirAndMain.mainPath, strLiteral(".c"));
	immutable Result!(Str, Str) result =
		buildToC(alloc, allPaths, allSymbols, storage, showDiagOptions, programDirAndMain.mainPath);
	return matchResultImpure!(immutable Opt!AbsolutePath, Str, Str)(
		result,
		(ref immutable Str cCode) {
			writeFileSync(alloc, allPaths, cPath, cCode);
			immutable AbsolutePath exePath = withExtension(cPath, emptyStr);
			compileC(alloc, allPaths, cPath, exePath, environ);
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

void compileC(Alloc, PathAlloc)(
	ref Alloc alloc,
	ref AllPaths!PathAlloc allPaths,
	ref immutable AbsolutePath cPath,
	ref immutable AbsolutePath exePath,
	ref immutable Environ environ,
) {
	immutable AbsolutePath cCompiler =
		AbsolutePath(strLiteral("/usr/bin"), rootPath(allPaths, shortSymAlphaLiteral("cc")), emptyStr);
	immutable Arr!Str args = arrLiteral!Str(alloc, [
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
		pathToStr(alloc, allPaths, cPath),
		strLiteral("-o"),
		pathToStr(alloc, allPaths, exePath)]);
	immutable int err = spawnAndWaitSync(alloc, allPaths, cCompiler, args, environ);
	if (err != 0)
		todo!void("C compile error");
}

@trusted void print(immutable Str a) {
	printf("%.*s", cast(uint) size(a), begin(a));
}

void print(immutable string a) {
	print(strLiteral(a));
}

@trusted void printErr(immutable Str a) {
	fprintf(stderr, "%.*s", cast(uint) size(a), begin(a));
}
