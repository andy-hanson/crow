module lower.lower;

@safe @nogc pure nothrow:

import lower.checkLowModel : checkLowProgram;
import lower.generateCallWithCtxFun : generateCallWithCtxFun;
import lower.generateMarkVisitFun :
	generateMarkVisitArrInner,
	generateMarkVisitArrOuter,
	generateMarkVisitNonArr,
	generateMarkVisitGcPtr;
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
	genLocal,
	genLocalGet,
	genParam,
	genParamGet,
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
	ConcreteFunSource,
	ConcreteLambdaImpl,
	ConcreteLocal,
	ConcreteParam,
	ConcreteProgram,
	ConcreteStruct,
	ConcreteStructBody,
	ConcreteType,
	ConcreteVariableRef,
	elementType,
	fieldOffsets,
	isCallWithCtxFun,
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
	LowParam,
	LowParamIndex,
	LowParamSource,
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
	decl,
	ClosureReferenceKind,
	ConfigExternPaths,
	EnumBackingType,
	EnumFunction,
	EnumValue,
	FlagsFunction,
	FunInst,
	name,
	range;
import util.alloc.alloc : Alloc;
import util.col.arr : empty, only;
import util.col.arrBuilder : add, ArrBuilder, arrBuilderSize, finishArr;
import util.col.arrUtil :
	arrLiteral,
	exists,
	map,
	mapPtrsWithOptFirst,
	mapZip,
	mapZipPtrFirst,
	mapWithIndexAndConcatOne;
import util.col.dict : mustGetAt, Dict;
import util.col.dictBuilder : finishDict, mustAddToDict, DictBuilder;
import util.col.fullIndexDict : FullIndexDict, fullIndexDictOfArr, fullIndexDictSize;
import util.col.mutIndexDict : getOrAddAndDidAdd, mustGetAt, MutIndexDict, newMutIndexDict;
import util.col.mutArr : moveToArr, MutArr, push;
import util.col.mutDict : getAt_mut, getOrAdd, mapToArr_mut, MutDict, MutDict, ValueAndDidAdd;
import util.col.stackDict : StackDict2, stackDict2Add0, stackDict2Add1, stackDict2MustGet0, stackDict2MustGet1;
import util.late : Late, late, lateGet, lateIsSet, lateSet;
import util.memory : allocate, allocateMut, overwriteMemory;
import util.opt : force, has, none, Opt, some;
import util.perf : Perf, PerfMeasure, withMeasure;
import util.ptr : castNonScope_ref, ptrTrustMe;
import util.sourceRange : FileAndRange;
import util.sym : AllSymbols, Sym, sym;
import util.union_ : Union;
import util.util : as, unreachable, verify;

immutable(LowProgram) lower(
	ref Alloc alloc,
	scope ref Perf perf,
	ref const AllSymbols allSymbols,
	scope ref immutable ConfigExternPaths configExtern,
	ref immutable ConcreteProgram a,
) =>
	withMeasure!(immutable LowProgram, () =>
		lowerInner(alloc, allSymbols, configExtern, a)
	)(alloc, perf, PerfMeasure.lower);

private immutable(LowProgram) lowerInner(
	ref Alloc alloc,
	ref const AllSymbols allSymbols,
	scope ref immutable ConfigExternPaths configExtern,
	ref immutable ConcreteProgram a,
) {
	AllLowTypesWithCtx allTypes = getAllLowTypes(ptrTrustMe(alloc), ptrTrustMe(allSymbols), a);
	immutable AllLowFuns allFuns = getAllLowFuns(allTypes.allTypes, allTypes.getLowTypeCtx, configExtern, a);
	immutable AllConstantsLow allConstants = convertAllConstants(allTypes.getLowTypeCtx, a.allConstants);
	immutable LowProgram res = immutable LowProgram(
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
	MutDict!(immutable LowType, immutable LowFunIndex) gcPointeeToVisit;
}

immutable(LowFunIndex) getMarkVisitFun(ref const MarkVisitFuns funs, immutable LowType type) {
	immutable Opt!LowFunIndex opt = tryGetMarkVisitFun(funs, type);
	return force(opt);
}

immutable(Opt!LowFunIndex) tryGetMarkVisitFun(ref const MarkVisitFuns funs, immutable LowType type) =>
	type.match!(immutable Opt!LowFunIndex)(
		(immutable LowType.Extern) =>
			none!LowFunIndex,
		(immutable LowType.FunPtr) =>
			none!LowFunIndex,
		(immutable PrimitiveType it) =>
			none!LowFunIndex,
		(immutable LowType.PtrGc it) =>
			getAt_mut(funs.gcPointeeToVisit, *it.pointee),
		(immutable LowType.PtrRawConst) =>
			none!LowFunIndex,
		(immutable LowType.PtrRawMut) =>
			none!LowFunIndex,
		(immutable LowType.Record it) =>
			as!(immutable Opt!LowFunIndex)(funs.recordValToVisit[it]),
		(immutable LowType.Union it) =>
			as!(immutable Opt!LowFunIndex)(funs.unionToVisit[it]));

private:

immutable(AllConstantsLow) convertAllConstants(
	ref GetLowTypeCtx ctx,
	ref immutable AllConstantsConcrete a,
) {
	immutable ArrTypeAndConstantsLow[] arrs = map(ctx.alloc, a.arrs, (ref immutable ArrTypeAndConstantsConcrete it) {
		immutable LowType arrType = lowTypeFromConcreteStruct(ctx, it.arrType);
		immutable LowType elementType = lowTypeFromConcreteType(ctx, it.elementType);
		return immutable ArrTypeAndConstantsLow(arrType.as!(LowType.Record), elementType, it.constants);
	});
	immutable PointerTypeAndConstantsLow[] records =
		map(ctx.alloc, a.pointers, (ref immutable PointerTypeAndConstantsConcrete it) =>
			immutable PointerTypeAndConstantsLow(lowTypeFromConcreteStruct(ctx, it.pointeeType), it.constants));
	return immutable AllConstantsLow(a.cStrings, arrs, records);
}

struct AllLowTypesWithCtx {
	immutable AllLowTypes allTypes;
	GetLowTypeCtx getLowTypeCtx;
}

struct AllLowFuns {
	immutable ConcreteFunToLowFunIndex concreteFunToLowFunIndex;
	immutable FullIndexDict!(LowFunIndex, LowFun) allLowFuns;
	immutable LowFunIndex main;
	immutable ExternLibraries allExternFuns;
	immutable FullIndexDict!(LowThreadLocalIndex, LowThreadLocal) threadLocals;
}

struct GetLowTypeCtx {
	@safe @nogc pure nothrow:

	Alloc* allocPtr;
	const AllSymbols* allSymbolsPtr;
	immutable Dict!(ConcreteStruct*, LowType) concreteStructToType;
	MutDict!(immutable ConcreteStruct*, immutable LowType) concreteStructToPtrType;
	MutDict!(immutable ConcreteStruct*, immutable LowType) concreteStructToPtrPtrType;

	ref Alloc alloc() return scope =>
		*allocPtr;

	ref const(AllSymbols) allSymbols() return scope const =>
		*allSymbolsPtr;
}

AllLowTypesWithCtx getAllLowTypes(
	Alloc* allocPtr,
	const AllSymbols* allSymbolsPtr,
	ref immutable ConcreteProgram program,
) {
	ref Alloc alloc() { return *allocPtr; }

	DictBuilder!(ConcreteStruct*, LowType) concreteStructToTypeBuilder;
	ArrBuilder!(ConcreteStruct*) allFunPointerSources;
	ArrBuilder!LowExternType allExternTypes;
	ArrBuilder!(ConcreteStruct*) allRecordSources;
	ArrBuilder!(ConcreteStruct*) allUnionSources;

	immutable(LowType) addUnion(immutable ConcreteStruct* s) {
		immutable size_t i = arrBuilderSize(allUnionSources);
		add(alloc, allUnionSources, s);
		return immutable LowType(immutable LowType.Union(i));
	}

	foreach (immutable ConcreteStruct* concrete; program.allStructs) {
		immutable Opt!LowType lowType = body_(*concrete).match!(immutable Opt!LowType)(
			(immutable ConcreteStructBody.Builtin it) {
				final switch (it.kind) {
					case BuiltinStructKind.bool_:
						return some(immutable LowType(PrimitiveType.bool_));
					case BuiltinStructKind.char8:
						return some(immutable LowType(PrimitiveType.char8));
					case BuiltinStructKind.float32:
						return some(immutable LowType(PrimitiveType.float32));
					case BuiltinStructKind.float64:
						return some(immutable LowType(PrimitiveType.float64));
					case BuiltinStructKind.fun:
						return some(addUnion(concrete));
					case BuiltinStructKind.funPointerN: {
						immutable size_t i = arrBuilderSize(allFunPointerSources);
						add(alloc, allFunPointerSources, concrete);
						return some(immutable LowType(immutable LowType.FunPtr(i)));
					}
					case BuiltinStructKind.int8:
						return some(immutable LowType(PrimitiveType.int8));
					case BuiltinStructKind.int16:
						return some(immutable LowType(PrimitiveType.int16));
					case BuiltinStructKind.int32:
						return some(immutable LowType(PrimitiveType.int32));
					case BuiltinStructKind.int64:
						return some(immutable LowType(PrimitiveType.int64));
					case BuiltinStructKind.nat8:
						return some(immutable LowType(PrimitiveType.nat8));
					case BuiltinStructKind.nat16:
						return some(immutable LowType(PrimitiveType.nat16));
					case BuiltinStructKind.nat32:
						return some(immutable LowType(PrimitiveType.nat32));
					case BuiltinStructKind.nat64:
						return some(immutable LowType(PrimitiveType.nat64));
					case BuiltinStructKind.pointerConst:
					case BuiltinStructKind.pointerMut:
						return none!LowType;
					case BuiltinStructKind.void_:
						return some(immutable LowType(PrimitiveType.void_));
				}
			},
			(immutable ConcreteStructBody.Enum it) =>
				some(immutable LowType(typeForEnum(it.backingType))),
			(immutable ConcreteStructBody.Extern it) {
				immutable size_t i = arrBuilderSize(allExternTypes);
				add(alloc, allExternTypes, immutable LowExternType(concrete));
				return some(immutable LowType(immutable LowType.Extern(i)));
			},
			(immutable ConcreteStructBody.Flags it) =>
				some(immutable LowType(typeForEnum(it.backingType))),
			(immutable ConcreteStructBody.Record it) {
				immutable size_t i = arrBuilderSize(allRecordSources);
				add(alloc, allRecordSources, concrete);
				return some(immutable LowType(immutable LowType.Record(i)));
			},
			(immutable ConcreteStructBody.Union it) =>
				some(addUnion(concrete)));
		if (has(lowType))
			mustAddToDict(alloc, concreteStructToTypeBuilder, concrete, force(lowType));
	}

	GetLowTypeCtx getLowTypeCtx = GetLowTypeCtx(
		allocPtr,
		allSymbolsPtr,
		finishDict(alloc, concreteStructToTypeBuilder));

	immutable FullIndexDict!(LowType.FunPtr, LowFunPtrType) allFunPointers =
		fullIndexDictOfArr!(LowType.FunPtr, LowFunPtrType)(
			map(alloc, finishArr(alloc, allFunPointerSources), (ref immutable ConcreteStruct* it) {
				immutable ConcreteType[] typeArgs = body_(*it).as!(ConcreteStructBody.Builtin).typeArgs;
				immutable LowType returnType = lowTypeFromConcreteType(getLowTypeCtx, typeArgs[0]);
				immutable LowType[] paramTypes =
					map(alloc, typeArgs[1 .. $], (ref immutable ConcreteType typeArg) =>
						lowTypeFromConcreteType(getLowTypeCtx, typeArg));
				return immutable LowFunPtrType(it, returnType, paramTypes);
			}));
	immutable FullIndexDict!(LowType.Record, LowRecord) allRecords =
		fullIndexDictOfArr!(LowType.Record, LowRecord)(
			map(alloc, finishArr(alloc, allRecordSources), (ref immutable ConcreteStruct* it) =>
				immutable LowRecord(
					it,
					mapZipPtrFirst!(LowField, ConcreteField, size_t)(
						alloc,
						body_(*it).as!(ConcreteStructBody.Record).fields,
						fieldOffsets(*it),
						(immutable ConcreteField* field, ref immutable size_t fieldOffset) =>
							immutable LowField(
								field,
								fieldOffset,
								lowTypeFromConcreteType(getLowTypeCtx, field.type))))));
	immutable FullIndexDict!(LowType.Union, LowUnion) allUnions =
		fullIndexDictOfArr!(LowType.Union, LowUnion)(
			map(alloc, finishArr(alloc, allUnionSources), (ref immutable ConcreteStruct* it) =>
				getLowUnion(program, getLowTypeCtx, it)));

	return AllLowTypesWithCtx(
		immutable AllLowTypes(
			fullIndexDictOfArr!(LowType.Extern, LowExternType)(finishArr(alloc, allExternTypes)),
			allFunPointers,
			allRecords,
			allUnions),
		getLowTypeCtx);
}

immutable(PrimitiveType) typeForEnum(immutable EnumBackingType a) {
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

immutable(LowUnion) getLowUnion(
	ref immutable ConcreteProgram program,
	ref GetLowTypeCtx getLowTypeCtx,
	immutable ConcreteStruct* s,
) =>
	immutable LowUnion(s, body_(*s).match!(immutable LowType[])(
		(immutable ConcreteStructBody.Builtin it) {
			verify(it.kind == BuiltinStructKind.fun);
			return map(
				getLowTypeCtx.alloc,
				mustGetAt(program.funStructToImpls, s),
				(ref immutable ConcreteLambdaImpl impl) =>
					lowTypeFromConcreteType(getLowTypeCtx, impl.closureType));
		},
		(immutable(ConcreteStructBody.Enum)) => unreachable!(immutable LowType[])(),
		(immutable(ConcreteStructBody.Extern)) => unreachable!(immutable LowType[])(),
		(immutable(ConcreteStructBody.Flags)) => unreachable!(immutable LowType[])(),
		(immutable(ConcreteStructBody.Record)) => unreachable!(immutable LowType[])(),
		(immutable ConcreteStructBody.Union it) =>
			map(getLowTypeCtx.alloc, it.members, (ref immutable Opt!ConcreteType member) =>
				has(member)
					? lowTypeFromConcreteType(getLowTypeCtx, force(member))
					: immutable LowType(PrimitiveType.void_))));

immutable(LowType) getLowRawPtrConstType(ref GetLowTypeCtx ctx, immutable LowType pointee) {
	//TODO:PERF Cache creation of pointer types by pointee
	return immutable LowType(immutable LowType.PtrRawConst(allocate(ctx.alloc, pointee)));
}

immutable(LowType) getLowGcPtrType(
	ref GetLowTypeCtx ctx,
	immutable LowType pointee,
) {
	//TODO:PERF Cache creation of pointer types by pointee
	return immutable LowType(immutable LowType.PtrGc(allocate(ctx.alloc, pointee)));
}

immutable(LowType) lowTypeFromConcreteStruct(ref GetLowTypeCtx ctx, immutable ConcreteStruct* it) {
	immutable Opt!LowType res = ctx.concreteStructToType[it];
	if (has(res))
		return force(res);
	else {
		immutable ConcreteStructBody.Builtin builtin = body_(*it).as!(ConcreteStructBody.Builtin);
		//TODO: cache the creation.. don't want an allocation for every BuiltinStructKind.ptr to the same target type
		immutable LowType* inner = allocate(ctx.alloc, lowTypeFromConcreteType(ctx, only(builtin.typeArgs)));
		switch (builtin.kind) {
			case BuiltinStructKind.pointerConst:
				return immutable LowType(immutable LowType.PtrRawConst(inner));
			case BuiltinStructKind.pointerMut:
				return immutable LowType(immutable LowType.PtrRawMut(inner));
			default:
				return unreachable!(immutable LowType);
		}
	}
}

immutable(LowType) lowTypeFromConcreteType(ref GetLowTypeCtx ctx, immutable ConcreteType it) {
	immutable LowType inner = lowTypeFromConcreteStruct(ctx, it.struct_);
	immutable(LowType) wrapInRef(immutable LowType x) =>
		immutable LowType(immutable LowType.PtrGc(allocate(ctx.alloc, x)));
	immutable(LowType) byRef() =>
		getOrAdd(ctx.alloc, ctx.concreteStructToPtrType, it.struct_, () => wrapInRef(inner));
	final switch (it.reference) {
		case ReferenceKind.byVal:
			return inner;
		case ReferenceKind.byRef:
			return byRef();
		case ReferenceKind.byRefRef:
			return getOrAdd(ctx.alloc, ctx.concreteStructToPtrPtrType, it.struct_, () => wrapInRef(byRef()));
	}
}

struct LowFunCause {
	struct CallWithCtx {
		immutable LowType funType;
		immutable LowType returnType;
		immutable LowType[] nonFunParamTypes;
		immutable ConcreteLambdaImpl[] impls;
	}
	struct MarkVisitArrInner {
		immutable LowType.PtrRawConst elementPtrType;
	}
	struct MarkVisitArrOuter {
		immutable LowType.Record arrType;
		immutable Opt!LowFunIndex inner;
	}
	struct MarkVisitNonArr { //TODO: this is record (by-val) or union. Maybe split?
		immutable LowType type;
	}
	struct MarkVisitGcPtr {
		immutable LowType.PtrGc pointerType;
		immutable Opt!LowFunIndex visitPointee;
	}

	mixin Union!(
		immutable CallWithCtx,
		immutable ConcreteFun*,
		immutable MarkVisitArrInner,
		immutable MarkVisitArrOuter,
		immutable MarkVisitNonArr,
		immutable MarkVisitGcPtr);
}

immutable(bool) needsMarkVisitFun(ref immutable AllLowTypes allTypes, immutable LowType a) =>
	a.match!(immutable bool)(
		(immutable LowType.Extern) =>
			false,
		(immutable LowType.FunPtr) =>
			false,
		(immutable PrimitiveType) =>
			false,
		(immutable LowType.PtrGc) =>
			true,
		(immutable LowType.PtrRawConst) =>
			false,
		(immutable LowType.PtrRawMut) =>
			false,
		(immutable LowType.Record it) {
			immutable LowRecord record = allTypes.allRecords[it];
			return isArray(record) || exists!(immutable LowField)(record.fields, (ref immutable LowField field) =>
				needsMarkVisitFun(allTypes, field.type));
		},
		(immutable LowType.Union it) =>
			exists!(immutable LowType)(allTypes.allUnions[it].members, (ref immutable LowType member) =>
				needsMarkVisitFun(allTypes, member)));

immutable(AllLowFuns) getAllLowFuns(
	ref immutable AllLowTypes allTypes,
	ref GetLowTypeCtx getLowTypeCtx,
	scope ref immutable ConfigExternPaths configExtern,
	ref immutable ConcreteProgram program,
) {
	DictBuilder!(ConcreteFun*, LowFunIndex) concreteFunToLowFunIndexBuilder;
	ArrBuilder!LowFunCause lowFunCausesBuilder;

	MarkVisitFuns markVisitFuns = MarkVisitFuns(
		newMutIndexDict!(LowType.Record, LowFunIndex)(getLowTypeCtx.alloc, fullIndexDictSize(allTypes.allRecords)),
		newMutIndexDict!(LowType.Union, LowFunIndex)(getLowTypeCtx.alloc, fullIndexDictSize(allTypes.allUnions)));

	immutable(LowFunIndex) addLowFun(immutable LowFunCause source) {
		immutable LowFunIndex res = immutable LowFunIndex(arrBuilderSize(lowFunCausesBuilder));
		add(getLowTypeCtx.alloc, lowFunCausesBuilder, source);
		return res;
	}

	immutable(LowFunIndex) generateMarkVisitForType(immutable LowType lowType) @safe @nogc pure nothrow {
		verify(needsMarkVisitFun(allTypes, lowType));
		immutable(LowFunIndex) addNonArr() =>
			addLowFun(immutable LowFunCause(immutable LowFunCause.MarkVisitNonArr(lowType)));
		immutable(Opt!LowFunIndex) maybeGenerateMarkVisitForType(immutable LowType t) @safe @nogc pure nothrow =>
			needsMarkVisitFun(allTypes, t) ? some(generateMarkVisitForType(t)) : none!LowFunIndex;

		return lowType.match!(immutable LowFunIndex)(
			(immutable LowType.Extern) =>
				unreachable!(immutable LowFunIndex),
			(immutable LowType.FunPtr) =>
				unreachable!(immutable LowFunIndex),
			(immutable PrimitiveType it) =>
				unreachable!(immutable LowFunIndex),
			(immutable LowType.PtrGc it) {
				immutable Opt!LowFunIndex visitPointee = maybeGenerateMarkVisitForType(*it.pointee);
				return getOrAdd(
					getLowTypeCtx.alloc,
					markVisitFuns.gcPointeeToVisit,
					*it.pointee,
					() =>
						addLowFun(immutable LowFunCause(immutable LowFunCause.MarkVisitGcPtr(it, visitPointee))));
			},
			(immutable LowType.PtrRawConst) =>
				unreachable!(immutable LowFunIndex),
			(immutable LowType.PtrRawMut) =>
				unreachable!(immutable LowFunIndex),
			(immutable LowType.Record it) {
				immutable LowRecord record = allTypes.allRecords[it];
				if (isArray(record)) {
					immutable LowType.PtrRawConst elementPtrType = getElementPtrTypeFromArrType(allTypes, it);
					immutable ValueAndDidAdd!LowFunIndex outerIndex = getOrAddAndDidAdd!(LowType.Record, LowFunIndex)(
						markVisitFuns.recordValToVisit,
						it,
						() {
							immutable Opt!LowFunIndex innerIndex =
								needsMarkVisitFun(allTypes, *elementPtrType.pointee)
								? some(addLowFun(
									immutable LowFunCause(immutable LowFunCause.MarkVisitArrInner(elementPtrType))))
								: none!LowFunIndex;
							return addLowFun(
								immutable LowFunCause(immutable LowFunCause.MarkVisitArrOuter(it, innerIndex)));
						});
					if (outerIndex.didAdd)
						maybeGenerateMarkVisitForType(*elementPtrType.pointee);
					return outerIndex.value;
				} else {
					immutable ValueAndDidAdd!LowFunIndex index = getOrAddAndDidAdd(
						markVisitFuns.recordValToVisit,
						it,
						() => addNonArr());
					if (index.didAdd)
						foreach (ref immutable LowField field; record.fields)
							maybeGenerateMarkVisitForType(field.type);
					return index.value;
				}
			},
			(immutable LowType.Union it) {
				immutable ValueAndDidAdd!LowFunIndex index =
					getOrAddAndDidAdd(markVisitFuns.unionToVisit, it, () => addNonArr());
				if (index.didAdd)
					foreach (immutable LowType member; allTypes.allUnions[it].members)
						maybeGenerateMarkVisitForType(member);
				return index.value;
			});
	}

	Late!(immutable LowType) markCtxTypeLate = late!(immutable LowType);

	MutDict!(immutable Sym, MutArr!(immutable Sym)) allExternFuns;

	ArrBuilder!LowThreadLocal threadLocals;
	DictBuilder!(ConcreteFun*, LowThreadLocalIndex) threadLocalIndicesBuilder;

	foreach (immutable ConcreteFun* fun; program.allFuns) {
		immutable Opt!LowFunIndex opIndex = body_(*fun).match!(immutable Opt!LowFunIndex)(
			(immutable ConcreteFunBody.Builtin it) {
				if (isCallWithCtxFun(program, *fun)) {
					immutable ConcreteStruct* funStruct =
						mustBeByVal(fun.paramsExcludingClosure[0].type);
					immutable LowType funType = lowTypeFromConcreteStruct(getLowTypeCtx, funStruct);
					immutable LowType returnType =
						lowTypeFromConcreteType(getLowTypeCtx, fun.returnType);
					immutable LowType[] nonFunParamTypes = map(
						getLowTypeCtx.alloc,
						fun.paramsExcludingClosure[1 .. $],
						(ref immutable ConcreteParam it) =>
							lowTypeFromConcreteType(getLowTypeCtx, it.type));
					// TODO: is it possible that we call a fun type but it's not implemented anywhere?
					immutable Opt!(ConcreteLambdaImpl[]) optImpls = program.funStructToImpls[funStruct];
					immutable ConcreteLambdaImpl[] impls = has(optImpls)
						? force(optImpls)
						: [];
					return some(addLowFun(immutable LowFunCause(
						immutable LowFunCause.CallWithCtx(funType, returnType, nonFunParamTypes, impls))));
				} else if (isMarkVisitFun(program, *fun)) {
					if (!lateIsSet(markCtxTypeLate))
						lateSet(markCtxTypeLate, lowTypeFromConcreteType(
							getLowTypeCtx,
							fun.paramsExcludingClosure[0].type));
					immutable LowFunIndex res =
						generateMarkVisitForType(lowTypeFromConcreteType(getLowTypeCtx, only(it.typeArgs)));
					return some(res);
				} else
					return none!LowFunIndex;
			},
			(immutable(Constant)) =>
				none!LowFunIndex,
			(immutable ConcreteFunBody.CreateRecord) =>
				none!LowFunIndex,
			(immutable ConcreteFunBody.CreateUnion) =>
				none!LowFunIndex,
			(immutable EnumFunction) =>
				none!LowFunIndex,
			(immutable ConcreteFunBody.Extern x) {
				immutable Opt!Sym optName = name(*fun);
				push(
					getLowTypeCtx.alloc,
					getOrAdd(getLowTypeCtx.alloc, allExternFuns, x.libraryName, () => MutArr!(immutable Sym)()),
					force(optName));
				return some(addLowFun(immutable LowFunCause(fun)));
			},
			(immutable(ConcreteExpr)) =>
				some(addLowFun(immutable LowFunCause(fun))),
			(immutable ConcreteFunBody.FlagsFn) =>
				none!LowFunIndex,
			(immutable ConcreteFunBody.RecordFieldGet) =>
				none!LowFunIndex,
			(immutable ConcreteFunBody.RecordFieldSet) =>
				none!LowFunIndex,
			(immutable ConcreteFunBody.ThreadLocal) {
				immutable LowThreadLocalIndex index = immutable LowThreadLocalIndex(arrBuilderSize(threadLocals));
				immutable LowType type =
					*lowTypeFromConcreteType(getLowTypeCtx, fun.returnType).as!(LowType.PtrRawMut).pointee;
				add(getLowTypeCtx.alloc, threadLocals, immutable LowThreadLocal(fun, type));
				mustAddToDict(getLowTypeCtx.alloc, threadLocalIndicesBuilder, fun, index);
				return none!LowFunIndex;
			});
		if (concreteFunWillBecomeNonExternLowFun(program, *fun))
			verify(has(opIndex));
		if (has(opIndex))
			mustAddToDict(getLowTypeCtx.alloc, concreteFunToLowFunIndexBuilder, fun, force(opIndex));
	}

	immutable LowType markCtxType = lateIsSet(markCtxTypeLate) ? lateGet(markCtxTypeLate) : voidType;

	immutable LowFunCause[] lowFunCauses = finishArr(getLowTypeCtx.alloc, lowFunCausesBuilder);
	immutable ConcreteFunToLowFunIndex concreteFunToLowFunIndex =
		finishDict(getLowTypeCtx.alloc, concreteFunToLowFunIndexBuilder);
	//TODO: use temp alloc
	immutable ConcreteFunToThreadLocalIndex concreteFunToThreadLocalIndex =
		finishDict(getLowTypeCtx.alloc, threadLocalIndicesBuilder);

	immutable LowType userMainFunPtrType =
		lowTypeFromConcreteType(getLowTypeCtx, program.rtMain.paramsExcludingClosure[2].type);

	immutable LowFunIndex markFunIndex = mustGetAt(concreteFunToLowFunIndex, program.markFun);
	immutable LowFunIndex allocFunIndex = mustGetAt(concreteFunToLowFunIndex, program.allocFun);
	immutable LowFunIndex throwImplFunIndex = mustGetAt(concreteFunToLowFunIndex, program.throwImplFun);
	immutable FullIndexDict!(LowFunIndex, LowFun) allLowFuns = fullIndexDictOfArr!(LowFunIndex, LowFun)(
		mapWithIndexAndConcatOne(
			getLowTypeCtx.alloc,
			lowFunCauses,
			(immutable size_t index, ref immutable LowFunCause cause) =>
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
					immutable LowFunIndex(index),
					cause),
			mainFun(
				getLowTypeCtx,
				mustGetAt(concreteFunToLowFunIndex, program.rtMain),
				program.userMain,
				userMainFunPtrType)));

	return immutable AllLowFuns(
		concreteFunToLowFunIndex,
		allLowFuns,
		immutable LowFunIndex(lowFunCauses.length),
		mapToArr_mut!(ExternLibrary, immutable Sym, MutArr!(immutable Sym))(
			getLowTypeCtx.alloc,
			allExternFuns,
			(immutable Sym libraryName, ref MutArr!(immutable Sym) xs) =>
				immutable ExternLibrary(
					libraryName,
					configExtern[libraryName],
					moveToArr!Sym(getLowTypeCtx.alloc, xs))),
		fullIndexDictOfArr!(LowThreadLocalIndex, LowThreadLocal)(finishArr(getLowTypeCtx.alloc, threadLocals)));
}

alias ConcreteFunToThreadLocalIndex = immutable Dict!(ConcreteFun*, LowThreadLocalIndex);

immutable(bool) concreteFunWillBecomeNonExternLowFun(
	ref immutable ConcreteProgram program,
	ref immutable ConcreteFun a,
) =>
	body_(a).match!(immutable bool)(
		(immutable ConcreteFunBody.Builtin) =>
			isCallWithCtxFun(program, a) || isMarkVisitFun(program, a),
		(immutable(Constant)) =>
			false,
		(immutable ConcreteFunBody.CreateRecord) =>
			false,
		(immutable ConcreteFunBody.CreateUnion) =>
			false,
		(immutable(EnumFunction)) =>
			false,
		(immutable ConcreteFunBody.Extern) =>
			false,
		(immutable(ConcreteExpr)) =>
			true,
		(immutable ConcreteFunBody.FlagsFn) =>
			false,
		(immutable ConcreteFunBody.RecordFieldGet) =>
			false,
		(immutable ConcreteFunBody.RecordFieldSet) =>
			false,
		(immutable ConcreteFunBody.ThreadLocal) =>
			false);

immutable(LowFun) lowFunFromCause(
	ref immutable AllLowTypes allTypes,
	immutable Constant staticSymbols,
	ref GetLowTypeCtx getLowTypeCtx,
	immutable LowFunIndex allocFunIndex,
	immutable LowFunIndex throwImplFunIndex,
	scope ref immutable ConcreteFunToLowFunIndex concreteFunToLowFunIndex,
	scope ref immutable ConcreteFunToThreadLocalIndex concreteFunToThreadLocalIndex,
	ref immutable LowFunCause[] lowFunCauses,
	ref const MarkVisitFuns markVisitFuns,
	immutable LowType markCtxType,
	immutable LowFunIndex markFun,
	immutable LowFunIndex thisFunIndex,
	ref immutable LowFunCause cause,
) =>
	cause.matchWithPointers!(immutable LowFun)(
		(immutable LowFunCause.CallWithCtx it) =>
			generateCallWithCtxFun(
				getLowTypeCtx.alloc,
				allTypes,
				concreteFunToLowFunIndex,
				it.returnType,
				it.funType,
				it.nonFunParamTypes,
				it.impls),
		(immutable ConcreteFun* cf) {
			immutable LowType returnType = lowTypeFromConcreteType(getLowTypeCtx, cf.returnType);
			immutable Opt!LowParam closureParam = has(cf.closureParam)
				? some(getLowParam(getLowTypeCtx, force(cf.closureParam)))
				: none!LowParam;
			immutable LowParam[] params = mapPtrsWithOptFirst!(LowParam, ConcreteParam)(
				getLowTypeCtx.alloc,
				closureParam,
				cf.paramsExcludingClosure,
				(immutable ConcreteParam* it) =>
					getLowParam(getLowTypeCtx, it));
			immutable LowFunBody body_ = getLowFunBody(
				allTypes,
				staticSymbols,
				getLowTypeCtx,
				concreteFunToLowFunIndex,
				concreteFunToThreadLocalIndex,
				allocFunIndex,
				throwImplFunIndex,
				cf.closureParam,
				thisFunIndex,
				body_(*cf));
			return immutable LowFun(immutable LowFunSource(cf), returnType, params, body_);
		},
		(immutable LowFunCause.MarkVisitArrInner it) =>
			generateMarkVisitArrInner(getLowTypeCtx.alloc, markVisitFuns, markCtxType, it.elementPtrType),
		(immutable LowFunCause.MarkVisitArrOuter it) =>
			generateMarkVisitArrOuter(
				getLowTypeCtx.alloc,
				markCtxType,
				markFun,
				it.arrType,
				getElementPtrTypeFromArrType(allTypes, it.arrType),
				it.inner),
		(immutable LowFunCause.MarkVisitNonArr it) =>
			generateMarkVisitNonArr(getLowTypeCtx.alloc, allTypes, markVisitFuns, markCtxType, it.type),
		(immutable LowFunCause.MarkVisitGcPtr it) =>
			generateMarkVisitGcPtr(getLowTypeCtx.alloc, markCtxType, markFun, it.pointerType, it.visitPointee));

immutable(LowFun) mainFun(
	ref GetLowTypeCtx ctx,
	immutable LowFunIndex rtMainIndex,
	immutable ConcreteFun* userMain,
	immutable LowType userMainFunPtrType,
) {
	immutable LowParam[] params = arrLiteral!LowParam(ctx.alloc, [
		genParam(ctx.alloc, sym!"argc", int32Type),
		genParam(ctx.alloc, sym!"argv", char8PtrPtrConstType)]);
	immutable LowParamIndex argc = immutable LowParamIndex(0);
	immutable LowParamIndex argv = immutable LowParamIndex(1);
	immutable LowExpr userMainFunPtr = immutable LowExpr(
		userMainFunPtrType,
		FileAndRange.empty,
		immutable LowExprKind(immutable Constant(immutable Constant.FunPtr(userMain))));
	immutable LowExpr call = immutable LowExpr(
		int32Type,
		FileAndRange.empty,
		immutable LowExprKind(immutable LowExprKind.Call(
			rtMainIndex,
			arrLiteral!LowExpr(ctx.alloc, [
				genParamGet(FileAndRange.empty, int32Type, argc),
				genParamGet(FileAndRange.empty, char8PtrPtrConstType, argv),
				userMainFunPtr]))));
	immutable LowFunBody body_ = immutable LowFunBody(immutable LowFunExprBody(false, call));
	return immutable LowFun(
		immutable LowFunSource(allocate(ctx.alloc, immutable LowFunSource.Generated(sym!"main", []))),
		int32Type,
		params,
		body_);
}

immutable(LowParam) getLowParam(ref GetLowTypeCtx ctx, immutable ConcreteParam* a) =>
	immutable LowParam(immutable LowParamSource(a), lowTypeFromConcreteType(ctx, a.type));

immutable(T) withLowLocal(T)(
	ref GetLowExprCtx ctx,
	scope ref immutable Locals locals,
	immutable ConcreteLocal* concreteLocal,
	scope immutable(T) delegate(scope ref immutable Locals, immutable LowLocal*) @safe @nogc pure nothrow cb,
) {
	immutable LowType typeByVal = lowTypeFromConcreteType(ctx.typeCtx, concreteLocal.type);
	immutable LowType type = concreteLocal.isAllocated ? getLowGcPtrType(ctx.typeCtx, typeByVal) : typeByVal;
	immutable LowLocal* local =
		allocate(ctx.alloc, immutable LowLocal(immutable LowLocalSource(concreteLocal), type));
	scope immutable Locals newLocals = addLocal(castNonScope_ref(locals), concreteLocal, local);
	return cb(newLocals, local);
}

immutable(T) withOptLowLocal(T)(
	ref GetLowExprCtx ctx,
	scope ref immutable Locals locals,
	immutable Opt!(ConcreteLocal*) concreteLocal,
	scope immutable(T) delegate(scope ref immutable Locals, immutable Opt!(LowLocal*)) @safe @nogc pure nothrow cb,
) =>
	has(concreteLocal)
		? withLowLocal!T(
			ctx, locals, force(concreteLocal),
			(scope ref immutable Locals newLocals, immutable LowLocal* local) =>
				cb(newLocals, some(local)))
		: cb(locals, none!(LowLocal*));

immutable(LowFunBody) getLowFunBody(
	ref immutable AllLowTypes allTypes,
	ref immutable Constant staticSymbols,
	ref GetLowTypeCtx getLowTypeCtx,
	scope ref immutable ConcreteFunToLowFunIndex concreteFunToLowFunIndex,
	scope ref immutable ConcreteFunToThreadLocalIndex concreteFunToThreadLocalIndex,
	immutable LowFunIndex allocFunIndex,
	immutable LowFunIndex throwImplFunIndex,
	immutable Opt!(ConcreteParam*) closureParam,
	immutable LowFunIndex thisFunIndex,
	ref immutable ConcreteFunBody a,
) =>
	a.match!(immutable LowFunBody)(
		(immutable ConcreteFunBody.Builtin) =>
			unreachable!(immutable LowFunBody),
		(immutable(Constant)) =>
			unreachable!(immutable LowFunBody),
		(immutable ConcreteFunBody.CreateRecord) =>
			unreachable!(immutable LowFunBody),
		(immutable ConcreteFunBody.CreateUnion) =>
			unreachable!(immutable LowFunBody),
		(immutable EnumFunction) =>
			unreachable!(immutable LowFunBody),
		(immutable ConcreteFunBody.Extern x) =>
			immutable LowFunBody(immutable LowFunBody.Extern(x.isGlobal, x.libraryName)),
		(immutable ConcreteExpr x) @trusted {
			GetLowExprCtx exprCtx = GetLowExprCtx(
				thisFunIndex,
				ptrTrustMe(allTypes),
				staticSymbols,
				ptrTrustMe(getLowTypeCtx),
				concreteFunToLowFunIndex,
				concreteFunToThreadLocalIndex,
				allocFunIndex,
				throwImplFunIndex,
				has(closureParam)
					? some(lowTypeFromConcreteType(getLowTypeCtx, force(closureParam).type))
					: none!LowType,
				false);
			immutable Locals locals;
			immutable LowExpr expr = getLowExpr(exprCtx, locals, x, ExprPos.tail);
			return immutable LowFunBody(immutable LowFunExprBody(exprCtx.hasTailRecur, expr));
		},
		(immutable ConcreteFunBody.FlagsFn) =>
			unreachable!(immutable LowFunBody),
		(immutable ConcreteFunBody.RecordFieldGet) =>
			unreachable!(immutable LowFunBody),
		(immutable ConcreteFunBody.RecordFieldSet) =>
			unreachable!(immutable LowFunBody),
		(immutable ConcreteFunBody.ThreadLocal) =>
			unreachable!(immutable LowFunBody));

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
	immutable Opt!LowType closureParamType;
	bool hasTailRecur;
	size_t tempLocalIndex;

	ref Alloc alloc() return scope =>
		typeCtx.alloc;

	ref typeCtx() return scope =>
		*getLowTypeCtxPtr;

	ref const(AllSymbols) allSymbols() return scope =>
		typeCtx.allSymbols();
	
	immutable(bool) hasClosure() const =>
		has(closureParamType);
}

alias Locals = immutable StackDict2!(ConcreteLocal*, LowLocal*, ConcreteExprKind.Loop*, LowExprKind.Loop*);
alias addLocal = stackDict2Add0!(ConcreteLocal*, LowLocal*, ConcreteExprKind.Loop*, LowExprKind.Loop*);
alias addLoop = stackDict2Add1!(ConcreteLocal*, LowLocal*, ConcreteExprKind.Loop*, LowExprKind.Loop*);
alias getLocal = stackDict2MustGet0!(ConcreteLocal*, LowLocal*, ConcreteExprKind.Loop*, LowExprKind.Loop*);
alias getLoop = stackDict2MustGet1!(ConcreteLocal*, LowLocal*, ConcreteExprKind.Loop*, LowExprKind.Loop*);

immutable(Opt!LowFunIndex) tryGetLowFunIndex(ref const GetLowExprCtx ctx, immutable ConcreteFun* it) =>
	ctx.concreteFunToLowFunIndex[it];

immutable(size_t) getTempLocalIndex(ref GetLowExprCtx ctx) {
	immutable size_t res = ctx.tempLocalIndex;
	ctx.tempLocalIndex++;
	return res;
}

immutable(LowLocal*) addTempLocal(ref GetLowExprCtx ctx, immutable LowType type) =>
	genLocal(ctx.alloc, sym!"temp", getTempLocalIndex(ctx), type);

enum ExprPos {
	tail,
	nonTail,
}

immutable(LowExpr) getLowExpr(
	ref GetLowExprCtx ctx,
	scope ref immutable Locals locals,
	ref immutable ConcreteExpr expr,
	immutable ExprPos exprPos,
) {
	immutable LowType type = lowTypeFromConcreteType(ctx.typeCtx, expr.type);
	return immutable LowExpr(type, expr.range, getLowExprKind(ctx, locals, type, expr, exprPos));
}

immutable(LowExprKind) getLowExprKind(
	ref GetLowExprCtx ctx,
	scope ref immutable Locals locals,
	immutable LowType type,
	ref immutable ConcreteExpr expr,
	immutable ExprPos exprPos,
) =>
	expr.kind.match!(immutable LowExprKind)(
		(ref immutable ConcreteExprKind.Alloc it) =>
			getAllocExpr(ctx, locals, expr.range, it),
		(immutable ConcreteExprKind.Call it) =>
			getCallExpr(ctx, locals, exprPos, expr.range, type, it),
		(immutable ConcreteExprKind.ClosureCreate it) =>
			getClosureCreateExpr(ctx, locals, expr.range, type, it),
		(ref immutable ConcreteExprKind.ClosureGet it) =>
			getClosureGetExpr(ctx, expr.range, it),
		(ref immutable ConcreteExprKind.ClosureSet it) =>
			getClosureSetExpr(ctx, locals, expr.range, it),
		(ref immutable ConcreteExprKind.Cond it) =>
			immutable LowExprKind(allocate(ctx.alloc, immutable LowExprKind.If(
				getLowExpr(ctx, locals, it.cond, ExprPos.nonTail),
				getLowExpr(ctx, locals, it.then, exprPos),
				getLowExpr(ctx, locals, it.else_, exprPos)))),
		(immutable Constant it) =>
			immutable LowExprKind(it),
		(ref immutable ConcreteExprKind.CreateArr it) =>
			getCreateArrExpr(ctx, locals, expr.range, it),
		(immutable ConcreteExprKind.CreateRecord it) =>
			immutable LowExprKind(immutable LowExprKind.CreateRecord(getArgs(ctx, locals, it.args))),
		(ref immutable ConcreteExprKind.CreateUnion it) =>
			immutable LowExprKind(allocate(ctx.alloc, immutable LowExprKind.CreateUnion(
				it.memberIndex,
				getLowExpr(ctx, locals, it.arg, ExprPos.nonTail)))),
		(ref immutable ConcreteExprKind.Drop it) =>
			getDropExpr(ctx, locals, expr.range, it),
		(immutable ConcreteExprKind.Lambda it) =>
			getLambdaExpr(ctx, locals, expr.range, it),
		(ref immutable ConcreteExprKind.Let it) =>
			getLetExpr(ctx, locals, exprPos, expr.range, it),
		(immutable ConcreteExprKind.LocalGet it) =>
			getLocalGetExpr(ctx, locals, type, expr.range, it),
		(ref immutable ConcreteExprKind.LocalSet it) =>
			getLocalSetExpr(ctx, locals, expr.range, it),
		(ref immutable ConcreteExprKind.Loop it) =>
			getLoopExpr(ctx, locals, exprPos, type, it),
		(ref immutable ConcreteExprKind.LoopBreak it) =>
			getLoopBreakExpr(ctx, locals, exprPos, it),
		(immutable ConcreteExprKind.LoopContinue it) =>
			// Ignore exprPos, this is always non-tail
			getLoopContinueExpr(ctx, locals, it),
		(ref immutable ConcreteExprKind.MatchEnum it) =>
			getMatchEnumExpr(ctx, locals, exprPos, it),
		(ref immutable ConcreteExprKind.MatchUnion it) =>
			getMatchUnionExpr(ctx, locals, exprPos, it),
		(immutable ConcreteExprKind.ParamGet it) =>
			getParamGetExpr(ctx, it.param),
		(ref immutable ConcreteExprKind.PtrToField it) =>
			getPtrToFieldExpr(ctx, locals, it),
		(immutable ConcreteExprKind.PtrToLocal it) =>
			getPtrToLocalExpr(ctx, locals, expr.range, it),
		(immutable ConcreteExprKind.PtrToParam it) =>
			getPtrToParam(ctx, it),
		(ref immutable ConcreteExprKind.Seq it) =>
			immutable LowExprKind(allocate(ctx.alloc, immutable LowExprKind.Seq(
				getLowExpr(ctx, locals, it.first, ExprPos.nonTail),
				getLowExpr(ctx, locals, it.then, exprPos)))),
		(ref immutable ConcreteExprKind.Throw it) =>
			getThrowExpr(ctx, locals, expr.range, type, it));

immutable(LowExpr) getAllocateExpr(
	ref Alloc alloc,
	immutable LowFunIndex allocFunIndex,
	immutable FileAndRange range,
	immutable LowType ptrType,
	ref immutable LowExpr size,
) {
	immutable LowExpr allocate = immutable LowExpr(
		anyPtrMutType, //TODO: ensure this will definitely be the return type of allocFunIndex
		range,
		immutable LowExprKind(immutable LowExprKind.Call(allocFunIndex, arrLiteral!LowExpr(alloc, [size]))));
	return genPtrCast(alloc, ptrType, range, allocate);
}

immutable(LowExprKind) getAllocExpr(
	ref GetLowExprCtx ctx,
	scope ref immutable Locals locals,
	immutable FileAndRange range,
	ref immutable ConcreteExprKind.Alloc a,
) {
	// (temp0 = (T*) alloc(sizeof(T)), *temp0 = inner, temp0)
	immutable LowExpr inner = getLowExpr(ctx, locals, a.inner, ExprPos.nonTail);
	immutable LowType ptrType = getLowGcPtrType(ctx.typeCtx, inner.type);
	return getAllocExpr2(ctx, range, inner, ptrType);
}

immutable(LowExpr) getAllocExpr2Expr(
	ref GetLowExprCtx ctx,
	immutable FileAndRange range,
	ref immutable LowExpr inner,
	immutable LowType ptrType,
) =>
	immutable LowExpr(ptrType, range, getAllocExpr2(ctx, range, inner, ptrType));

immutable(LowExprKind) getAllocExpr2(
	ref GetLowExprCtx ctx,
	immutable FileAndRange range,
	ref immutable LowExpr inner,
	immutable LowType ptrType,
) {
	immutable LowLocal* local = addTempLocal(ctx, ptrType);
	immutable LowExpr sizeofT = genSizeOf(range, asPtrGcPointee(ptrType));
	immutable LowExpr allocatePtr = getAllocateExpr(ctx.alloc, ctx.allocFunIndex, range, ptrType, sizeofT);
	immutable LowExpr getTemp = genLocalGet(ctx.alloc, range, local);
	immutable LowExpr setTemp = genWriteToPtr(ctx.alloc, range, getTemp, inner);
	return immutable LowExprKind(allocate(ctx.alloc, immutable LowExprKind.Let(
		local,
		allocatePtr,
		genSeq(ctx.alloc, range, setTemp, getTemp))));
}

@trusted immutable(LowExprKind) getLoopExpr(
	ref GetLowExprCtx ctx,
	scope ref immutable Locals locals,
	immutable ExprPos exprPos,
	immutable LowType type,
	ref immutable ConcreteExprKind.Loop a,
) {
	LowExprKind.Loop* res = allocateMut(ctx.alloc, LowExprKind.Loop(type));
	immutable Locals newLocals = addLoop(locals, ptrTrustMe(a), cast(immutable) res);
	// Go ahead and give the body the same 'exprPos'. 'continue' will know it's non-tail.
	overwriteMemory(&res.body_, getLowExpr(ctx, newLocals, a.body_, exprPos));
	return immutable LowExprKind(cast(immutable) res);
}

//TODO: not @trusted
@trusted immutable(LowExprKind) getLoopBreakExpr(
	ref GetLowExprCtx ctx,
	scope ref immutable Locals locals,
	immutable ExprPos exprPos,
	ref immutable ConcreteExprKind.LoopBreak a,
) =>
	immutable LowExprKind(allocate(ctx.alloc, immutable LowExprKind.LoopBreak(
		getLoop(locals, a.loop),
		getLowExpr(ctx, locals, a.value, exprPos))));

@trusted immutable(LowExprKind) getLoopContinueExpr(
	ref GetLowExprCtx ctx,
	return scope ref immutable Locals locals,
	ref immutable ConcreteExprKind.LoopContinue a,
) =>
	immutable LowExprKind(immutable LowExprKind.LoopContinue(getLoop(locals, a.loop)));

immutable(LowExprKind) getCallExpr(
	ref GetLowExprCtx ctx,
	scope ref immutable Locals locals,
	immutable ExprPos exprPos,
	immutable FileAndRange range,
	immutable LowType type,
	ref immutable ConcreteExprKind.Call a,
) {
	immutable Opt!LowFunIndex opCalled = tryGetLowFunIndex(ctx, a.called);
	return has(opCalled)
		? getCallRegular(ctx, locals, exprPos, a, force(opCalled))
		: getCallSpecial(ctx, locals, exprPos, range, type, a);
}

immutable(LowExprKind) getCallRegular(
	ref GetLowExprCtx ctx,
	scope ref immutable Locals locals,
	immutable ExprPos exprPos,
	ref immutable ConcreteExprKind.Call a,
	immutable LowFunIndex called,
) {
	if (called == ctx.currentFun && exprPos == ExprPos.tail) {
		ctx.hasTailRecur = true;
		ArrBuilder!UpdateParam updateParams;
		foreach (immutable size_t argIndex, ref immutable ConcreteExpr it; a.args) {
			immutable LowExpr arg = getLowExpr(ctx, locals, it, ExprPos.nonTail);
			immutable LowParamIndex paramIndex = immutable LowParamIndex(argIndex);
			if (!(arg.kind.isA!(LowExprKind.ParamGet) && arg.kind.as!(LowExprKind.ParamGet).index == paramIndex))
				add(ctx.alloc, updateParams, immutable UpdateParam(paramIndex, arg));
		}
		return immutable LowExprKind(immutable LowExprKind.TailRecur(finishArr(ctx.alloc, updateParams)));
	} else
		return immutable LowExprKind(immutable LowExprKind.Call(
			called,
			map(ctx.alloc, a.args, (ref immutable ConcreteExpr it) =>
				getLowExpr(ctx, locals, it, ExprPos.nonTail))));
}

immutable(LowExprKind) getCallSpecial(
	ref GetLowExprCtx ctx,
	scope ref immutable Locals locals,
	immutable ExprPos exprPos,
	immutable FileAndRange range,
	immutable LowType type,
	ref immutable ConcreteExprKind.Call a,
) =>
	body_(*a.called).match!(immutable LowExprKind)(
		(immutable ConcreteFunBody.Builtin) =>
			getCallBuiltinExpr(ctx, locals, exprPos, range, type, a),
		(immutable Constant x) =>
			immutable LowExprKind(x),
		(immutable ConcreteFunBody.CreateRecord) {
			immutable LowExpr[] args = getArgs(ctx, locals, a.args);
			immutable LowExprKind create = immutable LowExprKind(immutable LowExprKind.CreateRecord(args));
			if (type.isA!(LowType.PtrGc)) {
				immutable LowExpr inner = immutable LowExpr(asPtrGcPointee(type), range, create);
				return getAllocExpr2(ctx, range, inner, type);
			} else
				return create;
		},
		(immutable ConcreteFunBody.CreateUnion x) {
			immutable LowExpr arg = empty(a.args)
				? genVoid(range)
				: getLowExpr(ctx, locals, only(a.args), ExprPos.nonTail);
			return immutable LowExprKind(allocate(ctx.alloc, immutable LowExprKind.CreateUnion(x.memberIndex, arg)));
		},
		(immutable EnumFunction x) =>
			genEnumFunction(ctx, locals, x, a.args),
		(immutable ConcreteFunBody.Extern) =>
			unreachable!(immutable LowExprKind),
		(immutable(ConcreteExpr)) =>
			unreachable!(immutable LowExprKind),
		(immutable ConcreteFunBody.FlagsFn x) {
			final switch (x.fn) {
				case FlagsFunction.all:
					return immutable LowExprKind(immutable Constant(immutable Constant.Integral(x.allValue)));
				case FlagsFunction.negate:
					return genFlagsNegate(
						ctx.alloc,
						range,
						x.allValue,
						getLowExpr(ctx, locals, only(a.args), ExprPos.nonTail));
				case FlagsFunction.new_:
					return immutable LowExprKind(immutable Constant(immutable Constant.Integral(0)));
			}
		},
		(immutable ConcreteFunBody.RecordFieldGet x) =>
			immutable LowExprKind(allocate(ctx.alloc, immutable LowExprKind.RecordFieldGet(
				getLowExpr(ctx, locals, only(a.args), ExprPos.nonTail),
				x.fieldIndex))),
		(immutable ConcreteFunBody.RecordFieldSet x) {
			verify(a.args.length == 2);
			return immutable LowExprKind(allocate(ctx.alloc, immutable LowExprKind.RecordFieldSet(
				getLowExpr(ctx, locals, a.args[0], ExprPos.nonTail),
				x.fieldIndex,
				getLowExpr(ctx, locals, a.args[1], ExprPos.nonTail))));
		},
		(immutable ConcreteFunBody.ThreadLocal) {
			immutable LowThreadLocalIndex index = mustGetAt(ctx.concreteFunToThreadLocalIndex, a.called);
			return immutable LowExprKind(immutable LowExprKind.ThreadLocalPtr(index));
		});

immutable(LowExprKind) genFlagsNegate(
	ref Alloc alloc,
	immutable FileAndRange range,
	immutable ulong allValue,
	immutable LowExpr a,
) =>
	genEnumIntersect(
		alloc,
		immutable LowExpr(a.type, range, genBitwiseNegate(alloc, a)),
		immutable LowExpr(a.type, range, immutable LowExprKind(
			immutable Constant(immutable Constant.Integral(allValue)))));

immutable(LowExprKind) genEnumFunction(
	ref GetLowExprCtx ctx,
	scope ref immutable Locals locals,
	immutable EnumFunction a,
	ref immutable ConcreteExpr[] args,
) {
	immutable(LowExpr) arg0() { return getLowExpr(ctx, locals, args[0], ExprPos.nonTail); }
	immutable(LowExpr) arg1() { return getLowExpr(ctx, locals, args[1], ExprPos.nonTail); }
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
			return unreachable!(immutable LowExprKind);
	}
}

immutable(LowExpr[]) getArgs(ref GetLowExprCtx ctx, scope ref immutable Locals locals, immutable ConcreteExpr[] args) =>
	map(ctx.alloc, args, (ref immutable ConcreteExpr arg) =>
		getLowExpr(ctx, locals, arg, ExprPos.nonTail));

immutable(LowExprKind) getCallBuiltinExpr(
	ref GetLowExprCtx ctx,
	scope ref immutable Locals locals,
	immutable ExprPos exprPos,
	immutable FileAndRange range,
	immutable LowType type,
	ref immutable ConcreteExprKind.Call a,
) {
	immutable Sym name = a.called.source.match!(immutable Sym)(
		(ref immutable FunInst it) =>
			decl(it).name,
		(ref immutable(ConcreteFunSource.Lambda)) =>
			unreachable!(immutable Sym)(),
		(ref immutable(ConcreteFunSource.Test)) =>
			unreachable!(immutable Sym)());
	immutable(LowType) paramType(immutable size_t index) =>
		index < a.args.length
			? lowTypeFromConcreteType(ctx.typeCtx, a.called.paramsExcludingClosure[index].type)
			: voidType;
	immutable LowType p0 = paramType(0);
	immutable LowType p1 = paramType(1);
	immutable BuiltinKind builtinKind = getBuiltinKind(ctx.alloc, ctx.allSymbols, name, type, p0, p1);
	immutable(LowExpr) getArg(ref immutable ConcreteExpr arg, immutable ExprPos argPos) =>
		getLowExpr(ctx, locals, arg, argPos);
	return builtinKind.match!(immutable LowExprKind)(
		(immutable BuiltinKind.CallFunPointer) =>
			immutable LowExprKind(allocate(ctx.alloc, immutable LowExprKind.CallFunPtr(
				getLowExpr(ctx, locals, a.args[0], ExprPos.nonTail),
				getArgs(ctx, locals, a.args[1 .. $])))),
		(immutable Constant it) =>
			immutable LowExprKind(it),
		(immutable BuiltinKind.InitConstants) =>
			immutable LowExprKind(immutable LowExprKind.InitConstants()),
		(immutable LowExprKind.SpecialUnary.Kind kind) {
			verify(a.args.length == 1);
			return immutable LowExprKind(
				allocate(ctx.alloc, immutable LowExprKind.SpecialUnary(kind, getArg(a.args[0], ExprPos.nonTail))));
		},
		(immutable LowExprKind.SpecialBinary.Kind kind) {
			verify(a.args.length == 2);
			immutable ExprPos arg1Pos = () {
				switch (kind) {
					case LowExprKind.SpecialBinary.Kind.and:
					case LowExprKind.SpecialBinary.Kind.orBool:
						return exprPos;
					default:
						return ExprPos.nonTail;
				}
			}();
			return immutable LowExprKind(allocate(ctx.alloc, immutable LowExprKind.SpecialBinary(
				kind,
				getArg(a.args[0], ExprPos.nonTail),
				getArg(a.args[1], arg1Pos))));
		},
		(immutable LowExprKind.SpecialTernary.Kind kind) {
			verify(a.args.length == 3);
			return immutable LowExprKind(allocate(ctx.alloc, immutable LowExprKind.SpecialTernary(kind, [
				getArg(a.args[0], ExprPos.nonTail),
				getArg(a.args[1], ExprPos.nonTail),
				getArg(a.args[2], ExprPos.nonTail)])));
		},
		(immutable BuiltinKind.OptOr) {
			verify(a.args.length == 2);
			verify(p0 == p1);
			immutable LowLocal* lhsLocal = addTempLocal(ctx, p0);
			immutable LowExpr lhsRef = genLocalGet(ctx.alloc, range, lhsLocal);
			return immutable LowExprKind(allocate(ctx.alloc, immutable LowExprKind.Let(
				lhsLocal,
				getArg(a.args[0], ExprPos.nonTail),
				immutable LowExpr(p0, range, immutable LowExprKind(allocate(ctx.alloc, immutable LowExprKind.MatchUnion(
					lhsRef,
					arrLiteral!(LowExprKind.MatchUnion.Case)(ctx.alloc, [
						immutable LowExprKind.MatchUnion.Case(none!(LowLocal*), getArg(a.args[1], ExprPos.tail)),
						immutable LowExprKind.MatchUnion.Case(none!(LowLocal*), lhsRef)]))))))));
		},
		(immutable BuiltinKind.OptQuestion2) {
			verify(a.args.length == 2);
			immutable LowLocal* valueLocal = addTempLocal(ctx, p1);
			return immutable LowExprKind(allocate(ctx.alloc, immutable LowExprKind.MatchUnion(
				getArg(a.args[0], ExprPos.nonTail),
				arrLiteral!(LowExprKind.MatchUnion.Case)(ctx.alloc, [
					immutable LowExprKind.MatchUnion.Case(none!(LowLocal*), getArg(a.args[1], ExprPos.tail)),
					immutable LowExprKind.MatchUnion.Case(
						some(valueLocal),
						genLocalGet(ctx.alloc, range, valueLocal))]))));
		},
		(immutable BuiltinKind.PointerCast) {
			verify(a.args.length == 1);
			return genPtrCastKind(ctx.alloc, getLowExpr(ctx, locals, only(a.args), ExprPos.nonTail));
		},
		(immutable BuiltinKind.SizeOf) {
			immutable LowType typeArg =
				lowTypeFromConcreteType(ctx.typeCtx, only(body_(*a.called).as!(ConcreteFunBody.Builtin).typeArgs));
			return immutable LowExprKind(immutable LowExprKind.SizeOf(typeArg));
		},
		(immutable BuiltinKind.StaticSymbols) =>
			immutable LowExprKind(ctx.staticSymbols));
}

immutable(LowExprKind) getCreateArrExpr(
	ref GetLowExprCtx ctx,
	scope ref immutable Locals locals,
	immutable FileAndRange range,
	ref immutable ConcreteExprKind.CreateArr a,
) {
	// (temp = _alloc(ctx, sizeof(foo) * 2),
	// *(temp + 0) = a,
	// *(temp + 1) = b,
	// arr_foo{2, temp})
	immutable LowType arrType = lowTypeFromConcreteStruct(ctx.typeCtx, a.arrType);
	immutable LowType elementType = lowTypeFromConcreteType(ctx.typeCtx, elementType(a));
	immutable LowType elementPtrType = getLowRawPtrConstType(ctx.typeCtx, elementType);
	immutable LowExpr elementSize = genSizeOf(range, elementType);
	immutable LowExpr nElements = genConstantNat64(range, a.args.length);
	immutable LowExpr sizeBytes = genWrapMulNat64(ctx.alloc, range, elementSize, nElements);
	immutable LowExpr allocatePtr = getAllocateExpr(ctx.alloc, ctx.allocFunIndex, range, elementPtrType, sizeBytes);
	immutable LowLocal* temp = addTempLocal(ctx, elementPtrType);
	immutable LowExpr getTemp = genLocalGet(ctx.alloc, range, temp);
	immutable(LowExpr) recur(immutable LowExpr cur, immutable size_t prevIndex) {
		if (prevIndex == 0)
			return cur;
		else {
			immutable size_t index = prevIndex - 1;
			immutable LowExpr arg = getLowExpr(ctx, locals, a.args[index], ExprPos.nonTail);
			immutable LowExpr elementPtr = genAddPtr(
				ctx.alloc,
				elementPtrType.as!(LowType.PtrRawConst),
				range,
				getTemp,
				genConstantNat64(range, index));
			immutable LowExpr writeToElement = genWriteToPtr(ctx.alloc, range, elementPtr, arg);
			return recur(genSeq(ctx.alloc, range, writeToElement, cur), index);
		}
	}
	immutable LowExpr createArr = immutable LowExpr(
		arrType,
		range,
		immutable LowExprKind(immutable LowExprKind.CreateRecord(
			arrLiteral!LowExpr(ctx.alloc, [nElements, genLocalGet(ctx.alloc, range, temp)]))));
	immutable LowExpr writeAndGetArr = recur(createArr, a.args.length);
	return immutable LowExprKind(allocate(ctx.alloc, immutable LowExprKind.Let(
		temp,
		allocatePtr,
		writeAndGetArr)));
}

immutable(LowExprKind) getDropExpr(
	ref GetLowExprCtx ctx,
	scope ref immutable Locals locals,
	immutable FileAndRange range,
	ref immutable ConcreteExprKind.Drop a,
) {
	immutable LowExpr arg = getLowExpr(ctx, locals, a.arg, ExprPos.nonTail);
	return genDrop(ctx.alloc, range, arg, getTempLocalIndex(ctx)).kind;
}

immutable(LowExprKind) getLambdaExpr(
	ref GetLowExprCtx ctx,
	scope ref immutable Locals locals,
	immutable FileAndRange range,
	ref immutable ConcreteExprKind.Lambda a,
) =>
	immutable LowExprKind(allocate(ctx.alloc, immutable LowExprKind.CreateUnion(
		a.memberIndex,
		has(a.closure)
			? getLowExpr(ctx, locals, *force(a.closure), ExprPos.nonTail)
			: genVoid(range))));

immutable(LowExprKind) getLetExpr(
	ref GetLowExprCtx ctx,
	scope ref immutable Locals locals,
	immutable ExprPos exprPos,
	immutable FileAndRange range,
	ref immutable ConcreteExprKind.Let a,
) {
	immutable LowExpr valueByVal = getLowExpr(ctx, locals, a.value, ExprPos.nonTail);
	immutable LowExpr value = a.local.isAllocated
		? getAllocExpr2Expr(ctx, range, valueByVal, getLowGcPtrType(ctx.typeCtx, valueByVal.type))
		: valueByVal;
	return withLowLocal(
		ctx, locals, a.local,
		(scope ref immutable Locals innerLocals, immutable LowLocal* local) =>
			immutable LowExprKind(allocate(ctx.alloc, immutable LowExprKind.Let(
				local, value, getLowExpr(ctx, innerLocals, a.then, exprPos)))));
}

immutable(LowExprKind) getLocalGetExpr(
	ref GetLowExprCtx ctx,
	scope ref immutable Locals locals,
	immutable LowType type,
	immutable FileAndRange range,
	ref immutable ConcreteExprKind.LocalGet a,
) {
	immutable LowLocal* local = getLocal(locals, a.local);
	immutable LowExprKind localGet = immutable LowExprKind(immutable LowExprKind.LocalGet(local));
	return a.local.isAllocated
		? genDerefGcPtr(ctx.alloc, immutable LowExpr(local.type, range, localGet))
		: localGet;
}

// TODO: not @trusted
@trusted immutable(LowExprKind) getPtrToLocalExpr(
	ref GetLowExprCtx ctx,
	scope ref immutable Locals locals,
	immutable FileAndRange range,
	ref immutable ConcreteExprKind.PtrToLocal a,
) {
	immutable LowLocal* local = getLocal(locals, a.local);
	return a.local.isAllocated
		? immutable LowExprKind(allocate(ctx.alloc, immutable LowExprKind.PtrCast(
			immutable LowExpr(local.type, range, immutable LowExprKind(LowExprKind.LocalGet(local))))))
		: immutable LowExprKind(immutable LowExprKind.PtrToLocal(local));
}

// TODO: not @trusted
@trusted immutable(LowExprKind) getLocalSetExpr(
	ref GetLowExprCtx ctx,
	scope ref immutable Locals locals,
	immutable FileAndRange range,
	ref immutable ConcreteExprKind.LocalSet a,
) {
	immutable LowLocal* local = getLocal(locals, a.local);
	immutable LowExpr value = getLowExpr(ctx, locals, a.value, ExprPos.nonTail);
	return a.local.isAllocated
		? genWriteToPtr(
			ctx.alloc,
			immutable LowExpr(local.type, range, immutable LowExprKind(immutable LowExprKind.LocalGet(local))),
			value)
		: immutable LowExprKind(allocate(ctx.alloc, immutable LowExprKind.LocalSet(local, value)));
}

immutable(LowExprKind) getMatchEnumExpr(
	ref GetLowExprCtx ctx,
	scope ref immutable Locals locals,
	immutable ExprPos exprPos,
	ref immutable ConcreteExprKind.MatchEnum a,
) {
	immutable ConcreteStructBody.Enum enum_ = body_(*mustBeByVal(a.matchedValue.type)).as!(ConcreteStructBody.Enum);
	immutable LowExpr matchedValue = getLowExpr(ctx, locals, a.matchedValue, ExprPos.nonTail);
	immutable LowExpr[] cases = map(ctx.alloc, a.cases, (ref immutable ConcreteExpr case_) =>
		getLowExpr(ctx, locals, case_, exprPos));
	return enum_.values.match!(immutable LowExprKind)(
		(immutable(size_t)) =>
			immutable LowExprKind(allocate(ctx.alloc, immutable LowExprKind.Switch0ToN(matchedValue, cases))),
		(immutable EnumValue[] values) =>
			immutable LowExprKind(
				allocate(ctx.alloc, immutable LowExprKind.SwitchWithValues(matchedValue, values, cases))));
}

immutable(LowExprKind) getMatchUnionExpr(
	ref GetLowExprCtx ctx,
	scope ref immutable Locals locals,
	immutable ExprPos exprPos,
	ref immutable ConcreteExprKind.MatchUnion a,
) {
	immutable LowExpr matched = getLowExpr(ctx, locals, a.matchedValue, ExprPos.nonTail);
	return immutable LowExprKind(allocate(ctx.alloc, immutable LowExprKind.MatchUnion(
		matched,
		map(ctx.alloc, a.cases, (ref immutable ConcreteExprKind.MatchUnion.Case case_) =>
			withOptLowLocal(
				ctx, locals, case_.local,
				(scope ref immutable Locals caseLocals, immutable Opt!(LowLocal*) local) =>
					immutable LowExprKind.MatchUnion.Case(
						local,
						getLowExpr(ctx, caseLocals, case_.then, exprPos)))))));
}

immutable(LowExprKind) getParamGetExpr(ref GetLowExprCtx ctx, immutable ConcreteParam* param) {
	// We won't get a closure param here, that is done in ClosureGet or ClosureSet
	return immutable LowExprKind(immutable LowExprKind.ParamGet(immutable LowParamIndex(
		(ctx.hasClosure ? 1 : 0) + force(param.index))));
}

immutable(LowExprKind) getPtrToParam(ref GetLowExprCtx ctx, ref immutable ConcreteExprKind.PtrToParam a) =>
	immutable LowExprKind(immutable LowExprKind.PtrToParam(immutable LowParamIndex(
		(ctx.hasClosure ? 1 : 0) + force(a.param.index))));

immutable(LowExprKind) getClosureCreateExpr(
	ref GetLowExprCtx ctx,
	scope ref immutable Locals locals,
	immutable FileAndRange range,
	immutable LowType type,
	immutable ConcreteExprKind.ClosureCreate a,
) {
	immutable LowRecord record = ctx.allTypes.allRecords[type.as!(LowType.Record)];
	return immutable LowExprKind(immutable LowExprKind.CreateRecord(
		mapZip!(immutable LowExpr, immutable ConcreteVariableRef, LowField)(
			ctx.alloc, a.args, record.fields,
			(ref immutable ConcreteVariableRef x, ref immutable LowField f) =>
				getVariableRefExprForClosure(ctx, locals, range, f.type, x))));
}

immutable(LowExpr) getVariableRefExprForClosure(
	ref GetLowExprCtx ctx,
	scope ref immutable Locals locals,
	immutable FileAndRange range,
	immutable LowType type,
	immutable ConcreteVariableRef a,
) =>
	a.matchWithPointers!(immutable LowExpr)(
		(immutable Constant x) =>
			immutable LowExpr(type, range, immutable LowExprKind(x)),
		(immutable ConcreteLocal* x) =>
			// Intentionally not dereferencing the local like 'getLocalGetExpr' does
			immutable LowExpr(type, range, immutable LowExprKind(immutable LowExprKind.LocalGet(getLocal(locals, x)))),
		(immutable ConcreteParam* x) =>
			immutable LowExpr(type, range, getParamGetExpr(ctx, x)),
		(immutable ConcreteClosureRef x) =>
			getClosureField(ctx, range, x));

immutable(LowExprKind) getClosureGetExpr(
	ref GetLowExprCtx ctx,
	immutable FileAndRange range,
	immutable ConcreteExprKind.ClosureGet a,
) {
	immutable LowExpr getField = getClosureField(ctx, range, a.closureRef);
	final switch (a.referenceKind) {
		case ClosureReferenceKind.direct:
			return getField.kind;
		case ClosureReferenceKind.allocated:
			return genDerefGcPtr(ctx.alloc, getField);
	}
}

immutable(LowExprKind) getClosureSetExpr(
	ref GetLowExprCtx ctx,
	scope ref immutable Locals locals,
	immutable FileAndRange range,
	ref immutable ConcreteExprKind.ClosureSet a,
) {
	// Note: This doesn't write to a field, it gets a pointer from the field and writes to that
	immutable LowExpr pointer = getClosureField(ctx, range, a.closureRef);
	immutable LowExpr value = getLowExpr(ctx, locals, a.value, ExprPos.nonTail);
	return genWriteToPtr(ctx.alloc, pointer, value);
}

// NOTE: This does not dereference pointer for mutAllocated, getClosureGetExpr will do that
immutable(LowExpr) getClosureField(
	ref GetLowExprCtx ctx,
	immutable FileAndRange range,
	immutable ConcreteClosureRef closureRef,
) {
	immutable LowType closureParamType = force(ctx.closureParamType);
	immutable LowExpr closureParamGet = immutable LowExpr(
		closureParamType,
		range,
		immutable LowExprKind(immutable LowExprKind.ParamGet(immutable LowParamIndex(0))));
	immutable LowRecord record = ctx.allTypes.allRecords[asPtrGcPointee(closureParamType).as!(LowType.Record)];
	return immutable LowExpr(
		record.fields[closureRef.fieldIndex].type,
		range,
		immutable LowExprKind(allocate(
			ctx.alloc,
			immutable LowExprKind.RecordFieldGet(closureParamGet, closureRef.fieldIndex))));
}

immutable(LowExprKind) getPtrToFieldExpr(
	ref GetLowExprCtx ctx,
	scope ref immutable Locals locals,
	ref immutable ConcreteExprKind.PtrToField a,
) =>
	immutable LowExprKind(allocate(ctx.alloc, immutable LowExprKind.PtrToField(
		getLowExpr(ctx, locals, a.target, ExprPos.nonTail),
		a.fieldIndex)));

immutable(LowExprKind) getThrowExpr(
	ref GetLowExprCtx ctx,
	scope ref immutable Locals locals,
	immutable FileAndRange range,
	immutable LowType type,
	ref immutable ConcreteExprKind.Throw a,
) {
	immutable LowExprKind callThrow = immutable LowExprKind(immutable LowExprKind.Call(
		ctx.throwImplFunIndex,
		arrLiteral!LowExpr(ctx.alloc, [getLowExpr(ctx, locals, a.thrown, ExprPos.nonTail)])));
	return type == voidType
		? callThrow
		: immutable LowExprKind(allocate(ctx.alloc, immutable LowExprKind.Seq(
			immutable LowExpr(voidType, range, callThrow),
			immutable LowExpr(type, range, immutable LowExprKind(constantZero)))));
}
