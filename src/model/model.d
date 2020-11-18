module model.model;

@safe @nogc pure nothrow:

import model.diag : FilesInfo; // TODO: move that here?
import util.bools : and, Bool, False, True;
import util.collection.arr : Arr, ArrWithSize, empty, emptyArr, first, only, range, size, sizeEq, toArr;
import util.collection.arrUtil : compareArr;
import util.collection.dict : Dict;
import util.collection.fullIndexDict : FullIndexDict;
import util.collection.multiDict : MultiDict;
import util.collection.mutArr : MutArr;
import util.collection.str : Str;
import util.comparison : compareEnum, compareOr, Comparison, ptrEquals;
import util.late : Late, lateGet, lateIsSet, lateSet;
import util.lineAndColumnGetter : LineAndColumnGetter;
import util.memory : nu;
import util.opt : has, none, Opt, some;
import util.path : AbsolutePath, comparePath, PathAndStorageKind, StorageKind;
import util.ptr : comparePtr, Ptr;
import util.sourceRange : FileAndPos, FileAndRange, FileIndex, RangeWithinFile;
import util.sym : compareSym, shortSymAlphaLiteral, shortSymOperatorLiteral, Sym, symEq, symSize, writeSym;
import util.types : u8, safeSizeTToU32;
import util.util : todo, verify;
import util.writer : writeChar, Writer, writeStatic;

immutable(Comparison) comparePathAndStorageKind(immutable PathAndStorageKind a, immutable PathAndStorageKind b) {
	return compareOr(
		compareEnum(a.storageKind, b.storageKind),
		() => comparePath(a.path, b.path));
}

struct AbsolutePathsGetter {
	immutable Str globalPath;
	immutable Str localPath;
}

private immutable(Str) getBasePath(ref immutable AbsolutePathsGetter a, immutable StorageKind sk) {
	final switch (sk) {
		case StorageKind.global:
			return a.globalPath;
		case StorageKind.local:
			return a.localPath;
	}
}

immutable(AbsolutePath) getAbsolutePath(Alloc)(
	ref Alloc alloc,
	ref immutable AbsolutePathsGetter a,
	ref immutable PathAndStorageKind p,
	immutable Str extension,
) {
	return AbsolutePath(a.getBasePath(p.storageKind), p.path, extension);
}

alias LineAndColumnGetters = immutable FullIndexDict!(FileIndex, LineAndColumnGetter);

enum Purity {
	data,
	sendable,
	mut,
}

immutable(Bool) isDataOrSendable(immutable Purity a) {
	return Bool(a != Purity.mut);
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

immutable(Bool) isPurityWorse(immutable Purity a, immutable Purity b) {
	return Bool(a > b);
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

immutable(Bool) isBogus(ref immutable Type a) {
	return Bool(a.kind == Type.Kind.bogus);
}
immutable(Bool) isTypeParam(ref immutable Type a) {
	return Bool(a.kind == Type.Kind.typeParam);
}
@trusted immutable(Ptr!TypeParam) asTypeParam(ref immutable Type a) {
	verify(a.isTypeParam);
	return a.typeParam;
}
immutable(Bool) isStructInst(ref immutable Type a) {
	return Bool(a.kind == Type.Kind.structInst);
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
immutable(Bool) typeEquals(immutable Type a, immutable Type b) {
	return matchType(
		a,
		(ref immutable Type.Bogus) => isBogus(b),
		(immutable Ptr!TypeParam p) => and!(() => isTypeParam(b), () => ptrEquals(p, asTypeParam(b))),
		(immutable Ptr!StructInst i) => and!(() => isStructInst(b), () => ptrEquals(i, asStructInst(b))));
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
	immutable Sym name;
	immutable Type type;
	immutable size_t index;
}

immutable(Param) withType(ref immutable Param a, immutable Type t) {
	return Param(a.range, a.name, t, a.index);
}

struct Sig {
	@safe @nogc pure nothrow:

	immutable FileAndPos fileAndPos;
	immutable Sym name;
	immutable Type returnType;
	immutable Arr!Param params;
}
static assert(Sig.sizeof <= 48);

immutable(FileAndRange) range(ref immutable Sig a) {
	return immutable FileAndRange(
		a.fileAndPos.fileIndex,
		immutable RangeWithinFile(a.fileAndPos.pos, safeSizeTToU32(a.fileAndPos.pos + symSize(a.name))));
}

immutable(size_t) arity(ref const Sig a) {
	return a.params.size;
}

struct RecordField {
	//TODO: use NameAndRange (more compact)
	immutable FileAndRange range;
	immutable Bool isMutable;
	immutable Sym name;
	immutable Type type;
	immutable size_t index;
}

immutable(RecordField) withType(ref immutable RecordField a, immutable Type t) {
	return RecordField(a.range, a.isMutable, a.name, t, a.index);
}

enum ForcedByValOrRef {
	byVal,
	byRef,
}

struct StructBody {
	@safe @nogc pure nothrow:
	struct Bogus {}
	struct Builtin {}
	struct ExternPtr {}
	struct Record {
		immutable Opt!ForcedByValOrRef forcedByValOrRef;
		immutable Arr!RecordField fields;
	}
	struct Union {
		immutable Arr!(Ptr!StructInst) members;
	}

	private:
	enum Kind {
		bogus,
		builtin,
		externPtr,
		record,
		union_,
	}
	immutable Kind kind;
	union {
		immutable Bogus bogus;
		immutable Builtin builtin;
		immutable ExternPtr externPtr;
		immutable Record record;
		immutable Union union_;
	}

	public:
	immutable this(immutable Bogus a) { kind = Kind.bogus; bogus = a; }
	immutable this(immutable Builtin a) { kind = Kind.builtin; builtin = a; }
	immutable this(immutable ExternPtr a) { kind = Kind.externPtr; externPtr = a; }
	@trusted immutable this(immutable Record a) { kind = Kind.record; record = a; }
	@trusted immutable this(immutable Union a) { kind = Kind.union_; union_ = a;}
}

immutable(Bool) isBogus(ref immutable StructBody a) {
	return Bool(a.kind == StructBody.Kind.bogus);
}
immutable(Bool) isRecord(ref const StructBody a) {
	return Bool(a.kind == StructBody.Kind.record);
}
@trusted ref const(StructBody.Record) asRecord(return scope ref const StructBody a) {
	verify(a.isRecord);
	return a.record;
}
immutable(Bool) isUnion(ref immutable StructBody a) {
	return Bool(a.kind == StructBody.Kind.union_);
}
@trusted ref immutable(StructBody.Union) asUnion(return scope ref immutable StructBody a) {
	verify(a.isUnion);
	return a.union_;
}

@trusted T matchStructBody(T)(
	ref immutable StructBody a,
	scope T delegate(ref immutable StructBody.Bogus) @safe @nogc pure nothrow cbBogus,
	scope T delegate(ref immutable StructBody.Builtin) @safe @nogc pure nothrow cbBuiltin,
	scope T delegate(ref immutable StructBody.ExternPtr) @safe @nogc pure nothrow cbExternPtr,
	scope T delegate(ref immutable StructBody.Record) @safe @nogc pure nothrow cbRecord,
	scope T delegate(ref immutable StructBody.Union) @safe @nogc pure nothrow cbUnion,
) {
	final switch (a.kind) {
		case StructBody.Kind.bogus:
			return cbBogus(a.bogus);
		case StructBody.Kind.builtin:
			return cbBuiltin(a.builtin);
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
	immutable Bool isPublic;
	immutable Sym name;
	immutable ArrWithSize!TypeParam typeParams_;

	private:
	// This will be none if the alias target is not found
	Late!(immutable Opt!(Ptr!StructInst)) target_;
}

immutable(Arr!TypeParam) typeParams(ref const StructAlias a) {
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
	immutable Bool isPublic;
	immutable Sym name;
	immutable ArrWithSize!TypeParam typeParams_;
	// Note: purity on the decl does not take type args into account
	immutable Purity purity;
	immutable Bool purityIsForced;

	private:
	Late!(immutable StructBody) _body_;
}

immutable(Arr!TypeParam) typeParams(ref immutable StructDecl a) {
	return toArr(a.typeParams_);
}

immutable(Bool) bodyIsSet(ref const StructDecl a) {
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
	immutable Arr!Type typeArgs;

	immutable this(immutable Ptr!StructDecl d, immutable Arr!Type t) {
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

immutable(Bool) isArr(ref immutable StructInst i) {
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

immutable(Arr!Type) typeArgs(ref immutable StructInst i) {
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
		immutable Arr!Sig sigs;
	}

	public:
	immutable this(immutable Builtin a) { kind = Kind.builtin; builtin = a; }
	@trusted immutable this(immutable Arr!Sig a) { kind = Kind.sigs; sigs = a; }
}

@trusted T matchSpecBody(T)(
	ref immutable SpecBody a,
	scope T delegate(ref immutable SpecBody.Builtin) @safe @nogc pure nothrow cbBuiltin,
	scope T delegate(ref immutable Arr!Sig) @safe @nogc pure nothrow cbSigs,
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
		(ref immutable Arr!Sig sigs) => sigs.size);
}

struct SpecDecl {
	// TODO: use NameAndRange (more compact)
	immutable FileAndRange range;
	immutable Bool isPublic;
	immutable Sym name;
	immutable ArrWithSize!TypeParam typeParams_;
	immutable SpecBody body_;
	MutArr!(immutable Ptr!SpecInst) insts;
}

immutable(Arr!TypeParam) typeParams(ref immutable SpecDecl a) {
	return toArr(a.typeParams_);
}

struct SpecDeclAndArgs {
	immutable Ptr!SpecDecl decl;
	immutable Arr!Type typeArgs;
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

ref immutable(Arr!Type) typeArgs(return scope ref immutable SpecInst a) {
	return a.declAndArgs.typeArgs;
}

immutable(Sym) name(ref immutable SpecInst a) {
	return decl(a).name;
}

struct FunBody {
	@safe @nogc pure nothrow:

	struct Builtin {}
	struct Extern {
		immutable Bool isGlobal;
		immutable Str externName;
	}

	private:
	enum Kind {
		builtin,
		extern_,
		expr,
	}
	immutable Kind kind;
	union {
		immutable Builtin builtin;
		immutable Ptr!Extern extern_;
		immutable Ptr!Expr expr;
	}

	public:
	immutable this(immutable Builtin a) { kind = Kind.builtin; builtin = a; }
	@trusted immutable this(immutable Ptr!Extern a) { kind = Kind.extern_; extern_ = a; }
	@trusted immutable this(immutable Ptr!Expr a) { kind = Kind.expr; expr = a; }
}
static assert(FunBody.sizeof <= 16);

immutable(Bool) isExtern(ref immutable FunBody a) {
	return Bool(a.kind == FunBody.Kind.extern_);
}

@trusted immutable(FunBody.Extern) asExtern(ref immutable FunBody a) {
	verify(a.isExtern);
	return a.extern_;
}

@trusted T matchFunBody(T)(
	ref immutable FunBody a,
	scope T delegate(ref immutable FunBody.Builtin) @safe @nogc pure nothrow cbBuiltin,
	scope T delegate(ref immutable FunBody.Extern) @safe @nogc pure nothrow cbExtern,
	scope T delegate(immutable Ptr!Expr) @safe @nogc pure nothrow cbExpr,
) {
	final switch (a.kind) {
		case FunBody.Kind.builtin:
			return cbBuiltin(a.builtin);
		case FunBody.Kind.extern_:
			return cbExtern(a.extern_);
		case FunBody.Kind.expr:
			return cbExpr(a.expr);
	}
}

struct FunFlags {
	immutable Bool noCtx;
	immutable Bool summon;
	immutable Bool unsafe;
	immutable Bool trusted;
}
static assert(FunFlags.sizeof == 4);

struct FunDecl {
	@safe @nogc pure nothrow:

	@disable this(ref const FunDecl);
	this(
		immutable Bool ip,
		immutable FunFlags f,
		immutable Ptr!Sig s,
		immutable ArrWithSize!TypeParam tps,
		immutable ArrWithSize!(Ptr!SpecInst) sps,
	) {
		isPublic = ip;
		flags = f;
		sig = s;
		typeParams_ = tps;
		specs_ = sps;
		body_ = immutable FunBody(immutable FunBody.Builtin());
	}

	immutable Bool isPublic;
	immutable FunFlags flags;
	immutable Ptr!Sig sig;
	immutable ArrWithSize!TypeParam typeParams_;
	immutable ArrWithSize!(Ptr!SpecInst) specs_;
	FunBody body_;
}
static assert(FunDecl.sizeof <= 48);

immutable(Arr!TypeParam) typeParams(ref immutable FunDecl a) {
	return toArr(a.typeParams_);
}
immutable(Arr!(Ptr!SpecInst)) specs(ref immutable FunDecl a) {
	return toArr(a.specs_);
}

immutable(FileAndRange) range(return scope ref immutable FunDecl a) {
	return range(a.sig);
}

immutable(Bool) isExtern(ref immutable FunDecl a) {
	return a.body_.isExtern;
}

immutable(Bool) noCtx(ref const FunDecl a) {
	return a.flags.noCtx;
}
immutable(Bool) summon(ref immutable FunDecl a) {
	return a.flags.summon;
}
immutable(Bool) unsafe(ref immutable FunDecl a) {
	return a.flags.unsafe;
}
immutable(Bool) trusted(ref immutable FunDecl a) {
	return a.flags.trusted;
}

immutable(Sym) name(ref const FunDecl a) {
	return a.sig.name;
}

ref immutable(Type) returnType(return scope ref immutable FunDecl a) {
	return a.sig.returnType;
}

ref immutable(Arr!Param) params(return scope ref immutable FunDecl a) {
	return a.sig.params;
}

private immutable(size_t) nSpecImpls(ref immutable FunDecl a) {
	size_t n = 0;
	foreach (immutable Ptr!SpecInst s; a.specs.range)
		n += s.body_.nSigs;
	return n;
}

immutable(Bool) isTemplate(ref immutable FunDecl a) {
	return Bool(!empty(a.typeParams) || !empty(a.specs));
}

immutable(size_t) arity(ref const FunDecl a) {
	return arity(a.sig);
}

struct FunDeclAndArgs {
	@safe @nogc pure nothrow:

	immutable Ptr!FunDecl decl;
	immutable Arr!Type typeArgs;
	immutable Arr!Called specImpls;

	immutable this(immutable Ptr!FunDecl d, immutable Arr!Type ta, immutable Arr!Called si) {
		decl = d;
		typeArgs = ta;
		specImpls = si;
		verify(typeArgs.sizeEq(decl.typeParams));
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

immutable(Bool) isCompareFun(ref immutable FunInst a) {
	// TODO: only do this for the '<=>' in bootstrap
	return symEq(name(decl(a).deref()), shortSymOperatorLiteral("<=>"));
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

ref immutable(Arr!Param) params(return scope ref immutable FunInst a) {
	return a.sig.params;
}

immutable(Ptr!FunDecl) decl(ref immutable FunInst a) {
	return a.funDeclAndArgs.decl;
}

immutable(Arr!Type) typeArgs(ref immutable FunInst a) {
	return a.funDeclAndArgs.typeArgs;
}

immutable(Arr!Called) specImpls(ref immutable FunInst a) {
	return a.funDeclAndArgs.specImpls;
}

immutable(Bool) noCtx(ref immutable FunInst a) {
	return decl(a).deref.noCtx;
}

immutable(size_t) arity(ref immutable FunInst a) {
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

ref immutable(Arr!Param) params(return scope ref immutable CalledDecl a) {
	return a.sig.params;
}

immutable(Arr!TypeParam) typeParams(return scope ref immutable CalledDecl a) {
	return matchCalledDecl(
		a,
		(immutable Ptr!FunDecl f) => f.typeParams,
		(ref immutable SpecSig) => emptyArr!TypeParam);
}

immutable(size_t) arity(ref immutable CalledDecl a) {
	return params(a).size;
}

immutable(size_t) nTypeParams(ref immutable CalledDecl a) {
	return a.typeParams.size;
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

@trusted ref immutable(Sig) sig(ref immutable Called a) {
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

ref immutable(Type) returnType(ref immutable Called a) {
	return a.sig.returnType;
}

ref immutable(Arr!Param) params(ref immutable Called a) {
	return a.sig.params;
}

immutable(size_t) arity(ref immutable Called a) {
	return a.sig.arity;
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

immutable(Arr!TypeParam) typeParams(ref immutable StructOrAlias a) {
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

immutable(Bool) isPublic(ref immutable StructOrAlias a) {
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

alias StructsAndAliasesMap = Dict!(Sym, StructOrAlias, compareSym);
alias SpecsMap = Dict!(Sym, Ptr!SpecDecl, compareSym);
alias FunsMap = MultiDict!(Sym, Ptr!FunDecl, compareSym);

struct Module {
	@safe @nogc pure nothrow:

	immutable FileIndex fileIndex;
	private:
	immutable Ptr!ModuleImportsExports importsAndExports_;
	immutable Ptr!ModuleArrs arrs_;
	immutable Ptr!ModuleDicts dicts_;

	public:
	//TODO:NOT INSTANCE
	ref immutable(Arr!ModuleAndNameReferents) imports() immutable {
		return importsAndExports_.imports;
	}

	ref immutable(Arr!ModuleAndNameReferents) exports() immutable {
		return importsAndExports_.exports;
	}

	ref immutable(Arr!StructDecl) structs() immutable {
		return arrs_.structs;
	}

	ref immutable(Arr!SpecDecl) specs() immutable {
		return arrs_.specs;
	}

	ref immutable(Arr!FunDecl) funs() immutable {
		return arrs_.funs;
	}

	ref immutable(StructsAndAliasesMap) structsAndAliasesMap() immutable {
		return dicts_.structsAndAliasesMap;
	}

	ref immutable(SpecsMap) specsMap() immutable {
		return dicts_.specsMap;
	}

	ref immutable(FunsMap) funsMap() immutable {
		return dicts_.funsMap;
	}
}
static assert(Module.sizeof <= 48);

struct ModuleImportsExports {
	immutable Arr!ModuleAndNameReferents imports;
	immutable Arr!ModuleAndNameReferents exports;
}

struct ModuleArrs {
	immutable Arr!StructDecl structs;
	immutable Arr!SpecDecl specs;
	immutable Arr!FunDecl funs;
}

struct ModuleDicts {
	// WARN: these include private names
	immutable StructsAndAliasesMap structsAndAliasesMap;
	immutable SpecsMap specsMap;
	immutable FunsMap funsMap;
}


struct ModuleAndNameReferents {
	immutable Ptr!Module module_;
	immutable Opt!(Arr!NameAndReferents) namesAndReferents;
}

struct NameAndReferents {
	immutable Sym name;
	// These may all be empty if the name didn't refer to anything
	immutable Opt!(StructOrAlias) structOrAlias;
	immutable Opt!(Ptr!SpecDecl) spec;
	immutable Arr!(Ptr!FunDecl) funs;
}

enum FunKind {
	ptr,
	plain,
	mut,
	ref_,
}

struct FunKindAndStructs {
	immutable FunKind kind;
	immutable Arr!(Ptr!StructDecl) structs;
}

struct CommonTypes {
	@safe @nogc pure nothrow:

	@disable this(ref const CommonTypes);
	immutable this(
		immutable Ptr!StructInst b,
		immutable Ptr!StructInst c,
		immutable Ptr!StructInst i32,
		immutable Ptr!StructInst s,
		immutable Ptr!StructInst v,
		immutable Ptr!StructInst ap,
		immutable Arr!(Ptr!StructDecl) o,
		immutable Ptr!StructDecl bv,
		immutable Ptr!StructDecl a,
		immutable Ptr!StructDecl f,
		immutable Arr!FunKindAndStructs fks,
	) {
		bool_ = b;
		char_ = c;
		int32 = i32;
		str = s;
		void_ = v;
		anyPtr = ap;
		optionSomeNone = o;
		byVal = bv;
		arr = a;
		fut = f;
		funKindsAndStructs = fks;
	}

	immutable Ptr!StructInst bool_;
	immutable Ptr!StructInst char_;
	immutable Ptr!StructInst int32;
	immutable Ptr!StructInst str;
	immutable Ptr!StructInst void_;
	immutable Ptr!StructInst anyPtr;
	immutable Arr!(Ptr!StructDecl) optionSomeNone;
	immutable Ptr!StructDecl byVal;
	immutable Ptr!StructDecl arr;
	immutable Ptr!StructDecl fut;
	immutable Arr!FunKindAndStructs funKindsAndStructs;
}

immutable(Opt!FunKind) getFunStructInfo(ref immutable CommonTypes a, immutable Ptr!StructDecl s) {
	//TODO: use arrUtils
	foreach (ref immutable FunKindAndStructs fs; a.funKindsAndStructs.range)
		foreach (immutable Ptr!StructDecl funStruct; fs.structs.range)
			if (ptrEquals(s, funStruct))
				return some(fs.kind);
	return none!FunKind;
}

struct Program {
	@safe @nogc pure nothrow:

	@disable this(ref const Program);
	immutable this(
		immutable Ptr!FilesInfo f,
		immutable Ptr!SpecialModules s,
		immutable Arr!(Ptr!Module) all,
		immutable Ptr!CommonTypes ct,
		immutable Ptr!StructInst ctx,
	) {
		filesInfo = f;
		specialModules = s;
		allModules = all;
		commonTypes = ct;
		ctxStructInst = ctx;
	}

	immutable Ptr!FilesInfo filesInfo;
	immutable Ptr!SpecialModules specialModules;
	immutable Arr!(Ptr!Module) allModules;
	immutable Ptr!CommonTypes commonTypes;
	immutable Ptr!StructInst ctxStructInst;
}
static assert(Program.sizeof <= 48);

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
		immutable Arr!Expr args;
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

	struct CreateArr {
		immutable Ptr!StructInst arrType;
		immutable Arr!Expr args;
	}

	struct CreateRecord {
		immutable Ptr!StructInst structInst;
		immutable Arr!Expr args;
	}

	struct ImplicitConvertToUnion {
		immutable Ptr!StructInst unionType;
		immutable u8 memberIndex;
		immutable Ptr!Expr inner;
	}

	// type is the lambda's type (not the body's return type), e.g. a Fun1 or sendFun1 instance.
	struct Lambda {
		immutable Arr!Param params;
		immutable Ptr!Expr body_;
		immutable Arr!(Ptr!ClosureField) closure;
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

	struct LocalRef {
		immutable Ptr!Local local;
	}

	struct Match {
		struct Case {
			immutable Opt!(Ptr!Local) local;
			immutable Ptr!Expr then;
		}

		immutable Ptr!Expr matched;
		immutable Ptr!StructInst matchedUnion;
		immutable Arr!Case cases;
		immutable Type type;
	}

	struct ParamRef {
		immutable Ptr!Param param;
	}

	struct RecordFieldAccess {
		immutable Ptr!Expr target;
		immutable Ptr!StructInst targetType;
		immutable Ptr!RecordField field; // This is the field from the StructInst, not the StructDecl
	}

	struct RecordFieldSet {
		@safe @nogc pure nothrow:
		immutable Ptr!Expr target;
		immutable Ptr!StructInst targetType;
		immutable Ptr!RecordField field;
		immutable Ptr!Expr value;

		immutable this(
			immutable Ptr!Expr t,
			immutable Ptr!StructInst tt,
			immutable Ptr!RecordField f,
			immutable Ptr!Expr v,
		) {
			target = t;
			targetType = tt;
			field = f;
			value = v;
			verify(field.isMutable);
		}
	}

	struct Seq {
		immutable(Ptr!Expr) first;
		immutable(Ptr!Expr) then;
	}

	struct StringLiteral {
		immutable Str literal;
	}

	private:
	enum Kind {
		bogus,
		call,
		closureFieldRef,
		cond,
		createArr,
		createRecord,
		implicitConvertToUnion,
		lambda,
		let,
		localRef,
		match,
		paramRef,
		recordFieldAccess,
		recordFieldSet,
		seq,
		stringLiteral,
	}

	immutable FileAndRange range_;
	immutable Kind kind;
	union {
		immutable Bogus bogus;
		immutable Call call;
		immutable ClosureFieldRef closureFieldRef;
		immutable Cond cond;
		immutable CreateArr createArr;
		immutable CreateRecord createRecord;
		immutable ImplicitConvertToUnion implicitConvertToUnion;
		immutable Lambda lambda;
		immutable Let let;
		immutable LocalRef localRef;
		immutable Match match_;
		immutable ParamRef paramRef;
		immutable RecordFieldAccess recordFieldAccess;
		immutable RecordFieldSet recordFieldSet;
		immutable Seq seq;
		immutable StringLiteral stringLiteral;
	}

	public:
	immutable this(immutable FileAndRange r, immutable Bogus a) { range_ = r; kind = Kind.bogus; bogus = a; }
	@trusted immutable this(immutable FileAndRange r, immutable Call a) { range_ = r; kind = Kind.call; call = a; }
	@trusted immutable this(immutable FileAndRange r, immutable ClosureFieldRef a) {
		range_ = r; kind = Kind.closureFieldRef; closureFieldRef = a;
	}
	@trusted immutable this(immutable FileAndRange r, immutable Cond a) { range_ = r; kind = Kind.cond; cond = a; }
	@trusted immutable this(immutable FileAndRange r, immutable CreateArr a) {
		range_ = r; kind = Kind.createArr; createArr = a;
	}
	@trusted immutable this(immutable FileAndRange r, immutable CreateRecord a) {
		range_ = r; kind = Kind.createRecord; createRecord = a;
	}
	@trusted immutable this(immutable FileAndRange r, immutable ImplicitConvertToUnion a) {
		range_ = r; kind = Kind.implicitConvertToUnion; implicitConvertToUnion = a;
	}
	@trusted immutable this(immutable FileAndRange r, immutable Lambda a) {
		range_ = r; kind = Kind.lambda; lambda = a;
	}
	@trusted immutable this(immutable FileAndRange r, immutable Let a) { range_ = r; kind = Kind.let; let = a; }
	@trusted immutable this(immutable FileAndRange r, immutable LocalRef a) {
		range_ = r; kind = Kind.localRef; localRef = a;
	}
	@trusted immutable this(immutable FileAndRange r, immutable Match a) { range_ = r; kind = Kind.match; match_ = a; }
	@trusted immutable this(immutable FileAndRange r, immutable ParamRef a) {
		range_ = r; kind = Kind.paramRef; paramRef = a;
	}
	@trusted immutable this(immutable FileAndRange r, immutable RecordFieldAccess a) {
		range_ = r; kind = Kind.recordFieldAccess; recordFieldAccess = a;
	}
	@trusted immutable this(immutable FileAndRange r, immutable RecordFieldSet a) {
		range_ = r; kind = Kind.recordFieldSet; recordFieldSet = a;
	}
	@trusted immutable this(immutable FileAndRange r, immutable Seq a) { range_ = r; kind = Kind.seq; seq = a; }
	@trusted immutable this(immutable FileAndRange r, immutable StringLiteral a) {
		range_ = r; kind = Kind.stringLiteral; stringLiteral = a;
	}
}

ref immutable(Type) elementType(ref immutable Expr.CreateArr a) {
	return only(typeArgs(a.arrType));
}

//TODO:KILL (just write field.type everywhere)
immutable(Type) accessedFieldType(ref immutable Expr.RecordFieldAccess a) {
	return a.field.type;
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
	scope T delegate(ref immutable Expr.CreateArr) @safe @nogc pure nothrow cbCreateArr,
	scope T delegate(ref immutable Expr.CreateRecord) @safe @nogc pure nothrow cbCreateRecord,
	scope T delegate(ref immutable Expr.ImplicitConvertToUnion) @safe @nogc pure nothrow cbImplicitConvertToUnion,
	scope T delegate(ref immutable Expr.Lambda) @safe @nogc pure nothrow cbLambda,
	scope T delegate(ref immutable Expr.Let) @safe @nogc pure nothrow cbLet,
	scope T delegate(ref immutable Expr.LocalRef) @safe @nogc pure nothrow cbLocalRef,
	scope T delegate(ref immutable Expr.Match) @safe @nogc pure nothrow cbMatch,
	scope T delegate(ref immutable Expr.ParamRef) @safe @nogc pure nothrow cbParamRef,
	scope T delegate(ref immutable Expr.RecordFieldAccess) @safe @nogc pure nothrow cbRecordFieldAccess,
	scope T delegate(ref immutable Expr.RecordFieldSet) @safe @nogc pure nothrow cbRecordFieldSet,
	scope T delegate(ref immutable Expr.Seq) @safe @nogc pure nothrow cbSeq,
	scope T delegate(ref immutable Expr.StringLiteral) @safe @nogc pure nothrow cbStringLiteral,
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
		case Expr.Kind.createArr:
			return cbCreateArr(a.createArr);
		case Expr.Kind.createRecord:
			return cbCreateRecord(a.createRecord);
		case Expr.Kind.implicitConvertToUnion:
			return cbImplicitConvertToUnion(a.implicitConvertToUnion);
		case Expr.Kind.lambda:
			return cbLambda(a.lambda);
		case Expr.Kind.let:
			return cbLet(a.let);
		case Expr.Kind.localRef:
			return cbLocalRef(a.localRef);
		case Expr.Kind.match:
			return cbMatch(a.match_);
		case Expr.Kind.paramRef:
			return cbParamRef(a.paramRef);
		case Expr.Kind.recordFieldAccess:
			return cbRecordFieldAccess(a.recordFieldAccess);
		case Expr.Kind.recordFieldSet:
			return cbRecordFieldSet(a.recordFieldSet);
		case Expr.Kind.seq:
			return cbSeq(a.seq);
		case Expr.Kind.stringLiteral:
			return cbStringLiteral(a.stringLiteral);
	}
}

immutable(Bool) typeIsBogus(ref immutable Expr a) {
	return matchExpr!(immutable Bool)(
		a,
		(ref immutable Expr.Bogus) => True,
		(ref immutable Expr.Call e) => e.called.returnType.isBogus,
		(ref immutable Expr.ClosureFieldRef e) => e.field.type.isBogus,
		(ref immutable Expr.Cond e) => e.type.isBogus,
		(ref immutable Expr.CreateArr) => False,
		(ref immutable Expr.CreateRecord) => False,
		(ref immutable Expr.ImplicitConvertToUnion) => False,
		(ref immutable Expr.Lambda) => False,
		(ref immutable Expr.Let e) => e.then.typeIsBogus,
		(ref immutable Expr.LocalRef e) => e.local.type.isBogus,
		(ref immutable Expr.Match e) => e.type.isBogus,
		(ref immutable Expr.ParamRef e) => e.param.type.isBogus,
		(ref immutable Expr.RecordFieldAccess e) => e.field.type.isBogus,
		(ref immutable Expr.RecordFieldSet e) => False,
		(ref immutable Expr.Seq e) => e.then.typeIsBogus,
		(ref immutable Expr.StringLiteral e) => False);
}

immutable(Type) getType(ref immutable Expr a, ref immutable CommonTypes commonTypes) {
	return matchExpr!(immutable Type)(
		a,
		(ref immutable Expr.Bogus) => immutable Type(immutable Type.Bogus()),
		(ref immutable Expr.Call e) => e.called.returnType,
		(ref immutable Expr.ClosureFieldRef e) => e.field.type,
		(ref immutable Expr.Cond) => todo!(immutable Type)("getType cond"),
		(ref immutable Expr.CreateArr e) => immutable Type(e.arrType),
		(ref immutable Expr.CreateRecord e) => immutable Type(e.structInst),
		(ref immutable Expr.ImplicitConvertToUnion e) => immutable Type(e.unionType),
		(ref immutable Expr.Lambda e) => immutable Type(e.type),
		(ref immutable Expr.Let e) => e.then.getType(commonTypes),
		(ref immutable Expr.LocalRef e) => e.local.type,
		(ref immutable Expr.Match) => todo!(immutable Type)("getType match"),
		(ref immutable Expr.ParamRef e) => e.param.type,
		(ref immutable Expr.RecordFieldAccess e) => e.field.type,
		(ref immutable Expr.RecordFieldSet e) => immutable Type(commonTypes.void_),
		(ref immutable Expr.Seq e) => e.then.getType(commonTypes),
		(ref immutable Expr.StringLiteral) => immutable Type(commonTypes.str));
}

void writeStructInst(Alloc)(ref Writer!Alloc writer, ref immutable StructInst s) {
	writeSym(writer, s.decl.name);
	if (!s.typeArgs.empty) {
		Bool first = True;
		foreach (ref immutable Type t; s.typeArgs.range) {
			writeChar(writer, first ? '<' : ' ');
			writeType(writer, t);
			first = False;
		}
		writeChar(writer, '>');
	}
}

void writeType(Alloc)(ref Writer!Alloc writer, ref immutable Type type) {
	return matchType!void(
		type,
		(ref immutable Type.Bogus) {
			writeStatic(writer, "<<bogus>>");
		},
		(immutable Ptr!TypeParam p) {
			writeChar(writer, '?');
			writeSym(writer, p.name);
		},
		(immutable Ptr!StructInst s) {
			writeStructInst(writer, s);
		});
}
