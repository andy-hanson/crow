module frontend.getDiagnosticSeverity;

@safe @nogc pure nothrow:

import model.diag : Diag, DiagSeverity;
import model.parseDiag : ParseDiag;

immutable(DiagSeverity) getDiagnosticSeverity(ref immutable Diag a) =>
	a.match!(immutable DiagSeverity)(
		(immutable Diag.BuiltinUnsupported) =>
			DiagSeverity.checkError,
		(immutable Diag.CallMultipleMatches) =>
			DiagSeverity.checkError,
		(immutable Diag.CallNoMatch) =>
			DiagSeverity.checkError,
		(immutable Diag.CantCall) =>
			DiagSeverity.checkError,
		(immutable Diag.CantInferTypeArguments) =>
			DiagSeverity.checkError,
		(immutable Diag.CharLiteralMustBeOneChar) =>
			DiagSeverity.checkError,
		(immutable Diag.CommonFunDuplicate) =>
			DiagSeverity.checkError,
		(immutable Diag.CommonFunMissing) =>
			DiagSeverity.checkError,
		(immutable Diag.CommonTypeMissing) =>
			DiagSeverity.checkError,
		(immutable Diag.DuplicateDeclaration) =>
			DiagSeverity.checkError,
		(immutable Diag.DuplicateExports) =>
			DiagSeverity.checkError,
		(immutable Diag.DuplicateImports) =>
			DiagSeverity.checkError,
		(immutable Diag.EnumBackingTypeInvalid) =>
			DiagSeverity.checkError,
		(immutable Diag.EnumDuplicateValue) =>
			DiagSeverity.checkError,
		(immutable Diag.EnumMemberOverflows) =>
			DiagSeverity.checkError,
		(immutable Diag.ExpectedTypeIsNotALambda) =>
			DiagSeverity.checkError,
		(immutable Diag.ExternFunForbidden) =>
			DiagSeverity.checkError,
		(immutable Diag.ExternHasTypeParams) =>
			DiagSeverity.checkError,
		(immutable Diag.ExternRecordImplicitlyByVal) =>
			DiagSeverity.checkError,
		(immutable Diag.ExternUnion) =>
			DiagSeverity.checkError,
		(immutable Diag.FunMissingBody) =>
			DiagSeverity.checkError,
		(immutable Diag.FunModifierConflict) =>
			DiagSeverity.checkError,
		(immutable Diag.FunModifierRedundant) =>
			DiagSeverity.checkWarning,
		(immutable Diag.FunModifierTypeArgs) =>
			DiagSeverity.checkError,
		(immutable Diag.IfNeedsOpt) =>
			DiagSeverity.checkError,
		(immutable Diag.ImportRefersToNothing) =>
			DiagSeverity.nameNotFound,
		(immutable Diag.LambdaCantInferParamTypes) =>
			DiagSeverity.checkError,
		(immutable Diag.LambdaClosesOverMut) =>
			DiagSeverity.checkError,
		(immutable Diag.LambdaWrongNumberParams) =>
			DiagSeverity.checkError,
		(immutable Diag.LinkageWorseThanContainingFun) =>
			DiagSeverity.checkError,
		(immutable Diag.LinkageWorseThanContainingType) =>
			DiagSeverity.checkError,
		(immutable Diag.LiteralOverflow) =>
			DiagSeverity.checkError,
		(immutable Diag.LocalNotMutable) =>
			DiagSeverity.checkWarning,
		(immutable Diag.LoopNeedsBreakOrContinue) =>
			DiagSeverity.checkError,
		(immutable Diag.LoopWithoutBreak) =>
			DiagSeverity.checkWarning,
		(immutable Diag.MatchCaseNamesDoNotMatch) =>
			DiagSeverity.checkError,
		(immutable Diag.MatchCaseShouldHaveLocal) =>
			DiagSeverity.checkWarning,
		(immutable Diag.MatchCaseShouldNotHaveLocal) =>
			DiagSeverity.checkError,
		(immutable Diag.MatchOnNonUnion) =>
			DiagSeverity.checkError,
		(immutable Diag.ModifierConflict) =>
			DiagSeverity.checkError,
		(immutable Diag.ModifierDuplicate) =>
			DiagSeverity.checkWarning,
		(immutable Diag.ModifierInvalid) =>
			DiagSeverity.checkError,
		(immutable Diag.MutFieldNotAllowed) =>
			DiagSeverity.checkError,
		(immutable Diag.NameNotFound) =>
			DiagSeverity.nameNotFound,
		(immutable Diag.NeedsExpectedType) =>
			DiagSeverity.checkError,
		(immutable Diag.ParamNotMutable) =>
			DiagSeverity.checkError,
		(immutable(ParseDiag)) =>
			DiagSeverity.parseError,
		(immutable Diag.PtrIsUnsafe) =>
			DiagSeverity.checkError,
		(immutable Diag.PtrMutToConst) =>
			DiagSeverity.checkError,
		(immutable Diag.PtrUnsupported) =>
			DiagSeverity.checkError,
		(immutable Diag.PurityWorseThanParent) =>
			DiagSeverity.checkError,
		(immutable Diag.PuritySpecifierRedundant) =>
			DiagSeverity.checkWarning,
		(immutable Diag.RecordNewVisibilityIsRedundant) =>
			DiagSeverity.checkWarning,
		(immutable Diag.SendFunDoesNotReturnFut) =>
			DiagSeverity.checkError,
		(immutable Diag.SpecBuiltinNotSatisfied) =>
			DiagSeverity.checkError,
		(immutable Diag.SpecImplFoundMultiple) =>
			DiagSeverity.checkError,
		(immutable Diag.SpecImplNotFound) =>
			DiagSeverity.checkError,
		(immutable Diag.SpecImplTooDeep) =>
			DiagSeverity.checkError,
		(immutable Diag.ThreadLocalError) =>
			DiagSeverity.checkError,
		(immutable Diag.TypeAnnotationUnnecessary) =>
			DiagSeverity.checkWarning,
		(immutable Diag.TypeConflict) =>
			DiagSeverity.checkError,
		(immutable Diag.TypeParamCantHaveTypeArgs) =>
			DiagSeverity.checkError,
		(immutable Diag.TypeShouldUseSyntax) =>
			DiagSeverity.checkWarning,
		(immutable Diag.UnusedImport) =>
			DiagSeverity.unusedCode,
		(immutable Diag.UnusedLocal) =>
			DiagSeverity.unusedCode,
		(immutable Diag.UnusedParam) =>
			DiagSeverity.unusedCode,
		(immutable Diag.UnusedPrivateFun) =>
			DiagSeverity.unusedCode,
		(immutable Diag.UnusedPrivateSpec) =>
			DiagSeverity.unusedCode,
		(immutable Diag.UnusedPrivateStruct) =>
			DiagSeverity.unusedCode,
		(immutable Diag.UnusedPrivateStructAlias) =>
			DiagSeverity.unusedCode,
		(immutable Diag.WrongNumberTypeArgsForSpec) =>
			DiagSeverity.checkError,
		(immutable Diag.WrongNumberTypeArgsForStruct) =>
			DiagSeverity.checkError);
