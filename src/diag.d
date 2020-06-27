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
	struct CommonTypesMissing {}
	struct CreateArrNoExpectedType {}
	struct CreateRecordByRefNoCtx {
		immutable Ptr!StructDecl strukt;
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
			strukt,
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
		immutable FunDecl* called;
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
	@trusted this(immutable CallMultipleMatches a) { kind = Kind.callMultipleMatches; callMultipleMatches = a; }
	@trusted this(immutable CallNoMatch a) { kind = Kind.callNoMatch; callNoMatch = a; }
	@trusted this(immutable CantCall a) { kind = Kind.cantCall; cantCall = a; }
	@trusted this(immutable CantCreateNonRecordType a) { kind = Kind.cantCreateNonRecordType; cantCreateNonRecordType = a; }
	@trusted this(immutable CantCreateRecordWithoutExpectedType a) { kind = Kind.cantCreateRecordWithoutExpectedType; cantCreateRecordWithoutExpectedType = a; }
	@trusted this(immutable CantInferTypeArguments a) { kind = Kind.cantInferTypeArguments; cantInferTypeArguments = a; }
	@trusted this(immutable CircularImport a) { kind = Kind.circularImport; circularImport = a; }
	@trusted this(immutable CommonTypesMissing a) { kind = Kind.commonTypesMissing; commonTypesMissing = a; }
	@trusted this(immutable CreateArrNoExpectedType a) { kind = Kind.createArrNoExpectedType; createArrNoExpectedType = a; }
	@trusted this(immutable CreateRecordByRefNoCtx a) { kind = Kind.createRecordByRefNoCtx; createRecordByRefNoCtx = a; }
	@trusted this(immutable CreateRecordMultiLineWrongFields a) { kind = Kind.createRecordMultiLineWrongFields; createRecordMultiLineWrongFields = a; }
	@trusted this(immutable DuplicateDeclaration a) { kind = Kind.duplicateDeclaration; duplicateDeclaration = a; }
	@trusted this(immutable DuplicateImports a) { kind = Kind.duplicateImports; duplicateImports = a; }
	@trusted this(immutable ExpectedTypeIsNotALambda a) { kind = Kind.expectedTypeIsNotALambda; expectedTypeIsNotALambda = a; }
	@trusted this(immutable FileDoesNotExist a) { kind = Kind.fileDoesNotExist; fileDoesNotExist = a; }
	@trusted this(immutable LambdaCantInferParamTypes a) { kind = Kind.lambdaCantInferParamTypes; lambdaCantInferParamTypes = a; }
	@trusted this(immutable LambdaClosesOverMut a) { kind = Kind.lambdaClosesOverMut; lambdaClosesOverMut = a; }
	@trusted this(immutable LambdaForFunPtrHasClosure a) { kind = Kind.lambdaForFunPtrHasClosure; lambdaForFunPtrHasClosure = a; }
	@trusted this(immutable LocalShadowsPrevious a) { kind = Kind.localShadowsPrevious; localShadowsPrevious = a; }
	@trusted this(immutable MatchCaseStructNamesDoNotMatch a) { kind = Kind.matchCaseStructNamesDoNotMatch; matchCaseStructNamesDoNotMatch = a; }
	@trusted this(immutable MatchOnNonUnion a) { kind = Kind.matchOnNonUnion; matchOnNonUnion = a; }
	@trusted this(immutable MutFieldNotAllowed a) { kind = Kind.mutFieldNotAllowed; mutFieldNotAllowed = a; }
	@trusted this(immutable NameNotFound a) { kind = Kind.nameNotFound; nameNotFound = a; }
	@trusted this(immutable ParamShadowsPrevious a) { kind = Kind.paramShadowsPrevious; paramShadowsPrevious = a; }
	@trusted this(immutable ParseDiag a) { kind = Kind.parseDiag; parseDiag = a; }
	@trusted this(immutable PurityOfFieldWorseThanRecord a) { kind = Kind.purityOfFieldWorseThanRecord; purityOfFieldWorseThanRecord = a; }
	@trusted this(immutable PurityOfMemberWorseThanUnion a) { kind = Kind.purityOfMemberWorseThanUnion; purityOfMemberWorseThanUnion = a; }
	@trusted this(immutable RelativeImportReachesPastRoot a) { kind = Kind.relativeImportReachesPastRoot; relativeImportReachesPastRoot = a; }
	@trusted this(immutable SendFunDoesNotReturnFut a) { kind = Kind.sendFunDoesNotReturnFut; sendFunDoesNotReturnFut = a; }
	@trusted this(immutable SpecBuiltinNotSatisfied a) { kind = Kind.specBuiltinNotSatisfied; specBuiltinNotSatisfied = a; }
	@trusted this(immutable SpecImplHasSpecs a) { kind = Kind.specImplHasSpecs; specImplHasSpecs = a; }
	@trusted this(immutable SpecImplNotFound a) { kind = Kind.specImplNotFound; specImplNotFound = a; }
	@trusted this(immutable TypeConflict a) { kind = Kind.typeConflict; typeConflict = a; }
	@trusted this(immutable TypeNotSendable a) { kind = Kind.typeNotSendable; typeNotSendable = a; }
	@trusted this(immutable WriteToNonExistentField a) { kind = Kind.writeToNonExistentField; writeToNonExistentField = a; }
	@trusted this(immutable WriteToNonMutableField a) { kind = Kind.writeToNonMutableField; writeToNonMutableField = a; }
	@trusted this(immutable WrongNumberNewStructArgs a) { kind = Kind.wrongNumberNewStructArgs; wrongNumberNewStructArgs = a; }
	@trusted this(immutable WrongNumberTypeArgsForSpec a) { kind = Kind.wrongNumberTypeArgsForSpec; wrongNumberTypeArgsForSpec = a; }
	@trusted this(immutable WrongNumberTypeArgsForStruct a) { kind = Kind.wrongNumberTypeArgsForStruct; wrongNumberTypeArgsForStruct = a; }
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
