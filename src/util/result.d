module util.result;

@nogc nothrow @trusted immutable(Out) matchImpure(Out, S, F)(
	ref immutable Result!(S, F) a,
	scope immutable(Out) delegate(ref immutable S) @safe @nogc nothrow cbSuccess,
	scope immutable(Out) delegate(ref immutable F) @safe @nogc nothrow cbFailure,
) {
	return a.isSuccess_
		? cbSuccess(a.success_)
		: cbFailure(a.failure_);
}

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

	@trusted this(immutable Success a) { isSuccess_ = True; success_ = a; }
	@trusted this(immutable Failure a) { isSuccess_ = False; failure_ = a; }
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

@trusted ref immutable(S) asSuccess(S, F)(ref immutable Result!(S, F) a) {
	assert(a.isSuccess_);
	return a.success_;
}

@trusted ref immutable(F) asFailure(S, F)(ref immutable Result!(S, F) a) {
	assert(!a.isSuccess_);
	return a.failure_;
}

@trusted immutable(Out) match(Out, S, F)(
	ref immutable Result!(S, F) a,
	scope immutable(Out) delegate(ref immutable S) @safe @nogc pure nothrow cbSuccess,
	scope immutable(Out) delegate(ref immutable F) @safe @nogc pure nothrow cbFailure,
) {
	return a.isSuccess_
		? cbSuccess(a.success_)
		: cbFailure(a.failure_);
}

immutable(Result!(OutSuccess, Failure)) mapSuccess(OutSuccess, InSuccess, Failure)(
	ref immutable Result!(InSuccess, Failure) a,
	scope immutable(OutSuccess) delegate(ref immutable InSuccess) @safe @nogc pure nothrow cb,
) {
	return a.match!(immutable Result!(OutSuccess, Failure), InSuccess, Failure)(
		(ref immutable InSuccess s) => success!(OutSuccess, Failure)(cb(s)),
		(ref immutable Failure f) => fail!(OutSuccess, Failure)(f),
	);
}

immutable(Result!(Success, OutFailure)) mapFailure(OutFailure, Success, InFailure)(
	ref immutable Result!(Success, InFailure) a,
	scope immutable(OutFailure) delegate(ref immutable InFailure) @safe @nogc pure nothrow cb,
) {
	return a.match!(immutable Result!(Success, OutFailure), Success, InFailure)(
		(ref immutable Success s) => success!(Success, OutFailure)(s),
		(ref immutable InFailure f) => fail!(Success, OutFailure)(cb(f)),
	);
}

immutable(Result!(OutSuccess, Failure)) flatMapSuccess(OutSuccess, InSuccess, Failure)(
	ref immutable Result!(InSuccess, Failure) a,
	scope immutable(Result!(OutSuccess, Failure)) delegate(ref immutable InSuccess) @safe @nogc pure nothrow cb,
) {
	return a.match!(immutable Result!(OutSuccess, Failure), InSuccess, Failure)(
		cb,
		(ref immutable Failure f) => fail!(OutSuccess, Failure)(f),
	);
}

immutable(Result!(OutSuccess, Failure)) joinResults(OutSuccess, InSuccess0, InSuccess1, Failure)(
	ref immutable Result!(InSuccess0, Failure) r0,
	ref immutable Result!(InSuccess1, Failure) r1,
	scope immutable(OutSuccess) delegate(ref immutable InSuccess0, ref immutable InSuccess1) @safe @nogc pure nothrow cb,
) {
	return flatMapSuccess!(OutSuccess, InSuccess0, Failure)(r0, (ref immutable InSuccess0 success0) =>
		mapSuccess!(OutSuccess, InSuccess1, Failure)(r1, (ref immutable InSuccess1 success1) =>
			cb(success0, success1)));
}
