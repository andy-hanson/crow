module util.sourceRange;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc;
import util.col.fullIndexDict : FullIndexDict;
import util.col.dict : Dict;
import util.conv : safeToUint, safeToUshort;
import util.path : Path;
import util.repr : Repr, reprNat, reprRecord;
import util.sym : AllSymbols, Sym, symSize;

alias Pos = uint;

alias FilePaths = FullIndexDict!(FileIndex, Path);
alias PathToFile = Dict!(Path, FileIndex);

struct FileIndex {
	immutable ushort index;

	static immutable FileIndex none = FileIndex(ushort.max);
}

struct RangeWithinFile {
	immutable Pos start;
	immutable Pos end;

	static immutable RangeWithinFile max = immutable RangeWithinFile(immutable Pos(uint.max), immutable Pos(uint.max));
	static immutable RangeWithinFile empty = immutable RangeWithinFile(immutable Pos(0), immutable Pos(0));
}
static assert(RangeWithinFile.sizeof == 8);

immutable(bool) hasPos(immutable RangeWithinFile a, immutable Pos p) {
	return a.start <= p && p < a.end;
}

immutable(RangeWithinFile) rangeOfStartAndName(
	immutable Pos start,
	immutable Sym name,
	ref const AllSymbols allSymbols,
) {
	return rangeOfStartAndLength(start, symSize(allSymbols, name));
}

immutable(RangeWithinFile) rangeOfStartAndLength(immutable Pos start, immutable size_t length) {
	return immutable RangeWithinFile(start, safeToUint(start + length));
}

struct FileAndPos {
	immutable FileIndex fileIndex;
	immutable Pos pos;
}

immutable(FileAndPos) fileAndPosFromFileAndRange(immutable FileAndRange a) {
	return immutable FileAndPos(a.fileIndex, a.start);
}

immutable(FileAndRange) fileAndRangeFromFileAndPos(immutable FileAndPos a) {
	return immutable FileAndRange(a.fileIndex, immutable RangeWithinFile(a.pos, a.pos + 1));
}

struct FileAndRange {
	@safe @nogc pure nothrow:

	immutable FileIndex fileIndex;
	immutable ushort size;
	immutable Pos start;

	immutable this(immutable FileIndex fi, immutable RangeWithinFile r) {
		fileIndex = fi;
		size = safeToUshort(r.end - r.start);
		start = r.start;
	}

	//TODO: NOT INSTANCE
	immutable(RangeWithinFile) range() immutable{
		return immutable RangeWithinFile(start, start + size);
	}

	static immutable FileAndRange empty = immutable FileAndRange(FileIndex.none, RangeWithinFile.empty);
}
static assert(FileAndRange.sizeof == 8);

immutable(Repr) reprFileAndPos(ref Alloc alloc, ref immutable FileAndPos a) {
	return reprRecord(alloc, "file-pos", [reprNat(a.fileIndex.index), reprNat(a.pos)]);
}

immutable(Repr) reprFileAndRange(ref Alloc alloc, ref immutable FileAndRange a) {
	return reprRecord(alloc, "file-range", [reprNat(a.fileIndex.index), reprRangeWithinFile(alloc, a.range)]);
}

immutable(Repr) reprRangeWithinFile(ref Alloc alloc, immutable RangeWithinFile a) {
	return reprRecord(alloc, "range", [reprNat(a.start), reprNat(a.end)]);
}
