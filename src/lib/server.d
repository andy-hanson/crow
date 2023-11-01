module lib.server;

@safe @nogc nothrow: // not pure

import backend.writeToC : writeToC;
import concretize.concretize : concretize;
import document.document : documentJSON;
import frontend.diagnosticsBuilder : DiagnosticsBuilder, DiagnosticsBuilderForFile, finishDiagnostics;
import frontend.frontendCompile : frontendCompile, FileAstAndDiagnostics, parseAllFiles, parseSingleAst;
import frontend.ide.getDefinition : Definition, getDefinitionForPosition;
import frontend.ide.getHover : getHoverStr;
import frontend.ide.getPosition : getPosition, Position;
import frontend.ide.getTokens : jsonOfTokens, Token, tokensOfAst;
import frontend.parse.ast : FileAst;
import frontend.parse.jsonOfAst : jsonOfAst;
import frontend.parse.parse : parseFile;
import frontend.showDiag : strOfDiagnostic, strOfDiagnostics;
import frontend.showModel : ShowCtx, ShowOptions;
import interpret.bytecode : ByteCode;
import interpret.extern_ : Extern, ExternFunPtrsForAllLibraries, WriteError;
import interpret.fakeExtern : Pipe, withFakeExtern, WriteCb;
import interpret.generateBytecode : generateBytecode;
import interpret.runBytecode : runBytecode;
import lower.lower : lower;
import model.concreteModel : ConcreteProgram;
import model.diag : Diagnostic, diagnosticsIsFatal;
import model.jsonOfConcreteModel : jsonOfConcreteProgram;
import model.jsonOfLowModel : jsonOfLowProgram;
import model.jsonOfModel : jsonOfModule;
import model.lowModel : ExternLibraries, LowProgram;
import model.model : fakeProgramForDiagnostics, Module, Program;
import util.alloc.alloc : Alloc;
import util.col.arr : only;
import util.col.str : SafeCStr, safeCStr, safeCStrIsEmpty, strOfSafeCStr;
import util.exitCode : ExitCode;
import util.json : Json;
import util.late : Late, lateGet, lateSet;
import util.lineAndColumnGetter : LineAndColumnGetters;
import util.opt : force, has, none, Opt, some;
import util.perf : Perf;
import util.ptr : ptrTrustMe;
import util.storage :
	allKnownGoodUris,
	allocateToStorage,
	allUnknownUris,
	asSafeCStr,
	deleteFile,
	FileContent,
	getFileNoMarkUnknown,
	hasUnknownUris,
	ReadFileResult,
	Storage,
	setFile,
	withFileContent;
import util.sourceRange : Pos;
import util.sym : AllSymbols;
import util.uri : AllUris, parseUri, Uri, UrisInfo;
import util.util : verify;
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

private bool hasUnknownUris(in Server server) =>
	hasUnknownUris(server.storage);

Uri[] allUnknownUris(ref Alloc alloc, in Server server) =>
	allUnknownUris(alloc, server.storage);

ExitCode buildAndInterpret(
	ref Alloc alloc,
	ref Perf perf,
	ref Server server,
	in Extern extern_,
	in WriteError writeError,
	Uri main,
	in SafeCStr[] allArgs,
) {
	verify(!hasUnknownUris(server));
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

void setIncludeDir(ref Server server, Uri uri) {
	lateSet!Uri(server.includeDir_, uri);
}

void setCwd(ref Server server, Uri uri) {
	lateSet!UrisInfo(server.urisInfo_, UrisInfo(some(uri)));
}

void setDiagOptions(ref Server server, in ShowOptions options) {
	lateSet!ShowOptions(server.diagOptions_, options);
}

void addOrChangeFileFromTempString(ref Server server, Uri uri, in SafeCStr value) {
	setFile(server.storage, uri, ReadFileResult(allocateToStorage(server.storage, value)));
}

void addOrChangeFile(ref Server server, Uri uri, ReadFileResult value) {
	setFile(server.storage, uri, value);
}

void deleteFile(ref Server server, Uri uri) {
	deleteFile(server.storage, uri);
}

Opt!FileContent getFile(ref Alloc alloc, in Server server, Uri uri) =>
	getFileNoMarkUnknown(alloc, server.storage, uri);

void justParseEverything(ref Alloc alloc, ref Perf perf, ref Server server, in Uri[] rootUris) {
	parseAllFiles(alloc, perf, server.allSymbols, server.allUris, server.storage, server.includeDir, rootUris);
}

Program typeCheckAllKnownFiles(ref Alloc alloc, ref Perf perf, ref Server server) =>
	justTypeCheck(alloc, perf, server, allKnownGoodUris(alloc, server.storage));

Program justTypeCheck(ref Alloc alloc, ref Perf perf, ref Server server, in Uri[] rootUris) =>
	frontendCompile(alloc, perf, server, rootUris, none!Uri);

SafeCStr showDiagnostic(ref Alloc alloc, scope ref Server server, in Program program, in Diagnostic a) {
	ShowCtx ctx = getShowDiagCtx(server, program);
	return strOfDiagnostic(alloc, ctx, a);
}

SafeCStr showDiagnostics(ref Alloc alloc, scope ref Server server, in Program program) {
	ShowCtx ctx = getShowDiagCtx(server, program);
	return strOfDiagnostics(alloc, ctx, program.diagnostics);
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

private Program frontendCompile(ref Alloc alloc, ref Perf perf, ref Server server, in Uri[] rootUris, Opt!Uri main) =>
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
	in Uri uri,
) =>
	withFileContent!TokensAndParseDiagnostics(server.storage, uri, (in ReadFileResult x) {
		SafeCStr text = x.isA!FileContent ? asSafeCStr(x.as!FileContent) : safeCStr!"";
		DiagnosticsBuilder diags = DiagnosticsBuilder(&alloc);
		DiagnosticsBuilderForFile diagsForFile = DiagnosticsBuilderForFile(&diags, uri);
		FileAst ast = parseFile(alloc, perf, server.allSymbols, server.allUris, diagsForFile, text);
		return TokensAndParseDiagnostics(
			tokensOfAst(alloc, server.allSymbols, ast),
			fakeProgramForDiagnostics(finishDiagnostics(diags, server.allUris)));
	});

struct ProgramAndDefinition {
	Program program;
	Opt!Definition definition;
}

ProgramAndDefinition getDefinition(ref Perf perf, ref Alloc alloc, ref Server server, in Uri uri, Pos pos) {
	Program program = getProgram(perf, alloc, server, uri);
	Opt!Position position = getPosition(server, program, uri, pos);
	Opt!Definition definition = has(position)
		? getDefinitionForPosition(program, force(position))
		: none!Definition;
	return ProgramAndDefinition(program, definition);
}

SafeCStr getHover(ref Perf perf, ref Alloc alloc, ref Server server, in Uri uri, Pos pos) {
	Program program = getProgram(perf, alloc, server, uri);
	Opt!Position position = getPosition(server, program, uri, pos);
	ShowCtx ctx = getShowDiagCtx(server, program);
	return has(position)
		? getHoverStr(alloc, ctx, force(position))
		: safeCStr!"";
}

private Program getProgram(ref Perf perf, ref Alloc alloc, ref Server server, Uri root) =>
	frontendCompile(alloc, perf, server, [root], none!Uri);

private Opt!Position getPosition(in Server server, ref Program program, Uri uri, Pos pos) {
	Opt!(immutable Module*) module_ = program.allModules[uri];
	return has(module_)
		? some(getPosition(server.allSymbols, force(module_), pos))
		: none!Position;
}

Uri toUri(ref Server server, in SafeCStr uri) =>
	parseUri(server.allUris, uri);

struct DiagsAndResultJson {
	SafeCStr diagnostics;
	Json result;
}

private DiagsAndResultJson diagsAndResultJson(ref Alloc alloc, ref Server server, in Program program, Json result) =>
	DiagsAndResultJson(showDiagnostics(alloc, server, program), result);

DiagsAndResultJson printTokens(ref Alloc alloc, ref Perf perf, ref Server server, Uri uri) {
	FileAstAndDiagnostics astResult = parseSingleAst(
		alloc, perf, server.allSymbols, server.allUris, server.storage, uri);
	return diagsAndResultJson(
		alloc, server, fakeProgramForDiagnostics(astResult.diagnostics),
		jsonOfTokens(alloc, tokensOfAst(alloc, server.allSymbols, astResult.ast)));
}

DiagsAndResultJson printAst(ref Alloc alloc, ref Perf perf, ref Server server, Uri uri) {
	FileAstAndDiagnostics astResult = parseSingleAst(
		alloc, perf, server.allSymbols, server.allUris, server.storage, uri);
	return diagsAndResultJson(
		alloc,
		server,
		fakeProgramForDiagnostics(astResult.diagnostics),
		jsonOfAst(alloc, server.allUris, astResult.ast));
}

DiagsAndResultJson printModel(ref Alloc alloc, ref Perf perf, ref Server server, Uri uri) {
	Program program = frontendCompile(alloc, perf, server, [uri], none!Uri);
	return diagsAndResultJson(alloc, server, program, jsonOfModule(alloc, server.allUris, *only(program.rootModules)));
}

DiagsAndResultJson printConcreteModel(
	ref Alloc alloc,
	ref Perf perf,
	ref Server server,
	in VersionInfo versionInfo,
	Uri uri,
) {
	Program program = frontendCompile(alloc, perf, server, [uri], none!Uri);
	ShowCtx ctx = getShowDiagCtx(server, program);
	return diagsAndResultJson(
		alloc, server, program,
		jsonOfConcreteProgram(alloc, concretize(alloc, perf, ctx, versionInfo, program)));
}

DiagsAndResultJson printLowModel(
	ref Alloc alloc,
	ref Perf perf,
	ref Server server,
	in VersionInfo versionInfo,
	Uri uri,
) {
	Program program = frontendCompile(alloc, perf, server, [uri], none!Uri);
	ShowCtx ctx = getShowDiagCtx(server, program);
	ConcreteProgram concreteProgram = concretize(alloc, perf, ctx, versionInfo, program);
	LowProgram lowProgram = lower(alloc, perf, server.allSymbols, program.config.extern_, program, concreteProgram);
	return diagsAndResultJson(alloc, server, program, jsonOfLowProgram(alloc, lowProgram));
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
