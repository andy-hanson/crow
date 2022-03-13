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
	SpecBody,
	SpecDecl,
	StructAlias,
	StructDecl,
	StructInst,
	StructOrAlias,
	Type,
	Visibility;
import model.parseDiag : ParseDiag;
import util.alloc.alloc : Alloc;
import util.col.arrUtil : arrLiteral;
import util.col.dict : dictLiteral;
import util.col.fullIndexDict : fullIndexDictOfArr;
import util.lineAndColumnGetter : LineAndColumnGetter;
import util.opt : Opt;
import util.path : AbsolutePath, AllPaths, hashPathAndStorageKind, PathAndStorageKind, pathAndStorageKindEqual;
import util.ptr : Ptr;
import util.sourceRange : FileAndPos, FileAndRange, FileIndex, FilePaths, PathToFile, RangeWithinFile;
import util.sym : Sym;
import util.writer : Writer, writeBold, writeHyperlink, writeChar, writeRed, writeReset, writeStatic;
import util.writerUtils : writePathRelativeToCwd, writePos, writeRangeWithinFile;

enum DiagSeverity {
	unusedCode,
	checkWarning,
	checkError,
	nameNotFound,
	parseError,
	fileNotFound,
}

struct Diagnostic {
	immutable FileAndRange where;
	immutable Diag diag;
}

struct DiagnosticWithinFile {
	immutable RangeWithinFile range;
	immutable Diag diag;
}

struct Diagnostics {
	immutable DiagSeverity severity;
	immutable Diagnostic[] diags;
}

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

	struct BuiltinUnsupported {
		immutable Sym name;
	}

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

	struct CantInferTypeArguments {}
	struct CharLiteralMustBeOneChar {}
	struct CommonFunMissing {
		immutable Sym name;
	}
	struct CommonTypesMissing {
		immutable string[] missing;
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
	struct ExternFunForbidden {
		enum Reason { hasSpecs, hasTypeParams, needsNoCtx, variadic }
		immutable Ptr!FunDecl fun;
		immutable Reason reason;
	}
	struct ExternPtrHasTypeParams {}
	struct ExternRecordMustBeByRefOrVal {
		immutable Ptr!StructDecl struct_;
	}
	struct ExternUnion {}
	struct IfNeedsOpt {
		immutable Type actualType;
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
	struct LinkageWorseThanContainingFun {
		immutable Ptr!FunDecl containingFun;
		immutable Type referencedType;
		// empty for return type
		immutable Opt!(Ptr!Param) param;
	}
	struct LinkageWorseThanContainingType {
		immutable Ptr!StructDecl containingType;
		immutable Type referencedType;
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

	struct ModifierConflict {
		immutable Sym prevModifier;
		immutable Sym curModifier;
	}
	struct ModifierDuplicate {
		immutable Sym modifier;
	}
	struct ModifierInvalid {
		immutable Sym modifier;
		immutable TypeKind typeKind;
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
	struct RecordNewVisibilityIsRedundant {
		immutable Visibility visibility;
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
	struct TypeAnnotationUnnecessary {
		immutable Type type;
	}
	struct TypeConflict {
		immutable Type expected;
		immutable Type actual;
	}
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
		immutable size_t nExpectedTypeArgs;
		immutable size_t nActualTypeArgs;
	}

	private:
	enum Kind {
		builtinUnsupported,
		callMultipleMatches,
		callNoMatch,
		cantCall,
		cantInferTypeArguments,
		charLiteralMustBeOneChar,
		commonFunMissing,
		commonTypesMissing,
		duplicateDeclaration,
		duplicateExports,
		duplicateImports,
		enumBackingTypeInvalid,
		enumDuplicateValue,
		enumMemberOverflows,
		expectedTypeIsNotALambda,
		externFunForbidden,
		externPtrHasTypeParams,
		externRecordMustBeByRefOrVal,
		externUnion,
		ifNeedsOpt,
		importRefersToNothing,
		lambdaCantInferParamTypes,
		lambdaClosesOverMut,
		lambdaWrongNumberParams,
		linkageWorseThanContainingFun,
		linkageWorseThanContainingType,
		literalOverflow,
		localShadowsPrevious,
		matchCaseNamesDoNotMatch,
		matchCaseShouldHaveLocal,
		matchCaseShouldNotHaveLocal,
		matchOnNonUnion,
		modifierConflict,
		modifierDuplicate,
		modifierInvalid,
		mutFieldNotAllowed,
		nameNotFound,
		paramShadowsPrevious,
		parseDiag,
		purityWorseThanParent,
		puritySpecifierRedundant,
		recordNewVisibilityIsRedundant,
		sendFunDoesNotReturnFut,
		specBuiltinNotSatisfied,
		specImplFoundMultiple,
		specImplHasSpecs,
		specImplNotFound,
		typeAnnotationUnnecessary,
		typeConflict,
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
		immutable BuiltinUnsupported builtinUnsupported;
		immutable CallMultipleMatches callMultipleMatches;
		immutable CallNoMatch callNoMatch;
		immutable CantCall cantCall;
		immutable CantInferTypeArguments cantInferTypeArguments;
		immutable CharLiteralMustBeOneChar charLiteralMustBeOneChar;
		immutable CommonFunMissing commonFunMissing;
		immutable CommonTypesMissing commonTypesMissing;
		immutable DuplicateDeclaration duplicateDeclaration;
		immutable DuplicateExports duplicateExports;
		immutable DuplicateImports duplicateImports;
		immutable EnumBackingTypeInvalid enumBackingTypeInvalid;
		immutable EnumDuplicateValue enumDuplicateValue;
		immutable EnumMemberOverflows enumMemberOverflows;
		immutable ExpectedTypeIsNotALambda expectedTypeIsNotALambda;
		immutable ExternFunForbidden externFunForbidden;
		immutable ExternPtrHasTypeParams externPtrHasTypeParams;
		immutable ExternRecordMustBeByRefOrVal externRecordMustBeByRefOrVal;
		immutable ExternUnion externUnion;
		immutable IfNeedsOpt ifNeedsOpt;
		immutable ImportRefersToNothing importRefersToNothing;
		immutable LambdaCantInferParamTypes lambdaCantInferParamTypes;
		immutable LambdaClosesOverMut lambdaClosesOverMut;
		immutable LambdaWrongNumberParams lambdaWrongNumberParams;
		immutable LinkageWorseThanContainingFun linkageWorseThanContainingFun;
		immutable LinkageWorseThanContainingType linkageWorseThanContainingType;
		immutable LiteralOverflow literalOverflow;
		immutable LocalShadowsPrevious localShadowsPrevious;
		immutable MatchCaseNamesDoNotMatch matchCaseNamesDoNotMatch;
		immutable MatchCaseShouldHaveLocal matchCaseShouldHaveLocal;
		immutable MatchCaseShouldNotHaveLocal matchCaseShouldNotHaveLocal;
		immutable MatchOnNonUnion matchOnNonUnion;
		immutable ModifierConflict modifierConflict;
		immutable ModifierDuplicate modifierDuplicate;
		immutable ModifierInvalid modifierInvalid;
		immutable MutFieldNotAllowed mutFieldNotAllowed;
		immutable NameNotFound nameNotFound;
		immutable ParamShadowsPrevious paramShadowsPrevious;
		immutable ParseDiag parseDiag;
		immutable PurityWorseThanParent purityWorseThanParent;
		immutable PuritySpecifierRedundant puritySpecifierRedundant;
		immutable RecordNewVisibilityIsRedundant recordNewVisibilityIsRedundant;
		immutable SendFunDoesNotReturnFut sendFunDoesNotReturnFut;
		immutable SpecBuiltinNotSatisfied specBuiltinNotSatisfied;
		immutable SpecImplFoundMultiple specImplFoundMultiple;
		immutable SpecImplHasSpecs specImplHasSpecs;
		immutable SpecImplNotFound specImplNotFound;
		immutable TypeAnnotationUnnecessary typeAnnotationUnnecessary;
		immutable TypeConflict typeConflict;
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
	immutable this(immutable BuiltinUnsupported a) {
		kind = Kind.builtinUnsupported; builtinUnsupported = a;
	}
	@trusted immutable this(immutable CallMultipleMatches a) {
		kind = Kind.callMultipleMatches; callMultipleMatches = a;
	}
	@trusted immutable this(immutable CallNoMatch a) { kind = Kind.callNoMatch; callNoMatch = a; }
	@trusted immutable this(immutable CantCall a) { kind = Kind.cantCall; cantCall = a; }
	@trusted immutable this(immutable CantInferTypeArguments a) {
		kind = Kind.cantInferTypeArguments; cantInferTypeArguments = a;
	}
	immutable this(immutable CharLiteralMustBeOneChar a) {
		kind = Kind.charLiteralMustBeOneChar; charLiteralMustBeOneChar = a;
	}
	@trusted immutable this(immutable CommonFunMissing a) { kind = Kind.commonFunMissing; commonFunMissing = a; }
	@trusted immutable this(immutable CommonTypesMissing a) { kind = Kind.commonTypesMissing; commonTypesMissing = a; }
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
	immutable this(immutable ExternFunForbidden a) {
		kind = Kind.externFunForbidden; externFunForbidden = a;
	}
	immutable this(immutable ExternPtrHasTypeParams a) {
		kind = Kind.externPtrHasTypeParams; externPtrHasTypeParams = a;
	}
	immutable this(immutable ExternRecordMustBeByRefOrVal a) {
		kind = Kind.externRecordMustBeByRefOrVal; externRecordMustBeByRefOrVal = a;
	}
	immutable this(immutable ExternUnion a) {
		kind = Kind.externUnion; externUnion = a;
	}
	@trusted immutable this(immutable IfNeedsOpt a) { kind = Kind.ifNeedsOpt; ifNeedsOpt = a; }
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
	@trusted immutable this(immutable LinkageWorseThanContainingFun a) {
		kind = Kind.linkageWorseThanContainingFun; linkageWorseThanContainingFun = a;
	}
	@trusted immutable this(immutable LinkageWorseThanContainingType a) {
		kind = Kind.linkageWorseThanContainingType; linkageWorseThanContainingType = a;
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
	@trusted immutable this(immutable ModifierConflict a) {
		kind = Kind.modifierConflict; modifierConflict = a;
	}
	@trusted immutable this(immutable ModifierDuplicate a) {
		kind = Kind.modifierDuplicate; modifierDuplicate = a;
	}
	@trusted immutable this(immutable ModifierInvalid a) {
		kind = Kind.modifierInvalid; modifierInvalid = a;
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
	@trusted immutable this(immutable ParseDiag a) {
		kind = Kind.parseDiag; parseDiag = a;
	}
	@trusted immutable this(immutable PurityWorseThanParent a) {
		kind = Kind.purityWorseThanParent; purityWorseThanParent = a;
	}
	immutable this(immutable PuritySpecifierRedundant a) {
		kind = Kind.puritySpecifierRedundant; puritySpecifierRedundant = a;
	}
	immutable this(immutable RecordNewVisibilityIsRedundant a) {
		kind = Kind.recordNewVisibilityIsRedundant; recordNewVisibilityIsRedundant = a;
	}
	@trusted immutable this(immutable SendFunDoesNotReturnFut a) {
		kind = Kind.sendFunDoesNotReturnFut; sendFunDoesNotReturnFut = a;
	}
	@trusted immutable this(immutable SpecBuiltinNotSatisfied a) {
		kind = Kind.specBuiltinNotSatisfied; specBuiltinNotSatisfied = a;
	}
	@trusted immutable this(immutable SpecImplFoundMultiple a) {
		kind = Kind.specImplFoundMultiple; specImplFoundMultiple = a;
	}
	@trusted immutable this(immutable SpecImplHasSpecs a) { kind = Kind.specImplHasSpecs; specImplHasSpecs = a; }
	@trusted immutable this(immutable SpecImplNotFound a) { kind = Kind.specImplNotFound; specImplNotFound = a; }
	immutable this(immutable TypeAnnotationUnnecessary a) {
		kind = Kind.typeAnnotationUnnecessary; typeAnnotationUnnecessary = a;
	}
	@trusted immutable this(immutable TypeConflict a) { kind = Kind.typeConflict; typeConflict = a; }
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

@trusted immutable(Out) matchDiag(Out)(
	immutable Diag a,
	scope immutable(Out) delegate(ref immutable Diag.BuiltinUnsupported) @safe @nogc pure nothrow cbBuiltinUnsupported,
	scope immutable(Out) delegate(
		ref immutable Diag.CallMultipleMatches
	) @safe @nogc pure nothrow cbCallMultipleMatches,
	scope immutable(Out) delegate(ref immutable Diag.CallNoMatch) @safe @nogc pure nothrow cbCallNoMatch,
	scope immutable(Out) delegate(ref immutable Diag.CantCall) @safe @nogc pure nothrow cbCantCall,
	scope immutable(Out) delegate(
		ref immutable Diag.CantInferTypeArguments
	) @safe @nogc pure nothrow cbCantInferTypeArguments,
	scope immutable(Out) delegate(
		ref immutable Diag.CharLiteralMustBeOneChar
	) @safe @nogc pure nothrow cbCharLiteralMustBeOneChar,
	scope immutable(Out) delegate(
		ref immutable Diag.CommonFunMissing
	) @safe @nogc pure nothrow cbCommonFunMissing,
	scope immutable(Out) delegate(
		ref immutable Diag.CommonTypesMissing
	) @safe @nogc pure nothrow cbCommonTypesMissing,
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
		ref immutable Diag.ExternFunForbidden
	) @safe @nogc pure nothrow cbExternFunForbidden,
	scope immutable(Out) delegate(
		ref immutable Diag.ExternPtrHasTypeParams
	) @safe @nogc pure nothrow cbExternPtrHasTypeParams,
	scope immutable(Out) delegate(
		ref immutable Diag.ExternRecordMustBeByRefOrVal
	) @safe @nogc pure nothrow cbExternRecordMustBeByRefOrVal,
	scope immutable(Out) delegate(ref immutable Diag.ExternUnion) @safe @nogc pure nothrow cbExternUnion,
	scope immutable(Out) delegate(ref immutable Diag.IfNeedsOpt) @safe @nogc pure nothrow cbIfNeedsOpt,
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
	scope immutable(Out) delegate(
		ref immutable Diag.LinkageWorseThanContainingFun
	) @safe @nogc pure nothrow cbLinkageWorseThanContainingFun,
	scope immutable(Out) delegate(
		ref immutable Diag.LinkageWorseThanContainingType
	) @safe @nogc pure nothrow cbLinkageWorseThanContainingType,
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
	scope immutable(Out) delegate(ref immutable Diag.ModifierConflict) @safe @nogc pure nothrow cbModifierConflict,
	scope immutable(Out) delegate(ref immutable Diag.ModifierDuplicate) @safe @nogc pure nothrow cbModifierDuplicate,
	scope immutable(Out) delegate(ref immutable Diag.ModifierInvalid) @safe @nogc pure nothrow cbModifierInvalid,
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
		ref immutable Diag.RecordNewVisibilityIsRedundant
	) @safe @nogc pure nothrow cbRecordNewVisibilityIsRedundant,
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
		ref immutable Diag.TypeAnnotationUnnecessary
	) @safe @nogc pure nothrow cbTypeAnnotationUnnecessary,
	scope immutable(Out) delegate(
		ref immutable Diag.TypeConflict
	) @safe @nogc pure nothrow cbTypeConflict,
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
		case Diag.Kind.builtinUnsupported:
			return cbBuiltinUnsupported(a.builtinUnsupported);
		case Diag.Kind.callMultipleMatches:
			return cbCallMultipleMatches(a.callMultipleMatches);
		case Diag.Kind.callNoMatch:
			return cbCallNoMatch(a.callNoMatch);
		case Diag.Kind.cantCall:
			return cbCantCall(a.cantCall);
		case Diag.Kind.cantInferTypeArguments:
			return cbCantInferTypeArguments(a.cantInferTypeArguments);
		case Diag.Kind.charLiteralMustBeOneChar:
			return cbCharLiteralMustBeOneChar(a.charLiteralMustBeOneChar);
		case Diag.Kind.commonFunMissing:
			return cbCommonFunMissing(a.commonFunMissing);
		case Diag.Kind.commonTypesMissing:
			return cbCommonTypesMissing(a.commonTypesMissing);
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
		case Diag.Kind.externFunForbidden:
			return cbExternFunForbidden(a.externFunForbidden);
		case Diag.Kind.externPtrHasTypeParams:
			return cbExternPtrHasTypeParams(a.externPtrHasTypeParams);
		case Diag.Kind.externRecordMustBeByRefOrVal:
			return cbExternRecordMustBeByRefOrVal(a.externRecordMustBeByRefOrVal);
		case Diag.Kind.externUnion:
			return cbExternUnion(a.externUnion);
		case Diag.Kind.ifNeedsOpt:
			return cbIfNeedsOpt(a.ifNeedsOpt);
		case Diag.Kind.importRefersToNothing:
			return cbImportRefersToNothing(a.importRefersToNothing);
		case Diag.Kind.lambdaCantInferParamTypes:
			return cbLambdaCantInferParamTypes(a.lambdaCantInferParamTypes);
		case Diag.Kind.lambdaClosesOverMut:
			return cbLambdaClosesOverMut(a.lambdaClosesOverMut);
		case Diag.Kind.lambdaWrongNumberParams:
			return cbLambdaWrongNumberParams(a.lambdaWrongNumberParams);
		case Diag.Kind.linkageWorseThanContainingFun:
			return cbLinkageWorseThanContainingFun(a.linkageWorseThanContainingFun);
		case Diag.Kind.linkageWorseThanContainingType:
			return cbLinkageWorseThanContainingType(a.linkageWorseThanContainingType);
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
		case Diag.Kind.modifierConflict:
			return cbModifierConflict(a.modifierConflict);
		case Diag.Kind.modifierDuplicate:
			return cbModifierDuplicate(a.modifierDuplicate);
		case Diag.Kind.modifierInvalid:
			return cbModifierInvalid(a.modifierInvalid);
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
		case Diag.Kind.recordNewVisibilityIsRedundant:
			return cbRecordNewVisibilityIsRedundant(a.recordNewVisibilityIsRedundant);
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
		case Diag.Kind.typeAnnotationUnnecessary:
			return cbTypeAnnotationUnnecessary(a.typeAnnotationUnnecessary);
		case Diag.Kind.typeConflict:
			return cbTypeConflict(a.typeConflict);
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

struct FilesInfo {
	immutable FilePaths filePaths;
	immutable PathToFile pathToFile;
	immutable AbsolutePathsGetter absolutePathsGetter;
	immutable LineAndColumnGetters lineAndColumnGetters;
}

immutable(FilesInfo) filesInfoForSingle(
	ref Alloc alloc,
	immutable PathAndStorageKind path,
	immutable LineAndColumnGetter lineAndColumnGetter,
	immutable AbsolutePathsGetter absolutePathsGetter,
) {
	return immutable FilesInfo(
		fullIndexDictOfArr!(FileIndex, PathAndStorageKind)(
			arrLiteral!PathAndStorageKind(alloc, [path])),
		dictLiteral!(PathAndStorageKind, FileIndex, pathAndStorageKindEqual, hashPathAndStorageKind)(
			alloc, path, immutable FileIndex(0)),
		absolutePathsGetter,
		fullIndexDictOfArr!(FileIndex, LineAndColumnGetter)(
			arrLiteral!LineAndColumnGetter(alloc, [lineAndColumnGetter])));
}

void writeFileAndRange(
	ref Writer writer,
	ref const AllPaths allPaths,
	ref immutable ShowDiagOptions options,
	ref immutable FilesInfo fi,
	ref immutable FileAndRange where,
) {
	writeFileNoResetWriter(writer, allPaths, options, fi, where.fileIndex);
	if (where.fileIndex != FileIndex.none)
		writeRangeWithinFile(writer, fi.lineAndColumnGetters[where.fileIndex], where.range);
	if (options.color)
		writeReset(writer);
}

void writeFileAndPos(
	ref Writer writer,
	ref const AllPaths allPaths,
	ref immutable ShowDiagOptions options,
	ref immutable FilesInfo fi,
	ref immutable FileAndPos where,
) {
	writeFileNoResetWriter(writer, allPaths, options, fi, where.fileIndex);
	if (where.fileIndex != FileIndex.none)
		writePos(writer, fi.lineAndColumnGetters[where.fileIndex], where.pos);
	if (options.color)
		writeReset(writer);
}

void writeFile(
	ref Writer writer,
	ref const AllPaths allPaths,
	ref immutable FilesInfo fi,
	immutable FileIndex fileIndex,
) {
	immutable ShowDiagOptions noColor = immutable ShowDiagOptions(false);
	writeFileNoResetWriter(writer, allPaths, noColor, fi, fileIndex);
	// No need to reset writer since we didn't use color
}

private void writeFileNoResetWriter(
	ref Writer writer,
	ref const AllPaths allPaths,
	ref immutable ShowDiagOptions options,
	ref immutable FilesInfo fi,
	immutable FileIndex fileIndex,
) {
	if (options.color)
		writeBold(writer);
	if (fileIndex == FileIndex.none) {
		writeStatic(writer, "<generated code> ");
	} else {
		immutable PathAndStorageKind path = fi.filePaths[fileIndex];
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
