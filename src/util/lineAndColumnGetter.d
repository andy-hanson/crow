module util.lineAndColumnGetter;

@safe @nogc pure nothrow:

import frontend.storage : asSafeCStr, FileContent, ReadFileResult, Storage, withFileNoMarkUnknown;
import model.diag : ReadFileDiag;
import util.alloc.alloc : Alloc, MetaAlloc, newAlloc;
import util.col.arrBuilder : add, ArrBuilder, finishArr;
import util.col.mutMap : getOrAdd, mayDelete, MutMap;
import util.col.str : SafeCStr, safeCStr;
import util.conv : safeToUint;
import util.ptr : castNonScope_ref;
import util.sourceRange : Pos, Range, UriAndPos, UriAndRange;
import util.uri : Uri;
import util.util : min, verify;

struct LineAndColumnGetters {
	@safe @nogc pure nothrow:

	private:
	Alloc alloc;
	const Storage* storage;
	MutMap!(Uri, LineAndColumnGetter) getters;

	public:
	this(MetaAlloc* metaAlloc, return scope const Storage* s) {
		alloc = newAlloc(metaAlloc);
		storage = s;
	}

	LineAndColumnGetter opIndex(Uri uri) scope =>
		getOrAdd(castNonScope_ref(alloc), getters, uri, () =>
			withFileNoMarkUnknown!LineAndColumnGetter(*storage, uri, (in ReadFileResult x) =>
				x.matchIn!LineAndColumnGetter(
					(in FileContent content) =>
						lineAndColumnGetterForText(alloc, asSafeCStr(content)),
					(in ReadFileDiag _) =>
						lineAndColumnGetterForEmptyFile(alloc))));

	Pos opIndex(in UriLineAndCharacter x) scope =>
		this[x.uri][x.lineAndCharacter];
}

UriLineAndCharacter toLineAndCharacter(scope ref LineAndColumnGetters a, in UriLineAndColumn x) =>
	UriLineAndCharacter(x.uri, toLineAndCharacter(a[x.uri], x.lineAndColumn));

void uncacheFile(scope ref LineAndColumnGetters a, Uri uri) {
	// TODO: also free memory
	mayDelete(a.getters, uri);
}

LineAndColumn lineAndColumnAtPos(ref LineAndColumnGetters a, in UriAndPos pos, PosKind kind) =>
	lineAndColumnAtPos(a[pos.uri], pos.pos, kind);

LineAndCharacter lineAndCharacterAtPos(ref LineAndColumnGetters a, in UriAndPos pos, PosKind kind) =>
	lineAndCharacterAtPos(a[pos.uri], pos.pos, kind);

LineAndCharacterRange lineAndCharacterRange(scope ref LineAndColumnGetters a, in UriAndRange range) =>
	lineAndCharacterRange(a[range.uri], range.range);

LineAndColumnRange lineAndColumnRange(scope ref LineAndColumnGetters a, in UriAndRange range) =>
	lineAndColumnRange(a[range.uri], range.range);

LineAndCharacterRange lineAndCharacterRange(in LineAndColumnGetter a, in Range range) =>
	LineAndCharacterRange(
		lineAndCharacterAtPos(a, range.start, PosKind.startOfRange),
		lineAndCharacterAtPos(a, range.end, PosKind.endOfRange));

LineAndColumnRange lineAndColumnRange(in LineAndColumnGetter a, in Range range) =>
	LineAndColumnRange(
		lineAndColumnAtPos(a, range.start, PosKind.startOfRange),
		lineAndColumnAtPos(a, range.end, PosKind.endOfRange));

immutable struct UriLineAndCharacter {
	Uri uri;
	LineAndCharacter lineAndCharacter;
}

immutable struct UriLineAndColumn {
	Uri uri;
	LineAndColumn lineAndColumn;
}

immutable struct LineAndCharacter {
	uint line;
	// This counts tabs as 1 character.
	uint character;
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

immutable struct LineAndColumnRange {
	LineAndColumn start;
	LineAndColumn end;
}

immutable struct LineAndCharacterRange {
	LineAndCharacter start;
	LineAndCharacter end;
}

immutable struct LineAndColumnGetter {
	@safe @nogc pure nothrow:
	bool usesCRLF;
	Pos maxPos;
	Pos[] lineToPos;
	ubyte[] lineToNTabs;

	this(bool ucr, Pos mp, immutable Pos[] lp, immutable ubyte[] lnt) {
		usesCRLF = ucr;
		maxPos = mp;
		lineToPos = lp;
		lineToNTabs = lnt;
		verify(lineToPos.length == lineToNTabs.length);
	}

	Pos opIndex(in LineAndCharacter lc) scope =>
		lc.line >= lineToPos.length
			? maxPos
			: min(
				lineToPos[lc.line] + lc.character,
				lc.line >= lineToPos.length - 1 ? maxPos : lineToPos[lc.line + 1] - 1);

	Pos opIndex(in LineAndColumn lc) scope =>
		this[toLineAndCharacter(this, lc)];
}

LineAndCharacter toLineAndCharacter(in LineAndColumnGetter a, in LineAndColumn lc) =>
	LineAndCharacter(
		lc.line0Indexed,
		columnToCharacter(
			lc.column0Indexed,
			lc.line0Indexed < a.lineToNTabs.length ? a.lineToNTabs[lc.line0Indexed] : 0));

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

	return LineAndColumnGetter(
		usesCRLF,
		safeToUint(ptr - text.ptr),
		finishArr(alloc, lineToPos),
		finishArr(alloc, lineToNTabs));
}

private LineAndColumnGetter lineAndColumnGetterForEmptyFile(ref Alloc alloc) =>
	lineAndColumnGetterForText(alloc, safeCStr!"");

enum PosKind { startOfRange, endOfRange }

LineAndColumn lineAndColumnAtPos(in LineAndColumnGetter lc, Pos pos, PosKind kind) {
	LineAndCharacter res = lineAndCharacterAtPos(lc, pos, kind);
	ubyte nTabs = lc.lineToNTabs[res.line];
	uint column = res.character <= nTabs
		? res.character * TAB_SIZE
		: nTabs * (TAB_SIZE - 1) + res.character;
	return LineAndColumn(res.line, column);
}

LineAndCharacter lineAndCharacterAtPos(in LineAndColumnGetter lc, Pos pos, PosKind kind) {
	uint line = lineAtPos(lc, pos);
	if (kind == PosKind.endOfRange && lc.lineToPos[line] == pos && line != 0) {
		// Show end of range at the end of the previous line
		line--;
		pos--;
	}
	Pos lineStart = lc.lineToPos[line];
	verify((pos >= lineStart && line == lc.lineToPos.length - 1) || pos <= lc.lineToPos[line + 1]);
	uint character = pos - lineStart;
	// Don't include a column for the '\r' in '\r\n'
	if (lc.usesCRLF && line + 1 < lc.lineToPos.length && pos + 1 == lc.lineToPos[line + 1])
		character--;
	return LineAndCharacter(line, character);
}

private:

Pos columnToCharacter(uint column, ubyte nTabs) =>
	column <= nTabs * TAB_SIZE
		? column / TAB_SIZE
		: column - (nTabs * (TAB_SIZE - 1));

uint lineAtPos(in LineAndColumnGetter lc, Pos pos) {
	uint lowLine = 0; // inclusive
	uint highLine = safeToUint(lc.lineToPos.length);
	while (lowLine < highLine - 1) {
		uint middleLine = mid(lowLine, highLine);
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

uint mid(uint a, uint b) =>
	(a + b) / 2;

@system ubyte advanceAndGetNTabs(ref immutable(char)* a) {
	immutable char* begin = a;
	while (*a == '\t') a++;
	return cast(ubyte) (a - begin);
}
