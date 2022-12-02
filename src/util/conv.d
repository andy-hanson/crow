module util.conv;

@safe @nogc pure nothrow:

import util.util : verify;

int safeIntFromUint(uint u) {
	verify(u <= int.max);
	return cast(int) u;
}

ushort safeToUshort(size_t a) {
	verify(a <= ushort.max);
	return cast(ushort) a;
}

int safeToInt(size_t a) {
	verify(a <= int.max);
	return cast(int) a;
}

uint safeToUint(size_t a) {
	verify(a <= uint.max);
	return cast(uint) a;
}

size_t safeToSizeT(ulong a) {
	verify(a <= size_t.max);
	return cast(size_t) a;
}

uint bitsOfFloat32(float value) {
	Converter32 conv;
	conv.asFloat32 = value;
	return conv.asU32;
}

float float32OfBits(ulong value) {
	Converter32 conv;
	conv.asU32 = cast(uint) value;
	return conv.asFloat32;
}

ulong bitsOfFloat64(double value) {
	Converter64 conv;
	conv.asFloat64 = value;
	return conv.asU64;
}

double float64OfBits(ulong value) {
	Converter64 conv;
	conv.asU64 = value;
	return conv.asFloat64;
}

private:

union Converter32 {
	uint asU32;
	float asFloat32;
}

union Converter64 {
	ulong asU64;
	double asFloat64;
}
