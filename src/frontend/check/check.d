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
import frontend.check.inferringType : CommonFuns;
import frontend.check.instantiate :
	DelayStructInsts,
	instantiateFun,
	instantiateSpec,
	instantiateStruct,
	instantiateStructBody,
	instantiateStructNeverDelay,
	makeArrayType,
	makeNamedValType,
	TypeParamsScope;
import frontend.check.typeFromAst : instStructFromAst, tryFindSpec, typeArgsFromAsts, typeFromAst;
import frontend.parse.ast :
	ExplicitByValOrRef,
	ExplicitByValOrRefAndRange,
	ExprAst,
	FileAst,
	FunBodyAst,
	FunDeclAst,
	LiteralAst,
	matchFunBodyAst,
	matchLiteralIntOrNat,
	matchSpecBodyAst,
	matchStructDeclAstBody,
	matchTypeAst,
	ParamAst,
	PuritySpecifier,
	rangeOfNameAndRange,
	SigAst,
	SpecBodyAst,
	SpecDeclAst,
	SpecUseAst,
	StructAliasAst,
	StructDeclAst,
	TestAst,
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
	EnumBackingType,
	EnumFunction,
	EnumValue,
	FlagsFunction,
	ForcedByValOrRefOrNone,
	FunBody,
	FunDecl,
	FunDeclAndArgs,
	FunFlags,
	FunInst,
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
	matchType,
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
	only,
	ptrAt,
	ptrsRange,
	size,
	sizeEq,
	toArr;
import util.collection.arrBuilder : add, ArrBuilder, finishArr;
import util.collection.arrUtil :
	arrLiteral,
	cat,
	count,
	eachPair,
	exists,
	fillArr_mut,
	map,
	mapAndFold,
	MapAndFold,
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
import util.collection.arrWithSizeBuilder :
	add,
	ArrWithSizeBuilder,
	arrWithSizeBuilderAsTempArr,
	arrWithSizeBuilderSize,
	finishArrWithSize;
import util.collection.dict : Dict, dictEach, getAt, hasKey, KeyValuePair;
import util.collection.dictBuilder : addToDict, DictBuilder, finishDict;
import util.collection.dictUtil : buildMultiDict;
import util.collection.exactSizeArrBuilder :
	ExactSizeArrBuilder,
	exactSizeArrBuilderAdd,
	finish,
	newExactSizeArrBuilder;
import util.collection.multiDict : multiDictEach, multiDictGetAt;
import util.collection.mutArr : mustPop, MutArr, mutArrIsEmpty;
import util.collection.mutDict : insertOrUpdate, moveToDict, MutDict;
import util.collection.str : copySafeCStr, copyStr, emptySafeCStr;
import util.memory : allocate, nu, nuMut, overwriteMemory;
import util.opt : force, has, none, noneMut, Opt, OptPtr, some, someMut, toOpt;
import util.ptr : castImmutable, Ptr, ptrEquals, ptrTrustMe_mut;
import util.sourceRange : FileAndPos, fileAndPosFromFileAndRange, FileAndRange, FileIndex, RangeWithinFile;
import util.sym :
	addToMutSymSetOkIfPresent,
	AllSymbols,
	compareSym,
	containsSym,
	Operator,
	prependSet,
	shortSymAlphaLiteral,
	shortSymAlphaLiteralValue,
	Sym,
	symEq,
	symForOperator;
import util.types : safeSizeTToU8;
import util.util : todo, unreachable, verify;

struct PathAndAst { //TODO:RENAME
	immutable FileIndex fileIndex;
	immutable FileAst ast;
}

struct BootstrapCheck {
	immutable Ptr!Module module_;
	immutable Ptr!CommonFuns commonFuns;
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
		none!(Ptr!CommonFuns),
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
	immutable Ptr!CommonFuns commonFunsFromBootstrap,
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
		some(commonFunsFromBootstrap),
		(ref CheckCtx, ref immutable(StructsAndAliasesDict), ref MutArr!(Ptr!StructInst)) => commonTypes,
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
	ref ProgramState programState,
	ref immutable StructsAndAliasesDict structsAndAliasesDict,
	immutable Sym name,
	ref MutArr!(Ptr!StructInst) delayedStructInsts,
) {
	immutable Opt!StructOrAliasAndIndex opStructOrAlias = getAt(structsAndAliasesDict, name);
	return has(opStructOrAlias)
		? instantiateNonTemplateStructOrAlias(
			alloc,
			programState,
			delayedStructInsts,
			force(opStructOrAlias).structOrAlias)
		: none!(Ptr!StructInst);
}

immutable(Opt!(Ptr!StructInst)) instantiateNonTemplateStructOrAlias(Alloc)(
	ref Alloc alloc,
	ref ProgramState programState,
	ref MutArr!(Ptr!StructInst) delayedStructInsts,
	immutable StructOrAlias structOrAlias,
) {
	verify(empty(typeParams(structOrAlias)));
	return matchStructOrAlias!(immutable Opt!(Ptr!StructInst))(
		structOrAlias,
		(immutable Ptr!StructAlias it) =>
			target(it),
		(immutable Ptr!StructDecl it) =>
			some(instantiateNonTemplateStructDecl(alloc, programState, delayedStructInsts, it)));
}

immutable(Ptr!StructInst) instantiateNonTemplateStructDeclNeverDelay(Alloc)(
	ref Alloc alloc,
	ref ProgramState programState,
	immutable Ptr!StructDecl structDecl,
) {
	return instantiateStruct(
		alloc,
		programState,
		immutable StructDeclAndArgs(structDecl, emptyArr!Type),
		noneMut!(Ptr!(MutArr!(Ptr!StructInst))));
}

immutable(Ptr!StructInst) instantiateNonTemplateStructDecl(Alloc)(
	ref Alloc alloc,
	ref ProgramState programState,
	ref MutArr!(Ptr!StructInst) delayedStructInsts,
	immutable Ptr!StructDecl structDecl,
) {
	return instantiateStruct(
		alloc,
		programState,
		immutable StructDeclAndArgs(structDecl, emptyArr!Type),
		someMut(ptrTrustMe_mut(delayedStructInsts)));
}

immutable(Ptr!FunInst) instantiateNonTemplateFunInst(Alloc)(
	ref Alloc alloc,
	ref ProgramState programState,
	immutable Ptr!FunDecl funDecl,
) {
	return instantiateFun(alloc, programState, immutable FunDeclAndArgs(funDecl, [], []));
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
			ctx.programState,
			structsAndAliasesDict,
			shortSymAlphaLiteral(name),
			delayedStructInsts);
		if (has(res))
			return force(res);
		else {
			add(alloc, missing, name);
			return instantiateNonTemplateStructDecl(
				alloc,
				ctx.programState,
				delayedStructInsts,
				bogusStructDecl(alloc, 0));
		}
	}

	immutable Ptr!StructInst bool_ = nonTemplate("bool");
	immutable Ptr!StructInst char_ = nonTemplate("char");
	immutable Ptr!StructInst float32 = nonTemplate("float32");
	immutable Ptr!StructInst float64 = nonTemplate("float64");
	immutable Ptr!StructInst int8 = nonTemplate("int8");
	immutable Ptr!StructInst int16 = nonTemplate("int16");
	immutable Ptr!StructInst int32 = nonTemplate("int32");
	immutable Ptr!StructInst int64 = nonTemplate("int64");
	immutable Ptr!StructInst nat8 = nonTemplate("nat8");
	immutable Ptr!StructInst nat16 = nonTemplate("nat16");
	immutable Ptr!StructInst nat32 = nonTemplate("nat32");
	immutable Ptr!StructInst nat64 = nonTemplate("nat64");
	immutable Ptr!StructInst str = nonTemplate("str");
	immutable Ptr!StructInst sym = nonTemplate("sym");
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
	immutable Ptr!StructDecl namedVal = com("named-val", 1);
	immutable Ptr!StructDecl opt = com("opt", 1);
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
		float32,
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
		sym,
		void_,
		ctxStructInst,
		byVal,
		arr,
		fut,
		namedVal,
		opt,
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
		emptySafeCStr,
		shortSymAlphaLiteral("bogus"),
		finishArrWithSize(alloc, typeParams),
		true,
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
	eachPair!TypeParam(toArr(res), (ref immutable TypeParam a, ref immutable TypeParam b) {
		if (symEq(a.name, b.name))
			addDiag(alloc, ctx, b.range, immutable Diag(
				immutable Diag.ParamShadowsPrevious(Diag.ParamShadowsPrevious.Kind.typeParam, b.name)));
	});
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
	return finishArrWithSize(alloc, res);
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
		return immutable SpecDecl(
			rangeInFile(ctx, ast.range),
			copySafeCStr(alloc, ast.docComment),
			ast.isPublic,
			ast.name,
			typeParams,
			body_);
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
			copySafeCStr(alloc, ast.docComment),
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
		(ref immutable StructDeclAst.Body.Enum) =>
			Purity.data,
		(ref immutable StructDeclAst.Body.Flags) =>
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
		(ref immutable StructDeclAst.Body.Enum) => TypeKind.enum_,
		(ref immutable StructDeclAst.Body.Flags) => TypeKind.flags,
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
			copySafeCStr(alloc, ast.docComment),
			ast.name,
			checkTypeParams(alloc, ctx, ast.typeParams),
			ast.isPublic,
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

immutable(StructBody.Enum) checkEnum(Alloc)(
	ref Alloc alloc,
	ref CheckCtx ctx,
	ref immutable CommonTypes commonTypes,
	ref immutable StructsAndAliasesDict structsAndAliasesDict,
	immutable RangeWithinFile range,
	ref immutable StructDeclAst.Body.Enum e,
	ref MutArr!(Ptr!StructInst) delayStructInsts,
) {
	immutable EnumTypeAndMembers tm = checkEnumMembers!Alloc(
		alloc, ctx, commonTypes, structsAndAliasesDict, range, e.typeArg, e.members, delayStructInsts,
		(immutable Opt!EnumValue lastValue, immutable EnumBackingType enumType) =>
			has(lastValue)
				? immutable ValueAndOverflow(
					immutable EnumValue(force(lastValue).value + 1),
					force(lastValue) == maxValue(enumType))
				: immutable ValueAndOverflow(immutable EnumValue(0), false));
	return immutable StructBody.Enum(tm.backingType, tm.memers);
}

immutable(StructBody.Flags) checkFlags(Alloc)(
	ref Alloc alloc,
	ref CheckCtx ctx,
	ref immutable CommonTypes commonTypes,
	ref immutable StructsAndAliasesDict structsAndAliasesDict,
	immutable RangeWithinFile range,
	ref immutable StructDeclAst.Body.Flags f,
	ref MutArr!(Ptr!StructInst) delayStructInsts,
) {
	immutable EnumTypeAndMembers tm = checkEnumMembers(
		alloc, ctx, commonTypes, structsAndAliasesDict, range, f.typeArg, f.members, delayStructInsts,
		(immutable Opt!EnumValue lastValue, immutable EnumBackingType enumType) =>
			has(lastValue)
				? immutable ValueAndOverflow(
					//TODO: if the last value isn't a power of 2, there should be a diagnostic
					immutable EnumValue(force(lastValue).value * 2),
					force(lastValue).value >= maxValue(enumType).value / 2)
				: immutable ValueAndOverflow(immutable EnumValue(1), false));
	return immutable StructBody.Flags(tm.backingType, tm.memers);
}


struct EnumTypeAndMembers {
	immutable EnumBackingType backingType;
	immutable StructBody.Enum.Member[] memers;
}

immutable(EnumTypeAndMembers) checkEnumMembers(Alloc)(
	ref Alloc alloc,
	ref CheckCtx ctx,
	ref immutable CommonTypes commonTypes,
	ref immutable StructsAndAliasesDict structsAndAliasesDict,
	immutable RangeWithinFile range,
	immutable OptPtr!TypeAst optPtrTypeArg,
	immutable ArrWithSize!(StructDeclAst.Body.Enum.Member) memberAsts,
	ref MutArr!(Ptr!StructInst) delayStructInsts,
	scope immutable(ValueAndOverflow) delegate(
		immutable Opt!EnumValue,
		immutable EnumBackingType,
	) @safe @nogc pure nothrow cbGetNextValue,
) {
	immutable TypeParamsScope typeParamsScope = immutable TypeParamsScope(emptyArr!TypeParam);
	immutable Opt!(Ptr!TypeAst) typeAst = toOpt(optPtrTypeArg);
	immutable Type implementationType = has(typeAst)
		? typeFromAst(
			alloc, ctx, commonTypes, force(typeAst), structsAndAliasesDict, typeParamsScope,
			someMut(ptrTrustMe_mut(delayStructInsts)))
		: immutable Type(commonTypes.integrals.nat32);
	immutable EnumBackingType enumType = getEnumTypeFromType(alloc, ctx, range, commonTypes, implementationType);

	immutable StructBody.Enum.Member[] members =
		mapAndFold!(StructBody.Enum.Member, Opt!EnumValue, StructDeclAst.Body.Enum.Member, Alloc)(
			alloc,
			none!EnumValue,
			toArr(memberAsts),
			(ref immutable StructDeclAst.Body.Enum.Member memberAst, immutable Opt!EnumValue lastValue) {
				immutable ValueAndOverflow valueAndOverflow = () {
					if (has(memberAst.value))
						return isSignedEnumBackingType(enumType)
							? matchLiteralIntOrNat!(immutable ValueAndOverflow)(
								force(memberAst.value),
								(ref immutable LiteralAst.Int i) =>
									immutable ValueAndOverflow(immutable EnumValue(i.value), i.overflow),
								(ref immutable LiteralAst.Nat n) =>
									immutable ValueAndOverflow(immutable EnumValue(n.value), n.value > long.max))
							: matchLiteralIntOrNat!(immutable ValueAndOverflow)(
								force(memberAst.value),
								(ref immutable LiteralAst.Int) =>
									todo!(immutable ValueAndOverflow)("signed value in unsigned enum"),
								(ref immutable LiteralAst.Nat n) =>
									immutable ValueAndOverflow(immutable EnumValue(n.value), n.overflow));
					else
						return cbGetNextValue(lastValue, enumType);
				}();
				immutable EnumValue value = valueAndOverflow.value;
				if (valueAndOverflow.overflow || valueOverflows(enumType, value))
					addDiag(alloc, ctx, memberAst.range, immutable Diag(immutable Diag.EnumMemberOverflows(enumType)));
				return immutable MapAndFold!(StructBody.Enum.Member, Opt!EnumValue)(
					immutable StructBody.Enum.Member(rangeInFile(ctx, memberAst.range), memberAst.name, value),
					some(value));
			}).output;

	eachPair!(StructBody.Enum.Member)(
		members,
		(ref immutable StructBody.Enum.Member a, ref immutable StructBody.Enum.Member b) {
			if (a.value == b.value)
				addDiag(alloc, ctx, b.range, immutable Diag(
					immutable Diag.EnumDuplicateValue(isSignedEnumBackingType(enumType), b.value.value)));
		});
	return immutable EnumTypeAndMembers(enumType, members);
}

immutable(bool) valueOverflows(immutable EnumBackingType type, immutable EnumValue value) {
	immutable long v = value.value;
	final switch (type) {
		case EnumBackingType.int8:
			return v < byte.min || v > byte.max;
		case EnumBackingType.int16:
			return v < short.min || v > short.max;
		case EnumBackingType.int32:
			return v < int.min || v > int.max;
		case EnumBackingType.int64:
			return false;
		case EnumBackingType.nat8:
			return v < 0 || v > ubyte.max;
		case EnumBackingType.nat16:
			return v < 0 || v > ushort.max;
		case EnumBackingType.nat32:
			return v < 0 || v > uint.max;
		// For unsigned types, any negative 'value' is actually a wrapped-around large nat.
		case EnumBackingType.nat64:
			return false;
	}
}

immutable(EnumValue) maxValue(immutable EnumBackingType type) {
	return immutable EnumValue(() {
		final switch (type) {
			case EnumBackingType.int8: return byte.max;
			case EnumBackingType.int16: return short.max;
			case EnumBackingType.int32: return int.max;
			case EnumBackingType.int64: return long.max;
			case EnumBackingType.nat8: return ubyte.max;
			case EnumBackingType.nat16: return ushort.max;
			case EnumBackingType.nat32: return uint.max;
			case EnumBackingType.nat64: return ulong.max;
		}
	}());
}

struct ValueAndOverflow {
	immutable EnumValue value;
	immutable bool overflow;
}

immutable(EnumBackingType) defaultEnumBackingType() { return EnumBackingType.nat32; }

immutable(EnumBackingType) getEnumTypeFromType(Alloc)(
	ref Alloc alloc,
	ref CheckCtx ctx,
	ref immutable RangeWithinFile range,
	ref immutable CommonTypes commonTypes,
	ref immutable Type type,
) {
	immutable IntegralTypes integrals = commonTypes.integrals;
	return matchType!EnumBackingType(
		type,
		(ref immutable Type.Bogus) =>
			defaultEnumBackingType(),
		(immutable Ptr!TypeParam) =>
			// enums can't have type params
			unreachable!EnumBackingType(),
		(immutable Ptr!StructInst it) =>
			ptrEquals(integrals.int8, it)
				? EnumBackingType.int8
				: ptrEquals(integrals.int16, it)
				? EnumBackingType.int16
				: ptrEquals(integrals.int32, it)
				? EnumBackingType.int32
				: ptrEquals(integrals.int64, it)
				? EnumBackingType.int64
				: ptrEquals(integrals.nat8, it)
				? EnumBackingType.nat8
				: ptrEquals(integrals.nat16, it)
				? EnumBackingType.nat16
				: ptrEquals(integrals.nat32, it)
				? EnumBackingType.nat32
				: ptrEquals(integrals.nat64, it)
				? EnumBackingType.nat64
				: (() {
					addDiag(alloc, ctx, range, immutable Diag(immutable Diag.EnumBackingTypeInvalid(it)));
					return defaultEnumBackingType();
				})());
}

immutable(Ptr!StructInst) getBackingTypeFromEnumType(
	immutable EnumBackingType a,
	ref immutable CommonTypes commonTypes,
) {
	immutable IntegralTypes integrals = commonTypes.integrals;
	final switch (a) {
		case EnumBackingType.int8:
			return integrals.int8;
		case EnumBackingType.int16:
			return integrals.int16;
		case EnumBackingType.int32:
			return integrals.int32;
		case EnumBackingType.int64:
			return integrals.int64;
		case EnumBackingType.nat8:
			return integrals.nat8;
		case EnumBackingType.nat16:
			return integrals.nat16;
		case EnumBackingType.nat32:
			return integrals.nat32;
		case EnumBackingType.nat64:
			return integrals.nat64;
	}
}

immutable(bool) isSignedEnumBackingType(immutable EnumBackingType a) {
	final switch (a) {
		case EnumBackingType.int8:
		case EnumBackingType.int16:
		case EnumBackingType.int32:
		case EnumBackingType.int64:
			return true;
		case EnumBackingType.nat8:
		case EnumBackingType.nat16:
		case EnumBackingType.nat32:
		case EnumBackingType.nat64:
			return false;
	}
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

immutable(StructBody.Record) checkRecord(Alloc)(
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
		toArr(r.fields),
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

	return immutable StructBody.Record(immutable RecordFlags(has(r.packed), forcedByValOrRef), fields);
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
				(ref immutable StructDeclAst.Body.Enum it) =>
					immutable StructBody(
						checkEnum(alloc, ctx, commonTypes, structsAndAliasesDict, ast.range, it, delayStructInsts)),
				(ref immutable StructDeclAst.Body.Flags it) =>
					immutable StructBody(
						checkFlags(alloc, ctx, commonTypes, structsAndAliasesDict, ast.range, it, delayStructInsts)),
				(ref immutable StructDeclAst.Body.ExternPtr) {
					if (!empty(toArr(ast.typeParams)))
						addDiag(alloc, ctx, ast.range, immutable Diag(immutable Diag.ExternPtrHasTypeParams()));
					return immutable StructBody(immutable StructBody.ExternPtr());
				},
				(ref immutable StructDeclAst.Body.Record it) =>
					immutable StructBody(checkRecord(
						alloc,
						ctx,
						commonTypes,
						structsAndAliasesDict,
						castImmutable(struct_),
						it,
						delayStructInsts)),
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
			(ref immutable StructBody.Enum) {},
			(ref immutable StructBody.Flags) {},
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
	immutable Ptr!CommonFuns commonFuns;
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
	ref immutable Opt!(Ptr!CommonFuns) commonFunsFromBootstrap,
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
		immutable FunFlags flags =
			immutable FunFlags(funAst.noCtx, funAst.summon, funAst.unsafe, funAst.trusted, false, false, false);
		exactSizeArrBuilderAdd(
			funsBuilder,
			FunDecl(copySafeCStr(alloc, funAst.docComment), funAst.isPublic, flags, sig, typeParams, specUses));
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

	immutable Ptr!CommonFuns commonFuns = has(commonFunsFromBootstrap)
		? force(commonFunsFromBootstrap)
		: getCommonFuns(alloc, ctx, funsDict);

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
					has(e.libraryName) ? some(copyStr(alloc, force(e.libraryName))) : none!string));
			},
			(ref immutable ExprAst e) {
				immutable Ptr!FunDecl f = castImmutable(fun);
				return immutable FunBody(checkFunctionBody(
					alloc,
					ctx,
					structsAndAliasesDict,
					commonTypes,
					commonFuns,
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
			commonFuns,
			funsDict,
			usedFuns,
			voidType,
			emptyArr!TypeParam,
			emptyArr!Param,
			emptyArr!(Ptr!SpecInst),
			FunFlags.unsafeSummon,
			ast.body_));
	});

	zipPtrFirst!(FunDecl, bool)(
		castImmutable(funs),
		castImmutable(usedFuns),
		(immutable Ptr!FunDecl fun, ref immutable bool used) {
			if (!used && !fun.isPublic && !okIfUnused(fun))
				addDiag(alloc, ctx, range(fun), immutable Diag(immutable Diag.UnusedPrivateFun(fun)));
		});

	return immutable FunsAndDict(castImmutable(funs), tests, funsDict, commonFuns);
}

immutable(Ptr!CommonFuns) getCommonFuns(Alloc)(
	ref Alloc alloc,
	ref CheckCtx ctx,
	ref immutable FunsDict funsDict,
) {
	immutable(Ptr!FunDecl) commonFunDecl(immutable string name) {
		immutable Sym nameSym = shortSymAlphaLiteral(name);
		immutable FunDeclAndIndex[] funs = multiDictGetAt!(Sym, FunDeclAndIndex, compareSym)(funsDict, nameSym);
		if (size(funs) != 1) {
			addDiag(
				alloc,
				ctx,
				immutable FileAndRange(ctx.fileIndex, RangeWithinFile.empty),
				immutable Diag(immutable Diag.CommonFunMissing(nameSym)));
			return castImmutable(nuMut!FunDecl(
				alloc,
				emptySafeCStr,
				true,
				FunFlags.none,
				allocate(alloc, immutable Sig(
					immutable FileAndPos(ctx.fileIndex, 0),
					nameSym,
					immutable Type(immutable Type.Bogus()),
					emptyArr!Param)),
				emptyArrWithSize!TypeParam(),
				emptyArrWithSize!(Ptr!SpecInst)()));
		} else
			return only(funs).decl;
	}
	immutable(Ptr!FunInst) commonFunInst(immutable string name) {
		return instantiateNonTemplateFunInst(alloc, ctx.programState, commonFunDecl(name));
	}

	immutable Ptr!FunDecl someFun = commonFunDecl("some");
	immutable Ptr!FunInst noneFun = commonFunInst("none");
	return allocate(alloc, immutable CommonFuns(someFun, noneFun));
}

immutable(size_t) countFunsForStruct(
	ref immutable FunDeclAst[] asts,
	ref immutable StructDecl[] structs,
) {
	return size(asts) + sum!StructDecl(structs, (ref immutable StructDecl s) =>
		matchStructBody!(immutable size_t)(
			body_(s),
			(ref immutable StructBody.Bogus) =>
				immutable size_t(0),
			(ref immutable StructBody.Builtin) =>
				immutable size_t(0),
			(ref immutable StructBody.Enum it) =>
				// '==', 'to-intXX'/'to-natXX', 'enum-members', and a constructor for each member
				3 + size(it.members),
			(ref immutable StructBody.Flags it) =>
				// 'empty', 'all', '==', '~', '|', '&', 'to-intXX'/'to-natXX', 'flags-members',
				// and a constructor for each member
				8 + size(it.members),
			(ref immutable StructBody.ExternPtr) =>
				immutable size_t(0),
			(ref immutable StructBody.Record it) {
				immutable size_t nConstructors = recordIsAlwaysByVal(it) ? 1 : 2;
				immutable size_t nMutableFields = count!RecordField(it.fields, (ref immutable RecordField field) =>
					field.isMutable);
				return nConstructors + size(it.fields) + nMutableFields;
			},
			(ref immutable StructBody.Union) =>
				immutable size_t(0)));
}

void addFunsForStruct(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref AllSymbols!SymAlloc allSymbols,
	ref CheckCtx ctx,
	ref ExactSizeArrBuilder!FunDecl funsBuilder,
	ref immutable CommonTypes commonTypes,
	immutable Ptr!StructDecl struct_,
) {
	matchStructBody!void(
		body_(struct_),
		(ref immutable StructBody.Bogus) {},
		(ref immutable StructBody.Builtin) {},
		(ref immutable StructBody.Enum it) {
			addFunsForEnum(alloc, allSymbols, ctx, funsBuilder, commonTypes, struct_, it);
		},
		(ref immutable StructBody.Flags it) {
			addFunsForFlags(alloc, allSymbols, ctx, funsBuilder, commonTypes, struct_, it);
		},
		(ref immutable StructBody.ExternPtr) {},
		(ref immutable StructBody.Record it) {
			addFunsForRecord(alloc, allSymbols, ctx, funsBuilder, commonTypes, struct_, it);
		},
		(ref immutable StructBody.Union) {});
}

void addFunsForEnum(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref AllSymbols!SymAlloc allSymbols,
	ref CheckCtx ctx,
	ref ExactSizeArrBuilder!FunDecl funsBuilder,
	ref immutable CommonTypes commonTypes,
	immutable Ptr!StructDecl struct_,
	ref immutable StructBody.Enum enum_,
) {
	immutable Type enumType =
		immutable Type(instantiateNonTemplateStructDeclNeverDelay(alloc, ctx.programState, struct_));
	immutable bool isPublic = struct_.isPublic;
	immutable FileAndRange range = struct_.range;
	addEnumFlagsCommonFunctions(
		alloc, funsBuilder, ctx.programState, isPublic, range, enumType, enum_.backingType, commonTypes,
		shortSymAlphaLiteral("enum-members"));
	foreach (ref immutable StructBody.Enum.Member member; enum_.members)
		exactSizeArrBuilderAdd(funsBuilder, enumOrFlagsConstructor(alloc, struct_.isPublic, enumType, member));
}

void addFunsForFlags(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref AllSymbols!SymAlloc allSymbols,
	ref CheckCtx ctx,
	ref ExactSizeArrBuilder!FunDecl funsBuilder,
	ref immutable CommonTypes commonTypes,
	immutable Ptr!StructDecl struct_,
	ref immutable StructBody.Flags flags,
) {
	immutable Type type =
		immutable Type(instantiateNonTemplateStructDeclNeverDelay(alloc, ctx.programState, struct_));
	immutable bool isPublic = struct_.isPublic;
	immutable FileAndRange range = struct_.range;
	addEnumFlagsCommonFunctions(
		alloc, funsBuilder, ctx.programState, isPublic, range, type, flags.backingType, commonTypes,
		ctx.programState.symFlagsMembers);
	exactSizeArrBuilderAdd(funsBuilder, flagsEmptyFunction(alloc, isPublic, range, type));
	exactSizeArrBuilderAdd(funsBuilder, flagsAllFunction(alloc, isPublic, range, type));
	exactSizeArrBuilderAdd(funsBuilder, flagsNegateFunction(alloc, isPublic, range, type));
	exactSizeArrBuilderAdd(funsBuilder, flagsUnionOrIntersectFunction(
		alloc, isPublic, range, type, Operator.or1, EnumFunction.union_));
	exactSizeArrBuilderAdd(funsBuilder, flagsUnionOrIntersectFunction(
		alloc, isPublic, range, type, Operator.and1, EnumFunction.intersect));

	foreach (ref immutable StructBody.Enum.Member member; flags.members)
		exactSizeArrBuilderAdd(funsBuilder, enumOrFlagsConstructor(alloc, isPublic, type, member));
}

void addEnumFlagsCommonFunctions(Alloc)(
	ref Alloc alloc,
	ref ExactSizeArrBuilder!FunDecl funsBuilder,
	ref ProgramState programState,
	immutable bool isPublic,
	ref immutable FileAndRange range,
	ref immutable Type type,
	immutable EnumBackingType backingType,
	ref immutable CommonTypes commonTypes,
	immutable Sym membersName,
) {
	exactSizeArrBuilderAdd(funsBuilder, enumEqualFunction(alloc, isPublic, range, type, commonTypes));
	exactSizeArrBuilderAdd(funsBuilder, enumToIntegralFunction(alloc, isPublic, range, backingType, type, commonTypes));
	exactSizeArrBuilderAdd(
		funsBuilder,
		enumOrFlagsMembersFunction(alloc, programState, isPublic, range, membersName, type, commonTypes));
}

FunDecl enumOrFlagsConstructor(Alloc)(
	ref Alloc alloc,
	immutable bool isPublic,
	ref immutable Type enumType,
	ref immutable StructBody.Enum.Member member,
) {
	return FunDecl(
		emptySafeCStr,
		isPublic,
		FunFlags.generatedNoCtx,
		allocate(alloc, immutable Sig(
			fileAndPosFromFileAndRange(member.range),
			member.name,
			enumType,
			emptyArr!Param)),
		emptyArrWithSize!TypeParam,
		emptyArrWithSize!(Ptr!SpecInst),
		immutable FunBody(immutable FunBody.CreateEnum(member.value)));
}

FunDecl enumEqualFunction(Alloc)(
	ref Alloc alloc,
	immutable bool isPublic,
	immutable FileAndRange fileAndRange,
	ref immutable Type enumType,
	ref immutable CommonTypes commonTypes,
) {
	return FunDecl(
		emptySafeCStr,
		isPublic,
		FunFlags.generatedNoCtx,
		allocate(alloc, immutable Sig(
			fileAndPosFromFileAndRange(fileAndRange),
			symForOperator(Operator.equal),
			immutable Type(commonTypes.bool_),
			arrLiteral!Param(alloc, [
				immutable Param(fileAndRange, some(shortSymAlphaLiteral("a")), enumType, 0),
				immutable Param(fileAndRange, some(shortSymAlphaLiteral("b")), enumType, 1)]))),
		emptyArrWithSize!TypeParam,
		emptyArrWithSize!(Ptr!SpecInst),
		immutable FunBody(EnumFunction.equal));
}

FunDecl flagsEmptyFunction(Alloc)(
	ref Alloc alloc,
	immutable bool isPublic,
	immutable FileAndRange fileAndRange,
	ref immutable Type enumType,
) {
	return FunDecl(
		emptySafeCStr,
		isPublic,
		FunFlags.generatedNoCtx,.
		allocate(alloc, immutable Sig(
			fileAndPosFromFileAndRange(fileAndRange),
			shortSymAlphaLiteral("empty"),
			enumType,
			emptyArr!Param)),
		emptyArrWithSize!TypeParam,
		emptyArrWithSize!(Ptr!SpecInst),
		immutable FunBody(FlagsFunction.empty));
}

FunDecl flagsAllFunction(Alloc)(
	ref Alloc alloc,
	immutable bool isPublic,
	immutable FileAndRange fileAndRange,
	ref immutable Type enumType,
) {
	return FunDecl(
		emptySafeCStr,
		isPublic,
		FunFlags.generatedNoCtx,.
		allocate(alloc, immutable Sig(
			fileAndPosFromFileAndRange(fileAndRange),
			shortSymAlphaLiteral("all"),
			enumType,
			emptyArr!Param)),
		emptyArrWithSize!TypeParam,
		emptyArrWithSize!(Ptr!SpecInst),
		immutable FunBody(FlagsFunction.all));
}

FunDecl flagsNegateFunction(Alloc)(
	ref Alloc alloc,
	immutable bool isPublic,
	immutable FileAndRange fileAndRange,
	ref immutable Type enumType,
) {
	return FunDecl(
		emptySafeCStr,
		isPublic,
		FunFlags.generatedNoCtx,
		allocate(alloc, immutable Sig(
			fileAndPosFromFileAndRange(fileAndRange),
			symForOperator(Operator.tilde),
			enumType,
			arrLiteral!Param(alloc, [immutable Param(fileAndRange, some(shortSymAlphaLiteral("a")), enumType, 0)]))),
		emptyArrWithSize!TypeParam,
		emptyArrWithSize!(Ptr!SpecInst),
		immutable FunBody(FlagsFunction.negate));
}

FunDecl enumToIntegralFunction(Alloc)(
	ref Alloc alloc,
	immutable bool isPublic,
	immutable FileAndRange fileAndRange,
	immutable EnumBackingType enumBackingType,
	immutable Type enumType,
	ref immutable CommonTypes commonTypes,
) {
	return FunDecl(
		emptySafeCStr,
		isPublic,
		FunFlags.generatedNoCtx,
		allocate(alloc, immutable Sig(
			fileAndPosFromFileAndRange(fileAndRange),
			enumToIntegralName(enumBackingType),
			immutable Type(getBackingTypeFromEnumType(enumBackingType, commonTypes)),
			arrLiteral!Param(alloc, [immutable Param(fileAndRange, some(shortSymAlphaLiteral("a")), enumType, 0)]))),
		emptyArrWithSize!TypeParam,
		emptyArrWithSize!(Ptr!SpecInst),
		immutable FunBody(EnumFunction.toIntegral));
}

FunDecl enumOrFlagsMembersFunction(Alloc)(
	ref Alloc alloc,
	ref ProgramState programState,
	immutable bool isPublic,
	ref immutable FileAndRange fileAndRange,
	immutable Sym name,
	ref immutable Type enumType,
	ref immutable CommonTypes commonTypes,
) {
	return FunDecl(
		emptySafeCStr,
		isPublic,
		FunFlags.generatedNoCtx,
		allocate(alloc, immutable Sig(
			fileAndPosFromFileAndRange(fileAndRange),
			name,
			immutable Type(makeArrayType(
				alloc,
				programState,
				commonTypes,
				immutable Type(makeNamedValType(alloc, programState, commonTypes, enumType)))),
			emptyArr!Param)),
		emptyArrWithSize!TypeParam,
		emptyArrWithSize!(Ptr!SpecInst),
		immutable FunBody(EnumFunction.members));
}

FunDecl flagsUnionOrIntersectFunction(Alloc)(
	ref Alloc alloc,
	immutable bool isPublic,
	immutable FileAndRange fileAndRange,
	immutable Type enumType,
	immutable Operator operator,
	immutable EnumFunction fn,
) {
	return FunDecl(
		emptySafeCStr,
		isPublic,
		FunFlags.generatedNoCtx,
		allocate(alloc, immutable Sig(
			fileAndPosFromFileAndRange(fileAndRange),
			symForOperator(operator),
			enumType,
			arrLiteral!Param(alloc, [
				immutable Param(fileAndRange, some(shortSymAlphaLiteral("a")), enumType, 0),
				immutable Param(fileAndRange, some(shortSymAlphaLiteral("b")), enumType, 0)]))),
		emptyArrWithSize!TypeParam,
		emptyArrWithSize!(Ptr!SpecInst),
		immutable FunBody(fn));
}

//TODO: actually, we should record the type name used,
//so if they had 'e enum<size_t>' we should have 'to-size_t' not 'to-nat64'
immutable(Sym) enumToIntegralName(immutable EnumBackingType a) {
	return shortSymAlphaLiteral(() {
		final switch (a) {
			case EnumBackingType.int8:
				return "to-int8";
			case EnumBackingType.int16:
				return "to-int16";
			case EnumBackingType.int32:
				return "to-int32";
			case EnumBackingType.int64:
				return "to-int64";
			case EnumBackingType.nat8:
				return "to-nat8";
			case EnumBackingType.nat16:
				return "to-nat16";
			case EnumBackingType.nat32:
				return "to-nat32";
			case EnumBackingType.nat64:
				return "to-nat64";
		}
	}());
}

void addFunsForRecord(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref AllSymbols!SymAlloc allSymbols,
	ref CheckCtx ctx,
	ref ExactSizeArrBuilder!FunDecl funsBuilder,
	ref immutable CommonTypes commonTypes,
	immutable Ptr!StructDecl struct_,
	ref immutable StructBody.Record record,
) {
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
			emptySafeCStr,
			struct_.isPublic,
			flags.withOkIfUnused(),
			ctorSig,
			typeParams,
			emptyArrWithSize!(Ptr!SpecInst),
			immutable FunBody(immutable FunBody.CreateRecord()));
	}

	if (recordIsAlwaysByVal(record)) {
		exactSizeArrBuilderAdd(funsBuilder, constructor(structType, FunFlags.generatedNoCtx));
	} else {
		exactSizeArrBuilderAdd(funsBuilder, constructor(structType, FunFlags.generatedPreferred));
		immutable Type byValType = immutable Type(
			instantiateStructNeverDelay(
				alloc,
				ctx.programState,
				immutable StructDeclAndArgs(commonTypes.byVal, arrLiteral!Type(alloc, [structType]))));
		exactSizeArrBuilderAdd(funsBuilder, constructor(byValType, FunFlags.generatedNoCtx));
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
			emptySafeCStr,
			struct_.isPublic,
			FunFlags.generatedNoCtx,
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
				emptySafeCStr,
				struct_.isPublic,
				FunFlags.generatedNoCtx,
				setterSig,
				typeParams,
				emptyArrWithSize!(Ptr!SpecInst),
				immutable FunBody(immutable FunBody.RecordFieldSet(fieldIndex))));
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

struct ModuleAndCommonFuns {
	immutable Ptr!Module module_;
	immutable Ptr!CommonFuns commonFuns;
}

immutable(ModuleAndCommonFuns) checkWorkerAfterCommonTypes(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref AllSymbols!SymAlloc allSymbols,
	ref CheckCtx ctx,
	ref immutable CommonTypes commonTypes,
	ref immutable Opt!(Ptr!CommonFuns) commonFunsFromBootstrap,
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
		commonFunsFromBootstrap,
		specsDict,
		structsImmutable,
		structsAndAliasesDict,
		ast.funs,
		ast.tests);

	checkForUnused!Alloc(alloc, ctx, structAliases, castImmutable(structs), specs);

	// Create a module unconditionally so every function will always have containingModule set, even in failure case
	immutable Ptr!Module module_ = nu!Module(
		alloc,
		fileIndex,
		copySafeCStr(alloc, ast.docComment),
		nu!ModuleImportsExports(alloc, imports, reExports),
		nu!ModuleArrs(alloc, structsImmutable, specs, funsAndDict.funs, funsAndDict.tests),
		getAllExportedNames(
			alloc,
			ctx.diagsBuilder,
			reExports,
			structsAndAliasesDict,
			specsDict,
			funsAndDict.funsDict,
			fileIndex));
	return immutable ModuleAndCommonFuns(module_, funsAndDict.commonFuns);
}

immutable(Dict!(Sym, NameReferents, compareSym)) getAllExportedNames(Alloc)(
	ref Alloc alloc,
	ref ArrBuilder!Diagnostic diagsBuilder,
	ref immutable ModuleAndNames[] reExports,
	ref immutable StructsAndAliasesDict structsAndAliasesDict,
	ref immutable SpecsDict specsDict,
	ref immutable FunsDict funsDict,
	immutable FileIndex fileIndex,
) {
	MutDict!(immutable Sym, immutable NameReferents, compareSym) res;
	void addExport(immutable Sym name, immutable NameReferents cur, immutable FileAndRange range)
		@safe @nogc pure nothrow {
		insertOrUpdate!(Alloc, immutable Sym, immutable NameReferents, compareSym)(
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
					add(alloc, diagsBuilder, immutable Diagnostic(
						range,
						allocate(alloc, immutable Diag(immutable Diag.DuplicateExports(force(kind), name)))));
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
					addExport(name, value, immutable FileAndRange(
						fileIndex,
						has(e.importSource) ? force(e.importSource) : RangeWithinFile.empty));
			});
	}
	dictEach!(Sym, StructOrAliasAndIndex, compareSym)(
		structsAndAliasesDict,
		(ref immutable Sym name, ref immutable StructOrAliasAndIndex it) {
			if (isPublic(it.structOrAlias))
				addExport(
					name,
					immutable NameReferents(some(it.structOrAlias), none!(Ptr!SpecDecl), emptyArr!(Ptr!FunDecl)),
					range(it.structOrAlias));
		});
	dictEach!(Sym, SpecDeclAndIndex, compareSym)(
		specsDict,
		(ref immutable Sym name, ref immutable SpecDeclAndIndex it) {
			if (it.decl.isPublic)
				addExport(
					name,
					immutable NameReferents(none!StructOrAlias, some(it.decl), emptyArr!(Ptr!FunDecl)),
					it.decl.range);
		});
	multiDictEach!(Sym, FunDeclAndIndex, compareSym)(
		funsDict,
		(ref immutable Sym name, immutable FunDeclAndIndex[] funs) {
			immutable Ptr!FunDecl[] funDecls = mapOp!(Ptr!FunDecl)(
				alloc,
				funs,
				(ref immutable FunDeclAndIndex it) =>
					it.decl.isPublic ? some(it.decl) : none!(Ptr!FunDecl));
			if (!empty(funDecls))
				addExport(
					name,
					immutable NameReferents(none!StructOrAlias, none!(Ptr!SpecDecl), funDecls),
					// This argument doesn't matter because a function never results in a duplicate export error
					immutable FileAndRange(fileIndex, RangeWithinFile.empty));
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
	immutable Opt!(Ptr!CommonFuns) commonFunsFromBootstrap,
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

	immutable ModuleAndCommonFuns res = checkWorkerAfterCommonTypes(
		alloc,
		allSymbols,
		ctx,
		commonTypes,
		commonFunsFromBootstrap,
		structsAndAliasesDict,
		castImmutable(structAliases),
		structs,
		delayStructInsts,
		pathAndAst.fileIndex,
		imports,
		reExports,
		ast);
	return immutable BootstrapCheck(res.module_, res.commonFuns, commonTypes);
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
