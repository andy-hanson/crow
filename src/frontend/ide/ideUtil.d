module frontend.ide.ideUtil;

@safe @nogc pure nothrow:

import model.ast : FunModifierAst, NameAndRange, TypeAst;
import model.model :
	AssertOrForbidExpr,
	BogusExpr,
	CallExpr,
	ClosureGetExpr,
	ClosureSetExpr,
	Destructure,
	Expr,
	ExprKind,
	FunDecl,
	FunDeclSource,
	FunPointerExpr,
	IfExpr,
	IfOptionExpr,
	LambdaExpr,
	LetExpr,
	LiteralCStringExpr,
	LiteralExpr,
	LiteralSymbolExpr,
	Local,
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
	TypeParamIndex;
import util.col.array : arrayOfSingle, count, first, firstZip, isEmpty, only, only2;
import util.col.arrayBuilder : ArrBuilderCb;
import util.opt : force, has, none, Opt, optOr, some;
import util.sourceRange : UriAndRange;

alias ReferenceCb = ArrBuilderCb!UriAndRange;

void eachSpecParent(in SpecDecl a, in void delegate(SpecInst*, in TypeAst) @safe @nogc pure nothrow cb) {
	Opt!bool res = eachSpecParent!bool(a, (SpecInst* x, in TypeAst ast) {
		cb(x, ast);
		return none!bool;
	});
	assert(!has(res));
}

Opt!T eachSpecParent(T)(in SpecDecl a, in Opt!T delegate(SpecInst*, in TypeAst) @safe @nogc pure nothrow cb) =>
	firstZip!(T, immutable SpecInst*, TypeAst)(a.parents, a.ast.parents, (immutable SpecInst* parent, TypeAst ast) =>
		cb(parent, ast));

void eachFunSpec(in FunDecl a, in void delegate(in SpecInst*, in TypeAst) @safe @nogc pure nothrow cb) {
	if (a.source.isA!(FunDeclSource.Ast)) {
		FunModifierAst[] modifiers = a.source.as!(FunDeclSource.Ast).ast.modifiers;
		// Count may not match if there are compile errors.
		zipSecondMapOpIfSizeEq!(SpecInst*, FunModifierAst, TypeAst)(
			a.specs,
			modifiers,
			(in FunModifierAst x) => x.isA!(TypeAst) ? some(x.as!TypeAst) : none!TypeAst,
			cb);
	}
}

private void zipSecondMapOpIfSizeEq(T, UIn, UOut)(
	in T[] a,
	in UIn[] b,
	in Opt!UOut delegate(in UIn) @safe @nogc pure nothrow bMap,
	in void delegate(in T, in UOut) @safe @nogc pure nothrow cb,
) {
	size_t cnt = count!UIn(b, (in UIn x) => has(bMap(x)));
	if (cnt == a.length) {
		size_t bi = 0;
		foreach (ref const T x; a) {
			while (true) {
				Opt!UOut y = bMap(b[bi]);
				bi++;
				if (has(y)) {
					cb(x, force(y));
					break;
				}
			}
		}
		debug {
			while (bi < b.length && !has(bMap(b[bi]))) bi++;
			assert(bi == b.length);
		}
	}
}

Opt!T eachTypeComponent(T)(
	in Type type,
	in TypeAst ast,
	in Opt!T delegate(in Type, in TypeAst) @safe @nogc pure nothrow cb,
) =>
	type.matchIn!(Opt!T)(
		(in Type.Bogus) =>
			none!T,
		(in TypeParamIndex _) =>
			none!T,
		(in StructInst x) =>
			eachTypeArg!T(x.typeArgs, ast, cb));

void eachTypeArg(
	in Type[] typeArgs,
	in TypeAst ast,
	in void delegate(in Type, in TypeAst) @safe @nogc pure nothrow cb,
) {
	Opt!bool res = eachTypeArg!bool(typeArgs, ast, (in Type x, in TypeAst y) {
		cb(x, y);
		return none!bool;
	});
	assert(!has(res));
}

Opt!T eachTypeArg(T)(
	in Type[] typeArgs,
	in TypeAst ast,
	in Opt!T delegate(in Type, in TypeAst) @safe @nogc pure nothrow cb,
) {
	Opt!T zipIt(in TypeAst[] typeArgAsts) =>
		firstZip!(T, Type, TypeAst)(typeArgs, typeArgAsts, (Type x, TypeAst y) => cb(x, y));
	Opt!T zipSuffix(in TypeAst* typeArgAst) =>
		zipIt(typeArgs.length == 1
			? arrayOfSingle(typeArgAst)
			: typeArgAst.as!(TypeAst.Tuple*).members);

	return ast.match!(Opt!T)(
		(TypeAst.Bogus) =>
			none!T,
		(ref TypeAst.Fun x) {
			Type[2] returnAndParam = only2(typeArgs);
			Opt!T fromReturn = cb(returnAndParam[0], x.returnType);
			switch (x.paramTypes.length) {
				case 0:
					return fromReturn;
				case 1:
					return optOr!T(fromReturn, () => cb(returnAndParam[1], only(x.paramTypes)));
				default:
					TypeAst.Tuple tuple = TypeAst.Tuple(x.range, x.paramTypes);
					return optOr!T(fromReturn, () => cb(returnAndParam[1], TypeAst(&tuple)));
			}
		},
		(ref TypeAst.Map x) =>
			zipIt(x.kv),
		(NameAndRange _) =>
			// For a type alias, 'typeArgs' may be non-empty as it comes from the alias' target type.
			// But ignore them in any case.
			none!T,
		(ref TypeAst.SuffixName x) @safe =>
			zipSuffix(&x.left),
		(ref TypeAst.SuffixSpecial x) =>
			zipSuffix(&x.left),
		(ref TypeAst.Tuple x) =>
			zipIt(x.members));
}

Opt!T eachDestructureComponent(T)(Destructure a, in Opt!T delegate(Local*) @safe @nogc pure nothrow cb) =>
	a.matchWithPointers!(Opt!T)(
		(Destructure.Ignore*) =>
			none!T,
		(Local* x) =>
			cb(x),
		(Destructure.Split* x) =>
			isEmpty(x.parts)
				? none!T
				: first!(T, Destructure)(x.parts, (Destructure part) =>
					eachDestructureComponent!T(part, cb)));

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
		(in LiteralCStringExpr _) =>
			none!T,
		(in LiteralSymbolExpr _) =>
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
			cb(x.inner));
