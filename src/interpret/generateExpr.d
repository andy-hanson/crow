module interpret.generateExpr;

@safe @nogc pure nothrow:

import interpret.applyFn :
	fnAddFloat32,
	fnAddFloat64,
	fnBitwiseAnd,
	fnBitwiseNot,
	fnBitwiseOr,
	fnBitwiseXor,
	fnCountOnesNat64,
	fnEq8Bit,
	fnEq16Bit,
	fnEq32Bit,
	fnEq64Bit,
	fnEqFloat32,
	fnEqFloat64,
	fnForBinaryMath,
	fnForUnaryMath,
	fnInt64FromInt8,
	fnInt64FromInt16,
	fnInt64FromInt32,
	fnFloat32FromFloat64,
	fnFloat64FromFloat32,
	fnFloat64FromInt64,
	fnFloat64FromNat64,
	fnLessFloat32,
	fnLessFloat64,
	fnLessInt8,
	fnLessInt16,
	fnLessInt32,
	fnLessInt64,
	fnLessNat8,
	fnLessNat16,
	fnLessNat32,
	fnLessNat64,
	fnMulFloat32,
	fnMulFloat64,
	fnSubFloat32,
	fnSubFloat64,
	fnTruncateToInt64FromFloat64,
	fnUnsafeBitShiftLeftNat64,
	fnUnsafeBitShiftRightNat64,
	fnUnsafeDivFloat32,
	fnUnsafeDivFloat64,
	fnUnsafeDivInt8,
	fnUnsafeDivInt16,
	fnUnsafeDivInt32,
	fnUnsafeDivInt64,
	fnUnsafeDivNat8,
	fnUnsafeDivNat16,
	fnUnsafeDivNat32,
	fnUnsafeDivNat64,
	fnUnsafeModNat64,
	fnWrapAddIntegral,
	fnWrapMulIntegral,
	fnWrapSubIntegral;
import interpret.bytecode : ByteCodeIndex, ByteCodeSource, Operation, stackEntrySize;
import interpret.bytecodeWriter :
	ByteCodeWriter,
	nextByteCodeIndex,
	fillDelayedJumpIfFalse,
	fillDelayedSwitchEntry,
	fillInJumpDelayed,
	getNextStackEntry,
	JumpIfFalseDelayed,
	setNextStackEntry,
	StackEntries,
	stackEntriesEnd,
	StackEntry,
	SwitchDelayed,
	writeAbort,
	writeAddConstantNat64,
	writeCallDelayed,
	writeCallFunPointer,
	writeDup,
	writeDupEntries,
	writeFnBinary,
	writeFnTernary,
	writeFnUnary,
	writeInterpreterBacktrace,
	writeMulConstantNat64,
	writePushConstant,
	writePushConstantPointer,
	writePushEmptySpace,
	writePushFunPointerDelayed,
	writeJump,
	writeJumpDelayed,
	writeJumpIfFalseDelayed,
	writePack,
	writeStackRef,
	writeRead,
	writeRemove,
	writeReturn,
	writeReturnData,
	writeSet,
	writeSwitchDelay,
	writeSwitchFiber,
	writeThreadLocalPtr,
	writeWrite;
import interpret.extern_ : ExternPointersForAllLibraries, FunPointer;
import interpret.funToReferences :
	FunPointerTypeToDynCallSig, FunToReferences, registerCall, registerFunPointerReference;
import interpret.generateText :
	getTextInfoForArray, getTextPointer, getTextPointerForCString, TextArrInfo, TextInfo, VarsInfo;
import interpret.runBytecode : opInitStack, opSwitchFiber;
import model.constant : Constant;
import model.lowModel :
	asPtrRawPointee,
	funPtrType,
	LowExpr,
	LowExprKind,
	LowField,
	LowFunExprBody,
	LowFunIndex,
	LowLocal,
	LowProgram,
	LowRecord,
	LowType,
	LowVar,
	LowVarIndex,
	PrimitiveType,
	targetIsPointer,
	targetRecordType,
	UpdateParam;
import model.model : BuiltinBinary, BuiltinTernary, BuiltinUnary, Program;
import model.typeLayout : nStackEntriesForType, optPack, Pack, typeSizeBytes;
import util.alloc.alloc : TempAlloc;
import util.col.array : indexOfPointer, isEmpty;
import util.col.arrayBuilder : add;
import util.col.map : mustGet;
import util.col.mutArr : clearAndFree, MutArr, push;
import util.col.stackMap : StackMap, stackMapAdd, stackMapMustGet;
import util.conv : bitsOfFloat32, bitsOfFloat64;
import util.integralValues : IntegralValue;
import util.opt : force, has, Opt;
import util.symbol : Symbol;
import util.union_ : TaggedUnion;
import util.util : castNonScope, castNonScope_ref, divRoundUp, ptrTrustMe, todo;

void generateFunFromExpr(
	ref TempAlloc tempAlloc,
	scope ref ByteCodeWriter writer,
	in Program program,
	in LowProgram lowProgram,
	in TextInfo textInfo,
	in VarsInfo varsInfo,
	ExternPointersForAllLibraries externPointers,
	LowFunIndex funIndex,
	ref FunToReferences funToReferences,
	in LowLocal[] curFunParams,
	in StackEntries[] parameters,
	size_t returnEntries,
	in LowFunExprBody body_,
) {
	ExprCtx ctx = ExprCtx(
		ptrTrustMe(lowProgram),
		ptrTrustMe(textInfo),
		ptrTrustMe(varsInfo),
		externPointers,
		funIndex,
		returnEntries,
		ptrTrustMe(tempAlloc),
		ptrTrustMe(funToReferences),
		nextByteCodeIndex(writer),
		castNonScope(curFunParams),
		castNonScope(parameters));
	Locals locals;
	StackEntries returnStackEntries = StackEntries(StackEntry(0), returnEntries);
	ExprAfter after = ExprAfter(returnStackEntries, ExprAfterKind(ExprAfterKind.Return()));
	generateExpr(castNonScope_ref(writer), ctx, locals, after, body_.expr);
	assert(getNextStackEntry(writer).entry == returnEntries);
}

private:

struct ExprAfter {
	// Return value should go here. (Shift it left to cover anything left by a 'let'.)
	immutable StackEntries returnValueStackEntries;
	ExprAfterKind kind;
}

struct ExprAfterKind {
	// Continue means: Just leave the value on the stack. (Still make sure to pop to 'toStackDepth')
	// No relation to loop 'continue'!
	immutable struct Continue {}
	struct JumpDelayed {
		@safe @nogc pure nothrow:

		MutArr!ByteCodeIndex* delayedJumps;

		@system const(void*) asPointerForTaggedUnion() const =>
			cast(void*) delayedJumps;
		@system static JumpDelayed fromPointerForTaggedUnion(void* a) =>
			JumpDelayed(cast(MutArr!ByteCodeIndex*) a);
	}
	struct Loop {
		immutable ByteCodeIndex loopTop; // used by 'continue'
		immutable StackEntry stackBeforeLoop;
		ExprAfter* afterBreak;
	}
	immutable struct Return {}

	mixin TaggedUnion!(Continue, JumpDelayed, Loop*, Return);
}

void handleAfter(
	ref ByteCodeWriter writer,
	ref ExprCtx ctx,
	ByteCodeSource source,
	scope ref ExprAfter after,
) {
	handleAfterReturnData(writer, source, after.returnValueStackEntries);
	after.kind.match!void(
		(ExprAfterKind.Continue) {},
		(ExprAfterKind.JumpDelayed x) {
			immutable ByteCodeIndex delayed = writeJumpDelayed(writer, source);
			push(ctx.tempAlloc, *x.delayedJumps, delayed);
		},
		(scope ref ExprAfterKind.Loop) {
			// Only 'break' or 'continue' possible here, and they don't call 'handleAfter' normally
			assert(false);
		},
		(ExprAfterKind.Return) {
			writeReturn(writer, source);
		});
}

void handleAfterReturnData(ref ByteCodeWriter writer, ByteCodeSource source, StackEntries returnValueStackEntries) {
	writeReturnData(writer, source, returnValueStackEntries);
	assert(getNextStackEntry(writer) == stackEntriesEnd(returnValueStackEntries));
}

struct ExprCtx {
	@safe @nogc pure nothrow:

	immutable LowProgram* programPtr;
	immutable TextInfo* textInfoPtr;
	immutable VarsInfo* varsInfoPtr;
	ExternPointersForAllLibraries externPointers;
	immutable LowFunIndex curFunIndex;
	immutable size_t returnTypeSizeInStackEntries;
	TempAlloc* tempAllocPtr;
	FunToReferences* funToReferencesPtr;
	immutable ByteCodeIndex startOfCurrentFun;
	immutable LowLocal[] curFunParams;
	immutable StackEntries[] parameterEntries;

	ref LowProgram program() return scope const =>
		*programPtr;
	ref TextInfo textInfo() return scope const =>
		*textInfoPtr;
	ref VarsInfo varsInfo() return scope const =>
		*varsInfoPtr;
	ref TempAlloc tempAlloc() return scope =>
		*tempAllocPtr;
	ref FunToReferences funToReferences() return scope =>
		*funToReferencesPtr;
	FunPointerTypeToDynCallSig funPtrTypeToDynCallSig() =>
		funToReferences.funPtrTypeToDynCallSig;
}

size_t typeSizeBytes(in ExprCtx ctx, LowType t) =>
	typeSizeBytes(ctx.program, t);

size_t nStackEntriesForType(in ExprCtx ctx, LowType t) =>
	nStackEntriesForType(ctx.program, t);

size_t nStackEntriesForRecordType(in ExprCtx ctx, LowType.Record t) {
	LowType type = LowType(t);
	return nStackEntriesForType(ctx, type);
}

size_t nStackEntriesForUnionType(in ExprCtx ctx, LowType.Union t) {
	LowType type = LowType(t);
	return nStackEntriesForType(ctx, type);
}

alias Locals = StackMap!(LowLocal*, StackEntries);
alias addLocal = stackMapAdd!(LowLocal*, StackEntries);
StackEntries getLocal(in ExprCtx ctx, in Locals locals, in LowLocal* local) {
	Opt!size_t paramIndex = indexOfPointer(ctx.curFunParams, local);
	return has(paramIndex)
		? ctx.parameterEntries[force(paramIndex)]
		: stackMapMustGet!(LowLocal*, StackEntries)(locals, local);
}

void generateExpr(
	ref ByteCodeWriter writer,
	ref ExprCtx ctx,
	in Locals locals,
	scope ref ExprAfter after,
	in LowExpr expr,
) {
	assert(after.returnValueStackEntries.size == nStackEntriesForType(ctx, expr.type));
	ByteCodeSource source = ByteCodeSource(ctx.curFunIndex, expr.source.range.start);
	expr.kind.matchIn!void(
		(in LowExprKind.Abort x) {
			writeAbort(writer, source);
			setNextStackEntry(writer, stackEntriesEnd(after.returnValueStackEntries));
		},
		(in LowExprKind.Call it) {
			StackEntry stackEntryBeforeArgs = getNextStackEntry(writer);
			size_t expectedStackEffect = after.returnValueStackEntries.size;
			generateArgsAndContinue(writer, ctx, locals, it.args);
			ByteCodeIndex where = writeCallDelayed(writer, source, stackEntryBeforeArgs, expectedStackEffect);
			registerCall(ctx.tempAlloc, ctx.funToReferences, it.called, where);
			assert(stackEntryBeforeArgs.entry + expectedStackEffect == getNextStackEntry(writer).entry);
			//TODO: do a tailcall if possible
			handleAfter(writer, ctx, source, after);
		},
		(in LowExprKind.CallFunPointer x) {
			StackEntry stackEntryBeforeArgs = getNextStackEntry(writer);
			generateExprAndContinue(writer, ctx, locals, *x.funPtr);
			generateArgsAndContinue(writer, ctx, locals, x.args);
			writeCallFunPointer(writer, source, stackEntryBeforeArgs, ctx.funPtrTypeToDynCallSig[funPtrType(x)]);
			handleAfter(writer, ctx, source, after);
		},
		(in LowExprKind.CreateRecord it) {
			generateCreateRecord(writer, ctx, expr.type.as!(LowType.Record), source, locals, it);
			handleAfter(writer, ctx, source, after);
		},
		(in LowExprKind.CreateUnion it) {
			generateCreateUnion(writer, ctx, expr.type.as!(LowType.Union), source, locals, it);
			handleAfter(writer, ctx, source, after);
		},
		(in LowExprKind.FunPointer x) {
			writeConstantFunPointer(writer, ctx, source, expr.type, x.fun);
			handleAfter(writer, ctx, source, after);
		},
		(in LowExprKind.If it) {
			generateIf(
				writer, ctx, source, locals, after, it.cond,
				(ref ExprAfter innerAfter) {
					generateExpr(writer, ctx, locals, innerAfter, it.then);
				},
				(ref ExprAfter innerAfter) {
					generateExpr(writer, ctx, locals, innerAfter, it.else_);
				});
		},
		(in LowExprKind.InitConstants) {
			// bytecode interpreter doesn't need to do anything in 'init-constants'
			handleAfter(writer, ctx, source, after);
		},
		(in LowExprKind.Let it) =>
			generateLet(writer, ctx, locals, after, it),
		(in LowExprKind.LocalGet it) {
			StackEntries entries = getLocal(ctx, locals, it.local);
			if (entries.size != 0)
				writeDupEntries(writer, source, entries);
			handleAfter(writer, ctx, source, after);
		},
		(in LowExprKind.LocalSet it) {
			StackEntries entries = getLocal(ctx, locals, it.local);
			generateExprAndContinue(writer, ctx, locals, it.value);
			if (entries.size != 0)
				writeSet(writer, source, entries);
			handleAfter(writer, ctx, source, after);
		},
		(in LowExprKind.Loop x) {
			generateLoop(writer, ctx, locals, after, x);
		},
		(in LowExprKind.LoopBreak x) {
			generateExpr(writer, ctx, locals, *after.kind.as!(ExprAfterKind.Loop*).afterBreak, x.value);
		},
		(in LowExprKind.LoopContinue x) {
			generateLoopContinue(writer, ctx, source, locals, after, x);
		},
		(in LowExprKind.PtrCast it) {
			generateExpr(writer, ctx, locals, after, it.target);
		},
		(in LowExprKind.PtrToField x) =>
			generatePtrToField(writer, ctx, source, locals, after, x),
		(in LowExprKind.PtrToLocal x) =>
			generatePtrToLocal(writer, ctx, source, locals, after, x.local),
		(in LowExprKind.RecordFieldGet it) {
			generateRecordFieldGet(writer, ctx, source, locals, it);
			handleAfter(writer, ctx, source, after);
		},
		(in LowExprKind.RecordFieldSet x) {
			generateRecordFieldSet(writer, ctx, source, locals, x);
			handleAfter(writer, ctx, source, after);
		},
		(in Constant it) {
			generateConstant(writer, ctx, source, expr.type, it);
			handleAfter(writer, ctx, source, after);
		},
		(in LowExprKind.SpecialUnary it) {
			generateSpecialUnary(writer, ctx, source, locals, after, expr.type, it);
		},
		(in LowExprKind.SpecialUnaryMath x) {
			generateExprAndContinue(writer, ctx, locals, x.arg);
			writeFnUnary(writer, source, fnForUnaryMath(x.kind));
			handleAfter(writer, ctx, source, after);
		},
		(in LowExprKind.SpecialBinary x) {
			generateSpecialBinary(writer, ctx, source, locals, after, x);
		},
		(in LowExprKind.SpecialBinaryMath x) {
			foreach (scope ref LowExpr arg; castNonScope(x.args))
				generateExprAndContinue(writer, ctx, locals, arg);
			writeFnBinary(writer, source, fnForBinaryMath(x.kind));
			handleAfter(writer, ctx, source, after);
		},
		(in LowExprKind.SpecialTernary it) {
			generateSpecialTernary(writer, ctx, source, locals, after, it);
		},
		(in LowExprKind.Switch x) {
			generateSwitch(writer, ctx, source, locals, after, x);
		},
		(in LowExprKind.TailRecur it) {
			generateTailRecur(writer, ctx, source, locals, after, it);
		},
		(in LowExprKind.UnionAs x) {
			generateUnionAs(writer, ctx, source, locals, after, x);
		},
		(in LowExprKind.UnionKind x) {
			generateUnionKind(writer, ctx, source,locals, after, x);
		},
		(in LowExprKind.VarGet x) {
			LowVar var = ctx.program.vars[x.varIndex];
			writeVarPtr(writer, ctx, source, x.varIndex, var);
			writeRead(writer, source, 0, typeSizeBytes(ctx, var.type));
			handleAfter(writer, ctx, source, after);
		},
		(in LowExprKind.VarSet x) {
			LowVar var = ctx.program.vars[x.varIndex];
			writeVarPtr(writer, ctx, source, x.varIndex, var);
			generateExprAndContinue(writer, ctx, locals, *x.value);
			writeWrite(writer, source, 0, typeSizeBytes(ctx, var.type));
			handleAfter(writer, ctx, source, after);
		});
}

void writeVarPtr(
	scope ref ByteCodeWriter writer,
	scope ref ExprCtx ctx,
	ByteCodeSource source,
	LowVarIndex varIndex,
	LowVar var,
) {
	final switch (var.kind) {
		case LowVar.Kind.externGlobal:
			Opt!Symbol libName = var.externLibraryName;
			writePushConstant(
				writer, source,
				mustGet(mustGet(ctx.externPointers, force(libName)), var.name).asUlong);
			break;
		case LowVar.Kind.global:
			writePushConstant(writer, source, cast(ulong) getGlobalsPointer(ctx.varsInfo.offsetsInWords[varIndex]));
			break;
		case LowVar.Kind.threadLocal:
			writeThreadLocalPtr(writer, source, ctx.varsInfo.offsetsInWords[varIndex]);
			break;
	}
}
public @safe pure size_t maxGlobalsSizeWords() =>
	256;
__gshared ulong[maxGlobalsSizeWords] globalsStorage;
@trusted ulong* getGlobalsPointer(ulong offsetInWords) {
	ulong* function() @nogc pure nothrow getIt = cast(ulong* function() @nogc pure nothrow) () =>
		globalsStorage.ptr;
	assert(offsetInWords < maxGlobalsSizeWords);
	return getIt() + offsetInWords;
}

void generateExprAndContinue(
	ref ByteCodeWriter writer,
	ref ExprCtx ctx,
	in Locals locals,
	in LowExpr expr,
) {
	ExprAfter after = ExprAfter(
		StackEntries(getNextStackEntry(writer), nStackEntriesForType(ctx, expr.type)),
		ExprAfterKind(ExprAfterKind.Continue()));
	generateExpr(writer, ctx, locals, after, expr);
}

void generateLet(
	ref ByteCodeWriter writer,
	ref ExprCtx ctx,
	in Locals locals,
	scope ref ExprAfter after,
	in LowExprKind.Let a,
) {
	StackEntries localEntries = StackEntries(getNextStackEntry(writer), nStackEntriesForType(ctx, a.local.type));
	generateExprAndContinue(writer, ctx, locals, a.value);
	assert(getNextStackEntry(writer) == stackEntriesEnd(localEntries));
	generateExpr(writer, ctx, addLocal(locals, a.local, localEntries), after, a.then);
}

@trusted void generateLoop(
	ref ByteCodeWriter writer,
	ref ExprCtx ctx,
	in Locals locals,
	scope ref ExprAfter after,
	in LowExprKind.Loop a,
) {
	StackEntry stackBeforeLoop = getNextStackEntry(writer);
	withBranching(writer, ctx, after, (ref ExprAfter afterBranch, ref ExprAfter afterLastBranch) {
		ByteCodeIndex loopTop = nextByteCodeIndex(writer);
		ExprAfterKind.Loop loop = ExprAfterKind.Loop(loopTop, stackBeforeLoop, ptrTrustMe(afterBranch));
		scope ExprAfter loopAfter = ExprAfter(after.returnValueStackEntries, ExprAfterKind(&loop));
		// the loop always ends in a 'break' or 'continue' which will know what to do
		generateExpr(writer, ctx, locals, loopAfter, a.body_);
	});
	// We're after the 'break' now, so the loop result is on the stack
	setNextStackEntry(writer, stackEntriesEnd(after.returnValueStackEntries));
}

void generateLoopContinue(
	ref ByteCodeWriter writer,
	ref ExprCtx ctx,
	ByteCodeSource source,
	in Locals locals,
	scope ref ExprAfter after,
	in LowExprKind.LoopContinue a,
) {
	ExprAfterKind.Loop* loop = after.kind.as!(ExprAfterKind.Loop*);
	// Need to clean up any temporaries before doing the loop again
	handleAfterReturnData(writer, source, StackEntries(loop.stackBeforeLoop, 0));
	writeJump(writer, source, loop.loopTop);
	setNextStackEntry(writer, stackEntriesEnd(after.returnValueStackEntries));
}

void generateUnionAs(
	ref ByteCodeWriter writer,
	ref ExprCtx ctx,
	ByteCodeSource source,
	in Locals locals,
	scope ref ExprAfter after,
	in LowExprKind.UnionAs a,
) {
	StackEntry startStack = getNextStackEntry(writer);
	generateExprAndContinue(writer, ctx, locals, *a.union_);
	size_t unionEntries = getNextStackEntry(writer).entry - startStack.entry;
	assert(unionEntries == nStackEntriesForType(ctx, a.union_.type));
	// Remove extra space after the member
	LowType memberType = ctx.program.allUnions[a.union_.type.as!(LowType.Union)].members[a.memberIndex];
	size_t memberEntries = nStackEntriesForType(ctx, memberType);
	writeRemove(writer, source, StackEntries(
		StackEntry(startStack.entry + 1 + memberEntries),
		unionEntries - 1 - memberEntries));
	// Remove the kind
	writeRemove(writer, source, StackEntries(startStack, 1));
	handleAfter(writer, ctx, source, after);
}

void generateUnionKind(
	ref ByteCodeWriter writer,
	ref ExprCtx ctx,
	ByteCodeSource source,
	in Locals locals,
	scope ref ExprAfter after,
	in LowExprKind.UnionKind a,
) {
	StackEntry startStack = getNextStackEntry(writer);
	generateExprAndContinue(writer, ctx, locals, *a.union_);
	size_t unionEntries = getNextStackEntry(writer).entry - startStack.entry;
	assert(unionEntries == nStackEntriesForType(ctx, a.union_.type));
	writeRemove(writer, source, StackEntries(StackEntry(startStack.entry + 1), unionEntries - 1));
	handleAfter(writer, ctx, source, after);
}

void generateSwitch(
	ref ByteCodeWriter writer,
	ref ExprCtx ctx,
	ByteCodeSource source,
	in Locals locals,
	scope ref ExprAfter after,
	in LowExprKind.Switch a,
 ) {
	StackEntry stackBefore = getNextStackEntry(writer);
	generateExprAndContinue(writer, ctx, locals, a.value);
	bool defaultAbort = a.default_.kind.isA!(LowExprKind.Abort);
	SwitchDelayed delayed = writeSwitchDelay(writer, source, a.caseValues, !defaultAbort);
	withBranching(writer, ctx, after, (ref ExprAfter afterBranch, ref ExprAfter afterLastBranch) {
		void writeCaseOrDefault(size_t index, ref LowExpr expr, bool isLast) {
			fillDelayedSwitchEntry(writer, delayed, index);
			generateExpr(writer, ctx, locals, isLast ? afterLastBranch : afterBranch, expr);
			if (!isLast)
				setNextStackEntry(writer, stackBefore);
		}
		foreach (size_t caseIndex, ref LowExpr case_; a.caseExprs)
			writeCaseOrDefault(caseIndex, case_, defaultAbort && caseIndex == a.caseExprs.length - 1);
		if (!defaultAbort)
			writeCaseOrDefault(a.caseExprs.length, a.default_, true);
	});
}

void generateTailRecur(
	ref ByteCodeWriter writer,
	ref ExprCtx ctx,
	ByteCodeSource source,
	in Locals locals,
	scope ref ExprAfter after,
	in LowExprKind.TailRecur a,
) {
	// We need to generate all new values before overwriting anything.
	foreach (ref UpdateParam updateParam; a.updateParams)
		generateExprAndContinue(writer, ctx, locals, updateParam.newValue);
	// Now pop them in reverse and write to the appropriate params
	foreach_reverse (ref UpdateParam updateParam; a.updateParams)
		writeSet(writer, source, getLocal(ctx, locals, updateParam.param));

	// Delete anything on the stack besides parameters
	assert(after.kind.isA!(ExprAfterKind.Return));
	assert(after.returnValueStackEntries.start.entry == 0);
	StackEntry parametersEnd = isEmpty(ctx.parameterEntries)
		? StackEntry(0)
		: stackEntriesEnd(ctx.parameterEntries[$ - 1]);
	StackEntry localsEnd = getNextStackEntry(writer);
	writeRemove(writer, source, StackEntries(parametersEnd, localsEnd.entry - parametersEnd.entry));
	writeJump(writer, source, ctx.startOfCurrentFun);

	// Fake the stack as if this were a normal call and return
	setNextStackEntry(writer, StackEntry(ctx.returnTypeSizeInStackEntries));
}

void generateArgsAndContinue(ref ByteCodeWriter writer, ref ExprCtx ctx, in Locals locals, in LowExpr[] args) {
	foreach (ref LowExpr arg; args)
		generateExprAndContinue(writer, ctx, locals, arg);
}

void generateCreateRecord(
	ref ByteCodeWriter writer,
	ref ExprCtx ctx,
	LowType.Record type,
	ByteCodeSource source,
	in Locals locals,
	in LowExprKind.CreateRecord it,
) {
	generateCreateRecordOrConstantRecord(
		writer,
		ctx,
		type,
		source,
		(size_t fieldIndex, LowType fieldType) {
			LowExpr arg = it.args[fieldIndex];
			assert(arg.type == fieldType);
			generateExprAndContinue(writer, ctx, locals, arg);
		});
}

void generateCreateRecordOrConstantRecord(
	ref ByteCodeWriter writer,
	ref ExprCtx ctx,
	LowType.Record type,
	ByteCodeSource source,
	in void delegate(size_t, LowType) @safe @nogc pure nothrow cbGenerateField,
) {
	StackEntry before = getNextStackEntry(writer);

	LowRecord record = ctx.program.allRecords[type];
	foreach (size_t i, ref LowField field; record.fields)
		cbGenerateField(i, field.type);

	Opt!Pack optPack = optPack(ctx.tempAlloc, ctx.program, type);
	if (has(optPack))
		writePack(writer, source, force(optPack));

	assert(getNextStackEntry(writer).entry - before.entry == nStackEntriesForRecordType(ctx, type));
}

void generateCreateUnion(
	ref ByteCodeWriter writer,
	ref ExprCtx ctx,
	LowType.Union type,
	ByteCodeSource source,
	in Locals locals,
	in LowExprKind.CreateUnion it,
) {
	generateCreateUnionOrConstantUnion(
		writer,
		ctx,
		type,
		it.memberIndex,
		source,
		(LowType) {
			generateExprAndContinue(writer, ctx, locals, it.arg);
		});
}

void generateCreateUnionOrConstantUnion(
	ref ByteCodeWriter writer,
	ref const ExprCtx ctx,
	LowType.Union type,
	size_t memberIndex,
	ByteCodeSource source,
	in void delegate(LowType) @safe @nogc pure nothrow cbGenerateMember,
) {
	StackEntry before = getNextStackEntry(writer);
	size_t size = nStackEntriesForUnionType(ctx, type);
	writePushConstant(writer, source, memberIndex);
	LowType memberType = ctx.program.allUnions[type].members[memberIndex];
	cbGenerateMember(memberType);
	StackEntry after = getNextStackEntry(writer);
	if (before.entry + size != after.entry) {
		// Some members of a union are smaller than the union.
		assert(before.entry + size > after.entry);
		writePushEmptySpace(writer, source, before.entry + size - after.entry);
	}
}

immutable struct FieldOffsetAndSize {
	size_t offset;
	size_t size;
}

FieldOffsetAndSize getFieldOffsetAndSize(ref const ExprCtx ctx, LowType.Record record, size_t fieldIndex) {
	LowField field = ctx.program.allRecords[record].fields[fieldIndex];
	return FieldOffsetAndSize(field.offset, typeSizeBytes(ctx, field.type));
}

void generateConstant(
	ref ByteCodeWriter writer,
	ref ExprCtx ctx,
	ByteCodeSource source,
	in LowType type,
	in Constant constant,
) {
	constant.matchIn!void(
		(in Constant.ArrConstant it) {
			TextArrInfo info = getTextInfoForArray(ctx.textInfo, ctx.program.allConstants, it);
			writePushConstant(writer, source, info.size);
			writePushConstantPointer(writer, source, info.textPtr);
		},
		(in Constant.CString it) {
			writePushConstantPointer(writer, source, getTextPointerForCString(ctx.textInfo, it));
		},
		(in Constant.Float it) {
			switch (type.as!PrimitiveType) {
				case PrimitiveType.float32:
					writePushConstant(writer, source, bitsOfFloat32(cast(float) it.value));
					break;
				case PrimitiveType.float64:
					writePushConstant(writer, source, bitsOfFloat64(it.value));
					break;
				default:
					assert(false);
			}
		},
		(in Constant.FunPointer x) {
			writeConstantFunPointer(writer, ctx, source, type, mustGet(ctx.program.concreteFunToLowFunIndex, x.fun));
		},
		(in IntegralValue it) {
			writePushConstant(writer, source, it.value);
		},
		(in Constant.Pointer it) {
			immutable ubyte* pointer = getTextPointer(ctx.textInfo, it);
			writePushConstantPointer(writer, source, pointer);
		},
		(in Constant.Record it) {
			generateCreateRecordOrConstantRecord(
				writer,
				ctx,
				type.as!(LowType.Record),
				source,
				(size_t argIndex, LowType argType) {
					generateConstant(writer, ctx, source, argType, it.args[argIndex]);
				});
		},
		(in Constant.Union x) {
			generateCreateUnionOrConstantUnion(
				writer,
				ctx,
				type.as!(LowType.Union),
				x.memberIndex,
				source,
				(LowType memberType) {
					generateConstant(writer, ctx, source, memberType, x.arg);
				});
		},
		(in Constant.Zero) {
			writeZeroed(writer, source, typeSizeBytes(ctx, type));
		});
}

void writeConstantFunPointer(
	scope ref ByteCodeWriter writer,
	ref ExprCtx ctx,
	ByteCodeSource source,
	in LowType type,
	LowFunIndex fun,
) {
	ByteCodeIndex where = writePushFunPointerDelayed(writer, source);
	registerFunPointerReference(ctx.tempAlloc, ctx.funToReferences, type.as!(LowType.FunPointer), fun, where);
}

void writeZeroed(ref ByteCodeWriter writer, ByteCodeSource source, size_t sizeBytes) {
	foreach (size_t i; 0 .. divRoundUp(sizeBytes, stackEntrySize))
		writePushConstant(writer, source, 0);
}

void generateSpecialUnary(
	ref ByteCodeWriter writer,
	ref ExprCtx ctx,
	ByteCodeSource source,
	in Locals locals,
	scope ref ExprAfter after,
	in LowType type,
	in LowExprKind.SpecialUnary a,
) {
	void generateArg() {
		generateExprAndContinue(writer, ctx, locals, a.arg);
	}

	void fn(Operation.Fn fn) {
		generateArg();
		writeFnUnary(writer, source, fn);
		handleAfter(writer, ctx, source, after);
	}

	final switch (a.kind) {
		case BuiltinUnary.asAnyPtr:
		case BuiltinUnary.enumToIntegral:
		case BuiltinUnary.referenceFromPointer:
		case BuiltinUnary.toChar8FromNat8:
		case BuiltinUnary.toNat8FromChar8:
		case BuiltinUnary.toNat32FromChar32:
		case BuiltinUnary.toNat64FromPtr:
		case BuiltinUnary.toPtrFromNat64:
		case BuiltinUnary.unsafeToChar32FromChar8:
		case BuiltinUnary.unsafeToChar32FromNat32:
		case BuiltinUnary.unsafeToInt8FromInt64:
		case BuiltinUnary.unsafeToInt16FromInt64:
		case BuiltinUnary.unsafeToInt32FromInt64:
		case BuiltinUnary.unsafeToInt64FromNat64:
		case BuiltinUnary.unsafeToNat8FromNat64:
		case BuiltinUnary.unsafeToNat16FromNat64:
		case BuiltinUnary.unsafeToNat32FromInt32:
		case BuiltinUnary.unsafeToNat32FromNat64:
		case BuiltinUnary.unsafeToNat64FromInt64:
			// do nothing (doesn't change the bits, just their type)
			// Some of these widen, but all fit within the one stack entry so nothing to do
			// NOTE: we treat the upper bits of <64-bit types as arbitrary, so those are no-ops too
			generateExpr(writer, ctx, locals, after, a.arg);
			break;
		case BuiltinUnary.bitwiseNotNat8:
		case BuiltinUnary.bitwiseNotNat16:
		case BuiltinUnary.bitwiseNotNat32:
		case BuiltinUnary.bitwiseNotNat64:
			fn(&fnBitwiseNot);
			break;
		case BuiltinUnary.countOnesNat64:
			fn(&fnCountOnesNat64);
			break;
		case BuiltinUnary.drop:
			generateExprAndContinue(writer, ctx, locals, a.arg);
			handleAfter(writer, ctx, source, after);
			break;
		case BuiltinUnary.toInt64FromInt8:
			fn(&fnInt64FromInt8);
			break;
		case BuiltinUnary.toInt64FromInt16:
			fn(&fnInt64FromInt16);
			break;
		case BuiltinUnary.toInt64FromInt32:
			fn(&fnInt64FromInt32);
			break;
		// Normal operations on <64-bit values treat other bits as garbage
		// (they may be written to, such as in a wrap-add operation that overflows)
		// So we must mask out just the lower bits now.
		case BuiltinUnary.toNat64FromNat8:
			generateArg();
			writePushConstant(writer, source, ubyte.max);
			writeFnBinary(writer, source, &fnBitwiseAnd);
			handleAfter(writer, ctx, source, after);
			break;
		case BuiltinUnary.toNat64FromNat16:
			generateArg();
			writePushConstant(writer, source, ushort.max);
			writeFnBinary(writer, source, &fnBitwiseAnd);
			handleAfter(writer, ctx, source, after);
			break;
		case BuiltinUnary.toNat64FromNat32:
			generateArg();
			writePushConstant(writer, source, uint.max);
			writeFnBinary(writer, source, &fnBitwiseAnd);
			handleAfter(writer, ctx, source, after);
			break;
		case BuiltinUnary.deref:
			generateArg();
			size_t size = typeSizeBytes(ctx, type);
			if (size != 0)
				writeRead(writer, source, 0, size);
			handleAfter(writer, ctx, source, after);
			break;
		case BuiltinUnary.toFloat32FromFloat64:
			fn(&fnFloat32FromFloat64);
			break;
		case BuiltinUnary.toFloat64FromFloat32:
			fn(&fnFloat64FromFloat32);
			break;
		case BuiltinUnary.toFloat64FromInt64:
			fn(&fnFloat64FromInt64);
			break;
		case BuiltinUnary.toFloat64FromNat64:
			fn(&fnFloat64FromNat64);
			break;
		case BuiltinUnary.truncateToInt64FromFloat64:
			fn(&fnTruncateToInt64FromFloat64);
			break;
	}
}

void generatePtrToLocal(
	ref ByteCodeWriter writer,
	ref ExprCtx ctx,
	ByteCodeSource source,
	in Locals locals,
	scope ref ExprAfter after,
	in LowLocal* local,
) {
	writeStackRef(writer, source, getLocal(ctx, locals, local).start);
	handleAfter(writer, ctx, source, after);
}

void generatePtrToField(
	ref ByteCodeWriter writer,
	ref ExprCtx ctx,
	ByteCodeSource source,
	in Locals locals,
	scope ref ExprAfter after,
	in LowExprKind.PtrToField a,
) {
	size_t offset = ctx.program.allRecords[targetRecordType(a)].fields[a.fieldIndex].offset;
	if (offset != 0) {
		generateExprAndContinue(writer, ctx, locals, a.target);
		writeAddConstantNat64(writer, source, offset);
		handleAfter(writer, ctx, source, after);
	} else
		generateExpr(writer, ctx, locals, after, a.target);
}

void generateRecordFieldGet(
	ref ByteCodeWriter writer,
	ref ExprCtx ctx,
	ByteCodeSource source,
	in Locals locals,
	in LowExprKind.RecordFieldGet a,
) {
	StackEntry targetEntry = getNextStackEntry(writer);
	generateExprAndContinue(writer, ctx, locals, *a.target);
	StackEntries targetEntries = StackEntries(
		targetEntry,
		getNextStackEntry(writer).entry - targetEntry.entry);
	FieldOffsetAndSize offsetAndSize = getFieldOffsetAndSize(ctx, targetRecordType(a), a.fieldIndex);
	if (targetIsPointer(a)) {
		if (offsetAndSize.size == 0)
			writeRemove(writer, source, targetEntries);
		else
			writeRead(writer, source, offsetAndSize.offset, offsetAndSize.size);
	} else {
		if (offsetAndSize.size != 0) {
			StackEntry firstEntry = StackEntry(targetEntry.entry + (offsetAndSize.offset / stackEntrySize));
			writeDup(
				writer,
				source,
				firstEntry,
				offsetAndSize.offset % stackEntrySize,
				offsetAndSize.size);
		}
		writeRemove(writer, source, targetEntries);
	}
}

void generateRecordFieldSet(
	ref ByteCodeWriter writer,
	ref ExprCtx ctx,
	ByteCodeSource source,
	in Locals locals,
	in LowExprKind.RecordFieldSet a,
) {
	StackEntry before = getNextStackEntry(writer);
	assert(targetIsPointer(a));
	generateExprAndContinue(writer, ctx, locals, a.target);
	StackEntry mid = getNextStackEntry(writer);
	generateExprAndContinue(writer, ctx, locals, a.value);
	FieldOffsetAndSize offsetAndSize = getFieldOffsetAndSize(ctx, targetRecordType(a), a.fieldIndex);
	assert(mid.entry + divRoundUp(offsetAndSize.size, stackEntrySize) == getNextStackEntry(writer).entry);
	writeWrite(writer, source, offsetAndSize.offset, offsetAndSize.size);
	assert(getNextStackEntry(writer) == before);
}

void generateSpecialTernary(
	ref ByteCodeWriter writer,
	ref ExprCtx ctx,
	ByteCodeSource source,
	in Locals locals,
	scope ref ExprAfter after,
	in LowExprKind.SpecialTernary a,
) {
	foreach (ref LowExpr arg; castNonScope(a).args)
		generateExprAndContinue(writer, ctx, locals, arg);
	final switch (a.kind) {
		case BuiltinTernary.initStack:
			writeFnTernary(writer, source, &opInitStack);
			break;
		case BuiltinTernary.interpreterBacktrace:
			writeInterpreterBacktrace(writer, source);
			handleAfter(writer, ctx, source, after);
			break;
	}
}

void generateSpecialBinary(
	ref ByteCodeWriter writer,
	ref ExprCtx ctx,
	ByteCodeSource source,
	in Locals locals,
	scope ref ExprAfter after,
	in LowExprKind.SpecialBinary a,
) {
	LowExpr left = a.args[0], right = a.args[1];
	void fn(Operation.Fn fn, bool returnVoid = false) {
		generateExprAndContinue(writer, ctx, locals, left);
		generateExprAndContinue(writer, ctx, locals, right);
		writeFnBinary(writer, source, fn, returnVoid);
		handleAfter(writer, ctx, source, after);
	}

	final switch (a.kind) {
		case BuiltinBinary.addPointerAndNat64:
		case BuiltinBinary.subPointerAndNat64:
			LowType pointee = asPtrRawPointee(left.type);
			generateExprAndContinue(writer, ctx, locals, left);
			StackEntry afterLeft = getNextStackEntry(writer);
			generateExprAndContinue(writer, ctx, locals, right);
			size_t pointeeSize = typeSizeBytes(ctx, pointee);
			if (pointeeSize != 0 && pointeeSize != 1)
				writeMulConstantNat64(writer, source, pointeeSize);

			if (pointeeSize == 0)
				writeRemove(writer, source, StackEntries(afterLeft, 1));
			else
				writeFnBinary(
					writer, source, a.kind == BuiltinBinary.addPointerAndNat64 ? &fnWrapAddIntegral : &fnWrapSubIntegral);
			handleAfter(writer, ctx, source, after);
			break;
		case BuiltinBinary.addFloat32:
			fn(&fnAddFloat32);
			break;
		case BuiltinBinary.addFloat64:
			fn(&fnAddFloat64);
			break;
		case BuiltinBinary.unsafeBitShiftLeftNat64:
			fn(&fnUnsafeBitShiftLeftNat64);
			break;
		case BuiltinBinary.unsafeBitShiftRightNat64:
			fn(&fnUnsafeBitShiftRightNat64);
			break;
		case BuiltinBinary.bitwiseAndInt8:
		case BuiltinBinary.bitwiseAndInt16:
		case BuiltinBinary.bitwiseAndInt32:
		case BuiltinBinary.bitwiseAndInt64:
		case BuiltinBinary.bitwiseAndNat8:
		case BuiltinBinary.bitwiseAndNat16:
		case BuiltinBinary.bitwiseAndNat32:
		case BuiltinBinary.bitwiseAndNat64:
			fn(&fnBitwiseAnd);
			break;
		case BuiltinBinary.bitwiseOrInt8:
		case BuiltinBinary.bitwiseOrInt16:
		case BuiltinBinary.bitwiseOrInt32:
		case BuiltinBinary.bitwiseOrInt64:
		case BuiltinBinary.bitwiseOrNat8:
		case BuiltinBinary.bitwiseOrNat16:
		case BuiltinBinary.bitwiseOrNat32:
		case BuiltinBinary.bitwiseOrNat64:
			fn(&fnBitwiseOr);
			break;
		case BuiltinBinary.bitwiseXorInt8:
		case BuiltinBinary.bitwiseXorInt16:
		case BuiltinBinary.bitwiseXorInt32:
		case BuiltinBinary.bitwiseXorInt64:
		case BuiltinBinary.bitwiseXorNat8:
		case BuiltinBinary.bitwiseXorNat16:
		case BuiltinBinary.bitwiseXorNat32:
		case BuiltinBinary.bitwiseXorNat64:
			fn(&fnBitwiseXor);
			break;
		case BuiltinBinary.eqFloat32:
			fn(&fnEqFloat32);
			break;
		case BuiltinBinary.eqFloat64:
			fn(&fnEqFloat64);
			break;
		case BuiltinBinary.eqChar8:
		case BuiltinBinary.eqInt8:
		case BuiltinBinary.eqNat8:
			fn(&fnEq8Bit);
			break;
		case BuiltinBinary.eqInt16:
		case BuiltinBinary.eqNat16:
			fn(&fnEq16Bit);
			break;
		case BuiltinBinary.eqChar32:
		case BuiltinBinary.eqInt32:
		case BuiltinBinary.eqNat32:
			fn(&fnEq32Bit);
			break;
		case BuiltinBinary.eqInt64:
		case BuiltinBinary.eqNat64:
		case BuiltinBinary.eqPointer:
			fn(&fnEq64Bit);
			break;
		case BuiltinBinary.lessChar8:
		case BuiltinBinary.lessNat8:
			fn(&fnLessNat8);
			break;
		case BuiltinBinary.lessNat16:
			fn(&fnLessNat16);
			break;
		case BuiltinBinary.lessNat32:
			fn(&fnLessNat32);
			break;
		case BuiltinBinary.lessNat64:
		case BuiltinBinary.lessPointer:
			fn(&fnLessNat64);
			break;
		case BuiltinBinary.lessFloat32:
			fn(&fnLessFloat32);
			break;
		case BuiltinBinary.lessFloat64:
			fn(&fnLessFloat64);
			break;
		case BuiltinBinary.lessInt8:
			fn(&fnLessInt8);
			break;
		case BuiltinBinary.lessInt16:
			fn(&fnLessInt16);
			break;
		case BuiltinBinary.lessInt32:
			fn(&fnLessInt32);
			break;
		case BuiltinBinary.lessInt64:
			fn(&fnLessInt64);
			break;
		case BuiltinBinary.mulFloat32:
			fn(&fnMulFloat32);
			break;
		case BuiltinBinary.mulFloat64:
			fn(&fnMulFloat64);
			break;
		case BuiltinBinary.seq:
			generateExprAndContinue(writer, ctx, locals, left);
			generateExpr(writer, ctx, locals, after, right);
			break;
		case BuiltinBinary.subFloat32:
			fn(&fnSubFloat32);
			break;
		case BuiltinBinary.subFloat64:
			fn(&fnSubFloat64);
			break;
		case BuiltinBinary.switchFiber:
			fn(&opSwitchFiber, returnVoid: true);
			break;
		case BuiltinBinary.unsafeSubInt8:
		case BuiltinBinary.unsafeSubInt16:
		case BuiltinBinary.unsafeSubInt32:
		case BuiltinBinary.unsafeSubInt64:
		case BuiltinBinary.wrapSubNat8:
		case BuiltinBinary.wrapSubNat16:
		case BuiltinBinary.wrapSubNat32:
		case BuiltinBinary.wrapSubNat64:
			fn(&fnWrapSubIntegral);
			break;
		case BuiltinBinary.unsafeDivFloat32:
			fn(&fnUnsafeDivFloat32);
			break;
		case BuiltinBinary.unsafeDivFloat64:
			fn(&fnUnsafeDivFloat64);
			break;
		case BuiltinBinary.unsafeDivInt8:
			fn(&fnUnsafeDivInt8);
			break;
		case BuiltinBinary.unsafeDivInt16:
			fn(&fnUnsafeDivInt16);
			break;
		case BuiltinBinary.unsafeDivInt32:
			fn(&fnUnsafeDivInt32);
			break;
		case BuiltinBinary.unsafeDivInt64:
			fn(&fnUnsafeDivInt64);
			break;
		case BuiltinBinary.unsafeDivNat8:
			fn(&fnUnsafeDivNat8);
			break;
		case BuiltinBinary.unsafeDivNat16:
			fn(&fnUnsafeDivNat16);
			break;
		case BuiltinBinary.unsafeDivNat32:
			fn(&fnUnsafeDivNat32);
			break;
		case BuiltinBinary.unsafeDivNat64:
			fn(&fnUnsafeDivNat64);
			break;
		case BuiltinBinary.unsafeModNat64:
			fn(&fnUnsafeModNat64);
			break;
		case BuiltinBinary.unsafeAddInt8:
		case BuiltinBinary.unsafeAddInt16:
		case BuiltinBinary.unsafeAddInt32:
		case BuiltinBinary.unsafeAddInt64:
		case BuiltinBinary.wrapAddNat8:
		case BuiltinBinary.wrapAddNat16:
		case BuiltinBinary.wrapAddNat32:
		case BuiltinBinary.wrapAddNat64:
			fn(&fnWrapAddIntegral);
			break;
		case BuiltinBinary.unsafeMulInt8:
		case BuiltinBinary.unsafeMulInt16:
		case BuiltinBinary.unsafeMulInt32:
		case BuiltinBinary.unsafeMulInt64:
		case BuiltinBinary.wrapMulNat8:
		case BuiltinBinary.wrapMulNat16:
		case BuiltinBinary.wrapMulNat32:
		case BuiltinBinary.wrapMulNat64:
			fn(&fnWrapMulIntegral);
			break;
		case BuiltinBinary.writeToPointer:
			generateExprAndContinue(writer, ctx, locals, left);
			generateExprAndContinue(writer, ctx, locals, right);
			size_t size = typeSizeBytes(ctx, right.type);
			if (size != 0) {
				writeWrite(writer, source, 0, size);
			}
			handleAfter(writer, ctx, source, after);
			break;
	}
}

void generateIf(
	ref ByteCodeWriter writer,
	ref ExprCtx ctx,
	ByteCodeSource source,
	in Locals locals,
	scope ref ExprAfter after,
	in LowExpr cond,
	in void delegate(ref ExprAfter) @safe @nogc pure nothrow cbThen,
	in void delegate(ref ExprAfter) @safe @nogc pure nothrow cbElse,
) {
	StackEntry stackEntryAtStart = getNextStackEntry(writer);
	generateExprAndContinue(writer, ctx, locals, cond);
	JumpIfFalseDelayed delayed = writeJumpIfFalseDelayed(writer, source);
	withBranching(writer, ctx, after, (ref ExprAfter afterBranch, ref ExprAfter afterLastBranch) {
		cbThen(afterBranch);
		fillDelayedJumpIfFalse(writer, delayed);
		setNextStackEntry(writer, stackEntryAtStart);
		cbElse(afterLastBranch);
		assert(getNextStackEntry(writer) == stackEntriesEnd(after.returnValueStackEntries));
	});
}

@trusted void withBranching(
	ref ByteCodeWriter writer,
	ref ExprCtx ctx,
	scope ref ExprAfter after,
	// if 'after' is ExprAfterKind.Continue, last branch is different; just slides down to the result
	in void delegate(ref ExprAfter afterBranch, ref ExprAfter afterLastBranch) @safe @nogc pure nothrow cb,
) {
	bool needsJumps = after.kind.matchIn!bool(
		(in ExprAfterKind.Continue) => true,
		(in ExprAfterKind.JumpDelayed) => false,
		(in ExprAfterKind.Loop) => false,
		(in ExprAfterKind.Return) => false);
	if (needsJumps) {
		MutArr!ByteCodeIndex delayedJumps;
		ExprAfter afterBranch = ExprAfter(
			after.returnValueStackEntries,
			ExprAfterKind(ExprAfterKind.JumpDelayed(&delayedJumps)));
		cb(afterBranch, after);
		foreach (ByteCodeIndex jumpIndex; delayedJumps)
			fillInJumpDelayed(writer, jumpIndex);
		clearAndFree(ctx.tempAlloc, delayedJumps);
	} else
		cb(after, after);
}
