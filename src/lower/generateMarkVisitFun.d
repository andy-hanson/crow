module lower.generateMarkVisitFun;

@safe @nogc pure nothrow:

import model.lowModel :
	AllLowTypes,
	isArray,
	isFiber,
	LowExpr,
	LowField,
	LowFun,
	LowFunSource,
	LowFunExprBody,
	LowFunBody,
	LowFunIndex,
	LowFunFlags,
	LowLocal,
	LowRecord,
	LowType,
	PrimitiveType;
import lower.lower : addLowFun, LowFunCause;
import lower.lowExprHelpers :
	boolType,
	genAddPointer,
	genAsAnyPointerConst,
	genCallFunPointerNoGcRoots,
	genCallNoGcRoots,
	genDerefGcPointer,
	genDerefRawPointer,
	genDrop,
	genGetArrData,
	genGetArrSize,
	genIf,
	genIncrPointer,
	genLetNoGcRoot,
	genLocal,
	genLocalByValue,
	genLocalGet,
	genLocalSet,
	genLoop,
	genLoopBreak,
	genLoopContinue,
	genPointerCast,
	genPointerEqual,
	genPointerEqualNull,
	genRecordFieldGet,
	genSeq,
	genSizeOf,
	genUnionMatch,
	genVoid,
	genWrapMulNat64,
	getElementPointerTypeFromArrType,
	voidType,
	voidConstPointerType;
import util.alloc.alloc : Alloc;
import util.col.array : exists, foldWithIndex, newArray, newSmallArray, SmallArray;
import util.col.fullIndexMap : fullIndexMapSize;
import util.col.mutArr : MutArr;
import util.col.mutIndexMap : getOrAdd, MutIndexMap, newMutIndexMap;
import util.col.mutMap : getOrAdd, MutMap;
import util.memory : allocate;
import util.opt : force, has, none, Opt, optIf, some;
import util.sourceRange : UriAndRange;
import util.symbol : symbol;

struct MarkVisitFuns {
	@safe @nogc pure nothrow:
	private:

	AllLowTypes* allTypesPtr;
	// If a type is not in one of these maps, it means we didn't need to generate a function for the type.

	// Every type with a 'mark-root' needs a 'mark-visit', but not the other way around.
	MutIndexMap!(LowType.Record, Opt!LowFunIndex) recordToMarkRoot;
	MutIndexMap!(LowType.Union, Opt!LowFunIndex) unionToMarkRoot;
	// For a gcPointee, the 'mark-visit' function works as a 'mark-root'.

	// Result is optional because some record types don't need a mark-visit funtion
	MutIndexMap!(LowType.Record, Opt!LowFunIndex) recordValToVisit;
	MutIndexMap!(LowType.Union, Opt!LowFunIndex) unionToVisit;
	MutMap!(LowType, LowFunIndex) gcPointeeToVisit;

	ref AllLowTypes allTypes() return scope =>
		*allTypesPtr;
}

MarkVisitFuns initMarkVisitFuns(ref Alloc alloc, AllLowTypes* allTypes) =>
	MarkVisitFuns(
		allTypes,
		newMutIndexMap!(LowType.Record, Opt!LowFunIndex)(alloc, fullIndexMapSize(allTypes.allRecords)),
		newMutIndexMap!(LowType.Union, Opt!LowFunIndex)(alloc, fullIndexMapSize(allTypes.allUnions)),
		newMutIndexMap!(LowType.Record, Opt!LowFunIndex)(alloc, fullIndexMapSize(allTypes.allRecords)),
		newMutIndexMap!(LowType.Union, Opt!LowFunIndex)(alloc, fullIndexMapSize(allTypes.allUnions)));

immutable struct MarkRoot {
	enum Kind { pointerToLocal, localAlreadyPointer }
	Kind kind;
	LowFunIndex fun;
}
Opt!MarkRoot getMarkRootForType(
	ref Alloc alloc,
	scope ref MutArr!LowFunCause lowFunCauses,
	scope ref MarkVisitFuns markVisitFuns,
	LowType lowType,
) =>
	lowType.match!(Opt!MarkRoot)(
		(LowType.Extern) =>
			none!MarkRoot,
		(LowType.FunPointer) =>
			none!MarkRoot,
		(PrimitiveType _) =>
			none!MarkRoot,
		(LowType.PtrGc x) =>
			some(MarkRoot(
				MarkRoot.Kind.localAlreadyPointer,
				getMarkVisitForPtrGc(alloc, lowFunCauses, markVisitFuns, x))),
		(LowType.PtrRawConst x) =>
			none!MarkRoot,
		(LowType.PtrRawMut x) =>
			none!MarkRoot,
		(LowType.Record x) {
			Opt!LowFunIndex res = getOrAdd!(LowType.Record, Opt!LowFunIndex)(markVisitFuns.recordToMarkRoot, x, () =>
				optIf(has(getMarkVisitForRecord(alloc, lowFunCauses, markVisitFuns, x)), () =>
					addLowFun(alloc, lowFunCauses, LowFunCause(LowFunCause.MarkRoot(LowType(x))))));
			return optIf(has(res), () => MarkRoot(MarkRoot.Kind.pointerToLocal, force(res)));
		},
		(LowType.Union x) {
			Opt!LowFunIndex res = getOrAdd!(LowType.Union, Opt!LowFunIndex)(markVisitFuns.unionToMarkRoot, x, () =>
				optIf(has(getMarkVisitForUnion(alloc, lowFunCauses, markVisitFuns, x)), () =>
					addLowFun(alloc, lowFunCauses, LowFunCause(LowFunCause.MarkRoot(LowType(x))))));
			return optIf(has(res), () => MarkRoot(MarkRoot.Kind.pointerToLocal, force(res)));
		});

// Returns none if the type does not need a mark-visit function (since it contains no GC pointers)
Opt!LowFunIndex getMarkVisitForType(
	ref Alloc alloc,
	scope ref MutArr!LowFunCause lowFunCauses,
	scope ref MarkVisitFuns markVisitFuns,
	LowType type,
) =>
	type.match!(Opt!LowFunIndex)(
		(LowType.Extern) =>
			none!LowFunIndex,
		(LowType.FunPointer) =>
			none!LowFunIndex,
		(PrimitiveType _) =>
			none!LowFunIndex,
		(LowType.PtrGc x) =>
			some(getMarkVisitForPtrGc(alloc, lowFunCauses, markVisitFuns, x)),
		(LowType.PtrRawConst) =>
			none!LowFunIndex,
		(LowType.PtrRawMut) =>
			none!LowFunIndex,
		(LowType.Record x) =>
			getMarkVisitForRecord(alloc, lowFunCauses, markVisitFuns, x),
		(LowType.Union x) =>
			getMarkVisitForUnion(alloc, lowFunCauses, markVisitFuns, x));

private LowFunIndex getMarkVisitForPtrGc(
	ref Alloc alloc,
	scope ref MutArr!LowFunCause lowFunCauses,
	scope ref MarkVisitFuns markVisitFuns,
	LowType.PtrGc type,
) =>
	getOrAdd(alloc, markVisitFuns.gcPointeeToVisit, *type.pointee, () =>
		addLowFun(alloc, lowFunCauses, LowFunCause(LowFunCause.MarkVisit(LowType(type)))));

private Opt!LowFunIndex getMarkVisitForRecord(
	ref Alloc alloc,
	scope ref MutArr!LowFunCause lowFunCauses,
	scope ref MarkVisitFuns markVisitFuns,
	LowType.Record type,
) =>
	getOrAdd!(LowType.Record, Opt!LowFunIndex)(markVisitFuns.recordValToVisit, type, () @safe {
		LowRecord record = markVisitFuns.allTypes.allRecords[type];
		return optIf(
			isArray(record) || isFiber(record) || exists!LowField(record.fields, (ref LowField field) =>
				has(getMarkVisitForType(alloc, lowFunCauses, markVisitFuns, field.type))),
			() => addLowFun(alloc, lowFunCauses, LowFunCause(LowFunCause.MarkVisit(LowType(type)))));
	});

private Opt!LowFunIndex getMarkVisitForUnion(
	ref Alloc alloc,
	scope ref MutArr!LowFunCause lowFunCauses,
	scope ref MarkVisitFuns markVisitFuns,
	LowType.Union type,
) =>
	getOrAdd!(LowType.Union, Opt!LowFunIndex)(markVisitFuns.unionToVisit, type, () =>
		optIf(
			exists!LowType(markVisitFuns.allTypes.allUnions[type].members, (ref LowType member) =>
				has(getMarkVisitForType(alloc, lowFunCauses, markVisitFuns, member))),
			() => addLowFun(alloc, lowFunCauses, LowFunCause(LowFunCause.MarkVisit(LowType(type))))));

LowFun generateMarkRoot(
	ref Alloc alloc,
	scope ref MutArr!LowFunCause lowFunCauses,
	scope ref MarkVisitFuns markVisitFuns,
	LowType markCtxType,
	LowFunIndex markFun,
	LowType type,
) {
	// For a pointer we should use mark-visit directly.
	assert(type.isA!(LowType.Record) || type.isA!(LowType.Union));
	LowFunIndex visit = force(getMarkVisitForType(alloc, lowFunCauses, markVisitFuns, type));
	/*
	mark-root void(ctx mark-ctx, pointer void const*)
		ctx mark-visit *(pointer.pointer-cast::t*)
	*/
	LowLocal[] params = newArray!LowLocal(alloc, [
		genLocalByValue(alloc, symbol!"mark-ctx", isMutable: false, 0, markCtxType),
		genLocalByValue(alloc, symbol!"pointer", isMutable: false, 1, voidConstPointerType)]);
	UriAndRange range = UriAndRange.empty;
	LowExpr markCtx = genLocalGet(range, &params[0]);
	LowExpr pointer = genLocalGet(range, &params[1]);
	LowType tPointer = LowType(LowType.PtrRawConst(allocate(alloc, type)));
	LowExpr deref = genDerefRawPointer(alloc, range, genPointerCast(alloc, tPointer, range, pointer));
	LowExpr callVisit = genCallNoGcRoots(alloc, voidType, range, visit, [markCtx, deref]);
	return LowFun(
		LowFunSource(allocate(alloc, LowFunSource.Generated(
			symbol!"mark-root",
			newArray!LowType(alloc, [type])))),
		voidType,
		params,
		LowFunBody(LowFunExprBody(LowFunFlags.none, callVisit)));
}

LowFun generateMarkVisit(
	ref Alloc alloc,
	scope ref MutArr!LowFunCause lowFunCauses,
	ref MarkVisitFuns markVisitFuns,
	LowType markCtxType,
	LowFunIndex markFun,
	LowType type,
) {
	UriAndRange range = UriAndRange.empty;
	LowLocal[] params = newArray!LowLocal(alloc, [
		genLocalByValue(alloc, symbol!"mark-ctx", isMutable: false, 0, markCtxType),
		genLocalByValue(alloc, symbol!"value", isMutable: false, 1, type)]);
	LowExpr markCtx = genLocalGet(range, &params[0]);
	LowExpr value = genLocalGet(range, &params[1]);
	Opt!LowFunIndex getMarkVisit(LowType x) =>
		getMarkVisitForType(alloc, lowFunCauses, markVisitFuns, x);
	ref AllLowTypes allTypes() => markVisitFuns.allTypes;
	LowExpr body_ = type.match!LowExpr(
		(LowType.Extern) =>
			assert(false),
		(LowType.FunPointer) =>
			assert(false),
		(PrimitiveType _) =>
			assert(false),
		(LowType.PtrGc x) =>
			generateMarkVisitGcPtr(
				alloc, allTypes, markCtxType, markFun, range, markCtx, value, *x.pointee, getMarkVisit(*x.pointee)),
		(LowType.PtrRawConst) =>
			assert(false),
		(LowType.PtrRawMut) =>
			assert(false),
		(LowType.Record x) {
			LowRecord* record = &allTypes.allRecords[x];
			if (isArray(*record)) {
				LowType.PtrRawConst elementPointerType = getElementPointerTypeFromArrType(allTypes, x);
				return generateMarkVisitArray(
					alloc, allTypes, markFun, markCtx, value, elementPointerType,
					getMarkVisit(*elementPointerType.pointee));
			} else if (isFiber(*record))
				return generateMarkVisitFiber(alloc, allTypes, range, markCtx, value, *record, (LowType x) =>
					getMarkVisit(x));
			else
				return generateMarkVisitRecord(
					alloc, lowFunCauses, markVisitFuns, range, record.fields, markCtx, value);
		},
		(LowType.Union x) =>
			generateMarkVisitUnion(
				alloc, lowFunCauses, markVisitFuns, range, allTypes.allUnions[x].members, markCtx, value));
	return LowFun(
		LowFunSource(allocate(alloc, LowFunSource.Generated(symbol!"mark-visit", newArray!LowType(alloc, [type])))),
		voidType,
		params,
		LowFunBody(LowFunExprBody(LowFunFlags.none, body_)));
}

private:

LowExpr generateMarkVisitGcPtr(
	ref Alloc alloc,
	in AllLowTypes allTypes,
	LowType markCtxType,
	LowFunIndex markFun,
	UriAndRange range,
	LowExpr markCtx,
	LowExpr value,
	LowType pointeeType,
	Opt!LowFunIndex visitPointee,
) {
	LowExpr mark = genCallNoGcRoots(alloc, boolType, range, markFun, [
		markCtx,
		genAsAnyPointerConst(alloc, range, value),
		genSizeOf(allTypes, range, pointeeType)]);
	if (has(visitPointee)) {
		LowExpr valueDeref = genDerefGcPointer(alloc, range, value);
		LowExpr recur = genCallNoGcRoots(alloc, voidType, range, force(visitPointee), [markCtx, valueDeref]);
		return genIf(alloc, range, mark, recur, genVoid(range));
	} else
		return genDrop(alloc, range, mark);
}

/*
mark-visit void(mark-ctx mark-ctx, a element[])
	if mark-ctx mark a.data.pointer-cast, a.size * size-of@<a>
		cur mut = a.data
		end = a.data + a.size
		loop
			# mark-visit for `element`
			mark-ctx mark-visit *cur
			cur := cur + 1
			if cur == end
				break
			else
				continue
*/
LowExpr generateMarkVisitArray(
	ref Alloc alloc,
	in AllLowTypes allTypes,
	LowFunIndex markFun,
	LowExpr getMarkCtx,
	LowExpr getA,
	LowType.PtrRawConst elementPointerType,
	Opt!LowFunIndex markVisitElementFun,
) {
	LowType elementType = *elementPointerType.pointee;
	UriAndRange range = UriAndRange.empty;
	LowExpr getData = genGetArrData(alloc, range, getA, elementPointerType);
	LowExpr getSize = genGetArrSize(alloc, range, getA);
	// mark-ctx mark a.data.pointer-cast, a.size * size-of@<a>
	LowExpr callMark = genCallNoGcRoots(alloc, boolType, range, markFun, [
		getMarkCtx,
		genAsAnyPointerConst(alloc, range, getData),
		genWrapMulNat64(alloc, range, getSize, genSizeOf(allTypes, range, elementType))]);
	if (has(markVisitElementFun)) {
		LowExpr voidValue = genVoid(range);
		LowLocal* cur = genLocal(alloc, symbol!"cur", isMutable: true, 2, LowType(elementPointerType));
		LowExpr getCur = genLocalGet(range, cur);
		LowLocal* end = genLocal(alloc, symbol!"end", isMutable: false, 3, LowType(elementPointerType));
		LowExpr getEnd = genLocalGet(range, end);
		LowExpr loop = genLoop(alloc, voidType, range, genSeq(
			alloc, range,
			// mark-ctx mark-visit *cur
			genCallNoGcRoots(alloc, voidType, range, force(markVisitElementFun), [
				getMarkCtx,
				genDerefRawPointer(alloc, range, getCur)]),
			// cur := cur + 1
			genLocalSet(alloc, range, cur, genIncrPointer(alloc, range, elementPointerType, getCur)),
			// cur == end ? break : continue
			genIf(
				alloc,
				range,
				genPointerEqual(alloc, range, getCur, getEnd),
				genLoopBreak(alloc, voidType, range, voidValue),
				genLoopContinue(voidType, range))));
		LowExpr ifBody = genLetNoGcRoot(
			alloc, range, cur, getData,
			genLetNoGcRoot(
				alloc, range, end, genAddPointer(alloc, elementPointerType, range, getData, getSize), loop));
		return genIf(alloc, range, callMark, ifBody, voidValue);
	} else
		return genDrop(alloc, range, callMark);
}

/*
mark-visit void(mark-ctx mark-ctx, a fiber)
	mark-ctx mark-visit fiber.initial-function
	mark-ctx mark-visit fiber.log-handler
	mark-ctx mark-visit fiber.stack
	cur mut = fiber.gc-root
	loop
		if cur == null
			break
		else
			cur->trace[mark-ctx, cur->pointer]
			cur := cur->next
			continue
*/
LowExpr generateMarkVisitFiber(
	ref Alloc alloc,
	in AllLowTypes allTypes,
	UriAndRange range,
	LowExpr markCtx,
	LowExpr fiber,
	in LowRecord fiberRecord,
	in Opt!LowFunIndex delegate(LowType) @safe @nogc pure nothrow getMarkVisit,
) {
	LowExpr genVisitField(uint fieldIndex, bool allowSkip = false) {
		LowType fieldType = fiberRecord.fields[fieldIndex].type;
		Opt!LowFunIndex visitField = getMarkVisit(fieldType);
		return allowSkip && !has(visitField)
			? genVoid(range)
			: genCallNoGcRoots(alloc, voidType, range, force(visitField), [
				markCtx,
				genRecordFieldGet(alloc, fieldType, range, fiber, fieldIndex)]);
	}
	LowExpr visitState = genVisitField(0);
	// 'log-handler' might never need a closure and so might not need a visit
	LowExpr visitLogHandler = genVisitField(1, true);
	LowExpr visitStack = genVisitField(2);
	LowField* gcRoot = &fiberRecord.fields[3];
	LowExpr getGcRoot = genRecordFieldGet(alloc, gcRoot.type, range, fiber, 3);

	LowLocal* cur = genLocal(alloc, symbol!"cur", isMutable: true, 2, gcRoot.type);
	LowExpr getCur = genLocalGet(range, cur);
	LowRecord* gcRootRecord = &allTypes.allRecords[cur.type.as!(LowType.PtrRawMut).pointee.as!(LowType.Record)];
	LowExpr gcRootField(size_t fieldIndex) =>
		genRecordFieldGet(alloc, gcRootRecord.fields[fieldIndex].type, range, getCur, fieldIndex);
	LowExpr curPointer = gcRootField(0);
	LowExpr curTrace = gcRootField(1);
	LowExpr curNext = gcRootField(2);
	LowExpr callTrace = genCallFunPointerNoGcRoots(
		voidType, range, allocate(alloc, curTrace), newSmallArray!LowExpr(alloc, [markCtx, curPointer]));
	LowExpr updateCur = genLocalSet(alloc, range, cur, curNext);
	LowExpr loop = genLoop(alloc, voidType, range, genIf(
		alloc,
		range,
		genPointerEqualNull(alloc, range, getCur),
		genLoopBreak(alloc, voidType, range, genVoid(range)),
		genSeq(alloc, range, callTrace, updateCur, genLoopContinue(voidType, range))));
	LowExpr letCurAndLoop = genLetNoGcRoot(alloc, range, cur, getGcRoot, loop);
	return genSeq(alloc, range, visitState, visitLogHandler, visitStack, letCurAndLoop);
}

LowExpr generateMarkVisitRecord(
	ref Alloc alloc,
	scope ref MutArr!LowFunCause lowFunCauses,
	scope ref MarkVisitFuns markVisitFuns,
	UriAndRange range,
	LowField[] fields,
	LowExpr markCtx,
	LowExpr value,
) =>
	// 'force' since we wouldn't generate the function unless some field needed marking.
	force(foldWithIndex!(Opt!LowExpr, LowField)(
		none!LowExpr, fields, (Opt!LowExpr acc, size_t fieldIndex, ref LowField field) {
			Opt!LowFunIndex fun = getMarkVisitForType(alloc, lowFunCauses, markVisitFuns, field.type);
			if (has(fun)) {
				LowExpr fieldGet = genRecordFieldGet(alloc, field.type, range, value, fieldIndex);
				LowExpr call = genCallNoGcRoots(alloc, voidType, range, force(fun), [markCtx, fieldGet]);
				return some(has(acc) ? genSeq(alloc, range, force(acc), call) : call);
			} else
				return acc;
		}));

LowExpr generateMarkVisitUnion(
	ref Alloc alloc,
	scope ref MutArr!LowFunCause lowFunCauses,
	scope ref MarkVisitFuns markVisitFuns,
	UriAndRange range,
	SmallArray!LowType unionMembers,
	LowExpr markCtx,
	LowExpr value,
) =>
	genUnionMatch(alloc, voidType, range, value, unionMembers, (size_t i, LowExpr member) {
		Opt!LowFunIndex visitMember = getMarkVisitForType(alloc, lowFunCauses, markVisitFuns, unionMembers[i]);
		return has(visitMember)
			? genCallNoGcRoots(alloc, voidType, range, force(visitMember), [markCtx, member])
			: genVoid(range);
	});
