module util.sourceRange;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc;
import util.col.fullIndexMap : FullIndexMap;
import util.col.map : Map;
import util.conv : safeToUint, safeToUshort;
import util.json : field, Json, jsonObject;
import util.path : Path;
import util.sym : AllSymbols, Sym, symSize;
import util.util : verify;

alias Pos = uint;

alias FilePaths = FullIndexMap!(FileIndex, Path);
alias PathToFile = Map!(Path, FileIndex);

immutable struct FileIndex {
	@safe @nogc pure nothrow:

	ushort index;

	static FileIndex none() =>
		FileIndex(ushort.max);
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

immutable struct FileAndPos {
	@safe @nogc pure nothrow:

	FileIndex fileIndex;
	Pos pos;

	static FileAndPos empty() =>
		FileAndPos(FileIndex.none, 0);
}

FileAndPos fileAndPosFromFileAndRange(FileAndRange a) =>
	FileAndPos(a.fileIndex, a.start);

FileAndRange fileAndRangeFromFileAndPos(FileAndPos a) =>
	FileAndRange(a.fileIndex, RangeWithinFile(a.pos, a.pos + 1));

immutable struct FileAndRange {
	@safe @nogc pure nothrow:

	FileIndex fileIndex;
	ushort size;
	Pos start;

	this(FileIndex fi, RangeWithinFile r) {
		fileIndex = fi;
		size = safeToUshort(r.end - r.start);
		start = r.start;
	}

	RangeWithinFile range() =>
		RangeWithinFile(start, start + size);

	static FileAndRange topOfFile(FileIndex file) =>
		FileAndRange(file, RangeWithinFile.empty);

	static FileAndRange empty() =>
		FileAndRange(FileIndex.none, RangeWithinFile.empty);
}
static assert(FileAndRange.sizeof == 8);

FileAndPos toFileAndPos(FileAndRange a) =>
	FileAndPos(a.fileIndex, a.start);

Json jsonOfFileAndPos(ref Alloc alloc, FileAndPos a) =>
	jsonObject(alloc, [field!"file"(a.fileIndex.index), field!"pos"(a.pos)]);

Json jsonOfFileAndRange(ref Alloc alloc, FileAndRange a) =>
	jsonObject(alloc, [
		field!"file"(a.fileIndex.index),
		field!"range"(jsonOfRangeWithinFile(alloc, a.range))]);

Json jsonOfRangeWithinFile(ref Alloc alloc, RangeWithinFile a) =>
	jsonObject(alloc, [field!"start"(a.start), field!"end"(a.end)]);
