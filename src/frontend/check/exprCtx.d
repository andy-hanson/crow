module frontend.check.exprCtx;

@safe @nogc pure nothrow:

import frontend.check.checkCtx : addDiag, CheckCtx;
import frontend.check.instantiate : InstantiateCtx, noDelayStructInsts;
import frontend.check.maps : FunsMap, SpecsMap, StructsAndAliasesMap;
import frontend.check.typeFromAst : typeFromAst;
import frontend.lang : maxClosureFields;
import model.ast : ExprAst, TypeAst;
import model.diag : Diag, TypeContainer, TypeWithContainer;
import model.model :
	CommonTypes, FunFlags, LambdaExpr, Local, Mutability, Specs, Type, TypeParams, VariableRef;
import util.alloc.alloc : Alloc;
import util.col.mutMaxArr : MutMaxArr;
import util.col.enumMap : EnumMap;
import util.opt : has, force, MutOpt, none, Opt, some;
import util.perf : Perf;
import util.sourceRange : Range, rangeOfStartAndLength;
import util.symbol : Symbol;

struct ClosureFieldBuilder {
	@safe @nogc pure nothrow:

	// name, mutability, and type are eventually redundant to the variableRef,
	// but are needed before the lambda has its Late fields filled in
	immutable Symbol name;
	immutable Mutability mutability; // same
	EnumMap!(LocalAccessKind, bool)* isUsed; // points to isUsed for the outer variable. Null for Param.
	immutable Type type;
	immutable VariableRef variableRef;

	void setIsUsed(LocalAccessKind accessKind) {
		if (isUsed != null) {
			(*isUsed)[accessKind] = true;
		}
	}
}

struct LambdaInfo {
	LocalsInfo* outer;
	// WARN: Only 'lambda.kind' will be initialized while checking the lambda
	immutable LambdaExpr* lambda;
	MutMaxArr!(maxClosureFields, ClosureFieldBuilder) closureFields = void;
}

struct LocalsInfo {
	MutOpt!(LambdaInfo*) lambda;
	MutOpt!(LocalNode*) locals;
}

bool isInLambda(in LocalsInfo a) =>
	has(a.lambda);

bool isInDataLambda(in LocalsInfo a) =>
	has(a.lambda) && (force(a.lambda).lambda.kind == LambdaExpr.Kind.data || isInDataLambda(*force(a.lambda).outer));

struct LocalNode {
	MutOpt!(LocalNode*) prev;
	EnumMap!(LocalAccessKind, bool) isUsed;
	immutable Local* local;
}
enum LocalAccessKind { getOnStack, getThroughClosure, setOnStack, setThroughClosure }

void markIsUsedSetOnStack(scope ref LocalsInfo locals, Local* local) {
	LocalNode* node = force(locals.locals);
	while (true) {
		if (node.local == local) {
			node.isUsed[LocalAccessKind.setOnStack] = true;
			break;
		}
		node = force(node.prev);
	}
}

struct ExprCtx {
	@safe @nogc pure nothrow:

	CheckCtx* checkCtxPtr;
	immutable StructsAndAliasesMap structsAndAliasesMap;
	immutable SpecsMap specsMap;
	immutable FunsMap funsMap;
	immutable CommonTypes* commonTypesPtr;
	immutable TypeContainer typeContainer; // for diags. This will be a FunDecl* or Test*.
	immutable Specs outermostFunSpecs;
	immutable TypeParams outermostFunTypeParams;
	immutable FunFlags outermostFunFlags;
	private bool isInTrusted;
	private bool usedTrusted;

	ref Alloc alloc() return scope =>
		checkCtx().alloc();
	Alloc* allocPtr() =>
		checkCtx().allocPtr;

	ref Perf perf() return scope =>
		checkCtx().perf();

	ref CheckCtx checkCtx() return scope =>
		*checkCtxPtr;

	ref const(CheckCtx) checkCtx() return scope const =>
		*checkCtxPtr;

	ref InstantiateCtx instantiateCtx() return scope =>
		checkCtx.instantiateCtx;

	ref CommonTypes commonTypes() return scope const =>
		*commonTypesPtr;
}


TypeWithContainer typeWithContainer(ref const ExprCtx ctx, Type a) =>
	TypeWithContainer(a, ctx.typeContainer);

T withTrusted(T)(ref ExprCtx ctx, ExprAst* source, in T delegate() @safe @nogc pure nothrow cb) {
	Opt!(Diag.TrustedUnnecessary.Reason) reason = ctx.outermostFunFlags.safety != FunFlags.Safety.safe
		? some(Diag.TrustedUnnecessary.Reason.inUnsafeFunction)
		: ctx.isInTrusted
		? some(Diag.TrustedUnnecessary.Reason.inTrusted)
		: none!(Diag.TrustedUnnecessary.Reason);
	if(has(reason)) {
		addDiag2(ctx, trustedKeywordRange(source), Diag(Diag.TrustedUnnecessary(force(reason))));
		return cb();
	} else {
		ctx.isInTrusted = true;
		T res = cb();
		ctx.isInTrusted = false;
		if (!ctx.usedTrusted)
			addDiag2(ctx, trustedKeywordRange(source), Diag(
				Diag.TrustedUnnecessary(Diag.TrustedUnnecessary.Reason.unused)));
		ctx.usedTrusted = false;
		return res;
	}
}

private Range trustedKeywordRange(in ExprAst* source) =>
	rangeOfStartAndLength(source.range.start, "trusted".length);

bool checkCanDoUnsafe(ref ExprCtx ctx) {
	if (allowsUnsafe(ctx.outermostFunFlags.safety))
		return true;
	else {
		bool res = ctx.isInTrusted;
		if (res)
			ctx.usedTrusted = true;
		return res;
	}
}

bool allowsUnsafe(FunFlags.Safety a) {
	final switch (a) {
		case FunFlags.Safety.safe:
			return false;
		case FunFlags.Safety.unsafe:
		case FunFlags.Safety.trusted:
			return true;
	}
}

void addDiag2(ref ExprCtx ctx, in Range range, Diag diag) {
	addDiag(ctx.checkCtx, range, diag);
}
void addDiag2(ref ExprCtx ctx, in ExprAst* source, Diag diag) {
	addDiag2(ctx, source.range, diag);
}

immutable(Type) typeFromAst2(ref ExprCtx ctx, in TypeAst ast) =>
	typeFromAst(
		ctx.checkCtx,
		ctx.commonTypes,
		ast,
		ctx.structsAndAliasesMap,
		ctx.outermostFunTypeParams,
		noDelayStructInsts);
