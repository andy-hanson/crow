module frontend.check.check;

@safe @nogc pure nothrow:

import frontend.check.checkCtx :
	addDiag,
	CheckCtx,
	checkForUnused,
	newUsedImportsAndReExports,
	posInFile,
	rangeInFile;
import frontend.check.checkExpr : checkFunctionBody;
import frontend.check.dicts :
	FunDeclAndIndex,
	FunsDict,
	ModuleLocalFunIndex,
	ModuleLocalSpecIndex,
	ModuleLocalStructOrAliasIndex,
	SpecDeclAndIndex,
	SpecsDict,
	StructsAndAliasesDict,
	StructOrAliasAndIndex;
import frontend.check.instantiate :
	DelayStructInsts,
	instantiateSpec,
	instantiateStruct,
	instantiateStructBody,
	instantiateStructNeverDelay,
	TypeParamsScope;
import frontend.check.typeFromAst : instStructFromAst, tryFindSpec, typeArgsFromAsts, typeFromAst;
import frontend.parse.ast :
	ExplicitByValOrRef,
	ExplicitByValOrRefAndRange,
	exports,
	ExprAst,
	FileAst,
	FunBodyAst,
	FunDeclAst,
	funs,
	imports,
	matchFunBodyAst,
	matchSpecBodyAst,
	matchStructDeclAstBody,
	matchTypeAst,
	ParamAst,
	PuritySpecifier,
	rangeOfNameAndRange,
	SigAst,
	SpecBodyAst,
	SpecDeclAst,
	specs,
	SpecUseAst,
	StructAliasAst,
	StructDeclAst,
	structAliases,
	structs,
	TestAst,
	tests,
	TypeAst,
	TypeParamAst;
import frontend.programState : ProgramState;
import model.diag : Diag, Diagnostic, TypeKind;
import model.model :
	arity,
	asRecord,
	asStructDecl,
	asStructInst,
	bestCasePurity,
	body_,
	CommonTypes,
	decl,
	ForcedByValOrRefOrNone,
	FunBody,
	FunDecl,
	FunFlags,
	FunKind,
	FunKindAndStructs,
	IntegralTypes,
	isBogus,
	isPublic,
	isPurityWorse,
	isRecord,
	isStructInst,
	isUnion,
	matchStructBody,
	matchStructOrAlias,
	Module,
	ModuleArrs,
	ModuleImportsExports,
	ModuleAndNames,
	name,
	NameReferents,
	noCtx,
	okIfUnused,
	Param,
	params,
	Purity,
	range,
	RecordField,
	RecordFlags,
	returnType,
	setBody,
	setTarget,
	Sig,
	SpecBody,
	SpecDecl,
	SpecDeclAndArgs,
	SpecInst,
	specs,
	StructAlias,
	StructBody,
	StructDecl,
	StructDeclAndArgs,
	StructInst,
	StructOrAlias,
	target,
	Test,
	Type,
	TypeParam,
	typeParams;
import util.collection.arr :
	ArrWithSize,
	at,
	castImmutable,
	empty,
	emptyArr,
	emptyArrWithSize,
	ptrAt,
	ptrsRange,
	size,
	sizeEq,
	toArr;
import util.collection.arrBuilder :
	add,
	ArrBuilder,
	ArrWithSizeBuilder,
	arrWithSizeBuilderAsTempArr,
	arrWithSizeBuilderSize,
	finishArr;
import util.collection.arrUtil :
	arrLiteral,
	cat,
	count,
	exists,
	fillArr_mut,
	map,
	mapOp,
	mapOpWithSize,
	mapOrNone,
	mapPtrs,
	mapToMut,
	mapWithIndex,
	mapWithSizeWithIndex,
	sum,
	zipFirstMut,
	zipMutPtrFirst,
	zipPtrFirst;
import util.collection.dict : Dict, dictEach, getAt, hasKey, KeyValuePair;
import util.collection.dictBuilder : addToDict, DictBuilder, finishDict;
import util.collection.dictUtil : buildMultiDict;
import util.collection.exactSizeArrBuilder :
	ExactSizeArrBuilder,
	exactSizeArrBuilderAdd,
	finish,
	newExactSizeArrBuilder;
import util.collection.multiDict : multiDictEach;
import util.collection.mutArr : mustPop, MutArr, mutArrIsEmpty;
import util.collection.mutDict : insertOrUpdate, moveToDict, MutDict;
import util.collection.str : copyStr;
import util.memory : allocate, nu, nuMut, overwriteMemory;
import util.opt : force, has, none, noneMut, Opt, some, someMut;
import util.ptr : castImmutable, Ptr, ptrEquals, ptrTrustMe_mut;
import util.sourceRange : fileAndPosFromFileAndRange, FileAndRange, FileIndex, RangeWithinFile;
import util.sym :
	addToMutSymSetOkIfPresent,
	AllSymbols,
	compareSym,
	containsSym,
	prependSet,
	shortSymAlphaLiteral,
	shortSymAlphaLiteralValue,
	Sym,
	symEq;
import util.types : safeSizeTToU8;
import util.util : todo, verify;

struct PathAndAst { //TODO:RENAME
	immutable FileIndex fileIndex;
	immutable FileAst ast;
}

struct BootstrapCheck {
	immutable Ptr!Module module_;
	immutable Ptr!CommonTypes commonTypes;
}

immutable(BootstrapCheck) checkBootstrap(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref AllSymbols!SymAlloc allSymbols,
	ref ArrBuilder!Diagnostic diagsBuilder,
	ref ProgramState programState,
	immutable PathAndAst pathAndAst,
) {
	return checkWorker(
		alloc,
		allSymbols,
		diagsBuilder,
		programState,
		emptyArr!ModuleAndNames,
		emptyArr!ModuleAndNames,
		pathAndAst,
		(ref CheckCtx ctx,
		ref immutable StructsAndAliasesDict structsAndAliasesDict,
		ref MutArr!(Ptr!StructInst) delayedStructInsts) =>
			getCommonTypes(alloc, ctx, structsAndAliasesDict, delayedStructInsts));
}

immutable(Ptr!Module) check(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref AllSymbols!SymAlloc allSymbols,
	ref ArrBuilder!Diagnostic diagsBuilder,
	ref ProgramState programState,
	ref immutable ModuleAndNames[] imports,
	ref immutable ModuleAndNames[] exports,
	ref immutable PathAndAst pathAndAst,
	immutable Ptr!CommonTypes commonTypes,
) {
	return checkWorker(
		alloc,
		allSymbols,
		diagsBuilder,
		programState,
		imports,
		exports,
		pathAndAst,
		(ref CheckCtx, ref immutable StructsAndAliasesDict, ref MutArr!(Ptr!StructInst)) => commonTypes,
	).module_;
}

private:

immutable(Opt!(Ptr!StructDecl)) getCommonTemplateType(
	ref immutable StructsAndAliasesDict structsAndAliasesDict,
	immutable Sym name,
	immutable size_t expectedTypeParams,
) {
	immutable Opt!StructOrAliasAndIndex res = getAt(structsAndAliasesDict, name);
	if (has(res)) {
		// TODO: may fail -- builtin Template should not be an alias
		immutable Ptr!StructDecl decl = asStructDecl(force(res).structOrAlias);
		if (size(decl.typeParams) != expectedTypeParams)
			todo!void("getCommonTemplateType");
		return some(decl);
	} else
		return none!(Ptr!StructDecl);
}

immutable(Opt!(Ptr!StructInst)) getCommonNonTemplateType(Alloc)(
	ref Alloc alloc,
	ref CheckCtx ctx,
	ref immutable StructsAndAliasesDict structsAndAliasesDict,
	immutable Sym name,
	ref MutArr!(Ptr!StructInst) delayedStructInsts,
) {
	immutable Opt!StructOrAliasAndIndex opStructOrAlias = getAt(structsAndAliasesDict, name);
	return has(opStructOrAlias)
		? instantiateNonTemplateStructOrAlias(alloc, ctx, delayedStructInsts, force(opStructOrAlias).structOrAlias)
		: none!(Ptr!StructInst);
}

immutable(Opt!(Ptr!StructInst)) instantiateNonTemplateStructOrAlias(Alloc)(
	ref Alloc alloc,
	ref CheckCtx ctx,
	ref MutArr!(Ptr!StructInst) delayedStructInsts,
	immutable StructOrAlias structOrAlias,
) {
	verify(empty(typeParams(structOrAlias)));
	return matchStructOrAlias!(immutable Opt!(Ptr!StructInst))(
		structOrAlias,
		(immutable Ptr!StructAlias it) =>
			target(it),
		(immutable Ptr!StructDecl it) =>
			some(instantiateNonTemplateStructDecl(alloc, ctx, delayedStructInsts, it)));
}

immutable(Ptr!StructInst) instantiateNonTemplateStructDecl(ALloc)(
	ref ALloc alloc,
	ref CheckCtx ctx,
	ref MutArr!(Ptr!StructInst) delayedStructInsts,
	immutable Ptr!StructDecl structDecl,
) {
	return instantiateStruct(
		alloc,
		ctx.programState,
		immutable StructDeclAndArgs(structDecl, emptyArr!Type),
		someMut(ptrTrustMe_mut(delayedStructInsts)));
}

immutable(Ptr!CommonTypes) getCommonTypes(Alloc)(
	ref Alloc alloc,
	ref CheckCtx ctx,
	ref immutable StructsAndAliasesDict structsAndAliasesDict,
	ref MutArr!(Ptr!StructInst) delayedStructInsts,
) {
	ArrBuilder!string missing = ArrBuilder!string();

	immutable(Ptr!StructInst) nonTemplate(immutable string name) {
		immutable Opt!(Ptr!StructInst) res = getCommonNonTemplateType(
			alloc,
			ctx,
			structsAndAliasesDict,
			shortSymAlphaLiteral(name),
			delayedStructInsts);
		if (has(res))
			return force(res);
		else {
			add(alloc, missing, name);
			return instantiateNonTemplateStructDecl(alloc, ctx, delayedStructInsts, bogusStructDecl(alloc, 0));
		}
	}

	immutable Ptr!StructInst bool_ = nonTemplate("bool");
	immutable Ptr!StructInst char_ = nonTemplate("char");
	immutable Ptr!StructInst float64 = nonTemplate("float");
	immutable Ptr!StructInst int8 = nonTemplate("int8");
	immutable Ptr!StructInst int16 = nonTemplate("int16");
	immutable Ptr!StructInst int32 = nonTemplate("int32");
	immutable Ptr!StructInst int64 = nonTemplate("int");
	immutable Ptr!StructInst nat8 = nonTemplate("nat8");
	immutable Ptr!StructInst nat16 = nonTemplate("nat16");
	immutable Ptr!StructInst nat32 = nonTemplate("nat32");
	immutable Ptr!StructInst nat64 = nonTemplate("nat");
	immutable Ptr!StructInst void_ = nonTemplate("void");
	immutable Ptr!StructInst ctxStructInst = nonTemplate("ctx");

	immutable(Ptr!StructDecl) com(immutable string name, immutable size_t nTypeParameters) {
		immutable Opt!(Ptr!StructDecl) res = getCommonTemplateType(
			structsAndAliasesDict,
			shortSymAlphaLiteral(name),
			nTypeParameters);
		if (has(res))
			return force(res);
		else {
			add(alloc, missing, name);
			return bogusStructDecl(alloc, nTypeParameters);
		}
	}

	immutable Ptr!StructDecl byVal = com("by-val", 1);
	immutable Ptr!StructDecl arr = com("arr", 1);
	immutable Ptr!StructDecl fut = com("fut", 1);
	immutable Ptr!StructDecl fun0 = com("fun0", 1);
	immutable Ptr!StructDecl fun1 = com("fun1", 2);
	immutable Ptr!StructDecl fun2 = com("fun2", 3);
	immutable Ptr!StructDecl fun3 = com("fun3", 4);
	immutable Ptr!StructDecl fun4 = com("fun4", 5);
	immutable Ptr!StructDecl funAct0 = com("fun-act0", 1);
	immutable Ptr!StructDecl funAct1 = com("fun-act1", 2);
	immutable Ptr!StructDecl funAct2 = com("fun-act2", 3);
	immutable Ptr!StructDecl funAct3 = com("fun-act3", 4);
	immutable Ptr!StructDecl funAct4 = com("fun-act4", 5);
	immutable Ptr!StructDecl funPtr0 = com("fun-ptr0", 1);
	immutable Ptr!StructDecl funPtr1 = com("fun-ptr1", 2);
	immutable Ptr!StructDecl funPtr2 = com("fun-ptr2", 3);
	immutable Ptr!StructDecl funPtr3 = com("fun-ptr3", 4);
	immutable Ptr!StructDecl funPtr4 = com("fun-ptr4", 5);
	immutable Ptr!StructDecl funPtr5 = com("fun-ptr5", 6);
	immutable Ptr!StructDecl funPtr6 = com("fun-ptr6", 7);
	immutable Ptr!StructDecl funRef0 = com("fun-ref0", 1);
	immutable Ptr!StructDecl funRef1 = com("fun-ref1", 2);
	immutable Ptr!StructDecl funRef2 = com("fun-ref2", 3);
	immutable Ptr!StructDecl funRef3 = com("fun-ref3", 4);
	immutable Ptr!StructDecl funRef4 = com("fun-ref4", 5);

	immutable Ptr!StructInst str = instantiateStruct!Alloc(
		alloc,
		ctx.programState,
		immutable StructDeclAndArgs(arr, arrLiteral!Type(alloc, [immutable Type(char_)])),
		someMut(ptrTrustMe_mut(delayedStructInsts)));

	immutable string[] missingArr = finishArr(alloc, missing);

	if (!empty(missingArr))
		addDiag(
			alloc,
			ctx,
			immutable FileAndRange(ctx.fileIndex, RangeWithinFile.empty),
			immutable Diag(immutable Diag.CommonTypesMissing(missingArr)));
	return nu!CommonTypes(
		alloc,
		bool_,
		char_,
		float64,
		nu!IntegralTypes(
			alloc,
			int8,
			int16,
			int32,
			int64,
			nat8,
			nat16,
			nat32,
			nat64),
		str,
		void_,
		ctxStructInst,
		byVal,
		arr,
		fut,
		//TODO: this could have a compile-time length
		arrLiteral!(Ptr!StructDecl)(alloc, [
			funPtr0,
			funPtr1,
			funPtr2,
			funPtr3,
			funPtr4,
			funPtr5,
			funPtr6]),
		arrLiteral!FunKindAndStructs(alloc, [
			immutable FunKindAndStructs(FunKind.plain, arrLiteral!(Ptr!StructDecl)(alloc, [
				fun0,
				fun1,
				fun2,
				fun3,
				fun4])),
			immutable FunKindAndStructs(FunKind.mut, arrLiteral!(Ptr!StructDecl)(alloc, [
				funAct0,
				funAct1,
				funAct2,
				funAct3,
				funAct4])),
			immutable FunKindAndStructs(FunKind.ref_, arrLiteral!(Ptr!StructDecl)(alloc, [
				funRef0,
				funRef1,
				funRef2,
				funRef3,
				funRef4]))]));
}

immutable(Ptr!StructDecl) bogusStructDecl(Alloc)(ref Alloc alloc, immutable size_t nTypeParameters) {
	ArrWithSizeBuilder!TypeParam typeParams;
	immutable FileAndRange fileAndRange = immutable FileAndRange(immutable FileIndex(0), RangeWithinFile.empty);
	foreach (immutable size_t i; 0 .. nTypeParameters)
		add(alloc, typeParams, immutable TypeParam(fileAndRange, shortSymAlphaLiteral("bogus"), i));
	Ptr!StructDecl res = nuMut!StructDecl(
		alloc,
		fileAndRange,
		true,
		shortSymAlphaLiteral("bogus"),
		finishArr(alloc, typeParams),
		Purity.data,
		false);
	setBody(res, immutable StructBody(immutable StructBody.Bogus()));
	return castImmutable(res);
}

immutable(ArrWithSize!TypeParam) checkTypeParams(Alloc)(
	ref Alloc alloc,
	ref CheckCtx ctx,
	ref immutable ArrWithSize!TypeParamAst asts,
) {
	immutable ArrWithSize!TypeParam res =
		mapWithSizeWithIndex(alloc, toArr(asts), (immutable size_t index, ref immutable TypeParamAst ast) =>
			immutable TypeParam(rangeInFile(ctx, ast.range), ast.name, index));
	immutable TypeParam[] typeParams = toArr(res);
	foreach (immutable size_t i; 0 .. size(typeParams))
		foreach (immutable size_t prev_i; 0 .. i) {
			immutable TypeParam tp = at(typeParams, i);
			if (symEq(tp.name, at(typeParams, prev_i).name))
				addDiag(alloc, ctx, tp.range, immutable Diag(
					immutable Diag.ParamShadowsPrevious(Diag.ParamShadowsPrevious.Kind.typeParam, tp.name)));
		}
	return res;
}

void collectTypeParamsInAst(Alloc)(
	ref Alloc alloc,
	ref const CheckCtx ctx,
	ref immutable TypeAst ast,
	ref ArrWithSizeBuilder!TypeParam res,
) {
	matchTypeAst!void(
		ast,
		(ref immutable TypeAst.Fun it) {
			foreach (ref immutable TypeAst paramType; it.returnAndParamTypes)
				collectTypeParamsInAst(alloc, ctx, paramType, res);
		},
		(ref immutable TypeAst.InstStruct i) {
			foreach (ref immutable TypeAst arg; toArr(i.typeArgs))
				collectTypeParamsInAst(alloc, ctx, arg, res);
		},
		(ref immutable TypeAst.TypeParam tp) {
			immutable TypeParam[] a = arrWithSizeBuilderAsTempArr(res);
			if (!exists!TypeParam(a, (ref immutable TypeParam it) => symEq(it.name, tp.name))) {
				add(alloc, res, immutable TypeParam(rangeInFile(ctx, tp.range), tp.name, arrWithSizeBuilderSize(res)));
			}
		});
}

immutable(ArrWithSize!TypeParam) collectTypeParams(Alloc)(
	ref Alloc alloc,
	ref const CheckCtx ctx,
	ref immutable SigAst ast,
) {
	ArrWithSizeBuilder!TypeParam res;
	collectTypeParamsInAst(alloc, ctx, ast.returnType, res);
	foreach (ref immutable ParamAst p; toArr(ast.params))
		collectTypeParamsInAst(alloc, ctx, p.type, res);
	return finishArr(alloc, res);
}

immutable(Param[]) checkParams(Alloc)(
	ref Alloc alloc,
	ref CheckCtx ctx,
	ref immutable CommonTypes commonTypes,
	immutable ParamAst[] asts,
	ref immutable StructsAndAliasesDict structsAndAliasesDict,
	ref immutable TypeParamsScope typeParamsScope,
	ref DelayStructInsts delayStructInsts,
) {
	immutable Param[] params = mapWithIndex!Param(
		alloc,
		asts,
		(immutable size_t index, ref immutable ParamAst ast) {
			immutable Type type = typeFromAst(
				alloc,
				ctx,
				commonTypes,
				ast.type,
				structsAndAliasesDict,
				typeParamsScope,
				delayStructInsts);
			return immutable Param(rangeInFile(ctx, ast.range), ast.name, type, index);
		});
	foreach (immutable size_t i; 0 .. size(params))
		foreach (immutable size_t prev_i; 0 .. i) {
			immutable Ptr!Param param = ptrAt(params, i);
			immutable Ptr!Param prev = ptrAt(params, i - 1);
			if (has(param.name) && has(prev.name) && symEq(force(param.name), force(prev.name)))
				addDiag(alloc, ctx, param.range, immutable Diag(
					immutable Diag.ParamShadowsPrevious(Diag.ParamShadowsPrevious.Kind.param, force(param.name))));
		}
	return params;
}

immutable(Sig) checkSig(Alloc)(
	ref Alloc alloc,
	ref CheckCtx ctx,
	ref immutable CommonTypes commonTypes,
	ref immutable SigAst ast,
	immutable TypeParam[] typeParams,
	ref immutable StructsAndAliasesDict structsAndAliasesDict,
	DelayStructInsts delayStructInsts
) {
	immutable TypeParamsScope typeParamsScope = TypeParamsScope(typeParams);
	immutable Param[] params = checkParams(
		alloc,
		ctx,
		commonTypes,
		toArr(ast.params),
		structsAndAliasesDict,
		typeParamsScope,
		delayStructInsts);
	immutable Type returnType =
		typeFromAst(alloc, ctx, commonTypes, ast.returnType, structsAndAliasesDict, typeParamsScope, delayStructInsts);
	return immutable Sig(posInFile(ctx, ast.range.start), ast.name, returnType, params);
}

immutable(SpecBody.Builtin.Kind) getSpecBodyBuiltinKind(immutable Sym name) {
	switch (name.value) {
		case shortSymAlphaLiteralValue("data"):
			return SpecBody.Builtin.Kind.data;
		case shortSymAlphaLiteralValue("send"):
			return SpecBody.Builtin.Kind.send;
		default:
			return todo!(SpecBody.Builtin.Kind)("reachable?");
	}
}

immutable(SpecBody) checkSpecBody(Alloc)(
	ref Alloc alloc,
	ref CheckCtx ctx,
	ref immutable CommonTypes commonTypes,
	ref immutable ArrWithSize!TypeParam typeParams,
	ref immutable StructsAndAliasesDict structsAndAliasesDict,
	immutable Sym name,
	ref immutable SpecBodyAst ast,
) {
	return matchSpecBodyAst!(immutable SpecBody)(
		ast,
		(ref immutable SpecBodyAst.Builtin) =>
			immutable SpecBody(SpecBody.Builtin(getSpecBodyBuiltinKind(name))),
		(ref immutable SigAst[] sigs) =>
			immutable SpecBody(map!Sig(alloc, sigs, (ref immutable SigAst it) =>
				checkSig!Alloc(
					alloc,
					ctx,
					commonTypes,
					it,
					toArr(typeParams),
					structsAndAliasesDict,
					noneMut!(Ptr!(MutArr!(Ptr!StructInst)))))));
}

immutable(SpecDecl[]) checkSpecDecls(Alloc)(
	ref Alloc alloc,
	ref CheckCtx ctx,
	ref immutable CommonTypes commonTypes,
	ref immutable StructsAndAliasesDict structsAndAliasesDict,
	ref immutable SpecDeclAst[] asts,
) {
	return map!SpecDecl(alloc, asts, (ref immutable SpecDeclAst ast) {
		immutable ArrWithSize!TypeParam typeParams = checkTypeParams(alloc, ctx, ast.typeParams);
		immutable SpecBody body_ =
			checkSpecBody(alloc, ctx, commonTypes, typeParams, structsAndAliasesDict, ast.name, ast.body_);
		return immutable SpecDecl(rangeInFile(ctx, ast.range), ast.isPublic, ast.name, typeParams, body_);
	});
}

StructAlias[] checkStructAliasesInitial(Alloc)(
	ref Alloc alloc,
	ref CheckCtx ctx,
	ref immutable StructAliasAst[] asts,
) {
	return mapToMut!StructAlias(alloc, asts, (ref immutable StructAliasAst ast) =>
		StructAlias(
			rangeInFile(ctx, ast.range),
			ast.isPublic,
			ast.name,
			checkTypeParams(alloc, ctx, ast.typeParams)));
}

struct PurityAndForced {
	immutable Purity purity;
	immutable bool forced;
}

immutable(PurityAndForced) getPurityFromAst(Alloc)(
	ref Alloc alloc,
	ref CheckCtx ctx,
	ref immutable StructDeclAst ast,
) {
	immutable Purity defaultPurity = matchStructDeclAstBody!(immutable Purity)(
		ast.body_,
		(ref immutable StructDeclAst.Body.Builtin) =>
			Purity.data,
		(ref immutable StructDeclAst.Body.ExternPtr) =>
			Purity.mut,
		(ref immutable StructDeclAst.Body.Record) =>
			Purity.data,
		(ref immutable StructDeclAst.Body.Union) =>
			Purity.data);
	// Note: purity is taken for granted here, and verified later when we check the body.
	if (has(ast.purity)) {
		immutable PurityAndForced res = () {
			final switch (force(ast.purity).specifier) {
				case PuritySpecifier.data:
					return PurityAndForced(Purity.data, false);
				case PuritySpecifier.forceData:
					return PurityAndForced(Purity.data, true);
				case PuritySpecifier.sendable:
					return PurityAndForced(Purity.sendable, false);
				case PuritySpecifier.forceSendable:
					return PurityAndForced(Purity.sendable, true);
				case PuritySpecifier.mut:
					return PurityAndForced(Purity.mut, false);
			}
		}();
		if (res.purity == defaultPurity && !res.forced)
			addDiag(alloc, ctx, ast.range, immutable Diag(
				immutable Diag.PuritySpecifierRedundant(defaultPurity, getTypeKind(ast.body_))));
		return res;
	} else
		return PurityAndForced(defaultPurity, false);
}

immutable(TypeKind) getTypeKind(ref immutable StructDeclAst.Body a) {
	return matchStructDeclAstBody!(immutable TypeKind)(
		a,
		(ref immutable StructDeclAst.Body.Builtin) => TypeKind.builtin,
		(ref immutable StructDeclAst.Body.ExternPtr) => TypeKind.externPtr,
		(ref immutable StructDeclAst.Body.Record) => TypeKind.record,
		(ref immutable StructDeclAst.Body.Union) => TypeKind.union_);
}

StructDecl[] checkStructsInitial(Alloc)(
	ref Alloc alloc,
	ref CheckCtx ctx,
	ref immutable StructDeclAst[] asts,
) {
	return mapToMut!StructDecl(alloc, asts, (ref immutable StructDeclAst ast) {
		immutable PurityAndForced p = getPurityFromAst(alloc, ctx, ast);
		return StructDecl(
			rangeInFile(ctx, ast.range),
			ast.isPublic,
			ast.name,
			checkTypeParams(alloc, ctx, ast.typeParams),
			p.purity,
			p.forced);
	});
}

void checkStructAliasTargets(Alloc)(
	ref Alloc alloc,
	ref CheckCtx ctx,
	ref immutable CommonTypes commonTypes,
	ref immutable StructsAndAliasesDict structsAndAliasesDict,
	ref StructAlias[] aliases,
	ref immutable StructAliasAst[] asts,
	ref MutArr!(Ptr!StructInst) delayStructInsts,
) {
	zipFirstMut!(StructAlias, StructAliasAst)(
		aliases,
		asts,
		(ref StructAlias structAlias, ref immutable StructAliasAst ast) {
			immutable Type type = typeFromAst!Alloc(
				alloc,
				ctx,
				commonTypes,
				ast.target,
				structsAndAliasesDict,
				immutable TypeParamsScope(typeParams(structAlias)),
				someMut!(Ptr!(MutArr!(Ptr!StructInst)))(ptrTrustMe_mut(delayStructInsts)));
			if (isStructInst(type))
				setTarget(structAlias, some(asStructInst(type)));
			else {
				if (!isBogus(type))
					todo!void("diagnostic -- alias does not resolve to struct (must be bogus or a type parameter)");
				setTarget(structAlias, none!(Ptr!StructInst));
			}
		});
}

//TODO:MOVE
void everyPairWithIndex(T)(
	immutable T[] a,
	scope void delegate(
		ref immutable T,
		ref immutable T,
		immutable size_t,
		immutable size_t,
	) @safe @nogc pure nothrow cb,
) {
	foreach (immutable size_t i; 0 .. size(a))
		foreach (immutable size_t j; 0 .. i)
			cb(at(a, j), at(a, i), j, i);
}

//TODO:MOVE
void everyPair(T)(
	ref immutable T[] a,
	scope void delegate(ref immutable T, ref immutable T) @safe @nogc pure nothrow cb,
) {
	foreach (immutable size_t i; 0 .. size(a))
		foreach (immutable size_t j; 0 .. i)
			cb(at(a, i), at(a, j));
}

immutable(ForcedByValOrRefOrNone) getForcedByValOrRef(immutable Opt!ExplicitByValOrRefAndRange e) {
	if (has(e))
		final switch (force(e).byValOrRef) {
			case ExplicitByValOrRef.byVal:
				return ForcedByValOrRefOrNone.byVal;
			case ExplicitByValOrRef.byRef:
				return ForcedByValOrRefOrNone.byRef;
		}
	else
		return ForcedByValOrRefOrNone.none;
}

immutable(StructBody) checkRecord(Alloc)(
	ref Alloc alloc,
	ref CheckCtx ctx,
	ref immutable CommonTypes commonTypes,
	ref immutable StructsAndAliasesDict structsAndAliasesDict,
	immutable Ptr!StructDecl struct_,
	ref immutable StructDeclAst.Body.Record r,
	ref MutArr!(Ptr!StructInst) delayStructInsts,
) {
	immutable ForcedByValOrRefOrNone forcedByValOrRef = getForcedByValOrRef(r.explicitByValOrRef);
	immutable bool forcedByVal = forcedByValOrRef == ForcedByValOrRefOrNone.byVal;
	immutable RecordField[] fields = mapWithIndex(
		alloc,
		r.fields,
		(immutable size_t index, ref immutable StructDeclAst.Body.Record.Field field) {
			immutable Type fieldType = typeFromAst!Alloc(
				alloc,
				ctx,
				commonTypes,
				field.type,
				structsAndAliasesDict,
				TypeParamsScope(struct_.typeParams),
				someMut(ptrTrustMe_mut(delayStructInsts)));
			if (isPurityWorse(bestCasePurity(fieldType), struct_.purity) && !struct_.purityIsForced)
				addDiag(alloc, ctx, field.range, immutable Diag(
					immutable Diag.PurityOfFieldWorseThanRecord(struct_, fieldType)));
			if (field.isMutable) {
				immutable Opt!(Diag.MutFieldNotAllowed.Reason) reason =
					struct_.purity != Purity.mut && !struct_.purityIsForced
						? some(Diag.MutFieldNotAllowed.Reason.recordIsNotMut)
						: forcedByVal
						? some(Diag.MutFieldNotAllowed.Reason.recordIsForcedByVal)
						: none!(Diag.MutFieldNotAllowed.Reason);
				if (has(reason))
					addDiag(alloc, ctx, field.range, immutable Diag(immutable Diag.MutFieldNotAllowed(force(reason))));
			}
			return immutable RecordField(rangeInFile(ctx, field.range), field.isMutable, field.name, fieldType, index);
		});
	everyPair!RecordField(fields, (ref immutable RecordField a, ref immutable RecordField b) {
		if (symEq(a.name, b.name))
			addDiag(alloc, ctx, b.range,
				immutable Diag(immutable Diag.DuplicateDeclaration(Diag.DuplicateDeclaration.Kind.field, a.name)));
	});

	return immutable StructBody(immutable StructBody.Record(
		immutable RecordFlags(has(r.packed), forcedByValOrRef),
		fields));
}

immutable(StructBody) checkUnion(Alloc)(
	ref Alloc alloc,
	ref CheckCtx ctx,
	ref immutable CommonTypes commonTypes,
	ref immutable StructsAndAliasesDict structsAndAliasesDict,
	immutable Ptr!StructDecl struct_,
	ref immutable StructDeclAst.Body.Union un,
	ref MutArr!(Ptr!StructInst) delayStructInsts,
) {
	immutable Opt!(Ptr!StructInst[]) members = mapOrNone!(Ptr!StructInst)(
		alloc,
		un.members,
		(ref immutable TypeAst.InstStruct it) {
			immutable Opt!(Ptr!StructInst) res = instStructFromAst(
				alloc,
				ctx,
				commonTypes,
				it,
				structsAndAliasesDict,
				TypeParamsScope(struct_.typeParams),
				someMut(ptrTrustMe_mut(delayStructInsts)));
			if (has(res) && isPurityWorse(force(res).bestCasePurity, struct_.purity))
				addDiag(alloc, ctx, it.range, immutable Diag(
					immutable Diag.PurityOfMemberWorseThanUnion(struct_, force(res))));
			return res;
		});
	if (has(members)) {
		everyPairWithIndex!(Ptr!StructInst)(
			force(members),
			// Must name the ignored parameter due to https://issues.dlang.org/show_bug.cgi?id=21165
			(ref immutable Ptr!StructInst a,
			ref immutable Ptr!StructInst b,
			immutable size_t _,
			immutable size_t bIndex) {
				if (ptrEquals(decl(a), decl(b))) {
					immutable Diag diag = immutable Diag(
						immutable Diag.DuplicateDeclaration(Diag.DuplicateDeclaration.Kind.unionMember, a.decl.name));
					addDiag(alloc, ctx, at(un.members, bIndex).range, diag);
				}
			});
		return immutable StructBody(StructBody.Union(force(members)));
	} else
		return immutable StructBody(StructBody.Bogus());
}

void checkStructBodies(Alloc)(
	ref Alloc alloc,
	ref CheckCtx ctx,
	ref immutable CommonTypes commonTypes,
	ref immutable StructsAndAliasesDict structsAndAliasesDict,
	ref StructDecl[] structs,
	ref immutable StructDeclAst[] asts,
	ref MutArr!(Ptr!StructInst) delayStructInsts,
) {
	zipMutPtrFirst!(StructDecl, StructDeclAst)(
		structs,
		asts,
		(Ptr!StructDecl struct_, ref immutable StructDeclAst ast) {
			immutable StructBody body_ = matchStructDeclAstBody!(immutable StructBody)(
				ast.body_,
				(ref immutable StructDeclAst.Body.Builtin) =>
					immutable StructBody(immutable StructBody.Builtin()),
				(ref immutable StructDeclAst.Body.ExternPtr) {
					if (!empty(toArr(ast.typeParams)))
						addDiag(alloc, ctx, ast.range, immutable Diag(immutable Diag.ExternPtrHasTypeParams()));
					return immutable StructBody(immutable StructBody.ExternPtr());
				},
				(ref immutable StructDeclAst.Body.Record it) =>
					checkRecord(
						alloc,
						ctx,
						commonTypes,
						structsAndAliasesDict,
						castImmutable(struct_),
						it,
						delayStructInsts),
				(ref immutable StructDeclAst.Body.Union it) =>
					checkUnion(
						alloc,
						ctx,
						commonTypes,
						structsAndAliasesDict,
						castImmutable(struct_),
						it,
						delayStructInsts));
			setBody(struct_, body_);
		});

	foreach (ref immutable StructDecl struct_; castImmutable(structs)) {
		matchStructBody!void(
			body_(struct_),
			(ref immutable StructBody.Bogus) {},
			(ref immutable StructBody.Builtin) {},
			(ref immutable StructBody.ExternPtr) {},
			(ref immutable StructBody.Record) {},
			(ref immutable StructBody.Union u) {
				foreach (ref immutable Ptr!StructInst member; u.members)
					if (isUnion(body_(member.decl.deref)))
						todo!void("unions can't contain unions");
			});
	}
}

immutable(StructsAndAliasesDict) buildStructsAndAliasesDict(Alloc)(
	ref Alloc alloc,
	ref CheckCtx ctx,
	immutable StructDecl[] structs,
	immutable StructAlias[] aliases,
) {
	DictBuilder!(Sym, StructOrAliasAndIndex, compareSym) d;
	foreach (immutable size_t index; 0 .. size(structs)) {
		immutable Ptr!StructDecl decl = ptrAt(structs, index);
		addToDict(alloc, d, decl.name, immutable StructOrAliasAndIndex(
			immutable StructOrAlias(decl),
			immutable ModuleLocalStructOrAliasIndex(index)));
	}
	foreach (immutable size_t index; 0 .. size(aliases)) {
		immutable Ptr!StructAlias alias_ = ptrAt(aliases, index);
		addToDict(alloc, d, alias_.name, immutable StructOrAliasAndIndex(
			immutable StructOrAlias(alias_),
			immutable ModuleLocalStructOrAliasIndex(index)));
	}
	return finishDict!(Alloc, Sym, StructOrAliasAndIndex, compareSym)(
		alloc,
		d,
		(ref immutable Sym name, ref immutable StructOrAliasAndIndex, ref immutable StructOrAliasAndIndex b) =>
			addDiag(alloc, ctx, b.structOrAlias.range, immutable Diag(
				immutable Diag.DuplicateDeclaration(Diag.DuplicateDeclaration.Kind.structOrAlias, name))));
}

struct FunsAndDict {
	immutable FunDecl[] funs;
	immutable Test[] tests;
	immutable FunsDict funsDict;
}

immutable(ArrWithSize!(Ptr!SpecInst)) checkSpecUses(Alloc)(
	ref Alloc alloc,
	ref CheckCtx ctx,
	ref immutable CommonTypes commonTypes,
	ref immutable SpecUseAst[] asts,
	ref immutable StructsAndAliasesDict structsAndAliasesDict,
	ref immutable SpecsDict specsDict,
	immutable TypeParamsScope typeParamsScope,
) {
	return mapOpWithSize!(Ptr!SpecInst)(alloc, asts, (ref immutable SpecUseAst ast) {
		immutable Opt!(Ptr!SpecDecl) opSpec = tryFindSpec(alloc, ctx, ast.spec.name, ast.range, specsDict);
		if (has(opSpec)) {
			immutable Ptr!SpecDecl spec = force(opSpec);
			immutable Type[] typeArgs = typeArgsFromAsts(
				alloc,
				ctx,
				commonTypes,
				toArr(ast.typeArgs),
				structsAndAliasesDict,
				typeParamsScope,
				noneMut!(Ptr!(MutArr!(Ptr!StructInst))));
			if (!sizeEq(typeArgs, spec.typeParams)) {
				addDiag(alloc, ctx, ast.range, immutable Diag(
					immutable Diag.WrongNumberTypeArgsForSpec(spec, size(spec.typeParams), size(typeArgs))));
				return none!(Ptr!SpecInst);
			} else
				return some(instantiateSpec(alloc, ctx.programState, SpecDeclAndArgs(spec, typeArgs)));
		} else {
			addDiag(alloc, ctx, rangeOfNameAndRange(ast.spec), immutable Diag(
				immutable Diag.NameNotFound(Diag.NameNotFound.Kind.spec, ast.spec.name)));
			return none!(Ptr!SpecInst);
		}
	});
}

immutable(bool) recordIsAlwaysByVal(ref immutable StructBody.Record record) {
	return empty(record.fields) || record.flags.forcedByValOrRef == ForcedByValOrRefOrNone.byVal;
}

immutable(FunsAndDict) checkFuns(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref AllSymbols!SymAlloc allSymbols,
	ref CheckCtx ctx,
	ref immutable CommonTypes commonTypes,
	ref immutable SpecsDict specsDict,
	ref immutable StructDecl[] structs,
	ref immutable StructsAndAliasesDict structsAndAliasesDict,
	ref immutable FunDeclAst[] asts,
	ref immutable TestAst[] testAsts,
) {
	ExactSizeArrBuilder!FunDecl funsBuilder = newExactSizeArrBuilder!FunDecl(alloc, countFunsForStruct(asts, structs));
	foreach (ref immutable FunDeclAst funAst; asts) {
		immutable ArrWithSize!TypeParam typeParams = empty(toArr(funAst.typeParams))
			? collectTypeParams(alloc, ctx, funAst.sig)
			: checkTypeParams(alloc, ctx, funAst.typeParams);
		immutable Ptr!Sig sig = allocate(alloc, checkSig(
			alloc,
			ctx,
			commonTypes,
			funAst.sig,
			toArr(typeParams),
			structsAndAliasesDict,
			noneMut!(Ptr!(MutArr!(Ptr!StructInst)))));
		immutable ArrWithSize!(Ptr!SpecInst) specUses = checkSpecUses(
			alloc,
			ctx,
			commonTypes,
			funAst.specUses,
			structsAndAliasesDict,
			specsDict,
			immutable TypeParamsScope(toArr(typeParams)));
		immutable FunFlags flags = FunFlags(funAst.noCtx, funAst.summon, funAst.unsafe, funAst.trusted, false, false);
		exactSizeArrBuilderAdd(funsBuilder, FunDecl(funAst.isPublic, flags, sig, typeParams, specUses));
	}
	foreach (immutable Ptr!StructDecl struct_; ptrsRange(structs))
		addFunsForStruct(alloc, allSymbols, ctx, funsBuilder, commonTypes, struct_);
	FunDecl[] funs = finish(funsBuilder);
	bool[] usedFuns = fillArr_mut!bool(alloc, size(funs), (immutable size_t) =>
		false);

	immutable FunsDict funsDict = buildMultiDict!(Sym, FunDeclAndIndex, compareSym, FunDecl, Alloc)(
		alloc,
		castImmutable(funs),
		(immutable size_t index, immutable Ptr!FunDecl it) =>
			immutable KeyValuePair!(Sym, FunDeclAndIndex)(
				name(it),
				immutable FunDeclAndIndex(immutable ModuleLocalFunIndex(index), it)));

	foreach (ref const FunDecl f; funs)
		addToMutSymSetOkIfPresent(alloc, ctx.programState.names.funNames, name(f));

	FunDecl[] funsWithAsts = funs[0 .. size(asts)];
	zipMutPtrFirst!(FunDecl, FunDeclAst)(funsWithAsts, asts, (Ptr!FunDecl fun, ref immutable FunDeclAst funAst) {
		overwriteMemory(&fun.body_, matchFunBodyAst(
			funAst.body_,
			(ref immutable FunBodyAst.Builtin) =>
				immutable FunBody(immutable FunBody.Builtin()),
			(ref immutable FunBodyAst.Extern e) {
				if (!fun.noCtx)
					todo!void("'extern' fun must be 'noctx'");
				if (e.isGlobal && arity(fun) != 0)
					todo!void("'extern' fun has parameters");
				return immutable FunBody(nu!(FunBody.Extern)(
					alloc,
					e.isGlobal,
					copyStr(alloc, e.externName),
					has(e.libraryName) ? some(copyStr(alloc, force(e.libraryName))) : none!string));
			},
			(ref immutable ExprAst e) {
				immutable Ptr!FunDecl f = castImmutable(fun);
				return immutable FunBody(checkFunctionBody(
					alloc,
					ctx,
					structsAndAliasesDict,
					commonTypes,
					funsDict,
					usedFuns,
					returnType(f.deref()),
					typeParams(f.deref()),
					params(f.deref()),
					specs(f.deref()),
					f.flags,
					e));
			}));
	});

	immutable Test[] tests = map!(Test, TestAst, Alloc)(alloc, testAsts, (ref immutable TestAst ast) {
		immutable Type voidType = immutable Type(commonTypes.void_);
		return immutable Test(checkFunctionBody!Alloc(
			alloc,
			ctx,
			structsAndAliasesDict,
			commonTypes,
			funsDict,
			usedFuns,
			voidType,
			emptyArr!TypeParam,
			emptyArr!Param,
			emptyArr!(Ptr!SpecInst),
			FunFlags.none,
			ast.body_));
	});

	zipPtrFirst!(FunDecl, bool)(
		castImmutable(funs),
		castImmutable(usedFuns),
		(immutable Ptr!FunDecl fun, ref immutable bool used) {
			if (!used && !fun.isPublic && !okIfUnused(fun))
				addDiag(alloc, ctx, range(fun), immutable Diag(immutable Diag.UnusedPrivateFun(fun)));
		});

	return FunsAndDict(castImmutable(funs), tests, funsDict);
}

immutable(size_t) countFunsForStruct(
	ref immutable FunDeclAst[] asts,
	ref immutable StructDecl[] structs,
) {
	return size(asts) + sum!StructDecl(structs, (ref immutable StructDecl s) {
		if (isRecord(body_(s))) {
			immutable StructBody.Record record = asRecord(body_(s));
			immutable size_t constructors = recordIsAlwaysByVal(record) ? 1 : 2;
			immutable size_t nMutableFields = count!RecordField(record.fields, (ref immutable RecordField it) =>
				it.isMutable);
			return constructors + size(record.fields) + nMutableFields;
		} else
			return immutable size_t(0);
	});
}

void addFunsForStruct(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref AllSymbols!SymAlloc allSymbols,
	ref CheckCtx ctx,
	ref ExactSizeArrBuilder!FunDecl funsBuilder,
	ref immutable CommonTypes commonTypes,
	immutable Ptr!StructDecl struct_,
) {
	if (isRecord(body_(struct_))) {
		immutable StructBody.Record record = asRecord(body_(struct_));

		immutable ArrWithSize!TypeParam typeParams = struct_.typeParams_;
		immutable Type[] typeArgs = mapPtrs(alloc, toArr(typeParams), (immutable Ptr!TypeParam p) =>
			immutable Type(p));
		immutable Type structType = immutable Type(instantiateStructNeverDelay!Alloc(
			alloc,
			ctx.programState,
			immutable StructDeclAndArgs(struct_, typeArgs)));
		immutable Param[] ctorParams = map(alloc, record.fields, (ref immutable RecordField it) =>
			immutable Param(it.range, some(it.name), it.type, it.index));
		FunDecl constructor(immutable Type returnType, immutable FunFlags flags) {
			immutable Ptr!Sig ctorSig = allocate(alloc, immutable Sig(
				fileAndPosFromFileAndRange(struct_.range),
				struct_.name,
				returnType,
				ctorParams));
			return FunDecl(
				struct_.isPublic,
				flags.withOkIfUnused(),
				ctorSig,
				typeParams,
				emptyArrWithSize!(Ptr!SpecInst),
				immutable FunBody(immutable FunBody.CreateRecord()));
		}

		if (recordIsAlwaysByVal(record)) {
			exactSizeArrBuilderAdd(funsBuilder, constructor(structType, FunFlags.justNoCtx));
		} else {
			exactSizeArrBuilderAdd(funsBuilder, constructor(structType, FunFlags.justPreferred));
			immutable Type byValType = immutable Type(
				instantiateStructNeverDelay(
					alloc,
					ctx.programState,
					immutable StructDeclAndArgs(commonTypes.byVal, arrLiteral!Type(alloc, [structType]))));
			exactSizeArrBuilderAdd(funsBuilder, constructor(byValType, FunFlags.justNoCtx));
		}

		foreach (immutable ubyte fieldIndex; 0 .. safeSizeTToU8(size(record.fields))) {
			immutable Ptr!RecordField field = ptrAt(record.fields, fieldIndex);
			immutable Ptr!Sig getterSig = allocate(alloc, immutable Sig(
				fileAndPosFromFileAndRange(field.range),
				field.name,
				field.type,
				arrLiteral!Param(alloc, [
					immutable Param(field.range, some(shortSymAlphaLiteral("a")), structType, 0)])));
			exactSizeArrBuilderAdd(funsBuilder, FunDecl(
				struct_.isPublic,
				FunFlags.justNoCtx,
				getterSig,
				typeParams,
				emptyArrWithSize!(Ptr!SpecInst),
				immutable FunBody(immutable FunBody.RecordFieldGet(fieldIndex))));

			if (field.isMutable) {
				immutable Ptr!Sig setterSig = allocate(alloc, immutable Sig(
					fileAndPosFromFileAndRange(field.range),
					prependSet(allSymbols, field.name),
					immutable Type(commonTypes.void_),
					arrLiteral!Param(alloc, [
						immutable Param(field.range, some(shortSymAlphaLiteral("a")), structType, 0),
						immutable Param(field.range, some(field.name), field.type, 1)])));
				exactSizeArrBuilderAdd(funsBuilder, FunDecl(
					struct_.isPublic,
					FunFlags.justNoCtx,
					setterSig,
					typeParams,
					emptyArrWithSize!(Ptr!SpecInst),
					immutable FunBody(immutable FunBody.RecordFieldSet(fieldIndex))));
			}
		}
	}
}

immutable(SpecsDict) buildSpecsDict(Alloc)(
	ref Alloc alloc,
	ref CheckCtx ctx,
	ref immutable SpecDecl[] specs,
) {
	DictBuilder!(Sym, SpecDeclAndIndex, compareSym) res;
	foreach (immutable size_t index; 0 .. size(specs)) {
		immutable Ptr!SpecDecl spec = ptrAt(specs, index);
		addToDict(alloc, res, spec.name, immutable SpecDeclAndIndex(spec, immutable ModuleLocalSpecIndex(index)));
	}
	return finishDict!(Alloc, Sym, SpecDeclAndIndex, compareSym)(
		alloc,
		res,
		(ref immutable Sym name, ref immutable SpecDeclAndIndex, ref immutable SpecDeclAndIndex b) {
			addDiag(alloc, ctx, b.decl.range, immutable Diag(
				immutable Diag.DuplicateDeclaration(Diag.DuplicateDeclaration.Kind.spec, name)));
		});
}

immutable(Ptr!Module) checkWorkerAfterCommonTypes(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref AllSymbols!SymAlloc allSymbols,
	ref CheckCtx ctx,
	ref immutable CommonTypes commonTypes,
	ref immutable StructsAndAliasesDict structsAndAliasesDict,
	immutable StructAlias[] structAliases,
	ref StructDecl[] structs,
	ref MutArr!(Ptr!StructInst) delayStructInsts,
	immutable FileIndex fileIndex,
	ref immutable ModuleAndNames[] imports,
	ref immutable ModuleAndNames[] reExports,
	ref immutable FileAst ast,
) {
	checkStructBodies!Alloc(alloc, ctx, commonTypes, structsAndAliasesDict, structs, ast.structs, delayStructInsts);
	immutable StructDecl[] structsImmutable = castImmutable(structs);
	foreach (ref const StructDecl s; structs)
		if (isRecord(s.body_))
			foreach (ref immutable RecordField f; asRecord(s.body_).fields)
				addToMutSymSetOkIfPresent(alloc, ctx.programState.names.recordFieldNames, f.name);

	while (!mutArrIsEmpty(delayStructInsts)) {
		Ptr!StructInst i = mustPop(delayStructInsts);
		setBody(i, instantiateStructBody(
			alloc,
			ctx.programState,
			i.declAndArgs,
			someMut(ptrTrustMe_mut(delayStructInsts))));
	}

	immutable SpecDecl[] specs = checkSpecDecls(alloc, ctx, commonTypes, structsAndAliasesDict, ast.specs);
	immutable SpecsDict specsDict = buildSpecsDict(alloc, ctx, specs);
	foreach (ref immutable SpecDecl s; specs)
		addToMutSymSetOkIfPresent(alloc, ctx.programState.names.specNames, s.name);

	immutable FunsAndDict funsAndDict = checkFuns(
		alloc,
		allSymbols,
		ctx,
		commonTypes,
		specsDict,
		structsImmutable,
		structsAndAliasesDict,
		ast.funs,
		ast.tests);

	checkForUnused!Alloc(alloc, ctx, structAliases, castImmutable(structs), specs);

	// Create a module unconditionally so every function will always have containingModule set, even in failure case
	return nu!Module(
		alloc,
		fileIndex,
		nu!ModuleImportsExports(alloc, imports, reExports),
		nu!ModuleArrs(alloc, structsImmutable, specs, funsAndDict.funs, funsAndDict.tests),
		getAllExportedNames(
			alloc,
			ctx.diagsBuilder,
			reExports,
			structsAndAliasesDict,
			specsDict,
			funsAndDict.funsDict));
}

immutable(Dict!(Sym, NameReferents, compareSym)) getAllExportedNames(Alloc)(
	ref Alloc alloc,
	ref ArrBuilder!Diagnostic diagsBuilder,
	ref immutable ModuleAndNames[] reExports,
	ref immutable StructsAndAliasesDict structsAndAliasesDict,
	ref immutable SpecsDict specsDict,
	ref immutable FunsDict funsDict,
) {
	MutDict!(immutable Sym, immutable NameReferents, compareSym) res;
	void add(immutable Sym name, immutable NameReferents cur) @safe @nogc pure nothrow {
		insertOrUpdate!(Alloc, immutable Sym, immutable NameReferents, compareSym)(
			alloc,
			res,
			name,
			() => cur,
			(ref immutable NameReferents prev) {
				if ((has(prev.structOrAlias) && has(cur.structOrAlias)) || (has(prev.spec) && has(cur.spec)))
					todo!void("duplicate export");
				return immutable NameReferents(
					has(prev.structOrAlias) ? prev.structOrAlias : cur.structOrAlias,
					has(prev.spec) ? prev.spec : cur.spec,
					cat(alloc, prev.funs, cur.funs));
			});
	}

	foreach (ref immutable ModuleAndNames e; reExports) {
		dictEach!(Sym, NameReferents, compareSym)(
			e.module_.allExportedNames,
			(ref immutable Sym name, ref immutable NameReferents value) {
				if (!has(e.names) || containsSym(force(e.names), name))
					add(name, value);
			});
	}
	dictEach!(Sym, StructOrAliasAndIndex, compareSym)(
		structsAndAliasesDict,
		(ref immutable Sym name, ref immutable StructOrAliasAndIndex it) {
			if (isPublic(it.structOrAlias))
				add(name, immutable NameReferents(some(it.structOrAlias), none!(Ptr!SpecDecl), emptyArr!(Ptr!FunDecl)));
		});
	dictEach!(Sym, SpecDeclAndIndex, compareSym)(
		specsDict,
		(ref immutable Sym name, ref immutable SpecDeclAndIndex it) {
			if (it.decl.isPublic)
				add(name, immutable NameReferents(none!StructOrAlias, some(it.decl), emptyArr!(Ptr!FunDecl)));
		});
	multiDictEach!(Sym, FunDeclAndIndex, compareSym)(
		funsDict,
		(ref immutable Sym name, immutable FunDeclAndIndex[] funs) {
			immutable Ptr!FunDecl[] funDecls = mapOp!(Ptr!FunDecl)(
				alloc,
				funs,
				(ref immutable FunDeclAndIndex it) =>
					it.decl.isPublic ? some(it.decl) : none!(Ptr!FunDecl));
			add(name, immutable NameReferents(none!StructOrAlias, none!(Ptr!SpecDecl), funDecls));
		});

	return moveToDict!(Sym, NameReferents, compareSym, Alloc)(alloc, res);
}

immutable(BootstrapCheck) checkWorker(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref AllSymbols!SymAlloc allSymbols,
	ref ArrBuilder!Diagnostic diagsBuilder,
	ref ProgramState programState,
	immutable ModuleAndNames[] imports,
	immutable ModuleAndNames[] reExports,
	ref immutable PathAndAst pathAndAst,
	scope immutable(Ptr!CommonTypes) delegate(
		ref CheckCtx,
		ref immutable StructsAndAliasesDict,
		ref MutArr!(Ptr!StructInst),
	) @safe @nogc pure nothrow getCommonTypes,
) {
	checkImportsOrExports(alloc, diagsBuilder, pathAndAst.fileIndex, imports);
	checkImportsOrExports(alloc, diagsBuilder, pathAndAst.fileIndex, reExports);
	immutable FileAst ast = pathAndAst.ast;
	CheckCtx ctx = CheckCtx(
		ptrTrustMe_mut(programState),
		pathAndAst.fileIndex,
		imports,
		reExports,
		// TODO: use temp alloc
		newUsedImportsAndReExports(alloc, imports, reExports),
		// TODO: use temp alloc
		fillArr_mut(alloc, size(ast.structAliases), (immutable size_t) => false),
		// TODO: use temp alloc
		fillArr_mut(alloc, size(ast.structs), (immutable size_t) => false),
		// TODO: use temp alloc
		fillArr_mut(alloc, size(ast.specs), (immutable size_t) => false),
		ptrTrustMe_mut(diagsBuilder));

	// Since structs may refer to each other, first get a structsAndAliasesDict, *then* fill in bodies
	StructDecl[] structs = checkStructsInitial(alloc, ctx, ast.structs);
	foreach (ref const StructDecl s; structs)
		addToMutSymSetOkIfPresent(alloc, programState.names.structAndAliasNames, s.name);
	StructAlias[] structAliases = checkStructAliasesInitial(alloc, ctx, ast.structAliases);
	foreach (ref const StructAlias a; structAliases)
		addToMutSymSetOkIfPresent(alloc, programState.names.structAndAliasNames, a.name);
	immutable StructsAndAliasesDict structsAndAliasesDict =
		buildStructsAndAliasesDict(alloc, ctx, castImmutable(structs), castImmutable(structAliases));

	// We need to create StructInsts when filling in struct bodies.
	// But when creating a StructInst, we usually want to fill in its body.
	// In case the decl body isn't available yet,
	// we'll delay creating the StructInst body, which isn't needed until expr checking.
	MutArr!(Ptr!StructInst) delayStructInsts;

	immutable Ptr!CommonTypes commonTypes = getCommonTypes(ctx, structsAndAliasesDict, delayStructInsts);

	checkStructAliasTargets(
		alloc,
		ctx,
		commonTypes,
		structsAndAliasesDict,
		structAliases,
		ast.structAliases,
		delayStructInsts);

	immutable Ptr!Module mod = checkWorkerAfterCommonTypes(
		alloc,
		allSymbols,
		ctx,
		commonTypes,
		structsAndAliasesDict,
		castImmutable(structAliases),
		structs,
		delayStructInsts,
		pathAndAst.fileIndex,
		imports,
		reExports,
		ast);
	return immutable BootstrapCheck(mod, commonTypes);
}

void checkImportsOrExports(Alloc)(
	ref Alloc alloc,
	ref ArrBuilder!Diagnostic diags,
	immutable FileIndex thisFile,
	ref immutable ModuleAndNames[] imports,
) {
	foreach (ref immutable ModuleAndNames m; imports)
		if (has(m.names))
			foreach (ref immutable Sym name; force(m.names))
				if (!hasKey(m.module_.allExportedNames, name))
					add(alloc, diags, immutable Diagnostic(
						// TODO: use the range of the particular name
						// (by advancing pos by symSize until we get to this name)
						immutable FileAndRange(thisFile, force(m.importSource)),
						allocate(alloc, immutable Diag(immutable Diag.ImportRefersToNothing(name)))));
}
