module util.opt;

@safe @nogc pure nothrow:

import util.util : verify;

private struct Option(T) {
	@safe @nogc pure nothrow:

	private:
	static if (is(T == U*, U)) {
		inout this(return scope inout T value) {
			value_ = value;
		}
		T value_;
		bool has_() scope const =>
			value_ != null;
	} else {
		inout this(return scope inout T value) {
			has_ = true;
			value_ = value;
		}
		bool has_;
		T value_ = void;
	}

	@disable bool opEquals(scope const Opt!T b) scope const;
}

alias Opt(T) = immutable Option!(immutable T);
alias MutOpt(T) = Option!T;

Opt!T none(T)() =>
	Opt!T();

MutOpt!T noneMut(T)() =>
	MutOpt!T();

Opt!T some(T)(immutable T value) =>
	Opt!T(value);

MutOpt!T someMut(T)(T value) =>
	MutOpt!T(value);

bool has(T)(in Option!T a) =>
	a.has_;

ref inout(T) force(T)(ref inout Option!T a) {
	verify(has(a));
	return a.value_;
}
