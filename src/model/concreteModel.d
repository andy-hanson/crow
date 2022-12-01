module model.concreteModel;

@safe @nogc pure nothrow:

import model.constant : Constant;
import model.model :
	ClosureReferenceKind,
	debugName,
	decl,
	EnumBackingType,
	EnumFunction,
	EnumValue,
	FlagsFunction,
	FunDecl,
	FunInst,
	isArray,
	Local,
	name,
	Param,
	Params,
	Purity,
	range,
	StructInst,
	summon;
import util.col.arr : empty, only, PtrAndSmallNumber;
import util.col.arrUtil : contains;
import util.col.dict : Dict;
import util.col.str : SafeCStr;
import util.hash : hashEnum, Hasher;
import util.late : Late, lateGet, lateIsSet, lateSet;
import util.opt : none, Opt, some;
import util.ptr : hashPtr;
import util.sourceRange : FileAndRange;
import util.sym : AllSymbols, Sym, sym;
import util.union_ : Union;
import util.util : unreachable, verify;

enum BuiltinStructKind {
	bool_,
	char8,
	float32,
	float64,
	fun, // 'fun' or 'act'
	funPointerN, // fun-pointer0, fun-pointer1, etc...
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

immutable(Sym) symOfBuiltinStructKind(immutable BuiltinStructKind a) {
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
		case BuiltinStructKind.funPointerN:
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

struct EnumValues {
	// size_t for 0 to N
	mixin Union!(immutable size_t, immutable EnumValue[]);
}

struct ConcreteStructBody {
	struct Builtin {
		immutable BuiltinStructKind kind;
		immutable ConcreteType[] typeArgs;
	}
	struct Enum {
		immutable EnumBackingType backingType;
		immutable EnumValues values;
	}
	struct Flags {
		immutable EnumBackingType backingType;
		immutable ulong[] values;
	}
	struct Extern {}
	struct Record {
		immutable ConcreteField[] fields;
	}
	struct Union {
		// In the concrete model we identify members by index, so don't care about their names
		immutable Opt!ConcreteType[] members;
	}

	mixin .Union!(
		immutable Builtin,
		immutable Enum,
		immutable Extern,
		immutable Flags,
		immutable Record,
		immutable Union);
}

struct ConcreteType {
	@safe @nogc pure nothrow:

	immutable ReferenceKind reference;
	immutable ConcreteStruct* struct_;

	immutable(bool) opEquals(scope immutable ConcreteType b) scope immutable =>
		struct_ == b.struct_ && reference == reference;

	void hash(ref Hasher hasher) scope immutable {
		hashPtr(hasher, struct_);
		hashEnum(hasher, reference);
	}
}

enum ReferenceKind { byVal, byRef, byRefRef }

immutable(Sym) symOfReferenceKind(immutable ReferenceKind a) {
	final switch (a) {
		case ReferenceKind.byVal:
			return sym!"by-val";
		case ReferenceKind.byRef:
			return sym!"by-ref";
		case ReferenceKind.byRefRef:
			return sym!"by-ref-ref";
	}
}

struct TypeSize {
	immutable size_t sizeBytes;
	immutable size_t alignmentBytes;
}

immutable(Purity) purity(immutable ConcreteType a) =>
	a.struct_.purity;

immutable(ConcreteStruct*) mustBeByVal(immutable ConcreteType a) {
	verify(a.reference == ReferenceKind.byVal);
	return a.struct_;
}

struct ConcreteStructInfo {
	immutable ConcreteStructBody body_;
	immutable bool isSelfMutable; //TODO: never used? (may need for GC though)
}

struct ConcreteStructSource {
	@safe @nogc pure nothrow:

	struct Inst {
		immutable StructInst* inst;
		immutable ConcreteType[] typeArgs;
	}

	struct Lambda {
		immutable ConcreteFun* containingFun;
		immutable size_t index;
	}

	mixin Union!(immutable Inst, immutable Lambda);
}

struct ConcreteStruct {
	@safe @nogc pure nothrow:

	immutable Purity purity;
	immutable ConcreteStructSource source;
	Late!(immutable ConcreteStructInfo) info_;
	//TODO: this isn't needed outside of concretizeCtx.d
	Late!(immutable ReferenceKind) defaultReferenceKind_;
	Late!(immutable TypeSize) typeSize_;
	// Only set for records
	Late!(immutable size_t[]) fieldOffsets_;
}

immutable(bool) isArray(ref immutable ConcreteStruct a) =>
	a.source.match!(immutable bool)(
		(immutable ConcreteStructSource.Inst it) =>
			isArray(*it.inst),
		(immutable ConcreteStructSource.Lambda it) =>
			false);

private ref immutable(ConcreteStructInfo) info(scope return ref const ConcreteStruct a) =>
	lateGet(a.info_);

ref immutable(ConcreteStructBody) body_(scope return ref immutable ConcreteStruct a) =>
	info(a).body_;

immutable(TypeSize) typeSize(ref immutable ConcreteStruct a) =>
	lateGet(a.typeSize_);

ref immutable(size_t[]) fieldOffsets(scope return ref immutable ConcreteStruct a) =>
	lateGet(a.fieldOffsets_);

immutable(bool) isSelfMutable(ref immutable ConcreteStruct a) =>
	info(a).isSelfMutable;

immutable(ReferenceKind) defaultReferenceKind(ref immutable ConcreteStruct a) =>
	lateGet(a.defaultReferenceKind_);

//TODO: this is only useful during concretize, move
immutable(bool) hasSizeOrPointerSizeBytes(ref immutable ConcreteType a) {
	final switch (a.reference) {
		case ReferenceKind.byVal:
			return lateIsSet(a.struct_.typeSize_);
		case ReferenceKind.byRef:
			return true;
		case ReferenceKind.byRefRef:
			return true;
	}
}

immutable(TypeSize) sizeOrPointerSizeBytes(ref immutable ConcreteType a) {
	final switch (a.reference) {
		case ReferenceKind.byVal:
			return typeSize(*a.struct_);
		case ReferenceKind.byRef:
		case ReferenceKind.byRefRef:
			return immutable TypeSize(8, 8);
	}
}

immutable(ConcreteType) byRef(immutable ConcreteType t) =>
	immutable ConcreteType(ReferenceKind.byRef, t.struct_);

immutable(ConcreteType) byVal(ref immutable ConcreteType t) =>
	immutable ConcreteType(ReferenceKind.byVal, t.struct_);

enum ConcreteMutability {
	const_,
	mutable,
}

immutable(Sym) symOfConcreteMutability(immutable ConcreteMutability a) {
	final switch (a) {
		case ConcreteMutability.const_:
			return sym!"const";
		case ConcreteMutability.mutable:
			return sym!"mutable";
	}
}

struct ConcreteField {
	immutable Sym debugName;
	immutable ConcreteMutability mutability;
	immutable ConcreteType type;
}

struct ConcreteParamSource {
	struct Closure {}
	struct Synthetic {}
	mixin Union!(immutable Closure, immutable Param*, immutable Synthetic);
}
static assert(ConcreteParamSource.sizeof == ulong.sizeof);

struct ConcreteParam {
	immutable ConcreteParamSource source;
	immutable Opt!size_t index; // not present for closure param
	immutable ConcreteType type;
}

struct ConcreteLocal {
	@safe @nogc pure nothrow:

	immutable Local* source;
	immutable ConcreteType type;

	immutable(bool) isAllocated() immutable =>
		source.isAllocated;
}

struct ConcreteFunBody {
	@safe @nogc pure nothrow:

	struct Builtin {
		immutable ConcreteType[] typeArgs;
	}
	struct CreateRecord {}
	struct CreateUnion {
		immutable size_t memberIndex;
	}
	struct Extern {
		immutable bool isGlobal;
		immutable Sym libraryName;
	}
	struct FlagsFn {
		immutable ulong allValue;
		immutable FlagsFunction fn;
	}
	struct RecordFieldGet {
		immutable size_t fieldIndex;
	}
	struct RecordFieldSet {
		immutable size_t fieldIndex;
	}
	struct ThreadLocal {}

	mixin Union!(
		immutable Builtin,
		immutable Constant,
		immutable CreateRecord,
		immutable CreateUnion,
		immutable EnumFunction,
		immutable Extern,
		immutable ConcreteExpr,
		immutable FlagsFn,
		immutable RecordFieldGet,
		immutable RecordFieldSet,
		immutable ThreadLocal);
}

immutable(bool) isGlobal(ref immutable ConcreteFunBody a) =>
	a.isA!(ConcreteFunBody.Extern) && a.as!(ConcreteFunBody.Extern).isGlobal;

struct ConcreteFunSource {
	struct Lambda {
		immutable FileAndRange range;
		immutable ConcreteFun* containingFun;
		immutable size_t index; // nth lambda in the containing function
	}

	struct Test {
		immutable FileAndRange range;
		immutable size_t testIndex;
	}

	mixin Union!(immutable FunInst*, immutable Lambda*, immutable Test*);
}
static assert(ConcreteFunSource.sizeof == ulong.sizeof);

// We generate a ConcreteFun for:
// Each instantiation of a FunDecl
// Each lambda inside an instantiation of a FunDecl
struct ConcreteFun {
	immutable ConcreteFunSource source;
	immutable ConcreteType returnType;
	immutable Opt!(ConcreteParam*) closureParam;
	immutable ConcreteParam[] paramsExcludingClosure;
	Late!(immutable ConcreteFunBody) _body_;
}

immutable(bool) isVariadic(ref immutable ConcreteFun a) =>
	a.source.match!(immutable bool)(
		(ref immutable FunInst i) =>
			i.params.isA!(Params.Varargs*),
		(ref immutable ConcreteFunSource.Lambda) =>
			false,
		(ref immutable ConcreteFunSource.Test) =>
			false);

immutable(Opt!Sym) name(ref immutable ConcreteFun a) =>
	a.source.match!(immutable Opt!Sym)(
		(ref immutable FunInst it) =>
			some(it.name),
		(ref immutable ConcreteFunSource.Lambda) =>
			none!Sym,
		(ref immutable ConcreteFunSource.Test) =>
			none!Sym);

immutable(bool) isSummon(ref immutable ConcreteFun a) =>
	a.source.match!(immutable bool)(
		(ref immutable FunInst it) =>
			summon(*decl(it)),
		(ref immutable ConcreteFunSource.Lambda it) =>
			isSummon(*it.containingFun),
		(ref immutable ConcreteFunSource.Test) =>
			// 'isSummon' is called for direct calls, but tests are never called directly
			unreachable!(immutable bool)());

immutable(FileAndRange) concreteFunRange(ref immutable ConcreteFun a, ref const AllSymbols allSymbols) =>
	a.source.match!(immutable FileAndRange)(
		(ref immutable FunInst x) =>
			decl(x).range,
		(ref immutable ConcreteFunSource.Lambda x) =>
			x.range,
		(ref immutable ConcreteFunSource.Test x) =>
			x.range);

immutable(bool) isFunOrActSubscript(ref immutable ConcreteProgram program, ref immutable ConcreteFun a) =>
	a.source.isA!(FunInst*) && contains(program.commonFuns.funOrActSubscriptFunDecls, decl(*a.source.as!(FunInst*)));

immutable(bool) isMarkVisitFun(ref immutable ConcreteProgram program, ref immutable ConcreteFun a) =>
	a.source.isA!(FunInst*) && decl(*a.source.as!(FunInst*)) == program.commonFuns.markVisitFunDecl;

ref immutable(ConcreteFunBody) body_(scope return ref const ConcreteFun a) =>
	lateGet(a._body_);

void setBody(ref ConcreteFun a, immutable ConcreteFunBody value) {
	lateSet(a._body_, value);
}

immutable(bool) isGlobal(ref immutable ConcreteFun a) =>
	isGlobal(body_(a));

struct ConcreteExpr {
	immutable ConcreteType type;
	immutable FileAndRange range;
	immutable ConcreteExprKind kind;
}

struct ConcreteClosureRef {
	@safe @nogc pure nothrow:

	immutable PtrAndSmallNumber!ConcreteParam paramAndIndex;

	immutable(ConcreteParam*) closureParam() immutable =>
		paramAndIndex.ptr;

	immutable(ushort) fieldIndex() immutable =>
		paramAndIndex.number;
}

struct ConcreteExprKind {
	@safe @nogc pure nothrow:

	struct Alloc {
		immutable ConcreteExpr inner;
	}

	struct Call {
		immutable ConcreteFun* called;
		immutable ConcreteExpr[] args;
	}

	struct ClosureCreate {
		immutable ConcreteVariableRef[] args;
	}

	struct ClosureGet {
		immutable ConcreteClosureRef closureRef;
		immutable ClosureReferenceKind referenceKind;
	}

	struct ClosureSet {
		immutable ConcreteClosureRef closureRef;
		immutable ConcreteExpr value;
		// referenceKind is always allocated
	}

	struct Cond {
		immutable ConcreteExpr cond;
		immutable ConcreteExpr then;
		immutable ConcreteExpr else_;
	}

	struct CreateArr {
		@safe @nogc pure nothrow:

		immutable ConcreteStruct* arrType;
		immutable ConcreteExpr[] args;

		immutable this(immutable ConcreteStruct* at, immutable ConcreteExpr[] as) {
			arrType = at;
			args = as;
			verify(!empty(args));
		}
	}

	// TODO: this is only used for closures now, since normal record creation always goes through a function.
	struct CreateRecord {
		immutable ConcreteExpr[] args;
	}

	// Only used for 'safe-value', otherwise it goes through a function
	struct CreateUnion {
		immutable size_t memberIndex;
		immutable ConcreteExpr arg;
	}

	struct Drop {
		immutable ConcreteExpr arg;
	}

	struct Let {
		immutable ConcreteLocal* local;
		immutable ConcreteExpr value;
		immutable ConcreteExpr then;
	}

	// May be a fun or fun-mut.
	// (A fun-ref is a lambda wrapped in CreateRecord.)
	struct Lambda {
		immutable size_t memberIndex; // Member index of a Union (which hasn't been created yet)
		immutable Opt!(ConcreteExpr*) closure;
	}

	struct LocalGet {
		immutable ConcreteLocal* local;
	}

	struct LocalSet {
		immutable ConcreteLocal* local;
		immutable ConcreteExpr value;
	}

	struct Loop {
		immutable ConcreteExpr body_;
	}

	struct LoopBreak {
		immutable ConcreteExprKind.Loop* loop;
		immutable ConcreteExpr value;
	}

	struct LoopContinue {
		immutable ConcreteExprKind.Loop* loop;
	}

	struct MatchEnum {
		immutable ConcreteExpr matchedValue;
		immutable ConcreteExpr[] cases;
	}

	struct MatchUnion {
		struct Case {
			immutable Opt!(ConcreteLocal*) local;
			immutable ConcreteExpr then;
		}

		immutable ConcreteExpr matchedValue;
		immutable Case[] cases;
	}

	struct ParamGet {
		immutable ConcreteParam* param;
	}

	struct PtrToField {
		immutable ConcreteExpr target;
		immutable size_t fieldIndex;
	}

	struct PtrToLocal {
		immutable ConcreteLocal* local;
	}

	struct PtrToParam {
		immutable ConcreteParam* param;
	}

	struct Seq {
		immutable ConcreteExpr first;
		immutable ConcreteExpr then;
	}

	struct Throw {
		// a `c-str`
		immutable ConcreteExpr thrown;
	}

	mixin Union!(
		immutable Alloc*,
		immutable Call,
		immutable ClosureCreate,
		immutable ClosureGet*,
		immutable ClosureSet*,
		immutable Cond*,
		immutable Constant,
		immutable CreateArr*,
		immutable CreateRecord,
		immutable CreateUnion*,
		immutable Drop*,
		immutable Lambda,
		immutable Let*,
		immutable LocalGet,
		immutable LocalSet*,
		immutable Loop*,
		immutable LoopBreak*,
		immutable LoopContinue,
		immutable MatchEnum*,
		immutable MatchUnion*,
		immutable ParamGet,
		immutable PtrToField*,
		immutable PtrToLocal,
		immutable PtrToParam,
		immutable Seq*,
		immutable Throw*);
}

struct ConcreteVariableRef {
	mixin Union!(
		immutable Constant,
		immutable ConcreteLocal*,
		immutable ConcreteParam*,
		immutable ConcreteClosureRef);
}

immutable(ConcreteType) elementType(return scope ref immutable ConcreteExprKind.CreateArr a) =>
	only(a.arrType.source.as!(ConcreteStructSource.Inst).typeArgs);

immutable(ConcreteType) returnType(return scope ref immutable ConcreteExprKind.Call a) =>
	a.called.returnType;

struct ArrTypeAndConstantsConcrete {
	immutable ConcreteStruct* arrType;
	immutable ConcreteType elementType;
	immutable Constant[][] constants;
}

struct PointerTypeAndConstantsConcrete {
	immutable ConcreteStruct* pointeeType;
	immutable Constant[] constants;
}

// TODO: rename -- this is not all constants, just the ones by-ref
struct AllConstantsConcrete {
	immutable SafeCStr[] cStrings;
	immutable Constant staticSymbols;
	immutable ArrTypeAndConstantsConcrete[] arrs;
	// These are just the by-ref records
	immutable PointerTypeAndConstantsConcrete[] pointers;
}

struct ConcreteProgram {
	@safe @nogc pure nothrow:

	immutable AllConstantsConcrete allConstants;
	immutable ConcreteStruct*[] allStructs;
	immutable ConcreteFun*[] allFuns;
	immutable Dict!(ConcreteStruct*, ConcreteLambdaImpl[]) funStructToImpls;
	immutable ConcreteCommonFuns commonFuns;

	//TODO:NOT INSTANCE
	immutable(ConcreteFun*) markFun() immutable { return commonFuns.markFun; }
	immutable(ConcreteFun*) rtMain() immutable { return commonFuns.rtMain; }
	immutable(ConcreteFun*) userMain() immutable { return commonFuns.userMain; }
	immutable(ConcreteFun*) allocFun() immutable { return commonFuns.allocFun; }
	immutable(ConcreteFun*) throwImplFun() immutable { return commonFuns.throwImpl; }
}

struct ConcreteCommonFuns {
	immutable ConcreteFun* allocFun;
	immutable FunDecl*[] funOrActSubscriptFunDecls;
	immutable ConcreteFun* markFun;
	immutable FunDecl* markVisitFunDecl;
	immutable ConcreteFun* rtMain;
	immutable ConcreteFun* throwImpl;
	immutable ConcreteFun* userMain;
}

struct ConcreteLambdaImpl {
	immutable ConcreteType closureType;
	immutable ConcreteFun* impl;
}
