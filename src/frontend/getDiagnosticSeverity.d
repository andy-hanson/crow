module frontend.getDiagnosticSeverity;

@safe @nogc pure nothrow:

import model.diag : Diag, DiagSeverity, matchDiag;
import model.parseDiag : ParseDiag;

immutable(DiagSeverity) getDiagnosticSeverity(ref immutable Diag a) {
	return matchDiag!(immutable DiagSeverity)(
		a,
		(ref immutable Diag.BuiltinUnsupported) =>
			DiagSeverity.checkError,
		(ref immutable Diag.CallMultipleMatches) =>
			DiagSeverity.checkError,
		(ref immutable Diag.CallNoMatch) =>
			DiagSeverity.checkError,
		(ref immutable Diag.CantCall) =>
			DiagSeverity.checkError,
		(ref immutable Diag.CantInferTypeArguments) =>
			DiagSeverity.checkError,
		(ref immutable Diag.CharLiteralMustBeOneChar) =>
			DiagSeverity.checkError,
		(ref immutable Diag.CommonFunMissing) =>
			DiagSeverity.checkError,
		(ref immutable Diag.CommonTypesMissing) =>
			DiagSeverity.checkError,
		(ref immutable Diag.DuplicateDeclaration) =>
			DiagSeverity.checkError,
		(ref immutable Diag.DuplicateExports) =>
			DiagSeverity.checkError,
		(ref immutable Diag.DuplicateImports) =>
			DiagSeverity.checkError,
		(ref immutable Diag.EnumBackingTypeInvalid) =>
			DiagSeverity.checkError,
		(ref immutable Diag.EnumDuplicateValue) =>
			DiagSeverity.checkError,
		(ref immutable Diag.EnumMemberOverflows) =>
			DiagSeverity.checkError,
		(ref immutable Diag.ExpectedTypeIsNotALambda) =>
			DiagSeverity.checkError,
		(ref immutable Diag.ExternFunForbidden) =>
			DiagSeverity.checkError,
		(ref immutable Diag.ExternPtrHasTypeParams) =>
			DiagSeverity.checkError,
		(ref immutable Diag.ExternRecordMustBeByRefOrVal) =>
			DiagSeverity.checkError,
		(ref immutable Diag.ExternUnion) =>
			DiagSeverity.checkError,
		(ref immutable Diag.IfNeedsOpt) =>
			DiagSeverity.checkError,
		(ref immutable Diag.ImportRefersToNothing) =>
			DiagSeverity.nameNotFound,
		(ref immutable Diag.LambdaCantInferParamTypes) =>
			DiagSeverity.checkError,
		(ref immutable Diag.LambdaClosesOverMut) =>
			DiagSeverity.checkError,
		(ref immutable Diag.LambdaWrongNumberParams) =>
			DiagSeverity.checkError,
		(ref immutable Diag.LinkageWorseThanContainingFun) =>
			DiagSeverity.checkError,
		(ref immutable Diag.LinkageWorseThanContainingType) =>
			DiagSeverity.checkError,
		(ref immutable Diag.LiteralOverflow) =>
			DiagSeverity.checkError,
		(ref immutable Diag.LocalNotMutable) =>
			DiagSeverity.checkWarning,
		(ref immutable Diag.LoopBreakNotAtTail) =>
			DiagSeverity.checkError,
		(ref immutable Diag.LoopNeedsBreakOrContinue) =>
			DiagSeverity.checkError,
		(ref immutable Diag.LoopNeedsExpectedType) =>
			DiagSeverity.checkError,
		(ref immutable Diag.LoopWithoutBreak) =>
			DiagSeverity.checkWarning,
		(ref immutable Diag.MatchCaseNamesDoNotMatch) =>
			DiagSeverity.checkError,
		(ref immutable Diag.MatchCaseShouldHaveLocal) =>
			DiagSeverity.checkWarning,
		(ref immutable Diag.MatchCaseShouldNotHaveLocal) =>
			DiagSeverity.checkError,
		(ref immutable Diag.MatchOnNonUnion) =>
			DiagSeverity.checkError,
		(ref immutable Diag.ModifierConflict) =>
			DiagSeverity.checkError,
		(ref immutable Diag.ModifierDuplicate) =>
			DiagSeverity.checkWarning,
		(ref immutable Diag.ModifierInvalid) =>
			DiagSeverity.checkError,
		(ref immutable Diag.MutFieldNotAllowed) =>
			DiagSeverity.checkError,
		(ref immutable Diag.NameNotFound) =>
			DiagSeverity.nameNotFound,
		(ref immutable(ParseDiag)) =>
			DiagSeverity.parseError,
		(ref immutable Diag.PurityWorseThanParent) =>
			DiagSeverity.checkError,
		(ref immutable Diag.PuritySpecifierRedundant) =>
			DiagSeverity.checkWarning,
		(ref immutable Diag.RecordNewVisibilityIsRedundant) =>
			DiagSeverity.checkWarning,
		(ref immutable Diag.SendFunDoesNotReturnFut) =>
			DiagSeverity.checkError,
		(ref immutable Diag.SpecBuiltinNotSatisfied) =>
			DiagSeverity.checkError,
		(ref immutable Diag.SpecImplFoundMultiple) =>
			DiagSeverity.checkError,
		(ref immutable Diag.SpecImplHasSpecs) =>
			DiagSeverity.checkError,
		(ref immutable Diag.SpecImplNotFound) =>
			DiagSeverity.checkError,
		(ref immutable Diag.ThrowNeedsExpectedType) =>
			DiagSeverity.checkError,
		(ref immutable Diag.TypeAnnotationUnnecessary) =>
			DiagSeverity.checkWarning,
		(ref immutable Diag.TypeConflict) =>
			DiagSeverity.checkError,
		(ref immutable Diag.TypeParamCantHaveTypeArgs) =>
			DiagSeverity.checkError,
		(ref immutable Diag.TypeShouldUseSyntax) =>
			DiagSeverity.checkWarning,
		(ref immutable Diag.UnusedImport) =>
			DiagSeverity.unusedCode,
		(ref immutable Diag.UnusedLocal) =>
			DiagSeverity.unusedCode,
		(ref immutable Diag.UnusedParam) =>
			DiagSeverity.unusedCode,
		(ref immutable Diag.UnusedPrivateFun) =>
			DiagSeverity.unusedCode,
		(ref immutable Diag.UnusedPrivateSpec) =>
			DiagSeverity.unusedCode,
		(ref immutable Diag.UnusedPrivateStruct) =>
			DiagSeverity.unusedCode,
		(ref immutable Diag.UnusedPrivateStructAlias) =>
			DiagSeverity.unusedCode,
		(ref immutable Diag.WrongNumberTypeArgsForSpec) =>
			DiagSeverity.checkError,
		(ref immutable Diag.WrongNumberTypeArgsForStruct) =>
			DiagSeverity.checkError);
}

