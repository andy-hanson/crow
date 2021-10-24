module test.testUtil;

@safe @nogc pure nothrow:

import interpret.bytecode : ByteCodeIndex;
import interpret.runBytecode : byteCodeIndexOfPtr, DataStack, Interpreter, showDataArr;
import util.alloc.alloc : Alloc;
import util.collection.arr : sizeEq;
import util.collection.arrUtil : eachCorresponds;
import util.collection.globalAllocatedStack : asTempArr;
import util.path : AllPaths;
import util.ptr : Ptr;
import util.sym : AllSymbols;
import util.types : Nat64;
import util.util : verify;
import util.writer : finishWriter, writeChar, writeNat, Writer, writeStatic;

struct Test(Debug) {
	Ptr!Debug dbg;
	Ptr!Alloc alloc;
	AllSymbols allSymbols;
	AllPaths allPaths;

	Writer writer() {
		return Writer(alloc);
	}

	void fail(immutable string s) {
		debug {
			import core.stdc.stdio : printf;
			printf("Failed: %.*s\n", cast(int) s.length, s.ptr);
		}
		verify(false);
	}
}

void expectDataStack(Debug)(
	ref Test!Debug test,
	ref const DataStack dataStack,
	scope immutable Nat64[] expected,
) {
	immutable Nat64[] stack = asTempArr(dataStack);
	immutable bool eq = sizeEq(stack, expected) &&
		eachCorresponds!(Nat64, Nat64)(stack, expected, (ref immutable Nat64 a, ref immutable Nat64 b) => a == b);
	if (!eq) {
		debug {
			Writer writer = test.writer();
			writeStatic(writer, "expected:\n");
			showDataArr(writer, expected);
			writeStatic(writer, "\nactual:\n");
			showDataArr(writer, stack);
			test.fail(finishWriter(writer));
		}
	}
}

void expectReturnStack(Debug, Extern)(
	ref Test!Debug test,
	ref const Interpreter!Extern interpreter,
	scope immutable ByteCodeIndex[] expected,
) {
	immutable ubyte*[] stack = asTempArr(interpreter.returnStack);
	immutable bool eq = sizeEq(stack, expected) &&
		eachCorresponds!(immutable(ubyte)*, ByteCodeIndex)(
			stack,
			expected,
			(ref immutable ubyte* a, ref immutable ByteCodeIndex b) =>
				byteCodeIndexOfPtr(interpreter, a) == b);
	if (!eq) {
		debug {
			Writer writer = test.writer();
			writeStatic(writer, "expected:\nreturn:");
			foreach (immutable ubyte* ptr; stack) {
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
