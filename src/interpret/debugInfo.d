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
import model.model : Program;
import util.alloc.alloc : Alloc, withStackAlloc;
import util.lineAndColumnGetter : LineAndColumn, lineAndColumnAtPos;
import util.col.str : CStr;
import util.memory : overwriteMemory;
import util.opt : force, has, none, Opt, some;
import util.path : AllPaths, Path, PathsInfo, pathToSafeCStrPreferRelative;
import util.ptr : ptrTrustMe;
import util.sourceRange : FileAndPos, FileIndex;
import util.sym : AllSymbols;
import util.util : min, verify;
import util.writer : finishWriterToSafeCStr, writeHex, Writer;

const struct InterpreterDebugInfo {
	@safe @nogc pure nothrow:
	Program* programPtr;
	LowProgram* lowProgramPtr;
	ByteCode* byteCodePtr;
	AllSymbols* allSymbolsPtr;
	AllPaths* allPathsPtr;
	PathsInfo* pathsInfoPtr;

	ref ByteCode byteCode() return scope =>
		*byteCodePtr;
	ref Program program() return scope =>
		*programPtr;
	ref LowProgram lowProgram() return scope =>
		*lowProgramPtr;
	ref const(AllSymbols) allSymbols() return scope =>
		*allSymbolsPtr;
	ref const(AllPaths) allPaths() return scope =>
		*allPathsPtr;
	ref PathsInfo pathsInfo() return scope =>
		*pathsInfoPtr;
	ref FilesInfo filesInfo() return scope =>
		program.filesInfo;
}

// matches `backtrace-entry` from `bootstrap.crow`.
immutable struct BacktraceEntry {
	@safe @nogc pure nothrow:

	this(CStr fn, CStr fp, uint ln, uint cn) {
		functionName = fn;
		filePath = fp;
		lineNumber = ln;
		columnNumber = cn;
	}

	// Making sure pointers look like 64-bit even for a 32-bit WASM build
	Ptr64!(immutable char) functionName;
	Ptr64!(immutable char) filePath;
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
	in InterpreterDebugInfo info,
	BacktraceEntry* out_,
	size_t max,
	size_t skip,
	in Stacks stacks,
) {
	Alloc alloc = Alloc(backtraceStringsStorage);
	size_t resSize = min(returnStackSize(stacks) - skip, max);
	foreach (size_t i, ref BacktraceEntry entry; out_[0 .. resSize])
		overwriteMemory(&entry, getBacktraceEntry(alloc, info, returnPeek(stacks, skip + i)));
	return out_ + resSize;
}

private static ulong[0x1000] backtraceStringsStorage = void;

pure:

private BacktraceEntry getBacktraceEntry(ref Alloc alloc, in InterpreterDebugInfo info, in Operation* cur) {
	Opt!ByteCodeSource source = nextSource(info, cur);
	return has(source)
		? backtraceEntryFromSource(alloc, info, force(source))
		: BacktraceEntry("", "", 0, 0);
}

private @trusted BacktraceEntry backtraceEntryFromSource(
	ref Alloc alloc,
	in InterpreterDebugInfo info,
	ByteCodeSource source,
) {
	Writer writer = Writer(ptrTrustMe(alloc));
	writeFunName(writer, info.allSymbols, info.program, info.lowProgram, source.fun);
	CStr funName = finishWriterToSafeCStr(writer).ptr;

	Opt!FileIndex opFileIndex = getFileIndex(info.allSymbols, info.lowProgram, source.fun);
	if (has(opFileIndex)) {
		FileIndex fileIndex = force(opFileIndex);
		Path path = info.filesInfo.filePaths[fileIndex];
		CStr filePath = pathToSafeCStrPreferRelative(alloc, info.allPaths, info.pathsInfo, path).ptr;
		LineAndColumn lc = lineAndColumnAtPos(info.filesInfo.lineAndColumnGetters[fileIndex], source.pos);
		return BacktraceEntry(funName, filePath, lc.line + 1, 0);
	} else
		return BacktraceEntry(funName, "", 0, 0);
}


void printDebugInfo(
	in InterpreterDebugInfo a,
	in immutable ulong[] dataStack,
	in immutable Operation*[] returnStackReverse,
	in Operation* cur,
) {
	Opt!ByteCodeSource source = nextSource(a, cur);

	debug {
		import core.stdc.stdio : printf;
		withStackAlloc!0x1000((ref Alloc dbgAlloc) {
			scope Writer writer = Writer(ptrTrustMe(dbgAlloc));
			showDataArr(writer, dataStack);
			showReturnStack(writer, a, returnStackReverse, cur);
			printf("%s\n", finishWriterToSafeCStr(writer).ptr);
		});

		withStackAlloc!0x1000((ref Alloc dbgAlloc) {
			scope Writer writer = Writer(ptrTrustMe(dbgAlloc));
			writer ~= "STEP: ";
			ShowDiagOptions showDiagOptions = ShowDiagOptions(false);
			if (has(source)) {
				writeByteCodeSource(
					writer, a.allSymbols, a.allPaths, a.pathsInfo, showDiagOptions,
					a.program, a.lowProgram, a.filesInfo, force(source));
			} else
				writer ~= "opStopInterpretation";
			printf("%s\n", finishWriterToSafeCStr(writer).ptr);
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
	scope ref Writer writer,
	in InterpreterDebugInfo debugInfo,
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

void writeByteCodeSource(
	scope ref Writer writer,
	in AllSymbols allSymbols,
	in AllPaths allPaths,
	in PathsInfo pathsInfo,
	in ShowDiagOptions showDiagOptions,
	in Program program,
	in LowProgram lowProgram,
	in FilesInfo filesInfo,
	ByteCodeSource source,
) {
	writeFunName(writer, allSymbols, program, lowProgram, source.fun);
	writer ~= ' ';
	Opt!FileIndex where = getFileIndex(allSymbols, lowProgram, source.fun);
	if (has(where))
		writeFileAndPos(writer, allPaths, pathsInfo, showDiagOptions, filesInfo, FileAndPos(force(where), source.pos));
}

Opt!FileIndex getFileIndex(in AllSymbols allSymbols, in LowProgram lowProgram, LowFunIndex fun) =>
	lowProgram.allFuns[fun].source.matchIn!(Opt!FileIndex)(
		(in ConcreteFun x) =>
			some(concreteFunRange(x, allSymbols).fileIndex),
		(in LowFunSource.Generated) =>
			none!FileIndex);

void writeFunNameAtIndex(scope ref Writer writer, in InterpreterDebugInfo debugInfo, ByteCodeIndex index) {
	writeFunName(
		writer, debugInfo.allSymbols, debugInfo.program, debugInfo.lowProgram,
		byteCodeSourceAtIndex(debugInfo, index).fun);
}

@trusted void writeFunNameAtByteCodePtr(
	scope ref Writer writer,
	in InterpreterDebugInfo debugInfo,
	in Operation* ptr,
) {
	Opt!ByteCodeIndex index = byteCodeIndexOfPtr(debugInfo, ptr);
	if (has(index))
		writeFunNameAtIndex(writer, debugInfo, force(index));
	else
		writer ~= "opStopInterpretation";
}

@system bool ptrInRange(T)(in T[] xs, in T* x) =>
	xs.ptr <= x && x < (xs.ptr + xs.length);

ByteCodeSource byteCodeSourceAtIndex(in InterpreterDebugInfo a, ByteCodeIndex index) =>
	a.byteCode.sources[index];

Opt!ByteCodeSource byteCodeSourceAtByteCodePtr(in InterpreterDebugInfo a, in Operation* ptr) {
	Opt!ByteCodeIndex index = byteCodeIndexOfPtr(a, ptr);
	return has(index)
		? some(byteCodeSourceAtIndex(a, force(index)))
		: none!ByteCodeSource;
}

@trusted Opt!ByteCodeIndex byteCodeIndexOfPtr(in InterpreterDebugInfo a, in Operation* ptr) {
	if (ptrInRange(operationOpStopInterpretation, ptr))
		return none!ByteCodeIndex;
	else {
		size_t index = ptr - a.byteCode.byteCode.ptr;
		verify(index < a.byteCode.byteCode.length);
		return some(ByteCodeIndex(index));
	}
}

Opt!ByteCodeSource nextSource(in InterpreterDebugInfo a, in Operation* cur) =>
	byteCodeSourceAtByteCodePtr(a, cur);
