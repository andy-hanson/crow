module util.opt;

@safe @nogc pure nothrow:

import util.ptr : Ptr, ptrTrustMe;
import util.util : verify;

struct Opt(T) {
	private:
	this(BeNone) {
		has_ = false;
	}
	this(BeNone) const {
		has_ = false;
	}
	this(BeNone) immutable {
		has_ = false;
	}
	@trusted this(T value) {
		has_ = true;
		value_ = value;
	}
	@trusted this(const T value) const {
		has_ = true;
		value_ = value;
	}
	@trusted this(immutable T value) immutable {
		has_ = true;
		value_ = value;
	}
	bool has_;
	T value_ = void;
}

private struct BeNone {}

immutable(Opt!T) none(T)() {
	return immutable Opt!T(BeNone());
}

immutable(Opt!T) asImmutable(T)(immutable Opt!(immutable T) a) {
	return has(a) ? some(force(a)) : none!T;
}

const(Opt!T) noneConst(T)() {
	return const Opt!T(BeNone());
}

Opt!T noneMut(T)() {
	return Opt!T(BeNone());
}

immutable(Opt!T) some(T)(immutable T value) {
	return immutable Opt!T(value);
}

const(Opt!T) someConst(T)(const T value) {
	return const Opt!T(value);
}

Opt!T someMut(T)(T value) {
	return Opt!T(value);
}

immutable(bool) has(T)(const Opt!T a) {
	return a.has_;
}

@trusted ref T force(T)(ref Opt!T a) {
	verify(has(a));
	return a.value_;
}
@trusted ref const(T) force(T)(ref const Opt!T a) {
	verify(has(a));
	return a.value_;
}
@trusted ref immutable(T) force(T)(ref immutable Opt!T a) {
	verify(has(a));
	return a.value_;
}

@trusted immutable(Ptr!T) forcePtr(T)(immutable Ptr!(Opt!T) a) {
	verify(has(a));
	return ptrTrustMe(a.value_);
}

ref immutable(T) forceOrTodo(T)(return scope ref immutable Opt!T a) {
	if (has(a))
		return force(a);
	else
		assert(0);
}

immutable(T) optOr(T)(immutable Opt!T a, scope immutable(T) delegate() @safe @nogc pure nothrow cb) {
	return has(a) ? force(a) : cb();
}

immutable(Opt!T) optOr2(T)(immutable Opt!T a, scope immutable(Opt!T) delegate() @safe @nogc pure nothrow cb) {
	return has(a) ? a : cb();
}

immutable(Opt!Out) mapOption(Out, T)(
	immutable Opt!T a,
	scope immutable(Out) delegate(ref immutable T) @safe @nogc pure nothrow cb,
) {
	return has(a) ? some!Out(cb(force(a))) : none!Out;
}
