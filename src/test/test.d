module test.test;

@safe @nogc nothrow: // not pure

import lib.compiler : ExitCode;
import test.testApplyFn : testApplyFn;
import test.testDict : testDict;
import test.testFakeExtern : testFakeExtern;
import test.testHover : testHover;
import test.testInterpreter : testInterpreter;
import test.testJson : testJson;
import test.testLineAndColumnGetter : testLineAndColumnGetter;
import test.testMemory : testMemory;
import test.testPath : testPath;
import test.testServer : testServer;
import test.testSortUtil : testSortUtil;
import test.testStack : testStack;
import test.testSym : testSym;
import test.testTokens : testTokens;
import test.testUtil : Test;
import test.testWriter : testWriter;
import util.alloc.alloc : Alloc;
import util.opt : force, has, Opt;
import util.ptr : castNonScope_mut;
import util.sym : Sym, sym;

immutable(ExitCode) test(ref Alloc alloc, scope immutable Opt!Sym name) {
	Test test = Test(castNonScope_mut(&alloc));
	foreach (ref immutable NameAndTest it; allTests)
		if (!has(name) || force(name) == it.name)
			it.test(test);
	return ExitCode.ok;
}

private:

immutable(NameAndTest[]) allTests = [
	immutable NameAndTest(sym!"apply-fn", &testApplyFn),
	immutable NameAndTest(sym!"dict", &testDict),
	immutable NameAndTest(sym!"fake-extern", &testFakeExtern),
	immutable NameAndTest(sym!"hover", &testHover),
	immutable NameAndTest(sym!"interpreter", &testInterpreter),
	immutable NameAndTest(sym!"json", &testJson),
	immutable NameAndTest(sym!"line-and-column-getter", &testLineAndColumnGetter),
	immutable NameAndTest(sym!"memory", &testMemory),
	immutable NameAndTest(sym!"path", &testPath),
	immutable NameAndTest(sym!"server", &testServer),
	immutable NameAndTest(sym!"sort-util", &testSortUtil),
	immutable NameAndTest(sym!"stack", &testStack),
	immutable NameAndTest(sym!"sym", &testSym),
	immutable NameAndTest(sym!"tokens", &testTokens),
	immutable NameAndTest(sym!"writer", &testWriter),
];

struct NameAndTest {
	immutable Sym name;
	immutable void function(ref Test) @safe @nogc nothrow test; // not pure
}
