module lib.lsp.lspParse;

@safe @nogc pure nothrow:

import lib.lsp.lspTypes :
	DefinitionParams,
	DidChangeTextDocumentParams,
	DidCloseTextDocumentParams,
	DidOpenTextDocumentParams,
	DidSaveTextDocumentParams,
	ExitParams,
	HoverParams,
	InitializeParams,
	InitializedParams,
	LspInMessage,
	LspInNotification,
	LspInRequest,
	LspInRequestParams,
	ReadFileResultParams,
	ReadFileResultType,
	ReferenceParams,
	RenameParams,
	RunParams,
	SemanticTokensParams,
	SetTraceParams,
	ShutdownParams,
	TextDocumentContentChangeEvent,
	TextDocumentIdentifier,
	TextDocumentItem,
	TextDocumentPositionParams,
	TraceValue,
	UnloadedUrisParams;
import util.alloc.alloc : Alloc;
import util.col.arrUtil : map;
import util.json : get, hasKey, Json;
import util.jsonParse : asUint;
import util.lineAndColumnGetter : LineAndCharacter, LineAndCharacterRange;
import util.opt : none, some;
import util.uri : AllUris, parseUri, Uri;

// If extending this, remember to modify 'initializeCapabilities'
LspInMessage parseLspInMessage(ref Alloc alloc, scope ref AllUris allUris, in Json message) {
	LspInMessage notification(T)(T res) =>
		LspInMessage(LspInNotification(res));
	LspInMessage request(T)(T res) =>
		LspInMessage(LspInRequest(asUint(get!"id"(message)), LspInRequestParams(res)));

	Json params = get!"params"(message);
	switch (get!"method"(message).as!string) {
		case "$/setTrace":
			return notification(SetTraceParams(parseTraceValue(get!"value"(params).as!string)));
		case "custom/readFileResult":
			return notification(ReadFileResultParams(
				parseUriProperty(allUris, params),
				toReadFileResponseType(get!"type"(params).as!string)));
		case "custom/run":
			return request(RunParams(parseUriProperty(allUris, params)));
		case "custom/unloadedUris":
			return request(UnloadedUrisParams());
		case "exit":
			return notification(ExitParams());
		case "initialize":
			return request(InitializeParams(hasKey!"trace"(params)
				? parseTraceValue(get!"trace"(params).as!string)
				: TraceValue.off));
		case "initialized":
			return notification(InitializedParams());
		case "shutdown":
			return request(ShutdownParams());
		case "textDocument/definition":
			return request(DefinitionParams(parseTextDocumentPositionParams(alloc, allUris, params)));
		case "textDocument/didChange":
			return notification(parseDidChangeTextDocumentParams(alloc, allUris, params));
		case "textDocument/didClose":
			return notification(DidCloseTextDocumentParams());
		case "textDocument/didOpen":
			return notification(DidOpenTextDocumentParams(parseTextDocumentItem(allUris, get!"textDocument"(params))));
		case "textDocument/didSave":
			return notification(DidSaveTextDocumentParams(
				parseTextDocumentIdentifier(allUris, get!"textDocument"(params))));
		case "textDocument/hover":
			return request(HoverParams(parseTextDocumentPositionParams(alloc, allUris, params)));
		case "textDocument/references":
			return request(ReferenceParams(parseTextDocumentPositionParams(alloc, allUris, params)));
		case "textDocument/rename":
			return request(RenameParams(
				parseTextDocumentPositionParams(alloc, allUris, params),
				get!"newName"(params).as!string));
		case "textDocument/semanticTokens/full":
			return request(SemanticTokensParams(parseTextDocumentIdentifier(allUris, get!"textDocument"(params))));
		default:
			assert(false);
	}
}

private:

TraceValue parseTraceValue(string a) {
	final switch (a) {
		case "off":
			return TraceValue.off;
		case "messages":
			return TraceValue.messages;
		case "verbose":
			return TraceValue.verbose;
	}
}

DidChangeTextDocumentParams parseDidChangeTextDocumentParams(ref Alloc alloc, scope ref AllUris allUris, in Json a) =>
	DidChangeTextDocumentParams(
		parseTextDocumentIdentifier(allUris, get!"textDocument"(a)),
		parseList!TextDocumentContentChangeEvent(alloc, get!"contentChanges"(a), (in Json x) =>
			parseTextDocumentContentChangeEvent(alloc, x)));

ReadFileResultType toReadFileResponseType(in string a) {
	final switch (a) {
		case "notFound":
			return ReadFileResultType.notFound;
		case "error":
			return ReadFileResultType.error;
	}
}

TextDocumentItem parseTextDocumentItem(scope ref AllUris allUris, in Json a) =>
	TextDocumentItem(parseUriProperty(allUris, a), parseTextProperty(a));

string parseTextProperty(in Json a) =>
	get!"text"(a).as!string;

TextDocumentPositionParams parseTextDocumentPositionParams(ref Alloc alloc, scope ref AllUris allUris, in Json a) =>
	TextDocumentPositionParams(
		parseTextDocumentIdentifier(allUris, get!"textDocument"(a)),
		parsePosition(get!"position"(a)));

TextDocumentIdentifier parseTextDocumentIdentifier(scope ref AllUris allUris, in Json a) =>
	TextDocumentIdentifier(parseUriProperty(allUris, a));

Uri parseUriProperty(scope ref AllUris allUris, in Json a) =>
	parseUri(allUris, get!"uri"(a).as!string);

T[] parseList(T)(ref Alloc alloc, in Json input, in T delegate(in Json) @safe @nogc pure nothrow cb) =>
	map!(T, Json)(alloc, input.as!(Json[]), (ref Json x) => cb(x));

TextDocumentContentChangeEvent parseTextDocumentContentChangeEvent(ref Alloc alloc, in Json a) =>
	hasKey!"range"(a)
		? TextDocumentContentChangeEvent(some(parseLineAndCharacterRange(get!"range"(a))), parseTextProperty(a))
		: TextDocumentContentChangeEvent(none!LineAndCharacterRange, parseTextProperty(a));

LineAndCharacterRange parseLineAndCharacterRange(in Json a) =>
	LineAndCharacterRange(parseLineAndCharacter(get!"start"(a)), parseLineAndCharacter(get!"end"(a)));

alias parsePosition = parseLineAndCharacter;

LineAndCharacter parseLineAndCharacter(in Json a) =>
	LineAndCharacter(asUint(get!"line"(a)), asUint(get!"character"(a)));
