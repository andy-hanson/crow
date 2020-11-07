module concretize.concretizeExpr;

@safe @nogc pure nothrow:

import concreteModel :
	asRecord,
	body_,
	byRef,
	byVal,
	ConcreteExpr,
	ConcreteField,
	ConcreteFieldSource,
	ConcreteFun,
	ConcreteFunBody,
	ConcreteFunExprBody,
	ConcreteLocal,
	ConcreteLocalSource,
	ConcreteParam,
	ConcreteParamSource,
	ConcreteStruct,
	ConcreteStructBody,
	ConcreteStructSource,
	ConcreteType,
	concreteType_byValue,
	mustBeNonPointer,
	name,
	returnType;
import concretize.concretizeCtx :
	anyPtrType,
	boolType,
	charType,
	ConcretizeCtx,
	ConcreteFunKey,
	ConcreteFunBodyInputs,
	concreteTypeFromFields_alwaysPointer,
	concretizeParams,
	getAllocFun,
	getConcreteType_fromConcretizeCtx = getConcreteType,
	getConcreteType_forStructInst_fromConcretizeCtx = getConcreteType_forStructInst,
	getGetVatAndActorFun,
	getOrAddConcreteFunAndFillBody,
	getConcreteFunForLambdaAndFillBody,
	specImpls,
	typeArgsScope,
	TypeArgsScope,
	typesToConcreteTypes_fromConcretizeCtx = typesToConcreteTypes,
	voidType;
import model :
	Called,
	ClosureField,
	elementType,
	Expr,
	FunInst,
	FunKind,
	Local,
	matchCalled,
	matchExpr,
	range,
	RecordField,
	specImpls,
	SpecSig,
	StructInst,
	Type,
	typeArgs;
import util.bools : Bool, False;
import util.collection.arr : Arr, at, empty, emptyArr, ptrAt, size;
import util.collection.arrBuilder : add, ArrBuilder, arrBuilderSize, finishArr;
import util.collection.arrUtil : arrLiteral, map, mapWithIndex;
import util.collection.mutDict : addToMutDict, mustDelete, mustGetAt_mut, MutDict;
import util.collection.str : copyStr;
import util.memory : allocate, nu;
import util.opt : force, forcePtr, has, none, Opt, some;
import util.ptr : comparePtr, Ptr, ptrEquals, ptrTrustMe, ptrTrustMe_mut;
import util.sourceRange : FileAndRange;
import util.sym : shortSymAlphaLiteral, symEq, symEqLongAlphaLiteral;
import util.types : safeSizeTToU8;
import util.util : unreachable, verify;

immutable(ConcreteFunBody) concretizeExpr(Alloc)(
	ref Alloc alloc,
	ref ConcretizeCtx ctx,
	ref immutable ConcreteFunBodyInputs inputs,
	immutable Ptr!ConcreteFun cf,
	ref immutable Expr e,
) {
	ConcretizeExprCtx exprCtx = ConcretizeExprCtx(ptrTrustMe_mut(ctx), inputs, cf, False);
	immutable ConcreteExpr res = concretizeExpr(alloc, exprCtx, e);
	return immutable ConcreteFunBody(
		immutable ConcreteFunExprBody(
			finishArr(alloc, exprCtx.allLocalsInThisFun),
			allocExpr(alloc, res)));
}

immutable(Ptr!ConcreteExpr) allocExpr(Alloc)(ref Alloc alloc, immutable ConcreteExpr e) {
	return allocate(alloc, e);
}

private:

struct ConcretizeExprCtx {
	Ptr!ConcretizeCtx concretizeCtx;
	immutable ConcreteFunBodyInputs concreteFunBodyInputs;
	immutable Ptr!ConcreteFun currentConcreteFun; // This is the ConcreteFun* for a lambda, not its containing fun
	size_t nextLambdaIndex = 0;

	// Note: this dict contains only the locals that are currently in scope.
	MutDict!(immutable Ptr!Local, immutable Ptr!ConcreteLocal, comparePtr!Local) locals;
	// Contains *all* locals
	ArrBuilder!(Ptr!ConcreteLocal) allLocalsInThisFun;
}

immutable(ConcreteType) getConcreteType(Alloc)(ref Alloc alloc, ref ConcretizeExprCtx ctx, ref immutable Type t) {
	immutable TypeArgsScope s = typeScope(ctx);
	return getConcreteType_fromConcretizeCtx(alloc, ctx.concretizeCtx.deref, t, s);
}

immutable(ConcreteType) getConcreteType_forStructInst(Alloc)(
	ref Alloc alloc,
	ref ConcretizeExprCtx ctx,
	immutable Ptr!StructInst i,
) {
	immutable TypeArgsScope s = typeScope(ctx);
	return getConcreteType_forStructInst_fromConcretizeCtx(alloc, ctx.concretizeCtx, i, s);
}

immutable(Arr!ConcreteType) typesToConcreteTypes(Alloc)(
	ref Alloc alloc,
	ref ConcretizeExprCtx ctx,
	immutable Arr!Type typeArgs,
) {
	immutable TypeArgsScope s = typeScope(ctx);
	return typesToConcreteTypes_fromConcretizeCtx(alloc, ctx.concretizeCtx, typeArgs, s);
}

immutable(TypeArgsScope) typeScope(ref ConcretizeExprCtx ctx) {
	return typeArgsScope(ctx.concreteFunBodyInputs);
}

immutable(ConcreteExpr) concretizeCall(Alloc)(
	ref Alloc alloc,
	ref ConcretizeExprCtx ctx,
	ref immutable FileAndRange range,
	ref immutable Expr.Call e,
) {
	immutable Ptr!ConcreteFun concreteCalled = getConcreteFunFromCalled(alloc, ctx, e.called);
	immutable Arr!ConcreteExpr args = getArgs(alloc, ctx, e.args);
	return immutable ConcreteExpr(concreteCalled.returnType, range, immutable ConcreteExpr.Call(concreteCalled, args));
}

immutable(Ptr!ConcreteFun) getConcreteFunFromCalled(Alloc)(
	ref Alloc alloc,
	ref ConcretizeExprCtx ctx,
	ref immutable Called called,
) {
	return matchCalled(
		called,
		(immutable Ptr!FunInst funInst) =>
			getConcreteFunFromFunInst(alloc, ctx, funInst),
		(ref immutable SpecSig specSig) =>
			at(specImpls(ctx.concreteFunBodyInputs), specSig.indexOverAllSpecUses));
}

immutable(Ptr!ConcreteFun) getConcreteFunFromFunInst(Alloc)(
	ref Alloc alloc,
	ref ConcretizeExprCtx ctx,
	immutable Ptr!FunInst funInst,
) {
	immutable Arr!ConcreteType typeArgs = typesToConcreteTypes(alloc, ctx, typeArgs(funInst.deref));
	immutable Arr!(Ptr!ConcreteFun) specImpls = map!(Ptr!ConcreteFun)(
		alloc,
		specImpls(funInst),
		(ref immutable Called it) => getConcreteFunFromCalled(alloc, ctx, it));
	immutable ConcreteFunKey key = immutable ConcreteFunKey(funInst, typeArgs, specImpls);
	return getOrAddConcreteFunAndFillBody(alloc, ctx.concretizeCtx, key);
}

immutable(ConcreteExpr) concretizeClosureFieldRef(Alloc)(
	ref Alloc alloc,
	ref ConcretizeExprCtx ctx,
	ref immutable FileAndRange range,
	ref immutable Expr.ClosureFieldRef e,
) {
	immutable Ptr!ConcreteParam closureParam = forcePtr(ptrTrustMe(ctx.currentConcreteFun.closureParam));
	immutable ConcreteType closureType = closureParam.type;
	immutable ConcreteStructBody.Record record = asRecord(body_(closureType.struct_));
	immutable Ptr!ConcreteField field = ptrAt(record.fields, e.field.index);
	immutable ConcreteExpr closureParamRef = immutable ConcreteExpr(
		closureType,
		range,
		immutable ConcreteExpr.ParamRef(closureParam));
	return immutable ConcreteExpr(
		field.type,
		range,
		immutable ConcreteExpr.RecordFieldAccess(allocExpr(alloc, closureParamRef), field));
}

immutable(Arr!ConcreteExpr) getArgs(Alloc)(
	ref Alloc alloc,
	ref ConcretizeExprCtx ctx,
	ref immutable Arr!Expr argExprs,
) {
	return map!ConcreteExpr(alloc, argExprs, (ref immutable Expr arg) =>
		concretizeExpr(alloc, ctx, arg));
}

immutable(ConcreteExpr) createAllocExpr(Alloc)(
	ref Alloc alloc,
	ref ConcretizeCtx ctx,
	immutable ConcreteExpr inner,
) {
	verify(!inner.type.isPointer);
	return immutable ConcreteExpr(
		byRef(inner.type),
		inner.range,
		immutable ConcreteExpr.Alloc(getAllocFun(alloc, ctx), allocExpr(alloc, inner)));
}

immutable(ConcreteExpr) concretizeCreateRecord(Alloc)(
	ref Alloc alloc,
	ref ConcretizeExprCtx ctx,
	ref immutable FileAndRange range,
	ref immutable Expr.CreateRecord e,
) {
	immutable ConcreteType type = getConcreteType_forStructInst(alloc, ctx, e.structInst);
	immutable ConcreteExpr value = immutable ConcreteExpr(
		byVal(type),
		range,
		immutable ConcreteExpr.CreateRecord(getArgs(alloc, ctx, e.args)));
	return type.isPointer
		? createAllocExpr(alloc, ctx.concretizeCtx, value)
		: value;
}

immutable(ConcreteExpr) getGetVatAndActor(Alloc)(
	ref Alloc alloc,
	ref ConcretizeExprCtx ctx,
	ref immutable ConcreteType type,
	ref immutable FileAndRange range,
) {
	return immutable ConcreteExpr(
		type,
		range,
		immutable ConcreteExpr.Call(getGetVatAndActorFun(alloc, ctx.concretizeCtx), emptyArr!ConcreteExpr));
}

immutable(Arr!ConcreteField) concretizeClosureFields(Alloc)(
	ref Alloc alloc,
	ref ConcretizeCtx ctx,
	ref immutable Arr!(Ptr!ClosureField) closure,
	ref immutable TypeArgsScope typeArgsScope,
) {
	return mapWithIndex!ConcreteField(alloc, closure, (immutable size_t index, ref immutable Ptr!ClosureField it) =>
		immutable ConcreteField(
			immutable ConcreteFieldSource(it),
			safeSizeTToU8(index),
			False,
			getConcreteType_fromConcretizeCtx(alloc, ctx, it.type, typeArgsScope)));
}

immutable(ConcreteExpr) concretizeLambda(Alloc)(
	ref Alloc alloc,
	ref ConcretizeExprCtx ctx,
	ref immutable FileAndRange range,
	ref immutable Expr.Lambda e,
) {
	immutable size_t lambdaIndex = ctx.nextLambdaIndex;
	ctx.nextLambdaIndex++;

	immutable TypeArgsScope tScope = typeScope(ctx);
	immutable Arr!ConcreteParam params = concretizeParams(alloc, ctx.concretizeCtx, e.params, tScope);
	immutable Arr!ConcreteExpr closureArgs = map!ConcreteExpr(alloc, e.closure, (ref immutable Ptr!ClosureField f) =>
		concretizeExpr(alloc, ctx, f.expr));
	immutable Arr!ConcreteField closureFields = concretizeClosureFields(alloc, ctx.concretizeCtx, e.closure, tScope);
	immutable Opt!ConcreteType closureType = e.kind == FunKind.ptr
		? none!ConcreteType
		: some!ConcreteType(empty(closureArgs)
			? anyPtrType(alloc, ctx.concretizeCtx)
			: concreteTypeFromFields_alwaysPointer(
				alloc,
				ctx.concretizeCtx,
				closureFields,
				immutable ConcreteStructSource(
					immutable ConcreteStructSource.Lambda(ctx.currentConcreteFun, lambdaIndex))));
	immutable Opt!ConcreteParam closureParam = has(closureType)
		? some(immutable ConcreteParam(
			immutable ConcreteParamSource(immutable ConcreteParamSource.Closure()),
			none!size_t,
			force(closureType)))
		: none!ConcreteParam;
	immutable Opt!(Ptr!ConcreteExpr) closure = e.kind == FunKind.ptr
		? none!(Ptr!ConcreteExpr)
		: some!(Ptr!ConcreteExpr)(
			empty(closureArgs)
				? allocExpr(alloc, immutable ConcreteExpr(
					byRef(boolType(alloc, ctx.concretizeCtx)),
					range,
					immutable ConcreteExpr.Call(
						getNullAnyPtrFun(alloc, ctx),
						emptyArr!ConcreteExpr)))
				: allocExpr(alloc, createAllocExpr(alloc, ctx.concretizeCtx, immutable ConcreteExpr(
					byVal(force(closureType)),
					range,
					immutable ConcreteExpr.CreateRecord(closureArgs)))));

	immutable ConcreteType possiblySendType = getConcreteType_forStructInst(alloc, ctx, e.type);
	// For a fun-ref this is the inner fun-mut type.
	immutable ConcreteType funType = e.kind == FunKind.ref_
		? () {
			immutable Arr!ConcreteField fields = asRecord(body_(possiblySendType.struct_)).fields;
			verify(size(fields) == 2);
			immutable ConcreteField funField = at(fields, 1);
			verify(symEq(name(funField), shortSymAlphaLiteral("fun")));
			return funField.type;
		}()
		: possiblySendType;

	immutable Ptr!ConcreteFun fun = getConcreteFunForLambdaAndFillBody(
		alloc,
		ctx.concretizeCtx,
		immutable Bool(e.kind != FunKind.ptr),
		ctx.currentConcreteFun,
		lambdaIndex,
		getConcreteType(alloc, ctx, e.returnType),
		closureParam,
		params,
		ctx.concreteFunBodyInputs.containingConcreteFunKey,
		ptrTrustMe(e.body_));
	immutable ConcreteExpr res = immutable ConcreteExpr(funType, range, immutable ConcreteExpr.Lambda(fun, closure));

	if (e.kind == FunKind.ref_) {
		immutable ConcreteField vatAndActorField = at(asRecord(body_(possiblySendType.struct_)).fields, 0);
		verify(symEqLongAlphaLiteral(name(vatAndActorField), "vat-and-actor"));
		immutable ConcreteExpr vatAndActor = getGetVatAndActor(alloc, ctx, vatAndActorField.type, range);
		return immutable ConcreteExpr(
			possiblySendType,
			range,
			immutable ConcreteExpr.CreateRecord(arrLiteral!ConcreteExpr(alloc, vatAndActor, res)));
	} else
		return res;
}

immutable(Ptr!ConcreteFun) getNullAnyPtrFun(Alloc)(ref Alloc alloc, ref ConcretizeExprCtx ctx) {
	return getConcreteFunFromFunInst(alloc, ctx, ctx.concretizeCtx.nullAnyPtrFun);
}

immutable(Ptr!ConcreteLocal) makeLocalWorker(Alloc)(
	ref Alloc alloc,
	ref ConcretizeExprCtx ctx,
	immutable ConcreteLocalSource source,
	immutable ConcreteType type,
) {
	immutable Ptr!ConcreteLocal res = nu!ConcreteLocal(
		alloc,
		source,
		arrBuilderSize(ctx.allLocalsInThisFun),
		type);
	add(alloc, ctx.allLocalsInThisFun, res);
	return res;
}

immutable(Ptr!ConcreteLocal) concretizeLocal(Alloc)(
	ref Alloc alloc,
	ref ConcretizeExprCtx ctx,
	immutable Ptr!Local local,
) {
	return makeLocalWorker(alloc, ctx, immutable ConcreteLocalSource(local), getConcreteType(alloc, ctx, local.type));
}

immutable(Ptr!ConcreteLocal) getMatchedLocal(Alloc)(
	ref Alloc alloc,
	ref ConcretizeExprCtx ctx,
	immutable Ptr!ConcreteStruct matchedUnion,
) {
	return makeLocalWorker(
		alloc,
		ctx,
		immutable ConcreteLocalSource(immutable ConcreteLocalSource.Matched()),
		concreteType_byValue(matchedUnion));
}

immutable(ConcreteExpr) concretizeWithLocal(Alloc)(
	ref Alloc alloc,
	ref ConcretizeExprCtx ctx,
	immutable Ptr!Local modelLocal,
	immutable Ptr!ConcreteLocal concreteLocal,
	ref immutable Expr expr,
) {
	addToMutDict(alloc, ctx.locals, modelLocal, concreteLocal);
	immutable ConcreteExpr res = concretizeExpr(alloc, ctx, expr);
	immutable Ptr!ConcreteLocal cl2 = mustDelete(ctx.locals, modelLocal);
	verify(ptrEquals(cl2, concreteLocal));
	return res;
}

immutable(ConcreteExpr) concretizeLet(Alloc)(
	ref Alloc alloc,
	ref ConcretizeExprCtx ctx,
	ref immutable FileAndRange range,
	ref immutable Expr.Let e,
) {
	immutable Ptr!ConcreteExpr value = allocExpr(alloc, concretizeExpr(alloc, ctx, e.value));
	immutable Ptr!ConcreteLocal local = concretizeLocal(alloc, ctx, e.local);
	immutable Ptr!ConcreteExpr then = allocExpr(alloc, concretizeWithLocal(alloc, ctx, e.local, local, e.then));
	return immutable ConcreteExpr(then.type, range, immutable ConcreteExpr.Let(local, value, then));
}

immutable(ConcreteExpr) concretizeMatch(Alloc)(
	ref Alloc alloc,
	ref ConcretizeExprCtx ctx,
	ref immutable FileAndRange range,
	ref immutable Expr.Match e,
) {
	immutable ConcreteExpr matched = concretizeExpr(alloc, ctx, e.matched);
	immutable Ptr!ConcreteStruct matchedUnion =
		mustBeNonPointer(getConcreteType_forStructInst(alloc, ctx, e.matchedUnion));
	immutable ConcreteType type = getConcreteType(alloc, ctx, e.type);
	immutable Arr!(ConcreteExpr.Match.Case) cases = map!(ConcreteExpr.Match.Case)(
		alloc,
		e.cases,
		(ref immutable Expr.Match.Case case_) {
			if (has(case_.local)) {
				immutable Ptr!ConcreteLocal local = concretizeLocal(alloc, ctx, force(case_.local));
				immutable ConcreteExpr then = concretizeWithLocal(alloc, ctx, force(case_.local), local, case_.then);
				return immutable ConcreteExpr.Match.Case(some(local), then);
			} else
				return immutable ConcreteExpr.Match.Case(
					none!(Ptr!ConcreteLocal),
					concretizeExpr(alloc, ctx, case_.then));
		});
	return immutable ConcreteExpr(
		type,
		range,
		immutable ConcreteExpr.Match(getMatchedLocal(alloc, ctx, matchedUnion), allocExpr(alloc, matched), cases));
}

immutable(ConcreteExpr) concretizeParamRef(Alloc)(
	ref Alloc alloc,
	ref ConcretizeExprCtx ctx,
	ref immutable FileAndRange range,
	ref immutable Expr.ParamRef e,
) {
	immutable size_t paramIndex = e.param.index;
	// NOTE: we'll never see a ParamRef to a param from outside of a lambda --
	// that would be a ClosureFieldRef instead.
	immutable Ptr!ConcreteParam concreteParam = ptrAt(ctx.currentConcreteFun.paramsExcludingCtxAndClosure, paramIndex);
	return immutable ConcreteExpr(concreteParam.type, range, immutable ConcreteExpr.ParamRef(concreteParam));
}

immutable(Ptr!ConcreteField) getMatchingField(immutable Ptr!ConcreteStruct struct_, immutable size_t fieldIndex) {
	return ptrAt(asRecord(body_(struct_)).fields, fieldIndex);
}

immutable(Ptr!ConcreteField) getMatchingField(Alloc)(
	ref Alloc alloc,
	ref const ConcretizeExprCtx ctx,
	immutable Ptr!StructInst targetType,
	immutable Ptr!RecordField field,
) {
	immutable ConcreteType type = getConcreteType_forStructInst(alloc, ctx, targetType);
	return getMatchingField(type, field.index);
}

immutable(ConcreteExpr) concretizeRecordFieldAccess(Alloc)(
	ref Alloc alloc,
	ref ConcretizeExprCtx ctx,
	ref immutable FileAndRange range,
	ref immutable Expr.RecordFieldAccess e,
) {
	immutable Ptr!ConcreteExpr target = allocExpr(alloc, concretizeExpr(alloc, ctx, e.target));
	immutable ConcreteType targetType = getConcreteType_forStructInst(alloc, ctx, e.targetType);
	immutable Ptr!ConcreteField field = getMatchingField(targetType.struct_, e.field.index);
	return immutable ConcreteExpr(
		field.type,
		range,
		immutable ConcreteExpr.RecordFieldAccess(target, field));
}

immutable(ConcreteExpr) concretizeRecordFieldSet(Alloc)(
	ref Alloc alloc,
	ref ConcretizeExprCtx ctx,
	ref immutable FileAndRange range,
	ref immutable Expr.RecordFieldSet e,
) {
	immutable Ptr!ConcreteExpr target = allocExpr(alloc, concretizeExpr(alloc, ctx, e.target));
	immutable ConcreteType targetType = getConcreteType_forStructInst(alloc, ctx, e.targetType);
	verify(targetType.isPointer); // If we're mutating it, it should be by reference.
	immutable Ptr!ConcreteField field = getMatchingField(targetType.struct_, e.field.index);
	immutable Ptr!ConcreteExpr value = allocExpr(alloc, concretizeExpr(alloc, ctx, e.value));
	immutable ConcreteType voidType = voidType(alloc, ctx.concretizeCtx);
	return immutable ConcreteExpr(
		voidType,
		range,
		immutable ConcreteExpr.RecordFieldSet(target, field, value));
}

immutable(ConcreteExpr) concretizeExpr(Alloc)(
	ref Alloc alloc,
	ref ConcretizeExprCtx ctx,
	ref immutable Expr e,
) {
	immutable FileAndRange range = range(e);
	return matchExpr(
		e,
		(ref immutable Expr.Bogus) =>
			unreachable!(immutable ConcreteExpr),
		(ref immutable Expr.Call e) =>
			concretizeCall(alloc, ctx, range, e),
		(ref immutable Expr.ClosureFieldRef e) =>
			concretizeClosureFieldRef(alloc, ctx, range, e),
		(ref immutable Expr.Cond e) =>
			immutable ConcreteExpr(
				getConcreteType(alloc, ctx, e.type),
				range,
				immutable ConcreteExpr.Cond(
					allocExpr(alloc, concretizeExpr(alloc, ctx, e.cond)),
					allocExpr(alloc, concretizeExpr(alloc, ctx, e.then)),
					allocExpr(alloc, concretizeExpr(alloc, ctx, e.else_)))),
		(ref immutable Expr.CreateArr e) {
			immutable Arr!ConcreteExpr args = getArgs(alloc, ctx, e.args);
			immutable ConcreteType arrayType = getConcreteType_forStructInst(alloc, ctx, e.arrType);
			immutable Ptr!ConcreteStruct arrayStruct = mustBeNonPointer(arrayType);
			immutable ConcreteType elementType = getConcreteType(alloc, ctx, elementType(e));
			immutable Ptr!ConcreteLocal local = makeLocalWorker(
				alloc,
				ctx,
				immutable ConcreteLocalSource(immutable ConcreteLocalSource.Arr()),
				arrayType);
			return immutable ConcreteExpr(
				arrayType,
				range,
				immutable ConcreteExpr.CreateArr(
					arrayStruct,
					elementType,
					getAllocFun(alloc, ctx.concretizeCtx),
					local,
					args));
		},
		(ref immutable Expr.CreateRecord e) =>
			concretizeCreateRecord(alloc, ctx, range, e),
		(ref immutable Expr.ImplicitConvertToUnion e) {
			immutable ConcreteExpr inner = concretizeExpr(alloc, ctx, e.inner);
			immutable ConcreteType unionType = getConcreteType_forStructInst(alloc, ctx, e.unionType);
			return immutable ConcreteExpr(
				unionType,
				range,
				immutable ConcreteExpr.ConvertToUnion(e.memberIndex, allocExpr(alloc, inner)));
		},
		(ref immutable Expr.Lambda e) =>
			concretizeLambda(alloc, ctx, range, e),
		(ref immutable Expr.Let e) =>
			concretizeLet(alloc, ctx, range, e),
		(ref immutable Expr.LocalRef e) {
			immutable Ptr!ConcreteLocal let = mustGetAt_mut(ctx.locals, e.local);
			return immutable ConcreteExpr(let.type, range, immutable ConcreteExpr.LocalRef(let));
		},
		(ref immutable Expr.Match e) =>
			concretizeMatch(alloc, ctx, range, e),
		(ref immutable Expr.ParamRef e) =>
			concretizeParamRef(alloc, ctx, range, e),
		(ref immutable Expr.RecordFieldAccess e) =>
			concretizeRecordFieldAccess(alloc, ctx, range, e),
		(ref immutable Expr.RecordFieldSet e) =>
			concretizeRecordFieldSet(alloc, ctx, range, e),
		(ref immutable Expr.Seq e) {
			immutable ConcreteExpr first = concretizeExpr(alloc, ctx, e.first);
			immutable ConcreteExpr then = concretizeExpr(alloc, ctx, e.then);
			return immutable ConcreteExpr(
				then.type,
				range,
				immutable ConcreteExpr.Seq(allocExpr(alloc, first), allocExpr(alloc, then)));
		},
		(ref immutable Expr.StringLiteral e) {
			immutable ConcreteType charType = charType(alloc, ctx.concretizeCtx);
			//TODO: Use ctx->concretizeCtx->strType() like we do for char
			immutable ConcreteType strType =
				getConcreteType_forStructInst(alloc, ctx, ctx.concretizeCtx.commonTypes.str);
			return immutable ConcreteExpr(
				strType,
				range,
				immutable ConcreteExpr.StringLiteral(copyStr(alloc, e.literal)));
		});
}

