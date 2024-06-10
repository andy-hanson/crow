module lower.checkLowModel;

@safe @nogc pure nothrow:

import frontend.showModel : ShowCtx;
import lower.lowExprHelpers :
	boolType,
	char8Type,
	char32Type,
	float32Type,
	float64Type,
	int8Type,
	int16Type,
	int32Type,
	int64Type,
	nat8Type,
	nat16Type,
	nat32Type,
	nat64Type,
	voidType;
import model.constant : Constant;
import model.jsonOfConcreteModel : jsonOfConcreteStructRef;
import model.concreteModel : ConcreteFun, ConcreteProgram;
import model.lowModel :
	asNonGcPointee,
	asPointee,
	isPointerNonGc,
	isVoid,
	LowCommonTypes,
	LowExpr,
	LowExprKind,
	LowExternType,
	LowField,
	LowFun,
	LowFunBody,
	LowFunExprBody,
	LowFunPointerType,
	LowLocal,
	LowProgram,
	LowRecord,
	LowType,
	LowUnion,
	PrimitiveType,
	UpdateParam;
import model.model :
	Builtin4ary, BuiltinBinary, BuiltinBinaryMath, BuiltinTernary, BuiltinUnary, BuiltinUnaryMath, Program;
import model.showLowModel : writeFunName;
import util.alloc.alloc : Alloc;
import util.col.array : sizeEq;
import util.col.array : zip;
import util.json : field, Json, jsonObject, jsonString, kindField;
import util.opt : force, has, none, Opt, some;
import util.util : castNonScope, ptrTrustMe, stringOfEnum;
import util.writer : debugLogWithWriter, Writer;

void checkLowProgram(in ShowCtx showCtx, in Program program, in ConcreteProgram concreteProgram, in LowProgram a) {
	Ctx ctx = Ctx(ptrTrustMe(showCtx), ptrTrustMe(program), ptrTrustMe(concreteProgram), ptrTrustMe(a));
	foreach (ref LowFun fun; a.allFuns)
		checkLowFun(ctx, fun);
}

private:

const struct Ctx {
	@safe @nogc pure nothrow:

	ShowCtx* showCtx;
	Program* modelProgramPtr;
	ConcreteProgram* concreteProgramPtr;
	LowProgram* programPtr;

	ref Program modelProgram() return scope const =>
		*modelProgramPtr;
	ref ConcreteProgram concreteProgram() return scope const =>
		*concreteProgramPtr;
	ref LowProgram program() return scope const =>
		*programPtr;
}

struct FunCtx {
	@safe @nogc pure nothrow:

	Ctx* ctxPtr;
	immutable LowFun* funPtr;

	ref inout(Ctx) ctx() return scope inout =>
		*ctxPtr;

	ref LowFun fun() return scope const =>
		*funPtr;

	ref LowProgram program() return scope const =>
		ctx.program;

	ref LowCommonTypes commonTypes() return scope const =>
		program.commonTypes;
}

void checkLowFun(ref Ctx ctx, in LowFun fun) {
	fun.body_.matchIn!void(
		(in LowFunBody.Extern) {},
		(in LowFunExprBody x) {
			FunCtx funCtx = FunCtx(ptrTrustMe(ctx), ptrTrustMe(fun));
			checkLowExpr(funCtx, fun.returnType, x.expr, ExprPos.tail);
		});
}

enum ExprPos { nonTail, tail, loop }

void checkLowExpr(ref FunCtx ctx, in LowType type, in LowExpr expr, in ExprPos exprPos) {
	checkTypeEqual(ctx, type, expr.type);
	expr.kind.matchIn!void(
		(in LowExprKind.Abort) {},
		(in LowExprKind.Call x) {
			LowFun* fun = &ctx.program.allFuns[x.called];
			assert(
				!fun.mayYield ||
				ctx.fun.mayYield ||
				ctx.fun.source.as!(ConcreteFun*) == ctx.ctx.concreteProgram.commonFuns.runFiber);
			checkTypeEqual(ctx, type, fun.returnType);
			zip!(LowLocal, LowExpr)(fun.params, x.args, (ref LowLocal param, ref LowExpr arg) {
				checkLowExpr(ctx, param.type, arg, ExprPos.nonTail);
			});
		},
		(in LowExprKind.CallFunPointer x) {
			checkTypeEqual(ctx, type, x.funPointerType.returnType);
			assert(sizeEq(x.funPointerType.paramTypes, x.args));
			zip!(LowType, LowExpr)(x.funPointerType.paramTypes, x.args, (ref LowType paramType, ref LowExpr arg) {
				checkLowExpr(ctx, paramType, arg, ExprPos.nonTail);
			});
		},
		(in LowExprKind.CreateRecord x) {
			zip!(LowField, LowExpr)(type.as!(LowRecord*).fields, x.args, (ref LowField field, ref LowExpr arg) {
				checkLowExpr(ctx, field.type, arg, ExprPos.nonTail);
			});
		},
		(in LowExprKind.CreateUnion x) {
			checkLowExpr(ctx, type.as!(LowUnion*).members[x.memberIndex], x.arg, ExprPos.nonTail);
		},
		(in LowExprKind.FunPointer x) {
			// TODO
		},
		(in LowExprKind.If it) {
			checkLowExpr(ctx, boolType, it.cond, ExprPos.nonTail);
			checkLowExpr(ctx, type, it.then, exprPos);
			checkLowExpr(ctx, type, it.else_, exprPos);
		},
		(in LowExprKind.Init) {
			assert(isVoid(type));
		},
		(in LowExprKind.Let x) {
			checkLowExpr(ctx, x.local.type, x.value, ExprPos.nonTail);
			checkLowExpr(ctx, type, x.then, exprPos);
		},
		(in LowExprKind.LocalGet x) {
			checkTypeEqual(ctx, type, x.local.type);
		},
		(in LowExprKind.LocalPointer x) {
			checkTypeEqual(ctx, asNonGcPointee(type), x.local.type);
		},
		(in LowExprKind.LocalSet x) {
			checkTypeEqual(ctx, type, voidType);
			checkLowExpr(ctx, x.local.type, x.value, ExprPos.nonTail);
		},
		(in LowExprKind.Loop x) {
			checkLowExpr(ctx, type, x.body_, ExprPos.loop);
		},
		(in LowExprKind.LoopBreak x) {
			checkLowExpr(ctx, type, x.value, ExprPos.nonTail);
		},
		(in LowExprKind.LoopContinue x) {
			assert(exprPos == ExprPos.loop);
		},
		(in LowExprKind.PointerCast x) {
			// TODO: there are some limitations on target...
			checkLowExpr(ctx, x.target.type, x.target, ExprPos.nonTail);
		},
		(in LowExprKind.RecordFieldGet x) {
			checkLowExpr(ctx, x.target.type, *x.target, ExprPos.nonTail);
			LowType fieldType = x.targetRecordType.fields[x.fieldIndex].type;
			checkTypeEqual(ctx, type, fieldType);
		},
		(in LowExprKind.RecordFieldPointer x) {
			checkLowExpr(ctx, x.target.type, *x.target, ExprPos.nonTail);
			LowType fieldType = x.targetRecordType.fields[x.fieldIndex].type;
			checkTypeEqual(ctx, asNonGcPointee(type), fieldType);
		},
		(in LowExprKind.RecordFieldSet x) {
			checkLowExpr(ctx, x.target.type, x.target, ExprPos.nonTail);
			LowType fieldType = x.targetRecordType.fields[x.fieldIndex].type;
			checkLowExpr(ctx, fieldType, x.value, ExprPos.nonTail);
			checkTypeEqual(ctx, type, voidType);
		},
		(in Constant _) {
			// Constants are untyped, so can't check more
		},
		(in LowExprKind.SpecialUnary x) {
			checkSpecialUnary(ctx, type, x);
		},
		(in LowExprKind.SpecialUnaryMath x) {
			LowType actual = unaryMathType(x.kind);
			checkTypeEqual(ctx, type, actual);
			checkLowExpr(ctx, actual, x.arg, ExprPos.nonTail);
		},
		(in LowExprKind.SpecialBinary it) {
			checkSpecialBinary(ctx, type, it, exprPos);
		},
		(in LowExprKind.SpecialBinaryMath x) {
			LowType actual = binaryMathType(x.kind);
			checkTypeEqual(ctx, type, actual);
			foreach (scope ref LowExpr arg; castNonScope(x.args))
				checkLowExpr(ctx, actual, arg, ExprPos.nonTail);
		},
		(in LowExprKind.SpecialTernary x) {
			final switch (x.kind) {
				case BuiltinTernary.interpreterBacktrace:
					// TODO
					break;
			}
		},
		(in LowExprKind.Special4ary x) {
			final switch (x.kind) {
				case Builtin4ary.switchFiberInitial:
					checkTypeEqual(ctx, type, voidType);
					checkLowExpr(ctx, ctx.commonTypes.fiberReference, x.args[0], ExprPos.nonTail);
					checkLowExpr(ctx, ctx.commonTypes.nat64MutPointerMutPointer, x.args[1], ExprPos.nonTail);
					checkLowExpr(ctx, ctx.commonTypes.nat64MutPointer, x.args[2], ExprPos.nonTail);
					// TODO: x.args[3] is a 'void function(a fiber)'
					break;
			}
		},
		(in LowExprKind.Switch x) {
			checkLowExpr(ctx, x.value.type, x.value, ExprPos.nonTail);
			foreach (ref LowExpr case_; x.caseExprs)
				checkLowExpr(ctx, type, case_, exprPos);
		},
		(in LowExprKind.TailRecur it) {
			assert(exprPos == ExprPos.tail);
			foreach (ref UpdateParam update; it.updateParams)
				checkLowExpr(ctx, update.param.type, update.newValue, ExprPos.nonTail);
		},
		(in LowExprKind.UnionAs x) {
			checkTypeEqual(ctx, type, x.union_.type.as!(LowUnion*).members[x.memberIndex]);
			checkLowExpr(ctx, x.union_.type, *x.union_, ExprPos.nonTail);
		},
		(in LowExprKind.UnionKind x) {
			checkTypeEqual(ctx, type, LowType(PrimitiveType.nat64));
			checkLowExpr(ctx, x.union_.type, *x.union_, ExprPos.nonTail);
		},
		(in LowExprKind.VarGet x) {
			checkTypeEqual(ctx, type, ctx.program.vars[x.varIndex].type);
		},
		(in LowExprKind.VarSet x) {
			checkTypeEqual(ctx, type, voidType);
			checkLowExpr(ctx, ctx.program.vars[x.varIndex].type, *x.value, ExprPos.nonTail);
		});
}

void checkSpecialUnary(ref FunCtx ctx, in LowType type, in LowExprKind.SpecialUnary a) {
	ExpectUnary expected = unaryExpected(ctx.commonTypes, a.kind, type, a.arg.type);
	if (has(expected.return_))
		checkTypeEqual(ctx, force(expected.return_), type);
	checkLowExpr(ctx, has(expected.arg) ? force(expected.arg) : a.arg.type, a.arg, ExprPos.nonTail);
}

ExpectUnary unaryExpected(
	ref LowCommonTypes commonTypes,
	BuiltinUnary kind,
	return scope LowType returnType,
	return scope LowType argType,
) {
	final switch (kind) {
		case BuiltinUnary.referenceFromPointer:
		case BuiltinUnary.asAnyPointer:
			//TODO: returns one of anyPtrConstType or anyPtrMutType. Maybe split these up
			return ExpectUnary();
		case BuiltinUnary.enumToIntegral:
			return ExpectUnary();
		case BuiltinUnary.bitwiseNotNat8:
			return expect(nat8Type, nat8Type);
		case BuiltinUnary.bitwiseNotNat16:
			return expect(nat16Type, nat16Type);
		case BuiltinUnary.bitwiseNotNat32:
			return expect(nat32Type, nat32Type);
		case BuiltinUnary.bitwiseNotNat64:
		case BuiltinUnary.countOnesNat64:
			return expect(nat64Type, nat64Type);
		case BuiltinUnary.deref:
			return ExpectUnary(some(asPointee(argType)), none!LowType);
		case BuiltinUnary.drop:
			return ExpectUnary(some(voidType), none!LowType);
		case BuiltinUnary.isNanFloat32:
			return expect(boolType, float32Type);
		case BuiltinUnary.isNanFloat64:
			return expect(boolType, float64Type);
		case BuiltinUnary.jumpToCatch:
			return expect(voidType, commonTypes.catchPointConstPointer);
		case BuiltinUnary.setupCatch:
			return expect(boolType, commonTypes.catchPointMutPointer);
		case BuiltinUnary.toChar8FromNat8:
			return expect(char8Type, nat8Type);
		case BuiltinUnary.toFloat32FromFloat64:
			return expect(float32Type, float64Type);
		case BuiltinUnary.toFloat64FromFloat32:
			return expect(float64Type, float32Type);
		case BuiltinUnary.toFloat64FromInt64:
			return expect(float64Type, int64Type);
		case BuiltinUnary.toFloat64FromNat64:
			return expect(float64Type, nat64Type);
		case BuiltinUnary.toInt64FromInt8:
			return expect(int64Type, int8Type);
		case BuiltinUnary.toInt64FromInt16:
			return expect(int64Type, int16Type);
		case BuiltinUnary.toInt64FromInt32:
			return expect(int64Type, int32Type);
		case BuiltinUnary.toNat8FromChar8:
			return expect(nat8Type, char8Type);
		case BuiltinUnary.toNat32FromChar32:
			return expect(nat32Type, char32Type);
		case BuiltinUnary.toNat64FromNat8:
			return expect(nat64Type, nat8Type);
		case BuiltinUnary.toNat64FromNat16:
			return expect(nat64Type, nat16Type);
		case BuiltinUnary.toNat64FromNat32:
			return expect(nat64Type, nat32Type);
		case BuiltinUnary.toNat64FromPtr:
			assert(isPointerNonGc(argType));
			return ExpectUnary(some(nat64Type), none!LowType);
		case BuiltinUnary.toPtrFromNat64:
			assert(isPointerNonGc(returnType));
			return ExpectUnary(none!LowType, some(nat64Type));
		case BuiltinUnary.truncateToInt64FromFloat64:
			return expect(int64Type, float64Type);
		case BuiltinUnary.unsafeToChar32FromChar8:
			return expect(char32Type, char8Type);
		case BuiltinUnary.unsafeToChar32FromNat32:
			return expect(char32Type, nat32Type);
		case BuiltinUnary.unsafeToInt8FromInt64:
			return expect(int8Type, int64Type);
		case BuiltinUnary.unsafeToInt16FromInt64:
			return expect(int16Type, int64Type);
		case BuiltinUnary.unsafeToInt32FromInt64:
			return expect(int32Type, int64Type);
		case BuiltinUnary.unsafeToInt64FromNat64:
			return expect(int64Type, nat64Type);
		case BuiltinUnary.unsafeToNat8FromNat64:
			return expect(nat8Type, nat64Type);
		case BuiltinUnary.unsafeToNat16FromNat64:
			return expect(nat16Type, nat64Type);
		case BuiltinUnary.unsafeToNat32FromInt32:
			return expect(nat32Type, int32Type);
		case BuiltinUnary.unsafeToNat32FromNat64:
			return expect(nat32Type, nat64Type);
		case BuiltinUnary.unsafeToNat64FromInt64:
			return expect(nat64Type, int64Type);
	}
}

LowType unaryMathType(BuiltinUnaryMath kind) {
	final switch (kind) {
		case BuiltinUnaryMath.acosFloat32:
		case BuiltinUnaryMath.acoshFloat32:
		case BuiltinUnaryMath.asinFloat32:
		case BuiltinUnaryMath.asinhFloat32:
		case BuiltinUnaryMath.atanFloat32:
		case BuiltinUnaryMath.atanhFloat32:
		case BuiltinUnaryMath.cosFloat32:
		case BuiltinUnaryMath.coshFloat32:
		case BuiltinUnaryMath.roundFloat32:
		case BuiltinUnaryMath.sinFloat32:
		case BuiltinUnaryMath.sinhFloat32:
		case BuiltinUnaryMath.sqrtFloat32:
		case BuiltinUnaryMath.tanFloat32:
		case BuiltinUnaryMath.tanhFloat32:
		case BuiltinUnaryMath.unsafeLogFloat32:
			return float32Type;
		case BuiltinUnaryMath.acosFloat64:
		case BuiltinUnaryMath.acoshFloat64:
		case BuiltinUnaryMath.asinFloat64:
		case BuiltinUnaryMath.asinhFloat64:
		case BuiltinUnaryMath.atanFloat64:
		case BuiltinUnaryMath.atanhFloat64:
		case BuiltinUnaryMath.cosFloat64:
		case BuiltinUnaryMath.coshFloat64:
		case BuiltinUnaryMath.sinFloat64:
		case BuiltinUnaryMath.sinhFloat64:
		case BuiltinUnaryMath.tanFloat64:
		case BuiltinUnaryMath.tanhFloat64:
		case BuiltinUnaryMath.roundFloat64:
		case BuiltinUnaryMath.sqrtFloat64:
		case BuiltinUnaryMath.unsafeLogFloat64:
			return float64Type;
	}
}

immutable struct ExpectUnary {
	Opt!LowType return_;
	Opt!LowType arg;
}
ExpectUnary expect() =>
	ExpectUnary(none!LowType, none!LowType);
ExpectUnary expect(LowType return_, LowType arg) =>
	ExpectUnary(some(return_), some(arg));

void checkSpecialBinary(ref FunCtx ctx, in LowType type, in LowExprKind.SpecialBinary a, in ExprPos exprPos) {
	ExpectBinary expected = binaryExpected(ctx.commonTypes, a.kind, type, a.args[0].type, a.args[1].type);
	if (has(expected.return_))
		checkTypeEqual(ctx, force(expected.return_), type);
	foreach (size_t i; 0 .. a.args.length)
		checkLowExpr(
			ctx, has(expected.args[i]) ? force(expected.args[i]) : a.args[i].type, a.args[i],
			i == 1 && canTailRecurse(a.kind) ? exprPos : ExprPos.nonTail);
}

bool canTailRecurse(BuiltinBinary a) =>
	a == BuiltinBinary.seq;

ExpectBinary binaryExpected(
	ref LowCommonTypes commonTypes,
	in BuiltinBinary kind,
	in LowType returnType,
	return scope LowType arg0Type,
	in LowType arg1Type,
) {
	final switch (kind) {
		case BuiltinBinary.addFloat32:
		case BuiltinBinary.mulFloat32:
		case BuiltinBinary.subFloat32:
		case BuiltinBinary.unsafeDivFloat32:
			return expect(float32Type, float32Type, float32Type);
		case BuiltinBinary.addFloat64:
		case BuiltinBinary.mulFloat64:
		case BuiltinBinary.subFloat64:
		case BuiltinBinary.unsafeDivFloat64:
			return expect(float64Type, float64Type, float64Type);
		case BuiltinBinary.addPointerAndNat64:
		case BuiltinBinary.subPointerAndNat64:
			assert(returnType == arg0Type);
			assert(isPointerNonGc(returnType));
			return ExpectBinary(none!LowType, [none!LowType, some(nat64Type)]);
		case BuiltinBinary.bitwiseAndInt8:
		case BuiltinBinary.bitwiseOrInt8:
		case BuiltinBinary.bitwiseXorInt8:
		case BuiltinBinary.unsafeAddInt8:
		case BuiltinBinary.unsafeDivInt8:
		case BuiltinBinary.unsafeMulInt8:
		case BuiltinBinary.unsafeSubInt8:
			return expect(int8Type, int8Type, int8Type);
		case BuiltinBinary.bitwiseAndInt16:
		case BuiltinBinary.bitwiseOrInt16:
		case BuiltinBinary.bitwiseXorInt16:
		case BuiltinBinary.unsafeAddInt16:
		case BuiltinBinary.unsafeDivInt16:
		case BuiltinBinary.unsafeMulInt16:
		case BuiltinBinary.unsafeSubInt16:
			return expect(int16Type, int16Type, int16Type);
		case BuiltinBinary.bitwiseAndInt32:
		case BuiltinBinary.bitwiseOrInt32:
		case BuiltinBinary.bitwiseXorInt32:
		case BuiltinBinary.unsafeAddInt32:
		case BuiltinBinary.unsafeDivInt32:
		case BuiltinBinary.unsafeMulInt32:
		case BuiltinBinary.unsafeSubInt32:
			return expect(int32Type, int32Type, int32Type);
		case BuiltinBinary.bitwiseAndInt64:
		case BuiltinBinary.bitwiseOrInt64:
		case BuiltinBinary.bitwiseXorInt64:
		case BuiltinBinary.unsafeAddInt64:
		case BuiltinBinary.unsafeDivInt64:
		case BuiltinBinary.unsafeMulInt64:
		case BuiltinBinary.unsafeSubInt64:
			return expect(int64Type, int64Type, int64Type);
		case BuiltinBinary.bitwiseAndNat8:
		case BuiltinBinary.bitwiseOrNat8:
		case BuiltinBinary.bitwiseXorNat8:
		case BuiltinBinary.unsafeDivNat8:
		case BuiltinBinary.wrapAddNat8:
		case BuiltinBinary.wrapMulNat8:
		case BuiltinBinary.wrapSubNat8:
			return expect(nat8Type, nat8Type, nat8Type);
		case BuiltinBinary.bitwiseAndNat16:
		case BuiltinBinary.bitwiseOrNat16:
		case BuiltinBinary.bitwiseXorNat16:
		case BuiltinBinary.unsafeDivNat16:
		case BuiltinBinary.wrapAddNat16:
		case BuiltinBinary.wrapMulNat16:
		case BuiltinBinary.wrapSubNat16:
			return expect(nat16Type, nat16Type, nat16Type);
		case BuiltinBinary.bitwiseAndNat32:
		case BuiltinBinary.bitwiseOrNat32:
		case BuiltinBinary.bitwiseXorNat32:
		case BuiltinBinary.unsafeDivNat32:
		case BuiltinBinary.wrapAddNat32:
		case BuiltinBinary.wrapMulNat32:
		case BuiltinBinary.wrapSubNat32:
			return expect(nat32Type, nat32Type, nat32Type);
		case BuiltinBinary.bitwiseAndNat64:
		case BuiltinBinary.bitwiseOrNat64:
		case BuiltinBinary.bitwiseXorNat64:
		case BuiltinBinary.unsafeBitShiftLeftNat64:
		case BuiltinBinary.unsafeBitShiftRightNat64:
		case BuiltinBinary.unsafeDivNat64:
		case BuiltinBinary.unsafeModNat64:
		case BuiltinBinary.wrapAddNat64:
		case BuiltinBinary.wrapMulNat64:
		case BuiltinBinary.wrapSubNat64:
			return expect(nat64Type, nat64Type, nat64Type);
		case BuiltinBinary.eqChar8:
			return expect(boolType, char8Type, char8Type);
		case BuiltinBinary.eqChar32:
			return expect(boolType, char32Type, char32Type);
		case BuiltinBinary.eqFloat32:
		case BuiltinBinary.lessFloat32:
			return expect(boolType, float32Type, float32Type);
		case BuiltinBinary.eqFloat64:
		case BuiltinBinary.lessFloat64:
			return expect(boolType, float64Type, float64Type);
		case BuiltinBinary.eqInt8:
		case BuiltinBinary.lessInt8:
			return expect(boolType, int8Type, int8Type);
		case BuiltinBinary.eqInt16:
		case BuiltinBinary.lessInt16:
			return expect(boolType, int16Type, int16Type);
		case BuiltinBinary.eqInt32:
		case BuiltinBinary.lessInt32:
			return expect(boolType, int32Type, int32Type);
		case BuiltinBinary.eqInt64:
		case BuiltinBinary.lessInt64:
			return expect(boolType, int64Type, int64Type);
		case BuiltinBinary.eqNat8:
		case BuiltinBinary.lessNat8:
			return expect(boolType, nat8Type, nat8Type);
		case BuiltinBinary.eqNat16:
		case BuiltinBinary.lessNat16:
			return expect(boolType, nat16Type, nat16Type);
		case BuiltinBinary.eqNat32:
		case BuiltinBinary.lessNat32:
			return expect(boolType, nat32Type, nat32Type);
		case BuiltinBinary.eqNat64:
		case BuiltinBinary.lessNat64:
			return expect(boolType, nat64Type, nat64Type);
		case BuiltinBinary.eqPointer:
		case BuiltinBinary.lessPointer:
			assert(arg0Type == arg1Type);
			return ExpectBinary(some(boolType), [none!LowType, none!LowType]);
		case BuiltinBinary.lessChar8:
			return expect(boolType, char8Type, char8Type);
		case BuiltinBinary.seq:
			assert(returnType == arg1Type);
			return ExpectBinary(none!LowType, [some(voidType), none!LowType]);
		case BuiltinBinary.switchFiber:
			return expect(voidType, commonTypes.nat64MutPointerMutPointer, commonTypes.nat64MutPointer);
		case BuiltinBinary.writeToPointer:
			return ExpectBinary(some(voidType), [none!LowType, some(asPointee(arg0Type))]);
	}
}

LowType binaryMathType(BuiltinBinaryMath kind) {
	final switch (kind) {
		case BuiltinBinaryMath.atan2Float32:
			return float32Type;
		case BuiltinBinaryMath.atan2Float64:
			return float64Type;
	}
}

immutable struct ExpectBinary {
	Opt!LowType return_;
	Opt!LowType[2] args;
}
ExpectBinary expect(LowType return_, LowType arg0, LowType arg1) =>
	ExpectBinary(some(return_), [some(arg0), some(arg1)]);

void checkTypeEqual(in FunCtx ctx, in LowType expected, in LowType actual) {
	if (expected != actual)
		debugLogWithWriter((scope ref Alloc alloc, scope ref Writer writer) {
			writer ~= "In ";
			writeFunName(writer, *ctx.ctx.showCtx, ctx.program, ctx.fun);
			writer ~= ":\nType is not as expected. Expected:\n";
			writer ~= jsonOfLowType2(alloc, ctx.program, expected);
			writer ~= "\nActual:\n";
			writer ~= jsonOfLowType2(alloc, ctx.program, actual);
		});
	assert(expected == actual);
}

Json jsonOfLowType2(ref Alloc alloc, in LowProgram program, in LowType a) =>
	a.matchIn!Json(
		(in LowExternType _) =>
			jsonString!"some-extern", //TODO: more detail
		(in LowFunPointerType _) =>
			jsonString!"some-fun-ptr", //TODO: more detail
		(in PrimitiveType x) =>
			jsonString(stringOfEnum(x)),
		(in LowType.PointerGc x) =>
			jsonObject(alloc, [
				kindField!"pointer-gc",
				field!"pointee"(jsonOfLowType2(alloc, program, *x.pointee))]),
		(in LowType.PointerConst x) =>
			jsonObject(alloc, [
				kindField!"pointer-const",
				field!"pointee"(jsonOfLowType2(alloc, program, *x.pointee))]),
		(in LowType.PointerMut x) =>
			jsonObject(alloc, [
				kindField!"pointer-mut",
				field!"pointee"(jsonOfLowType2(alloc, program, *x.pointee))]),
		(in LowRecord x) =>
			jsonOfConcreteStructRef(alloc, *x.source),
		(in LowUnion x) =>
			jsonOfConcreteStructRef(alloc, *x.source));
