module lib.compiler;

@safe @nogc nothrow: // not pure

import backend.writeToC : writeToC;
import concretize.concretize : concretize;
import document.document : document;
import frontend.parse.ast : FileAst, reprAst;
import frontend.frontendCompile : FileAstAndDiagnostics, frontendCompile, parseSingleAst;
import frontend.ide.getTokens : Token, tokensOfAst, reprTokens;
import frontend.showDiag : ShowDiagOptions, strOfDiagnostics;
import interpret.bytecode : ByteCode;
import interpret.extern_ : Extern;
import interpret.generateBytecode : generateBytecode;
import interpret.runBytecode : runBytecode;
import lower.lower : lower;
import model.concreteModel : ConcreteProgram;
import model.diag : Diagnostics, FilesInfo;
import model.lowModel : LowProgram;
import model.model : hasDiags, Module, Program;
import model.reprConcreteModel : reprOfConcreteProgram;
import model.reprLowModel : reprOfLowProgram;
import model.reprModel : reprModule;
import util.alloc.alloc : Alloc;
import util.collection.arr : emptyArr;
import util.collection.str : SafeCStr;
import util.dbg : Debug;
import util.opt : force, none, Opt, some;
import util.path : AllPaths, PathAndStorageKind;
import util.perf : Perf;
import util.ptr : ptrTrustMe_mut;
import util.repr : Repr, writeRepr, writeReprJSON;
import util.sym : AllSymbols, Sym;
import util.util : castImmutableRef;
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
	ref Perf perf,
	ref AllSymbols allSymbols,
	ref AllPaths allPaths,
	ref ReadOnlyStorage storage,
	ref immutable ShowDiagOptions showDiagOptions,
	immutable PrintKind kind,
	immutable PrintFormat format,
	immutable PathAndStorageKind main,
) {
	final switch (kind) {
		case PrintKind.tokens:
			return printTokens(alloc, perf, allSymbols, allPaths, storage, showDiagOptions, main, format);
		case PrintKind.ast:
			return printAst(alloc, perf, allSymbols, allPaths, storage, showDiagOptions, main, format);
		case PrintKind.model:
			return printModel(alloc, perf, allSymbols, allPaths, storage, showDiagOptions, main, format);
		case PrintKind.concreteModel:
			return printConcreteModel(alloc, perf, allSymbols, allPaths, storage, showDiagOptions, main, format);
		case PrintKind.lowModel:
			return printLowModel(alloc, perf, allSymbols, allPaths, storage, showDiagOptions, main, format);
	}
}

struct ExitCode {
	@safe @nogc pure nothrow:
	immutable int value;

	static immutable(ExitCode) ok() { return immutable ExitCode(0); }
	static immutable(ExitCode) error() { return immutable ExitCode(1); }
}

immutable(ExitCode) buildAndInterpret(ReadOnlyStorage)(
	ref Alloc alloc,
	scope ref Debug dbg,
	ref Perf perf,
	ref AllSymbols allSymbols,
	ref AllPaths allPaths,
	ref ReadOnlyStorage storage,
	scope ref Extern extern_,
	ref immutable ShowDiagOptions showDiagOptions,
	immutable PathAndStorageKind main,
	scope immutable SafeCStr[] allArgs,
) {
	immutable ProgramsAndFilesInfo programs = buildToLowProgram(alloc, perf, allSymbols, allPaths, storage, main);
	if (!hasDiags(programs.program)) {
		immutable LowProgram lowProgram = force(programs.concreteAndLowProgram).lowProgram;
		immutable ByteCode byteCode = generateBytecode(dbg, alloc, alloc, allSymbols, programs.program, lowProgram);
		return immutable ExitCode(runBytecode(
			dbg,
			perf,
			alloc,
			allSymbols,
			allPaths,
			extern_,
			lowProgram,
			byteCode,
			programs.program.filesInfo,
			allArgs));
	} else {
		writeDiagsToExtern(
			alloc,
			allSymbols,
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
	ref const AllSymbols allSymbols,
	ref const AllPaths allPaths,
	ref Extern extern_,
	ref immutable ShowDiagOptions showDiagOptions,
	ref immutable FilesInfo filesInfo,
	ref immutable Diagnostics diagnostics,
) {
	immutable int stderr = 2;
	immutable string s = strOfDiagnostics(alloc, allSymbols, allPaths, showDiagOptions, filesInfo, diagnostics);
	extern_.write(stderr, s.ptr, s.length);
}

immutable(DiagsAndResultStrs) printTokens(ReadOnlyStorage)(
	ref Alloc alloc,
	ref Perf perf,
	ref AllSymbols allSymbols,
	ref AllPaths allPaths,
	ref ReadOnlyStorage storage,
	ref immutable ShowDiagOptions showDiagOptions,
	immutable PathAndStorageKind main,
	immutable PrintFormat format,
) {
	immutable FileAstAndDiagnostics astResult = parseSingleAst(alloc, perf, allSymbols, allPaths, storage, main);
	immutable Token[] tokens = tokensOfAst(alloc, allSymbols, astResult.ast);
	return immutable DiagsAndResultStrs(
		strOfDiagnostics(alloc, allSymbols, allPaths, showDiagOptions, astResult.filesInfo, astResult.diagnostics),
		showRepr(alloc, allSymbols, reprTokens(alloc, tokens), format));
}

immutable(DiagsAndResultStrs) printAst(ReadOnlyStorage)(
	ref Alloc alloc,
	ref Perf perf,
	ref AllSymbols allSymbols,
	ref AllPaths allPaths,
	ref ReadOnlyStorage storage,
	ref immutable ShowDiagOptions showDiagOptions,
	immutable PathAndStorageKind main,
	immutable PrintFormat format,
) {
	immutable FileAstAndDiagnostics astResult = parseSingleAst(alloc, perf, allSymbols, allPaths, storage, main);
	return immutable DiagsAndResultStrs(
		strOfDiagnostics(alloc, allSymbols, allPaths, showDiagOptions, astResult.filesInfo, astResult.diagnostics),
		showAst(alloc, allSymbols, allPaths, astResult.ast, format));
}

immutable(DiagsAndResultStrs) printModel(ReadOnlyStorage)(
	ref Alloc alloc,
	ref Perf perf,
	ref AllSymbols allSymbols,
	ref AllPaths allPaths,
	ref ReadOnlyStorage storage,
	ref immutable ShowDiagOptions showDiagOptions,
	immutable PathAndStorageKind main,
	immutable PrintFormat format,
) {
	immutable Program program = frontendCompile(alloc, perf, alloc, allPaths, allSymbols, storage, main);
	return !hasDiags(program)
		? immutable DiagsAndResultStrs(
			"",
			showModule(alloc, allSymbols, program.specialModules.mainModule.deref(), format))
		: immutable DiagsAndResultStrs(
			strOfDiagnostics(alloc, allSymbols, allPaths, showDiagOptions, program.filesInfo, program.diagnostics),
			"");
}

immutable(DiagsAndResultStrs) printConcreteModel(ReadOnlyStorage)(
	ref Alloc alloc,
	ref Perf perf,
	ref AllSymbols allSymbols,
	ref AllPaths allPaths,
	ref ReadOnlyStorage storage,
	ref immutable ShowDiagOptions showDiagOptions,
	immutable PathAndStorageKind main,
	immutable PrintFormat format,
) {
	immutable Program program = frontendCompile(alloc, perf, alloc, allPaths, allSymbols, storage, main);
	if (!hasDiags(program)) {
		immutable ConcreteProgram concreteProgram = concretize(alloc, perf, allSymbols, program);
		return immutable DiagsAndResultStrs("", showConcreteProgram(alloc, allSymbols, concreteProgram, format));
	} else
		return immutable DiagsAndResultStrs(
			strOfDiagnostics(alloc, allSymbols, allPaths, showDiagOptions, program.filesInfo, program.diagnostics),
			"");
}

immutable(DiagsAndResultStrs) printLowModel(ReadOnlyStorage)(
	ref Alloc alloc,
	ref Perf perf,
	ref AllSymbols allSymbols,
	ref AllPaths allPaths,
	ref ReadOnlyStorage storage,
	ref immutable ShowDiagOptions showDiagOptions,
	immutable PathAndStorageKind main,
	immutable PrintFormat format,
) {
	immutable Program program = frontendCompile(alloc, perf, alloc, allPaths, allSymbols, storage, main);
	if (!hasDiags(program)) {
		immutable ConcreteProgram concreteProgram = concretize(alloc, perf, allSymbols, program);
		immutable LowProgram lowProgram = lower(alloc, perf, concreteProgram);
		return immutable DiagsAndResultStrs("", showLowProgram(alloc, allSymbols, lowProgram, format));
	} else
		return immutable DiagsAndResultStrs(
			strOfDiagnostics(alloc, allSymbols, allPaths, showDiagOptions, program.filesInfo, program.diagnostics),
			"");
}

//TODO:INLINE
immutable(string) showAst(
	ref Alloc alloc,
	ref const AllSymbols allSymbols,
	ref const AllPaths allPaths,
	ref immutable FileAst ast,
	immutable PrintFormat format,
) {
	return showRepr(alloc, allSymbols, reprAst(alloc, allPaths, ast), format);
}

//TODO:INLINE
immutable(string) showModule(
	ref Alloc alloc,
	ref const AllSymbols allSymbols,
	ref immutable Module a,
	immutable PrintFormat format,
) {
	return showRepr(alloc, allSymbols, reprModule(alloc, a), format);
}

//TODO:INLINE
immutable(string) showConcreteProgram(
	ref Alloc alloc,
	ref const AllSymbols allSymbols,
	ref immutable ConcreteProgram a,
	immutable PrintFormat format,
) {
	return showRepr(alloc, allSymbols, reprOfConcreteProgram(alloc, a), format);
}

//TODO:INLINE
immutable(string) showLowProgram(
	ref Alloc alloc,
	ref const AllSymbols allSymbols,
	ref immutable LowProgram a,
	immutable PrintFormat format,
) {
	return showRepr(alloc, allSymbols, reprOfLowProgram(alloc, a), format);
}

public immutable(ExitCode) justTypeCheck(ReadOnlyStorage)(
	ref Alloc alloc,
	ref Perf perf,
	ref AllSymbols allSymbols,
	ref AllPaths allPaths,
	ref ReadOnlyStorage storage,
	immutable PathAndStorageKind main,
) {
	immutable Program program = frontendCompile(alloc, perf, alloc, allPaths, allSymbols, storage, main);
	return !hasDiags(program) ? immutable ExitCode(0) : immutable ExitCode(1);
}

public struct BuildToCResult {
	immutable string cSource;
	immutable string diagnostics;
	immutable Sym[] allExternLibraryNames;
}

public immutable(BuildToCResult) buildToC(ReadOnlyStorage)(
	ref Alloc alloc,
	ref Perf perf,
	ref AllSymbols allSymbols,
	ref AllPaths allPaths,
	ref ReadOnlyStorage storage,
	ref immutable ShowDiagOptions showDiagOptions,
	immutable PathAndStorageKind main,
) {
	immutable ProgramsAndFilesInfo programs = buildToLowProgram(alloc, perf, allSymbols, allPaths, storage, main);
	return !hasDiags(programs.program)
		? immutable BuildToCResult(
			writeToC(alloc, alloc, castImmutableRef(allSymbols), force(programs.concreteAndLowProgram).lowProgram),
			"",
			force(programs.concreteAndLowProgram).concreteProgram.allExternLibraryNames)
		: immutable BuildToCResult(
			"",
			strOfDiagnostics(
				alloc,
				allSymbols,
				allPaths,
				showDiagOptions,
				programs.program.filesInfo,
				programs.program.diagnostics),
			emptyArr!Sym);
}

public struct DocumentResult {
	immutable string document;
	immutable string diagnostics;
}

public immutable(DocumentResult) compileAndDocument(ReadOnlyStorage)(
	ref Alloc alloc,
	ref Perf perf,
	ref AllSymbols allSymbols,
	ref AllPaths allPaths,
	ref ReadOnlyStorage storage,
	ref immutable ShowDiagOptions showDiagOptions,
	immutable PathAndStorageKind main,
) {
	immutable Program program = frontendCompile(alloc, perf, alloc, allPaths, allSymbols, storage, main);
	return !hasDiags(program)
		? immutable DocumentResult(
			document(alloc, allSymbols, allPaths, program, program.specialModules.mainModule.deref()), "")
		: immutable DocumentResult(
			"",
			strOfDiagnostics(alloc, allSymbols, allPaths, showDiagOptions, program.filesInfo, program.diagnostics));
}

struct ConcreteAndLowProgram {
	immutable ConcreteProgram concreteProgram;
	immutable LowProgram lowProgram;
}

//TODO:RENAME
public struct ProgramsAndFilesInfo {
	@safe @nogc pure nothrow:

	immutable Program program;
	immutable Opt!ConcreteAndLowProgram concreteAndLowProgram;

	ref immutable(LowProgram) lowProgram() return scope const {
		return force(concreteAndLowProgram).lowProgram;
	}
}

public immutable(ProgramsAndFilesInfo) buildToLowProgram(ReadOnlyStorage)(
	ref Alloc alloc,
	ref Perf perf,
	ref AllSymbols allSymbols,
	ref AllPaths allPaths,
	ref ReadOnlyStorage storage,
	immutable PathAndStorageKind main,
) {
	immutable Program program = frontendCompile(alloc, perf, alloc, allPaths, allSymbols, storage, main);
	if (!hasDiags(program)) {
		immutable ConcreteProgram concreteProgram = concretize(alloc, perf, allSymbols, program);
		return immutable ProgramsAndFilesInfo(
			program,
			some(immutable ConcreteAndLowProgram(concreteProgram, lower(alloc, perf, concreteProgram))));
	} else
		return immutable ProgramsAndFilesInfo(program, none!ConcreteAndLowProgram);
}

immutable(string) showRepr(
	ref Alloc alloc,
	ref const AllSymbols allSymbols,
	immutable Repr a,
	immutable PrintFormat format,
) {
	Writer writer = Writer(ptrTrustMe_mut(alloc));
	final switch (format) {
		case PrintFormat.repr:
			writeRepr(writer, allSymbols, a);
			break;
		case PrintFormat.json:
			writeReprJSON(writer, allSymbols, a);
			break;
	}
	return finishWriter(writer);
}
