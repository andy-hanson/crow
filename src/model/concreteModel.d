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
	FunInst,
	isArray,
	isCallWithCtxFun,
	isCompareFun,
	isMarkVisitFun,
	isVarargs,
	Local,
	name,
	Param,
	Purity,
	range,
	StructInst,
	summon;
import util.col.arr : empty, only, PtrAndSmallNumber;
import util.col.dict : Dict;
import util.col.str : SafeCStr;
import util.hash : hashEnum, Hasher;
import util.late : Late, lateGet, lateIsSet, lateSet;
import util.opt : none, Opt, some;
import util.ptr : hashPtr, TaggedPtr;
import util.sourceRange : FileAndRange;
import util.sym : AllSymbols, shortSym, Sym, sym;
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
			return shortSym("bool");
		case BuiltinStructKind.char8:
			return shortSym("char8");
		case BuiltinStructKind.float32:
			return shortSym("float-32");
		case BuiltinStructKind.float64:
			return shortSym("float-64");
		case BuiltinStructKind.fun:
			return shortSym("fun");
		case BuiltinStructKind.funPointerN:
			return shortSym("fun-pointer");
		case BuiltinStructKind.int8:
			return shortSym("int-8");
		case BuiltinStructKind.int16:
			return shortSym("int-16");
		case BuiltinStructKind.int32:
			return shortSym("int-32");
		case BuiltinStructKind.int64:
			return shortSym("int-64");
		case BuiltinStructKind.nat8:
			return shortSym("nat-8");
		case BuiltinStructKind.nat16:
			return shortSym("nat-16");
		case BuiltinStructKind.nat32:
			return shortSym("nat-32");
		case BuiltinStructKind.nat64:
			return shortSym("nat-64");
		case BuiltinStructKind.pointerConst:
			return sym!"const-pointer";
		case BuiltinStructKind.pointerMut:
			return shortSym("pointer-mut");
		case BuiltinStructKind.void_:
			return shortSym("void");
	}
}

struct ConcreteStructBody {
	@safe @nogc pure nothrow:

	struct Builtin {
		immutable BuiltinStructKind kind;
		immutable ConcreteType[] typeArgs;
	}
	struct Enum {
		@safe @nogc pure nothrow:

		@disable this();
		immutable this(immutable EnumBackingType b, immutable size_t a) {
			backingType = b; kind = Kind.size; size = a;
		}
		@trusted immutable this(immutable EnumBackingType b, immutable EnumValue[] a) {
			backingType = b; kind = Kind.values; values = a;
		}

		immutable EnumBackingType backingType;
		private:
		enum Kind {
			size, // for 0 to N
			values,
		}
		immutable Kind kind;
		union {
			immutable size_t size;
			immutable EnumValue[] values;
		}
	}
	struct Flags {
		immutable EnumBackingType backingType;
		immutable ulong[] values;
	}
	struct ExternPtr {}
	struct Record {
		immutable ConcreteField[] fields;
	}
	struct Union {
		// In the concrete model we identify members by index, so don't care about their names
		immutable Opt!ConcreteType[] members;
	}

	private:
	enum Kind {
		builtin,
		externPtr,
		record,
		enum_,
		flags,
		union_,
	}
	immutable Kind kind;
	union {
		immutable Builtin builtin;
		immutable Enum enum_;
		immutable Flags flags;
		immutable ExternPtr externPtr;
		immutable Record record;
		immutable Union union_;
	}

	public:
	@trusted immutable this(immutable Builtin a) { kind = Kind.builtin; builtin = a; }
	@trusted immutable this(immutable Enum a) { kind = Kind.enum_; enum_ = a; }
	@trusted immutable this(immutable Flags a) { kind = Kind.flags; flags = a; }
	immutable this(immutable ExternPtr a) { kind = Kind.externPtr; externPtr = a; }
	@trusted immutable this(immutable Record a) { kind = Kind.record; record = a; }
	@trusted immutable this(immutable Union a) { kind = Kind.union_; union_ = a; }
}

@trusted immutable(T) matchEnum(T)(
	ref immutable ConcreteStructBody.Enum a,
	scope immutable(T) delegate(immutable size_t) @safe @nogc pure nothrow cbSize,
	scope immutable(T) delegate(immutable EnumValue[]) @safe @nogc pure nothrow cbValues,
) {
	final switch (a.kind) {
		case ConcreteStructBody.Enum.Kind.size:
			return cbSize(a.size);
		case ConcreteStructBody.Enum.Kind.values:
			return cbValues(a.values);
	}
}

@trusted ref immutable(ConcreteStructBody.Builtin) asBuiltin(scope return ref immutable ConcreteStructBody a) {
	verify(a.kind == ConcreteStructBody.Kind.builtin);
	return a.builtin;
}

@trusted ref immutable(ConcreteStructBody.Enum) asEnum(scope return ref immutable ConcreteStructBody a) {
	verify(a.kind == ConcreteStructBody.Kind.enum_);
	return a.enum_;
}

@trusted ref immutable(ConcreteStructBody.Flags) asFlags(scope return ref immutable ConcreteStructBody a) {
	verify(a.kind == ConcreteStructBody.Kind.flags);
	return a.flags;
}

@trusted ref immutable(ConcreteStructBody.Record) asRecord(scope return ref immutable ConcreteStructBody a) {
	verify(a.kind == ConcreteStructBody.Kind.record);
	return a.record;
}

@trusted ref immutable(ConcreteStructBody.Union) asUnion(scope return ref immutable ConcreteStructBody a) {
	verify(a.kind == ConcreteStructBody.Kind.union_);
	return a.union_;
}

@trusted immutable(T) matchConcreteStructBody(T)(
	ref immutable ConcreteStructBody a,
	scope immutable(T) delegate(ref immutable ConcreteStructBody.Builtin) @safe @nogc pure nothrow cbBuiltin,
	scope immutable(T) delegate(ref immutable ConcreteStructBody.Enum) @safe @nogc pure nothrow cbEnum,
	scope immutable(T) delegate(ref immutable ConcreteStructBody.Flags) @safe @nogc pure nothrow cbFlags,
	scope immutable(T) delegate(ref immutable ConcreteStructBody.ExternPtr) @safe @nogc pure nothrow cbExternPtr,
	scope immutable(T) delegate(ref immutable ConcreteStructBody.Record) @safe @nogc pure nothrow cbRecord,
	scope immutable(T) delegate(ref immutable ConcreteStructBody.Union) @safe @nogc pure nothrow cbUnion,
) {
	final switch (a.kind) {
		case ConcreteStructBody.Kind.builtin:
			return cbBuiltin(a.builtin);
		case ConcreteStructBody.Kind.enum_:
			return cbEnum(a.enum_);
		case ConcreteStructBody.Kind.flags:
			return cbFlags(a.flags);
		case ConcreteStructBody.Kind.externPtr:
			return cbExternPtr(a.externPtr);
		case ConcreteStructBody.Kind.record:
			return cbRecord(a.record);
		case ConcreteStructBody.Kind.union_:
			return cbUnion(a.union_);
	}
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
			return shortSym("by-val");
		case ReferenceKind.byRef:
			return shortSym("by-ref");
		case ReferenceKind.byRefRef:
			return shortSym("by-ref-ref");
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

	@trusted immutable this(immutable Lambda a) { kind_ = Kind.lambda; lambda_ = a; }
	@trusted immutable this(immutable Inst a) { kind_ = Kind.inst; inst_ = a; }

	private:
	enum Kind {
		inst,
		lambda,
	}
	immutable Kind kind_;
	union {
		immutable Inst inst_;
		immutable Lambda lambda_;
	}
}

@trusted ref immutable(ConcreteStructSource.Inst) asInst(scope return ref immutable ConcreteStructSource a) {
	verify(a.kind_ == ConcreteStructSource.Kind.inst);
	return a.inst_;
}

@trusted immutable(T) matchConcreteStructSource(T, alias cbInst, alias cbLambda)(ref immutable ConcreteStructSource a) {
	final switch (a.kind_) {
		case ConcreteStructSource.Kind.inst:
			return cbInst(a.inst_);
		case ConcreteStructSource.Kind.lambda:
			return cbLambda(a.lambda_);
	}
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
	matchConcreteStructSource!(
		immutable bool,
		(ref immutable ConcreteStructSource.Inst it) =>
			isArray(*it.inst),
		(ref immutable ConcreteStructSource.Lambda it) =>
			false,
	)(a.source);

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
			return shortSym("const");
		case ConcreteMutability.mutable:
			return shortSym("mutable");
	}
}

struct ConcreteField {
	immutable Sym debugName;
	immutable ConcreteMutability mutability;
	immutable ConcreteType type;
}

struct ConcreteParamSource {
	@safe @nogc pure nothrow:

	struct Closure {}
	struct Synthetic {}

	immutable this(immutable Closure a) { kind_ = Kind.closure; closure_ = a; }
	@trusted immutable this(immutable Param* a) { kind_ = Kind.param; param_ = a; }
	immutable this(immutable Synthetic a) { kind_ = Kind.synthetic; synthetic_ = a; }

	private:
	enum Kind {
		closure,
		param,
		synthetic,
	}
	immutable Kind kind_;
	union {
		immutable Closure closure_;
		immutable Param* param_;
		immutable Synthetic synthetic_;
	}
}

@trusted immutable(T) matchConcreteParamSource(T)(
	ref immutable ConcreteParamSource a,
	scope immutable(T) delegate(ref immutable ConcreteParamSource.Closure) @safe @nogc pure nothrow cbClosure,
	scope immutable(T) delegate(ref immutable Param) @safe @nogc pure nothrow cbParam,
	scope immutable(T) delegate(ref immutable ConcreteParamSource.Synthetic) @safe @nogc pure nothrow cbSynthetic,
) {
	final switch (a.kind_) {
		case ConcreteParamSource.Kind.closure:
			return cbClosure(a.closure_);
		case ConcreteParamSource.Kind.param:
			return cbParam(*a.param_);
		case ConcreteParamSource.Kind.synthetic:
			return cbSynthetic(a.synthetic_);
	}
}

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
	struct CreateEnum {
		immutable EnumValue value;
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

	private:
	enum Kind {
		builtin,
		createEnum,
		createRecord,
		createUnion,
		enumFunction,
		extern_,
		flagsFn,
		concreteExpr,
		recordFieldGet,
		recordFieldSet,
		threadLocal,
	}
	immutable Kind kind;
	union {
		immutable Builtin builtin;
		immutable CreateEnum createEnum;
		immutable CreateRecord createRecord;
		immutable CreateUnion createUnion;
		immutable EnumFunction enumFunction;
		immutable Extern extern_;
		immutable FlagsFn flagsFn;
		immutable ConcreteExpr concreteExpr;
		immutable RecordFieldGet recordFieldGet;
		immutable RecordFieldSet recordFieldSet;
		immutable ThreadLocal threadLocal;
	}

	public:
	@trusted immutable this(immutable Builtin a) { kind = Kind.builtin; builtin = a; }
	immutable this(immutable CreateEnum a) { kind = Kind.createEnum; createEnum = a; }
	@trusted immutable this(immutable CreateRecord a) { kind = Kind.createRecord; createRecord = a; }
	immutable this(immutable CreateUnion a) { kind = Kind.createUnion; createUnion = a; }
	immutable this(immutable EnumFunction a) { kind = Kind.enumFunction; enumFunction = a; }
	@trusted immutable this(immutable Extern a) { kind = Kind.extern_; extern_ = a; }
	@trusted immutable this(immutable ConcreteExpr a) {
		kind = Kind.concreteExpr; concreteExpr = a;
	}
	immutable this(immutable FlagsFn a) { kind = Kind.flagsFn; flagsFn = a; }
	immutable this(immutable RecordFieldGet a) { kind = Kind.recordFieldGet; recordFieldGet = a; }
	immutable this(immutable RecordFieldSet a) { kind = Kind.recordFieldSet; recordFieldSet = a; }
	immutable this(immutable ThreadLocal a) { kind = Kind.threadLocal; threadLocal = a; }
}

immutable(bool) isExtern(ref immutable ConcreteFunBody a) =>
	a.kind == ConcreteFunBody.Kind.extern_;

@trusted ref immutable(ConcreteFunBody.Builtin) asBuiltin(scope return ref immutable ConcreteFunBody a) {
	verify(a.kind == ConcreteFunBody.Kind.builtin);
	return a.builtin;
}

private @trusted ref immutable(ConcreteFunBody.Extern) asExtern(scope return ref immutable ConcreteFunBody a) {
	verify(isExtern(a));
	return a.extern_;
}

@trusted immutable(T) matchConcreteFunBody(T)(
	ref immutable ConcreteFunBody a,
	scope immutable(T) delegate(ref immutable ConcreteFunBody.Builtin) @safe @nogc pure nothrow cbBuiltin,
	scope immutable(T) delegate(ref immutable ConcreteFunBody.CreateEnum) @safe @nogc pure nothrow cbCreateEnum,
	scope immutable(T) delegate(ref immutable ConcreteFunBody.CreateRecord) @safe @nogc pure nothrow cbCreateRecord,
	scope immutable(T) delegate(ref immutable ConcreteFunBody.CreateUnion) @safe @nogc pure nothrow cbCreateUnion,
	scope immutable(T) delegate(immutable EnumFunction) @safe @nogc pure nothrow cbEnumFunction,
	scope immutable(T) delegate(ref immutable ConcreteFunBody.Extern) @safe @nogc pure nothrow cbExtern,
	scope immutable(T) delegate(ref immutable ConcreteExpr) @safe @nogc pure nothrow cbConcreteExpr,
	scope immutable(T) delegate(ref immutable ConcreteFunBody.FlagsFn) @safe @nogc pure nothrow cbFlagsFn,
	scope immutable(T) delegate(ref immutable ConcreteFunBody.RecordFieldGet) @safe @nogc pure nothrow cbRecordFieldGet,
	scope immutable(T) delegate(ref immutable ConcreteFunBody.RecordFieldSet) @safe @nogc pure nothrow cbRecordFieldSet,
	scope immutable(T) delegate(ref immutable ConcreteFunBody.ThreadLocal) @safe @nogc pure nothrow cbThreadLocal,
) {
	final switch (a.kind) {
		case ConcreteFunBody.Kind.builtin:
			return cbBuiltin(a.builtin);
		case ConcreteFunBody.Kind.createEnum:
			return cbCreateEnum(a.createEnum);
		case ConcreteFunBody.Kind.createRecord:
			return cbCreateRecord(a.createRecord);
		case ConcreteFunBody.Kind.createUnion:
			return cbCreateUnion(a.createUnion);
		case ConcreteFunBody.Kind.enumFunction:
			return cbEnumFunction(a.enumFunction);
		case ConcreteFunBody.Kind.extern_:
			return cbExtern(a.extern_);
		case ConcreteFunBody.Kind.flagsFn:
			return cbFlagsFn(a.flagsFn);
		case ConcreteFunBody.Kind.concreteExpr:
			return cbConcreteExpr(a.concreteExpr);
		case ConcreteFunBody.Kind.recordFieldGet:
			return cbRecordFieldGet(a.recordFieldGet);
		case ConcreteFunBody.Kind.recordFieldSet:
			return cbRecordFieldSet(a.recordFieldSet);
		case ConcreteFunBody.Kind.threadLocal:
			return cbThreadLocal(a.threadLocal);
	}
}

immutable(bool) isGlobal(ref immutable ConcreteFunBody a) =>
	isExtern(a) && asExtern(a).isGlobal;

struct ConcreteFunSource {
	@safe @nogc pure nothrow:

	struct Lambda {
		immutable FileAndRange range;
		immutable ConcreteFun* containingFun;
		immutable size_t index; // nth lambda in the containing function
	}

	struct Test {
		immutable FileAndRange range;
		immutable size_t testIndex;
	}

	@trusted immutable this(immutable FunInst* a) { kind_ = Kind.funInst; funInst_ = a; }
	@trusted immutable this(immutable Lambda* a) { kind_ = Kind.lambda; lambda_ = a; }
	@trusted immutable this(immutable Test* a) { kind_ = Kind.test; test_ = a; }

	private:
	enum Kind {
		funInst,
		lambda,
		test,
	}
	immutable Kind kind_;
	union {
		immutable FunInst* funInst_;
		immutable Lambda* lambda_;
		immutable Test* test_;
	}
}
static assert(ConcreteFunSource.sizeof <= 16);

@trusted immutable(FunInst*) asFunInst(ref immutable ConcreteFunSource a) {
	verify(a.kind_ == ConcreteFunSource.Kind.funInst);
	return a.funInst_;
}

@trusted immutable(T) matchConcreteFunSource(T, alias cbFunInst, alias cbLambda, alias cbTest)(
	ref immutable ConcreteFunSource a,
) {
	final switch (a.kind_) {
		case ConcreteFunSource.Kind.funInst:
			return cbFunInst(*a.funInst_);
		case ConcreteFunSource.Kind.lambda:
			return cbLambda(*a.lambda_);
		case ConcreteFunSource.Kind.test:
			return cbTest(*a.test_);
	}
}

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
	matchConcreteFunSource!(
		immutable bool,
		(ref immutable FunInst i) =>
			isVarargs(i.params),
		(ref immutable ConcreteFunSource.Lambda) =>
			false,
		(ref immutable ConcreteFunSource.Test) =>
			false,
	)(a.source);

immutable(Opt!Sym) name(ref immutable ConcreteFun a) =>
	matchConcreteFunSource!(
		immutable Opt!Sym,
		(ref immutable FunInst it) =>
			some(it.name),
		(ref immutable ConcreteFunSource.Lambda) =>
			none!Sym,
		(ref immutable ConcreteFunSource.Test) =>
			none!Sym,
	)(a.source);

immutable(bool) isSummon(ref immutable ConcreteFun a) =>
	matchConcreteFunSource!(
		immutable bool,
		(ref immutable FunInst it) =>
			summon(*decl(it)),
		(ref immutable ConcreteFunSource.Lambda it) =>
			isSummon(*it.containingFun),
		(ref immutable ConcreteFunSource.Test) =>
			// 'isSummon' is called for direct calls, but tests are never called directly
			unreachable!(immutable bool)(),
	)(a.source);

immutable(FileAndRange) concreteFunRange(ref immutable ConcreteFun a, ref const AllSymbols allSymbols) =>
	matchConcreteFunSource!(
		immutable FileAndRange,
		(ref immutable FunInst it) =>
			decl(it).range,
		(ref immutable ConcreteFunSource.Lambda it) =>
			it.range,
		(ref immutable ConcreteFunSource.Test it) =>
			it.range,
	)(a.source);

immutable(bool) isCallWithCtxFun(ref immutable ConcreteFun a) =>
	matchConcreteFunSource!(
		immutable bool,
		(ref immutable FunInst it) =>
			isCallWithCtxFun(it),
		(ref immutable ConcreteFunSource.Lambda) =>
			false,
		(ref immutable ConcreteFunSource.Test) =>
			false,
	)(a.source);

immutable(bool) isCompareFun(ref immutable ConcreteFun a) =>
	matchConcreteFunSource!(
		immutable bool,
		(ref immutable FunInst it) =>
			isCompareFun(it),
		(ref immutable ConcreteFunSource.Lambda) =>
			false,
		(ref immutable ConcreteFunSource.Test) =>
			false,
	)(a.source);

immutable(bool) isMarkVisitFun(ref immutable ConcreteFun a) =>
	matchConcreteFunSource!(
		immutable bool,
		(ref immutable FunInst it) =>
			isMarkVisitFun(it),
		(ref immutable ConcreteFunSource.Lambda) =>
			false,
		(ref immutable ConcreteFunSource.Test) =>
			false,
	)(a.source);

ref immutable(ConcreteFunBody) body_(scope return ref const ConcreteFun a) =>
	lateGet(a._body_);

void setBody(ref ConcreteFun a, immutable ConcreteFunBody value) {
	lateSet(a._body_, value);
}

immutable(bool) isExtern(ref immutable ConcreteFun a) =>
	isExtern(body_(a));

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

	private:
	enum Kind {
		alloc,
		call,
		closureCreate,
		closureGet,
		closureSet,
		cond,
		constant,
		createArr,
		createRecord,
		createUnion,
		drop,
		lambda,
		let,
		localGet,
		localSet,
		loop,
		loopBreak,
		loopContinue,
		matchEnum,
		matchUnion,
		paramGet,
		ptrToField,
		ptrToLocal,
		ptrToParam,
		seq,
		throw_,
	}
	immutable Kind kind;
	union {
		immutable Alloc* alloc;
		immutable Call call;
		immutable ClosureCreate closureCreate;
		immutable ClosureGet* closureGet;
		immutable ClosureSet* closureSet;
		immutable Cond* cond;
		immutable CreateArr* createArr;
		immutable Constant constant;
		immutable CreateRecord createRecord;
		immutable CreateUnion* createUnion;
		immutable Drop* drop;
		immutable Lambda lambda;
		immutable Let* let;
		immutable LocalGet localGet;
		immutable LocalSet* localSet;
		immutable Loop* loop;
		immutable LoopBreak* loopBreak;
		immutable LoopContinue loopContinue;
		immutable MatchEnum* matchEnum;
		immutable MatchUnion* matchUnion;
		immutable ParamGet paramGet;
		immutable PtrToField* ptrToField;
		immutable PtrToLocal ptrToLocal;
		immutable PtrToParam ptrToParam;
		immutable Seq* seq;
		immutable Throw* throw_;
	}

	public:
	@trusted immutable this(immutable Alloc* a) { kind = Kind.alloc; alloc = a; }
	@trusted immutable this(immutable Call a) { kind = Kind.call; call = a; }
	immutable this(immutable ClosureCreate a) { kind = Kind.closureCreate; closureCreate = a; }
	immutable this(immutable ClosureGet* a) { kind = Kind.closureGet; closureGet = a; }
	immutable this(immutable ClosureSet* a) { kind = Kind.closureSet; closureSet = a; }
	@trusted immutable this(immutable Cond* a) { kind = Kind.cond; cond = a; }
	@trusted immutable this(immutable CreateArr* a) { kind = Kind.createArr; createArr = a; }
	@trusted immutable this(immutable Constant a) { kind = Kind.constant; constant = a; }
	@trusted immutable this(immutable CreateRecord a) { kind = Kind.createRecord; createRecord = a; }
	immutable this(immutable CreateUnion* a) { kind = Kind.createUnion; createUnion = a; }
	immutable this(immutable Drop* a) { kind = Kind.drop; drop = a; }
	@trusted immutable this(immutable Lambda a) { kind = Kind.lambda; lambda = a; }
	@trusted immutable this(immutable Let* a) { kind = Kind.let; let = a; }
	@trusted immutable this(immutable LocalGet a) { kind = Kind.localGet; localGet = a; }
	@trusted immutable this(immutable LocalSet* a) { kind = Kind.localSet; localSet = a; }
	@trusted immutable this(immutable Loop* a) { kind = Kind.loop; loop = a; }
	@trusted immutable this(immutable LoopBreak* a) { kind = Kind.loopBreak; loopBreak = a; }
	immutable this(immutable LoopContinue a) { kind = Kind.loopContinue; loopContinue = a; }
	@trusted immutable this(immutable MatchEnum* a) { kind = Kind.matchEnum; matchEnum = a; }
	@trusted immutable this(immutable MatchUnion* a) { kind = Kind.matchUnion; matchUnion = a; }
	@trusted immutable this(immutable ParamGet a) { kind = Kind.paramGet; paramGet = a; }
	immutable this(immutable PtrToField* a) { kind = Kind.ptrToField; ptrToField = a; }
	immutable this(immutable PtrToLocal a) { kind = Kind.ptrToLocal; ptrToLocal = a; }
	immutable this(immutable PtrToParam a) { kind = Kind.ptrToParam; ptrToParam = a; }
	@trusted immutable this(immutable Seq* a) { kind = Kind.seq; seq = a; }
	immutable this(immutable Throw* a) { kind = Kind.throw_; throw_ = a; }
}

struct ConcreteVariableRef {
	@safe @nogc pure nothrow:
	@trusted immutable this(immutable Constant* a) {
		inner = immutable TaggedPtr!Kind(Kind.constant, a);
	}
	@trusted immutable this(immutable ConcreteLocal* a) {
		inner = immutable TaggedPtr!Kind(Kind.local, a);
	}
	@trusted immutable this(immutable ConcreteParam* a) {
		inner = immutable TaggedPtr!Kind(Kind.param, a);
	}
	@trusted immutable this(immutable ConcreteClosureRef a) {
		inner = immutable TaggedPtr!Kind(Kind.closure, a.paramAndIndex);
	}

	private:
	enum Kind { constant, local, param, closure }
	immutable TaggedPtr!Kind inner;
}

@trusted immutable(T) matchConcreteVariableRef(T)(
	immutable ConcreteVariableRef a,
	scope immutable(T) delegate(immutable Constant) @safe @nogc pure nothrow cbConstant,
	scope immutable(T) delegate(immutable ConcreteLocal*) @safe @nogc pure nothrow cbLocal,
	scope immutable(T) delegate(immutable ConcreteParam*) @safe @nogc pure nothrow cbParam,
	scope immutable(T) delegate(immutable ConcreteClosureRef) @safe @nogc pure nothrow cbClosure,
) {
	final switch (a.inner.tag()) {
		case ConcreteVariableRef.Kind.constant:
			return cbConstant(*a.inner.asPtr!Constant);
		case ConcreteVariableRef.Kind.local:
			return cbLocal(a.inner.asPtr!ConcreteLocal);
		case ConcreteVariableRef.Kind.param:
			return cbParam(a.inner.asPtr!ConcreteParam);
		case ConcreteVariableRef.Kind.closure:
			return cbClosure(immutable ConcreteClosureRef(a.inner.asPtrAndSmallNumber!ConcreteParam));
	}
}

immutable(ConcreteType) elementType(return scope ref immutable ConcreteExprKind.CreateArr a) =>
	only(asInst(a.arrType.source).typeArgs);

immutable(ConcreteType) returnType(return scope ref immutable ConcreteExprKind.Call a) =>
	a.called.returnType;

immutable(bool) isConstant(ref immutable ConcreteExprKind a) =>
	a.kind == ConcreteExprKind.Kind.constant;

@trusted ref immutable(Constant) asConstant(scope return ref immutable ConcreteExprKind a) {
	verify(isConstant(a));
	return a.constant;
}

@trusted immutable(T) matchConcreteExprKind(T)(
	ref immutable ConcreteExprKind a,
	scope immutable(T) delegate(ref immutable ConcreteExprKind.Alloc) @safe @nogc pure nothrow cbAlloc,
	scope immutable(T) delegate(ref immutable ConcreteExprKind.Call) @safe @nogc pure nothrow cbCall,
	scope immutable(T) delegate(ref immutable ConcreteExprKind.ClosureCreate) @safe @nogc pure nothrow cbClosureCreate,
	scope immutable(T) delegate(ref immutable ConcreteExprKind.ClosureGet) @safe @nogc pure nothrow cbClosureGet,
	scope immutable(T) delegate(ref immutable ConcreteExprKind.ClosureSet) @safe @nogc pure nothrow cbClosureSet,
	scope immutable(T) delegate(ref immutable ConcreteExprKind.Cond) @safe @nogc pure nothrow cbCond,
	scope immutable(T) delegate(immutable Constant) @safe @nogc pure nothrow cbConstant,
	scope immutable(T) delegate(ref immutable ConcreteExprKind.CreateArr) @safe @nogc pure nothrow cbCreateArr,
	scope immutable(T) delegate(ref immutable ConcreteExprKind.CreateRecord) @safe @nogc pure nothrow cbCreateRecord,
	scope immutable(T) delegate(ref immutable ConcreteExprKind.CreateUnion) @safe @nogc pure nothrow cbCreateUnion,
	scope immutable(T) delegate(ref immutable ConcreteExprKind.Drop) @safe @nogc pure nothrow cbDrop,
	scope immutable(T) delegate(ref immutable ConcreteExprKind.Lambda) @safe @nogc pure nothrow cbLambda,
	scope immutable(T) delegate(ref immutable ConcreteExprKind.Let) @safe @nogc pure nothrow cbLet,
	scope immutable(T) delegate(ref immutable ConcreteExprKind.LocalGet) @safe @nogc pure nothrow cbLocalGet,
	scope immutable(T) delegate(ref immutable ConcreteExprKind.LocalSet) @safe @nogc pure nothrow cbLocalSet,
	scope immutable(T) delegate(ref immutable ConcreteExprKind.Loop) @safe @nogc pure nothrow cbLoop,
	scope immutable(T) delegate(ref immutable ConcreteExprKind.LoopBreak) @safe @nogc pure nothrow cbLoopBreak,
	scope immutable(T) delegate(ref immutable ConcreteExprKind.LoopContinue) @safe @nogc pure nothrow cbLoopContinue,
	scope immutable(T) delegate(ref immutable ConcreteExprKind.MatchEnum) @safe @nogc pure nothrow cbMatchEnum,
	scope immutable(T) delegate(ref immutable ConcreteExprKind.MatchUnion) @safe @nogc pure nothrow cbMatchUnion,
	scope immutable(T) delegate(ref immutable ConcreteExprKind.ParamGet) @safe @nogc pure nothrow cbParamGet,
	scope immutable(T) delegate(ref immutable ConcreteExprKind.PtrToField) @safe @nogc pure nothrow cbPtrToField,
	scope immutable(T) delegate(ref immutable ConcreteExprKind.PtrToLocal) @safe @nogc pure nothrow cbPtrToLocal,
	scope immutable(T) delegate(ref immutable ConcreteExprKind.PtrToParam) @safe @nogc pure nothrow cbPtrToParam,
	scope immutable(T) delegate(ref immutable ConcreteExprKind.Seq) @safe @nogc pure nothrow cbSeq,
	scope immutable(T) delegate(ref immutable ConcreteExprKind.Throw) @safe @nogc pure nothrow cbThrow,
) {
	final switch (a.kind) {
		case ConcreteExprKind.Kind.alloc:
			return cbAlloc(*a.alloc);
		case ConcreteExprKind.Kind.call:
			return cbCall(a.call);
		case ConcreteExprKind.Kind.closureCreate:
			return cbClosureCreate(a.closureCreate);
		case ConcreteExprKind.Kind.closureGet:
			return cbClosureGet(*a.closureGet);
		case ConcreteExprKind.Kind.closureSet:
			return cbClosureSet(*a.closureSet);
		case ConcreteExprKind.Kind.cond:
			return cbCond(*a.cond);
		case ConcreteExprKind.Kind.constant:
			return cbConstant(a.constant);
		case ConcreteExprKind.Kind.createArr:
			return cbCreateArr(*a.createArr);
		case ConcreteExprKind.Kind.createRecord:
			return cbCreateRecord(a.createRecord);
		case ConcreteExprKind.Kind.createUnion:
			return cbCreateUnion(*a.createUnion);
		case ConcreteExprKind.Kind.drop:
			return cbDrop(*a.drop);
		case ConcreteExprKind.Kind.lambda:
			return cbLambda(a.lambda);
		case ConcreteExprKind.Kind.let:
			return cbLet(*a.let);
		case ConcreteExprKind.Kind.localGet:
			return cbLocalGet(a.localGet);
		case ConcreteExprKind.Kind.localSet:
			return cbLocalSet(*a.localSet);
		case ConcreteExprKind.Kind.loop:
			return cbLoop(*a.loop);
		case ConcreteExprKind.Kind.loopBreak:
			return cbLoopBreak(*a.loopBreak);
		case ConcreteExprKind.Kind.loopContinue:
			return cbLoopContinue(a.loopContinue);
		case ConcreteExprKind.Kind.matchEnum:
			return cbMatchEnum(*a.matchEnum);
		case ConcreteExprKind.Kind.matchUnion:
			return cbMatchUnion(*a.matchUnion);
		case ConcreteExprKind.Kind.paramGet:
			return cbParamGet(a.paramGet);
		case ConcreteExprKind.Kind.ptrToField:
			return cbPtrToField(*a.ptrToField);
		case ConcreteExprKind.Kind.ptrToLocal:
			return cbPtrToLocal(a.ptrToLocal);
		case ConcreteExprKind.Kind.ptrToParam:
			return cbPtrToParam(a.ptrToParam);
		case ConcreteExprKind.Kind.seq:
			return cbSeq(*a.seq);
		case ConcreteExprKind.Kind.throw_:
			return cbThrow(*a.throw_);
	}
}

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
	immutable ConcreteFun* markFun;
	immutable ConcreteFun* rtMain;
	immutable ConcreteFun* userMain;
	immutable ConcreteFun* allocFun;
	immutable ConcreteFun* throwImpl;
}

struct ConcreteLambdaImpl {
	immutable ConcreteType closureType;
	immutable ConcreteFun* impl;
}
