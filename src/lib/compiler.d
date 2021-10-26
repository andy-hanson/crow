module lib.compiler;

@safe @nogc nothrow: // not pure

import backend.writeToC : writeToC;
import concretize.concretize : concretize;
import document.document : document;
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
import util.alloc.alloc : Alloc;
import util.collection.arr : begin, empty, emptyArr, size;
import util.opt : force, none, Opt, some;
import util.path : AbsolutePath, AllPaths, PathAndStorageKind;
import util.ptr : ptrTrustMe_mut;
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

immutable(DiagsAndResultStrs) print(ReadOnlyStorage)(
	ref Alloc alloc,
	ref AllPaths allPaths,
	ref ReadOnlyStorage storage,
	ref immutable ShowDiagOptions showDiagOptions,
	immutable PrintKind kind,
	immutable PrintFormat format,
	immutable PathAndStorageKind main,
) {
	AllSymbols allSymbols = AllSymbols(ptrTrustMe_mut(alloc));
	final switch (kind) {
		case PrintKind.tokens:
			return printTokens(alloc, allPaths, allSymbols, storage, showDiagOptions, main, format);
		case PrintKind.ast:
			return printAst(alloc, allPaths, allSymbols, storage, showDiagOptions, main, format);
		case PrintKind.model:
			return printModel(alloc, allPaths, allSymbols, storage, showDiagOptions, main, format);
		case PrintKind.concreteModel:
			return printConcreteModel(alloc, allPaths, allSymbols, storage, showDiagOptions, main, format);
		case PrintKind.lowModel:
			return printLowModel(alloc, allPaths, allSymbols, storage, showDiagOptions, main, format);
	}
}

struct ExitCode {
	@safe @nogc pure nothrow:
	immutable int value;

	static immutable(ExitCode) ok() { return immutable ExitCode(0); }
	static immutable(ExitCode) error() { return immutable ExitCode(1); }
}

immutable(ExitCode) buildAndInterpret(Debug, ReadOnlyStorage, Extern)(
	ref Debug dbg,
	ref Alloc alloc,
	ref AllPaths allPaths,
	ref AllSymbols allSymbols,
	ref ReadOnlyStorage storage,
	ref Extern extern_,
	ref immutable ShowDiagOptions showDiagOptions,
	immutable PathAndStorageKind main,
	immutable string[] programArgs,
) {
	immutable ProgramsAndFilesInfo programs = buildToLowProgram(alloc, allPaths, allSymbols, storage, main);
	if (empty(programs.program.diagnostics)) {
		immutable LowProgram lowProgram = force(programs.concreteAndLowProgram).lowProgram;
		immutable ByteCode byteCode = generateBytecode(dbg, alloc, alloc, programs.program, lowProgram);
		immutable AbsolutePath mainAbsolutePath = getAbsolutePathFromStorage(storage, main, crowExtension);
		return immutable ExitCode(runBytecode(
			dbg,
			alloc,
			allPaths,
			extern_,
			lowProgram,
			byteCode,
			programs.program.filesInfo,
			mainAbsolutePath,
			programArgs));
	} else {
		writeDiagsToExtern(
			alloc,
			allPaths,
			extern_,
			showDiagOptions,
			programs.program.filesInfo,
			programs.program.diagnostics);
		return ExitCode.error;
	}
}

private:

@trusted void writeDiagsToExtern(Extern)(
	ref Alloc alloc,
	ref const AllPaths allPaths,
	ref Extern extern_,
	ref immutable ShowDiagOptions showDiagOptions,
	ref immutable FilesInfo filesInfo,
	ref immutable Diags diagnostics,
) {
	immutable int stderr = 2;
	immutable string s = strOfDiagnostics(alloc, allPaths, showDiagOptions, filesInfo, diagnostics);
	extern_.write(stderr, begin(s), size(s));
}

immutable(DiagsAndResultStrs) printTokens(ReadOnlyStorage)(
	ref Alloc alloc,
	ref AllPaths allPaths,
	ref AllSymbols allSymbols,
	ref ReadOnlyStorage storage,
	ref immutable ShowDiagOptions showDiagOptions,
	immutable PathAndStorageKind main,
	immutable PrintFormat format,
) {
	immutable FileAstAndDiagnostics astResult = parseSingleAst(alloc, allPaths, allSymbols, storage, main);
	immutable Token[] tokens = tokensOfAst(alloc, astResult.ast);
	return immutable DiagsAndResultStrs(
		strOfDiagnostics(alloc, allPaths, showDiagOptions, astResult.filesInfo, astResult.diagnostics),
		showRepr(alloc, reprTokens(alloc, tokens), format));
}

immutable(DiagsAndResultStrs) printAst(ReadOnlyStorage)(
	ref Alloc alloc,
	ref AllPaths allPaths,
	ref AllSymbols allSymbols,
	ref ReadOnlyStorage storage,
	ref immutable ShowDiagOptions showDiagOptions,
	immutable PathAndStorageKind main,
	immutable PrintFormat format,
) {
	immutable FileAstAndDiagnostics astResult = parseSingleAst(alloc, allPaths, allSymbols, storage, main);
	return immutable DiagsAndResultStrs(
		strOfDiagnostics(alloc, allPaths, showDiagOptions, astResult.filesInfo, astResult.diagnostics),
		showAst(alloc, allPaths, astResult.ast, format));
}

immutable(DiagsAndResultStrs) printModel(ReadOnlyStorage)(
	ref Alloc alloc,
	ref AllPaths allPaths,
	ref AllSymbols allSymbols,
	ref ReadOnlyStorage storage,
	ref immutable ShowDiagOptions showDiagOptions,
	immutable PathAndStorageKind main,
	immutable PrintFormat format,
) {
	immutable Program program = frontendCompile(alloc, alloc, allPaths, allSymbols, storage, main);
	return empty(program.diagnostics)
		? immutable DiagsAndResultStrs("", showModule(alloc, program.specialModules.mainModule.deref(), format))
		: immutable DiagsAndResultStrs(
			strOfDiagnostics(alloc, allPaths, showDiagOptions, program.filesInfo, program.diagnostics),
			"");
}

immutable(DiagsAndResultStrs) printConcreteModel(ReadOnlyStorage)(
	ref Alloc alloc,
	ref AllPaths allPaths,
	ref AllSymbols allSymbols,
	ref ReadOnlyStorage storage,
	ref immutable ShowDiagOptions showDiagOptions,
	immutable PathAndStorageKind main,
	immutable PrintFormat format,
) {
	immutable Program program = frontendCompile(alloc, alloc, allPaths, allSymbols, storage, main);
	if (empty(program.diagnostics)) {
		immutable ConcreteProgram concreteProgram = concretize(alloc, allSymbols, program);
		return immutable DiagsAndResultStrs("", showConcreteProgram(alloc, concreteProgram, format));
	} else
		return immutable DiagsAndResultStrs(
			strOfDiagnostics(alloc, allPaths, showDiagOptions, program.filesInfo, program.diagnostics),
			"");
}

immutable(DiagsAndResultStrs) printLowModel(ReadOnlyStorage)(
	ref Alloc alloc,
	ref AllPaths allPaths,
	ref AllSymbols allSymbols,
	ref ReadOnlyStorage storage,
	ref immutable ShowDiagOptions showDiagOptions,
	immutable PathAndStorageKind main,
	immutable PrintFormat format,
) {
	immutable Program program = frontendCompile(alloc, alloc, allPaths, allSymbols, storage, main);
	if (empty(program.diagnostics)) {
		immutable ConcreteProgram concreteProgram = concretize(alloc, allSymbols, program);
		immutable LowProgram lowProgram = lower(alloc, concreteProgram);
		return immutable DiagsAndResultStrs("", showLowProgram(alloc, lowProgram, format));
	} else
		return immutable DiagsAndResultStrs(
			strOfDiagnostics(alloc, allPaths, showDiagOptions, program.filesInfo, program.diagnostics),
			"");
}

//TODO:INLINE
immutable(string) showAst(
	ref Alloc alloc,
	ref const AllPaths allPaths,
	ref immutable FileAst ast,
	immutable PrintFormat format,
) {
	return showRepr(alloc, reprAst(alloc, allPaths, ast), format);
}

//TODO:INLINE
immutable(string) showModule(ref Alloc alloc, ref immutable Module a, immutable PrintFormat format) {
	return showRepr(alloc, reprModule(alloc, a), format);
}

//TODO:INLINE
immutable(string) showConcreteProgram(
	ref Alloc alloc,
	ref immutable ConcreteProgram a,
	immutable PrintFormat format,
) {
	return showRepr(alloc, reprOfConcreteProgram(alloc, a), format);
}

//TODO:INLINE
immutable(string) showLowProgram(ref Alloc alloc, ref immutable LowProgram a, immutable PrintFormat format) {
	return showRepr(alloc, reprOfLowProgram(alloc, a), format);
}

public struct BuildToCResult {
	immutable string cSource;
	immutable string diagnostics;
	immutable string[] allExternLibraryNames;
}

public immutable(BuildToCResult) buildToC(ReadOnlyStorage)(
	ref Alloc alloc,
	ref AllPaths allPaths,
	ref ReadOnlyStorage storage,
	ref immutable ShowDiagOptions showDiagOptions,
	immutable PathAndStorageKind main,
) {
	AllSymbols allSymbols = AllSymbols(ptrTrustMe_mut(alloc));
	immutable ProgramsAndFilesInfo programs = buildToLowProgram(alloc, allPaths, allSymbols, storage, main);
	return empty(programs.program.diagnostics)
		? immutable BuildToCResult(
			writeToC(alloc, alloc, force(programs.concreteAndLowProgram).lowProgram),
			"",
			force(programs.concreteAndLowProgram).concreteProgram.allExternLibraryNames)
		: immutable BuildToCResult(
			"",
			strOfDiagnostics(
				alloc,
				allPaths,
				showDiagOptions,
				programs.program.filesInfo,
				programs.program.diagnostics),
			emptyArr!string);
}

public struct DocumentResult {
	immutable string document;
	immutable string diagnostics;
}

public immutable(DocumentResult) compileAndDocument(ReadOnlyStorage)(
	ref Alloc alloc,
	ref AllPaths allPaths,
	ref ReadOnlyStorage storage,
	ref immutable ShowDiagOptions showDiagOptions,
	immutable PathAndStorageKind main,
) {
	AllSymbols allSymbols = AllSymbols(ptrTrustMe_mut(alloc));
	immutable Program program = frontendCompile(alloc, alloc, allPaths, allSymbols, storage, main);
	return empty(program.diagnostics)
		? immutable DocumentResult(document(alloc, allPaths, program, program.specialModules.mainModule.deref()), "")
		: immutable DocumentResult(
			"",
			strOfDiagnostics(alloc, allPaths, showDiagOptions, program.filesInfo, program.diagnostics));
}

struct ConcreteAndLowProgram {
	immutable ConcreteProgram concreteProgram;
	immutable LowProgram lowProgram;
}

//TODO:RENAME
struct ProgramsAndFilesInfo {
	immutable Program program;
	immutable Opt!ConcreteAndLowProgram concreteAndLowProgram;
}

immutable(ProgramsAndFilesInfo) buildToLowProgram(ReadOnlyStorage)(
	ref Alloc alloc,
	ref AllPaths allPaths,
	ref AllSymbols allSymbols,
	ref ReadOnlyStorage storage,
	immutable PathAndStorageKind main,
) {
	immutable Program program = frontendCompile(alloc, alloc, allPaths, allSymbols, storage, main);
	if (empty(program.diagnostics)) {
		immutable ConcreteProgram concreteProgram = concretize(alloc, allSymbols, program);
		return immutable ProgramsAndFilesInfo(
			program,
			some(immutable ConcreteAndLowProgram(concreteProgram, lower(alloc, concreteProgram))));
	} else
		return immutable ProgramsAndFilesInfo(program, none!ConcreteAndLowProgram);
}

immutable(AbsolutePath) getAbsolutePathFromStorage(Storage)(
	ref Storage storage,
	immutable PathAndStorageKind path,
	immutable string extension,
) {
	immutable AbsolutePathsGetter abs = storage.absolutePathsGetter();
	return getAbsolutePath(abs, path, extension);
}

immutable(string) showRepr(ref Alloc alloc, immutable Repr a, immutable PrintFormat format) {
	Writer writer = Writer(ptrTrustMe_mut(alloc));
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
