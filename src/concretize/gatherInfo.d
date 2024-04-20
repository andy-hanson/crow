module concretize.gatherInfo;

@safe @nogc pure nothrow:

import concretize.concretizeCtx : ConcreteLambdaImpl;
import model.concreteModel :
	ConcreteCommonFuns,
	ConcreteExpr,
	ConcreteExprKind,
	ConcreteFun,
	ConcreteFunBody,
	ConcreteLocal,
	ConcreteStruct,
	mustBeByVal;
import model.constant : Constant;
import model.model : BuiltinBinary, BuiltinFun, EnumFunction, FlagsFunction;
import util.alloc.alloc : Alloc;
import util.col.array : mustFind, only2;
import util.col.map : mustGet;
import util.col.mutArr : mustPop, MutArr, mutArrIsEmpty, push;
import util.col.mutMultiMap : eachValueForKey, MutMultiMap, add;
import util.col.mutSet : mayAddToMutSet, MutSet, mustSetMustDelete;
import util.col.set : moveToSet, Set;
import util.opt : force, has, Opt;
import util.util : todo;

Set!(immutable ConcreteFun*) getYieldingFuns(ref Alloc alloc, in ConcreteCommonFuns commonFuns, immutable ConcreteFun*[] allConcreteFuns) {
	const CalledBy calledBy = getCalledBy(alloc, allConcreteFuns); // TODO: use a temp alloc? ------------------------------------------------------------

	// There is just 1 intrinsically yielding function: 'switch-fiber-suspension'
	ConcreteFun* switchFiberSuspension = mustFind!(immutable ConcreteFun*)(allConcreteFuns, (ref immutable ConcreteFun* f) {
		if (f.body_.isA!(ConcreteFunBody.Builtin)) {
			ConcreteFunBody.Builtin builtin = f.body_.as!(ConcreteFunBody.Builtin);
			return builtin.kind.isA!(BuiltinBinary) && builtin.kind.as!(BuiltinBinary) == BuiltinBinary.switchFiberSuspension;
		} else
			return false;
	});

	// These are functions known to yield that have been added to 'res' but not yet processed callers.
	MutArr!(immutable ConcreteFun*) toPropagate;
	MutSet!(immutable ConcreteFun*) res;

	void add(ConcreteFun* x) {
		if (mayAddToMutSet(alloc, res, x))
			push(alloc, toPropagate, x); // TODO: use temp alloc
	}

	add(switchFiberSuspension);
	while (!mutArrIsEmpty(toPropagate)) {
		ConcreteFun* fun = mustPop(toPropagate);
		eachValueForKey!(immutable ConcreteFun*, immutable ConcreteFun*)(calledBy, fun, (immutable ConcreteFun* caller) {
			add(caller);
		});
	}

	// This function is special
	mustSetMustDelete(res, commonFuns.runFiber);

	return moveToSet!(immutable ConcreteFun*)(res);
}

private:

// Maps a function to all functions that call it.
alias CalledBy = MutMultiMap!(immutable ConcreteFun*, immutable ConcreteFun*);

CalledBy getCalledBy(ref Alloc alloc, in immutable ConcreteFun*[] allConcreteFuns) {
	CalledBy res;
	foreach (ConcreteFun* fun; allConcreteFuns)
		fun.body_.match!void(
			(ConcreteFunBody.Builtin x) {
				assert(!x.kind.isA!(BuiltinFun.CallLambda)); // TODO: it should just not be in the type then? ----------------
				// TODO: ignoring CallFunPointer, but those should have to be 'bare' functions anyway??????????????????????????????????
				// Otherwise we'd have to track all fun-pointer expressions of a given type
			},
			(Constant _) {},
			(ConcreteFunBody.CreateRecord) {},
			(ConcreteFunBody.CreateUnion) {},
			(EnumFunction _) {},
			(ConcreteFunBody.Extern) {},
			(ConcreteExpr x) {
				getCalledByRecur(alloc, res, fun, x);
			},
			(ConcreteFunBody.FlagsFn) {},
			(ConcreteFunBody.RecordFieldCall x) {
				add(alloc, res, x.caller, fun);
			},
			(ConcreteFunBody.RecordFieldGet) {},
			(ConcreteFunBody.RecordFieldPointer) {},
			(ConcreteFunBody.RecordFieldSet) {},
			(ConcreteFunBody.VarGet) {},
			(ConcreteFunBody.VarSet) {});
	return res;
}

void getCalledByRecur(ref Alloc alloc, ref CalledBy res, ConcreteFun* f, ref ConcreteExpr expr) {
	// TODO: this ignores Alloc calling an alloc function, or Throw calling a throw function. But those don't yield so it doesn't matter?
	if (expr.kind.isA!(ConcreteExprKind.Call))
		add(alloc, res, expr.kind.as!(ConcreteExprKind.Call).called, f);
	eachDirectChildExpr(expr, (ref ConcreteExpr child) {
		getCalledByRecur(alloc, res, f, child);
	});
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
