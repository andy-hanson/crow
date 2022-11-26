module interpret.debugInfo;

@safe @nogc nothrow: // not pure (because of backtraceStringsStorage)

import frontend.showDiag : ShowDiagOptions;
import interpret.bytecode : ByteCode, ByteCodeIndex, ByteCodeSource, Operation;
import interpret.debugging : writeFunName;
import interpret.runBytecode : operationOpStopInterpretation;
import interpret.stacks : returnPeek, returnStackSize, Stacks;
import model.diag : FilesInfo, writeFileAndPos;
import model.concreteModel : ConcreteFun, concreteFunRange;
import model.lowModel : LowFunIndex, LowFunSource, LowProgram;
import util.alloc.alloc : Alloc;
import util.lineAndColumnGetter : LineAndColumn, lineAndColumnAtPos;
import util.opt : force, has, none, Opt, some;
import util.path : AllPaths, Path, PathsInfo, pathToSafeCStrPreferRelative;
import util.ptr : ptrTrustMe;
import util.sourceRange : FileAndPos, FileIndex;
import util.sym : AllSymbols;
import util.util : min, verify;
import util.writer : finishWriterToSafeCStr, writeHex, Writer;

struct InterpreterDebugInfo {
	@safe @nogc pure nothrow:
	immutable LowProgram* lowProgramPtr;
	immutable ByteCode* byteCodePtr;
	immutable AllSymbols* allSymbolsPtr;
	immutable AllPaths* allPathsPtr;
	immutable PathsInfo* pathsInfoPtr;
	immutable FilesInfo* filesInfoPtr;

	ref immutable(ByteCode) byteCode() const return scope pure =>
		*byteCodePtr;
	ref immutable(LowProgram) lowProgram() const return scope pure =>
		*lowProgramPtr;
	ref immutable(AllSymbols) allSymbols() const return scope pure =>
		*allSymbolsPtr;
	ref immutable(AllPaths) allPaths() const return scope pure =>
		*allPathsPtr;
	ref immutable(PathsInfo) pathsInfo() const return scope pure =>
		*pathsInfoPtr;
	ref immutable(FilesInfo) filesInfo() const return scope pure =>
		*filesInfoPtr;
}

// matches `backtrace-entry` from `bootstrap.crow`.
struct BacktraceEntry {
	@safe @nogc pure nothrow:

	// Making sure pointers look like 64-bit even for a 32-bit WASM build
	Ptr64!(immutable char) functionName;
	Ptr64!(immutable char) filePath;
	uint lineNumber;
	uint columnNumber;
}

private struct Ptr64(T) {
	@safe @nogc pure nothrow:

	this(T* a) { inner = a; }

	version (LittleEndian) {
		T* inner;
		byte[ulong.sizeof - (char*).sizeof] padding;
	} else {
		byte[ulong.sizeof - (char*).sizeof] padding;
		T* inner;
	}
}

@system BacktraceEntry* fillBacktrace(
	scope ref immutable InterpreterDebugInfo info,
	BacktraceEntry* out_,
	immutable size_t max,
	immutable size_t skip,
	const Stacks stacks,
) {
	Alloc alloc = Alloc(
		cast(ubyte*) backtraceStringsStorage.ptr,
		backtraceStringsStorage.length * backtraceStringsStorage[0].sizeof);
	immutable size_t resSize = min(returnStackSize(stacks) - skip, max);
	foreach (immutable size_t i, ref BacktraceEntry entry; out_[0 .. resSize])
		entry = getBacktraceEntry(alloc, info, returnPeek(stacks, skip + i));
	return out_ + resSize;
}

private static ulong[0x1000] backtraceStringsStorage = void;

pure:

private immutable(BacktraceEntry) getBacktraceEntry(
	ref Alloc alloc,
	scope ref immutable InterpreterDebugInfo info,
	immutable Operation* cur,
) {
	immutable Opt!ByteCodeSource source = nextSource(info, cur);
	return has(source)
		? backtraceEntryFromSource(alloc, info, force(source))
		: immutable BacktraceEntry(Ptr64!(immutable char)(""), Ptr64!(immutable char)(""), 0, 0);
}

private @trusted immutable(BacktraceEntry) backtraceEntryFromSource(
	ref Alloc alloc,
	scope ref immutable InterpreterDebugInfo info,
	immutable ByteCodeSource source,
) {
	Writer writer = Writer(ptrTrustMe(alloc));
	writeFunName(writer, info.allSymbols, info.lowProgram, source.fun);
	immutable Ptr64!(immutable char) funName = Ptr64!(immutable char)(finishWriterToSafeCStr(writer).ptr);

	immutable Opt!FileIndex opFileIndex = getFileIndex(info.allSymbols, info.lowProgram, source.fun);
	if (has(opFileIndex)) {
		immutable FileIndex fileIndex = force(opFileIndex);
		immutable Path path = info.filesInfo.filePaths[fileIndex];
		immutable Ptr64!(immutable char) filePath =
			Ptr64!(immutable char)(pathToSafeCStrPreferRelative(alloc, info.allPaths, info.pathsInfo, path).ptr);
		immutable LineAndColumn lc = lineAndColumnAtPos(info.filesInfo.lineAndColumnGetters[fileIndex], source.pos);
		return immutable BacktraceEntry(funName, filePath, lc.line + 1, 0);
	} else
		return immutable BacktraceEntry(funName, Ptr64!(immutable char)(""), 0, 0);
}

pure:

void printDebugInfo(
	scope ref const InterpreterDebugInfo a,
	scope immutable ulong[] dataStack,
	scope immutable immutable(Operation)*[] returnStackReverse,
	immutable Operation* cur,
) {
	immutable Opt!ByteCodeSource source = nextSource(a, cur);

	debug {
		import core.stdc.stdio : printf;
		{
			ubyte[10_000] mem;
			scope Alloc dbgAlloc = Alloc(&mem[0], mem.length);
			scope Writer writer = Writer(ptrTrustMe(dbgAlloc));
			showDataArr(writer, dataStack);
			showReturnStack(writer, a, returnStackReverse, cur);
			printf("%s\n", finishWriterToSafeCStr(writer).ptr);
		}

		{
			ubyte[10_000] mem;
			scope Alloc dbgAlloc = Alloc(&mem[0], mem.length);
			scope Writer writer = Writer(ptrTrustMe(dbgAlloc));
			writer ~= "STEP: ";
			immutable ShowDiagOptions showDiagOptions = immutable ShowDiagOptions(false);
			if (has(source)) {
				writeByteCodeSource(
					writer, a.allSymbols, a.allPaths, a.pathsInfo, showDiagOptions,
					a.lowProgram, a.filesInfo, force(source));
			} else
				writer ~= "opStopInterpretation";
			printf("%s\n", finishWriterToSafeCStr(writer).ptr);
		}
	}
}

void showDataArr(scope ref Writer writer, scope immutable ulong[] values) {
	writer ~= "data (";
	writer ~= values.length;
	writer ~= "): ";
	foreach (immutable ulong value; values) {
		writer ~= ' ';
		writeHex(writer, value);
	}
	writer ~= '\n';
}

private:

void showReturnStack(
	scope ref Writer writer,
	scope ref const InterpreterDebugInfo debugInfo,
	scope const immutable(Operation)*[] returnStackReverse,
	immutable(Operation)* cur,
) {
	writer ~= "call stack (";
	writer ~= returnStackReverse.length;
	writer ~= "): ";
	foreach_reverse (immutable Operation* ptr; returnStackReverse) {
		writer ~= ' ';
		writeFunNameAtByteCodePtr(writer, debugInfo, ptr);
	}
	writer ~= ' ';
	writeFunNameAtByteCodePtr(writer, debugInfo, cur);
}

void writeByteCodeSource(
	scope ref Writer writer,
	scope ref const AllSymbols allSymbols,
	scope ref const AllPaths allPaths,
	scope ref immutable PathsInfo pathsInfo,
	scope ref immutable ShowDiagOptions showDiagOptions,
	scope ref immutable LowProgram lowProgram,
	scope ref immutable FilesInfo filesInfo,
	immutable ByteCodeSource source,
) {
	writeFunName(writer, allSymbols, lowProgram, source.fun);
	writer ~= ' ';
	immutable Opt!FileIndex where = getFileIndex(allSymbols, lowProgram, source.fun);
	if (has(where))
		writeFileAndPos(
			writer, allPaths, pathsInfo, showDiagOptions, filesInfo,
			immutable FileAndPos(force(where), source.pos));
}

immutable(Opt!FileIndex) getFileIndex(
	scope ref const AllSymbols allSymbols,
	scope ref immutable LowProgram lowProgram,
	immutable LowFunIndex fun,
) =>
	lowProgram.allFuns[fun].source.match!(immutable Opt!FileIndex)(
		(ref immutable ConcreteFun x) =>
			some(concreteFunRange(x, allSymbols).fileIndex),
		(ref immutable LowFunSource.Generated) =>
			none!FileIndex);

void writeFunNameAtIndex(
	scope ref Writer writer,
	scope ref const InterpreterDebugInfo debugInfo,
	immutable ByteCodeIndex index,
) {
	writeFunName(writer, debugInfo.allSymbols, debugInfo.lowProgram, byteCodeSourceAtIndex(debugInfo, index).fun);
}

@trusted void writeFunNameAtByteCodePtr(
	scope ref Writer writer,
	scope ref const InterpreterDebugInfo debugInfo,
	immutable Operation* ptr,
) {
	immutable Opt!ByteCodeIndex index = byteCodeIndexOfPtr(debugInfo, ptr);
	if (has(index))
		writeFunNameAtIndex(writer, debugInfo, force(index));
	else
		writer ~= "opStopInterpretation";
}

@system immutable(bool) ptrInRange(T)(immutable T[] xs, immutable T* x) =>
	xs.ptr <= x && x < (xs.ptr + xs.length);

immutable(ByteCodeSource) byteCodeSourceAtIndex(ref const InterpreterDebugInfo a, immutable ByteCodeIndex index) =>
	a.byteCode.sources[index];

immutable(Opt!ByteCodeSource) byteCodeSourceAtByteCodePtr(
	ref const InterpreterDebugInfo a,
	immutable Operation* ptr,
) {
	immutable Opt!ByteCodeIndex index = byteCodeIndexOfPtr(a, ptr);
	return has(index)
		? some(byteCodeSourceAtIndex(a, force(index)))
		: none!ByteCodeSource;
}

@trusted pure immutable(Opt!ByteCodeIndex) byteCodeIndexOfPtr(
	ref const InterpreterDebugInfo a,
	immutable Operation* ptr,
) {
	if (ptrInRange(operationOpStopInterpretation, ptr))
		return none!ByteCodeIndex;
	else {
		immutable size_t index = ptr - a.byteCode.byteCode.ptr;
		verify(index < a.byteCode.byteCode.length);
		return some(immutable ByteCodeIndex(index));
	}
}

immutable(Opt!ByteCodeSource) nextSource(ref const InterpreterDebugInfo a, immutable Operation* cur) =>
	byteCodeSourceAtByteCodePtr(a, cur);
