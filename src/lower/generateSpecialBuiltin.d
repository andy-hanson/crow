module lower.generateSpecialBuiltin;

@safe @nogc pure nothrow:

import concretize.allConstantsBuilder : constantEmptyArr;
import lower.lower : asConcreteFun, isConcreteFun, LowFunCause, matchLowFunCause;
import lower.lowExprHelpers : anyPtrType, constantNat64, genParam, genSwitch, nat64Type, paramRef, ptrCast;
import model.concreteModel : body_, ConcreteFun, ConcreteFunSource, ConcreteFunToName, isGlobal, matchConcreteFunSource;
import model.constant : Constant;
import model.lowModel :
	LowExpr,
	LowExprKind,
	LowFun,
	LowFunExprBody,
	LowFunBody,
	LowFunIndex,
	LowFunParamsKind,
	LowFunSig,
	LowFunSource,
	LowParam,
	LowParamIndex,
	LowType;
import model.model : decl, FunInst, name;
import util.collection.arr : emptyArr, size;
import util.collection.arrUtil : arrLiteral, map, mapWithIndex;
import util.collection.dict : mustGetAt;
import util.memory : allocate, nu;
import util.opt : none, Opt, some;
import util.ptr : Ptr;
import util.sourceRange : FileAndRange;
import util.sym : shortSymAlphaLiteral, shortSymAlphaLiteralValue, Sym;
import util.util : unreachable;

enum SpecialBuiltinKind {
	allFunsCount,
	getFunName,
	getFunPtr,
}

immutable(Opt!SpecialBuiltinKind) getSpecialBuiltinKind(ref immutable ConcreteFun a) {
	return matchConcreteFunSource!(immutable Opt!SpecialBuiltinKind)(
		a.source,
		(immutable Ptr!FunInst it) {
			immutable Sym name = name(decl(it).deref());
			switch (name.value) {
				case shortSymAlphaLiteralValue("funs-count"):
					return some(SpecialBuiltinKind.allFunsCount);
				case shortSymAlphaLiteralValue("get-fun-name"):
					return some(SpecialBuiltinKind.getFunName);
				case shortSymAlphaLiteralValue("get-fun-ptr"):
					return some(SpecialBuiltinKind.getFunPtr);
				default:
					return none!SpecialBuiltinKind;
			}
		},
		(ref immutable ConcreteFunSource.Lambda) =>
			unreachable!(immutable Opt!SpecialBuiltinKind)(),
		(ref immutable ConcreteFunSource.Test) =>
			unreachable!(immutable Opt!SpecialBuiltinKind)());
}

immutable(LowFun) generateSpecialBuiltin(Alloc)(
	ref Alloc alloc,
	ref immutable ConcreteFunToName funToName,
	ref immutable LowFunCause[] lowFunCauses,
	ref immutable LowType strType,
	immutable SpecialBuiltinKind kind,
) {
	immutable FileAndRange range = FileAndRange.empty;
	final switch (kind) {
		case SpecialBuiltinKind.allFunsCount:
			return allFunsCount(alloc, range, lowFunCauses);
		case SpecialBuiltinKind.getFunName:
			return getFunName(alloc, funToName, range, lowFunCauses, strType);
		case SpecialBuiltinKind.getFunPtr:
			return getFunPtr(alloc, range, lowFunCauses);
	}
}

private:

immutable(LowFun) allFunsCount(Alloc)(
	ref Alloc alloc,
	ref immutable FileAndRange range,
	ref immutable LowFunCause[] lowFunCauses,
) {
	immutable LowExpr expr = constantNat64(range, size(lowFunCauses));
	immutable LowFunExprBody body_ = immutable LowFunExprBody(false, allocate(alloc, expr));
	return immutable LowFun(
		immutable LowFunSource(nu!(LowFunSource.Generated)(
			alloc,
			shortSymAlphaLiteral("funs-count"),
			emptyArr!LowType)),
		nu!LowFunSig(
			alloc,
			nat64Type,
			immutable LowFunParamsKind(false, false),
			emptyArr!LowParam),
		immutable LowFunBody(body_));
}

immutable(LowFun) getFunName(Alloc)(
	ref Alloc alloc,
	ref immutable ConcreteFunToName funToName,
	ref immutable FileAndRange range,
	ref immutable LowFunCause[] lowFunCauses,
	ref immutable LowType strType,
) {
	immutable LowParam[] params = arrLiteral!LowParam(alloc, [genParam(shortSymAlphaLiteral("fun-id"), nat64Type)]);
	immutable LowExpr funId = paramRef(range, nat64Type, immutable LowParamIndex(0));
	immutable LowExpr[] cases = map(alloc, lowFunCauses, (ref immutable LowFunCause cause) =>
		immutable LowExpr(strType, range, immutable LowExprKind(nameFromLowFunCause(funToName, cause))));
	immutable LowExpr expr = genSwitch(alloc, strType, range, funId, cases);
	immutable LowFunExprBody body_ = immutable LowFunExprBody(false, allocate(alloc, expr));
	return immutable LowFun(
		immutable LowFunSource(nu!(LowFunSource.Generated)(
			alloc,
			shortSymAlphaLiteral("get-fun-name"),
			emptyArr!LowType)),
		nu!LowFunSig(
			alloc,
			strType,
			immutable LowFunParamsKind(false, false),
			params),
		immutable LowFunBody(body_));
}

immutable(Constant) nameFromLowFunCause(ref immutable ConcreteFunToName funToName, ref immutable LowFunCause a) {
	return matchLowFunCause!(immutable Constant)(
		a,
		// TODO: these other causes come from ConcreteFun too, just need to pass those along..
		(ref immutable LowFunCause.CallWithCtx) =>
			constantEmptyArr(),
		(ref immutable LowFunCause.Compare) =>
			constantEmptyArr(),
		(immutable Ptr!ConcreteFun it) =>
			mustGetAt(funToName, it),
		(ref immutable LowFunCause.MarkVisitArrInner) =>
			constantEmptyArr(),
		(ref immutable LowFunCause.MarkVisitArrOuter) =>
			constantEmptyArr(),
		(ref immutable LowFunCause.MarkVisitNonArr) =>
			constantEmptyArr(),
		(ref immutable LowFunCause.MarkVisitGcPtr) =>
			constantEmptyArr(),
		(ref immutable LowFunCause.SpecialBuiltin) =>
			constantEmptyArr());
}

immutable(LowFun) getFunPtr(Alloc)(
	ref Alloc alloc,
	ref immutable FileAndRange range,
	ref immutable LowFunCause[] causes,
) {
	immutable LowParam[] params = arrLiteral!LowParam(alloc, [genParam(shortSymAlphaLiteral("fun-id"), nat64Type)]);
	immutable LowExpr funId = paramRef(range, nat64Type, immutable LowParamIndex(0));
	immutable LowExpr[] cases = mapWithIndex(alloc, causes, (immutable size_t i, ref immutable LowFunCause cause) =>
		// TODO: maybe globals shouldn't compile to functions
		isConcreteFun(cause) && isGlobal(body_(asConcreteFun(cause).deref()))
			? immutable LowExpr(anyPtrType, range, immutable LowExprKind(immutable Constant(immutable Constant.Null())))
			: ptrCast(alloc, anyPtrType, range, immutable LowExpr(anyPtrType, range, immutable LowExprKind(
				immutable LowExprKind.FunPtr(immutable LowFunIndex(i))))));
	immutable LowExpr expr = genSwitch(alloc, anyPtrType, range, funId, cases);
	immutable LowFunExprBody body_ = immutable LowFunExprBody(false, allocate(alloc, expr));
	return immutable LowFun(
		immutable LowFunSource(nu!(LowFunSource.Generated)(
			alloc,
			shortSymAlphaLiteral("get-fun-ptr"),
			emptyArr!LowType)),
		nu!LowFunSig(
			alloc,
			anyPtrType,
			immutable LowFunParamsKind(false, false),
			params),
		immutable LowFunBody(body_));
}
