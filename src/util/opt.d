module util.opt;

@safe @nogc pure nothrow:

import util.util : verify;

struct Opt(T) {
	@safe @nogc pure nothrow:

	private:
	static if (is(T == U*, U)) {
		this(BeNone) inout {
			value_ = null;
		}
		@trusted this(return scope inout T value) inout {
			value_ = value;
		}
		T value_;

		immutable(bool) has_() scope const =>
			value_ != null;
	} else {
		this(BeNone) inout {
			has_ = false;
		}
		@trusted this(return scope inout T value) inout {
			has_ = true;
			value_ = value;
		}
		bool has_;
		T value_ = void;
	}

	@disable immutable(bool) opEquals(scope const Opt!T b) scope const;
}

private struct BeNone {}

immutable(Opt!T) none(T)() =>
	immutable Opt!T(BeNone());

// Trick to allow 'none' to be 'inout' in safe code.
@trusted inout(Opt!T) noneInout(T, U)(ref inout U) =>
	cast(inout(Opt!T)) none!T;

Opt!T noneMut(T)() =>
	Opt!T(BeNone());

auto some(T)(inout T value) {
	static if (is(T == enum)) {
		return immutable Opt!T(value);
	} else {
		return inout Opt!T(value);
	}
}

immutable(bool) has(T)(in Opt!T a) =>
	a.has_;

@trusted ref inout(T) force(T)(ref inout Opt!T a) {
	verify!"force"(has(a));
	return a.value_;
}
