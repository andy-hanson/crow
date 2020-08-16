module util.late;

@safe @nogc pure nothrow:

import util.bools : False, Bool, True;
import util.memory : initMemory;

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
	assert(a.lateIsSet);
	return a.value_;
}

@trusted ref const(T) lateGet(T)(ref const Late!T a) {
	assert(a.lateIsSet);
	return a.value_;
}

@trusted void lateSet(T)(ref Late!T a, T value) {
	assert(!a.lateIsSet);
	initMemory(&a.value_, value);
	a.isSet_ = True;
}

ref const(T) lazilySet(T)(ref Late!T a, scope T delegate() @safe @nogc pure nothrow cb) {
	if (!a.lateIsSet)
		a.lateSet(value);
	return a.lateGet;
}

