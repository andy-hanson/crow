module frontend.check.check;

@safe @nogc pure nothrow:

import frontend.check.checkCtx : addDiag, CheckCtx, checkForUnused, newUsedImportsAndReExports, posInFile, rangeInFile;
import frontend.check.checkExpr : checkFunctionBody;
import frontend.check.checkStructs : checkStructBodies, checkStructsInitial;
import frontend.check.dicts :
	FunDeclAndIndex,
	FunsDict,
	ModuleLocalAliasIndex,
	ModuleLocalFunIndex,
	ModuleLocalSpecIndex,
	ModuleLocalStructIndex,
	ModuleLocalStructOrAliasIndex,
	SpecDeclAndIndex,
	SpecsDict,
	StructsAndAliasesDict,
	StructOrAliasAndIndex;
import frontend.check.funsForStruct : addFunsForStruct, countFunsForStruct;
import frontend.check.instantiate :
	DelaySpecInsts,
	DelayStructInsts,
	instantiateSpec,
	instantiateSpecParents,
	instantiateStruct,
	instantiateStructBody,
	noDelaySpecInsts,
	noDelayStructInsts,
	TypeArgsArray,
	typeArgsArray;
import frontend.check.typeFromAst :
	checkTypeParams, getTypeArgsForSpecIfNumberMatches, tryFindSpec, typeFromAst, typeFromAstNoTypeParamsNeverDelay;
import frontend.diagnosticsBuilder : addDiagnostic, DiagnosticsBuilder;
import frontend.parse.ast :
	ExprAst,
	ExprAstKind,
	FileAst,
	FunDeclAst,
	FunModifierAst,
	LiteralStringAst,
	NameAndRange,
	ParamAst,
	ParamsAst,
	range,
	rangeOfNameAndRange,
	SpecBodyAst,
	SpecDeclAst,
	SpecSigAst,
	StructAliasAst,
	TestAst,
	TypeAst;
import frontend.programState : ProgramState;
import model.diag : Diag;
import model.model :
	arity,
	arityIsNonZero,
	body_,
	CommonTypes,
	decl,
	Expr,
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
	okIfUnused,
	Param,
	Params,
	paramsArray,
	Purity,
	range,
	setBody,
	setTarget,
	SpecBody,
	SpecDecl,
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
	Visibility,
	visibility;
import util.alloc.alloc : Alloc;
import util.col.arr : empty, only, ptrsRange, small;
import util.col.arrBuilder : add, ArrBuilder, finishArr;
import util.col.arrUtil : cat, eachPair, map, mapOp, mapToMut, mapWithIndex, zip, zipPtrFirst;
import util.col.dict : Dict, dictEach, dictEachIn, hasKey, KeyValuePair;
import util.col.dictBuilder : DictBuilder, finishDict, tryAddToDict;
import util.col.enumDict : EnumDict;
import util.col.exactSizeArrBuilder : ExactSizeArrBuilder, exactSizeArrBuilderAdd, finish, newExactSizeArrBuilder;
import util.col.fullIndexDict : FullIndexDict, fullIndexDictOfArr, fullIndexDictZipPtrFirst, makeFullIndexDict_mut;
import util.col.multiDict : buildMultiDict, multiDictEach;
import util.col.mutArr : mustPop, MutArr, mutArrIsEmpty;
import util.col.mutDict : insertOrUpdate, moveToDict, MutDict;
import util.col.mutMaxArr :
	isFull, mustPop, MutMaxArr, mutMaxArr, mutMaxArrSize, push, pushIfUnderMaxSize, tempAsArr, toArray;
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
	Opt!StructOrAliasAndIndex res = structsAndAliasesDict[name];
	if (has(res)) {
		// TODO: may fail -- builtin Template should not be an alias
		StructDecl* decl = force(res).structOrAlias.as!(StructDecl*);
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
	Opt!StructOrAliasAndIndex opStructOrAlias = structsAndAliasesDict[name];
	return has(opStructOrAlias)
		? instantiateNonTemplateStructOrAlias(
			alloc,
			programState,
			delayedStructInsts,
			force(opStructOrAlias).structOrAlias)
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

	StructDecl* byVal = getDecl!"by-val"(1);
	StructDecl* array = getDecl!"array"(1);
	StructDecl* future = getDecl!"future"(1);
	StructDecl* namedVal = getDecl!"named-val"(1);
	StructDecl* opt = getDecl!"option"(1);
	StructDecl* pointerConst = getDecl!"const-pointer"(1);
	StructDecl* pointerMut = getDecl!"mut-pointer"(1);
	StructDecl*[10] funStructs = [
		getDecl!"fun0"(1),
		getDecl!"fun1"(2),
		getDecl!"fun2"(3),
		getDecl!"fun3"(4),
		getDecl!"fun4"(5),
		getDecl!"fun5"(6),
		getDecl!"fun6"(7),
		getDecl!"fun7"(8),
		getDecl!"fun8"(9),
		getDecl!"fun9"(10),
	];
	StructDecl*[10] funActStructs = [
		getDecl!"fun-act0"(1),
		getDecl!"fun-act1"(2),
		getDecl!"fun-act2"(3),
		getDecl!"fun-act3"(4),
		getDecl!"fun-act4"(5),
		getDecl!"fun-act5"(6),
		getDecl!"fun-act6"(7),
		getDecl!"fun-act7"(8),
		getDecl!"fun-act8"(9),
		getDecl!"fun-act9"(10),
	];
	StructDecl*[10] funPointerStructs = [
		getDecl!"fun-pointer0"(1),
		getDecl!"fun-pointer1"(2),
		getDecl!"fun-pointer2"(3),
		getDecl!"fun-pointer3"(4),
		getDecl!"fun-pointer4"(5),
		getDecl!"fun-pointer5"(6),
		getDecl!"fun-pointer6"(7),
		getDecl!"fun-pointer7"(8),
		getDecl!"fun-pointer8"(9),
		getDecl!"fun-pointer9"(10),
	];
	StructDecl*[10] funRefStructs = [
		getDecl!"fun-ref0"(1),
		getDecl!"fun-ref1"(2),
		getDecl!"fun-ref2"(3),
		getDecl!"fun-ref3"(4),
		getDecl!"fun-ref4"(5),
		getDecl!"fun-ref5"(6),
		getDecl!"fun-ref6"(7),
		getDecl!"fun-ref7"(8),
		getDecl!"fun-ref8"(9),
		getDecl!"fun-ref9"(10),
	];

	StructDecl* constPointer = getDecl!"const-pointer"(1);
	StructInst* cStr = instantiateStruct(
		ctx.alloc, ctx.programState, constPointer, [Type(char8)], someMut(ptrTrustMe(delayedStructInsts)));

	return CommonTypes(
		bool_,
		char8,
		cStr,
		float32,
		float64,
		IntegralTypes(int8, int16, int32, int64, nat8, nat16, nat32, nat64),
		symbol,
		void_,
		byVal,
		array,
		future,
		namedVal,
		opt,
		pointerConst,
		pointerMut,
		immutable EnumDict!(FunKind, StructDecl*[10])([funStructs, funActStructs, funRefStructs, funPointerStructs]));
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
		(in ParamAst[] asts) {
			Param[] params = mapWithIndex!(Param, ParamAst)(
				ctx.alloc,
				asts,
				(size_t index, scope ref ParamAst ast) =>
					checkParam(ctx, commonTypes, structsAndAliasesDict, typeParamsScope, delayStructInsts, ast, index));
			eachPair!Param(params, (in Param x, in Param y) {
				if (has(x.name) && has(y.name) && force(x.name) == force(y.name))
					addDiag(ctx, y.range, Diag(Diag.DuplicateDeclaration(
						Diag.DuplicateDeclaration.Kind.paramOrLocal, force(y.name))));
			});
			return Params(params);
		},
		(in ParamsAst.Varargs varargs) {
			Param param = checkParam(
				ctx, commonTypes, structsAndAliasesDict, typeParamsScope, delayStructInsts, varargs.param, 0);
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
				addDiag(ctx, varargs.param.range, Diag(Diag.VarargsParamMustBeArray()));
			return Params(allocate(ctx.alloc,
				Params.Varargs(param, has(elementType) ? force(elementType) : Type(Type.Bogus()))));
		});

Param checkParam(
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	in StructsAndAliasesDict structsAndAliasesDict,
	TypeParam[] typeParamsScope,
	ref DelayStructInsts delayStructInsts,
	in ParamAst ast,
	size_t index,
) =>
	Param(
		rangeInFile(ctx, ast.range),
		ast.name,
		typeFromAst(ctx, commonTypes, ast.type, structsAndAliasesDict, typeParamsScope, delayStructInsts),
		index);

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

SpecBody.Builtin.Kind getSpecBodyBuiltinKind(ref CheckCtx ctx, RangeWithinFile range, Sym name) {
	switch (name.value) {
		case sym!"data".value:
			return SpecBody.Builtin.Kind.data;
		case sym!"shared".value:
			return SpecBody.Builtin.Kind.shared_;
		default:
			addDiag(ctx, range, Diag(Diag.BuiltinUnsupported(name)));
			return SpecBody.Builtin.Kind.data;
	}
}

SpecBody checkSpecBody(
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	TypeParam[] typeParams,
	in StructsAndAliasesDict structsAndAliasesDict,
	RangeWithinFile range,
	Sym name,
	in SpecBodyAst ast,
) =>
	ast.matchIn!SpecBody(
		(in SpecBodyAst.Builtin) =>
			SpecBody(SpecBody.Builtin(getSpecBodyBuiltinKind(ctx, range, name))),
		(in SpecSigAst[] sigs) =>
			SpecBody(map(ctx.alloc, sigs, (ref SpecSigAst it) {
				ReturnTypeAndParams rp = checkReturnTypeAndParams(
					ctx, commonTypes, it.returnType, it.params, typeParams, structsAndAliasesDict, noDelayStructInsts);
				return SpecDeclSig(it.docComment, posInFile(ctx, it.range.start), it.name, rp.returnType, rp.params);
			})));

SpecDecl[] checkSpecDeclsInitial(
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	ref StructsAndAliasesDict structsAndAliasesDict,
	in SpecDeclAst[] asts,
) =>
	map(ctx.alloc, asts, (ref SpecDeclAst ast) {
		TypeParam[] typeParams = checkTypeParams(ctx, ast.typeParams);
		SpecBody body_ =
			checkSpecBody(ctx, commonTypes, typeParams, structsAndAliasesDict, ast.range, ast.name, ast.body_);
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
	DictBuilder!(Sym, StructOrAliasAndIndex) builder;
	void warnOnDup(Sym name, FileAndRange range, Opt!StructOrAliasAndIndex opt) {
		if (has(opt))
			addDiag(ctx, range, Diag(Diag.DuplicateDeclaration(Diag.DuplicateDeclaration.Kind.structOrAlias, name)));
	}
	foreach (size_t index; 0 .. structs.length) {
		StructDecl* decl = &structs[index];
		Sym name = decl.name;
		warnOnDup(name, decl.range, tryAddToDict(ctx.alloc, builder, name, StructOrAliasAndIndex(
			StructOrAlias(decl),
			ModuleLocalStructOrAliasIndex(index))));
	}
	foreach (size_t index; 0 .. aliases.length) {
		StructAlias* alias_ = &aliases[index];
		Sym name = alias_.name;
		warnOnDup(name, alias_.range, tryAddToDict(ctx.alloc, builder, name, StructOrAliasAndIndex(
			StructOrAlias(alias_),
			ModuleLocalStructOrAliasIndex(index))));
	}
	return finishDict(ctx.alloc, builder);
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
				(in FunModifierAst.ExternOrGlobal x) {
					if (allFlags & x.flag)
						todo!void("diag: duplicate flag");
					allFlags |= x.flag;
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
		return checkSpecReference(
			ctx, commonTypes, structsAndAliasesDict, specsDict, typeParamsScope,
			none!(TypeAst*), ast.as!NameAndRange, delaySpecInsts);
	} else if (ast.isA!(TypeAst.SuffixName*)) {
		TypeAst.SuffixName* n = ast.as!(TypeAst.SuffixName*);
		return checkSpecReference(
			ctx, commonTypes, structsAndAliasesDict, specsDict, typeParamsScope, some(&n.left), n.name, delaySpecInsts);
	} else {
		addDiag(ctx, range(ast, ctx.allSymbols), Diag(Diag.SpecNameMissing()));
		return none!(SpecInst*);
	}

}

Opt!(SpecInst*) checkSpecReference(
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
		TypeArgsArray typeArgs = typeArgsArray();
		bool ok = getTypeArgsForSpecIfNumberMatches(
			typeArgs,
			ctx,
			commonTypes,
			rangeOfNameAndRange(specName, ctx.allSymbols),
			structsAndAliasesDict,
			spec,
			suffixLeft,
			typeParamsScope);
		return ok
			? some(instantiateSpec(ctx.alloc, ctx.programState, spec, tempAsArr(typeArgs), delaySpecInsts))
			: none!(SpecInst*);
	} else
		return none!(SpecInst*);
}

FunFlags checkFunFlags(ref CheckCtx ctx, RangeWithinFile range, FunModifierAst.Special.Flags flags) {
	void warnConflict(Sym modifier0, Sym modifier1) {
		addDiag(ctx, range, Diag(Diag.FunModifierConflict(modifier0, modifier1)));
	}
	void warnRedundant(Sym modifier, Sym redundantModifier) {
		addDiag(ctx, range, Diag(Diag.FunModifierRedundant(modifier, redundantModifier)));
	}

	bool builtin = (flags & FunModifierAst.Special.Flags.builtin) != 0;
	bool extern_ = (flags & FunModifierAst.Special.Flags.extern_) != 0;
	bool global = (flags & FunModifierAst.Special.Flags.global) != 0;
	bool explicitNoctx = (flags & FunModifierAst.Special.Flags.noctx) != 0;
	bool forceCtx = (flags & FunModifierAst.Special.Flags.forceCtx) != 0;
	bool summon = (flags & FunModifierAst.Special.Flags.summon) != 0;
	bool threadLocal = (flags & FunModifierAst.Special.Flags.thread_local) != 0;
	bool trusted = (flags & FunModifierAst.Special.Flags.trusted) != 0;
	bool explicitUnsafe = (flags & FunModifierAst.Special.Flags.unsafe) != 0;

	bool implicitUnsafe = extern_ || global || threadLocal;
	bool unsafe = explicitUnsafe || implicitUnsafe;
	bool implicitNoctx = extern_ || global || threadLocal;
	bool noctx = explicitNoctx || implicitNoctx;

	Sym bodyModifier() {
		return builtin
			? sym!"builtin"
			: extern_
			? sym!"extern"
			: global
			? sym!"global"
			: threadLocal
			? sym!"thread-local"
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
		: global
		? FunFlags.SpecialBody.global
		: threadLocal
		? FunFlags.SpecialBody.threadLocal
		: FunFlags.SpecialBody.none;
	if (builtin + extern_ + global + threadLocal > 1) {
		MutMaxArr!(2, Sym) bodyModifiers = mutMaxArr!(2, Sym);
		if (builtin) pushIfUnderMaxSize(bodyModifiers, sym!"builtin");
		if (extern_) pushIfUnderMaxSize(bodyModifiers, sym!"extern");
		if (global) pushIfUnderMaxSize(bodyModifiers, sym!"global");
		if (threadLocal) pushIfUnderMaxSize(bodyModifiers, sym!"thread-local");
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
	ImportOrExportFile[] fileImports,
	ImportOrExportFile[] fileExports,
	in FunDeclAst[] asts,
	in TestAst[] testAsts,
) {
	ExactSizeArrBuilder!FunDecl funsBuilder = newExactSizeArrBuilder!FunDecl(
		ctx.alloc,
		asts.length + fileImports.length + fileExports.length + countFunsForStruct(structs));
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
	FunDecl[] funs = finish(funsBuilder);
	FullIndexDict!(ModuleLocalFunIndex, bool) usedFuns =
		makeFullIndexDict_mut!(ModuleLocalFunIndex, bool)(ctx.alloc, funs.length, (size_t) => false);

	FunsDict funsDict = buildMultiDict!(Sym, FunDeclAndIndex, FunDecl)(
		ctx.alloc,
		funs,
		(size_t index, FunDecl* it) =>
			KeyValuePair!(Sym, FunDeclAndIndex)(
				it.name,
				FunDeclAndIndex(ModuleLocalFunIndex(index), it)));

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
							usedFuns,
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
					return FunBody(checkExternOrGlobalBody(
						ctx, fun, getExternTypeArg(funAst, FunModifierAst.Special.Flags.extern_), false));
				case FunFlags.SpecialBody.global:
					if (has(funAst.body_))
						todo!void("diag: global fun can't have body");
					return FunBody(checkExternOrGlobalBody(
						ctx, fun, getExternTypeArg(funAst, FunModifierAst.Special.Flags.global), true));
				case FunFlags.SpecialBody.threadLocal:
					if (has(funAst.body_))
						todo!void("diag: thraed-local fun can't have body");
					return FunBody(checkThreadLocalBody(ctx, commonTypes, fun));
			}
		}());
	});
	foreach (size_t i, ref ImportOrExportFile f; fileImports) {
		FunDecl* fun = &funs[asts.length + i];
		fun.setBody(getFileImportFunctionBody(
			ctx, commonTypes, structsAndAliasesDict, funsDict, usedFuns, *fun, f));
	}
	foreach (size_t i, ref ImportOrExportFile f; fileExports) {
		FunDecl* fun = &funs[asts.length + fileImports.length + i];
		fun.setBody(getFileImportFunctionBody(
			ctx, commonTypes, structsAndAliasesDict, funsDict, usedFuns, *fun, f));
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
			usedFuns,
			voidType,
			[],
			[],
			[],
			FunFlags.unsafeSummon,
			force(ast.body_)));
	});

	fullIndexDictZipPtrFirst!(ModuleLocalFunIndex, FunDecl, bool)(
		fullIndexDictOfArr!(ModuleLocalFunIndex, FunDecl)(funs),
		usedFuns,
		(ModuleLocalFunIndex _, FunDecl* fun, in bool used) {
			final switch (fun.visibility) {
				case Visibility.private_:
					if (!used && !okIfUnused(*fun))
						addDiag(ctx, fun.range, Diag(Diag.UnusedPrivateFun(fun)));
					break;
				case Visibility.internal:
				case Visibility.public_:
					break;
			}
		});

	return FunsAndDict(funs, tests, funsDict);
}

Opt!TypeAst getExternTypeArg(ref FunDeclAst a, FunModifierAst.Special.Flags externOrGlobalFlag) {
	foreach (ref FunModifierAst modifier; a.modifiers) {
		Opt!(Opt!TypeAst) res = modifier.match!(Opt!(Opt!TypeAst))(
			(FunModifierAst.Special x) =>
				x.flag == externOrGlobalFlag ? some(none!TypeAst) : none!(Opt!TypeAst),
			(FunModifierAst.ExternOrGlobal x) =>
				x.flag == externOrGlobalFlag ? some(some(*x.left)) : none!(Opt!TypeAst),
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
	ref FullIndexDict!(ModuleLocalFunIndex, bool) usedFuns,
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
			return FunBody(getExprFunctionBody(ctx, commonTypes, structsAndAliasesDict, funsDict, usedFuns, f, ast));
		});

Expr getExprFunctionBody(
	ref CheckCtx ctx,
	in CommonTypes commonTypes,
	in StructsAndAliasesDict structsAndAliasesDict,
	in FunsDict funsDict,
	scope ref FullIndexDict!(ModuleLocalFunIndex, bool) usedFuns,
	in FunDecl f,
	in ExprAst e,
) =>
	checkFunctionBody(
		ctx,
		structsAndAliasesDict,
		commonTypes,
		funsDict,
		usedFuns,
		f.returnType,
		f.typeParams,
		paramsArray(f.params),
		f.specs,
		f.flags,
		e);

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

FunBody.Extern checkExternOrGlobalBody(ref CheckCtx ctx, FunDecl* fun, in Opt!TypeAst typeArg, bool isGlobal) {
	Linkage funLinkage = Linkage.extern_;

	if (!empty(fun.typeParams))
		addDiag(ctx, fun.range, Diag(Diag.ExternFunForbidden(fun, Diag.ExternFunForbidden.Reason.hasTypeParams)));
	if (!empty(fun.specs))
		addDiag(ctx, fun.range, Diag(Diag.ExternFunForbidden(fun, Diag.ExternFunForbidden.Reason.hasSpecs)));

	if (!isLinkageAlwaysCompatible(funLinkage, linkageRange(fun.returnType)))
		addDiag(ctx, fun.range, Diag(Diag.LinkageWorseThanContainingFun(fun, fun.returnType, none!(Param*))));
	fun.params.match!void(
		(Param[] params) {
			foreach (Param* p; ptrsRange(params))
				if (!isLinkageAlwaysCompatible(funLinkage, linkageRange(p.type)))
					addDiag(ctx, p.range, Diag(Diag.LinkageWorseThanContainingFun(fun, p.type, some(p))));
		},
		(ref Params.Varargs) {
			addDiag(ctx, fun.range, Diag(Diag.ExternFunForbidden(fun, Diag.ExternFunForbidden.Reason.variadic)));
		});

	if (isGlobal && arityIsNonZero(arity(*fun)))
		todo!void("'global' fun has parameters");

	Sym libraryName = () {
		if (has(typeArg) && force(typeArg).isA!NameAndRange)
			return force(typeArg).as!NameAndRange.name;
		else {
			addDiag(ctx, fun.range, Diag(
				Diag.ExternFunForbidden(fun, Diag.ExternFunForbidden.Reason.missingLibraryName)));
			return sym!"bogus";
		}
	}();
	return FunBody.Extern(isGlobal, libraryName);
}

FunBody.ThreadLocal checkThreadLocalBody(ref CheckCtx ctx, in CommonTypes commonTypes, FunDecl* fun) {
	void err(Diag.ThreadLocalError.Kind kind) {
		addDiag(ctx, fun.range, Diag(Diag.ThreadLocalError(fun, kind)));
	}
	if (!empty(fun.typeParams))
		err(Diag.ThreadLocalError.Kind.hasTypeParams);
	if (!isPtrMutType(commonTypes, fun.returnType))
		err(Diag.ThreadLocalError.Kind.mustReturnPtrMut);
	if (!paramsIsEmpty(fun.params))
		err(Diag.ThreadLocalError.Kind.hasParams);
	if (!empty(fun.specs))
		err(Diag.ThreadLocalError.Kind.hasSpecs);
	return FunBody.ThreadLocal();
}

bool isPtrMutType(in CommonTypes commonTypes, Type a) =>
	a.isA!(StructInst*) && decl(*a.as!(StructInst*)) == commonTypes.ptrMut;

bool paramsIsEmpty(scope Params a) =>
	empty(paramsArray(a));

SpecsDict buildSpecsDict(ref CheckCtx ctx, SpecDecl[] specs) {
	DictBuilder!(Sym, SpecDeclAndIndex) res;
	foreach (size_t index; 0 .. specs.length) {
		SpecDecl* spec = &specs[index];
		Sym name = spec.name;
		Opt!SpecDeclAndIndex b = tryAddToDict(ctx.alloc, res, name, SpecDeclAndIndex(
			spec,
			ModuleLocalSpecIndex(index)));
		if (has(b))
			addDiag(ctx, force(b).decl.range, Diag(
				Diag.DuplicateDeclaration(Diag.DuplicateDeclaration.Kind.spec, name)));
	}
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
		setBody(*i, instantiateStructBody(
			ctx.alloc,
			ctx.programState,
			i.declAndArgs,
			someMut(ptrTrustMe(delayStructInsts))));
	}

	SpecDecl[] specs = checkSpecDeclsInitial(ctx, commonTypes, structsAndAliasesDict, ast.specs);
	SpecsDict specsDict = buildSpecsDict(ctx, specs);
	checkSpecDeclParents(ctx, commonTypes, structsAndAliasesDict, specsDict, ast.specs, specs);
	FunsAndDict funsAndDict = checkFuns(
		ctx,
		commonTypes,
		specsDict,
		structs,
		structsAndAliasesDict,
		importsAndExports.fileImports,
		importsAndExports.fileExports,
		ast.funs,
		ast.tests);
	checkForUnused(ctx, structAliases, structs, specs);
	return Module(
		fileIndex,
		copySafeCStr(ctx.alloc, ast.docComment),
		importsAndExports.moduleImports,
		importsAndExports.moduleExports,
		structs, specs, funsAndDict.funs, funsAndDict.tests,
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
	dictEach!(Sym, StructOrAliasAndIndex)(
		structsAndAliasesDict,
		(Sym name, ref StructOrAliasAndIndex it) {
			final switch (visibility(it.structOrAlias)) {
				case Visibility.private_:
					break;
				case Visibility.internal:
				case Visibility.public_:
					addExport(
						name,
						NameReferents(some(it.structOrAlias), none!(SpecDecl*), []),
						range(it.structOrAlias));
					break;
			}
		});
	dictEach!(Sym, SpecDeclAndIndex)(specsDict, (Sym name, ref SpecDeclAndIndex it) {
		final switch (it.decl.visibility) {
			case Visibility.private_:
				break;
			case Visibility.internal:
			case Visibility.public_:
				addExport(name, NameReferents(none!StructOrAlias, some(it.decl), []), it.decl.range);
				break;
		}
	});
	multiDictEach!(Sym, FunDeclAndIndex)(funsDict, (Sym name, FunDeclAndIndex[] funs) {
		immutable FunDecl*[] funDecls = mapOp!(immutable FunDecl*, FunDeclAndIndex)(
			alloc,
			funs,
			(ref FunDeclAndIndex it) {
				final switch (it.decl.visibility) {
					case Visibility.private_:
						return none!(FunDecl*);
					case Visibility.internal:
					case Visibility.public_:
						return some(it.decl);
				}
			});
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
		importsAndExports.moduleImports,
		importsAndExports.moduleExports,
		// TODO: use temp alloc
		newUsedImportsAndReExports(alloc, importsAndExports.moduleImports, importsAndExports.moduleExports),
		// TODO: use temp alloc
		makeFullIndexDict_mut!(ModuleLocalAliasIndex, bool)(
			alloc, ast.structAliases.length, (ModuleLocalAliasIndex _) => false),
		// TODO: use temp alloc
		makeFullIndexDict_mut!(ModuleLocalStructIndex, bool)(
			alloc, ast.structs.length, (ModuleLocalStructIndex _) => false),
		// TODO: use temp alloc
		makeFullIndexDict_mut!(ModuleLocalSpecIndex, bool)(
			alloc, ast.specs.length, (ModuleLocalSpecIndex _) => false),
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
