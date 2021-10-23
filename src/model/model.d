module model.model;

@safe @nogc pure nothrow:

import model.constant : Constant;
import model.diag : Diags, FilesInfo; // TODO: move FilesInfo here?
import util.collection.arr : ArrWithSize, empty, emptyArr, first, only, size, sizeEq, toArr;
import util.collection.arrUtil : compareArr;
import util.collection.dict : Dict;
import util.collection.fullIndexDict : FullIndexDict;
import util.collection.mutArr : MutArr;
import util.collection.str : SafeCStr;
import util.comparison : compareOr, Comparison, ptrEquals;
import util.late : Late, lateGet, lateIsSet, lateSet;
import util.lineAndColumnGetter : LineAndColumnGetter;
import util.memory : nu;
import util.opt : Opt, some;
import util.path : AbsolutePath, PathAndStorageKind, StorageKind;
import util.ptr : comparePtr, Ptr;
import util.sourceRange : FileAndPos, FileAndRange, FileIndex, rangeOfStartAndName, RangeWithinFile;
import util.sym :
	compareSym,
	Operator,
	shortSymAlphaLiteral,
	Sym,
	symEq,
	symEqLongAlphaLiteral,
	symForOperator,
	symSize,
	writeSym;
import util.types : Int64, Nat16, Nat64, safeSizeTToU32;
import util.util : todo, unreachable, verify;
import util.writer : writeChar, Writer, writeStatic, writeWithCommas;

struct AbsolutePathsGetter {
	immutable string cwd;
	immutable string globalPath;
	immutable string localPath;
}

private immutable(string) getBasePath(ref immutable AbsolutePathsGetter a, immutable StorageKind sk) {
	final switch (sk) {
		case StorageKind.global:
			return a.globalPath;
		case StorageKind.local:
			return a.localPath;
	}
}

immutable(AbsolutePath) getAbsolutePath(
	ref immutable AbsolutePathsGetter a,
	ref immutable PathAndStorageKind p,
	immutable string extension,
) {
	return immutable AbsolutePath(getBasePath(a, p.storageKind), p.path, extension);
}

alias LineAndColumnGetters = immutable FullIndexDict!(FileIndex, LineAndColumnGetter);

enum Purity : ubyte {
	data,
	sendable,
	mut,
}

immutable(bool) isDataOrSendable(immutable Purity a) {
	return a != Purity.mut;
}

immutable(Sym) symOfPurity(immutable Purity a) {
	final switch (a) {
		case Purity.data:
			return shortSymAlphaLiteral("data");
		case Purity.sendable:
			return shortSymAlphaLiteral("sendable");
		case Purity.mut:
			return shortSymAlphaLiteral("mut");
	}
}

immutable(bool) isPurityWorse(immutable Purity a, immutable Purity b) {
	return a > b;
}

immutable(Purity) worsePurity(immutable Purity a, immutable Purity b) {
	return isPurityWorse(a, b) ? a : b;
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

	private:
	immutable Kind kind;
	union {
		immutable Bogus bogus;
		immutable Ptr!TypeParam typeParam;
		immutable Ptr!StructInst structInst;
	}

	public:
	immutable this(immutable Bogus a) { kind = Kind.bogus; bogus = a; }
	@trusted immutable this(immutable Ptr!TypeParam a) { kind = Kind.typeParam; typeParam = a; }
	@trusted immutable this(immutable Ptr!StructInst a) { kind = Kind.structInst; structInst = a; }
}

@trusted immutable(T) matchType(T)(
	ref immutable Type a,
	scope immutable(T) delegate(ref immutable Type.Bogus) @safe @nogc pure nothrow cbBogus,
	scope immutable(T) delegate(immutable Ptr!TypeParam) @safe @nogc pure nothrow cbTypeParam,
	scope immutable(T) delegate(immutable Ptr!StructInst) @safe @nogc pure nothrow cbStructInst,
) {
	final switch (a.kind) {
		case Type.Kind.bogus:
			return cbBogus(a.bogus);
		case Type.Kind.typeParam:
			return cbTypeParam(a.typeParam);
		case Type.Kind.structInst:
			return cbStructInst(a.structInst);
	}
}

immutable(bool) isBogus(ref immutable Type a) {
	return a.kind == Type.Kind.bogus;
}
immutable(bool) isTypeParam(ref immutable Type a) {
	return a.kind == Type.Kind.typeParam;
}
@trusted immutable(Ptr!TypeParam) asTypeParam(ref immutable Type a) {
	verify(a.isTypeParam);
	return a.typeParam;
}
immutable(bool) isStructInst(ref immutable Type a) {
	return a.kind == Type.Kind.structInst;
}
@trusted immutable(Ptr!StructInst) asStructInst(ref immutable Type a) {
	verify(a.isStructInst);
	return a.structInst;
}

immutable(Purity) bestCasePurity(ref immutable Type a) {
	return matchType!(immutable Purity)(
		a,
		(ref immutable Type.Bogus) => Purity.data,
		(immutable Ptr!TypeParam) => Purity.data,
		(immutable Ptr!StructInst i) => i.bestCasePurity);
}

immutable(Purity) worstCasePurity(ref immutable Type a) {
	return matchType!(immutable Purity)(
		a,
		(ref immutable Type.Bogus) => Purity.data,
		(immutable Ptr!TypeParam) => Purity.mut,
		(immutable Ptr!StructInst i) => i.worstCasePurity);
}

//TODO:MOVE?
immutable(bool) typeEquals(immutable Type a, immutable Type b) {
	return matchType!(immutable bool)(
		a,
		(ref immutable Type.Bogus) =>
			isBogus(b),
		(immutable Ptr!TypeParam p) =>
			isTypeParam(b) && ptrEquals(p, asTypeParam(b)),
		(immutable Ptr!StructInst i) =>
			isStructInst(b) && ptrEquals(i, asStructInst(b)));
}

private immutable(Comparison) compareType(ref immutable Type a, ref immutable Type b) {
	return matchType!(immutable Comparison)(
		a,
		(ref immutable Type.Bogus) => isBogus(b) ? Comparison.equal : Comparison.less,
		(immutable Ptr!TypeParam pa) =>
			matchType!(immutable Comparison)(
				b,
				(ref immutable Type.Bogus) => Comparison.greater,
				(immutable Ptr!TypeParam pb) => comparePtr(pa, pb),
				(immutable Ptr!StructInst) => Comparison.less),
		(immutable Ptr!StructInst ia) =>
			matchType!(immutable Comparison)(
				b,
				(ref immutable Type.Bogus) => Comparison.greater,
				(immutable Ptr!TypeParam) => Comparison.greater,
				(immutable Ptr!StructInst ib) => comparePtr(ia, ib)));
}

struct Param {
	//TODO: use NameAndRange (more compact)
	immutable FileAndRange range;
	immutable Opt!Sym name;
	immutable Type type;
	immutable size_t index;
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

	immutable this(immutable Param[] a) { kind = Kind.regular; regular = a; }
	immutable this(immutable Ptr!Varargs a) { kind = Kind.varargs; varargs = a; }

	private:
	enum Kind {
		regular,
		varargs,
	}
	immutable Kind kind;
	union {
		immutable Param[] regular;
		immutable Ptr!Varargs varargs;
	}
}

@trusted immutable(T) matchParams(T)(
	ref immutable Params a,
	scope immutable(T) delegate(immutable Param[]) @safe @nogc pure nothrow cbRegular,
	scope immutable(T) delegate(ref immutable Params.Varargs) @safe @nogc pure nothrow cbVarargs,
) {
	final switch (a.kind) {
		case Params.Kind.regular:
			return cbRegular(a.regular);
		case Params.Kind.varargs:
			return cbVarargs(a.varargs);
	}
}

@trusted immutable(Param[]) paramsArray(return scope ref immutable Params a) {
	final switch (a.kind) {
		case Params.Kind.regular:
			return a.regular;
		case Params.Kind.varargs:
			return (&a.varargs.param)[0 .. 1];
	}
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

@trusted immutable(T) matchArity(T)(
	immutable Arity a,
	scope immutable(T) delegate(immutable size_t) @safe @nogc pure nothrow cbRegular,
	scope immutable(T) delegate(ref immutable Arity.Varargs) @safe @nogc pure nothrow cbVarargs,
) {
	final switch (a.kind) {
		case Arity.Kind.regular:
			return cbRegular(a.regular);
		case Arity.Kind.varargs:
			return cbVarargs(a.varargs);
	}
}

immutable(bool) arityIsNonZero(immutable Arity a) {
	return matchArity!(immutable bool)(
		a,
		(immutable size_t size) =>
			size != 0,
		(ref immutable Arity.Varargs) =>
			true);
}

immutable(bool) arityMatches(immutable Arity sigArity, immutable size_t nArgs) {
	return matchArity!(immutable bool)(
		sigArity,
		(immutable size_t nParams) =>
			nParams == nArgs,
		(ref immutable Arity.Varargs) =>
			true);
}

immutable(Arity) arity(ref immutable Params a) {
	return matchParams(
		a,
		(immutable Param[] params) =>
			immutable Arity(size(params)),
		(ref immutable Params.Varargs) =>
			immutable Arity(immutable Arity.Varargs()));
}

struct Sig {
	@safe @nogc pure nothrow:

	immutable FileAndPos fileAndPos;
	immutable Sym name;
	immutable Type returnType;
	immutable Params params;

	immutable(RangeWithinFile) range() immutable {
		return rangeOfStartAndName(fileAndPos.pos, name);
	}
}

immutable(FileAndRange) range(ref immutable Sig a) {
	return immutable FileAndRange(
		a.fileAndPos.fileIndex,
		immutable RangeWithinFile(a.fileAndPos.pos, safeSizeTToU32(a.fileAndPos.pos + symSize(a.name))));
}

immutable(Arity) arity(ref const Sig a) {
	return arity(a.params);
}

struct RecordField {
	//TODO: use NameAndRange (more compact)
	immutable FileAndRange range;
	immutable bool isMutable;
	immutable Sym name;
	immutable Type type;
	immutable size_t index;
}

immutable(RecordField) withType(ref immutable RecordField a, immutable Type t) {
	return immutable RecordField(a.range, a.isMutable, a.name, t, a.index);
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

struct RecordFlags {
	immutable bool packed;
	immutable ForcedByValOrRefOrNone forcedByValOrRef;
}

struct EnumValue {
	@safe @nogc pure nothrow:

	// Large nat64 are represented as wrapped to negative values.
	immutable long value;

	//TODO:NOT INSTANCE
	immutable(Int64) asSigned() immutable { return immutable Int64(value); }
	immutable(Nat64) asUnsigned() immutable { return immutable Nat64(cast(ulong) value); }
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
static assert(StructBody.sizeof <= 32);

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

@trusted T matchStructBody(T)(
	ref immutable StructBody a,
	scope T delegate(ref immutable StructBody.Bogus) @safe @nogc pure nothrow cbBogus,
	scope T delegate(ref immutable StructBody.Builtin) @safe @nogc pure nothrow cbBuiltin,
	scope T delegate(ref immutable StructBody.Enum) @safe @nogc pure nothrow cbEnum,
	scope T delegate(ref immutable StructBody.Flags) @safe @nogc pure nothrow cbFlags,
	scope T delegate(ref immutable StructBody.ExternPtr) @safe @nogc pure nothrow cbExternPtr,
	scope T delegate(ref immutable StructBody.Record) @safe @nogc pure nothrow cbRecord,
	scope T delegate(ref immutable StructBody.Union) @safe @nogc pure nothrow cbUnion,
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
	immutable bool isPublic;
	immutable Sym name;
	immutable ArrWithSize!TypeParam typeParams_;

	private:
	// This will be none if the alias target is not found
	Late!(immutable Opt!(Ptr!StructInst)) target_;
}

immutable(TypeParam[]) typeParams(ref const StructAlias a) {
	return toArr(a.typeParams_);
}

immutable(Opt!(Ptr!StructInst)) target(ref immutable StructAlias a) {
	return lateGet(a.target_);
}
void setTarget(ref StructAlias a, immutable Opt!(Ptr!StructInst) value) {
	lateSet(a.target_, value);
}

struct StructDecl {
	// TODO: use NameAndRange (more compact)
	immutable FileAndRange range;
	immutable SafeCStr docComment;
	immutable Sym name;
	immutable ArrWithSize!TypeParam typeParams_;
	immutable bool isPublic;
	// Note: purity on the decl does not take type args into account
	immutable Purity purity;
	immutable bool purityIsForced;

	private:
	Late!(immutable StructBody) _body_;
}

immutable(TypeParam[]) typeParams(ref immutable StructDecl a) {
	return toArr(a.typeParams_);
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

	immutable Ptr!StructDecl decl;
	immutable Type[] typeArgs;

	immutable this(immutable Ptr!StructDecl d, immutable Type[] t) {
		verify(size(d.typeParams) == size(t));
		decl = d;
		typeArgs = t;
	}
}

immutable(Comparison) compareStructDeclAndArgs(ref immutable StructDeclAndArgs a, ref immutable StructDeclAndArgs b) {
	return compareOr(
		comparePtr(a.decl, b.decl),
		() => compareArr!Type(a.typeArgs, b.typeArgs, (ref immutable Type ta, ref immutable Type tb) =>
			compareType(ta, tb)));
}

struct StructInst {
	@safe @nogc pure nothrow:

	immutable StructDeclAndArgs declAndArgs;
	immutable Purity bestCasePurity; // inferred from declAndArgs
	immutable Purity worstCasePurity; // inferred from declAndArgs

	private:
	// Like decl.body but has type args filled in.
	Late!(immutable StructBody) _body_;
}

immutable(bool) isArr(ref immutable StructInst i) {
	// TODO: only do this for the arr in bootstrap, not anything named 'arr'
	return symEq(decl(i).name, shortSymAlphaLiteral("arr"));
}

immutable(Sym) name(ref immutable StructInst i) {
	return decl(i).name;
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
		immutable Sig[] sigs;
	}

	public:
	immutable this(immutable Builtin a) { kind = Kind.builtin; builtin = a; }
	@trusted immutable this(immutable Sig[] a) { kind = Kind.sigs; sigs = a; }
}

@trusted T matchSpecBody(T)(
	ref immutable SpecBody a,
	scope T delegate(ref immutable SpecBody.Builtin) @safe @nogc pure nothrow cbBuiltin,
	scope T delegate(ref immutable Sig[]) @safe @nogc pure nothrow cbSigs,
) {
	final switch (a.kind) {
		case SpecBody.Kind.builtin:
			return cbBuiltin(a.builtin);
		case SpecBody.Kind.sigs:
			return cbSigs(a.sigs);
	}
}

immutable(size_t) nSigs(ref immutable SpecBody a) {
	return matchSpecBody(
		a,
		(ref immutable SpecBody.Builtin) => immutable size_t(0),
		(ref immutable Sig[] sigs) => size(sigs));
}

struct SpecDecl {
	// TODO: use NameAndRange (more compact)
	immutable FileAndRange range;
	immutable SafeCStr docComment;
	immutable bool isPublic;
	immutable Sym name;
	immutable ArrWithSize!TypeParam typeParams_;
	immutable SpecBody body_;
	MutArr!(immutable Ptr!SpecInst) insts;
}

immutable(TypeParam[]) typeParams(ref immutable SpecDecl a) {
	return toArr(a.typeParams_);
}

struct SpecDeclAndArgs {
	immutable Ptr!SpecDecl decl;
	immutable Type[] typeArgs;
}

immutable(Comparison) compareSpecDeclAndArgs(ref immutable SpecDeclAndArgs a, ref immutable SpecDeclAndArgs b) {
	return compareOr(
		comparePtr(a.decl, b.decl),
		() => compareArr!Type(a.typeArgs, b.typeArgs, (ref immutable Type ta, ref immutable Type tb) =>
			compareType(ta, tb)));
}

struct SpecInst {
	immutable SpecDeclAndArgs declAndArgs;
	immutable SpecBody body_;
}

immutable(Ptr!SpecDecl) decl(ref immutable SpecInst a) {
	return a.declAndArgs.decl;
}

ref immutable(Type[]) typeArgs(return scope ref immutable SpecInst a) {
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
			return shortSymAlphaLiteral("members");
		case EnumFunction.toIntegral:
			return shortSymAlphaLiteral("to-integral");
		case EnumFunction.union_:
			return symForOperator(Operator.or1);
	}
}

enum FlagsFunction {
	all,
	empty,
	negate,
}

immutable(Sym) flagsFunctionName(immutable FlagsFunction a) {
	final switch (a) {
		case FlagsFunction.all:
			return shortSymAlphaLiteral("all");
		case FlagsFunction.empty:
			return shortSymAlphaLiteral("empty");
		case FlagsFunction.negate:
			return symForOperator(Operator.tilde);
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
		immutable Nat16 memberIndex;
	}
	struct Extern {
		immutable bool isGlobal;
		immutable Opt!string libraryName;
	}
	struct RecordFieldGet {
		immutable ubyte fieldIndex;
	}
	struct RecordFieldSet {
		immutable ubyte fieldIndex;
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
		immutable Ptr!Extern extern_;
		immutable Ptr!Expr expr;
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
	@trusted immutable this(immutable Ptr!Extern a) { kind = Kind.extern_; extern_ = a; }
	@trusted immutable this(immutable Ptr!Expr a) { kind = Kind.expr; expr = a; }
	immutable this(immutable FlagsFunction a) { kind = Kind.flagsFunction; flagsFunction = a; }
	immutable this(immutable RecordFieldGet a) { kind = Kind.recordFieldGet; recordFieldGet = a; }
	immutable this(immutable RecordFieldSet a) { kind = Kind.recordFieldSet; recordFieldSet = a; }
}
static assert(FunBody.sizeof <= 16);

immutable(bool) isExtern(ref immutable FunBody a) {
	return a.kind == FunBody.Kind.extern_;
}

@trusted T matchFunBody(T)(
	ref immutable FunBody a,
	scope T delegate(ref immutable FunBody.Builtin) @safe @nogc pure nothrow cbBuiltin,
	scope T delegate(ref immutable FunBody.CreateEnum) @safe @nogc pure nothrow cbCreateEnum,
	scope T delegate(ref immutable FunBody.CreateRecord) @safe @nogc pure nothrow cbCreateRecord,
	scope T delegate(ref immutable FunBody.CreateUnion) @safe @nogc pure nothrow cbCreateUnion,
	scope T delegate(immutable EnumFunction) @safe @nogc pure nothrow cbEnumFunction,
	scope T delegate(ref immutable FunBody.Extern) @safe @nogc pure nothrow cbExtern,
	scope T delegate(immutable Ptr!Expr) @safe @nogc pure nothrow cbExpr,
	scope T delegate(immutable FlagsFunction) @safe @nogc pure nothrow cbFlagsFunction,
	scope T delegate(ref immutable FunBody.RecordFieldGet) @safe @nogc pure nothrow cbRecordFieldGet,
	scope T delegate(ref immutable FunBody.RecordFieldSet) @safe @nogc pure nothrow cbRecordFieldSet,
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

	immutable bool noCtx;
	immutable bool summon;
	immutable bool unsafe;
	immutable bool trusted;
	immutable bool generated;
	immutable bool preferred;
	immutable bool okIfUnused;

	//TODO:NOT INSTANCE
	immutable(FunFlags) withOkIfUnused() immutable {
		return immutable FunFlags(noCtx, summon, unsafe, trusted, generated, preferred, true);
	}

	static immutable FunFlags none = immutable FunFlags(false, false, false, false, false, false, false);
	static immutable FunFlags generatedNoCtx = immutable FunFlags(true, false, false, false, true, false, false);
	static immutable FunFlags generatedPreferred = immutable FunFlags(false, false, false, false, true, true, false);
	static immutable FunFlags unsafeSummon = immutable FunFlags(false, true, true, false, false, false, false);
}
static assert(FunFlags.sizeof == 7);

struct FunDecl {
	@safe @nogc pure nothrow:

	@disable this(ref const FunDecl);
	this(
		immutable SafeCStr dc,
		immutable bool ip,
		immutable FunFlags f,
		immutable Ptr!Sig s,
		immutable ArrWithSize!TypeParam tps,
		immutable ArrWithSize!(Ptr!SpecInst) sps,
	) {
		docComment = dc;
		isPublic = ip;
		flags = f;
		sig = s;
		typeParams_ = tps;
		specs_ = sps;
		body_ = immutable FunBody(immutable FunBody.Builtin());
	}
	this(
		immutable SafeCStr dc,
		immutable bool ip,
		immutable FunFlags f,
		immutable Ptr!Sig s,
		immutable ArrWithSize!TypeParam tps,
		immutable ArrWithSize!(Ptr!SpecInst) sps,
		immutable FunBody b,
	) {
		docComment = dc;
		isPublic = ip;
		flags = f;
		sig = s;
		typeParams_ = tps;
		specs_ = sps;
		body_ = b;
	}

	immutable SafeCStr docComment;
	immutable bool isPublic;
	immutable FunFlags flags;
	immutable Ptr!Sig sig;
	immutable ArrWithSize!TypeParam typeParams_;
	immutable ArrWithSize!(Ptr!SpecInst) specs_;
	FunBody body_;
}
static assert(FunDecl.sizeof <= 56);

immutable(TypeParam[]) typeParams(ref immutable FunDecl a) {
	return toArr(a.typeParams_);
}
immutable(Ptr!SpecInst[]) specs(ref immutable FunDecl a) {
	return toArr(a.specs_);
}

immutable(FileAndRange) range(return scope ref immutable FunDecl a) {
	return range(a.sig);
}

immutable(bool) isExtern(ref immutable FunDecl a) {
	return a.body_.isExtern;
}

immutable(bool) noCtx(ref const FunDecl a) {
	return a.flags.noCtx;
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
immutable(bool) generated(ref immutable FunDecl a) {
	return a.flags.generated;
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

private immutable(size_t) nSpecImpls(ref immutable FunDecl a) {
	size_t n = 0;
	foreach (immutable Ptr!SpecInst s; a.specs)
		n += s.body_.nSigs;
	return n;
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

	immutable this(immutable Ptr!FunDecl d, immutable Type[] ta, immutable Called[] si) {
		decl = d;
		typeArgs = ta;
		specImpls = si;
		verify(sizeEq(typeArgs, decl.typeParams));
		verify(size(specImpls) == nSpecImpls(decl));
	}
}

immutable(Comparison) compareFunDeclAndArgs(ref immutable FunDeclAndArgs a, ref immutable FunDeclAndArgs b) {
	return compareOr(
		comparePtr(a.decl, b.decl),
		() => compareArr!Type(a.typeArgs, b.typeArgs, (ref immutable Type ta, ref immutable Type tb) =>
			compareType(ta, tb)),
		() => compareArr!Called(a.specImpls, b.specImpls, (ref immutable Called ca, ref immutable Called cb) =>
			compareCalled(ca, cb)));
}

struct FunInst {
	immutable FunDeclAndArgs funDeclAndArgs;
	immutable Sig sig;
}

immutable(bool) isCallWithCtxFun(ref immutable FunInst a) {
	// TODO: only do this for the call-with-ctx in bootstrap
	return symEqLongAlphaLiteral(name(decl(a).deref()), "call-with-ctx");
}

immutable(bool) isCompareFun(ref immutable FunInst a) {
	// TODO: only do this for the '<=>' in bootstrap
	return symEq(name(decl(a).deref()), symForOperator(Operator.compare));
}

immutable(bool) isMarkVisitFun(ref immutable FunInst a) {
	// TODO: only do this for the 'mark-visit' in bootstrap
	return symEq(name(decl(a).deref()), shortSymAlphaLiteral("mark-visit"));
}

immutable(Ptr!FunInst) nonTemplateFunInst(Alloc)(ref Alloc alloc, immutable Ptr!FunDecl decl) {
	return nu!FunInst(alloc, immutable FunDeclAndArgs(decl, emptyArr!Type, emptyArr!Called), decl.sig);
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
	immutable Ptr!Sig sig;
	immutable size_t indexOverAllSpecUses; // this is redundant to specInst and sig
}

private immutable(Comparison) compareSpecSig(ref immutable SpecSig a, ref immutable SpecSig b) {
	// Don't bother with indexOverAllSpecUses, it's redundant if we checked sig
	return compareOr(
		comparePtr(a.specInst, b.specInst),
		() => comparePtr(a.sig, b.sig));
}

immutable(Sym) name(ref immutable SpecSig a) {
	return a.sig.name;
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

@trusted T matchCalledDecl(T)(
	ref immutable CalledDecl a,
	scope T delegate(immutable Ptr!FunDecl) @safe @nogc pure nothrow cbFunDecl,
	scope T delegate(ref immutable SpecSig) @safe @nogc pure nothrow cbSpecSig,
) {
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
			return a.specSig.sig.deref;
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
	return matchCalledDecl(
		a,
		(immutable Ptr!FunDecl f) => f.typeParams,
		(ref immutable SpecSig) => emptyArr!TypeParam);
}

immutable(Arity) arity(ref immutable CalledDecl a) {
	return arity(params(a));
}

immutable(size_t) nTypeParams(ref immutable CalledDecl a) {
	return size(typeParams(a));
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

@trusted T matchCalled(T)(
	ref immutable Called a,
	scope T delegate(immutable Ptr!FunInst) @safe @nogc pure nothrow cbFunInst,
	scope T delegate(ref immutable SpecSig) @safe @nogc pure nothrow cbSpecSig,
) {
	final switch (a.kind) {
		case Called.Kind.funInst:
			return cbFunInst(a.funInst);
		case Called.Kind.specSig:
			return cbSpecSig(a.specSig);
	}
}

private immutable(Comparison) compareCalled(ref immutable Called a, ref immutable Called b) {
	return matchCalled!(immutable Comparison)(
		a,
		(immutable Ptr!FunInst fa) =>
			matchCalled!(immutable Comparison)(
				b,
				(immutable Ptr!FunInst fb) => comparePtr(fa, fb),
				(ref immutable SpecSig) => Comparison.less),
		(ref immutable SpecSig sa) =>
			matchCalled!(immutable Comparison)(
				b,
				(immutable Ptr!FunInst) => Comparison.greater,
				(ref immutable SpecSig sb) => compareSpecSig(sa, sb)));
}

@trusted ref immutable(Sig) sig(return scope ref immutable Called a) {
	final switch (a.kind) {
		case Called.Kind.funInst:
			return a.funInst.sig;
		case Called.Kind.specSig:
			return a.specSig.sig.deref;
	}
	//TODO: match can't return ref?
	//return a.match(
	//	(immutable Ptr!FunInst f) => f.sig,
	//	(ref immutable SpecSig s) => s.sig.deref,
	//);
}

immutable(Sym) name(ref immutable Called a) {
	return matchCalled(
		a,
		(immutable Ptr!FunInst) => a.name,
		(ref immutable SpecSig s) => a.name);
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
		verify(size(a.typeParams) < 10); //TODO:KILL
	}
}

@trusted immutable(Ptr!StructDecl) asStructDecl(immutable StructOrAlias a) {
	verify(a.kind == StructOrAlias.Kind.structDecl);
	return a.structDecl_;
}

@trusted T matchStructOrAlias(T)(
	ref immutable StructOrAlias a,
	scope T delegate(immutable Ptr!StructAlias) @safe @nogc pure nothrow cbAlias,
	scope T delegate(immutable Ptr!StructDecl) @safe @nogc pure nothrow cbStructDecl,
) {
	final switch (a.kind) {
		case StructOrAlias.Kind.alias_:
			return cbAlias(a.alias_);
		case StructOrAlias.Kind.structDecl:
			return cbStructDecl(a.structDecl_);
	}
}

immutable(TypeParam[]) typeParams(ref immutable StructOrAlias a) {
	return matchStructOrAlias(
		a,
		(immutable Ptr!StructAlias al) => al.typeParams,
		(immutable Ptr!StructDecl d) => d.typeParams);
}

immutable(FileAndRange) range(ref immutable StructOrAlias a) {
	return matchStructOrAlias(
		a,
		(immutable Ptr!StructAlias al) => al.range,
		(immutable Ptr!StructDecl d) => d.range);
}

immutable(bool) isPublic(ref immutable StructOrAlias a) {
	return matchStructOrAlias(
		a,
		(immutable Ptr!StructAlias al) => al.isPublic,
		(immutable Ptr!StructDecl d) => d.isPublic);
}

immutable(Sym) name(ref immutable StructOrAlias a) {
	return matchStructOrAlias(
		a,
		(immutable Ptr!StructAlias al) => al.name,
		(immutable Ptr!StructDecl d) => d.name);
}

struct Module {
	@safe @nogc pure nothrow:

	immutable FileIndex fileIndex;
	immutable SafeCStr docComment;
	private:
	immutable Ptr!ModuleImportsExports importsAndExports_;
	immutable Ptr!ModuleArrs arrs_;

	public:
	// Includes re-exports
	immutable Dict!(Sym, NameReferents, compareSym) allExportedNames;

	//TODO:NOT INSTANCE
	ref immutable(ModuleAndNames[]) imports() return scope immutable {
		return importsAndExports_.imports;
	}

	ref immutable(ModuleAndNames[]) exports() return scope immutable {
		return importsAndExports_.exports;
	}

	ref immutable(StructDecl[]) structs() return scope immutable {
		return arrs_.structs;
	}

	ref immutable(SpecDecl[]) specs() return scope immutable {
		return arrs_.specs;
	}

	ref immutable(FunDecl[]) funs() return scope immutable {
		return arrs_.funs;
	}

	ref immutable(Test[]) tests() return scope immutable {
		return arrs_.tests;
	}
}
static assert(Module.sizeof <= 48);

struct ModuleImportsExports {
	immutable ModuleAndNames[] imports; // includes import of std (if applicable)
	immutable ModuleAndNames[] exports;
}

struct ModuleArrs {
	immutable StructDecl[] structs;
	immutable SpecDecl[] specs;
	immutable FunDecl[] funs;
	immutable Test[] tests;
}

struct ModuleAndNames {
	// none for an automatic import of std
	immutable Opt!RangeWithinFile importSource;
	immutable Ptr!Module module_;
	immutable Opt!(Sym[]) names;
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
	immutable Ptr!StructDecl[] structs;
}

struct CommonTypes {
	@safe @nogc pure nothrow:

	immutable Ptr!StructInst bool_;
	immutable Ptr!StructInst char_;
	immutable Ptr!StructInst float32;
	immutable Ptr!StructInst float64;
	immutable Ptr!IntegralTypes integrals;
	immutable Ptr!StructInst str;
	immutable Ptr!StructInst sym;
	immutable Ptr!StructInst void_;
	immutable Ptr!StructInst ctx;
	immutable Ptr!StructDecl byVal;
	immutable Ptr!StructDecl arr;
	immutable Ptr!StructDecl fut;
	immutable Ptr!StructDecl namedVal;
	immutable Ptr!StructDecl opt;
	immutable Ptr!StructDecl[] funPtrStructs; // Indexed by arity
	immutable FunKindAndStructs[] funKindsAndStructs;
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
	@safe @nogc pure nothrow:

	@disable this(ref const Program);
	immutable this(
		immutable Ptr!FilesInfo f,
		immutable Ptr!SpecialModules s,
		immutable Ptr!Module[] all,
		immutable Ptr!CommonTypes ct,
		immutable Diags d,
	) {
		filesInfo = f;
		specialModules = s;
		allModules = all;
		commonTypes = ct;
		diagnostics = d;
	}

	immutable Ptr!FilesInfo filesInfo;
	immutable Ptr!SpecialModules specialModules;
	immutable Ptr!Module[] allModules;
	immutable Ptr!CommonTypes commonTypes;
	immutable Diags diagnostics;
}
static assert(Program.sizeof <= 64);

struct SpecialModules {
	immutable Ptr!Module allocModule;
	immutable Ptr!Module bootstrapModule;
	immutable Ptr!Module runtimeModule;
	immutable Ptr!Module runtimeMainModule;
	immutable Ptr!Module mainModule;
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
	immutable Ptr!Expr expr;
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
		immutable Ptr!Expr cond;
		immutable Ptr!Expr then;
		immutable Ptr!Expr else_;
	}

	struct FunPtr {
		immutable Ptr!FunInst funInst;
		immutable Ptr!StructInst structInst;
	}

	struct IfOption {
		immutable Type type;
		immutable Ptr!Expr option;
		immutable Ptr!Local local;
		immutable Ptr!Expr then;
		immutable Ptr!Expr else_;
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
		immutable Ptr!Expr value;
		immutable Ptr!Expr then;
	}

	struct Literal {
		immutable Ptr!StructInst structInst;
		immutable Constant value;
	}

	struct LocalRef {
		immutable Ptr!Local local;
	}

	struct MatchEnum {
		immutable Ptr!Expr matched;
		immutable Expr[] cases;
		immutable Type type;
	}

	struct MatchUnion {
		struct Case {
			immutable Opt!(Ptr!Local) local;
			immutable Ptr!Expr then;
		}

		immutable Ptr!Expr matched;
		immutable Ptr!StructInst matchedUnion;
		immutable Case[] cases;
		immutable Type type;
	}

	struct ParamRef {
		immutable Ptr!Param param;
	}

	struct Seq {
		immutable(Ptr!Expr) first;
		immutable(Ptr!Expr) then;
	}

	struct StringLiteral {
		immutable string literal;
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
		immutable Cond cond;
		immutable FunPtr funPtr;
		immutable IfOption ifOption;
		immutable Ptr!Lambda lambda;
		immutable Let let;
		immutable Ptr!Literal literal;
		immutable LocalRef localRef;
		immutable MatchEnum matchEnum;
		immutable MatchUnion matchUnion;
		immutable ParamRef paramRef;
		immutable Seq seq;
		immutable StringLiteral stringLiteral;
		immutable SymbolLiteral symbolLiteral;
	}

	public:
	immutable this(immutable FileAndRange r, immutable Bogus a) { range_ = r; kind = Kind.bogus; bogus = a; }
	@trusted immutable this(immutable FileAndRange r, immutable Call a) { range_ = r; kind = Kind.call; call = a; }
	@trusted immutable this(immutable FileAndRange r, immutable ClosureFieldRef a) {
		range_ = r; kind = Kind.closureFieldRef; closureFieldRef = a;
	}
	@trusted immutable this(immutable FileAndRange r, immutable Cond a) { range_ = r; kind = Kind.cond; cond = a; }
	@trusted immutable this(immutable FileAndRange r, immutable FunPtr a) {
		range_ = r; kind = Kind.funPtr; funPtr = a;
	}
	@trusted immutable this(immutable FileAndRange r, immutable IfOption a) {
		range_ = r; kind = Kind.ifOption; ifOption = a;
	}
	@trusted immutable this(immutable FileAndRange r, immutable Ptr!Lambda a) {
		range_ = r; kind = Kind.lambda; lambda = a;
	}
	@trusted immutable this(immutable FileAndRange r, immutable Let a) { range_ = r; kind = Kind.let; let = a; }
	@trusted immutable this(immutable FileAndRange r, immutable Ptr!Literal a) {
		range_ = r; kind = Kind.literal; literal = a;
	}
	@trusted immutable this(immutable FileAndRange r, immutable LocalRef a) {
		range_ = r; kind = Kind.localRef; localRef = a;
	}
	@trusted immutable this(immutable FileAndRange r, immutable MatchEnum a) {
		range_ = r; kind = Kind.matchEnum; matchEnum = a;
	}
	@trusted immutable this(immutable FileAndRange r, immutable MatchUnion a) {
		range_ = r; kind = Kind.matchUnion; matchUnion = a;
	}
	@trusted immutable this(immutable FileAndRange r, immutable ParamRef a) {
		range_ = r; kind = Kind.paramRef; paramRef = a;
	}
	@trusted immutable this(immutable FileAndRange r, immutable Seq a) { range_ = r; kind = Kind.seq; seq = a; }
	@trusted immutable this(immutable FileAndRange r, immutable StringLiteral a) {
		range_ = r; kind = Kind.stringLiteral; stringLiteral = a;
	}
	@trusted immutable this(immutable FileAndRange r, immutable SymbolLiteral a) {
		range_ = r; kind = Kind.symbolLiteral; symbolLiteral = a;
	}
}

ref immutable(FileAndRange) range(return ref immutable Expr a) {
	return a.range_;
}

@trusted T matchExpr(T)(
	ref immutable Expr a,
	scope T delegate(ref immutable Expr.Bogus) @safe @nogc pure nothrow cbBogus,
	scope T delegate(ref immutable Expr.Call) @safe @nogc pure nothrow cbCall,
	scope T delegate(ref immutable Expr.ClosureFieldRef) @safe @nogc pure nothrow cbClosureFieldRef,
	scope T delegate(ref immutable Expr.Cond) @safe @nogc pure nothrow cbCond,
	scope T delegate(ref immutable Expr.FunPtr) @safe @nogc pure nothrow cbFunPtr,
	scope T delegate(ref immutable Expr.IfOption) @safe @nogc pure nothrow cbIfOption,
	scope T delegate(ref immutable Expr.Lambda) @safe @nogc pure nothrow cbLambda,
	scope T delegate(ref immutable Expr.Let) @safe @nogc pure nothrow cbLet,
	scope T delegate(ref immutable Expr.Literal) @safe @nogc pure nothrow cbLiteral,
	scope T delegate(ref immutable Expr.LocalRef) @safe @nogc pure nothrow cbLocalRef,
	scope T delegate(ref immutable Expr.MatchEnum) @safe @nogc pure nothrow cbMatchEnum,
	scope T delegate(ref immutable Expr.MatchUnion) @safe @nogc pure nothrow cbMatchUnion,
	scope T delegate(ref immutable Expr.ParamRef) @safe @nogc pure nothrow cbParamRef,
	scope T delegate(ref immutable Expr.Seq) @safe @nogc pure nothrow cbSeq,
	scope T delegate(ref immutable Expr.StringLiteral) @safe @nogc pure nothrow cbStringLiteral,
	scope T delegate(ref immutable Expr.SymbolLiteral) @safe @nogc pure nothrow cbSymbolLiteral,
) {
	final switch (a.kind) {
		case Expr.Kind.bogus:
			return cbBogus(a.bogus);
		case Expr.Kind.call:
			return cbCall(a.call);
		case Expr.Kind.closureFieldRef:
			return cbClosureFieldRef(a.closureFieldRef);
		case Expr.Kind.cond:
			return cbCond(a.cond);
		case Expr.Kind.funPtr:
			return cbFunPtr(a.funPtr);
		case Expr.Kind.ifOption:
			return cbIfOption(a.ifOption);
		case Expr.Kind.lambda:
			return cbLambda(a.lambda);
		case Expr.Kind.let:
			return cbLet(a.let);
		case Expr.Kind.literal:
			return cbLiteral(a.literal);
		case Expr.Kind.localRef:
			return cbLocalRef(a.localRef);
		case Expr.Kind.matchEnum:
			return cbMatchEnum(a.matchEnum);
		case Expr.Kind.matchUnion:
			return cbMatchUnion(a.matchUnion);
		case Expr.Kind.paramRef:
			return cbParamRef(a.paramRef);
		case Expr.Kind.seq:
			return cbSeq(a.seq);
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
		(ref immutable Expr.ClosureFieldRef e) => isBogus(e.field.type),
		(ref immutable Expr.Cond e) => isBogus(e.type),
		(ref immutable Expr.FunPtr) => false,
		(ref immutable Expr.IfOption e) => isBogus(e.type),
		(ref immutable Expr.Lambda) => false,
		(ref immutable Expr.Let e) => typeIsBogus(e.then),
		(ref immutable Expr.Literal) => false,
		(ref immutable Expr.LocalRef e) => isBogus(e.local.type),
		(ref immutable Expr.MatchEnum e) => isBogus(e.type),
		(ref immutable Expr.MatchUnion e) => isBogus(e.type),
		(ref immutable Expr.ParamRef e) => isBogus(e.param.type),
		(ref immutable Expr.Seq e) => typeIsBogus(e.then),
		(ref immutable Expr.StringLiteral) => false,
		(ref immutable Expr.SymbolLiteral) => false);
}

immutable(Type) getType(ref immutable Expr a, ref immutable CommonTypes commonTypes) {
	return matchExpr!(immutable Type)(
		a,
		(ref immutable Expr.Bogus) => immutable Type(immutable Type.Bogus()),
		(ref immutable Expr.Call e) => returnType(e.called),
		(ref immutable Expr.ClosureFieldRef e) => e.field.type,
		(ref immutable Expr.Cond) => todo!(immutable Type)("getType cond"),
		(ref immutable Expr.FunPtr e) => immutable Type(e.structInst),
		(ref immutable Expr.IfOption e) => e.type,
		(ref immutable Expr.Lambda e) => immutable Type(e.type),
		(ref immutable Expr.Let e) => getType(e.then, commonTypes),
		(ref immutable Expr.Literal e) => immutable Type(e.structInst),
		(ref immutable Expr.LocalRef e) => e.local.type,
		(ref immutable Expr.MatchEnum) => todo!(immutable Type)("getType matchEnum"),
		(ref immutable Expr.MatchUnion) => todo!(immutable Type)("getType matchUnion"),
		(ref immutable Expr.ParamRef e) => e.param.type,
		(ref immutable Expr.Seq e) => getType(e.then, commonTypes),
		(ref immutable Expr.StringLiteral) => immutable Type(commonTypes.str),
		(ref immutable Expr.SymbolLiteral) => immutable Type(commonTypes.sym));
}

void writeStructDecl(Alloc)(ref Writer!Alloc writer, ref immutable StructDecl a) {
	writeSym(writer, a.name);
}

void writeStructInst(Alloc)(ref Writer!Alloc writer, ref immutable StructInst s) {
	writeStructDecl(writer, decl(s).deref());
	if (!empty(s.typeArgs)) {
		writeChar(writer, '<');
		writeWithCommas!(Type, Alloc)(writer, s.typeArgs, (ref immutable Type t) {
			writeType(writer, t);
		});
		writeChar(writer, '>');
	}
}

//TODO:MOVE
void writeType(Alloc)(ref Writer!Alloc writer, ref immutable Type type) {
	matchType!void(
		type,
		(ref immutable Type.Bogus) {
			writeStatic(writer, "<<bogus>>");
		},
		(immutable Ptr!TypeParam p) {
			writeSym(writer, p.name);
		},
		(immutable Ptr!StructInst s) {
			writeStructInst(writer, s);
		});
}
