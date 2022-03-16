module util.col.tempStr;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc;
import util.col.str : copyStr, copyToSafeCStr, eachChar, SafeCStr;
import util.util : verify;

struct TempStr(size_t strCapacity) {
	@safe @nogc pure nothrow:

	// Unfortunately LDC will 'memset' fields even though they are marked '= void'.
	// The whole 'TempStr' must be marked '= void'.
	// Then 'initializeTempStr'.
	@disable this();
	@disable this(ref const TempStr);

	@system inout(char*) ptr() inout {
		return buffer.ptr;
	}
	immutable(size_t) capacity() {
		return buffer.length;
	}

	private:
	size_t length_ = void;
	char[strCapacity] buffer = void;
}

void initializeTempStr(size_t capacity)(ref TempStr!capacity a) {
	a.length_ = 0;
}

immutable(size_t) length(size_t capacity)(ref const TempStr!capacity a) {
	return a.length_;
}

void setLength(size_t capacity)(ref TempStr!capacity a, immutable size_t newLength) {
	verify(newLength < capacity);
	a.length_ = newLength;
	nulTerminate(a);
}

immutable(string) copyTempStrToString(size_t capacity)(ref Alloc alloc, ref const TempStr!capacity a) {
	return copyStr(alloc, tempAsStr(a));
}

@trusted immutable(SafeCStr) asTempSafeCStr(size_t capacity)(ref const TempStr!capacity a) {
	return immutable SafeCStr(cast(immutable) a.buffer.ptr);
}

immutable(SafeCStr) copyTempStrToSafeCStr(size_t capacity)(ref Alloc alloc, ref const TempStr!capacity a) {
	return copyToSafeCStr(alloc, a.buffer[0 .. a.length]);
}

@trusted immutable(string) tempAsStr(size_t capacity)(return ref const TempStr!capacity a) {
	return cast(immutable) a.buffer[0 .. a.length];
}

void pushToTempStr(size_t capacity)(ref TempStr!capacity a, immutable char b) {
	verify(a.length < a.buffer.length);
	a.buffer[a.length] = b;
	a.length_++;
	nulTerminate(a);
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
	verify(a.length < a.buffer.length);
	a.buffer[a.length] = '\0';
}
