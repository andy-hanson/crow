module model.model;

@safe @nogc pure nothrow:

import model.concreteModel : TypeSize;
import model.constant : Constant;
import model.diag : Diagnostics, FilesInfo; // TODO: move FilesInfo here?
import util.col.arr : empty, only, PtrAndSmallNumber, small, SmallArray;
import util.col.arrUtil : arrEqual, exists;
import util.col.dict : Dict;
import util.col.enumDict : EnumDict;
import util.col.fullIndexDict : FullIndexDict;
import util.col.mutArr : MutArr;
import util.col.str : SafeCStr;
import util.hash : Hasher;
import util.late : Late, lateGet, lateIsSet, lateSet;
import util.lineAndColumnGetter : LineAndColumnGetter;
import util.opt : force, has, Opt, some;
import util.path : Path;
import util.ptr : hashPtr;
import util.sourceRange :
	FileAndPos,
	FileAndRange,
	fileAndRangeFromFileAndPos,
	FileIndex,
	rangeOfStartAndName,
	RangeWithinFile;
import util.sym : AllSymbols, Sym, sym, writeSym;
import util.union_ : Union;
import util.util : as, max, min, unreachable, verify;
import util.writer : Writer, writeWithCommas;

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

immutable(PurityRange) combinePurityRange(immutable PurityRange a, immutable PurityRange b) =>
	immutable PurityRange(worsePurity(a.bestCase, b.bestCase), worsePurity(a.worstCase, b.worstCase));

immutable(bool) isPurityAlwaysCompatible(immutable Purity referencer, immutable PurityRange referenced) =>
	referenced.worstCase <= referencer;

immutable(bool) isPurityPossiblyCompatible(immutable Purity referencer, immutable PurityRange referenced) =>
	referenced.bestCase <= referencer;

immutable(Purity) worsePurity(immutable Purity a, immutable Purity b) =>
	max(a, b);

immutable(Sym) symOfPurity(immutable Purity a) {
	final switch (a) {
		case Purity.data:
			return sym!"data";
		case Purity.sendable:
			return sym!"sendable";
		case Purity.mut:
			return sym!"mut";
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

	mixin Union!(immutable Bogus, immutable TypeParam*, immutable StructInst*);

	immutable(bool) opEquals(scope immutable Type b) scope immutable =>
		matchWithPointers!(immutable bool)(
			(immutable Type.Bogus) =>
				b.isA!(Type.Bogus),
			(immutable TypeParam* p) =>
				b.isA!(TypeParam*) && b.as!(TypeParam*) == p,
			(immutable StructInst* i) =>
				b.isA!(StructInst*) && b.as!(StructInst*) == i);

	void hash(ref Hasher hasher) scope immutable {
		matchWithPointers!void(
			(immutable Type.Bogus) {},
			(immutable TypeParam* p) =>
				hashPtr(hasher, p),
			(immutable StructInst* i) =>
				hashPtr(hasher, i));
	}
}
static assert(Type.sizeof == ulong.sizeof);

immutable(PurityRange) purityRange(immutable Type a) =>
	a.match!(immutable PurityRange)(
		(immutable Type.Bogus) =>
			immutable PurityRange(Purity.data, Purity.data),
		(ref immutable(TypeParam)) =>
			immutable PurityRange(Purity.data, Purity.mut),
		(ref immutable StructInst i) =>
			i.purityRange);

immutable(Purity) bestCasePurity(immutable Type a) =>
	purityRange(a).bestCase;

immutable(Purity) worstCasePurity(immutable Type a) =>
	purityRange(a).worstCase;

immutable(LinkageRange) linkageRange(immutable Type a) =>
	a.match!(immutable LinkageRange)(
		(immutable Type.Bogus) =>
			immutable LinkageRange(Linkage.extern_, Linkage.extern_),
		(ref immutable(TypeParam)) =>
			immutable LinkageRange(Linkage.internal, Linkage.extern_),
		(ref immutable StructInst i) =>
			i.linkageRange);

struct Param {
	@safe @nogc pure nothrow:

	//TODO: use NameAndRange (more compact)
	immutable FileAndRange range;
	immutable Opt!Sym name;
	immutable Type type;
	immutable size_t index;

	immutable(Sym) nameOrUnderscore() immutable =>
		has(name) ? force(name) : sym!"_";

	immutable(RangeWithinFile) nameRange(ref const AllSymbols allSymbols) immutable =>
		rangeOfStartAndName(range.range.start, nameOrUnderscore, allSymbols);
}

immutable(Param) withType(ref immutable Param a, immutable Type t) =>
	immutable Param(a.range, a.name, t, a.index);

struct Params {
	struct Varargs {
		immutable Param param;
		immutable Type elementType;
	}

	mixin Union!(immutable SmallArray!Param, immutable Varargs*);
}
static assert(Params.sizeof == ulong.sizeof);

immutable(Param[]) paramsArray(immutable Params a) =>
	a.matchWithPointers!(immutable Param[])(
		(immutable Param[] p) =>
			p,
		(immutable Params.Varargs* v) @trusted =>
			(&v.param)[0 .. 1]);

immutable(Param[]) assertNonVariadic(immutable Params a) =>
	a.as!(immutable Param[]);

struct Arity {
	struct Varargs {}
	mixin Union!(immutable size_t, immutable Varargs);
}

immutable(bool) arityIsNonZero(immutable Arity a) =>
	a.match!(immutable bool)(
		(immutable size_t size) =>
			size != 0,
		(immutable Arity.Varargs) =>
			true);

immutable(bool) arityMatches(immutable Arity sigArity, immutable size_t nArgs) =>
	sigArity.match!(immutable bool)(
		(immutable size_t nParams) =>
			nParams == nArgs,
		(immutable Arity.Varargs) =>
			true);

immutable(Arity) arity(scope immutable Params a) =>
	a.match!(immutable Arity)(
		(immutable Param[] params) =>
			immutable Arity(params.length),
		(ref immutable Params.Varargs) =>
			immutable Arity(immutable Arity.Varargs()));

struct SpecDeclSig {
	@safe @nogc pure nothrow:

	immutable SafeCStr docComment;
	immutable FileAndPos fileAndPos;
	immutable Sym name;
	immutable Type returnType;
	immutable Params params;
}

immutable(Arity) arity(scope ref immutable SpecDeclSig a) =>
	arity(a.params);

enum FieldMutability {
	const_,
	private_,
	public_,
}

immutable(Sym) symOfFieldMutability(immutable FieldMutability a) {
	final switch (a) {
		case FieldMutability.const_:
			return sym!"const";
		case FieldMutability.private_:
			return sym!"private";
		case FieldMutability.public_:
			return sym!"public";
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

immutable(RecordField) withType(ref immutable RecordField a, immutable Type t) =>
	immutable RecordField(a.range, a.visibility, a.name, a.mutability, t, a.index);

struct UnionMember {
	//TODO: use NameAndRange (more compact)
	immutable FileAndRange range;
	immutable Sym name;
	immutable Opt!Type type;
}

immutable(UnionMember) withType(ref immutable UnionMember a, immutable Type t) =>
	immutable UnionMember(a.range, a.name, some(t));

enum ForcedByValOrRefOrNone {
	none,
	byVal,
	byRef,
}

immutable(Sym) symOfForcedByValOrRefOrNone(immutable ForcedByValOrRefOrNone a) {
	final switch (a) {
		case ForcedByValOrRefOrNone.none:
			return sym!"none";
		case ForcedByValOrRefOrNone.byVal:
			return sym!"by-val";
		case ForcedByValOrRefOrNone.byRef:
			return sym!"by-ref";
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
	struct Extern {
		immutable Opt!TypeSize size;
	}
	struct Flags {
		alias Member = Enum.Member;
		immutable EnumBackingType backingType;
		// For Flags, members should be unsigned
		immutable Member[] members;
	}
	struct Record {
		immutable RecordFlags flags;
		immutable RecordField[] fields;
	}
	struct Union {
		immutable UnionMember[] members;
	}

	mixin .Union!(
		immutable Bogus,
		immutable Builtin,
		immutable Enum,
		immutable Extern,
		immutable Flags,
		immutable Record,
		immutable Union);
}
static assert(StructBody.sizeof == size_t.sizeof + StructBody.Record.sizeof);


struct StructAlias {
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

immutable(Opt!(StructInst*)) target(ref immutable StructAlias a) =>
	lateGet(a.target_);
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

immutable(LinkageRange) combineLinkageRange(immutable LinkageRange referencer, immutable LinkageRange referenced) =>
	immutable LinkageRange(
		lessStrictLinkage(referencer.leastStrict, referenced.leastStrict),
		lessStrictLinkage(referencer.mostStrict, referenced.mostStrict));

private immutable(Linkage) lessStrictLinkage(immutable Linkage a, immutable Linkage b) =>
	min(a, b);

immutable(bool) isLinkagePossiblyCompatible(immutable Linkage referencer, immutable LinkageRange referenced) =>
	referenced.mostStrict >= referencer;

immutable(bool) isLinkageAlwaysCompatible(immutable Linkage referencer, immutable LinkageRange referenced) =>
	referenced.leastStrict >= referencer;

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

immutable(bool) isTemplate(scope ref immutable StructDecl a) =>
	!empty(a.typeParams);

immutable(bool) bodyIsSet(ref const StructDecl a) =>
	lateIsSet(a._body_);

ref const(StructBody) body_(scope return ref const StructDecl a) =>
	lateGet(a._body_);
ref immutable(StructBody) body_(scope return ref immutable StructDecl a) =>
	lateGet(a._body_);

void setBody(ref StructDecl a, immutable StructBody value) {
	lateSet(a._body_, value);
}

struct StructDeclAndArgs {
	@safe @nogc pure nothrow:

	immutable StructDecl* decl;
	immutable Type[] typeArgs;

	immutable(bool) opEquals(scope immutable StructDeclAndArgs b) scope immutable =>
		decl == b.decl &&
			arrEqual!(immutable Type)(typeArgs, b.typeArgs, (ref immutable Type ta, ref immutable Type tb) =>
				ta == tb);

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

immutable(bool) hasMutableField(scope ref immutable StructInst a) {
	immutable StructBody body_ = body_(*decl(a));
	return body_.isA!(StructBody.Record) &&
		exists!(immutable RecordField)(body_.as!(StructBody.Record).fields, (scope ref immutable RecordField x) =>
			x.mutability != FieldMutability.const_);
}

immutable(bool) isDefinitelyByRef(scope ref immutable StructInst a) {
	immutable StructBody body_ = body_(*decl(a));
	return body_.isA!(StructBody.Record) &&
		body_.as!(StructBody.Record).flags.forcedByValOrRef == ForcedByValOrRefOrNone.byRef;
}

immutable(bool) isArray(ref immutable StructInst i) {
	// TODO: only do this for the arr in bootstrap, not anything named 'arr'
	return decl(i).name == sym!"array";
}

immutable(Sym) name(ref immutable StructInst i) =>
	decl(i).name;

const(StructDecl*) decl(ref const StructInst i) =>
	i.declAndArgs.decl;
immutable(StructDecl*) decl(ref immutable StructInst i) =>
	i.declAndArgs.decl;

ref immutable(Type[]) typeArgs(scope return ref immutable StructInst i) =>
	i.declAndArgs.typeArgs;

ref immutable(StructBody) body_(scope return ref immutable StructInst a) =>
	lateGet(a._body_);

void setBody(ref StructInst a, immutable StructBody value) {
	lateSet(a._body_, value);
}

struct SpecBody {
	struct Builtin {
		enum Kind {
			data,
			send,
		}
		immutable Kind kind;
	}
	mixin Union!(immutable Builtin, immutable SmallArray!SpecDeclSig);
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

	immutable(bool) opEquals(scope immutable SpecDeclAndArgs b) scope immutable =>
		decl == b.decl &&
			arrEqual!(immutable Type)(typeArgs, b.typeArgs, (ref immutable Type ta, ref immutable Type tb) =>
				ta == tb);

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

immutable(SpecDecl*) decl(ref immutable SpecInst a) =>
	a.declAndArgs.decl;

immutable(Type[]) typeArgs(return scope ref immutable SpecInst a) =>
	a.declAndArgs.typeArgs;

immutable(Sym) name(ref immutable SpecInst a) =>
	decl(a).name;

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
			return sym!"==";
		case EnumFunction.intersect:
			return sym!"&";
		case EnumFunction.members:
			return sym!"members";
		case EnumFunction.toIntegral:
			return sym!"to-integral";
		case EnumFunction.union_:
			return sym!"|";
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
			return sym!"all";
		case FlagsFunction.negate:
			return sym!"~";
		case FlagsFunction.new_:
			return sym!"new";
	}
}

struct FunBody {
	@safe @nogc pure nothrow:

	struct Bogus {}
	struct Builtin {}
	struct CreateEnum {
		immutable EnumValue value;
	}
	struct CreateExtern {}
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
	struct ThreadLocal {}

	mixin Union!(
		immutable Bogus,
		immutable Builtin,
		immutable CreateEnum,
		immutable CreateExtern,
		immutable CreateRecord,
		immutable CreateUnion,
		immutable EnumFunction,
		immutable Extern,
		immutable Expr,
		immutable FileBytes,
		immutable FlagsFunction,
		immutable RecordFieldGet,
		immutable RecordFieldSet,
		immutable ThreadLocal);
}

struct FunFlags {
	@safe @nogc pure nothrow:

	immutable bool noCtx;
	immutable bool noDoc;
	immutable bool summon;
	enum Safety : ubyte { safe, unsafe, trusted }
	immutable Safety safety;
	immutable bool preferred;
	immutable bool okIfUnused;
	// generated functions like record field getters are also builtins
	enum SpecialBody : ubyte { none, builtin, extern_, global, threadLocal }
	immutable SpecialBody specialBody;
	immutable bool forceCtx;

	immutable(FunFlags) withOkIfUnused() immutable =>
		immutable FunFlags(noDoc, noCtx, summon, safety, preferred, true, specialBody);

	static immutable(FunFlags) none() =>
		immutable FunFlags(false, false, false, Safety.safe, false, false, SpecialBody.none);
	static immutable(FunFlags) generatedNoCtx() =>
		immutable FunFlags(true, true, false, Safety.safe, false, true, SpecialBody.builtin);
	static immutable(FunFlags) generatedNoCtxUnsafe() =>
		immutable FunFlags(true, true, false, Safety.unsafe, false, true, SpecialBody.builtin);
	static immutable(FunFlags) generatedPreferred() =>
		immutable FunFlags(false, true, false, Safety.safe, true, true, SpecialBody.builtin);
	static immutable(FunFlags) unsafeSummon() =>
		immutable FunFlags(false, false, true, Safety.unsafe, false, false, SpecialBody.none);
}
static assert(FunFlags.sizeof == 8);

struct FunDecl {
	@safe @nogc pure nothrow:

	@disable this(ref const FunDecl);

	this(
		immutable SafeCStr dc,
		immutable Visibility v,
		immutable FileAndPos fp,
		immutable Sym n,
		immutable TypeParam[] tps,
		immutable Type rt,
		immutable Params pms,
		immutable FunFlags f,
		immutable SpecInst*[] sps,
		immutable FunBody b,
	) {
		docComment = dc;
		visibility = v;
		fileAndPos = fp;
		name = n;
		flags = f;
		returnType = rt;
		params = pms;
		typeParams = small(tps);
		specs = sps;
		body_ = b;
	}

	immutable SafeCStr docComment;
	immutable Visibility visibility;
	immutable FileAndPos fileAndPos;
	immutable Sym name;
	immutable FunFlags flags;
	immutable Type returnType;
	immutable Params params;
	immutable SmallArray!TypeParam typeParams;
	immutable SmallArray!(SpecInst*) specs;
	FunBody body_;

	immutable(FileAndRange) range() immutable {
		// TODO: end position
		return fileAndRangeFromFileAndPos(fileAndPos);
	}

	immutable(RangeWithinFile) nameRange(ref const AllSymbols allSymbols) immutable =>
		rangeOfStartAndName(fileAndPos.pos, name, allSymbols);
}

immutable(Linkage) linkage(ref immutable FunDecl a) =>
	a.body_.isA!(FunBody.Extern) ? Linkage.extern_ : Linkage.internal;

immutable(bool) noCtx(ref const FunDecl a) =>
	a.flags.noCtx;
immutable(bool) noDoc(ref immutable FunDecl a) =>
	a.flags.noDoc;
immutable(bool) summon(ref immutable FunDecl a) =>
	a.flags.summon;
immutable(bool) unsafe(ref immutable FunDecl a) =>
	a.flags.safety == FunFlags.Safety.unsafe;
immutable(bool) okIfUnused(ref immutable FunDecl a) =>
	a.flags.okIfUnused;

immutable(bool) isVariadic(ref immutable FunDecl a) =>
	a.params.isA!(Params.Varargs*);

immutable(bool) isTemplate(ref immutable FunDecl a) =>
	!empty(a.typeParams) || !empty(a.specs);

immutable(Arity) arity(ref const FunDecl a) =>
	arity(a.params);

struct Test {
	immutable Expr body_;
}

struct FunDeclAndTypeArgs {
	immutable FunDecl* decl;
	immutable Type[] typeArgs;
}

struct FunDeclAndArgs {
	@safe @nogc pure nothrow:

	immutable FunDecl* decl;
	immutable Type[] typeArgs;
	immutable Called[] specImpls;

	immutable(bool) opEquals(scope immutable FunDeclAndArgs b) scope immutable =>
		decl == b.decl &&
			arrEqual!Type(typeArgs, b.typeArgs, (ref immutable Type ta, ref immutable Type tb) =>
				ta == tb) &&
			arrEqual!Called(specImpls, b.specImpls, (ref immutable Called ca, ref immutable Called cb) =>
				ca == cb);

	void hash(ref Hasher hasher) scope immutable {
		hashPtr(hasher, decl);
		foreach (immutable Type t; typeArgs)
			t.hash(hasher);
		foreach (ref immutable Called c; specImpls)
			c.hash(hasher);
	}
}

struct FunInst {
	@safe @nogc pure nothrow:

	immutable FunDeclAndArgs funDeclAndArgs;
	immutable Type returnType;
	immutable Params params;

	immutable(Sym) name() scope immutable =>
		decl(this).name;
}

immutable(FunDecl*) decl(return scope ref immutable FunInst a) =>
	a.funDeclAndArgs.decl;

immutable(Type[]) typeArgs(ref immutable FunInst a) =>
	a.funDeclAndArgs.typeArgs;

immutable(Called[]) specImpls(ref immutable FunInst a) =>
	a.funDeclAndArgs.specImpls;

immutable(Arity) arity(ref immutable FunInst a) =>
	arity(*decl(a));

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

immutable(Sym) name(ref immutable SpecSig a) =>
	a.sig.name;

// Like 'Called', but we haven't fully instantiated yet. (This is used for Candidate when checking a call expr.)
struct CalledDecl {
	@safe @nogc pure nothrow:

	mixin Union!(immutable FunDecl*, immutable SpecSig);

	immutable(Sym) name() scope immutable =>
		match!(immutable Sym)(
			(ref immutable FunDecl f) => f.name,
			(immutable SpecSig s) => s.name);

	immutable(TypeParam[]) typeParams() immutable =>
		match!(immutable TypeParam[])(
			(ref immutable FunDecl f) => f.typeParams.toArray,
			(immutable SpecSig) => .as!(TypeParam[])([]));

	immutable(Type) returnType() scope immutable =>
		match!(immutable Type)(
			(ref immutable FunDecl f) => f.returnType,
			(immutable SpecSig s) => s.sig.returnType);

	immutable(Params) params() scope immutable =>
		match!(immutable Params)(
			(ref immutable FunDecl f) => f.params,
			(immutable SpecSig s) => s.sig.params);
}

immutable(Arity) arity(ref immutable CalledDecl a) =>
	arity(a.params);

immutable(size_t) nTypeParams(ref immutable CalledDecl a) =>
	a.typeParams.length;

struct Called {
	@safe @nogc pure nothrow:

	mixin Union!(immutable FunInst*, immutable SpecSig*);

	immutable(bool) opEquals(scope immutable Called b) scope immutable =>
		matchWithPointers!(immutable bool)(
			(immutable FunInst* fa) =>
				b.matchWithPointers!(immutable bool)(
					(immutable FunInst* fb) =>
						fa == fb,
					(immutable SpecSig*) =>
						false),
			(immutable SpecSig* sa) =>
				b.matchWithPointers!(immutable bool)(
					(immutable FunInst*) =>
						false,
					(immutable SpecSig* sb) =>
						*sa == *sb));

	void hash(ref Hasher hasher) scope immutable {
		matchWithPointers!void(
			(immutable FunInst* f) {
				hashPtr(hasher, f);
			},
			(immutable SpecSig* s) {
				s.hash(hasher);
			});
	}

	immutable(Sym) name() scope immutable =>
		match!(immutable Sym)(
			(ref immutable FunInst f) =>
				f.name,
			(ref immutable SpecSig s) =>
				s.name);

	immutable(Type) returnType() scope immutable =>
		match!(immutable Type)(
			(ref immutable FunInst f) =>
				f.returnType,
			(ref immutable SpecSig s) =>
				s.sig.returnType);

	immutable(Params) params() scope immutable =>
		match!(immutable Params)(
			(ref immutable FunInst f) =>
				f.params,
			(ref immutable SpecSig s) =>
				s.sig.params);
}

immutable(Arity) arity(scope immutable Called a) =>
	arity(a.params);

struct StructOrAlias {
	mixin Union!(immutable StructAlias*, immutable StructDecl*);
}
static assert(StructOrAlias.sizeof == ulong.sizeof);

immutable(TypeParam[]) typeParams(ref immutable StructOrAlias a) =>
	a.match!(immutable TypeParam[])(
		(ref immutable StructAlias x) => x.typeParams.toArray(),
		(ref immutable StructDecl x) => x.typeParams.toArray());

immutable(FileAndRange) range(ref immutable StructOrAlias a) =>
	a.match!(immutable FileAndRange)(
		(ref immutable StructAlias x) => x.range,
		(ref immutable StructDecl x) => x.range);

immutable(Visibility) visibility(ref immutable StructOrAlias a) =>
	a.match!(immutable Visibility)(
		(ref immutable StructAlias x) => x.visibility,
		(ref immutable StructDecl x) => x.visibility);

immutable(Sym) name(ref immutable StructOrAlias a) =>
	a.match!(immutable Sym)(
		(ref immutable StructAlias x) => x.name,
		(ref immutable StructDecl x) => x.name);

struct Module {
	@safe @nogc pure nothrow:

	immutable FileIndex fileIndex;
	immutable SafeCStr docComment;
	immutable ImportOrExport[] imports; // includes import of std (if applicable)
	immutable ImportOrExport[] reExports;
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

		ref immutable(Module) module_() return immutable =>
			*modulePtr;
	}
	struct ModuleNamed {
		@safe @nogc pure nothrow:
		immutable Module* modulePtr;
		immutable Sym[] names;

		ref immutable(Module) module_() return immutable =>
			*modulePtr;
	}

	immutable this(immutable ModuleWhole a) {
		modulePtr = a.modulePtr;
		names = [];
	}
	immutable this(immutable ModuleNamed a) {
		verify(a.names.length != 0);
		modulePtr = a.modulePtr;
		names = a.names;
	}

	immutable(T) match(T)(
		scope immutable(T) delegate(immutable ModuleWhole) @safe @nogc pure nothrow cbWhole,
		scope immutable(T) delegate(immutable ModuleNamed) @safe @nogc pure nothrow cbNamed,
	) immutable =>
		names.length == 0
			? cbWhole(immutable ModuleWhole(modulePtr))
			: cbNamed(immutable ModuleNamed(modulePtr, names));

	private:
	immutable Module* modulePtr;
	immutable SmallArray!Sym names;	
}
static assert(ImportOrExportKind.sizeof == ulong.sizeof * 2);

enum ImportFileType { nat8Array, str }

immutable(Sym) symOfImportFileType(immutable ImportFileType a) {
	final switch (a) {
		case ImportFileType.nat8Array:
			return sym!"nat8Array";
		case ImportFileType.str:
			return sym!"string";
	}
}

struct FileContent {
	mixin Union!(immutable ubyte[], immutable SafeCStr);
}

struct NameReferents {
	immutable Opt!StructOrAlias structOrAlias;
	immutable Opt!(SpecDecl*) spec;
	immutable FunDecl*[] funs;
}

enum FunKind {
	fun,
	act,
	ref_,
	pointer,
}

immutable(Sym) symOfFunKind(immutable FunKind a) {
	final switch (a) {
		case FunKind.fun:
			return sym!"fun";
		case FunKind.act:
			return sym!"act";
		case FunKind.ref_:
			return sym!"ref";
		case FunKind.pointer:
			return sym!"pointer";
	}
}

struct CommonFuns {
	immutable FunInst* alloc;
	immutable FunDecl*[] funOrActSubscriptFunDecls;
	immutable FunInst* curExclusion;
	immutable FunInst* main;
	immutable FunInst* mark;
	immutable FunDecl* markVisitFunDecl;
	immutable FunInst* rtMain;
	immutable FunInst* staticSymbols;
	immutable FunInst* throwImpl;
}

struct CommonTypes {
	@safe @nogc pure nothrow:

	immutable StructInst* bool_;
	immutable StructInst* char8;
	immutable StructInst* cString;
	immutable StructInst* float32;
	immutable StructInst* float64;
	immutable IntegralTypes integrals;
	immutable StructInst* symbol;
	immutable StructInst* void_;
	immutable StructDecl* byVal;
	immutable StructDecl* array;
	immutable StructDecl* future;
	immutable StructDecl* namedVal;
	immutable StructDecl* opt;
	immutable StructDecl* ptrConst;
	immutable StructDecl* ptrMut;
	// Indexed by FunKind, then by arity. (arity = typeArgs.length - 1)
	immutable EnumDict!(FunKind, StructDecl*[10]) funStructs;

	immutable(StructDecl*[]) funPtrStructs() return immutable =>
		funStructs[FunKind.pointer];
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
	immutable Module[] allModules;
	immutable Module*[] rootModules;
	immutable Opt!CommonFuns commonFuns;
	immutable CommonTypes commonTypes;
	immutable Diagnostics diagnostics;
}

struct Config {
	immutable ConfigImportPaths include;
	immutable ConfigExternPaths extern_;
}

alias ConfigImportPaths = immutable Dict!(Sym, Path);
alias ConfigExternPaths = immutable Dict!(Sym, Path);

immutable(bool) hasDiags(ref immutable Program a) =>
	!empty(a.diagnostics.diags);

struct Local {
	@safe @nogc pure nothrow:

	//TODO: use NameAndRange (more compact)
	immutable FileAndRange range;
	immutable Sym name;
	immutable LocalMutability mutability;
	immutable Type type;

	immutable(bool) isAllocated() immutable {
		final switch (mutability) {
			case LocalMutability.immut:
			case LocalMutability.mutOnStack:
				return false;
			case LocalMutability.mutAllocated:
				return true;
		}
	}
}

enum LocalMutability {
	immut,
	mutOnStack, // Mutable and on the stack
	mutAllocated, // Mutable and must be heap-allocated since it's used in a closure
}
enum Mutability { immut, mut }
immutable(Mutability) toMutability(immutable LocalMutability a) {
	final switch (a) {
		case LocalMutability.immut:
			return Mutability.immut;
		case LocalMutability.mutOnStack:
		case LocalMutability.mutAllocated:
			return Mutability.mut;
	}
}

struct ClosureRef {
	@safe @nogc pure nothrow:

	immutable PtrAndSmallNumber!(ExprKind.Lambda) lambdaAndIndex;

	immutable(ulong) asTaggable() immutable =>
		lambdaAndIndex.asTaggable;
	static immutable(ClosureRef) fromTagged(immutable ulong x) =>
		immutable ClosureRef(PtrAndSmallNumber!(ExprKind.Lambda).fromTagged(x));

	immutable(ExprKind.Lambda*) lambda() immutable =>
		lambdaAndIndex.ptr;

	immutable(ushort) index() immutable =>
		lambdaAndIndex.number;

	immutable(VariableRef) variableRef() immutable =>
		lambda.closure[index];
}

enum ClosureReferenceKind { direct, allocated }
immutable(Sym) symOfClosureReferenceKind(immutable ClosureReferenceKind a) {
	final switch (a) {
		case ClosureReferenceKind.direct:
			return sym!"direct";
		case ClosureReferenceKind.allocated:
			return sym!"allocated";
	}
}
immutable(ClosureReferenceKind) getClosureReferenceKind(immutable ClosureRef a) =>
	getClosureReferenceKind(a.variableRef);
private immutable(ClosureReferenceKind) getClosureReferenceKind(immutable VariableRef a) =>
	toLocalOrParam(a).match!(immutable ClosureReferenceKind)(
		(ref immutable Local l) {
			final switch (l.mutability) {
				case LocalMutability.immut:
					return ClosureReferenceKind.direct;
				case LocalMutability.mutOnStack:
					return unreachable!(immutable ClosureReferenceKind);
				case LocalMutability.mutAllocated:
					return ClosureReferenceKind.allocated;
			}
		},
		(ref immutable Param) =>
			ClosureReferenceKind.direct);

struct VariableRef {
	mixin Union!(immutable Local*, immutable Param*, immutable ClosureRef);
}
static assert(VariableRef.sizeof == ulong.sizeof);

immutable(Sym) debugName(immutable VariableRef a) =>
	toLocalOrParam(a).match!(immutable Sym)(
		(ref immutable Local x) =>
			x.name,
		(ref immutable Param x) =>
			force(x.name));

immutable(Type) variableRefType(immutable VariableRef a) =>
	toLocalOrParam(a).match!(immutable Type)(
		(ref immutable Local x) =>
			x.type,
		(ref immutable Param x) =>
			x.type);

private struct LocalOrParam {
	mixin Union!(immutable Local*, immutable Param*);
}

immutable(Opt!Sym) name(immutable VariableRef a) =>
	toLocalOrParam(a).match!(immutable Opt!Sym)(
		(ref immutable Local x) =>
			some(x.name),
		(ref immutable Param x) =>
			x.name);

private immutable(LocalOrParam) toLocalOrParam(immutable VariableRef a) =>
	a.matchWithPointers!(immutable LocalOrParam)(
		(immutable Local* x) =>
			immutable LocalOrParam(x),
		(immutable Param* x) =>
			immutable LocalOrParam(x),
		(immutable ClosureRef x) =>
			toLocalOrParam(x.variableRef()));

struct Expr {
	immutable FileAndRange range;
	immutable ExprKind kind;
}

struct ExprKind {
	@safe @nogc pure nothrow:

	struct AssertOrForbid {
		immutable AssertOrForbidKind kind;
		immutable Expr* condition;
		immutable Opt!(Expr*) thrown;
	}

	struct Bogus {}

	struct Call {
		immutable Called called;
		immutable Expr[] args;
	}

	struct ClosureGet {
		// TODO: by value (causes forward reference error on dmd 2.100 but not on dmd 2.101)
		immutable ClosureRef* closureRef;
	}

	struct ClosureSet {
		// TODO: by value (causes forward reference error on dmd 2.100 but not on dmd 2.101)
		immutable ClosureRef* closureRef;
		immutable Expr* value;
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
		// This is the function type;
		immutable StructInst* funType;
		immutable FunKind kind;
		// For FunKind.send this includes 'future' wrapper
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

	struct LocalGet {
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

	struct LoopUntil {
		immutable Expr condition;
		immutable Expr body_;
	}

	struct LoopWhile {
		immutable Expr condition;
		immutable Expr body_;
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

	struct ParamGet {
		immutable Param* param;
	}

	struct PtrToField {
		immutable Type pointerType;
		immutable Expr target; // This will be a pointer or by-ref type
		immutable size_t fieldIndex;
	}

	struct PtrToLocal {
		immutable Type ptrType;
		immutable Local* local;
	}

	struct PtrToParam {
		immutable Type ptrType;
		immutable Param* param;
	}

	struct Seq {
		immutable Expr first;
		immutable Expr then;
	}

	struct Throw {
		immutable Type type;
		immutable Expr thrown;
	}

	mixin Union!(
		immutable AssertOrForbid,
		immutable Bogus,
		immutable Call,
		immutable ClosureGet,
		immutable ClosureSet,
		immutable Cond*,
		immutable Drop*,
		immutable FunPtr,
		immutable IfOption*,
		immutable Lambda*,
		immutable Let*,
		immutable Literal*,
		immutable LiteralCString,
		immutable LiteralSymbol,
		immutable LocalGet,
		immutable LocalSet*,
		immutable Loop*,
		immutable LoopBreak*,
		immutable LoopContinue,
		immutable LoopUntil*,
		immutable LoopWhile*,
		immutable MatchEnum*,
		immutable MatchUnion*,
		immutable ParamGet,
		immutable PtrToField*,
		immutable PtrToLocal,
		immutable PtrToParam,
		immutable Seq*,
		immutable Throw*);
}

enum AssertOrForbidKind { assert_, forbid }

immutable(Sym) symOfAssertOrForbidKind(immutable AssertOrForbidKind a) {
	final switch (a) {
		case AssertOrForbidKind.assert_:
			return sym!"assert";
		case AssertOrForbidKind.forbid:
			return sym!"forbid";
	}
}

void writeStructDecl(scope ref Writer writer, scope ref const AllSymbols allSymbols, scope ref immutable StructDecl a) {
	writeSym(writer, allSymbols, a.name);
}

void writeStructInst(scope ref Writer writer, scope ref const AllSymbols allSymbols, scope ref immutable StructInst s) {
	// TODO: more cases like this
	if (decl(s).name == sym!"mut-list" && s.typeArgs.length == 1) {
		writeTypeUnquoted(writer, allSymbols, only(s.typeArgs));
		writer ~= " mut[]";
	} else {
		writeStructDecl(writer, allSymbols, *decl(s));
		if (!empty(s.typeArgs)) {
			writer ~= '<';
			writeWithCommas!Type(writer, s.typeArgs, (ref immutable Type t) {
				writeTypeUnquoted(writer, allSymbols, t);
			});
			writer ~= '>';
		}
	}
}

void writeTypeArgs(ref Writer writer, scope ref const AllSymbols allSymbols, scope immutable Type[] a) {
	writer ~= '<';
	writeWithCommas!Type(writer, a, (scope ref immutable Type x) {
		writeTypeUnquoted(writer, allSymbols, x);
	});
	writer ~= '>';
}

void writeTypeQuoted(ref Writer writer, ref const AllSymbols allSymbols, immutable Type a) {
	writer ~= '\'';
	writeTypeUnquoted(writer, allSymbols, a);
	writer ~= '\'';
}

//TODO:MOVE
void writeTypeUnquoted(ref Writer writer, scope ref const AllSymbols allSymbols, immutable Type a) {
	a.match!void(
		(immutable Type.Bogus) {
			writer ~= "<<bogus>>";
		},
		(ref immutable TypeParam x) {
			writeSym(writer, allSymbols, x.name);
		},
		(ref immutable StructInst x) {
			writeStructInst(writer, allSymbols, x);
		});
}

enum Visibility : ubyte {
	public_,
	private_,
}

immutable(Sym) symOfVisibility(immutable Visibility a) {
	final switch (a) {
		case Visibility.public_:
			return sym!"public";
		case Visibility.private_:
			return sym!"private";
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
