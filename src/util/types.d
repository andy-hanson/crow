module util.types;

@safe @nogc pure nothrow:

import util.bools : Bool;
import util.util : verify;

alias u8 = ubyte;
alias u16 = ushort;
alias u32 = uint;
alias u64 = ulong;

alias i8 = byte;
alias i16 = short;
alias i32 = int;
alias i64 = long;

alias float64 = double;

alias ssize_t = long;

struct NatN(T) {
	immutable(NatN!T) opBinary(string op)(immutable NatN!T b) const {
		static if (op == "+") {
			// TODO: this will fail to detect overflow for Nat64
			immutable size_t res = (cast(immutable size_t) value) + (cast(immutable size_t) b.value);
			verify(res <= T.max);
			return immutable NatN!T(cast(immutable T) res);
		} else static if (op == "-") {
			verify(value >= b.value);
			return immutable NatN!T(cast(immutable T) (value - b.value));
		} else static if (op == "*") {
			// TODO: this will fail to detect overflow for Nat64
			immutable size_t res = (cast(immutable size_t) value) * (cast(immutable size_t) b.value);
			verify(res <= T.max);
			return immutable NatN!T(cast(immutable T) res);
		} else static if (op == "/") {
			verify(b.value != 0);
			return immutable NatN!T(value / b.value);
		} else static if (op == "%") {
			verify(b.value != 0);
			return immutable NatN!T(value % b.value);
		} else static if (op == "&") {
			return immutable NatN!T(value & b.value);
		} else static if (op == "|") {
			return immutable NatN!T(value | b.value);
		} else static if (op == "<<") {
			// TODO: this will fail to detect overflow for Nat64
			immutable size_t res = (cast(immutable size_t) value) << (cast(immutable size_t) b.value);
			verify(res <= T.max);
			return immutable NatN!T(cast(immutable T) res);
		} else static if (op == ">>") {
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
		static if (op == "+") {
			// TODO: detect overflow
			value = cast(immutable T) (value + b);
		} else static if (op == "-") {
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
		static if (op == "-") {
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

immutable(Bool) zero(T)(immutable NatN!T a) {
	return immutable Bool(a.value == 0);
}
//TODO:KILL
immutable(Bool) zero(immutable size_t a) {
	return immutable Bool(a == 0);
}

alias Nat8 = NatN!ubyte;
alias Nat16 = NatN!ushort;
alias Nat32 = NatN!uint;
alias Nat64 = NatN!ulong;
alias Int16 = IntN!short;
private alias Int32 = IntN!int;

immutable(u8) bottomU8OfU64(immutable u64 u) {
	return cast(u8) u;
}

immutable(u16) bottomU16OfU64(immutable u64 u) {
	return cast(u16) u;
}

immutable(u32) bottomU32OfU64(immutable u64 u) {
	return cast(u32) u;
}

immutable(i32) safeI32FromU32(immutable u32 u) {
	verify(u <= i32.max);
	return cast(i32) u;
}

immutable(u16) safeU32ToU16(immutable u32 u) {
	verify(u <= u16.max);
	return cast(u16) u;
}

immutable(u16) safeSizeTToU16(immutable size_t s) {
	verify(s <= u16.max);
	return cast(u16) s;
}

immutable(u32) safeSizeTToU32(immutable size_t s) {
	verify(s <= u32.max);
	return cast(u32) s;
}

immutable(int) safeIntFromSizeT(immutable size_t s) {
	verify(s <= int.max);
	return cast(int) s;
}

immutable(int) safeIntFromNat64(immutable Nat64 a) {
	verify(a.value <= int.max);
	return cast(int) a.value;
}

immutable(u8) safeSizeTToU8(immutable size_t s) {
	verify(s <= 255);
	return cast(u8) s;
}

immutable(size_t) safeSizeTFromSSizeT(immutable ssize_t s) {
	verify(s >= 0);
	return cast(size_t) s;
}

immutable(size_t) abs(immutable ssize_t s) {
	return s < 0 ? -s : s;
}

private immutable u8 maxU4 = 0xf;

immutable(Nat8) catU4U4(immutable Nat8 a, immutable Nat8 b) {
	verify(a.value <= maxU4);
	verify(b.value <= maxU4);
	return (a << immutable Nat8(4)) | b;
}

struct U4U4 {
	immutable Nat8 a;
	immutable Nat8 b;
}

immutable(U4U4) u4u4OfU8(immutable Nat8 a) {
	return immutable U4U4(immutable Nat8(a.raw() >> 4), immutable Nat8(a.raw() & maxU4));
}

immutable(Nat64) u64OfFloat64Bits(immutable float64 value) {
	Converter64 conv;
	conv.asFloat64 = value;
	return conv.asU64;
}

immutable(float64) float64OfU64Bits(immutable u64 value) {
	Converter64 conv;
	conv.asU64 = immutable Nat64(value);
	return conv.asFloat64;
}

private:

union Converter64 {
	Nat64 asU64;
	float64 asFloat64;
}
