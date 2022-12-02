module lower.generateMarkVisitFun;

@safe @nogc pure nothrow:

import model.lowModel :
	AllLowTypes,
	LowExpr,
	LowExprKind,
	LowField,
	LowFun,
	LowFunSource,
	LowFunExprBody,
	LowFunBody,
	LowFunIndex,
	LowLocal,
	LowParam,
	LowParamIndex,
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
	genLocalGet,
	genLocalSet,
	genLoop,
	genLoopBreak,
	genLoopContinue,
	genParam,
	genParamGet,
	genPtrEq,
	genRecordFieldGet,
	genSeq,
	genSizeOf,
	genVoid,
	genWrapMulNat64,
	voidType;
import util.alloc.alloc : Alloc;
import util.col.arrUtil : arrLiteral, mapWithIndex;
import util.memory : allocate;
import util.opt : force, has, none, Opt, some;
import util.sourceRange : FileAndRange;
import util.sym : sym;
import util.util : unreachable;

LowFun generateMarkVisitGcPtr(
	ref Alloc alloc,
	LowType markCtxType,
	LowFunIndex markFun,
	LowType.PtrGc pointerTypePtrGc,
	Opt!LowFunIndex visitPointee,
) {
	LowType pointerType = LowType(pointerTypePtrGc);
	LowType pointeeType = *pointerTypePtrGc.pointee;
	FileAndRange range = FileAndRange.empty;
	LowParam[] params = arrLiteral!LowParam(alloc, [
		genParam(alloc, sym!"mark-ctx", markCtxType),
		genParam(alloc, sym!"value", pointerType)]);
	LowExpr markCtx = genParamGet(range, markCtxType, LowParamIndex(0));
	LowExpr value = genParamGet(range, pointerType, LowParamIndex(1));
	LowExpr sizeExpr = genSizeOf(range, pointeeType);
	LowExpr valueAsAnyPtrConst = genAsAnyPtrConst(alloc, range, value);
	LowExpr mark = genCall(
		alloc,
		range,
		markFun,
		boolType,
		arrLiteral!LowExpr(alloc, [markCtx, valueAsAnyPtrConst, sizeExpr]));
	LowExpr expr = () {
		if (has(visitPointee)) {
			LowExpr valueDeref = genDerefGcPtr(alloc, range, value);
			LowExpr recur = genCall(
				alloc,
				range,
				force(visitPointee),
				voidType,
				arrLiteral!LowExpr(alloc, [markCtx, valueDeref]));
			return genIf(alloc, range, mark, recur, genVoid(range));
		} else
			return genDrop(alloc, range, mark, 0);
	}();
	LowFunExprBody body_ = LowFunExprBody(false, expr);
	return LowFun(
		LowFunSource(allocate(alloc, LowFunSource.Generated(
			sym!"mark-visit",
			arrLiteral!LowType(alloc, [pointerType])))),
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
	FileAndRange range = FileAndRange.empty;
	LowParam[] params = arrLiteral!LowParam(alloc, [
		genParam(alloc, sym!"mark-ctx", markCtxType),
		genParam(alloc, sym!"value", paramType)]);
	LowExpr markCtx = genParamGet(range, markCtxType, LowParamIndex(0));
	LowExpr value = genParamGet(range, paramType, LowParamIndex(1));
	LowFunExprBody body_ = paramType.isA!(LowType.Record)
		? visitRecordBody(
			alloc, range, markVisitFuns, allTypes.allRecords[paramType.as!(LowType.Record)].fields, markCtx, value)
		: paramType.isA!(LowType.Union)
		? visitUnionBody(
			alloc, range, markVisitFuns, allTypes.allUnions[paramType.as!(LowType.Union)].members, markCtx, value)
		: unreachable!LowFunExprBody;
	return LowFun(
		LowFunSource(allocate(alloc, LowFunSource.Generated(sym!"mark-visit", arrLiteral!LowType(alloc, [paramType])))),
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
	LowType markCtxType,
	LowFunIndex markFun,
	LowType.Record arrType,
	LowType.PtrRawConst elementPointerType,
	Opt!LowFunIndex markVisitElementFun,
) {
	LowType elementType = *elementPointerType.pointee;
	FileAndRange range = FileAndRange.empty;
	LowParam[] params = arrLiteral!LowParam(alloc, [
		genParam(alloc, sym!"mark-ctx", markCtxType),
		genParam(alloc, sym!"a", LowType(arrType))]);
	LowExpr getMarkCtx = genParamGet(range, markCtxType, LowParamIndex(0));
	LowExpr getA = genParamGet(range, LowType(arrType), LowParamIndex(1));
	LowExpr getData = genGetArrData(alloc, range, getA, elementPointerType);
	LowExpr getSize = genGetArrSize(alloc, range, getA);
	// mark-ctx mark a.data.pointer-cast, a.size * size-of@<a>
	LowExpr callMark = genCall(
		alloc,
		range,
		markFun,
		boolType,
		arrLiteral!LowExpr(alloc, [
			getMarkCtx,
			genAsAnyPtrConst(alloc, range, getData),
			genWrapMulNat64(alloc, range, getSize, genSizeOf(range, elementType))]));
	LowExpr expr = () {
		if (has(markVisitElementFun)) {
			LowExpr voidValue = genVoid(range);
			LowLocal* cur = genLocal(alloc, sym!"cur", 0, LowType(elementPointerType));
			LowExpr getCur = genLocalGet(range, cur);
			LowLocal* end = genLocal(alloc, sym!"end", 0, LowType(elementPointerType));
			LowExpr getEnd = genLocalGet(range, end);
			LowExpr theLoop = genLoop(alloc, range, voidType, (LowExprKind.Loop* loop) {
				// mark-ctx mark-visit *cur
				LowExpr markVisitCur = genCall(
					alloc,
					range,
					force(markVisitElementFun),
					voidType,
					arrLiteral!LowExpr(alloc, [getMarkCtx, genDerefRawPtr(alloc, range, getCur)]));
				// cur := cur + 1
				LowExpr incrCur = genLocalSet(alloc, range, cur,
					genIncrPointer(alloc, range, elementPointerType, getCur));
				// if cur == end \n break \n else \n continue
				LowExpr breakOrContinue = genIf(
					alloc,
					range,
					genPtrEq(alloc, range, getCur, getEnd),
					genLoopBreak(alloc, range, loop, voidValue),
					genLoopContinue(range, loop));
				return genSeq(alloc, range, markVisitCur, incrCur, breakOrContinue);
			});
			LowExpr ifBody = genLet(alloc, range, cur, getData,
				genLet(alloc, range, end, genAddPtr(alloc, elementPointerType, range, getData, getSize),
					theLoop));
			return genIf(alloc, range, callMark, ifBody, voidValue);			
		} else
			return genDrop(alloc, range, callMark, 0);
	}();
	return LowFun(
		LowFunSource(allocate(alloc, LowFunSource.Generated(sym!"mark-arr", arrLiteral!LowType(alloc, [elementType])))),
		voidType,
		params,
		LowFunBody(LowFunExprBody(false, expr)));
}

private:

LowFunExprBody visitRecordBody(
	ref Alloc alloc,
	FileAndRange range,
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
					LowExpr call = genCall(
						alloc,
						range,
						force(fun),
						voidType,
						arrLiteral!LowExpr(alloc, [markCtx, fieldGet]));
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
	FileAndRange range,
	in MarkVisitFuns markVisitFuns,
	LowType[] unionMembers,
	LowExpr markCtx,
	LowExpr value,
) {
	LowExprKind.MatchUnion.Case[] cases = mapWithIndex!(LowExprKind.MatchUnion.Case, LowType)(
		alloc, unionMembers, (size_t memberIndex, ref LowType memberType) {
			Opt!LowFunIndex visitMember = tryGetMarkVisitFun(markVisitFuns, memberType);
			if (has(visitMember)) {
				LowLocal* local = genLocal(
					alloc,
					sym!"value",
					memberIndex,
					memberType);
				LowExpr getLocal = genLocalGet(range, local);
				LowExpr then = genCall(
					alloc,
					range,
					force(visitMember),
					voidType,
					arrLiteral!LowExpr(alloc, [markCtx, getLocal]));
				return LowExprKind.MatchUnion.Case(some(local), then);
			} else
				return LowExprKind.MatchUnion.Case(none!(LowLocal*), genVoid(range));
		});
	return LowFunExprBody(
		false,
		LowExpr(voidType, range, LowExprKind(allocate(alloc, LowExprKind.MatchUnion(value, cases)))));
}
