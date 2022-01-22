module util.lineAndColumnGetter;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc;
import util.col.arrBuilder : add, ArrBuilder, finishArr;
import util.col.str : SafeCStr, safeCStr;
import util.conv : safeToUint, safeToUshort;
import util.sourceRange : Pos;
import util.util : verify;

struct LineAndColumn {
	// both 0-indexed
	immutable ushort line;
	immutable ushort column;
}

struct LineAndColumnGetter {
	@safe @nogc pure nothrow:
	immutable Pos[] lineToPos;
	immutable ubyte[] lineToNTabs;

	immutable this(immutable Pos[] lp, immutable ubyte[] lnt) {
		lineToPos = lp;
		lineToNTabs = lnt;
		verify(lineToPos.length == lineToNTabs.length);
	}
}

@trusted immutable(LineAndColumnGetter) lineAndColumnGetterForText(ref Alloc alloc, immutable SafeCStr text) {
	ArrBuilder!Pos lineToPos;
	ArrBuilder!ubyte lineToNTabs;

	immutable(char)* ptr = text.ptr;

	add(alloc, lineToPos, 0);
	add(alloc, lineToNTabs, advanceAndGetNTabs(ptr));

	while (*ptr != '\0') {
		immutable bool nl = *ptr == '\n';
		ptr++;
		if (nl) {
			add(alloc, lineToPos, safeToUint(ptr - text.ptr));
			add(alloc, lineToNTabs, advanceAndGetNTabs(ptr));
		}
	}

	return immutable LineAndColumnGetter(finishArr(alloc, lineToPos), finishArr(alloc, lineToNTabs));
}

immutable(LineAndColumnGetter) lineAndColumnGetterForEmptyFile(ref Alloc alloc) {
	return lineAndColumnGetterForText(alloc, safeCStr!"");
}

immutable(LineAndColumn) lineAndColumnAtPos(ref immutable LineAndColumnGetter lc, immutable Pos pos) {
	ushort lowLine = 0; // inclusive
	ushort highLine = safeToUshort(lc.lineToPos.length);

	while (lowLine < highLine - 1) {
		immutable ushort middleLine = mid(lowLine, highLine);
		immutable Pos middlePos = lc.lineToPos[middleLine];
		if (pos == middlePos)
			return LineAndColumn(middleLine, 0);
		else if (pos < middlePos)
			// Exclusive -- must be on a previous line
			highLine = middleLine;
		else
			// Inclusive -- may be on a later character of the same line
			lowLine = middleLine;
	}

	immutable ushort line = lowLine;
	immutable Pos lineStart = lc.lineToPos[line];
	verify((pos >= lineStart && line == lc.lineToPos.length - 1) || pos <= lc.lineToPos[line + 1]);

	immutable uint nCharsIntoLine = pos - lineStart;
	immutable ubyte nTabs = lc.lineToNTabs[line];
	immutable uint column = nCharsIntoLine <= nTabs
		? nCharsIntoLine * TAB_SIZE
		: nTabs * (TAB_SIZE - 1) + nCharsIntoLine;
	return immutable LineAndColumn(line, safeToUshort(column));
}

private:

immutable uint TAB_SIZE = 4; // TODO: configurable

ushort mid(immutable ushort a, immutable ushort b) {
	return (a + b) / 2;
}

@system ubyte advanceAndGetNTabs(ref immutable(char)* a) {
	immutable char* begin = a;
	while (*a == '\t') a++;
	return cast(ubyte) (a - begin);
}
