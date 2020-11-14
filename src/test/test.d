module test.test;

@safe @nogc nothrow: // not pure

import test.testApplyFn : testApplyFn;
import test.testByteReaderWriter : testByteReaderWriter;
import test.testFakeExtern : testFakeExtern;
import test.testInterpreter : testInterpreter;
import test.testLineAndColumnGetter : testLineAndColumnGetter;
import test.testSym : testSym;
import util.collection.str : Str, strEqLiteral;
import util.opt : force, has, Opt;

int test(Alloc)(ref Alloc alloc, immutable Opt!Str name) {
	foreach (ref immutable NameAndTest!Alloc it; allTests!Alloc)
		if (!has(name) || strEqLiteral(force(name), it.name)) {
			debug {
				import core.stdc.stdio : printf;
				printf("Running test %.*s\n", cast(int) it.name.length, it.name.ptr);
			}
			it.test(alloc);
		}
	return 0;
}

private:

immutable (NameAndTest!Alloc)[] allTests(Alloc) = [
	immutable NameAndTest!Alloc("apply-fn", &testApplyFn!Alloc),
	immutable NameAndTest!Alloc("byte-reader-writer", &testByteReaderWriter!Alloc),
	immutable NameAndTest!Alloc("fake-extern", &testFakeExtern!Alloc),
	immutable NameAndTest!Alloc("interpreter", &testInterpreter!Alloc),
	immutable NameAndTest!Alloc("line-and-column-getter", &testLineAndColumnGetter!Alloc),
	immutable NameAndTest!Alloc("sym", &testSym!Alloc),
];


struct NameAndTest(Alloc) {
	immutable string name;
	immutable void function(ref Alloc) @safe @nogc nothrow test; // not pure
}
