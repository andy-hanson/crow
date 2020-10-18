module test.testApplyFn;

@safe @nogc nothrow: // not pure

import interpret.applyFn : applyFn;
import interpret.bytecode : FnOp;
import interpret.runBytecode : DataStack;
import test.testUtil : expectStack;
import util.collection.arr : arrOfD;
import util.collection.globalAllocatedStack : clearStack, pop, pushAll;
import util.types : float64, i8, i16, i32, i64, u8, u16, u32, u64, u64OfFloat64Bits;
import util.util : verifyEq;

void testApplyFn() {
	u64 one = 1; // https://issues.dlang.org/show_bug.cgi?id=17778

	testFn([u64OfFloat64Bits(-1.5), u64OfFloat64Bits(2.6)], FnOp.addFloat64, [u64OfFloat64Bits(1.1)]);

	testFn([0x0123456789abcdef, u64OfI32Bits(4)], FnOp.unsafeBitShiftLeftNat64, [0x123456789abcdef0]);
	testFn([0x0123456789abcdef, u64OfI32Bits(4)], FnOp.unsafeBitShiftRightNat64, [0x00123456789abcde]);

	testFn([0b0101, 0b0011], FnOp.bitwiseAnd, [0b0001]);
	testFn([0b0101, 0b0011], FnOp.bitwiseOr, [0b0111]);

	testCompareExchangeStrong();

	testFn([u64OfI64Bits(-1)], FnOp.float64FromInt64, [u64OfFloat64Bits(-1.0)]);

	testFn([1], FnOp.float64FromNat64, [u64OfFloat64Bits(1.0)]);

	testFn([u64OfFloat64Bits(-1.0), u64OfFloat64Bits(1.0)], FnOp.lessFloat64, [1]);
	testFn([u64OfFloat64Bits(1.0), u64OfFloat64Bits(-1.0)], FnOp.lessFloat64, [0]);

	verifyEq(u64OfI8Bits(-1), 0xff);

	testFn([u64OfI8Bits(-1), u64OfI8Bits(1)], FnOp.lessInt8, [1]);

	verifyEq(u64OfI16Bits(-1), 0xffff);

	testFn([u64OfI16Bits(-1), u64OfI16Bits(1)], FnOp.lessInt16, [1]);

	verifyEq(u64OfI32Bits(-1), 0x00000000ffffffff);

	testFn([u64OfI32Bits(-1), u64OfI32Bits(1)], FnOp.lessInt32, [1]);
	testFn([u64OfI32Bits(i32.max), u64OfI32Bits(1)], FnOp.lessInt32, [0]);

	testFn([u64OfI64Bits(-1), u64OfI64Bits(1)], FnOp.lessInt64, [1]);
	testFn([u64OfI64Bits(i64.max), u64OfI64Bits(1)], FnOp.lessInt64, [0]);

	testFn([1, 3], FnOp.lessNat, [1]);
	testFn([1, one], FnOp.lessNat, [0]);

	testFn([u64OfFloat64Bits(1.5), u64OfFloat64Bits(2.6)], FnOp.mulFloat64, [u64OfFloat64Bits(3.9000000000000004)]);

	testFn([1], FnOp.not, [0]);
	testFn([0], FnOp.not, [1]);

	testFn([u64OfFloat64Bits(1.5), u64OfFloat64Bits(2.6)], FnOp.subFloat64, [u64OfFloat64Bits(-1.1)]);

	testFn([u64OfFloat64Bits(-float64.infinity)], FnOp.truncateToInt64FromFloat64, [cast(u64) i64.min]);
	testFn([u64OfFloat64Bits(-9.0)], FnOp.truncateToInt64FromFloat64, [cast(u64) -9]);

	testFn([u64OfFloat64Bits(9.0), u64OfFloat64Bits(5.0)], FnOp.unsafeDivFloat64, [u64OfFloat64Bits(1.8)]);

	testFn([3, 2], FnOp.unsafeDivInt64, [1]);
	testFn([3, cast(u64) -1], FnOp.unsafeDivInt64, [cast(u64) -3]);

	testFn([3, 2], FnOp.unsafeDivNat64, [1]);
	testFn([3, cast(u64) -1], FnOp.unsafeDivNat64, [0]);

	testFn([3, 2], FnOp.unsafeModNat64, [1]);

	testFn([1, 2], FnOp.wrapAddIntegral, [3]);
	testFn([u64.max, 1], FnOp.wrapAddIntegral, [0]);

	testFn([2, 3], FnOp.wrapMulIntegral, [6]);
	ulong i = 0x123456789; // https://issues.dlang.org/show_bug.cgi?id=17778
	testFn([i, i], FnOp.wrapMulIntegral, [0x4b66dc326fb98751]);

	testFn([2, 1], FnOp.wrapSubIntegral, [1]);
	testFn([1, 2], FnOp.wrapSubIntegral, [u64.max]);
}

private:

@trusted void testCompareExchangeStrong() {
	bool b0 = false;
	bool b1 = false;
	immutable u64 b0Ptr = cast(immutable u64) &b0;
	immutable u64 b1Ptr = cast(immutable u64) &b1;
	testFn([b0Ptr, b1Ptr, true], FnOp.compareExchangeStrongBool, [1]);
	verifyEq(b0, true);
	verifyEq(b1, false);

	b0 = false;
	b1 = true;

	testFn([b0Ptr, b1Ptr, true], FnOp.compareExchangeStrongBool, [0]);
	verifyEq(b0, false);
	verifyEq(b1, true);
}

immutable(u64) u64OfI8Bits(immutable i8 a) {
	return cast(u64) (cast(u8) a);
}

immutable(u64) u64OfI16Bits(immutable i16 a) {
	return cast(u64) (cast(u16) a);
}

immutable(u64) u64OfI32Bits(immutable i32 a) {
	return cast(u64) (cast(u32) a);
}

immutable(u64) u64OfI64Bits(immutable i64 a) {
	return cast(u64) a;
}

void testFn(scope immutable u64[] stackIn, immutable FnOp fnOp, scope immutable u64[] stackOut) {
	DataStack dataStack;
	pushAll(dataStack, arrOfD(stackIn));
	applyFn(dataStack, fnOp);
	expectStack(dataStack, stackOut);
	clearStack(dataStack);
}
