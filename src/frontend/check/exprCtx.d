module frontend.check.exprCtx;

@safe @nogc pure nothrow:

import frontend.check.checkCtx : addDiag, CheckCtx;
import frontend.check.instantiate : InstantiateCtx, noDelayStructInsts;
import frontend.check.maps : FunsMap, StructsAndAliasesMap;
import frontend.check.typeFromAst : typeFromAst;
import frontend.lang : maxClosureFields;
import frontend.parse.ast : ExprAst, TypeAst;
import model.diag : Diag, TypeContainer, TypeWithContainer;
import model.model :
	CommonTypes,
	Destructure,
	FunFlags,
	LambdaExpr,
	Local,
	Mutability,
	range,
	SpecInst,
	Type,
	TypeParams,
	VariableRef;
import util.alloc.alloc : Alloc;
import util.col.mutMaxArr : MutMaxArr;
import util.opt : has, force, MutOpt, none, Opt, some;
import util.perf : Perf;
import util.sourceRange : Range, UriAndRange;
import util.sym : AllSymbols, Sym;

struct ClosureFieldBuilder {
	@safe @nogc pure nothrow:

	immutable Sym name; // Redundant to the variableRef, but it's faster to keep this close
	immutable Mutability mutability;
	bool[4]* isUsed; // points to isUsed for the outer variable. Null for Param.
	immutable Type type; // Same as above
	immutable VariableRef variableRef;

	void setIsUsed(LocalAccessKind accessKind) {
		if (isUsed != null) {
			(*isUsed)[accessKind] = true;
		}
	}
}

struct FunOrLambdaInfo {
	MutOpt!(LocalsInfo*) outer;
	// none for a function.
	// WARN: This will not be initialized; but we allocate the pointer early.
	immutable Opt!(LambdaExpr*) lambda;
	// Will be uninitialized for a function
	MutMaxArr!(maxClosureFields, ClosureFieldBuilder) closureFields = void;
}

struct LocalsInfo {
	FunOrLambdaInfo* funOrLambda;
	MutOpt!(LocalNode*) locals;
}

bool isInLambda(ref LocalsInfo a) =>
	has(a.funOrLambda.outer);

struct LocalNode {
	MutOpt!(LocalNode*) prev;
	bool[4] isUsed; // One for each LocalAccessKind
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
	immutable FunsMap funsMap;
	immutable CommonTypes commonTypes;
	immutable TypeContainer typeContainer; // for diags
	immutable Sym outermostFunName;
	immutable SpecInst*[] outermostFunSpecs;
	immutable Destructure[] outermostFunParams;
	immutable TypeParams outermostFunTypeParams;
	immutable FunFlags outermostFunFlags;
	private bool isInTrusted;
	private bool usedTrusted;

	ref Alloc alloc() return scope =>
		checkCtx().alloc();
	Alloc* allocPtr() =>
		checkCtx().allocPtr;

	ref const(AllSymbols) allSymbols() return scope const =>
		checkCtx().allSymbols();
	ref AllSymbols allSymbols() return scope =>
		checkCtx().allSymbols();

	ref Perf perf() return scope =>
		checkCtx().perf();

	ref CheckCtx checkCtx() return scope =>
		*checkCtxPtr;

	ref const(CheckCtx) checkCtx() return scope const =>
		*checkCtxPtr;

	ref InstantiateCtx instantiateCtx() return scope =>
		checkCtx.instantiateCtx;
}

TypeParams typeContext(in ExprCtx ctx) => // TODO:USED? ---------------------------------------------------------------------------
	ctx.outermostFunTypeParams;
TypeWithContainer typeWithContainer(ref const ExprCtx ctx, Type a) =>
	TypeWithContainer(a, ctx.typeContainer);

T withTrusted(T)(ref ExprCtx ctx, ExprAst* source, in T delegate() @safe @nogc pure nothrow cb) {
	Opt!(Diag.TrustedUnnecessary.Reason) reason = ctx.outermostFunFlags.safety != FunFlags.Safety.safe
		? some(Diag.TrustedUnnecessary.Reason.inUnsafeFunction)
		: ctx.isInTrusted
		? some(Diag.TrustedUnnecessary.Reason.inTrusted)
		: none!(Diag.TrustedUnnecessary.Reason);
	if(has(reason)) {
		addDiag2(ctx, source, Diag(Diag.TrustedUnnecessary(force(reason))));
		return cb();
	} else {
		ctx.isInTrusted = true;
		T res = cb();
		ctx.isInTrusted = false;
		if (!ctx.usedTrusted)
			addDiag2(ctx, source, Diag(Diag.TrustedUnnecessary(Diag.TrustedUnnecessary.Reason.unused)));
		ctx.usedTrusted = false;
		return res;
	}
}

bool checkCanDoUnsafe(ref ExprCtx ctx) {
	if (ctx.outermostFunFlags.safety == FunFlags.Safety.unsafe)
		return true;
	else {
		bool res = ctx.isInTrusted;
		if (res) ctx.usedTrusted = true;
		return res;
	}
}

void addDiag2(ref ExprCtx ctx, in UriAndRange range, Diag diag) {
	addDiag(ctx.checkCtx, range, diag);
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
