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
	fnLessNat,
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
import interpret.bytecodeWriter : ByteCodeWriter, writeFnBinary, writeFnUnary, writeReturn;
import interpret.runBytecode : Interpreter;
import test.testInterpreter : interpreterTest, stepAndExpect, stepExit;
import test.testUtil : Test;
import util.collection.stack : push;
import util.types : Nat64, u64OfFloat32Bits, u64OfFloat64Bits;
import util.util : verify;

void testApplyFn(ref Test test) {
	immutable Nat64 one = immutable Nat64(1); // https://issues.dlang.org/show_bug.cgi?id=17778

	testFnBinary!fnAddFloat32(test, [u64OfFloat32Bits(-1.5), u64OfFloat32Bits(2.7)], u64OfFloat32Bits(1.2));
	testFnBinary!fnAddFloat64(test, [u64OfFloat64Bits(-1.5), u64OfFloat64Bits(2.6)], u64OfFloat64Bits(1.1));

	testFnUnary!fnBitwiseNot(test, immutable Nat64(0xa), immutable Nat64(0xfffffffffffffff5));
	testFnUnary!fnInt64FromInt16(test, u64OfI16Bits(-1), u64OfI64Bits(-1));
	testFnUnary!fnInt64FromInt32(test, u64OfI32Bits(-1), u64OfI64Bits(-1));
	testFnBinary!fnUnsafeBitShiftLeftNat64(
		test,
		[immutable Nat64(0x0123456789abcdef), immutable Nat64(4)],
		immutable Nat64(0x123456789abcdef0));
	testFnBinary!fnUnsafeBitShiftRightNat64(
		test,
		[immutable Nat64(0x0123456789abcdef), immutable Nat64(4)],
		immutable Nat64(0x00123456789abcde));

	testFnBinary!fnBitwiseAnd(test, [immutable Nat64(0b0101), immutable Nat64(0b0011)], immutable Nat64(0b0001));
	testFnBinary!fnBitwiseOr(test, [immutable Nat64(0b0101), immutable Nat64(0b0011)], immutable Nat64(0b0111));

	testFnUnary!fnCountOnesNat64(test, immutable Nat64(0b10101), immutable Nat64(3));

	testFnUnary!fnFloat64FromInt64(test, u64OfI64Bits(-1), u64OfFloat64Bits(-1.0));

	testFnUnary!fnFloat64FromNat64(test, immutable Nat64(1), u64OfFloat64Bits(1.0));

	testFnBinary!fnLessFloat32(test, [u64OfFloat32Bits(-1.0), u64OfFloat32Bits(1.0)], immutable Nat64(1));
	testFnBinary!fnLessFloat32(test, [u64OfFloat32Bits(1.0), u64OfFloat32Bits(-1.0)], immutable Nat64(0));

	testFnBinary!fnLessFloat64(test, [u64OfFloat64Bits(-1.0), u64OfFloat64Bits(1.0)], immutable Nat64(1));
	testFnBinary!fnLessFloat64(test, [u64OfFloat64Bits(1.0), u64OfFloat64Bits(-1.0)], immutable Nat64(0));

	verify(u64OfI8Bits(-1) == immutable Nat64(0xff));

	testFnBinary!fnLessInt8(test, [u64OfI8Bits(-1), u64OfI8Bits(1)], immutable Nat64(1));

	verify(u64OfI16Bits(-1) == immutable Nat64(0xffff));

	testFnBinary!fnLessInt16(test, [u64OfI16Bits(-1), u64OfI16Bits(1)], immutable Nat64(1));

	verify(u64OfI32Bits(-1) == immutable Nat64(0x00000000ffffffff));

	testFnBinary!fnLessInt32(test, [u64OfI32Bits(-1), u64OfI32Bits(1)], immutable Nat64(1));
	testFnBinary!fnLessInt32(test, [u64OfI32Bits(int.max), u64OfI32Bits(1)], immutable Nat64(0));

	testFnBinary!fnLessInt64(test, [u64OfI64Bits(-1), u64OfI64Bits(1)], immutable Nat64(1));
	testFnBinary!fnLessInt64(test, [u64OfI64Bits(long.max), u64OfI64Bits(1)], immutable Nat64(0));

	testFnBinary!fnLessNat(test, [immutable Nat64(1), immutable Nat64(3)], immutable Nat64(1));
	testFnBinary!fnLessNat(test, [immutable Nat64(1), one], immutable Nat64(0));

	testFnBinary!fnMulFloat64(
		test,
		[u64OfFloat64Bits(1.5), u64OfFloat64Bits(2.6)],
		u64OfFloat64Bits(3.9000000000000004));

	testFnBinary!fnSubFloat64(test, [u64OfFloat64Bits(1.5), u64OfFloat64Bits(2.6)], u64OfFloat64Bits(-1.1));

	testFnUnary!fnTruncateToInt64FromFloat64(test, u64OfFloat64Bits(-double.infinity), u64OfI64Bits(long.min));
	testFnUnary!fnTruncateToInt64FromFloat64(test, u64OfFloat64Bits(-9.0), u64OfI64Bits(-9));

	testFnBinary!fnUnsafeDivFloat32(test, [u64OfFloat32Bits(9.0), u64OfFloat32Bits(5.0)], u64OfFloat32Bits(1.8));
	testFnBinary!fnUnsafeDivFloat64(test, [u64OfFloat64Bits(9.0), u64OfFloat64Bits(5.0)], u64OfFloat64Bits(1.8));

	testFnBinary!fnUnsafeDivInt64(test, [u64OfI64Bits(3), u64OfI64Bits(2)], u64OfI64Bits(1));
	testFnBinary!fnUnsafeDivInt64(test, [u64OfI64Bits(3), u64OfI64Bits(-1)], u64OfI64Bits(-3));

	testFnBinary!fnUnsafeDivNat64(test, [immutable Nat64(3), immutable Nat64(2)], immutable Nat64(1));
	testFnBinary!fnUnsafeDivNat64(test, [immutable Nat64(3), Nat64.max], immutable Nat64(0));

	testFnBinary!fnUnsafeModNat64(test, [immutable Nat64(3), immutable Nat64(2)], immutable Nat64(1));

	testFnBinary!fnWrapAddIntegral(test, [immutable Nat64(1), immutable Nat64(2)], immutable Nat64(3));
	testFnBinary!fnWrapAddIntegral(test, [Nat64.max, immutable Nat64(1)], immutable Nat64(0));

	testFnBinary!fnWrapMulIntegral(test, [immutable Nat64(2), immutable Nat64(3)], immutable Nat64(6));
	immutable Nat64 i = immutable Nat64(0x123456789); // https://issues.dlang.org/show_bug.cgi?id=17778
	testFnBinary!fnWrapMulIntegral(test, [i, i], immutable Nat64(0x4b66dc326fb98751));

	testFnBinary!fnWrapSubIntegral(test, [immutable Nat64(2), immutable Nat64(1)], immutable Nat64(1));
	testFnBinary!fnWrapSubIntegral(test, [immutable Nat64(1), immutable Nat64(2)], Nat64.max);
}

private:

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

@trusted void testFnBinary(alias fn)(
	ref Test test,
	scope immutable Nat64[2] stackIn,
	scope immutable Nat64 stackOut,
) {
	interpreterTest(
		test,
		(ref ByteCodeWriter writer, immutable ByteCodeSource source) {
			writeFnBinary!fn(test.dbg, writer, source);
			writeReturn(test.dbg, writer, source);
		},
		(scope ref Interpreter interpreter, immutable(Operation)* cur) {
			foreach (immutable Nat64 x; stackIn)
				push(interpreter.dataStack, x);
			cur = stepAndExpect(test, interpreter, [stackOut], cur);
			stepExit(test, interpreter, cur);
		});
}

@trusted void testFnUnary(alias fn)(
	ref Test test,
	scope immutable Nat64 stackIn,
	scope immutable Nat64 stackOut,
) {
	interpreterTest(
		test,
		(ref ByteCodeWriter writer, immutable ByteCodeSource source) {
			writeFnUnary!fn(writer, source);
			writeReturn(test.dbg, writer, source);
		},
		(scope ref Interpreter interpreter, immutable(Operation)* cur) {
			push(interpreter.dataStack, stackIn);
			cur = stepAndExpect(test, interpreter, [stackOut], cur);
			stepExit(test, interpreter, cur);
		});
}
