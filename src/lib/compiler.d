module lib.compiler;

@safe @nogc nothrow: // not pure

import backend.writeToC : writeToC;
import concretize.concretize : concretize;
import document.document : documentJSON;
import frontend.frontendCompile : FileAstAndDiagnostics, frontendCompile, parseSingleAst;
import frontend.ide.getTokens : jsonOfTokens, tokensOfAst;
import frontend.parse.jsonOfAst : jsonOfAst;
import frontend.showDiag : ShowDiagOptions, strOfDiagnostics;
import interpret.bytecode : ByteCode;
import interpret.extern_ : Extern, ExternFunPtrsForAllLibraries, WriteError;
import interpret.generateBytecode : generateBytecode;
import interpret.runBytecode : runBytecode;
import lower.lower : lower;
import model.concreteModel : ConcreteProgram;
import model.diag : isEmpty, isFatal;
import model.lowModel : ExternLibraries, LowProgram;
import model.model : fakeProgramForDiagnostics, Program;
import model.jsonOfConcreteModel : jsonOfConcreteProgram;
import model.jsonOfLowModel : jsonOfLowProgram;
import model.jsonOfModel : jsonOfModule;
import util.alloc.alloc : Alloc;
import util.col.arr : only;
import util.col.str : SafeCStr, safeCStr;
import util.json : Json, jsonToString;
import util.opt : force, has, none, Opt, some;
import util.path : AllPaths, Path, PathsInfo;
import util.perf : Perf;
import util.readOnlyStorage : ReadOnlyStorage;
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
	DiagsAndResultJson json = () {
		final switch (kind) {
			case PrintKind.tokens:
				return printTokens(alloc, perf, allSymbols, allPaths, storage, main);
			case PrintKind.ast:
				return printAst(alloc, perf, allSymbols, allPaths, storage, main);
			case PrintKind.model:
				return printModel(alloc, perf, allSymbols, allPaths, storage, main);
			case PrintKind.concreteModel:
				return printConcreteModel(
					alloc, perf, versionInfo, allSymbols, allPaths, storage, main);
			case PrintKind.lowModel:
				return printLowModel(
					alloc, perf, versionInfo, allSymbols, allPaths, storage, main);
		}
	}();
	return DiagsAndResultStrs(
		strOfDiagnostics(alloc, allSymbols, allPaths, pathsInfo, showDiagOptions, json.programForDiags),
		jsonToString(alloc, allSymbols, json.result));
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
	writeDiagnostics(writeError, alloc, allSymbols, allPaths, pathsInfo, showDiagOptions, programs.program);
	if (isFatal(programs.program.diagnostics))
		return ExitCode.error;
	else {
		Opt!ExternFunPtrsForAllLibraries externFunPtrs =
			extern_.loadExternFunPtrs(programs.lowProgram.externLibraries, writeError);
		if (has(externFunPtrs)) {
			ByteCode byteCode = generateBytecode(
				alloc, perf, allSymbols,
				programs.program, programs.lowProgram, force(externFunPtrs), extern_.makeSyntheticFunPtrs);
			return ExitCode(runBytecode(
				perf,
				alloc,
				allSymbols,
				allPaths,
				pathsInfo,
				extern_.doDynCall,
				programs.program,
				programs.lowProgram,
				byteCode,
				allArgs));
		} else {
			writeError(safeCStr!"Failed to load external libraries\n");
			return ExitCode.error;
		}
	}
}

private:

void writeDiagnostics(
	in WriteError writeError,
	ref Alloc alloc,
	in AllSymbols allSymbols,
	in AllPaths allPaths,
	in PathsInfo pathsInfo,
	in ShowDiagOptions showDiagOptions,
	in Program program,
) {
	if (!isEmpty(program.diagnostics))
		writeError(strOfDiagnostics(alloc, allSymbols, allPaths, pathsInfo, showDiagOptions, program));
}

struct DiagsAndResultJson {
	Program programForDiags;
	Json result;
}

DiagsAndResultJson printTokens(
	ref Alloc alloc,
	ref Perf perf,
	ref AllSymbols allSymbols,
	ref AllPaths allPaths,
	in ReadOnlyStorage storage,
	Path main,
) {
	FileAstAndDiagnostics astResult = parseSingleAst(alloc, perf, allSymbols, allPaths, storage, main);
	return DiagsAndResultJson(
		fakeProgram(astResult),
		jsonOfTokens(alloc, tokensOfAst(alloc, allSymbols, astResult.ast)));
}

Program fakeProgram(FileAstAndDiagnostics astResult) =>
	fakeProgramForDiagnostics(astResult.filesInfo, astResult.diagnostics);

DiagsAndResultJson printAst(
	ref Alloc alloc,
	ref Perf perf,
	ref AllSymbols allSymbols,
	ref AllPaths allPaths,
	in ReadOnlyStorage storage,
	Path main,
) {
	FileAstAndDiagnostics astResult = parseSingleAst(alloc, perf, allSymbols, allPaths, storage, main);
	return DiagsAndResultJson(fakeProgram(astResult), jsonOfAst(alloc, allPaths, astResult.ast));
}

DiagsAndResultJson printModel(
	ref Alloc alloc,
	ref Perf perf,
	ref AllSymbols allSymbols,
	ref AllPaths allPaths,
	in ReadOnlyStorage storage,
	Path main,
) {
	Program program = frontendCompile(alloc, perf, alloc, allPaths, allSymbols, storage, [main], none!Path);
	return DiagsAndResultJson(program, jsonOfModule(alloc, *only(program.rootModules)));
}

DiagsAndResultJson printConcreteModel(
	ref Alloc alloc,
	ref Perf perf,
	in VersionInfo versionInfo,
	ref AllSymbols allSymbols,
	ref AllPaths allPaths,
	in ReadOnlyStorage storage,
	Path main,
) {
	Program program = frontendCompile(alloc, perf, alloc, allPaths, allSymbols, storage, [main], none!Path);
	return DiagsAndResultJson(
		program,
		jsonOfConcreteProgram(alloc, concretize(alloc, perf, versionInfo, allSymbols, program)));
}

DiagsAndResultJson printLowModel(
	ref Alloc alloc,
	ref Perf perf,
	in VersionInfo versionInfo,
	ref AllSymbols allSymbols,
	ref AllPaths allPaths,
	in ReadOnlyStorage storage,
	Path main,
) {
	Program program = frontendCompile(alloc, perf, alloc, allPaths, allSymbols, storage, [main], none!Path);
	ConcreteProgram concreteProgram = concretize(alloc, perf, versionInfo, allSymbols, program);
	LowProgram lowProgram = lower(alloc, perf, allSymbols, program.config.extern_, program, concreteProgram);
	return DiagsAndResultJson(program, jsonOfLowProgram(alloc, lowProgram));
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
	return isEmpty(program.diagnostics)
		? none!SafeCStr
		: some(strOfDiagnostics(alloc, allSymbols, allPaths, pathsInfo, showDiagOptions, program));
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
		return BuildToCResult(
			isFatal(programs.program.diagnostics)
				? safeCStr!""
				: writeToC(alloc, alloc, allSymbols, programs.program, programs.lowProgram),
			strOfDiagnostics(alloc, allSymbols, allPaths, pathsInfo, showDiagOptions, programs.program),
			programs.lowProgram.externLibraries);
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
	return DocumentResult(
		documentJSON(alloc, allSymbols, allPaths, pathsInfo, program),
		strOfDiagnostics(alloc, allSymbols, allPaths, pathsInfo, showDiagOptions, program));
}

//TODO:RENAME
public immutable struct ProgramsAndFilesInfo {
	Program program;
	ConcreteProgram concreteProgram;
	LowProgram lowProgram;
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
	ConcreteProgram concreteProgram = concretize(alloc, perf, versionInfo, allSymbols, program);
	LowProgram lowProgram = lower(alloc, perf, allSymbols, program.config.extern_, program, concreteProgram);
	return ProgramsAndFilesInfo(program, concreteProgram, lowProgram);
}
