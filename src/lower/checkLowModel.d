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
import model.lowModel :
	asFunPtrType,
	asGcOrRawPointee,
	asRecordType,
	asUnionType,
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
	LowParam,
	LowProgram,
	LowType,
	matchLowExprKind,
	matchLowFunBody,
	matchLowType,
	PrimitiveType,
	symOfPrimitiveType,
	targetIsPointer,
	targetRecordType,
	UpdateParam;
import model.reprConcreteModel : reprOfConcreteStructRef;
import util.alloc.alloc : Alloc;
import util.col.arr : sizeEq;
import util.col.arrUtil : zip;
import util.col.fullIndexDict : fullIndexDictEachValue;
import util.opt : force, has, none, Opt, some;
import util.ptr : castNonScope_ref, ptrTrustMe;
import util.repr : Repr, reprRecord, reprSym;
import util.sym : AllSymbols;
import util.util : verify;

void checkLowProgram(ref Alloc alloc, ref const AllSymbols allSymbols, scope ref immutable LowProgram a) {
	Ctx ctx = Ctx(ptrTrustMe(alloc), ptrTrustMe(allSymbols), ptrTrustMe(castNonScope_ref(a)));
	fullIndexDictEachValue!(LowFunIndex, LowFun)(a.allFuns, (ref immutable LowFun fun) {
		checkLowFun(ctx, fun);
	});
}

private:

struct Ctx {
	@safe @nogc pure nothrow:

	Alloc* allocPtr;
	const AllSymbols* allSymbolsPtr;
	immutable LowProgram* programPtr;

	ref Alloc alloc() return scope =>
		*allocPtr;

	ref const(AllSymbols) allSymbols() return scope const =>
		*allSymbolsPtr;

	ref immutable(LowProgram) program() return scope const =>
		*programPtr;
}

struct FunCtx {
	@safe @nogc pure nothrow:

	Ctx* ctxPtr;
	immutable LowFun* funPtr;

	ref Ctx ctx() return scope =>
		*ctxPtr;

	ref immutable(LowFun) fun() return scope const =>
		*funPtr;
}

void checkLowFun(ref Ctx ctx, ref immutable LowFun fun) {
	static if (false) debug {
		import core.stdc.stdio : printf;
		import interpret.debugging : writeFunName;
		import util.writer : Writer, finishWriterToCStr;
	
		Writer writer = Writer(ctx.allocPtr);
		writeFunName(writer, ctx.allSymbols, ctx.program, fun);
		printf("Will check function %s\n", finishWriterToCStr(writer));
	}

	matchLowFunBody!(
		void,
		(ref immutable LowFunBody.Extern) {},
		(ref immutable LowFunExprBody it) {
			FunCtx funCtx = FunCtx(ptrTrustMe(ctx), ptrTrustMe(fun));
			checkLowExpr(funCtx, fun.returnType, it.expr);
		},
	)(fun.body_);
}

void checkLowExpr(
	ref FunCtx ctx,
	immutable LowType type,
	ref immutable LowExpr expr,
) {
	checkTypeEqual(ctx.ctx, type, expr.type);
	matchLowExprKind!(
		void,
		(ref immutable LowExprKind.Call it) {
			immutable LowFun* fun = &ctx.ctx.program.allFuns[it.called];
			checkTypeEqual(ctx.ctx, type, fun.returnType);
			verify(sizeEq(fun.params, it.args));
			zip!(immutable LowParam, immutable LowExpr)(
				fun.params,
				it.args,
				(ref immutable LowParam param, ref immutable LowExpr arg) {
					checkLowExpr(ctx, param.type, arg);
				});
		},
		(ref immutable LowExprKind.CallFunPtr it) {
			immutable LowFunPtrType funPtrType = ctx.ctx.program.allFunPtrTypes[asFunPtrType(it.funPtr.type)];
			checkTypeEqual(ctx.ctx, type, funPtrType.returnType);
			verify(sizeEq(funPtrType.paramTypes, it.args));
			zip!(immutable LowType, immutable LowExpr)(
				funPtrType.paramTypes,
				it.args,
				(ref immutable LowType paramType, ref immutable LowExpr arg) {
					checkLowExpr(ctx, paramType, arg);
				});
		},
		(ref immutable LowExprKind.CreateRecord it) {
			immutable LowField[] fields = ctx.ctx.program.allRecords[asRecordType(type)].fields;
			zip!(immutable LowField, immutable LowExpr)(
				fields,
				it.args,
				(ref immutable LowField field, ref immutable LowExpr arg) {
					checkLowExpr(ctx, field.type, arg);
				});
		},
		(ref immutable LowExprKind.CreateUnion it) {
			immutable LowType member = ctx.ctx.program.allUnions[asUnionType(type)].members[it.memberIndex];
			checkLowExpr(ctx, member, it.arg);
		},
		(ref immutable LowExprKind.If it) {
			checkLowExpr(ctx, boolType, it.cond);
			checkLowExpr(ctx, type, it.then);
			checkLowExpr(ctx, type, it.else_);
		},
		(ref immutable LowExprKind.InitConstants) {
			verify(isVoid(type));
		},
		(ref immutable LowExprKind.Let it) {
			checkLowExpr(ctx, it.local.type, it.value);
			checkLowExpr(ctx, type, it.then);
		},
		(ref immutable LowExprKind.LocalGet it) {
			checkTypeEqual(ctx.ctx, type, it.local.type);
		},
		(ref immutable LowExprKind.LocalSet it) {
			checkTypeEqual(ctx.ctx, type, voidType);
			checkLowExpr(ctx, it.local.type, it.value);
		},
		(ref immutable LowExprKind.Loop it) {
			checkLowExpr(ctx, voidType, it.body_);
		},
		(ref immutable LowExprKind.LoopBreak it) {
			checkLowExpr(ctx, it.loop.type, it.value);
		},
		(ref immutable LowExprKind.LoopContinue) {
			// TODO
		},
		(ref immutable LowExprKind.MatchUnion it) {
			checkLowExpr(ctx, it.matchedValue.type, it.matchedValue);
			zip!(immutable LowType, immutable LowExprKind.MatchUnion.Case)(
				ctx.ctx.program.allUnions[asUnionType(it.matchedValue.type)].members,
				it.cases,
				(ref immutable LowType memberType, ref immutable LowExprKind.MatchUnion.Case case_) {
					if (has(case_.local))
						checkTypeEqual(ctx.ctx, memberType, force(case_.local).type);
					checkLowExpr(ctx, type, case_.then);
				});
		},
		(ref immutable LowExprKind.ParamGet it) {
			checkTypeEqual(ctx.ctx, type, ctx.fun.params[it.index.index].type);
		},
		(ref immutable LowExprKind.PtrCast it) {
			// TODO: there are some limitations on target...
			checkLowExpr(ctx, it.target.type, it.target);
		},
		(ref immutable LowExprKind.PtrToField it) {
			checkLowExpr(ctx, it.target.type, it.target);
			immutable LowType fieldType = ctx.ctx.program.allRecords[targetRecordType(it)].fields[it.fieldIndex].type;
			checkTypeEqual(ctx.ctx, asGcOrRawPointee(type), fieldType);
		},
		(ref immutable LowExprKind.PtrToLocal it) {
			checkTypeEqual(ctx.ctx, asGcOrRawPointee(type), it.local.type);
		},
		(ref immutable LowExprKind.PtrToParam it) {
			checkTypeEqual(ctx.ctx, type, immutable LowType(
				immutable LowType.PtrRawConst(&ctx.fun.params[it.index.index].type)));
		},
		(ref immutable LowExprKind.RecordFieldGet it) {
			immutable LowType.Record recordType = targetRecordType(it);
			checkLowExpr(ctx, it.target.type, it.target);
			immutable LowType fieldType = ctx.ctx.program.allRecords[recordType].fields[it.fieldIndex].type;
			checkTypeEqual(ctx.ctx, type, fieldType);
		},
		(ref immutable LowExprKind.RecordFieldSet it) {
			immutable LowType.Record recordType = targetRecordType(it);
			verify(targetIsPointer(it)); // TODO: then this function doesn't need to exist
			checkLowExpr(ctx, it.target.type, it.target);
			immutable LowType fieldType = ctx.ctx.program.allRecords[recordType].fields[it.fieldIndex].type;
			checkLowExpr(ctx, fieldType, it.value);
			checkTypeEqual(ctx.ctx, type, voidType);
		},
		(ref immutable LowExprKind.Seq it) {
			checkLowExpr(ctx, voidType, it.first);
			checkLowExpr(ctx, type, it.then);
		},
		(ref immutable LowExprKind.SizeOf it) {
			checkTypeEqual(ctx.ctx, type, nat64Type);
		},
		(ref immutable Constant it) {
			// Constants are untyped, so can't check more
		},
		(ref immutable LowExprKind.SpecialUnary it) {
			checkSpecialUnary(ctx, type, it);
		},
		(ref immutable LowExprKind.SpecialBinary it) {
			checkSpecialBinary(ctx, type, it);
		},
		(ref immutable LowExprKind.SpecialTernary) {
			// TODO
		},
		(ref immutable LowExprKind.Switch0ToN it) {
			checkLowExpr(ctx, it.value.type, it.value);
			foreach (ref immutable LowExpr case_; it.cases)
				checkLowExpr(ctx, type, case_);
		},
		(ref immutable LowExprKind.SwitchWithValues it) {
			checkLowExpr(ctx, it.value.type, it.value);
			foreach (ref immutable LowExpr case_; it.cases)
				checkLowExpr(ctx, type, case_);
		},
		(ref immutable LowExprKind.TailRecur it) {
			checkTypeEqual(ctx.ctx, type, ctx.fun.returnType);
			foreach (ref immutable UpdateParam update; it.updateParams)
				checkLowExpr(ctx, ctx.fun.params[update.param.index].type, update.newValue);
		},
		(ref immutable LowExprKind.ThreadLocalPtr it) {
			immutable LowType pointee = ctx.ctx.program.threadLocals[it.threadLocalIndex].type;
			checkTypeEqual(ctx.ctx, type, immutable LowType(immutable LowType.PtrRawMut(&pointee)));
		},
		(ref immutable LowExprKind.Zeroed) {},
	)(expr.kind);
}

void checkSpecialUnary(ref FunCtx ctx, immutable LowType type, immutable LowExprKind.SpecialUnary a) {
	immutable ExpectUnary expected = unaryExpected(a.kind, type, a.arg.type);
	if (has(expected.return_))
		checkTypeEqual(ctx.ctx, force(expected.return_), type);
	checkLowExpr(ctx, has(expected.arg) ? force(expected.arg) : a.arg.type, a.arg);
}

immutable(ExpectUnary) unaryExpected(
	immutable LowExprKind.SpecialUnary.Kind kind,
	immutable LowType returnType,
	immutable LowType argType,
) {
	final switch (kind) {
		case LowExprKind.SpecialUnary.Kind.asAnyPtr:
			//TODO: returns one of anyPtrConstType or anyPtrMutType. Maybe split these up
			return immutable ExpectUnary();
		case LowExprKind.SpecialUnary.Kind.asRef:
		case LowExprKind.SpecialUnary.Kind.enumToIntegral:
			return immutable ExpectUnary();
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
			return immutable ExpectUnary(some(asGcOrRawPointee(argType)), none!LowType);
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
			verify(isPtrGcOrRaw(argType));
			return immutable ExpectUnary(some(nat64Type), none!LowType);
		case LowExprKind.SpecialUnary.Kind.toPtrFromNat64:
			verify(isPtrGcOrRaw(returnType));
			return immutable ExpectUnary(none!LowType, some(nat64Type));
		case LowExprKind.SpecialUnary.Kind.truncateToInt64FromFloat64:
			return expect(int64Type, float64Type);
		case LowExprKind.SpecialUnary.Kind.unsafeInt32ToNat32:
			return expect(nat32Type, int32Type);
		case LowExprKind.SpecialUnary.Kind.unsafeInt64ToInt8:
			return expect(int8Type, int64Type);
		case LowExprKind.SpecialUnary.Kind.unsafeInt64ToInt16:
			return expect(int16Type, int64Type);
		case LowExprKind.SpecialUnary.Kind.unsafeInt64ToInt32:
			return expect(int32Type, int64Type);
		case LowExprKind.SpecialUnary.Kind.unsafeInt64ToNat64:
			return expect(nat64Type, int64Type);
		case LowExprKind.SpecialUnary.Kind.unsafeNat64ToInt64:
			return expect(int64Type, nat64Type);
		case LowExprKind.SpecialUnary.Kind.unsafeNat64ToNat8:
			return expect(nat8Type, nat64Type);
		case LowExprKind.SpecialUnary.Kind.unsafeNat64ToNat16:
			return expect(nat16Type, nat64Type);
		case LowExprKind.SpecialUnary.Kind.unsafeNat64ToNat32:
			return expect(nat32Type, nat64Type);
	}
}

struct ExpectUnary {
	immutable Opt!LowType return_;
	immutable Opt!LowType arg;
}
immutable(ExpectUnary) expect() =>
	immutable ExpectUnary(none!LowType, none!LowType);
immutable(ExpectUnary) expect(immutable LowType return_, immutable LowType arg) =>
	immutable ExpectUnary(some(return_), some(arg));

void checkSpecialBinary(ref FunCtx ctx, immutable LowType type, immutable LowExprKind.SpecialBinary a) {
	immutable ExpectBinary expected = binaryExpected(a.kind, type, a.left.type, a.right.type);
	if (has(expected.return_))
		checkTypeEqual(ctx.ctx, force(expected.return_), type);
	checkLowExpr(ctx, has(expected.arg0) ? force(expected.arg0) : a.left.type, a.left);
	checkLowExpr(ctx, has(expected.arg1) ? force(expected.arg1) : a.right.type, a.right);
}

immutable(ExpectBinary) binaryExpected(
	immutable LowExprKind.SpecialBinary.Kind kind,
	immutable LowType returnType,
	immutable LowType arg0Type,
	immutable LowType arg1Type,
) {
	final switch (kind) {
		case LowExprKind.SpecialBinary.Kind.addFloat32:
		case LowExprKind.SpecialBinary.Kind.mulFloat32:
		case LowExprKind.SpecialBinary.Kind.subFloat32:
		case LowExprKind.SpecialBinary.Kind.unsafeDivFloat32:
			return expect(float32Type, float32Type, float32Type);
		case LowExprKind.SpecialBinary.Kind.addFloat64:
		case LowExprKind.SpecialBinary.Kind.mulFloat64:
		case LowExprKind.SpecialBinary.Kind.subFloat64:
		case LowExprKind.SpecialBinary.Kind.unsafeDivFloat64:
			return expect(float64Type, float64Type, float64Type);
		case LowExprKind.SpecialBinary.Kind.addPtrAndNat64:
		case LowExprKind.SpecialBinary.Kind.subPtrAndNat64:
			verify(returnType == arg0Type);
			verify(isPtrGcOrRaw(returnType));
			return immutable ExpectBinary(none!LowType, none!LowType, some(nat64Type));
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
			verify(arg0Type == arg1Type);
			return immutable ExpectBinary(some(boolType), none!LowType, none!LowType);
		case LowExprKind.SpecialBinary.Kind.lessChar8:
			return expect(boolType, char8Type, char8Type);
		case LowExprKind.SpecialBinary.Kind.writeToPtr:
			return immutable ExpectBinary(some(voidType), none!LowType, some(asGcOrRawPointee(arg0Type)));
	}
}

struct ExpectBinary {
	immutable Opt!LowType return_;
	immutable Opt!LowType arg0;
	immutable Opt!LowType arg1;
}
immutable(ExpectBinary) expect(immutable LowType return_, immutable LowType arg0, immutable LowType arg1) =>
	immutable ExpectBinary(some(return_), some(arg0), some(arg1));

void checkTypeEqual(
	ref Ctx ctx,
	immutable LowType expected,
	immutable LowType actual,
) {
	static if (false) debug {
		if (expected != actual) {
			import core.stdc.stdio : printf;
			import util.repr : writeReprJSON;
			import util.writer : finishWriterToCStr, Writer;
			Writer writer = Writer(ctx.allocPtr);
			writer ~= "Type is not as expected. Expected:\n";
			writeReprJSON(writer, ctx.allSymbols, reprOfLowType2(ctx, expected));
			writer ~= "\nActual:\n";
			writeReprJSON(writer, ctx.allSymbols, reprOfLowType2(ctx, actual));
			printf("%s\n", finishWriterToCStr(writer));
		}
	}
	verify(expected == actual);
}

immutable(Repr) reprOfLowType2(ref Ctx ctx, immutable LowType a) =>
	matchLowType!(
		immutable Repr,
		(immutable LowType.Extern) =>
			reprSym!"some-extern", //TODO: more detail
		(immutable LowType.FunPtr) =>
			reprSym!"some-fun-ptr", //TODO: more detail
		(immutable PrimitiveType it) =>
			reprSym(symOfPrimitiveType(it)),
		(immutable LowType.PtrGc it) =>
			reprRecord!"gc-ptr"(ctx.alloc, [reprOfLowType2(ctx, *it.pointee)]),
		(immutable LowType.PtrRawConst it) =>
			reprRecord!"ptr-const"(ctx.alloc, [reprOfLowType2(ctx, *it.pointee)]),
		(immutable LowType.PtrRawMut it) =>
			reprRecord!"ptr-mut"(ctx.alloc, [reprOfLowType2(ctx, *it.pointee)]),
		(immutable LowType.Record it) =>
			reprOfConcreteStructRef(ctx.alloc, *ctx.program.allRecords[it].source),
		(immutable LowType.Union it) =>
			reprOfConcreteStructRef(ctx.alloc, *ctx.program.allUnions[it].source),
	)(a);
