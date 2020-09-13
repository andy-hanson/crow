module lower.getBuiltinCall;

@safe @nogc pure nothrow:

import lowModel :
	asPrimitive,
	isFunPtrType,
	isNonFunPtrType,
	isPrimitive,
	LowExpr,
	LowExprKind,
	LowParam,
	LowType,
	PrimitiveType;
import lower.lowExprHelpers : ptrCastKind;
import util.bools : Bool, False, True;
import util.collection.arr : Arr, at, empty, size;
import util.memory : allocate;
import util.opt : force, Opt;
import util.ptr : Ptr;
import util.sourceRange : SourceRange;
import util.sym : shortSymAlphaLiteralValue, shortSymOperatorLiteralValue, Sym, symEqLongAlphaLiteral;
import util.util : todo, verify;

immutable(LowExprKind) getBuiltinCallExpr(Alloc)(
	ref Alloc alloc,
	ref immutable SourceRange range,
	immutable Sym name,
	immutable LowType rt,
	immutable Arr!LowExpr args,
	immutable Arr!LowType typeArgs,
	immutable Opt!(Ptr!LowParam) ctxParam,
) {
	immutable(LowExpr) arg0() {
		return at(args, 0);
	}
	immutable(LowExpr) arg1() {
		return at(args, 1);
	}
	immutable(LowExpr) arg2() {
		return at(args, 2);
	}
	immutable(LowType) typeArg0() {
		return at(typeArgs, 0);
	}
	immutable(LowExprKind) constant(immutable LowExprKind.SpecialConstant kind) {
		return immutable LowExprKind(kind);
	}
	immutable(LowExprKind) constantBool(immutable Bool value) {
		return immutable LowExprKind(
			immutable LowExprKind.SpecialConstant(immutable LowExprKind.SpecialConstant.BoolConstant(value)));
	}
	immutable(LowExprKind) constantIntegral(int value) {
		return constant(immutable LowExprKind.SpecialConstant(immutable LowExprKind.SpecialConstant.Integral(value)));
	}
	immutable(LowExprKind) special0Ary(immutable LowExprKind.Special0Ary.Kind kind) {
		verify(empty(args));
		return immutable LowExprKind(immutable LowExprKind.Special0Ary(kind));
	}
	immutable(LowExprKind) unary(immutable LowExprKind.SpecialUnary.Kind kind) {
		verify(size(args) == 1);
		return immutable LowExprKind(immutable LowExprKind.SpecialUnary(
			kind,
			allocate(alloc, arg0())));
	}
	immutable(LowExprKind) binary(immutable LowExprKind.SpecialBinary.Kind kind) {
		verify(size(args) == 2);
		return immutable LowExprKind(immutable LowExprKind.SpecialBinary(
			kind,
			allocate(alloc, arg0()),
			allocate(alloc, arg1())));
	}
	immutable(LowExprKind) trinary(immutable LowExprKind.SpecialTrinary.Kind kind) {
		verify(size(args) == 3);
		return immutable LowExprKind(immutable LowExprKind.SpecialTrinary(
			kind,
			allocate(alloc, arg0()),
			allocate(alloc, arg1()),
			allocate(alloc, arg2())));
	}
	immutable(LowExprKind) nAry(immutable LowExprKind.SpecialNAry.Kind kind) {
		return immutable LowExprKind(immutable LowExprKind.SpecialNAry(kind, args));
	}
	immutable(T) failT(T)() {
		debug {
			import util.sym : symToCStr;
			import util.print : print;
			print(symToCStr(alloc, name));
		}
		return todo!T("not a builtin fun");
	}
	immutable(LowExprKind) fail() {
		return failT!(immutable LowExprKind);
	}
	immutable(LowExprKind.SpecialBinary.Kind) failBinary() {
		return failT!(immutable LowExprKind.SpecialBinary.Kind);
	}
	immutable(LowExprKind.SpecialUnary.Kind) failUnary() {
		return failT!(immutable LowExprKind.SpecialUnary.Kind);
	}

	switch (name.value) {
		case shortSymOperatorLiteralValue("+"):
			return binary(isFloat64(rt)
					? LowExprKind.SpecialBinary.Kind.addFloat64
					: isNonFunPtrType(rt)
					? LowExprKind.SpecialBinary.Kind.addPtr
					: failBinary());
		case shortSymOperatorLiteralValue("-"):
			return binary(isFloat64(rt)
				? LowExprKind.SpecialBinary.Kind.subFloat64
				: isNonFunPtrType(arg0().type) && isNat64(arg1().type)
				? LowExprKind.SpecialBinary.Kind.subPtrNat
				: failBinary());
		case shortSymOperatorLiteralValue("*"):
			return binary(isFloat64(rt) ? LowExprKind.SpecialBinary.Kind.mulFloat64 : failBinary());
		case shortSymAlphaLiteralValue("as-any-ptr"):
			return unary(LowExprKind.SpecialUnary.Kind.asAnyPtr);
		case shortSymAlphaLiteralValue("and"):
			return binary(LowExprKind.SpecialBinary.Kind.and);
		case shortSymAlphaLiteralValue("as"):
			verify(size(args) == 1);
			return arg0().kind;
		case shortSymAlphaLiteralValue("as-ref"):
			return unary(LowExprKind.SpecialUnary.Kind.asRef);
		case shortSymAlphaLiteralValue("bits-and"):
			return binary(isInt8(rt)
				? LowExprKind.SpecialBinary.Kind.bitwiseAndInt8
				: isInt16(rt)
				? LowExprKind.SpecialBinary.Kind.bitwiseAndInt16
				: isInt32(rt)
				? LowExprKind.SpecialBinary.Kind.bitwiseAndInt32
				: isInt64(rt)
				? LowExprKind.SpecialBinary.Kind.bitwiseAndInt64
				: isNat8(rt)
				? LowExprKind.SpecialBinary.Kind.bitwiseAndNat8
				: isNat16(rt)
				? LowExprKind.SpecialBinary.Kind.bitwiseAndNat16
				: isNat32(rt)
				? LowExprKind.SpecialBinary.Kind.bitwiseAndNat32
				: isNat64(rt)
				? LowExprKind.SpecialBinary.Kind.bitwiseAndNat64
				: failBinary());
		case shortSymAlphaLiteralValue("bits-or"):
			return binary(isInt8(rt)
				? LowExprKind.SpecialBinary.Kind.bitwiseOrInt8
				: isInt16(rt)
				? LowExprKind.SpecialBinary.Kind.bitwiseOrInt16
				: isInt32(rt)
				? LowExprKind.SpecialBinary.Kind.bitwiseOrInt32
				: isInt64(rt)
				? LowExprKind.SpecialBinary.Kind.bitwiseOrInt64
				: isNat8(rt)
				? LowExprKind.SpecialBinary.Kind.bitwiseOrNat8
				: isNat16(rt)
				? LowExprKind.SpecialBinary.Kind.bitwiseOrNat16
				: isNat32(rt)
				? LowExprKind.SpecialBinary.Kind.bitwiseOrNat32
				: isNat64(rt)
				? LowExprKind.SpecialBinary.Kind.bitwiseOrNat64
				: failBinary());
		case shortSymAlphaLiteralValue("call"):
			return isFunPtrType(arg0().type)
				? nAry(LowExprKind.SpecialNAry.Kind.callFunPtr)
				: fail();
		case shortSymAlphaLiteralValue("deref"):
			return unary(LowExprKind.SpecialUnary.Kind.deref);
		case shortSymAlphaLiteralValue("false"):
			return constantBool(False);
		case shortSymAlphaLiteralValue("get-ctx"):
			return immutable LowExprKind(immutable LowExprKind.ParamRef(force(ctxParam)));
		case shortSymAlphaLiteralValue("get-errno"):
			return special0Ary(LowExprKind.Special0Ary.Kind.getErrno);
		case shortSymAlphaLiteralValue("hard-fail"):
			return unary(LowExprKind.SpecialUnary.Kind.hardFail);
		case shortSymAlphaLiteralValue("if"):
			return trinary(LowExprKind.SpecialTrinary.Kind.if_);
		case shortSymAlphaLiteralValue("not"):
			return unary(LowExprKind.SpecialUnary.Kind.not);
		case shortSymAlphaLiteralValue("null"):
			return constant(immutable LowExprKind.SpecialConstant(immutable LowExprKind.SpecialConstant.Null()));
		case shortSymAlphaLiteralValue("one"):
			return isIntegral(rt) ? constantIntegral(1) : fail();
		case shortSymAlphaLiteralValue("or"):
			return binary(LowExprKind.SpecialBinary.Kind.or);
		case shortSymAlphaLiteralValue("pass"):
			return constant(immutable LowExprKind.SpecialConstant(immutable LowExprKind.SpecialConstant.Void()));
		case shortSymAlphaLiteralValue("ptr-cast"):
			verify(size(args) == 1 && size(typeArgs) == 2);
			return ptrCastKind(alloc, arg0());
		case shortSymAlphaLiteralValue("ptr-eq"):
			return binary(LowExprKind.SpecialBinary.Kind.eqPtr);
		case shortSymAlphaLiteralValue("ptr-to"):
			return unary(LowExprKind.SpecialUnary.Kind.ptrTo);
		case shortSymAlphaLiteralValue("ref-of-val"):
			return unary(LowExprKind.SpecialUnary.Kind.refOfVal);
		case shortSymAlphaLiteralValue("set"):
			return isNonFunPtrType(arg0().type) ? binary(LowExprKind.SpecialBinary.Kind.writeToPtr) : fail();
		case shortSymAlphaLiteralValue("size-of"):
			verify(empty(args) && size(typeArgs) == 1);
			return immutable LowExprKind(immutable LowExprKind.SizeOf(typeArg0()));
		case shortSymAlphaLiteralValue("to-float"):
			return unary(isInt64(arg0().type)
				? LowExprKind.SpecialUnary.Kind.toFloat64FromInt64
				: isNat64(arg0().type)
				? LowExprKind.SpecialUnary.Kind.toFloat64FromNat64
				: failUnary());
		case shortSymAlphaLiteralValue("to-int"):
			return unary(isInt16(arg0().type)
				? LowExprKind.SpecialUnary.Kind.toIntFromInt16
				: isInt32(arg0().type)
				? LowExprKind.SpecialUnary.Kind.toIntFromInt32
				: failUnary());
		case shortSymAlphaLiteralValue("to-nat"):
			return unary(isNat16(arg0().type)
				? LowExprKind.SpecialUnary.Kind.toNatFromNat16
				: isNat32(arg0().type)
				? LowExprKind.SpecialUnary.Kind.toNatFromNat32
				: isNonFunPtrType(arg0().type)
				? LowExprKind.SpecialUnary.Kind.toNatFromPtr
				: failUnary());
		case shortSymAlphaLiteralValue("true"):
			return constantBool(True);
		case shortSymAlphaLiteralValue("unsafe-div"):
			return binary(isFloat64(rt)
				? LowExprKind.SpecialBinary.Kind.unsafeDivFloat64
				: isInt64(rt)
				? LowExprKind.SpecialBinary.Kind.unsafeDivInt64
				: isNat64(rt)
				? LowExprKind.SpecialBinary.Kind.unsafeDivNat64
				: failBinary());
		case shortSymAlphaLiteralValue("wrap-add"):
			return binary(isInt16(rt)
				? LowExprKind.SpecialBinary.Kind.wrapAddInt16
				: isInt32(rt)
				? LowExprKind.SpecialBinary.Kind.wrapAddInt32
				: isInt64(rt)
				? LowExprKind.SpecialBinary.Kind.wrapAddInt64
				: isNat16(rt)
				? LowExprKind.SpecialBinary.Kind.wrapAddNat16
				: isNat32(rt)
				? LowExprKind.SpecialBinary.Kind.wrapAddNat32
				: isNat64(rt)
				? LowExprKind.SpecialBinary.Kind.wrapAddNat64
				: failBinary());
		case shortSymAlphaLiteralValue("wrap-mul"):
			return binary(isInt16(rt)
				? LowExprKind.SpecialBinary.Kind.wrapMulInt16
				: isInt32(rt)
				? LowExprKind.SpecialBinary.Kind.wrapMulInt32
				: isInt64(rt)
				? LowExprKind.SpecialBinary.Kind.wrapMulInt64
				: isNat16(rt)
				? LowExprKind.SpecialBinary.Kind.wrapMulNat16
				: isNat32(rt)
				? LowExprKind.SpecialBinary.Kind.wrapMulNat32
				: isNat64(rt)
				? LowExprKind.SpecialBinary.Kind.wrapMulNat64
				: failBinary());
		case shortSymAlphaLiteralValue("wrap-sub"):
			return binary(isInt16(rt)
				? LowExprKind.SpecialBinary.Kind.wrapSubInt16
				: isInt32(rt)
				? LowExprKind.SpecialBinary.Kind.wrapSubInt32
				: isInt64(rt)
				? LowExprKind.SpecialBinary.Kind.wrapSubInt64
				: isNat16(rt)
				? LowExprKind.SpecialBinary.Kind.wrapSubNat16
				: isNat32(rt)
				? LowExprKind.SpecialBinary.Kind.wrapSubNat32
				: isNat64(rt)
				? LowExprKind.SpecialBinary.Kind.wrapSubNat64
				: failBinary());
		case shortSymAlphaLiteralValue("zero"):
			return isIntegral(rt) ? constantIntegral(0) : fail();
		case shortSymAlphaLiteralValue("unsafe-mod"):
			return isNat64(rt) ? binary(LowExprKind.SpecialBinary.Kind.unsafeModNat64) : fail();
		default:
			if (symEqLongAlphaLiteral(name, "bit-shift-left"))
				return binary(isInt32(rt)
					? LowExprKind.SpecialBinary.Kind.bitShiftLeftInt32
					: isNat32(rt)
					? LowExprKind.SpecialBinary.Kind.bitShiftLeftNat32
					: failBinary());
			else if (symEqLongAlphaLiteral(name, "bit-shift-right"))
				return binary(isInt32(rt)
					? LowExprKind.SpecialBinary.Kind.bitShiftRightInt32
					: isNat32(rt)
					? LowExprKind.SpecialBinary.Kind.bitShiftRightNat32
					: failBinary());
			else if (symEqLongAlphaLiteral(name, "compare-exchange-strong"))
				//TODO: why was this not just an extern fn?
				return trinary(LowExprKind.SpecialTrinary.Kind.compareExchangeStrong);
			else if (symEqLongAlphaLiteral(name, "is-reference-type"))
				return todo!(immutable LowExprKind)("is-reference-type");
			else if (symEqLongAlphaLiteral(name, "truncate-to-int"))
				return unary(LowExprKind.SpecialUnary.Kind.truncateToInt64FromFloat64);
			else if (symEqLongAlphaLiteral(name, "unsafe-to-int"))
				return isNat64(arg0().type) ? unary(LowExprKind.SpecialUnary.Kind.unsafeNat64ToInt64) : fail();
			else if (symEqLongAlphaLiteral(name, "unsafe-to-int8"))
				return isInt64(arg0().type) ? unary(LowExprKind.SpecialUnary.Kind.unsafeInt64ToInt8) : fail();
			else if (symEqLongAlphaLiteral(name, "unsafe-to-int16"))
				return isInt64(arg0().type) ? unary(LowExprKind.SpecialUnary.Kind.unsafeInt64ToInt16) : fail();
			else if (symEqLongAlphaLiteral(name, "unsafe-to-int32"))
				return isInt64(arg0().type) ? unary(LowExprKind.SpecialUnary.Kind.unsafeInt64ToInt32) : fail();
			else if (symEqLongAlphaLiteral(name, "unsafe-to-nat"))
				return isInt64(arg0().type) ? unary(LowExprKind.SpecialUnary.Kind.unsafeInt64ToNat64) : fail();
			else if (symEqLongAlphaLiteral(name, "unsafe-to-nat8"))
				return isNat64(arg0().type) ? unary(LowExprKind.SpecialUnary.Kind.unsafeNat64ToNat8) : fail();
			else if (symEqLongAlphaLiteral(name, "unsafe-to-nat16"))
				return isNat64(arg0().type) ? unary(LowExprKind.SpecialUnary.Kind.unsafeNat64ToNat16): fail();
			else if (symEqLongAlphaLiteral(name, "unsafe-to-nat32"))
				return isNat64(arg0().type) ? unary(LowExprKind.SpecialUnary.Kind.unsafeNat64ToNat32) : fail();
			else
				return fail();
	}
}

immutable(Bool) isPrimitiveType(ref immutable LowType t, immutable PrimitiveType p) {
	return immutable Bool(isPrimitive(t) && asPrimitive(t) == p);
}

immutable(Bool) isInt8(ref immutable LowType t) {
	return isPrimitiveType(t, PrimitiveType.int8);
}

immutable(Bool) isInt16(ref immutable LowType t) {
	return isPrimitiveType(t, PrimitiveType.int16);
}

immutable(Bool) isInt32(ref immutable LowType t) {
	return isPrimitiveType(t, PrimitiveType.int32);
}

immutable(Bool) isInt64(ref immutable LowType t) {
	return isPrimitiveType(t, PrimitiveType.int64);
}

immutable(Bool) isNat8(ref immutable LowType t) {
	return isPrimitiveType(t, PrimitiveType.nat8);
}

immutable(Bool) isNat16(ref immutable LowType t) {
	return isPrimitiveType(t, PrimitiveType.nat16);
}

immutable(Bool) isNat32(ref immutable LowType t) {
	return isPrimitiveType(t, PrimitiveType.nat32);
}

immutable(Bool) isNat64(ref immutable LowType t) {
	return isPrimitiveType(t, PrimitiveType.nat64);
}

immutable(Bool) isFloat64(ref immutable LowType t) {
	return isPrimitiveType(t, PrimitiveType.float64);
}

immutable(Bool) isIntegral(ref immutable LowType t) {
	return immutable Bool(isPrimitive(t) && () {
		final switch (asPrimitive(t)) {
			case PrimitiveType.int8:
			case PrimitiveType.int16:
			case PrimitiveType.int32:
			case PrimitiveType.int64:
			case PrimitiveType.nat8:
			case PrimitiveType.nat16:
			case PrimitiveType.nat32:
			case PrimitiveType.nat64:
				return True;
			case PrimitiveType.bool_:
			case PrimitiveType.char_:
			case PrimitiveType.float64:
			case PrimitiveType.void_:
				return False;
		}
	}());
}
