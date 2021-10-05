module lower.checkLowModel;

@safe @nogc pure nothrow:

import lower.lowExprHelpers : boolType, nat64Type, voidType;
import model.constant : Constant;
import model.lowModel :
	asFunPtrType,
	asRecordType,
	asUnionType,
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
	lowTypeEqual,
	matchLowExprKind,
	matchLowFunBody,
	matchLowType,
	PrimitiveType,
	symOfPrimitiveType;
import model.reprConcreteModel : reprOfConcreteStructRef;
import util.collection.arr : at, sizeEq;
import util.collection.arrUtil : tail, zip;
import util.collection.fullIndexDict : fullIndexDictEachValue, fullIndexDictGet, fullIndexDictGetPtr;
import util.opt : force, has;
import util.ptr : Ptr, ptrTrustMe;
import util.repr : Repr, reprRecord, reprSym;
import util.util : verify;

void checkLowProgram(Alloc)(ref Alloc alloc, ref immutable LowProgram a) {
	immutable Ctx ctx = immutable Ctx(ptrTrustMe(a));
	fullIndexDictEachValue!(LowFunIndex, LowFun)(a.allFuns, (ref immutable LowFun fun) {
		checkLowFun(alloc, ctx, fun);
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

void checkLowFun(Alloc)(ref Alloc alloc, ref immutable Ctx ctx, ref immutable LowFun fun) {
	matchLowFunBody!void(
		fun.body_,
		(ref immutable LowFunBody.Extern) {},
		(ref immutable LowFunExprBody it) {
			immutable FunCtx funCtx = immutable FunCtx(ctx, ptrTrustMe(fun));
			checkLowExpr(alloc, funCtx, fun.returnType, it.expr);
		});
}

void checkLowExpr(Alloc)(
	ref Alloc alloc,
	ref immutable FunCtx ctx,
	ref immutable LowType type,
	ref immutable LowExpr expr,
) {
	checkTypeEqual(alloc, ctx.ctx, type, expr.type);
	matchLowExprKind!void(
		expr.kind,
		(ref immutable LowExprKind.Call it) {
			immutable Ptr!LowFun fun = fullIndexDictGetPtr(ctx.ctx.program.allFuns, it.called);
			checkTypeEqual(alloc, ctx.ctx, type, fun.returnType);
			verify(sizeEq(fun.params, it.args));
			zip!(LowParam, LowExpr)(fun.params, it.args, (ref immutable LowParam param, ref immutable LowExpr arg) {
				checkLowExpr(alloc, ctx, param.type, arg);
			});
		},
		(ref immutable LowExprKind.CreateRecord it) {
			immutable LowField[] fields = fullIndexDictGet(ctx.ctx.program.allRecords, asRecordType(type)).fields;
			zip!(LowField, LowExpr)(fields, it.args, (ref immutable LowField field, ref immutable LowExpr arg) {
				checkLowExpr(alloc, ctx, field.type, arg);
			});
		},
		(ref immutable LowExprKind.ConvertToUnion it) {
			immutable LowType member = at(
				fullIndexDictGet(ctx.ctx.program.allUnions, asUnionType(type)).members,
				it.memberIndex);
			checkLowExpr(alloc, ctx, member, it.arg);
		},
		(ref immutable LowExprKind.Let it) {
			checkLowExpr(alloc, ctx, it.local.type, it.value);
			checkLowExpr(alloc, ctx, type, it.then);
		},
		(ref immutable LowExprKind.LocalRef it) {
			checkTypeEqual(alloc, ctx.ctx, type, it.local.type);
		},
		(ref immutable LowExprKind.MatchUnion it) {
			checkLowExpr(alloc, ctx, it.matchedValue.type, it.matchedValue);
			zip!(LowType, LowExprKind.MatchUnion.Case)(
				fullIndexDictGet(ctx.ctx.program.allUnions, asUnionType(it.matchedValue.type)).members,
				it.cases,
				(ref immutable LowType memberType, ref immutable LowExprKind.MatchUnion.Case case_) {
					if (has(case_.local))
						checkTypeEqual(alloc, ctx.ctx, memberType, force(case_.local).type);
					checkLowExpr(alloc, ctx, type, case_.then);
				});
		},
		(ref immutable LowExprKind.ParamRef it) {
			checkTypeEqual(alloc, ctx.ctx, type, at(ctx.fun.params, it.index.index).type);
		},
		(ref immutable LowExprKind.PtrCast it) {
			// TODO: there are some limitations on target...
			checkLowExpr(alloc, ctx, it.target.type, it.target);
		},
		(ref immutable LowExprKind.RecordFieldGet it) {
			immutable LowType targetTypeNonPtr = immutable LowType(it.record);
			immutable LowType targetType = it.targetIsPointer
				? immutable LowType(immutable LowType.PtrGc(ptrTrustMe(targetTypeNonPtr)))
				: targetTypeNonPtr;
			checkLowExpr(alloc, ctx, targetType, it.target);
			immutable LowType fieldType =
				at(fullIndexDictGet(ctx.ctx.program.allRecords, it.record).fields, it.fieldIndex).type;
			checkTypeEqual(alloc, ctx.ctx, type, fieldType);
		},
		(ref immutable LowExprKind.RecordFieldSet it) {
			immutable LowType targetTypeNonPtr = immutable LowType(it.record);
			immutable LowType targetType = it.targetIsPointer
				? immutable LowType(immutable LowType.PtrGc(ptrTrustMe(targetTypeNonPtr)))
				: targetTypeNonPtr;
			checkLowExpr(alloc, ctx, targetType, it.target);
			immutable LowType fieldType =
				at(fullIndexDictGet(ctx.ctx.program.allRecords, it.record).fields, it.fieldIndex).type;
			checkLowExpr(alloc, ctx, fieldType, it.value);
			checkTypeEqual(alloc, ctx.ctx, type, voidType);
		},
		(ref immutable LowExprKind.Seq it) {
			checkLowExpr(alloc, ctx, voidType, it.first);
			checkLowExpr(alloc, ctx, type, it.then);
		},
		(ref immutable LowExprKind.SizeOf it) {
			checkTypeEqual(alloc, ctx.ctx, type, nat64Type);
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
		(ref immutable LowExprKind.SpecialTrinary it) {
			final switch (it.kind) {
				case LowExprKind.SpecialTrinary.Kind.if_:
					checkLowExpr(alloc, ctx, boolType, it.p0);
					checkLowExpr(alloc, ctx, type, it.p1);
					checkLowExpr(alloc, ctx, type, it.p2);
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
					immutable Ptr!LowFunPtrType funPtrType =
						fullIndexDictGetPtr(ctx.ctx.program.allFunPtrTypes, asFunPtrType(funPtr.type));
					checkTypeEqual(alloc, ctx.ctx, type, funPtrType.returnType);
					verify(sizeEq(funPtrType.paramTypes, tail(it.args)));
					zip!(LowType, LowExpr)(
						funPtrType.paramTypes,
						tail(it.args),
						(ref immutable LowType paramType, ref immutable LowExpr arg) {
							checkLowExpr(alloc, ctx, paramType, arg);
						});
			}
		},
		(ref immutable LowExprKind.Switch0ToN it) {
			checkLowExpr(alloc, ctx, it.value.type, it.value);
			foreach (ref immutable LowExpr case_; it.cases)
				checkLowExpr(alloc, ctx, type, case_);
		},
		(ref immutable LowExprKind.SwitchWithValues it) {
			checkLowExpr(alloc, ctx, it.value.type, it.value);
			foreach (ref immutable LowExpr case_; it.cases)
				checkLowExpr(alloc, ctx, type, case_);
		},
		(ref immutable LowExprKind.TailRecur) {
			// TODO
		},
		(ref immutable LowExprKind.Zeroed) {});
}

void checkTypeEqual(Alloc)(
	ref Alloc alloc,
	ref immutable Ctx ctx,
	ref immutable LowType expected,
	ref immutable LowType actual,
) {
	/*
	debug {
		if (!lowTypeEqual(expected, actual)) {
			import core.stdc.stdio : printf;
			import util.repr : writeRepr;
			import util.writer : finishWriterToCStr, Writer, writeStatic;
			import util.ptr : ptrTrustMe_mut;
			Writer!Alloc writer = Writer!Alloc(ptrTrustMe_mut(alloc));
			writeStatic(writer, "Type is not as expected. Expected:\n");
			writeRepr(writer, reprOfLowType2(alloc, ctx, expected));
			writeStatic(writer, "Actual:\n");
			writeRepr(writer, reprOfLowType2(alloc, ctx, actual));
			printf("%s\n", finishWriterToCStr(writer));
		}
	}
	*/
	verify(lowTypeEqual(expected, actual));
}

immutable(Repr) reprOfLowType2(Alloc)(ref Alloc alloc, ref immutable Ctx ctx, immutable LowType a) {
	return matchLowType!(immutable Repr)(
		a,
		(immutable LowType.ExternPtr) =>
			reprSym("a-extern-ptr"), //TODO: more detail
		(immutable LowType.FunPtr) =>
			reprSym("some-fun-ptr"), //TODO: more detail
		(immutable PrimitiveType it) =>
			reprSym(symOfPrimitiveType(it)),
		(immutable LowType.PtrGc it) =>
			reprRecord(alloc, "gc-ptr", [reprOfLowType2(alloc, ctx, it.pointee)]),
		(immutable LowType.PtrRaw it) =>
			reprRecord(alloc, "raw-ptr", [reprOfLowType2(alloc, ctx, it.pointee)]),
		(immutable LowType.Record it) =>
			reprOfConcreteStructRef(alloc, fullIndexDictGet(ctx.program.allRecords, it).source),
		(immutable LowType.Union it) =>
			reprOfConcreteStructRef(alloc, fullIndexDictGet(ctx.program.allUnions, it).source));
}
