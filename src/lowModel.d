module lowModel;

@safe @nogc pure nothrow:

import util.bools : Bool;
import util.collection.arr : Arr;
import util.collection.str : Str;
import util.opt : Opt;
import util.ptr : Ptr;
import util.sourceRange : SourceRange;

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

enum PrimitiveType {
	bool_,
	byte_,
	char_,
	float64,
	int16,
	int32,
	int64,
	nat16,
	nat32,
	nat64,
	void_,
}

struct LowType {
	@safe @nogc pure nothrow:

	struct FunPtr {
		immutable size_t index;
	}
	struct NonFunPtr {
		immutable Ptr!LowType pointee;
	}
	struct Record {
		immutable size_t index;
	}
	struct Union {
		immutable size_t index;
	}

	private:
	enum Kind {
		funPtr,
		nonFunPtr,
		primitive,
		record,
		union_,
	}
	immutable Kind kind_;
	union {
		immutable FunPtr funPtr_;
		immutable NonFunPtr nonFunPtr_;
		immutable PrimitiveType primitive_;
		immutable Record record_;
		immutable Union union_;
	}

	public:
	immutable this(immutable FunPtr a) { kind_ = Kind.funPtr; funPtr_ = a; }
	@trusted immutable this(immutable NonFunPtr a) { kind_ = Kind.nonFunPtr; nonFunPtr_ = a; }
	immutable this(immutable PrimitiveType a) { kind_ = Kind.primitive; primitive_ = a; }
	immutable this(immutable Record a) { kind_ = Kind.record; record_ = a; }
	immutable this(immutable Union a) { kind_ = Kind.union_; union_ = a; }
}

immutable(LowType.FunPtr) asFunPtrType(ref immutable LowType a) {
	assert(a.kind_ == LowType.Kind.funPtr);
	return a.funPtr_;
}

T matchLowType(T)(
	ref immutable LowType a,
	scope T delegate(immutable LowType.FunPtr) @safe @nogc pure nothrow cbBuiltin,
	scope T delegate(immutable LowType.NonFunPtr) @safe @nogc pure nothrow cbFunPtr,
	scope T delegate(immutable PrimitiveType) @safe @nogc pure nothrow cbPtr,
	scope T delegate(immutable LowType.Record) @safe @nogc pure nothrow cbRecord,
	scope T delegate(immutable LowType.Union) @safe @nogc pure nothrow cbUnion,
) {
	final switch (a.kind) {
		case LowType.Kind.funPtr_:
			return cbBuiltin(a.funPtr_);
		case LowType.Kind.nonFunPtr:
			return cbFunPtr(a.nonFunPtr_);
		case LowType.Kind.primitive:
			return cbPtr(a.primitive_);
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
	@safe @nogc pure nothrow:

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
			return cbExpr(a.expr_);
	}
}

struct LowFun {
	immutable(Str) mangledName;
	immutable(LowType) returnType;
	immutable Arr!LowParam params;
	immutable LowFunBody body_;
}

struct LowExpr {
	immutable LowType type;
	immutable SourceRange range;
	immutable LowExprKind kind;
}

struct LowFunIndex {
	immutable size_t index;
}

struct LowExprKind {
	@safe @nogc pure nothrow:

	struct Call {
		immutable LowFunIndex called;
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

	struct FunPtr {
		immutable LowFunIndex fun;
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

	struct SizeOf {
		immutable LowType type;
	}

	struct SpecialConstant {
		@safe @nogc pure nothrow:

		struct Nat {
			immutable size_t value;
		}
		private:
		enum Kind {
			nat,
		}
		immutable Kind kind;
		union {
			immutable Nat nat_;
		}
		public:
		immutable this(immutable Nat a) { kind = Kind.nat; nat_ = a; }
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
			bitShiftLeftInt32,
			eq,
			less,
			mulNat64,
			or,
			sub,
			writeToPtr,
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
		funPtr,
		let,
		localRef,
		match,
		paramRef,
		recordFieldAccess,
		recordFieldSet,
		seq,
		sizeOf,
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
		immutable FunPtr funPtr;
		immutable ConvertToUnion convertToUnion;
		immutable Let let;
		immutable LocalRef localRef;
		immutable Match match;
		immutable ParamRef paramRef;
		immutable RecordFieldAccess recordFieldAccess;
		immutable RecordFieldSet recordFieldSet;
		immutable Seq seq;
		immutable SizeOf sizeOf;
		immutable SpecialConstant specialConstant;
		immutable SpecialUnary specialUnary;
		immutable SpecialBinary specialBinary;
		immutable StringLiteral stringLiteral;
	}

	public:
	@trusted immutable this(immutable Call a) { kind = Kind.call; call = a; }
	@trusted immutable this(immutable Cond a) { kind = Kind.cond; cond = a; }
	@trusted immutable this(immutable CreateRecord a) { kind = Kind.createRecord; createRecord = a; }
	immutable this(immutable FunPtr a) { kind = Kind.funPtr; funPtr = a; }
	@trusted immutable this(immutable ConvertToUnion a) { kind = Kind.convertToUnion; convertToUnion = a; }
	@trusted immutable this(immutable Let a) { kind = Kind.let; let = a; }
	@trusted immutable this(immutable LocalRef a) { kind = Kind.localRef; localRef = a; }
	@trusted immutable this(immutable Match a) { kind = Kind.match; match = a; }
	@trusted immutable this(immutable ParamRef a) { kind = Kind.paramRef; paramRef = a; }
	@trusted immutable this(immutable RecordFieldAccess a) { kind = Kind.recordFieldAccess; recordFieldAccess = a; }
	@trusted immutable this(immutable RecordFieldSet a) { kind = Kind.recordFieldSet; recordFieldSet = a; }
	@trusted immutable this(immutable Seq a) { kind = Kind.seq; seq = a; }
	@trusted immutable this(immutable SizeOf a) { kind = Kind.sizeOf; sizeOf = a; }
	@trusted immutable this(immutable SpecialConstant a) { kind = Kind.specialConstant; specialConstant = a; }
	@trusted immutable this(immutable SpecialUnary a) { kind = Kind.specialUnary; specialUnary = a; }
	@trusted immutable this(immutable SpecialBinary a) { kind = Kind.specialBinary; specialBinary = a; }
	@trusted immutable this(immutable StringLiteral a) { kind = Kind.stringLiteral; stringLiteral = a; }
}

T matchSpecialConstant(T)(
	ref immutable LowExprKind.SpecialConstant a,
	scope T delegate(immutable LowExprKind.SpecialConstant.Nat) @safe @nogc pure nothrow cbNat,
) {
	final switch (a.kind) {
		case LowExprKind.SpecialConstant.Kind.nat:
			return cbNat(a.nat_);
	}
}

T matchLowExprKind(T)(
	ref immutable LowExprKind a,
	scope T delegate(ref immutable LowExprKind.Call) @safe @nogc pure nothrow cbCall,
	scope T delegate(ref immutable LowExprKind.Cond) @safe @nogc pure nothrow cbCond,
	scope T delegate(ref immutable LowExprKind.CreateRecord) @safe @nogc pure nothrow cbCreateRecord,
	scope T delegate(ref immutable LowExprKind.ConvertToUnion) @safe @nogc pure nothrow cbConvertToUnion,
	scope T delegate(ref immutable LowExprKind.FunPtr) @safe @nogc pure nothrow cbFunPtr,
	scope T delegate(ref immutable LowExprKind.Let) @safe @nogc pure nothrow cbLet,
	scope T delegate(ref immutable LowExprKind.LocalRef) @safe @nogc pure nothrow cbLocalRef,
	scope T delegate(ref immutable LowExprKind.Match) @safe @nogc pure nothrow cbMatch,
	scope T delegate(ref immutable LowExprKind.ParamRef) @safe @nogc pure nothrow cbParamRef,
	scope T delegate(ref immutable LowExprKind.RecordFieldAccess) @safe @nogc pure nothrow cbRecordFieldAccess,
	scope T delegate(ref immutable LowExprKind.RecordFieldSet) @safe @nogc pure nothrow cbRecordFieldSet,
	scope T delegate(ref immutable LowExprKind.Seq) @safe @nogc pure nothrow cbSeq,
	scope T delegate(ref immutable LowExprKind.SizeOf) @safe @nogc pure nothrow cbSizeOf,
	scope T delegate(ref immutable LowExprKind.SpecialConstant) @safe @nogc pure nothrow cbSpecialConstant,
	scope T delegate(ref immutable LowExprKind.SpecialUnary) @safe @nogc pure nothrow cbSpecialUnary,
	scope T delegate(ref immutable LowExprKind.SpecialBinary) @safe @nogc pure nothrow cbSpecialBinary,
	scope T delegate(ref immutable LowExprKind.StringLiteral) @safe @nogc pure nothrow cbStringLiteral,
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
		case LowExpr.Kind.funPtr:
			return cbFunPtr(a.funPtr);
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
		case LowExpr.Kind.sizeOf:
			return cbSizeOf(a.sizeOf);
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
	immutable Arr!LowFunPtrType allFunPtrs;
	immutable Arr!LowRecord allRecords;
	immutable Arr!LowUnion allUnions;
	immutable Arr!LowFun allFuns;
	immutable Ptr!LowFun main;
}
