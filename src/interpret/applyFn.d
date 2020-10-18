module interpret.applyFn;

@safe @nogc nothrow: // not pure

import core.atomic : cas;

import interpret.bytecode : FnOp;
import interpret.runBytecode : DataStack;
import util.collection.globalAllocatedStack : pop, push;
import util.types : i8, i16, i32, i64, u32, u64, float64, float64OfU64Bits, u64OfFloat64Bits;
import util.util : todo, verify;

public void applyFn(ref DataStack dataStack, immutable FnOp fn) {
	final switch (fn) {
		case FnOp.addFloat64:
			binaryFloats(dataStack, (immutable float64 a, immutable float64 b) =>
				a + b);
			break;
		case FnOp.bitwiseAnd:
			binary(dataStack, (immutable u64 a, immutable u64 b) =>
				a & b);
			break;
		case FnOp.bitwiseOr:
			binary(dataStack, (immutable u64 a, immutable u64 b) =>
				a | b);
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
		case FnOp.malloc:
			todo!void("!");
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
			unary(dataStack, (immutable u64 a) => cast(u64) cast(i64) float64OfU64Bits(a));
			break;
		case FnOp.unsafeBitShiftLeftNat64:
			binary(dataStack, (immutable u64 a, immutable u64 b) {
				verify(b < 64);
				return a << b;
			});
			break;
		case FnOp.unsafeBitShiftRightNat64:
			binary(dataStack, (immutable u64 a, immutable u64 b) {
				verify(b < 64);
				return a >> b;
			});
			break;
		case FnOp.unsafeDivFloat64:
			binaryFloats(dataStack, (immutable float64 a, immutable float64 b) =>
				a / b);
			break;
		case FnOp.unsafeDivInt64:
			binary(dataStack, (immutable u64 a, immutable u64 b) => cast(u64) ((cast(i64) a) / (cast(i64) b)));
			break;
		case FnOp.unsafeDivNat64:
			binary(dataStack, (immutable u64 a, immutable u64 b) => a / b);
			break;
		case FnOp.unsafeModNat64:
			binary(dataStack, (immutable u64 a, immutable u64 b) => a % b);
			break;
		case FnOp.wrapAddIntegral:
			binary(dataStack, (immutable u64 a, immutable u64 b) => a + b);
			break;
		case FnOp.wrapMulIntegral:
			binary(dataStack, (immutable u64 a, immutable u64 b) => a * b);
			break;
		case FnOp.wrapSubIntegral:
			binary(dataStack, (immutable u64 a, immutable u64 b) => a - b);
			break;
	}
}

private:

pure @trusted immutable(u64) compareExchangeStrongBool(immutable u64 a, immutable u64 b, immutable u64 c) {
	bool* valuePtr = cast(bool*) a;
	immutable bool expected = *(cast(immutable bool*) b);
	immutable bool desired = cast(immutable bool) c;
	return cas(valuePtr, expected, desired);
}

pure immutable(u64) u64OfBool(immutable bool value) {
	return value ? 1 : 0;
}

void unary(ref DataStack dataStack, scope immutable(u64) delegate(immutable u64) @safe @nogc pure nothrow cb) {
	push(dataStack, cb(pop(dataStack)));
}

void binary(
	ref DataStack dataStack,
	scope immutable(u64) delegate(immutable u64, immutable u64) @safe @nogc pure nothrow cb,
) {
	immutable u64 b = pop(dataStack);
	immutable u64 a = pop(dataStack);
	push(dataStack, cb(a, b));
}

void trinary(
	ref DataStack dataStack,
	scope immutable(u64) delegate(immutable u64, immutable u64, immutable u64) @safe @nogc pure nothrow cb,
) {
	immutable u64 c = pop(dataStack);
	immutable u64 b = pop(dataStack);
	immutable u64 a = pop(dataStack);
	push(dataStack, cb(a, b, c));
}

void binaryFloats(
	ref DataStack dataStack,
	scope immutable(float64) delegate(immutable float64, immutable float64) @safe @nogc pure nothrow cb,
) {
	binary(dataStack, (immutable u64 a, immutable u64 b) =>
		u64OfFloat64Bits(cb(float64OfU64Bits(a), float64OfU64Bits(b))));
}
