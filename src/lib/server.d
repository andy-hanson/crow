module lib.server;

@safe @nogc nothrow: // not pure

import backend.writeToC : writeToC;
import concretize.concretize : concretize;
import document.document : documentJSON;
import frontend.diagnosticsBuilder : DiagnosticsBuilder, DiagnosticsBuilderForFile, finishDiagnostics;
import frontend.frontendCompile : frontendCompile, FileAstAndDiagnostics, parseAllFiles, parseSingleAst;
import frontend.ide.getDefinition : getDefinitionForPosition;
import frontend.ide.getHover : getHoverStr;
import frontend.ide.getPosition : getPosition;
import frontend.ide.getRename : getRenameForPosition, jsonOfRename, Rename;
import frontend.ide.getReferences : getReferencesForPosition, jsonOfReferences;
import frontend.ide.getTokens : jsonOfTokens, Token, tokensOfAst;
import frontend.ide.position : Position;
import frontend.lang : crowExtension;
import frontend.parse.ast : FileAst;
import frontend.parse.jsonOfAst : jsonOfAst;
import frontend.parse.parse : parseFile;
import frontend.showDiag : stringOfDiag, stringOfDiagnostics;
import frontend.showModel : ShowCtx, ShowOptions;
import interpret.bytecode : ByteCode;
import interpret.extern_ : Extern, ExternFunPtrsForAllLibraries, WriteError;
import interpret.fakeExtern : Pipe, withFakeExtern, WriteCb;
import interpret.generateBytecode : generateBytecode;
import interpret.runBytecode : runBytecode;
import lib.cliParser : PrintKind;
import lower.lower : lower;
import model.concreteModel : ConcreteProgram;
import model.diag : Diag, Diagnostic, diagnosticsIsFatal;
import model.jsonOfConcreteModel : jsonOfConcreteProgram;
import model.jsonOfLowModel : jsonOfLowProgram;
import model.jsonOfModel : jsonOfModule;
import model.lowModel : ExternLibraries, LowProgram;
import model.model : fakeProgramForDiagnostics, Module, Program;
import util.alloc.alloc : Alloc;
import util.col.arr : only;
import util.col.str : SafeCStr, safeCStr, safeCStrIsEmpty, strOfSafeCStr;
import util.exitCode : ExitCode;
import util.json : Json, jsonString;
import util.late : Late, lateGet, lateSet;
import util.lineAndColumnGetter :
	LineAndColumnGetters, toLineAndCharacter, uncacheFile, UriLineAndCharacter, UriLineAndColumn;
import util.opt : force, has, none, Opt, some;
import util.perf : Perf;
import util.ptr : ptrTrustMe;
import util.storage :
	allocateToStorage,
	allKnownGoodUris,
	allStorageUris,
	allUrisWithIssue,
	asSafeCStr,
	FileContent,
	getFileNoMarkUnknown,
	hasUnknownOrLoadingUris,
	ReadFileIssue,
	ReadFileResult,
	Storage,
	setFile,
	withFile;
import util.sourceRange : UriAndRange;
import util.sym : AllSymbols;
import util.uri : AllUris, getExtension, parseUri, Uri, UrisInfo;
import util.util : verify;
import util.writer : finishWriterToSafeCStr, Writer;
import versionInfo : VersionInfo, versionInfoForBuildToC, versionInfoForInterpret;

ExitCode run(ref Perf perf, ref Alloc alloc, ref Server server, Uri main, in WriteCb writeCb) {
	// TODO: use an arena so anything allocated during interpretation is cleaned up.
	// Or just have interpreter free things.
	SafeCStr[1] allArgs = [safeCStr!"/usr/bin/fakeExecutable"];
	return withFakeExtern(alloc, server.allSymbols, writeCb, (scope ref Extern extern_) =>
		buildAndInterpret(
			alloc, perf, server, extern_,
			(in SafeCStr x) {
				writeCb(Pipe.stderr, strOfSafeCStr(x));
			},
			main, allArgs));
}

ExitCode buildAndInterpret(
	ref Alloc alloc,
	ref Perf perf,
	ref Server server,
	in Extern extern_,
	in WriteError writeError,
	Uri main,
	in SafeCStr[] allArgs,
) {
	verify(!hasUnknownOrLoadingUris(server));
	Programs programs = buildToLowProgram(alloc, perf, server, versionInfoForInterpret, main);
	SafeCStr diags = showDiagnostics(alloc, server, programs.program);
	if (!safeCStrIsEmpty(diags))
		writeError(diags);
	if (!has(programs.lowProgram))
		return ExitCode.error;
	else {
		LowProgram lowProgram = force(programs.lowProgram);
		Opt!ExternFunPtrsForAllLibraries externFunPtrs =
			extern_.loadExternFunPtrs(lowProgram.externLibraries, writeError);
		if (has(externFunPtrs)) {
			ByteCode byteCode = generateBytecode(
				alloc, perf, server.allSymbols,
				programs.program, lowProgram, force(externFunPtrs), extern_.makeSyntheticFunPtrs);
			ShowCtx printCtx = getShowDiagCtx(server, programs.program);
			return ExitCode(runBytecode(perf, alloc, printCtx, extern_.doDynCall, lowProgram, byteCode, allArgs));
		} else {
			writeError(safeCStr!"Failed to load external libraries\n");
			return ExitCode.error;
		}
	}
}

pure:

struct Server {
	@safe @nogc pure nothrow:

	Alloc alloc;
	AllSymbols allSymbols;
	AllUris allUris;
	private Late!Uri includeDir_;
	private Late!UrisInfo urisInfo_;
	private Late!ShowOptions diagOptions_;
	Storage storage;
	LineAndColumnGetters lineAndColumnGetters;

	@trusted this(Alloc a) {
		alloc = a.move();
		allSymbols = AllSymbols(&alloc);
		allUris = AllUris(&alloc, &allSymbols);
		storage = Storage(&alloc);
		lineAndColumnGetters = LineAndColumnGetters(&alloc, &storage);
	}

	ref Uri includeDir() return scope const =>
		lateGet(includeDir_);
	ref UrisInfo urisInfo() return scope const =>
		lateGet(urisInfo_);
	ref ShowOptions diagOptions() return scope const =>
		lateGet(diagOptions_);
}

SafeCStr version_(ref Alloc alloc, in Server server) {
	static immutable string date = import("date.txt")[0 .. "2020-02-02".length];
	static immutable string commitHash = import("commit-hash.txt")[0 .. 8];
	Writer writer = Writer(&alloc);
	writer ~= date;
	//"%.*s (%.*s)",
	writer ~= " (";
	writer ~= commitHash;
	writer ~= ")";
	version (Debug) {
		writer ~= ", debug build";
	}
	version (assert) {} else {
		writer ~= ", assertions disabled";
	}
	version (TailRecursionAvailable) {} else {
		writer ~= ", no tail calls";
	}
	version (GccJitEnabled) {} else {
		writer ~= ", does not support '--jit'";
	}
	writer ~= ", built with ";
	writer ~= dCompilerName;
	return finishWriterToSafeCStr(writer);
}

private string dCompilerName() {
	version (DigitalMars) {
		return "DMD";
	} else version (GNU) {
		return "GDC";
	} else version (LDC) {
		return "LDC";
	} else {
		static assert(false);
	}
}

void setIncludeDir(ref Server server, Uri uri) {
	lateSet!Uri(server.includeDir_, uri);
}

void setCwd(ref Server server, Uri uri) {
	lateSet!UrisInfo(server.urisInfo_, UrisInfo(some(uri)));
}

void setDiagOptions(ref Server server, in ShowOptions options) {
	lateSet!ShowOptions(server.diagOptions_, options);
}

void setFile(ref Server server, Uri uri, ReadFileResult result) {
	uncacheFile(server, uri);
	setFile(server.storage, uri, result);
}

void setFileFromTemp(ref Server server, Uri uri, in SafeCStr text) {
	uncacheFile(server, uri);
	setFile(server, uri, ReadFileResult(allocateToStorage(server.storage, text)));
}

private void uncacheFile(scope ref Server server, Uri uri) {
	uncacheFile(server.lineAndColumnGetters, uri);
}

Opt!FileContent getFile(ref Alloc alloc, in Server server, Uri uri) =>
	getFileNoMarkUnknown(alloc, server.storage, uri);

private bool hasUnknownOrLoadingUris(in Server server) =>
	hasUnknownOrLoadingUris(server.storage);

Uri[] allStorageUris(ref Alloc alloc, in Server server) =>
	allStorageUris(alloc, server.storage);
Uri[] allUnknownUris(ref Alloc alloc, in Server server) =>
	allUrisWithIssue(alloc, server.storage, ReadFileIssue.unknown);
Uri[] allLoadingUris(ref Alloc alloc, in Server server) =>
	allUrisWithIssue(alloc, server.storage, ReadFileIssue.loading);

void justParseEverything(ref Alloc alloc, ref Perf perf, ref Server server, in Uri[] rootUris) {
	parseAllFiles(alloc, perf, server.allSymbols, server.allUris, server.storage, server.includeDir, rootUris);
}

Program typeCheckAllKnownFiles(ref Alloc alloc, ref Perf perf, ref Server server) =>
	justTypeCheck(alloc, perf, server, allKnownGoodUris(alloc, server.storage, (Uri uri) =>
		getExtension(server.allUris, uri) == crowExtension));

Program justTypeCheck(ref Alloc alloc, ref Perf perf, ref Server server, in Uri[] rootUris) =>
	frontendCompile(alloc, perf, server, rootUris, none!Uri);

SafeCStr showDiag(ref Alloc alloc, scope ref Server server, in Program program, in Diag a) {
	ShowCtx ctx = getShowDiagCtx(server, program);
	return stringOfDiag(alloc, ctx, a);
}

SafeCStr showDiagnostics(ref Alloc alloc, scope ref Server server, in Program program) {
	ShowCtx ctx = getShowDiagCtx(server, program);
	return stringOfDiagnostics(alloc, ctx, program.diagnostics);
}

immutable struct DocumentResult {
	SafeCStr document;
	SafeCStr diagnostics;
}

DocumentResult getDocumentation(ref Alloc alloc, ref Perf perf, ref Server server, in Uri[] uris) {
	Program program = frontendCompile(alloc, perf, server, uris, none!Uri);
	return DocumentResult(
		documentJSON(alloc, server.allSymbols, server.allUris, program),
		showDiagnostics(alloc, server, program));
}

private Program frontendCompile(
	ref Alloc alloc,
	ref Perf perf,
	scope ref Server server,
	in Uri[] rootUris,
	in Opt!Uri main,
) =>
	frontendCompile(
		alloc, perf, alloc, server.allSymbols, server.allUris, server.storage, server.includeDir, rootUris, main);

immutable struct TokensAndParseDiagnostics {
	Token[] tokens;
	Program programForDiagnostics;
}

TokensAndParseDiagnostics getTokensAndParseDiagnostics(
	ref Alloc alloc,
	scope ref Perf perf,
	ref Server server,
	Uri uri,
) =>
	withFile!TokensAndParseDiagnostics(server.storage, uri, (in ReadFileResult x) {
		SafeCStr text = x.isA!FileContent ? asSafeCStr(x.as!FileContent) : safeCStr!"";
		DiagnosticsBuilder diags = DiagnosticsBuilder(&alloc);
		DiagnosticsBuilderForFile diagsForFile = DiagnosticsBuilderForFile(&diags, uri);
		FileAst ast = parseFile(alloc, perf, server.allSymbols, server.allUris, diagsForFile, text);
		return TokensAndParseDiagnostics(
			tokensOfAst(alloc, server.allSymbols, server.allUris, ast),
			fakeProgramForDiagnostics(finishDiagnostics(diags, server.allUris)));
	});

UriAndRange[] getDefinition(ref Perf perf, ref Alloc alloc, ref Server server, in UriLineAndCharacter where) =>
	getDefinitionForProgram(alloc, server, getProgram(perf, alloc, server, [where.uri]), where);

private UriAndRange[] getDefinitionForProgram(
	ref Alloc alloc,
	scope ref Server server,
	in Program program,
	in UriLineAndCharacter where,
) {
	Opt!Position position = getPosition(server, program, where);
	return has(position)
		? getDefinitionForPosition(alloc, server.allSymbols, program, force(position))
		: [];
}

UriAndRange[] getReferences(
	ref Perf perf,
	ref Alloc alloc,
	scope ref Server server,
	in UriLineAndCharacter where,
	in Uri[] roots,
) =>
	getReferencesForProgram(alloc, server, where, getProgram(perf, alloc, server, roots));

private UriAndRange[] getReferencesForProgram(
	ref Alloc alloc,
	scope ref Server server,
	in UriLineAndCharacter where,
	in Program program,
) {
	Opt!Position position = getPosition(server, program, where);
	return has(position)
		? getReferencesForPosition(alloc, server.allSymbols, server.allUris, program, force(position))
		: [];
}

Opt!Rename getRename(
	ref Perf perf,
	ref Alloc alloc,
	scope ref Server server,
	in UriLineAndCharacter where,
	in Uri[] roots,
	string newName,
) =>
	getRenameForProgram(alloc, server, getProgram(perf, alloc, server, roots), where, newName);

private Opt!Rename getRenameForProgram(
	ref Alloc alloc,
	scope ref Server server,
	in Program program,
	in UriLineAndCharacter where,
	string newName,
) {
	Opt!Position position = getPosition(server, program, where);
	return has(position)
		? getRenameForPosition(alloc, server.allSymbols, server.allUris, program, force(position), newName)
		: none!Rename;
}

SafeCStr getHover(ref Perf perf, ref Alloc alloc, ref Server server, in UriLineAndCharacter where) =>
	getHoverForProgram(alloc, server, getProgram(perf, alloc, server, [where.uri]), where);

private SafeCStr getHoverForProgram(
	ref Alloc alloc,
	scope ref Server server,
	in Program program,
	in UriLineAndCharacter where,
) {
	Opt!Position position = getPosition(server, program, where);
	ShowCtx ctx = getShowDiagCtx(server, program);
	return has(position)
		? getHoverStr(alloc, ctx, force(position))
		: safeCStr!"";
}

private Program getProgram(ref Perf perf, ref Alloc alloc, scope ref Server server, in Uri[] roots) =>
	frontendCompile(alloc, perf, server, roots, none!Uri);

private Opt!Position getPosition(scope ref Server server, in Program program, in UriLineAndCharacter where) {
	Opt!(immutable Module*) module_ = program.allModules[where.uri];
	return has(module_)
		? some(getPosition(server.allSymbols, server.allUris, force(module_), server.lineAndColumnGetters[where]))
		: none!Position;
}

Uri toUri(ref Server server, in SafeCStr uri) =>
	parseUri(server.allUris, uri);

struct DiagsAndResultJson {
	SafeCStr diagnostics;
	Json result;
}

private DiagsAndResultJson diagsAndResultJson(
	ref Alloc alloc,
	scope ref Server server,
	in Program program,
	Json result,
) =>
	DiagsAndResultJson(showDiagnostics(alloc, server, program), result);

DiagsAndResultJson printTokens(ref Alloc alloc, ref Perf perf, ref Server server, Uri uri) {
	FileAstAndDiagnostics astResult = parseSingleAst(
		alloc, perf, server.allSymbols, server.allUris, server.storage, uri);
	Json json = jsonOfTokens(
		alloc, server.lineAndColumnGetters[uri], tokensOfAst(alloc, server.allSymbols, server.allUris, astResult.ast));
	return diagsAndResultJson(alloc, server, fakeProgramForDiagnostics(astResult.diagnostics), json);
}

DiagsAndResultJson printAst(ref Alloc alloc, ref Perf perf, ref Server server, Uri uri) {
	FileAstAndDiagnostics astResult = parseSingleAst(
		alloc, perf, server.allSymbols, server.allUris, server.storage, uri);
	return diagsAndResultJson(
		alloc,
		server,
		fakeProgramForDiagnostics(astResult.diagnostics),
		jsonOfAst(alloc, server.allUris, server.lineAndColumnGetters[uri], astResult.ast));
}

DiagsAndResultJson printModel(ref Alloc alloc, ref Perf perf, ref Server server, Uri uri) {
	Program program = frontendCompile(alloc, perf, server, [uri], none!Uri);
	Json json = jsonOfModule(alloc, server.allUris, server.lineAndColumnGetters[uri], *only(program.rootModules));
	return diagsAndResultJson(alloc, server, program, json);
}

DiagsAndResultJson printConcreteModel(
	ref Alloc alloc,
	ref Perf perf,
	ref Server server,
	scope ref LineAndColumnGetters lineAndColumnGetters,
	in VersionInfo versionInfo,
	Uri uri,
) {
	Program program = frontendCompile(alloc, perf, server, [uri], none!Uri);
	ShowCtx ctx = getShowDiagCtx(server, program);
	return diagsAndResultJson(
		alloc, server, program,
		jsonOfConcreteProgram(alloc, lineAndColumnGetters, concretize(alloc, perf, ctx, versionInfo, program)));
}

DiagsAndResultJson printLowModel(
	ref Alloc alloc,
	ref Perf perf,
	ref Server server,
	scope ref LineAndColumnGetters lineAndColumnGetters,
	in VersionInfo versionInfo,
	Uri uri,
) {
	Program program = frontendCompile(alloc, perf, server, [uri], none!Uri);
	ShowCtx ctx = getShowDiagCtx(server, program);
	ConcreteProgram concreteProgram = concretize(alloc, perf, ctx, versionInfo, program);
	LowProgram lowProgram = lower(alloc, perf, server.allSymbols, program.config.extern_, program, concreteProgram);
	return diagsAndResultJson(alloc, server, program, jsonOfLowProgram(alloc, lineAndColumnGetters, lowProgram));
}

DiagsAndResultJson printIde(
	ref Alloc alloc,
	ref Perf perf,
	scope ref Server server,
	in UriLineAndColumn where,
	in PrintKind.Ide.Kind kind,
) {
	Program program = getProgram(perf, alloc, server, [where.uri]); // TODO: we should support specifying roots...
	UriLineAndCharacter where2 = toLineAndCharacter(server.lineAndColumnGetters, where);
	Json locations(UriAndRange[] xs) =>
		jsonOfReferences(alloc, server.allUris, server.lineAndColumnGetters, xs);
	Json json = () {
		final switch (kind) {
			case PrintKind.Ide.Kind.definition:
				return locations(getDefinitionForProgram(alloc, server, program, where2));
			case PrintKind.Ide.Kind.hover:
				return jsonString(getHoverForProgram(alloc, server, program, where2));
			case PrintKind.Ide.Kind.rename:
				Opt!Rename rename = getRenameForProgram(alloc, server, program, where2, "new-name");
				return jsonOfRename(alloc, server.allUris, server.lineAndColumnGetters, rename);
			case PrintKind.Ide.Kind.references:
				return locations(getReferencesForProgram(alloc, server, where2, program));
		}
	}();
	return diagsAndResultJson(alloc, server, program, json);
}

immutable struct Programs {
	Program program;
	Opt!ConcreteProgram concreteProgram;
	Opt!LowProgram lowProgram;
}

Programs buildToLowProgram(
	ref Alloc alloc,
	ref Perf perf,
	ref Server server,
	in VersionInfo versionInfo,
	Uri main,
) {
	Program program = frontendCompile(alloc, perf, server, [main], some(main));
	ShowCtx ctx = getShowDiagCtx(server, program);
	if (diagnosticsIsFatal(program.diagnostics))
		return Programs(program, none!ConcreteProgram, none!LowProgram);
	else {
		ConcreteProgram concreteProgram = concretize(alloc, perf, ctx, versionInfo, program);
		LowProgram lowProgram = lower(alloc, perf, server.allSymbols, program.config.extern_, program, concreteProgram);
		return Programs(program, some(concreteProgram), some(lowProgram));
	}
}

immutable struct BuildToCResult {
	SafeCStr cSource;
	SafeCStr diagnostics;
	ExternLibraries externLibraries;
}
BuildToCResult buildToC(ref Alloc alloc, ref Perf perf, ref Server server, Uri main) {
	Programs programs = buildToLowProgram(alloc, perf, server, versionInfoForBuildToC, main);
	ShowCtx ctx = getShowDiagCtx(server, programs.program);
	return BuildToCResult(
		has(programs.lowProgram)
			? safeCStr!""
			: writeToC(alloc, alloc, ctx, force(programs.lowProgram)),
		showDiagnostics(alloc, server, programs.program),
		has(programs.lowProgram) ? force(programs.lowProgram).externLibraries : []);
}

private:

ShowCtx getShowDiagCtx(return scope ref Server server, return scope ref Program program) =>
	ShowCtx(
		ptrTrustMe(server.allSymbols),
		ptrTrustMe(server.allUris),
		ptrTrustMe(server.lineAndColumnGetters),
		server.urisInfo,
		server.diagOptions,
		ptrTrustMe(program));
