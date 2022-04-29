module util.conv;

@safe @nogc pure nothrow:

import util.util : verify;

immutable(int) safeIntFromUint(immutable uint u) {
	verify(u <= int.max);
	return cast(immutable int) u;
}

immutable(ushort) safeToUshort(immutable size_t a) {
	verify(a <= ushort.max);
	return cast(immutable ushort) a;
}

immutable(uint) safeToUint(immutable size_t a) {
	verify(a <= uint.max);
	return cast(immutable uint) a;
}

immutable(size_t) safeToSizeT(immutable ulong a) {
	verify(a <= size_t.max);
	return cast(immutable size_t) a;
}

immutable(uint) bitsOfFloat32(immutable float value) {
	Converter32 conv;
	conv.asFloat32 = value;
	return conv.asU32;
}

immutable(float) float32OfBits(immutable ulong value) {
	Converter32 conv;
	conv.asU32 = cast(immutable uint) value;
	return conv.asFloat32;
}

immutable(ulong) bitsOfFloat64(immutable double value) {
	Converter64 conv;
	conv.asFloat64 = value;
	return conv.asU64;
}

immutable(double) float64OfBits(immutable ulong value) {
	Converter64 conv;
	conv.asU64 = value;
	return conv.asFloat64;
}

// Result will depend on system endianness
@system immutable(ulong) ulongOfBytes(immutable ubyte[8] value) {
	Converter64 conv;
	conv.asBytes = value;
	return conv.asU64;
}

private:

union Converter32 {
	uint asU32;
	float asFloat32;
}

union Converter64 {
	ulong asU64;
	double asFloat64;
	ubyte[8] asBytes;
}
