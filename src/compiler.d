module compiler;

@safe @nogc nothrow: // not pure

import backend.writeToC : writeToC;
import concretize.concretize : concretize;
import frontend.ast : FileAst, sexprOfAst;
import frontend.frontendCompile : FileAstAndDiagnostics, frontendCompile, parseSingleAst;
import frontend.getTokens : Token, tokensOfAst, sexprOfTokens;
import frontend.lang : nozeExtension;
import frontend.showDiag : strOfDiagnostics;
import interpret.bytecode : ByteCode;
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
import util.collection.arr : Arr, empty;
import util.collection.str : Str;
import util.path : AbsolutePath, Path, PathAndStorageKind, StorageKind;
import util.ptr : Ptr, ptrTrustMe_mut;
import util.print : printErr;
import util.result : fail, mapSuccess, matchResult, matchResultImpure, Result, success;
import util.sexprPrint : PrintFormat, printOutSexpr;
import util.sym : AllSymbols;

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

immutable(int) buildAndInterpret(Alloc, SymAlloc, ReadOnlyStorage, Extern)(
	ref Alloc alloc,
	ref AllSymbols!SymAlloc allSymbols,
	ref ReadOnlyStorage storage,
	ref Extern extern_,
	immutable Ptr!Path mainPath,
	ref immutable Arr!Str programArgs,
) {
	alias TempAlloc = Arena!(Alloc, "buildAndRun");
	TempAlloc tempAlloc = TempAlloc(ptrTrustMe_mut(alloc));
	immutable Result!(ProgramsAndFilesInfo, Diagnostics) lowProgramResult =
		buildToLowProgram(tempAlloc, allSymbols, storage, mainPath);
	return matchResultImpure!(int, ProgramsAndFilesInfo, Diagnostics)(
		lowProgramResult,
		(ref immutable ProgramsAndFilesInfo it) {
			immutable ByteCode byteCode = generateBytecode(tempAlloc, tempAlloc, it.program, it.lowProgram);
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

public immutable(Result!(Str, Str)) buildToC(Alloc, SymAlloc, ReadOnlyStorage)(
	ref Alloc alloc,
	ref AllSymbols!SymAlloc allSymbols,
	ref ReadOnlyStorage storage,
	immutable Ptr!Path mainPath,
) {
	alias TempAlloc = Arena!(Alloc, "buildToC");
	TempAlloc tempAlloc = TempAlloc(ptrTrustMe_mut(alloc));
	immutable Result!(ProgramsAndFilesInfo, Diagnostics) programResult =
		buildToLowProgram(tempAlloc, allSymbols, storage, mainPath);
	return matchResult!(Result!(Str, Str), ProgramsAndFilesInfo, Diagnostics)(
		programResult,
		(ref immutable ProgramsAndFilesInfo it) =>
			success!(Str, Str)(writeToC!Alloc(alloc, it.lowProgram)),
		(ref immutable Diagnostics it) =>
			fail!(Str, Str)(strOfDiagnostics(alloc, it)));
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

void printDiagnostics(Alloc)(ref Alloc alloc, ref immutable Diagnostics diagnostics) {
	printErr(strOfDiagnostics(alloc, diagnostics));
}

public immutable(AbsolutePath) getAbsolutePathFromStorage(Alloc, Storage)(
	ref Alloc alloc,
	ref Storage storage,
	immutable Ptr!Path path,
	immutable Str extension,
) {
	immutable AbsolutePathsGetter abs = storage.absolutePathsGetter();
	immutable PathAndStorageKind pk = immutable PathAndStorageKind(path, StorageKind.local);
	return getAbsolutePath(alloc, abs, pk, extension);
}
