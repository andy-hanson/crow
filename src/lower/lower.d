module lower.lower;

@safe @nogc pure nothrow:

import lower.checkLowModel : checkLowProgram;
import lower.generateCallWithCtxFun : generateCallWithCtxFun;
import lower.generateMarkVisitFun : generateMarkVisitArr, generateMarkVisitNonArr, generateMarkVisitGcPtr;
import lower.getBuiltinCall : BuiltinKind, getBuiltinKind;
import lower.lowExprHelpers :
	anyPtrMutType,
	char8PtrPtrConstType,
	genAddPtr,
	genBitwiseNegate,
	genConstantNat64,
	genDerefGcPtr,
	genDrop,
	genEnumEq,
	genEnumIntersect,
	genEnumToIntegral,
	genEnumUnion,
	genLetTemp,
	genLocal,
	genLocalByValue,
	genLocalGet,
	genRecordFieldGet,
	genPtrCast,
	genPtrCastKind,
	genSeq,
	genSizeOf,
	genVoid,
	genWrapMulNat64,
	genWriteToPtr,
	getElementPtrTypeFromArrType,
	int32Type,
	voidType;
import model.concreteModel :
	AllConstantsConcrete,
	ArrTypeAndConstantsConcrete,
	body_,
	BuiltinStructKind,
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
	ConcreteType,
	ConcreteVariableRef,
	elementType,
	fieldOffsets,
	isFunOrActSubscript,
	isMarkVisitFun,
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
	LowFunPtrType,
	LowFunSource,
	LowLocal,
	LowLocalSource,
	LowProgram,
	LowRecord,
	LowThreadLocal,
	LowThreadLocalIndex,
	LowType,
	LowUnion,
	PointerTypeAndConstantsLow,
	PrimitiveType,
	UpdateParam;
import model.model :
	ClosureReferenceKind,
	ConfigExternPaths,
	EnumBackingType,
	EnumFunction,
	EnumValue,
	FlagsFunction,
	FunInst,
	Local,
	name,
	range;
import util.alloc.alloc : Alloc;
import util.col.arr : empty, only, only2;
import util.col.arrBuilder : add, ArrBuilder, arrBuilderSize, finishArr;
import util.col.arrUtil :
	arrLiteral,
	exists,
	indexOfPointer,
	map,
	mapPointersWithIndex,
	mapWithIndex,
	mapWithIndexAndConcatOne,
	mapZip,
	mapZipPtrFirst,
	zipPtrFirst;
import util.col.dict : mustGetAt, Dict;
import util.col.dictBuilder : finishDict, mustAddToDict, DictBuilder;
import util.col.fullIndexDict : FullIndexDict, fullIndexDictOfArr, fullIndexDictSize;
import util.col.mutIndexDict : getOrAddAndDidAdd, mustGetAt, MutIndexDict, newMutIndexDict;
import util.col.mutArr : moveToArr, MutArr, push;
import util.col.mutDict : getAt_mut, getOrAdd, mapToArr_mut, MutDict, MutDict, ValueAndDidAdd;
import util.col.stackDict : StackDict2, stackDict2Add0, stackDict2Add1, stackDict2MustGet0, stackDict2MustGet1;
import util.late : Late, late, lateGet, lateIsSet, lateSet;
import util.memory : allocate, overwriteMemory;
import util.opt : force, has, none, Opt, some;
import util.perf : Perf, PerfMeasure, withMeasure;
import util.ptr : castNonScope_ref, ptrTrustMe;
import util.sourceRange : FileAndRange;
import util.sym : AllSymbols, Sym, sym;
import util.union_ : Union;
import util.util : typeAs, unreachable, verify;

LowProgram lower(
	ref Alloc alloc,
	scope ref Perf perf,
	in AllSymbols allSymbols,
	in ConfigExternPaths configExtern,
	ref ConcreteProgram a,
) =>
	withMeasure!(LowProgram, () =>
		lowerInner(alloc, allSymbols, configExtern, a)
	)(alloc, perf, PerfMeasure.lower);

private LowProgram lowerInner(
	ref Alloc alloc,
	in AllSymbols allSymbols,
	in ConfigExternPaths configExtern,
	ref ConcreteProgram a,
) {
	AllLowTypesWithCtx allTypes = getAllLowTypes(alloc, allSymbols, a);
	AllLowFuns allFuns = getAllLowFuns(allTypes.allTypes, allTypes.getLowTypeCtx, configExtern, a);
	AllConstantsLow allConstants = convertAllConstants(allTypes.getLowTypeCtx, a.allConstants);
	LowProgram res = LowProgram(
		allFuns.concreteFunToLowFunIndex,
		allConstants,
		allFuns.threadLocals,
		allTypes.allTypes,
		allFuns.allLowFuns,
		allFuns.main,
		allFuns.allExternFuns);
	checkLowProgram(alloc, allSymbols, res);
	return res;
}

struct MarkVisitFuns {
	MutIndexDict!(LowType.Record, LowFunIndex) recordValToVisit;
	MutIndexDict!(LowType.Union, LowFunIndex) unionToVisit;
	MutDict!(LowType, LowFunIndex) gcPointeeToVisit;
}

Opt!LowFunIndex tryGetMarkVisitFun(ref const MarkVisitFuns funs, LowType type) =>
	type.match!(Opt!LowFunIndex)(
		(LowType.Extern) =>
			none!LowFunIndex,
		(LowType.FunPtr) =>
			none!LowFunIndex,
		(PrimitiveType it) =>
			none!LowFunIndex,
		(LowType.PtrGc it) =>
			getAt_mut(funs.gcPointeeToVisit, *it.pointee),
		(LowType.PtrRawConst) =>
			none!LowFunIndex,
		(LowType.PtrRawMut) =>
			none!LowFunIndex,
		(LowType.Record it) =>
			typeAs!(Opt!LowFunIndex)(funs.recordValToVisit[it]),
		(LowType.Union it) =>
			typeAs!(Opt!LowFunIndex)(funs.unionToVisit[it]));

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
	FullIndexDict!(LowFunIndex, LowFun) allLowFuns;
	LowFunIndex main;
	ExternLibraries allExternFuns;
	FullIndexDict!(LowThreadLocalIndex, LowThreadLocal) threadLocals;
}

struct GetLowTypeCtx {
	@safe @nogc pure nothrow:

	Alloc* allocPtr;
	const AllSymbols* allSymbolsPtr;
	immutable Dict!(ConcreteStruct*, LowType) concreteStructToType;
	MutDict!(ConcreteStruct*, LowType) concreteStructToPtrType;
	MutDict!(ConcreteStruct*, LowType) concreteStructToPtrPtrType;

	ref Alloc alloc() return scope =>
		*allocPtr;

	ref const(AllSymbols) allSymbols() return scope const =>
		*allSymbolsPtr;
}

AllLowTypesWithCtx getAllLowTypes(ref Alloc alloc, in AllSymbols allSymbols, in ConcreteProgram program) {
	DictBuilder!(ConcreteStruct*, LowType) concreteStructToTypeBuilder;
	ArrBuilder!(ConcreteStruct*) allFunPointerSources;
	ArrBuilder!LowExternType allExternTypes;
	ArrBuilder!(ConcreteStruct*) allRecordSources;
	ArrBuilder!(ConcreteStruct*) allUnionSources;

	LowType addUnion(ConcreteStruct* s) {
		size_t i = arrBuilderSize(allUnionSources);
		add(alloc, allUnionSources, s);
		return LowType(LowType.Union(i));
	}

	foreach (ConcreteStruct* concrete; program.allStructs) {
		Opt!LowType lowType = body_(*concrete).matchIn!(Opt!LowType)(
			(in ConcreteStructBody.Builtin it) {
				final switch (it.kind) {
					case BuiltinStructKind.bool_:
						return some(LowType(PrimitiveType.bool_));
					case BuiltinStructKind.char8:
						return some(LowType(PrimitiveType.char8));
					case BuiltinStructKind.float32:
						return some(LowType(PrimitiveType.float32));
					case BuiltinStructKind.float64:
						return some(LowType(PrimitiveType.float64));
					case BuiltinStructKind.fun:
						return some(addUnion(concrete));
					case BuiltinStructKind.funPointer: {
						size_t i = arrBuilderSize(allFunPointerSources);
						add(alloc, allFunPointerSources, concrete);
						return some(LowType(LowType.FunPtr(i)));
					}
					case BuiltinStructKind.int8:
						return some(LowType(PrimitiveType.int8));
					case BuiltinStructKind.int16:
						return some(LowType(PrimitiveType.int16));
					case BuiltinStructKind.int32:
						return some(LowType(PrimitiveType.int32));
					case BuiltinStructKind.int64:
						return some(LowType(PrimitiveType.int64));
					case BuiltinStructKind.nat8:
						return some(LowType(PrimitiveType.nat8));
					case BuiltinStructKind.nat16:
						return some(LowType(PrimitiveType.nat16));
					case BuiltinStructKind.nat32:
						return some(LowType(PrimitiveType.nat32));
					case BuiltinStructKind.nat64:
						return some(LowType(PrimitiveType.nat64));
					case BuiltinStructKind.pointerConst:
					case BuiltinStructKind.pointerMut:
						return none!LowType;
					case BuiltinStructKind.void_:
						return some(LowType(PrimitiveType.void_));
				}
			},
			(in ConcreteStructBody.Enum it) =>
				some(LowType(typeForEnum(it.backingType))),
			(in ConcreteStructBody.Extern it) {
				size_t i = arrBuilderSize(allExternTypes);
				add(alloc, allExternTypes, LowExternType(concrete));
				return some(LowType(LowType.Extern(i)));
			},
			(in ConcreteStructBody.Flags it) =>
				some(LowType(typeForEnum(it.backingType))),
			(in ConcreteStructBody.Record it) {
				size_t i = arrBuilderSize(allRecordSources);
				add(alloc, allRecordSources, concrete);
				return some(LowType(LowType.Record(i)));
			},
			(in ConcreteStructBody.Union it) =>
				some(addUnion(concrete)));
		if (has(lowType))
			mustAddToDict(alloc, concreteStructToTypeBuilder, concrete, force(lowType));
	}

	GetLowTypeCtx getLowTypeCtx =
		GetLowTypeCtx(ptrTrustMe(alloc), ptrTrustMe(allSymbols), finishDict(alloc, concreteStructToTypeBuilder));

	immutable FullIndexDict!(LowType.Record, LowRecord) allRecords =
		fullIndexDictOfArr!(LowType.Record, LowRecord)(
			map(alloc, finishArr(alloc, allRecordSources), (ref immutable ConcreteStruct* it) =>
				LowRecord(
					it,
					mapZipPtrFirst!(LowField, ConcreteField, immutable size_t)(
						alloc,
						body_(*it).as!(ConcreteStructBody.Record).fields,
						fieldOffsets(*it),
						(ConcreteField* field, in immutable size_t fieldOffset) =>
							LowField(field, fieldOffset, lowTypeFromConcreteType(getLowTypeCtx, field.type))))));
	immutable FullIndexDict!(LowType.FunPtr, LowFunPtrType) allFunPointers =
		fullIndexDictOfArr!(LowType.FunPtr, LowFunPtrType)(
			map(alloc, finishArr(alloc, allFunPointerSources), (ref immutable ConcreteStruct* x) {
				ConcreteType[2] typeArgs = only2(body_(*x).as!(ConcreteStructBody.Builtin).typeArgs);
				return LowFunPtrType(
					x,
					lowTypeFromConcreteType(getLowTypeCtx, typeArgs[0]),
					maybeUnpackTuple(alloc, allRecords, lowTypeFromConcreteType(getLowTypeCtx, typeArgs[1])));
			}));
	immutable FullIndexDict!(LowType.Union, LowUnion) allUnions =
		fullIndexDictOfArr!(LowType.Union, LowUnion)(
			map(alloc, finishArr(alloc, allUnionSources), (ref immutable ConcreteStruct* it) =>
				getLowUnion(alloc, program, getLowTypeCtx, it)));

	return AllLowTypesWithCtx(
		AllLowTypes(
			fullIndexDictOfArr!(LowType.Extern, LowExternType)(finishArr(alloc, allExternTypes)),
			allFunPointers,
			allRecords,
			allUnions),
		getLowTypeCtx);
}

LowType[] maybeUnpackTuple(
	ref Alloc alloc,
	FullIndexDict!(LowType.Record, LowRecord) allRecords,
	LowType a,
) {
	Opt!(LowType[]) res = tryUnpackTuple(alloc, allRecords, a);
	return has(res) ? force(res) : arrLiteral!LowType(alloc, [a]);
}

Opt!(LowType[]) tryUnpackTuple(
	ref Alloc alloc,
	FullIndexDict!(LowType.Record, LowRecord) allRecords,
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

PrimitiveType typeForEnum(EnumBackingType a) {
	final switch (a) {
		case EnumBackingType.int8:
			return PrimitiveType.int8;
		case EnumBackingType.int16:
			return PrimitiveType.int16;
		case EnumBackingType.int32:
			return PrimitiveType.int32;
		case EnumBackingType.int64:
			return PrimitiveType.int64;
		case EnumBackingType.nat8:
			return PrimitiveType.nat8;
		case EnumBackingType.nat16:
			return PrimitiveType.nat16;
		case EnumBackingType.nat32:
			return PrimitiveType.nat32;
		case EnumBackingType.nat64:
			return PrimitiveType.nat64;
	}
}

LowUnion getLowUnion(ref Alloc alloc, in ConcreteProgram program, ref GetLowTypeCtx getLowTypeCtx, ConcreteStruct* s) =>
	LowUnion(s, body_(*s).matchIn!(LowType[])(
		(in ConcreteStructBody.Builtin it) {
			verify(it.kind == BuiltinStructKind.fun);
			return map(getLowTypeCtx.alloc, mustGetAt(program.funStructToImpls, s), (ref ConcreteLambdaImpl impl) =>
				lowTypeFromConcreteType(getLowTypeCtx, impl.closureType));
		},
		(in ConcreteStructBody.Enum) => unreachable!(LowType[])(),
		(in ConcreteStructBody.Extern) => unreachable!(LowType[])(),
		(in ConcreteStructBody.Flags) => unreachable!(LowType[])(),
		(in ConcreteStructBody.Record) => unreachable!(LowType[])(),
		(in ConcreteStructBody.Union it) =>
			map(getLowTypeCtx.alloc, it.members, (ref Opt!ConcreteType member) =>
				has(member)
					? lowTypeFromConcreteType(getLowTypeCtx, force(member))
					: LowType(PrimitiveType.void_))));

LowType getLowRawPtrConstType(ref GetLowTypeCtx ctx, LowType pointee) {
	//TODO:PERF Cache creation of pointer types by pointee
	return LowType(LowType.PtrRawConst(allocate(ctx.alloc, pointee)));
}

LowType getLowGcPtrType(ref GetLowTypeCtx ctx, LowType pointee) {
	//TODO:PERF Cache creation of pointer types by pointee
	return LowType(LowType.PtrGc(allocate(ctx.alloc, pointee)));
}

LowType lowTypeFromConcreteStruct(ref GetLowTypeCtx ctx, in ConcreteStruct* it) {
	Opt!LowType res = ctx.concreteStructToType[it];
	if (has(res))
		return force(res);
	else {
		ConcreteStructBody.Builtin builtin = body_(*it).as!(ConcreteStructBody.Builtin);
		//TODO: cache the creation.. don't want an allocation for every BuiltinStructKind.ptr to the same target type
		LowType* inner = allocate(ctx.alloc, lowTypeFromConcreteType(ctx, only(builtin.typeArgs)));
		switch (builtin.kind) {
			case BuiltinStructKind.pointerConst:
				return LowType(LowType.PtrRawConst(inner));
			case BuiltinStructKind.pointerMut:
				return LowType(LowType.PtrRawMut(inner));
			default:
				return unreachable!LowType;
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

immutable struct LowFunCause {
	immutable struct CallWithCtx {
		LowType funType;
		LowType returnType;
		LowType[] nonFunParamTypes;
		ConcreteLambdaImpl[] impls;
	}
	immutable struct MarkVisitArrOuter {
		LowType.Record arrType;
	}
	immutable struct MarkVisitNonArr { //TODO: this is record (by-val) or union. Maybe split?
		LowType type;
	}
	immutable struct MarkVisitGcPtr {
		LowType.PtrGc pointerType;
		Opt!LowFunIndex visitPointee;
	}

	mixin Union!(CallWithCtx, ConcreteFun*, MarkVisitArrOuter, MarkVisitNonArr, MarkVisitGcPtr);
}

bool needsMarkVisitFun(in AllLowTypes allTypes, in LowType a) =>
	a.matchIn!bool(
		(in LowType.Extern) =>
			false,
		(in LowType.FunPtr) =>
			false,
		(in PrimitiveType) =>
			false,
		(in LowType.PtrGc) =>
			true,
		(in LowType.PtrRawConst) =>
			false,
		(in LowType.PtrRawMut) =>
			false,
		(in LowType.Record it) {
			LowRecord record = allTypes.allRecords[it];
			return isArray(record) || exists!LowField(record.fields, (in LowField field) =>
				needsMarkVisitFun(allTypes, field.type));
		},
		(in LowType.Union it) =>
			exists!LowType(allTypes.allUnions[it].members, (in LowType member) =>
				needsMarkVisitFun(allTypes, member)));

AllLowFuns getAllLowFuns(
	ref AllLowTypes allTypes,
	ref GetLowTypeCtx getLowTypeCtx,
	in ConfigExternPaths configExtern,
	ref ConcreteProgram program,
) {
	DictBuilder!(ConcreteFun*, LowFunIndex) concreteFunToLowFunIndexBuilder;
	ArrBuilder!LowFunCause lowFunCausesBuilder;

	MarkVisitFuns markVisitFuns = MarkVisitFuns(
		newMutIndexDict!(LowType.Record, LowFunIndex)(getLowTypeCtx.alloc, fullIndexDictSize(allTypes.allRecords)),
		newMutIndexDict!(LowType.Union, LowFunIndex)(getLowTypeCtx.alloc, fullIndexDictSize(allTypes.allUnions)));

	LowFunIndex addLowFun(LowFunCause source) {
		LowFunIndex res = LowFunIndex(arrBuilderSize(lowFunCausesBuilder));
		add(getLowTypeCtx.alloc, lowFunCausesBuilder, source);
		return res;
	}

	LowFunIndex generateMarkVisitForType(LowType lowType) @safe @nogc pure nothrow {
		verify(needsMarkVisitFun(allTypes, lowType));
		LowFunIndex addNonArr() {
			return addLowFun(LowFunCause(LowFunCause.MarkVisitNonArr(lowType)));
		}
		Opt!LowFunIndex maybeGenerateMarkVisitForType(LowType t) {
			return needsMarkVisitFun(allTypes, t) ? some(generateMarkVisitForType(t)) : none!LowFunIndex;
		}

		return lowType.match!LowFunIndex(
			(LowType.Extern) =>
				unreachable!LowFunIndex,
			(LowType.FunPtr) =>
				unreachable!LowFunIndex,
			(PrimitiveType it) =>
				unreachable!LowFunIndex,
			(LowType.PtrGc it) {
				Opt!LowFunIndex visitPointee = maybeGenerateMarkVisitForType(*it.pointee);
				return getOrAdd(
					getLowTypeCtx.alloc,
					markVisitFuns.gcPointeeToVisit,
					*it.pointee,
					() => addLowFun(LowFunCause(LowFunCause.MarkVisitGcPtr(it, visitPointee))));
			},
			(LowType.PtrRawConst) =>
				unreachable!LowFunIndex,
			(LowType.PtrRawMut) =>
				unreachable!LowFunIndex,
			(LowType.Record it) {
				LowRecord record = allTypes.allRecords[it];
				if (isArray(record)) {
					LowType.PtrRawConst elementPtrType = getElementPtrTypeFromArrType(allTypes, it);
					ValueAndDidAdd!LowFunIndex outerIndex = getOrAddAndDidAdd!(LowType.Record, LowFunIndex)(
						markVisitFuns.recordValToVisit, it, () =>
							addLowFun(LowFunCause(LowFunCause.MarkVisitArrOuter(it))));
					if (outerIndex.didAdd)
						maybeGenerateMarkVisitForType(*elementPtrType.pointee);
					return outerIndex.value;
				} else {
					ValueAndDidAdd!LowFunIndex index = getOrAddAndDidAdd!(LowType.Record, LowFunIndex)(
						markVisitFuns.recordValToVisit,
						it,
						() => addNonArr());
					if (index.didAdd)
						foreach (ref LowField field; record.fields)
							maybeGenerateMarkVisitForType(field.type);
					return index.value;
				}
			},
			(LowType.Union it) {
				ValueAndDidAdd!LowFunIndex index =
					getOrAddAndDidAdd!(LowType.Union, LowFunIndex)(markVisitFuns.unionToVisit, it, () => addNonArr());
				if (index.didAdd)
					foreach (LowType member; allTypes.allUnions[it].members)
						maybeGenerateMarkVisitForType(member);
				return index.value;
			});
	}

	Late!LowType markCtxTypeLate = late!LowType;

	MutDict!(Sym, MutArr!Sym) allExternFuns;

	ArrBuilder!LowThreadLocal threadLocals;
	DictBuilder!(ConcreteFun*, LowThreadLocalIndex) threadLocalIndicesBuilder;

	foreach (ConcreteFun* fun; program.allFuns) {
		Opt!LowFunIndex opIndex = body_(*fun).match!(Opt!LowFunIndex)(
			(ConcreteFunBody.Builtin it) {
				if (isFunOrActSubscript(program, *fun)) {
					ConcreteStruct* funStruct = mustBeByVal(fun.paramsIncludingClosure[0].type);
					LowType funType = lowTypeFromConcreteStruct(getLowTypeCtx, funStruct);
					LowType returnType =
						lowTypeFromConcreteType(getLowTypeCtx, fun.returnType);
					LowType[] nonFunParamTypes = map(
						getLowTypeCtx.alloc,
						fun.paramsIncludingClosure[1 .. $],
						(ref ConcreteLocal x) =>
							lowTypeFromConcreteType(getLowTypeCtx, x.type));
					// TODO: is it possible that we call a fun type but it's not implemented anywhere?
					Opt!(ConcreteLambdaImpl[]) optImpls = program.funStructToImpls[funStruct];
					ConcreteLambdaImpl[] impls = has(optImpls)
						? force(optImpls)
						: [];
					return some(addLowFun(LowFunCause(
						LowFunCause.CallWithCtx(funType, returnType, nonFunParamTypes, impls))));
				} else if (isMarkVisitFun(program, *fun)) {
					if (!lateIsSet(markCtxTypeLate))
						lateSet(markCtxTypeLate, lowTypeFromConcreteType(
							getLowTypeCtx,
							fun.paramsIncludingClosure[0].type));
					return some(generateMarkVisitForType(lowTypeFromConcreteType(getLowTypeCtx, only(it.typeArgs))));
				} else
					return none!LowFunIndex;
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
				Opt!Sym optName = name(*fun);
				push(
					getLowTypeCtx.alloc,
					getOrAdd(getLowTypeCtx.alloc, allExternFuns, x.libraryName, () => MutArr!Sym()),
					force(optName));
				return some(addLowFun(LowFunCause(fun)));
			},
			(ConcreteExpr _) =>
				some(addLowFun(LowFunCause(fun))),
			(ConcreteFunBody.FlagsFn) =>
				none!LowFunIndex,
			(ConcreteFunBody.RecordFieldGet) =>
				none!LowFunIndex,
			(ConcreteFunBody.RecordFieldSet) =>
				none!LowFunIndex,
			(ConcreteFunBody.ThreadLocal) {
				LowThreadLocalIndex index = LowThreadLocalIndex(arrBuilderSize(threadLocals));
				LowType type =
					*lowTypeFromConcreteType(getLowTypeCtx, fun.returnType).as!(LowType.PtrRawMut).pointee;
				add(getLowTypeCtx.alloc, threadLocals, LowThreadLocal(fun, type));
				mustAddToDict(getLowTypeCtx.alloc, threadLocalIndicesBuilder, fun, index);
				return none!LowFunIndex;
			});
		if (concreteFunWillBecomeNonExternLowFun(program, *fun))
			verify(has(opIndex));
		if (has(opIndex))
			mustAddToDict(getLowTypeCtx.alloc, concreteFunToLowFunIndexBuilder, fun, force(opIndex));
	}

	LowType markCtxType = lateIsSet(markCtxTypeLate) ? lateGet(markCtxTypeLate) : voidType;

	LowFunCause[] lowFunCauses = finishArr(getLowTypeCtx.alloc, lowFunCausesBuilder);
	ConcreteFunToLowFunIndex concreteFunToLowFunIndex =
		finishDict(getLowTypeCtx.alloc, concreteFunToLowFunIndexBuilder);
	//TODO: use temp alloc
	ConcreteFunToThreadLocalIndex concreteFunToThreadLocalIndex =
		finishDict(getLowTypeCtx.alloc, threadLocalIndicesBuilder);

	LowType userMainFunPtrType =
		lowTypeFromConcreteType(getLowTypeCtx, program.rtMain.paramsIncludingClosure[2].type);

	LowFunIndex markFunIndex = mustGetAt(concreteFunToLowFunIndex, program.markFun);
	LowFunIndex allocFunIndex = mustGetAt(concreteFunToLowFunIndex, program.allocFun);
	LowFunIndex throwImplFunIndex = mustGetAt(concreteFunToLowFunIndex, program.throwImplFun);
	FullIndexDict!(LowFunIndex, LowFun) allLowFuns = fullIndexDictOfArr!(LowFunIndex, LowFun)(
		mapWithIndexAndConcatOne(
			getLowTypeCtx.alloc,
			lowFunCauses,
			(size_t index, ref LowFunCause cause) =>
				lowFunFromCause(
					allTypes,
					program.allConstants.staticSymbols,
					getLowTypeCtx,
					allocFunIndex,
					throwImplFunIndex,
					concreteFunToLowFunIndex,
					concreteFunToThreadLocalIndex,
					lowFunCauses,
					markVisitFuns,
					markCtxType,
					markFunIndex,
					LowFunIndex(index),
					cause),
			mainFun(
				getLowTypeCtx,
				mustGetAt(concreteFunToLowFunIndex, program.rtMain),
				program.userMain,
				userMainFunPtrType)));

	return AllLowFuns(
		concreteFunToLowFunIndex,
		allLowFuns,
		LowFunIndex(lowFunCauses.length),
		mapToArr_mut!(ExternLibrary, Sym, MutArr!Sym)(
			getLowTypeCtx.alloc,
			allExternFuns,
			(Sym libraryName, ref MutArr!Sym xs) =>
				ExternLibrary(
					libraryName,
					configExtern[libraryName],
					moveToArr!Sym(getLowTypeCtx.alloc, xs))),
		fullIndexDictOfArr!(LowThreadLocalIndex, LowThreadLocal)(finishArr(getLowTypeCtx.alloc, threadLocals)));
}

alias ConcreteFunToThreadLocalIndex = Dict!(ConcreteFun*, LowThreadLocalIndex);

bool concreteFunWillBecomeNonExternLowFun(in ConcreteProgram program, in ConcreteFun a) =>
	body_(a).match!bool(
		(ConcreteFunBody.Builtin) =>
			isFunOrActSubscript(program, a) || isMarkVisitFun(program, a),
		(Constant _) =>
			false,
		(ConcreteFunBody.CreateRecord) =>
			false,
		(ConcreteFunBody.CreateUnion) =>
			false,
		(EnumFunction _) =>
			false,
		(ConcreteFunBody.Extern) =>
			false,
		(ConcreteExpr _) =>
			true,
		(ConcreteFunBody.FlagsFn) =>
			false,
		(ConcreteFunBody.RecordFieldGet) =>
			false,
		(ConcreteFunBody.RecordFieldSet) =>
			false,
		(ConcreteFunBody.ThreadLocal) =>
			false);

LowFun lowFunFromCause(
	ref AllLowTypes allTypes,
	in Constant staticSymbols,
	ref GetLowTypeCtx getLowTypeCtx,
	LowFunIndex allocFunIndex,
	LowFunIndex throwImplFunIndex,
	in ConcreteFunToLowFunIndex concreteFunToLowFunIndex,
	in ConcreteFunToThreadLocalIndex concreteFunToThreadLocalIndex,
	in LowFunCause[] lowFunCauses,
	in MarkVisitFuns markVisitFuns,
	LowType markCtxType,
	LowFunIndex markFun,
	LowFunIndex thisFunIndex,
	LowFunCause cause,
) =>
	cause.matchWithPointers!LowFun(
		(LowFunCause.CallWithCtx it) =>
			generateCallWithCtxFun(
				getLowTypeCtx.alloc,
				allTypes,
				concreteFunToLowFunIndex,
				it.returnType,
				it.funType,
				it.nonFunParamTypes,
				it.impls),
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
				concreteFunToThreadLocalIndex,
				allocFunIndex,
				throwImplFunIndex,
				thisFunIndex,
				params,
				*cf);
			return LowFun(LowFunSource(cf), returnType, params, body_);
		},
		(LowFunCause.MarkVisitArrOuter x) {
			LowType.PtrRawConst elementPointerType = getElementPtrTypeFromArrType(allTypes, x.arrType);
			Opt!LowFunIndex markVisitElement = tryGetMarkVisitFun(markVisitFuns, *elementPointerType.pointee);
			return generateMarkVisitArr(
				getLowTypeCtx.alloc, markCtxType, markFun, x.arrType, elementPointerType, markVisitElement);
		},
		(LowFunCause.MarkVisitNonArr it) =>
			generateMarkVisitNonArr(getLowTypeCtx.alloc, allTypes, markVisitFuns, markCtxType, it.type),
		(LowFunCause.MarkVisitGcPtr it) =>
			generateMarkVisitGcPtr(getLowTypeCtx.alloc, markCtxType, markFun, it.pointerType, it.visitPointee));

LowFun mainFun(ref GetLowTypeCtx ctx, LowFunIndex rtMainIndex, ConcreteFun* userMain, LowType userMainFunPtrType) {
	LowLocal[] params = arrLiteral!LowLocal(ctx.alloc, [
		genLocalByValue(ctx.alloc, sym!"argc", 0, int32Type),
		genLocalByValue(ctx.alloc, sym!"argv", 1, char8PtrPtrConstType)]);
	LowExpr userMainFunPtr =
		LowExpr(userMainFunPtrType, FileAndRange.empty, LowExprKind(Constant(Constant.FunPtr(userMain))));
	LowExpr call = LowExpr(
		int32Type,
		FileAndRange.empty,
		LowExprKind(LowExprKind.Call(
			rtMainIndex,
			arrLiteral!LowExpr(ctx.alloc, [
				genLocalGet(FileAndRange.empty, &params[0]),
				genLocalGet(FileAndRange.empty, &params[1]),
				userMainFunPtr]))));
	LowFunBody body_ = LowFunBody(LowFunExprBody(false, call));
	return LowFun(
		LowFunSource(allocate(ctx.alloc, LowFunSource.Generated(sym!"main", []))),
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
			LowLocalSource(allocate(alloc, LowLocalSource.Generated(sym!"closure", getIndex()))),
		(ConcreteLocalSource.Generated x) =>
			LowLocalSource(allocate(alloc, LowLocalSource.Generated(x.name, getIndex()))));

T withLowLocal(T)(
	ref GetLowExprCtx ctx,
	in Locals locals,
	ConcreteLocal* concreteLocal,
	in T delegate(in Locals, LowLocal*) @safe @nogc pure nothrow cb,
) {
	LowType typeByVal = lowTypeFromConcreteType(ctx.typeCtx, concreteLocal.type);
	LowType type = concreteLocal.isAllocated ? getLowGcPtrType(ctx.typeCtx, typeByVal) : typeByVal;
	LowLocal* local = allocate(ctx.alloc, LowLocal(getLowLocalSource(ctx, concreteLocal.source), type));
	Locals newLocals = addLocal(locals, concreteLocal, local);
	return cb(newLocals, local);
}

T withOptLowLocal(T)(
	ref GetLowExprCtx ctx,
	in Locals locals,
	Opt!(ConcreteLocal*) concreteLocal,
	in T delegate(in Locals, Opt!(LowLocal*)) @safe @nogc pure nothrow cb,
) =>
	has(concreteLocal)
		? withLowLocal!T(ctx, locals, force(concreteLocal), (in Locals newLocals, LowLocal* local) =>
			cb(newLocals, some(local)))
		: cb(locals, none!(LowLocal*));

LowFunBody getLowFunBody(
	in AllLowTypes allTypes,
	in Constant staticSymbols,
	ref GetLowTypeCtx getLowTypeCtx,
	in ConcreteFunToLowFunIndex concreteFunToLowFunIndex,
	in ConcreteFunToThreadLocalIndex concreteFunToThreadLocalIndex,
	LowFunIndex allocFunIndex,
	LowFunIndex throwImplFunIndex,
	LowFunIndex thisFunIndex,
	LowLocal[] params,
	ref ConcreteFun a,
) =>
	body_(a).match!LowFunBody(
		(ConcreteFunBody.Builtin) =>
			unreachable!LowFunBody,
		(Constant _) =>
			unreachable!LowFunBody,
		(ConcreteFunBody.CreateRecord) =>
			unreachable!LowFunBody,
		(ConcreteFunBody.CreateUnion) =>
			unreachable!LowFunBody,
		(EnumFunction) =>
			unreachable!LowFunBody,
		(ConcreteFunBody.Extern x) =>
			LowFunBody(LowFunBody.Extern(x.isGlobal, x.libraryName)),
		(ConcreteExpr x) @trusted {
			GetLowExprCtx exprCtx = GetLowExprCtx(
				thisFunIndex,
				ptrTrustMe(allTypes),
				staticSymbols,
				ptrTrustMe(getLowTypeCtx),
				concreteFunToLowFunIndex,
				concreteFunToThreadLocalIndex,
				allocFunIndex,
				throwImplFunIndex,
				a.paramsIncludingClosure,
				params,
				false,
				a.paramsIncludingClosure.length);
			Locals locals;
			LowExpr expr = getLowExpr(exprCtx, locals, x, ExprPos.tail);
			return LowFunBody(LowFunExprBody(exprCtx.hasTailRecur, expr));
		},
		(ConcreteFunBody.FlagsFn) =>
			unreachable!LowFunBody,
		(ConcreteFunBody.RecordFieldGet) =>
			unreachable!LowFunBody,
		(ConcreteFunBody.RecordFieldSet) =>
			unreachable!LowFunBody,
		(ConcreteFunBody.ThreadLocal) =>
			unreachable!LowFunBody);

struct GetLowExprCtx {
	@safe @nogc pure nothrow:

	immutable LowFunIndex currentFun;
	immutable AllLowTypes* allTypes;
	immutable Constant staticSymbols;
	GetLowTypeCtx* getLowTypeCtxPtr;
	immutable ConcreteFunToLowFunIndex concreteFunToLowFunIndex;
	immutable ConcreteFunToThreadLocalIndex concreteFunToThreadLocalIndex;
	immutable LowFunIndex allocFunIndex;
	immutable LowFunIndex throwImplFunIndex;
	ConcreteLocal[] concreteParams;
	LowLocal[] lowParams;
	bool hasTailRecur;
	size_t tempLocalIndex;

	ref Alloc alloc() return scope =>
		typeCtx.alloc;

	ref typeCtx() return scope =>
		*getLowTypeCtxPtr;

	ref const(AllSymbols) allSymbols() return scope =>
		typeCtx.allSymbols();
}

alias Locals = immutable StackDict2!(ConcreteLocal*, LowLocal*, ConcreteExprKind.Loop*, LowExprKind.Loop*);
alias addLocal = stackDict2Add0!(ConcreteLocal*, LowLocal*, ConcreteExprKind.Loop*, LowExprKind.Loop*);
alias addLoop = stackDict2Add1!(ConcreteLocal*, LowLocal*, ConcreteExprKind.Loop*, LowExprKind.Loop*);
LowLocal* getLocal(ref GetLowExprCtx ctx, in Locals locals, in ConcreteLocal* local) {
	Opt!size_t paramIndex = indexOfPointer(ctx.concreteParams, local);
	return has(paramIndex)
		? &ctx.lowParams[force(paramIndex)]
		: stackDict2MustGet0!(ConcreteLocal*, LowLocal*, ConcreteExprKind.Loop*, LowExprKind.Loop*)(
			castNonScope_ref(locals), local);
}

alias getLoop = stackDict2MustGet1!(ConcreteLocal*, LowLocal*, ConcreteExprKind.Loop*, LowExprKind.Loop*);

Opt!LowFunIndex tryGetLowFunIndex(in GetLowExprCtx ctx, ConcreteFun* it) =>
	ctx.concreteFunToLowFunIndex[it];

size_t nextTempLocalIndex(ref GetLowExprCtx ctx) {
	size_t res = ctx.tempLocalIndex;
	ctx.tempLocalIndex++;
	return res;
}

LowLocal* addTempLocal(ref GetLowExprCtx ctx, LowType type) =>
	genLocal(ctx.alloc, sym!"temp", nextTempLocalIndex(ctx), type);

enum ExprPos {
	tail,
	nonTail,
}

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
		(ConcreteExprKind.Call it) =>
			getCallExpr(ctx, locals, exprPos, expr.range, type, it),
		(ConcreteExprKind.ClosureCreate it) =>
			getClosureCreateExpr(ctx, locals, expr.range, type, it),
		(ref ConcreteExprKind.ClosureGet it) =>
			getClosureGetExpr(ctx, expr.range, it),
		(ref ConcreteExprKind.ClosureSet it) =>
			getClosureSetExpr(ctx, locals, expr.range, it),
		(ref ConcreteExprKind.Cond it) =>
			LowExprKind(allocate(ctx.alloc, LowExprKind.If(
				getLowExpr(ctx, locals, it.cond, ExprPos.nonTail),
				getLowExpr(ctx, locals, it.then, exprPos),
				getLowExpr(ctx, locals, it.else_, exprPos)))),
		(Constant it) =>
			LowExprKind(it),
		(ref ConcreteExprKind.CreateArr it) =>
			getCreateArrExpr(ctx, locals, expr.range, it),
		(ConcreteExprKind.CreateRecord it) =>
			LowExprKind(LowExprKind.CreateRecord(getArgs(ctx, locals, it.args))),
		(ref ConcreteExprKind.CreateUnion it) =>
			LowExprKind(allocate(ctx.alloc, LowExprKind.CreateUnion(
				it.memberIndex,
				getLowExpr(ctx, locals, it.arg, ExprPos.nonTail)))),
		(ref ConcreteExprKind.Drop it) =>
			getDropExpr(ctx, locals, expr.range, it),
		(ConcreteExprKind.Lambda it) =>
			getLambdaExpr(ctx, locals, expr.range, it),
		(ref ConcreteExprKind.Let it) =>
			getLetExpr(ctx, locals, exprPos, expr.range, it),
		(ConcreteExprKind.LocalGet it) =>
			getLocalGetExpr(ctx, locals, type, expr.range, it),
		(ref ConcreteExprKind.LocalSet it) =>
			getLocalSetExpr(ctx, locals, expr.range, it),
		(ref ConcreteExprKind.Loop it) =>
			getLoopExpr(ctx, locals, exprPos, type, it),
		(ref ConcreteExprKind.LoopBreak it) =>
			getLoopBreakExpr(ctx, locals, exprPos, it),
		(ConcreteExprKind.LoopContinue it) =>
			// Ignore exprPos, this is always non-tail
			getLoopContinueExpr(ctx, locals, it),
		(ref ConcreteExprKind.MatchEnum it) =>
			getMatchEnumExpr(ctx, locals, exprPos, it),
		(ref ConcreteExprKind.MatchUnion it) =>
			getMatchUnionExpr(ctx, locals, exprPos, it),
		(ref ConcreteExprKind.PtrToField it) =>
			getPtrToFieldExpr(ctx, locals, it),
		(ConcreteExprKind.PtrToLocal it) =>
			getPtrToLocalExpr(ctx, locals, expr.range, it),
		(ConcreteExprKind.RecordFieldGet x) =>
			getRecordFieldGet(ctx, locals, *x.record, x.fieldIndex),
		(ref ConcreteExprKind.Seq it) =>
			LowExprKind(allocate(ctx.alloc, LowExprKind.Seq(
				getLowExpr(ctx, locals, it.first, ExprPos.nonTail),
				getLowExpr(ctx, locals, it.then, exprPos)))),
		(ref ConcreteExprKind.Throw it) =>
			getThrowExpr(ctx, locals, expr.range, type, it));

LowExpr getAllocateExpr(
	ref Alloc alloc,
	LowFunIndex allocFunIndex,
	FileAndRange range,
	LowType ptrType,
	ref LowExpr size,
) {
	LowExpr allocate = LowExpr(
		anyPtrMutType, //TODO: ensure this will definitely be the return type of allocFunIndex
		range,
		LowExprKind(LowExprKind.Call(allocFunIndex, arrLiteral!LowExpr(alloc, [size]))));
	return genPtrCast(alloc, ptrType, range, allocate);
}

LowExprKind getAllocExpr(ref GetLowExprCtx ctx, in Locals locals, FileAndRange range, ref ConcreteExprKind.Alloc a) {
	// (temp0 = (T*) alloc(sizeof(T)), *temp0 = inner, temp0)
	LowExpr inner = getLowExpr(ctx, locals, a.inner, ExprPos.nonTail);
	LowType ptrType = getLowGcPtrType(ctx.typeCtx, inner.type);
	return getAllocExpr2(ctx, range, inner, ptrType);
}

LowExpr getAllocExpr2Expr(ref GetLowExprCtx ctx, FileAndRange range, ref LowExpr inner, LowType ptrType) =>
	LowExpr(ptrType, range, getAllocExpr2(ctx, range, inner, ptrType));

LowExprKind getAllocExpr2(ref GetLowExprCtx ctx, FileAndRange range, ref LowExpr inner, LowType ptrType) {
	LowLocal* local = addTempLocal(ctx, ptrType);
	LowExpr sizeofT = genSizeOf(range, asPtrGcPointee(ptrType));
	LowExpr allocatePtr = getAllocateExpr(ctx.alloc, ctx.allocFunIndex, range, ptrType, sizeofT);
	LowExpr getTemp = genLocalGet(range, local);
	LowExpr setTemp = genWriteToPtr(ctx.alloc, range, getTemp, inner);
	return LowExprKind(allocate(ctx.alloc, LowExprKind.Let(
		local, allocatePtr, genSeq(ctx.alloc, range, setTemp, getTemp))));
}

LowExprKind getLoopExpr(
	ref GetLowExprCtx ctx,
	in Locals locals,
	ExprPos exprPos,
	LowType type,
	ref ConcreteExprKind.Loop a,
) {
	immutable LowExprKind.Loop* res = allocate(ctx.alloc, LowExprKind.Loop());
	Locals newLocals = addLoop(locals, ptrTrustMe(a), res);
	// Go ahead and give the body the same 'exprPos'. 'continue' will know it's non-tail.
	overwriteMemory(&res.body_, getLowExpr(ctx, newLocals, a.body_, exprPos));
	return LowExprKind(res);
}

//TODO: not @trusted
@trusted LowExprKind getLoopBreakExpr(
	ref GetLowExprCtx ctx,
	in Locals locals,
	ExprPos exprPos,
	in ConcreteExprKind.LoopBreak a,
) =>
	LowExprKind(allocate(ctx.alloc, LowExprKind.LoopBreak(
		getLoop(locals, a.loop),
		getLowExpr(ctx, locals, a.value, exprPos))));

@trusted LowExprKind getLoopContinueExpr(
	ref GetLowExprCtx ctx,
	in Locals locals,
	in ConcreteExprKind.LoopContinue a,
) =>
	LowExprKind(LowExprKind.LoopContinue(getLoop(locals, a.loop)));

LowExprKind getCallExpr(
	ref GetLowExprCtx ctx,
	in Locals locals,
	ExprPos exprPos,
	FileAndRange range,
	LowType type,
	ref ConcreteExprKind.Call a,
) {
	Opt!LowFunIndex opCalled = tryGetLowFunIndex(ctx, a.called);
	return has(opCalled)
		? getCallRegular(ctx, locals, exprPos, a, force(opCalled))
		: getCallSpecial(ctx, locals, exprPos, range, type, a);
}

LowExprKind getCallRegular(
	ref GetLowExprCtx ctx,
	in Locals locals,
	ExprPos exprPos,
	in ConcreteExprKind.Call a,
	LowFunIndex called,
) {
	if (called == ctx.currentFun && exprPos == ExprPos.tail) {
		ctx.hasTailRecur = true;
		ArrBuilder!UpdateParam updateParams;
		zipPtrFirst(ctx.lowParams, a.args, (LowLocal* param, ref ConcreteExpr concreteArg) {
			LowExpr arg = getLowExpr(ctx, locals, concreteArg, ExprPos.nonTail);
			if (!(arg.kind.isA!(LowExprKind.LocalGet) && arg.kind.as!(LowExprKind.LocalGet).local == param))
				add(ctx.alloc, updateParams, UpdateParam(param, arg));
		});
		return LowExprKind(LowExprKind.TailRecur(finishArr(ctx.alloc, updateParams)));
	} else
		return LowExprKind(LowExprKind.Call(called, map(ctx.alloc, a.args, (ref ConcreteExpr it) =>
			getLowExpr(ctx, locals, it, ExprPos.nonTail))));
}

LowExprKind getCallSpecial(
	ref GetLowExprCtx ctx,
	in Locals locals,
	ExprPos exprPos,
	FileAndRange range,
	LowType type,
	ref ConcreteExprKind.Call a,
) =>
	body_(*a.called).match!LowExprKind(
		(ConcreteFunBody.Builtin) =>
			getCallBuiltinExpr(ctx, locals, exprPos, range, type, a),
		(Constant x) =>
			LowExprKind(x),
		(ConcreteFunBody.CreateRecord) {
			LowExpr[] args = getArgs(ctx, locals, a.args);
			LowExprKind create = LowExprKind(LowExprKind.CreateRecord(args));
			if (type.isA!(LowType.PtrGc)) {
				LowExpr inner = LowExpr(asPtrGcPointee(type), range, create);
				return getAllocExpr2(ctx, range, inner, type);
			} else
				return create;
		},
		(ConcreteFunBody.CreateUnion x) {
			LowExpr arg = empty(a.args)
				? genVoid(range)
				: getLowExpr(ctx, locals, only(a.args), ExprPos.nonTail);
			return LowExprKind(allocate(ctx.alloc, LowExprKind.CreateUnion(x.memberIndex, arg)));
		},
		(EnumFunction x) =>
			genEnumFunction(ctx, locals, x, a.args),
		(ConcreteFunBody.Extern) =>
			unreachable!LowExprKind,
		(ConcreteExpr _) =>
			unreachable!LowExprKind,
		(ConcreteFunBody.FlagsFn x) {
			final switch (x.fn) {
				case FlagsFunction.all:
					return LowExprKind(Constant(Constant.Integral(x.allValue)));
				case FlagsFunction.negate:
					return genFlagsNegate(
						ctx.alloc,
						range,
						x.allValue,
						getLowExpr(ctx, locals, only(a.args), ExprPos.nonTail));
				case FlagsFunction.new_:
					return LowExprKind(Constant(Constant.Integral(0)));
			}
		},
		(ConcreteFunBody.RecordFieldGet x) =>
			getRecordFieldGet(ctx, locals, only(a.args), x.fieldIndex),
		(ConcreteFunBody.RecordFieldSet x) {
			verify(a.args.length == 2);
			return LowExprKind(allocate(ctx.alloc, LowExprKind.RecordFieldSet(
				getLowExpr(ctx, locals, a.args[0], ExprPos.nonTail),
				x.fieldIndex,
				getLowExpr(ctx, locals, a.args[1], ExprPos.nonTail))));
		},
		(ConcreteFunBody.ThreadLocal) {
			LowThreadLocalIndex index = mustGetAt(ctx.concreteFunToThreadLocalIndex, a.called);
			return LowExprKind(LowExprKind.ThreadLocalPtr(index));
		});


LowExprKind getRecordFieldGet(ref GetLowExprCtx ctx, in Locals locals, ref ConcreteExpr record, size_t fieldIndex) =>
	LowExprKind(allocate(ctx.alloc, LowExprKind.RecordFieldGet(
		getLowExpr(ctx, locals, record, ExprPos.nonTail),
		fieldIndex)));

LowExprKind genFlagsNegate(ref Alloc alloc, FileAndRange range, ulong allValue, LowExpr a) =>
	genEnumIntersect(
		alloc,
		LowExpr(a.type, range, genBitwiseNegate(alloc, a)),
		LowExpr(a.type, range, LowExprKind(Constant(Constant.Integral(allValue)))));

LowExprKind genEnumFunction(
	ref GetLowExprCtx ctx,
	in Locals locals,
	EnumFunction a,
	ConcreteExpr[] args,
) {
	LowExpr arg0() { return getLowExpr(ctx, locals, args[0], ExprPos.nonTail); }
	LowExpr arg1() { return getLowExpr(ctx, locals, args[1], ExprPos.nonTail); }
	final switch (a) {
		case EnumFunction.equal:
			verify(args.length == 2);
			return genEnumEq(ctx.alloc, arg0(), arg1());
		case EnumFunction.intersect:
			verify(args.length == 2);
			return genEnumIntersect(ctx.alloc, arg0(), arg1());
		case EnumFunction.toIntegral:
			verify(args.length == 1);
			return genEnumToIntegral(ctx.alloc, arg0());
		case EnumFunction.union_:
			verify(args.length == 2);
			return genEnumUnion(ctx.alloc, arg0(), arg1());
		case EnumFunction.members:
			// In concretize, this was translated to a constant
			return unreachable!LowExprKind;
	}
}

LowExpr[] getArgs(ref GetLowExprCtx ctx, in Locals locals, ConcreteExpr[] args) =>
	map(ctx.alloc, args, (ref ConcreteExpr arg) =>
		getLowExpr(ctx, locals, arg, ExprPos.nonTail));

// cbWrap will only be called if this is not a plain argument array
LowExprKind callFunPtr(
	ref GetLowExprCtx ctx,
	in Locals locals,
	FileAndRange range,
	LowType type,
	ConcreteExpr[2] funPtrAndArg,
) {
	LowExprKind doCall(LowExpr funPtr, LowExpr[] args) {
		return LowExprKind(allocate(ctx.alloc, LowExprKind.CallFunPtr(funPtr, args)));
	}
	LowExpr doCallExpr(LowExpr funPtr, LowExpr[] args) {
		return LowExpr(type, range, doCall(funPtr, args));
	}

	LowExpr funPtr = getLowExpr(ctx, locals, funPtrAndArg[0], ExprPos.nonTail);
	LowExpr arg = getLowExpr(ctx, locals, funPtrAndArg[1], ExprPos.nonTail);
	Opt!(LowType[]) optArgTypes = tryUnpackTuple(ctx.alloc, ctx.allTypes.allRecords, arg.type);
	if (has(optArgTypes)) {
		LowType[] argTypes = force(optArgTypes);
		return arg.kind.isA!(LowExprKind.CreateRecord)
			? doCall(funPtr, arg.kind.as!(LowExprKind.CreateRecord).args)
			: argTypes.length == 0
			// Making sure the side effect order is function then arg
			? genLetTemp(ctx.alloc, range, nextTempLocalIndex(ctx), funPtr, (LowExpr getFunPtr) =>
				genSeq(ctx.alloc, range, arg, doCallExpr(getFunPtr, []))).kind
			: genLetTemp(ctx.alloc, range, nextTempLocalIndex(ctx), funPtr, (LowExpr getFunPtr) =>
				genLetTemp(ctx.alloc, range, nextTempLocalIndex(ctx), arg, (LowExpr getArg) =>
					doCallExpr(getFunPtr, mapWithIndex!(LowExpr, LowType)(
						ctx.alloc, argTypes, (size_t argIndex, ref LowType argType) =>
							genRecordFieldGet(ctx.alloc, range, getArg, argType, argIndex))))).kind;
	} else
		return doCall(funPtr, arrLiteral!LowExpr(ctx.alloc, [arg]));
}

LowExprKind getCallBuiltinExpr(
	ref GetLowExprCtx ctx,
	in Locals locals,
	ExprPos exprPos,
	FileAndRange range,
	LowType type,
	ref ConcreteExprKind.Call a,
) {
	Sym name = a.called.source.as!(FunInst*).name;
	LowType paramType(size_t index) {
		return index < a.args.length
			? lowTypeFromConcreteType(ctx.typeCtx, a.called.paramsIncludingClosure[index].type)
			: voidType;
	}
	LowExpr getArg(ref ConcreteExpr arg, ExprPos argPos) {
		return getLowExpr(ctx, locals, arg, argPos);
	}
	LowType p0 = paramType(0);
	LowType p1 = paramType(1);
	BuiltinKind builtinKind = getBuiltinKind(ctx.alloc, name, type, p0, p1);
	return builtinKind.match!LowExprKind(
		(BuiltinKind.CallFunPointer) =>
			callFunPtr(ctx, locals, range, type, only2(a.args)),
		(Constant it) =>
			LowExprKind(it),
		(BuiltinKind.InitConstants) =>
			LowExprKind(LowExprKind.InitConstants()),
		(LowExprKind.SpecialUnary.Kind kind) {
			verify(a.args.length == 1);
			return LowExprKind(allocate(ctx.alloc, LowExprKind.SpecialUnary(kind, getArg(a.args[0], ExprPos.nonTail))));
		},
		(LowExprKind.SpecialBinary.Kind kind) {
			verify(a.args.length == 2);
			ExprPos arg1Pos = () {
				switch (kind) {
					case LowExprKind.SpecialBinary.Kind.and:
					case LowExprKind.SpecialBinary.Kind.orBool:
						return exprPos;
					default:
						return ExprPos.nonTail;
				}
			}();
			return LowExprKind(allocate(ctx.alloc, LowExprKind.SpecialBinary(
				kind,
				getArg(a.args[0], ExprPos.nonTail),
				getArg(a.args[1], arg1Pos))));
		},
		(LowExprKind.SpecialTernary.Kind kind) {
			verify(a.args.length == 3);
			return LowExprKind(allocate(ctx.alloc, LowExprKind.SpecialTernary(kind, [
				getArg(a.args[0], ExprPos.nonTail),
				getArg(a.args[1], ExprPos.nonTail),
				getArg(a.args[2], ExprPos.nonTail)])));
		},
		(BuiltinKind.OptOr) {
			verify(a.args.length == 2);
			verify(p0 == p1);
			LowLocal* lhsLocal = addTempLocal(ctx, p0);
			LowExpr lhsRef = genLocalGet(range, lhsLocal);
			return LowExprKind(allocate(ctx.alloc, LowExprKind.Let(
				lhsLocal,
				getArg(a.args[0], ExprPos.nonTail),
				LowExpr(p0, range, LowExprKind(allocate(ctx.alloc, LowExprKind.MatchUnion(
					lhsRef,
					arrLiteral!(LowExprKind.MatchUnion.Case)(ctx.alloc, [
						LowExprKind.MatchUnion.Case(none!(LowLocal*), getArg(a.args[1], ExprPos.tail)),
						LowExprKind.MatchUnion.Case(none!(LowLocal*), lhsRef)]))))))));
		},
		(BuiltinKind.OptQuestion2) {
			verify(a.args.length == 2);
			LowLocal* valueLocal = addTempLocal(ctx, p1);
			return LowExprKind(allocate(ctx.alloc, LowExprKind.MatchUnion(
				getArg(a.args[0], ExprPos.nonTail),
				arrLiteral!(LowExprKind.MatchUnion.Case)(ctx.alloc, [
					LowExprKind.MatchUnion.Case(none!(LowLocal*), getArg(a.args[1], ExprPos.tail)),
					LowExprKind.MatchUnion.Case(some(valueLocal), genLocalGet(range, valueLocal))]))));
		},
		(BuiltinKind.PointerCast) {
			verify(a.args.length == 1);
			return genPtrCastKind(ctx.alloc, getLowExpr(ctx, locals, only(a.args), ExprPos.nonTail));
		},
		(BuiltinKind.SizeOf) {
			LowType typeArg =
				lowTypeFromConcreteType(ctx.typeCtx, only(body_(*a.called).as!(ConcreteFunBody.Builtin).typeArgs));
			return LowExprKind(LowExprKind.SizeOf(typeArg));
		},
		(BuiltinKind.StaticSymbols) =>
			LowExprKind(ctx.staticSymbols));
}

LowExprKind getCreateArrExpr(
	ref GetLowExprCtx ctx,
	in Locals locals,
	FileAndRange range,
	in ConcreteExprKind.CreateArr a,
) {
	// (temp = _alloc(ctx, sizeof(foo) * 2),
	// *(temp + 0) = a,
	// *(temp + 1) = b,
	// arr_foo{2, temp})
	LowType arrType = lowTypeFromConcreteStruct(ctx.typeCtx, a.arrType);
	LowType elementType = lowTypeFromConcreteType(ctx.typeCtx, elementType(a));
	LowType elementPtrType = getLowRawPtrConstType(ctx.typeCtx, elementType);
	LowExpr elementSize = genSizeOf(range, elementType);
	LowExpr nElements = genConstantNat64(range, a.args.length);
	LowExpr sizeBytes = genWrapMulNat64(ctx.alloc, range, elementSize, nElements);
	LowExpr allocatePtr = getAllocateExpr(ctx.alloc, ctx.allocFunIndex, range, elementPtrType, sizeBytes);
	LowLocal* temp = addTempLocal(ctx, elementPtrType);
	LowExpr getTemp = genLocalGet(range, temp);
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
				getTemp,
				genConstantNat64(range, index));
			LowExpr writeToElement = genWriteToPtr(ctx.alloc, range, elementPtr, arg);
			return recur(genSeq(ctx.alloc, range, writeToElement, cur), index);
		}
	}
	LowExpr createArr = LowExpr(arrType, range, LowExprKind(
		LowExprKind.CreateRecord(arrLiteral!LowExpr(ctx.alloc, [nElements, genLocalGet(range, temp)]))));
	LowExpr writeAndGetArr = recur(createArr, a.args.length);
	return LowExprKind(allocate(ctx.alloc, LowExprKind.Let(temp, allocatePtr, writeAndGetArr)));
}

LowExprKind getDropExpr(ref GetLowExprCtx ctx, in Locals locals, FileAndRange range, ref ConcreteExprKind.Drop a) {
	LowExpr arg = getLowExpr(ctx, locals, a.arg, ExprPos.nonTail);
	return genDrop(ctx.alloc, range, arg, nextTempLocalIndex(ctx)).kind;
}

LowExprKind getLambdaExpr(ref GetLowExprCtx ctx, in Locals locals, FileAndRange range, in ConcreteExprKind.Lambda a) =>
	LowExprKind(allocate(ctx.alloc, LowExprKind.CreateUnion(
		a.memberIndex,
		has(a.closure)
			? getLowExpr(ctx, locals, *force(a.closure), ExprPos.nonTail)
			: genVoid(range))));

LowExprKind getLetExpr(
	ref GetLowExprCtx ctx,
	in Locals locals,
	ExprPos exprPos,
	FileAndRange range,
	ref ConcreteExprKind.Let a,
) {
	LowExpr valueByVal = getLowExpr(ctx, locals, a.value, ExprPos.nonTail);
	LowExpr value = a.local.isAllocated
		? getAllocExpr2Expr(ctx, range, valueByVal, getLowGcPtrType(ctx.typeCtx, valueByVal.type))
		: valueByVal;
	return withLowLocal!LowExprKind(ctx, locals, a.local, (in Locals innerLocals, LowLocal* local) =>
		LowExprKind(allocate(ctx.alloc, LowExprKind.Let(local, value, getLowExpr(ctx, innerLocals, a.then, exprPos)))));
}

LowExprKind getLocalGetExpr(
	ref GetLowExprCtx ctx,
	in Locals locals,
	LowType type,
	FileAndRange range,
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
	FileAndRange range,
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
	FileAndRange range,
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

LowExprKind getMatchEnumExpr(
	ref GetLowExprCtx ctx,
	in Locals locals,
	ExprPos exprPos,
	ref ConcreteExprKind.MatchEnum a,
) {
	ConcreteStructBody.Enum enum_ = body_(*mustBeByVal(a.matchedValue.type)).as!(ConcreteStructBody.Enum);
	LowExpr matchedValue = getLowExpr(ctx, locals, a.matchedValue, ExprPos.nonTail);
	LowExpr[] cases = map(ctx.alloc, a.cases, (ref ConcreteExpr case_) =>
		getLowExpr(ctx, locals, case_, exprPos));
	return enum_.values.match!LowExprKind(
		(size_t) =>
			LowExprKind(allocate(ctx.alloc, LowExprKind.Switch0ToN(matchedValue, cases))),
		(EnumValue[] values) =>
			LowExprKind(allocate(ctx.alloc, LowExprKind.SwitchWithValues(matchedValue, values, cases))));
}

LowExprKind getMatchUnionExpr(
	ref GetLowExprCtx ctx,
	in Locals locals,
	ExprPos exprPos,
	ref ConcreteExprKind.MatchUnion a,
) {
	LowExpr matched = getLowExpr(ctx, locals, a.matchedValue, ExprPos.nonTail);
	return LowExprKind(allocate(ctx.alloc, LowExprKind.MatchUnion(
		matched,
		map(ctx.alloc, a.cases, (ref ConcreteExprKind.MatchUnion.Case case_) =>
			withOptLowLocal!(LowExprKind.MatchUnion.Case)(
				ctx, locals, case_.local, (in Locals caseLocals, Opt!(LowLocal*) local) =>
					LowExprKind.MatchUnion.Case(local, getLowExpr(ctx, caseLocals, case_.then, exprPos)))))));
}

LowExprKind getClosureCreateExpr(
	ref GetLowExprCtx ctx,
	in Locals locals,
	FileAndRange range,
	LowType type,
	in ConcreteExprKind.ClosureCreate a,
) {
	LowRecord record = ctx.allTypes.allRecords[type.as!(LowType.Record)];
	return LowExprKind(LowExprKind.CreateRecord(
		mapZip!(LowExpr, ConcreteVariableRef, LowField)(
			ctx.alloc, a.args, record.fields,
			(ref ConcreteVariableRef x, ref LowField f) =>
				getVariableRefExprForClosure(ctx, locals, range, f.type, x))));
}

LowExpr getVariableRefExprForClosure(
	ref GetLowExprCtx ctx,
	in Locals locals,
	FileAndRange range,
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

LowExprKind getClosureGetExpr(ref GetLowExprCtx ctx, FileAndRange range, ConcreteExprKind.ClosureGet a) {
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
	FileAndRange range,
	ref ConcreteExprKind.ClosureSet a,
) =>
	// Note: This doesn't write to a field, it gets a pointer from the field and writes to that
	genWriteToPtr(
		ctx.alloc,
		getClosureField(ctx, range, a.closureRef),
		getLowExpr(ctx, locals, a.value, ExprPos.nonTail));

// NOTE: This does not dereference pointer for mutAllocated, getClosureGetExpr will do that
LowExpr getClosureField(ref GetLowExprCtx ctx, FileAndRange range, ConcreteClosureRef closureRef) {
	LowLocal* closureLocal = &ctx.lowParams[0];
	LowExpr closureGet = genLocalGet(range, closureLocal);
	LowRecord record = ctx.allTypes.allRecords[asPtrGcPointee(closureLocal.type).as!(LowType.Record)];
	return LowExpr(record.fields[closureRef.fieldIndex].type, range, LowExprKind(allocate(ctx.alloc,
		LowExprKind.RecordFieldGet(closureGet, closureRef.fieldIndex))));
}

LowExprKind getPtrToFieldExpr(ref GetLowExprCtx ctx, in Locals locals, ref ConcreteExprKind.PtrToField a) =>
	LowExprKind(allocate(ctx.alloc,
		LowExprKind.PtrToField(getLowExpr(ctx, locals, a.target, ExprPos.nonTail), a.fieldIndex)));

LowExprKind getThrowExpr(
	ref GetLowExprCtx ctx,
	in Locals locals,
	FileAndRange range,
	LowType type,
	ref ConcreteExprKind.Throw a,
) {
	LowExprKind callThrow = LowExprKind(LowExprKind.Call(
		ctx.throwImplFunIndex,
		arrLiteral!LowExpr(ctx.alloc, [getLowExpr(ctx, locals, a.thrown, ExprPos.nonTail)])));
	return type == voidType
		? callThrow
		: LowExprKind(allocate(ctx.alloc, LowExprKind.Seq(
			LowExpr(voidType, range, callThrow),
			LowExpr(type, range, LowExprKind(constantZero)))));
}
