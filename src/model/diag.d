module model.diag;

@safe @nogc pure nothrow:

import model.model :
	Called,
	CalledDecl,
	Destructure,
	emptyTypeParams,
	EnumBackingType,
	FunDecl,
	FunDeclAndTypeArgs,
	Local,
	Module,
	ReturnAndParamTypes,
	SpecDecl,
	SpecDeclBody,
	SpecDeclSig,
	StructDecl,
	StructInst,
	Test,
	Type,
	TypeParams,
	TypeParamsAndSig,
	VarDecl,
	VariableRef,
	Visibility;
import model.parseDiag : ParseDiag;
import util.col.arr : empty;
import util.opt : force, Opt;
import util.sourceRange : Range, UriAndRange;
import util.sym : Sym;
import util.union_ : Union;
import util.uri : RelPath, Uri;

// In the CLI, we omit diagnostics if there are other more severe ones.
// So e.g., you wouldn't see unused code errors if there are parse errors.
enum DiagnosticSeverity {
	// Warn: JS 'getDiagnosticsForUri' calls use these numbers directly
	unusedCode,
	checkWarning,
	checkError,
	nameNotFound,
	// Severe error where a common fun (e.g. 'alloc', 'main') or type (e.g. 'void') is missing
	commonMissing,
	importError,
	parseError,
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

enum TypeKind {
	builtin,
	enum_,
	flags,
	extern_,
	record,
	union_,
}

private enum ReadFileDiag_ {
	unknown, // We've just encountered the file and haven't notified the environment.
	loading, // We've notified the environment that we want this file, but haven't received a response.
	notFound, // The file is known to not exist.
	error, // There was some error trying read the file.
}
alias ReadFileDiag = immutable ReadFileDiag_;

immutable struct Diag {
	@safe @nogc pure nothrow:

	immutable struct AssignmentNotAllowed {}

	immutable struct BuiltinUnsupported {
		Sym name;
	}

	// Note: this error is issued *before* resolving specs.
	// We don't exclude a candidate based on not having specs.
	immutable struct CallMultipleMatches {
		Sym funName;
		TypeContainer typeContainer;
		// Unlike CallNoMatch, these are only the ones that match
		CalledDecl[] matches;
	}

	immutable struct CallNoMatch {
		TypeContainer typeContainer;
		Sym funName;
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
			unsafe,
			variadicFromBare,
		}

		Reason reason;
		FunDecl* callee;
	}

	immutable struct CharLiteralMustBeOneChar {}
	immutable struct CommonFunDuplicate {
		Sym name;
	}
	immutable struct CommonFunMissing {
		FunDecl* dummyForContext;
		TypeParamsAndSig[] sigChoices;
	}
	immutable struct CommonTypeMissing {
		Sym name;
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
		Sym name;
	}
	immutable struct DuplicateExports {
		enum Kind {
			spec,
			type,
		}
		Kind kind;
		Sym name;
	}
	immutable struct DuplicateImports {
		enum Kind {
			spec,
			type,
		}
		Kind kind;
		Sym name;
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
		EnumBackingType backingType;
	}
	immutable struct ExpectedTypeIsNotALambda {
		Opt!TypeWithContainer expectedType;
	}
	immutable struct ExternFunForbidden {
		enum Reason { hasSpecs, hasTypeParams, variadic }
		FunDecl* fun;
		Reason reason;
	}
	immutable struct ExternHasTypeParams {}
	immutable struct ExternMissingLibraryName {}
	immutable struct ExternRecordImplicitlyByVal {
		StructDecl* struct_;
	}
	immutable struct ExternUnion {}
	immutable struct FunMissingBody {}
	immutable struct FunModifierTrustedOnNonExtern {}
	immutable struct IfNeedsOpt {
		TypeWithContainer actualType;
	}
	immutable struct ImportFileDiag {
		immutable struct CircularImport {
			Uri[] cycle;
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
		mixin Union!(CircularImport, ReadError, RelativeImportReachesPastRoot);
	}
	immutable struct ImportRefersToNothing {
		Sym name;
	}
	immutable struct LambdaCantInferParamType {}
	immutable struct LambdaClosesOverMut {
		Sym name;
		// If missing, the error is that the local itself is 'mut'.
		// If present, the error is that the type is 'mut'.
		Opt!TypeWithContainer type;
	}
	immutable struct LambdaMultipleMatch {
		ExpectedForDiag expected;
	}
	immutable struct LambdaNotExpected {
		ExpectedForDiag expected;
	}
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
	immutable struct LiteralAmbiguous {
		TypeContainer typeContainer;
		StructInst*[] types;
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
		Sym[] expectedNames;
	}
	immutable struct MatchOnNonUnion {
		TypeWithContainer type;
	}

	immutable struct ModifierConflict {
		Sym prevModifier;
		Sym curModifier;
	}
	immutable struct ModifierDuplicate {
		Sym modifier;
	}
	immutable struct ModifierInvalid {
		Sym modifier;
		TypeKind typeKind;
	}
	// This is like 'ModifierDuplicate' but the modifiers are not identical.
	// E.g., 'extern unsafe', since 'extern' implies 'unsafe'.
	immutable struct ModifierRedundantDueToModifier {
		Sym modifier;
		// This is implied by the first modifier
		Sym redundantModifier;
	}
	immutable struct ModifierRedundantDueToTypeKind {
		Sym modifier;
		TypeKind typeKind;
	}
	immutable struct MutFieldNotAllowed {}
	immutable struct NameNotFound {
		enum Kind {
			spec,
			type,
		}
		Kind kind;
		Sym name;
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
		enum Kind { field, local }
		Kind kind;
	}
	immutable struct PointerUnsupported {}
	immutable struct PurityWorseThanParent {
		StructDecl* parent;
		Type child;
	}
	immutable struct RecordNewVisibilityIsRedundant {
		Visibility visibility;
	}
	// spec did have a match, but there was an error
	immutable struct SpecMatchError {
		immutable struct Reason {
			immutable struct MultipleMatches {
				Sym sigName;
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
				SpecDeclBody.Builtin kind;
				Type type;
			}
			immutable struct CantInferTypeArguments {}
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
	immutable struct SpecNameMissing {}
	immutable struct SpecRecursion {
		SpecDecl*[] trace;
	}
	immutable struct ThreadLocalError {
		FunDecl* fun;
		enum Kind { hasParams, hasSpecs, hasTypeParams, mustReturnPtrMut }
		Kind kind;
	}
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
	immutable struct TypeShouldUseSyntax {
		enum Kind {
			funAct,
			funFar,
			funFun,
			future,
			list,
			map,
			mutMap,
			mutList,
			mutPointer,
			opt,
			pointer,
			tuple,
		}
		Kind kind;
	}
	immutable struct Unused {
		immutable struct Kind {
			immutable struct Import {
				Module* importedModule;
				Opt!Sym importedName;
			}
			immutable struct Local {
				.Local* local;
				bool usedGet;
				bool usedSet;
			}
			immutable struct PrivateDecl {
				Sym name;
			}
			mixin Union!(Import, Local, PrivateDecl);
		}
		Kind kind;
	}
	immutable struct VarargsParamMustBeArray {}
	immutable struct WrongNumberTypeArgs {
		Sym name;
		size_t nExpectedTypeArgs;
		size_t nActualTypeArgs;
	}

	mixin Union!(
		AssignmentNotAllowed,
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
		ExternFunForbidden,
		ExternHasTypeParams,
		ExternMissingLibraryName,
		ExternRecordImplicitlyByVal,
		ExternUnion,
		FunMissingBody,
		FunModifierTrustedOnNonExtern,
		IfNeedsOpt,
		ImportFileDiag,
		ImportRefersToNothing,
		LambdaCantInferParamType,
		LambdaClosesOverMut,
		LambdaMultipleMatch,
		LambdaNotExpected,
		LinkageWorseThanContainingFun,
		LinkageWorseThanContainingType,
		LiteralAmbiguous,
		LiteralOverflow,
		LocalIgnoredButMutable,
		LocalNotMutable,
		LoopWithoutBreak,
		MatchCaseNamesDoNotMatch,
		MatchOnNonUnion,
		ModifierConflict,
		ModifierDuplicate,
		ModifierInvalid,
		ModifierRedundantDueToModifier,
		ModifierRedundantDueToTypeKind,
		MutFieldNotAllowed,
		NameNotFound,
		NeedsExpectedType,
		ParamMissingType,
		ParseDiag,
		PointerIsUnsafe,
		PointerMutToConst,
		PointerUnsupported,
		PurityWorseThanParent,
		RecordNewVisibilityIsRedundant,
		SpecMatchError,
		SpecNoMatch,
		SpecNameMissing,
		SpecRecursion,
		TrustedUnnecessary,
		TypeAnnotationUnnecessary,
		TypeConflict,
		TypeParamCantHaveTypeArgs,
		TypeShouldUseSyntax,
		Unused,
		VarargsParamMustBeArray,
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

	mixin Union!(FunDecl*, SpecDecl*, StructDecl*, Test*, VarDecl*);

	Uri moduleUri() scope =>
		matchIn!Uri(
			(in FunDecl x) =>
				x.moduleUri,
			(in SpecDecl x) =>
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
			(in StructDecl x) =>
				x.typeParams,
			(in Test x) =>
				emptyTypeParams,
			(in VarDecl x) =>
				emptyTypeParams);
}
