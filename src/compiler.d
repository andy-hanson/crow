module compiler;

@safe @nogc nothrow: // not pure

import backend.writeToC : writeToC;
import concreteModel : ConcreteProgram;
import concretize.concretize : concretize;
import diag : Diagnostics, FilesInfo;
import frontend.ast : FileAst, sexprOfAst;
import frontend.frontendCompile : FileAstAndDiagnostics, frontendCompile, parseSingleAst;
import frontend.getTokens : Token, tokensOfAst, sexprOfTokens;
import frontend.lang : nozeExtension;
import frontend.readOnlyStorage : ReadOnlyStorage, ReadOnlyStorages;
import frontend.showDiag : cStrOfDiagnostics;
import interpret.bytecode : ByteCode;
import interpret.fakeExtern : FakeExtern, newFakeExtern;
import interpret.generateBytecode : generateBytecode;
import interpret.runBytecode : runBytecode;
import lower.lower : lower;
import lowModel : LowProgram;
import model : Module, Program;
import sexprOfConcreteModel : tataOfConcreteProgram;
import sexprOfLowModel : tataOfLowProgram;
import sexprOfModel : sexprOfModule;
import util.alloc.mallocator : Mallocator;
import util.alloc.stackAlloc : SingleHeapAlloc, StackAlloc;
import util.bools : Bool;
import util.collection.arr : Arr, empty;
import util.collection.arrUtil : arrLiteral, cat;
import util.collection.str : emptyStr, Str, strLiteral;
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
import util.print : printErr;
import util.result : mapSuccess, matchResultImpure, Result;
import util.sexpr : Sexpr;
import util.sexprPrint : PrintFormat, printOutSexpr;
import util.sym : AllSymbols, shortSymAlphaLiteral;
import util.util : todo, unreachable;

// These return program exit codes

struct ProgramDirAndMain {
	immutable Str programDir;
	immutable Ptr!Path mainPath;
}

enum PrintKind {
	tokens,
	ast,
	model,
	concreteModel,
	lowModel,
}

immutable(int) print(SymAlloc)(
	ref AllSymbols!SymAlloc allSymbols,
	immutable PrintKind kind,
	immutable PrintFormat format,
	ref immutable Str nozeDir,
	ref immutable ProgramDirAndMain programDirAndMain,
) {
	final switch (kind) {
		case PrintKind.tokens:
			return printTokens(allSymbols, programDirAndMain, format);
		case PrintKind.ast:
			return printAst(allSymbols, programDirAndMain, format);
		case PrintKind.model:
			return printModel(allSymbols, nozeDir, programDirAndMain, format);
		case PrintKind.concreteModel:
			return printConcreteModel(allSymbols, nozeDir, programDirAndMain, format);
		case PrintKind.lowModel:
			return printLowModel(allSymbols, nozeDir, programDirAndMain, format);
	}
}

immutable(int) build(SymAlloc)(
	ref AllSymbols!SymAlloc allSymbols,
	immutable Str nozeDir,
	ref immutable ProgramDirAndMain programDirAndMain,
	immutable Environ environ,
) {
	ExePathAlloc exePathAlloc;
	immutable Opt!AbsolutePath exePath = buildWorker(exePathAlloc, allSymbols, nozeDir, programDirAndMain, environ);
	return exePath.has ? 0 : 1;
}

immutable(int) buildAndRun(SymAlloc)(
	immutable Bool interpret,
	ref AllSymbols!SymAlloc allSymbols,
	ref immutable Str nozeDir,
	ref immutable ProgramDirAndMain programDirAndMain,
	ref immutable Arr!Str programArgs,
	ref immutable Environ environ,
) {
	if (interpret) {
		Mallocator mallocator;
		LowAlloc lowAlloc = LowAlloc(ptrTrustMe_mut(mallocator));
		immutable Result!(ProgramsAndFilesInfo, Diagnostics) lowProgramResult =
			buildToLowProgram(lowAlloc, allSymbols, nozeDir, programDirAndMain);
		return matchResultImpure!(int, ProgramsAndFilesInfo, Diagnostics)(
			lowProgramResult,
			(ref immutable ProgramsAndFilesInfo it) {
				immutable ByteCode byteCode = generateBytecode(lowAlloc, it.program, it.lowProgram);
				FakeExtern!Mallocator fakeExtern = newFakeExtern(ptrTrustMe_mut(mallocator));
				return runBytecode!(FakeExtern!Mallocator)(
					fakeExtern,
					it.lowProgram,
					byteCode,
					it.filesInfo,
					getExecutablePath(mallocator, programDirAndMain),
					programArgs);
			},
			(ref immutable Diagnostics diagnostics) {
				printDiagnostics(diagnostics);
				return 1;
			});
	} else {
		ExePathAlloc exePathAlloc;
		immutable Opt!AbsolutePath exePath = buildWorker(exePathAlloc, allSymbols, nozeDir, programDirAndMain, environ);
		if (exePath.has) {
			replaceCurrentProcess(exePath.force, programArgs, environ);
			return unreachable!int;
		} else
			return 1;
	}
}

private:

immutable(Str) getExecutablePath(Alloc)(ref Alloc alloc, ref immutable ProgramDirAndMain programDirAndMain) {
	return pathToStr(alloc, programDirAndMain.programDir, programDirAndMain.mainPath, nozeExtension);
}

immutable(int) printTokens(SymAlloc)(
	ref AllSymbols!SymAlloc allSymbols,
	ref immutable ProgramDirAndMain programDirAndMain,
	immutable PrintFormat format,
) {
	StackAlloc!("printTokens", 1024 * 1024) alloc;
	immutable FileAstAndDiagnostics astResult = getAst(alloc, allSymbols, programDirAndMain);
	printDiagnostics(astResult.diagnostics);
	immutable Arr!Token tokens = tokensOfAst(alloc, astResult.ast);
	printOutSexpr(sexprOfTokens(alloc, tokens), format);
	return empty(astResult.diagnostics.diagnostics) ? 0 : 1;
}

immutable(int) printAst(SymAlloc)(
	ref AllSymbols!SymAlloc allSymbols,
	ref immutable ProgramDirAndMain programDirAndMain,
	immutable PrintFormat format,
) {
	StackAlloc!("printAst", 1024 * 1024) alloc;
	immutable FileAstAndDiagnostics astResult = getAst(alloc, allSymbols, programDirAndMain);
	printDiagnostics(astResult.diagnostics);
	printOutAst(astResult.ast, format);
	return empty(astResult.diagnostics.diagnostics) ? 0 : 1;
}

immutable(FileAstAndDiagnostics) getAst(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref AllSymbols!SymAlloc allSymbols,
	ref immutable ProgramDirAndMain programDirAndMain,
) {
	ReadOnlyStorages storages = ReadOnlyStorages(
		ReadOnlyStorage(programDirAndMain.programDir),
		ReadOnlyStorage(programDirAndMain.programDir));
	return parseSingleAst(alloc, allSymbols, storages, programDirAndMain.mainPath);
}

immutable(int) printModel(SymAlloc)(
	ref AllSymbols!SymAlloc allSymbols,
	ref immutable Str nozeDir,
	ref immutable ProgramDirAndMain programDirAndMain,
	immutable PrintFormat format,
) {
	Mallocator mallocator;
	ModelAlloc modelAlloc = ModelAlloc(ptrTrustMe_mut(mallocator));
	immutable Result!(Program, Diagnostics) programResult =
		frontendCompileProgram(modelAlloc, allSymbols, nozeDir, programDirAndMain);
	return matchResultImpure!(int, Program, Diagnostics)(
		programResult,
		(ref immutable Program program) {
			printOutModule(program.mainModule, format);
			return 0;
		},
		(ref immutable Diagnostics diagnostics) {
			printDiagnostics(diagnostics);
			return 1;
		});
}

immutable(int) printConcreteModel(SymAlloc)(
	ref AllSymbols!SymAlloc allSymbols,
	ref immutable Str nozeDir,
	ref immutable ProgramDirAndMain programDirAndMain,
	immutable PrintFormat format,
) {
	Mallocator mallocator;
	ModelAlloc modelAlloc = ModelAlloc(ptrTrustMe_mut(mallocator));
	immutable Result!(Program, Diagnostics) programResult =
		frontendCompileProgram(modelAlloc, allSymbols, nozeDir, programDirAndMain);
	return matchResultImpure!(int, Program, Diagnostics)(
		programResult,
		(ref immutable Program program) {
			ConcreteAlloc concreteAlloc = ConcreteAlloc(ptrTrustMe_mut(mallocator));
			immutable ConcreteProgram concreteProgram = concretize(concreteAlloc, program);
			printOutConcreteProgram(mallocator, concreteProgram, format);
			return 0;
		},
		(ref immutable Diagnostics diagnostics) {
			printDiagnostics(diagnostics);
			return 1;
		});

}

immutable(int) printLowModel(SymAlloc)(
	ref AllSymbols!SymAlloc allSymbols,
	ref immutable Str nozeDir,
	ref immutable ProgramDirAndMain programDirAndMain,
	immutable PrintFormat format,
) {
	Mallocator mallocator;
	ModelAlloc modelAlloc = ModelAlloc(ptrTrustMe_mut(mallocator));
	immutable Result!(Program, Diagnostics) programResult =
		frontendCompileProgram(modelAlloc, allSymbols, nozeDir, programDirAndMain);
	return matchResultImpure!(int, Program, Diagnostics)(
		programResult,
		(ref immutable Program program) {
			ConcreteAlloc concreteAlloc = ConcreteAlloc(ptrTrustMe_mut(mallocator));
			LowAlloc lowAlloc = LowAlloc(ptrTrustMe_mut(mallocator));
			immutable ConcreteProgram concreteProgram = concretize(concreteAlloc, program);
			immutable LowProgram lowProgram = lower(lowAlloc, concreteProgram);
			printOutLowProgram(mallocator, lowProgram, format);
			return 0;
		},
		(ref immutable Diagnostics diagnostics) {
			printDiagnostics(diagnostics);
			return 1;
		});

}

void printOutAst(ref immutable FileAst ast, immutable PrintFormat format) {
	StackAlloc!("sexprOfAst", 32 * 1024) alloc;
	printOutSexpr(sexprOfAst(alloc, ast), format);
}

void printOutModule(ref immutable Module a, immutable PrintFormat format) {
	StackAlloc!("sexprOfModule", 32 * 1024) alloc;
	printOutSexpr(sexprOfModule(alloc, a), format);
}

void printOutConcreteProgram(ref Mallocator mallocator, ref immutable ConcreteProgram a, immutable PrintFormat format) {
	ConcreteSexprAlloc alloc = ConcreteSexprAlloc(ptrTrustMe_mut(mallocator));
	printOutSexpr(tataOfConcreteProgram(alloc, a), format);
}

void printOutLowProgram(ref Mallocator mallocator, ref immutable LowProgram a, immutable PrintFormat format) {
	LowSexprAlloc alloc = LowSexprAlloc(ptrTrustMe_mut(mallocator));
	printOutSexpr(tataOfLowProgram(alloc, a), format);
}

alias ExePathAlloc = StackAlloc!("exePath", 1024);
alias ModelAlloc = SingleHeapAlloc!(Mallocator, "model", 16 * 1024 * 1024);
alias ConcreteAlloc = SingleHeapAlloc!(Mallocator, "concrete-model", 64 * 1024 * 1024);
alias LowAlloc = SingleHeapAlloc!(Mallocator, "low-model", 64 * 1024 * 1024);
alias ConcreteSexprAlloc = SingleHeapAlloc!(Mallocator, "concrete-model-repr", 64 * 1024 * 1024);
alias LowSexprAlloc = SingleHeapAlloc!(Mallocator, "low-model-repr", 64 * 1024 * 1024);
alias WriteAlloc = SingleHeapAlloc!(Mallocator, "write-to-c", 128 * 1024 * 1024);

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
	LowAlloc lowAlloc = LowAlloc(ptrTrustMe_mut(mallocator));
	immutable Result!(ProgramsAndFilesInfo, Diagnostics) programResult =
		buildToLowProgram(lowAlloc, allSymbols, nozeDir, programDirAndMain);
	return matchResultImpure!(Opt!AbsolutePath)(
		programResult,
		(ref immutable ProgramsAndFilesInfo lowProgram) {
			immutable AbsolutePath fullMainPath =
				immutable AbsolutePath(programDirAndMain.programDir, programDirAndMain.mainPath, emptyStr);
			immutable AbsolutePath fullMainCPath = withExtension(fullMainPath, strLiteral(".c"));
			emitProgram(lowProgram.lowProgram, fullMainCPath);
			compileC(fullMainCPath, fullMainPath, environ);
			return some(fullMainPath);
		},
		(ref immutable Diagnostics diagnostics) {
			printDiagnostics(diagnostics);
			return none!AbsolutePath;
		});
}

struct ProgramsAndFilesInfo {
	immutable Program program;
	immutable ConcreteProgram concreteProgram;
	immutable LowProgram lowProgram;
	immutable FilesInfo filesInfo;
}

immutable(Result!(ProgramsAndFilesInfo, Diagnostics)) buildToLowProgram(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref AllSymbols!SymAlloc allSymbols,
	ref immutable Str nozeDir,
	ref immutable ProgramDirAndMain programDirAndMain,
) {
	immutable Result!(Program, Diagnostics) programResult =
		frontendCompileProgram(alloc, allSymbols, nozeDir, programDirAndMain);
	return mapSuccess!(ProgramsAndFilesInfo, Program, Diagnostics)(
		programResult,
		(ref immutable Program program) {
			immutable ConcreteProgram concreteProgram = concretize(alloc, program);
			return immutable ProgramsAndFilesInfo(
				program,
				concreteProgram,
				lower(alloc, concreteProgram),
				program.filesInfo);
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
		strLiteral("-lSDL2"),
		// TODO: configurable whether we want debug or release
		strLiteral("-g"),
		pathToStr(alloc, cPath),
		strLiteral("-o"),
		pathToStr(alloc, exePath));
	immutable int err = spawnAndWaitSync(cCompiler, args, environ);
	if (err != 0)
		todo!void("C compile error");
}

void emitProgram(ref immutable LowProgram program, immutable AbsolutePath cPath) {
	Mallocator mallocator;
	WriteAlloc writeAlloc = WriteAlloc(ptrTrustMe_mut(mallocator));
	immutable Str emitted = writeToC(writeAlloc, program);
	writeFileSync(cPath, emitted);
}

void printDiagnostics(ref immutable Diagnostics diagnostics) {
	StackAlloc!("printDiagnostics", 1024 * 1024) tempAlloc;
	printErr(cStrOfDiagnostics(tempAlloc, diagnostics));
}
