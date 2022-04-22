module interpret.stacks;

@nogc nothrow: // not @safe, not pure

import interpret.bytecode : Operation;
import util.util : verify;

private immutable size_t stacksStorageSize = 0x10000;
private static bool stacksInitialized = false;
private static Stacks.Inner savedStacks;
private static ulong[stacksStorageSize] stacksStorage = void;

void saveStacks(Stacks a) {
	verify(stacksInitialized);
	savedStacks = a.inner;
}

/*
WARN: In case this is reentrant, the interpreter must call 'saveStacks' before.
The callback should have a net 0 effect on the stack depths..
*/
immutable(T) withStacks(T)(scope immutable(T) delegate(ref Stacks) @nogc nothrow cb) {
	if (!stacksInitialized) {
		savedStacks = Stacks.Inner(
			stacksStorage.ptr - 1,
			cast(immutable(Operation)**) (stacksStorage.ptr + stacksStorage.length));
		stacksInitialized = true;
	}

	Stacks.Inner stacksAtStart = savedStacks;
	version (Windows) {
		Stacks curStacks = Stacks(&stacksAtStart);
	} else {
		Stacks curStacks = stacksAtStart;
	}

	static if (is(T == void))
		cb(curStacks);
	else
		immutable T res = cb(curStacks);

	verify(curStacks.inner == stacksAtStart);
	savedStacks = stacksAtStart;

	static if (!is(T == void))
		return res;
}

private immutable(Operation)** storageEnd(ref Stacks a) {
	verify!"storageEnd"(a.storage.length == stacksStorageSize);
	return cast(immutable(Operation)**) (a.storage.ptr + a.storage.length);
}
private const(immutable(Operation)**) storageEnd(ref const Stacks a) {
	verify!"storageEnd"(a.storage.length == stacksStorageSize);
	return cast(immutable(Operation)**) (a.storage.ptr + a.storage.length);
}

struct Stacks {
	@safe @nogc nothrow:

	private:
	version (Windows) {
		// Apparently, tail recursion breaks on Windows if Stacks is bigger than a pointer.
		// See https://github.com/ldc-developers/ldc/issues/3968
		public struct Inner {
			private:
			ulong* dataPtr;
			immutable(Operation)** returnPtr;
		}
		Inner* inner_;

		public ref inout(Inner) inner() inout { return *inner_; }
		ref inout(ulong*) dataPtr() inout { return inner.dataPtr; }
		ref inout(immutable(Operation)**) returnPtr() inout { return inner.returnPtr; }

		public void setTo(Inner inner) { *inner_ = inner; }

	} else {
		public alias Inner = Stacks;
		// Grows right towards returnPtr. Points to the last-pushed value.
		ulong* dataPtr;
		// Grows left towards dataPtr. Points to the last-pushed value.
		immutable(Operation)** returnPtr;

		public ref inout(Inner) inner() inout { return this; }
	}

	@trusted ulong[] storage() { return stacksStorage; }
	@trusted const(ulong[]) storage() const { return stacksStorage; }
}
version (Windows) {
	static assert(Stacks.sizeof == (void*).sizeof);
} else {
	static assert(Stacks.sizeof == (void*).sizeof * 2);
}

immutable(bool) dataStackIsEmpty(ref const Stacks a) {
	debug verify!"dataStackIsEmpty check"(a.dataPtr >= dataBegin(a) - 1);
	return a.dataPtr == dataBegin(a) - 1;
}

void dataPush(ref Stacks a, immutable ulong value) {
	a.dataPtr++;
	debug verify!"dataPush check"(a.dataPtr < cast(ulong*) a.returnPtr);
	*a.dataPtr = value;
}

void dataPush(ref Stacks a, scope immutable ulong[] values) {
	foreach (immutable ulong value; values)
		dataPush(a, value);
}

void dataPushUninitialized(ref Stacks a, immutable size_t n) {
	a.dataPtr += n;
	debug verify!"dataPushUninitialized check"(a.dataPtr < cast(ulong*) a.returnPtr);
}

immutable(ulong) dataPeek(ref const Stacks a, immutable size_t offset = 0) {
	return *(a.dataPtr - offset);
}

void dataDupWord(ref Stacks a, immutable size_t offsetWords) {
	dataPush(a, dataPeek(a, offsetWords));
}

void dataDupWords(ref Stacks a, immutable size_t offsetWords, immutable size_t sizeWords) {
	const(ulong)* ptr = dataTop(a) - offsetWords;
	foreach (immutable size_t i; 0 .. sizeWords) {
		dataPush(a, *ptr);
		ptr++;
	}
}

immutable(ulong) dataPop(ref Stacks a) {
	immutable ulong res = *a.dataPtr;
	a.dataPtr--;
	return res;
}

ulong* dataRef(ref Stacks a, immutable size_t offset) {
	return a.dataPtr - offset;
}

// WARN: result is temporary!
immutable(ulong[]) dataPopN(return ref Stacks a, immutable size_t n) {
	a.dataPtr -= n;
	return cast(immutable) a.dataPtr[1 .. n + 1];
}

// pointer to the last data value pushed
ulong* dataTop(ref Stacks a) {
	return a.dataPtr;
}

// Pointer to the value at the bottom of the data stack
const(ulong*) dataBegin(ref const Stacks a) {
	return a.storage.ptr;
}

// One past the last data value pushed
ulong* dataEnd(ref Stacks a) {
	return a.dataPtr + 1;
}

immutable(ulong[]) dataTempAsArr(ref const Stacks a) {
	return cast(immutable) a.storage.ptr[0 .. a.dataPtr + 1 - a.storage.ptr];
}

immutable(ulong) dataRemove(ref Stacks a, immutable size_t offset) {
	immutable ulong res = dataPeek(a, offset);
	dataRemoveN(a, offset, 1);
	return res;
}

void dataRemoveN(ref Stacks a, immutable size_t offset, immutable size_t nToRemove) {
	// For example, if offset = 0 and nEntries = 1, this pops the last element.
	debug verify!"dataRemoveN check"(offset + 1 >= nToRemove);
	ulong* outPtr = a.dataPtr - offset;
	ulong* inPtr = outPtr + nToRemove;
	foreach (immutable size_t i; 0 .. offset + 1 - nToRemove)
		outPtr[i] = inPtr[i];
	a.dataPtr -= nToRemove;
}

immutable(bool) returnStackIsEmpty(ref const Stacks a) {
	debug verify!"returnStackIsEmpty check"(a.returnPtr <= storageEnd(a));
	return a.returnPtr == storageEnd(a);
}

immutable(size_t) returnStackSize(ref const Stacks a) {
	return storageEnd(a) - a.returnPtr;
}

void returnPush(ref Stacks a, immutable Operation* value) {
	const ulong* begin = dataBegin(a);
	immutable(Operation)** end = storageEnd(a);
	debug verify!"returnPush check 1"(begin - 1 <= a.dataPtr);
	debug verify!"returnPush check 2"(a.dataPtr < cast(ulong*) a.returnPtr);
	debug verify!"returnPush check 3"(a.returnPtr <= end);

	a.returnPtr--;
	*a.returnPtr = value;
}

immutable(Operation*) returnPeek(ref const Stacks a, immutable size_t offset = 0) {
	return *(a.returnPtr + offset);
}

void setReturnPeek(ref Stacks a, immutable Operation* value) {
	*a.returnPtr = value;
}

immutable(Operation*) returnPop(ref Stacks a) {
	immutable Operation* res = *a.returnPtr;
	a.returnPtr++;
	return res;
}

immutable(Operation*[]) returnTempAsArrReverse(ref const Stacks a) {
	return cast(immutable) a.returnPtr[0 .. returnStackSize(a)];
}
