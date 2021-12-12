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
	charPtrPtrConstType,
	constantNat64,
	genAddPtr,
	genBitwiseNegate,
	genEnumEq,
	genEnumIntersect,
	genEnumToIntegral,
	genEnumUnion,
	genVoid,
	getElementPtrTypeFromArrType,
	getSizeOf,
	int32Type,
	localRef,
	paramRef,
	ptrCast,
	ptrCastKind,
	seq,
	voidType,
	wrapMulNat64,
	writeToPtr;
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
	ConcreteFunExprBody,
	ConcreteFunSource,
	ConcreteLambdaImpl,
	ConcreteLocal,
	ConcreteParam,
	ConcreteProgram,
	ConcreteStruct,
	ConcreteStructBody,
	ConcreteType,
	ConcreteFunToName,
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
	mustBeNonPointer,
	NeedsCtx,
	PointerTypeAndConstantsConcrete;
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
import util.collection.arr : at, empty, emptyArr, first, only, size;
import util.collection.arrBuilder : add, ArrBuilder, arrBuilderSize, finishArr;
import util.collection.arrUtil :
	arrLiteral,
	exists,
	map,
	mapZipPtrFirst,
	mapWithIndexAndConcatOne,
	mapWithOptFirst,
	mapWithOptFirst2,
	tail;
import util.collection.dict : getAt, mustGetAt, PtrDict;
import util.collection.dictBuilder : finishDict, mustAddToDict, PtrDictBuilder;
import util.collection.fullIndexDict : FullIndexDict, fullIndexDictGet, fullIndexDictOfArr, fullIndexDictSize;
import util.collection.mutIndexDict : getAt, getOrAddAndDidAdd, mustGetAt, MutIndexDict, newMutIndexDict;
import util.collection.mutDict :
	addToMutDict,
	getAt_mut,
	getOrAdd,
	mustDelete,
	mustGetAt_mut,
	MutDict,
	MutPtrDict,
	ValueAndDidAdd;
import util.late : Late, late, lateGet, lateIsSet, lateSet;
import util.memory : allocate;
import util.opt : asImmutable, force, has, mapOption, none, Opt, optOr, some;
import util.perf : Perf, PerfMeasure, withMeasure;
import util.ptr : Ptr, ptrTrustMe, ptrTrustMe_mut;
import util.sourceRange : FileAndRange;
import util.sym : shortSymAlphaLiteral, Sym;
import util.util : unreachable, verify;

immutable(LowProgram) lower(ref Alloc alloc, ref Perf perf, ref immutable ConcreteProgram a) {
	return withMeasure!(immutable LowProgram, () =>
		lowerInner(alloc, a)
	)(alloc, perf, PerfMeasure.lower);
}

private immutable(LowProgram) lowerInner(ref Alloc alloc, ref immutable ConcreteProgram a) {
	AllLowTypesWithCtx allTypes = getAllLowTypes(alloc, a);
	immutable AllLowFuns allFuns = getAllLowFuns(alloc, allTypes.allTypes, allTypes.getLowTypeCtx, a);
	immutable AllConstantsLow allConstants = convertAllConstants(alloc, allTypes.getLowTypeCtx, a.allConstants);
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

immutable(LowFunIndex) getMarkVisitFun(ref const MarkVisitFuns funs, ref immutable LowType type) {
	immutable Opt!LowFunIndex opt = tryGetMarkVisitFun(funs, type);
	return force(opt);
}

immutable(Opt!LowFunIndex) tryGetMarkVisitFun(ref const MarkVisitFuns funs, ref immutable LowType type) {
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
			asImmutable(getAt(funs.recordValToVisit, it)),
		(immutable LowType.Union it) =>
			asImmutable(getAt(funs.unionToVisit, it)),
	)(type);
}

private:

immutable(AllConstantsLow) convertAllConstants(
	ref Alloc alloc,
	ref GetLowTypeCtx ctx,
	ref immutable AllConstantsConcrete a,
) {
	immutable string[] cStrings = a.cStrings;
	immutable ArrTypeAndConstantsLow[] arrs =
		map!ArrTypeAndConstantsLow(alloc, a.arrs, (ref immutable ArrTypeAndConstantsConcrete it) {
			immutable LowType arrType = lowTypeFromConcreteStruct(alloc, ctx, it.arrType);
			immutable LowType elementType = lowTypeFromConcreteType(alloc, ctx, it.elementType);
			return immutable ArrTypeAndConstantsLow(asRecordType(arrType), elementType, it.constants);
		});
	immutable PointerTypeAndConstantsLow[] records =
		map(alloc, a.pointers, (ref immutable PointerTypeAndConstantsConcrete it) =>
			immutable PointerTypeAndConstantsLow(lowTypeFromConcreteStruct(alloc, ctx, it.pointeeType), it.constants));
	return immutable AllConstantsLow(cStrings, arrs, records);
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
	immutable PtrDict!(ConcreteStruct, LowType) concreteStructToType;
	MutPtrDict!(ConcreteStruct, immutable LowType) concreteStructToPtrType;
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
		immutable Opt!LowType lowType = matchConcreteStructBody!(
			immutable Opt!LowType,
			(ref immutable ConcreteStructBody.Builtin it) {
				final switch (it.kind) {
					case BuiltinStructKind.bool_:
						return some(immutable LowType(PrimitiveType.bool_));
					case BuiltinStructKind.char_:
						return some(immutable LowType(PrimitiveType.char_));
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
				some(addUnion(s)),
		)(body_(s.deref()));
		if (has(lowType))
			mustAddToDict(alloc, concreteStructToTypeBuilder, s, force(lowType));
	}

	GetLowTypeCtx getLowTypeCtx = GetLowTypeCtx(finishDict(alloc, concreteStructToTypeBuilder));

	immutable FullIndexDict!(LowType.FunPtr, LowFunPtrType) allFunPtrs =
		fullIndexDictOfArr!(LowType.FunPtr, LowFunPtrType)(
			map(alloc, finishArr(alloc, allFunPtrSources), (ref immutable Ptr!ConcreteStruct it) {
				immutable ConcreteType[] typeArgs = asBuiltin(it.deref().body_).typeArgs;
				immutable LowType returnType = lowTypeFromConcreteType(alloc, getLowTypeCtx, first(typeArgs));
				immutable LowType[] paramTypes =
					map(alloc, tail(typeArgs), (ref immutable ConcreteType typeArg) =>
						lowTypeFromConcreteType(alloc, getLowTypeCtx, typeArg));
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
								lowTypeFromConcreteType(alloc, getLowTypeCtx, field.deref().type))))));
	immutable FullIndexDict!(LowType.Union, LowUnion) allUnions =
		fullIndexDictOfArr!(LowType.Union, LowUnion)(
			map(alloc, finishArr(alloc, allUnionSources), (ref immutable Ptr!ConcreteStruct it) =>
				getLowUnion(alloc, program, getLowTypeCtx, it)));

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
	ref Alloc alloc,
	ref immutable ConcreteProgram program,
	ref GetLowTypeCtx getLowTypeCtx,
	immutable Ptr!ConcreteStruct s,
) {
	immutable LowType[] members = matchConcreteStructBody!(
		immutable LowType[],
		(ref immutable ConcreteStructBody.Builtin it) {
			verify(it.kind == BuiltinStructKind.fun);
			return map(alloc, mustGetAt(program.funStructToImpls, s), (ref immutable ConcreteLambdaImpl impl) =>
				lowTypeFromConcreteType(alloc, getLowTypeCtx, impl.closureType));
		},
		(ref immutable(ConcreteStructBody.Enum)) => unreachable!(immutable LowType[])(),
		(ref immutable(ConcreteStructBody.Flags)) => unreachable!(immutable LowType[])(),
		(ref immutable(ConcreteStructBody.ExternPtr)) => unreachable!(immutable LowType[])(),
		(ref immutable(ConcreteStructBody.Record)) => unreachable!(immutable LowType[])(),
		(ref immutable ConcreteStructBody.Union it) =>
			map(alloc, it.members, (ref immutable Opt!ConcreteType member) =>
				has(member)
					? lowTypeFromConcreteType(alloc, getLowTypeCtx, force(member))
					: immutable LowType(PrimitiveType.void_)),
	)(body_(s.deref()));
	return immutable LowUnion(s, members);
}

immutable(LowType) getLowRawPtrConstType(
	ref Alloc alloc,
	ref GetLowTypeCtx ctx,
	immutable LowType pointee,
) {
	//TODO:PERF Cache creation of pointer types by pointee
	return immutable LowType(immutable LowType.PtrRawConst(allocate(alloc, pointee)));
}

immutable(LowType) getLowGcPtrType(
	ref Alloc alloc,
	ref GetLowTypeCtx ctx,
	immutable LowType pointee,
) {
	//TODO:PERF Cache creation of pointer types by pointee
	return immutable LowType(immutable LowType.PtrGc(allocate(alloc, pointee)));
}

immutable(LowType) lowTypeFromConcreteStruct(
	ref Alloc alloc,
	ref GetLowTypeCtx ctx,
	immutable Ptr!ConcreteStruct it,
) {
	return optOr!LowType(getAt(ctx.concreteStructToType, it), () {
		immutable ConcreteStructBody.Builtin builtin = asBuiltin(body_(it.deref()));
		verify(builtin.kind == BuiltinStructKind.ptrConst || builtin.kind == BuiltinStructKind.ptrMut);
		//TODO: cache the creation.. don't want an allocation for every BuiltinStructKind.ptr to the same target type
		immutable Ptr!LowType inner = allocate(alloc, lowTypeFromConcreteType(alloc, ctx, only(builtin.typeArgs)));
		switch (builtin.kind) {
			case BuiltinStructKind.ptrConst:
				return immutable LowType(immutable LowType.PtrRawConst(inner));
			case BuiltinStructKind.ptrMut:
				return immutable LowType(immutable LowType.PtrRawMut(inner));
			default:
				return unreachable!(immutable LowType);
		}
	});
}

immutable(LowType) lowTypeFromConcreteType(
	ref Alloc alloc,
	ref GetLowTypeCtx ctx,
	immutable ConcreteType it,
) {
	return it.isPointer
		? getOrAdd(alloc, ctx.concreteStructToPtrType, it.struct_, () =>
			immutable LowType(immutable LowType.PtrGc(
				allocate(alloc, lowTypeFromConcreteStruct(alloc, ctx, it.struct_)))))
		: lowTypeFromConcreteStruct(alloc, ctx, it.struct_);
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

immutable(bool) needsMarkVisitFun(ref immutable AllLowTypes allTypes, ref immutable LowType a) {
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
			immutable LowRecord record = fullIndexDictGet(allTypes.allRecords, it);
			return isArr(record) || exists!LowField(record.fields, (ref immutable LowField field) =>
				needsMarkVisitFun(allTypes, field.type));
		},
		(immutable LowType.Union it) =>
			exists!LowType(fullIndexDictGet(allTypes.allUnions, it).members, (ref immutable LowType member) =>
				needsMarkVisitFun(allTypes, member)),
	)(a);
}

immutable(AllLowFuns) getAllLowFuns(
	ref Alloc alloc,
	ref immutable AllLowTypes allTypes,
	ref GetLowTypeCtx getLowTypeCtx,
	ref immutable ConcreteProgram program,
) {
	immutable LowType ctxType =
		lowTypeFromConcreteType(alloc, getLowTypeCtx, immutable ConcreteType(true, program.ctxType));
	PtrDictBuilder!(ConcreteFun, LowFunIndex) concreteFunToLowFunIndexBuilder;
	ArrBuilder!LowFunCause lowFunCausesBuilder;

	MarkVisitFuns markVisitFuns = MarkVisitFuns(
		newMutIndexDict!(immutable LowType.Record, immutable LowFunIndex)(
			alloc, fullIndexDictSize(allTypes.allRecords)),
		newMutIndexDict!(immutable LowType.Union, immutable LowFunIndex)(
			alloc, fullIndexDictSize(allTypes.allUnions)));

	immutable(LowFunIndex) addLowFun(immutable LowFunCause source) {
		immutable LowFunIndex res = immutable LowFunIndex(arrBuilderSize(lowFunCausesBuilder));
		add(alloc, lowFunCausesBuilder, source);
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
					alloc,
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
				immutable LowRecord record = fullIndexDictGet(allTypes.allRecords, it);
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
					foreach (ref immutable LowType member; fullIndexDictGet(allTypes.allUnions, it).members)
						maybeGenerateMarkVisitForType(member);
				return index.value;
			},
		)(lowType);
	}

	Late!(immutable LowType) markCtxTypeLate = late!(immutable LowType);

	foreach (immutable Ptr!ConcreteFun fun; program.allFuns) {
		immutable Opt!LowFunIndex opIndex = matchConcreteFunBody!(
			immutable Opt!LowFunIndex,
			(ref immutable ConcreteFunBody.Builtin it) {
				if (isCallWithCtxFun(fun.deref())) {
					immutable Ptr!ConcreteStruct funStruct =
						mustBeNonPointer(first(fun.deref().paramsExcludingCtxAndClosure).type);
					immutable LowType funType = lowTypeFromConcreteStruct(alloc, getLowTypeCtx, funStruct);
					immutable LowType returnType =
						lowTypeFromConcreteType(alloc, getLowTypeCtx, fun.deref().returnType);
					// NOTE: 'paramsExcludingCtxAndClosure' includes the *explicit* ctx param on this function
					immutable LowType[] nonFunNonCtxParamTypes =
						map(alloc, fun.deref().paramsExcludingCtxAndClosure[2 .. $], (ref immutable ConcreteParam it) =>
							lowTypeFromConcreteType(alloc, getLowTypeCtx, it.type));
					// TODO: is it possible that we call a fun type but it's not implemented anywhere?
					immutable Opt!(ConcreteLambdaImpl[]) optImpls = getAt(program.funStructToImpls, funStruct);
					immutable ConcreteLambdaImpl[] impls = has(optImpls)
						? force(optImpls)
						: emptyArr!ConcreteLambdaImpl;
					return some(addLowFun(immutable LowFunCause(
						immutable LowFunCause.CallWithCtx(funType, returnType, nonFunNonCtxParamTypes, impls))));
				} else if (isMarkVisitFun(fun.deref())) {
					if (!lateIsSet(markCtxTypeLate))
						lateSet(markCtxTypeLate, lowTypeFromConcreteType(
							alloc,
							getLowTypeCtx,
							first(fun.deref().paramsExcludingCtxAndClosure).type));
					immutable LowFunIndex res =
						generateMarkVisitForType(lowTypeFromConcreteType(alloc, getLowTypeCtx, only(it.typeArgs)));
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
			(ref immutable ConcreteFunExprBody) =>
				some(addLowFun(immutable LowFunCause(fun))),
			(ref immutable ConcreteFunBody.FlagsFn) =>
				none!LowFunIndex,
			(ref immutable ConcreteFunBody.RecordFieldGet) =>
				none!LowFunIndex,
			(ref immutable ConcreteFunBody.RecordFieldSet) =>
				none!LowFunIndex,
		)(body_(fun.deref()));
		if (concreteFunWillBecomeNonExternLowFun(fun.deref()))
			verify(has(opIndex));
		if (has(opIndex))
			mustAddToDict(alloc, concreteFunToLowFunIndexBuilder, fun, force(opIndex));
	}

	immutable LowType markCtxType = lateIsSet(markCtxTypeLate) ? lateGet(markCtxTypeLate) : voidType;

	immutable LowFunCause[] lowFunCauses = finishArr(alloc, lowFunCausesBuilder);
	immutable ConcreteFunToLowFunIndex concreteFunToLowFunIndex =
		finishDict(alloc, concreteFunToLowFunIndexBuilder);

	immutable LowType userMainFunPtrType =
		lowTypeFromConcreteType(alloc, getLowTypeCtx, at(program.rtMain.deref().paramsExcludingCtxAndClosure, 2).type);

	immutable LowFunIndex markFunIndex = mustGetAt(concreteFunToLowFunIndex, program.markFun);
	immutable LowFunIndex allocFunIndex = mustGetAt(concreteFunToLowFunIndex, program.allocFun);
	immutable FullIndexDict!(LowFunIndex, LowFun) allLowFuns = fullIndexDictOfArr!(LowFunIndex, LowFun)(
		mapWithIndexAndConcatOne(
			alloc,
			lowFunCauses,
			(immutable size_t index, ref immutable LowFunCause cause) =>
				lowFunFromCause(
					alloc,
					program.funToName,
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
				alloc,
				getLowTypeCtx,
				mustGetAt(concreteFunToLowFunIndex, program.rtMain),
				program.userMain,
				userMainFunPtrType)));

	return immutable AllLowFuns(concreteFunToLowFunIndex, allLowFuns, immutable LowFunIndex(size(lowFunCauses)));
}

public immutable(bool) concreteFunWillBecomeNonExternLowFun()(ref immutable ConcreteFun a) {
	return matchConcreteFunBody!(
		immutable bool,
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
		(ref immutable ConcreteFunExprBody) =>
			true,
		(ref immutable ConcreteFunBody.FlagsFn) =>
			false,
		(ref immutable ConcreteFunBody.RecordFieldGet) =>
			false,
		(ref immutable ConcreteFunBody.RecordFieldSet) =>
			false,
	)(body_(a));
}

immutable(LowFun) lowFunFromCause(
	ref Alloc alloc,
	ref immutable ConcreteFunToName funToName,
	ref immutable AllLowTypes allTypes,
	ref immutable Constant allFuns,
	ref immutable Constant staticSyms,
	ref GetLowTypeCtx getLowTypeCtx,
	immutable LowFunIndex allocFunIndex,
	ref immutable LowType ctxType,
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
				alloc,
				allTypes,
				concreteFunToLowFunIndex,
				it.returnType,
				it.funType,
				ctxType,
				it.nonFunNonCtxParamTypes,
				it.impls),
		(immutable Ptr!ConcreteFun cf) {
			immutable LowType returnType = lowTypeFromConcreteType(alloc, getLowTypeCtx, cf.deref().returnType);
			immutable Opt!LowParam ctxParam = () {
				final switch (cf.deref().needsCtx) {
					case NeedsCtx.no:
						return none!LowParam;
					case NeedsCtx.yes:
						return some(immutable LowParam(
							immutable LowParamSource(immutable LowParamSource.Generated(shortSymAlphaLiteral("ctx"))),
							ctxType));
				}
			}();
			immutable Opt!LowParam closureParam = mapOption!LowParam(
				cf.deref().closureParam,
				(ref immutable Ptr!ConcreteParam it) =>
					getLowParam(alloc, getLowTypeCtx, it));
			immutable LowParam[] params = mapWithOptFirst2!(LowParam, ConcreteParam)(
				alloc,
				ctxParam,
				closureParam,
				cf.deref().paramsExcludingCtxAndClosure,
				(immutable(size_t), immutable Ptr!ConcreteParam it) =>
					getLowParam(alloc, getLowTypeCtx, it));
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
				alloc,
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
			generateMarkVisitArrInner(alloc, markVisitFuns, markCtxType, it.elementPtrType),
		(ref immutable LowFunCause.MarkVisitArrOuter it) =>
			generateMarkVisitArrOuter(
				alloc,
				markCtxType,
				markFun,
				it.arrType,
				getElementPtrTypeFromArrType(allTypes, it.arrType),
				it.inner),
		(ref immutable LowFunCause.MarkVisitNonArr it) =>
			generateMarkVisitNonArr(alloc, allTypes, markVisitFuns, markCtxType, it.type),
		(ref immutable LowFunCause.MarkVisitGcPtr it) =>
			generateMarkVisitGcPtr(alloc, markCtxType, markFun, it.pointerType, it.visitPointee));
}

immutable(LowFun) mainFun(
	ref Alloc alloc,
	ref const GetLowTypeCtx ctx,
	immutable LowFunIndex rtMainIndex,
	immutable Ptr!ConcreteFun userMain,
	ref immutable LowType userMainFunPtrType,
) {
	immutable LowParam[] params = arrLiteral!LowParam(alloc, [
		immutable LowParam(
			immutable LowParamSource(immutable LowParamSource.Generated(shortSymAlphaLiteral("argc"))),
			int32Type),
		immutable LowParam(
			immutable LowParamSource(immutable LowParamSource.Generated(shortSymAlphaLiteral("argv"))),
			charPtrPtrConstType)]);
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
			arrLiteral!LowExpr(alloc, [
				paramRef(FileAndRange.empty, int32Type, argc),
				paramRef(FileAndRange.empty, charPtrPtrConstType, argv),
				userMainFunPtr]))));
	immutable LowFunBody body_ = immutable LowFunBody(immutable LowFunExprBody(false, call));
	return immutable LowFun(
		immutable LowFunSource(
			allocate(alloc, immutable LowFunSource.Generated(shortSymAlphaLiteral("main"), emptyArr!LowType))),
		int32Type,
		immutable LowFunParamsKind(false, false),
		params,
		body_);
}

immutable(LowParam) getLowParam(ref Alloc alloc, ref GetLowTypeCtx ctx, immutable Ptr!ConcreteParam a) {
	return immutable LowParam(immutable LowParamSource(a), lowTypeFromConcreteType(alloc, ctx, a.deref().type));
}

immutable(T) withLowLocal(T)(
	ref Alloc alloc,
	ref GetLowExprCtx ctx,
	immutable Ptr!ConcreteLocal concreteLocal,
	scope immutable(T) delegate(immutable Ptr!LowLocal) @safe @nogc pure nothrow cb,
) {
	immutable Ptr!LowLocal local = allocate(alloc, immutable LowLocal(
		immutable LowLocalSource(concreteLocal),
		lowTypeFromConcreteType(alloc, typeCtx(ctx), concreteLocal.deref().type)));
	//TODO: store lookup on stack instead of using dict
	addToMutDict(alloc, ctx.locals, concreteLocal, local);
	immutable T res = cb(local);
	mustDelete(ctx.locals, concreteLocal);
	return res;
}

immutable(T) withOptLowLocal(T)(
	ref Alloc alloc,
	ref GetLowExprCtx ctx,
	immutable Opt!(Ptr!ConcreteLocal) concreteLocal,
	scope immutable(T) delegate(immutable Opt!(Ptr!LowLocal)) @safe @nogc pure nothrow cb,
) {
	return has(concreteLocal)
		? withLowLocal!T(alloc, ctx, force(concreteLocal), (immutable Ptr!LowLocal local) => cb(some(local)))
		: cb(none!(Ptr!LowLocal));
}

immutable(LowFunBody) getLowFunBody(
	ref Alloc alloc,
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
	return matchConcreteFunBody!(
		immutable LowFunBody,
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
		(ref immutable ConcreteFunExprBody it) {
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
			immutable LowExpr expr = getLowExpr(alloc, exprCtx, it.expr, ExprPos.tail);
			return immutable LowFunBody(immutable LowFunExprBody(exprCtx.hasTailRecur, expr));
		},
		(ref immutable ConcreteFunBody.FlagsFn) =>
			unreachable!(immutable LowFunBody),
		(ref immutable ConcreteFunBody.RecordFieldGet) =>
			unreachable!(immutable LowFunBody),
		(ref immutable ConcreteFunBody.RecordFieldSet) =>
			unreachable!(immutable LowFunBody),
	)(a);
}

struct GetLowExprCtx {
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
	MutPtrDict!(ConcreteLocal, immutable Ptr!LowLocal) locals;
}

//TODO:KILL (inline)
ref GetLowTypeCtx typeCtx(return scope ref GetLowExprCtx ctx) {
	return ctx.getLowTypeCtxPtr.deref();
}

immutable(LowExpr) getCtxParamRef(
	ref Alloc alloc,
	ref const GetLowExprCtx ctx,
	ref immutable FileAndRange range,
) {
	return paramRef(range, ctx.ctxType, force(ctx.ctxParam));
}

immutable(Opt!LowFunIndex) tryGetLowFunIndex(ref const GetLowExprCtx ctx, immutable Ptr!ConcreteFun it) {
	return getAt(ctx.concreteFunToLowFunIndex, it);
}

immutable(Ptr!LowLocal) addTempLocal(ref Alloc alloc, ref GetLowExprCtx ctx, ref immutable LowType type) {
	immutable Ptr!LowLocal res = allocate(alloc, immutable LowLocal(
		immutable LowLocalSource(immutable LowLocalSource.Generated(shortSymAlphaLiteral("temp"), ctx.tempLocalIndex)),
		type));
	ctx.tempLocalIndex++;
	return res;
}

enum ExprPos {
	tail,
	nonTail,
}

immutable(LowExpr) getLowExpr(
	ref Alloc alloc,
	ref GetLowExprCtx ctx,
	ref immutable ConcreteExpr expr,
	immutable ExprPos exprPos,
) {
	immutable LowType type = lowTypeFromConcreteType(alloc, typeCtx(ctx), expr.type);
	return immutable LowExpr(type, expr.range, getLowExprKind(alloc, ctx, type, expr, exprPos));
}

immutable(LowExprKind) getLowExprKind(
	ref Alloc alloc,
	ref GetLowExprCtx ctx,
	ref immutable LowType type,
	ref immutable ConcreteExpr expr,
	immutable ExprPos exprPos,
) {
	return matchConcreteExprKind!(
		immutable LowExprKind,
		(ref immutable ConcreteExprKind.Alloc it) =>
			getAllocExpr(alloc, ctx, expr.range, it),
		(ref immutable ConcreteExprKind.Call it) =>
			getCallExpr(alloc, ctx, exprPos, expr.range, type, it),
		(ref immutable ConcreteExprKind.Cond it) =>
			immutable LowExprKind(allocate(alloc, immutable LowExprKind.If(
				getLowExpr(alloc, ctx, it.cond, ExprPos.nonTail),
				getLowExpr(alloc, ctx, it.then, exprPos),
				getLowExpr(alloc, ctx, it.else_, exprPos)))),
		(ref immutable Constant it) =>
			immutable LowExprKind(it),
		(ref immutable ConcreteExprKind.CreateArr it) =>
			getCreateArrExpr(alloc, ctx, expr.range, it),
		(ref immutable ConcreteExprKind.CreateRecord it) =>
			immutable LowExprKind(immutable LowExprKind.CreateRecord(
				getArgs(alloc, ctx, it.args))),
		(ref immutable ConcreteExprKind.Lambda it) =>
			getLambdaExpr(alloc, ctx, type, expr.range, it),
		(ref immutable ConcreteExprKind.Let it) =>
			getLetExpr(alloc, ctx, exprPos, expr.range, it),
		(ref immutable ConcreteExprKind.LocalRef it) =>
			immutable LowExprKind(immutable LowExprKind.LocalRef(mustGetAt_mut(ctx.locals, it.local))),
		(ref immutable ConcreteExprKind.MatchEnum it) =>
			getMatchEnumExpr(alloc, ctx, exprPos, it),
		(ref immutable ConcreteExprKind.MatchUnion it) =>
			getMatchUnionExpr(alloc, ctx, exprPos, it),
		(ref immutable ConcreteExprKind.ParamRef it) =>
			getParamRefExpr(alloc, ctx, it),
		(ref immutable ConcreteExprKind.RecordFieldGet it) =>
			getRecordFieldGetExpr(alloc, ctx, it),
		(ref immutable ConcreteExprKind.Seq it) =>
			immutable LowExprKind(allocate(alloc, immutable LowExprKind.Seq(
				getLowExpr(alloc, ctx, it.first, ExprPos.nonTail),
				getLowExpr(alloc, ctx, it.then, exprPos)))),
	)(expr.kind);
}

immutable(LowExpr) getAllocateExpr(
	ref Alloc alloc,
	immutable LowFunIndex allocFunIndex,
	ref immutable LowType ctxType,
	immutable LowParamIndex ctxParam,
	ref immutable FileAndRange range,
	ref immutable LowType ptrType,
	ref immutable LowExpr size,
) {
	immutable LowExpr allocate = immutable LowExpr(
		anyPtrMutType, //TODO: ensure this will definitely be the return type of allocFunIndex
		range,
		immutable LowExprKind(immutable LowExprKind.Call(
			allocFunIndex,
			arrLiteral!LowExpr(alloc, [paramRef(range, ctxType, ctxParam), size]))));
	return ptrCast(alloc, ptrType, range, allocate);
}

immutable(LowExprKind) getAllocExpr(
	ref Alloc alloc,
	ref GetLowExprCtx ctx,
	ref immutable FileAndRange range,
	ref immutable ConcreteExprKind.Alloc a,
) {
	// (temp0 = (T*) alloc(sizeof(T)), *temp0 = inner, temp0)
	immutable LowExpr inner = getLowExpr(alloc, ctx, a.inner, ExprPos.nonTail);
	immutable LowType ptrType = getLowGcPtrType(alloc, typeCtx(ctx), inner.type);
	return getAllocExpr2(alloc, ctx, range, inner, ptrType);
}

immutable(LowExprKind) getAllocExpr2(
	ref Alloc alloc,
	ref GetLowExprCtx ctx,
	ref immutable FileAndRange range,
	ref immutable LowExpr inner,
	ref immutable LowType ptrType,
) {
	immutable Ptr!LowLocal local = addTempLocal(alloc, ctx, ptrType);
	immutable LowExpr sizeofT = getSizeOf(range, asPtrGcPointee(ptrType));
	immutable LowExpr allocatePtr =
		getAllocateExpr(alloc, ctx.allocFunIndex, ctx.ctxType, force(ctx.ctxParam), range, ptrType, sizeofT);
	immutable LowExpr getTemp = localRef(alloc, range, local);
	immutable LowExpr setTemp = writeToPtr(alloc, range, getTemp, inner);
	return immutable LowExprKind(allocate(alloc, immutable LowExprKind.Let(
		local,
		allocatePtr,
		seq(alloc, range, setTemp, getTemp))));
}

immutable(LowExprKind) getCallExpr(
	ref Alloc alloc,
	ref GetLowExprCtx ctx,
	immutable ExprPos exprPos,
	ref immutable FileAndRange range,
	ref immutable LowType type,
	ref immutable ConcreteExprKind.Call a,
) {
	immutable Opt!LowFunIndex opCalled = tryGetLowFunIndex(ctx, a.called);
	return has(opCalled)
		? getCallRegular(alloc, ctx, exprPos, range, type, a, force(opCalled))
		: getCallSpecial(alloc, ctx, exprPos, range, type, a);
}

immutable(LowExprKind) getCallRegular(
	ref Alloc alloc,
	ref GetLowExprCtx ctx,
	immutable ExprPos exprPos,
	ref immutable FileAndRange range,
	ref immutable LowType type,
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
			immutable LowExpr arg = getLowExpr(alloc, ctx, it, ExprPos.nonTail);
			immutable LowParamIndex paramIndex = immutable LowParamIndex(p0 + argIndex);
			if (!(isParamRef(arg.kind) && asParamRef(arg.kind).index == paramIndex))
				add(alloc, updateParams, immutable UpdateParam(paramIndex, arg));
		}
		return immutable LowExprKind(immutable LowExprKind.TailRecur(finishArr(alloc, updateParams)));
	} else {
		immutable Opt!LowExpr ctxArg = () {
			final switch (a.called.deref().needsCtx) {
				case NeedsCtx.no:
					return none!LowExpr;
				case NeedsCtx.yes:
					return some(getCtxParamRef(alloc, ctx, range));
			}
		}();
		immutable LowExpr[] args = mapWithOptFirst(alloc, ctxArg, a.args, (ref immutable ConcreteExpr it) =>
			getLowExpr(alloc, ctx, it, ExprPos.nonTail));
		return immutable LowExprKind(immutable LowExprKind.Call(called, args));
	}
}

immutable(LowExprKind) getCallSpecial(
	ref Alloc alloc,
	ref GetLowExprCtx ctx,
	immutable ExprPos exprPos,
	ref immutable FileAndRange range,
	ref immutable LowType type,
	ref immutable ConcreteExprKind.Call a,
) {
	return matchConcreteFunBody!(
		immutable LowExprKind,
		(ref immutable ConcreteFunBody.Builtin) {
			return getCallBuiltinExpr(alloc, ctx, exprPos, range, type, a);
		},
		(ref immutable ConcreteFunBody.CreateEnum it) =>
			immutable LowExprKind(immutable Constant(immutable Constant.Integral(it.value.value))),
		(ref immutable ConcreteFunBody.CreateRecord) {
			immutable LowExpr[] args = getArgs(alloc, ctx, a.args);
			immutable LowExprKind create = immutable LowExprKind(immutable LowExprKind.CreateRecord(args));
			if (isPtrGc(type)) {
				immutable LowExpr inner = immutable LowExpr(asPtrGcPointee(type), range, create);
				return getAllocExpr2(alloc, ctx, range, inner, type);
			} else
				return create;
		},
		(ref immutable ConcreteFunBody.CreateUnion it) {
			immutable LowExpr arg = empty(a.args)
				? genVoid(range)
				: getLowExpr(alloc, ctx, only(a.args), ExprPos.nonTail);
			return immutable LowExprKind(allocate(alloc, immutable LowExprKind.CreateUnion(it.memberIndex, arg)));
		},
		(immutable EnumFunction it) =>
			genEnumFunction(alloc, ctx, it, a.args),
		(ref immutable ConcreteFunBody.Extern) =>
			unreachable!(immutable LowExprKind),
		(ref immutable ConcreteFunExprBody) =>
			unreachable!(immutable LowExprKind),
		(ref immutable ConcreteFunBody.FlagsFn it) {
			final switch (it.fn) {
				case FlagsFunction.all:
					return immutable LowExprKind(immutable Constant(immutable Constant.Integral(it.allValue)));
				case FlagsFunction.empty:
					return immutable LowExprKind(immutable Constant(immutable Constant.Integral(0)));
				case FlagsFunction.negate:
					return genFlagsNegate(
						alloc,
						range,
						it.allValue,
						getLowExpr(alloc, ctx, only(a.args), ExprPos.nonTail));
			}
		},
		(ref immutable ConcreteFunBody.RecordFieldGet it) =>
			immutable LowExprKind(allocate(alloc, immutable LowExprKind.RecordFieldGet(
				getLowExpr(alloc, ctx, only(a.args), ExprPos.nonTail),
				it.fieldIndex))),
		(ref immutable ConcreteFunBody.RecordFieldSet it) {
			verify(size(a.args) == 2);
			return immutable LowExprKind(allocate(alloc, immutable LowExprKind.RecordFieldSet(
				getLowExpr(alloc, ctx, at(a.args, 0), ExprPos.nonTail),
				it.fieldIndex,
				getLowExpr(alloc, ctx, at(a.args, 1), ExprPos.nonTail))));
		},
	)(body_(a.called.deref()));
}

immutable(LowExprKind) genFlagsNegate(
	ref Alloc alloc,
	ref immutable FileAndRange range,
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
	ref Alloc alloc,
	ref GetLowExprCtx ctx,
	immutable EnumFunction a,
	ref immutable ConcreteExpr[] args,
) {
	immutable(LowExpr) arg0() { return getLowExpr(alloc, ctx, at(args, 0), ExprPos.nonTail); }
	immutable(LowExpr) arg1() { return getLowExpr(alloc, ctx, at(args, 1), ExprPos.nonTail); }
	final switch (a) {
		case EnumFunction.equal:
			verify(size(args) == 2);
			return genEnumEq(alloc, arg0(), arg1());
		case EnumFunction.intersect:
			verify(size(args) == 2);
			return genEnumIntersect(alloc, arg0(), arg1());
		case EnumFunction.toIntegral:
			verify(size(args) == 1);
			return genEnumToIntegral(alloc, arg0());
		case EnumFunction.union_:
			verify(size(args) == 2);
			return genEnumUnion(alloc, arg0(), arg1());
		case EnumFunction.members:
			// In concretize, this was translated to a constant
			return unreachable!(immutable LowExprKind);
	}
}

immutable(LowExpr[]) getArgs(
	ref Alloc alloc,
	ref GetLowExprCtx ctx,
	immutable ConcreteExpr[] args,
) {
	return map!LowExpr(alloc, args, (ref immutable ConcreteExpr arg) =>
		getLowExpr(alloc, ctx, arg, ExprPos.nonTail));
}

immutable(LowExprKind) getCallBuiltinExpr(
	ref Alloc alloc,
	ref GetLowExprCtx ctx,
	immutable ExprPos exprPos,
	ref immutable FileAndRange range,
	ref immutable LowType type,
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
		return index < size(a.args)
			? lowTypeFromConcreteType(
				alloc,
				typeCtx(ctx),
				at(a.called.deref().paramsExcludingCtxAndClosure, index).type)
			: voidType;
	}
	immutable LowType p0 = paramType(0);
	immutable LowType p1 = paramType(1);
	immutable BuiltinKind builtinKind = getBuiltinKind(name, type, p0, p1);
	immutable(LowExpr) getArg(ref immutable ConcreteExpr arg, immutable ExprPos argPos) {
		return getLowExpr(alloc, ctx, arg, argPos);
	}
	return matchBuiltinKind!(immutable LowExprKind)(
		builtinKind,
		(ref immutable BuiltinKind.AllFuns) =>
			immutable LowExprKind(ctx.allFuns),
		(ref immutable BuiltinKind.CallFunPtr) =>
			immutable LowExprKind(allocate(alloc, immutable LowExprKind.CallFunPtr(
				getLowExpr(alloc, ctx, first(a.args), ExprPos.nonTail),
				getArgs(alloc, ctx, tail(a.args))))),
		(ref immutable BuiltinKind.GetCtx) =>
			immutable LowExprKind(immutable LowExprKind.ParamRef(force(ctx.ctxParam))),
		(ref immutable Constant it) =>
			immutable LowExprKind(it),
		(ref immutable BuiltinKind.InitConstants) =>
			immutable LowExprKind(immutable LowExprKind.InitConstants()),
		(immutable LowExprKind.SpecialUnary.Kind kind) {
			verify(size(a.args) == 1);
			return immutable LowExprKind(
				allocate(alloc, immutable LowExprKind.SpecialUnary(kind, getArg(at(a.args, 0), ExprPos.nonTail))));
		},
		(immutable LowExprKind.SpecialBinary.Kind kind) {
			verify(size(a.args) == 2);
			immutable ExprPos arg1Pos = () {
				switch (kind) {
					case LowExprKind.SpecialBinary.Kind.and:
					case LowExprKind.SpecialBinary.Kind.or:
						return exprPos;
					default:
						return ExprPos.nonTail;
				}
			}();
			return immutable LowExprKind(allocate(alloc, immutable LowExprKind.SpecialBinary(
				kind,
				getArg(at(a.args, 0), ExprPos.nonTail),
				getArg(at(a.args, 1), arg1Pos))));
		},
		(ref immutable BuiltinKind.PtrCast) {
			verify(size(a.args) == 1);
			return ptrCastKind(alloc, getLowExpr(alloc, ctx, only(a.args), ExprPos.nonTail));
		},
		(ref immutable BuiltinKind.SizeOf) {
			immutable LowType typeArg =
				lowTypeFromConcreteType(alloc, typeCtx(ctx), only(asBuiltin(body_(a.called.deref())).typeArgs));
			return immutable LowExprKind(immutable LowExprKind.SizeOf(typeArg));
		},
		(ref immutable BuiltinKind.StaticSyms) =>
			immutable LowExprKind(ctx.staticSyms),
		(ref immutable BuiltinKind.Zeroed) =>
			immutable LowExprKind(immutable LowExprKind.Zeroed()));
}

immutable(LowExprKind) getCreateArrExpr(
	ref Alloc alloc,
	ref GetLowExprCtx ctx,
	ref immutable FileAndRange range,
	ref immutable ConcreteExprKind.CreateArr a,
) {
	// (temp = _alloc(ctx, sizeof(foo) * 2),
	// *(temp + 0) = a,
	// *(temp + 1) = b,
	// arr_foo{2, temp})
	immutable LowType arrType = lowTypeFromConcreteStruct(alloc, typeCtx(ctx), a.arrType);
	immutable LowType elementType = lowTypeFromConcreteType(alloc, typeCtx(ctx), elementType(a));
	immutable LowType elementPtrType = getLowRawPtrConstType(alloc, typeCtx(ctx), elementType);
	immutable LowExpr elementSize = getSizeOf(range, elementType);
	immutable LowExpr nElements = constantNat64(range, size(a.args));
	immutable LowExpr sizeBytes = wrapMulNat64(alloc, range, elementSize, nElements);
	immutable LowExpr allocatePtr = getAllocateExpr(
		alloc,
		ctx.allocFunIndex,
		ctx.ctxType,
		force(ctx.ctxParam),
		range,
		elementPtrType,
		sizeBytes);
	immutable Ptr!LowLocal temp = addTempLocal(alloc, ctx, elementPtrType);
	immutable LowExpr getTemp = localRef(alloc, range, temp);
	immutable(LowExpr) recur(immutable LowExpr cur, immutable size_t prevIndex) {
		if (prevIndex == 0)
			return cur;
		else {
			immutable size_t index = prevIndex - 1;
			immutable LowExpr arg = getLowExpr(alloc, ctx, at(a.args, index), ExprPos.nonTail);
			immutable LowExpr elementPtr = genAddPtr(
				alloc,
				asPtrRawConst(elementPtrType),
				range,
				getTemp,
				constantNat64(range, index));
			immutable LowExpr writeToElement = writeToPtr(alloc, range, elementPtr, arg);
			return recur(seq(alloc, range, writeToElement, cur), index);
		}
	}
	immutable LowExpr createArr = immutable LowExpr(
		arrType,
		range,
		immutable LowExprKind(immutable LowExprKind.CreateRecord(
			arrLiteral!LowExpr(alloc, [nElements, localRef(alloc, range, temp)]))));
	immutable LowExpr writeAndGetArr = recur(createArr, size(a.args));
	return immutable LowExprKind(allocate(alloc, immutable LowExprKind.Let(
		temp,
		allocatePtr,
		writeAndGetArr)));
}

immutable(LowExprKind) getLambdaExpr(
	ref Alloc alloc,
	ref GetLowExprCtx ctx,
	ref immutable LowType type,
	ref immutable FileAndRange range,
	ref immutable ConcreteExprKind.Lambda a,
) {
	return immutable LowExprKind(allocate(alloc, immutable LowExprKind.CreateUnion(
		a.memberIndex,
		getLowExpr(alloc, ctx, a.closure, ExprPos.nonTail))));
}

immutable(LowExprKind) getLetExpr(
	ref Alloc alloc,
	ref GetLowExprCtx ctx,
	immutable ExprPos exprPos,
	ref immutable FileAndRange range,
	ref immutable ConcreteExprKind.Let a,
) {
	return withLowLocal!LowExprKind(alloc, ctx, a.local, (immutable Ptr!LowLocal local) =>
		immutable LowExprKind(allocate(alloc, immutable LowExprKind.Let(
			local,
			getLowExpr(alloc, ctx, a.value, ExprPos.nonTail),
			getLowExpr(alloc, ctx, a.then, exprPos)))));
}

immutable(LowExprKind) getMatchEnumExpr(
	ref Alloc alloc,
	ref GetLowExprCtx ctx,
	immutable ExprPos exprPos,
	ref immutable ConcreteExprKind.MatchEnum a,
) {
	immutable ConcreteStructBody.Enum enum_ = asEnum(body_(mustBeNonPointer(a.matchedValue.type).deref()));
	immutable LowExpr matchedValue = getLowExpr(alloc, ctx, a.matchedValue, ExprPos.nonTail);
	immutable LowExpr[] cases = map!LowExpr(alloc, a.cases, (ref immutable ConcreteExpr case_) =>
		getLowExpr(alloc, ctx, case_, exprPos));
	return matchEnum!(
		immutable LowExprKind,
		(immutable size_t) =>
			immutable LowExprKind(allocate(alloc, immutable LowExprKind.Switch0ToN(matchedValue, cases))),
		(immutable EnumValue[] values) =>
			immutable LowExprKind(
				allocate(alloc, immutable LowExprKind.SwitchWithValues(matchedValue, values, cases))),
	)(enum_);
}

immutable(LowExprKind) getMatchUnionExpr(
	ref Alloc alloc,
	ref GetLowExprCtx ctx,
	immutable ExprPos exprPos,
	ref immutable ConcreteExprKind.MatchUnion a,
) {
	immutable LowExpr matched = getLowExpr(alloc, ctx, a.matchedValue, ExprPos.nonTail);
	return immutable LowExprKind(allocate(alloc, immutable LowExprKind.MatchUnion(
		matched,
		map(alloc, a.cases, (ref immutable ConcreteExprKind.MatchUnion.Case case_) =>
			withOptLowLocal(alloc, ctx, case_.local, (immutable Opt!(Ptr!LowLocal) local) =>
				immutable LowExprKind.MatchUnion.Case(
					local,
					getLowExpr(alloc, ctx, case_.then, exprPos)))))));
}

immutable(LowExprKind) getParamRefExpr(
	ref Alloc alloc,
	ref GetLowExprCtx ctx,
	ref immutable ConcreteExprKind.ParamRef a,
) {
	if (!has(a.param.deref().index)) {
		//TODO: don't generate ParamRef in ConcreteModel for closure field access. Do that in lowering.
		verify(isClosure(a.param.deref().source));
		return immutable LowExprKind(immutable LowExprKind.ParamRef(force(ctx.closureParam)));
	} else
		return immutable LowExprKind(immutable LowExprKind.ParamRef(immutable LowParamIndex(
			ctx.firstRegularParam.index + force(a.param.deref().index))));
}

immutable(LowExprKind) getRecordFieldGetExpr(
	ref Alloc alloc,
	ref GetLowExprCtx ctx,
	ref immutable ConcreteExprKind.RecordFieldGet a,
) {
	return immutable LowExprKind(allocate(alloc, immutable LowExprKind.RecordFieldGet(
		getLowExpr(alloc, ctx, a.target, ExprPos.nonTail),
		a.field.deref().index)));
}
