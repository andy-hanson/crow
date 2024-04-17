module concretize.gatherInfo;

@safe @nogc pure nothrow:

import model.concreteModel : ConcreteExpr, ConcreteExprKind, ConcreteFun;
import model.constant : Constant;
import util.col.mutMultiMap : MutMultiMap, add;
import util.col.mutSet : MutSet;
import util.col.set : Set;
import util.opt : force, has, Opt;
import util.util : todo;

Set!(ConcreteFun*) getYieldingFuns(immutable ConcreteFun*[] allConcreteFuns) {
	// TODO: use temp alloc
	/*
	PLAN:
	* First, generate a map from fun to callers.
	* Add intrinsically yielding functions to 'toPropagate'.
	* While toPropagate is non-empty:
		- Take one out arbitrarily and move to 'res'.
		- For each caller:
			Add to toPropagate, if not already in 'res'.
	
	This terminates, since each step adds something new to 'res'.
	*/
	MutSet!(immutable ConcreteFun*) toPropagate; // These are functions known to yield that have not been processed.
	MutSet!(immutable ConcreteFun*) res; // These are functions known to yield that have been processed.
	return Set!(ConcreteFun*)();
	//return todo!ConcreteInfo("SDFJKDSF");
}

private:

// Maps a function to all functions that call it.
alias Callers = MutMultiMap!(ConcreteFun*, ConcreteFun*);

Callers getCallers(immutable ConcreteFun*[] allConcreteFuns) {
	/*
	PLAN:
	For each function:
		Walk its body and for each call:
			Add it to the set
	This step is simple...
	*/
	return todo!Callers("GETCALLERS");
}

void eachDirectChildExpr(ref ConcreteExpr a, in void delegate(ref ConcreteExpr) @safe @nogc pure nothrow cb) {
	void cbEach(ConcreteExpr[] args) {
		foreach (ref ConcreteExpr arg; args)
			cb(arg);
	}
	a.kind.matchWithPointers!void(
		(ConcreteExprKind.Alloc* x) =>
			cb(x.arg),
		(ConcreteExprKind.Call x) =>
			cbEach(x.args),
		(ConcreteExprKind.ClosureCreate x) {},
		(ConcreteExprKind.ClosureGet* x) {},
		(ConcreteExprKind.ClosureSet* x) =>
			cb(x.value),
		(Constant x) {},
		(ConcreteExprKind.CreateArray x) =>
			cbEach(x.args),
		(ConcreteExprKind.CreateRecord x) =>
			cbEach(x.args),
		(ConcreteExprKind.CreateUnion* x) =>
			cb(x.arg),
		(ConcreteExprKind.Drop* x) =>
			cb(x.arg),
		(ConcreteExprKind.Finally* x) {
			cb(x.right);
			cb(x.below);
		},
		(ConcreteExprKind.If* x) {
			cb(x.cond);
			cb(x.then);
			cb(x.else_);
		},
		(ConcreteExprKind.Lambda x) {},
		(ConcreteExprKind.Let* x) {
			cb(x.value);
			cb(x.then);
		},
		(ConcreteExprKind.LocalGet) {},
		(ConcreteExprKind.LocalSet* x) =>
			cb(x.value),
		(ConcreteExprKind.Loop* x) =>
			cb(x.body_),
		(ConcreteExprKind.LoopBreak* x) =>
			cb(x.value),
		(ConcreteExprKind.LoopContinue) {},
		(ConcreteExprKind.MatchEnumOrIntegral* x) {
			cb(x.matched);
			cbEach(x.caseExprs);
			if (has(x.else_))
				cb(*force(x.else_));
		},
		(ConcreteExprKind.MatchStringLike* x) {
			cb(x.matched);
			foreach (ConcreteExprKind.MatchStringLike.Case case_; x.cases) {
				cb(case_.value);
				cb(case_.then);
			}
			cb(x.else_);
		},
		(ConcreteExprKind.MatchUnion* x) {
			cb(x.matched);
			foreach (ConcreteExprKind.MatchUnion.Case case_; x.cases)
				cb(case_.then);
			if (has(x.else_))
				cb(*force(x.else_));
		},
		(ConcreteExprKind.PtrToField* x) =>
			cb(x.target),
		(ConcreteExprKind.PtrToLocal) {},
		(ConcreteExprKind.RecordFieldGet x) =>
			cb(*x.record),
		(ConcreteExprKind.Seq* x) {
			cb(x.first);
			cb(x.then);
		},
		(ConcreteExprKind.Throw* x) =>
			cb(x.thrown),
		(ConcreteExprKind.Try* x) {
			cb(x.tried);
			foreach (ConcreteExprKind.MatchUnion.Case case_; x.catchCases)
				cb(case_.then);
		},
		(ConcreteExprKind.TryLet* x) {
			cb(x.value);
			cb(x.catch_.then);
			cb(x.then);
		},
		(ConcreteExprKind.UnionAs x) =>
			cb(*x.union_),
		(ConcreteExprKind.UnionKind x) =>
			cb(*x.union_));
}
