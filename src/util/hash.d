module util.hash;

@safe @nogc pure nothrow:

struct Hasher {
	@safe @nogc pure nothrow:

	private ulong value;

	ulong finish() =>
		value;

	private:

	void mix(immutable ulong n) {
		value = value ^ n;
	}
}

void hashEnum(E)(ref Hasher hasher, immutable E a) {
	hashSizeT(hasher, a);
}

void hashSizeT(ref Hasher hasher, immutable size_t a) {
	hasher.mix(a);
}

void hashUbyte(ref Hasher hasher, immutable ubyte a) {
	hasher.mix(a);
}

void hashUshort(ref Hasher hasher, immutable ushort a) {
	hasher.mix(a);
}

void hashUint(ref Hasher hasher, immutable uint a) {
	hasher.mix(a);
}

void hashUlong(ref Hasher hasher, immutable ulong a) {
	hasher.mix(a);
}
