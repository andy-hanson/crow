module frontend.parse.lexWhitespace;

@safe @nogc pure nothrow:

import frontend.parse.lexUtil : isWhitespace, tryTakeChar, tryTakeChars;
import model.parseDiag : ParseDiag;
import util.col.array : isEmpty;
import util.conv : safeIntFromUint, safeToUint;
import util.string : CString, cStringIsEmpty, MutCString, stringOfRange;
import util.util : castNonScope_ref;

private alias AddDiag = void delegate(ParseDiag) @safe @nogc pure nothrow;

enum IndentKind {
	tabs,
	spaces2,
	spaces4,
}

// Note: Not issuing any diagnostics here. We'll fail later if we detect the wrong indent kind.
IndentKind detectIndentKind(in CString a) {
	MutCString ptr = a;
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
				size_t n = ptr - a;
				// Only allowed amounts are 2 and 4.
				return n == 2 ? IndentKind.spaces2 : IndentKind.spaces4;
			default:
				while (!cStringIsEmpty(ptr) && !isNewlineChar(*ptr))
					ptr++;
				if (isNewlineChar(*ptr))
					ptr++;
				continue;
		}
	}
}

void skipUntilNewline(scope ref MutCString ptr) {
	while (!isNewlineChar(*ptr) && *ptr != '\0')
		ptr++;
}

void skipSpacesAndComments(scope ref MutCString ptr) {
	while (true) {
		switch (*ptr) {
			case ' ':
			case '\t':
			case '\r':
				ptr++;
				continue;
			case '\\':
				scope MutCString ptr2 = ptr;
				ptr2++;
				while (tryTakeChar(ptr2, ' ')) {}
				if (tryTakeNewline(ptr2)) {
					while (tryTakeNewline(ptr2) || tryTakeChar(ptr2, ' ')) {}
					ptr = castNonScope_ref(ptr2);
					continue;
				} else
					return;
			case '#':
				skipUntilNewline(ptr);
				return;
			default:
				return;
		}
	}
}

immutable struct DocCommentAndIndentDelta {
	string docComment;
	int indentDelta;
}

DocCommentAndIndentDelta skipBlankLinesAndGetIndentDelta(
	ref MutCString ptr,
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

		if (*ptr == '\0')
			// Ignore indent before EOF
			newIndent = 0;

		// If we got here, we're looking at a non-empty line (or EOF)
		int delta = safeIntFromUint(newIndent) - safeIntFromUint(curIndent);
		if (delta > 1) {
			addDiag(ParseDiag(ParseDiag.IndentTooMuch()));
			skipRestOfLineAndNewline(ptr);
			continue;
		} else {
			curIndent = newIndent;
			return DocCommentAndIndentDelta(docComment, delta);
		}
	}
}

private:

bool isNewlineChar(char c) =>
	c == '\r' || c == '\n';

void skipRestOfLineAndNewline(ref MutCString ptr) {
	skipUntilNewline(ptr);
	cast(void) tryTakeNewline(ptr);
}

bool tryTakeNewline(ref MutCString ptr) =>
	tryTakeChar(ptr, '\r') || tryTakeChar(ptr, '\n');

uint takeIndentAmountAfterNewline(ref MutCString ptr, IndentKind indentKind, in AddDiag addDiag) {
	final switch (indentKind) {
		case IndentKind.tabs:
			CString begin = ptr;
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

uint takeIndentAmountAfterNewlineSpaces(ref MutCString ptr, uint nSpacesPerIndent, in AddDiag addDiag) {
	CString begin = ptr;
	while (tryTakeChar(ptr, ' ')) {}
	if (*ptr == '\t')
		addDiag(ParseDiag(ParseDiag.IndentWrongCharacter(false)));
	uint nSpaces = safeToUint(ptr - begin);
	uint res = nSpaces / nSpacesPerIndent;
	if (res * nSpacesPerIndent != nSpaces)
		addDiag(ParseDiag(ParseDiag.IndentNotDivisible(nSpaces, nSpacesPerIndent)));
	return res;
}

string takeRestOfBlockComment(return scope ref MutCString ptr, in AddDiag addDiag) {
	CString begin = ptr;
	CString end = skipRestOfBlockComment(ptr, addDiag);
	return stripWhitespace(stringOfRange(begin, end));
}

string takeRestOfLineAndNewline(return scope ref MutCString ptr) {
	CString begin = ptr;
	skipUntilNewline(ptr);
	string res = stringOfRange(begin, ptr);
	cast(void) tryTakeNewline(ptr);
	return res;
}

string stripWhitespace(string a) {
	while (!isEmpty(a) && isWhitespace(a[0]))
		a = a[1 .. $];
	while (!isEmpty(a) && isWhitespace(a[$ - 1]))
		a = a[0 .. $ - 1];
	return a;
}

bool tryTakeTripleHashThenNewline(ref MutCString ptr) =>
	tryTakeChars(ptr, "###\r") || tryTakeChars(ptr, "###\n");

// Returns the end of the comment text (ptr will be advanced further, past the '###')
CString skipRestOfBlockComment(ref MutCString ptr, in AddDiag addDiag) {
	while (true) {
		skipRestOfLineAndNewline(ptr);
		while (tryTakeChar(ptr, '\t') || tryTakeChar(ptr, ' ')) {}
		CString end = ptr;
		if (tryTakeTripleHashThenNewline(ptr))
			return end;
		else if (*ptr == '\0') {
			addDiag(ParseDiag(ParseDiag.Expected(ParseDiag.Expected.Kind.blockCommentEnd)));
			return end;
		}
	}
}
