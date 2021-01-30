module test.testFakeExtern;

@safe @nogc nothrow: // not pure

import interpret.fakeExtern : FakeExtern, newFakeExtern;
import test.testUtil : Test;
import util.collection.arr : empty;
import util.collection.str : strEqLiteral;
import util.util : verify;

void testFakeExtern(Debug, Alloc)(ref Test!(Debug, Alloc) test) {
	testMallocAndFree(test);
	testWrite(test);
}

private:

@trusted void testMallocAndFree(Debug, Alloc)(ref Test!(Debug, Alloc) test) {
	FakeExtern!Alloc extern_ = newFakeExtern!Alloc(test.alloc);
	ubyte* ptr = extern_.malloc(8);
	ubyte* ptr2 = extern_.malloc(16);
	*ptr = 1;
	verify(*ptr == 1);
	verify(ptr2 != ptr + 8);
	extern_.free(ptr2);
	extern_.free(ptr);
}

void testWrite(Debug, Alloc)(ref Test!(Debug, Alloc) test) {
	FakeExtern!Alloc extern_ = newFakeExtern!Alloc(test.alloc);

	extern_.write(1, "gnarly", 4);
	extern_.write(2, "tubular", 2);
	extern_.write(1, "way cool", 5);

	verify(strEqLiteral(extern_.moveStdout(), "gnarway c"));
	verify(strEqLiteral(extern_.moveStderr(), "tu"));
	verify(empty(extern_.moveStdout()));
	verify(empty(extern_.moveStderr()));
}
