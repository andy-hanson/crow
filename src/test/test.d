module test.test;

@safe @nogc nothrow: // not pure

import test.testApplyFn : testApplyFn;
import test.testArrUtil : testArrUtil;
import test.testByteReaderWriter : testByteReaderWriter;
import test.testFakeExtern : testFakeExtern;
import test.testHover : testHover;
import test.testInterpreter : testInterpreter;
import test.testLineAndColumnGetter : testLineAndColumnGetter;
import test.testPath : testPath;
import test.testServer : testServer;
import test.testSym : testSym;
import test.testTokens : testTokens;
import test.testUtil : Test;
import test.testWriter : testWriter;
import util.collection.str : strEqLiteral;
import util.opt : force, has, Opt;
import util.path : AllPaths;
import util.ptr : ptrTrustMe_mut;
import util.sym : AllSymbols;

int test(Debug, Alloc)(ref Debug dbg, ref Alloc alloc, immutable Opt!string name) {
	Test!(Debug, Alloc) test = Test!(Debug, Alloc)(
		ptrTrustMe_mut(dbg),
		ptrTrustMe_mut(alloc),
		AllSymbols!Alloc(ptrTrustMe_mut(alloc)),
		AllPaths!Alloc(ptrTrustMe_mut(alloc)));
	foreach (ref immutable NameAndTest!(Debug, Alloc) it; allTests!(Debug, Alloc))
		if (!has(name) || strEqLiteral(force(name), it.name))
			it.test(test);
	return 0;
}

private:

immutable(NameAndTest!(Debug, Alloc)[]) allTests(Debug, Alloc) = [
	immutable NameAndTest!(Debug, Alloc)("arr-util", &testArrUtil!(Debug, Alloc)),
	immutable NameAndTest!(Debug, Alloc)("apply-fn", &testApplyFn!(Debug, Alloc)),
	immutable NameAndTest!(Debug, Alloc)("byte-reader-writer", &testByteReaderWriter!(Debug, Alloc)),
	immutable NameAndTest!(Debug, Alloc)("fake-extern", &testFakeExtern!(Debug, Alloc)),
	immutable NameAndTest!(Debug, Alloc)("hover", &testHover!(Debug, Alloc)),
	immutable NameAndTest!(Debug, Alloc)("interpreter", &testInterpreter!(Debug, Alloc)),
	immutable NameAndTest!(Debug, Alloc)("line-and-column-getter", &testLineAndColumnGetter!(Debug, Alloc)),
	immutable NameAndTest!(Debug, Alloc)("path", &testPath!(Debug, Alloc)),
	immutable NameAndTest!(Debug, Alloc)("server", &testServer!(Debug, Alloc)),
	immutable NameAndTest!(Debug, Alloc)("sym", &testSym!(Debug, Alloc)),
	immutable NameAndTest!(Debug, Alloc)("tokens", &testTokens!(Debug, Alloc)),
	immutable NameAndTest!(Debug, Alloc)("writer", &testWriter!(Debug, Alloc)),
];


struct NameAndTest(Debug, Alloc) {
	immutable string name;
	immutable void function(ref Test!(Debug, Alloc)) @safe @nogc nothrow test; // not pure
}
