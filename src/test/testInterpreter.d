module test.testInterpreter;

@safe @nogc nothrow: // not pure

import core.stdc.stdio : printf;
import diag : FilesInfo;
import model : AbsolutePathsGetter;
import interpret.bytecode : ByteCode, ByteCodeIndex;
import interpret.runBytecode :
	nextByteCodeIndex,
	Interpreter,
	newInterpreter,
	printDataArr,
	runBytecode,
	step,
	StepResult;
import interpret.bytecodeWriter :
	ByteCodeWriter,
	finishByteCode,
	getNextStackEntry,
	newByteCodeWriter,
	StackEntries,
	StackEntry,
	writeDupEntries,
	writeDupEntry,
	writePushConstant,
	writePushConstants,
	writeReturn;
import util.alloc.stackAlloc : StackAlloc;
import util.bools : Bool;
import util.collection.arr : Arr, range;
import util.collection.arrUtil : eachCorresponds;
import util.collection.fullIndexDict : emptyFullIndexDict, fullIndexDictOfArr;
import util.collection.globalAllocatedStack : asTempArr;
import util.collection.str : emptyStr;
import util.lineAndColumnGetter : LineAndColumnGetter, lineAndColumnGetterForEmptyFile;
import util.opt : none;
import util.path : Path, PathAndStorageKind, StorageKind;
import util.ptr : Ptr, ptrTrustMe, ptrTrustMe_mut;
import util.sourceRange : FileAndRange, FileIndex;
import util.sym : shortSymAlphaLiteral;
import util.types : u64;
import util.util : repeatImpure, verify;

void testInterpreter() {
	testDup();
}

private:

alias Alloc = StackAlloc!("temp", 1024 * 1024);

void doTest(
	scope void delegate(
		ref ByteCodeWriter!Alloc,
		ref immutable FileAndRange source,
	) @safe @nogc pure nothrow writeBytecode,
	scope void delegate(ref Interpreter) @safe @nogc nothrow runInterpreter,
) {
	Alloc alloc;
	ByteCodeWriter!Alloc writer = newByteCodeWriter(ptrTrustMe_mut(alloc));
	immutable FileAndRange source = FileAndRange.empty;
	writeBytecode(writer, source);
	immutable ByteCode byteCode = finishByteCode(writer, immutable ByteCodeIndex(0));

	immutable Path emptyPath = immutable Path(none!(Ptr!Path), shortSymAlphaLiteral("test"));
	immutable PathAndStorageKind pk = immutable PathAndStorageKind(ptrTrustMe(emptyPath), StorageKind.global);
	immutable LineAndColumnGetter lcg = lineAndColumnGetterForEmptyFile(alloc);
	immutable FilesInfo filesInfo = immutable FilesInfo(
		fullIndexDictOfArr!(FileIndex, PathAndStorageKind)(
			immutable Arr!PathAndStorageKind(ptrTrustMe(pk).rawPtr(), 1)),
		immutable AbsolutePathsGetter(emptyStr, emptyStr),
		fullIndexDictOfArr!(FileIndex, LineAndColumnGetter)(
			immutable Arr!LineAndColumnGetter(ptrTrustMe(lcg).rawPtr(), 1)));

	Interpreter interpreter = newInterpreter(ptrTrustMe(byteCode), ptrTrustMe(filesInfo));
	runInterpreter(interpreter);
}

void testDup() {
	doTest(
		(ref ByteCodeWriter!Alloc writer, ref immutable FileAndRange source) {
			writePushConstants(writer, source, [55, 65, 75]);
			verifyStackEntry(writer, 3);
			writeDupEntry(writer, source, immutable StackEntry(0));
			verifyStackEntry(writer, 4);
			writeDupEntries(writer, source, immutable StackEntries(immutable StackEntry(2), 2));
			verifyStackEntry(writer, 6);
			writeReturn(writer, source);
		},
		(ref Interpreter interpreter) {
			verify(nextByteCodeIndex(interpreter) == 0);
			repeatImpure(3, () { step(interpreter); });
			expectStack(interpreter, [55, 65, 75]);
			stepContinue(interpreter);
			expectStack(interpreter, [55, 65, 75, 55]);
			stepContinue(interpreter);
			expectStack(interpreter, [55, 65, 75, 55, 75]);
			stepContinue(interpreter);
			expectStack(interpreter, [55, 65, 75, 55, 75, 55]);
			stepExit(interpreter);
			//verify(nextByteCodeIndex(interpreter) == 3);
		});
}

void verifyStackEntry(Alloc)(ref ByteCodeWriter!Alloc writer, immutable uint n) {
	verify(getNextStackEntry(writer) == immutable StackEntry(n));
}

void stepContinue(ref Interpreter interpreter) {
	immutable StepResult result = step(interpreter);
	verify(result == StepResult.continue_);
}

void stepExit(ref Interpreter interpreter) {
	immutable StepResult result = step(interpreter);
	verify(result == StepResult.exit);
}

@trusted void expectStack(size_t size)(ref Interpreter interpreter, immutable u64[size] expected) {
	expectStack(interpreter, immutable Arr!u64(expected.ptr, size));
}

void expectStack(ref Interpreter interpreter, immutable Arr!u64 expected) {
	immutable Arr!u64 stack = asTempArr(interpreter.dataStack);
	immutable Bool eq = eachCorresponds!(u64, u64)(stack, expected, (ref immutable u64 a, ref immutable u64 b) =>
		immutable Bool(a == b));
	if (!eq) {
		debug {
			printf("expected:\n");
			printDataArr(expected);
			printf("\nactual:\n");
			printDataArr(stack);
		}
		verify(false);
	}
}
