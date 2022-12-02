module test.testLineAndColumnGetter;

@safe @nogc pure nothrow:

import test.testUtil : Test;
import util.col.str : safeCStr;
import util.lineAndColumnGetter : LineAndColumn, lineAndColumnAtPos, LineAndColumnGetter, lineAndColumnGetterForText;
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
	verifyEq(lineAndColumnAtPos(lcg, Pos(0)), LineAndColumn(0, 0));
	verifyEq(lineAndColumnAtPos(lcg, Pos(1)), LineAndColumn(0, 1));
	verifyEq(lineAndColumnAtPos(lcg, Pos(2)), LineAndColumn(1, 0));
	verifyEq(lineAndColumnAtPos(lcg, Pos(3)), LineAndColumn(1, 4));
	verifyEq(lineAndColumnAtPos(lcg, Pos(4)), LineAndColumn(1, 5));
	verifyEq(lineAndColumnAtPos(lcg, Pos(5)), LineAndColumn(1, 6));
	verifyEq(lineAndColumnAtPos(lcg, Pos(6)), LineAndColumn(2, 0));
	verifyEq(lineAndColumnAtPos(lcg, Pos(7)), LineAndColumn(2, 1));
	verifyEq(lineAndColumnAtPos(lcg, Pos(8)), LineAndColumn(3, 0));
}

void testCRLF(ref Test test) {
	LineAndColumnGetter lcg = lineAndColumnGetterForText(test.alloc, safeCStr!"a\r\n\tbb\r\nc\r\n");
	verifyEq(lineAndColumnAtPos(lcg, Pos(0)), LineAndColumn(0, 0)); // a
	verifyEq(lineAndColumnAtPos(lcg, Pos(1)), LineAndColumn(0, 1)); // \r
	verifyEq(lineAndColumnAtPos(lcg, Pos(2)), LineAndColumn(0, 2)); // \n
	verifyEq(lineAndColumnAtPos(lcg, Pos(3)), LineAndColumn(1, 0)); // \t
	verifyEq(lineAndColumnAtPos(lcg, Pos(4)), LineAndColumn(1, 4)); // b
	verifyEq(lineAndColumnAtPos(lcg, Pos(5)), LineAndColumn(1, 5)); // b
	verifyEq(lineAndColumnAtPos(lcg, Pos(6)), LineAndColumn(1, 6)); // \r
	verifyEq(lineAndColumnAtPos(lcg, Pos(7)), LineAndColumn(1, 7)); // \n
	verifyEq(lineAndColumnAtPos(lcg, Pos(8)), LineAndColumn(2, 0)); // c
	verifyEq(lineAndColumnAtPos(lcg, Pos(9)), LineAndColumn(2, 1)); // \r
	verifyEq(lineAndColumnAtPos(lcg, Pos(10)), LineAndColumn(2, 2)); // \n
	verifyEq(lineAndColumnAtPos(lcg, Pos(11)), LineAndColumn(3, 0)); // end
}
