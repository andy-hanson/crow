module sexprOfLowModel;

@safe @nogc pure nothrow:

import concreteModel : ConcreteFun, ConcreteLocal, ConcreteParam;
import constant : Constant;
import lowModel :
	LowExpr,
	LowExprKind,
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
import sexprOfConcreteModel :
	tataOfConcreteFunRef,
	tataOfConcreteLocalRef,
	tataOfConcreteParamRef,
	tataOfConcreteStructRef;
import sexprOfConstant : tataOfConstant;
import util.collection.arr : size;
import util.collection.arrUtil : arrLiteral;
import util.collection.str : strLiteral;
import util.ptr : Ptr;
import util.sexpr :
	NameAndSexpr,
	nameAndTata,
	Sexpr,
	tataArr,
	tataBool,
	tataFullIndexDict,
	tataNamedRecord,
	tataNat,
	tataOpt,
	tataRecord,
	tataStr,
	tataSym;
import util.sourceRange : sexprOfFileAndRange;

immutable(Sexpr) tataOfLowProgram(Alloc)(ref Alloc alloc, ref immutable LowProgram a) {
	return tataNamedRecord(
		"program",
		arrLiteral!NameAndSexpr(
			alloc,
			nameAndTata("fun-ptrs", tataFullIndexDict(alloc, a.allFunPtrTypes, (ref immutable LowFunPtrType it) =>
				tataOfLowFunPtrType(alloc, it))),
			nameAndTata("records", tataFullIndexDict(alloc, a.allRecords, (ref immutable LowRecord it) =>
				tataOfLowRecord(alloc, it))),
			nameAndTata("unions", tataFullIndexDict(alloc, a.allUnions, (ref immutable LowUnion it) =>
				tataOfLowUnion(alloc, it))),
			nameAndTata("funs", tataFullIndexDict(alloc, a.allFuns, (ref immutable LowFun it) =>
				tataOfLowFun(alloc, it))),
			nameAndTata("main", tataNat(a.main.index))));
}

private:

immutable(Sexpr) tataOfLowType(Alloc)(ref Alloc alloc, ref immutable LowType a) {
	return matchLowType!(immutable Sexpr)(
		a,
		(immutable LowType.ExternPtr it) =>
			tataRecord(alloc, "extern-ptr", tataNat(it.index)),
		(immutable LowType.FunPtr it) =>
			tataRecord(alloc, "fun-ptr", tataNat(it.index)),
		(immutable LowType.NonFunPtr it) =>
			tataRecord(alloc, "ptr", tataOfLowType(alloc, it.pointee)),
		(immutable PrimitiveType it) =>
			tataSym(symOfPrimitiveType(it)),
		(immutable LowType.Record it) =>
			tataRecord(alloc, "record", tataNat(it.index)),
		(immutable LowType.Union it) =>
			tataRecord(alloc, "union", tataNat(it.index)));
}

immutable(Sexpr) tataOfLowFunPtrType(Alloc)(ref Alloc alloc, ref immutable LowFunPtrType a) {
	return tataRecord(
		alloc,
		"fun-ptr",
		tataOfConcreteStructRef(alloc, a.source),
		tataOfLowType(alloc, a.returnType),
		tataArr(alloc, a.paramTypes, (ref immutable LowType it) =>
			tataOfLowType(alloc, it)));
}

immutable(Sexpr) tataOfLowRecord(Alloc)(ref Alloc alloc, ref immutable LowRecord a) {
	return tataRecord(
		alloc,
		"record",
		tataOfConcreteStructRef(alloc, a.source),
		tataArr(alloc, a.fields, (ref immutable LowField field) =>
			tataRecord(alloc, "field", tataSym(name(field)), tataOfLowType(alloc, field.type))));
}

immutable(Sexpr) tataOfLowUnion(Alloc)(ref Alloc alloc, ref immutable LowUnion a){
	return tataRecord(
		alloc,
		"union",
		tataOfConcreteStructRef(alloc, a.source),
		tataArr(alloc, a.members, (ref immutable LowType it) =>
			tataOfLowType(alloc, it)));
}

immutable(Sexpr) tataOfLowFun(Alloc)(ref Alloc alloc, ref immutable LowFun a) {
	return tataRecord(
		alloc,
		"fun",
		tataOfLowFunSource(alloc, a.source),
		tataOfLowType(alloc, a.returnType),
		tataOfLowFunParamsKind(alloc, a.paramsKind),
		tataArr(alloc, a.params, (ref immutable LowParam it) =>
			tataRecord(alloc, "param", tataOfLowParamSource(it.source), tataOfLowType(alloc, it.type))),
		tataOfLowFunBody(alloc, a.body_));
}

immutable(Sexpr) tataOfLowFunParamsKind(Alloc)(ref Alloc alloc, ref immutable LowFunParamsKind a) {
	return tataNamedRecord(
		"param-kind",
		arrLiteral!NameAndSexpr(
			alloc,
			nameAndTata("ctx", tataBool(a.hasCtx)),
			nameAndTata("closure", tataBool(a.hasClosure))));
}

immutable(Sexpr) tataOfLowFunSource(Alloc)(ref Alloc alloc, ref immutable LowFunSource a) {
	return matchLowFunSource(
		a,
		(immutable Ptr!ConcreteFun it) =>
			tataOfConcreteFunRef(alloc, it),
		(ref immutable LowFunSource.Generated it) =>
			tataRecord(
				alloc,
				"generated",
				tataSym(it.name)));
}

immutable(Sexpr) tataOfLowParamSource(ref immutable LowParamSource a) {
	return matchLowParamSource!(immutable Sexpr)(
		a,
		(immutable Ptr!ConcreteParam it) =>
			tataOfConcreteParamRef(it),
		(ref immutable LowParamSource.Generated it) =>
			tataSym(it.name));
}

immutable(Sexpr) tataOfLowFunBody(Alloc)(ref Alloc alloc, ref immutable LowFunBody a) {
	return matchLowFunBody!(immutable Sexpr)(
		a,
		(ref immutable LowFunBody.Extern it) =>
			tataRecord(alloc, "extern", tataBool(it.isGlobal)),
		(ref immutable LowFunExprBody it) =>
			tataRecord(
				alloc,
				"expr-body",
				tataArr(alloc, it.allLocals, (ref immutable Ptr!LowLocal local) =>
					tataRecord(
						alloc,
						"local",
						tataOfLowLocalSource(alloc, local.source),
						tataOfLowType(alloc, local.type))),
				tataOfLowExpr(alloc, it.expr)));
}

immutable(Sexpr) tataOfLowLocalSource(Alloc)(ref Alloc alloc, ref immutable LowLocalSource a) {
	return matchLowLocalSource!(immutable Sexpr)(
		a,
		(immutable Ptr!ConcreteLocal it) =>
			tataOfConcreteLocalRef(it),
		(ref immutable LowLocalSource.Generated it) =>
			tataRecord(alloc, "generated", tataSym(it.name), tataNat(it.index)));
}

immutable(Sexpr) tataOfLowExpr(Alloc)(ref Alloc alloc, ref immutable LowExpr a) {
	return tataRecord(
		alloc,
		"expr",
		tataOfLowType(alloc, a.type),
		sexprOfFileAndRange(alloc, a.source),
		tataOfLowExprKind(alloc, a.kind));
}

immutable(Sexpr) tataOfLowExprKind(Alloc)(ref Alloc alloc, ref immutable LowExprKind a) {
	return matchLowExprKind!(immutable Sexpr)(
		a,
		(ref immutable LowExprKind.Call it) =>
			tataRecord(alloc, "call", tataNat(it.called.index), tataArr(alloc, it.args, (ref immutable LowExpr e) =>
				tataOfLowExpr(alloc, e))),
		(ref immutable LowExprKind.CreateRecord it) =>
			tataRecord(alloc, "record", tataArr(alloc, it.args, (ref immutable LowExpr e) =>
				tataOfLowExpr(alloc, e))),
		(ref immutable LowExprKind.ConvertToUnion it) =>
			tataRecord(alloc, "to-union", tataNat(it.memberIndex), tataOfLowExpr(alloc, it.arg)),
		(ref immutable LowExprKind.FunPtr it) =>
			tataRecord(alloc, "fun-ptr", tataNat(it.fun.index)),
		(ref immutable LowExprKind.Let it) =>
			tataRecord(
				alloc,
				"let",
				tataOfLowLocalSource(alloc, it.local.source),
				tataOfLowExpr(alloc, it.value),
				tataOfLowExpr(alloc, it.then)),
		(ref immutable LowExprKind.LocalRef it) =>
			tataRecord(alloc, "local-ref", tataOfLowLocalSource(alloc, it.local.source)),
		(ref immutable LowExprKind.Match it) =>
			tataOfMatch(alloc, it),
		(ref immutable LowExprKind.ParamRef it) =>
			tataRecord(alloc, "param-ref", tataNat(it.index.index)),
		(ref immutable LowExprKind.PtrCast it) =>
			tataRecord(alloc, "ptr-cast", tataOfLowExpr(alloc, it.target)),
		(ref immutable LowExprKind.RecordFieldAccess it) =>
			tataRecord(
				alloc,
				"get-field",
				tataOfLowExpr(alloc, it.target),
				tataBool(it.targetIsPointer),
				tataNat(it.fieldIndex)),
		(ref immutable LowExprKind.RecordFieldSet it) =>
			tataRecord(
				alloc,
				"set-field",
				tataOfLowExpr(alloc, it.target),
				tataBool(it.targetIsPointer),
				tataNat(it.fieldIndex),
				tataOfLowExpr(alloc, it.value)),
		(ref immutable LowExprKind.Seq it) =>
			tataRecord(
				alloc,
				"seq",
				tataOfLowExpr(alloc, it.first),
				tataOfLowExpr(alloc, it.then)),
		(ref immutable LowExprKind.SizeOf it) =>
			tataRecord(
				alloc,
				"size-of",
				tataOfLowType(alloc, it.type)),
		(ref immutable Constant it) =>
			tataOfConstant(alloc, it),
		(ref immutable LowExprKind.Special0Ary it) =>
			tataRecord(alloc, "zero-ary", tataStr(strLiteral(strOfSpecial0AryKind(it.kind)))),
		(ref immutable LowExprKind.SpecialUnary it) =>
			tataRecord(
				alloc,
				"unary",
				tataStr(strLiteral(strOfSpecialUnaryKind(it.kind))),
				tataOfLowExpr(alloc, it.arg)),
		(ref immutable LowExprKind.SpecialBinary it) =>
			tataRecord(
				alloc,
				"binary",
				tataStr(strLiteral(strOfSpecialBinaryKind(it.kind))),
				tataOfLowExpr(alloc, it.left),
				tataOfLowExpr(alloc, it.right)),
		(ref immutable LowExprKind.SpecialTrinary it) =>
			tataRecord(
				alloc,
				"trinary",
				tataStr(strLiteral(strOfSpecialTrinaryKind(it.kind))),
				tataOfLowExpr(alloc, it.p0),
				tataOfLowExpr(alloc, it.p1),
				tataOfLowExpr(alloc, it.p2)),
		(ref immutable LowExprKind.SpecialNAry it) =>
			tataRecord(
				alloc,
				"n-ary",
				tataStr(strLiteral(strOfSpecialNAryKind(it.kind))),
				tataArr(alloc, it.args, (ref immutable LowExpr arg) =>
					tataOfLowExpr(alloc, arg))),
		(ref immutable LowExprKind.TailRecur it) =>
			tataRecord(
				alloc,
				"tail-recur",
				tataArr(alloc, it.args, (ref immutable LowExpr arg) =>
					tataOfLowExpr(alloc, arg))));
}

immutable(Sexpr) tataOfMatch(Alloc)(ref Alloc alloc, ref immutable LowExprKind.Match a) {
	return tataRecord(
		alloc,
		"match",
		tataOfLowLocalSource(alloc, a.matchedLocal.source),
		tataOfLowExpr(alloc, a.matchedValue),
		tataArr(alloc, a.cases, (ref immutable LowExprKind.Match.Case case_) =>
			tataRecord(
				alloc,
				"case",
				tataOpt(alloc, case_.local, (ref immutable Ptr!LowLocal it) =>
					tataOfLowLocalSource(alloc, it.source)),
				tataOfLowExpr(alloc, case_.then))));
}

immutable(string) strOfSpecial0AryKind(immutable LowExprKind.Special0Ary.Kind a) {
	final switch (a) {
		case LowExprKind.Special0Ary.Kind.getErrno:
			return "get-errno";
	}
}

immutable(string) strOfSpecialUnaryKind(immutable LowExprKind.SpecialUnary.Kind a) {
	final switch (a) {
		case LowExprKind.SpecialUnary.Kind.asAnyPtr:
			return "as-any-ptr";
		case LowExprKind.SpecialUnary.Kind.asRef:
			return "as-ref";
		case LowExprKind.SpecialUnary.Kind.deref:
			return "deref";
		case LowExprKind.SpecialUnary.Kind.hardFail:
			return "hard-fail";
		case LowExprKind.SpecialUnary.Kind.not:
			return "not";
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
