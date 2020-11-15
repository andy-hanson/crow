module test.testFakeExtern;

@safe @nogc nothrow: // not pure

import interpret.fakeExtern : FakeExtern, newFakeExtern;
import test.testUtil : Test;
import util.collection.arr : empty;
import util.collection.str : strEqLiteral;
import util.ptr : ptrTrustMe_mut;
import util.types : u8;
import util.util : verify;

void testFakeExtern(Alloc)(ref Test!Alloc test) {
	testMallocAndFree(test);
	testWrite(test);
}

private:

@trusted void testMallocAndFree(Alloc)(ref Test!Alloc test) {
	FakeExtern!Alloc extern_ = newFakeExtern!Alloc(test.alloc);
	u8* ptr = extern_.malloc(8);
	u8* ptr2 = extern_.malloc(16);
	*ptr = 1;
	verify(*ptr == 1);
	verify(ptr2 != ptr + 8);
	extern_.free(ptr2);
	extern_.free(ptr);
}

void testWrite(Alloc)(ref Test!Alloc test) {
	FakeExtern!Alloc extern_ = newFakeExtern!Alloc(test.alloc);

	extern_.write(1, "gnarly", 4);
	extern_.write(2, "tubular", 2);
	extern_.write(1, "way cool", 5);

	verify(strEqLiteral(extern_.getStdoutTemp(), "gnarway c"));
	verify(strEqLiteral(extern_.getStderrTemp(), "tu"));

	extern_.clearOutput();
	verify(empty(extern_.getStdoutTemp()));
	verify(empty(extern_.getStderrTemp()));
}
