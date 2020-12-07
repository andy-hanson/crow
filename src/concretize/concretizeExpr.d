module concretize.concretizeExpr;

@safe @nogc pure nothrow:

import concretize.allConstantsBuilder : getConstantArr, getConstantStr;
import concretize.concretizeCtx :
	anyPtrType,
	boolType,
	charType,
	ConcretizeCtx,
	ConcreteFunKey,
	ConcreteFunBodyInputs,
	concreteTypeFromFields_alwaysPointer,
	concretizeParams,
	getConcreteType_fromConcretizeCtx = getConcreteType,
	getConcreteType_forStructInst_fromConcretizeCtx = getConcreteType_forStructInst,
	getGetVatAndActorFun,
	getOrAddConcreteFunAndFillBody,
	getConcreteFunForLambdaAndFillBody,
	specImpls,
	typeArgsScope,
	TypeArgsScope,
	typesToConcreteTypes_fromConcretizeCtx = typesToConcreteTypes;
import model.concreteModel :
	asConstant,
	asRecord,
	asUnion,
	body_,
	byRef,
	byVal,
	ConcreteExpr,
	ConcreteExprKind,
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
	isConstant,
	isSummon,
	mustBeNonPointer,
	name,
	purity,
	returnType;
import model.constant : asBool, asRecord, asUnion, Constant;
import model.model :
	Called,
	ClosureField,
	elementType,
	Expr,
	FunInst,
	FunKind,
	Local,
	matchCalled,
	matchExpr,
	Purity,
	range,
	RecordField,
	specImpls,
	SpecSig,
	StructInst,
	Type,
	typeArgs;
import util.bools : Bool, False, True;
import util.collection.arr : Arr, at, empty, emptyArr, ptrAt, size;
import util.collection.arrUtil : arrLiteral, every, map, mapWithIndex;
import util.collection.mutDict : addToMutDict, mustDelete, mustGetAt_mut, MutDict;
import util.memory : allocate, nu;
import util.opt : force, forcePtr, has, none, Opt, some;
import util.ptr : comparePtr, Ptr, ptrTrustMe, ptrTrustMe_mut;
import util.sourceRange : FileAndRange;
import util.sym : shortSymAlphaLiteral, symEq, symEqLongAlphaLiteral;
import util.types : safeSizeTToU8;
import util.util : todo, unreachable, verify;

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
		immutable ConcreteFunExprBody(allocExpr(alloc, res)));
}

immutable(Ptr!ConcreteExpr) allocExpr(Alloc)(ref Alloc alloc, immutable ConcreteExpr e) {
	return allocate(alloc, e);
}

private:

// TODO: command line flag? (default to true)
immutable Bool inlineConstants = True;

struct ConcretizeExprCtx {
	Ptr!ConcretizeCtx concretizeCtx;
	immutable ConcreteFunBodyInputs concreteFunBodyInputs;
	immutable Ptr!ConcreteFun currentConcreteFun; // This is the ConcreteFun* for a lambda, not its containing fun
	size_t nextLambdaIndex = 0;
	size_t nextLocalIndex = 0;

	// Contains only the locals that are currently in scope.
	MutDict!(immutable Ptr!Local, immutable LocalOrConstant, comparePtr!Local) locals;
}

struct TypedConstant {
	immutable ConcreteType type;
	immutable Constant value;
}

struct LocalOrConstant {
	@safe @nogc pure nothrow:

	@trusted immutable this(immutable Ptr!ConcreteLocal a) { kind_ = Kind.local; local_ = a; }
	@trusted immutable this(immutable TypedConstant a) { kind_ = Kind.typedConstant; typedConstant_ = a; }

	private:
	enum Kind {
		local,
		typedConstant,
	}
	immutable Kind kind_;
	union {
		immutable Ptr!ConcreteLocal local_;
		immutable TypedConstant typedConstant_;
	}
}

@trusted T matchLocalOrConstant(T)(
	ref immutable LocalOrConstant a,
	scope T delegate(immutable Ptr!ConcreteLocal) @safe @nogc pure nothrow cbLocal,
	scope T delegate(ref immutable TypedConstant) @safe @nogc pure nothrow cbTypedConstant,
) {
	final switch (a.kind_) {
		case LocalOrConstant.Kind.local:
			return cbLocal(a.local_);
		case LocalOrConstant.Kind.typedConstant:
			return cbTypedConstant(a.typedConstant_);
	}
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
	immutable ConstantsOrExprs args =
		!isSummon(concreteCalled) && purity(concreteCalled.returnType) == Purity.data && false // TODO
			? getConstantsOrExprs(alloc, ctx, e.args)
			: immutable ConstantsOrExprs(getArgs(alloc, ctx, e.args));
	return matchConstantsOrExprs!(immutable ConcreteExpr)(
		args,
		(ref immutable Arr!Constant constants) => immutable ConcreteExpr(
			concreteCalled.returnType,
			range,
			immutable ConcreteExprKind(evalConstant(concreteCalled, constants))),
		(ref immutable Arr!ConcreteExpr exprs) => immutable ConcreteExpr(
			concreteCalled.returnType,
			range,
			immutable ConcreteExprKind(immutable ConcreteExprKind.Call(concreteCalled, exprs))));
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
	immutable ConcreteExpr closureParamRef = immutable ConcreteExpr(closureType, range, immutable ConcreteExprKind(
		immutable ConcreteExprKind.ParamRef(closureParam)));
	return immutable ConcreteExpr(field.type, range, immutable ConcreteExprKind(
		immutable ConcreteExprKind.RecordFieldGet(allocExpr(alloc, closureParamRef), field)));
}

struct ConstantsOrExprs {
	@safe @nogc pure nothrow:

	@trusted immutable this(immutable Arr!Constant a) {
		verify(inlineConstants);
		kind_ = Kind.constants;
		constants = a;
	}
	@trusted immutable this(immutable Arr!ConcreteExpr a) { kind_ = Kind.exprs; exprs = a; }

	private:
	enum Kind {
		constants,
		exprs,
	}
	immutable Kind kind_;
	union {
		immutable Arr!Constant constants;
		immutable Arr!ConcreteExpr exprs;
	}
}

@trusted T matchConstantsOrExprs(T)(
	ref immutable ConstantsOrExprs a,
	scope T delegate(ref immutable Arr!Constant) @safe @nogc pure nothrow cbConstants,
	scope T delegate(ref immutable Arr!ConcreteExpr) @safe @nogc pure nothrow cbExprs,
) {
	final switch (a.kind_) {
		case ConstantsOrExprs.Kind.constants:
			return cbConstants(a.constants);
		case ConstantsOrExprs.Kind.exprs:
			return cbExprs(a.exprs);
	}
}

immutable(ConstantsOrExprs) getConstantsOrExprs(Alloc)(
	ref Alloc alloc,
	ref ConcretizeExprCtx ctx,
	ref immutable Arr!Expr argExprs,
) {
	immutable Arr!ConcreteExpr exprs = getArgs(alloc, ctx, argExprs);
	return inlineConstants && every(exprs, (ref immutable ConcreteExpr arg) => isConstant(arg.kind))
		? immutable ConstantsOrExprs(map(alloc, exprs, (ref immutable ConcreteExpr arg) => asConstant(arg.kind)))
		: immutable ConstantsOrExprs(exprs);
}

immutable(Arr!ConcreteExpr) getArgs(Alloc)(
	ref Alloc alloc,
	ref ConcretizeExprCtx ctx,
	ref immutable Arr!Expr argExprs,
) {
	return map(alloc, argExprs, (ref immutable Expr arg) =>
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
		immutable ConcreteExprKind(immutable ConcreteExprKind.Alloc(allocExpr(alloc, inner))));
}

immutable(ConcreteExpr) getGetVatAndActor(Alloc)(
	ref Alloc alloc,
	ref ConcretizeExprCtx ctx,
	ref immutable ConcreteType type,
	ref immutable FileAndRange range,
) {
	return immutable ConcreteExpr(type, range, immutable ConcreteExprKind(
		immutable ConcreteExprKind.Call(getGetVatAndActorFun(alloc, ctx.concretizeCtx), emptyArr!ConcreteExpr)));
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
	// TODO: handle constants in closure
	// (do *not* include in the closure type, instead remember them for when compiling the lambda fn)

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
	immutable Opt!(Ptr!ConcreteParam) closureParam = has(closureType)
		? some(nu!ConcreteParam(
			alloc,
			immutable ConcreteParamSource(immutable ConcreteParamSource.Closure()),
			none!size_t,
			force(closureType)))
		: none!(Ptr!ConcreteParam);
	immutable Opt!(Ptr!ConcreteExpr) closure = e.kind == FunKind.ptr
		? none!(Ptr!ConcreteExpr)
		: some!(Ptr!ConcreteExpr)(
			empty(closureArgs)
				? allocExpr(alloc, immutable ConcreteExpr(
					byRef(boolType(alloc, ctx.concretizeCtx)), // TODO: this should be any-ptr type
					range,
					immutable ConcreteExprKind(immutable Constant(immutable Constant.Null()))))
				: allocExpr(alloc, createAllocExpr(alloc, ctx.concretizeCtx, immutable ConcreteExpr(
					byVal(force(closureType)),
					range,
					immutable ConcreteExprKind(immutable ConcreteExprKind.CreateRecord(closureArgs))))));

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
	immutable ConcreteExpr res = immutable ConcreteExpr(funType, range, immutable ConcreteExprKind(
		immutable ConcreteExprKind.Lambda(fun, closure)));

	if (e.kind == FunKind.ref_) {
		immutable ConcreteField vatAndActorField = at(asRecord(body_(possiblySendType.struct_)).fields, 0);
		verify(symEqLongAlphaLiteral(name(vatAndActorField), "vat-and-actor"));
		immutable ConcreteExpr vatAndActor = getGetVatAndActor(alloc, ctx, vatAndActorField.type, range);
		return immutable ConcreteExpr(possiblySendType, range, immutable ConcreteExprKind(
			immutable ConcreteExprKind.CreateRecord(arrLiteral!ConcreteExpr(alloc, [vatAndActor, res]))));
	} else
		return res;
}

immutable(Ptr!ConcreteLocal) makeLocalWorker(Alloc)(
	ref Alloc alloc,
	ref ConcretizeExprCtx ctx,
	immutable ConcreteLocalSource source,
	immutable ConcreteType type,
) {
	immutable Ptr!ConcreteLocal res = nu!ConcreteLocal(alloc, source, ctx.nextLocalIndex, type);
	ctx.nextLocalIndex++;
	return res;
}

immutable(Ptr!ConcreteLocal) concretizeLocal(Alloc)(
	ref Alloc alloc,
	ref ConcretizeExprCtx ctx,
	immutable Ptr!Local local,
) {
	return makeLocalWorker(alloc, ctx, immutable ConcreteLocalSource(local), getConcreteType(alloc, ctx, local.type));
}

immutable(ConcreteExpr) concretizeWithLocal(Alloc)(
	ref Alloc alloc,
	ref ConcretizeExprCtx ctx,
	immutable Ptr!Local modelLocal,
	ref immutable LocalOrConstant concreteLocal,
	ref immutable Expr expr,
) {
	addToMutDict(alloc, ctx.locals, modelLocal, concreteLocal);
	immutable ConcreteExpr res = concretizeExpr(alloc, ctx, expr);
	mustDelete(ctx.locals, modelLocal);
	return res;
}

immutable(ConcreteExpr) concretizeLet(Alloc)(
	ref Alloc alloc,
	ref ConcretizeExprCtx ctx,
	ref immutable FileAndRange range,
	ref immutable Expr.Let e,
) {
	immutable Ptr!ConcreteExpr value = allocExpr(alloc, concretizeExpr(alloc, ctx, e.value));
	immutable LocalOrConstant localOrConstant = isConstant(value.kind)
		? immutable LocalOrConstant(immutable TypedConstant(value.type, asConstant(value.kind)))
		: immutable LocalOrConstant(concretizeLocal(alloc, ctx, e.local));
	immutable ConcreteExpr then = concretizeWithLocal(alloc, ctx, e.local, localOrConstant, e.then);
	return matchLocalOrConstant!(immutable ConcreteExpr)(
		localOrConstant,
		(immutable Ptr!ConcreteLocal local) =>
			immutable ConcreteExpr(then.type, range, immutable ConcreteExprKind(
				immutable ConcreteExprKind.Let(local, value, allocExpr(alloc, then)))),
		(ref immutable TypedConstant) =>
			then);
}

immutable(ConcreteExpr) concretizeMatch(Alloc)(
	ref Alloc alloc,
	ref ConcretizeExprCtx ctx,
	ref immutable FileAndRange range,
	ref immutable Expr.Match e,
) {
	immutable ConcreteExpr matched = concretizeExpr(alloc, ctx, e.matched);
	immutable ConcreteType ct = getConcreteType_forStructInst(alloc, ctx, e.matchedUnion);
	immutable Ptr!ConcreteStruct matchedUnion = mustBeNonPointer(ct);
	immutable ConcreteType type = getConcreteType(alloc, ctx, e.type);
	if (isConstant(matched.kind)) {
		immutable Constant.Union u = asUnion(asConstant(matched.kind));
		immutable Expr.Match.Case case_ = at(e.cases, u.memberIndex);
		if (has(case_.local)) {
			immutable ConcreteType caseType = at(asUnion(body_(matchedUnion)).members, u.memberIndex);
			immutable LocalOrConstant lc = immutable LocalOrConstant(immutable TypedConstant(caseType, u.arg));
			return concretizeWithLocal(alloc, ctx, force(case_.local), lc, case_.then);
		} else
			return concretizeExpr(alloc, ctx, case_.then);
	} else {
		immutable Arr!(ConcreteExprKind.Match.Case) cases = map!(ConcreteExprKind.Match.Case)(
			alloc,
			e.cases,
			(ref immutable Expr.Match.Case case_) {
				if (has(case_.local)) {
					immutable Ptr!ConcreteLocal local = concretizeLocal(alloc, ctx, force(case_.local));
					immutable LocalOrConstant lc = immutable LocalOrConstant(local);
					immutable ConcreteExpr then = concretizeWithLocal(alloc, ctx, force(case_.local), lc, case_.then);
					return immutable ConcreteExprKind.Match.Case(some(local), then);
				} else
					return immutable ConcreteExprKind.Match.Case(
						none!(Ptr!ConcreteLocal),
						concretizeExpr(alloc, ctx, case_.then));
			});
		return immutable ConcreteExpr(type, range, immutable ConcreteExprKind(
			nu!(ConcreteExprKind.Match)(alloc, allocExpr(alloc, matched), cases)));
	}
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
	return immutable ConcreteExpr(concreteParam.type, range, immutable ConcreteExprKind(
		immutable ConcreteExprKind.ParamRef(concreteParam)));
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

immutable(ConcreteExpr) concretizeExpr(Alloc)(
	ref Alloc alloc,
	ref ConcretizeExprCtx ctx,
	ref immutable Expr e,
) {
	immutable FileAndRange range = range(e);
	return matchExpr!(immutable ConcreteExpr)(
		e,
		(ref immutable Expr.Bogus) =>
			unreachable!(immutable ConcreteExpr),
		(ref immutable Expr.Call e) =>
			concretizeCall(alloc, ctx, range, e),
		(ref immutable Expr.ClosureFieldRef e) =>
			concretizeClosureFieldRef(alloc, ctx, range, e),
		(ref immutable Expr.Cond e) {
			immutable ConcreteExpr cond = concretizeExpr(alloc, ctx, e.cond);
			return inlineConstants && isConstant(cond.kind)
				? concretizeExpr(alloc, ctx, asBool(asConstant(cond.kind)) ? e.then : e.else_)
				: immutable ConcreteExpr(
					getConcreteType(alloc, ctx, e.type),
					range,
					immutable ConcreteExprKind(immutable ConcreteExprKind.Cond(
						allocExpr(alloc, cond),
						allocExpr(alloc, concretizeExpr(alloc, ctx, e.then)),
						allocExpr(alloc, concretizeExpr(alloc, ctx, e.else_)))));
		},
		(ref immutable Expr.CreateArr e) {
			immutable ConstantsOrExprs args = getConstantsOrExprs(alloc, ctx, e.args);
			immutable ConcreteType arrayType = getConcreteType_forStructInst(alloc, ctx, e.arrType);
			immutable Ptr!ConcreteStruct arrayStruct = mustBeNonPointer(arrayType);
			immutable ConcreteType elementType = getConcreteType(alloc, ctx, elementType(e));
			return matchConstantsOrExprs!(immutable ConcreteExpr)(
				args,
				(ref immutable Arr!Constant constants) =>
					immutable ConcreteExpr(arrayType, range, immutable ConcreteExprKind(
						getConstantArr(alloc, ctx.concretizeCtx.allConstants, arrayStruct, elementType, constants))),
				(ref immutable Arr!ConcreteExpr exprs) {
					return immutable ConcreteExpr(arrayType, range, immutable ConcreteExprKind(
						allocate(alloc, immutable ConcreteExprKind.CreateArr(arrayStruct, elementType, exprs))));
				});
		},
		(ref immutable Expr.ImplicitConvertToUnion e) {
			immutable ConcreteExpr inner = concretizeExpr(alloc, ctx, e.inner);
			immutable ConcreteType unionType = getConcreteType_forStructInst(alloc, ctx, e.unionType);
			if (inlineConstants && isConstant(inner.kind))
				return immutable ConcreteExpr(unionType, range, immutable ConcreteExprKind(immutable Constant(
					immutable Constant.Union(e.memberIndex, allocate(alloc, asConstant(inner.kind))))));
			else
				return immutable ConcreteExpr(unionType, range, immutable ConcreteExprKind(
					immutable ConcreteExprKind.ConvertToUnion(e.memberIndex, allocExpr(alloc, inner))));
		},
		(ref immutable Expr.Lambda e) =>
			concretizeLambda(alloc, ctx, range, e),
		(ref immutable Expr.Let e) =>
			concretizeLet(alloc, ctx, range, e),
		(ref immutable Expr.Literal e) =>
			immutable ConcreteExpr(
				getConcreteType_forStructInst(alloc, ctx, e.structInst),
				range,
				immutable ConcreteExprKind(e.value)),
		(ref immutable Expr.LocalRef e) =>
			matchLocalOrConstant!(immutable ConcreteExpr)(
				mustGetAt_mut(ctx.locals, e.local),
				(immutable Ptr!ConcreteLocal local) =>
					immutable ConcreteExpr(local.type, range, immutable ConcreteExprKind(
						immutable ConcreteExprKind.LocalRef(local))),
				(ref immutable TypedConstant it) =>
					immutable ConcreteExpr(it.type, range, immutable ConcreteExprKind(it.value))),
		(ref immutable Expr.Match e) =>
			concretizeMatch(alloc, ctx, range, e),
		(ref immutable Expr.ParamRef e) =>
			concretizeParamRef(alloc, ctx, range, e),
		(ref immutable Expr.Seq e) {
			immutable ConcreteExpr first = concretizeExpr(alloc, ctx, e.first);
			immutable ConcreteExpr then = concretizeExpr(alloc, ctx, e.then);
			return isConstant(first.kind)
				? then
				: immutable ConcreteExpr(then.type, range, immutable ConcreteExprKind(
					immutable ConcreteExprKind.Seq(allocExpr(alloc, first), allocExpr(alloc, then))));
		},
		(ref immutable Expr.StringLiteral e) {
			immutable ConcreteType charType = charType(alloc, ctx.concretizeCtx);
			//TODO: Use ctx->concretizeCtx->strType() like we do for char
			immutable ConcreteType strType =
				getConcreteType_forStructInst(alloc, ctx, ctx.concretizeCtx.commonTypes.str);
			immutable Ptr!ConcreteStruct strStruct = mustBeNonPointer(strType);
			return immutable ConcreteExpr(strType, range, immutable ConcreteExprKind(
				getConstantStr(alloc, ctx.concretizeCtx.allConstants, strStruct, charType, e.literal)));
		});
}

immutable(Constant) evalConstant(ref immutable ConcreteFun fn, immutable Arr!Constant /*parameters*/) {
	return todo!(immutable Constant)("evalConstant");
}
