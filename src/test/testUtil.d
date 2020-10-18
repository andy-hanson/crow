module test.testUtil;

@safe @nogc nothrow: // not pure

import core.stdc.stdio : printf;
import interpret.runBytecode : DataStack, printDataArr;
import util.bools : Bool;
import util.collection.arr : Arr, arrOfD, sizeEq;
import util.collection.arrUtil : eachCorresponds;
import util.collection.globalAllocatedStack : asTempArr;
import util.types : u64;
import util.util : verify;

void expectStack(ref DataStack dataStack, scope immutable u64[] expected) {
	immutable Arr!u64 stack = asTempArr(dataStack);
	immutable Arr!u64 expectedArr = arrOfD(expected);
	immutable Bool eq = immutable Bool(
		sizeEq(stack, expectedArr) &&
		eachCorresponds!(u64, u64)(stack, expectedArr, (ref immutable u64 a, ref immutable u64 b) =>
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
