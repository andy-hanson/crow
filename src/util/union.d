module util.union_;

@safe @nogc nothrow: // not pure

import std.traits : isMutable, Unqual;
import std.meta : staticMap;
import util.col.arr : SmallArray;

mixin template Union(ReprTypes...) {
	@safe @nogc nothrow:

	import std.meta : staticMap;
	import util.col.arr : SmallArray;
	import util.union_ :
		canUseTaggedPointers,
		getAsTaggable,
		isEmptyStruct,
		isImmutable,
		toHandlers,
		toHandlersIn,
		toHandlersImpure,
		toHandlersWithPointers,
		toMemberType;
	import util.util : verify;

	static foreach (T; ReprTypes)
		static assert(isImmutable!T, "Union types must be immutable (otherwise use UnionMutable)");

	enum usesTaggedPointer = canUseTaggedPointers!ReprTypes;
	alias MemberTypes = staticMap!(toMemberType, ReprTypes);

	@trusted R matchImpure(R)(scope toHandlersImpure!(R, MemberTypes) handlers) scope immutable {
		final switch (kind) {
			static foreach (i, T; ReprTypes) {
				case i:
					static if (usesTaggedPointer) {
						static if (isEmptyStruct!T)
							return handlers[i](T());
						else static if (is(T == SmallArray!U, U))
							return handlers[i](SmallArray!U.fromTagged(ptrValue));
						else static if (is(T == P*, P))
							return handlers[i](*(cast(immutable P*) ptrValue));
						else
							static assert(false);
					} else static if (is(T == U*, U)) {
						mixin("return handlers[", i, "](*as", i, ");");
					} else {
						mixin("return handlers[", i, "](as", i, ");");
					}
			}
		}
	}

	pure:

	static if (usesTaggedPointer) {
		private immutable ulong value;
		private uint kind() scope const =>
			value & 0b11;
		private ulong ptrValue() scope const =>
			value & ~0b11;
	} else {
		private immutable uint kind;
		union {
			static foreach (i, T; ReprTypes) {
				mixin("private immutable T as", i, ";");
			}
		}
	}

	@disable this();
	static foreach (i, T; ReprTypes) {
		immutable this(immutable toMemberType!T a) {
			static if (is(T == P*, P))
				verify(a != null);
			static if (usesTaggedPointer) {
				ulong ptr = getAsTaggable!T(a);
				verify((ptr & 0b11) == 0);
				static assert((i & 0b11) == i);
				value = ptr | i;
			} else {
				kind = i;
				mixin("as", i, " = a;");
			}
		}
	}

	@trusted R match(R)(scope toHandlers!(R, MemberTypes) handlers) immutable {
		final switch (kind) {
			static foreach (i, T; ReprTypes) {
				case i:
					static if (usesTaggedPointer) {
						static if (isEmptyStruct!T)
							return handlers[i](T());
						else static if (is(T == P*, P))
							return handlers[i](*(cast(immutable P*) ptrValue));
						else
							return handlers[i](T.fromTagged(ptrValue));
					} else {
						static if (is(T == U*, U)) {
							mixin("return handlers[", i, "](*as", i, ");");
						} else {
							mixin("return handlers[", i, "](as", i, ");");
						}
					}
			}
		}
	}

	@trusted R matchIn(R)(scope toHandlersIn!(R, MemberTypes) handlers) scope {
		final switch (kind) {
			static foreach (i, T; ReprTypes) {
				case i:
					static if (usesTaggedPointer) {
						static if (isEmptyStruct!T)
							return handlers[i](T());
						else static if (is(T == P*, P))
							return handlers[i](*(cast(immutable P*) ptrValue));
						else
							return handlers[i](T.fromTagged(ptrValue));
					} else {
						static if (is(T == U*, U)) {
							mixin("return handlers[", i, "](*as", i, ");");
						} else {
							mixin("return handlers[", i, "](as", i, ");");
						}
					}
			}
		}
	}

	@trusted R matchWithPointers(R)(scope toHandlersWithPointers!(R, MemberTypes) handlers) immutable {
		final switch (kind) {
			static foreach (i, T; ReprTypes) {
				case i:
					static if (usesTaggedPointer) {
						static if (isEmptyStruct!T)
							return handlers[i](T());
						else static if (is(T == P*, P))
							return handlers[i](cast(immutable P*) ptrValue);
						else
							return handlers[i](T.fromTagged(ptrValue));
					} else {
						mixin("return handlers[", i, "](as", i, ");");
					}
			}
		}
	}

	bool isA(T)() scope immutable {
		static foreach (i, Ty; MemberTypes) {
			static if (is(immutable T == Ty))
				return kind == i;
		}
	}

	@trusted immutable(T) as(T)() immutable {
		static foreach (i, Ty; ReprTypes) {
			static if (is(immutable T == toMemberType!Ty)) {
				verify(kind == i);
				static if (usesTaggedPointer) {
					static if (is(Ty == P*, P))
						return (cast(immutable P*) ptrValue);
					else
						return Ty.fromTagged(ptrValue);
				} else {
					mixin("return as", i, ";");
				}
			}
		}
	}
}

bool isImmutable(T)() {
	static if (is(T == U*, U))
		return !isMutable!U;
	else static if (is(T == U[], U))
		return !isMutable!U || is(U == ubyte);
	else static if (isSimple!T)
		return true;
	else
		return !isMutable!T;
}

bool isSimple(T)() =>
	is(T == bool) || is(T == size_t) || is(T == long) || is(T == double);

mixin template UnionMutable(Types...) {
	@safe @nogc pure nothrow:

	import util.memory : overwriteMemory;
	import util.union_ : toHandlersConst, toHandlersMutable;
	import util.util : verify;

	private uint kind;
	union {
		static foreach (i, T; Types) {
			mixin("private T as", i, ";");
		}
	}

	@disable this();
	static foreach (i, T; Types) {
		this(return T a) {
			kind = i;
			mixin("as", i, " = a;");
		}
	}

	static foreach (i, T; Types) {
		@trusted void opAssign(T value) {
			kind = i;
			mixin("overwriteMemory(&as", i, ", value);");
		}
	}

	@trusted R match(R)(scope toHandlersMutable!(R, Types) handlers) {
		final switch (kind) {
			static foreach (i, T; Types) {
				case i:
					mixin("return handlers[", i, "](as", i, ");");
			}
		}
	}

	@trusted R matchConst(R)(scope toHandlersConst!(R, Types) handlers) const {
		final switch (kind) {
			static foreach (i, T; Types) {
				case i:
					mixin("return handlers[", i, "](as", i, ");");
			}
		}
	}

	bool isA(T)() scope const {
		static foreach (i, Ty; Types) {
			static if (is(T == Ty))
				return kind == i;
		}
	}

	@trusted ref T as(T)() {
		static foreach (i, Ty; Types) {
			static if (is(T == Ty)) {
				verify(kind == i);
				mixin("return as", i, ";");
			}
		}
	}
}

bool canUseTaggedPointers(Types...)() {
	static if (Types.length > 4)
		return false;
	else static if (Types.length == 0)
		return true;
	else static if (canUseTaggedPointer!(Types[0]))
		return canUseTaggedPointers!(Types[1 .. $]);
	else
		return false;
}
private bool canUseTaggedPointer(T)() =>
	isEmptyStruct!T || is(T == U*, U) || __traits(compiles, T.fromTagged(0)); 

ulong getAsTaggable(T)(toMemberType!T a) {
	static if (isEmptyStruct!T)
		return 0;
	else static if (is(T == P*, P))
		return cast(ulong) a;
	else static if (is(T == SmallArray!U, U))
		return T(a).asTaggable;
	else
		return a.asTaggable;
}

bool isEmptyStruct(T)() {
	static if (is(T == struct))
		return __traits(allMembers, T).length == 0;
	else
		return false;
}
private struct TestEmptyStruct {}
private struct TestNonEmptyStruct { bool b; }
static assert(isEmptyStruct!TestEmptyStruct);
static assert(!isEmptyStruct!TestNonEmptyStruct);
static assert(!isEmptyStruct!bool);

template toMemberType(T) {
	static if (is(T == SmallArray!U, U))
		alias toMemberType = immutable U[];
	else
		alias toMemberType = immutable T;
}

template toHandlers(R, Types...) {
	template toHandler(P) {
		static if (is(P == U*, U))
			alias toHandler = R delegate(ref immutable U) @safe @nogc pure nothrow;
		else static if (isSimple!(Unqual!P))
			alias toHandler = R delegate(Unqual!P) @safe @nogc pure nothrow;
		else
			alias toHandler = R delegate(immutable P) @safe @nogc pure nothrow;
	}
	alias toHandlers = staticMap!(toHandler, Types);
}

template toHandlersIn(R, Types...) {
	template toHandlerIn(P) {
		static if (is(P == U*, U))
			alias toHandlerIn = immutable(R) delegate(in U) @safe @nogc pure nothrow;
		else static if (is(P == U[], U))
			// This makes it 'immutable(T)[]' instead of 'immutable T[]'
			alias toHandlerIn = R delegate(in U[]) @safe @nogc pure nothrow;
		else static if (isSimple!(Unqual!P))
			alias toHandlerIn = R delegate(Unqual!P) @safe @nogc pure nothrow;
		else
			alias toHandlerIn = R delegate(in P) @safe @nogc pure nothrow;
	}
	alias toHandlersIn = staticMap!(toHandlerIn, Types);
}

template toHandlersImpure(R, Types...) {
	template toHandlerImpure(P) {
		static if (is(P == U*, U))
			alias toHandlerImpure = R delegate(in U) @safe @nogc nothrow;
		else
			alias toHandlerImpure = R delegate(in P) @safe @nogc nothrow;
	}
	alias toHandlersImpure = staticMap!(toHandlerImpure, Types);
}

template toHandlersConst(R, Types...) {
	alias toHandlerConst(P) = R delegate(const P) @safe @nogc pure nothrow;
	alias toHandlersConst = staticMap!(toHandlerConst, Types);
}

template toHandlersMutable(R, Types...) {
	template toHandlerMutable(P) {
		static if (isMutable!P) {
			static if (is(P == U[], U) || is(P == U*, U))
				alias toHandlerMutable = R delegate(P) @safe @nogc pure nothrow;
			else
				alias toHandlerMutable = R delegate(ref P) @safe @nogc pure nothrow;
		} else
			alias toHandlerMutable = R delegate(immutable P) @safe @nogc pure nothrow;
	}
	alias toHandlersMutable = staticMap!(toHandlerMutable, Types);
}

template toHandlersWithPointers(R, Types...) {
	template toHandlerWithPointers(P) {
		static if (isSimple!(Unqual!P))
			alias toHandlerWithPointers = R delegate(Unqual!P) @safe @nogc pure nothrow;
		else
			alias toHandlerWithPointers = R delegate(P) @safe @nogc pure nothrow;
	}
	alias toHandlersWithPointers = staticMap!(toHandlerWithPointers, Types);
}
