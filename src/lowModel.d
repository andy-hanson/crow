module lowModel;

@safe @nogc pure nothrow:

import concreteModel : BuiltinStructInfo, BuiltinStructKind;
import util.bools : Bool;
import util.collection.arr : Arr;
import util.collection.str : Str;
import util.late : Late, lateGet, lateSet;
import util.opt : Opt;
import util.ptr : Ptr;
import util.sourceRange : SourceRange;

/*
struct LowStructBody {
	@safe @nogc pure nothrow:

	struct Builtin {
		immutable BuiltinStructInfo info;
		immutable Arr!LowType typeArgs;
	}
	struct Record {
		immutable Arr!LowField fields;
	}
	// NOTE: this is not completely a low-level union as it still has the discriminant
	struct Union {
		immutable Arr!LowType members;
	}

	private:
	enum Kind {
		builtin,
		record,
		union_,
	}
	immutable Kind kind;
	union {
		immutable Builtin builtin;
		immutable Record record;
		immutable Union union_;
	}

	public:
	@trusted immutable this(immutable Builtin a) { kind = Kind.builtin; builtin = a; }
	@trusted immutable this(immutable Record a) { kind = Kind.record; record = a; }
	@trusted immutable this(immutable Union a) { kind = Kind.union_; union_ = a; }
}

@trusted T matchLowStructBody(T)(
	ref immutable LowStructBody a,
	scope T delegate(ref immutable LowStructBody.Builtin) @safe @nogc pure nothrow cbBuiltin,
	scope T delegate(ref immutable LowStructBody.Record) @safe @nogc pure nothrow cbRecord,
	scope T delegate(ref immutable LowStructBody.Union) @safe @nogc pure nothrow cbUnion,
) {
	final switch (a.kind) {
		case LowStructBody.Kind.builtin:
			return cbBuiltin(a.builtin);
		case LowStructBody.Kind.record:
			return cbRecord(a.record);
		case LowStructBody.Kind.union_:
			return cbUnion(a.union_);
	}
}
*/

struct LowRecord {
	// TODO: first field will be the reference count field. Not implicit like it is for ConcreteStruct
	immutable Arr!LowField fields;
}

struct LowUnion {
	immutable Arr!LowType members;
}

struct LowFunPtrType {
	immutable LowType returnType;
	immutable Arr!LowType paramTypes;
}

struct LowPtrType {
	immutable Ptr!LowType pointee;
}

struct LowType {
	private:
	enum Kind {
		builtin,
		funPtr,
		ptr,
		record,
		union_,
	}
	immutable Kind kind_;
	union {
		immutable BuiltinStructKind builtin_;
		immutable Ptr!LowFunPtrType funPtr_;
		immutable LowPtrType ptr_;
		immutable Ptr!LowRecord record_;
		immutable Ptr!LowUnion union_;
	}

	public:
	immutable this(immutable BuiltinStructKind a) { kind_ = Kind.builtin; builtin_ = a;}
	@trusted immutable this(immutable Ptr!LowFunPtrType a) { kind_ = Kind.funPtr; funPtr_ = a; }
	@trusted immutable this(immutable LowPtrType a) { kind_ = Kind.ptr; ptr_ = a; }
	@trusted immutable this(immutable Ptr!LowRecord a) { kind_ = Kind.record; record_ = a; }
	@trusted immutable this(immutable Ptr!LowUnion a) { kind_ = Kind.union_; union_ = a; }
}

T matchLowType(T)(
	ref immutable LowType a,
	scope T delegate(immutable BuiltinStructKind) @safe @nogc pure nothrow cbBuiltin,
	scope T delegate(immutable Ptr!LowFunPtrType) @safe @nogc pure nothrow cbFunPtr,
	scope T delegate(immutable LowPtrType) @safe @nogc pure nothrow cbPtr,
	scope T delegate(immutable Ptr!LowRecord) @safe @nogc pure nothrow cbRecord,
	scope T delegate(immutable Ptr!LowUnion) @safe @nogc pure nothrow cbUnion,
) {
	final switch (a.kind) {
		case LowType.Kind.builtin:
			return cbBuiltin(a.builtin_);
		case LowType.Kind.funPtr:
			return cbFunPtr(a.funPtr_);
		case LowType.Kind.ptr:
			return cbPtr(a.ptr_);
		case LowType.Kind.record:
			return cbRecord(a.record_);
		case LowType.Kind.union_:
			return cbUnion(a.union_);
	}
}

struct LowField {
	immutable Str mangledName;
	immutable LowType type;
}

struct LowParam {
	immutable Str mangledName;
	immutable LowType type;
}

struct LowLocal {
	immutable Str mangledName;
	immutable LowType type;
}

struct LowFunExprBody {
	immutable Arr!(Ptr!LowLocal) allLocals;
	immutable LowExpr expr;
}

// Unlike ConcreteFunBody, this is always an expr or extern.
struct LowFunBody {
	struct Extern {
		immutable Bool isGlobal_;
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
	immutable this(immutable Extern a) { kind = Kind.extern_; extern_ = a; }
	@trusted immutable this(immutable LowFunExprBody a) { kind = Kind.expr; expr_ = a; }
}

T matchLowFunBody(T)(
	ref immutable LowFunBody a,
	scope T delegate(ref immutable LowFunBody.Extern) @safe @nogc pure nothrow cbExtern,
	scope T delegate(ref immutable LowFunExprBody) @safe @nogc pure nothrow cbExpr,
) {
	final switch (a.kind) {
		case LowFunBody.Kind.extern_:
			return cbExtern(a.extern_);
		case LowFunBody.Kind.expr:
			retur ncbExpr(a.expr_);
	}
}

struct LowFun {
	immutable(Str) mangledName;
	immutable(LowType) returnType;
	immutable Arr!LowParam params;
	Late!(immutable LowFunBody) _body_;
}

ref immutable(LowFunBody) body_(return scope ref const LowFun a) {
	return lateGet(a._body_);
}

void setBody(ref LowFun a, immutable LowFunBody value) {
	lateSet(a._body_, value);
}

struct LowExpr {
	immutable LowType type;
	immutable SourceRange range;
	immutable LowExprKind kind;
}

struct LowExprKind {
	struct Call {
		immutable Ptr!LowFun called;
		immutable Arr!LowExpr args;
	}

	struct Cond {
		immutable Ptr!LowExpr cond;
		immutable Ptr!LowExpr then;
		immutable Ptr!LowExpr else_;
	}

	struct CreateRecord {
		immutable Arr!LowExpr args;
	}

	struct ConvertToUnion {
		immutable size_t memberIndex;
		immutable Ptr!LowExpr arg;
	}

	struct Let {
		immutable Ptr!LowLocal local;
		immutable Ptr!LowExpr value;
		immutable Ptr!LowExpr then;
	}

	struct LocalRef {
		immutable Ptr!LowLocal local;
	}

	//TODO: make this disappear into Cond on getting the union idx?
	struct Match {
		struct Case {
			immutable Opt!(Ptr!LowLocal) local;
			immutable LowExpr then;
		}

		immutable Ptr!LowLocal matchedLocal;
		immutable Ptr!LowExpr matchedValue;
		immutable Arr!Case cases;
	}

	struct ParamRef {
		immutable Ptr!LowParam param;
	}

	struct RecordFieldAccess {
		immutable Ptr!LowExpr target;
		immutable Ptr!LowField field;
	}

	struct RecordFieldSet {
		immutable Ptr!LowExpr target;
		immutable Ptr!LowField field;
		immutable Ptr!LowExpr value;
	}

	struct Seq {
		immutable Ptr!LowExpr first;
		immutable Ptr!LowExpr then;
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
		immutable Ptr!LowExpr arg;
	}

	struct SpecialBinary {
		enum Kind {
			add,
			eq,
			less,
			or,
			sub,
		}
		immutable Kind kind;
		immutable Ptr!LowExpr left;
		immutable Ptr!LowExpr right;
	}

	struct StringLiteral {
		immutable Str literal;
	}

	private:
	enum Kind {
		call,
		cond,
		createRecord,
		convertToUnion,
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
	immutable Kind kind;
	union {
		immutable Call call;
		immutable Cond cond;
		immutable CreateRecord createRecord;
		immutable ConvertToUnion convertToUnion;
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
	@trusted immutable this(immutable Call a) { kind = Kind.call; call = a; }
	@trusted immutable this(immutable Cond a) { kind = Kind.cond; cond = a; }
	@trusted immutable this(immutable CreateRecord a) { kind = Kind.createRecord; createRecord = a; }
	@trusted immutable this(immutable ConvertToUnion a) { kind = Kind.convertToUnion; convertToUnion = a; }
	@trusted immutable this(immutable Let a) { kind = Kind.let; let = a; }
	@trusted immutable this(immutable LocalRef a) { kind = Kind.localRef; localRef = a; }
	@trusted immutable this(immutable Match a) { kind = Kind.match; match = a; }
	@trusted immutable this(immutable ParamRef a) { kind = Kind.paramRef; paramRef = a; }
	@trusted immutable this(immutable RecordFieldAccess a) { kind = Kind.recordFieldAccess; recordFieldAccess = a; }
	@trusted immutable this(immutable RecordFieldSet a) { kind = Kind.recordFieldSet; recordFieldSet = a; }
	@trusted immutable this(immutable Seq a) { kind = Kind.seq; seq = a; }
	@trusted immutable this(immutable SpecialConstant a) { kind = Kind.specialConstant; specialConstant = a; }
	@trusted immutable this(immutable SpecialUnary a) { kind = Kind.specialUnary; specialUnary = a; }
	@trusted immutable this(immutable SpecialBinary a) { kind = Kind.specialBinary; specialBinary = a; }
	@trusted immutable this(immutable StringLiteral a) { kind = Kind.stringLiteral; stringLiteral = a; }
}

T matchLowExpr(T)(
	ref immutable LowExpr a,
	scope T delegate(ref immutable LowExpr.Call) @safe @nogc pure nothrow cbCall,
	scope T delegate(ref immutable LowExpr.Cond) @safe @nogc pure nothrow cbCond,
	scope T delegate(ref immutable LowExpr.CreateRecord) @safe @nogc pure nothrow cbCreateRecord,
	scope T delegate(ref immutable LowExpr.ConvertToUnion) @safe @nogc pure nothrow cbConvertToUnion,
	scope T delegate(ref immutable LowExpr.Let) @safe @nogc pure nothrow cbLet,
	scope T delegate(ref immutable LowExpr.LocalRef) @safe @nogc pure nothrow cbLocalRef,
	scope T delegate(ref immutable LowExpr.Match) @safe @nogc pure nothrow cbMatch,
	scope T delegate(ref immutable LowExpr.ParamRef) @safe @nogc pure nothrow cbParamRef,
	scope T delegate(ref immutable LowExpr.RecordFieldAccess) @safe @nogc pure nothrow cbRecordFieldAccess,
	scope T delegate(ref immutable LowExpr.RecordFieldSet) @safe @nogc pure nothrow cbRecordFieldSet,
	scope T delegate(ref immutable LowExpr.Seq) @safe @nogc pure nothrow cbSeq,
	scope T delegate(ref immutable LowExpr.SpecialConstant) @safe @nogc pure nothrow cbSpecialConstant,
	scope T delegate(ref immutable LowExpr.SpecialUnary) @safe @nogc pure nothrow cbSpecialUnary,
	scope T delegate(ref immutable LowExpr.SpecialBinary) @safe @nogc pure nothrow cbSpecialBinary,
	scope T delegate(ref immutable LowExpr.StringLiteral) @safe @nogc pure nothrow cbStringLiteral,
) {
	final switch (a.kind) {
		case LowExpr.Kind.call:
			return cbCall(a.call);
		case LowExpr.Kind.cond:
			return cbCond(a.cond);
		case LowExpr.Kind.createRecord:
			return cbCreateRecord(a.createRecord);
		case LowExpr.Kind.convertToUnion:
			return cbConvertToUnion(a.convertToUnion);
		case LowExpr.Kind.let:
			return cbLet(a.let);
		case LowExpr.Kind.localRef:
			return cbLocalRef(a.localRef);
		case LowExpr.Kind.match:
			return cbMatch(a.match);
		case LowExpr.Kind.paramRef:
			return cbParamRef(a.paramRef);
		case LowExpr.Kind.recordFieldAccess:
			return cbRecordFieldAccess(a.recordFieldAccess);
		case LowExpr.Kind.recordFieldSet:
			return cbRecordFieldSet(a.recordFieldSet);
		case LowExpr.Kind.seq:
			return cbSeq(a.seq);
		case LowExpr.Kind.specialConstant:
			return cbSpecialConstant(a.specialConstant);
		case LowExpr.Kind.specialUnary:
			return cbSpecialUnary(a.specialUnary);
		case LowExpr.Kind.specialBinary:
			return cbSpecialBinary(a.specialBinary);
		case LowExpr.Kind.stringLiteral:
			return cbStringLiteral(a.stringLiteral);
	}
}

struct LowProgram {
	immutable Arr!(Ptr!LowRecord) allRecords;
	immutable Arr!(Ptr!LowUnion) allUnions;
	immutable Ptr!LowFun main;
}
