module test.test;

@safe @nogc nothrow: // not pure

import test.testAlloc : testAlloc;
import test.testApplyFn : testApplyFn;
import test.testMap : testMap;
import test.testFakeExtern : testFakeExtern;
import test.testHover : testHover;
import test.testInterpreter : testInterpreter;
import test.testJson : testJson;
import test.testLineAndColumnGetter : testLineAndColumnGetter;
import test.testMemory : testMemory;
import test.testSortUtil : testSortUtil;
import test.testStack : testStack;
import test.testSym : testSym;
import test.testUri : testUri;
import test.testUtil : Test;
import test.testWriter : testWriter;
import util.alloc.alloc : MetaAlloc;
import util.exitCode : ExitCode;
import util.perf : Perf, withNullPerf;
import util.ptr : ptrTrustMe;
import util.sym : Sym, sym;

ExitCode test(MetaAlloc* alloc) =>
	withNullPerf!(ExitCode, (scope ref Perf perf) {
		Test test = Test(alloc, ptrTrustMe(perf));
		foreach (ref NameAndTest x; allTests)
			x.test(test);
		return ExitCode.ok;
	});

private:

NameAndTest[] allTests = [
	NameAndTest(sym!"alloc", &testAlloc),
	NameAndTest(sym!"apply-fn", &testApplyFn),
	NameAndTest(sym!"fake-extern", &testFakeExtern),
	NameAndTest(sym!"hover", &testHover),
	NameAndTest(sym!"interpreter", &testInterpreter),
	NameAndTest(sym!"json", &testJson),
	NameAndTest(sym!"line-and-column-getter", &testLineAndColumnGetter),
	NameAndTest(sym!"map", &testMap),
	NameAndTest(sym!"memory", &testMemory),
	NameAndTest(sym!"sort-util", &testSortUtil),
	NameAndTest(sym!"stack", &testStack),
	NameAndTest(sym!"sym", &testSym),
	NameAndTest(sym!"path", &testUri),
	NameAndTest(sym!"writer", &testWriter),
];

immutable struct NameAndTest {
	Sym name;
	void function(ref Test) @safe @nogc nothrow test; // not pure
}
