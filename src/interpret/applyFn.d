module interpret.applyFn;

@safe @nogc pure nothrow:

import interpret.bytecode : FnOp;
import interpret.runBytecode : DataStack;
import util.collection.globalAllocatedStack : pop, push;
import util.types :
	bottomU16OfU64,
	bottomU32OfU64,
	float32OfU64Bits,
	float64OfU64Bits,
	Nat64,
	u64OfFloat32Bits,
	u64OfFloat64Bits;
import util.util : verify;

void applyFn(ref DataStack dataStack, immutable FnOp fn) {
	final switch (fn) {
		case FnOp.addFloat32:
			binaryFloat32s(dataStack, (immutable float a, immutable float b) =>
				a + b);
			break;
		case FnOp.addFloat64:
			binaryFloat64s(dataStack, (immutable double a, immutable double b) =>
				a + b);
			break;
		case FnOp.bitwiseNot:
			unary(dataStack, (immutable ulong a) =>
				immutable Nat64(~a));
			break;
		case FnOp.bitwiseAnd:
			binary(dataStack, (immutable ulong a, immutable ulong b) =>
				immutable Nat64(a & b));
			break;
		case FnOp.bitwiseOr:
			binary(dataStack, (immutable ulong a, immutable ulong b) =>
				immutable Nat64(a | b));
			break;
		case FnOp.bitwiseXor:
			binary(dataStack, (immutable ulong a, immutable ulong b) =>
				immutable Nat64(a ^ b));
			break;
		case FnOp.countOnesNat64:
			unary(dataStack, (immutable ulong a) =>
				immutable Nat64(popcount(a)));
			break;
		case FnOp.eqBits:
			binary(dataStack, (immutable ulong a, immutable ulong b) =>
				u64OfBool(a == b));
			break;
		case FnOp.eqFloat64:
			binary(dataStack, (immutable ulong a, immutable ulong b) =>
				u64OfBool(float64OfU64Bits(a) == float64OfU64Bits(b)));
			break;
		case FnOp.float64FromFloat32:
			unary(dataStack, (immutable ulong a) =>
				u64OfFloat64Bits(cast(double) float32OfU64Bits(a)));
			break;
		case FnOp.float64FromInt64:
			unary(dataStack, (immutable ulong a) =>
				u64OfFloat64Bits(cast(double) (cast(long) a)));
			break;
		case FnOp.float64FromNat64:
			unary(dataStack, (immutable ulong a) =>
				u64OfFloat64Bits(cast(double) a));
			break;
		case FnOp.intFromInt16:
			unary(dataStack, (immutable ulong a) =>
				immutable Nat64(cast(ulong) (cast(long) (cast(short) (bottomU16OfU64(a))))));
			break;
		case FnOp.intFromInt32:
			unary(dataStack, (immutable ulong a) =>
				nat64OfI32(cast(int) (bottomU32OfU64(a))));
			break;
		case FnOp.isNanFloat32:
			unary(dataStack, (immutable ulong a) =>
				u64OfBool(isNaN(float32OfU64Bits(a))));
			break;
		case FnOp.isNanFloat64:
			unary(dataStack, (immutable ulong a) =>
				u64OfBool(isNaN(float64OfU64Bits(a))));
			break;
		case FnOp.lessFloat32:
			binary(dataStack, (immutable ulong a, immutable ulong b) =>
				u64OfBool(float32OfU64Bits(a) < float32OfU64Bits(b)));
			break;
		case FnOp.lessFloat64:
			binary(dataStack, (immutable ulong a, immutable ulong b) =>
				u64OfBool(float64OfU64Bits(a) < float64OfU64Bits(b)));
			break;
		case FnOp.lessInt8:
			binary(dataStack, (immutable ulong a, immutable ulong b) =>
				u64OfBool((cast(byte) a) < (cast(byte) b)));
			break;
		case FnOp.lessInt16:
			binary(dataStack, (immutable ulong a, immutable ulong b) =>
				u64OfBool((cast(short) a) < (cast(short) b)));
			break;
		case FnOp.lessInt32:
			binary(dataStack, (immutable ulong a, immutable ulong b) =>
				u64OfBool((cast(int) a) < (cast(int) b)));
			break;
		case FnOp.lessInt64:
			binary(dataStack, (immutable ulong a, immutable ulong b) =>
				u64OfBool((cast(long) a) < (cast(long) b)));
			break;
		case FnOp.lessNat:
			binary(dataStack, (immutable ulong a, immutable ulong b) =>
				u64OfBool(a < b));
			break;
		case FnOp.mulFloat64:
			binaryFloat64s(dataStack, (immutable double a, immutable double b) =>
				a * b);
			break;
		case FnOp.subFloat64:
			binaryFloat64s(dataStack, (immutable double a, immutable double b) =>
				a - b);
			break;
		case FnOp.truncateToInt64FromFloat64:
			unary(dataStack, (immutable ulong a) =>
				immutable Nat64(cast(ulong) cast(long) float64OfU64Bits(a)));
			break;
		case FnOp.unsafeBitShiftLeftNat64:
			binary(dataStack, (immutable ulong a, immutable ulong b) {
				verify(b < 64);
				return immutable Nat64(a << b);
			});
			break;
		case FnOp.unsafeBitShiftRightNat64:
			binary(dataStack, (immutable ulong a, immutable ulong b) {
				verify(b < 64);
				return immutable Nat64(a >> b);
			});
			break;
		case FnOp.unsafeDivFloat32:
			binaryFloat32s(dataStack, (immutable float a, immutable float b) =>
				a / b);
			break;
		case FnOp.unsafeDivFloat64:
			binaryFloat64s(dataStack, (immutable double a, immutable double b) =>
				a / b);
			break;
		case FnOp.unsafeDivInt64:
			binary(dataStack, (immutable ulong a, immutable ulong b) =>
				immutable Nat64(cast(ulong) ((cast(long) a) / (cast(long) b))));
			break;
		case FnOp.unsafeDivNat64:
			binary(dataStack, (immutable ulong a, immutable ulong b) =>
				immutable Nat64(a / b));
			break;
		case FnOp.unsafeModNat64:
			binary(dataStack, (immutable ulong a, immutable ulong b) =>
				immutable Nat64(a % b));
			break;
		case FnOp.wrapAddIntegral:
			binary(dataStack, (immutable ulong a, immutable ulong b) =>
				immutable Nat64(a + b));
			break;
		case FnOp.wrapMulIntegral:
			binary(dataStack, (immutable ulong a, immutable ulong b) =>
				immutable Nat64(a * b));
			break;
		case FnOp.wrapSubIntegral:
			binary(dataStack, (immutable ulong a, immutable ulong b) =>
				immutable Nat64(a - b));
			break;
	}
}

//TODO:MOVE
pure immutable(Nat64) nat64OfI32(immutable int a) {
	return nat64OfI64(a);
}

pure immutable(Nat64) nat64OfI64(immutable long a) {
	return immutable Nat64(cast(ulong) a);
}

private:

pure immutable(Nat64) u64OfBool(immutable bool value) {
	return immutable Nat64(value ? 1 : 0);
}

void unary(ref DataStack dataStack, scope immutable(Nat64) delegate(immutable ulong) @safe @nogc pure nothrow cb) {
	push(dataStack, cb(pop(dataStack).raw()));
}

void binary(
	ref DataStack dataStack,
	scope immutable(Nat64) delegate(immutable ulong, immutable ulong) @safe @nogc pure nothrow cb,
) {
	immutable ulong b = pop(dataStack).raw();
	immutable ulong a = pop(dataStack).raw();
	push(dataStack, cb(a, b));
}

void binaryFloat32s(
	ref DataStack dataStack,
	scope immutable(float) delegate(immutable float, immutable float) @safe @nogc pure nothrow cb,
) {
	binary(dataStack, (immutable ulong a, immutable ulong b) =>
		u64OfFloat32Bits(cb(float32OfU64Bits(a), float32OfU64Bits(b))));
}

void binaryFloat64s(
	ref DataStack dataStack,
	scope immutable(double) delegate(immutable double, immutable double) @safe @nogc pure nothrow cb,
) {
	binary(dataStack, (immutable ulong a, immutable ulong b) =>
		u64OfFloat64Bits(cb(float64OfU64Bits(a), float64OfU64Bits(b))));
}

pure immutable(bool) isNaN(immutable double a) {
	return a != a;
}

//TODO:PERF
pure immutable(long) popcount(immutable ulong a) {
	return a == 0
		? 0
		: popcount(a >> 1) + (a % 2 != 0 ? 1 : 0);
}
