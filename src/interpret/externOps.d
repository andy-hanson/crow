module interpret.externOps;

@safe @nogc nothrow: // not pure

import interpret.bytecode : ExternOp;
import interpret.runBytecode : DataStack;
import util.collection.globalAllocatedStack : pop, push;
import util.collection.mutDict : addToMutDict, mustDelete, MutDict, mutDictIsEmpty;
import util.ptr : comparePtrRaw, Ptr;
import util.types : u8, Nat64;
import util.util : todo, verify;

struct Extern(Alloc) {
	@safe @nogc pure nothrow:

	Ptr!Alloc alloc;
	MutDict!(u8*, immutable size_t, comparePtrRaw!u8) allocations;

	~this() {
		verify(mutDictIsEmpty(allocations));
	}
}

Extern!Alloc newExtern(Alloc)(Ptr!Alloc alloc) {
	return Extern!Alloc(alloc);
}

@trusted void applyExternOp(Alloc)(ref Extern!Alloc a, ref DataStack dataStack, immutable ExternOp op) {
	final switch (op) {
		case ExternOp.free:
			u8* ptr = cast(u8*) pop(dataStack).raw();
			immutable size_t size = mustDelete!(u8*, immutable size_t, comparePtrRaw!u8)(a.allocations, ptr);
			a.alloc.free(ptr, size);
			break;
		case ExternOp.malloc:
			immutable size_t size = pop(dataStack).raw();
			u8* ptr = a.alloc.allocate(size);
			push(dataStack, immutable Nat64(cast(immutable size_t) ptr));
			addToMutDict(a.alloc, a.allocations, ptr, size);
			break;
		case ExternOp.write:
			// Emulate output streams stdout and stderr.
			// Assert error on invalid output stream.
			todo!void("write");
	}
}

private:

