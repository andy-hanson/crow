module test.testSourceRange;

@safe @nogc pure nothrow:

import test.testUtil : Test;
import util.sourceRange :
	LineAndCharacter, LineAndColumn, LineAndColumnGetter, lineAndColumnGetterForText, Pos, PosKind;
import util.string : CString, cString, MutCString, startsWith;

void testSourceRange(ref Test test) {
	testLF(test);
	testCR(test);
	testCRLF(test);
	testUnicode(test);
}

private:

void testLF(ref Test test) {
	LineAndColumnGetter lcg = lineAndColumnGetterForText(test.alloc, cString!"a\n\tbb\nc\n");
	testLFOrCR(lcg);
}

void testCR(ref Test test) {
	LineAndColumnGetter lcg = lineAndColumnGetterForText(test.alloc, cString!"a\r\tbb\rc\r");
	testLFOrCR(lcg);
}

void testLFOrCR(in LineAndColumnGetter lcg) {
	verifyConvert(lcg, 0, line: 0, character: 0); // a
	verifyConvert(lcg, 0, line: 0, character: 0); //
	verifyConvert(lcg, 1, line: 0, character: 1); // \n or \r
	verifyConvert(lcg, 2, line: 1, character: 0); // \t
	verifyConvert(lcg, 2, PosKind.endOfRange, line: 0, character: 1, column: 1, convertBackPos: 1);
	verifyConvert(lcg, 3, line: 1, character: 1, column: 4); // b
	verifyConvert(lcg, 4, line: 1, character: 2, column: 5); // b
	verifyConvert(lcg, 5, line: 1, character: 3, column: 6); // \n or \r
	verifyConvert(lcg, 6, line: 2, character: 0); // c
	verifyConvert(lcg, 7, line: 2, character: 1); // \n or \r
	verifyConvert(lcg, 8, line: 3, character: 0); // end

	assert(lcg[LineAndColumn(0, 99)] == 1);
	assert(lcg.lineAndCharacterGetter[LineAndCharacter(0, 99)] == 1);
	assert(lcg[LineAndColumn(99, 99)] == 8);
	assert(lcg.lineAndCharacterGetter[LineAndCharacter(99, 99)] == 8);
}

void testCRLF(ref Test test) {
	LineAndColumnGetter lcg = lineAndColumnGetterForText(test.alloc, cString!"a\r\n\tbb\r\nc\r\n");
	verifyConvert(lcg, 0, line: 0, character: 0); // a
	verifyConvert(lcg, 1, line: 0, character: 1); // \r
	verifyConvert(lcg, 2, PosKind.startOfRange, line: 0, character: 1, column: 1, convertBackPos: 1); // \n
	verifyConvert(lcg, 2, PosKind.endOfRange, line: 0, character: 1, column: 1, convertBackPos: 1);
	verifyConvert(lcg, 3, line: 1, character: 0); // \t
	verifyConvert(lcg, 3, PosKind.endOfRange, line: 0, character: 1, column: 1, convertBackPos: 1);
	verifyConvert(lcg, 4, line: 1, character: 1, column: 4); // b
	verifyConvert(lcg, 5, line: 1, character: 2, column: 5); // b
	verifyConvert(lcg, 6, line: 1, character: 3, column: 6); // \r
	verifyConvert(lcg, 7, PosKind.startOfRange, line: 1, character: 3, column: 6, convertBackPos: 6); // \n
	verifyConvert(lcg, 8, line: 2, character: 0); // c
	verifyConvert(lcg, 9, line: 2, character: 1, column: 1); // \r
	verifyConvert(lcg, 10, PosKind.startOfRange, line: 2, character: 1, column: 1, convertBackPos: 9); // \n
	verifyConvert(lcg, 11, line: 3, character: 0); // end
}

void testUnicode(ref Test test) {
	assert("$".length == 1 && "¥".length == 2 && "₿".length == 3 && "𝄮".length == 4);
	CString text = cString!"x\n$¥₿𝄮\ny";
	Pos cash = assertIndexOf(text, "$", 2);
	Pos yen = assertIndexOf(text, "¥", 3);
	Pos bitcoin = assertIndexOf(text, "₿", 5);
	Pos natural = assertIndexOf(text, "𝄮", 8);
	Pos y = assertIndexOf(text, "y", 13);

	LineAndColumnGetter lcg = lineAndColumnGetterForText(test.alloc, text);
	verifyConvert(lcg, cash, line: 1, character: 0);
	verifyConvert(lcg, yen, line:1, character: 1);
	verifyConvert(lcg, bitcoin, line: 1, character: 2);
	verifyConvert(lcg, natural, line: 1, character: 3);
	verifyConvert(lcg, y - 1, line: 1, character: 4);
	verifyConvert(lcg, y, line: 2, character: 0);
}

Pos assertIndexOf(in CString a, in string substring, Pos expected) {
	MutCString cur = a;
	while (true) {
		assert(*cur != '\0');
		if (startsWith(cur, substring)) {
			assert(cur - a == expected);
			return expected;
		}
		cur++;
	}
}

void verifyConvert(in LineAndColumnGetter lcg, Pos pos, uint line, uint character) {
	verifyConvert(lcg, pos, line, character, column: character);
}
void verifyConvert(in LineAndColumnGetter lcg, Pos pos, uint line, uint character, uint column) {
	verifyConvert(lcg, pos, PosKind.startOfRange, line, character, column, pos);
}
void verifyConvert(
	in LineAndColumnGetter lcg,
	Pos pos,
	PosKind kind,
	uint line,
	uint character,
	uint column,
	Pos convertBackPos,
) {
	LineAndCharacter lineAndCharacter = LineAndCharacter(line, character);
	LineAndColumn lineAndColumn = LineAndColumn(line, column);
	assert(lcg.lineAndCharacterGetter[pos, kind] == lineAndCharacter);
	assert(lcg[pos, kind] == lineAndColumn);
	assert(lcg.lineAndCharacterGetter[lineAndCharacter] == convertBackPos);
	assert(lcg[lineAndColumn] == convertBackPos);
}
