module frontend.check.typeFromAst;

@safe @nogc pure nothrow:

import frontend.check.checkCtx :
	addDiag,
	CheckCtx,
	eachImportAndReExport,
	ImportIndex,
	markUsedImport,
	markUsedSpec,
	markUsedStructOrAlias,
	rangeInFile;
import frontend.check.dicts : SpecDeclAndIndex, SpecsDict, StructsAndAliasesDict, StructOrAliasAndIndex;
import frontend.check.instantiate :
	DelayStructInsts, instantiateStruct, instantiateStructNeverDelay, noDelayStructInsts, TypeArgsArray, typeArgsArray;
import frontend.lang : maxTypeParams;
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
	body_,
	CommonTypes,
	decl,
	Destructure,
	Local,
	LocalMutability,
	NameReferents,
	RecordField,
	SpecDecl,
	StructAlias,
	StructBody,
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
import util.col.arrUtil : eachPair, findPtr, map, mapOrNone, mapWithIndex, mapZipPtrFirst;
import util.col.mutMaxArr : mapTo, tempAsArr;
import util.memory : allocate;
import util.opt : force, has, none, Opt, some;
import util.ptr : castNonScope_ref, ptrTrustMe;
import util.sourceRange : RangeWithinFile;
import util.sym : Sym, sym;
import util.util : todo, verify;

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
	Opt!StructOrAliasAndIndex opDeclFromHere = structsAndAliasesDict[name];
	if (has(opDeclFromHere))
		markUsedStructOrAlias(ctx, force(opDeclFromHere));
	Opt!StructOrAlias here = has(opDeclFromHere)
		? some(force(opDeclFromHere).structOrAlias)
		: none!StructOrAlias;
	Opt!StructOrAlias opDecl = tryFindT!StructOrAlias(
		ctx, name, suffixRange, here,
		Diag.DuplicateImports.Kind.type, Diag.NameNotFound.Kind.type,
		(in NameReferents nr) => nr.structOrAlias);
	if (!has(opDecl))
		return Type(Type.Bogus());
	else {
		StructOrAlias sOrA = force(opDecl);
		TypeArgsArray typeArgs = typeArgsArray();
		Status status = getTypeArgsForStructOrAliasIfNumberMatches(
			typeArgs,
			ctx, commonTypes, suffixRange, structsAndAliasesDict,
			sOrA, typeArgsAst, typeParamsScope, delayStructInsts);
		final switch (status) {
			case Status.ok:
				return sOrA.matchWithPointers!Type(
					(StructAlias* a) =>
						typeParams(sOrA).length != 0
							? todo!Type("alias with type params")
							: typeFromOptInst(target(*a)),
					(StructDecl* decl) =>
						Type(instantiateStruct(
							ctx.alloc, ctx.programState, decl, tempAsArr(typeArgs), delayStructInsts)));
			case Status.error:
				return Type(Type.Bogus());
		}
	}
}

Status getTypeArgsForSpecIfNumberMatches(
	ref TypeArgsArray res,
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	RangeWithinFile range,
	in StructsAndAliasesDict structsAndAliasesDict,
	SpecDecl* spec,
	in Opt!(TypeAst*) typeArgsAst,
	TypeParam[] typeParamsScope,
) =>
	getTypeArgsIfNumberMatches(
		res,
		ctx,
		commonTypes,
		range,
		structsAndAliasesDict,
		spec.typeParams.length,
		typeArgsAst,
		typeParamsScope,
		noDelayStructInsts,
		(size_t expected, size_t actual) => Diag(Diag.WrongNumberTypeArgsForSpec(spec, expected, actual)));

Type makeTupleType(ref CheckCtx ctx, ref CommonTypes commonTypes, in Type[] args) {
	if (args.length == 0)
		return Type(commonTypes.void_);
	else if (args.length == 1)
		return only(args);
	else {
		Opt!(StructDecl*) decl = commonTypes.tuple(args.length);
		return has(decl)
			? Type(instantiateStructNeverDelay(ctx.alloc, ctx.programState, force(decl), args))
			: Type(Type.Bogus());
	}
}

enum Status { ok, error }

private Status getTypeArgsForStructOrAliasIfNumberMatches(
	ref TypeArgsArray res,
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	RangeWithinFile range,
	in StructsAndAliasesDict structsAndAliasesDict,
	StructOrAlias sOrA,
	in Opt!(TypeAst*) typeArgsAst,
	TypeParam[] typeParamsScope,
	DelayStructInsts delayStructInsts,
) =>
	getTypeArgsIfNumberMatches(
		res,
		ctx,
		commonTypes,
		range,
		structsAndAliasesDict,
		typeParams(sOrA).length,
		typeArgsAst,
		typeParamsScope,
		delayStructInsts,
		(size_t expected, size_t actual) => Diag(Diag.WrongNumberTypeArgsForStruct(sOrA, expected, actual)));

private Status getTypeArgsIfNumberMatches(
	ref TypeArgsArray res,
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	RangeWithinFile range,
	in StructsAndAliasesDict structsAndAliasesDict,
	size_t nExpectedTypeArgs,
	in Opt!(TypeAst*) typeArgsAst,
	TypeParam[] typeParamsScope,
	DelayStructInsts delayStructInsts,
	in Diag delegate(size_t expected, size_t actual) @safe @nogc pure nothrow makeDiag,
) {
	TypeAst[] typeArgsArray = tryGetMatchingTypeArgs(nExpectedTypeArgs, typeArgsAst);
	if (typeArgsArray.length == nExpectedTypeArgs) {
		mapTo!(maxTypeParams, Type, TypeAst)(res, typeArgsArray, (ref TypeAst x) =>
			typeFromAst(ctx, commonTypes, x, structsAndAliasesDict, typeParamsScope, delayStructInsts));
		return Status.ok;
	} else {
		addDiag(ctx, range, makeDiag(nExpectedTypeArgs, typeArgsArray.length));
		return Status.error;
	}
}

// May return array of non-matching size
TypeAst[] tryGetMatchingTypeArgs(size_t nTypeParams, Opt!(TypeAst*) typeArgsAst) {
	if (has(typeArgsAst)) {
		TypeAst* args = force(typeArgsAst);
		if (nTypeParams >= 2) {
			Opt!(TypeAst[]) unpacked = tryUnpackTupleType(*args);
			return has(unpacked) ? force(unpacked) : arrayOfSingle(args);
		} else
			return arrayOfSingle(args);
	} else
		return [];
}

Opt!(TypeAst[]) tryUnpackTupleType(in TypeAst a) =>
	a.isA!(TypeAst.Tuple*) ? some(a.as!(TypeAst.Tuple*).members) : none!(TypeAst[]);

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
		(in TypeAst.SuffixName x) @safe {
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
	return makeTupleType(ctx, commonTypes, args);
}

private Opt!(TypeParam*) findTypeParam(TypeParam[] typeParamsScope, Sym name) =>
	findPtr!TypeParam(typeParamsScope, (in TypeParam x) =>
		x.name == name);

Opt!(Diag.TypeShouldUseSyntax.Kind) typeSyntaxKind(Sym a) {
	switch (a.value) {
		case sym!"fun-act".value:
			return some(Diag.TypeShouldUseSyntax.Kind.funAct);
		case sym!"fun-fun".value:
			return some(Diag.TypeShouldUseSyntax.Kind.funFun);
		case sym!"fun-ref".value:
			return some(Diag.TypeShouldUseSyntax.Kind.funRef);
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

Opt!(SpecDecl*) tryFindSpec(ref CheckCtx ctx, NameAndRange name, in SpecsDict specsDict) {
	Opt!SpecDeclAndIndex opDeclFromHere = specsDict[name.name];
	if (has(opDeclFromHere))
		markUsedSpec(ctx, force(opDeclFromHere).index);
	Opt!(SpecDecl*) here = has(opDeclFromHere)
		? some(force(opDeclFromHere).decl)
		: none!(SpecDecl*);
	return tryFindT!(SpecDecl*)(
		ctx,
		name.name,
		rangeOfNameAndRange(name, ctx.allSymbols),
		here,
		Diag.DuplicateImports.Kind.spec,
		Diag.NameNotFound.Kind.spec,
		(in NameReferents nr) =>
			nr.spec);
}

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
			return has(types) ? some(makeTupleType(ctx, commonTypes, force(types))) : none!Type;
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
				Opt!(RecordField[]) fields = getTupleFields(commonTypes, partAsts.length, tupleType);
				if (has(fields))
					return Destructure(allocate(ctx.alloc, Destructure.Split(
						tupleType.as!(StructInst*),
						small(mapZipPtrFirst!(Destructure, RecordField, DestructureAst)(
							ctx.alloc, force(fields), partAsts, (RecordField* field, in DestructureAst part) =>
								checkDestructure(
									ctx, commonTypes, structsAndAliasesDict, typeParamsScope, delayStructInsts,
									part, some(field.type)))))));
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
				//TODO:PERF Use temp alloc
				Type type = makeTupleType(ctx, commonTypes, map(ctx.alloc, parts, (ref Destructure part) => part.type));
				return Destructure(allocate(ctx.alloc, Destructure.Split(type.as!(StructInst*), small(parts))));
			}
		});
}

private:

Opt!(RecordField[]) getTupleFields(ref CommonTypes commonTypes, size_t nParts, Type type) {
	if (2 <= nParts && nParts <= 9 && type.isA!(StructInst*)) {
		StructInst* inst = type.as!(StructInst*);
		StructDecl* decl = decl(*inst);
		if (decl == commonTypes.tuples2Through9[nParts - 2]) {
			RecordField[] fields = body_(*inst).as!(StructBody.Record).fields;
			verify(fields.length == nParts);
			return some(fields);
		} else
			return none!(RecordField[]);
	} else
		return none!(RecordField[]);
}

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
	eachImportAndReExport(ctx, name, (ImportIndex index, in NameReferents referents) {
		Opt!T got = getFromNameReferents(referents);
		if (has(got)) {
			markUsedImport(ctx, index);
			if (has(cellGet(res)))
				// TODO: include both modules in the diag
				addDiag(ctx, range, Diag(Diag.DuplicateImports(duplicateImportKind, name)));
			else
				cellSet(res, got);
		}
	});
	if (!has(cellGet(res)))
		addDiag(ctx, range, Diag(Diag.NameNotFound(nameNotFoundKind, name)));
	return cellGet(res);
}
