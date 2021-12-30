module interpret.generateBytecode;

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
	fnEqFloat64,
	fnIsNanFloat32,
	fnIsNanFloat64,
	fnInt64FromInt16,
	fnInt64FromInt32,
	fnFloat64FromFloat32,
	fnFloat64FromInt64,
	fnFloat64FromNat64,
	fnLessFloat32,
	fnLessFloat64,
	fnLessInt8,
	fnLessInt16,
	fnLessInt32,
	fnLessInt64,
	fnLessNat,
	fnMulFloat64,
	fnSubFloat64,
	fnTruncateToInt64FromFloat64,
	fnUnsafeBitShiftLeftNat64,
	fnUnsafeBitShiftRightNat64,
	fnUnsafeDivFloat32,
	fnUnsafeDivFloat64,
	fnUnsafeDivInt64,
	fnUnsafeDivNat64,
	fnUnsafeModNat64,
	fnWrapAddIntegral,
	fnWrapMulIntegral,
	fnWrapSubIntegral;
import interpret.bytecode :
	ByteCode,
	ByteCodeIndex,
	ByteCodeSource,
	ExternOp,
	FileToFuns,
	FunNameAndPos,
	stackEntrySize;
import interpret.bytecodeWriter :
	ByteCodeWriter,
	nextByteCodeIndex,
	fillDelayedCall,
	fillDelayedJumpIfFalse,
	fillDelayedSwitchEntry,
	fillInJumpDelayed,
	finishByteCode,
	getNextStackEntry,
	JumpIfFalseDelayed,
	newByteCodeWriter,
	setNextStackEntry,
	setStackEntryAfterParameters,
	StackEntries,
	stackEntriesEnd,
	StackEntry,
	SwitchDelayed,
	writeAddConstantNat64,
	writeAssertUnreachable,
	writeCallDelayed,
	writeCallFunPtr,
	writeDup,
	writeDupEntries,
	writeDupEntry,
	writeExtern,
	writeExternDynCall,
	writeFnBinary,
	writeFnUnary,
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
	writeSet,
	writeSwitch0ToNDelay,
	writeSwitchWithValuesDelay,
	writeWrite;
import interpret.debugging : writeLowType;
import interpret.extern_ : DynCallType;
import interpret.generateText :
	generateText,
	getTextInfoForArray,
	getTextPointer,
	getTextPointerForCString,
	InterpreterFunPtr,
	TextAndInfo,
	TextArrInfo,
	TextIndex,
	TextInfo;
import model.concreteModel : TypeSize;
import model.constant : Constant, matchConstant;
import model.lowModel :
	asLocalRef,
	asParamRef,
	asPrimitiveType,
	asPtrRawPointee,
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
	LowFun,
	LowFunBody,
	LowFunExprBody,
	lowFunRange,
	LowFunIndex,
	LowLocal,
	LowParam,
	LowProgram,
	LowRecord,
	LowType,
	lowTypeEqual,
	matchLowExprKind,
	matchLowFunBody,
	matchLowType,
	name,
	PrimitiveType,
	UpdateParam;
import model.model : FunDecl, Module, name, Program, range;
import model.typeLayout : nStackEntriesForType, optPack, Pack, sizeOfType;
import util.alloc.alloc : Alloc, TempAlloc;
import util.col.arr : castImmutable, empty, only;
import util.col.arrUtil : map, mapOpWithIndex;
import util.col.dict : mustGetAt;
import util.col.fullIndexDict :
	FullIndexDict,
	fullIndexDictEach,
	fullIndexDictGet,
	fullIndexDictOfArr,
	fullIndexDictSize,
	mapFullIndexDict;
import util.col.mutIndexMultiDict :
	MutIndexMultiDict,
	mutIndexMultiDictAdd,
	mutIndexMultiDictMustGetAt,
	newMutIndexMultiDict;
import util.col.stackDict : StackDict, stackDictAdd, stackDictMustGet;
import util.conv : bitsOfFloat32, bitsOfFloat64;
import util.memory : overwriteMemory;
import util.opt : force, has, none, Opt, some;
import util.ptr : nullPtr, Ptr, ptrEquals, ptrTrustMe, ptrTrustMe_const, ptrTrustMe_mut;
import util.sourceRange : FileIndex;
import util.sym : AllSymbols, shortSymValue, SpecialSym, specialSymValue, Sym;
import util.util : divRoundUp, todo, unreachable, verify;
import util.writer : finishWriter, writeChar, Writer, writeStatic;

immutable(ByteCode) generateBytecode(
	ref Alloc codeAlloc,
	ref TempAlloc tempAlloc,
	ref const AllSymbols allSymbols,
	ref immutable Program modelProgram,
	ref immutable LowProgram program,
) {
	TextAndInfo text = generateText(codeAlloc, tempAlloc, program, program.allConstants);

	MutIndexMultiDict!(LowFunIndex, ByteCodeIndex) funToReferences =
		newMutIndexMultiDict!(LowFunIndex, ByteCodeIndex)(tempAlloc, fullIndexDictSize(program.allFuns));

	ByteCodeWriter writer = newByteCodeWriter(ptrTrustMe_mut(codeAlloc));

	immutable FullIndexDict!(LowFunIndex, ByteCodeIndex) funToDefinition =
		mapFullIndexDict!(LowFunIndex, ByteCodeIndex, LowFun)(
			tempAlloc,
			program.allFuns,
			(immutable LowFunIndex funIndex, ref immutable LowFun fun) {
				immutable ByteCodeIndex funPos = nextByteCodeIndex(writer);
				generateBytecodeForFun(
					tempAlloc,
					writer,
					funToReferences,
					allSymbols,
					text.info,
					program,
					funIndex,
					fun);
				return funPos;
		});

	fullIndexDictEach!(LowFunIndex, ByteCodeIndex)(
		funToDefinition,
		(immutable LowFunIndex index, ref immutable ByteCodeIndex definition) {
			foreach (immutable TextIndex reference; mutIndexMultiDictMustGetAt(text.funToTextReferences, index))
				overwriteMemory(
					trustedCast!(InterpreterFunPtr, ubyte)(&text.text[reference.index]),
					immutable InterpreterFunPtr(definition));
			foreach (immutable ByteCodeIndex reference; mutIndexMultiDictMustGetAt(funToReferences, index))
				fillDelayedCall(writer, reference, definition);
		});

	return finishByteCode(
		writer,
		castImmutable(text.text),
		fullIndexDictGet(funToDefinition, program.main),
		fileToFuns(codeAlloc, allSymbols, modelProgram));
}

private:

@trusted Out* trustedCast(Out, In)(In* ptr) {
	return cast(Out*) ptr;
}

immutable(FileToFuns) fileToFuns(ref Alloc alloc, ref const AllSymbols allSymbols, ref immutable Program program) {
	immutable FullIndexDict!(FileIndex, Module) modulesDict =
		fullIndexDictOfArr!(FileIndex, Module)(program.allModules);
	return mapFullIndexDict!(FileIndex, FunNameAndPos[], Module)(
		alloc,
		modulesDict,
		(immutable FileIndex, ref immutable Module module_) =>
			map(alloc, module_.funs, (ref immutable FunDecl it) =>
				immutable FunNameAndPos(name(it), it.fileAndPos.pos)));
}

immutable(TypeSize) sizeOfType(ref const ExprCtx ctx, ref immutable LowType t) {
	return sizeOfType(ctx.program, t);
}

immutable(size_t) nStackEntriesForType(ref const ExprCtx ctx, ref immutable LowType t) {
	return nStackEntriesForType(ctx.program, t);
}

immutable(size_t) nStackEntriesForRecordType(ref const ExprCtx ctx, ref immutable LowType.Record t) {
	immutable LowType type = immutable LowType(t);
	return nStackEntriesForType(ctx, type);
}

immutable(size_t) nStackEntriesForUnionType(ref const ExprCtx ctx, ref immutable LowType.Union t) {
	immutable LowType type = immutable LowType(t);
	return nStackEntriesForType(ctx, type);
}

void generateBytecodeForFun(
	ref TempAlloc tempAlloc,
	ref ByteCodeWriter writer,
	ref MutIndexMultiDict!(LowFunIndex, ByteCodeIndex) funToReferences,
	ref const AllSymbols allSymbols,
	ref immutable TextInfo textInfo,
	ref immutable LowProgram program,
	immutable LowFunIndex funIndex,
	ref immutable LowFun fun,
) {
	debug {
		if (false) {
			import util.writer : finishWriterToCStr;
			import core.stdc.stdio : printf;
			import interpret.debugging : writeFunName;
			Writer w = Writer(ptrTrustMe_mut(tempAlloc));
			writeFunName(w, allSymbols, program, fun);
			printf("generateBytecodeForFun %s\n", finishWriterToCStr(w));
		}
	}

	size_t stackEntry = 0;
	immutable StackEntries[] parameters = map!StackEntries(
		tempAlloc,
		fun.params,
		(ref immutable LowParam it) {
			immutable StackEntry start = immutable StackEntry(stackEntry);
			immutable size_t n = nStackEntriesForType(program, it.type);
			stackEntry += n;
			return immutable StackEntries(start, n);
		});
	immutable StackEntry stackEntryAfterParameters = immutable StackEntry(stackEntry);
	setStackEntryAfterParameters(writer, stackEntryAfterParameters);
	immutable size_t returnEntries = nStackEntriesForType(program, fun.returnType);
	immutable ByteCodeSource source = immutable ByteCodeSource(funIndex, lowFunRange(fun, allSymbols).range.start);

	matchLowFunBody!(
		void,
		(ref immutable LowFunBody.Extern body_) {
			generateExternCall(tempAlloc, writer, allSymbols, funIndex, fun, body_);
		},
		(ref immutable LowFunExprBody body_) {
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
			immutable Locals locals;
			generateExpr(writer, ctx, locals, body_.expr);
			verify(stackEntryAfterParameters.entry + returnEntries == getNextStackEntry(writer).entry);
			writeRemove(writer, source, immutable StackEntries(
				immutable StackEntry(0),
				stackEntryAfterParameters.entry));
		},
	)(fun.body_);
	verify(getNextStackEntry(writer).entry == returnEntries);
	writeReturn(writer, source);
	setNextStackEntry(writer, immutable StackEntry(0));
}

void generateExternCall(
	ref TempAlloc tempAlloc,
	ref ByteCodeWriter writer,
	ref const AllSymbols allSymbols,
	immutable LowFunIndex funIndex,
	ref immutable LowFun fun,
	ref immutable LowFunBody.Extern a,
) {
	immutable ByteCodeSource source = immutable ByteCodeSource(funIndex, lowFunRange(fun, allSymbols).range.start);
	immutable Opt!Sym optName = name(fun);
	immutable Sym name = force(optName);
	immutable Opt!ExternOp op = externOpFromName(name);
	if (has(op))
		writeExtern(writer, source, force(op));
	else {
		immutable DynCallType[] parameterTypes = map(tempAlloc, fun.params, (ref immutable LowParam it) =>
			toDynCallType(it.type));
		immutable DynCallType returnType = toDynCallType(fun.returnType);
		writeExternDynCall(writer, source, name, returnType, parameterTypes);
	}
	writeReturn(writer, source);
}

immutable(DynCallType) toDynCallType(ref immutable LowType a) {
	return matchLowType!(
		immutable DynCallType,
		(immutable LowType.ExternPtr) =>
			DynCallType.pointer,
		(immutable LowType.FunPtr) =>
			DynCallType.pointer,
		(immutable PrimitiveType it) {
			final switch (it) {
				case PrimitiveType.bool_:
					return DynCallType.bool_;
				case PrimitiveType.char_:
					return DynCallType.char_;
				case PrimitiveType.float32:
					return DynCallType.float32;
				case PrimitiveType.float64:
					return DynCallType.float64;
				case PrimitiveType.int8:
					return DynCallType.int8;
				case PrimitiveType.int16:
					return DynCallType.int16;
				case PrimitiveType.int32:
					return DynCallType.int32;
				case PrimitiveType.int64:
					return DynCallType.int64;
				case PrimitiveType.nat8:
					return DynCallType.nat8;
				case PrimitiveType.nat16:
					return DynCallType.nat16;
				case PrimitiveType.nat32:
					return DynCallType.nat32;
				case PrimitiveType.nat64:
					return DynCallType.nat64;
				case PrimitiveType.void_:
					return DynCallType.void_;
			}
		},
		(immutable LowType.PtrGc) =>
			DynCallType.pointer,
		(immutable LowType.PtrRawConst) =>
			DynCallType.pointer,
		(immutable LowType.PtrRawMut) =>
			DynCallType.pointer,
		(immutable LowType.Record) =>
			unreachable!(immutable DynCallType),
		(immutable LowType.Union) =>
			unreachable!(immutable DynCallType),
	)(a);
}

immutable(Opt!ExternOp) externOpFromName(immutable Sym a) {
	switch (a.value) {
		case shortSymValue("backtrace"):
			return some(ExternOp.backtrace);
		case shortSymValue("free"):
			return some(ExternOp.free);
		case shortSymValue("longjmp"):
			return some(ExternOp.longjmp);
		case shortSymValue("malloc"):
			return some(ExternOp.malloc);
		case shortSymValue("memcpy"):
			return some(ExternOp.memcpy);
		case shortSymValue("memmove"):
			return some(ExternOp.memmove);
		case shortSymValue("memset"):
			return some(ExternOp.memset);
		case shortSymValue("setjmp"):
			return some(ExternOp.setjmp);
		case shortSymValue("write"):
			return some(ExternOp.write);
		case specialSymValue(SpecialSym.clock_gettime):
			return some(ExternOp.clockGetTime);
		case shortSymValue("get_nprocs"):
			return some(ExternOp.getNProcs);
		case specialSymValue(SpecialSym.pthread_condattr_destroy):
			return some(ExternOp.pthreadCondattrDestroy);
		case specialSymValue(SpecialSym.pthread_condattr_init):
			return some(ExternOp.pthreadCondattrInit);
		case specialSymValue(SpecialSym.pthread_condattr_setclock):
			return some(ExternOp.pthreadCondattrSetClock);
		case specialSymValue(SpecialSym.pthread_cond_broadcast):
			return some(ExternOp.pthreadCondBroadcast);
		case specialSymValue(SpecialSym.pthread_cond_destroy):
			return some(ExternOp.pthreadCondDestroy);
		case specialSymValue(SpecialSym.pthread_cond_init):
			return some(ExternOp.pthreadCondInit);
		case specialSymValue(SpecialSym.pthread_create):
			return some(ExternOp.pthreadCreate);
		case shortSymValue("pthread_join"):
			return some(ExternOp.pthreadJoin);
		case specialSymValue(SpecialSym.pthread_mutexattr_destroy):
			return some(ExternOp.pthreadMutexattrDestroy);
		case specialSymValue(SpecialSym.pthread_mutexattr_init):
			return some(ExternOp.pthreadMutexattrInit);
		case specialSymValue(SpecialSym.pthread_mutex_destroy):
			return some(ExternOp.pthreadMutexDestroy);
		case specialSymValue(SpecialSym.pthread_mutex_init):
			return some(ExternOp.pthreadMutexInit);
		case specialSymValue(SpecialSym.pthread_mutex_lock):
			return some(ExternOp.pthreadMutexLock);
		case specialSymValue(SpecialSym.pthread_mutex_unlock):
			return some(ExternOp.pthreadMutexUnlock);
		case shortSymValue("sched_yield"):
			return some(ExternOp.schedYield);
		default:
			return none!ExternOp;
	}
}

struct ExprCtx {
	@safe @nogc pure nothrow:

	const Ptr!AllSymbols allSymbolsPtr;
	immutable Ptr!LowProgram programPtr;
	immutable Ptr!TextInfo textInfoPtr;
	immutable LowFunIndex curFunIndex;
	immutable size_t returnTypeSizeInStackEntries;
	Ptr!TempAlloc tempAllocPtr;
	Ptr!(MutIndexMultiDict!(LowFunIndex, ByteCodeIndex)) funToReferences;
	immutable ByteCodeIndex startOfCurrentFun;
	immutable StackEntries[] parameterEntries;

	ref const(AllSymbols) allSymbols() return scope const {
		return allSymbolsPtr.deref();
	}
	ref immutable(LowProgram) program() return scope const {
		return programPtr.deref();
	}
	ref immutable(TextInfo) textInfo() return scope const {
		return textInfoPtr.deref();
	}
	ref TempAlloc tempAlloc() return scope {
		return tempAllocPtr.deref();
	}
}

alias Locals = immutable StackDict!(
	immutable Ptr!LowLocal,
	immutable StackEntries,
	nullPtr!LowLocal,
	ptrEquals!LowLocal);
alias addLocal = stackDictAdd!(
	immutable Ptr!LowLocal,
	immutable StackEntries,
	nullPtr!LowLocal,
	ptrEquals!LowLocal);
alias getLocal = stackDictMustGet!(
	immutable Ptr!LowLocal,
	immutable StackEntries,
	nullPtr!LowLocal,
	ptrEquals!LowLocal);

void generateExpr(
	ref ByteCodeWriter writer,
	ref ExprCtx ctx,
	scope ref immutable Locals locals,
	ref immutable LowExpr expr,
) {
	immutable ByteCodeSource source = immutable ByteCodeSource(ctx.curFunIndex, expr.source.range.start);
	matchLowExprKind!(
		void,
		(ref immutable LowExprKind.Call it) {
			immutable StackEntry stackEntryBeforeArgs = getNextStackEntry(writer);
			immutable size_t expectedStackEffect = nStackEntriesForType(ctx, expr.type);
			generateArgs(writer, ctx, locals, it.args);
			registerFunAddress(ctx, it.called,
				writeCallDelayed(writer, source, stackEntryBeforeArgs, expectedStackEffect));
			verify(stackEntryBeforeArgs.entry + expectedStackEffect == getNextStackEntry(writer).entry);
		},
		(ref immutable LowExprKind.CallFunPtr it) {
			immutable StackEntry stackEntryBeforeArgs = getNextStackEntry(writer);
			generateExpr(writer, ctx, locals, it.funPtr);
			generateArgs(writer, ctx, locals, it.args);
			writeCallFunPtr(writer, source, stackEntryBeforeArgs, nStackEntriesForType(ctx, expr.type));
		},
		(ref immutable LowExprKind.CreateRecord it) {
			generateCreateRecord(writer, ctx, asRecordType(expr.type), source, locals, it);
		},
		(ref immutable LowExprKind.CreateUnion it) {
			generateCreateUnion(writer, ctx, asUnionType(expr.type), source, locals, it);
		},
		(ref immutable LowExprKind.If it) {
			generateIf(
				writer, ctx, source, locals, it.cond,
				() { generateExpr(writer, ctx, locals, it.then); },
				() { generateExpr(writer, ctx, locals, it.else_); });
		},
		(ref immutable LowExprKind.InitConstants) {
			// bytecode interpreter doesn't need to do anything in 'init-constants'
		},
		(ref immutable LowExprKind.Let it) {
			immutable StackEntries localEntries =
				immutable StackEntries(getNextStackEntry(writer), nStackEntriesForType(ctx, it.local.deref().type));
			generateExpr(writer, ctx, locals, it.value);
			verify(getNextStackEntry(writer).entry == localEntries.start.entry + localEntries.size);
			scope immutable Locals newLocals = addLocal(locals, it.local, localEntries);
			generateExpr(writer, ctx, newLocals, it.then);
			writeRemove(writer, source, localEntries);
		},
		(ref immutable LowExprKind.LocalRef it) {
			immutable StackEntries entries = getLocal(locals, it.local);
			if (entries.size != 0)
				writeDupEntries(writer, source, entries);
		},
		(ref immutable LowExprKind.MatchUnion it) {
			immutable StackEntry startStack = getNextStackEntry(writer);
			generateExpr(writer, ctx, locals, it.matchedValue);
			// Move the union kind to top of stack
			writeDupEntry(writer, source, startStack);
			writeRemove(writer, source, immutable StackEntries(startStack, 1));
			// Get the kind (always the first entry)
			immutable SwitchDelayed switchDelayed = writeSwitch0ToNDelay(writer, source, it.cases.length);
			// Start of the union values is where the kind used to be.
			immutable StackEntry stackAfterMatched = getNextStackEntry(writer);
			immutable StackEntries matchedEntriesWithoutKind =
				immutable StackEntries(startStack, (stackAfterMatched.entry - startStack.entry));
			// TODO: 'mapOp' is overly complex, all but the last case return 'some'
			immutable ByteCodeIndex[] delayedGotos = mapOpWithIndex!ByteCodeIndex(
				ctx.tempAlloc,
				it.cases,
				(immutable size_t caseIndex, ref immutable LowExprKind.MatchUnion.Case case_) @safe {
					fillDelayedSwitchEntry(writer, switchDelayed, caseIndex);
					if (has(case_.local)) {
						immutable size_t nEntries = nStackEntriesForType(ctx, force(case_.local).deref().type);
						verify(nEntries <= matchedEntriesWithoutKind.size);
						scope immutable Locals newLocals = addLocal(
							locals,
							force(case_.local),
							immutable StackEntries(matchedEntriesWithoutKind.start, nEntries));
						generateExpr(writer, ctx, newLocals, case_.then);
					} else {
						generateExpr(writer, ctx, locals, case_.then);
					}
					if (caseIndex != it.cases.length - 1) {
						setNextStackEntry(writer, stackAfterMatched);
						return some(writeJumpDelayed(writer, source));
					} else
						// For the last one, don't reset the stack as by the end one of the cases will have run.
						// Last one doesn't need a jump, just continues straight into the code after it.
						return none!ByteCodeIndex;
				});
			foreach (immutable ByteCodeIndex jumpIndex; delayedGotos)
				fillInJumpDelayed(writer, jumpIndex);
			writeRemove(writer, source, matchedEntriesWithoutKind);
		},
		(ref immutable LowExprKind.ParamRef it) {
			immutable StackEntries entries = ctx.parameterEntries[it.index.index];
			if (entries.size != 0)
				writeDupEntries(writer, source, entries);
		},
		(ref immutable LowExprKind.PtrCast it) {
			generateExpr(writer, ctx, locals, it.target);
		},
		(ref immutable LowExprKind.RecordFieldGet it) {
			generateRecordFieldGet(writer, ctx, source, locals, it);
		},
		(ref immutable LowExprKind.RecordFieldSet it) {
			immutable StackEntry before = getNextStackEntry(writer);
			verify(it.targetIsPointer);
			generateExpr(writer, ctx, locals, it.target);
			immutable StackEntry mid = getNextStackEntry(writer);
			generateExpr(writer, ctx, locals, it.value);
			immutable FieldOffsetAndSize offsetAndSize = getFieldOffsetAndSize(ctx, it.record, it.fieldIndex);
			verify(mid.entry + divRoundUp(offsetAndSize.size, stackEntrySize) == getNextStackEntry(writer).entry);
			writeWrite(writer, source, offsetAndSize.offset, offsetAndSize.size);
			verify(getNextStackEntry(writer) == before);
		},
		(ref immutable LowExprKind.Seq it) {
			generateExpr(writer, ctx, locals, it.first);
			generateExpr(writer, ctx, locals, it.then);
		},
		(ref immutable LowExprKind.SizeOf it) {
			writePushConstant(writer, source, sizeOfType(ctx, it.type).size);
		},
		(ref immutable Constant it) {
			generateConstant(writer, ctx, source, expr.type, it);
		},
		(ref immutable LowExprKind.SpecialUnary it) {
			generateSpecialUnary(writer, ctx, source, locals, expr.type, it);
		},
		(ref immutable LowExprKind.SpecialBinary it) {
			generateSpecialBinary(writer, ctx, source, locals, it);
		},
		(ref immutable LowExprKind.Switch0ToN it) {
			generateSwitch0ToN(writer, ctx, source, locals, it);
		},
		(ref immutable LowExprKind.SwitchWithValues it) {
			generateSwitchWithValues(writer, ctx, source, locals, it);
		},
		(ref immutable LowExprKind.TailRecur it) {
			// We need to generate all new values before overwriting anything.
			foreach (ref immutable UpdateParam updateParam; it.updateParams)
				generateExpr(writer, ctx, locals, updateParam.newValue);
			// Now pop them in reverse and write to the appropriate params
			foreach_reverse (ref immutable UpdateParam updateParam; it.updateParams)
				writeSet(writer, source, ctx.parameterEntries[updateParam.param.index]);

			// Delete anything on the stack besides parameters
			immutable StackEntry parametersEnd = empty(ctx.parameterEntries)
				? immutable StackEntry(0)
				: stackEntriesEnd(ctx.parameterEntries[$ - 1]);
			immutable StackEntry localsEnd = getNextStackEntry(writer);
			writeRemove(writer, source, immutable StackEntries(parametersEnd, localsEnd.entry - parametersEnd.entry));
			writeJump(writer, source, ctx.startOfCurrentFun);

			// We'll continue to write code after the jump for cleaning up the stack, but it's unreachable.
			// Set the stack entry as if this was a regular call returning.
			setNextStackEntry(writer, immutable StackEntry(localsEnd.entry + ctx.returnTypeSizeInStackEntries));
			writeAssertUnreachable(writer, source);
		},
		(ref immutable LowExprKind.Zeroed) {
			writePushEmptySpace(writer, source, nStackEntriesForType(ctx, expr.type));
		},
	)(expr.kind);
}

void generateSwitch0ToN(
	ref ByteCodeWriter writer,
	ref ExprCtx ctx,
	immutable ByteCodeSource source,
	scope ref immutable Locals locals,
	ref immutable LowExprKind.Switch0ToN it,
 ) {
	immutable StackEntry stackBefore = getNextStackEntry(writer);
	generateExpr(writer, ctx, locals, it.value);
	writeSwitchCases(
		writer,
		ctx,
		source,
		locals,
		stackBefore,
		writeSwitch0ToNDelay(writer, source, it.cases.length),
		it.cases);
}

void generateSwitchWithValues(
	ref ByteCodeWriter writer,
	ref ExprCtx ctx,
	immutable ByteCodeSource source,
	scope ref immutable Locals locals,
	ref immutable LowExprKind.SwitchWithValues it,
) {
	immutable StackEntry stackBefore = getNextStackEntry(writer);
	generateExpr(writer, ctx, locals, it.value);
	writeSwitchCases(
		writer,
		ctx,
		source,
		locals,
		stackBefore,
		writeSwitchWithValuesDelay(writer, source, it.values),
		it.cases);
}

void writeSwitchCases(
	ref ByteCodeWriter writer,
	ref ExprCtx ctx,
	immutable ByteCodeSource source,
	scope ref immutable Locals locals,
	immutable StackEntry stackBefore,
	immutable SwitchDelayed switchDelayed,
	immutable LowExpr[] cases,
 ) {
	// TODO: 'mapOp' is overly complex, all but the last case return 'some'
	immutable ByteCodeIndex[] delayedGotos = mapOpWithIndex!ByteCodeIndex(
		ctx.tempAlloc,
		cases,
		(immutable size_t caseIndex, ref immutable LowExpr case_) {
			fillDelayedSwitchEntry(writer, switchDelayed, caseIndex);
			generateExpr(writer, ctx, locals, case_);
			if (caseIndex != cases.length - 1) {
				setNextStackEntry(writer, stackBefore);
				return some(writeJumpDelayed(writer, source));
			} else
				return none!ByteCodeIndex;
		});
	foreach (immutable ByteCodeIndex jumpIndex; delayedGotos)
		fillInJumpDelayed(writer, jumpIndex);
}

void generateArgs(
	ref ByteCodeWriter writer,
	ref ExprCtx ctx,
	scope ref immutable Locals locals,
	immutable LowExpr[] args,
) {
	foreach (ref immutable LowExpr arg; args)
		generateExpr(writer, ctx, locals, arg);
}

void generateCreateRecord(
	ref ByteCodeWriter writer,
	ref ExprCtx ctx,
	immutable LowType.Record type,
	immutable ByteCodeSource source,
	scope ref immutable Locals locals,
	ref immutable LowExprKind.CreateRecord it,
) {
	generateCreateRecordOrConstantRecord(
		writer,
		ctx,
		type,
		source,
		(immutable size_t fieldIndex, ref immutable LowType fieldType) {
			immutable LowExpr arg = it.args[fieldIndex];
			verify(lowTypeEqual(arg.type, fieldType));
			generateExpr(writer, ctx, locals, arg);
		});
}

void generateCreateRecordOrConstantRecord(
	ref ByteCodeWriter writer,
	ref ExprCtx ctx,
	immutable LowType.Record type,
	immutable ByteCodeSource source,
	scope void delegate(immutable size_t, ref immutable LowType) @safe @nogc pure nothrow cbGenerateField,
) {
	immutable StackEntry before = getNextStackEntry(writer);

	immutable LowRecord record = fullIndexDictGet(ctx.program.allRecords, type);
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
	scope ref immutable Locals locals,
	ref immutable LowExprKind.CreateUnion it,
) {
	generateCreateUnionOrConstantUnion(
		writer,
		ctx,
		type,
		it.memberIndex,
		source,
		(ref immutable LowType) {
			generateExpr(writer, ctx, locals, it.arg);
		});
}

void generateCreateUnionOrConstantUnion(
	ref ByteCodeWriter writer,
	ref const ExprCtx ctx,
	immutable LowType.Union type,
	immutable size_t memberIndex,
	immutable ByteCodeSource source,
	scope void delegate(ref immutable LowType) @safe @nogc pure nothrow cbGenerateMember,
) {
	immutable StackEntry before = getNextStackEntry(writer);
	immutable size_t size = nStackEntriesForUnionType(ctx, type);
	writePushConstant(writer, source, memberIndex);
	immutable LowType memberType = fullIndexDictGet(ctx.program.allUnions, type).members[memberIndex];
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
	immutable LowField field = fullIndexDictGet(ctx.program.allRecords, record).fields[fieldIndex];
	immutable size_t size = sizeOfType(ctx, field.type).size;
	return immutable FieldOffsetAndSize(field.offset, size);
}

void registerFunAddress(ref ExprCtx ctx, immutable LowFunIndex fun, immutable ByteCodeIndex index) {
	mutIndexMultiDictAdd(ctx.tempAlloc, ctx.funToReferences.deref(), fun, index);
}

void generateConstant(
	ref ByteCodeWriter writer,
	ref ExprCtx ctx,
	immutable ByteCodeSource source,
	ref immutable LowType type,
	ref immutable Constant constant,
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
			immutable LowFunIndex index = mustGetAt(ctx.program.concreteFunToLowFunIndex, it.fun);
			registerFunAddress(ctx, index, writePushFunPtrDelayed(writer, source));
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
				(immutable size_t argIndex, ref immutable LowType argType) {
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
				(ref immutable LowType memberType) {
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
	scope ref immutable Locals locals,
	ref immutable LowType type,
	ref immutable LowExprKind.SpecialUnary a,
) {
	void generateArg() {
		generateExpr(writer, ctx, locals, a.arg);
	}

	void fn(alias cb)() {
		generateArg();
		writeFnUnary!cb(writer, source);
	}

	final switch (a.kind) {
		case LowExprKind.SpecialUnary.Kind.asAnyPtr:
		case LowExprKind.SpecialUnary.Kind.asRef:
		case LowExprKind.SpecialUnary.Kind.enumToIntegral:
		case LowExprKind.SpecialUnary.Kind.toCharFromNat8:
		case LowExprKind.SpecialUnary.Kind.toNat8FromChar:
		case LowExprKind.SpecialUnary.Kind.toNat64FromPtr:
		case LowExprKind.SpecialUnary.Kind.toPtrFromNat64:
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
			generateArg();
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
		case LowExprKind.SpecialUnary.Kind.isNanFloat32:
			fn!fnIsNanFloat32();
			break;
		case LowExprKind.SpecialUnary.Kind.isNanFloat64:
			fn!fnIsNanFloat64();
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
			break;
		case LowExprKind.SpecialUnary.Kind.toNat64FromNat16:
			generateArg();
			writePushConstant(writer, source, ushort.max);
			writeFnBinary!fnBitwiseAnd(writer, source);
			break;
		case LowExprKind.SpecialUnary.Kind.toNat64FromNat32:
			generateArg();
			writePushConstant(writer, source, uint.max);
			writeFnBinary!fnBitwiseAnd(writer, source);
			break;
		case LowExprKind.SpecialUnary.Kind.deref:
			generateArg();
			writeRead(writer, source, 0, sizeOfType(ctx, type).size);
			break;
		case LowExprKind.SpecialUnary.Kind.ptrTo:
		case LowExprKind.SpecialUnary.Kind.refOfVal:
			generateRefOfVal(writer, ctx, source, locals, a.arg);
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
	scope ref immutable Locals locals,
	ref immutable LowExpr arg,
) {
	if (isLocalRef(arg.kind))
		writeStackRef(writer, source, getLocal(locals, asLocalRef(arg.kind).local).start);
	else if (isParamRef(arg.kind))
		writeStackRef(writer, source, ctx.parameterEntries[asParamRef(arg.kind).index.index].start);
	else if (isRecordFieldGet(arg.kind)) {
		immutable LowExprKind.RecordFieldGet rfa = asRecordFieldGet(arg.kind);
		generatePtrToRecordFieldGet(
			writer,
			ctx,
			source,
			locals,
			rfa.record,
			rfa.fieldIndex,
			rfa.targetIsPointer,
			rfa.target);
	} else if(isSpecialUnary(arg.kind)) {
		immutable LowExprKind.SpecialUnary it = asSpecialUnary(arg.kind);
		if (it.kind == LowExprKind.SpecialUnary.Kind.deref)
			// Ref of deref just changes the type
			generateExpr(writer, ctx, locals, it.arg);
		else
			todo!void("!");
	} else
		todo!void("!");
}

void generateRecordFieldGet(
	ref ByteCodeWriter writer,
	ref ExprCtx ctx,
	immutable ByteCodeSource source,
	scope ref immutable Locals locals,
	ref immutable LowExprKind.RecordFieldGet it,
) {
	immutable StackEntry targetEntry = getNextStackEntry(writer);
	generateExpr(writer, ctx, locals, it.target);
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
	scope ref immutable Locals locals,
	immutable LowType.Record record,
	immutable size_t fieldIndex,
	immutable bool targetIsPointer,
	ref immutable LowExpr target,
) {
	generateExpr(writer, ctx, locals, target);
	immutable size_t offset = fullIndexDictGet(ctx.program.allRecords, record).fields[fieldIndex].offset;
	if (targetIsPointer) {
		if (offset != 0)
			writeAddConstantNat64(writer, source, offset);
	} else
		// This only works if it's a local .. or another RecordFieldGet
		todo!void("ptr-to-record-field-get");
}

void generateSpecialBinary(
	ref ByteCodeWriter writer,
	ref ExprCtx ctx,
	immutable ByteCodeSource source,
	scope ref immutable Locals locals,
	ref immutable LowExprKind.SpecialBinary a,
) {
	void fn(alias cb)() {
		generateExpr(writer, ctx, locals, a.left);
		generateExpr(writer, ctx, locals, a.right);
		writeFnBinary!cb(writer, source);
	}

	final switch (a.kind) {
		case LowExprKind.SpecialBinary.Kind.addPtrAndNat64:
		case LowExprKind.SpecialBinary.Kind.subPtrAndNat64:
			immutable LowType pointee = asPtrRawPointee(a.left.type);
			generateExpr(writer, ctx, locals, a.left);
			generateExpr(writer, ctx, locals, a.right);
			immutable size_t pointeeSize = sizeOfType(ctx, pointee).size;
			if (pointeeSize != 1)
				writeMulConstantNat64(writer, source, pointeeSize);
			if (a.kind == LowExprKind.SpecialBinary.Kind.addPtrAndNat64)
				writeFnBinary!fnWrapAddIntegral(writer, source);
			else
				writeFnBinary!fnWrapSubIntegral(writer, source);
			break;
		case LowExprKind.SpecialBinary.Kind.addFloat32:
			fn!fnAddFloat32();
			break;
		case LowExprKind.SpecialBinary.Kind.addFloat64:
			fn!fnAddFloat64();
			break;
		case LowExprKind.SpecialBinary.Kind.and:
			generateIf(
				writer, ctx, source, locals, a.left,
				() { generateExpr(writer, ctx, locals, a.right); },
				() { writeBoolConstant(writer, source, false); });
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
		case LowExprKind.SpecialBinary.Kind.lessNat16:
		case LowExprKind.SpecialBinary.Kind.lessNat32:
		case LowExprKind.SpecialBinary.Kind.lessNat64:
		case LowExprKind.SpecialBinary.Kind.lessPtr:
			fn!fnLessNat();
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
		case LowExprKind.SpecialBinary.Kind.mulFloat64:
			fn!fnMulFloat64();
			break;
		case LowExprKind.SpecialBinary.Kind.orBool:
			generateIf(
				writer, ctx, source, locals, a.left,
				() { writeBoolConstant(writer, source, true); },
				() { generateExpr(writer, ctx, locals, a.right); });
			break;
		case LowExprKind.SpecialBinary.Kind.subFloat64:
			fn!fnSubFloat64();
			break;
		case LowExprKind.SpecialBinary.Kind.wrapSubInt16:
		case LowExprKind.SpecialBinary.Kind.wrapSubInt32:
		case LowExprKind.SpecialBinary.Kind.wrapSubInt64:
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
		case LowExprKind.SpecialBinary.Kind.unsafeDivInt64:
			fn!fnUnsafeDivInt64();
			break;
		case LowExprKind.SpecialBinary.Kind.unsafeDivNat64:
			fn!fnUnsafeDivNat64();
			break;
		case LowExprKind.SpecialBinary.Kind.unsafeModNat64:
			fn!fnUnsafeModNat64();
			break;
		case LowExprKind.SpecialBinary.Kind.wrapAddInt16:
		case LowExprKind.SpecialBinary.Kind.wrapAddInt32:
		case LowExprKind.SpecialBinary.Kind.wrapAddInt64:
		case LowExprKind.SpecialBinary.Kind.wrapAddNat8:
		case LowExprKind.SpecialBinary.Kind.wrapAddNat16:
		case LowExprKind.SpecialBinary.Kind.wrapAddNat32:
		case LowExprKind.SpecialBinary.Kind.wrapAddNat64:
			fn!fnWrapAddIntegral();
			break;
		case LowExprKind.SpecialBinary.Kind.wrapMulInt16:
		case LowExprKind.SpecialBinary.Kind.wrapMulInt32:
		case LowExprKind.SpecialBinary.Kind.wrapMulInt64:
		case LowExprKind.SpecialBinary.Kind.wrapMulNat16:
		case LowExprKind.SpecialBinary.Kind.wrapMulNat32:
		case LowExprKind.SpecialBinary.Kind.wrapMulNat64:
			fn!fnWrapMulIntegral();
			break;
		case LowExprKind.SpecialBinary.Kind.writeToPtr:
			generateExpr(writer, ctx, locals, a.left);
			generateExpr(writer, ctx, locals, a.right);
			writeWrite(writer, source, 0, sizeOfType(ctx, a.right.type).size);
			break;
	}
}

void generateIf(
	ref ByteCodeWriter writer,
	ref ExprCtx ctx,
	immutable ByteCodeSource source,
	scope ref immutable Locals locals,
	ref immutable LowExpr cond,
	scope void delegate() @safe @nogc pure nothrow cbThen,
	scope void delegate() @safe @nogc pure nothrow cbElse,
) {
	immutable StackEntry startStack = getNextStackEntry(writer);
	generateExpr(writer, ctx, locals, cond);
	immutable JumpIfFalseDelayed delayed = writeJumpIfFalseDelayed(writer, source);
	cbThen();
	// At the end of 'then', jump to the end.
	immutable ByteCodeIndex jumpIndex = writeJumpDelayed(writer, source);
	fillDelayedJumpIfFalse(writer, delayed);
	setNextStackEntry(writer, startStack);
	cbElse();
	fillInJumpDelayed(writer, jumpIndex);
}
