module test.test;

@safe @nogc nothrow: // not pure

import test.testApplyFn : testApplyFn;
import test.testByteReaderWriter : testByteReaderWriter;
import test.testExternOps : testExternOps;
import test.testInterpreter : testInterpreter;
import test.testLineAndColumnGetter : testLineAndColumnGetter;
import util.collection.str : Str, strEqLiteral;
import util.opt : force, has, Opt;

int test(immutable Opt!Str name) {
	foreach (ref immutable NameAndTest it; allTests)
		if (!has(name) || strEqLiteral(force(name), it.name)) {
			debug {
				import core.stdc.stdio : printf;
				printf("Running test %.*s\n", cast(int) it.name.length, it.name.ptr);
			}
			it.test();
		}
	return 0;
}

private:

immutable NameAndTest[] allTests = [
	immutable NameAndTest("apply-fn", &testApplyFn),
	immutable NameAndTest("byte-reader-writer", &testByteReaderWriter),
	immutable NameAndTest("extern-ops", &testExternOps),
	immutable NameAndTest("interpreter", &testInterpreter),
	immutable NameAndTest("line-and-column-getter", &testLineAndColumnGetter),
];


struct NameAndTest {
	immutable string name;
	immutable void function() @safe @nogc nothrow test; // not pure
}
