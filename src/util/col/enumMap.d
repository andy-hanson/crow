module util.col.enumMap;

@safe @nogc pure nothrow:

import std.meta : staticMap;
import std.traits : EnumMembers;
import util.opt : none, Opt, some;

struct EnumMap(E, V) {
	@safe @nogc pure nothrow:

	int opApply(in int delegate(immutable V) @safe @nogc pure nothrow cb) immutable {
		foreach (E e; cast(E) 0 .. cast(E) size) {
			int x = cb(this[e]);
			assert(x == 0);
		}
		return 0;
	}

	enum size = EnumMembers!E.length;
	static foreach (size_t i; 0 .. size)
		static assert(Members[i] == i);

	this(inout V[size] values) inout {
		static foreach (size_t i; 0 .. size)
			mixin("value", i, " = values[", i, "];");
	}

	ref inout(V) opIndex(E key) inout {
		final switch (key) {
			static foreach (size_t i; 0 .. size)
				case cast(E) i:
					mixin("return value", i, ";");
		}
	}

	private:
	alias Members = EnumMembers!E;
	// Using an array caused errors where it tried to call '_memset16'
	static foreach (size_t i; 0 .. size) {
		mixin("V value", i, ";");
	}
}

EnumMap!(E, V) makeEnumMap(E, V)(in V delegate(E) @safe @nogc pure nothrow cb) {
	V getAt(E e)() => cb(e);
	return EnumMap!(E, V)([staticMap!(getAt, EnumMembers!E)]);
}

void enumMapEach(E, V)(in EnumMap!(E, V) a, in void delegate(E, in V) @safe @nogc pure nothrow cb) {
	foreach (E e; cast(E) 0 .. cast(E) a.size)
		cb(e, a[e]);
}

Opt!E enumMapFindKey(E, V)(in EnumMap!(E, V) a, in bool delegate(in V) @safe @nogc pure nothrow cb) {
	foreach (E e; cast(E) 0 .. cast(E) a.size) {
		if (cb(a[e]))
			return some(e);
	}
	return none!E;
}

@trusted EnumMap!(E, VOut) enumMapMapValues(E, VOut, VIn)(
	in EnumMap!(E, VIn) a,
	in VOut delegate(in VIn) @safe @nogc pure nothrow cb,
) =>
	makeEnumMap!(E, VOut)((E e) =>
		cb(a[e]));
