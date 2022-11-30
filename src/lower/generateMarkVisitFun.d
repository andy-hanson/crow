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

immutable(LowFun) generateMarkVisitGcPtr(
	ref Alloc alloc,
	immutable LowType markCtxType,
	immutable LowFunIndex markFun,
	immutable LowType.PtrGc pointerTypePtrGc,
	immutable Opt!LowFunIndex visitPointee,
) {
	immutable LowType pointerType = immutable LowType(pointerTypePtrGc);
	immutable LowType pointeeType = *pointerTypePtrGc.pointee;
	immutable FileAndRange range = FileAndRange.empty;
	immutable LowParam[] params = arrLiteral!LowParam(alloc, [
		genParam(alloc, sym!"mark-ctx", markCtxType),
		genParam(alloc, sym!"value", pointerType)]);
	immutable LowExpr markCtx = genParamGet(range, markCtxType, immutable LowParamIndex(0));
	immutable LowExpr value = genParamGet(range, pointerType, immutable LowParamIndex(1));
	immutable LowExpr sizeExpr = genSizeOf(range, pointeeType);
	immutable LowExpr valueAsAnyPtrConst = genAsAnyPtrConst(alloc, range, value);
	immutable LowExpr mark = genCall(
		alloc,
		range,
		markFun,
		boolType,
		arrLiteral!LowExpr(alloc, [markCtx, valueAsAnyPtrConst, sizeExpr]));
	immutable LowExpr expr = () {
		if (has(visitPointee)) {
			immutable LowExpr valueDeref = genDerefGcPtr(alloc, range, value);
			immutable LowExpr recur = genCall(
				alloc,
				range,
				force(visitPointee),
				voidType,
				arrLiteral!LowExpr(alloc, [markCtx, valueDeref]));
			return genIf(alloc, range, mark, recur, genVoid(range));
		} else
			return genDrop(alloc, range, mark, 0);
	}();
	immutable LowFunExprBody body_ = immutable LowFunExprBody(false, expr);
	return immutable LowFun(
		immutable LowFunSource(allocate(alloc, immutable LowFunSource.Generated(
			sym!"mark-visit",
			arrLiteral!LowType(alloc, [pointerType])))),
		voidType,
		params,
		immutable LowFunBody(body_));
}

immutable(LowFun) generateMarkVisitNonArr(
	ref Alloc alloc,
	ref immutable AllLowTypes allTypes,
	ref const MarkVisitFuns markVisitFuns,
	immutable LowType markCtxType,
	immutable LowType paramType,
) {
	immutable FileAndRange range = FileAndRange.empty;
	immutable LowParam[] params = arrLiteral!LowParam(alloc, [
		genParam(alloc, sym!"mark-ctx", markCtxType),
		genParam(alloc, sym!"value", paramType)]);
	immutable LowExpr markCtx = genParamGet(range, markCtxType, immutable LowParamIndex(0));
	immutable LowExpr value = genParamGet(range, paramType, immutable LowParamIndex(1));
	immutable LowFunExprBody body_ = paramType.isA!(LowType.Record)
		? visitRecordBody(
			alloc, range, markVisitFuns, allTypes.allRecords[paramType.as!(LowType.Record)].fields, markCtx, value)
		: paramType.isA!(LowType.Union)
		? visitUnionBody(
			alloc, range, markVisitFuns, allTypes.allUnions[paramType.as!(LowType.Union)].members, markCtx, value)
		: unreachable!(immutable LowFunExprBody);
	return immutable LowFun(
		immutable LowFunSource(allocate(alloc, immutable LowFunSource.Generated(
			sym!"mark-visit",
			arrLiteral!LowType(alloc, [paramType])))),
		voidType,
		params,
		immutable LowFunBody(body_));
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
immutable(LowFun) generateMarkVisitArrOuter(
	ref Alloc alloc,
	immutable LowType markCtxType,
	immutable LowFunIndex markFun,
	immutable LowType.Record arrType,
	immutable LowType.PtrRawConst elementPointerType,
	immutable Opt!LowFunIndex markVisitElementFun,
) {
	immutable LowType elementType = *elementPointerType.pointee;
	immutable FileAndRange range = FileAndRange.empty;
	immutable LowParam[] params = arrLiteral!LowParam(alloc, [
		genParam(alloc, sym!"mark-ctx", markCtxType),
		genParam(alloc, sym!"a", immutable LowType(arrType))]);
	immutable LowExpr getMarkCtx = genParamGet(range, markCtxType, immutable LowParamIndex(0));
	immutable LowExpr getA = genParamGet(range, immutable LowType(arrType), immutable LowParamIndex(1));
	immutable LowExpr getData = genGetArrData(alloc, range, getA, elementPointerType);
	immutable LowExpr getSize = genGetArrSize(alloc, range, getA);
	// mark-ctx mark a.data.pointer-cast, a.size * size-of@<a>
	immutable LowExpr callMark = genCall(
		alloc,
		range,
		markFun,
		boolType,
		arrLiteral!LowExpr(alloc, [
			getMarkCtx,
			genAsAnyPtrConst(alloc, range, getData),
			genWrapMulNat64(alloc, range, getSize, genSizeOf(range, elementType))]));
	immutable LowExpr expr = () {
		if (has(markVisitElementFun)) {
			immutable LowExpr voidValue = genVoid(range);
			immutable LowLocal* cur = genLocal(alloc, sym!"cur", 0, immutable LowType(elementPointerType));
			immutable LowExpr getCur = genLocalGet(range, cur);
			immutable LowLocal* end = genLocal(alloc, sym!"end", 0, immutable LowType(elementPointerType));
			immutable LowExpr getEnd = genLocalGet(range, end);
			immutable LowExpr theLoop = genLoop(alloc, range, voidType, (immutable LowExprKind.Loop* loop) {
				// mark-ctx mark-visit *cur
				immutable LowExpr markVisitCur = genCall(
					alloc,
					range,
					force(markVisitElementFun),
					voidType,
					arrLiteral!LowExpr(alloc, [getMarkCtx, genDerefRawPtr(alloc, range, getCur)]));
				// cur := cur + 1
				immutable LowExpr incrCur = genLocalSet(alloc, range, cur,
					genIncrPointer(alloc, range, elementPointerType, getCur));
				// if cur == end \n break \n else \n continue
				immutable LowExpr breakOrContinue = genIf(
					alloc,
					range,
					genPtrEq(alloc, range, getCur, getEnd),
					genLoopBreak(alloc, range, loop, voidValue),
					genLoopContinue(range, loop));
				return genSeq(alloc, range, markVisitCur, incrCur, breakOrContinue);
			});
			immutable LowExpr ifBody = genLet(alloc, range, cur, getData,
				genLet(alloc, range, end, genAddPtr(alloc, elementPointerType, range, getData, getSize),
					theLoop));
			return genIf(alloc, range, callMark, ifBody, voidValue);			
		} else
			return genDrop(alloc, range, callMark, 0);
	}();
	return immutable LowFun(
		immutable LowFunSource(allocate(alloc, immutable LowFunSource.Generated(
			sym!"mark-arr",
			arrLiteral!LowType(alloc, [elementType])))),
		voidType,
		params,
		immutable LowFunBody(immutable LowFunExprBody(false, expr)));
}

private:

immutable(LowFunExprBody) visitRecordBody(
	ref Alloc alloc,
	immutable FileAndRange range,
	ref const MarkVisitFuns markVisitFuns,
	immutable LowField[] fields,
	ref immutable LowExpr markCtx,
	ref immutable LowExpr value,
) {
	immutable(Opt!LowExpr) recur(immutable Opt!LowExpr accum, immutable size_t fieldIndex) {
		if (fieldIndex == fields.length)
			return accum;
		else {
			immutable LowType fieldType = fields[fieldIndex].type;
			immutable Opt!LowExpr newAccum = () {
				immutable Opt!LowFunIndex fun = tryGetMarkVisitFun(markVisitFuns, fieldType);
				if (has(fun)) {
					immutable LowExpr fieldGet = genRecordFieldGet(alloc, range, value, fieldType, fieldIndex);
					immutable LowExpr call = genCall(
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
	immutable Opt!LowExpr e = recur(none!LowExpr, 0);
	return immutable LowFunExprBody(false, has(e) ? force(e) : genVoid(range));
}

immutable(LowFunExprBody) visitUnionBody(
	ref Alloc alloc,
	immutable FileAndRange range,
	ref const MarkVisitFuns markVisitFuns,
	immutable LowType[] unionMembers,
	ref immutable LowExpr markCtx,
	ref immutable LowExpr value,
) {
	immutable LowExprKind.MatchUnion.Case[] cases =
		mapWithIndex(alloc, unionMembers, (immutable size_t memberIndex, ref immutable LowType memberType) {
				immutable Opt!LowFunIndex visitMember = tryGetMarkVisitFun(markVisitFuns, memberType);
				if (has(visitMember)) {
					immutable LowLocal* local = genLocal(
						alloc,
						sym!"value",
						memberIndex,
						memberType);
					immutable LowExpr getLocal = genLocalGet(range, local);
					immutable LowExpr then = genCall(
						alloc,
						range,
						force(visitMember),
						voidType,
						arrLiteral!LowExpr(alloc, [markCtx, getLocal]));
					return immutable LowExprKind.MatchUnion.Case(some(local), then);
				} else
					return immutable LowExprKind.MatchUnion.Case(none!(LowLocal*), genVoid(range));
			});
	immutable LowExpr expr = immutable LowExpr(voidType, range, immutable LowExprKind(
		allocate(alloc, immutable LowExprKind.MatchUnion(value, cases))));
	return immutable LowFunExprBody(false, expr);
}
