module concretize.safeValue;

@safe @nogc pure nothrow:

import concretize.concretizeCtx : addConcreteFun, ConcretizeCtx, voidType;
import concretize.concretizeExpr : closureParam, nextLambdaImplId;
import concretize.constantsOrExprs : asConstantsOrExprs, ConstantsOrExprs, matchConstantsOrExprs;
import concretize.allConstantsBuilder : getConstantPtr;
import model.concreteModel :
	asConstant,
	asInst,
	body_,
	BuiltinStructKind,
	ConcreteExpr,
	ConcreteExprKind,
	ConcreteField,
	ConcreteFun,
	ConcreteFunBody,
	ConcreteFunSource,
	ConcreteLambdaImpl,
	ConcreteParam,
	ConcreteParamSource,
	ConcreteStruct,
	ConcreteStructBody,
	ConcreteType,
	isConstant,
	isSelfMutable,
	matchConcreteStructBody,
	matchEnum,
	NeedsCtx,
	setBody;
import model.constant : Constant;
import model.model : EnumValue;
import util.alloc.alloc : Alloc;
import util.collection.arrUtil : map, mapWithIndex;
import util.memory : allocate, allocateMut;
import util.opt : force, has, some;
import util.ptr : castImmutable, Ptr, ptrTrustMe_mut;
import util.sourceRange : FileAndRange;

immutable(ConcreteFunBody) bodyForSafeValue(
	ref Alloc alloc,
	ref ConcretizeCtx concretizeCtx,
	immutable Ptr!ConcreteFun containingFun,
	immutable FileAndRange range,
	immutable ConcreteType type,
) {
	Ctx ctx = Ctx(ptrTrustMe_mut(concretizeCtx), containingFun);
	return immutable ConcreteFunBody(safeValueForType(alloc, ctx, range, type));
}

private:

struct Ctx {
	@safe @nogc pure nothrow:

	Ptr!ConcretizeCtx concretizeCtxPtr;
	immutable Ptr!ConcreteFun containingFun;
	size_t nextLambdaIndex;

	ref ConcretizeCtx concretizeCtx() return scope {
		return concretizeCtxPtr.deref();
	}
}

immutable(ConcreteExpr) safeValueForType(
	ref Alloc alloc,
	ref Ctx ctx,
	immutable FileAndRange range,
	immutable ConcreteType type,
) {
	immutable ConcreteExpr inner = safeValueForStruct(alloc, ctx, range, type.struct_);
	return type.isPointer
		? immutable ConcreteExpr(type, range, isConstant(inner.kind)
			? immutable ConcreteExprKind(getConstantPtr(
				alloc,
				ctx.concretizeCtx.allConstants,
				type.struct_,
				asConstant(inner.kind)))
			: immutable ConcreteExprKind(allocate(alloc, immutable ConcreteExprKind.Alloc(inner))))
		: inner;
}

immutable(ConcreteExpr) safeValueForStruct(
	ref Alloc alloc,
	ref Ctx ctx,
	immutable FileAndRange range,
	immutable Ptr!ConcreteStruct struct_,
) {
	immutable ConcreteType type = immutable ConcreteType(false, struct_);
	immutable(ConcreteExpr) fromConstant(immutable Constant constant) {
		return immutable ConcreteExpr(
			type,
			range,
			immutable ConcreteExprKind(constant));
	}

	return matchConcreteStructBody!(immutable ConcreteExpr)(
		body_(struct_.deref()),
		(ref immutable ConcreteStructBody.Builtin it) {
			final switch (it.kind) {
				case BuiltinStructKind.bool_:
					return fromConstant(immutable Constant(immutable Constant.BoolConstant(false)));
				case BuiltinStructKind.char_:
					return fromConstant(immutable Constant(immutable Constant.Integral('\0')));
				case BuiltinStructKind.float32:
				case BuiltinStructKind.float64:
					return fromConstant(immutable Constant(0.0));
				case BuiltinStructKind.fun:
					return safeFunValue(alloc, ctx, range, struct_);
				case BuiltinStructKind.funPtrN:
					return fromConstant(immutable Constant(immutable Constant.Null()));
				case BuiltinStructKind.int8:
				case BuiltinStructKind.int16:
				case BuiltinStructKind.int32:
				case BuiltinStructKind.int64:
				case BuiltinStructKind.nat8:
				case BuiltinStructKind.nat16:
				case BuiltinStructKind.nat32:
				case BuiltinStructKind.nat64:
					return fromConstant(immutable Constant(immutable Constant.Integral(0)));
				case BuiltinStructKind.ptrConst:
				case BuiltinStructKind.ptrMut:
					return fromConstant(immutable Constant(immutable Constant.Null()));
				case BuiltinStructKind.void_:
					return fromConstant(immutable Constant(immutable Constant.Void()));
			}
		},
		(ref immutable ConcreteStructBody.Enum it) {
			immutable long value = matchEnum!(immutable long)(
				it,
				(immutable(size_t)) =>
					immutable long(0),
				(immutable EnumValue[] values) =>
					values[0].asSigned());
			return fromConstant(immutable Constant(immutable Constant.Integral(value)));
		},
		(ref immutable ConcreteStructBody.Flags) =>
			fromConstant(immutable Constant(immutable Constant.Integral(0))),
		(ref immutable ConcreteStructBody.ExternPtr) =>
			fromConstant(immutable Constant(immutable Constant.Null())),
		(ref immutable ConcreteStructBody.Record it) {
			immutable ConcreteExpr[] fieldExprs = map!(immutable ConcreteExpr, ConcreteField)(
				alloc,
				it.fields,
				(ref immutable ConcreteField field) =>
					safeValueForType(alloc, ctx, range, field.type));
			immutable ConstantsOrExprs fieldConstantsOrExprs = isSelfMutable(struct_.deref())
				? immutable ConstantsOrExprs(fieldExprs)
				: asConstantsOrExprs(alloc, fieldExprs);
			return immutable ConcreteExpr(type, range, matchConstantsOrExprs!(immutable ConcreteExprKind)(
				fieldConstantsOrExprs,
				(ref immutable Constant[] constants) =>
					immutable ConcreteExprKind(immutable Constant(immutable Constant.Record(constants))),
				(ref immutable ConcreteExpr[] exprs) =>
					immutable ConcreteExprKind(immutable ConcreteExprKind.CreateRecord(exprs))));
		},
		(ref immutable ConcreteStructBody.Union it) {
			immutable ConcreteExpr member = has(it.members[0])
				? safeValueForType(alloc, ctx, range, force(it.members[0]))
				: fromConstant(immutable Constant(immutable Constant.Void()));
			//TODO: we need to find the function that creates that union...
			return isConstant(member.kind)
				? fromConstant(immutable Constant(
					allocate(alloc, immutable Constant.Union(0, asConstant(member.kind)))))
				: immutable ConcreteExpr(type, range, immutable ConcreteExprKind(
					allocate(alloc, immutable ConcreteExprKind.CreateUnion(0, member))));
		});
}

immutable(ConcreteExpr) safeFunValue(
	ref Alloc alloc,
	ref Ctx ctx,
	immutable FileAndRange range,
	immutable Ptr!ConcreteStruct struct_,
) {
	immutable ConcreteType[] typeArgs = asInst(struct_.deref().source).typeArgs;
	immutable ConcreteType returnType = typeArgs[0];
	immutable ConcreteParam[] params = mapWithIndex!(immutable ConcreteParam, ConcreteType)(
		alloc,
		typeArgs[1 .. $],
		(immutable size_t index, ref immutable ConcreteType paramType) =>
			immutable ConcreteParam(
				immutable ConcreteParamSource(immutable ConcreteParamSource.Synthetic()),
				some(index),
				paramType));
	immutable size_t lambdaIndex = ctx.nextLambdaIndex;
	ctx.nextLambdaIndex++;
	immutable ConcreteType closureType = voidType(alloc, ctx.concretizeCtx);
	Ptr!ConcreteFun fun = allocateMut(alloc, ConcreteFun(
		immutable ConcreteFunSource(
			allocate(alloc, immutable ConcreteFunSource.Lambda(range, ctx.containingFun, lambdaIndex))),
		returnType,
		NeedsCtx.yes,
		some(closureParam(alloc, closureType)),
		params));
	setBody(fun.deref(), immutable ConcreteFunBody(safeValueForType(alloc, ctx, range, returnType)));
	immutable Ptr!ConcreteFun impl = castImmutable(fun);
	addConcreteFun(alloc, ctx.concretizeCtx, impl);
	immutable size_t id = nextLambdaImplId(
		alloc,
		ctx.concretizeCtx,
		struct_,
		immutable ConcreteLambdaImpl(closureType, impl));
	return immutable ConcreteExpr(
		immutable ConcreteType(false, struct_),
		range,
		immutable ConcreteExprKind(allocate(alloc, immutable ConcreteExprKind.Lambda(
			id,
			immutable ConcreteExpr(
				closureType,
				range,
				immutable ConcreteExprKind(immutable Constant(immutable Constant.Void())))))));
}
