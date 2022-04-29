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
// NOTE: first entry will be dummy, since stack is initialized with a peek value.
private static ulong[stacksStorageSize] stacksStorage = void;

//TODO!
private immutable size_t N_PEEK = 1;

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
			0,
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

	// Points to last value written to memory (meaning, not counting 'dataPeek_')
	ulong* dataPtr_;
	// Stores the last value pushed.
	ulong dataPeek_;
	// Points to the last value returned.
	immutable(Operation)** returnPtr_;
}

private void dataPushToMemory(ref Stacks a, ulong value) {
	a.dataPtr_++;
	debug verify(a.dataPtr_ < cast(ulong*) a.returnPtr_);
	*a.dataPtr_ = value;
}

private immutable(ulong) dataPopFromMemory(ref Stacks a) {
	immutable ulong res = *a.dataPtr_;
	a.dataPtr_--;
	return res;
}

void dataApplyUnary(alias cb)(ref Stacks a) {
	a.dataPeek_ = cb(a.dataPeek_);
}

void dataApplyBinary(alias cb)(ref Stacks a) {
	a.dataPeek_ = cb(dataPopFromMemory(a), a.dataPeek_);
}

// Used by operations that are simpler with all data in memory and not touch 'dataPeek_'.
// Be sure to call 'restorePeek' after!
private void dataPeekFlush(ref Stacks a) {
	dataPushToMemory(a, a.dataPeek_);
}

private void dataPeekRestore(ref Stacks a) {
	a.dataPeek_ = dataPopFromMemory(a);
}

immutable(bool) dataStackIsEmpty(ref const Stacks a) {
	// The value in 'a.dataPeek_' will be a dummy value in this case.
	debug verify!"dataStackIsEmpty check"(a.dataPtr_ >= stacksStorage.ptr - 1);
	return a.dataPtr_ == stacksStorage.ptr - 1;
}

void dataPush(ref Stacks a, immutable ulong value) {
	dataPushToMemory(a, a.dataPeek_);
	a.dataPeek_ = value;
}

void dataPush(ref Stacks a, scope immutable ulong[] values) {
	foreach (immutable ulong value; values)
		dataPush(a, value);
}

void dataReadAndPush(ref Stacks a, const ubyte* readFrom, immutable size_t sizeBytes) {
	dataPeekFlush(a);
	dataReadAndPushInner(a, readFrom, sizeBytes);
	dataPeekRestore(a);
}

void dataReadAndPushInner(ref Stacks a, const ubyte* readFrom, immutable size_t sizeBytes) {
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
	dataPeekFlush(a);
	immutable size_t sizeWords = divRoundUp(sizeBytes, ulong.sizeof);
	ubyte* src = cast(ubyte*) (a.dataPtr_ + 1 - sizeWords);
	a.dataPtr_ -= sizeWords;
	ubyte* dest = (cast(ubyte*) *a.dataPtr_) + offsetBytes;
	a.dataPtr_--;
	memcpy(dest, src, sizeBytes);
	dataPeekRestore(a);
}

immutable(ulong) dataPeek(ref const Stacks a, immutable size_t offset = 0) {
	return offset == 0
		? a.dataPeek_
		: *(a.dataPtr_ - (offset - 1));
}

void dataDupWord(ref Stacks a, immutable size_t offsetWords) {
	dataPush(a, dataPeek(a, offsetWords));
}

void dataDupWords(ref Stacks a, immutable size_t offsetWords, immutable size_t sizeWords) {
	foreach (immutable size_t i; 0 .. sizeWords)
		dataPush(a, dataPeek(a, offsetWords));
}

void dataDupBytes(ref Stacks a, immutable size_t offsetBytes, immutable size_t sizeBytes) {
	dataPeekFlush(a);
	const ubyte* ptr = (cast(const ubyte*) (a.dataPtr_ + 1)) - offsetBytes;
	dataReadAndPushInner(a, ptr, sizeBytes);
	dataPeekRestore(a);
}

immutable(ulong) dataPop(ref Stacks a) {
	immutable ulong res = a.dataPeek_;
	a.dataPeek_ = dataPopFromMemory(a);
	return res;
}

void dataPushRef(ref Stacks a, immutable size_t offset) {
	dataPeekFlush(a);
	dataPushToMemory(a, cast(immutable ulong) (a.dataPtr_ - offset));
	dataPeekRestore(a);
}

// WARN: result is temporary!
immutable(ulong[]) dataPopN(return ref Stacks a, immutable size_t n) {
	dataPeekFlush(a);
	a.dataPtr_ -= n;
	immutable ulong[] res = cast(immutable) a.dataPtr_[1 .. n + 1];
	dataPeekRestore(a);
	return res;
}

void dataDropN(ref Stacks a, immutable size_t n) {
	dataPopN(a, n);
}

void dataPopAndSet(ref Stacks a, immutable size_t offsetWords, immutable size_t sizeWords) {
	debug verify(offsetWords + 1 >= sizeWords * 2);
	dataPeekFlush(a);
	// Start at the end of the range and pop in reverse
	memcpyWords(a.dataPtr_ - offsetWords, a.dataPtr_ + 1 - sizeWords, sizeWords);
	a.dataPtr_ -= sizeWords;
	dataPeekRestore(a);
}

// Pointer to the value at the bottom of the data stack
const(ulong*) dataBegin(ref const Stacks a) {
	// + 1 because the stack starts out with a '0' value
	return stacksStorage.ptr + 1;
}

immutable(ulong[]) dataTempAsArr(return ref Stacks a) {
	dataPeekFlush(a);
	immutable ulong[] res = cast(immutable) stacksStorage.ptr[N_PEEK .. a.dataPtr_ + 1 - stacksStorage.ptr];
	dataPeekRestore(a);
	return res;
}

immutable(ulong) dataRemove(ref Stacks a, immutable size_t offset) {
	immutable ulong res = dataPeek(a, offset);
	dataRemoveN(a, offset, 1);
	return res;
}

void dataRemoveN(ref Stacks a, immutable size_t offset, immutable size_t nToRemove) {
	dataPeekFlush(a);
	// For example, if offset = 0 and nEntries = 1, this pops the last element.
	debug verify!"dataRemoveN check"(offset + 1 >= nToRemove);
	ulong* outPtr = a.dataPtr_ - offset;
	ulong* inPtr = outPtr + nToRemove;
	foreach (immutable size_t i; 0 .. offset + 1 - nToRemove)
		outPtr[i] = inPtr[i];
	a.dataPtr_ -= nToRemove;
	dataPeekRestore(a);
}

void dataPack(ref Stacks a, immutable size_t inEntries, immutable size_t outEntries, scope immutable PackField[] fields) {
	debug verify(inEntries > outEntries);

	dataPeekFlush(a);
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
	dataPeekRestore(a);
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
