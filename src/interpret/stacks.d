module interpret.stacks;

@nogc nothrow: // not @safe, not pure

import interpret.bytecode : Operation;
import util.col.array : arrayOfRange, endPtr;

private size_t stacksStorageSize() =>
	0x10000;
private static bool stacksInitialized = false;
private static Stacks savedStacks;
private static ulong[stacksStorageSize] stacksStorage = void;

pragma(inline, true):

void saveStacks(Stacks a) {
	assert(stacksInitialized);
	savedStacks = a;
}

Stacks loadStacks() {
	return savedStacks;
}

/*
WARN: In case this is reentrant, the interpreter must call 'saveStacks' before.
The callback should have a net 0 effect on the stack depth.
*/
@trusted T withDefaultStacks(T)(in T delegate(ref Stacks) @nogc nothrow cb) {
	if (!stacksInitialized) {
		savedStacks = stacksForRange(stacksStorage);
		stacksInitialized = true;
	}

	Stacks stacksAtStart = savedStacks;
	Stacks curStacks = stacksAtStart;

	static if (is(T == void))
		cb(curStacks);
	else
		T res = cb(curStacks);

	assert(curStacks == stacksAtStart);
	savedStacks = stacksAtStart;

	static if (!is(T == void))
		return res;
}

void assertStacksAtOriginalState(in Stacks a) {
	assert(dataEnd(a) == stacksStorage.ptr);
	assert(a.returnPtr == (cast(Operation**) endPtr(stacksStorage)) - 1);
	assert(*a.returnPtr == null);
}

pure:

struct Stacks {
	ulong* dataPtr; // Pointer to the previous pushed value.
	Operation** returnPtr; // Pointer to the previous pushed value.
}

Stacks stacksForRange(ulong[] range) {
	Stacks res = Stacks(cast(ulong*) range.ptr - 1, cast(Operation**) endPtr(range));
	// Initial return entry is null so we can detect it in 'fillBacktrace'
	returnPush(res, null);
	return res;
}

void dataPush(ref Stacks a, ulong value) {
	a.dataPtr++;
	debug assert(a.dataPtr < cast(ulong*) a.returnPtr);
	*a.dataPtr = value;
}

void dataPush(ref Stacks a, in ulong[] values) {
	foreach (ulong value; values)
		dataPush(a, value);
}

ulong* dataPushUninitialized(ref Stacks a, size_t n) {
	ulong* res = dataEnd(a);
	a.dataPtr += n;
	debug assert(a.dataPtr < cast(ulong*) a.returnPtr);
	return res;
}

ulong dataPeek(in Stacks a, size_t offset = 0) =>
	*(a.dataPtr - offset);

void dataDupWords(ref Stacks a, size_t offsetWords, size_t sizeWords) {
	debug assert(sizeWords != 0);
	debug assert(sizeWords <= offsetWords + 1);
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

// One past the last data value pushed; meaning a pointer to the next pushed value
inout(ulong*) dataEnd(ref inout Stacks a) =>
	a.dataPtr + 1;

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
	debug assert(sizeWords <= offsetWords);
	const ulong* inPtr = a.dataPtr + 1 - sizeWords;
	ulong* outPtr = a.dataPtr - offsetWords;
	foreach (size_t i; 0 .. sizeWords)
		outPtr[i] = inPtr[i];
	a.dataPtr -= (offsetWords + 1 - sizeWords);
}
void returnPush(ref Stacks a, Operation* value) {
	a.returnPtr--;
	*a.returnPtr = value;
}

Operation* returnPop(ref Stacks a) {
	Operation* res = *a.returnPtr;
	a.returnPtr++;
	return res;
}

const(Operation*[]) returnTempAsArrReverse(ref const Stacks a) {
	const(Operation*)* cur = a.returnPtr;
	while (*cur != null)
		cur++;
	return arrayOfRange(a.returnPtr, cur);
}
