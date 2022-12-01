module util.col.enumDict;

@safe @nogc pure nothrow:

import std.meta : staticMap;
import std.traits : EnumMembers;
import util.opt : none, Opt, some;
import util.util : verify;

struct EnumDict(E, V) {
	@safe @nogc nothrow:

	int opApply(scope int delegate(immutable V) @safe @nogc nothrow cb) immutable {
		foreach (immutable E e; cast(immutable E) 0 .. cast(immutable E) size) {
			immutable int x = cb(this[e]);
			verify(x == 0);
		}
		return 0;
	}

	pure:

	enum size = EnumMembers!E.length;
	static foreach (immutable size_t i; 0 .. size)
		static assert(Members[i] == i);

	immutable this(immutable V[size] values) {
		static foreach (immutable size_t i; 0 .. size)
			mixin("value", i, " = values[", i, "];");
	}

	ref inout(V) opIndex(immutable E key) inout {
		final switch (key) {
			static foreach (immutable size_t i; 0 .. size)
				case cast(immutable E) i:
					mixin("return value", i, ";");
		}
	}

	private:
	alias Members = EnumMembers!E;
	// Using an array caused errors where it tried to call '_memset16'
	static foreach (immutable size_t i; 0 .. size) {
		mixin("V value", i, ";");
	}
}

immutable(EnumDict!(E, V)) makeEnumDict(E, V)(
	scope immutable(V) delegate(immutable E) @safe @nogc pure nothrow cb,
) {
	immutable(V) getAt(immutable E e)() =>
		cb(e);
	return immutable EnumDict!(E, V)([staticMap!(getAt, EnumMembers!E)]);
}

void enumDictEach(E, V)(
	ref const EnumDict!(E, V) a,
	scope void delegate(immutable E, ref const V) @safe @nogc pure nothrow cb,
) {
	foreach (immutable E e; cast(immutable E) 0 .. cast(immutable E) a.size)
		cb(e, a[e]);
}

immutable(Opt!E) enumDictFindKey(E, V)(
	immutable EnumDict!(E, V) a,
	scope immutable(bool) delegate(ref immutable V) @safe @nogc pure nothrow cb,
) {
	foreach (immutable E e; cast(immutable E) 0 .. cast(immutable E) a.size) {
		if (cb(a[e]))
			return some(e);
	}
	return none!E;
}

@trusted immutable(EnumDict!(E, VOut)) enumDictMapValues(E, VOut, VIn)(
	immutable EnumDict!(E, VIn) a,
	scope immutable(VOut) delegate(ref immutable VIn) @safe @nogc pure nothrow cb,
) =>
	makeEnumDict!(E, VOut)((immutable E e) =>
		cb(a[e]));
