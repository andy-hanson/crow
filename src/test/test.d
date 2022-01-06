module test.test;

@safe @nogc nothrow: // not pure

import lib.compiler : ExitCode;
import test.testApplyFn : testApplyFn;
import test.testFakeExtern : testFakeExtern;
import test.testHover : testHover;
import test.testInterpreter : testInterpreter;
import test.testLineAndColumnGetter : testLineAndColumnGetter;
import test.testPath : testPath;
import test.testServer : testServer;
import test.testSortUtil : testSortUtil;
import test.testStack : testStack;
import test.testSym : testSym;
import test.testTokens : testTokens;
import test.testUtil : Test;
import test.testWriter : testWriter;
import util.alloc.alloc : Alloc;
import util.col.str : strEq;
import util.opt : force, has, Opt;
import util.ptr : ptrTrustMe_mut;

immutable(ExitCode) test(ref Alloc alloc, immutable Opt!string name) {
	Test test = Test(ptrTrustMe_mut(alloc));
	foreach (ref immutable NameAndTest it; allTests)
		if (!has(name) || strEq(force(name), it.name))
			it.test(test);
	return ExitCode.ok;
}

private:

immutable(NameAndTest[]) allTests = [
	immutable NameAndTest("apply-fn", &testApplyFn),
	immutable NameAndTest("fake-extern", &testFakeExtern),
	immutable NameAndTest("hover", &testHover),
	immutable NameAndTest("interpreter", &testInterpreter),
	immutable NameAndTest("line-and-column-getter", &testLineAndColumnGetter),
	immutable NameAndTest("path", &testPath),
	immutable NameAndTest("server", &testServer),
	immutable NameAndTest("sort-util", &testSortUtil),
	immutable NameAndTest("stack", &testStack),
	immutable NameAndTest("sym", &testSym),
	immutable NameAndTest("tokens", &testTokens),
	immutable NameAndTest("writer", &testWriter),
];

struct NameAndTest {
	immutable string name;
	immutable void function(ref Test) @safe @nogc nothrow test; // not pure
}
