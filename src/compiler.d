module compiler;

@safe @nogc nothrow: // not pure

import backend.writeToC : writeToC;
import concretize.concretize : concretize;
import frontend.ast : FileAst, sexprOfAst;
import frontend.frontendCompile : FileAstAndDiagnostics, frontendCompile, parseSingleAst;
import frontend.getTokens : Token, tokensOfAst, sexprOfTokens;
import frontend.lang : nozeExtension;
import frontend.showDiag : ShowDiagOptions, strOfDiagnostics;
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
import util.collection.arr : Arr, begin, size;
import util.collection.str : emptyStr, Str;
import util.path : AbsolutePath, AllPaths, Path, PathAndStorageKind, StorageKind;
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

immutable(DiagsAndResultStrs) print(Alloc, PathAlloc, SymAlloc, ReadOnlyStorage)(
	ref Alloc alloc,
	ref AllPaths!PathAlloc allPaths,
	ref AllSymbols!SymAlloc allSymbols,
	ref ReadOnlyStorage storage,
	ref immutable ShowDiagOptions showDiagOptions,
	immutable PrintKind kind,
	immutable PrintFormat format,
	immutable Path mainPath,
) {
	final switch (kind) {
		case PrintKind.tokens:
			return printTokens(alloc, allPaths, allSymbols, storage, showDiagOptions, mainPath, format);
		case PrintKind.ast:
			return printAst(alloc, allPaths, allSymbols, storage, showDiagOptions, mainPath, format);
		case PrintKind.model:
			return printModel(alloc, allPaths, allSymbols, storage, showDiagOptions, mainPath, format);
		case PrintKind.concreteModel:
			return printConcreteModel(alloc, allPaths, allSymbols, storage, showDiagOptions, mainPath, format);
		case PrintKind.lowModel:
			return printLowModel(alloc, allPaths, allSymbols, storage, showDiagOptions, mainPath, format);
	}
}

// These return program exit codes

immutable(int) buildAndInterpret(Debug, Alloc, PathAlloc, SymAlloc, ReadOnlyStorage, Extern)(
	ref Debug dbg,
	ref Alloc alloc,
	ref AllPaths!PathAlloc allPaths,
	ref AllSymbols!SymAlloc allSymbols,
	ref ReadOnlyStorage storage,
	ref Extern extern_,
	ref immutable ShowDiagOptions showDiagOptions,
	immutable Path mainPath,
	ref immutable Arr!Str programArgs,
) {
	immutable Result!(ProgramsAndFilesInfo, Diagnostics) lowProgramResult =
		buildToLowProgram(alloc, allPaths, allSymbols, storage, mainPath);
	return matchResultImpure!(int, ProgramsAndFilesInfo, Diagnostics)(
		lowProgramResult,
		(ref immutable ProgramsAndFilesInfo it) {
			immutable ByteCode byteCode = generateBytecode(dbg, alloc, alloc, it.program, it.lowProgram);
			immutable AbsolutePath mainAbsolutePath =
				getAbsolutePathFromStorage(alloc, storage, mainPath, nozeExtension);
			return runBytecode(
				dbg,
				alloc,
				allPaths,
				extern_,
				it.lowProgram,
				byteCode,
				it.filesInfo,
				mainAbsolutePath,
				programArgs);
		},
		(ref immutable Diagnostics diagnostics) {
			writeDiagsToExtern(alloc, allPaths, extern_, showDiagOptions, diagnostics);
			return 1;
		});
}

private:

@trusted void writeDiagsToExtern(Alloc, PathAlloc, Extern)(
	ref Alloc alloc,
	ref const AllPaths!PathAlloc allPaths,
	ref Extern extern_,
	ref immutable ShowDiagOptions showDiagOptions,
	ref immutable Diagnostics diagnostics,
) {
	immutable int stderr = 2;
	immutable Str s = strOfDiagnostics(alloc, allPaths, showDiagOptions, diagnostics);
	extern_.write(stderr, begin(s), size(s));
}

immutable(DiagsAndResultStrs) printTokens(Alloc, PathAlloc, SymAlloc, ReadOnlyStorage)(
	ref Alloc alloc,
	ref AllPaths!PathAlloc allPaths,
	ref AllSymbols!SymAlloc allSymbols,
	ref ReadOnlyStorage storage,
	ref immutable ShowDiagOptions showDiagOptions,
	immutable Path mainPath,
	immutable PrintFormat format,
) {
	immutable FileAstAndDiagnostics astResult = parseSingleAst(alloc, allPaths, allSymbols, storage, mainPath);
	immutable Arr!Token tokens = tokensOfAst(alloc, astResult.ast);
	return immutable DiagsAndResultStrs(
		strOfDiagnostics(alloc, allPaths, showDiagOptions, astResult.diagnostics),
		showSexpr(alloc, sexprOfTokens(alloc, tokens), format));
}

immutable(DiagsAndResultStrs) printAst(Alloc, PathAlloc, SymAlloc, ReadOnlyStorage)(
	ref Alloc alloc,
	ref AllPaths!PathAlloc allPaths,
	ref AllSymbols!SymAlloc allSymbols,
	ref ReadOnlyStorage storage,
	ref immutable ShowDiagOptions showDiagOptions,
	immutable Path mainPath,
	immutable PrintFormat format,
) {
	immutable FileAstAndDiagnostics astResult = parseSingleAst(alloc, allPaths, allSymbols, storage, mainPath);
	return immutable DiagsAndResultStrs(
		strOfDiagnostics(alloc, allPaths, showDiagOptions, astResult.diagnostics),
		showAst(alloc, allPaths, astResult.ast, format));
}

immutable(DiagsAndResultStrs) printModel(Alloc, PathAlloc, SymAlloc, ReadOnlyStorage)(
	ref Alloc alloc,
	ref AllPaths!PathAlloc allPaths,
	ref AllSymbols!SymAlloc allSymbols,
	ref ReadOnlyStorage storage,
	ref immutable ShowDiagOptions showDiagOptions,
	immutable Path mainPath,
	immutable PrintFormat format,
) {
	immutable Result!(Ptr!Program, Diagnostics) programResult =
		frontendCompile(alloc, alloc, allPaths, allSymbols, storage, mainPath);
	return matchResult!(immutable DiagsAndResultStrs, Ptr!Program, Diagnostics)(
		programResult,
		(ref immutable Ptr!Program program) =>
			immutable DiagsAndResultStrs(emptyStr, showModule(alloc, program.specialModules.mainModule, format)),
		(ref immutable Diagnostics diagnostics) =>
			immutable DiagsAndResultStrs(strOfDiagnostics(alloc, allPaths, showDiagOptions, diagnostics), emptyStr));
}

immutable(DiagsAndResultStrs) printConcreteModel(Alloc, PathAlloc, SymAlloc, ReadOnlyStorage)(
	ref Alloc alloc,
	ref AllPaths!PathAlloc allPaths,
	ref AllSymbols!SymAlloc allSymbols,
	ref ReadOnlyStorage storage,
	ref immutable ShowDiagOptions showDiagOptions,
	immutable Path mainPath,
	immutable PrintFormat format,
) {
	immutable Result!(Ptr!Program, Diagnostics) programResult =
		frontendCompile(alloc, alloc, allPaths, allSymbols, storage, mainPath);
	return matchResult!(immutable DiagsAndResultStrs, Ptr!Program, Diagnostics)(
		programResult,
		(ref immutable Ptr!Program program) {
			immutable ConcreteProgram concreteProgram = concretize(alloc, program);
			return immutable DiagsAndResultStrs(emptyStr, showConcreteProgram(alloc, concreteProgram, format));
		},
		(ref immutable Diagnostics diagnostics) =>
			immutable DiagsAndResultStrs(strOfDiagnostics(alloc, allPaths, showDiagOptions, diagnostics), emptyStr));

}

immutable(DiagsAndResultStrs) printLowModel(Alloc, PathAlloc, SymAlloc, ReadOnlyStorage)(
	ref Alloc alloc,
	ref AllPaths!PathAlloc allPaths,
	ref AllSymbols!SymAlloc allSymbols,
	ref ReadOnlyStorage storage,
	ref immutable ShowDiagOptions showDiagOptions,
	immutable Path mainPath,
	immutable PrintFormat format,
) {
	immutable Result!(Ptr!Program, Diagnostics) programResult =
		frontendCompile(alloc, alloc, allPaths, allSymbols, storage, mainPath);
	return matchResultImpure!(immutable DiagsAndResultStrs, Ptr!Program, Diagnostics)(
		programResult,
		(ref immutable Ptr!Program program) {
			immutable ConcreteProgram concreteProgram = concretize(alloc, program);
			immutable Ptr!LowProgram lowProgram = lower(alloc, concreteProgram);
			return immutable DiagsAndResultStrs(emptyStr, showLowProgram(alloc, lowProgram, format));
		},
		(ref immutable Diagnostics diagnostics) =>
			immutable DiagsAndResultStrs(strOfDiagnostics(alloc, allPaths, showDiagOptions, diagnostics), emptyStr));
}

//TODO:INLINE
immutable(Str) showAst(Alloc, PathAlloc)(
	ref Alloc alloc,
	ref const AllPaths!PathAlloc allPaths,
	ref immutable FileAst ast,
	immutable PrintFormat format,
) {
	return showSexpr(alloc, sexprOfAst(alloc, allPaths, ast), format);
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

public immutable(Result!(Str, Str)) buildToC(Alloc, PathAlloc, SymAlloc, ReadOnlyStorage)(
	ref Alloc alloc,
	ref AllPaths!PathAlloc allPaths,
	ref AllSymbols!SymAlloc allSymbols,
	ref ReadOnlyStorage storage,
	ref immutable ShowDiagOptions showDiagOptions,
	immutable Path mainPath,
) {
	immutable Result!(ProgramsAndFilesInfo, Diagnostics) programResult =
		buildToLowProgram(alloc, allPaths, allSymbols, storage, mainPath);
	return matchResult!(Result!(Str, Str), ProgramsAndFilesInfo, Diagnostics)(
		programResult,
		(ref immutable ProgramsAndFilesInfo it) =>
			success!(Str, Str)(writeToC!Alloc(alloc, it.lowProgram)),
		(ref immutable Diagnostics it) =>
			fail!(Str, Str)(strOfDiagnostics(alloc, allPaths, showDiagOptions, it)));
}

struct ProgramsAndFilesInfo {
	immutable Ptr!Program program;
	immutable Ptr!ConcreteProgram concreteProgram;
	immutable Ptr!LowProgram lowProgram;
	immutable Ptr!FilesInfo filesInfo;
}

immutable(Result!(ProgramsAndFilesInfo, Diagnostics)) buildToLowProgram(Alloc, PathAlloc, SymAlloc, ReadOnlyStorage)(
	ref Alloc alloc,
	ref AllPaths!PathAlloc allPaths,
	ref AllSymbols!SymAlloc allSymbols,
	ref ReadOnlyStorage storage,
	immutable Path mainPath,
) {
	immutable Result!(Ptr!Program, Diagnostics) programResult =
		frontendCompile(alloc, alloc, allPaths, allSymbols, storage, mainPath);
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
	immutable Path path,
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
