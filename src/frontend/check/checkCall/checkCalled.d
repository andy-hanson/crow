module frontend.check.checkCall.checkCalled;

@safe @nogc pure nothrow:

import frontend.check.checkCtx : markUsed;
import frontend.check.checkExpr : LocalsInfo;
import frontend.check.exprCtx : addDiag2, checkCanDoUnsafe, ExprCtx, isInDataLambda, isInLambda;
import model.diag : Diag;
import model.model : Called, CalledSpecSig, FunDecl, FunInst, FunFlags;
import util.opt : force, has, none, Opt, some;
import util.sourceRange : Range;

/*
Additional checks on a call after the overload and spec impls have been chosen.
*/

void checkCalled(ref ExprCtx ctx, in Range diagRange, in Called called, in LocalsInfo locals, ArgsKind argsKind) {
	called.match!void(
		(ref FunInst x) {
			markUsed(ctx.checkCtx, x.decl);
			checkCallFlags(ctx, diagRange, x.decl, ctx.outermostFunFlags, locals, argsKind);
			foreach (ref Called impl; x.specImpls)
				checkCalled(ctx, diagRange, impl, locals, argsKind);
		},
		// For a spec, we do checks when providing the spec impl
		(CalledSpecSig _) {});
}

enum ArgsKind { empty, nonEmpty }

private:

void checkCallFlags(
	ref ExprCtx ctx,
	in Range diagRange,
	FunDecl* called,
	FunFlags caller,
	in LocalsInfo locals,
	ArgsKind argsKind,
) {
	Opt!(Diag.CantCall.Reason) reason = getCantCallReason(
		ctx,
		called.isVariadic && argsKind == ArgsKind.nonEmpty,
		called.flags,
		caller,
		locals);
	if (has(reason))
		addDiag2(ctx, diagRange, Diag(Diag.CantCall(force(reason), called)));
}

Opt!(Diag.CantCall.Reason) getCantCallReason(
	ref ExprCtx ctx,
	bool calledIsVariadicNonEmpty,
	FunFlags calledFlags,
	FunFlags callerFlags,
	in LocalsInfo locals,
) =>
	!calledFlags.bare && callerFlags.bare && !calledFlags.forceCtx && !isInLambda(locals)
		// TODO: need to explain this better in the case where 'bare' is due to the lambda
		? some(Diag.CantCall.Reason.nonBare)
		: calledFlags.summon && (!callerFlags.summon || isInDataLambda(locals))
		? some(!callerFlags.summon ? Diag.CantCall.Reason.summon : Diag.CantCall.Reason.summonInDataLambda)
		: calledFlags.safety == FunFlags.Safety.unsafe && !checkCanDoUnsafe(ctx)
		? some(Diag.CantCall.Reason.unsafe)
		: calledIsVariadicNonEmpty && callerFlags.bare
		? some(Diag.CantCall.Reason.variadicFromBare)
		: none!(Diag.CantCall.Reason);
