module lib.lsp.lspToJson;

@safe @nogc pure nothrow:

import lib.lsp.lspTypes : Hover, MarkupContent, MarkupKind;
import util.alloc.alloc : Alloc;
import util.json : field, Json, jsonNull, jsonObject, jsonString, optionalField;
import util.lineAndColumnGetter : LineAndCharacterRange;
import util.opt : force, has, Opt;
import util.sourceRange : jsonOfLineAndCharacterRange;

Json jsonOfHover(ref Alloc alloc, in Opt!Hover a) =>
	has(a) ? jsonOfHover(alloc, force(a)) : jsonNull;

Json jsonOfHover(ref Alloc alloc, in Hover a) =>
	jsonObject(alloc, [
		field!"contents"(jsonOfMarkupContent(alloc, a.contents)),
		optionalField!("range", LineAndCharacterRange)(a.range, (in LineAndCharacterRange x) =>
			jsonOfLineAndCharacterRange(alloc, x))]);

private:

Json jsonOfMarkupContent(ref Alloc alloc, in MarkupContent a) =>
	jsonObject(alloc, [
		field!"kind"(stringOfMarkupKind(a.kind)),
		field!"value"(jsonString(alloc, a.value))]);

string stringOfMarkupKind(MarkupKind a) {
	final switch (a) {
		case MarkupKind.plaintext:
			return "plaintext";
		case MarkupKind.markdown:
			return "markdown";
	}
}
