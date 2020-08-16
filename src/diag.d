module diag;

@safe @nogc pure nothrow:

import model :
	AbsolutePathsGetter,
	CalledDecl,
	ClosureField,
	FunDecl,
	LineAndColumnGetters,
	RecordField,
	SpecBody,
	SpecDecl,
	StructDecl,
	StructInst,
	StructOrAlias,
	Type;
import parseDiag : ParseDiag;
import util.collection.arr : Arr, empty;
import util.collection.str : Str;
import util.opt : Opt;
import util.path : PathAndStorageKind, RelPath;
import util.ptr : Ptr;
import util.sourceRange : SourceRange;
import util.sym : Sym;

struct Diag {
	@safe @nogc pure nothrow:

	// Note: this error is issued *before* resolving specs.
	// We don't exclude a candidate based on not having specs.
	struct CallMultipleMatches {
		immutable Sym funName;
		// Unlike CallNoMatch, these are only the ones that match
		immutable Arr!CalledDecl matches;
	}

	struct CallNoMatch {
		immutable Sym funName;
		immutable Opt!Type expectedReturnType;
		// 0 for inferred type args
		immutable size_t actualNTypeArgs;
		immutable size_t actualArity;
		// NOTE: we may have given up early and this may not be as much as actualArity
		immutable Arr!Type actualArgTypes;
		// All candidates, including those with wrong arity
		immutable Arr!CalledDecl allCandidates;
	}

	struct CantCall {
		enum Reason {
			nonNoCtx,
			summon,
			unsafe,
		}

		immutable Reason reason;
		immutable Ptr!FunDecl callee;
		immutable Ptr!FunDecl caller;
	}

	struct CantCreateNonRecordType {
		immutable Type type;
	}

	struct CantCreateRecordWithoutExpectedType {}
	struct CantInferTypeArguments {}
	struct CircularImport {
		immutable PathAndStorageKind from;
		immutable PathAndStorageKind to;
	}
	struct CommonTypesMissing {
		immutable Arr!Str missing;
	}
	struct CreateArrNoExpectedType {}
	struct CreateRecordByRefNoCtx {
		immutable Ptr!StructDecl struct_;
	}
	struct CreateRecordMultiLineWrongFields {
		immutable Ptr!StructDecl decl;
		immutable Arr!RecordField fields;
		immutable Arr!Sym providedFieldNames;
	}
	struct DuplicateDeclaration {
		enum Kind {
			structOrAlias,
			spec,
			field,
			unionMember,
		}
		immutable Kind kind;
		immutable Sym name;
	}
	struct DuplicateImports {
		enum Kind {
			structOrAlias,
			spec,
		}
		immutable Kind kind;
		immutable Sym name;
	}
	struct ExpectedTypeIsNotALambda {
		immutable Opt!Type expectedType;
	}
	struct FileDoesNotExist {
		enum Kind {
			root,
			import_,
		}
		immutable Kind kind;
		immutable PathAndStorageKind path;
	}
	struct LambdaCantInferParamTypes {}
	struct LambdaClosesOverMut {
		immutable Ptr!ClosureField field;
	}
	struct LambdaForFunPtrHasClosure {
		immutable Ptr!ClosureField field;
	}
	struct LambdaWrongNumberParams {
		immutable Ptr!StructInst expectedLambdaType;
		immutable size_t actualNParams;
	}
	struct LocalShadowsPrevious {
		immutable Sym name;
	}
	struct MatchCaseStructNamesDoNotMatch {
		immutable Arr!(Ptr!StructInst) unionMembers;
	}
	struct MatchOnNonUnion {
		immutable Type type;
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
			struct_,
			spec,
			typeParam,
		}
		immutable Kind kind;
		immutable Sym name;
	}
	struct ParamShadowsPrevious {
		enum Kind {
			param,
			typeParam,
		}
		immutable Kind kind;
		immutable Sym name;
	}
	struct PurityOfFieldWorseThanRecord {
		immutable Ptr!StructDecl strukt;
		immutable Type fieldType;
	}
	struct PurityOfMemberWorseThanUnion {
		immutable Ptr!StructDecl strukt;
		immutable Ptr!StructInst member;
	}
	struct RelativeImportReachesPastRoot {
		immutable RelPath imported;
	}
	struct SendFunDoesNotReturnFut {
		immutable Type actualReturnType;
	}
	struct SpecBuiltinNotSatisfied {
		immutable SpecBody.Builtin.Kind kind;
		immutable Type type;
		immutable Ptr!FunDecl called;
	}
	struct SpecImplNotFound {
		immutable Sym sigName;
	}
	struct SpecImplHasSpecs {
		immutable Sym funName;
	}
	struct TypeConflict {
		immutable Type expected;
		immutable Type actual;
	}
	struct TypeNotSendable {}
	struct WriteToNonExistentField {
		// Type of `x` in `x.y := z`
		immutable Type targetType;
		// `y` in `x.y := z`
		immutable Sym fieldName;
	}
	struct WriteToNonMutableField {
		immutable Ptr!RecordField field;
	}
	struct WrongNumberNewStructArgs {
		immutable Ptr!StructDecl decl;
		immutable size_t nExpectedArgs;
		immutable size_t nActualArgs;
	}
	struct WrongNumberTypeArgsForSpec {
		immutable Ptr!SpecDecl decl;
		immutable size_t nExpectedTypeArgs;
		immutable size_t nActualTypeArgs;
	}
	struct WrongNumberTypeArgsForStruct {
		immutable StructOrAlias decl;
		immutable size_t nExpectedTypeArgs;
		immutable size_t nActualTypeArgs;
	}

	private:
	enum Kind {
		callMultipleMatches,
		callNoMatch,
		cantCall,
		cantCreateNonRecordType,
		cantCreateRecordWithoutExpectedType,
		cantInferTypeArguments,
		circularImport,
		commonTypesMissing,
		createArrNoExpectedType,
		createRecordByRefNoCtx,
		createRecordMultiLineWrongFields,
		duplicateDeclaration,
		duplicateImports,
		expectedTypeIsNotALambda,
		fileDoesNotExist,
		lambdaCantInferParamTypes,
		lambdaClosesOverMut,
		lambdaForFunPtrHasClosure,
		lambdaWrongNumberParams,
		localShadowsPrevious,
		matchCaseStructNamesDoNotMatch,
		matchOnNonUnion,
		mutFieldNotAllowed,
		nameNotFound,
		paramShadowsPrevious,
		parseDiag,
		purityOfFieldWorseThanRecord,
		purityOfMemberWorseThanUnion,
		relativeImportReachesPastRoot,
		sendFunDoesNotReturnFut,
		specBuiltinNotSatisfied,
		specImplHasSpecs,
		specImplNotFound,
		typeConflict,
		typeNotSendable,
		writeToNonExistentField,
		writeToNonMutableField,
		wrongNumberNewStructArgs,
		wrongNumberTypeArgsForSpec,
		wrongNumberTypeArgsForStruct,
	}

	immutable Kind kind;
	union {
		immutable CallMultipleMatches callMultipleMatches;
		immutable CallNoMatch callNoMatch;
		immutable CantCall cantCall;
		immutable CantCreateNonRecordType cantCreateNonRecordType;
		immutable CantCreateRecordWithoutExpectedType cantCreateRecordWithoutExpectedType;
		immutable CantInferTypeArguments cantInferTypeArguments;
		immutable CircularImport circularImport;
		immutable CommonTypesMissing commonTypesMissing;
		immutable CreateArrNoExpectedType createArrNoExpectedType;
		immutable CreateRecordByRefNoCtx createRecordByRefNoCtx;
		immutable CreateRecordMultiLineWrongFields createRecordMultiLineWrongFields;
		immutable DuplicateDeclaration duplicateDeclaration;
		immutable DuplicateImports duplicateImports;
		immutable ExpectedTypeIsNotALambda expectedTypeIsNotALambda;
		immutable FileDoesNotExist fileDoesNotExist;
		immutable LambdaCantInferParamTypes lambdaCantInferParamTypes;
		immutable LambdaClosesOverMut lambdaClosesOverMut;
		immutable LambdaForFunPtrHasClosure lambdaForFunPtrHasClosure;
		immutable LambdaWrongNumberParams lambdaWrongNumberParams;
		immutable LocalShadowsPrevious localShadowsPrevious;
		immutable MatchCaseStructNamesDoNotMatch matchCaseStructNamesDoNotMatch;
		immutable MatchOnNonUnion matchOnNonUnion;
		immutable MutFieldNotAllowed mutFieldNotAllowed;
		immutable NameNotFound nameNotFound;
		immutable ParamShadowsPrevious paramShadowsPrevious;
		immutable ParseDiag parseDiag;
		immutable PurityOfFieldWorseThanRecord purityOfFieldWorseThanRecord;
		immutable PurityOfMemberWorseThanUnion purityOfMemberWorseThanUnion;
		immutable RelativeImportReachesPastRoot relativeImportReachesPastRoot;
		immutable SendFunDoesNotReturnFut sendFunDoesNotReturnFut;
		immutable SpecBuiltinNotSatisfied specBuiltinNotSatisfied;
		immutable SpecImplHasSpecs specImplHasSpecs;
		immutable SpecImplNotFound specImplNotFound;
		immutable TypeConflict typeConflict;
		immutable TypeNotSendable typeNotSendable;
		immutable WriteToNonExistentField writeToNonExistentField;
		immutable WriteToNonMutableField writeToNonMutableField;
		immutable WrongNumberNewStructArgs wrongNumberNewStructArgs;
		immutable WrongNumberTypeArgsForSpec wrongNumberTypeArgsForSpec;
		immutable WrongNumberTypeArgsForStruct wrongNumberTypeArgsForStruct;
	}

	public:
	@trusted immutable this(immutable CallMultipleMatches a) { kind = Kind.callMultipleMatches; callMultipleMatches = a; }
	@trusted immutable this(immutable CallNoMatch a) { kind = Kind.callNoMatch; callNoMatch = a; }
	@trusted immutable this(immutable CantCall a) { kind = Kind.cantCall; cantCall = a; }
	@trusted immutable this(immutable CantCreateNonRecordType a) { kind = Kind.cantCreateNonRecordType; cantCreateNonRecordType = a; }
	@trusted immutable this(immutable CantCreateRecordWithoutExpectedType a) { kind = Kind.cantCreateRecordWithoutExpectedType; cantCreateRecordWithoutExpectedType = a; }
	@trusted immutable this(immutable CantInferTypeArguments a) { kind = Kind.cantInferTypeArguments; cantInferTypeArguments = a; }
	@trusted immutable this(immutable CircularImport a) { kind = Kind.circularImport; circularImport = a; }
	@trusted immutable this(immutable CommonTypesMissing a) { kind = Kind.commonTypesMissing; commonTypesMissing = a; }
	@trusted immutable this(immutable CreateArrNoExpectedType a) { kind = Kind.createArrNoExpectedType; createArrNoExpectedType = a; }
	@trusted immutable this(immutable CreateRecordByRefNoCtx a) { kind = Kind.createRecordByRefNoCtx; createRecordByRefNoCtx = a; }
	@trusted immutable this(immutable CreateRecordMultiLineWrongFields a) { kind = Kind.createRecordMultiLineWrongFields; createRecordMultiLineWrongFields = a; }
	@trusted immutable this(immutable DuplicateDeclaration a) { kind = Kind.duplicateDeclaration; duplicateDeclaration = a; }
	@trusted immutable this(immutable DuplicateImports a) { kind = Kind.duplicateImports; duplicateImports = a; }
	@trusted immutable this(immutable ExpectedTypeIsNotALambda a) { kind = Kind.expectedTypeIsNotALambda; expectedTypeIsNotALambda = a; }
	@trusted immutable this(immutable FileDoesNotExist a) { kind = Kind.fileDoesNotExist; fileDoesNotExist = a; }
	@trusted immutable this(immutable LambdaCantInferParamTypes a) { kind = Kind.lambdaCantInferParamTypes; lambdaCantInferParamTypes = a; }
	@trusted immutable this(immutable LambdaClosesOverMut a) { kind = Kind.lambdaClosesOverMut; lambdaClosesOverMut = a; }
	@trusted immutable this(immutable LambdaForFunPtrHasClosure a) { kind = Kind.lambdaForFunPtrHasClosure; lambdaForFunPtrHasClosure = a; }
	@trusted immutable this(immutable LambdaWrongNumberParams a) { kind = Kind.lambdaWrongNumberParams; lambdaWrongNumberParams = a; }
	@trusted immutable this(immutable LocalShadowsPrevious a) { kind = Kind.localShadowsPrevious; localShadowsPrevious = a; }
	@trusted immutable this(immutable MatchCaseStructNamesDoNotMatch a) { kind = Kind.matchCaseStructNamesDoNotMatch; matchCaseStructNamesDoNotMatch = a; }
	@trusted immutable this(immutable MatchOnNonUnion a) { kind = Kind.matchOnNonUnion; matchOnNonUnion = a; }
	@trusted immutable this(immutable MutFieldNotAllowed a) { kind = Kind.mutFieldNotAllowed; mutFieldNotAllowed = a; }
	@trusted immutable this(immutable NameNotFound a) { kind = Kind.nameNotFound; nameNotFound = a; }
	@trusted immutable this(immutable ParamShadowsPrevious a) { kind = Kind.paramShadowsPrevious; paramShadowsPrevious = a; }
	@trusted immutable this(immutable ParseDiag a) { kind = Kind.parseDiag; parseDiag = a; }
	@trusted immutable this(immutable PurityOfFieldWorseThanRecord a) { kind = Kind.purityOfFieldWorseThanRecord; purityOfFieldWorseThanRecord = a; }
	@trusted immutable this(immutable PurityOfMemberWorseThanUnion a) { kind = Kind.purityOfMemberWorseThanUnion; purityOfMemberWorseThanUnion = a; }
	@trusted immutable this(immutable RelativeImportReachesPastRoot a) { kind = Kind.relativeImportReachesPastRoot; relativeImportReachesPastRoot = a; }
	@trusted immutable this(immutable SendFunDoesNotReturnFut a) { kind = Kind.sendFunDoesNotReturnFut; sendFunDoesNotReturnFut = a; }
	@trusted immutable this(immutable SpecBuiltinNotSatisfied a) { kind = Kind.specBuiltinNotSatisfied; specBuiltinNotSatisfied = a; }
	@trusted immutable this(immutable SpecImplHasSpecs a) { kind = Kind.specImplHasSpecs; specImplHasSpecs = a; }
	@trusted immutable this(immutable SpecImplNotFound a) { kind = Kind.specImplNotFound; specImplNotFound = a; }
	@trusted immutable this(immutable TypeConflict a) { kind = Kind.typeConflict; typeConflict = a; }
	@trusted immutable this(immutable TypeNotSendable a) { kind = Kind.typeNotSendable; typeNotSendable = a; }
	@trusted immutable this(immutable WriteToNonExistentField a) { kind = Kind.writeToNonExistentField; writeToNonExistentField = a; }
	@trusted immutable this(immutable WriteToNonMutableField a) { kind = Kind.writeToNonMutableField; writeToNonMutableField = a; }
	@trusted immutable this(immutable WrongNumberNewStructArgs a) { kind = Kind.wrongNumberNewStructArgs; wrongNumberNewStructArgs = a; }
	@trusted immutable this(immutable WrongNumberTypeArgsForSpec a) { kind = Kind.wrongNumberTypeArgsForSpec; wrongNumberTypeArgsForSpec = a; }
	@trusted immutable this(immutable WrongNumberTypeArgsForStruct a) { kind = Kind.wrongNumberTypeArgsForStruct; wrongNumberTypeArgsForStruct = a; }
}


@trusted immutable(Out) matchDiag(Out)(
	immutable Diag a,
	scope immutable(Out) delegate(ref immutable Diag.CallMultipleMatches) @safe @nogc pure nothrow cbCallMultipleMatches,
	scope immutable(Out) delegate(ref immutable Diag.CallNoMatch) @safe @nogc pure nothrow cbCallNoMatch,
	scope immutable(Out) delegate(ref immutable Diag.CantCall) @safe @nogc pure nothrow cbCantCall,
	scope immutable(Out) delegate(ref immutable Diag.CantCreateNonRecordType) @safe @nogc pure nothrow cbCantCreateNonRecordType,
	scope immutable(Out) delegate(ref immutable Diag.CantCreateRecordWithoutExpectedType) @safe @nogc pure nothrow cbCantCreateRecordWithoutExpectedType,
	scope immutable(Out) delegate(ref immutable Diag.CantInferTypeArguments) @safe @nogc pure nothrow cbCantInferTypeArguments,
	scope immutable(Out) delegate(ref immutable Diag.CircularImport) @safe @nogc pure nothrow cbCircularImport,
	scope immutable(Out) delegate(ref immutable Diag.CommonTypesMissing) @safe @nogc pure nothrow cbCommonTypesMissing,
	scope immutable(Out) delegate(ref immutable Diag.CreateArrNoExpectedType) @safe @nogc pure nothrow cbCreateArrNoExpectedType,
	scope immutable(Out) delegate(ref immutable Diag.CreateRecordByRefNoCtx) @safe @nogc pure nothrow cbCreateRecordByRefNoCtx,
	scope immutable(Out) delegate(ref immutable Diag.CreateRecordMultiLineWrongFields) @safe @nogc pure nothrow cbCreateRecordMultiLineWrongFields,
	scope immutable(Out) delegate(ref immutable Diag.DuplicateDeclaration) @safe @nogc pure nothrow cbDuplicateDeclaration,
	scope immutable(Out) delegate(ref immutable Diag.DuplicateImports) @safe @nogc pure nothrow cbDuplicateImports,
	scope immutable(Out) delegate(ref immutable Diag.ExpectedTypeIsNotALambda) @safe @nogc pure nothrow cbExpectedTypeIsNotALambda,
	scope immutable(Out) delegate(ref immutable Diag.FileDoesNotExist) @safe @nogc pure nothrow cbFileDoesNotExist,
	scope immutable(Out) delegate(ref immutable Diag.LambdaCantInferParamTypes) @safe @nogc pure nothrow cbLambdaCantInferParamTypes,
	scope immutable(Out) delegate(ref immutable Diag.LambdaClosesOverMut) @safe @nogc pure nothrow cbLambdaClosesOverMut,
	scope immutable(Out) delegate(ref immutable Diag.LambdaForFunPtrHasClosure) @safe @nogc pure nothrow cbLambdaForFunPtrHasClosure,
	scope immutable(Out) delegate(ref immutable Diag.LambdaWrongNumberParams) @safe @nogc pure nothrow cbLambdaWrongNumberParams,
	scope immutable(Out) delegate(ref immutable Diag.LocalShadowsPrevious) @safe @nogc pure nothrow cbLocalShadowsPrevious,
	scope immutable(Out) delegate(ref immutable Diag.MatchCaseStructNamesDoNotMatch) @safe @nogc pure nothrow cbMatchCaseStructNamesDoNotMatch,
	scope immutable(Out) delegate(ref immutable Diag.MatchOnNonUnion) @safe @nogc pure nothrow cbMatchOnNonUnion,
	scope immutable(Out) delegate(ref immutable Diag.MutFieldNotAllowed) @safe @nogc pure nothrow cbMutFieldNotAllowed,
	scope immutable(Out) delegate(ref immutable Diag.NameNotFound) @safe @nogc pure nothrow cbNameNotFound,
	scope immutable(Out) delegate(ref immutable Diag.ParamShadowsPrevious) @safe @nogc pure nothrow cbParamShadowsPrevious,
	scope immutable(Out) delegate(ref immutable ParseDiag) @safe @nogc pure nothrow cbParseDiag,
	scope immutable(Out) delegate(ref immutable Diag.PurityOfFieldWorseThanRecord) @safe @nogc pure nothrow cbPurityOfFieldWorseThanRecord,
	scope immutable(Out) delegate(ref immutable Diag.PurityOfMemberWorseThanUnion) @safe @nogc pure nothrow cbPurityOfMemberWorseThanUnion,
	scope immutable(Out) delegate(ref immutable Diag.RelativeImportReachesPastRoot) @safe @nogc pure nothrow cbRelativeImportReachesPastRoot,
	scope immutable(Out) delegate(ref immutable Diag.SendFunDoesNotReturnFut) @safe @nogc pure nothrow cbSendFunDoesNotReturnFut,
	scope immutable(Out) delegate(ref immutable Diag.SpecBuiltinNotSatisfied) @safe @nogc pure nothrow cbSpecBuiltinNotSatisfied,
	scope immutable(Out) delegate(ref immutable Diag.SpecImplHasSpecs) @safe @nogc pure nothrow cbSpecImplHasSpecs,
	scope immutable(Out) delegate(ref immutable Diag.SpecImplNotFound) @safe @nogc pure nothrow cbSpecImplNotFound,
	scope immutable(Out) delegate(ref immutable Diag.TypeConflict) @safe @nogc pure nothrow cbTypeConflict,
	scope immutable(Out) delegate(ref immutable Diag.TypeNotSendable) @safe @nogc pure nothrow cbTypeNotSendable,
	scope immutable(Out) delegate(ref immutable Diag.WriteToNonExistentField) @safe @nogc pure nothrow cbWriteToNonExistentField,
	scope immutable(Out) delegate(ref immutable Diag.WriteToNonMutableField) @safe @nogc pure nothrow cbWriteToNonMutableField,
	scope immutable(Out) delegate(ref immutable Diag.WrongNumberNewStructArgs) @safe @nogc pure nothrow cbWrongNumberNewStructArgs,
	scope immutable(Out) delegate(ref immutable Diag.WrongNumberTypeArgsForSpec) @safe @nogc pure nothrow cbWrongNumberTypeArgsForSpec,
	scope immutable(Out) delegate(ref immutable Diag.WrongNumberTypeArgsForStruct) @safe @nogc pure nothrow cbWrongNumberTypeArgsForStruct,
) {
	final switch (a.kind) {
		case Diag.Kind.callMultipleMatches:
			return cbCallMultipleMatches(a.callMultipleMatches);
		case Diag.Kind.callNoMatch:
			return cbCallNoMatch(a.callNoMatch);
		case Diag.Kind.cantCall:
			return cbCantCall(a.cantCall);
		case Diag.Kind.cantCreateNonRecordType:
			return cbCantCreateNonRecordType(a.cantCreateNonRecordType);
		case Diag.Kind.cantCreateRecordWithoutExpectedType:
			return cbCantCreateRecordWithoutExpectedType(a.cantCreateRecordWithoutExpectedType);
		case Diag.Kind.cantInferTypeArguments:
			return cbCantInferTypeArguments(a.cantInferTypeArguments);
		case Diag.Kind.circularImport:
			return cbCircularImport(a.circularImport);
		case Diag.Kind.commonTypesMissing:
			return cbCommonTypesMissing(a.commonTypesMissing);
		case Diag.Kind.createArrNoExpectedType:
			return cbCreateArrNoExpectedType(a.createArrNoExpectedType);
		case Diag.Kind.createRecordByRefNoCtx:
			return cbCreateRecordByRefNoCtx(a.createRecordByRefNoCtx);
		case Diag.Kind.createRecordMultiLineWrongFields:
			return cbCreateRecordMultiLineWrongFields(a.createRecordMultiLineWrongFields);
		case Diag.Kind.duplicateDeclaration:
			return cbDuplicateDeclaration(a.duplicateDeclaration);
		case Diag.Kind.duplicateImports:
			return cbDuplicateImports(a.duplicateImports);
		case Diag.Kind.expectedTypeIsNotALambda:
			return cbExpectedTypeIsNotALambda(a.expectedTypeIsNotALambda);
		case Diag.Kind.fileDoesNotExist:
			return cbFileDoesNotExist(a.fileDoesNotExist);
		case Diag.Kind.lambdaCantInferParamTypes:
			return cbLambdaCantInferParamTypes(a.lambdaCantInferParamTypes);
		case Diag.Kind.lambdaClosesOverMut:
			return cbLambdaClosesOverMut(a.lambdaClosesOverMut);
		case Diag.Kind.lambdaForFunPtrHasClosure:
			return cbLambdaForFunPtrHasClosure(a.lambdaForFunPtrHasClosure);
		case Diag.Kind.lambdaWrongNumberParams:
			return cbLambdaWrongNumberParams(a.lambdaWrongNumberParams);
		case Diag.Kind.localShadowsPrevious:
			return cbLocalShadowsPrevious(a.localShadowsPrevious);
		case Diag.Kind.matchCaseStructNamesDoNotMatch:
			return cbMatchCaseStructNamesDoNotMatch(a.matchCaseStructNamesDoNotMatch);
		case Diag.Kind.matchOnNonUnion:
			return cbMatchOnNonUnion(a.matchOnNonUnion);
		case Diag.Kind.mutFieldNotAllowed:
			return cbMutFieldNotAllowed(a.mutFieldNotAllowed);
		case Diag.Kind.nameNotFound:
			return cbNameNotFound(a.nameNotFound);
		case Diag.Kind.paramShadowsPrevious:
			return cbParamShadowsPrevious(a.paramShadowsPrevious);
		case Diag.Kind.parseDiag:
			return cbParseDiag(a.parseDiag);
		case Diag.Kind.purityOfFieldWorseThanRecord:
			return cbPurityOfFieldWorseThanRecord(a.purityOfFieldWorseThanRecord);
		case Diag.Kind.purityOfMemberWorseThanUnion:
			return cbPurityOfMemberWorseThanUnion(a.purityOfMemberWorseThanUnion);
		case Diag.Kind.relativeImportReachesPastRoot:
			return cbRelativeImportReachesPastRoot(a.relativeImportReachesPastRoot);
		case Diag.Kind.sendFunDoesNotReturnFut:
			return cbSendFunDoesNotReturnFut(a.sendFunDoesNotReturnFut);
		case Diag.Kind.specBuiltinNotSatisfied:
			return cbSpecBuiltinNotSatisfied(a.specBuiltinNotSatisfied);
		case Diag.Kind.specImplHasSpecs:
			return cbSpecImplHasSpecs(a.specImplHasSpecs);
		case Diag.Kind.specImplNotFound:
			return cbSpecImplNotFound(a.specImplNotFound);
		case Diag.Kind.typeConflict:
			return cbTypeConflict(a.typeConflict);
		case Diag.Kind.typeNotSendable:
			return cbTypeNotSendable(a.typeNotSendable);
		case Diag.Kind.writeToNonExistentField:
			return cbWriteToNonExistentField(a.writeToNonExistentField);
		case Diag.Kind.writeToNonMutableField:
			return cbWriteToNonMutableField(a.writeToNonMutableField);
		case Diag.Kind.wrongNumberNewStructArgs:
			return cbWrongNumberNewStructArgs(a.wrongNumberNewStructArgs);
		case Diag.Kind.wrongNumberTypeArgsForSpec:
			return cbWrongNumberTypeArgsForSpec(a.wrongNumberTypeArgsForSpec);
		case Diag.Kind.wrongNumberTypeArgsForStruct:
			return cbWrongNumberTypeArgsForStruct(a.wrongNumberTypeArgsForStruct);
	}
}

struct PathAndStorageKindAndRange {
	immutable PathAndStorageKind pathAndStorageKind;
	immutable SourceRange range;
}

struct Diagnostic {
	immutable PathAndStorageKindAndRange where;
	immutable Diag diag;
}

struct FilesInfo {
	immutable AbsolutePathsGetter absolutePathsGetter;
	immutable LineAndColumnGetters lineAndColumnGetters;
}

alias Diags = Arr!Diagnostic;

struct Diagnostics {
	@safe @nogc pure nothrow:
	immutable Diags diagnostics;
	immutable FilesInfo filesInfo;

	this(immutable Diags d, immutable FilesInfo f) immutable {
		diagnostics = d;
		filesInfo = f;
		assert(!diagnostics.empty);
	}
}
