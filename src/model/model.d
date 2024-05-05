module model.model;

@safe @nogc pure nothrow:

import frontend.getDiagnosticSeverity : getDiagnosticSeverity;
import model.ast :
	DestructureAst,
	EnumOrFlagsMemberAst,
	ExprAst,
	FileAst,
	FunDeclAst,
	IfAst,
	ImportOrExportAst,
	NameAndRange,
	RecordOrUnionMemberAst,
	SpecDeclAst,
	SpecSigAst,
	StructAliasAst,
	StructDeclAst,
	TestAst,
	VarDeclAst,
	VariantMemberAst;
import model.concreteModel : TypeSize;
import model.constant : Constant;
import model.diag : Diag, Diagnostic, isFatal, UriAndDiagnostic;
import model.parseDiag : ParseDiagnostic;
import util.alloc.alloc : Alloc;
import util.col.array :
	arrayOfSingle,
	emptySmallArray,
	every,
	exists,
	first,
	isEmpty,
	mustHaveIndexOfPointer,
	newArray,
	only,
	PtrAndSmallNumber,
	SmallArray,
	sum;
import util.col.hashTable : existsInHashTable, HashTable;
import util.col.map : Map;
import util.col.enumMap : EnumMap;
import util.conv : safeToUint;
import util.integralValues : IntegralValue;
import util.late : Late, lateGet, lateIsSet, lateSet, lateSetOverwrite;
import util.opt : force, has, none, Opt, optEqual, some;
import util.sourceRange : combineRanges, UriAndRange, Pos, Range;
import util.string : emptySmallString, SmallString;
import util.symbol : Symbol, symbol;
import util.union_ : IndexType, TaggedUnion, Union;
import util.uri : Uri;
import util.util : enumConvertOrAssert, max, min, stringOfEnum;
import versionInfo : VersionFun;

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

alias TypeParams = SmallArray!NameAndRange;
TypeParams emptyTypeParams() =>
	emptySmallArray!NameAndRange;
alias TypeArgs = SmallArray!Type;
TypeArgs emptyTypeArgs() =>
	emptySmallArray!Type;
alias SpecImpls = SmallArray!Called;
SpecImpls emptySpecImpls() =>
	emptySmallArray!Called;
alias Specs = SmallArray!(immutable SpecInst*);
Specs emptySpecs() =>
	emptySmallArray!(immutable SpecInst*);

// Represent type parameter as the index, so we don't generate different types for every `t list`.
// (These are disambiguated in the type checker using `TypeAndContext`)
immutable struct TypeParamIndex {
	mixin IndexType;
}

immutable struct Type {
	@safe @nogc pure nothrow:
	immutable struct Bogus {}
	mixin TaggedUnion!(Bogus, TypeParamIndex, StructInst*);

	static Type bogus() =>
		Type(Type.Bogus());

	bool isBogus() scope =>
		isA!Bogus;

	bool opEquals(scope Type b) scope =>
		taggedPointerEquals(b);
}

PurityRange purityRange(Type a) =>
	a.matchIn!PurityRange(
		(in Type.Bogus) =>
			PurityRange(Purity.data, Purity.data),
		(in TypeParamIndex _) =>
			PurityRange(Purity.data, Purity.mut),
		(in StructInst x) =>
			x.purityRange);

Purity bestCasePurity(Type a) =>
	purityRange(a).bestCase;

Purity worstCasePurity(Type a) =>
	purityRange(a).worstCase;

LinkageRange linkageRange(Type a) =>
	a.matchIn!LinkageRange(
		(in Type.Bogus) =>
			LinkageRange(Linkage.extern_, Linkage.extern_),
		(in TypeParamIndex _) =>
			LinkageRange(Linkage.internal, Linkage.extern_),
		(in StructInst x) =>
			x.linkageRange);

immutable struct Params {
	@safe @nogc pure nothrow:

	immutable struct Varargs {
		Destructure param;
		Type elementType;
	}

	mixin TaggedUnion!(SmallArray!Destructure, Varargs*);

	Arity arity() scope =>
		matchIn!Arity(
			(in Destructure[] params) =>
				Arity(safeToUint(params.length)),
			(in Params.Varargs) =>
				Arity(Arity.Varargs()));
}

Destructure[] paramsArray(return scope Params a) =>
	a.matchWithPointers!(Destructure[])(
		(Destructure[] x) =>
			x,
		(Params.Varargs* x) =>
			arrayOfSingle(&x.param));

Destructure[] assertNonVariadic(Params a) =>
	a.as!(Destructure[]);

private immutable struct Arity {
	@safe @nogc pure nothrow:
	immutable struct Varargs {}
	mixin TaggedUnion!(immutable uint, Varargs);

	uint countParamDecls() =>
		matchIn!uint(
			(in uint x) => x,
			(in Varargs) => 1);
}

bool arityMatches(Arity sigArity, size_t nArgs) =>
	sigArity.match!bool(
		(uint nParams) =>
			nParams == nArgs,
		(Arity.Varargs) =>
			true);

immutable struct SpecDeclSig {
	@safe @nogc pure nothrow:

	Uri moduleUri;
	SpecSigAst* ast;
	Type returnType;
	SmallArray!Destructure params;

	Symbol name() scope =>
		ast.name;
	UriAndRange range() scope =>
		UriAndRange(moduleUri, ast.range);
	UriAndRange nameRange() scope =>
		UriAndRange(moduleUri, ast.nameAndRange.range);
}

immutable struct TypeParamsAndSig {
	TypeParams typeParams;
	Type returnType;
	ParamsShort params;
	uint countSpecs;
}
immutable struct ParamsShort {
	immutable struct Variadic { ParamShort param; Type elementType; }
	mixin TaggedUnion!(SmallArray!ParamShort, Variadic*);
}
immutable struct ParamShort {
	Symbol name;
	Type type;
}

immutable struct RecordOrUnionMemberSource {
	@safe @nogc pure nothrow:
	mixin TaggedUnion!(DestructureAst.Single*, RecordOrUnionMemberAst*);

	Symbol name() scope =>
		matchIn!Symbol(
			(in DestructureAst.Single x) =>
				x.name.name,
			(in RecordOrUnionMemberAst x) =>
				x.name.name);

	Range range() scope =>
		matchIn!Range(
			(in DestructureAst.Single x) =>
				x.range,
			(in RecordOrUnionMemberAst x) =>
				x.range);

	Range nameRange() scope =>
		matchIn!Range(
			(in DestructureAst.Single x) =>
				x.nameRange,
			(in RecordOrUnionMemberAst x) =>
				x.nameRange);
}

immutable struct RecordField {
	@safe @nogc pure nothrow:

	RecordOrUnionMemberSource source;
	StructDecl* containingRecord;
	Visibility visibility;
	Opt!Visibility mutability;
	Type type;

	Uri moduleUri() scope =>
		containingRecord.moduleUri;
	Symbol name() scope =>
		source.name;
	Range range() scope =>
		source.range;
	UriAndRange nameRange() scope =>
		UriAndRange(moduleUri, source.nameRange);
}

immutable struct UnionMember {
	@safe @nogc pure nothrow:

	RecordOrUnionMemberSource source;
	StructDecl* containingUnion;
	Type type; // This will be 'void' if no type is specified

	size_t memberIndex() =>
		mustHaveIndexOfPointer(containingUnion.body_.as!(StructBody.Union*).members, &this);
	Uri moduleUri() scope =>
		containingUnion.moduleUri;
	Visibility visibility() scope =>
		containingUnion.visibility;
	Symbol name() scope =>
		source.name;
	Range range() scope =>
		source.range;
	UriAndRange nameRange() scope =>
		UriAndRange(moduleUri, source.nameRange);
}

immutable struct VariantMember {
	@safe @nogc pure nothrow:

	VariantMemberAst* ast;
	Uri moduleUri;
	Visibility visibility;
	StructInst* variant;
	Type type;

	SmallString docComment() return scope =>
		ast.docComment;
	Symbol name() scope =>
		ast.name.name;
	TypeParams typeParams() return scope =>
		ast.typeParams;
	UriAndRange range() scope =>
		UriAndRange(moduleUri, ast.range);
	UriAndRange nameRange() scope =>
		UriAndRange(moduleUri, ast.name.range);
}

alias ByValOrRef = immutable ByValOrRef_;
private enum ByValOrRef_ : ubyte {
	byVal,
	byRef,
}

immutable struct RecordFlags {
	Visibility newVisibility;
	bool nominal;
	bool packed;
	Opt!ByValOrRef forcedByValOrRef;
}
static assert(RecordFlags.sizeof == uint.sizeof);

immutable struct EnumMemberSource {
	@safe @nogc pure nothrow:
	mixin TaggedUnion!(EnumOrFlagsMemberAst*, DestructureAst.Single*);

	Symbol name() scope =>
		matchIn!Symbol(
			(in EnumOrFlagsMemberAst x) => x.name,
			(in DestructureAst.Single x) => x.name.name);
	Range range() scope =>
		matchIn!Range(
			(in EnumOrFlagsMemberAst x) => x.range,
			(in DestructureAst.Single x) => x.range);
	Range nameRange() scope =>
		matchIn!Range(
			(in EnumOrFlagsMemberAst x) => x.nameRange,
			(in DestructureAst.Single x) => x.nameRange);
}

immutable struct EnumOrFlagsMember {
	@safe @nogc pure nothrow:

	EnumMemberSource source;
	StructDecl* containingEnum;
	IntegralValue value;

	size_t memberIndex() =>
		mustHaveIndexOfPointer(containingEnum.body_.as!(StructBody.Enum*).members, &this);
	Uri moduleUri() scope =>
		containingEnum.moduleUri;
	Visibility visibility() scope =>
		containingEnum.visibility;
	Symbol name() scope =>
		source.name;
	Range range() scope =>
		source.range;
	UriAndRange nameRange() scope =>
		UriAndRange(moduleUri, source.nameRange);
}

immutable struct StructBody {
	immutable struct Bogus {}
	immutable struct Enum {
		IntegralType storage;
		SmallArray!EnumOrFlagsMember members;
		HashTable!(EnumOrFlagsMember*, Symbol, nameOfEnumOrFlagsMember) membersByName;
	}
	immutable struct Extern {
		Opt!TypeSize size;
	}
	immutable struct Flags {
		IntegralType storage;
		SmallArray!EnumOrFlagsMember members;
	}
	immutable struct Record {
		RecordFlags flags;
		SmallArray!RecordField fields;
	}
	immutable struct Union {
		SmallArray!UnionMember members;
		HashTable!(UnionMember*, Symbol, nameOfUnionMember) membersByName;
	}
	immutable struct Variant {}

	mixin .Union!(Bogus, BuiltinType, Enum*, Extern, Flags, Record, Union*, Variant);
}
static assert(StructBody.sizeof == StructBody.Record.sizeof + size_t.sizeof);

Symbol nameOfEnumOrFlagsMember(in EnumOrFlagsMember* a) =>
	a.name;
Symbol nameOfUnionMember(in UnionMember* a) =>
	a.name;

enum BuiltinType {
	bool_,
	char8,
	char32,
	float32,
	float64,
	funPointer,
	int8,
	int16,
	int32,
	int64,
	lambda, // 'data', 'shared', or 'mut' lambda type. Not 'function'.
	nat8,
	nat16,
	nat32,
	nat64,
	pointerConst,
	pointerMut,
	void_,
}
bool isCharOrIntegral(BuiltinType a) {
	final switch (a) {
		case BuiltinType.char8:
		case BuiltinType.char32:
		case BuiltinType.int8:
		case BuiltinType.int16:
		case BuiltinType.int32:
		case BuiltinType.int64:
		case BuiltinType.nat8:
		case BuiltinType.nat16:
		case BuiltinType.nat32:
		case BuiltinType.nat64:
			return true;
		case BuiltinType.bool_:
		case BuiltinType.float32:
		case BuiltinType.float64:
		case BuiltinType.funPointer:
		case BuiltinType.lambda:
		case BuiltinType.pointerConst:
		case BuiltinType.pointerMut:
		case BuiltinType.void_:
			return false;
	}
}
bool isPointer(BuiltinType a) =>
	a == BuiltinType.pointerConst || a == BuiltinType.pointerMut;

immutable struct StructAlias {
	@safe @nogc pure nothrow:

	StructAliasAst* ast;
	Uri moduleUri;
	Visibility visibility;
	private Late!(StructInst*) target_;

	SmallString docComment() return scope =>
		ast.docComment;

	Symbol name() scope =>
		ast.name.name;
	TypeParams typeParams() return scope =>
		emptyTypeParams;

	UriAndRange range() scope =>
		UriAndRange(moduleUri, ast.range);
	UriAndRange nameRange() scope =>
		UriAndRange(moduleUri, ast.nameRange);

	StructInst* target() return scope =>
		lateGet(target_);
	void target(StructInst* value) {
		lateSet(target_, value);
	}
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
	@safe @nogc pure nothrow:

	StructDeclSource source;
	Uri moduleUri;
	Visibility visibility;
	Linkage linkage;
	// Note: purity on the decl does not take type args into account
	Purity purity;
	bool purityIsForced;

	private Late!StructBody lateBody;

	bool bodyIsSet() =>
		lateIsSet(lateBody);

	ref StructBody body_() return scope =>
		lateGet(lateBody);

	void body_(StructBody value) {
		lateSet(lateBody, value);
	}

	SmallString docComment() return scope =>
		source.match!SmallString(
			(ref StructDeclAst x) =>
				x.docComment,
			(ref StructDeclSource.Bogus) =>
				emptySmallString);
	TypeParams typeParams() return scope =>
		source.match!TypeParams(
			(ref StructDeclAst x) =>
				x.typeParams,
			(ref StructDeclSource.Bogus x) =>
				x.typeParams);
	Symbol name() scope =>
		source.matchIn!Symbol(
			(in StructDeclAst x) =>
				x.name.name,
			(in StructDeclSource.Bogus x) =>
				x.name);

	UriAndRange range() scope =>
		UriAndRange(moduleUri, source.matchIn!Range(
			(in StructDeclAst x) =>
				x.range,
			(in StructDeclSource.Bogus) =>
				Range.empty));

	UriAndRange nameRange() scope =>
		UriAndRange(moduleUri, source.matchIn!Range(
			(in StructDeclAst x) =>
				x.nameRange,
			(in StructDeclSource.Bogus) =>
				Range.empty));

	bool isTemplate() scope =>
		!isEmpty(typeParams);
}
bool isPointer(in StructDecl a) =>
	a.body_.isA!BuiltinType && isPointer(a.body_.as!BuiltinType);

immutable struct StructDeclSource {
	immutable struct Bogus {
		Symbol name;
		TypeParams typeParams;
	}
	mixin TaggedUnion!(StructDeclAst*, Bogus*);
}

// The StructInst and its contents are allocated using the AllInsts alloc.
immutable struct StructInst {
	@safe @nogc pure nothrow:

	StructDecl* decl;
	TypeArgs typeArgs;
	// these are inferred from declAndArgs:
	LinkageRange linkageRange;
	PurityRange purityRange;
	// For a Record, this is the field types.
	// For a Union, this is the member types (Bogus for members with no type).
	// Otherwise this is empty.
	private Late!(SmallArray!Type) lateInstantiatedTypes;

	SmallArray!Type instantiatedTypes() return scope =>
		lateGet(lateInstantiatedTypes);

	void instantiatedTypes(SmallArray!Type value) {
		lateSet(lateInstantiatedTypes, value);
	}
}

bool isDefinitelyByRef(in StructInst a) {
	StructBody body_ = a.decl.body_;
	return body_.isA!(StructBody.Record) &&
		optEqual!ByValOrRef(body_.as!(StructBody.Record).flags.forcedByValOrRef, some(ByValOrRef.byRef));
}

bool isTuple(in CommonTypes commonTypes, in Type a) =>
	a.isA!(StructInst*) && isTuple(commonTypes, a.as!(StructInst*).decl);
bool isTuple(in CommonTypes commonTypes, in StructDecl* a) {
	Opt!(StructDecl*) actual = commonTypes.tuple(a.typeParams.length);
	return has(actual) && force(actual) == a;
}
Opt!(Type[]) asTuple(in CommonTypes commonTypes, Type type) =>
	isTuple(commonTypes, type) ? some!(Type[])(type.as!(StructInst*).typeArgs) : none!(Type[]);

immutable struct SpecDeclBody {
	Opt!BuiltinSpec builtin;
	Specs parents;
	SmallArray!SpecDeclSig sigs;
}

enum BuiltinSpec { data, enum_, flags, shared_ }

immutable struct SpecDecl {
	@safe @nogc pure nothrow:

	Uri moduleUri;
	SpecDeclAst* ast;
	Visibility visibility;
	private Late!SpecDeclBody lateBody;

	SmallString docComment() return scope =>
		ast.docComment;
	Symbol name() scope =>
		ast.name.name;
	TypeParams typeParams() return scope =>
		ast.typeParams;

	bool bodyIsSet() scope =>
		lateIsSet(lateBody);
	private ref SpecDeclBody body_() return scope =>
		lateGet(lateBody);
	void body_(SpecDeclBody value) scope {
		lateSet(lateBody, value);
	}

	ref Opt!BuiltinSpec builtin() return scope =>
		body_.builtin;

	Specs parents() return scope =>
		body_.parents;

	void overwriteParentsToEmpty() scope =>
		lateSetOverwrite(lateBody, SpecDeclBody(builtin, emptySpecs, sigs));

	SmallArray!SpecDeclSig sigs() return scope =>
		body_.sigs;

	UriAndRange range() scope =>
		UriAndRange(moduleUri, ast.range);
	UriAndRange nameRange() scope =>
		UriAndRange(moduleUri, ast.nameRange);
}

// The SpecInst and contents are allocated using the AllInsts alloc.
immutable struct SpecInst {
	@safe @nogc pure nothrow:

	SpecDecl* decl;
	TypeArgs typeArgs;
	private Late!SpecInstBody lateBody;

	immutable(SpecInst*[]) parents() return scope =>
		lateGet(lateBody).parents;
	immutable(ReturnAndParamTypes[]) sigTypes() return scope =>
		lateGet(lateBody).sigTypes;
	void body_(SpecInstBody value) {
		lateSet(lateBody, value);
	}

	Symbol name() scope =>
		decl.name;
}
size_t countSigs(in SpecInst a) =>
	sum(a.parents, (in SpecInst* x) => countSigs(*x)) + a.sigTypes.length;

immutable struct SpecInstBody {
	Specs parents;
	// Corresponds to the signatures in decl.body_
	SmallArray!ReturnAndParamTypes sigTypes;
}

alias EnumFunction = immutable EnumFunction_;
private enum EnumFunction_ {
	equal,
	intersect,
	members,
	toIntegral,
	union_,
}

// These are just the functions needing an 'all' value, otherwise they are in EnumFunction
alias FlagsFunction = immutable FlagsFunction_;
private enum FlagsFunction_ {
	all,
	negate,
	new_,
}

enum VarKind { global, threadLocal }

string stringOfVarKindUpperCase(VarKind a) {
	final switch (a) {
		case VarKind.global:
			return "Global";
		case VarKind.threadLocal:
			return "Thread-local";
	}
}

string stringOfVarKindLowerCase(VarKind a) {
	final switch (a) {
		case VarKind.global:
			return "global";
		case VarKind.threadLocal:
			return "thread-local";
	}
}

immutable struct AutoFun {
	enum Kind { compare, equals, toJson }
	Kind kind;
	Called[] members; // e.g., '<=>' implementations for each record/union member
}

immutable struct FunBody {
	immutable struct Bogus {}
	immutable struct CreateEnumOrFlags {
		EnumOrFlagsMember* member;
	}
	immutable struct CreateExtern {}
	immutable struct CreateRecord {}
	immutable struct CreateUnion {
		UnionMember* member;
	}
	immutable struct CreateVariant {
		VariantMember* member;
	}
	immutable struct Extern {
		Symbol libraryName;
	}
	immutable struct FileImport {
		ImportFileContent content;
	}
	immutable struct RecordFieldCall {
		size_t fieldIndex;
		FunKind funKind;
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
	immutable struct UnionMemberGet { size_t memberIndex; }
	immutable struct VarGet { VarDecl* var; }
	immutable struct VariantMemberGet { VariantMember* member; }
	immutable struct VarSet { VarDecl* var; }

	mixin Union!(
		Bogus,
		AutoFun,
		BuiltinFun,
		CreateEnumOrFlags,
		CreateExtern,
		CreateRecord,
		CreateUnion,
		CreateVariant,
		EnumFunction,
		Expr,
		Extern,
		FileImport,
		FlagsFunction,
		RecordFieldCall,
		RecordFieldGet,
		RecordFieldPointer,
		RecordFieldSet,
		UnionMemberGet,
		VarGet,
		VariantMemberGet,
		VarSet);
}
static assert(FunBody.sizeof == ulong.sizeof + Expr.sizeof);

immutable struct BuiltinFun {
	immutable struct AllTests {}
	immutable struct CallLambda {}
	immutable struct CallFunPointer {}
	immutable struct InitConstants {}
	immutable struct MarkRoot {}
	immutable struct MarkVisit {}
	immutable struct PointerCast {}
	immutable struct SizeOf {}
	immutable struct StaticSymbols {}

	mixin Union!(
		AllTests,
		BuiltinUnary,
		BuiltinUnaryMath,
		BuiltinBinary,
		BuiltinBinaryLazy,
		BuiltinBinaryMath,
		BuiltinTernary,
		CallLambda,
		CallFunPointer,
		Constant,
		InitConstants,
		MarkRoot,
		MarkVisit,
		PointerCast,
		SizeOf,
		StaticSymbols,
		VersionFun);
}

alias BuiltinUnary = immutable BuiltinUnary_;
private enum BuiltinUnary_ {
	asAnyPtr,
	bitwiseNotNat8,
	bitwiseNotNat16,
	bitwiseNotNat32,
	bitwiseNotNat64,
	countOnesNat64,
	deref,
	drop,
	enumToIntegral,
	referenceFromPointer,
	toChar8FromNat8,
	toFloat32FromFloat64,
	toFloat64FromFloat32,
	toFloat64FromInt64,
	toFloat64FromNat64,
	toInt64FromInt8,
	toInt64FromInt16,
	toInt64FromInt32,
	toNat8FromChar8,
	toNat32FromChar32,
	toNat64FromNat8,
	toNat64FromNat16,
	toNat64FromNat32,
	toNat64FromPtr,
	toPtrFromNat64,
	truncateToInt64FromFloat64,
	unsafeToChar32FromChar8,
	unsafeToChar32FromNat32,
	unsafeToNat32FromInt32,
	unsafeToInt8FromInt64,
	unsafeToInt16FromInt64,
	unsafeToInt32FromInt64,
	unsafeToNat64FromInt64,
	unsafeToInt64FromNat64,
	unsafeToNat8FromNat64,
	unsafeToNat16FromNat64,
	unsafeToNat32FromNat64,
}

alias BuiltinUnaryMath = immutable BuiltinUnaryMath_;
private enum BuiltinUnaryMath_ {
	acosFloat32,
	acosFloat64,
	acoshFloat32,
	acoshFloat64,
	asinFloat32,
	asinFloat64,
	asinhFloat32,
	asinhFloat64,
	atanFloat32,
	atanFloat64,
	atanhFloat32,
	atanhFloat64,
	cosFloat32,
	cosFloat64,
	coshFloat32,
	coshFloat64,
	roundFloat32,
	roundFloat64,
	sinFloat32,
	sinFloat64,
	sinhFloat32,
	sinhFloat64,
	sqrtFloat32,
	sqrtFloat64,
	tanFloat32,
	tanFloat64,
	tanhFloat32,
	tanhFloat64,
}

enum BuiltinBinary {
	addFloat32,
	addFloat64,
	addPointerAndNat64, // RHS is multiplied by size of pointee first
	bitwiseAndInt8,
	bitwiseAndInt16,
	bitwiseAndInt32,
	bitwiseAndInt64,
	bitwiseAndNat8,
	bitwiseAndNat16,
	bitwiseAndNat32,
	bitwiseAndNat64,
	bitwiseOrInt8,
	bitwiseOrInt16,
	bitwiseOrInt32,
	bitwiseOrInt64,
	bitwiseOrNat8,
	bitwiseOrNat16,
	bitwiseOrNat32,
	bitwiseOrNat64,
	bitwiseXorInt8,
	bitwiseXorInt16,
	bitwiseXorInt32,
	bitwiseXorInt64,
	bitwiseXorNat8,
	bitwiseXorNat16,
	bitwiseXorNat32,
	bitwiseXorNat64,
	eqChar8,
	eqChar32,
	eqFloat32,
	eqFloat64,
	eqInt8,
	eqInt16,
	eqInt32,
	eqInt64,
	eqNat8,
	eqNat16,
	eqNat32,
	eqNat64,
	eqPointer,
	lessChar8,
	lessFloat32,
	lessFloat64,
	lessInt8,
	lessInt16,
	lessInt32,
	lessInt64,
	lessNat8,
	lessNat16,
	lessNat32,
	lessNat64,
	lessPointer,
	mulFloat32,
	mulFloat64,
	seq,
	subFloat32,
	subFloat64,
	subPointerAndNat64, // RHS is multiplied by size of pointee first
	switchFiber,
	unsafeAddInt8,
	unsafeAddInt16,
	unsafeAddInt32,
	unsafeAddInt64,
	unsafeBitShiftLeftNat64,
	unsafeBitShiftRightNat64,
	unsafeDivFloat32,
	unsafeDivFloat64,
	unsafeDivInt8,
	unsafeDivInt16,
	unsafeDivInt32,
	unsafeDivInt64,
	unsafeDivNat8,
	unsafeDivNat16,
	unsafeDivNat32,
	unsafeDivNat64,
	unsafeModNat64,
	unsafeMulInt8,
	unsafeMulInt16,
	unsafeMulInt32,
	unsafeMulInt64,
	unsafeSubInt8,
	unsafeSubInt16,
	unsafeSubInt32,
	unsafeSubInt64,
	wrapAddNat8,
	wrapAddNat16,
	wrapAddNat32,
	wrapAddNat64,
	wrapMulNat8,
	wrapMulNat16,
	wrapMulNat32,
	wrapMulNat64,
	wrapSubNat8,
	wrapSubNat16,
	wrapSubNat32,
	wrapSubNat64,
	writeToPointer,
}

// These all have a lazy second argument
enum BuiltinBinaryLazy {
	boolAnd,
	boolOr,
	optionOr,
	optionQuestion2,
}

enum BuiltinBinaryMath {
	atan2Float32,
	atan2Float64,
}

enum BuiltinTernary { initStack, interpreterBacktrace }

immutable struct FunFlags {
	@safe @nogc pure nothrow:

	bool bare;
	bool summon;
	enum Safety : ubyte { safe, trusted, unsafe }
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
		TypeParams typeParams;
	}
	immutable struct Ast {
		Uri moduleUri;
		FunDeclAst* ast;
	}
	immutable struct FileImport {
		Uri moduleUri; // This is the importing module, not imported
		ImportOrExportAst* ast;
	}

	mixin Union!(
		Bogus,
		Ast,
		EnumOrFlagsMember*,
		FileImport,
		RecordField*,
		StructDecl*,
		UnionMember*,
		VarDecl*,
		VariantMember*);

	Uri moduleUri() scope =>
		matchIn!Uri(
			(in FunDeclSource.Bogus x) =>
				x.uri,
			(in FunDeclSource.Ast x) =>
				x.moduleUri,
			(in EnumOrFlagsMember x) =>
				x.moduleUri,
			(in FunDeclSource.FileImport x) =>
				x.moduleUri,
			(in RecordField x) =>
				x.moduleUri,
			(in StructDecl x) =>
				x.moduleUri,
			(in UnionMember x) =>
				x.moduleUri,
			(in VarDecl x) =>
				x.moduleUri,
			(in VariantMember x) =>
				x.moduleUri);

	UriAndRange range() scope =>
		matchIn!UriAndRange(
			(in FunDeclSource.Bogus x) =>
				UriAndRange(x.uri, Range.empty),
			(in FunDeclSource.Ast x) =>
				UriAndRange(x.moduleUri, x.ast.range),
			(in EnumOrFlagsMember x) =>
				UriAndRange(x.moduleUri, x.range),
			(in FunDeclSource.FileImport x) =>
				UriAndRange(x.moduleUri, x.ast.range),
			(in RecordField x) =>
				UriAndRange(x.moduleUri, x.range),
			(in StructDecl x) =>
				x.range,
			(in UnionMember x) =>
				UriAndRange(x.moduleUri, x.range),
			(in VarDecl x) =>
				x.range,
			(in VariantMember x) =>
			 	x.range);
	UriAndRange nameRange() scope =>
		matchIn!UriAndRange(
			(in FunDeclSource.Bogus x) =>
				UriAndRange(x.uri, Range.empty),
			(in FunDeclSource.Ast x) =>
				UriAndRange(x.moduleUri, x.ast.nameRange),
			(in EnumOrFlagsMember x) =>
				x.nameRange,
			(in FunDeclSource.FileImport x) =>
				UriAndRange(x.moduleUri, x.ast.range),
			(in RecordField x) =>
				x.nameRange,
			(in StructDecl x) =>
				x.nameRange,
			(in UnionMember x) =>
				x.nameRange,
			(in VarDecl x) =>
				x.nameRange,
			(in VariantMember x) =>
				x.nameRange);
}

immutable struct FunDecl {
	@safe @nogc pure nothrow:

	FunDeclSource source;
	Visibility visibility;
	Symbol name;
	Type returnType;
	Params params;
	FunFlags flags;
	Specs specs;
	private Late!FunBody lateBody;

	ref FunBody body_() return scope =>
		lateGet(lateBody);

	void body_(FunBody b) {
		lateSet(lateBody, b);
	}

	TypeParams typeParams() return scope =>
		source.match!TypeParams(
			(FunDeclSource.Bogus x) =>
				x.typeParams,
			(FunDeclSource.Ast x) =>
				x.ast.typeParams,
			(ref EnumOrFlagsMember x) =>
				x.containingEnum.typeParams,
			(FunDeclSource.FileImport _) =>
				emptySmallArray!NameAndRange,
			(ref RecordField x) =>
				x.containingRecord.typeParams,
			(ref StructDecl x) =>
				x.typeParams,
			(ref UnionMember x) =>
				x.containingUnion.typeParams,
			(ref VarDecl x) =>
				x.typeParams,
			(ref VariantMember x) =>
				x.typeParams);

	Uri moduleUri() scope =>
		source.moduleUri;

	UriAndRange range() scope =>
		source.range;
	UriAndRange nameRange() scope =>
		source.nameRange;

	SmallString docComment() scope =>
		source.as!(FunDeclSource.Ast).ast.docComment;

	Linkage linkage() scope =>
		body_.isA!(FunBody.Extern) ? Linkage.extern_ : Linkage.internal;

	bool isBare() scope =>
		flags.bare;
	bool isGenerated() scope =>
		flags.specialBody == FunFlags.SpecialBody.generated;
	bool isSummon() scope =>
		flags.summon;
	bool isUnsafe() scope =>
		flags.safety == FunFlags.Safety.unsafe;
	bool okIfUnused() scope =>
		flags.okIfUnused;

	bool isVariadic() scope =>
		params.isA!(Params.Varargs*);

	bool isTemplate() scope =>
		!isEmpty(typeParams) || !isEmpty(specs);

	Arity arity() scope =>
		params.arity;
}

immutable struct Test {
	@safe @nogc pure nothrow:

	TestAst* ast;
	Uri moduleUri;
	FunFlags flags;
	Expr body_;

	UriAndRange range() =>
		UriAndRange(moduleUri, ast.range);
}

immutable struct FunDeclAndTypeArgs {
	FunDecl* decl;
	TypeArgs typeArgs;
}

// The FunInst and its contents are allocated using the AllInsts alloc.
immutable struct FunInst {
	@safe @nogc pure nothrow:

	FunDecl* decl;
	TypeArgs typeArgs;
	SpecImpls specImpls;
	ReturnAndParamTypes instantiatedSig;

	Symbol name() scope =>
		decl.name;

	Type returnType() scope =>
		instantiatedSig.returnType;

	Type[] paramTypes() return scope =>
		instantiatedSig.paramTypes;

	Arity arity() scope =>
		decl.arity;
}

immutable struct ReturnAndParamTypes {
	@safe @nogc pure nothrow:

	SmallArray!Type returnAndParamTypes;

	Type returnType() scope =>
		returnAndParamTypes[0];

	Type[] paramTypes() return scope =>
		returnAndParamTypes[1 .. $];
}

immutable struct CalledSpecSig {
	@safe @nogc pure nothrow:

	private PtrAndSmallNumber!SpecInst inner;

	private this(PtrAndSmallNumber!SpecInst i) {
		inner = i;
		assert(sigIndex < specInst.sigTypes.length);
	}
	this(SpecInst* s, ushort i) {
		this(PtrAndSmallNumber!SpecInst(s, i));
	}

	@system ulong asTaggable() =>
		inner.asTaggable;
	@system static CalledSpecSig fromTagged(ulong x) =>
		CalledSpecSig(PtrAndSmallNumber!SpecInst.fromTagged(x));

	SpecInst* specInst() return scope =>
		inner.ptr;
	size_t sigIndex() scope =>
		inner.number;

	ReturnAndParamTypes instantiatedSig() return scope =>
		specInst.sigTypes[sigIndex];
	Type returnType() scope =>
		instantiatedSig.returnType;
	Type[] paramTypes() return scope =>
		instantiatedSig.paramTypes;

	SpecDeclSig* nonInstantiatedSig() return scope =>
		&specInst.decl.sigs[sigIndex];

	Symbol name() scope =>
		nonInstantiatedSig.name;

	Arity arity() scope =>
		Arity(safeToUint(nonInstantiatedSig.params.length));
}

// Like 'Called', but we haven't fully instantiated yet. (This is used for Candidate when checking a call expr.)
immutable struct CalledDecl {
	@safe @nogc pure nothrow:

	mixin TaggedUnion!(FunDecl*, CalledSpecSig);

	Symbol name() scope =>
		matchIn!Symbol(
			(in FunDecl f) => f.name,
			(in CalledSpecSig s) => s.name);

	TypeParams typeParams() return scope =>
		match!TypeParams(
			(ref FunDecl f) => f.typeParams,
			(CalledSpecSig _) => emptyTypeParams);

	Type returnType() =>
		match!Type(
			(ref FunDecl f) => f.returnType,
			(CalledSpecSig s) => s.returnType);

	Arity arity() scope =>
		matchIn!Arity(
			(in FunDecl x) =>
				x.arity,
			(in CalledSpecSig x) =>
				x.arity);

}

size_t nTypeParams(in CalledDecl a) =>
	a.typeParams.length;

immutable struct Called {
	@safe @nogc pure nothrow:

	immutable struct Bogus {
		CalledDecl decl;
		Type returnType;
		Type[] paramTypes;
	}
	mixin TaggedUnion!(Bogus*, FunInst*, CalledSpecSig);

	Symbol name() scope =>
		matchIn!Symbol(
			(in Bogus x) =>
				x.decl.name,
			(in FunInst f) =>
				f.name,
			(in CalledSpecSig s) =>
				s.name);

	Type returnType() scope =>
		match!Type(
			(ref Bogus x) =>
				x.returnType,
			(ref FunInst f) =>
				f.returnType,
			(CalledSpecSig s) =>
				s.instantiatedSig.returnType);

	Type[] paramTypes() scope =>
		match!(Type[])(
			(ref Bogus x) =>
				x.paramTypes,
			(ref FunInst x) =>
				x.paramTypes,
			(CalledSpecSig s) =>
				s.instantiatedSig.paramTypes);

	Arity arity() scope =>
		matchIn!Arity(
			(in Bogus x) =>
				x.decl.arity,
			(in FunInst x) =>
				x.arity,
			(in CalledSpecSig x) =>
				x.arity);

	bool isVariadic() scope =>
		arity.isA!(Arity.Varargs);
}

Type paramTypeAt(in Called a, size_t argIndex) scope =>
	a.matchIn!Type(
		(in Called.Bogus x) =>
			a.isVariadic ? only(x.paramTypes) : x.paramTypes[argIndex],
		(in FunInst x) =>
			a.isVariadic ? only(x.paramTypes) : x.paramTypes[argIndex],
		(in CalledSpecSig x) {
			assert(!a.isVariadic);
			return x.paramTypes[argIndex];
		});

immutable struct StructOrAlias {
	@safe @nogc pure nothrow:

	mixin TaggedUnion!(StructAlias*, StructDecl*);

	UriAndRange range() scope =>
		matchIn!UriAndRange(
			(in StructAlias x) => x.range,
			(in StructDecl x) => x.range);
	UriAndRange nameRange() scope =>
		matchIn!UriAndRange(
			(in StructAlias x) =>
				x.nameRange,
			(in StructDecl x) =>
				x.nameRange);

	Visibility visibility() scope =>
		matchIn!Visibility(
			(in StructAlias x) => x.visibility,
			(in StructDecl x) => x.visibility);

	Symbol name() scope =>
		matchIn!Symbol(
			(in StructAlias x) => x.name,
			(in StructDecl x) => x.name);

	TypeParams typeParams() =>
		match!TypeParams(
			(ref StructAlias x) => x.typeParams,
			(ref StructDecl x) => x.typeParams);
}

// No VarInst since these can't be templates
immutable struct VarDecl {
	@safe @nogc pure nothrow:

	VarDeclAst* ast;
	Uri moduleUri;
	Visibility visibility;
	Type type;
	Opt!Symbol externLibraryName;

	SmallString docComment() return scope =>
		ast.docComment;
	Symbol name() scope =>
		ast.name.name;
	TypeParams typeParams() return scope =>
		emptyTypeParams;
	VarKind kind() scope =>
		ast.kind;

	UriAndRange range() scope =>
		UriAndRange(moduleUri, ast.range);
	UriAndRange nameRange() scope =>
		UriAndRange(moduleUri, ast.nameRange);
}

immutable struct Module {
	@safe @nogc pure nothrow:

	Uri uri;
	FileAst* ast;
	SmallArray!Diagnostic diagnostics; // See also 'ast.diagnostics'
	SmallArray!ImportOrExport imports; // includes import of std (if applicable)
	SmallArray!ImportOrExport reExports;
	SmallArray!StructAlias aliases;
	SmallArray!StructDecl structs;
	SmallArray!VariantMember variantMembers;
	SmallArray!VarDecl vars;
	SmallArray!SpecDecl specs;
	SmallArray!FunDecl funs;
	SmallArray!Test tests;
	// Includes both internal and public exports.
	HashTable!(NameReferents, Symbol, nameFromNameReferents) exports;

	UriAndRange range() scope =>
		UriAndRange.topOfFile(uri);
}
Uri getModuleUri(in Module* a) =>
	a.uri;

void eachImportOrReExport(in Module a, in void delegate(in ImportOrExport) @safe @nogc pure nothrow cb) {
	foreach (ref ImportOrExport x; a.imports)
		cb(x);
	foreach (ref ImportOrExport x; a.reExports)
		cb(x);
}

immutable struct ImportOrExport {
	@safe @nogc pure nothrow:

	// none for an automatic import of std
	Opt!(ImportOrExportAst*) source;
	Module* modulePtr;
	// If this is internal, imports internal and public exports; if this is public, import only public exports
	ExportVisibility importVisibility;
	ImportOrExportKind kind;

	ref Module module_() return scope =>
		*modulePtr;
}

// No File option since those become FunDecls
immutable struct ImportOrExportKind {
	immutable struct ModuleWhole {}
	mixin TaggedUnion!(ModuleWhole, SmallArray!(Opt!(NameReferents*)));
}

immutable struct ImportFileContent {
	immutable struct Bogus {}
	mixin Union!(immutable ubyte[], string, Bogus);
}

immutable struct NameReferents {
	@safe @nogc pure nothrow:

	Opt!StructOrAlias structOrAlias;
	Opt!(SpecDecl*) spec;
	SmallArray!(FunDecl*) funs;

	this(Opt!StructOrAlias sa, Opt!(SpecDecl*) sp, immutable FunDecl*[] fs) {
		structOrAlias = sa;
		spec = sp;
		funs = fs;
		assert(has(structOrAlias) || has(spec) || !isEmpty(funs));
	}

	Symbol name() scope =>
		has(structOrAlias)
			? force(structOrAlias).name
			: has(spec)
			? force(spec).name
			: funs[0].name;
}
Symbol nameFromNameReferents(in NameReferents a) =>
	a.name;

enum FunKind {
	data,
	shared_,
	mut,
	function_,
}

immutable struct CommonFuns {
	FunInst* curJmpBuf;
	FunInst* setCurJmpBuf;
	VarDecl* curThrown;
	FunInst* allocate;
	FunInst* and;
	FunInst* createError;
	EnumMap!(FunKind, FunDecl*) lambdaSubscript;
	FunDecl* sharedOfMutLambda;
	FunInst* mark;
	FunInst* newJsonFromPairs;
	FunDecl* newTList;
	FunInst* runFiber;
	FunInst* rtMain;
	FunInst* throwImpl;
	FunInst* char8ArrayTrustAsString;
	FunInst* equalNat64;
	FunInst* lessNat64;
	FunInst* rethrowCurrentException;
	FunInst* setjmp;

	FunInst* gcRoot;
	FunInst* setGcRoot;
	FunInst* popGcRoot;
}

immutable struct CommonTypes {
	@safe @nogc pure nothrow:

	StructInst* bool_;
	StructInst* char8;
	StructInst* char32;
	StructInst* cString;
	StructInst* exception;
	StructInst* fiber;
	StructInst* float32;
	StructInst* float64;
	IntegralTypes integrals;
	StructInst* string_;
	StructInst* symbol;
	StructInst* symbolArray;
	StructInst* void_;

	StructDecl* array;
	StructInst* char8Array;
	StructInst* char32Array;
	StructDecl* list;
	StructInst* char8List;
	StructInst* char32List;
	StructDecl* option;
	StructDecl* pointerConst;
	StructDecl* pointerMut;
	StructDecl* reference;
	// No tuple0 and tuple1, so this is 2-9 inclusive
	StructDecl*[8] tuples2Through9;
	// Indexed by FunKind, then by arity. (arity = typeArgs.length - 1)
	EnumMap!(FunKind, StructDecl*) funStructs;

	StructDecl* funPointerStruct() =>
		funStructs[FunKind.function_];

	Opt!(StructDecl*) tuple(size_t arity) return scope =>
		2 <= arity && arity <= 9 ? some(tuples2Through9[arity - 2]) : none!(StructDecl*);

	size_t maxTupleSize() scope =>
		9;
}

Type arrayElementType(in CommonTypes commonTypes, Type type) {
	assert(type.as!(StructInst*).decl == commonTypes.array);
	return only(type.as!(StructInst*).typeArgs);
}

bool isLambdaType(in CommonTypes commonTypes, StructDecl* a) =>
	a.body_.isA!BuiltinType && a.body_.as!BuiltinType == BuiltinType.lambda;

bool isNonFunctionPointer(in CommonTypes commonTypes, StructDecl* a) =>
	a == commonTypes.pointerConst || a == commonTypes.pointerMut;

immutable struct IntegralTypes {
	@safe @nogc pure nothrow:
	EnumMap!(IntegralType, StructInst*) map;
	StructInst* opIndex(IntegralType name) return scope => map[name];
	StructInst* int8() return scope => this[IntegralType.int8];
	StructInst* int16() return scope => this[IntegralType.int16];
	StructInst* int32() return scope => this[IntegralType.int32];
	StructInst* int64() return scope => this[IntegralType.int64];
	StructInst* nat8() return scope => this[IntegralType.nat8];
	StructInst* nat16() return scope => this[IntegralType.nat16];
	StructInst* nat32() return scope => this[IntegralType.nat32];
	StructInst* nat64() return scope => this[IntegralType.nat64];
}

enum CharType { char8, char32 }
enum FloatType { float32, float64 }
enum IntegralType {
	int8,
	int16,
	int32,
	int64,
	nat8,
	nat16,
	nat32,
	nat64,
}
bool isSigned(IntegralType a) {
	final switch (a) {
		case IntegralType.int8:
		case IntegralType.int16:
		case IntegralType.int32:
		case IntegralType.int64:
			return true;
		case IntegralType.nat8:
		case IntegralType.nat16:
		case IntegralType.nat32:
		case IntegralType.nat64:
			return false;
	}
}

long minValue(IntegralType type) {
	final switch (type) {
		case IntegralType.int8:
			return byte.min;
		case IntegralType.int16:
			return short.min;
		case IntegralType.int32:
			return int.min;
		case IntegralType.int64:
			return long.min;
		case IntegralType.nat8:
		case IntegralType.nat16:
		case IntegralType.nat32:
		case IntegralType.nat64:
			return 0;
	}
}

ulong maxValue(IntegralType type) {
	final switch (type) {
		case IntegralType.int8:
			return byte.max;
		case IntegralType.int16:
			return short.max;
		case IntegralType.int32:
			return int.max;
		case IntegralType.int64:
			return long.max;
		case IntegralType.nat8:
			return ubyte.max;
		case IntegralType.nat16:
			return ushort.max;
		case IntegralType.nat32:
			return uint.max;
		case IntegralType.nat64:
			return ulong.max;
	}
}

immutable struct ProgramWithMain {
	Config* mainConfig;
	MainFun mainFun;
	Program program;
}

immutable struct MainFun {
	immutable struct Nat64OfArgs {
		FunInst* fun;
	}

	immutable struct Void {
		// Needed to wrap it to the Nat64OfArgs signature
		StructInst* stringList;
		FunInst* fun;
	}

	mixin Union!(Nat64OfArgs, Void);
}

bool hasAnyDiagnostics(in ProgramWithMain a) =>
	hasAnyDiagnostics(a.program);

bool hasFatalDiagnostics(in ProgramWithMain a) =>
	existsDiagnostic(a.program, (in UriAndDiagnostic x) =>
		isFatal(getDiagnosticSeverity(x.kind)));

immutable struct Program {
	HashTable!(immutable Config*, Uri, getConfigUri) allConfigs;
	HashTable!(immutable Module*, Uri, getModuleUri) allModules;
	Module*[] rootModules;
	SmallArray!UriAndDiagnostic commonFunsDiagnostics;
	CommonFuns commonFuns;
	CommonTypes* commonTypes;
}

bool hasAnyDiagnostics(in Program a) =>
	existsDiagnostic(a, (in UriAndDiagnostic _) => true);

// Iterates in no particular order
void eachDiagnostic(in Program a, in void delegate(in UriAndDiagnostic) @safe @nogc pure nothrow cb) {
	bool res = existsDiagnostic(a, (in UriAndDiagnostic x) {
		cb(x);
		return false;
	});
	assert(!res);
}

private bool existsDiagnostic(in Program a, in bool delegate(in UriAndDiagnostic) @safe @nogc pure nothrow cb) =>
	exists!UriAndDiagnostic(a.commonFunsDiagnostics, cb) ||
	existsInHashTable!(immutable Config*, Uri, getConfigUri)(a.allConfigs, (in Config* config) =>
		exists!Diagnostic(config.diagnostics, (in Diagnostic x) =>
			cb(UriAndDiagnostic(force(config.configUri), x)))) ||
	existsInHashTable!(immutable Module*, Uri, getModuleUri)(a.allModules, (in Module* module_) =>
		exists!ParseDiagnostic(module_.ast.parseDiagnostics, (in ParseDiagnostic x) =>
			cb(UriAndDiagnostic(UriAndRange(module_.uri, x.range), Diag(x.kind)))) ||
		exists!Diagnostic(module_.diagnostics, (in Diagnostic x) =>
			cb(UriAndDiagnostic(module_.uri, x))));

immutable struct Config {
	Opt!Uri configUri; // none for default config
	Diagnostic[] diagnostics;
	ConfigImportUris include;
	ConfigExternUris extern_;
}
Uri getConfigUri(in Config* a) =>
	force(a.configUri);
Config emptyConfig = Config(none!Uri, [], ConfigImportUris(), ConfigExternUris());
Config configForDiag(ref Alloc alloc, Uri uri, Diag diag) =>
	Config(some(uri), newArray(alloc, [Diagnostic(Range.empty, diag)]));

alias ConfigImportUris = Map!(Symbol, Uri);
alias ConfigExternUris = Map!(Symbol, Uri);

immutable struct LocalSource {
	immutable struct Generated { Symbol name; }
	mixin TaggedUnion!(DestructureAst.Single*, Generated*);
}

immutable struct Local {
	@safe @nogc pure nothrow:

	LocalSource source;
	LocalMutability mutability;
	Type type;

	Symbol name() scope =>
		source.matchIn!Symbol(
			(in DestructureAst.Single x) =>
				x.name.name,
			(in LocalSource.Generated x) =>
				x.name);

	bool isMutable() scope =>
		mutability.matchIn!bool(
			(in LocalMutability.Immutable) =>
				false,
			(in LocalMutability.MutableOnStack) =>
				true,
			(in LocalMutability.MutableAllocated) =>
				true);

	bool isAllocated() scope =>
		mutability.matchIn!bool(
			(in LocalMutability.Immutable) =>
				false,
			(in LocalMutability.MutableOnStack) =>
				false,
			(in LocalMutability.MutableAllocated) =>
				true);
}

Range localMustHaveNameRange(in Local a) =>
	a.source.as!(DestructureAst.Single*).nameRange;

private Range localMustHaveRange(in Local a) =>
	a.source.as!(DestructureAst.Single*).range;

immutable struct LocalMutability {
	@safe @nogc pure nothrow:
	immutable struct Immutable {}
	immutable struct MutableOnStack {}
	immutable struct MutableAllocated { StructInst* referenceType; }
	mixin Union!(Immutable, MutableOnStack, MutableAllocated);

	static LocalMutability immutable_() =>
		LocalMutability(LocalMutability.Immutable());
	static LocalMutability mutableOnStack() =>
		LocalMutability(LocalMutability.MutableOnStack());

	bool isImmutable() =>
		isA!Immutable;
}

enum Mutability { immut, mut }
Mutability toMutability(LocalMutability a) =>
	a.matchIn!Mutability(
		(in LocalMutability.Immutable) =>
			Mutability.immut,
		(in LocalMutability.MutableOnStack) =>
			Mutability.mut,
		(in LocalMutability.MutableAllocated) =>
			Mutability.mut);

immutable struct ClosureRef {
	@safe @nogc pure nothrow:

	PtrAndSmallNumber!LambdaExpr lambdaAndIndex;

	@system ulong asTaggable() =>
		lambdaAndIndex.asTaggable;
	@system static ClosureRef fromTagged(ulong x) =>
		ClosureRef(PtrAndSmallNumber!LambdaExpr.fromTagged(x));

	LambdaExpr* lambda() return scope =>
		lambdaAndIndex.ptr;

	ushort index() scope =>
		lambdaAndIndex.number;

	VariableRef variableRef() return scope =>
		lambda.closure[index];

	Local* local() return scope =>
		variableRef.local;

	ClosureReferenceKind closureReferenceKind() scope =>
		variableRef.closureReferenceKind;

	Symbol name() scope =>
		local.name;

	Type type() return scope =>
		local.type;
}

enum ClosureReferenceKind { direct, allocated }

immutable struct VariableRef {
	@safe @nogc pure nothrow:

	mixin TaggedUnion!(Local*, ClosureRef);

	Symbol name() scope =>
		local.name;
	LocalMutability mutability() scope =>
		local.mutability;
	Type type() return scope =>
		local.type;

	Local* local() return scope =>
		matchWithPointers!(Local*)(
			(Local* x) => x,
			(ClosureRef x) => x.local);
	ClosureReferenceKind closureReferenceKind() scope =>
		local.mutability.matchIn!ClosureReferenceKind(
			(in LocalMutability.Immutable) =>
				ClosureReferenceKind.direct,
			(in LocalMutability.MutableOnStack) =>
				assert(false),
			(in LocalMutability.MutableAllocated) =>
				ClosureReferenceKind.allocated);
}

immutable struct Destructure {
	@safe @nogc pure nothrow:

	// This can come from '_' or '()' (which is the same as '_ void')
	immutable struct Ignore {
		Pos pos;
		Type type;
	}
	immutable struct Split {
		Type destructuredType; // This will be a tuple instance or Bogus.
		SmallArray!Destructure parts;
	}
	mixin TaggedUnion!(Ignore*, Local*, Split*);

	Opt!Symbol name() scope =>
		matchIn!(Opt!Symbol)(
			(in Destructure.Ignore _) =>
				none!Symbol,
			(in Local x) =>
				some(x.name),
			(in Destructure.Split _) =>
				none!Symbol);

	Range range() scope =>
		matchIn!Range(
			(in Ignore x) =>
				Range(x.pos, x.pos + 1),
			(in Local x) =>
				localMustHaveRange(x),
			(in Split x) =>
				combineRanges(x.parts[0].range, x.parts[$ - 1].range));

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
	@safe @nogc pure nothrow:
	ExprAst* ast;
	ExprKind kind;

	Range range() scope =>
		ast.range;
}

immutable struct ExprKind {
	mixin Union!(
		AssertOrForbidExpr*,
		BogusExpr,
		CallExpr,
		CallOptionExpr*,
		ClosureGetExpr,
		ClosureSetExpr,
		FinallyExpr*,
		FunPointerExpr,
		IfExpr*,
		LambdaExpr*,
		LetExpr*,
		LiteralExpr,
		LiteralStringLikeExpr,
		LocalGetExpr,
		LocalPointerExpr,
		LocalSetExpr,
		LoopExpr*,
		LoopBreakExpr*,
		LoopContinueExpr,
		LoopWhileOrUntilExpr*,
		MatchEnumExpr*,
		MatchIntegralExpr*,
		MatchStringLikeExpr*,
		MatchUnionExpr*,
		MatchVariantExpr*,
		RecordFieldPointerExpr*,
		SeqExpr*,
		ThrowExpr*,
		TrustedExpr*,
		TryExpr*,
		TryLetExpr*,
		TypedExpr*);
}
static assert(ExprKind.sizeof == CallExpr.sizeof + ulong.sizeof);

immutable struct ExprAndType {
	Expr expr;
	Type type;
}

immutable struct Condition {
	immutable struct UnpackOption {
		Destructure destructure;
		ExprAndType option;
	}
	mixin TaggedUnion!(Expr*, UnpackOption*);
}

immutable struct AssertOrForbidExpr {
	bool isForbid;
	Condition condition;
	Opt!(Expr*) thrown;
	Expr after;
}

immutable struct BogusExpr {}

immutable struct CallExpr {
	Called called;
	SmallArray!Expr args;
}

// Expression for 'x?.y' or 'x?[y]'
immutable struct CallOptionExpr {
	// May or may not return an option. If not it will be wrapped after calling.
	Called called;
	// Type is an option type. The option is unwrapped before calling.
	ExprAndType firstArg;
	// These are non-optional.
	SmallArray!Expr restArgs;
}

immutable struct ClosureGetExpr {
	@safe @nogc pure nothrow:
	ClosureRef closureRef;

	Local* local() return scope =>
		closureRef.local;
}

immutable struct ClosureSetExpr {
	@safe @nogc pure nothrow:
	ClosureRef closureRef;
	Expr* value;

	Local* local() return scope =>
		closureRef.local;
}

immutable struct FinallyExpr {
	Expr right;
	Expr below;
}

immutable struct FunPointerExpr {
	Called called;
}

// Expression for an IfAst -- see that for all kinds of syntax this corresponds to
immutable struct IfExpr {
	@safe @nogc pure nothrow:
	Condition condition;
	Expr trueBranch;
	Expr falseBranch;

	ref Expr firstBranch(ExprAst* ast) return =>
		ast.kind.as!IfAst.isConditionNegated ? falseBranch : trueBranch;
	ref Expr secondBranch(ExprAst* ast) return =>
		ast.kind.as!IfAst.isConditionNegated ? trueBranch : falseBranch;
}

immutable struct LambdaExpr {
	@safe @nogc pure nothrow:

	enum Kind {
		data,
		shared_,
		mut,
		explicitShared,
	}

	Kind kind;
	Destructure param;
	Opt!(StructInst*) mutTypeForExplicitShared;
	private Late!Expr lateBody;
	private Late!(SmallArray!VariableRef) closure_;
	private Late!Type returnType_;

	void fillLate(Expr body_, SmallArray!VariableRef closure, Type returnType) {
		lateSet(lateBody, body_);
		lateSet(closure_, closure);
		lateSet(returnType_, returnType);
	}

	ref Expr body_() return scope =>
		lateGet(lateBody);
	SmallArray!VariableRef closure() return scope =>
		lateGet(closure_);
	Type returnType() return scope =>
		lateGet(returnType_);
}

immutable struct LetExpr {
	Destructure destructure;
	Expr value;
	Expr then;
}

immutable struct LiteralExpr {
	Constant value;
}

immutable struct LiteralStringLikeExpr {
	enum Kind { char8Array, char8List, char32Array, char32List, cString, string_, symbol }
	Kind kind;
	SmallString value; // For char32Array, this will be decoded in concretize.
}

immutable struct LocalGetExpr {
	Local* local;
}

immutable struct LocalPointerExpr {
	Local* local;
}

immutable struct LocalSetExpr {
	Local* local;
	Expr* value;
}

immutable struct LoopExpr {
	Expr body_;
}

immutable struct LoopBreakExpr {
	LoopExpr* loop;
	Expr value;
}

immutable struct LoopContinueExpr {
	LoopExpr* loop;
}

immutable struct LoopWhileOrUntilExpr {
	bool isUntil;
	Condition condition;
	Expr body_; // Always of type 'void'
	Expr after;
}

immutable struct MatchEnumExpr {
	@safe @nogc pure nothrow:

	ExprAndType matched;
	immutable struct Case {
		immutable EnumOrFlagsMember* member;
		Expr then;
	}
	SmallArray!Case cases;
	Opt!Expr else_;

	StructDecl* enum_() {
		StructInst* inst = matched.type.as!(StructInst*);
		assert(isEmpty(inst.typeArgs));
		StructDecl* res = inst.decl;
		assert(every!Case(cases, (in Case x) => x.member.containingEnum == res));
		return res;
	}

	StructBody.Enum* enumBody() =>
		enum_.body_.as!(StructBody.Enum*);
}

// Match on charX, intX, natX type
immutable struct MatchIntegralExpr {
	immutable struct Kind {
		@safe @nogc pure nothrow:
		mixin TaggedUnion!(CharType, IntegralType);
		bool isSigned() =>
			match!bool(
				(CharType _) => false,
				(IntegralType x) => .isSigned(x));
	}
	immutable struct Case {
		IntegralValue value;
		Expr then;
	}
	Kind kind;
	ExprAndType matched;
	SmallArray!Case cases;
	Expr else_;
}

// Match on symbol, string, char8 array, char8[], char32 array, char32[]
immutable struct MatchStringLikeExpr {
	immutable struct Case {
		string value;
		Expr then;
	}

	LiteralStringLikeExpr.Kind kind;
	ExprAndType matched;
	Called equals; // == function for the type
	SmallArray!Case cases;
	Expr else_;
}

immutable struct MatchUnionExpr {
	@safe @nogc pure nothrow:

	immutable struct Case {
		UnionMember* member;
		Destructure destructure;
		Expr then;
	}

	ExprAndType matched;
	SmallArray!Case cases;
	Opt!(Expr*) else_;

	StructInst* union_() =>
		matched.type.as!(StructInst*);
	UnionMember[] unionMembers() =>
		union_.decl.body_.as!(StructBody.Union*).members;
}

immutable struct MatchVariantExpr {
	@safe @nogc pure nothrow:

	immutable struct Case {
		VariantMember* member;
		Destructure destructure;
		Expr then;
	}

	ExprAndType matched;
	SmallArray!Case cases;
	Expr else_;

	StructInst* variant() return scope =>
		matched.type.as!(StructInst*);
}

immutable struct RecordFieldPointerExpr {
	@safe @nogc pure nothrow:

	ExprAndType target; // This will be a pointer or by-ref type
	size_t fieldIndex;

	StructDecl* recordDecl(in CommonTypes commonTypes) scope {
		StructInst* inst = target.type.as!(StructInst*);
		return isNonFunctionPointer(commonTypes, inst.decl)
			? only(inst.typeArgs).as!(StructInst*).decl
			: inst.decl;
	}

	RecordField* fieldDecl(in CommonTypes commonTypes) scope =>
		&recordDecl(commonTypes).body_.as!(StructBody.Record).fields[fieldIndex];
}

immutable struct SeqExpr {
	Expr first;
	Expr then;
}

immutable struct ThrowExpr {
	Expr thrown;
}

immutable struct TrustedExpr {
	Expr inner;
}

immutable struct TryExpr {
	Expr tried;
	SmallArray!(MatchVariantExpr.Case) catches;
}

immutable struct TryLetExpr {
	Destructure destructure;
	Expr value;
	MatchVariantExpr.Case catch_;
	Expr then;
}

immutable struct TypedExpr {
	Expr inner;
}

alias Visibility = immutable Visibility_;
private enum Visibility_ : ubyte {
	private_,
	internal,
	public_,
}
string stringOfVisibility(Visibility a) =>
	stringOfEnum(a);

enum ExportVisibility : ubyte {
	internal,
	public_
}

bool importCanSee(ExportVisibility importVisibility, Visibility exportVisibility) =>
	enumConvertOrAssert!ExportVisibility(exportVisibility) >= importVisibility;

Visibility leastVisibility(Visibility a, Visibility b) =>
	min(a, b);
Visibility greatestVisibility(Visibility a, Visibility b) =>
	max(a, b);
