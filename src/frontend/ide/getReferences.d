module frontend.ide.getReferences;

@safe @nogc pure nothrow:

import frontend.ide.getTarget : exprTarget, Target, targetForPosition;
import frontend.ide.position : Position, PositionKind;
import model.model :
	eachDescendentExprExcluding,
	eachDescendentExprIncluding,
	Expr,
	ExprKind,
	FunBody,
	FunDecl,
	localMustHaveNameRange,
	loopKeywordRange,
	Module,
	Program,
	range,
	RecordField,
	SpecDecl,
	SpecDeclSig,
	StructDecl,
	TypeParam;
import util.alloc.alloc : Alloc;
import util.col.arrBuilder : add, ArrBuilder, finishArr;
import util.json : Json, jsonList;
import util.lineAndColumnGetter : LineAndColumnGetters;
import util.opt : force, has, Opt, optEqual, some;
import util.ptr : ptrTrustMe;
import util.sourceRange : UriAndRange, jsonOfUriAndRange;
import util.sym : AllSymbols;
import util.uri : AllUris, Uri;
import util.util : typeAs;

UriAndRange[] getReferencesForPosition(ref Alloc alloc, in AllSymbols allSymbols, in Program program, in Position pos) {
	Opt!Target target = targetForPosition(program, pos.kind);
	return has(target) ? referencesForTarget(alloc, allSymbols, program, pos.module_.uri, force(target)) : [];
}

Json jsonOfReferences(
	ref Alloc alloc,
	in AllUris allUris,
	scope ref LineAndColumnGetters lineAndColumnGetters,
	in UriAndRange[] references,
) =>
	jsonList!UriAndRange(alloc, references, (in UriAndRange x) =>
		jsonOfUriAndRange(alloc, allUris, lineAndColumnGetters, x));

private:

UriAndRange[] referencesForTarget(
	ref Alloc alloc,
	in AllSymbols allSymbols,
	in Program program,
	Uri curUri,
	in Target a,
) =>
	a.matchIn!(UriAndRange[])(
		(in FunDecl x) =>
			// TODO
			typeAs!(UriAndRange[])([]),
		(in Target.LocalInFunction x) =>
			localReferences(alloc, allSymbols, program, curUri, x),
		(in ExprKind.Loop x) =>
			loopReferences(alloc, curUri, x),
		(in Module x) =>
			// TODO
			typeAs!(UriAndRange[])([]),
		(in RecordField x) =>
			// TODO (get references for the get/set functions)
			typeAs!(UriAndRange[])([]),
		(in SpecDecl x) =>
			// TODO (search all functions)
			typeAs!(UriAndRange[])([]),
		(in SpecDeclSig x) =>
			// TODO (find call references)
			typeAs!(UriAndRange[])([]),
		(in StructDecl x) =>
			// TODO
			typeAs!(UriAndRange[])([]),
		(in TypeParam x) =>
			// TODO
			typeAs!(UriAndRange[])([]));

UriAndRange[] localReferences(
	ref Alloc alloc,
	in AllSymbols allSymbols,
	in Program program,
	Uri curUri,
	in Target.LocalInFunction a,
) {
	ArrBuilder!UriAndRange res;
	add(alloc, res, localMustHaveNameRange(*a.local, allSymbols));
	Expr body_ = a.containingFun.body_.isA!(FunBody.ExpressionBody)
		? a.containingFun.body_.as!(FunBody.ExpressionBody).expr
		: Expr(UriAndRange.empty, ExprKind(ExprKind.Bogus()));
	eachDescendentExprIncluding(body_, (in Expr x) @safe {
		Opt!Target xTarget = exprTarget(program, PositionKind.Expression(a.containingFun, ptrTrustMe(x)));
		if (optEqual!Target(xTarget, some(Target(a))))
			add(alloc, res, x.range);
	});
	return finishArr(alloc, res);
}

UriAndRange[] loopReferences(ref Alloc alloc, Uri curUri, in ExprKind.Loop x) {
	ArrBuilder!UriAndRange res;
	add(alloc, res, UriAndRange(curUri, loopKeywordRange(x)));
	eachDescendentExprExcluding(ExprKind(&x), (in Expr child) {
		if (child.kind.isA!(ExprKind.LoopBreak*) || child.kind.isA!(ExprKind.LoopContinue))
			add(alloc, res, child.range);
	});
	return finishArr(alloc, res);
}
