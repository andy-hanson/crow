module lower.checkLowModel;

@safe @nogc pure nothrow:

import lower.lowExprHelpers :
	boolType,
	char8Type,
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
	LowFunIndex,
	LowFunPtrType,
	LowLocal,
	LowProgram,
	LowType,
	PrimitiveType,
	targetIsPointer,
	targetRecordType,
	UpdateParam;
import model.model : Program;
import util.alloc.alloc : Alloc;
import util.col.arr : sizeEq;
import util.col.arrUtil : zip;
import util.col.stackMap : StackMap, stackMapAdd, stackMapMustGet;
import util.col.fullIndexMap : fullIndexMapEachValue;
import util.json : field, Json, jsonObject, jsonString, kindField, writeJson;
import util.opt : force, has, none, Opt, some;
import util.symbol : AllSymbols;
import util.util : ptrTrustMe, stringOfEnum;
import util.writer : debugLogWithWriter, Writer;

void checkLowProgram(in AllSymbols allSymbols, in Program program, in LowProgram a) {
	Ctx ctx = Ctx(ptrTrustMe(allSymbols), ptrTrustMe(program), ptrTrustMe(a));
	fullIndexMapEachValue!(LowFunIndex, LowFun)(a.allFuns, (ref LowFun fun) {
		checkLowFun(ctx, fun);
	});
}

private:

struct Ctx {
	@safe @nogc pure nothrow:

	const AllSymbols* allSymbolsPtr;
	immutable Program* modelProgramPtr;
	immutable LowProgram* programPtr;

	ref const(AllSymbols) allSymbols() return scope const =>
		*allSymbolsPtr;

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
		// TODO: not @trusted
		(in LowFunExprBody x) @trusted {
			FunCtx funCtx = FunCtx(ptrTrustMe(ctx), ptrTrustMe(fun));
			InfoStack info;
			checkLowExpr(funCtx, info, fun.returnType, x.expr);
		});
}

alias InfoStack = StackMap!(LowExprKind.Loop*, LowType);
alias addLoop = stackMapAdd!(LowExprKind.Loop*, LowType);
alias getLoop = stackMapMustGet!(LowExprKind.Loop*, LowType);

void checkLowExpr(ref FunCtx ctx, in InfoStack info, in LowType type, in LowExpr expr) {
	checkTypeEqual(ctx.ctx, type, expr.type);
	expr.kind.matchIn!void(
		(in LowExprKind.Call it) {
			LowFun* fun = &ctx.ctx.program.allFuns[it.called];
			checkTypeEqual(ctx.ctx, type, fun.returnType);
			assert(sizeEq(fun.params, it.args));
			zip!(LowLocal, LowExpr)(fun.params, it.args, (ref LowLocal param, ref LowExpr arg) {
				checkLowExpr(ctx, info, param.type, arg);
			});
		},
		(in LowExprKind.CallFunPtr it) {
			LowFunPtrType funPtrType = ctx.ctx.program.allFunPtrTypes[it.funPtr.type.as!(LowType.FunPtr)];
			checkTypeEqual(ctx.ctx, type, funPtrType.returnType);
			assert(sizeEq(funPtrType.paramTypes, it.args));
			zip!(LowType, LowExpr)(funPtrType.paramTypes, it.args, (ref LowType paramType, ref LowExpr arg) {
				checkLowExpr(ctx, info, paramType, arg);
			});
		},
		(in LowExprKind.CreateRecord it) {
			LowField[] fields = ctx.ctx.program.allRecords[type.as!(LowType.Record)].fields;
			zip!(LowField, LowExpr)(fields, it.args, (ref LowField field, ref LowExpr arg) {
				checkLowExpr(ctx, info, field.type, arg);
			});
		},
		(in LowExprKind.CreateUnion it) {
			LowType member = ctx.ctx.program.allUnions[type.as!(LowType.Union)].members[it.memberIndex];
			checkLowExpr(ctx, info, member, it.arg);
		},
		(in LowExprKind.If it) {
			checkLowExpr(ctx, info, boolType, it.cond);
			checkLowExpr(ctx, info, type, it.then);
			checkLowExpr(ctx, info, type, it.else_);
		},
		(in LowExprKind.InitConstants) {
			assert(isVoid(type));
		},
		(in LowExprKind.Let it) {
			checkLowExpr(ctx, info, it.local.type, it.value);
			checkLowExpr(ctx, info, type, it.then);
		},
		(in LowExprKind.LocalGet it) {
			checkTypeEqual(ctx.ctx, type, it.local.type);
		},
		(in LowExprKind.LocalSet it) {
			checkTypeEqual(ctx.ctx, type, voidType);
			checkLowExpr(ctx, info, it.local.type, it.value);
		},
		(in LowExprKind.Loop x) {
			checkLowExpr(ctx, addLoop(info, ptrTrustMe(x), type), voidType, x.body_);
		},
		(in LowExprKind.LoopBreak x) {
			checkLowExpr(ctx, info, getLoop(info, x.loop), x.value);
		},
		(in LowExprKind.LoopContinue x) {
			cast(void) getLoop(info, x.loop);
		},
		(in LowExprKind.MatchUnion it) {
			checkLowExpr(ctx, info, it.matchedValue.type, it.matchedValue);
			zip!(LowType, LowExprKind.MatchUnion.Case)(
				ctx.ctx.program.allUnions[it.matchedValue.type.as!(LowType.Union)].members,
				it.cases,
				(ref LowType memberType, ref LowExprKind.MatchUnion.Case case_) {
					if (has(case_.local))
						checkTypeEqual(ctx.ctx, memberType, force(case_.local).type);
					checkLowExpr(ctx, info, type, case_.then);
				});
		},
		(in LowExprKind.PtrCast it) {
			// TODO: there are some limitations on target...
			checkLowExpr(ctx, info, it.target.type, it.target);
		},
		(in LowExprKind.PtrToField it) {
			checkLowExpr(ctx, info, it.target.type, it.target);
			LowType fieldType = ctx.ctx.program.allRecords[targetRecordType(it)].fields[it.fieldIndex].type;
			checkTypeEqual(ctx.ctx, asGcOrRawPointee(type), fieldType);
		},
		(in LowExprKind.PtrToLocal it) {
			checkTypeEqual(ctx.ctx, asGcOrRawPointee(type), it.local.type);
		},
		(in LowExprKind.RecordFieldGet it) {
			LowType.Record recordType = targetRecordType(it);
			checkLowExpr(ctx, info, it.target.type, it.target);
			LowType fieldType = ctx.ctx.program.allRecords[recordType].fields[it.fieldIndex].type;
			checkTypeEqual(ctx.ctx, type, fieldType);
		},
		(in LowExprKind.RecordFieldSet it) {
			LowType.Record recordType = targetRecordType(it);
			assert(targetIsPointer(it)); // TODO: then this function doesn't need to exist
			checkLowExpr(ctx, info, it.target.type, it.target);
			LowType fieldType = ctx.ctx.program.allRecords[recordType].fields[it.fieldIndex].type;
			checkLowExpr(ctx, info, fieldType, it.value);
			checkTypeEqual(ctx.ctx, type, voidType);
		},
		(in LowExprKind.SizeOf it) {
			checkTypeEqual(ctx.ctx, type, nat64Type);
		},
		(in Constant it) {
			// Constants are untyped, so can't check more
		},
		(in LowExprKind.SpecialUnary it) {
			checkSpecialUnary(ctx, info, type, it);
		},
		(in LowExprKind.SpecialBinary it) {
			checkSpecialBinary(ctx, info, type, it);
		},
		(in LowExprKind.SpecialTernary) {
			// TODO
		},
		(in LowExprKind.Switch0ToN it) {
			checkLowExpr(ctx, info, it.value.type, it.value);
			foreach (ref LowExpr case_; it.cases)
				checkLowExpr(ctx, info, type, case_);
		},
		(in LowExprKind.SwitchWithValues it) {
			checkLowExpr(ctx, info, it.value.type, it.value);
			foreach (ref LowExpr case_; it.cases)
				checkLowExpr(ctx, info, type, case_);
		},
		(in LowExprKind.TailRecur it) {
			foreach (ref UpdateParam update; it.updateParams)
				checkLowExpr(ctx, info, update.param.type, update.newValue);
		},
		(in LowExprKind.VarGet x) {
			checkTypeEqual(ctx.ctx, type, ctx.ctx.program.vars[x.varIndex].type);
		},
		(in LowExprKind.VarSet x) {
			checkTypeEqual(ctx.ctx, type, voidType);
			checkLowExpr(ctx, info, ctx.ctx.program.vars[x.varIndex].type, *x.value);
		});
}

void checkSpecialUnary(ref FunCtx ctx, in InfoStack info, in LowType type, in LowExprKind.SpecialUnary a) {
	ExpectUnary expected = unaryExpected(a.kind, type, a.arg.type);
	if (has(expected.return_))
		checkTypeEqual(ctx.ctx, force(expected.return_), type);
	checkLowExpr(ctx, info, has(expected.arg) ? force(expected.arg) : a.arg.type, a.arg);
}

ExpectUnary unaryExpected(
	LowExprKind.SpecialUnary.Kind kind,
	return scope LowType returnType,
	return scope LowType argType,
) {
	final switch (kind) {
		case LowExprKind.SpecialUnary.Kind.asAnyPtr:
			//TODO: returns one of anyPtrConstType or anyPtrMutType. Maybe split these up
			return ExpectUnary();
		case LowExprKind.SpecialUnary.Kind.enumToIntegral:
			return ExpectUnary();
		case LowExprKind.SpecialUnary.Kind.bitwiseNotNat8:
			return expect(nat8Type, nat8Type);
		case LowExprKind.SpecialUnary.Kind.bitwiseNotNat16:
			return expect(nat16Type, nat16Type);
		case LowExprKind.SpecialUnary.Kind.bitwiseNotNat32:
			return expect(nat32Type, nat32Type);
		case LowExprKind.SpecialUnary.Kind.bitwiseNotNat64:
		case LowExprKind.SpecialUnary.Kind.countOnesNat64:
			return expect(nat64Type, nat64Type);
		case LowExprKind.SpecialUnary.Kind.deref:
			return ExpectUnary(some(asGcOrRawPointee(argType)), none!LowType);
		case LowExprKind.SpecialUnary.Kind.drop:
			return ExpectUnary(some(voidType), none!LowType);
		case LowExprKind.SpecialUnary.Kind.acosFloat64:
		case LowExprKind.SpecialUnary.Kind.acoshFloat64:
		case LowExprKind.SpecialUnary.Kind.asinFloat64:
		case LowExprKind.SpecialUnary.Kind.asinhFloat64:
		case LowExprKind.SpecialUnary.Kind.atanFloat64:
		case LowExprKind.SpecialUnary.Kind.atanhFloat64:
		case LowExprKind.SpecialUnary.Kind.cosFloat64:
		case LowExprKind.SpecialUnary.Kind.coshFloat64:
		case LowExprKind.SpecialUnary.Kind.sinFloat64:
		case LowExprKind.SpecialUnary.Kind.sinhFloat64:
		case LowExprKind.SpecialUnary.Kind.tanFloat64:
		case LowExprKind.SpecialUnary.Kind.tanhFloat64:
		case LowExprKind.SpecialUnary.Kind.roundFloat64:
		case LowExprKind.SpecialUnary.Kind.sqrtFloat64:
			return expect(float64Type, float64Type);
		case LowExprKind.SpecialUnary.Kind.toChar8FromNat8:
			return expect(char8Type, nat8Type);
		case LowExprKind.SpecialUnary.Kind.toFloat32FromFloat64:
			return expect(float32Type, float64Type);
		case LowExprKind.SpecialUnary.Kind.toFloat64FromFloat32:
			return expect(float64Type, float32Type);
		case LowExprKind.SpecialUnary.Kind.toFloat64FromInt64:
			return expect(float64Type, int64Type);
		case LowExprKind.SpecialUnary.Kind.toFloat64FromNat64:
			return expect(float64Type, nat64Type);
		case LowExprKind.SpecialUnary.Kind.toInt64FromInt8:
			return expect(int64Type, int8Type);
		case LowExprKind.SpecialUnary.Kind.toInt64FromInt16:
			return expect(int64Type, int16Type);
		case LowExprKind.SpecialUnary.Kind.toInt64FromInt32:
			return expect(int64Type, int32Type);
		case LowExprKind.SpecialUnary.Kind.toNat8FromChar8:
			return expect(nat8Type, char8Type);
		case LowExprKind.SpecialUnary.Kind.toNat64FromNat8:
			return expect(nat64Type, nat8Type);
		case LowExprKind.SpecialUnary.Kind.toNat64FromNat16:
			return expect(nat64Type, nat16Type);
		case LowExprKind.SpecialUnary.Kind.toNat64FromNat32:
			return expect(nat64Type, nat32Type);
		case LowExprKind.SpecialUnary.Kind.toNat64FromPtr:
			assert(isPtrGcOrRaw(argType));
			return ExpectUnary(some(nat64Type), none!LowType);
		case LowExprKind.SpecialUnary.Kind.toPtrFromNat64:
			assert(isPtrGcOrRaw(returnType));
			return ExpectUnary(none!LowType, some(nat64Type));
		case LowExprKind.SpecialUnary.Kind.truncateToInt64FromFloat64:
			return expect(int64Type, float64Type);
		case LowExprKind.SpecialUnary.Kind.unsafeToInt8FromInt64:
			return expect(int8Type, int64Type);
		case LowExprKind.SpecialUnary.Kind.unsafeToInt16FromInt64:
			return expect(int16Type, int64Type);
		case LowExprKind.SpecialUnary.Kind.unsafeToInt32FromInt64:
			return expect(int32Type, int64Type);
		case LowExprKind.SpecialUnary.Kind.unsafeToInt64FromNat64:
			return expect(int64Type, nat64Type);
		case LowExprKind.SpecialUnary.Kind.unsafeToNat8FromNat64:
			return expect(nat8Type, nat64Type);
		case LowExprKind.SpecialUnary.Kind.unsafeToNat16FromNat64:
			return expect(nat16Type, nat64Type);
		case LowExprKind.SpecialUnary.Kind.unsafeToNat32FromInt32:
			return expect(nat32Type, int32Type);
		case LowExprKind.SpecialUnary.Kind.unsafeToNat32FromNat64:
			return expect(nat32Type, nat64Type);
		case LowExprKind.SpecialUnary.Kind.unsafeToNat64FromInt64:
			return expect(nat64Type, int64Type);
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

void checkSpecialBinary(ref FunCtx ctx, in InfoStack info, in LowType type, in LowExprKind.SpecialBinary a) {
	ExpectBinary expected = binaryExpected(a.kind, type, a.args[0].type, a.args[1].type);
	if (has(expected.return_))
		checkTypeEqual(ctx.ctx, force(expected.return_), type);
	foreach (size_t i; 0 .. a.args.length)
		checkLowExpr(ctx, info, has(expected.args[i]) ? force(expected.args[i]) : a.args[i].type, a.args[i]);
}

ExpectBinary binaryExpected(
	in LowExprKind.SpecialBinary.Kind kind,
	in LowType returnType,
	return scope LowType arg0Type,
	in LowType arg1Type,
) {
	final switch (kind) {
		case LowExprKind.SpecialBinary.Kind.addFloat32:
		case LowExprKind.SpecialBinary.Kind.mulFloat32:
		case LowExprKind.SpecialBinary.Kind.subFloat32:
		case LowExprKind.SpecialBinary.Kind.unsafeDivFloat32:
			return expect(float32Type, float32Type, float32Type);
		case LowExprKind.SpecialBinary.Kind.addFloat64:
		case LowExprKind.SpecialBinary.Kind.atan2Float64:
		case LowExprKind.SpecialBinary.Kind.mulFloat64:
		case LowExprKind.SpecialBinary.Kind.subFloat64:
		case LowExprKind.SpecialBinary.Kind.unsafeDivFloat64:
			return expect(float64Type, float64Type, float64Type);
		case LowExprKind.SpecialBinary.Kind.addPtrAndNat64:
		case LowExprKind.SpecialBinary.Kind.subPtrAndNat64:
			assert(returnType == arg0Type);
			assert(isPtrGcOrRaw(returnType));
			return ExpectBinary(none!LowType, [none!LowType, some(nat64Type)]);
		case LowExprKind.SpecialBinary.Kind.and:
		case LowExprKind.SpecialBinary.Kind.orBool:
			return expect(boolType, boolType, boolType);
		case LowExprKind.SpecialBinary.Kind.bitwiseAndInt8:
		case LowExprKind.SpecialBinary.Kind.bitwiseOrInt8:
		case LowExprKind.SpecialBinary.Kind.bitwiseXorInt8:
		case LowExprKind.SpecialBinary.Kind.unsafeAddInt8:
		case LowExprKind.SpecialBinary.Kind.unsafeDivInt8:
		case LowExprKind.SpecialBinary.Kind.unsafeMulInt8:
		case LowExprKind.SpecialBinary.Kind.unsafeSubInt8:
			return expect(int8Type, int8Type, int8Type);
		case LowExprKind.SpecialBinary.Kind.bitwiseAndInt16:
		case LowExprKind.SpecialBinary.Kind.bitwiseOrInt16:
		case LowExprKind.SpecialBinary.Kind.bitwiseXorInt16:
		case LowExprKind.SpecialBinary.Kind.unsafeAddInt16:
		case LowExprKind.SpecialBinary.Kind.unsafeDivInt16:
		case LowExprKind.SpecialBinary.Kind.unsafeMulInt16:
		case LowExprKind.SpecialBinary.Kind.unsafeSubInt16:
			return expect(int16Type, int16Type, int16Type);
		case LowExprKind.SpecialBinary.Kind.bitwiseAndInt32:
		case LowExprKind.SpecialBinary.Kind.bitwiseOrInt32:
		case LowExprKind.SpecialBinary.Kind.bitwiseXorInt32:
		case LowExprKind.SpecialBinary.Kind.unsafeAddInt32:
		case LowExprKind.SpecialBinary.Kind.unsafeDivInt32:
		case LowExprKind.SpecialBinary.Kind.unsafeMulInt32:
		case LowExprKind.SpecialBinary.Kind.unsafeSubInt32:
			return expect(int32Type, int32Type, int32Type);
		case LowExprKind.SpecialBinary.Kind.bitwiseAndInt64:
		case LowExprKind.SpecialBinary.Kind.bitwiseOrInt64:
		case LowExprKind.SpecialBinary.Kind.bitwiseXorInt64:
		case LowExprKind.SpecialBinary.Kind.unsafeAddInt64:
		case LowExprKind.SpecialBinary.Kind.unsafeDivInt64:
		case LowExprKind.SpecialBinary.Kind.unsafeMulInt64:
		case LowExprKind.SpecialBinary.Kind.unsafeSubInt64:
			return expect(int64Type, int64Type, int64Type);
		case LowExprKind.SpecialBinary.Kind.bitwiseAndNat8:
		case LowExprKind.SpecialBinary.Kind.bitwiseOrNat8:
		case LowExprKind.SpecialBinary.Kind.bitwiseXorNat8:
		case LowExprKind.SpecialBinary.Kind.unsafeDivNat8:
		case LowExprKind.SpecialBinary.Kind.wrapAddNat8:
		case LowExprKind.SpecialBinary.Kind.wrapMulNat8:
		case LowExprKind.SpecialBinary.Kind.wrapSubNat8:
			return expect(nat8Type, nat8Type, nat8Type);
		case LowExprKind.SpecialBinary.Kind.bitwiseAndNat16:
		case LowExprKind.SpecialBinary.Kind.bitwiseOrNat16:
		case LowExprKind.SpecialBinary.Kind.bitwiseXorNat16:
		case LowExprKind.SpecialBinary.Kind.unsafeDivNat16:
		case LowExprKind.SpecialBinary.Kind.wrapAddNat16:
		case LowExprKind.SpecialBinary.Kind.wrapMulNat16:
		case LowExprKind.SpecialBinary.Kind.wrapSubNat16:
			return expect(nat16Type, nat16Type, nat16Type);
		case LowExprKind.SpecialBinary.Kind.bitwiseAndNat32:
		case LowExprKind.SpecialBinary.Kind.bitwiseOrNat32:
		case LowExprKind.SpecialBinary.Kind.bitwiseXorNat32:
		case LowExprKind.SpecialBinary.Kind.unsafeDivNat32:
		case LowExprKind.SpecialBinary.Kind.wrapAddNat32:
		case LowExprKind.SpecialBinary.Kind.wrapMulNat32:
		case LowExprKind.SpecialBinary.Kind.wrapSubNat32:
			return expect(nat32Type, nat32Type, nat32Type);
		case LowExprKind.SpecialBinary.Kind.bitwiseAndNat64:
		case LowExprKind.SpecialBinary.Kind.bitwiseOrNat64:
		case LowExprKind.SpecialBinary.Kind.bitwiseXorNat64:
		case LowExprKind.SpecialBinary.Kind.unsafeBitShiftLeftNat64:
		case LowExprKind.SpecialBinary.Kind.unsafeBitShiftRightNat64:
		case LowExprKind.SpecialBinary.Kind.unsafeDivNat64:
		case LowExprKind.SpecialBinary.Kind.unsafeModNat64:
		case LowExprKind.SpecialBinary.Kind.wrapAddNat64:
		case LowExprKind.SpecialBinary.Kind.wrapMulNat64:
		case LowExprKind.SpecialBinary.Kind.wrapSubNat64:
			return expect(nat64Type, nat64Type, nat64Type);
		case LowExprKind.SpecialBinary.Kind.eqFloat32:
		case LowExprKind.SpecialBinary.Kind.lessFloat32:
			return expect(boolType, float32Type, float32Type);
		case LowExprKind.SpecialBinary.Kind.eqFloat64:
		case LowExprKind.SpecialBinary.Kind.lessFloat64:
			return expect(boolType, float64Type, float64Type);
		case LowExprKind.SpecialBinary.Kind.eqInt8:
		case LowExprKind.SpecialBinary.Kind.lessInt8:
			return expect(boolType, int8Type, int8Type);
		case LowExprKind.SpecialBinary.Kind.eqInt16:
		case LowExprKind.SpecialBinary.Kind.lessInt16:
			return expect(boolType, int16Type, int16Type);
		case LowExprKind.SpecialBinary.Kind.eqInt32:
		case LowExprKind.SpecialBinary.Kind.lessInt32:
			return expect(boolType, int32Type, int32Type);
		case LowExprKind.SpecialBinary.Kind.eqInt64:
		case LowExprKind.SpecialBinary.Kind.lessInt64:
			return expect(boolType, int64Type, int64Type);
		case LowExprKind.SpecialBinary.Kind.eqNat8:
		case LowExprKind.SpecialBinary.Kind.lessNat8:
			return expect(boolType, nat8Type, nat8Type);
		case LowExprKind.SpecialBinary.Kind.eqNat16:
		case LowExprKind.SpecialBinary.Kind.lessNat16:
			return expect(boolType, nat16Type, nat16Type);
		case LowExprKind.SpecialBinary.Kind.eqNat32:
		case LowExprKind.SpecialBinary.Kind.lessNat32:
			return expect(boolType, nat32Type, nat32Type);
		case LowExprKind.SpecialBinary.Kind.eqNat64:
		case LowExprKind.SpecialBinary.Kind.lessNat64:
			return expect(boolType, nat64Type, nat64Type);
		case LowExprKind.SpecialBinary.Kind.eqPtr:
		case LowExprKind.SpecialBinary.Kind.lessPtr:
			assert(arg0Type == arg1Type);
			return ExpectBinary(some(boolType), [none!LowType, none!LowType]);
		case LowExprKind.SpecialBinary.Kind.lessChar8:
			return expect(boolType, char8Type, char8Type);
		case LowExprKind.SpecialBinary.Kind.seq:
			assert(returnType == arg1Type);
			return ExpectBinary(none!LowType, [some(voidType), none!LowType]);
		case LowExprKind.SpecialBinary.Kind.writeToPtr:
			return ExpectBinary(some(voidType), [none!LowType, some(asGcOrRawPointee(arg0Type))]);
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
			writeJson(writer, ctx.allSymbols, jsonOfLowType2(alloc, ctx.program, expected));
			writer ~= "\nActual:\n";
			writeJson(writer, ctx.allSymbols, jsonOfLowType2(alloc, ctx.program, actual));
		});
	assert(expected == actual);
}

Json jsonOfLowType2(ref Alloc alloc, in LowProgram program, in LowType a) =>
	a.matchIn!Json(
		(in LowType.Extern) =>
			jsonString!"some-extern", //TODO: more detail
		(in LowType.FunPtr) =>
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
