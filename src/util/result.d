module util.result;

@safe @nogc pure nothrow:

import util.bools : Bool, False, True;

struct Result(Success, Failure) {
	@safe @nogc pure nothrow:
	private:
	immutable Bool isSuccess_;
	union {
		immutable Success success_;
		immutable Failure failure_;
	}

	this(immutable Success a) { isSuccess_ = True; success_ = a; }
	this(immutable Failure a) { isSuccess_ = False; failure_ = a; }
}

immutable(Result!(S, F)) success(S, F)(immutable S s) {
	return Result!(S, F)(s);
}

immutable(Result!(S, F)) fail(S, F)(immutable F f) {
	return Result!(S, F)(f);
}


immutable(Bool) isSuccess(S, F)(ref immutable Result!(S, F) a) {
	return a.isSuccess_;
}

ref immutable(S) asSuccess(S, F)(ref immutable Result!(S, F) a) {
	assert(a.isSuccess_);
	return a.success_;
}

ref immutable(F) asFailure(S, F)(ref immutable Result!(S, F) a) {
	assert(!a.isSuccess_);
	return a.failure_;
}

T match(T, S, F)(
	ref immutable Result!(S, F) a,
	scope Out delegate(ref immutable S) @safe @nogc pure nothrow cbSuccess,
	scope Out delegate(ref immutable F) @safe @nogc pure nothrow cbFailure,
) {
	return a.isSuccess_
		? cbSuccess(a.success_)
		: cbFailure(a.failure_);
}
