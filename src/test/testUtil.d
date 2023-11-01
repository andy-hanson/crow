module test.testUtil;

@safe @nogc nothrow: // not pure

import frontend.showModel : ShowCtx, ShowOptions;
import interpret.bytecode : ByteCode, ByteCodeIndex, Operation;
import interpret.debugInfo : showDataArr;
import interpret.stacks : dataTempAsArr, returnTempAsArrReverse, Stacks;
import model.model : Program;
import util.alloc.alloc : Alloc;
import util.col.arrUtil : arrEqual, arrsCorrespond, makeArr;
import util.lineAndColumnGetter : LineAndColumnGetters;
import util.opt : none;
import util.ptr : ptrTrustMe;
import util.storage : Storage;
import util.sym : AllSymbols;
import util.uri : AllUris, Uri, UrisInfo;
import util.util : verifyFail;
import util.writer : debugLogWithWriter, Writer;

struct Test {
	@safe @nogc pure nothrow:

	Alloc* allocPtr;
	AllSymbols allSymbols;
	AllUris allUris;

	@trusted this(Alloc* ap) {
		allocPtr = ap;
		allSymbols = AllSymbols(ap);
		allUris = AllUris(ap, &allSymbols);
	}

	ref Alloc alloc() return scope =>
		*allocPtr;
}

pure void withShowDiagCtxForTest(
	return scope ref Test test,
	return scope ref Storage storage,
	return in Program program,
	in void delegate(scope ref ShowCtx) @safe @nogc pure nothrow cb,
) {
	withShowDiagCtxForTestImpl!cb(test, storage, program);
}

void withShowDiagCtxForTestImpure(
	return scope ref Test test,
	return scope ref Storage storage,
	return in Program program,
	in void delegate(scope ref ShowCtx) @safe @nogc nothrow cb,
) {
	withShowDiagCtxForTestImpl!cb(test, storage, program);
}

private void withShowDiagCtxForTestImpl(alias cb)(
	return scope ref Test test,
	return scope ref Storage storage,
	return in Program program,
) {
	LineAndColumnGetters lineAndColumnGetters = LineAndColumnGetters(test.allocPtr, &storage);
	ShowCtx ctx = ShowCtx(
		ptrTrustMe(test.allSymbols),
		ptrTrustMe(test.allUris),
		ptrTrustMe(lineAndColumnGetters),
		UrisInfo(none!Uri),
		ShowOptions(false),
		ptrTrustMe(program));
	return cb(ctx);
}

@trusted void expectDataStack(ref Test test, in Stacks stacks, in immutable ulong[] expected) {
	scope immutable ulong[] stack = dataTempAsArr(stacks);
	if (!arrEqual(stack, expected)) {
		debugLogWithWriter((ref Writer writer) {
			writer ~= "expected:\n";
			showDataArr(writer, expected);
			writer ~= "\nactual:\n";
			showDataArr(writer, stack);
		});
		verifyFail();
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
		debugLogWithWriter((ref Writer writer) @trusted {
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
		});
		verifyFail();
	}
}

private T[] reverse(T)(ref Alloc alloc, scope T[] xs) =>
	makeArr(alloc, xs.length, (size_t i) =>
		xs[xs.length - 1 - i]);
