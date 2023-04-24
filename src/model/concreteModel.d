module model.concreteModel;

@safe @nogc pure nothrow:

import model.constant : Constant;
import model.model :
	ClosureReferenceKind,
	decl,
	EnumBackingType,
	EnumFunction,
	EnumValue,
	FlagsFunction,
	FunDecl,
	FunInst,
	isArray,
	isSummon,
	isTuple,
	Local,
	name,
	Params,
	Purity,
	range,
	StructInst,
	VarDecl;
import util.col.arr : only, PtrAndSmallNumber;
import util.col.arrUtil : contains;
import util.col.map : Map;
import util.col.str : SafeCStr;
import util.hash : hashEnum, Hasher;
import util.late : Late, lateGet, lateIsSet, lateSet;
import util.opt : none, Opt, some;
import util.ptr : hashPtr;
import util.sourceRange : FileAndRange;
import util.sym : Sym, sym;
import util.union_ : Union;
import util.util : unreachable, verify;

enum BuiltinStructKind {
	bool_,
	char8,
	float32,
	float64,
	fun, // 'fun' or 'act'
	funPointer,
	int8,
	int16,
	int32,
	int64,
	nat8,
	nat16,
	nat32,
	nat64,
	pointerConst,
	pointerMut,
	void_,
}

Sym symOfBuiltinStructKind(BuiltinStructKind a) {
	final switch (a) {
		case BuiltinStructKind.bool_:
			return sym!"bool";
		case BuiltinStructKind.char8:
			return sym!"char8";
		case BuiltinStructKind.float32:
			return sym!"float-32";
		case BuiltinStructKind.float64:
			return sym!"float-64";
		case BuiltinStructKind.fun:
			return sym!"fun";
		case BuiltinStructKind.funPointer:
			return sym!"fun-pointer";
		case BuiltinStructKind.int8:
			return sym!"int-8";
		case BuiltinStructKind.int16:
			return sym!"int-16";
		case BuiltinStructKind.int32:
			return sym!"int-32";
		case BuiltinStructKind.int64:
			return sym!"int-64";
		case BuiltinStructKind.nat8:
			return sym!"nat-8";
		case BuiltinStructKind.nat16:
			return sym!"nat-16";
		case BuiltinStructKind.nat32:
			return sym!"nat-32";
		case BuiltinStructKind.nat64:
			return sym!"nat-64";
		case BuiltinStructKind.pointerConst:
			return sym!"const-pointer";
		case BuiltinStructKind.pointerMut:
			return sym!"pointer-mut";
		case BuiltinStructKind.void_:
			return sym!"void";
	}
}

immutable struct EnumValues {
	// size_t for 0 to N
	mixin Union!(size_t, EnumValue[]);
}

immutable struct ConcreteStructBody {
	immutable struct Builtin {
		BuiltinStructKind kind;
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

	void hash(ref Hasher hasher) scope {
		hashPtr(hasher, struct_);
		hashEnum(hasher, reference);
	}
}

bool isBogus(in ConcreteType a) =>
	a.reference == ReferenceKind.byVal &&
	isBogus(*a.struct_);
bool isVoid(in ConcreteType a) =>
	a.reference == ReferenceKind.byVal &&
	body_(*a.struct_).isA!(ConcreteStructBody.Builtin) &&
	body_(*a.struct_).as!(ConcreteStructBody.Builtin).kind == BuiltinStructKind.void_;

alias ReferenceKind = immutable ReferenceKind_;
private enum ReferenceKind_ { byVal, byRef, byRefRef }

Sym symOfReferenceKind(ReferenceKind a) {
	final switch (a) {
		case ReferenceKind.byVal:
			return sym!"by-val";
		case ReferenceKind.byRef:
			return sym!"by-ref";
		case ReferenceKind.byRefRef:
			return sym!"by-ref-ref";
	}
}

immutable struct TypeSize {
	size_t sizeBytes;
	size_t alignmentBytes;
}

Purity purity(ConcreteType a) =>
	a.struct_.purity;

ConcreteStruct* mustBeByVal(ConcreteType a) {
	verify(a.reference == ReferenceKind.byVal);
	return a.struct_;
}

immutable struct ConcreteStructInfo {
	ConcreteStructBody body_;
	bool isSelfMutable; //TODO: never used? (may need for GC though)
}

immutable struct ConcreteStructSource {
	immutable struct Invalid {} //TODO:KILL

	immutable struct Bogus {}

	immutable struct Inst {
		StructInst* inst;
		ConcreteType[] typeArgs;
	}

	immutable struct Lambda {
		ConcreteFun* containingFun;
		size_t index;
	}

	mixin Union!(Invalid, Bogus, Inst, Lambda);
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
	Late!ConcreteStructInfo info_;
	//TODO: this isn't needed outside of concretizeCtx.d
	Late!ReferenceKind defaultReferenceKind_;
	Late!TypeSize typeSize_;
	// Only set for records
	Late!(immutable size_t[]) fieldOffsets_;
}

bool isArray(in ConcreteStruct a) =>
	a.specialKind == ConcreteStruct.SpecialKind.array;
private bool isBogus(in ConcreteStruct a) =>
	a.source.isA!(ConcreteStructSource.Bogus);
bool isTuple(in ConcreteStruct a) =>
	a.specialKind == ConcreteStruct.SpecialKind.tuple;

private ref ConcreteStructInfo info(return scope ref ConcreteStruct a) =>
	lateGet(a.info_);

ref ConcreteStructBody body_(return scope ref ConcreteStruct a) =>
	info(a).body_;

TypeSize typeSize(in ConcreteStruct a) =>
	lateGet(a.typeSize_);

immutable(size_t[]) fieldOffsets(return ref ConcreteStruct a) =>
	lateGet(a.fieldOffsets_);

bool isSelfMutable(ref ConcreteStruct a) =>
	info(a).isSelfMutable;

ReferenceKind defaultReferenceKind(in ConcreteStruct a) =>
	lateGet(a.defaultReferenceKind_);

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
			return typeSize(*a.struct_);
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

Sym symOfConcreteMutability(ConcreteMutability a) {
	final switch (a) {
		case ConcreteMutability.const_:
			return sym!"const";
		case ConcreteMutability.mutable:
			return sym!"mutable";
	}
}

immutable struct ConcreteField {
	Sym debugName;
	ConcreteMutability mutability;
	ConcreteType type;
}

immutable struct ConcreteLocalSource {
	immutable struct Closure {}
	immutable struct Generated { Sym name; }
	mixin Union!(Local*, Closure, Generated);
}

immutable struct ConcreteLocal {
	@safe @nogc pure nothrow:

	ConcreteLocalSource source;
	ConcreteType type;

	bool isAllocated() scope =>
		source.matchIn!bool(
			(in Local x) => x.isAllocated,
			(in ConcreteLocalSource.Closure) => false,
			(in ConcreteLocalSource.Generated) => false);
}

immutable struct ConcreteFunBody {
	immutable struct Builtin {
		ConcreteType[] typeArgs;
	}
	immutable struct CreateRecord {}
	immutable struct CreateUnion {
		size_t memberIndex;
	}
	immutable struct Extern {
		Sym libraryName;
	}
	immutable struct FlagsFn {
		ulong allValue;
		FlagsFunction fn;
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
		RecordFieldGet,
		RecordFieldPointer,
		RecordFieldSet,
		VarGet,
		VarSet);
}

immutable struct ConcreteFunSource {
	immutable struct Lambda {
		FileAndRange range;
		ConcreteFun* containingFun;
		size_t index; // nth lambda in the containing function
	}

	immutable struct Test {
		FileAndRange range;
		size_t testIndex;
	}

	mixin Union!(FunInst*, Lambda*, Test*);
}
static assert(ConcreteFunSource.sizeof == ulong.sizeof);

// We generate a ConcreteFun for:
// Each instantiation of a FunDecl
// Each lambda inside an instantiation of a FunDecl
immutable struct ConcreteFun {
	ConcreteFunSource source;
	ConcreteType returnType;
	ConcreteLocal[] paramsIncludingClosure;
	Late!ConcreteFunBody _body_;
}

bool isVariadic(in ConcreteFun a) =>
	a.source.matchIn!bool(
		(in FunInst x) =>
			x.decl.params.isA!(Params.Varargs*),
		(in ConcreteFunSource.Lambda) =>
			false,
		(in ConcreteFunSource.Test) =>
			false);

Opt!Sym name(ref ConcreteFun a) =>
	a.source.match!(Opt!Sym)(
		(ref FunInst it) =>
			some(it.name),
		(ref ConcreteFunSource.Lambda) =>
			none!Sym,
		(ref ConcreteFunSource.Test) =>
			none!Sym);

bool isSummon(ref ConcreteFun a) =>
	a.source.match!bool(
		(ref FunInst it) =>
			isSummon(*decl(it)),
		(ref ConcreteFunSource.Lambda it) =>
			isSummon(*it.containingFun),
		(ref ConcreteFunSource.Test) =>
			// 'isSummon' is called for direct calls, but tests are never called directly
			unreachable!bool());

FileAndRange concreteFunRange(in ConcreteFun a) =>
	a.source.matchIn!FileAndRange(
		(in FunInst x) =>
			decl(x).range,
		(in ConcreteFunSource.Lambda x) =>
			x.range,
		(in ConcreteFunSource.Test x) =>
			x.range);

bool isFunOrActSubscript(ref ConcreteProgram program, ref ConcreteFun a) =>
	a.source.isA!(FunInst*) && contains(program.commonFuns.funOrActSubscriptFunDecls, decl(*a.source.as!(FunInst*)));

bool isMarkVisitFun(ref ConcreteProgram program, ref ConcreteFun a) =>
	a.source.isA!(FunInst*) && decl(*a.source.as!(FunInst*)) == program.commonFuns.markVisitFunDecl;

ref ConcreteFunBody body_(return scope ref ConcreteFun a) =>
	lateGet(a._body_);

void setBody(ref ConcreteFun a, ConcreteFunBody value) {
	lateSet(a._body_, value);
}

immutable struct ConcreteExpr {
	ConcreteType type;
	FileAndRange range;
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
		body_(*closureParam.type.struct_).as!(ConcreteStructBody.Record).fields[fieldIndex].type;
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
	SafeCStr[] cStrings;
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
	FunDecl*[] funOrActSubscriptFunDecls;
	ConcreteFun* markFun;
	FunDecl* markVisitFunDecl;
	ConcreteFun* rtMain;
	ConcreteFun* throwImpl;
	ConcreteFun* userMain;
}

immutable struct ConcreteLambdaImpl {
	ConcreteType closureType;
	ConcreteFun* impl;
}
