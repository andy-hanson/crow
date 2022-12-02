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
	Pos[] lineToPos;
	ubyte[] lineToNTabs;

	this(immutable Pos[] lp, immutable ubyte[] lnt) {
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

	while (*ptr != '\0') {
		bool nl = *ptr == '\n' || (*ptr == '\r' && *(ptr + 1) != '\n');
		ptr++;
		if (nl) {
			add(alloc, lineToPos, safeToUint(ptr - text.ptr));
			add(alloc, lineToNTabs, advanceAndGetNTabs(ptr));
		}
	}

	return LineAndColumnGetter(finishArr(alloc, lineToPos), finishArr(alloc, lineToNTabs));
}

LineAndColumnGetter lineAndColumnGetterForEmptyFile(ref Alloc alloc) =>
	lineAndColumnGetterForText(alloc, safeCStr!"");

LineAndColumn lineAndColumnAtPos(in LineAndColumnGetter lc, Pos pos) {
	ushort lowLine = 0; // inclusive
	ushort highLine = safeToUshort(lc.lineToPos.length);

	while (lowLine < highLine - 1) {
		ushort middleLine = mid(lowLine, highLine);
		Pos middlePos = lc.lineToPos[middleLine];
		if (pos == middlePos)
			return LineAndColumn(middleLine, 0);
		else if (pos < middlePos)
			// Exclusive -- must be on a previous line
			highLine = middleLine;
		else
			// Inclusive -- may be on a later character of the same line
			lowLine = middleLine;
	}

	ushort line = lowLine;
	Pos lineStart = lc.lineToPos[line];
	verify((pos >= lineStart && line == lc.lineToPos.length - 1) || pos <= lc.lineToPos[line + 1]);

	uint nCharsIntoLine = pos - lineStart;
	ubyte nTabs = lc.lineToNTabs[line];
	uint column = nCharsIntoLine <= nTabs
		? nCharsIntoLine * TAB_SIZE
		: nTabs * (TAB_SIZE - 1) + nCharsIntoLine;
	return LineAndColumn(line, safeToUshort(column));
}

private:

uint TAB_SIZE() => 4; // TODO: configurable

ushort mid(ushort a, ushort b) =>
	(a + b) / 2;

@system ubyte advanceAndGetNTabs(ref immutable(char)* a) {
	immutable char* begin = a;
	while (*a == '\t') a++;
	return cast(ubyte) (a - begin);
}
