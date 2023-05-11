module test.testLineAndColumnGetter;

@safe @nogc pure nothrow:

import test.testUtil : Test;
import util.col.str : safeCStr;
import util.lineAndColumnGetter :
	LineAndColumn, lineAndColumnAtPos, LineAndColumnGetter, lineAndColumnGetterForText, PosKind;
import util.sourceRange : Pos;
import util.util : verifyEq;

void testLineAndColumnGetter(ref Test test) {
	testLF(test);
	testCR(test);
	testCRLF(test);
}

private:

void testLF(ref Test test) {
	LineAndColumnGetter lcg = lineAndColumnGetterForText(test.alloc, safeCStr!"a\n\tbb\nc\n");
	testLFOrCR(lcg);
}

void testCR(ref Test test) {
	LineAndColumnGetter lcg = lineAndColumnGetterForText(test.alloc, safeCStr!"a\r\tbb\rc\r");
	testLFOrCR(lcg);
}

void testLFOrCR(ref LineAndColumnGetter lcg) {
	verifyEq(lineAndColumnAtPos(lcg, Pos(0), PosKind.startOfRange), LineAndColumn(0, 0));
	verifyEq(lineAndColumnAtPos(lcg, Pos(1), PosKind.startOfRange), LineAndColumn(0, 1));
	verifyEq(lineAndColumnAtPos(lcg, Pos(2), PosKind.startOfRange), LineAndColumn(1, 0));
	verifyEq(lineAndColumnAtPos(lcg, Pos(2), PosKind.endOfRange), LineAndColumn(0, 1));
	verifyEq(lineAndColumnAtPos(lcg, Pos(3), PosKind.startOfRange), LineAndColumn(1, 4));
	verifyEq(lineAndColumnAtPos(lcg, Pos(4), PosKind.startOfRange), LineAndColumn(1, 5));
	verifyEq(lineAndColumnAtPos(lcg, Pos(5), PosKind.startOfRange), LineAndColumn(1, 6));
	verifyEq(lineAndColumnAtPos(lcg, Pos(6), PosKind.startOfRange), LineAndColumn(2, 0));
	verifyEq(lineAndColumnAtPos(lcg, Pos(7), PosKind.startOfRange), LineAndColumn(2, 1));
	verifyEq(lineAndColumnAtPos(lcg, Pos(8), PosKind.startOfRange), LineAndColumn(3, 0));
}

void testCRLF(ref Test test) {
	LineAndColumnGetter lcg = lineAndColumnGetterForText(test.alloc, safeCStr!"a\r\n\tbb\r\nc\r\n");
	verifyEq(lineAndColumnAtPos(lcg, Pos(0), PosKind.startOfRange), LineAndColumn(0, 0)); // a
	verifyEq(lineAndColumnAtPos(lcg, Pos(1), PosKind.startOfRange), LineAndColumn(0, 1)); // \r
	verifyEq(lineAndColumnAtPos(lcg, Pos(2), PosKind.startOfRange), LineAndColumn(0, 1)); // \n
	verifyEq(lineAndColumnAtPos(lcg, Pos(2), PosKind.endOfRange), LineAndColumn(0, 1));
	verifyEq(lineAndColumnAtPos(lcg, Pos(3), PosKind.startOfRange), LineAndColumn(1, 0)); // \t
	verifyEq(lineAndColumnAtPos(lcg, Pos(3), PosKind.endOfRange), LineAndColumn(0, 1));
	verifyEq(lineAndColumnAtPos(lcg, Pos(4), PosKind.startOfRange), LineAndColumn(1, 4)); // b
	verifyEq(lineAndColumnAtPos(lcg, Pos(5), PosKind.startOfRange), LineAndColumn(1, 5)); // b
	verifyEq(lineAndColumnAtPos(lcg, Pos(6), PosKind.startOfRange), LineAndColumn(1, 6)); // \r
	verifyEq(lineAndColumnAtPos(lcg, Pos(7), PosKind.startOfRange), LineAndColumn(1, 6)); // \n
	verifyEq(lineAndColumnAtPos(lcg, Pos(8), PosKind.startOfRange), LineAndColumn(2, 0)); // c
	verifyEq(lineAndColumnAtPos(lcg, Pos(9), PosKind.startOfRange), LineAndColumn(2, 1)); // \r
	verifyEq(lineAndColumnAtPos(lcg, Pos(10), PosKind.startOfRange), LineAndColumn(2, 1)); // \n
	verifyEq(lineAndColumnAtPos(lcg, Pos(11), PosKind.startOfRange), LineAndColumn(3, 0)); // end
}
