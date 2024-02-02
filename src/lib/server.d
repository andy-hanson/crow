module lib.server;

@safe @nogc nothrow: // not pure

import backend.writeToC : PathAndArgs, writeToC, WriteToCParams, WriteToCResult;
import concretize.concretize : concretize;
import document.document : documentJSON;
import frontend.frontendCompile :
	Frontend, initFrontend, makeProgramForRoots, makeProgramForMain, onFileChanged, perfStats;
import frontend.getDiagnosticSeverity : getDiagnosticSeverity;
import frontend.ide.getDefinition : getDefinitionForPosition;
import frontend.ide.getHover : getHover;
import frontend.ide.getPosition : getPosition;
import frontend.ide.getRename : getRenameForPosition;
import frontend.ide.getReferences : getReferencesForPosition;
import frontend.ide.getTokens : jsonOfDecodedTokens, tokensOfAst;
import frontend.ide.position : Position;
import frontend.showDiag :
	sortedDiagnostics, stringOfDiag, stringOfDiagnostics, stringOfParseDiagnostics, UriAndDiagnostics;
import frontend.showModel : ShowCtx, ShowDiagCtx, ShowOptions;
import frontend.storage :
	allKnownGoodCrowUris,
	allStorageUris,
	allUrisWithFileDiag,
	changeFile,
	FileContentGetters,
	FilesState,
	filesState,
	getSourceAndAstOrDiag,
	LineAndCharacterGetters,
	LineAndColumnGetters,
	ReadFileResult,
	setFile,
	SourceAndAst,
	Storage;
import interpret.bytecode : ByteCode;
import interpret.extern_ : Extern, ExternPointersForAllLibraries, WriteError;
import interpret.fakeExtern : withFakeExtern, WriteCb;
import interpret.generateBytecode : generateBytecode;
import interpret.runBytecode : runBytecode;
import lib.lsp.lspToJson : jsonOfHover, jsonOfReferences, jsonOfRename;
import lib.lsp.lspTypes :
	CancelRequestParams,
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
import util.col.array : concatenate, contains, isEmpty, map, mapOp, newArray, only;
import util.col.arrayBuilder : add, ArrayBuilder, finish;
import util.col.mutArr : clearAndDoNotFree, MutArr, push;
import util.exitCode : ExitCode;
import util.json : field, Json, jsonNull, jsonObject;
import util.late : Late, lateGet, lateSet, MutLate;
import util.opt : force, has, none, Opt, some;
import util.perf : Perf;
import util.sourceRange : LineAndColumn, toLineAndCharacter, UriAndRange, UriLineAndColumn;
import util.string : copyString, CString, cString;
import util.symbol : AllSymbols;
import util.uri : AllUris, Uri, UrisInfo, writeUri;
import util.union_ : Union;
import util.util : castNonScope, castNonScope_ref, ptrTrustMe;
import util.writer : debugLogWithWriter, Writer;
import versionInfo : getOS, OS, VersionInfo, versionInfoForBuildToC, versionInfoForInterpret;

ExitCode buildAndInterpret(
	scope ref Perf perf,
	ref Server server,
	in Extern extern_,
	in WriteError writeError,
	Uri main,
	in Opt!(Uri[]) diagnosticsOnlyForUris,
	in CString[] allArgs,
) {
	assert(filesState(server) == FilesState.allLoaded);
	return withTempAllocImpure!ExitCode(server.metaAlloc, AllocKind.buildToLowProgram, (ref Alloc buildAlloc) {
		Programs programs = buildToLowProgram(perf, buildAlloc, server, versionInfoForInterpret(getOS()), main);
		string diags = showDiagnostics(buildAlloc, server, programs.program, diagnosticsOnlyForUris);
		if (!isEmpty(diags))
			writeError(diags);
		if (!has(programs.lowProgram))
			return ExitCode.error;
		else {
			LowProgram lowProgram = force(programs.lowProgram);
			Opt!ExternPointersForAllLibraries externPointers =
				extern_.loadExternPointers(lowProgram.externLibraries, writeError);
			if (has(externPointers))
				return withTempAllocImpure!ExitCode(server.metaAlloc, AllocKind.interpreter, (ref Alloc bytecodeAlloc) {
					ByteCode byteCode = generateBytecode(
						perf, bytecodeAlloc, server.allSymbols, programs.program, lowProgram,
						force(externPointers), extern_.aggregateCbs, extern_.makeSyntheticFunPointers);
					ShowCtx printCtx = getShowDiagCtx(server, programs.program);
					return runBytecode(
						perf, bytecodeAlloc, printCtx, extern_.doDynCall, lowProgram, byteCode, allArgs);
				});
			else {
				writeError("Failed to load external libraries\n");
				return ExitCode.error;
			}
		}
	});
}

LspOutAction handleLspMessage(scope ref Perf perf, ref Alloc alloc, ref Server server, in LspInMessage message) =>
	message.matchImpure!LspOutAction(
		(in LspInNotification x) =>
			handleLspNotification(perf, alloc, server, x),
		(in LspInRequest x) {
			Opt!LspOutResult response = handleLspRequest(perf, alloc, server, x);
			return LspOutAction(
				has(response) ? newArray!LspOutMessage(alloc, [messageForResponse(x, force(response))]) : [],
				none!ExitCode);
		});

private LspOutMessage messageForResponse(in LspInRequest request, LspOutResult result) =>
	LspOutMessage(LspOutResponse(request.id, result));

private LspOutAction handleLspNotification(
	scope ref Perf perf,
	ref Alloc alloc,
	ref Server server,
	in LspInNotification a,
) =>
	a.matchImpure!LspOutAction(
		(in CancelRequestParams _) {
			// Ignore because according to documentation,
			// "A request that got canceled still needs to return from the server and send a response back"
			return LspOutAction([]);
		},
		(in DidChangeTextDocumentParams x) {
			changeFile(perf, server, x.textDocument.uri, x.contentChanges);
			return handleFileChanged(perf, alloc, server, x.textDocument.uri);
		},
		(in DidCloseTextDocumentParams x) =>
			LspOutAction([]),
		(in DidOpenTextDocumentParams x) {
			setFile(perf, server, x.textDocument.uri, x.textDocument.text);
			return handleFileChanged(perf, alloc, server, x.textDocument.uri);
		},
		(in DidSaveTextDocumentParams x) =>
			LspOutAction([]),
		(in ExitParams x) =>
			LspOutAction([], some(ExitCode.ok)),
		(in InitializedParams _) =>
			initializedAction(alloc, server),
		(in ReadFileResultParams x) {
			final switch (x.type) {
				case ReadFileResultType.ok:
					setFile(perf, server, x.uri, x.content);
					break;
				case ReadFileResultType.notFound:
					setFile(perf, server, x.uri, ReadFileDiag.notFound);
					break;
				case ReadFileResultType.error:
					setFile(perf, server, x.uri, ReadFileDiag.error);
					break;
			}
			return handleFileChanged(perf, alloc, server, x.uri);
		},
		(in SetTraceParams _) =>
			// TODO: implement this
			LspOutAction([]));

private LspOutAction handleFileChanged(scope ref Perf perf, ref Alloc alloc, ref Server server, Uri changed) {
	final switch (filesState(server)) {
		case FilesState.hasUnknown:
			Uri[] unknown = allUnknownUris(alloc, server);
			foreach (Uri uri; unknown)
				setFile(perf, server, uri, ReadFileDiag.loading);
			return LspOutAction(newArray!LspOutMessage(alloc, [notification(UnknownUris(unknown))]));
		case FilesState.hasLoading:
			return LspOutAction([]);
		case FilesState.allLoaded:
			Program program = getProgramForAll(perf, alloc, server);
			ArrayBuilder!LspOutMessage messages;
			foreach (LspInRequest request; server.lspState.pendingRequests)
				add(alloc, messages, messageForResponse(
					request,
					handleLspRequestWithProgram(perf, alloc, server, program, request.params)));
			clearAndDoNotFree(server.lspState.pendingRequests);
			notifyDiagnostics(perf, alloc, messages, server, program);
			return LspOutAction(finish(alloc, messages), none!ExitCode);
	}
}

// Only returns 'none' if not all files are loaded
private Opt!LspOutResult handleLspRequest(
	scope ref Perf perf,
	ref Alloc alloc,
	ref Server server,
	in LspInRequest a,
) =>
	a.params.matchImpure!(Opt!LspOutResult)(
		(in DefinitionParams x) =>
			respondWithProgram(perf, alloc, server, a),
		(in HoverParams x) =>
			respondWithProgram(perf, alloc, server, a),
		(in InitializeParams x) {
			server.lspState.supportsUnknownUris = x.initializationOptions.unknownUris;
			return some(LspOutResult(InitializeResult()));
		},
		(in ReferenceParams x) =>
			respondWithProgram(perf, alloc, server, a),
		(in RenameParams x) =>
			respondWithProgram(perf, alloc, server, a),
		(in RunParams x) =>
			respondWithProgram(perf, alloc, server, a),
		(in SemanticTokensParams x) {
			Uri uri = x.textDocument.uri;
			return some(LspOutResult(getTokens(alloc, server, uri, getSourceAndAst(alloc, server, uri))));
		},
		(in ShutdownParams _) =>
			some(LspOutResult(LspOutResult.Null())),
		(in UnloadedUrisParams) =>
			some(LspOutResult(UnloadedUris(allUnloadedUris(alloc, server)))));

private Opt!LspOutResult respondWithProgram(
	scope ref Perf perf,
	ref Alloc alloc,
	ref Server server,
	in LspInRequest request,
) {
	if (filesState(server) == FilesState.allLoaded) {
		return some(handleLspRequestWithProgram(
			perf,alloc, server, getProgramForAll(perf, alloc, server), request.params));
	} else {
		foreach (Uri uri; allUnloadedUris(alloc, server))
			debugLogWithWriter((scope ref Writer writer) {
				writer ~= "Unknown or unloaded URI: ";
				writeUri(writer, server.allUris, uri);
			});
		push(server.lspState.stateAlloc, server.lspState.pendingRequests, request);
		return none!LspOutResult;
	}
}

private LspOutResult handleLspRequestWithProgram(
	scope ref Perf perf,
	ref Alloc alloc,
	ref Server server,
	in Program program,
	in LspInRequestParams a,
) =>
	a.matchImpure!LspOutResult(
		(in DefinitionParams x) =>
			LspOutResult(getDefinitionForProgram(alloc, server, program, x)),
		(in HoverParams x) =>
			LspOutResult(getHoverForProgram(alloc, server, program, x)),
		(in InitializeParams _) =>
			assert(false),
		(in ReferenceParams x) =>
			LspOutResult(getReferencesForProgram(alloc, server, program, x)),
		(in RenameParams x) =>
			LspOutResult(getRenameForProgram(alloc, server, program, x)),
		(in RunParams x) {
			ArrayBuilder!Write writes;
			// TODO: this redundantly builds a program...
			ExitCode exitCode = run(perf, alloc, server, x.uri, x.diagnosticsOnlyForUris, (Pipe pipe, in string x) {
				add(alloc, writes, Write(pipe, copyString(alloc, x)));
			});
			return LspOutResult(RunResult(exitCode, finish(alloc, writes)));
		},
		(in SemanticTokensParams _) =>
			assert(false),
		(in ShutdownParams _) =>
			assert(false),
		(in UnloadedUrisParams _) =>
			assert(false));

private ExitCode run(
	scope ref Perf perf,
	ref Alloc alloc,
	ref Server server,
	Uri main,
	in Opt!(Uri[]) diagnosticsOnlyForUris,
	in WriteCb writeCb,
) {
	// TODO: use an arena so anything allocated during interpretation is cleaned up.
	// Or just have interpreter free things.
	CString[1] allArgs = [cString!"/usr/bin/fakeExecutable"];
	return withFakeExtern(alloc, server.allSymbols, writeCb, (scope ref Extern extern_) =>
		buildAndInterpret(
			perf, server, extern_,
			(in string x) { writeCb(Pipe.stderr, x); },
			main, diagnosticsOnlyForUris, allArgs));
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
	MutLate!(Frontend*) frontend_;

	@trusted this(return scope FetchMemoryCb fetch) {
		metaAlloc_ = MetaAlloc(fetch);
		allSymbols = AllSymbols(newAlloc(AllocKind.allSymbols, metaAlloc));
		allUris = AllUris(newAlloc(AllocKind.allUris, metaAlloc), &allSymbols);
		storage = Storage(metaAlloc, &allSymbols, &allUris);
		lspState = LspState(newAlloc(AllocKind.lspState, metaAlloc));
	}

	inout(MetaAlloc*) metaAlloc() inout =>
		castNonScope(&metaAlloc_);
	Uri includeDir() scope const =>
		lateGet(includeDir_);
	ref UrisInfo urisInfo() return scope const =>
		lateGet(urisInfo_);
	ref inout(Frontend) frontend() return scope inout =>
		*lateGet(frontend_);
	ShowOptions showOptions() scope const =>
		showOptions_;
	LineAndCharacterGetters lineAndCharacterGetters() return scope const =>
		LineAndCharacterGetters(&castNonScope_ref(storage));
	LineAndColumnGetters lineAndColumnGetters() return scope const =>
		LineAndColumnGetters(&castNonScope_ref(storage));
}

Json perfStats(ref Alloc alloc, in Server a) =>
	jsonObject(alloc, [
		field!"frontend"(perfStats(alloc, a.frontend))]);

private struct LspState {
	@safe @nogc pure nothrow:

	Alloc* stateAllocPtr;
	bool supportsUnknownUris;
	Uri[] urisWithDiagnostics;
	MutArr!LspInRequest pendingRequests;

	ref inout(Alloc) stateAlloc() return scope inout =>
		*stateAllocPtr;
}

void writeVersion(scope ref Writer writer, in Server server) {
	static immutable string date = import("date.txt")[0 .. "2020-02-02".length];
	static immutable string commitHash = import("commit-hash.txt")[0 .. 8];

	writer ~= date;
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
	version (GccJitAvailable) {} else {
		writer ~= ", does not support '--jit'";
	}
	writer ~= ", built with ";
	writer ~= dCompilerName;
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

void setIncludeDir(Server* server, Uri uri) {
	lateSet!Uri(server.includeDir_, uri);
	lateSet!(Frontend*)(
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

string showDiagnostics(
	ref Alloc alloc,
	in Server server,
	in Program program,
	in Opt!(Uri[]) onlyForUris = none!(Uri[]),
) =>
	stringOfDiagnostics(alloc, getShowDiagCtx(server, program), program, onlyForUris);

immutable struct DocumentResult {
	string document;
	string diagnostics;
}

string check(scope ref Perf perf, ref Alloc alloc, ref Server server, in Uri[] rootUris) {
	Program program = getProgram(perf, alloc, server, rootUris);
	return showDiagnostics(alloc, server, program);
}

DocumentResult getDocumentation(scope ref Perf perf, ref Alloc alloc, ref Server server, in Uri[] uris) {
	Program program = getProgram(perf, alloc, server, uris);
	return DocumentResult(
		documentJSON(alloc, server.allSymbols, server.allUris, program),
		showDiagnostics(alloc, server, program));
}

private UriAndRange[] getDefinitionForProgram(
	ref Alloc alloc,
	in Server server,
	in Program program,
	in DefinitionParams params,
) {
	Opt!Position position = getPosition(server, program, params.params);
	return has(position)
		? getDefinitionForPosition(alloc, server.allSymbols, force(position))
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
	in Server server,
	in Program program,
	in HoverParams params,
) {
	Opt!Position position = getPosition(server, program, params.params);
	return has(position)
		? getHover(alloc, getShowDiagCtx(server, program), force(position))
		: none!Hover;
}

private Program getProgram(scope ref Perf perf, ref Alloc alloc, ref Server server, in Uri[] roots) =>
	makeProgramForRoots(perf, alloc, server.frontend, roots);

ProgramWithMain getProgramForMain(scope ref Perf perf, ref Alloc alloc, ref Server server, Uri mainUri) =>
	makeProgramForMain(perf, alloc, server.frontend, mainUri);

Program getProgramForAll(scope ref Perf perf, ref Alloc alloc, ref Server server) =>
	getProgram(perf, alloc, server, allKnownGoodCrowUris(alloc, server.storage));

private Opt!Position getPosition(in Server server, in Program program, in TextDocumentPositionParams where) {
	Opt!(immutable Module*) module_ = program.allModules[where.textDocument.uri];
	return has(module_)
		? some(getPosition(server.allSymbols, server.allUris, force(module_), server.lineAndCharacterGetters[where]))
		: none!Position;
}

struct DiagsAndResultJson {
	string diagnostics;
	Json result;
}

private DiagsAndResultJson printForProgram(
	ref Alloc alloc,
	in Server server,
	in Program program,
	Json result,
) =>
	DiagsAndResultJson(showDiagnostics(alloc, server, program), result);

private DiagsAndResultJson printForAst(ref Alloc alloc, ref Server server, Uri uri, in FileAst ast, Json result) =>
	DiagsAndResultJson(
		stringOfParseDiagnostics(alloc, getShowCtx(server), uri, ast.parseDiagnostics),
		result);

DiagsAndResultJson printTokens(ref Alloc alloc, ref Server server, in SemanticTokensParams params) {
	Uri uri = params.textDocument.uri;
	SourceAndAst ast = getSourceAndAst(alloc, server, uri);
	return printForAst(alloc, server, uri, *ast.ast, jsonOfDecodedTokens(alloc, getTokens(alloc, server, uri, ast)));
}

DiagsAndResultJson printAst(scope ref Perf perf, ref Alloc alloc, ref Server server, Uri uri) {
	SourceAndAst ast = getSourceAndAst(alloc, server, uri);
	return printForAst(
		alloc, server, uri, *ast.ast,
		jsonOfAst(alloc, server.allUris, server.lineAndColumnGetters[uri], *ast.ast));
}

private SourceAndAst getSourceAndAst(ref Alloc alloc, ref Server server, Uri uri) =>
	getSourceAndAstOrDiag(server.storage, uri).match!SourceAndAst(
		(SourceAndAst x) =>
			x,
		(ReadFileDiag x) =>
			SourceAndAst(cString!"", fileAstForReadFileDiag(alloc, x)));

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

immutable struct PrintKind {
	immutable struct Tokens {}
	immutable struct Ast {}
	immutable struct Model {}
	immutable struct ConcreteModel {}
	immutable struct LowModel {}
	immutable struct Ide {
		enum Kind { hover, definition, rename, references }
		Kind kind;
		LineAndColumn lineAndColumn;
	}

	mixin Union!(Tokens, Ast, Model, ConcreteModel, LowModel, Ide);
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
		toLineAndCharacter(server.lineAndColumnGetters[where.uri], where.pos));
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
		jsonOfReferences(alloc, server.allUris, server.lineAndCharacterGetters, xs);
	final switch (kind) {
		case PrintKind.Ide.Kind.definition:
			return locations(getDefinitionForProgram(alloc, server, program, DefinitionParams(params)));
		case PrintKind.Ide.Kind.hover:
			return jsonOfHover(alloc, getHoverForProgram(alloc, server, program, HoverParams(params)));
		case PrintKind.Ide.Kind.rename:
			Opt!WorkspaceEdit rename = getRenameForProgram(alloc, server, program, RenameParams(params, "new-name"));
			return jsonOfRename(alloc, server.allUris, server.lineAndCharacterGetters, rename);
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
			perf, alloc, server.allSymbols, ctx, versionInfo, program, FileContentGetters(&server.storage));
		LowProgram lowProgram = lower(
			perf, alloc, server.allSymbols, program.mainConfig.extern_, program.program, concreteProgram);
		return Programs(program, some(concreteProgram), some(lowProgram));
	}
}

immutable struct BuildToCResult {
	WriteToCResult writeToCResult;
	string diagnostics;
	bool hasFatalDiagnostics;
	ExternLibraries externLibraries;
}
BuildToCResult buildToC(
	scope ref Perf perf,
	ref Alloc alloc,
	ref Server server,
	OS os,
	Uri main,
	in WriteToCParams params,
) {
	Programs programs = buildToLowProgram(perf, alloc, server, versionInfoForBuildToC(os), main);
	ShowCtx ctx = getShowDiagCtx(server, programs.program);
	return BuildToCResult(
		has(programs.lowProgram)
			? writeToC(alloc, server.allSymbols, server.allUris, ctx, force(programs.lowProgram), params)
			: WriteToCResult(PathAndArgs(params.cCompiler), ""),
		showDiagnostics(alloc, server, programs.program),
		hasFatalDiagnostics(programs.programWithMain),
		has(programs.lowProgram) ? force(programs.lowProgram).externLibraries : []);
}

ShowDiagCtx getShowDiagCtx(return scope ref const Server server, return scope ref Program program) =>
	ShowDiagCtx(getShowCtx(server), program.commonTypes);

private:

ShowCtx getShowCtx(return scope ref const Server server) =>
	ShowCtx(
		ptrTrustMe(server.allSymbols),
		ptrTrustMe(server.allUris),
		server.lineAndColumnGetters,
		server.urisInfo,
		server.showOptions);

SemanticTokens getTokens(ref Alloc alloc, ref Server server, Uri uri, in SourceAndAst ast) =>
	tokensOfAst(alloc, server.allSymbols, server.allUris, server.lineAndCharacterGetters[uri], ast);

LspOutMessage notification(T)(T a) =>
	LspOutMessage(LspOutNotification(a));

void notifyDiagnostics(
	scope ref Perf perf,
	ref Alloc alloc,
	scope ref ArrayBuilder!LspOutMessage out_,
	ref Server server,
	ref Program program,
) {
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
	ShowDiagCtx ctx = getShowDiagCtx(server, program);
	foreach (ref UriAndDiagnostics ud; all)
		add(alloc, out_, notification(PublishDiagnosticsParams(ud.uri, map(alloc, ud.diagnostics, (ref Diagnostic x) =>
			LspDiagnostic(
				x.range,
				toLspDiagnosticSeverity(getDiagnosticSeverity(x.kind)),
				stringOfDiag(alloc, ctx, x.kind))))));
}

LspDiagnosticSeverity toLspDiagnosticSeverity(DiagnosticSeverity a) {
	final switch (a) {
		case DiagnosticSeverity.unusedCode:
			return LspDiagnosticSeverity.Hint;
		case DiagnosticSeverity.warning:
			return LspDiagnosticSeverity.Warning;
		case DiagnosticSeverity.checkError:
		case DiagnosticSeverity.nameNotFound:
		case DiagnosticSeverity.importError:
		case DiagnosticSeverity.commonMissing:
		case DiagnosticSeverity.parseError:
			return LspDiagnosticSeverity.Error;
	}
}

LspOutAction initializedAction(ref Alloc alloc, ref Server server) {
	return LspOutAction(newArray!LspOutMessage(alloc, [
		register("textDocument/definition"),
		register("textDocument/hover"),
		register("textDocument/rename"),
		register("textDocument/references"),
		register("textDocument/semanticTokens/full"),
	]));
}

LspOutMessage register(string method) =>
	notification(RegisterCapability(method, method));
