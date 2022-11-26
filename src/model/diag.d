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
	extern_,
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
	struct CommonFunDuplicate {
		immutable Sym name;
	}
	struct CommonFunMissing {
		immutable SpecDeclSig expectedSig;
	}
	struct CommonTypeMissing {
		immutable Sym name;
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
	struct ExternHasTypeParams {}
	struct ExternRecordImplicitlyByVal {
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
		// If missing, the error is that the local itself is 'mut'.
		// If present, the error is that the type is 'mut'.
		immutable Opt!Type type;
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
		immutable VariableRef local;
	}
	struct LoopNeedsBreakOrContinue {}
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
	struct NeedsExpectedType {
		enum Kind {
			loop,
			pointer,
			throw_,
		}
		immutable Kind kind;
	}
	struct ParamNotMutable {}
	struct PtrIsUnsafe {}
	struct PtrMutToConst {
		enum Kind { field, local }
		immutable Kind kind;
	}
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
	struct SpecImplNotFound {
		immutable SpecDeclSig sig;
		immutable FunDeclAndTypeArgs[] trace;
	}
	struct SpecImplTooDeep {
		immutable FunDeclAndTypeArgs[] trace;
	}
	struct ThreadLocalError {
		immutable FunDecl* fun;
		enum Kind { hasParams, hasSpecs, hasTypeParams, mustReturnPtrMut }
		immutable Kind kind;
	}
	struct TypeAnnotationUnnecessary {
		immutable Type type;
	}
	struct TypeConflict {
		immutable Type[] expected;
		immutable Type actual;
	}
	struct TypeParamCantHaveTypeArgs {}
	struct TypeShouldUseSyntax {
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
		FunModifierTypeArgs,
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
		ThreadLocalError,
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
		WrongNumberTypeArgsForSpec,
		WrongNumberTypeArgsForStruct);
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
