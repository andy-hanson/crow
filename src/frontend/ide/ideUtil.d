module frontend.ide.ideUtil;

@safe @nogc pure nothrow:

import frontend.parse.ast : FunModifierAst, NameAndRange, TypeAst;
import model.model :
	Destructure,
	Expr,
	ExprKind,
	FunDecl,
	FunDeclSource,
	Local,
	SpecDecl,
	SpecInst,
	StructInst,
	Type,
	typeArgs,
	TypeParam;
import util.col.arr : arrayOfSingle, empty, only;
import util.col.arrBuilder : ArrBuilderCb;
import util.col.arrUtil : count, first, firstZip;
import util.opt : force, has, none, Opt, optOr, some;
import util.sourceRange : UriAndRange;
import util.util : typeAs, verify;

alias ReferenceCb = ArrBuilderCb!UriAndRange;

void eachSpecParent(in SpecDecl a, in void delegate(SpecInst*, in TypeAst) @safe @nogc pure nothrow cb) {
	Opt!bool res = eachSpecParent!bool(a, (SpecInst* x, in TypeAst ast) {
		cb(x, ast);
		return none!bool;
	});
	verify(!has(res));
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
			verify(bi == b.length);
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
		(in TypeParam) =>
			none!T,
		(in StructInst x) =>
			eachTypeArg!T(typeArgs(x), ast, cb));

private TypeAst[] typeAstTypeArgs(return scope TypeAst ast) =>
	ast.match!(TypeAst[])(
		(TypeAst.Bogus) =>
			typeAs!(TypeAst[])([]),
		(ref TypeAst.Fun x) =>
			x.returnAndParamTypes,
		(ref TypeAst.Map x) =>
			x.kv,
		(NameAndRange _) =>
			typeAs!(TypeAst[])([]),
		(ref TypeAst.SuffixName x) =>
			arrayOfSingle(&x.left),
		(ref TypeAst.SuffixSpecial x) =>
			arrayOfSingle(&x.left),
		(ref TypeAst.Tuple x) =>
			x.members);

void eachTypeArg(
	in Type[] typeArgs,
	in TypeAst ast,
	in void delegate(in Type, in TypeAst) @safe @nogc pure nothrow cb,
) {
	Opt!bool res = eachTypeArg!bool(typeArgs, ast, (in Type x, in TypeAst y) {
		cb(x, y);
		return none!bool;
	});
	verify(!has(res));
}

Opt!T eachTypeArg(T)(
	in Type[] typeArgs,
	in TypeAst ast,
	in Opt!T delegate(in Type, in TypeAst) @safe @nogc pure nothrow cb,
) {
	TypeAst[] typeArgAsts = typeAstTypeArgs(ast);
	TypeAst[] actualArgAsts = typeArgAsts.length == typeArgs.length
		? typeArgAsts
		: only(typeArgAsts).as!(TypeAst.Tuple*).members;
	return firstZip!(T, Type, TypeAst)(typeArgs, actualArgAsts, (Type x, TypeAst y) => cb(x, y));
}

Opt!T eachDestructureComponent(T)(Destructure a, in Opt!T delegate(Local*) @safe @nogc pure nothrow cb) =>
	a.matchWithPointers!(Opt!T)(
		(Destructure.Ignore*) =>
			none!T,
		(Local* x) =>
			cb(x),
		(Destructure.Split* x) =>
			empty(x.parts)
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
	verify(!has(res));
}

private Opt!T findDirectChildExpr(T)(in ExprKind a, in Opt!T delegate(in Expr) @safe @nogc pure nothrow cb) =>
	a.matchIn!(Opt!T)(
		(in ExprKind.AssertOrForbid x) =>
			optOr!T(cb(*x.condition), () =>
				has(x.thrown) ? cb(*force(x.thrown)) : none!T),
		(in ExprKind.Bogus) =>
			none!T,
		(in ExprKind.Call x) =>
			first!(T, Expr)(x.args, (Expr y) => cb(y)),
		(in ExprKind.ClosureGet) =>
			none!T,
		(in ExprKind.ClosureSet x) =>
			cb(*x.value),
		(in ExprKind.FunPtr) =>
			none!T,
		(in ExprKind.If x) =>
			optOr!T(cb(x.cond), () => cb(x.then), () => cb(x.else_)),
		(in ExprKind.IfOption x) =>
			optOr!T(cb(x.option.expr), () => cb(x.then), () => cb(x.else_)),
		(in ExprKind.Lambda x) =>
			cb(x.body_),
		(in ExprKind.Let x) =>
			optOr!T(cb(x.value), () => cb(x.then)),
		(in ExprKind.Literal) =>
			none!T,
		(in ExprKind.LiteralCString) =>
			none!T,
		(in ExprKind.LiteralSymbol) =>
			none!T,
		(in ExprKind.LocalGet) =>
			none!T,
		(in ExprKind.LocalSet x) =>
			cb(x.value),
		(in ExprKind.Loop x) =>
			cb(x.body_),
		(in ExprKind.LoopBreak x) =>
			cb(x.value),
		(in ExprKind.LoopContinue) =>
			none!T,
		(in ExprKind.LoopUntil x) =>
			optOr!T(cb(x.condition), () => cb(x.body_)),
		(in ExprKind.LoopWhile x) =>
			optOr!T(cb(x.condition), () => cb(x.body_)),
		(in ExprKind.MatchEnum x) =>
			optOr!T(cb(x.matched.expr), () => first!(T, Expr)(x.cases, (Expr y) => cb(y))),
		(in ExprKind.MatchUnion x) =>
			optOr!T(
				cb(x.matched.expr),
				() => first!(T, ExprKind.MatchUnion.Case)(x.cases, (ExprKind.MatchUnion.Case case_) =>
					cb(case_.then))),
		(in ExprKind.PtrToField x) =>
			cb(x.target.expr),
		(in ExprKind.PtrToLocal) =>
			none!T,
		(in ExprKind.Seq x) =>
			optOr!T(cb(x.first), () => cb(x.then)),
		(in ExprKind.Throw x) =>
			cb(x.thrown));
