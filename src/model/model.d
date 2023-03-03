module model.model;

@safe @nogc pure nothrow:

import frontend.check.typeFromAst : typeSyntaxKind;
import frontend.parse.ast : NameAndRange, rangeOfNameAndRange;
import model.concreteModel : TypeSize;
import model.constant : Constant;
import model.diag : Diag, Diagnostics, FilesInfo; // TODO: move FilesInfo here?
import util.col.arr : arrayOfSingle, empty, only, only2, PtrAndSmallNumber, small, SmallArray;
import util.col.arrUtil : arrEqual, exists;
import util.col.dict : Dict;
import util.col.enumDict : EnumDict;
import util.col.fullIndexDict : FullIndexDict;
import util.col.str : SafeCStr;
import util.hash : Hasher;
import util.late : Late, lateGet, lateIsSet, lateSet, lateSetOverwrite;
import util.lineAndColumnGetter : LineAndColumnGetter;
import util.opt : force, has, none, Opt, some;
import util.path : Path;
import util.ptr : hashPtr;
import util.sourceRange :
	combineRanges,
	FileAndPos,
	FileAndRange,
	fileAndRangeFromFileAndPos,
	FileIndex,
	Pos,
	rangeOfStartAndName,
	RangeWithinFile;
import util.sym : AllSymbols, Sym, sym, writeSym;
import util.union_ : Union;
import util.util : max, min, typeAs, unreachable, verify;
import util.writer : Writer, writeWithCommas;

alias LineAndColumnGetters = immutable FullIndexDict!(FileIndex, LineAndColumnGetter);

alias Purity = immutable Purity_;
private enum Purity_ : ubyte {
	// sorted best case to worst case
	data,
	shared_,
	mut,
}

bool isPurityCompatible(Purity expected, Purity actual) =>
	actual <= expected;

immutable struct PurityRange {
	Purity bestCase;
	Purity worstCase;
}

PurityRange combinePurityRange(PurityRange a, PurityRange b) =>
	immutable PurityRange(worsePurity(a.bestCase, b.bestCase), worsePurity(a.worstCase, b.worstCase));

bool isPurityAlwaysCompatible(Purity referencer, PurityRange referenced) =>
	referenced.worstCase <= referencer;

bool isPurityPossiblyCompatible(Purity referencer, PurityRange referenced) =>
	referenced.bestCase <= referencer;

Purity worsePurity(Purity a, Purity b) =>
	max(a, b);

Sym symOfPurity(Purity a) {
	final switch (a) {
		case Purity.data:
			return sym!"data";
		case Purity.shared_:
			return sym!"shared";
		case Purity.mut:
			return sym!"mut";
	}
}

immutable struct TypeParam {
	FileAndRange range;
	Sym name;
	size_t index;
}

immutable struct Type {
	@safe @nogc pure nothrow:
	immutable struct Bogus {}

	mixin Union!(Bogus, TypeParam*, StructInst*);

	bool opEquals(scope Type b) scope =>
		matchWithPointers!bool(
			(Type.Bogus) =>
				b.isA!(Type.Bogus),
			(TypeParam* p) =>
				b.isA!(TypeParam*) && b.as!(TypeParam*) == p,
			(StructInst* i) =>
				b.isA!(StructInst*) && b.as!(StructInst*) == i);

	void hash(ref Hasher hasher) scope {
		matchWithPointers!void(
			(Type.Bogus) {},
			(TypeParam* p) =>
				hashPtr(hasher, p),
			(StructInst* i) =>
				hashPtr(hasher, i));
	}
}
static assert(Type.sizeof == ulong.sizeof);

PurityRange purityRange(Type a) =>
	a.match!PurityRange(
		(Type.Bogus) =>
			PurityRange(Purity.data, Purity.data),
		(ref TypeParam _) =>
			PurityRange(Purity.data, Purity.mut),
		(ref StructInst x) =>
			x.purityRange);

Purity bestCasePurity(Type a) =>
	purityRange(a).bestCase;

LinkageRange linkageRange(Type a) =>
	a.match!LinkageRange(
		(Type.Bogus) =>
			LinkageRange(Linkage.extern_, Linkage.extern_),
		(ref TypeParam _) =>
			LinkageRange(Linkage.internal, Linkage.extern_),
		(ref StructInst x) =>
			x.linkageRange);

immutable struct Params {
	immutable struct Varargs {
		Destructure param;
		Type elementType;
	}

	mixin Union!(SmallArray!Destructure, Varargs*);
}
static assert(Params.sizeof == ulong.sizeof);

Destructure[] paramsArray(Params a) =>
	a.matchWithPointers!(Destructure[])(
		(Destructure[] x) =>
			x,
		(Params.Varargs* x) =>
			arrayOfSingle(&x.param));

Destructure[] assertNonVariadic(Params a) =>
	a.as!(Destructure[]);

immutable struct Arity {
	immutable struct Varargs {}
	mixin Union!(size_t, Varargs);
}

bool arityMatches(Arity sigArity, size_t nArgs) =>
	sigArity.match!bool(
		(size_t nParams) =>
			nParams == nArgs,
		(Arity.Varargs) =>
			true);

Arity arity(in Params a) =>
	a.matchIn!Arity(
		(in Destructure[] params) =>
			Arity(params.length),
		(in Params.Varargs) =>
			Arity(Arity.Varargs()));

immutable struct SpecDeclSig {
	@safe @nogc pure nothrow:

	SafeCStr docComment;
	FileAndPos fileAndPos;
	Sym name;
	Type returnType;
	SmallArray!Destructure params;
}

enum FieldMutability {
	const_,
	private_,
	public_,
}

Sym symOfFieldMutability(FieldMutability a) {
	final switch (a) {
		case FieldMutability.const_:
			return sym!"const";
		case FieldMutability.private_:
			return sym!"private";
		case FieldMutability.public_:
			return sym!"public";
	}
}

immutable struct RecordField {
	//TODO: use NameAndRange (more compact)
	FileAndRange range;
	Visibility visibility;
	Sym name;
	FieldMutability mutability;
	Type type;
}

immutable struct UnionMember {
	//TODO: use NameAndRange (more compact)
	FileAndRange range;
	Sym name;
	Type type;
}

enum ForcedByValOrRefOrNone {
	none,
	byVal,
	byRef,
}

Sym symOfForcedByValOrRefOrNone(ForcedByValOrRefOrNone a) {
	final switch (a) {
		case ForcedByValOrRefOrNone.none:
			return sym!"none";
		case ForcedByValOrRefOrNone.byVal:
			return sym!"by-val";
		case ForcedByValOrRefOrNone.byRef:
			return sym!"by-ref";
	}
}

immutable struct RecordFlags {
	Visibility newVisibility;
	bool packed;
	ForcedByValOrRefOrNone forcedByValOrRef;
}

immutable struct EnumValue {
	@safe @nogc pure nothrow:

	// Large nat64 are represented as wrapped to negative values.
	long value;

	//TODO:NOT INSTANCE
	long asSigned() =>
		value;
	ulong asUnsigned() =>
		cast(ulong) value;
}

immutable struct StructBody {
	immutable struct Bogus {}
	immutable struct Builtin {}
	immutable struct Enum {
		immutable struct Member {
			FileAndRange range;
			Sym name;
			EnumValue value;
		}
		EnumBackingType backingType;
		Member[] members;
	}
	immutable struct Extern {
		Opt!TypeSize size;
	}
	immutable struct Flags {
		alias Member = Enum.Member;
		EnumBackingType backingType;
		// For Flags, members should be unsigned
		Member[] members;
	}
	immutable struct Record {
		RecordFlags flags;
		RecordField[] fields;
	}
	immutable struct Union {
		UnionMember[] members;
	}

	mixin .Union!(Bogus, Builtin, Enum, Extern, Flags, Record, Union);
}
static assert(StructBody.sizeof == size_t.sizeof + StructBody.Record.sizeof);

immutable struct StructAlias {
	// TODO: use NameAndRange (more compact)
	FileAndRange range;
	SafeCStr docComment;
	Visibility visibility;
	Sym name;
	SmallArray!TypeParam typeParams;

	private:
	// This will be none if the alias target is not found
	Late!(Opt!(StructInst*)) target_;
}

Opt!(StructInst*) target(ref StructAlias a) =>
	lateGet(a.target_);
void setTarget(ref StructAlias a, Opt!(StructInst*) value) {
	lateSet(a.target_, value);
}

// sorted least strict to most strict
enum Linkage : ubyte { internal, extern_ }

// Range of possible linkage
immutable struct LinkageRange {
	Linkage leastStrict;
	Linkage mostStrict;
}

LinkageRange combineLinkageRange(LinkageRange referencer, LinkageRange referenced) =>
	LinkageRange(
		lessStrictLinkage(referencer.leastStrict, referenced.leastStrict),
		lessStrictLinkage(referencer.mostStrict, referenced.mostStrict));

private Linkage lessStrictLinkage(Linkage a, Linkage b) =>
	min(a, b);

bool isLinkagePossiblyCompatible(Linkage referencer, LinkageRange referenced) =>
	referenced.mostStrict >= referencer;

bool isLinkageAlwaysCompatible(Linkage referencer, LinkageRange referenced) =>
	referenced.leastStrict >= referencer;

immutable struct StructDecl {
	// TODO: use NameAndRange (more compact)
	FileAndRange range;
	SafeCStr docComment;
	Sym name;
	SmallArray!TypeParam typeParams;
	Visibility visibility;
	Linkage linkage;
	// Note: purity on the decl does not take type args into account
	Purity purity;
	bool purityIsForced;

	private Late!StructBody lateBody;
}

bool isTemplate(in StructDecl a) =>
	!empty(a.typeParams);

bool bodyIsSet(in StructDecl a) =>
	lateIsSet(a.lateBody);

ref StructBody body_(return scope ref StructDecl a) =>
	lateGet(a.lateBody);

void setBody(ref StructDecl a, StructBody value) {
	lateSet(a.lateBody, value);
}

immutable struct StructDeclAndArgs {
	@safe @nogc pure nothrow:

	StructDecl* decl;
	Type[] typeArgs;

	bool opEquals(in StructDeclAndArgs b) scope =>
		decl == b.decl && arrEqual!Type(typeArgs, b.typeArgs);

	void hash(ref Hasher hasher) scope {
		hashPtr(hasher, decl);
		foreach (Type t; typeArgs)
			t.hash(hasher);
	}
}

immutable struct StructInst {
	@safe @nogc pure nothrow:

	StructDeclAndArgs declAndArgs;

	// these are inferred from declAndArgs:
	LinkageRange linkageRange;
	PurityRange purityRange;
	// For a Record, this is the field types.
	// For a Union, this is the member types (Bogus for members with no type).
	// Otherwise this is empty.
	private Late!(SmallArray!Type) lateInstantiatedTypes;

	Type[] instantiatedTypes() return scope =>
		lateGet(lateInstantiatedTypes);

	void instantiatedTypes(Type[] value) {
		lateSet(lateInstantiatedTypes, small(value));
	}
}

bool hasMutableField(in StructInst a) {
	StructBody body_ = body_(*decl(a));
	return body_.isA!(StructBody.Record) &&
		exists!RecordField(body_.as!(StructBody.Record).fields, (in RecordField x) =>
			x.mutability != FieldMutability.const_);
}

bool isDefinitelyByRef(in StructInst a) {
	StructBody body_ = body_(*decl(a));
	return body_.isA!(StructBody.Record) &&
		body_.as!(StructBody.Record).flags.forcedByValOrRef == ForcedByValOrRefOrNone.byRef;
}

bool isArray(in CommonTypes commonTypes, in StructInst a) =>
	decl(a) == commonTypes.array;

bool isTuple(in CommonTypes commonTypes, in Type a) =>
	a.isA!(StructInst*) && isTuple(commonTypes, *a.as!(StructInst*));
bool isTuple(in CommonTypes commonTypes, in StructInst a) =>
	isTuple(commonTypes, decl(a));
bool isTuple(in CommonTypes commonTypes, in StructDecl* a) {
	Opt!(StructDecl*) actual = commonTypes.tuple(a.typeParams.length);
	return has(actual) && force(actual) == a;
}
Opt!(Type[]) asTuple(in CommonTypes commonTypes, Type type) =>
	isTuple(commonTypes, type) ? some(typeArgs(*type.as!(StructInst*))) : none!(Type[]);

Sym name(in StructInst a) =>
	decl(a).name;

StructDecl* decl(ref StructInst a) =>
	a.declAndArgs.decl;

Type[] typeArgs(ref StructInst a) =>
	a.declAndArgs.typeArgs;

immutable struct SpecDeclBody {
	immutable struct Builtin {
		enum Kind {
			data,
			shared_,
		}
		Kind kind;
	}
	mixin Union!(Builtin, SmallArray!SpecDeclSig);
}

Sym symOfSpecBodyBuiltinKind(SpecDeclBody.Builtin.Kind kind) {
	final switch (kind) {
		case SpecDeclBody.Builtin.Kind.data:
			return sym!"data";
		case SpecDeclBody.Builtin.Kind.shared_:
			return sym!"shared";
	}
}

immutable struct SpecDecl {
	@safe @nogc pure nothrow:

	// TODO: use NameAndRange (more compact)
	FileAndRange range;
	SafeCStr docComment;
	Visibility visibility;
	Sym name;
	SmallArray!TypeParam typeParams;
	SpecDeclBody body_;
	Late!(SmallArray!(immutable SpecInst*)) parents_;

	bool parentsIsSet() =>
		lateIsSet(parents_);
	immutable(SpecInst*[]) parents() scope =>
		lateGet(parents_);
	void parents(immutable SpecInst*[] value) {
		lateSet(parents_, small(value));
	}
	void overwriteParents(immutable SpecInst*[] value) =>
		lateSetOverwrite(parents_, small(value));
}

immutable struct SpecDeclAndArgs {
	@safe @nogc pure nothrow:

	SpecDecl* decl;
	Type[] typeArgs;

	bool opEquals(in SpecDeclAndArgs b) scope =>
		decl == b.decl && arrEqual!Type(typeArgs, b.typeArgs);

	void hash(ref Hasher hasher) scope {
		hashPtr(hasher, decl);
		foreach (Type t; typeArgs)
			t.hash(hasher);
	}
}

immutable struct SpecInst {
	@safe @nogc pure nothrow:

	SpecDeclAndArgs declAndArgs;
	// Corresponds to the signatures in decl.body_
	SmallArray!ReturnAndParamTypes sigTypes_;
	private Late!(SmallArray!(immutable SpecInst*)) parents_;
	
	ReturnAndParamTypes[] sigTypes() return scope =>
		sigTypes_;

	immutable(SpecInst*[]) parents() return scope =>
		lateGet(parents_);
	void parents(immutable SpecInst*[] value) {
		lateSet(parents_, small(value));
	}
}

SpecDecl* decl(return scope ref SpecInst a) =>
	a.declAndArgs.decl;

Type[] typeArgs(return scope ref SpecInst a) =>
	a.declAndArgs.typeArgs;

Sym name(in SpecInst a) =>
	decl(a).name;

alias EnumFunction = immutable EnumFunction_;
private enum EnumFunction_ {
	equal,
	intersect,
	members,
	toIntegral,
	union_,
}

Sym enumFunctionName(EnumFunction a) {
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

alias FlagsFunction = immutable FlagsFunction_;
private enum FlagsFunction_ {
	all,
	negate,
	new_,
}

Sym flagsFunctionName(FlagsFunction a) {
	final switch (a) {
		case FlagsFunction.all:
			return sym!"all";
		case FlagsFunction.negate:
			return sym!"~";
		case FlagsFunction.new_:
			return sym!"new";
	}
}

enum VarKind { global, threadLocal }

immutable struct FunBody {
	immutable struct Bogus {}
	immutable struct Builtin {}
	immutable struct CreateEnum {
		EnumValue value;
	}
	immutable struct CreateExtern {}
	immutable struct CreateRecord {}
	immutable struct CreateUnion {
		size_t memberIndex;
	}
	immutable struct ExpressionBody {
		Expr expr;
	}
	immutable struct Extern {
		Sym libraryName;
	}
	immutable struct FileBytes {
		ubyte[] bytes;
	}
	immutable struct RecordFieldGet {
		size_t fieldIndex;
	}
	immutable struct RecordFieldSet {
		size_t fieldIndex;
	}
	immutable struct VarGet { VarDecl* var; }
	immutable struct VarSet { VarDecl* var; }

	mixin Union!(
		Bogus,
		Builtin,
		CreateEnum,
		CreateExtern,
		CreateRecord,
		CreateUnion,
		EnumFunction,
		Extern,
		ExpressionBody,
		FileBytes,
		FlagsFunction,
		RecordFieldGet,
		RecordFieldSet,
		VarGet,
		VarSet);
}

immutable struct FunFlags {
	@safe @nogc pure nothrow:

	bool noCtx;
	bool summon;
	enum Safety : ubyte { safe, unsafe }
	Safety safety;
	bool preferred;
	bool okIfUnused;
	enum SpecialBody : ubyte { none, builtin, extern_, generated }
	SpecialBody specialBody;
	bool forceCtx;

	FunFlags withOkIfUnused() =>
		FunFlags(noCtx, summon, safety, preferred, true, specialBody, forceCtx);

	static FunFlags regular(bool noCtx, bool summon, Safety safety, SpecialBody specialBody, bool forceCtx) =>
		FunFlags(noCtx, summon, safety, false, false, specialBody, forceCtx);

	static FunFlags none() =>
		FunFlags(false, false, Safety.safe, false, false, SpecialBody.none);
	static FunFlags generatedNoCtx() =>
		FunFlags(true, false, Safety.safe, false, true, SpecialBody.generated);
	static FunFlags generatedNoCtxUnsafe() =>
		FunFlags(true, false, Safety.unsafe, false, true, SpecialBody.generated);
	static FunFlags generatedPreferred() =>
		FunFlags(false, false, Safety.safe, true, true, SpecialBody.generated);
	static FunFlags unsafeSummon() =>
		FunFlags(false, true, Safety.unsafe, false, false, SpecialBody.none);
}
static assert(FunFlags.sizeof == 7);

immutable struct FunDecl {
	@safe @nogc pure nothrow:

	@disable this(ref const FunDecl);

	this(
		SafeCStr dc,
		Visibility v,
		FileAndPos fp,
		Sym n,
		TypeParam[] tps,
		Type rt,
		Params pms,
		FunFlags f,
		immutable SpecInst*[] sps,
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
	}
	this(
		SafeCStr dc,
		Visibility v,
		FileAndPos fp,
		Sym n,
		TypeParam[] tps,
		Type rt,
		Params pms,
		FunFlags f,
		immutable SpecInst*[] sps,
		FunBody b,
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
		setBody(b);
	}

	SafeCStr docComment;
	Visibility visibility;
	FileAndPos fileAndPos;
	Sym name;
	FunFlags flags;
	Type returnType;
	Params params;
	SmallArray!TypeParam typeParams;
	SmallArray!(SpecInst*) specs;
	private Late!FunBody lateBody;

	FileAndRange range() scope =>
		// TODO: end position
		fileAndRangeFromFileAndPos(fileAndPos);

	immutable(RangeWithinFile) nameRange(in AllSymbols allSymbols) =>
		rangeOfStartAndName(fileAndPos.pos, name, allSymbols);

	ref FunBody body_() return scope =>
		lateGet(lateBody);

	void setBody(FunBody b) {
		lateSet(lateBody, b);
	}
}

Linkage linkage(ref FunDecl a) =>
	a.body_.isA!(FunBody.Extern) ? Linkage.extern_ : Linkage.internal;

bool noCtx(in FunDecl a) =>
	a.flags.noCtx;
bool isGenerated(in FunDecl a) =>
	a.flags.specialBody == FunFlags.SpecialBody.generated;
bool summon(in FunDecl a) =>
	a.flags.summon;
bool unsafe(in FunDecl a) =>
	a.flags.safety == FunFlags.Safety.unsafe;
bool okIfUnused(in FunDecl a) =>
	a.flags.okIfUnused;

bool isVariadic(in FunDecl a) =>
	a.params.isA!(Params.Varargs*);

bool isTemplate(in FunDecl a) =>
	!empty(a.typeParams) || !empty(a.specs);

Arity arity(in FunDecl a) =>
	arity(a.params);

immutable struct Test {
	Expr body_;
}

immutable struct FunDeclAndTypeArgs {
	FunDecl* decl;
	Type[] typeArgs;
}

immutable struct FunDeclAndArgs {
	@safe @nogc pure nothrow:

	FunDecl* decl;
	Type[] typeArgs;
	Called[] specImpls;

	bool opEquals(in FunDeclAndArgs b) scope =>
		decl == b.decl && arrEqual!Type(typeArgs, b.typeArgs) && arrEqual!Called(specImpls, b.specImpls);

	void hash(ref Hasher hasher) scope {
		hashPtr(hasher, decl);
		foreach (Type t; typeArgs)
			t.hash(hasher);
		foreach (ref Called c; specImpls)
			c.hash(hasher);
	}
}

immutable struct FunInst {
	@safe @nogc pure nothrow:

	FunDeclAndArgs funDeclAndArgs;
	ReturnAndParamTypes instantiatedSig;

	Sym name() scope =>
		decl(this).name;

	Type returnType() scope =>
		instantiatedSig.returnType;

	Type[] paramTypes() scope =>
		instantiatedSig.paramTypes;
}

FunDecl* decl(ref FunInst a) =>
	a.funDeclAndArgs.decl;

Type[] typeArgs(ref FunInst a) =>
	a.funDeclAndArgs.typeArgs;

Called[] specImpls(ref FunInst a) =>
	a.funDeclAndArgs.specImpls;

Arity arity(in FunInst a) =>
	arity(*decl(a));

immutable struct ReturnAndParamTypes {
	@safe @nogc pure nothrow:

	SmallArray!Type returnAndParamTypes;

	Type returnType() scope =>
		returnAndParamTypes[0];
	
	Type[] paramTypes() scope =>
		returnAndParamTypes[1 .. $];
}

immutable struct CalledSpecSig {
	@safe @nogc pure nothrow:

	SpecInst* specInst;
	ReturnAndParamTypes instantiatedSig; // comes from the specInst
	SpecDeclSig* nonInstantiatedSig;
	size_t indexOverAllSpecUses; // this is redundant to specInst and sig

	Type returnType() scope =>
		instantiatedSig.returnType;
	Type[] paramTypes() scope =>
		instantiatedSig.paramTypes;

	private:

	bool opEquals(scope CalledSpecSig b) scope =>
		// Don't bother with indexOverAllSpecUses, it's redundant if we checked sig
		specInst == b.specInst && nonInstantiatedSig == b.nonInstantiatedSig;

	void hash(ref Hasher hasher) scope {
		hashPtr(hasher, specInst);
		hashPtr(hasher, nonInstantiatedSig);
	}
}

Sym name(ref CalledSpecSig a) =>
	a.nonInstantiatedSig.name;

Arity arity(in CalledSpecSig a) =>
	Arity(a.nonInstantiatedSig.params.length);

// Like 'Called', but we haven't fully instantiated yet. (This is used for Candidate when checking a call expr.)
immutable struct CalledDecl {
	@safe @nogc pure nothrow:

	mixin Union!(FunDecl*, CalledSpecSig);

	Sym name() scope =>
		matchIn!Sym(
			(in FunDecl f) => f.name,
			(in CalledSpecSig s) => s.name);

	TypeParam[] typeParams() return scope =>
		match!(TypeParam[])(
			(ref FunDecl f) => f.typeParams.toArray,
			(CalledSpecSig) => typeAs!(TypeParam[])([]));

	Type returnType() scope =>
		match!Type(
			(ref FunDecl f) => f.returnType,
			(CalledSpecSig s) => s.returnType);
}

Arity arity(in CalledDecl a) =>
	a.matchIn!Arity(
		(in FunDecl x) =>
			arity(x.params),
		(in CalledSpecSig x) =>
			arity(x));

size_t nTypeParams(in CalledDecl a) =>
	a.typeParams.length;

immutable struct Called {
	@safe @nogc pure nothrow:

	mixin Union!(FunInst*, CalledSpecSig*);

	bool opEquals(scope Called b) scope =>
		matchWithPointers!bool(
			(FunInst* fa) =>
				b.matchWithPointers!bool(
					(FunInst* fb) =>
						fa == fb,
					(CalledSpecSig*) =>
						false),
			(CalledSpecSig* sa) =>
				b.matchWithPointers!bool(
					(FunInst*) =>
						false,
					(CalledSpecSig* sb) =>
						*sa == *sb));

	void hash(ref Hasher hasher) scope {
		matchWithPointers!void(
			(FunInst* f) {
				hashPtr(hasher, f);
			},
			(CalledSpecSig* s) {
				s.hash(hasher);
			});
	}

	Sym name() scope =>
		matchIn!Sym(
			(in FunInst f) =>
				f.name,
			(in CalledSpecSig s) =>
				s.name);

	Type returnType() scope =>
		match!Type(
			(ref FunInst f) =>
				f.returnType,
			(ref CalledSpecSig s) =>
				s.instantiatedSig.returnType);
}

Type paramTypeAt(in Called a, size_t argIndex) scope =>
	a.matchIn!Type(
		(in FunInst f) =>
			decl(f).params.matchIn!Type(
				(in Destructure[]) =>
					f.paramTypes[argIndex],
				(in Params.Varargs) =>
					f.paramTypes[0]),
		(in CalledSpecSig s) =>
			s.paramTypes[argIndex]);

Arity arity(in Called a) =>
	a.match!Arity(
		(ref FunInst f) =>
			arity(f),
		(ref CalledSpecSig s) =>
			arity(s));

immutable struct StructOrAlias {
	@safe @nogc pure nothrow:
	
	mixin Union!(StructAlias*, StructDecl*);

	immutable(void*) asVoidPointer() =>
		matchWithPointers!(immutable void*)(
			(StructAlias* x) => typeAs!(immutable void*)(x),
			(StructDecl* x) => typeAs!(immutable void*)(x));
}
static assert(StructOrAlias.sizeof == ulong.sizeof);

TypeParam[] typeParams(ref StructOrAlias a) =>
	a.match!(TypeParam[])(
		(ref StructAlias x) => x.typeParams.toArray(),
		(ref StructDecl x) => x.typeParams.toArray());

FileAndRange range(ref StructOrAlias a) =>
	a.match!FileAndRange(
		(ref StructAlias x) => x.range,
		(ref StructDecl x) => x.range);

Visibility visibility(ref StructOrAlias a) =>
	a.match!Visibility(
		(ref StructAlias x) => x.visibility,
		(ref StructDecl x) => x.visibility);

Sym name(ref StructOrAlias a) =>
	a.match!Sym(
		(ref StructAlias x) => x.name,
		(ref StructDecl x) => x.name);

// No VarInst since these can't be templates
immutable struct VarDecl {
	@safe @nogc pure nothrow:

	FileAndPos pos;
	SafeCStr docComment;
	Visibility visibility;
	Sym name;
	VarKind kind;
	Type type;
	Opt!Sym externLibraryName;

	FileAndRange range() scope =>
		fileAndRangeFromFileAndPos(pos);
}

immutable struct Module {
	@safe @nogc pure nothrow:

	FileIndex fileIndex;
	SafeCStr docComment;
	ImportOrExport[] imports; // includes import of std (if applicable)
	ImportOrExport[] reExports;
	StructDecl[] structs;
	VarDecl[] vars;
	SpecDecl[] specs;
	FunDecl[] funs;
	Test[] tests;
	// Includes re-exports
	Dict!(Sym, NameReferents) allExportedNames;
}

immutable struct ImportOrExport {
	// none for an automatic import of std
	Opt!RangeWithinFile importSource;
	ImportOrExportKind kind;
}

// No File option since those become FunDecls
immutable struct ImportOrExportKind {
	@safe @nogc pure nothrow:

	immutable struct ModuleWhole {
		@safe @nogc pure nothrow:
		Module* modulePtr;

		ref Module module_() return scope =>
			*modulePtr;
	}
	immutable struct ModuleNamed {
		@safe @nogc pure nothrow:
		Module* modulePtr;
		Sym[] names;

		ref Module module_() return scope =>
			*modulePtr;
	}

	this(ModuleWhole a) {
		modulePtr = a.modulePtr;
		names = [];
	}
	this(ModuleNamed a) {
		verify(a.names.length != 0);
		modulePtr = a.modulePtr;
		names = a.names;
	}

	T match(T)(
		in T delegate(ModuleWhole) @safe @nogc pure nothrow cbWhole,
		in T delegate(ModuleNamed) @safe @nogc pure nothrow cbNamed,
	) =>
		names.length == 0
			? cbWhole(ModuleWhole(modulePtr))
			: cbNamed(ModuleNamed(modulePtr, names));
	T matchIn(T)(
		in T delegate(in ModuleWhole) @safe @nogc pure nothrow cbWhole,
		in T delegate(in ModuleNamed) @safe @nogc pure nothrow cbNamed,
	) scope =>
		names.length == 0
			? cbWhole(ModuleWhole(modulePtr))
			: cbNamed(ModuleNamed(modulePtr, names));

	private:
	Module* modulePtr;
	SmallArray!Sym names;	
}
static assert(ImportOrExportKind.sizeof == ulong.sizeof * 2);

enum ImportFileType { nat8Array, str }

Sym symOfImportFileType(ImportFileType a) {
	final switch (a) {
		case ImportFileType.nat8Array:
			return sym!"nat8Array";
		case ImportFileType.str:
			return sym!"string";
	}
}

immutable struct FileContent {
	mixin Union!(ubyte[], SafeCStr);
}

immutable struct NameReferents {
	Opt!StructOrAlias structOrAlias;
	Opt!(SpecDecl*) spec;
	FunDecl*[] funs;
}

enum FunKind {
	fun,
	act,
	far,
	pointer,
}

Sym symOfFunKind(FunKind a) {
	final switch (a) {
		case FunKind.fun:
			return sym!"fun";
		case FunKind.act:
			return sym!"act";
		case FunKind.far:
			return sym!"far";
		case FunKind.pointer:
			return sym!"pointer";
	}
}

immutable struct CommonFuns {
	FunInst* alloc;
	FunDecl*[] funOrActSubscriptFunDecls;
	FunInst* curExclusion;
	FunInst* main;
	FunInst* mark;
	FunDecl* markVisitFunDecl;
	FunInst* rtMain;
	FunInst* staticSymbols;
	FunInst* throwImpl;
}

immutable struct CommonTypes {
	@safe @nogc pure nothrow:

	StructInst* bool_;
	StructInst* char8;
	StructInst* cString;
	StructInst* float32;
	StructInst* float64;
	IntegralTypes integrals;
	StructInst* symbol;
	StructInst* void_;
	StructDecl* byVal;
	StructDecl* array;
	StructDecl* future;
	StructDecl* opt;
	StructDecl* ptrConst;
	StructDecl* ptrMut;
	// No tuple0 and tuple1, so this is 2-9 inclusive
	StructDecl*[8] tuples2Through9;
	// Indexed by FunKind, then by arity. (arity = typeArgs.length - 1)
	EnumDict!(FunKind, StructDecl*) funStructs;
	
	StructDecl* funPtrStruct() =>
		funStructs[FunKind.pointer];

	Opt!(StructDecl*) tuple(size_t arity) return scope =>
		2 <= arity && arity <= 9 ? some(tuples2Through9[arity - 2]) : none!(StructDecl*);
}

immutable struct IntegralTypes {
	StructInst* int8;
	StructInst* int16;
	StructInst* int32;
	StructInst* int64;
	StructInst* nat8;
	StructInst* nat16;
	StructInst* nat32;
	StructInst* nat64;
}

alias EnumBackingType = immutable EnumBackingType_;
private enum EnumBackingType_ {
	int8,
	int16,
	int32,
	int64,
	nat8,
	nat16,
	nat32,
	nat64,
}

immutable struct Program {
	FilesInfo filesInfo;
	Config config;
	Module[] allModules;
	Module*[] rootModules;
	Opt!CommonFuns commonFuns;
	CommonTypes commonTypes;
	Diagnostics diagnostics;
}
Program fakeProgramForTest(FilesInfo filesInfo) =>
	fakeProgramForDiagnostics(filesInfo, Diagnostics());
Program fakeProgramForDiagnostics(FilesInfo filesInfo, Diagnostics diagnostics) =>
	Program(filesInfo, Config(), [], [], none!CommonFuns, CommonTypes(), diagnostics);

immutable struct Config {
	ConfigImportPaths include;
	ConfigExternPaths extern_;
}

alias ConfigImportPaths = Dict!(Sym, Path);
alias ConfigExternPaths = Dict!(Sym, Path);

bool hasDiags(in Program a) =>
	!empty(a.diagnostics.diags);

immutable struct Local {
	@safe @nogc pure nothrow:

	//TODO: use NameAndRange (more compact)
	FileAndRange range;
	Sym name;
	LocalMutability mutability;
	Type type;

	bool isAllocated() {
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
Mutability toMutability(LocalMutability a) {
	final switch (a) {
		case LocalMutability.immut:
			return Mutability.immut;
		case LocalMutability.mutOnStack:
		case LocalMutability.mutAllocated:
			return Mutability.mut;
	}
}

immutable struct ClosureRef {
	@safe @nogc pure nothrow:

	PtrAndSmallNumber!(ExprKind.Lambda) lambdaAndIndex;

	ulong asTaggable() =>
		lambdaAndIndex.asTaggable;
	static ClosureRef fromTagged(ulong x) =>
		ClosureRef(PtrAndSmallNumber!(ExprKind.Lambda).fromTagged(x));

	ExprKind.Lambda* lambda() =>
		lambdaAndIndex.ptr;

	ushort index() =>
		lambdaAndIndex.number;

	VariableRef variableRef() =>
		lambda.closure[index];
}

enum ClosureReferenceKind { direct, allocated }
Sym symOfClosureReferenceKind(ClosureReferenceKind a) {
	final switch (a) {
		case ClosureReferenceKind.direct:
			return sym!"direct";
		case ClosureReferenceKind.allocated:
			return sym!"allocated";
	}
}
ClosureReferenceKind getClosureReferenceKind(ClosureRef a) =>
	getClosureReferenceKind(a.variableRef);
private ClosureReferenceKind getClosureReferenceKind(VariableRef a) {
	final switch (toLocal(a).mutability) {
		case LocalMutability.immut:
			return ClosureReferenceKind.direct;
		case LocalMutability.mutOnStack:
			return unreachable!ClosureReferenceKind;
		case LocalMutability.mutAllocated:
			return ClosureReferenceKind.allocated;
	}
}

immutable struct VariableRef {
	mixin Union!(Local*, ClosureRef);
}
static assert(VariableRef.sizeof == ulong.sizeof);

Sym name(VariableRef a) =>
	toLocal(a).name;
Type variableRefType(VariableRef a) =>
	toLocal(a).type;

private Local* toLocal(VariableRef a) =>
	a.matchWithPointers!(Local*)(
		(Local* x) =>
			x,
		(ClosureRef x) =>
			toLocal(x.variableRef()));

immutable struct Destructure {
	@safe @nogc pure nothrow:

	immutable struct Ignore {
		Pos pos;
		Type type;
	}
	immutable struct Split {
		StructInst* type; // This will be a tuple instance
		SmallArray!Destructure parts;
	}
	mixin Union!(Ignore*, Local*, Split*);

	Opt!Sym name() scope =>
		matchIn!(Opt!Sym)(
			(in Destructure.Ignore _) =>
				none!Sym,
			(in Local x) =>
				some(x.name),
			(in Destructure.Split _) =>
				none!Sym);

	Opt!RangeWithinFile nameRange(in AllSymbols allSymbols) scope {
		Opt!Sym name = name;
		return has(name)
			? some(rangeOfNameAndRange(NameAndRange(range.start, force(name)), allSymbols))
			: none!RangeWithinFile;
	}

	RangeWithinFile range() scope =>
		matchIn!RangeWithinFile(
			(in Ignore x) =>
				RangeWithinFile(x.pos, x.pos + 1),
			(in Local x) =>
				x.range.range,
			(in Split x) =>
				combineRanges(x.parts[0].range, x.parts[$ - 1].range));
	
	Type type() scope =>
		matchIn!Type(
			(in Ignore x) =>
				x.type,
			(in Local x) =>
				x.type,
			(in Split x) =>
				Type(x.type));
}

immutable struct Expr {
	FileAndRange range;
	ExprKind kind;
}

immutable struct ExprKind {
	@safe @nogc pure nothrow:

	immutable struct AssertOrForbid {
		AssertOrForbidKind kind;
		Expr* condition;
		Opt!(Expr*) thrown;
	}

	immutable struct Bogus {}

	immutable struct Call {
		Called called;
		Expr[] args;
	}

	immutable struct ClosureGet {
		// TODO: by value (causes forward reference error on dmd 2.100 but not on dmd 2.101)
		ClosureRef* closureRef;
	}

	immutable struct ClosureSet {
		// TODO: by value (causes forward reference error on dmd 2.100 but not on dmd 2.101)
		ClosureRef* closureRef;
		Expr* value;
	}

	immutable struct Cond {
		Type type;
		Expr cond;
		Expr then;
		Expr else_;
	}

	immutable struct Drop {
		Expr arg;
	}

	immutable struct FunPtr {
		FunInst* funInst;
		StructInst* structInst;
	}

	immutable struct IfOption {
		Type type;
		Destructure destructure;
		Expr option;
		Expr then;
		Expr else_;
	}

	immutable struct Lambda {
		Destructure param;
		Expr body_;
		VariableRef[] closure;
		// This is the function type
		StructInst* funType;
		FunKind kind;
		// For FunKind.send this includes 'future' wrapper
		Type returnType;
	}

	immutable struct Let {
		Destructure destructure;
		Expr value;
		Expr then;
	}

	immutable struct Literal {
		StructInst* structInst;
		Constant value;
	}

	immutable struct LiteralCString {
		SafeCStr value;
	}

	immutable struct LiteralSymbol {
		Sym value;
	}

	immutable struct LocalGet {
		Local* local;
	}

	immutable struct LocalSet {
		Local* local;
		Expr value;
	}

	immutable struct Loop {
		Type type;
		Expr body_;
	}

	immutable struct LoopBreak {
		Loop* loop;
		Expr value;
	}

	immutable struct LoopContinue {
		Loop* loop;
	}

	immutable struct LoopUntil {
		Expr condition;
		Expr body_;
	}

	immutable struct LoopWhile {
		Expr condition;
		Expr body_;
	}

	immutable struct MatchEnum {
		Expr matched;
		Expr[] cases;
		Type type;
	}

	immutable struct MatchUnion {
		immutable struct Case {
			Destructure destructure;
			Expr then;
		}

		Expr matched;
		Case[] cases;
		Type type;
	}

	immutable struct PtrToField {
		Type pointerType;
		Expr target; // This will be a pointer or by-ref type
		size_t fieldIndex;
	}

	immutable struct PtrToLocal {
		Type ptrType;
		Local* local;
	}

	immutable struct Seq {
		Expr first;
		Expr then;
	}

	immutable struct Throw {
		Type type;
		Expr thrown;
	}

	mixin Union!(
		AssertOrForbid,
		Bogus,
		Call,
		ClosureGet,
		ClosureSet,
		Cond*,
		Drop*,
		FunPtr,
		IfOption*,
		Lambda*,
		Let*,
		Literal*,
		LiteralCString,
		LiteralSymbol,
		LocalGet,
		LocalSet*,
		Loop*,
		LoopBreak*,
		LoopContinue,
		LoopUntil*,
		LoopWhile*,
		MatchEnum*,
		MatchUnion*,
		PtrToField*,
		PtrToLocal,
		Seq*,
		Throw*);
}

enum AssertOrForbidKind { assert_, forbid }

Sym symOfAssertOrForbidKind(AssertOrForbidKind a) {
	final switch (a) {
		case AssertOrForbidKind.assert_:
			return sym!"assert";
		case AssertOrForbidKind.forbid:
			return sym!"forbid";
	}
}

void writeStructDecl(scope ref Writer writer, in AllSymbols allSymbols, in Program program, in StructDecl a) {
	writeSym(writer, allSymbols, a.name);
}

void writeStructInst(scope ref Writer writer, in AllSymbols allSymbols, in Program program, in StructInst s) {
	void dict(string open) {
		Type[2] vk = only2(s.typeArgs);
		writeTypeUnquoted(writer, allSymbols, program, vk[0]);
		writer ~= open;
		writeTypeUnquoted(writer, allSymbols, program, vk[1]);
		writer ~= ']';
	}
	void fun(string keyword) {
		writer ~= keyword;
		writer ~= ' ';
		Type[2] rp = only2(s.typeArgs);
		writeTypeUnquoted(writer, allSymbols, program, rp[0]);
		Type param = rp[1];
		bool needParens = !(param.isA!(StructInst*) && isTuple(program.commonTypes, *param.as!(StructInst*)));
		if (needParens) writer ~= '(';
		writeTypeUnquoted(writer, allSymbols, program, param);
		if (needParens) writer ~= ')';
	}
	void suffix(string suffix) {
		writeTypeUnquoted(writer, allSymbols, program, only(s.typeArgs));
		writer ~= suffix;	
	}

	Sym name = decl(s).name;
	Opt!(Diag.TypeShouldUseSyntax.Kind) kind = typeSyntaxKind(name);
	if (has(kind)) {
		final switch (force(kind)) {
			case Diag.TypeShouldUseSyntax.Kind.dict:
				return dict("[");
			case Diag.TypeShouldUseSyntax.Kind.funAct:
				return fun("act");
			case Diag.TypeShouldUseSyntax.Kind.funFar:
				return fun("far");
			case Diag.TypeShouldUseSyntax.Kind.funFun:
				return fun("fun");
			case Diag.TypeShouldUseSyntax.Kind.future:
				return suffix("^");
			case Diag.TypeShouldUseSyntax.Kind.list:
				return suffix("[]");
			case Diag.TypeShouldUseSyntax.Kind.mutDict:
				return dict(" mut[");
			case Diag.TypeShouldUseSyntax.Kind.mutList:
				return suffix(" mut[]");
			case Diag.TypeShouldUseSyntax.Kind.mutPointer:
				return suffix(" mut*");
			case Diag.TypeShouldUseSyntax.Kind.opt:
				return suffix("?");
			case Diag.TypeShouldUseSyntax.Kind.pointer:
				return suffix("*");
			case Diag.TypeShouldUseSyntax.Kind.tuple:
				return writeTupleType(writer, allSymbols, program, s.typeArgs);
		}
	} else {
		switch (s.typeArgs.length) {
			case 0:
				break;
			case 1:
				writeTypeUnquoted(writer, allSymbols, program, only(s.typeArgs));
				writer ~= ' ';
				break;
			default:
				writeTupleType(writer, allSymbols, program, s.typeArgs);
				writer ~= ' ';
				break;
		}
		writeSym(writer, allSymbols, name);
	}
}

private void writeTupleType(scope ref Writer writer, in AllSymbols allSymbols, in Program program, in Type[] members) {
	writer ~= '(';
	writeWithCommas!Type(writer, members, (in Type arg) {
		writeTypeUnquoted(writer, allSymbols, program, arg);
	});
	writer ~= ')';
}

void writeTypeArgsGeneric(T)(
	scope ref Writer writer,
	in T[] typeArgs,
	in bool delegate(in T) @safe @nogc pure nothrow isSimpleType,
	in void delegate(in T) @safe @nogc pure nothrow cbWriteType,
) {
	if (!empty(typeArgs)) {
		writer ~= '@';
		if (typeArgs.length == 1 && isSimpleType(only(typeArgs)))
			cbWriteType(only(typeArgs));
		else {
			writer ~= '(';
			writeWithCommas!T(writer, typeArgs, cbWriteType);
			writer ~= ')';
		}
	}
}

void writeTypeArgs(scope ref Writer writer, in AllSymbols allSymbols, in Program program, in Type[] types) {
	writeTypeArgsGeneric!Type(writer, types,
		(in Type x) =>
			!x.isA!(StructInst*) || empty(typeArgs(*x.as!(StructInst*))),
		(in Type x) {
			writeTypeUnquoted(writer, allSymbols, program, x);
		});
}

void writeTypeQuoted(scope ref Writer writer, in AllSymbols allSymbols, in Program program, in Type a) {
	writer ~= '\'';
	writeTypeUnquoted(writer, allSymbols, program, a);
	writer ~= '\'';
}

//TODO:MOVE
void writeTypeUnquoted(ref Writer writer, in AllSymbols allSymbols, in Program program, in Type a) {
	a.matchIn!void(
		(in Type.Bogus) {
			writer ~= "<<bogus>>";
		},
		(in TypeParam x) {
			writeSym(writer, allSymbols, x.name);
		},
		(in StructInst x) {
			writeStructInst(writer, allSymbols, program, x);
		});
}

alias Visibility = immutable Visibility_;
private enum Visibility_ : ubyte {
	private_,
	internal,
	public_,
}

Sym symOfVisibility(Visibility a) {
	final switch (a) {
		case Visibility.internal:
			return sym!"internal";
		case Visibility.public_:
			return sym!"public";
		case Visibility.private_:
			return sym!"private";
	}
}

Visibility leastVisibility(Visibility a, Visibility b) =>
	min(a, b);
