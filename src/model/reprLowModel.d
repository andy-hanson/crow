module model.reprLowModel;

@safe @nogc pure nothrow:

import model.concreteModel : ConcreteFun;
import model.constant : Constant;
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
import model.reprConcreteModel : reprOfConcreteFunRef, reprOfConcreteStructRef;
import model.reprConstant : reprOfConstant;
import util.alloc.alloc : Alloc;
import util.repr :
	nameAndRepr,
	Repr,
	reprArr,
	reprFullIndexDict,
	reprInt,
	reprNamedRecord,
	reprNat,
	reprOpt,
	reprRecord,
	reprStr,
	reprSym;
import util.sourceRange : reprFileAndRange;

Repr reprOfLowProgram(ref Alloc alloc, in LowProgram a) =>
	reprNamedRecord!"program"(alloc, [
		nameAndRepr!"extern"(
			reprFullIndexDict!(LowType.Extern, LowExternType)(alloc, a.allExternTypes, (ref LowExternType it) =>
				reprOfExternType(alloc, it))),
		nameAndRepr!"fun-pointers"(reprFullIndexDict!(LowType.FunPtr, LowFunPtrType)(
			alloc,
			a.allFunPtrTypes,
			(ref LowFunPtrType it) =>
				reprOfLowFunPtrType(alloc, it))),
		nameAndRepr!"records"(reprFullIndexDict!(LowType.Record, LowRecord)(alloc, a.allRecords, (ref LowRecord it) =>
			reprOfLowRecord(alloc, it))),
		nameAndRepr!"unions"(reprFullIndexDict!(LowType.Union, LowUnion)(alloc, a.allUnions, (ref LowUnion it) =>
			reprOfLowUnion(alloc, it))),
		nameAndRepr!"funs"(reprFullIndexDict!(LowFunIndex, LowFun)(alloc, a.allFuns, (ref LowFun it) =>
			reprOfLowFun(alloc, it))),
		nameAndRepr!"main"(reprNat(a.main.index))]);

private:

Repr reprOfLowType(ref Alloc alloc, in LowType a) =>
	a.matchIn!Repr(
		(in LowType.Extern it) =>
			reprRecord!"extern"(alloc, [reprNat(it.index)]),
		(in LowType.FunPtr it) =>
			reprRecord!"fun-pointer"(alloc, [reprNat(it.index)]),
		(in PrimitiveType it) =>
			reprSym(symOfPrimitiveType(it)),
		(in LowType.PtrGc it) =>
			reprRecord!"gc-ptr"(alloc, [reprOfLowType(alloc, *it.pointee)]),
		(in LowType.PtrRawConst it) =>
			reprRecord!"ptr-const"(alloc, [reprOfLowType(alloc, *it.pointee)]),
		(in LowType.PtrRawMut it) =>
			reprRecord!"ptr-mut"(alloc, [reprOfLowType(alloc, *it.pointee)]),
		(in LowType.Record it) =>
			reprRecord!"record"(alloc, [reprNat(it.index)]),
		(in LowType.Union it) =>
			reprRecord!"union"(alloc, [reprNat(it.index)]));

Repr reprOfExternType(ref Alloc alloc, in LowExternType a) =>
	reprRecord!"extern"(alloc, [
		reprOfConcreteStructRef(alloc, *a.source)]);

Repr reprOfLowFunPtrType(ref Alloc alloc, in LowFunPtrType a) =>
	reprRecord!"fun-pointer"(alloc, [
		reprOfConcreteStructRef(alloc, *a.source),
		reprOfLowType(alloc, a.returnType),
		reprArr!LowType(alloc, a.paramTypes, (in LowType it) =>
			reprOfLowType(alloc, it))]);

Repr reprOfLowRecord(ref Alloc alloc, in LowRecord a) =>
	reprRecord!"record"(alloc, [
		reprOfConcreteStructRef(alloc, *a.source),
		reprArr!LowField(alloc, a.fields, (in LowField field) =>
			reprRecord!"field"(alloc, [reprSym(debugName(field)), reprOfLowType(alloc, field.type)]))]);

Repr reprOfLowUnion(ref Alloc alloc, in LowUnion a) =>
	reprRecord!"union"(alloc, [
		reprOfConcreteStructRef(alloc, *a.source),
		reprArr!LowType(alloc, a.members, (in LowType it) =>
			reprOfLowType(alloc, it))]);

Repr reprOfLowFun(ref Alloc alloc, in LowFun a) =>
	reprRecord!"fun"(alloc, [
		reprOfLowFunSource(alloc, a.source),
		reprOfLowType(alloc, a.returnType),
		reprArr!LowLocal(alloc, a.params, (in LowLocal x) =>
			reprOfLowLocal(alloc, x)),
		reprOfLowFunBody(alloc, a.body_)]);

Repr reprOfLowFunSource(ref Alloc alloc, in LowFunSource a) =>
	a.matchIn!Repr(
		(in ConcreteFun x) =>
			reprOfConcreteFunRef(alloc, x),
		(in LowFunSource.Generated x) =>
			reprRecord!"generated"(alloc, [reprSym(x.name)]));

Repr reprOfLowFunBody(ref Alloc alloc, in LowFunBody a) =>
	a.matchIn!Repr(
		(in LowFunBody.Extern) =>
			reprSym!"extern",
		(in LowFunExprBody x) =>
			reprRecord!"expr-body"(alloc, [reprOfLowExpr(alloc, x.expr)]));

Repr reprOfLowLocal(ref Alloc alloc, in LowLocal a) =>
	reprRecord!"local"(alloc, [
		reprOfLowLocalSource(alloc, a.source),
		reprOfLowType(alloc, a.type)]);

Repr reprOfLowLocalSource(ref Alloc alloc, in LowLocalSource a) =>
	a.matchIn!Repr(
		(in Local it) =>
			reprSym(it.name),
		(in LowLocalSource.Generated it) =>
			reprRecord!"generated"(alloc, [reprSym(it.name), reprNat(it.index)]));

Repr reprOfLowExpr(ref Alloc alloc, in LowExpr a) =>
	reprRecord!"expr"(alloc, [
		reprOfLowType(alloc, a.type),
		reprFileAndRange(alloc, a.source),
		reprOfLowExprKind(alloc, a.kind)]);

Repr reprOfLowExprs(ref Alloc alloc, in LowExpr[] a) =>
	reprArr!LowExpr(alloc, a, (in LowExpr x) =>
		reprOfLowExpr(alloc, x));

Repr reprOfLowExprKind(ref Alloc alloc, in LowExprKind a) =>
	a.matchIn!Repr(
		(in LowExprKind.Call it) =>
			reprRecord!"call"(alloc, [
				reprNat(it.called.index),
				reprOfLowExprs(alloc, it.args)]),
		(in LowExprKind.CallFunPtr it) =>
			reprRecord!"call-fun-pointer"(alloc, [
				reprOfLowExpr(alloc, it.funPtr),
				reprOfLowExprs(alloc, it.args)]),
		(in LowExprKind.CreateRecord it) =>
			reprRecord!"record"(alloc, [reprOfLowExprs(alloc, it.args)]),
		(in LowExprKind.CreateUnion it) =>
			reprRecord!"to-union"(alloc, [reprNat(it.memberIndex), reprOfLowExpr(alloc, it.arg)]),
		(in LowExprKind.If it) =>
			reprRecord!"if"(alloc, [
				reprOfLowExpr(alloc, it.cond),
				reprOfLowExpr(alloc, it.then),
				reprOfLowExpr(alloc, it.else_)]),
		(in LowExprKind.InitConstants) =>
			reprSym!"init-const" ,
		(in LowExprKind.Let it) =>
			reprRecord!"let"(alloc, [
				reprOfLowLocal(alloc, *it.local),
				reprOfLowExpr(alloc, it.value),
				reprOfLowExpr(alloc, it.then)]),
		(in LowExprKind.LocalGet it) =>
			reprRecord!"local-get"(alloc, [reprOfLowLocalSource(alloc, it.local.source)]),
		(in LowExprKind.LocalSet it) =>
			reprRecord!"local-set"(alloc, [
				reprOfLowLocalSource(alloc, it.local.source),
				reprOfLowExpr(alloc, it.value)]),
		(in LowExprKind.Loop it) =>
			reprRecord!"loop"(alloc, [reprOfLowExpr(alloc, it.body_)]),
		(in LowExprKind.LoopBreak it) =>
			reprRecord!"break"(alloc, [reprOfLowExpr(alloc, it.value)]),
		(in LowExprKind.LoopContinue) =>
			reprSym!"continue" ,
		(in LowExprKind.MatchUnion it) =>
			reprOfMatchUnion(alloc, it),
		(in LowExprKind.PtrCast it) =>
			reprRecord!"ptr-cast"(alloc, [reprOfLowExpr(alloc, it.target)]),
		(in LowExprKind.PtrToField it) =>
			reprRecord!"ptr-to-field"(alloc, [
				reprOfLowExpr(alloc, it.target),
				reprNat(it.fieldIndex)]),
		(in LowExprKind.PtrToLocal it) =>
			reprRecord!"ptr-to-local"(alloc, [reprOfLowLocalSource(alloc, it.local.source)]),
		(in LowExprKind.RecordFieldGet it) =>
			reprRecord!"get-field"(alloc, [
				reprOfLowExpr(alloc, it.target),
				reprNat(it.fieldIndex)]),
		(in LowExprKind.RecordFieldSet it) =>
			reprRecord!"set-field"(alloc, [
				reprOfLowExpr(alloc, it.target),
				reprNat(it.fieldIndex),
				reprOfLowExpr(alloc, it.value)]),
		(in LowExprKind.Seq it) =>
			reprRecord!"seq"(alloc, [
				reprOfLowExpr(alloc, it.first),
				reprOfLowExpr(alloc, it.then)]),
		(in LowExprKind.SizeOf it) =>
			reprRecord!"size-of"(alloc, [reprOfLowType(alloc, it.type)]),
		(in Constant it) =>
			reprOfConstant(alloc, it),
		(in LowExprKind.SpecialUnary it) =>
			reprRecord!"unary"(alloc, [
				reprStr(strOfSpecialUnaryKind(it.kind)),
				reprOfLowExpr(alloc, it.arg)]),
		(in LowExprKind.SpecialBinary it) =>
			reprRecord!"binary"(alloc, [
				reprStr(strOfSpecialBinaryKind(it.kind)),
				reprOfLowExpr(alloc, it.left),
				reprOfLowExpr(alloc, it.right)]),
		(in LowExprKind.SpecialTernary it) =>
			reprRecord!"ternary"(alloc, [
				reprStr(strOfSpecialTernaryKind(it.kind)),
				reprOfLowExpr(alloc, it.args[0]),
				reprOfLowExpr(alloc, it.args[1]),
				reprOfLowExpr(alloc, it.args[2])]),
		(in LowExprKind.Switch0ToN it) =>
			reprRecord!"switch-n"(alloc, [
				reprOfLowExpr(alloc, it.value),
				reprOfLowExprs(alloc, it.cases)]),
		(in LowExprKind.SwitchWithValues it) =>
			reprRecord!"switch-v"(alloc, [
				reprOfLowExpr(alloc, it.value),
				reprArr!EnumValue(alloc, it.values, (in EnumValue value) =>
					reprInt(value.value)),
				reprOfLowExprs(alloc, it.cases)]),
		(in LowExprKind.TailRecur it) =>
			reprRecord!"tail-recur"(alloc, [
				reprArr!UpdateParam(alloc, it.updateParams, (in UpdateParam updateParam) =>
					reprRecord!"update"(alloc, [
						reprOfLowLocalSource(alloc, updateParam.param.source),
						reprOfLowExpr(alloc, updateParam.newValue),
					]))]),
		(in LowExprKind.VarGet x) =>
			reprRecord!"var-get"(alloc, [reprNat(x.varIndex.index)]),
		(in LowExprKind.VarSet x) =>
			reprRecord!"var-set"(alloc, [
				reprNat(x.varIndex.index),
				reprOfLowExpr(alloc, *x.value)]));

Repr reprOfMatchUnion(ref Alloc alloc, in LowExprKind.MatchUnion a) =>
	reprRecord!"match"(alloc, [
		reprOfLowExpr(alloc, a.matchedValue),
		reprArr!(LowExprKind.MatchUnion.Case)(alloc, a.cases, (in LowExprKind.MatchUnion.Case case_) =>
			reprRecord!"case"(alloc, [
				reprOpt!(LowLocal*)(alloc, case_.local, (in LowLocal* it) =>
					reprOfLowLocalSource(alloc, it.source)),
				reprOfLowExpr(alloc, case_.then)]))]);

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
