module lower.lower;

@safe @nogc pure nothrow:

import backend.builtinMath : builtinForBinaryMath, builtinForUnaryMath;
import lower.checkLowModel : checkLowProgram;
import lower.generateMarkVisitFun : getMarkRootForType, getMarkVisitForType, generateMarkRoot, generateMarkVisit, initMarkVisitFuns, MarkRoot, MarkVisitFuns;
import lower.lowExprHelpers :
	anyPtrMutType,
	boolType,
	char8PtrConstType,
	genAbort,
	genAddPointer,
	genBitwiseNegate,
	genCallNoGcRoots,
	genCreateRecord,
	genConstantIntegral,
	genConstantInt32,
	genConstantNat64,
	genDerefGcPointer,
	genDrop,
	genEnumEq,
	genEnumIntersect,
	genEnumToIntegral,
	genEnumUnion,
	genFalse,
	genFunPointer,
	genIf,
	genLetNoGcRoot,
	genLetTempNoGcRoot,
	genLocal,
	genLocalByValue,
	genLocalGet,
	genLocalSet,
	genLoopContinue,
	genLoopBreak,
	genPointerToLocal,
	genPointerCast,
	genRecordFieldGet,
	genSeq,
	genSeqThenReturnFirstNoGcRoot,
	genSizeOf,
	genTrue,
	genUnionAs,
	genUnionKind,
	genUnionKindEquals,
	genVarGet,
	genVarSet,
	genVoid,
	genWrapMulNat64,
	genWriteToPointer,
	genZeroed,
	getElementPointerTypeFromArrType,
	int32Type,
	voidConstPointerType,
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
	applyNTimes,
	emptySmallArray,
	exists,
	exists2,
	foldPointers,
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
import util.util : castNonScope_ref, enumConvert, ptrTrustMe, todo, typeAs;
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
	LowUnion(s, small!LowType(s.body_.matchIn!(LowType[])( // TODO: no match, just cast --------------------------------------------
		(in ConcreteStructBody.Builtin x) => assert(false),
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

public immutable struct LowFunCause { // TODO: I could just save generating all MarkRoot / MarkVisit funs to the end, then not need this?
	immutable struct MarkRoot {
		LowType type;
	}
	immutable struct MarkVisit {
		LowType type;
	}
	mixin Union!(ConcreteFun*, MarkRoot, MarkVisit);
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
	MarkVisitFuns markVisitFuns = initMarkVisitFuns(alloc, allTypes);
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
				if (x.kind.isA!(BuiltinFun.MarkRoot)) {
					Opt!MarkRoot res = getMarkRootForType(getLowTypeCtx.alloc, lowFunCauses, markVisitFuns, allTypes, lowTypeFromConcreteType(getLowTypeCtx, only(x.typeArgs)));
					return optIf(has(res), () =>
						force(res).fun);
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

	LowType gcRootMutPointerType = lowTypeFromConcreteType(getLowTypeCtx, program.commonFuns.gcRoot.returnType);
	LowType gcRootType = *gcRootMutPointerType.as!(LowType.PtrRawMut).pointee;
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
		gcRootType: gcRootType,
		gcRootMutPointerType: gcRootMutPointerType,
		markRootFunPointerType: allTypes.allRecords[gcRootType.as!(LowType.Record)].fields[1].type,
		setGcRoot: mustGet(concreteFunToLowFunIndex, program.commonFuns.setGcRoot),
		popGcRoot: mustGet(concreteFunToLowFunIndex, program.commonFuns.popGcRoot));

	MutArr!LowFun allLowFuns;
	// New LowFuns will be discovered while compiling and added to lowFunCauses
	for (size_t index = 0; index < mutArrSize(lowFunCauses); index++) {
		push(alloc, allLowFuns, lowFunFromCause(
			program,
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
	LowType gcRootType;
	LowType gcRootMutPointerType;
	LowType markRootFunPointerType;
	LowFunIndex setGcRoot;
	LowFunIndex popGcRoot;
}

LowFun lowFunFromCause(
	ref ConcreteProgram concreteProgram,
	ref AllLowTypes allTypes,
	in Constant staticSymbols,
	ref GetLowTypeCtx getLowTypeCtx,
	in LowCommonFuns commonFuns,
	in MutConcreteFunToLowFunIndex concreteFunToLowFunIndex,
	in VarIndices varIndices,
	ref MutArr!LowFunCause lowFunCauses,
	ref MarkVisitFuns markVisitFuns,
	LowType markCtxType,
	LowFunIndex thisFunIndex,
	LowFunCause cause,
) =>
	cause.matchWithPointers!LowFun(
		(ConcreteFun* cf) {
			LowType returnType = lowTypeFromConcreteType(getLowTypeCtx, cf.returnType);
			LowLocal[] params = mapPointersWithIndex!(LowLocal, ConcreteLocal)(
				getLowTypeCtx.alloc, cf.paramsIncludingClosure, (size_t i, ConcreteLocal* x) =>
					getLowLocalForParameter(getLowTypeCtx, i, x));
			LowFunBody body_ = getLowFunBody(
				concreteProgram,
				allTypes,
				staticSymbols,
				getLowTypeCtx,
				lowFunCauses,
				markVisitFuns,
				concreteFunToLowFunIndex,
				commonFuns,
				varIndices,
				thisFunIndex,
				params,
				cf);
			return LowFun(LowFunSource(cf), returnType, params, body_);
		},
		(LowFunCause.MarkRoot x) =>
			generateMarkRoot(getLowTypeCtx.alloc, lowFunCauses, markVisitFuns, allTypes, markCtxType, commonFuns.mark, x.type),
		(LowFunCause.MarkVisit x) =>
			generateMarkVisit(getLowTypeCtx.alloc, lowFunCauses, markVisitFuns, allTypes, markCtxType, commonFuns.mark, x.type));

LowFun mainFun(ref GetLowTypeCtx ctx, LowFunIndex rtMainIndex, ConcreteFun* userMain, LowType userMainFunPointerType) {
	LowType char8PtrPtrConstType = LowType(LowType.PtrRawConst(allocate(ctx.alloc, char8PtrConstType)));
	LowLocal[] params = newArray!LowLocal(ctx.alloc, [
		genLocalByValue(ctx.alloc, symbol!"argc", 0, int32Type),
		genLocalByValue(ctx.alloc, symbol!"argv", 1, char8PtrPtrConstType)]);
	LowExpr userMainFunPointer =
		genFunPointer(userMainFunPointerType, UriAndRange.empty, userMain);
	LowExpr call = genCallNoGcRoots(ctx.alloc, int32Type, UriAndRange.empty, rtMainIndex, [
		genLocalGet(UriAndRange.empty, &params[0]),
		genLocalGet(UriAndRange.empty, &params[1]),
		userMainFunPointer
	]);
	LowFunBody body_ = LowFunBody(LowFunExprBody(false, false, call));
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
	ref ConcreteProgram concreteProgram,
	in AllLowTypes allTypes,
	in Constant staticSymbols,
	ref GetLowTypeCtx getLowTypeCtx,
	ref MutArr!LowFunCause lowFunCauses,
	ref MarkVisitFuns markVisitFuns,
	in MutConcreteFunToLowFunIndex concreteFunToLowFunIndex,
	in LowCommonFuns commonFuns,
	in VarIndices varIndices,
	LowFunIndex thisFunIndex,
	LowLocal[] params,
	ConcreteFun* a,
) {
	if (a.body_.isA!(ConcreteFunBody.Extern)) {
		return LowFunBody(LowFunBody.Extern(a.body_.as!(ConcreteFunBody.Extern).libraryName));
	} else {
		ConcreteExpr expr = a.body_.as!(ConcreteExpr);
		GetLowExprCtx exprCtx = GetLowExprCtx(
			thisFunIndex,
			ptrTrustMe(concreteProgram),
			ptrTrustMe(allTypes),
			castNonScope_ref(staticSymbols),
			ptrTrustMe(getLowTypeCtx),
			ptrTrustMe(lowFunCauses),
			ptrTrustMe(markVisitFuns),
			ptrTrustMe(concreteFunToLowFunIndex),
			commonFuns,
			castNonScope_ref(varIndices),
			a.paramsIncludingClosure,
			params,
			curFunIsYielding: concreteProgram.yieldingFuns.has(a),
			hasTailRecur: false,
			tempLocalIndex: a.paramsIncludingClosure.length);
		LowExpr body_ = withStackMap!(LowExpr, ConcreteLocal*, LowLocal*)((ref Locals locals) =>
			getLowExpr(exprCtx, locals, expr, ExprPos(0, ExprPos.Kind.tail)));
		return LowFunBody(LowFunExprBody(exprCtx.curFunIsYielding, exprCtx.hasTailRecur, body_));
	}
}

LowExpr genLetPossiblyGcRoot(
	ref GetLowExprCtx ctx,
	in UriAndRange range,
	LowLocal* local,
	LowExpr init,
	ExprPos exprPos,
	in LowExpr delegate(ExprPos) @safe @nogc pure nothrow cbThen,
) =>
	genLetNoGcRoot(ctx.alloc, range, local, init, maybeAddGcRoot(ctx, range, local, exprPos, cbThen));

LowExpr genLetTempPossiblyGcRoot(
	ref GetLowExprCtx ctx,
	ExprPos exprPos,
	in UriAndRange range,
	LowExpr value,
	in LowExpr delegate(ExprPos, LowExpr) @safe @nogc pure nothrow cbThen,
) {
	LowLocal* local = genLocal(ctx.alloc, symbol!"temp", nextTempLocalIndex(ctx), value.type);
	return genLetPossiblyGcRoot(ctx, range, local, value, exprPos, (ExprPos inner) =>
		cbThen(inner, genLocalGet(range, local)));
}

LowExpr genSeqThenReturnFirstPossiblyGcRoot(ref GetLowExprCtx ctx, ExprPos exprPos, in UriAndRange range, LowExpr a, LowExpr b) =>
	genLetTempPossiblyGcRoot(ctx, exprPos, range, a, (ExprPos inner, LowExpr getA) =>
		genSeq(ctx.alloc, range, b, handleExprPos(ctx, inner, getA)));

LowExpr withPushAllGcRoots(
	ref GetLowExprCtx ctx,
	ExprPos exprPos,
	in UriAndRange range,
	bool isYieldingCall,
	LowExpr[] args,
	in LowExpr delegate(ExprPos, LowExpr[]) @safe @nogc pure nothrow cb,
) {
	bool hasRoots = isYieldingCall && exists2!LowExpr(args, (ref LowExpr x) =>
		has(getMarkRootForType(ctx.alloc, *ctx.lowFunCauses, *ctx.markVisitFuns, *ctx.allTypes, x.type)));
	if (hasRoots) {
		ArrayBuilder!LowExpr argGetters;
		return genWithGcRootsRecur(ctx, exprPos, range, args, argGetters, cb);
	} else
		return cb(exprPos, args);
}
LowExpr genWithGcRootsRecur(
	ref GetLowExprCtx ctx,
	ExprPos exprPos,
	in UriAndRange range,
	in LowExpr[] args,
	ref ArrayBuilder!LowExpr argGetters,
	in LowExpr delegate(ExprPos, LowExpr[]) @safe @nogc pure nothrow cb,
) =>
	isEmpty(args)
		? cb(exprPos, finish(ctx.alloc, argGetters))
		: genLetTempPossiblyGcRoot(ctx, exprPos, range, args[0], (ExprPos inner, LowExpr getArg0) {
			add(ctx.alloc, argGetters, getArg0);
			return genWithGcRootsRecur(ctx, inner, range, args[1 .. $], argGetters, cb);
		});

// Wraps 'expr' in code to push a GC root for 'local' and pop it when done
LowExpr maybeAddGcRoot( // TODO: just merge into its only caller ??????????????????????????????????????????????????????????????????????
	ref GetLowExprCtx ctx,
	in UriAndRange range,
	LowLocal* local,
	ExprPos exprPos,
	in LowExpr delegate(ExprPos) @safe @nogc pure nothrow cbThen,
) {
	Opt!MarkRoot optMarkRoot = ctx.curFunIsYielding
		? getMarkRootForType(ctx.alloc, *ctx.lowFunCauses, *ctx.markVisitFuns, *ctx.allTypes, local.type)
		: none!MarkRoot;
	if (!has(optMarkRoot)) return cbThen(exprPos);
	MarkRoot markRoot = force(optMarkRoot);

	LowExpr pointerToLocal = () {
		final switch (markRoot.kind) {
			case MarkRoot.Kind.localAlreadyPointer:
				return genLocalGet(range, local);
			case MarkRoot.Kind.pointerToLocal:
				LowType type = LowType(LowType.PtrRawMut(allocate(ctx.alloc, local.type))); // TODO: helper for this??????
				return genPointerToLocal(type, range, local);
		}
	}();
	LowExpr markRootFunction = () {
		LowType funType = ctx.commonFuns.markRootFunPointerType;
		LowExpr fun = genFunPointer(funType, range, markRoot.fun); // TODO: the type is wrong for localAlreadyPointer, but currently that's unchecked
		final switch (markRoot.kind) {
			case MarkRoot.Kind.localAlreadyPointer:
				return genPointerCast(ctx.alloc, funType, range, fun);
			case MarkRoot.Kind.pointerToLocal:
				return fun;
		}
	}();
	/*
	root gc-root = (x, &visit-x, gc-root)
	&root set-gc-root
	res = <<the body>>
	pop-gc-root
	res
	*/
	LowExpr initRoot = genCreateRecord(ctx.alloc, ctx.commonFuns.gcRootType, range, [
		genPointerCast(ctx.alloc, voidConstPointerType, range, pointerToLocal),
		markRootFunction,
		genCallNoGcRoots(ctx.alloc, ctx.commonFuns.gcRootMutPointerType, range, ctx.commonFuns.gcRoot, [])]);
	LowLocal* root = genLocal(ctx.alloc, symbol!"root", nextTempLocalIndex(ctx), ctx.commonFuns.gcRootType);
	return genLetNoGcRoot(
		ctx.alloc, range, root,
		initRoot,
		genSeq(ctx.alloc, range,
			genCallNoGcRoots(ctx.alloc, voidType, range, ctx.commonFuns.setGcRoot, [genPointerToLocal(ctx.commonFuns.gcRootMutPointerType, range, root)]),
			cbThen(exprPos.withIncrNGcRoots)));
}

struct GetLowExprCtx {
	@safe @nogc pure nothrow:

	immutable LowFunIndex currentFun;
	immutable ConcreteProgram* concreteProgram;
	immutable AllLowTypes* allTypes;
	immutable Constant staticSymbols;
	GetLowTypeCtx* getLowTypeCtxPtr;
	MutArr!LowFunCause* lowFunCauses;
	MarkVisitFuns* markVisitFuns;
	const MutConcreteFunToLowFunIndex* concreteFunToLowFunIndexPtr;
	LowCommonFuns commonFuns;
	immutable VarIndices varIndices;
	ConcreteLocal[] concreteParams;
	LowLocal[] lowParams;
	immutable bool curFunIsYielding;
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

struct ExprPos {
	@safe @nogc pure nothrow:
	uint nGcRootsToPop;
	enum Kind {
		// A regular expression, not the one returned from the function
		nonTail,
		// The body of a loop (or a branch of an 'if' that is the body of a loop, etc.)
		loop,
		// An expression returned from the function. (Not just the main expression, but e.g. the branch of an 'if' that is the main expression.)
		tail
	}
	Kind kind;

	static ExprPos nonTailNoGcRoots() => ExprPos(0, Kind.nonTail);
	static ExprPos loopNoGcRoots() => ExprPos(0, Kind.loop);
	ExprPos withIncrNGcRoots() =>
		ExprPos(nGcRootsToPop + 1, kind);
	ExprPos asNonTail() {
		assert(kind != Kind.loop);
		return ExprPos(nGcRootsToPop, Kind.nonTail);
	}
}

LowExpr handleExprPos(ref GetLowExprCtx ctx, ExprPos exprPos, LowExpr expr) {
	assert(exprPos.kind != ExprPos.Kind.loop);
	return doThenPopGcRoots(ctx, exprPos.nGcRootsToPop, expr);
}

LowExpr doThenPopGcRoots(ref GetLowExprCtx ctx, uint nGcRootsToPop, LowExpr expr) =>
	applyNTimes(expr, nGcRootsToPop, (LowExpr x) =>
		genSeqThenReturnFirstNoGcRoot(
			ctx.alloc, x.source, nextTempLocalIndex(ctx), x,
			genCallNoGcRoots(ctx.alloc, voidType, x.source, ctx.commonFuns.popGcRoot, [])));

LowExpr popGcRootsThenDo(ref GetLowExprCtx ctx, uint nGcRootsToPop, LowExpr expr) =>
	applyNTimes(expr, nGcRootsToPop, (LowExpr x) =>
		genSeq(
			ctx.alloc, x.source,
			genCallNoGcRoots(ctx.alloc, voidType, x.source, ctx.commonFuns.popGcRoot, []),
			x));

LowExpr getLowExpr(
	ref GetLowExprCtx ctx,
	in Locals locals,
	ref ConcreteExpr expr,
	ExprPos exprPos,
) {
	LowType type = lowTypeFromConcreteType(ctx.typeCtx, expr.type);
	LowExpr res = getLowExprKind(ctx, locals, type, expr, exprPos); // TODO: that is misnamed then ............................
	if (res.type != type) { // ---------------------------------------------------------------------------------------------------
		import util.writer : debugLogWithWriter, Writer;
		debugLogWithWriter((scope ref Writer writer) {
			writer ~= "Type is not as expected for concrete expr kind ";
			writer ~= expr.kind.kind;
			writer ~= " output as low expr kind ";
			writer ~= res.kind.kind;
		});
	}
	assert(res.type == type);
	return res;
}

LowExpr getLowExprKind(
	ref GetLowExprCtx ctx,
	in Locals locals,
	LowType type,
	ref ConcreteExpr expr,
	ExprPos exprPos,
) {
	UriAndRange range() =>
		expr.range;
	LowExpr regular(LowExprKind x) =>
		handleExprPos(ctx, exprPos, LowExpr(type, range, x));
	return expr.kind.match!LowExpr(
		(ref ConcreteExprKind.Alloc x) =>
			getAllocExpr(ctx, exprPos, locals, range, x),
		(ConcreteExprKind.Call x) =>
			getCallExpr(ctx, locals, exprPos, type, range, x.called, x.args),
		(ConcreteExprKind.ClosureCreate x) =>
			handleExprPos(ctx, exprPos, getClosureCreateExpr(ctx, locals, range, type, x)),
		(ref ConcreteExprKind.ClosureGet x) =>
			handleExprPos(ctx, exprPos, getClosureGetExpr(ctx, range, x)),
		(ref ConcreteExprKind.ClosureSet x) =>
			handleExprPos(ctx, exprPos, getClosureSetExpr(ctx, locals, range, x)),
		(Constant x) =>
			regular(LowExprKind(x)),
		(ConcreteExprKind.CreateArray x) =>
			getCreateArrayExpr(ctx, exprPos, locals, range, type, expr.type, x),
		(ConcreteExprKind.CreateRecord x) =>
			regular(LowExprKind(LowExprKind.CreateRecord(getArgs(ctx, locals, x.args)))), // TODO: this has the same issue as a Call -- need to push roots for non-last args if some arg may yield
		(ref ConcreteExprKind.CreateUnion x) =>
			LowExpr(type, range, LowExprKind(allocate(ctx.alloc, LowExprKind.CreateUnion(
				x.memberIndex,
				getLowExpr(ctx, locals, x.arg, exprPos.asNonTail))))),
		(ref ConcreteExprKind.Drop x) =>
			handleExprPos(ctx, exprPos, getDropExpr(ctx, locals, range, x)),
		(ref ConcreteExprKind.Finally x) =>
			getFinallyExpr(ctx, exprPos, locals, range, type, x),
		(ref ConcreteExprKind.If x) =>
			LowExpr(type, range, LowExprKind(allocate(ctx.alloc, LowExprKind.If(
				getLowExpr(ctx, locals, x.cond, ExprPos.nonTailNoGcRoots),
				getLowExpr(ctx, locals, x.then, exprPos),
				getLowExpr(ctx, locals, x.else_, exprPos))))),
		(ConcreteExprKind.Lambda x) =>
			handleExprPos(ctx, exprPos, getLambdaExpr(ctx, locals, type, range, x)),
		(ref ConcreteExprKind.Let x) =>
			getLetExpr(ctx, locals, exprPos, type, range, x),
		(ConcreteExprKind.LocalGet x) =>
			handleExprPos(ctx, exprPos, getLocalGetExpr(ctx, locals, type, range, x)),
		(ref ConcreteExprKind.LocalSet x) =>
			handleExprPos(ctx, exprPos, getLocalSetExpr(ctx, locals, range, x)),
		(ref ConcreteExprKind.Loop x) =>
			handleExprPos(ctx, exprPos, LowExpr(type, range, LowExprKind(allocate(ctx.alloc, LowExprKind.Loop(getLowExpr(ctx, locals, x.body_, ExprPos.loopNoGcRoots)))))),
		(ref ConcreteExprKind.LoopBreak x) {
			assert(exprPos.kind == ExprPos.Kind.loop);
			return genLoopBreak(ctx.alloc, type, range, getLowExpr(ctx, locals, x.value, ExprPos(exprPos.nGcRootsToPop, ExprPos.Kind.nonTail)));
		},
		(ConcreteExprKind.LoopContinue) {
			assert(exprPos.kind == ExprPos.Kind.loop);
			return popGcRootsThenDo(ctx, exprPos.nGcRootsToPop, genLoopContinue(type, range));
		},
		(ref ConcreteExprKind.MatchEnumOrIntegral x) =>
			getMatchIntegralExpr(ctx, locals, exprPos, type, range, x),
		(ref ConcreteExprKind.MatchStringLike x) =>
			getMatchStringLikeExpr(ctx, locals, exprPos, range, x),
		(ref ConcreteExprKind.MatchUnion x) =>
			getMatchUnionExpr(ctx, locals, exprPos, type, range, x),
		(ref ConcreteExprKind.PtrToField x) =>
			handleExprPos(ctx, exprPos, getPtrToFieldExpr(ctx, locals, type, range, x.target, x.fieldIndex)),
		(ConcreteExprKind.PtrToLocal x) =>
			handleExprPos(ctx, exprPos, getPtrToLocalExpr(ctx, locals, type, range, x)),
		(ConcreteExprKind.RecordFieldGet x) =>
			handleExprPos(ctx, exprPos, getRecordFieldGet(ctx, locals, type, range, *x.record, x.fieldIndex)),
		(ref ConcreteExprKind.Seq x) =>
			genSeq(
				ctx.alloc, range,
				getLowExpr(ctx, locals, x.first, ExprPos.nonTailNoGcRoots),
				getLowExpr(ctx, locals, x.then, exprPos)),
		(ref ConcreteExprKind.Throw x) =>
			getThrowExpr(ctx, locals, range, type, x, exprPos),
		(ref ConcreteExprKind.Try x) =>
			getTryExpr(ctx, locals, exprPos, range, type, x),
		(ref ConcreteExprKind.TryLet x) =>
			getTryLetExpr(ctx, locals, exprPos, range, type, x),
		(ConcreteExprKind.UnionAs x) =>
			LowExpr(type, range, LowExprKind(LowExprKind.UnionAs(
				allocate(ctx.alloc, getLowExpr(ctx, locals, *x.union_, exprPos.asNonTail)), x.memberIndex))),
		(ConcreteExprKind.UnionKind x) =>
			LowExpr(type, range, LowExprKind(LowExprKind.UnionKind(
				allocate(ctx.alloc, getLowExpr(ctx, locals, *x.union_, exprPos.asNonTail))))));
}

LowExpr getAllocateExpr(
	ref Alloc alloc,
	LowFunIndex allocFunIndex,
	UriAndRange range,
	LowType ptrType,
	LowExpr size,
) =>
	// TODO: ensure this will definitely be the return type of allocFunIndex
	genPointerCast(alloc, ptrType, range, genCallNoGcRoots(alloc, anyPtrMutType, range, allocFunIndex, [size]));

LowExpr getAllocExpr(ref GetLowExprCtx ctx, ExprPos exprPos, in Locals locals, UriAndRange range, ref ConcreteExprKind.Alloc a) {
	LowExpr arg = getLowExpr(ctx, locals, a.arg, ExprPos.nonTailNoGcRoots);
	return getAllocExpr2(ctx, exprPos, getLowGcPtrType(ctx.typeCtx, arg.type), range, arg);
}

LowExpr getAllocExpr2(ref GetLowExprCtx ctx, ExprPos exprPos, LowType type, UriAndRange range, LowExpr arg) => // TODO: just roll into getAllocExpr2Expr?
	isEmptyType(*ctx.allTypes, arg.type)
		? handleExprPos(ctx, exprPos, mayHaveSideEffects(arg)
			? genSeq(ctx.alloc, range, genDrop(ctx.alloc, range, arg), genZeroed(type, range))
			: genZeroed(type, range))
		// ptr = (T*) alloc(sizeof(T)); ptr add-gc-root; *ptr = arg; pop-gc-root; return ptr;
		// This is safe even if 'arg' yields becase 'alloc' returns zeroed memory.
		: genLetTempPossiblyGcRoot(
			ctx, exprPos, range,
			getAllocateExpr(
				ctx.alloc, ctx.commonFuns.alloc, range, type,
				genSizeOf(*ctx.allTypes, range, asPtrGcPointee(type))), // TODO: asPtrGcPointee(type) is just arg.type? -------
			(ExprPos inner, LowExpr getPtr) => genSeq(ctx.alloc, range, genWriteToPointer(ctx.alloc, range, getPtr, arg), handleExprPos(ctx, inner, getPtr)));

// TODO: this should probably part of the expression 'type'
bool mayHaveSideEffects(in LowExpr a) =>
	!a.kind.isA!Constant && !a.kind.isA!(LowExprKind.LocalGet) && (
		!a.kind.isA!(LowExprKind.CreateRecord) ||
		exists2!LowExpr(a.kind.as!(LowExprKind.CreateRecord).args, (ref LowExpr x) => mayHaveSideEffects(x)));

LowExpr getCallExpr(
	ref GetLowExprCtx ctx,
	in Locals locals,
	ExprPos exprPos,
	LowType type,
	UriAndRange range,
	ConcreteFun* called,
	in SmallArray!ConcreteExpr args,
) {
	Opt!LowFunIndex opCalled = tryGetLowFunIndex(ctx, called);
	return has(opCalled)
		? getCallRegular(ctx, locals, type, range, exprPos, args, called, force(opCalled))
		: handleExprPos(ctx, exprPos, getCallSpecial(ctx, locals, type, range, called, args));
}

LowExpr getCallEquals(
	ref GetLowExprCtx ctx,
	UriAndRange range,
	ConcreteFun* called,
	LowExpr arg0,
	LowExpr arg1,
) {
	Opt!LowFunIndex opCalled = tryGetLowFunIndex(ctx, called);
	return has(opCalled)
		? genCallNoGcRoots(ctx.alloc, boolType, range, force(opCalled), [arg0, arg1])
		: LowExpr(boolType, range, LowExprKind(allocate(ctx.alloc, LowExprKind.SpecialBinary(
			called.body_.as!(ConcreteFunBody.Builtin).kind.as!(BuiltinBinary), [arg0, arg1]))));
}

LowExpr getCallRegular(
	ref GetLowExprCtx ctx,
	in Locals locals,
	LowType type,
	in UriAndRange range,
	ExprPos exprPos,
	in SmallArray!ConcreteExpr args,
	ConcreteFun* concreteCalled,
	LowFunIndex called,
) {
	if (called == ctx.currentFun && exprPos.kind == ExprPos.Kind.tail) {
		ctx.hasTailRecur = true;
		ArrayBuilder!UpdateParam updateParams;
		zipPtrFirst(ctx.lowParams, args, (LowLocal* param, ref ConcreteExpr concreteArg) {
			LowExpr arg = getLowExpr(ctx, locals, concreteArg, ExprPos.nonTailNoGcRoots);
			if (!(arg.kind.isA!(LowExprKind.LocalGet) && arg.kind.as!(LowExprKind.LocalGet).local == param))
				add(ctx.alloc, updateParams, UpdateParam(param, arg));
		});
		return handleExprPos(ctx, exprPos, LowExpr(type, range, LowExprKind(LowExprKind.TailRecur(finish(ctx.alloc, updateParams)))));
	} else
		return withPushAllGcRoots(
			ctx, exprPos, range, ctx.curFunIsYielding && ctx.concreteProgram.yieldingFuns.has(concreteCalled),
			map!(LowExpr, ConcreteExpr)(ctx.alloc, args, (ref ConcreteExpr x) =>
				getLowExpr(ctx, locals, x, ExprPos.nonTailNoGcRoots)),
			(ExprPos inner, LowExpr[] args) =>
				handleExprPos(ctx, inner, genCallNoGcRoots(type, range, called, args)));
}

LowExpr getCallSpecial(
	ref GetLowExprCtx ctx,
	in Locals locals,
	LowType type,
	UriAndRange range,
	ConcreteFun* called,
	in ConcreteExpr[] args,
) =>
	called.body_.match!LowExpr(
		(ConcreteFunBody.Builtin x) =>
			getCallBuiltinExpr(ctx, locals, type, range, called, args, x.kind),
		(Constant x) =>
			LowExpr(type, range, LowExprKind(x)),
		(ConcreteFunBody.CreateRecord) {
			if (isEmptyType(*ctx.allTypes, type))
				return genZeroed(type, range);
			else {
				LowExprKind create = LowExprKind(LowExprKind.CreateRecord(getArgs(ctx, locals, args))); // TODO: same issue with args... need to have GC roots for non-last args
				return type.isA!(LowType.PtrGc)
					? getAllocExpr2(ctx, ExprPos.nonTailNoGcRoots, type, range, LowExpr(asPtrGcPointee(type), range, create))
					: LowExpr(type, range, create);
			}
		},
		(ConcreteFunBody.CreateUnion x) {
			LowExpr arg = isEmpty(args)
				? genVoid(range)
				: getLowExpr(ctx, locals, only(args), ExprPos.nonTailNoGcRoots);
			return LowExpr(type, range, LowExprKind(allocate(ctx.alloc, LowExprKind.CreateUnion(x.memberIndex, arg))));
		},
		(EnumFunction x) =>
			genEnumFunction(ctx, locals, type, range, x, args),
		(ConcreteFunBody.Extern) =>
			assert(false),
		(ConcreteExpr _) =>
			assert(false),
		(ConcreteFunBody.FlagsFn x) {
			final switch (x.fn) {
				case FlagsFunction.all:
					return genConstantIntegral(type, range, x.allValue);
				case FlagsFunction.negate:
					return genFlagsNegate(
						ctx.alloc,
						range,
						x.allValue,
						getLowExpr(ctx, locals, only(args), ExprPos.nonTailNoGcRoots));
				case FlagsFunction.new_:
					return genConstantIntegral(type, range, 0);
			}
		},
		(ConcreteFunBody.RecordFieldCall x) =>
			getRecordFieldCall(ctx, locals, type, range, args, x),
		(ConcreteFunBody.RecordFieldGet x) =>
			getRecordFieldGet(ctx, locals, type, range, only(args), x.fieldIndex),
		(ConcreteFunBody.RecordFieldPointer x) =>
			getPtrToFieldExpr(ctx, locals, type, range, only(args), x.fieldIndex),
		(ConcreteFunBody.RecordFieldSet x) {
			assert(args.length == 2);
			// TODO: transform this into: -------------------------------------------------------------------------------------------------------
			// target = ...
			// &target push-gc-root
			// target.x := value
			// pop-gc-root
			return LowExpr(voidType, range, LowExprKind(allocate(ctx.alloc, LowExprKind.RecordFieldSet(
				getLowExpr(ctx, locals, args[0], ExprPos.nonTailNoGcRoots), // TODO: Wait, this actually needs to be a GC root! ---------------------
				x.fieldIndex,
				getLowExpr(ctx, locals, args[1], ExprPos.nonTailNoGcRoots)))));
		},
		(ConcreteFunBody.VarGet x) =>
			LowExpr(type, range, LowExprKind(LowExprKind.VarGet(mustGet(ctx.varIndices, x.var)))),
		(ConcreteFunBody.VarSet x) =>
			LowExpr(type, range, LowExprKind(LowExprKind.VarSet(
				mustGet(ctx.varIndices, x.var),
				allocate(ctx.alloc, getLowExpr(ctx, locals, only(args), ExprPos.nonTailNoGcRoots))))));

LowExpr getRecordFieldCall(
	ref GetLowExprCtx ctx,
	in Locals locals,
	LowType type,
	UriAndRange range,
	in ConcreteExpr[] args,
	in ConcreteFunBody.RecordFieldCall body_,
) {
	LowExpr fun = getRecordFieldGet(ctx, locals, lowTypeFromConcreteStruct(ctx.typeCtx, body_.funType), range, args[0], body_.fieldIndex);
	LowExpr arg = () {
		switch (args.length) {
			case 0:
				assert(false);
			case 1:
				return genVoid(range);
			case 2:
				return getLowExpr(ctx, locals, args[1], ExprPos.nonTailNoGcRoots);
			default:
				return LowExpr(
					lowTypeFromConcreteType(ctx.typeCtx, body_.argType),
					range,
					LowExprKind(LowExprKind.CreateRecord(map(ctx.alloc, args[1 .. $], (ref ConcreteExpr arg) =>
						getLowExpr(ctx, locals, arg, ExprPos.nonTailNoGcRoots))))); // TODO: the usual problem with args ...........................
		}
	}();
	ConcreteFun* caller = body_.caller;
	Opt!LowFunIndex opCalled = tryGetLowFunIndex(ctx, caller);
	if (has(opCalled))
		return genCallNoGcRoots(ctx.alloc, type, range, force(opCalled), [fun, arg]); // TODO: the usual problem with args.... -------------------------------
	else {
		assert(caller.body_.as!(ConcreteFunBody.Builtin).kind.isA!(BuiltinFun.CallFunPointer));
		return callFunPointerInner(ctx, ExprPos.nonTailNoGcRoots, locals, range, type, fun, arg);
	}
}

LowExpr getRecordFieldGet(ref GetLowExprCtx ctx, in Locals locals, LowType type, in UriAndRange range, ref ConcreteExpr record, size_t fieldIndex) =>
	LowExpr(type, range, LowExprKind(LowExprKind.RecordFieldGet(
		allocate(ctx.alloc, getLowExpr(ctx, locals, record, ExprPos.nonTailNoGcRoots)),
		fieldIndex)));

LowExpr genFlagsNegate(ref Alloc alloc, UriAndRange range, ulong allValue, LowExpr a) =>
	genEnumIntersect(alloc, range, genBitwiseNegate(alloc, range, a), genConstantIntegral(a.type, range, allValue));

LowExpr genEnumFunction(
	ref GetLowExprCtx ctx,
	in Locals locals,
	LowType type,
	in UriAndRange range,
	EnumFunction a,
	in ConcreteExpr[] args,
) {
	LowExpr arg0() { return getLowExpr(ctx, locals, args[0], ExprPos.nonTailNoGcRoots); }
	LowExpr arg1() { return getLowExpr(ctx, locals, args[1], ExprPos.nonTailNoGcRoots); }
	final switch (a) {
		case EnumFunction.equal:
			assert(args.length == 2);
			return genEnumEq(ctx.alloc, range, arg0(), arg1());
		case EnumFunction.intersect:
			assert(args.length == 2);
			return genEnumIntersect(ctx.alloc, range, arg0(), arg1());
		case EnumFunction.toIntegral:
			assert(args.length == 1);
			return genEnumToIntegral(ctx.alloc, type, range, arg0());
		case EnumFunction.union_:
			assert(args.length == 2);
			return genEnumUnion(ctx.alloc, range, arg0(), arg1());
		case EnumFunction.members:
			// In concretize, this was translated to a constant
			assert(false);
	}
}

LowExpr[] getArgs(ref GetLowExprCtx ctx, in Locals locals, in ConcreteExpr[] args) =>
	map(ctx.alloc, args, (ref ConcreteExpr arg) =>
		getLowExpr(ctx, locals, arg, ExprPos.nonTailNoGcRoots)); // TODO: THE USUAL PROBLEM WITH ARGS ----------------------

LowExpr callFunPointer(
	ref GetLowExprCtx ctx,
	ExprPos exprPos,
	in Locals locals,
	UriAndRange range,
	LowType type,
	ConcreteExpr[2] funPtrAndArg,
) {
	LowExpr funPtr = getLowExpr(ctx, locals, funPtrAndArg[0], ExprPos.nonTailNoGcRoots);
	LowExpr arg = getLowExpr(ctx, locals, funPtrAndArg[1], ExprPos.nonTailNoGcRoots);
	return callFunPointerInner(ctx, exprPos, locals, range, type, funPtr, arg);
}

LowExpr callFunPointerInner(
	ref GetLowExprCtx ctx,
	ExprPos exprPos,
	in Locals locals,
	UriAndRange range,
	LowType type,
	LowExpr funPtr,
	LowExpr arg,
) {
	LowExpr doCall(ExprPos inner, LowExpr getFunPtr, SmallArray!LowExpr args) =>
		handleExprPos(ctx, exprPos, LowExpr(type, range, LowExprKind(LowExprKind.CallFunPointer(allocate(ctx.alloc, getFunPtr), args))));
	Opt!(LowType[]) optArgTypes = tryUnpackTuple(ctx.alloc, ctx.allTypes.allRecords, arg.type);
	if (has(optArgTypes)) {
		LowType[] argTypes = force(optArgTypes);
		return arg.kind.isA!(LowExprKind.CreateRecord)
			? doCall(exprPos, funPtr, small!LowExpr(arg.kind.as!(LowExprKind.CreateRecord).args))
			: argTypes.length == 0
			// Making sure the side effect order is function then arg
			? genLetTempNoGcRoot(ctx.alloc, range, nextTempLocalIndex(ctx), funPtr, (LowExpr getFunPointer) =>
				genSeq(ctx.alloc, range, arg, doCall(exprPos, getFunPointer, emptySmallArray!LowExpr)))
			: genLetTempNoGcRoot(ctx.alloc, range, nextTempLocalIndex(ctx), funPtr, (LowExpr getFunPointer) =>
				genLetTempPossiblyGcRoot(ctx, exprPos, range, arg, (ExprPos inner, LowExpr getArg) =>
					doCall(inner, getFunPointer, mapWithIndex!(LowExpr, LowType)(
						ctx.alloc, small!LowType(argTypes), (size_t argIndex, ref LowType argType) =>
							genRecordFieldGet(ctx.alloc, range, getArg, argType, argIndex)))));
	} else
		return doCall(exprPos, funPtr, newSmallArray!LowExpr(ctx.alloc, [arg]));
}

LowExpr getCallBuiltinExpr(
	ref GetLowExprCtx ctx,
	in Locals locals,
	LowType type,
	UriAndRange range,
	ConcreteFun* called,
	in ConcreteExpr[] args,
	BuiltinFun kind,
) {
	LowExpr getArg(ref ConcreteExpr arg, ExprPos argPos = ExprPos.nonTailNoGcRoots) =>
		getLowExpr(ctx, locals, arg, argPos);
	LowExpr getArg0() =>
		getArg(args[0]);
	LowExpr getArg1() =>
		getArg(args[1]);
	return kind.match!LowExpr(
		(BuiltinFun.AllTests) =>
			assert(false), // handled in concretize
		(BuiltinUnary kind) {
			assert(args.length == 1);
			return LowExpr(type, range, LowExprKind(allocate(ctx.alloc, LowExprKind.SpecialUnary(kind, getArg0))));
		},
		(BuiltinUnaryMath kind) {
			assert(args.length == 1);
			return LowExpr(type, range, LowExprKind(allocate(ctx.alloc, LowExprKind.SpecialUnaryMath(kind, getArg0))));
		},
		(BuiltinBinary kind) {
			assert(args.length == 2);
			return maybeOptimizeSpecialBinary(ctx, type, range, kind, getArg0, getArg1);
		},
		(BuiltinBinaryLazy kind) {
			assert(args.length == 2);
			return genBuiltinBinaryLazy(ctx, type, range, kind, getArg0, getArg1); //getArg(args[1], ExprPos.tail)); // TODO: second arg should use ExprPos.tail
		},
		(BuiltinBinaryMath kind) {
			assert(args.length == 2);
			return LowExpr(type, range, LowExprKind(allocate(ctx.alloc, LowExprKind.SpecialBinaryMath(
				kind, [getArg0,getArg1]))));
		},
		(BuiltinTernary kind) {
			assert(args.length == 3);
			return LowExpr(type, range, LowExprKind(allocate(ctx.alloc, LowExprKind.SpecialTernary(
				kind, [getArg0, getArg1, getArg(args[2])]))));
		},
		(BuiltinFun.CallLambda) =>
			assert(false), // handled in concretize
		(BuiltinFun.CallFunPointer) =>
			callFunPointer(ctx, ExprPos.nonTailNoGcRoots, locals, range, type, only2(args)), // TODO: should pass outer exprPos down too here
		(Constant x) =>
			LowExpr(type, range, LowExprKind(x)),
		(BuiltinFun.InitConstants) =>
			LowExpr(type, range, LowExprKind(LowExprKind.InitConstants())),
		(BuiltinFun.MarkRoot) =>
			// Handled in getAllLowFuns
			assert(false),
		(BuiltinFun.MarkVisit) =>
			// Handled in getAllLowFuns
			assert(false),
		(BuiltinFun.PointerCast) {
			assert(args.length == 1);
			return genPointerCast(ctx.alloc, type, range, getArg0);
		},
		(BuiltinFun.SizeOf) {
			LowType typeArg =
				lowTypeFromConcreteType(ctx.typeCtx, only(called.body_.as!(ConcreteFunBody.Builtin).typeArgs));
			return genSizeOf(*ctx.allTypes, range, typeArg);
		},
		(BuiltinFun.StaticSymbols) =>
			LowExpr(type, range, LowExprKind(ctx.staticSymbols)),
		(VersionFun _) =>
			// handled in concretize
			assert(false));
}

LowExpr maybeOptimizeSpecialBinary(
	ref GetLowExprCtx ctx,
	LowType type,
	UriAndRange range,
	BuiltinBinary kind,
	LowExpr arg0,
	LowExpr arg1,
) {
	LowExpr unopt() =>
		LowExpr(type, range, LowExprKind(allocate(ctx. alloc, LowExprKind.SpecialBinary(kind, [arg0, arg1]))));

	switch (kind) {
		case BuiltinBinary.addPtrAndNat64:
			return isEmptyType(*ctx.allTypes, asPtrRawPointee(arg0.type))
				? genLetTempNoGcRoot(ctx.alloc, range, nextTempLocalIndex(ctx), arg0, (LowExpr getA) =>
					genSeq(ctx.alloc, range, genDrop(ctx.alloc, range, arg1), getA))
				: unopt();
		case BuiltinBinary.unsafeDivNat64:
			if (arg1.kind.isA!Constant) {
				ulong divisor = arg1.kind.as!Constant.as!IntegralValue.asUnsigned;
				switch (divisor) {
					case 0:
						return genAbort(type, range);
					case 1:
						// This is not for performance but to work around a bug dividing by 1 in Mir.
						// See https://github.com/vnmakarov/mir/issues/393
						return arg0;
					default:
						return unopt();
				}
			} else
				return unopt();
		default:
			return unopt();
	}
}

LowExpr genBuiltinBinaryLazy( // TODO: this should take exprPos as an arg. Or just do all this in concretize!---------------------
	ref GetLowExprCtx ctx,
	LowType type,
	UriAndRange range,
	BuiltinBinaryLazy kind,
	LowExpr arg0,
	LowExpr arg1,
) {
	final switch (kind) {
		case BuiltinBinaryLazy.boolAnd:
			return genIf(ctx.alloc, range, arg0, arg1, genFalse(range));
		case BuiltinBinaryLazy.boolOr:
			return genIf(ctx.alloc, range, arg0, genTrue(range), arg1);
		case BuiltinBinaryLazy.optionOr:
			return genOptionOrLike(ctx, ExprPos.nonTailNoGcRoots, range, arg0, arg1, (LowExpr x) => x);
		case BuiltinBinaryLazy.optionQuestion2:
			return genOptionOrLike(ctx, ExprPos.nonTailNoGcRoots, range, arg0, arg1, (LowExpr x) =>
				genUnionAs(type, range, allocate(ctx.alloc, x), 1));
	}
}
LowExpr genOptionOrLike(
	ref GetLowExprCtx ctx,
	ExprPos exprPos,
	UriAndRange range,
	LowExpr arg0,
	LowExpr arg1,
	in LowExpr delegate(LowExpr) @safe @nogc pure nothrow cbArg0NonEmpty,
) =>
	// x = arg0; x.kind == 1 ? cbArg0NonEmpty(x) : arg1
	genLetTempPossiblyGcRoot(ctx, exprPos, range, arg0, (ExprPos inner, LowExpr getArg0) =>
		handleExprPos(ctx, inner, genIf(ctx.alloc, range, genUnionKindEquals(ctx.alloc, range, getArg0, 1), cbArg0NonEmpty(getArg0), arg1)));

LowExpr getCreateArrayExpr(
	ref GetLowExprCtx ctx,
	ExprPos exprPos,
	in Locals locals,
	UriAndRange range,
	LowType arrType,
	ConcreteType concreteArrType,
	in ConcreteExprKind.CreateArray a,
) {
	// TODO: We need to make sure the array is on the stack, not just the pointer! So create it earlier! ---------------------------------------
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
	return genLetTempPossiblyGcRoot(ctx, exprPos, range, allocatePtr, (ExprPos inner, LowExpr getPtr) {
		LowExpr recur(LowExpr cur, size_t prevIndex) { // TODO: use applyNTimes? -------------------------------------------------------
			if (prevIndex == 0)
				return handleExprPos(ctx, inner, cur);
			else {
				size_t index = prevIndex - 1;
				LowExpr arg = getLowExpr(ctx, locals, a.args[index], ExprPos.nonTailNoGcRoots);
				LowExpr elementPtr = genAddPointer(
					ctx.alloc,
					elementPtrType.as!(LowType.PtrRawConst),
					range,
					getPtr,
					genConstantNat64(range, index));
				LowExpr writeToElement = genWriteToPointer(ctx.alloc, range, elementPtr, arg);
				return recur(genSeq(ctx.alloc, range, writeToElement, cur), index);
			}
		}
		return recur(genCreateRecord(ctx.alloc, arrType, range, [nElements, getPtr]), a.args.length);
	});
}

LowExpr getDropExpr(ref GetLowExprCtx ctx, in Locals locals, UriAndRange range, ref ConcreteExprKind.Drop a) =>
	genDrop(ctx.alloc, range, getLowExpr(ctx, locals, a.arg, ExprPos.nonTailNoGcRoots));

LowExpr getLambdaExpr(ref GetLowExprCtx ctx, in Locals locals, LowType type, UriAndRange range, in ConcreteExprKind.Lambda a) =>
	LowExpr(type, range, LowExprKind(allocate(ctx.alloc, LowExprKind.CreateUnion(
		a.memberIndex,
		has(a.closure)
			? getLowExpr(ctx, locals, *force(a.closure), ExprPos.nonTailNoGcRoots)
			: genVoid(range)))));

LowExpr getLetExpr(
	ref GetLowExprCtx ctx,
	in Locals locals,
	ExprPos exprPos,
	LowType type,
	UriAndRange range,
	ref ConcreteExprKind.Let a,
) =>
	genLetHandleAllocated(ctx, locals, exprPos, type, range, a.local, a.value, a.then, (LowExpr x) => x);

LowExpr genLetHandleAllocated(
	ref GetLowExprCtx ctx,
	in Locals locals,
	ExprPos exprPos,
	LowType type,
	UriAndRange range,
	ConcreteLocal* concreteLocal,
	ref ConcreteExpr concreteValue,
	ref ConcreteExpr concreteThen,
	in LowExpr delegate(LowExpr) @safe @nogc pure nothrow cbModifyThen,
) {
	LowExpr valueByVal = getLowExpr(ctx, locals, concreteValue, ExprPos.nonTailNoGcRoots);
	return withLowLocal!LowExpr(ctx, locals, concreteLocal, (in Locals innerLocals, LowLocal* local) =>
		LowExpr(type, range, LowExprKind(allocate(ctx.alloc, LowExprKind.Let(
			local,
			concreteLocal.isAllocated
				? getAllocExpr2(ctx, ExprPos.nonTailNoGcRoots, getLowGcPtrType(ctx.typeCtx, valueByVal.type), range, valueByVal)
				: valueByVal,
			cbModifyThen(getLowExpr(ctx, innerLocals, concreteThen, exprPos)))))));
}

LowExpr getLocalGetExpr(
	ref GetLowExprCtx ctx,
	in Locals locals,
	LowType type,
	UriAndRange range,
	in ConcreteExprKind.LocalGet a,
) {
	LowLocal* local = getLocal(ctx, locals, a.local);
	LowExpr localGet = genLocalGet(range, local);
	return a.local.isAllocated ? genDerefGcPointer(ctx.alloc, range, localGet) : localGet;
}

LowExpr getPtrToLocalExpr(
	ref GetLowExprCtx ctx,
	in Locals locals,
	LowType type,
	UriAndRange range,
	in ConcreteExprKind.PtrToLocal a,
) {
	LowLocal* local = getLocal(ctx, locals, a.local);
	return LowExpr(type, range, a.local.isAllocated
		? LowExprKind(allocate(ctx.alloc, LowExprKind.PtrCast(
			LowExpr(local.type, range, LowExprKind(LowExprKind.LocalGet(local))))))
		: LowExprKind(LowExprKind.PtrToLocal(local)));
}

LowExpr getLocalSetExpr(
	ref GetLowExprCtx ctx,
	in Locals locals,
	UriAndRange range,
	ref ConcreteExprKind.LocalSet a,
) {
	LowLocal* local = getLocal(ctx, locals, a.local);
	LowExpr value = getLowExpr(ctx, locals, a.value, ExprPos.nonTailNoGcRoots);
	return a.local.isAllocated
		? genWriteToPointer(ctx.alloc, range, genLocalGet(range, local), value)
		: genLocalSet(ctx.alloc, range, local, value);
}

LowExpr getMatchIntegralExpr(
	ref GetLowExprCtx ctx,
	in Locals locals,
	ExprPos exprPos,
	LowType type,
	UriAndRange range,
	ref ConcreteExprKind.MatchEnumOrIntegral a,
) =>
	LowExpr(type, range, LowExprKind(allocate(ctx.alloc, LowExprKind.Switch(
		value: getLowExpr(ctx, locals, a.matched, ExprPos.nonTailNoGcRoots),
		caseValues: a.caseValues,
		caseExprs: map!(LowExpr, ConcreteExpr)(ctx.alloc, a.caseExprs, (ref ConcreteExpr case_) =>
			getLowExpr(ctx, locals, case_, exprPos)),
		default_: has(a.else_)
			? getLowExpr(ctx, locals, *force(a.else_), exprPos)
			: genAbort(type, range)))));

LowExpr withLetTempNoGcRoot(
	ref GetLowExprCtx ctx,
	in Locals locals,
	ref ConcreteExpr expr,
	in LowExpr delegate(LowExpr) @safe @nogc pure nothrow cb,
) =>
	genLetTempNoGcRoot(ctx.alloc, expr.range, nextTempLocalIndex(ctx), getLowExpr(ctx, locals, expr, ExprPos.nonTailNoGcRoots), cb);

LowExpr getMatchStringLikeExpr(
	ref GetLowExprCtx ctx,
	in Locals locals,
	ExprPos exprPos,
	UriAndRange range,
	ref ConcreteExprKind.MatchStringLike a,
) =>
	// We don't need a GC root for 'matched' since we use it immediately without yielding
	withLetTempNoGcRoot(ctx, locals, a.matched, (LowExpr matched) =>
		foldReverse!(LowExpr, ConcreteExprKind.MatchStringLike.Case)(
			getLowExpr(ctx, locals, a.else_, exprPos),
			a.cases,
			(LowExpr else_, ref ConcreteExprKind.MatchStringLike.Case case_) =>
				genIf(
					ctx.alloc,
					range,
					getCallEquals(ctx, range, a.equals, matched, getLowExpr(ctx, locals, case_.value, ExprPos.nonTailNoGcRoots)),
					getLowExpr(ctx, locals, case_.then, exprPos),
					else_)));

LowExpr getMatchUnionExpr(
	ref GetLowExprCtx ctx,
	in Locals locals,
	ExprPos exprPos,
	LowType type,
	UriAndRange range,
	ref ConcreteExprKind.MatchUnion a,
) =>
	// We don't need a  GC root for 'matched', since each case handles its argument GC root
	withLetTempNoGcRoot(ctx, locals, a.matched, (LowExpr getMatched) {
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
					genLetPossiblyGcRoot(
						ctx, range, local,
						genUnionAs(
							local.type, range, getMatched,
							safeToUint(memberIndices[caseIndex].asUnsigned)),
						exprPos,
						(ExprPos inner) => getLowExpr(ctx, newLocals, case_.then, exprPos)))
				: getLowExpr(ctx, locals, case_.then, exprPos)));

LowExpr getClosureCreateExpr(
	ref GetLowExprCtx ctx,
	in Locals locals,
	UriAndRange range,
	LowType type,
	in ConcreteExprKind.ClosureCreate a,
) =>
	LowExpr(type, range, LowExprKind(LowExprKind.CreateRecord(
		mapZip!(LowExpr, ConcreteVariableRef, LowField)(
			ctx.alloc, a.args, ctx.allTypes.allRecords[type.as!(LowType.Record)].fields,
			(ref ConcreteVariableRef x, ref LowField f) =>
				getVariableRefExprForClosure(ctx, locals, range, f.type, x)))));

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

LowExpr getClosureGetExpr(ref GetLowExprCtx ctx, UriAndRange range, ConcreteExprKind.ClosureGet a) {
	LowExpr getField = getClosureField(ctx, range, a.closureRef);
	final switch (a.referenceKind) {
		case ClosureReferenceKind.direct:
			return getField;
		case ClosureReferenceKind.allocated:
			return genDerefGcPointer(ctx.alloc, range, getField);
	}
}

LowExpr getClosureSetExpr(
	ref GetLowExprCtx ctx,
	in Locals locals,
	UriAndRange range,
	ref ConcreteExprKind.ClosureSet a,
) =>
	// Note: This doesn't write to a field, it gets a pointer from the field and writes to that
	genWriteToPointer(
		ctx.alloc,
		range,
		getClosureField(ctx, range, a.closureRef),
		getLowExpr(ctx, locals, a.value, ExprPos.nonTailNoGcRoots));

// NOTE: This does not dereference pointer for mutAllocated, getClosureGetExpr will do that
LowExpr getClosureField(ref GetLowExprCtx ctx, UriAndRange range, ConcreteClosureRef closureRef) {
	LowLocal* closureLocal = &ctx.lowParams[0];
	LowExpr* closureGet = allocate(ctx.alloc, genLocalGet(range, closureLocal));
	LowRecord record = ctx.allTypes.allRecords[asPtrGcPointee(closureLocal.type).as!(LowType.Record)];
	return LowExpr(record.fields[closureRef.fieldIndex].type, range, LowExprKind(
		LowExprKind.RecordFieldGet(closureGet, closureRef.fieldIndex)));
}

LowExpr getPtrToFieldExpr(
	ref GetLowExprCtx ctx,
	in Locals locals,
	LowType type,
	in UriAndRange range,
	ref ConcreteExpr target,
	size_t fieldIndex,
) =>
	LowExpr(type, range, LowExprKind(allocate(ctx.alloc,
		LowExprKind.PtrToField(getLowExpr(ctx, locals, target, ExprPos.nonTailNoGcRoots), fieldIndex))));

LowExpr getThrowExpr(
	ref GetLowExprCtx ctx,
	in Locals locals,
	UriAndRange range,
	LowType type,
	ref ConcreteExprKind.Throw a,
	ExprPos exprPos,
) {
	// Since we are throwing an exception, don't worry about popping GC roots since 'catch' should restore it.
	LowExpr callThrow = genCallNoGcRoots(ctx.alloc, voidType, range, ctx.commonFuns.throwImpl, [
		getLowExpr(ctx, locals, a.thrown, ExprPos.nonTailNoGcRoots)]);
	LowExpr res = type == voidType ? callThrow : genSeq(ctx.alloc, range, callThrow, genZeroed(type, range));
	return exprPos.kind == ExprPos.Kind.loop ? genLoopBreak(ctx.alloc, type, range, res) : res;
}

LowExpr getFinallyExpr(
	ref GetLowExprCtx ctx,
	ExprPos exprPos,
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
		TODO: NEED TO RESTORE GC ROOT HERE! ----------------------------------------------------------------------------------
		err = true
		zeroed
	res add-gc-root
	cur-jmp-buf := old-jmp-buf
	right
	if err
		rethrow-current-exception
	pop-gc-root
	res
	*/
	withRestorableJmpBuf(ctx, range, (LowExpr restoreCurJmpBuf) {
		LowLocal* err = genLocal(ctx.alloc, symbol!"err", nextTempLocalIndex(ctx), boolType);
		LowExpr res = genSetjmp(
			ctx, range,
			getLowExpr(ctx, locals, a.below, ExprPos.nonTailNoGcRoots),
			genSeq(
				ctx.alloc, range,
				genLocalSet(ctx.alloc, range, err, genTrue(range)),
				genZeroed(type, range)));
		LowExpr afterRes = genSeq(
			ctx.alloc, range,
			restoreCurJmpBuf,
			getLowExpr(ctx, locals, a.right, ExprPos.nonTailNoGcRoots),
			genIf(ctx.alloc, range, genLocalGet(range, err), genRethrowCurrentException(ctx, range), genVoid(range)));
		return genLetNoGcRoot(
			ctx.alloc, range, err,
			genFalse(range),
			genSeqThenReturnFirstPossiblyGcRoot(ctx, exprPos, range, res, afterRes));
	});

LowExpr getTryExpr(
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
			genSeqThenReturnFirstNoGcRoot( // 'tried' type can be a GC root, but 'restoreCurJmpBuf' never yields.
				ctx.alloc, range, nextTempLocalIndex(ctx),
				getLowExpr(ctx, locals, a.tried, exprPos),
				restoreCurJmpBuf));

LowExpr getTryLetExpr(
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
			has(a.local)
				? genLetHandleAllocated(
					ctx, locals, exprPos, type, range, force(a.local), a.value, a.then,
					(LowExpr then) => genSeq(ctx.alloc, range, restoreCurJmpBuf, then))
				: genSeq(
					ctx.alloc, range,
					genDrop(ctx.alloc, range, getLowExpr(ctx, locals, a.value, ExprPos.nonTailNoGcRoots)),
					restoreCurJmpBuf,
					getLowExpr(ctx, locals, a.then, exprPos)));

LowExpr getTryOrTryLetExpr(
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
		first-block
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

LowExpr withRestorableJmpBuf(
	ref GetLowExprCtx ctx,
	UriAndRange range,
	in LowExpr delegate(LowExpr restoreJmpBuf) @safe @nogc pure nothrow cb,
) =>
	// Don't need a GC root since 'set-cur-jmp-buf' never yields.
	genLetTempNoGcRoot(ctx.alloc, range, nextTempLocalIndex(ctx), genGetCurJmpBuf(ctx, range), (LowExpr oldJmpBuf) =>
		cb(genSetCurJmpBuf(ctx, range, oldJmpBuf)));

LowExpr genRethrowCurrentException(ref GetLowExprCtx ctx, UriAndRange range) =>
	genCallNoGcRoots(ctx.alloc, voidType, range, ctx.commonFuns.rethrowCurrentException, []);

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
	LowExpr storePtr = genPointerToLocal(jmpBuf, range, store);
	LowExpr then = genIf(
		ctx.alloc, range,
		genEqInt32(
			ctx.alloc, range,
			genCallNoGcRoots(ctx.alloc, int32Type, range, ctx.commonFuns.setjmp, [storePtr]),
			genConstantInt32(range, 0)),
		genSeq(ctx.alloc, range, genSetCurJmpBuf(ctx, range, storePtr), tried),
		onLongjmp);
	return genLetNoGcRoot(ctx.alloc, range, store, genZeroed(jmpBufTag, range), then);
}

LowExpr genEqInt32(ref Alloc alloc, UriAndRange range, LowExpr a, LowExpr b) =>
	LowExpr(boolType, range, LowExprKind(allocate(alloc, LowExprKind.SpecialBinary(BuiltinBinary.eqInt32, [a, b]))));

LowExpr genGetCurThrown(ref GetLowExprCtx ctx, UriAndRange range) =>
	genVarGet(ctx.commonFuns.exceptionType, range, ctx.commonFuns.curThrown);

LowExpr genGetCurJmpBuf(ref GetLowExprCtx ctx, UriAndRange range) =>
	genCallNoGcRoots(ctx.alloc, ctx.commonFuns.jmpBufType, range, ctx.commonFuns.curJmpBuf, []);

LowExpr genSetCurJmpBuf(ref GetLowExprCtx ctx, UriAndRange range, LowExpr value) =>
	genCallNoGcRoots(ctx.alloc, voidType, range, ctx.commonFuns.setCurJmpBuf, [value]);
