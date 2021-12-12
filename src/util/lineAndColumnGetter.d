module util.lineAndColumnGetter;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc;
import util.collection.arr : at;
import util.collection.arrBuilder : add, ArrBuilder, finishArr;
import util.conv : safeToUint, safeToUshort;
import util.sourceRange : Pos;
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
		verify(lineToPos.length == lineToNTabs.length);
	}
}

immutable(LineAndColumnGetter) lineAndColumnGetterForText(ref Alloc alloc, immutable string text) {
	ArrBuilder!Pos lineToPos;
	ArrBuilder!ubyte lineToNTabs;

	add(alloc, lineToPos, 0);
	add(alloc, lineToNTabs, getNTabs(text));

	foreach (immutable uint i; 0 .. safeToUint(text.length)) {
		if (at(text, i) == '\n') {
			add(alloc, lineToPos, i + 1);
			add(alloc, lineToNTabs, getNTabs(text[i + 1 .. $]));
		}
	}

	return immutable LineAndColumnGetter(finishArr(alloc, lineToPos), finishArr(alloc, lineToNTabs));
}

immutable(LineAndColumnGetter) lineAndColumnGetterForEmptyFile(ref Alloc alloc) {
	return lineAndColumnGetterForText(alloc, "");
}

immutable(LineAndColumn) lineAndColumnAtPos(ref immutable LineAndColumnGetter lc, immutable Pos pos) {
	ushort lowLine = 0; // inclusive
	ushort highLine = safeToUshort(lc.lineToPos.length);

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
	verify((pos >= lineStart && line == lc.lineToPos.length - 1) || pos <= at(lc.lineToPos, line + 1));

	immutable uint nCharsIntoLine = pos - lineStart;
	immutable ubyte nTabs = at(lc.lineToNTabs, line);
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

ubyte getNTabs(immutable string text) {
	ubyte i = 0;
	while (i < ubyte.max
		&& i < text.length
		&& at(text, i) == '\t'
	) {
		i++;
	}
	return i;
}
