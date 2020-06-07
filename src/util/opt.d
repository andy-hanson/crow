module util.opt;

@safe @nogc pure nothrow:

import util.bools : Bool, False, True;
import util.comparison : Comparison;

struct Opt(T) {
	static assert(__traits(isPOD, T)); // TODO: handling types with destructors

	private:
	immutable Bool has_;
	T value_ = void;
}

immutable(Opt!T) none(T)() {
	return Opt!T(False);
}

immutable(Opt!T) some(T)(immutable T value) {
	return immutable Opt!T(True, value);
}

immutable(Bool) has(T)(immutable ref Opt!T a) {
	return a.has_;
}

ref immutable(T) force(T)(immutable ref Opt!T a) {
	assert(a.has);
	return a.value_;
}

immutable(Out) match(Out, T)(
	immutable Opt!T a,
	scope Out delegate(ref immutable T) @safe @nogc pure nothrow cbSome,
	scope Out delegate() @safe @nogc pure nothrow cbNone,
) {
	return a.has ? cbSome(a.force) : cbNone();
}

immutable(T) optOr(T)(immutable Opt!T a, scope T delegate() @safe @nogc pure nothrow cb) {
	return a.match((immutable T t) => t, cb);
}

immutable(Opt!Out) mapOption(Out, T)(
	immutable Opt!T a,
	scope Out delegate(immutable T) @safe @nogc pure nothrow cb,
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
