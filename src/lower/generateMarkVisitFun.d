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
	LowFunParamsKind,
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
	genLocal,
	genParam,
	genPtrEq,
	genVoid,
	genTailRecur,
	getSizeOf,
	incrPointer,
	localRef,
	paramRef,
	recordFieldGet,
	seq,
	voidType,
	wrapMulNat64;
import util.alloc.alloc : Alloc;
import util.collection.arr : at, size;
import util.collection.arrUtil : arrLiteral, mapWithIndex;
import util.collection.fullIndexDict : fullIndexDictGet;
import util.memory : allocate;
import util.opt : force, has, none, Opt, some;
import util.ptr : Ptr;
import util.sourceRange : FileAndRange;
import util.sym : shortSymAlphaLiteral;
import util.types : safeIncrU8, safeSizeTToU8;
import util.util : unreachable;

immutable(LowFun) generateMarkVisitGcPtr(
	ref Alloc alloc,
	ref immutable LowType markCtxType,
	immutable LowFunIndex markFun,
	immutable LowType.PtrGc pointerTypePtrGc,
	immutable Opt!LowFunIndex visitPointee,
) {
	immutable LowType pointerType = immutable LowType(pointerTypePtrGc);
	immutable LowType pointeeType = pointerTypePtrGc.pointee.deref();
	immutable FileAndRange range = FileAndRange.empty;
	immutable LowParam[] params = arrLiteral!LowParam(alloc, [
		genParam(shortSymAlphaLiteral("mark-ctx"), markCtxType),
		genParam(shortSymAlphaLiteral("value"), pointerType)]);
	immutable LowExpr markCtx = paramRef(range, markCtxType, immutable LowParamIndex(0));
	immutable LowExpr value = paramRef(range, pointerType, immutable LowParamIndex(1));
	immutable LowExpr sizeExpr = getSizeOf(range, pointeeType);
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
			shortSymAlphaLiteral("mark-visit"),
			arrLiteral!LowType(alloc, [pointerType])))),
		voidType,
		immutable LowFunParamsKind(false, false),
		params,
		immutable LowFunBody(body_));
}

immutable(LowFun) generateMarkVisitNonArr(
	ref Alloc alloc,
	ref immutable AllLowTypes allTypes,
	ref const MarkVisitFuns markVisitFuns,
	ref immutable LowType markCtxType,
	ref immutable LowType paramType,
) {
	immutable FileAndRange range = FileAndRange.empty;
	immutable LowParam[] params = arrLiteral!LowParam(alloc, [
		genParam(shortSymAlphaLiteral("mark-ctx"), markCtxType),
		genParam(shortSymAlphaLiteral("value"), paramType)]);
	immutable LowExpr markCtx = paramRef(range, markCtxType, immutable LowParamIndex(0));
	immutable LowExpr value = paramRef(range, paramType, immutable LowParamIndex(1));
	immutable LowFunExprBody body_ =
		visitBody(alloc, range, allTypes, markVisitFuns, paramType, markCtx, value);
	return immutable LowFun(
		immutable LowFunSource(allocate(alloc, immutable LowFunSource.Generated(
			shortSymAlphaLiteral("mark-visit"),
			arrLiteral!LowType(alloc, [paramType])))),
		voidType,
		immutable LowFunParamsKind(false, false),
		params,
		immutable LowFunBody(body_));
}

immutable(LowFun) generateMarkVisitArrInner(
	ref Alloc alloc,
	ref const MarkVisitFuns markVisitFuns,
	ref immutable LowType markCtxType,
	immutable LowType.PtrRawConst elementPtrType,
) {
	immutable FileAndRange range = FileAndRange.empty;
	immutable LowParam[] params = arrLiteral!LowParam(alloc, [
		genParam(shortSymAlphaLiteral("mark-ctx"), markCtxType),
		genParam(shortSymAlphaLiteral("cur"), immutable LowType(elementPtrType)),
		genParam(shortSymAlphaLiteral("end"), immutable LowType(elementPtrType))]);
	immutable LowExpr markCtxParamRef = paramRef(range, markCtxType, immutable LowParamIndex(0));
	immutable LowExpr curParamRef = paramRef(range, immutable LowType(elementPtrType), immutable LowParamIndex(1));
	immutable LowExpr endParamRef = paramRef(range, immutable LowType(elementPtrType), immutable LowParamIndex(2));
	immutable LowExpr visit = genCall(
		alloc,
		range,
		getMarkVisitFun(markVisitFuns, elementPtrType.pointee.deref()),
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
			incrPointer(alloc, range, elementPtrType, curParamRef))]));
	immutable LowExpr visitAndRecur = seq(alloc, range, visit, recur);
	immutable LowExpr expr = genIf(
		alloc,
		range,
		genPtrEq(alloc, range, curParamRef, endParamRef),
		genVoid(range),
		visitAndRecur);
	return immutable LowFun(
		immutable LowFunSource(allocate(alloc, immutable LowFunSource.Generated(
			shortSymAlphaLiteral("mark-elems"),
			arrLiteral!LowType(alloc, [elementPtrType.pointee.deref()])))),
		voidType,
		immutable LowFunParamsKind(false, false),
		params,
		immutable LowFunBody(immutable LowFunExprBody(true, expr)));
}

immutable(LowFun) generateMarkVisitArrOuter(
	ref Alloc alloc,
	ref immutable LowType markCtxType,
	immutable LowFunIndex markFun,
	immutable LowType.Record arrType,
	immutable LowType.PtrRawConst elementPtrType,
	immutable Opt!LowFunIndex inner,
) {
	immutable LowType elementType = elementPtrType.pointee.deref();
	immutable FileAndRange range = FileAndRange.empty;
	immutable LowParam[] params = arrLiteral!LowParam(alloc, [
		genParam(shortSymAlphaLiteral("mark-ctx"), markCtxType),
		genParam(shortSymAlphaLiteral("a"), immutable LowType(arrType))]);
	immutable LowExpr markCtxParamRef = paramRef(range, markCtxType, immutable LowParamIndex(0));
	immutable LowExpr aParamRef = paramRef(range, immutable LowType(arrType), immutable LowParamIndex(1));
	immutable LowExpr getData = genGetArrData(alloc, range, aParamRef, elementPtrType);
	immutable LowExpr getSize = genGetArrSize(alloc, range, aParamRef);
	immutable LowExpr getSizeBytes = wrapMulNat64(alloc, range, getSize, getSizeOf(range, elementType));
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
			shortSymAlphaLiteral("mark-arr"),
			arrLiteral!LowType(alloc, [elementType])))),
		voidType,
		immutable LowFunParamsKind(false, false),
		params,
		immutable LowFunBody(immutable LowFunExprBody(false, expr)));
}

private:

//TODO:INLINE
immutable(LowFunExprBody) visitBody(
	ref Alloc alloc,
	ref immutable FileAndRange range,
	ref immutable AllLowTypes allTypes,
	ref const MarkVisitFuns markVisitFuns,
	ref immutable LowType valueType,
	ref immutable LowExpr markCtx,
	ref immutable LowExpr value,
) {
	return matchLowType!(immutable LowFunExprBody)(
		valueType,
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
			visitRecordBody(
				alloc,
				range,
				markVisitFuns,
				fullIndexDictGet(allTypes.allRecords, it).fields,
				markCtx,
				value),
		(immutable LowType.Union it) =>
			visitUnionBody(
				alloc,
				range,
				markVisitFuns,
				fullIndexDictGet(allTypes.allUnions, it).members,
				markCtx,
				value));
}

immutable(LowFunExprBody) visitRecordBody(
	ref Alloc alloc,
	ref immutable FileAndRange range,
	ref const MarkVisitFuns markVisitFuns,
	immutable LowField[] fields,
	ref immutable LowExpr markCtx,
	ref immutable LowExpr value,
) {
	immutable(Opt!LowExpr) recur(immutable Opt!LowExpr accum, immutable ubyte fieldIndex) {
		if (fieldIndex == size(fields))
			return accum;
		else {
			immutable LowType fieldType = at(fields, fieldIndex).type;
			immutable Opt!LowExpr newAccum = () {
				immutable Opt!LowFunIndex fun = tryGetMarkVisitFun(markVisitFuns, fieldType);
				if (has(fun)) {
					immutable LowExpr fieldGet = recordFieldGet(alloc, range, value, fieldType, fieldIndex);
					immutable LowExpr call = genCall(
						alloc,
						range,
						force(fun),
						voidType,
						arrLiteral!LowExpr(alloc, [markCtx, fieldGet]));
					return some(has(accum) ? seq(alloc, range, force(accum), call) : call);
				} else
					return accum;
			}();
			return recur(newAccum, safeIncrU8(fieldIndex));
		}
	}
	immutable Opt!LowExpr e = recur(none!LowExpr, 0);
	return immutable LowFunExprBody(false, has(e) ? force(e) : genVoid(range));
}

immutable(LowFunExprBody) visitUnionBody(
	ref Alloc alloc,
	ref immutable FileAndRange range,
	ref const MarkVisitFuns markVisitFuns,
	ref immutable LowType[] unionMembers,
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
					immutable Ptr!LowLocal local = genLocal(
						alloc,
						shortSymAlphaLiteral("value"),
						safeSizeTToU8(memberIndex),
						memberType);
					immutable LowExpr getLocal = localRef(alloc, range, local);
					immutable LowExpr then = genCall(
						alloc,
						range,
						force(visitMember),
						voidType,
						arrLiteral!LowExpr(alloc, [markCtx, getLocal]));
					return immutable LowExprKind.MatchUnion.Case(some(local), then);
				} else
					return immutable LowExprKind.MatchUnion.Case(none!(Ptr!LowLocal), genVoid(range));
			});
	immutable LowExpr expr = immutable LowExpr(voidType, range, immutable LowExprKind(
		allocate(alloc, immutable LowExprKind.MatchUnion(value, cases))));
	return immutable LowFunExprBody(false, expr);
}
