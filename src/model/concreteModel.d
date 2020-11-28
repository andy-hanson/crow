module model.concreteModel;

@safe @nogc pure nothrow:

import model.constant : Constant;
import model.model :
	ClosureField,
	decl,
	FunInst,
	isArr,
	isCompareFun,
	Local,
	Param,
	Purity,
	range,
	RecordField,
	StructInst,
	summon;
import util.bools : Bool, False, True;
import util.collection.arr : Arr;
import util.collection.str : Str;
import util.comparison : compareBool, Comparison;
import util.late : Late, lateGet, lateSet;
import util.opt : force, has, none, Opt;
import util.ptr : comparePtr, Ptr;
import util.sourceRange : FileAndRange;
import util.sym : shortSymAlphaLiteral, Sym;
import util.types : u8;
import util.util : verify;

enum BuiltinStructKind {
	bool_,
	char_,
	float64,
	funPtrN, // fun-ptr0, fun-ptr1, etc...
	int8,
	int16,
	int32,
	int64,
	nat8,
	nat16,
	nat32,
	nat64,
	ptr,
	void_,
}

immutable(Sym) symOfBuiltinStructKind(immutable BuiltinStructKind a) {
	final switch (a) {
		case BuiltinStructKind.bool_:
			return shortSymAlphaLiteral("bool");
		case BuiltinStructKind.char_:
			return shortSymAlphaLiteral("char");
		case BuiltinStructKind.float64:
			return shortSymAlphaLiteral("float-64");
		case BuiltinStructKind.funPtrN:
			return shortSymAlphaLiteral("fun-ptr");
		case BuiltinStructKind.int8:
			return shortSymAlphaLiteral("int-8");
		case BuiltinStructKind.int16:
			return shortSymAlphaLiteral("int-16");
		case BuiltinStructKind.int32:
			return shortSymAlphaLiteral("int-32");
		case BuiltinStructKind.int64:
			return shortSymAlphaLiteral("int-64");
		case BuiltinStructKind.nat8:
			return shortSymAlphaLiteral("nat-8");
		case BuiltinStructKind.nat16:
			return shortSymAlphaLiteral("nat-16");
		case BuiltinStructKind.nat32:
			return shortSymAlphaLiteral("nat-32");
		case BuiltinStructKind.nat64:
			return shortSymAlphaLiteral("nat-64");
		case BuiltinStructKind.ptr:
			return shortSymAlphaLiteral("ptr");
		case BuiltinStructKind.void_:
			return shortSymAlphaLiteral("void");
	}
}

struct ConcreteStructBody {
	@safe @nogc pure nothrow:

	struct Builtin {
		immutable BuiltinStructKind kind;
		immutable Arr!ConcreteType typeArgs;
	}
	struct ExternPtr {}
	struct Record {
		immutable Arr!ConcreteField fields;
	}
	struct Union {
		immutable Arr!ConcreteType members;
	}

	private:
	enum Kind {
		builtin,
		externPtr,
		record,
		union_,
	}
	immutable Kind kind;
	union {
		immutable Builtin builtin;
		immutable ExternPtr externPtr;
		immutable Record record;
		immutable Union union_;
	}

	public:
	@trusted immutable this(immutable Builtin a) { kind = Kind.builtin; builtin = a; }
	immutable this(immutable ExternPtr a) { kind = Kind.externPtr; externPtr = a; }
	@trusted immutable this(immutable Record a) { kind = Kind.record; record = a; }
	@trusted immutable this(immutable Union a) { kind = Kind.union_; union_ = a; }
}

@trusted ref immutable(ConcreteStructBody.Builtin) asBuiltin(return scope ref immutable ConcreteStructBody a) {
	verify(a.kind == ConcreteStructBody.Kind.builtin);
	return a.builtin;
}

@trusted ref immutable(ConcreteStructBody.Record) asRecord(return scope ref immutable ConcreteStructBody a) {
	verify(a.kind == ConcreteStructBody.Kind.record);
	return a.record;
}

@trusted ref immutable(ConcreteStructBody.Union) asUnion(return scope ref immutable ConcreteStructBody a) {
	verify(a.kind == ConcreteStructBody.Kind.union_);
	return a.union_;
}

@trusted T matchConcreteStructBody(T)(
	ref immutable ConcreteStructBody a,
	scope T delegate(ref immutable ConcreteStructBody.Builtin) @safe @nogc pure nothrow cbBuiltin,
	scope T delegate(ref immutable ConcreteStructBody.ExternPtr) @safe @nogc pure nothrow cbExternPtr,
	scope T delegate(ref immutable ConcreteStructBody.Record) @safe @nogc pure nothrow cbRecord,
	scope T delegate(ref immutable ConcreteStructBody.Union) @safe @nogc pure nothrow cbUnion,
) {
	final switch (a.kind) {
		case ConcreteStructBody.Kind.builtin:
			return cbBuiltin(a.builtin);
		case ConcreteStructBody.Kind.externPtr:
			return cbExternPtr(a.externPtr);
		case ConcreteStructBody.Kind.record:
			return cbRecord(a.record);
		case ConcreteStructBody.Kind.union_:
			return cbUnion(a.union_);
	}
}

struct ConcreteType {
	// NOTE: ConcreteType for 'ptr' (e.g. 'ptr byte') will *not* have isPointer set -- since it's not a ptr*
	immutable Bool isPointer;
	immutable Ptr!ConcreteStruct struct_;
}

immutable(Purity) purity(immutable ConcreteType a) {
	return a.struct_.purity;
}

ref immutable(Ptr!ConcreteStruct) mustBeNonPointer(return scope ref immutable ConcreteType a) {
	verify(!a.isPointer);
	return a.struct_;
}

struct ConcreteStructInfo {
	immutable ConcreteStructBody body_;
	immutable size_t sizeBytes; // TODO: never used?
	immutable Bool isSelfMutable; //TODO: never used? (may need for GC though)
	immutable Bool defaultIsPointer;
}

struct ConcreteStructSource {
	@safe @nogc pure nothrow:

	struct Inst {
		immutable Ptr!StructInst inst;
		immutable Arr!ConcreteType typeArgs;
	}

	struct Lambda {
		immutable Ptr!ConcreteFun containingFun;
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

@trusted T matchConcreteStructSource(T)(
	ref immutable ConcreteStructSource a,
	scope T delegate(ref immutable ConcreteStructSource.Inst) @safe @nogc pure nothrow cbInst,
	scope T delegate(ref immutable ConcreteStructSource.Lambda) @safe @nogc pure nothrow cbLambda,
) {
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
}

immutable(Bool) isArr(ref immutable ConcreteStruct a) {
	return matchConcreteStructSource(
		a.source,
		(ref immutable ConcreteStructSource.Inst it) =>
			isArr(it.inst),
		(ref immutable ConcreteStructSource.Lambda it) =>
			False);
}

private ref immutable(ConcreteStructInfo) info(return scope ref const ConcreteStruct a) {
	return lateGet(a.info_);
}

ref immutable(ConcreteStructBody) body_(return scope ref immutable ConcreteStruct a) {
	return info(a).body_;
}

private immutable(size_t) sizeBytes(ref immutable ConcreteStruct a) {
	return info(a).sizeBytes;
}

immutable(Bool) isSelfMutable(ref immutable ConcreteStruct a) {
	return info(a).isSelfMutable;
}

immutable(Bool) defaultIsPointer(ref immutable ConcreteStruct a) {
	return info(a).defaultIsPointer;
}

immutable(size_t) sizeOrPointerSizeBytes(ref immutable ConcreteType t) {
	return t.isPointer ? (void*).sizeof : sizeBytes(t.struct_);
}

immutable(ConcreteType) concreteType_pointer(immutable Ptr!ConcreteStruct struct_) {
	return immutable ConcreteType(True, struct_);
}

immutable(ConcreteType) byRef(immutable ConcreteType t) {
	return concreteType_pointer(t.struct_);
}

immutable(ConcreteType) byVal(ref immutable ConcreteType t) {
	return immutable ConcreteType(False, t.struct_);
}

immutable(ConcreteType) concreteType_fromStruct(immutable Ptr!ConcreteStruct s) {
	return immutable ConcreteType(defaultIsPointer(s), s);
}

immutable(Comparison) compareConcreteType(ref immutable ConcreteType a, ref immutable ConcreteType b) {
	immutable Comparison res = comparePtr(a.struct_, b.struct_);
	return res != Comparison.equal ? res : compareBool(a.isPointer, b.isPointer);
}

struct ConcreteFieldSource {
	@safe @nogc pure nothrow:

	@trusted immutable this(immutable Ptr!ClosureField a) { kind_ = Kind.closureField; closureField_ = a; }
	@trusted immutable this(immutable Ptr!RecordField a) { kind_ = Kind.recordField; recordField_ = a; }

	private:
	enum Kind {
		closureField,
		recordField,
	}
	immutable Kind kind_;
	union {
		immutable Ptr!ClosureField closureField_;
		immutable Ptr!RecordField recordField_;
	}
}

@trusted T matchConcreteFieldSource(T)(
	ref immutable ConcreteFieldSource a,
	scope T delegate(immutable Ptr!ClosureField) @safe @nogc pure nothrow cbClosureField,
	scope T delegate(immutable Ptr!RecordField) @safe @nogc pure nothrow cbRecordField,
) {
	final switch (a.kind_) {
		case ConcreteFieldSource.Kind.closureField:
			return cbClosureField(a.closureField_);
		case ConcreteFieldSource.Kind.recordField:
			return cbRecordField(a.recordField_);
	}
}

struct ConcreteField {
	immutable ConcreteFieldSource source;
	immutable u8 index;
	immutable Bool isMutable;
	immutable ConcreteType type;
}

immutable(Sym) name(ref immutable ConcreteField a) {
	return matchConcreteFieldSource(
		a.source,
		(immutable Ptr!ClosureField it) =>
			it.name,
		(immutable Ptr!RecordField it) =>
			it.name);
}

struct ConcreteParamSource {
	@safe @nogc pure nothrow:

	struct Closure {}

	immutable this(immutable Closure a) { kind_ = Kind.closure; closure_ = a; }
	@trusted immutable this(immutable Ptr!Param a) { kind_ = Kind.param; param_ = a; }

	private:
	enum Kind {
		closure,
		param,
	}
	immutable Kind kind_;
	union {
		immutable Closure closure_;
		immutable Ptr!Param param_;
	}
}

immutable(Bool) isClosure(ref immutable ConcreteParamSource a) {
	return immutable Bool(a.kind_ == ConcreteParamSource.Kind.closure);
}

@trusted T matchConcreteParamSource(T)(
	ref immutable ConcreteParamSource a,
	scope T delegate(ref immutable ConcreteParamSource.Closure) @safe @nogc pure nothrow cbClosure,
	scope T delegate(immutable Ptr!Param) @safe @nogc pure nothrow cbParam,
) {
	final switch (a.kind_) {
		case ConcreteParamSource.Kind.closure:
			return cbClosure(a.closure_);
		case ConcreteParamSource.Kind.param:
			return cbParam(a.param_);
	}
}

struct ConcreteParam {
	immutable ConcreteParamSource source;
	immutable Opt!size_t index; // not present for ctx/ closure param
	immutable ConcreteType type;
}

struct ConcreteLocalSource {
	@safe @nogc pure nothrow:

	struct Arr {}
	struct Matched {}

	immutable this(immutable Arr a) { kind_ = Kind.arr; arr_ = a; }
	@trusted immutable this(immutable Ptr!Local a) { kind_ = Kind.local; local_ = a; }
	immutable this(immutable Matched a) { kind_ = Kind.matched; matched_ = a; }

	private:
	enum Kind {
		arr,
		local,
		matched,
	}
	immutable Kind kind_;
	union {
		immutable Arr arr_;
		immutable Ptr!Local local_;
		immutable Matched matched_;
	}
}

@trusted T matchConcreteLocalSource(T)(
	ref immutable ConcreteLocalSource a,
	scope T delegate(ref immutable ConcreteLocalSource.Arr) @safe @nogc pure nothrow cbArr,
	scope T delegate(immutable Ptr!Local) @safe @nogc pure nothrow cbLocal,
	scope T delegate(ref immutable ConcreteLocalSource.Matched) @safe @nogc pure nothrow cbMatched,
) {
	final switch (a.kind_) {
		case ConcreteLocalSource.Kind.arr:
			return cbArr(a.arr_);
		case ConcreteLocalSource.Kind.local:
			return cbLocal(a.local_);
		case ConcreteLocalSource.Kind.matched:
			return cbMatched(a.matched_);
	}
}

struct ConcreteLocal {
	immutable ConcreteLocalSource source;
	// Needed to distinguish two locals with the same name when compiling to C
	immutable size_t index;
	immutable ConcreteType type;
}

struct ConcreteFunExprBody {
	immutable ConcreteExpr expr;
}

struct ConcreteFunBody {
	@safe @nogc pure nothrow:

	struct Builtin {
		immutable Arr!ConcreteType typeArgs;
	}
	struct CreateRecord {
	}
	struct Extern {
		immutable Bool isGlobal;
		immutable Str externName;
	}
	struct RecordFieldGet {
		immutable u8 fieldIndex;
	}
	struct RecordFieldSet {
		immutable u8 fieldIndex;
	}

	private:
	enum Kind {
		builtin,
		createRecord,
		extern_,
		concreteFunExprBody,
		recordFieldGet,
		recordFieldSet,
	}
	immutable Kind kind;
	union {
		immutable Builtin builtin;
		immutable CreateRecord createRecord;
		immutable Extern extern_;
		immutable ConcreteFunExprBody concreteFunExprBody;
		immutable RecordFieldGet recordFieldGet;
		immutable RecordFieldSet recordFieldSet;
	}

	public:
	@trusted immutable this(immutable Builtin a) { kind = Kind.builtin; builtin = a; }
	@trusted immutable this(immutable CreateRecord a) { kind = Kind.createRecord; createRecord = a; }
	@trusted immutable this(immutable Extern a) { kind = Kind.extern_; extern_ = a; }
	@trusted immutable this(immutable ConcreteFunExprBody a) {
		kind = Kind.concreteFunExprBody; concreteFunExprBody = a;
	}
	immutable this(immutable RecordFieldGet a) { kind = Kind.recordFieldGet; recordFieldGet = a; }
	immutable this(immutable RecordFieldSet a) { kind = Kind.recordFieldSet; recordFieldSet = a; }
}

immutable(Bool) isExtern(ref immutable ConcreteFunBody a) {
	return Bool(a.kind == ConcreteFunBody.Kind.extern_);
}

@trusted ref immutable(ConcreteFunBody.Builtin) asBuiltin(return scope ref immutable ConcreteFunBody a) {
	verify(a.kind == ConcreteFunBody.Kind.builtin);
	return a.builtin;
}

@trusted ref immutable(ConcreteFunBody.Extern) asExtern(return scope ref immutable ConcreteFunBody a) {
	verify(isExtern(a));
	return a.extern_;
}

@trusted T matchConcreteFunBody(T)(
	ref immutable ConcreteFunBody a,
	scope T delegate(ref immutable ConcreteFunBody.Builtin) @safe @nogc pure nothrow cbBuiltin,
	scope T delegate(ref immutable ConcreteFunBody.CreateRecord) @safe @nogc pure nothrow cbCreateRecord,
	scope T delegate(ref immutable ConcreteFunBody.Extern) @safe @nogc pure nothrow cbExtern,
	scope T delegate(ref immutable ConcreteFunExprBody) @safe @nogc pure nothrow cbConcreteFunExprBody,
	scope T delegate(ref immutable ConcreteFunBody.RecordFieldGet) @safe @nogc pure nothrow cbRecordFieldGet,
	scope T delegate(ref immutable ConcreteFunBody.RecordFieldSet) @safe @nogc pure nothrow cbRecordFieldSet,
) {
	final switch (a.kind) {
		case ConcreteFunBody.Kind.builtin:
			return cbBuiltin(a.builtin);
		case ConcreteFunBody.Kind.createRecord:
			return cbCreateRecord(a.createRecord);
		case ConcreteFunBody.Kind.extern_:
			return cbExtern(a.extern_);
		case ConcreteFunBody.Kind.concreteFunExprBody:
			return cbConcreteFunExprBody(a.concreteFunExprBody);
		case ConcreteFunBody.Kind.recordFieldGet:
			return cbRecordFieldGet(a.recordFieldGet);
		case ConcreteFunBody.Kind.recordFieldSet:
			return cbRecordFieldSet(a.recordFieldSet);
	}
}

immutable(Bool) isGlobal(ref immutable ConcreteFunBody a) {
	return Bool(isExtern(a) && asExtern(a).isGlobal);
}

struct ConcreteFunSource {
	@safe @nogc pure nothrow:

	struct Lambda {
		immutable FileAndRange range;
		immutable Ptr!ConcreteFun containingFun;
		immutable size_t index; // nth lambda in the containing function
	}

	@trusted immutable this(immutable Ptr!FunInst a) { kind_ = Kind.funInst; funInst_ = a; }
	@trusted immutable this(immutable Ptr!Lambda a) { kind_ = Kind.lambda; lambda_ = a; }

	private:
	enum Kind {
		funInst,
		lambda,
	}
	immutable Kind kind_;
	union {
		immutable Ptr!FunInst funInst_;
		immutable Ptr!Lambda lambda_;
	}
}
static assert(ConcreteFunSource.sizeof <= 16);

@trusted T matchConcreteFunSource(T)(
	ref immutable ConcreteFunSource a,
	scope T delegate(immutable Ptr!FunInst) @safe @nogc pure nothrow cbFunInst,
	scope T delegate(ref immutable ConcreteFunSource.Lambda) @safe @nogc pure nothrow cbLambda,
) {
	final switch (a.kind_) {
		case ConcreteFunSource.Kind.funInst:
			return cbFunInst(a.funInst_);
		case ConcreteFunSource.Kind.lambda:
			return cbLambda(a.lambda_);
	}
}

// We generate a ConcreteFun for:
// Each instantiation of a FunDecl
// Each lambda inside an instantiation of a FunDecl
struct ConcreteFun {
	@safe @nogc pure nothrow:

	immutable ConcreteFunSource source;
	immutable Ptr!ConcreteFunSig sig;
	Late!(immutable ConcreteFunBody) _body_;

	//TODO: not instance
	immutable(ConcreteType) returnType() return scope immutable {
		return immutable ConcreteType(sig.returnTypeNeedsPtr, sig.returnStruct);
	}

	immutable(Bool) needsCtx() immutable {
		return sig.needsCtx;
	}

	ref immutable(Opt!(Ptr!ConcreteParam)) closureParam() return scope immutable {
		return sig.closureParam;
	}

	ref immutable(Arr!ConcreteParam) paramsExcludingCtxAndClosure() return scope immutable {
		return sig.paramsExcludingCtxAndClosure;
	}
}

struct ConcreteFunSig {
	@safe @nogc pure nothrow:

	immutable this(
		immutable ConcreteType returnType,
		immutable Bool n,
		immutable Opt!(Ptr!ConcreteParam) c,
		immutable Arr!ConcreteParam p,
	) {
		returnStruct = returnType.struct_;
		returnTypeNeedsPtr = returnType.isPointer;
		needsCtx = n;
		closureParam = c;
		paramsExcludingCtxAndClosure = p;
	}

	// Breaking up `immutable ConcreteType returnType;` so bools can be stored together
	immutable Ptr!ConcreteStruct returnStruct;
	immutable Bool returnTypeNeedsPtr;
	immutable Bool needsCtx;
	immutable Opt!(Ptr!ConcreteParam) closureParam;
	immutable Arr!ConcreteParam paramsExcludingCtxAndClosure;
}
static assert(ConcreteFunSig.sizeof <= 48);

immutable(Bool) isSummon(ref immutable ConcreteFun a) {
	return matchConcreteFunSource!(immutable Bool)(
		a.source,
		(immutable Ptr!FunInst it) =>
			summon(decl(it).deref()),
		(ref immutable ConcreteFunSource.Lambda it) =>
			isSummon(it.containingFun));
}

immutable(FileAndRange) concreteFunRange(ref immutable ConcreteFun a) {
	return matchConcreteFunSource!(immutable FileAndRange)(
		a.source,
		(immutable Ptr!FunInst it) =>
			range(decl(it).deref()),
		(ref immutable ConcreteFunSource.Lambda it) =>
			it.range);
}

immutable(Bool) isCompareFun(ref immutable ConcreteFun a) {
	return matchConcreteFunSource!(immutable Bool)(
		a.source,
		(immutable Ptr!FunInst it) =>
			isCompareFun(it),
		(ref immutable ConcreteFunSource.Lambda) =>
			False);
}

ref immutable(ConcreteFunBody) body_(return scope ref const ConcreteFun a) {
	return lateGet(a._body_);
}

void setBody(ref ConcreteFun a, immutable ConcreteFunBody value) {
	lateSet(a._body_, value);
}

immutable(Bool) isExtern(ref immutable ConcreteFun a) {
	return isExtern(body_(a));
}

immutable(Bool) isGlobal(ref immutable ConcreteFun a) {
	return isGlobal(body_(a));
}

struct ConcreteExpr {
	immutable ConcreteType type;
	immutable FileAndRange range;
	immutable ConcreteExprKind kind;
}

struct ConcreteExprKind {
	@safe @nogc pure nothrow:

	struct Alloc {
		immutable Ptr!ConcreteExpr inner;
	}

	struct Call {
		immutable Ptr!ConcreteFun called;
		immutable Arr!ConcreteExpr args;
	}

	struct Cond {
		immutable Ptr!ConcreteExpr cond;
		immutable Ptr!ConcreteExpr then;
		immutable Ptr!ConcreteExpr else_;
	}

	struct CreateArr {
		immutable Ptr!ConcreteStruct arrType;
		immutable ConcreteType elementType;
		immutable Arr!ConcreteExpr args;
	}

	// TODO: this is only used for closures now, since normal record creation always goes through a function.
	struct CreateRecord {
		immutable Arr!ConcreteExpr args;
	}

	struct ConvertToUnion {
		immutable u8 memberIndex;
		immutable Ptr!ConcreteExpr arg;
	}

	struct Let {
		immutable Ptr!ConcreteLocal local;
		immutable Ptr!ConcreteExpr value; // If a constant, we just use 'then' in place of the Let
		immutable Ptr!ConcreteExpr then;
	}

	// NOTE: A fun-ref is a lambda wrapped in CreateRecord.
	struct Lambda {
		@safe @nogc pure nothrow:

		immutable Ptr!ConcreteFun fun; // function implementing the lambda body
		// none for fun-ptrs only.
		// If not a fun-ptr but no closure is needed, this calls `null`.
		// Else this is a ConcreteExpr.Alloc of the closure type.
		immutable Opt!(Ptr!ConcreteExpr) closure;

		immutable this(immutable Ptr!ConcreteFun f, immutable Opt!(Ptr!ConcreteExpr) c) {
			fun = f;
			closure = c;
			if (has(closure))
				verify(force(closure).type.isPointer);
		}
	}

	struct LocalRef {
		immutable Ptr!ConcreteLocal local;
	}

	struct Match {
		@safe @nogc pure nothrow:

		struct Case {
			immutable Opt!(Ptr!ConcreteLocal) local;
			immutable ConcreteExpr then;
		}

		immutable Ptr!ConcreteExpr matchedValue;
		immutable Arr!Case cases;
	}

	struct ParamRef {
		immutable Ptr!ConcreteParam param;
	}

	// TODO: this is only used for closure field accesses now. At least rename.
	struct RecordFieldGet {
		immutable Ptr!ConcreteExpr target;
		immutable Ptr!ConcreteField field;
	}

	struct Seq {
		immutable Ptr!ConcreteExpr first;
		immutable Ptr!ConcreteExpr then;
	}

	private:
	enum Kind {
		alloc,
		call,
		cond,
		constant,
		createArr,
		createRecord,
		convertToUnion,
		lambda,
		let,
		localRef,
		match,
		paramRef,
		recordFieldGet,
		seq,
	}
	immutable Kind kind;
	union {
		immutable Alloc alloc;
		immutable Call call;
		immutable Cond cond;
		immutable Ptr!CreateArr createArr;
		immutable Constant constant;
		immutable CreateRecord createRecord;
		immutable ConvertToUnion convertToUnion;
		immutable Lambda lambda;
		immutable Let let;
		immutable LocalRef localRef;
		immutable Ptr!Match match;
		immutable ParamRef paramRef;
		immutable RecordFieldGet recordFieldGet;
		immutable Seq seq;
	}

	public:
	@trusted immutable this(immutable Alloc a) { kind = Kind.alloc; alloc = a; }
	@trusted immutable this(immutable Call a) {
		kind = Kind.call; call = a;
	}
	@trusted immutable this(immutable Cond a) {
		kind = Kind.cond; cond = a;
	}
	@trusted immutable this(immutable Ptr!CreateArr a) {
		kind = Kind.createArr; createArr = a;
	}
	@trusted immutable this(immutable Constant a) {
		kind = Kind.constant; constant = a;
	}
	@trusted immutable this(immutable CreateRecord a) {
		kind = Kind.createRecord; createRecord = a;
	}
	@trusted immutable this(immutable ConvertToUnion a) {
		kind = Kind.convertToUnion; convertToUnion = a;
	}
	@trusted immutable this(immutable Lambda a) {
		kind = Kind.lambda; lambda = a;
	}
	@trusted immutable this(immutable Let a) {
		kind = Kind.let; let = a;
	}
	@trusted immutable this(immutable LocalRef a) {
		kind = Kind.localRef; localRef = a;
	}
	@trusted immutable this(immutable Ptr!Match a) {
		kind = Kind.match; match = a;
	}
	@trusted immutable this(immutable ParamRef a) {
		kind = Kind.paramRef; paramRef = a;
	}
	@trusted immutable this(immutable RecordFieldGet a) {
		kind = Kind.recordFieldGet; recordFieldGet = a;
	}
	@trusted immutable this(immutable Seq a) {
		kind = Kind.seq; seq = a;
	}
}

immutable(ConcreteType) returnType(return scope ref immutable ConcreteExprKind.Call a) {
	return a.called.returnType;
}

immutable(Bool) isConstant(ref immutable ConcreteExprKind a) {
	return immutable Bool(a.kind == ConcreteExprKind.Kind.constant);
}

@trusted ref immutable(Constant) asConstant(return scope ref immutable ConcreteExprKind a) {
	verify(isConstant(a));
	return a.constant;
}

@trusted T matchConcreteExprKind(T)(
	ref immutable ConcreteExprKind a,
	scope T delegate(ref immutable ConcreteExprKind.Alloc) @safe @nogc pure nothrow cbAlloc,
	scope T delegate(ref immutable ConcreteExprKind.Call) @safe @nogc pure nothrow cbCall,
	scope T delegate(ref immutable ConcreteExprKind.Cond) @safe @nogc pure nothrow cbCond,
	scope T delegate(ref immutable Constant) @safe @nogc pure nothrow cbConstant,
	scope T delegate(ref immutable ConcreteExprKind.CreateArr) @safe @nogc pure nothrow cbCreateArr,
	scope T delegate(ref immutable ConcreteExprKind.CreateRecord) @safe @nogc pure nothrow cbCreateRecord,
	scope T delegate(ref immutable ConcreteExprKind.ConvertToUnion) @safe @nogc pure nothrow cbConvertToUnion,
	scope T delegate(ref immutable ConcreteExprKind.Lambda) @safe @nogc pure nothrow cbLambda,
	scope T delegate(ref immutable ConcreteExprKind.Let) @safe @nogc pure nothrow cbLet,
	scope T delegate(ref immutable ConcreteExprKind.LocalRef) @safe @nogc pure nothrow cbLocalRef,
	scope T delegate(ref immutable ConcreteExprKind.Match) @safe @nogc pure nothrow cbMatch,
	scope T delegate(ref immutable ConcreteExprKind.ParamRef) @safe @nogc pure nothrow cbParamRef,
	scope T delegate(ref immutable ConcreteExprKind.RecordFieldGet) @safe @nogc pure nothrow cbRecordFieldGet,
	scope T delegate(ref immutable ConcreteExprKind.Seq) @safe @nogc pure nothrow cbSeq,
) {
	final switch (a.kind) {
		case ConcreteExprKind.Kind.alloc:
			return cbAlloc(a.alloc);
		case ConcreteExprKind.Kind.call:
			return cbCall(a.call);
		case ConcreteExprKind.Kind.cond:
			return cbCond(a.cond);
		case ConcreteExprKind.Kind.constant:
			return cbConstant(a.constant);
		case ConcreteExprKind.Kind.createArr:
			return cbCreateArr(a.createArr);
		case ConcreteExprKind.Kind.createRecord:
			return cbCreateRecord(a.createRecord);
		case ConcreteExprKind.Kind.convertToUnion:
			return cbConvertToUnion(a.convertToUnion);
		case ConcreteExprKind.Kind.lambda:
			return cbLambda(a.lambda);
		case ConcreteExprKind.Kind.let:
			return cbLet(a.let);
		case ConcreteExprKind.Kind.localRef:
			return cbLocalRef(a.localRef);
		case ConcreteExprKind.Kind.match:
			return cbMatch(a.match);
		case ConcreteExprKind.Kind.paramRef:
			return cbParamRef(a.paramRef);
		case ConcreteExprKind.Kind.recordFieldGet:
			return cbRecordFieldGet(a.recordFieldGet);
		case ConcreteExprKind.Kind.seq:
			return cbSeq(a.seq);
	}
}

struct ArrTypeAndConstantsConcrete {
	immutable Ptr!ConcreteStruct arrType;
	immutable ConcreteType elementType;
	immutable Arr!(Arr!Constant) constants;
}

struct PointerTypeAndConstantsConcrete {
	immutable Ptr!ConcreteStruct pointeeType;
	immutable Arr!(Ptr!Constant) constants;
}

// TODO: rename -- this is not all constants, just the ones by-ref
struct AllConstantsConcrete {
	immutable Arr!ArrTypeAndConstantsConcrete arrs;
	// These are just the by-ref records
	immutable Arr!PointerTypeAndConstantsConcrete pointers;
}

struct ConcreteProgram {
	immutable AllConstantsConcrete allConstants;
	immutable Arr!(Ptr!ConcreteStruct) allStructs;
	immutable Arr!(Ptr!ConcreteFun) allFuns;
	immutable Ptr!ConcreteFun rtMain;
	immutable Ptr!ConcreteFun userMain;
	immutable Ptr!ConcreteFun allocFun;
	immutable Ptr!ConcreteStruct ctxType;
}
