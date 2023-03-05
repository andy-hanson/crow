module frontend.check.check;

@safe @nogc pure nothrow:

import frontend.check.checkCtx : addDiag, CheckCtx, checkForUnused, ImportsAndReExports, posInFile, rangeInFile;
import frontend.check.checkExpr : checkFunctionBody;
import frontend.check.checkStructs : checkStructBodies, checkStructsInitial;
import frontend.check.dicts : FunsDict, SpecsDict, StructsAndAliasesDict;
import frontend.check.funsForStruct : addFunsForStruct, addFunsForVar, countFunsForStructs, countFunsForVars;
import frontend.check.instantiate :
	DelaySpecInsts,
	DelayStructInsts,
	instantiateSpecParents,
	instantiateStruct,
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
	FileContent,
	FunBody,
	FunDecl,
	FunFlags,
	FunKind,
	ImportFileType,
	ImportOrExport,
	ImportOrExportKind,
	IntegralTypes,
	isLinkageAlwaysCompatible,
	Linkage,
	linkageRange,
	Module,
	name,
	NameReferents,
	Params,
	paramsArray,
	Purity,
	range,
	setBody,
	setTarget,
	SpecDecl,
	SpecDeclBody,
	SpecDeclSig,
	SpecInst,
	StructAlias,
	StructBody,
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
import util.col.arrBuilder : add, ArrBuilder, finishArr;
import util.col.arrUtil : cat, filter, map, mapOp, mapToMut, zip, zipPtrFirst;
import util.col.dict : Dict, dictEach, dictEachIn, hasKey, KeyValuePair;
import util.col.dictBuilder : DictBuilder, finishDict, tryAddToDict;
import util.col.enumDict : EnumDict;
import util.col.exactSizeArrBuilder : ExactSizeArrBuilder, exactSizeArrBuilderAdd, finish, newExactSizeArrBuilder;
import util.col.multiDict : buildMultiDict, multiDictEach;
import util.col.mutArr : mustPop, MutArr, mutArrIsEmpty;
import util.col.mutDict : insertOrUpdate, moveToDict, MutDict;
import util.col.mutMaxArr : isFull, mustPop, MutMaxArr, mutMaxArr, mutMaxArrSize, push, pushIfUnderMaxSize, toArray;
import util.col.str : copySafeCStr, SafeCStr, safeCStr, strOfSafeCStr;
import util.memory : allocate;
import util.opt : force, has, none, Opt, someMut, some;
import util.perf : Perf;
import util.ptr : ptrTrustMe;
import util.sourceRange : FileAndPos, FileAndRange, FileIndex, RangeWithinFile;
import util.sym : AllSymbols, Sym, sym;
import util.util : unreachable, todo, verify;

immutable struct PathAndAst { //TODO:RENAME
	FileIndex fileIndex;
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
	in PathAndAst pathAndAst,
) {
	static ImportsAndExports emptyImportsAndExports = ImportsAndExports([], [], [], []);
	return checkWorker(
		alloc,
		perf,
		allSymbols,
		diagsBuilder,
		programState,
		emptyImportsAndExports,
		pathAndAst,
		(ref CheckCtx ctx,
		in StructsAndAliasesDict structsAndAliasesDict,
		scope ref MutArr!(StructInst*) delayedStructInsts) @safe =>
			getCommonTypes(ctx, structsAndAliasesDict, delayedStructInsts));
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
	in PathAndAst pathAndAst,
	in CommonTypes commonTypes,
) =>
	checkWorker(
		alloc,
		perf,
		allSymbols,
		diagsBuilder,
		programState,
		importsAndExports,
		pathAndAst,
		(ref CheckCtx _, in StructsAndAliasesDict _2, scope ref MutArr!(StructInst*)) => commonTypes,
	).module_;

private:

Opt!(StructDecl*) getCommonTemplateType(
	in StructsAndAliasesDict structsAndAliasesDict,
	Sym name,
	size_t expectedTypeParams,
) {
	Opt!StructOrAlias res = structsAndAliasesDict[name];
	if (has(res)) {
		// TODO: may fail -- builtin Template should not be an alias
		StructDecl* decl = force(res).as!(StructDecl*);
		if (decl.typeParams.length != expectedTypeParams)
			todo!void("getCommonTemplateType");
		return some(decl);
	} else
		return none!(StructDecl*);
}

Opt!(StructInst*) getCommonNonTemplateType(
	ref Alloc alloc,
	ref ProgramState programState,
	in StructsAndAliasesDict structsAndAliasesDict,
	Sym name,
	scope ref MutArr!(StructInst*) delayedStructInsts,
) {
	Opt!StructOrAlias opStructOrAlias = structsAndAliasesDict[name];
	return has(opStructOrAlias)
		? instantiateNonTemplateStructOrAlias(alloc, programState, delayedStructInsts, force(opStructOrAlias))
		: none!(StructInst*);
}

Opt!(StructInst*) instantiateNonTemplateStructOrAlias(
	ref Alloc alloc,
	ref ProgramState programState,
	scope ref MutArr!(StructInst*) delayedStructInsts,
	StructOrAlias structOrAlias,
) {
	verify(empty(typeParams(structOrAlias)));
	return structOrAlias.matchWithPointers!(Opt!(StructInst*))(
		(StructAlias* x) =>
			target(*x),
		(StructDecl* x) =>
			some(instantiateNonTemplateStructDecl(alloc, programState, delayedStructInsts, x)));
}

StructInst* instantiateNonTemplateStructDecl(
	ref Alloc alloc,
	ref ProgramState programState,
	scope ref MutArr!(StructInst*) delayedStructInsts,
	StructDecl* structDecl,
) =>
	instantiateStruct(alloc, programState, structDecl, [], someMut(ptrTrustMe(delayedStructInsts)));

CommonTypes getCommonTypes(
	ref CheckCtx ctx,
	in StructsAndAliasesDict structsAndAliasesDict,
	scope ref MutArr!(StructInst*) delayedStructInsts,
) {
	void addDiagMissing(Sym name) {
		addDiag(ctx, FileAndRange(ctx.fileIndex, RangeWithinFile.empty), Diag(Diag.CommonTypeMissing(name)));
	}

	StructInst* nonTemplateFromSym(Sym name) {
		Opt!(StructInst*) res =
			getCommonNonTemplateType(ctx.alloc, ctx.programState, structsAndAliasesDict, name, delayedStructInsts);
		if (has(res))
			return force(res);
		else {
			addDiagMissing(name);
			return instantiateNonTemplateStructDecl(
				ctx.alloc,
				ctx.programState,
				delayedStructInsts,
				bogusStructDecl(ctx.alloc, 0));
		}
	}
	StructInst* nonTemplate(string name)() {
		return nonTemplateFromSym(sym!name);
	}

	StructInst* bool_ = nonTemplate!"bool";
	StructInst* char8 = nonTemplate!"char8";
	StructInst* float32 = nonTemplate!"float32";
	StructInst* float64 = nonTemplate!"float64";
	StructInst* int8 = nonTemplate!"int8";
	StructInst* int16 = nonTemplate!"int16";
	StructInst* int32 = nonTemplate!"int32";
	StructInst* int64 = nonTemplate!"int64";
	StructInst* nat8 = nonTemplate!"nat8";
	StructInst* nat16 = nonTemplate!"nat16";
	StructInst* nat32 = nonTemplate!"nat32";
	StructInst* nat64 = nonTemplate!"nat64";
	StructInst* symbol = nonTemplate!"symbol";
	StructInst* void_ = nonTemplate!"void";

	StructDecl* getDeclFromSym(Sym name, size_t nTypeParameters) {
		Opt!(StructDecl*) res = getCommonTemplateType(structsAndAliasesDict, name, nTypeParameters);
		if (has(res))
			return force(res);
		else {
			addDiagMissing(name);
			return bogusStructDecl(ctx.alloc, nTypeParameters);
		}
	}
	StructDecl* getDecl(string name)(size_t nTypeParameters) {
		return getDeclFromSym(sym!name, nTypeParameters);
	}

	StructDecl* array = getDecl!"array"(1);
	StructDecl* future = getDecl!"future"(1);
	StructDecl* opt = getDecl!"option"(1);
	StructDecl* pointerConst = getDecl!"const-pointer"(1);
	StructDecl* pointerMut = getDecl!"mut-pointer"(1);
	EnumDict!(FunKind, StructDecl*) funs = immutable EnumDict!(FunKind, StructDecl*)([
		getDecl!"fun-fun"(2), getDecl!"fun-act"(2), getDecl!"fun-far"(2), getDecl!"fun-pointer"(2),
	]);

	StructDecl* constPointer = getDecl!"const-pointer"(1);
	StructInst* cStr = instantiateStruct(
		ctx.alloc, ctx.programState, constPointer, [Type(char8)], someMut(ptrTrustMe(delayedStructInsts)));

	StructDecl*[8] tuples = [
		getDecl!"tuple2"(2),
		getDecl!"tuple3"(3),
		getDecl!"tuple4"(4),
		getDecl!"tuple5"(5),
		getDecl!"tuple6"(6),
		getDecl!"tuple7"(7),
		getDecl!"tuple8"(8),
		getDecl!"tuple9"(9),
	];

	return CommonTypes(
		bool_,
		char8,
		cStr,
		float32,
		float64,
		IntegralTypes(int8, int16, int32, int64, nat8, nat16, nat32, nat64),
		symbol,
		void_,
		array,
		future,
		opt,
		pointerConst,
		pointerMut,
		tuples,
		funs);
}

StructDecl* bogusStructDecl(ref Alloc alloc, size_t nTypeParameters) {
	ArrBuilder!TypeParam typeParams;
	FileAndRange fileAndRange = FileAndRange(FileIndex(0), RangeWithinFile.empty);
	foreach (size_t i; 0 .. nTypeParameters)
		add(alloc, typeParams, TypeParam(fileAndRange, sym!"bogus", i));
	StructDecl* res = allocate(alloc, StructDecl(
		fileAndRange,
		safeCStr!"",
		sym!"bogus",
		small(finishArr(alloc, typeParams)),
		Visibility.public_,
		Linkage.internal,
		Purity.data,
		false));
	setBody(*res, StructBody(StructBody.Bogus()));
	return res;
}

Params checkParams(
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	in ParamsAst ast,
	in StructsAndAliasesDict structsAndAliasesDict,
	TypeParam[] typeParamsScope,
	ref DelayStructInsts delayStructInsts,
) =>
	ast.matchIn!Params(
		(in DestructureAst[] asts) =>
			Params(map!(Destructure, DestructureAst)(ctx.alloc, asts, (ref DestructureAst ast) =>
				checkDestructure(
					ctx, commonTypes, structsAndAliasesDict, typeParamsScope, delayStructInsts,
					ast, none!Type))),
		(in ParamsAst.Varargs varargs) {
			Destructure param = checkDestructure(
				ctx, commonTypes, structsAndAliasesDict, typeParamsScope, delayStructInsts, varargs.param, none!Type);
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
	in StructsAndAliasesDict structsAndAliasesDict,
	DelayStructInsts delayStructInsts
) =>
	ReturnTypeAndParams(
		typeFromAst(ctx, commonTypes, returnTypeAst, structsAndAliasesDict, typeParams, delayStructInsts),
		checkParams(ctx, commonTypes, paramsAst, structsAndAliasesDict, typeParams, delayStructInsts));

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
	in StructsAndAliasesDict structsAndAliasesDict,
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
					ctx, commonTypes, x.returnType, x.params, typeParams, structsAndAliasesDict, noDelayStructInsts);
				Destructure[] params = rp.params.match!(Destructure[])(
					(Destructure[] x) =>
						x,
					(ref Params.Varargs _) =>
						todo!(Destructure[])("diag: no varargs in spec"));
				return SpecDeclSig(x.docComment, posInFile(ctx, x.range.start), x.name, rp.returnType, small(params));
			})));

SpecDecl[] checkSpecDeclsInitial(
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	ref StructsAndAliasesDict structsAndAliasesDict,
	in SpecDeclAst[] asts,
) =>
	map(ctx.alloc, asts, (ref SpecDeclAst ast) {
		TypeParam[] typeParams = checkTypeParams(ctx, ast.typeParams);
		SpecDeclBody body_ =
			checkSpecDeclBody(ctx, commonTypes, typeParams, structsAndAliasesDict, ast.range, ast.name, ast.body_);
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
	ref StructsAndAliasesDict structsAndAliasesDict,
	ref SpecsDict specsDict,
	in SpecDeclAst[] asts,
	SpecDecl[] specs,
) {
	MutArr!(SpecInst*) delaySpecInsts;

	zip!(SpecDeclAst, SpecDecl)(asts, specs, (ref SpecDeclAst ast, ref SpecDecl spec) {
		spec.parents = mapOp!(immutable SpecInst*, TypeAst)(ctx.alloc, ast.parents, (ref TypeAst parent) =>
			checkFunModifierNonSpecial(
				ctx, commonTypes, structsAndAliasesDict, specsDict, spec.typeParams, parent,
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
	in StructsAndAliasesDict structsAndAliasesDict,
	StructAlias[] aliases,
	in StructAliasAst[] asts,
	ref MutArr!(StructInst*) delayStructInsts,
) {
	zip!(StructAlias, StructAliasAst)(aliases, asts, (ref StructAlias structAlias, ref StructAliasAst ast) {
		Type type = typeFromAst(
			ctx,
			commonTypes,
			ast.target,
			structsAndAliasesDict,
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

StructsAndAliasesDict buildStructsAndAliasesDict(ref CheckCtx ctx, StructDecl[] structs, StructAlias[] aliases) {
	DictBuilder!(Sym, StructOrAlias) builder;
	foreach (StructDecl* decl; ptrsRange(structs))
		addToDeclsDict!StructOrAlias(ctx, builder, StructOrAlias(decl), Diag.DuplicateDeclaration.Kind.structOrAlias);
	foreach (StructAlias* alias_; ptrsRange(aliases))
		addToDeclsDict!StructOrAlias(ctx, builder, StructOrAlias(alias_), Diag.DuplicateDeclaration.Kind.structOrAlias);
	return finishDict(ctx.alloc, builder);
}

VarDecl[] checkVars(
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	in StructsAndAliasesDict structsAndAliasesDict,
	in VarDeclAst[] asts,
) =>
	map(ctx.alloc, asts, (ref VarDeclAst ast) =>
		checkVarDecl(ctx, commonTypes, structsAndAliasesDict, ast));

VarDecl checkVarDecl(
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	in StructsAndAliasesDict structsAndAliasesDict,
	in VarDeclAst ast,
) {
	if (!empty(ast.typeParams))
		todo!void("diag");
	return VarDecl(
		FileAndPos(ctx.fileIndex, ast.range.start),
		copySafeCStr(ctx.alloc, ast.docComment),
		ast.visibility,
		ast.name,
		ast.kind,
		typeFromAstNoTypeParamsNeverDelay(ctx, commonTypes, ast.type, structsAndAliasesDict),
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

void addToDeclsDict(T)(
	ref CheckCtx ctx,
	ref DictBuilder!(Sym, T) builder,
	T added,
	Diag.DuplicateDeclaration.Kind kind,
) {
	Opt!T old = tryAddToDict(ctx.alloc, builder, added.name, added);
	if (has(old))
		addDiag(ctx, added.range, Diag(Diag.DuplicateDeclaration(kind, added.name)));
}

immutable struct FunsAndDict {
	FunDecl[] funs;
	Test[] tests;
	FunsDict funsDict;
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
	in StructsAndAliasesDict structsAndAliasesDict,
	in SpecsDict specsDict,
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
						ctx, commonTypes, structsAndAliasesDict, specsDict, typeParamsScope, x, noDelaySpecInsts)));
	return FunFlagsAndSpecs(checkFunFlags(ctx, range, allFlags), specs);
}

Opt!(SpecInst*) checkFunModifierNonSpecial(
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	in StructsAndAliasesDict structsAndAliasesDict,
	in SpecsDict specsDict,
	TypeParam[] typeParamsScope,
	in TypeAst ast,
	DelaySpecInsts delaySpecInsts,
) {
	if (ast.isA!NameAndRange) {
		return specFromAst(
			ctx, commonTypes, structsAndAliasesDict, specsDict, typeParamsScope,
			none!(TypeAst*), ast.as!NameAndRange, delaySpecInsts);
	} else if (ast.isA!(TypeAst.SuffixName*)) {
		TypeAst.SuffixName* n = ast.as!(TypeAst.SuffixName*);
		return specFromAst(
			ctx, commonTypes, structsAndAliasesDict, specsDict, typeParamsScope, some(&n.left), n.name, delaySpecInsts);
	} else {
		addDiag(ctx, range(ast, ctx.allSymbols), Diag(Diag.SpecNameMissing()));
		return none!(SpecInst*);
	}
}

FunFlags checkFunFlags(ref CheckCtx ctx, RangeWithinFile range, FunModifierAst.Special.Flags flags) {
	void warnRedundant(Sym modifier, Sym redundantModifier) {
		addDiag(ctx, range, Diag(Diag.FunModifierRedundant(modifier, redundantModifier)));
	}

	bool builtin = (flags & FunModifierAst.Special.Flags.builtin) != 0;
	bool extern_ = (flags & FunModifierAst.Special.Flags.extern_) != 0;
	bool explicitNoctx = (flags & FunModifierAst.Special.Flags.noctx) != 0;
	bool forceCtx = (flags & FunModifierAst.Special.Flags.forceCtx) != 0;
	bool summon = (flags & FunModifierAst.Special.Flags.summon) != 0;
	bool trusted = (flags & FunModifierAst.Special.Flags.trusted) != 0;
	bool explicitUnsafe = (flags & FunModifierAst.Special.Flags.unsafe) != 0;

	bool implicitUnsafe = extern_;
	bool unsafe = explicitUnsafe || implicitUnsafe;
	bool implicitNoctx = extern_;
	bool noctx = explicitNoctx || implicitNoctx;

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
	if (implicitNoctx && explicitNoctx)
		warnRedundant(bodyModifier(), sym!"noctx");
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
		addDiag(ctx, range, Diag(Diag.FunModifierConflict(bodyModifiers[0], bodyModifiers[1])));
	}
	return FunFlags.regular(noctx, summon, safety, specialBody, forceCtx);
}

FunsAndDict checkFuns(
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	in SpecsDict specsDict,
	StructDecl[] structs,
	in StructsAndAliasesDict structsAndAliasesDict,
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
			structsAndAliasesDict,
			noDelayStructInsts);
		FunFlagsAndSpecs flagsAndSpecs = checkFunModifiers(
			ctx, commonTypes, funAst.range, funAst.modifiers, structsAndAliasesDict, specsDict, typeParams);
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
			funDeclForFileImportOrExport(ctx, commonTypes, structsAndAliasesDict, f, Visibility.private_));
	foreach (ref ImportOrExportFile f; fileExports)
		exactSizeArrBuilderAdd(
			funsBuilder,
			funDeclForFileImportOrExport(ctx, commonTypes, structsAndAliasesDict, f, Visibility.public_));

	foreach (StructDecl* struct_; ptrsRange(structs))
		addFunsForStruct(ctx, funsBuilder, commonTypes, struct_);
	foreach (VarDecl* var; ptrsRange(vars))
		addFunsForVar(ctx, funsBuilder, commonTypes, var);
	FunDecl[] funs = finish(funsBuilder);

	FunsDict funsDict = buildMultiDict!(Sym, immutable FunDecl*, FunDecl)(
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
							structsAndAliasesDict,
							funsDict,
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
		fun.setBody(getFileImportFunctionBody(ctx, commonTypes, structsAndAliasesDict, funsDict, *fun, f));
	}
	foreach (size_t i, ref ImportOrExportFile f; fileExports) {
		FunDecl* fun = &funs[asts.length + fileImports.length + i];
		fun.setBody(getFileImportFunctionBody(ctx, commonTypes, structsAndAliasesDict, funsDict, *fun, f));
	}

	Test[] tests = map(ctx.alloc, testAsts, (scope ref TestAst ast) {
		Type voidType = Type(commonTypes.void_);
		if (!has(ast.body_))
			todo!void("diag: test needs body");
		return Test(checkFunctionBody(
			ctx,
			structsAndAliasesDict,
			commonTypes,
			funsDict,
			voidType,
			[],
			[],
			[],
			FunFlags.unsafeSummon,
			force(ast.body_)));
	});

	return FunsAndDict(funs, tests, funsDict);
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
	in StructsAndAliasesDict structsAndAliasesDict,
	ref FunsDict funsDict,
	ref FunDecl f,
	ref ImportOrExportFile ie,
) =>
	ie.content.match!FunBody(
		(immutable ubyte[] bytes) =>
			FunBody(FunBody.FileBytes(bytes)),
		(SafeCStr str) {
			ExprAst ast = ExprAst(
				f.range.range,
				ExprAstKind(LiteralStringAst(strOfSafeCStr(str))));
			return FunBody(getExprFunctionBody(ctx, commonTypes, structsAndAliasesDict, funsDict, f, ast));
		});

FunBody.ExpressionBody getExprFunctionBody(
	ref CheckCtx ctx,
	in CommonTypes commonTypes,
	in StructsAndAliasesDict structsAndAliasesDict,
	in FunsDict funsDict,
	in FunDecl f,
	in ExprAst e,
) =>
	FunBody.ExpressionBody(checkFunctionBody(
		ctx,
		structsAndAliasesDict,
		commonTypes,
		funsDict,
		f.returnType,
		f.typeParams,
		paramsArray(f.params),
		f.specs,
		f.flags,
		e));

FunDecl funDeclForFileImportOrExport(
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	in StructsAndAliasesDict structsAndAliasesDict,
	in ImportOrExportFile a,
	Visibility visibility,
) =>
	FunDecl(
		safeCStr!"",
		visibility,
		FileAndPos(ctx.fileIndex, a.range.start),
		a.name,
		[],
		typeForFileImport(ctx, commonTypes, structsAndAliasesDict, a.range, a.type),
		Params([]),
		FunFlags.generatedNoCtx,
		[]);

Type typeForFileImport(
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	in StructsAndAliasesDict structsAndAliasesDict,
	RangeWithinFile range,
	ImportFileType type,
) {
	final switch (type) {
		case ImportFileType.nat8Array:
			TypeAst nat8 = TypeAst(NameAndRange(range.start, sym!"nat8"));
			TypeAst.SuffixName suffixName = TypeAst.SuffixName(nat8, NameAndRange(range.start, sym!"array"));
			scope TypeAst arrayNat8 = TypeAst(&suffixName);
			return typeFromAstNoTypeParamsNeverDelay(ctx, commonTypes, arrayNat8, structsAndAliasesDict);
		case ImportFileType.str:
			//TODO: this sort of duplicates 'getStrType'
			TypeAst ast = TypeAst(NameAndRange(range.start, sym!"string"));
			return typeFromAstNoTypeParamsNeverDelay(ctx, commonTypes, ast, structsAndAliasesDict);
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

SpecsDict buildSpecsDict(ref CheckCtx ctx, SpecDecl[] specs) {
	DictBuilder!(Sym, SpecDecl*) res;
	foreach (SpecDecl* spec; ptrsRange(specs))
		addToDeclsDict(ctx, res, spec, Diag.DuplicateDeclaration.Kind.spec);
	return finishDict(ctx.alloc, res);
}

Module checkWorkerAfterCommonTypes(
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	ref StructsAndAliasesDict structsAndAliasesDict,
	StructAlias[] structAliases,
	StructDecl[] structs,
	ref MutArr!(StructInst*) delayStructInsts,
	FileIndex fileIndex,
	ref ImportsAndExports importsAndExports,
	in FileAst ast,
) {
	checkStructBodies(ctx, commonTypes, structsAndAliasesDict, structs, ast.structs, delayStructInsts);

	while (!mutArrIsEmpty(delayStructInsts)) {
		StructInst* i = mustPop(delayStructInsts);
		i.instantiatedTypes =
			instantiateStructTypes(ctx.alloc, ctx.programState, i.declAndArgs, someMut(ptrTrustMe(delayStructInsts)));
	}

	VarDecl[] vars = checkVars(ctx, commonTypes, structsAndAliasesDict, ast.vars);
	SpecDecl[] specs = checkSpecDeclsInitial(ctx, commonTypes, structsAndAliasesDict, ast.specs);
	SpecsDict specsDict = buildSpecsDict(ctx, specs);
	checkSpecDeclParents(ctx, commonTypes, structsAndAliasesDict, specsDict, ast.specs, specs);
	FunsAndDict funsAndDict = checkFuns(
		ctx,
		commonTypes,
		specsDict,
		structs,
		structsAndAliasesDict,
		vars,
		importsAndExports.fileImports,
		importsAndExports.fileExports,
		ast.funs,
		ast.tests);
	checkForUnused(ctx, structAliases, structs, specs, funsAndDict.funs);
	return Module(
		fileIndex,
		copySafeCStr(ctx.alloc, ast.docComment),
		importsAndExports.moduleImports,
		importsAndExports.moduleExports,
		structs, vars, specs, funsAndDict.funs, funsAndDict.tests,
		getAllExportedNames(
			ctx.alloc,
			ctx.diagsBuilder,
			importsAndExports.moduleExports,
			structsAndAliasesDict,
			specsDict,
			funsAndDict.funsDict,
			fileIndex));
}

Dict!(Sym, NameReferents) getAllExportedNames(
	ref Alloc alloc,
	scope ref DiagnosticsBuilder diagsBuilder,
	in ImportOrExport[] reExports,
	in StructsAndAliasesDict structsAndAliasesDict,
	in SpecsDict specsDict,
	in FunsDict funsDict,
	FileIndex fileIndex,
) {
	MutDict!(Sym, NameReferents) res;
	void addExport(Sym name, NameReferents cur, FileAndRange range) {
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
				dictEachIn!(Sym, NameReferents)(
					m.module_.allExportedNames,
					(in Sym name, in NameReferents value) {
						addExport(name, value, FileAndRange(fileIndex, force(e.importSource)));
					});
			},
			(in ImportOrExportKind.ModuleNamed m) {
				foreach (Sym name; m.names) {
					Opt!NameReferents value = m.module_.allExportedNames[name];
					if (has(value))
						addExport(name, force(value), FileAndRange(fileIndex, force(e.importSource)));
				}
			});
	dictEach!(Sym, StructOrAlias)(
		structsAndAliasesDict,
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
	dictEach!(Sym, SpecDecl*)(specsDict, (Sym name, ref SpecDecl* x) {
		final switch (x.visibility) {
			case Visibility.private_:
				break;
			case Visibility.internal:
			case Visibility.public_:
				addExport(name, NameReferents(none!StructOrAlias, some(x), []), x.range);
				break;
		}
	});
	multiDictEach!(Sym, immutable FunDecl*)(funsDict, (Sym name, immutable FunDecl*[] funs) {
		immutable FunDecl*[] funDecls = filter!(immutable FunDecl*)(alloc, funs, (in immutable FunDecl* x) =>
			x.visibility != Visibility.private_);
		if (!empty(funDecls))
			addExport(
				name,
				NameReferents(none!StructOrAlias, none!(SpecDecl*), funDecls),
				// This argument doesn't matter because a function never results in a duplicate export error
				FileAndRange(fileIndex, RangeWithinFile.empty));
	});

	return moveToDict!(Sym, NameReferents)(alloc, res);
}

BootstrapCheck checkWorker(
	ref Alloc alloc,
	scope ref Perf perf,
	scope ref AllSymbols allSymbols,
	scope ref DiagnosticsBuilder diagsBuilder,
	ref ProgramState programState,
	ref ImportsAndExports importsAndExports,
	in PathAndAst pathAndAst,
	in CommonTypes delegate(
		ref CheckCtx,
		in StructsAndAliasesDict,
		scope ref MutArr!(StructInst*),
	) @safe @nogc pure nothrow getCommonTypes,
) {
	checkImportsOrExports(alloc, diagsBuilder, pathAndAst.fileIndex, importsAndExports.moduleImports);
	checkImportsOrExports(alloc, diagsBuilder, pathAndAst.fileIndex, importsAndExports.moduleExports);
	FileAst ast = pathAndAst.ast;
	CheckCtx ctx = CheckCtx(
		ptrTrustMe(alloc),
		ptrTrustMe(perf),
		ptrTrustMe(programState),
		ptrTrustMe(allSymbols),
		pathAndAst.fileIndex,
		ImportsAndReExports(importsAndExports.moduleImports, importsAndExports.moduleExports),
		ptrTrustMe(diagsBuilder));

	// Since structs may refer to each other, first get a structsAndAliasesDict, *then* fill in bodies
	StructDecl[] structs = checkStructsInitial(ctx, ast.structs);
	StructAlias[] structAliases = checkStructAliasesInitial(ctx, ast.structAliases);
	StructsAndAliasesDict structsAndAliasesDict = buildStructsAndAliasesDict(ctx, structs, structAliases);

	// We need to create StructInsts when filling in struct bodies.
	// But when creating a StructInst, we usually want to fill in its body.
	// In case the decl body isn't available yet,
	// we'll delay creating the StructInst body, which isn't needed until expr checking.
	MutArr!(StructInst*) delayStructInsts;

	CommonTypes commonTypes = getCommonTypes(ctx, structsAndAliasesDict, delayStructInsts);

	checkStructAliasTargets(
		ctx,
		commonTypes,
		structsAndAliasesDict,
		structAliases,
		ast.structAliases,
		delayStructInsts);

	Module res = checkWorkerAfterCommonTypes(
		ctx,
		commonTypes,
		structsAndAliasesDict,
		structAliases,
		structs,
		delayStructInsts,
		pathAndAst.fileIndex,
		importsAndExports,
		ast);
	return BootstrapCheck(res, commonTypes);
}

void checkImportsOrExports(
	ref Alloc alloc,
	scope ref DiagnosticsBuilder diags,
	FileIndex thisFile,
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
							FileAndRange(thisFile, force(x.importSource)),
							Diag(Diag.ImportRefersToNothing(name)));
			});
}
