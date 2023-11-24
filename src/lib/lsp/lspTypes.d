module lib.lsp.lspTypes;

@safe @nogc pure nothrow:

import util.lineAndColumnGetter : LineAndCharacter, LineAndCharacterRange;
import util.col.str : SafeCStr;
import util.opt : Opt;
import util.uri : Uri;

alias Position = LineAndCharacter;

immutable struct TextDocumentChangeEvent {
	Opt!LineAndCharacterRange range;
	string text;
}

immutable struct TextDocumentPositionParams {
	TextDocumentIdentifier textDocument;
	Position position;
}

alias DefinitionParams = TextDocumentPositionParams;

alias HoverParams = TextDocumentPositionParams;
immutable struct Hover {
	MarkupContent contents;
	Opt!LineAndCharacterRange range;
}
immutable struct MarkupContent {
	MarkupKind kind;
	SafeCStr value;
}
enum MarkupKind {
	plaintext,
	markdown,
}

immutable struct RenameParams {
	@safe @nogc pure nothrow:

	TextDocumentPositionParams textDocumentAndPosition; // This appears in JSON as two separate properties
	string newName;
}

immutable struct TextDocumentIdentifier {
	Uri uri;
}
