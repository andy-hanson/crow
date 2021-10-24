module test.test;

@safe @nogc nothrow: // not pure

import lib.compiler : ExitCode;
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
import util.alloc.alloc : Alloc;
import util.collection.str : strEq;
import util.opt : force, has, Opt;
import util.path : AllPaths;
import util.ptr : ptrTrustMe_mut;
import util.sym : AllSymbols;

immutable(ExitCode) test(Debug)(ref Debug dbg, ref Alloc alloc, immutable Opt!string name) {
	Test!Debug test = Test!Debug(
		ptrTrustMe_mut(dbg),
		ptrTrustMe_mut(alloc),
		AllSymbols(ptrTrustMe_mut(alloc)),
		AllPaths(ptrTrustMe_mut(alloc)));
	foreach (ref immutable NameAndTest!Debug it; allTests!Debug)
		if (!has(name) || strEq(force(name), it.name))
			it.test(test);
	return ExitCode.ok;
}

private:

immutable(NameAndTest!Debug[]) allTests(Debug) = [
	immutable NameAndTest!Debug("arr-util", &testArrUtil!Debug),
	immutable NameAndTest!Debug("apply-fn", &testApplyFn!Debug),
	immutable NameAndTest!Debug("byte-reader-writer", &testByteReaderWriter!Debug),
	immutable NameAndTest!Debug("fake-extern", &testFakeExtern!Debug),
	immutable NameAndTest!Debug("hover", &testHover!Debug),
	immutable NameAndTest!Debug("interpreter", &testInterpreter!Debug),
	immutable NameAndTest!Debug("line-and-column-getter", &testLineAndColumnGetter!Debug),
	immutable NameAndTest!Debug("path", &testPath!Debug),
	immutable NameAndTest!Debug("server", &testServer!Debug),
	immutable NameAndTest!Debug("sym", &testSym!Debug),
	immutable NameAndTest!Debug("tokens", &testTokens!Debug),
	immutable NameAndTest!Debug("writer", &testWriter!Debug),
];

struct NameAndTest(Debug) {
	immutable string name;
	immutable void function(ref Test!Debug) @safe @nogc nothrow test; // not pure
}
