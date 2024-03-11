module util.conv;

@safe @nogc pure nothrow:

int safeIntFromUint(uint u) {
	assert(u <= int.max);
	return cast(int) u;
}

ushort safeToUshort(size_t a) {
	assert(a <= ushort.max);
	return cast(ushort) a;
}

int safeToInt(size_t a) {
	assert(a <= int.max);
	return cast(int) a;
}

bool isUint(ulong a) =>
	a <= uint.max;

static if (!is(uint == size_t))
	uint safeToUint()(uint a) { static assert(false); }
uint safeToUint(ulong a) {
	assert(isUint(a));
	return cast(uint) a;
}

size_t safeToSizeT(ulong a) {
	assert(a <= size_t.max);
	return cast(size_t) a;
}

uint bitsOfFloat32(float value) {
	Converter32 conv;
	conv.asFloat32 = value;
	return conv.asUint;
}

float float32OfBits(ulong value) {
	Converter32 conv;
	conv.asUint = cast(uint) value;
	return conv.asFloat32;
}

ulong bitsOfFloat64(double value) {
	Converter64 conv;
	conv.asFloat64 = value;
	return conv.asUlong;
}

double float64OfBits(ulong value) {
	Converter64 conv;
	conv.asUlong = value;
	return conv.asFloat64;
}

uint uintOfUshorts(ushort[2] a) =>
	((cast(uint) a[0]) << 16) | a[1];
ushort[2] ushortsOfUint(uint a) =>
	[a >> 16, a & 0xffff];

static assert(uintOfUshorts([0x1234, 0x5678]) == 0x12345678);
static assert(ushortsOfUint(0x12345678) == [0x1234, 0x5678], ushortsOfUint(0x12345678));

ulong bitsOfByte(byte a) =>
	cast(ulong) (cast(ubyte) a);

ulong bitsOfShort(short a) =>
	cast(ulong) (cast(ushort) a);

ulong bitsOfInt(int a) =>
	cast(ulong) (cast(uint) a);

ulong bitsOfLong(long a) =>
	cast(ulong) a;

private:

union Converter32 {
	uint asUint;
	float asFloat32;
}

union Converter64 {
	ulong asUlong;
	double asFloat64;
}
