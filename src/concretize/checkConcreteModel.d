module concretize.checkConcreteModel;

@safe @nogc pure nothrow:

import frontend.showModel : ShowCtx;
import model.concreteModel :
	ConcreteExpr,
	ConcreteExprKind,
	ConcreteFun,
	ConcreteLocal,
	ConcreteProgram,
	ConcreteStructBody,
	ConcreteType,
	isBogus,
	isVoid,
	mustBeByVal;
import model.constant : Constant;
import model.showLowModel : writeConcreteType;
import util.alloc.alloc : Alloc;
import util.col.array : zip;
import util.opt : force, has;
import util.util : ptrTrustMe;
import util.writer : debugLogWithWriter, Writer;

void checkConcreteProgram(in ShowCtx printCtx, in ConcreteCommonTypes types, in ConcreteProgram a) {
	Ctx ctx = Ctx(ptrTrustMe(printCtx), ptrTrustMe(types));
	foreach (ConcreteFun* fun; a.allFuns)
		if (fun.body_.isA!ConcreteExpr)
			checkExpr(ctx, fun.returnType, fun.body_.as!ConcreteExpr);
}

immutable struct ConcreteCommonTypes {
	ConcreteType bool_;
	ConcreteType nat64;
	ConcreteType string_;
	ConcreteType void_;
}

private:

struct Ctx {
	ShowCtx* printCtx;
	ConcreteCommonTypes* types;
}

void checkExpr(ref Ctx ctx, in ConcreteType type, in ConcreteExpr expr) {
	assert(!isBogus(type) || expr.kind.isA!(ConcreteExprKind.Throw*));
	checkType(ctx, type, expr.type);
	expr.kind.matchIn!void(
		(in ConcreteExprKind.Alloc x) {
			// TODO: validate 'type' is a pointer type and 'x.arg' is the pointee
			checkExprAnyType(ctx, x.arg);
		},
		(in ConcreteExprKind.Call x) {
			checkType(ctx, type, x.called.returnType);
			zip(x.called.paramsIncludingClosure, x.args, (ref ConcreteLocal param, ref ConcreteExpr arg) {
				checkExpr(ctx, param.type, arg);
			});
		},
		(in ConcreteExprKind.ClosureCreate) {
			// TODO: validate 'type' is a record and this creates it
		},
		(in ConcreteExprKind.ClosureGet x) @safe {
			checkType(ctx, type, x.closureRef.type);
		},
		(in ConcreteExprKind.ClosureSet x) {
			checkExpr(ctx, x.closureRef.type, x.value);
		},
		(in Constant) {},
		(in ConcreteExprKind.CreateArray x) {
			// TODO: validate 'type' is an array type and 'args' are elements
			foreach (ConcreteExpr arg; x.args)
				checkExprAnyType(ctx, arg);
		},
		(in ConcreteExprKind.CreateRecord x) {
			// TODO: validate 'type' is a record and this creates it
			foreach (ConcreteExpr arg; x.args)
				checkExprAnyType(ctx, arg);
		},
		(in ConcreteExprKind.CreateUnion x) {
			// TODO: validate 'type' is a union and this creates it
			checkExprAnyType(ctx, x.arg);
		},
		(in ConcreteExprKind.Drop x) {
			assert(isVoid(type));
			checkExprAnyType(ctx, x.arg);
		},
		(in ConcreteExprKind.If x) {
			checkExpr(ctx, ctx.types.bool_, x.cond);
			checkExpr(ctx, type, x.then);
			checkExpr(ctx, type, x.else_);
		},
		(in ConcreteExprKind.Lambda x) {
			if (has(x.closure))
				checkExprAnyType(ctx, *force(x.closure));
		},
		(in ConcreteExprKind.Let x) {
			checkExpr(ctx, x.local.type, x.value);
			checkExpr(ctx, type, x.then);
		},
		(in ConcreteExprKind.LocalGet x) {
			checkType(ctx, type, x.local.type);
		},
		(in ConcreteExprKind.LocalSet x) {
			assert(isVoid(type));
			checkExpr(ctx, x.local.type, x.value);
		},
		(in ConcreteExprKind.Loop x) {
			checkExpr(ctx, ctx.types.void_, x.body_);
		},
		(in ConcreteExprKind.LoopBreak x) {
			assert(isVoid(type));
			// TODO: use type from loop
			checkExprAnyType(ctx, x.value);
		},
		(in ConcreteExprKind.LoopContinue) {
			assert(isVoid(type));
		},
		(in ConcreteExprKind.MatchEnum x) {
			checkExprAnyType(ctx, x.matchedValue);
			foreach (ConcreteExpr case_; x.cases)
				checkExpr(ctx, type, case_);
		},
		(in ConcreteExprKind.MatchUnion x) {
			checkExprAnyType(ctx, x.matchedValue);
			foreach (ConcreteExprKind.MatchUnion.Case case_; x.cases)
				checkExpr(ctx, type, case_.then);
		},
		(in ConcreteExprKind.PtrToField x) {
			checkExprAnyType(ctx, x.target);
		},
		(in ConcreteExprKind.PtrToLocal) {
			// TODO
		},
		(in ConcreteExprKind.RecordFieldGet x) {
			checkExprAnyType(ctx, *x.record);
		},
		(in ConcreteExprKind.Seq x) {
			checkExpr(ctx, ctx.types.void_, x.first);
			checkExpr(ctx, type, x.then);
		},
		(in ConcreteExprKind.Throw x) {
			checkExpr(ctx, ctx.types.string_, x.thrown);
		},
		(in ConcreteExprKind.UnionAs x) {
			checkType(ctx, type, mustBeByVal(x.union_.type).body_.as!(ConcreteStructBody.Union).members[x.memberIndex]);
			checkExprAnyType(ctx, *x.union_);
		},
		(in ConcreteExprKind.UnionKind x) {
			checkType(ctx, type, ctx.types.nat64);
			assert(mustBeByVal(x.union_.type).body_.isA!(ConcreteStructBody.Union));
		});
}

void checkExprAnyType(ref Ctx ctx, in ConcreteExpr expr) {
	checkExpr(ctx, expr.type, expr);
}

void checkType(ref Ctx ctx, in ConcreteType expected, in ConcreteType actual) {
	if (expected != actual) {
		debugLogWithWriter((scope ref Writer writer) {
			writer ~= "expected ";
			writeConcreteType(writer, *ctx.printCtx, expected);
			writer ~= " but was ";
			writeConcreteType(writer, *ctx.printCtx, actual);
		});
		assert(false);
	}
}
