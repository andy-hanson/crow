module concretize.safeValue;

@safe @nogc pure nothrow:

import concretize.concretizeCtx : addConcreteFun, ConcretizeCtx, voidType;
import concretize.concretizeExpr : nextLambdaImplId;
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
	ReferenceKind,
	setBody;
import model.constant : Constant;
import model.model : EnumValue;
import util.alloc.alloc : Alloc;
import util.col.arrUtil : map, mapWithIndex;
import util.memory : allocate, allocateMut;
import util.opt : force, has, none, some;
import util.ptr : castImmutable, castNonScope_mut;
import util.sourceRange : FileAndRange;

immutable(ConcreteFunBody) bodyForSafeValue(
	ref ConcretizeCtx concretizeCtx,
	immutable ConcreteFun* containingFun,
	immutable FileAndRange range,
	immutable ConcreteType type,
) {
	Ctx ctx = Ctx(castNonScope_mut(&concretizeCtx), containingFun);
	return immutable ConcreteFunBody(safeValueForType(ctx, range, type));
}

private:

struct Ctx {
	@safe @nogc pure nothrow:

	ConcretizeCtx* concretizeCtxPtr;
	immutable ConcreteFun* containingFun;
	size_t nextLambdaIndex;

	ref Alloc alloc() return scope =>
		concretizeCtx.alloc;

	ref ConcretizeCtx concretizeCtx() return scope =>
		*concretizeCtxPtr;
}

immutable(ConcreteExpr) safeValueForType(ref Ctx ctx, immutable FileAndRange range, immutable ConcreteType type) {
	immutable ConcreteExpr inner = safeValueForStruct(ctx, range, type.struct_);
	final switch (type.reference) {
		case ReferenceKind.byRef:
			return immutable ConcreteExpr(type, range, isConstant(inner.kind)
				? immutable ConcreteExprKind(getConstantPtr(
					ctx.alloc,
					ctx.concretizeCtx.allConstants,
					type.struct_,
					asConstant(inner.kind)))
				: immutable ConcreteExprKind(allocate(ctx.alloc, immutable ConcreteExprKind.Alloc(inner))));
		case ReferenceKind.byVal:
			return inner;
	}
}

immutable(ConcreteExpr) safeValueForStruct(
	ref Ctx ctx,
	immutable FileAndRange range,
	immutable ConcreteStruct* struct_,
) {
	immutable ConcreteType type = immutable ConcreteType(ReferenceKind.byVal, struct_);
	immutable(ConcreteExpr) fromConstant(immutable Constant constant) =>
		immutable ConcreteExpr(
			type,
			range,
			immutable ConcreteExprKind(constant));

	return matchConcreteStructBody!(immutable ConcreteExpr)(
		body_(*struct_),
		(ref immutable ConcreteStructBody.Builtin it) {
			final switch (it.kind) {
				case BuiltinStructKind.bool_:
					return fromConstant(immutable Constant(immutable Constant.BoolConstant(false)));
				case BuiltinStructKind.char8:
					return fromConstant(immutable Constant(immutable Constant.Integral('\0')));
				case BuiltinStructKind.float32:
				case BuiltinStructKind.float64:
					return fromConstant(immutable Constant(immutable Constant.Float(0)));
				case BuiltinStructKind.fun:
					return safeFunValue(ctx, range, struct_);
				case BuiltinStructKind.funPointerN:
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
				case BuiltinStructKind.pointerConst:
				case BuiltinStructKind.pointerMut:
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
				ctx.alloc,
				it.fields,
				(ref immutable ConcreteField field) =>
					safeValueForType(ctx, range, field.type));
			immutable ConstantsOrExprs fieldConstantsOrExprs = isSelfMutable(*struct_)
				? immutable ConstantsOrExprs(fieldExprs)
				: asConstantsOrExprs(ctx.alloc, fieldExprs);
			return immutable ConcreteExpr(type, range, matchConstantsOrExprs!(immutable ConcreteExprKind)(
				fieldConstantsOrExprs,
				(ref immutable Constant[] constants) =>
					immutable ConcreteExprKind(immutable Constant(immutable Constant.Record(constants))),
				(ref immutable ConcreteExpr[] exprs) =>
					immutable ConcreteExprKind(immutable ConcreteExprKind.CreateRecord(exprs))));
		},
		(ref immutable ConcreteStructBody.Union it) {
			immutable ConcreteExpr member = has(it.members[0])
				? safeValueForType(ctx, range, force(it.members[0]))
				: fromConstant(immutable Constant(immutable Constant.Void()));
			//TODO: we need to find the function that creates that union...
			return isConstant(member.kind)
				? fromConstant(immutable Constant(
					allocate(ctx.alloc, immutable Constant.Union(0, asConstant(member.kind)))))
				: immutable ConcreteExpr(type, range, immutable ConcreteExprKind(
					allocate(ctx.alloc, immutable ConcreteExprKind.CreateUnion(0, member))));
		});
}

immutable(ConcreteExpr) safeFunValue(ref Ctx ctx, immutable FileAndRange range, immutable ConcreteStruct* struct_) {
	immutable ConcreteType[] typeArgs = asInst(struct_.source).typeArgs;
	immutable ConcreteType returnType = typeArgs[0];
	immutable ConcreteParam[] params = mapWithIndex!(immutable ConcreteParam, ConcreteType)(
		ctx.alloc,
		typeArgs[1 .. $],
		(immutable size_t index, ref immutable ConcreteType paramType) =>
			immutable ConcreteParam(
				immutable ConcreteParamSource(immutable ConcreteParamSource.Synthetic()),
				some(index),
				paramType));
	immutable size_t lambdaIndex = ctx.nextLambdaIndex;
	ctx.nextLambdaIndex++;
	immutable ConcreteType closureType = voidType(ctx.concretizeCtx);
	ConcreteFun* fun = allocateMut(ctx.alloc, ConcreteFun(
		immutable ConcreteFunSource(
			allocate(ctx.alloc, immutable ConcreteFunSource.Lambda(range, ctx.containingFun, lambdaIndex))),
		returnType,
		none!(ConcreteParam*),
		params));
	setBody(*fun, immutable ConcreteFunBody(safeValueForType(ctx, range, returnType)));
	immutable ConcreteFun* impl = castImmutable(fun);
	addConcreteFun(ctx.concretizeCtx, impl);
	immutable size_t id =
		nextLambdaImplId(ctx.concretizeCtx, struct_, immutable ConcreteLambdaImpl(closureType, impl));
	return immutable ConcreteExpr(
		immutable ConcreteType(ReferenceKind.byVal, struct_),
		range,
		immutable ConcreteExprKind(immutable ConcreteExprKind.Lambda(id, none!(ConcreteExpr*))));
}
