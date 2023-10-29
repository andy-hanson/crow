module util.sourceRange;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc;
import util.col.fullIndexMap : FullIndexMap;
import util.col.map : Map;
import util.comparison : compareNat32, Comparison;
import util.conv : safeToUint;
import util.hash : Hasher, hashUshort;
import util.json : field, Json, jsonObject;
import util.opt : none;
import util.sym : AllSymbols, Sym, symSize;
import util.uri : AllUris, compareUriAlphabetically, Uri, uriToString;
import util.util : verify;

alias Pos = uint;

alias FileUris = FullIndexMap!(FileIndex, Uri);
alias UriToFile = Map!(Uri, FileIndex);

immutable struct FileIndex {
	@safe @nogc pure nothrow:

	ushort index;

	static FileIndex none() =>
		FileIndex(ushort.max);

	void hash(ref Hasher hasher) scope const {
		hashUshort(hasher, index);
	}
}

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
	a.start <= p && p < a.end;

RangeWithinFile rangeOfStartAndName(Pos start, Sym name, in AllSymbols allSymbols) =>
	rangeOfStartAndLength(start, symSize(allSymbols, name));

RangeWithinFile rangeOfStartAndLength(Pos start, size_t length) =>
	RangeWithinFile(start, safeToUint(start + length));

// TODO: RENAME
immutable struct FileAndPos {
	@safe @nogc pure nothrow:

	Uri uri;
	Pos pos;

	static FileAndPos empty() =>
		fileAndPosFromFileAndRange(FileAndRange.empty);
}

FileAndPos fileAndPosFromFileAndRange(FileAndRange a) =>
	FileAndPos(a.uri, a.start);

FileAndRange fileAndRangeFromFileAndPos(FileAndPos a) =>
	FileAndRange(a.uri, RangeWithinFile(a.pos, a.pos + 1));

immutable struct UriAndRange {
	@safe @nogc pure nothrow:

	Uri uri;
	RangeWithinFile range;

	Pos start() =>
		range.start;

	//TODO:KILL
	Uri fileIndex() =>
		uri;

	static UriAndRange empty() =>
		topOfFile(Uri.empty);

	static FileAndRange topOfFile(Uri uri) =>
		FileAndRange(uri, RangeWithinFile.empty);
}
//TODO:KILL
alias FileAndRange = UriAndRange;

Comparison compareUriAndRange(in AllUris allUris, UriAndRange a, UriAndRange b) {
	Comparison cmpUri = compareUriAlphabetically(allUris, a.uri, b.uri);
	return cmpUri != Comparison.equal ? cmpUri : compareRangeWithinFile(a.range, b.range);
}

FileAndPos toFileAndPos(FileAndRange a) =>
	FileAndPos(a.fileIndex, a.start);

Json jsonOfFileAndPos(ref Alloc alloc, in AllUris allUris, FileAndPos a) =>
	jsonObject(alloc, [field!"uri"(uriToString(alloc, allUris, a.uri)), field!"pos"(a.pos)]);

Json jsonOfFileAndRange(ref Alloc alloc, in AllUris allUris, FileAndRange a) =>
	jsonObject(alloc, [
		field!"uri"(uriToString(alloc, allUris, a.uri)),
		field!"range"(jsonOfRangeWithinFile(alloc, a.range))]);

Json jsonOfRangeWithinFile(ref Alloc alloc, RangeWithinFile a) =>
	jsonObject(alloc, [field!"start"(a.start), field!"end"(a.end)]);
