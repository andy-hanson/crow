module util.opt;

@safe @nogc pure nothrow:

import util.util : verify;

struct Opt(T) {
	@safe @nogc pure nothrow:

	private:
	static if (is(T == U*, U)) {
		this(BeNone) immutable {
			value_ = null;
		}
		this(BeNone) const {
			value_ = null;
		}
		this(BeNone) {
			value_ = null;
		}
		@trusted this(return scope immutable T value) immutable {
			value_ = value;
		}
		@trusted this(return scope const T value) const {
			value_ = value;
		}
		@trusted this(return scope T value) {
			value_ = value;
		}
		T value_;

		immutable(bool) has_() const {
			return value_ != null;
		}
	} else {
		this(BeNone) immutable {
			has_ = false;
		}
		this(BeNone) const {
			has_ = false;
		}
		this(BeNone) {
			has_ = false;
		}
		@trusted this(return scope immutable T value) immutable {
			has_ = true;
			value_ = value;
		}
		@trusted this(return scope const T value) const {
			has_ = true;
			value_ = value;
		}
		@trusted this(return scope T value) {
			has_ = true;
			value_ = value;
		}
		bool has_;
		T value_ = void;
	}

	@disable immutable(bool) opEquals(scope const Opt!T b) scope const;
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

immutable(Opt!T) some(T)(immutable T value) if (!is(T == U*, U)) {
	return immutable Opt!T(value);
}
immutable(Opt!(T*)) some(T)(immutable T* value) {
	return immutable Opt!(T*)(value);
}

const(Opt!T) someConst(T)(return scope const T value) {
	return const Opt!T(value);
}

Opt!T someMut(T)(T value) {
	return Opt!T(value);
}

immutable(bool) has(T)(ref const Opt!T a) {
	return a.has_;
}

@trusted ref T force(T)(ref Opt!T a) {
	verify!"force"(has(a));
	return a.value_;
}
@trusted ref const(T) force(T)(ref const Opt!T a) {
	verify!"force"(has(a));
	return a.value_;
}
@trusted ref immutable(T) force(T)(ref immutable Opt!T a) {
	verify!"force"(has(a));
	return a.value_;
}
