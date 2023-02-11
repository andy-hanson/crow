module lower.generateCallWithCtxFun;

@safe @nogc pure nothrow:

import lower.lower : ConcreteFunToLowFunIndex;
import lower.lowExprHelpers : genLocal, genLocalByValue, genLocalGet;
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
	LowType;
import util.alloc.alloc : Alloc;
import util.col.arrUtil : mapPointersWithFirst, mapWithFirst, mapZip, prepend;
import util.col.dict : mustGetAt;
import util.memory : allocate;
import util.opt : some;
import util.sourceRange : FileAndRange;
import util.sym : Sym, sym;
import util.util : verify;

LowFun generateCallWithCtxFun(
	ref Alloc alloc,
	in AllLowTypes allTypes,
	in ConcreteFunToLowFunIndex concreteFunToLowFunIndex,
	LowType returnType,
	LowType funType,
	in LowType[] nonFunParamTypes,
	in ConcreteLambdaImpl[] impls,
) {
	FileAndRange range = FileAndRange.empty;
	LowLocal[] params = mapWithFirst!(LowLocal, LowType)(
		alloc, genLocalByValue(alloc, sym!"a", 0, funType), nonFunParamTypes, (size_t i, ref LowType paramType) {
			verify(i < paramNames.length);
			return genLocalByValue(alloc, paramNames[i], i + 1, paramType);
		});
	LowExpr funParamGet = genLocalGet(range, &params[0]);

	size_t localIndex = params.length;

	LowExprKind.MatchUnion.Case[] cases = mapZip(
		alloc,
		impls,
		allTypes.allUnions[funType.as!(LowType.Union)].members,
		(ref ConcreteLambdaImpl impl, ref LowType closureType) {
			LowLocal* closureLocal = genLocal(alloc, sym!"closure", localIndex, closureType);
			localIndex = localIndex + 1;
			LowExpr[] args = mapPointersWithFirst!LowExpr(
				alloc, params[1 .. $], genLocalGet(range, closureLocal), (LowLocal* param) =>
					genLocalGet(range, param));
			LowExpr then = LowExpr(returnType, range, LowExprKind(
				LowExprKind.Call(mustGetAt(concreteFunToLowFunIndex, impl.impl), args)));
			return LowExprKind.MatchUnion.Case(some(closureLocal), then);
		});

	LowExpr expr = LowExpr(returnType, range, LowExprKind(allocate(alloc, LowExprKind.MatchUnion(funParamGet, cases))));
	return LowFun(
		//TODO: use long sym call-with-ctx
		//Or rename it in bootstrap.crow
		LowFunSource(allocate(alloc, LowFunSource.Generated(
			sym!"call-w-ctx",
			prepend(alloc, returnType, nonFunParamTypes)))),
		returnType,
		params,
		LowFunBody(LowFunExprBody(false, expr)));
}

private:

immutable Sym[] paramNames = [
	sym!"p0",
	sym!"p1",
	sym!"p2",
	sym!"p3",
	sym!"p4",
];
