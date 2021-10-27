module lower.generateCallWithCtxFun;

@safe @nogc pure nothrow:

import lower.lower : ConcreteFunToLowFunIndex;
import lower.lowExprHelpers : genLocal, localRef, paramRef;
import model.concreteModel : ConcreteLambdaImpl;
import model.lowModel :
	asUnionType,
	AllLowTypes,
	LowExpr,
	LowExprKind,
	LowFun,
	LowFunBody,
	LowFunExprBody,
	LowFunParamsKind,
	LowFunSig,
	LowFunSource,
	LowLocal,
	LowParam,
	LowParamIndex,
	LowParamSource,
	LowType;
import util.alloc.alloc : Alloc;
import util.collection.arrUtil : mapWithFirst2, mapZip, prepend;
import util.collection.dict : mustGetAt;
import util.collection.fullIndexDict : fullIndexDictGet;
import util.memory : allocate;
import util.opt : some;
import util.ptr : Ptr;
import util.sourceRange : FileAndRange;
import util.sym : shortSymAlphaLiteral, Sym;
import util.types : safeSizeTToU8;
import util.util : verify;

immutable(LowFun) generateCallWithCtxFun(
	ref Alloc alloc,
	ref immutable AllLowTypes allTypes,
	ref immutable ConcreteFunToLowFunIndex concreteFunToLowFunIndex,
	immutable LowType returnType,
	immutable LowType funType,
	ref immutable LowType ctxType,
	immutable LowType[] nonFunNonCtxParamTypes,
	immutable ConcreteLambdaImpl[] impls,
) {
	immutable FileAndRange range = FileAndRange.empty;
	immutable LowExpr funParamRef = paramRef(range, funType, immutable LowParamIndex(0));
	immutable LowExpr ctxParamRef = paramRef(range, ctxType, immutable LowParamIndex(1));

	ubyte localIndex = 0;

	immutable LowExprKind.MatchUnion.Case[] cases = mapZip(
		alloc,
		impls,
		fullIndexDictGet(allTypes.allUnions, asUnionType(funType)).members,
		(ref immutable ConcreteLambdaImpl impl, ref immutable LowType closureType) {
			immutable Ptr!LowLocal closureLocal =
				genLocal(alloc, shortSymAlphaLiteral("closure"), localIndex, closureType);
			localIndex = safeSizeTToU8(localIndex + 1);
			immutable LowExpr[] args = mapWithFirst2!(LowExpr, LowType)(
				alloc,
				ctxParamRef,
				localRef(alloc, range, closureLocal),
				nonFunNonCtxParamTypes,
				(immutable size_t i, ref immutable LowType paramType) =>
					paramRef(range, paramType, immutable LowParamIndex(i + 2)));
			immutable LowExpr then = immutable LowExpr(returnType, range, immutable LowExprKind(
				immutable LowExprKind.Call(mustGetAt(concreteFunToLowFunIndex, impl.impl), args)));
			return immutable LowExprKind.MatchUnion.Case(some(closureLocal), then);
		});

	immutable LowExpr expr = immutable LowExpr(returnType, range, immutable LowExprKind(
		allocate(alloc, immutable LowExprKind.MatchUnion(funParamRef, cases))));
	immutable LowParam[] params = mapWithFirst2!(LowParam, LowType)(
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
		//Or rename it in bootstrap.crow
		immutable LowFunSource(allocate(alloc, immutable LowFunSource.Generated(
			shortSymAlphaLiteral("call-w-ctx"),
			prepend(alloc, returnType, nonFunNonCtxParamTypes)))),
		immutable LowFunSig(returnType, immutable LowFunParamsKind(true, false), params),
		immutable LowFunBody(immutable LowFunExprBody(false, expr)));
}

private:

immutable Sym[] paramNames = [
	shortSymAlphaLiteral("p0"),
	shortSymAlphaLiteral("p1"),
	shortSymAlphaLiteral("p2"),
	shortSymAlphaLiteral("p3"),
	shortSymAlphaLiteral("p4"),
];
