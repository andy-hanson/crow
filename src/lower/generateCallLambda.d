module lower.generateCallLambda;

@safe @nogc pure nothrow:

import lower.lower : MutConcreteFunToLowFunIndex, LowFunCause;
import lower.lowExprHelpers : genCall, genLocalByValue, genLocalGet, genUnionMatch;
import model.lowModel : AllLowTypes, LowExpr, LowFun, LowFunBody, LowFunExprBody, LowFunSource, LowLocal, LowType;
import util.alloc.alloc : Alloc;
import util.col.array : newArray;
import util.col.mutMap : mustGet;
import util.memory : allocate;
import util.sourceRange : UriAndRange;
import util.symbol : symbol;

LowFun generateCallLambda(
	ref Alloc alloc,
	in AllLowTypes allTypes,
	in MutConcreteFunToLowFunIndex concreteFunToLowFunIndex,
	LowFunCause.CallLambda a,
) {
	UriAndRange range = UriAndRange.empty;
	LowLocal[] params = newArray(alloc, [
		genLocalByValue(alloc, symbol!"fun", 0, a.funType),
		genLocalByValue(alloc, symbol!"arg", 1, a.funParamType),
	]);
	LowExpr funParamGet = genLocalGet(range, &params[0]);
	LowExpr argParamGet = genLocalGet(range, &params[1]);
	LowExpr expr = genUnionMatch(
		alloc, a.returnType, range, funParamGet, allTypes.allUnions[a.funType.as!(LowType.Union)].members,
		(size_t memberIndex, LowExpr asClosure) =>
			genCall(
				alloc,
				range,
				mustGet(concreteFunToLowFunIndex, a.impls[memberIndex].impl),
				a.returnType,
				[asClosure, argParamGet]));
	return LowFun(
		LowFunSource(
			allocate(alloc, LowFunSource.Generated(symbol!"call", newArray(alloc, [a.returnType, a.funParamType])))),
		a.returnType,
		params,
		// TODO: need to infer 'mayYield' from called functions! -------------------------------------------------------------
		LowFunBody(LowFunExprBody(false, false, expr)));
}
