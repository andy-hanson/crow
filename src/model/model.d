module model.model;

@safe @nogc pure nothrow:

import frontend.getDiagnosticSeverity : getDiagnosticSeverity;
import model.ast :
	DestructureAst,
	ExprAst,
	FileAst,
	FunDeclAst,
	ImportOrExportAst,
	NameAndRange,
	nameRange,
	nameRangeOfDestructureSingle,
	rangeOfDestructureSingle,
	rangeOfNameAndRange,
	SpecDeclAst,
	SpecSigAst,
	StructAliasAst,
	StructBodyAst,
	StructDeclAst,
	TestAst,
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
import util.conv : safeToSizeT;
import util.late : Late, lateGet, lateIsSet, lateSet, lateSetOverwrite;
import util.opt : force, has, none, Opt, some;
import util.sourceRange : combineRanges, UriAndRange, Pos, rangeOfStartAndLength, Range;
import util.string : emptySmallString, SmallString;
import util.symbol : AllSymbols, Symbol, symbol;
import util.union_ : Union;
import util.uri : Uri;
import util.util : max, min, stringOfEnum, typeAs;

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
	@safe @nogc pure nothrow:

	size_t index;

	ulong asTaggable() =>
		index << 2;
	static TypeParamIndex fromTagged(ulong x) =>
		TypeParamIndex(safeToSizeT(x >> 2));
}

immutable struct Type {
	@safe @nogc pure nothrow:
	immutable struct Bogus {}

	mixin Union!(Bogus, TypeParamIndex, StructInst*);

	bool opEquals(scope Type b) scope =>
		taggedPointerEquals(b);
}
static assert(Type.sizeof == ulong.sizeof);

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

	mixin Union!(SmallArray!Destructure, Varargs*);

	Arity arity() scope =>
		matchIn!Arity(
			(in Destructure[] params) =>
				Arity(params.length),
			(in Params.Varargs) =>
				Arity(Arity.Varargs()));
}
static assert(Params.sizeof == ulong.sizeof);

Destructure[] paramsArray(return scope Params a) =>
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
	UriAndRange(a.moduleUri, rangeOfNameAndRange(a.ast.nameAndRange, allSymbols));

immutable struct TypeParamsAndSig {
	TypeParams typeParams;
	Type returnType;
	ParamShort[] params;
}
immutable struct ParamShort {
	Symbol name;
	Type type;
}

enum FieldMutability {
	const_,
	private_,
	public_,
}

immutable struct RecordField {
	@safe @nogc pure nothrow:

	StructBodyAst.Record.Field* ast;
	StructDecl* containingRecord;
	Visibility visibility;
	Symbol name;
	FieldMutability mutability;
	Type type;

	Range range() scope =>
		ast.range;
}

UriAndRange nameRange(in AllSymbols allSymbols, in RecordField a) =>
	UriAndRange(a.containingRecord.moduleUri, rangeOfNameAndRange(a.ast.name, allSymbols));

immutable struct UnionMember {
	@safe @nogc pure nothrow:

	//TODO: use NameAndRange (more compact)
	StructBodyAst.Union.Member* ast;
	StructDecl* containingUnion;
	Symbol name;
	Type type;

	Range range() scope =>
		ast.range;
}

UriAndRange nameRange(in AllSymbols allSymbols, in UnionMember a) =>
	UriAndRange(a.containingUnion.moduleUri, rangeOfNameAndRange(a.ast.nameAndRange, allSymbols));

enum ForcedByValOrRefOrNone {
	none,
	byVal,
	byRef,
}

Symbol symbolOfForcedByValOrRefOrNone(ForcedByValOrRefOrNone a) {
	final switch (a) {
		case ForcedByValOrRefOrNone.none:
			return symbol!"none";
		case ForcedByValOrRefOrNone.byVal:
			return symbol!"by-val";
		case ForcedByValOrRefOrNone.byRef:
			return symbol!"by-ref";
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

	long asSigned() =>
		value;
	ulong asUnsigned() =>
		cast(ulong) value;
}

immutable struct EnumMember {
	@safe @nogc pure nothrow:

	StructBodyAst.Enum.Member* ast;
	StructDecl* containingEnum;
	Symbol name;
	EnumValue value;

	Range range() scope =>
		ast.range;
}

immutable struct StructBody {
	immutable struct Bogus {}
	immutable struct Builtin {}
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

	mixin .Union!(Bogus, Builtin, Enum, Extern, Flags, Record, Union);
}
static assert(StructBody.sizeof == size_t.sizeof + StructBody.Record.sizeof);

UriAndRange nameRange(in AllSymbols allSymbols, in EnumMember a) =>
	UriAndRange(a.containingEnum.moduleUri, rangeOfNameAndRange(a.ast.nameAndRange, allSymbols));

immutable struct StructAlias {
	@safe @nogc pure nothrow:

	StructAliasAst* ast;
	Uri moduleUri;
	Visibility visibility;
	Symbol name;
	// This will be none if the alias target is not found
	private Late!(Opt!(StructInst*)) target_;

	SmallString docComment() return scope =>
		ast.docComment;

	TypeParams typeParams() return scope =>
		emptyTypeParams;

	UriAndRange range() scope =>
		UriAndRange(moduleUri, ast.range);

	ref Opt!(StructInst*) target() return scope =>
		lateGet(target_);
	void target(Opt!(StructInst*) value) {
		lateSet(target_, value);
	}
}

UriAndRange nameRange(in AllSymbols allSymbols, in StructAlias a) =>
	UriAndRange(a.moduleUri, rangeOfNameAndRange(a.ast.name, allSymbols));

// sorted least strict to most strict
enum Linkage : ubyte { internal, extern_ }

Symbol symbolOfLinkage(Linkage a) {
	final switch (a) {
		case Linkage.internal:
			return symbol!"internal";
		case Linkage.extern_:
			return symbol!"extern";
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

	bool isTemplate() scope =>
		!isEmpty(typeParams);
}

immutable struct StructDeclSource {
	immutable struct Bogus {
		TypeParams typeParams;
	}
	mixin Union!(StructDeclAst*, Bogus*);
}
static assert(StructDeclSource.sizeof == ulong.sizeof);

UriAndRange nameRange(in AllSymbols allSymbols, in StructDecl a) =>
	UriAndRange(a.moduleUri, a.source.matchIn!Range(
		(in StructDeclAst x) =>
			nameRange(allSymbols, x),
		(in StructDeclSource.Bogus) =>
			Range.empty));

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
		body_.as!(StructBody.Record).flags.forcedByValOrRef == ForcedByValOrRefOrNone.byRef;
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
	@safe @nogc pure nothrow:

	private enum Builtin_ { data, shared_ }
	alias Builtin = immutable Builtin_;
	mixin Union!(Builtin, SmallArray!SpecDeclSig);
}
static assert(SpecDeclBody.sizeof == ulong.sizeof);
size_t countSigs(in SpecDeclBody a) =>
	a.matchIn!size_t(
		(in SpecDeclBody.Builtin x) =>
			0,
		(in SpecDeclSig[] x) =>
			x.length);

string stringOfSpecBodyBuiltinKind(SpecDeclBody.Builtin a) =>
	stringOfEnum(a);

immutable struct SpecDecl {
	@safe @nogc pure nothrow:

	Uri moduleUri;
	SpecDeclAst* ast;
	Visibility visibility;
	Symbol name;
	SpecDeclBody body_;
	private Late!(SmallArray!(immutable SpecInst*)) parents_;

	SmallString docComment() return scope =>
		ast.docComment;
	TypeParams typeParams() return scope =>
		ast.typeParams;

	bool parentsIsSet() scope =>
		lateIsSet(parents_);
	immutable(SpecInst*[]) parents() scope =>
		lateGet(parents_);
	void parents(immutable SpecInst*[] value) scope {
		lateSet(parents_, small!(immutable SpecInst*)(value));
	}
	void overwriteParentsToEmpty() scope =>
		lateSetOverwrite(parents_, emptySmallArray!(immutable SpecInst*));

	UriAndRange range() scope =>
		UriAndRange(moduleUri, ast.range);
}

UriAndRange nameRange(in AllSymbols allSymbols, in SpecDecl a) =>
	UriAndRange(a.moduleUri, nameRange(allSymbols, *a.ast));

// The SpecInst and contents are allocated using the AllInsts alloc.
immutable struct SpecInst {
	@safe @nogc pure nothrow:

	SpecDecl* decl;
	TypeArgs typeArgs;
	// Corresponds to the signatures in decl.body_
	SmallArray!ReturnAndParamTypes sigTypes;
	private Late!(SmallArray!(immutable SpecInst*)) parents_;

	immutable(SpecInst*[]) parents() return scope =>
		lateGet(parents_);
	void parents(immutable SpecInst*[] value) {
		lateSet(parents_, small!(immutable SpecInst*)(value));
	}

	Symbol name() scope =>
		decl.name;
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
	immutable struct Builtin {}
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
		FileImport,
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
}

UriAndRange nameRange(in AllSymbols allSymbols, in FunDeclSource a) =>
	a.matchIn!UriAndRange(
		(in FunDeclSource.Bogus x) =>
			UriAndRange(x.uri, Range.empty),
		(in FunDeclSource.Ast x) =>
			UriAndRange(x.moduleUri, nameRange(allSymbols, *x.ast)),
		(in EnumMember x) =>
			nameRange(allSymbols, x),
		(in FunDeclSource.FileImport x) =>
			UriAndRange(x.moduleUri, x.ast.range),
		(in RecordField x) =>
			nameRange(allSymbols, x),
		(in StructDecl x) =>
			nameRange(allSymbols, x),
		(in UnionMember x) =>
			nameRange(allSymbols, x),
		(in VarDecl x) =>
			nameRange(allSymbols, x));

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

	TypeParams typeParams() scope =>
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

UriAndRange nameRange(in AllSymbols allSymbols, in FunDecl a) scope =>
	nameRange(allSymbols, a.source);

immutable struct Test {
	@safe @nogc pure nothrow:

	TestAst* ast;
	Uri moduleUri;
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

	Type[] paramTypes() scope =>
		instantiatedSig.paramTypes;

	Arity arity() scope =>
		decl.arity;
}

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

	private PtrAndSmallNumber!SpecInst inner;

	private this(PtrAndSmallNumber!SpecInst i) {
		inner = i;
	}
	this(SpecInst* s, ushort i) {
		inner = PtrAndSmallNumber!SpecInst(s, i);
	}

	ulong asTaggable() =>
		inner.asTaggable;
	static CalledSpecSig fromTagged(ulong x) =>
		CalledSpecSig(PtrAndSmallNumber!SpecInst.fromTagged(x));

	SpecInst* specInst() =>
		inner.ptr;
	size_t sigIndex() =>
		inner.number;

	ReturnAndParamTypes instantiatedSig() return scope =>
		specInst.sigTypes[sigIndex];
	Type returnType() scope =>
		instantiatedSig.returnType;
	Type[] paramTypes() scope =>
		instantiatedSig.paramTypes;

	SpecDeclSig* nonInstantiatedSig() return scope =>
		&specInst.decl.body_.as!(SpecDeclSig[])[sigIndex];

	Symbol name() scope =>
		nonInstantiatedSig.name;

	Arity arity() scope =>
		Arity(nonInstantiatedSig.params.length);
}

// Like 'Called', but we haven't fully instantiated yet. (This is used for Candidate when checking a call expr.)
immutable struct CalledDecl {
	@safe @nogc pure nothrow:

	mixin Union!(FunDecl*, CalledSpecSig);

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
static assert(CalledDecl.sizeof == ulong.sizeof);

size_t nTypeParams(in CalledDecl a) =>
	a.typeParams.length;

immutable struct Called {
	@safe @nogc pure nothrow:

	mixin Union!(FunInst*, CalledSpecSig);

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
static assert(Called.sizeof == ulong.sizeof);

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

	mixin Union!(StructAlias*, StructDecl*);

	immutable(void*) asVoidPointer() =>
		matchWithPointers!(immutable void*)(
			(StructAlias* x) => typeAs!(immutable void*)(x),
			(StructDecl* x) => typeAs!(immutable void*)(x));

	UriAndRange range() scope =>
		matchIn!UriAndRange(
			(in StructAlias x) => x.range,
			(in StructDecl x) => x.range);

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
static assert(StructOrAlias.sizeof == ulong.sizeof);

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
}

UriAndRange nameRange(in AllSymbols allSymbols, in VarDecl a) =>
	UriAndRange(a.moduleUri, rangeOfNameAndRange(a.ast.name, allSymbols));

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
	// Includes re-exports
	HashTable!(NameReferents, Symbol, nameFromNameReferents) allExportedNames;

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
	ImportOrExportKind kind;

	ref Module module_() return scope =>
		*modulePtr;
}

// No File option since those become FunDecls
immutable struct ImportOrExportKind {
	immutable struct ModuleWhole {}
	mixin Union!(ModuleWhole, SmallArray!(Opt!(NameReferents*)));
}
static assert(ImportOrExportKind.sizeof == ulong.sizeof);

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
	fun,
	act,
	far,
	pointer,
}

immutable struct CommonFuns {
	UriAndDiagnostic[] diagnostics;
	FunInst* alloc;
	FunDecl*[] funOrActSubscriptFunDecls;
	FunInst* curExclusion;
	FunInst* mark;
	FunDecl* markVisitFunDecl;
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
	mixin Union!(DestructureAst.Single*, Generated);
}
static assert(LocalSource.sizeof == ulong.sizeof);

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
	nameRangeOfDestructureSingle(*a.source.as!(DestructureAst.Single*), allSymbols);

private Range localMustHaveRange(in Local a, in AllSymbols allSymbols) =>
	rangeOfDestructureSingle(*a.source.as!(DestructureAst.Single*), allSymbols);

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

	ulong asTaggable() =>
		lambdaAndIndex.asTaggable;
	static ClosureRef fromTagged(ulong x) =>
		ClosureRef(PtrAndSmallNumber!LambdaExpr.fromTagged(x));

	LambdaExpr* lambda() =>
		lambdaAndIndex.ptr;

	ushort index() =>
		lambdaAndIndex.number;

	VariableRef variableRef() =>
		lambda.closure[index];

	Symbol name() =>
		toLocal(this).name;

	Type type() =>
		toLocal(this).type;
}

Local* toLocal(in ClosureRef a) =>
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

	mixin Union!(Local*, ClosureRef);

	Symbol name() =>
		toLocal(this).name;
	Type type() =>
		toLocal(this).type;
}
static assert(VariableRef.sizeof == ulong.sizeof);

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

	Opt!Symbol name() scope =>
		matchIn!(Opt!Symbol)(
			(in Destructure.Ignore _) =>
				none!Symbol,
			(in Local x) =>
				some(x.name),
			(in Destructure.Split _) =>
				none!Symbol);

	Opt!Range nameRange(in AllSymbols allSymbols) scope {
		Opt!Symbol name = name;
		return has(name)
			? some(rangeOfNameAndRange(NameAndRange(range(allSymbols).start, force(name)), allSymbols))
			: none!Range;
	}

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
		LiteralCStringExpr,
		LiteralSymbolExpr,
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
		ThrowExpr*);
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
	Destructure param;
	Expr body_;
	VariableRef[] closure;
	FunKind kind;
	// For FunKind.far this includes 'future' wrapper
	Type returnType;
}

immutable struct LetExpr {
	Destructure destructure;
	Expr value;
	Expr then;
}

immutable struct LiteralExpr {
	Constant value;
}

immutable struct LiteralCStringExpr {
	string value;
}

immutable struct LiteralSymbolExpr {
	Symbol value;
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
	ExprAndType matched;
	Expr[] cases;
}

immutable struct MatchUnionExpr {
	immutable struct Case {
		Destructure destructure;
		Expr then;
	}

	ExprAndType matched;
	Case[] cases;
}

immutable struct PtrToFieldExpr {
	ExprAndType target; // This will be a pointer or by-ref type
	size_t fieldIndex;
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

alias Visibility = immutable Visibility_;
private enum Visibility_ : ubyte {
	private_,
	internal,
	public_,
}
string stringOfVisibility(Visibility a) =>
	stringOfEnum(a);

Visibility leastVisibility(Visibility a, Visibility b) =>
	min(a, b);
Visibility greatestVisibility(Visibility a, Visibility b) =>
	max(a, b);
