module test.testPath;

@safe @nogc pure nothrow:

import test.testUtil : Test;
import util.collection.str : emptyStr, strEqLiteral;
import util.comparison : Comparison;
import util.path : childPath, comparePath, AllPaths, Path, pathToStr, rootPath;
import util.sym : shortSymAlphaLiteral;
import util.util : verify;

void testPath(Debug, Alloc)(ref Test!(Debug, Alloc) test) {
	AllPaths!Alloc allPaths = AllPaths!Alloc(test.alloc);
	immutable Path a = rootPath(allPaths, shortSymAlphaLiteral("a"));
	immutable Path b = rootPath(allPaths, shortSymAlphaLiteral("b"));
	verify(comparePath(a, a) == Comparison.equal);
	verify(comparePath(a, b) == Comparison.less);

	verify(strEqLiteral(pathToStr(test.alloc, allPaths, emptyStr, a, emptyStr), "/a"));
	verify(strEqLiteral(pathToStr(test.alloc, allPaths, emptyStr, b, emptyStr), "/b"));

	immutable Path aX = childPath(allPaths, a, shortSymAlphaLiteral("x"));
	verify(childPath(allPaths, a, shortSymAlphaLiteral("x")) == aX);
	immutable Path aY = childPath(allPaths, a, shortSymAlphaLiteral("y"));
	verify(aX != aY);
	verify(strEqLiteral(pathToStr(test.alloc, allPaths, emptyStr, aX, emptyStr), "/a/x"));
	verify(strEqLiteral(pathToStr(test.alloc, allPaths, emptyStr, aY, emptyStr), "/a/y"));
}
