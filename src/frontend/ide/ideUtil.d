module frontend.ide.ideUtil;

@safe @nogc pure nothrow:

import model.ast : DestructureAst, ModifierAst, NameAndRange, ParamsAst, SpecUseAst, TypeAst;
import model.model : FunDecl, FunDeclSource, SpecInst, SpecDecl, StructInst, Type, TypeParamIndex;
import util.col.array : arrayOfSingle, count, firstZip, isEmpty, only, only2;
import util.opt : force, has, none, Opt, optOr, some;
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

void eachPackedTypeArg(in Type[] typeArgs, in TypeAst ast, in TypeCb cb) {
	eachPackedTypeArg(typeArgs, some(ast), cb);
}
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

private:

Opt!T findInTypeArgs(T)(in Type[] typeArgs, in TypeAst ast, in TypeCbOpt!T cb) =>
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
		(ref TypeAst.SuffixSpecial x) =>
			zipEachTypeArgMayUnpackTuple!T(typeArgs, x.left, cb),
		(ref TypeAst.Tuple x) =>
			zipEachTypeArg!T(typeArgs, x.members, cb));

Opt!T zipEachTypeArgMayUnpackTuple(T)(in Type[] typeArgs, in TypeAst typeArgAst, in TypeCbOpt!T cb) =>
	zipEachTypeArg!T(
		typeArgs,
		typeArgs.length == 1 ? arrayOfSingle(ptrTrustMe(typeArgAst)) : typeArgAst.as!(TypeAst.Tuple*).members,
		cb);

Opt!T zipEachTypeArg(T)(in Type[] typeArgs, in TypeAst[] typeArgAsts, in TypeCbOpt!T cb) =>
	firstZip!(T, Type, TypeAst)(typeArgs, typeArgAsts, (Type x, TypeAst y) => cb(x, y));

Opt!T eachFunTypeParameter(T)(in Type paramsType, in ParamsAst paramsAst, in TypeCbOpt!T cb) =>
	paramsAst.matchIn!(Opt!T)(
		(in DestructureAst[] params) =>
			params.length == 1
				? eachTypeInDestructure!T(paramsType, only(params), cb)
				: eachTypeInDestructureParts!T(paramsType, params, cb),
		(in ParamsAst.Varargs) =>
			none!T);

Opt!T eachTypeInDestructureParts(T)(in Type type, in DestructureAst[] parts, in TypeCbOpt!T cb) =>
	firstZip!(T, Type, DestructureAst)(type.as!(StructInst*).typeArgs, parts, (Type typeArg, DestructureAst param) =>
		eachTypeInDestructure!T(typeArg, param, cb));

Opt!T eachTypeInDestructure(T)(in Type type, in DestructureAst ast, in TypeCbOpt!T cb) =>
	ast.matchIn!(Opt!T)(
		(in DestructureAst.Single x) =>
			has(x.type) ? cb(type, *force(x.type)) : none!T,
		(in DestructureAst.Void x) =>
			none!T,
		(in DestructureAst[] parts) =>
			eachTypeInDestructureParts!T(type, parts, cb));
