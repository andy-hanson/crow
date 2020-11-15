module test.testLineAndColumnGetter;

@safe @nogc pure nothrow:

import test.testUtil : Test;
import util.collection.str : Str, strLiteral;
import util.lineAndColumnGetter : LineAndColumn, lineAndColumnAtPos, LineAndColumnGetter, lineAndColumnGetterForText;
import util.sourceRange : Pos;
import util.util : verifyEq;

void testLineAndColumnGetter(Alloc)(ref Test!Alloc test) {
	immutable Str text = strLiteral("a\n\tbb\nc\n");
	immutable LineAndColumnGetter lcg = lineAndColumnGetterForText(test.alloc, text);
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
