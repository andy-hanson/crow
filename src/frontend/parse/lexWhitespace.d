module frontend.parse.lexWhitespace;

@safe @nogc pure nothrow:

import model.parseDiag : ParseDiag;
import util.col.arr : arrOfRange, empty;
import util.col.str : SafeCStr;
import util.conv : safeIntFromUint, safeToUint;
import util.union_ : Union;
import util.util : drop;

private alias AddDiag = void delegate(ParseDiag) @safe @nogc pure nothrow;

enum IndentKind {
	tabs,
	spaces2,
	spaces4,
}

// Note: Not issuing any diagnostics here. We'll fail later if we detect the wrong indent kind.
@trusted IndentKind detectIndentKind(SafeCStr a) {
	immutable(char)* ptr = a.ptr;
	while (true) {
		switch (*ptr) {
			case '\0':
				// No indented lines, so it's irrelevant
				return IndentKind.tabs;
			case '\t':
				return IndentKind.tabs;
			case ' ':
				// Count spaces
				do { ptr++; } while (*ptr == ' ');
				size_t n = ptr - a.ptr;
				// Only allowed amounts are 2 and 4.
				return n == 2 ? IndentKind.spaces2 : IndentKind.spaces4;
			default:
				while (*ptr != '\0' && !isNewlineChar(*ptr))
					ptr++;
				if (isNewlineChar(*ptr))
					ptr++;
				continue;
		}
	}
}

void skipWhitespaceWithinLine(ref immutable(char)* ptr) {
	while (tryTakeChar(ptr, ' ') || tryTakeChar(ptr, '\t') || tryTakeChar(ptr, '\r')) {}
}

public @trusted void skipUntilNewline(ref immutable(char)* ptr) {
	while (!isNewlineChar(*ptr) && *ptr != '\0')
		ptr++;
}

private:

bool isNewlineChar(char c) =>
	c == '\r' || c == '\n';

void skipSpacesAndComments(ref immutable(char)* ptr) {
	while (true) {
		switch (*ptr) {
			case ' ':
			case '\t':
				continue;
			case '#':
				skipUntilNewline(ptr);
				return;
			default:
				return;
		}
	}
}

public @trusted bool tryTakeChar(ref immutable(char)* ptr, char c) {
	if (*ptr == c) {
		ptr++;
		return true;
	} else
		return false;
}

public @trusted bool tryTakeChars(ref immutable(char)* ptr, in string chars) {
	immutable(char)* ptr2 = ptr;
	foreach (immutable char expected; chars) {
		if (*ptr2 != expected)
			return false;
		ptr2++;
	}
	ptr = ptr2;
	return true;
}

public void skipRestOfLineAndNewline(ref immutable(char)* ptr) {
	skipUntilNewline(ptr);
	drop(tryTakeNewline(ptr));
}

bool tryTakeNewline(ref immutable(char)* ptr) =>
	tryTakeChar(ptr, '\r') || tryTakeChar(ptr, '\n');

uint takeIndentAmountAfterNewline(ref immutable(char)* ptr, IndentKind indentKind, in AddDiag addDiag) {
	final switch (indentKind) {
		case IndentKind.tabs:
			immutable char* begin = ptr;
			while (tryTakeChar(ptr, '\t')) {}
			if (*ptr == ' ')
				addDiag(ParseDiag(ParseDiag.IndentWrongCharacter(true)));
			return safeToUint(ptr - begin);
		case IndentKind.spaces2:
			return takeIndentAmountAfterNewlineSpaces(ptr, 2, addDiag);
		case IndentKind.spaces4:
			return takeIndentAmountAfterNewlineSpaces(ptr, 4, addDiag);
	}
}

uint takeIndentAmountAfterNewlineSpaces(ref immutable(char)* ptr, uint nSpacesPerIndent, in AddDiag addDiag) {
	immutable char* begin = ptr;
	while (tryTakeChar(ptr, ' ')) {}
	if (*ptr == '\t')
		addDiag(ParseDiag(ParseDiag.IndentWrongCharacter(false)));
	uint nSpaces = safeToUint(ptr - begin);
	uint res = nSpaces / nSpacesPerIndent;
	if (res * nSpacesPerIndent != nSpaces)
		addDiag(ParseDiag(ParseDiag.IndentNotDivisible(nSpaces, nSpacesPerIndent)));
	return res;
}

public immutable struct IndentDelta {
	immutable struct DedentOrSame {
		uint nDedents;
	}
	immutable struct Indent {}

	mixin Union!(DedentOrSame, Indent);
}

public IndentDelta skipBlankLinesAndGetIndentDelta(
	ref immutable(char)* ptr,
	IndentKind indentKind,
	ref uint curIndent,
	in AddDiag addDiag,
) {
	while (true) {
		// comment / region counts as a blank line no matter its indent level.
		uint newIndent = takeIndentAmountAfterNewline(ptr, indentKind, addDiag);
		if (tryTakeNewline(ptr))
			// Ignore lines that are just whitespace
			continue;

		// For indent == 0, we'll try taking any comments as doc comments
		if (newIndent != 0) {
			// Comments can mean a dedent
			if (tryTakeTripleHashThenNewline(ptr)) {
				drop(skipRestOfBlockComment(ptr, addDiag));
				continue;
			} else if (tryTakeChar(ptr, '#')) {
				skipRestOfLineAndNewline(ptr);
				continue;
			}
		}

		// If we got here, we're looking at a non-empty line (or EOF)
		int delta = safeIntFromUint(newIndent) - safeIntFromUint(curIndent);
		if (delta > 1) {
			addDiag(ParseDiag(ParseDiag.IndentTooMuch()));
			skipRestOfLineAndNewline(ptr);
			continue;
		} else {
			curIndent = newIndent;
			return delta == 1
				? IndentDelta(IndentDelta.Indent())
				: IndentDelta(IndentDelta.DedentOrSame(-delta));
		}
	}
}

public string skipBlankLinesAndGetDocComment(ref immutable(char)* ptr, in AddDiag addDiag) {
	string comment = "";
	while (true) {
		if (tryTakeNewline(ptr)) {
		} else if (tryTakeTripleHashThenNewline(ptr)) {
			comment = takeRestOfBlockComment(ptr, addDiag);
		} else if (tryTakeChar(ptr, '#')) {
			comment = takeRestOfLineAndNewline(ptr);
		} else if (tryTakeChars(ptr, "region ") || tryTakeChars(ptr, "subregion ")) {
			skipRestOfLineAndNewline(ptr);
			comment = "";
		} else
			return comment;
	}
}

@trusted string takeRestOfBlockComment(return scope ref immutable(char)* ptr, in AddDiag addDiag) {
	immutable char* begin = ptr;
	immutable char* end = skipRestOfBlockComment(ptr, addDiag);
	return stripWhitespace(arrOfRange(begin, end));
}

@trusted string takeRestOfLineAndNewline(return scope ref immutable(char)* ptr) {
	immutable char* begin = ptr;
	skipRestOfLineAndNewline(ptr);
	immutable char* end = ptr - 1;
	return arrOfRange(begin, end);
}

string stripWhitespace(string a) {
	while (!empty(a) && isWhitespace(a[0]))
		a = a[1 .. $];
	while (!empty(a) && isWhitespace(a[$ - 1]))
		a = a[0 .. $ - 1];
	return a;
}

public bool isWhitespace(char a) {
	switch (a) {
		case ' ':
		case '\t':
		case '\r':
		case '\n':
			return true;
		default:
			return false;
	}
}

bool tryTakeTripleHashThenNewline(ref immutable(char)* ptr) =>
	tryTakeChars(ptr, "###\r") || tryTakeChars(ptr, "###\n");

// Returns the end of the comment text (ptr will be advanced further, past the '###')
@trusted immutable(char*) skipRestOfBlockComment(ref immutable(char)* ptr, in AddDiag addDiag) {
	while (true) {
		skipRestOfLineAndNewline(ptr);
		while (tryTakeChar(ptr, '\t') || tryTakeChar(ptr, ' ')) {}
		immutable char* end = ptr;
		if (tryTakeTripleHashThenNewline(ptr))
			return end;
		else if (*ptr == '\0') {
			addDiag(ParseDiag(ParseDiag.Expected(ParseDiag.Expected.Kind.blockCommentEnd)));
			return end;
		}
	}
}

public @trusted IndentDelta takeNewlineAndReturnIndentDelta(
	ref immutable(char)* ptr,
	IndentKind indentKind,
	ref uint curIndent,
	in AddDiag addDiag,
) {
	skipSpacesAndComments(ptr);
	if (!tryTakeNewline(ptr)) {
		//TODO: not always expecting indent..
		addDiag(ParseDiag(ParseDiag.Expected(ParseDiag.Expected.Kind.indent)));
		skipRestOfLineAndNewline(ptr);
	}
	return skipBlankLinesAndGetIndentDelta(ptr, indentKind, curIndent, addDiag);
}
