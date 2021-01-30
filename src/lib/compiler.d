module lib.compiler;

@safe @nogc nothrow: // not pure

import backend.writeToC : writeToC;
import concretize.concretize : concretize;
import frontend.parse.ast : FileAst, reprAst;
import frontend.frontendCompile : FileAstAndDiagnostics, frontendCompile, parseSingleAst;
import frontend.ide.getTokens : Token, tokensOfAst, reprTokens;
import frontend.lang : crowExtension;
import frontend.showDiag : ShowDiagOptions, strOfDiagnostics;
import interpret.bytecode : ByteCode;
import interpret.generateBytecode : generateBytecode;
import interpret.runBytecode : runBytecode;
import lower.lower : lower;
import model.concreteModel : ConcreteProgram;
import model.diag : Diags, FilesInfo;
import model.lowModel : LowProgram;
import model.model : AbsolutePathsGetter, getAbsolutePath, Module, Program;
import model.reprConcreteModel : reprOfConcreteProgram;
import model.reprLowModel : reprOfLowProgram;
import model.reprModel : reprModule;
import util.collection.arr : begin, empty, emptyArr, size;
import util.collection.str : emptyStr;
import util.opt : force, none, Opt, some;
import util.path : AbsolutePath, AllPaths, Path, PathAndStorageKind, StorageKind;
import util.ptr : Ptr, ptrTrustMe_mut;
import util.repr : Repr, writeRepr, writeReprJSON;
import util.sym : AllSymbols;
import util.writer : finishWriter, Writer;

enum PrintFormat {
	repr,
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
	immutable string diagnostics;
	immutable string result;
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
	ref immutable string[] programArgs,
) {
	immutable ProgramsAndFilesInfo programs =
		buildToLowProgram(alloc, allPaths, allSymbols, storage, mainPath);
	if (empty(programs.program.diagnostics)) {
		immutable Ptr!LowProgram lowProgram = force(programs.concreteAndLowProgram).lowProgram;
		immutable ByteCode byteCode = generateBytecode(dbg, alloc, alloc, programs.program, lowProgram);
		immutable AbsolutePath mainAbsolutePath =
			getAbsolutePathFromStorage(alloc, storage, mainPath, crowExtension);
		return runBytecode(
			dbg,
			alloc,
			allPaths,
			extern_,
			lowProgram,
			byteCode,
			programs.program.filesInfo,
			mainAbsolutePath,
			programArgs);
	} else {
		writeDiagsToExtern(
			alloc,
			allPaths,
			extern_,
			showDiagOptions,
			programs.program.filesInfo,
			programs.program.diagnostics);
		return 1;
	}
}

private:

@trusted void writeDiagsToExtern(Alloc, PathAlloc, Extern)(
	ref Alloc alloc,
	ref const AllPaths!PathAlloc allPaths,
	ref Extern extern_,
	ref immutable ShowDiagOptions showDiagOptions,
	ref immutable FilesInfo filesInfo,
	ref immutable Diags diagnostics,
) {
	immutable int stderr = 2;
	immutable string s = strOfDiagnostics(alloc, allPaths, showDiagOptions, filesInfo, diagnostics);
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
	immutable Token[] tokens = tokensOfAst(alloc, astResult.ast);
	return immutable DiagsAndResultStrs(
		strOfDiagnostics(alloc, allPaths, showDiagOptions, astResult.filesInfo, astResult.diagnostics),
		showRepr(alloc, reprTokens(alloc, tokens), format));
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
		strOfDiagnostics(alloc, allPaths, showDiagOptions, astResult.filesInfo, astResult.diagnostics),
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
	immutable Ptr!Program program = frontendCompile(alloc, alloc, allPaths, allSymbols, storage, mainPath);
	return empty(program.diagnostics)
		? immutable DiagsAndResultStrs(emptyStr, showModule(alloc, program.specialModules.mainModule, format))
		: immutable DiagsAndResultStrs(
			strOfDiagnostics(alloc, allPaths, showDiagOptions, program.filesInfo, program.diagnostics),
			emptyStr);
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
	immutable Ptr!Program program = frontendCompile(alloc, alloc, allPaths, allSymbols, storage, mainPath);
	if (empty(program.diagnostics)) {
		immutable ConcreteProgram concreteProgram = concretize(alloc, allSymbols, program);
		return immutable DiagsAndResultStrs(emptyStr, showConcreteProgram(alloc, concreteProgram, format));
	} else
		return immutable DiagsAndResultStrs(
			strOfDiagnostics(alloc, allPaths, showDiagOptions, program.filesInfo, program.diagnostics),
			emptyStr);
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
	immutable Ptr!Program program = frontendCompile(alloc, alloc, allPaths, allSymbols, storage, mainPath);
	if (empty(program.diagnostics)) {
		immutable ConcreteProgram concreteProgram = concretize(alloc, allSymbols, program);
		immutable Ptr!LowProgram lowProgram = lower(alloc, concreteProgram);
		return immutable DiagsAndResultStrs(emptyStr, showLowProgram(alloc, lowProgram, format));
	} else
		return immutable DiagsAndResultStrs(
			strOfDiagnostics(alloc, allPaths, showDiagOptions, program.filesInfo, program.diagnostics),
			emptyStr);
}

//TODO:INLINE
immutable(string) showAst(Alloc, PathAlloc)(
	ref Alloc alloc,
	ref const AllPaths!PathAlloc allPaths,
	ref immutable FileAst ast,
	immutable PrintFormat format,
) {
	return showRepr(alloc, reprAst(alloc, allPaths, ast), format);
}

//TODO:INLINE
immutable(string) showModule(Alloc)(ref Alloc alloc, ref immutable Module a, immutable PrintFormat format) {
	return showRepr(alloc, reprModule(alloc, a), format);
}

//TODO:INLINE
immutable(string) showConcreteProgram(Alloc)(
	ref Alloc alloc,
	ref immutable ConcreteProgram a,
	immutable PrintFormat format,
) {
	return showRepr(alloc, reprOfConcreteProgram(alloc, a), format);
}

//TODO:INLINE
immutable(string) showLowProgram(Alloc)(ref Alloc alloc, ref immutable LowProgram a, immutable PrintFormat format) {
	return showRepr(alloc, reprOfLowProgram(alloc, a), format);
}

public struct BuildToCResult {
	immutable string cSource;
	immutable string diagnostics;
	immutable string[] allExternLibraryNames;
}

public immutable(BuildToCResult) buildToC(Alloc, PathAlloc, SymAlloc, ReadOnlyStorage)(
	ref Alloc alloc,
	ref AllPaths!PathAlloc allPaths,
	ref AllSymbols!SymAlloc allSymbols,
	ref ReadOnlyStorage storage,
	ref immutable ShowDiagOptions showDiagOptions,
	immutable Path mainPath,
) {
	immutable ProgramsAndFilesInfo programs =
		buildToLowProgram(alloc, allPaths, allSymbols, storage, mainPath);
	return empty(programs.program.diagnostics)
		? immutable BuildToCResult(
			writeToC(alloc, alloc, force(programs.concreteAndLowProgram).lowProgram),
			emptyStr,
			force(programs.concreteAndLowProgram).concreteProgram.allExternLibraryNames)
		: immutable BuildToCResult(
			emptyStr,
			strOfDiagnostics(
				alloc,
				allPaths,
				showDiagOptions,
				programs.program.filesInfo,
				programs.program.diagnostics),
			emptyArr!string);
}

struct ConcreteAndLowProgram {
	immutable Ptr!ConcreteProgram concreteProgram;
	immutable Ptr!LowProgram lowProgram;
}

//TODO:RENAME
struct ProgramsAndFilesInfo {
	immutable Ptr!Program program;
	immutable Opt!(ConcreteAndLowProgram) concreteAndLowProgram;
}

immutable(ProgramsAndFilesInfo) buildToLowProgram(Alloc, PathAlloc, SymAlloc, ReadOnlyStorage)(
	ref Alloc alloc,
	ref AllPaths!PathAlloc allPaths,
	ref AllSymbols!SymAlloc allSymbols,
	ref ReadOnlyStorage storage,
	immutable Path mainPath,
) {
	immutable Ptr!Program program =
		frontendCompile(alloc, alloc, allPaths, allSymbols, storage, mainPath);
	if (empty(program.diagnostics)) {
		immutable Ptr!ConcreteProgram concreteProgram = concretize(alloc, allSymbols, program);
		return immutable ProgramsAndFilesInfo(
			program,
			some(immutable ConcreteAndLowProgram(concreteProgram, lower(alloc, concreteProgram))));
	} else
		return immutable ProgramsAndFilesInfo(program, none!ConcreteAndLowProgram);
}

public immutable(AbsolutePath) getAbsolutePathFromStorage(Alloc, Storage)(
	ref Alloc alloc,
	ref Storage storage,
	immutable Path path,
	immutable string extension,
) {
	immutable AbsolutePathsGetter abs = storage.absolutePathsGetter();
	immutable PathAndStorageKind pk = immutable PathAndStorageKind(path, StorageKind.local);
	return getAbsolutePath(alloc, abs, pk, extension);
}

immutable(string) showRepr(Alloc)(ref Alloc alloc, immutable Repr a, immutable PrintFormat format) {
	Writer!Alloc writer = Writer!Alloc(ptrTrustMe_mut(alloc));
	final switch (format) {
		case PrintFormat.repr:
			writeRepr(writer, a);
			break;
		case PrintFormat.json:
			writeReprJSON(writer, a);
			break;
	}
	return finishWriter(writer);
}
