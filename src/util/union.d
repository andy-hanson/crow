module util.union_;

@safe @nogc nothrow: // not pure

import std.meta : staticMap;
import util.col.arr : SmallArray;

mixin template Union(Types...) {
	@safe @nogc nothrow:

	import util.col.arr : SmallArray;
	import util.union_ : canUseTaggedPointer, isEmptyStruct, isIn, toHandlers, toHandlersImpure;

	@trusted R matchImpure(R)(scope toHandlersImpure!(R, Types) handlers) immutable {
		static foreach (i, T; Types) {
			if (kind == i) {
				static if (usesTaggedPointer) {
					static if (isEmptyStruct!T)
						return handlers[i](immutable T());
					else static if (is(T == SmallArray!U, U))
						return handlers[i](SmallArray!U.decode(ptrValue));
					else static if (is(T == P*, P))
						return handlers[i](*(cast(immutable P*) ptrValue));
					else
						static assert(false, T.stringof);
				} else static if (is(T == U*, U)) {
					mixin("return handlers[", i, "](*as", i, ");");
				} else {
					mixin("return handlers[", i, "](as", i, ");");
				}
			}
		}
		assert(0);
	}

	pure:

	private enum usesTaggedPointer = canUseTaggedPointer!Types;
	static if (usesTaggedPointer) {
		private immutable ulong value;
		private static immutable(ulong) makeValue(immutable ulong kind)(immutable ulong ptr) {
			static assert((kind & 0b11) == kind);
			verify((ptr & 0b11) == 0);
			return ptr | kind;
		}
		immutable(uint) kind() scope const =>
			value & 0b11;
		immutable(ulong) ptrValue() scope const =>
			value & ~0b11;
	} else {
		private immutable uint kind;
		union {
			static foreach (i, T; Types) {
				mixin("private T as", i, ";");
			}
		}
	}

	static foreach (i, T; Types) {
		static if (usesTaggedPointer && isEmptyStruct!T) {
			immutable this(immutable T a) {
				value = makeValue!i(0);
			}
		} else static if (is(T == SmallArray!U, U)) {
			@trusted immutable this(immutable U[] a) {
				static if (usesTaggedPointer) {
					value = makeValue!i(SmallArray!U.encode(a));
				} else {
					kind = i;
					mixin("as", i, " = a;");
				}
			}
		} else {
			immutable this(immutable T a) {
				static if (usesTaggedPointer) {
					static assert(is(T == P*, P));
					value = makeValue!i(cast(immutable ulong) a);
				} else {
					kind = i;
					mixin("as", i, " = a;");
				}
			}
		}
	}

	@trusted R match(R)(scope toHandlers!(R, Types) handlers) immutable {
		static foreach (i, T; Types) {
			if (kind == i) {
				static if (usesTaggedPointer) {
					static if (isEmptyStruct!T)
						return handlers[i](immutable T());
					else static if (is(T == SmallArray!U, U))
						return handlers[i](SmallArray!U.decode(ptrValue));
					else static if (is(T == P*, P))
						return handlers[i](*(cast(immutable P*) ptrValue));
					else
						static assert(false, T.stringof);
				} else static if (is(T == U*, U)) {
					mixin("return handlers[", i, "](*as", i, ");");
				} else {
					mixin("return handlers[", i, "](as", i, ");");
				}
			}
		}
		assert(0);
	}

	immutable(bool) isA(T)() scope const {
		static assert(isIn!(T, Types));
		static foreach (i, Ty; Types) {
			static if (is(T == Ty))
				return kind == i;
		}
		assert(0);
	}

	@trusted ref inout(T) as(T)() return inout {
		static foreach (i, Ty; Types) {
			static if (is(T == Ty)) {
				verify(kind == i);
				mixin("return as", i, ";");
			}
		}
	}
}

immutable(bool) canUseTaggedPointer(Types...)() {
	static if (Types.length > 4) {
		return false;
	} else static if (Types.length == 0) {
		return true;
	} else static if (isEmptyStruct!(Types[0]) || is(Types[0] == U*, U) || is(Types[0] == SmallArray!U, U)) {
		return canUseTaggedPointer!(Types[1 .. $]);
	} else {
		return false;
	}
}

immutable(bool) isIn(T, Types...)() {
	static if (Types.length == 0 ||is(T == Types[0])) {
		return true;
	} else {
		return isIn!(T, Types[1 .. $]);
	}
}

immutable(bool) isEmptyStruct(T)() {
	static if (is(T == struct)) {
		return __traits(allMembers, T).length == 0;
	} else {
		return false;
	}
};
private struct TestEmptyStruct {}
private struct TestNonEmptyStruct { bool b; }
static assert(isEmptyStruct!TestEmptyStruct);
static assert(!isEmptyStruct!TestNonEmptyStruct);
static assert(!isEmptyStruct!bool);

template toHandlers(R, Types...) {
	template toHandler(P) {
		static if (is(P == U*, U)) {
			alias toHandler = immutable(R) delegate(ref immutable U) @safe @nogc pure nothrow;
		} else static if (is(P == SmallArray!U, U)) {
			alias toHandler = immutable(R) delegate(immutable U[]) @safe @nogc pure nothrow;
		} else {
			alias toHandler = immutable(R) delegate(immutable P) @safe @nogc pure nothrow;
		}
	}
	alias toHandlers = staticMap!(toHandler, Types);
}

template toHandlersImpure(R, Types...) {
	template toHandlerImpure(P) {
		static if (is(P == U*, U)) {
			alias toHandlerImpure = immutable(R) delegate(ref immutable U) @safe @nogc nothrow;
		} else static if (is(P == SmallArray!U, U)) {
			alias toHandlerImpure = immutable(R) delegate(immutable U[]) @safe @nogc nothrow;
		} else {
			alias toHandlerImpure = immutable(R) delegate(immutable P) @safe @nogc nothrow;
		}
	}
	alias toHandlersImpure = staticMap!(toHandlerImpure, Types);
}
