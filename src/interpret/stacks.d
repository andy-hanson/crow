module interpret.stacks;

@nogc nothrow: // not @safe, not pure

import interpret.bytecode : Operation;
import util.util : verify;

private size_t stacksStorageSize() =>
	0x10000;
private static bool stacksInitialized = false;
private static Stacks savedStacks;
private static ulong[stacksStorageSize] stacksStorage = void;

pragma(inline, true):

void saveStacks(Stacks a) {
	verify(stacksInitialized);
	savedStacks = a;
}

/*
WARN: In case this is reentrant, the interpreter must call 'saveStacks' before.
The callback should have a net 0 effect on the stack depths..
*/
@trusted T withStacks(T)(in T delegate(ref Stacks) @nogc nothrow cb) {
	if (!stacksInitialized) {
		savedStacks = Stacks(
			stacksStorage.ptr - 1,
			cast(Operation**) (stacksStorage.ptr + stacksStorage.length));
		stacksInitialized = true;
	}

	Stacks stacksAtStart = savedStacks;
	Stacks curStacks = stacksAtStart;

	static if (is(T == void))
		cb(curStacks);
	else
		T res = cb(curStacks);

	verify(curStacks == stacksAtStart);
	savedStacks = stacksAtStart;

	static if (!is(T == void))
		return res;
}

private inout(Operation)** storageEnd(ref inout Stacks a) {
	verify!"storageEnd"(stacksStorage.length == stacksStorageSize);
	return cast(inout(Operation)**) (stacksStorage.ptr + stacksStorage.length);
}

struct Stacks {
	ulong* dataPtr;
	Operation** returnPtr;
}

bool dataStackIsEmpty(in Stacks a) {
	debug verify!"dataStackIsEmpty check"(a.dataPtr >= dataBegin(a) - 1);
	return a.dataPtr == dataBegin(a) - 1;
}

void dataPush(ref Stacks a, ulong value) {
	a.dataPtr++;
	debug verify!"dataPush check"(a.dataPtr < cast(ulong*) a.returnPtr);
	*a.dataPtr = value;
}

void dataPush(ref Stacks a, in ulong[] values) {
	foreach (ulong value; values)
		dataPush(a, value);
}

void dataPushUninitialized(ref Stacks a, size_t n) {
	a.dataPtr += n;
	debug verify!"dataPushUninitialized check"(a.dataPtr < cast(ulong*) a.returnPtr);
}

ulong dataPeek(in Stacks a, size_t offset = 0) =>
	*(a.dataPtr - offset);

void dataDupWords(ref Stacks a, size_t offsetWords, size_t sizeWords) {
	debug verify(sizeWords != 0);
	debug verify(sizeWords <= offsetWords + 1);
	const(ulong)* ptr = dataTop(a) - offsetWords;
	foreach (size_t i; 0 .. sizeWords) {
		dataPush(a, *ptr);
		ptr++;
	}
}

ulong dataPop(ref Stacks a) {
	ulong res = *a.dataPtr;
	a.dataPtr--;
	return res;
}

ulong* dataRef(ref Stacks a, size_t offset) =>
	a.dataPtr - offset;

// WARN: result is temporary!
immutable(ulong[]) dataPopN(return ref Stacks a, size_t n) {
	a.dataPtr -= n;
	return cast(immutable) a.dataPtr[1 .. n + 1];
}

// pointer to the last data value pushed
ulong* dataTop(ref Stacks a) =>
	a.dataPtr;

// Pointer to the value at the bottom of the data stack
const(ulong*) dataBegin(in Stacks a) =>
	stacksStorage.ptr;

// One past the last data value pushed
ulong* dataEnd(ref Stacks a) =>
	a.dataPtr + 1;

immutable(ulong[]) dataTempAsArr(ref const Stacks a) =>
	cast(immutable) stacksStorage.ptr[0 .. a.dataPtr + 1 - stacksStorage.ptr];

ulong dataRemove(ref Stacks a, size_t offset) {
	ulong res = dataPeek(a, offset);
	dataReturn(a, offset, offset);
	return res;
}

/*
Typically used to remove local variables when returning from a function.
'offsetWords' is the new location of the first word of the return value.
'sizeWords' is allowed to be 0, in which case this just removes the top 'offsetWords' entries from the stack.
*/
void dataReturn(ref Stacks a, size_t offsetWords, size_t sizeWords) {
	debug verify(sizeWords <= offsetWords);
	const ulong* inPtr = a.dataPtr + 1 - sizeWords;
	ulong* outPtr = a.dataPtr - offsetWords;
	foreach (size_t i; 0 .. sizeWords)
		outPtr[i] = inPtr[i];
	a.dataPtr -= (offsetWords + 1 - sizeWords);
}

bool returnStackIsEmpty(in Stacks a) {
	debug verify!"returnStackIsEmpty check"(a.returnPtr <= storageEnd(a));
	return a.returnPtr == storageEnd(a);
}

size_t returnStackSize(in Stacks a) =>
	storageEnd(a) - a.returnPtr;

void returnPush(ref Stacks a, Operation* value) {
	const ulong* begin = dataBegin(a);
	Operation** end = storageEnd(a);
	debug verify!"returnPush check 1"(begin - 1 <= a.dataPtr);
	debug verify!"returnPush check 2"(a.dataPtr < cast(ulong*) a.returnPtr);
	debug verify!"returnPush check 3"(a.returnPtr <= end);

	a.returnPtr--;
	*a.returnPtr = value;
}

Operation* returnPeek(in Stacks a, size_t offset = 0) =>
	*(a.returnPtr + offset);

void setReturnPeek(ref Stacks a, Operation* value) {
	*a.returnPtr = value;
}

Operation* returnPop(ref Stacks a) {
	Operation* res = *a.returnPtr;
	a.returnPtr++;
	return res;
}

immutable(Operation*[]) returnTempAsArrReverse(ref const Stacks a) =>
	cast(immutable) a.returnPtr[0 .. returnStackSize(a)];
