module lower.checkLowModel;

@safe @nogc pure nothrow:

import lower.lowExprHelpers : boolType, nat64Type, voidType;
import model.constant : Constant;
import model.lowModel :
	asFunPtrType,
	asRecordType,
	asUnionType,
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
	UpdateParam;
import model.reprConcreteModel : reprOfConcreteStructRef;
import util.alloc.alloc : Alloc;
import util.col.arr : sizeEq;
import util.col.arrUtil : zip;
import util.col.fullIndexDict : fullIndexDictEachValue;
import util.opt : force, has;
import util.ptr : ptrTrustMe, ptrTrustMe_mut;
import util.repr : Repr, reprRecord, reprSym;
import util.util : verify;

void checkLowProgram(ref Alloc alloc, scope ref immutable LowProgram a) {
	Ctx ctx = Ctx(ptrTrustMe_mut(alloc), ptrTrustMe(a));
	fullIndexDictEachValue!(LowFunIndex, LowFun)(a.allFuns, (ref immutable LowFun fun) {
		checkLowFun(ctx, fun);
	});
}

private:

struct Ctx {
	@safe @nogc pure nothrow:

	Alloc* allocPtr;
	immutable LowProgram* programPtr;

	ref Alloc alloc() return scope {
		return *allocPtr;
	}

	ref immutable(LowProgram) program() return scope const {
		return *programPtr;
	}
}

struct FunCtx {
	@safe @nogc pure nothrow:

	Ctx* ctxPtr;
	immutable LowFun* funPtr;

	ref Ctx ctx() return scope {
		return *ctxPtr;
	}

	ref immutable(LowFun) fun() return scope const {
		return *funPtr;
	}
}

void checkLowFun(ref Ctx ctx, ref immutable LowFun fun) {
	//debug {
	//	import core.stdc.stdio : printf;
	//	import interpret.debugging : writeFunName;
	//	import util.writer : Writer, finishWriterToCStr;
	//
	//	Writer writer = Writer(ptrTrustMe_mut(alloc));
	//	writeFunName(writer, ctx.program, fun);
	//	printf("Will check function %s\n", finishWriterToCStr(writer));
	//}

	matchLowFunBody!(
		void,
		(ref immutable LowFunBody.Extern) {},
		(ref immutable LowFunExprBody it) {
			FunCtx funCtx = FunCtx(ptrTrustMe_mut(ctx), ptrTrustMe(fun));
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
			zip!(LowParam, LowExpr)(
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
			zip!(LowType, LowExpr)(
				funPtrType.paramTypes,
				it.args,
				(ref immutable LowType paramType, ref immutable LowExpr arg) {
					checkLowExpr(ctx, paramType, arg);
				});
		},
		(ref immutable LowExprKind.CreateRecord it) {
			immutable LowField[] fields = ctx.ctx.program.allRecords[asRecordType(type)].fields;
			zip!(LowField, LowExpr)(fields, it.args, (ref immutable LowField field, ref immutable LowExpr arg) {
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
		(ref immutable LowExprKind.LocalRef it) {
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
			// TODO
		},
		(ref immutable LowExprKind.MatchUnion it) {
			checkLowExpr(ctx, it.matchedValue.type, it.matchedValue);
			zip!(LowType, LowExprKind.MatchUnion.Case)(
				ctx.ctx.program.allUnions[asUnionType(it.matchedValue.type)].members,
				it.cases,
				(ref immutable LowType memberType, ref immutable LowExprKind.MatchUnion.Case case_) {
					if (has(case_.local))
						checkTypeEqual(ctx.ctx, memberType, force(case_.local).type);
					checkLowExpr(ctx, type, case_.then);
				});
		},
		(ref immutable LowExprKind.ParamRef it) {
			checkTypeEqual(ctx.ctx, type, ctx.fun.params[it.index.index].type);
		},
		(ref immutable LowExprKind.PtrCast it) {
			// TODO: there are some limitations on target...
			checkLowExpr(ctx, it.target.type, it.target);
		},
		(ref immutable LowExprKind.RecordFieldGet it) {
			immutable LowType targetTypeNonPtr = immutable LowType(it.record);
			immutable LowType targetType = it.targetIsPointer
				? immutable LowType(immutable LowType.PtrGc(ptrTrustMe(targetTypeNonPtr)))
				: targetTypeNonPtr;
			checkLowExpr(ctx, targetType, it.target);
			immutable LowType fieldType = ctx.ctx.program.allRecords[it.record].fields[it.fieldIndex].type;
			checkTypeEqual(ctx.ctx, type, fieldType);
		},
		(ref immutable LowExprKind.RecordFieldSet it) {
			immutable LowType targetTypeNonPtr = immutable LowType(it.record);
			immutable LowType targetType = it.targetIsPointer
				? immutable LowType(immutable LowType.PtrGc(ptrTrustMe(targetTypeNonPtr)))
				: targetTypeNonPtr;
			checkLowExpr(ctx, targetType, it.target);
			immutable LowType fieldType = ctx.ctx.program.allRecords[it.record].fields[it.fieldIndex].type;
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
			// TODO
		},
		(ref immutable LowExprKind.SpecialBinary it) {
			// TODO
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
		(ref immutable LowExprKind.Zeroed) {},
	)(expr.kind);
}

void checkTypeEqual(
	ref Ctx ctx,
	immutable LowType expected,
	immutable LowType actual,
) {
	//debug {
	//	if (expected != actual) {
	//		import core.stdc.stdio : printf;
	//		import util.repr : writeRepr;
	//		import util.writer : finishWriterToCStr, Writer, writeStatic;
	//		Writer writer = Writer(ptrTrustMe_mut(alloc));
	//		writeStatic(writer, "Type is not as expected. Expected:\n");
	//		writeRepr(writer, allSymbols, reprOfLowType2(alloc, ctx, expected));
	//		writeStatic(writer, "Actual:\n");
	//		writeRepr(writer, allSymbols, reprOfLowType2(alloc, ctx, actual));
	//		printf("%s\n", finishWriterToCStr(writer));
	//	}
	//}
	verify(expected == actual);
}

immutable(Repr) reprOfLowType2(ref Ctx ctx, immutable LowType a) {
	return matchLowType!(
		immutable Repr,
		(immutable LowType.ExternPtr) =>
			reprSym("a-extern-ptr"), //TODO: more detail
		(immutable LowType.FunPtr) =>
			reprSym("some-fun-ptr"), //TODO: more detail
		(immutable PrimitiveType it) =>
			reprSym(symOfPrimitiveType(it)),
		(immutable LowType.PtrGc it) =>
			reprRecord(ctx.alloc, "gc-ptr", [reprOfLowType2(ctx, *it.pointee)]),
		(immutable LowType.PtrRawConst it) =>
			reprRecord(ctx.alloc, "ptr-const", [reprOfLowType2(ctx, *it.pointee)]),
		(immutable LowType.PtrRawMut it) =>
			reprRecord(ctx.alloc, "ptr-mut", [reprOfLowType2(ctx, *it.pointee)]),
		(immutable LowType.Record it) =>
			reprOfConcreteStructRef(ctx.alloc, *ctx.program.allRecords[it].source),
		(immutable LowType.Union it) =>
			reprOfConcreteStructRef(ctx.alloc, *ctx.program.allUnions[it].source),
	)(a);
}
