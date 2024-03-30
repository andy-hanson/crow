module lower.generateMarkVisitFun;

@safe @nogc pure nothrow:

import model.lowModel :
	AllLowTypes,
	LowExpr,
	LowField,
	LowFun,
	LowFunSource,
	LowFunExprBody,
	LowFunBody,
	LowFunIndex,
	LowLocal,
	LowType;
import lower.lower : MarkVisitFuns, tryGetMarkVisitFun;
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
	voidType;
import util.alloc.alloc : Alloc;
import util.col.array : newArray;
import util.memory : allocate;
import util.opt : force, has, none, Opt, some;
import util.sourceRange : UriAndRange;
import util.symbol : symbol;

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
	ref AllLowTypes allTypes,
	in MarkVisitFuns markVisitFuns,
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
			alloc, range, markVisitFuns, allTypes.allRecords[paramType.as!(LowType.Record)].fields, markCtx, value)
		: paramType.isA!(LowType.Union)
		? visitUnionBody(
			alloc, range, markVisitFuns, allTypes.allUnions[paramType.as!(LowType.Union)].members, markCtx, value)
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
	UriAndRange range,
	in MarkVisitFuns markVisitFuns,
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
				Opt!LowFunIndex fun = tryGetMarkVisitFun(markVisitFuns, fieldType);
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
	UriAndRange range,
	in MarkVisitFuns markVisitFuns,
	LowType[] unionMembers,
	LowExpr markCtx,
	LowExpr value,
) =>
	LowFunExprBody(false, genUnionMatch(alloc, voidType, range, value, unionMembers, (size_t i, LowExpr member) {
		Opt!LowFunIndex visitMember = tryGetMarkVisitFun(markVisitFuns, unionMembers[i]);
		return has(visitMember)
			? genCall(alloc, range, force(visitMember), voidType, [markCtx, member])
			: genVoid(range);
	}));
