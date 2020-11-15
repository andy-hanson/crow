module test.testUtil;

@safe @nogc nothrow: // not pure

import interpret.bytecode : ByteCodeIndex;
import interpret.runBytecode : byteCodeIndexOfPtr, DataStack, Interpreter, showDataArr;
import util.bools : Bool;
import util.collection.arr : Arr, arrOfD, range, sizeEq;
import util.collection.arrUtil : eachCorresponds;
import util.collection.globalAllocatedStack : asTempArr;
import util.collection.str : Str;
import util.ptr : Ptr;
import util.types : Nat64, u8;
import util.util : verify;
import util.writer : finishWriter, writeChar, writeNat, Writer, writeStatic;

struct Test(Alloc) {
	Ptr!Alloc alloc;

	Writer!Alloc writer() {
		return Writer!Alloc(alloc);
	}

	void fail(immutable Str) {
		verify(false);
	}
}

void expectDataStack(Alloc)(ref Test!Alloc test, ref const DataStack dataStack, scope immutable Nat64[] expected) {
	immutable Arr!Nat64 stack = asTempArr(dataStack);
	immutable Arr!Nat64 expectedArr = arrOfD(expected);
	immutable Bool eq = immutable Bool(
		sizeEq(stack, expectedArr) &&
		eachCorresponds!(Nat64, Nat64)(stack, expectedArr, (ref immutable Nat64 a, ref immutable Nat64 b) =>
			immutable Bool(a == b)));
	if (!eq) {
		debug {
			Writer!Alloc writer = test.writer();
			writeStatic(writer, "expected:\n");
			showDataArr(writer, expectedArr);
			writeStatic(writer, "\nactual:\n");
			showDataArr(writer, stack);
			test.fail(finishWriter(writer));
		}
	}
}

void expectReturnStack(Alloc, Extern)(
	ref Test!Alloc test,
	ref const Interpreter!Extern interpreter,
	scope immutable ByteCodeIndex[] expected,
) {
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
			Writer!Alloc writer = test.writer();
			writeStatic(writer, "expected:\nreturn:");
			foreach (immutable u8* ptr; range(stack)) {
				writeChar(writer, ' ');
				writeNat(writer, byteCodeIndexOfPtr(interpreter, ptr).index.raw());
			}
			writeStatic(writer, "\nactual:\nreturn:");
			foreach (immutable ByteCodeIndex index; expected) {
				writeChar(writer, ' ');
				writeNat(writer, index.index.raw());
			}
			writeChar(writer, '\n');
			test.fail(finishWriter(writer));
		}
		verify(false);
	}
}
