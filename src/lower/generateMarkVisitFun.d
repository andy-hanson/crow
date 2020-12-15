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
	LowFunParamsKind,
	LowFunSig,
	LowParam,
	LowParamIndex,
	LowType,
	matchLowType;
import lower.lower : getMarkVisitFun, MarkVisitFuns, getMarkVisitFun;
import lower.lowExprHelpers :
	anyPtrType,
	boolType,
	genAddPtr,
	genAsAnyPtr,
	genCall,
	genDeref,
	genGetArrData,
	genGetArrSize,
	genIf,
	genParam,
	genPtrEq,
	genVoid,
	genTailRecur,
	getSizeOf,
	incrPointer,
	paramRef,
	recordFieldGet,
	seq,
	voidType,
	wrapMulNat64;
import util.bools : Bool, False, True;
import util.collection.arr : Arr, at, size;
import util.collection.arrUtil : arrLiteral;
import util.collection.fullIndexDict : fullIndexDictGet;
import util.memory : allocate, nu;
import util.opt : force, has, none, Opt, some;
import util.sourceRange : FileAndRange;
import util.sym : shortSymAlphaLiteral;
import util.types : safeIncrU8;
import util.util : unreachable;

immutable(LowFun) generateMarkVisitGcPtr(Alloc)(
	ref Alloc alloc,
	ref immutable LowType markCtxType,
	immutable LowFunIndex markFun,
	immutable LowType.PtrGc pointerTypePtrGc,
	immutable LowFunIndex visitPointee,
) {
	immutable LowType pointerType = immutable LowType(pointerTypePtrGc);
	immutable LowType pointeeType = pointerTypePtrGc.pointee;
	immutable FileAndRange range = FileAndRange.empty;
	immutable Arr!LowParam params = arrLiteral!LowParam(alloc, [
		genParam(shortSymAlphaLiteral("mark-ctx"), markCtxType),
		genParam(shortSymAlphaLiteral("value"), pointerType)]);
	immutable LowExpr markCtx = paramRef(range, markCtxType, immutable LowParamIndex(0));
	immutable LowExpr value = paramRef(range, pointerType, immutable LowParamIndex(1));
	immutable LowExpr sizeExpr = getSizeOf(range, pointeeType);
	immutable LowExpr valueAsAnyPtr = genAsAnyPtr(alloc, anyPtrType, range, value);
	immutable LowExpr mark = genCall(
		alloc,
		range,
		markFun,
		boolType,
		arrLiteral!LowExpr(alloc, [markCtx, valueAsAnyPtr, sizeExpr]));
	immutable LowExpr valueDeref = genDeref(alloc, range, value);
	immutable LowExpr recur = genCall(
		alloc,
		range,
		visitPointee,
		voidType,
		arrLiteral!LowExpr(alloc, [markCtx, valueDeref]));
	immutable LowFunExprBody body_ =
		immutable LowFunExprBody(False, allocate(alloc, genIf(alloc, range, mark, recur, genVoid(range))));
	return immutable LowFun(
		immutable LowFunSource(nu!(LowFunSource.Generated)(
			alloc,
			shortSymAlphaLiteral("mark-visit"),
			arrLiteral!LowType(alloc, [pointerType]))),
		nu!LowFunSig(
			alloc,
			voidType,
			immutable LowFunParamsKind(False, False),
			params),
		immutable LowFunBody(body_));
}

immutable(LowFun) generateMarkVisitNonArr(Alloc)(
	ref Alloc alloc,
	ref immutable AllLowTypes allTypes,
	ref const MarkVisitFuns markVisitFuns,
	ref immutable LowType markCtxType,
	ref immutable LowType paramType,
) {
	immutable FileAndRange range = FileAndRange.empty;
	immutable Arr!LowParam params = arrLiteral!LowParam(alloc, [
		genParam(shortSymAlphaLiteral("mark-ctx"), markCtxType),
		genParam(shortSymAlphaLiteral("value"), paramType)]);
	immutable LowExpr markCtx = paramRef(range, markCtxType, immutable LowParamIndex(0));
	immutable LowExpr value = paramRef(range, paramType, immutable LowParamIndex(1));
	immutable LowFunExprBody body_ =
		visitBody(alloc, range, allTypes, markVisitFuns, paramType, markCtx, value);
	return immutable LowFun(
		immutable LowFunSource(nu!(LowFunSource.Generated)(
			alloc,
			shortSymAlphaLiteral("mark-visit"),
			arrLiteral!LowType(alloc, [paramType]))),
		nu!LowFunSig(
			alloc,
			voidType,
			immutable LowFunParamsKind(False, False),
			params),
		immutable LowFunBody(body_));
}

immutable(LowFun) generateMarkVisitArrInner(Alloc)(
	ref Alloc alloc,
	ref const MarkVisitFuns markVisitFuns,
	ref immutable LowType markCtxType,
	immutable LowType.PtrRaw elementPtrType,
) {
	immutable FileAndRange range = FileAndRange.empty;
	immutable Arr!LowParam params = arrLiteral!LowParam(alloc, [
		genParam(shortSymAlphaLiteral("mark-ctx"), markCtxType),
		genParam(shortSymAlphaLiteral("cur"), immutable LowType(elementPtrType)),
		genParam(shortSymAlphaLiteral("end"), immutable LowType(elementPtrType))]);
	immutable LowExpr markCtxParamRef = paramRef(range, markCtxType, immutable LowParamIndex(0));
	immutable LowExpr curParamRef = paramRef(range, immutable LowType(elementPtrType), immutable LowParamIndex(1));
	immutable LowExpr endParamRef = paramRef(range, immutable LowType(elementPtrType), immutable LowParamIndex(2));
	immutable LowExpr visit = genCall(
		alloc,
		range,
		getMarkVisitFun(markVisitFuns, elementPtrType.pointee),
		voidType,
		arrLiteral!LowExpr(alloc, [
			markCtxParamRef,
			genDeref(alloc, range, curParamRef)]));
	immutable LowExpr recur = genTailRecur(alloc, range, voidType, arrLiteral!LowExpr(alloc, [
		markCtxParamRef,
		incrPointer(alloc, range, elementPtrType, curParamRef),
		endParamRef]));
	immutable LowExpr visitAndRecur = seq(alloc, range, visit, recur);
	immutable LowExpr expr = genIf(
		alloc,
		range,
		genPtrEq(alloc, range, curParamRef, endParamRef),
		genVoid(range),
		visitAndRecur);
	return immutable LowFun(
		immutable LowFunSource(nu!(LowFunSource.Generated)(
			alloc,
			shortSymAlphaLiteral("mark-elements"),
			arrLiteral!LowType(alloc, [elementPtrType.pointee]))),
		nu!LowFunSig(
			alloc,
			voidType,
			immutable LowFunParamsKind(False, False),
			params),
		immutable LowFunBody(immutable LowFunExprBody(True, allocate(alloc, expr))));
}

immutable(LowFun) generateMarkVisitArrOuter(Alloc)(
	ref Alloc alloc,
	ref immutable LowType markCtxType,
	immutable LowFunIndex markFun,
	immutable LowType.Record arrType,
	immutable LowType.PtrRaw elementPtrType,
	immutable LowFunIndex inner,
) {
	immutable LowType elementType = elementPtrType.pointee;
	immutable FileAndRange range = FileAndRange.empty;
	immutable Arr!LowParam params = arrLiteral!LowParam(alloc, [
		genParam(shortSymAlphaLiteral("mark-ctx"), markCtxType),
		genParam(shortSymAlphaLiteral("a"), immutable LowType(arrType))]);
	immutable LowExpr markCtxParamRef = paramRef(range, markCtxType, immutable LowParamIndex(0));
	immutable LowExpr aParamRef = paramRef(range, immutable LowType(arrType), immutable LowParamIndex(1));
	immutable LowExpr getData = genGetArrData(alloc, range, aParamRef, elementPtrType);
	immutable LowExpr getSize = genGetArrSize(alloc, range, aParamRef);
	immutable LowExpr getSizeBytes = wrapMulNat64(alloc, range, getSize, getSizeOf(range, elementType));
	immutable LowExpr getEnd = genAddPtr(alloc, elementPtrType, range, getData, getSize);
	immutable LowExpr callMark = genCall(
		alloc,
		range,
		markFun,
		boolType,
		arrLiteral!LowExpr(alloc, [markCtxParamRef, getData, getSizeBytes]));
	immutable LowExpr callInner = genCall(
		alloc,
		range,
		inner,
		voidType,
		arrLiteral!LowExpr(alloc, [markCtxParamRef, getData, getEnd]));
	immutable LowExpr expr = genIf!Alloc(
		alloc,
		range,
		callMark,
		callInner,
		genVoid(range));
	return immutable LowFun(
		immutable LowFunSource(nu!(LowFunSource.Generated)(
			alloc,
			shortSymAlphaLiteral("mark-visit"),
			arrLiteral!LowType(alloc, [elementType]))),
		nu!LowFunSig(
			alloc,
			voidType,
			immutable LowFunParamsKind(False, False),
			params),
		immutable LowFunBody(immutable LowFunExprBody(False, allocate(alloc, expr))));
}

private:

//TODO:INLINE
immutable(LowFunExprBody) visitBody(Alloc)(
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
		(immutable LowType.PtrGc it) =>
			unreachable!(immutable LowFunExprBody),
		(immutable LowType.PtrRaw it) =>
			unreachable!(immutable LowFunExprBody),
		(immutable LowType.Record it) =>
			visitRecordBody!Alloc(
				alloc,
				range,
				markVisitFuns,
				fullIndexDictGet(allTypes.allRecords, it).fields,
				markCtx,
				value),
		(immutable LowType.Union it) =>
			visitUnionBody(alloc, range, it, markCtx, value));
}

immutable(Bool) mayVisit(ref immutable LowType a) {
	return matchLowType!(immutable Bool)(
		a,
		(immutable LowType.ExternPtr) => False,
		(immutable LowType.FunPtr) => False,
		(immutable PrimitiveType) => False,
		(immutable LowType.PtrGc) => True,
		(immutable LowType.PtrRaw) => False,
		(immutable LowType.Record) => True,
		(immutable LowType.Union) => True);
}

immutable(LowFunExprBody) visitRecordBody(Alloc)(
	ref Alloc alloc,
	ref immutable FileAndRange range,
	ref const MarkVisitFuns markVisitFuns,
	immutable Arr!LowField fields,
	ref immutable LowExpr markCtx,
	ref immutable LowExpr value,
) {
	immutable(Opt!LowExpr) recur(immutable Opt!LowExpr accum, immutable ubyte fieldIndex) {
		if (fieldIndex == size(fields))
			return accum;
		else {
			immutable LowType fieldType = at(fields, fieldIndex).type;
			immutable Opt!LowExpr newAccum = () {
				if (mayVisit(fieldType)) {
					immutable LowFunIndex fun = getMarkVisitFun(markVisitFuns, fieldType);
					immutable LowExpr fieldGet = recordFieldGet!Alloc(alloc, range, value, fieldType, fieldIndex);
					immutable LowExpr call = genCall(
						alloc,
						range,
						fun,
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
	return immutable LowFunExprBody(False, allocate(alloc, has(e) ? force(e) : genVoid(range)));
}

immutable(LowFunExprBody) visitUnionBody(Alloc)(
	ref Alloc, //alloc,
	ref immutable FileAndRange,// range,
	immutable LowType.Union,
	ref immutable LowExpr, //markCtx,
	ref immutable LowExpr, //value,
) {
	assert(0); //TODO
}
