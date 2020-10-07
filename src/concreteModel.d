module concreteModel;

@safe @nogc pure nothrow:

import util.bools : Bool, False, True;
import util.collection.arr : Arr, empty, size, sizeEq;
import util.collection.str : Str;
import util.comparison : compareBool, Comparison;
import util.late : Late, lateGet, lateSet;
import util.opt : force, has, none, Opt, some;
import util.ptr : comparePtr, Ptr, ptrEquals;
import util.sourceRange : SourceRange;
import util.sym : shortSymAlphaLiteral, Sym;
import util.types : u8;
import util.util : todo, unreachable, verify;

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

immutable(Bool) concreteTypeEqual(ref immutable ConcreteType a, ref immutable ConcreteType b) {
	return Bool(
		a.isPointer == b.isPointer &&
		ptrEquals(a.struct_, b.struct_));
}

immutable(Ptr!ConcreteStruct) mustBePointer(immutable ConcreteType a) {
	verify(a.isPointer);
	return a.struct_;
}

// Union should never be a pointer
immutable(Ptr!ConcreteStruct) mustBeNonPointer(immutable ConcreteType a) {
	verify(!a.isPointer);
	return a.struct_;
}

struct ConcreteStructInfo {
	immutable ConcreteStructBody body_;
	immutable size_t sizeBytes; // TODO: never used?
	immutable Bool isSelfMutable; //TODO: never used? (may need for GC though)
	immutable Bool defaultIsPointer;
}

struct ConcreteStruct {
	@safe @nogc pure nothrow:

	immutable Sym name;
	immutable Str mangledName; // TODO:KILL
	Late!(immutable ConcreteStructInfo) info_;
}

ref immutable(ConcreteStructInfo) info(return scope ref const ConcreteStruct a) {
	return lateGet(a.info_);
}

ref immutable(ConcreteStructBody) body_(return scope ref immutable ConcreteStruct a) {
	return info(a).body_;
}

immutable(size_t) sizeBytes(ref immutable ConcreteStruct a) {
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

immutable(ConcreteType) concreteType_byValue(immutable Ptr!ConcreteStruct struct_) {
	return immutable ConcreteType(False, struct_);
}

immutable(ConcreteType) byRef(immutable ConcreteType t) {
	return concreteType_pointer(t.struct_);
}

immutable(ConcreteType) byVal(ref immutable ConcreteType t) {
	return concreteType_byValue(t.struct_);
}

immutable(ConcreteType) changeToByRef(ref immutable ConcreteType t) {
	verify(!t.isPointer);
	return byRef(t);
}

immutable(ConcreteType) concreteType_fromStruct(immutable Ptr!ConcreteStruct s) {
	return immutable ConcreteType(defaultIsPointer(s), s);
}

void writeConcreteType(Alloc)(ref Writer!Alloc writer, ref immutable ConcreteType t) {
	writeStr(writer, t.struct_.mangledName);
	if (t.isPointer)
		writeChar(writer, '*');
}

immutable(Comparison) compareConcreteType(ref immutable ConcreteType a, ref immutable ConcreteType b) {
	immutable Comparison res = comparePtr(a.struct_, b.struct_);
	return res != Comparison.equal ? res : compareBool(a.isPointer, b.isPointer);
}

immutable(Bool) concreteTypeEq(ref immutable ConcreteType a, ref immutable ConcreteType b) {
	return Bool(compareConcreteType(a, b) == Comparison.equal);
}

struct ConcreteField {
	immutable size_t index;
	immutable Bool isMutable;
	immutable Str mangledName;
	immutable ConcreteType type;
}

struct ConcreteParam {
	immutable Opt!size_t index; // not present for ctx/ closure param
	immutable Str mangledName;
	immutable ConcreteType type;
}

immutable(ConcreteParam) withType(ref immutable ConcreteParam a, ref immutable ConcreteType newType) {
	return immutable ConcreteParam(a.index, a.mangledName, newType);
}

struct ConcreteLocal {
	immutable size_t index;
	immutable Str mangledName;
	immutable ConcreteType type;
}

struct ConcreteFunExprBody {
	immutable Arr!(Ptr!ConcreteLocal) allLocals;
	immutable ConcreteExpr expr;
}

struct ConcreteFunBody {
	@safe @nogc pure nothrow:

	struct Builtin {
		immutable Arr!ConcreteType typeArgs;
	}
	struct Extern {
		immutable Bool isGlobal;
	}

	private:
	enum Kind {
		builtin,
		extern_,
		concreteFunExprBody,
	}
	immutable Kind kind;
	union {
		immutable Builtin builtin;
		immutable Extern extern_;
		immutable ConcreteFunExprBody concreteFunExprBody;
	}

	public:
	@trusted immutable this(immutable Builtin a) { kind = Kind.builtin; builtin = a; }
	immutable this(immutable Extern a) { kind = Kind.extern_; extern_ = a; }
	@trusted immutable this(immutable ConcreteFunExprBody a) {
		kind = Kind.concreteFunExprBody; concreteFunExprBody = a;
	}
}

immutable(Bool) isBuiltin(ref immutable ConcreteFunBody a) {
	return Bool(a.kind == ConcreteFunBody.Kind.builtin);
}

immutable(Bool) isExtern(ref immutable ConcreteFunBody a) {
	return Bool(a.kind == ConcreteFunBody.Kind.extern_);
}

immutable(Bool) isConcreteFunExprBody(ref immutable ConcreteFunBody a) {
	return Bool(a.kind == ConcreteFunBody.Kind.concreteFunExprBody);
}

@trusted ref immutable(ConcreteFunBody.Builtin) asBuiltin(return scope ref immutable ConcreteFunBody a) {
	verify(isBuiltin(a));
	return a.builtin;
}

@trusted ref immutable(ConcreteFunBody.Extern) asExtern(return scope ref immutable ConcreteFunBody a) {
	verify(isExtern(a));
	return a.extern_;
}

@trusted ref immutable(ConcreteFunExprBody) asConcreteFunExprBody(return scope ref immutable ConcreteFunBody a) {
	verify(isConcreteFunExprBody(a));
	return a.concreteFunExprBody;
}

@trusted T matchConcreteFunBody(T)(
	ref immutable ConcreteFunBody a,
	scope T delegate(ref immutable ConcreteFunBody.Builtin) @safe @nogc pure nothrow cbBuiltin,
	scope T delegate(ref immutable ConcreteFunBody.Extern) @safe @nogc pure nothrow cbExtern,
	scope T delegate(ref immutable ConcreteFunExprBody) @safe @nogc pure nothrow cbConcreteFunExprBody,
) {
	final switch (a.kind) {
		case ConcreteFunBody.Kind.builtin:
			return cbBuiltin(a.builtin);
		case ConcreteFunBody.Kind.extern_:
			return cbExtern(a.extern_);
		case ConcreteFunBody.Kind.concreteFunExprBody:
			return cbConcreteFunExprBody(a.concreteFunExprBody);
	}
}

immutable(Bool) isGlobal(ref immutable ConcreteFunBody a) {
	return Bool(isExtern(a) && asExtern(a).isGlobal);
}

// We generate a ConcreteFun for:
// Each instantiation of a FunDecl
// Each lambda inside an instantiation of a FunDecl
struct ConcreteFun {
	immutable Sym name;
	immutable(Str) mangledName; // TODO:KILL
	immutable(ConcreteType) returnType;
	immutable Bool needsCtx;
	immutable Opt!ConcreteParam closureParam;
	immutable Arr!ConcreteParam paramsExcludingCtxAndClosure;
	Late!(immutable ConcreteFunBody) _body_;
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
	@safe @nogc pure nothrow:

	struct Alloc {
		immutable Ptr!ConcreteFun alloc; // TODO: just store this once on the ConcreteProgram
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
		immutable Ptr!ConcreteFun alloc;
		// Needed because we must first allocate the array, then write to each field. That requires a local.
		immutable Ptr!ConcreteLocal local; // TODO:KILL
		immutable Arr!ConcreteExpr args;
	}

	// Note: CreateRecord always creates a record by-value. This may be wrapped in Alloc.
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

		immutable Ptr!ConcreteLocal matchedLocal;
		immutable Ptr!ConcreteExpr matchedValue;
		immutable Arr!Case cases;

		immutable this(immutable Ptr!ConcreteLocal ml, immutable Ptr!ConcreteExpr mv, immutable Arr!Case c) {
			matchedLocal = ml;
			matchedValue = mv;
			cases = c;
			verify(sizeEq(matchedUnionMembers(this), cases));
		}
	}

	struct ParamRef {
		immutable Ptr!ConcreteParam param;
	}

	struct RecordFieldAccess {
		immutable Ptr!ConcreteExpr target;
		immutable Ptr!ConcreteField field;
	}

	struct RecordFieldSet {
		@safe @nogc pure nothrow:

		immutable Ptr!ConcreteExpr target;
		immutable Ptr!ConcreteField field;
		immutable Ptr!ConcreteExpr value;

		immutable this(
			immutable Ptr!ConcreteExpr t,
			immutable Ptr!ConcreteField f,
			immutable Ptr!ConcreteExpr v,
		) {
			target = t;
			field = f;
			value = v;
			verify(field.isMutable);
		}
	}

	struct Seq {
		immutable Ptr!ConcreteExpr first;
		immutable Ptr!ConcreteExpr then;
	}

	struct SpecialConstant {
		enum Kind {
			one,
			zero,
		}
		immutable Kind kind;
	}

	struct SpecialUnary {
		enum Kind {
			deref,
		}
		immutable Kind kind;
		immutable Ptr!ConcreteExpr arg;
	}

	struct SpecialBinary {
		enum Kind {
			eqNat64,
			less,
			or,
			wrapAddNat64,
			wrapSubNat64,
		}
		immutable Kind kind;
		immutable Ptr!ConcreteExpr left;
		immutable Ptr!ConcreteExpr right;
	}

	struct StringLiteral {
		immutable Str literal;
	}

	immutable ConcreteType type;
	immutable SourceRange range;
	immutable Kind kind;
	private:
	enum Kind {
		alloc,
		call,
		cond,
		createArr,
		createRecord,
		convertToUnion,
		lambda,
		let,
		localRef,
		match,
		paramRef,
		recordFieldAccess,
		recordFieldSet,
		seq,
		specialConstant,
		specialUnary,
		specialBinary,
		stringLiteral,
	}
	union {
		immutable Alloc alloc;
		immutable Call call;
		immutable Cond cond;
		immutable CreateArr createArr;
		immutable CreateRecord createRecord;
		immutable ConvertToUnion convertToUnion;
		immutable Lambda lambda;
		immutable Let let;
		immutable LocalRef localRef;
		immutable Match match;
		immutable ParamRef paramRef;
		immutable RecordFieldAccess recordFieldAccess;
		immutable RecordFieldSet recordFieldSet;
		immutable Seq seq;
		immutable SpecialConstant specialConstant;
		immutable SpecialUnary specialUnary;
		immutable SpecialBinary specialBinary;
		immutable StringLiteral stringLiteral;
	}

	public:
	@trusted immutable this(immutable ConcreteType t, immutable SourceRange r, immutable Alloc a) {
		type = t; range = r; kind = Kind.alloc; alloc = a;
	}
	@trusted immutable this(immutable ConcreteType t, immutable SourceRange r, immutable Call a) {
		type = t; range = r; kind = Kind.call; call = a;
	}
	@trusted immutable this(immutable ConcreteType t, immutable SourceRange r, immutable Cond a) {
		type = t; range = r; kind = Kind.cond; cond = a;
	}
	@trusted immutable this(immutable ConcreteType t, immutable SourceRange r, immutable CreateArr a) {
		type = t; range = r; kind = Kind.createArr; createArr = a;
	}
	@trusted immutable this(immutable ConcreteType t, immutable SourceRange r, immutable CreateRecord a) {
		type = t; range = r; kind = Kind.createRecord; createRecord = a;
	}
	@trusted immutable this(immutable ConcreteType t, immutable SourceRange r, immutable ConvertToUnion a) {
		type = t; range = r; kind = Kind.convertToUnion; convertToUnion = a;
	}
	@trusted immutable this(immutable ConcreteType t, immutable SourceRange r, immutable Lambda a) {
		type = t; range = r; kind = Kind.lambda; lambda = a;
	}
	@trusted immutable this(immutable ConcreteType t, immutable SourceRange r, immutable Let a) {
		type = t; range = r; kind = Kind.let; let = a;
	}
	@trusted immutable this(immutable ConcreteType t, immutable SourceRange r, immutable LocalRef a) {
		type = t; range = r; kind = Kind.localRef; localRef = a;
	}
	@trusted immutable this(immutable ConcreteType t, immutable SourceRange r, immutable Match a) {
		type = t; range = r; kind = Kind.match; match = a;
	}
	@trusted immutable this(immutable ConcreteType t, immutable SourceRange r, immutable ParamRef a) {
		type = t; range = r; kind = Kind.paramRef; paramRef = a;
	}
	@trusted immutable this(immutable ConcreteType t, immutable SourceRange r, immutable RecordFieldAccess a) {
		type = t; range = r; kind = Kind.recordFieldAccess; recordFieldAccess = a;
	}
	@trusted immutable this(immutable ConcreteType t, immutable SourceRange r, immutable RecordFieldSet a) {
		type = t; range = r; kind = Kind.recordFieldSet; recordFieldSet = a;
	}
	@trusted immutable this(immutable ConcreteType t, immutable SourceRange r, immutable Seq a) {
		type = t; range = r; kind = Kind.seq; seq = a;
	}
	@trusted immutable this(immutable ConcreteType t, immutable SourceRange r, immutable SpecialConstant a) {
		type = t; range = r; kind = Kind.specialConstant; specialConstant = a;
	}
	@trusted immutable this(immutable ConcreteType t, immutable SourceRange r, immutable SpecialUnary a) {
		type = t; range = r; kind = Kind.specialUnary; specialUnary = a;
	}
	@trusted immutable this(immutable ConcreteType t, immutable SourceRange r, immutable SpecialBinary a) {
		type = t; range = r; kind = Kind.specialBinary; specialBinary = a;
	}
	@trusted immutable this(immutable ConcreteType t, immutable SourceRange r, immutable StringLiteral a) {
		type = t; range = r; kind = Kind.stringLiteral; stringLiteral = a;
	}
}

ref immutable(ConcreteType) returnType(return scope ref immutable ConcreteExpr.Call a) {
	return a.called.returnType;
}

immutable(size_t) sizeBytes(ref immutable ConcreteExpr.CreateArr a) {
	return size(a.args) * sizeOrPointerSizeBytes(a.elementType);
}

ref immutable(Arr!ConcreteType) matchedUnionMembers(return scope ref const ConcreteExpr.Match a) {
	return asUnion(body_(mustBeNonPointer(a.matchedLocal.type).deref)).members;
}

immutable(Bool) isCond(ref immutable ConcreteExpr a) {
	return Bool(a.kind == ConcreteExpr.Kind.cond);
}

@trusted T matchConcreteExpr(T)(
	ref immutable ConcreteExpr a,
	scope T delegate(ref immutable ConcreteExpr.Alloc) @safe @nogc pure nothrow cbAlloc,
	scope T delegate(ref immutable ConcreteExpr.Call) @safe @nogc pure nothrow cbCall,
	scope T delegate(ref immutable ConcreteExpr.Cond) @safe @nogc pure nothrow cbCond,
	scope T delegate(ref immutable ConcreteExpr.CreateArr) @safe @nogc pure nothrow cbCreateArr,
	scope T delegate(ref immutable ConcreteExpr.CreateRecord) @safe @nogc pure nothrow cbCreateRecord,
	scope T delegate(ref immutable ConcreteExpr.ConvertToUnion) @safe @nogc pure nothrow cbConvertToUnion,
	scope T delegate(ref immutable ConcreteExpr.Lambda) @safe @nogc pure nothrow cbLambda,
	scope T delegate(ref immutable ConcreteExpr.Let) @safe @nogc pure nothrow cbLet,
	scope T delegate(ref immutable ConcreteExpr.LocalRef) @safe @nogc pure nothrow cbLocalRef,
	scope T delegate(ref immutable ConcreteExpr.Match) @safe @nogc pure nothrow cbMatch,
	scope T delegate(ref immutable ConcreteExpr.ParamRef) @safe @nogc pure nothrow cbParamRef,
	scope T delegate(ref immutable ConcreteExpr.RecordFieldAccess) @safe @nogc pure nothrow cbRecordFieldAccess,
	scope T delegate(ref immutable ConcreteExpr.RecordFieldSet) @safe @nogc pure nothrow cbRecordFieldSet,
	scope T delegate(ref immutable ConcreteExpr.Seq) @safe @nogc pure nothrow cbSeq,
	scope T delegate(ref immutable ConcreteExpr.SpecialConstant) @safe @nogc pure nothrow cbSpecialConstant,
	scope T delegate(ref immutable ConcreteExpr.SpecialUnary) @safe @nogc pure nothrow cbSpecialUnary,
	scope T delegate(ref immutable ConcreteExpr.SpecialBinary) @safe @nogc pure nothrow cbSpecialBinary,
	scope T delegate(ref immutable ConcreteExpr.StringLiteral) @safe @nogc pure nothrow cbStringLiteral,
) {
	final switch (a.kind) {
		case ConcreteExpr.Kind.alloc:
			return cbAlloc(a.alloc);
		case ConcreteExpr.Kind.call:
			return cbCall(a.call);
		case ConcreteExpr.Kind.cond:
			return cbCond(a.cond);
		case ConcreteExpr.Kind.createArr:
			return cbCreateArr(a.createArr);
		case ConcreteExpr.Kind.createRecord:
			return cbCreateRecord(a.createRecord);
		case ConcreteExpr.Kind.convertToUnion:
			return cbConvertToUnion(a.convertToUnion);
		case ConcreteExpr.Kind.lambda:
			return cbLambda(a.lambda);
		case ConcreteExpr.Kind.let:
			return cbLet(a.let);
		case ConcreteExpr.Kind.localRef:
			return cbLocalRef(a.localRef);
		case ConcreteExpr.Kind.match:
			return cbMatch(a.match);
		case ConcreteExpr.Kind.paramRef:
			return cbParamRef(a.paramRef);
		case ConcreteExpr.Kind.recordFieldAccess:
			return cbRecordFieldAccess(a.recordFieldAccess);
		case ConcreteExpr.Kind.recordFieldSet:
			return cbRecordFieldSet(a.recordFieldSet);
		case ConcreteExpr.Kind.seq:
			return cbSeq(a.seq);
		case ConcreteExpr.Kind.specialConstant:
			return cbSpecialConstant(a.specialConstant);
		case ConcreteExpr.Kind.specialUnary:
			return cbSpecialUnary(a.specialUnary);
		case ConcreteExpr.Kind.specialBinary:
			return cbSpecialBinary(a.specialBinary);
		case ConcreteExpr.Kind.stringLiteral:
			return cbStringLiteral(a.stringLiteral);
	}
}

struct ConcreteProgram {
	immutable Arr!(Ptr!ConcreteStruct) allStructs;
	immutable Arr!(Ptr!ConcreteFun) allFuns;
	immutable Ptr!ConcreteFun rtMain;
	immutable Ptr!ConcreteFun userMain;
	immutable Ptr!ConcreteStruct ctxType;
}
