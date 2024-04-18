module lower.generateMarkVisitFun;

@safe @nogc pure nothrow:

import model.lowModel :
	AllLowTypes,
	isArray,
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
import lower.lower : addLowFun, LowFunCause; // TODO: CIRCULAR IMPORT ---------------------------------
import lower.lowExprHelpers :
	boolType,
	genAddPtr,
	genAsAnyPtrConst,
	genCall,
	genDerefGcPtr,
	genDerefRawPtr,
	genDrop,
	genGetArrData,
	genGetArrSize,
	genIf,
	genIncrPointer,
	genLet,
	genLocal,
	genLocalByValue,
	genLocalGet,
	genLocalSet,
	genLoop,
	genLoopBreak,
	genLoopContinue,
	genPtrEq,
	genRecordFieldGet,
	genSeq,
	genSizeOf,
	genUnionMatch,
	genVoid,
	genWrapMulNat64,
	getElementPtrTypeFromArrType,
	voidType;
import util.alloc.alloc : Alloc;
import util.col.array : exists2, newArray, SmallArray;
import util.col.mutArr : MutArr;
import util.col.mutIndexMap : getOrAdd, mustGet, MutIndexMap, newMutIndexMap;
import util.col.mutMap : getOrAdd, MutMap, ValueAndDidAdd;
import util.memory : allocate;
import util.opt : force, has, none, Opt, optIf, some;
import util.sourceRange : UriAndRange;
import util.symbol : symbol;
import util.util : typeAs;

struct MarkVisitFuns {
	// If a type is not in one of these maps, it means we didn't need to generate a mark-visit function for the type.

	// Result is optional because some record types don't need a mark-visit funtion
	MutIndexMap!(LowType.Record, Opt!LowFunIndex) recordValToVisit;
	MutIndexMap!(LowType.Union, Opt!LowFunIndex) unionToVisit;
	MutMap!(LowType, LowFunIndex) gcPointeeToVisit;
}

// Returns none if the type does not need a mark-visit function (since it contains no GC pointers)
Opt!LowFunIndex getMarkVisitForType(
	ref Alloc alloc,
	scope ref MutArr!LowFunCause lowFunCauses,
	scope ref MarkVisitFuns markVisitFuns,
	in AllLowTypes allTypes,
	LowType lowType,
) {
	LowFunIndex add() =>
		addLowFun(alloc, lowFunCauses, LowFunCause(LowFunCause.MarkVisit(lowType)));
	Opt!LowFunIndex recur(LowType x) =>
		getMarkVisitForType(alloc, lowFunCauses, markVisitFuns, allTypes, x);
	return lowType.match!(Opt!LowFunIndex)(
		(LowType.Extern) =>
			none!LowFunIndex,
		(LowType.FunPointer) =>
			none!LowFunIndex,
		(PrimitiveType _) =>
			none!LowFunIndex,
		(LowType.PtrGc x) =>
			some(getOrAdd(alloc, markVisitFuns.gcPointeeToVisit, *x.pointee, () => add())),
		(LowType.PtrRawConst) =>
			none!LowFunIndex,
		(LowType.PtrRawMut) =>
			none!LowFunIndex,
		(LowType.Record x) =>
			getOrAdd!(LowType.Record, Opt!LowFunIndex)(markVisitFuns.recordValToVisit, x, () {
				LowRecord record = allTypes.allRecords[x];
				return optIf(
					isArray(record) || exists2!LowField(record.fields, (ref LowField field) =>
						has(recur(field.type))),
					() => add());
			}),
		(LowType.Union x) =>
			getOrAdd!(LowType.Union, Opt!LowFunIndex)(markVisitFuns.unionToVisit, x, () =>
				optIf(
					exists2!LowType(allTypes.allUnions[x].members, (ref LowType member) => has(recur(member))),
					() => add())));
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
			if (isArray(allTypes.allRecords[x])) {
				LowType.PtrRawConst elementPtrType = getElementPtrTypeFromArrType(allTypes, x);
				return generateMarkVisitArr(
					alloc, allTypes, markCtxType, markFun, x, elementPtrType, getMarkVisit(*elementPtrType.pointee));
			} else
				return generateMarkVisitNonArr(alloc, lowFunCauses, markVisitFuns, allTypes, markCtxType, type);
		},
		(LowType.Union x) =>
			generateMarkVisitNonArr(alloc, lowFunCauses, markVisitFuns, allTypes, markCtxType, type));
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
	LowLocal[] params = newArray!LowLocal(alloc, [
		genLocalByValue(alloc, symbol!"mark-ctx", 0, markCtxType),
		genLocalByValue(alloc, symbol!"value", 1, pointerType)]);
	LowExpr markCtx = genLocalGet(range, &params[0]);
	LowExpr value = genLocalGet(range, &params[1]);
	LowExpr sizeExpr = genSizeOf(allTypes, range, pointeeType);
	LowExpr valueAsAnyPtrConst = genAsAnyPtrConst(alloc, range, value);
	LowExpr mark = genCall(alloc, range, markFun, boolType, [markCtx, valueAsAnyPtrConst, sizeExpr]);
	LowExpr expr = () {
		if (has(visitPointee)) {
			LowExpr valueDeref = genDerefGcPtr(alloc, range, value);
			LowExpr recur = genCall(alloc, range, force(visitPointee), voidType, [markCtx, valueDeref]);
			return genIf(alloc, range, mark, recur, genVoid(range));
		} else
			return genDrop(alloc, range, mark);
	}();
	LowFunExprBody body_ = LowFunExprBody(false, expr);
	return LowFun(
		LowFunSource(allocate(alloc, LowFunSource.Generated(
			symbol!"mark-visit",
			newArray!LowType(alloc, [pointerType])))),
		voidType,
		params,
		LowFunBody(body_));
}

LowFun generateMarkVisitNonArr(
	ref Alloc alloc,
	scope ref MutArr!LowFunCause lowFunCauses,
	scope ref MarkVisitFuns markVisitFuns,
	in AllLowTypes allTypes,
	LowType markCtxType,
	LowType paramType,
) {
	UriAndRange range = UriAndRange.empty;
	LowLocal[] params = newArray!LowLocal(alloc, [
		genLocalByValue(alloc, symbol!"mark-ctx", 0, markCtxType),
		genLocalByValue(alloc, symbol!"value", 1, paramType)]);
	LowExpr markCtx = genLocalGet(range, &params[0]);
	LowExpr value = genLocalGet(range, &params[1]);
	LowFunExprBody body_ = paramType.isA!(LowType.Record)
		? visitRecordBody(
			alloc, lowFunCauses, markVisitFuns, allTypes, range, allTypes.allRecords[paramType.as!(LowType.Record)].fields, markCtx, value)
		: paramType.isA!(LowType.Union)
		? visitUnionBody(
			alloc, lowFunCauses, markVisitFuns, allTypes, range, allTypes.allUnions[paramType.as!(LowType.Union)].members, markCtx, value)
		: assert(false);
	return LowFun(
		LowFunSource(allocate(alloc, LowFunSource.Generated(
			symbol!"mark-visit", newArray!LowType(alloc, [paramType])))),
		voidType,
		params,
		LowFunBody(body_));
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
LowFun generateMarkVisitArr(
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
	LowLocal[] params = newArray!LowLocal(alloc, [
		genLocalByValue(alloc, symbol!"mark-ctx", 0, markCtxType),
		genLocalByValue(alloc, symbol!"a", 1, LowType(arrType))]);
	LowExpr getMarkCtx = genLocalGet(range, &params[0]);
	LowExpr getA = genLocalGet(range, &params[1]);
	LowExpr getData = genGetArrData(alloc, range, getA, elementPointerType);
	LowExpr getSize = genGetArrSize(alloc, range, getA);
	// mark-ctx mark a.data.pointer-cast, a.size * size-of@<a>
	LowExpr callMark = genCall(alloc, range, markFun, boolType, [
		getMarkCtx,
		genAsAnyPtrConst(alloc, range, getData),
		genWrapMulNat64(alloc, range, getSize, genSizeOf(allTypes, range, elementType))]);
	LowExpr expr = () {
		if (has(markVisitElementFun)) {
			LowExpr voidValue = genVoid(range);
			LowLocal* cur = genLocal(alloc, symbol!"cur", 2, LowType(elementPointerType));
			LowExpr getCur = genLocalGet(range, cur);
			LowLocal* end = genLocal(alloc, symbol!"end", 3, LowType(elementPointerType));
			LowExpr getEnd = genLocalGet(range, end);
			LowExpr loop = genLoop(alloc, range, voidType, genSeq(
				alloc, range,
				// mark-ctx mark-visit *cur
				genCall(alloc, range, force(markVisitElementFun), voidType, [
					getMarkCtx,
					genDerefRawPtr(alloc, range, getCur)]),
				// cur := cur + 1
				genLocalSet(alloc, range, cur, genIncrPointer(alloc, range, elementPointerType, getCur)),
				// cur == end ? break : continue
				genIf(
					alloc,
					range,
					genPtrEq(alloc, range, getCur, getEnd),
					genLoopBreak(alloc, range, voidValue),
					genLoopContinue(range))));

			LowExpr ifBody = genLet(alloc, range, cur, getData,
				genLet(alloc, range, end, genAddPtr(alloc, elementPointerType, range, getData, getSize), loop));
			return genIf(alloc, range, callMark, ifBody, voidValue);
		} else
			return genDrop(alloc, range, callMark);
	}();
	return LowFun(
		LowFunSource(allocate(alloc, LowFunSource.Generated(
			symbol!"mark-arr", newArray!LowType(alloc, [elementType])))),
		voidType,
		params,
		LowFunBody(LowFunExprBody(false, expr)));
}

private:

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
					LowExpr call = genCall(alloc, range, force(fun), voidType, [markCtx, fieldGet]);
					return some(has(accum) ? genSeq(alloc, range, force(accum), call) : call);
				} else
					return accum;
			}();
			return recur(newAccum, fieldIndex + 1);
		}
	}
	Opt!LowExpr e = recur(none!LowExpr, 0);
	return LowFunExprBody(false, has(e) ? force(e) : genVoid(range));
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
	LowFunExprBody(false, genUnionMatch(alloc, voidType, range, value, unionMembers, (size_t i, LowExpr member) {
		Opt!LowFunIndex visitMember = getMarkVisitForType(alloc, lowFunCauses, markVisitFuns, allTypes, unionMembers[i]);
		return has(visitMember)
			? genCall(alloc, range, force(visitMember), voidType, [markCtx, member])
			: genVoid(range);
	}));
