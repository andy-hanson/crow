module frontend.check.getBuiltinFun;

@safe @nogc pure nothrow:

import frontend.check.checkCall.checkCallSpecs : isEnumOrFlags, isFlags;
import frontend.check.checkCtx : addDiag, CheckCtx;
import model.constant : constantBool, constantZero;
import model.diag : Diag;
import model.model :
	BuiltinBinary,
	BuiltinBinaryMath,
	BuiltinFun,
	BuiltinType,
	BuiltinUnary,
	BuiltinUnaryMath,
	BuiltinTernary,
	Destructure,
	EnumFunction,
	FlagsFunction,
	FunBody,
	FunDecl,
	nameRange,
	paramsArray,
	SpecInst,
	StructInst,
	Type;
import util.opt : force, has, none, Opt, some;
import util.sourceRange : Range;
import util.symbol : Symbol, symbol;
import versionInfo : VersionFun;

FunBody getBuiltinFun(ref CheckCtx ctx, FunDecl* fun) {
	Destructure[] params = paramsArray(fun.params);
	return inner(
		ctx, fun.nameRange.range, fun.name, fun.returnType, params.length,
		params.length >= 1 ? params[0].type : Type(Type.Bogus()),
		params.length >= 2 ? params[1].type : Type(Type.Bogus()),
		fun.specs);
}

private:

FunBody inner(
	ref CheckCtx ctx,
	in Range range,
	Symbol name,
	Type rt,
	size_t arity,
	Type p0,
	Type p1,
	in SpecInst*[] specs,
) {
	BuiltinUnary failUnary = cast(BuiltinUnary) 0xff;
	BuiltinBinary failBinary = cast(BuiltinBinary) 0xff;

	FunBody fail() {
		addDiag(ctx, range, Diag(Diag.BuiltinUnsupported(Diag.BuiltinUnsupported.Kind.function_, name)));
		return FunBody(FunBody.Bogus());
	}
	FunBody unary(BuiltinUnary kind) =>
		arity == 1 && kind != failUnary ? FunBody(BuiltinFun(kind)) : fail();
	FunBody binary(BuiltinBinary kind) =>
		arity == 2 && kind != failBinary ? FunBody(BuiltinFun(kind)) : fail();

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

	switch (name.value) {
		case symbol!"+".value:
			return binary(isFloat32(rt)
				? BuiltinBinary.addFloat32
				: isBinaryFloat64()
				? BuiltinBinary.addFloat64
				: isPointerConstOrMut(rt) && isPointerConstOrMut(p0) && isNat64(p1)
				? BuiltinBinary.addPtrAndNat64
				: failBinary);
		case symbol!"-".value:
			return binary(isFloat32(rt)
				? BuiltinBinary.subFloat32
				: isBinaryFloat64()
				? BuiltinBinary.subFloat64
				: isPointerConstOrMut(rt) && isPointerConstOrMut(p0) && isNat64(p1)
				? BuiltinBinary.subPtrAndNat64
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
			return isEnumOrFlags(specs, p0) ? FunBody(EnumFunction.equal) : binary(
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
				isPointerConstOrMut(p0) ? BuiltinBinary.eqPtr :
				failBinary);
		case symbol!"&&".value:
			return binary(BuiltinBinary.and);
		case symbol!"||".value:
			return isBool(rt)
				? binary(BuiltinBinary.orBool)
				: FunBody(BuiltinFun(BuiltinFun.OptOr()));
		case symbol!"??".value:
			return FunBody(BuiltinFun(BuiltinFun.OptQuestion2()));
		case symbol!"&".value:
			return isFlags(specs, rt) ? FunBody(EnumFunction.intersect) : binary(isInt8(rt)
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
			return isFlags(specs, rt) ? FunBody(FlagsFunction.negate) : unary(isNat8(rt)
				? BuiltinUnary.bitwiseNotNat8
				: isNat16(rt)
				? BuiltinUnary.bitwiseNotNat16
				: isNat32(rt)
				? BuiltinUnary.bitwiseNotNat32
				: isNat64(rt)
				? BuiltinUnary.bitwiseNotNat64
				: failUnary);
		case symbol!"|".value:
			return isFlags(specs, rt) ? FunBody(EnumFunction.union_) : binary(isInt8(rt)
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
		case symbol!"all".value:
			return isFlags(specs, rt) ? FunBody(FlagsFunction.all) : fail();
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
		case symbol!"enum-members".value:
		case symbol!"flags-members".value:
			return FunBody(EnumFunction.members);
		case symbol!"false".value:
			return FunBody(BuiltinFun(constantBool(false)));
		case symbol!"interpreter-backtrace".value:
			return FunBody(BuiltinFun(BuiltinTernary.interpreterBacktrace));
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
				isPointerConstOrMut(p0) ? BuiltinBinary.lessPtr :
				failBinary);
		case symbol!"mark-visit".value:
			// TODO: check signature
			return FunBody(BuiltinFun(BuiltinFun.MarkVisit()));
		case symbol!"new".value:
			return isFlags(specs, rt) ? FunBody(FlagsFunction.new_) : fail();
		case symbol!"new-void".value:
			return isVoid(rt)
				? FunBody(BuiltinFun(constantZero))
				: fail();
		case symbol!"null".value:
			return FunBody(BuiltinFun(constantZero));
		case symbol!"reference-equal".value:
			return binary(BuiltinBinary.eqPtr);
		case symbol!"round".value:
			return unaryMath(BuiltinUnaryMath.roundFloat32, BuiltinUnaryMath.roundFloat64);
		case symbol!"set-deref".value:
			return binary(isBuiltin(p0, BuiltinType.pointerMut) ? BuiltinBinary.writeToPtr : failBinary);
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
			return FunBody(BuiltinFun(constantBool(true)));
		case symbol!"unsafe-add".value:
			return binary(isInt8(rt)
				? BuiltinBinary.unsafeAddInt8
				: isInt16(rt)
				? BuiltinBinary.unsafeAddInt16
				: isInt32(rt)
				? BuiltinBinary.unsafeAddInt32
				: isInt64(rt)
				? BuiltinBinary.unsafeAddInt64
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
			return FunBody(BuiltinFun(constantZero));
		case symbol!"as-any-mut-pointer".value:
			return unary(BuiltinUnary.asAnyPtr);
		case symbol!"init-constants".value:
			return FunBody(BuiltinFun(BuiltinFun.InitConstants()));
		case symbol!"pointer-cast-from-extern".value:
		case symbol!"pointer-cast-to-extern".value:
			return FunBody(BuiltinFun(BuiltinFun.PointerCast()));
		case symbol!"static-symbols".value:
			return FunBody(BuiltinFun(BuiltinFun.StaticSymbols()));
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

bool isFloat32(in Type a) =>
	isBuiltin(a, BuiltinType.float32);

bool isFloat64(in Type a) =>
	isBuiltin(a, BuiltinType.float64);

bool isPointerConstOrMut(in Type a) =>
	isBuiltin(a, BuiltinType.pointerConst) || isBuiltin(a, BuiltinType.pointerMut);

bool isVoid(in Type a) =>
	isBuiltin(a, BuiltinType.void_);

Opt!VersionFun versionFunFromSymbol(Symbol name) {
	switch (name.value) {
		case symbol!"is-abort-on-throw".value:
			return some(VersionFun.isAbortOnThrow);
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
