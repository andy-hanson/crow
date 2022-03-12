module test.testFakeExtern;

@safe @nogc nothrow: // not pure

import interpret.extern_ : Extern;
import interpret.fakeExtern : FakeExternResult, withFakeExtern;
import lib.compiler : ExitCode;
import test.testUtil : Test;
import util.col.str : strEq;
import util.util : verify;

void testFakeExtern(ref Test test) {
	testMallocAndFree(test);
	testWrite(test);
}

private:

@trusted void testMallocAndFree(ref Test test) {
	withFakeExtern(test.alloc, test.allSymbols, (scope ref Extern extern_) @trusted {
		ubyte* ptr = extern_.malloc(8);
		ubyte* ptr2 = extern_.malloc(16);
		*ptr = 1;
		verify(*ptr == 1);
		verify(ptr2 == ptr + 8);
		extern_.free(ptr2);
		extern_.free(ptr);
		return immutable ExitCode(0);
	});
}

void testWrite(ref Test test) {
	immutable FakeExternResult result =
		withFakeExtern(test.alloc, test.allSymbols, (scope ref Extern extern_) @trusted {
			extern_.write(1, "gnarly", 4);
			extern_.write(2, "tubular", 2);
			extern_.write(1, "way cool", 5);
			return immutable ExitCode(42);
		});
	verify(result.err.value == 42);
	verify(strEq(result.stdout, "gnarway c"));
	verify(strEq(result.stderr, "tu"));
}
