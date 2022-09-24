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
	LowType,
	matchLowType,
	UpdateParam;
import lower.lower : getMarkVisitFun, MarkVisitFuns, tryGetMarkVisitFun;
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
	genLocal,
	genLocalRef,
	genParam,
	genParamRef,
	genPtrEq,
	genRecordFieldGet,
	genSeq,
	genSizeOf,
	genTailRecur,
	genVoid,
	genWrapMulNat64,
	voidType;
import util.alloc.alloc : Alloc;
import util.col.arrUtil : arrLiteral, mapWithIndex;
import util.memory : allocate;
import util.opt : force, has, none, Opt, some;
import util.sourceRange : FileAndRange;
import util.sym : shortSym;
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
		genParam(shortSym("mark-ctx"), markCtxType),
		genParam(shortSym("value"), pointerType)]);
	immutable LowExpr markCtx = genParamRef(range, markCtxType, immutable LowParamIndex(0));
	immutable LowExpr value = genParamRef(range, pointerType, immutable LowParamIndex(1));
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
			shortSym("mark-visit"),
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
		genParam(shortSym("mark-ctx"), markCtxType),
		genParam(shortSym("value"), paramType)]);
	immutable LowExpr markCtx = genParamRef(range, markCtxType, immutable LowParamIndex(0));
	immutable LowExpr value = genParamRef(range, paramType, immutable LowParamIndex(1));
	immutable LowFunExprBody body_ =
		visitBody(alloc, range, allTypes, markVisitFuns, paramType, markCtx, value);
	return immutable LowFun(
		immutable LowFunSource(allocate(alloc, immutable LowFunSource.Generated(
			shortSym("mark-visit"),
			arrLiteral!LowType(alloc, [paramType])))),
		voidType,
		params,
		immutable LowFunBody(body_));
}

immutable(LowFun) generateMarkVisitArrInner(
	ref Alloc alloc,
	ref const MarkVisitFuns markVisitFuns,
	immutable LowType markCtxType,
	immutable LowType.PtrRawConst elementPtrType,
) {
	immutable FileAndRange range = FileAndRange.empty;
	immutable LowParam[] params = arrLiteral!LowParam(alloc, [
		genParam(shortSym("mark-ctx"), markCtxType),
		genParam(shortSym("cur"), immutable LowType(elementPtrType)),
		genParam(shortSym("end"), immutable LowType(elementPtrType))]);
	immutable LowExpr markCtxParamRef = genParamRef(range, markCtxType, immutable LowParamIndex(0));
	immutable LowExpr curParamRef = genParamRef(range, immutable LowType(elementPtrType), immutable LowParamIndex(1));
	immutable LowExpr endParamRef = genParamRef(range, immutable LowType(elementPtrType), immutable LowParamIndex(2));
	immutable LowExpr visit = genCall(
		alloc,
		range,
		getMarkVisitFun(markVisitFuns, *elementPtrType.pointee),
		voidType,
		arrLiteral!LowExpr(alloc, [
			markCtxParamRef,
			genDerefRawPtr(alloc, range, curParamRef)]));
	immutable LowExpr recur = genTailRecur(
		alloc,
		range,
		voidType,
		arrLiteral!(UpdateParam)(alloc, [immutable UpdateParam(
			immutable LowParamIndex(1),
			genIncrPointer(alloc, range, elementPtrType, curParamRef))]));
	immutable LowExpr visitAndRecur = genSeq(alloc, range, visit, recur);
	immutable LowExpr expr = genIf(
		alloc,
		range,
		genPtrEq(alloc, range, curParamRef, endParamRef),
		genVoid(range),
		visitAndRecur);
	return immutable LowFun(
		immutable LowFunSource(allocate(alloc, immutable LowFunSource.Generated(
			shortSym("mark-elems"),
			arrLiteral!LowType(alloc, [*elementPtrType.pointee])))),
		voidType,
		params,
		immutable LowFunBody(immutable LowFunExprBody(true, expr)));
}

immutable(LowFun) generateMarkVisitArrOuter(
	ref Alloc alloc,
	immutable LowType markCtxType,
	immutable LowFunIndex markFun,
	immutable LowType.Record arrType,
	immutable LowType.PtrRawConst elementPtrType,
	immutable Opt!LowFunIndex inner,
) {
	immutable LowType elementType = *elementPtrType.pointee;
	immutable FileAndRange range = FileAndRange.empty;
	immutable LowParam[] params = arrLiteral!LowParam(alloc, [
		genParam(shortSym("mark-ctx"), markCtxType),
		genParam(shortSym("a"), immutable LowType(arrType))]);
	immutable LowExpr markCtxParamRef = genParamRef(range, markCtxType, immutable LowParamIndex(0));
	immutable LowExpr aParamRef = genParamRef(range, immutable LowType(arrType), immutable LowParamIndex(1));
	immutable LowExpr getData = genGetArrData(alloc, range, aParamRef, elementPtrType);
	immutable LowExpr getSize = genGetArrSize(alloc, range, aParamRef);
	immutable LowExpr getSizeBytes = genWrapMulNat64(alloc, range, getSize, genSizeOf(range, elementType));
	immutable LowExpr getEnd = genAddPtr(alloc, elementPtrType, range, getData, getSize);
	immutable LowExpr dataAsAnyPtrConst = genAsAnyPtrConst(alloc, range, getData);
	immutable LowExpr callMark = genCall(
		alloc,
		range,
		markFun,
		boolType,
		arrLiteral!LowExpr(alloc, [markCtxParamRef, dataAsAnyPtrConst, getSizeBytes]));
	immutable LowExpr expr = () {
		if (has(inner)) {
			immutable LowExpr callInner = genCall(
				alloc,
				range,
				force(inner),
				voidType,
				arrLiteral!LowExpr(alloc, [markCtxParamRef, getData, getEnd]));
			return genIf(
				alloc,
				range,
				callMark,
				callInner,
				genVoid(range));
		} else
			return genDrop(alloc, range, callMark, 0);
	}();
	return immutable LowFun(
		immutable LowFunSource(allocate(alloc, immutable LowFunSource.Generated(
			shortSym("mark-arr"),
			arrLiteral!LowType(alloc, [elementType])))),
		voidType,
		params,
		immutable LowFunBody(immutable LowFunExprBody(false, expr)));
}

private:

//TODO:INLINE
immutable(LowFunExprBody) visitBody(
	ref Alloc alloc,
	immutable FileAndRange range,
	ref immutable AllLowTypes allTypes,
	ref const MarkVisitFuns markVisitFuns,
	immutable LowType valueType,
	ref immutable LowExpr markCtx,
	ref immutable LowExpr value,
) =>
	matchLowType!(
		immutable LowFunExprBody,
		(immutable LowType.ExternPtr) =>
			unreachable!(immutable LowFunExprBody),
		(immutable LowType.FunPtr) =>
			unreachable!(immutable LowFunExprBody),
		(immutable PrimitiveType) =>
			unreachable!(immutable LowFunExprBody),
		(immutable LowType.PtrGc) =>
			unreachable!(immutable LowFunExprBody),
		(immutable LowType.PtrRawConst) =>
			unreachable!(immutable LowFunExprBody),
		(immutable LowType.PtrRawMut) =>
			unreachable!(immutable LowFunExprBody),
		(immutable LowType.Record it) =>
			visitRecordBody(alloc, range, markVisitFuns, allTypes.allRecords[it].fields, markCtx, value),
		(immutable LowType.Union it) =>
			visitUnionBody(alloc, range, markVisitFuns, allTypes.allUnions[it].members, markCtx, value),
	)(valueType);

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
		mapWithIndex!(LowExprKind.MatchUnion.Case)(
			alloc,
			unionMembers,
			(immutable size_t memberIndex, ref immutable LowType memberType) {
				immutable Opt!LowFunIndex visitMember = tryGetMarkVisitFun(markVisitFuns, memberType);
				if (has(visitMember)) {
					immutable LowLocal* local = genLocal(
						alloc,
						shortSym("value"),
						memberIndex,
						memberType);
					immutable LowExpr getLocal = genLocalRef(alloc, range, local);
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
