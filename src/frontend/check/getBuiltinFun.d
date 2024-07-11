module frontend.check.getBuiltinFun;

@safe @nogc pure nothrow:

import frontend.check.checkCtx : addDiag, CheckCtx;
import frontend.check.instantiate : isOptionType;
import model.constant : Constant, constantBool, constantZero;
import model.diag : Diag;
import model.model :
	arrayElementType,
	Builtin4ary,
	BuiltinBinary,
	BuiltinBinaryLazy,
	BuiltinBinaryMath,
	BuiltinFun,
	BuiltinType,
	BuiltinUnary,
	BuiltinUnaryMath,
	BuiltinTernary,
	CommonTypes,
	Destructure,
	FunBody,
	FunDecl,
	isArray,
	isMutArray,
	isString,
	isSymbol,
	JsFun,
	paramsArray,
	pointeeType,
	SpecInst,
	StructInst,
	Type,
	TypeParamIndex;
import util.opt : force, has, none, Opt, some;
import util.sourceRange : Range;
import util.symbol : Symbol, symbol;
import versionInfo : VersionFun;

FunBody getBuiltinFun(ref CheckCtx ctx, in CommonTypes commonTypes, FunDecl* fun) {
	Destructure[] params = paramsArray(fun.params);
	return inner(
		ctx, commonTypes, fun.nameRange.range, fun.name, fun.returnType, params.length,
		params.length >= 1 ? params[0].type : Type.bogus,
		params.length >= 2 ? params[1].type : Type.bogus,
		params.length >= 3 ? params[2].type : Type.bogus,
		fun.specs);
}

private:

FunBody inner(
	ref CheckCtx ctx,
	in CommonTypes commonTypes,
	in Range range,
	Symbol name,
	Type rt,
	size_t arity,
	Type p0,
	Type p1,
	Type p2,
	in SpecInst*[] specs,
) {
	BuiltinUnary failUnary() => cast(BuiltinUnary) 0xffffffff;
	BuiltinBinary failBinary() => cast(BuiltinBinary) 0xffffffff;
	BuiltinBinaryLazy failBinaryLazy() => cast(BuiltinBinaryLazy) 0xffffffff;

	FunBody fail() {
		addDiag(ctx, range, Diag(Diag.BuiltinUnsupported(Diag.BuiltinUnsupported.Kind.function_, name)));
		return FunBody(FunBody.Bogus());
	}
	FunBody constant(bool returnTypeOk, Constant value) =>
		returnTypeOk ? FunBody(BuiltinFun(value)) : fail();
	FunBody unary(BuiltinUnary kind) =>
		arity == 1 && kind != failUnary ? FunBody(BuiltinFun(kind)) : fail();
	FunBody binary(BuiltinBinary kind) =>
		arity == 2 && kind != failBinary ? FunBody(BuiltinFun(kind)) : fail();
	FunBody ternary(BuiltinTernary kind) =>
		arity == 3 ? FunBody(BuiltinFun(kind)) : fail();
	FunBody fourary(Builtin4ary kind) =>
		arity == 4 ? FunBody(BuiltinFun(kind)) : fail();

	bool isUnaryFloat32() =>
		arity == 1 && isFloat32(rt) && isFloat32(p0);
	bool isUnaryFloat64() =>
		arity == 1 && isFloat64(rt) && isFloat64(p0);
	bool isBinaryFloat32() =>
		arity == 2 && isFloat32(rt) && isFloat32(p0) && isFloat32(p1);
	bool isBinaryFloat64() =>
		arity == 2 && isFloat64(rt) && isFloat64(p0) && isFloat64(p1);

	FunBody unaryFloat64(BuiltinUnary kind) =>
		unary(isUnaryFloat64() ? kind : failUnary);
	FunBody unaryMath(BuiltinUnaryMath kind32, BuiltinUnaryMath kind64) =>
		arity != 1
			? fail()
			: isUnaryFloat32()
			? FunBody(BuiltinFun(kind32))
			: isUnaryFloat64()
			? FunBody(BuiltinFun(kind64))
			: fail();
	FunBody binaryFloat64(BuiltinBinary kind) =>
		binary(isBinaryFloat64() ? kind : failBinary);
	FunBody binaryMath(BuiltinBinaryMath kind32, BuiltinBinaryMath kind64) =>
		arity != 2
			? fail()
			: isBinaryFloat32()
			? FunBody(BuiltinFun(kind32))
			: isBinaryFloat64()
			? FunBody(BuiltinFun(kind64))
			: fail();
	FunBody binaryLazy(BuiltinBinaryLazy kind) =>
		arity == 2 && kind != failBinaryLazy ? FunBody(BuiltinFun(kind)) : fail();

	switch (name.value) {
		case symbol!"as-js-any".value:
			return isJsAny(rt) && arity == 1 && isTypeParam0(p0)
				? FunBody(BuiltinFun(JsFun.asJsAny))
				: fail();
		// TODO: MOVE STUFF _----------------------------------------------------------------------------------------------------------
		case symbol!"as-t".value:
			return isTypeParam0(rt) && arity == 1 && isJsAny(p0)
				? FunBody(BuiltinFun(JsFun.jsAnyAsT))
				: fail();
		case symbol!"js-global".value:
			return isJsAny(rt) && arity == 0 ? FunBody(BuiltinFun(JsFun.jsGlobal)) : fail();
		case symbol!"get".value:
			return isJsAny(rt) && arity == 2 && isJsAny(p0) && isJsObjectKey(commonTypes, p1) ? FunBody(BuiltinFun(JsFun.get)) : fail();
		case symbol!"set".value:
			return isVoid(rt) && arity == 3 && isJsAny(p0) && isJsObjectKey(commonTypes, p1) && isTypeParam0(p2)
				? FunBody(BuiltinFun(JsFun.set))
				: fail();
		case symbol!"call".value:
			return isJsAny(rt)
				? FunBody(BuiltinFun(JsFun.call))
				: fail();
		case symbol!"call-new".value:
			return isJsAny(rt)
				? FunBody(BuiltinFun(JsFun.callNew))
				: fail();
		case symbol!"call-property".value:
			return isJsAny(rt) && arity >= 2 && isJsAny(p0) && isString(p1) /*&& isJsAny(commonTypes, p2)*/ // TODO: assert that all other args are jsAny
				? FunBody(BuiltinFun(JsFun.callProperty))
				: fail();
		case symbol!"call-property-spread".value:
			return isJsAny(rt) && arity == 3 && isJsAny(p0) && isString(p1) && isTypeParam0Array(p2)
				? FunBody(BuiltinFun(JsFun.callPropertySpread))
				: fail();
		case symbol!"js-cast".value:
			return isTypeParam0(rt) && arity == 1 && isTypeParam1(p0)
				? FunBody(BuiltinFun(JsFun.cast_))
				: fail();
		case symbol!"js-eq-eq-eq".value:
			return isBool(rt) && arity == 2 && isTypeParam0(p0) && isTypeParam0(p1)
				? FunBody(BuiltinFun(JsFun.eqEqEq))
				: fail();
		case symbol!"js-less".value:
			return isBool(rt) && arity == 2 && isTypeParam0(p0) && isTypeParam0(p1)
				? FunBody(BuiltinFun(JsFun.less))
				: fail();
		case symbol!"js-plus".value:
			return isTypeParam0(rt) && arity == 2 && isTypeParam0(p0) && isTypeParam0(p1)
				? FunBody(BuiltinFun(JsFun.plus))
				: fail();
		case symbol!"c-string-of-symbol".value:
			return unary(isCString(rt) && isSymbol(p0)
				? BuiltinUnary.cStringOfSymbol
				: failUnary);
		case symbol!"symbol-of-c-string".value:
			return unary(isSymbol(rt) && isCString(p0)
				? BuiltinUnary.symbolOfCString
				: failUnary);
		// TODO: MOVE STUFF ABOVE ----------------------------------------------------------------------------------------------------------


		case symbol!"array-size".value:
			return arity == 1 && isNat64(rt) && isArray(p0) ? unary(BuiltinUnary.arraySize) : fail();
		case symbol!"mut-array-size".value:
			return arity == 1 && isNat64(rt) && isMutArray(p0) ? unary(BuiltinUnary.arraySize) : fail();
		case symbol!"array-pointer".value:
			return arity == 1 && isPointerConst(rt) && isArray(p0) ? unary(BuiltinUnary.arrayPointer) : fail();
		case symbol!"mut-array-pointer".value:
			return arity == 1 && isPointerMut(rt) && isMutArray(p0) ? unary(BuiltinUnary.arrayPointer) : fail();
		case symbol!"+".value:
			return binary(isFloat32(rt)
				? BuiltinBinary.addFloat32
				: isBinaryFloat64()
				? BuiltinBinary.addFloat64
				: isPointerConstOrMut(rt) && isPointerConstOrMut(p0) && isNat64(p1)
				? BuiltinBinary.addPointerAndNat64
				: failBinary);
		case symbol!"-".value:
			return binary(isFloat32(rt)
				? BuiltinBinary.subFloat32
				: isBinaryFloat64()
				? BuiltinBinary.subFloat64
				: isPointerConstOrMut(rt) && isPointerConstOrMut(p0) && isNat64(p1)
				? BuiltinBinary.subPointerAndNat64
				: failBinary);
		case symbol!"*".value:
			return isPointerConstOrMut(p0)
				? unary(BuiltinUnary.deref)
				: binary(isFloat32(rt)
					? BuiltinBinary.mulFloat32
					: isBinaryFloat64()
					? BuiltinBinary.mulFloat64
					: failBinary);
		case symbol!"==".value:
			return binary(
				p0 != p1 ? failBinary :
				isChar8(p0) ? BuiltinBinary.eqChar8 :
				isChar32(p0) ? BuiltinBinary.eqChar32 :
				isNat8(p0) ? BuiltinBinary.eqNat8 :
				isNat16(p0) ? BuiltinBinary.eqNat16 :
				isNat32(p0) ? BuiltinBinary.eqNat32 :
				isNat64(p0) ? BuiltinBinary.eqNat64 :
				isInt8(p0) ? BuiltinBinary.eqInt8 :
				isInt16(p0) ? BuiltinBinary.eqInt16 :
				isInt32(p0) ? BuiltinBinary.eqInt32 :
				isInt64(p0) ? BuiltinBinary.eqInt64 :
				isFloat32(p0) ? BuiltinBinary.eqFloat32 :
				isFloat64(p0) ? BuiltinBinary.eqFloat64 :
				isPointerConstOrMut(p0) ? BuiltinBinary.eqPointer :
				failBinary);
		case symbol!"&&".value:
			return binaryLazy(isBool(rt) && isBool(p0) && isBool(p1) ? BuiltinBinaryLazy.boolAnd : failBinaryLazy);
		case symbol!"||".value:
			return binaryLazy(
				isBool(rt) && isBool(p0) && isBool(p1)
				? BuiltinBinaryLazy.boolOr
				: isOptionType(commonTypes, rt) && isOptionType(commonTypes, p0) && isOptionType(commonTypes, p1)
				? BuiltinBinaryLazy.optionOr
				: failBinaryLazy);
		case symbol!"??".value:
			return binaryLazy(isOptionType(commonTypes, p0) ? BuiltinBinaryLazy.optionQuestion2 : failBinaryLazy);
		case symbol!"&".value:
			return binary(isInt8(rt)
				? BuiltinBinary.bitwiseAndInt8
				: isInt16(rt)
				? BuiltinBinary.bitwiseAndInt16
				: isInt32(rt)
				? BuiltinBinary.bitwiseAndInt32
				: isInt64(rt)
				? BuiltinBinary.bitwiseAndInt64
				: isNat8(rt)
				? BuiltinBinary.bitwiseAndNat8
				: isNat16(rt)
				? BuiltinBinary.bitwiseAndNat16
				: isNat32(rt)
				? BuiltinBinary.bitwiseAndNat32
				: isNat64(rt)
				? BuiltinBinary.bitwiseAndNat64
				: failBinary);
		case symbol!"~".value:
			return unary(isNat8(rt)
				? BuiltinUnary.bitwiseNotNat8
				: isNat16(rt)
				? BuiltinUnary.bitwiseNotNat16
				: isNat32(rt)
				? BuiltinUnary.bitwiseNotNat32
				: isNat64(rt)
				? BuiltinUnary.bitwiseNotNat64
				: failUnary);
		case symbol!"|".value:
			return binary(isInt8(rt)
				? BuiltinBinary.bitwiseOrInt8
				: isInt16(rt)
				? BuiltinBinary.bitwiseOrInt16
				: isInt32(rt)
				? BuiltinBinary.bitwiseOrInt32
				: isInt64(rt)
				? BuiltinBinary.bitwiseOrInt64
				: isNat8(rt)
				? BuiltinBinary.bitwiseOrNat8
				: isNat16(rt)
				? BuiltinBinary.bitwiseOrNat16
				: isNat32(rt)
				? BuiltinBinary.bitwiseOrNat32
				: isNat64(rt)
				? BuiltinBinary.bitwiseOrNat64
				: failBinary);
		case symbol!"^".value:
			return binary(isInt8(rt)
				? BuiltinBinary.bitwiseXorInt8
				: isInt16(rt)
				? BuiltinBinary.bitwiseXorInt16
				: isInt32(rt)
				? BuiltinBinary.bitwiseXorInt32
				: isInt64(rt)
				? BuiltinBinary.bitwiseXorInt64
				: isNat8(rt)
				? BuiltinBinary.bitwiseXorNat8
				: isNat16(rt)
				? BuiltinBinary.bitwiseXorNat16
				: isNat32(rt)
				? BuiltinBinary.bitwiseXorNat32
				: isNat64(rt)
				? BuiltinBinary.bitwiseXorNat64
				: failBinary);
		case symbol!"acos".value:
			return unaryMath(BuiltinUnaryMath.acosFloat32, BuiltinUnaryMath.acosFloat64);
		case symbol!"acosh".value:
			return unaryMath(BuiltinUnaryMath.acoshFloat32, BuiltinUnaryMath.acoshFloat64);
		case symbol!"all-tests".value:
			return arity == 0 ? FunBody(BuiltinFun(BuiltinFun.AllTests())) : fail();
		case symbol!"asin".value:
			return unaryMath(BuiltinUnaryMath.asinFloat32, BuiltinUnaryMath.asinFloat64);
		case symbol!"asinh".value:
			return unaryMath(BuiltinUnaryMath.asinhFloat32, BuiltinUnaryMath.asinhFloat64);
		case symbol!"atan".value:
			return unaryMath(BuiltinUnaryMath.atanFloat32, BuiltinUnaryMath.atanFloat64);
		case symbol!"atan2".value:
			return binaryMath(BuiltinBinaryMath.atan2Float32, BuiltinBinaryMath.atan2Float64);
		case symbol!"atanh".value:
			return unaryMath(BuiltinUnaryMath.atanhFloat32, BuiltinUnaryMath.atanhFloat64);
		case symbol!"as-const".value:
		case symbol!"as-fun-pointer".value:
		case symbol!"as-mut".value:
		case symbol!"pointer-cast".value:
			return FunBody(BuiltinFun(BuiltinFun.PointerCast()));
		case symbol!"count-ones".value:
			return unary(isNat64(p0)
				? BuiltinUnary.countOnesNat64
				: failUnary);
		case symbol!"cos".value:
			return unaryMath(BuiltinUnaryMath.cosFloat32, BuiltinUnaryMath.cosFloat64);
		case symbol!"cosh".value:
			return unaryMath(BuiltinUnaryMath.coshFloat32, BuiltinUnaryMath.coshFloat64);
		case symbol!"false".value:
			return FunBody(BuiltinFun(constantBool(false)));
		case symbol!"infinity".value:
			return constant(isFloat32Or64(rt), Constant(Constant.Float(double.infinity)));
		case symbol!"interpreter-backtrace".value:
			return ternary(BuiltinTernary.interpreterBacktrace);
		case symbol!"is-less".value:
			return binary(
				isInt8(p0) ? BuiltinBinary.lessInt8 :
				isInt16(p0) ? BuiltinBinary.lessInt16 :
				isInt32(p0) ? BuiltinBinary.lessInt32 :
				isInt64(p0) ? BuiltinBinary.lessInt64 :
				isNat8(p0) ? BuiltinBinary.lessNat8 :
				isNat16(p0) ? BuiltinBinary.lessNat16 :
				isNat32(p0) ? BuiltinBinary.lessNat32 :
				isNat64(p0) ? BuiltinBinary.lessNat64 :
				isFloat32(p0) ? BuiltinBinary.lessFloat32 :
				isFloat64(p0) ? BuiltinBinary.lessFloat64 :
				isPointerConstOrMut(p0) ? BuiltinBinary.lessPointer :
				failBinary);
		case symbol!"is-nan".value:
			return unary(
				isBool(rt) && isFloat32(p0) ? BuiltinUnary.isNanFloat32 :
				isBool(rt) && isFloat64(p0) ? BuiltinUnary.isNanFloat64 :
				failUnary());
		case symbol!"mark-root".value:
			return FunBody(BuiltinFun(BuiltinFun.MarkRoot()));
		case symbol!"mark-visit".value:
			// TODO: check signature
			return FunBody(BuiltinFun(BuiltinFun.MarkVisit()));
		case symbol!"nan".value:
			return constant(isFloat32Or64(rt), Constant(Constant.Float(double.nan)));
		case symbol!"new-array".value:
			return isArray(rt) && isNat64(p0) && isPointerConst(p1)
				? binary(BuiltinBinary.newArray)
				: fail();
		case symbol!"new-mut-array".value:
			return isMutArray(rt) && isNat64(p0) && isPointerMut(p1)
				? binary(BuiltinBinary.newArray)
				: fail();
		case symbol!"jump-to-catch".value:
			return unary(BuiltinUnary.jumpToCatch);
		case symbol!"new-void".value:
			return constant(isVoid(rt), constantZero);
		case symbol!"null".value: // TODO: REMOVE (use zeroed) ------------------------------------------------------------------------------
			return isJsAny(rt) && arity == 0
				? FunBody(BuiltinFun(JsFun.null_))
				: constant(isPointerConstOrMut(rt), constantZero);
		case symbol!"reference-equal".value:
			return binary(BuiltinBinary.referenceEqual);
		case symbol!"round".value:
			return unaryMath(BuiltinUnaryMath.roundFloat32, BuiltinUnaryMath.roundFloat64);
		case symbol!"set-deref".value:
			return binary(isBuiltin(p0, BuiltinType.pointerMut) ? BuiltinBinary.writeToPointer : failBinary);
		case symbol!"setup-catch".value:
			return unary(BuiltinUnary.setupCatch);
		case symbol!"sin".value:
			return unaryMath(BuiltinUnaryMath.sinFloat32, BuiltinUnaryMath.sinFloat64);
		case symbol!"sinh".value:
			return unaryMath(BuiltinUnaryMath.sinhFloat32, BuiltinUnaryMath.sinhFloat64);
		case symbol!"size-of".value:
			return FunBody(BuiltinFun(BuiltinFun.SizeOf()));
		case symbol!"subscript".value:
			// TODO: check signature
			return isBuiltin(p0, BuiltinType.funPointer)
				? FunBody(BuiltinFun(BuiltinFun.CallFunPointer()))
				: isBuiltin(p0, BuiltinType.lambda)
				? FunBody(BuiltinFun(BuiltinFun.CallLambda()))
				: fail();
		case symbol!"sqrt".value:
			return unaryMath(BuiltinUnaryMath.sqrtFloat32, BuiltinUnaryMath.sqrtFloat64);
		case symbol!"tan".value:
			return unaryMath(BuiltinUnaryMath.tanFloat32, BuiltinUnaryMath.tanFloat64);
		case symbol!"tanh".value:
			return unaryMath(BuiltinUnaryMath.tanhFloat32, BuiltinUnaryMath.tanhFloat64);
		case symbol!"to".value:
			return unary(isChar8(rt)
				? isNat8(p0)
					? BuiltinUnary.toChar8FromNat8
					: failUnary
			: isChar8Array(rt)
				? isString(p0)
					? BuiltinUnary.toChar8ArrayFromString
					: failUnary
			: isFloat32(rt)
				? isFloat64(p0)
					? BuiltinUnary.toFloat32FromFloat64
					: failUnary
			: isFloat64(rt)
				? isInt64(p0)
					? BuiltinUnary.toFloat64FromInt64
					: isNat64(p0)
					? BuiltinUnary.toFloat64FromNat64
					: isFloat32(p0)
					? BuiltinUnary.toFloat64FromFloat32
					: failUnary
			: isInt64(rt)
				? isInt8(p0)
					? BuiltinUnary.toInt64FromInt8
					: isInt16(p0)
					? BuiltinUnary.toInt64FromInt16
					: isInt32(p0)
					? BuiltinUnary.toInt64FromInt32
					: failUnary
			: isNat8(rt)
				? isChar8(p0)
					? BuiltinUnary.toNat8FromChar8
					: failUnary
			: isNat32(rt)
				? isChar32(p0)
					? BuiltinUnary.toNat32FromChar32
					: failUnary
			: isNat64(rt)
				? isNat8(p0)
					? BuiltinUnary.toNat64FromNat8
					: isNat16(p0)
					? BuiltinUnary.toNat64FromNat16
					: isNat32(p0)
					? BuiltinUnary.toNat64FromNat32
					: isPointerConstOrMut(p0)
					? BuiltinUnary.toNat64FromPtr
					: failUnary
			: failUnary);
		case symbol!"to-mut-pointer".value:
			return unary(isNat64(p0)
				? BuiltinUnary.toPtrFromNat64
				: failUnary);
		case symbol!"true".value:
			return constant(isBool(rt), constantBool(true));
		case symbol!"trust-as-string".value:
			return unary(isString(rt) && isChar8Array(p0)
				? BuiltinUnary.trustAsString
				: failUnary);
		case symbol!"unsafe-add".value:
			return binary(isInt8(rt)
				? BuiltinBinary.unsafeAddInt8
				: isInt16(rt)
				? BuiltinBinary.unsafeAddInt16
				: isInt32(rt)
				? BuiltinBinary.unsafeAddInt32
				: isInt64(rt)
				? BuiltinBinary.unsafeAddInt64
				: isNat8(rt)
				? BuiltinBinary.unsafeAddNat8
				: isNat16(rt)
				? BuiltinBinary.unsafeAddNat16
				: isNat32(rt)
				? BuiltinBinary.unsafeAddNat32
				: isNat64(rt)
				? BuiltinBinary.unsafeAddNat64
				: failBinary);
		case symbol!"unsafe-div".value:
			return binary(isFloat32(rt)
				? BuiltinBinary.unsafeDivFloat32
				: isBinaryFloat64()
				? BuiltinBinary.unsafeDivFloat64
				: isInt8(rt)
				? BuiltinBinary.unsafeDivInt8
				: isInt16(rt)
				? BuiltinBinary.unsafeDivInt16
				: isInt32(rt)
				? BuiltinBinary.unsafeDivInt32
				: isInt64(rt)
				? BuiltinBinary.unsafeDivInt64
				: isNat8(rt)
				? BuiltinBinary.unsafeDivNat8
				: isNat16(rt)
				? BuiltinBinary.unsafeDivNat16
				: isNat32(rt)
				? BuiltinBinary.unsafeDivNat32
				: isNat64(rt)
				? BuiltinBinary.unsafeDivNat64
				: failBinary);
		case symbol!"unsafe-log".value:
			return unaryMath(BuiltinUnaryMath.unsafeLogFloat32, BuiltinUnaryMath.unsafeLogFloat64);
		case symbol!"unsafe-mod".value:
			return isNat64(rt) ? binary(BuiltinBinary.unsafeModNat64) : fail();
		case symbol!"unsafe-mul".value:
			return binary(isInt8(rt)
				? BuiltinBinary.unsafeMulInt8
				: isInt16(rt)
				? BuiltinBinary.unsafeMulInt16
				: isInt32(rt)
				? BuiltinBinary.unsafeMulInt32
				: isInt64(rt)
				? BuiltinBinary.unsafeMulInt64
				: isNat8(rt)
				? BuiltinBinary.unsafeMulNat8
				: isNat16(rt)
				? BuiltinBinary.unsafeMulNat16
				: isNat32(rt)
				? BuiltinBinary.unsafeMulNat32
				: isNat64(rt)
				? BuiltinBinary.unsafeMulNat64
				: failBinary);
		case symbol!"unsafe-sub".value:
			return binary(isInt8(rt)
				? BuiltinBinary.unsafeSubInt8
				: isInt16(rt)
				? BuiltinBinary.unsafeSubInt16
				: isInt32(rt)
				? BuiltinBinary.unsafeSubInt32
				: isInt64(rt)
				? BuiltinBinary.unsafeSubInt64
				: isNat8(rt)
				? BuiltinBinary.unsafeSubNat8
				: isNat16(rt)
				? BuiltinBinary.unsafeSubNat16
				: isNat32(rt)
				? BuiltinBinary.unsafeSubNat32
				: isNat64(rt)
				? BuiltinBinary.unsafeSubNat64
				: failBinary);
		case symbol!"wrap-add".value:
			return binary(isNat8(rt)
				? BuiltinBinary.wrapAddNat8
				: isNat16(rt)
				? BuiltinBinary.wrapAddNat16
				: isNat32(rt)
				? BuiltinBinary.wrapAddNat32
				: isNat64(rt)
				? BuiltinBinary.wrapAddNat64
				: failBinary);
		case symbol!"wrap-mul".value:
			return binary(isNat8(rt)
				? BuiltinBinary.wrapMulNat8
				: isNat16(rt)
				? BuiltinBinary.wrapMulNat16
				: isNat32(rt)
				? BuiltinBinary.wrapMulNat32
				: isNat64(rt)
				? BuiltinBinary.wrapMulNat64
				: failBinary);
		case symbol!"wrap-sub".value:
			return binary(isNat8(rt)
				? BuiltinBinary.wrapSubNat8
				: isNat16(rt)
				? BuiltinBinary.wrapSubNat16
				: isNat32(rt)
				? BuiltinBinary.wrapSubNat32
				: isNat64(rt)
				? BuiltinBinary.wrapSubNat64
				: failBinary);
		case symbol!"zeroed".value:
			return FunBody(BuiltinFun(BuiltinFun.Zeroed())); // constant(true, constantZero); -----------------------------------------------------------------------------------------------------
		case symbol!"as-any-mut-pointer".value:
			return unary(BuiltinUnary.asAnyPointer);
		case symbol!"global-init".value:
			return arity == 0 ? FunBody(BuiltinFun(BuiltinFun.Init(BuiltinFun.Init.Kind.global))) : fail();
		case symbol!"per-thread-init".value:
			return arity == 0 ? FunBody(BuiltinFun(BuiltinFun.Init(BuiltinFun.Init.Kind.perThread))) : fail();
		case symbol!"reference-from-pointer".value:
			return unary(BuiltinUnary.referenceFromPointer);
		case symbol!"pointer-cast-from-extern".value:
		case symbol!"pointer-cast-to-extern".value:
			return FunBody(BuiltinFun(BuiltinFun.PointerCast()));
		case symbol!"static-symbols".value:
			return FunBody(BuiltinFun(BuiltinFun.StaticSymbols()));
		case symbol!"switch-fiber".value:
			return binary(BuiltinBinary.switchFiber);
		case symbol!"switch-fiber-initial".value:
			return fourary(Builtin4ary.switchFiberInitial);
		case symbol!"truncate-to".value:
			return unary(isFloat64(p0)
				? BuiltinUnary.truncateToInt64FromFloat64
				: failUnary);
		case symbol!"unsafe-bit-shift-left".value:
			return isNat64(rt) ? binary(BuiltinBinary.unsafeBitShiftLeftNat64) : fail();
		case symbol!"unsafe-bit-shift-right".value:
			return isNat64(rt)
				? binary(BuiltinBinary.unsafeBitShiftRightNat64)
				: fail();
		case symbol!"unsafe-to".value:
			return unary(
				isChar32(rt)
					? isNat32(p0)
						? BuiltinUnary.unsafeToChar32FromNat32
						: isChar8(p0)
						? BuiltinUnary.unsafeToChar32FromChar8
						: failUnary
				: isInt8(rt)
					? isInt64(p0)
						? BuiltinUnary.unsafeToInt8FromInt64
						: failUnary
				: isInt16(rt)
					? isInt64(p0)
						? BuiltinUnary.unsafeToInt16FromInt64
						: failUnary
				: isInt32(rt)
					? isInt64(p0)
						? BuiltinUnary.unsafeToInt32FromInt64
						: failUnary
				: isInt64(rt)
					? isNat64(p0)
						? BuiltinUnary.unsafeToInt64FromNat64
						: failUnary
				: isNat8(rt)
					? isNat64(p0)
						? BuiltinUnary.unsafeToNat8FromNat64
						: failUnary
				: isNat16(rt)
					? isNat64(p0)
						? BuiltinUnary.unsafeToNat16FromNat64
						: failUnary
				: isNat32(rt)
					? isInt32(p0)
						? BuiltinUnary.unsafeToNat32FromInt32
						: isNat64(p0)
						? BuiltinUnary.unsafeToNat32FromNat64
						: failUnary
				: isNat64(rt)
					? isInt64(p0)
						? BuiltinUnary.unsafeToNat64FromInt64
						: failUnary
				: failUnary);
		default:
			Opt!VersionFun version_ = versionFunFromSymbol(name);
			return has(version_) && arity == 0 ? FunBody(BuiltinFun(force(version_))) : fail();
	}
}

bool isJsObjectKey(in CommonTypes commonTypes, in Type a) =>
	isNat64(a) || isString(a);

bool isBuiltin(in Type a, BuiltinType b) =>
	a.isA!(StructInst*) &&
	a.as!(StructInst*).decl.body_.isA!BuiltinType &&
	a.as!(StructInst*).decl.body_.as!BuiltinType == b;

bool isBool(in Type a) =>
	isBuiltin(a, BuiltinType.bool_);

bool isChar8(in Type a) =>
	isBuiltin(a, BuiltinType.char8);

bool isChar32(in Type a) =>
	isBuiltin(a, BuiltinType.char32);

bool isInt8(in Type a) =>
	isBuiltin(a, BuiltinType.int8);

bool isInt16(in Type a) =>
	isBuiltin(a, BuiltinType.int16);

bool isInt32(in Type a) =>
	isBuiltin(a, BuiltinType.int32);

bool isInt64(in Type a) =>
	isBuiltin(a, BuiltinType.int64);

bool isNat8(in Type a) =>
	isBuiltin(a, BuiltinType.nat8);

bool isNat16(in Type a) =>
	isBuiltin(a, BuiltinType.nat16);

bool isNat32(in Type a) =>
	isBuiltin(a, BuiltinType.nat32);

bool isNat64(in Type a) =>
	isBuiltin(a, BuiltinType.nat64);

bool isFloat32Or64(in Type a) =>
	isFloat32(a) || isFloat64(a);

bool isFloat32(in Type a) =>
	isBuiltin(a, BuiltinType.float32);

bool isFloat64(in Type a) =>
	isBuiltin(a, BuiltinType.float64);

bool isJsAny(in Type a) =>
	isBuiltin(a, BuiltinType.jsAny);

bool isChar8Array(in Type a) =>
	isArray(a) && isChar8(arrayElementType(a));
bool isTypeParam0Array(in Type a) =>
	isArray(a) && isTypeParam0(arrayElementType(a));
bool isJsAnyArray(in Type a) =>
	isArray(a) && isJsAny(arrayElementType(a));

bool isPointerConstOrMut(in Type a) =>
	isBuiltin(a, BuiltinType.pointerConst) || isBuiltin(a, BuiltinType.pointerMut);
bool isPointerConst(in Type a) =>
	isBuiltin(a, BuiltinType.pointerConst); // TODO: this should be in model.d ----------------------------------------------------
bool isPointerMut(in Type a) =>
	isBuiltin(a, BuiltinType.pointerMut); // TODO: this should be in model.d ----------------------------------------------------

bool isCString(in Type a) =>
	isPointerConst(a) && isChar8(pointeeType(a));

bool isTypeParam0(in Type a) =>
	a.isA!TypeParamIndex && a.as!TypeParamIndex.index == 0;
bool isTypeParam1(in Type a) =>
	a.isA!TypeParamIndex && a.as!TypeParamIndex.index == 1;

bool isVoid(in Type a) => // TODO: this should be in model.d -----------------------------------------------------------------------
	isBuiltin(a, BuiltinType.void_);

Opt!VersionFun versionFunFromSymbol(Symbol name) {
	switch (name.value) {
		case symbol!"is-big-endian".value:
			return some(VersionFun.isBigEndian);
		case symbol!"is-interpreted".value:
			return some(VersionFun.isInterpreted);
		case symbol!"is-jit".value:
			return some(VersionFun.isJit);
		case symbol!"is-single-threaded".value:
			return some(VersionFun.isSingleThreaded);
		case symbol!"is-stack-trace-enabled".value:
			return some(VersionFun.isStackTraceEnabled);
		case symbol!"is-wasm".value:
			return some(VersionFun.isWasm);
		case symbol!"is-windows".value:
			return some(VersionFun.isWindows);
		default:
			return none!VersionFun;
	}
}
