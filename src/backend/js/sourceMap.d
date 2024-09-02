module backend.js.sourceMap;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc;
import util.cell : Cell, cellGet, cellSet;
import util.col.mutArr : findIndexOrPush, moveToArray, MutArr, push;
import util.comparison : Comparison;
import util.conv : safeToInt, safeToUint;
import util.json : field, Json, jsonList, jsonObject, jsonString, jsonToString;
import util.sourceRange : compareLineAndColumn, LineAndColumn;
import util.symbol : Symbol, symbol;
import util.uri : stringOfUri, Uri;
import util.util : abs, ptrTrustMe;
import util.writer : makeStringWithWriter, Writer;

// https://docs.google.com/document/d/1U1RGAehQwRypUTovF1KRlpiOFze0b-_2gc6fAH0KY0k/edit?pli=1

struct SourceMapBuilder {
	@safe @nogc pure nothrow:
	private:
	Alloc* allocPtr;
	MutArr!Uri sources;
	MutArr!Symbol names;
	MutArr!(immutable char) mappings;
	
	Cell!SingleSourceMapping prev = Cell!SingleSourceMapping(SingleSourceMapping(noSource));
	uint prevSourceUriIndex;
	uint prevSourceNameIndex;

	public ref Alloc alloc() return scope =>
		*allocPtr;

	void opOpAssign(string op : "~")(in SingleSourceMapping x) scope {
		add(this, x);
	}
}
string finish(SourceMapBuilder a) =>
	jsonToString(a.alloc, jsonObject(a.alloc, [
		field!"version"(3),
		field!"sources"(jsonList!Uri(a.alloc, moveToArray(a.alloc, a.sources), (in Uri source) =>
			jsonString(stringOfUri(a.alloc, source)))),
		field!"names"(jsonList!Symbol(a.alloc, moveToArray(a.alloc, a.names), (in Symbol name) =>
			jsonString(name))),
		field!"mappings"(moveToArray(a.alloc, a.mappings))]));

immutable struct Source {
	Uri uri;
	Symbol name; // E.g. a function name
	LineAndColumn pos;
}
Source noSource() =>
	Source(Uri.empty, symbol!"");

immutable struct SingleSourceMapping {
	Source source;
	LineAndColumn outPos;
}

private:

void add(scope ref SourceMapBuilder a, in SingleSourceMapping mapping) {
	SingleSourceMapping prev = cellGet(a.prev);
	if (mapping.source == noSource || mapping.source == prev.source) return;

	assert(compareLineAndColumn(prev.outPos, mapping.outPos) != Comparison.greater);

	ref Alloc alloc() => *a.allocPtr;
	void outVLQ(int value) {
		writeBase64VLQ(*a.allocPtr, a.mappings, value);
	}

	foreach (uint _; prev.outPos.line0Indexed .. mapping.outPos.line0Indexed)
		push(alloc, a.mappings, ';');

	if (prev.outPos.line0Indexed == mapping.outPos.line0Indexed) {
		if (prev.source.uri != Uri.empty)
			push(alloc, a.mappings, ',');
		outVLQ(mapping.outPos.column0Indexed);
	} else
		outVLQ(safeToInt(mapping.outPos.column0Indexed) - safeToInt(prev.outPos.column0Indexed));

	if (prev.source.uri != mapping.source.uri ||
		prev.source.name != mapping.source.name ||
		prev.source.pos != mapping.source.pos) {

		// As an optimization, check if it's the same URI as last time
		if (prev.source.uri == mapping.source.uri)
			outVLQ(0);
		else {
			uint uriIndex = safeToUint(findIndexOrPush(alloc, a.sources, mapping.source.uri));
			outVLQ(safeToInt(uriIndex) - a.prevSourceUriIndex);
			a.prevSourceUriIndex = uriIndex;
		}

		outVLQ(safeToInt(mapping.source.pos.line0Indexed) - safeToInt(prev.source.pos.line0Indexed));
		outVLQ(safeToInt(mapping.source.pos.column0Indexed) - safeToInt(prev.source.pos.column0Indexed));

		if (prev.source.name == mapping.source.name)
			outVLQ(0);
		else {
			uint nameIndex = safeToUint(findIndexOrPush(alloc, a.names, mapping.source.name));
			outVLQ(safeToInt(nameIndex) - a.prevSourceNameIndex);
			a.prevSourceNameIndex = nameIndex;
		}
	}

	cellSet(a.prev, mapping);
}

void writeBase64VLQ(ref Alloc alloc, scope ref MutArr!(immutable char) out_, int value) {
	if (value == 0) {
		push(alloc, out_, base64Char(0));
	} else {
		// First char is special; only 5 bits of the value, with least significant bit as the sign bit
		bool signBit = value < 0;
		uint valueRemaining = abs(value);
		push(alloc, out_, base64Char(((valueRemaining & 0b11111) << 1) | signBit));
		valueRemaining >>= 5;
		while (valueRemaining != 0) {
			push(alloc, out_, base64Char(valueRemaining & 0b111111));
			valueRemaining >>= 6;
		}
	}
}

char base64Char(ubyte number) {
	assert((number & 0b111111) == number);
	return base64Chars[number];
}

immutable char[] base64Chars =
	"ABCDEFGHIJKLMNOP" ~
	"QRSTUVWXYZabcdef" ~
	"ghijklmnopqrstuv" ~
	"wxyz0123456789+/";


