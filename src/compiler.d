module compiler;

@safe @nogc nothrow: // not pure

import core.stdc.stdio : printf;

import backend.writeToC : writeToC;
import concreteModel : ConcreteProgram;
import concretize.concretize : concretize;
import diag : Diagnostics;
import frontend.ast : FileAst, sexprOfAst;
import frontend.frontendCompile : frontendCompile, parseAst;
import frontend.readOnlyStorage : ReadOnlyStorage, ReadOnlyStorages;
import frontend.showDiag : printDiagnostics;
import model : Module, Program;
import sexprOfModel : sexprOfModule;
import util.alloc.mallocator : Mallocator;
import util.alloc.stackAlloc : SingleHeapAlloc, StackAlloc;
import util.bools : Bool;
import util.collection.arr : Arr;
import util.collection.arrUtil : arrLiteral, cat;
import util.collection.str : CStr, emptyStr, Str, strLiteral;
import util.io : Environ, replaceCurrentProcess, spawnAndWaitSync, writeFileSync;
import util.opt : force, has, none, Opt, some;
import util.path :
	AbsolutePath,
	addManyChildren,
	childPath,
	parseAbsoluteOrRelPath,
	Path,
	pathToStr,
	rootPath,
	withExtension;
import util.ptr : Ptr, ptrTrustMe_mut;
import util.result : matchImpure, Result;
import util.sexpr : Sexpr, writeSexpr;
import util.sym : AllSymbols, shortSymAlphaLiteral;
import util.util : todo;
import util.verify : unreachable;
import util.writer : finishWriterToCStr, Writer;

// These return program exit codes

struct ProgramDirAndMain {
	immutable Str programDir;
	immutable Ptr!Path mainPath;
}

immutable(int) printAst(SymAlloc)(
	ref AllSymbols!SymAlloc allSymbols,
	immutable ProgramDirAndMain programDirAndMain,
) {
	StackAlloc!("printAst", 1024 * 1024) alloc;
	ReadOnlyStorages storages = ReadOnlyStorages(
		ReadOnlyStorage(programDirAndMain.programDir),
		ReadOnlyStorage(programDirAndMain.programDir));
	immutable Result!(FileAst, Diagnostics) astResult =
		parseAst(alloc, allSymbols, storages, programDirAndMain.mainPath);
	return astResult.matchImpure!(int, FileAst, Diagnostics)(
		(ref immutable FileAst ast) {
			printOutAst(ast);
			return 0;
		},
		(ref immutable Diagnostics diagnostics) {
			printDiagnostics(diagnostics);
			return 1;
		});
}

immutable(int) printModel(SymAlloc)(
	ref AllSymbols!SymAlloc allSymbols,
	immutable Str nozeDir,
	immutable ProgramDirAndMain programDirAndMain,
) {
	Mallocator mallocator;
	ModelAlloc modelAlloc = ModelAlloc(ptrTrustMe_mut(mallocator));
	immutable Result!(Program, Diagnostics) programResult =
		frontendCompileProgram(modelAlloc, allSymbols, nozeDir, programDirAndMain);
	return matchImpure!(int, Program, Diagnostics)(
		programResult,
		(ref immutable Program program) {
			printOutModule(program.mainModule);
			return 0;
		},
		(ref immutable Diagnostics diagnostics) {
			printDiagnostics(diagnostics);
			return 1;
		});
}

immutable(int) build(SymAlloc)(
	ref AllSymbols!SymAlloc allSymbols,
	immutable Str nozeDir,
	immutable ProgramDirAndMain programDirAndMain,
	immutable Environ environ,
) {
	ExePathAlloc exePathAlloc;
	immutable Opt!AbsolutePath exePath = buildWorker(exePathAlloc, allSymbols, nozeDir, programDirAndMain, environ);
	return exePath.has ? 0 : 1;
}

immutable(int) buildAndRun(SymAlloc)(
	ref AllSymbols!SymAlloc allSymbols,
	immutable Str nozeDir,
	immutable ProgramDirAndMain programDirAndMain,
	immutable Arr!Str programArgs,
	immutable Environ environ
) {
	ExePathAlloc exePathAlloc;
	immutable Opt!AbsolutePath exePath = buildWorker(exePathAlloc, allSymbols, nozeDir, programDirAndMain, environ);
	if (exePath.has) {
		replaceCurrentProcess(exePath.force, programArgs, environ);
		return unreachable!int;
	} else
		return 1;
}

private:

@trusted void printCStr(immutable CStr a) {
	printf("%s\n", a);
}

void printOutModule(ref immutable Module a) {
	StackAlloc!("sexprOfModule", 8 * 1024) sexprAlloc;
	immutable Sexpr sexpr = sexprOfModule(sexprAlloc, a);
	alias StrAlloc = StackAlloc!("printOutSexprOfModule", 32 * 1024);
	StrAlloc strAlloc;
	Writer!StrAlloc writer = Writer!StrAlloc(ptrTrustMe_mut(strAlloc));
	writeSexpr(writer, sexpr);
	printCStr(finishWriterToCStr(writer));
}

void printOutAst(ref immutable FileAst ast) {
	alias Alloc = StackAlloc!("printOutAst", 32 * 1024);
	Alloc alloc;
	immutable Sexpr sexpr = sexprOfAst(alloc, ast);
	Writer!Alloc writer = Writer!Alloc(ptrTrustMe_mut(alloc));
	writeSexpr(writer, sexpr);
	printCStr(finishWriterToCStr(writer));
}

alias ExePathAlloc = StackAlloc!("exePath", 1024);
alias ModelAlloc = SingleHeapAlloc!(Mallocator, "model", 16 * 1024 * 1024);

// mainPath is relative to programDir
// Returns exePath
immutable(Opt!AbsolutePath) buildWorker(Alloc, SymAlloc)(
	ref Alloc outputAlloc, // Just for exePath
	ref AllSymbols!SymAlloc allSymbols,
	ref immutable Str nozeDir,
	ref immutable ProgramDirAndMain programDirAndMain,
	ref immutable Environ environ
) {
	Mallocator mallocator;
	ModelAlloc modelAlloc = ModelAlloc(ptrTrustMe_mut(mallocator));
	immutable Result!(Program, Diagnostics) programResult =
		frontendCompileProgram(modelAlloc, allSymbols, nozeDir, programDirAndMain);
	return matchImpure!(Opt!AbsolutePath, Program, Diagnostics)(
		programResult,
		(ref immutable Program program) {
			immutable AbsolutePath fullMainPath =
				AbsolutePath(programDirAndMain.programDir, programDirAndMain.mainPath, emptyStr);
			immutable AbsolutePath fullMainCPath = withExtension(fullMainPath, strLiteral(".c"));
			emitProgram(program, fullMainCPath);
			compileC(fullMainCPath, fullMainPath, environ);
			return some(fullMainPath);
		},
		(ref immutable Diagnostics diagnostics) {
			printDiagnostics(diagnostics);
			return none!AbsolutePath;
		});
}

immutable(Result!(Program, Diagnostics)) frontendCompileProgram(ModelAlloc, SymAlloc)(
	ref ModelAlloc modelAlloc,
	ref AllSymbols!SymAlloc allSymbols,
	ref immutable Str nozeDir,
	ref immutable ProgramDirAndMain programDirAndMain,
) {
	immutable Str include = cat(modelAlloc, nozeDir, strLiteral("/include")); // NOTE: could be a temp alloc..
	immutable ReadOnlyStorages storages =
		ReadOnlyStorages(ReadOnlyStorage(include), ReadOnlyStorage(programDirAndMain.programDir));
	return frontendCompile(modelAlloc, allSymbols, storages, programDirAndMain.mainPath);
}

void compileC(immutable AbsolutePath cPath, immutable AbsolutePath exePath, immutable Environ environ) {
	StackAlloc!("compileC", 1024) alloc;
	immutable AbsolutePath cCompiler =
		AbsolutePath(strLiteral("/usr/bin"), rootPath(alloc, shortSymAlphaLiteral("cc")), emptyStr);
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
		strLiteral("-Wno-builtin-declaration-mismatch"), //TODO:KILL?
		strLiteral("-pthread"),
		// TODO: configurable whether we want debug or release
		strLiteral("-g"),
		pathToStr(alloc, cPath),
		strLiteral("-o"),
		pathToStr(alloc, exePath));
	immutable int err = spawnAndWaitSync(cCompiler, args, environ);
	if (err != 0) {
		debug {
			printf("C compile error! Exit code: %d\n", err);
		}
		todo!void("C compile error");
	}
}

void emitProgram(ref immutable Program program, immutable AbsolutePath cPath) {
	Mallocator mallocator;
	alias ConcreteAlloc = SingleHeapAlloc!(Mallocator, "concrete-model", 64 * 1024 * 1024);
	ConcreteAlloc concreteAlloc = ConcreteAlloc(ptrTrustMe_mut(mallocator));
	immutable ConcreteProgram concreteProgram = concretize(concreteAlloc, program);
	alias WriteAlloc = SingleHeapAlloc!(Mallocator, "write-to-c", 64 * 1024 * 1024);
	WriteAlloc writeAlloc = WriteAlloc(ptrTrustMe_mut(mallocator));
	immutable Str emitted = writeToC(writeAlloc, concreteProgram);
	writeFileSync(cPath, emitted);
}
