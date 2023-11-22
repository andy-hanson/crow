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
import test.testServer : testServer;
import test.testSortUtil : testSortUtil;
import test.testStack : testStack;
import test.testSym : testSym;
import test.testTokens : testTokens;
import test.testUri : testUri;
import test.testUtil : Test;
import test.testWriter : testWriter;
import util.alloc.alloc : Alloc;
import util.exitCode : ExitCode;
import util.opt : force, has, Opt;
import util.ptr : ptrTrustMe;
import util.sym : Sym, sym;

ExitCode test(ref Alloc alloc, Opt!Sym name) {
	Test test = Test(ptrTrustMe(alloc));
	foreach (ref NameAndTest it; allTests)
		if (!has(name) || force(name) == it.name)
			it.test(test);
	return ExitCode.ok;
}

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
	NameAndTest(sym!"server", &testServer),
	NameAndTest(sym!"sort-util", &testSortUtil),
	NameAndTest(sym!"stack", &testStack),
	NameAndTest(sym!"sym", &testSym),
	NameAndTest(sym!"tokens", &testTokens),
	NameAndTest(sym!"path", &testUri),
	NameAndTest(sym!"writer", &testWriter),
];

immutable struct NameAndTest {
	Sym name;
	void function(ref Test) @safe @nogc nothrow test; // not pure
}
