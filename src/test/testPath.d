module test.testPath;

@safe @nogc pure nothrow:

import test.testUtil : Test;
import util.collection.str : strEq;
import util.comparison : Comparison;
import util.path : childPath, comparePath, AllPaths, Path, pathToStr, rootPath;
import util.util : verify;

void testPath(Debug)(ref Test!Debug test) {
	AllPaths allPaths = AllPaths(test.alloc);
	immutable Path a = rootPath(allPaths, "a");
	immutable Path b = rootPath(allPaths, "b");
	verify(comparePath(a, a) == Comparison.equal);
	verify(comparePath(a, b) == Comparison.less);

	verify(strEq(pathToStr(test.alloc.deref(), allPaths, "", a, ""), "/a"));
	verify(strEq(pathToStr(test.alloc.deref(), allPaths, "", b, ""), "/b"));

	immutable Path aX = childPath(allPaths, a, "x");
	verify(childPath(allPaths, a, "x") == aX);
	immutable Path aY = childPath(allPaths, a, "y");
	verify(aX != aY);
	verify(strEq(pathToStr(test.alloc.deref(), allPaths, "", aX, ""), "/a/x"));
	verify(strEq(pathToStr(test.alloc.deref(), allPaths, "", aY, ""), "/a/y"));
}
