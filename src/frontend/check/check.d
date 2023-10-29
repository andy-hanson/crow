module frontend.check.check;

@safe @nogc pure nothrow:

import frontend.check.checkCtx : addDiag, CheckCtx, checkForUnused, ImportsAndReExports, posInFile, rangeInFile;
import frontend.check.checkExpr : checkFunctionBody;
import frontend.check.checkStructs : checkStructBodies, checkStructsInitial;
import frontend.check.getCommonTypes : getCommonTypes;
import frontend.check.maps : FunsMap, SpecsMap, StructsAndAliasesMap;
import frontend.check.funsForStruct : addFunsForStruct, addFunsForVar, countFunsForStructs, countFunsForVars;
import frontend.check.instantiate :
	DelaySpecInsts,
	DelayStructInsts,
	instantiateSpecParents,
	instantiateStructTypes,
	noDelaySpecInsts,
	noDelayStructInsts;
import frontend.check.typeFromAst :
	checkDestructure, checkTypeParams, specFromAst, typeFromAst, typeFromAstNoTypeParamsNeverDelay;
import frontend.diagnosticsBuilder : addDiagnostic, DiagnosticsBuilder;
import frontend.parse.ast :
	DestructureAst,
	ExprAst,
	ExprAstKind,
	FileAst,
	FunDeclAst,
	FunModifierAst,
	LiteralStringAst,
	NameAndRange,
	ParamsAst,
	range,
	SpecBodyAst,
	SpecDeclAst,
	SpecSigAst,
	StructAliasAst,
	TestAst,
	TypeAst,
	VarDeclAst;
import frontend.programState : ProgramState;
import model.diag : Diag;
import model.model :
	body_,
	CommonTypes,
	decl,
	Destructure,
	FunBody,
	FunDecl,
	FunFlags,
	ImportFileType,
	ImportOrExport,
	ImportOrExportKind,
	isLinkageAlwaysCompatible,
	Linkage,
	linkageRange,
	Module,
	name,
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
	target,
	Test,
	Type,
	typeArgs,
	TypeParam,
	typeParams,
	VarDecl,
	Visibility,
	visibility;
import util.alloc.alloc : Alloc;
import util.cell : Cell, cellGet, cellSet;
import util.col.arr : empty, only, ptrsRange, small;
import util.col.arrUtil : cat, filter, map, mapOp, mapToMut, zip, zipPtrFirst;
import util.col.map : Map, mapEach, mapEachIn, hasKey, KeyValuePair;
import util.col.mapBuilder : MapBuilder, finishMap, tryAddToMap;
import util.col.exactSizeArrBuilder : ExactSizeArrBuilder, exactSizeArrBuilderAdd, finish, newExactSizeArrBuilder;
import util.col.multiMap : buildMultiMap, multiMapEach;
import util.col.mutArr : mustPop, MutArr, mutArrIsEmpty;
import util.col.mutMap : insertOrUpdate, moveToMap, MutMap;
import util.col.mutMaxArr : isFull, mustPop, MutMaxArr, mutMaxArr, mutMaxArrSize, push, pushIfUnderMaxSize, toArray;
import util.col.str : copySafeCStr, safeCStr;
import util.memory : allocate;
import util.opt : force, has, none, Opt, someMut, some;
import util.perf : Perf;
import util.ptr : ptrTrustMe;
import util.storage : asBytes, asString, FileContent;
import util.sourceRange : UriAndPos, UriAndRange, RangeWithinFile;
import util.sym : AllSymbols, Sym, sym;
import util.uri : Uri;
import util.util : unreachable, todo, verify;

immutable struct FileAndAst {
	Uri uri;
	FileAst ast;
}

immutable struct BootstrapCheck {
	Module module_;
	CommonTypes commonTypes;
}

BootstrapCheck checkBootstrap(
	ref Alloc alloc,
	ref Perf perf,
	ref AllSymbols allSymbols,
	scope ref DiagnosticsBuilder diagsBuilder,
	ref ProgramState programState,
	in FileAndAst fileAndAst,
) {
	static ImportsAndExports emptyImportsAndExports = ImportsAndExports([], [], [], []);
	return checkWorker(
		alloc,
		perf,
		allSymbols,
		diagsBuilder,
		programState,
		emptyImportsAndExports,
		fileAndAst,
		(ref CheckCtx ctx,
		in StructsAndAliasesMap structsAndAliasesMap,
		scope ref MutArr!(StructInst*) delayedStructInsts) @safe =>
			getCommonTypes(ctx, structsAndAliasesMap, delayedStructInsts));
}

immutable struct ImportsAndExports {
	ImportOrExport[] moduleImports;
	ImportOrExport[] moduleExports;
	ImportOrExportFile[] fileImports;
	ImportOrExportFile[] fileExports;
}

immutable struct ImportOrExportFile {
	RangeWithinFile range;
	Sym name;
	ImportFileType type;
	FileContent content;
}

Module check(
	ref Alloc alloc,
	ref Perf perf,
	ref AllSymbols allSymbols,
	scope ref DiagnosticsBuilder diagsBuilder,
	ref ProgramState programState,
	ref ImportsAndExports importsAndExports,
	in FileAndAst fileAndAst,
	in CommonTypes commonTypes,
) =>
	checkWorker(
		alloc,
		perf,
		allSymbols,
		diagsBuilder,
		programState,
		importsAndExports,
		fileAndAst,
		(ref CheckCtx _, in StructsAndAliasesMap _2, scope ref MutArr!(StructInst*)) => commonTypes,
	).module_;

private:

Params checkParams(
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	in ParamsAst ast,
	in StructsAndAliasesMap structsAndAliasesMap,
	TypeParam[] typeParamsScope,
	ref DelayStructInsts delayStructInsts,
) =>
	ast.matchIn!Params(
		(in DestructureAst[] asts) =>
			Params(map!(Destructure, DestructureAst)(ctx.alloc, asts, (ref DestructureAst ast) =>
				checkDestructure(
					ctx, commonTypes, structsAndAliasesMap, typeParamsScope, delayStructInsts,
					ast, none!Type))),
		(in ParamsAst.Varargs varargs) {
			Destructure param = checkDestructure(
				ctx, commonTypes, structsAndAliasesMap, typeParamsScope, delayStructInsts, varargs.param, none!Type);
			Opt!Type elementType = param.type.match!(Opt!Type)(
				(Type.Bogus _) =>
					some(Type(Type.Bogus())),
				(ref TypeParam _) =>
					none!Type,
				(ref StructInst x) =>
					decl(x) == commonTypes.array
					? some(only(typeArgs(x)))
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
	in TypeAst returnTypeAst,
	in ParamsAst paramsAst,
	TypeParam[] typeParams,
	in StructsAndAliasesMap structsAndAliasesMap,
	DelayStructInsts delayStructInsts
) =>
	ReturnTypeAndParams(
		typeFromAst(ctx, commonTypes, returnTypeAst, structsAndAliasesMap, typeParams, delayStructInsts),
		checkParams(ctx, commonTypes, paramsAst, structsAndAliasesMap, typeParams, delayStructInsts));

SpecDeclBody.Builtin.Kind getSpecBodyBuiltinKind(ref CheckCtx ctx, RangeWithinFile range, Sym name) {
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
	TypeParam[] typeParams,
	in StructsAndAliasesMap structsAndAliasesMap,
	RangeWithinFile range,
	Sym name,
	in SpecBodyAst ast,
) =>
	ast.matchIn!SpecDeclBody(
		(in SpecBodyAst.Builtin) =>
			SpecDeclBody(SpecDeclBody.Builtin(getSpecBodyBuiltinKind(ctx, range, name))),
		(in SpecSigAst[] sigs) =>
			SpecDeclBody(map(ctx.alloc, sigs, (ref SpecSigAst x) {
				ReturnTypeAndParams rp = checkReturnTypeAndParams(
					ctx, commonTypes, x.returnType, x.params, typeParams, structsAndAliasesMap, noDelayStructInsts);
				Destructure[] params = rp.params.match!(Destructure[])(
					(Destructure[] x) =>
						x,
					(ref Params.Varargs _) =>
						todo!(Destructure[])("diag: no varargs in spec"));
				return SpecDeclSig(x.docComment, rangeInFile(ctx, x.range), x.name, rp.returnType, small(params));
			})));

SpecDecl[] checkSpecDeclsInitial(
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	ref StructsAndAliasesMap structsAndAliasesMap,
	in SpecDeclAst[] asts,
) =>
	map(ctx.alloc, asts, (ref SpecDeclAst ast) {
		TypeParam[] typeParams = checkTypeParams(ctx, ast.typeParams);
		SpecDeclBody body_ =
			checkSpecDeclBody(ctx, commonTypes, typeParams, structsAndAliasesMap, ast.range, ast.name, ast.body_);
		return SpecDecl(
			rangeInFile(ctx, ast.range),
			copySafeCStr(ctx.alloc, ast.docComment),
			ast.visibility,
			ast.name,
			small(typeParams),
			body_);
	});

void checkSpecDeclParents(
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	ref StructsAndAliasesMap structsAndAliasesMap,
	ref SpecsMap specsMap,
	in SpecDeclAst[] asts,
	SpecDecl[] specs,
) {
	MutArr!(SpecInst*) delaySpecInsts;

	zip!(SpecDeclAst, SpecDecl)(asts, specs, (ref SpecDeclAst ast, ref SpecDecl spec) {
		spec.parents = mapOp!(immutable SpecInst*, TypeAst)(ctx.alloc, ast.parents, (ref TypeAst parent) =>
			checkFunModifierNonSpecial(
				ctx, commonTypes, structsAndAliasesMap, specsMap, spec.typeParams, parent,
				someMut(ptrTrustMe(delaySpecInsts))));
	});

	foreach (SpecDecl* decl; ptrsRange(specs))
		detectAndFixSpecRecursion(ctx, decl);

	while (!mutArrIsEmpty(delaySpecInsts)) {
		SpecInst* i = mustPop(delaySpecInsts);
		instantiateSpecParents(ctx.alloc, ctx.programState, i, someMut(&delaySpecInsts));
	}
}

void detectAndFixSpecRecursion(ref CheckCtx ctx, SpecDecl* decl) {
	MutMaxArr!(8, immutable SpecDecl*) trace = mutMaxArr!(8, immutable SpecDecl*);
	if (recurDetectSpecRecursion(decl, trace)) {
		addDiag(ctx, decl.range, Diag(Diag.SpecRecursion(toArray(ctx.alloc, trace))));
		decl.overwriteParents([]);
	}
}
bool recurDetectSpecRecursion(SpecDecl* cur, ref MutMaxArr!(8, immutable SpecDecl*) trace) {
	if (!empty(cur.parents) && isFull(trace))
		return true;
	foreach (SpecInst* parent; cur.parents) {
		push(trace, decl(*parent));
		if (recurDetectSpecRecursion(decl(*parent), trace))
			return true;
		else
			mustPop(trace);
	}
	return false;
}

StructAlias[] checkStructAliasesInitial(ref CheckCtx ctx, scope StructAliasAst[] asts) =>
	mapToMut!(StructAlias, StructAliasAst)(ctx.alloc, asts, (in StructAliasAst ast) @safe =>
		StructAlias(
			rangeInFile(ctx, ast.range),
			copySafeCStr(ctx.alloc, ast.docComment),
			ast.visibility,
			ast.name,
			small(checkTypeParams(ctx, ast.typeParams))));

void checkStructAliasTargets(
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	in StructsAndAliasesMap structsAndAliasesMap,
	StructAlias[] aliases,
	in StructAliasAst[] asts,
	ref MutArr!(StructInst*) delayStructInsts,
) {
	zip!(StructAlias, StructAliasAst)(aliases, asts, (ref StructAlias structAlias, ref StructAliasAst ast) {
		Type type = typeFromAst(
			ctx,
			commonTypes,
			ast.target,
			structsAndAliasesMap,
			structAlias.typeParams,
			someMut!(MutArr!(StructInst*)*)(ptrTrustMe(delayStructInsts)));
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
	MapBuilder!(Sym, StructOrAlias) builder;
	foreach (StructDecl* decl; ptrsRange(structs))
		addToDeclsMap!StructOrAlias(ctx, builder, StructOrAlias(decl), Diag.DuplicateDeclaration.Kind.structOrAlias);
	foreach (StructAlias* alias_; ptrsRange(aliases))
		addToDeclsMap!StructOrAlias(ctx, builder, StructOrAlias(alias_), Diag.DuplicateDeclaration.Kind.structOrAlias);
	return finishMap(ctx.alloc, builder);
}

VarDecl[] checkVars(
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	in StructsAndAliasesMap structsAndAliasesMap,
	in VarDeclAst[] asts,
) =>
	map(ctx.alloc, asts, (ref VarDeclAst ast) =>
		checkVarDecl(ctx, commonTypes, structsAndAliasesMap, ast));

VarDecl checkVarDecl(
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	in StructsAndAliasesMap structsAndAliasesMap,
	in VarDeclAst ast,
) {
	if (!empty(ast.typeParams))
		todo!void("diag");
	return VarDecl(
		UriAndPos(ctx.curUri, ast.range.start),
		copySafeCStr(ctx.alloc, ast.docComment),
		ast.visibility,
		ast.name,
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

void addToDeclsMap(T)(
	ref CheckCtx ctx,
	ref MapBuilder!(Sym, T) builder,
	T added,
	Diag.DuplicateDeclaration.Kind kind,
) {
	Opt!T old = tryAddToMap(ctx.alloc, builder, added.name, added);
	if (has(old))
		addDiag(ctx, added.range, Diag(Diag.DuplicateDeclaration(kind, added.name)));
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
	RangeWithinFile range,
	in FunModifierAst[] asts,
	in StructsAndAliasesMap structsAndAliasesMap,
	in SpecsMap specsMap,
	TypeParam[] typeParamsScope,
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
	TypeParam[] typeParamsScope,
	in TypeAst ast,
	DelaySpecInsts delaySpecInsts,
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

FunFlags checkFunFlags(ref CheckCtx ctx, RangeWithinFile range, FunModifierAst.Special.Flags flags) {
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
		verify(mutMaxArrSize(bodyModifiers) == 2);
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
	ExactSizeArrBuilder!FunDecl funsBuilder = newExactSizeArrBuilder!FunDecl(
		ctx.alloc,
		asts.length + fileImports.length + fileExports.length + countFunsForStructs(structs) + countFunsForVars(vars));
	foreach (ref FunDeclAst funAst; asts) {
		TypeParam[] typeParams = checkTypeParams(ctx, funAst.typeParams);
		ReturnTypeAndParams rp = checkReturnTypeAndParams(
			ctx,
			commonTypes,
			funAst.returnType,
			funAst.params,
			typeParams,
			structsAndAliasesMap,
			noDelayStructInsts);
		FunFlagsAndSpecs flagsAndSpecs = checkFunModifiers(
			ctx, commonTypes, funAst.range, funAst.modifiers, structsAndAliasesMap, specsMap, typeParams);
		exactSizeArrBuilderAdd(
			funsBuilder,
			FunDecl(
				copySafeCStr(ctx.alloc, funAst.docComment),
				funAst.visibility,
				posInFile(ctx, funAst.range.start),
				funAst.name,
				typeParams,
				rp.returnType,
				rp.params,
				flagsAndSpecs.flags,
				flagsAndSpecs.specs));
	}
	foreach (ref ImportOrExportFile f; fileImports)
		exactSizeArrBuilderAdd(
			funsBuilder,
			funDeclForFileImportOrExport(ctx, commonTypes, structsAndAliasesMap, f, Visibility.private_));
	foreach (ref ImportOrExportFile f; fileExports)
		exactSizeArrBuilderAdd(
			funsBuilder,
			funDeclForFileImportOrExport(ctx, commonTypes, structsAndAliasesMap, f, Visibility.public_));

	foreach (StructDecl* struct_; ptrsRange(structs))
		addFunsForStruct(ctx, funsBuilder, commonTypes, struct_);
	foreach (VarDecl* var; ptrsRange(vars))
		addFunsForVar(ctx, funsBuilder, commonTypes, var);
	FunDecl[] funs = finish(funsBuilder);

	FunsMap funsMap = buildMultiMap!(Sym, immutable FunDecl*, FunDecl)(
		ctx.alloc, funs, (size_t index, FunDecl* x) => KeyValuePair!(Sym, immutable FunDecl*)(x.name, x));

	FunDecl[] funsWithAsts = funs[0 .. asts.length];
	zipPtrFirst!(FunDecl, FunDeclAst)(funsWithAsts, asts, (FunDecl* fun, ref FunDeclAst funAst) {
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
							*fun,
							force(funAst.body_)));
				case FunFlags.SpecialBody.builtin:
				case FunFlags.SpecialBody.generated:
					if (has(funAst.body_))
						todo!void("diag: builtin fun can't have body");
					return FunBody(FunBody.Builtin());
				case FunFlags.SpecialBody.extern_:
					if (has(funAst.body_))
						todo!void("diag: builtin fun can't have body");
					return FunBody(checkExternBody(
						ctx, fun, getExternTypeArg(funAst, FunModifierAst.Special.Flags.extern_)));
			}
		}());
	});
	foreach (size_t i, ref ImportOrExportFile f; fileImports) {
		FunDecl* fun = &funs[asts.length + i];
		fun.setBody(getFileImportFunctionBody(ctx, commonTypes, structsAndAliasesMap, funsMap, *fun, f));
	}
	foreach (size_t i, ref ImportOrExportFile f; fileExports) {
		FunDecl* fun = &funs[asts.length + fileImports.length + i];
		fun.setBody(getFileImportFunctionBody(ctx, commonTypes, structsAndAliasesMap, funsMap, *fun, f));
	}

	Test[] tests = map(ctx.alloc, testAsts, (scope ref TestAst ast) {
		Type voidType = Type(commonTypes.void_);
		if (!has(ast.body_))
			todo!void("diag: test needs body");
		return Test(checkFunctionBody(
			ctx,
			structsAndAliasesMap,
			commonTypes,
			funsMap,
			voidType,
			sym!"test",
			[],
			[],
			[],
			FunFlags.none.withSummon,
			force(ast.body_)));
	});

	return FunsAndMap(funs, tests, funsMap);
}

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

FunBody getFileImportFunctionBody(
	ref CheckCtx ctx,
	in CommonTypes commonTypes,
	in StructsAndAliasesMap structsAndAliasesMap,
	ref FunsMap funsMap,
	ref FunDecl f,
	ref ImportOrExportFile ie,
) {
	final switch (ie.type) {
		case ImportFileType.nat8Array:
			return FunBody(FunBody.FileBytes(asBytes(ie.content)));
		case ImportFileType.string:
			ExprAst ast = ExprAst(f.range.range, ExprAstKind(LiteralStringAst(asString(ie.content))));
			return FunBody(getExprFunctionBody(ctx, commonTypes, structsAndAliasesMap, funsMap, f, ast));
	}
}

FunBody.ExpressionBody getExprFunctionBody(
	ref CheckCtx ctx,
	in CommonTypes commonTypes,
	in StructsAndAliasesMap structsAndAliasesMap,
	in FunsMap funsMap,
	in FunDecl f,
	in ExprAst e,
) =>
	FunBody.ExpressionBody(checkFunctionBody(
		ctx,
		structsAndAliasesMap,
		commonTypes,
		funsMap,
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
	in ImportOrExportFile a,
	Visibility visibility,
) =>
	FunDecl(
		safeCStr!"",
		visibility,
		UriAndPos(ctx.curUri, a.range.start),
		a.name,
		[],
		typeForFileImport(ctx, commonTypes, structsAndAliasesMap, a.range, a.type),
		Params([]),
		FunFlags.generatedBare,
		[]);

Type typeForFileImport(
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	in StructsAndAliasesMap structsAndAliasesMap,
	RangeWithinFile range,
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
		addDiag(ctx, fun.range, Diag(Diag.ExternFunForbidden(fun, Diag.ExternFunForbidden.Reason.hasTypeParams)));
	if (!empty(fun.specs))
		addDiag(ctx, fun.range, Diag(Diag.ExternFunForbidden(fun, Diag.ExternFunForbidden.Reason.hasSpecs)));

	if (!isLinkageAlwaysCompatible(funLinkage, linkageRange(fun.returnType)))
		addDiag(ctx, fun.range, Diag(Diag.LinkageWorseThanContainingFun(fun, fun.returnType, none!(Destructure*))));
	fun.params.match!void(
		(Destructure[] params) {
			foreach (Destructure* p; ptrsRange(params))
				if (!isLinkageAlwaysCompatible(funLinkage, linkageRange(p.type)))
					addDiag(ctx, p.range, Diag(Diag.LinkageWorseThanContainingFun(fun, p.type, some(p))));
		},
		(ref Params.Varargs) {
			addDiag(ctx, fun.range, Diag(Diag.ExternFunForbidden(fun, Diag.ExternFunForbidden.Reason.variadic)));
		});
	return FunBody.Extern(externLibraryNameFromTypeArg(ctx, fun.nameRange(ctx.allSymbols), typeArg));
}

Sym externLibraryNameFromTypeArg(ref CheckCtx ctx, RangeWithinFile range, in Opt!TypeAst typeArg) {
	if (has(typeArg) && force(typeArg).isA!NameAndRange)
		return force(typeArg).as!NameAndRange.name;
	else {
		addDiag(ctx, range, Diag(Diag.ExternMissingLibraryName()));
		return sym!"bogus";
	}
}

SpecsMap buildSpecsMap(ref CheckCtx ctx, SpecDecl[] specs) {
	MapBuilder!(Sym, SpecDecl*) res;
	foreach (SpecDecl* spec; ptrsRange(specs))
		addToDeclsMap(ctx, res, spec, Diag.DuplicateDeclaration.Kind.spec);
	return finishMap(ctx.alloc, res);
}

Module checkWorkerAfterCommonTypes(
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	ref StructsAndAliasesMap structsAndAliasesMap,
	StructAlias[] structAliases,
	StructDecl[] structs,
	ref MutArr!(StructInst*) delayStructInsts,
	Uri uri,
	ref ImportsAndExports importsAndExports,
	in FileAst ast,
) {
	checkStructBodies(ctx, commonTypes, structsAndAliasesMap, structs, ast.structs, delayStructInsts);

	while (!mutArrIsEmpty(delayStructInsts)) {
		StructInst* i = mustPop(delayStructInsts);
		i.instantiatedTypes =
			instantiateStructTypes(ctx.alloc, ctx.programState, i.declAndArgs, someMut(ptrTrustMe(delayStructInsts)));
	}

	VarDecl[] vars = checkVars(ctx, commonTypes, structsAndAliasesMap, ast.vars);
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
		importsAndExports.fileImports,
		importsAndExports.fileExports,
		ast.funs,
		ast.tests);
	checkForUnused(ctx, structAliases, structs, specs, funsAndMap.funs);
	return Module(
		uri,
		copySafeCStr(ctx.alloc, ast.docComment),
		importsAndExports.moduleImports,
		importsAndExports.moduleExports,
		structs, vars, specs, funsAndMap.funs, funsAndMap.tests,
		getAllExportedNames(
			ctx.alloc,
			ctx.diagsBuilder,
			importsAndExports.moduleExports,
			structsAndAliasesMap,
			specsMap,
			funsAndMap.funsMap,
			uri));
}

Map!(Sym, NameReferents) getAllExportedNames(
	ref Alloc alloc,
	scope ref DiagnosticsBuilder diagsBuilder,
	in ImportOrExport[] reExports,
	in StructsAndAliasesMap structsAndAliasesMap,
	in SpecsMap specsMap,
	in FunsMap funsMap,
	Uri uri,
) {
	MutMap!(Sym, NameReferents) res;
	void addExport(Sym name, NameReferents cur, UriAndRange range) {
		insertOrUpdate!(Sym, NameReferents)(
			alloc,
			res,
			name,
			() => cur,
			(ref NameReferents prev) {
				Opt!(Diag.DuplicateExports.Kind) kind = has(prev.structOrAlias) && has(cur.structOrAlias)
					? some(Diag.DuplicateExports.Kind.type)
					: has(prev.spec) && has(cur.spec)
					? some(Diag.DuplicateExports.Kind.spec)
					: none!(Diag.DuplicateExports.Kind);
				if (has(kind))
					addDiagnostic(alloc, diagsBuilder, range, Diag(Diag.DuplicateExports(force(kind), name)));
				return NameReferents(
					has(prev.structOrAlias) ? prev.structOrAlias : cur.structOrAlias,
					has(prev.spec) ? prev.spec : cur.spec,
					cat(alloc, prev.funs, cur.funs));
			});
	}

	foreach (ref ImportOrExport e; reExports)
		e.kind.matchIn!void(
			(in ImportOrExportKind.ModuleWhole m) {
				mapEachIn!(Sym, NameReferents)(
					m.module_.allExportedNames,
					(in Sym name, in NameReferents value) {
						addExport(name, value, UriAndRange(uri, force(e.importSource)));
					});
			},
			(in ImportOrExportKind.ModuleNamed m) {
				foreach (Sym name; m.names) {
					Opt!NameReferents value = m.module_.allExportedNames[name];
					if (has(value))
						addExport(name, force(value), UriAndRange(uri, force(e.importSource)));
				}
			});
	mapEach!(Sym, StructOrAlias)(
		structsAndAliasesMap,
		(Sym name, ref StructOrAlias x) {
			final switch (visibility(x)) {
				case Visibility.private_:
					break;
				case Visibility.internal:
				case Visibility.public_:
					addExport(name, NameReferents(some(x), none!(SpecDecl*), []), range(x));
					break;
			}
		});
	mapEach!(Sym, SpecDecl*)(specsMap, (Sym name, ref SpecDecl* x) {
		final switch (x.visibility) {
			case Visibility.private_:
				break;
			case Visibility.internal:
			case Visibility.public_:
				addExport(name, NameReferents(none!StructOrAlias, some(x), []), x.range);
				break;
		}
	});
	multiMapEach!(Sym, immutable FunDecl*)(funsMap, (Sym name, in immutable FunDecl*[] funs) {
		immutable FunDecl*[] funDecls = filter!(immutable FunDecl*)(alloc, funs, (in immutable FunDecl* x) =>
			x.visibility != Visibility.private_);
		if (!empty(funDecls))
			addExport(
				name,
				NameReferents(none!StructOrAlias, none!(SpecDecl*), funDecls),
				// This argument doesn't matter because a function never results in a duplicate export error
				UriAndRange(uri, RangeWithinFile.empty));
	});

	return moveToMap!(Sym, NameReferents)(alloc, res);
}

BootstrapCheck checkWorker(
	ref Alloc alloc,
	scope ref Perf perf,
	scope ref AllSymbols allSymbols,
	scope ref DiagnosticsBuilder diagsBuilder,
	ref ProgramState programState,
	ref ImportsAndExports importsAndExports,
	in FileAndAst fileAndAst,
	in CommonTypes delegate(
		ref CheckCtx,
		in StructsAndAliasesMap,
		scope ref MutArr!(StructInst*),
	) @safe @nogc pure nothrow getCommonTypes,
) {
	checkImportsOrExports(alloc, diagsBuilder, fileAndAst.uri, importsAndExports.moduleImports);
	checkImportsOrExports(alloc, diagsBuilder, fileAndAst.uri, importsAndExports.moduleExports);
	FileAst ast = fileAndAst.ast;
	CheckCtx ctx = CheckCtx(
		ptrTrustMe(alloc),
		ptrTrustMe(perf),
		ptrTrustMe(programState),
		ptrTrustMe(allSymbols),
		fileAndAst.uri,
		ImportsAndReExports(importsAndExports.moduleImports, importsAndExports.moduleExports),
		ptrTrustMe(diagsBuilder));

	// Since structs may refer to each other, first get a structsAndAliasesMap, *then* fill in bodies
	StructDecl[] structs = checkStructsInitial(ctx, ast.structs);
	StructAlias[] structAliases = checkStructAliasesInitial(ctx, ast.structAliases);
	StructsAndAliasesMap structsAndAliasesMap = buildStructsAndAliasesMap(ctx, structs, structAliases);

	// We need to create StructInsts when filling in struct bodies.
	// But when creating a StructInst, we usually want to fill in its body.
	// In case the decl body isn't available yet,
	// we'll delay creating the StructInst body, which isn't needed until expr checking.
	MutArr!(StructInst*) delayStructInsts;

	CommonTypes commonTypes = getCommonTypes(ctx, structsAndAliasesMap, delayStructInsts);

	checkStructAliasTargets(
		ctx,
		commonTypes,
		structsAndAliasesMap,
		structAliases,
		ast.structAliases,
		delayStructInsts);

	Module res = checkWorkerAfterCommonTypes(
		ctx,
		commonTypes,
		structsAndAliasesMap,
		structAliases,
		structs,
		delayStructInsts,
		fileAndAst.uri,
		importsAndExports,
		ast);
	return BootstrapCheck(res, commonTypes);
}

void checkImportsOrExports(
	ref Alloc alloc,
	scope ref DiagnosticsBuilder diags,
	Uri thisFile,
	in ImportOrExport[] imports,
) {
	foreach (ref ImportOrExport x; imports)
		x.kind.matchIn!void(
			(in ImportOrExportKind.ModuleWhole) {},
			(in ImportOrExportKind.ModuleNamed m) {
				foreach (Sym name; m.names)
					if (!hasKey(m.module_.allExportedNames, name))
						addDiagnostic(
							alloc,
							diags,
							// TODO: use the range of the particular name
							// (by advancing pos by symSize until we get to this name)
							UriAndRange(thisFile, force(x.importSource)),
							Diag(Diag.ImportRefersToNothing(name)));
			});
}
