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
import util.util : verify;

void testApplyFn(ref Test test) {
	ulong one = 1; // https://issues.dlang.org/show_bug.cgi?id=17778
	one += 0;

	testFnBinary!fnAddFloat32(test, [bitsOfFloat32(-1.5), bitsOfFloat32(2.7)], bitsOfFloat32(1.2));

	testFnBinary!fnAddFloat64(test, [bitsOfFloat64(-1.5), bitsOfFloat64(2.6)], bitsOfFloat64(1.1));

	testFnUnary!fnBitwiseNot(test, 0xa, 0xfffffffffffffff5);
	testFnUnary!fnInt64FromInt16(test, u64OfI16Bits(-1), u64OfI64Bits(-1));
	testFnUnary!fnInt64FromInt32(test, u64OfI32Bits(-1), u64OfI64Bits(-1));
	testFnBinary!fnUnsafeBitShiftLeftNat64(test, [0x0123456789abcdef, 4], 0x123456789abcdef0);
	testFnBinary!fnUnsafeBitShiftRightNat64(test, [0x0123456789abcdef, 4], 0x00123456789abcde);

	testFnBinary!fnBitwiseAnd(test, [0b0101, 0b0011], 0b0001);
	testFnBinary!fnBitwiseOr(test, [0b0101, 0b0011], 0b0111);

	testFnUnary!fnCountOnesNat64(test, 0b10101, 3);

	testFnUnary!fnFloat64FromInt64(test, u64OfI64Bits(-1), bitsOfFloat64(-1.0));

	testFnUnary!fnFloat64FromNat64(test, 1, bitsOfFloat64(1.0));

	testFnBinary!fnLessFloat32(test, [bitsOfFloat32(-1.0), bitsOfFloat32(1.0)], 1);
	testFnBinary!fnLessFloat32(test, [bitsOfFloat32(1.0), bitsOfFloat32(-1.0)], 0);

	testFnBinary!fnLessFloat64(test, [bitsOfFloat64(-1.0), bitsOfFloat64(1.0)], 1);
	testFnBinary!fnLessFloat64(test, [bitsOfFloat64(1.0), bitsOfFloat64(-1.0)], 0);

	verify(u64OfI8Bits(-1) == 0xff);

	testFnBinary!fnLessInt8(test, [u64OfI8Bits(-1), u64OfI8Bits(1)], 1);

	verify(u64OfI16Bits(-1) == 0xffff);

	testFnBinary!fnLessInt16(test, [u64OfI16Bits(-1), u64OfI16Bits(1)], 1);

	verify(u64OfI32Bits(-1) == 0x00000000ffffffff);

	testFnBinary!fnLessInt32(test, [u64OfI32Bits(-1), u64OfI32Bits(1)], 1);
	testFnBinary!fnLessInt32(test, [u64OfI32Bits(int.max), u64OfI32Bits(1)], 0);

	testFnBinary!fnLessInt64(test, [u64OfI64Bits(-1), u64OfI64Bits(1)], 1);
	testFnBinary!fnLessInt64(test, [u64OfI64Bits(long.max), u64OfI64Bits(1)], 0);

	testFnBinary!fnLessNat64(test, [1, 3], 1);
	testFnBinary!fnLessNat64(test, [1, one], 0);
	testFnBinary!fnLessNat64(test, [256, 1], 0);
	testFnBinary!fnLessNat8(test, [256, 1], 1);

	testFnBinary!fnMulFloat64(
		test,
		[bitsOfFloat64(1.5), bitsOfFloat64(2.6)],
		bitsOfFloat64(3.9000000000000004));

	testFnBinary!fnSubFloat64(test, [bitsOfFloat64(1.5), bitsOfFloat64(2.6)], bitsOfFloat64(-1.1));

	testFnUnary!fnTruncateToInt64FromFloat64(test, bitsOfFloat64(-double.infinity), u64OfI64Bits(long.min));
	testFnUnary!fnTruncateToInt64FromFloat64(test, bitsOfFloat64(-9.0), u64OfI64Bits(-9));

	testFnBinary!fnUnsafeDivFloat32(test, [bitsOfFloat32(9.0), bitsOfFloat32(5.0)], bitsOfFloat32(1.8));
	testFnBinary!fnUnsafeDivFloat64(test, [bitsOfFloat64(9.0), bitsOfFloat64(5.0)], bitsOfFloat64(1.8));

	testFnBinary!fnUnsafeDivInt64(test, [u64OfI64Bits(3), u64OfI64Bits(2)], u64OfI64Bits(1));
	testFnBinary!fnUnsafeDivInt64(test, [u64OfI64Bits(3), u64OfI64Bits(-1)], u64OfI64Bits(-3));

	testFnBinary!fnUnsafeDivNat64(test, [3, 2], 1);
	testFnBinary!fnUnsafeDivNat64(test, [3, ulong.max], 0);

	testFnBinary!fnUnsafeModNat64(test, [3, 2], 1);

	testFnBinary!fnWrapAddIntegral(test, [1, 2], 3);
	testFnBinary!fnWrapAddIntegral(test, [ulong.max, 1], 0);

	testFnBinary!fnWrapMulIntegral(test, [2, 3], 6);
	ulong i = 0x123456789; // https://issues.dlang.org/show_bug.cgi?id=17778
	i += 0;
	testFnBinary!fnWrapMulIntegral(test, [i, i], 0x4b66dc326fb98751);

	testFnBinary!fnWrapSubIntegral(test, [2, 1], 1);
	testFnBinary!fnWrapSubIntegral(test, [1, 2], ulong.max);
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

@trusted void testFnBinary(alias fn)(ref Test test, ulong[2] stackIn, ulong stackOut) {
	interpreterTest(
		test,
		(scope ref ByteCodeWriter writer, ByteCodeSource source) {
			writePushConstants(writer, source, stackIn);
			writeFnBinary!fn(writer, source);
			writeReturn(writer, source);
		},
		(scope ref Stacks stacks, Operation* cur) {
			stepUntilExitAndExpect(test, stacks, [stackOut], cur);
		});
}

@trusted void testFnUnary(alias fn)(ref Test test, ulong stackIn, ulong stackOut) {
	interpreterTest(
		test,
		(scope ref ByteCodeWriter writer, ByteCodeSource source) {
			writeFnUnary!fn(writer, source);
			writeReturn(writer, source);
		},
		(scope ref Stacks stacks, Operation* cur) {
			dataPush(stacks, stackIn);
			stepUntilExitAndExpect(test, stacks, [stackOut], cur);
		});
}
