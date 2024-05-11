module model.jsonOfLowModel;

@safe @nogc pure nothrow:

import frontend.storage : LineAndColumnGetters;
import model.concreteModel : ConcreteFun;
import model.constant : Constant;
import model.jsonOfConstant : jsonOfConstant;
import model.lowModel :
	debugName,
	LowExpr,
	LowExprKind,
	LowExternType,
	LowField,
	LowFun,
	LowFunBody,
	LowFunExprBody,
	LowFunIndex,
	LowFunPointerType,
	LowFunSource,
	LowLocal,
	LowLocalSource,
	LowProgram,
	LowRecord,
	LowType,
	LowUnion,
	PrimitiveType,
	UpdateParam;
import model.model : Local;
import model.jsonOfConcreteModel : jsonOfConcreteFunRef, jsonOfConcreteStructRef, jsonOfIntegralValues;
import util.alloc.alloc : Alloc;
import util.json : field, jsonObject, Json, jsonList, jsonString, kindField;
import util.sourceRange : jsonOfLineAndColumnRange;
import util.util : castNonScope, stringOfEnum, todo;

Json jsonOfLowProgram(ref Alloc alloc, in LineAndColumnGetters lineAndColumnGetters, in LowProgram a) {
	Ctx ctx = Ctx(lineAndColumnGetters);
	return jsonObject(alloc, [
		field!"extern"(
			jsonList!(LowType.Extern, LowExternType)(alloc, a.allExternTypes, (in LowExternType x) =>
				jsonOfExternType(alloc, x))),
		field!"fun-pointers"(jsonList!(LowType.FunPointer, LowFunPointerType)(
			alloc, a.allFunPointerTypes, (in LowFunPointerType x) =>
				jsonOfLowFunPointerType(alloc, x))),
		field!"records"(jsonList!(LowType.Record, LowRecord)(alloc, a.allRecords, (in LowRecord x) =>
			jsonOfLowRecord(alloc, x))),
		field!"unions"(jsonList!(LowType.Union, LowUnion)(alloc, a.allUnions, (in LowUnion x) =>
			jsonOfLowUnion(alloc, x))),
		field!"funs"(jsonList!(LowFunIndex, LowFun)(alloc, a.allFuns, (in LowFun x) =>
			jsonOfLowFun(alloc, ctx, x))),
		field!"main"(a.main.index)]);
}

private:

const struct Ctx {
	LineAndColumnGetters lineAndColumnGetters;
}

Json jsonOfLowType(ref Alloc alloc, in LowType a) =>
	a.matchIn!Json(
		(in LowType.Extern x) =>
			jsonObject(alloc, [kindField!"extern", field!"index"(x.index)]),
		(in LowType.FunPointer x) =>
			jsonObject(alloc, [kindField!"fun-pointer", field!"index"(x.index)]),
		(in PrimitiveType x) =>
			jsonString(stringOfEnum(x)),
		(in LowType.PtrGc x) =>
			jsonObject(alloc, [kindField!"gc-ptr", field!"pointee"(jsonOfLowType(alloc, *x.pointee))]),
		(in LowType.PtrRawConst x) =>
			jsonObject(alloc, [kindField!"ptr-const", field!"pointee"(jsonOfLowType(alloc, *x.pointee))]),
		(in LowType.PtrRawMut x) =>
			jsonObject(alloc, [kindField!"ptr-mut", field!"pointee"(jsonOfLowType(alloc, *x.pointee))]),
		(in LowType.Record x) =>
			jsonObject(alloc, [kindField!"record", field!"index"(x.index)]),
		(in LowType.Union x) =>
			jsonObject(alloc, [kindField!"union", field!"index"(x.index)]));

Json jsonOfExternType(ref Alloc alloc, in LowExternType a) =>
	jsonObject(alloc, [field!"source"(jsonOfConcreteStructRef(alloc, *a.source))]);

Json jsonOfLowFunPointerType(ref Alloc alloc, in LowFunPointerType a) =>
	jsonObject(alloc, [
		field!"source"(jsonOfConcreteStructRef(alloc, *a.source)),
		field!"return-type"(jsonOfLowType(alloc, a.returnType)),
		field!"param-types"(jsonList!LowType(alloc, a.paramTypes, (in LowType x) =>
			jsonOfLowType(alloc, x)))]);

Json jsonOfLowRecord(ref Alloc alloc, in LowRecord a) =>
	jsonObject(alloc, [
		field!"source"(jsonOfConcreteStructRef(alloc, *a.source)),
		field!"fields"(jsonList!LowField(alloc, a.fields, (in LowField x) =>
			jsonObject(alloc, [
				field!"name"(debugName(x)),
				field!"type"(jsonOfLowType(alloc, x.type))])))]);

Json jsonOfLowUnion(ref Alloc alloc, in LowUnion a) =>
	jsonObject(alloc, [
		field!"source"(jsonOfConcreteStructRef(alloc, *a.source)),
		field!"members"(jsonList!LowType(alloc, a.members, (in LowType x) =>
			jsonOfLowType(alloc, x)))]);

Json jsonOfLowFun(ref Alloc alloc, in Ctx ctx, in LowFun a) =>
	jsonObject(alloc, [
		field!"source"(jsonOfLowFunSource(alloc, a.source)),
		field!"return-type"(jsonOfLowType(alloc, a.returnType)),
		field!"params"(jsonList!LowLocal(alloc, a.params, (in LowLocal x) =>
			jsonOfLowLocal(alloc, x))),
		field!"body"(jsonOfLowFunBody(alloc, ctx, a.body_))]);

Json jsonOfLowFunSource(ref Alloc alloc, in LowFunSource a) =>
	a.matchIn!Json(
		(in ConcreteFun x) =>
			jsonOfConcreteFunRef(alloc, x),
		(in LowFunSource.Generated x) =>
			jsonObject(alloc, [kindField!"generated", field!"name"(x.name)]));

Json jsonOfLowFunBody(ref Alloc alloc, in Ctx ctx, in LowFunBody a) =>
	a.matchIn!Json(
		(in LowFunBody.Extern) =>
			jsonString!"extern",
		(in LowFunExprBody x) =>
			jsonOfLowExpr(alloc, ctx, x.expr));

Json jsonOfLowLocal(ref Alloc alloc, in LowLocal a) =>
	jsonObject(alloc, [
		field!"source"(jsonOfLowLocalSource(alloc, a.source)),
		field!"type"(jsonOfLowType(alloc, a.type))]);

Json jsonOfLowLocalSource(ref Alloc alloc, in LowLocalSource a) =>
	a.matchIn!Json(
		(in Local x) =>
			jsonString(x.name),
		(in LowLocalSource.Generated x) =>
			jsonObject(alloc, [
				kindField!"generated",
				field!"name"(x.name),
				field!"index"(x.index)]));

Json jsonOfLowExpr(ref Alloc alloc, in Ctx ctx, in LowExpr a) =>
	jsonObject(alloc, [
		field!"type"(jsonOfLowType(alloc, a.type)),
		field!"source"(jsonOfLineAndColumnRange(alloc, ctx.lineAndColumnGetters[a.source].range)),
		field!"expr-kind"(jsonOfLowExprKind(alloc, ctx, a.kind))]);

Json jsonOfLowExprs(ref Alloc alloc, in Ctx ctx, in LowExpr[] a) =>
	jsonList!LowExpr(alloc, a, (in LowExpr x) =>
		jsonOfLowExpr(alloc, ctx, x));

Json jsonOfLowExprKind(ref Alloc alloc, in Ctx ctx, in LowExprKind a) =>
	a.matchIn!Json(
		(in LowExprKind.Abort x) =>
			jsonObject(alloc, [kindField!"abort"]),
		(in LowExprKind.Call x) =>
			jsonObject(alloc, [
				kindField!"call",
				field!"called"(x.called.index),
				field!"args"(jsonOfLowExprs(alloc, ctx, x.args))]),
		(in LowExprKind.CallFunPointer x) =>
			jsonObject(alloc, [
				kindField!"call-fun-pointer",
				field!"fun-pointer"(jsonOfLowExpr(alloc, ctx, *x.funPtr)),
				field!"args"(jsonOfLowExprs(alloc, ctx, x.args))]),
		(in LowExprKind.CreateRecord x) =>
			jsonObject(alloc, [
				kindField!"create-record",
				field!"args"(jsonOfLowExprs(alloc, ctx, x.args))]),
		(in LowExprKind.CreateUnion x) =>
			jsonObject(alloc, [
				kindField!"create-union",
				field!"member-index"(x.memberIndex),
				field!"arg"(jsonOfLowExpr(alloc, ctx, x.arg))]),
		(in LowExprKind.FunPointer x) =>
			jsonObject(alloc, [
				kindField!"fun-pointer",
				field!"fun"(x.fun.index)]),
		(in LowExprKind.If x) =>
			jsonObject(alloc, [
				kindField!"if",
				field!"condition"(jsonOfLowExpr(alloc, ctx, x.cond)),
				field!"then"(jsonOfLowExpr(alloc, ctx, x.then)),
				field!"else"(jsonOfLowExpr(alloc, ctx, x.else_))]),
		(in LowExprKind.InitConstants) =>
			jsonString!"init-const" ,
		(in LowExprKind.Let x) =>
			jsonObject(alloc, [
				kindField!"let",
				field!"local"(jsonOfLowLocal(alloc, *x.local)),
				field!"value"(jsonOfLowExpr(alloc, ctx, x.value)),
				field!"then"(jsonOfLowExpr(alloc, ctx, x.then))]),
		(in LowExprKind.LocalGet x) =>
			jsonObject(alloc, [
				kindField!"local-get",
				field!"source"(jsonOfLowLocalSource(alloc, x.local.source))]),
		(in LowExprKind.LocalPointer x) =>
			jsonObject(alloc, [
				kindField!"local-pointer",
				field!"local"(jsonOfLowLocalSource(alloc, x.local.source))]),
		(in LowExprKind.LocalSet x) =>
			jsonObject(alloc, [
				kindField!"local-set",
				field!"source"(jsonOfLowLocalSource(alloc, x.local.source)),
				field!"value"(jsonOfLowExpr(alloc, ctx, x.value))]),
		(in LowExprKind.Loop x) =>
			jsonObject(alloc, [
				kindField!"loop",
				field!"body"(jsonOfLowExpr(alloc, ctx, x.body_))]),
		(in LowExprKind.LoopBreak x) =>
			jsonObject(alloc, [
				kindField!"break",
				field!"value"(jsonOfLowExpr(alloc, ctx, x.value))]),
		(in LowExprKind.LoopContinue) =>
			jsonObject(alloc, [kindField!"continue"]),
		(in LowExprKind.PointerCast x) =>
			jsonObject(alloc, [
				kindField!"pointer-cast",
				field!"target"(jsonOfLowExpr(alloc, ctx, x.target))]),
		(in LowExprKind.RecordFieldGet x) =>
			jsonObject(alloc, [
				kindField!"get-field",
				field!"target"(jsonOfLowExpr(alloc, ctx, *x.target)),
				field!"field-index"(x.fieldIndex)]),
		(in LowExprKind.RecordFieldPointer x) =>
			jsonObject(alloc, [
				kindField!"field-pointer",
				field!"target"(jsonOfLowExpr(alloc, ctx, *x.target)),
				field!"field-index"(x.fieldIndex)]),
				(in LowExprKind.RecordFieldSet x) =>
			jsonObject(alloc, [
				kindField!"set-field",
				field!"target"(jsonOfLowExpr(alloc, ctx, x.target)),
				field!"field-index"(x.fieldIndex),
				field!"value"(jsonOfLowExpr(alloc, ctx, x.value))]),
		(in Constant x) =>
			jsonObject(alloc, [
				kindField!"constant",
				field!"constant"(jsonOfConstant(alloc, x))]),
		(in LowExprKind.SpecialUnary x) =>
			jsonObject(alloc, [
				kindField!"unary",
				field!"operation"(stringOfEnum(x.kind)),
				field!"arg"(jsonOfLowExpr(alloc, ctx, x.arg))]),
		(in LowExprKind.SpecialUnaryMath x) =>
			jsonObject(alloc, [
				kindField!"unary-math",
				field!"fun"(stringOfEnum(x.kind)),
				field!"arg"(jsonOfLowExpr(alloc, ctx, x.arg))]),
		(in LowExprKind.SpecialBinary x) =>
			jsonObject(alloc, [
				kindField!"binary",
				field!"operation"(stringOfEnum(x.kind)),
				field!"args"(jsonList!LowExpr(alloc, castNonScope(x.args), (in LowExpr e) =>
					jsonOfLowExpr(alloc, ctx, e)))]),
		(in LowExprKind.SpecialBinaryMath x) =>
			jsonObject(alloc, [
				kindField!"binary-math",
				field!"fun"(stringOfEnum(x.kind)),
				field!"args"(jsonList!LowExpr(alloc, castNonScope(x.args), (in LowExpr e) =>
					jsonOfLowExpr(alloc, ctx, e)))]),
		(in LowExprKind.SpecialTernary x) =>
			jsonObject(alloc, [
				kindField!"ternary",
				field!"operation"(stringOfEnum(x.kind)),
				field!"args"(jsonList!LowExpr(alloc, castNonScope(x.args), (in LowExpr e) =>
					jsonOfLowExpr(alloc, ctx, e)))]),
		(in LowExprKind.Special4ary x) =>
			todo!Json("SPECIAL4ARY"), // ----------------------------------------------------------------------------------------
		(in LowExprKind.Switch x) =>
			jsonObject(alloc, [
				kindField!"switch",
				field!"value"(jsonOfLowExpr(alloc, ctx, x.value)),
				field!"case-values"(jsonOfIntegralValues(alloc, x.caseValues)),
				field!"case-exprs"(jsonOfLowExprs(alloc, ctx, x.caseExprs))]),
		(in LowExprKind.TailRecur x) =>
			jsonObject(alloc, [
				kindField!"tail-recur",
				field!"updates"(jsonList!UpdateParam(alloc, x.updateParams, (in UpdateParam updateParam) =>
					jsonObject(alloc, [
						field!"param"(jsonOfLowLocalSource(alloc, updateParam.param.source)),
						field!"value"(jsonOfLowExpr(alloc, ctx, updateParam.newValue)),
					])))]),
		(in LowExprKind.UnionAs x) =>
			jsonObject(alloc, [
				kindField!"union-as",
				field!"union"(jsonOfLowExpr(alloc, ctx, *x.union_)),
				field!"member-index"(x.memberIndex)]),
		(in LowExprKind.UnionKind x) =>
			jsonObject(alloc, [
				kindField!"union-kind",
				field!"union"(jsonOfLowExpr(alloc, ctx, *x.union_))]),
		(in LowExprKind.VarGet x) =>
			jsonObject(alloc, [
				kindField!"var-get",
				field!"var"(x.varIndex.index)]),
		(in LowExprKind.VarSet x) =>
			jsonObject(alloc, [
				kindField!"var-set",
				field!"var"(x.varIndex.index),
				field!"value"(jsonOfLowExpr(alloc, ctx, *x.value))]));
