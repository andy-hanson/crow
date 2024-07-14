module frontend.frontendUtil;

@safe @nogc pure nothrow:

import model.ast : DestructureAst, ModifierAst, NameAndRange, ParamsAst, SpecUseAst, TypeAst;
import model.model :
	arrayElementType,
	AssertOrForbidExpr,
	BogusExpr,
	CallExpr,
	CallOptionExpr,
	ClosureGetExpr,
	ClosureSetExpr,
	CommonTypes,
	Condition,
	Expr,
	ExprAndType,
	ExternExpr,
	FinallyExpr,
	FunDecl,
	FunDeclSource,
	FunPointerExpr,
	IfExpr,
	LambdaExpr,
	LetExpr,
	LiteralExpr,
	LiteralStringLikeExpr,
	LocalGetExpr,
	LocalPointerExpr,
	LocalSetExpr,
	LoopBreakExpr,
	LoopContinueExpr,
	LoopExpr,
	LoopWhileOrUntilExpr,
	MatchEnumExpr,
	MatchIntegralExpr,
	MatchStringLikeExpr,
	MatchUnionExpr,
	MatchVariantExpr,
	RecordFieldPointerExpr,
	SeqExpr,
	SpecInst,
	SpecDecl,
	StructInst,
	Test,
	ThrowExpr,
	TrustedExpr,
	TryExpr,
	TryLetExpr,
	Type,
	TypedExpr,
	TypeParamIndex;
import util.col.array : arrayOfSingle, count, first, firstPointer, firstZip, firstZipPointerFirst, isEmpty, only, only2;
import util.opt : force, has, none, Opt, optOr, some;
import util.sourceRange : UriAndRange;
import util.util : ptrTrustMe;

immutable struct ExprRef {
	Expr* expr;
	Type type;
}

ExprRef funBodyExprRef(FunDecl* a) =>
	ExprRef(&a.body_.as!Expr(), a.returnType);
ExprRef testBodyExprRef(ref CommonTypes commonTypes, Test* a) =>
	ExprRef(&a.body_, Type(commonTypes.void_));

void eachDescendentExprIncluding(
	ref CommonTypes commonTypes,
	ExprRef a,
	in void delegate(ExprRef) @safe @nogc pure nothrow cb,
) {
	cb(a);
	eachDescendentExprExcluding(commonTypes, a, cb);
}

void eachDescendentExprExcluding(
	ref CommonTypes commonTypes,
	ExprRef a,
	in void delegate(ExprRef) @safe @nogc pure nothrow cb,
) {
	eachDirectChildExpr(commonTypes, a, (ExprRef x) {
		eachDescendentExprIncluding(commonTypes, x, cb);
	});
}

void eachDirectChildExpr(
	ref CommonTypes commonTypes,
	ExprRef a,
	in void delegate(ExprRef) @safe @nogc pure nothrow cb,
) {
	Opt!bool res = findDirectChildExpr!bool(commonTypes, a, (ExprRef x) {
		cb(x);
		return none!bool;
	});
	assert(!has(res));
}

Opt!T findDirectChildExpr(T)(
	ref CommonTypes commonTypes,
	ExprRef a,
	in Opt!T delegate(ExprRef) @safe @nogc pure nothrow cb,
) {
	Type boolType = Type(commonTypes.bool_);
	Type exceptionType = Type(commonTypes.exception);
	Type voidType = Type(commonTypes.void_);
	ExprRef sameType(Expr* x) =>
		ExprRef(x, a.type);
	ExprRef toRef(ExprAndType* x) =>
		ExprRef(&x.expr, x.type);

	ExprRef directChildInCondition(Condition cond) =>
		cond.matchWithPointers!ExprRef(
			(Expr* x) =>
				ExprRef(x, boolType),
			(Condition.UnpackOption* x) =>
				toRef(&x.option));
	Opt!T directChildInMatchVariantCases(MatchVariantExpr.Case[] cases) =>
		firstPointer!(T, MatchVariantExpr.Case)(cases, (MatchVariantExpr.Case* x) =>
			cb(sameType(&x.then)));

	return a.expr.kind.matchWithPointers!(Opt!T)(
		(AssertOrForbidExpr* x) =>
			optOr!T(
				cb(directChildInCondition(x.condition)),
				() => has(x.thrown) ? cb(ExprRef(force(x.thrown), exceptionType)) : none!T,
				() => cb(sameType(&x.after))),
		(BogusExpr _) =>
			none!T,
		(CallExpr x) {
			assert(a.type == x.called.returnType);
			if (x.called.isVariadic) {
				Type argType = arrayElementType(only(x.called.paramTypes));
				return firstPointer!(T, Expr)(x.args, (Expr* e) => cb(ExprRef(e, argType)));
			} else
				return firstZipPointerFirst!(T, Expr, Type)(x.args, x.called.paramTypes, (Expr* e, Type t) =>
					cb(ExprRef(e, t)));
		},
		(CallOptionExpr* x) =>
			optOr!T(
				cb(toRef(&x.firstArg)),
				() => firstZipPointerFirst!(T, Expr, Type)(x.restArgs, x.called.paramTypes[1 .. $], (Expr* e, Type t) =>
					cb(ExprRef(e, t)))),
		(ClosureGetExpr x) {
			assert(a.type == x.local.type);
			return none!T;
		},
		(ClosureSetExpr x) {
			assert(a.type == voidType);
			return cb(ExprRef(x.value, x.local.type));
		},
		(ExternExpr x) =>
			none!T,
		(FinallyExpr* x) =>
			optOr!T(
				cb(ExprRef(&x.right, voidType)),
				() => cb(sameType(&x.below))),
		(FunPointerExpr _) =>
			none!T,
		(IfExpr* x) =>
			optOr!T(
				cb(directChildInCondition(x.condition)),
				() => cb(sameType(&x.firstBranch(a.expr.ast))),
				() => cb(sameType(&x.secondBranch(a.expr.ast)))),
		(LambdaExpr* x) =>
			cb(ExprRef(&x.body_(), x.returnType)),
		(LetExpr* x) =>
			optOr!T(cb(ExprRef(&x.value, x.destructure.type)), () => cb(sameType(&x.then))),
		(LiteralExpr _) =>
			none!T,
		(LiteralStringLikeExpr _) =>
			none!T,
		(LocalGetExpr x) {
			assert(a.type == x.local.type);
			return none!T;
		},
		(LocalPointerExpr _) =>
			none!T,
		(LocalSetExpr x) {
			assert(a.type == voidType);
			return cb(ExprRef(x.value, x.local.type));
		},
		(LoopExpr* x) =>
			cb(sameType(&x.body_)),
		(LoopBreakExpr* x) =>
			cb(sameType(&x.value)),
		(LoopContinueExpr _) =>
			none!T,
		(LoopWhileOrUntilExpr* x) =>
			optOr!T(
				cb(directChildInCondition(x.condition)),
				() => cb(ExprRef(&x.body_, voidType)),
				() => cb(sameType(&x.after))),
		(MatchEnumExpr* x) =>
			optOr!T(
				cb(toRef(&x.matched)),
				() => firstPointer!(T, MatchEnumExpr.Case)(x.cases, (MatchEnumExpr.Case* y) => cb(sameType(&y.then))),
				() => has(x.else_) ? cb(sameType(&force(x.else_))) : none!T),
		(MatchIntegralExpr* x) =>
			optOr!T(
				cb(toRef(&x.matched)),
				() => firstPointer!(T, MatchIntegralExpr.Case)(x.cases, (MatchIntegralExpr.Case* y) =>
					cb(sameType(&y.then))),
				() => cb(sameType(&x.else_))),
		(MatchStringLikeExpr* x) =>
			optOr!T(
				cb(toRef(&x.matched)),
				() => firstPointer!(T, MatchStringLikeExpr.Case)(x.cases, (MatchStringLikeExpr.Case* y) =>
					cb(sameType(&y.then))),
				() => cb(sameType(&x.else_))),
		(MatchUnionExpr* x) =>
			optOr!T(
				cb(toRef(&x.matched)),
				() => firstPointer!(T, MatchUnionExpr.Case)(x.cases, (MatchUnionExpr.Case* case_) =>
					cb(sameType(&case_.then))),
				() => has(x.else_) ? cb(sameType(force(x.else_))) : none!T),
		(MatchVariantExpr* x) =>
			optOr!T(
				cb(toRef(&x.matched)),
				() => directChildInMatchVariantCases(x.cases),
				() => cb(sameType(&x.else_))),
		(RecordFieldPointerExpr* x) =>
			cb(toRef(&x.target)),
		(SeqExpr* x) =>
			optOr!T(cb(ExprRef(&x.first, voidType)), () => cb(sameType(&x.then))),
		(ThrowExpr* x) =>
			cb(ExprRef(&x.thrown, exceptionType)),
		(TrustedExpr* x) =>
			cb(sameType(&x.inner)),
		(TryExpr* x) =>
			optOr!T(cb(sameType(&x.tried)), () => directChildInMatchVariantCases(x.catches)),
		(TryLetExpr* x) =>
			optOr!T(
				cb(ExprRef(&x.value, x.destructure.type)),
				() => cb(sameType(&x.catch_.then)),
				() => cb(sameType(&x.then))),
		(TypedExpr* x) =>
			cb(sameType(&x.inner)));
}
