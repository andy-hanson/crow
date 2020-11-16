module util.sourceRange;

@safe @nogc pure nothrow:

import util.collection.fullIndexDict : FullIndexDict;
import util.path : PathAndStorageKind;
import util.sexpr : Sexpr, tataNat, tataRecord;
import util.types : safeU32ToU16, u16, u32;

alias Pos = u32;

alias FilePaths = FullIndexDict!(FileIndex, PathAndStorageKind);

struct FileIndex {
	immutable u16 index;

	static immutable FileIndex none = FileIndex(u16.max);
}

struct RangeWithinFile {
	immutable Pos start;
	immutable Pos end;

	static immutable RangeWithinFile max = immutable RangeWithinFile(immutable Pos(u32.max), immutable Pos(u32.max));
	static immutable RangeWithinFile empty = immutable RangeWithinFile(immutable Pos(0), immutable Pos(0));
}
static assert(RangeWithinFile.sizeof == 8);

struct FileAndPos {
	immutable FileIndex fileIndex;
	immutable Pos pos;
}

struct FileAndRange {
	@safe @nogc pure nothrow:

	immutable FileIndex fileIndex;
	immutable u16 size;
	immutable Pos start;

	immutable this(immutable FileIndex fi, immutable RangeWithinFile r) {
		fileIndex = fi;
		size = safeU32ToU16(r.end - r.start);
		start = r.start;
	}

	//TODO: NOT INSTANCE
	immutable(RangeWithinFile) range() immutable{
		return immutable RangeWithinFile(start, start + size);
	}

	static immutable FileAndRange empty = immutable FileAndRange(FileIndex.none, RangeWithinFile.empty);
}
static assert(FileAndRange.sizeof == 8);

immutable(Sexpr) sexprOfFileAndPos(Alloc)(ref Alloc alloc, ref immutable FileAndPos a) {
	return tataRecord(
		alloc,
		"file-pos",
		tataNat(a.fileIndex.index),
		tataNat(a.pos));
}

immutable(Sexpr) sexprOfFileAndRange(Alloc)(ref Alloc alloc, ref immutable FileAndRange a) {
	return tataRecord(
		alloc,
		"file-range",
		tataNat(a.fileIndex.index),
		sexprOfRangeWithinFile(alloc, a.range));
}

immutable(Sexpr) sexprOfRangeWithinFile(Alloc)(ref Alloc alloc, immutable RangeWithinFile a) {
	return tataRecord(alloc, "range", tataNat(a.start), tataNat(a.end));
}
