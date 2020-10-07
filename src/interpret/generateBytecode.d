module interpret.generateBytecode;

@safe @nogc pure nothrow:

import interpret.bytecode :
	ByteCode,
	ByteCodeIndex,
	ByteCodeOffset,
	ByteCodeWriter,
	curByteCodeIndex,
	fillDelayedU8,
	fillDelayedU32,
	fillInJumpDelayed,
	finishByteCode,
	getNextStackEntry,
	setNextStackEntry,
	setStackEntryAfterParameters,
	StackEntries,
	writeCallDelayed,
	writeGet,
	writePushU8,
	writePushU32,
	writePushU32Delayed,
	writeJumpDelayed,
	writeRemove,
	writeReturn,
	writeSwitchDelay;
import lowModel :
	LowExpr,
	LowExprKind,
	LowField,
	LowFun,
	LowFunBody,
	LowFunExprBody,
	LowFunIndex,
	LowLocal,
	LowParam,
	LowProgram,
	LowRecord,
	LowType,
	LowUnion,
	matchLowExprKind,
	matchLowFunBody,
	matchLowType,
	PrimitiveType;
import util.alloc.stackAlloc : StackAlloc;
import util.collection.arr : Arr, at, range, size;
import util.collection.arrUtil : arrMax, map, mapOpWithIndex, sum;
import util.collection.fullIndexDict :
	FullIndexDict,
	fullIndexDictEach,
	fullIndexDictGet,
	fullIndexDictOfArr,
	fullIndexDictSize,
	mapFullIndexDict;
import util.collection.fullIndexDictBuilder :
	finishFullIndexDict,
	FullIndexDictBuilder,
	fullIndexDictBuilderAdd,
	fullIndexDictBuilderHas,
	fullIndexDictBuilderOptGet,
	newFullIndexDictBuilder;
import util.collection.mutIndexDict;
import util.collection.mutDict : addToMutDict, mustDelete, mustGetAt_mut, MutDict;
import util.collection.mutIndexDict : MutIndexDict;
import util.collection.mutIndexMultiDict :
	MutIndexMultiDict,
	mutIndexMultiDictAdd,
	mutIndexMultiDictMustGetAt,
	newMutIndexMultiDict;
import util.comparison : Comparison;
import util.opt : force, has, none, Opt, some;
import util.ptr : comparePtr, Ptr, ptrTrustMe, ptrTrustMe_mut;
import util.types : safeSizeTToU8, safeSizeTToU32, safeU32ToU8, u8;
import util.util : roundUp, todo, verify;

immutable(ByteCode) generateBytecode(CodeAlloc)(ref CodeAlloc codeAlloc, ref immutable LowProgram program) {
	alias TempAlloc = StackAlloc!("generateBytecode", 1024 * 1024);
	TempAlloc tempAlloc;

	immutable RecordLayout recordLayout = layOutRecords(tempAlloc, program);

	MutIndexMultiDict!(LowFunIndex, ByteCodeIndex) funToReferences =
		newMutIndexMultiDict!(LowFunIndex, ByteCodeIndex)(tempAlloc, fullIndexDictSize(program.allFuns));

	ByteCodeWriter!CodeAlloc writer = ByteCodeWriter!CodeAlloc(ptrTrustMe_mut(codeAlloc));

	immutable FullIndexDict!(LowFunIndex, ByteCodeIndex) funToDefinition =
		mapFullIndexDict!(LowFunIndex, ByteCodeIndex, LowFun, TempAlloc)(
			tempAlloc,
			program.allFuns,
			(immutable LowFunIndex, ref immutable LowFun fun) {
				immutable ByteCodeIndex funPos = curByteCodeIndex(writer);
				generateBytecodeForFun(tempAlloc, writer, funToReferences, program, fun);
				return funPos;
		});

	fullIndexDictEach(funToDefinition, (immutable LowFunIndex index, ref immutable ByteCodeIndex definition) {
		foreach (immutable ByteCodeIndex reference; range(mutIndexMultiDictMustGetAt(funToReferences, index)))
			fillDelayedU32(writer, reference, definition);
	});

	immutable ByteCodeIndex mainIndex = todo!(immutable ByteCodeIndex)("mainIndex");

	return finishByteCode(writer, mainIndex);
}

private:

// NOTE: we should lay out structs so that no primitive field straddles multiple stack entries.
struct RecordLayout {
	immutable FullIndexDict!(LowType.Record, u8) recordSizes;
	immutable FullIndexDict!(LowType.Record, Arr!u8) fieldOffsets; // In bytes.
}

struct RecordLayoutBuilder {
	FullIndexDictBuilder!(LowType.Record, u8) resultSizes;
	FullIndexDictBuilder!(LowType.Record, Arr!u8) resultFieldOffsets;
}

immutable(RecordLayout) layOutRecords(Alloc)(ref Alloc alloc, ref immutable LowProgram program) {
	RecordLayoutBuilder builder = RecordLayoutBuilder(
		newFullIndexDictBuilder!(LowType.Record, u8)(alloc, fullIndexDictSize(program.allRecords)),
		newFullIndexDictBuilder!(LowType.Record, Arr!u8)(alloc, fullIndexDictSize(program.allRecords)));
	fullIndexDictEach(program.allRecords, (immutable LowType.Record index, ref immutable LowRecord record) {
		if (!fullIndexDictBuilderHas(builder.resultSizes, index))
			fillRecordSize!Alloc(alloc, program, index, record, builder);
	});
	return immutable RecordLayout(
		finishFullIndexDict(builder.resultSizes),
		finishFullIndexDict(builder.resultFieldOffsets));
}

immutable u8 fieldBoundary = 8;

immutable(u8) fillRecordSize(Alloc)(
	ref Alloc alloc,
	ref immutable LowProgram program,
	immutable LowType.Record index,
	ref immutable LowRecord record,
	ref RecordLayoutBuilder builder,
) {
	u8 offset = 0;
	immutable Arr!u8 fieldOffsets = map(alloc, record.fields, (ref immutable LowField field) {
		immutable u8 fieldSize = sizeOfType(alloc, program, field.type, builder);
		// If field would stretch across a boundary, move offset up to the next boundary
		immutable u8 mod = offset % fieldBoundary;
		if (mod != 0 && mod + fieldSize > fieldBoundary) {
			offset = roundUp(offset, fieldBoundary);
		}
		immutable u8 res = offset;
		offset += fieldSize;
		return res;
	});
	immutable u8 size = offset;
	fullIndexDictBuilderAdd(builder.resultSizes, index, size);
	fullIndexDictBuilderAdd(builder.resultFieldOffsets, index, fieldOffsets);
	return size;
}

immutable u8 externPtrSize = (void*).sizeof;
immutable u8 ptrSize = (void*).sizeof;
immutable u8 funPtrSize = 4;
immutable u8 unionTypeSize = 8;

immutable(u8) sizeOfType(Alloc)(
	ref Alloc alloc,
	ref immutable LowProgram program,
	ref immutable LowType t,
	ref RecordLayoutBuilder builder,
) {
	return matchLowType!(immutable u8)(
		t,
		(immutable LowType.ExternPtr) => externPtrSize,
		(immutable LowType.FunPtr) => funPtrSize,
		(immutable LowType.NonFunPtr) => ptrSize,
		(immutable PrimitiveType it) => primitiveSize(it),
		(immutable LowType.Record index) {
			//immutable LowRecord record = fullIndexDictGet(program.allRecords, index);
			immutable Opt!u8 size = fullIndexDictBuilderOptGet(builder.resultSizes, index);
			return has(size)
				? force(size)
				: fillRecordSize(alloc, program, index, fullIndexDictGet(program.allRecords, index), builder);
		},
		(immutable LowType.Union it) =>
			// Union type takes up entire word
			safeSizeTToU8(unionTypeSize + nStackEntriesForUnionTypeExcludingKind(program, it)));
}

immutable(u8) primitiveSize(immutable PrimitiveType a) {
	return todo!(immutable u8)("primitiveSize");
}

//TODO:KILL! Use record sizes!
immutable(u8) nStackEntriesForType(ref immutable LowProgram program, ref immutable LowType t) {
	todo!void("KILL");
	return matchLowType!(immutable u8)(
		t,
		(immutable LowType.ExternPtr) => immutable u8(1),
		(immutable LowType.FunPtr) => immutable u8(1),
		(immutable LowType.NonFunPtr) => immutable u8(1),
		(immutable PrimitiveType) => immutable u8(1),
		(immutable LowType.Record record) =>
			// TODO: for perf, would be better if record fields could share stack entries.
			safeSizeTToU8(sum!LowField(
				fullIndexDictGet(program.allRecords, record).fields,
				(ref immutable LowField field) =>
					immutable size_t(nStackEntriesForType(program, field.type)))),
		(immutable LowType.Union it) =>
			// Union kind takes up an entire stack entry
			safeSizeTToU8(1 + nStackEntriesForUnionTypeExcludingKind(program, it)));
}

immutable(u8) nStackEntriesForUnionTypeExcludingKind(
	ref immutable LowProgram program,
	ref immutable LowType.Union union_,
) {
	return arrMax(immutable u8(0), fullIndexDictGet(program.allUnions, union_).members, (ref immutable LowType t) =>
		nStackEntriesForType(program, t));
}

void generateBytecodeForFun(TempAlloc, CodeAlloc)(
	ref TempAlloc tempAlloc,
	ref ByteCodeWriter!CodeAlloc writer,
	ref MutIndexMultiDict!(LowFunIndex, ByteCodeIndex) funToReferences,
	ref immutable LowProgram program,
	ref immutable LowFun fun,
) {
	matchLowFunBody!void(
		fun.body_,
		(ref immutable LowFunBody.Extern body_) {
			generateExternCall(body_);
		},
		(ref immutable LowFunExprBody body_) {
			uint stackEntry = 0;
			immutable Arr!StackEntries parameters = map!StackEntries(
				tempAlloc,
				fun.params,
				(ref immutable LowParam it) {
					immutable uint start = stackEntry;
					immutable uint n = nStackEntriesForType(program, it.type);
					stackEntry += n;
					return immutable StackEntries(start, n);
				});
			setStackEntryAfterParameters(writer, stackEntry);
			// Note: not doing it for locals because they might be unrelated and occupy the same stack entry
			ExprCtx ctx = ExprCtx(ptrTrustMe(program), ptrTrustMe_mut(funToReferences), parameters);
			generateExpr(tempAlloc, writer, ctx, body_.expr);
			writeReturn(writer);
		});
}

void generateExternCall(ref immutable LowFunBody.Extern a) {
	todo!void("generateExternCall");
}

struct ExprCtx {
	immutable Ptr!LowProgram program;
	Ptr!(MutIndexMultiDict!(LowFunIndex, ByteCodeIndex)) funToReferences;
	immutable Arr!StackEntries parameterEntries;
	MutDict!(immutable Ptr!LowLocal, immutable StackEntries, comparePtr!LowLocal) localEntries;
}

void generateExpr(CodeAlloc, TempAlloc)(
	ref TempAlloc tempAlloc,
	ref ByteCodeWriter!CodeAlloc writer,
	ref ExprCtx ctx,
	ref immutable LowExpr expr,
) {
	return matchLowExprKind(
		expr.kind,
		(ref immutable LowExprKind.Call it) {
			immutable uint stackEntryBeforeArgs = getNextStackEntry(writer);
			foreach (ref immutable LowExpr arg; range(it.args))
				generateExpr(tempAlloc, writer, ctx, arg);
			registerFunAddress(tempAlloc, ctx, it.called,
				writeCallDelayed(writer, stackEntryBeforeArgs, nStackEntriesForType(ctx.program, expr.type)));
		},
		(ref immutable LowExprKind.CreateRecord it) {
			// WARN: this works because we store every record field in separate entries.
			// When allocating to the heap we'll compact them according to the record layout.
			foreach (ref immutable LowExpr arg; range(it.args))
				generateExpr(tempAlloc, writer, ctx, arg);
		},
		(ref immutable LowExprKind.ConvertToUnion it) {
			//immutable uint offset = nStackEntriesForUnionTypeExcludingKind(ctx.program, asUnionType(it.type));
			writePushU8(writer, it.memberIndex);
			generateExpr(tempAlloc, writer, ctx, it.arg);
		},
		(ref immutable LowExprKind.FunPtr it) {
			registerFunAddress(tempAlloc, ctx, it.fun,
				writePushU32Delayed(writer));
		},
		(ref immutable LowExprKind.Let it) {
			immutable StackEntries localEntries =
				immutable StackEntries(getNextStackEntry(writer), nStackEntriesForType(ctx.program, it.local.type));
			generateExpr(tempAlloc, writer, ctx, it.value);
			verify(getNextStackEntry(writer) == localEntries.start + localEntries.size);
			addToMutDict(tempAlloc, ctx.localEntries, it.local, localEntries);
			generateExpr(tempAlloc, writer, ctx, it.then);
			mustDelete(ctx.localEntries, it.local);
			writeRemove(writer, localEntries);
		},
		(ref immutable LowExprKind.LocalRef it) {
			writeGet!CodeAlloc(writer, mustGetAt_mut(ctx.localEntries, it.local));
		},
		(ref immutable LowExprKind.Match it) {
			immutable uint startStack = getNextStackEntry(writer);
			generateExpr(tempAlloc, writer, ctx, it.matchedValue);
			// Move the union kind to top of stack
			writeGet(writer, immutable StackEntries(startStack, 1));
			writeRemove(writer, immutable StackEntries(startStack));
			// Get the kind (always the first entry)
			immutable ByteCodeIndex indexOfFirstCaseOffset = writeSwitchDelay(writer, size(it.cases));
			// Start of the union values is where the kind used to be.
			immutable uint stackAfterMatched = getNextStackEntry(writer);
			immutable StackEntries matchedEntriesWithoutKind =
				immutable StackEntries(startStack, safeU32ToU8(stackAfterMatched - startStack));
			immutable Arr!ByteCodeIndex delayedGotos = mapOpWithIndex!ByteCodeIndex(
				tempAlloc,
				it.cases,
				(immutable size_t caseIndex, ref immutable LowExprKind.Match.Case case_) {
					fillDelayedU8(
						writer,
						immutable ByteCodeIndex(safeSizeTToU32(indexOfFirstCaseOffset.index + caseIndex)),
						immutable ByteCodeOffset(
							safeU32ToU8(curByteCodeIndex(writer).index - indexOfFirstCaseOffset.index)));
					curByteCodeIndex(writer);
					if (has(case_.local)) {
						immutable uint nEntries = nStackEntriesForType(ctx.program, force(case_.local).type);
						verify(nEntries <= matchedEntriesWithoutKind.size);
						addToMutDict(
							tempAlloc,
							ctx.localEntries,
							force(case_.local),
							immutable StackEntries(matchedEntriesWithoutKind.start, nEntries));
					}
					generateExpr(tempAlloc, writer, ctx, case_.then);
					mustDelete(ctx.localEntries, force(case_.local));
					if (caseIndex != size(it.cases) - 1) {
						setNextStackEntry(writer, stackAfterMatched);
						return some(writeJumpDelayed(writer));
					} else
						// For the last one, don't reset the stack as by the end one of the cases will have run.
						// Last one doesn't need a jump, just continues straight into the code after it.
						return none!ByteCodeIndex;
				});
			foreach (immutable ByteCodeIndex jumpIndex; range(delayedGotos))
				fillInJumpDelayed(writer, jumpIndex);
			writeRemove(writer, matchedEntriesWithoutKind);
		},
		(ref immutable LowExprKind.ParamRef it) {
			writeGet(writer, at(ctx.parameterEntries, it.index.index));
		},
		(ref immutable LowExprKind.PtrCast) {
			// Do nothing
		},
		(ref immutable LowExprKind.RecordFieldAccess) {
			todo!void("field-access");
		},
		(ref immutable LowExprKind.RecordFieldSet) {
			todo!void("field-set");
		},
		(ref immutable LowExprKind.Seq it) {
			generateExpr(tempAlloc, writer, ctx, it.first);
			generateExpr(tempAlloc, writer, ctx, it.then);
		},
		(ref immutable LowExprKind.SizeOf) {
			todo!void("size-of");
		},
		(ref immutable LowExprKind.SpecialConstant) {
			todo!void("special-constant");
		},
		(ref immutable LowExprKind.Special0Ary) {
			todo!void("special-0ary");
		},
		(ref immutable LowExprKind.SpecialUnary) {
			todo!void("unary");
		},
		(ref immutable LowExprKind.SpecialBinary) {
			// Remember to treat 'or' and 'and' specially
			todo!void("binary");
		},
		(ref immutable LowExprKind.SpecialTrinary) {
			//Remember to treat 'if' specially
			todo!void("trinary");
		},
		(ref immutable LowExprKind.SpecialNAry) {
			todo!void("nary");
		},
		(ref immutable LowExprKind.StringLiteral) {
			todo!void("literal");
		});
}

void registerFunAddress(TempAlloc)(
	ref TempAlloc tempAlloc,
	ref ExprCtx ctx,
	immutable LowFunIndex fun,
	immutable ByteCodeIndex index,
) {
	mutIndexMultiDictAdd(tempAlloc, ctx.funToReferences, fun, index);
}
