module compiler;

@safe @nogc nothrow: // not pure

import backend.writeToC : writeToC;
import concretize.concretize : concretize;
import frontend.ast : FileAst, sexprOfAst;
import frontend.frontendCompile : FileAstAndDiagnostics, frontendCompile, parseSingleAst;
import frontend.getTokens : Token, tokensOfAst, sexprOfTokens;
import frontend.lang : nozeExtension;
import frontend.showDiag : cStrOfDiagnostics;
import interpret.bytecode : ByteCode;
import interpret.realExtern : newRealExtern, RealExtern;
import interpret.generateBytecode : generateBytecode;
import interpret.runBytecode : runBytecode;
import lower.lower : lower;
import model.concreteModel : ConcreteProgram;
import model.diag : Diagnostics, FilesInfo;
import model.lowModel : LowProgram;
import model.model : AbsolutePathsGetter, getAbsolutePath, Module, Program;
import model.sexprOfConcreteModel : tataOfConcreteProgram;
import model.sexprOfLowModel : tataOfLowProgram;
import model.sexprOfModel : sexprOfModule;
import util.alloc.mallocator : Mallocator;
import util.alloc.stackAlloc : SingleHeapAlloc, StackAlloc;
import util.bools : Bool;
import util.collection.arr : Arr, empty;
import util.collection.arrUtil : arrLiteral, cat;
import util.collection.str : emptyStr, Str, strLiteral;
import util.io.io : Environ, replaceCurrentProcess, spawnAndWaitSync, writeFileSync;
import util.opt : force, has, none, Opt, some;
import util.path :
	AbsolutePath,
	Path,
	PathAndStorageKind,
	pathToStr,
	rootPath,
	StorageKind,
	withExtension;
import util.ptr : Ptr, ptrTrustMe_mut;
import util.print : printErr;
import util.result : mapSuccess, matchResultImpure, Result;
import util.sexprPrint : PrintFormat, printOutSexpr;
import util.sym : AllSymbols, shortSymAlphaLiteral;
import util.util : todo, unreachable;

// These return program exit codes

enum PrintKind {
	tokens,
	ast,
	model,
	concreteModel,
	lowModel,
}

immutable(int) print(SymAlloc, ReadOnlyStorage)(
	ref AllSymbols!SymAlloc allSymbols,
	ref immutable ReadOnlyStorage storage,
	immutable PrintKind kind,
	immutable PrintFormat format,
	immutable Ptr!Path mainPath,
) {
	final switch (kind) {
		case PrintKind.tokens:
			return printTokens(allSymbols, storage, mainPath, format);
		case PrintKind.ast:
			return printAst(allSymbols, storage, mainPath, format);
		case PrintKind.model:
			return printModel(allSymbols, storage, mainPath, format);
		case PrintKind.concreteModel:
			return printConcreteModel(allSymbols, storage, mainPath, format);
		case PrintKind.lowModel:
			return printLowModel(allSymbols, storage, mainPath, format);
	}
}

immutable(int) build(SymAlloc, ReadOnlyStorage)(
	ref AllSymbols!SymAlloc allSymbols,
	ref immutable ReadOnlyStorage storage,
	immutable Ptr!Path mainPath,
	ref immutable Environ environ,
) {
	ExePathAlloc exePathAlloc;
	immutable Opt!AbsolutePath exePath = buildWorker(exePathAlloc, allSymbols, storage, mainPath, environ);
	return exePath.has ? 0 : 1;
}

immutable(int) buildAndRun(SymAlloc, ReadOnlyStorage)(
	immutable Bool interpret,
	ref AllSymbols!SymAlloc allSymbols,
	ref immutable ReadOnlyStorage storage,
	immutable Ptr!Path mainPath,
	ref immutable Arr!Str programArgs,
	ref immutable Environ environ,
) {
	if (interpret) {
		Mallocator mallocator;
		LowAlloc lowAlloc = LowAlloc(ptrTrustMe_mut(mallocator));
		immutable Result!(ProgramsAndFilesInfo, Diagnostics) lowProgramResult =
			buildToLowProgram(lowAlloc, allSymbols, storage, mainPath);
		return matchResultImpure!(int, ProgramsAndFilesInfo, Diagnostics)(
			lowProgramResult,
			(ref immutable ProgramsAndFilesInfo it) {
				immutable ByteCode byteCode = generateBytecode(lowAlloc, it.program, it.lowProgram);
				RealExtern extern_ = newRealExtern();
				immutable AbsolutePath mainAbsolutePath =
					getAbsolutePathFromStorage(mallocator, storage, mainPath, nozeExtension);
				return runBytecode(extern_, it.lowProgram, byteCode, it.filesInfo, mainAbsolutePath, programArgs);
			},
			(ref immutable Diagnostics diagnostics) {
				printDiagnostics(diagnostics);
				return 1;
			});
	} else {
		ExePathAlloc exePathAlloc;
		immutable Opt!AbsolutePath exePath = buildWorker(exePathAlloc, allSymbols, storage, mainPath, environ);
		if (exePath.has) {
			replaceCurrentProcess(exePath.force, programArgs, environ);
			return unreachable!int;
		} else
			return 1;
	}
}

private:

immutable(int) printTokens(SymAlloc, ReadOnlyStorage)(
	ref AllSymbols!SymAlloc allSymbols,
	ref immutable ReadOnlyStorage storage,
	immutable Ptr!Path mainPath,
	immutable PrintFormat format,
) {
	StackAlloc!("printTokens", 1024 * 1024) alloc;
	immutable FileAstAndDiagnostics astResult = getAst(alloc, allSymbols, storage, mainPath);
	printDiagnostics(astResult.diagnostics);
	immutable Arr!Token tokens = tokensOfAst(alloc, astResult.ast);
	printOutSexpr(sexprOfTokens(alloc, tokens), format);
	return empty(astResult.diagnostics.diagnostics) ? 0 : 1;
}

immutable(int) printAst(SymAlloc, ReadOnlyStorage)(
	ref AllSymbols!SymAlloc allSymbols,
	ref immutable ReadOnlyStorage storage,
	immutable Ptr!Path mainPath,
	immutable PrintFormat format,
) {
	StackAlloc!("printAst", 1024 * 1024) alloc;
	immutable FileAstAndDiagnostics astResult = getAst(alloc, allSymbols, storage, mainPath);
	printDiagnostics(astResult.diagnostics);
	printOutAst(astResult.ast, format);
	return empty(astResult.diagnostics.diagnostics) ? 0 : 1;
}

immutable(FileAstAndDiagnostics) getAst(Alloc, SymAlloc, ReadOnlyStorage)(
	ref Alloc alloc,
	ref AllSymbols!SymAlloc allSymbols,
	ref immutable ReadOnlyStorage storage,
	immutable Ptr!Path mainPath,
) {
	return parseSingleAst(alloc, allSymbols, storage, mainPath);
}

immutable(int) printModel(SymAlloc, ReadOnlyStorage)(
	ref AllSymbols!SymAlloc allSymbols,
	ref immutable ReadOnlyStorage storage,
	immutable Ptr!Path mainPath,
	immutable PrintFormat format,
) {
	Mallocator mallocator;
	ModelAlloc modelAlloc = ModelAlloc(ptrTrustMe_mut(mallocator));
	immutable Result!(Program, Diagnostics) programResult =
		frontendCompileProgram(modelAlloc, allSymbols, storage, mainPath);
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

immutable(int) printConcreteModel(SymAlloc, ReadOnlyStorage)(
	ref AllSymbols!SymAlloc allSymbols,
	ref immutable ReadOnlyStorage storage,
	immutable Ptr!Path mainPath,
	immutable PrintFormat format,
) {
	Mallocator mallocator;
	ModelAlloc modelAlloc = ModelAlloc(ptrTrustMe_mut(mallocator));
	immutable Result!(Program, Diagnostics) programResult =
		frontendCompileProgram(modelAlloc, allSymbols, storage, mainPath);
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

immutable(int) printLowModel(SymAlloc, ReadOnlyStorage)(
	ref AllSymbols!SymAlloc allSymbols,
	ref immutable ReadOnlyStorage storage,
	immutable Ptr!Path mainPath,
	immutable PrintFormat format,
) {
	Mallocator mallocator;
	ModelAlloc modelAlloc = ModelAlloc(ptrTrustMe_mut(mallocator));
	immutable Result!(Program, Diagnostics) programResult =
		frontendCompileProgram(modelAlloc, allSymbols, storage, mainPath);
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
immutable(Opt!AbsolutePath) buildWorker(Alloc, SymAlloc, ReadOnlyStorage)(
	ref Alloc outputAlloc, // Just for exePath
	ref AllSymbols!SymAlloc allSymbols,
	ref immutable ReadOnlyStorage storage,
	immutable Ptr!Path mainPath,
	ref immutable Environ environ
) {
	Mallocator mallocator;
	LowAlloc lowAlloc = LowAlloc(ptrTrustMe_mut(mallocator));
	immutable Result!(ProgramsAndFilesInfo, Diagnostics) programResult =
		buildToLowProgram(lowAlloc, allSymbols, storage, mainPath);
	return matchResultImpure!(Opt!AbsolutePath)(
		programResult,
		(ref immutable ProgramsAndFilesInfo lowProgram) {
			immutable AbsolutePath fullMainPath = getAbsolutePathFromStorage(outputAlloc, storage, mainPath, emptyStr);
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

immutable(Result!(ProgramsAndFilesInfo, Diagnostics)) buildToLowProgram(Alloc, SymAlloc, ReadOnlyStorage)(
	ref Alloc alloc,
	ref AllSymbols!SymAlloc allSymbols,
	ref immutable ReadOnlyStorage storage,
	immutable Ptr!Path mainPath,
) {
	immutable Result!(Program, Diagnostics) programResult =
		frontendCompileProgram(alloc, allSymbols, storage, mainPath);
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

//TODO:INLINE
immutable(Result!(Program, Diagnostics)) frontendCompileProgram(ModelAlloc, SymAlloc, ReadOnlyStorage)(
	ref ModelAlloc modelAlloc,
	ref AllSymbols!SymAlloc allSymbols,
	ref immutable ReadOnlyStorage storage,
	immutable Ptr!Path mainPath,
) {
	return frontendCompile(modelAlloc, allSymbols, storage, mainPath);
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

immutable(AbsolutePath) getAbsolutePathFromStorage(Alloc, Storage)(
	ref Alloc alloc,
	ref immutable Storage storage,
	immutable Ptr!Path path,
	immutable Str extension,
) {
	immutable AbsolutePathsGetter abs = storage.absolutePathsGetter();
	immutable PathAndStorageKind pk = immutable PathAndStorageKind(path, StorageKind.local);
	return getAbsolutePath(alloc, abs, pk, extension);
}
