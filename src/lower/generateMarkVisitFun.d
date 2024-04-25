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
	LowLocal,
	LowRecord,
	LowType,
	PrimitiveType;
import lower.lower : addLowFun, LowFunCause; // TODO: CIRCULAR IMPORT -------------------------------------------------------------
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
import util.col.array : exists2, mapPointers, newArray, newSmallArray, SmallArray;
import util.col.fullIndexMap : fullIndexMapSize;
import util.col.mutArr : MutArr;
import util.col.mutIndexMap : getOrAdd, mustGet, MutIndexMap, newMutIndexMap;
import util.col.mutMap : getOrAdd, MutMap, ValueAndDidAdd;
import util.memory : allocate;
import util.opt : force, has, none, Opt, optIf, some;
import util.sourceRange : UriAndRange;
import util.symbol : symbol;
import util.util : todo, typeAs;

struct MarkVisitFuns {
	private:
	// If a type is not in one of these maps, it means we didn't need to generate a mark-visit function for the type.

	// Every type with a 'mark-root' needs a 'mark-visit', but not the other way around.
	MutIndexMap!(LowType.Record, Opt!LowFunIndex) recordToMarkRoot;
	MutIndexMap!(LowType.Union, Opt!LowFunIndex) unionToMarkRoot;
	// For a gcPointee, the 'mark-visit' function works as a 'mark-root'. (And we don't point to the pointer, just use it directly.)

	// Result is optional because some record types don't need a mark-visit funtion
	MutIndexMap!(LowType.Record, Opt!LowFunIndex) recordValToVisit;
	MutIndexMap!(LowType.Union, Opt!LowFunIndex) unionToVisit;
	MutMap!(LowType, LowFunIndex) gcPointeeToVisit;
}

MarkVisitFuns initMarkVisitFuns(ref Alloc alloc, in AllLowTypes allTypes) =>
	MarkVisitFuns(
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
	in AllLowTypes allTypes,
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
			some(MarkRoot(MarkRoot.Kind.localAlreadyPointer, getMarkVisitForPtrGc(alloc, lowFunCauses, markVisitFuns, x))),
		(LowType.PtrRawConst x) =>
			none!MarkRoot,
		(LowType.PtrRawMut x) =>
			none!MarkRoot,
		(LowType.Record x) {
			Opt!LowFunIndex res = getOrAdd!(LowType.Record, Opt!LowFunIndex)(markVisitFuns.recordToMarkRoot, x, () =>
				optIf(has(getMarkVisitForRecord(alloc, lowFunCauses, markVisitFuns, allTypes, x)), () =>
					addLowFun(alloc, lowFunCauses, LowFunCause(LowFunCause.MarkRoot(LowType(x))))));
			return optIf(has(res), () => MarkRoot(MarkRoot.Kind.pointerToLocal, force(res)));
		},
		(LowType.Union x) {
			Opt!LowFunIndex res = getOrAdd!(LowType.Union, Opt!LowFunIndex)(markVisitFuns.unionToMarkRoot, x, () =>
				optIf(has(getMarkVisitForUnion(alloc, lowFunCauses, markVisitFuns, allTypes, x)), () => 
					addLowFun(alloc, lowFunCauses, LowFunCause(LowFunCause.MarkRoot(LowType(x))))));
			return optIf(has(res), () => MarkRoot(MarkRoot.Kind.pointerToLocal, force(res)));
		});

// Returns none if the type does not need a mark-visit function (since it contains no GC pointers)
Opt!LowFunIndex getMarkVisitForType(
	ref Alloc alloc,
	scope ref MutArr!LowFunCause lowFunCauses,
	scope ref MarkVisitFuns markVisitFuns,
	in AllLowTypes allTypes,
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
			getMarkVisitForRecord(alloc, lowFunCauses, markVisitFuns, allTypes, x),
		(LowType.Union x) =>
			getMarkVisitForUnion(alloc, lowFunCauses, markVisitFuns, allTypes, x));

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
	in AllLowTypes allTypes,
	LowType.Record type,
) =>
	getOrAdd!(LowType.Record, Opt!LowFunIndex)(markVisitFuns.recordValToVisit, type, () {
		LowRecord record = allTypes.allRecords[type];
		return optIf(
			isArray(record) || isFiber(record) || exists2!LowField(record.fields, (ref LowField field) =>
				has(getMarkVisitForType(alloc, lowFunCauses, markVisitFuns, allTypes, field.type))),
			() => addLowFun(alloc, lowFunCauses, LowFunCause(LowFunCause.MarkVisit(LowType(type)))));
	});

private Opt!LowFunIndex getMarkVisitForUnion(
	ref Alloc alloc,
	scope ref MutArr!LowFunCause lowFunCauses,
	scope ref MarkVisitFuns markVisitFuns,
	in AllLowTypes allTypes,
	LowType.Union type,
) =>
	getOrAdd!(LowType.Union, Opt!LowFunIndex)(markVisitFuns.unionToVisit, type, () =>
		optIf(
			exists2!LowType(allTypes.allUnions[type].members, (ref LowType member) =>
				has(getMarkVisitForType(alloc, lowFunCauses, markVisitFuns, allTypes, member))),
			() => addLowFun(alloc, lowFunCauses, LowFunCause(LowFunCause.MarkVisit(LowType(type))))));

LowFun generateMarkRoot(
	ref Alloc alloc,
	scope ref MutArr!LowFunCause lowFunCauses,
	scope ref MarkVisitFuns markVisitFuns,
	in AllLowTypes allTypes, // TODO: maybe this should be on the markVisitFuns so I don't have to pass it to every function! --------------
	LowType markCtxType,
	LowFunIndex markFun,
	LowType type,
) {
	// For a pointer we should use mark-visit directly.
	assert(type.isA!(LowType.Record) || type.isA!(LowType.Union));
	LowFunIndex visit = force(getMarkVisitForType(alloc, lowFunCauses, markVisitFuns, allTypes, type));	
	/*
	mark-root void(ctx mark-ctx, pointer void const*)
		ctx mark-visit *(pointer.pointer-cast::t*)
	*/
	LowLocal[] params = newArray!LowLocal(alloc, [
		genLocalByValue(alloc, symbol!"mark-ctx", 0, markCtxType),
		genLocalByValue(alloc, symbol!"pointer", 1, voidConstPointerType)]);
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
		LowFunBody(LowFunExprBody(false, false, callVisit)));
}

LowFun generateMarkVisit(
	ref Alloc alloc,
	scope ref MutArr!LowFunCause lowFunCauses,
	scope ref MarkVisitFuns markVisitFuns,
	in AllLowTypes allTypes,
	LowType markCtxType,
	LowFunIndex markFun,
	LowType type,
) {
	Opt!LowFunIndex getMarkVisit(LowType x) =>
		getMarkVisitForType(alloc, lowFunCauses, markVisitFuns, allTypes, x);
	return type.match!LowFun(
		(LowType.Extern) =>
			assert(false),
		(LowType.FunPointer) =>
			assert(false),
		(PrimitiveType _) =>
			assert(false),
		(LowType.PtrGc x) =>
			generateMarkVisitGcPtr(alloc, allTypes, markCtxType, markFun, x, getMarkVisit(*x.pointee)),
		(LowType.PtrRawConst) =>
			assert(false),
		(LowType.PtrRawMut) =>
			assert(false),
		(LowType.Record x) {
			LowRecord* record = &allTypes.allRecords[x];
			if (isArray(*record)) {
				LowType.PtrRawConst elementPointerType = getElementPointerTypeFromArrType(allTypes, x);
				return generateMarkVisitArray(
					alloc, allTypes, markCtxType, markFun, x, elementPointerType, getMarkVisit(*elementPointerType.pointee));
			} else if (isFiber(*record))
				return generateMarkVisitFiber(alloc, allTypes, markCtxType, markFun, x, *record, (LowType x) => getMarkVisit(x));
			else
				return generateMarkVisitRecordOrUnion(alloc, lowFunCauses, markVisitFuns, allTypes, markCtxType, type);
		},
		(LowType.Union x) =>
			generateMarkVisitRecordOrUnion(alloc, lowFunCauses, markVisitFuns, allTypes, markCtxType, type));
}

private:

LowFun generateMarkVisitGcPtr(
	ref Alloc alloc,
	in AllLowTypes allTypes,
	LowType markCtxType,
	LowFunIndex markFun,
	LowType.PtrGc pointerTypePtrGc,
	Opt!LowFunIndex visitPointee,
) {
	LowType pointerType = LowType(pointerTypePtrGc);
	LowType pointeeType = *pointerTypePtrGc.pointee;
	UriAndRange range = UriAndRange.empty;
	LowLocal[] params = markVisitParams(alloc, markCtxType, pointerType); // TODO: actually, just generate params in 'generateMarkVisit' and pass them to every individual fun...
	LowExpr markCtx = genLocalGet(range, &params[0]);
	LowExpr value = genLocalGet(range, &params[1]);
	LowExpr sizeExpr = genSizeOf(allTypes, range, pointeeType);
	LowExpr valueAsAnyPointerConst = genAsAnyPointerConst(alloc, range, value);
	LowExpr mark = genCallNoGcRoots(alloc, boolType, range, markFun, [markCtx, valueAsAnyPointerConst, sizeExpr]);
	LowExpr expr = () {
		if (has(visitPointee)) {
			LowExpr valueDeref = genDerefGcPointer(alloc, range, value);
			LowExpr recur = genCallNoGcRoots(alloc, voidType, range, force(visitPointee), [markCtx, valueDeref]);
			return genIf(alloc, range, mark, recur, genVoid(range));
		} else
			return genDrop(alloc, range, mark);
	}();
	LowFunExprBody body_ = LowFunExprBody(false, false, expr);
	return LowFun(markVisitLowFunSource(alloc, pointerType), voidType, params, LowFunBody(body_));
}

LowLocal[] markVisitParams(ref Alloc alloc, LowType markCtxType, LowType type) =>
	newArray!LowLocal(alloc, [
		genLocalByValue(alloc, symbol!"mark-ctx", 0, markCtxType),
		genLocalByValue(alloc, symbol!"value", 1, type)]);

LowFunSource markVisitLowFunSource(ref Alloc alloc, LowType type) =>
	LowFunSource(allocate(alloc, LowFunSource.Generated(symbol!"mark-visit", newArray!LowType(alloc, [type]))));

LowFun generateMarkVisitRecordOrUnion( // TODO: this function is a bit silly ..... I think once I have its caller doing more of the LowFun setup I should split this in 2
	ref Alloc alloc,
	scope ref MutArr!LowFunCause lowFunCauses,
	scope ref MarkVisitFuns markVisitFuns,
	in AllLowTypes allTypes,
	LowType markCtxType,
	LowType paramType,
) {
	UriAndRange range = UriAndRange.empty;
	LowLocal[] params = markVisitParams(alloc, markCtxType, paramType);
	LowExpr markCtx = genLocalGet(range, &params[0]);
	LowExpr value = genLocalGet(range, &params[1]);
	LowFunExprBody body_ = paramType.isA!(LowType.Record)
		? visitRecordBody(
			alloc, lowFunCauses, markVisitFuns, allTypes, range, allTypes.allRecords[paramType.as!(LowType.Record)].fields, markCtx, value)
		: paramType.isA!(LowType.Union)
		? visitUnionBody(
			alloc, lowFunCauses, markVisitFuns, allTypes, range, allTypes.allUnions[paramType.as!(LowType.Union)].members, markCtx, value)
		: assert(false);
	return LowFun(markVisitLowFunSource(alloc, paramType), voidType, params, LowFunBody(body_));
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
LowFun generateMarkVisitArray(
	ref Alloc alloc,
	in AllLowTypes allTypes,
	LowType markCtxType,
	LowFunIndex markFun,
	LowType.Record arrType,
	LowType.PtrRawConst elementPointerType,
	Opt!LowFunIndex markVisitElementFun,
) {
	LowType elementType = *elementPointerType.pointee;
	UriAndRange range = UriAndRange.empty;
	LowLocal[] params = markVisitParams(alloc, markCtxType, LowType(arrType));
	LowExpr getMarkCtx = genLocalGet(range, &params[0]);
	LowExpr getA = genLocalGet(range, &params[1]);
	LowExpr getData = genGetArrData(alloc, range, getA, elementPointerType);
	LowExpr getSize = genGetArrSize(alloc, range, getA);
	// mark-ctx mark a.data.pointer-cast, a.size * size-of@<a>
	LowExpr callMark = genCallNoGcRoots(alloc, boolType, range, markFun, [
		getMarkCtx,
		genAsAnyPointerConst(alloc, range, getData),
		genWrapMulNat64(alloc, range, getSize, genSizeOf(allTypes, range, elementType))]);
	LowExpr expr = () {
		if (has(markVisitElementFun)) {
			LowExpr voidValue = genVoid(range);
			LowLocal* cur = genLocal(alloc, symbol!"cur", 2, LowType(elementPointerType));
			LowExpr getCur = genLocalGet(range, cur);
			LowLocal* end = genLocal(alloc, symbol!"end", 3, LowType(elementPointerType));
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

			LowExpr ifBody = genLetNoGcRoot(alloc, range, cur, getData,
				genLetNoGcRoot(alloc, range, end, genAddPointer(alloc, elementPointerType, range, getData, getSize), loop));
			return genIf(alloc, range, callMark, ifBody, voidValue);
		} else
			return genDrop(alloc, range, callMark);
	}();
	return LowFun(
		LowFunSource(allocate(alloc, LowFunSource.Generated(
			symbol!"mark-arr", newArray!LowType(alloc, [elementType])))),
		voidType,
		params,
		LowFunBody(LowFunExprBody(false, false, expr)));
}


/*
mark-visit void(mark-ctx mark-ctx, a fiber)
	mark-ctx mark-visit fiber.initial-function
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
LowFun generateMarkVisitFiber(
	ref Alloc alloc,
	in AllLowTypes allTypes,
	LowType markCtxType,
	LowFunIndex markFun,
	LowType.Record fiberType,
	in LowRecord fiberRecord,
	in Opt!LowFunIndex delegate(LowType) @safe @nogc pure nothrow getMarkVisit,
) {
	UriAndRange range = UriAndRange.empty;
	LowLocal[] params = markVisitParams(alloc, markCtxType, LowType(fiberType));

	LowExpr markCtx = genLocalGet(range, &params[0]);
	LowExpr fiber = genLocalGet(range, &params[1]);

	LowField* initialFunction = &fiberRecord.fields[0];
	LowField* stack = &fiberRecord.fields[1];
	LowField* gcRoot = &fiberRecord.fields[2];

	LowExpr visitInitialFunction = genCallNoGcRoots(alloc, voidType, range, force(getMarkVisit(initialFunction.type)), [
		markCtx,
		genRecordFieldGet(alloc, range, fiber, initialFunction.type, 0)]);
	LowExpr visitStack = genCallNoGcRoots(alloc, voidType, range, force(getMarkVisit(stack.type)), [
		markCtx,
		genRecordFieldGet(alloc, range, fiber, stack.type, 1)]);
	
	LowLocal* cur = genLocal(alloc, symbol!"cur", 2, gcRoot.type);
	LowExpr getCur = genLocalGet(range, cur);
	LowRecord* gcRootRecord = &allTypes.allRecords[cur.type.as!(LowType.PtrRawMut).pointee.as!(LowType.Record)];
	LowExpr gcRootField(size_t fieldIndex) =>
		genRecordFieldGet(alloc, range, getCur, gcRootRecord.fields[fieldIndex].type, fieldIndex);
	LowExpr curPointer = gcRootField(0);
	LowExpr curTrace = gcRootField(1);
	LowExpr curNext = gcRootField(2);
	LowExpr callTrace = genCallFunPointerNoGcRoots(voidType, range, allocate(alloc, curTrace), newSmallArray!LowExpr(alloc, [markCtx, curPointer]));
	LowExpr updateCur = genLocalSet(alloc, range, cur, curNext);
	LowExpr loop = genLoop(alloc, voidType, range, genIf(
		alloc,
		range,
		genPointerEqualNull(alloc, range, getCur),
		genLoopBreak(alloc, voidType, range, genVoid(range)),
		genSeq(alloc, range, callTrace, updateCur, genLoopContinue(voidType, range))));
	LowExpr letCurAndLoop = genLetNoGcRoot(alloc, range, cur, genRecordFieldGet(alloc, range, fiber, cur.type, 2), loop);
	return LowFun(
		markVisitLowFunSource(alloc, LowType(fiberType)),
		voidType,
		params,
		LowFunBody(LowFunExprBody(false, false, genSeq(alloc, range, visitInitialFunction, visitStack, letCurAndLoop))));
}

LowFunExprBody visitRecordBody(
	ref Alloc alloc,
	scope ref MutArr!LowFunCause lowFunCauses,
	scope ref MarkVisitFuns markVisitFuns,
	in AllLowTypes allTypes,
	UriAndRange range,
	LowField[] fields,
	LowExpr markCtx,
	LowExpr value,
) {
	Opt!LowExpr recur(Opt!LowExpr accum, size_t fieldIndex) {
		if (fieldIndex == fields.length)
			return accum;
		else {
			LowType fieldType = fields[fieldIndex].type;
			Opt!LowExpr newAccum = () {
				Opt!LowFunIndex fun = getMarkVisitForType(alloc, lowFunCauses, markVisitFuns, allTypes, fieldType);
				if (has(fun)) {
					LowExpr fieldGet = genRecordFieldGet(alloc, range, value, fieldType, fieldIndex);
					LowExpr call = genCallNoGcRoots(alloc, voidType, range, force(fun), [markCtx, fieldGet]);
					return some(has(accum) ? genSeq(alloc, range, force(accum), call) : call);
				} else
					return accum;
			}();
			return recur(newAccum, fieldIndex + 1);
		}
	}
	Opt!LowExpr e = recur(none!LowExpr, 0);
	return LowFunExprBody(false, false, has(e) ? force(e) : genVoid(range));
}

LowFunExprBody visitUnionBody(
	ref Alloc alloc,
	scope ref MutArr!LowFunCause lowFunCauses,
	scope ref MarkVisitFuns markVisitFuns,
	in AllLowTypes allTypes,
	UriAndRange range,
	SmallArray!LowType unionMembers,
	LowExpr markCtx,
	LowExpr value,
) =>
	LowFunExprBody(false, false, genUnionMatch(alloc, voidType, range, value, unionMembers, (size_t i, LowExpr member) {
		Opt!LowFunIndex visitMember = getMarkVisitForType(alloc, lowFunCauses, markVisitFuns, allTypes, unionMembers[i]);
		return has(visitMember)
			? genCallNoGcRoots(alloc, voidType, range, force(visitMember), [markCtx, member])
			: genVoid(range);
	}));
