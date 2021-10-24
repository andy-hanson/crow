module test.testFakeExtern;

@safe @nogc pure nothrow:

import interpret.fakeExtern : FakeExtern, newFakeExtern;
import test.testUtil : Test;
import util.collection.arr : empty;
import util.collection.str : strEq;
import util.util : verify;

void testFakeExtern(Debug)(ref Test!Debug test) {
	testMallocAndFree(test);
	testWrite(test);
}

private:

@trusted void testMallocAndFree(Debug)(ref Test!Debug test) {
	FakeExtern extern_ = newFakeExtern(test.alloc);
	ubyte* ptr = extern_.malloc(8);
	ubyte* ptr2 = extern_.malloc(16);
	*ptr = 1;
	verify(*ptr == 1);
	verify(ptr2 != ptr + 8);
	extern_.free(ptr2);
	extern_.free(ptr);
}

void testWrite(Debug)(ref Test!Debug test) {
	FakeExtern extern_ = newFakeExtern(test.alloc);

	extern_.write(1, "gnarly", 4);
	extern_.write(2, "tubular", 2);
	extern_.write(1, "way cool", 5);

	verify(strEq(extern_.moveStdout(), "gnarway c"));
	verify(strEq(extern_.moveStderr(), "tu"));
	verify(empty(extern_.moveStdout()));
	verify(empty(extern_.moveStderr()));
}
