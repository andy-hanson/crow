module test.test;

@safe @nogc nothrow: // not pure

import lib.compiler : ExitCode;
import test.testApplyFn : testApplyFn;
import test.testArrUtil : testArrUtil;
import test.testFakeExtern : testFakeExtern;
import test.testHover : testHover;
import test.testInterpreter : testInterpreter;
import test.testLineAndColumnGetter : testLineAndColumnGetter;
import test.testPath : testPath;
import test.testServer : testServer;
import test.testStack : testStack;
import test.testSym : testSym;
import test.testTokens : testTokens;
import test.testUtil : Test;
import test.testWriter : testWriter;
import util.alloc.alloc : Alloc;
import util.collection.str : strEq;
import util.dbg : Debug;
import util.opt : force, has, Opt;
import util.ptr : ptrTrustMe_mut;

immutable(ExitCode) test(scope ref Debug dbg, ref Alloc alloc, immutable Opt!string name) {
	Test test = Test(
		ptrTrustMe_mut(dbg),
		ptrTrustMe_mut(alloc));
	foreach (ref immutable NameAndTest it; allTests)
		if (!has(name) || strEq(force(name), it.name))
			it.test(test);
	return ExitCode.ok;
}

private:

immutable(NameAndTest[]) allTests = [
	immutable NameAndTest("arr-util", &testArrUtil),
	immutable NameAndTest("apply-fn", &testApplyFn),
	immutable NameAndTest("fake-extern", &testFakeExtern),
	immutable NameAndTest("hover", &testHover),
	immutable NameAndTest("interpreter", &testInterpreter),
	immutable NameAndTest("line-and-column-getter", &testLineAndColumnGetter),
	immutable NameAndTest("path", &testPath),
	immutable NameAndTest("server", &testServer),
	immutable NameAndTest("stack", &testStack),
	immutable NameAndTest("sym", &testSym),
	immutable NameAndTest("tokens", &testTokens),
	immutable NameAndTest("writer", &testWriter),
];

struct NameAndTest {
	immutable string name;
	immutable void function(ref Test) @safe @nogc nothrow test; // not pure
}
