module concretize.checkConcreteModel;

@safe @nogc pure nothrow:

import interpret.debugging : writeConcreteType;
import model.concreteModel :
	body_,
	ConcreteExpr,
	ConcreteExprKind,
	ConcreteFun,
	ConcreteLocal,
	ConcreteProgram,
	ConcreteType,
	isBogus,
	isVoid;
import model.constant : Constant;
import model.model : Program;
import util.alloc.alloc : Alloc, withStackAlloc;
import util.col.arrUtil : zip;
import util.opt : force, has;
import util.ptr : ptrTrustMe;
import util.sym : AllSymbols;
import util.util : debugLog, verify, verifyFail;
import util.writer : finishWriterToCStr, Writer;

void checkConcreteProgram(
	in AllSymbols allSymbols,
	in Program program,
	in ConcreteCommonTypes types,
	in ConcreteProgram a,
) {
	Ctx ctx = Ctx(ptrTrustMe(allSymbols), ptrTrustMe(program), ptrTrustMe(types));
	foreach (ConcreteFun* fun; a.allFuns)
		if (body_(*fun).isA!ConcreteExpr)
			checkExpr(ctx, fun.returnType, body_(*fun).as!ConcreteExpr);
}

immutable struct ConcreteCommonTypes {
	ConcreteType bool_;
	ConcreteType cString;
	ConcreteType void_;
}

private:

struct Ctx {
	const AllSymbols* allSymbols;
	Program* program;
	ConcreteCommonTypes* types;
}

void checkExpr(ref Ctx ctx, in ConcreteType type, in ConcreteExpr expr) {
	verify(!isBogus(type) || expr.kind.isA!(ConcreteExprKind.Throw*));
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
		(in ConcreteExprKind.ClosureGet x) {
			checkType(ctx, type, x.closureRef.type);
		},
		(in ConcreteExprKind.ClosureSet x) {
			checkExpr(ctx, x.closureRef.type, x.value);
		},
		(in Constant) {},
		(in ConcreteExprKind.CreateArr x) {
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
			verify(isVoid(type));
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
			verify(isVoid(type));
			checkExpr(ctx, x.local.type, x.value);
		},
		(in ConcreteExprKind.Loop x) {
			checkExpr(ctx, ctx.types.void_, x.body_);
		},
		(in ConcreteExprKind.LoopBreak x) {
			verify(isVoid(type));
			// TODO: use type from loop
			checkExprAnyType(ctx, x.value);
		},
		(in ConcreteExprKind.LoopContinue) {
			verify(isVoid(type));
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
			checkExpr(ctx, ctx.types.cString, x.thrown);
		});
}

void checkExprAnyType(ref Ctx ctx, in ConcreteExpr expr) {
	checkExpr(ctx, expr.type, expr);
}

void checkType(in Ctx ctx, in ConcreteType expected, in ConcreteType actual) {
	if (expected != actual) {
		withStackAlloc!1024((ref Alloc alloc) {
			Writer writer = Writer(&alloc);
			writer ~= "expected ";
			writeConcreteType(writer, *ctx.allSymbols, *ctx.program, expected);
			writer ~= " but was ";
			writeConcreteType(writer, *ctx.allSymbols, *ctx.program, actual);
			debugLog(finishWriterToCStr(writer));
		});
		verifyFail();
	}
}