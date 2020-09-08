module sexprOfLowModel;

@safe @nogc pure nothrow:

import lowModel :
	LowExpr,
	LowExprKind,
	LowField,
	LowFun,
	LowFunBody,
	LowFunExprBody,
	LowFunPtrType,
	LowLocal,
	LowParam,
	LowProgram,
	LowRecord,
	LowType,
	LowUnion,
	matchLowExprKind,
	matchLowFunBody,
	matchLowType,
	matchSpecialConstant,
	PrimitiveType;
import util.collection.arr : size;
import util.collection.str : strLiteral;
import util.ptr : Ptr;
import util.sexpr : Sexpr, tataArr, tataBool, tataNat, tataOpt, tataRecord, tataStr, tataSym;
import util.sym : shortSymAlphaLiteral, Sym;
import util.sourceRange : sexprOfSourceRange;
import util.util : todo;

immutable(Sexpr) tataOfLowProgram(Alloc)(ref Alloc alloc, ref immutable LowProgram a) {
	return tataRecord(
		alloc,
		"program",
		tataArr(alloc, a.allFunPtrTypes, (immutable size_t index, ref immutable LowFunPtrType it) =>
			tataOfLowFunPtrType(alloc, index, it)),
		tataArr(alloc, a.allRecords, (immutable size_t index, ref immutable LowRecord it) =>
			tataOfLowRecord(alloc, index, it)),
		tataArr(alloc, a.allUnions, (immutable size_t index, ref immutable LowUnion it) =>
			tataOfLowUnion(alloc, index, it)),
		tataArr(alloc, a.allFuns, (immutable size_t index, ref immutable LowFun it) =>
			tataOfLowFun(alloc, index, it)),
		tataOfLowFun(alloc, size(a.allFuns), a.main));
}

private:

immutable(Sexpr) tataOfLowFunPtrType(Alloc)(ref Alloc alloc, immutable size_t index, ref immutable LowFunPtrType a) {
	return tataRecord(
		alloc,
		"fun-ptr",
		tataNat(index),
		tataStr(a.mangledName),
		tataOfLowType(alloc, a.returnType),
		tataArr(alloc, a.paramTypes, (ref immutable LowType it) =>
			tataOfLowType(alloc, it)));
}

immutable(Sexpr) tataOfLowType(Alloc)(ref Alloc alloc, ref immutable LowType a) {
	return matchLowType!(immutable Sexpr)(
		a,
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

immutable(Sexpr) tataOfLowRecord(Alloc)(ref Alloc alloc, immutable size_t index, ref immutable LowRecord a) {
	return tataRecord(
		alloc,
		"record",
		tataNat(index),
		tataStr(a.mangledName),
		tataArr(alloc, a.fields, (ref immutable LowField field) =>
			tataRecord(alloc, "field", tataStr(field.mangledName), tataOfLowType(alloc, field.type))));
}

immutable(Sexpr) tataOfLowUnion(Alloc)(ref Alloc alloc, immutable size_t index, ref immutable LowUnion a){
	return tataRecord(
		alloc,
		"union",
		tataNat(index),
		tataStr(a.mangledName),
		tataArr(alloc, a.members, (ref immutable LowType it) =>
			tataOfLowType(alloc, it)));
}

immutable(Sexpr) tataOfLowFun(Alloc)(ref Alloc alloc, immutable size_t index, ref immutable LowFun a) {
	return tataRecord(
		alloc,
		"fun",
		tataNat(index),
		tataStr(a.mangledName),
		tataOfLowType(alloc, a.returnType),
		tataArr(alloc, a.params, (ref immutable LowParam it) =>
			tataRecord(alloc, "param", tataStr(it.mangledName), tataOfLowType(alloc, it.type))),
		tataOfLowFunBody(alloc, a.body_));
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
					tataRecord(alloc, "local", tataStr(local.mangledName), tataOfLowType(alloc, local.type))),
				tataOfLowExpr(alloc, it.expr)));
}

immutable(Sexpr) tataOfLowExpr(Alloc)(ref Alloc alloc, ref immutable LowExpr a) {
	return tataRecord(
		alloc,
		"expr",
		tataOfLowType(alloc, a.type),
		sexprOfSourceRange(alloc, a.range),
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
				tataStr(it.local.mangledName),
				tataOfLowExpr(alloc, it.value),
				tataOfLowExpr(alloc, it.then)),
		(ref immutable LowExprKind.LocalRef it) =>
			tataRecord(alloc, "local-ref", tataStr(it.local.mangledName)),
		(ref immutable LowExprKind.Match it) =>
			tataOfMatch(alloc, it),
		(ref immutable LowExprKind.ParamRef it) =>
			tataRecord(alloc, "param-ref", tataStr(it.param.mangledName)),
		(ref immutable LowExprKind.PtrCast it) =>
			tataRecord(alloc, "ptr-cast", tataOfLowExpr(alloc, it.target)),
		(ref immutable LowExprKind.RecordFieldAccess it) =>
			tataRecord(
				alloc,
				"get-field",
				tataOfLowExpr(alloc, it.target),
				tataBool(it.targetIsPointer),
				tataStr(it.field.mangledName)),
		(ref immutable LowExprKind.RecordFieldSet it) =>
			tataRecord(
				alloc,
				"set-field",
				tataOfLowExpr(alloc, it.target),
				tataBool(it.targetIsPointer),
				tataStr(it.field.mangledName),
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
		(ref immutable LowExprKind.SpecialConstant it) =>
			tataOfSpecialConstant(alloc, it),
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
		(ref immutable LowExprKind.StringLiteral it) =>
			tataRecord(alloc, "str-lit", tataStr(it.literal)));
}

immutable(Sexpr) tataOfMatch(Alloc)(ref Alloc alloc, ref immutable LowExprKind.Match a) {
	return tataRecord(
		alloc,
		"match",
		tataStr(a.matchedLocal.mangledName),
		tataOfLowExpr(alloc, a.matchedValue),
		tataArr(alloc, a.cases, (ref immutable LowExprKind.Match.Case case_) =>
			tataRecord(
				alloc,
				"case",
				tataOpt(alloc, case_.local, (ref immutable Ptr!LowLocal it) =>
					tataStr(it.mangledName)),
				tataOfLowExpr(alloc, case_.then))));
}

immutable(Sym) symOfPrimitiveType(immutable PrimitiveType a) {
	return shortSymAlphaLiteral(() {
		final switch (a) {
			case PrimitiveType.bool_:
				return "bool";
			case PrimitiveType.char_:
				return "char";
			case PrimitiveType.float64:
				return "float-64";
			case PrimitiveType.int8:
				return "int-8";
			case PrimitiveType.int16:
				return "int-16";
			case PrimitiveType.int32:
				return "int-32";
			case PrimitiveType.int64:
				return "int-64";
			case PrimitiveType.nat8:
				return "nat-8";
			case PrimitiveType.nat16:
				return "nat-16";
			case PrimitiveType.nat32:
				return "nat-32";
			case PrimitiveType.nat64:
				return "nat-64";
			case PrimitiveType.void_:
				return "void";
		}
	}());
}

immutable(Sexpr) tataOfSpecialConstant(Alloc)(ref Alloc alloc, ref immutable LowExprKind.SpecialConstant a) {
	immutable Sexpr constant = matchSpecialConstant!(immutable Sexpr)(
		a,
		(immutable LowExprKind.SpecialConstant.BoolConstant it) =>
			tataBool(it.value),
		(immutable LowExprKind.SpecialConstant.Integral it) =>
			tataNat(it.value),
		(immutable LowExprKind.SpecialConstant.Null it) =>
			tataSym("null"),
		(immutable LowExprKind.SpecialConstant.Void it) =>
			tataSym("void"));
	return tataRecord(alloc, "constant", constant);
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
		case LowExprKind.SpecialUnary.Kind.toIntFromInt16:
			return "to-int (from int-16)";
		case LowExprKind.SpecialUnary.Kind.toIntFromInt32:
			return "to-int (from int-32)";
		case LowExprKind.SpecialUnary.Kind.toNatFromNat16:
			return "to-nat (from nat-16)";
		case LowExprKind.SpecialUnary.Kind.toNatFromNat32:
			return "to-nat (from nat-32)";
		case LowExprKind.SpecialUnary.Kind.toNatFromPtr:
			return "to-nat (from ptr)";
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
		case LowExprKind.SpecialBinary.Kind.bitShiftLeftInt32:
			return "bit-shift-left (int-32)";
		case LowExprKind.SpecialBinary.Kind.bitShiftLeftNat32:
			return "bit-shift-left (nat-32)";
		case LowExprKind.SpecialBinary.Kind.bitShiftRightInt32:
			return "bit-shift-right (int-32)";
		case LowExprKind.SpecialBinary.Kind.bitShiftRightNat32:
			return "bit-shift-right (nat-32)";
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
		case LowExprKind.SpecialBinary.Kind.less:
			return "< (?)";
		case LowExprKind.SpecialBinary.Kind.mulFloat64:
			return "* (float-64)";
		case LowExprKind.SpecialBinary.Kind.or:
			return "or";
		case LowExprKind.SpecialBinary.Kind.subFloat64:
			return "- (float-64)";
		case LowExprKind.SpecialBinary.Kind.subPtrNat:
			return "- (ptr - nat-64)";
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
		case LowExprKind.SpecialTrinary.Kind.compareExchangeStrong:
			return "compare-exchange-strong";
	}
}

immutable(string) strOfSpecialNAryKind(immutable LowExprKind.SpecialNAry.Kind a) {
	final switch (a) {
		case LowExprKind.SpecialNAry.Kind.callFunPtr:
			return "call fun ptr";
	}
}
