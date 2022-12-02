module test.testUtil;

@safe @nogc nothrow: // not pure

import interpret.bytecode : ByteCode, ByteCodeIndex, Operation;
import interpret.debugInfo : showDataArr;
import interpret.stacks : dataTempAsArr, returnTempAsArrReverse, Stacks;
import util.alloc.alloc : Alloc;
import util.col.arrUtil : arrEqual, arrsCorrespond, makeArr;
import util.path : AllPaths;
import util.sym : AllSymbols;
import util.util : verify;
import util.writer : finishWriter, Writer;

struct Test {
	@safe @nogc pure nothrow:

	Alloc* allocPtr;
	AllSymbols allSymbols;
	AllPaths allPaths;

	@trusted this(Alloc* ap) {
		allocPtr = ap;
		allSymbols = AllSymbols(ap);
		allPaths = AllPaths(ap, &allSymbols);
	}

	Writer writer() =>
		Writer(allocPtr);

	void fail(string s) {
		debug {
			import core.stdc.stdio : printf;
			printf("Failed: %.*s\n", cast(int) s.length, s.ptr);
		}
		verify(false);
	}

	ref Alloc alloc() return scope =>
		*allocPtr;
}

@trusted void expectDataStack(ref Test test, in Stacks stacks, in immutable ulong[] expected) {
	scope immutable ulong[] stack = dataTempAsArr(stacks);
	if (!arrEqual(stack, expected)) {
		debug {
			Writer writer = test.writer();
			writer ~= "expected:\n";
			showDataArr(writer, expected);
			writer ~= "\nactual:\n";
			showDataArr(writer, stack);
			test.fail(finishWriter(writer));
		}
	}
}

@trusted void expectReturnStack(
	ref Test test,
	in ByteCode byteCode,
	in Stacks stacks,
	in ByteCodeIndex[] expected,
) {
	// Ignore first entry (which is opStopInterpretation)
	scope immutable(Operation*)[] stack = reverse(test.alloc, returnTempAsArrReverse(stacks)[0 .. $ - 1]);
	bool eq = arrsCorrespond!(Operation*, ByteCodeIndex)(
		stack,
		expected,
		(in Operation* a, in ByteCodeIndex b) @trusted =>
			ByteCodeIndex(a - byteCode.byteCode.ptr) == b);
	if (!eq) {
		debug {
			Writer writer = test.writer();
			writer ~= "expected:\nreturn:";
			foreach (ByteCodeIndex index; expected) {
				writer ~= ' ';
				writer ~= index.index;
			}
			writer ~= "\nactual:\nreturn:";
			foreach (Operation* ptr; stack) {
				writer ~= ' ';
				writer ~= ptr - byteCode.byteCode.ptr;
			}
			writer ~= '\n';
			test.fail(finishWriter(writer));
		}
		verify(false);
	}
}

private T[] reverse(T)(ref Alloc alloc, scope T[] xs) =>
	makeArr(alloc, xs.length, (size_t i) =>
		xs[xs.length - 1 - i]);
