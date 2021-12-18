module util.col.tempStr;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc;
import util.col.str : copyStr, copyToSafeCStr, eachChar, SafeCStr;
import util.util : verify;

struct TempStr(size_t capacity) {
	private:
	char[capacity] buffer = void;
	size_t size;
}

immutable(string) copyTempStrToString(size_t capacity)(ref Alloc alloc, ref const TempStr!capacity a) {
	return copyStr(alloc, tempAsStr(a));
}

immutable(SafeCStr) copyTempStrToSafeCStr(size_t capacity)(ref Alloc alloc, ref const TempStr!capacity a) {
	return copyToSafeCStr(alloc, a.buffer[0 .. a.size]);
}

@trusted immutable(string) tempAsStr(size_t capacity)(return ref const TempStr!capacity a) {
	return cast(immutable) a.buffer[0 .. a.size];
}

@system const(char*) tempStrBegin(size_t capacity)(return ref TempStr!capacity a) {
	return a.buffer.ptr;
}

immutable(size_t) tempStrSize(size_t capacity)(ref TempStr!capacity a) {
	return a.size;
}

void reduceSize(size_t capacity)(ref TempStr!capacity a, immutable size_t newSize) {
	verify(newSize < a.size);
	a.size = newSize;
	a.buffer[a.size] = 0;
}

void pushToTempStr(size_t capacity)(ref TempStr!capacity a, immutable char b) {
	verify(a.size < a.buffer.length);
	a.buffer[a.size] = b;
	a.size++;
}

void pushToTempStr(size_t capacity)(ref TempStr!capacity a, immutable SafeCStr b) {
	eachChar(b, (immutable char c) pure {
		pushToTempStr(a, c);
	});
	nulTerminate(a);
}

void pushToTempStr(size_t capacity)(ref TempStr!capacity a, immutable string b) {
	foreach (immutable char c; b)
		pushToTempStr(a, c);
}

private:

void nulTerminate(size_t capacity)(ref TempStr!capacity a) {
	verify(a.size < a.buffer.length);
	a.buffer[a.size] = '\0';
}
