module frontend.check.typeFromAst;

@safe @nogc pure nothrow:

import frontend.check.checkCtx : addDiag, CheckCtx, eachImportAndReExport, markUsed, rangeInFile;
import frontend.check.dicts : SpecsDict, StructsAndAliasesDict;
import frontend.check.instantiate :
	DelaySpecInsts,
	DelayStructInsts,
	instantiateSpec,
	instantiateStruct,
	instantiateStructNeverDelay,
	noDelayStructInsts;
import frontend.parse.ast :
	DestructureAst,
	NameAndRange,
	range,
	rangeOfNameAndRange,
	suffixRange,
	symForTypeAstDict,
	symForTypeAstSuffix,
	TypeAst;
import frontend.programState : ProgramState;
import model.diag : Diag;
import model.model :
	asTuple,
	CommonTypes,
	decl,
	Destructure,
	Local,
	LocalMutability,
	NameReferents,
	SpecDecl,
	SpecInst,
	StructAlias,
	StructDecl,
	StructInst,
	StructOrAlias,
	target,
	Type,
	TypeParam,
	typeParams;
import util.alloc.alloc : Alloc;
import util.cell : Cell, cellGet, cellSet;
import util.col.arr : arrayOfSingle, empty, only, small;
import util.col.arrUtil : eachPair, findPtr, map, mapOrNone, mapWithIndex, mapZip;
import util.memory : allocate;
import util.opt : force, has, none, Opt, optOr, some;
import util.ptr : castNonScope_ref, ptrTrustMe;
import util.sourceRange : RangeWithinFile;
import util.sym : Sym, sym;
import util.util : todo;

private Type instStructFromAst(
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	Sym name,
	RangeWithinFile suffixRange,
	in Opt!(TypeAst*) typeArgsAst,
	in StructsAndAliasesDict structsAndAliasesDict,
	TypeParam[] typeParamsScope,
	DelayStructInsts delayStructInsts,
) {
	Opt!StructOrAlias opDecl = tryFindT!StructOrAlias(
		ctx, name, suffixRange, structsAndAliasesDict[name],
		Diag.DuplicateImports.Kind.type, Diag.NameNotFound.Kind.type,
		(in NameReferents x) => x.structOrAlias);
	if (!has(opDecl))
		return Type(Type.Bogus());
	else {
		StructOrAlias sOrA = force(opDecl);
		Opt!Type typeArg = optTypeFromOptAst(
			ctx, commonTypes, typeArgsAst, structsAndAliasesDict, typeParamsScope, delayStructInsts);
		Opt!(Type[]) typeArgs = getTypeArgsIfNumberMatches(
			ctx, commonTypes, suffixRange, name, typeParams(sOrA).length, &typeArg);
		return has(typeArgs)
			? sOrA.matchWithPointers!Type(
				(StructAlias* a) =>
					typeParams(sOrA).length != 0
						? todo!Type("alias with type params")
						: typeFromOptInst(target(*a)),
				(StructDecl* decl) =>
					Type(instantiateStruct(ctx.alloc, ctx.programState, decl, force(typeArgs), delayStructInsts)))
			: Type(Type.Bogus());
	}
}

Type makeTupleType(ref Alloc alloc, ref ProgramState programState, ref CommonTypes commonTypes, in Type[] args) {
	if (args.length == 0)
		return Type(commonTypes.void_);
	else if (args.length == 1)
		return only(args);
	else {
		Opt!(StructDecl*) decl = commonTypes.tuple(args.length);
		return has(decl)
			? Type(instantiateStructNeverDelay(alloc, programState, force(decl), args))
			: Type(Type.Bogus());
	}
}

private Opt!(Type[]) getTypeArgsIfNumberMatches(
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	RangeWithinFile range,
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
		: optOr!(Type[])(asTuple(commonTypes, *type), () => arrayOfSingle(type));

size_t getNTypeArgsForDiagnostic(in CommonTypes commonTypes, in Opt!Type explicitTypeArg) {
	if (has(explicitTypeArg)) {
		Opt!(Type[]) unpacked = asTuple(commonTypes, force(explicitTypeArg));
		return has(unpacked) ? force(unpacked).length : 1;
	} else
		return 0;
}

TypeParam[] checkTypeParams(ref CheckCtx ctx, in NameAndRange[] asts) {
	TypeParam[] res = mapWithIndex!(TypeParam, NameAndRange)(
		ctx.alloc,
		asts,
		(size_t index, scope ref NameAndRange ast) =>
			TypeParam(rangeInFile(ctx, rangeOfNameAndRange(ast, ctx.allSymbols)), ast.name, index));
	eachPair!TypeParam(res, (in TypeParam a, in TypeParam b) {
		if (a.name == b.name)
			addDiag(ctx, b.range, Diag(Diag.DuplicateDeclaration(Diag.DuplicateDeclaration.Kind.typeParam, b.name)));
	});
	return res;
}

Type typeFromAstNoTypeParamsNeverDelay(
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	in TypeAst ast,
	in StructsAndAliasesDict structsAndAliasesDict,
) =>
	typeFromAst(ctx, commonTypes, ast, structsAndAliasesDict, [], noDelayStructInsts);

Type typeFromAst(
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	in TypeAst ast,
	in StructsAndAliasesDict structsAndAliasesDict,
	TypeParam[] typeParamsScope,
	DelayStructInsts delayStructInsts,
) =>
	ast.matchIn!Type(
		(in TypeAst.Bogus) =>
			Type(Type.Bogus()),
		(in TypeAst.Dict it) {
			// TODO: don't create synthetic AST
			TypeAst[2] tupleMembers = [it.k, it.v];
			TypeAst.Tuple tuple = TypeAst.Tuple(RangeWithinFile.empty, castNonScope_ref(tupleMembers));
			TypeAst typeArg = TypeAst(ptrTrustMe(tuple));
			return instStructFromAst(
				ctx,
				commonTypes,
				symForTypeAstDict(it.kind),
				range(it, ctx.allSymbols),
				some(ptrTrustMe(typeArg)),
				structsAndAliasesDict,
				typeParamsScope,
				delayStructInsts);
		},
		(in TypeAst.Fun it) =>
			typeFromFunAst(ctx, commonTypes, it, structsAndAliasesDict, typeParamsScope, delayStructInsts),
		(in NameAndRange name) {
			Opt!(TypeParam*) typeParam = findTypeParam(typeParamsScope, name.name);
			return has(typeParam)
				? Type(force(typeParam))
				: instStructFromAst(
					ctx,
					commonTypes,
					name.name,
					rangeOfNameAndRange(name, ctx.allSymbols),
					none!(TypeAst*),
					structsAndAliasesDict,
					typeParamsScope,
					delayStructInsts);
		},
		(in TypeAst.SuffixName x) {
			Opt!(Diag.TypeShouldUseSyntax.Kind) optSyntax = typeSyntaxKind(x.name.name);
			if (has(optSyntax))
				addDiag(ctx, suffixRange(x, ctx.allSymbols), Diag(Diag.TypeShouldUseSyntax(force(optSyntax))));
			Opt!(TypeParam*) typeParam = findTypeParam(typeParamsScope, x.name.name);
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
					structsAndAliasesDict,
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
				structsAndAliasesDict,
				typeParamsScope,
				delayStructInsts),
		(in TypeAst.Tuple x) =>
			typeFromTupleAst(ctx, commonTypes, x.members, structsAndAliasesDict, typeParamsScope, delayStructInsts));

private Opt!Type optTypeFromOptAst(
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	in Opt!(TypeAst*) ast,
	in StructsAndAliasesDict structsAndAliasesDict,
	TypeParam[] typeParamsScope,
	DelayStructInsts delayStructInsts,
) =>
	has(ast)
		? some(typeFromAst(ctx, commonTypes, *force(ast), structsAndAliasesDict, typeParamsScope, delayStructInsts))
		: none!Type;

Opt!(SpecInst*) specFromAst(
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	in StructsAndAliasesDict structsAndAliasesDict,
	in SpecsDict specsDict,
	TypeParam[] typeParamsScope,
	in Opt!(TypeAst*) suffixLeft,
	NameAndRange specName,
	DelaySpecInsts delaySpecInsts,
) {
	Opt!(SpecDecl*) opSpec = tryFindSpec(ctx, specName, specsDict);
	if (has(opSpec)) {
		SpecDecl* spec = force(opSpec);
		Opt!Type typeArg = optTypeFromOptAst(
			ctx, commonTypes, suffixLeft, structsAndAliasesDict, typeParamsScope, noDelayStructInsts);
		Opt!(Type[]) typeArgs = getTypeArgsIfNumberMatches(
			ctx, commonTypes,
			rangeOfNameAndRange(specName, ctx.allSymbols), spec.name, spec.typeParams.length, &typeArg);
		return has(typeArgs)
			? some(instantiateSpec(ctx.alloc, ctx.programState, spec, force(typeArgs), delaySpecInsts))
			: none!(SpecInst*);
	} else
		return none!(SpecInst*);
}

private Type typeFromTupleAst(
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	in TypeAst[] members,
	in StructsAndAliasesDict structsAndAliasesDict,
	TypeParam[] typeParamsScope,
	DelayStructInsts delayStructInsts,
) {
	//TODO:PERF Use temp aloc
	Type[] args = map(ctx.alloc, members, (ref TypeAst x) =>
		typeFromAst(ctx, commonTypes, x, structsAndAliasesDict, typeParamsScope, delayStructInsts));
	return makeTupleType(ctx.alloc, ctx.programState, commonTypes, args);
}

private Opt!(TypeParam*) findTypeParam(TypeParam[] typeParamsScope, Sym name) =>
	findPtr!TypeParam(typeParamsScope, (in TypeParam x) =>
		x.name == name);

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
		case sym!"dict".value:
			return some(Diag.TypeShouldUseSyntax.Kind.dict);
		case sym!"future".value:
			return some(Diag.TypeShouldUseSyntax.Kind.future);
		case sym!"list".value:
			return some(Diag.TypeShouldUseSyntax.Kind.list);
		case sym!"mut-dict".value:
			return some(Diag.TypeShouldUseSyntax.Kind.mutDict);
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
	in StructsAndAliasesDict structsAndAliasesDict,
	TypeParam[] typeParamsScope,
	DelayStructInsts delayStructInsts,
) {
	TypeAst returnTypeAst = ast.returnAndParamTypes[0];
	TypeAst[] paramTypeAsts = ast.returnAndParamTypes[1 .. $];
	Type returnType = typeFromAst(
		ctx, commonTypes, returnTypeAst, structsAndAliasesDict, typeParamsScope, delayStructInsts);
	Type paramType = typeFromTupleAst(
		ctx, commonTypes, paramTypeAsts, structsAndAliasesDict, typeParamsScope, delayStructInsts);
	return Type(instantiateStruct(
		ctx.alloc, ctx.programState, commonTypes.funStructs[ast.kind], [returnType, paramType], delayStructInsts));
}

private Opt!(SpecDecl*) tryFindSpec(ref CheckCtx ctx, NameAndRange name, in SpecsDict specsDict) =>
	tryFindT!(SpecDecl*)(
		ctx,
		name.name,
		rangeOfNameAndRange(name, ctx.allSymbols),
		specsDict[name.name],
		Diag.DuplicateImports.Kind.spec,
		Diag.NameNotFound.Kind.spec,
		(in NameReferents x) => x.spec);

Type makeFutType(ref Alloc alloc, ref ProgramState programState, ref CommonTypes commonTypes, Type type) =>
	Type(instantiateStructNeverDelay(alloc, programState, commonTypes.future, [type]));

Opt!Type typeFromDestructure(
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	in DestructureAst ast,
	in StructsAndAliasesDict structsAndAliasesDict,
	TypeParam[] typeParamsScope,
) =>
	ast.matchIn!(Opt!Type)(
		(in DestructureAst.Single x) =>
			has(x.type)
				? some(typeFromAst(
					ctx,
					commonTypes,
					*force(x.type),
					structsAndAliasesDict,
					typeParamsScope,
					noDelayStructInsts))
				: none!Type,
		(in DestructureAst.Void) =>
			some(Type(commonTypes.void_)),
		(in DestructureAst[] parts) {
			// TODO:PERF use temp alloc
			Opt!(Type[]) types = mapOrNone!(Type, DestructureAst)(ctx.alloc, parts, (ref DestructureAst part) =>
				typeFromDestructure(ctx, commonTypes, part, structsAndAliasesDict, typeParamsScope));
			return has(types) ? some(makeTupleType(ctx.alloc, ctx.programState, commonTypes, force(types))) : none!Type;
		});

Destructure checkDestructure(
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	in StructsAndAliasesDict structsAndAliasesDict,
	TypeParam[] typeParamsScope,
	DelayStructInsts delayStructInsts,
	in DestructureAst ast,
	// This is for the type coming from the RHS of a 'let', or the expected type of a lambda
	Opt!Type destructuredType,
) {
	Type getType(Opt!Type declaredType) {
		if (has(declaredType)) {
			if (has(destructuredType) && force(destructuredType) != force(declaredType))
				addDiag(ctx, ast.range(ctx.allSymbols), Diag(
					Diag.DestructureTypeMismatch(
						Diag.DestructureTypeMismatch.Expected(force(declaredType)),
						force(destructuredType))));
			return force(declaredType);
		} else if (has(destructuredType))
			return force(destructuredType);
		else {
			addDiag(ctx, ast.range(ctx.allSymbols), Diag(Diag.ParamMissingType()));
			return Type(Type.Bogus());
		}
	}
	return ast.matchIn!Destructure(
		(in DestructureAst.Single x) {
			Opt!Type declaredType = has(x.type)
				? some(typeFromAst(
					ctx, commonTypes, *force(x.type), structsAndAliasesDict, typeParamsScope, delayStructInsts))
				: none!Type;
			Type type = getType(declaredType);
			if (x.name.name == sym!"_") {
				if (x.mut)
					addDiag(ctx, ast.range(ctx.allSymbols), Diag(Diag.LocalIgnoredButMutable()));
				return Destructure(allocate(ctx.alloc, Destructure.Ignore(x.name.start, type)));
			} else
				return Destructure(allocate(ctx.alloc, Local(
					rangeInFile(ctx, ast.range(ctx.allSymbols)),
					x.name.name,
					x.mut ? LocalMutability.mutOnStack : LocalMutability.immut,
					type)));
		},
		(in DestructureAst.Void x) {
			Type type = getType(some(Type(commonTypes.void_)));
			return Destructure(allocate(ctx.alloc, Destructure.Ignore(x.pos, type)));
		},
		(in DestructureAst[] partAsts) {
			if (has(destructuredType)) {
				Type tupleType = force(destructuredType);
				Opt!(Type[]) fieldTypes = asTuple(commonTypes, tupleType);
				if (has(fieldTypes) && force(fieldTypes).length == partAsts.length)
					return Destructure(allocate(ctx.alloc, Destructure.Split(
						tupleType.as!(StructInst*),
						small(mapZip!(Destructure, Type, DestructureAst)(
							ctx.alloc, force(fieldTypes), partAsts, (ref Type fieldType, ref DestructureAst part) =>
								checkDestructure(
									ctx, commonTypes, structsAndAliasesDict, typeParamsScope, delayStructInsts,
									part, some(fieldType)))))));
				else {
					addDiag(ctx, ast.range(ctx.allSymbols), Diag(
						Diag.DestructureTypeMismatch(
							Diag.DestructureTypeMismatch.Expected(
								Diag.DestructureTypeMismatch.Expected.Tuple(partAsts.length)),
							tupleType)));
					return Destructure(allocate(ctx.alloc, Destructure.Split(
						null,
						small(map!(Destructure, DestructureAst)(
							ctx.alloc, partAsts, (scope ref DestructureAst part) =>
								checkDestructure(
									ctx, commonTypes, structsAndAliasesDict, typeParamsScope, delayStructInsts,
									part, some(Type(Type.Bogus()))))))));
				}
			} else {
				Destructure[] parts = map(ctx. alloc, partAsts, (ref DestructureAst part) =>
					checkDestructure(
						ctx, commonTypes, structsAndAliasesDict, typeParamsScope, delayStructInsts,
						part, none!Type));
				Type type = makeTupleType(
					ctx.alloc, ctx.programState, commonTypes,
					//TODO:PERF Use temp alloc
					map(ctx.alloc, parts, (ref Destructure part) => part.type));
				return Destructure(allocate(ctx.alloc, Destructure.Split(type.as!(StructInst*), small(parts))));
			}
		});
}

private:

Opt!T tryFindT(T)(
	ref CheckCtx ctx,
	Sym name,
	RangeWithinFile range,
	Opt!T fromThisModule,
	Diag.DuplicateImports.Kind duplicateImportKind,
	Diag.NameNotFound.Kind nameNotFoundKind,
	in Opt!T delegate(in NameReferents) @safe @nogc pure nothrow getFromNameReferents,
) {
	Cell!(Opt!T) res = Cell!(Opt!T)(fromThisModule);
	eachImportAndReExport(ctx, name, (in NameReferents referents) {
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
