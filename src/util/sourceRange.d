module util.sourceRange;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc;
import util.comparison : compareNat32, Comparison;
import util.conv : safeToUint;
import util.json : field, Json, jsonObject;
import util.sym : AllSymbols, Sym, symSize;
import util.lineAndColumnGetter :
	LineAndCharacter, lineAndCharacterAtPos, LineAndCharacterRange, LineAndColumnGetter, PosKind;
import util.uri : AllUris, compareUriAlphabetically, Uri;

alias Pos = uint;

immutable struct Range {
	@safe @nogc pure nothrow:

	Pos start;
	Pos end;

	this(Pos s, Pos e) {
		start = s;
		end = e;
		assert(start <= end);
	}

	static Range max() =>
		Range(Pos.max, Pos.max);
	static Range empty() =>
		Range(0, 0);

	uint opDollar(size_t i : 0)() =>
		length;

	uint length() =>
		end - start;

	Range opSlice(uint low, uint high) =>
		Range(start + low, start + high);
}

Comparison compareRange(in Range a, in Range b) =>
	a.start == b.start ? compareNat32(a.end, b.end) : compareNat32(a.start, b.start);

Range combineRanges(in Range a, in Range b) {
	assert(a.end <= b.start);
	return Range(a.start, b.end);
}

bool hasPos(in Range a, Pos p) =>
	a.start <= p && p <= a.end;

Range rangeOfStartAndName(Pos start, Sym name, in AllSymbols allSymbols) =>
	rangeOfStartAndLength(start, symSize(allSymbols, name));

Range rangeOfStartAndLength(Pos start, size_t length) =>
	Range(start, safeToUint(start + length));

immutable struct UriAndPos {
	@safe @nogc pure nothrow:

	Uri uri;
	Pos pos;

	static UriAndPos empty() =>
		UriAndPos(Uri.empty, 0);
}

immutable struct UriAndRange {
	@safe @nogc pure nothrow:

	Uri uri;
	Range range;

	Pos start() =>
		range.start;

	static UriAndRange empty() =>
		topOfFile(Uri.empty);

	static UriAndRange topOfFile(Uri uri) =>
		UriAndRange(uri, Range.empty);
}

Comparison compareUriAndRange(in AllUris allUris, UriAndRange a, UriAndRange b) {
	Comparison cmpUri = compareUriAlphabetically(allUris, a.uri, b.uri);
	return cmpUri != Comparison.equal ? cmpUri : compareRange(a.range, b.range);
}

UriAndPos toUriAndPos(UriAndRange a) =>
	UriAndPos(a.uri, a.start);

Json jsonOfPosWithinFile(ref Alloc alloc, in LineAndColumnGetter lcg, Pos a, PosKind posKind) =>
	jsonOfLineAndCharacter(alloc, lineAndCharacterAtPos(lcg, a, posKind));

Json jsonOfRange(ref Alloc alloc, in LineAndColumnGetter lcg, in Range a) =>
	jsonOfLineAndCharacterRange(alloc, lineAndCharacterRange(lcg, a));

private Json jsonOfLineAndCharacterRange(ref Alloc alloc, in LineAndCharacterRange a) =>
	jsonObject(alloc, [
		field!"start"(jsonOfLineAndCharacter(alloc, a.start)),
		field!"end"(jsonOfLineAndCharacter(alloc, a.end))]);

LineAndCharacterRange lineAndCharacterRange(in LineAndColumnGetter lcg, in Range a) =>
	LineAndCharacterRange(
		lineAndCharacterAtPos(lcg, a.start, PosKind.startOfRange),
		lineAndCharacterAtPos(lcg, a.end, PosKind.endOfRange));

private:

Json jsonOfLineAndCharacter(ref Alloc alloc, in LineAndCharacter a) =>
	jsonObject(alloc, [field!"line"(a.line), field!"character"(a.character)]);
