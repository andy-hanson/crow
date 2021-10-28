module test.testApplyFn;

@safe @nogc nothrow: // not pure (DataStack constructor)

import interpret.applyFn : applyFn;
import interpret.bytecode : FnOp;
import interpret.runBytecode : DataStack;
import test.testUtil : expectDataStack, Test;
import util.collection.globalAllocatedStack : clearStack, pushAll;
import util.types : Nat64, u64OfFloat32Bits, u64OfFloat64Bits;
import util.util : verify,verifyEq;

void testApplyFn(ref Test test) {
	immutable Nat64 one = immutable Nat64(1); // https://issues.dlang.org/show_bug.cgi?id=17778

	testFn(test, [u64OfFloat32Bits(-1.5), u64OfFloat32Bits(2.7)], FnOp.addFloat32, [u64OfFloat32Bits(1.2)]);
	testFn(test, [u64OfFloat64Bits(-1.5), u64OfFloat64Bits(2.6)], FnOp.addFloat64, [u64OfFloat64Bits(1.1)]);

	testFn(test, [immutable Nat64(0xa)], FnOp.bitwiseNot, [immutable Nat64(0xfffffffffffffff5)]);

	testFn(test, [u64OfI16Bits(-1)], FnOp.intFromInt16, [u64OfI64Bits(-1)]);

	testFn(test, [u64OfI32Bits(-1)], FnOp.intFromInt32, [u64OfI64Bits(-1)]);

	testFn(
		test,
		[immutable Nat64(0x0123456789abcdef), immutable Nat64(4)],
		FnOp.unsafeBitShiftLeftNat64,
		[immutable Nat64(0x123456789abcdef0)]);
	testFn(
		test,
		[immutable Nat64(0x0123456789abcdef), immutable Nat64(4)],
		FnOp.unsafeBitShiftRightNat64,
		[immutable Nat64(0x00123456789abcde)]);

	testFn(test, [immutable Nat64(0b0101), immutable Nat64(0b0011)], FnOp.bitwiseAnd, [immutable Nat64(0b0001)]);
	testFn(test, [immutable Nat64(0b0101), immutable Nat64(0b0011)], FnOp.bitwiseOr, [immutable Nat64(0b0111)]);

	testCompareExchangeStrong(test);

	testFn(
		test,
		[immutable Nat64(0b10101)],
		FnOp.countOnesNat64,
		[immutable Nat64(3)]);

	testFn(test, [u64OfI64Bits(-1)], FnOp.float64FromInt64, [u64OfFloat64Bits(-1.0)]);

	testFn(test, [immutable Nat64(1)], FnOp.float64FromNat64, [u64OfFloat64Bits(1.0)]);

	testFn(test, [u64OfFloat32Bits(-1.0), u64OfFloat32Bits(1.0)], FnOp.lessFloat32, [immutable Nat64(1)]);
	testFn(test, [u64OfFloat32Bits(1.0), u64OfFloat32Bits(-1.0)], FnOp.lessFloat32, [immutable Nat64(0)]);

	testFn(test, [u64OfFloat64Bits(-1.0), u64OfFloat64Bits(1.0)], FnOp.lessFloat64, [immutable Nat64(1)]);
	testFn(test, [u64OfFloat64Bits(1.0), u64OfFloat64Bits(-1.0)], FnOp.lessFloat64, [immutable Nat64(0)]);

	verify(u64OfI8Bits(-1) == immutable Nat64(0xff));

	testFn(test, [u64OfI8Bits(-1), u64OfI8Bits(1)], FnOp.lessInt8, [immutable Nat64(1)]);

	verify(u64OfI16Bits(-1) == immutable Nat64(0xffff));

	testFn(test, [u64OfI16Bits(-1), u64OfI16Bits(1)], FnOp.lessInt16, [immutable Nat64(1)]);

	verify(u64OfI32Bits(-1) == immutable Nat64(0x00000000ffffffff));

	testFn(test, [u64OfI32Bits(-1), u64OfI32Bits(1)], FnOp.lessInt32, [immutable Nat64(1)]);
	testFn(test, [u64OfI32Bits(int.max), u64OfI32Bits(1)], FnOp.lessInt32, [immutable Nat64(0)]);

	testFn(test, [u64OfI64Bits(-1), u64OfI64Bits(1)], FnOp.lessInt64, [immutable Nat64(1)]);
	testFn(test, [u64OfI64Bits(long.max), u64OfI64Bits(1)], FnOp.lessInt64, [immutable Nat64(0)]);

	testFn(test, [immutable Nat64(1), immutable Nat64(3)], FnOp.lessNat, [immutable Nat64(1)]);
	testFn(test, [immutable Nat64(1), one], FnOp.lessNat, [immutable Nat64(0)]);

	testFn(
		test,
		[u64OfFloat64Bits(1.5), u64OfFloat64Bits(2.6)],
		FnOp.mulFloat64,
		[u64OfFloat64Bits(3.9000000000000004)]);

	testFn(test, [u64OfFloat64Bits(1.5), u64OfFloat64Bits(2.6)], FnOp.subFloat64, [u64OfFloat64Bits(-1.1)]);

	testFn(test, [u64OfFloat64Bits(-double.infinity)], FnOp.truncateToInt64FromFloat64, [u64OfI64Bits(long.min)]);
	testFn(test, [u64OfFloat64Bits(-9.0)], FnOp.truncateToInt64FromFloat64, [u64OfI64Bits(-9)]);

	testFn(test, [u64OfFloat32Bits(9.0), u64OfFloat32Bits(5.0)], FnOp.unsafeDivFloat32, [u64OfFloat32Bits(1.8)]);
	testFn(test, [u64OfFloat64Bits(9.0), u64OfFloat64Bits(5.0)], FnOp.unsafeDivFloat64, [u64OfFloat64Bits(1.8)]);

	testFn(test, [u64OfI64Bits(3), u64OfI64Bits(2)], FnOp.unsafeDivInt64, [u64OfI64Bits(1)]);
	testFn(test, [u64OfI64Bits(3), u64OfI64Bits(-1)], FnOp.unsafeDivInt64, [u64OfI64Bits(-3)]);

	testFn(test, [immutable Nat64(3), immutable Nat64(2)], FnOp.unsafeDivNat64, [immutable Nat64(1)]);
	testFn(test, [immutable Nat64(3), Nat64.max], FnOp.unsafeDivNat64, [immutable Nat64(0)]);

	testFn(test, [immutable Nat64(3), immutable Nat64(2)], FnOp.unsafeModNat64, [immutable Nat64(1)]);

	testFn(test, [immutable Nat64(1), immutable Nat64(2)], FnOp.wrapAddIntegral, [immutable Nat64(3)]);
	testFn(test, [Nat64.max, immutable Nat64(1)], FnOp.wrapAddIntegral, [immutable Nat64(0)]);

	testFn(test, [immutable Nat64(2), immutable Nat64(3)], FnOp.wrapMulIntegral, [immutable Nat64(6)]);
	immutable Nat64 i = immutable Nat64(0x123456789); // https://issues.dlang.org/show_bug.cgi?id=17778
	testFn(test, [i, i], FnOp.wrapMulIntegral, [immutable Nat64(0x4b66dc326fb98751)]);

	testFn(test, [immutable Nat64(2), immutable Nat64(1)], FnOp.wrapSubIntegral, [immutable Nat64(1)]);
	testFn(test, [immutable Nat64(1), immutable Nat64(2)], FnOp.wrapSubIntegral, [Nat64.max]);
}

private:

@trusted void testCompareExchangeStrong(ref Test test) {
	bool b0 = false;
	bool b1 = false;
	immutable Nat64 b0Ptr = immutable Nat64(cast(immutable ulong) &b0);
	immutable Nat64 b1Ptr = immutable Nat64(cast(immutable ulong) &b1);
	testFn(test, [b0Ptr, b1Ptr, immutable Nat64(1)], FnOp.compareExchangeStrongBool, [immutable Nat64(1)]);
	verifyEq(b0, true);
	verifyEq(b1, false);

	b0 = false;
	b1 = true;

	testFn(test, [b0Ptr, b1Ptr, immutable Nat64(1)], FnOp.compareExchangeStrongBool, [immutable Nat64(0)]);
	verifyEq(b0, false);
	verifyEq(b1, true);
}

immutable(Nat64) u64OfI8Bits(immutable byte a) {
	return immutable Nat64(cast(ulong) (cast(ubyte) a));
}

immutable(Nat64) u64OfI16Bits(immutable short a) {
	return immutable Nat64(cast(ulong) (cast(ushort) a));
}

immutable(Nat64) u64OfI32Bits(immutable int a) {
	return immutable Nat64(cast(ulong) (cast(uint) a));
}

immutable(Nat64) u64OfI64Bits(immutable long a) {
	return immutable Nat64(cast(ulong) a);
}

void testFn(
	ref Test test,
	scope immutable Nat64[] stackIn,
	immutable FnOp fnOp,
	scope immutable Nat64[] stackOut,
) {
	DataStack dataStack = DataStack(true);
	pushAll(dataStack, stackIn);
	applyFn(test.dbg, dataStack, fnOp);
	expectDataStack(test, dataStack, stackOut);
	clearStack(dataStack);
}
