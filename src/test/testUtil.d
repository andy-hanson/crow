module test.testUtil;

@safe @nogc nothrow: // not pure

import frontend.showModel : ShowCtx, ShowOptions;
import frontend.storage : LineAndColumnGetters, Storage;
import interpret.bytecode : ByteCode, ByteCodeIndex, Operation;
import interpret.debugInfo : showDataArr;
import interpret.stacks : dataTempAsArr, returnTempAsArrReverse, Stacks;
import model.model : Program;
import util.alloc.alloc : Alloc, MetaAlloc, newAlloc;
import util.col.arrUtil : arrEqual, arrsCorrespond, makeArr;
import util.opt : none;
import util.perf : Perf;
import util.ptr : ptrTrustMe;
import util.sym : AllSymbols;
import util.uri : AllUris, Uri, UrisInfo;
import util.util : verifyFail;
import util.writer : debugLogWithWriter, Writer;

struct Test {
	@safe @nogc pure nothrow:

	MetaAlloc* metaAlloc;
	Perf* perfPtr;
	Alloc alloc;
	AllSymbols allSymbols;
	AllUris allUris;

	@trusted this(MetaAlloc* m, return scope Perf* p) {
		metaAlloc = m;
		perfPtr = p;
		alloc = newAlloc(m);
		allSymbols = AllSymbols(metaAlloc);
		allUris = AllUris(metaAlloc, &allSymbols);
	}

	ref Perf perf() return scope =>
		*perfPtr;
}

pure void withShowDiagCtxForTest(
	scope ref Test test,
	scope ref Storage storage,
	in Program program,
	in void delegate(in ShowCtx) @safe @nogc pure nothrow cb,
) {
	withShowDiagCtxForTestImpl!cb(test, storage, program);
}

void withShowDiagCtxForTestImpure(
	scope ref Test test,
	scope ref Storage storage,
	in Program program,
	in void delegate(in ShowCtx) @safe @nogc nothrow cb,
) {
	withShowDiagCtxForTestImpl!cb(test, storage, program);
}

private void withShowDiagCtxForTestImpl(alias cb)(
	scope ref Test test,
	in Storage storage,
	in Program program,
) =>
	cb(ShowCtx(
		ptrTrustMe(test.allSymbols),
		ptrTrustMe(test.allUris),
		LineAndColumnGetters(ptrTrustMe(storage)),
		UrisInfo(none!Uri),
		ShowOptions(false),
		ptrTrustMe(program)));

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
