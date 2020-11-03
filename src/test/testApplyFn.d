module test.testApplyFn;

@safe @nogc nothrow: // not pure (DataStack uses globals)

import interpret.applyFn : applyFn;
import interpret.bytecode : FnOp;
import interpret.runBytecode : DataStack;
import test.testUtil : expectDataStack;
import util.collection.arr : arrOfD;
import util.collection.globalAllocatedStack : clearStack, pushAll;
import util.types : float64, i8, i16, i32, i64, Nat64, u8, u16, u32, u64, u64OfFloat64Bits;
import util.util : verify,verifyEq;

void testApplyFn() {
	immutable Nat64 one = immutable Nat64(1); // https://issues.dlang.org/show_bug.cgi?id=17778

	testFn([u64OfFloat64Bits(-1.5), u64OfFloat64Bits(2.6)], FnOp.addFloat64, [u64OfFloat64Bits(1.1)]);

	testFn([u64OfI16Bits(-1)], FnOp.intFromInt16, [u64OfI64Bits(-1)]);

	testFn([u64OfI32Bits(-1)], FnOp.intFromInt32, [u64OfI64Bits(-1)]);

	testFn(
		[immutable Nat64(0x0123456789abcdef), immutable Nat64(4)],
		FnOp.unsafeBitShiftLeftNat64,
		[immutable Nat64(0x123456789abcdef0)]);
	testFn(
		[immutable Nat64(0x0123456789abcdef), immutable Nat64(4)],
		FnOp.unsafeBitShiftRightNat64,
		[immutable Nat64(0x00123456789abcde)]);

	testFn([immutable Nat64(0b0101), immutable Nat64(0b0011)], FnOp.bitwiseAnd, [immutable Nat64(0b0001)]);
	testFn([immutable Nat64(0b0101), immutable Nat64(0b0011)], FnOp.bitwiseOr, [immutable Nat64(0b0111)]);

	testCompareExchangeStrong();

	testFn([u64OfI64Bits(-1)], FnOp.float64FromInt64, [u64OfFloat64Bits(-1.0)]);

	testFn([immutable Nat64(1)], FnOp.float64FromNat64, [u64OfFloat64Bits(1.0)]);

	testFn([u64OfFloat64Bits(-1.0), u64OfFloat64Bits(1.0)], FnOp.lessFloat64, [immutable Nat64(1)]);
	testFn([u64OfFloat64Bits(1.0), u64OfFloat64Bits(-1.0)], FnOp.lessFloat64, [immutable Nat64(0)]);

	verify(u64OfI8Bits(-1) == immutable Nat64(0xff));

	testFn([u64OfI8Bits(-1), u64OfI8Bits(1)], FnOp.lessInt8, [immutable Nat64(1)]);

	verify(u64OfI16Bits(-1) == immutable Nat64(0xffff));

	testFn([u64OfI16Bits(-1), u64OfI16Bits(1)], FnOp.lessInt16, [immutable Nat64(1)]);

	verify(u64OfI32Bits(-1) == immutable Nat64(0x00000000ffffffff));

	testFn([u64OfI32Bits(-1), u64OfI32Bits(1)], FnOp.lessInt32, [immutable Nat64(1)]);
	testFn([u64OfI32Bits(i32.max), u64OfI32Bits(1)], FnOp.lessInt32, [immutable Nat64(0)]);

	testFn([u64OfI64Bits(-1), u64OfI64Bits(1)], FnOp.lessInt64, [immutable Nat64(1)]);
	testFn([u64OfI64Bits(i64.max), u64OfI64Bits(1)], FnOp.lessInt64, [immutable Nat64(0)]);

	testFn([immutable Nat64(1), immutable Nat64(3)], FnOp.lessNat, [immutable Nat64(1)]);
	testFn([immutable Nat64(1), one], FnOp.lessNat, [immutable Nat64(0)]);

	testFn([u64OfFloat64Bits(1.5), u64OfFloat64Bits(2.6)], FnOp.mulFloat64, [u64OfFloat64Bits(3.9000000000000004)]);

	testFn([immutable Nat64(1)], FnOp.not, [immutable Nat64(0)]);
	testFn([immutable Nat64(0)], FnOp.not, [immutable Nat64(1)]);

	testFn([u64OfFloat64Bits(1.5), u64OfFloat64Bits(2.6)], FnOp.subFloat64, [u64OfFloat64Bits(-1.1)]);

	testFn([u64OfFloat64Bits(-float64.infinity)], FnOp.truncateToInt64FromFloat64, [u64OfI64Bits(i64.min)]);
	testFn([u64OfFloat64Bits(-9.0)], FnOp.truncateToInt64FromFloat64, [u64OfI64Bits(-9)]);

	testFn([u64OfFloat64Bits(9.0), u64OfFloat64Bits(5.0)], FnOp.unsafeDivFloat64, [u64OfFloat64Bits(1.8)]);

	testFn([u64OfI64Bits(3), u64OfI64Bits(2)], FnOp.unsafeDivInt64, [u64OfI64Bits(1)]);
	testFn([u64OfI64Bits(3), u64OfI64Bits(-1)], FnOp.unsafeDivInt64, [u64OfI64Bits(-3)]);

	testFn([immutable Nat64(3), immutable Nat64(2)], FnOp.unsafeDivNat64, [immutable Nat64(1)]);
	testFn([immutable Nat64(3), Nat64.max], FnOp.unsafeDivNat64, [immutable Nat64(0)]);

	testFn([immutable Nat64(3), immutable Nat64(2)], FnOp.unsafeModNat64, [immutable Nat64(1)]);

	testFn([immutable Nat64(1), immutable Nat64(2)], FnOp.wrapAddIntegral, [immutable Nat64(3)]);
	testFn([Nat64.max, immutable Nat64(1)], FnOp.wrapAddIntegral, [immutable Nat64(0)]);

	testFn([immutable Nat64(2), immutable Nat64(3)], FnOp.wrapMulIntegral, [immutable Nat64(6)]);
	immutable Nat64 i = immutable Nat64(0x123456789); // https://issues.dlang.org/show_bug.cgi?id=17778
	testFn([i, i], FnOp.wrapMulIntegral, [immutable Nat64(0x4b66dc326fb98751)]);

	testFn([immutable Nat64(2), immutable Nat64(1)], FnOp.wrapSubIntegral, [immutable Nat64(1)]);
	testFn([immutable Nat64(1), immutable Nat64(2)], FnOp.wrapSubIntegral, [Nat64.max]);
}

private:

@trusted void testCompareExchangeStrong() {
	bool b0 = false;
	bool b1 = false;
	immutable Nat64 b0Ptr = immutable Nat64(cast(immutable u64) &b0);
	immutable Nat64 b1Ptr = immutable Nat64(cast(immutable u64) &b1);
	testFn([b0Ptr, b1Ptr, immutable Nat64(1)], FnOp.compareExchangeStrongBool, [immutable Nat64(1)]);
	verifyEq(b0, true);
	verifyEq(b1, false);

	b0 = false;
	b1 = true;

	testFn([b0Ptr, b1Ptr, immutable Nat64(1)], FnOp.compareExchangeStrongBool, [immutable Nat64(0)]);
	verifyEq(b0, false);
	verifyEq(b1, true);
}

immutable(Nat64) u64OfI8Bits(immutable i8 a) {
	return immutable Nat64(cast(u64) (cast(u8) a));
}

immutable(Nat64) u64OfI16Bits(immutable i16 a) {
	return immutable Nat64(cast(u64) (cast(u16) a));
}

immutable(Nat64) u64OfI32Bits(immutable i32 a) {
	return immutable Nat64(cast(u64) (cast(u32) a));
}

immutable(Nat64) u64OfI64Bits(immutable i64 a) {
	return immutable Nat64(cast(u64) a);
}

void testFn(scope immutable Nat64[] stackIn, immutable FnOp fnOp, scope immutable Nat64[] stackOut) {
	DataStack dataStack;
	pushAll(dataStack, arrOfD(stackIn));
	applyFn(dataStack, fnOp);
	expectDataStack(dataStack, stackOut);
	clearStack(dataStack);
}
