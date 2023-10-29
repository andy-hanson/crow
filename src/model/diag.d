module model.diag;

@safe @nogc pure nothrow:

import frontend.showDiag : ShowDiagOptions;
import model.model :
	Called,
	CalledDecl,
	Destructure,
	EnumBackingType,
	FunDecl,
	FunDeclAndTypeArgs,
	LineAndColumnGetters,
	Local,
	Module,
	ReturnAndParamTypes,
	SpecDecl,
	SpecDeclBody,
	SpecDeclSig,
	StructDecl,
	StructInst,
	Type,
	TypeParamsAndSig,
	VariableRef,
	Visibility;
import model.parseDiag : ParseDiag;
import util.alloc.alloc : Alloc;
import util.col.arr : empty;
import util.col.map : mapLiteral, mustGetAt;
import util.lineAndColumnGetter : LineAndColumnGetter, PosKind;
import util.opt : Opt;
import util.sourceRange : FileAndPos, RangeWithinFile, UriAndRange;
import util.sym : Sym;
import util.union_ : Union;
import util.uri : AllUris, Uri, UrisInfo, writeUri;
import util.writer : Writer, writeBold, writeHyperlink, writeRed, writeReset;
import util.writerUtils : writePos, writeRangeWithinFile;

enum DiagSeverity {
	unusedCode,
	checkWarning,
	checkError,
	nameNotFound,
	// Severe error where a common fun (e.g. 'alloc') or type (e.g. 'void') is missing
	commonMissing,
	parseError,
	fileNotFound,
}
private bool isFatal(DiagSeverity a) =>
	a >= DiagSeverity.commonMissing;

immutable struct Diagnostic {
	// Some diagnostics aren't associated with a file, like if a root file is missing
	UriAndRange where;
	Diag diag;
}

immutable struct DiagnosticWithinFile {
	RangeWithinFile range;
	Diag diag;
}

immutable struct Diagnostics {
	DiagSeverity severity;
	Diagnostic[] diags;
}
bool diagnosticsIsEmpty(in Diagnostics a) =>
	empty(a.diags);
bool diagnosticsIsFatal(in Diagnostics a) =>
	isFatal(a.severity);

enum TypeKind {
	builtin,
	enum_,
	flags,
	extern_,
	record,
	union_,
}

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
		// Unlike CallNoMatch, these are only the ones that match
		CalledDecl[] matches;
	}

	immutable struct CallNoMatch {
		Sym funName;
		Opt!Type expectedReturnType;
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
		Sym name;
		TypeParamsAndSig[] sigChoices;
	}
	immutable struct CommonTypeMissing {
		Sym name;
	}
	immutable struct DestructureTypeMismatch {
		immutable struct Expected {
			immutable struct Tuple { size_t size; }
			mixin Union!(Tuple, Type);
		}
		Expected expected;
		Type actual;
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
		StructInst* actual;
	}
	immutable struct EnumDuplicateValue {
		bool signed;
		long value;
	}
	immutable struct EnumMemberOverflows {
		EnumBackingType backingType;
	}
	immutable struct ExpectedTypeIsNotALambda {
		Opt!Type expectedType;
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
		Type actualType;
	}
	immutable struct ImportRefersToNothing {
		Sym name;
	}
	immutable struct LambdaCantInferParamType {}
	immutable struct LambdaClosesOverMut {
		Sym name;
		// If missing, the error is that the local itself is 'mut'.
		// If present, the error is that the type is 'mut'.
		Opt!Type type;
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
		StructInst*[] types;
	}
	immutable struct LiteralNotAcceptable {
		StructInst* expectedType;
	}
	immutable struct LiteralOverflow {
		StructInst* type;
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
		Type type;
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
	immutable struct ParamCantBeMutable {}
	immutable struct ParamMissingType {}
	immutable struct ParamNotMutable {}
	immutable struct PtrIsUnsafe {}
	immutable struct PtrMutToConst {
		enum Kind { field, local }
		Kind kind;
	}
	immutable struct PtrUnsupported {}
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
		Reason reason;
		FunDeclAndTypeArgs[] trace;
	}
	immutable struct SpecNoMatch {
		immutable struct Reason {
			immutable struct BuiltinNotSatisfied {
				SpecDeclBody.Builtin.Kind kind;
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
		Type type;
	}
	immutable struct TypeConflict {
		ExpectedForDiag expected;
		Type actual;
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
		ParamCantBeMutable,
		ParamMissingType,
		ParamNotMutable,
		ParseDiag,
		PtrIsUnsafe,
		PtrMutToConst,
		PtrUnsupported,
		PurityWorseThanParent,
		RecordNewVisibilityIsRedundant,
		SpecMatchError,
		SpecNoMatch,
		SpecNameMissing,
		SpecRecursion,
		ThreadLocalError,
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
	immutable struct Infer {}
	immutable struct Loop {}
	mixin Union!(Type[], Infer, Loop);
}

immutable struct FilesInfo {
	LineAndColumnGetters lineAndColumnGetters;
}

FilesInfo filesInfoForSingle(ref Alloc alloc, Uri uri, LineAndColumnGetter lineAndColumnGetter) =>
	FilesInfo(mapLiteral!(Uri, LineAndColumnGetter)(alloc, uri, lineAndColumnGetter));

void writeUriAndRange(
	ref Writer writer,
	in AllUris allUris,
	in UrisInfo urisInfo,
	in ShowDiagOptions options,
	in FilesInfo fi,
	in UriAndRange where,
) {
	writeFileNoResetWriter(writer, allUris, urisInfo, options, where.uri);
	if (where.uri != Uri.empty)
		writeRangeWithinFile(writer, mustGetAt(fi.lineAndColumnGetters, where.uri), where.range);
	if (options.color)
		writeReset(writer);
}

void writeFileAndPos(
	ref Writer writer,
	in AllUris allUris,
	in UrisInfo urisInfo,
	in ShowDiagOptions options,
	in FilesInfo fi,
	in FileAndPos where,
) {
	writeFileNoResetWriter(writer, allUris, urisInfo, options, where.uri);
	if (where.uri != Uri.empty)
		writePos(writer, mustGetAt(fi.lineAndColumnGetters, where.uri), where.pos, PosKind.startOfRange);
	if (options.color)
		writeReset(writer);
}

void writeFile(ref Writer writer, in AllUris allUris, in UrisInfo urisInfo, Uri uri) {
	ShowDiagOptions noColor = ShowDiagOptions(false);
	writeFileNoResetWriter(writer, allUris, urisInfo, noColor, uri);
	// No need to reset writer since we didn't use color
}

private void writeFileNoResetWriter(
	ref Writer writer,
	in AllUris allUris,
	in UrisInfo urisInfo,
	in ShowDiagOptions options,
	Uri uri,
) {
	if (options.color)
		writeBold(writer);

	if (options.color) {
		writeHyperlink(
			writer,
			() { writeUri(writer, allUris, urisInfo, uri); },
			() { writeUri(writer, allUris, urisInfo, uri); });
		writeRed(writer);
	} else
		writeUri(writer, allUris, urisInfo, uri);
	writer ~= ' ';
}
