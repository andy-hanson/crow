module lib.lsp.lspParse;

@safe @nogc pure nothrow:

import lib.lsp.lspTypes :
	CancelRequestParams,
	DefinitionParams,
	DidChangeTextDocumentParams,
	DidCloseTextDocumentParams,
	DidOpenTextDocumentParams,
	DidSaveTextDocumentParams,
	ExitParams,
	HoverParams,
	InitializationOptions,
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
import util.col.array : map;
import util.json : get, hasKey, Json;
import util.jsonParse : asUint;
import util.opt : none, some;
import util.sourceRange : LineAndCharacter, LineAndCharacterRange;
import util.uri : mustParseUri, Uri;
import util.util : enumOfString;

// If extending this, remember to modify 'initializeCapabilities'
LspInMessage parseLspInMessage(ref Alloc alloc, in Json message) {
	LspInMessage notification(T)(T res) =>
		LspInMessage(LspInNotification(res));
	LspInMessage request(T)(T res) =>
		LspInMessage(LspInRequest(asUint(get!"id"(message)), LspInRequestParams(res)));

	Json params = get!"params"(message);
	switch (get!"method"(message).as!string) {
		case "$/cancelRequest":
			return notification(CancelRequestParams(asUint(get!"id"(params))));
		case "$/setTrace":
			return notification(SetTraceParams(parseTraceValue(get!"value"(params).as!string)));
		case "custom/readFileResult":
			return notification(ReadFileResultParams(
				parseUriProperty(params),
				enumOfString!ReadFileResultType(get!"type"(params).as!string),
				cast(immutable ubyte[]) (hasKey!"content"(params) ? get!"content"(params).as!string : ""))); // TODO: we already validated utf8 when parsing json, this makes us do it again
		case "custom/run":
			return request(RunParams(
				parseUriProperty(params),
				hasKey!"diagnosticsOnlyForUris"(params)
					? some(parseUriList(alloc, get!"diagnosticsOnlyForUris"(params)))
					: none!(Uri[])));
		case "custom/unloadedUris":
			return request(UnloadedUrisParams());
		case "exit":
			return notification(ExitParams());
		case "initialize":
			return request(InitializeParams(
				parseInitializationOptions(get!"initializationOptions"(params)),
				hasKey!"trace"(params) ? parseTraceValue(get!"trace"(params).as!string) : TraceValue.off));
		case "initialized":
			return notification(InitializedParams());
		case "shutdown":
			return request(ShutdownParams());
		case "textDocument/definition":
			return request(DefinitionParams(parseTextDocumentPositionParams(alloc, params)));
		case "textDocument/didChange":
			return notification(parseDidChangeTextDocumentParams(alloc, params));
		case "textDocument/didClose":
			return notification(DidCloseTextDocumentParams());
		case "textDocument/didOpen":
			return notification(DidOpenTextDocumentParams(parseTextDocumentItem(get!"textDocument"(params))));
		case "textDocument/didSave":
			return notification(DidSaveTextDocumentParams(
				parseTextDocumentIdentifier(get!"textDocument"(params))));
		case "textDocument/hover":
			return request(HoverParams(parseTextDocumentPositionParams(alloc, params)));
		case "textDocument/references":
			return request(ReferenceParams(parseTextDocumentPositionParams(alloc, params)));
		case "textDocument/rename":
			return request(RenameParams(
				parseTextDocumentPositionParams(alloc, params),
				get!"newName"(params).as!string));
		case "textDocument/semanticTokens/full":
			return request(SemanticTokensParams(parseTextDocumentIdentifier(get!"textDocument"(params))));
		default:
			assert(false);
	}
}

private:

Uri[] parseUriList(ref Alloc alloc, in Json a) =>
	map(alloc, a.as!(Json[]), (ref Json x) =>
		mustParseUri(x.as!string));

InitializationOptions parseInitializationOptions(in Json a) =>
	InitializationOptions(hasKey!"unknownUris"(a) ? get!"unknownUris"(a).as!bool : false);

TraceValue parseTraceValue(string a) =>
	enumOfString!TraceValue(a);

DidChangeTextDocumentParams parseDidChangeTextDocumentParams(ref Alloc alloc, in Json a) =>
	DidChangeTextDocumentParams(
		parseTextDocumentIdentifier(get!"textDocument"(a)),
		parseList!TextDocumentContentChangeEvent(alloc, get!"contentChanges"(a), (in Json x) =>
			parseTextDocumentContentChangeEvent(alloc, x)));

TextDocumentItem parseTextDocumentItem(in Json a) =>
	TextDocumentItem(parseUriProperty(a), parseTextProperty(a));

string parseTextProperty(in Json a) =>
	get!"text"(a).as!string;

TextDocumentPositionParams parseTextDocumentPositionParams(ref Alloc alloc, in Json a) =>
	TextDocumentPositionParams(
		parseTextDocumentIdentifier(get!"textDocument"(a)),
		parsePosition(get!"position"(a)));

TextDocumentIdentifier parseTextDocumentIdentifier(in Json a) =>
	TextDocumentIdentifier(parseUriProperty(a));

Uri parseUriProperty(in Json a) =>
	mustParseUri(get!"uri"(a).as!string);

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
