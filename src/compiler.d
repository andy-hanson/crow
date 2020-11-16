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
import util.collection.arr : Arr, begin, size;
import util.collection.str : emptyStr, Str;
import util.path : AbsolutePath, Path, PathAndStorageKind, StorageKind;
import util.ptr : Ptr, ptrTrustMe_mut;
import util.result : fail, mapSuccess, matchResult, matchResultImpure, Result, success;
import util.sexpr : Sexpr, writeSexpr, writeSexprJSON;
import util.sym : AllSymbols;
import util.writer : finishWriter, Writer;

enum PrintFormat {
	sexpr,
	json,
}

enum PrintKind {
	tokens,
	ast,
	model,
	concreteModel,
	lowModel,
}

struct DiagsAndResultStrs {
	immutable Str diagnostics;
	immutable Str result;
}

immutable(DiagsAndResultStrs) print(Alloc, SymAlloc, ReadOnlyStorage)(
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

// These return program exit codes

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
			writeDiagsToExtern(alloc, extern_, diagnostics);
			return 1;
		});
}

private:

@trusted void writeDiagsToExtern(Alloc, Extern)(
	ref Alloc alloc,
	ref Extern extern_,
	ref immutable Diagnostics diagnostics,
) {
	immutable int stderr = 2;
	immutable Str s = strOfDiagnostics(alloc, diagnostics);
	extern_.write(stderr, begin(s), size(s));
}

immutable(DiagsAndResultStrs) printTokens(Alloc, SymAlloc, ReadOnlyStorage)(
	ref Alloc alloc,
	ref AllSymbols!SymAlloc allSymbols,
	ref ReadOnlyStorage storage,
	immutable Ptr!Path mainPath,
	immutable PrintFormat format,
) {
	immutable FileAstAndDiagnostics astResult = parseSingleAst(alloc, allSymbols, storage, mainPath);
	immutable Arr!Token tokens = tokensOfAst(alloc, astResult.ast);
	return immutable DiagsAndResultStrs(
		strOfDiagnostics(alloc, astResult.diagnostics),
		showSexpr(alloc, sexprOfTokens(alloc, tokens), format));
}

immutable(DiagsAndResultStrs) printAst(Alloc, SymAlloc, ReadOnlyStorage)(
	ref Alloc alloc,
	ref AllSymbols!SymAlloc allSymbols,
	ref ReadOnlyStorage storage,
	immutable Ptr!Path mainPath,
	immutable PrintFormat format,
) {
	immutable FileAstAndDiagnostics astResult = parseSingleAst(alloc, allSymbols, storage, mainPath);
	return immutable DiagsAndResultStrs(
		strOfDiagnostics(alloc, astResult.diagnostics),
		showAst(alloc, astResult.ast, format));
}

immutable(DiagsAndResultStrs) printModel(Alloc, SymAlloc, ReadOnlyStorage)(
	ref Alloc alloc,
	ref AllSymbols!SymAlloc allSymbols,
	ref ReadOnlyStorage storage,
	immutable Ptr!Path mainPath,
	immutable PrintFormat format,
) {
	alias TempAlloc = Arena!(Alloc, "printModel");
	TempAlloc tempAlloc = TempAlloc(ptrTrustMe_mut(alloc));
	immutable Result!(Ptr!Program, Diagnostics) programResult =
		frontendCompile(tempAlloc, tempAlloc, allSymbols, storage, mainPath);
	return matchResult!(immutable DiagsAndResultStrs, Ptr!Program, Diagnostics)(
		programResult,
		(ref immutable Ptr!Program program) =>
			immutable DiagsAndResultStrs(emptyStr, showModule(alloc, program.specialModules.mainModule, format)),
		(ref immutable Diagnostics diagnostics) =>
			immutable DiagsAndResultStrs(strOfDiagnostics(alloc, diagnostics), emptyStr));
}

immutable(DiagsAndResultStrs) printConcreteModel(Alloc, SymAlloc, ReadOnlyStorage)(
	ref Alloc alloc,
	ref AllSymbols!SymAlloc allSymbols,
	ref ReadOnlyStorage storage,
	immutable Ptr!Path mainPath,
	immutable PrintFormat format,
) {
	alias TempAlloc = Arena!(Alloc, "printModel");
	TempAlloc tempAlloc = TempAlloc(ptrTrustMe_mut(alloc));
	immutable Result!(Ptr!Program, Diagnostics) programResult =
		frontendCompile(tempAlloc, tempAlloc, allSymbols, storage, mainPath);
	return matchResult!(immutable DiagsAndResultStrs, Ptr!Program, Diagnostics)(
		programResult,
		(ref immutable Ptr!Program program) {
			immutable ConcreteProgram concreteProgram = concretize(tempAlloc, program);
			return immutable DiagsAndResultStrs(emptyStr, showConcreteProgram(alloc, concreteProgram, format));
		},
		(ref immutable Diagnostics diagnostics) =>
			immutable DiagsAndResultStrs(strOfDiagnostics(alloc, diagnostics), emptyStr));

}

immutable(DiagsAndResultStrs) printLowModel(Alloc, SymAlloc, ReadOnlyStorage)(
	ref Alloc alloc,
	ref AllSymbols!SymAlloc allSymbols,
	ref ReadOnlyStorage storage,
	immutable Ptr!Path mainPath,
	immutable PrintFormat format,
) {
	alias TempAlloc = Arena!(Alloc, "printModel");
	TempAlloc tempAlloc = TempAlloc(ptrTrustMe_mut(alloc));
	immutable Result!(Ptr!Program, Diagnostics) programResult =
		frontendCompile(tempAlloc, tempAlloc, allSymbols, storage, mainPath);
	return matchResultImpure!(immutable DiagsAndResultStrs, Ptr!Program, Diagnostics)(
		programResult,
		(ref immutable Ptr!Program program) {
			immutable ConcreteProgram concreteProgram = concretize(tempAlloc, program);
			immutable Ptr!LowProgram lowProgram = lower(tempAlloc, concreteProgram);
			return immutable DiagsAndResultStrs(emptyStr, showLowProgram(alloc, lowProgram, format));
		},
		(ref immutable Diagnostics diagnostics) =>
			immutable DiagsAndResultStrs(strOfDiagnostics(tempAlloc, diagnostics), emptyStr));
}

//TODO:INLINE
immutable(Str) showAst(Alloc)(ref Alloc alloc, ref immutable FileAst ast, immutable PrintFormat format) {
	return showSexpr(alloc, sexprOfAst(alloc, ast), format);
}

//TODO:INLINE
immutable(Str) showModule(Alloc)(ref Alloc alloc, ref immutable Module a, immutable PrintFormat format) {
	return showSexpr(alloc, sexprOfModule(alloc, a), format);
}

//TODO:INLINE
immutable(Str) showConcreteProgram(Alloc)(
	ref Alloc alloc,
	ref immutable ConcreteProgram a,
	immutable PrintFormat format,
) {
	return showSexpr(alloc, tataOfConcreteProgram(alloc, a), format);
}

//TODO:INLINE
immutable(Str) showLowProgram(Alloc)(ref Alloc alloc, ref immutable LowProgram a, immutable PrintFormat format) {
	return showSexpr(alloc, tataOfLowProgram(alloc, a), format);
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
	immutable Ptr!Program program;
	immutable Ptr!ConcreteProgram concreteProgram;
	immutable Ptr!LowProgram lowProgram;
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
	immutable Result!(Ptr!Program, Diagnostics) programResult =
		frontendCompile(alloc, astsAlloc, allSymbols, storage, mainPath);
	return mapSuccess!(ProgramsAndFilesInfo, Ptr!Program, Diagnostics)(
		programResult,
		(ref immutable Ptr!Program program) {
			immutable Ptr!ConcreteProgram concreteProgram = concretize(alloc, program);
			return immutable ProgramsAndFilesInfo(
				program,
				concreteProgram,
				lower(alloc, concreteProgram),
				program.filesInfo);
		});
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

immutable(Str) showSexpr(Alloc)(ref Alloc alloc, immutable Sexpr a, immutable PrintFormat format) {
	Writer!Alloc writer = Writer!Alloc(ptrTrustMe_mut(alloc));
	final switch (format) {
		case PrintFormat.sexpr:
			writeSexpr(writer, a);
			break;
		case PrintFormat.json:
			writeSexprJSON(writer, a);
			break;
	}
	return finishWriter(writer);
}
