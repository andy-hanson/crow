module lower.lower;

@safe @nogc pure nothrow:

import backend.builtinMath : builtinForBinaryMath, builtinForUnaryMath;
import frontend.showModel : ShowCtx;
import lower.checkLowModel : checkLowProgram;
import lower.generateMarkVisitFun :
	getMarkRootForType,
	getMarkVisitForType,
	generateMarkRoot,
	generateMarkVisit,
	initMarkVisitFuns,
	MarkRoot,
	MarkVisitFuns;
import lower.lowExprHelpers :
	boolType,
	char8Type,
	gen4ary,
	genAbort,
	genAddPointer,
	genBinary,
	genBinaryMath,
	genBitwiseNegate,
	genCallFunPointerNoGcRoots,
	genCallNoGcRoots,
	genCreateRecordNoGcRoots,
	genConstantIntegral,
	genConstantNat64,
	genDrop,
	genEnumEq,
	genEnumIntersect,
	genEnumUnion,
	genFalse,
	genFunPointer,
	genIf,
	genLetNoGcRoot,
	genLetTempConstNoGcRoot,
	genLocal,
	genLocalByValue,
	genLocalGet,
	genLocalPointer,
	genLocalSet,
	genLoopContinue,
	genLoopBreak,
	genPointerCast,
	genRecordFieldGet,
	genRecordFieldPointer,
	genRecordFieldSetNoGcRoot,
	genSeq,
	genSeqThenReturnFirstNoGcRoot,
	genSizeOf,
	genTernary,
	genTrue,
	genUnary,
	genUnaryMath,
	genUnionAs,
	genUnionKind,
	genVarGet,
	genVarSet,
	genVoid,
	genWrapMulNat64,
	genWriteToPointer,
	genZeroed,
	int32Type,
	nat8Type,
	nat64Type,
	voidType;
import model.concreteModel :
	AllConstantsConcrete,
	ArrTypeAndConstantsConcrete,
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
	existsDirectChildExpr,
	mustBeByVal,
	name,
	PointerTypeAndConstantsConcrete,
	ReferenceKind;
import model.constant : Constant;
import model.lowModel :
	AllConstantsLow,
	AllLowTypes,
	ArrTypeAndConstantsLow,
	asGcPointee,
	asNonGcPointee,
	ConcreteFunToLowFunIndex,
	ExternLibraries,
	ExternLibrary,
	isPrimitiveType,
	isTuple,
	LowCommonTypes,
	LowExpr,
	LowExprKind,
	LowExternType,
	LowExternTypeIndex,
	LowField,
	LowFieldSource,
	LowFun,
	LowFunBody,
	LowFunExprBody,
	LowFunFlags,
	LowFunIndex,
	LowFunPointerType,
	LowFunPointerTypeIndex,
	LowFunSource,
	LowLocal,
	LowLocalSource,
	LowProgram,
	LowRecord,
	LowRecordIndex,
	LowVar,
	LowVarIndex,
	LowType,
	LowUnion,
	LowUnionIndex,
	PointerTypeAndConstantsLow,
	PrimitiveType,
	UpdateParam;
import model.model :
	Builtin4ary,
	BuiltinBinary,
	BuiltinBinaryLazy,
	BuiltinBinaryMath,
	BuiltinFun,
	BuiltinTernary,
	BuiltinType,
	BuiltinUnary,
	BuiltinUnaryMath,
	ConfigExternUris,
	EnumOrFlagsFunction,
	IntegralType,
	JsFun,
	Local,
	Program,
	VarKind;
import model.typeLayout : isEmptyType;
import util.alloc.alloc : Alloc;
import util.col.arrayBuilder : add, addAndGetIndex, ArrayBuilder, buildArray, Builder, finish;
import util.col.array :
	applyNTimes,
	emptySmallArray,
	every,
	exists,
	foldReverse,
	foldReverseWithIndex,
	indexOfPointer,
	isEmpty,
	map,
	mapPointersWithIndex,
	mapWithIndex,
	mapZipPtrFirst,
	newSmallArray,
	only,
	only2,
	small,
	SmallArray,
	zipPtrFirst;
import util.col.map : KeyValuePair, makeMapFromKeysOptional, makeMapWithIndex, mustGet, Map;
import util.col.fullIndexMap : FullIndexMap, fullIndexMapOfArr;
import util.col.mutArr : moveToArray, mustPop, MutArr, mutArrIsEmpty, mutArrSize, push;
import util.col.mutMap : getOrAdd, moveToMap, mustAdd, mustGet, MutMap, MutMap;
import util.col.mutMultiMap : add, eachKey, eachValueForKey, MutMultiMap;
import util.col.stackMap : StackMap, stackMapAdd, stackMapMustGet, withStackMap;
import util.conv : safeToUint;
import util.integralValues : IntegralValue, IntegralValues, singleIntegralValue;
import util.late : Late, late, lateGet, lateIsSet, lateSet;
import util.memory : allocate;
import util.opt : flattenOption, force, has, none, Opt, optIf, some;
import util.perf : Perf, PerfMeasure, withMeasure;
import util.sourceRange : UriAndRange;
import util.symbol : Symbol, symbol, symbolOfEnum;
import util.union_ : Union;
import util.uri : Uri;
import util.util : castNonScope_ref, enumConvert, ptrTrustMe;
import versionInfo : isVersion, VersionFun;

LowProgram lower(
	scope ref Perf perf,
	ref Alloc alloc,
	in ShowCtx showCtx,
	in ConfigExternUris configExtern,
	ref Program program,
	ref ConcreteProgram a,
) =>
	withMeasure!(LowProgram, () =>
		lowerInner(alloc, showCtx, configExtern, program, a)
	)(perf, alloc, PerfMeasure.lower);

private LowProgram lowerInner(
	ref Alloc alloc,
	in ShowCtx showCtx,
	in ConfigExternUris configExtern,
	ref Program program,
	ref ConcreteProgram a,
) {
	GetLowTypeCtx getLowTypeCtx = getAllLowTypes(alloc, a);
	LowType catchPointConstPointerType = lowTypeFromConcreteType(getLowTypeCtx, a.commonFuns.curCatchPoint.returnType);
	LowType nat64MutPointer = getPointerMut(getLowTypeCtx, nat64Type);
	LowCommonTypes commonTypes = LowCommonTypes(
		catchPointConstPointer: catchPointConstPointerType,
		catchPointMutPointer: LowType(LowType.PointerMut(catchPointConstPointerType.as!(LowType.PointerConst).pointee)),
		fiberReference: lowTypeFromConcreteType(getLowTypeCtx, a.commonFuns.fiberReferenceType),
		nat8ConstPointer: getPointerConst(getLowTypeCtx, nat8Type),
		nat8MutPointer: getPointerMut(getLowTypeCtx, nat8Type),
		nat64MutPointer: nat64MutPointer,
		nat64MutPointerMutPointer: getPointerMut(getLowTypeCtx, nat64MutPointer));
	immutable FullIndexMap!(LowVarIndex, LowVar) vars = getAllLowVars(alloc, getLowTypeCtx, a.allVars);
	AllLowFuns allFuns = getAllLowFuns(alloc, showCtx, getLowTypeCtx, commonTypes, configExtern, a, vars);
	AllConstantsLow allConstants = convertAllConstants(getLowTypeCtx, a.allConstants);
	LowProgram res = LowProgram(
		a.version_,
		allFuns.concreteFunToLowFunIndex,
		allConstants,
		commonTypes,
		vars,
		getLowTypeCtx.allTypes,
		allFuns.allLowFuns,
		allFuns.main,
		allFuns.allExternLibraries);
	checkLowProgram(showCtx, program, a, res);
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
		return ArrTypeAndConstantsLow(arrType.as!(LowRecord*), elementType, it.constants);
	});
	PointerTypeAndConstantsLow[] records = map(ctx.alloc, a.pointers, (ref PointerTypeAndConstantsConcrete it) =>
		PointerTypeAndConstantsLow(lowTypeFromConcreteStruct(ctx, it.pointeeType), it.constants));
	return AllConstantsLow(a.cStrings, arrs, records);
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
	AllLowTypes allTypes;
	private:
	// Meaning of the value depends on the kind of ConcreteStruct; it might be a LowRecordIndex for example.
	Map!(immutable ConcreteStruct*, immutable uint) lowIndices;
	MutMap!(LowType, LowType*) typeToAllocated;

	ref Alloc alloc() return scope =>
		*allocPtr;
}

LowType* allocateLowType(ref GetLowTypeCtx ctx, LowType a) =>
	getOrAdd(ctx.alloc, ctx.typeToAllocated, a, () =>
		allocate(ctx.alloc, a));

LowType getPointerGc(ref GetLowTypeCtx ctx, LowType pointee) =>
	LowType(LowType.PointerGc(allocateLowType(ctx, pointee)));

LowType getPointerConst(ref GetLowTypeCtx ctx, LowType pointee) =>
	LowType(LowType.PointerConst(allocateLowType(ctx, pointee)));

LowType getPointerMut(ref GetLowTypeCtx ctx, LowType pointee) =>
	LowType(LowType.PointerMut(allocateLowType(ctx, pointee)));

GetLowTypeCtx getAllLowTypes(ref Alloc alloc, in ConcreteProgram program) {
	ArrayBuilder!LowExternType externTypesBuilder;
	ArrayBuilder!LowFunPointerType funPointerTypesBuilder;
	ArrayBuilder!LowRecord recordsBuilder;
	ArrayBuilder!LowUnion unionsBuilder;
	Map!(immutable ConcreteStruct*, immutable uint) indices =
		makeMapFromKeysOptional!(ConcreteStruct*, uint)(alloc, program.allStructs, (immutable ConcreteStruct* source) =>
			source.body_.matchIn!(Opt!uint)(
				(in ConcreteStructBody.Builtin x) {
					switch (x.kind) {
						case BuiltinType.array:
						case BuiltinType.mutArray:
							return some(addAndGetIndex(alloc, recordsBuilder, LowRecord(source)));
						case BuiltinType.catchPoint:
							return some(addAndGetIndex(alloc, externTypesBuilder, LowExternType(source)));
						case BuiltinType.funPointer:
							return some(addAndGetIndex(alloc, funPointerTypesBuilder, LowFunPointerType(source)));
						default:
							return none!uint;
					}
				},
				(in ConcreteStructBody.Enum x) =>
					none!uint,
				(in ConcreteStructBody.Extern x) =>
					some(addAndGetIndex(alloc, externTypesBuilder, LowExternType(source))),
				(in ConcreteStructBody.Flags x) =>
					none!uint,
				(in ConcreteStructBody.Record) =>
					some(addAndGetIndex(alloc, recordsBuilder, LowRecord(source))),
				(in ConcreteStructBody.Union) =>
					some(addAndGetIndex(alloc, unionsBuilder, LowUnion(source)))));

	immutable FullIndexMap!(LowExternTypeIndex, LowExternType) allExternTypes =
		fullIndexMapOfArr!(LowExternTypeIndex, LowExternType)(finish(alloc, externTypesBuilder));
	immutable FullIndexMap!(LowFunPointerTypeIndex, LowFunPointerType) allFunPointerTypes =
		fullIndexMapOfArr!(LowFunPointerTypeIndex, LowFunPointerType)(finish(alloc, funPointerTypesBuilder));
	immutable FullIndexMap!(LowRecordIndex, LowRecord) allRecords =
		fullIndexMapOfArr!(LowRecordIndex, LowRecord)(finish(alloc, recordsBuilder));
	immutable FullIndexMap!(LowUnionIndex, LowUnion) allUnions =
		fullIndexMapOfArr!(LowUnionIndex, LowUnion)(finish(alloc, unionsBuilder));

	GetLowTypeCtx getLowTypeCtx = GetLowTypeCtx(
		ptrTrustMe(alloc),
		AllLowTypes(allExternTypes, allFunPointerTypes, allRecords, allUnions),
		indices);

	foreach (ref LowRecord record; allRecords)
		record.fields = makeRecordFields(getLowTypeCtx, record);
	foreach (ref LowFunPointerType funPointer; allFunPointerTypes) {
		ConcreteType[2] typeArgs = only2(funPointer.source.body_.as!(ConcreteStructBody.Builtin*).typeArgs);
		funPointer.returnType = lowTypeFromConcreteType(getLowTypeCtx, typeArgs[0]),
		funPointer.paramTypes = maybeUnpackTuple(alloc, lowTypeFromConcreteType(getLowTypeCtx, typeArgs[1]));
	}
	foreach (ref LowUnion union_; allUnions)
		union_.members = map!(LowType, ConcreteType)(
			alloc,
			union_.source.body_.as!(ConcreteStructBody.Union).members,
			(ref ConcreteType member) => lowTypeFromConcreteType(getLowTypeCtx, member));

	return getLowTypeCtx;
}

SmallArray!LowField makeRecordFields(ref GetLowTypeCtx getLowTypeCtx, ref LowRecord record) {
	if (record.source.body_.isA!(ConcreteStructBody.Builtin*)) {
		ConcreteStructBody.Builtin* builtin = record.source.body_.as!(ConcreteStructBody.Builtin*);
		assert(lowersToArray(builtin.kind));
		LowType elementType = builtin.kind == BuiltinType.string_
			? char8Type
			: lowTypeFromConcreteType(getLowTypeCtx, only(builtin.typeArgs));
		return newSmallArray(getLowTypeCtx.alloc, [
			LowField(LowFieldSource(LowFieldSource.ArrayField.size), 0, nat64Type),
			LowField(
				LowFieldSource(LowFieldSource.ArrayField.pointer),
				8,
				builtin.kind == BuiltinType.mutArray
					? getPointerMut(getLowTypeCtx, elementType)
					: getPointerConst(getLowTypeCtx, elementType))]);
	} else
		return mapZipPtrFirst!(LowField, ConcreteField, immutable uint)(
			getLowTypeCtx.alloc,
			record.source.body_.as!(ConcreteStructBody.Record).fields,
			record.source.fieldOffsets,
			(ConcreteField* field, immutable uint fieldOffset) =>
				LowField(LowFieldSource(field), fieldOffset, lowTypeFromConcreteType(getLowTypeCtx, field.type)));
}
bool lowersToArray(BuiltinType a) =>
	a == BuiltinType.array || a == BuiltinType.mutArray || a == BuiltinType.string_;

SmallArray!LowType maybeUnpackTuple(ref Alloc alloc, LowType a) {
	Opt!(SmallArray!LowType) res = tryUnpackTuple(alloc, a);
	return has(res) ? force(res) : newSmallArray!LowType(alloc, [a]);
}

Opt!(SmallArray!LowType) tryUnpackTuple(ref Alloc alloc, LowType a) {
	if (isPrimitiveType(a, PrimitiveType.void_))
		return some(emptySmallArray!LowType);
	else if (a.isA!(LowRecord*)) {
		LowRecord* record = a.as!(LowRecord*);
		return isTuple(*record)
			? some(map!(LowType, LowField)(alloc, record.fields, (ref LowField x) => x.type))
			: none!(SmallArray!LowType);
	} else
		return none!(SmallArray!LowType);
}

PrimitiveType typeOfIntegralType(IntegralType a) =>
	enumConvert!PrimitiveType(a);

LowType lowTypeFromConcreteStruct(ref GetLowTypeCtx ctx, in ConcreteStruct* struct_) {
	uint lowIndex() => mustGet(ctx.lowIndices, struct_);
	LowType record() => LowType(&ctx.allTypes.allRecords[LowRecordIndex(lowIndex)]);
	return struct_.body_.matchIn!LowType(
		(in ConcreteStructBody.Builtin x) {
			final switch (x.kind) {
				case BuiltinType.bool_:
					return LowType(PrimitiveType.bool_);
				case BuiltinType.catchPoint:
					return LowType(&ctx.allTypes.allExternTypes[LowExternTypeIndex(lowIndex)]);
				case BuiltinType.char8:
					return LowType(PrimitiveType.char8);
				case BuiltinType.char32:
					return LowType(PrimitiveType.char32);
				case BuiltinType.float32:
					return LowType(PrimitiveType.float32);
				case BuiltinType.float64:
					return LowType(PrimitiveType.float64);
				case BuiltinType.funPointer:
					return LowType(&ctx.allTypes.allFunPointerTypes[LowFunPointerTypeIndex(lowIndex)]);
				case BuiltinType.int8:
					return LowType(PrimitiveType.int8);
				case BuiltinType.int16:
					return LowType(PrimitiveType.int16);
				case BuiltinType.int32:
					return LowType(PrimitiveType.int32);
				case BuiltinType.int64:
					return LowType(PrimitiveType.int64);
				case BuiltinType.array:
				case BuiltinType.mutArray:
					return record();
				case BuiltinType.future: // Concretize replaces this with 'future-impl'
				case BuiltinType.jsAny: // JS builds don't concretize/lower
				case BuiltinType.lambda: // Lambda is compiled away by concretize
					assert(false);
				case BuiltinType.nat8:
					return LowType(PrimitiveType.nat8);
				case BuiltinType.nat16:
					return LowType(PrimitiveType.nat16);
				case BuiltinType.nat32:
					return LowType(PrimitiveType.nat32);
				case BuiltinType.nat64:
					return LowType(PrimitiveType.nat64);
				case BuiltinType.pointerConst:
					return getPointerConst(ctx, lowTypeFromConcreteType(ctx, only(x.typeArgs)));
				case BuiltinType.pointerMut:
					return getPointerMut(ctx, lowTypeFromConcreteType(ctx, only(x.typeArgs)));
				case BuiltinType.string_:
				case BuiltinType.symbol:
					// concretize turns string into 'char array' and symbol into 'char*'
					assert(false);
				case BuiltinType.void_:
					return LowType(PrimitiveType.void_);
			}
		},
		(in ConcreteStructBody.Enum x) =>
			LowType(typeOfIntegralType(x.storage)),
		(in ConcreteStructBody.Extern x) =>
			LowType(&ctx.allTypes.allExternTypes[LowExternTypeIndex(lowIndex)]),
		(in ConcreteStructBody.Flags x) =>
			LowType(typeOfIntegralType(x.storage)),
		(in ConcreteStructBody.Record) =>
			record(),
		(in ConcreteStructBody.Union) =>
			LowType(&ctx.allTypes.allUnions[LowUnionIndex(lowIndex)]));
}

LowType lowTypeFromConcreteType(ref GetLowTypeCtx ctx, in ConcreteType type) {
	LowType inner = lowTypeFromConcreteStruct(ctx, type.struct_);
	final switch (type.reference) {
		case ReferenceKind.byVal:
			return inner;
		case ReferenceKind.byRef:
			return getPointerGc(ctx, inner);
	}
}

// TODO: I could just save generating all MarkRoot / MarkVisit funs to the end, then not need this?
public immutable struct LowFunCause {
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
	in ShowCtx showCtx,
	ref GetLowTypeCtx getLowTypeCtx,
	ref LowCommonTypes commonTypes,
	in ConfigExternUris configExtern,
	ref ConcreteProgram program,
	in immutable FullIndexMap!(LowVarIndex, LowVar) allVars,
) {
	MutConcreteFunToLowFunIndex concreteFunToLowFunIndex;
	MutArr!LowFunCause lowFunCauses;
	MarkVisitFuns markVisitFuns = initMarkVisitFuns(alloc, ptrTrustMe(getLowTypeCtx.allTypes), ptrTrustMe(commonTypes));
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
					Opt!MarkRoot res = getMarkRootForType(
						getLowTypeCtx.alloc, lowFunCauses, markVisitFuns,
						lowTypeFromConcreteType(getLowTypeCtx, only(x.typeArgs)));
					return optIf(has(res), () =>
						force(res).fun);
				} else if (x.kind.isA!(BuiltinFun.MarkVisit)) {
					if (!lateIsSet(markCtxTypeLate))
						lateSet(markCtxTypeLate, lowTypeFromConcreteType(
							getLowTypeCtx,
							fun.params[0].type));
					return getMarkVisitForType(
						getLowTypeCtx.alloc, lowFunCauses, markVisitFuns,
						lowTypeFromConcreteType(getLowTypeCtx, only(x.typeArgs)));
				} else {
					if (!isVersion(program.version_, VersionFun.isInterpreted) &&
							(x.kind.isA!BuiltinUnaryMath || x.kind.isA!BuiltinBinaryMath))
						addExternSymbol(symbol!"m", x.kind.isA!BuiltinUnaryMath
							? symbolOfEnum(builtinForUnaryMath(x.kind.as!BuiltinUnaryMath))
							: symbolOfEnum(builtinForBinaryMath(x.kind.as!BuiltinBinaryMath)));
					return none!LowFunIndex;
				}
			},
			(EnumOrFlagsFunction _) =>
				none!LowFunIndex,
			(ConcreteFunBody.Extern x) {
				Opt!Symbol optName = name(*fun);
				addExternSymbol(x.libraryName, force(optName));
				return some(addLowFun(alloc, lowFunCauses, LowFunCause(fun)));
			},
			(ConcreteExpr x) =>
				some(addLowFun(alloc, lowFunCauses, LowFunCause(fun))),
			(ConcreteFunBody.FlagsFn) =>
				none!LowFunIndex,
			(ConcreteFunBody.VarGet x) =>
				none!LowFunIndex,
			(ConcreteFunBody.VarSet) =>
				none!LowFunIndex,
			(ConcreteFunBody.Deferred) =>
				assert(false));
		if (has(opIndex))
			mustAdd(getLowTypeCtx.alloc, concreteFunToLowFunIndex, fun, force(opIndex));
	}

	LowType markCtxType = lateIsSet(markCtxTypeLate) ? lateGet(markCtxTypeLate) : voidType;

	LowType userMainFunPointerType =
		lowTypeFromConcreteType(getLowTypeCtx, program.commonFuns.rtMain.params[2].type);

	//TODO: use temp alloc
	VarIndices varIndices = makeMapWithIndex!(immutable ConcreteVar*, LowVarIndex, immutable ConcreteVar*)(
		getLowTypeCtx.alloc, program.allVars, (size_t i, in immutable ConcreteVar* x) =>
			immutable KeyValuePair!(immutable ConcreteVar*, LowVarIndex)(x, LowVarIndex(i)));

	LowType gcRootMutPointerType = lowTypeFromConcreteType(getLowTypeCtx, program.commonFuns.gcRoot.returnType);
	LowType gcRootType = *gcRootMutPointerType.as!(LowType.PointerMut).pointee;

	LowCommonFuns commonFuns = LowCommonFuns(
		alloc: mustGet(concreteFunToLowFunIndex, program.commonFuns.alloc),
		curCatchPoint: mustGet(concreteFunToLowFunIndex, program.commonFuns.curCatchPoint),
		setCurCatchPoint: mustGet(concreteFunToLowFunIndex, program.commonFuns.setCurCatchPoint),
		commonTypes: commonTypes,
		curThrown: mustGet(varIndices, program.commonFuns.curThrown),
		exceptionType: lowTypeFromConcreteType(getLowTypeCtx, program.commonFuns.curThrown.type),
		mark: mustGet(concreteFunToLowFunIndex, program.commonFuns.mark),
		rethrowCurrentException: mustGet(concreteFunToLowFunIndex, program.commonFuns.rethrowCurrentException),
		throwImpl: mustGet(concreteFunToLowFunIndex, program.commonFuns.throwImpl),
		gcRoot: mustGet(concreteFunToLowFunIndex, program.commonFuns.gcRoot),
		gcRootType: gcRootType,
		gcRootMutPointerType: gcRootMutPointerType,
		markRootFunPointerType: gcRootType.as!(LowRecord*).fields[1].type,
		setGcRoot: mustGet(concreteFunToLowFunIndex, program.commonFuns.setGcRoot),
		popGcRoot: mustGet(concreteFunToLowFunIndex, program.commonFuns.popGcRoot));

	MutArr!LowFun allLowFuns;
	// New LowFuns will be discovered while compiling and added to lowFunCauses
	for (size_t index = 0; index < mutArrSize(lowFunCauses); index++) {
		push(alloc, allLowFuns, lowFunFromCause(
			showCtx,
			program,
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
		main: LowFunIndex(mutArrSize(lowFunCauses)),
		allExternLibraries: getExternLibraries(getLowTypeCtx.alloc, externLibraryToNames, configExtern));
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
			libraries ~= ExternLibrary(library, flattenOption!Uri(configExtern[library]), names);
		});
	});

alias VarIndices = Map!(immutable ConcreteVar*, LowVarIndex);

// Functions that we generate calls to when compiling
struct LowCommonFuns {
	LowCommonTypes commonTypes;

	LowFunIndex alloc;
	LowFunIndex curCatchPoint;
	LowFunIndex setCurCatchPoint;
	LowVarIndex curThrown;
	LowType exceptionType;
	LowFunIndex mark;
	LowFunIndex rethrowCurrentException;
	LowFunIndex throwImpl;

	LowFunIndex gcRoot;
	LowType gcRootType;
	LowType gcRootMutPointerType;
	LowType markRootFunPointerType;
	LowFunIndex setGcRoot;
	LowFunIndex popGcRoot;
}

LowFun lowFunFromCause(
	in ShowCtx showCtx,
	ref ConcreteProgram concreteProgram,
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
			SmallArray!LowLocal params = mapPointersWithIndex!(LowLocal, ConcreteLocal)(
				getLowTypeCtx.alloc, cf.params, (size_t i, ConcreteLocal* x) =>
					getLowLocalForParameter(getLowTypeCtx, i, x));
			LowFunBody body_ = getLowFunBody(
				showCtx,
				concreteProgram,
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
			generateMarkRoot(
				getLowTypeCtx.alloc, getLowTypeCtx, lowFunCauses, markVisitFuns, markCtxType, commonFuns.mark, x.type),
		(LowFunCause.MarkVisit x) =>
			generateMarkVisit(getLowTypeCtx.alloc, lowFunCauses, markVisitFuns, markCtxType, commonFuns.mark, x.type));

LowFun mainFun(ref GetLowTypeCtx ctx, LowFunIndex rtMainIndex, ConcreteFun* userMain, LowType userMainFunPointerType) {
	LowType char8PointerPointer = getPointerConst(ctx, getPointerConst(ctx, char8Type));
	SmallArray!LowLocal params = newSmallArray!LowLocal(ctx.alloc, [
		genLocalByValue(ctx.alloc, symbol!"argc", isMutable: false, 0, int32Type),
		genLocalByValue(ctx.alloc, symbol!"argv", isMutable: false, 1, char8PointerPointer)]);
	LowExpr userMainFunPointer =
		genFunPointer(userMainFunPointerType, UriAndRange.empty, userMain);
	LowExpr call = genCallNoGcRoots(ctx.alloc, int32Type, UriAndRange.empty, rtMainIndex, [
		genLocalGet(UriAndRange.empty, &params[0]),
		genLocalGet(UriAndRange.empty, &params[1]),
		userMainFunPointer
	]);
	LowFunBody body_ = LowFunBody(LowFunExprBody(LowFunFlags.none, call));
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
			LowLocalSource(allocate(alloc, LowLocalSource.Generated(symbol!"closure", isMutable: false, getIndex()))),
		(ConcreteLocalSource.Generated x) {
			bool isMutable = () {
				final switch (x) {
					case ConcreteLocalSource.Generated.args:
					case ConcreteLocalSource.Generated.ignore:
					case ConcreteLocalSource.Generated.destruct:
					case ConcreteLocalSource.Generated.member:
					case ConcreteLocalSource.Generated.reference:
						return false;
				}
			}();
			return LowLocalSource(allocate(alloc, LowLocalSource.Generated(symbolOfEnum(x), isMutable, getIndex())));
		});

T withLowLocal(T)(
	ref GetLowExprCtx ctx,
	in Locals locals,
	ConcreteLocal* concreteLocal,
	in T delegate(in Locals, LowLocal*) @safe @nogc pure nothrow cb,
) {
	LowType type = lowTypeFromConcreteType(ctx.typeCtx, concreteLocal.type);
	LowLocal* local = allocate(ctx.alloc, LowLocal(getLowLocalSource(ctx, concreteLocal.source), type));
	return cb(addLocal(locals, concreteLocal, local), local);
}

LowFunBody getLowFunBody(
	in ShowCtx showCtx,
	ref ConcreteProgram concreteProgram,
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
			ptrTrustMe(showCtx),
			thisFunIndex,
			ptrTrustMe(concreteProgram),
			castNonScope_ref(staticSymbols),
			ptrTrustMe(getLowTypeCtx),
			ptrTrustMe(lowFunCauses),
			ptrTrustMe(markVisitFuns),
			ptrTrustMe(concreteFunToLowFunIndex),
			commonFuns,
			castNonScope_ref(varIndices),
			a.params,
			params,
			curFunIsYielding: a in concreteProgram.yieldingFuns,
			hasSetupCatch: false,
			hasTailRecur: false,
			tempLocalIndex: a.params.length);
		LowExpr body_ = withStackMap!(LowExpr, ConcreteLocal*, LowLocal*)((ref Locals locals) =>
			getLowExpr(exprCtx, locals, expr, ExprPos(0, ExprPos.Kind.tail)));
		return LowFunBody(LowFunExprBody(
			LowFunFlags(
				hasSetupCatch: exprCtx.hasSetupCatch,
				hasTailRecur: exprCtx.hasTailRecur,
				mayYield: exprCtx.curFunIsYielding),
			body_));
	}
}

LowExpr genLetPossiblyGcRoot(
	ref GetLowExprCtx ctx,
	in UriAndRange range,
	LowLocal* local,
	LowExpr init,
	ExprPos exprPos,
	bool thenMayYield,
	in LowExpr delegate(ExprPos) @safe @nogc pure nothrow cbThen,
) =>
	genLetNoGcRoot(ctx.alloc, range, local, init, maybeAddGcRoot(ctx, range, local, exprPos, thenMayYield, cbThen));

LowExpr genLetTempPossiblyGcRoot(
	ref GetLowExprCtx ctx,
	ExprPos exprPos,
	in UriAndRange range,
	LowExpr value,
	bool thenMayYield,
	in LowExpr delegate(ExprPos, LowExpr) @safe @nogc pure nothrow cbThen,
) {
	LowLocal* local = genLocal(ctx.alloc, symbol!"temp", isMutable: false, nextTempLocalIndex(ctx), value.type);
	return genLetPossiblyGcRoot(ctx, range, local, value, exprPos, thenMayYield, (ExprPos inner) =>
		cbThen(inner, genLocalGet(range, local)));
}

LowExpr genSeqThenReturnFirstPossiblyGcRoot(
	ref GetLowExprCtx ctx,
	ExprPos exprPos,
	in UriAndRange range,
	LowExpr a,
	LowExpr b,
	bool bMayYield,
) =>
	genLetTempPossiblyGcRoot(ctx, exprPos, range, a, bMayYield, (ExprPos inner, LowExpr getA) =>
		genSeq(ctx.alloc, range, b, handleExprPos(ctx, inner, getA)));

LowExpr withPushAllGcRoots(
	ref GetLowExprCtx ctx,
	in Locals locals,
	in UriAndRange range,
	ExprPos exprPos,
	bool isYieldingCall,
	in ConcreteExpr[] args,
	in LowExpr delegate(ExprPos, LowExpr[]) @safe @nogc pure nothrow cb,
) {
	LowExpr[] lowArgs = map!(LowExpr, ConcreteExpr)(ctx.alloc, args, (ref ConcreteExpr x) =>
		getLowExpr(ctx, locals, x, ExprPos.nonTail));
	bool hasYield = isYieldingCall || exists!ConcreteExpr(args, (ref ConcreteExpr x) => expressionMayYield(ctx, x));
	bool hasRoot = exists!LowExpr(lowArgs, (ref LowExpr x) =>
		has(getMarkRootForType(ctx.alloc, *ctx.lowFunCauses, *ctx.markVisitFuns, x.type)));
	if (hasYield && hasRoot) {
		ArrayBuilder!LowExpr argGetters;
		return genWithGcRootsRecur(ctx, exprPos, range, lowArgs, argGetters, cb);
	} else
		return cb(exprPos, lowArgs);
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
		: genLetTempPossiblyGcRoot(ctx, exprPos, range, args[0], true, (ExprPos inner, LowExpr getArg0) {
			add(ctx.alloc, argGetters, getArg0);
			return genWithGcRootsRecur(ctx, inner, range, args[1 .. $], argGetters, cb);
		});

// Wraps 'expr' in code to push a GC root for 'local' and pop it when done
LowExpr maybeAddGcRoot(
	ref GetLowExprCtx ctx,
	in UriAndRange range,
	LowLocal* local,
	ExprPos exprPos,
	bool mayYield,
	in LowExpr delegate(ExprPos) @safe @nogc pure nothrow cbThen,
) {
	if (mayYield) assert(ctx.curFunIsYielding);
	Opt!MarkRoot optMarkRoot = mayYield
		? getMarkRootForType(ctx.alloc, *ctx.lowFunCauses, *ctx.markVisitFuns, local.type)
		: none!MarkRoot;
	if (!has(optMarkRoot)) return cbThen(exprPos);
	MarkRoot markRoot = force(optMarkRoot);

	LowExpr pointerToLocal = () {
		final switch (markRoot.kind) {
			case MarkRoot.Kind.localAlreadyPointer:
				return genLocalGet(range, local);
			case MarkRoot.Kind.pointerToLocal:
				return genLocalPointer(getPointerMut(ctx.typeCtx, local.type), range, local);
		}
	}();
	LowExpr markRootFunction = () {
		LowType funType = ctx.commonFuns.markRootFunPointerType;
		// TODO: 'funType' is not the correct type for 'markRoot.fun' if we need to cast it for 'localAlreadyPointer'
		LowExpr fun = genFunPointer(funType, range, markRoot.fun);
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
	LowExpr initRoot = genCreateRecordNoGcRoots(ctx.alloc, ctx.commonFuns.gcRootType, range, [
		genPointerCast(ctx.alloc, getPointerConst(ctx.typeCtx, voidType), range, pointerToLocal),
		markRootFunction,
		genGetGcRoot(ctx, range)]);
	LowLocal* root = genLocal(
		ctx.alloc, symbol!"root", isMutable: false, nextTempLocalIndex(ctx), ctx.commonFuns.gcRootType);
	return genLetNoGcRoot(
		ctx.alloc, range, root,
		initRoot,
		genSeq(
			ctx.alloc, range,
			genSetGcRoot(ctx, range, genLocalPointer(ctx.commonFuns.gcRootMutPointerType, range, root)),
			cbThen(exprPos.withIncrNGcRoots)));
}

struct GetLowExprCtx {
	@safe @nogc pure nothrow:

	const ShowCtx* showCtx;
	immutable LowFunIndex currentFun;
	immutable ConcreteProgram* concreteProgram;
	immutable Constant staticSymbols;
	GetLowTypeCtx* getLowTypeCtxPtr;
	MutArr!LowFunCause* lowFunCauses;
	MarkVisitFuns* markVisitFuns;
	const MutConcreteFunToLowFunIndex* concreteFunToLowFunIndexPtr;
	immutable LowCommonFuns commonFuns;
	immutable VarIndices varIndices;
	immutable ConcreteLocal[] concreteParams;
	immutable LowLocal[] lowParams;
	immutable bool curFunIsYielding;
	bool hasSetupCatch;
	bool hasTailRecur;
	size_t tempLocalIndex;

	ref Alloc alloc() return scope =>
		typeCtx.alloc;

	ref GetLowTypeCtx typeCtx() return scope =>
		*getLowTypeCtxPtr;
	ref AllLowTypes allTypes() return scope =>
		typeCtx.allTypes;

	ref const(MutConcreteFunToLowFunIndex) concreteFunToLowFunIndex() return scope const =>
		*concreteFunToLowFunIndexPtr;

	ref LowCommonTypes commonTypes() return const =>
		commonFuns.commonTypes;
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
		// An expression returned from the function with no step after, suitable for tail recursion.
		tail
	}
	Kind kind;

	static ExprPos nonTail() => ExprPos(0, Kind.nonTail);
	static ExprPos loopNoGcRoots() => ExprPos(0, Kind.loop);
	ExprPos withIncrNGcRoots() =>
		ExprPos(nGcRootsToPop + 1, kind);
	ExprPos asNonTail() =>
		ExprPos(nGcRootsToPop, Kind.nonTail);
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
	LowExpr res = getLowExpr(ctx, locals, type, expr, exprPos);
	assert(res.type == type);
	return res;
}

LowExpr getLowExpr(
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
		(ConcreteExprKind.Call x) =>
			getCallExpr(ctx, locals, exprPos, type, range, x.called, x.args),
		(Constant x) =>
			regular(LowExprKind(x)),
		(ConcreteExprKind.CreateArray x) =>
			getCreateArrayExpr(ctx, exprPos, locals, type, range, expr.type, x),
		(ConcreteExprKind.CreateRecord x) =>
			getCreateRecordExpr(ctx, exprPos, locals, type, range, x),
		(ref ConcreteExprKind.CreateUnion x) =>
			LowExpr(type, range, LowExprKind(allocate(ctx.alloc, LowExprKind.CreateUnion(
				x.memberIndex,
				getLowExpr(ctx, locals, x.arg, exprPos.asNonTail))))),
		(ref ConcreteExprKind.Drop x) =>
			handleExprPos(ctx, exprPos, genDrop(ctx.alloc, range, getLowExpr(ctx, locals, x.arg, ExprPos.nonTail))),
		(ref ConcreteExprKind.Finally x) =>
			getFinallyExpr(ctx, exprPos, locals, range, type, x),
		(ref ConcreteExprKind.If x) =>
			LowExpr(type, range, LowExprKind(allocate(ctx.alloc, LowExprKind.If(
				getLowExpr(ctx, locals, x.cond, ExprPos.nonTail),
				getLowExpr(ctx, locals, x.then, exprPos),
				getLowExpr(ctx, locals, x.else_, exprPos))))),
		(ref ConcreteExprKind.Let x) =>
			genLet(ctx, locals, exprPos, type, range, x.local, x.value, x.then, (LowExpr x) => x),
		(ConcreteExprKind.LocalGet x) =>
			handleExprPos(ctx, exprPos, genLocalGet(range, getLocal(ctx, locals, x.local))),
		(ConcreteExprKind.LocalPointer x) =>
			handleExprPos(ctx, exprPos, genLocalPointer(type, range, getLocal(ctx, locals, x.local))),
		(ref ConcreteExprKind.LocalSet x) =>
			handleExprPos(ctx, exprPos, genLocalSet(
				ctx.alloc, range, getLocal(ctx, locals, x.local), getLowExpr(ctx, locals, x.value, ExprPos.nonTail))),
		(ref ConcreteExprKind.Loop x) =>
			handleExprPos(ctx, exprPos, LowExpr(type, range, LowExprKind(allocate(ctx.alloc,
				LowExprKind.Loop(getLowExpr(ctx, locals, x.body_, ExprPos.loopNoGcRoots)))))),
		(ref ConcreteExprKind.LoopBreak x) {
			assert(exprPos.kind == ExprPos.Kind.loop);
			return genLoopBreak(ctx.alloc, type, range, getLowExpr(ctx, locals, x.value, exprPos.asNonTail));
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
		(ConcreteExprKind.RecordFieldGet x) =>
			handleExprPos(ctx, exprPos, genRecordFieldGet(
				ctx.alloc, type, range, getLowExpr(ctx, locals, *x.record, ExprPos.nonTail), x.fieldIndex)),
		(ConcreteExprKind.RecordFieldPointer x) =>
			handleExprPos(ctx, exprPos, genRecordFieldPointer(
				ctx.alloc, type, range, getLowExpr(ctx, locals, *x.record, ExprPos.nonTail), x.fieldIndex)),
		(ref ConcreteExprKind.RecordFieldSet x) =>
			getRecordFieldSet(ctx, locals, exprPos, range, x.record, x.fieldIndex, x.value),
		(ref ConcreteExprKind.Seq x) =>
			genSeq(
				ctx.alloc, range,
				getLowExpr(ctx, locals, x.first, ExprPos.nonTail),
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
	ref GetLowExprCtx ctx,
	UriAndRange range,
	LowType ptrType,
	LowExpr size,
) =>
	genPointerCast(
		ctx.alloc, ptrType, range,
		genCallNoGcRoots(ctx.alloc, ctx.commonTypes.nat8MutPointer, range, ctx.commonFuns.alloc, [size]));

LowExpr getAllocExpr(ref GetLowExprCtx ctx, ExprPos exprPos, LowType type, UriAndRange range, LowExpr arg) {
	if (isEmptyType(ctx.allTypes, arg.type))
		return handleExprPos(ctx, exprPos, mayHaveSideEffects(arg)
			? genSeq(ctx.alloc, range, genDrop(ctx.alloc, range, arg), genZeroed(type, range))
			: genZeroed(type, range));
	else {
		LowExpr ptr = getAllocateExpr(ctx, range, type, genSizeOf(ctx.allTypes, range, arg.type));
		// `x = arg; ptr = (T*) alloc(sizeof(T)); *ptr = x; return ptr;``
		return genLetTempConstNoGcRoot(ctx, range, arg, (LowExpr getArg) =>
			genLetTempConstNoGcRoot(ctx, range, ptr, (LowExpr getPtr) =>
				genSeq(
					ctx.alloc, range,
					genWriteToPointer(ctx.alloc, range, getPtr, arg),
					handleExprPos(ctx, exprPos, getPtr))));
	}
}

// TODO: this should probably part of the expression 'type'
bool mayHaveSideEffects(in LowExpr a) =>
	!neverHasSideEffects(a);
bool neverHasSideEffects(in LowExpr a) =>
	a.kind.isA!Constant ||
	a.kind.isA!(LowExprKind.LocalGet) ||
	(a.kind.isA!(LowExprKind.CreateRecord) &&
		every!LowExpr(a.kind.as!(LowExprKind.CreateRecord).args, (in LowExpr x) => neverHasSideEffects(x))) ||
	(a.kind.isA!(LowExprKind.SpecialUnary) &&
		a.kind.as!(LowExprKind.SpecialUnary).kind == BuiltinUnary.deref &&
		neverHasSideEffects(a.kind.as!(LowExprKind.SpecialUnary).arg));

LowExpr getCallExpr(
	ref GetLowExprCtx ctx,
	in Locals locals,
	ExprPos exprPos,
	LowType type,
	UriAndRange range,
	ConcreteFun* concreteCalled,
	in SmallArray!ConcreteExpr args,
) {
	Opt!LowFunIndex opCalled = tryGetLowFunIndex(ctx, concreteCalled);
	return has(opCalled)
		? getCallRegular(ctx, locals, type, range, exprPos, args, concreteCalled, force(opCalled))
		: handleExprPos(ctx, exprPos, getCallSpecial(ctx, locals, type, range, concreteCalled, args));
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
		: genBinary(
			ctx.alloc, boolType, range,
			called.body_.as!(ConcreteFunBody.Builtin).kind.as!BuiltinBinary,
			arg0, arg1);
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
		MutArr!UpdateParam updateParams;
		zipPtrFirst(ctx.lowParams, args, (LowLocal* param, ref ConcreteExpr concreteArg) {
			LowExpr arg = getLowExpr(ctx, locals, concreteArg, ExprPos.nonTail);
			if (!(arg.kind.isA!(LowExprKind.LocalGet) && arg.kind.as!(LowExprKind.LocalGet).local == param))
				push(ctx.alloc, updateParams, UpdateParam(param, arg));
		});
		if (mutArrIsEmpty(updateParams))
			return popGcRootsThenDo(
				ctx, exprPos.nGcRootsToPop,
				LowExpr(type, range, LowExprKind(LowExprKind.TailRecur([]))));
		else {
			UpdateParam last = mustPop(updateParams);
			push(ctx.alloc, updateParams, UpdateParam(last.param, handleExprPos(ctx, exprPos, last.newValue)));
			return LowExpr(type, range, LowExprKind(LowExprKind.TailRecur(moveToArray(ctx.alloc, updateParams))));
		}
	} else
		return withPushAllGcRoots(
			ctx, locals, range, exprPos, ctx.curFunIsYielding && concreteCalled in ctx.concreteProgram.yieldingFuns,
			args,
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
		(EnumOrFlagsFunction x) =>
			genEnumOrFlagsFunction(ctx, locals, type, range, x, args),
		(ConcreteFunBody.Extern) =>
			assert(false),
		(ConcreteExpr x) =>
			LowExpr(type, range, LowExprKind(x.kind.as!Constant)),
		(ConcreteFunBody.FlagsFn x) {
			switch (x.fn) {
				case EnumOrFlagsFunction.negate:
					return genFlagsNegate(
						ctx.alloc,
						range,
						x.allValue,
						getLowExpr(ctx, locals, only(args), ExprPos.nonTail));
				default:
					assert(0);
			}
		},
		(ConcreteFunBody.VarGet x) =>
			genVarGet(type, range, mustGet(ctx.varIndices, x.var)),
		(ConcreteFunBody.VarSet x) =>
			genVarSet(
				ctx.alloc, range,
				mustGet(ctx.varIndices, x.var),
				getLowExpr(ctx, locals, only(args), ExprPos.nonTail)),
		(ConcreteFunBody.Deferred) =>
			assert(false));

LowExpr getRecordFieldSet(
	ref GetLowExprCtx ctx,
	in Locals locals,
	ExprPos exprPos,
	in UriAndRange range,
	ref ConcreteExpr record,
	size_t fieldIndex,
	ref ConcreteExpr value,
) =>
	genLetTempPossiblyGcRoot(
		ctx, exprPos, range,
		getLowExpr(ctx, locals, record, ExprPos.nonTail),
		expressionMayYield(ctx, value),
		(ExprPos inner, LowExpr getRecord) =>
			handleExprPos(ctx, inner, genRecordFieldSetNoGcRoot(
				ctx.alloc, range, getRecord, fieldIndex, getLowExpr(ctx, locals, value, ExprPos.nonTail))));

LowExpr genFlagsNegate(ref Alloc alloc, UriAndRange range, ulong allValue, LowExpr a) =>
	genEnumIntersect(alloc, range, genBitwiseNegate(alloc, range, a), genConstantIntegral(a.type, range, allValue));

LowExpr genEnumOrFlagsFunction(
	ref GetLowExprCtx ctx,
	in Locals locals,
	LowType type,
	in UriAndRange range,
	EnumOrFlagsFunction a,
	in ConcreteExpr[] args,
) {
	LowExpr arg0() => getLowExpr(ctx, locals, args[0], ExprPos.nonTail);
	LowExpr arg1() => getLowExpr(ctx, locals, args[1], ExprPos.nonTail);
	final switch (a) {
		case EnumOrFlagsFunction.equal:
			assert(args.length == 2);
			return genEnumEq(ctx.alloc, range, arg0(), arg1());
		case EnumOrFlagsFunction.intersect:
			assert(args.length == 2);
			return genEnumIntersect(ctx.alloc, range, arg0(), arg1());
		case EnumOrFlagsFunction.none:
			return genConstantIntegral(type, range, 0);
		case EnumOrFlagsFunction.toIntegral:
			assert(args.length == 1);
			return arg0();
		case EnumOrFlagsFunction.union_:
			assert(args.length == 2);
			return genEnumUnion(ctx.alloc, range, arg0(), arg1());
		case EnumOrFlagsFunction.members: // In concretize, this was translated to a constant
		case EnumOrFlagsFunction.negate: // This becomes a ConcreteFunBody.FlagsFn
			assert(false);
	}
}

LowExpr callFunPointer(
	ref GetLowExprCtx ctx,
	ExprPos exprPos,
	in Locals locals,
	UriAndRange range,
	LowType type,
	ConcreteExpr[2] funPtrAndArg,
) {
	LowExpr funPtr = getLowExpr(ctx, locals, funPtrAndArg[0], ExprPos.nonTail);
	LowExpr arg = getLowExpr(ctx, locals, funPtrAndArg[1], ExprPos.nonTail);
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
	LowExpr doCall(LowExpr getFunPtr, SmallArray!LowExpr args) =>
		handleExprPos(ctx, exprPos, genCallFunPointerNoGcRoots(type, range, allocate(ctx.alloc, getFunPtr), args));
	Opt!(SmallArray!LowType) optArgTypes = tryUnpackTuple(ctx.alloc, arg.type);
	if (has(optArgTypes)) {
		SmallArray!LowType argTypes = force(optArgTypes);
		return arg.kind.isA!(LowExprKind.CreateRecord)
			? doCall(funPtr, small!LowExpr(arg.kind.as!(LowExprKind.CreateRecord).args))
			: argTypes.length == 0
			// Making sure the side effect order is function then arg
			? genLetTempConstNoGcRoot(ctx, range, funPtr, (LowExpr getFunPointer) =>
				genSeq(ctx.alloc, range, arg, doCall(getFunPointer, emptySmallArray!LowExpr)))
			: genLetTempConstNoGcRoot(ctx, range, funPtr, (LowExpr getFunPointer) =>
				genLetTempConstNoGcRoot(ctx, range, arg, (LowExpr getArg) =>
					doCall(getFunPointer, mapWithIndex!(LowExpr, LowType)(
						ctx.alloc, argTypes, (size_t argIndex, ref LowType argType) =>
							genRecordFieldGet(ctx.alloc, argType, range, getArg, argIndex)))));
	} else
		return doCall(funPtr, newSmallArray!LowExpr(ctx.alloc, [arg]));
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
	LowExpr getArg(ref ConcreteExpr arg, ExprPos argPos = ExprPos.nonTail) =>
		getLowExpr(ctx, locals, arg, argPos);
	LowExpr getArg0() =>
		getArg(args[0]);
	LowExpr getArg1() =>
		getArg(args[1]);
	LowExpr getArg2() =>
		getArg(args[2]);
	LowExpr getArg3() =>
		getArg(args[3]);
	return kind.match!LowExpr(
		(BuiltinFun.AllTests) =>
			assert(false), // handled in concretize
		(BuiltinUnary kind) {
			assert(args.length == 1);
			LowExpr arg = getArg0;
			switch (kind) {
				case BuiltinUnary.arrayPointer:
					return genRecordFieldGet(ctx.alloc, type, range, arg, 1);
				case BuiltinUnary.arraySize:
					return genRecordFieldGet(ctx.alloc, type, range, arg, 0);
				case BuiltinUnary.asFuture:
				case BuiltinUnary.asFutureImpl:
				case BuiltinUnary.cStringOfSymbol:
				case BuiltinUnary.symbolOfCString:
				case BuiltinUnary.toChar8ArrayFromString:
				case BuiltinUnary.trustAsString:
					assert(arg.type == type);
					return arg;
				default:
					return genUnary(ctx.alloc, type, range, kind, arg);
			}
		},
		(BuiltinUnaryMath kind) {
			assert(args.length == 1);
			return genUnaryMath(ctx.alloc, type, range, kind, getArg0);
		},
		(BuiltinBinary kind) {
			assert(args.length == 2);
			return maybeOptimizeSpecialBinary(ctx, type, range, kind, getArg0, getArg1);
		},
		(BuiltinBinaryLazy kind) =>
			assert(false), // handled in concretize
		(BuiltinBinaryMath kind) {
			assert(args.length == 2);
			return genBinaryMath(ctx.alloc, type, range, kind, getArg0, getArg1);
		},
		(BuiltinTernary kind) {
			assert(args.length == 3);
			return genTernary(ctx.alloc, type, range, kind, getArg0, getArg1, getArg2);
		},
		(Builtin4ary kind) {
			assert(args.length == 4);
			return gen4ary(ctx.alloc, type, range, kind, getArg0, getArg1, getArg2, getArg3);
		},
		(BuiltinFun.CallLambda) =>
			assert(false), // handled in concretize
		(BuiltinFun.CallFunPointer) =>
			callFunPointer(ctx, ExprPos.nonTail, locals, range, type, only2(args)),
		(Constant x) =>
			LowExpr(type, range, LowExprKind(x)),
		(BuiltinFun.GcSafeValue) =>
			// handled in concretize
			assert(false),
		(BuiltinFun.Init x) =>
			LowExpr(type, range, LowExprKind(LowExprKind.Init(x.kind))),
		(JsFun _) =>
			assert(false),
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
			return genSizeOf(ctx.allTypes, range, typeArg);
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
		genBinary(ctx.alloc, type, range, kind, arg0, arg1);

	switch (kind) {
		case BuiltinBinary.newArray:
			return genCreateRecordNoGcRoots(ctx.alloc, type, range, [arg0, arg1]);
		case BuiltinBinary.addPointerAndNat64:
			return isEmptyType(ctx.allTypes, asNonGcPointee(arg0.type))
				? genLetTempConstNoGcRoot(ctx, range, arg0, (LowExpr getA) =>
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

LowExpr getCreateArrayExpr(
	ref GetLowExprCtx ctx,
	ExprPos exprPos,
	in Locals locals,
	LowType arrType,
	UriAndRange range,
	ConcreteType concreteArrType,
	in ConcreteExprKind.CreateArray a,
) =>
	withPushAllGcRoots(ctx, locals, range, exprPos, isYieldingCall: false, a.args, (ExprPos innerPos, LowExpr[] args) {
		// arg0 = ...;
		// arg1 = ...;
		// ptr = _alloc(ctx, sizeof(foo) * n);
		// *(ptr + 0) = arg0;
		// *(ptr + 1) = arg1;
		// return arr_foo{n, ptr};
		LowType elementType = lowTypeFromConcreteType(
			ctx.typeCtx,
			only(mustBeByVal(concreteArrType).source.as!(ConcreteStructSource.Inst).typeArgs));
		LowType elementPtrType = getPointerConst(ctx.typeCtx, elementType);
		LowExpr elementSize = genSizeOf(ctx.allTypes, range, elementType);
		LowExpr nElements = genConstantNat64(range, a.args.length);
		LowExpr sizeBytes = genWrapMulNat64(ctx.alloc, range, elementSize, nElements);
		LowExpr allocatePtr = getAllocateExpr(ctx, range, elementPtrType, sizeBytes);
		return genLetTempConstNoGcRoot(ctx, range, allocatePtr, (LowExpr getPtr) =>
			handleExprPos(ctx, innerPos, foldReverseWithIndex!(LowExpr, LowExpr)(
				genCreateRecordNoGcRoots(ctx.alloc, arrType, range, [nElements, getPtr]),
				args,
				(LowExpr nextExpr, size_t index, ref LowExpr arg) {
					LowExpr elementPtr = genAddPointer(
						ctx.alloc,
						elementPtrType.as!(LowType.PointerConst),
						range,
						getPtr,
						genConstantNat64(range, index));
					LowExpr writeToElement = genWriteToPointer(ctx.alloc, range, elementPtr, arg);
					return genSeq(ctx.alloc, range, writeToElement, nextExpr);
				})));
	});

LowExpr getCreateRecordExpr(
	ref GetLowExprCtx ctx,
	ExprPos exprPos,
	in Locals locals,
	LowType type,
	UriAndRange range,
	in ConcreteExprKind.CreateRecord a,
) =>
	withPushAllGcRoots(ctx, locals, range, exprPos, isYieldingCall: false, a.args, (ExprPos innerPos, LowExpr[] args) {
		bool alloc = type.isA!(LowType.PointerGc);
		LowType recordType = alloc ? asGcPointee(type) : type;
		LowExpr record = genCreateRecordNoGcRoots(recordType, range, args);
		return alloc
			? getAllocExpr(ctx, exprPos, type, range, record)
			: handleExprPos(ctx, exprPos, record);
	});

LowExpr genLet(
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
	LowExpr value = getLowExpr(ctx, locals, concreteValue, ExprPos.nonTail);
	return withLowLocal!LowExpr(ctx, locals, concreteLocal, (in Locals innerLocals, LowLocal* local) =>
		genLetPossiblyGcRoot(
			ctx, range, local, value, exprPos, expressionMayYield(ctx, concreteThen), (ExprPos inner) =>
				cbModifyThen(getLowExpr(ctx, innerLocals, concreteThen, inner))));
}

bool expressionMayYield(in GetLowExprCtx ctx, in ConcreteExpr a) =>
	ctx.curFunIsYielding && (
		isYieldingCall(ctx, a) || existsDirectChildExpr(a, (ref ConcreteExpr child) => expressionMayYield(ctx, child)));

bool isYieldingCall(in GetLowExprCtx ctx, in ConcreteExpr a) =>
	a.kind.isA!(ConcreteExprKind.Call) && a.kind.as!(ConcreteExprKind.Call).called in ctx.concreteProgram.yieldingFuns;

LowExpr getMatchIntegralExpr(
	ref GetLowExprCtx ctx,
	in Locals locals,
	ExprPos exprPos,
	LowType type,
	UriAndRange range,
	ref ConcreteExprKind.MatchEnumOrIntegral a,
) =>
	LowExpr(type, range, LowExprKind(allocate(ctx.alloc, LowExprKind.Switch(
		value: getLowExpr(ctx, locals, a.matched, ExprPos.nonTail),
		caseValues: a.caseValues,
		caseExprs: map!(LowExpr, ConcreteExpr)(ctx.alloc, a.caseExprs, (ref ConcreteExpr case_) =>
			getLowExpr(ctx, locals, case_, exprPos)),
		default_: has(a.else_)
			? getLowExpr(ctx, locals, *force(a.else_), exprPos)
			: genAbort(type, range)))));

LowExpr withLetTempConstNoGcRoot(
	ref GetLowExprCtx ctx,
	in Locals locals,
	ref ConcreteExpr expr,
	in LowExpr delegate(LowExpr) @safe @nogc pure nothrow cb,
) =>
	genLetTempConstNoGcRoot(ctx, expr.range, getLowExpr(ctx, locals, expr, ExprPos.nonTail), cb);

LowExpr genLetTempConstNoGcRoot(
	ref GetLowExprCtx ctx,
	in UriAndRange range,
	LowExpr value,
	in LowExpr delegate(LowExpr) @safe @nogc pure nothrow cb,
) =>
	genLetTempConstNoGcRoot(ctx.alloc, range, nextTempLocalIndex(ctx), value, cb);

LowExpr getMatchStringLikeExpr(
	ref GetLowExprCtx ctx,
	in Locals locals,
	ExprPos exprPos,
	UriAndRange range,
	ref ConcreteExprKind.MatchStringLike a,
) =>
	// We don't need a GC root for 'matched' since we use it immediately without yielding
	withLetTempConstNoGcRoot(ctx, locals, a.matched, (LowExpr matched) =>
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

LowExpr getMatchUnionExpr(
	ref GetLowExprCtx ctx,
	in Locals locals,
	ExprPos exprPos,
	LowType type,
	UriAndRange range,
	ref ConcreteExprKind.MatchUnion a,
) =>
	// We don't need a GC root for 'matched', since each case handles its argument GC root
	withLetTempConstNoGcRoot(ctx, locals, a.matched, (LowExpr getMatched) {
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
						expressionMayYield(ctx, case_.then),
						(ExprPos inner) => getLowExpr(ctx, newLocals, case_.then, inner)))
				: getLowExpr(ctx, locals, case_.then, exprPos)));

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
		getLowExpr(ctx, locals, a.thrown, ExprPos.nonTail)]);
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
	old-catch-point = cur-catch-point
	old-gc-root = gc-root
	store mut catch-point = zeroed
	err mut = false
	res = if !(&store setup-catch)
		below
	else
		gc-root := old-gc-root
		err = true
		zeroed
	res add-gc-root
	cur-catch-point := old-catch-point
	right
	if err
		rethrow-current-exception
	pop-gc-root
	res
	*/
	withRestorableCatchPoint(ctx, range, (LowExpr restoreCurCatchPoint) =>
		withRestorableGcRoot(ctx, range, (LowExpr restoreGcRoot) {
			LowLocal* err = genLocal(ctx.alloc, symbol!"err", isMutable: true, nextTempLocalIndex(ctx), boolType);
			LowExpr res = genSetupCatch(
				ctx, range,
				getLowExpr(ctx, locals, a.below, ExprPos.nonTail),
				genSeq(
					ctx.alloc, range,
					restoreGcRoot,
					genLocalSet(ctx.alloc, range, err, genTrue(range)),
					genZeroed(type, range)));
			LowExpr afterRes = genSeq(
				ctx.alloc, range,
				restoreCurCatchPoint,
				getLowExpr(ctx, locals, a.right, ExprPos.nonTail),
				genIf(
					ctx.alloc, range,
					genLocalGet(range, err),
					genRethrowCurrentException(ctx, range),
					genVoid(range)));
			return genLetNoGcRoot(
				ctx.alloc, range, err,
				genFalse(range),
				genSeqThenReturnFirstPossiblyGcRoot(
					ctx, exprPos, range, res, afterRes, expressionMayYield(ctx, a.right)));
		}));

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
		(LowExpr restoreCurCatchPoint) =>
			genSeqThenReturnFirstNoGcRoot( // 'tried' type may be a GC root, but 'restoreCurCatchPoint' never yields.
				ctx.alloc, range, nextTempLocalIndex(ctx),
				getLowExpr(ctx, locals, a.tried, exprPos),
				restoreCurCatchPoint));

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
		(LowExpr restoreCurCatchPoint) =>
			has(a.local)
				? genLet(
					ctx, locals, exprPos, type, range, force(a.local), a.value, a.then,
					(LowExpr then) => genSeq(ctx.alloc, range, restoreCurCatchPoint, then))
				: genSeq(
					ctx.alloc, range,
					genDrop(ctx.alloc, range, getLowExpr(ctx, locals, a.value, ExprPos.nonTail)),
					restoreCurCatchPoint,
					getLowExpr(ctx, locals, a.then, exprPos)));

LowExpr getTryOrTryLetExpr(
	ref GetLowExprCtx ctx,
	in Locals locals,
	ExprPos exprPos,
	UriAndRange range,
	LowType type,
	IntegralValues exceptionMemberIndices,
	in ConcreteExprKind.MatchUnion.Case[] catchCases,
	in LowExpr delegate(LowExpr restoreCurCatchPoint) @safe @nogc pure nothrow firstBlock,
) =>
	/*
	try
		tried
	catch foo x
		handler
	==>
	old-catch-point = cur-catch-point
	old-gc-root = gc-root
	store mut catch-point = zeroed
	if !(&store setup-catch)
		cur-catch-point = &store
		res = first-block
		cur-catch-point := old-catch-point
	else
		cur-catch-point := old-catch-point
		gc-root := old-gc-root
		match cur-thrown
		as foo x
			handler
		else
			rethrow-current-exception
	*/
	withRestorableCatchPoint(ctx, range, (LowExpr restoreCurCatchPoint) =>
		withRestorableGcRoot(ctx, range, (LowExpr restoreGcRoot) {
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
			LowExpr onError = genSeq(ctx.alloc, range, restoreCurCatchPoint, restoreGcRoot, matchThrown);
			return genSetupCatch(ctx, range, firstBlock(restoreCurCatchPoint), onError);
		}));

LowExpr withRestorableCatchPoint(
	ref GetLowExprCtx ctx,
	UriAndRange range,
	in LowExpr delegate(LowExpr restoreCatchPoint) @safe @nogc pure nothrow cb,
) =>
	// Don't need a GC root since 'set-cur-catch-point' never yields.
	genLetTempConstNoGcRoot(ctx, range, genGetCurCatchPoint(ctx, range), (LowExpr oldCatchPoint) =>
		cb(genSetCurCatchPoint(ctx, range, oldCatchPoint)));

LowExpr withRestorableGcRoot(
	ref GetLowExprCtx ctx,
	UriAndRange range,
	in LowExpr delegate(LowExpr restoreGcRoot) @safe @nogc pure nothrow cb,
) =>
	// 'gc-root' is not itself a GC root
	genLetTempConstNoGcRoot(ctx, range, genGetGcRoot(ctx, range), (LowExpr oldGcRoot) =>
		cb(genSetGcRoot(ctx, range, oldGcRoot)));

LowExpr genRethrowCurrentException(ref GetLowExprCtx ctx, UriAndRange range) =>
	genCallNoGcRoots(ctx.alloc, voidType, range, ctx.commonFuns.rethrowCurrentException, []);

LowExpr genSetupCatch(ref GetLowExprCtx ctx, UriAndRange range, LowExpr tried, LowExpr onCatch) {
	ctx.hasSetupCatch = true;
	/*
	store mut catch-point = zeroed
	if !(&store setup-catch)
		cur-catch-point := &store
		tried
	else
		onCatch
	*/
	LowLocal* store = genLocal(
		ctx.alloc, symbol!"store", isMutable: true, nextTempLocalIndex(ctx), ctx.commonTypes.catchPoint);
	LowExpr then = genIf(
		ctx.alloc, range,
		genUnary(
			ctx.alloc, boolType, range, BuiltinUnary.setupCatch,
			genLocalPointer(ctx.commonTypes.catchPointMutPointer, range, store)),
		onCatch,
		genSeq(
			ctx.alloc, range,
			genSetCurCatchPoint(ctx, range, genLocalPointer(ctx.commonTypes.catchPointConstPointer, range, store)),
			tried));
	return genLetNoGcRoot(ctx.alloc, range, store, genZeroed(ctx.commonTypes.catchPoint, range), then);
}

LowExpr genGetCurThrown(ref GetLowExprCtx ctx, UriAndRange range) =>
	genVarGet(ctx.commonFuns.exceptionType, range, ctx.commonFuns.curThrown);

LowExpr genGetCurCatchPoint(ref GetLowExprCtx ctx, UriAndRange range) =>
	genCallNoGcRoots(ctx.alloc, ctx.commonTypes.catchPointConstPointer, range, ctx.commonFuns.curCatchPoint, []);

LowExpr genSetCurCatchPoint(ref GetLowExprCtx ctx, UriAndRange range, LowExpr value) =>
	genCallNoGcRoots(ctx.alloc, voidType, range, ctx.commonFuns.setCurCatchPoint, [value]);

LowExpr genGetGcRoot(ref GetLowExprCtx ctx, UriAndRange range) =>
	genCallNoGcRoots(ctx.alloc, ctx.commonFuns.gcRootMutPointerType, range, ctx.commonFuns.gcRoot, []);

LowExpr genSetGcRoot(ref GetLowExprCtx ctx, UriAndRange range, LowExpr root) =>
	genCallNoGcRoots(ctx.alloc, voidType, range, ctx.commonFuns.setGcRoot, [root]);
