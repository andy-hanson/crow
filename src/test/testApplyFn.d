module test.testApplyFn;

@safe @nogc nothrow: // not pure

import interpret.applyFn :
	fnAddFloat32,
	fnAddFloat64,
	fnBitwiseAnd,
	fnBitwiseNot,
	fnBitwiseOr,
	fnCountOnesNat64,
	fnFloat64FromInt64,
	fnFloat64FromNat64,
	fnInt64FromInt16,
	fnInt64FromInt32,
	fnLessFloat32,
	fnLessFloat64,
	fnLessInt8,
	fnLessInt16,
	fnLessInt32,
	fnLessInt64,
	fnLessNat8,
	fnLessNat64,
	fnMulFloat64,
	fnSubFloat64,
	fnTruncateToInt64FromFloat64,
	fnUnsafeBitShiftLeftNat64,
	fnUnsafeBitShiftRightNat64,
	fnUnsafeDivFloat32,
	fnUnsafeDivFloat64,
	fnUnsafeDivInt64,
	fnUnsafeDivNat64,
	fnUnsafeModNat64,
	fnWrapAddIntegral,
	fnWrapMulIntegral,
	fnWrapSubIntegral;
import interpret.bytecode : ByteCodeSource, Operation;
import interpret.bytecodeWriter : ByteCodeWriter, writeFnBinary, writeFnUnary, writePushConstants, writeReturn;
import interpret.stacks : dataPush, Stacks;
import test.testInterpreter : interpreterTest, stepUntilExitAndExpect;
import test.testUtil : Test;
import util.conv : bitsOfFloat32, bitsOfFloat64;

void testApplyFn(ref Test test) {
	ulong one = 1; // https://issues.dlang.org/show_bug.cgi?id=17778
	one += 0;

	testFnBinary(test, &fnAddFloat32, [bitsOfFloat32(-1.5), bitsOfFloat32(2.7)], bitsOfFloat32(1.2));

	testFnBinary(test, &fnAddFloat64, [bitsOfFloat64(-1.5), bitsOfFloat64(2.6)], bitsOfFloat64(1.1));

	testFnUnary(test, &fnBitwiseNot, 0xa, 0xfffffffffffffff5);
	testFnUnary(test, &fnInt64FromInt16, u64OfI16Bits(-1), u64OfI64Bits(-1));
	testFnUnary(test, &fnInt64FromInt32, u64OfI32Bits(-1), u64OfI64Bits(-1));
	testFnBinary(test, &fnUnsafeBitShiftLeftNat64, [0x0123456789abcdef, 4], 0x123456789abcdef0);
	testFnBinary(test, &fnUnsafeBitShiftRightNat64, [0x0123456789abcdef, 4], 0x00123456789abcde);

	testFnBinary(test, &fnBitwiseAnd, [0b0101, 0b0011], 0b0001);
	testFnBinary(test, &fnBitwiseOr, [0b0101, 0b0011], 0b0111);

	testFnUnary(test, &fnCountOnesNat64, 0b10101, 3);

	testFnUnary(test, &fnFloat64FromInt64, u64OfI64Bits(-1), bitsOfFloat64(-1.0));

	testFnUnary(test, &fnFloat64FromNat64, 1, bitsOfFloat64(1.0));

	testFnBinary(test, &fnLessFloat32, [bitsOfFloat32(-1.0), bitsOfFloat32(1.0)], 1);
	testFnBinary(test, &fnLessFloat32, [bitsOfFloat32(1.0), bitsOfFloat32(-1.0)], 0);

	testFnBinary(test, &fnLessFloat64, [bitsOfFloat64(-1.0), bitsOfFloat64(1.0)], 1);
	testFnBinary(test, &fnLessFloat64, [bitsOfFloat64(1.0), bitsOfFloat64(-1.0)], 0);

	assert(u64OfI8Bits(-1) == 0xff);

	testFnBinary(test, &fnLessInt8, [u64OfI8Bits(-1), u64OfI8Bits(1)], 1);

	assert(u64OfI16Bits(-1) == 0xffff);

	testFnBinary(test, &fnLessInt16, [u64OfI16Bits(-1), u64OfI16Bits(1)], 1);

	assert(u64OfI32Bits(-1) == 0x00000000ffffffff);

	testFnBinary(test, &fnLessInt32, [u64OfI32Bits(-1), u64OfI32Bits(1)], 1);
	testFnBinary(test, &fnLessInt32, [u64OfI32Bits(int.max), u64OfI32Bits(1)], 0);

	testFnBinary(test, &fnLessInt64, [u64OfI64Bits(-1), u64OfI64Bits(1)], 1);
	testFnBinary(test, &fnLessInt64, [u64OfI64Bits(long.max), u64OfI64Bits(1)], 0);

	testFnBinary(test, &fnLessNat64, [1, 3], 1);
	testFnBinary(test, &fnLessNat64, [1, one], 0);
	testFnBinary(test, &fnLessNat64, [256, 1], 0);
	testFnBinary(test, &fnLessNat8, [256, 1], 1);

	testFnBinary(
		test, &fnMulFloat64,
		[bitsOfFloat64(1.5), bitsOfFloat64(2.6)],
		bitsOfFloat64(3.9000000000000004));

	testFnBinary(test, &fnSubFloat64, [bitsOfFloat64(1.5), bitsOfFloat64(2.6)], bitsOfFloat64(-1.1));

	testFnUnary(test, &fnTruncateToInt64FromFloat64, bitsOfFloat64(-double.infinity), u64OfI64Bits(long.min));
	testFnUnary(test, &fnTruncateToInt64FromFloat64, bitsOfFloat64(-9.0), u64OfI64Bits(-9));

	testFnBinary(test, &fnUnsafeDivFloat32, [bitsOfFloat32(9.0), bitsOfFloat32(5.0)], bitsOfFloat32(1.8));
	testFnBinary(test, &fnUnsafeDivFloat64, [bitsOfFloat64(9.0), bitsOfFloat64(5.0)], bitsOfFloat64(1.8));

	testFnBinary(test, &fnUnsafeDivInt64, [u64OfI64Bits(3), u64OfI64Bits(2)], u64OfI64Bits(1));
	testFnBinary(test, &fnUnsafeDivInt64, [u64OfI64Bits(3), u64OfI64Bits(-1)], u64OfI64Bits(-3));

	testFnBinary(test, &fnUnsafeDivNat64, [3, 2], 1);
	testFnBinary(test, &fnUnsafeDivNat64, [3, ulong.max], 0);

	testFnBinary(test, &fnUnsafeModNat64, [3, 2], 1);

	testFnBinary(test, &fnWrapAddIntegral, [1, 2], 3);
	testFnBinary(test, &fnWrapAddIntegral, [ulong.max, 1], 0);

	testFnBinary(test, &fnWrapMulIntegral, [2, 3], 6);
	ulong i = 0x123456789; // https://issues.dlang.org/show_bug.cgi?id=17778
	i += 0;
	testFnBinary(test, &fnWrapMulIntegral, [i, i], 0x4b66dc326fb98751);

	testFnBinary(test, &fnWrapSubIntegral, [2, 1], 1);
	testFnBinary(test, &fnWrapSubIntegral, [1, 2], ulong.max);
}

private:

ulong u64OfI8Bits(byte a) =>
	cast(ulong) (cast(ubyte) a);

ulong u64OfI16Bits(short a) =>
	cast(ulong) (cast(ushort) a);

ulong u64OfI32Bits(int a) =>
	cast(ulong) (cast(uint) a);

ulong u64OfI64Bits(long a) =>
	cast(ulong) a;

@trusted void testFnBinary(ref Test test, Operation.Fn fn, ulong[2] stackIn, ulong stackOut) {
	interpreterTest(
		test,
		(scope ref ByteCodeWriter writer, ByteCodeSource source) {
			writePushConstants(writer, source, stackIn);
			writeFnBinary(writer, source, fn);
			writeReturn(writer, source);
		},
		(scope ref Stacks stacks, Operation* cur) {
			stepUntilExitAndExpect(test, stacks, [stackOut], cur);
		});
}

@trusted void testFnUnary(ref Test test, Operation.Fn fn, ulong stackIn, ulong stackOut) {
	interpreterTest(
		test,
		(scope ref ByteCodeWriter writer, ByteCodeSource source) {
			writeFnUnary(writer, source, fn);
			writeReturn(writer, source);
		},
		(scope ref Stacks stacks, Operation* cur) {
			dataPush(stacks, stackIn);
			stepUntilExitAndExpect(test, stacks, [stackOut], cur);
		});
}
