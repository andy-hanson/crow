module lower.lower;

@safe @nogc pure nothrow:

import lower.checkLowModel : checkLowProgram;
import lower.generateCallWithCtxFun : generateCallWithCtxFun;
import lower.generateMarkVisitFun :
	generateMarkVisitArrInner,
	generateMarkVisitArrOuter,
	generateMarkVisitNonArr,
	generateMarkVisitGcPtr;
import lower.getBuiltinCall : BuiltinKind, getBuiltinKind, matchBuiltinKind;
import lower.lowExprHelpers :
	anyPtrMutType,
	char8PtrPtrConstType,
	genAddPtr,
	genBitwiseNegate,
	genConstantNat64,
	genDrop,
	genEnumEq,
	genEnumIntersect,
	genEnumToIntegral,
	genEnumUnion,
	genLocal,
	genLocalRef,
	genParamRef,
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
	asBuiltin,
	asEnum,
	asRecord,
	body_,
	BuiltinStructKind,
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
	elementType,
	fieldOffsets,
	isCallWithCtxFun,
	isClosure,
	isMarkVisitFun,
	matchConcreteExprKind,
	matchConcreteFunBody,
	matchConcreteFunSource,
	matchConcreteStructBody,
	matchEnum,
	mustBeByVal,
	NeedsCtx,
	PointerTypeAndConstantsConcrete,
	ReferenceKind;
import model.constant : Constant;
import model.lowModel :
	AllConstantsLow,
	AllLowTypes,
	ArrTypeAndConstantsLow,
	asPtrGcPointee,
	asParamRef,
	asPtrRawConst,
	asRecordType,
	ConcreteFunToLowFunIndex,
	hashLowType,
	isArr,
	isParamRef,
	isPtrGc,
	LowExpr,
	LowExprKind,
	LowExternPtrType,
	LowField,
	LowFun,
	LowFunBody,
	LowFunExprBody,
	LowFunIndex,
	LowFunParamsKind,
	LowFunPtrType,
	LowFunSource,
	LowLocal,
	LowLocalSource,
	LowParam,
	LowParamIndex,
	LowParamSource,
	LowProgram,
	LowRecord,
	LowType,
	lowTypeEqual,
	LowUnion,
	matchLowType,
	PointerTypeAndConstantsLow,
	PrimitiveType,
	UpdateParam;
import model.model : decl, EnumBackingType, EnumFunction, EnumValue, FlagsFunction, FunInst, name, range;
import util.alloc.alloc : Alloc;
import util.col.arr : empty, emptyArr, only;
import util.col.arrBuilder : add, ArrBuilder, arrBuilderSize, finishArr;
import util.col.arrUtil :
	arrLiteral,
	exists,
	map,
	mapZipPtrFirst,
	mapWithIndexAndConcatOne,
	mapWithOptFirst,
	mapWithOptFirst2;
import util.col.dict : mustGetAt, PtrDict;
import util.col.dictBuilder : finishDict, mustAddToDict, PtrDictBuilder;
import util.col.fullIndexDict : FullIndexDict, fullIndexDictOfArr, fullIndexDictSize;
import util.col.mutIndexDict : getOrAddAndDidAdd, mustGetAt, MutIndexDict, newMutIndexDict;
import util.col.mutDict : getAt_mut, getOrAdd, MutDict, MutPtrDict, ValueAndDidAdd;
import util.col.stackDict : StackDict, stackDictAdd, stackDictMustGet;
import util.late : Late, late, lateGet, lateIsSet, lateSet;
import util.memory : allocate;
import util.opt : asImmutable, force, has, mapOption, none, Opt, some;
import util.perf : Perf, PerfMeasure, withMeasure;
import util.ptr : nullPtr, Ptr, ptrEquals, ptrTrustMe, ptrTrustMe_mut;
import util.sourceRange : FileAndRange;
import util.sym : shortSym, Sym;
import util.util : unreachable, verify;

immutable(LowProgram) lower(ref Alloc alloc, scope ref Perf perf, ref immutable ConcreteProgram a) {
	return withMeasure!(immutable LowProgram, () =>
		lowerInner(alloc, a)
	)(alloc, perf, PerfMeasure.lower);
}

private immutable(LowProgram) lowerInner(ref Alloc alloc, ref immutable ConcreteProgram a) {
	AllLowTypesWithCtx allTypes = getAllLowTypes(alloc, a);
	immutable AllLowFuns allFuns = getAllLowFuns(allTypes.allTypes, allTypes.getLowTypeCtx, a);
	immutable AllConstantsLow allConstants = convertAllConstants(allTypes.getLowTypeCtx, a.allConstants);
	immutable LowProgram res = immutable LowProgram(
		allFuns.concreteFunToLowFunIndex,
		allConstants,
		allTypes.allTypes,
		allFuns.allLowFuns,
		allFuns.main,
		a.allExternLibraryNames);
	checkLowProgram(alloc, res);
	return res;
}

struct MarkVisitFuns {
	MutIndexDict!(immutable LowType.Record, immutable LowFunIndex) recordValToVisit;
	MutIndexDict!(immutable LowType.Union, immutable LowFunIndex) unionToVisit;
	MutDict!(immutable LowType, immutable LowFunIndex, lowTypeEqual, hashLowType) gcPointeeToVisit;
}

immutable(LowFunIndex) getMarkVisitFun(ref const MarkVisitFuns funs, immutable LowType type) {
	immutable Opt!LowFunIndex opt = tryGetMarkVisitFun(funs, type);
	return force(opt);
}

immutable(Opt!LowFunIndex) tryGetMarkVisitFun(ref const MarkVisitFuns funs, immutable LowType type) {
	return matchLowType!(
		immutable Opt!LowFunIndex,
		(immutable LowType.ExternPtr) =>
			none!LowFunIndex,
		(immutable LowType.FunPtr) =>
			none!LowFunIndex,
		(immutable PrimitiveType it) =>
			none!LowFunIndex,
		(immutable LowType.PtrGc it) =>
			asImmutable(getAt_mut(funs.gcPointeeToVisit, it.pointee.deref())),
		(immutable LowType.PtrRawConst) =>
			none!LowFunIndex,
		(immutable LowType.PtrRawMut) =>
			none!LowFunIndex,
		(immutable LowType.Record it) =>
			asImmutable(funs.recordValToVisit[it]),
		(immutable LowType.Union it) =>
			asImmutable(funs.unionToVisit[it]),
	)(type);
}

private:

immutable(AllConstantsLow) convertAllConstants(
	ref GetLowTypeCtx ctx,
	ref immutable AllConstantsConcrete a,
) {
	immutable ArrTypeAndConstantsLow[] arrs =
		map!ArrTypeAndConstantsLow(ctx.alloc, a.arrs, (ref immutable ArrTypeAndConstantsConcrete it) {
			immutable LowType arrType = lowTypeFromConcreteStruct(ctx, it.arrType);
			immutable LowType elementType = lowTypeFromConcreteType(ctx, it.elementType);
			return immutable ArrTypeAndConstantsLow(asRecordType(arrType), elementType, it.constants);
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
}

struct GetLowTypeCtx {
	@safe @nogc pure nothrow:

	Ptr!Alloc allocPtr;
	immutable PtrDict!(ConcreteStruct, LowType) concreteStructToType;
	MutPtrDict!(ConcreteStruct, immutable LowType) concreteStructToPtrType;

	ref Alloc alloc() return scope {
		return allocPtr.deref();
	}
}

AllLowTypesWithCtx getAllLowTypes(
	ref Alloc alloc,
	ref immutable ConcreteProgram program,
) {
	PtrDictBuilder!(ConcreteStruct, LowType) concreteStructToTypeBuilder;
	ArrBuilder!(Ptr!ConcreteStruct) allFunPtrSources;
	ArrBuilder!LowExternPtrType allExternPtrTypes;
	ArrBuilder!(Ptr!ConcreteStruct) allRecordSources;
	ArrBuilder!(Ptr!ConcreteStruct) allUnionSources;

	immutable(LowType) addUnion(immutable Ptr!ConcreteStruct s) {
		immutable size_t i = arrBuilderSize(allUnionSources);
		add(alloc, allUnionSources, s);
		return immutable LowType(immutable LowType.Union(i));
	}

	foreach (immutable Ptr!ConcreteStruct s; program.allStructs) {
		immutable Opt!LowType lowType = matchConcreteStructBody!(immutable Opt!LowType)(
			body_(s.deref()),
			(ref immutable ConcreteStructBody.Builtin it) {
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
						return some(addUnion(s));
					case BuiltinStructKind.funPtrN: {
						immutable size_t i = arrBuilderSize(allFunPtrSources);
						add(alloc, allFunPtrSources, s);
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
					case BuiltinStructKind.ptrConst:
					case BuiltinStructKind.ptrMut:
						return none!LowType;
					case BuiltinStructKind.void_:
						return some(immutable LowType(PrimitiveType.void_));
				}
			},
			(ref immutable ConcreteStructBody.Enum it) =>
				some(immutable LowType(typeForEnum(it.backingType))),
			(ref immutable ConcreteStructBody.Flags it) =>
				some(immutable LowType(typeForEnum(it.backingType))),
			(ref immutable ConcreteStructBody.ExternPtr it) {
				immutable size_t i = arrBuilderSize(allExternPtrTypes);
				add(alloc, allExternPtrTypes, immutable LowExternPtrType(s));
				return some(immutable LowType(immutable LowType.ExternPtr(i)));
			},
			(ref immutable ConcreteStructBody.Record it) {
				immutable size_t i = arrBuilderSize(allRecordSources);
				add(alloc, allRecordSources, s);
				return some(immutable LowType(immutable LowType.Record(i)));
			},
			(ref immutable ConcreteStructBody.Union it) =>
				some(addUnion(s)));
		if (has(lowType))
			mustAddToDict(alloc, concreteStructToTypeBuilder, s, force(lowType));
	}

	GetLowTypeCtx getLowTypeCtx = GetLowTypeCtx(ptrTrustMe_mut(alloc), finishDict(alloc, concreteStructToTypeBuilder));

	immutable FullIndexDict!(LowType.FunPtr, LowFunPtrType) allFunPtrs =
		fullIndexDictOfArr!(LowType.FunPtr, LowFunPtrType)(
			map(alloc, finishArr(alloc, allFunPtrSources), (ref immutable Ptr!ConcreteStruct it) {
				immutable ConcreteType[] typeArgs = asBuiltin(it.deref().body_).typeArgs;
				immutable LowType returnType = lowTypeFromConcreteType(getLowTypeCtx, typeArgs[0]);
				immutable LowType[] paramTypes =
					map(alloc, typeArgs[1 .. $], (ref immutable ConcreteType typeArg) =>
						lowTypeFromConcreteType(getLowTypeCtx, typeArg));
				return immutable LowFunPtrType(it, returnType, paramTypes);
			}));
	immutable FullIndexDict!(LowType.Record, LowRecord) allRecords =
		fullIndexDictOfArr!(LowType.Record, LowRecord)(
			map(alloc, finishArr(alloc, allRecordSources), (ref immutable Ptr!ConcreteStruct it) =>
				immutable LowRecord(
					it,
					mapZipPtrFirst!(LowField, ConcreteField, size_t)(
						alloc,
						asRecord(body_(it.deref())).fields,
						fieldOffsets(it.deref()),
						(immutable Ptr!ConcreteField field, ref immutable size_t fieldOffset) =>
							immutable LowField(
								field,
								fieldOffset,
								lowTypeFromConcreteType(getLowTypeCtx, field.deref().type))))));
	immutable FullIndexDict!(LowType.Union, LowUnion) allUnions =
		fullIndexDictOfArr!(LowType.Union, LowUnion)(
			map(alloc, finishArr(alloc, allUnionSources), (ref immutable Ptr!ConcreteStruct it) =>
				getLowUnion(program, getLowTypeCtx, it)));

	return AllLowTypesWithCtx(
		immutable AllLowTypes(
			fullIndexDictOfArr!(LowType.ExternPtr, LowExternPtrType)(finishArr(alloc, allExternPtrTypes)),
			allFunPtrs,
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
	immutable Ptr!ConcreteStruct s,
) {
	immutable LowType[] members = matchConcreteStructBody!(immutable LowType[])(
		body_(s.deref()),
		(ref immutable ConcreteStructBody.Builtin it) {
			verify(it.kind == BuiltinStructKind.fun);
			return map(
				getLowTypeCtx.alloc,
				mustGetAt(program.funStructToImpls, s),
				(ref immutable ConcreteLambdaImpl impl) =>
					lowTypeFromConcreteType(getLowTypeCtx, impl.closureType));
		},
		(ref immutable(ConcreteStructBody.Enum)) => unreachable!(immutable LowType[])(),
		(ref immutable(ConcreteStructBody.Flags)) => unreachable!(immutable LowType[])(),
		(ref immutable(ConcreteStructBody.ExternPtr)) => unreachable!(immutable LowType[])(),
		(ref immutable(ConcreteStructBody.Record)) => unreachable!(immutable LowType[])(),
		(ref immutable ConcreteStructBody.Union it) =>
			map(getLowTypeCtx.alloc, it.members, (ref immutable Opt!ConcreteType member) =>
				has(member)
					? lowTypeFromConcreteType(getLowTypeCtx, force(member))
					: immutable LowType(PrimitiveType.void_)));
	return immutable LowUnion(s, members);
}

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

immutable(LowType) lowTypeFromConcreteStruct(ref GetLowTypeCtx ctx, immutable Ptr!ConcreteStruct it) {
	immutable Opt!LowType res = ctx.concreteStructToType[it];
	if (has(res))
		return force(res);
	else {
		immutable ConcreteStructBody.Builtin builtin = asBuiltin(body_(it.deref()));
		verify(builtin.kind == BuiltinStructKind.ptrConst || builtin.kind == BuiltinStructKind.ptrMut);
		//TODO: cache the creation.. don't want an allocation for every BuiltinStructKind.ptr to the same target type
		immutable Ptr!LowType inner = allocate(ctx.alloc, lowTypeFromConcreteType(ctx, only(builtin.typeArgs)));
		switch (builtin.kind) {
			case BuiltinStructKind.ptrConst:
				return immutable LowType(immutable LowType.PtrRawConst(inner));
			case BuiltinStructKind.ptrMut:
				return immutable LowType(immutable LowType.PtrRawMut(inner));
			default:
				return unreachable!(immutable LowType);
		}
	}
}

immutable(LowType) lowTypeFromConcreteType(ref GetLowTypeCtx ctx, immutable ConcreteType it) {
	final switch (it.reference) {
		case ReferenceKind.byRef:
			return getOrAdd(ctx.alloc, ctx.concreteStructToPtrType, it.struct_, () =>
				immutable LowType(immutable LowType.PtrGc(
					allocate(ctx.alloc, lowTypeFromConcreteStruct(ctx, it.struct_)))));
		case ReferenceKind.byVal:
			return lowTypeFromConcreteStruct(ctx, it.struct_);
	}
}

struct LowFunCause {
	@safe @nogc pure nothrow:
	struct CallWithCtx {
		immutable LowType funType;
		immutable LowType returnType;
		immutable LowType[] nonFunNonCtxParamTypes;
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

	@trusted immutable this(immutable CallWithCtx a) { kind = Kind.callWithCtx; callWithCtx_ = a; }
	@trusted immutable this(immutable Ptr!ConcreteFun a) { kind = Kind.concreteFun; concreteFun_ = a; }
	@trusted immutable this(immutable MarkVisitArrInner a) { kind = Kind.markVisitArrInner; markVisitArrInner_ = a; }
	@trusted immutable this(immutable MarkVisitArrOuter a) { kind = Kind.markVisitArrOuter; markVisitArrOuter_ = a; }
	@trusted immutable this(immutable MarkVisitNonArr a) { kind = Kind.markVisitNonArr; markVisitNonArr_ = a; }
	@trusted immutable this(immutable MarkVisitGcPtr a) { kind = Kind.markVisitGcPtr; markVisitGcPtr_ = a; }

	private:
	enum Kind {
		callWithCtx,
		concreteFun,
		markVisitArrInner,
		markVisitArrOuter,
		markVisitNonArr,
		markVisitGcPtr,
	}
	immutable Kind kind;
	union {
		immutable CallWithCtx callWithCtx_;
		immutable Ptr!ConcreteFun concreteFun_;
		immutable MarkVisitArrOuter markVisitArrOuter_;
		immutable MarkVisitArrInner markVisitArrInner_;
		immutable MarkVisitNonArr markVisitNonArr_;
		immutable MarkVisitGcPtr markVisitGcPtr_;
	}
}

immutable(bool) isConcreteFun(ref immutable LowFunCause a) {
	return a.kind == LowFunCause.Kind.concreteFun;
}

@trusted immutable(Ptr!ConcreteFun) asConcreteFun(ref immutable LowFunCause a) {
	verify(isConcreteFun(a));
	return a.concreteFun_;
}

@trusted T matchLowFunCause(T)(
	ref immutable LowFunCause a,
	scope T delegate(ref immutable LowFunCause.CallWithCtx) @safe @nogc pure nothrow cbCallWithCtx,
	scope T delegate(immutable Ptr!ConcreteFun) @safe @nogc pure nothrow cbConcreteFun,
	scope T delegate(ref immutable LowFunCause.MarkVisitArrInner) @safe @nogc pure nothrow cbMarkVisitArrInner,
	scope T delegate(ref immutable LowFunCause.MarkVisitArrOuter) @safe @nogc pure nothrow cbMarkVisitArrOuter,
	scope T delegate(ref immutable LowFunCause.MarkVisitNonArr) @safe @nogc pure nothrow cbMarkVisitNonArr,
	scope T delegate(ref immutable LowFunCause.MarkVisitGcPtr) @safe @nogc pure nothrow cbMarkVisitGcPtr,
) {
	final switch (a.kind) {
		case LowFunCause.Kind.callWithCtx:
			return cbCallWithCtx(a.callWithCtx_);
		case LowFunCause.Kind.concreteFun:
			return cbConcreteFun(a.concreteFun_);
		case LowFunCause.Kind.markVisitArrInner:
			return cbMarkVisitArrInner(a.markVisitArrInner_);
		case LowFunCause.Kind.markVisitArrOuter:
			return cbMarkVisitArrOuter(a.markVisitArrOuter_);
		case LowFunCause.Kind.markVisitNonArr:
			return cbMarkVisitNonArr(a.markVisitNonArr_);
		case LowFunCause.Kind.markVisitGcPtr:
			return cbMarkVisitGcPtr(a.markVisitGcPtr_);
	}
}

immutable(bool) needsMarkVisitFun(ref immutable AllLowTypes allTypes, immutable LowType a) {
	return matchLowType!(
		immutable bool,
		(immutable LowType.ExternPtr) =>
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
			return isArr(record) || exists!LowField(record.fields, (ref immutable LowField field) =>
				needsMarkVisitFun(allTypes, field.type));
		},
		(immutable LowType.Union it) =>
			exists!LowType(allTypes.allUnions[it].members, (ref immutable LowType member) =>
				needsMarkVisitFun(allTypes, member)),
	)(a);
}

immutable(AllLowFuns) getAllLowFuns(
	ref immutable AllLowTypes allTypes,
	ref GetLowTypeCtx getLowTypeCtx,
	ref immutable ConcreteProgram program,
) {
	immutable LowType ctxType =
		lowTypeFromConcreteType(getLowTypeCtx, immutable ConcreteType(ReferenceKind.byRef, program.ctxType));
	PtrDictBuilder!(ConcreteFun, LowFunIndex) concreteFunToLowFunIndexBuilder;
	ArrBuilder!LowFunCause lowFunCausesBuilder;

	MarkVisitFuns markVisitFuns = MarkVisitFuns(
		newMutIndexDict!(immutable LowType.Record, immutable LowFunIndex)(
			getLowTypeCtx.alloc, fullIndexDictSize(allTypes.allRecords)),
		newMutIndexDict!(immutable LowType.Union, immutable LowFunIndex)(
			getLowTypeCtx.alloc, fullIndexDictSize(allTypes.allUnions)));

	immutable(LowFunIndex) addLowFun(immutable LowFunCause source) {
		immutable LowFunIndex res = immutable LowFunIndex(arrBuilderSize(lowFunCausesBuilder));
		add(getLowTypeCtx.alloc, lowFunCausesBuilder, source);
		return res;
	}

	immutable(LowFunIndex) generateMarkVisitForType(immutable LowType lowType) @safe @nogc pure nothrow {
		verify(needsMarkVisitFun(allTypes, lowType));
		immutable(LowFunIndex) addNonArr() {
			return addLowFun(immutable LowFunCause(immutable LowFunCause.MarkVisitNonArr(lowType)));
		}
		immutable(Opt!LowFunIndex) maybeGenerateMarkVisitForType(immutable LowType t) @safe @nogc pure nothrow {
			return needsMarkVisitFun(allTypes, t) ? some(generateMarkVisitForType(t)) : none!LowFunIndex;
		}

		return matchLowType!(
			immutable LowFunIndex,
			(immutable LowType.ExternPtr) =>
				unreachable!(immutable LowFunIndex),
			(immutable LowType.FunPtr) =>
				unreachable!(immutable LowFunIndex),
			(immutable PrimitiveType it) =>
				unreachable!(immutable LowFunIndex),
			(immutable LowType.PtrGc it) {
				immutable Opt!LowFunIndex visitPointee = maybeGenerateMarkVisitForType(it.pointee.deref());
				return getOrAdd(
					getLowTypeCtx.alloc,
					markVisitFuns.gcPointeeToVisit,
					it.pointee.deref(),
					() =>
						addLowFun(immutable LowFunCause(immutable LowFunCause.MarkVisitGcPtr(it, visitPointee))));
			},
			(immutable LowType.PtrRawConst) =>
				unreachable!(immutable LowFunIndex),
			(immutable LowType.PtrRawMut) =>
				unreachable!(immutable LowFunIndex),
			(immutable LowType.Record it) {
				immutable LowRecord record = allTypes.allRecords[it];
				if (isArr(record)) {
					immutable LowType.PtrRawConst elementPtrType = getElementPtrTypeFromArrType(allTypes, it);
					immutable ValueAndDidAdd!(immutable LowFunIndex) outerIndex = getOrAddAndDidAdd(
						markVisitFuns.recordValToVisit,
						it,
						() {
							immutable Opt!LowFunIndex innerIndex =
								needsMarkVisitFun(allTypes, elementPtrType.pointee.deref())
								? some(addLowFun(
									immutable LowFunCause(immutable LowFunCause.MarkVisitArrInner(elementPtrType))))
								: none!LowFunIndex;
							return addLowFun(
								immutable LowFunCause(immutable LowFunCause.MarkVisitArrOuter(it, innerIndex)));
						});
					if (outerIndex.didAdd)
						maybeGenerateMarkVisitForType(elementPtrType.pointee.deref());
					return outerIndex.value;
				} else {
					immutable ValueAndDidAdd!(immutable LowFunIndex) index = getOrAddAndDidAdd(
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
				immutable ValueAndDidAdd!(immutable LowFunIndex) index =
					getOrAddAndDidAdd(markVisitFuns.unionToVisit, it, () => addNonArr());
				if (index.didAdd)
					foreach (immutable LowType member; allTypes.allUnions[it].members)
						maybeGenerateMarkVisitForType(member);
				return index.value;
			},
		)(lowType);
	}

	Late!(immutable LowType) markCtxTypeLate = late!(immutable LowType);

	foreach (immutable Ptr!ConcreteFun fun; program.allFuns) {
		immutable Opt!LowFunIndex opIndex = matchConcreteFunBody!(immutable Opt!LowFunIndex)(
			body_(fun.deref()),
			(ref immutable ConcreteFunBody.Builtin it) {
				if (isCallWithCtxFun(fun.deref())) {
					immutable Ptr!ConcreteStruct funStruct =
						mustBeByVal(fun.deref().paramsExcludingCtxAndClosure[0].type);
					immutable LowType funType = lowTypeFromConcreteStruct(getLowTypeCtx, funStruct);
					immutable LowType returnType =
						lowTypeFromConcreteType(getLowTypeCtx, fun.deref().returnType);
					// NOTE: 'paramsExcludingCtxAndClosure' includes the *explicit* ctx param on this function
					immutable LowType[] nonFunNonCtxParamTypes = map(
						getLowTypeCtx.alloc,
						fun.deref().paramsExcludingCtxAndClosure[2 .. $],
						(ref immutable ConcreteParam it) =>
							lowTypeFromConcreteType(getLowTypeCtx, it.type));
					// TODO: is it possible that we call a fun type but it's not implemented anywhere?
					immutable Opt!(ConcreteLambdaImpl[]) optImpls = program.funStructToImpls[funStruct];
					immutable ConcreteLambdaImpl[] impls = has(optImpls)
						? force(optImpls)
						: emptyArr!ConcreteLambdaImpl;
					return some(addLowFun(immutable LowFunCause(
						immutable LowFunCause.CallWithCtx(funType, returnType, nonFunNonCtxParamTypes, impls))));
				} else if (isMarkVisitFun(fun.deref())) {
					if (!lateIsSet(markCtxTypeLate))
						lateSet(markCtxTypeLate, lowTypeFromConcreteType(
							getLowTypeCtx,
							fun.deref().paramsExcludingCtxAndClosure[0].type));
					immutable LowFunIndex res =
						generateMarkVisitForType(lowTypeFromConcreteType(getLowTypeCtx, only(it.typeArgs)));
					return some(res);
				} else
					return none!LowFunIndex;
			},
			(ref immutable ConcreteFunBody.CreateEnum) =>
				none!LowFunIndex,
			(ref immutable ConcreteFunBody.CreateRecord) =>
				none!LowFunIndex,
			(ref immutable ConcreteFunBody.CreateUnion) =>
				none!LowFunIndex,
			(immutable EnumFunction) =>
				none!LowFunIndex,
			(ref immutable ConcreteFunBody.Extern) =>
				some(addLowFun(immutable LowFunCause(fun))),
			(ref immutable(ConcreteExpr)) =>
				some(addLowFun(immutable LowFunCause(fun))),
			(ref immutable ConcreteFunBody.FlagsFn) =>
				none!LowFunIndex,
			(ref immutable ConcreteFunBody.RecordFieldGet) =>
				none!LowFunIndex,
			(ref immutable ConcreteFunBody.RecordFieldSet) =>
				none!LowFunIndex);
		if (concreteFunWillBecomeNonExternLowFun(fun.deref()))
			verify(has(opIndex));
		if (has(opIndex))
			mustAddToDict(getLowTypeCtx.alloc, concreteFunToLowFunIndexBuilder, fun, force(opIndex));
	}

	immutable LowType markCtxType = lateIsSet(markCtxTypeLate) ? lateGet(markCtxTypeLate) : voidType;

	immutable LowFunCause[] lowFunCauses = finishArr(getLowTypeCtx.alloc, lowFunCausesBuilder);
	immutable ConcreteFunToLowFunIndex concreteFunToLowFunIndex =
		finishDict(getLowTypeCtx.alloc, concreteFunToLowFunIndexBuilder);

	immutable LowType userMainFunPtrType =
		lowTypeFromConcreteType(getLowTypeCtx, program.rtMain.deref().paramsExcludingCtxAndClosure[2].type);

	immutable LowFunIndex markFunIndex = mustGetAt(concreteFunToLowFunIndex, program.markFun);
	immutable LowFunIndex allocFunIndex = mustGetAt(concreteFunToLowFunIndex, program.allocFun);
	immutable FullIndexDict!(LowFunIndex, LowFun) allLowFuns = fullIndexDictOfArr!(LowFunIndex, LowFun)(
		mapWithIndexAndConcatOne(
			getLowTypeCtx.alloc,
			lowFunCauses,
			(immutable size_t index, ref immutable LowFunCause cause) =>
				lowFunFromCause(
					allTypes,
					program.allConstants.allFuns,
					program.allConstants.staticSyms,
					getLowTypeCtx,
					allocFunIndex,
					ctxType,
					concreteFunToLowFunIndex,
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

	return immutable AllLowFuns(concreteFunToLowFunIndex, allLowFuns, immutable LowFunIndex(lowFunCauses.length));
}

public immutable(bool) concreteFunWillBecomeNonExternLowFun()(ref immutable ConcreteFun a) {
	return matchConcreteFunBody!(immutable bool)(
		body_(a),
		(ref immutable ConcreteFunBody.Builtin it) =>
			isCallWithCtxFun(a) || isMarkVisitFun(a),
		(ref immutable ConcreteFunBody.CreateEnum) =>
			false,
		(ref immutable ConcreteFunBody.CreateRecord) =>
			false,
		(ref immutable ConcreteFunBody.CreateUnion) =>
			false,
		(immutable EnumFunction) =>
			false,
		(ref immutable ConcreteFunBody.Extern) =>
			false,
		(ref immutable(ConcreteExpr)) =>
			true,
		(ref immutable ConcreteFunBody.FlagsFn) =>
			false,
		(ref immutable ConcreteFunBody.RecordFieldGet) =>
			false,
		(ref immutable ConcreteFunBody.RecordFieldSet) =>
			false);
}

immutable(LowFun) lowFunFromCause(
	ref immutable AllLowTypes allTypes,
	ref immutable Constant allFuns,
	ref immutable Constant staticSyms,
	ref GetLowTypeCtx getLowTypeCtx,
	immutable LowFunIndex allocFunIndex,
	immutable LowType ctxType,
	ref immutable ConcreteFunToLowFunIndex concreteFunToLowFunIndex,
	ref immutable LowFunCause[] lowFunCauses,
	ref const MarkVisitFuns markVisitFuns,
	immutable LowType markCtxType,
	immutable LowFunIndex markFun,
	immutable LowFunIndex thisFunIndex,
	ref immutable LowFunCause cause,
) {
	return matchLowFunCause!(immutable LowFun)(
		cause,
		(ref immutable LowFunCause.CallWithCtx it) =>
			generateCallWithCtxFun(
				getLowTypeCtx.alloc,
				allTypes,
				concreteFunToLowFunIndex,
				it.returnType,
				it.funType,
				ctxType,
				it.nonFunNonCtxParamTypes,
				it.impls),
		(immutable Ptr!ConcreteFun cf) {
			immutable LowType returnType = lowTypeFromConcreteType(getLowTypeCtx, cf.deref().returnType);
			immutable Opt!LowParam ctxParam = () {
				final switch (cf.deref().needsCtx) {
					case NeedsCtx.no:
						return none!LowParam;
					case NeedsCtx.yes:
						return some(immutable LowParam(
							immutable LowParamSource(immutable LowParamSource.Generated(shortSym("ctx"))),
							ctxType));
				}
			}();
			immutable Opt!LowParam closureParam =
				mapOption!LowParam(cf.deref().closureParam, (ref immutable Ptr!ConcreteParam it) =>
					getLowParam(getLowTypeCtx, it));
			immutable LowParam[] params = mapWithOptFirst2!(LowParam, ConcreteParam)(
				getLowTypeCtx.alloc,
				ctxParam,
				closureParam,
				cf.deref().paramsExcludingCtxAndClosure,
				(immutable(size_t), immutable Ptr!ConcreteParam it) =>
					getLowParam(getLowTypeCtx, it));
			immutable Opt!LowParamIndex ctxParamIndex = has(ctxParam)
				? some(immutable LowParamIndex(0))
				: none!LowParamIndex;
			immutable Opt!LowParamIndex closureParamIndex = has(cf.deref().closureParam)
				? some(immutable LowParamIndex(() {
					final switch (cf.deref().needsCtx) {
						case NeedsCtx.no: return immutable ubyte(0);
						case NeedsCtx.yes: return immutable ubyte(1);
					}
				}()))
				: none!LowParamIndex;
			immutable LowFunBody body_ = getLowFunBody(
				allTypes,
				allFuns,
				staticSyms,
				getLowTypeCtx,
				concreteFunToLowFunIndex,
				allocFunIndex,
				ctxType,
				ctxParamIndex,
				closureParamIndex,
				immutable LowParamIndex((has(ctxParamIndex) ? 1 : 0) + (has(closureParamIndex) ? 1 : 0)),
				thisFunIndex,
				cf.deref(),
				body_(cf.deref()));
			return immutable LowFun(
				immutable LowFunSource(cf),
				returnType,
				immutable LowFunParamsKind(has(ctxParam), has(closureParam)),
				params,
				body_);
		},
		(ref immutable LowFunCause.MarkVisitArrInner it) =>
			generateMarkVisitArrInner(getLowTypeCtx.alloc, markVisitFuns, markCtxType, it.elementPtrType),
		(ref immutable LowFunCause.MarkVisitArrOuter it) =>
			generateMarkVisitArrOuter(
				getLowTypeCtx.alloc,
				markCtxType,
				markFun,
				it.arrType,
				getElementPtrTypeFromArrType(allTypes, it.arrType),
				it.inner),
		(ref immutable LowFunCause.MarkVisitNonArr it) =>
			generateMarkVisitNonArr(getLowTypeCtx.alloc, allTypes, markVisitFuns, markCtxType, it.type),
		(ref immutable LowFunCause.MarkVisitGcPtr it) =>
			generateMarkVisitGcPtr(getLowTypeCtx.alloc, markCtxType, markFun, it.pointerType, it.visitPointee));
}

immutable(LowFun) mainFun(
	ref GetLowTypeCtx ctx,
	immutable LowFunIndex rtMainIndex,
	immutable Ptr!ConcreteFun userMain,
	immutable LowType userMainFunPtrType,
) {
	immutable LowParam[] params = arrLiteral!LowParam(ctx.alloc, [
		immutable LowParam(
			immutable LowParamSource(immutable LowParamSource.Generated(shortSym("argc"))),
			int32Type),
		immutable LowParam(
			immutable LowParamSource(immutable LowParamSource.Generated(shortSym("argv"))),
			char8PtrPtrConstType)]);
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
				genParamRef(FileAndRange.empty, int32Type, argc),
				genParamRef(FileAndRange.empty, char8PtrPtrConstType, argv),
				userMainFunPtr]))));
	immutable LowFunBody body_ = immutable LowFunBody(immutable LowFunExprBody(false, call));
	return immutable LowFun(
		immutable LowFunSource(
			allocate(ctx.alloc, immutable LowFunSource.Generated(shortSym("main"), emptyArr!LowType))),
		int32Type,
		immutable LowFunParamsKind(false, false),
		params,
		body_);
}

immutable(LowParam) getLowParam(ref GetLowTypeCtx ctx, immutable Ptr!ConcreteParam a) {
	return immutable LowParam(immutable LowParamSource(a), lowTypeFromConcreteType(ctx, a.deref().type));
}

immutable(T) withLowLocal(T)(
	ref GetLowExprCtx ctx,
	scope ref immutable Locals locals,
	immutable Ptr!ConcreteLocal concreteLocal,
	scope immutable(T) delegate(scope ref immutable Locals, immutable Ptr!LowLocal) @safe @nogc pure nothrow cb,
) {
	immutable Ptr!LowLocal local = allocate(ctx.alloc, immutable LowLocal(
		immutable LowLocalSource(concreteLocal),
		lowTypeFromConcreteType(ctx.typeCtx, concreteLocal.deref().type)));
	scope immutable Locals newLocals = addLocal(locals, concreteLocal, local);
	return cb(newLocals, local);
}

immutable(T) withOptLowLocal(T)(
	ref GetLowExprCtx ctx,
	scope ref immutable Locals locals,
	immutable Opt!(Ptr!ConcreteLocal) concreteLocal,
	scope immutable(T) delegate(scope ref immutable Locals, immutable Opt!(Ptr!LowLocal)) @safe @nogc pure nothrow cb,
) {
	return has(concreteLocal)
		? withLowLocal!T(
			ctx, locals, force(concreteLocal),
			(scope ref immutable Locals newLocals, immutable Ptr!LowLocal local) =>
				cb(newLocals, some(local)))
		: cb(locals, none!(Ptr!LowLocal));
}

immutable(LowFunBody) getLowFunBody(
	ref immutable AllLowTypes allTypes,
	ref immutable Constant allFuns,
	ref immutable Constant staticSyms,
	ref GetLowTypeCtx getLowTypeCtx,
	ref immutable ConcreteFunToLowFunIndex concreteFunToLowFunIndex,
	immutable LowFunIndex allocFunIndex,
	immutable LowType ctxType,
	immutable Opt!LowParamIndex ctxParam,
	immutable Opt!LowParamIndex closureParam,
	immutable LowParamIndex firstRegularParam,
	immutable LowFunIndex thisFunIndex,
	ref immutable ConcreteFun cf,
	ref immutable ConcreteFunBody a,
) {
	return matchConcreteFunBody!(immutable LowFunBody)(
		a,
		(ref immutable ConcreteFunBody.Builtin it) =>
			unreachable!(immutable LowFunBody),
		(ref immutable ConcreteFunBody.CreateEnum) =>
			unreachable!(immutable LowFunBody),
		(ref immutable ConcreteFunBody.CreateRecord) =>
			unreachable!(immutable LowFunBody),
		(ref immutable ConcreteFunBody.CreateUnion) =>
			unreachable!(immutable LowFunBody),
		(immutable EnumFunction) =>
			unreachable!(immutable LowFunBody),
		(ref immutable ConcreteFunBody.Extern it) =>
			immutable LowFunBody(immutable LowFunBody.Extern(it.isGlobal)),
		(ref immutable ConcreteExpr it) @trusted {
			GetLowExprCtx exprCtx = GetLowExprCtx(
				thisFunIndex,
				ptrTrustMe(allTypes),
				allFuns,
				staticSyms,
				ptrTrustMe_mut(getLowTypeCtx),
				concreteFunToLowFunIndex,
				allocFunIndex,
				ctxType,
				ctxParam,
				closureParam,
				firstRegularParam,
				false);
			immutable Locals locals;
			immutable LowExpr expr = getLowExpr(exprCtx, locals, it, ExprPos.tail);
			return immutable LowFunBody(immutable LowFunExprBody(exprCtx.hasTailRecur, expr));
		},
		(ref immutable ConcreteFunBody.FlagsFn) =>
			unreachable!(immutable LowFunBody),
		(ref immutable ConcreteFunBody.RecordFieldGet) =>
			unreachable!(immutable LowFunBody),
		(ref immutable ConcreteFunBody.RecordFieldSet) =>
			unreachable!(immutable LowFunBody));
}

struct GetLowExprCtx {
	@safe @nogc pure nothrow:

	immutable LowFunIndex currentFun;
	immutable Ptr!AllLowTypes allTypes;
	immutable Constant allFuns;
	immutable Constant staticSyms;
	Ptr!GetLowTypeCtx getLowTypeCtxPtr;
	ConcreteFunToLowFunIndex concreteFunToLowFunIndex;
	immutable LowFunIndex allocFunIndex;
	immutable LowType ctxType;
	immutable Opt!LowParamIndex ctxParam;
	immutable Opt!LowParamIndex closureParam;
	immutable LowParamIndex firstRegularParam;
	bool hasTailRecur;
	size_t tempLocalIndex;

	ref Alloc alloc() return scope {
		return typeCtx.alloc;
	}

	ref typeCtx() return scope {
		return getLowTypeCtxPtr.deref();
	}

}

alias Locals = immutable StackDict!(
	immutable Ptr!ConcreteLocal,
	immutable Ptr!LowLocal,
	nullPtr!ConcreteLocal,
	ptrEquals!ConcreteLocal);
alias addLocal = stackDictAdd!(
	immutable Ptr!ConcreteLocal,
	immutable Ptr!LowLocal,
	nullPtr!ConcreteLocal,
	ptrEquals!ConcreteLocal);
alias getLocal = stackDictMustGet!(
	immutable Ptr!ConcreteLocal,
	immutable Ptr!LowLocal,
	nullPtr!ConcreteLocal,
	ptrEquals!ConcreteLocal);

immutable(LowExpr) genCtxParamRef(ref const GetLowExprCtx ctx, immutable FileAndRange range) {
	return genParamRef(range, ctx.ctxType, force(ctx.ctxParam));
}

immutable(Opt!LowFunIndex) tryGetLowFunIndex(ref const GetLowExprCtx ctx, immutable Ptr!ConcreteFun it) {
	return ctx.concreteFunToLowFunIndex[it];
}

immutable(size_t) getTempLocalIndex(ref GetLowExprCtx ctx) {
	immutable size_t res = ctx.tempLocalIndex;
	ctx.tempLocalIndex++;
	return res;
}

immutable(Ptr!LowLocal) addTempLocal(ref GetLowExprCtx ctx, immutable LowType type) {
	return genLocal(ctx.alloc, shortSym("temp"), getTempLocalIndex(ctx), type);
}

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
) {
	return matchConcreteExprKind!(immutable LowExprKind)(
		expr.kind,
		(ref immutable ConcreteExprKind.Alloc it) =>
			getAllocExpr(ctx, locals, expr.range, it),
		(ref immutable ConcreteExprKind.Call it) =>
			getCallExpr(ctx, locals, exprPos, expr.range, type, it),
		(ref immutable ConcreteExprKind.Cond it) =>
			immutable LowExprKind(allocate(ctx.alloc, immutable LowExprKind.If(
				getLowExpr(ctx, locals, it.cond, ExprPos.nonTail),
				getLowExpr(ctx, locals, it.then, exprPos),
				getLowExpr(ctx, locals, it.else_, exprPos)))),
		(immutable Constant it) =>
			immutable LowExprKind(it),
		(ref immutable ConcreteExprKind.CreateArr it) =>
			getCreateArrExpr(ctx, locals, expr.range, it),
		(ref immutable ConcreteExprKind.CreateRecord it) =>
			immutable LowExprKind(immutable LowExprKind.CreateRecord(getArgs(ctx, locals, it.args))),
		(ref immutable ConcreteExprKind.CreateUnion it) =>
			immutable LowExprKind(allocate(ctx.alloc, immutable LowExprKind.CreateUnion(
				it.memberIndex,
				getLowExpr(ctx, locals, it.arg, ExprPos.nonTail)))),
		(ref immutable ConcreteExprKind.Drop it) =>
			getDropExpr(ctx, locals, expr.range, it),
		(ref immutable ConcreteExprKind.Lambda it) =>
			getLambdaExpr(ctx, locals, expr.range, it),
		(ref immutable ConcreteExprKind.Let it) =>
			getLetExpr(ctx, locals, exprPos, it),
		(ref immutable ConcreteExprKind.LocalRef it) @trusted =>
			immutable LowExprKind(immutable LowExprKind.LocalRef(getLocal(locals, it.local))),
		(ref immutable ConcreteExprKind.MatchEnum it) =>
			getMatchEnumExpr(ctx, locals, exprPos, it),
		(ref immutable ConcreteExprKind.MatchUnion it) =>
			getMatchUnionExpr(ctx, locals, exprPos, it),
		(ref immutable ConcreteExprKind.ParamRef it) =>
			getParamRefExpr(ctx, it),
		(ref immutable ConcreteExprKind.RecordFieldGet it) =>
			getRecordFieldGetExpr(ctx, locals, it),
		(ref immutable ConcreteExprKind.Seq it) =>
			immutable LowExprKind(allocate(ctx.alloc, immutable LowExprKind.Seq(
				getLowExpr(ctx, locals, it.first, ExprPos.nonTail),
				getLowExpr(ctx, locals, it.then, exprPos)))));
}

immutable(LowExpr) getAllocateExpr(
	ref Alloc alloc,
	immutable LowFunIndex allocFunIndex,
	immutable LowType ctxType,
	immutable LowParamIndex ctxParam,
	immutable FileAndRange range,
	immutable LowType ptrType,
	ref immutable LowExpr size,
) {
	immutable LowExpr allocate = immutable LowExpr(
		anyPtrMutType, //TODO: ensure this will definitely be the return type of allocFunIndex
		range,
		immutable LowExprKind(immutable LowExprKind.Call(
			allocFunIndex,
			arrLiteral!LowExpr(alloc, [genParamRef(range, ctxType, ctxParam), size]))));
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

immutable(LowExprKind) getAllocExpr2(
	ref GetLowExprCtx ctx,
	immutable FileAndRange range,
	ref immutable LowExpr inner,
	immutable LowType ptrType,
) {
	immutable Ptr!LowLocal local = addTempLocal(ctx, ptrType);
	immutable LowExpr sizeofT = genSizeOf(range, asPtrGcPointee(ptrType));
	immutable LowExpr allocatePtr =
		getAllocateExpr(ctx.alloc, ctx.allocFunIndex, ctx.ctxType, force(ctx.ctxParam), range, ptrType, sizeofT);
	immutable LowExpr getTemp = genLocalRef(ctx.alloc, range, local);
	immutable LowExpr setTemp = genWriteToPtr(ctx.alloc, range, getTemp, inner);
	return immutable LowExprKind(allocate(ctx.alloc, immutable LowExprKind.Let(
		local,
		allocatePtr,
		genSeq(ctx.alloc, range, setTemp, getTemp))));
}

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
		? getCallRegular(ctx, locals, exprPos, range, a, force(opCalled))
		: getCallSpecial(ctx, locals, exprPos, range, type, a);
}

immutable(LowExprKind) getCallRegular(
	ref GetLowExprCtx ctx,
	scope ref immutable Locals locals,
	immutable ExprPos exprPos,
	immutable FileAndRange range,
	ref immutable ConcreteExprKind.Call a,
	immutable LowFunIndex called,
) {
	if (called == ctx.currentFun && exprPos == ExprPos.tail) {
		ctx.hasTailRecur = true;
		ArrBuilder!UpdateParam updateParams;
		immutable size_t p0 = () {
			final switch (a.called.deref().needsCtx) {
				case NeedsCtx.no:
					return 0;
				case NeedsCtx.yes:
					return 1;
			}
		}();
		foreach (immutable size_t argIndex, ref immutable ConcreteExpr it; a.args) {
			immutable LowExpr arg = getLowExpr(ctx, locals, it, ExprPos.nonTail);
			immutable LowParamIndex paramIndex = immutable LowParamIndex(p0 + argIndex);
			if (!(isParamRef(arg.kind) && asParamRef(arg.kind).index == paramIndex))
				add(ctx.alloc, updateParams, immutable UpdateParam(paramIndex, arg));
		}
		return immutable LowExprKind(immutable LowExprKind.TailRecur(finishArr(ctx.alloc, updateParams)));
	} else {
		immutable Opt!LowExpr ctxArg = () {
			final switch (a.called.deref().needsCtx) {
				case NeedsCtx.no:
					return none!LowExpr;
				case NeedsCtx.yes:
					return some(genCtxParamRef(ctx, range));
			}
		}();
		immutable LowExpr[] args = mapWithOptFirst(ctx.alloc, ctxArg, a.args, (ref immutable ConcreteExpr it) =>
			getLowExpr(ctx, locals, it, ExprPos.nonTail));
		return immutable LowExprKind(immutable LowExprKind.Call(called, args));
	}
}

immutable(LowExprKind) getCallSpecial(
	ref GetLowExprCtx ctx,
	scope ref immutable Locals locals,
	immutable ExprPos exprPos,
	immutable FileAndRange range,
	immutable LowType type,
	ref immutable ConcreteExprKind.Call a,
) {
	return matchConcreteFunBody!(immutable LowExprKind)(
		body_(a.called.deref()),
		(ref immutable ConcreteFunBody.Builtin) =>
			getCallBuiltinExpr(ctx, locals, exprPos, range, type, a),
		(ref immutable ConcreteFunBody.CreateEnum it) =>
			immutable LowExprKind(immutable Constant(immutable Constant.Integral(it.value.value))),
		(ref immutable ConcreteFunBody.CreateRecord) {
			immutable LowExpr[] args = getArgs(ctx, locals, a.args);
			immutable LowExprKind create = immutable LowExprKind(immutable LowExprKind.CreateRecord(args));
			if (isPtrGc(type)) {
				immutable LowExpr inner = immutable LowExpr(asPtrGcPointee(type), range, create);
				return getAllocExpr2(ctx, range, inner, type);
			} else
				return create;
		},
		(ref immutable ConcreteFunBody.CreateUnion it) {
			immutable LowExpr arg = empty(a.args)
				? genVoid(range)
				: getLowExpr(ctx, locals, only(a.args), ExprPos.nonTail);
			return immutable LowExprKind(allocate(ctx.alloc, immutable LowExprKind.CreateUnion(it.memberIndex, arg)));
		},
		(immutable EnumFunction it) =>
			genEnumFunction(ctx, locals, it, a.args),
		(ref immutable ConcreteFunBody.Extern) =>
			unreachable!(immutable LowExprKind),
		(ref immutable(ConcreteExpr)) =>
			unreachable!(immutable LowExprKind),
		(ref immutable ConcreteFunBody.FlagsFn it) {
			final switch (it.fn) {
				case FlagsFunction.all:
					return immutable LowExprKind(immutable Constant(immutable Constant.Integral(it.allValue)));
				case FlagsFunction.negate:
					return genFlagsNegate(
						ctx.alloc,
						range,
						it.allValue,
						getLowExpr(ctx, locals, only(a.args), ExprPos.nonTail));
				case FlagsFunction.new_:
					return immutable LowExprKind(immutable Constant(immutable Constant.Integral(0)));
			}
		},
		(ref immutable ConcreteFunBody.RecordFieldGet it) =>
			immutable LowExprKind(allocate(ctx.alloc, immutable LowExprKind.RecordFieldGet(
				getLowExpr(ctx, locals, only(a.args), ExprPos.nonTail),
				it.fieldIndex))),
		(ref immutable ConcreteFunBody.RecordFieldSet it) {
			verify(a.args.length == 2);
			return immutable LowExprKind(allocate(ctx.alloc, immutable LowExprKind.RecordFieldSet(
				getLowExpr(ctx, locals, a.args[0], ExprPos.nonTail),
				it.fieldIndex,
				getLowExpr(ctx, locals, a.args[1], ExprPos.nonTail))));
		});
}

immutable(LowExprKind) genFlagsNegate(
	ref Alloc alloc,
	immutable FileAndRange range,
	immutable ulong allValue,
	immutable LowExpr a,
) {
	return genEnumIntersect(
		alloc,
		immutable LowExpr(a.type, range, genBitwiseNegate(alloc, a)),
		immutable LowExpr(a.type, range, immutable LowExprKind(
			immutable Constant(immutable Constant.Integral(allValue)))));
}

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

immutable(LowExpr[]) getArgs(ref GetLowExprCtx ctx, scope ref immutable Locals locals, immutable ConcreteExpr[] args) {
	return map!LowExpr(ctx.alloc, args, (ref immutable ConcreteExpr arg) =>
		getLowExpr(ctx, locals, arg, ExprPos.nonTail));
}

immutable(LowExprKind) getCallBuiltinExpr(
	ref GetLowExprCtx ctx,
	scope ref immutable Locals locals,
	immutable ExprPos exprPos,
	immutable FileAndRange range,
	immutable LowType type,
	ref immutable ConcreteExprKind.Call a,
) {
	immutable Sym name = matchConcreteFunSource!(
		immutable Sym,
		(ref immutable FunInst it) =>
			name(decl(it).deref()),
		(ref immutable(ConcreteFunSource.Lambda)) =>
			unreachable!(immutable Sym)(),
		(ref immutable(ConcreteFunSource.Test)) =>
			unreachable!(immutable Sym)(),
	)(a.called.deref().source);
	immutable(LowType) paramType(immutable size_t index) {
		return index < a.args.length
			? lowTypeFromConcreteType(ctx.typeCtx, a.called.deref().paramsExcludingCtxAndClosure[index].type)
			: voidType;
	}
	immutable LowType p0 = paramType(0);
	immutable LowType p1 = paramType(1);
	immutable BuiltinKind builtinKind = getBuiltinKind(name, type, p0, p1);
	immutable(LowExpr) getArg(ref immutable ConcreteExpr arg, immutable ExprPos argPos) {
		return getLowExpr(ctx, locals, arg, argPos);
	}
	return matchBuiltinKind!(immutable LowExprKind)(
		builtinKind,
		(ref immutable BuiltinKind.AllFuns) =>
			immutable LowExprKind(ctx.allFuns),
		(ref immutable BuiltinKind.CallFunPtr) =>
			immutable LowExprKind(allocate(ctx.alloc, immutable LowExprKind.CallFunPtr(
				getLowExpr(ctx, locals, a.args[0], ExprPos.nonTail),
				getArgs(ctx, locals, a.args[1 .. $])))),
		(ref immutable BuiltinKind.GetCtx) =>
			immutable LowExprKind(immutable LowExprKind.ParamRef(force(ctx.ctxParam))),
		(ref immutable Constant it) =>
			immutable LowExprKind(it),
		(ref immutable BuiltinKind.InitConstants) =>
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
		(ref immutable BuiltinKind.OptOr) {
			verify(a.args.length == 2);
			verify(lowTypeEqual(p0, p1));
			immutable Ptr!LowLocal lhsLocal = addTempLocal(ctx, p0);
			immutable LowExpr lhsRef = genLocalRef(ctx.alloc, range, lhsLocal);
			return immutable LowExprKind(allocate(ctx.alloc, immutable LowExprKind.Let(
				lhsLocal,
				getArg(a.args[0], ExprPos.nonTail),
				immutable LowExpr(p0, range, immutable LowExprKind(allocate(ctx.alloc, immutable LowExprKind.MatchUnion(
					lhsRef,
					arrLiteral!(LowExprKind.MatchUnion.Case)(ctx.alloc, [
						immutable LowExprKind.MatchUnion.Case(none!(Ptr!LowLocal), getArg(a.args[1], ExprPos.tail)),
						immutable LowExprKind.MatchUnion.Case(none!(Ptr!LowLocal), lhsRef)]))))))));
		},
		(ref immutable BuiltinKind.OptQuestion2) {
			verify(a.args.length == 2);
			immutable Ptr!LowLocal valueLocal = addTempLocal(ctx, p1);
			return immutable LowExprKind(allocate(ctx.alloc, immutable LowExprKind.MatchUnion(
				getArg(a.args[0], ExprPos.nonTail),
				arrLiteral!(LowExprKind.MatchUnion.Case)(ctx.alloc, [
					immutable LowExprKind.MatchUnion.Case(none!(Ptr!LowLocal), getArg(a.args[1], ExprPos.tail)),
					immutable LowExprKind.MatchUnion.Case(
						some(valueLocal),
						genLocalRef(ctx.alloc, range, valueLocal))]))));
		},
		(ref immutable BuiltinKind.PtrCast) {
			verify(a.args.length == 1);
			return genPtrCastKind(ctx.alloc, getLowExpr(ctx, locals, only(a.args), ExprPos.nonTail));
		},
		(ref immutable BuiltinKind.SizeOf) {
			immutable LowType typeArg =
				lowTypeFromConcreteType(ctx.typeCtx, only(asBuiltin(body_(a.called.deref())).typeArgs));
			return immutable LowExprKind(immutable LowExprKind.SizeOf(typeArg));
		},
		(ref immutable BuiltinKind.StaticSyms) =>
			immutable LowExprKind(ctx.staticSyms),
		(ref immutable BuiltinKind.Zeroed) =>
			immutable LowExprKind(immutable LowExprKind.Zeroed()));
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
	immutable LowExpr allocatePtr = getAllocateExpr(
		ctx.alloc,
		ctx.allocFunIndex,
		ctx.ctxType,
		force(ctx.ctxParam),
		range,
		elementPtrType,
		sizeBytes);
	immutable Ptr!LowLocal temp = addTempLocal(ctx, elementPtrType);
	immutable LowExpr getTemp = genLocalRef(ctx.alloc, range, temp);
	immutable(LowExpr) recur(immutable LowExpr cur, immutable size_t prevIndex) {
		if (prevIndex == 0)
			return cur;
		else {
			immutable size_t index = prevIndex - 1;
			immutable LowExpr arg = getLowExpr(ctx, locals, a.args[index], ExprPos.nonTail);
			immutable LowExpr elementPtr = genAddPtr(
				ctx.alloc,
				asPtrRawConst(elementPtrType),
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
			arrLiteral!LowExpr(ctx.alloc, [nElements, genLocalRef(ctx.alloc, range, temp)]))));
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
) {
	return immutable LowExprKind(allocate(ctx.alloc, immutable LowExprKind.CreateUnion(
		a.memberIndex,
		has(a.closure)
			? getLowExpr(ctx, locals, force(a.closure).deref(), ExprPos.nonTail)
			: genVoid(range))));
}

immutable(LowExprKind) getLetExpr(
	ref GetLowExprCtx ctx,
	scope ref immutable Locals locals,
	immutable ExprPos exprPos,
	ref immutable ConcreteExprKind.Let a,
) {
	return withLowLocal(
		ctx, locals, a.local,
		(scope ref immutable Locals innerLocals, immutable Ptr!LowLocal local) =>
			immutable LowExprKind(allocate(ctx.alloc, immutable LowExprKind.Let(
				local,
				getLowExpr(ctx, innerLocals, a.value, ExprPos.nonTail),
				getLowExpr(ctx, innerLocals, a.then, exprPos)))));
}

immutable(LowExprKind) getMatchEnumExpr(
	ref GetLowExprCtx ctx,
	scope ref immutable Locals locals,
	immutable ExprPos exprPos,
	ref immutable ConcreteExprKind.MatchEnum a,
) {
	immutable ConcreteStructBody.Enum enum_ = asEnum(body_(mustBeByVal(a.matchedValue.type).deref()));
	immutable LowExpr matchedValue = getLowExpr(ctx, locals, a.matchedValue, ExprPos.nonTail);
	immutable LowExpr[] cases = map!LowExpr(ctx.alloc, a.cases, (ref immutable ConcreteExpr case_) =>
		getLowExpr(ctx, locals, case_, exprPos));
	return matchEnum!(immutable LowExprKind)(
		enum_,
		(immutable size_t) =>
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
				(scope ref immutable Locals caseLocals, immutable Opt!(Ptr!LowLocal) local) =>
					immutable LowExprKind.MatchUnion.Case(
						local,
						getLowExpr(ctx, caseLocals, case_.then, exprPos)))))));
}

immutable(LowExprKind) getParamRefExpr(ref GetLowExprCtx ctx, ref immutable ConcreteExprKind.ParamRef a) {
	if (!has(a.param.deref().index)) {
		//TODO: don't generate ParamRef in ConcreteModel for closure field access. Do that in lowering.
		verify(isClosure(a.param.deref().source));
		return immutable LowExprKind(immutable LowExprKind.ParamRef(force(ctx.closureParam)));
	} else
		return immutable LowExprKind(immutable LowExprKind.ParamRef(immutable LowParamIndex(
			ctx.firstRegularParam.index + force(a.param.deref().index))));
}

immutable(LowExprKind) getRecordFieldGetExpr(
	ref GetLowExprCtx ctx,
	scope ref immutable Locals locals,
	ref immutable ConcreteExprKind.RecordFieldGet a,
) {
	return immutable LowExprKind(allocate(ctx.alloc, immutable LowExprKind.RecordFieldGet(
		getLowExpr(ctx, locals, a.target, ExprPos.nonTail),
		a.fieldIndex)));
}
