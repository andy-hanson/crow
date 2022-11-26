module lower.generateCallWithCtxFun;

@safe @nogc pure nothrow:

import lower.lower : ConcreteFunToLowFunIndex;
import lower.lowExprHelpers : genLocal, genLocalGet, genParam, genParamGet;
import model.concreteModel : ConcreteLambdaImpl;
import model.lowModel :
	AllLowTypes,
	LowExpr,
	LowExprKind,
	LowFun,
	LowFunBody,
	LowFunExprBody,
	LowFunSource,
	LowLocal,
	LowParam,
	LowParamIndex,
	LowType;
import util.alloc.alloc : Alloc;
import util.col.arrUtil : mapWithFirst, mapZip, prepend;
import util.col.dict : mustGetAt;
import util.memory : allocate;
import util.opt : some;
import util.sourceRange : FileAndRange;
import util.sym : Sym, sym;
import util.util : verify;

immutable(LowFun) generateCallWithCtxFun(
	ref Alloc alloc,
	ref immutable AllLowTypes allTypes,
	scope ref immutable ConcreteFunToLowFunIndex concreteFunToLowFunIndex,
	immutable LowType returnType,
	immutable LowType funType,
	immutable LowType[] nonFunParamTypes,
	immutable ConcreteLambdaImpl[] impls,
) {
	immutable FileAndRange range = FileAndRange.empty;
	immutable LowExpr funParamGet = genParamGet(range, funType, immutable LowParamIndex(0));

	size_t localIndex = 0;

	immutable LowExprKind.MatchUnion.Case[] cases = mapZip(
		alloc,
		impls,
		allTypes.allUnions[funType.as!(LowType.Union)].members,
		(ref immutable ConcreteLambdaImpl impl, ref immutable LowType closureType) {
			immutable LowLocal* closureLocal =
				genLocal(alloc, sym!"closure", localIndex, closureType);
			localIndex = localIndex + 1;
			immutable LowExpr[] args = mapWithFirst!(LowExpr, LowType)(
				alloc,
				genLocalGet(alloc, range, closureLocal),
				nonFunParamTypes,
				(immutable size_t i, ref immutable LowType paramType) =>
					genParamGet(range, paramType, immutable LowParamIndex(i + 1)));
			immutable LowExpr then = immutable LowExpr(returnType, range, immutable LowExprKind(
				immutable LowExprKind.Call(mustGetAt(concreteFunToLowFunIndex, impl.impl), args)));
			return immutable LowExprKind.MatchUnion.Case(some(closureLocal), then);
		});

	immutable LowExpr expr = immutable LowExpr(returnType, range, immutable LowExprKind(
		allocate(alloc, immutable LowExprKind.MatchUnion(funParamGet, cases))));
	immutable LowParam[] params = mapWithFirst!(LowParam, LowType)(
		alloc,
		genParam(alloc, sym!"a", funType),
		nonFunParamTypes,
		(immutable size_t i, ref immutable LowType paramType) {
			verify(i < paramNames.length);
			return genParam(alloc, paramNames[i], paramType);
		});
	return immutable LowFun(
		//TODO: use long sym call-with-ctx
		//Or rename it in bootstrap.crow
		immutable LowFunSource(allocate(alloc, immutable LowFunSource.Generated(
			sym!"call-w-ctx",
			prepend(alloc, returnType, nonFunParamTypes)))),
		returnType,
		params,
		immutable LowFunBody(immutable LowFunExprBody(false, expr)));
}

private:

immutable Sym[] paramNames = [
	sym!"p0",
	sym!"p1",
	sym!"p2",
	sym!"p3",
	sym!"p4",
];
