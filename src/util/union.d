module util.union_;

@safe @nogc nothrow: // not pure

import std.traits : EnumMembers, isMutable, Unqual;
import std.meta : staticMap;
import util.col.array : MutSmallArray, SmallArray;
import util.util : assertNormalEnum;

mixin template TaggedUnion(ReprTypes...) {
	@safe @nogc nothrow:

	import std.meta : staticMap;
	import util.union_ :
		canUseTaggedPointers,
		getFromValueWithoutTag,
		getTaggedPointerValue,
		isEmptyStruct,
		isImmutable,
		toHandlers,
		toHandlersConst,
		toHandlersIn,
		toHandlersImpure,
		toHandlersWithPointers,
		toMemberType;

	static assert(canUseTaggedPointers!ReprTypes);

	private alias MemberTypes = staticMap!(toMemberType, ReprTypes);

	static if (isImmutable!(typeof(this))) {
		static foreach (T; ReprTypes)
			static assert(is(T == enum) || isImmutable!T, "Member types of immutable TaggedUnion should be immutable");
	}

	@trusted R matchImpure(R)(scope toHandlersImpure!(R, MemberTypes) handlers) scope immutable {
		final switch (kind) {
			static foreach (i, T; ReprTypes) {
				case i:
					static if (isEmptyStruct!T)
						return handlers[i](T());
					else static if (is(T == P*, P))
						return handlers[i](*(cast(immutable P*) valueWithoutTag));
					else
						return handlers[i](as!T);
			}
		}
	}

	pure:

	union {
		private immutable void* voidPointerWithTag; // Not a valid pointer! Here so 'scope' works.
		private ulong valueWithTag;
	}
	private uint kind() scope const =>
		valueWithTag & 0b11;
	private ulong valueWithoutTag() scope const =>
		valueWithTag & ~0b11;
	@trusted void* asVoidPointer() return scope =>
		cast(void*) valueWithoutTag;
	bool taggedPointerEquals(in typeof(this) other) scope const =>
		valueWithTag == other.valueWithTag;
	ulong taggedPointerValueForHash() scope =>
		valueWithTag;

	static if (ReprTypes.length < 4) {
		private immutable struct InvalidValue {}
		private @trusted this(InvalidValue a) {
			valueWithTag = 0b11;
		}
		static typeof(this) invalidValue() =>
			typeof(this)(InvalidValue());
		@trusted bool isInvalidValue() scope =>
			valueWithTag == 0b11;
	}

	@disable this();
	static foreach (i, T; MemberTypes) {
		@trusted inout this(inout T a) {
			static if (is(T == P*, P))
				assert(a != null);
			valueWithTag = getTaggedPointerValue!(i, T)(a);
		}
	}

	@trusted R match(R)(scope toHandlers!(R, MemberTypes) handlers) {
		final switch (kind) {
			static foreach (i, T; MemberTypes) {
				case i:
					static if (is(T == P*, P))
						return handlers[i](*(cast(P*) valueWithoutTag));
					else
						return handlers[i](as!T);
			}
		}
	}

	static if (!isImmutable!(typeof(this))) {
		@trusted R matchConst(R)(scope toHandlersConst!(R, MemberTypes) handlers) const {
			final switch (kind) {
				static foreach (i, T; MemberTypes) {
					case i:
						static if (is(T == P*, P))
							return handlers[i](cast(const P*) valueWithoutTag);
						else
							return handlers[i](as!T);
				}
			}
		}
	}

	@trusted R matchIn(R)(scope toHandlersIn!(R, MemberTypes) handlers) scope {
		final switch (kind) {
			static foreach (i, T; MemberTypes) {
				case i:
					static if (is(T == P*, P))
						return handlers[i](*(cast(immutable P*) valueWithoutTag));
					else
						return handlers[i](as!T);
			}
		}
	}

	@trusted R matchWithPointers(R)(scope toHandlersWithPointers!(R, MemberTypes) handlers) {
		final switch (kind) {
			static foreach (i, T; MemberTypes) {
				case i:
					return handlers[i](asNonConst!T);
			}
		}
	}

	bool isA(T)() scope const {
		static foreach (i, Ty; MemberTypes) {
			static if (is(T == Ty))
				return kind == i;
		}
	}

	@trusted const(T) as(T)() const {
		static foreach (i, Ty; ReprTypes) {
			static if (is(T == toMemberType!Ty)) {
				assert(kind == i);
				return getFromValueWithoutTag!Ty(valueWithoutTag);
			}
		}
	}

	@trusted private T asNonConst(T)() {
		static foreach (i, Ty; ReprTypes) {
			static if (is(T == toMemberType!Ty)) {
				assert(kind == i);
				return getFromValueWithoutTag!Ty(valueWithoutTag);
			}
		}
	}

	static if (!isImmutable!(typeof(this))) {
		@trusted inout(T) asInout(T)() inout {
			static foreach (i, Ty; ReprTypes) {
				static if (is(T == toMemberType!Ty)) {
					assert(kind == i);
					static if (is(Ty == P*, P))
						return cast(inout P*) valueWithoutTag;
					else static if (is(T == enum))
						return cast(T) (valueWithoutTag >> 2);
					else
						return cast(inout) Ty.fromTagged(valueWithoutTag);
				}
			}
		}
	}
}

static @system T getFromValueWithoutTag(T)(ulong valueWithoutTag) {
	static if (isEmptyStruct!T)
		return T();
	else static if (is(T == P*, P))
		return cast(P*) valueWithoutTag;
	else static if (is(T == enum) || is(T == uint) || is(T == immutable uint))
		return cast(T) (valueWithoutTag >> 2);
	else static if (T.sizeof <= uint.sizeof)
		return T.fromUintForTaggedUnion(cast(uint) (valueWithoutTag >> 2));
	else
		return T.fromTagged(valueWithoutTag);
}

mixin template Union(ReprTypes...) {
	@safe @nogc nothrow:

	import std.meta : staticMap;
	import util.union_ :
		canUseTaggedPointers,
		isEmptyStruct,
		isImmutable,
		toHandlers,
		toHandlersIn,
		toHandlersImpure,
		toHandlersWithPointers,
		toMemberType;

	static foreach (T; ReprTypes)
		static assert(is(T == enum) || isImmutable!T, "Union types must be immutable (otherwise use UnionMutable)");

	static assert(!canUseTaggedPointers!ReprTypes, "Use TaggedUnion instead");
	alias MemberTypes = staticMap!(toMemberType, ReprTypes);

	@trusted R matchImpure(R)(scope toHandlersImpure!(R, MemberTypes) handlers) scope immutable {
		final switch (kind) {
			static foreach (i, T; ReprTypes) {
				case i:
					static if (is(T == U*, U)) {
						mixin("return handlers[", i, "](*as", i, ");");
					} else {
						mixin("return handlers[", i, "](as", i, ");");
					}
			}
		}
	}

	pure:

	private immutable uint kind;
	union {
		static foreach (i, T; ReprTypes) {
			mixin("private immutable T as", i, ";");
		}
	}

	@disable this();
	static foreach (i, T; ReprTypes) {
		@trusted immutable this(immutable toMemberType!T a) {
			static if (is(T == P*, P))
				assert(a != null);
			kind = i;
			mixin("as", i, " = a;");
		}
	}

	@trusted R match(R)(scope toHandlers!(R, MemberTypes) handlers) immutable {
		final switch (kind) {
			static foreach (i, T; ReprTypes) {
				case i:
					static if (is(T == U*, U)) {
						mixin("return handlers[", i, "](*as", i, ");");
					} else {
						mixin("return handlers[", i, "](as", i, ");");
					}
			}
		}
	}

	@trusted R matchIn(R)(scope toHandlersIn!(R, MemberTypes) handlers) scope {
		final switch (kind) {
			static foreach (i, T; ReprTypes) {
				case i:
					static if (is(T == U*, U)) {
						mixin("return handlers[", i, "](*as", i, ");");
					} else {
						mixin("return handlers[", i, "](as", i, ");");
					}
			}
		}
	}

	@trusted R matchWithPointers(R)(scope toHandlersWithPointers!(R, MemberTypes) handlers) immutable {
		final switch (kind) {
			static foreach (i, T; ReprTypes) {
				case i:
					mixin("return handlers[", i, "](as", i, ");");
			}
		}
	}

	static foreach (i, Ty; MemberTypes) {
		bool isA(T : Ty)() scope immutable {
			return kind == i;
		}
	}

	static foreach (i, Ty; ReprTypes) {
		static if (is(Ty == toMemberType!Ty)) {
			@trusted ref immutable(T) as(T : Ty)() immutable {
				assert(kind == i);
				mixin("return as", i, ";");
			}
		} else {
			@trusted immutable(T) as(T : toMemberType!Ty)() immutable {
				assert(kind == i);
				mixin("return as", i, ";");
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
	is(T == bool) || is(T == uint) || is(T == ulong) || is(T == long) || is(T == double);

mixin template UnionMutable(Types...) {
	@safe @nogc pure nothrow:

	import std.traits : isMutable;
	import util.memory : overwriteMemory;
	import util.union_ : toHandlersConst, toHandlersMutable, toHandlersScope;

	private uint kind;
	union {
		static foreach (i, T; Types) {
			mixin("private T as", i, ";");
		}
	}

	@disable this();
	static foreach (i, T; Types) {
		static if (isMutable!T) {
			@trusted this(return inout T a) inout {
				static if (is(T == P*, P))
					assert(a != null);
				kind = i;
				mixin("as", i, " = a;");
			}
		} else {
			@trusted this(return T a) {
				static if (is(T == P*, P))
					assert(a != null);
				kind = i;
				mixin("as", i, " = a;");
			}
		}
	}

	static foreach (i, T; Types) {
		@trusted void opAssign(T b) {
			kind = i;
			mixin("overwriteMemory(&as", i, ", b);");
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

	@trusted R matchScope(R)(scope toHandlersScope!(R, Types) handlers) scope {
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

	@trusted ref inout(T) as(T)() inout {
		static foreach (i, Ty; Types) {
			static if (is(T == Ty)) {
				assert(kind == i);
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
private bool canUseTaggedPointer(T)() {
	static if (T.sizeof <= uint.sizeof || is(T == U*, U) || __traits(hasMember, T, "fromTagged")) {
		return true;
	} else static if (is(T == enum)) {
		assertNormalEnum!T;
		return true;
	} else
		return false;
}

@trusted ulong getAsTaggable(T)(const T a) {
	static if (isEmptyStruct!T)
		return 0;
	else static if (is(T == P*, P))
		return cast(ulong) a;
	else static if (is(T == U[], U))
		return (const MutSmallArray!U(a)).asTaggable;
	else static if (is(T == enum) || is(T == uint) || is(T == immutable uint))
		return (cast(ulong) a) << 2;
	else static if (T.sizeof <= uint.sizeof)
		return (cast(ulong) a.asUintForTaggedUnion) << 2;
	else
		return a.asTaggable;
}

ulong getTaggedPointerValue(size_t i, T)(const T a) {
	ulong ptr = getAsTaggable!T(a);
	assert((ptr & 0b11) == 0);
	static assert((i & 0b11) == i);
	return ptr | i;
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
	static if (is(T == MutSmallArray!U, U))
		alias toMemberType = U[];
	else
		alias toMemberType = T;
}

template toHandlers(R, Types...) {
	template toHandler(P) {
		static if (is(P == U*, U))
			alias toHandler = R delegate(ref U) @safe @nogc pure nothrow;
		else static if (isSimple!(Unqual!P))
			alias toHandler = R delegate(Unqual!P) @safe @nogc pure nothrow;
		else
			alias toHandler = R delegate(P) @safe @nogc pure nothrow;
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
			alias toHandlerIn = R delegate(in Unqual!P) @safe @nogc pure nothrow;
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
	template toHandlerConst(P) {
		static if (isMutable!P) {
			static if (isEmptyStruct!P || is(P == enum) || is(P == U[], U) || is(P == U*, U))
				alias toHandlerConst = R delegate(const P) @safe @nogc pure nothrow;
			else static if (is(P == MutSmallArray!U, U))
				alias toHandlerConst = R delegate(const U[]) @safe @nogc pure nothrow;
			else
				alias toHandlerConst = R delegate(ref const P) @safe @nogc pure nothrow;
		} else
			alias toHandlerConst = R delegate(immutable P) @safe @nogc pure nothrow;
	}
	alias toHandlersConst = staticMap!(toHandlerConst, Types);
}

template toHandlersMutable(R, Types...) {
	template toHandlerMutable(P) {
		static if (isMutable!P) {
			static if (isEmptyStruct!P || is(P == U[], U) || is(P == U*, U))
				alias toHandlerMutable = R delegate(P) @safe @nogc pure nothrow;
			else static if (is(P == MutSmallArray!U, U))
				alias toHandlerMutable = R delegate(U[]) @safe @nogc pure nothrow;
			else
				alias toHandlerMutable = R delegate(ref P) @safe @nogc pure nothrow;
		} else
			alias toHandlerMutable = R delegate(immutable P) @safe @nogc pure nothrow;
	}
	alias toHandlersMutable = staticMap!(toHandlerMutable, Types);
}

template toHandlersScope(R, Types...) {
	template toHandlerScope(P) {
		static if (isEmptyStruct!P)
			alias toHandlerScope = R delegate(P) @safe @nogc pure nothrow;
		else static if (is(P == U*, U))
			alias tohandlerScope = R delegate(scope ref U) @safe @nogc pure nothrow;
		else
			alias toHandlerScope = R delegate(scope ref P) @safe @nogc pure nothrow;
	}
	alias toHandlersScope = staticMap!(toHandlerScope, Types);
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
