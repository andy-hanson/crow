module frontend.check.check;

@safe @nogc pure nothrow:

import frontend.check.checkCtx :
	addDiag, CheckCtx, checkForUnused, finishDiagnostics, ImportAndReExportModules, rangeInFile;
import frontend.check.checkExpr : checkFunctionBody;
import frontend.check.checkStructs : checkStructBodies, checkStructsInitial;
import frontend.check.getCommonTypes : getCommonTypes;
import frontend.check.maps : funDeclsName, FunsMap, specDeclName, SpecsMap, StructsAndAliasesMap;
import frontend.check.funsForStruct : addFunsForStruct, addFunsForVar, countFunsForStructs, countFunsForVars;
import frontend.check.instantiate :
	DelaySpecInsts,
	DelayStructInsts,
	MayDelaySpecInsts,
	MayDelayStructInsts,
	InstantiateCtx,
	instantiateSpecParents,
	instantiateStructTypes,
	noDelaySpecInsts,
	noDelayStructInsts;
import frontend.check.typeFromAst :
	checkDestructure, checkTypeParams, specFromAst, typeFromAst, typeFromAstNoTypeParamsNeverDelay;
import frontend.parse.ast :
	DestructureAst,
	ExplicitVisibility,
	ExprAst,
	FileAst,
	FunDeclAst,
	FunModifierAst,
	ImportOrExportAstKind,
	ImportsOrExportsAst,
	ImportOrExportAst,
	NameAndRange,
	ParamsAst,
	pathRange,
	range,
	SpecBodyAst,
	SpecDeclAst,
	SpecSigAst,
	StructAliasAst,
	TestAst,
	TypeAst,
	VarDeclAst;
import frontend.programState : ProgramState;
import frontend.storage : FileContent;
import model.diag : Diag, Diagnostic, TypeContainer;
import model.model :
	body_,
	CommonTypes,
	Destructure,
	emptyTypeParams,
	FunBody,
	FunDecl,
	FunDeclSource,
	FunFlags,
	ImportFileType,
	ImportOrExport,
	ImportOrExportKind,
	isLinkageAlwaysCompatible,
	Linkage,
	linkageRange,
	Module,
	name,
	nameFromNameReferents,
	NameReferents,
	Params,
	paramsArray,
	range,
	setBody,
	setTarget,
	SpecDecl,
	SpecDeclBody,
	SpecDeclSig,
	SpecInst,
	StructAlias,
	StructDecl,
	StructInst,
	StructOrAlias,
	structOrAliasName,
	target,
	Test,
	Type,
	typeArgs,
	TypeParamIndex,
	TypeParams,
	typeParams,
	VarDecl,
	Visibility,
	visibility;
import util.alloc.alloc : Alloc;
import util.cell : Cell, cellGet, cellSet;
import util.col.arr : empty, emptySmallArray, only, ptrsRange, small;
import util.col.arrBuilder : add, ArrBuilder, arrBuilderTempAsArr, finishArr;
import util.col.arrUtil : concatenate, filter, map, mapOp, mapPointers, mapToMut, mapWithResultPointer,sum, zip, zipPointers;
import util.col.exactSizeArrBuilder : buildArrayExact, ExactSizeArrBuilder, pushUninitialized;
import util.col.hashTable : HashTable, insertOrUpdate, mapAndMovePreservingKeys, mayAdd, moveToImmutable, MutHashTable;
import util.col.mutArr : mustPop, mutArrIsEmpty;
import util.col.mutMaxArr : isFull, mustPop, MutMaxArr, mutMaxArr, mutMaxArrSize, push, pushIfUnderMaxSize, toArray;
import util.col.str : copySafeCStr;
import util.memory : allocate, initMemory;
import util.opt : force, has, none, Opt, someMut, some;
import util.perf : Perf, PerfMeasure, withMeasure;
import util.ptr : ptrTrustMe;
import util.sourceRange : Range, UriAndRange;
import util.sym : AllSymbols, Sym, sym;
import util.union_ : Union;
import util.uri : AllUris, Uri;
import util.util : unreachable, todo;

immutable struct FileAndAst {
	Uri uri;
	FileAst* ast;
}

immutable struct ResolvedImport {
	// Uri is for a file import
	mixin Union!(Module*, Uri, Diag.ImportFileDiag);
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
	ref ProgramState programState,
	ref FileAndAst fileAndAst,
) =>
	checkWorker(
		alloc,
		perf,
		allSymbols,
		allUris,
		programState,
		[],
		fileAndAst,
		(ref CheckCtx ctx,
		in StructsAndAliasesMap structsAndAliasesMap,
		scope ref DelayStructInsts delayedStructInsts) =>
			getCommonTypes(ctx, structsAndAliasesMap, delayedStructInsts));

Module* check(
	scope ref Perf perf,
	ref Alloc alloc,
	scope ref AllSymbols allSymbols,
	in AllUris allUris,
	ref ProgramState programState,
	ref FileAndAst fileAndAst,
	in ResolvedImport[] imports,
	CommonTypes* commonTypes,
) =>
	checkWorker(
		alloc,
		perf,
		allSymbols,
		allUris,
		programState,
		imports,
		fileAndAst,
		(ref CheckCtx _, in StructsAndAliasesMap _2, scope ref DelayStructInsts _3) => commonTypes,
	).module_;

Visibility visibilityFromExplicit(ExplicitVisibility a) {
	final switch (a) {
		case ExplicitVisibility.default_:
			return Visibility.internal;
		case ExplicitVisibility.private_:
			return Visibility.private_;
		case ExplicitVisibility.internal:
			return Visibility.internal;
		case ExplicitVisibility.public_:
			return Visibility.public_;
	}
}

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
				ctx, commonTypes, structsAndAliasesMap, typeContainer, typeParamsScope, delayStructInsts, varargs.param, none!Type);
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

SpecDeclBody.Builtin.Kind getSpecBodyBuiltinKind(ref CheckCtx ctx, in Range range, Sym name) {
	switch (name.value) {
		case sym!"data".value:
			return SpecDeclBody.Builtin.Kind.data;
		case sym!"shared".value:
			return SpecDeclBody.Builtin.Kind.shared_;
		default:
			addDiag(ctx, range, Diag(Diag.BuiltinUnsupported(name)));
			return SpecDeclBody.Builtin.Kind.data;
	}
}

SpecDeclBody checkSpecDeclBody(
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	TypeContainer typeContainer,
	TypeParams typeParams,
	in StructsAndAliasesMap structsAndAliasesMap,
	in Range range,
	Sym name,
	SpecBodyAst ast,
) =>
	ast.match!SpecDeclBody(
		(SpecBodyAst.Builtin) =>
			SpecDeclBody(SpecDeclBody.Builtin(getSpecBodyBuiltinKind(ctx, range, name))),
		(SpecSigAst[] sigs) =>
			SpecDeclBody(mapPointers(ctx.alloc, sigs, (SpecSigAst* x) {
				ReturnTypeAndParams rp = checkReturnTypeAndParams(
					ctx, commonTypes, typeContainer, x.returnType, x.params, typeParams, structsAndAliasesMap, noDelayStructInsts);
				Destructure[] params = rp.params.match!(Destructure[])(
					(Destructure[] x) =>
						x,
					(ref Params.Varargs _) =>
						todo!(Destructure[])("diag: no varargs in spec"));
				return SpecDeclSig(ctx.curUri, x, x.name, rp.returnType, small(params));
			})));

@trusted SpecDecl[] checkSpecDeclsInitial(
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	ref StructsAndAliasesMap structsAndAliasesMap,
	SpecDeclAst[] asts,
) =>
	mapWithResultPointer!(SpecDecl, SpecDeclAst)(ctx.alloc, asts, (SpecDeclAst* ast, SpecDecl* out_) {
		checkTypeParams(ctx, ast.typeParams);
		SpecDeclBody body_ =
			checkSpecDeclBody(ctx, commonTypes, TypeContainer(out_), ast.typeParams, structsAndAliasesMap, ast.range, ast.name.name, ast.body_);
		return SpecDecl(ctx.curUri, ast, visibilityFromExplicit(ast.visibility), ast.name.name, body_);
	});

void checkSpecDeclParents(
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	ref StructsAndAliasesMap structsAndAliasesMap,
	ref SpecsMap specsMap,
	in SpecDeclAst[] asts,
	SpecDecl[] specs,
) {
	DelaySpecInsts delaySpecInsts = DelaySpecInsts(ctx.allocPtr);

	zip!(SpecDeclAst, SpecDecl)(asts, specs, (ref SpecDeclAst ast, ref SpecDecl spec) {
		spec.parents = mapOp!(immutable SpecInst*, TypeAst)(ctx.alloc, ast.parents, (ref TypeAst parent) =>
			checkFunModifierNonSpecial(
				ctx, commonTypes, structsAndAliasesMap, specsMap, ast.typeParams, parent,
				someMut(ptrTrustMe(delaySpecInsts))));
	});

	foreach (SpecDecl* decl; ptrsRange(specs))
		detectAndFixSpecRecursion(ctx, decl);

	while (!mutArrIsEmpty(delaySpecInsts))
		instantiateSpecParents(ctx.instantiateCtx, mustPop(delaySpecInsts), someMut(&delaySpecInsts));
}

void detectAndFixSpecRecursion(ref CheckCtx ctx, SpecDecl* decl) {
	MutMaxArr!(8, immutable SpecDecl*) trace = mutMaxArr!(8, immutable SpecDecl*);
	if (recurDetectSpecRecursion(decl, trace)) {
		addDiag(ctx, range(*decl), Diag(Diag.SpecRecursion(toArray(ctx.alloc, trace))));
		decl.overwriteParentsToEmpty();
	}
}
bool recurDetectSpecRecursion(SpecDecl* cur, ref MutMaxArr!(8, immutable SpecDecl*) trace) {
	if (!empty(cur.parents) && isFull(trace))
		return true;
	foreach (SpecInst* parent; cur.parents) {
		push(trace, parent.decl);
		if (recurDetectSpecRecursion(parent.decl, trace))
			return true;
		else
			mustPop(trace);
	}
	return false;
}

StructAlias[] checkStructAliasesInitial(ref CheckCtx ctx, scope StructAliasAst[] asts) =>
	mapToMut!(StructAlias, StructAliasAst)(ctx.alloc, asts, (ref StructAliasAst ast) {
		checkTypeParams(ctx, ast.typeParams);
		return StructAlias(
			rangeInFile(ctx, ast.range),
			copySafeCStr(ctx.alloc, ast.docComment),
			visibilityFromExplicit(ast.visibility),
			ast.name.name);
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
		if (type.isA!(StructInst*))
			setTarget(structAlias, some(type.as!(StructInst*)));
		else {
			if (!type.isA!(Type.Bogus))
				todo!void("diagnostic -- alias does not resolve to struct (must be bogus or a type parameter)");
			setTarget(structAlias, none!(StructInst*));
		}
	});
}

StructsAndAliasesMap buildStructsAndAliasesMap(ref CheckCtx ctx, StructDecl[] structs, StructAlias[] aliases) {
	MutHashTable!(StructOrAlias, Sym, structOrAliasName) builder;
	foreach (StructDecl* decl; ptrsRange(structs))
		addToDeclsMap!StructOrAlias(
			ctx, builder, StructOrAlias(decl), Diag.DuplicateDeclaration.Kind.structOrAlias, () => range(*decl));
	foreach (StructAlias* alias_; ptrsRange(aliases))
		addToDeclsMap!StructOrAlias(
			ctx, builder, StructOrAlias(alias_), Diag.DuplicateDeclaration.Kind.structOrAlias, () => range(*alias_));
	return moveToImmutable(builder);
}

VarDecl checkVarDecl(
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	in StructsAndAliasesMap structsAndAliasesMap,
	VarDeclAst* ast,
) {
	if (!empty(ast.typeParams))
		todo!void("diag");
	return VarDecl(
		ast,
		ctx.curUri,
		visibilityFromExplicit(ast.visibility),
		ast.name.name,
		ast.kind,
		typeFromAstNoTypeParamsNeverDelay(ctx, commonTypes, ast.type, structsAndAliasesMap),
		checkVarModifiers(ctx, ast.modifiers));
}

Opt!Sym checkVarModifiers(ref CheckCtx ctx, in FunModifierAst[] modifiers) {
	Cell!(Opt!Sym) externLibraryName;
	foreach (ref FunModifierAst modifier; modifiers) {
		modifier.matchIn!void(
			(in FunModifierAst.Special x) {
				if (x.flag == FunModifierAst.Special.Flags.extern_)
					todo!void("diag: 'extern' missing library name");
				else
					todo!void("diag: unsupported modifier");
			},
			(in FunModifierAst.Extern x) {
				if (has(cellGet(externLibraryName)))
					todo!void("diag: duplicate modifier");
				cellSet(externLibraryName, some(
					externLibraryNameFromTypeArg(ctx, x.suffixRange(ctx.allSymbols), some(*x.left))));
			},
			(in TypeAst _) {
				todo!void("diag: unsupported modifier");
			});
	}
	return cellGet(externLibraryName);
}

void addToDeclsMap(T, alias getName)(
	ref CheckCtx ctx,
	scope ref MutHashTable!(T, Sym, getName) builder,
	T added,
	Diag.DuplicateDeclaration.Kind kind,
	in UriAndRange delegate() @safe @nogc pure nothrow getRange,
) {
	if (!mayAdd(ctx.alloc, builder, added))
		addDiag(ctx, getRange(), Diag(Diag.DuplicateDeclaration(kind, getName(added))));
}

immutable struct FunsAndMap {
	FunDecl[] funs;
	Test[] tests;
	FunsMap funsMap;
}

immutable struct FunFlagsAndSpecs {
	FunFlags flags;
	SpecInst*[] specs;
}

FunFlagsAndSpecs checkFunModifiers(
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	in Range range,
	in FunModifierAst[] asts,
	in StructsAndAliasesMap structsAndAliasesMap,
	in SpecsMap specsMap,
	TypeParams typeParamsScope,
) {
	FunModifierAst.Special.Flags allFlags = FunModifierAst.Special.Flags.none;
	immutable SpecInst*[] specs =
		mapOp!(immutable SpecInst*, FunModifierAst)(ctx.alloc, asts, (scope ref FunModifierAst ast) =>
			ast.matchIn!(Opt!(SpecInst*))(
				(in FunModifierAst.Special flag) {
					if (allFlags & flag.flag)
						todo!void("diag: duplicate flag");
					allFlags |= flag.flag;
					return none!(SpecInst*);
				},
				(in FunModifierAst.Extern x) {
					if (allFlags & FunModifierAst.Special.Flags.extern_)
						todo!void("diag: duplicate flag");
					allFlags |= FunModifierAst.Special.Flags.extern_;
					return none!(SpecInst*);
				},
				(in TypeAst x) =>
					checkFunModifierNonSpecial(
						ctx, commonTypes, structsAndAliasesMap, specsMap, typeParamsScope, x, noDelaySpecInsts)));
	return FunFlagsAndSpecs(checkFunFlags(ctx, range, allFlags), specs);
}

Opt!(SpecInst*) checkFunModifierNonSpecial(
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	in StructsAndAliasesMap structsAndAliasesMap,
	in SpecsMap specsMap,
	TypeParams typeParamsScope,
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

FunFlags checkFunFlags(ref CheckCtx ctx, in Range range, FunModifierAst.Special.Flags flags) {
	void warnRedundant(Sym modifier, Sym redundantModifier) {
		addDiag(ctx, range, Diag(Diag.ModifierRedundantDueToModifier(modifier, redundantModifier)));
	}

	bool builtin = (flags & FunModifierAst.Special.Flags.builtin) != 0;
	bool extern_ = (flags & FunModifierAst.Special.Flags.extern_) != 0;
	bool explicitBare = (flags & FunModifierAst.Special.Flags.bare) != 0;
	bool forceCtx = (flags & FunModifierAst.Special.Flags.forceCtx) != 0;
	bool summon = (flags & FunModifierAst.Special.Flags.summon) != 0;
	bool trusted = (flags & FunModifierAst.Special.Flags.trusted) != 0;
	bool explicitUnsafe = (flags & FunModifierAst.Special.Flags.unsafe) != 0;

	bool implicitUnsafe = extern_;
	bool unsafe = explicitUnsafe || implicitUnsafe;
	bool implicitBare = extern_;
	bool bare = explicitBare || implicitBare;

	Sym bodyModifier() {
		return builtin
			? sym!"builtin"
			: extern_
			? sym!"extern"
			: unreachable!Sym;
	}

	FunFlags.Safety safety = !unsafe
		? FunFlags.Safety.safe
		: trusted
		? FunFlags.Safety.safe
		: FunFlags.Safety.unsafe;
	if (implicitBare && explicitBare)
		warnRedundant(bodyModifier(), sym!"bare");
	if (implicitUnsafe && explicitUnsafe)
		warnRedundant(bodyModifier(), sym!"unsafe");
	if (trusted && !extern_)
		addDiag(ctx, range, Diag(Diag.FunModifierTrustedOnNonExtern()));
	FunFlags.SpecialBody specialBody = builtin
		? FunFlags.SpecialBody.builtin
		: extern_
		? FunFlags.SpecialBody.extern_
		: FunFlags.SpecialBody.none;
	if (builtin + extern_ > 1) {
		MutMaxArr!(2, Sym) bodyModifiers = mutMaxArr!(2, Sym);
		if (builtin) pushIfUnderMaxSize(bodyModifiers, sym!"builtin");
		if (extern_) pushIfUnderMaxSize(bodyModifiers, sym!"extern");
		assert(mutMaxArrSize(bodyModifiers) == 2);
		addDiag(ctx, range, Diag(Diag.ModifierConflict(bodyModifiers[0], bodyModifiers[1])));
	}
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
	in FunDeclAst[] asts,
	in TestAst[] testAsts,
) {
	FunDecl[] funs = buildArrayExact!FunDecl(
		ctx.alloc,
		asts.length + fileImports.length + fileExports.length + countFunsForStructs(structs) + countFunsForVars(vars),
		(scope ref ExactSizeArrBuilder!FunDecl funsBuilder) @trusted {
			foreach (FunDeclAst* funAst; ptrsRange(asts)) {
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
					ctx, commonTypes, funAst.range, funAst.modifiers, structsAndAliasesMap, specsMap, funAst.typeParams);
				initMemory(fun, FunDecl(
					FunDeclSource(FunDeclSource.Ast(ctx.curUri, funAst)),
					visibilityFromExplicit(funAst.visibility),
					funAst.name.name,
					rp.returnType,
					rp.params,
					flagsAndSpecs.flags,
					small(flagsAndSpecs.specs)));
			}
			foreach (ref ImportOrExportFile f; fileImports)
				funsBuilder ~= funDeclForFileImportOrExport(
					ctx, commonTypes, structsAndAliasesMap, f, Visibility.private_);
			foreach (ref ImportOrExportFile f; fileExports)
				funsBuilder ~= funDeclForFileImportOrExport(
					ctx, commonTypes, structsAndAliasesMap, f, Visibility.public_);

			foreach (StructDecl* struct_; ptrsRange(structs))
				addFunsForStruct(ctx, funsBuilder, commonTypes, struct_);
			foreach (VarDecl* var; ptrsRange(vars))
				addFunsForVar(ctx, funsBuilder, commonTypes, var);
		});

	FunsMap funsMap = buildFunsMap(ctx.alloc, funs);

	FunDecl[] funsWithAsts = funs[0 .. asts.length];
	zipPointers!(FunDecl, FunDeclAst)(funsWithAsts, asts, (FunDecl* fun, FunDeclAst* funAst) {
		fun.setBody(() {
			final switch (fun.flags.specialBody) {
				case FunFlags.SpecialBody.none:
					if (!has(funAst.body_)) {
						addDiag(ctx, funAst.range, Diag(Diag.FunMissingBody()));
						return FunBody(FunBody.Bogus());
					} else
						return FunBody(getExprFunctionBody(
							ctx,
							commonTypes,
							structsAndAliasesMap,
							funsMap,
							fun,
							&force(funAst.body_)));
				case FunFlags.SpecialBody.builtin:
				case FunFlags.SpecialBody.generated:
					if (has(funAst.body_))
						todo!void("diag: builtin fun can't have body");
					return FunBody(FunBody.Builtin());
				case FunFlags.SpecialBody.extern_:
					if (has(funAst.body_))
						todo!void("diag: builtin fun can't have body");
					return FunBody(checkExternBody(
						ctx, fun, getExternTypeArg(*funAst, FunModifierAst.Special.Flags.extern_)));
			}
		}());
	});
	foreach (size_t i, ref ImportOrExportFile f; fileImports)
		funs[asts.length + i].setBody(getFileImportFunctionBody(f));
	foreach (size_t i, ref ImportOrExportFile f; fileExports)
		funs[asts.length + fileImports.length + i].setBody(getFileImportFunctionBody(f));

	Test[] tests = () @trusted {
		return mapWithResultPointer!(Test, TestAst)(ctx.alloc, testAsts, (TestAst* ast, Test* out_) {
			Type voidType = Type(commonTypes.void_);
			if (!has(ast.body_))
				todo!void("diag: test needs body");
			return Test(ctx.curUri, checkFunctionBody(
				ctx,
				structsAndAliasesMap,
				commonTypes,
				funsMap,
				TypeContainer(out_),
				voidType,
				sym!"test",
				emptyTypeParams,
				[],
				[],
				FunFlags.none.withSummon,
				&force(ast.body_)));
		});
	}();

	return FunsAndMap(funs, tests, funsMap);
}

FunsMap buildFunsMap(ref Alloc alloc, in immutable FunDecl[] funs) {
	MutHashTable!(ArrBuilder!(immutable FunDecl*), Sym, funDeclsBuilderName) res;
	foreach (FunDecl* fun; ptrsRange(funs)) {
		insertOrUpdate(
			alloc,
			res,
			fun.name,
			() {
				ArrBuilder!(immutable FunDecl*) builder;
				add(alloc, builder, fun);
				return builder;
			},
			(ref ArrBuilder!(immutable FunDecl*) builder) {
				add(alloc, builder, fun);
				return builder;
			});
	}
	return mapAndMovePreservingKeys!(
		immutable FunDecl*[], funDeclsName, ArrBuilder!(immutable FunDecl*), Sym, funDeclsBuilderName,
	)(alloc, res, (ref ArrBuilder!(immutable FunDecl*) x) =>
		finishArr(alloc, x));
}
Sym funDeclsBuilderName(in ArrBuilder!(immutable FunDecl*) a) =>
	arrBuilderTempAsArr(a)[0].name;

Opt!TypeAst getExternTypeArg(ref FunDeclAst a, FunModifierAst.Special.Flags externOrGlobalFlag) {
	foreach (ref FunModifierAst modifier; a.modifiers) {
		Opt!(Opt!TypeAst) res = modifier.match!(Opt!(Opt!TypeAst))(
			(FunModifierAst.Special x) =>
				x.flag == externOrGlobalFlag ? some(none!TypeAst) : none!(Opt!TypeAst),
			(FunModifierAst.Extern x) =>
				externOrGlobalFlag == FunModifierAst.Special.Flags.extern_ ? some(some(*x.left)) : none!(Opt!TypeAst),
			(TypeAst x) =>
				none!(Opt!TypeAst));
		if (has(res))
			return force(res);
	}
	return unreachable!(Opt!TypeAst);
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
		f.name,
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
			TypeAst nat8 = TypeAst(NameAndRange(range.start, sym!"nat8"));
			TypeAst.SuffixName suffixName = TypeAst.SuffixName(nat8, NameAndRange(range.start, sym!"array"));
			scope TypeAst arrayNat8 = TypeAst(&suffixName);
			return typeFromAstNoTypeParamsNeverDelay(ctx, commonTypes, arrayNat8, structsAndAliasesMap);
		case ImportFileType.string:
			//TODO: this sort of duplicates 'getStrType'
			TypeAst ast = TypeAst(NameAndRange(range.start, sym!"string"));
			return typeFromAstNoTypeParamsNeverDelay(ctx, commonTypes, ast, structsAndAliasesMap);
	}
}

FunBody.Extern checkExternBody(ref CheckCtx ctx, FunDecl* fun, in Opt!TypeAst typeArg) {
	Linkage funLinkage = Linkage.extern_;

	if (!empty(fun.typeParams))
		addDiag(ctx, range(*fun), Diag(Diag.ExternFunForbidden(fun, Diag.ExternFunForbidden.Reason.hasTypeParams)));
	if (!empty(fun.specs))
		addDiag(ctx, range(*fun), Diag(Diag.ExternFunForbidden(fun, Diag.ExternFunForbidden.Reason.hasSpecs)));

	if (!isLinkageAlwaysCompatible(funLinkage, linkageRange(fun.returnType)))
		addDiag(ctx, range(*fun), Diag(Diag.LinkageWorseThanContainingFun(fun, fun.returnType, none!(Destructure*))));
	fun.params.match!void(
		(Destructure[] params) {
			foreach (Destructure* p; ptrsRange(params))
				if (!isLinkageAlwaysCompatible(funLinkage, linkageRange(p.type)))
					addDiag(ctx, p.range(ctx.allSymbols), Diag(
						Diag.LinkageWorseThanContainingFun(fun, p.type, some(p))));
		},
		(ref Params.Varargs) {
			addDiag(ctx, range(*fun), Diag(Diag.ExternFunForbidden(fun, Diag.ExternFunForbidden.Reason.variadic)));
		});
	return FunBody.Extern(externLibraryNameFromTypeArg(ctx, range(*fun).range, typeArg));
}

Sym externLibraryNameFromTypeArg(ref CheckCtx ctx, in Range range, in Opt!TypeAst typeArg) {
	if (has(typeArg) && force(typeArg).isA!NameAndRange)
		return force(typeArg).as!NameAndRange.name;
	else {
		addDiag(ctx, range, Diag(Diag.ExternMissingLibraryName()));
		return sym!"bogus";
	}
}

SpecsMap buildSpecsMap(ref CheckCtx ctx, SpecDecl[] specs) {
	MutHashTable!(immutable SpecDecl*, Sym, specDeclName) builder;
	foreach (SpecDecl* spec; ptrsRange(specs))
		addToDeclsMap(ctx, builder, spec, Diag.DuplicateDeclaration.Kind.spec, () => range(*spec));
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
	checkSpecDeclParents(ctx, commonTypes, structsAndAliasesMap, specsMap, ast.specs, specs);
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
		structs, vars, specs, funsAndMap.funs, funsAndMap.tests,
		getAllExportedNames(
			ctx, importsAndReExports.moduleReExports, structsAndAliasesMap, specsMap, funsAndMap.funsMap)));
}

HashTable!(NameReferents, Sym, nameFromNameReferents) getAllExportedNames(
	ref CheckCtx ctx,
	in ImportOrExport[] reExports,
	in StructsAndAliasesMap structsAndAliasesMap,
	in SpecsMap specsMap,
	in FunsMap funsMap,
) {
	MutHashTable!(NameReferents, Sym, nameFromNameReferents) res;
	void addExport(NameReferents toAdd, Range delegate() @safe @nogc pure nothrow range) {
		insertOrUpdate!(NameReferents, Sym, nameFromNameReferents)(
			ctx.alloc,
			res,
			nameFromNameReferents(toAdd),
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
				foreach (NameReferents referents; m.module_.allExportedNames)
					addExport(referents, () => pathRange(ctx.allUris, *force(e.source)));
			},
			(in ImportOrExportKind.ModuleNamed m) {
				foreach (Sym name; m.names) {
					Opt!NameReferents value = m.module_.allExportedNames[name];
					if (has(value))
						addExport(force(value), () => pathRange(ctx.allUris, *force(e.source)));
				}
			});
	foreach (StructOrAlias x; structsAndAliasesMap)
		final switch (visibility(x)) {
			case Visibility.private_:
				break;
			case Visibility.internal:
			case Visibility.public_:
				addExport(NameReferents(some(x), none!(SpecDecl*), []), () => range(x).range);
				break;
		}
	foreach (immutable SpecDecl* x; specsMap)
		final switch (x.visibility) {
			case Visibility.private_:
				break;
			case Visibility.internal:
			case Visibility.public_:
				addExport(NameReferents(none!StructOrAlias, some(x), []), () => range(*x).range);
				break;
		}
	foreach (immutable FunDecl*[] funs; funsMap) {
		immutable FunDecl*[] funDecls = filter!(immutable FunDecl*)(ctx.alloc, funs, (in immutable FunDecl* x) =>
			x.visibility != Visibility.private_);
		if (!empty(funDecls))
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
	ref ProgramState programState,
	in ResolvedImport[] resolvedImports,
	ref FileAndAst fileAndAst,
	in CommonTypes* delegate(
		ref CheckCtx,
		in StructsAndAliasesMap,
		scope ref DelayStructInsts,
	) @safe @nogc pure nothrow getCommonTypes,
) =>
	withMeasure!(BootstrapCheck, () {
		ArrBuilder!Diagnostic diagsBuilder;
		ImportsAndReExports importsAndReExports = checkImportsAndReExports(
			alloc, allUris, diagsBuilder, fileAndAst.ast, resolvedImports);
		FileAst* ast = fileAndAst.ast;
		CheckCtx ctx = CheckCtx(
			ptrTrustMe(alloc),
			InstantiateCtx(ptrTrustMe(perf), ptrTrustMe(programState)),
			ptrTrustMe(allSymbols),
			ptrTrustMe(allUris),
			fileAndAst.uri,
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
			fileAndAst.uri,
			importsAndReExports,
			ast);
		return BootstrapCheck(res, commonTypes);
	})(perf, alloc, PerfMeasure.check);

immutable struct ImportsAndReExports {
	@safe @nogc pure nothrow:

	ImportOrExport[] moduleImports;
	ImportOrExport[] moduleReExports;
	ImportOrExportFile[] fileImports;
	ImportOrExportFile[] fileExports;

	ImportAndReExportModules modules() =>
		ImportAndReExportModules(moduleImports, moduleReExports);
}
immutable struct ImportOrExportFile {
	ImportOrExportAst* source;
	Uri uri;
}

ImportsAndReExports checkImportsAndReExports(
	ref Alloc alloc,
	in AllUris allUris,
	scope ref ArrBuilder!Diagnostic diagsBuilder,
	FileAst* ast,
	in ResolvedImport[] resolvedImports,
) {
	scope ResolvedImport[] resolvedImportsLeft = resolvedImports;
	ImportsOrReExports imports = checkImportsOrReExports(
		alloc, allUris, diagsBuilder, ast.imports, resolvedImportsLeft, !ast.noStd);
	ImportsOrReExports reExports = checkImportsOrReExports(
		alloc, allUris, diagsBuilder, ast.reExports, resolvedImportsLeft, false);
	assert(empty(resolvedImportsLeft));
	return ImportsAndReExports(imports.modules, reExports.modules, imports.files, reExports.files);
}

struct ImportsOrReExports {
	ImportOrExport[] modules;
	ImportOrExportFile[] files;
}
ImportsOrReExports checkImportsOrReExports(
	ref Alloc alloc,
	in AllUris allUris,
	scope ref ArrBuilder!Diagnostic diagsBuilder,
	in Opt!ImportsOrExportsAst ast,
	scope ref ResolvedImport[] resolvedImports,
	bool includeStd,
) {
	ArrBuilder!ImportOrExport imports;
	ArrBuilder!ImportOrExportFile fileImports;

	ResolvedImport nextResolvedImport() {
		ResolvedImport res = resolvedImports[0];
		resolvedImports = resolvedImports[1 .. $];
		return res;
	}

	void handleModuleImport(
		Opt!(ImportOrExportAst*) source,
		ImportOrExportKind delegate(Module*) @safe @nogc pure nothrow cb,
	) {
		nextResolvedImport().matchWithPointers!void(
			(Module* x) {
				add(alloc, imports, ImportOrExport(source, cb(x)));
			},
			(FileContent) {
				unreachable!void();
			},
			(Diag.ImportFileDiag x) {
				add(alloc, diagsBuilder, Diagnostic(
					has(source) ? pathRange(allUris, *force(source)) : Range.empty,
					Diag(x)));
			});
	}

	if (includeStd)
		handleModuleImport(none!(ImportOrExportAst*), (Module* x) =>
			ImportOrExportKind(ImportOrExportKind.ModuleWhole(x)));

	if (has(ast))
		foreach (ImportOrExportAst* importAst; ptrsRange(force(ast).paths)) {
			Opt!(ImportOrExportAst*) source = some(importAst);
			importAst.kind.match!void(
				(ImportOrExportAstKind.ModuleWhole) {
					handleModuleImport(source, (Module* x) => ImportOrExportKind(ImportOrExportKind.ModuleWhole(x)));
				},
				(NameAndRange[] names) {
					handleModuleImport(source, (Module* x) =>
						ImportOrExportKind(ImportOrExportKind.ModuleNamed(x, map(alloc, names, (ref NameAndRange x) =>
							x.name))));
				},
				(ref ImportOrExportAstKind.File x) {
					nextResolvedImport().matchWithPointers!void(
						(Module*) {
							unreachable!void();
						},
						(Uri x) {
							add(alloc, fileImports, ImportOrExportFile(importAst, x));
						},
						(Diag.ImportFileDiag x) {
							add(alloc, diagsBuilder, Diagnostic(pathRange(allUris, *importAst), Diag(x)));
						});
				});
		}
	return ImportsOrReExports(finishArr(alloc, imports), finishArr(alloc, fileImports));
}
