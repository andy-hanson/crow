module test.testLineAndColumnGetter;

@safe @nogc pure nothrow:

import test.testUtil : Test;
import util.lineAndColumnGetter :
	LineAndColumn, lineAndColumnAtPos, LineAndColumnGetter, lineAndColumnGetterForText, PosKind;
import util.opt : force, has, none, Opt, some;
import util.sourceRange : Pos;
import util.string : cString;

void testLineAndColumnGetter(ref Test test) {
	testLF(test);
	testCR(test);
	testCRLF(test);
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
	verifyConvert(lcg, Pos(0), PosKind.startOfRange, LineAndColumn(0, 0));
	verifyConvert(lcg, Pos(1), PosKind.startOfRange, LineAndColumn(0, 1));
	verifyConvert(lcg, Pos(2), PosKind.startOfRange, LineAndColumn(1, 0));
	verifyConvert(lcg, Pos(2), PosKind.endOfRange, LineAndColumn(0, 1), some(Pos(1)));
	verifyConvert(lcg, Pos(3), PosKind.startOfRange, LineAndColumn(1, 4));
	verifyConvert(lcg, Pos(4), PosKind.startOfRange, LineAndColumn(1, 5));
	verifyConvert(lcg, Pos(5), PosKind.startOfRange, LineAndColumn(1, 6));
	verifyConvert(lcg, Pos(6), PosKind.startOfRange, LineAndColumn(2, 0));
	verifyConvert(lcg, Pos(7), PosKind.startOfRange, LineAndColumn(2, 1));
	verifyConvert(lcg, Pos(8), PosKind.startOfRange, LineAndColumn(3, 0));

	assert(lcg[LineAndColumn(0, 99)] == Pos(1));
	assert(lcg[LineAndColumn(99, 99)] == Pos(8));
}

void testCRLF(ref Test test) {
	LineAndColumnGetter lcg = lineAndColumnGetterForText(test.alloc, cString!"a\r\n\tbb\r\nc\r\n");
	verifyConvert(lcg, Pos(0), PosKind.startOfRange, LineAndColumn(0, 0)); // a
	verifyConvert(lcg, Pos(1), PosKind.startOfRange, LineAndColumn(0, 1)); // \r
	verifyConvert(lcg, Pos(2), PosKind.startOfRange, LineAndColumn(0, 1), some(Pos(1))); // \n
	verifyConvert(lcg, Pos(2), PosKind.endOfRange, LineAndColumn(0, 1), some(Pos(1)));
	verifyConvert(lcg, Pos(3), PosKind.startOfRange, LineAndColumn(1, 0)); // \t
	verifyConvert(lcg, Pos(3), PosKind.endOfRange, LineAndColumn(0, 1), some(Pos(1)));
	verifyConvert(lcg, Pos(4), PosKind.startOfRange, LineAndColumn(1, 4)); // b
	verifyConvert(lcg, Pos(5), PosKind.startOfRange, LineAndColumn(1, 5)); // b
	verifyConvert(lcg, Pos(6), PosKind.startOfRange, LineAndColumn(1, 6)); // \r
	verifyConvert(lcg, Pos(7), PosKind.startOfRange, LineAndColumn(1, 6), some(Pos(6))); // \n
	verifyConvert(lcg, Pos(8), PosKind.startOfRange, LineAndColumn(2, 0)); // c
	verifyConvert(lcg, Pos(9), PosKind.startOfRange, LineAndColumn(2, 1)); // \r
	verifyConvert(lcg, Pos(10), PosKind.startOfRange, LineAndColumn(2, 1), some(Pos(9))); // \n
	verifyConvert(lcg, Pos(11), PosKind.startOfRange, LineAndColumn(3, 0)); // end
}

void verifyConvert(
	in LineAndColumnGetter lcg,
	Pos pos,
	PosKind kind,
	in LineAndColumn lineAndColumn,
	in Opt!Pos convertBackPos = none!Pos,
) {
	assert(lineAndColumnAtPos(lcg, pos, kind) == lineAndColumn);
	assert(lcg[lineAndColumn] == (has(convertBackPos) ? force(convertBackPos) : pos));
}
