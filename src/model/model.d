module model.model;

@safe @nogc pure nothrow:

import model.constant : Constant;
import model.diag : Diagnostics, FilesInfo; // TODO: move FilesInfo here?
import util.alloc.alloc : Alloc;
import util.col.arr : empty, emptyArr, only, small, SmallArray;
import util.col.arrUtil : arrEqual;
import util.col.dict : SymDict;
import util.col.fullIndexDict : FullIndexDict;
import util.col.mutArr : MutArr;
import util.col.str : copySafeCStr, SafeCStr;
import util.hash : Hasher;
import util.late : Late, lateGet, lateIsSet, lateSet;
import util.lineAndColumnGetter : LineAndColumnGetter;
import util.memory : allocate;
import util.opt : force, has, Opt, some;
import util.path : AbsolutePath, PathAndStorageKind, StorageKind;
import util.ptr : hashPtr, Ptr, ptrEquals, TaggedPtr;
import util.sourceRange :
	FileAndPos,
	FileAndRange,
	fileAndRangeFromFileAndPos,
	FileIndex,
	rangeOfStartAndName,
	RangeWithinFile;
import util.sym :
	AllSymbols,
	Operator,
	shortSym,
	SpecialSym,
	Sym,
	symEq,
	symForOperator,
	symForSpecial,
	writeSym;
import util.util : max, min, todo, unreachable, verify;
import util.writer : writeChar, Writer, writeStatic, writeWithCommas;

struct AbsolutePathsGetter {
	immutable SafeCStr cwd;
	immutable SafeCStr globalPath;
	immutable SafeCStr localPath;
}
immutable(AbsolutePathsGetter) copyAbsolutePathsGetter(ref Alloc alloc, scope ref immutable AbsolutePathsGetter a) {
	return immutable AbsolutePathsGetter(
		copySafeCStr(alloc, a.cwd),
		copySafeCStr(alloc, a.globalPath),
		copySafeCStr(alloc, a.localPath));
}

private immutable(SafeCStr) getBasePath(return scope ref immutable AbsolutePathsGetter a, immutable StorageKind sk) {
	final switch (sk) {
		case StorageKind.global:
			return a.globalPath;
		case StorageKind.local:
			return a.localPath;
	}
}

immutable(AbsolutePath) getAbsolutePath(
	return scope ref immutable AbsolutePathsGetter a,
	immutable PathAndStorageKind p,
	immutable SafeCStr extension,
) {
	return immutable AbsolutePath(getBasePath(a, p.storageKind), p.path, extension);
}

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
	enum Kind {
		bogus,
		typeParam,
		structInst,
	}
	@trusted immutable this(immutable Bogus a) {
		inner = TaggedPtr!Kind(Kind.bogus, null);
	}
	@trusted immutable this(immutable Ptr!TypeParam a) {
		inner = TaggedPtr!Kind(Kind.typeParam, a.rawPtr());
	}
	@trusted immutable this(immutable Ptr!StructInst a) {
		inner = TaggedPtr!Kind(Kind.structInst, a.rawPtr());
	}

	private:
	TaggedPtr!Kind inner;
}

@trusted immutable(T) matchType(T)(
	immutable Type a,
	scope immutable(T) delegate(immutable Type.Bogus) @safe @nogc pure nothrow cbBogus,
	scope immutable(T) delegate(immutable Ptr!TypeParam) @safe @nogc pure nothrow cbTypeParam,
	scope immutable(T) delegate(immutable Ptr!StructInst) @safe @nogc pure nothrow cbStructInst
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
		(immutable Ptr!TypeParam) => false,
		(immutable Ptr!StructInst) => false);
}
immutable(bool) isTypeParam(immutable Type a) {
	return matchType!(immutable bool)(
		a,
		(immutable Type.Bogus) => false,
		(immutable Ptr!TypeParam) => true,
		(immutable Ptr!StructInst) => false);
}
@trusted immutable(Ptr!TypeParam) asTypeParam(immutable Type a) {
	return matchType!(immutable Ptr!TypeParam)(
		a,
		(immutable Type.Bogus) => unreachable!(immutable Ptr!TypeParam),
		(immutable Ptr!TypeParam it) => it,
		(immutable Ptr!StructInst) => unreachable!(immutable Ptr!TypeParam));
}
immutable(bool) isStructInst(immutable Type a) {
	return matchType!(immutable bool)(
		a,
		(immutable Type.Bogus) => false,
		(immutable Ptr!TypeParam) => false,
		(immutable Ptr!StructInst) => true);
}
@trusted immutable(Ptr!StructInst) asStructInst(immutable Type a) {
	return matchType!(immutable Ptr!StructInst)(
		a,
		(immutable Type.Bogus) => unreachable!(immutable Ptr!StructInst),
		(immutable Ptr!TypeParam) => unreachable!(immutable Ptr!StructInst),
		(immutable Ptr!StructInst it) => it);
}

immutable(PurityRange) purityRange(immutable Type a) {
	return matchType!(immutable PurityRange)(
		a,
		(immutable Type.Bogus) =>
			immutable PurityRange(Purity.data, Purity.data),
		(immutable Ptr!TypeParam) =>
			immutable PurityRange(Purity.data, Purity.mut),
		(immutable Ptr!StructInst i) =>
			i.deref().purityRange);
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
		(immutable Ptr!TypeParam) =>
			immutable LinkageRange(Linkage.internal, Linkage.extern_),
		(immutable Ptr!StructInst i) =>
			i.deref().linkageRange);
}

//TODO:MOVE?
immutable(bool) typeEquals(immutable Type a, immutable Type b) {
	return matchType!(immutable bool)(
		a,
		(immutable Type.Bogus) =>
			isBogus(b),
		(immutable Ptr!TypeParam p) =>
			isTypeParam(b) && ptrEquals(p, asTypeParam(b)),
		(immutable Ptr!StructInst i) =>
			isStructInst(b) && ptrEquals(i, asStructInst(b)));
}

private void hashType(ref Hasher hasher, immutable Type a) {
	matchType!void(
		a,
		(immutable Type.Bogus) {},
		(immutable Ptr!TypeParam p) =>
			hashPtr(hasher, p),
		(immutable Ptr!StructInst i) =>
			hashPtr(hasher, i));
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
	@trusted immutable this(immutable Ptr!Varargs a) {
		inner = immutable TaggedPtr!Kind(Kind.varargs, a.rawPtr());
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
			return cbVarargs(a.inner.asPtr!(Params.Varargs)().deref());
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
immutable(bool) isRecord(ref const StructBody a) {
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
	Late!(immutable Opt!(Ptr!StructInst)) target_;
}

immutable(Opt!(Ptr!StructInst)) target(ref immutable StructAlias a) {
	return lateGet(a.target_);
}
void setTarget(ref StructAlias a, immutable Opt!(Ptr!StructInst) value) {
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
	immutable Ptr!StructDecl decl;
	immutable Type[] typeArgs;
}

immutable(bool) structDeclAndArgsEqual(
	scope ref immutable StructDeclAndArgs a,
	scope ref immutable StructDeclAndArgs b,
) {
	return ptrEquals(a.decl, b.decl) &&
		arrEqual!(immutable Type)(a.typeArgs, b.typeArgs, (ref immutable Type ta, ref immutable Type tb) =>
			typeEquals(ta, tb));
}

void hashStructDeclAndArgs(ref Hasher hasher, scope ref immutable StructDeclAndArgs a) {
	hashPtr(hasher, a.decl);
	foreach (immutable Type t; a.typeArgs)
		hashType(hasher, t);
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
	return symEq(decl(i).deref().name, shortSym("arr"));
}

immutable(Sym) name(ref immutable StructInst i) {
	return decl(i).deref().name;
}

const(Ptr!StructDecl) decl(ref const StructInst i) {
	return i.declAndArgs.decl;
}
immutable(Ptr!StructDecl) decl(ref immutable StructInst i) {
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
	MutArr!(immutable Ptr!SpecInst) insts;
}

struct SpecDeclAndArgs {
	immutable Ptr!SpecDecl decl;
	immutable Type[] typeArgs;
}

immutable(bool) specDeclAndArgsEqual(ref immutable SpecDeclAndArgs a, ref immutable SpecDeclAndArgs b) {
	return ptrEquals(a.decl, b.decl) &&
		arrEqual!(immutable Type)(a.typeArgs, b.typeArgs, (ref immutable Type ta, ref immutable Type tb) =>
			typeEquals(ta, tb));
}

void hashSpecDeclAndArgs(ref Hasher hasher, ref immutable SpecDeclAndArgs a) {
	hashPtr(hasher, a.decl);
	foreach (immutable Type t; a.typeArgs)
		hashType(hasher, t);
}

struct SpecInst {
	immutable SpecDeclAndArgs declAndArgs;
	immutable SpecBody body_;
}

immutable(Ptr!SpecDecl) decl(ref immutable SpecInst a) {
	return a.declAndArgs.decl;
}

immutable(Type[]) typeArgs(return scope ref immutable SpecInst a) {
	return a.declAndArgs.typeArgs;
}

immutable(Sym) name(ref immutable SpecInst a) {
	return decl(a).deref().name;
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
		immutable Opt!Sym libraryName;
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
		immutable Ptr!SpecInst[] sps,
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
		immutable Ptr!SpecInst[] sps,
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
	immutable SmallArray!(Ptr!SpecInst) specs;
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

	immutable Ptr!FunDecl decl;
	immutable Type[] typeArgs;
	immutable Called[] specImpls;
}

immutable(bool) funDeclAndArgsEqual(ref immutable FunDeclAndArgs a, ref immutable FunDeclAndArgs b) {
	return ptrEquals(a.decl, b.decl) &&
		arrEqual!Type(a.typeArgs, b.typeArgs, (ref immutable Type ta, ref immutable Type tb) =>
			typeEquals(ta, tb)) &&
		arrEqual!Called(a.specImpls, b.specImpls, (ref immutable Called ca, ref immutable Called cb) =>
			calledEquals(ca, cb));
}

void hashFunDeclAndArgs(ref Hasher hasher, ref immutable FunDeclAndArgs a) {
	hashPtr(hasher, a.decl);
	foreach (immutable Type t; a.typeArgs)
		hashType(hasher, t);
	foreach (ref immutable Called c; a.specImpls)
		hashCalled(hasher, c);
}

struct FunInst {
	immutable FunDeclAndArgs funDeclAndArgs;
	immutable Sig sig;
}

immutable(bool) isCallWithCtxFun(ref immutable FunInst a) {
	// TODO: only do this for the call-with-ctx in bootstrap
	return symEq(name(decl(a).deref()), symForSpecial(SpecialSym.call_with_ctx));
}

immutable(bool) isCompareFun(ref immutable FunInst a) {
	// TODO: only do this for the '<=>' in bootstrap
	return symEq(name(decl(a).deref()), symForOperator(Operator.compare));
}

immutable(bool) isMarkVisitFun(ref immutable FunInst a) {
	// TODO: only do this for the 'mark-visit' in bootstrap
	return symEq(name(decl(a).deref()), shortSym("mark-visit"));
}

immutable(Ptr!FunInst) nonTemplateFunInst(ref Alloc alloc, immutable Ptr!FunDecl decl) {
	return allocate(alloc, immutable FunInst(
		immutable FunDeclAndArgs(decl, emptyArr!Type, emptyArr!Called),
		decl.deref().sig));
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

immutable(Ptr!FunDecl) decl(ref immutable FunInst a) {
	return a.funDeclAndArgs.decl;
}

immutable(Type[]) typeArgs(ref immutable FunInst a) {
	return a.funDeclAndArgs.typeArgs;
}

immutable(Called[]) specImpls(ref immutable FunInst a) {
	return a.funDeclAndArgs.specImpls;
}

immutable(bool) noCtx(ref immutable FunInst a) {
	return decl(a).deref.noCtx;
}

immutable(Arity) arity(ref immutable FunInst a) {
	return arity(decl(a).deref);
}

struct SpecSig {
	immutable Ptr!SpecInst specInst;
	immutable Ptr!SpecDeclSig sig;
	immutable size_t indexOverAllSpecUses; // this is redundant to specInst and sig
}

private immutable(bool) specSigEquals(ref immutable SpecSig a, ref immutable SpecSig b) {
	// Don't bother with indexOverAllSpecUses, it's redundant if we checked sig
	return ptrEquals(a.specInst, b.specInst) && ptrEquals(a.sig, b.sig);
}

private void hashSpecSig(ref Hasher hasher, ref immutable SpecSig a) {
	hashPtr(hasher, a.specInst);
	hashPtr(hasher, a.sig);
}

immutable(Sym) name(ref immutable SpecSig a) {
	return a.sig.deref().sig.name;
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
		immutable Ptr!FunDecl funDecl;
		immutable SpecSig specSig;
	}

	public:
	@trusted immutable this(immutable Ptr!FunDecl a) { kind = Kind.funDecl; funDecl = a; }
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
			return a.funDecl.deref().sig;
		case CalledDecl.Kind.specSig:
			return a.specSig.sig.deref().sig;
	}
	//TODO: match can't return ref?
	//return a.match(
	//	(immutable Ptr!FunDecl f) => f.sig,
	//	(ref immutable SpecSig s) => s.sig.deref,
	//);
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
		(immutable Ptr!FunDecl f) => f.deref().typeParams,
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
		immutable Ptr!FunInst funInst;
		immutable SpecSig specSig;
	}

	public:
	@trusted immutable this(immutable Ptr!FunInst a) { kind = Kind.funInst; funInst = a; }
	@trusted immutable this(immutable SpecSig a) { kind = Kind.specSig; specSig = a; }
}

@trusted T matchCalled(T, alias cbFunInst, alias cbSpecSig)(ref immutable Called a) {
	final switch (a.kind) {
		case Called.Kind.funInst:
			return cbFunInst(a.funInst);
		case Called.Kind.specSig:
			return cbSpecSig(a.specSig);
	}
}

private immutable(bool) calledEquals(ref immutable Called a, ref immutable Called b) {
	return matchCalled!(
		immutable bool,
		(immutable Ptr!FunInst fa) =>
			matchCalled!(
				immutable bool,
				(immutable Ptr!FunInst fb) => ptrEquals(fa, fb),
				(ref immutable SpecSig) => false,
			)(b),
		(ref immutable SpecSig sa) =>
			matchCalled!(
				immutable bool,
				(immutable Ptr!FunInst) => false,
				(ref immutable SpecSig sb) => specSigEquals(sa, sb),
			)(b),
	)(a);
}

private void hashCalled(ref Hasher hasher, ref immutable Called a) {
	matchCalled!(
		void,
		(immutable Ptr!FunInst f) {
			hashPtr(hasher, f);
		},
		(ref immutable SpecSig sa) {
			hashSpecSig(hasher, sa);
		},
	)(a);
}

@trusted ref immutable(Sig) sig(return scope ref immutable Called a) {
	final switch (a.kind) {
		case Called.Kind.funInst:
			return a.funInst.deref().sig;
		case Called.Kind.specSig:
			return a.specSig.sig.deref().sig;
	}
	//TODO: match can't return ref?
	//return a.match(
	//	(immutable Ptr!FunInst f) => f.sig,
	//	(ref immutable SpecSig s) => s.sig.deref,
	//);
}

immutable(Sym) name(ref immutable Called a) {
	return matchCalled!(
		immutable Sym,
		(immutable Ptr!FunInst) => a.name,
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
		immutable Ptr!StructAlias alias_;
		immutable Ptr!StructDecl structDecl_;
	}

	public:
	@trusted immutable this(immutable Ptr!StructAlias a) {
		kind = Kind.alias_; alias_ = a; }
	@trusted immutable this(immutable Ptr!StructDecl a) {
		kind = Kind.structDecl; structDecl_ = a;
	}
}

@trusted immutable(Ptr!StructDecl) asStructDecl(immutable StructOrAlias a) {
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
			return cbAlias(a.alias_.deref());
		case StructOrAlias.Kind.structDecl:
			return cbStructDecl(a.structDecl_.deref());
	}
}

@trusted immutable(T) matchStructOrAliasPtr(T)(
	ref immutable StructOrAlias a,
	scope immutable(T) delegate(ref immutable StructAlias) @safe @nogc pure nothrow cbAlias,
	scope immutable(T) delegate(immutable Ptr!StructDecl) @safe @nogc pure nothrow cbStructDecl,
) {
	final switch (a.kind) {
		case StructOrAlias.Kind.alias_:
			return cbAlias(a.alias_.deref());
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
	immutable ModuleAndNames[] imports; // includes import of std (if applicable)
	immutable ModuleAndNames[] exports;
	immutable StructDecl[] structs;
	immutable SpecDecl[] specs;
	immutable FunDecl[] funs;
	immutable Test[] tests;
	// Includes re-exports
	immutable SymDict!NameReferents allExportedNames;
}

struct ModuleAndNames {
	@safe @nogc pure nothrow:

	// none for an automatic import of std
	immutable Opt!RangeWithinFile importSource;
	immutable Ptr!Module modulePtr;
	immutable Opt!(Sym[]) names;

	ref immutable(Module) module_() return scope immutable {
		return modulePtr.deref();
	}
}

struct NameReferents {
	@safe @nogc pure nothrow:

	immutable Opt!StructOrAlias structOrAlias;
	immutable Opt!(Ptr!SpecDecl) spec;
	immutable Ptr!FunDecl[] funs;
}

enum FunKind {
	plain,
	mut,
	ref_,
}

struct FunKindAndStructs {
	immutable FunKind kind;
	immutable Ptr!StructDecl[5] structs;
}

struct CommonTypes {
	@safe @nogc pure nothrow:

	immutable Ptr!StructInst bool_;
	immutable Ptr!StructInst char8;
	immutable Ptr!StructInst cStr;
	immutable Ptr!StructInst float32;
	immutable Ptr!StructInst float64;
	immutable IntegralTypes integrals;
	immutable Ptr!StructInst sym;
	immutable Ptr!StructInst void_;
	immutable Ptr!StructInst ctx;
	immutable Ptr!StructDecl byVal;
	immutable Ptr!StructDecl arr;
	immutable Ptr!StructDecl fut;
	immutable Ptr!StructDecl namedVal;
	immutable Ptr!StructDecl opt;
	immutable Ptr!StructDecl[7] funPtrStructs; // Indexed by arity
	immutable FunKindAndStructs[3] funKindsAndStructs;
}

struct IntegralTypes {
	immutable Ptr!StructInst int8;
	immutable Ptr!StructInst int16;
	immutable Ptr!StructInst int32;
	immutable Ptr!StructInst int64;
	immutable Ptr!StructInst nat8;
	immutable Ptr!StructInst nat16;
	immutable Ptr!StructInst nat32;
	immutable Ptr!StructInst nat64;
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
	immutable SpecialModules specialModules;
	immutable Module[] allModules;
	immutable CommonTypes commonTypes;
	immutable Diagnostics diagnostics;
}

immutable(bool) hasDiags(ref immutable Program a) {
	return !empty(a.diagnostics.diags);
}

struct SpecialModules {
	immutable Ptr!Module allocModule;
	immutable Ptr!Module bootstrapModule;
	immutable Ptr!Module runtimeModule;
	immutable Ptr!Module runtimeMainModule;
	immutable Ptr!Module[] rootModules;
}

struct Local {
	//TODO: use NameAndRange (more compact)
	immutable FileAndRange range;
	immutable Sym name;
	immutable Type type;
}

struct ClosureField {
	immutable Sym name;
	immutable Type type;
	immutable Expr expr;
	immutable size_t index;
}

struct Expr {
	@safe @nogc pure nothrow:
	struct Bogus {}

	struct Call {
		immutable Called called;
		immutable Expr[] args;
	}

	struct ClosureFieldRef {
		immutable Ptr!ClosureField field;
	}

	struct Cond {
		immutable Type type;
		immutable Expr cond;
		immutable Expr then;
		immutable Expr else_;
	}

	struct FunPtr {
		immutable Ptr!FunInst funInst;
		immutable Ptr!StructInst structInst;
	}

	struct IfOption {
		immutable Type type;
		immutable Expr option;
		immutable Ptr!Local local;
		immutable Expr then;
		immutable Expr else_;
	}

	// type is the lambda's type (not the body's return type), e.g. a Fun1 or sendFun1 instance.
	struct Lambda {
		immutable Param[] params;
		immutable Expr body_;
		immutable Ptr!ClosureField[] closure;
		// This is the funN type;
		immutable Ptr!StructInst type;
		immutable FunKind kind;
		// For FunKind.send this includes 'fut' wrapper
		immutable Type returnType;
	}

	struct Let {
		immutable Ptr!Local local;
		immutable Expr value;
		immutable Expr then;
	}

	struct Literal {
		immutable Ptr!StructInst structInst;
		immutable Constant value;
	}

	struct LocalRef {
		immutable Ptr!Local local;
	}

	struct MatchEnum {
		immutable Expr matched;
		immutable Expr[] cases;
		immutable Type type;
	}

	struct MatchUnion {
		struct Case {
			immutable Opt!(Ptr!Local) local;
			immutable Expr then;
		}

		immutable Expr matched;
		immutable Ptr!StructInst matchedUnion;
		immutable Case[] cases;
		immutable Type type;
	}

	struct ParamRef {
		immutable Ptr!Param param;
	}

	struct Seq {
		immutable Expr first;
		immutable Expr then;
	}

	struct CStringLiteral {
		immutable SafeCStr value;
	}

	struct SymbolLiteral {
		immutable Sym value;
	}

	private:
	enum Kind {
		bogus,
		call,
		closureFieldRef,
		cond,
		funPtr,
		ifOption,
		lambda,
		let,
		literal,
		localRef,
		matchEnum,
		matchUnion,
		paramRef,
		seq,
		stringLiteral,
		symbolLiteral,
	}

	immutable FileAndRange range_;
	immutable Kind kind;
	union {
		immutable Bogus bogus;
		immutable Call call;
		immutable ClosureFieldRef closureFieldRef;
		immutable Ptr!Cond cond;
		immutable FunPtr funPtr;
		immutable Ptr!IfOption ifOption;
		immutable Ptr!Lambda lambda;
		immutable Ptr!Let let;
		immutable Ptr!Literal literal;
		immutable LocalRef localRef;
		immutable Ptr!MatchEnum matchEnum;
		immutable Ptr!MatchUnion matchUnion;
		immutable ParamRef paramRef;
		immutable Ptr!Seq seq;
		immutable CStringLiteral stringLiteral;
		immutable SymbolLiteral symbolLiteral;
	}

	public:
	immutable this(immutable FileAndRange r, immutable Bogus a) { range_ = r; kind = Kind.bogus; bogus = a; }
	@trusted immutable this(immutable FileAndRange r, immutable Call a) { range_ = r; kind = Kind.call; call = a; }
	@trusted immutable this(immutable FileAndRange r, immutable ClosureFieldRef a) {
		range_ = r; kind = Kind.closureFieldRef; closureFieldRef = a;
	}
	@trusted immutable this(immutable FileAndRange r, immutable Ptr!Cond a) { range_ = r; kind = Kind.cond; cond = a; }
	@trusted immutable this(immutable FileAndRange r, immutable FunPtr a) {
		range_ = r; kind = Kind.funPtr; funPtr = a;
	}
	@trusted immutable this(immutable FileAndRange r, immutable Ptr!IfOption a) {
		range_ = r; kind = Kind.ifOption; ifOption = a;
	}
	@trusted immutable this(immutable FileAndRange r, immutable Ptr!Lambda a) {
		range_ = r; kind = Kind.lambda; lambda = a;
	}
	@trusted immutable this(immutable FileAndRange r, immutable Ptr!Let a) { range_ = r; kind = Kind.let; let = a; }
	@trusted immutable this(immutable FileAndRange r, immutable Ptr!Literal a) {
		range_ = r; kind = Kind.literal; literal = a;
	}
	@trusted immutable this(immutable FileAndRange r, immutable LocalRef a) {
		range_ = r; kind = Kind.localRef; localRef = a;
	}
	@trusted immutable this(immutable FileAndRange r, immutable Ptr!MatchEnum a) {
		range_ = r; kind = Kind.matchEnum; matchEnum = a;
	}
	@trusted immutable this(immutable FileAndRange r, immutable Ptr!MatchUnion a) {
		range_ = r; kind = Kind.matchUnion; matchUnion = a;
	}
	@trusted immutable this(immutable FileAndRange r, immutable ParamRef a) {
		range_ = r; kind = Kind.paramRef; paramRef = a;
	}
	@trusted immutable this(immutable FileAndRange r, immutable Ptr!Seq a) { range_ = r; kind = Kind.seq; seq = a; }
	@trusted immutable this(immutable FileAndRange r, immutable CStringLiteral a) {
		range_ = r; kind = Kind.stringLiteral; stringLiteral = a;
	}
	@trusted immutable this(immutable FileAndRange r, immutable SymbolLiteral a) {
		range_ = r; kind = Kind.symbolLiteral; symbolLiteral = a;
	}
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
	scope immutable(T) delegate(ref immutable Expr.FunPtr) @safe @nogc pure nothrow cbFunPtr,
	scope immutable(T) delegate(ref immutable Expr.IfOption) @safe @nogc pure nothrow cbIfOption,
	scope immutable(T) delegate(ref immutable Expr.Lambda) @safe @nogc pure nothrow cbLambda,
	scope immutable(T) delegate(ref immutable Expr.Let) @safe @nogc pure nothrow cbLet,
	scope immutable(T) delegate(ref immutable Expr.Literal) @safe @nogc pure nothrow cbLiteral,
	scope immutable(T) delegate(ref immutable Expr.LocalRef) @safe @nogc pure nothrow cbLocalRef,
	scope immutable(T) delegate(ref immutable Expr.MatchEnum) @safe @nogc pure nothrow cbMatchEnum,
	scope immutable(T) delegate(ref immutable Expr.MatchUnion) @safe @nogc pure nothrow cbMatchUnion,
	scope immutable(T) delegate(ref immutable Expr.ParamRef) @safe @nogc pure nothrow cbParamRef,
	scope immutable(T) delegate(ref immutable Expr.Seq) @safe @nogc pure nothrow cbSeq,
	scope immutable(T) delegate(ref immutable Expr.CStringLiteral) @safe @nogc pure nothrow cbStringLiteral,
	scope immutable(T) delegate(ref immutable Expr.SymbolLiteral) @safe @nogc pure nothrow cbSymbolLiteral,
) {
	final switch (a.kind) {
		case Expr.Kind.bogus:
			return cbBogus(a.bogus);
		case Expr.Kind.call:
			return cbCall(a.call);
		case Expr.Kind.closureFieldRef:
			return cbClosureFieldRef(a.closureFieldRef);
		case Expr.Kind.cond:
			return cbCond(a.cond.deref());
		case Expr.Kind.funPtr:
			return cbFunPtr(a.funPtr);
		case Expr.Kind.ifOption:
			return cbIfOption(a.ifOption.deref());
		case Expr.Kind.lambda:
			return cbLambda(a.lambda.deref());
		case Expr.Kind.let:
			return cbLet(a.let.deref());
		case Expr.Kind.literal:
			return cbLiteral(a.literal.deref());
		case Expr.Kind.localRef:
			return cbLocalRef(a.localRef);
		case Expr.Kind.matchEnum:
			return cbMatchEnum(a.matchEnum.deref());
		case Expr.Kind.matchUnion:
			return cbMatchUnion(a.matchUnion.deref());
		case Expr.Kind.paramRef:
			return cbParamRef(a.paramRef);
		case Expr.Kind.seq:
			return cbSeq(a.seq.deref());
		case Expr.Kind.stringLiteral:
			return cbStringLiteral(a.stringLiteral);
		case Expr.Kind.symbolLiteral:
			return cbSymbolLiteral(a.symbolLiteral);
	}
}

immutable(bool) typeIsBogus(ref immutable Expr a) {
	return matchExpr!(immutable bool)(
		a,
		(ref immutable Expr.Bogus) => true,
		(ref immutable Expr.Call e) => isBogus(returnType(e.called)),
		(ref immutable Expr.ClosureFieldRef e) => isBogus(e.field.deref().type),
		(ref immutable Expr.Cond e) => isBogus(e.type),
		(ref immutable Expr.FunPtr) => false,
		(ref immutable Expr.IfOption e) => isBogus(e.type),
		(ref immutable Expr.Lambda) => false,
		(ref immutable Expr.Let e) => typeIsBogus(e.then),
		(ref immutable Expr.Literal) => false,
		(ref immutable Expr.LocalRef e) => isBogus(e.local.deref().type),
		(ref immutable Expr.MatchEnum e) => isBogus(e.type),
		(ref immutable Expr.MatchUnion e) => isBogus(e.type),
		(ref immutable Expr.ParamRef e) => isBogus(e.param.deref().type),
		(ref immutable Expr.Seq e) => typeIsBogus(e.then),
		(ref immutable Expr.CStringLiteral) => false,
		(ref immutable Expr.SymbolLiteral) => false);
}

//TODO: this is only called on LocalRef or ParamRef, all others unreachable
immutable(Type) getType(ref immutable Expr a) {
	return matchExpr!(immutable Type)(
		a,
		(ref immutable Expr.Bogus) => immutable Type(immutable Type.Bogus()),
		(ref immutable Expr.Call e) => returnType(e.called),
		(ref immutable Expr.ClosureFieldRef e) => e.field.deref().type,
		(ref immutable Expr.Cond) => todo!(immutable Type)("getType cond"),
		(ref immutable Expr.FunPtr e) => immutable Type(e.structInst),
		(ref immutable Expr.IfOption e) => e.type,
		(ref immutable Expr.Lambda e) => immutable Type(e.type),
		(ref immutable Expr.Let e) => unreachable!(immutable Type),
		(ref immutable Expr.Literal e) => immutable Type(e.structInst),
		(ref immutable Expr.LocalRef e) => e.local.deref().type,
		(ref immutable Expr.MatchEnum) => todo!(immutable Type)("getType matchEnum"),
		(ref immutable Expr.MatchUnion) => todo!(immutable Type)("getType matchUnion"),
		(ref immutable Expr.ParamRef e) => e.param.deref().type,
		(ref immutable Expr.Seq e) => unreachable!(immutable Type),
		(ref immutable Expr.CStringLiteral) => unreachable!(immutable Type),
		(ref immutable Expr.SymbolLiteral) => unreachable!(immutable Type));
}

void writeStructDecl(ref Writer writer, ref const AllSymbols allSymbols, ref immutable StructDecl a) {
	writeSym(writer, allSymbols, a.name);
}

void writeStructInst(ref Writer writer, ref const AllSymbols allSymbols, ref immutable StructInst s) {
	writeStructDecl(writer, allSymbols, decl(s).deref());
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
		(immutable Ptr!TypeParam p) {
			writeSym(writer, allSymbols, p.deref().name);
		},
		(immutable Ptr!StructInst s) {
			writeStructInst(writer, allSymbols, s.deref());
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
