module model.jsonOfLowModel;

@safe @nogc pure nothrow:

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
	LowFunPtrType,
	LowFunSource,
	LowLocal,
	LowLocalSource,
	LowProgram,
	LowRecord,
	LowType,
	LowUnion,
	PrimitiveType,
	symOfPrimitiveType,
	UpdateParam;
import model.model : EnumValue, Local;
import model.jsonOfConcreteModel : jsonOfConcreteFunRef, jsonOfConcreteStructRef;
import util.alloc.alloc : Alloc;
import util.json : field, jsonObject, optionalField, Json, jsonInt, jsonList, jsonString, kindField;
import util.ptr : castNonScope_ref;
import util.sourceRange : jsonOfFileAndRange;

Json jsonOfLowProgram(ref Alloc alloc, in LowProgram a) =>
	jsonObject(alloc, [
		field!"extern"(
			jsonList!(LowType.Extern, LowExternType)(alloc, a.allExternTypes, (in LowExternType x) =>
				jsonOfExternType(alloc, x))),
		field!"fun-pointers"(jsonList!(LowType.FunPtr, LowFunPtrType)(alloc, a.allFunPtrTypes, (in LowFunPtrType x) =>
			jsonOfLowFunPtrType(alloc, x))),
		field!"records"(jsonList!(LowType.Record, LowRecord)(alloc, a.allRecords, (in LowRecord x) =>
			jsonOfLowRecord(alloc, x))),
		field!"unions"(jsonList!(LowType.Union, LowUnion)(alloc, a.allUnions, (in LowUnion x) =>
			jsonOfLowUnion(alloc, x))),
		field!"funs"(jsonList!(LowFunIndex, LowFun)(alloc, a.allFuns, (in LowFun x) =>
			jsonOfLowFun(alloc, x))),
		field!"main"(a.main.index)]);

private:

Json jsonOfLowType(ref Alloc alloc, in LowType a) =>
	a.matchIn!Json(
		(in LowType.Extern x) =>
			jsonObject(alloc, [kindField!"extern", field!"index"(x.index)]),
		(in LowType.FunPtr x) =>
			jsonObject(alloc, [kindField!"fun-pointer", field!"index"(x.index)]),
		(in PrimitiveType x) =>
			jsonString(symOfPrimitiveType(x)),
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

Json jsonOfLowFunPtrType(ref Alloc alloc, in LowFunPtrType a) =>
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

Json jsonOfLowFun(ref Alloc alloc, in LowFun a) =>
	jsonObject(alloc, [
		field!"source"(jsonOfLowFunSource(alloc, a.source)),
		field!"return-type"(jsonOfLowType(alloc, a.returnType)),
		field!"params"(jsonList!LowLocal(alloc, a.params, (in LowLocal x) =>
			jsonOfLowLocal(alloc, x))),
		field!"body"(jsonOfLowFunBody(alloc, a.body_))]);

Json jsonOfLowFunSource(ref Alloc alloc, in LowFunSource a) =>
	a.matchIn!Json(
		(in ConcreteFun x) =>
			jsonOfConcreteFunRef(alloc, x),
		(in LowFunSource.Generated x) =>
			jsonObject(alloc, [kindField!"generated", field!"name"(x.name)]));

Json jsonOfLowFunBody(ref Alloc alloc, in LowFunBody a) =>
	a.matchIn!Json(
		(in LowFunBody.Extern) =>
			jsonString!"extern",
		(in LowFunExprBody x) =>
			jsonOfLowExpr(alloc, x.expr));

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

Json jsonOfLowExpr(ref Alloc alloc, in LowExpr a) =>
	jsonObject(alloc, [
		field!"type"(jsonOfLowType(alloc, a.type)),
		field!"source"(jsonOfFileAndRange(alloc, a.source)),
		field!"expr-kind"(jsonOfLowExprKind(alloc, a.kind))]);

Json jsonOfLowExprs(ref Alloc alloc, in LowExpr[] a) =>
	jsonList!LowExpr(alloc, a, (in LowExpr x) =>
		jsonOfLowExpr(alloc, x));

Json jsonOfLowExprKind(ref Alloc alloc, in LowExprKind a) =>
	a.matchIn!Json(
		(in LowExprKind.Call x) =>
			jsonObject(alloc, [
				kindField!"call",
				field!"called"(x.called.index),
				field!"args"(jsonOfLowExprs(alloc, x.args))]),
		(in LowExprKind.CallFunPtr x) =>
			jsonObject(alloc, [
				kindField!"call-fun-pointer",
				field!"fun-pointer"(jsonOfLowExpr(alloc, x.funPtr)),
				field!"args"(jsonOfLowExprs(alloc, x.args))]),
		(in LowExprKind.CreateRecord x) =>
			jsonObject(alloc, [
				kindField!"create-record",
				field!"args"(jsonOfLowExprs(alloc, x.args))]),
		(in LowExprKind.CreateUnion x) =>
			jsonObject(alloc, [
				kindField!"create-union",
				field!"member-index"(x.memberIndex),
				field!"arg"(jsonOfLowExpr(alloc, x.arg))]),
		(in LowExprKind.If x) =>
			jsonObject(alloc, [
				kindField!"if",
				field!"condition"(jsonOfLowExpr(alloc, x.cond)),
				field!"then"(jsonOfLowExpr(alloc, x.then)),
				field!"else"(jsonOfLowExpr(alloc, x.else_))]),
		(in LowExprKind.InitConstants) =>
			jsonString!"init-const" ,
		(in LowExprKind.Let x) =>
			jsonObject(alloc, [
				kindField!"let",
				field!"local"(jsonOfLowLocal(alloc, *x.local)),
				field!"value"(jsonOfLowExpr(alloc, x.value)),
				field!"then"(jsonOfLowExpr(alloc, x.then))]),
		(in LowExprKind.LocalGet x) =>
			jsonObject(alloc, [
				kindField!"local-get",
				field!"source"(jsonOfLowLocalSource(alloc, x.local.source))]),
		(in LowExprKind.LocalSet x) =>
			jsonObject(alloc, [
				kindField!"local-set",
				field!"source"(jsonOfLowLocalSource(alloc, x.local.source)),
				field!"value"(jsonOfLowExpr(alloc, x.value))]),
		(in LowExprKind.Loop x) =>
			jsonObject(alloc, [
				kindField!"loop",
				field!"body"(jsonOfLowExpr(alloc, x.body_))]),
		(in LowExprKind.LoopBreak x) =>
			jsonObject(alloc, [
				kindField!"break",
				field!"value"(jsonOfLowExpr(alloc, x.value))]),
		(in LowExprKind.LoopContinue) =>
			jsonObject(alloc, [kindField!"continue"]),
		(in LowExprKind.MatchUnion x) =>
			jsonOfMatchUnion(alloc, x),
		(in LowExprKind.PtrCast x) =>
			jsonObject(alloc, [
				kindField!"pointer-cast",
				field!"target"(jsonOfLowExpr(alloc, x.target))]),
		(in LowExprKind.PtrToField x) =>
			jsonObject(alloc, [
				kindField!"pointer-to-field",
				field!"target"(jsonOfLowExpr(alloc, x.target)),
				field!"field-index"(x.fieldIndex)]),
		(in LowExprKind.PtrToLocal x) =>
			jsonObject(alloc, [
				kindField!"pointer-to-local",
				field!"local"(jsonOfLowLocalSource(alloc, x.local.source))]),
		(in LowExprKind.RecordFieldGet x) =>
			jsonObject(alloc, [
				kindField!"get-field",
				field!"target"(jsonOfLowExpr(alloc, x.target)),
				field!"field-index"(x.fieldIndex)]),
		(in LowExprKind.RecordFieldSet x) =>
			jsonObject(alloc, [
				kindField!"set-field",
				field!"target"(jsonOfLowExpr(alloc, x.target)),
				field!"field-index"(x.fieldIndex),
				field!"value"(jsonOfLowExpr(alloc, x.value))]),
		(in LowExprKind.SizeOf x) =>
			jsonObject(alloc, [
				kindField!"size-of",
				field!"type"(jsonOfLowType(alloc, x.type))]),
		(in Constant x) =>
			jsonObject(alloc, [
				kindField!"constant",
				field!"constant"(jsonOfConstant(alloc, x))]),
		(in LowExprKind.SpecialUnary x) =>
			jsonObject(alloc, [
				kindField!"unary",
				field!"operation"(strOfSpecialUnaryKind(x.kind)),
				field!"arg"(jsonOfLowExpr(alloc, x.arg))]),
		(in LowExprKind.SpecialBinary x) =>
			jsonObject(alloc, [
				kindField!"binary",
				field!"operation"(strOfSpecialBinaryKind(x.kind)),
				field!"args"(jsonList!LowExpr(alloc, castNonScope_ref(x.args), (in LowExpr e) =>
					jsonOfLowExpr(alloc, e)))]),
		(in LowExprKind.SpecialTernary x) =>
			jsonObject(alloc, [
				kindField!"ternary",
				field!"operation"(strOfSpecialTernaryKind(x.kind)),
				field!"args"(jsonList!LowExpr(alloc, castNonScope_ref(x.args), (in LowExpr e) =>
					jsonOfLowExpr(alloc, e)))]),
		(in LowExprKind.Switch0ToN x) =>
			jsonObject(alloc, [
				kindField!"switch",
				field!"value"(jsonOfLowExpr(alloc, x.value)),
				field!"cases"(jsonOfLowExprs(alloc, x.cases))]),
		(in LowExprKind.SwitchWithValues x) =>
			jsonObject(alloc, [
				kindField!"switch",
				field!"value"(jsonOfLowExpr(alloc, x.value)),
				field!"values"(jsonList!EnumValue(alloc, x.values, (in EnumValue value) =>
					jsonInt(value.value))),
				field!"cases"(jsonOfLowExprs(alloc, x.cases))]),
		(in LowExprKind.TailRecur x) =>
			jsonObject(alloc, [
				kindField!"tail-recur",
				field!"updates"(jsonList!UpdateParam(alloc, x.updateParams, (in UpdateParam updateParam) =>
					jsonObject(alloc, [
						field!"param"(jsonOfLowLocalSource(alloc, updateParam.param.source)),
						field!"value"(jsonOfLowExpr(alloc, updateParam.newValue)),
					])))]),
		(in LowExprKind.VarGet x) =>
			jsonObject(alloc, [
				kindField!"var-get",
				field!"var"(x.varIndex.index)]),
		(in LowExprKind.VarSet x) =>
			jsonObject(alloc, [
				kindField!"var-set",
				field!"var"(x.varIndex.index),
				field!"value"(jsonOfLowExpr(alloc, *x.value))]));

Json jsonOfMatchUnion(ref Alloc alloc, in LowExprKind.MatchUnion a) =>
	jsonObject(alloc, [
		kindField!"match-union",
		field!"value"(jsonOfLowExpr(alloc, a.matchedValue)),
		field!"cases"(jsonList!(LowExprKind.MatchUnion.Case)(alloc, a.cases, (in LowExprKind.MatchUnion.Case case_) =>
			jsonObject(alloc, [
				optionalField!("local", LowLocal*)(case_.local, (in LowLocal* x) =>
					jsonOfLowLocalSource(alloc, x.source)),
				field!"then"(jsonOfLowExpr(alloc, case_.then))])))]);

string strOfSpecialUnaryKind(LowExprKind.SpecialUnary.Kind a) {
	final switch (a) {
		case LowExprKind.SpecialUnary.Kind.asAnyPtr:
			return "as-any-ptr";
		case LowExprKind.SpecialUnary.Kind.bitwiseNotNat8:
			return "bitwise-not (nat8)";
		case LowExprKind.SpecialUnary.Kind.bitwiseNotNat16:
			return "bitwise-not (nat16)";
		case LowExprKind.SpecialUnary.Kind.bitwiseNotNat32:
			return "bitwise-not (nat32)";
		case LowExprKind.SpecialUnary.Kind.bitwiseNotNat64:
			return "bitwise-not (nat64)";
		case LowExprKind.SpecialUnary.Kind.countOnesNat64:
			return "count-ones (nat64)";
		case LowExprKind.SpecialUnary.Kind.deref:
			return "deref";
		case LowExprKind.SpecialUnary.Kind.drop:
			return "drop";
		case LowExprKind.SpecialUnary.Kind.enumToIntegral:
			return "to integral (from enum)";
		case LowExprKind.SpecialUnary.Kind.toChar8FromNat8:
			return "to char8(nat8)";
		case LowExprKind.SpecialUnary.Kind.toFloat32FromFloat64:
			return "to float32(float64)";
		case LowExprKind.SpecialUnary.Kind.toFloat64FromFloat32:
			return "to float64(float32)";
		case LowExprKind.SpecialUnary.Kind.toFloat64FromInt64:
			return "to float64(int64)";
		case LowExprKind.SpecialUnary.Kind.toFloat64FromNat64:
			return "to float64(nat64)";
		case LowExprKind.SpecialUnary.Kind.toInt64FromInt8:
			return "to int64(int8)";
		case LowExprKind.SpecialUnary.Kind.toInt64FromInt16:
			return "to int64(int16)";
		case LowExprKind.SpecialUnary.Kind.toInt64FromInt32:
			return "to int64(int32)";
		case LowExprKind.SpecialUnary.Kind.toNat8FromChar8:
			return "to nat8(char8)";
		case LowExprKind.SpecialUnary.Kind.toNat64FromNat8:
			return "to nat64(nat8)";
		case LowExprKind.SpecialUnary.Kind.toNat64FromNat16:
			return "to nat64(nat16)";
		case LowExprKind.SpecialUnary.Kind.toNat64FromNat32:
			return "to nat64(nat32)";
		case LowExprKind.SpecialUnary.Kind.toNat64FromPtr:
			return "to nat64(ptr)";
		case LowExprKind.SpecialUnary.Kind.toPtrFromNat64:
			return "to ptr(nat64)";
		case LowExprKind.SpecialUnary.Kind.truncateToInt64FromFloat64:
			return "truncate-to int64(float64)";
		case LowExprKind.SpecialUnary.Kind.unsafeToInt8FromInt64:
			return "unsafe-to int8(int64)";
		case LowExprKind.SpecialUnary.Kind.unsafeToInt16FromInt64:
			return "unsafe-to int16(int64)";
		case LowExprKind.SpecialUnary.Kind.unsafeToInt32FromInt64:
			return "unsafe-to int32(int64)";
		case LowExprKind.SpecialUnary.Kind.unsafeToInt64FromNat64:
			return "unsafe-to int64(nat64)";
		case LowExprKind.SpecialUnary.Kind.unsafeToNat8FromNat64:
			return "unsafe-to nat8(nat64)";
		case LowExprKind.SpecialUnary.Kind.unsafeToNat16FromNat64:
			return "unsafe-to nat16(nat64)";
		case LowExprKind.SpecialUnary.Kind.unsafeToNat32FromInt32:
			return "unsafe-to nat32(int32)";
		case LowExprKind.SpecialUnary.Kind.unsafeToNat32FromNat64:
			return "unsafe-to nat32(nat64)";
		case LowExprKind.SpecialUnary.Kind.unsafeToNat64FromInt64:
			return "unsafe-to int64(nat64)";
	}
}

string strOfSpecialBinaryKind(LowExprKind.SpecialBinary.Kind a) {
	final switch (a) {
		case LowExprKind.SpecialBinary.Kind.addFloat32:
			return "+ (float32)";
		case LowExprKind.SpecialBinary.Kind.addFloat64:
			return "+ (float64)";
		case LowExprKind.SpecialBinary.Kind.addPtrAndNat64:
			return "+ (ptr + nat64)";
		case LowExprKind.SpecialBinary.Kind.and:
			return "and";
		case LowExprKind.SpecialBinary.Kind.bitwiseAndInt8:
			return "bitwise-and (int8)";
		case LowExprKind.SpecialBinary.Kind.bitwiseAndInt16:
			return "bitwise-and (int16)";
		case LowExprKind.SpecialBinary.Kind.bitwiseAndInt32:
			return "bitwise-and (int32)";
		case LowExprKind.SpecialBinary.Kind.bitwiseAndInt64:
			return "bitwise-and (int64)";
		case LowExprKind.SpecialBinary.Kind.bitwiseAndNat8:
			return "bitwise-and (nat8)";
		case LowExprKind.SpecialBinary.Kind.bitwiseAndNat16:
			return "bitwise-and (nat16)";
		case LowExprKind.SpecialBinary.Kind.bitwiseAndNat32:
			return "bitwise-and (nat32)";
		case LowExprKind.SpecialBinary.Kind.bitwiseAndNat64:
			return "bitwise-and (nat64)";
		case LowExprKind.SpecialBinary.Kind.bitwiseOrInt8:
			return "bitwise-or (int8)";
		case LowExprKind.SpecialBinary.Kind.bitwiseOrInt16:
			return "bitwise-or (int16)";
		case LowExprKind.SpecialBinary.Kind.bitwiseOrInt32:
			return "bitwise-or (int32)";
		case LowExprKind.SpecialBinary.Kind.bitwiseOrInt64:
			return "bitwise-or (int64)";
		case LowExprKind.SpecialBinary.Kind.bitwiseOrNat8:
			return "bitwise-or (nat8)";
		case LowExprKind.SpecialBinary.Kind.bitwiseOrNat16:
			return "bitwise-or (nat16)";
		case LowExprKind.SpecialBinary.Kind.bitwiseOrNat32:
			return "bitwise-or (nat32)";
		case LowExprKind.SpecialBinary.Kind.bitwiseOrNat64:
			return "bitwise-or (nat64)";
		case LowExprKind.SpecialBinary.Kind.bitwiseXorInt8:
			return "bitwise-xor (int8)";
		case LowExprKind.SpecialBinary.Kind.bitwiseXorInt16:
			return "bitwise-xor (int16)";
		case LowExprKind.SpecialBinary.Kind.bitwiseXorInt32:
			return "bitwise-xor (int32)";
		case LowExprKind.SpecialBinary.Kind.bitwiseXorInt64:
			return "bitwise-xor (int64)";
		case LowExprKind.SpecialBinary.Kind.bitwiseXorNat8:
			return "bitwise-xor (nat8)";
		case LowExprKind.SpecialBinary.Kind.bitwiseXorNat16:
			return "bitwise-xor (nat16)";
		case LowExprKind.SpecialBinary.Kind.bitwiseXorNat32:
			return "bitwise-xor (nat32)";
		case LowExprKind.SpecialBinary.Kind.bitwiseXorNat64:
			return "bitwise-xor (nat64)";
		case LowExprKind.SpecialBinary.Kind.eqFloat32:
			return "== (float32)";
		case LowExprKind.SpecialBinary.Kind.eqFloat64:
			return "== (float64)";
		case LowExprKind.SpecialBinary.Kind.eqInt8:
			return "== (int8)";
		case LowExprKind.SpecialBinary.Kind.eqInt16:
			return "== (int16)";
		case LowExprKind.SpecialBinary.Kind.eqInt32:
			return "== (int32)";
		case LowExprKind.SpecialBinary.Kind.eqInt64:
			return "== (int64)";
		case LowExprKind.SpecialBinary.Kind.eqNat8:
			return "== (nat8)";
		case LowExprKind.SpecialBinary.Kind.eqNat16:
			return "== (nat16)";
		case LowExprKind.SpecialBinary.Kind.eqNat32:
			return "== (nat32)";
		case LowExprKind.SpecialBinary.Kind.eqNat64:
			return "== (nat64)";
		case LowExprKind.SpecialBinary.Kind.eqPtr:
			return "ptr-eq?";
		case LowExprKind.SpecialBinary.Kind.lessChar8:
			return "< (char)";
		case LowExprKind.SpecialBinary.Kind.lessFloat32:
			return "< (float32)";
		case LowExprKind.SpecialBinary.Kind.lessFloat64:
			return "< (float32)";
		case LowExprKind.SpecialBinary.Kind.lessInt8:
			return "< (int8)";
		case LowExprKind.SpecialBinary.Kind.lessInt16:
			return "< (int16)";
		case LowExprKind.SpecialBinary.Kind.lessInt32:
			return "< (int32)";
		case LowExprKind.SpecialBinary.Kind.lessInt64:
			return "< (int64)";
		case LowExprKind.SpecialBinary.Kind.lessNat8:
			return "< (nat8)";
		case LowExprKind.SpecialBinary.Kind.lessNat16:
			return "< (nat16)";
		case LowExprKind.SpecialBinary.Kind.lessNat32:
			return "< (nat32)";
		case LowExprKind.SpecialBinary.Kind.lessNat64:
			return "< (nat64)";
		case LowExprKind.SpecialBinary.Kind.lessPtr:
			return "< (ptr)";
		case LowExprKind.SpecialBinary.Kind.mulFloat32:
			return "* (float32)";
		case LowExprKind.SpecialBinary.Kind.mulFloat64:
			return "* (float64)";
		case LowExprKind.SpecialBinary.Kind.orBool:
			return "or (bool)";
		case LowExprKind.SpecialBinary.Kind.seq:
			return "seq";
		case LowExprKind.SpecialBinary.Kind.subFloat32:
			return "- (float32)";
		case LowExprKind.SpecialBinary.Kind.subFloat64:
			return "- (float64)";
		case LowExprKind.SpecialBinary.Kind.subPtrAndNat64:
			return "- (ptr - nat64)";
		case LowExprKind.SpecialBinary.Kind.unsafeAddInt8:
			return "unsafe-add (int8)";
		case LowExprKind.SpecialBinary.Kind.unsafeAddInt16:
			return "unsafe-add (int16)";
		case LowExprKind.SpecialBinary.Kind.unsafeAddInt32:
			return "unsafe-add (int32)";
		case LowExprKind.SpecialBinary.Kind.unsafeAddInt64:
			return "unsafe-add (int64)";
		case LowExprKind.SpecialBinary.Kind.unsafeBitShiftLeftNat64:
			return "unsafe-bit-shift-left (nat64)";
		case LowExprKind.SpecialBinary.Kind.unsafeBitShiftRightNat64:
			return "unsafe-bit-shift-left (nat64)";
		case LowExprKind.SpecialBinary.Kind.unsafeDivFloat32:
			return "unsafe-div (float32)";
		case LowExprKind.SpecialBinary.Kind.unsafeDivFloat64:
			return "unsafe-div (float64)";
		case LowExprKind.SpecialBinary.Kind.unsafeDivInt8:
			return "unsafe-div (int8)";
		case LowExprKind.SpecialBinary.Kind.unsafeDivInt16:
			return "unsafe-div (int16)";
		case LowExprKind.SpecialBinary.Kind.unsafeDivInt32:
			return "unsafe-div (int32)";
		case LowExprKind.SpecialBinary.Kind.unsafeDivInt64:
			return "unsafe-div (int64)";
		case LowExprKind.SpecialBinary.Kind.unsafeDivNat8:
			return "unsafe-div (nat8)";
		case LowExprKind.SpecialBinary.Kind.unsafeDivNat16:
			return "unsafe-div (nat16)";
		case LowExprKind.SpecialBinary.Kind.unsafeDivNat32:
			return "unsafe-div (nat32)";
		case LowExprKind.SpecialBinary.Kind.unsafeDivNat64:
			return "unsafe-div (nat64)";
		case LowExprKind.SpecialBinary.Kind.unsafeModNat64:
			return "unsafe-mod (nat64)";
		case LowExprKind.SpecialBinary.Kind.unsafeMulInt8:
			return "unsafe-mul (int8)";
		case LowExprKind.SpecialBinary.Kind.unsafeMulInt16:
			return "unsafe-mul (int16)";
		case LowExprKind.SpecialBinary.Kind.unsafeMulInt32:
			return "unsafe-mul (int32)";
		case LowExprKind.SpecialBinary.Kind.unsafeMulInt64:
			return "unsafe-mul (int64)";
		case LowExprKind.SpecialBinary.Kind.unsafeSubInt8:
			return "unsafe-sub (int8)";
		case LowExprKind.SpecialBinary.Kind.unsafeSubInt16:
			return "unsafe-sub (int16)";
		case LowExprKind.SpecialBinary.Kind.unsafeSubInt32:
			return "unsafe-sub (int32)";
		case LowExprKind.SpecialBinary.Kind.unsafeSubInt64:
			return "unsafe-sub (int64)";
		case LowExprKind.SpecialBinary.Kind.wrapAddNat8:
			return "wrap-add (nat8)";
		case LowExprKind.SpecialBinary.Kind.wrapAddNat16:
			return "wrap-add (nat16)";
		case LowExprKind.SpecialBinary.Kind.wrapAddNat32:
			return "wrap-add (nat32)";
		case LowExprKind.SpecialBinary.Kind.wrapAddNat64:
			return "wrap-add (nat64)";
		case LowExprKind.SpecialBinary.Kind.wrapMulNat8:
			return "wrap-mul (nat8)";
		case LowExprKind.SpecialBinary.Kind.wrapMulNat16:
			return "wrap-mul (nat16)";
		case LowExprKind.SpecialBinary.Kind.wrapMulNat32:
			return "wrap-mul (nat32)";
		case LowExprKind.SpecialBinary.Kind.wrapMulNat64:
			return "wrap-mul (nat64)";
		case LowExprKind.SpecialBinary.Kind.wrapSubNat8:
			return "wrap-sub (nat8)";
		case LowExprKind.SpecialBinary.Kind.wrapSubNat16:
			return "wrap-sub (nat16)";
		case LowExprKind.SpecialBinary.Kind.wrapSubNat32:
			return "wrap-sub (nat32)";
		case LowExprKind.SpecialBinary.Kind.wrapSubNat64:
			return "wrap-sub (nat64)";
		case LowExprKind.SpecialBinary.Kind.writeToPtr:
			return "write to ptr";
	}
}

string strOfSpecialTernaryKind(LowExprKind.SpecialTernary.Kind a) {
	final switch (a) {
		case LowExprKind.SpecialTernary.Kind.interpreterBacktrace:
			return "interpreter-backtrace";
	}
}
