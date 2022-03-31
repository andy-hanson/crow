module test.testPath;

@safe @nogc pure nothrow:

import test.testUtil : Test;
import util.col.str : safeCStr, safeCStrEq;
import util.comparison : Comparison;
import util.path :
	childPath,
	commonAncestor,
	comparePath,
	AllPaths,
	Path,
	PathAndExtension,
	parseAbsoluteOrRelPathAndExtension,
	pathEqual,
	pathToSafeCStr,
	rootPath,
	TEST_countPathParts;
import util.ptr : ptrTrustMe_mut;
import util.sym : shortSym, SpecialSym, symEq, symForSpecial;
import util.util : verify;

void testPath(ref Test test) {
	AllPaths allPaths = AllPaths(test.allocPtr, ptrTrustMe_mut(test.allSymbols));
	immutable Path a = rootPath(allPaths, shortSym("a"));
	immutable Path b = rootPath(allPaths, shortSym("b"));
	verify(comparePath(a, a) == Comparison.equal);
	verify(comparePath(a, b) == Comparison.less);

	verify(safeCStrEq(pathToSafeCStr(test.alloc, allPaths, a), safeCStr!"a"));

	immutable Path aX = childPath(allPaths, a, shortSym("x"));
	verify(childPath(allPaths, a, shortSym("x")) == aX);
	immutable Path aY = childPath(allPaths, a, shortSym("y"));
	verify(aX != aY);
	verify(safeCStrEq(pathToSafeCStr(test.alloc, allPaths, aX), safeCStr!"a/x"));
	verify(safeCStrEq(pathToSafeCStr(test.alloc, allPaths, aY), safeCStr!"a/y"));

	immutable PathAndExtension zW = parseAbsoluteOrRelPathAndExtension(allPaths, aX, safeCStr!"/z/w.crow");
	verify(safeCStrEq(pathToSafeCStr(test.alloc, allPaths, zW.path), safeCStr!"/z/w"));
	verify(symEq(zW.extension, symForSpecial(SpecialSym.dotCrow)));
	immutable Path aXZW = parseAbsoluteOrRelPathAndExtension(allPaths, aX, safeCStr!"./z/w").path;
	verify(safeCStrEq(pathToSafeCStr(test.alloc, allPaths, aXZW), safeCStr!"a/x/z/w"));
	verify(pathEqual(aXZW, parseAbsoluteOrRelPathAndExtension(allPaths, aX, safeCStr!"z/w").path));
	verify(pathEqual(aY, parseAbsoluteOrRelPathAndExtension(allPaths, aX, safeCStr!"../y").path));

	verify(TEST_countPathParts(allPaths, zW.path) == 3); // initial empty part before the leading "/"

	verify(pathEqual(commonAncestor(allPaths, [aX, aY]), a));
	verify(pathEqual(commonAncestor(allPaths, [aX, aXZW]), aX));
	verify(pathEqual(commonAncestor(allPaths, [aX, aXZW, aY]), a));
}
