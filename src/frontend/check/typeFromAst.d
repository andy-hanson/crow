module frontend.check.typeFromAst;

@safe @nogc pure nothrow:

import frontend.check.checkCtx : addDiag, CheckCtx, CommonModule, eachImportAndReExport, markUsed;
import frontend.check.instantiate :
	instantiateSpec,
	instantiateStruct,
	instantiateStructNeverDelay,
	MayDelaySpecInsts,
	MayDelayStructInsts,
	noDelayStructInsts;
import frontend.check.maps : SpecsMap, StructsAndAliasesMap;
import model.ast :
	DestructureAst, NameAndRange, ParamsAst, SpecUseAst, symbolForTypeAstMap, symbolForTypeAstSuffix, TypeAst;
import model.diag : Diag, TypeContainer, TypeWithContainer;
import model.model :
	asTuple,
	CommonTypes,
	Destructure,
	emptyTypeParams,
	ExportVisibility,
	importCanSee,
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
	Type,
	TypeArgs,
	TypeParamIndex,
	TypeParams;
import util.alloc.stackAlloc : withMapOrNoneToStackArray, withMapToStackArray;
import util.cell : Cell, cellGet, cellSet;
import util.col.array : arrayOfSingle, eachPair, findIndex, isEmpty, map, mapPointers, mapZipPtrFirst, only, small;
import util.conv : safeToUint;
import util.memory : allocate;
import util.opt : force, has, none, Opt, optIf, optOrDefault, some;
import util.sourceRange : combineRanges, Range;
import util.symbol : Symbol, symbol;
import util.util : castNonScope_ref, ptrTrustMe;

private Type instStructFromAst(
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	Symbol name,
	in Range suffixRange,
	in Opt!(TypeAst*) typeArgsAst,
	in StructsAndAliasesMap structsAndAliasesMap,
	in TypeParams typeParamsScope,
	MayDelayStructInsts delayStructInsts,
) {
	Opt!StructOrAlias opDecl = tryFindT!StructOrAlias(
		ctx, name, suffixRange, structsAndAliasesMap[name],
		Diag.DuplicateImports.Kind.type, Diag.NameNotFound.Kind.type,
		(in NameReferents x) => x.structOrAlias);
	if (!has(opDecl))
		return Type.bogus;
	else {
		StructOrAlias sOrA = force(opDecl);
		Opt!Type typeArg = optTypeFromOptAst(
			ctx, commonTypes, typeArgsAst, structsAndAliasesMap, typeParamsScope, delayStructInsts);
		Opt!TypeArgs typeArgs = getTypeArgsIfNumberMatches(
			ctx, commonTypes, suffixRange, name, sOrA.typeParams.length, &typeArg);
		return has(typeArgs)
			? sOrA.matchWithPointers!Type(
				(StructAlias* a) {
					assert(isEmpty(force(typeArgs)));
					return Type(a.target);
				},
				(StructDecl* decl) =>
					Type(instantiateStruct(ctx.instantiateCtx, decl, force(typeArgs), delayStructInsts)))
			: Type.bogus;
	}
}

Type makeTupleType(
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	in Type[] args,
	in Range delegate() @safe @nogc pure nothrow cbDiagRange,
) {
	if (args.length == 0)
		return Type(commonTypes.void_);
	else if (args.length == 1)
		return only(args);
	else {
		Opt!(StructDecl*) decl = commonTypes.tuple(args.length);
		if (has(decl))
			return Type(instantiateStructNeverDelay(ctx.instantiateCtx, force(decl), args));
		else {
			addDiag(ctx, cbDiagRange(), Diag(Diag.TupleTooBig(args.length, commonTypes.maxTupleSize)));
			return Type.bogus;
		}
	}
}

Opt!Type tryUnpackOptionType(in CommonTypes commonTypes, Type optionType) {
	if (optionType.isA!(StructInst*)) {
		StructInst* inst = optionType.as!(StructInst*);
		return optIf(inst.decl == commonTypes.option, () => only(inst.typeArgs));
	} else if (optionType.isBogus)
		return some(Type.bogus);
	else
		return none!Type;
}

private Opt!TypeArgs getTypeArgsIfNumberMatches(
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	in Range range,
	Symbol name,
	size_t nExpectedTypeArgs,
	return in Opt!Type* type,
) {
	Type[] res = has(*type)
		? unpackTupleIfNeeded(commonTypes, nExpectedTypeArgs, &force(*type))
		: [];
	if (res.length == nExpectedTypeArgs)
		return some(small!Type(res));
	else {
		addDiag(ctx, range, Diag(Diag.WrongNumberTypeArgs(name, nExpectedTypeArgs, res.length)));
		return none!TypeArgs;
	}
}

// Tries to return array of length 'nExpectedTypeArgs', but may fail
Type[] unpackTupleIfNeeded(in CommonTypes commonTypes, size_t nExpectedTypeArgs, Type* type) =>
	nExpectedTypeArgs == 1
		? arrayOfSingle(type)
		: optOrDefault!(Type[])(asTuple(commonTypes, *type), () => arrayOfSingle(type));


Type[] unpackTuple(in CommonTypes commonTypes, Type* type) =>
	*type == Type(commonTypes.void_)
		? []
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
			addDiag(ctx, y.range, Diag(Diag.DuplicateDeclaration(Diag.DuplicateDeclaration.Kind.typeParam, y.name)));
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
	in TypeParams typeParamsScope,
	MayDelayStructInsts delayStructInsts,
) =>
	ast.match!Type(
		(TypeAst.Bogus) =>
			Type.bogus,
		(ref TypeAst.Fun x) =>
			typeFromFunAst(ctx, commonTypes, x, structsAndAliasesMap, typeParamsScope, delayStructInsts),
		(ref TypeAst.Map x) =>
			typeFromMapAst(ctx, commonTypes, x, structsAndAliasesMap, typeParamsScope, delayStructInsts),
		(NameAndRange name) {
			Opt!TypeParamIndex typeParam = findTypeParam(typeParamsScope, name.name);
			return has(typeParam)
				? Type(force(typeParam))
				: instStructFromAst(
					ctx,
					commonTypes,
					name.name,
					name.range,
					none!(TypeAst*),
					structsAndAliasesMap,
					typeParamsScope,
					delayStructInsts);
		},
		(ref TypeAst.SuffixName x) {
			Opt!(Diag.TypeShouldUseSyntax.Kind) optSyntax = typeSyntaxKind(x.name.name);
			if (has(optSyntax))
				addDiag(ctx, x.suffixRange, Diag(Diag.TypeShouldUseSyntax(force(optSyntax))));
			Opt!TypeParamIndex typeParam = findTypeParam(typeParamsScope, x.name.name);
			if (has(typeParam)) {
				addDiag(ctx, x.suffixRange, Diag(Diag.TypeParamCantHaveTypeArgs()));
				return Type(force(typeParam));
			} else
				return instStructFromAst(
					ctx,
					commonTypes,
					x.name.name,
					x.suffixRange,
					some(&castNonScope_ref(x).left),
					structsAndAliasesMap,
					typeParamsScope,
					delayStructInsts);
		},
		(ref TypeAst.SuffixSpecial x) =>
			instStructFromAst(
				ctx,
				commonTypes,
				symbolForTypeAstSuffix(x.kind),
				x.suffixRange,
				some(&x.left),
				structsAndAliasesMap,
				typeParamsScope,
				delayStructInsts),
		(ref TypeAst.Tuple x) =>
			typeFromTupleAst(ctx, commonTypes, x.members, structsAndAliasesMap, typeParamsScope, delayStructInsts));

private Opt!Type optTypeFromOptAst(
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	in Opt!(TypeAst*) ast,
	in StructsAndAliasesMap structsAndAliasesMap,
	in TypeParams typeParamsScope,
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
	in TypeParams typeParamsScope,
	in SpecUseAst ast,
	MayDelaySpecInsts delaySpecInsts,
) {
	Opt!(SpecDecl*) opSpec = tryFindSpec(ctx, ast.name, specsMap);
	if (has(opSpec)) {
		SpecDecl* spec = force(opSpec);
		Opt!Type typeArg = has(ast.typeArg)
			? some(typeFromAst(
				ctx, commonTypes, force(ast.typeArg), structsAndAliasesMap, typeParamsScope, noDelayStructInsts))
			: none!Type;
		Opt!TypeArgs typeArgs = getTypeArgsIfNumberMatches(
			ctx, commonTypes, ast.name.range, spec.name, spec.typeParams.length, &typeArg);
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
	in TypeParams typeParamsScope,
	MayDelayStructInsts delayStructInsts,
) =>
	withMapToStackArray!(Type, Type, TypeAst)(
		members,
		(ref TypeAst x) => typeFromAst(ctx, commonTypes, x, structsAndAliasesMap, typeParamsScope, delayStructInsts),
		(scope Type[] types) =>
			makeTupleType(ctx, commonTypes, types, () => combineRanges(members[0].range, members[$ - 1].range)));

private Opt!TypeParamIndex findTypeParam(in TypeParams typeParamsScope, Symbol name) {
	Opt!size_t res = findIndex!NameAndRange(typeParamsScope, (in NameAndRange x) =>
		x.name == name);
	return has(res) ? some(TypeParamIndex(safeToUint(force(res)))) : none!TypeParamIndex;
}

Opt!(Diag.TypeShouldUseSyntax.Kind) typeSyntaxKind(Symbol a) {
	switch (a.value) {
		case symbol!"fun-data".value:
			return some(Diag.TypeShouldUseSyntax.Kind.funData);
		case symbol!"fun-mut".value:
			return some(Diag.TypeShouldUseSyntax.Kind.funMut);
		case symbol!"fun-pointer".value:
			return some(Diag.TypeShouldUseSyntax.Kind.funPointer);
		case symbol!"fun-shared".value:
			return some(Diag.TypeShouldUseSyntax.Kind.funShared);
		case symbol!"const-pointer".value:
			return some(Diag.TypeShouldUseSyntax.Kind.pointer);
		case symbol!"map".value:
			return some(Diag.TypeShouldUseSyntax.Kind.map);
		case symbol!"list".value:
			return some(Diag.TypeShouldUseSyntax.Kind.list);
		case symbol!"mut-map".value:
			return some(Diag.TypeShouldUseSyntax.Kind.mutMap);
		case symbol!"mut-list".value:
			return some(Diag.TypeShouldUseSyntax.Kind.mutList);
		case symbol!"mut-pointer".value:
			return some(Diag.TypeShouldUseSyntax.Kind.mutPointer);
		case symbol!"option".value:
			return some(Diag.TypeShouldUseSyntax.Kind.opt);
		case symbol!"shared-list".value:
			return some(Diag.TypeShouldUseSyntax.Kind.sharedList);
		case symbol!"shared-map".value:
			return some(Diag.TypeShouldUseSyntax.Kind.sharedMap);
		case symbol!"tuple2".value:
		case symbol!"tuple3".value:
		case symbol!"tuple4".value:
		case symbol!"tuple5".value:
		case symbol!"tuple6".value:
		case symbol!"tuple7".value:
		case symbol!"tuple8".value:
		case symbol!"tuple9".value:
			return some(Diag.TypeShouldUseSyntax.Kind.tuple);
		default:
			return none!(Diag.TypeShouldUseSyntax.Kind);
	}
}

private Type typeFromFunAst(
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	in TypeAst.Fun ast,
	in StructsAndAliasesMap structsAndAliasesMap,
	in TypeParams typeParamsScope,
	MayDelayStructInsts delayStructInsts,
) {
	Type returnType = typeFromAst(
		ctx, commonTypes, ast.returnType, structsAndAliasesMap, typeParamsScope, delayStructInsts);
	Type paramType = ast.params.matchIn!Type(
		(in DestructureAst[] params) {
			Opt!Type res = typeFromDestructures(
				ctx, commonTypes, structsAndAliasesMap, typeParamsScope, delayStructInsts, params);
			if (!has(res))
				addDiag(ctx, ast.paramsRange, Diag(Diag.LambdaTypeMissingParamType()));
			return optOrDefault!Type(res, () => Type.bogus);
		},
		(in ParamsAst.Varargs x) {
			addDiag(ctx, x.param.range, Diag(Diag.LambdaTypeVariadic()));
			return Type.bogus;
		});
	Type[2] typeArgs = [returnType, paramType];
	return Type(instantiateStruct(
		ctx.instantiateCtx, commonTypes.funStructs[ast.kind], small!Type(typeArgs), delayStructInsts));
}

private Type typeFromMapAst(
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	in TypeAst.Map ast,
	in StructsAndAliasesMap structsAndAliasesMap,
	in TypeParams typeParamsScope,
	MayDelayStructInsts delayStructInsts,
) {
	TypeAst.Tuple tuple = TypeAst.Tuple(Range.empty, castNonScope_ref(ast.kv));
	TypeAst typeArg = TypeAst(&tuple);
	return instStructFromAst(
		ctx,
		commonTypes,
		symbolForTypeAstMap(ast.kind),
		ast.range,
		some(ptrTrustMe(typeArg)),
		structsAndAliasesMap,
		typeParamsScope,
		delayStructInsts);
}

Opt!(SpecDecl*) getSpecFromCommonModule(
	ref CheckCtx ctx,
	in SpecsMap specsMap,
	Range diagRange,
	Symbol name,
	CommonModule expectedModule,
) {
	Opt!(SpecDecl*) spec = tryFindSpec(ctx, NameAndRange(diagRange.start, name), specsMap);
	if (has(spec)) {
		if (force(spec).moduleUri != ctx.commonUris[expectedModule]) {
			addDiag(ctx, diagRange, Diag(Diag.AutoFunError(Diag.AutoFunError.SpecFromWrongModule())));
			return none!(SpecDecl*);
		} else
			return spec;
	} else
		return none!(SpecDecl*);
}

private Opt!(SpecDecl*) tryFindSpec(ref CheckCtx ctx, NameAndRange name, in SpecsMap specsMap) =>
	tryFindT!(SpecDecl*)(
		ctx,
		name.name,
		name.range,
		specsMap[name.name],
		Diag.DuplicateImports.Kind.spec,
		Diag.NameNotFound.Kind.spec,
		(in NameReferents x) => x.spec);

Opt!Type typeFromDestructure(
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	in DestructureAst ast,
	in StructsAndAliasesMap structsAndAliasesMap,
	in TypeParams typeParamsScope,
	MayDelayStructInsts delayStructInsts,
) =>
	ast.matchIn!(Opt!Type)(
		(in DestructureAst.Single x) =>
			has(x.type)
				? some(typeFromAst(
					ctx, commonTypes, *force(x.type), structsAndAliasesMap, typeParamsScope, delayStructInsts))
				: none!Type,
		(in DestructureAst.Void) =>
			some(Type(commonTypes.void_)),
		(in DestructureAst[] parts) =>
			typeFromDestructures(ctx, commonTypes, structsAndAliasesMap, typeParamsScope, delayStructInsts, parts));

private Opt!Type typeFromDestructures(
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	in StructsAndAliasesMap structsAndAliasesMap,
	in TypeParams typeParamsScope,
	MayDelayStructInsts delayStructInsts,
	in DestructureAst[] parts,
) =>
	withMapOrNoneToStackArray!(Type, Type, DestructureAst)(
		parts,
		(ref DestructureAst part) =>
			typeFromDestructure(ctx, commonTypes, part, structsAndAliasesMap, typeParamsScope, delayStructInsts),
		(Type[] types) =>
			makeTupleType(ctx, commonTypes, types, () => combineRanges(parts[0].range, parts[$ - 1].range)));

enum DestructureKind { local, param }
Destructure checkDestructure(
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	in StructsAndAliasesMap structsAndAliasesMap,
	TypeContainer typeContainer,
	// 'typeContainer' may be uninitialized, so pass 'typeParamsScope' separately
	TypeParams typeParamsScope,
	MayDelayStructInsts delayStructInsts,
	DestructureAst* ast,
	// This is for the type coming from the RHS of a 'let', or the expected type of a lambda
	Opt!Type destructuredType,
	DestructureKind kind,
) {
	TypeWithContainer typeWithContainer(Type x) =>
		TypeWithContainer(x, typeContainer);
	Type getType(Opt!Type declaredType) {
		if (has(declaredType)) {
			if (has(destructuredType) && force(destructuredType) != force(declaredType))
				addDiag(ctx, ast.range, Diag(
					Diag.DestructureTypeMismatch(
						Diag.DestructureTypeMismatch.Expected(typeWithContainer(force(declaredType))),
						typeWithContainer(force(destructuredType)))));
			return force(declaredType);
		} else if (has(destructuredType))
			return force(destructuredType);
		else {
			addDiag(ctx, ast.range, Diag(Diag.ParamMissingType()));
			return Type.bogus;
		}
	}
	return ast.match!Destructure(
		(DestructureAst.Single x) {
			Opt!Type declaredType = has(x.type)
				? some(typeFromAst(
					ctx, commonTypes, *force(x.type), structsAndAliasesMap, typeParamsScope, delayStructInsts))
				: none!Type;
			Type type = getType(declaredType);
			if (x.name.name == symbol!"_") {
				if (has(x.mut))
					addDiag(ctx, ast.range, Diag(Diag.LocalIgnoredButMutable()));
				return Destructure(allocate(ctx.alloc, Destructure.Ignore(x.name.start, type)));
			} else {
				LocalMutability mutability = () {
					if (has(x.mut) && kind == DestructureKind.param) {
						Opt!Range mutRange = x.mutRange;
						addDiag(ctx, force(mutRange), Diag(Diag.ParamMutable()));
						return LocalMutability.immut;
					} else
						return has(x.mut) ? LocalMutability.mutOnStack : LocalMutability.immut;
				}();
				Opt!Type referenceType = some(Type(instantiateStructNeverDelay(ctx.instantiateCtx, commonTypes.reference, [type]))); // TODO: we shouldn't have to do this in frontend
				return Destructure(allocate(ctx.alloc, Local(
					LocalSource(&ast.as!(DestructureAst.Single)()), mutability, type, referenceType)));
			}
		},
		(DestructureAst.Void x) {
			Type type = getType(some(Type(commonTypes.void_)));
			return Destructure(allocate(ctx.alloc, Destructure.Ignore(x.range.start, type)));
		},
		(DestructureAst[] partAsts) {
			if (has(destructuredType)) {
				Type tupleType = force(destructuredType);
				Opt!(Type[]) fieldTypes = asTuple(commonTypes, tupleType);
				if (has(fieldTypes) && force(fieldTypes).length == partAsts.length)
					return Destructure(allocate(ctx.alloc, Destructure.Split(
						tupleType,
						small!Destructure(mapZipPtrFirst!(Destructure, DestructureAst, Type)(
							ctx.alloc, partAsts, force(fieldTypes), (DestructureAst* part, Type fieldType) =>
								checkDestructure(
									ctx, commonTypes, structsAndAliasesMap,
									typeContainer, typeParamsScope, delayStructInsts,
									part, some(fieldType), kind))))));
				else {
					addDiag(ctx, ast.range, Diag(
						Diag.DestructureTypeMismatch(
							Diag.DestructureTypeMismatch.Expected(
								Diag.DestructureTypeMismatch.Expected.Tuple(partAsts.length)),
							typeWithContainer(tupleType))));
					return Destructure(allocate(ctx.alloc, Destructure.Split(
						Type.bogus,
						mapPointers!(Destructure, DestructureAst)(
							ctx.alloc, small!DestructureAst(partAsts), (DestructureAst* part) =>
								checkDestructure(
									ctx, commonTypes, structsAndAliasesMap,
									typeContainer, typeParamsScope, delayStructInsts,
									part, some(Type.bogus), kind)))));
				}
			} else {
				Destructure[] parts = mapPointers(ctx. alloc, partAsts, (DestructureAst* part) =>
					checkDestructure(
						ctx, commonTypes, structsAndAliasesMap, typeContainer, typeParamsScope, delayStructInsts,
						part, none!Type, kind));
				Type type = withMapToStackArray(
					parts,
					(ref Destructure x) => x.type,
					(scope Type[] types) =>
						makeTupleType(ctx, commonTypes, types, () =>
							combineRanges(partAsts[0].range, partAsts[$ - 1].range)));
				return Destructure(allocate(ctx.alloc, Destructure.Split(type, small!Destructure(parts))));
			}
		});
}

private:

Opt!T tryFindT(T)(
	ref CheckCtx ctx,
	Symbol name,
	in Range range,
	Opt!T fromThisModule,
	Diag.DuplicateImports.Kind duplicateImportKind,
	Diag.NameNotFound.Kind nameNotFoundKind,
	in Opt!T delegate(in NameReferents) @safe @nogc pure nothrow getFromNameReferents,
) {
	Cell!(Opt!T) res = Cell!(Opt!T)(fromThisModule);
	eachImportAndReExport(ctx.importsAndReExports, name, (ExportVisibility visibility, in NameReferents referents) {
		Opt!T got = getFromNameReferents(referents);
		if (has(got) && importCanSee(visibility, force(got).visibility)) {
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
