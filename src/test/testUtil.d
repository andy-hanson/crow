module test.testUtil;

@safe @nogc nothrow: // not pure

import interpret.bytecode : ByteCode, ByteCodeIndex, Operation;
import interpret.debugInfo : showDataArr;
import interpret.stacks : dataTempAsArr, returnTempAsArrReverse, Stacks;
import util.alloc.alloc : Alloc;
import util.col.arr : sizeEq;
import util.col.arrUtil : eachCorresponds, makeArr;
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

	void fail(immutable string s) {
		debug {
			import core.stdc.stdio : printf;
			printf("Failed: %.*s\n", cast(int) s.length, s.ptr);
		}
		verify(false);
	}

	ref Alloc alloc() return scope =>
		*allocPtr;
}

@trusted void expectDataStack(ref Test test, scope const Stacks stacks, scope immutable ulong[] expected) {
	scope immutable ulong[] stack = dataTempAsArr(stacks);
	immutable bool eq = sizeEq(stack, expected) &&
		eachCorresponds!(ulong, ulong)(stack, expected, (ref immutable ulong a, ref immutable ulong b) => a == b);
	if (!eq) {
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
	scope ref immutable ByteCode byteCode,
	scope ref const Stacks stacks,
	scope immutable ByteCodeIndex[] expected,
) {
	// Ignore first entry (which is opStopInterpretation)
	scope immutable(Operation*)[] stack = reverse(test.alloc, returnTempAsArrReverse(stacks)[0 .. $ - 1]);
	immutable bool eq = sizeEq(stack, expected) &&
		eachCorresponds!(immutable Operation*, ByteCodeIndex)(
			stack,
			expected,
			(ref immutable Operation* a, ref immutable ByteCodeIndex b) @trusted =>
				immutable ByteCodeIndex(a - byteCode.byteCode.ptr) == b);
	if (!eq) {
		debug {
			Writer writer = test.writer();
			writer ~= "expected:\nreturn:";
			foreach (immutable ByteCodeIndex index; expected) {
				writer ~= ' ';
				writer ~= index.index;
			}
			writer ~= "\nactual:\nreturn:";
			foreach (immutable Operation* ptr; stack) {
				writer ~= ' ';
				writer ~= ptr - byteCode.byteCode.ptr;
			}
			writer ~= '\n';
			test.fail(finishWriter(writer));
		}
		verify(false);
	}
}

private immutable(T[]) reverse(T)(ref Alloc alloc, scope T[] xs) =>
	makeArr(alloc, xs.length, (immutable size_t i) =>
		xs[xs.length - 1 - i]);
