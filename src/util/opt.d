module util.opt;

@safe @nogc pure nothrow:

import util.bools : Bool, False, True;
import util.comparison : Comparison;
import util.ptr : Ptr, ptrTrustMe;

struct Opt(T) {
	static assert(__traits(isPOD, T)); // TODO: handling types with destructors

	private:
	this(BeNone) {
		has_ = False;
	}
	this(BeNone) const {
		has_ = False;
	}
	this(BeNone) immutable {
		has_ = False;
	}
	@trusted this(T value) {
		has_ = True;
		value_ = value;
	}
	@trusted this(const T value) const {
		has_ = True;
		value_ = value;
	}
	@trusted this(immutable T value) immutable {
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

immutable(Bool) has(T)(const Opt!T a) {
	return a.has_;
}

@trusted ref T force(T)(ref Opt!T a) {
	assert(has(a));
	return a.value_;
}
@trusted ref const(T) force(T)(ref const Opt!T a) {
	assert(has(a));
	return a.value_;
}
@trusted ref immutable(T) force(T)(ref immutable Opt!T a) {
	assert(has(a));
	return a.value_;
}

@trusted immutable(Ptr!T) forcePtr(T)(immutable Ptr!(Opt!T) a) {
	assert(has(a));
	return ptrTrustMe(a.value_);
}

ref immutable(T) forceOrTodo(T)(ref immutable Opt!T a) {
	if (has(a))
		return force(a);
	else
		assert(0); // TODO
}

immutable(Out) matchOpt(Out, T)(
	immutable Opt!T a,
	scope immutable(Out) delegate(ref immutable T) @safe @nogc pure nothrow cbSome,
	scope immutable(Out) delegate() @safe @nogc pure nothrow cbNone,
) {
	if (has(a))
		return cbSome(force(a));
	else
		return cbNone();
}

immutable(T) optOr(T)(immutable Opt!T a, scope immutable(T) delegate() @safe @nogc pure nothrow cb) {
	return matchOpt(a, (ref immutable T t) => t, cb);
}

immutable(Opt!Out) mapOption(Out, T)(
	immutable Opt!T a,
	scope immutable(Out) delegate(ref immutable T) @safe @nogc pure nothrow cb,
) {
	return has(a) ? some!Out(cb(force(a))) : none!Out;
}

immutable(Opt!Out) mapOption_const(Out, T)(
	const Opt!T a,
	scope immutable(Out) delegate(ref const T) @safe @nogc pure nothrow cb,
) {
	return has(a) ? someConst!Out(cb(force(a))) : noneConst!Out;
}

immutable(Opt!Out) flatMapOption(Out, T)(
	immutable Opt!T a,
	scope immutable(Opt!Out) delegate(ref immutable T) @safe @nogc pure nothrow cb,
) {
	return has(a) ? cb(force(a)) : none!Out;
}

immutable(Comparison) compareOpt(T)(
	ref immutable Opt!T a,
	ref immutable Opt!T b,
	scope Comparison delegate(ref immutable T, ref immutable T) @safe @nogc pure nothrow compare,
) {
	// none < some
	return matchOpt!(Comparison, T)(
		a,
		(ref immutable T ta) =>
			matchOpt!(Comparison, T)(
				b,
				(ref immutable T tb) => compare(ta, tb),
				() => Comparison.greater),
		() =>
			has(b) ? Comparison.less : Comparison.equal);
}
