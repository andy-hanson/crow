module concretize.safeValue;

@safe @nogc pure nothrow:

import concretize.concretizeCtx : addConcreteFun, ConcretizeCtx, voidType;
import concretize.concretizeExpr : nextLambdaImplId;
import concretize.constantsOrExprs : asConstantsOrExprs, ConstantsOrExprs;
import concretize.allConstantsBuilder : getConstantPtr;
import model.concreteModel :
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
	ConcreteStructSource,
	ConcreteType,
	isSelfMutable,
	ReferenceKind,
	setBody;
import model.constant : Constant, constantZero;
import model.model : EnumValue;
import util.alloc.alloc : Alloc;
import util.col.arrUtil : map, mapWithIndex;
import util.memory : allocate, allocateMut;
import util.opt : force, has, none, some;
import util.ptr : castImmutable, ptrTrustMe;
import util.sourceRange : FileAndRange;
import util.util : todo;

immutable(ConcreteFunBody) bodyForSafeValue(
	ref ConcretizeCtx concretizeCtx,
	immutable ConcreteFun* containingFun,
	immutable FileAndRange range,
	immutable ConcreteType type,
) {
	Ctx ctx = Ctx(ptrTrustMe(concretizeCtx), containingFun);
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
		case ReferenceKind.byVal:
			return inner;
		case ReferenceKind.byRef:
			return immutable ConcreteExpr(type, range, inner.kind.isA!Constant
				? immutable ConcreteExprKind(getConstantPtr(
					ctx.alloc,
					ctx.concretizeCtx.allConstants,
					type.struct_,
					inner.kind.as!Constant))
				: immutable ConcreteExprKind(allocate(ctx.alloc, immutable ConcreteExprKind.Alloc(inner))));
		case ReferenceKind.byRefRef:
			return todo!(immutable ConcreteExpr)("!");
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

	return body_(*struct_).match!(immutable ConcreteExpr)(
		(immutable ConcreteStructBody.Builtin it) {
			final switch (it.kind) {
				case BuiltinStructKind.bool_:
				case BuiltinStructKind.char8:
				case BuiltinStructKind.int8:
				case BuiltinStructKind.int16:
				case BuiltinStructKind.int32:
				case BuiltinStructKind.int64:
				case BuiltinStructKind.nat8:
				case BuiltinStructKind.nat16:
				case BuiltinStructKind.nat32:
				case BuiltinStructKind.nat64:
					return fromConstant(immutable Constant(immutable Constant.Integral(0)));
				case BuiltinStructKind.float32:
				case BuiltinStructKind.float64:
					return fromConstant(immutable Constant(immutable Constant.Float(0)));
				case BuiltinStructKind.fun:
					return safeFunValue(ctx, range, struct_);
				case BuiltinStructKind.funPointerN:
				case BuiltinStructKind.pointerConst:
				case BuiltinStructKind.pointerMut:
				case BuiltinStructKind.void_:
					return fromConstant(constantZero);
			}
		},
		(immutable ConcreteStructBody.Enum x) {
			immutable long value = x.values.match!(immutable long)(
				(immutable(size_t)) =>
					immutable long(0),
				(immutable EnumValue[] values) =>
					values[0].asSigned());
			return fromConstant(immutable Constant(immutable Constant.Integral(value)));
		},
		(immutable ConcreteStructBody.Extern) =>
			todo!(immutable ConcreteExpr)("!"),
		(immutable ConcreteStructBody.Flags) =>
			fromConstant(immutable Constant(immutable Constant.Integral(0))),
		(immutable ConcreteStructBody.Record it) {
			immutable ConcreteExpr[] fieldExprs = map(ctx.alloc, it.fields, (ref immutable ConcreteField field) =>
				safeValueForType(ctx, range, field.type));
			immutable ConstantsOrExprs fieldConstantsOrExprs = isSelfMutable(*struct_)
				? immutable ConstantsOrExprs(fieldExprs)
				: asConstantsOrExprs(ctx.alloc, fieldExprs);
			return immutable ConcreteExpr(type, range, fieldConstantsOrExprs.match!(immutable ConcreteExprKind)(
				(immutable Constant[] constants) =>
					immutable ConcreteExprKind(immutable Constant(immutable Constant.Record(constants))),
				(immutable ConcreteExpr[] exprs) =>
					immutable ConcreteExprKind(immutable ConcreteExprKind.CreateRecord(exprs))));
		},
		(immutable ConcreteStructBody.Union it) {
			immutable ConcreteExpr member = has(it.members[0])
				? safeValueForType(ctx, range, force(it.members[0]))
				: fromConstant(constantZero);
			//TODO: we need to find the function that creates that union...
			return member.kind.isA!Constant
				? fromConstant(immutable Constant(
					allocate(ctx.alloc, immutable Constant.Union(0, member.kind.as!Constant))))
				: immutable ConcreteExpr(type, range, immutable ConcreteExprKind(
					allocate(ctx.alloc, immutable ConcreteExprKind.CreateUnion(0, member))));
		});
}

immutable(ConcreteExpr) safeFunValue(ref Ctx ctx, immutable FileAndRange range, immutable ConcreteStruct* struct_) {
	immutable ConcreteType[] typeArgs = struct_.source.as!(ConcreteStructSource.Inst).typeArgs;
	immutable ConcreteType returnType = typeArgs[0];
	immutable ConcreteParam[] params = mapWithIndex!(immutable ConcreteParam, ConcreteType)(
		ctx.alloc,
		typeArgs[1 .. $],
		(immutable size_t index, scope ref immutable ConcreteType paramType) =>
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
