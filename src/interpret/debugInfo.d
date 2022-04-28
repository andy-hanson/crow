module interpret.debugInfo;

@safe @nogc nothrow: // not pure (because of backtraceStringsStorage)

import frontend.showDiag : ShowDiagOptions;
import interpret.bytecode : ByteCode, ByteCodeIndex, ByteCodeSource, Operation;
import interpret.debugging : writeFunName;
import interpret.runBytecode : operationOpStopInterpretation;
import interpret.stacks : returnPeek, returnStackSize, Stacks;
import model.diag : FilesInfo, writeFileAndPos;
import model.concreteModel : ConcreteFun, concreteFunRange;
import model.lowModel : LowFunIndex, LowFunSource, LowProgram, matchLowFunSource;
import util.alloc.alloc : Alloc;
import util.lineAndColumnGetter : LineAndColumn, lineAndColumnAtPos;
import util.opt : force, has, none, Opt, some;
import util.path : AllPaths, Path, PathsInfo, pathToSafeCStrPreferRelative;
import util.ptr : Ptr, ptrTrustMe_mut;
import util.sourceRange : FileAndPos, FileIndex;
import util.sym : AllSymbols;
import util.util : min, verify;
import util.writer : finishWriterToSafeCStr, writeChar, writeHex, writeNat, Writer, writeStatic;

struct InterpreterDebugInfo {
	@safe @nogc pure nothrow:
	immutable Ptr!LowProgram lowProgramPtr;
	immutable Ptr!ByteCode byteCodePtr;
	immutable Ptr!AllSymbols allSymbolsPtr;
	immutable Ptr!AllPaths allPathsPtr;
	immutable Ptr!PathsInfo pathsInfoPtr;
	immutable Ptr!FilesInfo filesInfoPtr;

	ref immutable(ByteCode) byteCode() const return scope pure {
		return byteCodePtr.deref();
	}
	ref immutable(LowProgram) lowProgram() const return scope pure {
		return lowProgramPtr.deref();
	}
	ref immutable(AllSymbols) allSymbols() const return scope pure {
		return allSymbolsPtr.deref();
	}
	ref immutable(AllPaths) allPaths() const return scope pure {
		return allPathsPtr.deref();
	}
	ref immutable(PathsInfo) pathsInfo() const return scope pure {
		return pathsInfoPtr.deref();
	}
	ref immutable(FilesInfo) filesInfo() const return scope pure {
		return filesInfoPtr.deref();
	}
}

// matches `backtrace-entry` from `bootstrap.crow`
struct BacktraceEntry {
	immutable(char)* functionName;
	immutable(char)* filePath;
	uint lineNumber;
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
		: immutable BacktraceEntry("", "", 0);
}

private @trusted immutable(BacktraceEntry) backtraceEntryFromSource(
	ref Alloc alloc,
	scope ref immutable InterpreterDebugInfo info,
	immutable ByteCodeSource source,
) {
	Writer writer = Writer(ptrTrustMe_mut(alloc));
	writeFunName(writer, info.allSymbols, info.lowProgram, source.fun);
	immutable char* funName = finishWriterToSafeCStr(writer).ptr;

	immutable Opt!FileIndex opFileIndex = getFileIndex(info.allSymbols, info.lowProgram, source.fun);
	if (has(opFileIndex)) {
		immutable FileIndex fileIndex = force(opFileIndex);
		immutable Path path = info.filesInfo.filePaths[fileIndex];
		immutable char* filePath = pathToSafeCStrPreferRelative(alloc, info.allPaths, info.pathsInfo, path).ptr;
		immutable LineAndColumn lc = lineAndColumnAtPos(info.filesInfo.lineAndColumnGetters[fileIndex], source.pos);
		return immutable BacktraceEntry(funName, filePath, lc.line + 1);
	} else
		return immutable BacktraceEntry(funName, "", 0);
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
			scope Writer writer = Writer(ptrTrustMe_mut(dbgAlloc));
			showDataArr(writer, dataStack);
			showReturnStack(writer, a, returnStackReverse, cur);
			printf("%s\n", finishWriterToSafeCStr(writer).ptr);
		}

		{
			ubyte[10_000] mem;
			scope Alloc dbgAlloc = Alloc(&mem[0], mem.length);
			scope Writer writer = Writer(ptrTrustMe_mut(dbgAlloc));
			writeStatic(writer, "STEP: ");
			immutable ShowDiagOptions showDiagOptions = immutable ShowDiagOptions(false);
			if (has(source)) {
				writeByteCodeSource(
					writer, a.allSymbols, a.allPaths, a.pathsInfo, showDiagOptions,
					a.lowProgram, a.filesInfo, force(source));
			} else
				writeStatic(writer, "opStopInterpretation");
			printf("%s\n", finishWriterToSafeCStr(writer).ptr);
		}
	}
}

void showDataArr(scope ref Writer writer, scope immutable ulong[] values) {
	writeStatic(writer, "data (");
	writeNat(writer, values.length);
	writeStatic(writer, "): ");
	foreach (immutable ulong value; values) {
		writeChar(writer, ' ');
		writeHex(writer, value);
	}
	writeChar(writer, '\n');
}

private:

void showReturnStack(
	scope ref Writer writer,
	scope ref const InterpreterDebugInfo debugInfo,
	scope const immutable(Operation)*[] returnStackReverse,
	immutable(Operation)* cur,
) {
	writeStatic(writer, "call stack (");
	writeNat(writer, returnStackReverse.length);
	writeStatic(writer, "): ");
	foreach_reverse (immutable Operation* ptr; returnStackReverse) {
		writeChar(writer, ' ');
		writeFunNameAtByteCodePtr(writer, debugInfo, ptr);
	}
	writeChar(writer, ' ');
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
	writeChar(writer, ' ');
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
) {
	return matchLowFunSource!(
		immutable Opt!FileIndex,
		(immutable Ptr!ConcreteFun it) =>
			some(concreteFunRange(it.deref(), allSymbols).fileIndex),
		(ref immutable LowFunSource.Generated) =>
			none!FileIndex,
	)(lowProgram.allFuns[fun].source);
}

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
		writeStatic(writer, "opStopInterpretation");
}

@system immutable(bool) ptrInRange(T)(immutable T[] xs, immutable T* x) {
	return xs.ptr <= x && x < (xs.ptr + xs.length);
}

immutable(ByteCodeSource) byteCodeSourceAtIndex(ref const InterpreterDebugInfo a, immutable ByteCodeIndex index) {
	return a.byteCode.sources[index];
}

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

immutable(Opt!ByteCodeSource) nextSource(ref const InterpreterDebugInfo a, immutable Operation* cur) {
	return byteCodeSourceAtByteCodePtr(a, cur);
}
