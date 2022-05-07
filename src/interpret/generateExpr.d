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
	fnEqBits,
	fnEqFloat32,
	fnEqFloat64,
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
	writeCallFunPtr,
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
	writePushFunPtrDelayed,
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
	writeWrite;
import interpret.debugging : writeLowType;
import interpret.extern_ : FunPtr;
import interpret.funToReferences : FunPtrTypeToDynCallSig, FunToReferences, registerCall, registerFunPtrReference;
import interpret.generateText :
	getTextInfoForArray, getTextPointer, getTextPointerForCString, TextArrInfo, TextInfo;
import model.concreteModel : TypeSize;
import model.constant : Constant, matchConstant;
import model.lowModel :
	asFunPtrType,
	asLocalRef,
	asParamRef,
	asPrimitiveType,
	asPtrRawPointee,
	asRecordType,
	asRecordFieldGet,
	asRecordType,
	asSpecialUnary,
	asUnionType,
	isLocalRef,
	isParamRef,
	isRecordFieldGet,
	isSpecialUnary,
	LowExpr,
	LowExprKind,
	LowField,
	LowFunExprBody,
	LowFunIndex,
	LowLocal,
	LowProgram,
	LowRecord,
	LowType,
	matchLowExprKind,
	PrimitiveType,
	UpdateParam;
import model.model : range;
import model.typeLayout : nStackEntriesForType, optPack, Pack, sizeOfType;
import util.alloc.alloc : TempAlloc;
import util.col.arr : empty, only;
import util.col.arrBuilder : add;
import util.col.dict : mustGetAt;
import util.col.mutArr : clearAndFree, MutArr, push, tempAsArr;
import util.col.mutMaxArr : push, tempAsArr;
import util.col.stackDict : StackDict2, stackDict2Add0, stackDict2Add1, stackDict2MustGet0, stackDict2MustGet1;
import util.conv : bitsOfFloat32, bitsOfFloat64;
import util.opt : force, has, Opt;
import util.ptr : ptrTrustMe, ptrTrustMe_const, ptrTrustMe_mut;
import util.sym : AllSymbols;
import util.util : divRoundUp, todo, unreachable, verify;
import util.writer : finishWriter, writeChar, Writer, writeStatic;

//TODO: not @trusted
@trusted void generateFunFromExpr(
	ref TempAlloc tempAlloc,
	ref ByteCodeWriter writer,
	ref const AllSymbols allSymbols,
	ref immutable LowProgram program,
	ref immutable TextInfo textInfo,
	immutable LowFunIndex funIndex,
	ref FunToReferences funToReferences,
	immutable StackEntries[] parameters,
	immutable size_t returnEntries,
	ref immutable LowFunExprBody body_,
) {
	ExprCtx ctx = ExprCtx(
		ptrTrustMe_const(allSymbols),
		ptrTrustMe(program),
		ptrTrustMe(textInfo),
		funIndex,
		returnEntries,
		ptrTrustMe_mut(tempAlloc),
		ptrTrustMe_mut(funToReferences),
		nextByteCodeIndex(writer),
		parameters);
	Locals locals;
	immutable StackEntries returnStackEntries = immutable StackEntries(immutable StackEntry(0), returnEntries);
	ExprAfter after = ExprAfter(returnStackEntries, ExprAfterKind(immutable ExprAfterKind.Return()));
	generateExpr(writer, ctx, locals, after, body_.expr);
	verify(getNextStackEntry(writer).entry == returnEntries);
}

private:

struct ExprAfter {
	// Return value should go here. (Shift it left to cover anything left by a 'let'.)
	immutable StackEntries returnValueStackEntries;
	ExprAfterKind kind;
}

struct ExprAfterKind {
	@safe @nogc pure nothrow:

	// Continue means: Just leave the value on the stack. (Still make sure to pop to 'toStackDepth')
	struct Continue {}
	struct JumpDelayed { MutArr!ByteCodeIndex* delayedJumps; }
	struct JumpTo { immutable ByteCodeIndex to; }
	struct Return {}

	this(immutable Continue a) { kind = Kind.continue_; continue_ = a; }
	this(JumpDelayed a) { kind = Kind.jumpDelayed; jumpDelayed = a; }
	this(immutable JumpTo a) { kind = Kind.jumpTo; jumpTo = a; }
	this(immutable Return a) { kind = Kind.return_; return_ = a; }

	private:
	enum Kind { continue_, jumpDelayed, jumpTo, return_, }
	immutable Kind kind;
	union {
		immutable Continue continue_;
		JumpDelayed jumpDelayed;
		immutable JumpTo jumpTo;
		immutable Return return_;
	}
}

immutable(bool) isJumpTo(scope ref const ExprAfterKind a) {
	return a.kind == ExprAfterKind.Kind.jumpTo;
}

immutable(bool) isReturn(scope ref const ExprAfterKind a) {
	return a.kind == ExprAfterKind.Kind.return_;
}

@trusted immutable(T) matchExprAfterKind(T)(
	ref ExprAfterKind a,
	scope immutable(T) delegate(immutable ExprAfterKind.Continue) @safe @nogc pure nothrow cbContinue,
	scope immutable(T) delegate(ref ExprAfterKind.JumpDelayed) @safe @nogc pure nothrow cbJumpDelayed,
	scope immutable(T) delegate(immutable ExprAfterKind.JumpTo) @safe @nogc pure nothrow cbJumpTo,
	scope immutable(T) delegate(immutable ExprAfterKind.Return) @safe @nogc pure nothrow cbReturn,
) {
	final switch (a.kind) {
		case ExprAfterKind.Kind.continue_:
			return cbContinue(a.continue_);
		case ExprAfterKind.Kind.jumpDelayed:
			return cbJumpDelayed(a.jumpDelayed);
		case ExprAfterKind.Kind.jumpTo:
			return cbJumpTo(a.jumpTo);
		case ExprAfterKind.Kind.return_:
			return cbReturn(a.return_);
	}
}

void handleAfter(ref ByteCodeWriter writer, ref ExprCtx ctx, immutable ByteCodeSource source, ref ExprAfter after) {
	writeReturnData(writer, source, after.returnValueStackEntries);
	verify(getNextStackEntry(writer) == stackEntriesEnd(after.returnValueStackEntries));
	matchExprAfterKind!void(
		after.kind,
		(immutable ExprAfterKind.Continue) {},
		(ref ExprAfterKind.JumpDelayed x) {
			immutable ByteCodeIndex delayed = writeJumpDelayed(writer, source);
			push(ctx.tempAlloc, *x.delayedJumps, delayed);
		},
		(immutable ExprAfterKind.JumpTo x) {
			writeJump(writer, source, x.to);
		},
		(immutable ExprAfterKind.Return) {
			writeReturn(writer, source);
		});
}

struct ExprCtx {
	@safe @nogc pure nothrow:

	const AllSymbols* allSymbolsPtr;
	immutable LowProgram* programPtr;
	immutable TextInfo* textInfoPtr;
	immutable LowFunIndex curFunIndex;
	immutable size_t returnTypeSizeInStackEntries;
	TempAlloc* tempAllocPtr;
	FunToReferences* funToReferencesPtr;
	immutable ByteCodeIndex startOfCurrentFun;
	immutable StackEntries[] parameterEntries;

	ref const(AllSymbols) allSymbols() return scope const {
		return *allSymbolsPtr;
	}
	ref immutable(LowProgram) program() return scope const {
		return *programPtr;
	}
	ref immutable(TextInfo) textInfo() return scope const {
		return *textInfoPtr;
	}
	ref TempAlloc tempAlloc() return scope {
		return *tempAllocPtr;
	}
	ref FunToReferences funToReferences() return scope {
		return *funToReferencesPtr;
	}
	immutable(FunPtrTypeToDynCallSig) funPtrTypeToDynCallSig() {
		return funToReferences.funPtrTypeToDynCallSig;
	}
}

immutable(TypeSize) sizeOfType(ref const ExprCtx ctx, immutable LowType t) {
	return sizeOfType(ctx.program, t);
}

immutable(size_t) nStackEntriesForType(ref const ExprCtx ctx, immutable LowType t) {
	return nStackEntriesForType(ctx.program, t);
}

immutable(size_t) nStackEntriesForRecordType(ref const ExprCtx ctx, immutable LowType.Record t) {
	immutable LowType type = immutable LowType(t);
	return nStackEntriesForType(ctx, type);
}

immutable(size_t) nStackEntriesForUnionType(ref const ExprCtx ctx, immutable LowType.Union t) {
	immutable LowType type = immutable LowType(t);
	return nStackEntriesForType(ctx, type);
}

alias Locals = StackDict2!(immutable LowLocal*, immutable StackEntries, immutable LowExprKind.Loop*, ExprAfter*);
alias addLocal = stackDict2Add0!(immutable LowLocal*, immutable StackEntries, immutable LowExprKind.Loop*, ExprAfter*);
alias addLoop = stackDict2Add1!(immutable LowLocal*, immutable StackEntries, immutable LowExprKind.Loop*, ExprAfter*);
alias getLocal =
	stackDict2MustGet0!(immutable LowLocal*, immutable StackEntries, immutable LowExprKind.Loop*, ExprAfter*);
alias getLoop =
	stackDict2MustGet1!(immutable LowLocal*, immutable StackEntries, immutable LowExprKind.Loop*, ExprAfter*);

void generateExpr(
	ref ByteCodeWriter writer,
	ref ExprCtx ctx,
	scope ref Locals locals,
	ref ExprAfter after,
	ref immutable LowExpr expr,
) {
	verify(after.returnValueStackEntries.size == nStackEntriesForType(ctx, expr.type));
	immutable ByteCodeSource source = immutable ByteCodeSource(ctx.curFunIndex, expr.source.range.start);
	matchLowExprKind!(
		void,
		(ref immutable LowExprKind.Call it) {
			immutable StackEntry stackEntryBeforeArgs = getNextStackEntry(writer);
			immutable size_t expectedStackEffect = after.returnValueStackEntries.size;
			generateArgsAndContinue(writer, ctx, locals, it.args);
			immutable ByteCodeIndex where = writeCallDelayed(writer, source, stackEntryBeforeArgs, expectedStackEffect);
			registerCall(ctx.tempAlloc, ctx.funToReferences, it.called, where);
			verify(stackEntryBeforeArgs.entry + expectedStackEffect == getNextStackEntry(writer).entry);
			//TODO: do a tailcall if possible
			handleAfter(writer, ctx, source, after);
		},
		(ref immutable LowExprKind.CallFunPtr it) {
			immutable StackEntry stackEntryBeforeArgs = getNextStackEntry(writer);
			generateExprAndContinue(writer, ctx, locals, it.funPtr);
			generateArgsAndContinue(writer, ctx, locals, it.args);
			writeCallFunPtr(writer, source, stackEntryBeforeArgs, ctx.funPtrTypeToDynCallSig[it.funPtrType()]);
			handleAfter(writer, ctx, source, after);
		},
		(ref immutable LowExprKind.CreateRecord it) {
			generateCreateRecord(writer, ctx, asRecordType(expr.type), source, locals, it);
			handleAfter(writer, ctx, source, after);
		},
		(ref immutable LowExprKind.CreateUnion it) {
			generateCreateUnion(writer, ctx, asUnionType(expr.type), source, locals, it);
			handleAfter(writer, ctx, source, after);
		},
		(ref immutable LowExprKind.If it) {
			generateIf(
				writer, ctx, source, locals, after, it.cond,
				(ref ExprAfter innerAfter) {
					generateExpr(writer, ctx, locals, innerAfter, it.then);
				},
				(ref ExprAfter innerAfter) {
					generateExpr(writer, ctx, locals, innerAfter, it.else_);
				});
		},
		(ref immutable LowExprKind.InitConstants) {
			// bytecode interpreter doesn't need to do anything in 'init-constants'
			handleAfter(writer, ctx, source, after);
		},
		(ref immutable LowExprKind.Let it) =>
			generateLet(writer, ctx, locals, after, it),
		(ref immutable LowExprKind.LocalRef it) {
			immutable StackEntries entries = getLocal(locals, it.local);
			if (entries.size != 0)
				writeDupEntries(writer, source, entries);
			handleAfter(writer, ctx, source, after);
		},
		(ref immutable LowExprKind.LocalSet it) {
			immutable StackEntries entries = getLocal(locals, it.local);
			generateExprAndContinue(writer, ctx, locals, it.value);
			if (entries.size != 0)
				writeSet(writer, source, entries);
			handleAfter(writer, ctx, source, after);
		},
		(ref immutable LowExprKind.Loop it) {
			generateLoop(writer, ctx, source, locals, after, it);
		},
		(ref immutable LowExprKind.LoopBreak it) {
			generateLoopBreak(writer, ctx, locals, after, it);
		},
		(ref immutable LowExprKind.MatchUnion it) {
			generateMatchUnion(writer, ctx, source, locals, after, it);
		},
		(ref immutable LowExprKind.ParamRef it) {
			immutable StackEntries entries = ctx.parameterEntries[it.index.index];
			if (entries.size != 0)
				writeDupEntries(writer, source, entries);
			handleAfter(writer, ctx, source, after);
		},
		(ref immutable LowExprKind.PtrCast it) {
			generateExpr(writer, ctx, locals, after, it.target);
		},
		(ref immutable LowExprKind.RecordFieldGet it) {
			generateRecordFieldGet(writer, ctx, source, locals, it);
			handleAfter(writer, ctx, source, after);
		},
		(ref immutable LowExprKind.RecordFieldSet it) {
			immutable StackEntry before = getNextStackEntry(writer);
			verify(it.targetIsPointer);
			generateExprAndContinue(writer, ctx, locals, it.target);
			immutable StackEntry mid = getNextStackEntry(writer);
			generateExprAndContinue(writer, ctx, locals, it.value);
			immutable FieldOffsetAndSize offsetAndSize = getFieldOffsetAndSize(ctx, it.record, it.fieldIndex);
			verify(mid.entry + divRoundUp(offsetAndSize.size, stackEntrySize) == getNextStackEntry(writer).entry);
			writeWrite(writer, source, offsetAndSize.offset, offsetAndSize.size);
			verify(getNextStackEntry(writer) == before);
			handleAfter(writer, ctx, source, after);
		},
		(ref immutable LowExprKind.Seq it) {
			generateExprAndContinue(writer, ctx, locals, it.first);
			generateExpr(writer, ctx, locals, after, it.then);
		},
		(ref immutable LowExprKind.SizeOf it) {
			writePushConstant(writer, source, sizeOfType(ctx, it.type).size);
			handleAfter(writer, ctx, source, after);
		},
		(ref immutable Constant it) {
			generateConstant(writer, ctx, source, expr.type, it);
			handleAfter(writer, ctx, source, after);
		},
		(ref immutable LowExprKind.SpecialUnary it) {
			generateSpecialUnary(writer, ctx, source, locals, after, expr.type, it);
		},
		(ref immutable LowExprKind.SpecialBinary it) {
			generateSpecialBinary(writer, ctx, source, locals, after, it);
		},
		(ref immutable LowExprKind.SpecialTernary it) {
			generateSpecialTernary(writer, ctx, source, locals, after, it);
		},
		(ref immutable LowExprKind.Switch0ToN it) {
			generateSwitch0ToN(writer, ctx, source, locals, after, it);
		},
		(ref immutable LowExprKind.SwitchWithValues it) {
			generateSwitchWithValues(writer, ctx, source, locals, after, it);
		},
		(ref immutable LowExprKind.TailRecur it) {
			generateTailRecur(writer, ctx, source, locals, after, it);
		},
		(ref immutable LowExprKind.Zeroed) {
			writePushEmptySpace(writer, source, after.returnValueStackEntries.size);
			handleAfter(writer, ctx, source, after);
		},
	)(expr.kind);
}

void generateExprAndContinue(
	ref ByteCodeWriter writer,
	ref ExprCtx ctx,
	scope ref Locals locals,
	ref immutable LowExpr expr,
) {
	ExprAfter after = ExprAfter(
		immutable StackEntries(getNextStackEntry(writer), nStackEntriesForType(ctx, expr.type)),
		ExprAfterKind(immutable ExprAfterKind.Continue()));
	generateExpr(writer, ctx, locals, after, expr);
}

void generateLet(
	ref ByteCodeWriter writer,
	ref ExprCtx ctx,
	scope ref Locals locals,
	ref ExprAfter after,
	ref immutable LowExprKind.Let a,
) {
	immutable StackEntries localEntries =
		immutable StackEntries(getNextStackEntry(writer), nStackEntriesForType(ctx, a.local.type));
	generateExprAndContinue(writer, ctx, locals, a.value);
	verify(getNextStackEntry(writer) == stackEntriesEnd(localEntries));
	scope Locals newLocals = addLocal(locals, a.local, localEntries);
	generateExpr(writer, ctx, newLocals, after, a.then);
}

@trusted void generateLoop(
	ref ByteCodeWriter writer,
	ref ExprCtx ctx,
	immutable ByteCodeSource source,
	scope ref Locals locals,
	ref ExprAfter after,
	ref immutable LowExprKind.Loop a,
) {
	immutable StackEntry stackBeforeLoop = getNextStackEntry(writer);
	withBranching(writer, ctx, after, (ref ExprAfter afterBranch, ref ExprAfter afterLastBranch) {
		immutable ByteCodeIndex loopTop = nextByteCodeIndex(writer);
		// NOTE: We don't know whether the 'break' will appear at the bottom of the loop or not.
		// If it is at the bottom, it won't need a jump.
		Locals newLocals = addLoop(locals, &a, &afterBranch);
		// 'continue' should restore to state before loop
		ExprAfter continueAfter = ExprAfter(
			immutable StackEntries(stackBeforeLoop, 0),
			ExprAfterKind(immutable ExprAfterKind.JumpTo(loopTop)));
		generateExpr(writer, ctx, newLocals, continueAfter, a.body_);
		writeJump(writer, source, loopTop);
	});
	// We're after the 'break' now, so the loop result is on the stack
	setNextStackEntry(writer, stackEntriesEnd(after.returnValueStackEntries));
}

void generateLoopBreak(
	ref ByteCodeWriter writer,
	ref ExprCtx ctx,
	scope ref Locals locals,
	ref ExprAfter after,
	ref immutable LowExprKind.LoopBreak a,
) {
	verify(after.returnValueStackEntries.size == 0);
	verify(isJumpTo(after.kind));
	ExprAfter* breakAfter = getLoop(locals, a.loop);
	generateExpr(writer, ctx, locals, *breakAfter, a.value);
	setNextStackEntry(writer, after.returnValueStackEntries.start);
}

void generateMatchUnion(
	ref ByteCodeWriter writer,
	ref ExprCtx ctx,
	immutable ByteCodeSource source,
	scope ref Locals locals,
	ref ExprAfter after,
	ref immutable LowExprKind.MatchUnion a,
) {
	immutable StackEntry startStack = getNextStackEntry(writer);
	generateExprAndContinue(writer, ctx, locals, a.matchedValue);
	// Move the union kind to top of stack
	// TODO:PERF 'writeSwitch0ToN' should take the offset of the value to switch on
	writeDupEntry(writer, source, startStack);
	writeRemove(writer, source, immutable StackEntries(startStack, 1));

	// Get the kind (always the first entry)
	immutable SwitchDelayed switchDelayed = writeSwitch0ToNDelay(writer, source, a.cases.length);
	// Start of the union values is where the kind used to be.
	immutable StackEntry stackAfterMatched = getNextStackEntry(writer);
	immutable StackEntries matchedEntriesWithoutKind =
		immutable StackEntries(startStack, (stackAfterMatched.entry - startStack.entry));

	withBranching(writer, ctx, after, (ref ExprAfter afterBranch, ref ExprAfter afterLastBranch) {
		foreach (immutable size_t caseIndex, ref immutable LowExprKind.MatchUnion.Case case_; a.cases) {
			immutable bool isLast = caseIndex == a.cases.length - 1;
			fillDelayedSwitchEntry(writer, switchDelayed, caseIndex);
			if (has(case_.local)) {
				immutable size_t nEntries = nStackEntriesForType(ctx, force(case_.local).type);
				verify(nEntries <= matchedEntriesWithoutKind.size);
				scope Locals newLocals = addLocal(
					locals,
					force(case_.local),
					immutable StackEntries(matchedEntriesWithoutKind.start, nEntries));
				generateExpr(writer, ctx, newLocals, isLast ? afterLastBranch : afterBranch, case_.then);
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
	immutable ByteCodeSource source,
	scope ref Locals locals,
	ref ExprAfter after,
	ref immutable LowExprKind.Switch0ToN it,
 ) {
	immutable StackEntry stackBefore = getNextStackEntry(writer);
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
	immutable ByteCodeSource source,
	scope ref Locals locals,
	ref ExprAfter after,
	ref immutable LowExprKind.SwitchWithValues it,
) {
	immutable StackEntry stackBefore = getNextStackEntry(writer);
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
	scope ref Locals locals,
	ref ExprAfter after,
	immutable StackEntry stackBefore,
	immutable SwitchDelayed switchDelayed,
	scope immutable LowExpr[] cases,
 ) {
	withBranching(writer, ctx, after, (ref ExprAfter afterBranch, ref ExprAfter afterLastBranch) {
		foreach (immutable size_t caseIndex, ref immutable LowExpr case_; cases) {
			immutable bool isLast = caseIndex == cases.length - 1;
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
	immutable ByteCodeSource source,
	scope ref Locals locals,
	ref ExprAfter after,
	ref immutable LowExprKind.TailRecur a,
) {
	// We need to generate all new values before overwriting anything.
	foreach (ref immutable UpdateParam updateParam; a.updateParams)
		generateExprAndContinue(writer, ctx, locals, updateParam.newValue);
	// Now pop them in reverse and write to the appropriate params
	foreach_reverse (ref immutable UpdateParam updateParam; a.updateParams)
		writeSet(writer, source, ctx.parameterEntries[updateParam.param.index]);

	// Delete anything on the stack besides parameters
	verify(isReturn(after.kind));
	verify(after.returnValueStackEntries.start.entry == 0);
	immutable StackEntry parametersEnd = empty(ctx.parameterEntries)
		? immutable StackEntry(0)
		: stackEntriesEnd(ctx.parameterEntries[$ - 1]);
	immutable StackEntry localsEnd = getNextStackEntry(writer);
	writeRemove(writer, source, immutable StackEntries(parametersEnd, localsEnd.entry - parametersEnd.entry));
	writeJump(writer, source, ctx.startOfCurrentFun);

	// Fake the stack as if this were a normal call and return
	setNextStackEntry(writer, immutable StackEntry(ctx.returnTypeSizeInStackEntries));
}

void generateArgsAndContinue(
	ref ByteCodeWriter writer,
	ref ExprCtx ctx,
	scope ref Locals locals,
	immutable LowExpr[] args,
) {
	foreach (ref immutable LowExpr arg; args)
		generateExprAndContinue(writer, ctx, locals, arg);
}

void generateCreateRecord(
	ref ByteCodeWriter writer,
	ref ExprCtx ctx,
	immutable LowType.Record type,
	immutable ByteCodeSource source,
	scope ref Locals locals,
	ref immutable LowExprKind.CreateRecord it,
) {
	generateCreateRecordOrConstantRecord(
		writer,
		ctx,
		type,
		source,
		(immutable size_t fieldIndex, immutable LowType fieldType) {
			immutable LowExpr arg = it.args[fieldIndex];
			verify(arg.type == fieldType);
			generateExprAndContinue(writer, ctx, locals, arg);
		});
}

void generateCreateRecordOrConstantRecord(
	ref ByteCodeWriter writer,
	ref ExprCtx ctx,
	immutable LowType.Record type,
	immutable ByteCodeSource source,
	scope void delegate(immutable size_t, immutable LowType) @safe @nogc pure nothrow cbGenerateField,
) {
	immutable StackEntry before = getNextStackEntry(writer);

	immutable LowRecord record = ctx.program.allRecords[type];
	foreach (immutable size_t i, ref immutable LowField field; record.fields)
		cbGenerateField(i, field.type);

	immutable Opt!Pack optPack = optPack(ctx.tempAlloc, ctx.program, type);
	if (has(optPack))
		writePack(writer, source, force(optPack));

	verify(getNextStackEntry(writer).entry - before.entry == nStackEntriesForRecordType(ctx, type));
}

void generateCreateUnion(
	ref ByteCodeWriter writer,
	ref ExprCtx ctx,
	immutable LowType.Union type,
	immutable ByteCodeSource source,
	scope ref Locals locals,
	ref immutable LowExprKind.CreateUnion it,
) {
	generateCreateUnionOrConstantUnion(
		writer,
		ctx,
		type,
		it.memberIndex,
		source,
		(immutable LowType) {
			generateExprAndContinue(writer, ctx, locals, it.arg);
		});
}

void generateCreateUnionOrConstantUnion(
	ref ByteCodeWriter writer,
	ref const ExprCtx ctx,
	immutable LowType.Union type,
	immutable size_t memberIndex,
	immutable ByteCodeSource source,
	scope void delegate(immutable LowType) @safe @nogc pure nothrow cbGenerateMember,
) {
	immutable StackEntry before = getNextStackEntry(writer);
	immutable size_t size = nStackEntriesForUnionType(ctx, type);
	writePushConstant(writer, source, memberIndex);
	immutable LowType memberType = ctx.program.allUnions[type].members[memberIndex];
	cbGenerateMember(memberType);
	immutable StackEntry after = getNextStackEntry(writer);
	if (before.entry + size != after.entry) {
		// Some members of a union are smaller than the union.
		verify(before.entry + size > after.entry);
		writePushEmptySpace(writer, source, before.entry + size - after.entry);
	}
}

struct FieldOffsetAndSize {
	immutable size_t offset;
	immutable size_t size;
}

immutable(FieldOffsetAndSize) getFieldOffsetAndSize(
	ref const ExprCtx ctx,
	immutable LowType.Record record,
	immutable size_t fieldIndex,
) {
	immutable LowField field = ctx.program.allRecords[record].fields[fieldIndex];
	immutable size_t size = sizeOfType(ctx, field.type).size;
	return immutable FieldOffsetAndSize(field.offset, size);
}

void generateConstant(
	ref ByteCodeWriter writer,
	ref ExprCtx ctx,
	immutable ByteCodeSource source,
	immutable LowType type,
	immutable Constant constant,
) {
	debug {
		if (false) {
			Writer w = Writer(ptrTrustMe_mut(ctx.tempAlloc));
			writeStatic(w, "generateConstant of type ");
			writeLowType(w, ctx.allSymbols, ctx.program.allTypes, type);
			writeChar(w, '\n');
			//print()
			finishWriter(w);
		}
	}

	matchConstant!void(
		constant,
		(ref immutable Constant.ArrConstant it) {
			immutable TextArrInfo info = getTextInfoForArray(ctx.textInfo, ctx.program.allConstants, it);
			writePushConstant(writer, source, info.size);
			writePushConstantPointer(writer, source, info.textPtr);
		},
		(immutable Constant.BoolConstant it) {
			writeBoolConstant(writer, source, it.value);
		},
		(ref immutable Constant.CString it) {
			writePushConstantPointer(writer, source, getTextPointerForCString(ctx.textInfo, it));
		},
		(immutable Constant.Float it) {
			switch (asPrimitiveType(type)) {
				case PrimitiveType.float32:
					writePushConstant(writer, source, bitsOfFloat32(cast(float) it.value));
					break;
				case PrimitiveType.float64:
					writePushConstant(writer, source, bitsOfFloat64(it.value));
					break;
				default:
					unreachable!void();
					break;
			}
		},
		(immutable Constant.FunPtr it) {
			immutable LowFunIndex fun = mustGetAt(ctx.program.concreteFunToLowFunIndex, it.fun);
			immutable ByteCodeIndex where = writePushFunPtrDelayed(writer, source);
			registerFunPtrReference(ctx.tempAlloc, ctx.funToReferences, asFunPtrType(type), fun, where);
		},
		(immutable Constant.Integral it) {
			writePushConstant(writer, source, it.value);
		},
		(immutable Constant.Null) {
			writePushConstant(writer, source, 0);
		},
		(immutable Constant.Pointer it) {
			immutable ubyte* pointer = getTextPointer(ctx.textInfo, it);
			writePushConstantPointer(writer, source, pointer);
		},
		(ref immutable Constant.Record it) {
			generateCreateRecordOrConstantRecord(
				writer,
				ctx,
				asRecordType(type),
				source,
				(immutable size_t argIndex, immutable LowType argType) {
					generateConstant(writer, ctx, source, argType, it.args[argIndex]);
				});
		},
		(ref immutable Constant.Union it) {
			generateCreateUnionOrConstantUnion(
				writer,
				ctx,
				asUnionType(type),
				it.memberIndex,
				source,
				(immutable LowType memberType) {
					generateConstant(writer, ctx, source, memberType, it.arg);
				});
		},
		(immutable Constant.Void) {
			// do nothing
		});
}

void writeBoolConstant(ref ByteCodeWriter writer, immutable ByteCodeSource source, immutable bool value) {
	writePushConstant(writer, source, value ? 1 : 0);
}

void generateSpecialUnary(
	ref ByteCodeWriter writer,
	ref ExprCtx ctx,
	immutable ByteCodeSource source,
	scope ref Locals locals,
	ref ExprAfter after,
	immutable LowType type,
	ref immutable LowExprKind.SpecialUnary a,
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
		case LowExprKind.SpecialUnary.Kind.asAnyPtr:
		case LowExprKind.SpecialUnary.Kind.asRef:
		case LowExprKind.SpecialUnary.Kind.enumToIntegral:
		case LowExprKind.SpecialUnary.Kind.toCharFromNat8:
		case LowExprKind.SpecialUnary.Kind.toNat8FromChar:
		case LowExprKind.SpecialUnary.Kind.toNat64FromPtr:
		case LowExprKind.SpecialUnary.Kind.toPtrFromNat64:
		case LowExprKind.SpecialUnary.Kind.unsafeInt32ToNat32:
		case LowExprKind.SpecialUnary.Kind.unsafeInt64ToInt8:
		case LowExprKind.SpecialUnary.Kind.unsafeInt64ToInt16:
		case LowExprKind.SpecialUnary.Kind.unsafeInt64ToInt32:
		case LowExprKind.SpecialUnary.Kind.unsafeInt64ToNat64:
		case LowExprKind.SpecialUnary.Kind.unsafeNat64ToInt64:
		case LowExprKind.SpecialUnary.Kind.unsafeNat64ToNat8:
		case LowExprKind.SpecialUnary.Kind.unsafeNat64ToNat16:
		case LowExprKind.SpecialUnary.Kind.unsafeNat64ToNat32:
			// do nothing (doesn't change the bits, just their type)
			// Some of these widen, but all fit within the one stack entry so nothing to do
			// NOTE: we treat the upper bits of <64-bit types as arbitrary, so those are no-ops too
			generateExpr(writer, ctx, locals, after, a.arg);
			break;
		case LowExprKind.SpecialUnary.Kind.bitwiseNotNat8:
		case LowExprKind.SpecialUnary.Kind.bitwiseNotNat16:
		case LowExprKind.SpecialUnary.Kind.bitwiseNotNat32:
		case LowExprKind.SpecialUnary.Kind.bitwiseNotNat64:
			fn!fnBitwiseNot();
			break;
		case LowExprKind.SpecialUnary.Kind.countOnesNat64:
			fn!fnCountOnesNat64();
			break;
		case LowExprKind.SpecialUnary.Kind.toInt64FromInt16:
			fn!fnInt64FromInt16();
			break;
		case LowExprKind.SpecialUnary.Kind.toInt64FromInt32:
			fn!fnInt64FromInt32();
			break;
		// Normal operations on <64-bit values treat other bits as garbage
		// (they may be written to, such as in a wrap-add operation that overflows)
		// So we must mask out just the lower bits now.
		case LowExprKind.SpecialUnary.Kind.toNat64FromNat8:
			generateArg();
			writePushConstant(writer, source, ubyte.max);
			writeFnBinary!fnBitwiseAnd(writer, source);
			handleAfter(writer, ctx, source, after);
			break;
		case LowExprKind.SpecialUnary.Kind.toNat64FromNat16:
			generateArg();
			writePushConstant(writer, source, ushort.max);
			writeFnBinary!fnBitwiseAnd(writer, source);
			handleAfter(writer, ctx, source, after);
			break;
		case LowExprKind.SpecialUnary.Kind.toNat64FromNat32:
			generateArg();
			writePushConstant(writer, source, uint.max);
			writeFnBinary!fnBitwiseAnd(writer, source);
			handleAfter(writer, ctx, source, after);
			break;
		case LowExprKind.SpecialUnary.Kind.deref:
			generateArg();
			writeRead(writer, source, 0, sizeOfType(ctx, type).size);
			handleAfter(writer, ctx, source, after);
			break;
		case LowExprKind.SpecialUnary.Kind.ptrTo:
		case LowExprKind.SpecialUnary.Kind.refOfVal:
			generateRefOfVal(writer, ctx, source, locals, after, a.arg);
			break;
		case LowExprKind.SpecialUnary.Kind.toFloat32FromFloat64:
			fn!fnFloat32FromFloat64();
			break;
		case LowExprKind.SpecialUnary.Kind.toFloat64FromFloat32:
			fn!fnFloat64FromFloat32();
			break;
		case LowExprKind.SpecialUnary.Kind.toFloat64FromInt64: // FnOp.float64FromInt64
			fn!fnFloat64FromInt64();
			break;
		case LowExprKind.SpecialUnary.Kind.toFloat64FromNat64:
			fn!fnFloat64FromNat64();
			break;
		case LowExprKind.SpecialUnary.Kind.truncateToInt64FromFloat64:
			fn!fnTruncateToInt64FromFloat64();
			break;
	}
}

void generateRefOfVal(
	ref ByteCodeWriter writer,
	ref ExprCtx ctx,
	immutable ByteCodeSource source,
	scope ref Locals locals,
	ref ExprAfter after,
	ref immutable LowExpr arg,
) {
	if (isLocalRef(arg.kind)) {
		writeStackRef(writer, source, getLocal(locals, asLocalRef(arg.kind).local).start);
		handleAfter(writer, ctx, source, after);
	} else if (isParamRef(arg.kind)) {
		writeStackRef(writer, source, ctx.parameterEntries[asParamRef(arg.kind).index.index].start);
		handleAfter(writer, ctx, source, after);
	} else if (isRecordFieldGet(arg.kind)) {
		immutable LowExprKind.RecordFieldGet rfa = asRecordFieldGet(arg.kind);
		generatePtrToRecordFieldGet(
			writer,
			ctx,
			source,
			locals,
			after,
			rfa.record,
			rfa.fieldIndex,
			rfa.targetIsPointer,
			rfa.target);
	} else if (isSpecialUnary(arg.kind)) {
		immutable LowExprKind.SpecialUnary it = asSpecialUnary(arg.kind);
		if (it.kind == LowExprKind.SpecialUnary.Kind.deref)
			// Ref of deref just changes the type
			generateExpr(writer, ctx, locals, after, it.arg);
		else
			todo!void("!");
	} else
		todo!void("!");
}

void generateRecordFieldGet(
	ref ByteCodeWriter writer,
	ref ExprCtx ctx,
	immutable ByteCodeSource source,
	scope ref Locals locals,
	ref immutable LowExprKind.RecordFieldGet it,
) {
	immutable StackEntry targetEntry = getNextStackEntry(writer);
	generateExprAndContinue(writer, ctx, locals, it.target);
	immutable StackEntries targetEntries = immutable StackEntries(
		targetEntry,
		getNextStackEntry(writer).entry - targetEntry.entry);
	immutable FieldOffsetAndSize offsetAndSize = getFieldOffsetAndSize(ctx, it.record, it.fieldIndex);
	if (it.targetIsPointer) {
		if (offsetAndSize.size == 0)
			writeRemove(writer, source, targetEntries);
		else
			writeRead(writer, source, offsetAndSize.offset, offsetAndSize.size);
	} else {
		if (offsetAndSize.size != 0) {
			immutable StackEntry firstEntry =
				immutable StackEntry(targetEntry.entry + (offsetAndSize.offset / stackEntrySize));
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

void generatePtrToRecordFieldGet(
	ref ByteCodeWriter writer,
	ref ExprCtx ctx,
	immutable ByteCodeSource source,
	scope ref Locals locals,
	ref ExprAfter after,
	immutable LowType.Record record,
	immutable size_t fieldIndex,
	immutable bool targetIsPointer,
	ref immutable LowExpr target,
) {
	immutable size_t offset = ctx.program.allRecords[record].fields[fieldIndex].offset;
	if (targetIsPointer) {
		if (offset != 0) {
			generateExprAndContinue(writer, ctx, locals, target);
			writeAddConstantNat64(writer, source, offset);
			handleAfter(writer, ctx, source, after);
		} else
			generateExpr(writer, ctx, locals, after, target);
	} else if (isSpecialUnary(target.kind) && asSpecialUnary(target.kind).kind == LowExprKind.SpecialUnary.Kind.deref) {
		immutable LowExpr arg = asSpecialUnary(target.kind).arg;
		if (offset != 0) {
			generateExprAndContinue(writer, ctx, locals, arg);
			writeAddConstantNat64(writer, source, offset);
			handleAfter(writer, ctx, source, after);
		} else
			generateExpr(writer, ctx, locals, after, arg);
	} else {
		// Also allow: dereference ptr, get field, and get ptr of that
		// This only works if it's a local .. or another RecordFieldGet
		todo!void("ptr-to-record-field-get");
	}
}

void generateSpecialTernary(
	ref ByteCodeWriter writer,
	ref ExprCtx ctx,
	immutable ByteCodeSource source,
	scope ref Locals locals,
	ref ExprAfter after,
	ref immutable LowExprKind.SpecialTernary a,
) {
	foreach (ref immutable LowExpr arg; a.args)
		generateExprAndContinue(writer, ctx, locals, arg);
	final switch (a.kind) {
		case LowExprKind.SpecialTernary.Kind.interpreterBacktrace:
			writeInterpreterBacktrace(writer, source);
			handleAfter(writer, ctx, source, after);
	}
}

void generateSpecialBinary(
	ref ByteCodeWriter writer,
	ref ExprCtx ctx,
	immutable ByteCodeSource source,
	scope ref Locals locals,
	ref ExprAfter after,
	ref immutable LowExprKind.SpecialBinary a,
) {
	void fn(alias cb)() {
		generateExprAndContinue(writer, ctx, locals, a.left);
		generateExprAndContinue(writer, ctx, locals, a.right);
		writeFnBinary!cb(writer, source);
		handleAfter(writer, ctx, source, after);
	}

	final switch (a.kind) {
		case LowExprKind.SpecialBinary.Kind.addPtrAndNat64:
		case LowExprKind.SpecialBinary.Kind.subPtrAndNat64:
			immutable LowType pointee = asPtrRawPointee(a.left.type);
			generateExprAndContinue(writer, ctx, locals, a.left);
			generateExprAndContinue(writer, ctx, locals, a.right);
			immutable size_t pointeeSize = sizeOfType(ctx, pointee).size;
			if (pointeeSize != 1)
				writeMulConstantNat64(writer, source, pointeeSize);
			if (a.kind == LowExprKind.SpecialBinary.Kind.addPtrAndNat64)
				writeFnBinary!fnWrapAddIntegral(writer, source);
			else
				writeFnBinary!fnWrapSubIntegral(writer, source);
			handleAfter(writer, ctx, source, after);
			break;
		case LowExprKind.SpecialBinary.Kind.addFloat32:
			fn!fnAddFloat32();
			break;
		case LowExprKind.SpecialBinary.Kind.addFloat64:
			fn!fnAddFloat64();
			break;
		case LowExprKind.SpecialBinary.Kind.and:
			generateIf(
				writer, ctx, source, locals, after, a.left,
				(ref ExprAfter innerAfter) {
					generateExpr(writer, ctx, locals, innerAfter, a.right);
				},
				(ref ExprAfter innerAfter) {
					writeBoolConstant(writer, source, false);
					handleAfter(writer, ctx, source, innerAfter);
				});
			break;
		case LowExprKind.SpecialBinary.Kind.unsafeBitShiftLeftNat64:
			fn!fnUnsafeBitShiftLeftNat64();
			break;
		case LowExprKind.SpecialBinary.Kind.unsafeBitShiftRightNat64:
			fn!fnUnsafeBitShiftRightNat64();
			break;
		case LowExprKind.SpecialBinary.Kind.bitwiseAndInt8:
		case LowExprKind.SpecialBinary.Kind.bitwiseAndInt16:
		case LowExprKind.SpecialBinary.Kind.bitwiseAndInt32:
		case LowExprKind.SpecialBinary.Kind.bitwiseAndInt64:
		case LowExprKind.SpecialBinary.Kind.bitwiseAndNat8:
		case LowExprKind.SpecialBinary.Kind.bitwiseAndNat16:
		case LowExprKind.SpecialBinary.Kind.bitwiseAndNat32:
		case LowExprKind.SpecialBinary.Kind.bitwiseAndNat64:
			fn!fnBitwiseAnd();
			break;
		case LowExprKind.SpecialBinary.Kind.bitwiseOrInt8:
		case LowExprKind.SpecialBinary.Kind.bitwiseOrInt16:
		case LowExprKind.SpecialBinary.Kind.bitwiseOrInt32:
		case LowExprKind.SpecialBinary.Kind.bitwiseOrInt64:
		case LowExprKind.SpecialBinary.Kind.bitwiseOrNat8:
		case LowExprKind.SpecialBinary.Kind.bitwiseOrNat16:
		case LowExprKind.SpecialBinary.Kind.bitwiseOrNat32:
		case LowExprKind.SpecialBinary.Kind.bitwiseOrNat64:
			fn!fnBitwiseOr();
			break;
		case LowExprKind.SpecialBinary.Kind.bitwiseXorInt8:
		case LowExprKind.SpecialBinary.Kind.bitwiseXorInt16:
		case LowExprKind.SpecialBinary.Kind.bitwiseXorInt32:
		case LowExprKind.SpecialBinary.Kind.bitwiseXorInt64:
		case LowExprKind.SpecialBinary.Kind.bitwiseXorNat8:
		case LowExprKind.SpecialBinary.Kind.bitwiseXorNat16:
		case LowExprKind.SpecialBinary.Kind.bitwiseXorNat32:
		case LowExprKind.SpecialBinary.Kind.bitwiseXorNat64:
			fn!fnBitwiseXor();
			break;
		case LowExprKind.SpecialBinary.Kind.eqFloat32:
			fn!fnEqFloat32();
			break;
		case LowExprKind.SpecialBinary.Kind.eqFloat64:
			fn!fnEqFloat64();
			break;
		case LowExprKind.SpecialBinary.Kind.eqInt8:
		case LowExprKind.SpecialBinary.Kind.eqInt16:
		case LowExprKind.SpecialBinary.Kind.eqInt32:
		case LowExprKind.SpecialBinary.Kind.eqInt64:
		case LowExprKind.SpecialBinary.Kind.eqNat8:
		case LowExprKind.SpecialBinary.Kind.eqNat16:
		case LowExprKind.SpecialBinary.Kind.eqNat32:
		case LowExprKind.SpecialBinary.Kind.eqNat64:
		case LowExprKind.SpecialBinary.Kind.eqPtr:
			fn!fnEqBits();
			break;
		case LowExprKind.SpecialBinary.Kind.lessBool:
		case LowExprKind.SpecialBinary.Kind.lessChar:
		case LowExprKind.SpecialBinary.Kind.lessNat8:
			fn!fnLessNat8();
			break;
		case LowExprKind.SpecialBinary.Kind.lessNat16:
			fn!fnLessNat16();
			break;
		case LowExprKind.SpecialBinary.Kind.lessNat32:
			fn!fnLessNat32();
			break;
		case LowExprKind.SpecialBinary.Kind.lessNat64:
		case LowExprKind.SpecialBinary.Kind.lessPtr:
			fn!fnLessNat64();
			break;
		case LowExprKind.SpecialBinary.Kind.lessFloat32:
			fn!fnLessFloat32();
			break;
		case LowExprKind.SpecialBinary.Kind.lessFloat64:
			fn!fnLessFloat64();
			break;
		case LowExprKind.SpecialBinary.Kind.lessInt8:
			fn!fnLessInt8();
			break;
		case LowExprKind.SpecialBinary.Kind.lessInt16:
			fn!fnLessInt16();
			break;
		case LowExprKind.SpecialBinary.Kind.lessInt32:
			fn!fnLessInt32();
			break;
		case LowExprKind.SpecialBinary.Kind.lessInt64:
			fn!fnLessInt64();
			break;
		case LowExprKind.SpecialBinary.Kind.mulFloat32:
			fn!fnMulFloat32();
			break;
		case LowExprKind.SpecialBinary.Kind.mulFloat64:
			fn!fnMulFloat64();
			break;
		case LowExprKind.SpecialBinary.Kind.orBool:
			generateIf(
				writer, ctx, source, locals, after, a.left,
				(ref ExprAfter innerAfter) {
					writeBoolConstant(writer, source, true);
					handleAfter(writer, ctx, source, innerAfter);
				},
				(ref ExprAfter innerAfter) {
					generateExpr(writer, ctx, locals, innerAfter, a.right);
				});
			break;
		case LowExprKind.SpecialBinary.Kind.subFloat32:
			fn!fnSubFloat32();
			break;
		case LowExprKind.SpecialBinary.Kind.subFloat64:
			fn!fnSubFloat64();
			break;
		case LowExprKind.SpecialBinary.Kind.unsafeSubInt8:
		case LowExprKind.SpecialBinary.Kind.unsafeSubInt16:
		case LowExprKind.SpecialBinary.Kind.unsafeSubInt32:
		case LowExprKind.SpecialBinary.Kind.unsafeSubInt64:
		case LowExprKind.SpecialBinary.Kind.wrapSubNat8:
		case LowExprKind.SpecialBinary.Kind.wrapSubNat16:
		case LowExprKind.SpecialBinary.Kind.wrapSubNat32:
		case LowExprKind.SpecialBinary.Kind.wrapSubNat64:
			fn!fnWrapSubIntegral();
			break;
		case LowExprKind.SpecialBinary.Kind.unsafeDivFloat32:
			fn!fnUnsafeDivFloat32();
			break;
		case LowExprKind.SpecialBinary.Kind.unsafeDivFloat64:
			fn!fnUnsafeDivFloat64();
			break;
		case LowExprKind.SpecialBinary.Kind.unsafeDivInt8:
			fn!fnUnsafeDivInt8();
			break;
		case LowExprKind.SpecialBinary.Kind.unsafeDivInt16:
			fn!fnUnsafeDivInt16();
			break;
		case LowExprKind.SpecialBinary.Kind.unsafeDivInt32:
			fn!fnUnsafeDivInt32();
			break;
		case LowExprKind.SpecialBinary.Kind.unsafeDivInt64:
			fn!fnUnsafeDivInt64();
			break;
		case LowExprKind.SpecialBinary.Kind.unsafeDivNat8:
			fn!fnUnsafeDivNat8();
			break;
		case LowExprKind.SpecialBinary.Kind.unsafeDivNat16:
			fn!fnUnsafeDivNat16();
			break;
		case LowExprKind.SpecialBinary.Kind.unsafeDivNat32:
			fn!fnUnsafeDivNat32();
			break;
		case LowExprKind.SpecialBinary.Kind.unsafeDivNat64:
			fn!fnUnsafeDivNat64();
			break;
		case LowExprKind.SpecialBinary.Kind.unsafeModNat64:
			fn!fnUnsafeModNat64();
			break;
		case LowExprKind.SpecialBinary.Kind.unsafeAddInt8:
		case LowExprKind.SpecialBinary.Kind.unsafeAddInt16:
		case LowExprKind.SpecialBinary.Kind.unsafeAddInt32:
		case LowExprKind.SpecialBinary.Kind.unsafeAddInt64:
		case LowExprKind.SpecialBinary.Kind.wrapAddNat8:
		case LowExprKind.SpecialBinary.Kind.wrapAddNat16:
		case LowExprKind.SpecialBinary.Kind.wrapAddNat32:
		case LowExprKind.SpecialBinary.Kind.wrapAddNat64:
			fn!fnWrapAddIntegral();
			break;
		case LowExprKind.SpecialBinary.Kind.unsafeMulInt8:
		case LowExprKind.SpecialBinary.Kind.unsafeMulInt16:
		case LowExprKind.SpecialBinary.Kind.unsafeMulInt32:
		case LowExprKind.SpecialBinary.Kind.unsafeMulInt64:
		case LowExprKind.SpecialBinary.Kind.wrapMulNat8:
		case LowExprKind.SpecialBinary.Kind.wrapMulNat16:
		case LowExprKind.SpecialBinary.Kind.wrapMulNat32:
		case LowExprKind.SpecialBinary.Kind.wrapMulNat64:
			fn!fnWrapMulIntegral();
			break;
		case LowExprKind.SpecialBinary.Kind.writeToPtr:
			generateExprAndContinue(writer, ctx, locals, a.left);
			generateExprAndContinue(writer, ctx, locals, a.right);
			writeWrite(writer, source, 0, sizeOfType(ctx, a.right.type).size);
			handleAfter(writer, ctx, source, after);
			break;
	}
}

void generateIf(
	ref ByteCodeWriter writer,
	ref ExprCtx ctx,
	immutable ByteCodeSource source,
	scope ref Locals locals,
	ref ExprAfter after,
	ref immutable LowExpr cond,
	scope void delegate(ref ExprAfter) @safe @nogc pure nothrow cbThen,
	scope void delegate(ref ExprAfter) @safe @nogc pure nothrow cbElse,
) {
	immutable StackEntry stackEntryAtStart = getNextStackEntry(writer);
	generateExprAndContinue(writer, ctx, locals, cond);
	immutable JumpIfFalseDelayed delayed = writeJumpIfFalseDelayed(writer, source);
	withBranching(writer, ctx, after, (ref ExprAfter afterBranch, ref ExprAfter afterLastBranch) {
		cbThen(afterBranch);
		fillDelayedJumpIfFalse(writer, delayed);
		setNextStackEntry(writer, stackEntryAtStart);
		cbElse(afterLastBranch);
		verify(getNextStackEntry(writer) == stackEntriesEnd(after.returnValueStackEntries));
	});
}

@trusted void withBranching(
	ref ByteCodeWriter writer,
	ref ExprCtx ctx,
	ref ExprAfter after,
	// if 'after' is ExprAfterKind.Continue, last branch is different; just slides down to the result
	scope void delegate(ref ExprAfter afterBranch, ref ExprAfter afterLastBranch) @safe @nogc pure nothrow cb,
) {
	immutable bool needsJumps = matchExprAfterKind!(immutable bool)(
		after.kind,
		(immutable ExprAfterKind.Continue) => true,
		(ref ExprAfterKind.JumpDelayed) => false,
		(immutable ExprAfterKind.JumpTo) => false,
		(immutable ExprAfterKind.Return) => false);
	if (needsJumps) {
		MutArr!ByteCodeIndex delayedJumps;
		ExprAfter afterBranch = ExprAfter(
			after.returnValueStackEntries,
			ExprAfterKind(ExprAfterKind.JumpDelayed(&delayedJumps)));
		cb(afterBranch, after);
		foreach (immutable ByteCodeIndex jumpIndex; tempAsArr(delayedJumps))
			fillInJumpDelayed(writer, jumpIndex);
		clearAndFree(ctx.tempAlloc, delayedJumps);
	} else
		cb(after, after);
}
