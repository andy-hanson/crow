module frontend.check.typeFromAst;

@safe @nogc pure nothrow:

import frontend.check.checkCtx : addDiag, CheckCtx, eachImportAndReExport, markUsed, rangeInFile;
import frontend.check.instantiate :
	InstantiateCtx,
	instantiateSpec,
	instantiateStruct,
	instantiateStructNeverDelay,
	MayDelaySpecInsts,
	MayDelayStructInsts,
	noDelayStructInsts;
import frontend.check.maps : SpecsMap, StructsAndAliasesMap;
import frontend.parse.ast :
	DestructureAst,
	NameAndRange,
	range,
	rangeOfNameAndRange,
	suffixRange,
	symForTypeAstMap,
	symForTypeAstSuffix,
	TypeAst;
import model.diag : Diag, TypeContainer, TypeWithContainer;
import model.model :
	asTuple,
	CommonTypes,
	Destructure,
	emptyTypeParams,
	Local,
	LocalMutability,
	LocalSource,
	NameReferents,
	SpecDecl,
	SpecInst,
	StructAlias,
	StructDecl,
	StructInst,
	StructOrAlias,
	target,
	Type,
	TypeParamIndex,
	TypeParams,
	typeParams;
import util.cell : Cell, cellGet, cellSet;
import util.col.arr : arrayOfSingle, empty, only, small, SmallArray;
import util.col.arrUtil : eachPair, findIndex, map, mapOrNone, mapWithIndex, mapZip;
import util.memory : allocate;
import util.opt : force, has, none, Opt, optOrDefault, some;
import util.ptr : castNonScope_ref, ptrTrustMe;
import util.sourceRange : Range;
import util.sym : Sym, sym;
import util.util : todo;

private Type instStructFromAst(
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	Sym name,
	in Range suffixRange,
	in Opt!(TypeAst*) typeArgsAst,
	in StructsAndAliasesMap structsAndAliasesMap,
	TypeParams typeParamsScope,
	MayDelayStructInsts delayStructInsts,
) {
	Opt!StructOrAlias opDecl = tryFindT!StructOrAlias(
		ctx, name, suffixRange, structsAndAliasesMap[name],
		Diag.DuplicateImports.Kind.type, Diag.NameNotFound.Kind.type,
		(in NameReferents x) => x.structOrAlias);
	if (!has(opDecl))
		return Type(Type.Bogus());
	else {
		StructOrAlias sOrA = force(opDecl);
		Opt!Type typeArg = optTypeFromOptAst(
			ctx, commonTypes, typeArgsAst, structsAndAliasesMap, typeParamsScope, delayStructInsts);
		Opt!(Type[]) typeArgs = getTypeArgsIfNumberMatches(
			ctx, commonTypes, suffixRange, name, typeParams(sOrA).length, &typeArg);
		return has(typeArgs)
			? sOrA.matchWithPointers!Type(
				(StructAlias* a) =>
					typeParams(sOrA).length != 0
						? todo!Type("alias with type params")
						: typeFromOptInst(target(*a)),
				(StructDecl* decl) =>
					Type(instantiateStruct(ctx.instantiateCtx, decl, force(typeArgs), delayStructInsts)))
			: Type(Type.Bogus());
	}
}

Type makeTupleType(ref InstantiateCtx ctx, ref CommonTypes commonTypes, in Type[] args) {
	if (args.length == 0)
		return Type(commonTypes.void_);
	else if (args.length == 1)
		return only(args);
	else {
		Opt!(StructDecl*) decl = commonTypes.tuple(args.length);
		return has(decl)
			? Type(instantiateStructNeverDelay(ctx, force(decl), args))
			: Type(Type.Bogus());
	}
}

private Opt!(Type[]) getTypeArgsIfNumberMatches(
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	in Range range,
	Sym name,
	size_t nExpectedTypeArgs,
	return in Opt!Type* type,
) {
	Type[] res = has(*type)
		? unpackTupleIfNeeded(commonTypes, nExpectedTypeArgs, &force(*type))
		: [];
	if (res.length == nExpectedTypeArgs)
		return some(res);
	else {
		addDiag(ctx, range, Diag(Diag.WrongNumberTypeArgs(name, nExpectedTypeArgs, res.length)));
		return none!(Type[]);
	}
}

// Tries to return array of length 'nExpectedTypeArgs', but may fail
Type[] unpackTupleIfNeeded(in CommonTypes commonTypes, size_t nExpectedTypeArgs, Type* type) =>
	nExpectedTypeArgs == 1
		? arrayOfSingle(type)
		: optOrDefault!(Type[])(asTuple(commonTypes, *type), () => arrayOfSingle(type));

size_t getNTypeArgsForDiagnostic(in CommonTypes commonTypes, in Opt!Type explicitTypeArg) {
	if (has(explicitTypeArg)) {
		Opt!(Type[]) unpacked = asTuple(commonTypes, force(explicitTypeArg));
		return has(unpacked) ? force(unpacked).length : 1;
	} else
		return 0;
}

void checkTypeParams(ref CheckCtx ctx, in NameAndRange[] asts) {
	eachPair!NameAndRange(asts, (in NameAndRange x, in NameAndRange y) {
		if (x.name == y.name)
			addDiag(ctx, rangeOfNameAndRange(y, ctx.allSymbols), Diag(
				Diag.DuplicateDeclaration(Diag.DuplicateDeclaration.Kind.typeParam, y.name)));
	});
}

Type typeFromAstNoTypeParamsNeverDelay(
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	in TypeAst ast,
	in StructsAndAliasesMap structsAndAliasesMap,
) =>
	typeFromAst(ctx, commonTypes, ast, structsAndAliasesMap, emptyTypeParams, noDelayStructInsts);

Type typeFromAst(
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	in TypeAst ast,
	in StructsAndAliasesMap structsAndAliasesMap,
	TypeParams typeParamsScope,
	MayDelayStructInsts delayStructInsts,
) =>
	ast.matchIn!Type(
		(in TypeAst.Bogus) =>
			Type(Type.Bogus()),
		(in TypeAst.Fun x) =>
			typeFromFunAst(ctx, commonTypes, x, structsAndAliasesMap, typeParamsScope, delayStructInsts),
		(in TypeAst.Map x) =>
			typeFromMapAst(ctx, commonTypes, x, structsAndAliasesMap, typeParamsScope, delayStructInsts),
		(in NameAndRange name) {
			Opt!TypeParamIndex typeParam = findTypeParam(typeParamsScope, name.name);
			return has(typeParam)
				? Type(force(typeParam))
				: instStructFromAst(
					ctx,
					commonTypes,
					name.name,
					rangeOfNameAndRange(name, ctx.allSymbols),
					none!(TypeAst*),
					structsAndAliasesMap,
					typeParamsScope,
					delayStructInsts);
		},
		(in TypeAst.SuffixName x) {
			Opt!(Diag.TypeShouldUseSyntax.Kind) optSyntax = typeSyntaxKind(x.name.name);
			if (has(optSyntax))
				addDiag(ctx, suffixRange(x, ctx.allSymbols), Diag(Diag.TypeShouldUseSyntax(force(optSyntax))));
			Opt!TypeParamIndex typeParam = findTypeParam(typeParamsScope, x.name.name);
			if (has(typeParam)) {
				addDiag(ctx, suffixRange(x, ctx.allSymbols), Diag(Diag.TypeParamCantHaveTypeArgs()));
				return Type(force(typeParam));
			} else
				return instStructFromAst(
					ctx,
					commonTypes,
					x.name.name,
					suffixRange(x, ctx.allSymbols),
					some(&castNonScope_ref(x).left),
					structsAndAliasesMap,
					typeParamsScope,
					delayStructInsts);
		},
		(in TypeAst.SuffixSpecial it) =>
			instStructFromAst(
				ctx,
				commonTypes,
				symForTypeAstSuffix(it.kind),
				suffixRange(it),
				some(&castNonScope_ref(it).left),
				structsAndAliasesMap,
				typeParamsScope,
				delayStructInsts),
		(in TypeAst.Tuple x) =>
			typeFromTupleAst(ctx, commonTypes, x.members, structsAndAliasesMap, typeParamsScope, delayStructInsts));

private Opt!Type optTypeFromOptAst(
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	in Opt!(TypeAst*) ast,
	in StructsAndAliasesMap structsAndAliasesMap,
	TypeParams typeParamsScope,
	MayDelayStructInsts delayStructInsts,
) =>
	has(ast)
		? some(typeFromAst(ctx, commonTypes, *force(ast), structsAndAliasesMap, typeParamsScope, delayStructInsts))
		: none!Type;

Opt!(SpecInst*) specFromAst(
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	in StructsAndAliasesMap structsAndAliasesMap,
	in SpecsMap specsMap,
	TypeParams typeParamsScope,
	in Opt!(TypeAst*) suffixLeft,
	NameAndRange specName,
	MayDelaySpecInsts delaySpecInsts,
) {
	Opt!(SpecDecl*) opSpec = tryFindSpec(ctx, specName, specsMap);
	if (has(opSpec)) {
		SpecDecl* spec = force(opSpec);
		Opt!Type typeArg = optTypeFromOptAst(
			ctx, commonTypes, suffixLeft, structsAndAliasesMap, typeParamsScope, noDelayStructInsts);
		Opt!(Type[]) typeArgs = getTypeArgsIfNumberMatches(
			ctx, commonTypes,
			rangeOfNameAndRange(specName, ctx.allSymbols), spec.name, spec.typeParams.length, &typeArg);
		return has(typeArgs)
			? some(instantiateSpec(ctx.instantiateCtx, spec, force(typeArgs), delaySpecInsts))
			: none!(SpecInst*);
	} else
		return none!(SpecInst*);
}

private Type typeFromTupleAst(
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	in TypeAst[] members,
	in StructsAndAliasesMap structsAndAliasesMap,
	TypeParams typeParamsScope,
	MayDelayStructInsts delayStructInsts,
) {
	//TODO:PERF Use temp aloc
	Type[] args = map(ctx.alloc, members, (ref TypeAst x) =>
		typeFromAst(ctx, commonTypes, x, structsAndAliasesMap, typeParamsScope, delayStructInsts));
	return makeTupleType(ctx.instantiateCtx, commonTypes, args);
}

private Opt!TypeParamIndex findTypeParam(TypeParams typeParamsScope, Sym name) {
	Opt!size_t res = findIndex!NameAndRange(typeParamsScope, (in NameAndRange x) =>
		x.name == name);
	return has(res) ? some(TypeParamIndex(force(res))) : none!TypeParamIndex;
}

Opt!(Diag.TypeShouldUseSyntax.Kind) typeSyntaxKind(Sym a) {
	switch (a.value) {
		case sym!"fun-act".value:
			return some(Diag.TypeShouldUseSyntax.Kind.funAct);
		case sym!"fun-far".value:
			return some(Diag.TypeShouldUseSyntax.Kind.funFar);
		case sym!"fun-fun".value:
			return some(Diag.TypeShouldUseSyntax.Kind.funFun);
		case sym!"const-pointer".value:
			return some(Diag.TypeShouldUseSyntax.Kind.pointer);
		case sym!"map".value:
			return some(Diag.TypeShouldUseSyntax.Kind.map);
		case sym!"future".value:
			return some(Diag.TypeShouldUseSyntax.Kind.future);
		case sym!"list".value:
			return some(Diag.TypeShouldUseSyntax.Kind.list);
		case sym!"mut-map".value:
			return some(Diag.TypeShouldUseSyntax.Kind.mutMap);
		case sym!"mut-list".value:
			return some(Diag.TypeShouldUseSyntax.Kind.mutList);
		case sym!"mut-pointer".value:
			return some(Diag.TypeShouldUseSyntax.Kind.mutPointer);
		case sym!"option".value:
			return some(Diag.TypeShouldUseSyntax.Kind.opt);
		case sym!"tuple2".value:
		case sym!"tuple3".value:
		case sym!"tuple4".value:
		case sym!"tuple5".value:
		case sym!"tuple6".value:
		case sym!"tuple7".value:
		case sym!"tuple8".value:
		case sym!"tuple9".value:
			return some(Diag.TypeShouldUseSyntax.Kind.tuple);
		default:
			return none!(Diag.TypeShouldUseSyntax.Kind);
	}
}

private Type typeFromOptInst(Opt!(StructInst*) a) =>
	has(a) ? Type(force(a)) : Type(Type.Bogus());

private Type typeFromFunAst(
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	in TypeAst.Fun ast,
	in StructsAndAliasesMap structsAndAliasesMap,
	TypeParams typeParamsScope,
	MayDelayStructInsts delayStructInsts,
) {
	Type returnType = typeFromAst(
		ctx, commonTypes, ast.returnType, structsAndAliasesMap, typeParamsScope, delayStructInsts);
	Type paramType = typeFromTupleAst(
		ctx, commonTypes, ast.paramTypes, structsAndAliasesMap, typeParamsScope, delayStructInsts);
	return Type(instantiateStruct(
		ctx.instantiateCtx, commonTypes.funStructs[ast.kind], [returnType, paramType], delayStructInsts));
}

private Type typeFromMapAst(
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	in TypeAst.Map ast,
	in StructsAndAliasesMap structsAndAliasesMap,
	TypeParams typeParamsScope,
	MayDelayStructInsts delayStructInsts,
) {
	TypeAst.Tuple tuple = TypeAst.Tuple(Range.empty, castNonScope_ref(ast.kv));
	TypeAst typeArg = TypeAst(ptrTrustMe(tuple));
	return instStructFromAst(
		ctx,
		commonTypes,
		symForTypeAstMap(ast.kind),
		range(ast, ctx.allSymbols),
		some(ptrTrustMe(typeArg)),
		structsAndAliasesMap,
		typeParamsScope,
		delayStructInsts);
}

private Opt!(SpecDecl*) tryFindSpec(ref CheckCtx ctx, NameAndRange name, in SpecsMap specsMap) =>
	tryFindT!(SpecDecl*)(
		ctx,
		name.name,
		rangeOfNameAndRange(name, ctx.allSymbols),
		specsMap[name.name],
		Diag.DuplicateImports.Kind.spec,
		Diag.NameNotFound.Kind.spec,
		(in NameReferents x) => x.spec);

Type makeFutType(ref InstantiateCtx ctx, ref CommonTypes commonTypes, Type type) =>
	Type(instantiateStructNeverDelay(ctx, commonTypes.future, [type]));

Opt!Type typeFromDestructure(
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	in DestructureAst ast,
	in StructsAndAliasesMap structsAndAliasesMap,
	TypeParams typeParamsScope,
) =>
	ast.matchIn!(Opt!Type)(
		(in DestructureAst.Single x) =>
			has(x.type)
				? some(typeFromAst(
					ctx, commonTypes, *force(x.type), structsAndAliasesMap, typeParamsScope, noDelayStructInsts))
				: none!Type,
		(in DestructureAst.Void) =>
			some(Type(commonTypes.void_)),
		(in DestructureAst[] parts) {
			// TODO:PERF use temp alloc
			Opt!(Type[]) types = mapOrNone!(Type, DestructureAst)(ctx.alloc, parts, (ref DestructureAst part) =>
				typeFromDestructure(ctx, commonTypes, part, structsAndAliasesMap, typeParamsScope));
			return has(types) ? some(makeTupleType(ctx.instantiateCtx, commonTypes, force(types))) : none!Type;
		});

Destructure checkDestructure(
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	in StructsAndAliasesMap structsAndAliasesMap,
	TypeContainer typeContainer,
	// 'typeContainer' may be uninitialized, so pass 'typeParamsScope' separately
	TypeParams typeParamsScope,
	MayDelayStructInsts delayStructInsts,
	ref DestructureAst ast,
	// This is for the type coming from the RHS of a 'let', or the expected type of a lambda
	Opt!Type destructuredType,
) {
	TypeWithContainer typeWithContainer(Type x) =>
		TypeWithContainer(x, typeContainer);
	Type getType(Opt!Type declaredType) {
		if (has(declaredType)) {
			if (has(destructuredType) && force(destructuredType) != force(declaredType))
				addDiag(ctx, ast.range(ctx.allSymbols), Diag(
					Diag.DestructureTypeMismatch(
						Diag.DestructureTypeMismatch.Expected(typeWithContainer(force(declaredType))),
						typeWithContainer(force(destructuredType)))));
			return force(declaredType);
		} else if (has(destructuredType))
			return force(destructuredType);
		else {
			addDiag(ctx, ast.range(ctx.allSymbols), Diag(Diag.ParamMissingType()));
			return Type(Type.Bogus());
		}
	}
	return ast.match!Destructure(
		(DestructureAst.Single x) {
			Opt!Type declaredType = has(x.type)
				? some(typeFromAst(
					ctx, commonTypes, *force(x.type), structsAndAliasesMap, typeParamsScope, delayStructInsts))
				: none!Type;
			Type type = getType(declaredType);
			if (x.name.name == sym!"_") {
				if (has(x.mut))
					addDiag(ctx, ast.range(ctx.allSymbols), Diag(Diag.LocalIgnoredButMutable()));
				return Destructure(allocate(ctx.alloc, Destructure.Ignore(x.name.start, type)));
			} else
				return Destructure(allocate(ctx.alloc, Local(
					LocalSource(LocalSource.Ast(ctx.curUri, &ast.as!(DestructureAst.Single)())),
					x.name.name,
					has(x.mut) ? LocalMutability.mutOnStack : LocalMutability.immut,
					type)));
		},
		(DestructureAst.Void x) {
			Type type = getType(some(Type(commonTypes.void_)));
			return Destructure(allocate(ctx.alloc, Destructure.Ignore(x.pos, type)));
		},
		(DestructureAst[] partAsts) {
			if (has(destructuredType)) {
				Type tupleType = force(destructuredType);
				Opt!(Type[]) fieldTypes = asTuple(commonTypes, tupleType);
				if (has(fieldTypes) && force(fieldTypes).length == partAsts.length)
					return Destructure(allocate(ctx.alloc, Destructure.Split(
						tupleType,
						small(mapZip!(Destructure, Type, DestructureAst)(
							ctx.alloc, force(fieldTypes), partAsts, (ref Type fieldType, ref DestructureAst part) =>
								checkDestructure(
									ctx, commonTypes, structsAndAliasesMap, typeContainer, typeParamsScope, delayStructInsts,
									part, some(fieldType)))))));
				else {
					addDiag(ctx, ast.range(ctx.allSymbols), Diag(
						Diag.DestructureTypeMismatch(
							Diag.DestructureTypeMismatch.Expected(
								Diag.DestructureTypeMismatch.Expected.Tuple(partAsts.length)),
							typeWithContainer(tupleType))));
					return Destructure(allocate(ctx.alloc, Destructure.Split(
						Type(Type.Bogus()),
						small(map!(Destructure, DestructureAst)(
							ctx.alloc, partAsts, (ref DestructureAst part) =>
								checkDestructure(
									ctx, commonTypes, structsAndAliasesMap, typeContainer, typeParamsScope, delayStructInsts,
									part, some(Type(Type.Bogus()))))))));
				}
			} else {
				Destructure[] parts = map(ctx. alloc, partAsts, (ref DestructureAst part) =>
					checkDestructure(
						ctx, commonTypes, structsAndAliasesMap, typeContainer, typeParamsScope, delayStructInsts,
						part, none!Type));
				Type type = makeTupleType(
					ctx.instantiateCtx, commonTypes,
					//TODO:PERF Use temp alloc
					map(ctx.alloc, parts, (ref Destructure part) => part.type));
				return Destructure(allocate(ctx.alloc, Destructure.Split(type, small(parts))));
			}
		});
}

private:

Opt!T tryFindT(T)(
	ref CheckCtx ctx,
	Sym name,
	in Range range,
	Opt!T fromThisModule,
	Diag.DuplicateImports.Kind duplicateImportKind,
	Diag.NameNotFound.Kind nameNotFoundKind,
	in Opt!T delegate(in NameReferents) @safe @nogc pure nothrow getFromNameReferents,
) {
	Cell!(Opt!T) res = Cell!(Opt!T)(fromThisModule);
	eachImportAndReExport(ctx.importsAndReExports, name, (in NameReferents referents) {
		Opt!T got = getFromNameReferents(referents);
		if (has(got)) {
			if (has(cellGet(res)))
				// TODO: include both modules in the diag
				addDiag(ctx, range, Diag(Diag.DuplicateImports(duplicateImportKind, name)));
			else
				cellSet(res, got);
		}
	});
	Opt!T ret = cellGet(res);
	if (has(ret))
		markUsed(ctx, force(ret));
	else
		addDiag(ctx, range, Diag(Diag.NameNotFound(nameNotFoundKind, name)));
	return ret;
}
