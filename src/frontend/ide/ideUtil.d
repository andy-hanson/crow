module frontend.ide.ideUtil;

@safe @nogc pure nothrow:

import frontend.ide.position : ExprRef;
import model.ast : DestructureAst, ModifierAst, NameAndRange, ParamsAst, SpecUseAst, TypeAst;
import model.model :
	arrayElementType,
	AssertOrForbidExpr,
	BogusExpr,
	CallExpr,
	ClosureGetExpr,
	ClosureSetExpr,
	CommonTypes,
	Expr,
	ExprAndType,
	FunDecl,
	FunDeclSource,
	FunPointerExpr,
	IfExpr,
	IfOptionExpr,
	LambdaExpr,
	LetExpr,
	LiteralExpr,
	LiteralStringLikeExpr,
	LocalGetExpr,
	LocalSetExpr,
	LoopBreakExpr,
	LoopContinueExpr,
	LoopExpr,
	LoopUntilExpr,
	LoopWhileExpr,
	MatchEnumExpr,
	MatchUnionExpr,
	PtrToFieldExpr,
	PtrToLocalExpr,
	SeqExpr,
	SpecInst,
	SpecDecl,
	StructInst,
	Test,
	ThrowExpr,
	TrustedExpr,
	Type,
	TypedExpr,
	TypeParamIndex;
import util.col.array : arrayOfSingle, count, first, firstPointer, firstZip, firstZipPointerFirst, isEmpty, only, only2;
import util.opt : force, has, none, Opt, optOr;
import util.sourceRange : UriAndRange;
import util.util : ptrTrustMe;

alias ReferenceCb = void delegate(in UriAndRange) @safe @nogc pure nothrow;

private alias SpecCb = void delegate(SpecInst*, in SpecUseAst) @safe @nogc pure nothrow;

ExprRef funBodyExprRef(FunDecl* a) =>
	ExprRef(&a.body_.as!Expr(), a.returnType);
ExprRef testBodyExprRef(ref CommonTypes commonTypes, Test* a) =>
	ExprRef(&a.body_, a.returnType(commonTypes));

void eachSpecParent(in SpecDecl a, in SpecCb cb) {
	Opt!bool res = eachSpec!bool(a.parents, a.ast.modifiers, (SpecInst* x, in SpecUseAst ast) {
		cb(x, ast);
		return none!bool;
	});
	assert(!has(res));
}

void eachFunSpec(in FunDecl a, in SpecCb cb) {
	if (a.source.isA!(FunDeclSource.Ast)) {
		Opt!bool res = eachSpec!bool(
			a.specs, a.source.as!(FunDeclSource.Ast).ast.modifiers,
			(SpecInst* x, in SpecUseAst y) {
				cb(x, y);
				return none!bool;
			});
		assert(!has(res));
	}
}

bool specsMatch(in SpecInst*[] specs, in ModifierAst[] modifiers) =>
	specs.length == count!ModifierAst(modifiers, (in ModifierAst x) => x.isA!SpecUseAst);

private Opt!Out eachSpec(Out)(
	in SpecInst*[] specs,
	in ModifierAst[] modifiers,
	in Opt!Out delegate(SpecInst*, in SpecUseAst) @safe @nogc pure nothrow cb,
) {
	if (specsMatch(specs, modifiers)) {
		size_t specI = 0;
		foreach (ref ModifierAst mod; modifiers) {
			if (mod.isA!SpecUseAst) {
				Opt!Out res = cb(specs[specI], mod.as!SpecUseAst);
				if (has(res))
					return res;
				specI++;
			}
		}
		assert(specI == specs.length);
	}
	return none!Out;
}

alias TypeCb = void delegate(in Type, in TypeAst) @safe @nogc pure nothrow;
private alias TypeCbOpt(T) = Opt!T delegate(in Type, in TypeAst) @safe @nogc pure nothrow;

Opt!T eachTypeComponent(T)(in Type type, in TypeAst ast, in TypeCbOpt!T cb) =>
	type.matchIn!(Opt!T)(
		(in Type.Bogus) =>
			none!T,
		(in TypeParamIndex _) =>
			none!T,
		(in StructInst x) =>
			findInTypeArgs!T(x.typeArgs, ast, cb));

void eachPackedTypeArg(in Type[] typeArgs, in Opt!TypeAst ast, in TypeCb cb) {
	Opt!bool x = findInPackedTypeArgs!bool(typeArgs, ast, (in Type argType, in TypeAst argAst) {
		cb(argType, argAst);
		return none!bool;
	});
	assert(!has(x));
}

Opt!T findInPackedTypeArgs(T)(in Type[] typeArgs, in Opt!TypeAst ast, in TypeCbOpt!T cb) {
	if (has(ast))
		return zipEachTypeArgMayUnpackTuple!T(typeArgs, force(ast), cb);
	else {
		assert(isEmpty(typeArgs));
		return none!T;
	}
}

private Opt!T findInTypeArgs(T)(in Type[] typeArgs, in TypeAst ast, in TypeCbOpt!T cb) =>
	ast.match!(Opt!T)(
		(TypeAst.Bogus) =>
			none!T,
		(ref TypeAst.Fun x) {
			Type[2] returnAndParam = only2(typeArgs);
			return optOr!T(
				cb(returnAndParam[0], x.returnType),
				() => eachFunTypeParameter!T(returnAndParam[1], x.params, cb));
		},
		(ref TypeAst.Map x) =>
			zipEachTypeArg!T(typeArgs, x.kv, cb),
		(NameAndRange _) =>
			// For a type alias, 'typeArgs' may be non-empty as it comes from the alias' target type.
			// But ignore them in any case.
			none!T,
		(ref TypeAst.SuffixName x) =>
			zipEachTypeArgMayUnpackTuple!T(typeArgs, x.left, cb),
		(TypeAst.SuffixSpecial x) =>
			zipEachTypeArgMayUnpackTuple!T(typeArgs, *x.left, cb),
		(TypeAst.Tuple x) =>
			zipEachTypeArg!T(typeArgs, x.members, cb));

private Opt!T zipEachTypeArgMayUnpackTuple(T)(in Type[] typeArgs, in TypeAst typeArgAst, in TypeCbOpt!T cb) =>
	zipEachTypeArg!T(
		typeArgs,
		typeArgs.length == 1 ? arrayOfSingle(ptrTrustMe(typeArgAst)) : typeArgAst.as!(TypeAst.Tuple).members,
		cb);

private Opt!T zipEachTypeArg(T)(in Type[] typeArgs, in TypeAst[] typeArgAsts, in TypeCbOpt!T cb) =>
	firstZip!(T, Type, TypeAst)(typeArgs, typeArgAsts, (Type x, TypeAst y) => cb(x, y));

private Opt!T eachFunTypeParameter(T)(in Type paramsType, in ParamsAst paramsAst, in TypeCbOpt!T cb) =>
	paramsAst.matchIn!(Opt!T)(
		(in DestructureAst[] params) =>
			params.length == 1
				? eachTypeInDestructure!T(paramsType, only(params), cb)
				: eachTypeInDestructureParts!T(paramsType, params, cb),
		(in ParamsAst.Varargs) =>
			none!T);

private Opt!T eachTypeInDestructureParts(T)(in Type type, in DestructureAst[] parts, in TypeCbOpt!T cb) =>
	firstZip!(T, Type, DestructureAst)(type.as!(StructInst*).typeArgs, parts, (Type typeArg, DestructureAst param) =>
		eachTypeInDestructure!T(typeArg, param, cb));

private Opt!T eachTypeInDestructure(T)(in Type type, in DestructureAst ast, in TypeCbOpt!T cb) =>
	ast.matchIn!(Opt!T)(
		(in DestructureAst.Single x) =>
			has(x.type) ? cb(type, *force(x.type)) : none!T,
		(in DestructureAst.Void x) =>
			none!T,
		(in DestructureAst[] parts) =>
			eachTypeInDestructureParts!T(type, parts, cb));

void eachDescendentExprIncluding(
	ref CommonTypes commonTypes,
	ExprRef a,
	in void delegate(ExprRef) @safe @nogc pure nothrow cb,
) {
	cb(a);
	eachDescendentExprExcluding(commonTypes, a, cb);
}

void eachDescendentExprExcluding(
	ref CommonTypes commonTypes,
	ExprRef a,
	in void delegate(ExprRef) @safe @nogc pure nothrow cb,
) {
	eachDirectChildExpr(commonTypes, a, (ExprRef x) {
		eachDescendentExprIncluding(commonTypes, x, cb);
	});
}

private void eachDirectChildExpr(
	ref CommonTypes commonTypes,
	ExprRef a,
	in void delegate(ExprRef) @safe @nogc pure nothrow cb,
) {
	Opt!bool res = findDirectChildExpr!bool(commonTypes, a, (ExprRef x) {
		cb(x);
		return none!bool;
	});
	assert(!has(res));
}

Opt!T findDirectChildExpr(T)(
	ref CommonTypes commonTypes,
	in ExprRef a,
	in Opt!T delegate(ExprRef) @safe @nogc pure nothrow cb,
) {
	Type boolType = Type(commonTypes.bool_);
	Type stringType = Type(commonTypes.string_);
	Type voidType = Type(commonTypes.void_);
	ExprRef sameType(ref Expr x) =>
		ExprRef(&x, a.type);
	ExprRef toRef(ref ExprAndType x) =>
		ExprRef(&x.expr, x.type);
	return a.expr.kind.matchWithPointers!(Opt!T)(
		(AssertOrForbidExpr x) {
			assert(a.type == voidType);
			return optOr!T(cb(ExprRef(x.condition, boolType)), () =>
				has(x.thrown) ? cb(ExprRef(force(x.thrown), stringType)) : none!T);
		},
		(BogusExpr _) =>
			none!T,
		(CallExpr x) {
			assert(a.type == x.called.returnType);
			if (x.called.isVariadic) {
				Type argType = arrayElementType(commonTypes, only(x.called.paramTypes));
				return firstPointer!(T, Expr)(x.args, (Expr* e) => cb(ExprRef(e, argType)));
			} else
				return firstZipPointerFirst!(T, Expr, Type)(x.args, x.called.paramTypes, (Expr* e, Type t) =>
					cb(ExprRef(e, t)));
		},
		(ClosureGetExpr x) {
			assert(a.type == x.local.type);
			return none!T;
		},
		(ClosureSetExpr x) {
			assert(a.type == voidType);
			return cb(ExprRef(x.value, x.local.type));
		},
		(FunPointerExpr _) =>
			none!T,
		(IfExpr* x) =>
			optOr!T(cb(ExprRef(&x.cond, boolType)), () => cb(sameType(x.then)), () => cb(sameType(x.else_))),
		(IfOptionExpr* x) =>
			optOr!T(cb(toRef(x.option)), () => cb(sameType(x.then)), () => cb(sameType(x.else_))),
		(LambdaExpr* x) =>
			cb(ExprRef(&x.body_(), x.returnType)),
		(LetExpr* x) =>
			optOr!T(cb(ExprRef(&x.value, x.destructure.type)), () => cb(sameType(x.then))),
		(LiteralExpr* _) =>
			none!T,
		(LiteralStringLikeExpr _) =>
			none!T,
		(LocalGetExpr x) {
			assert(a.type == x.local.type);
			return none!T;
		},
		(LocalSetExpr x) {
			assert(a.type == voidType);
			return cb(ExprRef(x.value, x.local.type));
		},
		(LoopExpr* x) =>
			cb(sameType(x.body_)),
		(LoopBreakExpr* x) =>
			cb(sameType(x.value)),
		(LoopContinueExpr _) =>
			none!T,
		(LoopUntilExpr* x) =>
			optOr!T(cb(ExprRef(&x.condition, boolType)), () => cb(ExprRef(&x.body_, voidType))),
		(LoopWhileExpr* x) =>
			optOr!T(cb(ExprRef(&x.condition, boolType)), () => cb(ExprRef(&x.body_, voidType))),
		(MatchEnumExpr* x) =>
			optOr!T(
				cb(toRef(x.matched)),
				() => firstPointer!(T, Expr)(x.cases, (Expr* y) => cb(sameType(*y)))),
		(MatchUnionExpr* x) =>
			optOr!T(
				cb(toRef(x.matched)),
				() => firstPointer!(T, MatchUnionExpr.Case)(x.cases, (MatchUnionExpr.Case* case_) =>
					cb(sameType(case_.then)))),
		(PtrToFieldExpr* x) =>
			cb(toRef(x.target)),
		(PtrToLocalExpr _) =>
			none!T,
		(SeqExpr* x) =>
			optOr!T(cb(ExprRef(&x.first, voidType)), () => cb(sameType(x.then))),
		(ThrowExpr* x) =>
			cb(ExprRef(&x.thrown, stringType)),
		(TrustedExpr* x) =>
			cb(sameType(x.inner)),
		(TypedExpr* x) =>
			cb(sameType(x.inner)));
}
