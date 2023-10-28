module lib.server;

@safe @nogc nothrow: // not pure

import backend.writeToC : writeToC;
import concretize.concretize : concretize;
import document.document : documentJSON;
import frontend.diagnosticsBuilder : diagnosticsForFile;
import frontend.frontendCompile : frontendCompile, FileAstAndDiagnostics, parseAllFiles, parseSingleAst;
import frontend.ide.getDefinition : Definition, getDefinitionForPosition;
import frontend.ide.getHover : getHoverStr;
import frontend.ide.getPosition : getPosition, Position;
import frontend.ide.getTokens : jsonOfTokens, Token, tokensOfAst;
import frontend.parse.ast : FileAst;
import frontend.parse.jsonOfAst : jsonOfAst;
import frontend.parse.parse : parseFile;
import frontend.showDiag : ShowDiagOptions, strOfDiagnostic, strOfDiagnostics;
import interpret.bytecode : ByteCode;
import interpret.extern_ : Extern, ExternFunPtrsForAllLibraries, WriteError;
import interpret.fakeExtern : Pipe, withFakeExtern, WriteCb;
import interpret.generateBytecode : generateBytecode;
import interpret.runBytecode : runBytecode;
import lower.lower : lower;
import model.concreteModel : ConcreteProgram;
import model.diag :
	Diagnostic, Diagnostics, diagnosticsIsFatal, DiagnosticWithinFile, DiagSeverity, FilesInfo, diagnosticsIsEmpty;
import model.jsonOfConcreteModel : jsonOfConcreteProgram;
import model.jsonOfLowModel : jsonOfLowProgram;
import model.jsonOfModel : jsonOfModule;
import model.lowModel : ExternLibraries, LowProgram;
import model.model : fakeProgramForDiagnostics, Program;
import util.alloc.alloc : Alloc;
import util.col.arr : only;
import util.col.arrBuilder : ArrBuilder;
import util.col.arrUtil : arrLiteral, map;
import util.col.map : mapLiteral;
import util.col.fullIndexMap : fullIndexMapOfArr;
import util.col.str : SafeCStr, safeCStr, safeCStrIsEmpty, strOfSafeCStr;
import util.exitCode : ExitCode;
import util.json : Json;
import util.late : Late, lateGet, lateSet;
import util.lineAndColumnGetter : LineAndColumnGetter, lineAndColumnGetterForText;
import util.opt : force, has, none, Opt, some;
import util.perf : Perf;
import util.storage :
	allocateToStorage,
	asOption,
	asSafeCStr,
	deleteFile,
	emptyFileContent,
	FileContent,
	getFileNoMarkUnknown,
	getOneUnknownUri,
	hasUnknownUris,
	ReadFileResult,
	Storage,
	setFile,
	withFileContent;
import util.sourceRange : FileIndex, Pos, RangeWithinFile;
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

bool hasUnknownUris(in Server server) =>
	hasUnknownUris(server.storage);

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
	ProgramsAndFilesInfo programs = buildToLowProgram(alloc, perf, server, versionInfoForInterpret, main);
	SafeCStr diags = showDiagnostics(alloc, server, programs.program);
	if (!safeCStrIsEmpty(diags))
		writeError(diags);
	if (diagnosticsIsFatal(programs.program.diagnostics))
		return ExitCode.error;
	else {
		Opt!ExternFunPtrsForAllLibraries externFunPtrs =
			extern_.loadExternFunPtrs(programs.lowProgram.externLibraries, writeError);
		if (has(externFunPtrs)) {
			ByteCode byteCode = generateBytecode(
				alloc, perf, server.allSymbols,
				programs.program, programs.lowProgram, force(externFunPtrs), extern_.makeSyntheticFunPtrs);
			return ExitCode(runBytecode(
				perf,
				alloc,
				server.allSymbols,
				server.allUris,
				server.urisInfo,
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

pure:

struct Server {
	@safe @nogc pure nothrow:

	Alloc alloc;
	AllSymbols allSymbols;
	AllUris allUris;
	private Late!Uri includeDir_;
	private Late!UrisInfo urisInfo_;
	private Late!ShowDiagOptions diagOptions_;
	Storage storage;

	@trusted this(Alloc a) {
		alloc = a.move();
		allSymbols = AllSymbols(&alloc);
		allUris = AllUris(&alloc, &allSymbols);
		storage = Storage(&alloc);
	}

	ref Uri includeDir() return scope const =>
		lateGet(includeDir_);
	ref UrisInfo urisInfo() return scope const =>
		lateGet(urisInfo_);
	ref ShowDiagOptions diagOptions() return scope const =>
		lateGet(diagOptions_);
}

void setIncludeDir(ref Server server, Uri uri) {
	lateSet!Uri(server.includeDir_, uri);
}

void setCwd(ref Server server, Uri uri) {
	lateSet!UrisInfo(server.urisInfo_, UrisInfo(some(uri)));
}

void setDiagOptions(ref Server server, in ShowDiagOptions options) {
	lateSet!ShowDiagOptions(server.diagOptions_, options);
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

Opt!Uri getOneUnknownUri(in Server server) =>
	getOneUnknownUri(server.storage);

void justParseEverything(ref Alloc alloc, ref Perf perf, ref Server server, in Uri[] rootUris) {
	parseAllFiles(alloc, perf, server.allSymbols, server.allUris, server.storage, server.includeDir, rootUris);
}

Opt!SafeCStr justTypeCheck(ref Alloc alloc, ref Perf perf, ref Server server, in Uri[] rootUris) {
	Program program = frontendCompile(alloc, perf, server, rootUris, none!Uri);
	return diagnosticsIsEmpty(program.diagnostics)
		? none!SafeCStr
		: some(showDiagnostics(alloc, server, program));
}

private SafeCStr showDiagnostic(ref Alloc alloc, in Server server, in Program program, in Diagnostic a) =>
	strOfDiagnostic(alloc, server.allSymbols, server.allUris, server.urisInfo, server.diagOptions, program, a);

SafeCStr showDiagnostics(ref Alloc alloc, in Server server, in Program program) =>
	strOfDiagnostics(alloc, server.allSymbols, server.allUris, server.urisInfo, server.diagOptions, program);

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
	StrParseDiagnostic[] parseDiagnostics;
}

immutable struct StrParseDiagnostic {
	RangeWithinFile range;
	SafeCStr message;
}

TokensAndParseDiagnostics getTokensAndParseDiagnostics(
	ref Alloc alloc,
	scope ref Perf perf,
	ref Server server,
	in Uri uri,
) =>
	withFileContent!TokensAndParseDiagnostics(server.storage, uri, (in ReadFileResult x) {
		Opt!FileContent content = asOption(x);
		SafeCStr text = has(content) ? asSafeCStr(force(content)) : safeCStr!"";
		ArrBuilder!DiagnosticWithinFile diagnosticsBuilder;
		FileAst ast = parseFile(alloc, perf, server.allUris, server.allSymbols, diagnosticsBuilder, text);
		//TODO: use 'scope' to avoid allocating things here
		FilesInfo filesInfo = FilesInfo(
			fullIndexMapOfArr!(FileIndex, Uri)(arrLiteral!Uri(alloc, [uri])),
			mapLiteral!(Uri, FileIndex)(alloc, uri, FileIndex(0)),
			fullIndexMapOfArr!(FileIndex, LineAndColumnGetter)(
				arrLiteral!LineAndColumnGetter(alloc, [lineAndColumnGetterForText(alloc, text)])));
		Program program = fakeProgramForDiagnostics(filesInfo, Diagnostics(
			DiagSeverity.parseError,
			diagnosticsForFile(alloc, FileIndex(0), diagnosticsBuilder, server.allUris, filesInfo.fileUris).diags));
		return TokensAndParseDiagnostics(
			tokensOfAst(alloc, server.allSymbols, ast),
			map(alloc, program.diagnostics.diags, (ref Diagnostic x) =>
				StrParseDiagnostic(
					x.where.range,
					showDiagnostic(alloc, server, program, x))));
	});

Opt!Definition getDefinition(ref Perf perf, ref Alloc alloc, ref Server server, in Uri uri, Pos pos) {
	Program program = getProgram(perf, alloc, server, uri);
	Opt!Position position = getPosition(server, program, uri, pos);
	return has(position)
		? getDefinitionForPosition(program, force(position))
		: none!Definition;
}

SafeCStr getHover(ref Perf perf, ref Alloc alloc, ref Server server, in Uri uri, Pos pos) {
	Program program = getProgram(perf, alloc, server, uri);
	Opt!Position position = getPosition(server, program, uri, pos);
	return has(position)
		? getHoverStr(alloc, alloc, server.allSymbols, server.allUris, server.urisInfo, program, force(position))
		: safeCStr!"";
}

private Program getProgram(ref Perf perf, ref Alloc alloc, ref Server server, Uri root) =>
	frontendCompile(alloc, perf, server, [root], none!Uri);

private Opt!Position getPosition(in Server server, ref Program program, Uri uri, Pos pos) {
	Opt!FileIndex fileIndex = program.filesInfo.uriToFile[uri];
	return has(fileIndex)
		? some(getPosition(server.allSymbols, &program.allModules[force(fileIndex).index], pos))
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
		alloc, server, fakeProgram(astResult),
		jsonOfTokens(alloc, tokensOfAst(alloc, server.allSymbols, astResult.ast)));
}

DiagsAndResultJson printAst(ref Alloc alloc, ref Perf perf, ref Server server, Uri uri) {
	FileAstAndDiagnostics astResult = parseSingleAst(
		alloc, perf, server.allSymbols, server.allUris, server.storage, uri);
	return diagsAndResultJson(alloc, server, fakeProgram(astResult), jsonOfAst(alloc, server.allUris, astResult.ast));
}

private Program fakeProgram(FileAstAndDiagnostics a) =>
	fakeProgramForDiagnostics(a.filesInfo, a.diagnostics);

DiagsAndResultJson printModel(ref Alloc alloc, ref Perf perf, ref Server server, Uri uri) {
	Program program = frontendCompile(alloc, perf, server, [uri], none!Uri);
	return diagsAndResultJson(alloc, server, program, jsonOfModule(alloc, *only(program.rootModules)));
}

DiagsAndResultJson printConcreteModel(
	ref Alloc alloc,
	ref Perf perf,
	ref Server server,
	in VersionInfo versionInfo,
	Uri uri,
) {
	Program program = frontendCompile(alloc, perf, server, [uri], none!Uri);
	return diagsAndResultJson(
		alloc, server, program,
		jsonOfConcreteProgram(alloc, concretize(alloc, perf, versionInfo, server.allSymbols, program)));
}

DiagsAndResultJson printLowModel(
	ref Alloc alloc,
	ref Perf perf,
	ref Server server,
	in VersionInfo versionInfo,
	Uri uri,
) {
	Program program = frontendCompile(alloc, perf, server, [uri], none!Uri);
	ConcreteProgram concreteProgram = concretize(alloc, perf, versionInfo, server.allSymbols, program);
	LowProgram lowProgram = lower(alloc, perf, server.allSymbols, program.config.extern_, program, concreteProgram);
	return diagsAndResultJson(alloc, server, program, jsonOfLowProgram(alloc, lowProgram));
}

immutable struct ProgramsAndFilesInfo {
	Program program;
	ConcreteProgram concreteProgram;
	LowProgram lowProgram;
}

ProgramsAndFilesInfo buildToLowProgram(
	ref Alloc alloc,
	ref Perf perf,
	ref Server server,
	in VersionInfo versionInfo,
	Uri main,
) {
	Program program = frontendCompile(alloc, perf, server, [main], some(main));
	ConcreteProgram concreteProgram = concretize(alloc, perf, versionInfo, server.allSymbols, program);
	LowProgram lowProgram = lower(alloc, perf, server.allSymbols, program.config.extern_, program, concreteProgram);
	return ProgramsAndFilesInfo(program, concreteProgram, lowProgram);
}

immutable struct BuildToCResult {
	SafeCStr cSource;
	SafeCStr diagnostics;
	ExternLibraries externLibraries;
}
BuildToCResult buildToC(ref Alloc alloc, ref Perf perf, ref Server server, Uri main) {
	ProgramsAndFilesInfo programs = buildToLowProgram(alloc, perf, server, versionInfoForBuildToC, main);
	return BuildToCResult(
		diagnosticsIsFatal(programs.program.diagnostics)
			? safeCStr!""
			: writeToC(alloc, alloc, server.allSymbols, programs.program, programs.lowProgram),
		showDiagnostics(alloc, server, programs.program),
		programs.lowProgram.externLibraries);
}
