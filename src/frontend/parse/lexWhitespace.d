module frontend.parse.lexWhitespace;

@safe @nogc pure nothrow:

import frontend.parse.lexUtil : isWhitespace, tryTakeChar, tryTakeChars;
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

@trusted void skipUntilNewline(ref immutable(char)* ptr) {
	while (!isNewlineChar(*ptr) && *ptr != '\0')
		ptr++;
}

@trusted void skipSpacesAndComments(ref immutable(char)* ptr) {
	while (true) {
		switch (*ptr) {
			case ' ':
			case '\t':
			case '\r':
				ptr++;
				continue;
			case '#':
				skipUntilNewline(ptr);
				return;
			default:
				return;
		}
	}
}

immutable struct IndentDelta {
	immutable struct DedentOrSame {
		uint nDedents;
	}
	immutable struct Indent {}

	mixin Union!(DedentOrSame, Indent);
}

immutable struct DocCommentAndIndentDelta {
	string docComment;
	IndentDelta indentDelta;
}

DocCommentAndIndentDelta skipBlankLinesAndGetIndentDelta(
	ref immutable(char)* ptr,
	IndentKind indentKind,
	ref uint curIndent,
	in AddDiag addDiag,
) {
	string docComment = "";
	while (true) {
		uint newIndent = takeIndentAmountAfterNewline(ptr, indentKind, addDiag);
		if (tryTakeNewline(ptr))
			continue;
		else if (tryTakeTripleHashThenNewline(ptr)) {
			docComment = takeRestOfBlockComment(ptr, addDiag);
			continue;
		} else if (tryTakeChar(ptr, '#')) {
			docComment = takeRestOfLineAndNewline(ptr);
			continue;
		} else if (tryTakeChars(ptr, "region ") || tryTakeChars(ptr, "subregion ")) {
			skipRestOfLineAndNewline(ptr);
			docComment = "";
			continue;
		}

		// If we got here, we're looking at a non-empty line (or EOF)
		int delta = safeIntFromUint(newIndent) - safeIntFromUint(curIndent);
		if (delta > 1) {
			addDiag(ParseDiag(ParseDiag.IndentTooMuch()));
			skipRestOfLineAndNewline(ptr);
			continue;
		} else {
			curIndent = newIndent;
			return DocCommentAndIndentDelta(docComment, delta == 1
				? IndentDelta(IndentDelta.Indent())
				: IndentDelta(IndentDelta.DedentOrSame(-delta)));
		}
	}
}

private:

bool isNewlineChar(char c) =>
	c == '\r' || c == '\n';

void skipRestOfLineAndNewline(ref immutable(char)* ptr) {
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
