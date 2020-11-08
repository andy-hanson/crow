module interpret.applyFn;

@safe @nogc nothrow: // not pure

import core.atomic : cas;

import interpret.bytecode : FnOp;
import interpret.runBytecode : DataStack;
import util.collection.globalAllocatedStack : pop, push;
import util.types :
	bottomU16OfU64,
	bottomU32OfU64,
	i8,
	i16,
	i32,
	i64,
	float64,
	float64OfU64Bits,
	Nat64,
	u64,
	u64OfFloat64Bits;
import util.util : todo, verify;

void applyFn(ref DataStack dataStack, immutable FnOp fn) {
	final switch (fn) {
		case FnOp.addFloat64:
			binaryFloats(dataStack, (immutable float64 a, immutable float64 b) =>
				a + b);
			break;
		case FnOp.bitwiseAnd:
			binary(dataStack, (immutable u64 a, immutable u64 b) =>
				immutable Nat64(a & b));
			break;
		case FnOp.bitwiseOr:
			binary(dataStack, (immutable u64 a, immutable u64 b) =>
				immutable Nat64(a | b));
			break;
		case FnOp.compareExchangeStrongBool:
			trinary(dataStack, (immutable u64 a, immutable u64 b, immutable u64 c) =>
				compareExchangeStrongBool(a, b, c));
			break;
		case FnOp.eqBits:
			binary(dataStack, (immutable u64 a, immutable u64 b) =>
				u64OfBool(a == b));
			break;
		case FnOp.float64FromInt64:
			unary(dataStack, (immutable u64 a) =>
				u64OfFloat64Bits(cast(float64) (cast(i64) a)));
			break;
		case FnOp.float64FromNat64:
			unary(dataStack, (immutable u64 a) =>
				u64OfFloat64Bits(cast(float64) a));
			break;
		case FnOp.intFromInt16:
			unary(dataStack, (immutable u64 a) =>
				immutable Nat64(cast(u64) (cast(i64) (cast(i16) (bottomU16OfU64(a))))));
			break;
		case FnOp.intFromInt32:
			unary(dataStack, (immutable u64 a) =>
				nat64OfI32(cast(i32) (bottomU32OfU64(a))));
			break;
		case FnOp.hardFail:
			todo!void("!");
			break;
		case FnOp.lessFloat64:
			binary(dataStack, (immutable u64 a, immutable u64 b) =>
				u64OfBool(float64OfU64Bits(a) < float64OfU64Bits(b)));
			break;
		case FnOp.lessInt8:
			binary(dataStack, (immutable u64 a, immutable u64 b) =>
				u64OfBool((cast(i8) a) < (cast(i8) b)));
			break;
		case FnOp.lessInt16:
			binary(dataStack, (immutable u64 a, immutable u64 b) =>
				u64OfBool((cast(i16) a) < (cast(i16) b)));
			break;
		case FnOp.lessInt32:
			binary(dataStack, (immutable u64 a, immutable u64 b) =>
				u64OfBool((cast(i32) a) < (cast(i32) b)));
			break;
		case FnOp.lessInt64:
			binary(dataStack, (immutable u64 a, immutable u64 b) =>
				u64OfBool((cast(i64) a) < (cast(i64) b)));
			break;
		case FnOp.lessNat:
			binary(dataStack, (immutable u64 a, immutable u64 b) =>
				u64OfBool(a < b));
			break;
		case FnOp.mulFloat64:
			binaryFloats(dataStack, (immutable float64 a, immutable float64 b) =>
				a * b);
			break;
		case FnOp.not:
			unary(dataStack, (immutable u64 a) => u64OfBool(a == 0));
			break;
		case FnOp.subFloat64:
			binaryFloats(dataStack, (immutable float64 a, immutable float64 b) =>
				a - b);
			break;
		case FnOp.truncateToInt64FromFloat64:
			unary(dataStack, (immutable u64 a) =>
				immutable Nat64(cast(u64) cast(i64) float64OfU64Bits(a)));
			break;
		case FnOp.unsafeBitShiftLeftNat64:
			binary(dataStack, (immutable u64 a, immutable u64 b) {
				verify(b < 64);
				return immutable Nat64(a << b);
			});
			break;
		case FnOp.unsafeBitShiftRightNat64:
			binary(dataStack, (immutable u64 a, immutable u64 b) {
				verify(b < 64);
				return immutable Nat64(a >> b);
			});
			break;
		case FnOp.unsafeDivFloat64:
			binaryFloats(dataStack, (immutable float64 a, immutable float64 b) =>
				a / b);
			break;
		case FnOp.unsafeDivInt64:
			binary(dataStack, (immutable u64 a, immutable u64 b) =>
				immutable Nat64(cast(u64) ((cast(i64) a) / (cast(i64) b))));
			break;
		case FnOp.unsafeDivNat64:
			binary(dataStack, (immutable u64 a, immutable u64 b) =>
				immutable Nat64(a / b));
			break;
		case FnOp.unsafeModNat64:
			binary(dataStack, (immutable u64 a, immutable u64 b) =>
				immutable Nat64(a % b));
			break;
		case FnOp.wrapAddIntegral:
			binary(dataStack, (immutable u64 a, immutable u64 b) =>
				immutable Nat64(a + b));
			break;
		case FnOp.wrapMulIntegral:
			binary(dataStack, (immutable u64 a, immutable u64 b) =>
				immutable Nat64(a * b));
			break;
		case FnOp.wrapSubIntegral:
			binary(dataStack, (immutable u64 a, immutable u64 b) =>
				immutable Nat64(a - b));
			break;
	}
}

//TODO:MOVE
pure immutable(Nat64) nat64OfI32(immutable i32 a) {
	return nat64OfI64(a);
}

pure immutable(Nat64) nat64OfI64(immutable i64 a) {
	return immutable Nat64(cast(u64) a);
}

private:

pure @trusted immutable(u64) compareExchangeStrongBool(immutable u64 a, immutable u64 b, immutable u64 c) {
	bool* valuePtr = cast(bool*) a;
	immutable bool expected = *(cast(immutable bool*) b);
	immutable bool desired = cast(immutable bool) c;
	return cas(valuePtr, expected, desired);
}

pure immutable(Nat64) u64OfBool(immutable bool value) {
	return immutable Nat64(value ? 1 : 0);
}

void unary(ref DataStack dataStack, scope immutable(Nat64) delegate(immutable u64) @safe @nogc pure nothrow cb) {
	push(dataStack, cb(pop(dataStack).raw()));
}

void binary(
	ref DataStack dataStack,
	scope immutable(Nat64) delegate(immutable u64, immutable u64) @safe @nogc pure nothrow cb,
) {
	immutable u64 b = pop(dataStack).raw();
	immutable u64 a = pop(dataStack).raw();
	push(dataStack, cb(a, b));
}

void trinary(
	ref DataStack dataStack,
	scope immutable(u64) delegate(immutable u64, immutable u64, immutable u64) @safe @nogc pure nothrow cb,
) {
	immutable u64 c = pop(dataStack).raw();
	immutable u64 b = pop(dataStack).raw();
	immutable u64 a = pop(dataStack).raw();
	push(dataStack, immutable Nat64(cb(a, b, c)));
}

void binaryFloats(
	ref DataStack dataStack,
	scope immutable(float64) delegate(immutable float64, immutable float64) @safe @nogc pure nothrow cb,
) {
	binary(dataStack, (immutable u64 a, immutable u64 b) =>
		u64OfFloat64Bits(cb(float64OfU64Bits(a), float64OfU64Bits(b))));
}
