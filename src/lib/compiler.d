module lib.compiler;

@safe @nogc nothrow: // not pure

import backend.writeToC : writeToC;
import concretize.concretize : concretize;
import document.document : documentJSON;
import frontend.parse.ast : FileAst, reprAst;
import frontend.frontendCompile : FileAstAndDiagnostics, frontendCompile, parseSingleAst;
import frontend.ide.getTokens : Token, tokensOfAst, reprTokens;
import frontend.showDiag : ShowDiagOptions, strOfDiagnostics;
import interpret.bytecode : ByteCode;
import interpret.extern_ : Extern, ExternFunPtrsForAllLibraries, WriteError;
import interpret.generateBytecode : generateBytecode;
import interpret.runBytecode : runBytecode;
import lower.lower : lower;
import model.concreteModel : ConcreteProgram;
import model.lowModel : ExternLibraries, LowProgram;
import model.model : hasDiags, Module, Program;
import model.reprConcreteModel : reprOfConcreteProgram;
import model.reprLowModel : reprOfLowProgram;
import model.reprModel : reprModule;
import util.alloc.alloc : Alloc;
import util.col.arr : only;
import util.col.str : SafeCStr, safeCStr;
import util.opt : force, has, none, Opt, some;
import util.path : AllPaths, Path, PathsInfo;
import util.perf : Perf;
import util.readOnlyStorage : ReadOnlyStorage;
import util.repr : jsonStrOfRepr;
import util.sym : AllSymbols;
import util.util : castImmutableRef;
import versionInfo : VersionInfo, versionInfoForInterpret;
version (WebAssembly) {} else {
	import versionInfo : versionInfoForBuildToC;
}

enum PrintKind {
	tokens,
	ast,
	model,
	concreteModel,
	lowModel,
}

struct DiagsAndResultStrs {
	immutable SafeCStr diagnostics;
	immutable SafeCStr result;
}

immutable(DiagsAndResultStrs) print(
	ref Alloc alloc,
	ref Perf perf,
	immutable VersionInfo versionInfo,
	ref AllSymbols allSymbols,
	ref AllPaths allPaths,
	ref immutable PathsInfo pathsInfo,
	scope ref const ReadOnlyStorage storage,
	ref immutable ShowDiagOptions showDiagOptions,
	immutable PrintKind kind,
	immutable Path main,
) {
	final switch (kind) {
		case PrintKind.tokens:
			return printTokens(alloc, perf, allSymbols, allPaths, pathsInfo, storage, showDiagOptions, main);
		case PrintKind.ast:
			return printAst(alloc, perf, allSymbols, allPaths, pathsInfo, storage, showDiagOptions, main);
		case PrintKind.model:
			return printModel(alloc, perf, allSymbols, allPaths, pathsInfo, storage, showDiagOptions, main);
		case PrintKind.concreteModel:
			return printConcreteModel(
				alloc, perf, versionInfo, allSymbols, allPaths, pathsInfo, storage, showDiagOptions, main);
		case PrintKind.lowModel:
			return printLowModel(
				alloc, perf, versionInfo, allSymbols, allPaths, pathsInfo, storage, showDiagOptions, main);
	}
}

struct ExitCode {
	@safe @nogc pure nothrow:
	immutable int value;

	static immutable(ExitCode) ok() { return immutable ExitCode(0); }
	static immutable(ExitCode) error() { return immutable ExitCode(1); }
}

immutable(ExitCode) buildAndInterpret(
	ref Alloc alloc,
	ref Perf perf,
	ref AllSymbols allSymbols,
	ref AllPaths allPaths,
	ref immutable PathsInfo pathsInfo,
	scope ref const ReadOnlyStorage storage,
	scope ref Extern extern_,
	scope WriteError writeError,
	ref immutable ShowDiagOptions showDiagOptions,
	immutable Path main,
	scope immutable SafeCStr[] allArgs,
) {
	immutable ProgramsAndFilesInfo programs =
		buildToLowProgram(alloc, perf, versionInfoForInterpret(), allSymbols, allPaths, storage, main);
	if (!hasDiags(programs.program)) {
		immutable LowProgram lowProgram = force(programs.concreteAndLowProgram).lowProgram;
		immutable Opt!ExternFunPtrsForAllLibraries externFunPtrs =
			extern_.loadExternFunPtrs(lowProgram.externLibraries, writeError);
		if (has(externFunPtrs)) {
			immutable ByteCode byteCode = generateBytecode(
				alloc, perf, allSymbols,
				programs.program, lowProgram, force(externFunPtrs), extern_.makeSyntheticFunPtrs);
			return immutable ExitCode(runBytecode(
				perf,
				alloc,
				allSymbols,
				allPaths,
				pathsInfo,
				extern_.doDynCall,
				lowProgram,
				byteCode,
				programs.program.filesInfo,
				allArgs));
		} else {
			writeError(safeCStr!"Failed to load external libraries\n");
			return ExitCode.error;
		}
	} else {
		writeError(strOfDiagnostics(
			alloc,
			allSymbols,
			allPaths,
			pathsInfo,
			showDiagOptions,
			programs.program.filesInfo,
			programs.program.diagnostics));
		return ExitCode.error;
	}
}

private:

immutable(DiagsAndResultStrs) printTokens(
	ref Alloc alloc,
	ref Perf perf,
	ref AllSymbols allSymbols,
	ref AllPaths allPaths,
	ref immutable PathsInfo pathsInfo,
	scope ref const ReadOnlyStorage storage,
	ref immutable ShowDiagOptions showDiagOptions,
	immutable Path main,
) {
	immutable FileAstAndDiagnostics astResult = parseSingleAst(alloc, perf, allSymbols, allPaths, storage, main);
	immutable Token[] tokens = tokensOfAst(alloc, allSymbols, astResult.ast);
	return immutable DiagsAndResultStrs(
		strOfDiagnostics(
			alloc, allSymbols, allPaths, pathsInfo, showDiagOptions, astResult.filesInfo, astResult.diagnostics),
		jsonStrOfRepr(alloc, allSymbols, reprTokens(alloc, tokens)));
}

immutable(DiagsAndResultStrs) printAst(
	ref Alloc alloc,
	ref Perf perf,
	ref AllSymbols allSymbols,
	ref AllPaths allPaths,
	ref immutable PathsInfo pathsInfo,
	scope ref const ReadOnlyStorage storage,
	ref immutable ShowDiagOptions showDiagOptions,
	immutable Path main,
) {
	immutable FileAstAndDiagnostics astResult = parseSingleAst(alloc, perf, allSymbols, allPaths, storage, main);
	return immutable DiagsAndResultStrs(
		strOfDiagnostics(
			alloc, allSymbols, allPaths, pathsInfo, showDiagOptions, astResult.filesInfo, astResult.diagnostics),
		showAst(alloc, allSymbols, allPaths, astResult.ast));
}

immutable(DiagsAndResultStrs) printModel(
	ref Alloc alloc,
	ref Perf perf,
	ref AllSymbols allSymbols,
	ref AllPaths allPaths,
	ref immutable PathsInfo pathsInfo,
	scope ref const ReadOnlyStorage storage,
	ref immutable ShowDiagOptions showDiagOptions,
	immutable Path main,
) {
	immutable Program program = frontendCompile(alloc, perf, alloc, allPaths, allSymbols, storage, [main]);
	return !hasDiags(program)
		? immutable DiagsAndResultStrs(
			safeCStr!"",
			showModule(alloc, allSymbols, *only(program.specialModules.rootModules)))
		: immutable DiagsAndResultStrs(
			strOfDiagnostics(
				alloc, allSymbols, allPaths, pathsInfo, showDiagOptions, program.filesInfo, program.diagnostics),
			safeCStr!"");
}

immutable(DiagsAndResultStrs) printConcreteModel(
	ref Alloc alloc,
	ref Perf perf,
	immutable VersionInfo versionInfo,
	ref AllSymbols allSymbols,
	ref AllPaths allPaths,
	ref immutable PathsInfo pathsInfo,
	scope ref const ReadOnlyStorage storage,
	ref immutable ShowDiagOptions showDiagOptions,
	immutable Path main,
) {
	immutable Program program = frontendCompile(alloc, perf, alloc, allPaths, allSymbols, storage, [main]);
	if (!hasDiags(program)) {
		immutable ConcreteProgram concreteProgram = concretize(
			alloc, perf, versionInfo, allSymbols, allPaths, program,
			only(program.specialModules.rootModules));
		return immutable DiagsAndResultStrs(safeCStr!"", showConcreteProgram(alloc, allSymbols, concreteProgram));
	} else
		return immutable DiagsAndResultStrs(
			strOfDiagnostics(
				alloc, allSymbols, allPaths, pathsInfo, showDiagOptions, program.filesInfo, program.diagnostics),
			safeCStr!"");
}

immutable(DiagsAndResultStrs) printLowModel(
	ref Alloc alloc,
	ref Perf perf,
	immutable VersionInfo versionInfo,
	ref AllSymbols allSymbols,
	ref AllPaths allPaths,
	ref immutable PathsInfo pathsInfo,
	scope ref const ReadOnlyStorage storage,
	ref immutable ShowDiagOptions showDiagOptions,
	immutable Path main,
) {
	immutable Program program = frontendCompile(alloc, perf, alloc, allPaths, allSymbols, storage, [main]);
	if (!hasDiags(program)) {
		immutable ConcreteProgram concreteProgram = concretize(
			alloc, perf, versionInfo, allSymbols, allPaths, program,
			only(program.specialModules.rootModules));
		immutable LowProgram lowProgram = lower(alloc, perf, allSymbols, program.config.extern_, concreteProgram);
		return immutable DiagsAndResultStrs(safeCStr!"", showLowProgram(alloc, allSymbols, lowProgram));
	} else
		return immutable DiagsAndResultStrs(
			strOfDiagnostics(
				alloc, allSymbols, allPaths, pathsInfo, showDiagOptions, program.filesInfo, program.diagnostics),
			safeCStr!"");
}

//TODO:INLINE
immutable(SafeCStr) showAst(
	ref Alloc alloc,
	ref const AllSymbols allSymbols,
	ref const AllPaths allPaths,
	ref immutable FileAst ast,
) =>
	jsonStrOfRepr(alloc, allSymbols, reprAst(alloc, allPaths, ast));

//TODO:INLINE
immutable(SafeCStr) showModule(
	ref Alloc alloc,
	ref const AllSymbols allSymbols,
	ref immutable Module a,
) =>
	jsonStrOfRepr(alloc, allSymbols, reprModule(alloc, a));

//TODO:INLINE
immutable(SafeCStr) showConcreteProgram(
	ref Alloc alloc,
	ref const AllSymbols allSymbols,
	ref immutable ConcreteProgram a,
) =>
	jsonStrOfRepr(alloc, allSymbols, reprOfConcreteProgram(alloc, a));

//TODO:INLINE
immutable(SafeCStr) showLowProgram(ref Alloc alloc, ref const AllSymbols allSymbols, ref immutable LowProgram a) =>
	jsonStrOfRepr(alloc, allSymbols, reprOfLowProgram(alloc, a));

public immutable(ExitCode) justTypeCheck(
	ref Alloc alloc,
	ref Perf perf,
	ref AllSymbols allSymbols,
	ref AllPaths allPaths,
	scope ref immutable ReadOnlyStorage storage,
	immutable Path main,
) {
	immutable Program program = frontendCompile(alloc, perf, alloc, allPaths, allSymbols, storage, [main]);
	return !hasDiags(program) ? immutable ExitCode(0) : immutable ExitCode(1);
}

version (WebAssembly) {} else {
	public struct BuildToCResult {
		immutable SafeCStr cSource;
		immutable SafeCStr diagnostics;
		immutable ExternLibraries externLibraries;
	}
	public immutable(BuildToCResult) buildToC(
		ref Alloc alloc,
		ref Perf perf,
		ref AllSymbols allSymbols,
		ref AllPaths allPaths,
		ref immutable PathsInfo pathsInfo,
		scope ref const ReadOnlyStorage storage,
		ref immutable ShowDiagOptions showDiagOptions,
		immutable Path main,
	) {
		immutable ProgramsAndFilesInfo programs =
			buildToLowProgram(alloc, perf, versionInfoForBuildToC(), allSymbols, allPaths, storage, main);
		return !hasDiags(programs.program)
			? immutable BuildToCResult(
				writeToC(alloc, alloc, castImmutableRef(allSymbols), force(programs.concreteAndLowProgram).lowProgram),
				safeCStr!"",
				force(programs.concreteAndLowProgram).lowProgram.externLibraries)
			: immutable BuildToCResult(
				safeCStr!"",
				strOfDiagnostics(
					alloc,
					allSymbols,
					allPaths,
					pathsInfo,
					showDiagOptions,
					programs.program.filesInfo,
					programs.program.diagnostics),
				[]);
	}
}

public struct DocumentResult {
	immutable SafeCStr document;
	immutable SafeCStr diagnostics;
}

public immutable(DocumentResult) compileAndDocument(
	ref Alloc alloc,
	ref Perf perf,
	ref AllSymbols allSymbols,
	ref AllPaths allPaths,
	ref immutable PathsInfo pathsInfo,
	scope ref const ReadOnlyStorage storage,
	ref immutable ShowDiagOptions showDiagOptions,
	scope immutable Path[] rootPaths,
) {
	immutable Program program = frontendCompile(alloc, perf, alloc, allPaths, allSymbols, storage, rootPaths);
	return !hasDiags(program)
		? immutable DocumentResult(
			documentJSON(alloc, allSymbols, allPaths, pathsInfo, program),
			safeCStr!"")
		: immutable DocumentResult(
			safeCStr!"",
			strOfDiagnostics(
				alloc, allSymbols, allPaths, pathsInfo, showDiagOptions, program.filesInfo, program.diagnostics));
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

	ref immutable(LowProgram) lowProgram() scope return const =>
		force(concreteAndLowProgram).lowProgram;
}

public immutable(ProgramsAndFilesInfo) buildToLowProgram(
	ref Alloc alloc,
	ref Perf perf,
	immutable VersionInfo versionInfo,
	ref AllSymbols allSymbols,
	ref AllPaths allPaths,
	scope ref const ReadOnlyStorage storage,
	immutable Path main,
) {
	immutable Program program = frontendCompile(alloc, perf, alloc, allPaths, allSymbols, storage, [main]);
	if (!hasDiags(program)) {
		immutable ConcreteProgram concreteProgram = concretize(
			alloc, perf, versionInfo, allSymbols, allPaths, program,
			only(program.specialModules.rootModules));
		return immutable ProgramsAndFilesInfo(
			program,
			some(immutable ConcreteAndLowProgram(
				concreteProgram,
				lower(alloc, perf, allSymbols, program.config.extern_, concreteProgram))));
	} else
		return immutable ProgramsAndFilesInfo(program, none!ConcreteAndLowProgram);
}
