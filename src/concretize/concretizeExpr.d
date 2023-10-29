module concretize.concretizeExpr;

@safe @nogc pure nothrow:

import concretize.allConstantsBuilder : AllConstantsBuilder, getConstantArr, getConstantPtr;
import concretize.concretizeCtx :
	arrayElementType,
	boolType,
	ConcretizeCtx,
	ConcreteFunKey,
	concreteTypeFromClosure,
	concretizeLambdaParams,
	constantCStr,
	constantSym,
	ContainingFunInfo,
	cStrType,
	getOrAddNonTemplateConcreteFunAndFillBody,
	getConcreteType_fromConcretizeCtx = getConcreteType,
	getConcreteFunForLambdaAndFillBody,
	getOrAddConcreteFunAndFillBody,
	typeArgsScope,
	TypeArgsScope,
	typesToConcreteTypes_fromConcretizeCtx = typesToConcreteTypes,
	voidType;
import concretize.constantsOrExprs : asConstantsOrExprs, ConstantsOrExprs;
import model.concreteModel :
	body_,
	byRef,
	byVal,
	ConcreteClosureRef,
	ConcreteExpr,
	ConcreteExprKind,
	ConcreteField,
	ConcreteFun,
	ConcreteFunBody,
	ConcreteLambdaImpl,
	ConcreteLocal,
	ConcreteLocalSource,
	ConcreteMutability,
	ConcreteStruct,
	ConcreteStructBody,
	ConcreteStructSource,
	ConcreteType,
	ConcreteVariableRef,
	isBogus,
	isSummon,
	isVariadic,
	isVoid,
	mustBeByVal,
	name,
	purity,
	ReferenceKind,
	returnType;
import model.constant : asBool, Constant, constantBool, constantZero;
import model.model :
	AssertOrForbidKind,
	Called,
	CalledSpecSig,
	ClosureRef,
	ClosureReferenceKind,
	Destructure,
	EnumFunction,
	Expr,
	ExprAndType,
	ExprKind,
	FunInst,
	FunKind,
	getClosureReferenceKind,
	Local,
	name,
	Purity,
	range,
	specImpls,
	Type,
	typeArgs,
	VariableRef,
	variableRefType;
import util.alloc.alloc : Alloc;
import util.col.arr : empty, only, PtrAndSmallNumber, sizeEq;
import util.col.arrUtil : arrLiteral, map, mapZip;
import util.col.mutArr : MutArr, mutArrSize, push;
import util.col.mutMap : getOrAdd;
import util.col.stackMap : StackMap2, stackMap2Add0, stackMap2Add1, stackMap2MustGet0, stackMap2MustGet1, withStackMap2;
import util.col.str : SafeCStr, safeCStr;
import util.memory : allocate, overwriteMemory;
import util.opt : force, has, none, Opt, some;
import util.ptr : castNonScope, castNonScope_ref, ptrTrustMe;
import util.sourceRange : FileAndRange, RangeWithinFile;
import util.sym : Sym, sym;
import util.union_ : Union;
import util.uri : Uri;
import util.util : todo, unreachable, verify;
import versionInfo : VersionInfo;

ConcreteExpr concretizeFunBody(
	ref ConcretizeCtx ctx,
	ref ContainingFunInfo containing,
	ConcreteFun* cf,
	in Destructure[] params,
	ref Expr e,
) {
	ConcretizeExprCtx exprCtx = ConcretizeExprCtx(ptrTrustMe(ctx), e.range.uri, containing, cf);
	return withStackMap2!(ConcreteExpr, Local*, LocalOrConstant, ExprKind.Loop*, LoopAndType*)((ref Locals locals) {
		// Ignore closure param, which is never destructured.
		ConcreteLocal[] paramsToDestructure =
			cf.paramsIncludingClosure[params.length + 1 == cf.paramsIncludingClosure.length ? 1 : 0 .. $];
		return concretizeWithParamDestructures(exprCtx, cf.returnType, locals, params, paramsToDestructure, e);
	});
}

ConcreteExpr concretizeBogus(ref ConcretizeCtx ctx, ConcreteType type, FileAndRange range) =>
	makeThrow(ctx.alloc, range, type, cStrConcreteExpr(ctx, range, safeCStr!"Reached compile error"));

private:

ConcreteExpr concretizeWithParamDestructures(
	ref ConcretizeExprCtx ctx,
	ConcreteType type,
	in Locals locals,
	in Destructure[] params,
	ConcreteLocal[] concreteParams,
	ref Expr expr,
) {
	verify(sizeEq(params, concreteParams));
	if (empty(params))
		return concretizeExpr(ctx, type, locals, expr);
	else {
		ConcreteExpr rest(in Locals innerLocals) {
			return concretizeWithParamDestructures(
				ctx, type, innerLocals, params[1 .. $], concreteParams[1 .. $], expr);
		}
		return params[0].matchWithPointers!ConcreteExpr(
			(Destructure.Ignore*) =>
				rest(locals),
			(Local* local) =>
				rest(addLocal(locals, local, LocalOrConstant(&concreteParams[0]))),
			(Destructure.Split* x) =>
				concretizeWithDestructureSplit(
					ctx, type, toFileAndRange(ctx, params[0].range), locals, *x, &concreteParams[0],
					(in Locals innerLocals) => rest(innerLocals)));
	}
}

struct ConcretizeExprCtx {
	@safe @nogc pure nothrow:

	ConcretizeCtx* concretizeCtxPtr;
	Uri curUri;
	immutable ContainingFunInfo containing;
	immutable ConcreteFun* currentConcreteFunPtr; // This is the ConcreteFun* for a lambda, not its containing fun
	size_t nextLambdaIndex = 0;

	ref Alloc alloc() return scope =>
		concretizeCtx.alloc;

	ref inout(ConcretizeCtx) concretizeCtx() return scope inout =>
		*concretizeCtxPtr;

	ref ConcreteFun currentConcreteFun() return scope const =>
		*currentConcreteFunPtr;

	ref inout(AllConstantsBuilder) allConstants() return scope inout =>
		concretizeCtx.allConstants;
}

ConcreteType boolType(ref ConcretizeExprCtx ctx) =>
	.boolType(ctx.concretizeCtx);
ConcreteType voidType(ref ConcretizeExprCtx ctx) =>
	.voidType(ctx.concretizeCtx);

FileAndRange toFileAndRange(in ConcretizeExprCtx ctx, RangeWithinFile a) =>
	FileAndRange(ctx.curUri, a);

immutable struct TypedConstant {
	ConcreteType type;
	Constant value;
}

immutable struct LocalOrConstant {
	mixin Union!(ConcreteLocal*, TypedConstant);
}

ConcreteType type(in LocalOrConstant a) =>
	a.matchIn!ConcreteType(
		(in ConcreteLocal x) =>
			x.type,
		(in TypedConstant x) =>
			x.type);

ConcreteType getConcreteType(ref ConcretizeExprCtx ctx, in Type t) =>
	getConcreteType_fromConcretizeCtx(ctx.concretizeCtx, t, typeScope(ctx));

ConcreteType[] typesToConcreteTypes(ref ConcretizeExprCtx ctx, in Type[] typeArgs) =>
	typesToConcreteTypes_fromConcretizeCtx(ctx.concretizeCtx, typeArgs, typeScope(ctx));

TypeArgsScope typeScope(ref ConcretizeExprCtx ctx) =>
	typeArgsScope(ctx.containing);

ConcreteExpr concretizeCall(
	ref ConcretizeExprCtx ctx,
	ConcreteType type,
	FileAndRange range,
	in Locals locals,
	in ExprKind.Call e,
) {
	ConcreteFun* concreteCalled = getConcreteFunFromCalled(ctx, e.called);
	if (isBogus(concreteCalled.returnType))
		return concretizeBogus(ctx.concretizeCtx, type, range);
	verify(concreteCalled.returnType == type);
	bool argsMayBeConstants =
		empty(e.args) || (!isSummon(*concreteCalled) && purity(concreteCalled.returnType) == Purity.data);
	ConstantsOrExprs args = () {
		if (isVariadic(*concreteCalled)) {
			ConcreteType arrayType = only(concreteCalled.paramsIncludingClosure).type;
			ConcreteType elementType = arrayElementType(arrayType);
			return constantsOrExprsArr(
				ctx, range, arrayType,
				asConstantsOrExprsIf(ctx.alloc, argsMayBeConstants, map(ctx.alloc, e.args, (ref Expr arg) =>
					concretizeExpr(ctx, elementType, locals, arg))));
		} else
			return asConstantsOrExprsIf(
				ctx.alloc, argsMayBeConstants,
				mapZip(
					ctx.alloc, concreteCalled.paramsIncludingClosure, e.args,
					(ref ConcreteLocal param, ref Expr arg) =>
						concretizeExpr(ctx, param.type, locals, arg)));
	}();
	ConcreteExprKind kind = args.match!ConcreteExprKind(
		(Constant[] constants) {
			Opt!Constant constant =
				tryEvalConstant(*concreteCalled, constants, ctx.concretizeCtx.versionInfo);
			return has(constant)
				? ConcreteExprKind(force(constant))
				: ConcreteExprKind(ConcreteExprKind.Call(
					concreteCalled,
					mapZip(
						ctx.alloc,
						concreteCalled.paramsIncludingClosure,
						constants,
						(ref ConcreteLocal p, ref Constant x) =>
							ConcreteExpr(p.type, FileAndRange.empty, ConcreteExprKind(x)))));
		},
		(ConcreteExpr[] exprs) =>
			ConcreteExprKind(ConcreteExprKind.Call(concreteCalled, exprs)));
	return ConcreteExpr(type, range, kind);
}

ConstantsOrExprs asConstantsOrExprsIf(ref Alloc alloc, bool mayBeConstants, ConcreteExpr[] exprs) =>
	mayBeConstants
		? asConstantsOrExprs(alloc, exprs)
		: ConstantsOrExprs(exprs);

ConcreteFun* getConcreteFunFromCalled(ref ConcretizeExprCtx ctx, ref Called called) =>
	called.matchWithPointers!(ConcreteFun*)(
		(FunInst* funInst) =>
			getConcreteFunFromFunInst(ctx, funInst),
		(CalledSpecSig* specSig) =>
			ctx.containing.specImpls[specSig.indexOverAllSpecUses]);

ConcreteFun* getConcreteFunFromFunInst(ref ConcretizeExprCtx ctx, FunInst* funInst) {
	ConcreteType[] typeArgs = typesToConcreteTypes(ctx, typeArgs(*funInst));
	immutable ConcreteFun*[] specImpls = map!(ConcreteFun*, Called)(ctx.alloc, specImpls(*funInst), (ref Called it) =>
		getConcreteFunFromCalled(ctx, it));
	ConcreteFunKey key = ConcreteFunKey(funInst, typeArgs, specImpls);
	return getOrAddConcreteFunAndFillBody(ctx.concretizeCtx, key);
}

ConcreteExpr concretizeClosureGet(
	ref ConcretizeExprCtx ctx,
	ConcreteType type,
	FileAndRange range,
	in ExprKind.ClosureGet a,
) {
	ClosureFieldInfo info = getClosureFieldInfo(ctx, range, *a.closureRef);
	verify(info.type == type);
	return ConcreteExpr(type, range, ConcreteExprKind(
		allocate(ctx.alloc, ConcreteExprKind.ClosureGet(info.closureRef, info.referenceKind))));
}

ConcreteExpr concretizeClosureSet(
	ref ConcretizeExprCtx ctx,
	ConcreteType type,
	FileAndRange range,
	in Locals locals,
	in ExprKind.ClosureSet a,
) {
	verify(getClosureReferenceKind(*a.closureRef) == ClosureReferenceKind.allocated);
	ClosureFieldInfo info = getClosureFieldInfo(ctx, range, *a.closureRef);
	verify(info.referenceKind == ClosureReferenceKind.allocated);
	ConcreteExpr value = concretizeExpr(ctx, info.type, locals, *a.value);
	verify(isVoid(type));
	return ConcreteExpr(type, range, ConcreteExprKind(
		allocate(ctx.alloc, ConcreteExprKind.ClosureSet(info.closureRef, value))));
}

immutable struct ClosureFieldInfo {
	ConcreteClosureRef closureRef;
	ConcreteType type; // If 'referenceKind' is 'allocated', this is the pointee type
	ClosureReferenceKind referenceKind;
}
ClosureFieldInfo getClosureFieldInfo(ref ConcretizeExprCtx ctx, FileAndRange range, ClosureRef a) {
	ConcreteLocal* closureParam = &ctx.currentConcreteFun.paramsIncludingClosure[0];
	ConcreteType closureType = closureParam.type;
	ConcreteStructBody.Record record = body_(*closureType.struct_).as!(ConcreteStructBody.Record);
	ClosureReferenceKind referenceKind = getClosureReferenceKind(a);
	ConcreteType fieldType = record.fields[a.index].type;
	ConcreteType pointeeType = () {
		final switch (referenceKind) {
			case ClosureReferenceKind.direct:
				return fieldType;
			case ClosureReferenceKind.allocated:
				return removeIndirection(fieldType);
		}
	}();
	return ClosureFieldInfo(
		ConcreteClosureRef(PtrAndSmallNumber!ConcreteLocal(closureParam, a.index)),
		pointeeType,
		referenceKind);
}

ConcreteExpr createAllocExpr(ref Alloc alloc, ConcreteExpr inner) {
	verify(inner.type.reference == ReferenceKind.byVal);
	return ConcreteExpr(
		byRef(inner.type),
		inner.range,
		ConcreteExprKind(allocate(alloc, ConcreteExprKind.Alloc(inner))));
}

ConcreteExpr getCurExclusion(ref ConcretizeExprCtx ctx, ConcreteType type, FileAndRange range) =>
	ConcreteExpr(type, range, ConcreteExprKind(ConcreteExprKind.Call(ctx.concretizeCtx.curExclusionFun, [])));

ConcreteField[] concretizeClosureFields(ref ConcretizeCtx ctx, VariableRef[] closure, TypeArgsScope typeArgsScope) =>
	map(ctx.alloc, closure, (ref VariableRef x) {
		ConcreteType baseType = getConcreteType_fromConcretizeCtx(ctx, variableRefType(x), typeArgsScope);
		ConcreteType type = () {
			final switch (getClosureReferenceKind(x)) {
				case ClosureReferenceKind.direct:
					return baseType;
				case ClosureReferenceKind.allocated:
					return addIndirection(baseType);
			}
		}();
		// Even if the variable is mutable, it's a const field holding a mut pointer
		return ConcreteField(name(x), ConcreteMutability.const_, type);
	});

ConcreteType addIndirection(ConcreteType a) =>
	ConcreteType(addIndirection(a.reference), a.struct_);
ReferenceKind addIndirection(ReferenceKind a) {
	final switch (a) {
		case ReferenceKind.byVal:
			return ReferenceKind.byRef;
		case ReferenceKind.byRef:
			return ReferenceKind.byRefRef;
		case ReferenceKind.byRefRef:
			return unreachable!ReferenceKind;
	}
}

ConcreteType removeIndirection(ConcreteType a) =>
	ConcreteType(removeIndirection(a.reference), a.struct_);
ReferenceKind removeIndirection(ReferenceKind a) {
	final switch (a) {
		case ReferenceKind.byVal:
			return unreachable!ReferenceKind;
		case ReferenceKind.byRef:
			return ReferenceKind.byVal;
		case ReferenceKind.byRefRef:
			return ReferenceKind.byRef;
	}
}

ConcreteExpr constantVoid(ref ConcretizeCtx ctx, FileAndRange range) =>
	ConcreteExpr(voidType(ctx), range, constantVoidKind());

ConcreteExprKind constantVoidKind() =>
	ConcreteExprKind(constantZero);

ConcreteExpr concretizeFunPtr(ref ConcretizeExprCtx ctx, ConcreteType type, FileAndRange range, ExprKind.FunPtr e) =>
	ConcreteExpr(type, range, ConcreteExprKind(
		Constant(Constant.FunPtr(getOrAddNonTemplateConcreteFunAndFillBody(ctx.concretizeCtx, e.funInst)))));

ConcreteExpr concretizeLambda(
	ref ConcretizeExprCtx ctx,
	ConcreteType type,
	FileAndRange range,
	in Locals locals,
	ref ExprKind.Lambda e,
) {
	// TODO: handle constants in closure
	// (do *not* include in the closure type, instead remember them for when compiling the lambda fn)

	//TODO:KILL? (We also have an ID within the type..)
	size_t lambdaIndex = ctx.nextLambdaIndex;
	ctx.nextLambdaIndex++;

	TypeArgsScope tScope = typeScope(ctx);
	ConcreteField[] closureFields = concretizeClosureFields(ctx.concretizeCtx, e.closure, tScope);
	ConcreteType closureType = concreteTypeFromClosure(
		ctx.concretizeCtx,
		closureFields,
		ConcreteStructSource(ConcreteStructSource.Lambda(ctx.currentConcreteFunPtr, lambdaIndex)));
	ConcreteLocal[] paramsIncludingClosure = concretizeLambdaParams(ctx.concretizeCtx, closureType, e.param, tScope);

	ConcreteStruct* concreteStruct = mustBeByVal(type);

	ConcreteVariableRef[] closureArgs = map(ctx.alloc, e.closure, (ref VariableRef x) =>
		concretizeVariableRefForClosure(ctx, range, locals, x));
	Opt!(ConcreteExpr*) closure = empty(closureArgs)
		? none!(ConcreteExpr*)
		: some(allocate(ctx.alloc, createAllocExpr(ctx.alloc, ConcreteExpr(
			byVal(closureType),
			range,
			ConcreteExprKind(ConcreteExprKind.ClosureCreate(closureArgs))))));

	ConcreteType returnType = getConcreteType(ctx, e.returnType);
	if (isBogus(returnType))
		return concretizeBogus(ctx.concretizeCtx, type, range);

	ConcreteFun* fun = getConcreteFunForLambdaAndFillBody(
		ctx.concretizeCtx,
		ctx.currentConcreteFunPtr,
		lambdaIndex,
		returnType,
		e.param,
		paramsIncludingClosure,
		ctx.containing,
		e.body_);
	ConcreteLambdaImpl impl = ConcreteLambdaImpl(closureType, fun);
	ConcreteExprKind lambda(ConcreteStruct* funStruct) {
		return ConcreteExprKind(ConcreteExprKind.Lambda(nextLambdaImplId(ctx.concretizeCtx, funStruct, impl), closure));
	}
	if (e.kind == FunKind.far) {
		// For a 'far' function this is the inner 'act' type.
		ConcreteField[] fields = body_(*concreteStruct).as!(ConcreteStructBody.Record).fields;
		verify(fields.length == 2);
		ConcreteField exclusionField = fields[0];
		verify(exclusionField.debugName == sym!"exclusion");
		ConcreteField actionField = fields[1];
		verify(actionField.debugName == sym!"action");
		ConcreteType funType = actionField.type;
		ConcreteExpr exclusion = getCurExclusion(ctx, exclusionField.type, range);
		return ConcreteExpr(type, range, ConcreteExprKind(
			ConcreteExprKind.CreateRecord(arrLiteral!ConcreteExpr(ctx.alloc, [
				exclusion,
				ConcreteExpr(funType, range, lambda(mustBeByVal(funType)))]))));
	} else
		return ConcreteExpr(type, range, lambda(concreteStruct));
}

public size_t nextLambdaImplId(ref ConcretizeCtx ctx, ConcreteStruct* funStruct, ConcreteLambdaImpl impl) =>
	nextLambdaImplIdInner(ctx.alloc, impl, getOrAdd(ctx.alloc, ctx.funStructToImpls, funStruct, () =>
		MutArr!ConcreteLambdaImpl()));
size_t nextLambdaImplIdInner(ref Alloc alloc, ConcreteLambdaImpl impl, ref MutArr!ConcreteLambdaImpl impls) {
	size_t res = mutArrSize(impls);
	push(alloc, impls, impl);
	return res;
}

ConcreteLocal* makeLocalWorker(ref ConcretizeExprCtx ctx, Local* source, ConcreteType type) =>
	allocate(ctx.alloc, ConcreteLocal(ConcreteLocalSource(source), type));

ConcreteLocal* concretizeLocal(ref ConcretizeExprCtx ctx, Local* local) =>
	makeLocalWorker(ctx, local, getConcreteType(ctx, local.type));

immutable struct LoopAndType {
	ConcreteExprKind.Loop* loop;
	ConcreteType type; // Type of the whole loop (type of value in 'break')
}

alias Locals = immutable StackMap2!(Local*, LocalOrConstant, ExprKind.Loop*, LoopAndType*);
alias addLocal = stackMap2Add0!(Local*, LocalOrConstant, ExprKind.Loop*, LoopAndType*);
alias addLoop = stackMap2Add1!(Local*, LocalOrConstant, ExprKind.Loop*, LoopAndType*);
alias getLocal = stackMap2MustGet0!(Local*, LocalOrConstant, ExprKind.Loop*, LoopAndType*);

//TODO: use an alias
LoopAndType getLoop(in Locals locals, ExprKind.Loop* key) =>
	*stackMap2MustGet1!(Local*, LocalOrConstant, ExprKind.Loop*, LoopAndType*)(locals, key);

ConcreteExpr concretizeLet(
	ref ConcretizeExprCtx ctx,
	ConcreteType type,
	FileAndRange range,
	in Locals locals,
	ref ExprKind.Let e,
) {
	ConcreteType localType = getConcreteType(ctx, e.destructure.type);
	return concretizeWithDestructureAndLet(
			ctx, type, range, locals, e.destructure,
			concretizeExpr(ctx, localType, locals, e.value),
			(in Locals innerLocals) =>
				concretizeExpr(ctx, type, innerLocals, e.then));
}

ConcreteExprKind.MatchUnion.Case concretizeMatchCaseWithDestructure(
	ref ConcretizeExprCtx ctx,
	ConcreteType type,
	FileAndRange range,
	in Locals locals,
	ref Destructure destructure,
	ref Expr expr,
) {
	RootLocalAndExpr res = concretizeExprWithDestructure(ctx, type, range, locals, destructure, expr);
	return ConcreteExprKind.MatchUnion.Case(res.rootLocal, res.expr);
}

RootLocalAndExpr concretizeExprWithDestructure(
	ref ConcretizeExprCtx ctx,
	ConcreteType type,
	FileAndRange range,
	in Locals locals,
	ref Destructure destructure,
	ref Expr expr,
) =>
	concretizeWithDestructure(ctx, type, range, locals, destructure, (in Locals innerLocals) =>
		concretizeExpr(ctx, type, innerLocals, expr));

struct RootLocalAndExpr {
	Opt!(ConcreteLocal*) rootLocal;
	ConcreteExpr expr;
}

ConcreteExpr concretizeWithDestructureAndLet(
	ref ConcretizeExprCtx ctx,
	ConcreteType type,
	FileAndRange range,
	in Locals locals,
	ref Destructure destructure,
	ConcreteExpr value,
	in ConcreteExpr delegate(in Locals) @safe @nogc pure nothrow cb,
) {
	RootLocalAndExpr then = concretizeWithDestructure(ctx, type, range, locals, destructure, cb);
	if (has(then.rootLocal))
		return ConcreteExpr(type, range, ConcreteExprKind(
			allocate(ctx.alloc, ConcreteExprKind.Let(force(then.rootLocal), value, then.expr))));
	else {
		if (value.kind.isA!Constant)
			return then.expr;
		else {
			ConcreteExpr drop = ConcreteExpr(voidType(ctx), range, ConcreteExprKind(
				allocate(ctx.alloc, ConcreteExprKind.Drop(value))));
			return ConcreteExpr(type, range, ConcreteExprKind(
				allocate(ctx.alloc, ConcreteExprKind.Seq(drop, then.expr))));
		}
	}
}

RootLocalAndExpr concretizeWithDestructure(
	ref ConcretizeExprCtx ctx,
	ConcreteType type,
	FileAndRange range,
	in Locals locals,
	ref Destructure destructure,
	in ConcreteExpr delegate(in Locals) @safe @nogc pure nothrow cb,
) =>
	destructure.matchWithPointers!RootLocalAndExpr(
		(Destructure.Ignore*) {
			ConcreteExpr then = cb(locals);
			return RootLocalAndExpr(none!(ConcreteLocal*), then);
		},
		(Local* local) {
			ConcreteLocal* concreteLocal = concretizeLocal(ctx, local);
			ConcreteExpr then = cb(addLocal(locals, local, LocalOrConstant(concreteLocal)));
			return RootLocalAndExpr(some(concreteLocal), then);
		},
		(Destructure.Split* x) {
			if (x.destructuredType.isA!(Type.Bogus))
				return RootLocalAndExpr(none!(ConcreteLocal*), concretizeBogus(ctx.concretizeCtx, type, range));
			else {
				ConcreteLocal* temp = allocate(ctx.alloc, ConcreteLocal(
					ConcreteLocalSource(ConcreteLocalSource.Generated(sym!"destructure")),
					getConcreteType(ctx, destructure.type)));
				return RootLocalAndExpr(
					some(temp),
					concretizeWithDestructureSplit(ctx, type, range, locals, *x, temp, cb));
			}
		});

ConcreteExpr makeLocalGet(FileAndRange range, ConcreteLocal* local) =>
	ConcreteExpr(local.type, range, ConcreteExprKind(ConcreteExprKind.LocalGet(local)));

ConcreteExpr concretizeWithDestructureSplit(
	ref ConcretizeExprCtx ctx,
	ConcreteType type,
	FileAndRange range,
	in Locals locals,
	in Destructure.Split split,
	ConcreteLocal* destructured,
	in ConcreteExpr delegate(in Locals) @safe @nogc pure nothrow cb,
) =>
	concretizeWithDestructurePartsRecur(
		ctx, type, locals, allocate(ctx.alloc, makeLocalGet(range, destructured)), split.parts, 0, cb);
ConcreteExpr concretizeWithDestructurePartsRecur(
	ref ConcretizeExprCtx ctx,
	ConcreteType type,
	in Locals locals,
	ConcreteExpr* getTemp,
	in Destructure[] parts,
	size_t partIndex,
	in ConcreteExpr delegate(in Locals) @safe @nogc pure nothrow cb,
) {
	if (partIndex == parts.length)
		return cb(locals);
	else {
		Destructure part = parts[partIndex];
		FileAndRange range = toFileAndRange(ctx, part.range);
		ConcreteType valueType =
			body_(*mustBeByVal(getTemp.type)).as!(ConcreteStructBody.Record).fields[partIndex].type;
		ConcreteType expectedType = getConcreteType(ctx, part.type);
		if (expectedType == valueType) {
			ConcreteExpr value = ConcreteExpr(valueType, range, isVoid(valueType)
				? constantVoidKind
				: ConcreteExprKind(ConcreteExprKind.RecordFieldGet(getTemp, partIndex)));
			return concretizeWithDestructureAndLet(ctx, type, range, locals, part, value, (in Locals innerLocals) =>
				concretizeWithDestructurePartsRecur(ctx, type, innerLocals, getTemp, parts, partIndex + 1, cb));
		} else
			return concretizeBogus(ctx.concretizeCtx, type, range);
	}
}

ConcreteExpr concretizeIf(
	ref ConcretizeExprCtx ctx,
	ConcreteType type,
	FileAndRange range,
	in Locals locals,
	ref ExprKind.If a,
) {
	ConcreteExpr cond = concretizeExpr(ctx, boolType(ctx), locals, a.cond);
	return cond.kind.isA!Constant
		? concretizeExpr(ctx, type, locals, asBool(cond.kind.as!Constant) ? a.then : a.else_)
		: ConcreteExpr(type, range, ConcreteExprKind(allocate(ctx.alloc, ConcreteExprKind.If(
			cond,
			concretizeExpr(ctx, type, locals, a.then),
			concretizeExpr(ctx, type, locals, a.else_)))));
}

ConcreteExpr concretizeIfOption(
	ref ConcretizeExprCtx ctx,
	ConcreteType type,
	FileAndRange range,
	in Locals locals,
	ref ExprKind.IfOption e,
) {
	ConcreteExpr option = concretizeExpr(ctx, locals, e.option);
	if (option.kind.isA!Constant)
		return todo!ConcreteExpr("constant option");
	else {
		ConcreteExprKind.MatchUnion.Case noneCase = ConcreteExprKind.MatchUnion.Case(
			none!(ConcreteLocal*),
			concretizeExpr(ctx, type, locals, e.else_));
		RootLocalAndExpr then = concretizeExprWithDestructure(ctx, type, range, locals, e.destructure, e.then);
		ConcreteExprKind.MatchUnion.Case someCase = ConcreteExprKind.MatchUnion.Case(then.rootLocal, then.expr);
		return ConcreteExpr(type, range, ConcreteExprKind(
			allocate(ctx.alloc, ConcreteExprKind.MatchUnion(
				option,
				arrLiteral!(ConcreteExprKind.MatchUnion.Case)(ctx.alloc, [noneCase, someCase])))));
	}
}

ConcreteExpr concretizeLocalGet(
	ref ConcretizeExprCtx ctx,
	ConcreteType type,
	FileAndRange range,
	in Locals locals,
	Local* local,
) {
	LocalOrConstant concrete = castNonScope_ref(getLocal(locals, local));
	return concrete.matchWithPointers!ConcreteExpr(
		(ConcreteLocal* local) =>
			isBogus(local.type)
				? concretizeBogus(ctx.concretizeCtx, type, range)
				: ConcreteExpr(type, range, ConcreteExprKind(ConcreteExprKind.LocalGet(local))),
		(TypedConstant x) =>
			ConcreteExpr(type, range, ConcreteExprKind(x.value)));
}

ConcreteExpr concretizePtrToLocal(
	ref ConcretizeExprCtx ctx,
	ConcreteType type,
	FileAndRange range,
	in Locals locals,
	ExprKind.PtrToLocal a,
) {
	ConcreteExprKind kind = castNonScope_ref(getLocal(locals, a.local)).matchWithPointers!ConcreteExprKind(
		(ConcreteLocal* local) =>
			ConcreteExprKind(ConcreteExprKind.PtrToLocal(local)),
		(TypedConstant x) =>
			//TODO: what if pointee is a reference?
			ConcreteExprKind(getConstantPtr(ctx.alloc, ctx.allConstants, mustBeByVal(x.type), x.value)));
	return ConcreteExpr(type, range, kind);
}

ConcreteExpr concretizePtrToField(
	ref ConcretizeExprCtx ctx,
	ConcreteType type,
	FileAndRange range,
	in Locals locals,
	ref ExprKind.PtrToField a,
) =>
	ConcreteExpr(type, range, ConcreteExprKind(
		allocate(ctx.alloc, ConcreteExprKind.PtrToField(concretizeExpr(ctx, locals, a.target), a.fieldIndex))));

ConcreteExpr concretizeLocalSet(
	ref ConcretizeExprCtx ctx,
	ConcreteType type,
	FileAndRange range,
	in Locals locals,
	ref ExprKind.LocalSet a,
) {
	ConcreteLocal* local = getLocal(locals, a.local).as!(ConcreteLocal*);
	ConcreteExpr value = concretizeExpr(ctx, local.type, locals, a.value);
	return ConcreteExpr(type, range, ConcreteExprKind(
		allocate(ctx.alloc, ConcreteExprKind.LocalSet(castNonScope(local), value))));
}

ConcreteExpr concretizeLoop(
	ref ConcretizeExprCtx ctx,
	ConcreteType type,
	FileAndRange range,
	in Locals locals,
	ref ExprKind.Loop a,
) {
	immutable ConcreteExprKind.Loop* res = allocate(ctx.alloc, ConcreteExprKind.Loop());
	LoopAndType loopAndType = LoopAndType(res, type);
	scope Locals localsWithLoop = addLoop(locals, &a, &loopAndType);
	overwriteMemory(&res.body_, concretizeExpr(ctx, voidType(ctx), localsWithLoop, a.body_));
	return ConcreteExpr(type, range, ConcreteExprKind(res));
}

ConcreteExpr concretizeLoopBreak(
	ref ConcretizeExprCtx ctx,
	ConcreteType type,
	FileAndRange range,
	in Locals locals,
	ref ExprKind.LoopBreak a,
) {
	verify(isVoid(type));
	LoopAndType loop = castNonScope(getLoop(locals, a.loop));
	ConcreteExpr value = concretizeExpr(ctx, loop.type, locals, a.value);
	return ConcreteExpr(type, range, ConcreteExprKind(
		allocate(ctx.alloc, ConcreteExprKind.LoopBreak(loop.loop, value))));
}

ConcreteExpr concretizeLoopContinue(
	ref ConcretizeExprCtx ctx,
	ConcreteType type,
	FileAndRange range,
	in Locals locals,
	in ExprKind.LoopContinue a,
) {
	verify(isVoid(type));
	ConcreteExprKind.Loop* loop = castNonScope(getLoop(locals, a.loop).loop);
	return ConcreteExpr(type, range, ConcreteExprKind(ConcreteExprKind.LoopContinue(loop)));
}

ConcreteExpr concretizeLoopUntil(
	ref ConcretizeExprCtx ctx,
	ConcreteType type,
	FileAndRange range,
	in Locals locals,
	ref ExprKind.LoopUntil a,
) =>
	concretizeLoopUntilOrWhile(ctx, type, range, locals, a.condition, a.body_, true);

ConcreteExpr concretizeLoopWhile(
	ref ConcretizeExprCtx ctx,
	ConcreteType type,
	FileAndRange range,
	in Locals locals,
	ref ExprKind.LoopWhile a,
) =>
	concretizeLoopUntilOrWhile(ctx, type, range, locals, a.condition, a.body_, false);

ConcreteExpr concretizeLoopUntilOrWhile(
	ref ConcretizeExprCtx ctx,
	ConcreteType type,
	FileAndRange range,
	in Locals locals,
	ref Expr conditionExpr,
	ref Expr bodyExpr,
	bool isUntil,
) {
	verify(isVoid(type));
	ConcreteExprKind.Loop* res = allocate(ctx.alloc, ConcreteExprKind.Loop());
	ConcreteExpr breakVoid = ConcreteExpr(
		voidType(ctx),
		range,
		ConcreteExprKind(allocate(ctx.alloc, ConcreteExprKind.LoopBreak(res, constantVoid(ctx.concretizeCtx, range)))));
	ConcreteExpr doAndContinue = ConcreteExpr(
		voidType(ctx),
		range,
		ConcreteExprKind(allocate(ctx.alloc, ConcreteExprKind.Seq(
			concretizeExpr(ctx, voidType(ctx), locals, bodyExpr),
			ConcreteExpr(
				voidType(ctx),
				range,
				ConcreteExprKind(ConcreteExprKind.LoopContinue(res)))))));
	ConcreteExpr condition = concretizeExpr(ctx, boolType(ctx), locals, conditionExpr);
	ConcreteExprKind.If if_ = isUntil
		? ConcreteExprKind.If(condition, breakVoid, doAndContinue)
		: ConcreteExprKind.If(condition, doAndContinue, breakVoid);
	overwriteMemory(&res.body_, ConcreteExpr(voidType(ctx), range, ConcreteExprKind(allocate(ctx.alloc, if_))));
	return ConcreteExpr(type, range, ConcreteExprKind(res));
}

ConcreteExpr concretizeMatchEnum(
	ref ConcretizeExprCtx ctx,
	ConcreteType type,
	FileAndRange range,
	in Locals locals,
	ref ExprKind.MatchEnum e,
) {
	ConcreteExpr matched = concretizeExpr(ctx, locals, e.matched);
	//TODO: If matched is a constant, just compile the relevant case
	ConcreteExpr[] cases = map(ctx.alloc, e.cases, (ref Expr case_) =>
		concretizeExpr(ctx, type, locals, case_));
	return ConcreteExpr(type, range, ConcreteExprKind(
		allocate(ctx.alloc, ConcreteExprKind.MatchEnum(matched, cases))));
}

ConcreteExpr concretizeMatchUnion(
	ref ConcretizeExprCtx ctx,
	ConcreteType type,
	FileAndRange range,
	in Locals locals,
	ref ExprKind.MatchUnion e,
) {
	ConcreteExpr matched = concretizeExpr(ctx, locals, e.matched);
	ConcreteExprKind.MatchUnion.Case[] cases = map(ctx.alloc, e.cases, (ref ExprKind.MatchUnion.Case case_) =>
		concretizeMatchCaseWithDestructure(ctx, type, range, locals, case_.destructure, case_.then));
	return ConcreteExpr(type, range, ConcreteExprKind(
		allocate(ctx.alloc, ConcreteExprKind.MatchUnion(matched, cases))));
}

ConcreteVariableRef concretizeVariableRefForClosure(
	ref ConcretizeExprCtx ctx,
	FileAndRange range,
	in Locals locals,
	VariableRef a,
) =>
	a.matchWithPointers!ConcreteVariableRef(
		(Local* x) =>
			getLocal(locals, x).matchWithPointers!ConcreteVariableRef(
				(ConcreteLocal* local) =>
					ConcreteVariableRef(local),
				(TypedConstant constant) =>
					ConcreteVariableRef(constant.value)),
		(ClosureRef x) =>
			ConcreteVariableRef(getClosureFieldInfo(ctx, range, x).closureRef));

ConcreteExpr makeThrow(ref Alloc alloc, FileAndRange range, ConcreteType type, ConcreteExpr thrown) =>
	ConcreteExpr(type, range, ConcreteExprKind(allocate(alloc, ConcreteExprKind.Throw(thrown))));

ConcreteExpr cStrConcreteExpr(ref ConcretizeCtx ctx, FileAndRange range, SafeCStr value) =>
	cStrConcreteExpr(ctx, cStrType(ctx), range, value);
ConcreteExpr cStrConcreteExpr(ref ConcretizeCtx ctx, ConcreteType type, FileAndRange range, SafeCStr value) =>
	ConcreteExpr(type, range, ConcreteExprKind(constantCStr(ctx, value)));

ConcreteExpr concretizeAssertOrForbid(
	ref ConcretizeExprCtx ctx,
	ConcreteType type,
	FileAndRange range,
	in Locals locals,
	in ExprKind.AssertOrForbid a,
) {
	verify(isVoid(type));
	ConcreteExpr condition = concretizeExpr(ctx, boolType(ctx), locals, *a.condition);
	ConcreteExpr thrown = has(a.thrown)
		? concretizeExpr(ctx, cStrType(ctx.concretizeCtx), locals, *force(a.thrown))
		: cStrConcreteExpr(ctx.concretizeCtx, range, defaultAssertOrForbidMessage(a.kind));
	ConcreteExpr void_ = constantVoid(ctx.concretizeCtx, range);
	ConcreteType voidType = voidType(ctx);
	ConcreteExpr throw_ = ConcreteExpr(
		voidType,
		range,
		ConcreteExprKind(allocate(ctx.alloc, ConcreteExprKind.Throw(thrown))));
	ConcreteExprKind.If if_ = () {
		final switch (a.kind) {
			case AssertOrForbidKind.assert_:
				return ConcreteExprKind.If(condition, void_, throw_);
			case AssertOrForbidKind.forbid:
				return ConcreteExprKind.If(condition, throw_, void_);
		}
	}();
	return ConcreteExpr(type, range, ConcreteExprKind(allocate(ctx.alloc, if_)));
}

SafeCStr defaultAssertOrForbidMessage(AssertOrForbidKind a) {
	final switch (a) {
		case AssertOrForbidKind.assert_:
			return safeCStr!"assert failed";
		case AssertOrForbidKind.forbid:
			return safeCStr!"forbid failed";
	}
}

ConcreteExpr concretizeExpr(ref ConcretizeExprCtx ctx, in Locals locals, ref ExprAndType a) =>
	concretizeExpr(ctx, getConcreteType(ctx, a.type), locals, a.expr);

ConcreteExpr concretizeExpr(ref ConcretizeExprCtx ctx, ConcreteType type, in Locals locals, ref Expr a) {
	FileAndRange range = a.range;
	if (isBogus(type))
		return concretizeBogus(ctx.concretizeCtx, type, range);
	return a.kind.match!ConcreteExpr(
		(ExprKind.AssertOrForbid x) =>
			concretizeAssertOrForbid(ctx, type, range, locals, x),
		(ExprKind.Bogus) =>
			concretizeBogus(ctx.concretizeCtx, type, range),
		(ExprKind.Call x) =>
			concretizeCall(ctx, type, range, locals, x),
		(ExprKind.ClosureGet x) =>
			concretizeClosureGet(ctx, type, range, x),
		(ExprKind.ClosureSet x) =>
			concretizeClosureSet(ctx, type, range, locals, x),
		(ExprKind.FunPtr x) =>
			concretizeFunPtr(ctx, type, range, x),
		(ref ExprKind.If x) =>
			concretizeIf(ctx, type, range, locals, x),
		(ref ExprKind.IfOption x) =>
			concretizeIfOption(ctx, type, range, locals, x),
		(ref ExprKind.Lambda x) =>
			concretizeLambda(ctx, type, range, locals, x),
		(ref ExprKind.Let x) =>
			concretizeLet(ctx, type, range, locals, x),
		(ref ExprKind.Literal x) =>
			ConcreteExpr(type, range, ConcreteExprKind(x.value)),
		(ExprKind.LiteralCString x) =>
			cStrConcreteExpr(ctx.concretizeCtx, type, range, x.value),
		(ExprKind.LiteralSymbol x) =>
			ConcreteExpr(type, range, ConcreteExprKind(constantSym(ctx.concretizeCtx, x.value))),
		(ExprKind.LocalGet x) =>
			concretizeLocalGet(ctx, type, range, locals, x.local),
		(ref ExprKind.LocalSet x) =>
			concretizeLocalSet(ctx, type, range, locals, x),
		(ref ExprKind.Loop x) =>
			concretizeLoop(ctx, type, range, locals, x),
		(ref ExprKind.LoopBreak x) =>
			concretizeLoopBreak(ctx, type, range, locals, x),
		(ExprKind.LoopContinue x) =>
			concretizeLoopContinue(ctx, type, range, locals, x),
		(ref ExprKind.LoopUntil x) =>
			concretizeLoopUntil(ctx, type, range, locals, x),
		(ref ExprKind.LoopWhile x) =>
			concretizeLoopWhile(ctx, type, range, locals, x),
		(ref ExprKind.MatchEnum x) =>
			concretizeMatchEnum(ctx, type, range, locals, x),
		(ref ExprKind.MatchUnion x) =>
			concretizeMatchUnion(ctx, type, range, locals, x),
		(ref ExprKind.PtrToField x) =>
			concretizePtrToField(ctx, type, range, locals, x),
		(ExprKind.PtrToLocal x) =>
			concretizePtrToLocal(ctx, type, range, locals, x),
		(ref ExprKind.Seq x) {
			ConcreteExpr first = concretizeExpr(ctx, voidType(ctx), locals, x.first);
			ConcreteExpr then = concretizeExpr(ctx, type, locals, x.then);
			return first.kind.isA!Constant
				? then
				: ConcreteExpr(type, range, ConcreteExprKind(
					allocate(ctx.alloc, ConcreteExprKind.Seq(first, then))));
		},
		(ref ExprKind.Throw x) =>
			makeThrow(ctx.alloc, range, type, concretizeExpr(ctx, cStrType(ctx.concretizeCtx), locals, x.thrown)));
}

ConstantsOrExprs constantsOrExprsArr(
	ref ConcretizeExprCtx ctx,
	FileAndRange range,
	ConcreteType arrayType,
	ConstantsOrExprs args,
) =>
	args.match!ConstantsOrExprs(
		(Constant[] constants) =>
			ConstantsOrExprs(arrLiteral!Constant(ctx.alloc, [
				getConstantArr(ctx.alloc, ctx.allConstants, mustBeByVal(arrayType), constants)])),
		(ConcreteExpr[] exprs) =>
			ConstantsOrExprs(arrLiteral!ConcreteExpr(ctx.alloc, [
				ConcreteExpr(arrayType, range, ConcreteExprKind(
					allocate(ctx.alloc, ConcreteExprKind.CreateArr(exprs))))])));

Opt!Constant tryEvalConstant(
	in ConcreteFun fn,
	in Constant[] /*parameters*/,
	in VersionInfo versionInfo,
) =>
	body_(fn).matchIn!(Opt!Constant)(
		(in ConcreteFunBody.Builtin) {
			// TODO: don't just special-case this one..
			Opt!Sym name = name(fn);
			return has(name) ? tryEvalConstantBuiltin(force(name), versionInfo) : none!Constant;
		},
		(in Constant x) =>
			some(x),
		(in ConcreteFunBody.CreateRecord) => none!Constant,
		(in ConcreteFunBody.CreateUnion) => none!Constant,
		(in EnumFunction _) => none!Constant,
		(in ConcreteFunBody.Extern) => none!Constant,
		(in ConcreteExpr x) =>
			x.kind.isA!Constant
				? some(x.kind.as!Constant)
				: none!Constant,
		(in ConcreteFunBody.FlagsFn) => none!Constant,
		(in ConcreteFunBody.RecordFieldGet) => none!Constant,
		(in ConcreteFunBody.RecordFieldPointer) => none!Constant,
		(in ConcreteFunBody.RecordFieldSet) => none!Constant,
		(in ConcreteFunBody.VarGet) => none!Constant,
		(in ConcreteFunBody.VarSet) => none!Constant);

Opt!Constant tryEvalConstantBuiltin(Sym name, in VersionInfo versionInfo) {
	switch (name.value) {
		case sym!"is-big-endian".value:
			return some(constantBool(versionInfo.isBigEndian));
		case sym!"is-interpreted".value:
			return some(constantBool(versionInfo.isInterpreted));
		case sym!"is-jit".value:
			return some(constantBool(versionInfo.isJit));
		case sym!"is-single-threaded".value:
			return some(constantBool(versionInfo.isSingleThreaded));
		case sym!"is-wasm".value:
			return some(constantBool(versionInfo.isWasm));
		case sym!"is-windows".value:
			return some(constantBool(versionInfo.isWindows));
		default:
			return none!Constant;
	}
}
