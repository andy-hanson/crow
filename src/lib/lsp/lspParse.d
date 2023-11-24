module lib.lsp.lspParse;

@safe @nogc pure nothrow:

import lib.lsp.lspTypes :
	DefinitionParams,
	HoverParams,
	TextDocumentChangeEvent,
	TextDocumentIdentifier,
	TextDocumentPositionParams;
import util.alloc.alloc : Alloc;
import util.col.arrUtil : exists, find, map;
import util.col.str : SafeCStr;
import util.json : Json;
import util.jsonParse : parseJson;
import util.lineAndColumnGetter : LineAndCharacter, LineAndCharacterRange;
import util.opt : force, none, Opt, some;
import util.sym : AllSymbols, sym;
import util.uri : AllUris, parseUri;
import util.util : verify;

TextDocumentChangeEvent[] parseChangeEvents(ref Alloc alloc, scope ref AllSymbols allSymbols, in SafeCStr source) {
	Opt!Json json = parseJson(alloc, allSymbols, source);
	return parseList!TextDocumentChangeEvent(alloc, force(json), (in Json x) => parseChangeEvent(alloc, x));
}

DefinitionParams parseDefinitionParams(ref Alloc alloc, scope ref AllUris allUris, in Json source) =>
	parseTextDocumentPositionParams(alloc, allUris, source);

HoverParams parseHoverParams(ref Alloc alloc, scope ref AllUris allUris, in Json source) =>
	parseTextDocumentPositionParams(alloc, allUris, source);

private:

TextDocumentPositionParams parseTextDocumentPositionParams(ref Alloc alloc, scope ref AllUris allUris, in Json a) =>
	TextDocumentPositionParams(
		parseTextDocumentIdentifier(allUris, get!"textDocument"(a)),
		parsePosition(get!"position"(a)));

TextDocumentIdentifier parseTextDocumentIdentifier(scope ref AllUris allUris, in Json a) =>
	TextDocumentIdentifier(parseUri(allUris, get!"uri"(a).as!string));

T[] parseList(T)(ref Alloc alloc, in Json input, in T delegate(in Json) @safe @nogc pure nothrow cb) =>
	map!(T, Json)(alloc, input.as!(Json[]), (ref Json x) => cb(x));

Json get(string key)(in Json a) {
	Opt!(Json.ObjectField) pair = find!(Json.ObjectField)(a.as!(Json.Object), (in Json.ObjectField pair) =>
		pair.key == sym!key);
	return force(pair).value;
}

bool hasKey(string key)(in Json a) =>
	a.isA!(Json.Object) && exists!(Json.ObjectField)(a.as!(Json.Object), (in Json.ObjectField pair) =>
		pair.key == sym!key);

TextDocumentChangeEvent parseChangeEvent(ref Alloc alloc, in Json a) =>
	hasKey!"range"(a)
		? TextDocumentChangeEvent(some(parseLineAndCharacterRange(get!"range"(a))), get!"text"(a).as!string)
		: TextDocumentChangeEvent(none!LineAndCharacterRange, get!"text"(a).as!string);

LineAndCharacterRange parseLineAndCharacterRange(in Json a) =>
	LineAndCharacterRange(parseLineAndCharacter(get!"start"(a)), parseLineAndCharacter(get!"end"(a)));

alias parsePosition = parseLineAndCharacter;

LineAndCharacter parseLineAndCharacter(in Json a) =>
	LineAndCharacter(asUint(get!"line"(a)), asUint(get!"character"(a)));

uint asUint(in Json a) =>
	safeUintOfDouble(a.as!double);

uint safeUintOfDouble(double a) {
	uint res = cast(int) a;
	verify((cast(double) res) == a);
	return res;
}
