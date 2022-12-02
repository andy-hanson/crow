module util.hash;

@safe @nogc pure nothrow:

struct Hasher {
	@safe @nogc pure nothrow:

	private ulong value;

	ulong finish() =>
		value;

	private:

	void mix(ulong n) {
		value = value ^ n;
	}
}

void hashEnum(E)(ref Hasher hasher, E a) {
	hashSizeT(hasher, a);
}

void hashSizeT(ref Hasher hasher, size_t a) {
	hasher.mix(a);
}

void hashUbyte(ref Hasher hasher, ubyte a) {
	hasher.mix(a);
}

void hashUshort(ref Hasher hasher, ushort a) {
	hasher.mix(a);
}

void hashUint(ref Hasher hasher, uint a) {
	hasher.mix(a);
}

void hashUlong(ref Hasher hasher, ulong a) {
	hasher.mix(a);
}
