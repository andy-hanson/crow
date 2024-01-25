module frontend.check.check;

@safe @nogc pure nothrow:

import frontend.check.checkCtx :
	addDiag,
	addDiagAssertSameUri,
	CheckCtx,
	checkForUnused,
	checkNoTypeParams,
	CommonUris,
	finishDiagnostics,
	ImportAndReExportModules,
	visibilityFromExplicitTopLevel;
import frontend.check.checkExpr : checkFunctionBody, checkTestBody, TestBody;
import frontend.check.checkStructs : checkStructBodies, checkStructsInitial;
import frontend.check.getBuiltinFun : getBuiltinFun;
import frontend.check.getCommonTypes : getCommonTypes;
import frontend.check.maps : funDeclsName, FunsMap, specDeclName, SpecsMap, structOrAliasName, StructsAndAliasesMap;
import frontend.check.funsForStruct : addFunsForStruct, addFunsForVar, countFunsForStructs, countFunsForVars;
import frontend.check.instantiate :
	DelaySpecInsts,
	DelayStructInsts,
	MayDelaySpecInsts,
	MayDelayStructInsts,
	InstantiateCtx,
	instantiateSpecBody,
	instantiateStructTypes,
	noDelaySpecInsts,
	noDelayStructInsts;
import frontend.check.typeFromAst :
	checkDestructure, checkTypeParams, specFromAst, typeFromAst, typeFromAstNoTypeParamsNeverDelay;
import model.ast :
	DestructureAst,
	EmptyAst,
	ExprAst,
	FileAst,
	FunDeclAst,
	ModifierAst,
	ModifierKeyword,
	ImportOrExportAstKind,
	ImportsOrExportsAst,
	ImportOrExportAst,
	NameAndRange,
	nameRange,
	ParamsAst,
	pathRange,
	range,
	rangeOfNameAndRange,
	SpecDeclAst,
	SpecSigAst,
	StructAliasAst,
	TestAst,
	TypeAst,
	VarDeclAst;
import frontend.allInsts : AllInsts;
import frontend.storage : FileContent;
import model.diag : DeclKind, Diag, Diagnostic, TypeContainer;
import model.model :
	BuiltinSpec,
	BogusExpr,
	CommonTypes,
	Destructure,
	ExportVisibility,
	Expr,
	ExprKind,
	FunBody,
	FunDecl,
	FunDeclSource,
	FunFlags,
	importCanSee,
	ImportFileType,
	ImportOrExport,
	ImportOrExportKind,
	isLinkageAlwaysCompatible,
	Linkage,
	linkageRange,
	Module,
	nameFromNameReferents,
	nameRange,
	NameReferents,
	Params,
	paramsArray,
	SpecDecl,
	SpecDeclBody,
	SpecDeclSig,
	SpecInst,
	StructAlias,
	StructDecl,
	StructInst,
	StructOrAlias,
	Test,
	Type,
	TypeParamIndex,
	TypeParams,
	VarDecl,
	VarKind,
	Visibility;
import util.alloc.alloc : Alloc;
import util.cell : Cell, cellGet, cellSet;
import util.col.array :
	arrayOfSingle,
	concatenate,
	emptySmallArray,
	exists,
	filter,
	isEmpty,
	map,
	mapOp,
	mapPointers,
	mapWithResultPointer,
	mustFind,
	only,
	small,
	SmallArray,
	zip,
	zipPointers;
import util.col.arrayBuilder : add, ArrayBuilder, asTemporaryArray, finish, smallFinish;
import util.col.exactSizeArrayBuilder : buildArrayExact, ExactSizeArrayBuilder, pushUninitialized;
import util.col.hashTable :
	getPointer, HashTable, insertOrUpdate, mapAndMovePreservingKeys, mayAdd, moveToImmutable, MutHashTable;
import util.col.mutArr : mustPop, mutArrIsEmpty;
import util.col.mutMaxArr : isFull, mustPop, MutMaxArr, mutMaxArr, toArray;
import util.memory : allocate, initMemory;
import util.opt : force, has, none, Opt, someMut, some;
import util.perf : Perf, PerfMeasure, withMeasure;
import util.sourceRange : Range, UriAndRange;
import util.symbol : AllSymbols, Symbol, symbol;
import util.union_ : TaggedUnion;
import util.uri : AllUris, Path, RelPath, Uri;
import util.util : enumConvert, optEnumConvert, ptrTrustMe;

immutable struct UriAndAst {
	Uri uri;
	FileAst* ast;
}

immutable struct ResolvedImport {
	// Uri is for a file import
	mixin TaggedUnion!(Module*, Uri, Diag.ImportFileDiag*);
}

immutable struct BootstrapCheck {
	Module* module_;
	CommonTypes* commonTypes;
}

BootstrapCheck checkBootstrap(
	scope ref Perf perf,
	ref Alloc alloc,
	scope ref AllSymbols allSymbols,
	in AllUris allUris,
	ref AllInsts allInsts,
	in CommonUris commonUris,
	ref UriAndAst uriAndAst,
) =>
	checkWorker(
		alloc, perf, allSymbols, allUris, allInsts, commonUris, [], uriAndAst,
		(ref CheckCtx ctx,
		in StructsAndAliasesMap structsAndAliasesMap,
		scope ref DelayStructInsts delayedStructInsts) =>
			getCommonTypes(
				ctx.alloc, ctx.curUri, ctx.instantiateCtx, ctx.diagnosticsBuilder,
				structsAndAliasesMap, delayedStructInsts));

Module* check(
	scope ref Perf perf,
	ref Alloc alloc,
	scope ref AllSymbols allSymbols,
	in AllUris allUris,
	ref AllInsts allInsts,
	in CommonUris commonUris,
	ref UriAndAst uriAndAst,
	in ResolvedImport[] imports,
	CommonTypes* commonTypes,
) =>
	checkWorker(
		alloc, perf, allSymbols, allUris, allInsts, commonUris, imports, uriAndAst,
		(ref CheckCtx _, in StructsAndAliasesMap _2, scope ref DelayStructInsts _3) => commonTypes,
	).module_;

private:

Params checkParams(
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	TypeContainer typeContainer,
	in ParamsAst ast,
	in StructsAndAliasesMap structsAndAliasesMap,
	TypeParams typeParamsScope,
	MayDelayStructInsts delayStructInsts,
) =>
	ast.match!Params(
		(DestructureAst[] asts) =>
			Params(map!(Destructure, DestructureAst)(ctx.alloc, asts, (ref DestructureAst ast) =>
				checkDestructure(
					ctx, commonTypes, structsAndAliasesMap, typeContainer, typeParamsScope, delayStructInsts,
					ast, none!Type))),
		(ref ParamsAst.Varargs varargs) {
			Destructure param = checkDestructure(
				ctx, commonTypes, structsAndAliasesMap, typeContainer, typeParamsScope,
				delayStructInsts, varargs.param, none!Type);
			Opt!Type elementType = param.type.matchIn!(Opt!Type)(
				(in Type.Bogus _) =>
					some(Type(Type.Bogus())),
				(in TypeParamIndex _) =>
					none!Type,
				(in StructInst x) =>
					x.decl == commonTypes.array
					? some(only(x.typeArgs))
					: none!Type);
			if (!has(elementType))
				addDiag(ctx, varargs.param.range(ctx.allSymbols), Diag(Diag.VarargsParamMustBeArray()));
			return Params(allocate(ctx.alloc,
				Params.Varargs(param, has(elementType) ? force(elementType) : Type(Type.Bogus()))));
		});

immutable struct ReturnTypeAndParams {
	Type returnType;
	Params params;
}
ReturnTypeAndParams checkReturnTypeAndParams(
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	TypeContainer typeContainer,
	in TypeAst returnTypeAst,
	in ParamsAst paramsAst,
	TypeParams typeParams,
	in StructsAndAliasesMap structsAndAliasesMap,
	MayDelayStructInsts delayStructInsts
) =>
	ReturnTypeAndParams(
		typeFromAst(ctx, commonTypes, returnTypeAst, structsAndAliasesMap, typeParams, delayStructInsts),
		checkParams(ctx, commonTypes, typeContainer, paramsAst, structsAndAliasesMap, typeParams, delayStructInsts));

Opt!BuiltinSpec getBuiltinSpec(ref CheckCtx ctx, in Range range, Symbol name) {
	switch (name.value) {
		case symbol!"data".value:
			return some(BuiltinSpec.data);
		case symbol!"shared".value:
			return some(BuiltinSpec.shared_);
		default:
			addDiag(ctx, range, Diag(Diag.BuiltinUnsupported(Diag.BuiltinUnsupported.Kind.spec, name)));
			return none!BuiltinSpec;
	}
}

SpecDeclBody checkSpecDeclBody(
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	in StructsAndAliasesMap structsAndAliasesMap,
	in SpecsMap specsMap,
	TypeContainer typeContainer,
	TypeParams typeParams,
	ref DelaySpecInsts delaySpecInsts,
	in SpecDeclAst ast,
) {
	SpecFlagsAndParents modifiers = checkSpecModifiers(
		ctx, commonTypes, structsAndAliasesMap, specsMap, delaySpecInsts, ast.typeParams, ast.modifiers);
	Opt!BuiltinSpec builtin = modifiers.isBuiltin
		? getBuiltinSpec(ctx, nameRange(ctx.allSymbols, ast), ast.name.name)
		: none!BuiltinSpec;
	SpecDeclSig[] sigs = mapPointers(ctx.alloc, ast.sigs, (SpecSigAst* x) {
		ReturnTypeAndParams rp = checkReturnTypeAndParams(
			ctx, commonTypes, typeContainer, x.returnType, x.params,
			typeParams, structsAndAliasesMap, noDelayStructInsts);
		Destructure[] params = rp.params.matchWithPointers!(Destructure[])(
			(Destructure[] x) =>
				x,
			(Params.Varargs* x) {
				addDiag(ctx, x.param.range(ctx.allSymbols), Diag(Diag.SpecSigCantBeVariadic()));
				return arrayOfSingle(&x.param);
			});
		return SpecDeclSig(ctx.curUri, x, x.name, rp.returnType, small!Destructure(params));
	});
	return SpecDeclBody(builtin, small!(immutable SpecInst*)(modifiers.parents), small!SpecDeclSig(sigs));
}

@trusted SpecDecl[] checkSpecDeclsInitial(
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	ref StructsAndAliasesMap structsAndAliasesMap,
	SpecDeclAst[] asts,
) =>
	mapWithResultPointer!(SpecDecl, SpecDeclAst)(ctx.alloc, asts, (SpecDeclAst* ast, SpecDecl* out_) {
		checkTypeParams(ctx, ast.typeParams);
		return SpecDecl(ctx.curUri, ast, visibilityFromExplicitTopLevel(ast.visibility), ast.name.name);
	});

void checkSpecBodies(
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	ref StructsAndAliasesMap structsAndAliasesMap,
	ref SpecsMap specsMap,
	in SpecDeclAst[] asts,
	SpecDecl[] specs,
) {
	DelaySpecInsts delaySpecInsts = DelaySpecInsts(ctx.allocPtr);

	zipPointers!(SpecDeclAst, SpecDecl)(asts, specs, (SpecDeclAst* ast, SpecDecl* spec) {
		spec.body_ = checkSpecDeclBody(
			ctx, commonTypes, structsAndAliasesMap, specsMap,
			TypeContainer(spec), ast.typeParams, delaySpecInsts, *ast);
	});

	foreach (ref SpecDecl decl; specs)
		detectAndFixSpecRecursion(ctx, &decl);

	while (!mutArrIsEmpty(delaySpecInsts))
		instantiateSpecBody(ctx.instantiateCtx, mustPop(delaySpecInsts), someMut(&delaySpecInsts));
}

void detectAndFixSpecRecursion(ref CheckCtx ctx, SpecDecl* decl) {
	MutMaxArr!(8, immutable SpecDecl*) trace = mutMaxArr!(8, immutable SpecDecl*);
	if (recurDetectSpecRecursion(decl, trace)) {
		addDiagAssertSameUri(ctx, decl.range, Diag(Diag.SpecRecursion(toArray(ctx.alloc, trace))));
		decl.overwriteParentsToEmpty();
	}
}
bool recurDetectSpecRecursion(SpecDecl* cur, ref MutMaxArr!(8, immutable SpecDecl*) trace) {
	if (!isEmpty(cur.parents) && isFull(trace))
		return true;
	foreach (SpecInst* parent; cur.parents) {
		trace ~= parent.decl;
		if (recurDetectSpecRecursion(parent.decl, trace))
			return true;
		else
			mustPop(trace);
	}
	return false;
}

StructAlias[] checkStructAliasesInitial(ref CheckCtx ctx, scope StructAliasAst[] asts) =>
	mapPointers!(StructAlias, StructAliasAst)(ctx.alloc, asts, (StructAliasAst* ast) {
		checkNoTypeParams(ctx, ast.typeParams, DeclKind.alias_);
		return StructAlias(ast, ctx.curUri, visibilityFromExplicitTopLevel(ast.visibility), ast.name.name);
	});

void checkStructAliasTargets(
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	in StructsAndAliasesMap structsAndAliasesMap,
	StructAlias[] aliases,
	in StructAliasAst[] asts,
	scope ref DelayStructInsts delayStructInsts,
) {
	zip!(StructAlias, StructAliasAst)(aliases, asts, (ref StructAlias structAlias, ref StructAliasAst ast) {
		Type type = typeFromAst(
			ctx,
			commonTypes,
			ast.target,
			structsAndAliasesMap,
			ast.typeParams,
			someMut(ptrTrustMe(delayStructInsts)));
		assert(type.isA!(StructInst*) || type.isA!(Type.Bogus)); // since type aliases can't have type parameters
		structAlias.target = type.isA!(StructInst*)
			? type.as!(StructInst*)
			: commonTypes.void_;
	});
}

StructsAndAliasesMap buildStructsAndAliasesMap(ref CheckCtx ctx, StructDecl[] structs, StructAlias[] aliases) {
	MutHashTable!(StructOrAlias, Symbol, structOrAliasName) builder;
	void add(StructOrAlias sa) {
		addToDeclsMap!StructOrAlias(
			ctx, builder, sa, Diag.DuplicateDeclaration.Kind.structOrAlias, (in StructOrAlias x) =>
				nameRange(ctx.allSymbols, x));
	}
	foreach (ref StructDecl decl; structs)
		add(StructOrAlias(&decl));
	foreach (ref StructAlias alias_; aliases)
		add(StructOrAlias(&alias_));
	return moveToImmutable(builder);
}

VarDecl checkVarDecl(
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	in StructsAndAliasesMap structsAndAliasesMap,
	VarDeclAst* ast,
) {
	checkNoTypeParams(ctx, ast.typeParams, enumConvert!DeclKind(ast.kind));
	return VarDecl(
		ast,
		ctx.curUri,
		visibilityFromExplicitTopLevel(ast.visibility),
		ast.name.name,
		ast.kind,
		typeFromAstNoTypeParamsNeverDelay(ctx, commonTypes, ast.type, structsAndAliasesMap),
		checkVarModifiers(ctx, ast.kind, ast.modifiers));
}

Opt!Symbol checkVarModifiers(ref CheckCtx ctx, VarKind kind, in ModifierAst[] modifiers) {
	Cell!(Opt!Symbol) externLibraryName;
	foreach (ref ModifierAst modifier; modifiers) {
		Range diagRange = modifier.range(ctx.allSymbols);
		modifier.matchIn!void(
			(in ModifierAst.Keyword x) {
				addDiag(ctx, diagRange, x.kind == ModifierKeyword.extern_
					? Diag(Diag.ExternMissingLibraryName())
					: Diag(Diag.ModifierInvalid(x.kind, declKind(kind))));
			},
			(in ModifierAst.Extern x) {
				if (has(cellGet(externLibraryName)))
					addDiag(ctx, diagRange, Diag(Diag.ModifierDuplicate(ModifierKeyword.extern_)));
				final switch (kind) {
					case VarKind.global:
						cellSet(externLibraryName, some(
							externLibraryNameFromTypeArg(ctx, x.suffixRange, some(*x.left))));
						break;
					case VarKind.threadLocal:
						addDiag(ctx, diagRange, Diag(
							Diag.ModifierInvalid(ModifierKeyword.extern_, DeclKind.threadLocal)));
						break;
				}
			},
			(in TypeAst x) {
				addDiag(ctx, diagRange, Diag(Diag.SpecUseInvalid(declKind(kind))));
			});
	}
	return cellGet(externLibraryName);
}

DeclKind declKind(VarKind a) =>
	enumConvert!DeclKind(a);

void addToDeclsMap(T, alias getName)(
	ref CheckCtx ctx,
	scope ref MutHashTable!(T, Symbol, getName) builder,
	T added,
	Diag.DuplicateDeclaration.Kind kind,
	in UriAndRange delegate(in T) @safe @nogc pure nothrow cbNameRange,
) {
	if (!mayAdd(ctx.alloc, builder, added))
		addDiagAssertSameUri(ctx, cbNameRange(added), Diag(Diag.DuplicateDeclaration(kind, getName(added))));
}

immutable struct FunsAndMap {
	SmallArray!FunDecl funs;
	SmallArray!Test tests;
	FunsMap funsMap;
}

immutable struct SpecFlagsAndParents {
	bool isBuiltin;
	SpecInst*[] parents;
}

SpecFlagsAndParents checkSpecModifiers(
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	in StructsAndAliasesMap structsAndAliasesMap,
	in SpecsMap specsMap,
	ref DelaySpecInsts delaySpecInsts,
	in TypeParams typeParamsScope,
	in ModifierAst[] asts,
) {
	bool builtin = false;
	immutable SpecInst*[] parents = mapOp!(immutable SpecInst*, ModifierAst)(ctx.alloc, asts, (ref ModifierAst ast) =>
		ast.matchIn!(Opt!(SpecInst*))(
			(in ModifierAst.Keyword x) {
				switch (x.kind) {
					case ModifierKeyword.builtin:
						if (builtin)
							addDiag(ctx, x.range, Diag(Diag.ModifierDuplicate(x.kind)));
						builtin = true;
						break;
					default:
						addDiag(ctx, x.range, Diag(
							Diag.ModifierInvalid(x.kind, DeclKind.spec)));
						break;
				}
				return none!(SpecInst*);
			},
			(in ModifierAst.Extern x) {
				addDiag(ctx, x.suffixRange, Diag(Diag.ModifierInvalid(ModifierKeyword.extern_, DeclKind.spec)));
				return none!(SpecInst*);
			},
			(in TypeAst x) =>
				checkFunModifierNonSpecial(
					ctx, commonTypes, structsAndAliasesMap, specsMap, typeParamsScope, x,
					someMut(ptrTrustMe(delaySpecInsts)))));
	return SpecFlagsAndParents(builtin, parents);
}

immutable struct FunFlagsAndSpecs {
	FunFlags flags;
	SpecInst*[] specs;
}

FunFlagsAndSpecs checkFunModifiers(
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	in StructsAndAliasesMap structsAndAliasesMap,
	in SpecsMap specsMap,
	TypeParams typeParamsScope,
	in Range range,
	in ModifierAst[] asts,
) {
	CollectedFunFlags allFlags = CollectedFunFlags.none;
	immutable SpecInst*[] specs =
		mapOp!(immutable SpecInst*, ModifierAst)(ctx.alloc, asts, (ref ModifierAst ast) =>
			ast.matchIn!(Opt!(SpecInst*))(
				(in ModifierAst.Keyword x) {
					CollectedFunFlags flag = tryGetFunFlag(x.kind);
					if (flag == CollectedFunFlags.none)
						addDiag(ctx, x.range, Diag(Diag.ModifierInvalid(x.kind, DeclKind.function_)));
					if (allFlags & flag)
						addDiag(ctx, x.range, Diag(Diag.ModifierDuplicate(x.kind)));
					allFlags |= flag;
					return none!(SpecInst*);
				},
				(in ModifierAst.Extern x) {
					if (allFlags & CollectedFunFlags.extern_)
						addDiag(ctx, x.suffixRange, Diag(Diag.ModifierDuplicate(ModifierKeyword.extern_)));
					allFlags |= CollectedFunFlags.extern_;
					return none!(SpecInst*);
				},
				(in TypeAst x) =>
					checkFunModifierNonSpecial(
						ctx, commonTypes, structsAndAliasesMap, specsMap, typeParamsScope, x, noDelaySpecInsts)));
	return FunFlagsAndSpecs(checkFunFlags(ctx, range, allFlags, isTest: false), specs);
}

FunFlags checkTestModifiers(ref CheckCtx ctx, in TestAst ast) {
	CollectedFunFlags allFlags = CollectedFunFlags.none;
	foreach (ModifierAst modifier; ast.modifiers) {
		modifier.matchIn!void(
			(in ModifierAst.Keyword x) {
				CollectedFunFlags flag = tryGetFunFlag(x.kind);
				if (isAllowedTestFlag(flag))
					allFlags |= flag;
				else
					addDiag(ctx, x.range, Diag(Diag.ModifierInvalid(x.kind, DeclKind.test)));
			},
			(in ModifierAst.Extern x) {
				addDiag(ctx, x.suffixRange, Diag(Diag.ModifierInvalid(ModifierKeyword.extern_, DeclKind.test)));
			},
			(in TypeAst x) {
				addDiag(ctx, x.range(ctx.allSymbols), Diag(Diag.SpecUseInvalid(DeclKind.test)));
			});
	}
	return checkFunFlags(ctx, ast.keywordRange, allFlags, isTest: true);
}

bool isAllowedTestFlag(CollectedFunFlags flag) {
	switch (flag) {
		case CollectedFunFlags.bare:
		case CollectedFunFlags.summon:
		case CollectedFunFlags.trusted:
			return true;
		default:
			return false;
	}
}

enum CollectedFunFlags {
	none = 0,
	bare = 1,
	builtin = 0b10,
	extern_ = 0b100,
	forceCtx = 0b1000,
	summon = 0b10000,
	trusted = 0b100000,
	unsafe = 0b1000000,
}

CollectedFunFlags tryGetFunFlag(ModifierKeyword kind) =>
	optEnumConvert!CollectedFunFlags(kind, CollectedFunFlags.none);

Opt!(SpecInst*) checkFunModifierNonSpecial(
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	in StructsAndAliasesMap structsAndAliasesMap,
	in SpecsMap specsMap,
	in TypeParams typeParamsScope,
	in TypeAst ast,
	MayDelaySpecInsts delaySpecInsts,
) {
	if (ast.isA!NameAndRange) {
		return specFromAst(
			ctx, commonTypes, structsAndAliasesMap, specsMap, typeParamsScope,
			none!(TypeAst*), ast.as!NameAndRange, delaySpecInsts);
	} else if (ast.isA!(TypeAst.SuffixName*)) {
		TypeAst.SuffixName* n = ast.as!(TypeAst.SuffixName*);
		return specFromAst(
			ctx, commonTypes, structsAndAliasesMap, specsMap, typeParamsScope, some(&n.left), n.name, delaySpecInsts);
	} else {
		addDiag(ctx, range(ast, ctx.allSymbols), Diag(Diag.SpecNameMissing()));
		return none!(SpecInst*);
	}
}

FunFlags checkFunFlags(ref CheckCtx ctx, in Range range, CollectedFunFlags flags, bool isTest) {
	void warnRedundant(ModifierKeyword modifier, ModifierKeyword redundantModifier) {
		addDiag(ctx, range, Diag(Diag.ModifierRedundantDueToModifier(modifier, redundantModifier)));
	}

	bool builtin = (flags & CollectedFunFlags.builtin) != 0;
	bool extern_ = (flags & CollectedFunFlags.extern_) != 0;
	bool explicitBare = (flags & CollectedFunFlags.bare) != 0;
	bool forceCtx = (flags & CollectedFunFlags.forceCtx) != 0;
	bool summon = (flags & CollectedFunFlags.summon) != 0;
	bool trusted = (flags & CollectedFunFlags.trusted) != 0;
	bool explicitUnsafe = (flags & CollectedFunFlags.unsafe) != 0;

	bool implicitUnsafe = extern_;
	bool unsafe = explicitUnsafe || implicitUnsafe;
	bool implicitBare = extern_;
	bool bare = explicitBare || implicitBare;

	ModifierKeyword bodyModifier() =>
		builtin
			? ModifierKeyword.builtin
			: extern_
			? ModifierKeyword.extern_
			: assert(false);

	FunFlags.Safety safety = trusted
		? FunFlags.Safety.trusted
		: unsafe
		? FunFlags.Safety.unsafe
		: FunFlags.Safety.safe;
	if (implicitBare && explicitBare)
		warnRedundant(bodyModifier(), ModifierKeyword.bare);
	if (implicitUnsafe && explicitUnsafe)
		warnRedundant(bodyModifier(), ModifierKeyword.unsafe);
	if (trusted && !extern_ && !isTest)
		addDiag(ctx, range, Diag(Diag.FunModifierTrustedOnNonExtern()));
	FunFlags.SpecialBody specialBody = builtin
		? FunFlags.SpecialBody.builtin
		: extern_
		? FunFlags.SpecialBody.extern_
		: FunFlags.SpecialBody.none;
	if (builtin && extern_)
		addDiag(ctx, range, Diag(Diag.ModifierConflict(ModifierKeyword.builtin, ModifierKeyword.extern_)));
	if (explicitUnsafe && trusted)
		addDiag(ctx, range, Diag(Diag.ModifierConflict(ModifierKeyword.unsafe, ModifierKeyword.trusted)));
	return FunFlags.regular(bare, summon, safety, specialBody, forceCtx);
}

FunsAndMap checkFuns(
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	in SpecsMap specsMap,
	StructDecl[] structs,
	in StructsAndAliasesMap structsAndAliasesMap,
	VarDecl[] vars,
	ImportOrExportFile[] fileImports,
	ImportOrExportFile[] fileExports,
	FunDeclAst[] asts,
	TestAst[] testAsts,
) {
	FunDecl[] funs = checkFunsInitial(
		ctx, commonTypes, specsMap, structs, structsAndAliasesMap, vars, fileImports, fileExports, asts);
	FunsMap funsMap = buildFunsMap(ctx.alloc, funs);
	checkFunsWithAsts(ctx,commonTypes, structsAndAliasesMap, funsMap, funs[0 .. asts.length], asts);
	foreach (size_t i, ref ImportOrExportFile f; fileImports)
		funs[asts.length + i].body_ = getFileImportFunctionBody(f);
	foreach (size_t i, ref ImportOrExportFile f; fileExports)
		funs[asts.length + fileImports.length + i].body_ = getFileImportFunctionBody(f);
	return FunsAndMap(
		small!FunDecl(funs), checkTests(ctx, commonTypes, structsAndAliasesMap, funsMap, testAsts), funsMap);
}

FunDecl[] checkFunsInitial(
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	in SpecsMap specsMap,
	StructDecl[] structs,
	in StructsAndAliasesMap structsAndAliasesMap,
	VarDecl[] vars,
	ImportOrExportFile[] fileImports,
	ImportOrExportFile[] fileExports,
	FunDeclAst[] asts,
) =>
	buildArrayExact!FunDecl(
		ctx.alloc,
		asts.length + fileImports.length + fileExports.length +
			countFunsForStructs(commonTypes, structs) + countFunsForVars(vars),
		(scope ref ExactSizeArrayBuilder!FunDecl funsBuilder) @trusted {
			foreach (ref FunDeclAst funAst; asts) {
				FunDecl* fun = pushUninitialized(funsBuilder);
				checkTypeParams(ctx, funAst.typeParams);
				ReturnTypeAndParams rp = checkReturnTypeAndParams(
					ctx,
					commonTypes,
					TypeContainer(fun),
					funAst.returnType,
					funAst.params,
					funAst.typeParams,
					structsAndAliasesMap,
					noDelayStructInsts);
				FunFlagsAndSpecs flagsAndSpecs = checkFunModifiers(
					ctx, commonTypes, structsAndAliasesMap, specsMap,
					funAst.typeParams, nameRange(ctx.allSymbols, funAst), funAst.modifiers);
				initMemory(fun, FunDecl(
					FunDeclSource(FunDeclSource.Ast(ctx.curUri, &funAst)),
					visibilityFromExplicitTopLevel(funAst.visibility),
					funAst.name.name,
					rp.returnType,
					rp.params,
					flagsAndSpecs.flags,
					small!(immutable SpecInst*)(flagsAndSpecs.specs)));
			}
			foreach (ref ImportOrExportFile f; fileImports)
				funsBuilder ~= funDeclForFileImportOrExport(
					ctx, commonTypes, structsAndAliasesMap, f, Visibility.private_);
			foreach (ref ImportOrExportFile f; fileExports)
				funsBuilder ~= funDeclForFileImportOrExport(
					ctx, commonTypes, structsAndAliasesMap, f, Visibility.public_);

			foreach (ref StructDecl struct_; structs)
				addFunsForStruct(ctx, funsBuilder, commonTypes, &struct_);
			foreach (ref VarDecl var; vars)
				addFunsForVar(ctx, funsBuilder, commonTypes, &var);
		});

void checkFunsWithAsts(
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	in StructsAndAliasesMap structsAndAliasesMap,
	in FunsMap funsMap,
	FunDecl[] funsWithAsts,
	FunDeclAst[] asts,
) {
	zipPointers!(FunDecl, FunDeclAst)(funsWithAsts, asts, (FunDecl* fun, FunDeclAst* funAst) {
		Range diagRange = nameRange(ctx.allSymbols, *funAst);
		fun.body_ = () {
			final switch (fun.flags.specialBody) {
				case FunFlags.SpecialBody.none:
					if (funAst.body_.kind.isA!EmptyAst) {
						addDiag(ctx, diagRange, Diag(Diag.FunMissingBody()));
						return FunBody(FunBody.Bogus());
					} else
						return FunBody(getExprFunctionBody(
							ctx,
							commonTypes,
							structsAndAliasesMap,
							funsMap,
							fun,
							&funAst.body_));
				case FunFlags.SpecialBody.builtin:
					if (!funAst.body_.kind.isA!EmptyAst)
						addDiag(ctx, diagRange, Diag(Diag.FunCantHaveBody(Diag.FunCantHaveBody.Reason.builtin)));
					return getBuiltinFun(ctx, fun);
				case FunFlags.SpecialBody.extern_:
					if (!funAst.body_.kind.isA!EmptyAst)
						addDiag(ctx, diagRange, Diag(Diag.FunCantHaveBody(Diag.FunCantHaveBody.Reason.extern_)));
					return FunBody(checkExternBody(
						ctx, fun, funAst, getExternTypeArg(*funAst, ModifierKeyword.extern_)));
				case FunFlags.SpecialBody.generated:
					assert(false);
			}
		}();
	});
}

@trusted SmallArray!Test checkTests(
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	in StructsAndAliasesMap structsAndAliasesMap,
	in FunsMap funsMap,
	TestAst[] testAsts,
) =>
	small!Test(mapWithResultPointer!(Test, TestAst)(ctx.alloc, testAsts, (TestAst* ast, Test* out_) {
		FunFlags flags = checkTestModifiers(ctx, *ast);
		TestBody body_ = () {
			if (ast.body_.kind.isA!EmptyAst) {
				addDiag(ctx, ast.range, Diag(Diag.FunMissingBody()));
				return TestBody(Expr(&ast.body_, ExprKind(BogusExpr())));
			} else
				return checkTestBody(
					ctx, structsAndAliasesMap, commonTypes, funsMap, TypeContainer(out_), flags, &ast.body_);
		}();
		return Test(ast, ctx.curUri, flags, body_.body_, body_.type);
	}));

FunsMap buildFunsMap(ref Alloc alloc, in immutable FunDecl[] funs) {
	MutHashTable!(ArrayBuilder!(immutable FunDecl*), Symbol, funDeclsBuilderName) res;
	foreach (ref FunDecl fun; funs) {
		insertOrUpdate(
			alloc,
			res,
			fun.name,
			() {
				ArrayBuilder!(immutable FunDecl*) builder;
				add(alloc, builder, &fun);
				return builder;
			},
			(ref ArrayBuilder!(immutable FunDecl*) builder) {
				add(alloc, builder, &fun);
				return builder;
			});
	}
	return mapAndMovePreservingKeys!(
		immutable FunDecl*[], funDeclsName, ArrayBuilder!(immutable FunDecl*), Symbol, funDeclsBuilderName,
	)(alloc, res, (ref ArrayBuilder!(immutable FunDecl*) x) =>
		finish(alloc, x));
}
Symbol funDeclsBuilderName(in ArrayBuilder!(immutable FunDecl*) a) =>
	asTemporaryArray(a)[0].name;

Opt!TypeAst getExternTypeArg(ref FunDeclAst a, ModifierKeyword externOrGlobal) {
	foreach (ref ModifierAst modifier; a.modifiers) {
		Opt!(Opt!TypeAst) res = modifier.match!(Opt!(Opt!TypeAst))(
			(ModifierAst.Keyword x) =>
				x.kind == externOrGlobal ? some(none!TypeAst) : none!(Opt!TypeAst),
			(ModifierAst.Extern x) =>
				externOrGlobal == ModifierKeyword.extern_ ? some(some(*x.left)) : none!(Opt!TypeAst),
			(TypeAst x) =>
				none!(Opt!TypeAst));
		if (has(res))
			return force(res);
	}
	assert(false);
}

FunBody getFileImportFunctionBody(in ImportOrExportFile a) =>
	FunBody(FunBody.FileImport(a.source.kind.as!(ImportOrExportAstKind.File*).type, a.uri));

FunBody.ExpressionBody getExprFunctionBody(
	ref CheckCtx ctx,
	in CommonTypes commonTypes,
	in StructsAndAliasesMap structsAndAliasesMap,
	in FunsMap funsMap,
	FunDecl* f,
	ExprAst* e,
) =>
	FunBody.ExpressionBody(checkFunctionBody(
		ctx,
		structsAndAliasesMap,
		commonTypes,
		funsMap,
		TypeContainer(f),
		f.returnType,
		f.typeParams,
		paramsArray(f.params),
		f.specs,
		f.flags,
		e));

FunDecl funDeclForFileImportOrExport(
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	in StructsAndAliasesMap structsAndAliasesMap,
	ref ImportOrExportFile a,
	Visibility visibility,
) {
	ImportOrExportAstKind.File* ast = a.source.kind.as!(ImportOrExportAstKind.File*);
	return FunDecl(
		FunDeclSource(FunDeclSource.FileImport(ctx.curUri, a.source)),
		visibility,
		ast.name.name,
		typeForFileImport(ctx, commonTypes, structsAndAliasesMap, pathRange(ctx.allUris, *a.source), ast.type),
		Params([]),
		FunFlags.generatedBare,
		emptySmallArray!(immutable SpecInst*));
}

Type typeForFileImport(
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	in StructsAndAliasesMap structsAndAliasesMap,
	in Range range,
	ImportFileType type,
) {
	final switch (type) {
		case ImportFileType.nat8Array:
			TypeAst nat8 = TypeAst(NameAndRange(range.start, symbol!"nat8"));
			TypeAst.SuffixName suffixName = TypeAst.SuffixName(nat8, NameAndRange(range.start, symbol!"array"));
			scope TypeAst arrayNat8 = TypeAst(&suffixName);
			return typeFromAstNoTypeParamsNeverDelay(ctx, commonTypes, arrayNat8, structsAndAliasesMap);
		case ImportFileType.string:
			//TODO: this sort of duplicates 'getStrType'
			TypeAst ast = TypeAst(NameAndRange(range.start, symbol!"string"));
			return typeFromAstNoTypeParamsNeverDelay(ctx, commonTypes, ast, structsAndAliasesMap);
	}
}

FunBody.Extern checkExternBody(ref CheckCtx ctx, FunDecl* fun, FunDeclAst* ast, in Opt!TypeAst typeArg) {
	Linkage funLinkage = Linkage.extern_;

	checkNoTypeParams(ctx, fun.typeParams, DeclKind.externFunction);
	if (!isEmpty(fun.specs)) {
		Range range = mustFind!ModifierAst(ast.modifiers, (in ModifierAst x) => x.isA!TypeAst).range(ctx.allSymbols);
		addDiag(ctx, range, Diag(Diag.SpecUseInvalid(DeclKind.externFunction)));
	}

	if (!isLinkageAlwaysCompatible(funLinkage, linkageRange(fun.returnType)))
		addDiagAssertSameUri(ctx, fun.range, Diag(
			Diag.LinkageWorseThanContainingFun(fun, fun.returnType, none!(Destructure*))));
	fun.params.match!void(
		(Destructure[] params) {
			foreach (ref Destructure param; params)
				if (!isLinkageAlwaysCompatible(funLinkage, linkageRange(param.type)))
					addDiag(ctx, param.range(ctx.allSymbols), Diag(
						Diag.LinkageWorseThanContainingFun(fun, param.type, some(&param))));
		},
		(ref Params.Varargs x) {
			addDiag(ctx, x.param.range(ctx.allSymbols), Diag(Diag.ExternFunVariadic()));
		});
	return FunBody.Extern(externLibraryNameFromTypeArg(ctx, nameRange(ctx.allSymbols, *fun).range, typeArg));
}

Symbol externLibraryNameFromTypeArg(ref CheckCtx ctx, in Range range, in Opt!TypeAst typeArg) {
	if (has(typeArg) && force(typeArg).isA!NameAndRange)
		return force(typeArg).as!NameAndRange.name;
	else {
		addDiag(ctx, range, Diag(Diag.ExternMissingLibraryName()));
		return symbol!"";
	}
}

SpecsMap buildSpecsMap(ref CheckCtx ctx, SpecDecl[] specs) {
	MutHashTable!(immutable SpecDecl*, Symbol, specDeclName) builder;
	foreach (ref SpecDecl spec; specs)
		addToDeclsMap!(immutable SpecDecl*)(
			ctx, builder, &spec, Diag.DuplicateDeclaration.Kind.spec, (in SpecDecl* x) =>
				nameRange(ctx.allSymbols, *x));
	return moveToImmutable(builder);
}

Module* checkWorkerAfterCommonTypes(
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	ref StructsAndAliasesMap structsAndAliasesMap,
	StructAlias[] structAliases,
	StructDecl[] structs,
	scope ref DelayStructInsts delayStructInsts,
	Uri uri,
	ref ImportsAndReExports importsAndReExports,
	FileAst* ast,
) {
	checkStructBodies(ctx, commonTypes, structsAndAliasesMap, structs, ast.structs, delayStructInsts);

	while (!mutArrIsEmpty(delayStructInsts))
		instantiateStructTypes(ctx.instantiateCtx, mustPop(delayStructInsts), someMut(ptrTrustMe(delayStructInsts)));

	VarDecl[] vars = mapPointers(ctx.alloc, ast.vars, (VarDeclAst* ast) =>
		checkVarDecl(ctx, commonTypes, structsAndAliasesMap, ast));
	SpecDecl[] specs = checkSpecDeclsInitial(ctx, commonTypes, structsAndAliasesMap, ast.specs);
	SpecsMap specsMap = buildSpecsMap(ctx, specs);
	checkSpecBodies(ctx, commonTypes, structsAndAliasesMap, specsMap, ast.specs, specs);
	FunsAndMap funsAndMap = checkFuns(
		ctx,
		commonTypes,
		specsMap,
		structs,
		structsAndAliasesMap,
		vars,
		importsAndReExports.fileImports,
		importsAndReExports.fileExports,
		ast.funs,
		ast.tests);
	checkForUnused(ctx, structAliases, structs, specs, funsAndMap.funs);
	return allocate(ctx.alloc, Module(
		uri,
		ast,
		finishDiagnostics(ctx),
		importsAndReExports.moduleImports,
		importsAndReExports.moduleReExports,
		small!StructAlias(structAliases),
		small!StructDecl(structs),
		small!VarDecl(vars),
		small!SpecDecl(specs),
		funsAndMap.funs,
		funsAndMap.tests,
		getAllExports(
			ctx, importsAndReExports.moduleReExports, structsAndAliasesMap, specsMap, funsAndMap.funsMap)));
}

HashTable!(NameReferents, Symbol, nameFromNameReferents) getAllExports(
	ref CheckCtx ctx,
	in ImportOrExport[] reExports,
	in StructsAndAliasesMap structsAndAliasesMap,
	in SpecsMap specsMap,
	in FunsMap funsMap,
) {
	MutHashTable!(NameReferents, Symbol, nameFromNameReferents) res;

	void addExport(NameReferents toAdd, Range delegate() @safe @nogc pure nothrow range) {
		insertOrUpdate!(NameReferents, Symbol, nameFromNameReferents)(
			ctx.alloc,
			res,
			toAdd.name,
			() => toAdd,
			(ref NameReferents prev) {
				Opt!(Diag.DuplicateExports.Kind) kind = has(prev.structOrAlias) && has(toAdd.structOrAlias)
					? some(Diag.DuplicateExports.Kind.type)
					: has(prev.spec) && has(toAdd.spec)
					? some(Diag.DuplicateExports.Kind.spec)
					: none!(Diag.DuplicateExports.Kind);
				if (has(kind))
					addDiag(ctx, range(), Diag(Diag.DuplicateExports(force(kind), nameFromNameReferents(toAdd))));
				return NameReferents(
					has(prev.structOrAlias) ? prev.structOrAlias : toAdd.structOrAlias,
					has(prev.spec) ? prev.spec : toAdd.spec,
					concatenate(ctx.alloc, prev.funs, toAdd.funs));
			});
	}

	foreach (ref ImportOrExport e; reExports)
		e.kind.matchIn!void(
			(in ImportOrExportKind.ModuleWhole m) {
				// TODO: if this is a re-export of another library, only re-export the public members
				foreach (NameReferents referents; e.module_.exports)
					addExport(referents, () => pathRange(ctx.allUris, *force(e.source)));
			},
			(in Opt!(NameReferents*)[] referents) {
				foreach (Opt!(NameReferents*) x; referents)
					if (has(x))
						addExport(*force(x), () => pathRange(ctx.allUris, *force(e.source)));
			});
	foreach (StructOrAlias x; structsAndAliasesMap)
		final switch (x.visibility) {
			case Visibility.private_:
				break;
			case Visibility.internal:
			case Visibility.public_:
				addExport(NameReferents(some(x), none!(SpecDecl*), []), () => x.range.range);
				break;
		}
	foreach (immutable SpecDecl* x; specsMap)
		final switch (x.visibility) {
			case Visibility.private_:
				break;
			case Visibility.internal:
			case Visibility.public_:
				addExport(NameReferents(none!StructOrAlias, some(x), []), () => x.range.range);
				break;
		}
	foreach (immutable FunDecl*[] funs; funsMap) {
		immutable FunDecl*[] funDecls = filter!(immutable FunDecl*)(ctx.alloc, funs, (in immutable FunDecl* x) =>
			x.visibility != Visibility.private_);
		if (!isEmpty(funDecls))
			// Last argument doesn't matter because a function never results in a duplicate export error
			addExport(NameReferents(none!StructOrAlias, none!(SpecDecl*), funDecls), () => Range.empty);
	}

	return moveToImmutable(res);
}

BootstrapCheck checkWorker(
	ref Alloc alloc,
	scope ref Perf perf,
	scope ref AllSymbols allSymbols,
	in AllUris allUris,
	ref AllInsts allInsts,
	in CommonUris commonUris,
	in ResolvedImport[] resolvedImports,
	ref UriAndAst uriAndAst,
	in CommonTypes* delegate(
		ref CheckCtx,
		in StructsAndAliasesMap,
		scope ref DelayStructInsts,
	) @safe @nogc pure nothrow getCommonTypes,
) =>
	withMeasure!(BootstrapCheck, () {
		ArrayBuilder!Diagnostic diagsBuilder;
		ImportsAndReExports importsAndReExports = checkImportsAndReExports(
			alloc, allSymbols, allUris, diagsBuilder, uriAndAst.ast, resolvedImports);
		FileAst* ast = uriAndAst.ast;
		CheckCtx ctx = CheckCtx(
			ptrTrustMe(alloc),
			ptrTrustMe(allSymbols),
			ptrTrustMe(allUris),
			InstantiateCtx(ptrTrustMe(perf), ptrTrustMe(allInsts)),
			ptrTrustMe(commonUris),
			uriAndAst.uri,
			importsAndReExports.modules,
			ptrTrustMe(diagsBuilder));

		// Since structs may refer to each other, first get a structsAndAliasesMap, *then* fill in bodies
		StructDecl[] structs = checkStructsInitial(ctx, ast.structs);
		StructAlias[] structAliases = checkStructAliasesInitial(ctx, ast.structAliases);
		StructsAndAliasesMap structsAndAliasesMap = buildStructsAndAliasesMap(ctx, structs, structAliases);

		// We need to create StructInsts when filling in struct bodies.
		// But when creating a StructInst, we usually want to fill in its body.
		// In case the decl body isn't available yet,
		// we'll delay creating the StructInst body, which isn't needed until expr checking.
		DelayStructInsts delayStructInsts = DelayStructInsts(ctx.allocPtr);

		CommonTypes* commonTypes = getCommonTypes(ctx, structsAndAliasesMap, delayStructInsts);

		checkStructAliasTargets(
			ctx,
			*commonTypes,
			structsAndAliasesMap,
			structAliases,
			ast.structAliases,
			delayStructInsts);

		Module* res = checkWorkerAfterCommonTypes(
			ctx,
			*commonTypes,
			structsAndAliasesMap,
			structAliases,
			structs,
			delayStructInsts,
			uriAndAst.uri,
			importsAndReExports,
			ast);
		return BootstrapCheck(res, commonTypes);
	})(perf, alloc, PerfMeasure.check);

immutable struct ImportsAndReExports {
	@safe @nogc pure nothrow:

	SmallArray!ImportOrExport moduleImports;
	SmallArray!ImportOrExport moduleReExports;
	SmallArray!ImportOrExportFile fileImports;
	SmallArray!ImportOrExportFile fileExports;

	ImportAndReExportModules modules() =>
		ImportAndReExportModules(moduleImports, moduleReExports);
}
immutable struct ImportOrExportFile {
	ImportOrExportAst* source;
	Uri uri;
}

ImportsAndReExports checkImportsAndReExports(
	ref Alloc alloc,
	in AllSymbols allSymbols,
	in AllUris allUris,
	scope ref ArrayBuilder!Diagnostic diagsBuilder,
	FileAst* ast,
	in ResolvedImport[] resolvedImports,
) {
	scope ResolvedImport[] resolvedImportsLeft = resolvedImports;
	ImportsOrReExports imports = checkImportsOrReExports(
		alloc, allSymbols, allUris, diagsBuilder, ast.imports, resolvedImportsLeft, !ast.noStd);
	ImportsOrReExports reExports = checkImportsOrReExports(
		alloc, allSymbols, allUris, diagsBuilder, ast.reExports, resolvedImportsLeft, false);
	assert(isEmpty(resolvedImportsLeft));
	return ImportsAndReExports(imports.modules, reExports.modules, imports.files, reExports.files);
}

struct ImportsOrReExports {
	SmallArray!ImportOrExport modules;
	SmallArray!ImportOrExportFile files;
}
ImportsOrReExports checkImportsOrReExports(
	ref Alloc alloc,
	in AllSymbols allSymbols,
	in AllUris allUris,
	scope ref ArrayBuilder!Diagnostic diagsBuilder,
	in Opt!ImportsOrExportsAst ast,
	scope ref ResolvedImport[] resolvedImports,
	bool includeStd,
) {
	ArrayBuilder!ImportOrExport imports;
	ArrayBuilder!ImportOrExportFile fileImports;

	ResolvedImport nextResolvedImport() {
		ResolvedImport res = resolvedImports[0];
		resolvedImports = resolvedImports[1 .. $];
		return res;
	}

	void handleModuleImport(
		Opt!(ImportOrExportAst*) source,
		ExportVisibility minVisibility,
		ImportOrExportKind delegate(Module*) @safe @nogc pure nothrow cb,
	) {
		nextResolvedImport().matchWithPointers!void(
			(Module* x) {
				add(alloc, imports, ImportOrExport(source, x, minVisibility, cb(x)));
			},
			(FileContent) {
				assert(false);
			},
			(Diag.ImportFileDiag* x) {
				add(alloc, diagsBuilder, Diagnostic(
					has(source) ? pathRange(allUris, *force(source)) : Range.empty,
					Diag(x)));
			});
	}

	if (includeStd)
		handleModuleImport(none!(ImportOrExportAst*), ExportVisibility.public_, (Module*) =>
			ImportOrExportKind(ImportOrExportKind.ModuleWhole()));

	if (has(ast))
		foreach (ref ImportOrExportAst importAst; force(ast).paths) {
			ExportVisibility importVisibility = importMinVisibility(importAst);
			importAst.kind.match!void(
				(ImportOrExportAstKind.ModuleWhole) {
					handleModuleImport(some(&importAst), importVisibility, (Module*) =>
						ImportOrExportKind(ImportOrExportKind.ModuleWhole()));
				},
				(NameAndRange[] names) {
					handleModuleImport(some(&importAst), importVisibility, (Module* module_) =>
						ImportOrExportKind(
							checkNamedImports(alloc, allSymbols, diagsBuilder, importVisibility, module_, names)));
				},
				(ref ImportOrExportAstKind.File x) {
					nextResolvedImport().matchWithPointers!void(
						(Module*) {
							assert(false);
						},
						(Uri x) {
							add(alloc, fileImports, ImportOrExportFile(&importAst, x));
						},
						(Diag.ImportFileDiag* x) {
							add(alloc, diagsBuilder, Diagnostic(pathRange(allUris, importAst), Diag(x)));
						});
				});
		}
	return ImportsOrReExports(smallFinish(alloc, imports), smallFinish(alloc, fileImports));
}

ExportVisibility importMinVisibility(in ImportOrExportAst a) =>
	a.path.matchIn!ExportVisibility(
		(in Path _) => ExportVisibility.public_,
		(in RelPath _) => ExportVisibility.internal);

Opt!(NameReferents*)[] checkNamedImports(
	ref Alloc alloc,
	in AllSymbols allSymbols,
	scope ref ArrayBuilder!Diagnostic diagsBuilder,
	ExportVisibility importVisibility,
	Module* module_,
	in NameAndRange[] names,
) =>
	map(alloc, names, (ref NameAndRange name) {
		Opt!(NameReferents*) referents = getPointer!(NameReferents, Symbol, nameFromNameReferents)(
			module_.exports, name.name);
		if (!has(referents) || !hasVisibility(*force(referents), importVisibility))
			add(alloc, diagsBuilder, Diagnostic(
				rangeOfNameAndRange(name, allSymbols),
				Diag(Diag.ImportRefersToNothing(name.name))));
		return referents;
	});

bool hasVisibility(in NameReferents a, ExportVisibility visibility) =>
	(has(a.structOrAlias) && importCanSee(visibility, force(a.structOrAlias).visibility)) ||
	(has(a.spec) && importCanSee(visibility, force(a.spec).visibility)) ||
	exists(a.funs, (in FunDecl* x) =>
		importCanSee(visibility, x.visibility));
