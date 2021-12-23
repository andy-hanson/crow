module test.testPath;

@safe @nogc pure nothrow:

import test.testUtil : Test;
import util.col.str : safeCStr, safeCStrEq;
import util.comparison : Comparison;
import util.path : childPath, comparePath, AllPaths, Path, pathToSafeCStr, rootPath;
import util.ptr : ptrTrustMe_mut;
import util.sym : shortSym;
import util.util : verify;

void testPath(ref Test test) {
	AllPaths allPaths = AllPaths(test.allocPtr, ptrTrustMe_mut(test.allSymbols));
	immutable Path a = rootPath(allPaths, shortSym("a"));
	immutable Path b = rootPath(allPaths, shortSym("b"));
	verify(comparePath(a, a) == Comparison.equal);
	verify(comparePath(a, b) == Comparison.less);

	verify(safeCStrEq(pathToSafeCStr(test.alloc, allPaths, safeCStr!"", a, safeCStr!""), safeCStr!"a"));
	verify(safeCStrEq(pathToSafeCStr(test.alloc, allPaths, safeCStr!"root", b, safeCStr!""), safeCStr!"root/b"));

	immutable Path aX = childPath(allPaths, a, shortSym("x"));
	verify(childPath(allPaths, a, shortSym("x")) == aX);
	immutable Path aY = childPath(allPaths, a, shortSym("y"));
	verify(aX != aY);
	verify(safeCStrEq(pathToSafeCStr(test.alloc, allPaths, safeCStr!"", aX, safeCStr!""), safeCStr!"a/x"));
	verify(safeCStrEq(pathToSafeCStr(test.alloc, allPaths, safeCStr!"root", aY, safeCStr!""), safeCStr!"root/a/y"));
}
