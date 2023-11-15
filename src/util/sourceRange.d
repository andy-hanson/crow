module util.sourceRange;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc;
import util.comparison : compareNat32, Comparison;
import util.conv : safeToUint;
import util.json : field, Json, jsonObject;
import util.sym : AllSymbols, Sym, symSize;
import util.lineAndColumnGetter :
	LineAndCharacter,
	lineAndCharacterAtPos,
	LineAndCharacterRange,
	lineAndCharacterRange,
	LineAndColumnGetter,
	LineAndColumnGetters,
	PosKind;
import util.uri : AllUris, compareUriAlphabetically, Uri, uriToString;
import util.util : verify;

alias Pos = uint;

immutable struct RangeWithinFile {
	@safe @nogc pure nothrow:

	Pos start;
	Pos end;

	static RangeWithinFile max() =>
		RangeWithinFile(Pos.max, Pos.max);
	static RangeWithinFile empty() =>
		RangeWithinFile(0, 0);
}
static assert(RangeWithinFile.sizeof == 8);

Comparison compareRangeWithinFile(RangeWithinFile a, RangeWithinFile b) =>
	a.start == b.start ? compareNat32(a.end, b.end) : compareNat32(a.start, b.start);

RangeWithinFile combineRanges(RangeWithinFile a, RangeWithinFile b) {
	verify(a.end <= b.start);
	return RangeWithinFile(a.start, b.end);
}

bool hasPos(RangeWithinFile a, Pos p) =>
	a.start <= p && p <= a.end;

RangeWithinFile rangeOfStartAndName(Pos start, Sym name, in AllSymbols allSymbols) =>
	rangeOfStartAndLength(start, symSize(allSymbols, name));

RangeWithinFile rangeOfStartAndLength(Pos start, size_t length) =>
	RangeWithinFile(start, safeToUint(start + length));

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
	RangeWithinFile range;

	Pos start() =>
		range.start;

	static UriAndRange empty() =>
		topOfFile(Uri.empty);

	static UriAndRange topOfFile(Uri uri) =>
		UriAndRange(uri, RangeWithinFile.empty);
}

Comparison compareUriAndRange(in AllUris allUris, UriAndRange a, UriAndRange b) {
	Comparison cmpUri = compareUriAlphabetically(allUris, a.uri, b.uri);
	return cmpUri != Comparison.equal ? cmpUri : compareRangeWithinFile(a.range, b.range);
}

UriAndPos toUriAndPos(UriAndRange a) =>
	UriAndPos(a.uri, a.start);

Json jsonOfUriAndRange(ref Alloc alloc, in AllUris allUris, scope ref LineAndColumnGetters lcg, UriAndRange a) =>
	jsonObject(alloc, [
		field!"uri"(uriToString(alloc, allUris, a.uri)),
		field!"range"(jsonOfRangeWithinFile(alloc, lcg[a.uri], a.range))]);

Json jsonOfPosWithinFile(ref Alloc alloc, in LineAndColumnGetter lcg, Pos a, PosKind posKind) =>
	jsonOfLineAndCharacter(alloc, lineAndCharacterAtPos(lcg, a, posKind));

Json jsonOfRangeWithinFile(ref Alloc alloc, scope ref LineAndColumnGetters lcg, UriAndRange a) =>
	jsonOfRangeWithinFile(alloc, lcg[a.uri], a.range);

Json jsonOfRangeWithinFile(ref Alloc alloc, in LineAndColumnGetter lcg, in RangeWithinFile a) {
	LineAndCharacterRange r = lineAndCharacterRange(lcg, a);
	return jsonObject(alloc, [
		field!"start"(jsonOfLineAndCharacter(alloc, r.start)),
		field!"end"(jsonOfLineAndCharacter(alloc, r.end))]);
}

private:

Json jsonOfLineAndCharacter(ref Alloc alloc, in LineAndCharacter a) =>
	jsonObject(alloc, [field!"line"(a.line), field!"character"(a.character)]);
