module model.reprLowModel;

@safe @nogc pure nothrow:

import model.concreteModel : ConcreteFun, ConcreteLocal, ConcreteParam;
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
	LowFunPtrType,
	LowFunSource,
	LowLocal,
	LowLocalSource,
	LowParam,
	LowParamSource,
	LowProgram,
	LowRecord,
	LowType,
	LowUnion,
	matchLowExprKind,
	matchLowFunBody,
	matchLowFunSource,
	matchLowLocalSource,
	matchLowParamSource,
	matchLowType,
	PrimitiveType,
	symOfPrimitiveType,
	UpdateParam;
import model.model : EnumValue;
import model.reprConcreteModel :
	reprOfConcreteFunRef,
	reprOfConcreteLocalGet,
	reprOfConcreteParamGet,
	reprOfConcreteStructRef;
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

immutable(Repr) reprOfLowProgram(ref Alloc alloc, ref immutable LowProgram a) =>
	reprNamedRecord!"program"(alloc, [
		nameAndRepr!"extern"(
			reprFullIndexDict(alloc, a.allExternTypes, (ref immutable LowExternType it) =>
				reprOfExternType(alloc, it))),
		nameAndRepr!"fun-pointers"(reprFullIndexDict(alloc, a.allFunPtrTypes, (ref immutable LowFunPtrType it) =>
			reprOfLowFunPtrType(alloc, it))),
		nameAndRepr!"records"(reprFullIndexDict(alloc, a.allRecords, (ref immutable LowRecord it) =>
			reprOfLowRecord(alloc, it))),
		nameAndRepr!"unions"(reprFullIndexDict(alloc, a.allUnions, (ref immutable LowUnion it) =>
			reprOfLowUnion(alloc, it))),
		nameAndRepr!"funs"(reprFullIndexDict(alloc, a.allFuns, (ref immutable LowFun it) =>
			reprOfLowFun(alloc, it))),
		nameAndRepr!"main"(reprNat(a.main.index))]);

private:

immutable(Repr) reprOfLowType(ref Alloc alloc, immutable LowType a) =>
	matchLowType!(
		immutable Repr,
		(immutable LowType.Extern it) =>
			reprRecord!"extern"(alloc, [reprNat(it.index)]),
		(immutable LowType.FunPtr it) =>
			reprRecord!"fun-pointer"(alloc, [reprNat(it.index)]),
		(immutable PrimitiveType it) =>
			reprSym(symOfPrimitiveType(it)),
		(immutable LowType.PtrGc it) =>
			reprRecord!"gc-ptr"(alloc, [reprOfLowType(alloc, *it.pointee)]),
		(immutable LowType.PtrRawConst it) =>
			reprRecord!"ptr-const"(alloc, [reprOfLowType(alloc, *it.pointee)]),
		(immutable LowType.PtrRawMut it) =>
			reprRecord!"ptr-mut"(alloc, [reprOfLowType(alloc, *it.pointee)]),
		(immutable LowType.Record it) =>
			reprRecord!"record"(alloc, [reprNat(it.index)]),
		(immutable LowType.Union it) =>
			reprRecord!"union"(alloc, [reprNat(it.index)]),
	)(a);

immutable(Repr) reprOfExternType(ref Alloc alloc, ref immutable LowExternType a) =>
	reprRecord!"extern"(alloc, [
		reprOfConcreteStructRef(alloc, *a.source)]);

immutable(Repr) reprOfLowFunPtrType(ref Alloc alloc, ref immutable LowFunPtrType a) =>
	reprRecord!"fun-pointer"(alloc, [
		reprOfConcreteStructRef(alloc, *a.source),
		reprOfLowType(alloc, a.returnType),
		reprArr(alloc, a.paramTypes, (ref immutable LowType it) =>
			reprOfLowType(alloc, it))]);

immutable(Repr) reprOfLowRecord(ref Alloc alloc, ref immutable LowRecord a) =>
	reprRecord!"record"(alloc, [
		reprOfConcreteStructRef(alloc, *a.source),
		reprArr(alloc, a.fields, (ref immutable LowField field) =>
			reprRecord!"field"(alloc, [reprSym(debugName(field)), reprOfLowType(alloc, field.type)]))]);

immutable(Repr) reprOfLowUnion(ref Alloc alloc, ref immutable LowUnion a) =>
	reprRecord!"union"(alloc, [
		reprOfConcreteStructRef(alloc, *a.source),
		reprArr(alloc, a.members, (ref immutable LowType it) =>
			reprOfLowType(alloc, it))]);

immutable(Repr) reprOfLowFun(ref Alloc alloc, ref immutable LowFun a) =>
	reprRecord!"fun"(alloc, [
		reprOfLowFunSource(alloc, a.source),
		reprOfLowType(alloc, a.returnType),
		reprArr(alloc, a.params, (ref immutable LowParam it) =>
			reprRecord!"param"(alloc, [reprOfLowParamSource(it.source), reprOfLowType(alloc, it.type)])),
		reprOfLowFunBody(alloc, a.body_)]);

immutable(Repr) reprOfLowFunSource(ref Alloc alloc, ref immutable LowFunSource a) =>
	matchLowFunSource!(
		immutable Repr,
		(immutable ConcreteFun* it) =>
			reprOfConcreteFunRef(alloc, *it),
		(ref immutable LowFunSource.Generated it) =>
			reprRecord!"generated"(alloc, [reprSym(it.name)]),
	)(a);

immutable(Repr) reprOfLowParamSource(ref immutable LowParamSource a) =>
	matchLowParamSource!(
		immutable Repr,
		(ref immutable ConcreteParam it) =>
			reprOfConcreteParamGet(it),
		(ref immutable LowParamSource.Generated it) =>
			reprSym(it.name),
	)(a);

immutable(Repr) reprOfLowFunBody(ref Alloc alloc, ref immutable LowFunBody a) =>
	matchLowFunBody!(
		immutable Repr,
		(ref immutable LowFunBody.Extern it) =>
			reprSym!"extern" ,
		(ref immutable LowFunExprBody it) =>
			reprRecord!"expr-body"(alloc, [reprOfLowExpr(alloc, it.expr)]),
	)(a);

immutable(Repr) reprOfLowLocalSource(ref Alloc alloc, ref immutable LowLocalSource a) =>
	matchLowLocalSource!(
		immutable Repr,
		(ref immutable ConcreteLocal it) =>
			reprOfConcreteLocalGet(it),
		(ref immutable LowLocalSource.Generated it) =>
			reprRecord!"generated"(alloc, [reprSym(it.name), reprNat(it.index)]),
	)(a);

immutable(Repr) reprOfLowExpr(ref Alloc alloc, ref immutable LowExpr a) =>
	reprRecord!"expr"(alloc, [
		reprOfLowType(alloc, a.type),
		reprFileAndRange(alloc, a.source),
		reprOfLowExprKind(alloc, a.kind)]);

immutable(Repr) reprOfLowExprKind(ref Alloc alloc, ref immutable LowExprKind a) =>
	matchLowExprKind!(
		immutable Repr,
		(ref immutable LowExprKind.Call it) =>
			reprRecord!"call"(alloc, [
				reprNat(it.called.index),
				reprArr(alloc, it.args, (ref immutable LowExpr e) =>
					reprOfLowExpr(alloc, e))]),
		(ref immutable LowExprKind.CallFunPtr it) =>
			reprRecord!"call-fun-pointer"(alloc, [
				reprOfLowExpr(alloc, it.funPtr),
				reprArr(alloc, it.args, (ref immutable LowExpr arg) =>
					reprOfLowExpr(alloc, arg))]),
		(ref immutable LowExprKind.CreateRecord it) =>
			reprRecord!"record"(alloc, [
				reprArr(alloc, it.args, (ref immutable LowExpr e) =>
					reprOfLowExpr(alloc, e))]),
		(ref immutable LowExprKind.CreateUnion it) =>
			reprRecord!"to-union"(alloc, [reprNat(it.memberIndex), reprOfLowExpr(alloc, it.arg)]),
		(ref immutable LowExprKind.If it) =>
			reprRecord!"if"(alloc, [
				reprOfLowExpr(alloc, it.cond),
				reprOfLowExpr(alloc, it.then),
				reprOfLowExpr(alloc, it.else_)]),
		(ref immutable LowExprKind.InitConstants) =>
			reprSym!"init-const" ,
		(ref immutable LowExprKind.Let it) =>
			reprRecord!"let"(alloc, [
				reprOfLowLocalSource(alloc, it.local.source),
				reprOfLowExpr(alloc, it.value),
				reprOfLowExpr(alloc, it.then)]),
		(ref immutable LowExprKind.LocalGet it) =>
			reprRecord!"local-get"(alloc, [reprOfLowLocalSource(alloc, it.local.source)]),
		(ref immutable LowExprKind.LocalSet it) =>
			reprRecord!"local-set"(alloc, [
				reprOfLowLocalSource(alloc, it.local.source),
				reprOfLowExpr(alloc, it.value)]),
		(ref immutable LowExprKind.Loop it) =>
			reprRecord!"loop"(alloc, [reprOfLowExpr(alloc, it.body_)]),
		(ref immutable LowExprKind.LoopBreak it) =>
			reprRecord!"break"(alloc, [reprOfLowExpr(alloc, it.value)]),
		(ref immutable LowExprKind.LoopContinue) =>
			reprSym!"continue" ,
		(ref immutable LowExprKind.MatchUnion it) =>
			reprOfMatchUnion(alloc, it),
		(ref immutable LowExprKind.ParamGet it) =>
			reprRecord!"param-get"(alloc, [reprNat(it.index.index)]),
		(ref immutable LowExprKind.PtrCast it) =>
			reprRecord!"ptr-cast"(alloc, [reprOfLowExpr(alloc, it.target)]),
		(ref immutable LowExprKind.PtrToField it) =>
			reprRecord!"ptr-to-field"(alloc, [
				reprOfLowExpr(alloc, it.target),
				reprNat(it.fieldIndex)]),
		(ref immutable LowExprKind.PtrToLocal it) =>
			reprRecord!"ptr-to-local"(alloc, [reprOfLowLocalSource(alloc, it.local.source)]),
		(ref immutable LowExprKind.PtrToParam it) =>
			reprRecord!"ptr-to-param"(alloc, [reprNat(it.index.index)]),
		(ref immutable LowExprKind.RecordFieldGet it) =>
			reprRecord!"get-field"(alloc, [
				reprOfLowExpr(alloc, it.target),
				reprNat(it.fieldIndex)]),
		(ref immutable LowExprKind.RecordFieldSet it) =>
			reprRecord!"set-field"(alloc, [
				reprOfLowExpr(alloc, it.target),
				reprNat(it.fieldIndex),
				reprOfLowExpr(alloc, it.value)]),
		(ref immutable LowExprKind.Seq it) =>
			reprRecord!"seq"(alloc, [
				reprOfLowExpr(alloc, it.first),
				reprOfLowExpr(alloc, it.then)]),
		(ref immutable LowExprKind.SizeOf it) =>
			reprRecord!"size-of"(alloc, [reprOfLowType(alloc, it.type)]),
		(ref immutable Constant it) =>
			reprOfConstant(alloc, it),
		(ref immutable LowExprKind.SpecialUnary it) =>
			reprRecord!"unary"(alloc, [
				reprStr(strOfSpecialUnaryKind(it.kind)),
				reprOfLowExpr(alloc, it.arg)]),
		(ref immutable LowExprKind.SpecialBinary it) =>
			reprRecord!"binary"(alloc, [
				reprStr(strOfSpecialBinaryKind(it.kind)),
				reprOfLowExpr(alloc, it.left),
				reprOfLowExpr(alloc, it.right)]),
		(ref immutable LowExprKind.SpecialTernary it) =>
			reprRecord!"ternary"(alloc, [
				reprStr(strOfSpecialTernaryKind(it.kind)),
				reprOfLowExpr(alloc, it.args[0]),
				reprOfLowExpr(alloc, it.args[1]),
				reprOfLowExpr(alloc, it.args[2])]),
		(ref immutable LowExprKind.Switch0ToN it) =>
			reprRecord!"switch-n"(alloc, [
				reprOfLowExpr(alloc, it.value),
				reprArr(alloc, it.cases, (ref immutable LowExpr arg) =>
					reprOfLowExpr(alloc, arg))]),
		(ref immutable LowExprKind.SwitchWithValues it) =>
			reprRecord!"switch-v"(alloc, [
				reprOfLowExpr(alloc, it.value),
				reprArr(alloc, it.values, (ref immutable EnumValue value) =>
					reprInt(value.value)),
				reprArr(alloc, it.cases, (ref immutable LowExpr case_) =>
					reprOfLowExpr(alloc, case_))]),
		(ref immutable LowExprKind.TailRecur it) =>
			reprRecord!"tail-recur"(alloc, [
				reprArr(alloc, it.updateParams, (ref immutable UpdateParam updateParam) =>
					reprRecord!"update"(alloc, [
						reprNat(updateParam.param.index),
						reprOfLowExpr(alloc, updateParam.newValue),
					]))]),
		(ref immutable LowExprKind.ThreadLocalPtr it) =>
			reprRecord!"thread-local"(alloc, [
				reprNat(it.threadLocalIndex.index)]),
		(ref immutable LowExprKind.Zeroed) =>
			reprSym!"uninit" ,
	)(a);

immutable(Repr) reprOfMatchUnion(ref Alloc alloc, ref immutable LowExprKind.MatchUnion a) =>
	reprRecord!"match"(alloc, [
		reprOfLowExpr(alloc, a.matchedValue),
		reprArr(alloc, a.cases, (ref immutable LowExprKind.MatchUnion.Case case_) =>
			reprRecord!"case"(alloc, [
				reprOpt!(LowLocal*)(alloc, case_.local, (ref immutable LowLocal* it) =>
					reprOfLowLocalSource(alloc, it.source)),
				reprOfLowExpr(alloc, case_.then)]))]);

immutable(string) strOfSpecialUnaryKind(immutable LowExprKind.SpecialUnary.Kind a) {
	final switch (a) {
		case LowExprKind.SpecialUnary.Kind.asAnyPtr:
			return "as-any-ptr";
		case LowExprKind.SpecialUnary.Kind.asRef:
			return "as-ref";
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
			return "to-char8 (from nat8)";
		case LowExprKind.SpecialUnary.Kind.toFloat32FromFloat64:
			return "to-float32 (from float64)";
		case LowExprKind.SpecialUnary.Kind.toFloat64FromFloat32:
			return "to-float64 (from float32)";
		case LowExprKind.SpecialUnary.Kind.toFloat64FromInt64:
			return "to-float64 (from int64)";
		case LowExprKind.SpecialUnary.Kind.toFloat64FromNat64:
			return "to-float64 (from nat64)";
		case LowExprKind.SpecialUnary.Kind.toInt64FromInt16:
			return "to-int (from int16)";
		case LowExprKind.SpecialUnary.Kind.toInt64FromInt32:
			return "to-int (from int32)";
		case LowExprKind.SpecialUnary.Kind.toNat8FromChar8:
			return "to-nat8 (from char8)";
		case LowExprKind.SpecialUnary.Kind.toNat64FromNat8:
			return "to-nat (from nat8)";
		case LowExprKind.SpecialUnary.Kind.toNat64FromNat16:
			return "to-nat (from nat16)";
		case LowExprKind.SpecialUnary.Kind.toNat64FromNat32:
			return "to-nat (from nat32)";
		case LowExprKind.SpecialUnary.Kind.toNat64FromPtr:
			return "to-nat (from ptr)";
		case LowExprKind.SpecialUnary.Kind.toPtrFromNat64:
			return "to-ptr (from nat64)";
		case LowExprKind.SpecialUnary.Kind.truncateToInt64FromFloat64:
			return "truncate-to-int (from float64)";
		case LowExprKind.SpecialUnary.Kind.unsafeInt32ToNat32:
			return "unsafe-int32-to-nat32";
		case LowExprKind.SpecialUnary.Kind.unsafeInt64ToInt8:
			return "unsafe-int64-to-int8";
		case LowExprKind.SpecialUnary.Kind.unsafeInt64ToInt16:
			return "unsafe-int64-to-int16";
		case LowExprKind.SpecialUnary.Kind.unsafeInt64ToInt32:
			return "unsafe-int64-to-int32";
		case LowExprKind.SpecialUnary.Kind.unsafeInt64ToNat64:
			return "unsafe-int64-to-nat64";
		case LowExprKind.SpecialUnary.Kind.unsafeNat64ToInt64:
			return "unsafe-nat64-to-int64";
		case LowExprKind.SpecialUnary.Kind.unsafeNat64ToNat8:
			return "unsafe-nat64-to-nat8";
		case LowExprKind.SpecialUnary.Kind.unsafeNat64ToNat16:
			return "unsafe-nat64-to-nat16";
		case LowExprKind.SpecialUnary.Kind.unsafeNat64ToNat32:
			return "unsafe-nat64-to-nat32";
	}
}

immutable(string) strOfSpecialBinaryKind(immutable LowExprKind.SpecialBinary.Kind a) {
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

immutable(string) strOfSpecialTernaryKind(immutable LowExprKind.SpecialTernary.Kind a) {
	final switch (a) {
		case LowExprKind.SpecialTernary.Kind.interpreterBacktrace:
			return "interpreter-backtrace";
	}
}
