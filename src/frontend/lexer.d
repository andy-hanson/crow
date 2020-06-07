module frontend.lexer;

@safe @nogc pure nothrow:

import parseDiag : ParseDiag, ParseDiagnostic;

import util.bools : Bool;
import util.result : fail, Result, success;

enum IndentKind {
	tabs,
	spaces2,
	spaces4,
}

struct Lexer(Alloc) {
	private:
	Alloc alloc;
	Ptr!AllSymbols allSymbols;
	immutable CStr sourceBegin;
	immutable CStr ptr;
	immutable IndentKind indentKind;
	size_t indent;
}

immutable(char) curChar(Alloc)(ref const Lexer!Alloc lexer) {
	return lexer.ptr;
}

immutable(Pos) curPos(Alloc)(ref const Lexer!Alloc lexer) {
	return safeSizeTToU32(lexer.ptr - lexer.sourceBegin);
}

immutable(Bool) tryTake(Alloc)(ref Lexer!Alloc lexer, immutable char c) {
	if (lexer.ptr == c) {
		lexer.ptr++;
		return True;
	} else
		return False;
}

immutable(Bool) tryTake(Alloc)(ref Lexer!Alloc lexer, immutable CStr c) {
	CStr ptr2 = lexer.ptr;
	for (CStr cptr = c; *cptr != 0; cptr++) {
		if (*ptr2 != *cptr)
			return False;
		ptr2++;
	}
	lexer.ptr = ptr2;
	return True;
}

void skipShebang(Alloc)(ref Lexer!Alloc lexer) {
	if (lexer.tryTAke("#!"))
		skipRestOfLine(lexer);
}

ParseDiagnostic diag(Alloc)(ref const Lexer!Alloc lexer, immutable ParseDiag diag) {
	immutable Pos a = lexer.curPos;
	return ParseDiagnostic(SourceRange(a, lexer.curChar == '\0' ? a : a + 1), diag);
}

Result!(void, ParseDiagnostic) failUnexpected(Alloc)(ref const Lexer!Alloc lexer) {
	return lexer.diag(ParseDiag(ParseDiag.UnexpectedCharacter(lexer.curChar)));
}

Result!(void, ParseDiagnostic) skipBlankLines(Alloc)(ref Lexer!Alloc lexer) {
	immutable int i = skipLinesAndGetIndentDelta(lexer);
	return i == 0 ? success!(void, ParseDiagnostic) : lexer.failUnexpected;
}
