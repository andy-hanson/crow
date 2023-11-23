module lib.lsp.lspParse;

@safe @nogc pure nothrow:

import lib.lsp.lspTypes : ChangeEvent;
import util.alloc.alloc : Alloc;
import util.col.arrUtil : exists, find, map;
import util.col.str : SafeCStr;
import util.json : Json;
import util.jsonParse : parseJson;
import util.lineAndColumnGetter : LineAndCharacter, LineAndCharacterRange;
import util.opt : force, none, Opt, some;
import util.sym : AllSymbols, sym;
import util.util : verify;

ChangeEvent[] parseChangeEvents(ref Alloc alloc, scope ref AllSymbols allSymbols, in SafeCStr source) {
	Opt!Json json = parseJson(alloc, allSymbols, source);
	return parseList!ChangeEvent(alloc, force(json), (in Json x) => parseChangeEvent(alloc, x));
}

private:

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

ChangeEvent parseChangeEvent(ref Alloc alloc, in Json a) =>
	hasKey!"range"(a)
		? ChangeEvent(some(parseLineAndCharacterRange(get!"range"(a))), get!"text"(a).as!string)
		: ChangeEvent(none!LineAndCharacterRange, get!"text"(a).as!string);

LineAndCharacterRange parseLineAndCharacterRange(in Json a) =>
	LineAndCharacterRange(parseLineAndCharacter(get!"start"(a)), parseLineAndCharacter(get!"end"(a)));

LineAndCharacter parseLineAndCharacter(in Json a) =>
	LineAndCharacter(asUint(get!"line"(a)), asUint(get!"character"(a)));

uint asUint(in Json a) =>
	safeUintOfDouble(a.as!double);

uint safeUintOfDouble(double a) {
	uint res = cast(int) a;
	verify((cast(double) res) == a);
	return res;
}
