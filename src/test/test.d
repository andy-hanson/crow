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
import util.sym : shortSym, SpecialSym, Sym, symForSpecial;

immutable(ExitCode) test(ref Alloc alloc, scope immutable Opt!Sym name) {
	Test test = Test(castNonScope_mut(&alloc));
	foreach (ref immutable NameAndTest it; allTests)
		if (!has(name) || force(name) == it.name)
			it.test(test);
	return ExitCode.ok;
}

private:

immutable(NameAndTest[]) allTests = [
	immutable NameAndTest(shortSym("apply-fn"), &testApplyFn),
	immutable NameAndTest(shortSym("dict"), &testDict),
	immutable NameAndTest(shortSym("fake-extern"), &testFakeExtern),
	immutable NameAndTest(shortSym("hover"), &testHover),
	immutable NameAndTest(shortSym("interpreter"), &testInterpreter),
	immutable NameAndTest(shortSym("json"), &testJson),
	immutable NameAndTest(symForSpecial(SpecialSym.line_and_column_getter), &testLineAndColumnGetter),
	immutable NameAndTest(shortSym("memory"), &testMemory),
	immutable NameAndTest(shortSym("path"), &testPath),
	immutable NameAndTest(shortSym("server"), &testServer),
	immutable NameAndTest(shortSym("sort-util"), &testSortUtil),
	immutable NameAndTest(shortSym("stack"), &testStack),
	immutable NameAndTest(shortSym("sym"), &testSym),
	immutable NameAndTest(shortSym("tokens"), &testTokens),
	immutable NameAndTest(shortSym("writer"), &testWriter),
];

struct NameAndTest {
	immutable Sym name;
	immutable void function(ref Test) @safe @nogc nothrow test; // not pure
}
