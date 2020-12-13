module lower.generateCallWithCtxFun;

@safe @nogc pure nothrow:

import lower.lower : ConcreteFunToLowFunIndex, GetLowTypeCtx, lowTypeFromConcreteType;
import lower.lowExprHelpers : genBitShiftRightNat64, genBitwiseAndNat64, paramRef, ptrCast;
import model.concreteModel : ConcreteLambdaImpl;
import model.lowModel :
	LowExpr,
	LowExprKind,
	LowFun,
	LowFunBody,
	LowFunExprBody,
	LowFunParamsKind,
	LowFunSig,
	LowFunSource,
	LowParam,
	LowParamIndex,
	LowParamSource,
	LowType;
import util.bools : False, True;
import util.collection.arr : Arr;
import util.collection.arrUtil : map, mapWithFirst2, mapWithOptFirst2, prepend;
import util.collection.dict : mustGetAt;
import util.memory : allocate, nu;
import util.opt : force, has, none, Opt, some;
import util.ptr : Ptr;
import util.sourceRange : FileAndRange;
import util.sym : shortSymAlphaLiteral, Sym;
import util.util : verify;

immutable(LowFun) generateCallWithCtxFun(Alloc)(
	ref Alloc alloc,
	ref GetLowTypeCtx getLowTypeCtx,
	ref immutable ConcreteFunToLowFunIndex concreteFunToLowFunIndex,
	immutable LowType returnType,
	immutable LowType funType,
	ref immutable LowType ctxType,
	immutable Arr!LowType nonFunNonCtxParamTypes,
	immutable Arr!ConcreteLambdaImpl impls,
) {
	immutable FileAndRange range = FileAndRange.empty;
	immutable LowExpr funParamRef = paramRef(range, funType, immutable LowParamIndex(0));
	immutable LowExpr ctxParamRef = paramRef(range, ctxType, immutable LowParamIndex(1));
	immutable LowExpr closurePtr = genBitwiseAndNat64(alloc, range, funParamRef, 0x0000ffffffffffff);
	immutable Arr!LowExpr cases = map(alloc, impls, (ref immutable ConcreteLambdaImpl impl) {
		immutable Opt!LowExpr closureArg = has(impl.closureType)
			? some(ptrCast(
				alloc,
				lowTypeFromConcreteType(alloc, getLowTypeCtx, force(impl.closureType)),
				range,
				closurePtr))
			: none!LowExpr;
		immutable Opt!LowExpr someCtxParamRef = some(ctxParamRef);
		immutable Arr!LowExpr args = mapWithOptFirst2!(LowExpr, LowType, Alloc)(
			alloc,
			someCtxParamRef,
			closureArg,
			nonFunNonCtxParamTypes,
			(immutable size_t i, immutable Ptr!LowType paramType) =>
				paramRef(range, paramType, immutable LowParamIndex(i + 2)));
		return immutable LowExpr(returnType, range, immutable LowExprKind(
			immutable LowExprKind.Call(mustGetAt(concreteFunToLowFunIndex, impl.impl), args)));
	});
	immutable LowExpr switchValue = genBitShiftRightNat64(alloc, range, funParamRef, 48);
	immutable LowExpr switch_ = immutable LowExpr(
		returnType,
		range,
		immutable LowExprKind(immutable LowExprKind.Switch(allocate(alloc, switchValue), cases)));
	immutable Arr!LowParam params = mapWithFirst2!(LowParam, LowType, Alloc)(
		alloc,
		immutable LowParam(
			immutable LowParamSource(immutable LowParamSource.Generated(shortSymAlphaLiteral("a"))),
			funType),
		immutable LowParam(
			immutable LowParamSource(immutable LowParamSource.Generated(shortSymAlphaLiteral("ctx"))),
			ctxType),
		nonFunNonCtxParamTypes,
		(immutable size_t i, ref immutable LowType paramType) {
			verify(i < paramNames.length);
			return immutable LowParam(
				immutable LowParamSource(immutable LowParamSource.Generated(paramNames[i])),
				paramType);
		});
	return immutable LowFun(
		//TODO: use long sym call-with-ctx
		//Or rename it in bootstrap.nz
		immutable LowFunSource(nu!(LowFunSource.Generated)(
			alloc,
			shortSymAlphaLiteral("call-w-ctx"),
			prepend(alloc, returnType, nonFunNonCtxParamTypes))),
		nu!LowFunSig(alloc, returnType, immutable LowFunParamsKind(True, False), params),
		immutable LowFunBody(immutable LowFunExprBody(False, allocate(alloc, switch_))));
}

private:

immutable Sym[] paramNames = [
	shortSymAlphaLiteral("p0"),
	shortSymAlphaLiteral("p1"),
	shortSymAlphaLiteral("p2"),
	shortSymAlphaLiteral("p3"),
	shortSymAlphaLiteral("p4"),
];
