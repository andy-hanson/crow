module model.model;

@safe @nogc pure nothrow:

import frontend.parse.ast :
	DestructureAst,
	FunDeclAst,
	NameAndRange,
	rangeOfDestructureSingle,
	rangeOfNameAndRange,
	StructDeclAst;
import model.concreteModel : TypeSize;
import model.constant : Constant;
import model.diag : Diagnostics;
import util.col.arr : arrayOfSingle, empty, PtrAndSmallNumber, small, SmallArray;
import util.col.arrUtil : arrEqual;
import util.col.map : Map;
import util.col.enumMap : EnumMap;
import util.col.str : SafeCStr, safeCStr;
import util.hash : Hasher;
import util.late : Late, lateGet, lateIsSet, lateSet, lateSetOverwrite;
import util.opt : force, has, none, Opt, some;
import util.ptr : hashPtr;
import util.sourceRange :
	combineRanges, UriAndPos, UriAndRange, fileAndRangeFromUriAndPos, Pos, rangeOfStartAndName, RangeWithinFile;
import util.sym : AllSymbols, Sym, sym;
import util.union_ : Union;
import util.uri : Uri;
import util.util : max, min, typeAs, unreachable, verify;

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
	UriAndRange range;
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
	UriAndRange range;
	Sym name;
	Type returnType;
	SmallArray!Destructure params;
}

immutable struct TypeParamsAndSig {
	TypeParam[] typeParams;
	Type returnType;
	ParamShort[] params;
}
immutable struct ParamShort {
	Sym name;
	Type type;
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
	StructDeclAst.Body.Record.Field* ast;
	StructDecl* containingRecord;
	Visibility visibility;
	Sym name;
	FieldMutability mutability;
	Type type;
}

RangeWithinFile range(in RecordField a) =>
	a.ast.range;

UriAndRange uriAndRange(in RecordField a) =>
	UriAndRange(a.containingRecord.moduleUri, a.ast.range);

immutable struct UnionMember {
	//TODO: use NameAndRange (more compact)
	UriAndRange range;
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
			UriAndRange range;
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
	UriAndRange range;
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

Sym symOfLinkage(Linkage a) {
	final switch (a) {
		case Linkage.internal:
			return sym!"internal";
		case Linkage.extern_:
			return sym!"extern";
	}
}

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
	@safe @nogc pure nothrow:

	Opt!(StructDeclAst*) ast;
	Uri moduleUri;
	Sym name;
	SmallArray!TypeParam typeParams;
	Visibility visibility;
	Linkage linkage;
	// Note: purity on the decl does not take type args into account
	Purity purity;
	bool purityIsForced;

	private Late!StructBody lateBody;

	SafeCStr docComment() scope =>
		has(ast) ? force(ast).docComment : safeCStr!"";

	UriAndRange range() scope =>
		UriAndRange(moduleUri, has(ast) ? force(ast).range : RangeWithinFile.empty);
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
	UriAndRange range;
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

Sym symOfVarKind(in VarKind a) {
	final switch (a) {
		case VarKind.global:
			return sym!"global";
		case VarKind.threadLocal:
			return sym!"thread-local";
	}
}

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
	immutable struct RecordFieldPointer {
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
		RecordFieldPointer,
		RecordFieldSet,
		VarGet,
		VarSet);
}

immutable struct FunFlags {
	@safe @nogc pure nothrow:

	bool bare;
	bool summon;
	enum Safety : ubyte { safe, unsafe }
	Safety safety;
	bool preferred;
	bool okIfUnused;
	enum SpecialBody : ubyte { none, builtin, extern_, generated }
	SpecialBody specialBody;
	bool forceCtx;

	FunFlags withOkIfUnused() =>
		FunFlags(bare, summon, safety, preferred, true, specialBody, forceCtx);
	FunFlags withSummon() =>
		FunFlags(bare, true, safety, preferred, okIfUnused, specialBody, forceCtx);

	static FunFlags regular(bool bare, bool summon, Safety safety, SpecialBody specialBody, bool forceCtx) =>
		FunFlags(bare, summon, safety, false, false, specialBody, forceCtx);

	static FunFlags none() =>
		FunFlags(false, false, Safety.safe, false, false, SpecialBody.none);
	static FunFlags generatedBare() =>
		FunFlags(true, false, Safety.safe, false, true, SpecialBody.generated);
	static FunFlags generatedBareUnsafe() =>
		FunFlags(true, false, Safety.unsafe, false, true, SpecialBody.generated);
	static FunFlags generated() =>
		FunFlags(false, false, Safety.safe, false, true, SpecialBody.generated);
}
static assert(FunFlags.sizeof == 7);

immutable struct FunDeclSource {
	@safe @nogc pure nothrow:

	immutable struct Bogus {
		Uri uri;
	}
	immutable struct Ast {
		Uri uri;
		FunDeclAst* ast;
	}
	immutable struct FileImport {
		UriAndRange range;
	}

	mixin Union!(Bogus, Ast, FileImport, StructBody.Enum.Member*, StructDecl*, VarDecl*);

	UriAndRange range() scope =>
		matchIn!UriAndRange(
			(in FunDeclSource.Bogus x) =>
				UriAndRange(x.uri, RangeWithinFile.empty),
			(in FunDeclSource.Ast x) =>
				UriAndRange(x.uri, x.ast.range),
			(in FunDeclSource.FileImport x) =>
				x.range,
			(in StructBody.Enum.Member x) =>
				x.range,
			(in StructDecl x) =>
				x.range,
			(in VarDecl x) =>
				x.range);
}

immutable struct FunDecl {
	@safe @nogc pure nothrow:

	FunDeclSource* source;
	Visibility visibility;
	Sym name;
	SmallArray!TypeParam typeParams;
	Type returnType;
	Params params;
	FunFlags flags;
	SmallArray!(immutable SpecInst*) specs;
	private Late!FunBody lateBody;

	UriAndRange range() scope =>
		source.range;

	ref FunBody body_() return scope =>
		lateGet(lateBody);

	void setBody(FunBody b) {
		lateSet(lateBody, b);
	}
}

Linkage linkage(in FunDecl a) =>
	a.body_.isA!(FunBody.Extern) ? Linkage.extern_ : Linkage.internal;

bool isBare(in FunDecl a) =>
	a.flags.bare;
bool isGenerated(in FunDecl a) =>
	a.flags.specialBody == FunFlags.SpecialBody.generated;
bool isSummon(in FunDecl a) =>
	a.flags.summon;
bool isUnsafe(in FunDecl a) =>
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

UriAndRange range(ref StructOrAlias a) =>
	a.match!UriAndRange(
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

	UriAndPos pos;
	SafeCStr docComment;
	Visibility visibility;
	Sym name;
	VarKind kind;
	Type type;
	Opt!Sym externLibraryName;

	UriAndRange range() scope =>
		fileAndRangeFromUriAndPos(pos);
}

immutable struct Module {
	@safe @nogc pure nothrow:

	Uri uri;
	SafeCStr docComment;
	ImportOrExport[] imports; // includes import of std (if applicable)
	ImportOrExport[] reExports;
	StructDecl[] structs;
	VarDecl[] vars;
	SpecDecl[] specs;
	FunDecl[] funs;
	Test[] tests;
	// Includes re-exports
	Map!(Sym, NameReferents) allExportedNames;

	UriAndRange range() scope =>
		UriAndRange.topOfFile(uri);
}
Module emptyModule(Uri uri) =>
	Module(uri, safeCStr!"", [], [], [], [], [], [], [], Map!(Sym, NameReferents)());

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

enum ImportFileType { nat8Array, string }

Sym symOfImportFileType(ImportFileType a) {
	final switch (a) {
		case ImportFileType.nat8Array:
			return sym!"nat8Array";
		case ImportFileType.string:
			return sym!"string";
	}
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

immutable struct MainFun {
	immutable struct Nat64Future {
		FunInst* fun;
	}

	immutable struct Void {
		// Needed to wrap it to the natFuture signature
		StructInst* stringList;
		FunInst* fun;
	}

	mixin Union!(Nat64Future, Void);
}

immutable struct CommonFuns {
	FunInst* alloc;
	FunDecl*[] funOrActSubscriptFunDecls;
	FunInst* curExclusion;
	// Missing for the 'doc' command which has no 'main' module
	Opt!MainFun main;
	FunInst* mark;
	FunDecl* markVisitFunDecl;
	FunInst* newNat64Future;
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
	StructDecl* array;
	StructDecl* future;
	StructDecl* opt;
	StructDecl* ptrConst;
	StructDecl* ptrMut;
	// No tuple0 and tuple1, so this is 2-9 inclusive
	StructDecl*[8] tuples2Through9;
	// Indexed by FunKind, then by arity. (arity = typeArgs.length - 1)
	EnumMap!(FunKind, StructDecl*) funStructs;

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
	Config config;
	Map!(Uri, immutable Module*) allModules;
	Module*[] rootModules;
	CommonFuns commonFuns;
	CommonTypes commonTypes;
	Diagnostics diagnostics;
}
Program fakeProgramForTest() =>
	fakeProgramForDiagnostics(Diagnostics());
Program fakeProgramForDiagnostics(Diagnostics diagnostics) =>
	Program(Config(), Map!(Uri, immutable Module*)(), [], CommonFuns(), CommonTypes(), diagnostics);

immutable struct Config {
	Uri crowIncludeDir;
	ConfigImportUris include;
	ConfigExternUris extern_;
}

alias ConfigImportUris = Map!(Sym, Uri);
alias ConfigExternUris = Map!(Sym, Uri);

immutable struct LocalSource {
	immutable struct Ast {
		Uri uri;
		DestructureAst.Single* ast;
	}
	immutable struct Generated {}
	mixin Union!(Ast, Generated);
}

immutable struct Local {
	@safe @nogc pure nothrow:

	LocalSource source;
	Sym name;
	LocalMutability mutability;
	Type type;
}

bool localIsAllocated(in Local a) scope {
	final switch (a.mutability) {
		case LocalMutability.immut:
		case LocalMutability.mutOnStack:
			return false;
		case LocalMutability.mutAllocated:
			return true;
	}
}

UriAndRange localMustHaveRange(in Local a, in AllSymbols allSymbols) =>
	UriAndRange(a.source.as!(LocalSource.Ast).uri, rangeOfDestructureSingle(*a.source.as!(LocalSource.Ast).ast, allSymbols));

enum LocalMutability {
	immut,
	mutOnStack, // Mutable and on the stack
	mutAllocated, // Mutable and must be heap-allocated since it's used in a closure
}

Sym symOfLocalMutability(LocalMutability a) {
	final switch (a) {
		case LocalMutability.immut:
			return sym!"immut";
		case LocalMutability.mutOnStack:
			return sym!"mutOnStack";
		case LocalMutability.mutAllocated:
			return sym!"mutAllocated";
	}
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

	Sym name() =>
		toLocal(this).name;

	Type type() =>
		toLocal(this).type;
}

Local* toLocal(in ClosureRef a) =>
	toLocal(a.variableRef);

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
		Type destructuredType; // This will be a tuple instance or Bogus.
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
			? some(rangeOfNameAndRange(NameAndRange(range(allSymbols).start, force(name)), allSymbols))
			: none!RangeWithinFile;
	}

	RangeWithinFile range(in AllSymbols allSymbols) scope =>
		matchIn!RangeWithinFile(
			(in Ignore x) =>
				RangeWithinFile(x.pos, x.pos + 1),
			(in Local x) =>
				localMustHaveRange(x, allSymbols).range,
			(in Split x) =>
				combineRanges(x.parts[0].range(allSymbols), x.parts[$ - 1].range(allSymbols)));

	Type type() scope =>
		matchIn!Type(
			(in Ignore x) =>
				x.type,
			(in Local x) =>
				x.type,
			(in Split x) =>
				x.destructuredType);
}

immutable struct Expr {
	UriAndRange range;
	ExprKind kind;
}

immutable struct ExprAndType {
	Expr expr;
	Type type;
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

	immutable struct FunPtr {
		FunInst* funInst;
	}

	immutable struct If {
		Expr cond;
		Expr then;
		Expr else_;
	}

	immutable struct IfOption {
		Destructure destructure;
		ExprAndType option;
		Expr then;
		Expr else_;
	}

	immutable struct Lambda {
		Destructure param;
		Expr body_;
		VariableRef[] closure;
		FunKind kind;
		// For FunKind.far this includes 'future' wrapper
		Type returnType;
	}

	immutable struct Let {
		Destructure destructure;
		Expr value;
		Expr then;
	}

	immutable struct Literal {
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
		RangeWithinFile range;
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
		ExprAndType matched;
		Expr[] cases;
	}

	immutable struct MatchUnion {
		immutable struct Case {
			Destructure destructure;
			Expr then;
		}

		ExprAndType matched;
		Case[] cases;
	}

	immutable struct PtrToField {
		ExprAndType target; // This will be a pointer or by-ref type
		size_t fieldIndex;
	}

	immutable struct PtrToLocal {
		Local* local;
	}

	immutable struct Seq {
		Expr first;
		Expr then;
	}

	immutable struct Throw {
		Expr thrown;
	}

	mixin Union!(
		AssertOrForbid,
		Bogus,
		Call,
		ClosureGet,
		ClosureSet,
		FunPtr,
		If*,
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
