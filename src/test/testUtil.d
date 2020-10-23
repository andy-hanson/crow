module test.testUtil;

@safe @nogc nothrow: // not pure

import core.stdc.stdio : printf;
import interpret.bytecode : ByteCodeIndex;
import interpret.runBytecode : byteCodeIndexOfPtr, DataStack, Interpreter, printDataArr;
import util.bools : Bool;
import util.collection.arr : Arr, arrOfD, range, sizeEq;
import util.collection.arrUtil : eachCorresponds;
import util.collection.globalAllocatedStack : asTempArr;
import util.types : Nat64, u8, u64;
import util.util : todo, verify;

void expectDataStack(ref const DataStack dataStack, scope immutable Nat64[] expected) {
	immutable Arr!Nat64 stack = asTempArr(dataStack);
	immutable Arr!Nat64 expectedArr = arrOfD(expected);
	immutable Bool eq = immutable Bool(
		sizeEq(stack, expectedArr) &&
		eachCorresponds!(Nat64, Nat64)(stack, expectedArr, (ref immutable Nat64 a, ref immutable Nat64 b) =>
			immutable Bool(a == b)));
	if (!eq) {
		debug {
			printf("expected:\n");
			printDataArr(expectedArr);
			printf("\nactual:\n");
			printDataArr(stack);
		}
		verify(false);
	}
}

void expectReturnStack(ref const Interpreter interpreter, scope immutable ByteCodeIndex[] expected) {
	immutable Arr!(immutable(u8)*) stack = asTempArr(interpreter.returnStack);
	immutable Arr!ByteCodeIndex expectedArr = arrOfD(expected);
	immutable Bool eq = immutable Bool(
		sizeEq(stack, expectedArr) &&
		eachCorresponds!(immutable(u8)*, ByteCodeIndex)(
			stack,
			expectedArr,
			(ref immutable u8* a, ref immutable ByteCodeIndex b) =>
				immutable Bool(byteCodeIndexOfPtr(interpreter, a) == b)));
	if (!eq) {
		debug {
			printf("expected:\n");
			printf("return:");
			foreach (immutable u8* ptr; range(stack))
				printf(" %d", byteCodeIndexOfPtr(interpreter, ptr).index.raw());
			printf("\nactual:\n");
			printf("return:");
			foreach (immutable ByteCodeIndex index; expected)
				printf(" %d", index.index.raw());
			printf("\n");
		}
		todo!void("useful error message");
		verify(false);
	}
}
