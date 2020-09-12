module lower.lower;

@safe @nogc pure nothrow:

import concreteModel :
	asBuiltin,
	body_,
	BuiltinFunEmit,
	BuiltinFunKind,
	BuiltinStructKind,
	ConcreteExpr,
	ConcreteField,
	ConcreteFun,
	ConcreteFunBody,
	ConcreteFunExprBody,
	ConcreteLocal,
	ConcreteParam,
	ConcreteProgram,
	ConcreteStruct,
	ConcreteStructBody,
	ConcreteType,
	matchConcreteExpr,
	matchConcreteFunBody,
	matchConcreteStructBody;
import lower.checkLowModel : checkLowProgram;
import lower.generateCompareFun : ComparisonTypes, generateCompareFun;
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
	wrapMulNat64,
	writeToPtr;
import lowModel :
	asFunPtrType,
	asNonFunPtrType,
	asRecordType,
	asUnionType,
	isNonFunPtrType,
	LowExpr,
	LowExprKind,
	LowExternPtrType,
	LowField,
	LowFun,
	LowFunBody,
	LowFunExprBody,
	LowFunIndex,
	LowFunPtrType,
	LowLocal,
	LowParam,
	LowProgram,
	LowRecord,
	LowType,
	LowUnion,
	matchLowType,
	nPrimitiveTypes,
	PrimitiveType;
import util.alloc.stackAlloc : StackAlloc;
import util.bools : Bool, False, True;
import util.collection.arr : Arr, at, empty, emptyArr, first, only, ptrAt, arrRange = range, size;
import util.collection.arrBuilder : add, ArrBuilder, arrBuilderAt, arrBuilderSize, finishArr;
import util.collection.arrUtil : arrLiteral, map, mapOp, mapWithIndex, mapWithOptFirst, mapWithOptFirst2, slice, tail;
import util.collection.dict : Dict, getAt, mustGetAt;
import util.collection.dictBuilder : addToDict, DictBuilder, finishDictShouldBeNoConflict;
import util.collection.mutIndexDict : getOrAddAndDidAdd, mustGetAt, MutIndexDict, newMutIndexDict;
import util.collection.mutDict : getOrAdd, MutDict, ValueAndDidAdd;
import util.collection.str : Str, strEq, strEqLiteral, strLiteral;
import util.late : Late, late, lateGet, lateIsSet, lateSet;
import util.memory : allocate;
import util.opt : force, has, mapOption, none, Opt, optOr, some;
import util.ptr : comparePtr, Ptr, ptrTrustMe, ptrTrustMe_mut;
import util.sourceRange : SourceRange;
import util.util : todo, unreachable;
import util.writer : finishWriter, writeNat, Writer, writeStatic;

immutable(LowProgram) lower(Alloc)(ref Alloc alloc, ref immutable ConcreteProgram a) {
	AllLowTypesWithCtx allTypes = getAllLowTypes(alloc, a.allStructs);
	immutable AllLowFuns allFuns = getAllLowFuns!Alloc(
		alloc,
		allTypes.allTypes,
		allTypes.getLowTypeCtx,
		a);
	immutable LowProgram res = immutable LowProgram(
		allTypes.allTypes.allExternPtrTypes,
		allTypes.allTypes.allFunPtrTypes,
		allTypes.allTypes.allRecords,
		allTypes.allTypes.allUnions,
		allFuns.allLowFuns,
		allFuns.main);
	checkLowProgram(res);
	return res;
}

struct AllLowTypes {
	immutable Arr!LowExternPtrType allExternPtrTypes;
	immutable Arr!LowFunPtrType allFunPtrTypes;
	immutable Arr!LowRecord allRecords;
	immutable Arr!LowUnion allUnions;
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

immutable(LowFunIndex) getCompareFun(ref const CompareFuns compareFuns, ref immutable LowType type) {
	return matchLowType!(immutable LowFunIndex)(
		type,
		(immutable LowType.ExternPtr) => unreachable!(immutable LowFunIndex),
		(immutable LowType.FunPtr) => unreachable!(immutable LowFunIndex),
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

struct AllLowFuns {
	immutable Arr!LowFun allLowFuns; // Does not include main
	immutable LowFun main;
}

struct GetLowTypeCtx {
	immutable Dict!(Ptr!ConcreteStruct, LowType, comparePtr!ConcreteStruct) concreteStructToType;
	MutDict!(immutable Ptr!ConcreteStruct, immutable LowType, comparePtr!ConcreteStruct) concreteStructToPtrType;
}

struct FunPtrSource {
	immutable Str mangledName;
	immutable Ptr!(ConcreteStructBody.Builtin) body_;
}

struct RecordSource {
	immutable Str mangledName;
	immutable Ptr!(ConcreteStructBody.Record) body_;
}

struct UnionSource {
	immutable Str mangledName;
	immutable Ptr!(ConcreteStructBody.Union) body_;
}

AllLowTypesWithCtx getAllLowTypes(Alloc)(ref Alloc alloc, ref immutable Arr!(Ptr!ConcreteStruct) allStructs) {
	DictBuilder!(Ptr!ConcreteStruct, LowType, comparePtr!ConcreteStruct) concreteStructToTypeBuilder;
	ArrBuilder!FunPtrSource allFunPtrSources;
	ArrBuilder!LowExternPtrType allExternPtrTypes;
	ArrBuilder!RecordSource allRecordSources;
	ArrBuilder!UnionSource allUnionSources;

	foreach (immutable Ptr!ConcreteStruct s; arrRange(allStructs)) {
		immutable Opt!LowType lowType = matchConcreteStructBody!(immutable Opt!LowType)(
			body_(s),
			(ref immutable ConcreteStructBody.Builtin it) {
				final switch (it.info.kind) {
					case BuiltinStructKind.bool_:
						return some(immutable LowType(PrimitiveType.bool_));
					case BuiltinStructKind.char_:
						return some(immutable LowType(PrimitiveType.char_));
					case BuiltinStructKind.float64:
						return some(immutable LowType(PrimitiveType.float64));
					case BuiltinStructKind.funPtrN:
						immutable size_t i = arrBuilderSize(allFunPtrSources);
						add(alloc, allFunPtrSources, immutable FunPtrSource(s.mangledName, ptrTrustMe(it)));
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
				add(alloc, allExternPtrTypes, immutable LowExternPtrType(s.mangledName));
				return some(immutable LowType(immutable LowType.ExternPtr(i)));
			},
			(ref immutable ConcreteStructBody.Record it) {
				immutable size_t i = arrBuilderSize(allRecordSources);
				add(alloc, allRecordSources, immutable RecordSource(s.mangledName, ptrTrustMe(it)));
				return some(immutable LowType(immutable LowType.Record(i)));
			},
			(ref immutable ConcreteStructBody.Union it) {
				immutable size_t i = arrBuilderSize(allUnionSources);
				add(alloc, allUnionSources, immutable UnionSource(s.mangledName, ptrTrustMe(it)));
				return some(immutable LowType(immutable LowType.Union(i)));
			});
		if (has(lowType))
			addToDict(alloc, concreteStructToTypeBuilder, s, force(lowType));
	}

	GetLowTypeCtx getLowTypeCtx = GetLowTypeCtx(finishDictShouldBeNoConflict(alloc, concreteStructToTypeBuilder));

	immutable Arr!(LowFunPtrType) allFunPtrs =
		map(alloc, finishArr(alloc, allFunPtrSources), (ref immutable FunPtrSource it) {
			immutable LowType returnType = lowTypeFromConcreteType(alloc, getLowTypeCtx, first(it.body_.typeArgs));
			immutable Arr!LowType paramTypes =
				map(alloc, tail(it.body_.typeArgs), (ref immutable ConcreteType typeArg) =>
					lowTypeFromConcreteType(alloc, getLowTypeCtx, typeArg));
			return immutable LowFunPtrType(it.mangledName, returnType, paramTypes);
		});
	immutable Arr!LowRecord allRecords =
		map(alloc, finishArr(alloc, allRecordSources), (ref immutable RecordSource it) =>
			immutable LowRecord(it.mangledName, map(alloc, it.body_.fields, (ref immutable ConcreteField field) =>
				immutable LowField(field.mangledName, lowTypeFromConcreteType(alloc, getLowTypeCtx, field.type)))));
	immutable Arr!LowUnion allUnions =
		map(alloc, finishArr(alloc, allUnionSources), (ref immutable UnionSource it) =>
			immutable LowUnion(it.mangledName, map(alloc, it.body_.members, (ref immutable ConcreteType member) =>
				lowTypeFromConcreteType(alloc, getLowTypeCtx, member))));

	return AllLowTypesWithCtx(
		immutable AllLowTypes(finishArr(alloc, allExternPtrTypes), allFunPtrs, allRecords, allUnions),
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
		assert(builtin.info.kind == BuiltinStructKind.ptr);
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

struct LowFunSource {
	@safe @nogc pure nothrow:
	struct Compare {
		immutable LowType type;
		immutable Bool typeIsArr;
	}
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
	public:
	@trusted immutable this(immutable Compare a) { kind = Kind.compare; compare_ = a; }
	@trusted immutable this(immutable Ptr!ConcreteFun a) { kind = Kind.expr; expr_ = a; }
}

@trusted T matchLowFunSource(T)(
	ref immutable LowFunSource a,
	scope T delegate(ref immutable LowFunSource.Compare) @safe @nogc pure nothrow cbCompare,
	scope T delegate(immutable Ptr!ConcreteFun) @safe @nogc pure nothrow cbExpr,
) {
	final switch (a.kind) {
		case LowFunSource.Kind.compare:
			return cbCompare(a.compare_);
		case LowFunSource.Kind.expr:
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
	StackAlloc!("getAllLowFuns", 1024 * 1024) tempAlloc;
	CompareFuns compareFuns = CompareFuns(
		newMutIndexDict!(immutable LowType.Record, immutable LowFunIndex)(tempAlloc, size(allTypes.allRecords)),
		newMutIndexDict!(immutable LowType.Record, immutable LowFunIndex)(tempAlloc, size(allTypes.allRecords)),
		newMutIndexDict!(immutable LowType.Union, immutable LowFunIndex)(tempAlloc, size(allTypes.allUnions)),
		newMutIndexDict!(immutable PrimitiveTypeIndex, immutable LowFunIndex)(tempAlloc, nPrimitiveTypes));
	ArrBuilder!LowFunSource lowFunSourcesBuilder;

	Late!(immutable LowType) comparisonType = late!(immutable LowType);

	immutable(LowFunIndex) addLowFun(immutable LowFunSource source) {
		immutable LowFunIndex res = immutable LowFunIndex(arrBuilderSize(lowFunSourcesBuilder));
		add(tempAlloc, lowFunSourcesBuilder, source);
		return res;
	}

	immutable(Opt!LowFunIndex) generateCompareForType(immutable LowType lowType) @safe @nogc pure nothrow {
		immutable(LowFunIndex) addIt(immutable Bool typeIsArr) {
			return addLowFun(immutable LowFunSource(immutable LowFunSource.Compare(lowType, typeIsArr)));
		}

		void generateCompareForFields(immutable LowType.Record record) {
			foreach (ref immutable LowField field; arrRange(at(allTypes.allRecords, record.index).fields))
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
				//TODO: better way to detect arr!
				immutable LowRecord record = at(allTypes.allRecords, it.index);
				immutable Str mangledName = record.mangledName;
				immutable Bool typeIsArr = strEqLiteral(slice(mangledName, 0, 3), "arr");
				immutable ValueAndDidAdd!(immutable LowFunIndex) index = getOrAddAndDidAdd(
					compareFuns.recordValToCompare,
					it,
					() => addIt(typeIsArr));
				if (index.didAdd) {
					if (typeIsArr) {
						assert(strEqLiteral(at(record.fields, 1).mangledName, "data"));
						generateCompareForType(asNonFunPtrType(at(record.fields, 1).type).pointee);
					} else
						generateCompareForFields(it);
				}
				return some(index.value);
			},
			(immutable LowType.Union it) {
				immutable ValueAndDidAdd!(immutable LowFunIndex) index =
					getOrAddAndDidAdd(compareFuns.unionToCompare, it, () => addIt(False));
				if (index.didAdd)
					foreach (ref immutable LowType member; arrRange(at(allTypes.allUnions, it.index).members))
						generateCompareForType(member);
				return some(index.value);
			});
	}

	foreach (immutable Ptr!ConcreteFun fun; arrRange(program.allFuns)) {
		immutable Opt!LowFunIndex opIndex = matchConcreteFunBody!(immutable Opt!LowFunIndex)(
			body_(fun),
			(ref immutable ConcreteFunBody.Builtin it) {
				if (it.builtinInfo.emit == BuiltinFunEmit.generate) {
					assert(it.builtinInfo.kind == BuiltinFunKind.compare);
					if (!lateIsSet(comparisonType))
						lateSet(comparisonType, lowTypeFromConcreteType(alloc, getLowTypeCtx, fun.returnType));
					immutable Opt!LowFunIndex res = generateCompareForType(
						lowTypeFromConcreteType(alloc, getLowTypeCtx, only(it.typeArgs)));
					assert(has(res));
					return res;
				} else
					return none!LowFunIndex;
			},
			(ref immutable ConcreteFunBody.Extern) =>
				some(addLowFun(immutable LowFunSource(fun))),
			(ref immutable ConcreteFunExprBody) =>
				some(addLowFun(immutable LowFunSource(fun))));
		if (has(opIndex)) {
			addToDict(alloc, concreteFunToLowFunIndexBuilder, fun, force(opIndex));
		}
	}

	immutable ComparisonTypes comparisonTypes = getComparisonTypes(allTypes, lateGet(comparisonType));

	immutable Arr!LowFunSource lowFunSources = finishArr(tempAlloc, lowFunSourcesBuilder);
	immutable ConcreteFunToLowFunIndex concreteFunToLowFunIndex =
		finishDictShouldBeNoConflict(alloc, concreteFunToLowFunIndexBuilder);

	immutable Arr!LowFun allLowFuns =
		mapWithIndex(alloc, lowFunSources, (immutable size_t index, ref immutable LowFunSource source) =>
			matchLowFunSource!(immutable LowFun)(
				source,
				(ref immutable LowFunSource.Compare it) =>
					generateCompareFun(
						alloc,
						SourceRange.empty,
						allTypes,
						comparisonTypes,
						compareFuns,
						immutable LowFunIndex(index),
						it.type,
						it.typeIsArr),
				(immutable Ptr!ConcreteFun cf) {
					immutable LowType returnType = lowTypeFromConcreteType(alloc, getLowTypeCtx, cf.returnType);
					immutable Opt!LowParam ctxParam = cf.needsCtx
						? some(immutable LowParam(strLiteral("ctx"), ctxType))
						: none!LowParam;
					immutable Opt!LowParam closureParam = mapOption(cf.closureParam, (ref immutable ConcreteParam it) =>
						getLowParam(alloc, getLowTypeCtx, it));
					immutable Arr!LowParam params = mapWithOptFirst2!(LowParam, ConcreteParam, Alloc)(
						alloc,
						ctxParam,
						closureParam,
						cf.paramsExcludingCtxAndClosure,
						(ref immutable ConcreteParam it) =>
							getLowParam(alloc, getLowTypeCtx, it));
					immutable Opt!(Ptr!LowParam) ctxParamPtr = has(ctxParam)
						? some(ptrAt(params, 0))
						: none!(Ptr!LowParam);
					immutable Opt!(Ptr!LowParam) closureParamPtr = has(cf.closureParam)
						? some(ptrAt(params, cf.needsCtx ? 1 : 0))
						: none!(Ptr!LowParam);
					immutable LowFunBody body_ = getLowFunBody(
						alloc,
						allTypes,
						getLowTypeCtx,
						concreteFunToLowFunIndex,
						ctxParamPtr,
						closureParamPtr,
						slice(params, (has(ctxParamPtr) ? 1 : 0) + (has(closureParamPtr) ? 1 : 0)),
						body_(cf));
					return immutable LowFun(cf.mangledName, returnType, params, body_);
				}));

	immutable LowFunIndex userMainIndex = mustGetAt(concreteFunToLowFunIndex, program.userMain);
	immutable LowFunIndex rtMainIndex = mustGetAt(concreteFunToLowFunIndex, program.rtMain);
	immutable LowFun mainFun = mainFun!Alloc(
		alloc,
		getLowTypeCtx,
		rtMainIndex,
		userMainIndex,
		at(allLowFuns, rtMainIndex.index));
	return immutable AllLowFuns(allLowFuns, mainFun);
}

immutable(ComparisonTypes) getComparisonTypes(
	ref immutable AllLowTypes allTypes,
	immutable LowType comparisonType,
) {
	immutable LowType.Union comparison = asUnionType(comparisonType);
	immutable LowUnion unionBody = at(allTypes.allUnions, comparison.index);
	immutable(LowType.Record) getMember(immutable size_t index) {
		return asRecordType(at(unionBody.members, index));
	}
	return immutable ComparisonTypes(comparison, getMember(0), getMember(1), getMember(2));
}

immutable(LowFun) mainFun(Alloc)(
	ref Alloc alloc,
	ref const GetLowTypeCtx ctx,
	immutable LowFunIndex rtMainIndex,
	immutable LowFunIndex userMainIndex,
	ref immutable LowFun rtMain,
) {
	immutable Arr!LowParam params = arrLiteral!LowParam(
		alloc,
		immutable LowParam(strLiteral("argc"), int32Type),
		immutable LowParam(strLiteral("argv"), charPtrPtrType));
	immutable Ptr!LowParam argc = ptrAt(params, 0);
	immutable Ptr!LowParam argv = ptrAt(params, 1);
	immutable LowType userMainFunPtrType = at(rtMain.params, 2).type;
	immutable LowExpr userMainFunPtr = immutable LowExpr(
		userMainFunPtrType,
		SourceRange.empty,
		immutable LowExprKind(immutable LowExprKind.FunPtr(userMainIndex)));
	immutable LowExpr call = immutable LowExpr(
		int32Type,
		SourceRange.empty,
		immutable LowExprKind(immutable LowExprKind.Call(
			rtMainIndex,
			arrLiteral!LowExpr(
				alloc,
				paramRef(SourceRange.empty, argc),
				paramRef(SourceRange.empty, argv),
				userMainFunPtr))));
	immutable LowFunBody body_ = immutable LowFunBody(immutable LowFunExprBody(emptyArr!(Ptr!LowLocal), call));
	return immutable LowFun(strLiteral("main"), int32Type, params, body_);
}

immutable(LowParam) getLowParam(Alloc)(ref Alloc alloc, ref GetLowTypeCtx ctx, ref immutable ConcreteParam a) {
	return immutable LowParam(a.mangledName, lowTypeFromConcreteType(alloc, ctx, a.type));
}

immutable(LowLocal) getLowLocal(Alloc)(ref Alloc alloc, ref GetLowTypeCtx ctx, ref immutable ConcreteLocal a) {
	return immutable LowLocal(a.mangledName, lowTypeFromConcreteType(alloc, ctx, a.type));
}

alias ConcreteFunToLowFunIndex = immutable Dict!(Ptr!ConcreteFun, LowFunIndex, comparePtr!ConcreteFun);

immutable(LowFunBody) getLowFunBody(Alloc)(
	ref Alloc alloc,
	ref immutable AllLowTypes allTypes,
	ref GetLowTypeCtx getLowTypeCtx,
	ref immutable ConcreteFunToLowFunIndex concreteFunToLowFunIndex,
	immutable Opt!(Ptr!LowParam) ctxParam,
	immutable Opt!(Ptr!LowParam) closureParam,
	immutable Arr!(LowParam) regularParams,
	ref immutable ConcreteFunBody a,
) {
	return matchConcreteFunBody!(immutable LowFunBody)(
		a,
		(ref immutable ConcreteFunBody.Builtin it) =>
			unreachable!(immutable LowFunBody), // compare funs have a different code path
		(ref immutable ConcreteFunBody.Extern it) =>
			immutable LowFunBody(immutable LowFunBody.Extern(it.isGlobal)),
		(ref immutable ConcreteFunExprBody it) {
			GetLowExprCtx exprCtx = GetLowExprCtx(
				ptrTrustMe(allTypes),
				ptrTrustMe_mut(getLowTypeCtx),
				concreteFunToLowFunIndex,
				ctxParam,
				closureParam,
				regularParams);
			foreach (immutable Ptr!ConcreteLocal local; arrRange(it.allLocals))
				add(alloc, exprCtx.locals, allocate(alloc, getLowLocal(alloc, getLowTypeCtx, local)));
			immutable LowExpr expr = getLowExpr(alloc, exprCtx, it.expr);
			return immutable LowFunBody(immutable LowFunExprBody(finishArr(alloc, exprCtx.locals), expr));
		});
}

struct GetLowExprCtx {
	immutable Ptr!AllLowTypes allTypes;
	Ptr!GetLowTypeCtx getLowTypeCtx;
	ConcreteFunToLowFunIndex concreteFunToLowFunIndex;
	immutable Opt!(Ptr!LowParam) ctxParam;
	immutable Opt!(Ptr!LowParam) closureParam;
	immutable Arr!(LowParam) regularParams;
	ArrBuilder!(Ptr!LowLocal) locals;
	size_t tempLocalIdx;
}

//TODO:KILL (inline)
ref GetLowTypeCtx typeCtx(return scope ref GetLowExprCtx ctx) {
	return ctx.getLowTypeCtx;
}

immutable(LowExpr) getCtxParamRef(Alloc)(
	ref Alloc alloc,
	ref const GetLowExprCtx ctx,
	ref immutable SourceRange range,
) {
	return paramRef(range, force(ctx.ctxParam));
}

immutable(LowExprKind) getCtxParamRefKind(ref const GetLowExprCtx ctx) {
	return immutable LowExprKind(immutable LowExprKind.ParamRef(force(ctx.ctxParam)));
}

immutable(LowFunIndex) getLowFunIndex(ref const GetLowExprCtx ctx, immutable Ptr!ConcreteFun it) {
	immutable Opt!LowFunIndex op = tryGetLowFunIndex(ctx, it);
	return force(op);
}

immutable(Opt!LowFunIndex) tryGetLowFunIndex(ref const GetLowExprCtx ctx, immutable Ptr!ConcreteFun it) {
	return getAt(ctx.concreteFunToLowFunIndex, it);
}

immutable(Ptr!LowLocal) addTempLocal(Alloc)(ref Alloc alloc, ref GetLowExprCtx ctx, ref immutable LowType type) {
	Writer!Alloc writer = Writer!Alloc(ptrTrustMe_mut(alloc));
	writeStatic(writer, "temp");
	writeNat(writer, ctx.tempLocalIdx);
	ctx.tempLocalIdx++;
	immutable Ptr!LowLocal res = allocate(alloc, immutable LowLocal(finishWriter(writer), type));
	add(alloc, ctx.locals, res);
	return res;
}

immutable(LowExpr) getLowExpr(Alloc)(ref Alloc alloc, ref GetLowExprCtx ctx, ref immutable ConcreteExpr expr) {
	immutable LowType type = lowTypeFromConcreteType(alloc, typeCtx(ctx), expr.type);
	return immutable LowExpr(type, expr.range, getLowExprKind(alloc, ctx, type, expr));
}

immutable(LowExprKind) getLowExprKind(Alloc)(
	ref Alloc alloc,
	ref GetLowExprCtx ctx,
	ref immutable LowType type,
	ref immutable ConcreteExpr expr,
) {
	return matchConcreteExpr!(immutable LowExprKind)(
		expr,
		(ref immutable ConcreteExpr.Alloc it) =>
			getAllocExpr(alloc, ctx, expr.range, it),
		(ref immutable ConcreteExpr.Call it) =>
			getCallExpr(alloc, ctx, expr.range, it),
		(ref immutable ConcreteExpr.Cond it) =>
			immutable LowExprKind(immutable LowExprKind.SpecialTrinary(
				LowExprKind.SpecialTrinary.Kind.if_,
				allocate(alloc, getLowExpr(alloc, ctx, it.cond)),
				allocate(alloc, getLowExpr(alloc, ctx, it.then)),
				allocate(alloc, getLowExpr(alloc, ctx, it.else_)))),
		(ref immutable ConcreteExpr.CreateArr it) =>
			getCreateArrExpr(alloc, ctx, expr.range, it),
		(ref immutable ConcreteExpr.CreateRecord it) =>
			immutable LowExprKind(immutable LowExprKind.CreateRecord(
				map(alloc, it.args, (ref immutable ConcreteExpr it) =>
					getLowExpr(alloc, ctx, it)))),
		(ref immutable ConcreteExpr.ConvertToUnion it) =>
			immutable LowExprKind(immutable LowExprKind.ConvertToUnion(
				it.memberIndex,
				allocate(alloc, getLowExpr(alloc, ctx, it.arg)))),
		(ref immutable ConcreteExpr.Lambda it) =>
			getLambdaExpr(alloc, ctx, type, expr.range, it),
		(ref immutable ConcreteExpr.Let it) =>
			getLetExpr(alloc, ctx, expr.range, it),
		(ref immutable ConcreteExpr.LocalRef it) =>
			immutable LowExprKind(immutable LowExprKind.LocalRef(getLocal(ctx, it.local))),
		(ref immutable ConcreteExpr.Match it) =>
			getMatchExpr(alloc, ctx, it),
		(ref immutable ConcreteExpr.ParamRef it) =>
			getParamRefExpr(alloc, ctx, it),
		(ref immutable ConcreteExpr.RecordFieldAccess it) =>
			getRecordFieldAccessExpr(alloc, ctx, it),
		(ref immutable ConcreteExpr.RecordFieldSet it) =>
			getRecordFieldSetExpr(alloc, ctx, it),
		(ref immutable ConcreteExpr.Seq it) =>
			immutable LowExprKind(immutable LowExprKind.Seq(
				allocate(alloc, getLowExpr(alloc, ctx, it.first)),
				allocate(alloc, getLowExpr(alloc, ctx, it.then)))),
		(ref immutable ConcreteExpr.SpecialConstant it) =>
			immutable LowExprKind(immutable LowExprKind.SpecialConstant(() {
				final switch (it.kind) {
					case ConcreteExpr.SpecialConstant.Kind.one:
						return immutable LowExprKind.SpecialConstant.Integral(1);
					case ConcreteExpr.SpecialConstant.Kind.zero:
						return immutable LowExprKind.SpecialConstant.Integral(0);
				}
			}())),
		(ref immutable ConcreteExpr.SpecialUnary it) =>
			immutable LowExprKind(immutable LowExprKind.SpecialUnary(
				() {
					final switch (it.kind) {
						case ConcreteExpr.SpecialUnary.Kind.deref:
							return LowExprKind.SpecialUnary.Kind.deref;
					}
				}(),
				allocate(alloc, getLowExpr(alloc, ctx, it.arg)))),
		(ref immutable ConcreteExpr.SpecialBinary it) =>
			immutable LowExprKind(immutable LowExprKind.SpecialBinary(
				() {
					final switch (it.kind) {
						case ConcreteExpr.SpecialBinary.Kind.eqNat64:
							return LowExprKind.SpecialBinary.Kind.eqNat64;
						case ConcreteExpr.SpecialBinary.Kind.less:
							return LowExprKind.SpecialBinary.Kind.less;
						case ConcreteExpr.SpecialBinary.Kind.or:
							return LowExprKind.SpecialBinary.Kind.or;
						case ConcreteExpr.SpecialBinary.Kind.wrapAddNat64:
							return LowExprKind.SpecialBinary.Kind.wrapAddNat64;
						case ConcreteExpr.SpecialBinary.Kind.wrapSubNat64:
							return LowExprKind.SpecialBinary.Kind.wrapSubNat64;
					}
				}(),
				allocate(alloc, getLowExpr(alloc, ctx, it.left)),
				allocate(alloc, getLowExpr(alloc, ctx, it.right)))),
		(ref immutable ConcreteExpr.StringLiteral it) =>
			immutable LowExprKind(immutable LowExprKind.StringLiteral(it.literal)));
}

immutable(LowExpr) getAllocateExpr(Alloc)(
	ref Alloc alloc,
	ref GetLowExprCtx ctx,
	ref immutable SourceRange range,
	immutable Ptr!ConcreteFun allocFun,
	ref immutable LowType ptrType,
	ref immutable LowExpr size,
) {
	immutable LowExpr allocate = immutable LowExpr(
		anyPtrType,
		range,
		immutable LowExprKind(immutable LowExprKind.Call(
			getLowFunIndex(ctx, allocFun),
			arrLiteral!LowExpr(alloc, getCtxParamRef(alloc, ctx, range), size))));
	return ptrCast(alloc, ptrType, range, allocate);
}

immutable(LowExprKind) getAllocExpr(Alloc)(
	ref Alloc alloc,
	ref GetLowExprCtx ctx,
	ref immutable SourceRange range,
	ref immutable ConcreteExpr.Alloc a,
) {
	// (temp0 = (T*) alloc(sizeof(T)), *temp0 = inner, temp0)
	immutable LowExpr inner = getLowExpr(alloc, ctx, a.inner);
	immutable LowType pointeeType = inner.type;
	immutable LowType ptrType = getLowPtrType(alloc, typeCtx(ctx), pointeeType);
	immutable Ptr!LowLocal local = addTempLocal(alloc, ctx, ptrType);
	immutable LowExpr sizeofT = getSizeOf(range, pointeeType);
	immutable LowExpr allocatePtr = getAllocateExpr!Alloc(alloc, ctx, range, a.alloc, ptrType, sizeofT);
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
	ref immutable SourceRange range,
	ref immutable ConcreteExpr.Call a,
) {
	immutable Bool shouldBeCall = shouldMapToLowFun(body_(a.called));
	immutable Opt!LowFunIndex opCalled = tryGetLowFunIndex(ctx, a.called);
	if (has(opCalled)) {
		assert(shouldBeCall);
		immutable Opt!LowExpr ctxArg = a.called.needsCtx ? some(getCtxParamRef(alloc, ctx, range)) : none!LowExpr;
		immutable Arr!LowExpr args = mapWithOptFirst(alloc, ctxArg, a.args, (ref immutable ConcreteExpr it) =>
			getLowExpr(alloc, ctx, it));
		return immutable LowExprKind(immutable LowExprKind.Call(force(opCalled), args));
	} else {
		assert(!shouldBeCall);
		immutable ConcreteFunBody.Builtin builtin = asBuiltin(body_(a.called));
		assert(builtin.builtinInfo.emit == BuiltinFunEmit.operator ||
			builtin.builtinInfo.emit == BuiltinFunEmit.special);
		return getOperatorCallExpr(alloc, ctx, range, builtin.builtinInfo.kind, a.args, builtin.typeArgs);
	}
}

// Builtins don't become functions, they are compiled inline.
immutable(Bool) shouldMapToLowFun(ref immutable ConcreteFunBody a) {
	return matchConcreteFunBody!(immutable Bool)(
		a,
		(ref immutable ConcreteFunBody.Builtin it) =>
			immutable Bool(it.builtinInfo.emit == BuiltinFunEmit.generate),
		(ref immutable ConcreteFunBody.Extern) =>
			// No body but we do declare it as a function
			True,
		(ref immutable ConcreteFunExprBody) =>
			True);
}

immutable(LowExprKind) getCreateArrExpr(Alloc)(
	ref Alloc alloc,
	ref GetLowExprCtx ctx,
	ref immutable SourceRange range,
	ref immutable ConcreteExpr.CreateArr a,
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
	immutable LowExpr allocatePtr = getAllocateExpr(alloc, ctx, range, a.alloc, elementPtrType, sizeBytes);
	immutable Ptr!LowLocal temp = addTempLocal(alloc, ctx, elementPtrType);
	immutable LowExpr getTemp = localRef(alloc, range, temp);
	immutable(LowExpr) recur(immutable LowExpr cur, immutable size_t prevIndex) {
		if (prevIndex == 0)
			return cur;
		else {
			immutable size_t index = prevIndex - 1;
			immutable LowExpr arg = getLowExpr(alloc, ctx, at(a.args, index));
			immutable LowExpr elementPtr = addPtr(alloc, elementPtrType, range, getTemp, index);
			immutable LowExpr writeToElement = writeToPtr(alloc, range, elementPtr, arg);
			return recur(seq(alloc, range, writeToElement, cur), index);
		}
	}
	immutable LowExpr createArr = immutable LowExpr(
		arrType,
		range,
		immutable LowExprKind(immutable LowExprKind.CreateRecord(
			arrLiteral!LowExpr(alloc, nElements, localRef(alloc, range, temp)))));
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
	ref immutable SourceRange range,
	ref immutable ConcreteExpr.Lambda a,
) {
	immutable LowFunIndex lambdaFun = getLowFunIndex(ctx, a.fun);
	immutable LowExprKind funPtr = immutable LowExprKind(immutable LowExprKind.FunPtr(lambdaFun));
	if (!has(a.closure))
		return funPtr;
	else {
		immutable LowType.Record recordType = asRecordType(type);
		immutable Ptr!LowRecord record = ptrAt(ctx.allTypes.allRecords, recordType.index);
		assert(size(record.fields) == 2);
		immutable LowType funPtrType = immutable LowType(asFunPtrType(at(record.fields, 0).type));
		immutable LowExpr closure = ptrCast(alloc, anyPtrType, range, getLowExpr(alloc, ctx, force(a.closure)));
		immutable LowExpr funPtrCasted = ptrCast(
			alloc,
			funPtrType,
			range,
			immutable LowExpr(funPtrType, range, funPtr));
		immutable Arr!LowExpr args = arrLiteral!LowExpr(alloc, funPtrCasted, closure);
		return immutable LowExprKind(immutable LowExprKind.CreateRecord(args));
	}
}

immutable(Ptr!LowLocal) getLocal(ref GetLowExprCtx ctx, immutable Ptr!ConcreteLocal concreteLocal) {
	immutable size_t localIndex = concreteLocal.index;
	immutable Ptr!LowLocal local = arrBuilderAt(ctx.locals, localIndex);
	assert(strEq(local.mangledName, concreteLocal.mangledName));
	return local;
}

immutable(LowExprKind) getLetExpr(Alloc)(
	ref Alloc alloc,
	ref GetLowExprCtx ctx,
	ref immutable SourceRange range,
	ref immutable ConcreteExpr.Let a,
) {
	return immutable LowExprKind(immutable LowExprKind.Let(
		getLocal(ctx, a.local),
		allocate(alloc, getLowExpr(alloc, ctx, a.value)),
		allocate(alloc, getLowExpr(alloc, ctx, a.then))));
}

immutable(LowExprKind) getMatchExpr(Alloc)(
	ref Alloc alloc,
	ref GetLowExprCtx ctx,
	ref immutable ConcreteExpr.Match a,
) {
	immutable Ptr!LowLocal matchedLocal = getLocal(ctx, a.matchedLocal);
	return immutable LowExprKind(immutable LowExprKind.Match(
		matchedLocal,
		allocate(alloc, getLowExpr(alloc, ctx, a.matchedValue)),
		map(alloc, a.cases, (ref immutable ConcreteExpr.Match.Case case_) =>
			immutable LowExprKind.Match.Case(
				mapOption(case_.local, (ref immutable Ptr!ConcreteLocal local) =>
					getLocal(ctx, local)),
				getLowExpr(alloc, ctx, case_.then)))));
}

immutable(LowExprKind) getParamRefExpr(Alloc)(
	ref Alloc alloc,
	ref GetLowExprCtx ctx,
	ref immutable ConcreteExpr.ParamRef a,
) {
	if (!has(a.param.index)) {
		//TODO: don't generate ParamRef in ConcreteModel for closure field access. Do that in lowering.
		assert(strEq(a.param.mangledName, strLiteral("_closure")));
		return immutable LowExprKind(immutable LowExprKind.ParamRef(force(ctx.closureParam)));
	}

	immutable Ptr!LowParam param = ptrAt(ctx.regularParams, force(a.param.index));
	assert(strEq(param.mangledName, a.param.mangledName));
	return immutable LowExprKind(immutable LowExprKind.ParamRef(param));
}

struct FieldAndTargetIsPointer {
	immutable Bool targetIsPointer;
	immutable LowType.Record record;
	immutable Ptr!LowField field;
}

immutable(FieldAndTargetIsPointer) getLowField(
	ref GetLowExprCtx ctx,
	immutable LowType targetType,
	immutable Ptr!ConcreteField concreteField,
) {
	immutable Bool targetIsPointer = isNonFunPtrType(targetType);
	immutable LowType.Record record = asRecordType(targetIsPointer ? asNonFunPtrType(targetType).pointee : targetType);
	immutable Ptr!LowField field = ptrAt(at(ctx.allTypes.allRecords, record.index).fields, concreteField.index);
	assert(strEq(field.mangledName, concreteField.mangledName));
	return immutable FieldAndTargetIsPointer(targetIsPointer, record, field);
}

immutable(LowExprKind) getRecordFieldAccessExpr(Alloc)(
	ref Alloc alloc,
	ref GetLowExprCtx ctx,
	ref immutable ConcreteExpr.RecordFieldAccess a,
) {
	immutable LowExpr target = getLowExpr(alloc, ctx, a.target);
	immutable FieldAndTargetIsPointer field = getLowField(ctx, target.type, a.field);
	return immutable LowExprKind(
		immutable LowExprKind.RecordFieldAccess(
			allocate(alloc, target),
			field.targetIsPointer,
			field.record,
			field.field));
}

immutable(LowExprKind) getRecordFieldSetExpr(Alloc)(
	ref Alloc alloc,
	ref GetLowExprCtx ctx,
	ref immutable ConcreteExpr.RecordFieldSet a,
) {
	immutable LowExpr target = getLowExpr(alloc, ctx, a.target);
	immutable FieldAndTargetIsPointer field = getLowField(ctx, target.type, a.field);
	return immutable LowExprKind(immutable LowExprKind.RecordFieldSet(
		allocate(alloc, target),
		field.targetIsPointer,
		field.record,
		field.field,
		allocate(alloc, getLowExpr(alloc, ctx, a.value))));
}

immutable(LowExprKind) getOperatorCallExpr(Alloc)(
	ref Alloc alloc,
	ref GetLowExprCtx ctx,
	ref immutable SourceRange range,
	ref immutable BuiltinFunKind op,
	ref immutable Arr!ConcreteExpr args,
	ref immutable Arr!ConcreteType typeArgs,
) {
	immutable(LowExpr) arg0() {
		return getLowExpr(alloc, ctx, at(args, 0));
	}
	immutable(LowExpr) arg1() {
		return getLowExpr(alloc, ctx, at(args, 1));
	}
	immutable(LowExpr) arg2() {
		return getLowExpr(alloc, ctx, at(args, 2));
	}
	immutable(LowType) typeArg0() {
		return lowTypeFromConcreteType(alloc, ctx.getLowTypeCtx, at(typeArgs, 0));
	}
	immutable(LowExprKind) constant(immutable LowExprKind.SpecialConstant kind) {
		return immutable LowExprKind(kind);
	}
	immutable(LowExprKind) constantBool(immutable Bool value) {
		return immutable LowExprKind(
			immutable LowExprKind.SpecialConstant(immutable LowExprKind.SpecialConstant.BoolConstant(value)));
	}
	immutable(LowExprKind) constantIntegral(int value) {
		return constant(immutable LowExprKind.SpecialConstant(immutable LowExprKind.SpecialConstant.Integral(value)));
	}
	immutable(LowExprKind) special0Ary(immutable LowExprKind.Special0Ary.Kind kind) {
		assert(empty(args));
		return immutable LowExprKind(immutable LowExprKind.Special0Ary(kind));
	}
	immutable(LowExprKind) unary(immutable LowExprKind.SpecialUnary.Kind kind) {
		assert(size(args) == 1);
		return immutable LowExprKind(immutable LowExprKind.SpecialUnary(
			kind,
			allocate(alloc, arg0())));
	}
	immutable(LowExprKind) binary(immutable LowExprKind.SpecialBinary.Kind kind) {
		assert(size(args) == 2);
		return immutable LowExprKind(immutable LowExprKind.SpecialBinary(
			kind,
			allocate(alloc, arg0()),
			allocate(alloc, arg1())));
	}
	immutable(LowExprKind) trinary(immutable LowExprKind.SpecialTrinary.Kind kind) {
		assert(size(args) == 3);
		return immutable LowExprKind(immutable LowExprKind.SpecialTrinary(
			kind,
			allocate(alloc, arg0()),
			allocate(alloc, arg1()),
			allocate(alloc, arg2())));
	}
	immutable(LowExprKind) nAry(immutable LowExprKind.SpecialNAry.Kind kind) {
		return immutable LowExprKind(immutable LowExprKind.SpecialNAry(
			kind,
			map(alloc, args, (ref immutable ConcreteExpr arg) =>
				getLowExpr(alloc, ctx, arg))));
	}

	final switch (op) {
		case BuiltinFunKind.addFloat64:
			return binary(LowExprKind.SpecialBinary.Kind.addFloat64);
		case BuiltinFunKind.addPtr:
			return binary(LowExprKind.SpecialBinary.Kind.addPtr);
		case BuiltinFunKind.asAnyPtr:
			return unary(LowExprKind.SpecialUnary.Kind.asAnyPtr);
		case BuiltinFunKind.asRef:
			return unary(LowExprKind.SpecialUnary.Kind.asRef);
		case BuiltinFunKind.and:
			return binary(LowExprKind.SpecialBinary.Kind.and);
		case BuiltinFunKind.as:
			assert(size(args) == 1);
			return arg0().kind;
		case BuiltinFunKind.bitShiftLeftInt32:
			return binary(LowExprKind.SpecialBinary.Kind.bitShiftLeftInt32);
		case BuiltinFunKind.bitShiftLeftNat32:
			return binary(LowExprKind.SpecialBinary.Kind.bitShiftLeftNat32);
		case BuiltinFunKind.bitShiftRightInt32:
			return binary(LowExprKind.SpecialBinary.Kind.bitShiftRightInt32);
		case BuiltinFunKind.bitShiftRightNat32:
			return binary(LowExprKind.SpecialBinary.Kind.bitShiftRightNat32);
		case BuiltinFunKind.bitwiseAndInt8:
			return binary(LowExprKind.SpecialBinary.Kind.bitwiseAndInt8);
		case BuiltinFunKind.bitwiseAndInt16:
			return binary(LowExprKind.SpecialBinary.Kind.bitwiseAndInt16);
		case BuiltinFunKind.bitwiseAndInt32:
			return binary(LowExprKind.SpecialBinary.Kind.bitwiseAndInt32);
		case BuiltinFunKind.bitwiseAndInt64:
			return binary(LowExprKind.SpecialBinary.Kind.bitwiseAndInt64);
		case BuiltinFunKind.bitwiseAndNat8:
			return binary(LowExprKind.SpecialBinary.Kind.bitwiseAndNat8);
		case BuiltinFunKind.bitwiseAndNat16:
			return binary(LowExprKind.SpecialBinary.Kind.bitwiseAndNat16);
		case BuiltinFunKind.bitwiseAndNat32:
			return binary(LowExprKind.SpecialBinary.Kind.bitwiseAndNat32);
		case BuiltinFunKind.bitwiseAndNat64:
		return binary(LowExprKind.SpecialBinary.Kind.bitwiseAndNat64);
		case BuiltinFunKind.bitwiseOrInt8:
			return binary(LowExprKind.SpecialBinary.Kind.bitwiseOrInt8);
		case BuiltinFunKind.bitwiseOrInt16:
			return binary(LowExprKind.SpecialBinary.Kind.bitwiseOrInt16);
		case BuiltinFunKind.bitwiseOrInt32:
			return binary(LowExprKind.SpecialBinary.Kind.bitwiseOrInt32);
		case BuiltinFunKind.bitwiseOrInt64:
			return binary(LowExprKind.SpecialBinary.Kind.bitwiseOrInt64);
		case BuiltinFunKind.bitwiseOrNat8:
			return binary(LowExprKind.SpecialBinary.Kind.bitwiseAndNat8);
		case BuiltinFunKind.bitwiseOrNat16:
			return binary(LowExprKind.SpecialBinary.Kind.bitwiseOrNat16);
		case BuiltinFunKind.bitwiseOrNat32:
			return binary(LowExprKind.SpecialBinary.Kind.bitwiseOrNat32);
		case BuiltinFunKind.bitwiseOrNat64:
			return binary(LowExprKind.SpecialBinary.Kind.bitwiseOrNat64);
		case BuiltinFunKind.callFunPtr:
			return nAry(LowExprKind.SpecialNAry.Kind.callFunPtr);
		case BuiltinFunKind.compareExchangeStrong:
			//TODO: why was this not just an extern fn?
			return trinary(LowExprKind.SpecialTrinary.Kind.compareExchangeStrong);
		case BuiltinFunKind.deref:
			return unary(LowExprKind.SpecialUnary.Kind.deref);
		case BuiltinFunKind.false_:
			return constantBool(False);
		case BuiltinFunKind.getCtx:
			return getCtxParamRefKind(ctx);
		case BuiltinFunKind.getErrno:
			return special0Ary(LowExprKind.Special0Ary.Kind.getErrno);
		case BuiltinFunKind.hardFail:
			return unary(LowExprKind.SpecialUnary.Kind.hardFail);
		case BuiltinFunKind.if_:
			return trinary(LowExprKind.SpecialTrinary.Kind.if_);
		case BuiltinFunKind.isReferenceType:
			return todo!(immutable LowExprKind)("is-reference-type");
		case BuiltinFunKind.mulFloat64:
			return binary(LowExprKind.SpecialBinary.Kind.mulFloat64);
		case BuiltinFunKind.not:
			return unary(LowExprKind.SpecialUnary.Kind.not);
		case BuiltinFunKind.null_:
			return constant(immutable LowExprKind.SpecialConstant(immutable LowExprKind.SpecialConstant.Null()));
		case BuiltinFunKind.oneInt8:
		case BuiltinFunKind.oneInt16:
		case BuiltinFunKind.oneInt32:
		case BuiltinFunKind.oneInt64:
		case BuiltinFunKind.oneNat8:
		case BuiltinFunKind.oneNat16:
		case BuiltinFunKind.oneNat32:
		case BuiltinFunKind.oneNat64:
			return constantIntegral(1);
		case BuiltinFunKind.or:
			return binary(LowExprKind.SpecialBinary.Kind.or);
		case BuiltinFunKind.pass:
			return constant(immutable LowExprKind.SpecialConstant(immutable LowExprKind.SpecialConstant.Void()));
		case BuiltinFunKind.ptrCast:
			assert(size(args) == 1 && size(typeArgs) == 2);
			return ptrCastKind(alloc, arg0());
		case BuiltinFunKind.ptrEq:
			return binary(LowExprKind.SpecialBinary.Kind.eqPtr);
		case BuiltinFunKind.ptrTo:
			return unary(LowExprKind.SpecialUnary.Kind.ptrTo);
		case BuiltinFunKind.refOfVal:
			return unary(LowExprKind.SpecialUnary.Kind.refOfVal);
		case BuiltinFunKind.setPtr:
			return binary(LowExprKind.SpecialBinary.Kind.writeToPtr);
		case BuiltinFunKind.sizeOf:
			assert(empty(args) && size(typeArgs) == 1);
			return immutable LowExprKind(immutable LowExprKind.SizeOf(typeArg0()));
		case BuiltinFunKind.subFloat64:
			return binary(LowExprKind.SpecialBinary.Kind.subFloat64);
		case BuiltinFunKind.subPtrNat:
			return binary(LowExprKind.SpecialBinary.Kind.subPtrNat);
		case BuiltinFunKind.toFloat64FromInt64:
			return unary(LowExprKind.SpecialUnary.Kind.toFloat64FromInt64);
		case BuiltinFunKind.toFloat64FromNat64:
			return unary(LowExprKind.SpecialUnary.Kind.toFloat64FromNat64);
		case BuiltinFunKind.toIntFromInt16:
			return unary(LowExprKind.SpecialUnary.Kind.toIntFromInt16);
		case BuiltinFunKind.toIntFromInt32:
			return unary(LowExprKind.SpecialUnary.Kind.toIntFromInt32);
		case BuiltinFunKind.toNatFromNat16:
			return unary(LowExprKind.SpecialUnary.Kind.toNatFromNat16);
		case BuiltinFunKind.toNatFromNat32:
			return unary(LowExprKind.SpecialUnary.Kind.toNatFromNat32);
		case BuiltinFunKind.toNatFromPtr:
			return unary(LowExprKind.SpecialUnary.Kind.toNatFromPtr);
		case BuiltinFunKind.true_:
			return constantBool(True);
		case BuiltinFunKind.truncateToInt64FromFloat64:
			return unary(LowExprKind.SpecialUnary.Kind.truncateToInt64FromFloat64);
		case BuiltinFunKind.unsafeDivFloat64:
			return binary(LowExprKind.SpecialBinary.Kind.unsafeDivFloat64);
		case BuiltinFunKind.unsafeDivInt64:
			return binary(LowExprKind.SpecialBinary.Kind.unsafeDivInt64);
		case BuiltinFunKind.unsafeDivNat64:
			return binary(LowExprKind.SpecialBinary.Kind.unsafeDivNat64);
		case BuiltinFunKind.unsafeInt64ToNat64:
			return unary(LowExprKind.SpecialUnary.Kind.unsafeInt64ToNat64);
		case BuiltinFunKind.unsafeInt64ToInt8:
			return unary(LowExprKind.SpecialUnary.Kind.unsafeInt64ToInt8);
		case BuiltinFunKind.unsafeInt64ToInt16:
			return unary(LowExprKind.SpecialUnary.Kind.unsafeInt64ToInt16);
		case BuiltinFunKind.unsafeInt64ToInt32:
			return unary(LowExprKind.SpecialUnary.Kind.unsafeInt64ToInt32);
		case BuiltinFunKind.unsafeModNat64:
			return binary(LowExprKind.SpecialBinary.Kind.unsafeModNat64);
		case BuiltinFunKind.unsafeNat64ToInt64:
			return unary(LowExprKind.SpecialUnary.Kind.unsafeNat64ToInt64);
		case BuiltinFunKind.unsafeNat64ToNat8:
			return unary(LowExprKind.SpecialUnary.Kind.unsafeNat64ToNat8);
		case BuiltinFunKind.unsafeNat64ToNat16:
			return unary(LowExprKind.SpecialUnary.Kind.unsafeNat64ToNat16);
		case BuiltinFunKind.unsafeNat64ToNat32:
			return unary(LowExprKind.SpecialUnary.Kind.unsafeNat64ToNat32);
		case BuiltinFunKind.wrapAddInt16:
			return binary(LowExprKind.SpecialBinary.Kind.wrapAddInt16);
		case BuiltinFunKind.wrapAddInt32:
			return binary(LowExprKind.SpecialBinary.Kind.wrapAddInt32);
		case BuiltinFunKind.wrapAddInt64:
			return binary(LowExprKind.SpecialBinary.Kind.wrapAddInt64);
		case BuiltinFunKind.wrapAddNat16:
			return binary(LowExprKind.SpecialBinary.Kind.wrapAddNat16);
		case BuiltinFunKind.wrapAddNat32:
			return binary(LowExprKind.SpecialBinary.Kind.wrapAddNat32);
		case BuiltinFunKind.wrapAddNat64:
			return binary(LowExprKind.SpecialBinary.Kind.wrapAddNat64);
		case BuiltinFunKind.wrapMulInt16:
			return binary(LowExprKind.SpecialBinary.Kind.wrapMulInt16);
		case BuiltinFunKind.wrapMulInt32:
			return binary(LowExprKind.SpecialBinary.Kind.wrapMulInt32);
		case BuiltinFunKind.wrapMulInt64:
			return binary(LowExprKind.SpecialBinary.Kind.wrapMulInt64);
		case BuiltinFunKind.wrapMulNat16:
			return binary(LowExprKind.SpecialBinary.Kind.wrapMulNat16);
		case BuiltinFunKind.wrapMulNat32:
			return binary(LowExprKind.SpecialBinary.Kind.wrapMulNat32);
		case BuiltinFunKind.wrapMulNat64:
			return binary(LowExprKind.SpecialBinary.Kind.wrapMulNat64);
		case BuiltinFunKind.wrapSubInt16:
			return binary(LowExprKind.SpecialBinary.Kind.wrapSubInt16);
		case BuiltinFunKind.wrapSubInt32:
			return binary(LowExprKind.SpecialBinary.Kind.wrapSubInt32);
		case BuiltinFunKind.wrapSubInt64:
			return binary(LowExprKind.SpecialBinary.Kind.wrapSubInt64);
		case BuiltinFunKind.wrapSubNat16:
			return binary(LowExprKind.SpecialBinary.Kind.wrapSubNat16);
		case BuiltinFunKind.wrapSubNat32:
			return binary(LowExprKind.SpecialBinary.Kind.wrapSubNat32);
		case BuiltinFunKind.wrapSubNat64:
			return binary(LowExprKind.SpecialBinary.Kind.wrapSubNat64);
		case BuiltinFunKind.zeroInt8:
		case BuiltinFunKind.zeroInt16:
		case BuiltinFunKind.zeroInt32:
		case BuiltinFunKind.zeroInt64:
		case BuiltinFunKind.zeroNat8:
		case BuiltinFunKind.zeroNat16:
		case BuiltinFunKind.zeroNat32:
		case BuiltinFunKind.zeroNat64:
			return constantIntegral(0);
		case BuiltinFunKind.compare:
			return unreachable!(immutable LowExprKind); // not an operator
	}
}
