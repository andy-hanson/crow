module frontend.getDiagnosticSeverity;

@safe @nogc pure nothrow:

import model.diag : Diag, DiagnosticSeverity, ReadFileDiag;
import model.parseDiag : ParseDiag;

DiagnosticSeverity getDiagnosticSeverity(in Diag a) =>
	a.matchIn!DiagnosticSeverity(
		(in Diag.AssignmentNotAllowed) =>
			DiagnosticSeverity.checkError,
		(in Diag.BuiltinUnsupported) =>
			DiagnosticSeverity.checkError,
		(in Diag.CallMultipleMatches) =>
			DiagnosticSeverity.checkError,
		(in Diag.CallNoMatch) =>
			DiagnosticSeverity.checkError,
		(in Diag.CallShouldUseSyntax) =>
			DiagnosticSeverity.checkWarning,
		(in Diag.CantCall) =>
			DiagnosticSeverity.checkError,
		(in Diag.CharLiteralMustBeOneChar) =>
			DiagnosticSeverity.checkError,
		(in Diag.CommonFunDuplicate) =>
			DiagnosticSeverity.checkError,
		(in Diag.CommonFunMissing) =>
			DiagnosticSeverity.commonMissing,
		(in Diag.CommonTypeMissing) =>
			DiagnosticSeverity.commonMissing,
		(in Diag.DestructureTypeMismatch) =>
			DiagnosticSeverity.checkError,
		(in Diag.DuplicateDeclaration) =>
			DiagnosticSeverity.checkError,
		(in Diag.DuplicateExports) =>
			DiagnosticSeverity.checkError,
		(in Diag.DuplicateImports) =>
			DiagnosticSeverity.checkError,
		(in Diag.EnumBackingTypeInvalid) =>
			DiagnosticSeverity.checkError,
		(in Diag.EnumDuplicateValue) =>
			DiagnosticSeverity.checkError,
		(in Diag.EnumMemberOverflows) =>
			DiagnosticSeverity.checkError,
		(in Diag.ExpectedTypeIsNotALambda) =>
			DiagnosticSeverity.checkError,
		(in Diag.ExternFunForbidden) =>
			DiagnosticSeverity.checkError,
		(in Diag.ExternHasTypeParams) =>
			DiagnosticSeverity.checkError,
		(in Diag.ExternMissingLibraryName) =>
			DiagnosticSeverity.checkError,
		(in Diag.ExternRecordImplicitlyByVal) =>
			DiagnosticSeverity.checkError,
		(in Diag.ExternUnion) =>
			DiagnosticSeverity.checkError,
		(in Diag.FunMissingBody) =>
			DiagnosticSeverity.checkError,
		(in FunModifierTrustedOnNonExtern) =>
			DiagnosticSeverity.checkError,
		(in FunPointerNotSupported) =>
			DiagnosticSeverity.checkError,
		(in Diag.IfNeedsOpt) =>
			DiagnosticSeverity.checkError,
		(in Diag.ImportFileDiag) =>
			DiagnosticSeverity.importError,
		(in Diag.ImportRefersToNothing) =>
			DiagnosticSeverity.nameNotFound,
		(in Diag.LambdaCantBeFunctionPointer) =>
			DiagnosticSeverity.checkError,
		(in Diag.LambdaCantInferParamType) =>
			DiagnosticSeverity.checkError,
		(in Diag.LambdaClosesOverMut) =>
			DiagnosticSeverity.checkError,
		(in Diag.LambdaMultipleMatch) =>
			DiagnosticSeverity.checkError,
		(in Diag.LambdaNotExpected) =>
			DiagnosticSeverity.checkError,
		(in Diag.LinkageWorseThanContainingFun) =>
			DiagnosticSeverity.checkError,
		(in Diag.LinkageWorseThanContainingType) =>
			DiagnosticSeverity.checkError,
		(in Diag.LiteralAmbiguous) =>
			DiagnosticSeverity.checkError,
		(in Diag.LiteralOverflow) =>
			DiagnosticSeverity.checkError,
		(in Diag.LocalIgnoredButMutable) =>
			DiagnosticSeverity.checkWarning,
		(in Diag.LocalNotMutable) =>
			DiagnosticSeverity.checkError,
		(in Diag.LoopWithoutBreak) =>
			DiagnosticSeverity.checkWarning,
		(in Diag.MatchCaseNamesDoNotMatch) =>
			DiagnosticSeverity.checkError,
		(in Diag.MatchOnNonUnion) =>
			DiagnosticSeverity.checkError,
		(in Diag.ModifierConflict) =>
			DiagnosticSeverity.checkError,
		(in Diag.ModifierDuplicate) =>
			DiagnosticSeverity.checkWarning,
		(in Diag.ModifierInvalid) =>
			DiagnosticSeverity.checkError,
		(in Diag.ModifierRedundantDueToModifier) =>
			DiagnosticSeverity.checkWarning,
		(in Diag.ModifierRedundantDueToTypeKind) =>
			DiagnosticSeverity.checkWarning,
		(in Diag.MutFieldNotAllowed) =>
			DiagnosticSeverity.checkError,
		(in Diag.NameNotFound) =>
			DiagnosticSeverity.nameNotFound,
		(in Diag.NeedsExpectedType) =>
			DiagnosticSeverity.checkError,
		(in Diag.ParamMissingType) =>
			DiagnosticSeverity.checkError,
		(in ParseDiag x) =>
			x.isA!ReadFileDiag ? DiagnosticSeverity.importError : DiagnosticSeverity.parseError,
		(in Diag.PointerIsUnsafe) =>
			DiagnosticSeverity.checkError,
		(in Diag.PointerMutToConst) =>
			DiagnosticSeverity.checkError,
		(in Diag.PointerUnsupported) =>
			DiagnosticSeverity.checkError,
		(in Diag.PurityWorseThanParent) =>
			DiagnosticSeverity.checkError,
		(in Diag.SpecMatchError) =>
			DiagnosticSeverity.checkError,
		(in Diag.SpecNoMatch) =>
			DiagnosticSeverity.checkError,
		(in Diag.SpecNameMissing) =>
			DiagnosticSeverity.checkError,
		(in Diag.SpecRecursion) =>
			DiagnosticSeverity.checkError,
		(in Diag.StringLiteralInvalid) =>
			DiagnosticSeverity.checkError,
		(in Diag.TrustedUnnecessary) =>
			DiagnosticSeverity.checkWarning,
		(in Diag.TypeAnnotationUnnecessary) =>
			DiagnosticSeverity.checkWarning,
		(in Diag.TypeConflict) =>
			DiagnosticSeverity.checkError,
		(in Diag.TypeParamCantHaveTypeArgs) =>
			DiagnosticSeverity.checkError,
		(in Diag.TypeShouldUseSyntax) =>
			DiagnosticSeverity.checkWarning,
		(in Diag.Unused) =>
			DiagnosticSeverity.unusedCode,
		(in Diag.VarargsParamMustBeArray) =>
			DiagnosticSeverity.checkError,
		(in Diag.VarDeclTypeParams) =>
			DiagnosticSeverity.checkError,
		(in Diag.VisibilityIsRedundant) =>
			DiagnosticSeverity.unusedCode,
		(in Diag.WrongNumberTypeArgs) =>
			DiagnosticSeverity.checkError);
