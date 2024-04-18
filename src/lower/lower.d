module lower.lower;

@safe @nogc pure nothrow:

import backend.builtinMath : builtinForBinaryMath, builtinForUnaryMath;
import lower.checkLowModel : checkLowProgram;
import lower.generateCallLambda : generateCallLambda;
import lower.generateMarkVisitFun : getMarkVisitForType, generateMarkVisit, MarkVisitFuns;
import lower.lowExprHelpers :
	anyPtrMutType,
	boolType,
	char8PtrConstType,
	genAbort,
	genAddPtr,
	genBitwiseNegate,
	genCall,
	genCallKind,
	genCreateRecord,
	genConstantInt32,
	genConstantNat64,
	genDerefGcPtr,
	genDrop,
	genDropSecond,
	genEnumEq,
	genEnumIntersect,
	genEnumToIntegral,
	genEnumUnion,
	genFalse,
	genIf,
	genIfKind,
	genLet,
	genLetTemp,
	genLetTempKind,
	genLocal,
	genLocalByValue,
	genLocalGet,
	genLocalSet,
	genLoopBreakKind,
	genPtrToLocal,
	genPtrCast,
	genPtrCastKind,
	genRecordFieldGet,
	genSeq,
	genSeqKind,
	genSeqThenReturnFirst,
	genSizeOf,
	genSizeOfKind,
	genTrue,
	genUnionAs,
	genUnionKind,
	genUnionKindEquals,
	genVarGet,
	genVarSet,
	genVoid,
	genWrapMulNat64,
	genWriteToPtr,
	genZeroed,
	getElementPtrTypeFromArrType,
	int32Type,
	voidType;
import model.concreteModel :
	AllConstantsConcrete,
	ArrTypeAndConstantsConcrete,
	ConcreteClosureRef,
	ConcreteExpr,
	ConcreteExprKind,
	ConcreteField,
	ConcreteFun,
	ConcreteFunBody,
	ConcreteLambdaImpl,
	ConcreteLocal,
	ConcreteLocalSource,
	ConcreteProgram,
	ConcreteStruct,
	ConcreteStructBody,
	ConcreteStructSource,
	ConcreteType,
	ConcreteVar,
	ConcreteVariableRef,
	mustBeByVal,
	name,
	PointerTypeAndConstantsConcrete,
	ReferenceKind;
import model.constant : Constant, constantZero;
import model.lowModel :
	AllConstantsLow,
	AllLowTypes,
	ArrTypeAndConstantsLow,
	asPtrGcPointee,
	asPtrRawPointee,
	ConcreteFunToLowFunIndex,
	ExternLibraries,
	ExternLibrary,
	isArray,
	isPrimitiveType,
	isTuple,
	LowExpr,
	LowExprKind,
	LowExternType,
	LowField,
	LowFun,
	LowFunBody,
	LowFunExprBody,
	LowFunIndex,
	LowFunPointerType,
	LowFunSource,
	LowLocal,
	LowLocalSource,
	LowProgram,
	LowRecord,
	LowVar,
	LowVarIndex,
	LowType,
	LowUnion,
	PointerTypeAndConstantsLow,
	PrimitiveType,
	UpdateParam;
import model.model :
	BuiltinBinary,
	BuiltinBinaryLazy,
	BuiltinBinaryMath,
	BuiltinFun,
	BuiltinTernary,
	BuiltinType,
	BuiltinUnary,
	BuiltinUnaryMath,
	ClosureReferenceKind,
	ConfigExternUris,
	EnumFunction,
	FlagsFunction,
	IntegralType,
	Local,
	Program,
	VarKind;
import model.typeLayout : isEmptyType;
import util.alloc.alloc : Alloc;
import util.col.arrayBuilder : add, ArrayBuilder, arrBuilderSize, buildArray, Builder, finish;
import util.col.array :
	emptySmallArray,
	exists,
	foldReverse,
	indexOfPointer,
	isEmpty,
	map,
	mapPointersWithIndex,
	mapWithIndex,
	mapWithIndexAndAppend,
	mapZip,
	mapZipPtrFirst,
	newArray,
	newSmallArray,
	only,
	only2,
	small,
	SmallArray,
	zipPtrFirst;
import util.col.map : KeyValuePair, makeMapWithIndex, mustGet, Map;
import util.col.mapBuilder : finishMap, mustAddToMap, MapBuilder;
import util.col.fullIndexMap : FullIndexMap, fullIndexMapOfArr, fullIndexMapSize;
import util.col.mutArr : moveToArray, MutArr, mutArrSize, push;
import util.col.mutIndexMap : mustGet, MutIndexMap, newMutIndexMap;
import util.col.mutMap : getOrAdd, moveToMap, mustAdd, mustGet, MutMap, MutMap, ValueAndDidAdd;
import util.col.mutMultiMap : add, eachKey, eachValueForKey, MutMultiMap;
import util.col.stackMap : StackMap, stackMapAdd, stackMapMustGet, withStackMap;
import util.conv : safeToUint;
import util.integralValues : IntegralValue, IntegralValues, singleIntegralValue;
import util.late : Late, late, lateGet, lateIsSet, lateSet;
import util.memory : allocate;
import util.opt : force, has, none, Opt, optIf, optOrDefault, some;
import util.perf : Perf, PerfMeasure, withMeasure;
import util.sourceRange : UriAndRange;
import util.symbol : Symbol, symbol, symbolOfEnum;
import util.union_ : Union;
import util.util : castNonScope_ref, enumConvert, ptrTrustMe, typeAs;
import versionInfo : isVersion, VersionFun;

LowProgram lower(
	scope ref Perf perf,
	ref Alloc alloc,
	in ConfigExternUris configExtern,
	ref Program program,
	ref ConcreteProgram a,
) =>
	withMeasure!(LowProgram, () => lowerInner(alloc, configExtern, program, a))(perf, alloc, PerfMeasure.lower);

private LowProgram lowerInner(
	ref Alloc alloc,
	in ConfigExternUris configExtern,
	ref Program program,
	ref ConcreteProgram a,
) {
	AllLowTypesWithCtx allTypes = getAllLowTypes(alloc, a);
	immutable FullIndexMap!(LowVarIndex, LowVar) vars = getAllLowVars(alloc, allTypes.getLowTypeCtx, a.allVars);
	AllLowFuns allFuns = getAllLowFuns(alloc, allTypes.allTypes, allTypes.getLowTypeCtx, configExtern, a, vars);
	AllConstantsLow allConstants = convertAllConstants(allTypes.getLowTypeCtx, a.allConstants);
	LowProgram res = LowProgram(
		a.version_,
		allFuns.concreteFunToLowFunIndex,
		allConstants,
		vars,
		allTypes.allTypes,
		allFuns.allLowFuns,
		allFuns.main,
		allFuns.allExternLibraries);
	checkLowProgram(program, res);
	return res;
}

private FullIndexMap!(LowVarIndex, LowVar) getAllLowVars(
	ref Alloc alloc,
	ref GetLowTypeCtx ctx,
	immutable ConcreteVar*[] vars,
) =>
	fullIndexMapOfArr!(LowVarIndex, LowVar)(map(alloc, vars, (ref immutable ConcreteVar* source) {
		LowVar.Kind kind = () {
			final switch (source.source.kind) {
				case VarKind.global:
					return has(source.source.externLibraryName)
						? LowVar.Kind.externGlobal
						: LowVar.Kind.global;
				case VarKind.threadLocal:
					assert(!has(source.source.externLibraryName));
					return LowVar.Kind.threadLocal;
			}
		}();
		return LowVar(source, kind, lowTypeFromConcreteType(ctx, source.type));
	}));

private:

AllConstantsLow convertAllConstants(ref GetLowTypeCtx ctx, ref AllConstantsConcrete a) {
	ArrTypeAndConstantsLow[] arrs = map(ctx.alloc, a.arrs, (ref ArrTypeAndConstantsConcrete it) {
		LowType arrType = lowTypeFromConcreteStruct(ctx, it.arrType);
		LowType elementType = lowTypeFromConcreteType(ctx, it.elementType);
		return ArrTypeAndConstantsLow(arrType.as!(LowType.Record), elementType, it.constants);
	});
	PointerTypeAndConstantsLow[] records = map(ctx.alloc, a.pointers, (ref PointerTypeAndConstantsConcrete it) =>
		PointerTypeAndConstantsLow(lowTypeFromConcreteStruct(ctx, it.pointeeType), it.constants));
	return AllConstantsLow(a.cStrings, arrs, records);
}

struct AllLowTypesWithCtx {
	immutable AllLowTypes allTypes;
	GetLowTypeCtx getLowTypeCtx;
}

immutable struct AllLowFuns {
	ConcreteFunToLowFunIndex concreteFunToLowFunIndex;
	FullIndexMap!(LowFunIndex, LowFun) allLowFuns;
	LowFunIndex main;
	ExternLibraries allExternLibraries;
}

struct GetLowTypeCtx {
	@safe @nogc pure nothrow:

	Alloc* allocPtr;
	immutable Map!(ConcreteStruct*, LowType) concreteStructToType;
	MutMap!(ConcreteStruct*, LowType) concreteStructToPtrType;
	MutMap!(ConcreteStruct*, LowType) concreteStructToPtrPtrType;

	ref Alloc alloc() return scope =>
		*allocPtr;
}

AllLowTypesWithCtx getAllLowTypes(ref Alloc alloc, in ConcreteProgram program) {
	MapBuilder!(ConcreteStruct*, LowType) concreteStructToTypeBuilder;
	ArrayBuilder!(ConcreteStruct*) allFunPointerSources;
	ArrayBuilder!LowExternType allExternTypes;
	ArrayBuilder!(ConcreteStruct*) allRecordSources;
	ArrayBuilder!(ConcreteStruct*) allUnionSources;

	LowType addUnion(ConcreteStruct* s) {
		uint i = safeToUint(arrBuilderSize(allUnionSources));
		add(alloc, allUnionSources, s);
		return LowType(LowType.Union(i));
	}

	foreach (ConcreteStruct* concrete; program.allStructs) {
		Opt!LowType lowType = concrete.body_.matchIn!(Opt!LowType)(
			(in ConcreteStructBody.Builtin it) {
				final switch (it.kind) {
					case BuiltinType.bool_:
						return some(LowType(PrimitiveType.bool_));
					case BuiltinType.char8:
						return some(LowType(PrimitiveType.char8));
					case BuiltinType.char32:
						return some(LowType(PrimitiveType.char32));
					case BuiltinType.float32:
						return some(LowType(PrimitiveType.float32));
					case BuiltinType.float64:
						return some(LowType(PrimitiveType.float64));
					case BuiltinType.fiberSuspension:
						return some(LowType(PrimitiveType.fiberSuspension));
					case BuiltinType.funPointer: {
						uint i = safeToUint(arrBuilderSize(allFunPointerSources));
						add(alloc, allFunPointerSources, concrete);
						return some(LowType(LowType.FunPointer(i)));
					}
					case BuiltinType.int8:
						return some(LowType(PrimitiveType.int8));
					case BuiltinType.int16:
						return some(LowType(PrimitiveType.int16));
					case BuiltinType.int32:
						return some(LowType(PrimitiveType.int32));
					case BuiltinType.int64:
						return some(LowType(PrimitiveType.int64));
					case BuiltinType.lambda:
						return some(addUnion(concrete));
					case BuiltinType.nat8:
						return some(LowType(PrimitiveType.nat8));
					case BuiltinType.nat16:
						return some(LowType(PrimitiveType.nat16));
					case BuiltinType.nat32:
						return some(LowType(PrimitiveType.nat32));
					case BuiltinType.nat64:
						return some(LowType(PrimitiveType.nat64));
					case BuiltinType.pointerConst:
					case BuiltinType.pointerMut:
						return none!LowType;
					case BuiltinType.void_:
						return some(LowType(PrimitiveType.void_));
				}
			},
			(in ConcreteStructBody.Enum x) =>
				some(LowType(typeOfIntegralType(x.storage))),
			(in ConcreteStructBody.Extern it) {
				uint i = safeToUint(arrBuilderSize(allExternTypes));
				add(alloc, allExternTypes, LowExternType(concrete));
				return some(LowType(LowType.Extern(i)));
			},
			(in ConcreteStructBody.Flags x) =>
				some(LowType(typeOfIntegralType(x.storage))),
			(in ConcreteStructBody.Record) {
				uint i = safeToUint(arrBuilderSize(allRecordSources));
				add(alloc, allRecordSources, concrete);
				return some(LowType(LowType.Record(i)));
			},
			(in ConcreteStructBody.Union) =>
				some(addUnion(concrete)));
		if (has(lowType))
			mustAddToMap(alloc, concreteStructToTypeBuilder, concrete, force(lowType));
	}

	GetLowTypeCtx getLowTypeCtx = GetLowTypeCtx(ptrTrustMe(alloc), finishMap(alloc, concreteStructToTypeBuilder));

	immutable FullIndexMap!(LowType.Record, LowRecord) allRecords =
		fullIndexMapOfArr!(LowType.Record, LowRecord)(
			map(alloc, finish(alloc, allRecordSources), (ref immutable ConcreteStruct* struct_) =>
				LowRecord(
					struct_,
					mapZipPtrFirst!(LowField, ConcreteField, immutable uint)(
						alloc,
						struct_.body_.as!(ConcreteStructBody.Record).fields,
						struct_.fieldOffsets,
						(ConcreteField* field, immutable uint fieldOffset) =>
							LowField(field, fieldOffset, lowTypeFromConcreteType(getLowTypeCtx, field.type))))));
	immutable FullIndexMap!(LowType.FunPointer, LowFunPointerType) allFunPointers =
		fullIndexMapOfArr!(LowType.FunPointer, LowFunPointerType)(
			map(alloc, finish(alloc, allFunPointerSources), (ref immutable ConcreteStruct* x) {
				ConcreteType[2] typeArgs = only2(x.body_.as!(ConcreteStructBody.Builtin*).typeArgs);
				return LowFunPointerType(
					x,
					lowTypeFromConcreteType(getLowTypeCtx, typeArgs[0]),
					maybeUnpackTuple(alloc, allRecords, lowTypeFromConcreteType(getLowTypeCtx, typeArgs[1])));
			}));
	immutable FullIndexMap!(LowType.Union, LowUnion) allUnions =
		fullIndexMapOfArr!(LowType.Union, LowUnion)(
			map(alloc, finish(alloc, allUnionSources), (ref immutable ConcreteStruct* it) =>
				getLowUnion(alloc, program, getLowTypeCtx, it)));

	return AllLowTypesWithCtx(
		AllLowTypes(
			fullIndexMapOfArr!(LowType.Extern, LowExternType)(finish(alloc, allExternTypes)),
			allFunPointers,
			allRecords,
			allUnions),
		getLowTypeCtx);
}

LowType[] maybeUnpackTuple(
	ref Alloc alloc,
	FullIndexMap!(LowType.Record, LowRecord) allRecords,
	LowType a,
) {
	Opt!(LowType[]) res = tryUnpackTuple(alloc, allRecords, a);
	return has(res) ? force(res) : newArray!LowType(alloc, [a]);
}

Opt!(LowType[]) tryUnpackTuple(
	ref Alloc alloc,
	FullIndexMap!(LowType.Record, LowRecord) allRecords,
	LowType a,
) {
	if (isPrimitiveType(a, PrimitiveType.void_))
		return some!(LowType[])([]);
	else if (a.isA!(LowType.Record)) {
		LowRecord record = allRecords[a.as!(LowType.Record)];
		return isTuple(record)
			? some(map(alloc, record.fields, (ref LowField x) => x.type))
			: none!(LowType[]);
	} else
		return none!(LowType[]);
}

PrimitiveType typeOfIntegralType(IntegralType a) =>
	enumConvert!PrimitiveType(a);

LowUnion getLowUnion(ref Alloc alloc, in ConcreteProgram program, ref GetLowTypeCtx getLowTypeCtx, ConcreteStruct* s) =>
	LowUnion(s, small!LowType(s.body_.matchIn!(LowType[])(
		(in ConcreteStructBody.Builtin x) {
			assert(x.kind == BuiltinType.lambda);
			return map(getLowTypeCtx.alloc, getLambdaImpls(program, s), (ref ConcreteLambdaImpl impl) =>
				lowTypeFromConcreteType(getLowTypeCtx, impl.closureType));
		},
		(in ConcreteStructBody.Enum) => assert(false),
		(in ConcreteStructBody.Extern) => assert(false),
		(in ConcreteStructBody.Flags) => assert(false),
		(in ConcreteStructBody.Record) => assert(false),
		(in ConcreteStructBody.Union x) =>
			map(getLowTypeCtx.alloc, x.members, (ref ConcreteType member) =>
				lowTypeFromConcreteType(getLowTypeCtx, member)))));

LowType getLowRawPtrConstType(ref GetLowTypeCtx ctx, LowType pointee) {
	//TODO:PERF Cache creation of pointer types by pointee
	return LowType(LowType.PtrRawConst(allocate(ctx.alloc, pointee)));
}

ConcreteLambdaImpl[] getLambdaImpls(in ConcreteProgram program, in ConcreteStruct* struct_) =>
	optOrDefault!(SmallArray!ConcreteLambdaImpl)(program.lambdaStructToImpls[struct_], () =>
		emptySmallArray!ConcreteLambdaImpl);

LowType getLowGcPtrType(ref GetLowTypeCtx ctx, LowType pointee) {
	//TODO:PERF Cache creation of pointer types by pointee
	return LowType(LowType.PtrGc(allocate(ctx.alloc, pointee)));
}

LowType lowTypeFromConcreteStruct(ref GetLowTypeCtx ctx, in ConcreteStruct* struct_) {
	Opt!LowType res = ctx.concreteStructToType[struct_];
	if (has(res))
		return force(res);
	else {
		ConcreteStructBody.Builtin* builtin = struct_.body_.as!(ConcreteStructBody.Builtin*);
		//TODO: cache the creation.. don't want an allocation for every BuiltinType.ptr to the same target type
		LowType* inner = allocate(ctx.alloc, lowTypeFromConcreteType(ctx, only(builtin.typeArgs)));
		switch (builtin.kind) {
			case BuiltinType.pointerConst:
				return LowType(LowType.PtrRawConst(inner));
			case BuiltinType.pointerMut:
				return LowType(LowType.PtrRawMut(inner));
			default:
				assert(false);
		}
	}
}

LowType lowTypeFromConcreteType(ref GetLowTypeCtx ctx, in ConcreteType it) {
	LowType inner = lowTypeFromConcreteStruct(ctx, it.struct_);
	LowType wrapInRef(LowType x) {
		return LowType(LowType.PtrGc(allocate(ctx.alloc, x)));
	}
	LowType byRef() {
		return getOrAdd(ctx.alloc, ctx.concreteStructToPtrType, it.struct_, () => wrapInRef(inner));
	}
	final switch (it.reference) {
		case ReferenceKind.byVal:
			return inner;
		case ReferenceKind.byRef:
			return byRef();
		case ReferenceKind.byRefRef:
			return getOrAdd(ctx.alloc, ctx.concreteStructToPtrPtrType, it.struct_, () => wrapInRef(byRef()));
	}
}

public immutable struct LowFunCause {
	immutable struct CallLambda {
		LowType funType;
		LowType returnType;
		LowType funParamType;
		ConcreteLambdaImpl[] impls;
	}
	immutable struct MarkVisit {
		LowType type;
	}
	mixin Union!(CallLambda, ConcreteFun*, MarkVisit);
}

alias MutConcreteFunToLowFunIndex = MutMap!(ConcreteFun*, LowFunIndex);

AllLowFuns getAllLowFuns(
	ref Alloc alloc,
	ref AllLowTypes allTypes,
	ref GetLowTypeCtx getLowTypeCtx,
	in ConfigExternUris configExtern,
	ref ConcreteProgram program,
	in immutable FullIndexMap!(LowVarIndex, LowVar) allVars,
) {
	MutConcreteFunToLowFunIndex concreteFunToLowFunIndex;
	MutArr!LowFunCause lowFunCauses;

	MarkVisitFuns markVisitFuns = MarkVisitFuns(
		newMutIndexMap!(LowType.Record, Opt!LowFunIndex)(getLowTypeCtx.alloc, fullIndexMapSize(allTypes.allRecords)),
		newMutIndexMap!(LowType.Union, Opt!LowFunIndex)(getLowTypeCtx.alloc, fullIndexMapSize(allTypes.allUnions)));

	Late!LowType markCtxTypeLate = late!LowType;

	MutMultiMap!(Symbol, Symbol) externLibraryToNames; // Fun and Var combined
	void addExternSymbol(Symbol libraryName, Symbol symbolName) {
		add(getLowTypeCtx.alloc, externLibraryToNames, libraryName, symbolName);
	}

	foreach (ref LowVar x; allVars) {
		Opt!Symbol libraryName = x.externLibraryName;
		if (has(libraryName))
			addExternSymbol(force(libraryName), x.name);
	}

	foreach (ConcreteFun* fun; program.allFuns) {
		Opt!LowFunIndex opIndex = fun.body_.match!(Opt!LowFunIndex)(
			(ConcreteFunBody.Builtin x) {
				if (x.kind.isA!(BuiltinFun.CallLambda)) {
					ConcreteLocal[2] params = only2(fun.paramsIncludingClosure);
					return some(addLowFun(alloc, lowFunCauses, LowFunCause(LowFunCause.CallLambda(
						lowTypeFromConcreteType(getLowTypeCtx, params[0].type),
						lowTypeFromConcreteType(getLowTypeCtx, fun.returnType),
						lowTypeFromConcreteType(getLowTypeCtx, params[1].type),
						getLambdaImpls(program, mustBeByVal(params[0].type))))));
				} else if (x.kind.isA!(BuiltinFun.MarkVisit)) {
					if (!lateIsSet(markCtxTypeLate))
						lateSet(markCtxTypeLate, lowTypeFromConcreteType(
							getLowTypeCtx,
							fun.paramsIncludingClosure[0].type));
					return getMarkVisitForType(getLowTypeCtx.alloc, lowFunCauses, markVisitFuns, allTypes, lowTypeFromConcreteType(getLowTypeCtx, only(x.typeArgs)));
				} else {
					if (!isVersion(program.version_, VersionFun.isInterpreted) &&
							(x.kind.isA!BuiltinUnaryMath || x.kind.isA!BuiltinBinaryMath))
						addExternSymbol(symbol!"m", x.kind.isA!BuiltinUnaryMath
							? symbolOfEnum(builtinForUnaryMath(x.kind.as!BuiltinUnaryMath))
							: symbolOfEnum(builtinForBinaryMath(x.kind.as!BuiltinBinaryMath)));
					return none!LowFunIndex;
				}
			},
			(Constant _) =>
				none!LowFunIndex,
			(ConcreteFunBody.CreateRecord) =>
				none!LowFunIndex,
			(ConcreteFunBody.CreateUnion) =>
				none!LowFunIndex,
			(EnumFunction _) =>
				none!LowFunIndex,
			(ConcreteFunBody.Extern x) {
				Opt!Symbol optName = name(*fun);
				addExternSymbol(x.libraryName, force(optName));
				return some(addLowFun(alloc, lowFunCauses, LowFunCause(fun)));
			},
			(ConcreteExpr _) =>
				some(addLowFun(alloc, lowFunCauses, LowFunCause(fun))),
			(ConcreteFunBody.FlagsFn) =>
				none!LowFunIndex,
			(ConcreteFunBody.RecordFieldCall) =>
				none!LowFunIndex,
			(ConcreteFunBody.RecordFieldGet) =>
				none!LowFunIndex,
			(ConcreteFunBody.RecordFieldPointer) =>
				none!LowFunIndex,
			(ConcreteFunBody.RecordFieldSet) =>
				none!LowFunIndex,
			(ConcreteFunBody.VarGet x) =>
				none!LowFunIndex,
			(ConcreteFunBody.VarSet) =>
				none!LowFunIndex);
		if (has(opIndex))
			mustAdd(getLowTypeCtx.alloc, concreteFunToLowFunIndex, fun, force(opIndex));
	}

	LowType markCtxType = lateIsSet(markCtxTypeLate) ? lateGet(markCtxTypeLate) : voidType;

	LowType userMainFunPointerType =
		lowTypeFromConcreteType(getLowTypeCtx, program.commonFuns.rtMain.paramsIncludingClosure[2].type);

	//TODO: use temp alloc
	VarIndices varIndices = makeMapWithIndex!(immutable ConcreteVar*, LowVarIndex, immutable ConcreteVar*)(
		getLowTypeCtx.alloc, program.allVars, (size_t i, in immutable ConcreteVar* x) =>
			immutable KeyValuePair!(immutable ConcreteVar*, LowVarIndex)(x, LowVarIndex(i)));

	LowCommonFuns commonFuns = LowCommonFuns(
		alloc: mustGet(concreteFunToLowFunIndex, program.commonFuns.alloc),
		curJmpBuf: mustGet(concreteFunToLowFunIndex, program.commonFuns.curJmpBuf),
		setCurJmpBuf: mustGet(concreteFunToLowFunIndex, program.commonFuns.setCurJmpBuf),
		jmpBufType: lowTypeFromConcreteType(getLowTypeCtx, program.commonFuns.curJmpBuf.returnType),
		curThrown: mustGet(varIndices, program.commonFuns.curThrown),
		exceptionType: lowTypeFromConcreteType(getLowTypeCtx, program.commonFuns.curThrown.type),
		mark: mustGet(concreteFunToLowFunIndex, program.commonFuns.mark),
		setjmp: mustGet(concreteFunToLowFunIndex, program.commonFuns.setjmp),
		rethrowCurrentException: mustGet(concreteFunToLowFunIndex, program.commonFuns.rethrowCurrentException),
		throwImpl: mustGet(concreteFunToLowFunIndex, program.commonFuns.throwImpl),
		gcRoot: mustGet(concreteFunToLowFunIndex, program.commonFuns.gcRoot),
		setGcRoot: mustGet(concreteFunToLowFunIndex, program.commonFuns.setGcRoot),
		popGcRoot: mustGet(concreteFunToLowFunIndex, program.commonFuns.popGcRoot));

	MutArr!LowFun allLowFuns;
	// New LowFuns will be discovered while compiling and added to lowFunCauses
	for (size_t index = 0; index < mutArrSize(lowFunCauses); index++) {
		push(alloc, allLowFuns, lowFunFromCause(
			allTypes,
			program.allConstants.staticSymbols,
			getLowTypeCtx,
			commonFuns,
			concreteFunToLowFunIndex,
			varIndices,
			lowFunCauses,
			markVisitFuns,
			markCtxType,
			LowFunIndex(index),
			lowFunCauses[index]));
	}
	push(alloc, allLowFuns, mainFun(
		getLowTypeCtx,
		mustGet(concreteFunToLowFunIndex, program.commonFuns.rtMain),
		program.commonFuns.userMain,
		userMainFunPointerType));

	return AllLowFuns(
		moveToMap(getLowTypeCtx.alloc, concreteFunToLowFunIndex),
		fullIndexMapOfArr!(LowFunIndex, LowFun)(moveToArray(alloc, allLowFuns)),
		LowFunIndex(mutArrSize(lowFunCauses)),
		getExternLibraries(getLowTypeCtx.alloc, externLibraryToNames, configExtern));
}

public LowFunIndex addLowFun(ref Alloc alloc, scope ref MutArr!LowFunCause lowFunCauses, LowFunCause source) {
	LowFunIndex res = LowFunIndex(mutArrSize(lowFunCauses));
	push(alloc, lowFunCauses, source);
	return res;
}

ExternLibraries getExternLibraries(
	ref Alloc alloc,
	in MutMultiMap!(Symbol, Symbol) externLibraryToNames,
	in ConfigExternUris configExtern,
) =>
	buildArray!ExternLibrary(alloc, (scope ref Builder!ExternLibrary libraries) {
		eachKey!(Symbol, Symbol)(externLibraryToNames, (in Symbol library) {
			Symbol[] names = buildArray!Symbol(alloc, (scope ref Builder!Symbol res) {
				eachValueForKey!(Symbol, Symbol)(externLibraryToNames, library, (Symbol x) {
					res ~= x;
				});
			});
			libraries ~= ExternLibrary(library, configExtern[library], names);
		});
	});

alias VarIndices = Map!(immutable ConcreteVar*, LowVarIndex);

struct LowCommonFuns {
	LowFunIndex alloc;
	LowFunIndex curJmpBuf;
	LowFunIndex setCurJmpBuf;
	LowType jmpBufType;
	LowVarIndex curThrown;
	LowType exceptionType;
	LowFunIndex mark;
	LowFunIndex rethrowCurrentException;
	LowFunIndex setjmp;
	LowFunIndex throwImpl;

	LowFunIndex gcRoot;
	LowFunIndex setGcRoot;
	LowFunIndex popGcRoot;
}

LowFun lowFunFromCause(
	ref AllLowTypes allTypes,
	in Constant staticSymbols,
	ref GetLowTypeCtx getLowTypeCtx,
	in LowCommonFuns commonFuns,
	in MutConcreteFunToLowFunIndex concreteFunToLowFunIndex,
	in VarIndices varIndices,
	scope ref MutArr!LowFunCause lowFunCauses,
	scope ref MarkVisitFuns markVisitFuns,
	LowType markCtxType,
	LowFunIndex thisFunIndex,
	LowFunCause cause,
) =>
	cause.matchWithPointers!LowFun(
		(LowFunCause.CallLambda x) =>
			generateCallLambda(getLowTypeCtx.alloc, allTypes, concreteFunToLowFunIndex, x),
		(ConcreteFun* cf) {
			LowType returnType = lowTypeFromConcreteType(getLowTypeCtx, cf.returnType);
			LowLocal[] params = mapPointersWithIndex!(LowLocal, ConcreteLocal)(
				getLowTypeCtx.alloc, cf.paramsIncludingClosure, (size_t i, ConcreteLocal* x) =>
					getLowLocalForParameter(getLowTypeCtx, i, x));
			LowFunBody body_ = getLowFunBody(
				allTypes,
				staticSymbols,
				getLowTypeCtx,
				concreteFunToLowFunIndex,
				commonFuns,
				varIndices,
				thisFunIndex,
				params,
				*cf);
			return LowFun(LowFunSource(cf), returnType, params, body_);
		},
		(LowFunCause.MarkVisit x) =>
			generateMarkVisit(getLowTypeCtx.alloc, lowFunCauses, markVisitFuns, allTypes, markCtxType, commonFuns.mark, x.type));

LowFun mainFun(ref GetLowTypeCtx ctx, LowFunIndex rtMainIndex, ConcreteFun* userMain, LowType userMainFunPointerType) {
	LowType char8PtrPtrConstType = LowType(LowType.PtrRawConst(allocate(ctx.alloc, char8PtrConstType)));
	LowLocal[] params = newArray!LowLocal(ctx.alloc, [
		genLocalByValue(ctx.alloc, symbol!"argc", 0, int32Type),
		genLocalByValue(ctx.alloc, symbol!"argv", 1, char8PtrPtrConstType)]);
	LowExpr userMainFunPointer =
		LowExpr(userMainFunPointerType, UriAndRange.empty, LowExprKind(Constant(Constant.FunPointer(userMain))));
	LowExpr call = genCall(ctx.alloc, UriAndRange.empty, rtMainIndex, int32Type, [
		genLocalGet(UriAndRange.empty, &params[0]),
		genLocalGet(UriAndRange.empty, &params[1]),
		userMainFunPointer
	]);
	LowFunBody body_ = LowFunBody(LowFunExprBody(false, call));
	return LowFun(
		LowFunSource(allocate(ctx.alloc, LowFunSource.Generated(symbol!"main", []))),
		int32Type,
		params,
		body_);
}

LowLocal getLowLocalForParameter(ref GetLowTypeCtx ctx, size_t index, ConcreteLocal* a) =>
	LowLocal(
		getLowLocalSource(ctx.alloc, a.source, () => index),
		lowTypeFromConcreteType(ctx, a.type));

LowLocalSource getLowLocalSource(ref GetLowExprCtx ctx, ConcreteLocalSource a) =>
	getLowLocalSource(ctx.alloc, a, () => nextTempLocalIndex(ctx));

LowLocalSource getLowLocalSource(
	ref Alloc alloc,
	ConcreteLocalSource a,
	scope size_t delegate() @safe @nogc pure nothrow getIndex,
) =>
	a.matchWithPointers!LowLocalSource(
		(Local* x) =>
			LowLocalSource(x),
		(ConcreteLocalSource.Closure x) =>
			LowLocalSource(allocate(alloc, LowLocalSource.Generated(symbol!"closure", getIndex()))),
		(ConcreteLocalSource.Generated x) =>
			LowLocalSource(allocate(alloc, LowLocalSource.Generated(symbolOfEnum(x), getIndex()))));

T withLowLocal(T)(
	ref GetLowExprCtx ctx,
	in Locals locals,
	ConcreteLocal* concreteLocal,
	in T delegate(in Locals, LowLocal*) @safe @nogc pure nothrow cb,
) {
	LowType typeByVal = lowTypeFromConcreteType(ctx.typeCtx, concreteLocal.type);
	LowType type = concreteLocal.isAllocated ? getLowGcPtrType(ctx.typeCtx, typeByVal) : typeByVal;
	LowLocal* local = allocate(ctx.alloc, LowLocal(getLowLocalSource(ctx, concreteLocal.source), type));
	return cb(addLocal(locals, concreteLocal, local), local);
}

LowFunBody getLowFunBody(
	in AllLowTypes allTypes,
	in Constant staticSymbols,
	ref GetLowTypeCtx getLowTypeCtx,
	in MutConcreteFunToLowFunIndex concreteFunToLowFunIndex,
	in LowCommonFuns commonFuns,
	in VarIndices varIndices,
	LowFunIndex thisFunIndex,
	LowLocal[] params,
	ref ConcreteFun a,
) =>
	a.body_.match!LowFunBody(
		(ConcreteFunBody.Builtin x) =>
			assert(false),
		(Constant _) =>
			assert(false),
		(ConcreteFunBody.CreateRecord) =>
			assert(false),
		(ConcreteFunBody.CreateUnion) =>
			assert(false),
		(EnumFunction) =>
			assert(false),
		(ConcreteFunBody.Extern x) =>
			LowFunBody(LowFunBody.Extern(x.libraryName)),
		(ConcreteExpr x) {
			GetLowExprCtx exprCtx = GetLowExprCtx(
				thisFunIndex,
				ptrTrustMe(allTypes),
				castNonScope_ref(staticSymbols),
				ptrTrustMe(getLowTypeCtx),
				ptrTrustMe(concreteFunToLowFunIndex),
				commonFuns,
				castNonScope_ref(varIndices),
				a.paramsIncludingClosure,
				params,
				false,
				a.paramsIncludingClosure.length);
			LowExpr expr = withStackMap!(LowExpr, ConcreteLocal*, LowLocal*)((ref Locals locals) =>
				getLowExpr(exprCtx, locals, x, ExprPos.tail));
			return LowFunBody(LowFunExprBody(exprCtx.hasTailRecur, expr));
		},
		(ConcreteFunBody.FlagsFn) =>
			assert(false),
		(ConcreteFunBody.RecordFieldCall) =>
			assert(false),
		(ConcreteFunBody.RecordFieldGet) =>
			assert(false),
		(ConcreteFunBody.RecordFieldPointer) =>
			assert(false),
		(ConcreteFunBody.RecordFieldSet) =>
			assert(false),
		(ConcreteFunBody.VarGet) =>
			assert(false),
		(ConcreteFunBody.VarSet) =>
			assert(false));

struct GetLowExprCtx {
	@safe @nogc pure nothrow:

	immutable LowFunIndex currentFun;
	immutable AllLowTypes* allTypes;
	immutable Constant staticSymbols;
	GetLowTypeCtx* getLowTypeCtxPtr;
	const MutConcreteFunToLowFunIndex* concreteFunToLowFunIndexPtr;
	LowCommonFuns commonFuns;
	immutable VarIndices varIndices;
	ConcreteLocal[] concreteParams;
	LowLocal[] lowParams;
	bool hasTailRecur;
	size_t tempLocalIndex;

	ref Alloc alloc() return scope =>
		typeCtx.alloc;

	ref typeCtx() return scope =>
		*getLowTypeCtxPtr;
	
	ref const(MutConcreteFunToLowFunIndex) concreteFunToLowFunIndex() return scope const =>
		*concreteFunToLowFunIndexPtr;
}

alias Locals = StackMap!(ConcreteLocal*, LowLocal*);
alias addLocal = stackMapAdd!(ConcreteLocal*, LowLocal*);
LowLocal* getLocal(ref GetLowExprCtx ctx, in Locals locals, in ConcreteLocal* local) {
	Opt!size_t paramIndex = indexOfPointer(ctx.concreteParams, local);
	return has(paramIndex) ? &ctx.lowParams[force(paramIndex)] : stackMapMustGet(castNonScope_ref(locals), local);
}

Opt!LowFunIndex tryGetLowFunIndex(in GetLowExprCtx ctx, ConcreteFun* it) =>
	ctx.concreteFunToLowFunIndex[it];

size_t nextTempLocalIndex(ref GetLowExprCtx ctx) {
	size_t res = ctx.tempLocalIndex;
	ctx.tempLocalIndex++;
	return res;
}

enum ExprPos { nonTail, tail, loop }

LowExpr getLowExpr(
	ref GetLowExprCtx ctx,
	in Locals locals,
	ref ConcreteExpr expr,
	ExprPos exprPos,
) {
	LowType type = lowTypeFromConcreteType(ctx.typeCtx, expr.type);
	return LowExpr(type, expr.range, getLowExprKind(ctx, locals, type, expr, exprPos));
}

LowExprKind getLowExprKind(
	ref GetLowExprCtx ctx,
	in Locals locals,
	LowType type,
	ref ConcreteExpr expr,
	ExprPos exprPos,
) =>
	expr.kind.match!LowExprKind(
		(ref ConcreteExprKind.Alloc it) =>
			getAllocExpr(ctx, locals, expr.range, it),
		(ConcreteExprKind.Call x) =>
			getCallExpr(ctx, locals, exprPos, expr.range, type, x.called, x.args),
		(ConcreteExprKind.ClosureCreate it) =>
			getClosureCreateExpr(ctx, locals, expr.range, type, it),
		(ref ConcreteExprKind.ClosureGet it) =>
			getClosureGetExpr(ctx, expr.range, it),
		(ref ConcreteExprKind.ClosureSet it) =>
			getClosureSetExpr(ctx, locals, expr.range, it),
		(Constant it) =>
			LowExprKind(it),
		(ConcreteExprKind.CreateArray x) =>
			getCreateArrayExpr(ctx, locals, expr.range, type, expr.type, x),
		(ConcreteExprKind.CreateRecord it) =>
			LowExprKind(LowExprKind.CreateRecord(getArgs(ctx, locals, it.args))),
		(ref ConcreteExprKind.CreateUnion it) =>
			LowExprKind(allocate(ctx.alloc, LowExprKind.CreateUnion(
				it.memberIndex,
				getLowExpr(ctx, locals, it.arg, ExprPos.nonTail)))),
		(ref ConcreteExprKind.Drop it) =>
			getDropExpr(ctx, locals, expr.range, it),
		(ref ConcreteExprKind.Finally x) =>
			getFinallyExpr(ctx, locals, expr.range, type, x),
		(ref ConcreteExprKind.If x) =>
			LowExprKind(allocate(ctx.alloc, LowExprKind.If(
				getLowExpr(ctx, locals, x.cond, ExprPos.nonTail),
				getLowExpr(ctx, locals, x.then, exprPos),
				getLowExpr(ctx, locals, x.else_, exprPos)))),
		(ConcreteExprKind.Lambda it) =>
			getLambdaExpr(ctx, locals, expr.range, it),
		(ref ConcreteExprKind.Let x) =>
			getLetExpr(ctx, locals, exprPos, expr.range, x),
		(ConcreteExprKind.LocalGet it) =>
			getLocalGetExpr(ctx, locals, type, expr.range, it),
		(ref ConcreteExprKind.LocalSet it) =>
			getLocalSetExpr(ctx, locals, expr.range, it),
		(ref ConcreteExprKind.Loop x) =>
			LowExprKind(allocate(ctx.alloc, LowExprKind.Loop(getLowExpr(ctx, locals, x.body_, ExprPos.loop)))),
		(ref ConcreteExprKind.LoopBreak x) {
			assert(exprPos == ExprPos.loop);
			return LowExprKind(allocate(ctx.alloc, LowExprKind.LoopBreak(
				getLowExpr(ctx, locals, x.value, ExprPos.nonTail))));
		},
		(ConcreteExprKind.LoopContinue) {
			assert(exprPos == ExprPos.loop);
			return LowExprKind(LowExprKind.LoopContinue());
		},
		(ref ConcreteExprKind.MatchEnumOrIntegral x) =>
			getMatchIntegralExpr(ctx, locals, exprPos, type, expr.range, x),
		(ref ConcreteExprKind.MatchStringLike x) =>
			getMatchStringLikeExpr(ctx, locals, exprPos, expr.range, x),
		(ref ConcreteExprKind.MatchUnion x) =>
			getMatchUnionExpr(ctx, locals, exprPos, type, expr.range, x),
		(ref ConcreteExprKind.PtrToField x) =>
			getPtrToFieldExpr(ctx, locals, x.target, x.fieldIndex),
		(ConcreteExprKind.PtrToLocal it) =>
			getPtrToLocalExpr(ctx, locals, expr.range, it),
		(ConcreteExprKind.RecordFieldGet x) =>
			getRecordFieldGet(ctx, locals, *x.record, x.fieldIndex),
		(ref ConcreteExprKind.Seq x) =>
			genSeqKind(
				ctx.alloc,
				getLowExpr(ctx, locals, x.first, ExprPos.nonTail),
				getLowExpr(ctx, locals, x.then, exprPos)),
		(ref ConcreteExprKind.Throw x) =>
			getThrowExpr(ctx, locals, expr.range, type, x, exprPos),
		(ref ConcreteExprKind.Try x) =>
			getTryExpr(ctx, locals, exprPos, expr.range, type, x),
		(ref ConcreteExprKind.TryLet x) =>
			getTryLetExpr(ctx, locals, exprPos, expr.range, type, x),
		(ConcreteExprKind.UnionAs x) =>
			LowExprKind(LowExprKind.UnionAs(
				allocate(ctx.alloc, getLowExpr(ctx, locals, *x.union_, ExprPos.nonTail)), x.memberIndex)),
		(ConcreteExprKind.UnionKind x) =>
			LowExprKind(LowExprKind.UnionKind(
				allocate(ctx.alloc, getLowExpr(ctx, locals, *x.union_, ExprPos.nonTail)))));

LowExpr getAllocateExpr(
	ref Alloc alloc,
	LowFunIndex allocFunIndex,
	UriAndRange range,
	LowType ptrType,
	LowExpr size,
) =>
	// TODO: ensure this will definitely be the return type of allocFunIndex
	genPtrCast(alloc, ptrType, range, genCall(alloc, range, allocFunIndex, anyPtrMutType, [size]));

LowExprKind getAllocExpr(ref GetLowExprCtx ctx, in Locals locals, UriAndRange range, ref ConcreteExprKind.Alloc a) {
	LowExpr arg = getLowExpr(ctx, locals, a.arg, ExprPos.nonTail);
	LowType ptrType = getLowGcPtrType(ctx.typeCtx, arg.type);
	return getAllocExpr2(ctx, range, arg, ptrType);
}

LowExpr getAllocExpr2Expr(ref GetLowExprCtx ctx, UriAndRange range, ref LowExpr arg, LowType ptrType) =>
	LowExpr(ptrType, range, getAllocExpr2(ctx, range, arg, ptrType));

LowExprKind getAllocExpr2(ref GetLowExprCtx ctx, UriAndRange range, ref LowExpr arg, LowType ptrType) =>
	isEmptyType(*ctx.allTypes, arg.type)
		? mayHaveSideEffects(arg)
			? genSeqKind(ctx.alloc, genDrop(ctx.alloc, range, arg), LowExpr(ptrType, range, LowExprKind(constantZero)))
			: LowExprKind(constantZero)
		// ptr = (T*) alloc(sizeof(T)); *ptr = arg; return ptr;
		: genLetTempKind(
			ctx.alloc, range, nextTempLocalIndex(ctx),
			getAllocateExpr(
				ctx.alloc, ctx.commonFuns.alloc, range, ptrType,
				genSizeOf(*ctx.allTypes, range, asPtrGcPointee(ptrType))),
			(LowExpr getPtr) => genSeq(ctx.alloc, range, genWriteToPtr(ctx.alloc, range, getPtr, arg), getPtr));

// TODO: this should probably part of the expression 'type'
bool mayHaveSideEffects(in LowExpr a) =>
	!a.kind.isA!Constant && !a.kind.isA!(LowExprKind.LocalGet) && (
		!a.kind.isA!(LowExprKind.CreateRecord) ||
		exists!LowExpr(a.kind.as!(LowExprKind.CreateRecord).args, (in LowExpr x) => mayHaveSideEffects(x)));

LowExprKind getCallExpr(
	ref GetLowExprCtx ctx,
	in Locals locals,
	ExprPos exprPos,
	UriAndRange range,
	LowType type,
	ConcreteFun* called,
	in SmallArray!ConcreteExpr args,
) {
	Opt!LowFunIndex opCalled = tryGetLowFunIndex(ctx, called);
	return has(opCalled)
		? getCallRegular(ctx, locals, exprPos, args, force(opCalled))
		: getCallSpecial(ctx, locals, exprPos, range, type, called, args);
}

LowExpr getCallEquals(
	ref GetLowExprCtx ctx,
	UriAndRange range,
	ConcreteFun* called,
	LowExpr arg0,
	LowExpr arg1,
) {
	Opt!LowFunIndex opCalled = tryGetLowFunIndex(ctx, called);
	return LowExpr(boolType, range, has(opCalled)
		? genCallKind(ctx.alloc, force(opCalled), [arg0, arg1])
		: LowExprKind(allocate(ctx.alloc, LowExprKind.SpecialBinary(
			called.body_.as!(ConcreteFunBody.Builtin).kind.as!(BuiltinBinary), [arg0, arg1]))));
}

LowExprKind getCallRegular(
	ref GetLowExprCtx ctx,
	in Locals locals,
	ExprPos exprPos,
	in SmallArray!ConcreteExpr args,
	LowFunIndex called,
) {
	if (called == ctx.currentFun && exprPos == ExprPos.tail) {
		ctx.hasTailRecur = true;
		ArrayBuilder!UpdateParam updateParams;
		zipPtrFirst(ctx.lowParams, args, (LowLocal* param, ref ConcreteExpr concreteArg) {
			LowExpr arg = getLowExpr(ctx, locals, concreteArg, ExprPos.nonTail);
			if (!(arg.kind.isA!(LowExprKind.LocalGet) && arg.kind.as!(LowExprKind.LocalGet).local == param))
				add(ctx.alloc, updateParams, UpdateParam(param, arg));
		});
		return LowExprKind(LowExprKind.TailRecur(finish(ctx.alloc, updateParams)));
	} else
		return LowExprKind(LowExprKind.Call(called, map!(LowExpr, ConcreteExpr)(ctx.alloc, args, (ref ConcreteExpr x) =>
			getLowExpr(ctx, locals, x, ExprPos.nonTail))));
}

LowExprKind getCallSpecial(
	ref GetLowExprCtx ctx,
	in Locals locals,
	ExprPos exprPos,
	UriAndRange range,
	LowType type,
	ConcreteFun* called,
	in ConcreteExpr[] args,
) =>
	called.body_.match!LowExprKind(
		(ConcreteFunBody.Builtin x) =>
			getCallBuiltinExpr(ctx, locals, exprPos, range, type, called, args, x.kind),
		(Constant x) =>
			LowExprKind(x),
		(ConcreteFunBody.CreateRecord) {
			if (isEmptyType(*ctx.allTypes, type))
				return LowExprKind(constantZero);
			else {
				LowExpr[] lowArgs = getArgs(ctx, locals, args);
				LowExprKind create = LowExprKind(LowExprKind.CreateRecord(lowArgs));
				if (type.isA!(LowType.PtrGc)) {
					LowExpr inner = LowExpr(asPtrGcPointee(type), range, create);
					return getAllocExpr2(ctx, range, inner, type);
				} else
					return create;
			}
		},
		(ConcreteFunBody.CreateUnion x) {
			LowExpr arg = isEmpty(args)
				? genVoid(range)
				: getLowExpr(ctx, locals, only(args), ExprPos.nonTail);
			return LowExprKind(allocate(ctx.alloc, LowExprKind.CreateUnion(x.memberIndex, arg)));
		},
		(EnumFunction x) =>
			genEnumFunction(ctx, locals, x, args),
		(ConcreteFunBody.Extern) =>
			assert(false),
		(ConcreteExpr _) =>
			assert(false),
		(ConcreteFunBody.FlagsFn x) {
			final switch (x.fn) {
				case FlagsFunction.all:
					return LowExprKind(Constant(IntegralValue(x.allValue)));
				case FlagsFunction.negate:
					return genFlagsNegate(
						ctx.alloc,
						range,
						x.allValue,
						getLowExpr(ctx, locals, only(args), ExprPos.nonTail));
				case FlagsFunction.new_:
					return LowExprKind(Constant(IntegralValue(0)));
			}
		},
		(ConcreteFunBody.RecordFieldCall x) =>
			getRecordFieldCall(ctx, locals, range, type, args, x),
		(ConcreteFunBody.RecordFieldGet x) =>
			getRecordFieldGet(ctx, locals, only(args), x.fieldIndex),
		(ConcreteFunBody.RecordFieldPointer x) =>
			getPtrToFieldExpr(ctx, locals, only(args), x.fieldIndex),
		(ConcreteFunBody.RecordFieldSet x) {
			assert(args.length == 2);
			return LowExprKind(allocate(ctx.alloc, LowExprKind.RecordFieldSet(
				getLowExpr(ctx, locals, args[0], ExprPos.nonTail),
				x.fieldIndex,
				getLowExpr(ctx, locals, args[1], ExprPos.nonTail))));
		},
		(ConcreteFunBody.VarGet x) =>
			LowExprKind(LowExprKind.VarGet(mustGet(ctx.varIndices, x.var))),
		(ConcreteFunBody.VarSet x) =>
			LowExprKind(LowExprKind.VarSet(
				mustGet(ctx.varIndices, x.var),
				allocate(ctx.alloc, getLowExpr(ctx, locals, only(args), ExprPos.nonTail)))));

LowExprKind getRecordFieldCall(
	ref GetLowExprCtx ctx,
	in Locals locals,
	UriAndRange range,
	LowType type,
	in ConcreteExpr[] args,
	in ConcreteFunBody.RecordFieldCall body_,
) {
	LowExpr fun = LowExpr(
		lowTypeFromConcreteStruct(ctx.typeCtx, body_.funType),
		range,
		getRecordFieldGet(ctx, locals, args[0], body_.fieldIndex));
	LowExpr arg = () {
		switch (args.length) {
			case 0:
				assert(false);
			case 1:
				return genVoid(range);
			case 2:
				return getLowExpr(ctx, locals, args[1], ExprPos.nonTail);
			default:
				return LowExpr(
					lowTypeFromConcreteType(ctx.typeCtx, body_.argType),
					range,
					LowExprKind(LowExprKind.CreateRecord(map(ctx.alloc, args[1 .. $], (ref ConcreteExpr arg) =>
						getLowExpr(ctx, locals, arg, ExprPos.nonTail)))));
		}
	}();
	ConcreteFun* caller = body_.caller;
	Opt!LowFunIndex opCalled = tryGetLowFunIndex(ctx, caller);
	if (has(opCalled))
		return genCallKind(ctx.alloc, force(opCalled), [fun, arg]);
	else {
		assert(caller.body_.as!(ConcreteFunBody.Builtin).kind.isA!(BuiltinFun.CallFunPointer));
		return callFunPointerInner(ctx, locals, range, type, fun, arg);
	}
}

LowExprKind getRecordFieldGet(ref GetLowExprCtx ctx, in Locals locals, ref ConcreteExpr record, size_t fieldIndex) =>
	LowExprKind(LowExprKind.RecordFieldGet(
		allocate(ctx.alloc, getLowExpr(ctx, locals, record, ExprPos.nonTail)),
		fieldIndex));

LowExprKind genFlagsNegate(ref Alloc alloc, UriAndRange range, ulong allValue, LowExpr a) =>
	genEnumIntersect(
		alloc,
		LowExpr(a.type, range, genBitwiseNegate(alloc, a)),
		LowExpr(a.type, range, LowExprKind(Constant(IntegralValue(allValue)))));

LowExprKind genEnumFunction(
	ref GetLowExprCtx ctx,
	in Locals locals,
	EnumFunction a,
	in ConcreteExpr[] args,
) {
	LowExpr arg0() { return getLowExpr(ctx, locals, args[0], ExprPos.nonTail); }
	LowExpr arg1() { return getLowExpr(ctx, locals, args[1], ExprPos.nonTail); }
	final switch (a) {
		case EnumFunction.equal:
			assert(args.length == 2);
			return genEnumEq(ctx.alloc, arg0(), arg1());
		case EnumFunction.intersect:
			assert(args.length == 2);
			return genEnumIntersect(ctx.alloc, arg0(), arg1());
		case EnumFunction.toIntegral:
			assert(args.length == 1);
			return genEnumToIntegral(ctx.alloc, arg0());
		case EnumFunction.union_:
			assert(args.length == 2);
			return genEnumUnion(ctx.alloc, arg0(), arg1());
		case EnumFunction.members:
			// In concretize, this was translated to a constant
			assert(false);
	}
}

LowExpr[] getArgs(ref GetLowExprCtx ctx, in Locals locals, in ConcreteExpr[] args) =>
	map(ctx.alloc, args, (ref ConcreteExpr arg) =>
		getLowExpr(ctx, locals, arg, ExprPos.nonTail));

LowExprKind callFunPointer(
	ref GetLowExprCtx ctx,
	in Locals locals,
	UriAndRange range,
	LowType type,
	ConcreteExpr[2] funPtrAndArg,
) {
	LowExpr funPtr = getLowExpr(ctx, locals, funPtrAndArg[0], ExprPos.nonTail);
	LowExpr arg = getLowExpr(ctx, locals, funPtrAndArg[1], ExprPos.nonTail);
	return callFunPointerInner(ctx, locals, range, type, funPtr, arg);
}

LowExprKind callFunPointerInner(
	ref GetLowExprCtx ctx,
	in Locals locals,
	UriAndRange range,
	LowType type,
	LowExpr funPtr,
	LowExpr arg,
) {
	LowExprKind doCall(LowExpr getFunPtr, SmallArray!LowExpr args) =>
		LowExprKind(LowExprKind.CallFunPointer(allocate(ctx.alloc, getFunPtr), args));
	LowExpr doCallExpr(LowExpr getFunPtr, SmallArray!LowExpr args) =>
		LowExpr(type, range, doCall(getFunPtr, args));
	Opt!(LowType[]) optArgTypes = tryUnpackTuple(ctx.alloc, ctx.allTypes.allRecords, arg.type);
	if (has(optArgTypes)) {
		LowType[] argTypes = force(optArgTypes);
		return arg.kind.isA!(LowExprKind.CreateRecord)
			? doCall(funPtr, small!LowExpr(arg.kind.as!(LowExprKind.CreateRecord).args))
			: argTypes.length == 0
			// Making sure the side effect order is function then arg
			? genLetTemp(ctx.alloc, range, nextTempLocalIndex(ctx), funPtr, (LowExpr getFunPointer) =>
				genSeq(ctx.alloc, range, arg, doCallExpr(getFunPointer, emptySmallArray!LowExpr))).kind
			: genLetTemp(ctx.alloc, range, nextTempLocalIndex(ctx), funPtr, (LowExpr getFunPointer) =>
				genLetTemp(ctx.alloc, range, nextTempLocalIndex(ctx), arg, (LowExpr getArg) =>
					doCallExpr(getFunPointer, mapWithIndex!(LowExpr, LowType)(
						ctx.alloc, small!LowType(argTypes), (size_t argIndex, ref LowType argType) =>
							genRecordFieldGet(ctx.alloc, range, getArg, argType, argIndex))))).kind;
	} else
		return doCall(funPtr, newSmallArray!LowExpr(ctx.alloc, [arg]));
}

LowExprKind getCallBuiltinExpr(
	ref GetLowExprCtx ctx,
	in Locals locals,
	ExprPos exprPos,
	UriAndRange range,
	LowType type,
	ConcreteFun* called,
	in ConcreteExpr[] args,
	BuiltinFun kind,
) {
	LowExpr getArg(ref ConcreteExpr arg, ExprPos argPos = ExprPos.nonTail) =>
		getLowExpr(ctx, locals, arg, argPos);
	LowExpr getArg0() =>
		getArg(args[0]);
	LowExpr getArg1() =>
		getArg(args[1]);
	return kind.match!LowExprKind(
		(BuiltinFun.AllTests) =>
			assert(false), // handled in concretize
		(BuiltinUnary kind) {
			assert(args.length == 1);
			return LowExprKind(allocate(ctx.alloc, LowExprKind.SpecialUnary(kind, getArg0)));
		},
		(BuiltinUnaryMath kind) {
			assert(args.length == 1);
			return LowExprKind(allocate(ctx.alloc, LowExprKind.SpecialUnaryMath(kind, getArg0)));
		},
		(BuiltinBinary kind) {
			assert(args.length == 2);
			return maybeOptimizeSpecialBinary(ctx, range, kind, getArg0, getArg1);
		},
		(BuiltinBinaryLazy kind) {
			assert(args.length == 2);
			return genBuiltinBinaryLazy(ctx, type, range, kind, getArg0, getArg(args[1], ExprPos.tail));
		},
		(BuiltinBinaryMath kind) {
			assert(args.length == 2);
			return LowExprKind(allocate(ctx.alloc, LowExprKind.SpecialBinaryMath(
				kind, [getArg0,getArg1])));
		},
		(BuiltinTernary kind) {
			assert(args.length == 3);
			return LowExprKind(allocate(ctx.alloc, LowExprKind.SpecialTernary(
				kind, [getArg0, getArg1, getArg(args[2])])));
		},
		(BuiltinFun.CallLambda) =>
			assert(false), // handled in concretize
		(BuiltinFun.CallFunPointer) =>
			callFunPointer(ctx, locals, range, type, only2(args)),
		(Constant it) =>
			LowExprKind(it),
		(BuiltinFun.InitConstants) =>
			LowExprKind(LowExprKind.InitConstants()),
		(BuiltinFun.MarkVisit) =>
			// Handled in concretize
			assert(false),
		(BuiltinFun.PointerCast) {
			assert(args.length == 1);
			return genPtrCastKind(ctx.alloc, getLowExpr(ctx, locals, only(args), ExprPos.nonTail));
		},
		(BuiltinFun.SizeOf) {
			LowType typeArg =
				lowTypeFromConcreteType(ctx.typeCtx, only(called.body_.as!(ConcreteFunBody.Builtin).typeArgs));
			return genSizeOfKind(*ctx.allTypes, typeArg);
		},
		(BuiltinFun.StaticSymbols) =>
			LowExprKind(ctx.staticSymbols),
		(VersionFun _) =>
			// handled in concretize
			assert(false));
}

LowExprKind maybeOptimizeSpecialBinary(
	ref GetLowExprCtx ctx,
	UriAndRange range,
	BuiltinBinary kind,
	LowExpr arg0,
	LowExpr arg1,
) {
	LowExprKind unopt() =>
		LowExprKind(allocate(ctx. alloc, LowExprKind.SpecialBinary(kind, [arg0, arg1])));

	switch (kind) {
		case BuiltinBinary.addPtrAndNat64:
			return isEmptyType(*ctx.allTypes, asPtrRawPointee(arg0.type))
				? genDropSecond(ctx.alloc, range, nextTempLocalIndex(ctx), arg0, arg1)
				: unopt();
		case BuiltinBinary.unsafeDivNat64:
			if (arg1.kind.isA!Constant) {
				ulong divisor = arg1.kind.as!Constant.as!IntegralValue.asUnsigned;
				switch (divisor) {
					case 0:
						return LowExprKind(LowExprKind.Abort());
					case 1:
						// This is not for performance but to work around a bug dividing by 1 in Mir.
						// See https://github.com/vnmakarov/mir/issues/393
						return arg0.kind;
					default:
						return unopt();
				}
			} else
				return unopt();
		default:
			return unopt();
	}
}

LowExprKind genBuiltinBinaryLazy(
	ref GetLowExprCtx ctx,
	LowType type,
	UriAndRange range,
	BuiltinBinaryLazy kind,
	LowExpr arg0,
	LowExpr arg1,
) {
	final switch (kind) {
		case BuiltinBinaryLazy.boolAnd:
			return genIfKind(ctx.alloc, arg0, arg1, genFalse(range));
		case BuiltinBinaryLazy.boolOr:
			return genIfKind(ctx.alloc, arg0, genTrue(range), arg1);
		case BuiltinBinaryLazy.optionOr:
			return genOptionOrLike(ctx, range, arg0, arg1, (LowExpr x) => x);
		case BuiltinBinaryLazy.optionQuestion2:
			return genOptionOrLike(ctx, range, arg0, arg1, (LowExpr x) =>
				genUnionAs(type, range, allocate(ctx.alloc, x), 1));
	}
}
LowExprKind genOptionOrLike(
	ref GetLowExprCtx ctx,
	UriAndRange range,
	LowExpr arg0,
	LowExpr arg1,
	in LowExpr delegate(LowExpr) @safe @nogc pure nothrow cbArg0NonEmpty,
) =>
	// x = arg0; x.kind == 1 ? cbArg0NonEmpty(x) : arg1
	genLetTempKind(ctx.alloc, range, nextTempLocalIndex(ctx), arg0, (LowExpr getArg0) =>
		genIf(ctx.alloc, range, genUnionKindEquals(ctx.alloc, range, getArg0, 1), cbArg0NonEmpty(getArg0), arg1));

LowExprKind getCreateArrayExpr(
	ref GetLowExprCtx ctx,
	in Locals locals,
	UriAndRange range,
	LowType arrType,
	ConcreteType concreteArrType,
	in ConcreteExprKind.CreateArray a,
) {
	// ptr = _alloc(ctx, sizeof(foo) * n);
	// *(ptr + 0) = a;
	// *(ptr + 1) = b;
	// ... etc ...;
	// return arr_foo{n, ptr};
	LowType elementType = lowTypeFromConcreteType(
		ctx.typeCtx,
		only(mustBeByVal(concreteArrType).source.as!(ConcreteStructSource.Inst).typeArgs));
	LowType elementPtrType = getLowRawPtrConstType(ctx.typeCtx, elementType);
	LowExpr elementSize = genSizeOf(*ctx.allTypes, range, elementType);
	LowExpr nElements = genConstantNat64(range, a.args.length);
	LowExpr sizeBytes = genWrapMulNat64(ctx.alloc, range, elementSize, nElements);
	LowExpr allocatePtr = getAllocateExpr(ctx.alloc, ctx.commonFuns.alloc, range, elementPtrType, sizeBytes);
	return genLetTempKind(ctx.alloc, range, nextTempLocalIndex(ctx), allocatePtr, (LowExpr getPtr) {
		LowExpr recur(LowExpr cur, size_t prevIndex) {
			if (prevIndex == 0)
				return cur;
			else {
				size_t index = prevIndex - 1;
				LowExpr arg = getLowExpr(ctx, locals, a.args[index], ExprPos.nonTail);
				LowExpr elementPtr = genAddPtr(
					ctx.alloc,
					elementPtrType.as!(LowType.PtrRawConst),
					range,
					getPtr,
					genConstantNat64(range, index));
				LowExpr writeToElement = genWriteToPtr(ctx.alloc, range, elementPtr, arg);
				return recur(genSeq(ctx.alloc, range, writeToElement, cur), index);
			}
		}
		return recur(genCreateRecord(ctx.alloc, arrType, range, [nElements, getPtr]), a.args.length);
	});
}

LowExprKind getDropExpr(ref GetLowExprCtx ctx, in Locals locals, UriAndRange range, ref ConcreteExprKind.Drop a) =>
	genDrop(ctx.alloc, range, getLowExpr(ctx, locals, a.arg, ExprPos.nonTail)).kind;

LowExprKind getLambdaExpr(ref GetLowExprCtx ctx, in Locals locals, UriAndRange range, in ConcreteExprKind.Lambda a) =>
	LowExprKind(allocate(ctx.alloc, LowExprKind.CreateUnion(
		a.memberIndex,
		has(a.closure)
			? getLowExpr(ctx, locals, *force(a.closure), ExprPos.nonTail)
			: genVoid(range))));

LowExprKind getLetExpr(
	ref GetLowExprCtx ctx,
	in Locals locals,
	ExprPos exprPos,
	UriAndRange range,
	ref ConcreteExprKind.Let a,
) =>
	genLetHandleAllocated(ctx, locals, exprPos, range, a.local, a.value, a.then, (LowExpr x) => x);

LowExprKind genLetHandleAllocated(
	ref GetLowExprCtx ctx,
	in Locals locals,
	ExprPos exprPos,
	UriAndRange range,
	ConcreteLocal* concreteLocal,
	ref ConcreteExpr concreteValue,
	ref ConcreteExpr concreteThen,
	in LowExpr delegate(LowExpr) @safe @nogc pure nothrow cbModifyThen,
) {
	LowExpr valueByVal = getLowExpr(ctx, locals, concreteValue, ExprPos.nonTail);
	return withLowLocal!LowExprKind(ctx, locals, concreteLocal, (in Locals innerLocals, LowLocal* local) =>
		LowExprKind(allocate(ctx.alloc, LowExprKind.Let(
			local,
			concreteLocal.isAllocated
				? getAllocExpr2Expr(ctx, range, valueByVal, getLowGcPtrType(ctx.typeCtx, valueByVal.type))
				: valueByVal,
			cbModifyThen(getLowExpr(ctx, innerLocals, concreteThen, exprPos))))));
}

LowExprKind getLocalGetExpr(
	ref GetLowExprCtx ctx,
	in Locals locals,
	LowType type,
	UriAndRange range,
	in ConcreteExprKind.LocalGet a,
) {
	LowLocal* local = getLocal(ctx, locals, a.local);
	LowExprKind localGet = LowExprKind(LowExprKind.LocalGet(local));
	return a.local.isAllocated
		? genDerefGcPtr(ctx.alloc, LowExpr(local.type, range, localGet))
		: localGet;
}

LowExprKind getPtrToLocalExpr(
	ref GetLowExprCtx ctx,
	in Locals locals,
	UriAndRange range,
	in ConcreteExprKind.PtrToLocal a,
) {
	LowLocal* local = getLocal(ctx, locals, a.local);
	return a.local.isAllocated
		? LowExprKind(allocate(ctx.alloc, LowExprKind.PtrCast(
			LowExpr(local.type, range, LowExprKind(LowExprKind.LocalGet(local))))))
		: LowExprKind(LowExprKind.PtrToLocal(local));
}

LowExprKind getLocalSetExpr(
	ref GetLowExprCtx ctx,
	in Locals locals,
	UriAndRange range,
	ref ConcreteExprKind.LocalSet a,
) {
	LowLocal* local = getLocal(ctx, locals, a.local);
	LowExpr value = getLowExpr(ctx, locals, a.value, ExprPos.nonTail);
	return a.local.isAllocated
		? genWriteToPtr(
			ctx.alloc,
			LowExpr(local.type, range, LowExprKind(LowExprKind.LocalGet(local))),
			value)
		: LowExprKind(allocate(ctx.alloc, LowExprKind.LocalSet(local, value)));
}

LowExprKind getMatchIntegralExpr(
	ref GetLowExprCtx ctx,
	in Locals locals,
	ExprPos exprPos,
	LowType type,
	UriAndRange range,
	ref ConcreteExprKind.MatchEnumOrIntegral a,
) =>
	LowExprKind(allocate(ctx.alloc, LowExprKind.Switch(
		value: getLowExpr(ctx, locals, a.matched, ExprPos.nonTail),
		caseValues: a.caseValues,
		caseExprs: map!(LowExpr, ConcreteExpr)(ctx.alloc, a.caseExprs, (ref ConcreteExpr case_) =>
			getLowExpr(ctx, locals, case_, exprPos)),
		default_: has(a.else_)
			? getLowExpr(ctx, locals, *force(a.else_), exprPos)
			: genAbort(type, range))));

LowExprKind withLetTemp(
	ref GetLowExprCtx ctx,
	in Locals locals,
	ref ConcreteExpr expr,
	in LowExpr delegate(LowExpr) @safe @nogc pure nothrow cb,
) =>
	genLetTempKind(ctx.alloc, expr.range, nextTempLocalIndex(ctx), getLowExpr(ctx, locals, expr, ExprPos.nonTail), cb);

LowExprKind getMatchStringLikeExpr(
	ref GetLowExprCtx ctx,
	in Locals locals,
	ExprPos exprPos,
	UriAndRange range,
	ref ConcreteExprKind.MatchStringLike a,
) =>
	withLetTemp(ctx, locals, a.matched, (LowExpr matched) =>
		foldReverse!(LowExpr, ConcreteExprKind.MatchStringLike.Case)(
			getLowExpr(ctx, locals, a.else_, exprPos),
			a.cases,
			(LowExpr else_, ref ConcreteExprKind.MatchStringLike.Case case_) =>
				genIf(
					ctx.alloc,
					range,
					getCallEquals(ctx, range, a.equals, matched, getLowExpr(ctx, locals, case_.value, ExprPos.nonTail)),
					getLowExpr(ctx, locals, case_.then, exprPos),
					else_)));

LowExprKind getMatchUnionExpr(
	ref GetLowExprCtx ctx,
	in Locals locals,
	ExprPos exprPos,
	LowType type,
	UriAndRange range,
	ref ConcreteExprKind.MatchUnion a,
) =>
	withLetTemp(ctx, locals, a.matched, (LowExpr getMatched) {
		LowExpr* getMatchedPtr = allocate(ctx.alloc, getMatched);
		return LowExpr(type, range, LowExprKind(allocate(ctx.alloc,
			LowExprKind.Switch(
				value: genUnionKind(range, getMatchedPtr),
				caseValues: a.memberIndices,
				caseExprs: lowerMatchCases(ctx, locals, exprPos, type, range, getMatchedPtr, a.memberIndices, a.cases),
				default_: has(a.else_)
					? getLowExpr(ctx, locals, *force(a.else_), exprPos)
					: genAbort(type, range)))));
	});

SmallArray!LowExpr lowerMatchCases(
	ref GetLowExprCtx ctx,
	in Locals locals,
	ExprPos exprPos,
	LowType type,
	UriAndRange range,
	LowExpr* getMatched,
	IntegralValues memberIndices,
	in ConcreteExprKind.MatchUnion.Case[] cases,
) =>
	small!LowExpr(mapWithIndex!(LowExpr, ConcreteExprKind.MatchUnion.Case)(
		ctx.alloc, cases,
		(size_t caseIndex, ref ConcreteExprKind.MatchUnion.Case case_) =>
			has(case_.local)
				? withLowLocal!LowExpr(ctx, locals, force(case_.local), (in Locals newLocals, LowLocal* local) =>
					genLet(
						ctx.alloc, range, local,
						genUnionAs(
							local.type, range, getMatched,
							safeToUint(memberIndices[caseIndex].asUnsigned)),
						getLowExpr(ctx, newLocals, case_.then, exprPos)))
				: getLowExpr(ctx, locals, case_.then, exprPos)));

LowExprKind getClosureCreateExpr(
	ref GetLowExprCtx ctx,
	in Locals locals,
	UriAndRange range,
	LowType type,
	in ConcreteExprKind.ClosureCreate a,
) =>
	LowExprKind(LowExprKind.CreateRecord(
		mapZip!(LowExpr, ConcreteVariableRef, LowField)(
			ctx.alloc, a.args, ctx.allTypes.allRecords[type.as!(LowType.Record)].fields,
			(ref ConcreteVariableRef x, ref LowField f) =>
				getVariableRefExprForClosure(ctx, locals, range, f.type, x))));

LowExpr getVariableRefExprForClosure(
	ref GetLowExprCtx ctx,
	in Locals locals,
	UriAndRange range,
	LowType type,
	ConcreteVariableRef a,
) =>
	a.matchWithPointers!LowExpr(
		(Constant x) =>
			LowExpr(type, range, LowExprKind(x)),
		(ConcreteLocal* x) =>
			// Intentionally not dereferencing the local like 'getLocalGetExpr' does
			LowExpr(type, range, LowExprKind(LowExprKind.LocalGet(getLocal(ctx, locals, x)))),
		(ConcreteClosureRef x) =>
			getClosureField(ctx, range, x));

LowExprKind getClosureGetExpr(ref GetLowExprCtx ctx, UriAndRange range, ConcreteExprKind.ClosureGet a) {
	LowExpr getField = getClosureField(ctx, range, a.closureRef);
	final switch (a.referenceKind) {
		case ClosureReferenceKind.direct:
			return getField.kind;
		case ClosureReferenceKind.allocated:
			return genDerefGcPtr(ctx.alloc, getField);
	}
}

LowExprKind getClosureSetExpr(
	ref GetLowExprCtx ctx,
	in Locals locals,
	UriAndRange range,
	ref ConcreteExprKind.ClosureSet a,
) =>
	// Note: This doesn't write to a field, it gets a pointer from the field and writes to that
	genWriteToPtr(
		ctx.alloc,
		getClosureField(ctx, range, a.closureRef),
		getLowExpr(ctx, locals, a.value, ExprPos.nonTail));

// NOTE: This does not dereference pointer for mutAllocated, getClosureGetExpr will do that
LowExpr getClosureField(ref GetLowExprCtx ctx, UriAndRange range, ConcreteClosureRef closureRef) {
	LowLocal* closureLocal = &ctx.lowParams[0];
	LowExpr* closureGet = allocate(ctx.alloc, genLocalGet(range, closureLocal));
	LowRecord record = ctx.allTypes.allRecords[asPtrGcPointee(closureLocal.type).as!(LowType.Record)];
	return LowExpr(record.fields[closureRef.fieldIndex].type, range, LowExprKind(
		LowExprKind.RecordFieldGet(closureGet, closureRef.fieldIndex)));
}

LowExprKind getPtrToFieldExpr(
	ref GetLowExprCtx ctx,
	in Locals locals,
	ref ConcreteExpr target,
	size_t fieldIndex,
) =>
	LowExprKind(allocate(ctx.alloc,
		LowExprKind.PtrToField(getLowExpr(ctx, locals, target, ExprPos.nonTail), fieldIndex)));

LowExprKind getThrowExpr(
	ref GetLowExprCtx ctx,
	in Locals locals,
	UriAndRange range,
	LowType type,
	ref ConcreteExprKind.Throw a,
	ExprPos exprPos,
) {
	LowExprKind callThrow = genCallKind(ctx.alloc, ctx.commonFuns.throwImpl, [
		getLowExpr(ctx, locals, a.thrown, ExprPos.nonTail)]);
	LowExprKind kind = type == voidType
		? callThrow
		: genSeqKind(
			ctx.alloc,
			LowExpr(voidType, range, callThrow),
			LowExpr(type, range, LowExprKind(constantZero)));
	return exprPos == ExprPos.loop
		? genLoopBreakKind(ctx.alloc, LowExpr(type, range, kind))
		: kind;
}

LowExprKind getFinallyExpr(
	ref GetLowExprCtx ctx,
	in Locals locals,
	UriAndRange range,
	LowType type,
	ref ConcreteExprKind.Finally a,
) =>
	/*
	finally right
	below
	==>
	old-jmp-buf = cur-jmp-buf
	store mut __jmp_buf_tag = zeroed
	err mut = false
	res = if (&store).setjmp == 0
		below
	else
		err = true
		zeroed
	cur-jmp-buf := old-jmp-buf
	right
	if err
		rethrow-current-exception
	res
	*/
	withRestorableJmpBuf(ctx, range, (LowExpr restoreCurJmpBuf) {
		LowLocal* err = genLocal(ctx.alloc, symbol!"err", nextTempLocalIndex(ctx), boolType);
		LowExpr res = genSetjmp(
			ctx, range,
			getLowExpr(ctx, locals, a.below, ExprPos.nonTail),
			genSeq(
				ctx.alloc, range,
				genLocalSet(ctx.alloc, range, err, genTrue(range)),
				genZeroed(type, range)));
		LowExpr afterRes = genSeq(
			ctx.alloc, range,
			restoreCurJmpBuf,
			getLowExpr(ctx, locals, a.right, ExprPos.nonTail),
			genIf(ctx.alloc, range, genLocalGet(range, err), genRethrowCurrentException(ctx, range), genVoid(range)));
		return genLet(
			ctx.alloc, range, err,
			genFalse(range),
			genSeqThenReturnFirst(ctx.alloc, range, nextTempLocalIndex(ctx), res, afterRes));
	});

LowExprKind getTryExpr(
	ref GetLowExprCtx ctx,
	in Locals locals,
	ExprPos exprPos,
	UriAndRange range,
	LowType type,
	ref ConcreteExprKind.Try a,
) =>
	getTryOrTryLetExpr(
		ctx, locals, exprPos, range, type,
		a.exceptionMemberIndices, a.catchCases,
		(LowExpr restoreCurJmpBuf) =>
			genSeqThenReturnFirst(
				ctx.alloc, range, nextTempLocalIndex(ctx),
				getLowExpr(ctx, locals, a.tried, ExprPos.nonTail),
				restoreCurJmpBuf));

LowExprKind getTryLetExpr(
	ref GetLowExprCtx ctx,
	in Locals locals,
	ExprPos exprPos,
	UriAndRange range,
	LowType type,
	ref ConcreteExprKind.TryLet a,
) =>
	getTryOrTryLetExpr(
		ctx, locals, exprPos, range, type, singleIntegralValue(a.exceptionMemberIndex), [a.catch_],
		(LowExpr restoreCurJmpBuf) =>
			LowExpr(type, range, has(a.local)
				? genLetHandleAllocated(
					ctx, locals, exprPos, range, force(a.local), a.value, a.then,
					(LowExpr then) => genSeq(ctx.alloc, range, restoreCurJmpBuf, then))
				: genSeqKind(
					ctx.alloc, range,
					genDrop(ctx.alloc, range, getLowExpr(ctx, locals, a.value, ExprPos.nonTail)),
					restoreCurJmpBuf,
					getLowExpr(ctx, locals, a.then, exprPos))));

LowExprKind getTryOrTryLetExpr(
	ref GetLowExprCtx ctx,
	in Locals locals,
	ExprPos exprPos,
	UriAndRange range,
	LowType type,
	IntegralValues exceptionMemberIndices,
	in ConcreteExprKind.MatchUnion.Case[] catchCases,
	in LowExpr delegate(LowExpr restoreCurJmpBuf) @safe @nogc pure nothrow firstBlock,
) =>
	/*
	try
		tried
	catch foo x
		handler
	==>
	old-jmp-buf = cur-jmp-buf
	store mut __jmp_buf_tag = zeroed
	if (&store).setjmp == 0
		cur-jmp-buf = &store
		x = tried
		cur-jmp-buf := old-jmp-buf
		rest
	else
		cur-jmp-buf := old-jmp-buf
		match cur-thrown
		as foo x
			handler
		else
			rethrow-current-exception
	*/
	withRestorableJmpBuf(ctx, range, (LowExpr restoreCurJmpBuf) {
		LowExpr* curThrown = allocate(ctx.alloc, genGetCurThrown(ctx, range));
		LowExpr matchThrown = LowExpr(type, range, LowExprKind(allocate(ctx.alloc,
			LowExprKind.Switch(
				value: genUnionKind(range, curThrown),
				caseValues: exceptionMemberIndices,
				caseExprs: lowerMatchCases(
					ctx, locals, exprPos, type, range, curThrown, exceptionMemberIndices, catchCases),
				default_: genSeq(ctx.alloc, range,
					genRethrowCurrentException(ctx, range),
					// 'abort' is just to keep this well-typed
					genAbort(type, range))))));
		LowExpr onError = genSeq(ctx.alloc, range, restoreCurJmpBuf, matchThrown);
		return genSetjmp(ctx, range, firstBlock(restoreCurJmpBuf), onError);
	});

LowExprKind withRestorableJmpBuf(
	ref GetLowExprCtx ctx,
	UriAndRange range,
	in LowExpr delegate(LowExpr restoreJmpBuf) @safe @nogc pure nothrow cb,
) =>
	genLetTempKind(ctx.alloc, range, nextTempLocalIndex(ctx), genGetCurJmpBuf(ctx, range), (LowExpr oldJmpBuf) =>
		cb(genSetCurJmpBuf(ctx, range, oldJmpBuf)));

LowExpr genRethrowCurrentException(ref GetLowExprCtx ctx, UriAndRange range) =>
	genCall(ctx.alloc, range, ctx.commonFuns.rethrowCurrentException, voidType, []);

LowExpr genSetjmp(ref GetLowExprCtx ctx, UriAndRange range, LowExpr tried, LowExpr onLongjmp) {
	/*
	store mut __jmp_buf_tag = zeroed
	if (&store).setjmp == 0
		cur_jmp_buf = &store
		tried
	else
		onLongjmp
	*/
	LowType jmpBuf = ctx.commonFuns.jmpBufType;
	LowType jmpBufTag = *jmpBuf.as!(LowType.PtrRawMut).pointee;
	LowLocal* store = genLocal(ctx.alloc, symbol!"store", nextTempLocalIndex(ctx), jmpBufTag);
	LowExpr storePtr = genPtrToLocal(jmpBuf, range, store);
	LowExpr then = genIf(
		ctx.alloc, range,
		genEqInt32(
			ctx.alloc, range,
			genCall(ctx.alloc, range, ctx.commonFuns.setjmp, int32Type, [storePtr]),
			genConstantInt32(range, 0)),
		genSeq(ctx.alloc, range, genSetCurJmpBuf(ctx, range, storePtr), tried),
		onLongjmp);
	return genLet(ctx.alloc, range, store, genZeroed(jmpBufTag, range), then);
}

LowExpr genEqInt32(ref Alloc alloc, UriAndRange range, LowExpr a, LowExpr b) =>
	LowExpr(boolType, range, LowExprKind(allocate(alloc, LowExprKind.SpecialBinary(BuiltinBinary.eqInt32, [a, b]))));

LowExpr genGetCurThrown(ref GetLowExprCtx ctx, UriAndRange range) =>
	genVarGet(ctx.commonFuns.exceptionType, range, ctx.commonFuns.curThrown);

LowExpr genGetCurJmpBuf(ref GetLowExprCtx ctx, UriAndRange range) =>
	genCall(ctx.alloc, range, ctx.commonFuns.curJmpBuf, ctx.commonFuns.jmpBufType, []);

LowExpr genSetCurJmpBuf(ref GetLowExprCtx ctx, UriAndRange range, LowExpr value) =>
	genCall(ctx.alloc, range, ctx.commonFuns.setCurJmpBuf, voidType, [value]);
