module frontend.getDiagnosticSeverity;

@safe @nogc pure nothrow:

import model.diag : Diag, DiagSeverity;
import model.parseDiag : ParseDiag;

DiagSeverity getDiagnosticSeverity(in Diag a) =>
	a.matchIn!DiagSeverity(
		(in Diag.BuiltinUnsupported) =>
			DiagSeverity.checkError,
		(in Diag.CallMultipleMatches) =>
			DiagSeverity.checkError,
		(in Diag.CallNoMatch) =>
			DiagSeverity.checkError,
		(in Diag.CantCall) =>
			DiagSeverity.checkError,
		(in Diag.CantInferTypeArguments) =>
			DiagSeverity.checkError,
		(in Diag.CharLiteralMustBeOneChar) =>
			DiagSeverity.checkError,
		(in Diag.CommonFunDuplicate) =>
			DiagSeverity.checkError,
		(in Diag.CommonFunMissing) =>
			DiagSeverity.checkError,
		(in Diag.CommonTypeMissing) =>
			DiagSeverity.checkError,
		(in Diag.DuplicateDeclaration) =>
			DiagSeverity.checkError,
		(in Diag.DuplicateExports) =>
			DiagSeverity.checkError,
		(in Diag.DuplicateImports) =>
			DiagSeverity.checkError,
		(in Diag.EnumBackingTypeInvalid) =>
			DiagSeverity.checkError,
		(in Diag.EnumDuplicateValue) =>
			DiagSeverity.checkError,
		(in Diag.EnumMemberOverflows) =>
			DiagSeverity.checkError,
		(in Diag.ExpectedTypeIsNotALambda) =>
			DiagSeverity.checkError,
		(in Diag.ExternFunForbidden) =>
			DiagSeverity.checkError,
		(in Diag.ExternHasTypeParams) =>
			DiagSeverity.checkError,
		(in Diag.ExternRecordImplicitlyByVal) =>
			DiagSeverity.checkError,
		(in Diag.ExternUnion) =>
			DiagSeverity.checkError,
		(in Diag.FunMissingBody) =>
			DiagSeverity.checkError,
		(in Diag.FunModifierConflict) =>
			DiagSeverity.checkError,
		(in Diag.FunModifierRedundant) =>
			DiagSeverity.checkWarning,
		(in FunModifierTrustedOnNonExtern) =>
			DiagSeverity.checkError,
		(in Diag.IfNeedsOpt) =>
			DiagSeverity.checkError,
		(in Diag.ImportRefersToNothing) =>
			DiagSeverity.nameNotFound,
		(in Diag.LambdaCantInferParamTypes) =>
			DiagSeverity.checkError,
		(in Diag.LambdaClosesOverMut) =>
			DiagSeverity.checkError,
		(in Diag.LambdaWrongNumberParams) =>
			DiagSeverity.checkError,
		(in Diag.LinkageWorseThanContainingFun) =>
			DiagSeverity.checkError,
		(in Diag.LinkageWorseThanContainingType) =>
			DiagSeverity.checkError,
		(in Diag.LiteralOverflow) =>
			DiagSeverity.checkError,
		(in Diag.LocalNotMutable) =>
			DiagSeverity.checkWarning,
		(in Diag.LoopNeedsBreakOrContinue) =>
			DiagSeverity.checkError,
		(in Diag.LoopWithoutBreak) =>
			DiagSeverity.checkWarning,
		(in Diag.MatchCaseNamesDoNotMatch) =>
			DiagSeverity.checkError,
		(in Diag.MatchCaseShouldHaveLocal) =>
			DiagSeverity.checkWarning,
		(in Diag.MatchCaseShouldNotHaveLocal) =>
			DiagSeverity.checkError,
		(in Diag.MatchOnNonUnion) =>
			DiagSeverity.checkError,
		(in Diag.ModifierConflict) =>
			DiagSeverity.checkError,
		(in Diag.ModifierDuplicate) =>
			DiagSeverity.checkWarning,
		(in Diag.ModifierInvalid) =>
			DiagSeverity.checkError,
		(in Diag.MutFieldNotAllowed) =>
			DiagSeverity.checkError,
		(in Diag.NameNotFound) =>
			DiagSeverity.nameNotFound,
		(in Diag.NeedsExpectedType) =>
			DiagSeverity.checkError,
		(in Diag.ParamNotMutable) =>
			DiagSeverity.checkError,
		(in ParseDiag _) =>
			DiagSeverity.parseError,
		(in Diag.PtrIsUnsafe) =>
			DiagSeverity.checkError,
		(in Diag.PtrMutToConst) =>
			DiagSeverity.checkError,
		(in Diag.PtrUnsupported) =>
			DiagSeverity.checkError,
		(in Diag.PurityWorseThanParent) =>
			DiagSeverity.checkError,
		(in Diag.PuritySpecifierRedundant) =>
			DiagSeverity.checkWarning,
		(in Diag.RecordNewVisibilityIsRedundant) =>
			DiagSeverity.checkWarning,
		(in Diag.SendFunDoesNotReturnFut) =>
			DiagSeverity.checkError,
		(in Diag.SpecBuiltinNotSatisfied) =>
			DiagSeverity.checkError,
		(in Diag.SpecImplFoundMultiple) =>
			DiagSeverity.checkError,
		(in Diag.SpecImplNotFound) =>
			DiagSeverity.checkError,
		(in Diag.SpecImplTooDeep) =>
			DiagSeverity.checkError,
		(in Diag.SpecNameMissing) =>
			DiagSeverity.checkError,
		(in Diag.ThreadLocalError) =>
			DiagSeverity.checkError,
		(in Diag.TrustedUnnecessary) =>
			DiagSeverity.checkWarning,
		(in Diag.TypeAnnotationUnnecessary) =>
			DiagSeverity.checkWarning,
		(in Diag.TypeConflict) =>
			DiagSeverity.checkError,
		(in Diag.TypeParamCantHaveTypeArgs) =>
			DiagSeverity.checkError,
		(in Diag.TypeShouldUseSyntax) =>
			DiagSeverity.checkWarning,
		(in Diag.UnusedImport) =>
			DiagSeverity.unusedCode,
		(in Diag.UnusedLocal) =>
			DiagSeverity.unusedCode,
		(in Diag.UnusedParam) =>
			DiagSeverity.unusedCode,
		(in Diag.UnusedPrivateFun) =>
			DiagSeverity.unusedCode,
		(in Diag.UnusedPrivateSpec) =>
			DiagSeverity.unusedCode,
		(in Diag.UnusedPrivateStruct) =>
			DiagSeverity.unusedCode,
		(in Diag.UnusedPrivateStructAlias) =>
			DiagSeverity.unusedCode,
		(in Diag.VarargsParamMustBeArray) =>
			DiagSeverity.checkError,
		(in Diag.WrongNumberTypeArgsForSpec) =>
			DiagSeverity.checkError,
		(in Diag.WrongNumberTypeArgsForStruct) =>
			DiagSeverity.checkError);
