module util.types;

@safe @nogc pure nothrow:

import util.util : verify;

struct NatN(T) {
	immutable(NatN!T) opBinary(string op)(immutable NatN!T b) const {
		// Can't use '==' to compare strings due to https://github.com/ldc-developers/ldc/issues/3615
		static if (op.length == 1) {
			static if (op[0] == '+') {
				// TODO: this will fail to detect overflow for Nat64
				immutable size_t res = (cast(immutable size_t) value) + (cast(immutable size_t) b.value);
				verify(res <= T.max);
				return immutable NatN!T(cast(immutable T) res);
			} else static if (op[0] == '-') {
				verify(value >= b.value);
				return immutable NatN!T(cast(immutable T) (value - b.value));
			} else static if (op[0] == '*') {
				// TODO: this will fail to detect overflow for Nat64
				immutable size_t res = (cast(immutable size_t) value) * (cast(immutable size_t) b.value);
				verify(res <= T.max);
				return immutable NatN!T(cast(immutable T) res);
			} else static if (op[0] == '/') {
				verify(b.value != 0);
				return immutable NatN!T(value / b.value);
			} else static if (op[0] == '%') {
				verify(b.value != 0);
				return immutable NatN!T(value % b.value);
			} else static if (op[0] == '&') {
				return immutable NatN!T(value & b.value);
			} else static if (op[0] == '|') {
				return immutable NatN!T(value | b.value);
			} else
				static assert(0, "Operator "~op~" not implemented");
		} else static if (op.length == 2 && op[0] == '<' && op[1] == '<') {
			// TODO: this will fail to detect overflow for Nat64
			immutable size_t res = (cast(immutable size_t) value) << (cast(immutable size_t) b.value);
			verify(res <= T.max);
			return immutable NatN!T(cast(immutable T) res);
		} else static if (op.length == 2 && op[0] == '>' && op[1] == '>') {
			return immutable NatN!T(value >> b.value);
		} else
			static assert(0, "Operator "~op~" not implemented");
	}

	static immutable(NatN!T) max() {
		return immutable NatN!T(T.max);
	}

	immutable(T) raw() const {
		return value;
	}

	void opOpAssign(string op)(immutable NatN!T b) {
		value = opBinary!op(b).value;
	}
	void opOpAssign(string op)(immutable int b) {
		static if (op.length == 1 && op[0] == '+') {
			// TODO: detect overflow
			value = cast(immutable T) (value + b);
		} else static if (op.length == 1 && op[0] == '-') {
			// TODO: detect overflow
			value = cast(immutable T) (value - b);
		} else
			static assert(0, "Operator "~op~" not implemented");
	}

	immutable(bool) opEquals(immutable NatN!T b) const {
		return value == b.value;
	}

	immutable(int) opCmp(immutable NatN!T b) const {
		return value < b.value
			? -1
			: value > b.value
			? 1
			: 0;
	}

	static if (!is(T == ubyte)) {
		immutable(Nat8) to8() const {
			verify(value <= ubyte.max);
			return immutable Nat8(cast(immutable ubyte) value);
		}
	}

	static if (!is(T == ushort)) {
		immutable(Nat16) to16() const {
			verify(value <= ushort.max);
			return immutable Nat16(cast(immutable ushort) value);
		}
	}

	static if (!is(T == uint)) {
		immutable(Nat32) to32() const {
			verify(value <= uint.max);
			return immutable Nat32(cast(immutable uint) value);
		}
	}

	static if (!is(T == ulong)) {
		immutable(Nat64) to64() const {
			return immutable Nat64(value);
		}
	}

	static if (is(T == ulong)) {
		immutable(Nat48) to48() const {
			verify(value < (cast(ulong) 1) << 48);
			verify(bottomU16OfU64(value >> 48) == 0);
			return immutable Nat48(
				bottomU16OfU64(value >> 32),
				bottomU16OfU64(value >> 16),
				bottomU16OfU64(value));
		}
	}

	immutable(Int16) toInt16() const {
		verify(value <= short.max);
		return immutable Int16(cast(immutable short) value);
	}

	immutable(Int32) toInt32() const {
		verify(value <= int.max);
		return immutable Int32(cast(immutable int) value);
	}

	private:
	T value;
}

struct IntN(T) {
	@safe @nogc pure nothrow:

	immutable(IntN!T) opBinary(string op)(immutable IntN!T b) const {
		static if (op.length == 1 && op[0] == '-') {
			// TODO: check for overflow
			return immutable IntN!T(cast(immutable T) (value - b.value));
		} else {
			static assert(false);
		}
	}

	immutable(T) raw() const {
		return value;
	}

	//TODO:support more types
	static if(is(T == short)) {
		immutable(Nat16) unsigned() const {
			verify(value >= 0);
			return immutable Nat16(cast(immutable ushort) value);
		}
	}

	static if (!is(T == short)) {
		immutable(Int16) to16() const {
			verify(value >= short.min && value <= short.max);
			return immutable Int16(cast(immutable short) value);
		}
	}

	private:
	T value;
}

immutable(NatN!T) decr(T)(immutable NatN!T a) {
	return a - immutable NatN!T(1);
}

immutable(NatN!T) incr(T)(immutable NatN!T a) {
	return a + immutable NatN!T(1);
}
//TODO:KILL
immutable(size_t) incr(immutable size_t a) {
	return a + 1;
}

immutable(ubyte) safeIncrU8(immutable ubyte a) {
	verify(a != ubyte.max);
	return cast(ubyte) (a + 1);
}

immutable(bool) zero(T)(immutable NatN!T a) {
	return a.value == 0;
}
//TODO:KILL
immutable(bool) zero(immutable size_t a) {
	return a == 0;
}

struct Nat48 {
	@safe @nogc pure nothrow:

	static immutable(Nat48) max() {
		return immutable Nat48(0xffff, 0xffff, 0xffff);
	}

	immutable ushort a;
	immutable ushort b;
	immutable ushort c;

	immutable(Nat64) to64() immutable {
		return immutable Nat64(((cast(ulong) a) << 32) | ((cast(ulong) b) << 16) | (cast(ulong) c));
	}
}

alias Nat8 = NatN!ubyte;
alias Nat16 = NatN!ushort;
alias Nat32 = NatN!uint;
alias Nat64 = NatN!ulong;
alias Int16 = IntN!short;
private alias Int32 = IntN!int;
alias Int64 = IntN!long;

immutable(ubyte) bottomU8OfU64(immutable ulong u) {
	return cast(immutable ubyte) u;
}

immutable(ushort) bottomU16OfU64(immutable ulong u) {
	return cast(immutable ushort) u;
}

immutable(uint) bottomU32OfU64(immutable ulong u) {
	return cast(immutable uint) u;
}

immutable(int) safeI32FromU32(immutable uint u) {
	verify(u <= int.max);
	return cast(immutable int) u;
}

immutable(ushort) safeU32ToU16(immutable uint u) {
	verify(u <= ushort.max);
	return cast(immutable ushort) u;
}

immutable(ushort) safeSizeTToU16(immutable size_t s) {
	verify(s <= ushort.max);
	return cast(immutable ushort) s;
}

immutable(uint) safeSizeTToU32(immutable size_t s) {
	verify(s <= uint.max);
	return cast(immutable uint) s;
}

immutable(int) safeIntFromSizeT(immutable size_t s) {
	verify(s <= int.max);
	return cast(immutable int) s;
}

immutable(int) safeIntFromNat64(immutable Nat64 a) {
	verify(a.value <= int.max);
	return cast(immutable int) a.value;
}

immutable(ubyte) safeSizeTToU8(immutable size_t s) {
	verify(s <= 255);
	return cast(immutable ubyte) s;
}

immutable(uint) safeU32FromI64(immutable long a) {
	verify(a >= 0 && a <= uint.max);
	return cast(immutable uint) a;
}

immutable(uint) safeU32FromI32(immutable int a) {
	return safeU32FromI64(a);
}

immutable(ulong) safeUlongFromLong(immutable long s) {
	verify(s >= 0);
	return cast(immutable ulong) s;
}

immutable(size_t) safeSizeTFromU64(immutable ulong a) {
	verify(a <= size_t.max);
	return cast(immutable size_t) a;
}

immutable(ulong) abs(immutable long a) {
	return a < 0 ? -a : a;
}
immutable(double) abs(immutable double a) {
	return a < 0 ? -a : a;
}

immutable(Nat32) u32OfFloat32Bits(immutable float value) {
	Converter32 conv;
	conv.asFloat32 = value;
	return immutable Nat32(conv.asU32);
}

immutable(Nat64) u64OfFloat32Bits(immutable float value) {
	return u32OfFloat32Bits(value).to64();
}

immutable(float) float32OfU32Bits(immutable uint value) {
	Converter32 conv;
	conv.asU32 = value;
	return conv.asFloat32;
}

immutable(float) float32OfU64Bits(immutable ulong value) {
	return float32OfU32Bits(cast(uint) value);
}

immutable(uint) u32OfI32Bits(immutable int value) {
	Converter32 conv;
	conv.asI32 = value;
	return conv.asU32;
}

immutable(Nat64) u64OfFloat64Bits(immutable double value) {
	Converter64 conv;
	conv.asFloat64 = value;
	return immutable Nat64(conv.asU64);
}

immutable(double) float64OfU64Bits(immutable ulong value) {
	Converter64 conv;
	conv.asU64 = value;
	return conv.asFloat64;
}

immutable(int) i32OfU64Bits(immutable ulong value) {
	Converter32 conv;
	conv.asU32 = cast(uint) value;
	return conv.asI32;
}

immutable(long) i64OfU64Bits(immutable ulong value) {
	Converter64 conv;
	conv.asU64 = value;
	return conv.asI64;
}

private:

union Converter32 {
	int asI32;
	uint asU32;
	float asFloat32;
}

union Converter64 {
	ulong asU64;
	long asI64;
	double asFloat64;
}
