
module lib.lsp.lspTypes;

@safe @nogc pure nothrow:

// https://microsoft.github.io/language-server-protocol/specifications/lsp/3.18/specification/

import util.exitCode : ExitCode;
import util.lineAndColumnGetter : LineAndCharacter, LineAndCharacterRange;
import util.col.str : SafeCStr;
import util.col.multiMap : MultiMap;
import util.opt : Opt;
import util.sourceRange : Range, UriAndRange;
import util.union_ : Union;
import util.uri : Uri;

// Types and their properties are a subset of what's in the LSP.
// For output types, they also use Range instead of LineAndCharacterRange. Use LineAndColumnGetters to convert.
// (This makes it easier to use a LineAndColumnRange instead for text output.)

alias Position = LineAndCharacter;

immutable struct LspInMessage {
	mixin Union!(LspInNotification, LspInRequest);
}

immutable struct LspInNotification {
	mixin Union!(
		DidChangeTextDocumentParams,
		DidCloseTextDocumentParams,
		DidOpenTextDocumentParams,
		DidSaveTextDocumentParams,
		ExitParams,
		InitializedParams,
		ReadFileResultParams,
		SetTraceParams);
}

immutable struct LspInRequest {
	uint id;
	LspInRequestParams params;
}
immutable struct LspInRequestParams {
	mixin Union!(
		DefinitionParams,
		HoverParams,
		InitializeParams,
		ReferenceParams,
		RenameParams,
		RunParams,
		SemanticTokensParams,
		ShutdownParams,
		UnloadedUrisParams);
}

immutable struct LspOutAction {
	LspOutMessage[] outMessages;
	Opt!ExitCode exitCode;
}

immutable struct LspOutMessage {
	mixin Union!(LspOutNotification, LspOutResponse);
}
immutable struct LspOutNotification {
	mixin Union!(
		PublishDiagnosticsParams,
		RegisterCapability,
		UnknownUris);
}
immutable struct LspOutResponse {
	uint id;
	LspOutResult result;
}
immutable struct LspOutResult {
	immutable struct Null {}
	mixin Union!(
		InitializeResult,
		Opt!Hover,
		RunResult,
		SemanticTokens,
		UnloadedUris,
		UriAndRange[], // for definition or references
		Opt!WorkspaceEdit, // for rename
		Null,
	);
}

immutable struct RegisterCapability {
	string id;
	string method;
}

immutable struct UnknownUris {
	Uri[] unknownUris;
}

immutable struct InitializeResult {
	// We'll just hardcode toJson
}

immutable struct SetTraceParams {
	TraceValue value;
}
enum TraceValue { off, messages, verbose }

// Parameter to "custom/readFileResult"
immutable struct ReadFileResultParams {
	Uri uri;
	ReadFileResultType type;
}
enum ReadFileResultType { notFound, error }
// Parameter to "custom/run"
immutable struct RunParams {
	Uri uri;
}
immutable struct RunResult {
	ExitCode exitCode;
	Write[] writes;
}
immutable struct Write {
	Pipe pipe;
	string text;
}
enum Pipe { stdout, stderr }

// Parameter to "custom/unloadedUris"
immutable struct UnloadedUrisParams {}
immutable struct UnloadedUris {
	Uri[] unloadedUris;
}

immutable struct ExitParams {}

immutable struct InitializeParams {
	TraceValue trace;
}
immutable struct InitializedParams {}

immutable struct ShutdownParams {}

immutable struct DefinitionParams {
	TextDocumentPositionParams params;
}

immutable struct DidChangeTextDocumentParams {
	TextDocumentIdentifier textDocument;
	TextDocumentContentChangeEvent[] contentChanges;
}

immutable struct DidCloseTextDocumentParams {}

immutable struct DidSaveTextDocumentParams {
	TextDocumentIdentifier textDocument;
}

immutable struct DidOpenTextDocumentParams {
	TextDocumentItem textDocument;
}

immutable struct TextDocumentItem {
	Uri uri;
	string text;
}

immutable struct HoverParams {
	TextDocumentPositionParams params;
}
immutable struct Hover {
	MarkupContent contents;
}
immutable struct MarkupContent {
	MarkupKind kind;
	SafeCStr value;
}
enum MarkupKind {
	plaintext,
	markdown,
}

immutable struct PublishDiagnosticsParams {
	Uri uri;
	LspDiagnostic[] diagnostics;
}

immutable struct TextDocumentContentChangeEvent {
	Opt!LineAndCharacterRange range;
	string text;
}

immutable struct TextDocumentPositionParams {
	TextDocumentIdentifier textDocument;
	Position position;
}

immutable struct LspDiagnostic {
	Range range;
	LspDiagnosticSeverity severity;
	SafeCStr message;
}

enum LspDiagnosticSeverity {
	Error = 1,
	Warning = 2,
	Information = 3,
	Hint = 4,
}

immutable struct RenameParams {
	TextDocumentPositionParams textDocumentAndPosition; // This appears in JSON as two separate properties
	string newName;
}

immutable struct ReferenceParams {
	TextDocumentPositionParams params;
}

immutable struct SemanticTokensParams {
	TextDocumentIdentifier textDocument;
}

immutable struct TextDocumentIdentifier {
	Uri uri;
}

immutable struct WorkspaceEdit {
	MultiMap!(Uri, TextEdit) changes;
}

immutable struct TextEdit {
	Range range;
	string newText;
}

immutable struct SemanticTokens {
	uint[] data;
}