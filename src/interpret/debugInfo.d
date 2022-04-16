module interpret.debugInfo;

@safe @nogc pure nothrow:

import frontend.showDiag : ShowDiagOptions;
import interpret.bytecode : ByteCode, ByteCodeIndex, ByteCodeSource, Operation;
import interpret.debugging : writeFunName;
import interpret.types : DataStack, ReturnStack;
import model.diag : FilesInfo, writeFileAndPos;
import model.concreteModel : ConcreteFun, concreteFunRange;
import model.lowModel : LowFunSource, LowProgram, matchLowFunSource;
import util.alloc.alloc : Alloc;
import util.col.stack : asTempArr;
import util.path : AllPaths, PathsInfo;
import util.ptr : Ptr, ptrTrustMe_mut;
import util.sourceRange : FileAndPos;
import util.sym : AllSymbols;
import util.writer : finishWriterToSafeCStr, writeChar, writeHex, Writer, writeStatic;

struct InterpreterDebugInfo {
	@safe @nogc pure nothrow:
	immutable Ptr!LowProgram lowProgramPtr;
	immutable Ptr!ByteCode byteCodePtr;
	const Ptr!AllSymbols allSymbolsPtr;
	const Ptr!AllPaths allPathsPtr;
	immutable Ptr!PathsInfo pathsInfoPtr;
	immutable Ptr!FilesInfo filesInfoPtr;

	ref immutable(ByteCode) byteCode() const return scope pure {
		return byteCodePtr.deref();
	}
	ref immutable(LowProgram) lowProgram() const return scope pure {
		return lowProgramPtr.deref();
	}
	ref const(AllSymbols) allSymbols() const return scope pure {
		return allSymbolsPtr.deref();
	}
	ref const(AllPaths) allPaths() const return scope pure {
		return allPathsPtr.deref();
	}
	ref immutable(PathsInfo) pathsInfo() const return scope pure {
		return pathsInfoPtr.deref();
	}
	ref immutable(FilesInfo) filesInfo() const return scope pure {
		return filesInfoPtr.deref();
	}
}

void printDebugInfo(
	scope ref const InterpreterDebugInfo a,
	scope ref const DataStack dataStack,
	scope ref const ReturnStack returnStack,
	immutable Operation* cur,
) {
	immutable ByteCodeSource source = nextSource(a, cur);

	debug {
		import core.stdc.stdio : printf;
		{
			ubyte[10_000] mem;
			scope Alloc dbgAlloc = Alloc(&mem[0], mem.length);
			scope Writer writer = Writer(ptrTrustMe_mut(dbgAlloc));
			showDataStack(writer, dataStack);
			showReturnStack(writer, a, returnStack, cur);
			printf("%s\n", finishWriterToSafeCStr(writer).ptr);
		}

		{
			ubyte[10_000] mem;
			scope Alloc dbgAlloc = Alloc(&mem[0], mem.length);
			scope Writer writer = Writer(ptrTrustMe_mut(dbgAlloc));
			writeStatic(writer, "STEP: ");
			immutable ShowDiagOptions showDiagOptions = immutable ShowDiagOptions(false);
			writeByteCodeSource(
				writer, a.allSymbols, a.allPaths, a.pathsInfo, showDiagOptions, a.lowProgram, a.filesInfo, source);
			//writeChar(writer, ' ');
			//writeReprNoNewline(writer, reprOperation(dbgAlloc, operation));
			//writeChar(writer, '\n');
			printf("%s\n", finishWriterToSafeCStr(writer).ptr);
		}
	}
}

void showDataArr(scope ref Writer writer, scope immutable ulong[] values) {
	writeStatic(writer, "data: ");
	foreach (immutable ulong value; values) {
		writeChar(writer, ' ');
		writeHex(writer, value);
	}
	writeChar(writer, '\n');
}

private:

void showDataStack(scope ref Writer writer, scope ref const DataStack a) {
	showDataArr(writer, asTempArr(a));
}

void showReturnStack(
	scope ref Writer writer,
	scope ref const InterpreterDebugInfo debugInfo,
	scope ref const ReturnStack returnStack,
	immutable(Operation)* cur,
) {
	writeStatic(writer, "call stack:");
	foreach (immutable Operation* ptr; asTempArr(returnStack)) {
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
	matchLowFunSource!(
		void,
		(immutable Ptr!ConcreteFun it) {
			immutable FileAndPos where = immutable FileAndPos(
				concreteFunRange(it.deref(), allSymbols).fileIndex,
				source.pos);
			writeFileAndPos(writer, allPaths, pathsInfo, showDiagOptions, filesInfo, where);
		},
		(ref immutable LowFunSource.Generated) {},
	)(lowProgram.allFuns[source.fun].source);
}

void writeFunNameAtIndex(
	scope ref Writer writer,
	scope ref const InterpreterDebugInfo debugInfo,
	immutable ByteCodeIndex index,
) {
	writeFunName(writer, debugInfo.allSymbols, debugInfo.lowProgram, byteCodeSourceAtIndex(debugInfo, index).fun);
}

void writeFunNameAtByteCodePtr(
	scope ref Writer writer,
	scope ref const InterpreterDebugInfo debugInfo,
	immutable Operation* ptr,
) {
	writeFunNameAtIndex(writer, debugInfo, byteCodeIndexOfPtr(debugInfo, ptr));
}

immutable(ByteCodeSource) byteCodeSourceAtIndex(ref const InterpreterDebugInfo a, immutable ByteCodeIndex index) {
	return a.byteCode.sources[index];
}

immutable(ByteCodeSource) byteCodeSourceAtByteCodePtr(
	ref const InterpreterDebugInfo a,
	immutable Operation* ptr,
) {
	return byteCodeSourceAtIndex(a, byteCodeIndexOfPtr(a, ptr));
}

@trusted pure immutable(ByteCodeIndex) byteCodeIndexOfPtr(
	ref const InterpreterDebugInfo a,
	immutable Operation* ptr,
) {
	return immutable ByteCodeIndex(ptr - a.byteCode.byteCode.ptr);
}

immutable(ByteCodeSource) nextSource(ref const InterpreterDebugInfo a, immutable Operation* cur) {
	return byteCodeSourceAtByteCodePtr(a, cur);
}
