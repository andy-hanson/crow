module interpret.debugInfo;

@safe @nogc nothrow: // not pure (because of backtraceStringsStorage)

import frontend.showModel : ShowCtx, writeUriAndPos;
import interpret.bytecode : ByteCode, ByteCodeIndex, ByteCodeSource, Operation;
import interpret.debugging : writeFunName;
import interpret.runBytecode : operationOpStopInterpretation;
import interpret.stacks : returnPeek, returnStackSize, Stacks;
import model.concreteModel : ConcreteFun, concreteFunRange;
import model.lowModel : LowFunIndex, LowFunSource, LowProgram;
import util.alloc.alloc : Alloc, withStaticAlloc;
import util.lineAndColumnGetter : LineAndColumn, LineAndColumnGetters, lineAndColumnAtPos, PosKind;
import util.col.arr : isPointerInRange;
import util.col.str : CStr;
import util.memory : overwriteMemory;
import util.opt : force, has, none, Opt, some;
import util.sourceRange : UriAndPos;
import util.sym : AllSymbols;
import util.uri : AllUris, Uri, UrisInfo, uriToSafeCStrPreferRelative;
import util.util : min, verify;
import util.writer : debugLogWithWriter, withWriter, writeHex, Writer;

struct InterpreterDebugInfo {
	@safe @nogc pure nothrow:
	ShowCtx* showDiagPtr;
	LowProgram* lowProgramPtr;
	ByteCode* byteCodePtr;

	ref inout(ShowCtx) showDiag() inout return scope =>
		*showDiagPtr;
	ref const(AllSymbols) allSymbols() const return scope =>
		showDiag.allSymbols;
	ref const(AllUris) allUris() const return scope =>
		showDiag.allUris;
	ref const(UrisInfo) urisInfo() const return scope =>
		showDiag.urisInfo;
	ref LineAndColumnGetters lineAndColumnGetters() return scope =>
		showDiag.lineAndColumnGetters;
	ref ByteCode byteCode() const return scope =>
		*byteCodePtr;
	ref LowProgram lowProgram() const return scope =>
		*lowProgramPtr;
}

// matches `backtrace-entry` from `bootstrap.crow`.
immutable struct BacktraceEntry {
	@safe @nogc pure nothrow:

	this(CStr fn, CStr fp, uint ln, uint cn) {
		functionName = fn;
		fileUri = fp;
		lineNumber = ln;
		columnNumber = cn;
	}

	// Making sure pointers look like 64-bit even for a 32-bit WASM build
	Ptr64!(immutable char) functionName;
	Ptr64!(immutable char) fileUri;
	uint lineNumber;
	uint columnNumber;
}

private struct Ptr64(T) {
	@safe @nogc pure nothrow:

	inout this(inout T* a) { inner = a; }

	version (LittleEndian) {
		T* inner;
		byte[ulong.sizeof - (char*).sizeof] padding;
	} else {
		byte[ulong.sizeof - (char*).sizeof] padding;
		T* inner;
	}
}

@system BacktraceEntry* fillBacktrace(
	scope ref InterpreterDebugInfo info,
	BacktraceEntry* out_,
	size_t max,
	size_t skip,
	in Stacks stacks,
) =>
	withStaticAlloc!(BacktraceEntry*, (ref Alloc alloc) {
		size_t resSize = min(returnStackSize(stacks) - skip, max);
		foreach (size_t i, ref BacktraceEntry entry; out_[0 .. resSize])
			overwriteMemory(&entry, getBacktraceEntry(alloc, info, returnPeek(stacks, skip + i)));
		return out_ + resSize;
	})(backtraceStringsStorage);

private static ulong[0x1000] backtraceStringsStorage = void;

pure:

private BacktraceEntry getBacktraceEntry(ref Alloc alloc, scope ref InterpreterDebugInfo info, in Operation* cur) {
	Opt!ByteCodeSource source = nextSource(info, cur);
	return has(source)
		? backtraceEntryFromSource(alloc, info, force(source))
		: BacktraceEntry("", "", 0, 0);
}

private @trusted BacktraceEntry backtraceEntryFromSource(
	ref Alloc alloc,
	scope ref InterpreterDebugInfo info,
	ByteCodeSource source,
) {
	CStr funName = withWriter(alloc, (scope ref Writer writer) {
		writeFunName(writer, info.showDiag, info.lowProgram, source.fun);
	}).ptr;
	Opt!Uri opUri = getUri(info.lowProgram, source.fun);
	if (has(opUri)) {
		Uri uri = force(opUri);
		CStr fileUri = uriToSafeCStrPreferRelative(alloc, info.allUris, info.urisInfo, uri).ptr;
		LineAndColumn lc = lineAndColumnAtPos(
			info.lineAndColumnGetters, UriAndPos(uri, source.pos), PosKind.startOfRange);
		return BacktraceEntry(funName, fileUri, lc.line1Indexed, 0);
	} else
		return BacktraceEntry(funName, "", 0, 0);
}


void printDebugInfo(
	scope ref InterpreterDebugInfo a,
	in immutable ulong[] dataStack,
	in immutable Operation*[] returnStackReverse,
	in Operation* cur,
) {
	Opt!ByteCodeSource source = nextSource(a, cur);

	debug {
		debugLogWithWriter((scope ref Writer writer) {
			showDataArr(writer, dataStack);
			showReturnStack(writer, a, returnStackReverse, cur);
		});
		debugLogWithWriter((scope ref Writer writer) {
			writer ~= "STEP: ";
			if (has(source))
				writeByteCodeSource(writer, a.showDiag, a.lowProgram, force(source));
			else
				writer ~= "opStopInterpretation";
		});
	}
}

void showDataArr(scope ref Writer writer, in immutable ulong[] values) {
	writer ~= "data (";
	writer ~= values.length;
	writer ~= "): ";
	foreach (ulong value; values) {
		writer ~= ' ';
		writeHex(writer, value);
	}
	writer ~= '\n';
}

private:

void showReturnStack(
	ref Writer writer,
	scope ref InterpreterDebugInfo debugInfo,
	in immutable Operation*[] returnStackReverse,
	in Operation* cur,
) {
	writer ~= "call stack (";
	writer ~= returnStackReverse.length;
	writer ~= "): ";
	foreach_reverse (Operation* ptr; returnStackReverse) {
		writer ~= ' ';
		writeFunNameAtByteCodePtr(writer, debugInfo, ptr);
	}
	writer ~= ' ';
	writeFunNameAtByteCodePtr(writer, debugInfo, cur);
}

void writeByteCodeSource(ref Writer writer, ref ShowCtx ctx, in LowProgram lowProgram, in ByteCodeSource source) {
	writeFunName(writer, ctx, lowProgram, source.fun);
	writer ~= ' ';
	Opt!Uri where = getUri(lowProgram, source.fun);
	if (has(where))
		writeUriAndPos(writer, ctx, UriAndPos(force(where), source.pos));
}

Opt!Uri getUri(in LowProgram lowProgram, LowFunIndex fun) =>
	lowProgram.allFuns[fun].source.matchIn!(Opt!Uri)(
		(in ConcreteFun x) =>
			some(concreteFunRange(x).uri),
		(in LowFunSource.Generated) =>
			none!Uri);

void writeFunNameAtIndex(ref Writer writer, scope ref InterpreterDebugInfo debugInfo, ByteCodeIndex index) {
	writeFunName(writer, debugInfo.showDiag, debugInfo.lowProgram, byteCodeSourceAtIndex(debugInfo, index).fun);
}

@trusted void writeFunNameAtByteCodePtr(
	ref Writer writer,
	scope ref InterpreterDebugInfo debugInfo,
	in Operation* ptr,
) {
	Opt!ByteCodeIndex index = byteCodeIndexOfPtr(debugInfo, ptr);
	if (has(index))
		writeFunNameAtIndex(writer, debugInfo, force(index));
	else
		writer ~= "opStopInterpretation";
}

ByteCodeSource byteCodeSourceAtIndex(in InterpreterDebugInfo a, ByteCodeIndex index) =>
	a.byteCode.sources[index];

Opt!ByteCodeSource byteCodeSourceAtByteCodePtr(in InterpreterDebugInfo a, in Operation* ptr) {
	Opt!ByteCodeIndex index = byteCodeIndexOfPtr(a, ptr);
	return has(index)
		? some(byteCodeSourceAtIndex(a, force(index)))
		: none!ByteCodeSource;
}

@trusted Opt!ByteCodeIndex byteCodeIndexOfPtr(in InterpreterDebugInfo a, in Operation* ptr) {
	if (isPointerInRange(operationOpStopInterpretation, ptr))
		return none!ByteCodeIndex;
	else {
		size_t index = ptr - a.byteCode.byteCode.ptr;
		verify(index < a.byteCode.byteCode.length);
		return some(ByteCodeIndex(index));
	}
}

Opt!ByteCodeSource nextSource(in InterpreterDebugInfo a, in Operation* cur) =>
	byteCodeSourceAtByteCodePtr(a, cur);
