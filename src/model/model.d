module model.model;

@safe @nogc pure nothrow:

import model.constant : Constant;
import model.diag : Diagnostics, FilesInfo; // TODO: move FilesInfo here?
import util.alloc.alloc : Alloc;
import util.col.arr : empty, emptyArr, only, PtrAndSmallNumber, small, SmallArray;
import util.col.arrUtil : arrEqual;
import util.col.dict : Dict;
import util.col.fullIndexDict : FullIndexDict;
import util.col.mutArr : MutArr;
import util.col.str : SafeCStr;
import util.hash : Hasher;
import util.late : Late, lateGet, lateIsSet, lateSet;
import util.lineAndColumnGetter : LineAndColumnGetter;
import util.memory : allocate;
import util.opt : force, has, Opt, some;
import util.path : Path;
import util.ptr : hashPtr, TaggedPtr;
import util.sourceRange :
	FileAndPos,
	FileAndRange,
	fileAndRangeFromFileAndPos,
	FileIndex,
	rangeOfStartAndName,
	RangeWithinFile;
import util.sym : AllSymbols, Operator, shortSym, SpecialSym, Sym, symForOperator, symForSpecial, writeSym;
import util.util : max, min, unreachable, verify;
import util.writer : writeChar, Writer, writeStatic, writeWithCommas;

alias LineAndColumnGetters = immutable FullIndexDict!(FileIndex, LineAndColumnGetter);

enum Purity : ubyte {
	// sorted best case to worst case
	data,
	sendable,
	mut,
}

struct PurityRange {
	immutable Purity bestCase;
	immutable Purity worstCase;
}

immutable(PurityRange) combinePurityRange(immutable PurityRange a, immutable PurityRange b) {
	return immutable PurityRange(worsePurity(a.bestCase, b.bestCase), worsePurity(a.worstCase, b.worstCase));
}

immutable(bool) isPurityAlwaysCompatible(immutable Purity referencer, immutable PurityRange referenced) {
	return referenced.worstCase <= referencer;
}

immutable(bool) isPurityPossiblyCompatible(immutable Purity referencer, immutable PurityRange referenced) {
	return referenced.bestCase <= referencer;
}

immutable(Purity) worsePurity(immutable Purity a, immutable Purity b) {
	return max(a, b);
}

immutable(Sym) symOfPurity(immutable Purity a) {
	final switch (a) {
		case Purity.data:
			return shortSym("data");
		case Purity.sendable:
			return shortSym("sendable");
		case Purity.mut:
			return shortSym("mut");
	}
}

struct TypeParam {
	@safe @nogc pure nothrow:

	immutable FileAndRange range;
	immutable Sym name;
	immutable size_t index;

	immutable this(immutable FileAndRange r, immutable Sym n, immutable size_t i) {
		range = r;
		name = n;
		index = i;
	}
}

struct Type {
	@safe @nogc pure nothrow:
	struct Bogus {}
	@trusted immutable this(immutable Bogus a) {
		inner = TaggedPtr!Kind(Kind.bogus, null);
	}
	@trusted immutable this(immutable TypeParam* a) {
		inner = TaggedPtr!Kind(Kind.typeParam, a);
	}
	@trusted immutable this(immutable StructInst* a) {
		inner = TaggedPtr!Kind(Kind.structInst, a);
	}

	private:
	enum Kind {
		bogus,
		typeParam,
		structInst,
	}
	immutable TaggedPtr!Kind inner;

	public:

	immutable(bool) opEquals(scope immutable Type b) scope immutable {
		return matchType!(immutable bool)(
			this,
			(immutable Type.Bogus) =>
				isBogus(b),
			(immutable TypeParam* p) =>
				isTypeParam(b) && p == asTypeParam(b),
			(immutable StructInst* i) =>
				isStructInst(b) && i == asStructInst(b));
	}

	void hash(ref Hasher hasher) scope immutable {
		matchType!void(
			this,
			(immutable Type.Bogus) {},
			(immutable TypeParam* p) =>
				hashPtr(hasher, p),
			(immutable StructInst* i) =>
				hashPtr(hasher, i));
	}
}

@trusted immutable(T) matchType(T)(
	immutable Type a,
	scope immutable(T) delegate(immutable Type.Bogus) @safe @nogc pure nothrow cbBogus,
	scope immutable(T) delegate(immutable TypeParam*) @safe @nogc pure nothrow cbTypeParam,
	scope immutable(T) delegate(immutable StructInst*) @safe @nogc pure nothrow cbStructInst
) {
	final switch (a.inner.tag()) {
		case Type.Kind.bogus:
			immutable Type.Bogus bogus = immutable Type.Bogus();
			return cbBogus(bogus);
		case Type.Kind.typeParam:
			return cbTypeParam(a.inner.asPtr!TypeParam());
		case Type.Kind.structInst:
			return cbStructInst(a.inner.asPtr!StructInst());
	}
}

immutable(bool) isBogus(immutable Type a) {
	return matchType!(immutable bool)(
		a,
		(immutable Type.Bogus) => true,
		(immutable TypeParam*) => false,
		(immutable StructInst*) => false);
}
immutable(bool) isTypeParam(immutable Type a) {
	return matchType!(immutable bool)(
		a,
		(immutable Type.Bogus) => false,
		(immutable TypeParam*) => true,
		(immutable StructInst*) => false);
}
@trusted immutable(TypeParam*) asTypeParam(immutable Type a) {
	return matchType!(immutable TypeParam*)(
		a,
		(immutable Type.Bogus) => unreachable!(immutable TypeParam*),
		(immutable TypeParam* it) => it,
		(immutable StructInst*) => unreachable!(immutable TypeParam*));
}
immutable(bool) isStructInst(immutable Type a) {
	return matchType!(immutable bool)(
		a,
		(immutable Type.Bogus) => false,
		(immutable TypeParam*) => false,
		(immutable StructInst*) => true);
}
@trusted immutable(StructInst*) asStructInst(immutable Type a) {
	return matchType!(immutable StructInst*)(
		a,
		(immutable Type.Bogus) => unreachable!(immutable StructInst*),
		(immutable TypeParam*) => unreachable!(immutable StructInst*),
		(immutable StructInst* it) => it);
}

immutable(PurityRange) purityRange(immutable Type a) {
	return matchType!(immutable PurityRange)(
		a,
		(immutable Type.Bogus) =>
			immutable PurityRange(Purity.data, Purity.data),
		(immutable TypeParam*) =>
			immutable PurityRange(Purity.data, Purity.mut),
		(immutable StructInst* i) =>
			i.purityRange);
}

immutable(Purity) bestCasePurity(immutable Type a) {
	return purityRange(a).bestCase;
}

immutable(Purity) worstCasePurity(immutable Type a) {
	return purityRange(a).worstCase;
}

immutable(LinkageRange) linkageRange(immutable Type a) {
	return matchType!(immutable LinkageRange)(
		a,
		(immutable Type.Bogus) =>
			immutable LinkageRange(Linkage.extern_, Linkage.extern_),
		(immutable TypeParam*) =>
			immutable LinkageRange(Linkage.internal, Linkage.extern_),
		(immutable StructInst* i) =>
			i.linkageRange);
}

struct Param {
	@safe @nogc pure nothrow:

	//TODO: use NameAndRange (more compact)
	immutable FileAndRange range;
	immutable Opt!Sym name;
	immutable Type type;
	immutable size_t index;

	immutable(Sym) nameOrUnderscore() immutable {
		return has(name) ? force(name) : shortSym("_");
	}

	immutable(RangeWithinFile) nameRange(ref const AllSymbols allSymbols) immutable {
		return rangeOfStartAndName(range.range.start, nameOrUnderscore, allSymbols);
	}
}

immutable(Param) withType(ref immutable Param a, immutable Type t) {
	return Param(a.range, a.name, t, a.index);
}

struct Params {
	@safe @nogc pure nothrow:

	struct Varargs {
		immutable Param param;
		immutable Type elementType;
	}

	@trusted immutable this(immutable Param[] a) {
		inner = immutable TaggedPtr!Kind(Kind.regular, a);
	}
	@trusted immutable this(immutable Varargs* a) {
		inner = immutable TaggedPtr!Kind(Kind.varargs, a);
	}

	private:
	enum Kind {
		regular,
		varargs,
	}
	immutable TaggedPtr!Kind inner;
}

@trusted immutable(T) matchParams(T)(
	ref immutable Params a,
	scope immutable(T) delegate(immutable Param[]) @safe @nogc pure nothrow cbRegular,
	scope immutable(T) delegate(ref immutable Params.Varargs) @safe @nogc pure nothrow cbVarargs,
) {
	final switch (a.inner.tag()) {
		case Params.Kind.regular:
			return cbRegular(a.inner.asArray!Param());
		case Params.Kind.varargs:
			return cbVarargs(*a.inner.asPtr!(Params.Varargs)());
	}
}

@trusted immutable(Param[]) paramsArray(return scope ref immutable Params a) {
	return matchParams!(immutable Param[])(
		a,
		(immutable Param[] p) =>
			p,
		(ref immutable Params.Varargs v) =>
			trustedParamsArray(v));
}
private @trusted immutable(Param[]) trustedParamsArray(return ref immutable Params.Varargs v) {
	return (&v.param)[0 .. 1];
}

immutable(Param[]) assertNonVariadic(ref immutable Params a) {
	return matchParams!(immutable Param[])(
		a,
		(immutable Param[] p) =>
			p,
		(ref immutable Params.Varargs v) =>
			unreachable!(immutable Param[]));
}
struct Arity {
	@safe @nogc pure nothrow:

	struct Varargs {}

	immutable this(immutable size_t a) { kind = Kind.regular; regular = a; }
	immutable this(immutable Varargs a) { kind = Kind.varargs; varargs = a; }

	private:
	enum Kind {
		regular,
		varargs,
	}
	immutable Kind kind;
	union {
		immutable size_t regular;
		immutable Varargs varargs;
	}
}

@trusted immutable(T) matchArity(T, alias cbRegular, alias cbVarargs)(immutable Arity a) {
	final switch (a.kind) {
		case Arity.Kind.regular:
			return cbRegular(a.regular);
		case Arity.Kind.varargs:
			return cbVarargs(a.varargs);
	}
}

immutable(bool) arityIsNonZero(immutable Arity a) {
	return matchArity!(
		immutable bool,
		(immutable size_t size) =>
			size != 0,
		(ref immutable Arity.Varargs) =>
			true,
	)(a);
}

immutable(bool) arityMatches(immutable Arity sigArity, immutable size_t nArgs) {
	return matchArity!(
		immutable bool,
		(immutable size_t nParams) =>
			nParams == nArgs,
		(ref immutable Arity.Varargs) =>
			true,
	)(sigArity);
}

immutable(Arity) arity(ref immutable Params a) {
	return matchParams!(immutable Arity)(
		a,
		(immutable Param[] params) =>
			immutable Arity(params.length),
		(ref immutable Params.Varargs) =>
			immutable Arity(immutable Arity.Varargs()));
}

struct SpecDeclSig {
	immutable SafeCStr docComment;
	immutable Sig sig;
}

struct Sig {
	@safe @nogc pure nothrow:

	immutable FileAndPos fileAndPos;
	immutable Sym name;
	immutable Type returnType;
	immutable Params params;

	immutable(RangeWithinFile) nameRange(ref const AllSymbols allSymbols) immutable {
		return rangeOfStartAndName(fileAndPos.pos, name, allSymbols);
	}

	immutable(FileAndRange) nameFileAndRange(ref const AllSymbols allSymbols) immutable {
		return immutable FileAndRange(fileAndPos.fileIndex, nameRange(allSymbols));
	}
}
static assert(Sig.sizeof <= 48);

immutable(Arity) arity(ref const Sig a) {
	return arity(a.params);
}

enum FieldMutability {
	const_,
	private_,
	public_,
}

immutable(Sym) symOfFieldMutability(immutable FieldMutability a) {
	final switch (a) {
		case FieldMutability.const_:
			return shortSym("const");
		case FieldMutability.private_:
			return shortSym("private");
		case FieldMutability.public_:
			return shortSym("public");
	}
}

struct RecordField {
	//TODO: use NameAndRange (more compact)
	immutable FileAndRange range;
	immutable Visibility visibility;
	immutable Sym name;
	immutable FieldMutability mutability;
	immutable Type type;
	immutable size_t index;
}

immutable(RecordField) withType(ref immutable RecordField a, immutable Type t) {
	return immutable RecordField(a.range, a.visibility, a.name, a.mutability, t, a.index);
}

struct UnionMember {
	//TODO: use NameAndRange (more compact)
	immutable FileAndRange range;
	immutable Sym name;
	immutable Opt!Type type;
}

immutable(UnionMember) withType(ref immutable UnionMember a, immutable Type t) {
	return immutable UnionMember(a.range, a.name, some(t));
}

enum ForcedByValOrRefOrNone {
	none,
	byVal,
	byRef,
}

immutable(Sym) symOfForcedByValOrRefOrNone(immutable ForcedByValOrRefOrNone a) {
	final switch (a) {
		case ForcedByValOrRefOrNone.none:
			return shortSym("none");
		case ForcedByValOrRefOrNone.byVal:
			return shortSym("by-val");
		case ForcedByValOrRefOrNone.byRef:
			return shortSym("by-ref");
	}
}

struct RecordFlags {
	immutable Visibility newVisibility;
	immutable bool packed;
	immutable ForcedByValOrRefOrNone forcedByValOrRef;
}

struct EnumValue {
	@safe @nogc pure nothrow:

	// Large nat64 are represented as wrapped to negative values.
	immutable long value;

	//TODO:NOT INSTANCE
	immutable(long) asSigned() immutable { return value; }
	immutable(ulong) asUnsigned() immutable { return cast(ulong) value; }
}

struct StructBody {
	@safe @nogc pure nothrow:
	struct Bogus {}
	struct Builtin {}
	struct Enum {
		struct Member {
			immutable FileAndRange range;
			immutable Sym name;
			immutable EnumValue value;
		}
		immutable EnumBackingType backingType;
		immutable Member[] members;
	}
	struct Flags {
		alias Member = Enum.Member;
		immutable EnumBackingType backingType;
		// For Flags, members should be unsigned
		immutable Member[] members;
	}
	struct ExternPtr {}
	struct Record {
		immutable RecordFlags flags;
		immutable RecordField[] fields;
	}
	struct Union {
		immutable UnionMember[] members;
	}

	private:
	enum Kind {
		bogus,
		builtin,
		enum_,
		flags,
		externPtr,
		record,
		union_,
	}
	immutable Kind kind;
	union {
		immutable Bogus bogus;
		immutable Builtin builtin;
		immutable Enum enum_;
		immutable Flags flags;
		immutable ExternPtr externPtr;
		immutable Record record;
		immutable Union union_;
	}

	public:
	immutable this(immutable Bogus a) { kind = Kind.bogus; bogus = a; }
	immutable this(immutable Builtin a) { kind = Kind.builtin; builtin = a; }
	@trusted immutable this(immutable Enum a) { kind = Kind.enum_; enum_ = a; }
	@trusted immutable this(immutable Flags a) { kind = Kind.flags; flags = a; }
	immutable this(immutable ExternPtr a) { kind = Kind.externPtr; externPtr = a; }
	@trusted immutable this(immutable Record a) { kind = Kind.record; record = a; }
	@trusted immutable this(immutable Union a) { kind = Kind.union_; union_ = a;}
}

immutable(bool) isBogus(ref immutable StructBody a) {
	return a.kind == StructBody.Kind.bogus;
}
private immutable(bool) isRecord(ref const StructBody a) {
	return a.kind == StructBody.Kind.record;
}
@trusted ref const(StructBody.Record) asRecord(return scope ref const StructBody a) {
	verify(isRecord(a));
	return a.record;
}
private immutable(bool) isUnion(ref immutable StructBody a) {
	return a.kind == StructBody.Kind.union_;
}
@trusted ref immutable(StructBody.Union) asUnion(return scope ref immutable StructBody a) {
	verify(isUnion(a));
	return a.union_;
}

@trusted immutable(T) matchStructBody(T)(
	ref immutable StructBody a,
	scope immutable(T) delegate(ref immutable StructBody.Bogus) @safe @nogc pure nothrow cbBogus,
	scope immutable(T) delegate(ref immutable StructBody.Builtin) @safe @nogc pure nothrow cbBuiltin,
	scope immutable(T) delegate(ref immutable StructBody.Enum) @safe @nogc pure nothrow cbEnum,
	scope immutable(T) delegate(ref immutable StructBody.Flags) @safe @nogc pure nothrow cbFlags,
	scope immutable(T) delegate(ref immutable StructBody.ExternPtr) @safe @nogc pure nothrow cbExternPtr,
	scope immutable(T) delegate(ref immutable StructBody.Record) @safe @nogc pure nothrow cbRecord,
	scope immutable(T) delegate(ref immutable StructBody.Union) @safe @nogc pure nothrow cbUnion,
) {
	final switch (a.kind) {
		case StructBody.Kind.bogus:
			return cbBogus(a.bogus);
		case StructBody.Kind.builtin:
			return cbBuiltin(a.builtin);
		case StructBody.Kind.enum_:
			return cbEnum(a.enum_);
		case StructBody.Kind.flags:
			return cbFlags(a.flags);
		case StructBody.Kind.externPtr:
			return cbExternPtr(a.externPtr);
		case StructBody.Kind.record:
			return cbRecord(a.record);
		case StructBody.Kind.union_:
			return cbUnion(a.union_);
	}
}

struct StructAlias {
	@safe @nogc pure nothrow:
	// TODO: use NameAndRange (more compact)
	immutable FileAndRange range;
	immutable SafeCStr docComment;
	immutable Visibility visibility;
	immutable Sym name;
	immutable SmallArray!TypeParam typeParams;

	private:
	// This will be none if the alias target is not found
	Late!(immutable Opt!(StructInst*)) target_;
}

immutable(Opt!(StructInst*)) target(ref immutable StructAlias a) {
	return lateGet(a.target_);
}
void setTarget(ref StructAlias a, immutable Opt!(StructInst*) value) {
	lateSet(a.target_, value);
}

// sorted least strict to most strict
enum Linkage : ubyte { internal, extern_ }

// Range of possible linkage
struct LinkageRange {
	immutable Linkage leastStrict;
	immutable Linkage mostStrict;
}

immutable(LinkageRange) combineLinkageRange(immutable LinkageRange referencer, immutable LinkageRange referenced) {
	return immutable LinkageRange(
		lessStrictLinkage(referencer.leastStrict, referenced.leastStrict),
		lessStrictLinkage(referencer.mostStrict, referenced.mostStrict));
}

private immutable(Linkage) lessStrictLinkage(immutable Linkage a, immutable Linkage b) {
	return min(a, b);
}

immutable(bool) isLinkagePossiblyCompatible(immutable Linkage referencer, immutable LinkageRange referenced) {
	return referenced.mostStrict >= referencer;
}

immutable(bool) isLinkageAlwaysCompatible(immutable Linkage referencer, immutable LinkageRange referenced) {
	return referenced.leastStrict >= referencer;
}

struct StructDecl {
	// TODO: use NameAndRange (more compact)
	immutable FileAndRange range;
	immutable SafeCStr docComment;
	immutable Sym name;
	immutable SmallArray!TypeParam typeParams;
	immutable Visibility visibility;
	immutable Linkage linkage;
	// Note: purity on the decl does not take type args into account
	immutable Purity purity;
	immutable bool purityIsForced;

	private:
	Late!(immutable StructBody) _body_;
}

immutable(bool) bodyIsSet(ref const StructDecl a) {
	return lateIsSet(a._body_);
}

ref const(StructBody) body_(return scope ref const StructDecl a) {
	return lateGet(a._body_);
}
ref immutable(StructBody) body_(return scope ref immutable StructDecl a) {
	return lateGet(a._body_);
}

void setBody(ref StructDecl a, immutable StructBody value) {
	lateSet(a._body_, value);
}

struct StructDeclAndArgs {
	@safe @nogc pure nothrow:

	immutable StructDecl* decl;
	immutable Type[] typeArgs;

	immutable(bool) opEquals(scope immutable StructDeclAndArgs b) scope immutable {
		return decl == b.decl &&
			arrEqual!(immutable Type)(typeArgs, b.typeArgs, (ref immutable Type ta, ref immutable Type tb) =>
				ta == tb);
	}

	void hash(ref Hasher hasher) scope immutable {
		hashPtr(hasher, decl);
		foreach (immutable Type t; typeArgs)
			t.hash(hasher);
	}
}

struct StructInst {
	@safe @nogc pure nothrow:

	immutable StructDeclAndArgs declAndArgs;

	// these are inferred from declAndArgs:
	immutable LinkageRange linkageRange;
	immutable PurityRange purityRange;

	private:
	// Like decl.body but has type args filled in.
	Late!(immutable StructBody) _body_;
}

immutable(bool) isArr(ref immutable StructInst i) {
	// TODO: only do this for the arr in bootstrap, not anything named 'arr'
	return decl(i).name == shortSym("arr");
}

immutable(Sym) name(ref immutable StructInst i) {
	return decl(i).name;
}

const(StructDecl*) decl(ref const StructInst i) {
	return i.declAndArgs.decl;
}
immutable(StructDecl*) decl(ref immutable StructInst i) {
	return i.declAndArgs.decl;
}

ref immutable(Type[]) typeArgs(return scope ref immutable StructInst i) {
	return i.declAndArgs.typeArgs;
}

ref immutable(StructBody) body_(return scope ref immutable StructInst a) {
	return lateGet(a._body_);
}

void setBody(ref StructInst a, immutable StructBody value) {
	lateSet(a._body_, value);
}

struct SpecBody {
	@safe @nogc pure nothrow:

	struct Builtin {
		enum Kind {
			data,
			send,
		}
		immutable Kind kind;
	}

	private:
	enum Kind {
		builtin,
		sigs,
	}
	immutable Kind kind;
	union {
		immutable Builtin builtin;
		immutable SpecDeclSig[] sigs;
	}

	public:
	immutable this(immutable Builtin a) { kind = Kind.builtin; builtin = a; }
	@trusted immutable this(immutable SpecDeclSig[] a) { kind = Kind.sigs; sigs = a; }
}

@trusted immutable(T) matchSpecBody(T)(
	ref immutable SpecBody a,
	scope immutable(T) delegate(immutable SpecBody.Builtin) @safe @nogc pure nothrow cbBuiltin,
	scope immutable(T) delegate(immutable SpecDeclSig[]) @safe @nogc pure nothrow cbSigs,
) {
	final switch (a.kind) {
		case SpecBody.Kind.builtin:
			return cbBuiltin(a.builtin);
		case SpecBody.Kind.sigs:
			return cbSigs(a.sigs);
	}
}

struct SpecDecl {
	// TODO: use NameAndRange (more compact)
	immutable FileAndRange range;
	immutable SafeCStr docComment;
	immutable Visibility visibility;
	immutable Sym name;
	immutable SmallArray!TypeParam typeParams;
	immutable SpecBody body_;
	MutArr!(immutable SpecInst*) insts;
}

struct SpecDeclAndArgs {
	@safe @nogc pure nothrow:

	immutable SpecDecl* decl;
	immutable Type[] typeArgs;

	immutable(bool) opEquals(scope immutable SpecDeclAndArgs b) scope immutable {
		return decl == b.decl &&
			arrEqual!(immutable Type)(typeArgs, b.typeArgs, (ref immutable Type ta, ref immutable Type tb) =>
				ta == tb);
	}

	void hash(ref Hasher hasher) scope immutable {
		hashPtr(hasher, decl);
		foreach (immutable Type t; typeArgs)
			t.hash(hasher);
	}
}

struct SpecInst {
	immutable SpecDeclAndArgs declAndArgs;
	immutable SpecBody body_;
}

immutable(SpecDecl*) decl(ref immutable SpecInst a) {
	return a.declAndArgs.decl;
}

immutable(Type[]) typeArgs(return scope ref immutable SpecInst a) {
	return a.declAndArgs.typeArgs;
}

immutable(Sym) name(ref immutable SpecInst a) {
	return decl(a).name;
}

enum EnumFunction {
	equal,
	intersect,
	members,
	toIntegral,
	union_,
}

immutable(Sym) enumFunctionName(immutable EnumFunction a) {
	final switch (a) {
		case EnumFunction.equal:
			return symForOperator(Operator.equal);
		case EnumFunction.intersect:
			return symForOperator(Operator.and1);
		case EnumFunction.members:
			return shortSym("members");
		case EnumFunction.toIntegral:
			return shortSym("to-integral");
		case EnumFunction.union_:
			return symForOperator(Operator.or1);
	}
}

enum FlagsFunction {
	all,
	negate,
	new_,
}

immutable(Sym) flagsFunctionName(immutable FlagsFunction a) {
	final switch (a) {
		case FlagsFunction.all:
			return shortSym("all");
		case FlagsFunction.negate:
			return symForOperator(Operator.tilde);
		case FlagsFunction.new_:
			return shortSym("new");
	}
}

struct FunBody {
	@safe @nogc pure nothrow:

	struct Builtin {}
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
	struct FileBytes {
		immutable ubyte[] bytes;
	}
	struct RecordFieldGet {
		immutable size_t fieldIndex;
	}
	struct RecordFieldSet {
		immutable size_t fieldIndex;
	}

	private:
	enum Kind {
		builtin,
		createEnum,
		createRecord,
		createUnion,
		enumFunction,
		extern_,
		expr,
		fileBytes,
		flagsFunction,
		recordFieldGet,
		recordFieldSet,
	}
	immutable Kind kind;
	union {
		immutable Builtin builtin;
		immutable CreateEnum createEnum;
		immutable CreateRecord createRecord;
		immutable CreateUnion createUnion;
		immutable EnumFunction enumFunction;
		immutable Extern extern_;
		immutable Expr expr;
		immutable FileBytes fileBytes;
		immutable FlagsFunction flagsFunction;
		immutable RecordFieldGet recordFieldGet;
		immutable RecordFieldSet recordFieldSet;
	}

	public:
	immutable this(immutable Builtin a) { kind = Kind.builtin; builtin = a; }
	immutable this(immutable CreateEnum a) { kind = Kind.createEnum; createEnum = a; }
	immutable this(immutable CreateRecord a) { kind = Kind.createRecord; createRecord = a; }
	immutable this(immutable CreateUnion a) { kind = Kind.createUnion; createUnion = a; }
	immutable this(immutable EnumFunction a) { kind = Kind.enumFunction; enumFunction = a; }
	@trusted immutable this(immutable Extern a) { kind = Kind.extern_; extern_ = a; }
	@trusted immutable this(immutable Expr a) { kind = Kind.expr; expr = a; }
	immutable this(immutable FileBytes a) { kind = Kind.fileBytes; fileBytes = a; }
	immutable this(immutable FlagsFunction a) { kind = Kind.flagsFunction; flagsFunction = a; }
	immutable this(immutable RecordFieldGet a) { kind = Kind.recordFieldGet; recordFieldGet = a; }
	immutable this(immutable RecordFieldSet a) { kind = Kind.recordFieldSet; recordFieldSet = a; }
}

immutable(bool) isExtern(ref immutable FunBody a) {
	return a.kind == FunBody.Kind.extern_;
}

@trusted T matchFunBody(
	T,
	alias cbBuiltin,
	alias cbCreateEnum,
	alias cbCreateRecord,
	alias cbCreateUnion,
	alias cbEnumFunction,
	alias cbExtern,
	alias cbExpr,
	alias cbFileBytes,
	alias cbFlagsFunction,
	alias cbRecordFieldGet,
	alias cbRecordFieldSet,
)(
	ref immutable FunBody a,
) {
	final switch (a.kind) {
		case FunBody.Kind.builtin:
			return cbBuiltin(a.builtin);
		case FunBody.Kind.createEnum:
			return cbCreateEnum(a.createEnum);
		case FunBody.Kind.createRecord:
			return cbCreateRecord(a.createRecord);
		case FunBody.Kind.createUnion:
			return cbCreateUnion(a.createUnion);
		case FunBody.Kind.enumFunction:
			return cbEnumFunction(a.enumFunction);
		case FunBody.Kind.extern_:
			return cbExtern(a.extern_);
		case FunBody.Kind.fileBytes:
			return cbFileBytes(a.fileBytes);
		case FunBody.Kind.flagsFunction:
			return cbFlagsFunction(a.flagsFunction);
		case FunBody.Kind.expr:
			return cbExpr(a.expr);
		case FunBody.Kind.recordFieldGet:
			return cbRecordFieldGet(a.recordFieldGet);
		case FunBody.Kind.recordFieldSet:
			return cbRecordFieldSet(a.recordFieldSet);
	}
}

struct FunFlags {
	@safe @nogc pure nothrow:

	immutable bool noDoc;
	immutable bool noCtx;
	immutable bool summon;
	immutable bool unsafe;
	immutable bool trusted;
	immutable bool generated;
	immutable bool preferred;
	immutable bool okIfUnused;

	immutable(FunFlags) withOkIfUnused() immutable {
		return immutable FunFlags(noDoc, noCtx, summon, unsafe, trusted, generated, preferred, true);
	}

	static immutable FunFlags none = immutable FunFlags(false, false, false, false, false, false, false, false);
	static immutable FunFlags generatedNoCtx = immutable FunFlags(true, true, false, false, false, true, false, false);
	static immutable FunFlags generatedPreferred =
		immutable FunFlags(true, false, false, false, false, true, true, false);
	static immutable FunFlags unsafeSummon = immutable FunFlags(false, false, true, true, false, false, false, false);
}
static assert(FunFlags.sizeof == 8);

struct FunDecl {
	@safe @nogc pure nothrow:

	@disable this(ref const FunDecl);
	this(
		immutable SafeCStr dc,
		immutable Visibility v,
		immutable FunFlags f,
		immutable Sig s,
		immutable TypeParam[] tps,
		immutable SpecInst*[] sps,
	) {
		docComment = dc;
		visibility = v;
		flags = f;
		sig = s;
		typeParams = small(tps);
		specs = sps;
		body_ = immutable FunBody(immutable FunBody.Builtin());
	}
	this(
		immutable SafeCStr dc,
		immutable Visibility v,
		immutable FunFlags f,
		immutable Sig s,
		immutable TypeParam[] tps,
		immutable SpecInst*[] sps,
		immutable FunBody b,
	) {
		docComment = dc;
		visibility = v;
		flags = f;
		sig = s;
		typeParams = small(tps);
		specs = sps;
		body_ = b;
	}

	immutable SafeCStr docComment;
	immutable Visibility visibility;
	immutable FunFlags flags;
	immutable Sig sig;
	immutable SmallArray!TypeParam typeParams;
	immutable SmallArray!(SpecInst*) specs;
	FunBody body_;

	immutable(FileAndPos) fileAndPos() immutable {
		return sig.fileAndPos;
	}

	immutable(FileAndRange) range() immutable {
		// TODO: end position
		return fileAndRangeFromFileAndPos(fileAndPos);
	}
}

immutable(Linkage) linkage(ref immutable FunDecl a) {
	return isExtern(a.body_) ? Linkage.extern_ : Linkage.internal;
}

immutable(bool) isExtern(ref immutable FunDecl a) {
	return a.body_.isExtern;
}

immutable(bool) noCtx(ref const FunDecl a) {
	return a.flags.noCtx;
}
immutable(bool) noDoc(ref immutable FunDecl a) {
	return a.flags.noDoc;
}
immutable(bool) summon(ref immutable FunDecl a) {
	return a.flags.summon;
}
immutable(bool) unsafe(ref immutable FunDecl a) {
	return a.flags.unsafe;
}
immutable(bool) trusted(ref immutable FunDecl a) {
	return a.flags.trusted;
}
immutable(bool) okIfUnused(ref immutable FunDecl a) {
	return a.flags.okIfUnused;
}

immutable(Sym) name(ref const FunDecl a) {
	return a.sig.name;
}

ref immutable(Type) returnType(return scope ref immutable FunDecl a) {
	return a.sig.returnType;
}

ref immutable(Params) params(return scope ref immutable FunDecl a) {
	return a.sig.params;
}

immutable(bool) isVariadic(ref immutable FunDecl a) {
	return matchParams!(immutable bool)(
		params(a),
		(immutable Param[]) => false,
		(ref immutable Params.Varargs) => true);
}

immutable(bool) isTemplate(ref immutable FunDecl a) {
	return !empty(a.typeParams) || !empty(a.specs);
}

immutable(Arity) arity(ref const FunDecl a) {
	return arity(a.sig);
}

struct Test {
	immutable Expr body_;
}

struct FunDeclAndArgs {
	@safe @nogc pure nothrow:

	immutable FunDecl* decl;
	immutable Type[] typeArgs;
	immutable Called[] specImpls;

	immutable(bool) opEquals(scope immutable FunDeclAndArgs b) scope immutable {
		return decl == b.decl &&
			arrEqual!Type(typeArgs, b.typeArgs, (ref immutable Type ta, ref immutable Type tb) =>
				ta == tb) &&
			arrEqual!Called(specImpls, b.specImpls, (ref immutable Called ca, ref immutable Called cb) =>
				ca == cb);
	}

	void hash(ref Hasher hasher) scope immutable {
		hashPtr(hasher, decl);
		foreach (immutable Type t; typeArgs)
			t.hash(hasher);
		foreach (ref immutable Called c; specImpls)
			c.hash(hasher);
	}
}

struct FunInst {
	immutable FunDeclAndArgs funDeclAndArgs;
	immutable Sig sig;
}

immutable(bool) isCallWithCtxFun(ref immutable FunInst a) {
	// TODO: only do this for the call-with-ctx in bootstrap
	return name(*decl(a)) == symForSpecial(SpecialSym.call_with_ctx);
}

immutable(bool) isCompareFun(ref immutable FunInst a) {
	// TODO: only do this for the '<=>' in bootstrap
	return name(*decl(a)) == symForOperator(Operator.compare);
}

immutable(bool) isMarkVisitFun(ref immutable FunInst a) {
	// TODO: only do this for the 'mark-visit' in bootstrap
	return name(*decl(a)) == shortSym("mark-visit");
}

immutable(FunInst*) nonTemplateFunInst(ref Alloc alloc, immutable FunDecl* decl) {
	return allocate(alloc, immutable FunInst(
		immutable FunDeclAndArgs(decl, emptyArr!Type, emptyArr!Called),
		decl.sig));
}

immutable(Sym) name(ref immutable FunInst a) {
	return a.sig.name;
}

ref immutable(Type) returnType(return scope ref immutable FunInst a) {
	return a.sig.returnType;
}

ref immutable(Params) params(return scope ref immutable FunInst a) {
	return a.sig.params;
}

immutable(FunDecl*) decl(ref immutable FunInst a) {
	return a.funDeclAndArgs.decl;
}

immutable(Type[]) typeArgs(ref immutable FunInst a) {
	return a.funDeclAndArgs.typeArgs;
}

immutable(Called[]) specImpls(ref immutable FunInst a) {
	return a.funDeclAndArgs.specImpls;
}

immutable(bool) noCtx(ref immutable FunInst a) {
	return noCtx(*decl(a));
}

immutable(Arity) arity(ref immutable FunInst a) {
	return arity(*decl(a));
}

struct SpecSig {
	@safe @nogc pure nothrow:

	immutable SpecInst* specInst;
	immutable SpecDeclSig* sig;
	immutable size_t indexOverAllSpecUses; // this is redundant to specInst and sig

	private:

	immutable(bool) opEquals(scope immutable SpecSig b) scope immutable {
		// Don't bother with indexOverAllSpecUses, it's redundant if we checked sig
		return specInst == b.specInst && sig == b.sig;
	}

	void hash(ref Hasher hasher) scope immutable {
		hashPtr(hasher, specInst);
		hashPtr(hasher, sig);
	}
}

immutable(Sym) name(ref immutable SpecSig a) {
	return a.sig.sig.name;
}

// Like 'Called', but we haven't fully instantiated yet. (This is used for Candidate when checking a call expr.)
struct CalledDecl {
	@safe @nogc pure nothrow:

	private:
	enum Kind {
		funDecl,
		specSig,
	}
	immutable Kind kind;
	union {
		immutable FunDecl* funDecl;
		immutable SpecSig specSig;
	}

	public:
	@trusted immutable this(immutable FunDecl* a) { kind = Kind.funDecl; funDecl = a; }
	@trusted immutable this(immutable SpecSig a) { kind = Kind.specSig; specSig = a; }
}

@trusted T matchCalledDecl(T, alias cbFunDecl, alias cbSpecSig)(ref immutable CalledDecl a) {
	final switch (a.kind) {
		case CalledDecl.Kind.funDecl:
			return cbFunDecl(a.funDecl);
		case CalledDecl.Kind.specSig:
			return cbSpecSig(a.specSig);
	}
}

@trusted ref immutable(Sig) sig(return scope ref immutable CalledDecl a) {
	final switch (a.kind) {
		case CalledDecl.Kind.funDecl:
			return a.funDecl.sig;
		case CalledDecl.Kind.specSig:
			return a.specSig.sig.sig;
	}
}

immutable(Sym) name(ref immutable CalledDecl a) {
	return a.sig.name;
}

ref immutable(Type) returnType(return scope ref immutable CalledDecl a) {
	return a.sig.returnType;
}

ref immutable(Params) params(return scope ref immutable CalledDecl a) {
	return a.sig.params;
}

immutable(TypeParam[]) typeParams(return scope ref immutable CalledDecl a) {
	return matchCalledDecl!(
		immutable TypeParam[],
		(immutable FunDecl* f) => f.typeParams,
		(ref immutable SpecSig) => emptyArr!TypeParam,
	)(a);
}

immutable(Arity) arity(ref immutable CalledDecl a) {
	return arity(params(a));
}

immutable(size_t) nTypeParams(ref immutable CalledDecl a) {
	return typeParams(a).length;
}

struct Called {
	@safe @nogc pure nothrow:

	private:
	enum Kind {
		funInst,
		specSig,
	}
	immutable Kind kind;
	union {
		immutable FunInst* funInst;
		immutable SpecSig specSig;
	}

	public:
	@trusted immutable this(immutable FunInst* a) { kind = Kind.funInst; funInst = a; }
	@trusted immutable this(immutable SpecSig a) { kind = Kind.specSig; specSig = a; }

	immutable(bool) opEquals(scope immutable Called b) scope immutable {
		return matchCalled!(
			immutable bool,
			(immutable FunInst* fa) =>
				matchCalled!(
					immutable bool,
					(immutable FunInst* fb) => fa == fb,
					(ref immutable SpecSig) => false,
				)(b),
			(ref immutable SpecSig sa) =>
				matchCalled!(
					immutable bool,
					(immutable FunInst*) => false,
					(ref immutable SpecSig sb) => sa == sb,
				)(b),
		)(this);
	}

	void hash(ref Hasher hasher) scope immutable {
		matchCalled!(
			void,
			(immutable FunInst* f) {
				hashPtr(hasher, f);
			},
			(ref immutable SpecSig s) {
				s.hash(hasher);
			},
		)(this);
	}
}

@trusted T matchCalled(T, alias cbFunInst, alias cbSpecSig)(ref immutable Called a) {
	final switch (a.kind) {
		case Called.Kind.funInst:
			return cbFunInst(a.funInst);
		case Called.Kind.specSig:
			return cbSpecSig(a.specSig);
	}
}

@trusted ref immutable(Sig) sig(return scope ref immutable Called a) {
	final switch (a.kind) {
		case Called.Kind.funInst:
			return a.funInst.sig;
		case Called.Kind.specSig:
			return a.specSig.sig.sig;
	}
}

immutable(Sym) name(ref immutable Called a) {
	return matchCalled!(
		immutable Sym,
		(immutable FunInst*) => a.name,
		(ref immutable SpecSig s) => a.name,
	)(a);
}

ref immutable(Type) returnType(return scope ref immutable Called a) {
	return sig(a).returnType;
}

ref immutable(Params) params(return scope ref immutable Called a) {
	return sig(a).params;
}

immutable(Arity) arity(ref immutable Called a) {
	return arity(sig(a));
}

struct StructOrAlias {
	@safe @nogc pure nothrow:
	private:
	enum Kind {
		alias_,
		structDecl,
	}
	immutable Kind kind;
	union {
		immutable StructAlias* alias_;
		immutable StructDecl* structDecl_;
	}

	public:
	@trusted immutable this(immutable StructAlias* a) {
		kind = Kind.alias_; alias_ = a; }
	@trusted immutable this(immutable StructDecl* a) {
		kind = Kind.structDecl; structDecl_ = a;
	}
}

@trusted immutable(StructDecl*) asStructDecl(immutable StructOrAlias a) {
	verify(a.kind == StructOrAlias.Kind.structDecl);
	return a.structDecl_;
}

@trusted immutable(T) matchStructOrAlias(T)(
	ref immutable StructOrAlias a,
	scope immutable(T) delegate(ref immutable StructAlias) @safe @nogc pure nothrow cbAlias,
	scope immutable(T) delegate(ref immutable StructDecl) @safe @nogc pure nothrow cbStructDecl,
) {
	final switch (a.kind) {
		case StructOrAlias.Kind.alias_:
			return cbAlias(*a.alias_);
		case StructOrAlias.Kind.structDecl:
			return cbStructDecl(*a.structDecl_);
	}
}

@trusted immutable(T) matchStructOrAliasPtr(T)(
	ref immutable StructOrAlias a,
	scope immutable(T) delegate(ref immutable StructAlias) @safe @nogc pure nothrow cbAlias,
	scope immutable(T) delegate(immutable StructDecl*) @safe @nogc pure nothrow cbStructDecl,
) {
	final switch (a.kind) {
		case StructOrAlias.Kind.alias_:
			return cbAlias(*a.alias_);
		case StructOrAlias.Kind.structDecl:
			return cbStructDecl(a.structDecl_);
	}
}

immutable(TypeParam[]) typeParams(ref immutable StructOrAlias a) {
	return matchStructOrAlias!(immutable TypeParam[])(
		a,
		(ref immutable StructAlias al) => al.typeParams.toArray(),
		(ref immutable StructDecl d) => d.typeParams.toArray());
}

immutable(FileAndRange) range(ref immutable StructOrAlias a) {
	return matchStructOrAlias!(immutable FileAndRange)(
		a,
		(ref immutable StructAlias al) => al.range,
		(ref immutable StructDecl d) => d.range);
}

immutable(Visibility) visibility(ref immutable StructOrAlias a) {
	return matchStructOrAlias!(immutable Visibility)(
		a,
		(ref immutable StructAlias al) => al.visibility,
		(ref immutable StructDecl d) => d.visibility);
}

immutable(Sym) name(ref immutable StructOrAlias a) {
	return matchStructOrAlias!(immutable Sym)(
		a,
		(ref immutable StructAlias al) => al.name,
		(ref immutable StructDecl d) => d.name);
}

struct Module {
	@safe @nogc pure nothrow:

	immutable FileIndex fileIndex;
	immutable SafeCStr docComment;
	immutable ImportOrExport[] imports; // includes import of std (if applicable)
	immutable ImportOrExport[] exports;
	immutable StructDecl[] structs;
	immutable SpecDecl[] specs;
	immutable FunDecl[] funs;
	immutable Test[] tests;
	// Includes re-exports
	immutable Dict!(Sym, NameReferents) allExportedNames;
}

struct ImportOrExport {
	@safe @nogc pure nothrow:

	// none for an automatic import of std
	immutable Opt!RangeWithinFile importSource;
	immutable ImportOrExportKind kind;
}

// No File option since those become FunDecls
struct ImportOrExportKind {
	@safe @nogc pure nothrow:

	struct ModuleWhole {
		@safe @nogc pure nothrow:
		immutable Module* modulePtr;

		ref immutable(Module) module_() return scope immutable {
			return *modulePtr;
		}
	}
	struct ModuleNamed {
		@safe @nogc pure nothrow:
		immutable Module* modulePtr;
		immutable Sym[] names;

		ref immutable(Module) module_() return scope immutable {
			return *modulePtr;
		}
	}

	immutable this(immutable ModuleWhole a) { kind = Kind.moduleWhole; moduleWhole = a; }
	immutable this(immutable ModuleNamed a) { kind = Kind.moduleNamed; moduleNamed = a; }

	private:
	enum Kind { moduleWhole, moduleNamed, }
	immutable Kind kind;
	union {
		immutable ModuleWhole moduleWhole;
		immutable ModuleNamed moduleNamed;
	}
}

@trusted immutable(T) matchImportOrExportKind(T)(
	ref immutable ImportOrExportKind a,
	scope immutable(T) delegate(immutable ImportOrExportKind.ModuleWhole) @safe @nogc pure nothrow cbModuleWhole,
	scope immutable(T) delegate(immutable ImportOrExportKind.ModuleNamed) @safe @nogc pure nothrow cbModuleNamed,
) {
	final switch (a.kind) {
		case ImportOrExportKind.Kind.moduleWhole:
			return cbModuleWhole(a.moduleWhole);
		case ImportOrExportKind.Kind.moduleNamed:
			return cbModuleNamed(a.moduleNamed);
	}
}

enum ImportFileType { nat8Array, str }

immutable(Sym) symOfImportFileType(immutable ImportFileType a) {
	final switch (a) {
		case ImportFileType.nat8Array:
			return shortSym("nat8Array");
		case ImportFileType.str:
			return shortSym("str");
	}
}

struct FileContent {
	@safe @nogc pure nothrow:

	immutable this(immutable ubyte[] a) { kind = Kind.nat8Array; nat8Array = a; }
	immutable this(immutable SafeCStr a) { kind = Kind.str; str = a; }

	private:
	enum Kind { nat8Array, str }
	immutable Kind kind;
	union {
		immutable ubyte[] nat8Array;
		immutable SafeCStr str;
	}
}

@trusted immutable(T) matchFileContent(T)(
	ref immutable FileContent a,
	scope immutable(T) delegate(immutable ubyte[]) @safe @nogc pure nothrow cbNat8Array,
	scope immutable(T) delegate(immutable SafeCStr) @safe @nogc pure nothrow cbStr,
) {
	final switch (a.kind) {
		case FileContent.Kind.nat8Array:
			return cbNat8Array(a.nat8Array);
		case FileContent.Kind.str:
			return cbStr(a.str);
	}
}

struct NameReferents {
	@safe @nogc pure nothrow:

	immutable Opt!StructOrAlias structOrAlias;
	immutable Opt!(SpecDecl*) spec;
	immutable FunDecl*[] funs;
}

enum FunKind {
	plain,
	mut,
	ref_,
}

struct FunKindAndStructs {
	immutable FunKind kind;
	immutable StructDecl*[5] structs;
}

struct CommonTypes {
	@safe @nogc pure nothrow:

	immutable StructInst* bool_;
	immutable StructInst* char8;
	immutable StructInst* cStr;
	immutable StructInst* float32;
	immutable StructInst* float64;
	immutable IntegralTypes integrals;
	immutable StructInst* sym;
	immutable StructInst* void_;
	immutable StructInst* ctx;
	immutable StructDecl* byVal;
	immutable StructDecl* arr;
	immutable StructDecl* fut;
	immutable StructDecl* namedVal;
	immutable StructDecl* opt;
	immutable StructDecl*[10] funPtrStructs; // Indexed by arity
	immutable FunKindAndStructs[3] funKindsAndStructs;
}

struct IntegralTypes {
	immutable StructInst* int8;
	immutable StructInst* int16;
	immutable StructInst* int32;
	immutable StructInst* int64;
	immutable StructInst* nat8;
	immutable StructInst* nat16;
	immutable StructInst* nat32;
	immutable StructInst* nat64;
}

enum EnumBackingType {
	int8,
	int16,
	int32,
	int64,
	nat8,
	nat16,
	nat32,
	nat64,
}

struct Program {
	immutable FilesInfo filesInfo;
	immutable Config config;
	immutable SpecialModules specialModules;
	immutable Module[] allModules;
	immutable CommonTypes commonTypes;
	immutable Diagnostics diagnostics;
}

struct Config {
	immutable ConfigImportPaths include;
	immutable ConfigExternPaths extern_;
}

alias ConfigImportPaths = immutable Dict!(Sym, Path);
alias ConfigExternPaths = immutable Dict!(Sym, Path);

immutable(bool) hasDiags(ref immutable Program a) {
	return !empty(a.diagnostics.diags);
}

struct SpecialModules {
	immutable Module* allocModule;
	immutable Module* bootstrapModule;
	immutable Module* runtimeModule;
	immutable Module* runtimeMainModule;
	immutable Module*[] rootModules;
}

struct Local {
	//TODO: use NameAndRange (more compact)
	immutable FileAndRange range;
	immutable Sym name;
	immutable LocalMutability mutability;
	immutable Type type;
}

enum LocalMutability { immut, mut }

struct VariableRef {
	@safe @nogc pure nothrow:
	@trusted immutable this(immutable Param* a) {
		inner = immutable TaggedPtr!Kind(Kind.param, a);
	}
	@trusted immutable this(immutable Local* a) {
		inner = immutable TaggedPtr!Kind(Kind.local, a);
	}
	@trusted immutable this(immutable Expr.ClosureFieldRef a) {
		inner = immutable TaggedPtr!Kind(Kind.closure, a.lambdaAndIndex);
	}

	private:
	enum Kind { param, local, closure }
	immutable TaggedPtr!Kind inner;
}
static assert(VariableRef.sizeof == 8);

@trusted immutable(T) matchVariableRef(T)(
	immutable VariableRef a,
	scope immutable(T) delegate(immutable Param*) @safe @nogc pure nothrow cbParam,
	scope immutable(T) delegate(immutable Local*) @safe @nogc pure nothrow cbLocal,
	scope immutable(T) delegate(immutable Expr.ClosureFieldRef) @safe @nogc pure nothrow cbClosure,
) {
	final switch (a.inner.tag()) {
		case VariableRef.Kind.param:
			return cbParam(a.inner.asPtr!Param);
		case VariableRef.Kind.local:
			return cbLocal(a.inner.asPtr!Local);
		case VariableRef.Kind.closure:
			return cbClosure(immutable Expr.ClosureFieldRef(a.inner.asPtrAndSmallNumber!(Expr.Lambda)()));
	}
}

immutable(Sym) debugName(immutable VariableRef a) {
	return matchVariableRef!(immutable Sym)(
		a,
		(immutable Param* x) =>
			force(x.name),
		(immutable Local* x) =>
			x.name,
		(immutable Expr.ClosureFieldRef x) =>
			debugName(x.variableRef()));
}

immutable(Type) variableRefType(immutable VariableRef a) {
	return matchVariableRef!(immutable Type)(
		a,
		(immutable Param* x) =>
			x.type,
		(immutable Local* x) =>
			x.type,
		(immutable Expr.ClosureFieldRef x) =>
			variableRefType(x.variableRef()));
}

struct Expr {
	@safe @nogc pure nothrow:
	struct Bogus {}

	struct Call {
		immutable Called called;
		immutable Expr[] args;
	}

	struct ClosureFieldRef {
		@safe @nogc pure nothrow:

		immutable PtrAndSmallNumber!Lambda lambdaAndIndex;

		immutable(Expr.Lambda*) lambda() immutable {
			return lambdaAndIndex.ptr;
		}

		immutable(ushort) index() immutable {
			return lambdaAndIndex.number;
		}

		immutable(VariableRef) variableRef() immutable {
			return lambda.closure[index];
		}
	}

	struct Cond {
		immutable Type type;
		immutable Expr cond;
		immutable Expr then;
		immutable Expr else_;
	}

	struct Drop {
		immutable Expr arg;
	}

	struct FunPtr {
		immutable FunInst* funInst;
		immutable StructInst* structInst;
	}

	struct IfOption {
		immutable Type type;
		immutable Expr option;
		immutable Local* local;
		immutable Expr then;
		immutable Expr else_;
	}

	// type is the lambda's type (not the body's return type), e.g. a Fun1 or sendFun1 instance.
	struct Lambda {
		immutable Param[] params;
		immutable Expr body_;
		immutable VariableRef[] closure;
		// This is the funN type;
		immutable StructInst* type;
		immutable FunKind kind;
		// For FunKind.send this includes 'fut' wrapper
		immutable Type returnType;
	}

	struct Let {
		immutable Local* local;
		immutable Expr value;
		immutable Expr then;
	}

	struct Literal {
		immutable StructInst* structInst;
		immutable Constant value;
	}

	struct LiteralCString {
		immutable SafeCStr value;
	}

	struct LiteralSymbol {
		immutable Sym value;
	}

	struct LocalRef {
		immutable Local* local;
	}

	struct LocalSet {
		immutable Local* local;
		immutable Expr value;
	}

	struct Loop {
		immutable Type type;
		immutable Expr body_;
	}

	struct LoopBreak {
		immutable Loop* loop;
		immutable Expr value;
	}

	struct LoopContinue {
		immutable Loop* loop;
	}

	struct MatchEnum {
		immutable Expr matched;
		immutable Expr[] cases;
		immutable Type type;
	}

	struct MatchUnion {
		struct Case {
			immutable Opt!(Local*) local;
			immutable Expr then;
		}

		immutable Expr matched;
		immutable StructInst* matchedUnion;
		immutable Case[] cases;
		immutable Type type;
	}

	struct ParamRef {
		immutable Param* param;
	}

	struct Seq {
		immutable Expr first;
		immutable Expr then;
	}

	private:
	enum Kind {
		bogus,
		call,
		closureFieldRef,
		cond,
		drop,
		funPtr,
		ifOption,
		lambda,
		let,
		literal,
		literalCString,
		literalSymbol,
		localRef,
		localSet,
		loop,
		loopBreak,
		loopContinue,
		matchEnum,
		matchUnion,
		paramRef,
		seq,
	}

	immutable FileAndRange range_;
	immutable Kind kind;
	union {
		immutable Bogus bogus;
		immutable Call call;
		immutable ClosureFieldRef closureFieldRef;
		immutable Cond* cond;
		immutable Drop* drop;
		immutable FunPtr funPtr;
		immutable IfOption* ifOption;
		immutable Lambda* lambda;
		immutable Let* let;
		immutable Literal* literal;
		immutable LiteralCString literalCString;
		immutable LiteralSymbol literalSymbol;
		immutable LocalRef localRef;
		immutable LocalSet* localSet;
		immutable Loop* loop;
		immutable LoopBreak* loopBreak;
		immutable LoopContinue* loopContinue;
		immutable MatchEnum* matchEnum;
		immutable MatchUnion* matchUnion;
		immutable ParamRef paramRef;
		immutable Seq* seq;
	}

	public:
	immutable this(immutable FileAndRange r, immutable Bogus a) { range_ = r; kind = Kind.bogus; bogus = a; }
	@trusted immutable this(immutable FileAndRange r, immutable Call a) { range_ = r; kind = Kind.call; call = a; }
	@trusted immutable this(immutable FileAndRange r, immutable ClosureFieldRef a) {
		range_ = r; kind = Kind.closureFieldRef; closureFieldRef = a;
	}
	@trusted immutable this(immutable FileAndRange r, immutable Cond* a) { range_ = r; kind = Kind.cond; cond = a; }
	@trusted immutable this(immutable FileAndRange r, immutable Drop* a) { range_ = r; kind = Kind.drop; drop = a; }
	@trusted immutable this(immutable FileAndRange r, immutable FunPtr a) {
		range_ = r; kind = Kind.funPtr; funPtr = a;
	}
	@trusted immutable this(immutable FileAndRange r, immutable IfOption* a) {
		range_ = r; kind = Kind.ifOption; ifOption = a;
	}
	@trusted immutable this(immutable FileAndRange r, immutable Lambda* a) {
		range_ = r; kind = Kind.lambda; lambda = a;
	}
	@trusted immutable this(immutable FileAndRange r, immutable Let* a) { range_ = r; kind = Kind.let; let = a; }
	@trusted immutable this(immutable FileAndRange r, immutable Literal* a) {
		range_ = r; kind = Kind.literal; literal = a;
	}
	@trusted immutable this(immutable FileAndRange r, immutable LiteralCString a) {
		range_ = r; kind = Kind.literalCString; literalCString = a;
	}
	@trusted immutable this(immutable FileAndRange r, immutable LiteralSymbol a) {
		range_ = r; kind = Kind.literalSymbol; literalSymbol = a;
	}
	@trusted immutable this(immutable FileAndRange r, immutable LocalRef a) {
		range_ = r; kind = Kind.localRef; localRef = a;
	}
	@trusted immutable this(immutable FileAndRange r, immutable LocalSet* a) {
		range_ = r; kind = Kind.localSet; localSet = a;
	}
	immutable this(immutable FileAndRange r, immutable Loop* a) {
		range_ = r; kind = Kind.loop; loop = a;
	}
	immutable this(immutable FileAndRange r, immutable LoopBreak* a) {
		range_ = r; kind = Kind.loopBreak; loopBreak = a;
	}
	immutable this(immutable FileAndRange r, immutable LoopContinue* a) {
		range_ = r; kind = Kind.loopContinue; loopContinue = a;
	}
	@trusted immutable this(immutable FileAndRange r, immutable MatchEnum* a) {
		range_ = r; kind = Kind.matchEnum; matchEnum = a;
	}
	@trusted immutable this(immutable FileAndRange r, immutable MatchUnion* a) {
		range_ = r; kind = Kind.matchUnion; matchUnion = a;
	}
	@trusted immutable this(immutable FileAndRange r, immutable ParamRef a) {
		range_ = r; kind = Kind.paramRef; paramRef = a;
	}
	@trusted immutable this(immutable FileAndRange r, immutable Seq* a) { range_ = r; kind = Kind.seq; seq = a; }
}

immutable(FileAndRange) range(scope ref immutable Expr a) {
	return a.range_;
}

@trusted immutable(T) matchExpr(T)(
	ref immutable Expr a,
	scope immutable(T) delegate(ref immutable Expr.Bogus) @safe @nogc pure nothrow cbBogus,
	scope immutable(T) delegate(ref immutable Expr.Call) @safe @nogc pure nothrow cbCall,
	scope immutable(T) delegate(ref immutable Expr.ClosureFieldRef) @safe @nogc pure nothrow cbClosureFieldRef,
	scope immutable(T) delegate(ref immutable Expr.Cond) @safe @nogc pure nothrow cbCond,
	scope immutable(T) delegate(ref immutable Expr.Drop) @safe @nogc pure nothrow cbDrop,
	scope immutable(T) delegate(ref immutable Expr.FunPtr) @safe @nogc pure nothrow cbFunPtr,
	scope immutable(T) delegate(ref immutable Expr.IfOption) @safe @nogc pure nothrow cbIfOption,
	scope immutable(T) delegate(ref immutable Expr.Lambda) @safe @nogc pure nothrow cbLambda,
	scope immutable(T) delegate(ref immutable Expr.Let) @safe @nogc pure nothrow cbLet,
	scope immutable(T) delegate(ref immutable Expr.Literal) @safe @nogc pure nothrow cbLiteral,
	scope immutable(T) delegate(ref immutable Expr.LiteralCString) @safe @nogc pure nothrow cbLiteralCString,
	scope immutable(T) delegate(ref immutable Expr.LiteralSymbol) @safe @nogc pure nothrow cbLiteralSymbol,
	scope immutable(T) delegate(ref immutable Expr.LocalRef) @safe @nogc pure nothrow cbLocalRef,
	scope immutable(T) delegate(ref immutable Expr.LocalSet) @safe @nogc pure nothrow cbLocalSet,
	scope immutable(T) delegate(ref immutable Expr.Loop) @safe @nogc pure nothrow cbLoop,
	scope immutable(T) delegate(ref immutable Expr.LoopBreak) @safe @nogc pure nothrow cbLoopBreak,
	scope immutable(T) delegate(ref immutable Expr.LoopContinue) @safe @nogc pure nothrow cbLoopContinue,
	scope immutable(T) delegate(ref immutable Expr.MatchEnum) @safe @nogc pure nothrow cbMatchEnum,
	scope immutable(T) delegate(ref immutable Expr.MatchUnion) @safe @nogc pure nothrow cbMatchUnion,
	scope immutable(T) delegate(ref immutable Expr.ParamRef) @safe @nogc pure nothrow cbParamRef,
	scope immutable(T) delegate(ref immutable Expr.Seq) @safe @nogc pure nothrow cbSeq,
) {
	final switch (a.kind) {
		case Expr.Kind.bogus:
			return cbBogus(a.bogus);
		case Expr.Kind.call:
			return cbCall(a.call);
		case Expr.Kind.closureFieldRef:
			return cbClosureFieldRef(a.closureFieldRef);
		case Expr.Kind.cond:
			return cbCond(*a.cond);
		case Expr.Kind.drop:
			return cbDrop(*a.drop);
		case Expr.Kind.funPtr:
			return cbFunPtr(a.funPtr);
		case Expr.Kind.ifOption:
			return cbIfOption(*a.ifOption);
		case Expr.Kind.lambda:
			return cbLambda(*a.lambda);
		case Expr.Kind.let:
			return cbLet(*a.let);
		case Expr.Kind.literal:
			return cbLiteral(*a.literal);
		case Expr.Kind.literalCString:
			return cbLiteralCString(a.literalCString);
		case Expr.Kind.literalSymbol:
			return cbLiteralSymbol(a.literalSymbol);
		case Expr.Kind.localRef:
			return cbLocalRef(a.localRef);
		case Expr.Kind.localSet:
			return cbLocalSet(*a.localSet);
		case Expr.Kind.loop:
			return cbLoop(*a.loop);
		case Expr.Kind.loopBreak:
			return cbLoopBreak(*a.loopBreak);
		case Expr.Kind.loopContinue:
			return cbLoopContinue(*a.loopContinue);
		case Expr.Kind.matchEnum:
			return cbMatchEnum(*a.matchEnum);
		case Expr.Kind.matchUnion:
			return cbMatchUnion(*a.matchUnion);
		case Expr.Kind.paramRef:
			return cbParamRef(a.paramRef);
		case Expr.Kind.seq:
			return cbSeq(*a.seq);
	}
}

void writeStructDecl(ref Writer writer, ref const AllSymbols allSymbols, ref immutable StructDecl a) {
	writeSym(writer, allSymbols, a.name);
}

void writeStructInst(ref Writer writer, ref const AllSymbols allSymbols, ref immutable StructInst s) {
	writeStructDecl(writer, allSymbols, *decl(s));
	if (!empty(s.typeArgs)) {
		writeChar(writer, '<');
		writeWithCommas!Type(writer, s.typeArgs, (ref immutable Type t) {
			writeTypeUnquoted(writer, allSymbols, t);
		});
		writeChar(writer, '>');
	}
}

void writeTypeQuoted(ref Writer writer, ref const AllSymbols allSymbols, immutable Type a) {
	writeChar(writer, '\'');
	writeTypeUnquoted(writer, allSymbols, a);
	writeChar(writer, '\'');
}

//TODO:MOVE
void writeTypeUnquoted(ref Writer writer, ref const AllSymbols allSymbols, immutable Type a) {
	matchType!void(
		a,
		(immutable Type.Bogus) {
			writeStatic(writer, "<<bogus>>");
		},
		(immutable TypeParam* p) {
			writeSym(writer, allSymbols, p.name);
		},
		(immutable StructInst* s) {
			writeStructInst(writer, allSymbols, *s);
		});
}

enum Visibility : ubyte {
	public_,
	private_,
}

immutable(Sym) symOfVisibility(immutable Visibility a) {
	final switch (a) {
		case Visibility.public_:
			return shortSym("public");
		case Visibility.private_:
			return shortSym("private");
	}
}

immutable(Visibility) leastVisibility(immutable Visibility a, immutable Visibility b) {
	final switch (a) {
		case Visibility.public_:
			return b;
		case Visibility.private_:
			return Visibility.private_;
	}
}
