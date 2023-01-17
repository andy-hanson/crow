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
	DelayStructInsts, instantiateStruct, instantiateStructNeverDelay, TypeArgsArray, typeArgsArray;
import frontend.lang : maxTypeParams;
import frontend.parse.ast :
	NameAndRange, range, rangeOfNameAndRange, suffixRange, symForTypeAstDict, symForTypeAstSuffix, TypeAst;
import frontend.programState : ProgramState;
import model.diag : Diag;
import model.model :
	CommonTypes,
	NameReferents,
	SpecDecl,
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
import util.col.arr : arrayOfSingle, empty;
import util.col.arrUtil : eachPair, findPtr, mapWithIndex;
import util.col.mutArr : MutArr;
import util.col.mutMaxArr : fillMutMaxArr, mapTo, tempAsArr;
import util.opt : force, has, none, noneMut, Opt, some;
import util.ptr : castNonScope_ref, ptrTrustMe;
import util.sourceRange : RangeWithinFile;
import util.sym : Sym, sym;
import util.util : drop, todo;

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
		drop(getTypeArgsForStructOrAliasIfNumberMatches(
			typeArgs,
			ctx, commonTypes, suffixRange, structsAndAliasesDict,
			sOrA, typeArgsAst, typeParamsScope, delayStructInsts));
		return sOrA.matchWithPointers!Type(
			(StructAlias* a) =>
				typeParams(sOrA).length != 0
					? todo!Type("alias with type params")
					: typeFromOptInst(target(*a)),
			(StructDecl* decl) =>
				Type(instantiateStruct(ctx.alloc, ctx.programState, decl, tempAsArr(typeArgs), delayStructInsts)));
	}
}

bool getTypeArgsForSpecIfNumberMatches(
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
		noneMut!(MutArr!(StructInst*)*),
		(size_t expected, size_t actual) => Diag(Diag.WrongNumberTypeArgsForSpec(spec, expected, actual)));

private bool getTypeArgsForStructOrAliasIfNumberMatches(
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

private bool getTypeArgsIfNumberMatches(
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
		return true;
	} else {
		addDiag(ctx, range, makeDiag(nExpectedTypeArgs, typeArgsArray.length));
		fillMutMaxArr(res, nExpectedTypeArgs, Type(Type.Bogus()));
		return false;
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
	typeFromAst(ctx, commonTypes, ast, structsAndAliasesDict, [], noneMut!(MutArr!(StructInst*)*));

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
			instStructFromAst(
				ctx,
				commonTypes,
				nameForTuple(x.members.length),
				x.range,
				// TODO: this is somewhat hacky .. pass the tuple itself in so it is unpacked
				some(ptrTrustMe(ast)),
				structsAndAliasesDict,
				typeParamsScope,
				delayStructInsts));

private Sym nameForTuple(size_t length) {
	switch (length) {
		case 2:
			return sym!"tuple2";
		case 3:
			return sym!"tuple3";
		case 4:
			return sym!"tuple4";
		case 5:
			return sym!"tuple5";
		case 6:
			return sym!"tuple6";
		default:
			return todo!Sym("support more");
	}
}

private Opt!(TypeParam*) findTypeParam(TypeParam[] typeParamsScope, Sym name) =>
	findPtr!TypeParam(typeParamsScope, (in TypeParam x) =>
		x.name == name);

Opt!(Diag.TypeShouldUseSyntax.Kind) typeSyntaxKind(Sym a) {
	switch (a.value) {
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
	immutable StructDecl*[] structs = commonTypes.funStructs[ast.kind];
	if (ast.returnAndParamTypes.length > structs.length)
		// We don't have a fun type big enough
		todo!void("!");
	StructDecl* decl = structs[ast.returnAndParamTypes.length - 1];
	TypeArgsArray typeArgs = typeArgsArray();
	mapTo!(maxTypeParams, Type, TypeAst)(typeArgs, ast.returnAndParamTypes, (ref TypeAst x) =>
		typeFromAst(ctx, commonTypes, x, structsAndAliasesDict, typeParamsScope, delayStructInsts));
	return Type(instantiateStruct(ctx.alloc, ctx.programState, decl, tempAsArr(typeArgs), delayStructInsts));
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
