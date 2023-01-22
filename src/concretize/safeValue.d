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
	ConcreteLocal,
	ConcreteLocalSource,
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
import util.col.arrUtil : map;
import util.memory : allocate;
import util.opt : force, has, none;
import util.ptr : ptrTrustMe;
import util.sourceRange : FileAndRange;
import util.sym : sym;
import util.util : todo;

ConcreteFunBody bodyForSafeValue(
	ref ConcretizeCtx concretizeCtx,
	ConcreteFun* containingFun,
	FileAndRange range,
	ConcreteType type,
) {
	Ctx ctx = Ctx(ptrTrustMe(concretizeCtx), containingFun);
	return ConcreteFunBody(safeValueForType(ctx, range, type));
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

ConcreteExpr safeValueForType(ref Ctx ctx, FileAndRange range, ConcreteType type) {
	ConcreteExpr inner = safeValueForStruct(ctx, range, type.struct_);
	final switch (type.reference) {
		case ReferenceKind.byVal:
			return inner;
		case ReferenceKind.byRef:
			return ConcreteExpr(type, range, inner.kind.isA!Constant
				? ConcreteExprKind(getConstantPtr(
					ctx.alloc,
					ctx.concretizeCtx.allConstants,
					type.struct_,
					inner.kind.as!Constant))
				: ConcreteExprKind(allocate(ctx.alloc, ConcreteExprKind.Alloc(inner))));
		case ReferenceKind.byRefRef:
			return todo!ConcreteExpr("!");
	}
}

ConcreteExpr safeValueForStruct(ref Ctx ctx, FileAndRange range, ConcreteStruct* struct_) {
	ConcreteType type = ConcreteType(ReferenceKind.byVal, struct_);
	ConcreteExpr fromConstant(Constant constant) {
		return ConcreteExpr(type, range, ConcreteExprKind(constant));
	}

	return body_(*struct_).match!ConcreteExpr(
		(ConcreteStructBody.Builtin it) {
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
					return fromConstant(Constant(Constant.Integral(0)));
				case BuiltinStructKind.float32:
				case BuiltinStructKind.float64:
					return fromConstant(Constant(Constant.Float(0)));
				case BuiltinStructKind.fun:
					return safeFunValue(ctx, range, struct_);
				case BuiltinStructKind.funPointer:
				case BuiltinStructKind.pointerConst:
				case BuiltinStructKind.pointerMut:
				case BuiltinStructKind.void_:
					return fromConstant(constantZero);
			}
		},
		(ConcreteStructBody.Enum x) {
			long value = x.values.match!long(
				(size_t) =>
					0,
				(EnumValue[] values) =>
					values[0].asSigned());
			return fromConstant(Constant(Constant.Integral(value)));
		},
		(ConcreteStructBody.Extern) =>
			todo!ConcreteExpr("!"),
		(ConcreteStructBody.Flags) =>
			fromConstant(Constant(Constant.Integral(0))),
		(ConcreteStructBody.Record it) {
			ConcreteExpr[] fieldExprs = map(ctx.alloc, it.fields, (ref ConcreteField field) =>
				safeValueForType(ctx, range, field.type));
			ConstantsOrExprs fieldConstantsOrExprs = isSelfMutable(*struct_)
				? ConstantsOrExprs(fieldExprs)
				: asConstantsOrExprs(ctx.alloc, fieldExprs);
			return ConcreteExpr(type, range, fieldConstantsOrExprs.match!ConcreteExprKind(
				(Constant[] constants) =>
					ConcreteExprKind(Constant(Constant.Record(constants))),
				(ConcreteExpr[] exprs) =>
					ConcreteExprKind(ConcreteExprKind.CreateRecord(exprs))));
		},
		(ConcreteStructBody.Union it) {
			ConcreteExpr member = has(it.members[0])
				? safeValueForType(ctx, range, force(it.members[0]))
				: fromConstant(constantZero);
			//TODO: we need to find the function that creates that union...
			return member.kind.isA!Constant
				? fromConstant(Constant(
					allocate(ctx.alloc, Constant.Union(0, member.kind.as!Constant))))
				: ConcreteExpr(type, range, ConcreteExprKind(
					allocate(ctx.alloc, ConcreteExprKind.CreateUnion(0, member))));
		});
}

ConcreteExpr safeFunValue(ref Ctx ctx, FileAndRange range, ConcreteStruct* struct_) {
	ConcreteType[] typeArgs = struct_.source.as!(ConcreteStructSource.Inst).typeArgs;
	ConcreteType returnType = typeArgs[0];
	ConcreteLocal[] params =
		map!(ConcreteLocal, ConcreteType)(ctx.alloc, typeArgs[1 .. $], (ref ConcreteType paramType) =>
			ConcreteLocal(ConcreteLocalSource(ConcreteLocalSource.Generated(sym!"arg")), paramType));
	size_t lambdaIndex = ctx.nextLambdaIndex;
	ctx.nextLambdaIndex++;
	ConcreteType closureType = voidType(ctx.concretizeCtx);
	ConcreteFun* fun = allocate(ctx.alloc, ConcreteFun(
		ConcreteFunSource(allocate(ctx.alloc, ConcreteFunSource.Lambda(range, ctx.containingFun, lambdaIndex))),
		returnType,
		params));
	setBody(*fun, ConcreteFunBody(safeValueForType(ctx, range, returnType)));
	addConcreteFun(ctx.concretizeCtx, fun);
	size_t id = nextLambdaImplId(ctx.concretizeCtx, struct_, ConcreteLambdaImpl(closureType, fun));
	return ConcreteExpr(
		ConcreteType(ReferenceKind.byVal, struct_),
		range,
		ConcreteExprKind(ConcreteExprKind.Lambda(id, none!(ConcreteExpr*))));
}
