module model.diag;

@safe @nogc pure nothrow:

import frontend.lang : crowExtension;
import frontend.showDiag : ShowDiagOptions;
import model.model :
	AbsolutePathsGetter,
	CalledDecl,
	ClosureField,
	EnumBackingType,
	FunDecl,
	getAbsolutePath,
	LineAndColumnGetters,
	Local,
	Module,
	Param,
	Purity,
	RecordField,
	SpecBody,
	SpecDecl,
	StructAlias,
	StructDecl,
	StructInst,
	StructOrAlias,
	Type;
import model.parseDiag : ParseDiag;
import util.collection.fullIndexDict : fullIndexDictGet;
import util.opt : Opt;
import util.path : AbsolutePath, AllPaths, PathAndStorageKind;
import util.ptr : Ptr;
import util.sourceRange : FileAndPos, FileAndRange, FileIndex, FilePaths;
import util.sym : Sym;
import util.writer : Writer, writeBold, writeHyperlink, writeChar, writeRed, writeReset, writeStatic;
import util.writerUtils : writePathRelativeToCwd, writePos, writeRangeWithinFile;

enum TypeKind {
	builtin,
	enum_,
	flags,
	externPtr,
	record,
	union_,
}

struct Diag {
	@safe @nogc pure nothrow:

	// Note: this error is issued *before* resolving specs.
	// We don't exclude a candidate based on not having specs.
	struct CallMultipleMatches {
		immutable Sym funName;
		// Unlike CallNoMatch, these are only the ones that match
		immutable CalledDecl[] matches;
	}

	struct CallNoMatch {
		immutable Sym funName;
		immutable Opt!Type expectedReturnType;
		// 0 for inferred type args
		immutable size_t actualNTypeArgs;
		immutable size_t actualArity;
		// NOTE: we may have given up early and this may not be as much as actualArity
		immutable Type[] actualArgTypes;
		// All candidates, including those with wrong arity
		immutable CalledDecl[] allCandidates;
	}

	struct CantCall {
		enum Reason {
			nonNoCtx,
			summon,
			unsafe,
			variadicFromNoctx,
		}

		immutable Reason reason;
		immutable Ptr!FunDecl callee;
	}

	struct CantCreateNonRecordType {
		immutable Type type;
	}

	struct CantCreateRecordWithoutExpectedType {}
	struct CantInferTypeArguments {}
	struct CommonFunMissing {
		immutable Sym name;
	}
	struct CommonTypesMissing {
		immutable string[] missing;
	}
	struct CreateArrNoExpectedType {}
	struct CreateRecordByRefNoCtx {
		immutable Ptr!StructDecl struct_;
	}
	struct CreateRecordMultiLineWrongFields {
		immutable Ptr!StructDecl decl;
		immutable RecordField[] fields;
		immutable Sym[] providedFieldNames;
	}
	struct DuplicateDeclaration {
		enum Kind {
			structOrAlias,
			spec,
			field,
			unionMember,
		}
		immutable Kind kind;
		immutable Sym name;
	}
	struct DuplicateExports {
		enum Kind {
			spec,
			type,
		}
		immutable Kind kind;
		immutable Sym name;
	}
	struct DuplicateImports {
		enum Kind {
			spec,
			type,
		}
		immutable Kind kind;
		immutable Sym name;
	}
	struct EnumBackingTypeInvalid {
		immutable Ptr!StructInst actual;
	}
	struct EnumDuplicateValue {
		immutable bool signed;
		immutable long value;
	}
	struct EnumMemberOverflows {
		immutable EnumBackingType backingType;
	}
	struct ExpectedTypeIsNotALambda {
		immutable Opt!Type expectedType;
	}
	struct ExternPtrHasTypeParams {}
	struct IfNeedsOpt {
		immutable Type actualType;
	}
	struct IfWithoutElse {
		immutable Type thenType;
	}
	struct ImportRefersToNothing {
		immutable Sym name;
	}
	struct LambdaCantInferParamTypes {}
	struct LambdaClosesOverMut {
		immutable Ptr!ClosureField field;
	}
	struct LambdaWrongNumberParams {
		immutable Ptr!StructInst expectedLambdaType;
		immutable size_t actualNParams;
	}
	struct LiteralOverflow {
		immutable Ptr!StructInst type;
	}
	struct LocalShadowsPrevious {
		immutable Sym name;
	}
	struct MatchCaseNamesDoNotMatch {
		immutable Sym[] expectedNames;
	}
	struct MatchCaseShouldHaveLocal {
		immutable Sym name;
	}
	struct MatchCaseShouldNotHaveLocal {
		immutable Sym name;
	}
	struct MatchOnNonUnion {
		immutable Type type;
	}

	struct MutFieldNotAllowed {
		enum Reason {
			recordIsNotMut,
			recordIsForcedByVal,
		}
		immutable Reason reason;
	}
	struct NameNotFound {
		enum Kind {
			spec,
			type,
		}
		immutable Kind kind;
		immutable Sym name;
	}
	struct ParamShadowsPrevious {
		enum Kind {
			param,
			typeParam,
		}
		immutable Kind kind;
		immutable Sym name;
	}
	struct PurityWorseThanParent {
		immutable Ptr!StructDecl parent;
		immutable Type child;
	}
	struct PuritySpecifierRedundant {
		immutable Purity purity;
		immutable TypeKind typeKind;
	}
	struct SendFunDoesNotReturnFut {
		immutable Type actualReturnType;
	}
	struct SpecBuiltinNotSatisfied {
		immutable SpecBody.Builtin.Kind kind;
		immutable Type type;
		immutable Ptr!FunDecl called;
	}
	struct SpecImplFoundMultiple {
		immutable Sym sigName;
		immutable CalledDecl[] matches;
	}
	struct SpecImplHasSpecs {
		immutable Ptr!FunDecl outerCalled;
		immutable Ptr!FunDecl specImpl;
	}
	struct SpecImplNotFound {
		immutable Sym sigName;
	}
	struct TypeConflict {
		immutable Type expected;
		immutable Type actual;
	}
	struct TypeNotSendable {}
	struct TypeParamCantHaveTypeArgs {}
	struct TypeShouldUseSyntax {
		enum Kind {
			arr,
			arrMut,
			dict,
			dictMut,
			opt,
			ptr,
			ptrMut,
		}
		immutable Kind kind;
	}
	struct UnusedImport {
		immutable Ptr!Module importedModule;
		immutable Opt!Sym importedName;
	}
	struct UnusedLocal {
		immutable Ptr!Local local;
	}
	struct UnusedParam {
		immutable Ptr!Param param;
	}
	struct UnusedPrivateFun {
		immutable Ptr!FunDecl fun;
	}
	struct UnusedPrivateSpec {
		immutable Ptr!SpecDecl spec;
	}
	struct UnusedPrivateStruct {
		immutable Ptr!StructDecl struct_;
	}
	struct UnusedPrivateStructAlias {
		immutable Ptr!StructAlias alias_;
	}
	struct WrongNumberTypeArgsForSpec {
		immutable Ptr!SpecDecl decl;
		immutable size_t nExpectedTypeArgs;
		immutable size_t nActualTypeArgs;
	}
	struct WrongNumberTypeArgsForStruct {
		immutable StructOrAlias decl;
		immutable ubyte nExpectedTypeArgs;
		immutable ubyte nActualTypeArgs;
	}

	private:
	enum Kind {
		callMultipleMatches,
		callNoMatch,
		cantCall,
		cantCreateNonRecordType,
		cantCreateRecordWithoutExpectedType,
		cantInferTypeArguments,
		commonFunMissing,
		commonTypesMissing,
		createArrNoExpectedType,
		createRecordByRefNoCtx,
		createRecordMultiLineWrongFields,
		duplicateDeclaration,
		duplicateExports,
		duplicateImports,
		enumBackingTypeInvalid,
		enumDuplicateValue,
		enumMemberOverflows,
		expectedTypeIsNotALambda,
		externPtrHasTypeParams,
		ifNeedsOpt,
		ifWithoutElse,
		importRefersToNothing,
		lambdaCantInferParamTypes,
		lambdaClosesOverMut,
		lambdaWrongNumberParams,
		literalOverflow,
		localShadowsPrevious,
		matchCaseNamesDoNotMatch,
		matchCaseShouldHaveLocal,
		matchCaseShouldNotHaveLocal,
		matchOnNonUnion,
		mutFieldNotAllowed,
		nameNotFound,
		paramShadowsPrevious,
		parseDiag,
		purityWorseThanParent,
		puritySpecifierRedundant,
		sendFunDoesNotReturnFut,
		specBuiltinNotSatisfied,
		specImplFoundMultiple,
		specImplHasSpecs,
		specImplNotFound,
		typeConflict,
		typeNotSendable,
		typeParamCantHaveTypeArgs,
		typeShouldUseSyntax,
		unusedImport,
		unusedLocal,
		unusedParam,
		unusedPrivateFun,
		unusedPrivateSpec,
		unusedPrivateStruct,
		unusedPrivateStructAlias,
		wrongNumberTypeArgsForSpec,
		wrongNumberTypeArgsForStruct,
	}

	immutable Kind kind;
	union {
		immutable CallMultipleMatches callMultipleMatches;
		immutable Ptr!CallNoMatch callNoMatch;
		immutable CantCall cantCall;
		immutable CantCreateNonRecordType cantCreateNonRecordType;
		immutable CantCreateRecordWithoutExpectedType cantCreateRecordWithoutExpectedType;
		immutable CantInferTypeArguments cantInferTypeArguments;
		immutable CommonFunMissing commonFunMissing;
		immutable CommonTypesMissing commonTypesMissing;
		immutable CreateArrNoExpectedType createArrNoExpectedType;
		immutable CreateRecordByRefNoCtx createRecordByRefNoCtx;
		immutable Ptr!CreateRecordMultiLineWrongFields createRecordMultiLineWrongFields;
		immutable DuplicateDeclaration duplicateDeclaration;
		immutable DuplicateExports duplicateExports;
		immutable DuplicateImports duplicateImports;
		immutable EnumBackingTypeInvalid enumBackingTypeInvalid;
		immutable EnumDuplicateValue enumDuplicateValue;
		immutable EnumMemberOverflows enumMemberOverflows;
		immutable ExpectedTypeIsNotALambda expectedTypeIsNotALambda;
		immutable ExternPtrHasTypeParams externPtrHasTypeParams;
		immutable IfNeedsOpt ifNeedsOpt;
		immutable IfWithoutElse ifWithoutElse;
		immutable ImportRefersToNothing importRefersToNothing;
		immutable LambdaCantInferParamTypes lambdaCantInferParamTypes;
		immutable LambdaClosesOverMut lambdaClosesOverMut;
		immutable LambdaWrongNumberParams lambdaWrongNumberParams;
		immutable LiteralOverflow literalOverflow;
		immutable LocalShadowsPrevious localShadowsPrevious;
		immutable MatchCaseNamesDoNotMatch matchCaseNamesDoNotMatch;
		immutable MatchCaseShouldHaveLocal matchCaseShouldHaveLocal;
		immutable MatchCaseShouldNotHaveLocal matchCaseShouldNotHaveLocal;
		immutable MatchOnNonUnion matchOnNonUnion;
		immutable MutFieldNotAllowed mutFieldNotAllowed;
		immutable NameNotFound nameNotFound;
		immutable ParamShadowsPrevious paramShadowsPrevious;
		immutable Ptr!ParseDiag parseDiag;
		immutable PurityWorseThanParent purityWorseThanParent;
		immutable PuritySpecifierRedundant puritySpecifierRedundant;
		immutable SendFunDoesNotReturnFut sendFunDoesNotReturnFut;
		immutable Ptr!SpecBuiltinNotSatisfied specBuiltinNotSatisfied;
		immutable SpecImplFoundMultiple specImplFoundMultiple;
		immutable SpecImplHasSpecs specImplHasSpecs;
		immutable SpecImplNotFound specImplNotFound;
		immutable Ptr!TypeConflict typeConflict;
		immutable TypeNotSendable typeNotSendable;
		immutable TypeParamCantHaveTypeArgs typeParamCantHaveTypeArgs;
		immutable TypeShouldUseSyntax typeShouldUseSyntax;
		immutable UnusedImport unusedImport;
		immutable UnusedLocal unusedLocal;
		immutable UnusedParam unusedParam;
		immutable UnusedPrivateFun unusedPrivateFun;
		immutable UnusedPrivateSpec unusedPrivateSpec;
		immutable UnusedPrivateStructAlias unusedPrivateStructAlias;
		immutable UnusedPrivateStruct unusedPrivateStruct;
		immutable WrongNumberTypeArgsForSpec wrongNumberTypeArgsForSpec;
		immutable WrongNumberTypeArgsForStruct wrongNumberTypeArgsForStruct;
	}

	public:
	@trusted immutable this(immutable CallMultipleMatches a) {
		kind = Kind.callMultipleMatches; callMultipleMatches = a;
	}
	@trusted immutable this(immutable Ptr!CallNoMatch a) { kind = Kind.callNoMatch; callNoMatch = a; }
	@trusted immutable this(immutable CantCall a) { kind = Kind.cantCall; cantCall = a; }
	@trusted immutable this(immutable CantCreateNonRecordType a) {
		kind = Kind.cantCreateNonRecordType; cantCreateNonRecordType = a;
	}
	@trusted immutable this(immutable CantCreateRecordWithoutExpectedType a) {
		kind = Kind.cantCreateRecordWithoutExpectedType; cantCreateRecordWithoutExpectedType = a;
	}
	@trusted immutable this(immutable CantInferTypeArguments a) {
		kind = Kind.cantInferTypeArguments; cantInferTypeArguments = a;
	}
	@trusted immutable this(immutable CommonFunMissing a) { kind = Kind.commonFunMissing; commonFunMissing = a; }
	@trusted immutable this(immutable CommonTypesMissing a) { kind = Kind.commonTypesMissing; commonTypesMissing = a; }
	@trusted immutable this(immutable CreateArrNoExpectedType a) {
		kind = Kind.createArrNoExpectedType; createArrNoExpectedType = a;
	}
	@trusted immutable this(immutable CreateRecordByRefNoCtx a) {
		kind = Kind.createRecordByRefNoCtx; createRecordByRefNoCtx = a;
	}
	@trusted immutable this(immutable Ptr!CreateRecordMultiLineWrongFields a) {
		kind = Kind.createRecordMultiLineWrongFields; createRecordMultiLineWrongFields = a;
	}
	@trusted immutable this(immutable DuplicateDeclaration a) {
		kind = Kind.duplicateDeclaration; duplicateDeclaration = a;
	}
	@trusted immutable this(immutable DuplicateExports a) { kind = Kind.duplicateExports; duplicateExports = a; }
	@trusted immutable this(immutable DuplicateImports a) { kind = Kind.duplicateImports; duplicateImports = a; }
	@trusted immutable this(immutable EnumBackingTypeInvalid a) {
		kind = Kind.enumBackingTypeInvalid; enumBackingTypeInvalid = a;
	}
	immutable this(immutable EnumDuplicateValue a) { kind = Kind.enumDuplicateValue; enumDuplicateValue = a; }
	immutable this(immutable EnumMemberOverflows a) { kind = Kind.enumMemberOverflows; enumMemberOverflows = a; }
	@trusted immutable this(immutable ExpectedTypeIsNotALambda a) {
		kind = Kind.expectedTypeIsNotALambda; expectedTypeIsNotALambda = a;
	}
	immutable this(immutable ExternPtrHasTypeParams a) {
		kind = Kind.externPtrHasTypeParams; externPtrHasTypeParams = a;
	}
	@trusted immutable this(immutable IfNeedsOpt a) { kind = Kind.ifNeedsOpt; ifNeedsOpt = a; }
	@trusted immutable this(immutable IfWithoutElse a) { kind = Kind.ifWithoutElse; ifWithoutElse = a; }
	immutable this(immutable ImportRefersToNothing a) { kind = Kind.importRefersToNothing; importRefersToNothing = a; }
	@trusted immutable this(immutable LambdaCantInferParamTypes a) {
		kind = Kind.lambdaCantInferParamTypes; lambdaCantInferParamTypes = a;
	}
	@trusted immutable this(immutable LambdaClosesOverMut a) {
		kind = Kind.lambdaClosesOverMut; lambdaClosesOverMut = a;
	}
	@trusted immutable this(immutable LambdaWrongNumberParams a) {
		kind = Kind.lambdaWrongNumberParams; lambdaWrongNumberParams = a;
	}
	@trusted immutable this(immutable LiteralOverflow a) { kind = Kind.literalOverflow; literalOverflow = a; }
	@trusted immutable this(immutable LocalShadowsPrevious a) {
		kind = Kind.localShadowsPrevious; localShadowsPrevious = a;
	}
	@trusted immutable this(immutable MatchCaseNamesDoNotMatch a) {
		kind = Kind.matchCaseNamesDoNotMatch; matchCaseNamesDoNotMatch = a;
	}
	@trusted immutable this(immutable MatchCaseShouldHaveLocal a) {
		kind = Kind.matchCaseShouldHaveLocal; matchCaseShouldHaveLocal = a;
	}
	@trusted immutable this(immutable MatchCaseShouldNotHaveLocal a) {
		kind = Kind.matchCaseShouldNotHaveLocal; matchCaseShouldNotHaveLocal = a;
	}
	@trusted immutable this(immutable MatchOnNonUnion a) {
		kind = Kind.matchOnNonUnion; matchOnNonUnion = a;
	}
	@trusted immutable this(immutable MutFieldNotAllowed a) {
		kind = Kind.mutFieldNotAllowed; mutFieldNotAllowed = a;
	}
	@trusted immutable this(immutable NameNotFound a) {
		kind = Kind.nameNotFound; nameNotFound = a;
	}
	@trusted immutable this(immutable ParamShadowsPrevious a) {
		kind = Kind.paramShadowsPrevious; paramShadowsPrevious = a;
	}
	@trusted immutable this(immutable Ptr!ParseDiag a) {
		kind = Kind.parseDiag; parseDiag = a;
	}
	@trusted immutable this(immutable PurityWorseThanParent a) {
		kind = Kind.purityWorseThanParent; purityWorseThanParent = a;
	}
	immutable this(immutable PuritySpecifierRedundant a) {
		kind = Kind.puritySpecifierRedundant; puritySpecifierRedundant = a;
	}
	@trusted immutable this(immutable SendFunDoesNotReturnFut a) {
		kind = Kind.sendFunDoesNotReturnFut; sendFunDoesNotReturnFut = a;
	}
	@trusted immutable this(immutable Ptr!SpecBuiltinNotSatisfied a) {
		kind = Kind.specBuiltinNotSatisfied; specBuiltinNotSatisfied = a;
	}
	@trusted immutable this(immutable SpecImplFoundMultiple a) {
		kind = Kind.specImplFoundMultiple; specImplFoundMultiple = a;
	}
	@trusted immutable this(immutable SpecImplHasSpecs a) { kind = Kind.specImplHasSpecs; specImplHasSpecs = a; }
	@trusted immutable this(immutable SpecImplNotFound a) { kind = Kind.specImplNotFound; specImplNotFound = a; }
	@trusted immutable this(immutable Ptr!TypeConflict a) { kind = Kind.typeConflict; typeConflict = a; }
	@trusted immutable this(immutable TypeNotSendable a) { kind = Kind.typeNotSendable; typeNotSendable = a; }
	immutable this(immutable TypeParamCantHaveTypeArgs a) {
		kind = Kind.typeParamCantHaveTypeArgs; typeParamCantHaveTypeArgs = a;
	}
	immutable this(immutable TypeShouldUseSyntax a) { kind = Kind.typeShouldUseSyntax; typeShouldUseSyntax = a; }
	@trusted immutable this(immutable UnusedImport a) { kind = Kind.unusedImport; unusedImport = a; }
	@trusted immutable this(immutable UnusedLocal a) { kind = Kind.unusedLocal; unusedLocal = a; }
	@trusted immutable this(immutable UnusedParam a) { kind = Kind.unusedParam; unusedParam = a; }
	@trusted immutable this(immutable UnusedPrivateFun a) { kind = Kind.unusedPrivateFun; unusedPrivateFun = a; }
	@trusted immutable this(immutable UnusedPrivateSpec a) { kind = Kind.unusedPrivateSpec; unusedPrivateSpec = a; }
	@trusted immutable this(immutable UnusedPrivateStruct a) {
		kind = Kind.unusedPrivateStruct; unusedPrivateStruct = a;
	}
	@trusted immutable this(immutable UnusedPrivateStructAlias a) {
		kind = Kind.unusedPrivateStructAlias; unusedPrivateStructAlias = a;
	}
	@trusted immutable this(immutable WrongNumberTypeArgsForSpec a) {
		kind = Kind.wrongNumberTypeArgsForSpec; wrongNumberTypeArgsForSpec = a;
	}
	@trusted immutable this(immutable WrongNumberTypeArgsForStruct a) {
		kind = Kind.wrongNumberTypeArgsForStruct; wrongNumberTypeArgsForStruct = a;
	}
}
static assert(Diag.sizeof <= 32);

@trusted immutable(Out) matchDiag(Out)(
	immutable Diag a,
	scope immutable(Out) delegate(
		ref immutable Diag.CallMultipleMatches
	) @safe @nogc pure nothrow cbCallMultipleMatches,
	scope immutable(Out) delegate(ref immutable Diag.CallNoMatch) @safe @nogc pure nothrow cbCallNoMatch,
	scope immutable(Out) delegate(ref immutable Diag.CantCall) @safe @nogc pure nothrow cbCantCall,
	scope immutable(Out) delegate(
		ref immutable Diag.CantCreateNonRecordType
	) @safe @nogc pure nothrow cbCantCreateNonRecordType,
	scope immutable(Out) delegate(
		ref immutable Diag.CantCreateRecordWithoutExpectedType
	) @safe @nogc pure nothrow cbCantCreateRecordWithoutExpectedType,
	scope immutable(Out) delegate(
		ref immutable Diag.CantInferTypeArguments
	) @safe @nogc pure nothrow cbCantInferTypeArguments,
	scope immutable(Out) delegate(
		ref immutable Diag.CommonFunMissing
	) @safe @nogc pure nothrow cbCommonFunMissing,
	scope immutable(Out) delegate(
		ref immutable Diag.CommonTypesMissing
	) @safe @nogc pure nothrow cbCommonTypesMissing,
	scope immutable(Out) delegate(
		ref immutable Diag.CreateArrNoExpectedType
	) @safe @nogc pure nothrow cbCreateArrNoExpectedType,
	scope immutable(Out) delegate(
		ref immutable Diag.CreateRecordByRefNoCtx
	) @safe @nogc pure nothrow cbCreateRecordByRefNoCtx,
	scope immutable(Out) delegate(
		ref immutable Diag.CreateRecordMultiLineWrongFields
	) @safe @nogc pure nothrow cbCreateRecordMultiLineWrongFields,
	scope immutable(Out) delegate(
		ref immutable Diag.DuplicateDeclaration
	) @safe @nogc pure nothrow cbDuplicateDeclaration,
	scope immutable(Out) delegate(ref immutable Diag.DuplicateExports) @safe @nogc pure nothrow cbDuplicateExports,
	scope immutable(Out) delegate(ref immutable Diag.DuplicateImports) @safe @nogc pure nothrow cbDuplicateImports,
	scope immutable(Out) delegate(
		ref immutable Diag.EnumBackingTypeInvalid
	) @safe @nogc pure nothrow cbEnumBackingTypeInvalid,
	scope immutable(Out) delegate(ref immutable Diag.EnumDuplicateValue) @safe @nogc pure nothrow cbEnumDuplicateValue,
	scope immutable(Out) delegate(
		ref immutable Diag.EnumMemberOverflows
	) @safe @nogc pure nothrow cbEnumMemberOverflows,
	scope immutable(Out) delegate(
		ref immutable Diag.ExpectedTypeIsNotALambda
	) @safe @nogc pure nothrow cbExpectedTypeIsNotALambda,
	scope immutable(Out) delegate(
		ref immutable Diag.ExternPtrHasTypeParams
	) @safe @nogc pure nothrow cbExternPtrHasTypeParams,
	scope immutable(Out) delegate(ref immutable Diag.IfNeedsOpt) @safe @nogc pure nothrow cbIfNeedsOpt,
	scope immutable(Out) delegate(ref immutable Diag.IfWithoutElse) @safe @nogc pure nothrow cbIfWithoutElse,
	scope immutable(Out) delegate(
		ref immutable Diag.ImportRefersToNothing
	) @safe @nogc pure nothrow cbImportRefersToNothing,
	scope immutable(Out) delegate(
		ref immutable Diag.LambdaCantInferParamTypes
	) @safe @nogc pure nothrow cbLambdaCantInferParamTypes,
	scope immutable(Out) delegate(
		ref immutable Diag.LambdaClosesOverMut
	) @safe @nogc pure nothrow cbLambdaClosesOverMut,
	scope immutable(Out) delegate(
		ref immutable Diag.LambdaWrongNumberParams
	) @safe @nogc pure nothrow cbLambdaWrongNumberParams,
	scope immutable(Out) delegate(ref immutable Diag.LiteralOverflow) @safe @nogc pure nothrow cbLiteralOverflow,
	scope immutable(Out) delegate(
		ref immutable Diag.LocalShadowsPrevious
	) @safe @nogc pure nothrow cbLocalShadowsPrevious,
	scope immutable(Out) delegate(
		ref immutable Diag.MatchCaseNamesDoNotMatch
	) @safe @nogc pure nothrow cbMatchCaseNamesDoNotMatch,
	scope immutable(Out) delegate(
		ref immutable Diag.MatchCaseShouldHaveLocal
	) @safe @nogc pure nothrow cbMatchCaseShouldHaveLocal,
	scope immutable(Out) delegate(
		ref immutable Diag.MatchCaseShouldNotHaveLocal
	) @safe @nogc pure nothrow cbMatchCaseShouldNotHaveLocal,
	scope immutable(Out) delegate(
		ref immutable Diag.MatchOnNonUnion
	) @safe @nogc pure nothrow cbMatchOnNonUnion,
	scope immutable(Out) delegate(
		ref immutable Diag.MutFieldNotAllowed
	) @safe @nogc pure nothrow cbMutFieldNotAllowed,
	scope immutable(Out) delegate(
		ref immutable Diag.NameNotFound
	) @safe @nogc pure nothrow cbNameNotFound,
	scope immutable(Out) delegate(
		ref immutable Diag.ParamShadowsPrevious
	) @safe @nogc pure nothrow cbParamShadowsPrevious,
	scope immutable(Out) delegate(
		ref immutable ParseDiag)
	 @safe @nogc pure nothrow cbParseDiag,
	scope immutable(Out) delegate(
		ref immutable Diag.PurityWorseThanParent
	) @safe @nogc pure nothrow cbPurityWorseThanParent,
	scope immutable(Out) delegate(
		ref immutable Diag.PuritySpecifierRedundant
	) @safe @nogc pure nothrow cbPuritySpecifierRedundant,
	scope immutable(Out) delegate(
		ref immutable Diag.SendFunDoesNotReturnFut
	) @safe @nogc pure nothrow cbSendFunDoesNotReturnFut,
	scope immutable(Out) delegate(
		ref immutable Diag.SpecBuiltinNotSatisfied
	) @safe @nogc pure nothrow cbSpecBuiltinNotSatisfied,
	scope immutable(Out) delegate(
		ref immutable Diag.SpecImplFoundMultiple
	) @safe @nogc pure nothrow cbSpecImplFoundMultiple,
	scope immutable(Out) delegate(
		ref immutable Diag.SpecImplHasSpecs
	) @safe @nogc pure nothrow cbSpecImplHasSpecs,
	scope immutable(Out) delegate(
		ref immutable Diag.SpecImplNotFound
	) @safe @nogc pure nothrow cbSpecImplNotFound,
	scope immutable(Out) delegate(
		ref immutable Diag.TypeConflict
	) @safe @nogc pure nothrow cbTypeConflict,
	scope immutable(Out) delegate(
		ref immutable Diag.TypeNotSendable
	) @safe @nogc pure nothrow cbTypeNotSendable,
	scope immutable(Out) delegate(
		ref immutable Diag.TypeParamCantHaveTypeArgs
	) @safe @nogc pure nothrow cbTypeParamCantHaveTypeArgs,
	scope immutable(Out) delegate(
		ref immutable Diag.TypeShouldUseSyntax
	) @safe @nogc pure nothrow cbTypeShouldUseSyntax,
	scope immutable(Out) delegate(
		ref immutable Diag.UnusedImport
	) @safe @nogc pure nothrow cbUnusedImport,
	scope immutable(Out) delegate(ref immutable Diag.UnusedLocal) @safe @nogc pure nothrow cbUnusedLocal,
	scope immutable(Out) delegate(
		ref immutable Diag.UnusedParam
	) @safe @nogc pure nothrow cbUnusedParam,
	scope immutable(Out) delegate(ref immutable Diag.UnusedPrivateFun) @safe @nogc pure nothrow cbUnusedPrivateFun,
	scope immutable(Out) delegate(ref immutable Diag.UnusedPrivateSpec) @safe @nogc pure nothrow cbUnusedPrivateSpec,
	scope immutable(Out) delegate(
		ref immutable Diag.UnusedPrivateStruct,
	) @safe @nogc pure nothrow cbUnusedPrivateStruct,
	scope immutable(Out) delegate(
		ref immutable Diag.UnusedPrivateStructAlias,
	) @safe @nogc pure nothrow cbUnusedPrivateStructAlias,
	scope immutable(Out) delegate(
		ref immutable Diag.WrongNumberTypeArgsForSpec
	) @safe @nogc pure nothrow cbWrongNumberTypeArgsForSpec,
	scope immutable(Out) delegate(
		ref immutable Diag.WrongNumberTypeArgsForStruct
	) @safe @nogc pure nothrow cbWrongNumberTypeArgsForStruct,
) {
	final switch (a.kind) {
		case Diag.Kind.callMultipleMatches:
			return cbCallMultipleMatches(a.callMultipleMatches);
		case Diag.Kind.callNoMatch:
			return cbCallNoMatch(a.callNoMatch);
		case Diag.Kind.cantCall:
			return cbCantCall(a.cantCall);
		case Diag.Kind.cantCreateNonRecordType:
			return cbCantCreateNonRecordType(a.cantCreateNonRecordType);
		case Diag.Kind.cantCreateRecordWithoutExpectedType:
			return cbCantCreateRecordWithoutExpectedType(a.cantCreateRecordWithoutExpectedType);
		case Diag.Kind.cantInferTypeArguments:
			return cbCantInferTypeArguments(a.cantInferTypeArguments);
		case Diag.Kind.commonFunMissing:
			return cbCommonFunMissing(a.commonFunMissing);
		case Diag.Kind.commonTypesMissing:
			return cbCommonTypesMissing(a.commonTypesMissing);
		case Diag.Kind.createArrNoExpectedType:
			return cbCreateArrNoExpectedType(a.createArrNoExpectedType);
		case Diag.Kind.createRecordByRefNoCtx:
			return cbCreateRecordByRefNoCtx(a.createRecordByRefNoCtx);
		case Diag.Kind.createRecordMultiLineWrongFields:
			return cbCreateRecordMultiLineWrongFields(a.createRecordMultiLineWrongFields);
		case Diag.Kind.duplicateDeclaration:
			return cbDuplicateDeclaration(a.duplicateDeclaration);
		case Diag.Kind.duplicateExports:
			return cbDuplicateExports(a.duplicateExports);
		case Diag.Kind.duplicateImports:
			return cbDuplicateImports(a.duplicateImports);
		case Diag.Kind.enumBackingTypeInvalid:
			return cbEnumBackingTypeInvalid(a.enumBackingTypeInvalid);
		case Diag.Kind.enumDuplicateValue:
			return cbEnumDuplicateValue(a.enumDuplicateValue);
		case Diag.Kind.enumMemberOverflows:
			return cbEnumMemberOverflows(a.enumMemberOverflows);
		case Diag.Kind.expectedTypeIsNotALambda:
			return cbExpectedTypeIsNotALambda(a.expectedTypeIsNotALambda);
		case Diag.Kind.externPtrHasTypeParams:
			return cbExternPtrHasTypeParams(a.externPtrHasTypeParams);
		case Diag.Kind.ifNeedsOpt:
			return cbIfNeedsOpt(a.ifNeedsOpt);
		case Diag.Kind.ifWithoutElse:
			return cbIfWithoutElse(a.ifWithoutElse);
		case Diag.Kind.importRefersToNothing:
			return cbImportRefersToNothing(a.importRefersToNothing);
		case Diag.Kind.lambdaCantInferParamTypes:
			return cbLambdaCantInferParamTypes(a.lambdaCantInferParamTypes);
		case Diag.Kind.lambdaClosesOverMut:
			return cbLambdaClosesOverMut(a.lambdaClosesOverMut);
		case Diag.Kind.lambdaWrongNumberParams:
			return cbLambdaWrongNumberParams(a.lambdaWrongNumberParams);
		case Diag.Kind.literalOverflow:
			return cbLiteralOverflow(a.literalOverflow);
		case Diag.Kind.localShadowsPrevious:
			return cbLocalShadowsPrevious(a.localShadowsPrevious);
		case Diag.Kind.matchCaseNamesDoNotMatch:
			return cbMatchCaseNamesDoNotMatch(a.matchCaseNamesDoNotMatch);
		case Diag.Kind.matchCaseShouldHaveLocal:
			return cbMatchCaseShouldHaveLocal(a.matchCaseShouldHaveLocal);
		case Diag.Kind.matchCaseShouldNotHaveLocal:
			return cbMatchCaseShouldNotHaveLocal(a.matchCaseShouldNotHaveLocal);
		case Diag.Kind.matchOnNonUnion:
			return cbMatchOnNonUnion(a.matchOnNonUnion);
		case Diag.Kind.mutFieldNotAllowed:
			return cbMutFieldNotAllowed(a.mutFieldNotAllowed);
		case Diag.Kind.nameNotFound:
			return cbNameNotFound(a.nameNotFound);
		case Diag.Kind.paramShadowsPrevious:
			return cbParamShadowsPrevious(a.paramShadowsPrevious);
		case Diag.Kind.parseDiag:
			return cbParseDiag(a.parseDiag);
		case Diag.Kind.purityWorseThanParent:
			return cbPurityWorseThanParent(a.purityWorseThanParent);
		case Diag.Kind.puritySpecifierRedundant:
			return cbPuritySpecifierRedundant(a.puritySpecifierRedundant);
		case Diag.Kind.sendFunDoesNotReturnFut:
			return cbSendFunDoesNotReturnFut(a.sendFunDoesNotReturnFut);
		case Diag.Kind.specBuiltinNotSatisfied:
			return cbSpecBuiltinNotSatisfied(a.specBuiltinNotSatisfied);
		case Diag.Kind.specImplFoundMultiple:
			return cbSpecImplFoundMultiple(a.specImplFoundMultiple);
		case Diag.Kind.specImplHasSpecs:
			return cbSpecImplHasSpecs(a.specImplHasSpecs);
		case Diag.Kind.specImplNotFound:
			return cbSpecImplNotFound(a.specImplNotFound);
		case Diag.Kind.typeConflict:
			return cbTypeConflict(a.typeConflict);
		case Diag.Kind.typeNotSendable:
			return cbTypeNotSendable(a.typeNotSendable);
		case Diag.Kind.typeParamCantHaveTypeArgs:
			return cbTypeParamCantHaveTypeArgs(a.typeParamCantHaveTypeArgs);
		case Diag.Kind.typeShouldUseSyntax:
			return cbTypeShouldUseSyntax(a.typeShouldUseSyntax);
		case Diag.Kind.unusedImport:
			return cbUnusedImport(a.unusedImport);
		case Diag.Kind.unusedLocal:
			return cbUnusedLocal(a.unusedLocal);
		case Diag.Kind.unusedParam:
			return cbUnusedParam(a.unusedParam);
		case Diag.Kind.unusedPrivateFun:
			return cbUnusedPrivateFun(a.unusedPrivateFun);
		case Diag.Kind.unusedPrivateSpec:
			return cbUnusedPrivateSpec(a.unusedPrivateSpec);
		case Diag.Kind.unusedPrivateStruct:
			return cbUnusedPrivateStruct(a.unusedPrivateStruct);
		case Diag.Kind.unusedPrivateStructAlias:
			return cbUnusedPrivateStructAlias(a.unusedPrivateStructAlias);
		case Diag.Kind.wrongNumberTypeArgsForSpec:
			return cbWrongNumberTypeArgsForSpec(a.wrongNumberTypeArgsForSpec);
		case Diag.Kind.wrongNumberTypeArgsForStruct:
			return cbWrongNumberTypeArgsForStruct(a.wrongNumberTypeArgsForStruct);
	}
}

struct Diagnostic {
	immutable FileAndRange where;
	immutable Ptr!Diag diag;
}
static assert(Diagnostic.sizeof <= 32);

struct FilesInfo {
	immutable FilePaths filePaths;
	immutable Ptr!AbsolutePathsGetter absolutePathsGetter;
	immutable LineAndColumnGetters lineAndColumnGetters;
}
static assert(FilesInfo.sizeof <= 56);

void writeFileAndRange(Alloc, PathAlloc)(
	ref Writer!Alloc writer,
	ref const AllPaths!PathAlloc allPaths,
	ref immutable ShowDiagOptions options,
	ref immutable FilesInfo fi,
	ref immutable FileAndRange where,
) {
	writeFileNoResetWriter(writer, allPaths, options, fi, where.fileIndex);
	if (where.fileIndex != FileIndex.none)
		writeRangeWithinFile(writer, fullIndexDictGet(fi.lineAndColumnGetters, where.fileIndex), where.range);
	if (options.color)
		writeReset(writer);
}

void writeFileAndPos(Alloc, PathAlloc)(
	ref Writer!Alloc writer,
	ref const AllPaths!PathAlloc allPaths,
	ref immutable ShowDiagOptions options,
	ref immutable FilesInfo fi,
	ref immutable FileAndPos where,
) {
	writeFileNoResetWriter(writer, allPaths, options, fi, where.fileIndex);
	if (where.fileIndex != FileIndex.none)
		writePos(writer, fullIndexDictGet(fi.lineAndColumnGetters, where.fileIndex), where.pos);
	if (options.color)
		writeReset(writer);
}

void writeFile(Alloc, PathAlloc)(
	ref Writer!Alloc writer,
	ref const AllPaths!PathAlloc allPaths,
	ref immutable FilesInfo fi,
	immutable FileIndex fileIndex,
) {
	immutable ShowDiagOptions noColor = immutable ShowDiagOptions(false);
	writeFileNoResetWriter(writer, allPaths, noColor, fi, fileIndex);
	// No need to reset writer since we didn't use color
}

private void writeFileNoResetWriter(Alloc, PathAlloc)(
	ref Writer!Alloc writer,
	ref const AllPaths!PathAlloc allPaths,
	ref immutable ShowDiagOptions options,
	ref immutable FilesInfo fi,
	immutable FileIndex fileIndex,
) {
	if (options.color)
		writeBold(writer);
	if (fileIndex == FileIndex.none) {
		writeStatic(writer, "<generated code> ");
	} else {
		immutable PathAndStorageKind path = fullIndexDictGet(fi.filePaths, fileIndex);
		immutable AbsolutePath abs = getAbsolutePath(fi.absolutePathsGetter, path, crowExtension);
		if (options.color) {
			writeHyperlink(
				writer,
				() { writePathRelativeToCwd(writer, allPaths, fi.absolutePathsGetter.cwd, abs); },
				() { writePathRelativeToCwd(writer, allPaths, fi.absolutePathsGetter.cwd, abs); });
			writeRed(writer);
		} else
			writePathRelativeToCwd(writer, allPaths, fi.absolutePathsGetter.cwd, abs);
		writeChar(writer, ' ');
	}
}

alias Diags = Diagnostic[];
