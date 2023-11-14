module frontend.ide.ideUtil;

@safe @nogc pure nothrow:

import frontend.parse.ast : NameAndRange, TypeAst;
import model.model : Destructure, Expr, ExprKind, Local, StructInst, Type, typeArgs;
import util.col.arr : only;
import util.col.arrUtil : first, firstZip;
import util.opt : force, has, none, Opt, optOr;
import util.util : verify;

Opt!T eachTypeComponent(T)(
	in Type type,
	in TypeAst ast,
	in Opt!T delegate(in Type, in TypeAst) @safe @nogc pure nothrow cb,
) {
	Opt!T fromArgs(in TypeAst[] typeArgAsts) {
		Type[] args = typeArgs(*type.as!(StructInst*));
		TypeAst[] actualArgAsts = typeArgAsts.length == args.length
			? typeArgAsts
			: only(typeArgAsts).as!(TypeAst.Tuple*).members;
		return firstZip!(T, Type, TypeAst)(args, actualArgAsts, (Type x, TypeAst y) => cb(x, y));
	}
	return ast.match!(Opt!T)(
		(TypeAst.Bogus) =>
			none!T,
		(ref TypeAst.Fun x) =>
			fromArgs(x.returnAndParamTypes),
		(ref TypeAst.Map x) =>
			fromArgs([x.v, x.k]),
		(NameAndRange x) =>
			none!T,
		(ref TypeAst.SuffixName x) =>
			fromArgs([x.left]),
		(ref TypeAst.SuffixSpecial x) =>
			fromArgs([x.left]),
		(ref TypeAst.Tuple x) =>
			fromArgs(x.members));
}

Opt!T eachDestructureComponent(T)(Destructure a, in Opt!T delegate(Local*) @safe @nogc pure nothrow cb) =>
	a.matchWithPointers!(Opt!T)(
		(Destructure.Ignore*) =>
			none!T,
		(Local* x) =>
			cb(x),
		(Destructure.Split* x) =>
			//TODO: handle x.destructuredType
			first!(T, Destructure)(x.parts, (Destructure part) =>
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
