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
	isArr,
	matchConcreteStructSource,
	name,
	typeSize,
	TypeSize;
import model.constant : Constant;
import model.model : asRecord, body_, EnumValue;
import util.col.dict : Dict;
import util.col.fullIndexDict : FullIndexDict;
import util.col.str : SafeCStr;
import util.hash : Hasher, hashSizeT, hashUint;
import util.opt : none, Opt;
import util.path : Path;
import util.sourceRange : FileAndRange;
import util.sym : AllSymbols, shortSym, Sym;
import util.util : unreachable, verify;

struct LowExternPtrType {
	immutable ConcreteStruct* source;
}

struct LowRecord {
	@safe @nogc pure nothrow:

	immutable ConcreteStruct* source;
	immutable LowField[] fields;

	//TODO:MOVE
	immutable(bool) packed() scope immutable {
		return matchConcreteStructSource!(
			immutable bool,
			(ref immutable ConcreteStructSource.Inst it) =>
				asRecord(body_(*it.inst)).flags.packed,
			(ref immutable ConcreteStructSource.Lambda) =>
				false,
		)(source.source);
	}
}

immutable(TypeSize) typeSize(ref immutable LowRecord a) {
	return typeSize(*a.source);
}

immutable(bool) isArr(ref immutable LowRecord a) {
	return isArr(*a.source);
}

struct LowUnion {
	immutable ConcreteStruct* source;
	immutable LowType[] members;
}

immutable(TypeSize) typeSize(ref immutable LowUnion a) {
	return typeSize(*a.source);
}

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
	return shortSym(() {
		final switch (a) {
			case PrimitiveType.bool_:
				return "bool";
			case PrimitiveType.char8:
				return "char8";
			case PrimitiveType.float32:
				return "float-32";
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

struct LowType {
	@safe @nogc pure nothrow:

	struct ExternPtr {
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

	private:
	enum Kind {
		externPtr,
		funPtr,
		primitive,
		ptrGc,
		ptrRawConst,
		ptrRawMut,
		record,
		union_,
	}
	immutable Kind kind_;
	union {
		immutable ExternPtr externPtr_;
		immutable FunPtr funPtr_;
		immutable PrimitiveType primitive_;
		immutable PtrGc ptrGc_;
		immutable PtrRawConst ptrRawConst_;
		immutable PtrRawMut ptrRawMut_;
		immutable Record record_;
		immutable Union union_;
	}

	public:
	immutable this(immutable ExternPtr a) { kind_ = Kind.externPtr; externPtr_ = a; }
	immutable this(immutable FunPtr a) { kind_ = Kind.funPtr; funPtr_ = a; }
	@trusted immutable this(immutable PtrGc a) { kind_ = Kind.ptrGc; ptrGc_ = a; }
	@trusted immutable this(immutable PtrRawConst a) { kind_ = Kind.ptrRawConst; ptrRawConst_ = a; }
	@trusted immutable this(immutable PtrRawMut a) { kind_ = Kind.ptrRawMut; ptrRawMut_ = a; }
	immutable this(immutable PrimitiveType a) { kind_ = Kind.primitive; primitive_ = a; }
	immutable this(immutable Record a) { kind_ = Kind.record; record_ = a; }
	immutable this(immutable Union a) { kind_ = Kind.union_; union_ = a; }

	immutable(bool) opEquals(scope immutable LowType b) scope immutable {
		return kind_ == b.kind_ && () {
			final switch (kind_) {
				case LowType.Kind.externPtr:
					return externPtr_.index == b.externPtr_.index;
				case LowType.Kind.funPtr:
					return funPtr_.index == b.funPtr_.index;
				case LowType.Kind.primitive:
					return primitive_ == b.primitive_;
				case LowType.Kind.ptrGc:
					return *ptrGc_.pointee == *b.ptrGc_.pointee;
				case LowType.Kind.ptrRawConst:
					return *ptrRawConst_.pointee == *b.ptrRawConst_.pointee;
				case LowType.Kind.ptrRawMut:
					return *ptrRawMut_.pointee == *b.ptrRawMut_.pointee;
				case LowType.Kind.record:
					return record_.index == b.record_.index;
				case LowType.Kind.union_:
					return union_.index == b.union_.index;
			}
		}();
	}

	@trusted void hash(ref Hasher hasher) scope immutable {
		hashUint(hasher, kind_);
		final switch (kind_) {
			case LowType.Kind.externPtr:
				hashSizeT(hasher, externPtr_.index);
				break;
			case LowType.Kind.funPtr:
				hashSizeT(hasher, funPtr_.index);
				break;
			case LowType.Kind.primitive:
				hashUint(hasher, primitive_);
				break;
			case LowType.Kind.ptrGc:
				ptrGc_.pointee.hash(hasher);
				break;
			case LowType.Kind.ptrRawConst:
				ptrRawConst_.pointee.hash(hasher);
				break;
			case LowType.Kind.ptrRawMut:
				ptrRawMut_.pointee.hash(hasher);
				break;
			case LowType.Kind.record:
				hashSizeT(hasher, record_.index);
				break;
			case LowType.Kind.union_:
				hashSizeT(hasher, union_.index);
				break;
		}
	}

}
static assert(LowType.sizeof <= 16);

immutable(bool) lowTypeEqualCombinePtr(immutable LowType a, immutable LowType b) {
	return a == b ||
		(isPtrGcOrRaw(a) && isPtrGcOrRaw(b) && asGcOrRawPointee(a) == asGcOrRawPointee(b));
}

immutable(bool) isPrimitive(immutable LowType a) {
	return a.kind_ == LowType.Kind.primitive;
}

immutable(PrimitiveType) asPrimitive(immutable LowType a) {
	verify(isPrimitive(a));
	return a.primitive_;
}

immutable(bool) isChar8(immutable LowType a) {
	return isPrimitive(a) && asPrimitive(a) == PrimitiveType.char8;
}

immutable(bool) isVoid(immutable LowType a) {
	return isPrimitive(a) && asPrimitive(a) == PrimitiveType.void_;
}

immutable(bool) isFunPtrType(immutable LowType a) {
	return a.kind_ == LowType.Kind.funPtr;
}

immutable(bool) isPtrGc(immutable LowType a) {
	return a.kind_ == LowType.Kind.ptrGc;
}

immutable(bool) isPtrRawConst(immutable LowType a) {
	return a.kind_ == LowType.Kind.ptrRawConst;
}

immutable(bool) isPtrRawMut(immutable LowType a) {
	return a.kind_ == LowType.Kind.ptrRawMut;
}

immutable(bool) isPtrRawConstOrMut(immutable LowType a) {
	return isPtrRawConst(a) || isPtrRawMut(a);
}

@trusted immutable(LowType) asPtrGcPointee(return immutable LowType a) {
	verify(isPtrGc(a));
	return *a.ptrGc_.pointee;
}

@trusted immutable(LowType.PtrRawConst) asPtrRawConst(immutable LowType a) {
	verify(isPtrRawConst(a));
	return a.ptrRawConst_;
}

@trusted immutable(LowType.PtrRawMut) asPtrRawMut(immutable LowType a) {
	verify(isPtrRawMut(a));
	return a.ptrRawMut_;
}

private immutable(bool) isPtrGcOrRaw(immutable LowType a) {
	return isPtrGc(a) || isPtrRawConst(a) || isPtrRawMut(a);
}

@trusted immutable(LowType) asGcOrRawPointee(scope return immutable LowType a) {
	verify(isPtrGcOrRaw(a));
	return matchLowTypeCombinePtr!(
		immutable LowType,
		(immutable LowType.ExternPtr) => unreachable!(immutable LowType),
		(immutable LowType.FunPtr) => unreachable!(immutable LowType),
		(immutable PrimitiveType) => unreachable!(immutable LowType),
		(immutable LowPtrCombine it) => it.pointee,
		(immutable LowType.Record) => unreachable!(immutable LowType),
		(immutable LowType.Union) => unreachable!(immutable LowType),
	)(a);
}

immutable(LowType) asPtrRawPointee(immutable LowType a) {
	verify(isPtrRawConstOrMut(a));
	return asGcOrRawPointee(a);
}

immutable(LowType.FunPtr) asFunPtrType(immutable LowType a) {
	verify(a.kind_ == LowType.Kind.funPtr);
	return a.funPtr_;
}

immutable(PrimitiveType) asPrimitiveType(immutable LowType a) {
	verify(a.kind_ == LowType.Kind.primitive);
	return a.primitive_;
}

immutable(bool) isRecordType(immutable LowType a) {
	return a.kind_ == LowType.Kind.record;
}

immutable(LowType.Record) asRecordType(immutable LowType a) {
	verify(isRecordType(a));
	return a.record_;
}

immutable(LowType.Union) asUnionType(immutable LowType a) {
	verify(a.kind_ == LowType.Kind.union_);
	return a.union_;
}

@trusted immutable(T) matchLowType(
	T,
	alias cbExternPtr,
	alias cbFunPtr,
	alias cbPrimitive,
	alias cbPtrGc,
	alias cbPtrRawConst,
	alias cbPtrRawMut,
	alias cbRecord,
	alias cbUnion,
)(immutable LowType a) {
	final switch (a.kind_) {
		case LowType.Kind.externPtr:
			return cbExternPtr(a.externPtr_);
		case LowType.Kind.funPtr:
			return cbFunPtr(a.funPtr_);
		case LowType.Kind.primitive:
			return cbPrimitive(a.primitive_);
		case LowType.Kind.ptrGc:
			return cbPtrGc(a.ptrGc_);
		case LowType.Kind.ptrRawConst:
			return cbPtrRawConst(a.ptrRawConst_);
		case LowType.Kind.ptrRawMut:
			return cbPtrRawMut(a.ptrRawMut_);
		case LowType.Kind.record:
			return cbRecord(a.record_);
		case LowType.Kind.union_:
			return cbUnion(a.union_);
	}
}

struct LowPtrCombine {
	immutable LowType pointee;
}

@trusted immutable(T) matchLowTypeCombinePtr(
	T,
	alias cbExternPtr,
	alias cbFunPtr,
	alias cbPrimitive,
	alias cbPtr,
	alias cbRecord,
	alias cbUnion,
)(immutable LowType a) {
	return matchLowType!(
		T,
		cbExternPtr,
		cbFunPtr,
		cbPrimitive,
		(immutable LowType.PtrGc it) => cbPtr(immutable LowPtrCombine(*it.pointee)),
		(immutable LowType.PtrRawConst it) => cbPtr(immutable LowPtrCombine(*it.pointee)),
		(immutable LowType.PtrRawMut it) => cbPtr(immutable LowPtrCombine(*it.pointee)),
		cbRecord,
		cbUnion,
	)(a);
}

struct LowField {
	immutable ConcreteField* source;
	immutable size_t offset;
	immutable LowType type;
}

immutable(Sym) debugName(ref immutable LowField a) {
	return a.source.debugName;
}

struct LowParamSource {
	@safe @nogc pure nothrow:

	struct Generated {
		immutable Sym name;
	}

	@trusted immutable this(immutable ConcreteParam* a) { kind_ = Kind.concreteParam; concreteParam_ = a; }
	immutable this(immutable Generated a) { kind_ = Kind.generated; generated_ = a; }

	private:
	enum Kind {
		concreteParam,
		generated,
	}
	immutable Kind kind_;
	union {
		immutable ConcreteParam* concreteParam_;
		immutable Generated generated_;
	}
}

@trusted immutable(T) matchLowParamSource(T, alias cbConcreteParam, alias cbGenerated)(
	ref immutable LowParamSource a,
) {
	final switch (a.kind_) {
		case LowParamSource.Kind.concreteParam:
			return cbConcreteParam(*a.concreteParam_);
		case LowParamSource.Kind.generated:
			return cbGenerated(a.generated_);
	}
}

struct LowParam {
	immutable LowParamSource source;
	immutable LowType type;
}

struct LowLocalSource {
	@safe @nogc pure nothrow:

	struct Generated {
		immutable Sym name;
		immutable size_t index;
	}

	@trusted immutable this(immutable ConcreteLocal* a) { kind_ = Kind.concreteLocal; concreteLocal_ = a; }
	immutable this(immutable Generated a) { kind_ = Kind.generated; generated_ = a; }

	private:
	enum Kind {
		concreteLocal,
		generated,
	}
	immutable Kind kind_;
	union {
		immutable ConcreteLocal* concreteLocal_;
		immutable Generated generated_;
	}
}

@trusted immutable(T) matchLowLocalSource(T, alias cbConcreteLocal, alias cbGenerated)(
	ref immutable LowLocalSource a,
) {
	final switch (a.kind_) {
		case LowLocalSource.Kind.concreteLocal:
			return cbConcreteLocal(*a.concreteLocal_);
		case LowLocalSource.Kind.generated:
			return cbGenerated(a.generated_);
	}
}


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
	@safe @nogc pure nothrow:

	struct Extern {
		immutable bool isGlobal;
		immutable Sym libraryName;
	}

	enum Kind {
		extern_,
		expr,
	}
	immutable Kind kind;
	union {
		immutable Extern extern_;
		immutable LowFunExprBody expr_;
	}

	public:
	@trusted immutable this(immutable Extern a) { kind = Kind.extern_; extern_ = a; }
	@trusted immutable this(immutable LowFunExprBody a) { kind = Kind.expr; expr_ = a; }
}

immutable(bool) isExtern(ref immutable LowFunBody a) {
	return a.kind == LowFunBody.Kind.extern_;
}

@trusted immutable(bool) isGlobal(ref immutable LowFunBody a) {
	return isExtern(a) && a.extern_.isGlobal;
}

@trusted immutable(T) matchLowFunBody(T, alias cbExtern, alias cbExpr)(ref immutable LowFunBody a) {
	final switch (a.kind) {
		case LowFunBody.Kind.extern_:
			return cbExtern(a.extern_);
		case LowFunBody.Kind.expr:
			return cbExpr(a.expr_);
	}
}

struct LowFunSource {
	@safe @nogc pure nothrow:

	struct Generated {
		immutable Sym name;
		immutable LowType[] typeArgs;
	}

	@trusted immutable this(immutable ConcreteFun* a) { kind_ = Kind.concreteFun; concreteFun_ = a; }
	@trusted immutable this(immutable Generated* a) { kind_ = Kind.generated; generated_ = a; }

	private:
	enum Kind {
		concreteFun,
		generated,
	}
	immutable Kind kind_;
	union {
		immutable ConcreteFun* concreteFun_;
		immutable Generated* generated_;
	}
}
static assert(LowFunSource.sizeof <= 16);

@trusted immutable(T) matchLowFunSource(T, alias cbConcreteFun, alias cbGenerated)(ref immutable LowFunSource a) {
	final switch (a.kind_) {
		case LowFunSource.Kind.concreteFun:
			return cbConcreteFun(a.concreteFun_);
		case LowFunSource.Kind.generated:
			return cbGenerated(*a.generated_);
	}
}

struct LowFunParamsKind {
	immutable bool hasCtx;
	immutable bool hasClosure;
}

struct LowFun {
	@safe @nogc pure nothrow:

	@disable this(ref const LowFun);

	immutable LowFunSource source;
	immutable LowType returnType;
	immutable LowFunParamsKind paramsKind;
	// Includes ctx and closure params
	immutable LowParam[] params;
	immutable LowFunBody body_;
}

immutable(Opt!Sym) name(ref immutable LowFun a) {
	return matchLowFunSource!(
		immutable Opt!Sym,
		(immutable ConcreteFun* it) => name(*it),
		(ref immutable LowFunSource.Generated) => none!Sym,
	)(a.source);
}

immutable(FileAndRange) lowFunRange(ref immutable LowFun a, ref const AllSymbols allSymbols) {
	return matchLowFunSource!(
		immutable FileAndRange,
		(immutable ConcreteFun* cf) =>
			concreteFunRange(*cf, allSymbols),
		(ref immutable LowFunSource.Generated) =>
			FileAndRange.empty,
	)(a.source);
}

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

		immutable(LowType.FunPtr) funPtrType() immutable {
			return asFunPtrType(funPtr.type);
		}
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
		immutable LowLocal* local;
		immutable LowExpr value;
		immutable LowExpr then;
	}

	struct LocalRef {
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

	struct ParamRef {
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
		immutable LowExpr target;
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
			toCharFromNat8,
			toFloat32FromFloat64,
			toFloat64FromFloat32,
			toFloat64FromInt64,
			toFloat64FromNat64,
			toInt64FromInt16,
			toInt64FromInt32,
			toNat8FromChar,
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
			lessBool,
			lessChar,
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

	struct Zeroed {}

	private:
	enum Kind {
		call,
		callFunPtr,
		createRecord,
		createUnion,
		if_,
		initConstants,
		let,
		localRef,
		localSet,
		loop,
		loopBreak,
		loopContinue,
		matchUnion,
		paramRef,
		ptrCast,
		ptrToField,
		ptrToLocal,
		ptrToParam,
		recordFieldGet,
		recordFieldSet,
		seq,
		sizeOf,
		constant,
		specialUnary,
		specialBinary,
		specialTernary,
		switchWithValues,
		switch0ToN,
		tailRecur,
		threadLocalPtr,
		zeroed,
	}
	public immutable Kind kind; //TODO:PRIVATE
	union {
		immutable Call call;
		immutable CallFunPtr* callFunPtr;
		immutable CreateRecord createRecord;
		immutable CreateUnion* createUnion;
		immutable If* if_;
		immutable InitConstants initConstants;
		immutable Let* let;
		immutable LocalRef localRef;
		immutable LocalSet* localSet;
		immutable Loop* loop;
		immutable LoopBreak* loopBreak;
		immutable LoopContinue loopContinue;
		immutable MatchUnion* matchUnion;
		immutable ParamRef paramRef;
		immutable PtrCast* ptrCast;
		immutable PtrToField* ptrToField;
		immutable PtrToLocal ptrToLocal;
		immutable PtrToParam ptrToParam;
		immutable RecordFieldGet* recordFieldGet;
		immutable RecordFieldSet* recordFieldSet;
		immutable Seq* seq;
		immutable SizeOf sizeOf;
		immutable Constant constant;
		immutable SpecialUnary* specialUnary;
		immutable SpecialBinary* specialBinary;
		immutable SpecialTernary* specialTernary;
		immutable Switch0ToN* switch0ToN;
		immutable SwitchWithValues* switchWithValues;
		immutable TailRecur tailRecur;
		immutable ThreadLocalPtr threadLocalPtr;
		immutable Zeroed zeroed;
	}

	public:
	@trusted immutable this(immutable Call a) { kind = Kind.call; call = a; }
	@trusted immutable this(immutable CallFunPtr* a) { kind = Kind.callFunPtr; callFunPtr = a; }
	@trusted immutable this(immutable CreateRecord a) { kind = Kind.createRecord; createRecord = a; }
	@trusted immutable this(immutable CreateUnion* a) { kind = Kind.createUnion; createUnion = a; }
	immutable this(immutable If* a) { kind = Kind.if_; if_ = a; }
	immutable this(immutable InitConstants a) { kind = Kind.initConstants; initConstants = a; }
	@trusted immutable this(immutable Let* a) { kind = Kind.let; let = a; }
	@trusted immutable this(immutable LocalRef a) { kind = Kind.localRef; localRef = a; }
	@trusted immutable this(immutable LocalSet* a) { kind = Kind.localSet; localSet = a; }
	immutable this(immutable Loop* a) { kind = Kind.loop; loop = a; }
	immutable this(immutable LoopBreak* a) { kind = Kind.loopBreak; loopBreak = a; }
	immutable this(immutable LoopContinue a) { kind = Kind.loopContinue; loopContinue = a; }
	@trusted immutable this(immutable MatchUnion* a) { kind = Kind.matchUnion; matchUnion = a; }
	@trusted immutable this(immutable ParamRef a) { kind = Kind.paramRef; paramRef = a; }
	@trusted immutable this(immutable PtrCast* a) { kind = Kind.ptrCast; ptrCast = a; }
	immutable this(immutable PtrToField* a) { kind = Kind.ptrToField; ptrToField = a; }
	immutable this(immutable PtrToLocal a) { kind = Kind.ptrToLocal; ptrToLocal = a; }
	immutable this(immutable PtrToParam a) { kind = Kind.ptrToParam; ptrToParam = a; }
	@trusted immutable this(immutable RecordFieldGet* a) { kind = Kind.recordFieldGet; recordFieldGet = a; }
	@trusted immutable this(immutable RecordFieldSet* a) { kind = Kind.recordFieldSet; recordFieldSet = a; }
	@trusted immutable this(immutable Seq* a) { kind = Kind.seq; seq = a; }
	@trusted immutable this(immutable SizeOf a) { kind = Kind.sizeOf; sizeOf = a; }
	@trusted immutable this(immutable Constant a) { kind = Kind.constant; constant = a; }
	@trusted immutable this(immutable SpecialUnary* a) { kind = Kind.specialUnary; specialUnary = a; }
	@trusted immutable this(immutable SpecialBinary* a) { kind = Kind.specialBinary; specialBinary = a; }
	@trusted immutable this(immutable SpecialTernary* a) { kind = Kind.specialTernary; specialTernary = a; }
	@trusted immutable this(immutable Switch0ToN* a) { kind = Kind.switch0ToN; switch0ToN = a; }
	@trusted immutable this(immutable SwitchWithValues* a) { kind = Kind.switchWithValues; switchWithValues = a; }
	@trusted immutable this(immutable TailRecur a) { kind = Kind.tailRecur; tailRecur = a; }
	immutable this(immutable ThreadLocalPtr a) { kind = Kind.threadLocalPtr; threadLocalPtr = a; }
	immutable this(immutable Zeroed a) { kind = Kind.zeroed; zeroed = a; }
}
static assert(LowExprKind.sizeof <= 32);

@trusted T matchLowExprKind(
	T,
	alias cbCall,
	alias cbCallFunPtr,
	alias cbCreateRecord,
	alias cbCreateUnion,
	alias cbIf,
	alias cbInitConstants,
	alias cbLet,
	alias cbLocalRef,
	alias cbLocalSet,
	alias cbLoop,
	alias cbLoopBreak,
	alias cbLoopContinue,
	alias cbMatchUnion,
	alias cbParamRef,
	alias cbPtrCast,
	alias cbPtrToField,
	alias cbPtrToLocal,
	alias cbPtrToParam,
	alias cbRecordFieldGet,
	alias cbRecordFieldSet,
	alias cbSeq,
	alias cbSizeOf,
	alias cbConstant,
	alias cbSpecialUnary,
	alias cbSpecialBinary,
	alias cbSpecialTernary,
	alias cbSwitch0ToN,
	alias cbSwitchWithValues,
	alias cbTailRecur,
	alias cbThreadLocalPtr,
	alias cbZeroed,
)(scope ref immutable LowExprKind a) {
	final switch (a.kind) {
		case LowExprKind.Kind.call:
			return cbCall(a.call);
		case LowExprKind.Kind.callFunPtr:
			return cbCallFunPtr(*a.callFunPtr);
		case LowExprKind.Kind.createRecord:
			return cbCreateRecord(a.createRecord);
		case LowExprKind.Kind.createUnion:
			return cbCreateUnion(*a.createUnion);
		case LowExprKind.Kind.if_:
			return cbIf(*a.if_);
		case LowExprKind.Kind.initConstants:
			return cbInitConstants(a.initConstants);
		case LowExprKind.Kind.let:
			return cbLet(*a.let);
		case LowExprKind.Kind.localRef:
			return cbLocalRef(a.localRef);
		case LowExprKind.Kind.localSet:
			return cbLocalSet(*a.localSet);
		case LowExprKind.Kind.loop:
			return cbLoop(*a.loop);
		case LowExprKind.Kind.loopBreak:
			return cbLoopBreak(*a.loopBreak);
		case LowExprKind.Kind.loopContinue:
			return cbLoopContinue(a.loopContinue);
		case LowExprKind.Kind.matchUnion:
			return cbMatchUnion(*a.matchUnion);
		case LowExprKind.Kind.paramRef:
			return cbParamRef(a.paramRef);
		case LowExprKind.Kind.ptrCast:
			return cbPtrCast(*a.ptrCast);
		case LowExprKind.Kind.ptrToField:
			return cbPtrToField(*a.ptrToField);
		case LowExprKind.Kind.ptrToLocal:
			return cbPtrToLocal(a.ptrToLocal);
		case LowExprKind.Kind.ptrToParam:
			return cbPtrToParam(a.ptrToParam);
		case LowExprKind.Kind.recordFieldGet:
			return cbRecordFieldGet(*a.recordFieldGet);
		case LowExprKind.Kind.recordFieldSet:
			return cbRecordFieldSet(*a.recordFieldSet);
		case LowExprKind.Kind.seq:
			return cbSeq(*a.seq);
		case LowExprKind.Kind.sizeOf:
			return cbSizeOf(a.sizeOf);
		case LowExprKind.Kind.constant:
			return cbConstant(a.constant);
		case LowExprKind.Kind.specialUnary:
			return cbSpecialUnary(*a.specialUnary);
		case LowExprKind.Kind.specialBinary:
			return cbSpecialBinary(*a.specialBinary);
		case LowExprKind.Kind.specialTernary:
			return cbSpecialTernary(*a.specialTernary);
		case LowExprKind.Kind.switch0ToN:
			return cbSwitch0ToN(*a.switch0ToN);
		case LowExprKind.Kind.switchWithValues:
			return cbSwitchWithValues(*a.switchWithValues);
		case LowExprKind.Kind.tailRecur:
			return cbTailRecur(a.tailRecur);
		case LowExprKind.Kind.threadLocalPtr:
			return cbThreadLocalPtr(a.threadLocalPtr);
		case LowExprKind.Kind.zeroed:
			return cbZeroed(a.zeroed);
	}
}

immutable(LowType.Record) targetRecordType(scope ref immutable LowExprKind.PtrToField a) {
	return asRecordType(asGcOrRawPointee(a.target.type));
}

immutable(bool) targetIsPointer(scope ref immutable LowExprKind.RecordFieldGet a) {
	return isPtrGcOrRaw(a.target.type);
}

immutable(LowType.Record) targetRecordType(scope ref immutable LowExprKind.RecordFieldGet a) {
	return asRecordType(isPtrGcOrRaw(a.target.type)
		? asGcOrRawPointee(a.target.type)
		: a.target.type);
}

//TODO: this is always true
immutable(bool) targetIsPointer(scope ref immutable LowExprKind.RecordFieldSet a) {
	return isPtrGcOrRaw(a.target.type);
}

immutable(LowType.Record) targetRecordType(scope ref immutable LowExprKind.RecordFieldSet a) {
	return asRecordType(asGcOrRawPointee(a.target.type));
}

struct UpdateParam {
	immutable LowParamIndex param;
	immutable LowExpr newValue;
}

immutable(bool) isParamRef(ref immutable LowExprKind a) {
	return a.kind == LowExprKind.Kind.paramRef;
}

ref immutable(LowExprKind.ParamRef) asParamRef(scope return ref immutable LowExprKind a) {
	verify(isParamRef(a));
	return a.paramRef;
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
	ref immutable(FullIndexDict!(LowType.ExternPtr, LowExternPtrType)) allExternPtrTypes() scope return immutable {
		return allTypes.allExternPtrTypes;
	}

	ref immutable(FullIndexDict!(LowType.FunPtr, LowFunPtrType)) allFunPtrTypes() scope return immutable {
		return allTypes.allFunPtrTypes;
	}

	ref immutable(FullIndexDict!(LowType.Record, LowRecord)) allRecords() scope return immutable {
		return allTypes.allRecords;
	}

	ref immutable(FullIndexDict!(LowType.Union, LowUnion)) allUnions() scope return immutable {
		return allTypes.allUnions;
	}
}

alias ExternLibraries = ExternLibrary[];

struct ExternLibrary {
	immutable Sym libraryName;
	immutable Opt!Path configuredPath;
	immutable Sym[] importNames;
}

struct AllLowTypes {
	immutable FullIndexDict!(LowType.ExternPtr, LowExternPtrType) allExternPtrTypes;
	immutable FullIndexDict!(LowType.FunPtr, LowFunPtrType) allFunPtrTypes;
	immutable FullIndexDict!(LowType.Record, LowRecord) allRecords;
	immutable FullIndexDict!(LowType.Union, LowUnion) allUnions;
}
