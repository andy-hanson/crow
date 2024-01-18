module interpret.generateExpr;

@safe @nogc pure nothrow:

import interpret.applyFn :
	fnAcosFloat32,
	fnAcosFloat64,
	fnAcoshFloat32,
	fnAcoshFloat64,
	fnAddFloat32,
	fnAddFloat64,
	fnAsinFloat32,
	fnAsinFloat64,
	fnAsinhFloat32,
	fnAsinhFloat64,
	fnAtanFloat32,
	fnAtanFloat64,
	fnAtanhFloat32,
	fnAtanhFloat64,
	fnAtan2Float32,
	fnAtan2Float64,
	fnBitwiseAnd,
	fnBitwiseNot,
	fnBitwiseOr,
	fnBitwiseXor,
	fnCountOnesNat64,
	fnCosFloat32,
	fnCosFloat64,
	fnCoshFloat32,
	fnCoshFloat64,
	fnEqBits,
	fnEqFloat32,
	fnEqFloat64,
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
	fnRoundFloat32,
	fnRoundFloat64,
	fnSinFloat32,
	fnSinFloat64,
	fnSinhFloat32,
	fnSinhFloat64,
	fnSubFloat32,
	fnSubFloat64,
	fnSqrtFloat32,
	fnSqrtFloat64,
	fnTanFloat32,
	fnTanFloat64,
	fnTanhFloat32,
	fnTanhFloat64,
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
import interpret.bytecode : ByteCodeIndex, ByteCodeSource, stackEntrySize;
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
	writeAddConstantNat64,
	writeCallDelayed,
	writeCallFunPointer,
	writeDup,
	writeDupEntries,
	writeDupEntry,
	writeFnBinary,
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
	writeSwitch0ToNDelay,
	writeSwitchWithValuesDelay,
	writeThreadLocalPtr,
	writeWrite;
import interpret.extern_ : ExternPointersForAllLibraries, FunPointer;
import interpret.funToReferences :
	FunPointerTypeToDynCallSig, FunToReferences, registerCall, registerFunPointerReference;
import interpret.generateText :
	getTextInfoForArray, getTextPointer, getTextPointerForCString, TextArrInfo, TextInfo, VarsInfo;
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
import util.opt : force, has, Opt;
import util.symbol : AllSymbols, Symbol;
import util.union_ : UnionMutable;
import util.util : castNonScope, castNonScope_ref, divRoundUp, ptrTrustMe;

void generateFunFromExpr(
	ref TempAlloc tempAlloc,
	scope ref ByteCodeWriter writer,
	in AllSymbols allSymbols,
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
		ptrTrustMe(allSymbols),
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
	struct JumpDelayed { MutArr!ByteCodeIndex* delayedJumps; }
	struct Loop {
		immutable ByteCodeIndex loopTop; // used by 'continue'
		ExprAfter* afterBreak;
	}
	immutable struct Return {}

	mixin UnionMutable!(Continue, JumpDelayed, Loop, Return);
}

void handleAfter(
	ref ByteCodeWriter writer,
	ref ExprCtx ctx,
	ByteCodeSource source,
	scope ref ExprAfter after,
) {
	handleAfterReturnData(writer, source, after);
	after.kind.matchScope!void(
		(ExprAfterKind.Continue) {},
		(scope ref ExprAfterKind.JumpDelayed x) {
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

void handleAfterReturnData(ref ByteCodeWriter writer, ByteCodeSource source, in ExprAfter after) {
	writeReturnData(writer, source, after.returnValueStackEntries);
	assert(getNextStackEntry(writer) == stackEntriesEnd(after.returnValueStackEntries));
}

struct ExprCtx {
	@safe @nogc pure nothrow:

	const AllSymbols* allSymbolsPtr;
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

	ref const(AllSymbols) allSymbols() return scope const =>
		*allSymbolsPtr;
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
			generateExprAndContinue(writer, ctx, locals, x.funPtr);
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
		(in LowExprKind.Loop it) {
			generateLoop(writer, ctx, locals, after, it);
		},
		(in LowExprKind.LoopBreak it) {
			generateLoopBreak(writer, ctx, locals, after, it);
		},
		(in LowExprKind.LoopContinue it) {
			generateLoopContinue(writer, ctx, source, locals, after, it);
		},
		(in LowExprKind.MatchUnion x) {
			generateMatchUnion(writer, ctx, source, locals, after, expr.type, x);
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
		(in LowExprKind.SizeOf it) {
			writePushConstant(writer, source, typeSizeBytes(ctx, it.type));
			handleAfter(writer, ctx, source, after);
		},
		(in Constant it) {
			generateConstant(writer, ctx, source, expr.type, it);
			handleAfter(writer, ctx, source, after);
		},
		(in LowExprKind.SpecialUnary it) {
			generateSpecialUnary(writer, ctx, source, locals, after, expr.type, it);
		},
		(in LowExprKind.SpecialBinary it) {
			generateSpecialBinary(writer, ctx, source, locals, after, it);
		},
		(in LowExprKind.SpecialTernary it) {
			generateSpecialTernary(writer, ctx, source, locals, after, it);
		},
		(in LowExprKind.Switch0ToN it) {
			generateSwitch0ToN(writer, ctx, source, locals, after, it);
		},
		(in LowExprKind.SwitchWithValues it) {
			generateSwitchWithValues(writer, ctx, source, locals, after, it);
		},
		(in LowExprKind.TailRecur it) {
			generateTailRecur(writer, ctx, source, locals, after, it);
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
		scope ExprAfter loopAfter = ExprAfter(
			StackEntries(stackBeforeLoop, 0),
			ExprAfterKind(ExprAfterKind.Loop(loopTop, ptrTrustMe(afterBranch))));
		// the loop always ends in a 'break' or 'continue' which will know what to do
		generateExpr(writer, ctx, locals, loopAfter, a.body_);
	});
	// We're after the 'break' now, so the loop result is on the stack
	setNextStackEntry(writer, stackEntriesEnd(after.returnValueStackEntries));
}

void generateLoopBreak(
	ref ByteCodeWriter writer,
	ref ExprCtx ctx,
	in Locals locals,
	scope ref ExprAfter after,
	in LowExprKind.LoopBreak a,
) {
	assert(after.returnValueStackEntries.size == 0);
	ExprAfterKind.Loop loop = after.kind.as!(ExprAfterKind.Loop);
	generateExpr(writer, ctx, locals, *loop.afterBreak, a.value);
	setNextStackEntry(writer, after.returnValueStackEntries.start);
}

void generateLoopContinue(
	ref ByteCodeWriter writer,
	ref ExprCtx ctx,
	ByteCodeSource source,
	in Locals locals,
	scope ref ExprAfter after,
	in LowExprKind.LoopContinue a,
) {
	assert(after.returnValueStackEntries.size == 0);
	ExprAfterKind.Loop loop = after.kind.as!(ExprAfterKind.Loop);
	handleAfterReturnData(writer, source, after);
	writeJump(writer, source, loop.loopTop);
}

void generateMatchUnion(
	ref ByteCodeWriter writer,
	ref ExprCtx ctx,
	ByteCodeSource source,
	in Locals locals,
	scope ref ExprAfter after,
	in LowType type,
	in LowExprKind.MatchUnion a,
) {
	StackEntry startStack = getNextStackEntry(writer);
	generateExprAndContinue(writer, ctx, locals, a.matchedValue);
	// Move the union kind to top of stack
	// TODO:PERF 'writeSwitch0ToN' should take the offset of the value to switch on
	writeDupEntry(writer, source, startStack);
	writeRemove(writer, source, StackEntries(startStack, 1));

	// Get the kind (always the first entry)
	SwitchDelayed switchDelayed = writeSwitch0ToNDelay(writer, source, a.cases.length);
	// Start of the union values is where the kind used to be.
	StackEntry stackAfterMatched = getNextStackEntry(writer);
	StackEntries matchedEntriesWithoutKind = StackEntries(startStack, (stackAfterMatched.entry - startStack.entry));

	// TODO: this should throw on invalid union value.
	if (isEmpty(a.cases)) {
		writeZeroed(writer, source, typeSizeBytes(ctx, type));
		handleAfter(writer, ctx, source, after);
	} else
		withBranching(writer, ctx, after, (ref ExprAfter afterBranch, ref ExprAfter afterLastBranch) {
			foreach (size_t caseIndex, ref LowExprKind.MatchUnion.Case case_; a.cases) {
				bool isLast = caseIndex == a.cases.length - 1;
				fillDelayedSwitchEntry(writer, switchDelayed, caseIndex);
				if (has(case_.local)) {
					size_t nEntries = nStackEntriesForType(ctx, force(case_.local).type);
					assert(nEntries <= matchedEntriesWithoutKind.size);
					generateExpr(
						writer, ctx,
						addLocal(locals, force(case_.local), StackEntries(matchedEntriesWithoutKind.start, nEntries)),
						isLast ? afterLastBranch : afterBranch, case_.then);
				} else
					generateExpr(writer, ctx, locals, isLast ? afterLastBranch : afterBranch, case_.then);
				// For the last one, don't reset the stack as by the end one of the cases will have run.
				if (!isLast)
					setNextStackEntry(writer, stackAfterMatched);
			}
		});
}

void generateSwitch0ToN(
	ref ByteCodeWriter writer,
	ref ExprCtx ctx,
	ByteCodeSource source,
	in Locals locals,
	scope ref ExprAfter after,
	in LowExprKind.Switch0ToN it,
 ) {
	StackEntry stackBefore = getNextStackEntry(writer);
	generateExprAndContinue(writer, ctx, locals, it.value);
	writeSwitchCases(
		writer,
		ctx,
		locals,
		after,
		stackBefore,
		writeSwitch0ToNDelay(writer, source, it.cases.length),
		it.cases);
}

void generateSwitchWithValues(
	ref ByteCodeWriter writer,
	ref ExprCtx ctx,
	ByteCodeSource source,
	in Locals locals,
	scope ref ExprAfter after,
	in LowExprKind.SwitchWithValues it,
) {
	StackEntry stackBefore = getNextStackEntry(writer);
	generateExprAndContinue(writer, ctx, locals, it.value);
	writeSwitchCases(
		writer,
		ctx,
		locals,
		after,
		stackBefore,
		writeSwitchWithValuesDelay(writer, source, it.values),
		it.cases);
}

void writeSwitchCases(
	ref ByteCodeWriter writer,
	ref ExprCtx ctx,
	in Locals locals,
	scope ref ExprAfter after,
	StackEntry stackBefore,
	in SwitchDelayed switchDelayed,
	in LowExpr[] cases,
 ) {
	withBranching(writer, ctx, after, (ref ExprAfter afterBranch, ref ExprAfter afterLastBranch) {
		foreach (size_t caseIndex, ref LowExpr case_; cases) {
			bool isLast = caseIndex == cases.length - 1;
			fillDelayedSwitchEntry(writer, switchDelayed, caseIndex);
			generateExpr(writer, ctx, locals, isLast ? afterLastBranch : afterBranch, case_);
			if (!isLast)
				setNextStackEntry(writer, stackBefore);
		}
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
		(in Constant.FunPointer it) {
			LowFunIndex fun = mustGet(ctx.program.concreteFunToLowFunIndex, it.fun);
			ByteCodeIndex where = writePushFunPointerDelayed(writer, source);
			registerFunPointerReference(ctx.tempAlloc, ctx.funToReferences, type.as!(LowType.FunPointer), fun, where);
		},
		(in Constant.Integral it) {
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

	void fn(alias cb)() {
		generateArg();
		writeFnUnary!cb(writer, source);
		handleAfter(writer, ctx, source, after);
	}

	final switch (a.kind) {
		case BuiltinUnary.acosFloat32:
			fn!fnAcosFloat32();
			break;
		case BuiltinUnary.acosFloat64:
			fn!fnAcosFloat64();
			break;
		case BuiltinUnary.acoshFloat32:
			fn!fnAcoshFloat32();
			break;
		case BuiltinUnary.acoshFloat64:
			fn!fnAcoshFloat64();
			break;
		case BuiltinUnary.asAnyPtr:
		case BuiltinUnary.enumToIntegral:
		case BuiltinUnary.toChar8FromNat8:
		case BuiltinUnary.toNat8FromChar8:
		case BuiltinUnary.toNat64FromPtr:
		case BuiltinUnary.toPtrFromNat64:
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
		case BuiltinUnary.asinFloat32:
			fn!fnAsinFloat32();
			break;
		case BuiltinUnary.asinFloat64:
			fn!fnAsinFloat64();
			break;
		case BuiltinUnary.asinhFloat32:
			fn!fnAsinhFloat32();
			break;
		case BuiltinUnary.asinhFloat64:
			fn!fnAsinhFloat64();
			break;
		case BuiltinUnary.atanFloat32:
			fn!fnAtanFloat32();
			break;
		case BuiltinUnary.atanFloat64:
			fn!fnAtanFloat64();
			break;
		case BuiltinUnary.atanhFloat32:
			fn!fnAtanhFloat32();
			break;
		case BuiltinUnary.atanhFloat64:
			fn!fnAtanhFloat64();
			break;
		case BuiltinUnary.bitwiseNotNat8:
		case BuiltinUnary.bitwiseNotNat16:
		case BuiltinUnary.bitwiseNotNat32:
		case BuiltinUnary.bitwiseNotNat64:
			fn!fnBitwiseNot();
			break;
		case BuiltinUnary.countOnesNat64:
			fn!fnCountOnesNat64();
			break;
		case BuiltinUnary.cosFloat32:
			fn!fnCosFloat32();
			break;
		case BuiltinUnary.cosFloat64:
			fn!fnCosFloat64();
			break;
		case BuiltinUnary.coshFloat32:
			fn!fnCoshFloat32();
			break;
		case BuiltinUnary.coshFloat64:
			fn!fnCoshFloat64();
			break;
		case BuiltinUnary.drop:
			generateExprAndContinue(writer, ctx, locals, a.arg);
			handleAfter(writer, ctx, source, after);
			break;
		case BuiltinUnary.roundFloat32:
			fn!fnRoundFloat32();
			break;
		case BuiltinUnary.roundFloat64:
			fn!fnRoundFloat64();
			break;
		case BuiltinUnary.sinFloat32:
			fn!fnSinFloat32();
			break;
		case BuiltinUnary.sinFloat64:
			fn!fnSinFloat64();
			break;
		case BuiltinUnary.sinhFloat32:
			fn!fnSinhFloat32();
			break;
		case BuiltinUnary.sinhFloat64:
			fn!fnSinhFloat64();
			break;
		case BuiltinUnary.sqrtFloat32:
			fn!fnSqrtFloat32();
			break;
		case BuiltinUnary.sqrtFloat64:
			fn!fnSqrtFloat64();
			break;
		case BuiltinUnary.tanFloat32:
			fn!fnTanFloat32();
			break;
		case BuiltinUnary.tanFloat64:
			fn!fnTanFloat64();
			break;
		case BuiltinUnary.tanhFloat32:
			fn!fnTanhFloat32();
			break;
		case BuiltinUnary.tanhFloat64:
			fn!fnTanhFloat64();
			break;
		case BuiltinUnary.toInt64FromInt8:
			fn!fnInt64FromInt8();
			break;
		case BuiltinUnary.toInt64FromInt16:
			fn!fnInt64FromInt16();
			break;
		case BuiltinUnary.toInt64FromInt32:
			fn!fnInt64FromInt32();
			break;
		// Normal operations on <64-bit values treat other bits as garbage
		// (they may be written to, such as in a wrap-add operation that overflows)
		// So we must mask out just the lower bits now.
		case BuiltinUnary.toNat64FromNat8:
			generateArg();
			writePushConstant(writer, source, ubyte.max);
			writeFnBinary!fnBitwiseAnd(writer, source);
			handleAfter(writer, ctx, source, after);
			break;
		case BuiltinUnary.toNat64FromNat16:
			generateArg();
			writePushConstant(writer, source, ushort.max);
			writeFnBinary!fnBitwiseAnd(writer, source);
			handleAfter(writer, ctx, source, after);
			break;
		case BuiltinUnary.toNat64FromNat32:
			generateArg();
			writePushConstant(writer, source, uint.max);
			writeFnBinary!fnBitwiseAnd(writer, source);
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
			fn!fnFloat32FromFloat64();
			break;
		case BuiltinUnary.toFloat64FromFloat32:
			fn!fnFloat64FromFloat32();
			break;
		case BuiltinUnary.toFloat64FromInt64: // FnOp.float64FromInt64
			fn!fnFloat64FromInt64();
			break;
		case BuiltinUnary.toFloat64FromNat64:
			fn!fnFloat64FromNat64();
			break;
		case BuiltinUnary.truncateToInt64FromFloat64:
			fn!fnTruncateToInt64FromFloat64();
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
	in LowExprKind.RecordFieldGet it,
) {
	StackEntry targetEntry = getNextStackEntry(writer);
	generateExprAndContinue(writer, ctx, locals, it.target);
	StackEntries targetEntries = StackEntries(
		targetEntry,
		getNextStackEntry(writer).entry - targetEntry.entry);
	FieldOffsetAndSize offsetAndSize = getFieldOffsetAndSize(ctx, targetRecordType(it), it.fieldIndex);
	if (targetIsPointer(it)) {
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
		case BuiltinTernary.interpreterBacktrace:
			writeInterpreterBacktrace(writer, source);
			handleAfter(writer, ctx, source, after);
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
	void fn(alias cb)() {
		generateExprAndContinue(writer, ctx, locals, left);
		generateExprAndContinue(writer, ctx, locals, right);
		writeFnBinary!cb(writer, source);
		handleAfter(writer, ctx, source, after);
	}

	final switch (a.kind) {
		case BuiltinBinary.atan2Float32:
			fn!fnAtan2Float32();
			break;
		case BuiltinBinary.atan2Float64:
			fn!fnAtan2Float64();
			break;
		case BuiltinBinary.addPtrAndNat64:
		case BuiltinBinary.subPtrAndNat64:
			LowType pointee = asPtrRawPointee(left.type);
			generateExprAndContinue(writer, ctx, locals, left);
			StackEntry afterLeft = getNextStackEntry(writer);
			generateExprAndContinue(writer, ctx, locals, right);
			size_t pointeeSize = typeSizeBytes(ctx, pointee);
			if (pointeeSize != 0 && pointeeSize != 1)
				writeMulConstantNat64(writer, source, pointeeSize);
			if (pointeeSize == 0) {
				writeRemove(writer, source, StackEntries(afterLeft, 1));
			} else {
				if (a.kind == BuiltinBinary.addPtrAndNat64)
					writeFnBinary!fnWrapAddIntegral(writer, source);
				else
					writeFnBinary!fnWrapSubIntegral(writer, source);
			}
			handleAfter(writer, ctx, source, after);
			break;
		case BuiltinBinary.addFloat32:
			fn!fnAddFloat32();
			break;
		case BuiltinBinary.addFloat64:
			fn!fnAddFloat64();
			break;
		case BuiltinBinary.and:
			generateIf(
				writer, ctx, source, locals, after, left,
				(ref ExprAfter innerAfter) {
					generateExpr(writer, ctx, locals, innerAfter, right);
				},
				(ref ExprAfter innerAfter) {
					writePushConstant(writer, source, false);
					handleAfter(writer, ctx, source, innerAfter);
				});
			break;
		case BuiltinBinary.unsafeBitShiftLeftNat64:
			fn!fnUnsafeBitShiftLeftNat64();
			break;
		case BuiltinBinary.unsafeBitShiftRightNat64:
			fn!fnUnsafeBitShiftRightNat64();
			break;
		case BuiltinBinary.bitwiseAndInt8:
		case BuiltinBinary.bitwiseAndInt16:
		case BuiltinBinary.bitwiseAndInt32:
		case BuiltinBinary.bitwiseAndInt64:
		case BuiltinBinary.bitwiseAndNat8:
		case BuiltinBinary.bitwiseAndNat16:
		case BuiltinBinary.bitwiseAndNat32:
		case BuiltinBinary.bitwiseAndNat64:
			fn!fnBitwiseAnd();
			break;
		case BuiltinBinary.bitwiseOrInt8:
		case BuiltinBinary.bitwiseOrInt16:
		case BuiltinBinary.bitwiseOrInt32:
		case BuiltinBinary.bitwiseOrInt64:
		case BuiltinBinary.bitwiseOrNat8:
		case BuiltinBinary.bitwiseOrNat16:
		case BuiltinBinary.bitwiseOrNat32:
		case BuiltinBinary.bitwiseOrNat64:
			fn!fnBitwiseOr();
			break;
		case BuiltinBinary.bitwiseXorInt8:
		case BuiltinBinary.bitwiseXorInt16:
		case BuiltinBinary.bitwiseXorInt32:
		case BuiltinBinary.bitwiseXorInt64:
		case BuiltinBinary.bitwiseXorNat8:
		case BuiltinBinary.bitwiseXorNat16:
		case BuiltinBinary.bitwiseXorNat32:
		case BuiltinBinary.bitwiseXorNat64:
			fn!fnBitwiseXor();
			break;
		case BuiltinBinary.eqFloat32:
			fn!fnEqFloat32();
			break;
		case BuiltinBinary.eqFloat64:
			fn!fnEqFloat64();
			break;
		case BuiltinBinary.eqInt8:
		case BuiltinBinary.eqInt16:
		case BuiltinBinary.eqInt32:
		case BuiltinBinary.eqInt64:
		case BuiltinBinary.eqNat8:
		case BuiltinBinary.eqNat16:
		case BuiltinBinary.eqNat32:
		case BuiltinBinary.eqNat64:
		case BuiltinBinary.eqPtr:
			fn!fnEqBits();
			break;
		case BuiltinBinary.lessChar8:
		case BuiltinBinary.lessNat8:
			fn!fnLessNat8();
			break;
		case BuiltinBinary.lessNat16:
			fn!fnLessNat16();
			break;
		case BuiltinBinary.lessNat32:
			fn!fnLessNat32();
			break;
		case BuiltinBinary.lessNat64:
		case BuiltinBinary.lessPtr:
			fn!fnLessNat64();
			break;
		case BuiltinBinary.lessFloat32:
			fn!fnLessFloat32();
			break;
		case BuiltinBinary.lessFloat64:
			fn!fnLessFloat64();
			break;
		case BuiltinBinary.lessInt8:
			fn!fnLessInt8();
			break;
		case BuiltinBinary.lessInt16:
			fn!fnLessInt16();
			break;
		case BuiltinBinary.lessInt32:
			fn!fnLessInt32();
			break;
		case BuiltinBinary.lessInt64:
			fn!fnLessInt64();
			break;
		case BuiltinBinary.mulFloat32:
			fn!fnMulFloat32();
			break;
		case BuiltinBinary.mulFloat64:
			fn!fnMulFloat64();
			break;
		case BuiltinBinary.orBool:
			generateIf(
				writer, ctx, source, locals, after, left,
				(ref ExprAfter innerAfter) {
					writePushConstant(writer, source, true);
					handleAfter(writer, ctx, source, innerAfter);
				},
				(ref ExprAfter innerAfter) {
					generateExpr(writer, ctx, locals, innerAfter, right);
				});
			break;
		case BuiltinBinary.seq:
			generateExprAndContinue(writer, ctx, locals, left);
			generateExpr(writer, ctx, locals, after, right);
			break;
		case BuiltinBinary.subFloat32:
			fn!fnSubFloat32();
			break;
		case BuiltinBinary.subFloat64:
			fn!fnSubFloat64();
			break;
		case BuiltinBinary.unsafeSubInt8:
		case BuiltinBinary.unsafeSubInt16:
		case BuiltinBinary.unsafeSubInt32:
		case BuiltinBinary.unsafeSubInt64:
		case BuiltinBinary.wrapSubNat8:
		case BuiltinBinary.wrapSubNat16:
		case BuiltinBinary.wrapSubNat32:
		case BuiltinBinary.wrapSubNat64:
			fn!fnWrapSubIntegral();
			break;
		case BuiltinBinary.unsafeDivFloat32:
			fn!fnUnsafeDivFloat32();
			break;
		case BuiltinBinary.unsafeDivFloat64:
			fn!fnUnsafeDivFloat64();
			break;
		case BuiltinBinary.unsafeDivInt8:
			fn!fnUnsafeDivInt8();
			break;
		case BuiltinBinary.unsafeDivInt16:
			fn!fnUnsafeDivInt16();
			break;
		case BuiltinBinary.unsafeDivInt32:
			fn!fnUnsafeDivInt32();
			break;
		case BuiltinBinary.unsafeDivInt64:
			fn!fnUnsafeDivInt64();
			break;
		case BuiltinBinary.unsafeDivNat8:
			fn!fnUnsafeDivNat8();
			break;
		case BuiltinBinary.unsafeDivNat16:
			fn!fnUnsafeDivNat16();
			break;
		case BuiltinBinary.unsafeDivNat32:
			fn!fnUnsafeDivNat32();
			break;
		case BuiltinBinary.unsafeDivNat64:
			fn!fnUnsafeDivNat64();
			break;
		case BuiltinBinary.unsafeModNat64:
			fn!fnUnsafeModNat64();
			break;
		case BuiltinBinary.unsafeAddInt8:
		case BuiltinBinary.unsafeAddInt16:
		case BuiltinBinary.unsafeAddInt32:
		case BuiltinBinary.unsafeAddInt64:
		case BuiltinBinary.wrapAddNat8:
		case BuiltinBinary.wrapAddNat16:
		case BuiltinBinary.wrapAddNat32:
		case BuiltinBinary.wrapAddNat64:
			fn!fnWrapAddIntegral();
			break;
		case BuiltinBinary.unsafeMulInt8:
		case BuiltinBinary.unsafeMulInt16:
		case BuiltinBinary.unsafeMulInt32:
		case BuiltinBinary.unsafeMulInt64:
		case BuiltinBinary.wrapMulNat8:
		case BuiltinBinary.wrapMulNat16:
		case BuiltinBinary.wrapMulNat32:
		case BuiltinBinary.wrapMulNat64:
			fn!fnWrapMulIntegral();
			break;
		case BuiltinBinary.writeToPtr:
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
	bool needsJumps = after.kind.match!bool(
		(ExprAfterKind.Continue) => true,
		(ref ExprAfterKind.JumpDelayed) => false,
		(ref ExprAfterKind.Loop) => false,
		(ExprAfterKind.Return) => false);
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
