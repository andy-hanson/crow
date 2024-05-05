module model.lowModel;

@safe @nogc pure nothrow:

import model.concreteModel :
	ConcreteField,
	ConcreteFun,
	ConcreteStruct,
	ConcreteStructSource,
	ConcreteVar,
	isArray,
	isFiber,
	isTuple,
	name,
	TypeSize;
import model.constant : Constant;
import model.model :
	BuiltinUnary,
	BuiltinUnaryMath,
	BuiltinBinary,
	BuiltinBinaryMath,
	BuiltinTernary,
	Local,
	LocalMutability,
	StructBody;
import util.col.array : SmallArray;
import util.col.map : Map;
import util.col.fullIndexMap : FullIndexMap;
import util.hash : hash2, HashCode, hashEnum, hashUint;
import util.integralValues : IntegralValues;
import util.opt : has, none, Opt;
import util.sourceRange : UriAndRange;
import util.string : CString;
import util.symbol : Symbol, symbol;
import util.union_ : IndexType, TaggedUnion, Union;
import util.uri : Uri;
import versionInfo : VersionInfo;

immutable struct LowExternType {
	ConcreteStruct* source;
}

TypeSize typeSize(in LowExternType a) =>
	a.source.typeSize;

immutable struct LowRecord {
	@safe @nogc pure nothrow:

	ConcreteStruct* source;
	SmallArray!LowField fields;

	//TODO:MOVE
	bool packed() scope =>
		source.source.matchIn!bool(
			(in ConcreteStructSource.Bogus) =>
				false,
			(in ConcreteStructSource.Inst x) =>
				x.decl.body_.as!(StructBody.Record).flags.packed,
			(in ConcreteStructSource.Lambda) =>
				false);
}

TypeSize typeSize(in LowRecord a) =>
	a.source.typeSize;

bool isArray(in LowRecord a) =>
	isArray(*a.source);
bool isFiber(in LowRecord a) =>
	isFiber(*a.source);
bool isTuple(in LowRecord a) =>
	isTuple(*a.source);

immutable struct LowUnion {
	@safe @nogc pure nothrow:

	ConcreteStruct* source;
	SmallArray!LowType members;

	// This might change if we use tagged pointers
	size_t membersOffset() =>
		ulong.sizeof;
}

TypeSize typeSize(in LowUnion a) =>
	a.source.typeSize;

immutable struct LowFunPointerType {
	ConcreteStruct* source;
	LowType returnType;
	LowType[] paramTypes;
}

alias PrimitiveType = immutable PrimitiveType_;
private enum PrimitiveType_ : ubyte {
	bool_,
	char8,
	char32,
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

immutable struct LowType {
	@safe @nogc pure nothrow:

	immutable struct Extern {
		mixin IndexType;
	}
	immutable struct FunPointer {
		mixin IndexType;
	}
	// May be gc-allocated or not; gc will try to trace
	immutable struct PtrGc {
		@safe @nogc pure nothrow:
		LowType* pointee;

		@system void* asPointerForTaggedUnion() =>
			cast(void*) pointee;
		@system static PtrGc fromPointerForTaggedUnion(void* a) =>
			PtrGc(cast(LowType*) a);
	}
	immutable struct PtrRawConst {
		@safe @nogc pure nothrow:
		LowType* pointee;

		@system void* asPointerForTaggedUnion() =>
			cast(void*) pointee;
		@system static PtrRawConst fromPointerForTaggedUnion(void* a) =>
			PtrRawConst(cast(LowType*) a);
	}
	immutable struct PtrRawMut {
		@safe @nogc pure nothrow:
		LowType* pointee;

		@system void* asPointerForTaggedUnion() =>
			cast(void*) pointee;
		@system static PtrRawMut fromPointerForTaggedUnion(void* a) =>
			PtrRawMut(cast(LowType*) a);
	}
	immutable struct Record {
		@safe @nogc pure nothrow:
		mixin IndexType;
		HashCode hash() =>
			hashUint(index);
	}
	immutable struct Union {
		@safe @nogc pure nothrow:
		mixin IndexType;
		HashCode hash() =>
			hashUint(index);
	}

	mixin TaggedUnion!(
		Extern,
		FunPointer,
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
			(in FunPointer x) =>
				b.isA!FunPointer && b.as!FunPointer.index == x.index,
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
				hashUint(x.index),
			(in FunPointer x) =>
				hashUint(x.index),
			(in PrimitiveType x) =>
				hashEnum(x),
			(in PtrGc x) =>
				x.pointee.hash(),
			(in PtrRawConst x) =>
				x.pointee.hash(),
			(in PtrRawMut x) =>
				x.pointee.hash(),
			(in Record x) =>
				hashUint(x.index),
			(in Union x) =>
				hashUint(x.index)));

	LowTypeCombinePointer combinePointer() return scope =>
		match!LowTypeCombinePointer(
			(LowType.Extern x) =>
				LowTypeCombinePointer(x),
			(LowType.FunPointer x) =>
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
bool isChar32(LowType a) =>
	a.isA!PrimitiveType && a.as!PrimitiveType == PrimitiveType.char32;

bool isVoid(LowType a) =>
	a.isA!PrimitiveType && a.as!PrimitiveType == PrimitiveType.void_;

private bool isPtrRawConstOrMut(LowType a) =>
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
	mixin Union!(LowType.Extern, LowType.FunPointer, PrimitiveType, LowPtrCombine, LowType.Record, LowType.Union);
}

bool isPrimitiveType(LowType a, PrimitiveType p) =>
	a.isA!PrimitiveType && a.as!PrimitiveType == p;

immutable struct LowField {
	ConcreteField* source;
	size_t offset;
	LowType type;
}

Symbol debugName(in LowField a) =>
	a.source.debugName;

immutable struct LowLocalSource {
	immutable struct Generated {
		Symbol name;
		bool isMutable;
		size_t index;
	}
	mixin TaggedUnion!(Local*, Generated*);
}

immutable struct LowLocal {
	@safe @nogc pure nothrow:
	@disable this(ref const LowLocal);
	this(LowLocalSource s, LowType t) {
		source = s;
		type = t;
	}

	LowLocalSource source;
	LowType type;

	// This is whether the local itself is mutable, not whether its value is.
	bool isMutable() scope =>
		source.matchIn!bool(
			(in Local x) =>
				x.isMutable,
			(in LowLocalSource.Generated x) =>
				x.isMutable);
}
bool localMustBeVolatile(in LowFun curFun, in LowLocal local) =>
	// https://stackoverflow.com/questions/7996825/why-volatile-works-for-setjmp-longjmp
	local.isMutable && curFun.hasSetjmp;

immutable struct LowFunBody {
	immutable struct Extern {
		Symbol libraryName;
	}

	mixin Union!(Extern, LowFunExprBody);
}

immutable struct LowFunExprBody {
	LowFunFlags flags;
	LowExpr expr;

	alias flags this;
}

immutable struct LowFunFlags {
	@safe @nogc pure nothrow:
	bool hasSetjmp;
	bool hasTailRecur;
	bool mayYield;

	static LowFunFlags none() =>
		LowFunFlags(false, false, false);
}

immutable struct LowFunSource {
	immutable struct Generated {
		Symbol name;
		LowType[] typeArgs;
	}

	mixin TaggedUnion!(ConcreteFun*, Generated*);
}

immutable struct LowFun {
	@safe @nogc pure nothrow:
	@disable this(ref const LowFun);

	LowFunSource source;
	LowType returnType;
	// Includes closure param
	LowLocal[] params;
	LowFunBody body_;

	Opt!Symbol name() scope =>
		source.matchIn!(Opt!Symbol)(
			(in ConcreteFun x) => x.name,
			(in LowFunSource.Generated) => none!Symbol);

	UriAndRange range() scope =>
		source.matchIn!UriAndRange(
			(in ConcreteFun x) =>
				x.range,
			(in LowFunSource.Generated) =>
				UriAndRange.empty);

	LowFunFlags flags() scope =>
		body_.matchIn!LowFunFlags(
			(in LowFunBody.Extern) =>
				LowFunFlags(
					hasSetjmp: false,
					hasTailRecur: false,
					mayYield: false),
			(in LowFunExprBody x) =>
				x.flags);

	bool hasSetjmp() scope =>
		flags.hasSetjmp;

	bool mayYield() scope =>
		flags.mayYield;

	bool isGeneratedMain() scope =>
		source.matchIn!bool(
			(in ConcreteFun _) =>
				false,
			(in LowFunSource.Generated x) =>
				x.name == symbol!"main");
}

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
	immutable struct Abort {}

	immutable struct Call {
		LowFunIndex called;
		SmallArray!LowExpr args; // Includes implicit ctx arg if needed
	}

	immutable struct CallFunPointer {
		@safe @nogc pure nothrow:

		LowExpr* funPtr;
		SmallArray!LowExpr args;


		LowType.FunPointer funPointerType() scope =>
			funPtr.type.as!(LowType.FunPointer);
	}

	immutable struct CreateRecord {
		LowExpr[] args;
	}

	immutable struct CreateUnion {
		size_t memberIndex;
		LowExpr arg;
	}

	// Sometimes this will be a Constant.FunPointer instead,
	// but that's only possible for functions known to ConcreteModel
	immutable struct FunPointer {
		LowFunIndex fun;
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

	immutable struct LocalPointer {
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
		LowExpr value;
	}
	immutable struct LoopContinue {}

	immutable struct PointerCast {
		LowExpr target;
	}

	immutable struct RecordFieldGet {
		@safe @nogc pure nothrow:

		LowExpr* target; // Call 'targetIsPointer' to see if this is x.y or x->y
		size_t fieldIndex;

		LowType.Record targetRecordType() scope =>
			(targetIsPointer ? asGcOrRawPointee(target.type) : target.type).as!(LowType.Record);

		bool targetIsPointer() scope =>
			isPtrGcOrRaw(target.type);
	}

	immutable struct RecordFieldPointer {
		@safe @nogc pure nothrow:

		LowExpr* target; // Always a pointer
		size_t fieldIndex;

		LowType.Record targetRecordType() scope =>
			asGcOrRawPointee(target.type).as!(LowType.Record);
	}

	immutable struct RecordFieldSet {
		@safe @nogc pure nothrow:

		LowExpr target; // Always a pointer
		size_t fieldIndex;
		LowExpr value;

		// Use a template to avoid forward reference errors
		LowType.Record targetRecordType()() scope =>
			asGcOrRawPointee(target.type).as!(LowType.Record);
	}

	immutable struct SpecialUnary {
		BuiltinUnary kind;
		LowExpr arg;
	}

	immutable struct SpecialUnaryMath {
		BuiltinUnaryMath kind;
		LowExpr arg;
	}

	immutable struct SpecialBinary {
		BuiltinBinary kind;
		LowExpr[2] args;
	}

	immutable struct SpecialBinaryMath {
		BuiltinBinaryMath kind;
		LowExpr[2] args;
	}

	immutable struct SpecialTernary {
		BuiltinTernary kind;
		LowExpr[3] args;
	}

	immutable struct Switch {
		@safe @nogc pure nothrow:
		LowExpr value;
		IntegralValues caseValues;
		SmallArray!LowExpr caseExprs;
		LowExpr default_; // This is often Abort

		this(LowExpr value, IntegralValues caseValues, SmallArray!LowExpr caseExprs, LowExpr default_) {
			this.value = value; this.caseValues = caseValues; this.caseExprs = caseExprs; this.default_ = default_;
			assert(caseValues.length == caseExprs.length);
		}
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
	immutable struct UnionAs {
		LowExpr* union_;
		uint memberIndex;
	}
	immutable struct UnionKind {
		LowExpr* union_;
	}

	mixin Union!(
		Abort,
		Call,
		CallFunPointer,
		CreateRecord,
		CreateUnion*,
		FunPointer,
		If*,
		InitConstants,
		Let*,
		LocalGet,
		LocalPointer,
		LocalSet*,
		Loop*,
		LoopBreak*,
		LoopContinue,
		PointerCast*,
		RecordFieldGet,
		RecordFieldPointer,
		RecordFieldSet*,
		Constant,
		SpecialUnary*,
		SpecialUnaryMath*,
		SpecialBinary*,
		SpecialBinaryMath*,
		SpecialTernary*,
		Switch*,
		TailRecur,
		UnionAs,
		UnionKind,
		VarGet,
		VarSet);
}
version (WebAssembly) {
	static assert(LowExprKind.sizeof == Constant.sizeof + ulong.sizeof);
} else {
	static assert(LowExprKind.sizeof == LowExprKind.Call.sizeof + ulong.sizeof);
}

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
	CString[] cStrings;
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
	Opt!Symbol externLibraryName() scope =>
		source.source.externLibraryName;
	Symbol name() scope =>
		source.source.name;
}

immutable struct LowProgram {
	@safe @nogc pure nothrow:

	VersionInfo version_;
	ConcreteFunToLowFunIndex concreteFunToLowFunIndex;
	AllConstantsLow allConstants;
	FullIndexMap!(LowVarIndex, LowVar) vars;
	AllLowTypes allTypes;
	FullIndexMap!(LowFunIndex, LowFun) allFuns;
	LowFunIndex main;
	ExternLibraries externLibraries;

	ref immutable(FullIndexMap!(LowType.Extern, LowExternType)) allExternTypes() scope return =>
		allTypes.allExternTypes;

	ref immutable(FullIndexMap!(LowType.FunPointer, LowFunPointerType)) allFunPointerTypes() scope return =>
		allTypes.allFunPointerTypes;

	ref immutable(FullIndexMap!(LowType.Record, LowRecord)) allRecords() scope return =>
		allTypes.allRecords;

	ref immutable(FullIndexMap!(LowType.Union, LowUnion)) allUnions() scope return =>
		allTypes.allUnions;
}

alias ExternLibraries = immutable ExternLibrary[];

immutable struct ExternLibrary {
	Symbol libraryName;
	Opt!Uri configuredDir;
	Symbol[] importNames;
}

immutable struct AllLowTypes {
	FullIndexMap!(LowType.Extern, LowExternType) allExternTypes;
	FullIndexMap!(LowType.FunPointer, LowFunPointerType) allFunPointerTypes;
	FullIndexMap!(LowType.Record, LowRecord) allRecords;
	FullIndexMap!(LowType.Union, LowUnion) allUnions;
}
