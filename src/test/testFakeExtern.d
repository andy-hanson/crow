module test.testFakeExtern;

@safe @nogc nothrow: // not pure

import interpret.fakeExtern : FakeExtern, newFakeExtern;
import util.collection.arr : empty;
import util.collection.str : strEqLiteral;
import util.ptr : ptrTrustMe_mut;
import util.types : u8;
import util.util : verify;

void testFakeExtern(Alloc)(ref Alloc alloc) {
	testMallocAndFree(alloc);
	testWrite(alloc);
}

private:

@trusted void testMallocAndFree(Alloc)(ref Alloc alloc) {
	FakeExtern!Alloc extern_ = newFakeExtern!Alloc(ptrTrustMe_mut(alloc));
	u8* ptr = extern_.malloc(8);
	u8* ptr2 = extern_.malloc(16);
	*ptr = 1;
	verify(*ptr == 1);
	verify(ptr2 != ptr + 8);
	extern_.free(ptr2);
	extern_.free(ptr);
}

void testWrite(Alloc)(ref Alloc alloc) {
	FakeExtern!Alloc extern_ = newFakeExtern!Alloc(ptrTrustMe_mut(alloc));

	extern_.write(1, "gnarly", 4);
	extern_.write(2, "tubular", 2);
	extern_.write(1, "way cool", 5);

	verify(strEqLiteral(extern_.getStdoutTemp(), "gnarway c"));
	verify(strEqLiteral(extern_.getStderrTemp(), "tu"));

	extern_.clearOutput();
	verify(empty(extern_.getStdoutTemp()));
	verify(empty(extern_.getStderrTemp()));
}
