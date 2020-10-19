module test.testInterpreter;

@safe @nogc nothrow: // not pure

import core.stdc.stdio : printf;
import diag : FilesInfo;
import model : AbsolutePathsGetter;
import interpret.bytecode : ByteCode, ByteCodeIndex;
import interpret.runBytecode :
	DataStack,
	nextByteCodeIndex,
	Interpreter,
	newInterpreter,
	reset,
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
	writeDupPartial,
	writePack,
	writePushConstant,
	writePushConstants,
	writeRemove,
	writeReturn,
	writeStackRef,
	writeWrite;
import test.testUtil : expectStack;
import util.alloc.stackAlloc : StackAlloc;
import util.bools : Bool;
import util.collection.arr : Arr, arrOfD, range;
import util.collection.fullIndexDict : emptyFullIndexDict, fullIndexDictOfArr;
import util.collection.globalAllocatedStack : begin;
import util.collection.str : emptyStr;
import util.lineAndColumnGetter : LineAndColumnGetter, lineAndColumnGetterForEmptyFile;
import util.opt : none;
import util.path : Path, PathAndStorageKind, StorageKind;
import util.ptr : Ptr, ptrTrustMe, ptrTrustMe_mut;
import util.sourceRange : FileAndRange, FileIndex;
import util.sym : shortSymAlphaLiteral;
import util.types : u8, u16, u32, u64;
import util.util : repeatImpure, verify, verifyEq;

void testInterpreter() {
	testDup();
	testRemove();
	testDupPartial();
	testPack();
	testStackRef();
	testWriteSubword();
	testWriteWords();
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
	reset(interpreter);
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
			stepNAndExpect(interpreter, 3, [55, 65, 75]);
			stepAndExpect(interpreter, [55, 65, 75, 55]);
			stepAndExpect(interpreter, [55, 65, 75, 55, 75]);
			stepAndExpect(interpreter, [55, 65, 75, 55, 75, 55]);
			stepExit(interpreter);
		});
}

void testRemove() {
	doTest(
		(ref ByteCodeWriter!Alloc writer, ref immutable FileAndRange source) {
			writePushConstants(writer, source, [0, 1, 2, 3, 4]);
			writeRemove(writer, source, immutable StackEntries(immutable StackEntry(1), 2));
			writeReturn(writer, source);
		},
		(ref Interpreter interpreter) {
			stepNAndExpect(interpreter, 5, [0, 1, 2, 3, 4]);
			stepAndExpect(interpreter, [0, 3, 4]);
			stepExit(interpreter);
		});
}

void testDupPartial() {
	doTest(
		(ref ByteCodeWriter!Alloc writer, ref immutable FileAndRange source) {
			writePushConstants(writer, source, [0x0123456789abcdef]);
			writeDupPartial(writer, source, immutable StackEntry(0), 4, 4);
			writeDupPartial(writer, source, immutable StackEntry(1), 6, 2);
			writeDupPartial(writer, source, immutable StackEntry(2), 7, 1);
			writeDupPartial(writer, source, immutable StackEntry(0), 0, 1);
			writeReturn(writer, source);
		},
		(ref Interpreter interpreter) {
			stepAndExpect(interpreter, [0x0123456789abcdef]);
			stepAndExpect(interpreter, [0x0123456789abcdef, 0x89abcdef]);
			stepAndExpect(interpreter, [0x0123456789abcdef, 0x89abcdef, 0xcdef]);
			stepAndExpect(interpreter, [0x0123456789abcdef, 0x89abcdef, 0xcdef, 0xef]);
			stepAndExpect(interpreter, [0x0123456789abcdef, 0x89abcdef, 0xcdef, 0xef, 0x01]);
			stepExit(interpreter);
		});
}

void testPack() {
	doTest(
		(ref ByteCodeWriter!Alloc writer, ref immutable FileAndRange source) {
			writePushConstants(writer, source, [0x01234567, 0x89ab, 0xcd]);
			immutable u8[3] a = [4, 2, 1];
			writePack(writer, source, arrOfD(a));
			writeReturn(writer, source);
		},
		(ref Interpreter interpreter) {
			stepNAndExpect(interpreter, 3, [0x01234567, 0x89ab, 0xcd]);
			stepAndExpect(interpreter, [0x0123456789abcd00]);
		});
}

void testStackRef() {
	doTest(
		(ref ByteCodeWriter!Alloc writer, ref immutable FileAndRange source) {
			writePushConstants(writer, source, [1, 2]);
			writeStackRef(writer, source, immutable StackEntry(0), 0);
			writeStackRef(writer, source, immutable StackEntry(1), 4);
		},
		(ref Interpreter interpreter) {
			testStackRefInner(interpreter);
		});
}

@trusted void testStackRefInner(ref Interpreter interpreter) {
	stepNAndExpect(interpreter, 2, [1, 2]);
	stepAndExpect(interpreter, [1, 2, cast(immutable u64) begin(interpreter.dataStack)]);
	stepAndExpect(interpreter, [
		1,
		2,
		cast(immutable u64) begin(interpreter.dataStack),
		cast(immutable u64) (begin(interpreter.dataStack) + 1),
	]);
	stepAndExpect(interpreter, [
		1,
		2,
		cast(immutable u64) begin(interpreter.dataStack),
		cast(immutable u64) (begin(interpreter.dataStack) + 1),
		4,
	]);
	stepAndExpect(interpreter, [
		1,
		2,
		cast(immutable u64) begin(interpreter.dataStack),
		cast(immutable u64) (cast(immutable u32*) begin(interpreter.dataStack) + 3),
	]);
}

@trusted void testWriteSubword() {
	struct S {
		u32 a;
		u16 b;
		u8 c;
		u8 d;
	}
	S value;
	immutable u64 valuePtr = cast(immutable u64) &value;
	doTest(
		(ref ByteCodeWriter!Alloc writer, ref immutable FileAndRange source) {
			writePushConstants(writer, source, [valuePtr, 0x0123456789abcdef]);
			writeWrite(writer, source, 0, 4);
			writePushConstants(writer, source, [valuePtr, 0x0123456789abcdef]);
			writeWrite(writer, source, 4, 2);
			writePushConstants(writer, source, [valuePtr, 0x0123456789abcdef]);
			writeWrite(writer, source, 6, 1);
		},
		(ref Interpreter interpreter) {
			stepNAndExpect(interpreter, 2, [valuePtr, 0x0123456789abcdef]);
			stepAndExpect(interpreter, []);
			verify(value == immutable S(0x89abcdef, 0, 0, 0));

			stepNAndExpect(interpreter, 2, [valuePtr, 0x0123456789abcdef]);
			stepAndExpect(interpreter, []);
			verify(value == immutable S(0x89abcdef, 0xcdef, 0, 0));

			stepNAndExpect(interpreter, 2, [valuePtr, 0x0123456789abcdef]);
			stepAndExpect(interpreter, []);
			verify(value == immutable S(0x89abcdef, 0xcdef, 0xef, 0));
		});
}

@trusted void testWriteWords() {
	struct S { u64 a; u64 b; }
	S value;
	immutable u64 valuePtr = cast(immutable u64) &value;
	doTest(
		(ref ByteCodeWriter!Alloc writer, ref immutable FileAndRange source) {
			writePushConstants(writer, source, [valuePtr, 1, 2]);
			writeWrite(writer, source, 0, 16);
		},
		(ref Interpreter interpreter) {
			stepNAndExpect(interpreter, 3, [valuePtr, 1, 2]);
			stepAndExpect(interpreter, []);
			verify(value == immutable S(1, 2));
		});
}

void stepNAndExpect(ref Interpreter interpreter, immutable uint n, scope immutable u64[] expected) {
	repeatImpure(n, () { stepContinue(interpreter); });
	expectStack(interpreter, expected);
}

void stepAndExpect(ref Interpreter interpreter, scope immutable u64[] expected) {
	stepNAndExpect(interpreter, 1, expected);
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

void expectStack(ref Interpreter interpreter, scope immutable u64[] expected) {
	expectStack(interpreter.dataStack, expected);
}
