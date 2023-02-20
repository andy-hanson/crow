module lib.compiler;

@safe @nogc nothrow: // not pure

import backend.writeToC : writeToC;
import concretize.concretize : concretize;
import document.document : documentJSON;
import frontend.parse.ast : reprAst;
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
import model.model : fakeProgramForDiagnostics, hasDiags, Program;
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

immutable struct DiagsAndResultStrs {
	SafeCStr diagnostics;
	SafeCStr result;
}

DiagsAndResultStrs print(
	ref Alloc alloc,
	ref Perf perf,
	in VersionInfo versionInfo,
	ref AllSymbols allSymbols,
	ref AllPaths allPaths,
	in PathsInfo pathsInfo,
	in ReadOnlyStorage storage,
	in ShowDiagOptions showDiagOptions,
	PrintKind kind,
	Path main,
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

immutable struct ExitCode {
	@safe @nogc pure nothrow:
	int value;

	static ExitCode ok() =>
		ExitCode(0);
	static ExitCode error() =>
		ExitCode(1);
}

ExitCode buildAndInterpret(
	ref Alloc alloc,
	ref Perf perf,
	ref AllSymbols allSymbols,
	ref AllPaths allPaths,
	in PathsInfo pathsInfo,
	in ReadOnlyStorage storage,
	in Extern extern_,
	in WriteError writeError,
	in ShowDiagOptions showDiagOptions,
	Path main,
	in SafeCStr[] allArgs,
) {
	ProgramsAndFilesInfo programs =
		buildToLowProgram(alloc, perf, versionInfoForInterpret(), allSymbols, allPaths, storage, main);
	if (!hasDiags(programs.program)) {
		LowProgram lowProgram = force(programs.concreteAndLowProgram).lowProgram;
		Opt!ExternFunPtrsForAllLibraries externFunPtrs =
			extern_.loadExternFunPtrs(lowProgram.externLibraries, writeError);
		if (has(externFunPtrs)) {
			ByteCode byteCode = generateBytecode(
				alloc, perf, allSymbols,
				programs.program, lowProgram, force(externFunPtrs), extern_.makeSyntheticFunPtrs);
			return ExitCode(runBytecode(
				perf,
				alloc,
				allSymbols,
				allPaths,
				pathsInfo,
				extern_.doDynCall,
				programs.program,
				lowProgram,
				byteCode,
				allArgs));
		} else {
			writeError(safeCStr!"Failed to load external libraries\n");
			return ExitCode.error;
		}
	} else {
		writeError(strOfDiagnostics(alloc, allSymbols, allPaths, pathsInfo, showDiagOptions, programs.program));
		return ExitCode.error;
	}
}

private:

DiagsAndResultStrs printTokens(
	ref Alloc alloc,
	ref Perf perf,
	ref AllSymbols allSymbols,
	ref AllPaths allPaths,
	in PathsInfo pathsInfo,
	in ReadOnlyStorage storage,
	in ShowDiagOptions showDiagOptions,
	Path main,
) {
	FileAstAndDiagnostics astResult = parseSingleAst(alloc, perf, allSymbols, allPaths, storage, main);
	Token[] tokens = tokensOfAst(alloc, allSymbols, astResult.ast);
	return DiagsAndResultStrs(
		strOfDiagnostics(alloc, allSymbols, allPaths, pathsInfo, showDiagOptions, fakeProgram(astResult)),
		jsonStrOfRepr(alloc, allSymbols, reprTokens(alloc, tokens)));
}

Program fakeProgram(FileAstAndDiagnostics astResult) =>
	fakeProgramForDiagnostics(astResult.filesInfo, astResult.diagnostics);

DiagsAndResultStrs printAst(
	ref Alloc alloc,
	ref Perf perf,
	ref AllSymbols allSymbols,
	ref AllPaths allPaths,
	in PathsInfo pathsInfo,
	in ReadOnlyStorage storage,
	in ShowDiagOptions showDiagOptions,
	Path main,
) {
	FileAstAndDiagnostics astResult = parseSingleAst(alloc, perf, allSymbols, allPaths, storage, main);
	return DiagsAndResultStrs(
		strOfDiagnostics(alloc, allSymbols, allPaths, pathsInfo, showDiagOptions, fakeProgram(astResult)),
		jsonStrOfRepr(alloc, allSymbols, reprAst(alloc, allPaths, astResult.ast)));
}

DiagsAndResultStrs printModel(
	ref Alloc alloc,
	ref Perf perf,
	ref AllSymbols allSymbols,
	ref AllPaths allPaths,
	in PathsInfo pathsInfo,
	in ReadOnlyStorage storage,
	in ShowDiagOptions showDiagOptions,
	Path main,
) {
	Program program = frontendCompile(alloc, perf, alloc, allPaths, allSymbols, storage, [main], none!Path);
	return !hasDiags(program)
		? DiagsAndResultStrs(
			safeCStr!"",
			jsonStrOfRepr(alloc, allSymbols, reprModule(alloc, *only(program.rootModules))))
		: DiagsAndResultStrs(
			strOfDiagnostics(alloc, allSymbols, allPaths, pathsInfo, showDiagOptions, program),
			safeCStr!"");
}

DiagsAndResultStrs printConcreteModel(
	ref Alloc alloc,
	ref Perf perf,
	in VersionInfo versionInfo,
	ref AllSymbols allSymbols,
	ref AllPaths allPaths,
	in PathsInfo pathsInfo,
	in ReadOnlyStorage storage,
	in ShowDiagOptions showDiagOptions,
	Path main,
) {
	Program program = frontendCompile(alloc, perf, alloc, allPaths, allSymbols, storage, [main], none!Path);
	if (!hasDiags(program)) {
		ConcreteProgram concreteProgram = concretize(alloc, perf, versionInfo, allSymbols, program);
		return DiagsAndResultStrs(
			safeCStr!"",
			jsonStrOfRepr(alloc, allSymbols, reprOfConcreteProgram(alloc, concreteProgram)));
	} else
		return DiagsAndResultStrs(
			strOfDiagnostics(alloc, allSymbols, allPaths, pathsInfo, showDiagOptions, program),
			safeCStr!"");
}

DiagsAndResultStrs printLowModel(
	ref Alloc alloc,
	ref Perf perf,
	in VersionInfo versionInfo,
	ref AllSymbols allSymbols,
	ref AllPaths allPaths,
	in PathsInfo pathsInfo,
	in ReadOnlyStorage storage,
	in ShowDiagOptions showDiagOptions,
	Path main,
) {
	Program program = frontendCompile(alloc, perf, alloc, allPaths, allSymbols, storage, [main], none!Path);
	if (!hasDiags(program)) {
		ConcreteProgram concreteProgram = concretize(alloc, perf, versionInfo, allSymbols, program);
		LowProgram lowProgram = lower(alloc, perf, allSymbols, program.config.extern_, concreteProgram);
		return DiagsAndResultStrs(
			safeCStr!"",
			jsonStrOfRepr(alloc, allSymbols, reprOfLowProgram(alloc, lowProgram)));
	} else
		return DiagsAndResultStrs(
			strOfDiagnostics(alloc, allSymbols, allPaths, pathsInfo, showDiagOptions, program),
			safeCStr!"");
}

public Opt!SafeCStr justTypeCheck(
	ref Alloc alloc,
	ref Perf perf,
	ref AllSymbols allSymbols,
	ref AllPaths allPaths,
	in PathsInfo pathsInfo,
	in ReadOnlyStorage storage,
	in ShowDiagOptions showDiagOptions,
	Path main,
) {
	Program program = frontendCompile(alloc, perf, alloc, allPaths, allSymbols, storage, [main], none!Path);
	return hasDiags(program)
		? some(strOfDiagnostics(alloc, allSymbols, allPaths, pathsInfo, showDiagOptions, program))
		: none!SafeCStr;
}

version (WebAssembly) {} else {
	public immutable struct BuildToCResult {
		SafeCStr cSource;
		SafeCStr diagnostics;
		ExternLibraries externLibraries;
	}
	public BuildToCResult buildToC(
		ref Alloc alloc,
		ref Perf perf,
		ref AllSymbols allSymbols,
		ref AllPaths allPaths,
		in PathsInfo pathsInfo,
		in ReadOnlyStorage storage,
		in ShowDiagOptions showDiagOptions,
		Path main,
	) {
		ProgramsAndFilesInfo programs =
			buildToLowProgram(alloc, perf, versionInfoForBuildToC(), allSymbols, allPaths, storage, main);
		return !hasDiags(programs.program)
			? BuildToCResult(
				writeToC(alloc, alloc, allSymbols, programs.program, force(programs.concreteAndLowProgram).lowProgram),
				safeCStr!"",
				force(programs.concreteAndLowProgram).lowProgram.externLibraries)
			: BuildToCResult(
				safeCStr!"",
				strOfDiagnostics(alloc, allSymbols, allPaths, pathsInfo, showDiagOptions, programs.program),
				[]);
	}
}

public immutable struct DocumentResult {
	SafeCStr document;
	SafeCStr diagnostics;
}

public DocumentResult compileAndDocument(
	ref Alloc alloc,
	ref Perf perf,
	ref AllSymbols allSymbols,
	ref AllPaths allPaths,
	in PathsInfo pathsInfo,
	in ReadOnlyStorage storage,
	in ShowDiagOptions showDiagOptions,
	in Path[] rootPaths,
) {
	Program program =
		frontendCompile(alloc, perf, alloc, allPaths, allSymbols, storage, rootPaths, none!Path);
	return !hasDiags(program)
		? DocumentResult(
			documentJSON(alloc, allSymbols, allPaths, pathsInfo, program),
			safeCStr!"")
		: DocumentResult(
			safeCStr!"",
			strOfDiagnostics(alloc, allSymbols, allPaths, pathsInfo, showDiagOptions, program));
}

immutable struct ConcreteAndLowProgram {
	ConcreteProgram concreteProgram;
	LowProgram lowProgram;
}

//TODO:RENAME
public immutable struct ProgramsAndFilesInfo {
	@safe @nogc pure nothrow:

	Program program;
	Opt!ConcreteAndLowProgram concreteAndLowProgram;

	ref LowProgram lowProgram() return =>
		force(concreteAndLowProgram).lowProgram;
}

public ProgramsAndFilesInfo buildToLowProgram(
	ref Alloc alloc,
	ref Perf perf,
	in VersionInfo versionInfo,
	ref AllSymbols allSymbols,
	ref AllPaths allPaths,
	in ReadOnlyStorage storage,
	Path main,
) {
	Program program = frontendCompile(alloc, perf, alloc, allPaths, allSymbols, storage, [main], some(main));
	if (!hasDiags(program)) {
		ConcreteProgram concreteProgram = concretize(alloc, perf, versionInfo, allSymbols, program);
		return ProgramsAndFilesInfo(
			program,
			some(ConcreteAndLowProgram(
				concreteProgram,
				lower(alloc, perf, allSymbols, program.config.extern_, concreteProgram))));
	} else
		return ProgramsAndFilesInfo(program, none!ConcreteAndLowProgram);
}
