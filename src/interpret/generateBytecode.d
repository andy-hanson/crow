module interpret.generateBytecode;

@safe @nogc pure nothrow:

import concreteModel : ConcreteFun, ConcreteFunSource, matchConcreteFunSource;
import interpret.bytecode :
	addByteCodeIndex,
	ByteCode,
	ByteCodeIndex,
	ByteCodeOffset,
	ByteCodeSource,
	ExternOp,
	FileToFuns,
	FnOp,
	FunNameAndPos,
	stackEntrySize,
	subtractByteCodeIndex;
import interpret.bytecodeWriter :
	ByteCodeWriter,
	nextByteCodeIndex,
	fillDelayedCall,
	fillDelayedSwitchEntry,
	fillInJumpDelayed,
	finishByteCode,
	getNextStackEntry,
	newByteCodeWriter,
	setNextStackEntry,
	setStackEntryAfterParameters,
	StackEntries,
	StackEntry,
	writeAddConstantNat64,
	writeAssertStackSize,
	writeCallDelayed,
	writeCallFunPtr,
	writeDupEntries,
	writeDupEntry,
	writeDupPartial,
	writeExtern,
	writeFn,
	writeFnHardFail,
	writePushConstant,
	writePushConstantStr,
	writePushEmptySpace,
	writePushFunPtrDelayed,
	writeJumpDelayed,
	writePack,
	writeStackRef,
	writeRead,
	writeRemove,
	writeReturn,
	writeSwitchDelay,
	writeWrite;
import lower.lowExprHelpers : genBool;
import lowModel :
	asConcreteFun,
	asLocalRef,
	asParamRef,
	asRecordFieldAccess,
	asRecordType,
	isLocalRef,
	isParamRef,
	isRecordFieldAccess,
	LowExpr,
	LowExprKind,
	LowField,
	LowFun,
	LowFunBody,
	LowFunExprBody,
	lowFunRange,
	LowFunSource,
	LowFunIndex,
	LowLocal,
	LowParam,
	LowProgram,
	LowRecord,
	LowType,
	LowUnion,
	matchLowExprKind,
	matchLowFunBody,
	matchLowFunSource,
	matchLowType,
	matchSpecialConstant,
	PrimitiveType;
import model : decl, FunDecl, FunInst, Module, name, Program, range;
import util.alloc.stackAlloc : StackAlloc;
import util.bools : Bool, False, True;
import util.collection.arr : Arr, at, range, size;
import util.collection.arrUtil : arrMax, eachWithIndex, map, mapOpWithIndex, slice, sum, zip;
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
	mutIndexMultiDictSize,
	newMutIndexMultiDict;
import util.collection.str : strEqLiteral;
import util.comparison : Comparison;
import util.opt : force, has, none, Opt, some;
import util.ptr : comparePtr, Ptr, ptrTrustMe, ptrTrustMe_mut;
import util.sourceRange : FileAndRange, FileIndex;
import util.types : Nat8, Nat16, Nat32, Nat64, safeSizeTToU8, safeU32ToU8, u8, u16, u32, zero;
import util.util : divRoundUp, roundUp, todo, verify;

immutable(ByteCode) generateBytecode(CodeAlloc)(
	ref CodeAlloc codeAlloc,
	ref immutable Program modelProgram,
	ref immutable LowProgram program,
) {
	alias TempAlloc = StackAlloc!("generateBytecode", 1024 * 1024);
	TempAlloc tempAlloc;

	immutable TypeLayout typeLayout = layOutTypes(tempAlloc, program);

	MutIndexMultiDict!(LowFunIndex, ByteCodeIndex) funToReferences =
		newMutIndexMultiDict!(LowFunIndex, ByteCodeIndex)(tempAlloc, fullIndexDictSize(program.allFuns));

	ByteCodeWriter!CodeAlloc writer = newByteCodeWriter(ptrTrustMe_mut(codeAlloc));

	immutable FullIndexDict!(LowFunIndex, ByteCodeIndex) funToDefinition =
		mapFullIndexDict!(LowFunIndex, ByteCodeIndex, LowFun, TempAlloc)(
			tempAlloc,
			program.allFuns,
			(immutable LowFunIndex funIndex, ref immutable LowFun fun) {
				immutable ByteCodeIndex funPos = nextByteCodeIndex(writer);
				generateBytecodeForFun(tempAlloc, writer, funToReferences, typeLayout, program, funIndex, fun);
				return funPos;
		});

	fullIndexDictEach(funToDefinition, (immutable LowFunIndex index, ref immutable ByteCodeIndex definition) {
		foreach (immutable ByteCodeIndex reference; range(mutIndexMultiDictMustGetAt(funToReferences, index)))
			fillDelayedCall(writer, reference, definition);
	});

	return finishByteCode(writer, fullIndexDictGet(funToDefinition, program.main), fileToFuns(codeAlloc, modelProgram));
}

private:

import util.collection.mutIndexMultiDict : MutIndexMultiDict;

immutable(FileToFuns) fileToFuns(Alloc)(ref Alloc alloc, ref immutable Program program) {
	immutable FullIndexDict!(FileIndex, Ptr!Module) modulesDict =
		fullIndexDictOfArr!(FileIndex, Ptr!Module)(program.allModules);
	return mapFullIndexDict!(FileIndex, Arr!FunNameAndPos, Ptr!Module, Alloc)(
		alloc,
		modulesDict,
		(immutable FileIndex, ref immutable Ptr!Module module_) =>
			map(alloc, module_.funs, (ref immutable FunDecl it) =>
				immutable FunNameAndPos(name(it), range(it).range.start)));
}

// NOTE: we should lay out structs so that no primitive field straddles multiple stack entries.
struct TypeLayout {
	// All in bytes
	immutable FullIndexDict!(LowType.Record, Nat8) recordSizes;
	immutable FullIndexDict!(LowType.Record, Arr!Nat8) fieldOffsets;
	immutable FullIndexDict!(LowType.Union, Nat8) unionSizes;
}

struct TypeLayoutBuilder {
	FullIndexDictBuilder!(LowType.Record, Nat8) recordSizes;
	FullIndexDictBuilder!(LowType.Record, Arr!Nat8) recordFieldOffsets;
	FullIndexDictBuilder!(LowType.Union, Nat8) unionSizes;
}

immutable(TypeLayout) layOutTypes(Alloc)(ref Alloc alloc, ref immutable LowProgram program) {
	TypeLayoutBuilder builder = TypeLayoutBuilder(
		newFullIndexDictBuilder!(LowType.Record, Nat8)(alloc, fullIndexDictSize(program.allRecords)),
		newFullIndexDictBuilder!(LowType.Record, Arr!Nat8)(alloc, fullIndexDictSize(program.allRecords)),
		newFullIndexDictBuilder!(LowType.Union, Nat8)(alloc, fullIndexDictSize(program.allUnions)));
	fullIndexDictEach(program.allRecords, (immutable LowType.Record index, ref immutable LowRecord record) {
		if (!fullIndexDictBuilderHas(builder.recordSizes, index))
			fillRecordSize!Alloc(alloc, program, index, record, builder);
	});
	fullIndexDictEach(program.allUnions, (immutable LowType.Union index, ref immutable LowUnion union_) {
		if (!fullIndexDictBuilderHas(builder.unionSizes, index))
			fillUnionSize!Alloc(alloc, program, index, union_, builder);
	});
	return immutable TypeLayout(
		finishFullIndexDict(builder.recordSizes),
		finishFullIndexDict(builder.recordFieldOffsets),
		finishFullIndexDict(builder.unionSizes));
}

immutable Nat8 fieldBoundary = immutable Nat8(8);

immutable(Nat8) fillRecordSize(Alloc)(
	ref Alloc alloc,
	ref immutable LowProgram program,
	immutable LowType.Record index,
	ref immutable LowRecord record,
	ref TypeLayoutBuilder builder,
) {
	Nat8 offset = immutable Nat8(0);
	immutable Arr!Nat8 fieldOffsets = map(alloc, record.fields, (ref immutable LowField field) {
		immutable Nat8 fieldSize = sizeOfType(alloc, program, field.type, builder);
		// If field would stretch across a boundary, move offset up to the next boundary
		immutable Nat8 mod = offset % fieldBoundary;
		if (!zero(mod) && mod + fieldSize > fieldBoundary) {
			offset = roundUp(offset, fieldBoundary);
		}
		immutable Nat8 res = offset;
		offset += fieldSize;
		return res;
	});
	immutable Nat8 size = offset <= immutable Nat8(8) ? offset : roundUp(offset, immutable Nat8(8));
	fullIndexDictBuilderAdd(builder.recordSizes, index, size);
	fullIndexDictBuilderAdd(builder.recordFieldOffsets, index, fieldOffsets);
	return size;
}

immutable(Nat8) fillUnionSize(Alloc)(
	ref Alloc alloc,
	ref immutable LowProgram program,
	immutable LowType.Union index,
	ref immutable LowUnion union_,
	ref TypeLayoutBuilder builder,
) {
	immutable Nat8 maxMemberSize = arrMax(immutable Nat8(0), union_.members, (ref immutable LowType t) =>
		sizeOfType(alloc, program, t, builder));
	immutable Nat8 size = unionKindSize + maxMemberSize;
	fullIndexDictBuilderAdd(builder.unionSizes, index, size);
	return size;
}

immutable Nat8 externPtrSize = immutable Nat8((void*).sizeof);
immutable Nat8 ptrSize = immutable Nat8((void*).sizeof);
immutable Nat8 funPtrSize = immutable Nat8(4);
immutable Nat8 unionKindSize = immutable Nat8(8);

immutable(Nat8) sizeOfType(Alloc)(
	ref Alloc alloc,
	ref immutable LowProgram program,
	ref immutable LowType t,
	ref TypeLayoutBuilder builder,
) {
	return matchLowType!(immutable Nat8)(
		t,
		(immutable LowType.ExternPtr) =>
			externPtrSize,
		(immutable LowType.FunPtr) =>
			funPtrSize,
		(immutable LowType.NonFunPtr) =>
			ptrSize,
		(immutable PrimitiveType it) =>
			primitiveSize(it),
		(immutable LowType.Record index) {
			immutable Opt!Nat8 size = fullIndexDictBuilderOptGet(builder.recordSizes, index);
			return has(size)
				? force(size)
				: fillRecordSize(alloc, program, index, fullIndexDictGet(program.allRecords, index), builder);
		},
		(immutable LowType.Union index) {
			immutable Opt!Nat8 size = fullIndexDictBuilderOptGet(builder.unionSizes, index);
			return has(size)
				? force(size)
				: fillUnionSize(alloc, program, index, fullIndexDictGet(program.allUnions, index), builder);
		});
}

immutable(Nat8) sizeOfType(ref const ExprCtx ctx, ref immutable LowType t) {
	return sizeOfType(ctx.typeLayout, t);
}

immutable(Nat8) sizeOfType(ref immutable TypeLayout typeLayout, ref immutable LowType t) {
	return matchLowType!(immutable Nat8)(
		t,
		(immutable LowType.ExternPtr) =>
			externPtrSize,
		(immutable LowType.FunPtr) =>
			funPtrSize,
		(immutable LowType.NonFunPtr) =>
			ptrSize,
		(immutable PrimitiveType it) =>
			primitiveSize(it),
		(immutable LowType.Record index) =>
			fullIndexDictGet(typeLayout.recordSizes, index),
		(immutable LowType.Union index) =>
			fullIndexDictGet(typeLayout.unionSizes, index));
}

immutable(Nat8) primitiveSize(immutable PrimitiveType a) {
	final switch (a) {
		case PrimitiveType.void_:
			return immutable Nat8(0);
		case PrimitiveType.bool_:
		case PrimitiveType.char_:
		case PrimitiveType.int8:
		case PrimitiveType.nat8:
			return immutable Nat8(1);
		case PrimitiveType.int16:
		case PrimitiveType.nat16:
			return immutable Nat8(2);
		case PrimitiveType.int32:
		case PrimitiveType.nat32:
			return immutable Nat8(4);
		case PrimitiveType.float64:
		case PrimitiveType.int64:
		case PrimitiveType.nat64:
			return immutable Nat8(8);
	}
}

immutable(Nat8) nStackEntriesForType(ref const ExprCtx ctx, ref immutable LowType t) {
	return nStackEntriesForType(ctx.typeLayout, t);
}

immutable(Nat8) nStackEntriesForType(ref immutable TypeLayout typeLayout, ref immutable LowType t) {
	return divRoundUp(sizeOfType(typeLayout, t), stackEntrySize);
}

void generateBytecodeForFun(TempAlloc, CodeAlloc)(
	ref TempAlloc tempAlloc,
	ref ByteCodeWriter!CodeAlloc writer,
	ref MutIndexMultiDict!(LowFunIndex, ByteCodeIndex) funToReferences,
	ref immutable TypeLayout typeLayout,
	ref immutable LowProgram program,
	immutable LowFunIndex funIndex,
	ref immutable LowFun fun,
) {
	matchLowFunBody!void(
		fun.body_,
		(ref immutable LowFunBody.Extern body_) {
			generateExternCall(tempAlloc, writer, funIndex, fun, body_);
		},
		(ref immutable LowFunExprBody body_) {
			Nat16 stackEntry = Nat16(0);
			immutable Arr!StackEntries parameters = map!StackEntries(
				tempAlloc,
				fun.params,
				(ref immutable LowParam it) {
					immutable StackEntry start = immutable StackEntry(stackEntry);
					immutable Nat8 n = nStackEntriesForType(typeLayout, it.type);
					stackEntry += n.to16();
					return immutable StackEntries(start, n);
				});
			immutable StackEntry stackEntryAfterParameters = immutable StackEntry(stackEntry);
			setStackEntryAfterParameters(writer, stackEntryAfterParameters);
			// Note: not doing it for locals because they might be unrelated and occupy the same stack entry
			ExprCtx ctx = ExprCtx(
				ptrTrustMe(program),
				ptrTrustMe(typeLayout),
				funIndex,
				ptrTrustMe_mut(funToReferences),
				parameters);
			generateExpr(tempAlloc, writer, ctx, body_.expr);

			immutable Nat8 returnEntries = nStackEntriesForType(typeLayout, fun.returnType);
			verify(stackEntryAfterParameters.entry + returnEntries.to16() == getNextStackEntry(writer).entry);
			immutable ByteCodeSource source = immutable ByteCodeSource(funIndex, lowFunRange(fun).range.start);
			writeRemove(
				writer,
				source,
				immutable StackEntries(
					immutable StackEntry(immutable Nat16(0)),
					stackEntryAfterParameters.entry.to8()));
			verify(getNextStackEntry(writer).entry == returnEntries.to16());
			writeReturn(writer, source);

			setNextStackEntry(writer, immutable StackEntry(immutable Nat16(0)));
		});
}

void generateExternCall(TempAlloc, CodeAlloc)(
	ref TempAlloc tempAlloc,
	ref ByteCodeWriter!CodeAlloc writer,
	immutable LowFunIndex funIndex,
	ref immutable LowFun fun,
	ref immutable LowFunBody.Extern a,
) {
	immutable ByteCodeSource source = immutable ByteCodeSource(funIndex, lowFunRange(fun).range.start);
	if (strEqLiteral(a.externName, "free"))
		writeExtern(writer, source, ExternOp.free);
	else if (strEqLiteral(a.externName, "malloc"))
		writeExtern(writer, source, ExternOp.malloc);
	else if (strEqLiteral(a.externName, "write"))
		writeExtern(writer, source, ExternOp.write);
	else {
		debug {
			import core.stdc.stdio : printf;
			import util.alloc.stackAlloc : StackAlloc;
			import util.sym : Sym, symToCStr;
			import util.util : unreachable;

			immutable Sym name = matchLowFunSource(
				fun.source,
				(immutable Ptr!ConcreteFun cf) =>
					matchConcreteFunSource(
						cf.source,
						(immutable Ptr!FunInst it) =>
							name(it),
						(ref immutable ConcreteFunSource.Lambda) =>
							unreachable!(immutable Sym)()),
				(ref immutable LowFunSource.Generated) =>
					unreachable!(immutable Sym)());
			StackAlloc!("debug", 1024) alloc;
			printf("Unhandled extern function %s\n", symToCStr(alloc, name));
		}
		todo!void("unhandled extern function");
	}
	writeReturn(writer, source);
}


struct ExprCtx {
	immutable Ptr!LowProgram program;
	immutable Ptr!TypeLayout typeLayout;
	immutable LowFunIndex curFunIndex;
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
	immutable ByteCodeSource source = immutable ByteCodeSource(ctx.curFunIndex, expr.source.range.start);
	writeAssertStackSize(writer, source);
	return matchLowExprKind(
		expr.kind,
		(ref immutable LowExprKind.Call it) {
			immutable StackEntry stackEntryBeforeArgs = getNextStackEntry(writer);
			immutable Nat8 expectedStackEffect = nStackEntriesForType(ctx, expr.type);
			foreach (ref immutable LowExpr arg; range(it.args))
				generateExpr(tempAlloc, writer, ctx, arg);
			registerFunAddress(tempAlloc, ctx, it.called,
				writeCallDelayed(writer, source, stackEntryBeforeArgs, expectedStackEffect));
			verify(stackEntryBeforeArgs.entry + expectedStackEffect.to16() == getNextStackEntry(writer).entry);
		},
		(ref immutable LowExprKind.CreateRecord it) {
			immutable StackEntry before = getNextStackEntry(writer);

			void maybePack(immutable Opt!size_t packStart, immutable size_t packEnd) {
				if (has(packStart)) {
					// Need to give the instruction the field sizes
					immutable Arr!Nat8 fieldSizes = map!Nat8(
						tempAlloc,
						slice(it.args, force(packStart), packEnd - force(packStart)),
						(ref immutable LowExpr arg) => sizeOfType(ctx, arg.type));
					writePack(writer, source, fieldSizes);
				}
			}

			void recur(immutable Opt!size_t packStart, immutable size_t fieldIndex) {
				if (fieldIndex == size(it.args)) {
					maybePack(packStart, fieldIndex);
				} else {
					immutable Nat8 fieldSize = sizeOfType(ctx, at(it.args, fieldIndex).type);
					if (fieldSize < immutable Nat8(8)) {
						generateExpr(tempAlloc, writer, ctx, at(it.args, fieldIndex));
						recur(has(packStart) ? packStart : some(fieldIndex), fieldIndex + 1);
					} else {
						verify(fieldSize % immutable Nat8(8) == immutable Nat8(0));
						maybePack(packStart, fieldIndex);
						generateExpr(tempAlloc, writer, ctx, at(it.args, fieldIndex));
						recur(none!size_t, fieldIndex + 1);
					}
				}
			}

			recur(none!size_t, 0);

			immutable StackEntry after = getNextStackEntry(writer);
			immutable Nat8 stackEntriesForType = nStackEntriesForType(ctx, expr.type);
			verify(after.entry - before.entry == stackEntriesForType.to16());
		},
		(ref immutable LowExprKind.ConvertToUnion it) {
			//immutable uint offset = nStackEntriesForUnionTypeExcludingKind(ctx.program, asUnionType(it.type));
			immutable StackEntry before = getNextStackEntry(writer);
			immutable Nat8 size = nStackEntriesForType(ctx, expr.type);
			writePushConstant(writer, source, immutable Nat8(it.memberIndex));
			generateExpr(tempAlloc, writer, ctx, it.arg);
			immutable StackEntry after = getNextStackEntry(writer);
			if (before.entry + size.to16() != after.entry) {
				// Some members of a union are smaller than the union.
				verify(before.entry + size.to16() > after.entry);
				writePushEmptySpace(writer, source, before.entry + size.to16() - after.entry);
			}
		},
		(ref immutable LowExprKind.FunPtr it) {
			registerFunAddress(tempAlloc, ctx, it.fun,
				writePushFunPtrDelayed(writer, source));
		},
		(ref immutable LowExprKind.Let it) {
			immutable StackEntries localEntries =
				immutable StackEntries(getNextStackEntry(writer), nStackEntriesForType(ctx, it.local.type));
			generateExpr(tempAlloc, writer, ctx, it.value);
			verify(getNextStackEntry(writer).entry == localEntries.start.entry + localEntries.size.to16());
			addToMutDict(tempAlloc, ctx.localEntries, it.local, localEntries);
			generateExpr(tempAlloc, writer, ctx, it.then);
			mustDelete(ctx.localEntries, it.local);
			writeRemove(writer, source, localEntries);
		},
		(ref immutable LowExprKind.LocalRef it) {
			writeDupEntries(writer, source, mustGetAt_mut(ctx.localEntries, it.local));
		},
		(ref immutable LowExprKind.Match it) {
			immutable StackEntry startStack = getNextStackEntry(writer);
			generateExpr(tempAlloc, writer, ctx, it.matchedValue);
			// Move the union kind to top of stack
			writeDupEntry(writer, source, startStack);
			writeRemove(writer, source, immutable StackEntries(startStack, immutable Nat8(1)));
			// Get the kind (always the first entry)
			immutable ByteCodeIndex indexOfFirstCaseOffset = writeSwitchDelay(writer, source, size(it.cases));
			// Start of the union values is where the kind used to be.
			immutable StackEntry stackAfterMatched = getNextStackEntry(writer);
			immutable StackEntries matchedEntriesWithoutKind =
				immutable StackEntries(startStack, (stackAfterMatched.entry - startStack.entry).to8());
			immutable Arr!ByteCodeIndex delayedGotos = mapOpWithIndex!ByteCodeIndex(
				tempAlloc,
				it.cases,
				(immutable size_t caseIndex, ref immutable LowExprKind.Match.Case case_) {
					fillDelayedSwitchEntry(writer, indexOfFirstCaseOffset, immutable Nat8(safeSizeTToU8(caseIndex)));
					nextByteCodeIndex(writer);
					if (has(case_.local)) {
						immutable Nat8 nEntries = nStackEntriesForType(ctx, force(case_.local).type);
						verify(nEntries <= matchedEntriesWithoutKind.size);
						addToMutDict(
							tempAlloc,
							ctx.localEntries,
							force(case_.local),
							immutable StackEntries(matchedEntriesWithoutKind.start, nEntries));
					}
					generateExpr(tempAlloc, writer, ctx, case_.then);
					if (has(case_.local))
						mustDelete(ctx.localEntries, force(case_.local));
					if (caseIndex != size(it.cases) - 1) {
						setNextStackEntry(writer, stackAfterMatched);
						return some(writeJumpDelayed(writer, source));
					} else
						// For the last one, don't reset the stack as by the end one of the cases will have run.
						// Last one doesn't need a jump, just continues straight into the code after it.
						return none!ByteCodeIndex;
				});
			foreach (immutable ByteCodeIndex jumpIndex; range(delayedGotos))
				fillInJumpDelayed(writer, jumpIndex);
			writeRemove(writer, source, matchedEntriesWithoutKind);
		},
		(ref immutable LowExprKind.ParamRef it) {
			writeDupEntries(writer, source, at(ctx.parameterEntries, it.index.index));
		},
		(ref immutable LowExprKind.PtrCast it) {
			generateExpr(tempAlloc, writer, ctx, it.target);
		},
		(ref immutable LowExprKind.RecordFieldAccess it) {
			generateRecordFieldAccess(tempAlloc, writer, ctx, source, it);
		},
		(ref immutable LowExprKind.RecordFieldSet it) {
			immutable StackEntry before = getNextStackEntry(writer);
			verify(it.targetIsPointer);
			generateExpr(tempAlloc, writer, ctx, it.target);
			immutable StackEntry mid = getNextStackEntry(writer);
			generateExpr(tempAlloc, writer, ctx, it.value);
			immutable FieldOffsetAndSize offsetAndSize =
				getFieldOffsetAndSize(ctx, it.record, immutable Nat8(it.fieldIndex));
			verify(
				mid.entry + divRoundUp(offsetAndSize.size, stackEntrySize).to16() ==
					getNextStackEntry(writer).entry);
			writeWrite(writer, source, offsetAndSize.offset, offsetAndSize.size);
			verify(getNextStackEntry(writer) == before);
		},
		(ref immutable LowExprKind.Seq it) {
			generateExpr(tempAlloc, writer, ctx, it.first);
			generateExpr(tempAlloc, writer, ctx, it.then);
		},
		(ref immutable LowExprKind.SizeOf it) {
			writePushConstant(writer, source, sizeOfType(ctx, it.type));
		},
		(ref immutable LowExprKind.SpecialConstant it) {
			generateSpecialConstant(writer, source, it);
		},
		(ref immutable LowExprKind.Special0Ary it) {
			generateSpecial0Ary(writer, source, it);
		},
		(ref immutable LowExprKind.SpecialUnary it) {
			generateSpecialUnary(tempAlloc, writer, ctx, source, expr.type, it);
		},
		(ref immutable LowExprKind.SpecialBinary it) {
			generateSpecialBinary(tempAlloc, writer, ctx, source, it);
		},
		(ref immutable LowExprKind.SpecialTrinary it) {
			generateSpecialTrinary(tempAlloc, writer, ctx, source, it);
		},
		(ref immutable LowExprKind.SpecialNAry it) {
			generateSpecialNAry(tempAlloc, writer, ctx, source, expr.type, it);
		});
}

struct FieldOffsetAndSize {
	immutable Nat8 offset;
	immutable Nat8 size;
}

immutable(Nat8) getFieldOffset(ref const ExprCtx ctx, immutable LowType.Record record, immutable Nat8 fieldIndex) {
	immutable Arr!Nat8 fieldOffsets = fullIndexDictGet(ctx.typeLayout.fieldOffsets, record);
	return at(fieldOffsets, fieldIndex);
}

immutable(FieldOffsetAndSize) getFieldOffsetAndSize(
	ref const ExprCtx ctx,
	immutable LowType.Record record,
	immutable Nat8 fieldIndex,
) {
	immutable Nat8 size = sizeOfType(ctx, at(fullIndexDictGet(ctx.program.allRecords, record).fields, fieldIndex).type);
	return immutable FieldOffsetAndSize(getFieldOffset(ctx, record, fieldIndex), size);
}

void registerFunAddress(TempAlloc)(
	ref TempAlloc tempAlloc,
	ref ExprCtx ctx,
	immutable LowFunIndex fun,
	immutable ByteCodeIndex index,
) {
	mutIndexMultiDictAdd(tempAlloc, ctx.funToReferences, fun, index);
}

void generateSpecialConstant(CodeAlloc)(
	ref ByteCodeWriter!CodeAlloc writer,
	ref immutable ByteCodeSource source,
	ref immutable LowExprKind.SpecialConstant constant,
) {
	matchSpecialConstant(
		constant,
		(immutable LowExprKind.SpecialConstant.BoolConstant it) {
			writeBoolConstant(writer, source, it.value);
		},
		(immutable LowExprKind.SpecialConstant.Integral it) {
			writePushConstant(writer, source, immutable Nat64(it.value));
		},
		(immutable LowExprKind.SpecialConstant.Null) {
			writePushConstant(writer, source, immutable Nat8(0));
		},
		(immutable LowExprKind.SpecialConstant.StrConstant it) {
			writePushConstantStr(writer, source, it.value);
		},
		(immutable LowExprKind.SpecialConstant.Void) {
			// do nothing
		});
}

void writeBoolConstant(CodeAlloc)(
	ref ByteCodeWriter!CodeAlloc writer,
	ref immutable ByteCodeSource source,
	immutable Bool value,
) {
	writePushConstant(writer, source, immutable Nat8(value ? 1 : 0));
}

void generateSpecial0Ary(CodeAlloc)(
	ref ByteCodeWriter!CodeAlloc writer,
	ref immutable ByteCodeSource source,
	ref immutable LowExprKind.Special0Ary it,
) {
	final switch (it.kind) {
		case LowExprKind.Special0Ary.Kind.getErrno:
			todo!void("generate getErrno");
	}
}

void generateSpecialUnary(CodeAlloc, TempAlloc)(
	ref TempAlloc tempAlloc,
	ref ByteCodeWriter!CodeAlloc writer,
	ref ExprCtx ctx,
	ref immutable ByteCodeSource source,
	ref immutable LowType type,
	ref immutable LowExprKind.SpecialUnary a,
) {
	void generateArg() {
		generateExpr(tempAlloc, writer, ctx, a.arg);
	}

	void fn(immutable FnOp fnOp) {
		generateArg();
		writeFn(writer, source, fnOp);
	}

	final switch (a.kind) {
		case LowExprKind.SpecialUnary.Kind.asAnyPtr:
		case LowExprKind.SpecialUnary.Kind.asRef:
		case LowExprKind.SpecialUnary.Kind.toNatFromPtr:
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

		case LowExprKind.SpecialUnary.Kind.toIntFromInt16:
			fn(FnOp.intFromInt16);
			break;
		case LowExprKind.SpecialUnary.Kind.toIntFromInt32:
			fn(FnOp.intFromInt32);
			break;
		// Normal operations on <64-bit values treat other bits as garbage
		// (they may be written to, such as in a wrap-add operation that overflows)
		// So we must mask out just the lower bits now.
		case LowExprKind.SpecialUnary.Kind.toNatFromNat8:
			generateArg();
			writePushConstant(writer, source, Nat8.max);
			writeFn(writer, source, FnOp.bitwiseAnd);
			break;
		case LowExprKind.SpecialUnary.Kind.toNatFromNat16:
			generateArg();
			writePushConstant(writer, source, Nat16.max);
			writeFn(writer, source, FnOp.bitwiseAnd);
			break;
		case LowExprKind.SpecialUnary.Kind.toNatFromNat32:
			generateArg();
			writePushConstant(writer, source, Nat32.max);
			writeFn(writer, source, FnOp.bitwiseAnd);
			break;
		case LowExprKind.SpecialUnary.Kind.deref:
			generateArg();
			writeRead(writer, source, immutable Nat8(0), sizeOfType(ctx, type));
			break;
		case LowExprKind.SpecialUnary.Kind.hardFail:
			generateArg();
			writeFnHardFail(writer, source, nStackEntriesForType(ctx, type));
			break;
		case LowExprKind.SpecialUnary.Kind.not:
			fn(FnOp.not);
			break;
		case LowExprKind.SpecialUnary.Kind.ptrTo:
		case LowExprKind.SpecialUnary.Kind.refOfVal:
			generateRefOfVal(tempAlloc, writer, ctx, source, a.arg);
			break;
		case LowExprKind.SpecialUnary.Kind.toFloat64FromInt64: // FnOp.float64FromInt64
			fn(FnOp.float64FromInt64);
			break;
		case LowExprKind.SpecialUnary.Kind.toFloat64FromNat64:
			fn(FnOp.float64FromNat64);
			break;
		case LowExprKind.SpecialUnary.Kind.truncateToInt64FromFloat64:
			fn(FnOp.truncateToInt64FromFloat64);
			break;
	}
}

void generateRefOfVal(TempAlloc, CodeAlloc)(
	ref TempAlloc tempAlloc,
	ref ByteCodeWriter!CodeAlloc writer,
	ref ExprCtx ctx,
	ref immutable ByteCodeSource source,
	ref immutable LowExpr arg,
) {
	if (isLocalRef(arg.kind))
		writeStackRef(writer, source, mustGetAt_mut(ctx.localEntries, asLocalRef(arg.kind).local).start);
	else if (isParamRef(arg.kind))
		writeStackRef(writer, source, at(ctx.parameterEntries, asParamRef(arg.kind).index.index).start);
	else if (isRecordFieldAccess(arg.kind))
		generatePtrToRecordFieldAccess(tempAlloc, writer, ctx, source, asRecordFieldAccess(arg.kind));
	else {
		todo!void("ref-of-val -- not a local or record field");
	}
}

void generateRecordFieldAccess(TempAlloc, CodeAlloc)(
	ref TempAlloc tempAlloc,
	ref ByteCodeWriter!CodeAlloc writer,
	ref ExprCtx ctx,
	ref immutable ByteCodeSource source,
	ref immutable LowExprKind.RecordFieldAccess it,
) {
	immutable StackEntry targetEntry = getNextStackEntry(writer);
	generateExpr(tempAlloc, writer, ctx, it.target);
	immutable StackEntries targetEntries = immutable StackEntries(
		targetEntry,
		(getNextStackEntry(writer).entry - targetEntry.entry).to8());
	immutable FieldOffsetAndSize offsetAndSize = getFieldOffsetAndSize(ctx, it.record, immutable Nat8(it.fieldIndex));
	if (it.targetIsPointer) {
		writeRead(writer, source, offsetAndSize.offset, offsetAndSize.size);
	} else {
		immutable StackEntry firstEntry =
			immutable StackEntry(targetEntry.entry + (offsetAndSize.offset / stackEntrySize).to16());
		if (zero(offsetAndSize.size % stackEntrySize)) {
			verify(zero(offsetAndSize.offset % stackEntrySize));
			immutable StackEntries entries = immutable StackEntries(firstEntry, offsetAndSize.size / stackEntrySize);
			writeDupEntries(writer, source, entries);
		} else {
			writeDupPartial(
				writer,
				source,
				firstEntry,
				offsetAndSize.offset % stackEntrySize,
				offsetAndSize.size);
		}
		writeRemove(writer, source, targetEntries);
	}
}

void generatePtrToRecordFieldAccess(TempAlloc, CodeAlloc)(
	ref TempAlloc tempAlloc,
	ref ByteCodeWriter!CodeAlloc writer,
	ref ExprCtx ctx,
	ref immutable ByteCodeSource source,
	ref immutable LowExprKind.RecordFieldAccess it,
) {
	generateExpr(tempAlloc, writer, ctx, it.target);
	immutable Nat8 offset = getFieldOffset(ctx, it.record, immutable Nat8(it.fieldIndex));
	if (it.targetIsPointer) {
		if (!zero(offset))
			writeAddConstantNat64(writer, source, offset.to64());
	} else
		// This only works if it's a local .. or another recordfieldaccess
		todo!void("ptr-to-record-field-access");
}

void generateSpecialBinary(TempAlloc, CodeAlloc)(
	ref TempAlloc tempAlloc,
	ref ByteCodeWriter!CodeAlloc writer,
	ref ExprCtx ctx,
	ref immutable ByteCodeSource source,
	ref immutable LowExprKind.SpecialBinary a,
) {
	void fn(immutable FnOp fn) {
		generateExpr(tempAlloc, writer, ctx, a.left);
		generateExpr(tempAlloc, writer, ctx, a.right);
		writeFn(writer, source, fn);
	}

	final switch (a.kind) {
		case LowExprKind.SpecialBinary.Kind.addFloat64:
			fn(FnOp.addFloat64);
			break;
		case LowExprKind.SpecialBinary.Kind.addPtr:
			fn(FnOp.wrapAddIntegral);
			break;
		case LowExprKind.SpecialBinary.Kind.and:
			generateIf(
				tempAlloc,
				writer,
				ctx,
				source,
				a.left,
				() {
					generateExpr(tempAlloc, writer, ctx, a.right);
				},
				() {
					writeBoolConstant(writer, source, False);
				});
			break;
		case LowExprKind.SpecialBinary.Kind.unsafeBitShiftLeftNat64:
			fn(FnOp.unsafeBitShiftLeftNat64);
			break;
		case LowExprKind.SpecialBinary.Kind.unsafeBitShiftRightNat64:
			fn(FnOp.unsafeBitShiftRightNat64);
			break;
		case LowExprKind.SpecialBinary.Kind.bitwiseAndInt8:
		case LowExprKind.SpecialBinary.Kind.bitwiseAndInt16:
		case LowExprKind.SpecialBinary.Kind.bitwiseAndInt32:
		case LowExprKind.SpecialBinary.Kind.bitwiseAndInt64:
		case LowExprKind.SpecialBinary.Kind.bitwiseAndNat8:
		case LowExprKind.SpecialBinary.Kind.bitwiseAndNat16:
		case LowExprKind.SpecialBinary.Kind.bitwiseAndNat32:
		case LowExprKind.SpecialBinary.Kind.bitwiseAndNat64:
			fn(FnOp.bitwiseAnd);
			break;
		case LowExprKind.SpecialBinary.Kind.bitwiseOrInt8:
		case LowExprKind.SpecialBinary.Kind.bitwiseOrInt16:
		case LowExprKind.SpecialBinary.Kind.bitwiseOrInt32:
		case LowExprKind.SpecialBinary.Kind.bitwiseOrInt64:
		case LowExprKind.SpecialBinary.Kind.bitwiseOrNat8:
		case LowExprKind.SpecialBinary.Kind.bitwiseOrNat16:
		case LowExprKind.SpecialBinary.Kind.bitwiseOrNat32:
		case LowExprKind.SpecialBinary.Kind.bitwiseOrNat64:
			fn(FnOp.bitwiseOr);
			break;
		case LowExprKind.SpecialBinary.Kind.eqNat64:
		case LowExprKind.SpecialBinary.Kind.eqPtr:
			fn(FnOp.eqBits);
			break;
		case LowExprKind.SpecialBinary.Kind.less: // TODO:KILL
		case LowExprKind.SpecialBinary.Kind.lessBool:
		case LowExprKind.SpecialBinary.Kind.lessChar:
		case LowExprKind.SpecialBinary.Kind.lessNat8:
		case LowExprKind.SpecialBinary.Kind.lessNat16:
		case LowExprKind.SpecialBinary.Kind.lessNat32:
		case LowExprKind.SpecialBinary.Kind.lessNat64:
			fn(FnOp.lessNat);
			break;
		case LowExprKind.SpecialBinary.Kind.lessFloat64:
			fn(FnOp.lessFloat64);
			break;
		case LowExprKind.SpecialBinary.Kind.lessInt8:
			fn(FnOp.lessInt8);
			break;
		case LowExprKind.SpecialBinary.Kind.lessInt16:
			fn(FnOp.lessInt16);
			break;
		case LowExprKind.SpecialBinary.Kind.lessInt32:
			fn(FnOp.lessInt32);
			break;
		case LowExprKind.SpecialBinary.Kind.lessInt64:
			fn(FnOp.lessInt64);
			break;
		case LowExprKind.SpecialBinary.Kind.mulFloat64:
			fn(FnOp.mulFloat64);
			break;
		case LowExprKind.SpecialBinary.Kind.or:
			generateIf(
				tempAlloc,
				writer,
				ctx,
				source,
				a.left,
				() {
					writeBoolConstant(writer, source, True);
				},
				() {
					generateExpr(tempAlloc, writer, ctx, a.right);
				});
			break;
		case LowExprKind.SpecialBinary.Kind.subFloat64:
			fn(FnOp.subFloat64);
			break;
		case LowExprKind.SpecialBinary.Kind.subPtrNat:
		case LowExprKind.SpecialBinary.Kind.wrapSubInt16:
		case LowExprKind.SpecialBinary.Kind.wrapSubInt32:
		case LowExprKind.SpecialBinary.Kind.wrapSubInt64:
		case LowExprKind.SpecialBinary.Kind.wrapSubNat8:
		case LowExprKind.SpecialBinary.Kind.wrapSubNat16:
		case LowExprKind.SpecialBinary.Kind.wrapSubNat32:
		case LowExprKind.SpecialBinary.Kind.wrapSubNat64:
			fn(FnOp.wrapSubIntegral);
			break;
		case LowExprKind.SpecialBinary.Kind.unsafeDivFloat64:
			fn(FnOp.unsafeDivFloat64);
			break;
		case LowExprKind.SpecialBinary.Kind.unsafeDivInt64:
			fn(FnOp.unsafeDivInt64);
			break;
		case LowExprKind.SpecialBinary.Kind.unsafeDivNat64:
			fn(FnOp.unsafeDivNat64);
			break;
		case LowExprKind.SpecialBinary.Kind.unsafeModNat64:
			fn(FnOp.unsafeModNat64);
			break;
		case LowExprKind.SpecialBinary.Kind.wrapAddInt16:
		case LowExprKind.SpecialBinary.Kind.wrapAddInt32:
		case LowExprKind.SpecialBinary.Kind.wrapAddInt64:
		case LowExprKind.SpecialBinary.Kind.wrapAddNat8:
		case LowExprKind.SpecialBinary.Kind.wrapAddNat16:
		case LowExprKind.SpecialBinary.Kind.wrapAddNat32:
		case LowExprKind.SpecialBinary.Kind.wrapAddNat64:
			fn(FnOp.wrapAddIntegral);
			break;
		case LowExprKind.SpecialBinary.Kind.wrapMulInt16:
		case LowExprKind.SpecialBinary.Kind.wrapMulInt32:
		case LowExprKind.SpecialBinary.Kind.wrapMulInt64:
		case LowExprKind.SpecialBinary.Kind.wrapMulNat16:
		case LowExprKind.SpecialBinary.Kind.wrapMulNat32:
		case LowExprKind.SpecialBinary.Kind.wrapMulNat64:
			fn(FnOp.wrapMulIntegral);
			break;
		case LowExprKind.SpecialBinary.Kind.writeToPtr:
			generateExpr(tempAlloc, writer, ctx, a.left);
			generateExpr(tempAlloc, writer, ctx, a.right);
			writeWrite(writer, source, immutable Nat8(0), sizeOfType(ctx, a.right.type));
			break;
	}
}

void generateSpecialTrinary(TempAlloc, CodeAlloc)(
	ref TempAlloc tempAlloc,
	ref ByteCodeWriter!CodeAlloc writer,
	ref ExprCtx ctx,
	ref immutable ByteCodeSource source,
	ref immutable LowExprKind.SpecialTrinary a,
) {
	final switch (a.kind) {
		case LowExprKind.SpecialTrinary.Kind.if_:
			generateIf(
				tempAlloc,
				writer,
				ctx,
				source,
				a.p0,
				() {
					generateExpr(tempAlloc, writer, ctx, a.p1);
				},
				() {
					generateExpr(tempAlloc, writer, ctx, a.p2);
				});
			break;
		case LowExprKind.SpecialTrinary.Kind.compareExchangeStrongBool:
			generateExpr(tempAlloc, writer, ctx, a.p0);
			generateExpr(tempAlloc, writer, ctx, a.p1);
			generateExpr(tempAlloc, writer, ctx, a.p2);
			writeFn(writer, source, FnOp.compareExchangeStrongBool);
			break;
	}
}

void generateIf(TempAlloc, CodeAlloc)(
	ref TempAlloc tempAlloc,
	ref ByteCodeWriter!CodeAlloc writer,
	ref ExprCtx ctx,
	ref immutable ByteCodeSource source,
	ref immutable LowExpr cond,
	scope void delegate() @safe @nogc pure nothrow cbThen,
	scope void delegate() @safe @nogc pure nothrow cbElse,
) {
	immutable StackEntry startStack = getNextStackEntry(writer);
	generateExpr(tempAlloc, writer, ctx, cond);
	immutable ByteCodeIndex delayed = writeSwitchDelay(writer, source, 2);
	fillDelayedSwitchEntry(writer, delayed, immutable Nat8(0));
	cbElse();
	setNextStackEntry(writer, startStack);
	immutable ByteCodeIndex jumpIndex = writeJumpDelayed(writer, source);
	fillDelayedSwitchEntry(writer, delayed, immutable Nat8(1));
	cbThen();
	fillInJumpDelayed(writer, jumpIndex);
}

void generateSpecialNAry(TempAlloc, CodeAlloc)(
	ref TempAlloc tempAlloc,
	ref ByteCodeWriter!CodeAlloc writer,
	ref ExprCtx ctx,
	ref immutable ByteCodeSource source,
	ref immutable LowType type,
	ref immutable LowExprKind.SpecialNAry a,
) {
	final switch (a.kind) {
		case LowExprKind.SpecialNAry.Kind.callFunPtr:
			immutable StackEntry stackEntryBeforeArgs = getNextStackEntry(writer);
			foreach (ref immutable LowExpr arg; range(a.args))
				generateExpr(tempAlloc, writer, ctx, arg);
			writeCallFunPtr(writer, source, stackEntryBeforeArgs, nStackEntriesForType(ctx, type));
			break;
	}
}
