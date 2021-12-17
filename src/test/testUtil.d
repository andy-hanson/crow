module test.testUtil;

@safe @nogc nothrow: // not pure

import interpret.bytecode : ByteCodeIndex, Operation;
import interpret.runBytecode : byteCodeIndexOfPtr, DataStack, Interpreter, showDataArr;
import util.alloc.alloc : Alloc;
import util.col.arr : sizeEq;
import util.col.arrUtil : eachCorresponds;
import util.col.stack : asTempArr;
import util.dbg : Debug;
import util.path : AllPaths;
import util.ptr : Ptr;
import util.sym : AllSymbols;
import util.util : verify;
import util.writer : finishWriter, writeChar, writeNat, Writer, writeStatic;

struct Test {
	@safe @nogc pure nothrow:

	Ptr!Debug dbgPtr;
	Ptr!Alloc allocPtr;
	AllSymbols allSymbols;
	AllPaths allPaths;

	this(Ptr!Debug dp, Ptr!Alloc ap) {
		dbgPtr = dp;
		allocPtr = ap;
		allSymbols = AllSymbols(ap);
		allPaths = AllPaths(ap, Ptr!AllSymbols(&allSymbols));
	}

	Writer writer() {
		return Writer(allocPtr);
	}

	void fail(immutable string s) {
		debug {
			import core.stdc.stdio : printf;
			printf("Failed: %.*s\n", cast(int) s.length, s.ptr);
		}
		verify(false);
	}

	ref Debug dbg() return scope {
		return dbgPtr.deref();
	}
	ref Alloc alloc() return scope {
		return allocPtr.deref();
	}
}

@trusted void expectDataStack(ref Test test, scope ref const DataStack dataStack, scope immutable ulong[] expected) {
	immutable ulong[] stack = asTempArr(dataStack);
	immutable bool eq = sizeEq(stack, expected) &&
		eachCorresponds!(ulong, ulong)(stack, expected, (ref immutable ulong a, ref immutable ulong b) => a == b);
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

void expectReturnStack(
	ref Test test,
	scope ref const Interpreter interpreter,
	scope immutable ByteCodeIndex[] expected,
) {
	// Ignore first entry (which is opStopInterpretation)
	immutable Operation*[] stack = asTempArr(interpreter.returnStack)[1 .. $];
	immutable bool eq = sizeEq(stack, expected) &&
		eachCorresponds!(immutable Operation*, ByteCodeIndex)(
			stack,
			expected,
			(ref immutable Operation* a, ref immutable ByteCodeIndex b) =>
				byteCodeIndexOfPtr(interpreter, a) == b);
	if (!eq) {
		debug {
			Writer writer = test.writer();
			writeStatic(writer, "expected:\nreturn:");
			foreach (immutable Operation* ptr; stack) {
				writeChar(writer, ' ');
				writeNat(writer, byteCodeIndexOfPtr(interpreter, ptr).index);
			}
			writeStatic(writer, "\nactual:\nreturn:");
			foreach (immutable ByteCodeIndex index; expected) {
				writeChar(writer, ' ');
				writeNat(writer, index.index);
			}
			writeChar(writer, '\n');
			test.fail(finishWriter(writer));
		}
		verify(false);
	}
}
