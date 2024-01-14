module model.concreteModel;

@safe @nogc pure nothrow:

import model.constant : Constant;
import model.model :
	BuiltinFun,
	BuiltinType,
	ClosureReferenceKind,
	EnumBackingType,
	EnumFunction,
	EnumValue,
	FlagsFunction,
	FunDecl,
	isArray,
	isTuple,
	Local,
	localIsAllocated,
	Params,
	Purity,
	StructInst,
	VarDecl;
import util.col.array : arraysEqual, only, PtrAndSmallNumber, SmallArray;
import util.col.map : Map;
import util.hash : HashCode, Hasher, hashPtr;
import util.late : Late, lateGet, lateIsSet, lateSet, lateSetOverwrite;
import util.opt : none, Opt, some;
import util.sourceRange : UriAndRange;
import util.string : CString;
import util.symbol : Symbol;
import util.union_ : Union;

immutable struct EnumValues {
	// size_t for 0 to N
	mixin Union!(size_t, EnumValue[]);
}

immutable struct ConcreteStructBody {
	immutable struct Builtin {
		BuiltinType kind;
		ConcreteType[] typeArgs;
	}
	immutable struct Enum {
		EnumBackingType backingType;
		EnumValues values;
	}
	immutable struct Flags {
		EnumBackingType backingType;
		ulong[] values;
	}
	immutable struct Extern {}
	immutable struct Record {
		ConcreteField[] fields;
	}
	immutable struct Union {
		// In the concrete model we identify members by index, so don't care about their names.
		// This may be empty for a lambda type with no implementations.
		ConcreteType[] members;
	}

	mixin .Union!(Builtin, Enum, Extern, Flags, Record, Union);
}

immutable struct ConcreteType {
	@safe @nogc pure nothrow:

	ReferenceKind reference;
	ConcreteStruct* struct_;

	bool opEquals(scope ConcreteType b) scope =>
		struct_ == b.struct_ && reference == reference;

	HashCode hash() scope =>
		hashPtr(struct_);
}

bool isBogus(in ConcreteType a) =>
	a.reference == ReferenceKind.byVal &&
	isBogus(*a.struct_);
bool isVoid(in ConcreteType a) =>
	a.reference == ReferenceKind.byVal &&
	a.struct_.body_.isA!(ConcreteStructBody.Builtin) &&
	a.struct_.body_.as!(ConcreteStructBody.Builtin).kind == BuiltinType.void_;

alias ReferenceKind = immutable ReferenceKind_;
private enum ReferenceKind_ { byVal, byRef, byRefRef }

immutable struct TypeSize {
	uint sizeBytes;
	uint alignmentBytes;
}

Purity purity(ConcreteType a) =>
	a.struct_.purity;

ConcreteStruct* mustBeByVal(ConcreteType a) {
	assert(a.reference == ReferenceKind.byVal);
	return a.struct_;
}

immutable struct ConcreteStructInfo {
	ConcreteStructBody body_;
	bool isSelfMutable; //TODO: never used? (may need for GC though)
}

immutable struct ConcreteStructSource {
	immutable struct Bogus {}

	immutable struct Inst {
		StructInst* inst;
		ConcreteType[] typeArgs;
	}

	immutable struct Lambda {
		ConcreteFun* containingFun;
		size_t index;
	}

	mixin Union!(Bogus, Inst, Lambda);
}

immutable struct ConcreteStruct {
	@safe @nogc pure nothrow:

	enum SpecialKind {
		none,
		array,
		tuple,
	}

	Purity purity;
	SpecialKind specialKind;
	ConcreteStructSource source;
	private Late!ConcreteStructInfo info_;
	//TODO: this isn't needed outside of concretizeCtx.d
	private Late!ReferenceKind defaultReferenceKind_;
	private Late!TypeSize typeSize_;
	// Only set for records
	private Late!(immutable uint[]) fieldOffsets_;

	void info(ConcreteStructInfo value) {
		lateSet(info_, value);
	}
	private ref ConcreteStructInfo info() return scope =>
		lateGet(info_);

	ref ConcreteStructBody body_() return scope =>
		info.body_;

	bool isSelfMutable() scope =>
		info.isSelfMutable;

	TypeSize typeSize() scope =>
		lateGet(typeSize_);
	void typeSize(TypeSize value) {
		lateSet(typeSize_, value);
	}

	ReferenceKind defaultReferenceKind() scope =>
		lateGet(defaultReferenceKind_);
	void defaultReferenceKind(ReferenceKind value) {
		lateSet(defaultReferenceKind_, value);
	}
	bool defaultReferenceKindIsSet() =>
		lateIsSet(defaultReferenceKind_);

	immutable(uint[]) fieldOffsets() =>
		lateGet(fieldOffsets_);
	void fieldOffsets(immutable uint[] value) {
		lateSet(fieldOffsets_, value);
	}
}

bool isArray(in ConcreteStruct a) =>
	a.specialKind == ConcreteStruct.SpecialKind.array;
private bool isBogus(in ConcreteStruct a) =>
	a.source.isA!(ConcreteStructSource.Bogus);
bool isTuple(in ConcreteStruct a) =>
	a.specialKind == ConcreteStruct.SpecialKind.tuple;

//TODO: this is only useful during concretize, move
bool hasSizeOrPointerSizeBytes(in ConcreteType a) {
	final switch (a.reference) {
		case ReferenceKind.byVal:
			return lateIsSet(a.struct_.typeSize_);
		case ReferenceKind.byRef:
		case ReferenceKind.byRefRef:
			return true;
	}
}

TypeSize sizeOrPointerSizeBytes(in ConcreteType a) {
	final switch (a.reference) {
		case ReferenceKind.byVal:
			return a.struct_.typeSize;
		case ReferenceKind.byRef:
		case ReferenceKind.byRefRef:
			return TypeSize(8, 8);
	}
}

ConcreteType byRef(ConcreteType t) =>
	ConcreteType(ReferenceKind.byRef, t.struct_);

ConcreteType byVal(ref ConcreteType t) =>
	ConcreteType(ReferenceKind.byVal, t.struct_);

enum ConcreteMutability {
	const_,
	mutable,
}

immutable struct ConcreteField {
	Symbol debugName;
	ConcreteMutability mutability;
	ConcreteType type;
}

immutable struct ConcreteLocalSource {
	immutable struct Closure {}
	immutable struct Generated { Symbol name; }
	mixin Union!(Local*, Closure, Generated);
}

immutable struct ConcreteLocal {
	@safe @nogc pure nothrow:

	ConcreteLocalSource source;
	ConcreteType type;

	bool isAllocated() scope =>
		source.matchIn!bool(
			(in Local x) => localIsAllocated(x),
			(in ConcreteLocalSource.Closure) => false,
			(in ConcreteLocalSource.Generated) => false);
}

immutable struct ConcreteFunBody {
	immutable struct Builtin {
		BuiltinFun kind;
		ConcreteType[] typeArgs;
	}
	immutable struct CreateRecord {}
	immutable struct CreateUnion {
		size_t memberIndex;
	}
	immutable struct Extern {
		Symbol libraryName;
	}
	immutable struct FlagsFn {
		ulong allValue;
		FlagsFunction fn;
	}
	immutable struct RecordFieldCall {
		size_t fieldIndex;
		ConcreteStruct* funType;
		ConcreteType argType;
		ConcreteFun* caller;
	}
	immutable struct RecordFieldGet {
		size_t fieldIndex;
	}
	// Note: This is redundant to the 'PtrToField' expression; low model will unify them
	immutable struct RecordFieldPointer {
		size_t fieldIndex;
	}
	immutable struct RecordFieldSet {
		size_t fieldIndex;
	}
	immutable struct VarGet { ConcreteVar* var; }
	immutable struct VarSet { ConcreteVar* var; }

	mixin Union!(
		Builtin,
		Constant,
		CreateRecord,
		CreateUnion,
		EnumFunction,
		Extern,
		ConcreteExpr,
		FlagsFn,
		RecordFieldCall,
		RecordFieldGet,
		RecordFieldPointer,
		RecordFieldSet,
		VarGet,
		VarSet);
}

immutable struct ConcreteFunSource {
	immutable struct Lambda {
		UriAndRange range;
		ConcreteFun* containingFun;
		size_t index; // nth lambda in the containing function
	}

	immutable struct Test {
		UriAndRange range;
		size_t testIndex;
	}

	immutable struct WrapMain {
		UriAndRange range;
	}

	mixin Union!(ConcreteFunKey, Lambda*, Test*, WrapMain*);
}

// We generate a ConcreteFun for:
// Each instantiation of a FunDecl
// Each lambda inside an instantiation of a FunDecl
immutable struct ConcreteFun {
	@safe @nogc pure nothrow:

	ConcreteFunSource source;
	ConcreteType returnType;
	ConcreteLocal[] paramsIncludingClosure;
	private Late!ConcreteFunBody lateBody;

	ref ConcreteFunBody body_() return scope =>
		lateGet(lateBody);
	bool bodyIsSet() =>
		lateIsSet(lateBody);

	void body_(ConcreteFunBody value) {
		lateSet(lateBody, value);
	}

	void overwriteBody(ConcreteFunBody value) {
		lateSetOverwrite(lateBody, value);
	}
}

immutable struct ConcreteFunKey {
	@safe @nogc pure nothrow:

	FunDecl* decl;
	SmallArray!(ConcreteType) typeArgs;
	SmallArray!(immutable ConcreteFun*) specImpls;

	bool opEquals(scope ConcreteFunKey b) scope =>
		decl == b.decl &&
		arraysEqual!ConcreteType(typeArgs, b.typeArgs) &&
		arraysEqual!(ConcreteFun*)(specImpls, b.specImpls);

	HashCode hash() scope {
		Hasher hasher;
		hasher ~= decl;
		foreach (ConcreteType t; typeArgs)
			// Ignore 'reference', functions are unlikely to overload by that
			hasher ~= t.struct_;
		foreach (ConcreteFun* p; specImpls)
			hasher ~= p;
		return hasher.finish();
	}
}

bool isVariadic(in ConcreteFun a) =>
	a.source.matchIn!bool(
		(in ConcreteFunKey x) =>
			x.decl.params.isA!(Params.Varargs*),
		(in ConcreteFunSource.Lambda) =>
			false,
		(in ConcreteFunSource.Test) =>
			false,
		(in ConcreteFunSource.WrapMain) =>
			false);

Opt!Symbol name(ref ConcreteFun a) =>
	a.source.isA!ConcreteFunKey ? some(a.source.as!ConcreteFunKey.decl.name) : none!Symbol;

bool isSummon(ref ConcreteFun a) =>
	a.source.matchIn!bool(
		(in ConcreteFunKey x) =>
			x.decl.isSummon,
		(in ConcreteFunSource.Lambda x) =>
			isSummon(*x.containingFun),
		(in ConcreteFunSource.Test) =>
			// 'isSummon' is called for direct calls, but tests are never called directly
			assert(false),
		(in ConcreteFunSource.WrapMain) =>
			assert(false));

UriAndRange concreteFunRange(in ConcreteFun a) =>
	a.source.matchIn!UriAndRange(
		(in ConcreteFunKey x) =>
			x.decl.range,
		(in ConcreteFunSource.Lambda x) =>
			x.range,
		(in ConcreteFunSource.Test x) =>
			x.range,
		(in ConcreteFunSource.WrapMain x) =>
			x.range);

immutable struct ConcreteExpr {
	ConcreteType type;
	UriAndRange range;
	ConcreteExprKind kind;
}

immutable struct ConcreteClosureRef {
	@safe @nogc pure nothrow:

	PtrAndSmallNumber!ConcreteLocal paramAndIndex;

	ConcreteLocal* closureParam() =>
		paramAndIndex.ptr;

	ushort fieldIndex() =>
		paramAndIndex.number;

	ConcreteType type() =>
		closureParam.type.struct_.body_.as!(ConcreteStructBody.Record).fields[fieldIndex].type;
}

immutable struct ConcreteExprKind {
	immutable struct Alloc {
		ConcreteExpr arg;
	}

	immutable struct Call {
		ConcreteFun* called;
		ConcreteExpr[] args;
	}

	immutable struct ClosureCreate {
		ConcreteVariableRef[] args;
	}

	immutable struct ClosureGet {
		ConcreteClosureRef closureRef;
		ClosureReferenceKind referenceKind;
	}

	immutable struct ClosureSet {
		ConcreteClosureRef closureRef;
		ConcreteExpr value;
		// referenceKind is always allocated
	}

	immutable struct CreateArr {
		ConcreteExpr[] args;
	}

	// TODO: this is only used for 'safeValue'.
	immutable struct CreateRecord {
		ConcreteExpr[] args;
	}

	// Only used for 'safe-value', otherwise it goes through a function
	immutable struct CreateUnion {
		size_t memberIndex;
		ConcreteExpr arg;
	}

	immutable struct Drop {
		ConcreteExpr arg;
	}

	immutable struct If {
		ConcreteExpr cond;
		ConcreteExpr then;
		ConcreteExpr else_;
	}

	// May be a 'fun' or 'act'.
	// (A 'far' function is a lambda wrapped in CreateRecord.)
	immutable struct Lambda {
		size_t memberIndex; // Member index of a Union (which hasn't been created yet)
		Opt!(ConcreteExpr*) closure;
	}

	immutable struct Let {
		ConcreteLocal* local;
		ConcreteExpr value;
		ConcreteExpr then;
	}

	immutable struct LocalGet {
		ConcreteLocal* local;
	}

	immutable struct LocalSet {
		ConcreteLocal* local;
		ConcreteExpr value;
	}

	immutable struct Loop {
		ConcreteExpr body_;
	}

	immutable struct LoopBreak {
		ConcreteExprKind.Loop* loop;
		ConcreteExpr value;
	}

	immutable struct LoopContinue {
		ConcreteExprKind.Loop* loop;
	}

	immutable struct MatchEnum {
		ConcreteExpr matchedValue;
		ConcreteExpr[] cases;
	}

	immutable struct MatchUnion {
		immutable struct Case {
			Opt!(ConcreteLocal*) local;
			ConcreteExpr then;
		}

		ConcreteExpr matchedValue;
		Case[] cases;
	}

	immutable struct PtrToField {
		ConcreteExpr target;
		size_t fieldIndex;
	}

	immutable struct PtrToLocal {
		ConcreteLocal* local;
	}

	// Only used for destructuring.
	immutable struct RecordFieldGet {
		// This is always by-value
		ConcreteExpr* record;
		size_t fieldIndex;
	}

	immutable struct Seq {
		ConcreteExpr first;
		ConcreteExpr then;
	}

	immutable struct Throw {
		// a `c-string`
		ConcreteExpr thrown;
	}

	mixin Union!(
		Alloc*,
		Call,
		ClosureCreate,
		ClosureGet*,
		ClosureSet*,
		Constant,
		CreateArr*,
		CreateRecord,
		CreateUnion*,
		Drop*,
		If*,
		Lambda,
		Let*,
		LocalGet,
		LocalSet*,
		Loop*,
		LoopBreak*,
		LoopContinue,
		MatchEnum*,
		MatchUnion*,
		PtrToField*,
		PtrToLocal,
		RecordFieldGet,
		Seq*,
		Throw*);
}

immutable struct ConcreteVariableRef {
	mixin Union!(Constant, ConcreteLocal*, ConcreteClosureRef);
}

ConcreteType returnType(ConcreteExprKind.Call a) =>
	a.called.returnType;

immutable struct ArrTypeAndConstantsConcrete {
	ConcreteStruct* arrType;
	ConcreteType elementType;
	Constant[][] constants;
}

immutable struct PointerTypeAndConstantsConcrete {
	ConcreteStruct* pointeeType;
	Constant[] constants;
}

// TODO: rename -- this is not all constants, just the ones by-ref
immutable struct AllConstantsConcrete {
	CString[] cStrings;
	Constant staticSymbols;
	ArrTypeAndConstantsConcrete[] arrs;
	// These are just the by-ref records
	PointerTypeAndConstantsConcrete[] pointers;
}

immutable struct ConcreteVar {
	VarDecl* source;
	ConcreteType type;
}

immutable struct ConcreteProgram {
	@safe @nogc pure nothrow:

	AllConstantsConcrete allConstants;
	ConcreteStruct*[] allStructs;
	ConcreteVar*[] allVars;
	ConcreteFun*[] allFuns;
	Map!(ConcreteStruct*, ConcreteLambdaImpl[]) funStructToImpls;
	ConcreteCommonFuns commonFuns;

	//TODO:NOT INSTANCE
	ConcreteFun* markFun() return scope =>
		commonFuns.markFun;
	ConcreteFun* rtMain() return scope =>
		commonFuns.rtMain;
	ConcreteFun* userMain() return scope =>
		commonFuns.userMain;
	ConcreteFun* allocFun() return scope =>
		commonFuns.allocFun;
	ConcreteFun* throwImplFun() return scope =>
		commonFuns.throwImpl;
}

immutable struct ConcreteCommonFuns {
	ConcreteFun* allocFun;
	ConcreteFun* markFun;
	ConcreteFun* rtMain;
	ConcreteFun* throwImpl;
	ConcreteFun* userMain;
}

immutable struct ConcreteLambdaImpl {
	ConcreteType closureType;
	ConcreteFun* impl;
}
