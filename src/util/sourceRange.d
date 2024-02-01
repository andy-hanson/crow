module util.sourceRange;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc;
import util.comparison : compareOr, compareUint, Comparison;
import util.col.arrayBuilder : add, ArrayBuilder, finish;
import util.conv : safeToUint;
import util.json : field, Json, jsonObject;
import util.string : CString, MutCString;
import util.uri : AllUris, compareUriAlphabetically, stringOfUri, Uri;
import util.util : min;

alias Pos = uint;

immutable struct Range {
	@safe @nogc pure nothrow:

	Pos start;
	Pos end;

	this(Pos s, Pos e) {
		start = s;
		end = e;
		assert(start <= end);
	}

	static Range empty() =>
		Range(0, 0);

	uint opDollar(size_t i : 0)() =>
		length;

	uint length() =>
		end - start;

	Range opSlice(uint low, uint high) =>
		Range(start + low, start + high);
}

bool rangeContains(in Range a, in Range b) =>
	a.start <= b.start && b.end <= a.end;

Comparison compareRange(in Range a, in Range b) =>
	compareOr(compareUint(a.start, b.start), () => compareUint(a.end, b.end));

Range combineRanges(in Range a, in Range b) =>
	Range(a.start, b.end);

bool hasPos(in Range a, Pos p) =>
	a.start <= p && p < a.end;

Range rangeOfStartAndLength(Pos start, size_t length) =>
	Range(start, safeToUint(start + length));

immutable struct UriAndPos {
	@safe @nogc pure nothrow:

	Uri uri;
	Pos pos;

	static UriAndPos empty() =>
		UriAndPos(Uri.empty, 0);
}

immutable struct UriAndRange {
	@safe @nogc pure nothrow:

	Uri uri;
	Range range;

	Pos start() =>
		range.start;

	static UriAndRange empty() =>
		topOfFile(Uri.empty);

	static UriAndRange topOfFile(Uri uri) =>
		UriAndRange(uri, Range.empty);
}

Comparison compareUriAndRange(in AllUris allUris, UriAndRange a, UriAndRange b) {
	Comparison cmpUri = compareUriAlphabetically(allUris, a.uri, b.uri);
	return cmpUri != Comparison.equal ? cmpUri : compareRange(a.range, b.range);
}

UriAndPos toUriAndPos(UriAndRange a) =>
	UriAndPos(a.uri, a.start);

immutable struct LineAndCharacter {
	uint line;
	// This counts tabs as 1 character.
	uint character;
}

immutable struct LineAndColumnRange {
	LineAndColumn start;
	LineAndColumn end;
}

immutable struct UriLineAndColumn {
	Uri uri;
	LineAndColumn pos;
}

immutable struct UriLineAndColumnRange {
	Uri uri;
	LineAndColumnRange range;
}

immutable struct LineAndColumn {
	@safe @nogc pure nothrow:

	uint line0Indexed;
	// This counts tabs as TAB_SIZE characters.
	uint column0Indexed;

	uint line1Indexed() =>
		line0Indexed + 1;
	uint column1Indexed() =>
		column0Indexed + 1;
}

immutable struct LineAndCharacterRange {
	LineAndCharacter start;
	LineAndCharacter end;
}

immutable struct UriAndLineAndCharacterRange {
	Uri uri;
	LineAndCharacterRange range;
}

Json jsonOfUriAndLineAndCharacterRange(ref Alloc alloc, in AllUris allUris, in UriAndLineAndCharacterRange a) =>
	jsonObject(alloc, [
		field!"uri"(stringOfUri(alloc, allUris, a.uri)),
		field!"range"(jsonOfLineAndCharacterRange(alloc, a.range))]);

Json jsonOfLineAndColumnRange(ref Alloc alloc, in LineAndColumnRange a) =>
	jsonObject(alloc, [
		field!"start"(jsonOfLineAndColumn(alloc, a.start)),
		field!"end"(jsonOfLineAndColumn(alloc, a.end))]);

Json jsonOfLineAndCharacterRange(ref Alloc alloc, in LineAndCharacterRange a) =>
	jsonObject(alloc, [
		field!"start"(jsonOfLineAndCharacter(alloc, a.start)),
		field!"end"(jsonOfLineAndCharacter(alloc, a.end))]);

Json jsonOfLineAndColumn(ref Alloc alloc, in LineAndColumn a) =>
	jsonObject(alloc, [field!"line"(a.line1Indexed), field!"column"(a.column1Indexed)]);

private Json jsonOfLineAndCharacter(ref Alloc alloc, in LineAndCharacter a) =>
	jsonObject(alloc, [field!"line"(a.line), field!"character"(a.character)]);

immutable struct LineAndCharacterGetter {
	@safe @nogc pure nothrow:

	uint[] lineToPos;
	uint maxPos;
	bool usesCRLF;

	static LineAndCharacterGetter empty() {
		static immutable Pos[] emptyLineToPos = [0];
		return LineAndCharacterGetter(emptyLineToPos, 0, false);
	}

	Pos opIndex(in LineAndCharacter lc) scope =>
		lc.line >= lineToPos.length
			? maxPos
			: min(
				lineToPos[lc.line] + lc.character,
				lc.line >= lineToPos.length - 1 ? maxPos : lineToPos[lc.line + 1] - 1);

	Range opIndex(in LineAndCharacterRange lc) scope =>
		Range(this[lc.start], this[lc.end]);

	LineAndCharacter opIndex(Pos pos, PosKind kind) scope {
		uint line = lineAtPos(lineToPos, pos);
		if (kind == PosKind.endOfRange && lineToPos[line] == pos && line != 0) {
			// Show end of range at the end of the previous line
			line--;
			pos--;
		}
		Pos lineStart = lineToPos[line];
		assert((pos >= lineStart && line == lineToPos.length - 1) || pos <= lineToPos[line + 1]);
		uint character = pos - lineStart;
		// Don't include a column for the '\r' in '\r\n'
		if (usesCRLF && line + 1 < lineToPos.length && pos + 1 == lineToPos[line + 1])
			character--;
		return LineAndCharacter(line, character);
	}

	LineAndCharacterRange opIndex(in Range range) scope =>
		LineAndCharacterRange(this[range.start, PosKind.startOfRange], this[range.end, PosKind.endOfRange]);
}

immutable struct LineAndColumnGetter {
	@safe @nogc pure nothrow:
	LineAndCharacterGetter lineAndCharacterGetter;
	ubyte[] lineToNTabs;

	static LineAndColumnGetter empty() {
		static immutable ubyte[] emptyLineToNTabs = [0];
		return LineAndColumnGetter(LineAndCharacterGetter.empty, emptyLineToNTabs);
	}

	Pos opIndex(in LineAndColumn x) scope =>
		lineAndCharacterGetter[toLineAndCharacter(this, x)];

	LineAndColumn opIndex(Pos pos, PosKind kind) scope {
		LineAndCharacter res = lineAndCharacterGetter[pos, kind];
		ubyte nTabs = lineToNTabs[res.line];
		uint column = res.character <= nTabs
			? res.character * TAB_SIZE
			: nTabs * (TAB_SIZE - 1) + res.character;
		return LineAndColumn(res.line, column);
	}

	LineAndColumnRange opIndex(in Range range) scope =>
		LineAndColumnRange(this[range.start, PosKind.startOfRange], this[range.end, PosKind.endOfRange]);
}

LineAndCharacter toLineAndCharacter(in LineAndColumnGetter a, in LineAndColumn lc) =>
	LineAndCharacter(
		lc.line0Indexed,
		columnToCharacter(
			lc.column0Indexed,
			lc.line0Indexed < a.lineToNTabs.length ? a.lineToNTabs[lc.line0Indexed] : 0));

LineAndColumnGetter lineAndColumnGetterForText(ref Alloc alloc, scope CString text) {
	ArrayBuilder!Pos lineToPos;
	ArrayBuilder!ubyte lineToNTabs;

	MutCString ptr = text;

	add(alloc, lineToPos, 0);
	add(alloc, lineToNTabs, advanceAndGetNTabs(ptr));

	bool usesCRLF = false;
	while (*ptr != '\0') {
		char x = *ptr;
		ptr++;
		if (x == '\r' && *ptr == '\n') usesCRLF = true;
		if (x == '\n' || (x == '\r' && *ptr != '\n')) {
			add(alloc, lineToPos, safeToUint(ptr - text));
			add(alloc, lineToNTabs, advanceAndGetNTabs(ptr));
		}
	}

	return LineAndColumnGetter(
		LineAndCharacterGetter(finish(alloc, lineToPos), safeToUint(ptr - text), usesCRLF),
		finish(alloc, lineToNTabs));
}

enum PosKind { startOfRange, endOfRange }

uint lineLengthInCharacters(in LineAndCharacterGetter a, uint line) =>
	line < a.lineToPos.length - 1
		? a.lineToPos[line + 1] - a.lineToPos[line]
		: line == a.lineToPos.length - 1
		? a.maxPos - a.lineToPos[line]
		: 0;

private:

Pos columnToCharacter(uint column, ubyte nTabs) =>
	column <= nTabs * TAB_SIZE
		? column / TAB_SIZE
		: column - (nTabs * (TAB_SIZE - 1));

uint lineAtPos(in uint[] lineToPos, Pos pos) {
	uint lowLine = 0; // inclusive
	uint highLine = safeToUint(lineToPos.length);
	assert(highLine != 0);
	while (lowLine < highLine - 1) {
		uint middleLine = mid(lowLine, highLine);
		Pos middlePos = lineToPos[middleLine];
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

uint mid(uint a, uint b) =>
	(a + b) / 2;

ubyte advanceAndGetNTabs(ref MutCString a) {
	MutCString begin = a;
	while (*a == '\t') a++;
	return cast(ubyte) (a - begin);
}
