module util.late;

@safe @nogc pure nothrow:

import util.memory : initMemory;
import util.opt : force, has, Opt, some;
import util.ptr : castNonScope_ref;
import util.util : verify;

immutable struct Late(T) {
	private Opt!T value_;
}

@trusted Late!T late(T)() =>
	Late!T();

@trusted Late!T late(T)(T value) =>
	Late!T(some(value));

bool lateIsSet(T)(ref Late!T a) =>
	has(a.value_);

@trusted ref immutable(T) lateGet(T)(return scope ref Late!T a) {
	verify(lateIsSet(a));
	// TODO: castNonScope_ref not needed in newer dmd
	return force(castNonScope_ref(a.value_));
}

@trusted void lateSet(T)(ref Late!T a, T value) {
	verify(!lateIsSet(a));
	initMemory(&a.value_, some(value));
}

// TODO: we shouldn't do this
@trusted void lateSetOverwrite(T)(ref Late!T a, T value) {
	verify(lateIsSet(a));
	initMemory(&a.value_, some(value));
}

ref immutable(T) lazilySet(T)(ref Late!T a, in immutable(T) delegate() @safe @nogc pure nothrow cb) {
	if (!lateIsSet(a))
		lateSet!T(a, cb());
	return lateGet!T(a);
}
