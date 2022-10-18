module model.diag;

@safe @nogc pure nothrow:

import frontend.lang : crowExtension;
import frontend.showDiag : ShowDiagOptions;
import model.model :
	CalledDecl,
	EnumBackingType,
	FunDecl,
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
import util.path : AllPaths, Path, PathsInfo, writePath;
import util.sourceRange : FileAndPos, FileAndRange, FileIndex, FilePaths, PathToFile, RangeWithinFile;
import util.sym : Sym;
import util.writer : Writer, writeBold, writeHyperlink, writeRed, writeReset;
import util.writerUtils : writePos, writeRangeWithinFile;

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
		immutable FunDecl* callee;
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
			enumMember,
			flagsMember,
			paramOrLocal,
			recordField,
			spec,
			structOrAlias,
			typeParam,
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
		immutable StructInst* actual;
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
		enum Reason { hasSpecs, hasTypeParams, missingLibraryName, variadic }
		immutable FunDecl* fun;
		immutable Reason reason;
	}
	struct ExternPtrHasTypeParams {}
	struct ExternRecordMustBeByRefOrVal {
		immutable StructDecl* struct_;
	}
	struct ExternUnion {}
	struct FunMissingBody {}
	struct FunModifierConflict {
		immutable Sym modifier0;
		immutable Sym modifier1;
	}
	struct FunModifierRedundant {
		immutable Sym modifier;
		// This is implied by the first modifier
		immutable Sym redundantModifier;
	}
	struct FunModifierTypeArgs {
		immutable Sym modifier;
	}
	struct IfNeedsOpt {
		immutable Type actualType;
	}
	struct ImportRefersToNothing {
		immutable Sym name;
	}
	struct LambdaCantInferParamTypes {}
	struct LambdaClosesOverMut {
		immutable Sym name;
		immutable Type type;
	}
	struct LambdaWrongNumberParams {
		immutable StructInst* expectedLambdaType;
		immutable size_t actualNParams;
	}
	struct LinkageWorseThanContainingFun {
		immutable FunDecl* containingFun;
		immutable Type referencedType;
		// empty for return type
		immutable Opt!(Param*) param;
	}
	struct LinkageWorseThanContainingType {
		immutable StructDecl* containingType;
		immutable Type referencedType;
	}
	struct LiteralOverflow {
		immutable StructInst* type;
	}
	struct LocalNotMutable {
		immutable Local* local;
	}
	struct LoopBreakNotAtTail {}
	struct LoopNeedsBreakOrContinue {}
	struct LoopNeedsExpectedType {}
	struct LoopWithoutBreak {}
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
	struct PtrIsUnsafe {}
	struct PtrMutToConst {
		enum Kind { field, local }
		immutable Kind kind;
	}
	struct PtrNeedsExpectedType {}
	struct PtrUnsupported {}
	struct PurityWorseThanParent {
		immutable StructDecl* parent;
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
		immutable FunDecl* called;
	}
	struct SpecImplFoundMultiple {
		immutable Sym sigName;
		immutable CalledDecl[] matches;
	}
	struct SpecImplHasSpecs {
		immutable FunDecl* outerCalled;
		immutable FunDecl* specImpl;
	}
	struct SpecImplNotFound {
		immutable Sym sigName;
	}
	struct ThreadLocalError {
		immutable FunDecl* fun;
		enum Kind { hasParams, hasSpecs, hasTypeParams, mustReturnPtrMut }
		immutable Kind kind;
	}
	struct ThrowNeedsExpectedType {}
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
			arrMut,
			dict,
			dictMut,
			list,
			opt,
			ptr,
			ptrMut,
		}
		immutable Kind kind;
	}
	struct UnusedImport {
		immutable Module* importedModule;
		immutable Opt!Sym importedName;
	}
	struct UnusedLocal {
		immutable Local* local;
		immutable bool usedGet;
		immutable bool usedSet;
	}
	struct UnusedParam {
		immutable Param* param;
	}
	struct UnusedPrivateFun {
		immutable FunDecl* fun;
	}
	struct UnusedPrivateSpec {
		immutable SpecDecl* spec;
	}
	struct UnusedPrivateStruct {
		immutable StructDecl* struct_;
	}
	struct UnusedPrivateStructAlias {
		immutable StructAlias* alias_;
	}
	struct WrongNumberTypeArgsForSpec {
		immutable SpecDecl* decl;
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
		funMissingBody,
		funModifierConflict,
		funModifierRedundant,
		funModifierTypeArgs,
		ifNeedsOpt,
		importRefersToNothing,
		lambdaCantInferParamTypes,
		lambdaClosesOverMut,
		lambdaWrongNumberParams,
		linkageWorseThanContainingFun,
		linkageWorseThanContainingType,
		literalOverflow,
		localNotMutable,
		loopBreakNotAtTail,
		loopNeedsBreakOrContinue,
		loopNeedsExpectedType,
		loopWithoutBreak,
		matchCaseNamesDoNotMatch,
		matchCaseShouldHaveLocal,
		matchCaseShouldNotHaveLocal,
		matchOnNonUnion,
		modifierConflict,
		modifierDuplicate,
		modifierInvalid,
		mutFieldNotAllowed,
		nameNotFound,
		parseDiag,
		ptrIsUnsafe,
		ptrMutToConst,
		ptrNeedsExpectedType,
		ptrUnsupported,
		purityWorseThanParent,
		puritySpecifierRedundant,
		recordNewVisibilityIsRedundant,
		sendFunDoesNotReturnFut,
		specBuiltinNotSatisfied,
		specImplFoundMultiple,
		specImplHasSpecs,
		specImplNotFound,
		threadLocalError,
		throwNeedsExpectedType,
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
		immutable FunMissingBody funMissingBody;
		immutable FunModifierConflict funModifierConflict;
		immutable FunModifierRedundant funModifierRedundant;
		immutable FunModifierTypeArgs funModifierTypeArgs;
		immutable IfNeedsOpt ifNeedsOpt;
		immutable ImportRefersToNothing importRefersToNothing;
		immutable LambdaCantInferParamTypes lambdaCantInferParamTypes;
		immutable LambdaClosesOverMut lambdaClosesOverMut;
		immutable LambdaWrongNumberParams lambdaWrongNumberParams;
		immutable LinkageWorseThanContainingFun linkageWorseThanContainingFun;
		immutable LinkageWorseThanContainingType linkageWorseThanContainingType;
		immutable LiteralOverflow literalOverflow;
		immutable LocalNotMutable localNotMutable;
		immutable LoopBreakNotAtTail loopBreakNotAtTail;
		immutable LoopNeedsBreakOrContinue loopNeedsBreakOrContinue;
		immutable LoopNeedsExpectedType loopNeedsExpectedType;
		immutable LoopWithoutBreak loopWithoutBreak;
		immutable MatchCaseNamesDoNotMatch matchCaseNamesDoNotMatch;
		immutable MatchCaseShouldHaveLocal matchCaseShouldHaveLocal;
		immutable MatchCaseShouldNotHaveLocal matchCaseShouldNotHaveLocal;
		immutable MatchOnNonUnion matchOnNonUnion;
		immutable ModifierConflict modifierConflict;
		immutable ModifierDuplicate modifierDuplicate;
		immutable ModifierInvalid modifierInvalid;
		immutable MutFieldNotAllowed mutFieldNotAllowed;
		immutable NameNotFound nameNotFound;
		immutable ParseDiag parseDiag;
		immutable PtrIsUnsafe ptrIsUnsafe;
		immutable PtrMutToConst ptrMutToConst;
		immutable PtrNeedsExpectedType ptrNeedsExpectedType;
		immutable PtrUnsupported ptrUnsupported;
		immutable PurityWorseThanParent purityWorseThanParent;
		immutable PuritySpecifierRedundant puritySpecifierRedundant;
		immutable RecordNewVisibilityIsRedundant recordNewVisibilityIsRedundant;
		immutable SendFunDoesNotReturnFut sendFunDoesNotReturnFut;
		immutable SpecBuiltinNotSatisfied specBuiltinNotSatisfied;
		immutable SpecImplFoundMultiple specImplFoundMultiple;
		immutable SpecImplHasSpecs specImplHasSpecs;
		immutable SpecImplNotFound specImplNotFound;
		immutable ThreadLocalError threadLocalError;
		immutable ThrowNeedsExpectedType throwNeedsExpectedType;
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
	immutable this(immutable FunMissingBody a) {
		kind = Kind.funMissingBody; funMissingBody = a;
	}
	immutable this(immutable FunModifierConflict a) { kind = Kind.funModifierConflict; funModifierConflict = a; }
	immutable this(immutable FunModifierRedundant a) { kind = Kind.funModifierRedundant; funModifierRedundant = a; }
	immutable this(immutable FunModifierTypeArgs a) {
		kind = Kind.funModifierTypeArgs; funModifierTypeArgs = a;
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
	immutable this(immutable LocalNotMutable a) { kind = Kind.localNotMutable; localNotMutable = a; }
	immutable this(immutable LoopBreakNotAtTail a) { kind = Kind.loopBreakNotAtTail; loopBreakNotAtTail = a; }
	immutable this(immutable LoopNeedsBreakOrContinue a) {
		kind = Kind.loopNeedsBreakOrContinue; loopNeedsBreakOrContinue = a;
	}
	immutable this(immutable LoopNeedsExpectedType a) { kind = Kind.loopNeedsExpectedType; loopNeedsExpectedType = a; }
	immutable this(immutable LoopWithoutBreak a) { kind = Kind.loopWithoutBreak; loopWithoutBreak = a; }
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
	@trusted immutable this(immutable ParseDiag a) {
		kind = Kind.parseDiag; parseDiag = a;
	}
	immutable this(immutable PtrIsUnsafe a) {
		kind = Kind.ptrIsUnsafe; ptrIsUnsafe = a;
	}
	immutable this(immutable PtrMutToConst a) {
		kind = kind.ptrMutToConst; ptrMutToConst = a;
	}
	immutable this(immutable PtrNeedsExpectedType a) {
		kind = Kind.ptrNeedsExpectedType; ptrNeedsExpectedType = a;
	}
	immutable this(immutable PtrUnsupported a) {
		kind = Kind.ptrUnsupported; ptrUnsupported = a;
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
	immutable this(immutable ThreadLocalError a) { kind = Kind.threadLocalError; threadLocalError = a; }
	immutable this(immutable ThrowNeedsExpectedType a) {
		kind = Kind.throwNeedsExpectedType; throwNeedsExpectedType = a;
	}
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
	scope immutable(Out) delegate(ref immutable Diag.FunMissingBody) @safe @nogc pure nothrow cbFunMissingBody,
	scope immutable(Out) delegate(
		ref immutable Diag.FunModifierConflict,
	) @safe @nogc pure nothrow cbFunModifierConflict,
	scope immutable(Out) delegate(
		ref immutable Diag.FunModifierRedundant,
	) @safe @nogc pure nothrow cbFunModifierRedundant,
	scope immutable(Out) delegate(
		ref immutable Diag.FunModifierTypeArgs
	) @safe @nogc pure nothrow cbFunModifierTypeArgs,
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
	scope immutable(Out) delegate(ref immutable Diag.LocalNotMutable) @safe @nogc pure nothrow cbLocalNotMutable,
	scope immutable(Out) delegate(ref immutable Diag.LoopBreakNotAtTail) @safe @nogc pure nothrow cbLoopBreakNotAtTail,
	scope immutable(Out) delegate(
		ref immutable Diag.LoopNeedsBreakOrContinue
	) @safe @nogc pure nothrow cbLoopNeedsBreakOrContinue,
	scope immutable(Out) delegate(
		ref immutable Diag.LoopNeedsExpectedType
	) @safe @nogc pure nothrow cbLoopNeedsExpectedType,
	scope immutable(Out) delegate(ref immutable Diag.LoopWithoutBreak) @safe @nogc pure nothrow cbLoopWithoutBreak,
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
	scope immutable(Out) delegate(ref immutable ParseDiag) @safe @nogc pure nothrow cbParseDiag,
	scope immutable(Out) delegate(ref immutable Diag.PtrIsUnsafe) @safe @nogc pure nothrow cbPtrIsUnsafe,
	scope immutable(Out) delegate(ref immutable Diag.PtrMutToConst) @safe @nogc pure nothrow cbPtrMutToConst,
	scope immutable(Out) delegate(
		ref immutable Diag.PtrNeedsExpectedType
	) @safe @nogc pure nothrow cbPtrNeedsExpectedType,
	scope immutable(Out) delegate(ref immutable Diag.PtrUnsupported) @safe @nogc pure nothrow cbPtrUnsupported,
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
	scope immutable(Out) delegate(ref immutable Diag.ThreadLocalError) @safe @nogc pure nothrow cbThreadLocalError,
	scope immutable(Out) delegate(
		ref immutable Diag.ThrowNeedsExpectedType
	) @safe @nogc pure nothrow cbThrowNeedsExpectedType,
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
		case Diag.Kind.funMissingBody:
			return cbFunMissingBody(a.funMissingBody);
		case Diag.Kind.funModifierConflict:
			return cbFunModifierConflict(a.funModifierConflict);
		case Diag.Kind.funModifierRedundant:
			return cbFunModifierRedundant(a.funModifierRedundant);
		case Diag.Kind.funModifierTypeArgs:
			return cbFunModifierTypeArgs(a.funModifierTypeArgs);
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
		case Diag.Kind.localNotMutable:
			return cbLocalNotMutable(a.localNotMutable);
		case Diag.Kind.loopBreakNotAtTail:
			return cbLoopBreakNotAtTail(a.loopBreakNotAtTail);
		case Diag.Kind.loopNeedsBreakOrContinue:
			return cbLoopNeedsBreakOrContinue(a.loopNeedsBreakOrContinue);
		case Diag.Kind.loopNeedsExpectedType:
			return cbLoopNeedsExpectedType(a.loopNeedsExpectedType);
		case Diag.Kind.loopWithoutBreak:
			return cbLoopWithoutBreak(a.loopWithoutBreak);
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
		case Diag.Kind.parseDiag:
			return cbParseDiag(a.parseDiag);
		case Diag.Kind.ptrIsUnsafe:
			return cbPtrIsUnsafe(a.ptrIsUnsafe);
		case Diag.Kind.ptrMutToConst:
			return cbPtrMutToConst(a.ptrMutToConst);
		case Diag.Kind.ptrNeedsExpectedType:
			return cbPtrNeedsExpectedType(a.ptrNeedsExpectedType);
		case Diag.Kind.ptrUnsupported:
			return cbPtrUnsupported(a.ptrUnsupported);
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
		case Diag.Kind.threadLocalError:
			return cbThreadLocalError(a.threadLocalError);
		case Diag.Kind.throwNeedsExpectedType:
			return cbThrowNeedsExpectedType(a.throwNeedsExpectedType);
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
	immutable LineAndColumnGetters lineAndColumnGetters;
}

immutable(FilesInfo) filesInfoForSingle(
	ref Alloc alloc,
	immutable Path path,
	immutable LineAndColumnGetter lineAndColumnGetter,
) =>
	immutable FilesInfo(
		fullIndexDictOfArr!(FileIndex, Path)(arrLiteral!Path(alloc, [path])),
		dictLiteral!(Path, FileIndex)(alloc, path, immutable FileIndex(0)),
		fullIndexDictOfArr!(FileIndex, LineAndColumnGetter)(
			arrLiteral!LineAndColumnGetter(alloc, [lineAndColumnGetter])));

void writeFileAndRange(
	ref Writer writer,
	ref const AllPaths allPaths,
	ref immutable PathsInfo pathsInfo,
	ref immutable ShowDiagOptions options,
	ref immutable FilesInfo fi,
	ref immutable FileAndRange where,
) {
	writeFileNoResetWriter(writer, allPaths, pathsInfo, options, fi, where.fileIndex);
	if (where.fileIndex != FileIndex.none)
		writeRangeWithinFile(writer, fi.lineAndColumnGetters[where.fileIndex], where.range);
	if (options.color)
		writeReset(writer);
}

void writeFileAndPos(
	ref Writer writer,
	scope ref const AllPaths allPaths,
	scope ref immutable PathsInfo pathsInfo,
	scope ref immutable ShowDiagOptions options,
	scope ref immutable FilesInfo fi,
	scope immutable FileAndPos where,
) {
	writeFileNoResetWriter(writer, allPaths, pathsInfo, options, fi, where.fileIndex);
	if (where.fileIndex != FileIndex.none)
		writePos(writer, fi.lineAndColumnGetters[where.fileIndex], where.pos);
	if (options.color)
		writeReset(writer);
}

void writeFile(
	ref Writer writer,
	ref const AllPaths allPaths,
	ref immutable PathsInfo pathsInfo,
	ref immutable FilesInfo fi,
	immutable FileIndex fileIndex,
) {
	immutable ShowDiagOptions noColor = immutable ShowDiagOptions(false);
	writeFileNoResetWriter(writer, allPaths, pathsInfo, noColor, fi, fileIndex);
	// No need to reset writer since we didn't use color
}

private void writeFileNoResetWriter(
	ref Writer writer,
	scope ref const AllPaths allPaths,
	scope ref immutable PathsInfo pathsInfo,
	scope ref immutable ShowDiagOptions options,
	scope ref immutable FilesInfo fi,
	immutable FileIndex fileIndex,
) {
	if (options.color)
		writeBold(writer);
	if (fileIndex == FileIndex.none) {
		writer ~= "<generated code> ";
	} else {
		immutable Path path = fi.filePaths[fileIndex];
		if (options.color) {
			writeHyperlink(
				writer,
				() { writePath(writer, allPaths, pathsInfo, path, crowExtension); },
				() { writePath(writer, allPaths, pathsInfo, path, crowExtension); });
			writeRed(writer);
		} else
			writePath(writer, allPaths, pathsInfo, path, crowExtension);
		writer ~= ' ';
	}
}
