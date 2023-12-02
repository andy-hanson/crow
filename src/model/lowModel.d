module model.lowModel;

@safe @nogc pure nothrow:

import model.concreteModel :
	ConcreteField,
	ConcreteFun,
	concreteFunRange,
	ConcreteStruct,
	ConcreteStructSource,
	ConcreteVar,
	isArray,
	isTuple,
	name,
	typeSize,
	TypeSize;
import model.constant : Constant;
import model.model : body_, decl, EnumValue, Local, StructBody;
import util.col.arr : empty;
import util.col.map : Map;
import util.col.fullIndexMap : FullIndexMap;
import util.col.str : SafeCStr;
import util.hash : hash2, HashCode, hashEnum, hashSizeT;
import util.opt : has, none, Opt;
import util.sourceRange : UriAndRange;
import util.sym : Sym, sym;
import util.union_ : Union;
import util.uri : Uri;

immutable struct LowExternType {
	ConcreteStruct* source;
}

TypeSize typeSize(in LowExternType a) =>
	typeSize(*a.source);

immutable struct LowRecord {
	@safe @nogc pure nothrow:

	ConcreteStruct* source;
	LowField[] fields;

	//TODO:MOVE
	bool packed() scope =>
		source.source.matchIn!bool(
			(in ConcreteStructSource.Bogus) =>
				false,
			(in ConcreteStructSource.Inst it) =>
				body_(*decl(*it.inst)).as!(StructBody.Record).flags.packed,
			(in ConcreteStructSource.Lambda) =>
				false);
}

TypeSize typeSize(in LowRecord a) =>
	typeSize(*a.source);

bool isArray(in LowRecord a) =>
	isArray(*a.source);
bool isTuple(in LowRecord a) =>
	isTuple(*a.source);

immutable struct LowUnion {
	ConcreteStruct* source;
	LowType[] members;
}

TypeSize typeSize(in LowUnion a) =>
	typeSize(*a.source);

immutable struct LowFunPtrType {
	ConcreteStruct* source;
	LowType returnType;
	LowType[] paramTypes;
}

alias PrimitiveType = immutable PrimitiveType_;
private enum PrimitiveType_ {
	bool_,
	char8,
	float32,
	float64,
	int8,
	int16,
	int32,
	int64,
	nat8,
	nat16,
	nat32,
	nat64,
	void_,
}

Sym symOfPrimitiveType(PrimitiveType a) {
	final switch (a) {
		case PrimitiveType.bool_:
			return sym!"bool";
		case PrimitiveType.char8:
			return sym!"char8";
		case PrimitiveType.float32:
			return sym!"float-32";
		case PrimitiveType.float64:
			return sym!"float-64";
		case PrimitiveType.int8:
			return sym!"int-8";
		case PrimitiveType.int16:
			return sym!"int-16";
		case PrimitiveType.int32:
			return sym!"int-32";
		case PrimitiveType.int64:
			return sym!"int-64";
		case PrimitiveType.nat8:
			return sym!"nat-8";
		case PrimitiveType.nat16:
			return sym!"nat-16";
		case PrimitiveType.nat32:
			return sym!"nat-32";
		case PrimitiveType.nat64:
			return sym!"nat-64";
		case PrimitiveType.void_:
			return sym!"void";
	}
}

immutable struct LowType {
	@safe @nogc pure nothrow:

	immutable struct Extern {
		size_t index;
	}
	immutable struct FunPtr {
		size_t index;
	}
	// May be gc-allocated or not; gc will try to trace
	immutable struct PtrGc {
		LowType* pointee;
	}
	immutable struct PtrRawConst {
		LowType* pointee;
	}
	immutable struct PtrRawMut {
		LowType* pointee;
	}
	immutable struct Record {
		size_t index;
	}
	immutable struct Union {
		size_t index;
	}

	mixin .Union!(
		Extern,
		FunPtr,
		PrimitiveType,
		PtrGc,
		PtrRawConst,
		PtrRawMut,
		Record,
		Union);

	bool opEquals(scope LowType b) scope =>
		matchIn!bool(
			(in Extern x) =>
				b.isA!Extern && b.as!Extern.index == x.index,
			(in FunPtr x) =>
				b.isA!FunPtr && b.as!FunPtr.index == x.index,
			(in PrimitiveType x) =>
				b.isA!PrimitiveType && b.as!PrimitiveType == x,
			(in PtrGc x) =>
				b.isA!PtrGc && *b.as!PtrGc.pointee == *x.pointee,
			(in PtrRawConst x) =>
				b.isA!PtrRawConst && *b.as!PtrRawConst.pointee == *x.pointee,
			(in PtrRawMut x) =>
				b.isA!PtrRawMut && *b.as!PtrRawMut.pointee == *x.pointee,
			(in Record x) =>
				b.isA!Record && b.as!Record.index == x.index,
			(in Union x) =>
				b.isA!Union && b.as!Union.index == x.index);

	HashCode hash() scope =>
		hash2(kind, matchIn!HashCode(
			(in Extern x) =>
				hashSizeT(x.index),
			(in FunPtr x) =>
				hashSizeT(x.index),
			(in PrimitiveType x) =>
				hashEnum(x),
			(in PtrGc x) =>
				x.pointee.hash(),
			(in PtrRawConst x) =>
				x.pointee.hash(),
			(in PtrRawMut x) =>
				x.pointee.hash(),
			(in Record x) =>
				hashSizeT(x.index),
			(in Union x) =>
				hashSizeT(x.index)));

	LowTypeCombinePointer combinePointer() return scope =>
		match!LowTypeCombinePointer(
			(LowType.Extern x) =>
				LowTypeCombinePointer(x),
			(LowType.FunPtr x) =>
				LowTypeCombinePointer(x),
			(PrimitiveType x) =>
				LowTypeCombinePointer(x),
			(LowType.PtrGc x) =>
				LowTypeCombinePointer(LowPtrCombine(*x.pointee)),
			(LowType.PtrRawConst x) =>
				LowTypeCombinePointer(LowPtrCombine(*x.pointee)),
			(LowType.PtrRawMut x) =>
				LowTypeCombinePointer(LowPtrCombine(*x.pointee)),
			(LowType.Record x) =>
				LowTypeCombinePointer(x),
			(LowType.Union x) =>
				LowTypeCombinePointer(x));
}
static assert(LowType.sizeof <= 16);

bool lowTypeEqualCombinePtr(LowType a, LowType b) =>
	a == b || (isPtrGcOrRaw(a) && isPtrGcOrRaw(b) && asGcOrRawPointee(a) == asGcOrRawPointee(b));

bool isChar8(LowType a) =>
	a.isA!PrimitiveType && a.as!PrimitiveType == PrimitiveType.char8;

bool isVoid(LowType a) =>
	a.isA!PrimitiveType && a.as!PrimitiveType == PrimitiveType.void_;

bool isPtrRawConstOrMut(LowType a) =>
	a.isA!(LowType.PtrRawConst) || a.isA!(LowType.PtrRawMut);

bool isPtrGcOrRaw(LowType a) =>
	a.isA!(LowType.PtrGc) || isPtrRawConstOrMut(a);

@trusted LowType asGcOrRawPointee(return scope LowType a) =>
	a.combinePointer.as!LowPtrCombine.pointee;

immutable(LowType) asPtrGcPointee(LowType a) =>
	*a.as!(LowType.PtrGc).pointee;

immutable(LowType) asPtrRawPointee(LowType a) {
	assert(isPtrRawConstOrMut(a));
	return asGcOrRawPointee(a);
}

immutable struct LowPtrCombine {
	LowType pointee;
}

private immutable struct LowTypeCombinePointer {
	mixin Union!(LowType.Extern, LowType.FunPtr, PrimitiveType, LowPtrCombine, LowType.Record, LowType.Union);
}

bool isPrimitiveType(LowType a, PrimitiveType p) =>
	a.isA!PrimitiveType && a.as!PrimitiveType == p;

immutable struct LowField {
	ConcreteField* source;
	size_t offset;
	LowType type;
}

Sym debugName(in LowField a) =>
	a.source.debugName;

immutable struct LowLocalSource {
	immutable struct Generated {
		Sym name;
		size_t index;
	}
	mixin Union!(Local*, Generated*);
}
static assert(LowLocalSource.sizeof == ulong.sizeof);

immutable struct LowLocal {
	@safe @nogc pure nothrow:
	@disable this(ref const LowLocal);
	this(LowLocalSource s, LowType t) {
		source = s;
		type = t;
	}

	LowLocalSource source;
	LowType type;
}

immutable struct LowFunExprBody {
	bool hasTailRecur;
	LowExpr expr;
}

// Unlike ConcreteFunBody, this is always an expr or extern.
immutable struct LowFunBody {
	immutable struct Extern {
		Sym libraryName;
	}

	mixin Union!(Extern, LowFunExprBody);
}

immutable struct LowFunSource {
	immutable struct Generated {
		Sym name;
		LowType[] typeArgs;
	}

	mixin Union!(ConcreteFun*, Generated*);
}
static assert(LowFunSource.sizeof == ulong.sizeof);

immutable struct LowFun {
	@disable this(ref const LowFun);

	LowFunSource source;
	LowType returnType;
	// Includes closure param
	LowLocal[] params;
	LowFunBody body_;
}

bool isGeneratedMain(in LowFun a) =>
	a.source.matchIn!bool(
		(in ConcreteFun _) =>
			false,
		(in LowFunSource.Generated x) =>
			x.name == sym!"main");

Opt!Sym name(in LowFun a) =>
	a.source.matchIn!(Opt!Sym)(
		(in ConcreteFun x) => name(x),
		(in LowFunSource.Generated) => none!Sym);

UriAndRange lowFunRange(in LowFun a) =>
	a.source.matchIn!UriAndRange(
		(in ConcreteFun x) =>
			concreteFunRange(x),
		(in LowFunSource.Generated) =>
			UriAndRange.empty);

// TODO: use ConcreteExpr*
private alias LowExprSource = UriAndRange;

immutable struct LowExpr {
	LowType type;
	LowExprSource source;
	LowExprKind kind;
}

immutable struct LowFunIndex {
	@safe @nogc pure nothrow:

	size_t index;

	HashCode hash() scope =>
		HashCode(index);
}

immutable struct LowExprKind {
	immutable struct Call {
		LowFunIndex called;
		LowExpr[] args; // Includes implicit ctx arg if needed
	}

	immutable struct CallFunPtr {
		@safe @nogc pure nothrow:

		LowExpr funPtr;
		LowExpr[] args;
	}

	immutable struct CreateRecord {
		LowExpr[] args;
	}

	immutable struct CreateUnion {
		size_t memberIndex;
		LowExpr arg;
	}

	immutable struct If {
		LowExpr cond;
		LowExpr then;
		LowExpr else_;
	}

	immutable struct InitConstants {}

	immutable struct Let {
		// A heap-allocated mutable local will become a read-only local whose type is a gc-ptr
		LowLocal* local;
		LowExpr value;
		LowExpr then;
	}

	immutable struct LocalGet {
		LowLocal* local;
	}

	immutable struct LocalSet {
		LowLocal* local;
		LowExpr value;
	}

	immutable struct Loop {
		LowExpr body_;
	}

	immutable struct LoopBreak {
		LowExprKind.Loop* loop;
		LowExpr value;
	}

	immutable struct LoopContinue {
		LowExprKind.Loop* loop;
	}

	immutable struct MatchUnion {
		immutable struct Case {
			Opt!(LowLocal*) local;
			LowExpr then;
		}

		LowExpr matchedValue;
		Case[] cases;
	}

	immutable struct PtrCast {
		LowExpr target;
	}

	immutable struct PtrToField {
		LowExpr target;
		size_t fieldIndex;
	}

	immutable struct PtrToLocal {
		LowLocal* local;
	}

	immutable struct RecordFieldGet {
		LowExpr target; // Call 'targetIsPointer' to see if this is x.y or x->y
		size_t fieldIndex;
	}

	// No 'RecordFieldPointer', use 'PtrToField'

	immutable struct RecordFieldSet {
		LowExpr target;
		size_t fieldIndex;
		LowExpr value;
	}

	immutable struct SizeOf {
		LowType type;
	}

	immutable struct SpecialUnary {
		alias Kind = immutable Kind_;
		enum Kind_ {
			asAnyPtr,
			acosFloat64,
			acoshFloat64,
			asinFloat64,
			asinhFloat64,
			atanFloat64,
			atanhFloat64,
			bitwiseNotNat8,
			bitwiseNotNat16,
			bitwiseNotNat32,
			bitwiseNotNat64,
			countOnesNat64,
			cosFloat64,
			coshFloat64,
			deref,
			drop,
			enumToIntegral,
			roundFloat64,
			sinFloat64,
			sinhFloat64,
			sqrtFloat64,
			tanFloat64,
			tanhFloat64,
			toChar8FromNat8,
			toFloat32FromFloat64,
			toFloat64FromFloat32,
			toFloat64FromInt64,
			toFloat64FromNat64,
			toInt64FromInt8,
			toInt64FromInt16,
			toInt64FromInt32,
			toNat8FromChar8,
			toNat64FromNat8,
			toNat64FromNat16,
			toNat64FromNat32,
			toNat64FromPtr,
			toPtrFromNat64,
			truncateToInt64FromFloat64,
			unsafeToNat32FromInt32,
			unsafeToInt8FromInt64,
			unsafeToInt16FromInt64,
			unsafeToInt32FromInt64,
			unsafeToNat64FromInt64,
			unsafeToInt64FromNat64,
			unsafeToNat8FromNat64,
			unsafeToNat16FromNat64,
			unsafeToNat32FromNat64,
		}
		Kind kind;
		LowExpr arg;
	}

	immutable struct SpecialBinary {
		alias Kind = immutable Kind_;
		enum Kind_ {
			addFloat32,
			addFloat64,
			addPtrAndNat64, // RHS is multiplied by size of pointee first
			and,
			atan2Float64,
			bitwiseAndInt8,
			bitwiseAndInt16,
			bitwiseAndInt32,
			bitwiseAndInt64,
			bitwiseAndNat8,
			bitwiseAndNat16,
			bitwiseAndNat32,
			bitwiseAndNat64,
			bitwiseOrInt8,
			bitwiseOrInt16,
			bitwiseOrInt32,
			bitwiseOrInt64,
			bitwiseOrNat8,
			bitwiseOrNat16,
			bitwiseOrNat32,
			bitwiseOrNat64,
			bitwiseXorInt8,
			bitwiseXorInt16,
			bitwiseXorInt32,
			bitwiseXorInt64,
			bitwiseXorNat8,
			bitwiseXorNat16,
			bitwiseXorNat32,
			bitwiseXorNat64,
			eqFloat32,
			eqFloat64,
			eqInt8,
			eqInt16,
			eqInt32,
			eqInt64,
			eqNat8,
			eqNat16,
			eqNat32,
			eqNat64,
			eqPtr,
			lessChar8,
			lessFloat32,
			lessFloat64,
			lessInt8,
			lessInt16,
			lessInt32,
			lessInt64,
			lessNat8,
			lessNat16,
			lessNat32,
			lessNat64,
			lessPtr,
			mulFloat32,
			mulFloat64,
			orBool,
			seq,
			subFloat32,
			subFloat64,
			subPtrAndNat64, // RHS is multiplied by size of pointee first
			unsafeAddInt8,
			unsafeAddInt16,
			unsafeAddInt32,
			unsafeAddInt64,
			unsafeBitShiftLeftNat64,
			unsafeBitShiftRightNat64,
			unsafeDivFloat32,
			unsafeDivFloat64,
			unsafeDivInt8,
			unsafeDivInt16,
			unsafeDivInt32,
			unsafeDivInt64,
			unsafeDivNat8,
			unsafeDivNat16,
			unsafeDivNat32,
			unsafeDivNat64,
			unsafeModNat64,
			unsafeMulInt8,
			unsafeMulInt16,
			unsafeMulInt32,
			unsafeMulInt64,
			unsafeSubInt8,
			unsafeSubInt16,
			unsafeSubInt32,
			unsafeSubInt64,
			wrapAddNat8,
			wrapAddNat16,
			wrapAddNat32,
			wrapAddNat64,
			wrapMulNat8,
			wrapMulNat16,
			wrapMulNat32,
			wrapMulNat64,
			wrapSubNat8,
			wrapSubNat16,
			wrapSubNat32,
			wrapSubNat64,
			writeToPtr,
		}
		Kind kind;
		LowExpr[2] args;
	}

	immutable struct SpecialTernary {
		alias Kind = immutable Kind_;
		enum Kind_ { interpreterBacktrace }
		Kind kind;
		LowExpr[3] args;
	}

	immutable struct Switch0ToN {
		LowExpr value;
		LowExpr[] cases;
	}

	immutable struct SwitchWithValues {
		LowExpr value;
		EnumValue[] values;
		LowExpr[] cases;
	}

	immutable struct TailRecur {
		UpdateParam[] updateParams;
	}

	immutable struct VarGet {
		LowVarIndex varIndex;
	}
	immutable struct VarSet {
		LowVarIndex varIndex;
		LowExpr* value;
	}

	mixin Union!(
		Call,
		CallFunPtr*,
		CreateRecord,
		CreateUnion*,
		If*,
		InitConstants,
		Let*,
		LocalGet,
		LocalSet*,
		Loop*,
		LoopBreak*,
		LoopContinue,
		MatchUnion*,
		PtrCast*,
		PtrToField*,
		PtrToLocal,
		RecordFieldGet*,
		RecordFieldSet*,
		SizeOf,
		Constant,
		SpecialUnary*,
		SpecialBinary*,
		SpecialTernary*,
		Switch0ToN*,
		SwitchWithValues*,
		TailRecur,
		VarGet,
		VarSet);
}
static assert(LowExprKind.sizeof <= 32);

LowType.FunPtr funPtrType(in LowExprKind.CallFunPtr a) =>
	a.funPtr.type.as!(LowType.FunPtr);

LowType.Record targetRecordType(in LowExprKind.PtrToField a) =>
	asGcOrRawPointee(a.target.type).as!(LowType.Record);

bool targetIsPointer(in LowExprKind.RecordFieldGet a) =>
	isPtrGcOrRaw(a.target.type);

LowType.Record targetRecordType(in LowExprKind.RecordFieldGet a) =>
	(isPtrGcOrRaw(a.target.type) ? asGcOrRawPointee(a.target.type) : a.target.type).as!(LowType.Record);

//TODO: this is always true
bool targetIsPointer(in LowExprKind.RecordFieldSet a) =>
	isPtrGcOrRaw(a.target.type);

LowType.Record targetRecordType(in LowExprKind.RecordFieldSet a) =>
	asGcOrRawPointee(a.target.type).as!(LowType.Record);

immutable struct UpdateParam {
	LowLocal* param;
	LowExpr newValue;
}

immutable struct ArrTypeAndConstantsLow {
	@safe @nogc pure nothrow:

	@disable this(ref const ArrTypeAndConstantsLow);
	this(LowType.Record a, LowType e, immutable Constant[][] c) {
		arrType = a; elementType = e; constants = c;
	}

	LowType.Record arrType;
	LowType elementType;
	Constant[][] constants;
}

immutable struct PointerTypeAndConstantsLow {
	@safe @nogc pure nothrow:

	@disable this(ref const PointerTypeAndConstantsLow);
	this(LowType p, Constant[] c) {
		pointeeType = p; constants = c;
	}

	LowType pointeeType;
	Constant[] constants;
}

// TODO: rename -- this is not all constants, just the ones by-ref
immutable struct AllConstantsLow {
	SafeCStr[] cStrings;
	//TODO:FullIndexMap
	ArrTypeAndConstantsLow[] arrs;
	//TODO:FullIndexMap
	// These are just the by-ref records
	PointerTypeAndConstantsLow[] pointers;
}

alias ConcreteFunToLowFunIndex = Map!(ConcreteFun*, LowFunIndex);

immutable struct LowVarIndex {
	size_t index;
}

immutable struct LowVar {
	@safe @nogc pure nothrow:

	ConcreteVar* source;
	enum Kind {
		externGlobal,
		global,
		threadLocal,
	}
	Kind kind;
	LowType type;

	bool isExtern() scope =>
		has(externLibraryName);
	Opt!Sym externLibraryName() scope =>
		source.source.externLibraryName;
	Sym name() scope =>
		source.source.name;
}

immutable struct LowProgram {
	@safe @nogc pure nothrow:

	ConcreteFunToLowFunIndex concreteFunToLowFunIndex;
	AllConstantsLow allConstants;
	FullIndexMap!(LowVarIndex, LowVar) vars;
	AllLowTypes allTypes;
	FullIndexMap!(LowFunIndex, LowFun) allFuns;
	LowFunIndex main;
	ExternLibraries externLibraries;

	ref immutable(FullIndexMap!(LowType.Extern, LowExternType)) allExternTypes() scope return =>
		allTypes.allExternTypes;

	ref immutable(FullIndexMap!(LowType.FunPtr, LowFunPtrType)) allFunPtrTypes() scope return =>
		allTypes.allFunPtrTypes;

	ref immutable(FullIndexMap!(LowType.Record, LowRecord)) allRecords() scope return =>
		allTypes.allRecords;

	ref immutable(FullIndexMap!(LowType.Union, LowUnion)) allUnions() scope return =>
		allTypes.allUnions;
}

alias ExternLibraries = immutable ExternLibrary[];

immutable struct ExternLibrary {
	Sym libraryName;
	Opt!Uri configuredDir;
	Sym[] importNames;
}

immutable struct AllLowTypes {
	FullIndexMap!(LowType.Extern, LowExternType) allExternTypes;
	FullIndexMap!(LowType.FunPtr, LowFunPtrType) allFunPtrTypes;
	FullIndexMap!(LowType.Record, LowRecord) allRecords;
	FullIndexMap!(LowType.Union, LowUnion) allUnions;
}
