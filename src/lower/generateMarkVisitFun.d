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
	LowParamSource,
	LowType,
	matchLowType;
import lower.lower : getMarkVisitFun, MarkVisitFuns, getMarkVisitFun;
import lower.lowExprHelpers :
	anyPtrType,
	boolType,
	genAsAnyPtr,
	genCall,
	genDeref,
	genIf,
	genVoid,
	getSizeOf,
	paramRef,
	recordFieldGet,
	seq,
	voidType;
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

immutable(LowFun) generateMarkVisitFun(Alloc)(
	ref Alloc alloc,
	ref immutable AllLowTypes allTypes,
	ref const MarkVisitFuns markVisitFuns,
	immutable LowType markCtxType,
	immutable LowFunIndex markFun,
	ref immutable LowType paramType,
	immutable Bool typeIsArr,
) {
	immutable FileAndRange range = FileAndRange.empty;
	immutable Arr!LowParam params = arrLiteral!LowParam(alloc, [
		immutable LowParam(
			immutable LowParamSource(immutable LowParamSource.Generated(shortSymAlphaLiteral("mark-ctx"))),
			markCtxType),
		immutable LowParam(
			immutable LowParamSource(immutable LowParamSource.Generated(shortSymAlphaLiteral("value"))),
			paramType)]);
	immutable LowExpr markCtx = paramRef(range, markCtxType, immutable LowParamIndex(0));
	immutable LowExpr value = paramRef(range, paramType, immutable LowParamIndex(1));
	immutable LowFunExprBody body_ = typeIsArr
		? arrVisitBody(alloc, range, allTypes, paramType, markCtx, value)
		: visitBody(alloc, range, allTypes, markVisitFuns, markFun, paramType, markCtx, value);
	return immutable LowFun(
		immutable LowFunSource(nu!(LowFunSource.Generated)(alloc, shortSymAlphaLiteral("mark-visit"), some(paramType))),
		nu!LowFunSig(
			alloc,
			voidType,
			immutable LowFunParamsKind(False, False),
			params),
		immutable LowFunBody(body_));
}

private:

immutable(LowFunExprBody) arrVisitBody(Alloc)(
	ref Alloc alloc,
	ref immutable FileAndRange range,
	ref immutable AllLowTypes allTypes,
	ref immutable LowType arrType,
	ref immutable LowExpr markCtx,
	ref immutable LowExpr value,
) {
	assert(0); // TODO
}

immutable(LowFunExprBody) visitBody(Alloc)(
	ref Alloc alloc,
	ref immutable FileAndRange range,
	ref immutable AllLowTypes allTypes,
	ref const MarkVisitFuns markVisitFuns,
	immutable LowFunIndex markFun,
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
		(immutable LowType.NonFunPtr it) =>
			visitNonFunPtrBody(alloc, range, markVisitFuns, markFun, it, markCtx, value),
		(immutable PrimitiveType) =>
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
		(immutable LowType.NonFunPtr) => True,
		(immutable PrimitiveType) => False,
		(immutable LowType.Record) => True,
		(immutable LowType.Union) => True);
}

immutable(LowFunExprBody) visitNonFunPtrBody(Alloc)(
	ref Alloc alloc,
	ref immutable FileAndRange range,
	ref const MarkVisitFuns markVisitFuns,
	immutable LowFunIndex markFun,
	ref immutable LowType.NonFunPtr it,
	ref immutable LowExpr markCtx,
	ref immutable LowExpr value,
) {
	immutable LowExpr sizeExpr = getSizeOf(range, it.pointee);
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
		getMarkVisitFun(markVisitFuns, it.pointee),
		voidType,
		arrLiteral!LowExpr(alloc, [markCtx, valueDeref]));
	return immutable LowFunExprBody(False, allocate(alloc, genIf(alloc, range, mark, recur, genVoid(range))));
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
