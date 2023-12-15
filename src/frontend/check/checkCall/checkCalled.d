module frontend.check.checkCall.checkCalled;

@safe @nogc pure nothrow:

import frontend.check.checkCtx : markUsed;
import frontend.check.exprCtx : addDiag2, checkCanDoUnsafe, ExprCtx;
import model.ast : ExprAst;
import model.diag : Diag;
import model.model : Called, CalledSpecSig, FunDecl, FunInst, FunFlags, isVariadic;
import util.opt : force, has, none, Opt, some;
import util.sourceRange : Range;

/*
Additional checks on a call after the overload and spec impls have been chosen.
*/

void checkCalled(ref ExprCtx ctx, ExprAst* source, in Called called, bool isInLambda, ArgsKind argsKind) {
	called.match!void(
		(ref FunInst x) {
			markUsed(ctx.checkCtx, x.decl);
			checkCallFlags(ctx, source.range, x.decl, ctx.outermostFunFlags, isInLambda, argsKind);
			foreach (ref Called impl; x.specImpls) {
				checkCalled(ctx, source, impl, isInLambda, argsKind);
			}
		},
		// For a spec, we do checks when providing the spec impl
		(CalledSpecSig _) {});
}

enum ArgsKind { empty, nonEmpty }

private:

void checkCallFlags(
	ref ExprCtx ctx,
	in Range range,
	FunDecl* called,
	FunFlags caller,
	bool isCallerInLambda,
	ArgsKind argsKind,
) {
	Opt!(Diag.CantCall.Reason) reason = getCantCallReason(
		ctx,
		isVariadic(*called) && argsKind == ArgsKind.nonEmpty,
		called.flags,
		caller,
		isCallerInLambda);
	if (has(reason))
		addDiag2(ctx, range, Diag(Diag.CantCall(force(reason), called)));
}

Opt!(Diag.CantCall.Reason) getCantCallReason(
	ref ExprCtx ctx,
	bool calledIsVariadicNonEmpty,
	FunFlags calledFlags,
	FunFlags callerFlags,
	bool isCallerInLambda,
) =>
	!calledFlags.bare && callerFlags.bare && !calledFlags.forceCtx && !isCallerInLambda
		// TODO: need to explain this better in the case where 'bare' is due to the lambda
		? some(Diag.CantCall.Reason.nonBare)
		: calledFlags.summon && !callerFlags.summon
		? some(Diag.CantCall.Reason.summon)
		: calledFlags.safety == FunFlags.Safety.unsafe && !checkCanDoUnsafe(ctx)
		? some(Diag.CantCall.Reason.unsafe)
		: calledIsVariadicNonEmpty && callerFlags.bare
		? some(Diag.CantCall.Reason.variadicFromBare)
		: none!(Diag.CantCall.Reason);
