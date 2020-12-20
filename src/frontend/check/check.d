module frontend.check.check;

@safe @nogc pure nothrow:

import frontend.check.checkCtx : addDiag, CheckCtx, posInFile, rangeInFile;
import frontend.check.checkExpr : checkFunctionBody;
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
	TypeAst,
	TypeParamAst;
import frontend.programState : ProgramState;
import model.diag : Diag, Diagnostic, TypeKind;
import model.model :
	arity,
	asRecord,
	asStructDecl,
	bestCasePurity,
	body_,
	CommonTypes,
	decl,
	ForcedByValOrRef,
	FunBody,
	FunDecl,
	FunFlags,
	FunKind,
	FunKindAndStructs,
	FunsMap,
	IntegralTypes,
	isPublic,
	isPurityWorse,
	isRecord,
	isUnion,
	matchStructBody,
	matchStructOrAlias,
	Module,
	ModuleArrs,
	ModuleDicts,
	ModuleImportsExports,
	ModuleAndNameReferents,
	name,
	NameAndReferents,
	noCtx,
	Param,
	Purity,
	range,
	RecordField,
	setBody,
	setTarget,
	Sig,
	SpecBody,
	SpecDecl,
	SpecDeclAndArgs,
	SpecInst,
	SpecsMap,
	StructAlias,
	StructBody,
	StructDecl,
	StructDeclAndArgs,
	StructInst,
	StructOrAlias,
	StructsAndAliasesMap,
	target,
	Type,
	TypeParam,
	typeParams;
import util.bools : Bool, False, True;
import util.collection.arr :
	Arr,
	ArrWithSize,
	at,
	castImmutable,
	empty,
	emptyArr,
	emptyArrWithSize,
	ptrAt,
	ptrsRange,
	arrRange = range,
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
	count,
	exists,
	map,
	mapOpWithSize,
	mapOrNone,
	mapPtrs,
	mapToMut,
	mapWithIndex,
	mapWithSizeWithIndex,
	slice,
	sum,
	zipFirstMut,
	zipMutPtrFirst;
import util.collection.dict : getAt, KeyValuePair;
import util.collection.dictBuilder : addToDict, DictBuilder, finishDict;
import util.collection.dictUtil : buildDict, buildMultiDict;
import util.collection.exactSizeArrBuilder :
	ExactSizeArrBuilder,
	exactSizeArrBuilderAdd,
	finish,
	newExactSizeArrBuilder;
import util.collection.multiDict : multiDictGetAt;
import util.collection.mutArr : mustPop, MutArr, mutArrIsEmpty;
import util.collection.str : copyStr, Str, strLiteral;
import util.memory : allocate, nu, nuMut, overwriteMemory;
import util.opt : force, has, mapOption, none, noneMut, Opt, some, someMut;
import util.ptr : castImmutable, Ptr, ptrEquals, ptrTrustMe_mut;
import util.sourceRange : fileAndPosFromFileAndRange, FileAndRange, FileIndex, RangeWithinFile;
import util.sym :
	addToMutSymSetOkIfPresent,
	AllSymbols,
	compareSym,
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

struct ModuleAndNames {
	immutable Ptr!Module module_;
	immutable RangeWithinFile range;
	immutable Opt!(Arr!Sym) names;
}

immutable(BootstrapCheck) checkBootstrapNz(Alloc, SymAlloc)(
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
		ref immutable StructsAndAliasesMap structsAndAliasesMap,
		ref MutArr!(Ptr!StructInst) delayedStructInsts) =>
			getCommonTypes(alloc, ctx, structsAndAliasesMap, delayedStructInsts));
}

immutable(Ptr!Module) check(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref AllSymbols!SymAlloc allSymbols,
	ref ArrBuilder!Diagnostic diagsBuilder,
	ref ProgramState programState,
	ref immutable Arr!ModuleAndNames imports,
	ref immutable Arr!ModuleAndNames exports,
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
		(ref CheckCtx, ref immutable StructsAndAliasesMap, ref MutArr!(Ptr!StructInst)) => commonTypes,
	).module_;
}

private:

immutable(Opt!(Ptr!StructDecl)) getCommonTemplateType(
	ref immutable StructsAndAliasesMap structsAndAliasesMap,
	immutable Sym name,
	immutable size_t expectedTypeParams,
) {
	immutable Opt!StructOrAlias res = getAt(structsAndAliasesMap, name);
	if (has(res)) {
		// TODO: may fail -- builtin Template should not be an alias
		immutable Ptr!StructDecl decl = asStructDecl(force(res));
		if (size(decl.typeParams) != expectedTypeParams)
			todo!void("getCommonTemplateType");
		return some(decl);
	} else
		return none!(Ptr!StructDecl);
}

immutable(Opt!(Ptr!StructInst)) getCommonNonTemplateType(Alloc)(
	ref Alloc alloc,
	ref CheckCtx ctx,
	ref immutable StructsAndAliasesMap structsAndAliasesMap,
	immutable Sym name,
	ref MutArr!(Ptr!StructInst) delayedStructInsts,
) {
	immutable Opt!StructOrAlias opStructOrAlias = getAt(structsAndAliasesMap, name);
	return has(opStructOrAlias)
		? instantiateNonTemplateStructOrAlias(alloc, ctx, delayedStructInsts, force(opStructOrAlias))
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
	ref immutable StructsAndAliasesMap structsAndAliasesMap,
	ref MutArr!(Ptr!StructInst) delayedStructInsts,
) {
	ArrBuilder!Str missing = ArrBuilder!Str();

	immutable(Ptr!StructInst) nonTemplate(immutable string name) {
		immutable Opt!(Ptr!StructInst) res = getCommonNonTemplateType(
			alloc,
			ctx,
			structsAndAliasesMap,
			shortSymAlphaLiteral(name),
			delayedStructInsts);
		if (has(res))
			return force(res);
		else {
			add(alloc, missing, strLiteral(name));
			return instantiateNonTemplateStructDecl(alloc, ctx, delayedStructInsts, bogusStructDecl(alloc, 0));
		}
	}

	immutable Ptr!StructInst bool_ = nonTemplate("bool");
	immutable Ptr!StructInst char_ = nonTemplate("char");
	immutable Ptr!StructInst float64 = nonTemplate("float");
	immutable Ptr!StructInst int8 = nonTemplate("int8");
	immutable Ptr!StructInst int16 = nonTemplate("int16");
	immutable Ptr!StructInst int32 = nonTemplate("int32");
	immutable Ptr!StructInst int64 = nonTemplate("int64");
	immutable Ptr!StructInst nat8 = nonTemplate("nat8");
	immutable Ptr!StructInst nat16 = nonTemplate("nat16");
	immutable Ptr!StructInst nat32 = nonTemplate("nat32");
	immutable Ptr!StructInst nat64 = nonTemplate("nat64");
	immutable Ptr!StructInst str = nonTemplate("str");
	immutable Ptr!StructInst void_ = nonTemplate("void");
	immutable Ptr!StructInst ctxStructInst = nonTemplate("ctx");

	immutable(Ptr!StructDecl) com(immutable string name, immutable size_t nTypeParameters) {
		immutable Opt!(Ptr!StructDecl) res = getCommonTemplateType(
			structsAndAliasesMap,
			shortSymAlphaLiteral(name),
			nTypeParameters);
		if (has(res))
			return force(res);
		else {
			add(alloc, missing, strLiteral(name));
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
	immutable Ptr!StructDecl funMut0 = com("fun-mut0", 1);
	immutable Ptr!StructDecl funMut1 = com("fun-mut1", 2);
	immutable Ptr!StructDecl funMut2 = com("fun-mut2", 3);
	immutable Ptr!StructDecl funMut3 = com("fun-mut3", 4);
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

	immutable Arr!Str missingArr = finishArr(alloc, missing);

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
				fun3])),
			immutable FunKindAndStructs(FunKind.mut, arrLiteral!(Ptr!StructDecl)(alloc, [
				funMut0,
				funMut1,
				funMut2,
				funMut3])),
			immutable FunKindAndStructs(FunKind.ref_, arrLiteral!(Ptr!StructDecl)(alloc, [
				funRef0,
				funRef1,
				funRef2,
				funRef3]))]));
}

immutable(Ptr!StructDecl) bogusStructDecl(Alloc)(ref Alloc alloc, immutable size_t nTypeParameters) {
	ArrWithSizeBuilder!TypeParam typeParams;
	immutable FileAndRange fileAndRange = immutable FileAndRange(immutable FileIndex(0), RangeWithinFile.empty);
	foreach (immutable size_t i; 0..nTypeParameters)
		add(alloc, typeParams, immutable TypeParam(fileAndRange, shortSymAlphaLiteral("bogus"), i));
	Ptr!StructDecl res = nuMut!StructDecl(
		alloc,
		fileAndRange,
		True,
		shortSymAlphaLiteral("bogus"),
		finishArr(alloc, typeParams),
		Purity.data,
		False);
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
	immutable Arr!TypeParam typeParams = toArr(res);
	foreach (immutable size_t i; 0..size(typeParams))
		foreach (immutable size_t prev_i; 0..i) {
			immutable TypeParam tp = at(typeParams, i);
			if (symEq(tp.name, at(typeParams, prev_i).name))
				addDiag(alloc, ctx, tp.range, Diag(
					Diag.ParamShadowsPrevious(Diag.ParamShadowsPrevious.Kind.typeParam, tp.name)));
		}
	return res;
}

void collectTypeParamsInAst(Alloc)(
	ref Alloc alloc,
	ref const CheckCtx ctx,
	ref immutable TypeAst ast,
	ref ArrWithSizeBuilder!TypeParam res,
) {
	matchTypeAst(
		ast,
		(ref immutable TypeAst.TypeParam tp) {
			immutable Arr!TypeParam a = arrWithSizeBuilderAsTempArr(res);
			if (!exists(a, (ref immutable TypeParam it) => symEq(it.name, tp.name))) {
				add(alloc, res, immutable TypeParam(rangeInFile(ctx, tp.range), tp.name, arrWithSizeBuilderSize(res)));
			}
		},
		(ref immutable TypeAst.InstStruct i) {
			foreach (ref immutable TypeAst arg; arrRange(toArr(i.typeArgs)))
				collectTypeParamsInAst(alloc, ctx, arg, res);
		});
}

immutable(ArrWithSize!TypeParam) collectTypeParams(Alloc)(
	ref Alloc alloc,
	ref const CheckCtx ctx,
	ref immutable SigAst ast,
) {
	ArrWithSizeBuilder!TypeParam res;
	collectTypeParamsInAst(alloc, ctx, ast.returnType, res);
	foreach (ref immutable ParamAst p; arrRange(toArr(ast.params)))
		collectTypeParamsInAst(alloc, ctx, p.type, res);
	return finishArr(alloc, res);
}

immutable(Arr!Param) checkParams(Alloc)(
	ref Alloc alloc,
	ref CheckCtx ctx,
	immutable Arr!ParamAst asts,
	ref immutable StructsAndAliasesMap structsAndAliasesMap,
	ref immutable TypeParamsScope typeParamsScope,
	ref DelayStructInsts delayStructInsts,
) {
	immutable Arr!Param params = mapWithIndex!Param(
		alloc,
		asts,
		(immutable size_t index, ref immutable ParamAst ast) {
			immutable Type type = typeFromAst(
				alloc,
				ctx,
				ast.type,
				structsAndAliasesMap,
				typeParamsScope,
				delayStructInsts);
			return immutable Param(rangeInFile(ctx, ast.range), ast.name.name, type, index);
		});
	foreach (immutable size_t i; 0..size(params))
		foreach (immutable size_t prev_i; 0..i) {
			immutable Param param = at(params, i);
			if (symEq(param.name, at(params, prev_i).name))
				addDiag(alloc, ctx, at(params, i).range, Diag(
					Diag.ParamShadowsPrevious(Diag.ParamShadowsPrevious.Kind.param, param.name)));
		}
	return params;
}

immutable(Sig) checkSig(Alloc)(
	ref Alloc alloc,
	ref CheckCtx ctx,
	ref immutable SigAst ast,
	immutable Arr!TypeParam typeParams,
	ref immutable StructsAndAliasesMap structsAndAliasesMap,
	DelayStructInsts delayStructInsts
) {
	immutable TypeParamsScope typeParamsScope = TypeParamsScope(typeParams);
	immutable Arr!Param params =
		checkParams(alloc, ctx, toArr(ast.params), structsAndAliasesMap, typeParamsScope, delayStructInsts);
	immutable Type returnType =
		typeFromAst(alloc, ctx, ast.returnType, structsAndAliasesMap, typeParamsScope, delayStructInsts);
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
	ref immutable ArrWithSize!TypeParam typeParams,
	ref immutable StructsAndAliasesMap structsAndAliasesMap,
	immutable Sym name,
	ref immutable SpecBodyAst ast,
) {
	return matchSpecBodyAst!(immutable SpecBody)(
		ast,
		(ref immutable SpecBodyAst.Builtin) =>
			immutable SpecBody(SpecBody.Builtin(getSpecBodyBuiltinKind(name))),
		(ref immutable Arr!SigAst sigs) =>
			immutable SpecBody(map!Sig(alloc, sigs, (ref immutable SigAst it) =>
				checkSig!Alloc(
					alloc,
					ctx,
					it,
					toArr(typeParams),
					structsAndAliasesMap,
					noneMut!(Ptr!(MutArr!(Ptr!StructInst)))))));
}

immutable(Arr!SpecDecl) checkSpecDecls(Alloc)(
	ref Alloc alloc,
	ref CheckCtx ctx,
	ref immutable StructsAndAliasesMap structsAndAliasesMap,
	ref immutable Arr!SpecDeclAst asts,
) {
	return map!SpecDecl(alloc, asts, (ref immutable SpecDeclAst ast) {
		immutable ArrWithSize!TypeParam typeParams = checkTypeParams(alloc, ctx, ast.typeParams);
		immutable SpecBody body_ =
			checkSpecBody(alloc, ctx, typeParams, structsAndAliasesMap, ast.name, ast.body_);
		return immutable SpecDecl(rangeInFile(ctx, ast.range), ast.isPublic, ast.name, typeParams, body_);
	});
}

Arr!StructAlias checkStructAliasesInitial(Alloc)(
	ref Alloc alloc,
	ref CheckCtx ctx,
	ref immutable Arr!StructAliasAst asts,
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
	immutable Bool forced;
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
					return PurityAndForced(Purity.data, False);
				case PuritySpecifier.forceData:
					return PurityAndForced(Purity.data, True);
				case PuritySpecifier.sendable:
					return PurityAndForced(Purity.sendable, False);
				case PuritySpecifier.forceSendable:
					return PurityAndForced(Purity.sendable, True);
				case PuritySpecifier.mut:
					return PurityAndForced(Purity.mut, False);
			}
		}();
		if (res.purity == defaultPurity && !res.forced)
			addDiag(alloc, ctx, ast.range, immutable Diag(
				immutable Diag.PuritySpecifierRedundant(defaultPurity, getTypeKind(ast.body_))));
		return res;
	} else
		return PurityAndForced(defaultPurity, False);
}

immutable(TypeKind) getTypeKind(ref immutable StructDeclAst.Body a) {
	return matchStructDeclAstBody!(immutable TypeKind)(
		a,
		(ref immutable StructDeclAst.Body.Builtin) => TypeKind.builtin,
		(ref immutable StructDeclAst.Body.ExternPtr) => TypeKind.externPtr,
		(ref immutable StructDeclAst.Body.Record) => TypeKind.record,
		(ref immutable StructDeclAst.Body.Union) => TypeKind.union_);
}

Arr!StructDecl checkStructsInitial(Alloc)(
	ref Alloc alloc,
	ref CheckCtx ctx,
	ref immutable Arr!StructDeclAst asts,
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
	ref immutable StructsAndAliasesMap structsAndAliasesMap,
	ref Arr!StructAlias aliases,
	ref immutable Arr!StructAliasAst asts,
	ref MutArr!(Ptr!StructInst) delayStructInsts,
) {
	zipFirstMut!(StructAlias, StructAliasAst)(
		aliases,
		asts,
		(ref StructAlias structAlias, ref immutable StructAliasAst ast) {
			setTarget(structAlias, instStructFromAst!Alloc(
				alloc,
				ctx,
				ast.target,
				structsAndAliasesMap,
				immutable TypeParamsScope(typeParams(structAlias)),
				someMut!(Ptr!(MutArr!(Ptr!StructInst)))(ptrTrustMe_mut(delayStructInsts))));
		});
}

//TODO:MOVE
void everyPairWithIndex(T)(
	immutable Arr!T a,
	scope void delegate(
		ref immutable T,
		ref immutable T,
		immutable size_t,
		immutable size_t,
	) @safe @nogc pure nothrow cb,
) {
	foreach (immutable size_t i; 0..size(a))
		foreach (immutable size_t j; 0..i)
			cb(at(a, j), at(a, i), j, i);
}

//TODO:MOVE
void everyPair(T)(
	ref immutable Arr!T a,
	scope void delegate(ref immutable T, ref immutable T) @safe @nogc pure nothrow cb,
) {
	foreach (immutable size_t i; 0..size(a))
		foreach (immutable size_t j; 0..i)
			cb(at(a, i), at(a, j));
}

immutable(Opt!ForcedByValOrRef) getForcedByValOrRef(ref immutable Opt!ExplicitByValOrRefAndRange e) {
	if (has(e))
		final switch (force(e).byValOrRef) {
			case ExplicitByValOrRef.byVal:
				return some(ForcedByValOrRef.byVal);
			case ExplicitByValOrRef.byRef:
				return some(ForcedByValOrRef.byRef);
		}
	else
		return none!ForcedByValOrRef;
}

immutable(StructBody) checkRecord(Alloc)(
	ref Alloc alloc,
	ref CheckCtx ctx,
	ref immutable StructsAndAliasesMap structsAndAliasesMap,
	immutable Ptr!StructDecl struct_,
	ref immutable StructDeclAst.Body.Record r,
	ref MutArr!(Ptr!StructInst) delayStructInsts,
) {
	immutable Opt!ForcedByValOrRef forcedByValOrRef = getForcedByValOrRef(r.explicitByValOrRef);
	immutable Bool forcedByVal = Bool(has(forcedByValOrRef) && force(forcedByValOrRef) == ForcedByValOrRef.byVal);
	immutable Arr!RecordField fields = mapWithIndex(
		alloc,
		r.fields,
		(immutable size_t index, ref immutable StructDeclAst.Body.Record.Field field) {
			immutable Type fieldType = typeFromAst!Alloc(
				alloc,
				ctx,
				field.type,
				structsAndAliasesMap,
				TypeParamsScope(struct_.typeParams),
				someMut(ptrTrustMe_mut(delayStructInsts)));
			if (isPurityWorse(bestCasePurity(fieldType), struct_.purity) && !struct_.purityIsForced)
				addDiag(alloc, ctx, field.range, immutable Diag(Diag.PurityOfFieldWorseThanRecord(struct_, fieldType)));
			if (field.isMutable) {
				immutable Opt!(Diag.MutFieldNotAllowed.Reason) reason =
					struct_.purity != Purity.mut && !struct_.purityIsForced
						? some(Diag.MutFieldNotAllowed.Reason.recordIsNotMut)
						: forcedByVal
						? some(Diag.MutFieldNotAllowed.Reason.recordIsForcedByVal)
						: none!(Diag.MutFieldNotAllowed.Reason);
				if (has(reason))
					addDiag(alloc, ctx, field.range, immutable Diag(Diag.MutFieldNotAllowed(force(reason))));
			}
			return immutable RecordField(rangeInFile(ctx, field.range), field.isMutable, field.name, fieldType, index);
		});
	everyPair!RecordField(fields, (ref immutable RecordField a, ref immutable RecordField b) {
		if (symEq(a.name, b.name))
			addDiag(alloc, ctx, b.range,
				immutable Diag(Diag.DuplicateDeclaration(Diag.DuplicateDeclaration.Kind.field, a.name)));
	});

	return immutable StructBody(StructBody.Record(forcedByValOrRef, fields));
}

immutable(StructBody) checkUnion(Alloc)(
	ref Alloc alloc,
	ref CheckCtx ctx,
	ref immutable StructsAndAliasesMap structsAndAliasesMap,
	immutable Ptr!StructDecl struct_,
	ref immutable StructDeclAst.Body.Union un,
	ref MutArr!(Ptr!StructInst) delayStructInsts,
) {
	immutable Opt!(Arr!(Ptr!StructInst)) members = mapOrNone!(Ptr!StructInst)(
		alloc,
		un.members,
		(ref immutable TypeAst.InstStruct it) {
			immutable Opt!(Ptr!StructInst) res = instStructFromAst(
				alloc,
				ctx,
				it,
				structsAndAliasesMap,
				TypeParamsScope(struct_.typeParams),
				someMut(ptrTrustMe_mut(delayStructInsts)));
			if (has(res) && isPurityWorse(force(res).bestCasePurity, struct_.purity))
				addDiag(alloc, ctx, it.range, immutable Diag(Diag.PurityOfMemberWorseThanUnion(struct_, force(res))));
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
						Diag.DuplicateDeclaration(Diag.DuplicateDeclaration.Kind.unionMember, a.decl.name));
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
	ref immutable StructsAndAliasesMap structsAndAliasesMap,
	ref Arr!StructDecl structs,
	ref immutable Arr!StructDeclAst asts,
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
				(ref immutable StructDeclAst.Body.Record r) =>
					checkRecord(alloc, ctx, structsAndAliasesMap, castImmutable(struct_), r, delayStructInsts),
				(ref immutable StructDeclAst.Body.Union un) =>
					checkUnion(alloc, ctx, structsAndAliasesMap, castImmutable(struct_), un, delayStructInsts));
			setBody(struct_, body_);
		});

	foreach (ref immutable StructDecl struct_; arrRange(castImmutable(structs))) {
		matchStructBody!void(
			body_(struct_),
			(ref immutable StructBody.Bogus) {},
			(ref immutable StructBody.Builtin) {},
			(ref immutable StructBody.ExternPtr) {},
			(ref immutable StructBody.Record) {},
			(ref immutable StructBody.Union u) {
				foreach (ref immutable Ptr!StructInst member; arrRange(u.members))
					if (isUnion(body_(member.decl.deref)))
						todo!void("unions can't contain unions");
			});
	}
}

immutable(StructsAndAliasesMap) buildStructsAndAliasesDict(Alloc)(
	ref Alloc alloc,
	ref CheckCtx ctx,
	immutable Arr!StructDecl structs,
	immutable Arr!StructAlias aliases,
) {
	DictBuilder!(Sym, StructOrAlias, compareSym) d;
	foreach (immutable Ptr!StructDecl decl; ptrsRange(structs)) {
		verify(size(typeParams(decl.deref())) < 10); //TODO:KILL
		addToDict(alloc, d, decl.name, immutable StructOrAlias(decl));
	}
	foreach (immutable Ptr!StructAlias a; ptrsRange(aliases))
		addToDict(alloc, d, a.name, immutable StructOrAlias(a));
	return finishDict!(Alloc, Sym, StructOrAlias, compareSym)(
		alloc,
		d,
		(ref immutable Sym name, ref immutable StructOrAlias, ref immutable StructOrAlias b) =>
			addDiag(alloc, ctx, b.range, immutable Diag(
				Diag.DuplicateDeclaration(Diag.DuplicateDeclaration.Kind.structOrAlias, name))));
}

struct FunsAndMap {
	immutable Arr!FunDecl funs;
	immutable FunsMap funsMap;
}

immutable(ArrWithSize!(Ptr!SpecInst)) checkSpecUses(Alloc)(
	ref Alloc alloc,
	ref CheckCtx ctx,
	ref immutable Arr!SpecUseAst asts,
	ref immutable StructsAndAliasesMap structsAndAliasesMap,
	ref immutable SpecsMap specsMap,
	immutable TypeParamsScope typeParamsScope,
) {
	return mapOpWithSize!(Ptr!SpecInst)(alloc, asts, (ref immutable SpecUseAst ast) {
		immutable Opt!(Ptr!SpecDecl) opSpec = tryFindSpec(alloc, ctx, ast.spec.name, ast.range, specsMap);
		if (has(opSpec)) {
			immutable Ptr!SpecDecl spec = force(opSpec);
			immutable Arr!Type typeArgs = typeArgsFromAsts(
				alloc,
				ctx,
				toArr(ast.typeArgs),
				structsAndAliasesMap,
				typeParamsScope,
				noneMut!(Ptr!(MutArr!(Ptr!StructInst))));
			if (!sizeEq(typeArgs, spec.typeParams)) {
				addDiag(alloc, ctx, ast.range, immutable Diag(
					Diag.WrongNumberTypeArgsForSpec(spec, size(spec.typeParams), size(typeArgs))));
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

immutable(Bool) recordIsAlwaysByVal(ref immutable StructBody.Record record) {
	return immutable Bool(
		empty(record.fields) ||
		(has(record.forcedByValOrRef) && force(record.forcedByValOrRef) == ForcedByValOrRef.byVal));
}

immutable(FunsAndMap) checkFuns(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref AllSymbols!SymAlloc allSymbols,
	ref CheckCtx ctx,
	ref immutable CommonTypes commonTypes,
	ref immutable SpecsMap specsMap,
	ref immutable Arr!StructDecl structs,
	ref immutable StructsAndAliasesMap structsAndAliasesMap,
	ref immutable Arr!FunDeclAst asts,
) {
	ExactSizeArrBuilder!FunDecl funsBuilder = newExactSizeArrBuilder!FunDecl(alloc, countFunsForStruct(asts, structs));
	foreach (ref immutable FunDeclAst funAst; arrRange(asts)) {
		immutable ArrWithSize!TypeParam typeParams = empty(toArr(funAst.typeParams))
			? collectTypeParams(alloc, ctx, funAst.sig)
			: checkTypeParams(alloc, ctx, funAst.typeParams);
		immutable Ptr!Sig sig = allocate(alloc, checkSig(
			alloc,
			ctx,
			funAst.sig,
			toArr(typeParams),
			structsAndAliasesMap,
			noneMut!(Ptr!(MutArr!(Ptr!StructInst)))));
		immutable ArrWithSize!(Ptr!SpecInst) specUses = checkSpecUses(
			alloc,
			ctx,
			funAst.specUses,
			structsAndAliasesMap,
			specsMap,
			immutable TypeParamsScope(toArr(typeParams)));
		immutable FunFlags flags = FunFlags(funAst.noCtx, funAst.summon, funAst.unsafe, funAst.trusted, False);
		exactSizeArrBuilderAdd(funsBuilder, FunDecl(funAst.isPublic, flags, sig, typeParams, specUses));
	}
	foreach (immutable Ptr!StructDecl struct_; ptrsRange(structs))
		addFunsForStruct(alloc, allSymbols, ctx, funsBuilder, commonTypes, struct_);
	Arr!FunDecl funs = finish(funsBuilder);

	immutable FunsMap funsMap = buildMultiDict!(Sym, Ptr!FunDecl, compareSym, FunDecl, Alloc)(
		alloc,
		castImmutable(funs),
		(immutable Ptr!FunDecl it) =>
			immutable KeyValuePair!(Sym, Ptr!FunDecl)(name(it), it));

	foreach (ref const FunDecl f; arrRange(funs))
		addToMutSymSetOkIfPresent(alloc, ctx.programState.names.funNames, name(f));

	Arr!FunDecl funsWithAsts = slice(funs, 0, size(asts));
	zipMutPtrFirst!(FunDecl, FunDeclAst)(funsWithAsts, asts, (Ptr!FunDecl fun, ref immutable FunDeclAst funAst) {
		overwriteMemory(&fun.body_, matchFunBodyAst(
			funAst.body_,
			(ref immutable FunBodyAst.Builtin) =>
				immutable FunBody(FunBody.Builtin()),
			(ref immutable FunBodyAst.Extern e) {
				if (!fun.noCtx)
					todo!void("'extern' fun must be 'noctx'");
				if (e.isGlobal && arity(fun) != 0)
					todo!void("'extern' fun has parameters");
				return immutable FunBody(nu!(FunBody.Extern)(alloc, e.isGlobal, copyStr(alloc, e.externName)));
			},
			(ref immutable ExprAst e) =>
				immutable FunBody(checkFunctionBody!Alloc(
					alloc, ctx, e, structsAndAliasesMap, funsMap, castImmutable(fun), commonTypes))));
	});

	return FunsAndMap(castImmutable(funs), funsMap);
}

immutable(size_t) countFunsForStruct(
	ref immutable Arr!FunDeclAst asts,
	ref immutable Arr!StructDecl structs,
) {
	return size(asts) + sum!StructDecl(structs, (ref immutable StructDecl s) {
		if (isRecord(body_(s))) {
			immutable StructBody.Record record = asRecord(body_(s));
			immutable size_t constructors = recordIsAlwaysByVal(record) ? 1 : 2;
			return constructors + size(record.fields) + count(record.fields, (ref immutable RecordField it) =>
				it.isMutable);
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
		immutable Arr!Type typeArgs = mapPtrs(alloc, toArr(typeParams), (immutable Ptr!TypeParam p) =>
			immutable Type(p));
		immutable Type structType = immutable Type(instantiateStructNeverDelay!Alloc(
			alloc,
			ctx.programState,
			immutable StructDeclAndArgs(struct_, typeArgs)));
		immutable Arr!Param ctorParams = map(alloc, record.fields, (ref immutable RecordField it) =>
			immutable Param(it.range, it.name, it.type, it.index));
		FunDecl constructor(Type returnType, FunFlags flags) {
			immutable Ptr!Sig ctorSig = allocate(alloc, immutable Sig(
				fileAndPosFromFileAndRange(struct_.range),
				struct_.name,
				returnType,
				ctorParams));
			return FunDecl(
				struct_.isPublic,
				flags,
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

		foreach (immutable ubyte fieldIndex; 0..safeSizeTToU8(size(record.fields))) {
			immutable Ptr!RecordField field = ptrAt(record.fields, fieldIndex);
			immutable Ptr!Sig getterSig = allocate(alloc, immutable Sig(
				fileAndPosFromFileAndRange(field.range),
				field.name,
				field.type,
				arrLiteral!Param(alloc, [immutable Param(field.range, shortSymAlphaLiteral("a"), structType, 0)])));
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
						immutable Param(field.range, shortSymAlphaLiteral("a"), structType, 0),
						immutable Param(field.range, field.name, field.type, 1)])));
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

immutable(SpecsMap) buildSpecsDict(Alloc)(
	ref Alloc alloc,
	ref CheckCtx ctx,
	ref immutable Arr!SpecDecl specs,
) {
	return buildDict!(Sym, Ptr!SpecDecl, compareSym, SpecDecl, Alloc)(
		alloc,
		specs,
		(immutable Ptr!SpecDecl it) =>
			immutable KeyValuePair!(Sym, Ptr!SpecDecl)(it.name, it),
		(ref immutable Sym name, ref immutable Ptr!SpecDecl, ref immutable Ptr!SpecDecl s) {
			addDiag(alloc, ctx, s.range, Diag(Diag.DuplicateDeclaration(Diag.DuplicateDeclaration.Kind.spec, name)));
		});
}

immutable(Ptr!Module) checkWorkerAfterCommonTypes(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref AllSymbols!SymAlloc allSymbols,
	ref CheckCtx ctx,
	ref immutable CommonTypes commonTypes,
	ref immutable StructsAndAliasesMap structsAndAliasesMap,
	ref Arr!StructDecl structs,
	ref MutArr!(Ptr!StructInst) delayStructInsts,
	immutable FileIndex fileIndex,
	ref immutable Arr!ModuleAndNameReferents imports,
	ref immutable Arr!ModuleAndNameReferents exports,
	ref immutable FileAst ast,
) {
	checkStructBodies!Alloc(alloc, ctx, structsAndAliasesMap, structs, ast.structs, delayStructInsts);
	immutable Arr!StructDecl structsImmutable = castImmutable(structs);
	foreach (ref const StructDecl s; arrRange(structs))
		if (isRecord(s.body_))
			foreach (ref immutable RecordField f; arrRange(asRecord(s.body_).fields))
				addToMutSymSetOkIfPresent(alloc, ctx.programState.names.recordFieldNames, f.name);

	while (!mutArrIsEmpty(delayStructInsts)) {
		Ptr!StructInst i = mustPop(delayStructInsts);
		setBody(i, instantiateStructBody(
			alloc,
			ctx.programState,
			i.declAndArgs,
			someMut(ptrTrustMe_mut(delayStructInsts))));
	}

immutable Arr!SpecDecl specs = checkSpecDecls(alloc, ctx, structsAndAliasesMap, ast.specs);
	immutable SpecsMap specsMap = buildSpecsDict(alloc, ctx, specs);
	foreach (ref immutable SpecDecl s; arrRange(specs))
		addToMutSymSetOkIfPresent(alloc, ctx.programState.names.specNames, s.name);

	immutable FunsAndMap funsAndMap = checkFuns(
		alloc,
		allSymbols,
		ctx,
		commonTypes,
		specsMap,
		structsImmutable,
		structsAndAliasesMap,
		ast.funs);

	// Create a module unconditionally so every function will always have containingModule set, even in failure case
	return nu!Module(
		alloc,
		fileIndex,
		nu!ModuleImportsExports(alloc, imports, exports),
		nu!ModuleArrs(alloc, structsImmutable, specs, funsAndMap.funs),
		nu!ModuleDicts(alloc, structsAndAliasesMap, specsMap, funsAndMap.funsMap));
}

void recurAddImport(Alloc)(
	ref Alloc alloc,
	ref ArrBuilder!Diagnostic diags,
	ref ArrBuilder!ModuleAndNameReferents res,
	immutable Ptr!Module module_,
	ref immutable FileAndRange range,
	immutable Opt!(Arr!Sym) names,
) {
	immutable Opt!(Arr!NameAndReferents) nameReferents = mapOption(names, (ref immutable Arr!Sym names) =>
		map(alloc, names, (ref immutable Sym name) =>
			getNameReferents(alloc, diags, module_, range, name)));
	add(alloc, res, immutable ModuleAndNameReferents(range.range, module_, nameReferents));
	foreach (immutable ModuleAndNameReferents e; arrRange(module_.exports)) {
		if (has(e.namesAndReferents))
			// if we're importing specific names, check for overlap.
			// If not, import the specific names being re-exported.
			todo!void("export with names");
		recurAddImport(alloc, diags, res, e.module_, range, names);
	}
}

immutable(NameAndReferents) getNameReferents(Alloc)(
	ref Alloc alloc,
	ref ArrBuilder!Diagnostic diags,
	ref immutable Module module_,
	ref immutable FileAndRange range,
	immutable Sym name,
) {
	immutable NameAndReferents res = immutable NameAndReferents(
		range.start,
		name,
		getAt(module_.structsAndAliasesMap, name),
		getAt(module_.specsMap, name),
		multiDictGetAt(module_.funsMap, name));
	// TODO: it should be illegal to have public and private members with the same name
	// (so don't worry about it here, but elsewhere)
	if (has(res.structOrAlias) && !isPublic(force(res.structOrAlias)))
		todo!void("not public");
	if (has(res.spec) && !force(res.spec).isPublic)
		todo!void("not public");
	foreach (immutable Ptr!FunDecl fun; arrRange(res.funs))
		if (!fun.isPublic)
			todo!void("not public");
	if (!has(res.structOrAlias) && !has(res.spec) && empty(res.funs))
		add(alloc, diags, immutable Diagnostic(range, nu!Diag(alloc, immutable Diag.ImportRefersToNothing(name))));
	return res;
}

immutable(Arr!ModuleAndNameReferents) getFlattenedImports(Alloc)(
	ref Alloc alloc,
	ref ArrBuilder!Diagnostic diags,
	immutable FileIndex thisFile,
	ref immutable Arr!ModuleAndNames imports,
) {
	ArrBuilder!ModuleAndNameReferents res;
	foreach (ref immutable ModuleAndNames m; arrRange(imports)) {
		immutable FileAndRange fr = immutable FileAndRange(thisFile, m.range);
		recurAddImport(alloc, diags, res, m.module_, fr, m.names);
	}
	return finishArr(alloc, res);
}

immutable(BootstrapCheck) checkWorker(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref AllSymbols!SymAlloc allSymbols,
	ref ArrBuilder!Diagnostic diagsBuilder,
	ref ProgramState programState,
	immutable Arr!ModuleAndNames imports,
	immutable Arr!ModuleAndNames exports,
	ref immutable PathAndAst pathAndAst,
	scope immutable(Ptr!CommonTypes) delegate(
		ref CheckCtx,
		ref immutable StructsAndAliasesMap,
		ref MutArr!(Ptr!StructInst),
	) @safe @nogc pure nothrow getCommonTypes,
) {
	immutable Arr!ModuleAndNameReferents convertedImports =
		getFlattenedImports(alloc, diagsBuilder, pathAndAst.fileIndex, imports);
	immutable Arr!ModuleAndNameReferents convertedExports =
		getFlattenedImports(alloc, diagsBuilder, pathAndAst.fileIndex, exports);
	CheckCtx ctx = CheckCtx(
		ptrTrustMe_mut(programState),
		pathAndAst.fileIndex,
		convertedImports,
		ptrTrustMe_mut(diagsBuilder));
	immutable FileAst ast = pathAndAst.ast;

	// Since structs may refer to each other, first get a structsAndAliasesMap, *then* fill in bodies
	Arr!StructDecl structs = checkStructsInitial(alloc, ctx, ast.structs);
	foreach (ref const StructDecl s; arrRange(structs))
		addToMutSymSetOkIfPresent(alloc, programState.names.structAndAliasNames, s.name);
	Arr!StructAlias structAliases = checkStructAliasesInitial(alloc, ctx, ast.structAliases);
	foreach (ref const StructAlias a; arrRange(structAliases))
		addToMutSymSetOkIfPresent(alloc, programState.names.structAndAliasNames, a.name);
	immutable StructsAndAliasesMap structsAndAliasesMap =
		buildStructsAndAliasesDict(alloc, ctx, castImmutable(structs), castImmutable(structAliases));

	// We need to create StructInsts when filling in struct bodies.
	// But when creating a StructInst, we usually want to fill in its body.
	// In case the decl body isn't available yet,
	// we'll delay creating the StructInst body, which isn't needed until expr checking.
	MutArr!(Ptr!StructInst) delayStructInsts;
	checkStructAliasTargets!Alloc(alloc, ctx, structsAndAliasesMap, structAliases, ast.structAliases, delayStructInsts);

	immutable Ptr!CommonTypes commonTypes = getCommonTypes(ctx, structsAndAliasesMap, delayStructInsts);
	immutable Ptr!Module mod = checkWorkerAfterCommonTypes(
		alloc,
		allSymbols,
		ctx,
		commonTypes,
		structsAndAliasesMap,
		structs,
		delayStructInsts,
		pathAndAst.fileIndex,
		convertedImports,
		convertedExports,
		ast);
	return immutable BootstrapCheck(mod, commonTypes);
}
