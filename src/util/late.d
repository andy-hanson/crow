module util.late;

@safe @nogc pure nothrow:

import util.bools : False, Bool, True;
import util.memory : initMemory;
import util.util : verify;

struct Late(T) {
	private:
	Bool isSet_ = False;
	T value_ = void;
}

@trusted Late!T late(T)() {
	return Late!T();
}

immutable(Bool) lateIsSet(T)(ref const Late!T a) {
	return a.isSet_;
}

@trusted ref immutable(T) lateGet(T)(ref immutable Late!T a) {
	verify(lateIsSet(a));
	return a.value_;
}

@trusted ref const(T) lateGet(T)(ref const Late!T a) {
	verify(lateIsSet(a));
	return a.value_;
}

@trusted void lateSet(T)(ref Late!T a, immutable T value) {
	verify(!lateIsSet(a));
	initMemory(&a.value_, value);
	a.isSet_ = True;
}

@trusted void lateSetOverwrite(T)(ref Late!T a, T value) {
	verify(lateIsSet(a));
	initMemory(&a.value_, value);
	a.isSet_ = True;
}

ref const(T) lazilySet(T)(ref Late!T a, scope T delegate() @safe @nogc pure nothrow cb) {
	if (!lateIsSet(a))
		lateSet!T(a, cb());
	return lateGet!T(a);
}
