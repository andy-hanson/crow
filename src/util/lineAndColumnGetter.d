module util.lineAndColumnGetter;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc;
import util.col.arrBuilder : add, ArrBuilder, finishArr;
import util.col.str : SafeCStr, safeCStr;
import util.conv : safeToUint, safeToUshort;
import util.sourceRange : Pos;
import util.util : verify;

immutable struct LineAndColumn {
	// both 0-indexed
	ushort line;
	ushort column;
}

immutable struct LineAndColumnGetter {
	@safe @nogc pure nothrow:
	bool usesCRLF;
	Pos[] lineToPos;
	ubyte[] lineToNTabs;

	this(bool ucr, immutable Pos[] lp, immutable ubyte[] lnt) {
		usesCRLF = ucr;
		lineToPos = lp;
		lineToNTabs = lnt;
		verify(lineToPos.length == lineToNTabs.length);
	}
}

@trusted LineAndColumnGetter lineAndColumnGetterForText(ref Alloc alloc, scope SafeCStr text) {
	ArrBuilder!Pos lineToPos;
	ArrBuilder!ubyte lineToNTabs;

	immutable(char)* ptr = text.ptr;

	add(alloc, lineToPos, 0);
	add(alloc, lineToNTabs, advanceAndGetNTabs(ptr));

	bool usesCRLF = false;
	while (*ptr != '\0') {
		if (*ptr == '\r' && *(ptr + 1) == '\n') usesCRLF = true;
		bool nl = *ptr == '\n' || (*ptr == '\r' && *(ptr + 1) != '\n');
		ptr++;
		if (nl) {
			add(alloc, lineToPos, safeToUint(ptr - text.ptr));
			add(alloc, lineToNTabs, advanceAndGetNTabs(ptr));
		}
	}

	return LineAndColumnGetter(usesCRLF, finishArr(alloc, lineToPos), finishArr(alloc, lineToNTabs));
}

LineAndColumnGetter lineAndColumnGetterForEmptyFile(ref Alloc alloc) =>
	lineAndColumnGetterForText(alloc, safeCStr!"");

enum PosKind { startOfRange, endOfRange }

LineAndColumn lineAndColumnAtPos(in LineAndColumnGetter lc, Pos pos, PosKind kind) {
	ushort line = lineAtPos(lc, pos);
	if (kind == PosKind.endOfRange && lc.lineToPos[line] == pos && line != 0) {
		// Show end of range at the end of the previous line
		line--;
		pos--;
	}
	Pos lineStart = lc.lineToPos[line];
	verify((pos >= lineStart && line == lc.lineToPos.length - 1) || pos <= lc.lineToPos[line + 1]);
	uint nCharsIntoLine = pos - lineStart;
	// Don't include a column for the '\r' in '\r\n'
	if (lc.usesCRLF && line + 1 < lc.lineToPos.length && pos + 1 == lc.lineToPos[line + 1])
		nCharsIntoLine--;
	ubyte nTabs = lc.lineToNTabs[line];
	uint column = nCharsIntoLine <= nTabs
		? nCharsIntoLine * TAB_SIZE
		: nTabs * (TAB_SIZE - 1) + nCharsIntoLine;
	return LineAndColumn(line, safeToUshort(column));
}

private:

ushort lineAtPos(in LineAndColumnGetter lc, Pos pos) {
	ushort lowLine = 0; // inclusive
	ushort highLine = safeToUshort(lc.lineToPos.length);
	while (lowLine < highLine - 1) {
		ushort middleLine = mid(lowLine, highLine);
		Pos middlePos = lc.lineToPos[middleLine];
		if (pos == middlePos)
			return middleLine;
		else if (pos < middlePos)
			// Exclusive -- must be on a previous line
			highLine = middleLine;
		else
			// Inclusive -- may be on a later character of the same line
			lowLine = middleLine;
	}
	return lowLine;
}

uint TAB_SIZE() => 4; // TODO: configurable

ushort mid(ushort a, ushort b) =>
	(a + b) / 2;

@system ubyte advanceAndGetNTabs(ref immutable(char)* a) {
	immutable char* begin = a;
	while (*a == '\t') a++;
	return cast(ubyte) (a - begin);
}
