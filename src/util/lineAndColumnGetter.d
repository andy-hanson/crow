module util.lineAndColumnGetter;

@safe @nogc pure nothrow:

import util.collection.arr : at, size;
import util.collection.arrBuilder : add, ArrBuilder, finishArr;
import util.sourceRange : Pos;
import util.types : safeSizeTToU16, safeSizeTToU32, safeU32ToU16;
import util.util : verify;

struct LineAndColumn {
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
		verify(size(lineToPos) == size(lineToNTabs));
	}
}

immutable(LineAndColumnGetter) lineAndColumnGetterForText(Alloc)(ref Alloc alloc, immutable string text) {
	ArrBuilder!Pos lineToPos;
	ArrBuilder!ubyte lineToNTabs;

	add(alloc, lineToPos, 0);
	add(alloc, lineToNTabs, text.getNTabs);

	foreach (immutable uint i; 0 .. safeSizeTToU32(size(text))) {
		if (at(text, i) == '\n') {
			add(alloc, lineToPos, i + 1);
			add(alloc, lineToNTabs, text[i + 1 .. $].getNTabs);
		}
	}

	return immutable LineAndColumnGetter(finishArr(alloc, lineToPos), finishArr(alloc, lineToNTabs));
}

immutable(LineAndColumnGetter) lineAndColumnGetterForEmptyFile(Alloc)(ref Alloc alloc) {
	return lineAndColumnGetterForText(alloc, "");
}

immutable(LineAndColumn) lineAndColumnAtPos(ref immutable LineAndColumnGetter lc, immutable Pos pos) {
	ushort lowLine = 0; // inclusive
	ushort highLine = size(lc.lineToPos).safeSizeTToU16;

	while (lowLine < highLine - 1) {
		immutable ushort middleLine = mid(lowLine, highLine);
		immutable Pos middlePos = at(lc.lineToPos, middleLine);
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
	immutable Pos lineStart = at(lc.lineToPos, line);
	verify((pos >= lineStart && line == size(lc.lineToPos) - 1) || pos <= at(lc.lineToPos, line + 1));

	immutable uint nCharsIntoLine = pos - lineStart;
	immutable ubyte nTabs = at(lc.lineToNTabs, line);
	immutable uint column = nCharsIntoLine <= nTabs
		? nCharsIntoLine * TAB_SIZE
		: nTabs * (TAB_SIZE - 1) + nCharsIntoLine;
	return immutable LineAndColumn(line, column.safeU32ToU16);
}

private:

immutable uint TAB_SIZE = 4; // TODO: configurable

ushort mid(immutable ushort a, immutable ushort b) {
	return (a + b) / 2;
}

ubyte getNTabs(immutable string text) {
	ubyte i = 0;
	while (i < ubyte.max
		&& i < size(text)
		&& at(text, i) == '\t'
	) {
		i++;
	}
	return i;
}
