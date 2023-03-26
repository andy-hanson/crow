module util.sourceRange;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc;
import util.col.fullIndexMap : FullIndexMap;
import util.col.map : Map;
import util.conv : safeToUint, safeToUshort;
import util.path : Path;
import util.repr : Repr, reprNat, reprRecord;
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
	FileIndex fileIndex;
	Pos pos;
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

	static FileAndRange empty() =>
		FileAndRange(FileIndex.none, RangeWithinFile.empty);
}
static assert(FileAndRange.sizeof == 8);

Repr reprFileAndPos(ref Alloc alloc, FileAndPos a) =>
	reprRecord!"file-pos"(alloc, [reprNat(a.fileIndex.index), reprNat(a.pos)]);

Repr reprFileAndRange(ref Alloc alloc, FileAndRange a) =>
	reprRecord!"file-range"(alloc, [reprNat(a.fileIndex.index), reprRangeWithinFile(alloc, a.range)]);

Repr reprRangeWithinFile(ref Alloc alloc, RangeWithinFile a) =>
	reprRecord!"range"(alloc, [reprNat(a.start), reprNat(a.end)]);
