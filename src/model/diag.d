module model.diag;

@safe @nogc pure nothrow:

import frontend.lang : crowExtension;
import frontend.showDiag : ShowDiagOptions;
import model.model :
	CalledDecl,
	EnumBackingType,
	FunDecl,
	FunDeclAndTypeArgs,
	LineAndColumnGetters,
	Local,
	Module,
	Param,
	Purity,
	SpecBody,
	SpecDecl,
	SpecDeclSig,
	StructAlias,
	StructDecl,
	StructInst,
	StructOrAlias,
	Type,
	UnionMember,
	VariableRef,
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
import util.union_ : Union;
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

immutable struct Diagnostic {
	FileAndRange where;
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

	immutable struct CantCall {
		enum Reason {
			nonNoCtx,
			summon,
			unsafe,
			variadicFromNoctx,
		}

		Reason reason;
		FunDecl* callee;
	}

	immutable struct CantInferTypeArguments {
		FunDecl* callee;
	}
	immutable struct CharLiteralMustBeOneChar {}
	immutable struct CommonFunDuplicate {
		Sym name;
	}
	immutable struct CommonFunMissing {
		SpecDeclSig expectedSig;
	}
	immutable struct CommonTypeMissing {
		Sym name;
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
		enum Reason { hasSpecs, hasTypeParams, missingLibraryName, variadic }
		FunDecl* fun;
		Reason reason;
	}
	immutable struct ExternHasTypeParams {}
	immutable struct ExternRecordImplicitlyByVal {
		StructDecl* struct_;
	}
	immutable struct ExternUnion {}
	immutable struct FunMissingBody {}
	immutable struct FunModifierConflict {
		Sym modifier0;
		Sym modifier1;
	}
	immutable struct FunModifierRedundant {
		Sym modifier;
		// This is implied by the first modifier
		Sym redundantModifier;
	}
	immutable struct FunModifierTrustedOnNonExtern {}
	immutable struct IfNeedsOpt {
		Type actualType;
	}
	immutable struct ImportRefersToNothing {
		Sym name;
	}
	immutable struct LambdaCantInferParamTypes {}
	immutable struct LambdaClosesOverMut {
		Sym name;
		// If missing, the error is that the local itself is 'mut'.
		// If present, the error is that the type is 'mut'.
		Opt!Type type;
	}
	immutable struct LambdaWrongNumberParams {
		StructInst* expectedLambdaType;
		size_t actualNParams;
	}
	immutable struct LinkageWorseThanContainingFun {
		FunDecl* containingFun;
		Type referencedType;
		// empty for return type
		Opt!(Param*) param;
	}
	immutable struct LinkageWorseThanContainingType {
		StructDecl* containingType;
		Type referencedType;
	}
	immutable struct LiteralOverflow {
		StructInst* type;
	}
	immutable struct LocalNotMutable {
		VariableRef local;
	}
	immutable struct LoopNeedsBreakOrContinue {}
	immutable struct LoopWithoutBreak {}
	immutable struct MatchCaseNamesDoNotMatch {
		Sym[] expectedNames;
	}
	immutable struct MatchCaseShouldHaveLocal {
		UnionMember* member;
	}
	immutable struct MatchCaseShouldNotHaveLocal {
		UnionMember* member;
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
	immutable struct MutFieldNotAllowed {
		enum Reason {
			recordIsNotMut,
			recordIsForcedByVal,
		}
		Reason reason;
	}
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
	immutable struct PuritySpecifierRedundant {
		Purity purity;
		TypeKind typeKind;
	}
	immutable struct RecordNewVisibilityIsRedundant {
		Visibility visibility;
	}
	immutable struct SendFunDoesNotReturnFut {
		Type actualReturnType;
	}
	immutable struct SpecBuiltinNotSatisfied {
		SpecBody.Builtin.Kind kind;
		Type type;
		FunDecl* called;
	}
	immutable struct SpecImplFoundMultiple {
		Sym sigName;
		CalledDecl[] matches;
	}
	immutable struct SpecImplNotFound {
		SpecDeclSig sig;
		FunDeclAndTypeArgs[] trace;
	}
	immutable struct SpecImplTooDeep {
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
		Type[] expected;
		Type actual;
	}
	immutable struct TypeParamCantHaveTypeArgs {}
	immutable struct TypeShouldUseSyntax {
		enum Kind {
			dict,
			future,
			list,
			mutDict,
			mutList,
			mutPointer,
			opt,
			pair,
			pointer,
		}
		Kind kind;
	}
	immutable struct UnusedImport {
		Module* importedModule;
		Opt!Sym importedName;
	}
	immutable struct UnusedLocal {
		Local* local;
		bool usedGet;
		bool usedSet;
	}
	immutable struct UnusedParam {
		Param* param;
	}
	immutable struct UnusedPrivateFun {
		FunDecl* fun;
	}
	immutable struct UnusedPrivateSpec {
		SpecDecl* spec;
	}
	immutable struct UnusedPrivateStruct {
		StructDecl* struct_;
	}
	immutable struct UnusedPrivateStructAlias {
		StructAlias* alias_;
	}
	immutable struct VarargsParamMustBeArray {}
	immutable struct WrongNumberTypeArgsForSpec {
		SpecDecl* decl;
		size_t nExpectedTypeArgs;
		size_t nActualTypeArgs;
	}
	immutable struct WrongNumberTypeArgsForStruct {
		StructOrAlias decl;
		size_t nExpectedTypeArgs;
		size_t nActualTypeArgs;
	}

	mixin Union!(
		BuiltinUnsupported,
		CallMultipleMatches,
		CallNoMatch,
		CantCall,
		CantInferTypeArguments,
		CharLiteralMustBeOneChar,
		CommonFunDuplicate,
		CommonFunMissing,
		CommonTypeMissing,
		DuplicateDeclaration,
		DuplicateExports,
		DuplicateImports,
		EnumBackingTypeInvalid,
		EnumDuplicateValue,
		EnumMemberOverflows,
		ExpectedTypeIsNotALambda,
		ExternFunForbidden,
		ExternHasTypeParams,
		ExternRecordImplicitlyByVal,
		ExternUnion,
		FunMissingBody,
		FunModifierConflict,
		FunModifierRedundant,
		FunModifierTrustedOnNonExtern,
		IfNeedsOpt,
		ImportRefersToNothing,
		LambdaCantInferParamTypes,
		LambdaClosesOverMut,
		LambdaWrongNumberParams,
		LinkageWorseThanContainingFun,
		LinkageWorseThanContainingType,
		LiteralOverflow,
		LocalNotMutable,
		LoopNeedsBreakOrContinue,
		LoopWithoutBreak,
		MatchCaseNamesDoNotMatch,
		MatchCaseShouldHaveLocal,
		MatchCaseShouldNotHaveLocal,
		MatchOnNonUnion,
		ModifierConflict,
		ModifierDuplicate,
		ModifierInvalid,
		MutFieldNotAllowed,
		NameNotFound,
		NeedsExpectedType,
		ParamNotMutable,
		ParseDiag,
		PtrIsUnsafe,
		PtrMutToConst,
		PtrUnsupported,
		PurityWorseThanParent,
		PuritySpecifierRedundant,
		RecordNewVisibilityIsRedundant,
		SendFunDoesNotReturnFut,
		SpecBuiltinNotSatisfied,
		SpecImplFoundMultiple,
		SpecImplNotFound,
		SpecImplTooDeep,
		SpecNameMissing,
		SpecRecursion,
		ThreadLocalError,
		TrustedUnnecessary,
		TypeAnnotationUnnecessary,
		TypeConflict,
		TypeParamCantHaveTypeArgs,
		TypeShouldUseSyntax,
		UnusedImport,
		UnusedLocal,
		UnusedParam,
		UnusedPrivateFun,
		UnusedPrivateSpec,
		UnusedPrivateStruct,
		UnusedPrivateStructAlias,
		VarargsParamMustBeArray,
		WrongNumberTypeArgsForSpec,
		WrongNumberTypeArgsForStruct);
}

immutable struct FilesInfo {
	FilePaths filePaths;
	PathToFile pathToFile;
	LineAndColumnGetters lineAndColumnGetters;
}

FilesInfo filesInfoForSingle(ref Alloc alloc, Path path, LineAndColumnGetter lineAndColumnGetter) =>
	FilesInfo(
		fullIndexDictOfArr!(FileIndex, Path)(arrLiteral!Path(alloc, [path])),
		dictLiteral!(Path, FileIndex)(alloc, path, FileIndex(0)),
		fullIndexDictOfArr!(FileIndex, LineAndColumnGetter)(
			arrLiteral!LineAndColumnGetter(alloc, [lineAndColumnGetter])));

void writeFileAndRange(
	ref Writer writer,
	in AllPaths allPaths,
	in PathsInfo pathsInfo,
	in ShowDiagOptions options,
	in FilesInfo fi,
	in FileAndRange where,
) {
	writeFileNoResetWriter(writer, allPaths, pathsInfo, options, fi, where.fileIndex);
	if (where.fileIndex != FileIndex.none)
		writeRangeWithinFile(writer, fi.lineAndColumnGetters[where.fileIndex], where.range);
	if (options.color)
		writeReset(writer);
}

void writeFileAndPos(
	ref Writer writer,
	in AllPaths allPaths,
	in PathsInfo pathsInfo,
	in ShowDiagOptions options,
	in FilesInfo fi,
	in FileAndPos where,
) {
	writeFileNoResetWriter(writer, allPaths, pathsInfo, options, fi, where.fileIndex);
	if (where.fileIndex != FileIndex.none)
		writePos(writer, fi.lineAndColumnGetters[where.fileIndex], where.pos);
	if (options.color)
		writeReset(writer);
}

void writeFile(ref Writer writer, in AllPaths allPaths, in PathsInfo pathsInfo, in FilesInfo fi, FileIndex fileIndex) {
	ShowDiagOptions noColor = ShowDiagOptions(false);
	writeFileNoResetWriter(writer, allPaths, pathsInfo, noColor, fi, fileIndex);
	// No need to reset writer since we didn't use color
}

private void writeFileNoResetWriter(
	ref Writer writer,
	in AllPaths allPaths,
	in PathsInfo pathsInfo,
	in ShowDiagOptions options,
	in FilesInfo fi,
	FileIndex fileIndex,
) {
	if (options.color)
		writeBold(writer);
	if (fileIndex == FileIndex.none) {
		writer ~= "<generated code> ";
	} else {
		Path path = fi.filePaths[fileIndex];
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
