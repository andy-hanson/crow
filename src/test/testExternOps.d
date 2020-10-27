module test.testExternOps;

@safe @nogc nothrow: // not pure

import interpret.bytecode : ExternOp;
import interpret.externOps : applyExternOp, Extern, newExtern;
import interpret.runBytecode : DataStack;
import test.testUtil : expectDataStack;
import util.alloc.stackAlloc : StackAlloc;
import util.collection.globalAllocatedStack : peek, push;
import util.ptr : ptrTrustMe_mut;
import util.types : Nat64, u64;
import util.util : verify;

void testExternOps() {
	testMallocAndFree();
}

private:

@trusted void testMallocAndFree() {
	alias Alloc = StackAlloc!("test", 1024);
	Alloc alloc;
	DataStack dataStack;
	Extern!Alloc extern_ = newExtern!Alloc(ptrTrustMe_mut(alloc));
	push(dataStack, immutable Nat64(u64.sizeof));
	applyExternOp(extern_, dataStack, ExternOp.malloc);
	u64* ptr = cast(u64*) peek(dataStack).raw();
	expectDataStack(dataStack, [immutable Nat64(cast(immutable u64) ptr)]);
	verify(ptr == cast(u64*) alloc.TEST_data());
	applyExternOp(extern_, dataStack, ExternOp.free);
	expectDataStack(dataStack, []);
}
