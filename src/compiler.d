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
import util.alloc.arena : Arena;
import util.bools : Bool;
import util.collection.arr : Arr, empty;
import util.collection.arrUtil : arrLiteral;
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

immutable(int) print(Alloc, SymAlloc, ReadOnlyStorage)(
	ref Alloc alloc,
	ref AllSymbols!SymAlloc allSymbols,
	ref ReadOnlyStorage storage,
	immutable PrintKind kind,
	immutable PrintFormat format,
	immutable Ptr!Path mainPath,
) {
	final switch (kind) {
		case PrintKind.tokens:
			return printTokens(alloc, allSymbols, storage, mainPath, format);
		case PrintKind.ast:
			return printAst(alloc, allSymbols, storage, mainPath, format);
		case PrintKind.model:
			return printModel(alloc, allSymbols, storage, mainPath, format);
		case PrintKind.concreteModel:
			return printConcreteModel(alloc, allSymbols, storage, mainPath, format);
		case PrintKind.lowModel:
			return printLowModel(alloc, allSymbols, storage, mainPath, format);
	}
}

immutable(int) build(Alloc, SymAlloc, ReadOnlyStorage)(
	ref Alloc alloc,
	ref AllSymbols!SymAlloc allSymbols,
	ref ReadOnlyStorage storage,
	immutable Ptr!Path mainPath,
	ref immutable Environ environ,
) {
	immutable Opt!AbsolutePath exePath = buildWorker(alloc, allSymbols, storage, mainPath, environ);
	return exePath.has ? 0 : 1;
}

immutable(int) buildAndRun(Alloc, SymAlloc, ReadOnlyStorage)(
	ref Alloc alloc,
	immutable Bool interpret,
	ref AllSymbols!SymAlloc allSymbols,
	ref ReadOnlyStorage storage,
	immutable Ptr!Path mainPath,
	ref immutable Arr!Str programArgs,
	ref immutable Environ environ,
) {
	alias TempAlloc = Arena!(Alloc, "buildAndRun");
	TempAlloc tempAlloc = TempAlloc(ptrTrustMe_mut(alloc));
	if (interpret) {
		immutable Result!(ProgramsAndFilesInfo, Diagnostics) lowProgramResult =
			buildToLowProgram(tempAlloc, allSymbols, storage, mainPath);
		return matchResultImpure!(int, ProgramsAndFilesInfo, Diagnostics)(
			lowProgramResult,
			(ref immutable ProgramsAndFilesInfo it) {
				immutable ByteCode byteCode = generateBytecode(tempAlloc, tempAlloc, it.program, it.lowProgram);
				RealExtern extern_ = newRealExtern();
				immutable AbsolutePath mainAbsolutePath =
					getAbsolutePathFromStorage(tempAlloc, storage, mainPath, nozeExtension);
				return runBytecode(
					tempAlloc,
					extern_,
					it.lowProgram,
					byteCode,
					it.filesInfo,
					mainAbsolutePath,
					programArgs);
			},
			(ref immutable Diagnostics diagnostics) {
				printDiagnostics(alloc, diagnostics);
				return 1;
			});
	} else {
		immutable Opt!AbsolutePath exePath = buildWorker(tempAlloc, allSymbols, storage, mainPath, environ);
		if (exePath.has) {
			replaceCurrentProcess(tempAlloc, exePath.force, programArgs, environ);
			return unreachable!int;
		} else
			return 1;
	}
}

private:

immutable(int) printTokens(Alloc, SymAlloc, ReadOnlyStorage)(
	ref Alloc alloc,
	ref AllSymbols!SymAlloc allSymbols,
	ref ReadOnlyStorage storage,
	immutable Ptr!Path mainPath,
	immutable PrintFormat format,
) {
	immutable FileAstAndDiagnostics astResult = parseSingleAst(alloc, allSymbols, storage, mainPath);
	printDiagnostics(alloc, astResult.diagnostics);
	immutable Arr!Token tokens = tokensOfAst(alloc, astResult.ast);
	printOutSexpr(alloc, sexprOfTokens(alloc, tokens), format);
	return empty(astResult.diagnostics.diagnostics) ? 0 : 1;
}

immutable(int) printAst(Alloc, SymAlloc, ReadOnlyStorage)(
	ref Alloc alloc,
	ref AllSymbols!SymAlloc allSymbols,
	ref ReadOnlyStorage storage,
	immutable Ptr!Path mainPath,
	immutable PrintFormat format,
) {
	immutable FileAstAndDiagnostics astResult = parseSingleAst(alloc, allSymbols, storage, mainPath);
	printDiagnostics(alloc, astResult.diagnostics);
	printOutAst(alloc, astResult.ast, format);
	return empty(astResult.diagnostics.diagnostics) ? 0 : 1;
}

immutable(int) printModel(Alloc, SymAlloc, ReadOnlyStorage)(
	ref Alloc alloc,
	ref AllSymbols!SymAlloc allSymbols,
	ref ReadOnlyStorage storage,
	immutable Ptr!Path mainPath,
	immutable PrintFormat format,
) {
	alias TempAlloc = Arena!(Alloc, "printModel");
	TempAlloc tempAlloc = TempAlloc(ptrTrustMe_mut(alloc));
	immutable Result!(Program, Diagnostics) programResult =
		frontendCompile(tempAlloc, tempAlloc, allSymbols, storage, mainPath);
	return matchResultImpure!(int, Program, Diagnostics)(
		programResult,
		(ref immutable Program program) {
			printOutModule(alloc, program.mainModule, format);
			return 0;
		},
		(ref immutable Diagnostics diagnostics) {
			printDiagnostics(alloc, diagnostics);
			return 1;
		});
}

immutable(int) printConcreteModel(Alloc, SymAlloc, ReadOnlyStorage)(
	ref Alloc alloc,
	ref AllSymbols!SymAlloc allSymbols,
	ref ReadOnlyStorage storage,
	immutable Ptr!Path mainPath,
	immutable PrintFormat format,
) {
	alias TempAlloc = Arena!(Alloc, "printModel");
	TempAlloc tempAlloc = TempAlloc(ptrTrustMe_mut(alloc));
	immutable Result!(Program, Diagnostics) programResult =
		frontendCompile(tempAlloc, tempAlloc, allSymbols, storage, mainPath);
	return matchResultImpure!(int, Program, Diagnostics)(
		programResult,
		(ref immutable Program program) {
			immutable ConcreteProgram concreteProgram = concretize(tempAlloc, program);
			printOutConcreteProgram(tempAlloc, concreteProgram, format);
			return 0;
		},
		(ref immutable Diagnostics diagnostics) {
			printDiagnostics(tempAlloc, diagnostics);
			return 1;
		});

}

immutable(int) printLowModel(Alloc, SymAlloc, ReadOnlyStorage)(
	ref Alloc alloc,
	ref AllSymbols!SymAlloc allSymbols,
	ref ReadOnlyStorage storage,
	immutable Ptr!Path mainPath,
	immutable PrintFormat format,
) {
	alias TempAlloc = Arena!(Alloc, "printModel");
	TempAlloc tempAlloc = TempAlloc(ptrTrustMe_mut(alloc));
	immutable Result!(Program, Diagnostics) programResult =
		frontendCompile(tempAlloc, tempAlloc, allSymbols, storage, mainPath);
	return matchResultImpure!(int, Program, Diagnostics)(
		programResult,
		(ref immutable Program program) {
			immutable ConcreteProgram concreteProgram = concretize(tempAlloc, program);
			immutable LowProgram lowProgram = lower(tempAlloc, concreteProgram);
			printOutLowProgram(tempAlloc, lowProgram, format);
			return 0;
		},
		(ref immutable Diagnostics diagnostics) {
			printDiagnostics(tempAlloc, diagnostics);
			return 1;
		});

}

void printOutAst(Alloc)(ref Alloc alloc, ref immutable FileAst ast, immutable PrintFormat format) {
	printOutSexpr(alloc, sexprOfAst(alloc, ast), format);
}

void printOutModule(Alloc)(ref Alloc alloc, ref immutable Module a, immutable PrintFormat format) {
	printOutSexpr(alloc, sexprOfModule(alloc, a), format);
}

void printOutConcreteProgram(Alloc)(ref Alloc alloc, ref immutable ConcreteProgram a, immutable PrintFormat format) {
	printOutSexpr(alloc, tataOfConcreteProgram(alloc, a), format);
}

void printOutLowProgram(Alloc)(ref Alloc alloc, ref immutable LowProgram a, immutable PrintFormat format) {
	printOutSexpr(alloc, tataOfLowProgram(alloc, a), format);
}

// mainPath is relative to programDir
// Returns exePath
immutable(Opt!AbsolutePath) buildWorker(Alloc, SymAlloc, ReadOnlyStorage)(
	ref Alloc alloc,
	ref AllSymbols!SymAlloc allSymbols,
	ref ReadOnlyStorage storage,
	immutable Ptr!Path mainPath,
	ref immutable Environ environ
) {
	alias TempAlloc = Arena!(Alloc, "buildWorker");
	TempAlloc tempAlloc = TempAlloc(ptrTrustMe_mut(alloc));
	immutable Result!(ProgramsAndFilesInfo, Diagnostics) programResult =
		buildToLowProgram(tempAlloc, allSymbols, storage, mainPath);
	return matchResultImpure!(Opt!AbsolutePath)(
		programResult,
		(ref immutable ProgramsAndFilesInfo lowProgram) {
			immutable AbsolutePath fullMainPath = getAbsolutePathFromStorage(alloc, storage, mainPath, emptyStr);
			immutable AbsolutePath fullMainCPath = withExtension(fullMainPath, strLiteral(".c"));
			emitProgram(tempAlloc, lowProgram.lowProgram, fullMainCPath);
			compileC(tempAlloc, fullMainCPath, fullMainPath, environ);
			return some(fullMainPath);
		},
		(ref immutable Diagnostics diagnostics) {
			printDiagnostics(alloc, diagnostics);
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
	ref ReadOnlyStorage storage,
	immutable Ptr!Path mainPath,
) {
	alias AstsAlloc = Arena!(Alloc, "asts");
	AstsAlloc astsAlloc = AstsAlloc(ptrTrustMe_mut(alloc));
	immutable Result!(Program, Diagnostics) programResult =
		frontendCompile(alloc, astsAlloc, allSymbols, storage, mainPath);
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

void compileC(Alloc)(
	ref Alloc alloc,
	ref immutable AbsolutePath cPath,
	ref immutable AbsolutePath exePath,
	ref immutable Environ environ,
) {
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
	immutable int err = spawnAndWaitSync(alloc, cCompiler, args, environ);
	if (err != 0)
		todo!void("C compile error");
}

void emitProgram(Alloc)(ref Alloc alloc, ref immutable LowProgram program, ref immutable AbsolutePath cPath) {
	immutable Str cProgram = writeToC(alloc, program);
	writeFileSync(alloc, cPath, cProgram);
}

void printDiagnostics(Alloc)(ref Alloc alloc, ref immutable Diagnostics diagnostics) {
	printErr(cStrOfDiagnostics(alloc, diagnostics));
}

immutable(AbsolutePath) getAbsolutePathFromStorage(Alloc, Storage)(
	ref Alloc alloc,
	ref Storage storage,
	immutable Ptr!Path path,
	immutable Str extension,
) {
	immutable AbsolutePathsGetter abs = storage.absolutePathsGetter();
	immutable PathAndStorageKind pk = immutable PathAndStorageKind(path, StorageKind.local);
	return getAbsolutePath(alloc, abs, pk, extension);
}
