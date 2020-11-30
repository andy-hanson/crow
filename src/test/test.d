module test.test;

@safe @nogc nothrow: // not pure

import test.testApplyFn : testApplyFn;
import test.testByteReaderWriter : testByteReaderWriter;
import test.testDebug : testDebug;
import test.testFakeExtern : testFakeExtern;
import test.testInterpreter : testInterpreter;
import test.testLineAndColumnGetter : testLineAndColumnGetter;
import test.testServer : testServer;
import test.testSym : testSym;
import test.testTokens : testTokens;
import test.testUtil : Test;
import util.collection.str : Str, strEqLiteral;
import util.opt : force, has, Opt;
import util.ptr : ptrTrustMe_mut;

int test(Alloc)(ref Alloc alloc, immutable Opt!Str name) {
	Test!Alloc test = Test!Alloc(ptrTrustMe_mut(alloc));
	foreach (ref immutable NameAndTest!Alloc it; allTests!Alloc)
		if (!has(name) || strEqLiteral(force(name), it.name)) {
			//debug {
			//	import core.stdc.stdio : printf;
			//	printf("Running test %.*s\n", cast(uint) it.name.length, it.name.ptr);
			//}
			it.test(test);
		}
	return 0;
}

private:

immutable (NameAndTest!Alloc)[] allTests(Alloc) = [
	immutable NameAndTest!Alloc("apply-fn", &testApplyFn!Alloc),
	immutable NameAndTest!Alloc("byte-reader-writer", &testByteReaderWriter!Alloc),
	immutable NameAndTest!Alloc("debug", &testDebug!Alloc),
	immutable NameAndTest!Alloc("fake-extern", &testFakeExtern!Alloc),
	immutable NameAndTest!Alloc("interpreter", &testInterpreter!Alloc),
	immutable NameAndTest!Alloc("line-and-column-getter", &testLineAndColumnGetter!Alloc),
	immutable NameAndTest!Alloc("server", &testServer!Alloc),
	immutable NameAndTest!Alloc("sym", &testSym!Alloc),
	immutable NameAndTest!Alloc("tokens", &testTokens!Alloc),
];


struct NameAndTest(Alloc) {
	immutable string name;
	immutable void function(ref Test!Alloc) @safe @nogc nothrow test; // not pure
}
