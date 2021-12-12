module test.testPath;

@safe @nogc pure nothrow:

import test.testUtil : Test;
import util.collection.str : safeCStr, strEq;
import util.comparison : Comparison;
import util.path : childPath, comparePath, AllPaths, Path, pathToStr, rootPath;
import util.ptr : ptrTrustMe_mut;
import util.sym : shortSymAlphaLiteral;
import util.util : verify;

void testPath(ref Test test) {
	AllPaths allPaths = AllPaths(test.allocPtr, ptrTrustMe_mut(test.allSymbols));
	immutable Path a = rootPath(allPaths, shortSymAlphaLiteral("a"));
	immutable Path b = rootPath(allPaths, shortSymAlphaLiteral("b"));
	verify(comparePath(a, a) == Comparison.equal);
	verify(comparePath(a, b) == Comparison.less);

	verify(strEq(pathToStr(test.alloc, allPaths, safeCStr!"", a, ""), "/a"));
	verify(strEq(pathToStr(test.alloc, allPaths, safeCStr!"", b, ""), "/b"));

	immutable Path aX = childPath(allPaths, a, shortSymAlphaLiteral("x"));
	verify(childPath(allPaths, a, shortSymAlphaLiteral("x")) == aX);
	immutable Path aY = childPath(allPaths, a, shortSymAlphaLiteral("y"));
	verify(aX != aY);
	verify(strEq(pathToStr(test.alloc, allPaths, safeCStr!"", aX, ""), "/a/x"));
	verify(strEq(pathToStr(test.alloc, allPaths, safeCStr!"", aY, ""), "/a/y"));
}
