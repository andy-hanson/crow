module frontend.ide.ideUtil;

@safe @nogc pure nothrow:

import model.ast : DestructureAst, ModifierAst, NameAndRange, ParamsAst, SpecUseAst, TypeAst;
import model.model :
	AssertOrForbidExpr,
	BogusExpr,
	CallExpr,
	ClosureGetExpr,
	ClosureSetExpr,
	Expr,
	ExprKind,
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
	ThrowExpr,
	TrustedExpr,
	Type,
	TypedExpr,
	TypeParamIndex;
import util.col.array : arrayOfSingle, count, first, firstZip, isEmpty, only, only2;
import util.opt : force, has, none, Opt, optOr;
import util.sourceRange : UriAndRange;
import util.util : ptrTrustMe;

alias ReferenceCb = void delegate(in UriAndRange) @safe @nogc pure nothrow;

private alias SpecCb = void delegate(SpecInst*, in SpecUseAst) @safe @nogc pure nothrow;

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

private alias TypeCb(T) = Opt!T delegate(in Type, in TypeAst) @safe @nogc pure nothrow;

Opt!T eachTypeComponent(T)(in Type type, in TypeAst ast, in TypeCb!T cb) =>
	type.matchIn!(Opt!T)(
		(in Type.Bogus) =>
			none!T,
		(in TypeParamIndex _) =>
			none!T,
		(in StructInst x) =>
			eachTypeArg!T(x.typeArgs, ast, cb));

Opt!T eachTypeArgForSpecUse(T)(in Type[] typeArgs, in SpecUseAst ast, in TypeCb!T cb) {
	if (has(ast.typeArg))
		return zipEachTypeArgMayUnpackTuple!T(typeArgs, force(ast.typeArg), cb);
	else {
		assert(isEmpty(typeArgs));
		return none!T;
	}
}

private Opt!T eachTypeArg(T)(in Type[] typeArgs, in TypeAst ast, in TypeCb!T cb) =>
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

private Opt!T zipEachTypeArgMayUnpackTuple(T)(in Type[] typeArgs, in TypeAst typeArgAst, in TypeCb!T cb) =>
	zipEachTypeArg!T(
		typeArgs,
		typeArgs.length == 1 ? arrayOfSingle(ptrTrustMe(typeArgAst)) : typeArgAst.as!(TypeAst.Tuple).members,
		cb);

private Opt!T zipEachTypeArg(T)(in Type[] typeArgs, in TypeAst[] typeArgAsts, in TypeCb!T cb) =>
	firstZip!(T, Type, TypeAst)(typeArgs, typeArgAsts, (Type x, TypeAst y) => cb(x, y));

private Opt!T eachFunTypeParameter(T)(in Type paramsType, in ParamsAst paramsAst, in TypeCb!T cb) =>
	paramsAst.matchIn!(Opt!T)(
		(in DestructureAst[] params) =>
			params.length == 1
				? eachTypeInDestructure!T(paramsType, only(params), cb)
				: eachTypeInDestructureParts!T(paramsType, params, cb),
		(in ParamsAst.Varargs) =>
			none!T);

private Opt!T eachTypeInDestructureParts(T)(in Type type, in DestructureAst[] parts, in TypeCb!T cb) =>
	firstZip!(T, Type, DestructureAst)(type.as!(StructInst*).typeArgs, parts, (Type typeArg, DestructureAst param) =>
		eachTypeInDestructure!T(typeArg, param, cb));

private Opt!T eachTypeInDestructure(T)(in Type type, in DestructureAst ast, in TypeCb!T cb) =>
	ast.matchIn!(Opt!T)(
		(in DestructureAst.Single x) =>
			has(x.type) ? cb(type, *force(x.type)) : none!T,
		(in DestructureAst.Void x) =>
			none!T,
		(in DestructureAst[] parts) =>
			eachTypeInDestructureParts!T(type, parts, cb));

void eachDescendentExprIncluding(in Expr a, in void delegate(in Expr) @safe @nogc pure nothrow cb) {
	cb(a);
	eachDescendentExprExcluding(a.kind, cb);
}

void eachDescendentExprExcluding(in ExprKind a, in void delegate(in Expr) @safe @nogc pure nothrow cb) {
	eachDirectChildExpr(a, (in Expr x) {
		eachDescendentExprIncluding(x, cb);
	});
}

private void eachDirectChildExpr(in ExprKind a, in void delegate(in Expr) @safe @nogc pure nothrow cb) {
	Opt!bool res = findDirectChildExpr!bool(a, (in Expr x) {
		cb(x);
		return none!bool;
	});
	assert(!has(res));
}

private Opt!T findDirectChildExpr(T)(in ExprKind a, in Opt!T delegate(in Expr) @safe @nogc pure nothrow cb) =>
	a.matchIn!(Opt!T)(
		(in AssertOrForbidExpr x) =>
			optOr!T(cb(*x.condition), () =>
				has(x.thrown) ? cb(*force(x.thrown)) : none!T),
		(in BogusExpr _) =>
			none!T,
		(in CallExpr x) =>
			first!(T, Expr)(x.args, (Expr y) => cb(y)),
		(in ClosureGetExpr _) =>
			none!T,
		(in ClosureSetExpr x) =>
			cb(*x.value),
		(in FunPointerExpr _) =>
			none!T,
		(in IfExpr x) =>
			optOr!T(cb(x.cond), () => cb(x.then), () => cb(x.else_)),
		(in IfOptionExpr x) =>
			optOr!T(cb(x.option.expr), () => cb(x.then), () => cb(x.else_)),
		(in LambdaExpr x) =>
			cb(x.body_),
		(in LetExpr x) =>
			optOr!T(cb(x.value), () => cb(x.then)),
		(in LiteralExpr _) =>
			none!T,
		(in LiteralStringLikeExpr _) =>
			none!T,
		(in LocalGetExpr _) =>
			none!T,
		(in LocalSetExpr x) =>
			cb(x.value),
		(in LoopExpr x) =>
			cb(x.body_),
		(in LoopBreakExpr x) =>
			cb(x.value),
		(in LoopContinueExpr _) =>
			none!T,
		(in LoopUntilExpr x) =>
			optOr!T(cb(x.condition), () => cb(x.body_)),
		(in LoopWhileExpr x) =>
			optOr!T(cb(x.condition), () => cb(x.body_)),
		(in MatchEnumExpr x) =>
			optOr!T(cb(x.matched.expr), () => first!(T, Expr)(x.cases, (Expr y) => cb(y))),
		(in MatchUnionExpr x) =>
			optOr!T(
				cb(x.matched.expr),
				() => first!(T, MatchUnionExpr.Case)(x.cases, (MatchUnionExpr.Case case_) =>
					cb(case_.then))),
		(in PtrToFieldExpr x) =>
			cb(x.target.expr),
		(in PtrToLocalExpr _) =>
			none!T,
		(in SeqExpr x) =>
			optOr!T(cb(x.first), () => cb(x.then)),
		(in ThrowExpr x) =>
			cb(x.thrown),
		(in TrustedExpr x) =>
			cb(x.inner),
		(in TypedExpr x) =>
			cb(x.inner));
