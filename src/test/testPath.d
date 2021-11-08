module test.testPath;

@safe @nogc pure nothrow:

import test.testUtil : Test;
import util.collection.str : SafeCStr, strEq;
import util.comparison : Comparison;
import util.path : childPath, comparePath, AllPaths, Path, pathToStr, rootPath;
import util.util : verify;

void testPath(ref Test test) {
	AllPaths allPaths = AllPaths(test.allocPtr);
	immutable Path a = rootPath(allPaths, "a");
	immutable Path b = rootPath(allPaths, "b");
	verify(comparePath(a, a) == Comparison.equal);
	verify(comparePath(a, b) == Comparison.less);

	verify(strEq(pathToStr(test.alloc, allPaths, immutable SafeCStr(""), a, ""), "/a"));
	verify(strEq(pathToStr(test.alloc, allPaths, immutable SafeCStr(""), b, ""), "/b"));

	immutable Path aX = childPath(allPaths, a, "x");
	verify(childPath(allPaths, a, "x") == aX);
	immutable Path aY = childPath(allPaths, a, "y");
	verify(aX != aY);
	verify(strEq(pathToStr(test.alloc, allPaths, immutable SafeCStr(""), aX, ""), "/a/x"));
	verify(strEq(pathToStr(test.alloc, allPaths, immutable SafeCStr(""), aY, ""), "/a/y"));
}
