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
import util.opt : force, has;
import util.ptr : Ptr, ptrTrustMe;
import util.sexpr : Sexpr, tataRecord, tataStr, tataSym;
import util.util : todo, verify;

void checkLowProgram(ref immutable LowProgram a) {
	immutable Ctx ctx = immutable Ctx(ptrTrustMe(a));
	foreach (ref immutable LowFun fun; range(a.allFuns))
		checkLowFun(ctx, fun);
	checkLowFun(ctx, a.main);
}

private:

struct Ctx {
	Ptr!LowProgram program;
}

void checkLowFun(ref immutable Ctx ctx, ref immutable LowFun fun) {
	matchLowFunBody!void(
		fun.body_,
		(ref immutable LowFunBody.Extern) {},
		(ref immutable LowFunExprBody it) {
			checkLowExpr(ctx, fun.returnType, it.expr);
		});
}

void checkLowExpr(ref immutable Ctx ctx, ref immutable LowType type, ref immutable LowExpr expr) {
	checkTypeEqual(ctx, type, expr.type);
	matchLowExprKind(
		expr.kind,
		(ref immutable LowExprKind.Call it) {
			immutable LowFun fun = at(ctx.program.allFuns, it.called.index);
			checkTypeEqual(ctx, type, fun.returnType);
			verify(sizeEq(fun.params, it.args));
			zip(fun.params, it.args, (ref immutable LowParam param, ref immutable LowExpr arg) {
				checkLowExpr(ctx, param.type, arg);
			});
		},
		(ref immutable LowExprKind.CreateRecord it) {
			immutable LowRecord record = at(ctx.program.allRecords, asRecordType(type).index);
			verify(sizeEq(record.fields, it.args));
			zip(record.fields, it.args, (ref immutable LowField field, ref immutable LowExpr arg) {
				checkLowExpr(ctx, field.type, arg);
			});
		},
		(ref immutable LowExprKind.ConvertToUnion it) {
			immutable LowUnion union_ = at(ctx.program.allUnions, asUnionType(type).index);
			immutable LowType member = at(union_.members, it.memberIndex);
			checkLowExpr(ctx, member, it.arg);
		},
		(ref immutable LowExprKind.FunPtr it) {
			immutable LowFun fun = at(ctx.program.allFuns, it.fun.index);
			immutable LowFunPtrType funType = at(ctx.program.allFunPtrTypes, asFunPtrType(type).index);
			verify(sizeEq(fun.params, funType.paramTypes));
			size_t index = 0;
			zip(fun.params, funType.paramTypes, (ref immutable LowParam param, ref immutable LowType paramType) {
				// TODO: this is failing for lambda closure,
				// which is any-ptr in the function type and has a better type in the function
				if (index != 1) {
					checkTypeEqual(ctx, param.type, paramType);
				}
				index++;
			});
		},
		(ref immutable LowExprKind.Let it) {
			checkLowExpr(ctx, it.local.type, it.value);
			checkLowExpr(ctx, type, it.then);
		},
		(ref immutable LowExprKind.LocalRef it) {
			checkTypeEqual(ctx, type, it.local.type);
		},
		(ref immutable LowExprKind.Match it) {
			checkLowExpr(ctx, it.matchedLocal.type, it.matchedValue);
			immutable LowUnion union_ = at(ctx.program.allUnions, asUnionType(it.matchedLocal.type).index);
			verify(sizeEq(union_.members, it.cases));
			zip(
				union_.members,
				it.cases,
				(ref immutable LowType memberType, ref immutable LowExprKind.Match.Case case_) {
					if (has(case_.local))
						checkTypeEqual(ctx, memberType, force(case_.local).type);
					checkLowExpr(ctx, type, case_.then);
				});
		},
		(ref immutable LowExprKind.ParamRef it) {
			checkTypeEqual(ctx, type, it.param.type);
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
			checkTypeEqual(ctx, type, it.field.type);
		},
		(ref immutable LowExprKind.RecordFieldSet it) {
			immutable LowType targetTypeNonPtr = immutable LowType(it.record);
			immutable LowType targetType = it.targetIsPointer
				? immutable LowType(immutable LowType.NonFunPtr(ptrTrustMe(targetTypeNonPtr)))
				: targetTypeNonPtr;
			checkLowExpr(ctx, targetType, it.target);
			checkLowExpr(ctx, it.field.type, it.value);
			checkTypeEqual(ctx, type, voidType);
		},
		(ref immutable LowExprKind.Seq it) {
			checkLowExpr(ctx, voidType, it.first);
			checkLowExpr(ctx, type, it.then);
		},
		(ref immutable LowExprKind.SizeOf it) {
			checkTypeEqual(ctx, type, nat64Type);
		},
		(ref immutable LowExprKind.SpecialConstant it) {
			matchSpecialConstant!void(
				it,
				(immutable LowExprKind.SpecialConstant.BoolConstant) {
					checkTypeEqual(ctx, type, boolType);
				},
				(immutable LowExprKind.SpecialConstant.Integral) {
					// TODO
				},
				(immutable LowExprKind.SpecialConstant.Null) {
					// TODO
				},
				(immutable LowExprKind.SpecialConstant.Void) {
					checkTypeEqual(ctx, type, voidType);
				});
		},
		(ref immutable LowExprKind.Special0Ary it) {
			final switch (it.kind) {
				case LowExprKind.Special0Ary.Kind.getErrno:
					checkTypeEqual(ctx, type, int32Type);
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
				case LowExprKind.SpecialTrinary.Kind.compareExchangeStrong:
					// TODO
					break;
			}
		},
		(ref immutable LowExprKind.SpecialNAry it) {
			final switch (it.kind) {
				case LowExprKind.SpecialNAry.Kind.callFunPtr:
					immutable LowExpr funPtr = at(it.args, 0);
					immutable LowFunPtrType funPtrType =
						at(ctx.program.allFunPtrTypes, asFunPtrType(funPtr.type).index);
					checkTypeEqual(ctx, type, funPtrType.returnType);
					verify(sizeEq(funPtrType.paramTypes, tail(it.args)));
					zip(
						funPtrType.paramTypes,
						tail(it.args),
						(ref immutable LowType paramType, ref immutable LowExpr arg) {
							checkLowExpr(ctx, paramType, arg);
						});
			}
		},
		(ref immutable LowExprKind.StringLiteral) {
			// TODO
		});
}

void checkTypeEqual(ref immutable Ctx ctx, ref immutable LowType expected, ref immutable LowType actual) {
	if (!lowTypeEqual(expected, actual)) {
		debug {
			//import core.stdc.stdio : printf;
			//import util.alloc.stackAlloc : StackAlloc;
			//import util.sexprPrint : printOutSexpr;
			//printf("checkLowModel failed!\nExpected:\n");
			//StackAlloc!("checkTypeEqual", 4 * 1024) alloc;
			//printOutSexpr(tataOfLowType2(alloc, ctx, expected));
			//printf("Actual:\n");
			//printOutSexpr(tataOfLowType2(alloc, ctx, actual));
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
			tataRecord(alloc, "record", tataStr(at(ctx.program.allRecords, it.index).mangledName)),
		(immutable LowType.Union it) =>
			tataRecord(alloc, "union", tataStr(at(ctx.program.allUnions, it.index).mangledName)));
}
