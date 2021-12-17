module util.col.tempStr;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc;
import util.col.str : copyToSafeCStr, eachChar, SafeCStr;
import util.util : verify;

struct TempStr {
	private:
	char[1024] buffer = void;
	size_t size;
}

immutable(SafeCStr) copyTempStrToSafeCStr(ref Alloc alloc, ref const TempStr a) {
	return copyToSafeCStr(alloc, a.buffer[0 .. a.size]);
}

@system const(char*) tempStrBegin(return ref TempStr a) {
	return a.buffer.ptr;
}

immutable(size_t) tempStrSize(ref TempStr a) {
	return a.size;
}

void reduceSize(ref TempStr a, immutable size_t newSize) {
	verify(newSize < a.size);
	a.size = newSize;
	a.buffer[a.size] = 0;
}

void pushToTempStr(ref TempStr a, immutable char b) {
	verify(a.size < a.buffer.length);
	a.buffer[a.size] = b;
	a.size++;
}

void pushToTempStr(ref TempStr a, immutable SafeCStr b) {
	eachChar(b, (immutable char c) pure {
		pushToTempStr(a, c);
	});
	nulTerminate(a);
}

void pushToTempStr(ref TempStr a, immutable string b) {
	foreach (immutable char c; b)
		pushToTempStr(a, c);
}

private:

void nulTerminate(ref TempStr a) {
	verify(a.size < a.buffer.length);
	a.buffer[a.size] = '\0';
}
