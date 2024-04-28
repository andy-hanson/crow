module concretize.gatherInfo;

@safe @nogc pure nothrow:

import concretize.concretizeCtx : ConcreteLambdaImpl;
import model.concreteModel :
	ConcreteCommonFuns,
	ConcreteExpr,
	ConcreteExprKind,
	ConcreteFun,
	ConcreteFunBody,
	ConcreteFunKey,
	ConcreteLocal,
	ConcreteStruct,
	mustBeByVal;
import model.constant : Constant;
import model.model : BuiltinBinary, BuiltinFun, EnumFunction, FlagsFunction;
import util.alloc.alloc : Alloc;
import util.col.array : exists, mustFind, only2;
import util.col.map : mustGet;
import util.col.mutArr : mustPop, MutArr, mutArrIsEmpty, push;
import util.col.mutMultiMap : eachValueForKey, MutMultiMap, add;
import util.col.mutSet : mayAddToMutSet, MutSet, mustSetMustDelete;
import util.col.set : moveToSet, Set;
import util.opt : force, has, Opt;
import util.symbol : Symbol;
import util.util : todo;

Set!(immutable ConcreteFun*) getYieldingFuns(
	ref Alloc alloc,
	in ConcreteCommonFuns commonFuns,
	immutable ConcreteFun*[] allConcreteFuns,
) {
	const CalledBy calledBy = getCalledBy(alloc, allConcreteFuns); // TODO: use a temp alloc? ------------------------------------------------------------

	// There is just 1 intrinsically yielding function: 'switch-fiber'
	ConcreteFun* switchFiberSuspension = mustFind!(immutable ConcreteFun*)(allConcreteFuns, (ref immutable ConcreteFun* f) {
		if (f.body_.isA!(ConcreteFunBody.Builtin)) {
			ConcreteFunBody.Builtin builtin = f.body_.as!(ConcreteFunBody.Builtin);
			return builtin.kind.isA!(BuiltinBinary) && builtin.kind.as!(BuiltinBinary) == BuiltinBinary.switchFiber;
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
			if (caller != commonFuns.runFiber) {
				// ---------------------------------------------------------------------------------------------------------------
				if (false) {
					import frontend.showModel : ShowCtx;
					import model.showLowModel : writeConcreteFunSig;
					import util.writer : debugLogWithWriter, Writer;
					debugLogWithWriter((scope ref Writer writer) {
						ShowCtx ctx = ShowCtx();
						writeConcreteFunSig(writer, ctx, *caller, false);
						writer ~= " may yield because it calls ";
						writeConcreteFunSig(writer, ctx, *fun, false);
					});
				}
				add(caller);
			}
		});
	}

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
			(EnumFunction _) {},
			(ConcreteFunBody.Extern) {},
			(ConcreteExpr x) {
				getCalledByRecur(alloc, res, fun, x);
			},
			(ConcreteFunBody.FlagsFn) {},
			(ConcreteFunBody.VarGet) {},
			(ConcreteFunBody.VarSet) {});
	return res;
}

void getCalledByRecur(ref Alloc alloc, ref CalledBy res, ConcreteFun* f, ref ConcreteExpr expr) {
	if (expr.kind.isA!(ConcreteExprKind.Call))
		add(alloc, res, expr.kind.as!(ConcreteExprKind.Call).called, f);
	existsDirectChildExpr(expr, (ref ConcreteExpr child) {
		getCalledByRecur(alloc, res, f, child);
		return false;
	});
}

public bool existsDirectChildExpr(ref ConcreteExpr a, in bool delegate(ref ConcreteExpr) @safe @nogc pure nothrow cb) => // TODO: MOVE
	a.kind.matchWithPointers!bool(
		(ConcreteExprKind.Call x) =>
			exists!ConcreteExpr(x.args, cb),
		(Constant x) =>
			false,
		(ConcreteExprKind.CreateArray x) =>
			exists!ConcreteExpr(x.args, cb),
		(ConcreteExprKind.CreateRecord x) =>
			exists!ConcreteExpr(x.args, cb),
		(ConcreteExprKind.CreateUnion* x) =>
			cb(x.arg),
		(ConcreteExprKind.Drop* x) =>
			cb(x.arg),
		(ConcreteExprKind.Finally* x) =>
			cb(x.right) || cb(x.below),
		(ConcreteExprKind.If* x) =>
			cb(x.cond) || cb(x.then) || cb(x.else_),
		(ConcreteExprKind.Let* x) =>
			cb(x.value) || cb(x.then),
		(ConcreteExprKind.LocalGet) =>
			false,
		(ConcreteExprKind.LocalPointer) =>
			false,
		(ConcreteExprKind.LocalSet* x) =>
			cb(x.value),
		(ConcreteExprKind.Loop* x) =>
			cb(x.body_),
		(ConcreteExprKind.LoopBreak* x) =>
			cb(x.value),
		(ConcreteExprKind.LoopContinue) =>
			false,
		(ConcreteExprKind.MatchEnumOrIntegral* x) =>
			cb(x.matched) ||
			exists!ConcreteExpr(x.caseExprs, cb) ||
			(has(x.else_) && cb(*force(x.else_))),
		(ConcreteExprKind.MatchStringLike* x) =>
			cb(x.matched) ||
			exists!(ConcreteExprKind.MatchStringLike.Case)(x.cases, (ref ConcreteExprKind.MatchStringLike.Case case_) =>
				cb(case_.value) || cb(case_.then)) ||
			cb(x.else_),
		(ConcreteExprKind.MatchUnion* x) =>
			cb(x.matched) ||
			exists!(ConcreteExprKind.MatchUnion.Case)(x.cases, (ref ConcreteExprKind.MatchUnion.Case case_) =>
				cb(case_.then)) ||
			(has(x.else_) && cb(*force(x.else_))),
		(ConcreteExprKind.RecordFieldGet x) =>
			cb(*x.record),
		(ConcreteExprKind.RecordFieldPointer x) =>
			cb(*x.record),
		(ConcreteExprKind.RecordFieldSet* x) =>
			cb(x.record) || cb(x.value),
		(ConcreteExprKind.Seq* x) =>
			cb(x.first) || cb(x.then),
		(ConcreteExprKind.Throw* x) =>
			cb(x.thrown),
		(ConcreteExprKind.Try* x) =>
			cb(x.tried) ||
			exists!(ConcreteExprKind.MatchUnion.Case)(x.catchCases, (ref ConcreteExprKind.MatchUnion.Case case_) =>
				cb(case_.then)),
		(ConcreteExprKind.TryLet* x) =>
			cb(x.value) || cb(x.catch_.then) || cb(x.then),
		(ConcreteExprKind.UnionAs x) =>
			cb(*x.union_),
		(ConcreteExprKind.UnionKind x) =>
			cb(*x.union_));
