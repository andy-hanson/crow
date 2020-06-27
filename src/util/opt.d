module util.opt;

@safe @nogc pure nothrow:

import util.bools : Bool, False, True;
import util.comparison : Comparison;

struct Opt(T) {
	static assert(__traits(isPOD, T)); // TODO: handling types with destructors

	private:
	this(BeNone) immutable {
		has_ = False;
	}
	this(immutable T value) immutable {
		has_ = True;
		value_ = value;
	}
	this(inout T value) inout {
		has_ = True;
		value_ = value;
	}
	Bool has_;
	T value_ = void;
}

private struct BeNone {}

immutable(Opt!T) none(T)() {
	return immutable Opt!T(BeNone());
}

immutable(Opt!T) some(T)(immutable T value) {
	return immutable Opt!T(value);
}

immutable(Bool) has(T)(const Opt!T a) {
	return a.has_;
}

ref immutable(T) force(T)(immutable ref Opt!T a) {
	assert(a.has);
	return a.value_;
}

immutable(Out) match(Out, T)(
	immutable Opt!T a,
	scope immutable(Out) delegate(ref immutable T) @safe @nogc pure nothrow cbSome,
	scope immutable(Out) delegate() @safe @nogc pure nothrow cbNone,
) {
	if (a.has)
		return cbSome(a.force);
	else
		return cbNone();
}

immutable(T) optOr(T)(immutable Opt!T a, scope immutable(T) delegate() @safe @nogc pure nothrow cb) {
	return a.match!(T, T)((ref immutable T t) => t, cb);
}

immutable(Opt!Out) mapOption(Out, T)(
	immutable Opt!T a,
	scope immutable(Out) delegate(ref immutable T) @safe @nogc pure nothrow cb,
) {
	return a.has ? some!Out(cb(a.force)) :none!Out;
}

immutable(Comparison) compareOpt(T)(
	ref immutable Opt!T a,
	ref immutable Opt!T b,
	scope Comparison delegate(ref immutable T, ref immutable T) @safe @nogc pure nothrow compare,
) {
	// none < some
	return a.match!(Comparison, T)(
		(ref immutable T ta) =>
			b.match!(Comparison, T)(
				(ref immutable T tb) => compare(ta, tb),
				() => Comparison.greater),
		() => Comparison.less);
}
