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
import lowModel :
	asFunPtrType,
	LowExpr,
	LowExprKind,
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
	PrimitiveType;
import util.bools : Bool, True;
import util.collection.arr : Arr, at, first, only, ptrAt, arrRange = range, size;
import util.collection.arrBuilder : add, ArrBuilder, arrBuilderAt, arrBuilderSize, finishArr;
import util.collection.arrUtil : arrLiteral, map, mapOp, mapWithOptFirst, slice, tail;
import util.collection.dict : Dict, getAt;
import util.collection.dictBuilder : addToDict, DictBuilder, finishDictShouldBeNoConflict;
import util.collection.mutDict : getOrAdd, MutDict;
import util.collection.str : strEq, strLiteral;
import util.memory : allocate;
import util.opt : force, has, mapOption, none, Opt, optOr, some;
import util.ptr : comparePtr, Ptr, ptrTrustMe, ptrTrustMe_mut;
import util.sourceRange : SourceRange;
import util.util : todo;
import util.verify : unreachable;
import util.writer : finishWriter, writeNat, Writer, writeStatic;

immutable(LowProgram) lower(Alloc)(ref Alloc alloc, ref immutable ConcreteProgram a) {
	AllLowTypes allTypes = getAllLowTypes(alloc, a.allStructs);
	immutable AllLowFuns allFuns = getAllLowFuns!Alloc(
		alloc,
		allTypes,
		allTypes.getLowTypeCtx,
		a);
	return immutable LowProgram(
		allTypes.allFunPtrs,
		allTypes.allRecords,
		allTypes.allUnions,
		allFuns.allLowFuns,
		allFuns.lowMainFun);
}

private:

struct AllLowTypes {
	immutable Arr!LowFunPtrType allFunPtrs;
	immutable Arr!LowRecord allRecords;
	immutable Arr!LowUnion allUnions;
	GetLowTypeCtx getLowTypeCtx;
}

struct AllLowFuns {
	immutable Arr!LowFun allLowFuns;
	immutable Ptr!LowFun lowMainFun;
}

struct GetLowTypeCtx {
	immutable Dict!(Ptr!ConcreteStruct, LowType, comparePtr!ConcreteStruct) concreteStructToType;
	MutDict!(immutable Ptr!ConcreteStruct, immutable LowType, comparePtr!ConcreteStruct) concreteStructToPtrType;
}

AllLowTypes getAllLowTypes(Alloc)(ref Alloc alloc, ref immutable Arr!(Ptr!ConcreteStruct) allStructs) {
	DictBuilder!(Ptr!ConcreteStruct, LowType, comparePtr!ConcreteStruct) concreteStructToTypeBuilder;
	ArrBuilder!(Ptr!(ConcreteStructBody.Builtin)) allFunPtrSources;
	//ArrBuilder!(Ptr!(ConcreteStructBody.Builtin)) allPtrSources;
	ArrBuilder!(Ptr!(ConcreteStructBody.Record)) allRecordSources;
	ArrBuilder!(Ptr!(ConcreteStructBody.Union)) allUnionSources;

	foreach (immutable Ptr!ConcreteStruct s; arrRange(allStructs)) {
		immutable Opt!LowType lowType = matchConcreteStructBody!(immutable Opt!LowType)(
			body_(s),
			(ref immutable ConcreteStructBody.Builtin it) {
				final switch (it.info.kind) {
					case BuiltinStructKind.bool_:
						return some(immutable LowType(PrimitiveType.bool_));
					case BuiltinStructKind.byte_:
						return some(immutable LowType(PrimitiveType.byte_));
					case BuiltinStructKind.char_:
						return some(immutable LowType(PrimitiveType.char_));
					case BuiltinStructKind.float64:
						return some(immutable LowType(PrimitiveType.float64));
					case BuiltinStructKind.funPtrN:
						immutable size_t i = arrBuilderSize(allFunPtrSources);
						add(alloc, allFunPtrSources, ptrTrustMe(it));
						return some(immutable LowType(immutable LowType.FunPtr(i)));
					case BuiltinStructKind.int16:
						return some(immutable LowType(PrimitiveType.int16));
					case BuiltinStructKind.int32:
						return some(immutable LowType(PrimitiveType.int32));
					case BuiltinStructKind.int64:
						return some(immutable LowType(PrimitiveType.int64));
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
			(ref immutable ConcreteStructBody.Record it) {
				immutable size_t i = arrBuilderSize(allRecordSources);
				add(alloc, allRecordSources, ptrTrustMe(it));
				return some(immutable LowType(immutable LowType.Record(i)));
			},
			(ref immutable ConcreteStructBody.Union it) {
				immutable size_t i = arrBuilderSize(allUnionSources);
				add(alloc, allUnionSources, ptrTrustMe(it));
				return some(immutable LowType(immutable LowType.Union(i)));
			});
		if (has(lowType))
			addToDict(alloc, concreteStructToTypeBuilder, s, force(lowType));
	}

	GetLowTypeCtx getLowTypeCtx = GetLowTypeCtx(finishDictShouldBeNoConflict(alloc, concreteStructToTypeBuilder));

	immutable Arr!(LowFunPtrType) allFunPtrs =
		map(alloc, finishArr(alloc, allFunPtrSources), (ref immutable Ptr!(ConcreteStructBody.Builtin) it) {
			immutable LowType returnType = lowTypeFromConcreteType(alloc, getLowTypeCtx, first(it.typeArgs));
			immutable Arr!LowType paramTypes = map(alloc, tail(it.typeArgs), (ref immutable ConcreteType typeArg) =>
				lowTypeFromConcreteType(alloc, getLowTypeCtx, typeArg));
			return immutable LowFunPtrType(returnType, paramTypes);
		});
	immutable Arr!LowRecord allRecords =
		map(alloc, finishArr(alloc, allRecordSources), (ref immutable Ptr!(ConcreteStructBody.Record) it) =>
			immutable LowRecord(map(alloc, it.fields, (ref immutable ConcreteField field) =>
				immutable LowField(field.mangledName, lowTypeFromConcreteType(alloc, getLowTypeCtx, field.type)))));
	immutable Arr!LowUnion allUnions =
		map(alloc, finishArr(alloc, allUnionSources), (ref immutable Ptr!(ConcreteStructBody.Union) it) =>
			immutable LowUnion(map(alloc, it.members, (ref immutable ConcreteType member) =>
				lowTypeFromConcreteType(alloc, getLowTypeCtx, member))));

	return AllLowTypes(allFunPtrs, allRecords, allUnions, getLowTypeCtx);
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

immutable(AllLowFuns) getAllLowFuns(Alloc)(
	ref Alloc alloc,
	ref AllLowTypes allTypes,
	ref GetLowTypeCtx ctx,
	ref immutable ConcreteProgram program,
) {
	immutable LowType ctxType = lowTypeFromConcreteType(alloc, ctx, immutable ConcreteType(True, program.ctxType));
	DictBuilder!(Ptr!ConcreteFun, LowFunIndex, comparePtr!ConcreteFun) concreteFunToLowFunIndexBuilder;
	size_t lowFunIndex = 0;
	foreach (immutable Ptr!ConcreteFun fun; arrRange(program.allFuns)) {
		if (willMapToLowFun(body_(fun))) {
			addToDict(alloc, concreteFunToLowFunIndexBuilder, fun, immutable LowFunIndex(lowFunIndex));
			lowFunIndex++;
		}
	}

	ConcreteFunToLowFunIndex concreteFunToLowFunIndex =
		finishDictShouldBeNoConflict(alloc, concreteFunToLowFunIndexBuilder);

	immutable Arr!LowFun allLowFuns = mapOp(alloc, program.allFuns, (ref immutable Ptr!ConcreteFun cf) {
		if (willMapToLowFun(body_(cf))) {
			immutable LowType returnType = lowTypeFromConcreteType(alloc, ctx, cf.returnType);
			immutable Opt!LowParam ctxParam = cf.needsCtx
				? some(immutable LowParam(strLiteral("ctx"), ctxType))
				: none!LowParam;
			immutable Opt!LowParam closureParam = mapOption(cf.closureParam, (ref immutable ConcreteParam it) =>
				getLowParam(alloc, ctx, it));
			immutable Arr!LowParam params = mapWithOptFirst!(LowParam, ConcreteParam, Alloc)(
				alloc,
				ctxParam,
				closureParam,
				cf.paramsExcludingCtxAndClosure,
				(ref immutable ConcreteParam it) =>
					getLowParam(alloc, ctx, it));
			immutable Opt!(Ptr!LowParam) ctxParamPtr = has(ctxParam) ? some(ptrAt(params, 0)) : none!(Ptr!LowParam);
			immutable Opt!(Ptr!LowParam) closureParamPtr = has(cf.closureParam)
				? some(ptrAt(params, cf.needsCtx ? 1 : 0))
				: none!(Ptr!LowParam);
			immutable LowFunBody body_ = getLowFunBody(
				alloc,
				allTypes,
				concreteFunToLowFunIndex,
				ctxParamPtr,
				closureParamPtr,
				slice(params, (has(ctxParamPtr) ? 1 : 0) + (has(closureParamPtr) ? 1 : 0)),
				body_(cf));
			return some(immutable LowFun(cf.mangledName, returnType, params, body_));
		} else
			return none!LowFun;
	});

	assert(size(allLowFuns) == lowFunIndex);

	return immutable AllLowFuns(
		allLowFuns,
		todo!(immutable Ptr!LowFun)("getMain"));
}

immutable(LowParam) getLowParam(Alloc)(ref Alloc alloc, ref GetLowTypeCtx ctx, ref immutable ConcreteParam a) {
	return immutable LowParam(a.mangledName, lowTypeFromConcreteType(alloc, ctx, a.type));
}

immutable(LowLocal) getLowLocal(Alloc)(ref Alloc alloc, ref GetLowTypeCtx ctx, ref immutable ConcreteLocal a) {
	return immutable LowLocal(a.mangledName, lowTypeFromConcreteType(alloc, ctx, a.type));
}

// Builtins don't become functions, they are compiled inline.
immutable(Bool) willMapToLowFun(ref immutable ConcreteFunBody a) {
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

alias ConcreteFunToLowFunIndex = immutable Dict!(Ptr!ConcreteFun, LowFunIndex, comparePtr!ConcreteFun);

immutable(LowFunBody) getLowFunBody(Alloc)(
	ref Alloc alloc,
	ref AllLowTypes allTypes,
	ref immutable ConcreteFunToLowFunIndex concreteFunToLowFunIndex,
	immutable Opt!(Ptr!LowParam) ctxParam,
	immutable Opt!(Ptr!LowParam) closureParam,
	immutable Arr!(LowParam) otherParams,
	ref immutable ConcreteFunBody a,
) {
	return matchConcreteFunBody!(immutable LowFunBody)(
		a,
		(ref immutable ConcreteFunBody.Builtin it) {
			if (it.builtinInfo.emit == BuiltinFunEmit.generate) {
				// I think currently this is done in concretize, so we won't get here.
				// We *should* do that in lower though, not in concretize.
				return todo!(immutable LowFunBody)("getLowFunBody");
			} else
				return unreachable!(immutable LowFunBody);
		},
		(ref immutable ConcreteFunBody.Extern it) =>
			immutable LowFunBody(immutable LowFunBody.Extern(it.isGlobal)),
		(ref immutable ConcreteFunExprBody it) {
			GetLowExprCtx exprCtx = GetLowExprCtx(
				ptrTrustMe_mut(allTypes),
				concreteFunToLowFunIndex,
				ctxParam);
			foreach (immutable Ptr!ConcreteLocal local; arrRange(it.allLocals))
				add(alloc, exprCtx.locals, allocate(alloc, getLowLocal(alloc, allTypes.getLowTypeCtx, local)));
			immutable LowExpr expr = getLowExpr(alloc, exprCtx, it.expr);
			return immutable LowFunBody(immutable LowFunExprBody(finishArr(alloc, exprCtx.locals), expr));
		});
}

struct GetLowExprCtx {
	Ptr!AllLowTypes allTypes;
	ConcreteFunToLowFunIndex concreteFunToLowFunIndex;
	immutable Opt!(Ptr!LowParam) ctxParam;
	ArrBuilder!(Ptr!LowLocal) locals;
	size_t tempLocalIdx;
}

ref GetLowTypeCtx typeCtx(return scope ref GetLowExprCtx ctx) {
	return ctx.allTypes.getLowTypeCtx;
}

immutable(LowExpr) getCtxParam(Alloc)(ref Alloc alloc, ref const GetLowExprCtx ctx, ref immutable SourceRange range) {
	return immutable LowExpr(
		force(ctx.ctxParam).type,
		range,
		immutable LowExprKind(immutable LowExprKind.ParamRef(force(ctx.ctxParam))));
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
	return allocate(alloc, immutable LowLocal(finishWriter(writer), type));
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
			immutable LowExprKind(immutable LowExprKind.Cond(
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
		(ref immutable ConcreteExpr.LocalRef) =>
			todo!(immutable LowExprKind)("local-ref"),
		(ref immutable ConcreteExpr.Match) =>
			todo!(immutable LowExprKind)("match"),
		(ref immutable ConcreteExpr.ParamRef) =>
			todo!(immutable LowExprKind)("param-ref"),
		(ref immutable ConcreteExpr.RecordFieldAccess) =>
			todo!(immutable LowExprKind)("record-field-access"),
		(ref immutable ConcreteExpr.RecordFieldSet) =>
			todo!(immutable LowExprKind)("record-field-set"),
		(ref immutable ConcreteExpr.Seq) =>
			todo!(immutable LowExprKind)("seq"),
		(ref immutable ConcreteExpr.SpecialConstant) =>
			todo!(immutable LowExprKind)("special-constant"),
		(ref immutable ConcreteExpr.SpecialUnary) =>
			todo!(immutable LowExprKind)("special-unary"),
		(ref immutable ConcreteExpr.SpecialBinary) =>
			todo!(immutable LowExprKind)("special-binary"),
		(ref immutable ConcreteExpr.StringLiteral) =>
			todo!(immutable LowExprKind)("string-literal"));
}

immutable LowType nat64Type = immutable LowType(PrimitiveType.nat64);
immutable LowType anyPtrType = immutable LowType(immutable LowType.NonFunPtr(immutable Ptr!LowType(&nat64Type)));
immutable LowType voidType = immutable LowType(PrimitiveType.void_);

immutable(LowExpr) getSizeOf(immutable SourceRange range, immutable LowType t) {
	return immutable LowExpr(nat64Type, range, immutable LowExprKind(immutable LowExprKind.SizeOf(t)));
}

immutable(LowExpr) getAllocateExpr(Alloc)(
	ref Alloc alloc,
	ref GetLowExprCtx ctx,
	ref immutable SourceRange range,
	immutable Ptr!ConcreteFun allocFun,
	ref immutable LowType ptrType,
	ref immutable LowExpr size,
) {
	return immutable LowExpr(
		ptrType,
		range,
		immutable LowExprKind(immutable LowExprKind.Call(
			getLowFunIndex(ctx, allocFun),
			arrLiteral!LowExpr(alloc, getCtxParam(alloc, ctx, range), size))));
}

immutable(LowExpr) localRef(Alloc)(ref Alloc alloc, ref immutable SourceRange range, immutable Ptr!LowLocal local) {
	return immutable LowExpr(local.type, range, immutable LowExprKind(immutable LowExprKind.LocalRef(local)));
}

immutable(LowExpr) seq(Alloc)(
	ref Alloc alloc,
	ref immutable SourceRange range,
	immutable LowExpr first,
	immutable LowExpr then,
) {
	return immutable LowExpr(
		then.type,
		range,
		immutable LowExprKind(immutable LowExprKind.Seq(allocate(alloc, first), allocate(alloc, then))));
}

immutable(LowExprKind) getAllocExpr(Alloc)(
	ref Alloc alloc,
	ref GetLowExprCtx ctx,
	ref immutable SourceRange range,
	ref immutable ConcreteExpr.Alloc a,
) {
	// (temp0 = alloc(sizeof(T)), *temp0 = inner, temp0)
	immutable LowExpr inner = getLowExpr(alloc, ctx, a.inner);
	immutable LowType pointeeType = inner.type;
	immutable LowType ptrType = getLowPtrType(alloc, typeCtx(ctx), pointeeType);
	immutable Ptr!LowLocal local = addTempLocal(alloc, ctx, ptrType);
	immutable LowExpr sizeofT = getSizeOf(range, pointeeType);
	immutable LowExpr allocatePtr = getAllocateExpr!Alloc(alloc, ctx, range, a.alloc, ptrType, sizeofT);
	immutable Ptr!LowExpr getTemp = allocate(alloc, localRef(alloc, range, local));
	immutable LowExpr setTemp = immutable LowExpr(
		voidType,
		range,
		immutable LowExprKind(immutable LowExprKind.SpecialBinary(
			LowExprKind.SpecialBinary.Kind.writeToPtr,
			getTemp,
			allocate(alloc, inner))));
	return immutable LowExprKind(immutable LowExprKind.Let(
		local,
		allocate(alloc, allocatePtr),
		allocate(alloc, seq(alloc, range, setTemp, getTemp))));
}

immutable(LowExpr) constantNat64(
	ref immutable SourceRange range,
	immutable size_t value,
) {
	return immutable LowExpr(
		nat64Type,
		range,
		immutable LowExprKind(immutable LowExprKind.SpecialConstant(
			immutable LowExprKind.SpecialConstant.Nat(value))));
}

immutable(LowExpr) mulNat64(Alloc)(
	ref Alloc alloc,
	ref immutable SourceRange range,
	ref immutable LowExpr left,
	ref immutable LowExpr right,
) {
	return immutable LowExpr(
		nat64Type,
		range,
		immutable LowExprKind(immutable LowExprKind.SpecialBinary(
			LowExprKind.SpecialBinary.Kind.mulNat64,
			allocate(alloc, left),
			allocate(alloc, right))));
}

immutable(LowExprKind) getCallExpr(Alloc)(
	ref Alloc alloc,
	ref GetLowExprCtx ctx,
	ref immutable SourceRange range,
	ref immutable ConcreteExpr.Call a,
) {
	// A call isn't always a call!
	immutable Opt!LowFunIndex called = tryGetLowFunIndex(ctx, a.called);
	if (has(called))
		return immutable LowExprKind(immutable LowExprKind.Call(
			force(called),
			map(alloc, a.args, (ref immutable ConcreteExpr it) =>
				getLowExpr(alloc, ctx, it))));
	else {
		assert(!willMapToLowFun(body_(a.called)));
		immutable ConcreteFunBody.Builtin builtin = asBuiltin(body_(a.called));
		assert(builtin.builtinInfo.emit == BuiltinFunEmit.operator);
		return getOperatorCallExpr(alloc, ctx, range, builtin.builtinInfo.kind, a.args);
	}
}

immutable(LowExprKind) getOperatorCallExpr(Alloc)(
	ref Alloc alloc,
	ref GetLowExprCtx ctx,
	ref immutable SourceRange range,
	ref immutable BuiltinFunKind op,
	ref immutable Arr!ConcreteExpr args,
) {
	immutable(LowExpr) arg0() {
		return getLowExpr(alloc, ctx, at(args, 0));
	}
	immutable(LowExpr) arg1() {
		return getLowExpr(alloc, ctx, at(args, 1));
	}
	immutable(LowExprKind) binary(immutable LowExprKind.SpecialBinary.Kind kind) {
		assert(size(args) == 2);
		return immutable LowExprKind(immutable LowExprKind.SpecialBinary(
			kind,
			allocate(alloc, arg0()),
			allocate(alloc, arg1())));
	}

	switch (op) {
		case BuiltinFunKind.and:
			return binary(LowExprKind.SpecialBinary.Kind.add);
		case BuiltinFunKind.as:
			assert(size(args) == 1);
			return arg0().kind;
		case BuiltinFunKind.bitShiftLeftInt32:
			return binary(LowExprKind.SpecialBinary.Kind.bitShiftLeftInt32);
		default: // TODO: use final switch, no default
			return todo!(immutable LowExprKind)("OPERATORS!");
	}

}

immutable(LowExprKind) getCreateArrExpr(Alloc)(
	ref Alloc alloc,
	ref GetLowExprCtx ctx,
	ref immutable SourceRange range,
	ref immutable ConcreteExpr.CreateArr a,
) {
	// (arr = arr_foo{2, _alloc(ctx, sizeof(foo) * 2)},
	//  arr.data[0] = a,
	//  arr.data[1] = b,
	//  arr)
	immutable LowType arrType = lowTypeFromConcreteStruct(alloc, typeCtx(ctx), a.arrType);
	immutable LowType elementType = lowTypeFromConcreteType(alloc, typeCtx(ctx), a.elementType);
	immutable LowType elementPtrType = getLowPtrType(alloc, typeCtx(ctx), elementType);
	immutable LowExpr elementSize = getSizeOf(range, elementType);
	immutable LowExpr nElements = constantNat64(range, size(a.args));
	immutable LowExpr sizeBytes = mulNat64(alloc, range, elementSize, nElements);
	immutable LowExpr allocatePtr = getAllocateExpr(alloc, ctx, range, a.alloc, elementPtrType, sizeBytes);
	immutable LowExpr createArr = immutable LowExpr(
		arrType,
		range,
		immutable LowExprKind(immutable LowExprKind.CreateRecord(
			arrLiteral!LowExpr(alloc, nElements, allocatePtr))));
	immutable Ptr!LowLocal temp = addTempLocal(alloc, ctx, arrType);

	immutable(LowExpr) recur(immutable LowExpr cur, immutable size_t index) {
		if (index == 0)
			return cur;
		else {
			immutable LowExpr arg = getLowExpr(alloc, ctx, at(a.args, index - 1));
			return recur(seq(alloc, range, arg, cur), index - 1);
		}
	}
	immutable LowExpr assignAndGetArr = recur(localRef(alloc, range, temp), size(a.args));
	return immutable LowExprKind(immutable LowExprKind.Let(
		temp,
		allocate(alloc, createArr),
		allocate(alloc, assignAndGetArr)));
}

immutable(LowExprKind) getLambdaExpr(Alloc)(
	ref Alloc alloc,
	ref GetLowExprCtx ctx,
	ref immutable LowType type,
	ref immutable SourceRange range,
	ref immutable ConcreteExpr.Lambda a,
) {
	immutable LowFunIndex lambdaFun = getLowFunIndex(ctx, a.fun);
	immutable LowExprKind funPtr  = immutable LowExprKind(immutable LowExprKind.FunPtr(lambdaFun));
	immutable LowType funPtrType = immutable LowType(asFunPtrType(type));
	if (!has(a.closure))
		return funPtr;
	else {
		immutable LowExpr closure = getLowExpr(alloc, ctx, force(a.closure));
		immutable Arr!LowExpr args = arrLiteral!LowExpr(alloc,
			immutable LowExpr(funPtrType, range, funPtr),
			closure);
		return immutable LowExprKind(immutable LowExprKind.CreateRecord(args));
	}
}

immutable(LowExprKind) getLetExpr(Alloc)(
	ref Alloc alloc,
	ref GetLowExprCtx ctx,
	ref immutable SourceRange range,
	ref immutable ConcreteExpr.Let a,
) {
	immutable size_t localIndex = a.local.index;
	immutable Ptr!LowLocal local = arrBuilderAt(ctx.locals, localIndex);
	assert(strEq(local.mangledName, a.local.mangledName));
	return immutable LowExprKind(immutable LowExprKind.Let(
		local,
		allocate(alloc, getLowExpr(alloc, ctx, a.value)),
		allocate(alloc, getLowExpr(alloc, ctx, a.then))));
}
