module model.lowModel;

@safe @nogc pure nothrow:

import model.concreteModel :
	ConcreteField,
	ConcreteFun,
	concreteFunRange,
	ConcreteLocal,
	ConcreteParam,
	ConcreteStruct,
	ConcreteStructSource,
	isArray,
	name,
	typeSize,
	TypeSize;
import model.constant : Constant;
import model.model : body_, EnumValue, StructBody;
import util.col.dict : Dict;
import util.col.fullIndexDict : FullIndexDict;
import util.col.str : SafeCStr;
import util.hash : Hasher, hashSizeT, hashUint;
import util.opt : none, Opt;
import util.path : Path;
import util.sourceRange : FileAndRange;
import util.sym : AllSymbols, Sym, sym;
import util.union_ : Union;
import util.util : verify;

struct LowExternType {
	immutable ConcreteStruct* source;
}

immutable(TypeSize) typeSize(ref immutable LowExternType a) =>
	typeSize(*a.source);

struct LowRecord {
	@safe @nogc pure nothrow:

	immutable ConcreteStruct* source;
	immutable LowField[] fields;

	//TODO:MOVE
	immutable(bool) packed() scope immutable =>
		source.source.match!(immutable bool)(
			(immutable ConcreteStructSource.Inst it) =>
				body_(*it.inst).as!(StructBody.Record).flags.packed,
			(immutable ConcreteStructSource.Lambda) =>
				false);
}

immutable(TypeSize) typeSize(ref immutable LowRecord a) =>
	typeSize(*a.source);

immutable(bool) isArray(ref immutable LowRecord a) =>
	isArray(*a.source);

struct LowUnion {
	immutable ConcreteStruct* source;
	immutable LowType[] members;
}

immutable(TypeSize) typeSize(ref immutable LowUnion a) =>
	typeSize(*a.source);

struct LowFunPtrType {
	immutable ConcreteStruct* source;
	immutable LowType returnType;
	immutable LowType[] paramTypes;
}

enum PrimitiveType {
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

immutable(Sym) symOfPrimitiveType(immutable PrimitiveType a) {
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

struct LowType {
	@safe @nogc pure nothrow:

	struct Extern {
		immutable size_t index;
	}
	struct FunPtr {
		immutable size_t index;
	}
	// May be gc-allocated or not; gc will try to trace
	struct PtrGc {
		immutable LowType* pointee;
	}
	struct PtrRawConst {
		immutable LowType* pointee;
	}
	struct PtrRawMut {
		immutable LowType* pointee;
	}
	struct Record {
		immutable size_t index;
	}
	struct Union {
		immutable size_t index;
	}

	mixin .Union!(
		immutable Extern,
		immutable FunPtr,
		immutable PrimitiveType,
		immutable PtrGc,
		immutable PtrRawConst,
		immutable PtrRawMut,
		immutable Record,
		immutable Union);

	immutable(bool) opEquals(scope immutable LowType b) scope immutable =>
		match!(immutable bool)(
			(immutable Extern x) =>
				b.isA!Extern && b.as!Extern.index == x.index,
			(immutable FunPtr x) =>
				b.isA!FunPtr && b.as!FunPtr.index == x.index,
			(immutable PrimitiveType x) =>
				b.isA!PrimitiveType && b.as!PrimitiveType == x,
			(immutable PtrGc x) =>
				b.isA!PtrGc && *b.as!PtrGc.pointee == *x.pointee,
			(immutable PtrRawConst x) =>
				b.isA!PtrRawConst && *b.as!PtrRawConst.pointee == *x.pointee,
			(immutable PtrRawMut x) =>
				b.isA!PtrRawMut && *b.as!PtrRawMut.pointee == *x.pointee,
			(immutable Record x) =>
				b.isA!Record && b.as!Record.index == x.index,
			(immutable Union x) =>
				b.isA!Union && b.as!Union.index == x.index);

	void hash(ref Hasher hasher) scope immutable {
		hashSizeT(hasher, kind);
		match!void(
			(immutable Extern x) {
				hashSizeT(hasher, x.index);
			},
			(immutable FunPtr x) {
				hashSizeT(hasher, x.index);
			},
			(immutable PrimitiveType x) {
				hashUint(hasher, x);
			},
			(immutable PtrGc x) {
				x.pointee.hash(hasher);
			},
			(immutable PtrRawConst x) {
				x.pointee.hash(hasher);
			},
			(immutable PtrRawMut x) {
				x.pointee.hash(hasher);
			},
			(immutable Record x) {
				hashSizeT(hasher, x.index);
			},
			(immutable Union x) {
				hashSizeT(hasher, x.index);
			});
	}

	immutable(LowTypeCombinePointer) combinePointer() return scope immutable =>
		match!(immutable LowTypeCombinePointer)(
			(immutable LowType.Extern x) =>
				immutable LowTypeCombinePointer(x),
			(immutable LowType.FunPtr x) =>
				immutable LowTypeCombinePointer(x),
			(immutable PrimitiveType x) =>
				immutable LowTypeCombinePointer(x),
			(immutable LowType.PtrGc x) =>
				immutable LowTypeCombinePointer(immutable LowPtrCombine(*x.pointee)),
			(immutable LowType.PtrRawConst x) =>
				immutable LowTypeCombinePointer(immutable LowPtrCombine(*x.pointee)),
			(immutable LowType.PtrRawMut x) =>
				immutable LowTypeCombinePointer(immutable LowPtrCombine(*x.pointee)),
			(immutable LowType.Record x) =>
				immutable LowTypeCombinePointer(x),
			(immutable LowType.Union x) =>
				immutable LowTypeCombinePointer(x));
}
static assert(LowType.sizeof <= 16);

immutable(bool) lowTypeEqualCombinePtr(immutable LowType a, immutable LowType b) =>
	a == b || (isPtrGcOrRaw(a) && isPtrGcOrRaw(b) && asGcOrRawPointee(a) == asGcOrRawPointee(b));

immutable(bool) isChar8(immutable LowType a) =>
	a.isA!PrimitiveType && a.as!PrimitiveType == PrimitiveType.char8;

immutable(bool) isVoid(immutable LowType a) =>
	a.isA!PrimitiveType && a.as!PrimitiveType == PrimitiveType.void_;

immutable(bool) isPtrRawConstOrMut(immutable LowType a) =>
	a.isA!(LowType.PtrRawConst) || a.isA!(LowType.PtrRawMut);

immutable(bool) isPtrGcOrRaw(immutable LowType a) =>
	a.isA!(LowType.PtrGc) || isPtrRawConstOrMut(a);

@trusted immutable(LowType) asGcOrRawPointee(return scope immutable LowType a) =>
	a.combinePointer.as!(LowPtrCombine).pointee;

immutable(LowType) asPtrGcPointee(immutable LowType a) =>
	*a.as!(LowType.PtrGc).pointee;

immutable(LowType) asPtrRawPointee(immutable LowType a) {
	verify(isPtrRawConstOrMut(a));
	return asGcOrRawPointee(a);
}

struct LowPtrCombine {
	immutable LowType pointee;
}

private struct LowTypeCombinePointer {
	mixin Union!(
		immutable LowType.Extern,
		immutable LowType.FunPtr,
		immutable PrimitiveType,
		immutable LowPtrCombine,
		immutable LowType.Record,
		immutable LowType.Union);
}

struct LowField {
	immutable ConcreteField* source;
	immutable size_t offset;
	immutable LowType type;
}

immutable(Sym) debugName(ref immutable LowField a) =>
	a.source.debugName;

struct LowParamSource {
	struct Generated {
		immutable Sym name;
	}
	mixin Union!(immutable ConcreteParam*, immutable Generated*);
}
static assert(LowParamSource.sizeof == ulong.sizeof);

struct LowParam {
	immutable LowParamSource source;
	immutable LowType type;
}

struct LowLocalSource {
	struct Generated {
		immutable Sym name;
		immutable size_t index;
	}
	mixin Union!(immutable ConcreteLocal*, immutable Generated*);
}
static assert(LowLocalSource.sizeof == ulong.sizeof);

struct LowLocal {
	@safe @nogc pure nothrow:
	@disable this(ref const LowLocal);
	immutable this(immutable LowLocalSource s, immutable LowType t) {
		source = s;
		type = t;
	}

	immutable LowLocalSource source;
	immutable LowType type;
}

struct LowFunExprBody {
	immutable bool hasTailRecur;
	immutable LowExpr expr;
}

// Unlike ConcreteFunBody, this is always an expr or extern.
struct LowFunBody {
	struct Extern {
		immutable bool isGlobal;
		immutable Sym libraryName;
	}

	mixin Union!(immutable Extern, immutable LowFunExprBody);
}

immutable(bool) isGlobal(immutable LowFunBody a) =>
	a.isA!(LowFunBody.Extern) && a.as!(LowFunBody.Extern).isGlobal;

struct LowFunSource {
	struct Generated {
		immutable Sym name;
		immutable LowType[] typeArgs;
	}

	mixin Union!(immutable ConcreteFun*, immutable Generated*);
}
static assert(LowFunSource.sizeof == ulong.sizeof);

struct LowFun {
	@safe @nogc pure nothrow:

	@disable this(ref const LowFun);

	immutable LowFunSource source;
	immutable LowType returnType;
	// Includes ctx and closure params
	immutable LowParam[] params;
	immutable LowFunBody body_;
}

immutable(Opt!Sym) name(ref immutable LowFun a) =>
	a.source.match!(immutable Opt!Sym)(
		(ref immutable ConcreteFun x) => name(x),
		(ref immutable LowFunSource.Generated) => none!Sym);

immutable(FileAndRange) lowFunRange(ref immutable LowFun a, ref const AllSymbols allSymbols) =>
	a.source.match!(immutable FileAndRange)(
		(ref immutable ConcreteFun x) =>
			concreteFunRange(x, allSymbols),
		(ref immutable LowFunSource.Generated) =>
			FileAndRange.empty);

// TODO: use ConcreteExpr*
private alias LowExprSource = FileAndRange;

struct LowExpr {
	immutable LowType type;
	immutable LowExprSource source;
	immutable LowExprKind kind;
}

struct LowFunIndex {
	@safe @nogc pure nothrow:

	immutable size_t index;

	void hash(ref Hasher hasher) scope const {
		hashSizeT(hasher, index);
	}
}

struct LowParamIndex {
	immutable size_t index;
}

struct LowExprKind {
	@safe @nogc pure nothrow:

	struct Call {
		immutable LowFunIndex called;
		immutable LowExpr[] args; // Includes implicit ctx arg if needed
	}

	struct CallFunPtr {
		@safe @nogc pure nothrow:

		immutable LowExpr funPtr;
		immutable LowExpr[] args;

		immutable(LowType.FunPtr) funPtrType() immutable =>
			funPtr.type.as!(LowType.FunPtr);
	}

	struct CreateRecord {
		immutable LowExpr[] args;
	}

	struct CreateUnion {
		immutable size_t memberIndex;
		immutable LowExpr arg;
	}

	struct If {
		immutable LowExpr cond;
		immutable LowExpr then;
		immutable LowExpr else_;
	}

	struct InitConstants {}

	struct Let {
		// A heap-allocated mutable local will become a read-only local whose type is a gc-ptr
		immutable LowLocal* local;
		immutable LowExpr value;
		immutable LowExpr then;
	}

	struct LocalGet {
		immutable LowLocal* local;
	}

	struct LocalSet {
		immutable LowLocal* local;
		immutable LowExpr value;
	}

	struct Loop {
		immutable LowType type; // TODO: this is redundant
		immutable LowExpr body_;
	}

	struct LoopBreak {
		immutable LowExprKind.Loop* loop;
		immutable LowExpr value;
	}

	struct LoopContinue {
		immutable LowExprKind.Loop* loop;
	}

	// TODO: compile down to a Switch?
	struct MatchUnion {
		struct Case {
			immutable Opt!(LowLocal*) local;
			immutable LowExpr then;
		}

		immutable LowExpr matchedValue;
		immutable Case[] cases;
	}

	struct ParamGet {
		immutable LowParamIndex index;
	}

	struct PtrCast {
		immutable LowExpr target;
	}

	struct PtrToField {
		immutable LowExpr target;
		immutable size_t fieldIndex;
	}

	struct PtrToLocal {
		immutable LowLocal* local;
	}

	struct PtrToParam {
		immutable LowParamIndex index;
	}

	struct RecordFieldGet {
		immutable LowExpr target; // Call 'targetIsPointer' to see if this is x.y or x->y
		immutable size_t fieldIndex;
	}

	struct RecordFieldSet {
		immutable LowExpr target;
		immutable size_t fieldIndex;
		immutable LowExpr value;
	}

	struct Seq {
		immutable LowExpr first;
		immutable LowExpr then;
	}

	struct SizeOf {
		immutable LowType type;
	}

	struct SpecialUnary {
		enum Kind {
			asAnyPtr,
			asRef,
			bitwiseNotNat8,
			bitwiseNotNat16,
			bitwiseNotNat32,
			bitwiseNotNat64,
			countOnesNat64,
			deref,
			enumToIntegral,
			toChar8FromNat8,
			toFloat32FromFloat64,
			toFloat64FromFloat32,
			toFloat64FromInt64,
			toFloat64FromNat64,
			toInt64FromInt16,
			toInt64FromInt32,
			toNat8FromChar8,
			toNat64FromNat8,
			toNat64FromNat16,
			toNat64FromNat32,
			toNat64FromPtr,
			toPtrFromNat64,
			truncateToInt64FromFloat64,
			unsafeInt32ToNat32,
			unsafeInt64ToInt8,
			unsafeInt64ToInt16,
			unsafeInt64ToInt32,
			unsafeInt64ToNat64,
			unsafeNat64ToInt64,
			unsafeNat64ToNat8,
			unsafeNat64ToNat16,
			unsafeNat64ToNat32,
		}
		immutable Kind kind;
		immutable LowExpr arg;
	}

	struct SpecialBinary {
		enum Kind {
			addFloat32,
			addFloat64,
			addPtrAndNat64, // RHS is multiplied by size of pointee first
			and,
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
		immutable Kind kind;
		immutable LowExpr left;
		immutable LowExpr right;
	}

	struct SpecialTernary {
		enum Kind { interpreterBacktrace }
		immutable Kind kind;
		immutable LowExpr[3] args;
	}

	struct Switch0ToN {
		immutable LowExpr value;
		immutable LowExpr[] cases;
	}

	struct SwitchWithValues {
		immutable LowExpr value;
		immutable EnumValue[] values;
		immutable LowExpr[] cases;
	}

	struct TailRecur {
		immutable UpdateParam[] updateParams;
	}

	struct ThreadLocalPtr {
		immutable LowThreadLocalIndex threadLocalIndex;
	}

	mixin Union!(
		immutable Call,
		immutable CallFunPtr*,
		immutable CreateRecord,
		immutable CreateUnion*,
		immutable If*,
		immutable InitConstants,
		immutable Let*,
		immutable LocalGet,
		immutable LocalSet*,
		immutable Loop*,
		immutable LoopBreak*,
		immutable LoopContinue,
		immutable MatchUnion*,
		immutable ParamGet,
		immutable PtrCast*,
		immutable PtrToField*,
		immutable PtrToLocal,
		immutable PtrToParam,
		immutable RecordFieldGet*,
		immutable RecordFieldSet*,
		immutable Seq*,
		immutable SizeOf,
		immutable Constant,
		immutable SpecialUnary*,
		immutable SpecialBinary*,
		immutable SpecialTernary*,
		immutable Switch0ToN*,
		immutable SwitchWithValues*,
		immutable TailRecur,
		immutable ThreadLocalPtr);
}
static assert(LowExprKind.sizeof <= 32);

immutable(LowType.Record) targetRecordType(scope ref immutable LowExprKind.PtrToField a) =>
	asGcOrRawPointee(a.target.type).as!(LowType.Record);

immutable(bool) targetIsPointer(scope ref immutable LowExprKind.RecordFieldGet a) =>
	isPtrGcOrRaw(a.target.type);

immutable(LowType.Record) targetRecordType(scope ref immutable LowExprKind.RecordFieldGet a) =>
	(isPtrGcOrRaw(a.target.type) ? asGcOrRawPointee(a.target.type) : a.target.type).as!(LowType.Record);

//TODO: this is always true
immutable(bool) targetIsPointer(scope ref immutable LowExprKind.RecordFieldSet a) =>
	isPtrGcOrRaw(a.target.type);

immutable(LowType.Record) targetRecordType(scope ref immutable LowExprKind.RecordFieldSet a) =>
	asGcOrRawPointee(a.target.type).as!(LowType.Record);

struct UpdateParam {
	immutable LowParamIndex param;
	immutable LowExpr newValue;
}

struct ArrTypeAndConstantsLow {
	@safe @nogc pure nothrow:

	@disable this(ref const ArrTypeAndConstantsLow);
	immutable this(immutable LowType.Record a, immutable LowType e, immutable Constant[][] c) {
		arrType = a; elementType = e; constants = c;
	}

	immutable LowType.Record arrType;
	immutable LowType elementType;
	immutable Constant[][] constants;
}

struct PointerTypeAndConstantsLow {
	@safe @nogc pure nothrow:

	@disable this(ref const PointerTypeAndConstantsLow);
	immutable this(immutable LowType p, immutable Constant[] c) {
		pointeeType = p; constants = c;
	}

	immutable LowType pointeeType;
	immutable Constant[] constants;
}

// TODO: rename -- this is not all constants, just the ones by-ref
struct AllConstantsLow {
	immutable SafeCStr[] cStrings;
	//TODO:FullIndexDict
	immutable ArrTypeAndConstantsLow[] arrs;
	//TODO:FullIndexDict
	// These are just the by-ref records
	immutable PointerTypeAndConstantsLow[] pointers;
}

alias ConcreteFunToLowFunIndex = immutable Dict!(ConcreteFun*, LowFunIndex);

struct LowThreadLocalIndex {
	immutable size_t index;
}

struct LowThreadLocal {
	immutable ConcreteFun* source;
	immutable LowType type;
}

struct LowProgram {
	@safe @nogc pure nothrow:

	immutable ConcreteFunToLowFunIndex concreteFunToLowFunIndex;
	immutable AllConstantsLow allConstants;
	immutable FullIndexDict!(LowThreadLocalIndex, LowThreadLocal) threadLocals;
	immutable AllLowTypes allTypes;
	immutable FullIndexDict!(LowFunIndex, LowFun) allFuns;
	immutable LowFunIndex main;
	immutable ExternLibraries externLibraries;

	//TODO: NOT INSTANCE
	ref immutable(FullIndexDict!(LowType.Extern, LowExternType)) allExternTypes() scope return immutable =>
		allTypes.allExternTypes;

	ref immutable(FullIndexDict!(LowType.FunPtr, LowFunPtrType)) allFunPtrTypes() scope return immutable =>
		allTypes.allFunPtrTypes;

	ref immutable(FullIndexDict!(LowType.Record, LowRecord)) allRecords() scope return immutable =>
		allTypes.allRecords;

	ref immutable(FullIndexDict!(LowType.Union, LowUnion)) allUnions() scope return immutable =>
		allTypes.allUnions;
}

alias ExternLibraries = ExternLibrary[];

struct ExternLibrary {
	immutable Sym libraryName;
	immutable Opt!Path configuredPath;
	immutable Sym[] importNames;
}

struct AllLowTypes {
	immutable FullIndexDict!(LowType.Extern, LowExternType) allExternTypes;
	immutable FullIndexDict!(LowType.FunPtr, LowFunPtrType) allFunPtrTypes;
	immutable FullIndexDict!(LowType.Record, LowRecord) allRecords;
	immutable FullIndexDict!(LowType.Union, LowUnion) allUnions;
}
