module lower.lower;

@safe @nogc pure nothrow:

import lower.checkLowModel : checkLowProgram;
import lower.generateCompareFun : ComparisonTypes, generateCompareFun;
import lower.getBuiltinCall : BuiltinKind, getBuiltinKind, matchBuiltinKind;
import lower.lowExprHelpers :
	addPtr,
	anyPtrType,
	charPtrPtrType,
	constantNat64,
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
	asRecord,
	asUnion,
	body_,
	BuiltinStructKind,
	ConcreteExpr,
	ConcreteExprKind,
	ConcreteField,
	ConcreteFun,
	ConcreteFunBody,
	ConcreteFunExprBody,
	ConcreteFunSource,
	ConcreteLocal,
	ConcreteParam,
	ConcreteProgram,
	ConcreteStruct,
	ConcreteStructBody,
	ConcreteType,
	isClosure,
	isCompareFun,
	matchConcreteExprKind,
	matchConcreteFunBody,
	matchConcreteFunSource,
	matchConcreteStructBody,
	PointerTypeAndConstantsConcrete;
import model.constant : Constant;
import model.lowModel :
	AllConstantsLow,
	ArrTypeAndConstantsLow,
	asFunPtrType,
	asNonFunPtrType,
	asRecordType,
	asUnionType,
	isArr,
	isNonFunPtrType,
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
	LowFunSig,
	LowFunSource,
	LowLocal,
	LowLocalSource,
	LowParam,
	LowParamIndex,
	LowParamSource,
	LowProgram,
	LowRecord,
	LowType,
	LowUnion,
	matchLowType,
	nPrimitiveTypes,
	PointerTypeAndConstantsLow,
	PrimitiveType;
import model.model : decl, FunInst, name, range;
import util.bools : Bool, False, True;
import util.collection.arr : Arr, at, empty, first, only, arrRange = range, size;
import util.collection.arrBuilder : add, ArrBuilder, arrBuilderSize, finishArr;
import util.collection.arrUtil :
	arrLiteral,
	map,
	mapPtrs,
	mapWithIndexAndConcatOne,
	mapWithOptFirst,
	mapWithOptFirst2,
	tail;
import util.collection.dict : Dict, getAt, mustGetAt;
import util.collection.dictBuilder : addToDict, DictBuilder, finishDictShouldBeNoConflict;
import util.collection.fullIndexDict : FullIndexDict, fullIndexDictGet, fullIndexDictOfArr, fullIndexDictSize;
import util.collection.mutIndexDict : getOrAddAndDidAdd, mustGetAt, MutIndexDict, newMutIndexDict;
import util.collection.mutDict : addToMutDict, getOrAdd, mustDelete, mustGetAt_mut, MutDict, ValueAndDidAdd;
import util.late : Late, late, lateGet, lateIsSet, lateSet;
import util.memory : allocate, nu;
import util.opt : force, has, mapOption, none, Opt, optOr, some;
import util.ptr : comparePtr, Ptr, ptrTrustMe, ptrTrustMe_mut;
import util.sourceRange : FileAndRange;
import util.sym : shortSymAlphaLiteral, Sym;
import util.util : unreachable, verify;

immutable(Ptr!LowProgram) lower(Alloc)(ref Alloc alloc, ref immutable ConcreteProgram a) {
	AllLowTypesWithCtx allTypes = getAllLowTypes(alloc, a.allStructs);
	immutable AllConstantsLow allConstants = convertAllConstants(alloc, allTypes.getLowTypeCtx, a.allConstants);
	immutable AllLowFuns allFuns = getAllLowFuns!Alloc(
		alloc,
		allTypes.allTypes,
		allTypes.getLowTypeCtx,
		a);
	immutable Ptr!LowProgram res = nu!LowProgram(
		alloc,
		allConstants,
		allTypes.allTypes.allExternPtrTypes,
		allTypes.allTypes.allFunPtrTypes,
		allTypes.allTypes.allRecords,
		allTypes.allTypes.allUnions,
		allFuns.allLowFuns,
		allFuns.main);
	checkLowProgram(alloc, res);
	return res;
}

immutable(LowFunIndex) getCompareFun(ref const CompareFuns compareFuns, ref immutable LowType type) {
	return matchLowType!(immutable LowFunIndex)(
		type,
		(immutable LowType.ExternPtr) =>
			unreachable!(immutable LowFunIndex),
		(immutable LowType.FunPtr) =>
			unreachable!(immutable LowFunIndex),
		(immutable LowType.NonFunPtr it) =>
			mustGetAt(compareFuns.recordPtrToCompare, asRecordType(it.pointee)),
		(immutable PrimitiveType it) =>
			mustGetAt(compareFuns.primitiveToCompare, immutable PrimitiveTypeIndex(sizeTOfPrimitiveType(it))),
		(immutable LowType.Record it) =>
			mustGetAt(compareFuns.recordValToCompare, it),
		(immutable LowType.Union it) =>
			mustGetAt(compareFuns.unionToCompare, it));
}

private:

immutable(AllConstantsLow) convertAllConstants(Alloc)(
	ref Alloc alloc,
	ref GetLowTypeCtx ctx,
	ref immutable AllConstantsConcrete a,
) {
	immutable Arr!ArrTypeAndConstantsLow arrs =
		map!ArrTypeAndConstantsLow(alloc, a.arrs, (ref immutable ArrTypeAndConstantsConcrete it) {
			immutable LowType arrType = lowTypeFromConcreteStruct(alloc, ctx, it.arrType);
			immutable LowType elementType = lowTypeFromConcreteType(alloc, ctx, it.elementType);
			return immutable ArrTypeAndConstantsLow(asRecordType(arrType), elementType, it.constants);
		});
	immutable Arr!PointerTypeAndConstantsLow records =
		map(alloc, a.pointers, (ref immutable PointerTypeAndConstantsConcrete it) =>
			immutable PointerTypeAndConstantsLow(lowTypeFromConcreteStruct(alloc, ctx, it.pointeeType), it.constants));
	return immutable AllConstantsLow(arrs, records);
}

struct AllLowTypes {
	immutable FullIndexDict!(LowType.ExternPtr, LowExternPtrType) allExternPtrTypes;
	immutable FullIndexDict!(LowType.FunPtr, LowFunPtrType) allFunPtrTypes;
	immutable FullIndexDict!(LowType.Record, LowRecord) allRecords;
	immutable FullIndexDict!(LowType.Union, LowUnion) allUnions;
}

struct AllLowTypesWithCtx {
	immutable AllLowTypes allTypes;
	GetLowTypeCtx getLowTypeCtx;
}

struct CompareFuns {
	MutIndexDict!(immutable LowType.Record, immutable LowFunIndex) recordPtrToCompare;
	MutIndexDict!(immutable LowType.Record, immutable LowFunIndex) recordValToCompare;
	MutIndexDict!(immutable LowType.Union, immutable LowFunIndex) unionToCompare;
	MutIndexDict!(immutable PrimitiveTypeIndex, immutable LowFunIndex) primitiveToCompare;
}

struct AllLowFuns {
	immutable FullIndexDict!(LowFunIndex, LowFun) allLowFuns;
	immutable LowFunIndex main;
}

struct GetLowTypeCtx {
	immutable Dict!(Ptr!ConcreteStruct, LowType, comparePtr!ConcreteStruct) concreteStructToType;
	MutDict!(immutable Ptr!ConcreteStruct, immutable LowType, comparePtr!ConcreteStruct) concreteStructToPtrType;
}

AllLowTypesWithCtx getAllLowTypes(Alloc)(ref Alloc alloc, ref immutable Arr!(Ptr!ConcreteStruct) allStructs) {
	DictBuilder!(Ptr!ConcreteStruct, LowType, comparePtr!ConcreteStruct) concreteStructToTypeBuilder;
	ArrBuilder!(Ptr!ConcreteStruct) allFunPtrSources;
	ArrBuilder!LowExternPtrType allExternPtrTypes;
	ArrBuilder!(Ptr!ConcreteStruct) allRecordSources;
	ArrBuilder!(Ptr!ConcreteStruct) allUnionSources;

	foreach (immutable Ptr!ConcreteStruct s; arrRange(allStructs)) {
		immutable Opt!LowType lowType = matchConcreteStructBody!(immutable Opt!LowType)(
			body_(s),
			(ref immutable ConcreteStructBody.Builtin it) {
				final switch (it.kind) {
					case BuiltinStructKind.bool_:
						return some(immutable LowType(PrimitiveType.bool_));
					case BuiltinStructKind.char_:
						return some(immutable LowType(PrimitiveType.char_));
					case BuiltinStructKind.float64:
						return some(immutable LowType(PrimitiveType.float64));
					case BuiltinStructKind.funPtrN:
						immutable size_t i = arrBuilderSize(allFunPtrSources);
						add(alloc, allFunPtrSources, s);
						return some(immutable LowType(immutable LowType.FunPtr(i)));
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
					case BuiltinStructKind.ptr:
						return none!LowType;
					case BuiltinStructKind.void_:
						return some(immutable LowType(PrimitiveType.void_));
				}
			},
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
			(ref immutable ConcreteStructBody.Union it) {
				immutable size_t i = arrBuilderSize(allUnionSources);
				add(alloc, allUnionSources, s);
				return some(immutable LowType(immutable LowType.Union(i)));
			});
		if (has(lowType))
			addToDict(alloc, concreteStructToTypeBuilder, s, force(lowType));
	}

	GetLowTypeCtx getLowTypeCtx = GetLowTypeCtx(finishDictShouldBeNoConflict(alloc, concreteStructToTypeBuilder));

	immutable FullIndexDict!(LowType.FunPtr, LowFunPtrType) allFunPtrs =
		fullIndexDictOfArr!(LowType.FunPtr, LowFunPtrType)(
			map(alloc, finishArr(alloc, allFunPtrSources), (ref immutable Ptr!ConcreteStruct it) {
				immutable Arr!ConcreteType typeArgs = asBuiltin(it.body_).typeArgs;
				immutable LowType returnType = lowTypeFromConcreteType(alloc, getLowTypeCtx, first(typeArgs));
				immutable Arr!LowType paramTypes =
					map(alloc, tail(typeArgs), (ref immutable ConcreteType typeArg) =>
						lowTypeFromConcreteType(alloc, getLowTypeCtx, typeArg));
				return immutable LowFunPtrType(it, returnType, paramTypes);
			}));
	immutable FullIndexDict!(LowType.Record, LowRecord) allRecords =
		fullIndexDictOfArr!(LowType.Record, LowRecord)(
			map(alloc, finishArr(alloc, allRecordSources), (ref immutable Ptr!ConcreteStruct it) =>
				immutable LowRecord(
					it,
					mapPtrs(alloc, asRecord(it.body_).fields, (immutable Ptr!ConcreteField field) =>
						immutable LowField(
							field,
							lowTypeFromConcreteType(alloc, getLowTypeCtx, field.type))))));
	immutable FullIndexDict!(LowType.Union, LowUnion) allUnions =
		fullIndexDictOfArr!(LowType.Union, LowUnion)(
			map(alloc, finishArr(alloc, allUnionSources), (ref immutable Ptr!ConcreteStruct it) =>
				immutable LowUnion(
					it,
					map(alloc, asUnion(it.body_).members, (ref immutable ConcreteType member) =>
						lowTypeFromConcreteType(alloc, getLowTypeCtx, member)))));

	return AllLowTypesWithCtx(
		immutable AllLowTypes(
			fullIndexDictOfArr!(LowType.ExternPtr, LowExternPtrType)(finishArr(alloc, allExternPtrTypes)),
			allFunPtrs,
			allRecords,
			allUnions),
		getLowTypeCtx);
}

immutable(LowType) getLowPtrType(Alloc)(
	ref Alloc alloc,
	ref GetLowTypeCtx ctx,
	immutable LowType pointee,
) {
	//TODO:PERF Cache creation of pointer types by pointee
	return immutable LowType(immutable LowType.NonFunPtr(allocate(alloc, pointee)));
}

immutable(LowType) lowTypeFromConcreteStruct(Alloc)(
	ref Alloc alloc,
	ref GetLowTypeCtx ctx,
	immutable Ptr!ConcreteStruct it,
) {
	return optOr!LowType(getAt(ctx.concreteStructToType, it), () {
		immutable ConcreteStructBody.Builtin builtin = asBuiltin(body_(it));
		verify(builtin.kind == BuiltinStructKind.ptr);
		//TODO: cache the creation.. don't want an allocation for every BuiltinStructKind.ptr to the same target type
		return immutable LowType(
			immutable LowType.NonFunPtr(allocate(alloc, lowTypeFromConcreteType(alloc, ctx, only(builtin.typeArgs)))));
	});
}

immutable(LowType) lowTypeFromConcreteType(Alloc)(
	ref Alloc alloc,
	ref GetLowTypeCtx ctx,
	immutable ConcreteType it,
) {
	return it.isPointer
		? getOrAdd(alloc, ctx.concreteStructToPtrType, it.struct_, () =>
			immutable LowType(immutable LowType.NonFunPtr(
				allocate(alloc, lowTypeFromConcreteStruct(alloc, ctx, it.struct_)))))
		: lowTypeFromConcreteStruct(alloc, ctx, it.struct_);
}

struct PrimitiveTypeIndex {
	immutable size_t index; // Cast from the enum
}

struct LowFunCause {
	@safe @nogc pure nothrow:
	struct Compare {
		immutable LowType type;
		immutable Bool typeIsArr;
	}

	@trusted immutable this(immutable Compare a) { kind = Kind.compare; compare_ = a; }
	@trusted immutable this(immutable Ptr!ConcreteFun a) { kind = Kind.expr; expr_ = a; }

	private:
	enum Kind {
		compare,
		expr,
	}
	immutable Kind kind;
	union {
		immutable Compare compare_;
		immutable Ptr!ConcreteFun expr_;
	}
}

@trusted T matchLowFunCause(T)(
	ref immutable LowFunCause a,
	scope T delegate(ref immutable LowFunCause.Compare) @safe @nogc pure nothrow cbCompare,
	scope T delegate(immutable Ptr!ConcreteFun) @safe @nogc pure nothrow cbExpr,
) {
	final switch (a.kind) {
		case LowFunCause.Kind.compare:
			return cbCompare(a.compare_);
		case LowFunCause.Kind.expr:
			return cbExpr(a.expr_);
	}
}

//TODO:MOVE
immutable(size_t) sizeTOfPrimitiveType(immutable PrimitiveType a) {
	return cast(immutable size_t) a;
}

immutable(AllLowFuns) getAllLowFuns(Alloc)(
	ref Alloc alloc,
	ref immutable AllLowTypes allTypes,
	ref GetLowTypeCtx getLowTypeCtx,
	ref immutable ConcreteProgram program,
) {
	immutable LowType ctxType =
		lowTypeFromConcreteType(alloc, getLowTypeCtx, immutable ConcreteType(True, program.ctxType));
	DictBuilder!(Ptr!ConcreteFun, LowFunIndex, comparePtr!ConcreteFun) concreteFunToLowFunIndexBuilder;
	CompareFuns compareFuns = CompareFuns(
		newMutIndexDict!(immutable LowType.Record, immutable LowFunIndex)(
			alloc, fullIndexDictSize(allTypes.allRecords)),
		newMutIndexDict!(immutable LowType.Record, immutable LowFunIndex)(
			alloc, fullIndexDictSize(allTypes.allRecords)),
		newMutIndexDict!(immutable LowType.Union, immutable LowFunIndex)(
			alloc, fullIndexDictSize(allTypes.allUnions)),
		newMutIndexDict!(immutable PrimitiveTypeIndex, immutable LowFunIndex)(alloc, nPrimitiveTypes));
	ArrBuilder!LowFunCause lowFunCausesBuilder;

	Late!(immutable LowType) comparisonType = late!(immutable LowType);

	immutable(LowFunIndex) addLowFun(immutable LowFunCause source) {
		immutable LowFunIndex res = immutable LowFunIndex(arrBuilderSize(lowFunCausesBuilder));
		add(alloc, lowFunCausesBuilder, source);
		return res;
	}

	immutable(Opt!LowFunIndex) generateCompareForType(immutable LowType lowType) @safe @nogc pure nothrow {
		immutable(LowFunIndex) addIt(immutable Bool typeIsArr) {
			return addLowFun(immutable LowFunCause(immutable LowFunCause.Compare(lowType, typeIsArr)));
		}

		void generateCompareForFields(immutable LowType.Record record) {
			foreach (ref immutable LowField field; arrRange(fullIndexDictGet(allTypes.allRecords, record).fields))
				generateCompareForType(field.type);
		}

		// Then generate dependencies
		return matchLowType!(immutable Opt!LowFunIndex)(
			lowType,
			(immutable LowType.ExternPtr) =>
				none!LowFunIndex,
			(immutable LowType.FunPtr) =>
				none!LowFunIndex,
			(immutable LowType.NonFunPtr it) {
				immutable LowType.Record record = asRecordType(it.pointee);
				immutable ValueAndDidAdd!(immutable LowFunIndex) index = getOrAddAndDidAdd(
					compareFuns.recordPtrToCompare,
					record,
					() => addIt(False));
				if (index.didAdd)
					generateCompareForFields(record);
				return some(index.value);
			},
			(immutable PrimitiveType it) {
				immutable ValueAndDidAdd!(immutable LowFunIndex) index = getOrAddAndDidAdd(
					compareFuns.primitiveToCompare,
					immutable PrimitiveTypeIndex(sizeTOfPrimitiveType(it)),
					() => addIt(False));
				return some(index.value);
			},
			(immutable LowType.Record it) {
				immutable LowRecord record = fullIndexDictGet(allTypes.allRecords, it);
				immutable Bool typeIsArr = isArr(record);
				immutable ValueAndDidAdd!(immutable LowFunIndex) index = getOrAddAndDidAdd(
					compareFuns.recordValToCompare,
					it,
					() => addIt(typeIsArr));
				if (index.didAdd) {
					if (typeIsArr)
						generateCompareForType(asNonFunPtrType(at(record.fields, 1).type).pointee);
					else
						generateCompareForFields(it);
				}
				return some(index.value);
			},
			(immutable LowType.Union it) {
				immutable ValueAndDidAdd!(immutable LowFunIndex) index =
					getOrAddAndDidAdd(compareFuns.unionToCompare, it, () => addIt(False));
				if (index.didAdd)
					foreach (ref immutable LowType member; arrRange(fullIndexDictGet(allTypes.allUnions, it).members))
						generateCompareForType(member);
				return some(index.value);
			});
	}

	foreach (immutable Ptr!ConcreteFun fun; arrRange(program.allFuns)) {
		immutable Opt!LowFunIndex opIndex = matchConcreteFunBody!(immutable Opt!LowFunIndex)(
			body_(fun),
			(ref immutable ConcreteFunBody.Builtin it) {
				if (isCompareFun(fun)) {
					if (!lateIsSet(comparisonType)) {
						immutable LowType returnType = lowTypeFromConcreteType(alloc, getLowTypeCtx, fun.returnType);
						lateSet(comparisonType, returnType);
					}
					immutable Opt!LowFunIndex res = generateCompareForType(
						lowTypeFromConcreteType(alloc, getLowTypeCtx, only(it.typeArgs)));
					verify(has(res));
					return res;
				} else
					return none!LowFunIndex;
			},
			(ref immutable ConcreteFunBody.CreateRecord) =>
				none!LowFunIndex,
			(ref immutable ConcreteFunBody.Extern) =>
				some(addLowFun(immutable LowFunCause(fun))),
			(ref immutable ConcreteFunExprBody) =>
				some(addLowFun(immutable LowFunCause(fun))),
			(ref immutable ConcreteFunBody.RecordFieldGet) =>
				none!LowFunIndex,
			(ref immutable ConcreteFunBody.RecordFieldSet) =>
				none!LowFunIndex);
		if (has(opIndex)) {
			addToDict(alloc, concreteFunToLowFunIndexBuilder, fun, force(opIndex));
		}
	}

	immutable ComparisonTypes comparisonTypes = getComparisonTypes(allTypes, lateGet(comparisonType));

	immutable Arr!LowFunCause lowFunCauses = finishArr(alloc, lowFunCausesBuilder);
	immutable ConcreteFunToLowFunIndex concreteFunToLowFunIndex =
		finishDictShouldBeNoConflict(alloc, concreteFunToLowFunIndexBuilder);

	immutable LowType userMainFunPtrType =
		lowTypeFromConcreteType(alloc, getLowTypeCtx, at(program.rtMain.paramsExcludingCtxAndClosure, 2).type);

	immutable LowFunIndex allocFunIndex = mustGetAt(concreteFunToLowFunIndex, program.allocFun);
	immutable FullIndexDict!(LowFunIndex, LowFun) allLowFuns = fullIndexDictOfArr!(LowFunIndex, LowFun)(
		mapWithIndexAndConcatOne(
			alloc,
			lowFunCauses,
			(immutable size_t index, ref immutable LowFunCause cause) =>
				lowFunFromCause(
					alloc,
					allTypes,
					getLowTypeCtx,
					allocFunIndex,
					ctxType,
					concreteFunToLowFunIndex,
					compareFuns,
					comparisonTypes,
					immutable LowFunIndex(index),
					cause),
			mainFun(
				alloc,
				getLowTypeCtx,
				mustGetAt(concreteFunToLowFunIndex, program.rtMain),
				mustGetAt(concreteFunToLowFunIndex, program.userMain),
				userMainFunPtrType)));

	return immutable AllLowFuns(allLowFuns, immutable LowFunIndex(size(lowFunCauses)));
}

immutable(LowFun) lowFunFromCause(Alloc)(
	ref Alloc alloc,
	ref immutable AllLowTypes allTypes,
	ref GetLowTypeCtx getLowTypeCtx,
	immutable LowFunIndex allocFunIndex,
	ref immutable LowType ctxType,
	ref immutable ConcreteFunToLowFunIndex concreteFunToLowFunIndex,
	ref const CompareFuns compareFuns,
	ref immutable ComparisonTypes comparisonTypes,
	immutable LowFunIndex thisFunIndex,
	ref immutable LowFunCause cause,
) {
	return matchLowFunCause!(immutable LowFun)(
		cause,
		(ref immutable LowFunCause.Compare it) =>
			generateCompareFun(
				alloc,
				allTypes,
				comparisonTypes,
				compareFuns,
				it.type,
				it.typeIsArr),
		(immutable Ptr!ConcreteFun cf) {
			immutable LowType returnType = lowTypeFromConcreteType(alloc, getLowTypeCtx, cf.returnType);
			immutable Opt!LowParam ctxParam = cf.needsCtx
				? some(immutable LowParam(
					immutable LowParamSource(immutable LowParamSource.Generated(shortSymAlphaLiteral("ctx"))),
					ctxType))
				: none!LowParam;
			immutable Opt!LowParam closureParam = mapOption(
				ptrTrustMe(cf.closureParam),
				(ref immutable Ptr!ConcreteParam it) =>
					getLowParam(alloc, getLowTypeCtx, it));
			immutable Arr!LowParam params = mapWithOptFirst2!(LowParam, ConcreteParam, Alloc)(
				alloc,
				ctxParam,
				closureParam,
				cf.paramsExcludingCtxAndClosure,
				(immutable Ptr!ConcreteParam it) =>
					getLowParam(alloc, getLowTypeCtx, it));
			immutable Opt!LowParamIndex ctxParamIndex = has(ctxParam)
				? some(immutable LowParamIndex(0))
				: none!LowParamIndex;
			immutable Opt!LowParamIndex closureParamIndex = has(cf.closureParam)
				? some(immutable LowParamIndex(cf.needsCtx ? 1 : 0))
				: none!LowParamIndex;
			immutable Ptr!LowFunSig sig = nu!LowFunSig(
				alloc,
				returnType,
				immutable LowFunParamsKind(has(ctxParam), has(closureParam)),
				params);
			immutable LowFunBody body_ = getLowFunBody!Alloc(
				alloc,
				allTypes,
				getLowTypeCtx,
				concreteFunToLowFunIndex,
				allocFunIndex,
				ctxType,
				ctxParamIndex,
				closureParamIndex,
				immutable LowParamIndex((has(ctxParamIndex) ? 1 : 0) + (has(closureParamIndex) ? 1 : 0)),
				thisFunIndex,
				sig,
				cf,
				body_(cf));
			return immutable LowFun(immutable LowFunSource(cf), sig, body_);
		});
}

immutable(ComparisonTypes) getComparisonTypes(
	ref immutable AllLowTypes allTypes,
	immutable LowType comparisonType,
) {
	immutable LowType.Union comparison = asUnionType(comparisonType);
	immutable Arr!LowType members = fullIndexDictGet(allTypes.allUnions, comparison).members;
	immutable(LowType.Record) getMember(immutable size_t index) {
		return asRecordType(at(members, index));
	}
	return immutable ComparisonTypes(comparison, getMember(0), getMember(1), getMember(2));
}

immutable(LowFun) mainFun(Alloc)(
	ref Alloc alloc,
	ref const GetLowTypeCtx ctx,
	immutable LowFunIndex rtMainIndex,
	immutable LowFunIndex userMainIndex,
	ref immutable LowType userMainFunPtrType,
) {
	immutable Arr!LowParam params = arrLiteral!LowParam(alloc, [
		immutable LowParam(
			immutable LowParamSource(immutable LowParamSource.Generated(shortSymAlphaLiteral("argc"))),
			int32Type),
		immutable LowParam(
			immutable LowParamSource(immutable LowParamSource.Generated(shortSymAlphaLiteral("argv"))),
			charPtrPtrType)]);
	immutable LowParamIndex argc = immutable LowParamIndex(0);
	immutable LowParamIndex argv = immutable LowParamIndex(1);
	immutable LowExpr userMainFunPtr = immutable LowExpr(
		userMainFunPtrType,
		FileAndRange.empty,
		immutable LowExprKind(immutable LowExprKind.FunPtr(userMainIndex)));
	immutable LowExpr call = immutable LowExpr(
		int32Type,
		FileAndRange.empty,
		immutable LowExprKind(immutable LowExprKind.Call(
			rtMainIndex,
			arrLiteral!LowExpr(alloc, [
				paramRef(FileAndRange.empty, int32Type, argc),
				paramRef(FileAndRange.empty, charPtrPtrType, argv),
				userMainFunPtr]))));
	immutable LowFunBody body_ = immutable LowFunBody(immutable LowFunExprBody(False, allocate(alloc, call)));
	return immutable LowFun(
		immutable LowFunSource(nu!(LowFunSource.Generated)(
			alloc,
			shortSymAlphaLiteral("main"),
			none!LowType)),
		nu!LowFunSig(
			alloc,
			int32Type,
			immutable LowFunParamsKind(False, False),
			params),
		body_);
}

immutable(LowParam) getLowParam(Alloc)(ref Alloc alloc, ref GetLowTypeCtx ctx, immutable Ptr!ConcreteParam a) {
	return immutable LowParam(immutable LowParamSource(a), lowTypeFromConcreteType(alloc, ctx, a.type));
}

immutable(T) withLowLocal(T, Alloc)(
	ref Alloc alloc,
	ref GetLowExprCtx ctx,
	immutable Ptr!ConcreteLocal concreteLocal,
	scope immutable(T) delegate(immutable Ptr!LowLocal) @safe @nogc pure nothrow cb,
) {
	immutable Ptr!LowLocal local = nu!LowLocal(
		alloc,
		immutable LowLocalSource(concreteLocal),
		lowTypeFromConcreteType(alloc, ctx.getLowTypeCtx, concreteLocal.type));
	//TODO: store lookup on stack instead of using dict
	addToMutDict(alloc, ctx.locals, concreteLocal, local);
	immutable T res = cb(local);
	mustDelete(ctx.locals, concreteLocal);
	return res;
}

immutable(T) withOptLowLocal(T, Alloc)(
	ref Alloc alloc,
	ref GetLowExprCtx ctx,
	immutable Opt!(Ptr!ConcreteLocal) concreteLocal,
	scope immutable(T) delegate(immutable Opt!(Ptr!LowLocal)) @safe @nogc pure nothrow cb,
) {
	return has(concreteLocal)
		? withLowLocal!(T, Alloc)(alloc, ctx, force(concreteLocal), (immutable Ptr!LowLocal local) => cb(some(local)))
		: cb(none!(Ptr!LowLocal));
}

alias ConcreteFunToLowFunIndex = immutable Dict!(Ptr!ConcreteFun, LowFunIndex, comparePtr!ConcreteFun);

immutable(LowFunBody) getLowFunBody(Alloc)(
	ref Alloc alloc,
	ref immutable AllLowTypes allTypes,
	ref GetLowTypeCtx getLowTypeCtx,
	ref immutable ConcreteFunToLowFunIndex concreteFunToLowFunIndex,
	immutable LowFunIndex allocFunIndex,
	immutable LowType ctxType,
	immutable Opt!LowParamIndex ctxParam,
	immutable Opt!LowParamIndex closureParam,
	immutable LowParamIndex firstRegularParam,
	immutable LowFunIndex thisFunIndex,
	ref immutable LowFunSig sig,
	ref immutable ConcreteFun cf,
	ref immutable ConcreteFunBody a,
) {
	return matchConcreteFunBody!(immutable LowFunBody)(
		a,
		(ref immutable ConcreteFunBody.Builtin it) =>
			unreachable!(immutable LowFunBody), // compare funs have a different code path
		(ref immutable ConcreteFunBody.CreateRecord) =>
			unreachable!(immutable LowFunBody),
		(ref immutable ConcreteFunBody.Extern it) =>
			immutable LowFunBody(nu!(LowFunBody.Extern)(alloc, it.isGlobal, it.externName)),
		(ref immutable ConcreteFunExprBody it) {
			GetLowExprCtx exprCtx = GetLowExprCtx(
				thisFunIndex,
				ptrTrustMe(allTypes),
				ptrTrustMe_mut(getLowTypeCtx),
				concreteFunToLowFunIndex,
				allocFunIndex,
				ctxType,
				ctxParam,
				closureParam,
				firstRegularParam,
				False);
			immutable LowExpr expr = getLowExpr(alloc, exprCtx, it.expr, ExprPos.tail);
			return immutable LowFunBody(
				immutable LowFunExprBody(
					exprCtx.hasTailRecur,
					allocate(alloc, expr)));
		},
		(ref immutable ConcreteFunBody.RecordFieldGet) =>
			unreachable!(immutable LowFunBody),
		(ref immutable ConcreteFunBody.RecordFieldSet) =>
			unreachable!(immutable LowFunBody));
}

struct GetLowExprCtx {
	immutable LowFunIndex currentFun;
	immutable Ptr!AllLowTypes allTypes;
	Ptr!GetLowTypeCtx getLowTypeCtx;
	ConcreteFunToLowFunIndex concreteFunToLowFunIndex;
	immutable LowFunIndex allocFunIndex;
	immutable LowType ctxType;
	immutable Opt!LowParamIndex ctxParam;
	immutable Opt!LowParamIndex closureParam;
	immutable LowParamIndex firstRegularParam;
	Bool hasTailRecur;
	size_t tempLocalIndex;
	MutDict!(immutable Ptr!ConcreteLocal, immutable Ptr!LowLocal, comparePtr!ConcreteLocal) locals;
}

//TODO:KILL (inline)
ref GetLowTypeCtx typeCtx(return scope ref GetLowExprCtx ctx) {
	return ctx.getLowTypeCtx;
}

immutable(LowExpr) getCtxParamRef(Alloc)(
	ref Alloc alloc,
	ref const GetLowExprCtx ctx,
	ref immutable FileAndRange range,
) {
	return paramRef(range, ctx.ctxType, force(ctx.ctxParam));
}

immutable(LowFunIndex) getLowFunIndex(ref const GetLowExprCtx ctx, immutable Ptr!ConcreteFun it) {
	immutable Opt!LowFunIndex op = tryGetLowFunIndex(ctx, it);
	return force(op);
}

immutable(Opt!LowFunIndex) tryGetLowFunIndex(ref const GetLowExprCtx ctx, immutable Ptr!ConcreteFun it) {
	return getAt(ctx.concreteFunToLowFunIndex, it);
}

immutable(Ptr!LowLocal) addTempLocal(Alloc)(ref Alloc alloc, ref GetLowExprCtx ctx, ref immutable LowType type) {
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

immutable(LowExpr) getLowExpr(Alloc)(
	ref Alloc alloc,
	ref GetLowExprCtx ctx,
	ref immutable ConcreteExpr expr,
	immutable ExprPos exprPos,
) {
	immutable LowType type = lowTypeFromConcreteType(alloc, typeCtx(ctx), expr.type);
	return immutable LowExpr(type, expr.range, getLowExprKind(alloc, ctx, type, expr, exprPos));
}

immutable(LowExprKind) getLowExprKind(Alloc)(
	ref Alloc alloc,
	ref GetLowExprCtx ctx,
	ref immutable LowType type,
	ref immutable ConcreteExpr expr,
	immutable ExprPos exprPos,
) {
	return matchConcreteExprKind!(immutable LowExprKind)(
		expr.kind,
		(ref immutable ConcreteExprKind.Alloc it) =>
			getAllocExpr(alloc, ctx, expr.range, it),
		(ref immutable ConcreteExprKind.Call it) =>
			getCallExpr(alloc, ctx, exprPos, expr.range, type, it),
		(ref immutable ConcreteExprKind.Cond it) =>
			immutable LowExprKind(nu!(LowExprKind.SpecialTrinary)(
				alloc,
				LowExprKind.SpecialTrinary.Kind.if_,
				allocate(alloc, getLowExpr(alloc, ctx, it.cond, ExprPos.nonTail)),
				allocate(alloc, getLowExpr(alloc, ctx, it.then, exprPos)),
				allocate(alloc, getLowExpr(alloc, ctx, it.else_, exprPos)))),
		(ref immutable Constant it) =>
			immutable LowExprKind(it),
		(ref immutable ConcreteExprKind.CreateArr it) =>
			getCreateArrExpr(alloc, ctx, expr.range, it),
		(ref immutable ConcreteExprKind.CreateRecord it) =>
			immutable LowExprKind(immutable LowExprKind.CreateRecord(
				getArgs(alloc, ctx, it.args))),
		(ref immutable ConcreteExprKind.ConvertToUnion it) =>
			immutable LowExprKind(immutable LowExprKind.ConvertToUnion(
				it.memberIndex,
				allocate(alloc, getLowExpr(alloc, ctx, it.arg, ExprPos.nonTail)))),
		(ref immutable ConcreteExprKind.Lambda it) =>
			getLambdaExpr(alloc, ctx, type, expr.range, it),
		(ref immutable ConcreteExprKind.Let it) =>
			getLetExpr(alloc, ctx, exprPos, expr.range, it),
		(ref immutable ConcreteExprKind.LocalRef it) =>
			immutable LowExprKind(immutable LowExprKind.LocalRef(mustGetAt_mut(ctx.locals, it.local))),
		(ref immutable ConcreteExprKind.Match it) =>
			getMatchExpr(alloc, ctx, exprPos, it),
		(ref immutable ConcreteExprKind.ParamRef it) =>
			getParamRefExpr(alloc, ctx, it),
		(ref immutable ConcreteExprKind.RecordFieldGet it) =>
			getRecordFieldGetExpr(alloc, ctx, it),
		(ref immutable ConcreteExprKind.Seq it) =>
			immutable LowExprKind(immutable LowExprKind.Seq(
				allocate(alloc, getLowExpr(alloc, ctx, it.first, ExprPos.nonTail)),
				allocate(alloc, getLowExpr(alloc, ctx, it.then, exprPos)))));
}

immutable(LowExpr) getAllocateExpr(Alloc)(
	ref Alloc alloc,
	immutable LowFunIndex allocFunIndex,
	ref immutable LowType ctxType,
	immutable LowParamIndex ctxParam,
	ref immutable FileAndRange range,
	ref immutable LowType ptrType,
	ref immutable LowExpr size,
) {
	immutable LowExpr allocate = immutable LowExpr(
		anyPtrType,
		range,
		immutable LowExprKind(immutable LowExprKind.Call(
			allocFunIndex,
			arrLiteral!LowExpr(alloc, [paramRef(range, ctxType, ctxParam), size]))));
	return ptrCast(alloc, ptrType, range, allocate);
}

immutable(LowExprKind) getAllocExpr(Alloc)(
	ref Alloc alloc,
	ref GetLowExprCtx ctx,
	ref immutable FileAndRange range,
	ref immutable ConcreteExprKind.Alloc a,
) {
	// (temp0 = (T*) alloc(sizeof(T)), *temp0 = inner, temp0)
	immutable LowExpr inner = getLowExpr(alloc, ctx, a.inner, ExprPos.nonTail);
	immutable LowType ptrType = getLowPtrType(alloc, typeCtx(ctx), inner.type);
	return getAllocExpr2(alloc, ctx, range, inner, ptrType);
}

immutable(LowExprKind) getAllocExpr2(Alloc)(
	ref Alloc alloc,
	ref GetLowExprCtx ctx,
	ref immutable FileAndRange range,
	ref immutable LowExpr inner,
	ref immutable LowType ptrType,
) {
	immutable Ptr!LowLocal local = addTempLocal(alloc, ctx, ptrType);
	immutable LowExpr sizeofT = getSizeOf(range, asNonFunPtrType(ptrType).pointee);
	immutable LowExpr allocatePtr =
		getAllocateExpr!Alloc(alloc, ctx.allocFunIndex, ctx.ctxType, force(ctx.ctxParam), range, ptrType, sizeofT);
	immutable Ptr!LowExpr getTemp = allocate(alloc, localRef(alloc, range, local));
	immutable LowExpr setTemp = writeToPtr(alloc, range, getTemp, inner);
	return immutable LowExprKind(immutable LowExprKind.Let(
		local,
		allocate(alloc, allocatePtr),
		allocate(alloc, seq(alloc, range, setTemp, getTemp))));
}

immutable(LowExprKind) getCallExpr(Alloc)(
	ref Alloc alloc,
	ref GetLowExprCtx ctx,
	immutable ExprPos exprPos,
	ref immutable FileAndRange range,
	ref immutable LowType type,
	ref immutable ConcreteExprKind.Call a,
) {
	immutable Opt!LowFunIndex opCalled = tryGetLowFunIndex(ctx, a.called);
	if (has(opCalled)) {
		immutable Bool isTailRecur = force(opCalled) == ctx.currentFun && exprPos == ExprPos.tail;
		if (isTailRecur) ctx.hasTailRecur = True;
		immutable Opt!LowExpr ctxArg = !isTailRecur && a.called.needsCtx
			? some(getCtxParamRef(alloc, ctx, range))
			: none!LowExpr;
		immutable Arr!LowExpr args = mapWithOptFirst(alloc, ctxArg, a.args, (immutable Ptr!ConcreteExpr it) =>
			getLowExpr(alloc, ctx, it, ExprPos.nonTail));
		return isTailRecur
			? immutable LowExprKind(immutable LowExprKind.TailRecur(args))
			: immutable LowExprKind(immutable LowExprKind.Call(force(opCalled), args));
	} else
		return matchConcreteFunBody!(immutable LowExprKind)(
			body_(a.called),
			(ref immutable ConcreteFunBody.Builtin) {
				return getCallBuiltinExpr(alloc, ctx, exprPos, range, type, a);
			},
			(ref immutable ConcreteFunBody.CreateRecord) {
				immutable Arr!LowExpr args = getArgs(alloc, ctx, a.args);
				immutable LowExprKind create = immutable LowExprKind(immutable LowExprKind.CreateRecord(args));
				if (isNonFunPtrType(type)) {
					immutable LowExpr inner = immutable LowExpr(asNonFunPtrType(type).pointee, range, create);
					return getAllocExpr2!Alloc(alloc, ctx, range, inner, type);
				} else
					return create;
			},
			(ref immutable ConcreteFunBody.Extern) =>
				unreachable!(immutable LowExprKind),
			(ref immutable ConcreteFunExprBody) =>
				unreachable!(immutable LowExprKind),
			(ref immutable ConcreteFunBody.RecordFieldGet it) =>
				immutable LowExprKind(immutable LowExprKind.RecordFieldGet(
					allocate(alloc, getLowExpr(alloc, ctx, only(a.args), ExprPos.nonTail)),
					it.fieldIndex)),
			(ref immutable ConcreteFunBody.RecordFieldSet it) {
				verify(size(a.args) == 2);
				return immutable LowExprKind(immutable LowExprKind.RecordFieldSet(
					allocate(alloc, getLowExpr(alloc, ctx, at(a.args, 0), ExprPos.nonTail)),
					it.fieldIndex,
					allocate(alloc, getLowExpr(alloc, ctx, at(a.args, 1), ExprPos.nonTail))));
			});
}

immutable(Arr!LowExpr) getArgs(Alloc)(
	ref Alloc alloc,
	ref GetLowExprCtx ctx,
	ref immutable Arr!ConcreteExpr args,
) {
	return map(alloc, args, (ref immutable ConcreteExpr arg) =>
		getLowExpr(alloc, ctx, arg, ExprPos.nonTail));
}

immutable(LowExprKind) getCallBuiltinExpr(Alloc)(
	ref Alloc alloc,
	ref GetLowExprCtx ctx,
	immutable ExprPos exprPos,
	ref immutable FileAndRange range,
	ref immutable LowType type,
	ref immutable ConcreteExprKind.Call a,
) {
	immutable Sym name = matchConcreteFunSource!(immutable Sym)(
		a.called.source,
		(immutable Ptr!FunInst it) =>
			name(decl(it).deref()),
		(ref immutable ConcreteFunSource.Lambda) =>
			unreachable!(immutable Sym)());
	immutable(LowType) paramType(immutable size_t index) {
		return index < size(a.args)
			? lowTypeFromConcreteType(
				alloc,
				ctx.getLowTypeCtx,
				at(a.called.paramsExcludingCtxAndClosure, index).type)
			: voidType;
	}
	immutable LowType p0 = paramType(0);
	immutable LowType p1 = paramType(1);
	immutable BuiltinKind builtinKind = getBuiltinKind(name, type, p0, p1);
	immutable(Ptr!LowExpr) getArg(ref immutable ConcreteExpr arg, immutable ExprPos argPos) {
		return allocate(alloc, getLowExpr(alloc, ctx, arg, argPos));
	}
	return matchBuiltinKind!(immutable LowExprKind)(
		builtinKind,
		(ref immutable BuiltinKind.As) =>
			getLowExpr(alloc, ctx, at(a.args, 0), exprPos).kind,
		(ref immutable BuiltinKind.GetCtx) =>
			immutable LowExprKind(immutable LowExprKind.ParamRef(force(ctx.ctxParam))),
		(ref immutable Constant it) =>
			immutable LowExprKind(it),
		(immutable LowExprKind.SpecialUnary.Kind kind) {
			verify(size(a.args) == 1);
			return immutable LowExprKind(
				immutable LowExprKind.SpecialUnary(kind, getArg(at(a.args, 0), ExprPos.nonTail)));
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
			return immutable LowExprKind(immutable LowExprKind.SpecialBinary(
				kind,
				getArg(at(a.args, 0), ExprPos.nonTail),
				getArg(at(a.args, 1), arg1Pos)));
		},
		(immutable LowExprKind.SpecialTrinary.Kind kind) {
			verify(size(a.args) == 3);
			immutable ExprPos arg12Pos = () {
				switch (kind) {
					case LowExprKind.SpecialTrinary.Kind.if_:
						return exprPos;
					default:
						return ExprPos.nonTail;
				}
			}();
			return immutable LowExprKind(nu!(LowExprKind.SpecialTrinary)(
				alloc,
				kind,
				getArg(at(a.args, 0), ExprPos.nonTail),
				getArg(at(a.args, 1), arg12Pos),
				getArg(at(a.args, 2), arg12Pos)));
		},
		(immutable LowExprKind.SpecialNAry.Kind kind) =>
			immutable LowExprKind(immutable LowExprKind.SpecialNAry(kind, getArgs(alloc, ctx, a.args))),
		(ref immutable BuiltinKind.PtrCast) {
			verify(size(a.args) == 1);
			return ptrCastKind(alloc, getLowExpr(alloc, ctx, only(a.args), ExprPos.nonTail));
		},
		(ref immutable BuiltinKind.SizeOf) {
			immutable LowType typeArg =
				lowTypeFromConcreteType(alloc, ctx.getLowTypeCtx, only(asBuiltin(body_(a.called)).typeArgs));
			return immutable LowExprKind(immutable LowExprKind.SizeOf(typeArg));
		});
}

immutable(LowExprKind) getCreateArrExpr(Alloc)(
	ref Alloc alloc,
	ref GetLowExprCtx ctx,
	ref immutable FileAndRange range,
	ref immutable ConcreteExprKind.CreateArr a,
) {
	// (temp = _alloc(ctx, sizeof(foo) * 2),
	//  *(temp + 0) = a,
	//  *(temp + 1) = b,
	//  arr_foo{2, temp})
	immutable LowType arrType = lowTypeFromConcreteStruct(alloc, typeCtx(ctx), a.arrType);
	immutable LowType elementType = lowTypeFromConcreteType(alloc, typeCtx(ctx), a.elementType);
	immutable LowType elementPtrType = getLowPtrType(alloc, typeCtx(ctx), elementType);
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
			immutable LowExpr elementPtr = addPtr(alloc, elementPtrType, range, getTemp, index);
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
	return immutable LowExprKind(immutable LowExprKind.Let(
		temp,
		allocate(alloc, allocatePtr),
		allocate(alloc, writeAndGetArr)));
}

immutable(LowExprKind) getLambdaExpr(Alloc)(
	ref Alloc alloc,
	ref GetLowExprCtx ctx,
	ref immutable LowType type,
	ref immutable FileAndRange range,
	ref immutable ConcreteExprKind.Lambda a,
) {
	immutable LowFunIndex lambdaFun = getLowFunIndex(ctx, a.fun);
	immutable LowExprKind funPtr = immutable LowExprKind(immutable LowExprKind.FunPtr(lambdaFun));
	if (!has(a.closure))
		return funPtr;
	else {
		immutable LowType.Record recordType = asRecordType(type);
		immutable LowRecord record = fullIndexDictGet(ctx.allTypes.allRecords, recordType);
		verify(size(record.fields) == 2);
		immutable LowType funPtrType = immutable LowType(asFunPtrType(at(record.fields, 0).type));
		immutable LowExpr closure =
			ptrCast(alloc, anyPtrType, range, getLowExpr(alloc, ctx, force(a.closure), ExprPos.nonTail));
		immutable LowExpr funPtrCasted = ptrCast(
			alloc,
			funPtrType,
			range,
			immutable LowExpr(funPtrType, range, funPtr));
		immutable Arr!LowExpr args = arrLiteral!LowExpr(alloc, [funPtrCasted, closure]);
		return immutable LowExprKind(immutable LowExprKind.CreateRecord(args));
	}
}

immutable(LowExprKind) getLetExpr(Alloc)(
	ref Alloc alloc,
	ref GetLowExprCtx ctx,
	immutable ExprPos exprPos,
	ref immutable FileAndRange range,
	ref immutable ConcreteExprKind.Let a,
) {
	return withLowLocal!LowExprKind(alloc, ctx, a.local, (immutable Ptr!LowLocal local) =>
		immutable LowExprKind(immutable LowExprKind.Let(
			local,
			allocate(alloc, getLowExpr(alloc, ctx, a.value, ExprPos.nonTail)),
			allocate(alloc, getLowExpr(alloc, ctx, a.then, exprPos)))));
}

immutable(LowExprKind) getMatchExpr(Alloc)(
	ref Alloc alloc,
	ref GetLowExprCtx ctx,
	immutable ExprPos exprPos,
	ref immutable ConcreteExprKind.Match a,
) {
	immutable Ptr!LowExpr matched = allocate(alloc, getLowExpr(alloc, ctx, a.matchedValue, ExprPos.nonTail));
	return immutable LowExprKind(nu!(LowExprKind.Match)(
		alloc,
		addTempLocal(alloc, ctx, matched.type),
		matched,
		map(alloc, a.cases, (ref immutable ConcreteExprKind.Match.Case case_) =>
			withOptLowLocal(alloc, ctx, case_.local, (immutable Opt!(Ptr!LowLocal) local) =>
				immutable LowExprKind.Match.Case(
					local,
					getLowExpr(alloc, ctx, case_.then, exprPos))))));
}

immutable(LowExprKind) getParamRefExpr(Alloc)(
	ref Alloc alloc,
	ref GetLowExprCtx ctx,
	ref immutable ConcreteExprKind.ParamRef a,
) {
	if (!has(a.param.index)) {
		//TODO: don't generate ParamRef in ConcreteModel for closure field access. Do that in lowering.
		verify(isClosure(a.param.source));
		return immutable LowExprKind(immutable LowExprKind.ParamRef(force(ctx.closureParam)));
	}

	immutable LowParamIndex param = immutable LowParamIndex(ctx.firstRegularParam.index + force(a.param.index));
	return immutable LowExprKind(immutable LowExprKind.ParamRef(param));
}

immutable(LowExprKind) getRecordFieldGetExpr(Alloc)(
	ref Alloc alloc,
	ref GetLowExprCtx ctx,
	ref immutable ConcreteExprKind.RecordFieldGet a,
) {
	return immutable LowExprKind(immutable LowExprKind.RecordFieldGet(
		allocate(alloc, getLowExpr(alloc, ctx, a.target, ExprPos.nonTail)),
		a.field.index));
}
