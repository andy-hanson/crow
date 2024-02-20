module model.diag;

@safe @nogc pure nothrow:

import model.ast : ModifierKeyword;
import model.model :
	AutoFun,
	BuiltinSpec,
	Called,
	CalledDecl,
	Destructure,
	emptyTypeParams,
	FunDecl,
	FunDeclAndTypeArgs,
	IntegralType,
	LambdaExpr,
	Local,
	Module,
	Purity,
	ReturnAndParamTypes,
	SpecDecl,
	SpecDeclSig,
	StructAlias,
	StructDecl,
	StructInst,
	Test,
	Type,
	TypeParams,
	TypeParamsAndSig,
	UnionMember,
	VarDecl,
	VariableRef,
	Visibility;
import model.parseDiag : ParseDiag;
import util.col.array : SmallArray;
import util.opt : force, Opt;
import util.sourceRange : Range, UriAndRange;
import util.symbol : Symbol;
import util.union_ : TaggedUnion, Union;
import util.uri : RelPath, Uri;

// In the CLI, we omit diagnostics if there are other more severe ones.
// So e.g., you wouldn't see unused code errors if there are parse errors.
enum DiagnosticSeverity {
	unusedCode,
	warning,
	checkError,
	nameNotFound,
	// Severe error where a common fun (e.g. 'alloc', 'main') or type (e.g. 'void') is missing
	commonMissing,
	parseError,
	importError,
}
bool isFatal(DiagnosticSeverity a) =>
	a >= DiagnosticSeverity.commonMissing;

immutable struct UriAndDiagnostic {
	@safe @nogc pure nothrow:

	Uri uri;
	Diagnostic diagnostic;

	this(Uri u, Diagnostic d) {
		uri = u;
		diagnostic = d;
	}
	this(UriAndRange range, Diag kind) {
		uri = range.uri;
		diagnostic = Diagnostic(range.range, kind);
	}

	UriAndRange where() scope =>
		UriAndRange(uri, diagnostic.range);

	Diag kind() return scope =>
		diagnostic.kind;
}

immutable struct Diagnostic {
	Range range;
	Diag kind;
}

enum DeclKind {
	alias_,
	builtin,
	enum_,
	extern_,
	externFunction,
	function_,
	global,
	flags,
	record,
	spec,
	test,
	threadLocal,
	union_,
}

enum ReadFileDiag_ {
	unknown, // We've just encountered the file and haven't notified the environment.
	loading, // We've notified the environment that we want this file, but haven't received a response.
	notFound, // The file is known to not exist.
	error, // There was some error trying read the file.
}
alias ReadFileDiag = immutable ReadFileDiag_;

immutable struct Diag {
	@safe @nogc pure nothrow:

	immutable struct AssignmentNotAllowed {}

	immutable struct AutoFunError {
		immutable struct Bare {}
		immutable struct SpecFromWrongModule {}
		immutable struct TypeNotFullyVisible {}
		immutable struct WrongName {}
		immutable struct WrongParams {
			AutoFun.Kind kind;
		}
		immutable struct WrongParamType {
			bool isEnumOrFlags;
		}
		immutable struct WrongParamTypeEnumOrFlags {}
		immutable struct WrongReturnType {
			AutoFun.Kind kind;
		}
		mixin Union!(
			Bare,
			SpecFromWrongModule,
			TypeNotFullyVisible,
			WrongName,
			WrongParams,
			WrongParamType,
			WrongReturnType);
	}

	immutable struct BuiltinUnsupported {
		enum Kind { function_, spec, type }
		Kind kind;
		Symbol name;
	}

	// Note: this error is issued *before* resolving specs.
	// We don't exclude a candidate based on not having specs.
	immutable struct CallMultipleMatches {
		Symbol funName;
		TypeContainer typeContainer;
		// Unlike CallNoMatch, these are only the ones that match
		CalledDecl[] matches;
	}

	immutable struct CallNoMatch {
		TypeContainer typeContainer;
		Symbol funName;
		ExpectedForDiag expectedReturnType;
		// 0 for inferred type args.
		// This is the unpacked tuple, actualNTypeArgs > 1 may match candidates with 1 type arg.
		size_t actualNTypeArgs;
		size_t actualArity;
		// NOTE: we may have given up early and this may not be as much as actualArity
		Type[] actualArgTypes;
		// All candidates, including those with wrong arity
		CalledDecl[] allCandidates;
	}

	immutable struct CallShouldUseSyntax {
		enum Kind {
			for_break,
			force,
			for_loop,
			new_,
			not,
			set_subscript,
			subscript,
			with_block,
		}
		size_t arity;
		Kind kind;
	}

	immutable struct CantCall {
		enum Reason {
			nonBare,
			summon,
			summonInDataLambda,
			unsafe,
			variadicFromBare,
		}

		Reason reason;
		FunDecl* callee;
	}

	immutable struct CharLiteralMustBeOneChar {}
	immutable struct CommonFunDuplicate {
		Symbol name;
	}
	immutable struct CommonFunMissing {
		FunDecl* dummyForContext;
		TypeParamsAndSig[] sigChoices;
	}
	immutable struct CommonTypeMissing {
		Symbol name;
	}
	immutable struct DestructureTypeMismatch {
		immutable struct Expected {
			immutable struct Tuple { size_t size; }
			mixin Union!(Tuple, TypeWithContainer);
		}
		Expected expected;
		TypeWithContainer actual;
	}
	immutable struct DuplicateDeclaration {
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
		Kind kind;
		Symbol name;
	}
	immutable struct DuplicateExports {
		enum Kind {
			spec,
			type,
		}
		Kind kind;
		Symbol name;
	}
	immutable struct DuplicateImports {
		enum Kind {
			spec,
			type,
		}
		Kind kind;
		Symbol name;
	}
	immutable struct EnumBackingTypeInvalid {
		StructDecl* enum_;
		Type actual;
	}
	immutable struct EnumDuplicateValue {
		bool signed;
		long value;
	}
	immutable struct EnumMemberOverflows {
		IntegralType storage;
	}
	immutable struct ExpectedTypeIsNotALambda {
		Opt!TypeWithContainer expectedType;
	}
	immutable struct ExternFunVariadic {}
	immutable struct ExternHasUnnecessaryLibraryName {}
	immutable struct ExternMissingLibraryName {}
	immutable struct ExternRecordImplicitlyByVal {
		StructDecl* struct_;
	}
	immutable struct ExternTypeError {
		enum Reason { alignmentIsDefault, badAlignment, tooBig }
		Reason reason;
	}
	immutable struct ExternUnion {}
	immutable struct FunCantHaveBody {
		enum Reason { builtin, extern_ }
		Reason reason;
	}
	immutable struct FunModifierTrustedOnNonExtern {}
	immutable struct FunPointerExprMustBeName {}
	immutable struct FunPointerNotSupported {
		enum Reason { multiple, spec, template_ }
		Reason reason;
		Symbol name;
	}
	immutable struct IfNeedsOpt {
		TypeWithContainer actualType;
	}
	immutable struct ImportFileDiag {
		immutable struct CantImportCrowAsText {}
		immutable struct CircularImport {
			SmallArray!Uri cycle;
		}
		immutable struct LibraryNotConfigured {
			Symbol libraryName;
		}
		immutable struct ReadError {
			// The imported file will also have a ParseDiag for the issue, but we also show the error in the importer.
			// (This is important in an IDE.)
			Uri uri;
			ReadFileDiag diag;
		}
		immutable struct RelativeImportReachesPastRoot {
			RelPath imported;
		}
		mixin Union!(
			CantImportCrowAsText,
			CircularImport,
			LibraryNotConfigured,
			ReadError,
			RelativeImportReachesPastRoot);
	}
	immutable struct ImportRefersToNothing {
		Symbol name;
	}
	immutable struct LambdaCantBeFunctionPointer {}
	immutable struct LambdaCantInferParamType {}
	immutable struct LambdaClosurePurity {
		LambdaExpr.Kind lambdaKind;
		Symbol localName;
		Purity localPurity;
		// If missing, the error is that the local itself is 'mut'.
		// If present, the error is that the type is 'mut'.
		Opt!TypeWithContainer type;
	}
	immutable struct LambdaMultipleMatch {
		// This is only the expected types that are lambdas
		ExpectedForDiag.Choices choices;
	}
	immutable struct LambdaNotExpected {
		ExpectedForDiag expected;
	}
	immutable struct LambdaTypeMissingParamType {}
	immutable struct LambdaTypeVariadic {}
	immutable struct LinkageWorseThanContainingFun {
		FunDecl* containingFun;
		Type referencedType;
		// empty for return type
		Opt!(Destructure*) param;
	}
	immutable struct LinkageWorseThanContainingType {
		StructDecl* containingType;
		Type referencedType;
	}
	immutable struct LiteralMultipleMatch {
		TypeContainer typeContainer;
		StructInst*[] types;
	}
	immutable struct LiteralNotExpected {
		ExpectedForDiag expected;
	}
	immutable struct LiteralOverflow {
		TypeWithContainer type;
	}
	immutable struct LocalIgnoredButMutable {}
	immutable struct LocalNotMutable {
		VariableRef local;
	}
	immutable struct LoopWithoutBreak {}
	immutable struct MatchCaseNamesDoNotMatch {
		Symbol[] expectedNames;
	}
	immutable struct MatchCaseNoValueForEnum {
		StructDecl* enum_;
	}
	immutable struct MatchCaseShouldUseIgnore {
		UnionMember* member;
	}
	immutable struct MatchOnNonEnumOrUnion {
		TypeWithContainer type;
	}

	immutable struct ModifierConflict {
		ModifierKeyword prevModifier;
		ModifierKeyword curModifier;
	}
	immutable struct ModifierDuplicate {
		ModifierKeyword modifier;
	}
	immutable struct ModifierInvalid {
		ModifierKeyword modifier;
		DeclKind declKind;
	}
	// This is like 'ModifierDuplicate' but the modifiers are not identical.
	// E.g., 'extern unsafe', since 'extern' implies 'unsafe'.
	immutable struct ModifierRedundantDueToModifier {
		ModifierKeyword modifier;
		// This is implied by the first modifier
		ModifierKeyword redundantModifier;
	}
	immutable struct ModifierRedundantDueToDeclKind {
		ModifierKeyword modifier;
		DeclKind declKind;
	}
	immutable struct ModifierTypeArgInvalid {
		ModifierKeyword modifier;
	}
	immutable struct MutFieldNotAllowed {}
	immutable struct NameNotFound {
		enum Kind {
			function_,
			spec,
			type,
		}
		Kind kind;
		Symbol name;
	}
	immutable struct NeedsExpectedType {
		enum Kind {
			loop,
			pointer,
			throw_,
		}
		Kind kind;
	}
	immutable struct ParamMissingType {}
	immutable struct PointerIsUnsafe {}
	immutable struct PointerMutToConst {
		enum Kind { fieldOfByRef, fieldOfByVal, local }
		Kind kind;
	}
	immutable struct PointerUnsupported {
		enum Reason { other, recordNotByRef }
		Reason reason;
	}
	immutable struct PurityWorseThanParent {
		StructDecl* parent;
		Type child;
	}
	immutable struct RecordFieldNeedsType {
		Symbol fieldName;
	}
	immutable struct StructParamsSyntaxError {
		enum Reason {
			hasParamsAndFields,
			destructure,
			variadic,
		}
		StructDecl* struct_;
		Reason reason;
	}
	immutable struct SharedArgIsNotLambda {}
	immutable struct SharedLambdaTypeIsNotShared {
		enum Kind { paramType, returnType }
		Kind kind;
		TypeWithContainer actual;
	}
	immutable struct SharedLambdaUnused {}
	immutable struct SharedNotExpected {
		enum Reason { notShared, notFuture }
		Reason reason;
		ExpectedForDiag expected;
	}
	// spec did have a match, but there was an error
	immutable struct SpecMatchError {
		immutable struct Reason {
			immutable struct MultipleMatches {
				Symbol sigName;
				Called[] matches;
			}
			mixin Union!(MultipleMatches);
		}
		TypeContainer outermostTypeContainer;
		Reason reason;
		FunDeclAndTypeArgs[] trace;
	}
	immutable struct SpecNoMatch {
		immutable struct Reason {
			immutable struct BuiltinNotSatisfied {
				BuiltinSpec kind;
				Type type;
			}
			immutable struct CantInferTypeArguments {
				// Since we didn't infer type args, it can't go onto the trace.
				FunDecl* fun;
			}
			immutable struct SpecImplNotFound {
				SpecDeclSig* sigDecl;
				ReturnAndParamTypes sigType;
			}
			immutable struct TooDeep {}
			mixin Union!(BuiltinNotSatisfied, CantInferTypeArguments, SpecImplNotFound, TooDeep);
		}
		TypeContainer outermostTypeContainer;
		Reason reason;
		FunDeclAndTypeArgs[] trace;
	}
	immutable struct SpecRecursion {
		SpecDecl*[] trace;
	}
	immutable struct SpecSigCantBeVariadic {}
	immutable struct SpecUseInvalid {
		DeclKind declKind;
	}
	immutable struct StringLiteralInvalid {
		enum Reason { cStringContainsNul, symbolContainsNul }
		Reason reason;
	}
	immutable struct StorageMissingType {}
	immutable struct TestMissingBody {}
	immutable struct TrustedUnnecessary {
		enum Reason {
			inTrusted,
			inUnsafeFunction,
			unused,
		}
		Reason reason;
	}
	immutable struct TypeAnnotationUnnecessary {
		TypeWithContainer type;
	}
	immutable struct TypeConflict {
		ExpectedForDiag expected;
		TypeWithContainer actual;
	}
	immutable struct TypeParamCantHaveTypeArgs {}
	immutable struct TypeParamsUnsupported {
		DeclKind declKind;
	}
	immutable struct TypeShouldUseSyntax {
		enum Kind {
			funData,
			funMut,
			funPointer,
			funShared,
			future,
			list,
			map,
			mutMap,
			mutList,
			mutPointer,
			opt,
			pointer,
			sharedList,
			sharedMap,
			tuple,
		}
		Kind kind;
	}
	immutable struct UnsupportedSyntax {
		enum Reason { enumMemberMutability, enumMemberType, unionMemberMutability, unionMemberVisibility }
		Reason reason;
	}
	immutable struct Unused {
		immutable struct Kind {
			immutable struct Import {
				Module* importedModule;
				Opt!Symbol importedName;
			}
			immutable struct Local {
				.Local* local;
				bool usedGet;
				bool usedSet;
			}
			immutable struct PrivateDecl {
				Symbol name;
			}
			mixin Union!(Import, Local, PrivateDecl);
		}
		Kind kind;
	}
	immutable struct VarargsParamMustBeArray {}
	// We don't have any warning at the top-level even though '~' is redundant. This is only within a record.
	immutable struct VisibilityWarning {
		immutable struct Kind {
			immutable struct Field { StructDecl* record; Symbol fieldName; }
			immutable struct FieldMutability { Symbol fieldName; }
			immutable struct New { StructDecl* record; }
			mixin Union!(Field, FieldMutability, New);
		}
		Kind kind;
		Visibility defaultVisibility;
		Visibility actualVisibility;
	}
	immutable struct WithHasElse {}
	immutable struct WrongNumberTypeArgs {
		Symbol name;
		size_t nExpectedTypeArgs;
		size_t nActualTypeArgs;
	}

	mixin Union!(
		AssignmentNotAllowed,
		AutoFunError,
		BuiltinUnsupported,
		CallMultipleMatches,
		CallNoMatch,
		CallShouldUseSyntax,
		CantCall,
		CharLiteralMustBeOneChar,
		CommonFunDuplicate,
		CommonFunMissing,
		CommonTypeMissing,
		DestructureTypeMismatch,
		DuplicateDeclaration,
		DuplicateExports,
		DuplicateImports,
		EnumBackingTypeInvalid,
		EnumDuplicateValue,
		EnumMemberOverflows,
		ExpectedTypeIsNotALambda,
		ExternFunVariadic,
		ExternHasUnnecessaryLibraryName,
		ExternMissingLibraryName,
		ExternRecordImplicitlyByVal,
		ExternTypeError,
		ExternUnion,
		FunCantHaveBody,
		FunModifierTrustedOnNonExtern,
		FunPointerExprMustBeName,
		FunPointerNotSupported,
		IfNeedsOpt,
		ImportFileDiag*,
		ImportRefersToNothing,
		LambdaCantBeFunctionPointer,
		LambdaCantInferParamType,
		LambdaClosurePurity,
		LambdaMultipleMatch,
		LambdaNotExpected,
		LambdaTypeMissingParamType,
		LambdaTypeVariadic,
		LinkageWorseThanContainingFun,
		LinkageWorseThanContainingType,
		LiteralMultipleMatch,
		LiteralNotExpected,
		LiteralOverflow,
		LocalIgnoredButMutable,
		LocalNotMutable,
		LoopWithoutBreak,
		MatchCaseNamesDoNotMatch,
		MatchCaseNoValueForEnum,
		MatchCaseShouldUseIgnore,
		MatchOnNonEnumOrUnion,
		ModifierConflict,
		ModifierDuplicate,
		ModifierInvalid,
		ModifierRedundantDueToDeclKind,
		ModifierRedundantDueToModifier,
		ModifierTypeArgInvalid,
		MutFieldNotAllowed,
		NameNotFound,
		NeedsExpectedType,
		ParamMissingType,
		ParseDiag,
		PointerIsUnsafe,
		PointerMutToConst,
		PointerUnsupported,
		PurityWorseThanParent,
		RecordFieldNeedsType,
		SharedArgIsNotLambda,
		SharedLambdaTypeIsNotShared,
		SharedLambdaUnused,
		SharedNotExpected,
		SpecMatchError,
		SpecNoMatch,
		SpecRecursion,
		SpecSigCantBeVariadic,
		SpecUseInvalid,
		StringLiteralInvalid,
		StorageMissingType,
		StructParamsSyntaxError,
		TestMissingBody,
		TrustedUnnecessary,
		TypeAnnotationUnnecessary,
		TypeConflict,
		TypeParamCantHaveTypeArgs,
		TypeParamsUnsupported,
		TypeShouldUseSyntax,
		UnsupportedSyntax,
		Unused,
		VarargsParamMustBeArray,
		VisibilityWarning,
		WithHasElse,
		WrongNumberTypeArgs);
}

immutable struct ExpectedForDiag {
	immutable struct Choices {
		Type[] types;
		TypeContainer typeContainer;
	}
	immutable struct Infer {}
	immutable struct Loop {}
	mixin Union!(Choices, Infer, Loop);
}

immutable struct TypeWithContainer {
	Type type;
	TypeContainer container;
}

// Since a type parameter is represented as its index, we need a context to know where to find it.
immutable struct TypeContainer {
	@safe @nogc pure nothrow:

	mixin TaggedUnion!(FunDecl*, SpecDecl*, StructAlias*, StructDecl*, Test*, VarDecl*);

	Uri moduleUri() scope =>
		matchIn!Uri(
			(in FunDecl x) =>
				x.moduleUri,
			(in SpecDecl x) =>
				x.moduleUri,
			(in StructAlias x) =>
				x.moduleUri,
			(in StructDecl x) =>
				x.moduleUri,
			(in Test x) =>
				x.moduleUri,
			(in VarDecl x) =>
				x.moduleUri);

	TypeParams typeParams() scope =>
		matchIn!TypeParams(
			(in FunDecl x) =>
				x.typeParams,
			(in SpecDecl x) =>
				x.typeParams,
			(in StructAlias x) =>
				emptyTypeParams,
			(in StructDecl x) =>
				x.typeParams,
			(in Test x) =>
				emptyTypeParams,
			(in VarDecl x) =>
				emptyTypeParams);
}
