module lower.checkLowModel;

@safe @nogc pure nothrow:

import lower.lowExprHelpers : boolType, int32Type, nat64Type, voidType;
import lowModel :
	asFunPtrType,
	asRecordType,
	asUnionType,
	LowExpr,
	LowExprKind,
	LowField,
	LowFun,
	LowFunBody,
	LowFunExprBody,
	LowFunPtrType,
	LowParam,
	LowProgram,
	LowRecord,
	LowType,
	lowTypeEqual,
	LowUnion,
	matchLowExprKind,
	matchLowFunBody,
	matchLowType,
	matchSpecialConstant,
	PrimitiveType,
	symOfPrimitiveType;
import util.collection.arr : Arr, at, range, sizeEq;
import util.collection.arrUtil : tail, zip;
import util.collection.fullIndexDict : fullIndexDictEachValue, fullIndexDictGet;
import util.opt : force, has;
import util.ptr : Ptr, ptrTrustMe;
import util.sexpr : Sexpr, tataRecord, tataStr, tataSym;
import util.util : todo, verify;

void checkLowProgram(ref immutable LowProgram a) {
	immutable Ctx ctx = immutable Ctx(ptrTrustMe(a));
	fullIndexDictEachValue(a.allFuns, (ref immutable LowFun fun) {
		checkLowFun(ctx, fun);
	});
}

private:

struct Ctx {
	immutable Ptr!LowProgram program;
}

struct FunCtx {
	immutable Ctx ctx;
	immutable Ptr!LowFun fun;
}

void checkLowFun(ref immutable Ctx ctx, ref immutable LowFun fun) {
	matchLowFunBody!void(
		fun.body_,
		(ref immutable LowFunBody.Extern) {},
		(ref immutable LowFunExprBody it) {
			immutable FunCtx funCtx = immutable FunCtx(ctx, ptrTrustMe(fun));
			checkLowExpr(funCtx, fun.returnType, it.expr);
		});
}

void checkLowExpr(ref immutable FunCtx ctx, ref immutable LowType type, ref immutable LowExpr expr) {
	checkTypeEqual(ctx.ctx, type, expr.type);
	matchLowExprKind(
		expr.kind,
		(ref immutable LowExprKind.Call it) {
			immutable LowFun fun = fullIndexDictGet(ctx.ctx.program.allFuns, it.called);
			checkTypeEqual(ctx.ctx, type, fun.returnType);
			verify(sizeEq(fun.params, it.args));
			zip(fun.params, it.args, (ref immutable LowParam param, ref immutable LowExpr arg) {
				checkLowExpr(ctx, param.type, arg);
			});
		},
		(ref immutable LowExprKind.CreateRecord it) {
			immutable LowRecord record = fullIndexDictGet(ctx.ctx.program.allRecords, asRecordType(type));
			verify(sizeEq(record.fields, it.args));
			zip(record.fields, it.args, (ref immutable LowField field, ref immutable LowExpr arg) {
				checkLowExpr(ctx, field.type, arg);
			});
		},
		(ref immutable LowExprKind.ConvertToUnion it) {
			immutable LowUnion union_ = fullIndexDictGet(ctx.ctx.program.allUnions, asUnionType(type));
			immutable LowType member = at(union_.members, it.memberIndex);
			checkLowExpr(ctx, member, it.arg);
		},
		(ref immutable LowExprKind.FunPtr it) {
			immutable LowFun fun = fullIndexDictGet(ctx.ctx.program.allFuns, it.fun);
			immutable LowFunPtrType funType = fullIndexDictGet(ctx.ctx.program.allFunPtrTypes, asFunPtrType(type));
			verify(sizeEq(fun.params, funType.paramTypes));
			size_t index = 0;
			zip(fun.params, funType.paramTypes, (ref immutable LowParam param, ref immutable LowType paramType) {
				// TODO: this is failing for lambda closure,
				// which is any-ptr in the function type and has a better type in the function
				if (index != 1) {
					checkTypeEqual(ctx.ctx, param.type, paramType);
				}
				index++;
			});
		},
		(ref immutable LowExprKind.Let it) {
			checkLowExpr(ctx, it.local.type, it.value);
			checkLowExpr(ctx, type, it.then);
		},
		(ref immutable LowExprKind.LocalRef it) {
			checkTypeEqual(ctx.ctx, type, it.local.type);
		},
		(ref immutable LowExprKind.Match it) {
			checkLowExpr(ctx, it.matchedLocal.type, it.matchedValue);
			immutable LowUnion union_ = fullIndexDictGet(ctx.ctx.program.allUnions, asUnionType(it.matchedLocal.type));
			verify(sizeEq(union_.members, it.cases));
			zip(
				union_.members,
				it.cases,
				(ref immutable LowType memberType, ref immutable LowExprKind.Match.Case case_) {
					if (has(case_.local))
						checkTypeEqual(ctx.ctx, memberType, force(case_.local).type);
					checkLowExpr(ctx, type, case_.then);
				});
		},
		(ref immutable LowExprKind.ParamRef it) {
			checkTypeEqual(ctx.ctx, type, at(ctx.fun.params, it.index.index).type);
		},
		(ref immutable LowExprKind.PtrCast it) {
			// TODO: there are some limitations on target...
			checkLowExpr(ctx, it.target.type, it.target);
		},
		(ref immutable LowExprKind.RecordFieldAccess it) {
			immutable LowType targetTypeNonPtr = immutable LowType(it.record);
			immutable LowType targetType = it.targetIsPointer
				? immutable LowType(immutable LowType.NonFunPtr(ptrTrustMe(targetTypeNonPtr)))
				: targetTypeNonPtr;
			checkLowExpr(ctx, targetType, it.target);
			immutable LowType fieldType =
				at(fullIndexDictGet(ctx.ctx.program.allRecords, it.record).fields, it.fieldIndex).type;
			checkTypeEqual(ctx.ctx, type, fieldType);
		},
		(ref immutable LowExprKind.RecordFieldSet it) {
			immutable LowType targetTypeNonPtr = immutable LowType(it.record);
			immutable LowType targetType = it.targetIsPointer
				? immutable LowType(immutable LowType.NonFunPtr(ptrTrustMe(targetTypeNonPtr)))
				: targetTypeNonPtr;
			checkLowExpr(ctx, targetType, it.target);
			immutable LowType fieldType =
				at(fullIndexDictGet(ctx.ctx.program.allRecords, it.record).fields, it.fieldIndex).type;
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
		(ref immutable LowExprKind.SpecialConstant it) {
			matchSpecialConstant!void(
				it,
				(immutable LowExprKind.SpecialConstant.BoolConstant) {
					checkTypeEqual(ctx.ctx, type, boolType);
				},
				(immutable LowExprKind.SpecialConstant.Integral) {
					// TODO
				},
				(immutable LowExprKind.SpecialConstant.Null) {
					// TODO
				},
				(immutable LowExprKind.SpecialConstant.StrConstant) {
					// TODO
				},
				(immutable LowExprKind.SpecialConstant.Void) {
					checkTypeEqual(ctx.ctx, type, voidType);
				});
		},
		(ref immutable LowExprKind.Special0Ary it) {
			final switch (it.kind) {
				case LowExprKind.Special0Ary.Kind.getErrno:
					checkTypeEqual(ctx.ctx, type, int32Type);
					break;
			}
		},
		(ref immutable LowExprKind.SpecialUnary it) {
			// TODO
		},
		(ref immutable LowExprKind.SpecialBinary it) {
			// TODO
		},
		(ref immutable LowExprKind.SpecialTrinary it) {
			final switch (it.kind) {
				case LowExprKind.SpecialTrinary.Kind.if_:
					checkLowExpr(ctx, boolType, it.p0);
					checkLowExpr(ctx, type, it.p1);
					checkLowExpr(ctx, type, it.p2);
					break;
				case LowExprKind.SpecialTrinary.Kind.compareExchangeStrongBool:
					// TODO
					break;
			}
		},
		(ref immutable LowExprKind.SpecialNAry it) {
			final switch (it.kind) {
				case LowExprKind.SpecialNAry.Kind.callFunPtr:
					immutable LowExpr funPtr = at(it.args, 0);
					immutable LowFunPtrType funPtrType =
						fullIndexDictGet(ctx.ctx.program.allFunPtrTypes, asFunPtrType(funPtr.type));
					checkTypeEqual(ctx.ctx, type, funPtrType.returnType);
					verify(sizeEq(funPtrType.paramTypes, tail(it.args)));
					zip(
						funPtrType.paramTypes,
						tail(it.args),
						(ref immutable LowType paramType, ref immutable LowExpr arg) {
							checkLowExpr(ctx, paramType, arg);
						});
			}
		});
}

void checkTypeEqual(ref immutable Ctx ctx, ref immutable LowType expected, ref immutable LowType actual) {
	if (!lowTypeEqual(expected, actual)) {
		debug {
			import core.stdc.stdio : printf;
			import util.alloc.stackAlloc : StackAlloc;
			import util.sexprPrint : printOutSexpr, PrintFormat;
			printf("checkLowModel failed!\nExpected:\n");
			StackAlloc!("checkTypeEqual", 4 * 1024) alloc;
			printOutSexpr(tataOfLowType2(alloc, ctx, expected), PrintFormat.sexpr);
			printf("Actual:\n");
			printOutSexpr(tataOfLowType2(alloc, ctx, actual), PrintFormat.sexpr);
		}

		verify(0);
	}
}

immutable(Sexpr) tataOfLowType2(Alloc)(ref Alloc alloc, ref immutable Ctx ctx, immutable LowType a) {
	return matchLowType(
		a,
		(immutable LowType.ExternPtr) =>
			todo!(immutable Sexpr)("tataOfLowType"),
		(immutable LowType.FunPtr) =>
			todo!(immutable Sexpr)("tataOfLowType"),
		(immutable LowType.NonFunPtr it) =>
			tataRecord(alloc, "ptr", tataOfLowType2(alloc, ctx, it.pointee)),
		(immutable PrimitiveType it) =>
			tataSym(symOfPrimitiveType(it)),
		(immutable LowType.Record it) =>
			tataRecord(alloc, "record", tataStr(fullIndexDictGet(ctx.program.allRecords, it).mangledName)),
		(immutable LowType.Union it) =>
			tataRecord(alloc, "union", tataStr(fullIndexDictGet(ctx.program.allUnions, it).mangledName)));
}
