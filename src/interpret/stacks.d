module interpret.stacks;

@nogc nothrow: // not @safe, not pure

pragma(inline, true):

import interpret.bytecode : Operation;
import model.typeLayout : PackField;
import util.conv : safeToSizeT;
import util.memory : memcpy, memcpyWords, memmove;
import util.util : divRoundUp, verify;

private immutable size_t stacksStorageSize = 0x10000;
private static bool stacksInitialized = false;
private static Stacks savedStacks;
private static ulong[stacksStorageSize] stacksStorage = void;

void saveStacks(Stacks a) {
	verify(stacksInitialized);
	savedStacks = a;
}

/*
WARN: In case this is reentrant, the interpreter must call 'saveStacks' before.
The callback should have a net 0 effect on the stack depths..
*/
immutable(T) withStacks(T)(scope immutable(T) delegate(ref Stacks) @nogc nothrow cb) {
	if (!stacksInitialized) {
		savedStacks = Stacks(
			stacksStorage.ptr - 1,
			cast(immutable(Operation)**) (stacksStorage.ptr + stacksStorage.length));
		stacksInitialized = true;
	}

	Stacks stacksAtStart = savedStacks;
	Stacks curStacks = stacksAtStart;

	static if (is(T == void))
		cb(curStacks);
	else
		immutable T res = cb(curStacks);

	verify(curStacks == stacksAtStart);
	savedStacks = stacksAtStart;

	static if (!is(T == void))
		return res;
}

private immutable(Operation)** storageEnd(ref Stacks a) {
	verify!"storageEnd"(stacksStorage.length == stacksStorageSize);
	return cast(immutable(Operation)**) (stacksStorage.ptr + stacksStorage.length);
}
private const(immutable(Operation)**) storageEnd(ref const Stacks a) {
	verify!"storageEnd"(stacksStorage.length == stacksStorageSize);
	return cast(immutable(Operation)**) (stacksStorage.ptr + stacksStorage.length);
}

struct Stacks {
	// Treat all fields as private.
	// Only exposed since `Operation` passes these as separate parameters for performance.

	// Points to last value pushed.
	ulong* dataPtr_;
	// Points to the last value returned.
	immutable(Operation)** returnPtr_;
}

void dataApplyUnary(alias cb)(ref Stacks a) {
	*a.dataPtr_ = cb(*a.dataPtr_);
}

void dataApplyBinary(alias cb)(ref Stacks a) {
	immutable size_t rhs = dataPop(a);
	*a.dataPtr_ = cb(*a.dataPtr_, rhs);
}

immutable(bool) dataStackIsEmpty(ref const Stacks a) {
	debug verify!"dataStackIsEmpty check"(a.dataPtr_ >= stacksStorage.ptr - 1);
	return a.dataPtr_ == stacksStorage.ptr - 1;
}

void dataPush(ref Stacks a, immutable ulong value) {
	a.dataPtr_++;
	debug verify(a.dataPtr_ < cast(ulong*) a.returnPtr_);
	*a.dataPtr_ = value;
}

void dataPush(ref Stacks a, scope immutable ulong[] values) {
	foreach (immutable ulong value; values)
		dataPush(a, value);
}

void dataReadAndPush(ref Stacks a, const ubyte* readFrom, immutable size_t sizeBytes) {
	a.dataPtr_++;
	memcpy(cast(ubyte*) a.dataPtr_, readFrom, sizeBytes);
	ubyte* bytePtr = (cast(ubyte*) a.dataPtr_) + sizeBytes;
	a.dataPtr_ += divRoundUp(sizeBytes, ulong.sizeof);
	while (bytePtr < cast(ubyte*) a.dataPtr_) {
		*bytePtr = 0;
		bytePtr++;
	}
	a.dataPtr_--; // since it should point to the last value written
}

// On the stack is a pointer followed by the data to write to it.
void dataPopAndWriteToPtr(ref Stacks a, immutable size_t offsetBytes, immutable size_t sizeBytes) {
	immutable size_t sizeWords = divRoundUp(sizeBytes, ulong.sizeof);
	ubyte* src = cast(ubyte*) (a.dataPtr_ + 1 - sizeWords);
	a.dataPtr_ -= sizeWords;
	ubyte* dest = (cast(ubyte*) *a.dataPtr_) + offsetBytes;
	a.dataPtr_--;
	memcpy(dest, src, sizeBytes);
}

immutable(ulong) dataPeek(ref const Stacks a, immutable size_t offset = 0) {
	return *(a.dataPtr_ - offset);
}

void dataDupWord(ref Stacks a, immutable size_t offsetWords) {
	dataPush(a, dataPeek(a, offsetWords));
}

void dataDupWords(ref Stacks a, immutable size_t offsetWords, immutable size_t sizeWords) {
	foreach (immutable size_t i; 0 .. sizeWords)
		dataPush(a, dataPeek(a, offsetWords));
}

void dataDupBytes(ref Stacks a, immutable size_t offsetBytes, immutable size_t sizeBytes) {
	const ubyte* ptr = (cast(const ubyte*) (a.dataPtr_ + 1)) - offsetBytes;
	dataReadAndPush(a, ptr, sizeBytes);
}

immutable(ulong) dataPop(ref Stacks a) {
	immutable ulong res = *a.dataPtr_;
	a.dataPtr_--;
	return res;
}

void dataPushRef(ref Stacks a, immutable size_t offset) {
	dataPush(a, cast(immutable ulong) (a.dataPtr_ - offset));
}

// WARN: result is temporary!
immutable(ulong[]) dataPopN(return ref Stacks a, immutable size_t n) {
	a.dataPtr_ -= n;
	return cast(immutable) a.dataPtr_[1 .. n + 1];
}

void dataDropN(ref Stacks a, immutable size_t n) {
	dataPopN(a, n);
}

void dataPopAndSet(ref Stacks a, immutable size_t offsetWords, immutable size_t sizeWords) {
	debug verify(offsetWords + 1 >= sizeWords * 2);
	// Start at the end of the range and pop in reverse
	memcpyWords(a.dataPtr_ - offsetWords, a.dataPtr_ + 1 - sizeWords, sizeWords);
	a.dataPtr_ -= sizeWords;
}

// Pointer to the value at the bottom of the data stack
const(ulong*) dataBegin(ref const Stacks a) {
	return stacksStorage.ptr;
}

immutable(ulong[]) dataTempAsArr(return ref Stacks a) {
	return cast(immutable) stacksStorage.ptr[0 .. a.dataPtr_ + 1 - stacksStorage.ptr];
}

immutable(ulong) dataRemove(ref Stacks a, immutable size_t offset) {
	immutable ulong res = dataPeek(a, offset);
	dataRemoveN(a, offset, 1);
	return res;
}

void dataRemoveN(ref Stacks a, immutable size_t offset, immutable size_t nToRemove) {
	// For example, if offset = 0 and nEntries = 1, this pops the last element.
	debug verify!"dataRemoveN check"(offset + 1 >= nToRemove);
	ulong* outPtr = a.dataPtr_ - offset;
	ulong* inPtr = outPtr + nToRemove;
	foreach (immutable size_t i; 0 .. offset + 1 - nToRemove)
		outPtr[i] = inPtr[i];
	a.dataPtr_ -= nToRemove;
}

void dataPack(ref Stacks a, immutable size_t inEntries, immutable size_t outEntries, scope immutable PackField[] fields) {
	debug verify(inEntries > outEntries);

	ubyte* base = cast(ubyte*) (a.dataPtr_ + 1 - inEntries);
	foreach (immutable PackField field; fields)
		memmove(base + field.outOffset, base + field.inOffset, safeToSizeT(field.size));

	a.dataPtr_ -= (inEntries - outEntries);

	// fill remaining bytes with 0
	ubyte* ptr = base + fields[$ - 1].outOffset + fields[$ - 1].size;
	while (ptr < cast(ubyte*) (a.dataPtr_ + 1)) {
		*ptr = 0;
		ptr++;
	}
}

immutable(bool) returnStackIsEmpty(ref const Stacks a) {
	debug verify!"returnStackIsEmpty check"(a.returnPtr_ <= storageEnd(a));
	return a.returnPtr_ == storageEnd(a);
}

immutable(size_t) returnStackSize(ref const Stacks a) {
	return storageEnd(a) - a.returnPtr_;
}

void returnPush(ref Stacks a, immutable Operation* value) {
	a.returnPtr_--;
	debug verify(a.dataPtr_ < cast(ulong*) a.returnPtr_);
	*a.returnPtr_ = value;
}

immutable(Operation*) returnPeek(ref const Stacks a, immutable size_t offset = 0) {
	return *(a.returnPtr_ + offset);
}

void setReturnPeek(ref Stacks a, immutable Operation* value) {
	*a.returnPtr_ = value;
}

immutable(Operation*) returnPop(ref Stacks a) {
	immutable Operation* res = *a.returnPtr_;
	a.returnPtr_++;
	return res;
}

immutable(Operation*[]) returnTempAsArrReverse(ref const Stacks a) {
	return cast(immutable) a.returnPtr_[0 .. returnStackSize(a)];
}
