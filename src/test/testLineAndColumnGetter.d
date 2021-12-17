module test.testLineAndColumnGetter;

@safe @nogc pure nothrow:

import test.testUtil : Test;
import util.col.str : safeCStr;
import util.lineAndColumnGetter : LineAndColumn, lineAndColumnAtPos, LineAndColumnGetter, lineAndColumnGetterForText;
import util.sourceRange : Pos;
import util.util : verifyEq;

void testLineAndColumnGetter(ref Test test) {
	immutable LineAndColumnGetter lcg = lineAndColumnGetterForText(test.alloc, safeCStr!"a\n\tbb\nc\n");
	verifyEq(lineAndColumnAtPos(lcg, immutable Pos(0)), immutable LineAndColumn(0, 0));
	verifyEq(lineAndColumnAtPos(lcg, immutable Pos(1)), immutable LineAndColumn(0, 1));
	verifyEq(lineAndColumnAtPos(lcg, immutable Pos(2)), immutable LineAndColumn(1, 0));
	verifyEq(lineAndColumnAtPos(lcg, immutable Pos(3)), immutable LineAndColumn(1, 4));
	verifyEq(lineAndColumnAtPos(lcg, immutable Pos(4)), immutable LineAndColumn(1, 5));
	verifyEq(lineAndColumnAtPos(lcg, immutable Pos(5)), immutable LineAndColumn(1, 6));
	verifyEq(lineAndColumnAtPos(lcg, immutable Pos(6)), immutable LineAndColumn(2, 0));
	verifyEq(lineAndColumnAtPos(lcg, immutable Pos(7)), immutable LineAndColumn(2, 1));
	verifyEq(lineAndColumnAtPos(lcg, immutable Pos(8)), immutable LineAndColumn(3, 0));
}
