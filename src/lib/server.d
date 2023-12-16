module lib.server;

@safe @nogc nothrow: // not pure

import backend.writeToC : writeToC;
import concretize.concretize : concretize;
import document.document : documentJSON;
import frontend.frontendCompile :
	FrontendCompiler, getFileContents, initFrontend, makeProgramForRoots, makeProgramForMain, onFileChanged, perfStats;
import frontend.getDiagnosticSeverity : getDiagnosticSeverity;
import frontend.ide.getDefinition : getDefinitionForPosition;
import frontend.ide.getHover : getHover;
import frontend.ide.getPosition : getPosition;
import frontend.ide.getRename : getRenameForPosition;
import frontend.ide.getReferences : getReferencesForPosition;
import frontend.ide.getTokens : jsonOfDecodedTokens, tokensOfAst;
import frontend.ide.position : Position;
import frontend.lang : crowExtension;
import frontend.showDiag :
	sortedDiagnostics, stringOfDiag, stringOfDiagnostics, stringOfParseDiagnostics, UriAndDiagnostics;
import frontend.showModel : ShowCtx, ShowOptions;
import frontend.storage :
	allKnownGoodCrowUris,
	allStorageUris,
	allUrisWithFileDiag,
	changeFile,
	FilesState,
	filesState,
	getParsedOrDiag,
	LineAndColumnGetters,
	ParseResult,
	ReadFileResult,
	setFile,
	Storage,
	toLineAndCharacter;
import interpret.bytecode : ByteCode;
import interpret.extern_ : Extern, ExternFunPtrsForAllLibraries, WriteError;
import interpret.fakeExtern : withFakeExtern, WriteCb;
import interpret.generateBytecode : generateBytecode;
import interpret.runBytecode : runBytecode;
import lib.cliParser : PrintKind;
import lib.lsp.lspToJson : jsonOfHover, jsonOfReferences, jsonOfRename;
import lib.lsp.lspTypes :
	DefinitionParams,
	DidChangeTextDocumentParams,
	DidCloseTextDocumentParams,
	DidOpenTextDocumentParams,
	DidSaveTextDocumentParams,
	ExitParams,
	Hover,
	HoverParams,
	InitializedParams,
	InitializeParams,
	InitializeResult,
	LspDiagnostic,
	LspDiagnosticSeverity,
	LspInMessage,
	LspInNotification,
	LspInRequest,
	LspInRequestParams,
	LspOutAction,
	LspOutMessage,
	LspOutNotification,
	LspOutResponse,
	LspOutResult,
	Pipe,
	PublishDiagnosticsParams,
	ReadFileResultParams,
	ReadFileResultType,
	ReferenceParams,
	RegisterCapability,
	RenameParams,
	RunParams,
	RunResult,
	SemanticTokens,
	SemanticTokensParams,
	SetTraceParams,
	ShutdownParams,
	TextDocumentContentChangeEvent,
	TextDocumentIdentifier,
	TextDocumentPositionParams,
	UnloadedUris,
	UnloadedUrisParams,
	UnknownUris,
	WorkspaceEdit,
	Write;
import lower.lower : lower;
import model.ast : fileAstForReadFileDiag, FileAst;
import model.concreteModel : ConcreteProgram;
import model.diag : Diagnostic, DiagnosticSeverity, ReadFileDiag;
import model.jsonOfAst : jsonOfAst;
import model.jsonOfConcreteModel : jsonOfConcreteProgram;
import model.jsonOfLowModel : jsonOfLowProgram;
import model.jsonOfModel : jsonOfModule;
import model.lowModel : ExternLibraries, LowProgram;
import model.model : hasFatalDiagnostics, Module, Program, ProgramWithMain;
import util.alloc.alloc : Alloc, AllocKind, FetchMemoryCb, freeElements, MetaAlloc, newAlloc, withTempAllocImpure;
import util.col.arr : only;
import util.col.arrBuilder : add, ArrBuilder, finishArr;
import util.col.arrUtil : concatenate, contains, map, mapOp, newArray;
import util.exitCode : ExitCode;
import util.json : field, Json, jsonNull, jsonObject;
import util.late : Late, lateGet, lateSet, MutLate;
import util.lineAndColumnGetter : UriLineAndColumn;
import util.opt : force, has, none, Opt, some;
import util.perf : Perf;
import util.sourceRange : UriAndRange;
import util.string : copyString, CString, cString, cStringIsEmpty, stringOfCString;
import util.symbol : AllSymbols;
import util.uri : AllUris, getExtension, Uri, UrisInfo;
import util.util : castNonScope, castNonScope_ref, ptrTrustMe;
import util.writer : withWriter, Writer;
import versionInfo : VersionInfo, versionInfoForBuildToC, versionInfoForInterpret;

ExitCode buildAndInterpret(
	scope ref Perf perf,
	ref Server server,
	in Extern extern_,
	in WriteError writeError,
	Uri main,
	in CString[] allArgs,
) {
	assert(filesState(server) == FilesState.allLoaded);
	return withTempAllocImpure!ExitCode(server.metaAlloc, AllocKind.buildToLowProgram, (ref Alloc buildAlloc) {
		Programs programs = buildToLowProgram(perf, buildAlloc, server, versionInfoForInterpret, main);
		CString diags = showDiagnostics(buildAlloc, server, programs.program);
		if (!cStringIsEmpty(diags))
			writeError(diags);
		if (!has(programs.lowProgram))
			return ExitCode.error;
		else {
			LowProgram lowProgram = force(programs.lowProgram);
			Opt!ExternFunPtrsForAllLibraries externFunPtrs =
				extern_.loadExternFunPtrs(lowProgram.externLibraries, writeError);
			if (has(externFunPtrs))
				return withTempAllocImpure!ExitCode(server.metaAlloc, AllocKind.interpreter, (ref Alloc bytecodeAlloc) {
					ByteCode byteCode = generateBytecode(
						perf, bytecodeAlloc, server.allSymbols,
						programs.program, lowProgram, force(externFunPtrs), extern_.makeSyntheticFunPtrs);
					ShowCtx printCtx = getShowDiagCtx(server, programs.program);
					return ExitCode(runBytecode(
						perf, bytecodeAlloc, printCtx, extern_.doDynCall, lowProgram, byteCode, allArgs));
				});
			else {
				writeError(cString!"Failed to load external libraries\n");
				return ExitCode.error;
			}
		}
	});
}

alias CbHandleUnknownUris = void delegate() @safe @nogc nothrow;

LspOutAction handleLspMessage(
	scope ref Perf perf,
	ref Alloc alloc,
	ref Server server,
	in LspInMessage message,
	in Opt!CbHandleUnknownUris cb,
) =>
	message.matchImpure!LspOutAction(
		(in LspInNotification x) =>
			handleLspNotification(perf, alloc, server, x, cb),
		(in LspInRequest x) =>
			LspOutAction(
				newArray!LspOutMessage(alloc, [
					LspOutMessage(LspOutResponse(x.id, handleLspRequest(perf, alloc, server, x.params)))]),
				none!ExitCode));

private LspOutAction handleLspNotification(
	scope ref Perf perf,
	ref Alloc alloc,
	ref Server server,
	in LspInNotification a,
	in Opt!CbHandleUnknownUris cb,
) =>
	a.matchImpure!LspOutAction(
		(in DidChangeTextDocumentParams x) {
			changeFile(perf, server, x.textDocument.uri, x.contentChanges);
			return handleFileChanged(perf, alloc, server, x.textDocument.uri, cb);
		},
		(in DidCloseTextDocumentParams x) =>
			LspOutAction([]),
		(in DidOpenTextDocumentParams x) {
			setFile(perf, server, x.textDocument.uri, x.textDocument.text);
			return handleFileChanged(perf, alloc, server, x.textDocument.uri, cb);
		},
		(in DidSaveTextDocumentParams x) =>
			LspOutAction([]),
		(in ExitParams x) =>
			LspOutAction([], some(ExitCode.ok)),
		(in InitializedParams x) =>
			initializedAction(alloc),
		(in ReadFileResultParams x) {
			setFile(perf, server, x.uri, readFileDiagOfReadFileResultType(x.type));
			return handleFileChanged(perf, alloc, server, x.uri, cb);
		},
		(in SetTraceParams _) =>
			// TODO: implement this
			LspOutAction([]));

private LspOutAction handleFileChanged(
	scope ref Perf perf,
	ref Alloc alloc,
	ref Server server,
	Uri changed,
	in Opt!CbHandleUnknownUris cb,
) {
	if (has(cb)) {
		force(cb)();
		assert(filesState(server) == FilesState.allLoaded);
	}
	final switch (filesState(server)) {
		case FilesState.hasUnknown:
			Uri[] unknown = allUnknownUris(alloc, server);
			foreach (Uri uri; unknown)
				setFile(perf, server, uri, ReadFileDiag.loading);
			return LspOutAction(newArray!LspOutMessage(alloc, [notification(UnknownUris(unknown))]));
		case FilesState.hasLoading:
			return LspOutAction([]);
		case FilesState.allLoaded:
			return notifyDiagnostics(perf, alloc, server);
	}
}

private LspOutResult handleLspRequest(
	scope ref Perf perf,
	ref Alloc alloc,
	ref Server server,
	in LspInRequestParams a,
) =>
	a.matchImpure!LspOutResult(
		(in DefinitionParams x) =>
			LspOutResult(getDefinitionForProgram(
				alloc, server, getProgram(perf, alloc, server, [x.params.textDocument.uri]), x)),
		(in HoverParams x) =>
			LspOutResult(getHoverForProgram(
				alloc, server, getProgram(perf, alloc, server, [x.params.textDocument.uri]), x)),
		(in InitializeParams x) =>
			LspOutResult(InitializeResult()),
		(in ReferenceParams x) =>
			LspOutResult(getReferencesForProgram(alloc, server, getProgramForAll(perf, alloc, server), x)),
		(in RenameParams x) =>
			LspOutResult(getRenameForProgram(alloc, server, getProgramForAll(perf, alloc, server), x)),
		(in RunParams x) {
			ArrBuilder!Write writes;
			ExitCode exitCode = run(perf, alloc, server, x.uri, (Pipe pipe, in string x) {
				add(alloc, writes, Write(pipe, copyString(alloc, x)));
			});
			return LspOutResult(RunResult(exitCode, finishArr(alloc, writes)));
		},
		(in SemanticTokensParams x) {
			Uri uri = x.textDocument.uri;
			return LspOutResult(getTokens(alloc, server, uri, *getAst(alloc, server, uri)));
		},
		(in ShutdownParams _) =>
			LspOutResult(LspOutResult.Null()),
		(in UnloadedUrisParams) =>
			LspOutResult(UnloadedUris(allUnloadedUris(alloc, server))));

private ExitCode run(scope ref Perf perf, ref Alloc alloc, ref Server server, Uri main, in WriteCb writeCb) {
	// TODO: use an arena so anything allocated during interpretation is cleaned up.
	// Or just have interpreter free things.
	CString[1] allArgs = [cString!"/usr/bin/fakeExecutable"];
	return withFakeExtern(alloc, server.allSymbols, writeCb, (scope ref Extern extern_) =>
		buildAndInterpret(
			perf, server, extern_,
			(in CString x) {
				writeCb(Pipe.stderr, stringOfCString(x));
			},
			main, allArgs));
}

pure:

struct Server {
	@safe @nogc pure nothrow:

	MetaAlloc metaAlloc_;
	AllSymbols allSymbols;
	AllUris allUris;
	private Late!Uri includeDir_;
	private Late!UrisInfo urisInfo_;
	ShowOptions showOptions_ = ShowOptions(false);
	Storage storage;
	LspState lspState;
	MutLate!(FrontendCompiler*) frontend_;

	@trusted this(return scope FetchMemoryCb fetch) {
		metaAlloc_ = MetaAlloc(fetch);
		allSymbols = AllSymbols(newAlloc(AllocKind.allSymbols, metaAlloc));
		allUris = AllUris(newAlloc(AllocKind.allUris, metaAlloc), &allSymbols);
		storage = Storage(metaAlloc, &allSymbols, &allUris);
		lspState = LspState(newAlloc(AllocKind.lspState, metaAlloc), []);
	}

	inout(MetaAlloc*) metaAlloc() inout =>
		castNonScope(&metaAlloc_);
	Uri includeDir() scope const =>
		lateGet(includeDir_);
	ref UrisInfo urisInfo() return scope const =>
		lateGet(urisInfo_);
	ref inout(FrontendCompiler) frontend() return scope inout =>
		*lateGet(frontend_);
	ShowOptions showOptions() scope const =>
		showOptions_;
	LineAndColumnGetters lineAndColumnGetters() return scope const =>
		LineAndColumnGetters(&castNonScope_ref(storage));
}

Json perfStats(ref Alloc alloc, in Server a) =>
	jsonObject(alloc, [
		field!"frontend"(perfStats(alloc, a.frontend))]);

private struct LspState {
	@safe @nogc pure nothrow:

	Alloc* stateAllocPtr;
	Uri[] urisWithDiagnostics;

	ref inout(Alloc) stateAlloc() return scope inout =>
		*stateAllocPtr;
}

CString version_(ref Alloc alloc, in Server server) =>
	withWriter(alloc, (scope ref Writer writer) {
		static immutable string date = import("date.txt")[0 .. "2020-02-02".length];
		static immutable string commitHash = import("commit-hash.txt")[0 .. 8];

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
	});

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

void setIncludeDir(Server* server, Uri uri) {
	lateSet!Uri(server.includeDir_, uri);
	lateSet!(FrontendCompiler*)(
		server.frontend_,
		initFrontend(server.metaAlloc, &server.allSymbols, &server.allUris, &server.storage, uri));
}

void setCwd(ref Server server, Uri uri) {
	lateSet!UrisInfo(server.urisInfo_, UrisInfo(some(uri)));
}

void setShowOptions(ref Server server, in ShowOptions options) {
	server.showOptions_ = options;
}

void setFile(scope ref Perf perf, ref Server server, Uri uri, in ReadFileResult result) {
	setFile(perf, server.storage, uri, result);
	onFileChanged(perf, server.frontend, uri);
}
void setFile(scope ref Perf perf, ref Server server, Uri uri, in string result) {
	setFile(perf, server.storage, uri, result);
	onFileChanged(perf, server.frontend, uri);
}
void setFile(scope ref Perf perf, ref Server server, Uri uri, ReadFileDiag diag) {
	setFile(perf, server, uri, ReadFileResult(diag));
}

void changeFile(scope ref Perf perf, ref Server server, Uri uri, in TextDocumentContentChangeEvent[] changes) {
	changeFile(perf, server.storage, uri, changes);
	onFileChanged(perf, server.frontend, uri);
}

FilesState filesState(in Server server) =>
	filesState(server.storage);

Uri[] allStorageUris(ref Alloc alloc, in Server server) =>
	allStorageUris(alloc, server.storage);
Uri[] allUnknownUris(ref Alloc alloc, in Server server) =>
	allUrisWithFileDiag(alloc, server.storage, [ReadFileDiag.unknown]);
private Uri[] allUnloadedUris(ref Alloc alloc, in Server server) =>
	allUrisWithFileDiag(alloc, server.storage, [ReadFileDiag.unknown, ReadFileDiag.loading]);

CString showDiagnostics(ref Alloc alloc, scope ref Server server, in Program program) {
	ShowCtx ctx = getShowDiagCtx(server, program);
	return stringOfDiagnostics(alloc, ctx, program);
}

immutable struct DocumentResult {
	CString document;
	CString diagnostics;
}

DocumentResult getDocumentation(scope ref Perf perf, ref Alloc alloc, ref Server server, in Uri[] uris) {
	Program program = getProgram(perf, alloc, server, uris);
	return DocumentResult(
		documentJSON(alloc, server.allSymbols, server.allUris, program),
		showDiagnostics(alloc, server, program));
}

private UriAndRange[] getDefinitionForProgram(
	ref Alloc alloc,
	scope ref Server server,
	in Program program,
	in DefinitionParams params,
) {
	Opt!Position position = getPosition(server, program, params.params);
	return has(position)
		? getDefinitionForPosition(alloc, server.allSymbols, program, force(position))
		: [];
}

private UriAndRange[] getReferencesForProgram(
	ref Alloc alloc,
	scope ref Server server,
	in Program program,
	in ReferenceParams params,
) {
	Opt!Position position = getPosition(server, program, params.params);
	return has(position)
		? getReferencesForPosition(alloc, server.allSymbols, server.allUris, program, force(position))
		: [];
}

private Opt!WorkspaceEdit getRenameForProgram(
	ref Alloc alloc,
	scope ref Server server,
	in Program program,
	in RenameParams params,
) {
	Opt!Position position = getPosition(server, program, params.textDocumentAndPosition);
	return has(position)
		? getRenameForPosition(alloc, server.allSymbols, server.allUris, program, force(position), params.newName)
		: none!WorkspaceEdit;
}

private Opt!Hover getHoverForProgram(
	ref Alloc alloc,
	scope ref Server server,
	in Program program,
	in HoverParams params,
) {
	Opt!Position position = getPosition(server, program, params.params);
	ShowCtx ctx = getShowDiagCtx(server, program);
	return has(position)
		? getHover(alloc, ctx, force(position))
		: none!Hover;
}

private Program getProgram(scope ref Perf perf, ref Alloc alloc, ref Server server, in Uri[] roots) =>
	makeProgramForRoots(perf, alloc, server.frontend, roots);

ProgramWithMain getProgramForMain(scope ref Perf perf, ref Alloc alloc, ref Server server, Uri mainUri) =>
	makeProgramForMain(perf, alloc, server.frontend, mainUri);

Program getProgramForAll(scope ref Perf perf, ref Alloc alloc, ref Server server) =>
	getProgram(perf, alloc, server, allKnownGoodCrowUris(alloc, server.storage));

private Opt!Position getPosition(scope ref Server server, in Program program, in TextDocumentPositionParams where) {
	Opt!(immutable Module*) module_ = program.allModules[where.textDocument.uri];
	return has(module_)
		? some(getPosition(server.allSymbols, server.allUris, force(module_), server.lineAndColumnGetters[where]))
		: none!Position;
}

struct DiagsAndResultJson {
	CString diagnostics;
	Json result;
}

private DiagsAndResultJson printForProgram(
	ref Alloc alloc,
	scope ref Server server,
	in Program program,
	Json result,
) =>
	DiagsAndResultJson(showDiagnostics(alloc, server, program), result);

private DiagsAndResultJson printForAst(ref Alloc alloc, ref Server server, Uri uri, in FileAst ast, Json result) =>
	DiagsAndResultJson(
		stringOfParseDiagnostics(
			alloc, server.allSymbols, server.allUris, server.lineAndColumnGetters[uri], ast.parseDiagnostics),
		result);

DiagsAndResultJson printTokens(ref Alloc alloc, ref Server server, in SemanticTokensParams params) {
	Uri uri = params.textDocument.uri;
	FileAst* ast = getAst(alloc, server, uri);
	return printForAst(alloc, server, uri, *ast, jsonOfDecodedTokens(alloc, getTokens(alloc, server, uri, *ast)));
}

DiagsAndResultJson printAst(scope ref Perf perf, ref Alloc alloc, ref Server server, Uri uri) {
	FileAst* ast = getAst(alloc, server, uri);
	return printForAst(
		alloc, server, uri, *ast,
		jsonOfAst(alloc, server.allUris, server.lineAndColumnGetters[uri], *ast));
}

private FileAst* getAst(ref Alloc alloc, ref Server server, Uri uri) {
	assert(getExtension(server.allUris, uri) == crowExtension);
	return getParsedOrDiag(server.storage, uri).match!(FileAst*)(
		(ParseResult x) =>
			x.as!(FileAst*),
		(ReadFileDiag x) =>
			fileAstForReadFileDiag(alloc, x));
}

DiagsAndResultJson printModel(scope ref Perf perf, ref Alloc alloc, ref Server server, Uri uri) {
	Program program = getProgram(perf, alloc, server, [uri]);
	Json json = jsonOfModule(alloc, server.allUris, server.lineAndColumnGetters[uri], *only(program.rootModules));
	return printForProgram(alloc, server, program, json);
}

DiagsAndResultJson printConcreteModel(
	scope ref Perf perf,
	ref Alloc alloc,
	ref Server server,
	in LineAndColumnGetters lineAndColumnGetters,
	in VersionInfo versionInfo,
	Uri uri,
) {
	Programs programs = buildToLowProgram(perf, alloc, server, versionInfo, uri);
	return printForProgram(
		alloc, server, programs.program,
		has(programs.concreteProgram)
			? jsonOfConcreteProgram(alloc, lineAndColumnGetters, force(programs.concreteProgram))
			: jsonNull);
}

DiagsAndResultJson printLowModel(
	scope ref Perf perf,
	ref Alloc alloc,
	ref Server server,
	in LineAndColumnGetters lineAndColumnGetters,
	in VersionInfo versionInfo,
	Uri uri,
) {
	Programs programs = buildToLowProgram(perf, alloc, server, versionInfo, uri);
	return printForProgram(
		alloc, server, programs.program,
		has(programs.lowProgram)
			? jsonOfLowProgram(alloc, lineAndColumnGetters, force(programs.lowProgram))
			: jsonNull);
}

DiagsAndResultJson printIde(
	scope ref Perf perf,
	ref Alloc alloc,
	ref Server server,
	in UriLineAndColumn where,
	PrintKind.Ide.Kind kind,
) {
	Program program = getProgram(perf, alloc, server, [where.uri]); // TODO: we should support specifying roots...
	TextDocumentPositionParams params = TextDocumentPositionParams(
		TextDocumentIdentifier(where.uri),
		toLineAndCharacter(server.lineAndColumnGetters[where.uri], where.lineAndColumn));
	return printForProgram(alloc, server, program, getPrinted(alloc, server, program, params, kind));
}

private Json getPrinted(
	ref Alloc alloc,
	ref Server server,
	in Program program,
	in TextDocumentPositionParams params,
	PrintKind.Ide.Kind kind,
) {
	Json locations(UriAndRange[] xs) =>
		jsonOfReferences(alloc, server.allUris, server.lineAndColumnGetters, xs);
	final switch (kind) {
		case PrintKind.Ide.Kind.definition:
			return locations(getDefinitionForProgram(alloc, server, program, DefinitionParams(params)));
		case PrintKind.Ide.Kind.hover:
			return jsonOfHover(alloc, getHoverForProgram(alloc, server, program, HoverParams(params)));
		case PrintKind.Ide.Kind.rename:
			Opt!WorkspaceEdit rename = getRenameForProgram(alloc, server, program, RenameParams(params, "new-name"));
			return jsonOfRename(alloc, server.allUris, server.lineAndColumnGetters, rename);
		case PrintKind.Ide.Kind.references:
			return locations(getReferencesForProgram(alloc, server, program, ReferenceParams(params)));
	}
}

immutable struct Programs {
	@safe @nogc pure nothrow:

	ProgramWithMain programWithMain;
	Opt!ConcreteProgram concreteProgram;
	Opt!LowProgram lowProgram;

	ref Program program() return =>
		programWithMain.program;
}

Programs buildToLowProgram(
	scope ref Perf perf,
	ref Alloc alloc,
	ref Server server,
	in VersionInfo versionInfo,
	Uri main,
) {
	ProgramWithMain program = getProgramForMain(perf, alloc, server, main);
	ShowCtx ctx = getShowDiagCtx(server, program.program);
	if (hasFatalDiagnostics(program))
		return Programs(program, none!ConcreteProgram, none!LowProgram);
	else {
		ConcreteProgram concreteProgram = concretize(
			perf, alloc, ctx, versionInfo, program, getFileContents(alloc, server.frontend));
		LowProgram lowProgram = lower(
			perf, alloc, server.allSymbols, program.mainConfig.extern_, program.program, concreteProgram);
		return Programs(program, some(concreteProgram), some(lowProgram));
	}
}

immutable struct BuildToCResult {
	CString cSource;
	CString diagnostics;
	ExternLibraries externLibraries;
}
BuildToCResult buildToC(scope ref Perf perf, ref Alloc alloc, ref Server server, Uri main) {
	Programs programs = buildToLowProgram(perf, alloc, server, versionInfoForBuildToC, main);
	ShowCtx ctx = getShowDiagCtx(server, programs.program);
	return BuildToCResult(
		has(programs.lowProgram)
			? writeToC(alloc, alloc, ctx, force(programs.lowProgram))
			: cString!"",
		showDiagnostics(alloc, server, programs.program),
		has(programs.lowProgram) ? force(programs.lowProgram).externLibraries : []);
}

ShowCtx getShowDiagCtx(return scope ref const Server server, return scope ref Program program) =>
	ShowCtx(
		ptrTrustMe(server.allSymbols),
		ptrTrustMe(server.allUris),
		server.lineAndColumnGetters,
		server.urisInfo,
		server.showOptions,
		ptrTrustMe(program));

private:

SemanticTokens getTokens(ref Alloc alloc, ref Server server, Uri uri, in FileAst ast) =>
	tokensOfAst(alloc, server.allSymbols, server.allUris, server.lineAndColumnGetters[uri], ast);

ReadFileDiag readFileDiagOfReadFileResultType(ReadFileResultType a) {
	final switch (a) {
		case ReadFileResultType.notFound:
			return ReadFileDiag.notFound;
		case ReadFileResultType.error:
			return ReadFileDiag.error;
	}
}

LspOutMessage notification(T)(T a) =>
	LspOutMessage(LspOutNotification(a));

LspOutAction notifyDiagnostics(scope ref Perf perf, ref Alloc alloc, ref Server server) {
	Program program = getProgramForAll(perf, alloc, server);
	UriAndDiagnostics[] diags = sortedDiagnostics(alloc, server.allUris, program);
	ref LspState state() => server.lspState;
	Uri[] newUris = map(state.stateAlloc, diags, (ref UriAndDiagnostics x) => x.uri);
	UriAndDiagnostics[] all = concatenate(
		alloc,
		diags,
		mapOp!(UriAndDiagnostics, Uri)(alloc, state.urisWithDiagnostics, (ref Uri uri) =>
			contains(newUris, uri) ? none!UriAndDiagnostics : some(UriAndDiagnostics(uri, []))));
	() @trusted {
		freeElements!Uri(state.stateAlloc, state.urisWithDiagnostics);
	}();
	state.urisWithDiagnostics = castNonScope(newUris);
	ShowCtx ctx = getShowDiagCtx(server, program);
	return LspOutAction(map!(LspOutMessage, UriAndDiagnostics)(alloc, all, (ref UriAndDiagnostics ud) =>
		notification(PublishDiagnosticsParams(ud.uri, map(alloc, ud.diagnostics, (ref Diagnostic x) =>
			LspDiagnostic(
				x.range,
				toLspDiagnosticSeverity(getDiagnosticSeverity(x.kind)),
				stringOfDiag(alloc, ctx, x.kind)))))));
}

LspDiagnosticSeverity toLspDiagnosticSeverity(DiagnosticSeverity a) {
	final switch (a) {
		case DiagnosticSeverity.unusedCode:
			return LspDiagnosticSeverity.Hint;
		case DiagnosticSeverity.checkWarning:
			return LspDiagnosticSeverity.Warning;
		case DiagnosticSeverity.checkError:
		case DiagnosticSeverity.nameNotFound:
		case DiagnosticSeverity.importError:
		case DiagnosticSeverity.commonMissing:
		case DiagnosticSeverity.parseError:
			return LspDiagnosticSeverity.Error;
	}
}

LspOutAction initializedAction(ref Alloc alloc) =>
	LspOutAction(newArray!LspOutMessage(alloc, [
		register("textDocument/definition"),
		register("textDocument/hover"),
		register("textDocument/rename"),
		register("textDocument/references"),
		register("textDocument/semanticTokens/full"),
	]));

LspOutMessage register(string method) =>
	notification(RegisterCapability(method, method));
