module util.opt;

@safe @nogc pure nothrow:

import util.col.array : SmallArray;

private struct Option(T) {
	@safe @nogc pure nothrow:

	private:
	static if (is(T == U*, U)) {
		inout this(return scope inout T value) {
			value_ = value;
		}
		T value_ = null;
		bool has_() scope const =>
			value_ != null;
	} else static if (is(T == SmallArray!U, U)) {
		inout this(return scope inout T value) {
			value_ = value;
			assert(has_);
		}

		T value_ = T.fromTagged(1); // = none
		bool has_() scope const =>
			(value_.asTaggable & 1) == 0;
		static assert(!this.init.has);
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
alias ConstOpt(T) = const Option!T;
alias MutOpt(T) = Option!T;

Opt!T none(T)() =>
	Opt!T();

MutOpt!T noneMut(T)() =>
	MutOpt!T();

Opt!T some(T)(immutable T value) =>
	Opt!T(value);

ConstOpt!T someConst(T)(const T value) =>
	ConstOpt!T(value);

inout(Option!T) someInout(T)(inout T value) =>
	inout Option!T(value);

MutOpt!T someMut(T)(T value) =>
	MutOpt!T(value);

bool has(T)(in Option!T a) =>
	a.has_;

ref inout(T) force(T)(ref inout Option!T a) {
	assert(has(a));
	return a.value_;
}

Opt!T optIf(T)(bool b, in T delegate() @safe @nogc pure nothrow cb) =>
	b ? some(cb()) : none!T;

Opt!T optOr(T)(Opt!T a, in Opt!T delegate() @safe @nogc pure nothrow cb) =>
	has(a) ? a : cb();

Opt!T optOr(T)(
	Opt!T a,
	in Opt!T delegate() @safe @nogc pure nothrow b,
	in Opt!T delegate() @safe @nogc pure nothrow c,
) =>
	optOr!T(optOr!T(a, b), c);

Opt!T optOr(T)(
	Opt!T a,
	in Opt!T delegate() @safe @nogc pure nothrow b,
	in Opt!T delegate() @safe @nogc pure nothrow c,
	in Opt!T delegate() @safe @nogc pure nothrow d,
) =>
	optOr!T(optOr!T(a, b), c, d);

Opt!T optOr(T)(
	Opt!T a,
	in Opt!T delegate() @safe @nogc pure nothrow b,
	in Opt!T delegate() @safe @nogc pure nothrow c,
	in Opt!T delegate() @safe @nogc pure nothrow d,
	in Opt!T delegate() @safe @nogc pure nothrow e,
) =>
	optOr!T(optOr!T(a, b), c, d, e);

Opt!T optOr(T)(
	Opt!T a,
	in Opt!T delegate() @safe @nogc pure nothrow b,
	in Opt!T delegate() @safe @nogc pure nothrow c,
	in Opt!T delegate() @safe @nogc pure nothrow d,
	in Opt!T delegate() @safe @nogc pure nothrow e,
	in Opt!T delegate() @safe @nogc pure nothrow f,
) =>
	optOr!T(optOr!T(a, b), c, d, e, f);

T optOrDefault(T)(Opt!T a, in T delegate() @safe @nogc pure nothrow cb) =>
	has(a)
		? force(a)
		: cb();

bool optEqual(T)(in ConstOpt!T a, in ConstOpt!T b) =>
	has(a)
		? has(b) && force(a) == force(b)
		: !has(b);
