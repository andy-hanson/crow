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
	pathToSafeCStr,
	rootPath,
	TEST_countPathParts;
import util.ptr : ptrTrustMe_mut;
import util.sym : sym;
import util.util : verify;

void testPath(ref Test test) {
	AllPaths allPaths = AllPaths(test.allocPtr, ptrTrustMe_mut(test.allSymbols));
	immutable Path a = rootPath(allPaths, sym!"a");
	immutable Path b = rootPath(allPaths, sym!"b");
	verify(comparePath(a, a) == Comparison.equal);
	verify(comparePath(a, b) == Comparison.less);

	verify(safeCStrEq(pathToSafeCStr(test.alloc, allPaths, a), safeCStr!"a"));

	immutable Path aX = childPath(allPaths, a, sym!"x");
	verify(childPath(allPaths, a, sym!"x") == aX);
	immutable Path aY = childPath(allPaths, a, sym!"y");
	verify(aX != aY);
	verify(safeCStrEq(pathToSafeCStr(test.alloc, allPaths, aX), safeCStr!"a/x"));
	verify(safeCStrEq(pathToSafeCStr(test.alloc, allPaths, aY), safeCStr!"a/y"));

	immutable PathAndExtension zW = parseAbsoluteOrRelPathAndExtension(allPaths, aX, safeCStr!"/z/w.crow");
	verify(safeCStrEq(pathToSafeCStr(test.alloc, allPaths, zW.path), safeCStr!"/z/w"));
	verify(zW.extension == sym!".crow");
	immutable Path aXZW = parseAbsoluteOrRelPathAndExtension(allPaths, aX, safeCStr!"./z/w").path;
	verify(safeCStrEq(pathToSafeCStr(test.alloc, allPaths, aXZW), safeCStr!"a/x/z/w"));
	verify(aXZW == parseAbsoluteOrRelPathAndExtension(allPaths, aX, safeCStr!"z/w").path);
	verify(aY == parseAbsoluteOrRelPathAndExtension(allPaths, aX, safeCStr!"../y").path);

	verify(TEST_countPathParts(allPaths, zW.path) == 3); // initial empty part before the leading "/"

	verify(commonAncestor(allPaths, [aX, aY]) == a);
	verify(commonAncestor(allPaths, [aX, aXZW]) == aX);
	verify(commonAncestor(allPaths, [aX, aXZW, aY]) == a);
}
