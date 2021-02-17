module model.reprLowModel;

@safe @nogc pure nothrow:

import model.concreteModel : ConcreteFun, ConcreteLocal, ConcreteParam;
import model.constant : Constant;
import model.lowModel :
	LowExpr,
	LowExprKind,
	LowExternPtrType,
	LowField,
	LowFun,
	LowFunBody,
	LowFunExprBody,
	LowFunParamsKind,
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
	name,
	PrimitiveType,
	symOfPrimitiveType;
import model.reprConcreteModel :
	reprOfConcreteFunRef,
	reprOfConcreteLocalRef,
	reprOfConcreteParamRef,
	reprOfConcreteStructRef;
import model.reprConstant : reprOfConstant;
import util.collection.arr : size;
import util.ptr : Ptr;
import util.repr :
	nameAndRepr,
	Repr,
	reprArr,
	reprBool,
	reprFullIndexDict,
	reprNamedRecord,
	reprNat,
	reprOpt,
	reprRecord,
	reprStr,
	reprSym;
import util.sourceRange : reprFileAndRange;

immutable(Repr) reprOfLowProgram(Alloc)(ref Alloc alloc, ref immutable LowProgram a) {
	return reprNamedRecord(alloc, "program", [
		nameAndRepr("extern-ptrs", reprFullIndexDict(alloc, a.allExternPtrTypes, (ref immutable LowExternPtrType it) =>
			reprOfExternPtrType(alloc, it))),
		nameAndRepr("fun-ptrs", reprFullIndexDict(alloc, a.allFunPtrTypes, (ref immutable LowFunPtrType it) =>
			reprOfLowFunPtrType(alloc, it))),
		nameAndRepr("records", reprFullIndexDict(alloc, a.allRecords, (ref immutable LowRecord it) =>
			reprOfLowRecord(alloc, it))),
		nameAndRepr("unions", reprFullIndexDict(alloc, a.allUnions, (ref immutable LowUnion it) =>
			reprOfLowUnion(alloc, it))),
		nameAndRepr("funs", reprFullIndexDict(alloc, a.allFuns, (ref immutable LowFun it) =>
			reprOfLowFun(alloc, it))),
		nameAndRepr("main", reprNat(a.main.index))]);
}

private:

immutable(Repr) reprOfLowType(Alloc)(ref Alloc alloc, ref immutable LowType a) {
	return matchLowType!(immutable Repr)(
		a,
		(immutable LowType.ExternPtr it) =>
			reprRecord(alloc, "extern-ptr", [reprNat(it.index)]),
		(immutable LowType.FunPtr it) =>
			reprRecord(alloc, "fun-ptr", [reprNat(it.index)]),
		(immutable PrimitiveType it) =>
			reprSym(symOfPrimitiveType(it)),
		(immutable LowType.PtrGc it) =>
			reprRecord(alloc, "gc-ptr", [reprOfLowType(alloc, it.pointee)]),
		(immutable LowType.PtrRaw it) =>
			reprRecord(alloc, "raw-ptr", [reprOfLowType(alloc, it.pointee)]),
		(immutable LowType.Record it) =>
			reprRecord(alloc, "record", [reprNat(it.index)]),
		(immutable LowType.Union it) =>
			reprRecord(alloc, "union", [reprNat(it.index)]));
}

immutable(Repr) reprOfExternPtrType(Alloc)(ref Alloc alloc, ref immutable LowExternPtrType a) {
	return reprRecord(alloc, "extern-ptr", [
		reprOfConcreteStructRef(alloc, a.source)]);
}

immutable(Repr) reprOfLowFunPtrType(Alloc)(ref Alloc alloc, ref immutable LowFunPtrType a) {
	return reprRecord(alloc, "fun-ptr", [
		reprOfConcreteStructRef(alloc, a.source),
		reprOfLowType(alloc, a.returnType),
		reprArr(alloc, a.paramTypes, (ref immutable LowType it) =>
			reprOfLowType(alloc, it))]);
}

immutable(Repr) reprOfLowRecord(Alloc)(ref Alloc alloc, ref immutable LowRecord a) {
	return reprRecord(alloc, "record", [
		reprOfConcreteStructRef(alloc, a.source),
		reprArr(alloc, a.fields, (ref immutable LowField field) =>
			reprRecord(alloc, "field", [reprSym(name(field)), reprOfLowType(alloc, field.type)]))]);
}

immutable(Repr) reprOfLowUnion(Alloc)(ref Alloc alloc, ref immutable LowUnion a){
	return reprRecord(alloc, "union", [
		reprOfConcreteStructRef(alloc, a.source),
		reprArr(alloc, a.members, (ref immutable LowType it) =>
			reprOfLowType(alloc, it))]);
}

immutable(Repr) reprOfLowFun(Alloc)(ref Alloc alloc, ref immutable LowFun a) {
	return reprRecord(alloc, "fun", [
		reprOfLowFunSource(alloc, a.source),
		reprOfLowType(alloc, a.returnType),
		reprOfLowFunParamsKind(alloc, a.paramsKind),
		reprArr(alloc, a.params, (ref immutable LowParam it) =>
			reprRecord(alloc, "param", [reprOfLowParamSource(it.source), reprOfLowType(alloc, it.type)])),
		reprOfLowFunBody(alloc, a.body_)]);
}

immutable(Repr) reprOfLowFunParamsKind(Alloc)(ref Alloc alloc, ref immutable LowFunParamsKind a) {
	return reprNamedRecord(alloc, "param-kind", [
		nameAndRepr("ctx", reprBool(a.hasCtx)),
		nameAndRepr("closure", reprBool(a.hasClosure))]);
}

immutable(Repr) reprOfLowFunSource(Alloc)(ref Alloc alloc, ref immutable LowFunSource a) {
	return matchLowFunSource(
		a,
		(immutable Ptr!ConcreteFun it) =>
			reprOfConcreteFunRef(alloc, it),
		(ref immutable LowFunSource.Generated it) =>
			reprRecord(alloc, "generated", [reprSym(it.name)]));
}

immutable(Repr) reprOfLowParamSource(ref immutable LowParamSource a) {
	return matchLowParamSource!(immutable Repr)(
		a,
		(immutable Ptr!ConcreteParam it) =>
			reprOfConcreteParamRef(it),
		(ref immutable LowParamSource.Generated it) =>
			reprSym(it.name));
}

immutable(Repr) reprOfLowFunBody(Alloc)(ref Alloc alloc, ref immutable LowFunBody a) {
	return matchLowFunBody!(immutable Repr)(
		a,
		(ref immutable LowFunBody.Extern it) =>
			reprRecord(alloc, "extern", [reprBool(it.isGlobal)]),
		(ref immutable LowFunExprBody it) =>
			reprRecord(alloc, "expr-body", [reprOfLowExpr(alloc, it.expr)]));
}

immutable(Repr) reprOfLowLocalSource(Alloc)(ref Alloc alloc, ref immutable LowLocalSource a) {
	return matchLowLocalSource!(immutable Repr)(
		a,
		(immutable Ptr!ConcreteLocal it) =>
			reprOfConcreteLocalRef(it),
		(ref immutable LowLocalSource.Generated it) =>
			reprRecord(alloc, "generated", [reprSym(it.name), reprNat(it.index)]));
}

immutable(Repr) reprOfLowExpr(Alloc)(ref Alloc alloc, ref immutable LowExpr a) {
	return reprRecord(alloc, "expr", [
		reprOfLowType(alloc, a.type),
		reprFileAndRange(alloc, a.source),
		reprOfLowExprKind(alloc, a.kind)]);
}

immutable(Repr) reprOfLowExprKind(Alloc)(ref Alloc alloc, ref immutable LowExprKind a) {
	return matchLowExprKind!(immutable Repr)(
		a,
		(ref immutable LowExprKind.Call it) =>
			reprRecord(alloc, "call", [
				reprNat(it.called.index),
				reprArr(alloc, it.args, (ref immutable LowExpr e) =>
					reprOfLowExpr(alloc, e))]),
		(ref immutable LowExprKind.CreateRecord it) =>
			reprRecord(alloc, "record", [
				reprArr(alloc, it.args, (ref immutable LowExpr e) =>
					reprOfLowExpr(alloc, e))]),
		(ref immutable LowExprKind.ConvertToUnion it) =>
			reprRecord(alloc, "to-union", [reprNat(it.memberIndex), reprOfLowExpr(alloc, it.arg)]),
		(ref immutable LowExprKind.FunPtr it) =>
			reprRecord(alloc, "fun-ptr", [reprNat(it.fun.index)]),
		(ref immutable LowExprKind.Let it) =>
			reprRecord(alloc, "let", [
				reprOfLowLocalSource(alloc, it.local.source),
				reprOfLowExpr(alloc, it.value),
				reprOfLowExpr(alloc, it.then)]),
		(ref immutable LowExprKind.LocalRef it) =>
			reprRecord(alloc, "local-ref", [reprOfLowLocalSource(alloc, it.local.source)]),
		(ref immutable LowExprKind.Match it) =>
			reprOfMatch(alloc, it),
		(ref immutable LowExprKind.ParamRef it) =>
			reprRecord(alloc, "param-ref", [reprNat(it.index.index)]),
		(ref immutable LowExprKind.PtrCast it) =>
			reprRecord(alloc, "ptr-cast", [reprOfLowExpr(alloc, it.target)]),
		(ref immutable LowExprKind.RecordFieldGet it) =>
			reprRecord(alloc, "get-field", [
				reprOfLowExpr(alloc, it.target),
				reprBool(it.targetIsPointer),
				reprNat(it.fieldIndex)]),
		(ref immutable LowExprKind.RecordFieldSet it) =>
			reprRecord(alloc, "set-field", [
				reprOfLowExpr(alloc, it.target),
				reprBool(it.targetIsPointer),
				reprNat(it.fieldIndex),
				reprOfLowExpr(alloc, it.value)]),
		(ref immutable LowExprKind.Seq it) =>
			reprRecord(alloc, "seq", [
				reprOfLowExpr(alloc, it.first),
				reprOfLowExpr(alloc, it.then)]),
		(ref immutable LowExprKind.SizeOf it) =>
			reprRecord(alloc, "size-of", [reprOfLowType(alloc, it.type)]),
		(ref immutable Constant it) =>
			reprOfConstant(alloc, it),
		(ref immutable LowExprKind.SpecialUnary it) =>
			reprRecord(alloc, "unary", [
				reprStr(strOfSpecialUnaryKind(it.kind)),
				reprOfLowExpr(alloc, it.arg)]),
		(ref immutable LowExprKind.SpecialBinary it) =>
			reprRecord(alloc, "binary", [
				reprStr(strOfSpecialBinaryKind(it.kind)),
				reprOfLowExpr(alloc, it.left),
				reprOfLowExpr(alloc, it.right)]),
		(ref immutable LowExprKind.SpecialTrinary it) =>
			reprRecord(alloc, "trinary", [
				reprStr(strOfSpecialTrinaryKind(it.kind)),
				reprOfLowExpr(alloc, it.p0),
				reprOfLowExpr(alloc, it.p1),
				reprOfLowExpr(alloc, it.p2)]),
		(ref immutable LowExprKind.SpecialNAry it) =>
			reprRecord(alloc, "n-ary", [
				reprStr(strOfSpecialNAryKind(it.kind)),
				reprArr(alloc, it.args, (ref immutable LowExpr arg) =>
					reprOfLowExpr(alloc, arg))]),
		(ref immutable LowExprKind.Switch it) =>
			reprRecord(alloc, "switch", [
				reprOfLowExpr(alloc, it.value),
				reprArr(alloc, it.cases, (ref immutable LowExpr arg) =>
					reprOfLowExpr(alloc, arg))]),
		(ref immutable LowExprKind.TailRecur it) =>
			reprRecord(alloc, "tail-recur", [
				reprArr(alloc, it.args, (ref immutable LowExpr arg) =>
					reprOfLowExpr(alloc, arg))]),
		(ref immutable LowExprKind.Zeroed) =>
			reprSym("uninit"));
}

immutable(Repr) reprOfMatch(Alloc)(ref Alloc alloc, ref immutable LowExprKind.Match a) {
	return reprRecord(alloc, "match", [
		reprOfLowExpr(alloc, a.matchedValue),
		reprArr(alloc, a.cases, (ref immutable LowExprKind.Match.Case case_) =>
			reprRecord(alloc, "case", [
				reprOpt(alloc, case_.local, (ref immutable Ptr!LowLocal it) =>
					reprOfLowLocalSource(alloc, it.source)),
				reprOfLowExpr(alloc, case_.then)]))]);
}

immutable(string) strOfSpecialUnaryKind(immutable LowExprKind.SpecialUnary.Kind a) {
	final switch (a) {
		case LowExprKind.SpecialUnary.Kind.asAnyPtr:
			return "as-any-ptr";
		case LowExprKind.SpecialUnary.Kind.asRef:
			return "as-ref";
		case LowExprKind.SpecialUnary.Kind.bitsNotNat64:
			return "bits-not (nat-64)";
		case LowExprKind.SpecialUnary.Kind.deref:
			return "deref";
		case LowExprKind.SpecialUnary.Kind.isNan:
			return "nan?";
		case LowExprKind.SpecialUnary.Kind.ptrTo:
			return "ptr-to";
		case LowExprKind.SpecialUnary.Kind.refOfVal:
			return "ref-of-val";
		case LowExprKind.SpecialUnary.Kind.toFloat64FromInt64:
			return "to-float64 (from int-64)";
		case LowExprKind.SpecialUnary.Kind.toFloat64FromNat64:
			return "to-float64 (from nat-64)";
		case LowExprKind.SpecialUnary.Kind.toIntFromInt16:
			return "to-int (from int-16)";
		case LowExprKind.SpecialUnary.Kind.toIntFromInt32:
			return "to-int (from int-32)";
		case LowExprKind.SpecialUnary.Kind.toNatFromChar:
			return "to-nat (from char)";
		case LowExprKind.SpecialUnary.Kind.toNatFromNat8:
			return "to-nat (from nat-8)";
		case LowExprKind.SpecialUnary.Kind.toNatFromNat16:
			return "to-nat (from nat-16)";
		case LowExprKind.SpecialUnary.Kind.toNatFromNat32:
			return "to-nat (from nat-32)";
		case LowExprKind.SpecialUnary.Kind.toNatFromPtr:
			return "to-nat (from ptr)";
		case LowExprKind.SpecialUnary.Kind.truncateToInt64FromFloat64:
			return "truncate-to-int (from float-64)";
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
		case LowExprKind.SpecialBinary.Kind.addFloat64:
			return "+ (float-64)";
		case LowExprKind.SpecialBinary.Kind.addPtr:
			return "+ (ptr)";
		case LowExprKind.SpecialBinary.Kind.and:
			return "and";
		case LowExprKind.SpecialBinary.Kind.bitwiseAndInt8:
			return "bitwise-and (int-8)";
		case LowExprKind.SpecialBinary.Kind.bitwiseAndInt16:
			return "bitwise-and (int-16)";
		case LowExprKind.SpecialBinary.Kind.bitwiseAndInt32:
			return "bitwise-and (int-32)";
		case LowExprKind.SpecialBinary.Kind.bitwiseAndInt64:
			return "bitwise-and (int-64)";
		case LowExprKind.SpecialBinary.Kind.bitwiseAndNat8:
			return "bitwise-and (nat-8)";
		case LowExprKind.SpecialBinary.Kind.bitwiseAndNat16:
			return "bitwise-and (nat-16)";
		case LowExprKind.SpecialBinary.Kind.bitwiseAndNat32:
			return "bitwise-and (nat-32)";
		case LowExprKind.SpecialBinary.Kind.bitwiseAndNat64:
			return "bitwise-and (nat-64)";
		case LowExprKind.SpecialBinary.Kind.bitwiseOrInt8:
			return "bitwise-or (int-8)";
		case LowExprKind.SpecialBinary.Kind.bitwiseOrInt16:
			return "bitwise-or (int-16)";
		case LowExprKind.SpecialBinary.Kind.bitwiseOrInt32:
			return "bitwise-or (int-32)";
		case LowExprKind.SpecialBinary.Kind.bitwiseOrInt64:
			return "bitwise-or (int-64)";
		case LowExprKind.SpecialBinary.Kind.bitwiseOrNat8:
			return "bitwise-or (nat-8)";
		case LowExprKind.SpecialBinary.Kind.bitwiseOrNat16:
			return "bitwise-or (nat-16)";
		case LowExprKind.SpecialBinary.Kind.bitwiseOrNat32:
			return "bitwise-or (nat-32)";
		case LowExprKind.SpecialBinary.Kind.bitwiseOrNat64:
			return "bitwise-or (nat-64)";
		case LowExprKind.SpecialBinary.Kind.eqNat64:
			return "== (nat-64)";
		case LowExprKind.SpecialBinary.Kind.eqPtr:
			return "ptr-eq?";
		case LowExprKind.SpecialBinary.Kind.lessBool:
			return "< (bool)";
		case LowExprKind.SpecialBinary.Kind.lessChar:
			return "< (char)";
		case LowExprKind.SpecialBinary.Kind.lessFloat64:
			return "< (float-64)";
		case LowExprKind.SpecialBinary.Kind.lessInt8:
			return "< (int-8)";
		case LowExprKind.SpecialBinary.Kind.lessInt16:
			return "< (int-16)";
		case LowExprKind.SpecialBinary.Kind.lessInt32:
			return "< (int-32)";
		case LowExprKind.SpecialBinary.Kind.lessInt64:
			return "< (int-64)";
		case LowExprKind.SpecialBinary.Kind.lessNat8:
			return "< (nat-8)";
		case LowExprKind.SpecialBinary.Kind.lessNat16:
			return "< (nat-16)";
		case LowExprKind.SpecialBinary.Kind.lessNat32:
			return "< (nat-32)";
		case LowExprKind.SpecialBinary.Kind.lessNat64:
			return "< (nat-64)";
		case LowExprKind.SpecialBinary.Kind.lessPtr:
			return "< (ptr)";
		case LowExprKind.SpecialBinary.Kind.mulFloat64:
			return "* (float-64)";
		case LowExprKind.SpecialBinary.Kind.or:
			return "or";
		case LowExprKind.SpecialBinary.Kind.subFloat64:
			return "- (float-64)";
		case LowExprKind.SpecialBinary.Kind.subPtrNat:
			return "- (ptr - nat-64)";
		case LowExprKind.SpecialBinary.Kind.unsafeBitShiftLeftNat64:
			return "unsafe-bit-shift-left (nat-64)";
		case LowExprKind.SpecialBinary.Kind.unsafeBitShiftRightNat64:
			return "unsafe-bit-shift-left (nat-64)";
		case LowExprKind.SpecialBinary.Kind.unsafeDivFloat64:
			return "unsafe-div (float-64)";
		case LowExprKind.SpecialBinary.Kind.unsafeDivInt64:
			return "unsafe-div (int-64)";
		case LowExprKind.SpecialBinary.Kind.unsafeDivNat64:
			return "unsafe-div (nat-64)";
		case LowExprKind.SpecialBinary.Kind.unsafeModNat64:
			return "unsafe-mod (nat-64)";
		case LowExprKind.SpecialBinary.Kind.wrapAddInt16:
			return "wrap-add (int-16)";
		case LowExprKind.SpecialBinary.Kind.wrapAddInt32:
			return "wrap-add (int-32)";
		case LowExprKind.SpecialBinary.Kind.wrapAddInt64:
			return "wrap-add (int-64)";
		case LowExprKind.SpecialBinary.Kind.wrapAddNat8:
			return "wrap-add (nat-8)";
		case LowExprKind.SpecialBinary.Kind.wrapAddNat16:
			return "wrap-add (nat-16)";
		case LowExprKind.SpecialBinary.Kind.wrapAddNat32:
			return "wrap-add (nat-32)";
		case LowExprKind.SpecialBinary.Kind.wrapAddNat64:
			return "wrap-add (nat-64)";
		case LowExprKind.SpecialBinary.Kind.wrapMulInt16:
			return "wrap-mul (int-16)";
		case LowExprKind.SpecialBinary.Kind.wrapMulInt32:
			return "wrap-mul (int-32)";
		case LowExprKind.SpecialBinary.Kind.wrapMulInt64:
			return "wrap-mul (int-64)";
		case LowExprKind.SpecialBinary.Kind.wrapMulNat16:
			return "wrap-mul (nat-16)";
		case LowExprKind.SpecialBinary.Kind.wrapMulNat32:
			return "wrap-mul (nat-32)";
		case LowExprKind.SpecialBinary.Kind.wrapMulNat64:
			return "wrap-mul (nat-64)";
		case LowExprKind.SpecialBinary.Kind.wrapSubInt16:
			return "wrap-sub (int-16)";
		case LowExprKind.SpecialBinary.Kind.wrapSubInt32:
			return "wrap-sub (int-32)";
		case LowExprKind.SpecialBinary.Kind.wrapSubInt64:
			return "wrap-sub (int-64)";
		case LowExprKind.SpecialBinary.Kind.wrapSubNat8:
			return "wrap-sub (nat-8)";
		case LowExprKind.SpecialBinary.Kind.wrapSubNat16:
			return "wrap-sub (nat-16)";
		case LowExprKind.SpecialBinary.Kind.wrapSubNat32:
			return "wrap-sub (nat-32)";
		case LowExprKind.SpecialBinary.Kind.wrapSubNat64:
			return "wrap-sub (nat-64)";
		case LowExprKind.SpecialBinary.Kind.writeToPtr:
			return "wriite to ptr";
	}
}

immutable(string) strOfSpecialTrinaryKind(immutable LowExprKind.SpecialTrinary.Kind a) {
	final switch (a) {
		case LowExprKind.SpecialTrinary.Kind.if_:
			return "if";
		case LowExprKind.SpecialTrinary.Kind.compareExchangeStrongBool:
			return "compare-exchange-strong (bool)";
	}
}

immutable(string) strOfSpecialNAryKind(immutable LowExprKind.SpecialNAry.Kind a) {
	final switch (a) {
		case LowExprKind.SpecialNAry.Kind.callFunPtr:
			return "call fun ptr";
	}
}