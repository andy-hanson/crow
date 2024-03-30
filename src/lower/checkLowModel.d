module lower.checkLowModel;

@safe @nogc pure nothrow:

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
import model.lowModel :
	asGcOrRawPointee,
	isPtrGcOrRaw,
	isVoid,
	LowExpr,
	LowExprKind,
	LowField,
	LowFun,
	LowFunBody,
	LowFunExprBody,
	LowFunPointerType,
	LowLocal,
	LowProgram,
	LowType,
	PrimitiveType,
	targetIsPointer,
	targetRecordType,
	UpdateParam;
import model.model : BuiltinBinary, BuiltinBinaryMath, BuiltinUnary, BuiltinUnaryMath, Program;
import util.alloc.alloc : Alloc;
import util.col.array : sizeEq;
import util.col.array : zip;
import util.json : field, Json, jsonObject, jsonString, kindField;
import util.opt : force, has, none, Opt, some;
import util.util : castNonScope, ptrTrustMe, stringOfEnum;
import util.writer : debugLogWithWriter, Writer;

void checkLowProgram(in Program program, in LowProgram a) {
	Ctx ctx = Ctx(ptrTrustMe(program), ptrTrustMe(a));
	foreach (ref LowFun fun; a.allFuns)
		checkLowFun(ctx, fun);
}

private:

struct Ctx {
	@safe @nogc pure nothrow:

	immutable Program* modelProgramPtr;
	immutable LowProgram* programPtr;

	ref Program modelProgram() return scope const =>
		*modelProgramPtr;

	ref LowProgram program() return scope const =>
		*programPtr;
}

struct FunCtx {
	@safe @nogc pure nothrow:

	Ctx* ctxPtr;
	immutable LowFun* funPtr;

	ref Ctx ctx() return scope =>
		*ctxPtr;

	ref LowFun fun() return scope const =>
		*funPtr;
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
	checkTypeEqual(ctx.ctx, type, expr.type);
	expr.kind.matchIn!void(
		(in LowExprKind.Abort) {},
		(in LowExprKind.Call it) {
			LowFun* fun = &ctx.ctx.program.allFuns[it.called];
			checkTypeEqual(ctx.ctx, type, fun.returnType);
			assert(sizeEq(fun.params, it.args));
			zip!(LowLocal, LowExpr)(fun.params, it.args, (ref LowLocal param, ref LowExpr arg) {
				checkLowExpr(ctx, param.type, arg, ExprPos.nonTail);
			});
		},
		(in LowExprKind.CallFunPointer it) {
			LowFunPointerType funPtrType = ctx.ctx.program.allFunPointerTypes[it.funPtr.type.as!(LowType.FunPointer)];
			checkTypeEqual(ctx.ctx, type, funPtrType.returnType);
			assert(sizeEq(funPtrType.paramTypes, it.args));
			zip!(LowType, LowExpr)(funPtrType.paramTypes, it.args, (ref LowType paramType, ref LowExpr arg) {
				checkLowExpr(ctx, paramType, arg, ExprPos.nonTail);
			});
		},
		(in LowExprKind.CreateRecord it) {
			LowField[] fields = ctx.ctx.program.allRecords[type.as!(LowType.Record)].fields;
			zip!(LowField, LowExpr)(fields, it.args, (ref LowField field, ref LowExpr arg) {
				checkLowExpr(ctx, field.type, arg, ExprPos.nonTail);
			});
		},
		(in LowExprKind.CreateUnion it) {
			LowType member = ctx.ctx.program.allUnions[type.as!(LowType.Union)].members[it.memberIndex];
			checkLowExpr(ctx, member, it.arg, ExprPos.nonTail);
		},
		(in LowExprKind.If it) {
			checkLowExpr(ctx, boolType, it.cond, ExprPos.nonTail);
			checkLowExpr(ctx, type, it.then, exprPos);
			checkLowExpr(ctx, type, it.else_, exprPos);
		},
		(in LowExprKind.InitConstants) {
			assert(isVoid(type));
		},
		(in LowExprKind.Let it) {
			checkLowExpr(ctx, it.local.type, it.value, ExprPos.nonTail);
			checkLowExpr(ctx, type, it.then, exprPos);
		},
		(in LowExprKind.LocalGet it) {
			checkTypeEqual(ctx.ctx, type, it.local.type);
		},
		(in LowExprKind.LocalSet it) {
			checkTypeEqual(ctx.ctx, type, voidType);
			checkLowExpr(ctx, it.local.type, it.value, ExprPos.nonTail);
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
		(in LowExprKind.PtrCast x) {
			// TODO: there are some limitations on target...
			checkLowExpr(ctx, x.target.type, x.target, ExprPos.nonTail);
		},
		(in LowExprKind.PtrToField it) {
			checkLowExpr(ctx, it.target.type, it.target, ExprPos.nonTail);
			LowType fieldType = ctx.ctx.program.allRecords[targetRecordType(it)].fields[it.fieldIndex].type;
			checkTypeEqual(ctx.ctx, asGcOrRawPointee(type), fieldType);
		},
		(in LowExprKind.PtrToLocal it) {
			checkTypeEqual(ctx.ctx, asGcOrRawPointee(type), it.local.type);
		},
		(in LowExprKind.RecordFieldGet x) {
			LowType.Record recordType = targetRecordType(x);
			checkLowExpr(ctx, x.target.type, *x.target, ExprPos.nonTail);
			LowType fieldType = ctx.ctx.program.allRecords[recordType].fields[x.fieldIndex].type;
			checkTypeEqual(ctx.ctx, type, fieldType);
		},
		(in LowExprKind.RecordFieldSet x) {
			LowType.Record recordType = targetRecordType(x);
			assert(targetIsPointer(x)); // TODO: then this function doesn't need to exist
			checkLowExpr(ctx, x.target.type, x.target, ExprPos.nonTail);
			LowType fieldType = ctx.ctx.program.allRecords[recordType].fields[x.fieldIndex].type;
			checkLowExpr(ctx, fieldType, x.value, ExprPos.nonTail);
			checkTypeEqual(ctx.ctx, type, voidType);
		},
		(in Constant it) {
			// Constants are untyped, so can't check more
		},
		(in LowExprKind.SpecialUnary it) {
			checkSpecialUnary(ctx, type, it);
		},
		(in LowExprKind.SpecialUnaryMath x) {
			LowType actual = unaryMathType(x.kind);
			checkTypeEqual(ctx.ctx, type, actual);
			checkLowExpr(ctx, actual, x.arg, ExprPos.nonTail);
		},
		(in LowExprKind.SpecialBinary it) {
			checkSpecialBinary(ctx, type, it, exprPos);
		},
		(in LowExprKind.SpecialBinaryMath x) {
			LowType actual = binaryMathType(x.kind);
			checkTypeEqual(ctx.ctx, type, actual);
			foreach (scope ref LowExpr arg; castNonScope(x.args))
				checkLowExpr(ctx, actual, arg, ExprPos.nonTail);
		},
		(in LowExprKind.SpecialTernary) {
			// TODO
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
			checkTypeEqual(
				ctx.ctx, type,
				ctx.ctx.program.allUnions[x.union_.type.as!(LowType.Union)].members[x.memberIndex]);
			checkLowExpr(ctx, x.union_.type, *x.union_, ExprPos.nonTail);
		},
		(in LowExprKind.UnionKind x) {
			checkTypeEqual(ctx.ctx, type, LowType(PrimitiveType.nat64));
			checkLowExpr(ctx, x.union_.type, *x.union_, ExprPos.nonTail);
		},
		(in LowExprKind.VarGet x) {
			checkTypeEqual(ctx.ctx, type, ctx.ctx.program.vars[x.varIndex].type);
		},
		(in LowExprKind.VarSet x) {
			checkTypeEqual(ctx.ctx, type, voidType);
			checkLowExpr(ctx, ctx.ctx.program.vars[x.varIndex].type, *x.value, ExprPos.nonTail);
		});
}

void checkSpecialUnary(ref FunCtx ctx, in LowType type, in LowExprKind.SpecialUnary a) {
	ExpectUnary expected = unaryExpected(a.kind, type, a.arg.type);
	if (has(expected.return_))
		checkTypeEqual(ctx.ctx, force(expected.return_), type);
	checkLowExpr(ctx, has(expected.arg) ? force(expected.arg) : a.arg.type, a.arg, ExprPos.nonTail);
}

ExpectUnary unaryExpected(
	BuiltinUnary kind,
	return scope LowType returnType,
	return scope LowType argType,
) {
	final switch (kind) {
		case BuiltinUnary.asAnyPtr:
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
			return ExpectUnary(some(asGcOrRawPointee(argType)), none!LowType);
		case BuiltinUnary.drop:
			return ExpectUnary(some(voidType), none!LowType);
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
			assert(isPtrGcOrRaw(argType));
			return ExpectUnary(some(nat64Type), none!LowType);
		case BuiltinUnary.toPtrFromNat64:
			assert(isPtrGcOrRaw(returnType));
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
	ExpectBinary expected = binaryExpected(a.kind, type, a.args[0].type, a.args[1].type);
	if (has(expected.return_))
		checkTypeEqual(ctx.ctx, force(expected.return_), type);
	foreach (size_t i; 0 .. a.args.length)
		checkLowExpr(
			ctx, has(expected.args[i]) ? force(expected.args[i]) : a.args[i].type, a.args[i],
			i == 1 && canTailRecurse(a.kind) ? exprPos : ExprPos.nonTail);
}

bool canTailRecurse(BuiltinBinary a) {
	switch (a) {
		case BuiltinBinary.and:
		case BuiltinBinary.orBool:
		case BuiltinBinary.seq:
			return true;
		default:
			return false;
	}
}

ExpectBinary binaryExpected(
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
		case BuiltinBinary.addPtrAndNat64:
		case BuiltinBinary.subPtrAndNat64:
			assert(returnType == arg0Type);
			assert(isPtrGcOrRaw(returnType));
			return ExpectBinary(none!LowType, [none!LowType, some(nat64Type)]);
		case BuiltinBinary.and:
		case BuiltinBinary.orBool:
			return expect(boolType, boolType, boolType);
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
		case BuiltinBinary.eqPtr:
		case BuiltinBinary.lessPtr:
			assert(arg0Type == arg1Type);
			return ExpectBinary(some(boolType), [none!LowType, none!LowType]);
		case BuiltinBinary.lessChar8:
			return expect(boolType, char8Type, char8Type);
		case BuiltinBinary.seq:
			assert(returnType == arg1Type);
			return ExpectBinary(none!LowType, [some(voidType), none!LowType]);
		case BuiltinBinary.writeToPtr:
			return ExpectBinary(some(voidType), [none!LowType, some(asGcOrRawPointee(arg0Type))]);
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

void checkTypeEqual(ref Ctx ctx, in LowType expected, in LowType actual) {
	if (expected != actual)
		debugLogWithWriter((scope ref Alloc alloc, scope ref Writer writer) {
			writer ~= "Type is not as expected. Expected:\n";
			writer ~= jsonOfLowType2(alloc, ctx.program, expected);
			writer ~= "\nActual:\n";
			writer ~= jsonOfLowType2(alloc, ctx.program, actual);
		});
	assert(expected == actual);
}

Json jsonOfLowType2(ref Alloc alloc, in LowProgram program, in LowType a) =>
	a.matchIn!Json(
		(in LowType.Extern) =>
			jsonString!"some-extern", //TODO: more detail
		(in LowType.FunPointer) =>
			jsonString!"some-fun-ptr", //TODO: more detail
		(in PrimitiveType x) =>
			jsonString(stringOfEnum(x)),
		(in LowType.PtrGc x) =>
			jsonObject(alloc, [
				kindField!"gc-pointer",
				field!"pointee"(jsonOfLowType2(alloc, program, *x.pointee))]),
		(in LowType.PtrRawConst x) =>
			jsonObject(alloc, [
				kindField!"ptr-const",
				field!"pointee"(jsonOfLowType2(alloc, program, *x.pointee))]),
		(in LowType.PtrRawMut x) =>
			jsonObject(alloc, [
				kindField!"ptr-mut",
				field!"pointee"(jsonOfLowType2(alloc, program, *x.pointee))]),
		(in LowType.Record x) =>
			jsonOfConcreteStructRef(alloc, *program.allRecords[x].source),
		(in LowType.Union x) =>
			jsonOfConcreteStructRef(alloc, *program.allUnions[x].source));
