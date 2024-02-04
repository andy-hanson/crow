module model.model;

@safe @nogc pure nothrow:

import frontend.getDiagnosticSeverity : getDiagnosticSeverity;
import model.ast :
	DestructureAst,
	EnumMemberAst,
	ExprAst,
	FileAst,
	FunDeclAst,
	ImportOrExportAst,
	NameAndRange,
	RecordFieldAst,
	SpecDeclAst,
	SpecSigAst,
	StructAliasAst,
	StructDeclAst,
	TestAst,
	TypedAst,
	UnionMemberAst,
	VarDeclAst;
import model.concreteModel : TypeSize;
import model.constant : Constant;
import model.diag : Diag, Diagnostic, isFatal, UriAndDiagnostic;
import model.parseDiag : ParseDiagnostic;
import util.col.array :
	arrayOfSingle, emptySmallArray, exists, first, isEmpty, only, PtrAndSmallNumber, small, SmallArray;
import util.col.hashTable : existsInHashTable, HashTable;
import util.col.map : Map;
import util.col.enumMap : EnumMap;
import util.conv : safeToUint;
import util.late : Late, lateGet, lateIsSet, lateSet, lateSetOverwrite;
import util.opt : force, has, none, Opt, optEqual, some;
import util.sourceRange : combineRanges, UriAndRange, Pos, rangeOfStartAndLength, Range;
import util.string : emptySmallString, SmallString;
import util.symbol : AllSymbols, Symbol, symbol;
import util.union_ : IndexType, TaggedUnion, Union;
import util.uri : Uri;
import util.util : enumConvertOrAssert, max, min, stringOfEnum;

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

// Represent type parameter as the index, so we don't generate different types for every `t list`.
// (These are disambiguated in the type checker using `TypeAndContext`)
immutable struct TypeParamIndex {
	mixin IndexType;
}

immutable struct Type {
	@safe @nogc pure nothrow:
	immutable struct Bogus {}

	mixin TaggedUnion!(Bogus, TypeParamIndex, StructInst*);

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
	immutable struct Varargs {}
	mixin TaggedUnion!(immutable uint, Varargs);
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
	Symbol name;
	Type returnType;
	SmallArray!Destructure params;

	UriAndRange range() scope =>
		UriAndRange(moduleUri, ast.range);
}

UriAndRange nameRange(in AllSymbols allSymbols, in SpecDeclSig a) =>
	UriAndRange(a.moduleUri, a.ast.nameAndRange.range(allSymbols));

immutable struct TypeParamsAndSig {
	TypeParams typeParams;
	Type returnType;
	ParamShort[] params;
}
immutable struct ParamShort {
	Symbol name;
	Type type;
}

immutable struct RecordField {
	@safe @nogc pure nothrow:

	RecordFieldAst* ast;
	StructDecl* containingRecord;
	Visibility visibility;
	Symbol name;
	Opt!Visibility mutability;
	Type type;

	Range range() scope =>
		ast.range;
	UriAndRange nameRange(in AllSymbols allSymbols) scope =>
		UriAndRange(containingRecord.moduleUri, ast.nameRange(allSymbols));
}

immutable struct UnionMember {
	@safe @nogc pure nothrow:

	UnionMemberAst* ast;
	StructDecl* containingUnion;
	Symbol name;
	Type type; // This will be Void if no type is specified

	Range range() scope =>
		ast.range;
	UriAndRange nameRange(in AllSymbols allSymbols) scope =>
		UriAndRange(containingUnion.moduleUri, ast.nameRange(allSymbols));
}

alias ByValOrRef = immutable ByValOrRef_;
private enum ByValOrRef_ {
	byVal,
	byRef,
}

immutable struct RecordFlags {
	Visibility newVisibility;
	bool packed;
	Opt!ByValOrRef forcedByValOrRef;
}

immutable struct EnumValue {
	@safe @nogc pure nothrow:

	// Large nat64 are represented as wrapped to negative values.
	long value;

	long asSigned() =>
		value;
	ulong asUnsigned() =>
		cast(ulong) value;
}

immutable struct EnumMember {
	@safe @nogc pure nothrow:

	EnumMemberAst* ast;
	StructDecl* containingEnum;
	Symbol name;
	EnumValue value;

	Range range() scope =>
		ast.range;
	UriAndRange nameRange(in AllSymbols allSymbols) scope =>
		UriAndRange(containingEnum.moduleUri, ast.nameRange(allSymbols));
}

immutable struct StructBody {
	immutable struct Bogus {}
	immutable struct Enum {
		EnumBackingType backingType;
		EnumMember[] members;
	}
	immutable struct Extern {
		Opt!TypeSize size;
	}
	immutable struct Flags {
		EnumBackingType backingType;
		// For Flags, members should be unsigned
		EnumMember[] members;
	}
	immutable struct Record {
		RecordFlags flags;
		RecordField[] fields;
	}
	immutable struct Union {
		UnionMember[] members;
	}

	mixin .Union!(Bogus, BuiltinType, Enum, Extern, Flags, Record, Union);
}
static assert(StructBody.sizeof == size_t.sizeof + StructBody.Record.sizeof);

alias BuiltinType = immutable BuiltinType_;
private enum BuiltinType_ {
	bool_,
	char8,
	float32,
	float64,
	funPointer,
	int8,
	int16,
	int32,
	int64,
	lambda, // 'data', 'shared', or 'mut' lambda type. Not 'function' or 'far'.
	nat8,
	nat16,
	nat32,
	nat64,
	pointerConst,
	pointerMut,
	void_,
}

UriAndRange nameRange(in AllSymbols allSymbols, in EnumMember a) =>
	UriAndRange(a.containingEnum.moduleUri, a.ast.nameRange(allSymbols));

immutable struct StructAlias {
	@safe @nogc pure nothrow:

	StructAliasAst* ast;
	Uri moduleUri;
	Visibility visibility;
	Symbol name;
	private Late!(StructInst*) target_;

	SmallString docComment() return scope =>
		ast.docComment;

	TypeParams typeParams() return scope =>
		emptyTypeParams;

	UriAndRange range() scope =>
		UriAndRange(moduleUri, ast.range);
	UriAndRange nameRange(in AllSymbols allSymbols) scope =>
		UriAndRange(moduleUri, ast.nameRange(allSymbols));

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
	Symbol name;
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

	UriAndRange range() scope =>
		UriAndRange(moduleUri, source.matchIn!Range(
			(in StructDeclAst x) =>
				x.range,
			(in StructDeclSource.Bogus) =>
				Range.empty));

	UriAndRange nameRange(in AllSymbols allSymbols) scope =>
		UriAndRange(moduleUri, source.matchIn!Range(
			(in StructDeclAst x) =>
				x.nameRange(allSymbols),
			(in StructDeclSource.Bogus) =>
				Range.empty));

	bool isTemplate() scope =>
		!isEmpty(typeParams);
}

immutable struct StructDeclSource {
	immutable struct Bogus {
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

	Type[] instantiatedTypes() return scope =>
		lateGet(lateInstantiatedTypes);

	void instantiatedTypes(Type[] value) {
		lateSet(lateInstantiatedTypes, small!Type(value));
	}
}

bool isDefinitelyByRef(in StructInst a) {
	StructBody body_ = a.decl.body_;
	return body_.isA!(StructBody.Record) &&
		optEqual!ByValOrRef(body_.as!(StructBody.Record).flags.forcedByValOrRef, some(ByValOrRef.byRef));
}

bool isArray(in CommonTypes commonTypes, in StructInst a) =>
	a.decl == commonTypes.array;

bool isTuple(in CommonTypes commonTypes, in Type a) =>
	a.isA!(StructInst*) && isTuple(commonTypes, *a.as!(StructInst*));
bool isTuple(in CommonTypes commonTypes, in StructInst a) =>
	isTuple(commonTypes, a.decl);
bool isTuple(in CommonTypes commonTypes, in StructDecl* a) {
	Opt!(StructDecl*) actual = commonTypes.tuple(a.typeParams.length);
	return has(actual) && force(actual) == a;
}
Opt!(Type[]) asTuple(in CommonTypes commonTypes, Type type) =>
	isTuple(commonTypes, type) ? some!(Type[])(type.as!(StructInst*).typeArgs) : none!(Type[]);

immutable struct SpecDeclBody {
	Opt!BuiltinSpec builtin;
	SmallArray!(immutable SpecInst*) parents;
	SmallArray!SpecDeclSig sigs;
}

enum BuiltinSpec { data, shared_ }

immutable struct SpecDecl {
	@safe @nogc pure nothrow:

	Uri moduleUri;
	SpecDeclAst* ast;
	Visibility visibility;
	Symbol name;
	private Late!SpecDeclBody lateBody;

	SmallString docComment() return scope =>
		ast.docComment;
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

	SmallArray!(immutable SpecInst*) parents() return scope =>
		body_.parents;

	void overwriteParentsToEmpty() scope =>
		lateSetOverwrite(lateBody, SpecDeclBody(builtin, emptySmallArray!(immutable SpecInst*), sigs));

	SmallArray!SpecDeclSig sigs() return scope =>
		body_.sigs;

	UriAndRange range() scope =>
		UriAndRange(moduleUri, ast.range);
	UriAndRange nameRange(in AllSymbols allSymbols) scope =>
		UriAndRange(moduleUri, ast.nameRange(allSymbols));
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

immutable struct SpecInstBody {
	SmallArray!(immutable SpecInst*) parents;
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

Symbol enumFunctionName(EnumFunction a) {
	final switch (a) {
		case EnumFunction.equal:
			return symbol!"==";
		case EnumFunction.intersect:
			return symbol!"&";
		case EnumFunction.members:
			return symbol!"members";
		case EnumFunction.toIntegral:
			return symbol!"to-integral";
		case EnumFunction.union_:
			return symbol!"|";
	}
}

alias FlagsFunction = immutable FlagsFunction_;
private enum FlagsFunction_ {
	all,
	negate,
	new_,
}

Symbol flagsFunctionName(FlagsFunction a) {
	final switch (a) {
		case FlagsFunction.all:
			return symbol!"all";
		case FlagsFunction.negate:
			return symbol!"~";
		case FlagsFunction.new_:
			return symbol!"new";
	}
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

immutable struct FunBody {
	immutable struct Bogus {}
	immutable struct CreateEnum {
		EnumMember* member;
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
		Symbol libraryName;
	}
	immutable struct FileImport {
		ImportFileType type;
		Uri uri;
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
	immutable struct VarGet { VarDecl* var; }
	immutable struct VarSet { VarDecl* var; }

	mixin Union!(
		Bogus,
		BuiltinFun,
		CreateEnum,
		CreateExtern,
		CreateRecord,
		CreateUnion,
		EnumFunction,
		Extern,
		ExpressionBody,
		FileImport,
		FlagsFunction,
		RecordFieldCall,
		RecordFieldGet,
		RecordFieldPointer,
		RecordFieldSet,
		VarGet,
		VarSet);
}

immutable struct BuiltinFun {
	immutable struct AllTests {}
	immutable struct CallLambda {}
	immutable struct CallFunPointer {}
	immutable struct InitConstants {}
	immutable struct MarkVisit {}
	immutable struct OptOr {}
	immutable struct OptQuestion2 {}
	immutable struct PointerCast {}
	immutable struct SizeOf {}
	immutable struct StaticSymbols {}

	mixin Union!(
		AllTests,
		BuiltinUnary,
		BuiltinUnaryMath,
		BuiltinBinary,
		BuiltinBinaryMath,
		BuiltinTernary,
		CallLambda,
		CallFunPointer,
		Constant,
		InitConstants,
		MarkVisit,
		OptOr,
		OptQuestion2,
		PointerCast,
		SizeOf,
		StaticSymbols,
		VersionFun);
}

alias VersionFun = immutable VersionFun_;
private enum VersionFun_ {
	isBigEndian,
	isInterpreted,
	isJit,
	isSingleThreaded,
	isWasm,
	isWindows,
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
	toChar8FromNat8,
	toFloat32FromFloat64,
	toFloat64FromFloat32,
	toFloat64FromInt64,
	toFloat64FromNat64,
	toInt64FromInt8,
	toInt64FromInt16,
	toInt64FromInt32,
	toNat8FromChar8,
	toNat64FromNat8,
	toNat64FromNat16,
	toNat64FromNat32,
	toNat64FromPtr,
	toPtrFromNat64,
	truncateToInt64FromFloat64,
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

alias BuiltinBinary = immutable BuiltinBinary_;
private enum BuiltinBinary_ {
	addFloat32,
	addFloat64,
	addPtrAndNat64, // RHS is multiplied by size of pointee first
	and,
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
	eqPtr,
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
	lessPtr,
	mulFloat32,
	mulFloat64,
	orBool,
	seq,
	subFloat32,
	subFloat64,
	subPtrAndNat64, // RHS is multiplied by size of pointee first
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
	writeToPtr,
}

alias BuiltinBinaryMath = immutable BuiltinBinaryMath_;
private enum BuiltinBinaryMath_ {
	atan2Float32,
	atan2Float64,
}

alias BuiltinTernary = immutable BuiltinTernary_;
private enum BuiltinTernary_ { interpreterBacktrace }

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

	mixin Union!(Bogus, Ast, EnumMember*, FileImport, RecordField*, StructDecl*, UnionMember*, VarDecl*);

	UriAndRange range() scope =>
		matchIn!UriAndRange(
			(in FunDeclSource.Bogus x) =>
				UriAndRange(x.uri, Range.empty),
			(in FunDeclSource.Ast x) =>
				UriAndRange(x.moduleUri, x.ast.range),
			(in EnumMember x) =>
				UriAndRange(x.containingEnum.moduleUri, x.range),
			(in FunDeclSource.FileImport x) =>
				UriAndRange(x.moduleUri, x.ast.range),
			(in RecordField x) =>
				UriAndRange(x.containingRecord.moduleUri, x.range),
			(in StructDecl x) =>
				x.range,
			(in UnionMember x) =>
				UriAndRange(x.containingUnion.moduleUri, x.range),
			(in VarDecl x) =>
				x.range);
	UriAndRange nameRange(in AllSymbols allSymbols) scope =>
		matchIn!UriAndRange(
			(in FunDeclSource.Bogus x) =>
				UriAndRange(x.uri, Range.empty),
			(in FunDeclSource.Ast x) =>
				UriAndRange(x.moduleUri, x.ast.nameRange(allSymbols)),
			(in EnumMember x) =>
				x.nameRange(allSymbols),
			(in FunDeclSource.FileImport x) =>
				UriAndRange(x.moduleUri, x.ast.range),
			(in RecordField x) =>
				x.nameRange(allSymbols),
			(in StructDecl x) =>
				x.nameRange(allSymbols),
			(in UnionMember x) =>
				x.nameRange(allSymbols),
			(in VarDecl x) =>
				x.nameRange(allSymbols));
}

immutable struct FunDecl {
	@safe @nogc pure nothrow:

	FunDeclSource source;
	Visibility visibility;
	Symbol name;
	Type returnType;
	Params params;
	FunFlags flags;
	SmallArray!(immutable SpecInst*) specs;
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
			(ref EnumMember _) =>
				emptySmallArray!NameAndRange,
			(FunDeclSource.FileImport _) =>
				emptySmallArray!NameAndRange,
			(ref RecordField x) =>
				x.containingRecord.typeParams,
			(ref StructDecl x) =>
				x.typeParams,
			(ref UnionMember x) =>
				x.containingUnion.typeParams,
			(ref VarDecl x) =>
				x.typeParams);

	Uri moduleUri() scope =>
		range.uri;

	UriAndRange range() scope =>
		source.range;
	UriAndRange nameRange(in AllSymbols allSymbols) scope =>
		source.nameRange(allSymbols);

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
	enum BodyType { bogus, void_, voidFuture }
	BodyType bodyType;

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
	}
	this(SpecInst* s, ushort i) {
		inner = PtrAndSmallNumber!SpecInst(s, i);
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

	mixin TaggedUnion!(FunInst*, CalledSpecSig);

	Symbol name() scope =>
		matchIn!Symbol(
			(in FunInst f) =>
				f.name,
			(in CalledSpecSig s) =>
				s.name);

	Type returnType() scope =>
		match!Type(
			(ref FunInst f) =>
				f.returnType,
			(CalledSpecSig s) =>
				s.instantiatedSig.returnType);

	Arity arity() scope =>
		matchIn!Arity(
			(in FunInst x) =>
				x.arity,
			(in CalledSpecSig x) =>
				x.arity);
}

Type paramTypeAt(in Called a, size_t argIndex) scope =>
	a.matchIn!Type(
		(in FunInst f) =>
			f.decl.params.matchIn!Type(
				(in Destructure[]) =>
					f.paramTypes[argIndex],
				(in Params.Varargs) =>
					only(f.paramTypes)),
		(in CalledSpecSig s) =>
			s.paramTypes[argIndex]);

immutable struct StructOrAlias {
	@safe @nogc pure nothrow:

	mixin TaggedUnion!(StructAlias*, StructDecl*);

	UriAndRange range() scope =>
		matchIn!UriAndRange(
			(in StructAlias x) => x.range,
			(in StructDecl x) => x.range);
	UriAndRange nameRange(in AllSymbols allSymbols) scope =>
		matchIn!UriAndRange(
			(in StructAlias x) =>
				x.nameRange(allSymbols),
			(in StructDecl x) =>
				x.nameRange(allSymbols));

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
	Symbol name;
	VarKind kind;
	Type type;
	Opt!Symbol externLibraryName;

	TypeParams typeParams() return scope =>
		emptyTypeParams;

	UriAndRange range() scope =>
		UriAndRange(moduleUri, ast.range);
	UriAndRange nameRange(in AllSymbols allSymbols) scope =>
		UriAndRange(moduleUri, ast.nameRange(allSymbols));
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

enum ImportFileType { nat8Array, string }

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
	far,
	function_,
}

immutable struct CommonFuns {
	UriAndDiagnostic[] diagnostics;
	FunInst* alloc;
	EnumMap!(FunKind, FunDecl*) lambdaSubscript;
	FunInst* curExclusion;
	FunInst* mark;
	FunInst* newNat64Future;
	FunInst* newVoidFuture;
	FunInst* rtMain;
	FunInst* throwImpl;
	FunInst* char8ArrayAsString;
}

immutable struct CommonTypes {
	@safe @nogc pure nothrow:

	StructInst* bool_;
	StructInst* char8;
	StructInst* cString;
	StructInst* float32;
	StructInst* float64;
	IntegralTypes integrals;
	StructInst* string_;
	StructInst* symbol;
	StructInst* symbolArray;
	StructInst* void_;
	StructDecl* array;
	StructDecl* future;
	StructInst* voidFuture;
	StructDecl* opt;
	StructDecl* ptrConst;
	StructDecl* ptrMut;
	// No tuple0 and tuple1, so this is 2-9 inclusive
	StructDecl*[8] tuples2Through9;
	// Indexed by FunKind, then by arity. (arity = typeArgs.length - 1)
	EnumMap!(FunKind, StructDecl*) funStructs;

	StructDecl* funPtrStruct() =>
		funStructs[FunKind.function_];

	Opt!(StructDecl*) tuple(size_t arity) return scope =>
		2 <= arity && arity <= 9 ? some(tuples2Through9[arity - 2]) : none!(StructDecl*);
}

private bool isNonFunctionPointer(in CommonTypes commonTypes, StructDecl* a) =>
	a == commonTypes.ptrConst || a == commonTypes.ptrMut;

immutable struct IntegralTypes {
	@safe @nogc pure nothrow:
	EnumMap!(EnumBackingType, StructInst*) byEnumBackingType;
	StructInst* int8() return scope => byEnumBackingType[EnumBackingType.int8];
	StructInst* int16() return scope => byEnumBackingType[EnumBackingType.int16];
	StructInst* int32() return scope => byEnumBackingType[EnumBackingType.int32];
	StructInst* int64() return scope => byEnumBackingType[EnumBackingType.int64];
	StructInst* nat8() return scope => byEnumBackingType[EnumBackingType.nat8];
	StructInst* nat16() return scope => byEnumBackingType[EnumBackingType.nat16];
	StructInst* nat32() return scope => byEnumBackingType[EnumBackingType.nat32];
	StructInst* nat64() return scope => byEnumBackingType[EnumBackingType.nat64];
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

immutable struct ProgramWithMain {
	Config* mainConfig;
	MainFun mainFun;
	Program program;
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

bool hasAnyDiagnostics(in ProgramWithMain a) =>
	hasAnyDiagnostics(a.program);

bool hasFatalDiagnostics(in ProgramWithMain a) =>
	existsDiagnostic(a.program, (in UriAndDiagnostic x) =>
		isFatal(getDiagnosticSeverity(x.kind)));

immutable struct Program {
	HashTable!(immutable Config*, Uri, getConfigUri) allConfigs;
	HashTable!(immutable Module*, Uri, getModuleUri) allModules;
	Module*[] rootModules;
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
	exists!UriAndDiagnostic(a.commonFuns.diagnostics, cb) ||
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

alias ConfigImportUris = Map!(Symbol, Uri);
alias ConfigExternUris = Map!(Symbol, Uri);

immutable struct LocalSource {
	immutable struct Generated {}
	mixin TaggedUnion!(DestructureAst.Single*, Generated);
}

immutable struct Local {
	@safe @nogc pure nothrow:

	LocalSource source;
	Symbol name;
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

Range localMustHaveNameRange(in Local a, in AllSymbols allSymbols) =>
	a.source.as!(DestructureAst.Single*).nameRange(allSymbols);

private Range localMustHaveRange(in Local a, in AllSymbols allSymbols) =>
	a.source.as!(DestructureAst.Single*).range(allSymbols);

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

	Symbol name() scope =>
		toLocal(this).name;

	Type type() return scope =>
		toLocal(this).type;
}

Local* toLocal(return in ClosureRef a) =>
	toLocal(a.variableRef);

enum ClosureReferenceKind { direct, allocated }

ClosureReferenceKind getClosureReferenceKind(ClosureRef a) =>
	getClosureReferenceKind(a.variableRef);
private ClosureReferenceKind getClosureReferenceKind(VariableRef a) {
	final switch (toLocal(a).mutability) {
		case LocalMutability.immut:
			return ClosureReferenceKind.direct;
		case LocalMutability.mutOnStack:
			assert(false);
		case LocalMutability.mutAllocated:
			return ClosureReferenceKind.allocated;
	}
}

immutable struct VariableRef {
	@safe @nogc pure nothrow:

	mixin TaggedUnion!(Local*, ClosureRef);

	Symbol name() scope =>
		toLocal(this).name;
	Type type() =>
		toLocal(this).type;
}

private Local* toLocal(VariableRef a) =>
	a.matchWithPointers!(Local*)(
		(Local* x) =>
			x,
		(ClosureRef x) =>
			toLocal(x.variableRef()));

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

	Range range(in AllSymbols allSymbols) scope =>
		matchIn!Range(
			(in Ignore x) =>
				Range(x.pos, x.pos + 1),
			(in Local x) =>
				localMustHaveRange(x, allSymbols),
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
	@safe @nogc pure nothrow:

	ExprAst* ast;
	ExprKind kind;

	Range range() scope =>
		ast.range;
}

immutable struct ExprKind {
	mixin Union!(
		AssertOrForbidExpr,
		BogusExpr,
		CallExpr,
		ClosureGetExpr,
		ClosureSetExpr,
		FunPointerExpr,
		IfExpr*,
		IfOptionExpr*,
		LambdaExpr*,
		LetExpr*,
		LiteralExpr*,
		LiteralStringLikeExpr,
		LocalGetExpr,
		LocalSetExpr*,
		LoopExpr*,
		LoopBreakExpr*,
		LoopContinueExpr,
		LoopUntilExpr*,
		LoopWhileExpr*,
		MatchEnumExpr*,
		MatchUnionExpr*,
		PtrToFieldExpr*,
		PtrToLocalExpr,
		SeqExpr*,
		ThrowExpr*,
		TrustedExpr*,
		TypedExpr*);
}

immutable struct ExprAndType {
	Expr expr;
	Type type;
}

immutable struct AssertOrForbidExpr {
	AssertOrForbidKind kind;
	Expr* condition;
	Opt!(Expr*) thrown;
}

enum AssertOrForbidKind { assert_, forbid }

immutable struct BogusExpr {}

immutable struct CallExpr {
	Called called;
	Expr[] args;
}

immutable struct ClosureGetExpr {
	ClosureRef closureRef;
}

immutable struct ClosureSetExpr {
	ClosureRef closureRef;
	Expr* value;
}

immutable struct FunPointerExpr {
	FunInst* funInst;
}

immutable struct IfExpr {
	Expr cond;
	Expr then;
	Expr else_;
}

immutable struct IfOptionExpr {
	Destructure destructure;
	ExprAndType option;
	Expr then;
	Expr else_;
}

immutable struct LambdaExpr {
	@safe @nogc pure nothrow:

	FunKind kind;
	Destructure param;
	private Late!Expr lateBody;
	private Late!(SmallArray!VariableRef) closure_;
	// For FunKind.far this includes 'future' wrapper
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
	enum Kind { cString, string_, symbol }
	Kind kind;
	string value;
}

immutable struct LocalGetExpr {
	Local* local;
}

immutable struct LocalSetExpr {
	Local* local;
	Expr value;
}

immutable struct LoopExpr {
	Range range;
	Expr body_;
}

Range loopKeywordRange(in LoopExpr a) =>
	rangeOfStartAndLength(a.range.start, "loop".length);

immutable struct LoopBreakExpr {
	LoopExpr* loop;
	Expr value;
}

immutable struct LoopContinueExpr {
	LoopExpr* loop;
}

immutable struct LoopUntilExpr {
	Expr condition;
	Expr body_;
}

immutable struct LoopWhileExpr {
	Expr condition;
	Expr body_;
}

immutable struct MatchEnumExpr {
	@safe @nogc pure nothrow:

	ExprAndType matched;
	Expr[] cases;

	EnumMember[] enumMembers() =>
		matched.type.as!(StructInst*).decl.body_.as!(StructBody.Enum).members;
}

immutable struct MatchUnionExpr {
	@safe @nogc pure nothrow:

	immutable struct Case {
		Destructure destructure;
		Expr then;
	}

	ExprAndType matched;
	Case[] cases;

	UnionMember[] unionMembers() =>
		matched.type.as!(StructInst*).decl.body_.as!(StructBody.Union).members;
}

immutable struct PtrToFieldExpr {
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

immutable struct PtrToLocalExpr {
	Local* local;
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

immutable struct TypedExpr {
	@safe @nogc pure nothrow:

	Expr inner;
	Type type;

	TypedAst* ast(ref Expr expr) scope {
		assert(expr.kind.as!(TypedExpr*) == &this);
		return expr.ast.kind.as!(TypedAst*);
	}
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
