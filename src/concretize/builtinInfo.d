module concretize.builtinInfo;

@safe @nogc pure nothrow:

import concreteModel : BuiltinFunEmit, BuiltinFunInfo, BuiltinFunKind, BuiltinStructInfo, BuiltinStructKind;
import model : asStructInst, decl, isStructInst, Sig, StructDecl, Type;
import util.bools : Bool, False, True;
import util.collection.arr : at, size;
import util.opt : force, has, none, Opt, some;
import util.ptr : Ptr;
import util.sym :
	shortSymAlphaLiteral,
	shortSymAlphaLiteralValue,
	shortSymOperatorLiteralValue,
	Sym,
	symEq,
	symEqLongAlphaLiteral;
import util.util : todo;

immutable(BuiltinFunInfo) getBuiltinFunInfo(ref immutable Sig sig) {
	immutable Opt!BuiltinFunInfo res = tryGetBuiltinFunInfo(sig);
	if (!has(res)) {
		debug {
			import core.stdc.stdio : printf;
			import util.alloc.stackAlloc : StackAlloc;
			import util.sym : symToCStr;
			StackAlloc!("temp", 1024) tempAlloc;
			printf("not a builtin fun: %s\n", symToCStr(tempAlloc, sig.name));
		}
		todo!void("not a builtin fun");
	}
	return force(res);
}

immutable(BuiltinStructInfo) getBuiltinStructInfo(immutable Ptr!StructDecl s) {
	switch (s.name.value) {
		case shortSymAlphaLiteralValue("bool"):
			return BuiltinStructInfo(BuiltinStructKind.bool_, Bool.sizeof);
		case shortSymAlphaLiteralValue("byte"):
			return BuiltinStructInfo(BuiltinStructKind.byte_, byte.sizeof);
		case shortSymAlphaLiteralValue("char"):
			return BuiltinStructInfo(BuiltinStructKind.char_, char.sizeof);
		case shortSymAlphaLiteralValue("float"):
			return BuiltinStructInfo(BuiltinStructKind.float64, double.sizeof);
		case shortSymAlphaLiteralValue("fun-ptr0"):
		case shortSymAlphaLiteralValue("fun-ptr1"):
		case shortSymAlphaLiteralValue("fun-ptr2"):
		case shortSymAlphaLiteralValue("fun-ptr3"):
		case shortSymAlphaLiteralValue("fun-ptr4"):
		case shortSymAlphaLiteralValue("fun-ptr5"):
		case shortSymAlphaLiteralValue("fun-ptr6"):
			return BuiltinStructInfo(BuiltinStructKind.funPtrN, (void *).sizeof);
		case shortSymAlphaLiteralValue("int16"):
			return BuiltinStructInfo(BuiltinStructKind.int16, short.sizeof);
		case shortSymAlphaLiteralValue("int32"):
			return BuiltinStructInfo(BuiltinStructKind.int32, int.sizeof);
		case shortSymAlphaLiteralValue("int"):
			return BuiltinStructInfo(BuiltinStructKind.int64, long.sizeof);
		case shortSymAlphaLiteralValue("nat16"):
			return BuiltinStructInfo(BuiltinStructKind.nat16, ushort.sizeof);
		case shortSymAlphaLiteralValue("nat32"):
			return BuiltinStructInfo(BuiltinStructKind.nat32, uint.sizeof);
		case shortSymAlphaLiteralValue("nat"):
			return BuiltinStructInfo(BuiltinStructKind.nat64, ulong.sizeof);
		case shortSymAlphaLiteralValue("ptr"):
			return BuiltinStructInfo(BuiltinStructKind.ptr, (void*).sizeof);
		case shortSymAlphaLiteralValue("void"):
			return BuiltinStructInfo(BuiltinStructKind.void_, 1);
		default:
			return todo!(immutable BuiltinStructInfo)("not a recognized builtin struct");
	}
}

private:

immutable(Bool) isNamed(ref immutable Type t, immutable Sym name) {
	return Bool(isStructInst(t) && symEq(decl(asStructInst(t).deref).name, name));
}

immutable(Bool) isFloat64(ref immutable Type t) {
	return isNamed(t, shortSymAlphaLiteral("float"));
}

immutable(Bool) isInt16(ref immutable Type t) {
	return isNamed(t, shortSymAlphaLiteral("int16"));
}

immutable(Bool) isInt32(ref immutable Type t) {
	return isNamed(t, shortSymAlphaLiteral("int32"));
}

immutable(Bool) isInt64(ref immutable Type t) {
	return isNamed(t, shortSymAlphaLiteral("int"));
}

immutable(Bool) isNat16(ref immutable Type t) {
	return isNamed(t, shortSymAlphaLiteral("nat16"));
}

immutable(Bool) isNat32(ref immutable Type t) {
	return isNamed(t, shortSymAlphaLiteral("nat32"));
}

immutable(Bool) isNat64(ref immutable Type t) {
	return isNamed(t, shortSymAlphaLiteral("nat"));
}

immutable(Bool) isPtr(ref immutable Type t) {
	return isNamed(t, shortSymAlphaLiteral("ptr"));
}

immutable(Bool) isVoid(ref immutable Type t) {
	return isNamed(t, shortSymAlphaLiteral("void"));
}

immutable(Bool) isSomeFunPtr(ref immutable Type t) {
	if (!isStructInst(t))
		return False;
	else
		switch (decl(asStructInst(t).deref).name.value) {
			case shortSymAlphaLiteralValue("fun-ptr0"):
			case shortSymAlphaLiteralValue("fun-ptr1"):
			case shortSymAlphaLiteralValue("fun-ptr2"):
			case shortSymAlphaLiteralValue("fun-ptr3"):
			case shortSymAlphaLiteralValue("fun-ptr4"):
			case shortSymAlphaLiteralValue("fun-ptr5"):
			case shortSymAlphaLiteralValue("fun-ptr6"):
				return True;
			default:
				return False;
		}
}

immutable(Opt!BuiltinFunInfo) generate(immutable BuiltinFunKind kind) {
	return some(BuiltinFunInfo(BuiltinFunEmit.generate, kind));
}

immutable(Opt!BuiltinFunInfo) special(immutable BuiltinFunKind kind) {
	return some(BuiltinFunInfo(BuiltinFunEmit.special, kind));
}

immutable(Opt!BuiltinFunInfo) operator(immutable BuiltinFunKind kind) {
	return some(BuiltinFunInfo(BuiltinFunEmit.operator, kind));
}

immutable(Opt!BuiltinFunInfo) tryGetBuiltinFunInfo(ref immutable Sig sig) {
	immutable Sym name = sig.name;
	immutable Opt!BuiltinFunInfo no = none!BuiltinFunInfo;
	immutable Type rt = sig.returnType;
	immutable Type paramTypeAt(immutable size_t i) {
		return size(sig.params) > i
			? at(sig.params, i).type
			: immutable Type(Type.Bogus());
	}
	immutable Type p0 = paramTypeAt(0);
	immutable Type p1 = paramTypeAt(1);
	switch (name.value) {
		case shortSymOperatorLiteralValue("<=>"):
			return generate(BuiltinFunKind.compare);
		case shortSymOperatorLiteralValue("+"):
			return isFloat64(rt) ? operator(BuiltinFunKind.addFloat64)
				: isPtr(rt) ? operator(BuiltinFunKind.addPtr)
				: no;
		case shortSymOperatorLiteralValue("-"):
			return isFloat64(rt) ? operator(BuiltinFunKind.subFloat64)
				: isPtr(rt) && isPtr(p0) && isNat64(p1) ? operator(BuiltinFunKind.subPtrNat)
				: no;
		case shortSymOperatorLiteralValue("*"):
			return isFloat64(rt) ? operator(BuiltinFunKind.mulFloat64) : no;
		case shortSymAlphaLiteralValue("and"):
			return operator(BuiltinFunKind.and);
		case shortSymAlphaLiteralValue("as"):
			return operator(BuiltinFunKind.as);
		case shortSymAlphaLiteralValue("as-any-ptr"):
			return operator(BuiltinFunKind.asAnyPtr);
		case shortSymAlphaLiteralValue("as-ref"):
			// TODO: actually, this should be specializable in some cases.
			// Constant arr<by-val<?t>>, get ptr, do as-ref, it should be constant
			return operator(BuiltinFunKind.asRef);
		case shortSymAlphaLiteralValue("bits-and"):
			return isNat16(rt) ? operator(BuiltinFunKind.bitwiseAndNat16)
				: isNat32(rt) ? operator(BuiltinFunKind.bitwiseAndNat32)
				: isNat64(rt) ? operator(BuiltinFunKind.bitwiseAndNat64)
				: isInt16(rt) ? operator(BuiltinFunKind.bitwiseAndInt16)
				: isInt32(rt) ? operator(BuiltinFunKind.bitwiseAndInt32)
				: isInt64(rt) ? operator(BuiltinFunKind.bitwiseAndInt64)
				: no;
		case shortSymAlphaLiteralValue("bits-or"):
			return isNat16(rt) ? operator(BuiltinFunKind.bitwiseOrNat16)
				: isNat32(rt) ? operator(BuiltinFunKind.bitwiseOrNat32)
				: isNat64(rt) ? operator(BuiltinFunKind.bitwiseOrNat64)
				: isInt16(rt) ? operator(BuiltinFunKind.bitwiseOrInt16)
				: isInt32(rt) ? operator(BuiltinFunKind.bitwiseOrInt32)
				: isInt64(rt) ? operator(BuiltinFunKind.bitwiseOrInt64)
				: no;
		case shortSymAlphaLiteralValue("bit-lshift"):
			return isInt32(rt) ? operator(BuiltinFunKind.bitShiftLeftInt32) : no;
		case shortSymAlphaLiteralValue("bit-rshift"):
			return isInt32(rt) ? operator(BuiltinFunKind.bitShiftRightInt32) : no;
		case shortSymAlphaLiteralValue("call"):
			return isSomeFunPtr(p0) ? operator(BuiltinFunKind.callFunPtr) : no;
		case shortSymAlphaLiteralValue("deref"):
			return operator(BuiltinFunKind.deref);
		case shortSymAlphaLiteralValue("false"):
			return operator(BuiltinFunKind.false_);
		case shortSymAlphaLiteralValue("get-ctx"):
			return operator(BuiltinFunKind.getCtx);
		case shortSymAlphaLiteralValue("get-errno"):
			return special(BuiltinFunKind.getErrno);
		case shortSymAlphaLiteralValue("hard-fail"):
			return special(BuiltinFunKind.hardFail);
		case shortSymAlphaLiteralValue("if"):
			return operator(BuiltinFunKind.if_);
		case shortSymAlphaLiteralValue("not"):
			return operator(BuiltinFunKind.not);
		case shortSymAlphaLiteralValue("null"):
			return operator(BuiltinFunKind.null_);
		case shortSymAlphaLiteralValue("one"):
			return isFloat64(rt) ? todo!(immutable Opt!BuiltinFunInfo)("one float")
				: isInt16(rt) ? operator(BuiltinFunKind.oneInt16)
				: isInt32(rt) ? operator(BuiltinFunKind.oneInt32)
				: isInt64(rt) ? operator(BuiltinFunKind.oneInt64)
				: isNat16(rt) ? operator(BuiltinFunKind.oneNat16)
				: isNat32(rt) ? operator(BuiltinFunKind.oneNat32)
				: isNat64(rt) ? operator(BuiltinFunKind.oneNat64)
				: no;
		case shortSymAlphaLiteralValue("or"):
			return operator(BuiltinFunKind.or);
		case shortSymAlphaLiteralValue("pass"):
			return isVoid(rt) ? operator(BuiltinFunKind.pass) : no;
		case shortSymAlphaLiteralValue("ptr-cast"):
			return operator(BuiltinFunKind.ptrCast);
		case shortSymAlphaLiteralValue("ptr-to"):
			return operator(BuiltinFunKind.ptrTo);
		case shortSymAlphaLiteralValue("ref-of-val"):
			return operator(BuiltinFunKind.refOfVal);
		case shortSymAlphaLiteralValue("set"):
			return isPtr(p0) ? operator(BuiltinFunKind.setPtr) : no;
		case shortSymAlphaLiteralValue("size-of"):
			return operator(BuiltinFunKind.sizeOf);
		case shortSymAlphaLiteralValue("to-int"):
			return isInt16(p0) ? operator(BuiltinFunKind.toIntFromInt16)
				: isInt32(p0) ? operator(BuiltinFunKind.toIntFromInt32)
				: no;
		case shortSymAlphaLiteralValue("to-nat"):
			return isNat16(p0) ? operator(BuiltinFunKind.toNatFromNat16)
				: isNat32(p0) ? operator(BuiltinFunKind.toNatFromNat32)
				: isPtr(p0) ? operator(BuiltinFunKind.toNatFromPtr)
				: no;
		case shortSymAlphaLiteralValue("true"):
			return operator(BuiltinFunKind.true_);
		case shortSymAlphaLiteralValue("unsafe-div"):
			return isFloat64(rt) ? operator(BuiltinFunKind.unsafeDivFloat64)
				: isInt64(rt) ? operator(BuiltinFunKind.unsafeDivInt64)
				: isNat64(rt) ? operator(BuiltinFunKind.unsafeDivNat64)
				: no;
		case shortSymAlphaLiteralValue("unsafe-mod"):
			return operator(BuiltinFunKind.unsafeModNat64);
		case shortSymAlphaLiteralValue("wrap-add"):
			return isInt16(rt) ? operator(BuiltinFunKind.wrapAddInt16)
				: isInt32(rt) ? operator(BuiltinFunKind.wrapAddInt32)
				: isInt64(rt) ? operator(BuiltinFunKind.wrapAddInt64)
				: isNat16(rt) ? operator(BuiltinFunKind.wrapAddNat16)
				: isNat32(rt) ? operator(BuiltinFunKind.wrapAddNat32)
				: isNat64(rt) ? operator(BuiltinFunKind.wrapAddNat64)
				: no;
		case shortSymAlphaLiteralValue("wrap-sub"):
			return isInt16(rt) ? operator(BuiltinFunKind.wrapSubInt16)
				: isInt32(rt) ? operator(BuiltinFunKind.wrapSubInt32)
				: isInt64(rt) ? operator(BuiltinFunKind.wrapSubInt64)
				: isNat16(rt) ? operator(BuiltinFunKind.wrapSubNat16)
				: isNat32(rt) ? operator(BuiltinFunKind.wrapSubNat32)
				: isNat64(rt) ? operator(BuiltinFunKind.wrapSubNat64)
				: no;
		case shortSymAlphaLiteralValue("wrap-mul"):
			return isInt16(rt) ? operator(BuiltinFunKind.wrapMulInt16)
				: isInt32(rt) ? operator(BuiltinFunKind.wrapMulInt32)
				: isInt64(rt) ? operator(BuiltinFunKind.wrapMulInt64)
				: isInt16(rt) ? operator(BuiltinFunKind.wrapMulNat16)
				: isNat32(rt) ? operator(BuiltinFunKind.wrapMulNat32)
				: isNat64(rt) ? operator(BuiltinFunKind.wrapMulNat64)
				: no;
		case shortSymAlphaLiteralValue("zero"):
			return isFloat64(rt) ? todo!(immutable Opt!BuiltinFunInfo)("zero float")
				: isInt16(rt) ? operator(BuiltinFunKind.zeroInt16)
				: isInt32(rt) ? operator(BuiltinFunKind.zeroInt32)
				: isInt64(rt) ? operator(BuiltinFunKind.zeroInt64)
				: isNat16(rt) ? operator(BuiltinFunKind.zeroNat16)
				: isNat32(rt) ? operator(BuiltinFunKind.zeroNat32)
				: isNat64(rt) ? operator(BuiltinFunKind.zeroNat64)
				: no;
		default:
			if (symEqLongAlphaLiteral(name, "compare-exchange-strong"))
				return special(BuiltinFunKind.compareExchangeStrong);
			else if (symEqLongAlphaLiteral(name, "is-reference-type"))
				return operator(BuiltinFunKind.isReferenceType);
			else if (symEqLongAlphaLiteral(name, "unsafe-to-int"))
				return isNat64(p0) ? operator(BuiltinFunKind.unsafeNat64ToInt64) : no;
			else if (symEqLongAlphaLiteral(name, "unsafe-to-int16"))
				return isInt64(p0) ? operator(BuiltinFunKind.unsafeInt64ToInt16) : no;
			else if (symEqLongAlphaLiteral(name, "unsafe-to-int32"))
				return isInt64(p0) ? operator(BuiltinFunKind.unsafeInt64ToInt32) : no;
			else if (symEqLongAlphaLiteral(name, "unsafe-to-nat"))
				return isInt64(p0) ? operator(BuiltinFunKind.unsafeInt64ToNat64) : no;
			else if (symEqLongAlphaLiteral(name, "unsafe-to-nat16"))
				return isNat64(p0) ? operator(BuiltinFunKind.unsafeNat64ToNat16) : no;
			else if (symEqLongAlphaLiteral(name, "unsafe-to-nat32"))
				return isNat64(p0) ? operator(BuiltinFunKind.unsafeNat64ToNat32) : no;
			else
				return no;
	}

}


