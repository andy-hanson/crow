module compiler;

@safe @nogc nothrow: // not pure

import core.stdc.stdio : printf;

import diag : Diagnostics;
import frontend.frontendCompile : frontendCompile;
import frontend.readOnlyStorage : ReadOnlyStorage, ReadOnlyStorages;
import frontend.showDiag : printDiagnostics;
import model : Program;
import util.alloc.stackAlloc : StackAlloc;
import util.bools : Bool;
import util.collection.arr : Arr;
import util.collection.arrUtil : arrLiteral;
import util.collection.str : Str, strLiteral;
import util.io : Environ, replaceCurrentProcess, spawnAndWaitSync;
import util.opt : force, has, none, Opt, some;
import util.path : AbsolutePath, addManyChildren, childPath, Path, pathToStr, rootPath;
import util.ptr : Ptr;
import util.result : matchImpure, Result;
import util.sym : AllSymbols, shortSymAlphaLiteral;
import util.util : todo;
import util.verify : unreachable;

// These return program exit codes

immutable(int) build(SymAlloc)(
	ref AllSymbols!SymAlloc allSymbols,
	immutable AbsolutePath nozeDir,
	immutable AbsolutePath programDir,
	immutable Ptr!Path mainPath,
	immutable Environ environ,
) {
	StackAlloc exePathAlloc;
	immutable Opt!AbsolutePath exePath = buildWorker(exePathAlloc, allSymbols, nozeDir, programDir, mainPath, environ);
	return exePath.has ? 0 : 1;
}

immutable(int) buildAndRun(SymAlloc)(
	ref AllSymbols!SymAlloc allSymbols,
	immutable AbsolutePath nozeDir,
	immutable AbsolutePath programDir,
	immutable Ptr!Path mainPath,
	immutable Arr!Str programArgs,
	immutable Environ environ
) {
	StackAlloc exePathAlloc;
	immutable Opt!AbsolutePath exePath = buildWorker(exePathAlloc, allSymbols, nozeDir, programDir, mainPath, environ);
	if (exePath.has) {
		replaceCurrentProcess(exePath.force, programArgs, environ);
		return unreachable!int;
	} else
		return 1;
}

private:

// mainPath is relative to programDir
// Returns exePath
immutable(Opt!AbsolutePath) buildWorker(Alloc, SymAlloc)(
	ref Alloc outputAlloc, // Just for exePath
	ref AllSymbols!SymAlloc allSymbols,
	immutable AbsolutePath nozeDir,
	immutable AbsolutePath programDir,
	immutable Ptr!Path mainPath,
	immutable Environ environ
) {
	StackAlloc modelAlloc;
	immutable AbsolutePath include = childPath(modelAlloc, nozeDir, shortSymAlphaLiteral("include"));
	immutable ReadOnlyStorages storages = ReadOnlyStorages(ReadOnlyStorage(include), ReadOnlyStorage(programDir));
	immutable Result!(Program, Diagnostics) programResult =
		frontendCompile(modelAlloc, allSymbols, storages, mainPath);
	return programResult.matchImpure!(Opt!AbsolutePath, Program, Diagnostics)(
		(ref immutable Program program) {
			immutable AbsolutePath fullMainPath = addManyChildren(outputAlloc, programDir, mainPath);
			emitProgram(program, fullMainPath);
			compileC(fullMainPath, fullMainPath, environ);
			return some(fullMainPath);
		},
		(ref immutable Diagnostics diagnostics) {
			printDiagnostics(diagnostics);
			return none!AbsolutePath;
		});
}

void compileC(immutable AbsolutePath cPath, immutable AbsolutePath exePath, immutable Environ environ) {
	StackAlloc alloc;
	immutable AbsolutePath cCompiler = childPath(
		alloc,
		immutable AbsolutePath(rootPath(alloc, shortSymAlphaLiteral("usr"))),
		shortSymAlphaLiteral("bin"),
		shortSymAlphaLiteral("cc"));
	immutable Arr!Str args = arrLiteral!Str(
		alloc,
		strLiteral("-Werror"),
		strLiteral("-Wextra"),
		strLiteral("-Wall"),
		strLiteral("-ansi"),
		strLiteral("-pedantic"),
		strLiteral("-std=c11"),
		strLiteral("-Wno-unused-parameter"),
		strLiteral("-Wno-unused-but-set-variable"),
		strLiteral("-Wno-unused-variable"),
		strLiteral("-Wno-unused-value"),
		strLiteral("-pthread"),
		// TODO: configurable whether we want debug or release
		strLiteral("-g"),
		pathToStr(alloc, cPath, ".c"),
		strLiteral("-o"),
		pathToStr(alloc, exePath, ""));
	immutable int err = spawnAndWaitSync(cCompiler, args, environ);
	if (err != 0) {
		debug {
			printf("c++ compile error! Exit code: %d\n", err);
		}
		todo!void("compile error");
	}
}

void emitProgram(ref immutable Program program, immutable AbsolutePath cPath) {
	assert(0); //TODO
}

