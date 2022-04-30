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
	DelayStructInsts,
	instantiateSpec,
	instantiateStruct,
	instantiateStructBody,
	TypeArgsArray,
	typeArgsArray,
	TypeParamsScope;
import frontend.check.typeFromAst :
	checkTypeParams, tryFindSpec, typeArgsFromAsts, typeFromAst, typeFromAstNoTypeParamsNeverDelay;
import frontend.diagnosticsBuilder : addDiagnostic, DiagnosticsBuilder;
import frontend.parse.ast :
	ExprAst,
	ExprAstKind,
	FileAst,
	FunBodyAst,
	FunDeclAst,
	FunDeclAstFlags,
	LiteralAst,
	matchFunBodyAst,
	matchParamsAst,
	matchSpecBodyAst,
	NameAndRange,
	ParamAst,
	ParamsAst,
	SigAst,
	SpecBodyAst,
	SpecDeclAst,
	SpecSigAst,
	SpecUseAst,
	StructAliasAst,
	TestAst,
	TypeAst;
import frontend.programState : ProgramState;
import model.diag : Diag;
import model.model :
	arity,
	arityIsNonZero,
	asStructDecl,
	asStructInst,
	body_,
	CommonTypes,
	decl,
	Expr,
	FileContent,
	FunBody,
	FunDecl,
	FunFlags,
	FunKind,
	FunKindAndStructs,
	ImportFileType,
	ImportOrExport,
	ImportOrExportKind,
	IntegralTypes,
	isBogus,
	isLinkageAlwaysCompatible,
	isStructInst,
	Linkage,
	linkageRange,
	matchFileContent,
	matchImportOrExportKind,
	matchParams,
	matchStructOrAliasPtr,
	matchType,
	Module,
	name,
	NameReferents,
	noCtx,
	okIfUnused,
	Param,
	Params,
	params,
	paramsArray,
	Purity,
	range,
	returnType,
	setBody,
	setTarget,
	Sig,
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
import util.col.arr : castImmutable, empty, emptyArr, emptySmallArray, only, ptrAt, ptrsRange, sizeEq, small;
import util.col.arrBuilder : add, ArrBuilder, finishArr;
import util.col.arrUtil : cat, eachPair, map, mapOp, mapToMut, mapWithIndex, zipFirstMut, zipMutPtrFirst;
import util.col.dict : dictEach, hasKey, KeyValuePair, SymDict;
import util.col.dictBuilder : finishDict, SymDictBuilder, tryAddToDict;
import util.col.exactSizeArrBuilder : ExactSizeArrBuilder, exactSizeArrBuilderAdd, finish, newExactSizeArrBuilder;
import util.col.fullIndexDict :
	FullIndexDict, fullIndexDictCastImmutable, fullIndexDictOfArr, fullIndexDictZipPtrs, makeFullIndexDict_mut;
import util.col.multiDict : buildMultiDict, multiDictEach;
import util.col.mutArr : mustPop, MutArr, mutArrIsEmpty;
import util.col.mutDict : insertOrUpdate, moveToDict, MutSymDict;
import util.col.mutMaxArr : tempAsArr;
import util.col.str : copySafeCStr, SafeCStr, safeCStr, strOfSafeCStr;
import util.memory : allocate, allocateMut, overwriteMemory;
import util.opt : force, has, none, noneMut, Opt, some, someMut;
import util.perf : Perf;
import util.ptr : castImmutable, ptrTrustMe, ptrTrustMe_mut;
import util.sourceRange : FileAndPos, FileAndRange, FileIndex, RangeWithinFile;
import util.sym : AllSymbols, hashSym, shortSym, shortSymValue, Sym, symEq;
import util.util : todo, verify;

struct PathAndAst { //TODO:RENAME
	immutable FileIndex fileIndex;
	immutable FileAst ast;
}

struct BootstrapCheck {
	immutable Module module_;
	immutable CommonTypes commonTypes;
}

immutable(BootstrapCheck) checkBootstrap(
	ref Alloc alloc,
	ref Perf perf,
	ref AllSymbols allSymbols,
	ref DiagnosticsBuilder diagsBuilder,
	ref ProgramState programState,
	immutable PathAndAst pathAndAst,
) {
	static immutable ImportsAndExports emptyImportsAndExports = immutable ImportsAndExports([], [], [], []);
	return checkWorker(
		&alloc,
		&perf,
		&allSymbols,
		diagsBuilder,
		&programState,
		emptyImportsAndExports,
		pathAndAst,
		(ref CheckCtx ctx,
		ref immutable StructsAndAliasesDict structsAndAliasesDict,
		ref MutArr!(StructInst*) delayedStructInsts) =>
			getCommonTypes(ctx, structsAndAliasesDict, delayedStructInsts));
}

struct ImportsAndExports {
	immutable ImportOrExport[] moduleImports;
	immutable ImportOrExport[] moduleExports;
	immutable ImportOrExportFile[] fileImports;
	immutable ImportOrExportFile[] fileExports;
}

struct ImportOrExportFile {
	immutable RangeWithinFile range;
	immutable Sym name;
	immutable ImportFileType type;
	immutable FileContent content;
}

immutable(Module) check(
	ref Alloc alloc,
	ref Perf perf,
	ref AllSymbols allSymbols,
	ref DiagnosticsBuilder diagsBuilder,
	ref ProgramState programState,
	ref immutable ImportsAndExports importsAndExports,
	scope ref immutable PathAndAst pathAndAst,
	ref immutable CommonTypes commonTypes,
) {
	return checkWorker(
		&alloc,
		&perf,
		&allSymbols,
		diagsBuilder,
		&programState,
		importsAndExports,
		pathAndAst,
		(ref CheckCtx, ref immutable(StructsAndAliasesDict), ref MutArr!(StructInst*)) => commonTypes,
	).module_;
}

private:

immutable(Opt!(StructDecl*)) getCommonTemplateType(
	ref immutable StructsAndAliasesDict structsAndAliasesDict,
	immutable Sym name,
	immutable size_t expectedTypeParams,
) {
	immutable Opt!StructOrAliasAndIndex res = structsAndAliasesDict[name];
	if (has(res)) {
		// TODO: may fail -- builtin Template should not be an alias
		immutable StructDecl* decl = asStructDecl(force(res).structOrAlias);
		if (decl.typeParams.length != expectedTypeParams)
			todo!void("getCommonTemplateType");
		return some(decl);
	} else
		return none!(StructDecl*);
}

immutable(Opt!(StructInst*)) getCommonNonTemplateType(
	ref Alloc alloc,
	ref ProgramState programState,
	ref immutable StructsAndAliasesDict structsAndAliasesDict,
	immutable Sym name,
	ref MutArr!(StructInst*) delayedStructInsts,
) {
	immutable Opt!StructOrAliasAndIndex opStructOrAlias = structsAndAliasesDict[name];
	return has(opStructOrAlias)
		? instantiateNonTemplateStructOrAlias(
			alloc,
			programState,
			delayedStructInsts,
			force(opStructOrAlias).structOrAlias)
		: none!(StructInst*);
}

immutable(Opt!(StructInst*)) instantiateNonTemplateStructOrAlias(
	ref Alloc alloc,
	ref ProgramState programState,
	ref MutArr!(StructInst*) delayedStructInsts,
	immutable StructOrAlias structOrAlias,
) {
	verify(empty(typeParams(structOrAlias)));
	return matchStructOrAliasPtr!(immutable Opt!(StructInst*))(
		structOrAlias,
		(ref immutable StructAlias it) =>
			target(it),
		(immutable StructDecl* it) =>
			some(instantiateNonTemplateStructDecl(alloc, programState, delayedStructInsts, it)));
}

immutable(StructInst*) instantiateNonTemplateStructDecl(
	ref Alloc alloc,
	ref ProgramState programState,
	ref MutArr!(StructInst*) delayedStructInsts,
	immutable StructDecl* structDecl,
) {
	return instantiateStruct(alloc, programState, structDecl, [], someMut(ptrTrustMe_mut(delayedStructInsts)));
}

immutable(CommonTypes) getCommonTypes(
	ref CheckCtx ctx,
	ref immutable StructsAndAliasesDict structsAndAliasesDict,
	ref MutArr!(StructInst*) delayedStructInsts,
) {
	ArrBuilder!string missing = ArrBuilder!string();

	immutable(StructInst*) nonTemplate(immutable string name) {
		immutable Opt!(StructInst*) res = getCommonNonTemplateType(
			ctx.alloc,
			ctx.programState,
			structsAndAliasesDict,
			shortSym(name),
			delayedStructInsts);
		if (has(res))
			return force(res);
		else {
			add(ctx.alloc, missing, name);
			return instantiateNonTemplateStructDecl(
				ctx.alloc,
				ctx.programState,
				delayedStructInsts,
				bogusStructDecl(ctx.alloc, 0));
		}
	}

	immutable StructInst* bool_ = nonTemplate("bool");
	immutable StructInst* char8 = nonTemplate("char8");
	immutable StructInst* float32 = nonTemplate("float32");
	immutable StructInst* float64 = nonTemplate("float64");
	immutable StructInst* int8 = nonTemplate("int8");
	immutable StructInst* int16 = nonTemplate("int16");
	immutable StructInst* int32 = nonTemplate("int32");
	immutable StructInst* int64 = nonTemplate("int64");
	immutable StructInst* nat8 = nonTemplate("nat8");
	immutable StructInst* nat16 = nonTemplate("nat16");
	immutable StructInst* nat32 = nonTemplate("nat32");
	immutable StructInst* nat64 = nonTemplate("nat64");
	immutable StructInst* sym = nonTemplate("sym");
	immutable StructInst* void_ = nonTemplate("void");
	immutable StructInst* ctxStructInst = nonTemplate("ctx");

	immutable(StructDecl*) com(immutable string name, immutable size_t nTypeParameters) {
		immutable Opt!(StructDecl*) res =
			getCommonTemplateType(structsAndAliasesDict, shortSym(name), nTypeParameters);
		if (has(res))
			return force(res);
		else {
			add(ctx.alloc, missing, name);
			return bogusStructDecl(ctx.alloc, nTypeParameters);
		}
	}

	immutable StructDecl* byVal = com("by-val", 1);
	immutable StructDecl* arr = com("arr", 1);
	immutable StructDecl* fut = com("fut", 1);
	immutable StructDecl* namedVal = com("named-val", 1);
	immutable StructDecl* opt = com("opt", 1);
	immutable StructDecl* fun0 = com("fun0", 1);
	immutable StructDecl* fun1 = com("fun1", 2);
	immutable StructDecl* fun2 = com("fun2", 3);
	immutable StructDecl* fun3 = com("fun3", 4);
	immutable StructDecl* fun4 = com("fun4", 5);
	immutable StructDecl* funAct0 = com("fun-act0", 1);
	immutable StructDecl* funAct1 = com("fun-act1", 2);
	immutable StructDecl* funAct2 = com("fun-act2", 3);
	immutable StructDecl* funAct3 = com("fun-act3", 4);
	immutable StructDecl* funAct4 = com("fun-act4", 5);
	immutable StructDecl* funPtr0 = com("fun-ptr0", 1);
	immutable StructDecl* funPtr1 = com("fun-ptr1", 2);
	immutable StructDecl* funPtr2 = com("fun-ptr2", 3);
	immutable StructDecl* funPtr3 = com("fun-ptr3", 4);
	immutable StructDecl* funPtr4 = com("fun-ptr4", 5);
	immutable StructDecl* funPtr5 = com("fun-ptr5", 6);
	immutable StructDecl* funPtr6 = com("fun-ptr6", 7);
	immutable StructDecl* funPtr7 = com("fun-ptr7", 8);
	immutable StructDecl* funPtr8 = com("fun-ptr8", 9);
	immutable StructDecl* funPtr9 = com("fun-ptr9", 10);
	immutable StructDecl* funRef0 = com("fun-ref0", 1);
	immutable StructDecl* funRef1 = com("fun-ref1", 2);
	immutable StructDecl* funRef2 = com("fun-ref2", 3);
	immutable StructDecl* funRef3 = com("fun-ref3", 4);
	immutable StructDecl* funRef4 = com("fun-ref4", 5);

	immutable StructDecl* constPtr = com("const-ptr", 1);
	immutable StructInst* cStr = instantiateStruct(
		ctx.alloc, ctx.programState, constPtr, [immutable Type(char8)], someMut(ptrTrustMe_mut(delayedStructInsts)));

	immutable string[] missingArr = finishArr(ctx.alloc, missing);

	if (!empty(missingArr))
		addDiag(
			ctx,
			immutable FileAndRange(ctx.fileIndex, RangeWithinFile.empty),
			immutable Diag(immutable Diag.CommonTypesMissing(missingArr)));
	return immutable CommonTypes(
		bool_,
		char8,
		cStr,
		float32,
		float64,
		immutable IntegralTypes(
			int8,
			int16,
			int32,
			int64,
			nat8,
			nat16,
			nat32,
			nat64),
		sym,
		void_,
		ctxStructInst,
		byVal,
		arr,
		fut,
		namedVal,
		opt,
		[funPtr0, funPtr1, funPtr2, funPtr3, funPtr4, funPtr5, funPtr6, funPtr7, funPtr8, funPtr9],
		[
			immutable FunKindAndStructs(FunKind.plain, [fun0, fun1, fun2, fun3, fun4]),
			immutable FunKindAndStructs(FunKind.mut, [funAct0, funAct1, funAct2, funAct3, funAct4]),
			immutable FunKindAndStructs(FunKind.ref_, [funRef0, funRef1, funRef2, funRef3, funRef4])
		]);
}

immutable(StructDecl*) bogusStructDecl(ref Alloc alloc, immutable size_t nTypeParameters) {
	ArrBuilder!TypeParam typeParams;
	immutable FileAndRange fileAndRange = immutable FileAndRange(immutable FileIndex(0), RangeWithinFile.empty);
	foreach (immutable size_t i; 0 .. nTypeParameters)
		add(alloc, typeParams, immutable TypeParam(fileAndRange, shortSym("bogus"), i));
	StructDecl* res = allocateMut(alloc, StructDecl(
		fileAndRange,
		safeCStr!"",
		shortSym("bogus"),
		small(finishArr(alloc, typeParams)),
		Visibility.public_,
		Linkage.internal,
		Purity.data,
		false));
	setBody(*res, immutable StructBody(immutable StructBody.Bogus()));
	return castImmutable(res);
}

immutable(Params) checkParams(
	ref CheckCtx ctx,
	ref immutable CommonTypes commonTypes,
	scope immutable ParamsAst ast,
	scope ref immutable StructsAndAliasesDict structsAndAliasesDict,
	immutable TypeParamsScope typeParamsScope,
	ref DelayStructInsts delayStructInsts,
) {
	return matchParamsAst!(
		immutable Params,
		(immutable ParamAst[] asts) {
			immutable Param[] params = mapWithIndex!(Param, ParamAst)(
				ctx.alloc,
				asts,
				(immutable size_t index, scope ref immutable ParamAst ast) =>
					checkParam(
						ctx, commonTypes, structsAndAliasesDict, typeParamsScope, delayStructInsts,
						ast, index));
			eachPair!Param(params, (ref immutable Param x, ref immutable Param y) {
				if (has(x.name) && has(y.name) && symEq(force(x.name), force(y.name)))
					addDiag(ctx, y.range, immutable Diag(immutable Diag.DuplicateDeclaration(
						Diag.DuplicateDeclaration.Kind.paramOrLocal, force(y.name))));
			});
			return immutable Params(params);
		},
		(ref immutable ParamsAst.Varargs varargs) {
			immutable Param param = checkParam(
				ctx, commonTypes, structsAndAliasesDict, typeParamsScope, delayStructInsts, varargs.param, 0);
			immutable Type elementType = matchType!(immutable Type)(
				param.type,
				(immutable Type.Bogus) =>
					immutable Type(immutable Type.Bogus()),
				(immutable TypeParam*) =>
					todo!(immutable Type)("diagnostic"),
				(immutable StructInst* si) {
					if (decl(*si) == commonTypes.arr) {
						return only(typeArgs(*si));
					} else {
						return todo!(immutable Type)("diagnostic");
					}
				});
			return immutable Params(allocate(ctx.alloc, immutable Params.Varargs(param, elementType)));
		},
	)(ast);
}

immutable(Param) checkParam(
	ref CheckCtx ctx,
	ref immutable CommonTypes commonTypes,
	scope ref immutable StructsAndAliasesDict structsAndAliasesDict,
	immutable TypeParamsScope typeParamsScope,
	ref DelayStructInsts delayStructInsts,
	scope ref immutable ParamAst ast,
	immutable size_t index,
) {
	immutable Type type = typeFromAst(
		ctx,
		commonTypes,
		ast.type,
		structsAndAliasesDict,
		typeParamsScope,
		delayStructInsts);
	return immutable Param(rangeInFile(ctx, ast.range), ast.name, type, index);
}

immutable(Sig) checkSig(
	ref CheckCtx ctx,
	ref immutable CommonTypes commonTypes,
	scope ref immutable SigAst ast,
	immutable TypeParam[] typeParams,
	scope ref immutable StructsAndAliasesDict structsAndAliasesDict,
	DelayStructInsts delayStructInsts
) {
	immutable TypeParamsScope typeParamsScope = TypeParamsScope(typeParams);
	immutable Params params = checkParams(
		ctx,
		commonTypes,
		ast.params,
		structsAndAliasesDict,
		typeParamsScope,
		delayStructInsts);
	immutable Type returnType =
		typeFromAst(ctx, commonTypes, ast.returnType, structsAndAliasesDict, typeParamsScope, delayStructInsts);
	return immutable Sig(posInFile(ctx, ast.range.start), ast.name, returnType, params);
}

immutable(SpecBody.Builtin.Kind) getSpecBodyBuiltinKind(
	ref CheckCtx ctx,
	immutable RangeWithinFile range,
	immutable Sym name,
) {
	switch (name.value) {
		case shortSymValue("is-data"):
			return SpecBody.Builtin.Kind.data;
		case shortSymValue("is-sendable"):
			return SpecBody.Builtin.Kind.send;
		default:
			addDiag(ctx, range, immutable Diag(immutable Diag.BuiltinUnsupported(name)));
			return SpecBody.Builtin.Kind.data;
	}
}

immutable(SpecBody) checkSpecBody(
	ref CheckCtx ctx,
	ref immutable CommonTypes commonTypes,
	immutable TypeParam[] typeParams,
	ref immutable StructsAndAliasesDict structsAndAliasesDict,
	immutable RangeWithinFile range,
	immutable Sym name,
	ref immutable SpecBodyAst ast,
) {
	return matchSpecBodyAst!(
		immutable SpecBody,
		(ref immutable SpecBodyAst.Builtin) =>
			immutable SpecBody(SpecBody.Builtin(getSpecBodyBuiltinKind(ctx, range, name))),
		(ref immutable SpecSigAst[] sigs) =>
			immutable SpecBody(map!SpecDeclSig(ctx.alloc, sigs, (ref immutable SpecSigAst it) =>
				immutable SpecDeclSig(it.docComment, checkSig(
					ctx,
					commonTypes,
					it.sig,
					typeParams,
					structsAndAliasesDict,
					noneMut!(MutArr!(StructInst*)*))))),
	)(ast);
}

immutable(SpecDecl[]) checkSpecDecls(
	ref CheckCtx ctx,
	ref immutable CommonTypes commonTypes,
	ref immutable StructsAndAliasesDict structsAndAliasesDict,
	scope immutable SpecDeclAst[] asts,
) {
	return map!SpecDecl(ctx.alloc, asts, (ref immutable SpecDeclAst ast) {
		immutable TypeParam[] typeParams = checkTypeParams(ctx, ast.typeParams);
		immutable SpecBody body_ =
			checkSpecBody(ctx, commonTypes, typeParams, structsAndAliasesDict, ast.range, ast.name, ast.body_);
		return immutable SpecDecl(
			rangeInFile(ctx, ast.range),
			copySafeCStr(ctx.alloc, ast.docComment),
			ast.visibility,
			ast.name,
			small(typeParams),
			body_);
	});
}

StructAlias[] checkStructAliasesInitial(ref CheckCtx ctx, scope immutable StructAliasAst[] asts) {
	return mapToMut!(StructAlias, StructAliasAst)(ctx.alloc, asts, (scope ref immutable StructAliasAst ast) @safe =>
		StructAlias(
			rangeInFile(ctx, ast.range),
			copySafeCStr(ctx.alloc, ast.docComment),
			ast.visibility,
			ast.name,
			small(checkTypeParams(ctx, ast.typeParams))));
}

void checkStructAliasTargets(
	ref CheckCtx ctx,
	ref immutable CommonTypes commonTypes,
	ref immutable StructsAndAliasesDict structsAndAliasesDict,
	StructAlias[] aliases,
	scope immutable StructAliasAst[] asts,
	ref MutArr!(StructInst*) delayStructInsts,
) {
	zipFirstMut!(StructAlias, StructAliasAst)(
		aliases,
		asts,
		(ref StructAlias structAlias, ref immutable StructAliasAst ast) {
			immutable Type type = typeFromAst(
				ctx,
				commonTypes,
				ast.target,
				structsAndAliasesDict,
				immutable TypeParamsScope(structAlias.typeParams),
				someMut!(MutArr!(StructInst*)*)(ptrTrustMe_mut(delayStructInsts)));
			if (isStructInst(type))
				setTarget(structAlias, some(asStructInst(type)));
			else {
				if (!isBogus(type))
					todo!void("diagnostic -- alias does not resolve to struct (must be bogus or a type parameter)");
				setTarget(structAlias, none!(StructInst*));
			}
		});
}

immutable(StructsAndAliasesDict) buildStructsAndAliasesDict(
	ref CheckCtx ctx,
	immutable StructDecl[] structs,
	immutable StructAlias[] aliases,
) {
	SymDictBuilder!StructOrAliasAndIndex builder;
	void warnOnDup(immutable Sym name, immutable FileAndRange range, immutable Opt!StructOrAliasAndIndex opt) {
		if (has(opt))
			addDiag(ctx, range, immutable Diag(
				immutable Diag.DuplicateDeclaration(Diag.DuplicateDeclaration.Kind.structOrAlias, name)));
	}
	foreach (immutable size_t index; 0 .. structs.length) {
		immutable StructDecl* decl = ptrAt(structs, index);
		immutable Sym name = decl.name;
		warnOnDup(name, decl.range, tryAddToDict(ctx.alloc, builder, name, immutable StructOrAliasAndIndex(
			immutable StructOrAlias(decl),
			immutable ModuleLocalStructOrAliasIndex(index))));
	}
	foreach (immutable size_t index; 0 .. aliases.length) {
		immutable StructAlias* alias_ = ptrAt(aliases, index);
		immutable Sym name = alias_.name;
		warnOnDup(name, alias_.range, tryAddToDict(ctx.alloc, builder, name, immutable StructOrAliasAndIndex(
			immutable StructOrAlias(alias_),
			immutable ModuleLocalStructOrAliasIndex(index))));
	}
	return finishDict(ctx.alloc, builder);
}

struct FunsAndDict {
	immutable FunDecl[] funs;
	immutable Test[] tests;
	immutable FunsDict funsDict;
}

immutable(SpecInst*[]) checkSpecUses(
	ref CheckCtx ctx,
	ref immutable CommonTypes commonTypes,
	scope ref immutable SpecUseAst[] asts,
	scope ref immutable StructsAndAliasesDict structsAndAliasesDict,
	scope ref immutable SpecsDict specsDict,
	immutable TypeParamsScope typeParamsScope,
) {
	return mapOp!(SpecInst*)(ctx.alloc, asts, (scope ref immutable SpecUseAst ast) {
		immutable Opt!(SpecDecl*) opSpec = tryFindSpec(ctx, ast.spec.name, ast.range, specsDict);
		if (has(opSpec)) {
			immutable SpecDecl* spec = force(opSpec);
			TypeArgsArray typeArgs = typeArgsArray();
			typeArgsFromAsts(
				typeArgs,
				ctx,
				commonTypes,
				ast.typeArgs,
				structsAndAliasesDict,
				typeParamsScope,
				noneMut!(MutArr!(StructInst*)*));
			if (!sizeEq(tempAsArr(typeArgs), spec.typeParams)) {
				addDiag(ctx, ast.range, immutable Diag(
					immutable Diag.WrongNumberTypeArgsForSpec(
						spec,
						spec.typeParams.length,
						tempAsArr(typeArgs).length)));
				return none!(SpecInst*);
			} else
				return some(instantiateSpec(ctx.alloc, ctx.programState, spec, tempAsArr(typeArgs)));
		} else
			return none!(SpecInst*);
	});
}

immutable(FunsAndDict) checkFuns(
	ref CheckCtx ctx,
	ref immutable CommonTypes commonTypes,
	scope ref immutable SpecsDict specsDict,
	immutable StructDecl[] structs,
	scope ref immutable StructsAndAliasesDict structsAndAliasesDict,
	immutable ImportOrExportFile[] fileImports,
	immutable ImportOrExportFile[] fileExports,
	scope immutable FunDeclAst[] asts,
	scope immutable TestAst[] testAsts,
) {
	ExactSizeArrBuilder!FunDecl funsBuilder = newExactSizeArrBuilder!FunDecl(
		ctx.alloc,
		asts.length + fileImports.length + fileExports.length + countFunsForStruct(structs));
	foreach (ref immutable FunDeclAst funAst; asts) {
		immutable TypeParam[] typeParams = checkTypeParams(ctx, funAst.typeParams);
		immutable Sig sig = checkSig(
			ctx,
			commonTypes,
			funAst.sig,
			typeParams,
			structsAndAliasesDict,
			noneMut!(MutArr!(StructInst*)*));
		immutable SpecInst*[] specUses = checkSpecUses(
			ctx,
			commonTypes,
			funAst.specUses,
			structsAndAliasesDict,
			specsDict,
			immutable TypeParamsScope(typeParams));
		immutable FunFlags flags = flagsFromAst(funAst.flags);
		exactSizeArrBuilderAdd(
			funsBuilder,
			FunDecl(copySafeCStr(ctx.alloc, funAst.docComment), funAst.visibility, flags, sig, typeParams, specUses));
	}
	foreach (ref immutable ImportOrExportFile f; fileImports)
		exactSizeArrBuilderAdd(
			funsBuilder,
			funDeclForFileImportOrExport(ctx, commonTypes, structsAndAliasesDict, f, Visibility.private_));
	foreach (ref immutable ImportOrExportFile f; fileExports)
		exactSizeArrBuilderAdd(
			funsBuilder,
			funDeclForFileImportOrExport(ctx, commonTypes, structsAndAliasesDict, f, Visibility.public_));

	foreach (immutable StructDecl* struct_; ptrsRange(structs))
		addFunsForStruct(ctx, funsBuilder, commonTypes, struct_);
	FunDecl[] funs = finish(funsBuilder);
	FullIndexDict!(ModuleLocalFunIndex, bool) usedFuns =
		makeFullIndexDict_mut!(ModuleLocalFunIndex, bool)(ctx.alloc, funs.length, (immutable size_t) => false);

	immutable FunsDict funsDict = buildMultiDict!(Sym, FunDeclAndIndex, symEq, hashSym, FunDecl)(
		ctx.alloc,
		castImmutable(funs),
		(immutable size_t index, immutable FunDecl* it) =>
			immutable KeyValuePair!(Sym, FunDeclAndIndex)(
				name(*it),
				immutable FunDeclAndIndex(immutable ModuleLocalFunIndex(index), it)));

	FunDecl[] funsWithAsts = funs[0 .. asts.length];
	zipMutPtrFirst!(FunDecl, FunDeclAst)(funsWithAsts, asts, (FunDecl* fun, ref immutable FunDeclAst funAst) {
		overwriteMemory(&fun.body_, matchFunBodyAst!(
			immutable FunBody,
			(ref immutable FunBodyAst.Builtin) =>
				immutable FunBody(immutable FunBody.Builtin()),
			(ref immutable FunBodyAst.Extern e) =>
				immutable FunBody(checkExternFun(ctx, castImmutable(fun), e)),
			(ref immutable ExprAst e) =>
				immutable FunBody(getExprFunctionBody(
					ctx, commonTypes, structsAndAliasesDict, funsDict, usedFuns, *castImmutable(fun), e)),
		)(funAst.body_));
	});
	foreach (immutable size_t i, ref immutable ImportOrExportFile f; fileImports) {
		FunDecl* fun = ptrAt(funs, asts.length + i);
		overwriteMemory(&fun.body_, getFileImportFunctionBody(
			ctx, commonTypes, structsAndAliasesDict, funsDict, usedFuns, *castImmutable(fun), f));
	}
	foreach (immutable size_t i, ref immutable ImportOrExportFile f; fileExports) {
		FunDecl* fun = ptrAt(funs, asts.length + fileImports.length + i);
		overwriteMemory(&fun.body_, getFileImportFunctionBody(
			ctx, commonTypes, structsAndAliasesDict, funsDict, usedFuns, *castImmutable(fun), f));
	}

	immutable Test[] tests = map!(Test, TestAst)(ctx.alloc, testAsts, (scope ref immutable TestAst ast) {
		immutable Type voidType = immutable Type(commonTypes.void_);
		return immutable Test(checkFunctionBody(
			ctx,
			structsAndAliasesDict,
			commonTypes,
			funsDict,
			usedFuns,
			voidType,
			emptyArr!TypeParam,
			emptyArr!Param,
			emptyArr!(SpecInst*),
			FunFlags.unsafeSummon,
			ast.body_));
	});

	fullIndexDictZipPtrs!(ModuleLocalFunIndex, FunDecl, bool)(
		fullIndexDictOfArr!(ModuleLocalFunIndex, FunDecl)(castImmutable(funs)),
		fullIndexDictCastImmutable(usedFuns),
		(immutable(ModuleLocalFunIndex), immutable FunDecl* fun, immutable bool* used) {
			final switch (fun.visibility) {
				case Visibility.public_:
					break;
				case Visibility.private_:
					if (!*used && !okIfUnused(*fun))
						addDiag(ctx, fun.range, immutable Diag(
							immutable Diag.UnusedPrivateFun(fun)));
			}
		});

	return immutable FunsAndDict(castImmutable(funs), tests, funsDict);
}

immutable(FunBody) getFileImportFunctionBody(
	ref CheckCtx ctx,
	ref immutable CommonTypes commonTypes,
	scope ref immutable StructsAndAliasesDict structsAndAliasesDict,
	ref immutable FunsDict funsDict,
	ref FullIndexDict!(ModuleLocalFunIndex, bool) usedFuns,
	ref immutable FunDecl f,
	ref immutable ImportOrExportFile ie,
) {
	return matchFileContent!(immutable FunBody)(
		ie.content,
		(immutable ubyte[] bytes) =>
			immutable FunBody(immutable FunBody.FileBytes(bytes)),
		(immutable SafeCStr str) {
			immutable ExprAst ast = immutable ExprAst(
				f.range.range,
				immutable ExprAstKind(immutable LiteralAst(strOfSafeCStr(str))));
			return immutable FunBody(
				getExprFunctionBody(ctx, commonTypes, structsAndAliasesDict, funsDict, usedFuns, f, ast));
		});
}

immutable(Expr) getExprFunctionBody(
	ref CheckCtx ctx,
	ref immutable CommonTypes commonTypes,
	scope ref immutable StructsAndAliasesDict structsAndAliasesDict,
	ref immutable FunsDict funsDict,
	ref FullIndexDict!(ModuleLocalFunIndex, bool) usedFuns,
	ref immutable FunDecl f,
	ref immutable ExprAst e,
) {
	return checkFunctionBody(
		ctx,
		structsAndAliasesDict,
		commonTypes,
		funsDict,
		usedFuns,
		returnType(f),
		f.typeParams,
		paramsArray(params(f)),
		f.specs,
		f.flags,
		e);
}

FunDecl funDeclForFileImportOrExport(
	ref CheckCtx ctx,
	ref immutable CommonTypes commonTypes,
	scope ref immutable StructsAndAliasesDict structsAndAliasesDict,
	ref immutable ImportOrExportFile a,
	immutable Visibility visibility,
) {
	return FunDecl(
		safeCStr!"",
		visibility,
		FunFlags.generatedNoCtx,
		immutable Sig(
			immutable FileAndPos(ctx.fileIndex, a.range.start),
			a.name,
			typeForFileImport(ctx, commonTypes, structsAndAliasesDict, a.range, a.type),
			immutable Params(emptyArr!Param)),
		emptyArr!TypeParam,
		emptyArr!(SpecInst*));
}

immutable(Type) typeForFileImport(
	ref CheckCtx ctx,
	ref immutable CommonTypes commonTypes,
	scope ref immutable StructsAndAliasesDict structsAndAliasesDict,
	immutable RangeWithinFile range,
	immutable ImportFileType type,
) {
	final switch (type) {
		case ImportFileType.nat8Array:
			immutable TypeAst nat8 = immutable TypeAst(immutable TypeAst.InstStruct(
				range,
				immutable NameAndRange(range.start, shortSym("nat8")),
				emptySmallArray!TypeAst));
			immutable TypeAst.Suffix suffix = immutable TypeAst.Suffix(
				TypeAst.Suffix.Kind.arr,
				nat8);
			immutable TypeAst nat8Array = immutable TypeAst(ptrTrustMe(suffix));
			return typeFromAstNoTypeParamsNeverDelay(ctx, commonTypes, nat8Array, structsAndAliasesDict);
		case ImportFileType.str:
			//TODO: this sort of duplicates 'getStrType'
			scope immutable TypeAst ast = immutable TypeAst(immutable TypeAst.InstStruct(
				range,
				immutable NameAndRange(range.start, shortSym("str")),
				emptySmallArray!TypeAst));
			return typeFromAstNoTypeParamsNeverDelay(ctx, commonTypes, ast, structsAndAliasesDict);
	}
}

immutable(FunBody.Extern) checkExternFun(
	ref CheckCtx ctx,
	immutable FunDecl* fun,
	ref immutable FunBodyAst.Extern ast,
) {
	immutable Linkage funLinkage = Linkage.extern_;

	if (!empty(fun.typeParams))
		addDiag(ctx, fun.range, immutable Diag(
			immutable Diag.ExternFunForbidden(fun, Diag.ExternFunForbidden.Reason.hasTypeParams)));
	if (!empty(fun.specs))
		addDiag(ctx, fun.range, immutable Diag(
			immutable Diag.ExternFunForbidden(fun, Diag.ExternFunForbidden.Reason.hasSpecs)));
	if (!noCtx(*fun))
		addDiag(ctx, fun.range, immutable Diag(
			immutable Diag.ExternFunForbidden(fun, Diag.ExternFunForbidden.Reason.needsNoCtx)));

	if (!isLinkageAlwaysCompatible(funLinkage, linkageRange(returnType(*fun))))
		addDiag(ctx, fun.range, immutable Diag(
			immutable Diag.LinkageWorseThanContainingFun(fun, returnType(*fun), none!(Param*))));
	matchParams!void(
		params(*fun),
		(immutable Param[] params) {
			foreach (immutable Param* p; ptrsRange(params)) {
				if (!isLinkageAlwaysCompatible(funLinkage, linkageRange(p.type)))
					addDiag(ctx, p.range, immutable Diag(
						immutable Diag.LinkageWorseThanContainingFun(fun, p.type, some(p))));
			}
		},
		(ref immutable Params.Varargs) {
			addDiag(ctx, fun.range, immutable Diag(
				immutable Diag.ExternFunForbidden(fun, Diag.ExternFunForbidden.Reason.variadic)));
		});

	if (ast.isGlobal && arityIsNonZero(arity(*fun)))
		todo!void("'global' fun has parameters");

	return immutable FunBody.Extern(ast.isGlobal, ast.libraryName);
}

immutable(FunFlags) flagsFromAst(immutable FunDeclAstFlags a) {
	return immutable FunFlags(a.noDoc, a.noCtx, a.summon, a.unsafe, a.trusted, false, false, false);
}

immutable(SpecsDict) buildSpecsDict(ref CheckCtx ctx, immutable SpecDecl[] specs) {
	SymDictBuilder!SpecDeclAndIndex res;
	foreach (immutable size_t index; 0 .. specs.length) {
		immutable SpecDecl* spec = &specs[index];
		immutable Sym name = spec.name;
		immutable Opt!SpecDeclAndIndex b = tryAddToDict(ctx.alloc, res, name, immutable SpecDeclAndIndex(
			spec,
			immutable ModuleLocalSpecIndex(index)));
		if (has(b))
			addDiag(ctx, force(b).decl.range, immutable Diag(
				immutable Diag.DuplicateDeclaration(Diag.DuplicateDeclaration.Kind.spec, name)));
	}
	return finishDict(ctx.alloc, res);
}

immutable(Module) checkWorkerAfterCommonTypes(
	ref CheckCtx ctx,
	ref immutable CommonTypes commonTypes,
	ref immutable StructsAndAliasesDict structsAndAliasesDict,
	immutable StructAlias[] structAliases,
	StructDecl[] structs,
	ref MutArr!(StructInst*) delayStructInsts,
	immutable FileIndex fileIndex,
	ref immutable ImportsAndExports importsAndExports,
	scope ref immutable FileAst ast,
) {
	checkStructBodies(ctx, commonTypes, structsAndAliasesDict, structs, ast.structs, delayStructInsts);
	immutable StructDecl[] structsImmutable = castImmutable(structs);

	while (!mutArrIsEmpty(delayStructInsts)) {
		StructInst* i = mustPop(delayStructInsts);
		setBody(*i, instantiateStructBody(
			ctx.alloc,
			ctx.programState,
			i.declAndArgs,
			someMut(ptrTrustMe_mut(delayStructInsts))));
	}

	immutable SpecDecl[] specs = checkSpecDecls(ctx, commonTypes, structsAndAliasesDict, ast.specs);
	immutable SpecsDict specsDict = buildSpecsDict(ctx, specs);
	immutable FunsAndDict funsAndDict = checkFuns(
		ctx,
		commonTypes,
		specsDict,
		structsImmutable,
		structsAndAliasesDict,
		importsAndExports.fileImports,
		importsAndExports.fileExports,
		ast.funs,
		ast.tests);
	checkForUnused(ctx, structAliases, castImmutable(structs), specs);
	return immutable Module(
		fileIndex,
		copySafeCStr(ctx.alloc, ast.docComment),
		importsAndExports.moduleImports,
		importsAndExports.moduleExports,
		structsImmutable, specs, funsAndDict.funs, funsAndDict.tests,
		getAllExportedNames(
			ctx.alloc,
			ctx.diagsBuilder,
			importsAndExports.moduleExports,
			structsAndAliasesDict,
			specsDict,
			funsAndDict.funsDict,
			fileIndex));
}

immutable(SymDict!NameReferents) getAllExportedNames(
	ref Alloc alloc,
	scope ref DiagnosticsBuilder diagsBuilder,
	scope immutable ImportOrExport[] reExports,
	ref immutable StructsAndAliasesDict structsAndAliasesDict,
	ref immutable SpecsDict specsDict,
	ref immutable FunsDict funsDict,
	immutable FileIndex fileIndex,
) {
	MutSymDict!(immutable NameReferents) res;
	void addExport(immutable Sym name, immutable NameReferents cur, immutable FileAndRange range)
		@safe @nogc pure nothrow {
		insertOrUpdate!(immutable Sym, immutable NameReferents, symEq, hashSym)(
			alloc,
			res,
			name,
			() => cur,
			(ref immutable NameReferents prev) {
				immutable Opt!(Diag.DuplicateExports.Kind) kind = has(prev.structOrAlias) && has(cur.structOrAlias)
					? some(Diag.DuplicateExports.Kind.type)
					: has(prev.spec) && has(cur.spec)
					? some(Diag.DuplicateExports.Kind.spec)
					: none!(Diag.DuplicateExports.Kind);
				if (has(kind))
					addDiagnostic(alloc, diagsBuilder, range, immutable Diag(
						immutable Diag.DuplicateExports(force(kind), name)));
				return immutable NameReferents(
					has(prev.structOrAlias) ? prev.structOrAlias : cur.structOrAlias,
					has(prev.spec) ? prev.spec : cur.spec,
					cat(alloc, prev.funs, cur.funs));
			});
	}

	foreach (ref immutable ImportOrExport e; reExports)
		matchImportOrExportKind!void(
			e.kind,
			(immutable ImportOrExportKind.ModuleWhole m) {
				dictEach!(Sym, NameReferents, symEq, hashSym)(
					m.module_.allExportedNames,
					(immutable Sym name, ref immutable NameReferents value) {
						addExport(name, value, immutable FileAndRange(fileIndex, force(e.importSource)));
					});
			},
			(immutable ImportOrExportKind.ModuleNamed m) {
				foreach (immutable Sym name; m.names) {
					immutable Opt!NameReferents value = m.module_.allExportedNames[name];
					if (has(value))
						addExport(name, force(value), immutable FileAndRange(fileIndex, force(e.importSource)));
				}
			});
	dictEach!(Sym, StructOrAliasAndIndex, symEq, hashSym)(
		structsAndAliasesDict,
		(immutable Sym name, ref immutable StructOrAliasAndIndex it) {
			final switch (visibility(it.structOrAlias)) {
				case Visibility.public_:
					addExport(
						name,
						immutable NameReferents(some(it.structOrAlias), none!(SpecDecl*), emptyArr!(FunDecl*)),
						range(it.structOrAlias));
					break;
				case Visibility.private_:
					break;
			}
		});
	dictEach!(Sym, SpecDeclAndIndex, symEq, hashSym)(
		specsDict,
		(immutable Sym name, ref immutable SpecDeclAndIndex it) {
			final switch (it.decl.visibility) {
				case Visibility.public_:
					addExport(
						name,
						immutable NameReferents(none!StructOrAlias, some(it.decl), emptyArr!(FunDecl*)),
						it.decl.range);
					break;
				case Visibility.private_:
					break;
			}
		});
	multiDictEach!(Sym, FunDeclAndIndex, symEq, hashSym)(
		funsDict,
		(immutable Sym name, immutable FunDeclAndIndex[] funs) {
			immutable FunDecl*[] funDecls = mapOp!(FunDecl*)(
				alloc,
				funs,
				(ref immutable FunDeclAndIndex it) {
					final switch (it.decl.visibility) {
						case Visibility.public_:
							return some(it.decl);
						case Visibility.private_:
							return none!(FunDecl*);
					}
				});
			if (!empty(funDecls))
				addExport(
					name,
					immutable NameReferents(none!StructOrAlias, none!(SpecDecl*), funDecls),
					// This argument doesn't matter because a function never results in a duplicate export error
					immutable FileAndRange(fileIndex, RangeWithinFile.empty));
		});

	return moveToDict!(Sym, NameReferents, symEq, hashSym)(alloc, res);
}

immutable(BootstrapCheck) checkWorker(
	Alloc* allocPtr,
	Perf* perf,
	AllSymbols* allSymbolsPtr,
	ref DiagnosticsBuilder diagsBuilder,
	ProgramState* programStatePtr,
	ref immutable ImportsAndExports importsAndExports,
	scope ref immutable PathAndAst pathAndAst,
	scope immutable(CommonTypes) delegate(
		ref CheckCtx,
		ref immutable StructsAndAliasesDict,
		ref MutArr!(StructInst*),
	) @safe @nogc pure nothrow getCommonTypes,
) {
	ref Alloc alloc() { return *allocPtr; }

	checkImportsOrExports(alloc, diagsBuilder, pathAndAst.fileIndex, importsAndExports.moduleImports);
	checkImportsOrExports(alloc, diagsBuilder, pathAndAst.fileIndex, importsAndExports.moduleExports);
	immutable FileAst ast = pathAndAst.ast;
	CheckCtx ctx = CheckCtx(
		allocPtr,
		perf,
		programStatePtr,
		allSymbolsPtr,
		pathAndAst.fileIndex,
		importsAndExports.moduleImports,
		importsAndExports.moduleExports,
		// TODO: use temp alloc
		newUsedImportsAndReExports(alloc, importsAndExports.moduleImports, importsAndExports.moduleExports),
		// TODO: use temp alloc
		makeFullIndexDict_mut!(ModuleLocalAliasIndex, bool)(
			alloc, ast.structAliases.length, (immutable(ModuleLocalAliasIndex)) => false),
		// TODO: use temp alloc
		makeFullIndexDict_mut!(ModuleLocalStructIndex, bool)(
			alloc, ast.structs.length, (immutable(ModuleLocalStructIndex)) => false),
		// TODO: use temp alloc
		makeFullIndexDict_mut!(ModuleLocalSpecIndex, bool)(
			alloc, ast.specs.length, (immutable(ModuleLocalSpecIndex)) => false),
		ptrTrustMe_mut(diagsBuilder));

	// Since structs may refer to each other, first get a structsAndAliasesDict, *then* fill in bodies
	StructDecl[] structs = checkStructsInitial(ctx, ast.structs);
	StructAlias[] structAliases = checkStructAliasesInitial(ctx, ast.structAliases);
	immutable StructsAndAliasesDict structsAndAliasesDict =
		buildStructsAndAliasesDict(ctx, castImmutable(structs), castImmutable(structAliases));

	// We need to create StructInsts when filling in struct bodies.
	// But when creating a StructInst, we usually want to fill in its body.
	// In case the decl body isn't available yet,
	// we'll delay creating the StructInst body, which isn't needed until expr checking.
	MutArr!(StructInst*) delayStructInsts;

	immutable CommonTypes commonTypes = getCommonTypes(ctx, structsAndAliasesDict, delayStructInsts);

	checkStructAliasTargets(
		ctx,
		commonTypes,
		structsAndAliasesDict,
		structAliases,
		ast.structAliases,
		delayStructInsts);

	immutable Module res = checkWorkerAfterCommonTypes(
		ctx,
		commonTypes,
		structsAndAliasesDict,
		castImmutable(structAliases),
		structs,
		delayStructInsts,
		pathAndAst.fileIndex,
		importsAndExports,
		ast);
	return immutable BootstrapCheck(res, commonTypes);
}

void checkImportsOrExports(
	ref Alloc alloc,
	ref DiagnosticsBuilder diags,
	immutable FileIndex thisFile,
	immutable ImportOrExport[] imports,
) {
	foreach (ref immutable ImportOrExport x; imports)
		matchImportOrExportKind!void(
			x.kind,
			(immutable(ImportOrExportKind.ModuleWhole)) {},
			(immutable ImportOrExportKind.ModuleNamed m) {
				foreach (ref immutable Sym name; m.names)
					if (!hasKey(m.module_.allExportedNames, name))
						addDiagnostic(
							alloc,
							diags,
							// TODO: use the range of the particular name
							// (by advancing pos by symSize until we get to this name)
							immutable FileAndRange(thisFile, force(x.importSource)),
							immutable Diag(immutable Diag.ImportRefersToNothing(name)));
			});
}
