module lower.generateCallFunOrAct;

@safe @nogc pure nothrow:

import lower.lower : ConcreteFunToLowFunIndex, LowFunCause;
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
import util.col.arrUtil : arrLiteral, mapZip;
import util.col.map : mustGetAt;
import util.memory : allocate;
import util.opt : some;
import util.sourceRange : FileAndRange;
import util.sym : sym;

LowFun generateCallFunOrAct(
	ref Alloc alloc,
	in AllLowTypes allTypes,
	in ConcreteFunToLowFunIndex concreteFunToLowFunIndex,
	LowFunCause.CallFunOrAct a,
) {
	FileAndRange range = FileAndRange.empty;
	LowLocal[] params = arrLiteral(alloc, [
		genLocalByValue(alloc, sym!"fun", 0, a.funType),
		genLocalByValue(alloc, sym!"arg", 1, a.funParamType),
	]);
	LowExpr funParamGet = genLocalGet(range, &params[0]);
	LowExpr argParamGet = genLocalGet(range, &params[1]);
	size_t localIndex = params.length;

	LowExprKind.MatchUnion.Case[] cases = mapZip(
		alloc,
		a.impls,
		allTypes.allUnions[a.funType.as!(LowType.Union)].members,
		(ref ConcreteLambdaImpl impl, ref LowType closureType) {
			LowLocal* closureLocal = genLocal(alloc, sym!"closure", localIndex, closureType);
			localIndex = localIndex + 1;
			LowExpr then = LowExpr(a.returnType, range, LowExprKind(
				LowExprKind.Call(
					mustGetAt(concreteFunToLowFunIndex, impl.impl),
					arrLiteral(alloc, [genLocalGet(range, closureLocal), argParamGet]))));
			return LowExprKind.MatchUnion.Case(some(closureLocal), then);
		});

	LowExpr expr = LowExpr(a.returnType, range, LowExprKind(
		allocate(alloc, LowExprKind.MatchUnion(funParamGet, cases))));
	return LowFun(
		LowFunSource(
			allocate(alloc, LowFunSource.Generated(sym!"call", arrLiteral(alloc, [a.returnType, a.funParamType])))),
		a.returnType,
		params,
		LowFunBody(LowFunExprBody(false, expr)));
}
