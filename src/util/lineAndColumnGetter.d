module util.lineAndColumnGetter;

@safe @nogc pure nothrow:

import util.collection.arr : Arr, at, size;
import util.collection.arrUtil : slice;
import util.collection.arrBuilder : add, ArrBuilder, finishArr;
import util.collection.str : emptyStr, Str;
import util.sourceRange : Pos;
import util.types : safeSizeTToU16, safeSizeTToU32, safeU32ToU16, u8, u16, u32;
import util.util : verify;

struct LineAndColumn {
	immutable u16 line;
	immutable u16 column;
}

struct LineAndColumnGetter {
	@safe @nogc pure nothrow:
	immutable Arr!Pos lineToPos;
	immutable Arr!u8 lineToNTabs;

	immutable this(immutable Arr!Pos lp, immutable Arr!u8 lnt) {
		lineToPos = lp;
		lineToNTabs = lnt;
		verify(lineToPos.size == lineToNTabs.size);
	}
}

immutable(LineAndColumnGetter) lineAndColumnGetterForText(Alloc)(ref Alloc alloc, immutable Str text) {
	ArrBuilder!Pos lineToPos;
	ArrBuilder!u8 lineToNTabs;

	add(alloc, lineToPos, 0);
	add(alloc, lineToNTabs, text.getNTabs);

	foreach (immutable u32 i; 0..text.size.safeSizeTToU32) {
		if (text.at(i) == '\n') {
			add(alloc, lineToPos, i + 1);
			add(alloc, lineToNTabs, text.slice(i + 1).getNTabs);
		}
	}

	return immutable LineAndColumnGetter(finishArr(alloc, lineToPos), finishArr(alloc, lineToNTabs));
}

immutable(LineAndColumnGetter) lineAndColumnGetterForEmptyFile(Alloc)(ref Alloc alloc) {
	return lineAndColumnGetterForText(alloc, emptyStr);
}

immutable(LineAndColumn) lineAndColumnAtPos(ref immutable LineAndColumnGetter lc, immutable Pos pos) {
	u16 lowLine = 0; // inclusive
	u16 highLine = lc.lineToPos.size.safeSizeTToU16;

	while (lowLine < highLine - 1) {
		immutable u16 middleLine = lowLine.mid(highLine);
		immutable Pos middlePos = lc.lineToPos.at(middleLine);
		if (pos == middlePos)
			return LineAndColumn(middleLine, 0);
		else if (pos < middlePos)
			// Exclusive -- must be on a previous line
			highLine = middleLine;
		else
			// Inclusive -- may be on a later character of the same line
			lowLine = middleLine;
	}

	immutable u16 line = lowLine;
	immutable Pos lineStart = lc.lineToPos.at(line);
	verify((pos >= lineStart && line == lc.lineToPos.size - 1) || pos <= lc.lineToPos.at(line + 1));

	immutable u32 nCharsIntoLine = pos - lineStart;
	immutable u8 nTabs = lc.lineToNTabs.at(line);
	immutable u32 column = nCharsIntoLine <= nTabs
		? nCharsIntoLine * TAB_SIZE
		: nTabs * (TAB_SIZE - 1) + nCharsIntoLine;
	return LineAndColumn(line, column.safeU32ToU16);
}

private:

immutable u32 TAB_SIZE = 4; // TODO: configurable

u16 mid(immutable u16 a, immutable u16 b) {
	return (a + b) /  2;
}

u8 getNTabs(immutable Str text) {
	u8 i = 0;
	while (i < ubyte.max
		&& i < text.size
		&& text.at(i) == '\t'
	) {
		i++;
	}
	return i;
}
