module util.bitUtils;

@safe @nogc pure nothrow:

import util.bools : Bool, not;
import util.types : u64;

immutable(u64) singleBit(immutable u64 bitIndex) {
	return u64(1) << bitIndex;
}

immutable(Bool) bitsOverlap(immutable u64 a, immutable u64 b) {
	return Bool((a & b) != 0);
}

// Tests if 'a' has *all* bits from 'b' set
immutable(Bool) allBitsSet(immutable u64 a, immutable u64 b) {
	return Bool((a & b) == b);
}

immutable(Bool) getBit(immutable u64 n, immutable u64 bitIndex) {
	return bitsOverlap(n, singleBit(bitIndex));
}

immutable(u64) setBit(immutable u64 n, immutable u64 bitIndex) {
	return n | singleBit(bitIndex);
}


// Bits are counted such that the rightmost bit is bit 0. (Since it is the 2^0th place)
immutable(u64) getBitsUnshifted(immutable u64 n, immutable u64 firstBitIndex, immutable u64 nBits) {
	u64 mask = 0;
	foreach (immutable size_t i; firstBitIndex..firstBitIndex + nBits)
		mask = setBit(mask, i);
	immutable u64 res = n & mask;
	foreach (immutable size_t i; 0..firstBitIndex)
		assert(getBit(res, i).not);
	foreach (immutable size_t i; firstBitIndex + nBits..64)
		assert(getBit(res, i).not);
	return res;
}

immutable(u64) getBitsShifted(immutable u64 n, immutable u64 firstBitIndex, immutable u64 nBits) {
	immutable u64 res = getBitsUnshifted(n, firstBitIndex, nBits) >> firstBitIndex;
	foreach (immutable size_t i; nBits..64)
		assert(getBit(res, i).not);
	return res;
}
