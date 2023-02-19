module frontend.check.checkCall.checkCalled;

@safe @nogc pure nothrow:

import frontend.check.checkCtx : markUsed;
import frontend.check.inferringType : addDiag2, checkCanDoUnsafe, ExprCtx;
import model.diag : Diag;
import model.model : Called, CalledSpecSig, decl, FunDecl, FunInst, FunFlags, isVariadic, specImpls;
import util.opt : force, has, none, Opt, some;
import util.sourceRange : FileAndRange;

/*
Additional checks on a call after the overload and spec impls have been chosen.
*/

void checkCalled(ref ExprCtx ctx, FileAndRange range, in Called called, bool isInLambda, ArgsKind argsKind) {
	called.match!void(
		(ref FunInst x) {
			markUsed(ctx.checkCtx, decl(x));
			checkCallFlags(ctx, range, decl(x), ctx.outermostFunFlags, isInLambda, argsKind);
			foreach (ref Called impl; specImpls(x)) {
				checkCalled(ctx, range, impl, isInLambda, argsKind);
			}
		},
		// For a spec, we do checks when providing the spec impl
		(ref CalledSpecSig _) {});
}

enum ArgsKind { empty, nonEmpty }

private:

void checkCallFlags(
	ref ExprCtx ctx,
	FileAndRange range,
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
	!calledFlags.noCtx && callerFlags.noCtx && !calledFlags.forceCtx && !isCallerInLambda
		// TODO: need to explain this better in the case where noCtx is due to the lambda
		? some(Diag.CantCall.Reason.nonNoCtx)
		: calledFlags.summon && !callerFlags.summon
		? some(Diag.CantCall.Reason.summon)
		: calledFlags.safety == FunFlags.Safety.unsafe && !checkCanDoUnsafe(ctx)
		? some(Diag.CantCall.Reason.unsafe)
		: calledIsVariadicNonEmpty && callerFlags.noCtx
		? some(Diag.CantCall.Reason.variadicFromNoctx)
		: none!(Diag.CantCall.Reason);
