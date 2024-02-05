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
			DiagnosticSeverity.warning,
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
		(in Diag.ExternFunVariadic) =>
			DiagnosticSeverity.checkError,
		(in Diag.ExternHasUnnecessaryLibraryName) =>
			DiagnosticSeverity.warning,
		(in Diag.ExternMissingLibraryName) =>
			DiagnosticSeverity.checkError,
		(in Diag.ExternRecordImplicitlyByVal) =>
			DiagnosticSeverity.checkError,
		(in Diag.ExternTypeError) =>
			DiagnosticSeverity.checkError,
		(in Diag.ExternUnion) =>
			DiagnosticSeverity.checkError,
		(in Diag.FunCantHaveBody) =>
			DiagnosticSeverity.checkError,
		(in Diag.FunMissingBody) =>
			DiagnosticSeverity.checkError,
		(in Diag.FunModifierTrustedOnNonExtern) =>
			DiagnosticSeverity.checkError,
		(in Diag.FunPointerExprMustBeName) =>
			DiagnosticSeverity.checkError,
		(in Diag.FunPointerNotSupported) =>
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
		(in Diag.LambdaClosurePurity) =>
			DiagnosticSeverity.checkError,
		(in Diag.LambdaMultipleMatch) =>
			DiagnosticSeverity.checkError,
		(in Diag.LambdaNotExpected) =>
			DiagnosticSeverity.checkError,
		(in Diag.LambdaTypeMissingParamType) =>
			DiagnosticSeverity.parseError,
		(in Diag.LambdaTypeVariadic) =>
			DiagnosticSeverity.checkError,
		(in Diag.LinkageWorseThanContainingFun) =>
			DiagnosticSeverity.checkError,
		(in Diag.LinkageWorseThanContainingType) =>
			DiagnosticSeverity.checkError,
		(in Diag.LiteralMultipleMatch) =>
			DiagnosticSeverity.checkError,
		(in Diag.LiteralNotExpected) =>
			DiagnosticSeverity.checkError,
		(in Diag.LiteralOverflow) =>
			DiagnosticSeverity.checkError,
		(in Diag.LocalIgnoredButMutable) =>
			DiagnosticSeverity.warning,
		(in Diag.LocalNotMutable) =>
			DiagnosticSeverity.checkError,
		(in Diag.LoopWithoutBreak) =>
			DiagnosticSeverity.warning,
		(in Diag.MatchCaseNamesDoNotMatch) =>
			DiagnosticSeverity.checkError,
		(in Diag.MatchCaseNoValueForEnum) =>
			DiagnosticSeverity.checkError,
		(in Diag.MatchCaseShouldUseIgnore) =>
			DiagnosticSeverity.warning,
		(in Diag.MatchOnNonEnumOrUnion) =>
			DiagnosticSeverity.checkError,
		(in Diag.ModifierConflict) =>
			DiagnosticSeverity.checkError,
		(in Diag.ModifierDuplicate) =>
			DiagnosticSeverity.warning,
		(in Diag.ModifierInvalid) =>
			DiagnosticSeverity.checkError,
		(in Diag.ModifierRedundantDueToDeclKind) =>
			DiagnosticSeverity.warning,
		(in Diag.ModifierRedundantDueToModifier) =>
			DiagnosticSeverity.warning,
		(in Diag.MutFieldNotAllowed) =>
			DiagnosticSeverity.checkError,
		(in Diag.NameNotFound) =>
			DiagnosticSeverity.nameNotFound,
		(in Diag.NeedsExpectedType) =>
			DiagnosticSeverity.checkError,
		(in Diag.ParamMissingType) =>
			DiagnosticSeverity.checkError,
		(in ParseDiag x) =>
			parseDiagSeverity(x),
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
		(in Diag.SpecRecursion) =>
			DiagnosticSeverity.checkError,
		(in Diag.SpecSigCantBeVariadic) =>
			DiagnosticSeverity.checkError,
		(in Diag.SpecUseInvalid) =>
			DiagnosticSeverity.checkError,
		(in Diag.StringLiteralInvalid) =>
			DiagnosticSeverity.checkError,
		(in Diag.TrustedUnnecessary) =>
			DiagnosticSeverity.warning,
		(in Diag.TypeAnnotationUnnecessary) =>
			DiagnosticSeverity.warning,
		(in Diag.TypeConflict) =>
			DiagnosticSeverity.checkError,
		(in Diag.TypeParamCantHaveTypeArgs) =>
			DiagnosticSeverity.checkError,
		(in Diag.TypeParamsUnsupported) =>
			DiagnosticSeverity.checkError,
		(in Diag.TypeShouldUseSyntax) =>
			DiagnosticSeverity.warning,
		(in Diag.Unused) =>
			DiagnosticSeverity.unusedCode,
		(in Diag.VarargsParamMustBeArray) =>
			DiagnosticSeverity.checkError,
		(in Diag.VisibilityWarning) =>
			DiagnosticSeverity.unusedCode,
		(in Diag.WithHasElse) =>
			DiagnosticSeverity.checkError,
		(in Diag.WrongNumberTypeArgs) =>
			DiagnosticSeverity.checkError);

private:

DiagnosticSeverity parseDiagSeverity(in ParseDiag a) =>
	a.matchIn!DiagnosticSeverity(
		(in ParseDiag.Expected) =>
			DiagnosticSeverity.parseError,
		(in ParseDiag.ImportFileTypeNotSupported) =>
			DiagnosticSeverity.parseError,
		(in ParseDiag.IndentNotDivisible) =>
			DiagnosticSeverity.parseError,
		(in ParseDiag.IndentTooMuch) =>
			DiagnosticSeverity.parseError,
		(in ParseDiag.IndentWrongCharacter) =>
			DiagnosticSeverity.parseError,
		(in ParseDiag.InvalidStringEscape) =>
			DiagnosticSeverity.warning,
		(in ParseDiag.MissingExpression) =>
			DiagnosticSeverity.parseError,
		(in ParseDiag.NeedsBlockCtx) =>
			DiagnosticSeverity.parseError,
		(in ReadFileDiag _) =>
			DiagnosticSeverity.importError,
		(in ParseDiag.TrailingComma) =>
			DiagnosticSeverity.warning,
		(in ParseDiag.TypeEmptyParens) =>
			DiagnosticSeverity.parseError,
		(in ParseDiag.TypeUnnecessaryParens) =>
			DiagnosticSeverity.warning,
		(in ParseDiag.UnexpectedCharacter) =>
			DiagnosticSeverity.parseError,
		(in ParseDiag.UnexpectedOperator) =>
			DiagnosticSeverity.parseError,
		(in ParseDiag.UnexpectedToken) =>
			DiagnosticSeverity.parseError);
