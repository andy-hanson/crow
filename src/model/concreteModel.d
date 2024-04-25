module model.concreteModel;

@safe @nogc pure nothrow:

import model.constant : Constant;
import model.model :
	BuiltinBinaryLazy,
	BuiltinFun,
	BuiltinType,
	ClosureReferenceKind,
	EnumFunction,
	Expr,
	FlagsFunction,
	FunDecl,
	IntegralType,
	isTuple,
	Local,
	localIsAllocated,
	Params,
	Purity,
	StructDecl,
	StructInst,
	Test,
	VarDecl;
import util.alloc.alloc : Alloc;
import util.col.array : arraysEqual, only, PtrAndSmallNumber, SmallArray;
import util.col.map : Map;
import util.col.set : Set;
import util.hash : HashCode, Hasher, hashPtr;
import util.integralValues : IntegralValue, IntegralValues;
import util.late : Late, lateGet, lateIsSet, lateSet, lateSetOverwrite;
import util.opt : none, Opt, some;
import util.sourceRange : Range, UriAndRange;
import util.string : CString;
import util.symbol : Symbol;
import util.union_ : TaggedUnion, Union;
import util.uri : Uri;
import versionInfo : VersionInfo;

immutable struct ConcreteStructBody {
	immutable struct Builtin {
		BuiltinType kind; // Never 'lambda'. Can we type this better? ---------------------------------------------------------
		SmallArray!ConcreteType typeArgs;
	}
	immutable struct Enum {
		IntegralType storage;
	}
	immutable struct Flags {
		IntegralType storage;
	}
	immutable struct Extern {}
	immutable struct Record {
		SmallArray!ConcreteField fields;
	}
	// Both StructBody.Union and StructBody.Variant compile to this
	immutable struct Union {
		@safe @nogc pure nothrow:
		// In the concrete model we identify members by index, so don't care about their names.
		// This may be empty for a lambda type with no implementations.
		Late!(SmallArray!ConcreteType) members_;

		SmallArray!ConcreteType members() return scope =>
			lateGet(members_);
	}

	mixin .Union!(Builtin*, Enum, Extern, Flags, Record, Union);
}
static assert(ConcreteStructBody.sizeof == ConcreteStructBody.Record.sizeof + size_t.sizeof);

immutable struct ConcreteType {
	@safe @nogc pure nothrow:

	ReferenceKind reference;
	ConcreteStruct* struct_;

	static ConcreteType byVal(ConcreteStruct* struct_) =>
		ConcreteType(ReferenceKind.byVal, struct_);

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
	a.struct_.body_.isA!(ConcreteStructBody.Builtin*) &&
	a.struct_.body_.as!(ConcreteStructBody.Builtin*).kind == BuiltinType.void_;

alias ReferenceKind = immutable ReferenceKind_;
private enum ReferenceKind_ { byVal, byRef }

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
		StructDecl* decl;
		SmallArray!ConcreteType typeArgs;
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
		fiber,
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
bool isFiber(in ConcreteStruct a) =>
	a.specialKind == ConcreteStruct.SpecialKind.fiber;
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
			return true;
	}
}

TypeSize sizeOrPointerSizeBytes(in ConcreteType a) {
	final switch (a.reference) {
		case ReferenceKind.byVal:
			return a.struct_.typeSize;
		case ReferenceKind.byRef:
			return TypeSize(8, 8);
	}
}

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
	immutable struct Closure {} // Closure parameter
	enum Generated { args, ignore, destruct, member, reference }
	mixin TaggedUnion!(Local*, Closure, Generated);
}

immutable struct ConcreteLocal {
	ConcreteLocalSource source;
	ConcreteType type;
}

immutable struct ConcreteFunBody {
	immutable struct Builtin {
		BuiltinFun kind; // Never 'lambdaCall' (TODO: can we type this better?) --------------------------------------------
		ConcreteType[] typeArgs;
	}
	immutable struct Extern {
		Symbol libraryName;
	}
	immutable struct FlagsFn {
		ulong allValue;
		FlagsFunction fn;
	}
	immutable struct VarGet { ConcreteVar* var; }
	immutable struct VarSet { ConcreteVar* var; }

	mixin Union!(Builtin, Constant, EnumFunction, Extern, ConcreteExpr, FlagsFn, VarGet, VarSet);
}

immutable struct ConcreteFunSource {
	immutable struct Lambda {
		ConcreteFun* containingFun;
		Expr* bodyExpr;
		size_t index; // nth lambda in the containing function
	}

	immutable struct Test {
		.Test* test;
		size_t testIndex; // Arbitrary index over all tests
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
	ConcreteLocal[] params;
	private Late!ConcreteFunBody lateBody;

	ref ConcreteFunBody body_() return scope =>
		lateGet(lateBody);

	void body_(ConcreteFunBody value) {
		lateSet(lateBody, value);
	}

	void overwriteBody(ConcreteFunBody value) {
		lateSetOverwrite(lateBody, value);
	}

	Uri moduleUri() scope =>
		range.uri;

	UriAndRange range() scope =>
		source.matchIn!UriAndRange(
			(in ConcreteFunKey x) =>
				x.decl.range,
			(in ConcreteFunSource.Lambda x) =>
				UriAndRange(x.containingFun.moduleUri, x.bodyExpr.range),
			(in ConcreteFunSource.Test x) =>
				x.test.range,
			(in ConcreteFunSource.WrapMain x) =>
				x.range);
}

immutable struct ConcreteFunKey {
	@safe @nogc pure nothrow:

	FunDecl* decl;
	SmallArray!ConcreteType typeArgs;
	SmallArray!(immutable ConcreteFun*) specImpls;

	this(FunDecl* d, SmallArray!ConcreteType ta, SmallArray!(immutable ConcreteFun*) si) { // -----------------------------
		decl = d;
		typeArgs = ta;
		specImpls = si;
		if (decl.body_.isA!BuiltinFun) {
			BuiltinFun bf = decl.body_.as!BuiltinFun;
			assert(!bf.isA!BuiltinBinaryLazy);
		}
	}

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

immutable struct ConcreteExpr {
	ConcreteType type;
	UriAndRange range;
	ConcreteExprKind kind;
}

immutable struct ConcreteExprKind {
	immutable struct Call {
		ConcreteFun* called;
		SmallArray!ConcreteExpr args;
	}

	immutable struct CreateArray {
		ConcreteExpr[] args;
	}

	immutable struct CreateRecord {
		ConcreteExpr[] args;
	}

	immutable struct CreateUnion {
		size_t memberIndex;
		ConcreteExpr arg;
	}

	immutable struct Drop {
		ConcreteExpr arg;
	}

	immutable struct Finally {
		ConcreteExpr right;
		ConcreteExpr below;
	}

	immutable struct If {
		ConcreteExpr cond;
		ConcreteExpr then;
		ConcreteExpr else_;
	}

	immutable struct Let {
		ConcreteLocal* local;
		ConcreteExpr value;
		ConcreteExpr then;
	}

	immutable struct LocalGet {
		ConcreteLocal* local;
	}
	immutable struct LocalPointer {
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
		ConcreteExpr value;
	}
	immutable struct LoopContinue {}

	immutable struct MatchEnumOrIntegral {
		@safe @nogc pure nothrow:
		ConcreteExpr matched;
		IntegralValues caseValues;
		SmallArray!ConcreteExpr caseExprs;
		Opt!(ConcreteExpr*) else_;

		this(ConcreteExpr m, IntegralValues cv, ConcreteExpr[] ce, Opt!(ConcreteExpr*) e) {
			matched = m; caseValues = cv; caseExprs = ce; else_ = e;
			assert(caseExprs.length == caseValues.length);
		}
	}

	immutable struct MatchStringLike {
		immutable struct Case {
			ConcreteExpr value;
			ConcreteExpr then;
		}

		ConcreteExpr matched;
		ConcreteFun* equals;
		SmallArray!Case cases;
		ConcreteExpr else_;
	}

	immutable struct MatchUnion {
		immutable struct Case {
			Opt!(ConcreteLocal*) local;
			ConcreteExpr then;
		}

		ConcreteExpr matched;
		IntegralValues memberIndices;
		SmallArray!Case cases;
		Opt!(ConcreteExpr*) else_;
	}

	immutable struct RecordFieldGet {
		ConcreteExpr* record; // May be by-value or by-ref
		size_t fieldIndex;
	}

	immutable struct RecordFieldPointer {
		ConcreteExpr* record;
		size_t fieldIndex;
	}

	immutable struct RecordFieldSet {
		ConcreteExpr record; // May be by-value or by-ref
		size_t fieldIndex;
		ConcreteExpr value;
	}

	immutable struct Seq {
		ConcreteExpr first;
		ConcreteExpr then;
	}

	immutable struct Throw {
		// a `c-string`
		ConcreteExpr thrown;
	}

	immutable struct Try {
		ConcreteExpr tried;
		IntegralValues exceptionMemberIndices;
		SmallArray!(MatchUnion.Case) catchCases;
	}

	immutable struct TryLet {
		Opt!(ConcreteLocal*) local;
		ConcreteExpr value;
		IntegralValue exceptionMemberIndex;
		MatchUnion.Case catch_;
		ConcreteExpr then;
	}

	// Unsafe internal operation for casting a union to a member. Does not check the kind!
	immutable struct UnionAs {
		ConcreteExpr* union_;
		uint memberIndex;
	}

	// Internal operation for getting the 'kind' of a union. (This is the member index.)
	immutable struct UnionKind {
		ConcreteExpr* union_;
	}

	mixin Union!(
		Call,
		Constant,
		CreateArray,
		CreateRecord,
		CreateUnion*,
		Drop*,
		Finally*,
		If*,
		Let*,
		LocalGet,
		LocalPointer,
		LocalSet*,
		Loop*,
		LoopBreak*,
		LoopContinue,
		MatchEnumOrIntegral*,
		MatchStringLike*,
		MatchUnion*,
		RecordFieldGet,
		RecordFieldPointer,
		RecordFieldSet*,
		Seq*,
		Throw*,
		Try*,
		TryLet*,
		UnionAs,
		UnionKind);
}
version (WebAssembly) {} else {
	static assert(ConcreteExprKind.sizeof == ConcreteExprKind.Call.sizeof + ulong.sizeof);
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

	VersionInfo version_;
	AllConstantsConcrete allConstants;
	ConcreteStruct*[] allStructs;
	ConcreteVar*[] allVars;
	ConcreteFun*[] allFuns;
	// The functions are still in 'allFuns', this is just to identify them
	Set!(immutable ConcreteFun*) yieldingFuns;
	ConcreteCommonFuns commonFuns;
}
immutable struct ConcreteCommonFuns {
	ConcreteFun* alloc;
	ConcreteFun* curJmpBuf;
	ConcreteFun* setCurJmpBuf;
	ConcreteVar* curThrown;
	ConcreteFun* mark;
	ConcreteFun* markVisitFiber;
	ConcreteFun* rethrowCurrentException;
	ConcreteFun* runFiber;
	ConcreteFun* rtMain;
	ConcreteFun* setjmp;
	ConcreteFun* throwImpl;
	ConcreteFun* userMain;

	ConcreteFun* gcRoot;
	ConcreteFun* setGcRoot;
	ConcreteFun* popGcRoot;
}
