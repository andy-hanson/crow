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
	instantiateSpec,
	instantiateStruct,
	instantiateStructBody,
	instantiateStructNeverDelay,
	makeArrayType,
	makeNamedValType,
	TypeParamsScope;
import frontend.check.typeFromAst : tryFindSpec, typeArgsFromAsts, typeFromAst;
import frontend.diagnosticsBuilder : addDiagnostic, DiagnosticsBuilder;
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
	matchParamsAst,
	matchSpecBodyAst,
	matchStructDeclAstBody,
	NameAndRange,
	ParamAst,
	ParamsAst,
	PuritySpecifier,
	rangeOfNameAndRange,
	SigAst,
	SpecBodyAst,
	SpecDeclAst,
	SpecUseAst,
	StructAliasAst,
	StructDeclAst,
	TestAst,
	TypeAst;
import frontend.programState : ProgramState;
import model.diag : Diag, TypeKind;
import model.model :
	arity,
	arityIsNonZero,
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
	FieldMutability,
	FlagsFunction,
	ForcedByValOrRefOrNone,
	FunBody,
	FunDecl,
	FunFlags,
	FunKind,
	FunKindAndStructs,
	IntegralTypes,
	isBogus,
	isPurityWorse,
	isRecord,
	isStructInst,
	leastVisibility,
	matchStructBody,
	matchStructOrAliasPtr,
	matchType,
	Module,
	ModuleAndNames,
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
	typeArgs,
	TypeParam,
	typeParams,
	UnionMember,
	Visibility,
	visibility;
import util.alloc.alloc : Alloc;
import util.col.arr :
	ArrWithSize,
	castImmutable,
	empty,
	emptyArr,
	emptyArrWithSize,
	only,
	ptrAt,
	ptrsRange,
	sizeEq,
	toArr;
import util.col.arrBuilder : add, ArrBuilder, finishArr;
import util.col.arrUtil :
	arrLiteral,
	arrWithSizeLiteral,
	cat,
	count,
	eachPair,
	fillArr_mut,
	fold,
	map,
	mapAndFold,
	MapAndFold,
	mapOp,
	mapOpWithSize,
	mapPtrs,
	mapToMut,
	mapWithIndex,
	mapWithSize,
	mapWithSizeWithIndex,
	sum,
	zipFirstMut,
	zipMutPtrFirst,
	zipPtrFirst;
import util.col.arrWithSizeBuilder : add, ArrWithSizeBuilder, finishArrWithSize;
import util.col.dict : dictEach, getAt, hasKey, KeyValuePair, SymDict;
import util.col.dictBuilder : finishDict, SymDictBuilder, tryAddToDict;
import util.col.exactSizeArrBuilder :
	ExactSizeArrBuilder,
	exactSizeArrBuilderAdd,
	finish,
	newExactSizeArrBuilder;
import util.col.multiDict : buildMultiDict, multiDictEach, multiDictGetAt;
import util.col.mutArr : mustPop, MutArr, mutArrIsEmpty;
import util.col.mutDict : insertOrUpdate, moveToDict, MutSymDict;
import util.col.mutSet : addToMutSymSetOkIfPresent;
import util.col.str : copySafeCStr, safeCStr;
import util.memory : allocate, allocateMut, overwriteMemory;
import util.opt : force, has, none, noneMut, Opt, OptPtr, some, someMut, toOpt;
import util.perf : Perf;
import util.ptr : castImmutable, Ptr, ptrEquals, ptrTrustMe_mut;
import util.sourceRange : FileAndPos, fileAndPosFromFileAndRange, FileAndRange, FileIndex, RangeWithinFile;
import util.sym :
	AllSymbols,
	containsSym,
	hashSym,
	Operator,
	prependSet,
	shortSym,
	shortSymValue,
	SpecialSym,
	Sym,
	symEq,
	symForOperator,
	symForSpecial;
import util.util : todo, unreachable, verify;

struct PathAndAst { //TODO:RENAME
	immutable FileIndex fileIndex;
	immutable FileAst ast;
}

struct BootstrapCheck {
	immutable Module module_;
	immutable CommonFuns commonFuns;
	immutable CommonTypes commonTypes;
}

immutable(BootstrapCheck) checkBootstrap(
	ref Alloc alloc,
	scope ref Perf perf,
	ref AllSymbols allSymbols,
	ref DiagnosticsBuilder diagsBuilder,
	ref ProgramState programState,
	immutable PathAndAst pathAndAst,
) {
	return checkWorker(
		alloc,
		perf,
		allSymbols,
		diagsBuilder,
		programState,
		emptyArr!ModuleAndNames,
		emptyArr!ModuleAndNames,
		pathAndAst,
		none!CommonFuns,
		(ref CheckCtx ctx,
		ref immutable StructsAndAliasesDict structsAndAliasesDict,
		ref MutArr!(Ptr!StructInst) delayedStructInsts) =>
			getCommonTypes(alloc, ctx, structsAndAliasesDict, delayedStructInsts));
}

immutable(Module) check(
	ref Alloc alloc,
	scope ref Perf perf,
	ref AllSymbols allSymbols,
	ref DiagnosticsBuilder diagsBuilder,
	ref ProgramState programState,
	ref immutable ModuleAndNames[] imports,
	ref immutable ModuleAndNames[] exports,
	ref immutable PathAndAst pathAndAst,
	ref immutable CommonFuns commonFunsFromBootstrap,
	ref immutable CommonTypes commonTypes,
) {
	return checkWorker(
		alloc,
		perf,
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
		if (decl.deref().typeParams.length != expectedTypeParams)
			todo!void("getCommonTemplateType");
		return some(decl);
	} else
		return none!(Ptr!StructDecl);
}

immutable(Opt!(Ptr!StructInst)) getCommonNonTemplateType(
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

immutable(Opt!(Ptr!StructInst)) instantiateNonTemplateStructOrAlias(
	ref Alloc alloc,
	ref ProgramState programState,
	ref MutArr!(Ptr!StructInst) delayedStructInsts,
	immutable StructOrAlias structOrAlias,
) {
	verify(empty(typeParams(structOrAlias)));
	return matchStructOrAliasPtr!(
		immutable Opt!(Ptr!StructInst),
		(ref immutable StructAlias it) =>
			target(it),
		(immutable Ptr!StructDecl it) =>
			some(instantiateNonTemplateStructDecl(alloc, programState, delayedStructInsts, it)),
	)(structOrAlias);
}

immutable(Ptr!StructInst) instantiateNonTemplateStructDeclNeverDelay(
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

immutable(Ptr!StructInst) instantiateNonTemplateStructDecl(
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

immutable(CommonTypes) getCommonTypes(
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
			shortSym(name),
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
			shortSym(name),
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
	return immutable CommonTypes(
		bool_,
		char_,
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

immutable(Ptr!StructDecl) bogusStructDecl(ref Alloc alloc, immutable size_t nTypeParameters) {
	ArrWithSizeBuilder!TypeParam typeParams;
	immutable FileAndRange fileAndRange = immutable FileAndRange(immutable FileIndex(0), RangeWithinFile.empty);
	foreach (immutable size_t i; 0 .. nTypeParameters)
		add(alloc, typeParams, immutable TypeParam(fileAndRange, shortSym("bogus"), i));
	Ptr!StructDecl res = allocateMut(alloc, StructDecl(
		fileAndRange,
		safeCStr!"",
		shortSym("bogus"),
		finishArrWithSize(alloc, typeParams),
		Visibility.public_,
		Purity.data,
		false));
	setBody(res.deref(), immutable StructBody(immutable StructBody.Bogus()));
	return castImmutable(res);
}

immutable(ArrWithSize!TypeParam) checkTypeParams(
	ref Alloc alloc,
	ref CheckCtx ctx,
	ref immutable ArrWithSize!NameAndRange asts,
) {
	immutable ArrWithSize!TypeParam res =
		mapWithSizeWithIndex!(TypeParam, NameAndRange)(
			alloc,
			toArr(asts),
			(immutable size_t index, scope ref immutable NameAndRange ast) =>
				immutable TypeParam(rangeInFile(ctx, rangeOfNameAndRange(ast, ctx.allSymbols)), ast.name, index));
	eachPair!TypeParam(toArr(res), (ref immutable TypeParam a, ref immutable TypeParam b) {
		if (symEq(a.name, b.name))
			addDiag(alloc, ctx, b.range, immutable Diag(
				immutable Diag.ParamShadowsPrevious(Diag.ParamShadowsPrevious.Kind.typeParam, b.name)));
	});
	return res;
}

immutable(Params) checkParams(
	ref Alloc alloc,
	ref CheckCtx ctx,
	ref immutable CommonTypes commonTypes,
	ref immutable ParamsAst ast,
	ref immutable StructsAndAliasesDict structsAndAliasesDict,
	immutable TypeParamsScope typeParamsScope,
	ref DelayStructInsts delayStructInsts,
) {
	return matchParamsAst!(
		immutable Params,
		(immutable ParamAst[] asts) {
			immutable ArrWithSize!Param paramsWithSize = mapWithSizeWithIndex!(Param, ParamAst)(
				alloc,
				asts,
				(immutable size_t index, scope ref immutable ParamAst ast) =>
					checkParam(
						alloc, ctx, commonTypes, structsAndAliasesDict, typeParamsScope, delayStructInsts,
						ast, index));
			eachPair!Param(toArr(paramsWithSize), (ref immutable Param x, ref immutable Param y) {
				if (has(x.name) && has(y.name) && symEq(force(x.name), force(y.name)))
					addDiag(alloc, ctx, y.range, immutable Diag(immutable Diag.ParamShadowsPrevious(
						Diag.ParamShadowsPrevious.Kind.param, force(y.name))));
			});
			return immutable Params(paramsWithSize);
		},
		(ref immutable ParamsAst.Varargs varargs) {
			immutable Param param = checkParam(
				alloc, ctx, commonTypes, structsAndAliasesDict, typeParamsScope, delayStructInsts, varargs.param, 0);
			immutable Type elementType = matchType!(immutable Type)(
				param.type,
				(immutable Type.Bogus) =>
					immutable Type(immutable Type.Bogus()),
				(immutable Ptr!TypeParam) =>
					todo!(immutable Type)("diagnostic"),
				(immutable Ptr!StructInst si) {
					if (ptrEquals(si.deref().decl, commonTypes.arr)) {
						return only(typeArgs(si.deref()));
					} else {
						return todo!(immutable Type)("diagnostic");
					}
				});
			return immutable Params(allocate(alloc, immutable Params.Varargs(param, elementType)));
		},
	)(ast);
}

immutable(Param) checkParam(
	ref Alloc alloc,
	ref CheckCtx ctx,
	ref immutable CommonTypes commonTypes,
	ref immutable StructsAndAliasesDict structsAndAliasesDict,
	immutable TypeParamsScope typeParamsScope,
	ref DelayStructInsts delayStructInsts,
	scope ref immutable ParamAst ast,
	immutable size_t index,
) {
	immutable Type type = typeFromAst(
		alloc,
		ctx,
		commonTypes,
		ast.type,
		structsAndAliasesDict,
		typeParamsScope,
		delayStructInsts);
	return immutable Param(rangeInFile(ctx, ast.range), ast.name, type, index);
}

immutable(Sig) checkSig(
	ref Alloc alloc,
	ref CheckCtx ctx,
	ref immutable CommonTypes commonTypes,
	ref immutable SigAst ast,
	immutable TypeParam[] typeParams,
	ref immutable StructsAndAliasesDict structsAndAliasesDict,
	DelayStructInsts delayStructInsts
) {
	immutable TypeParamsScope typeParamsScope = TypeParamsScope(typeParams);
	immutable Params params = checkParams(
		alloc,
		ctx,
		commonTypes,
		ast.params,
		structsAndAliasesDict,
		typeParamsScope,
		delayStructInsts);
	immutable Type returnType =
		typeFromAst(alloc, ctx, commonTypes, ast.returnType, structsAndAliasesDict, typeParamsScope, delayStructInsts);
	return immutable Sig(posInFile(ctx, ast.range.start), ast.name, returnType, params);
}

immutable(SpecBody.Builtin.Kind) getSpecBodyBuiltinKind(
	ref Alloc alloc,
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
			addDiag(alloc, ctx, range, immutable Diag(immutable Diag.BuiltinUnsupported(name)));
			return SpecBody.Builtin.Kind.data;
	}
}

immutable(SpecBody) checkSpecBody(
	ref Alloc alloc,
	ref CheckCtx ctx,
	ref immutable CommonTypes commonTypes,
	ref immutable ArrWithSize!TypeParam typeParams,
	ref immutable StructsAndAliasesDict structsAndAliasesDict,
	immutable RangeWithinFile range,
	immutable Sym name,
	ref immutable SpecBodyAst ast,
) {
	return matchSpecBodyAst!(
		immutable SpecBody,
		(ref immutable SpecBodyAst.Builtin) =>
			immutable SpecBody(SpecBody.Builtin(getSpecBodyBuiltinKind(alloc, ctx, range, name))),
		(ref immutable SigAst[] sigs) =>
			immutable SpecBody(map!Sig(alloc, sigs, (ref immutable SigAst it) =>
				checkSig(
					alloc,
					ctx,
					commonTypes,
					it,
					toArr(typeParams),
					structsAndAliasesDict,
					noneMut!(Ptr!(MutArr!(Ptr!StructInst)))))),
	)(ast);
}

immutable(SpecDecl[]) checkSpecDecls(
	ref Alloc alloc,
	ref CheckCtx ctx,
	ref immutable CommonTypes commonTypes,
	ref immutable StructsAndAliasesDict structsAndAliasesDict,
	ref immutable SpecDeclAst[] asts,
) {
	return map!SpecDecl(alloc, asts, (ref immutable SpecDeclAst ast) {
		immutable ArrWithSize!TypeParam typeParams = checkTypeParams(alloc, ctx, ast.typeParams);
		immutable SpecBody body_ =
			checkSpecBody(alloc, ctx, commonTypes, typeParams, structsAndAliasesDict, ast.range, ast.name, ast.body_);
		return immutable SpecDecl(
			rangeInFile(ctx, ast.range),
			copySafeCStr(alloc, ast.docComment),
			ast.visibility,
			ast.name,
			typeParams,
			body_);
	});
}

StructAlias[] checkStructAliasesInitial(
	ref Alloc alloc,
	ref CheckCtx ctx,
	ref immutable StructAliasAst[] asts,
) {
	return mapToMut!StructAlias(alloc, asts, (ref immutable StructAliasAst ast) =>
		StructAlias(
			rangeInFile(ctx, ast.range),
			copySafeCStr(alloc, ast.docComment),
			ast.visibility,
			ast.name,
			checkTypeParams(alloc, ctx, ast.typeParams)));
}

struct PurityAndForced {
	immutable Purity purity;
	immutable bool forced;
}

immutable(PurityAndForced) getPurityFromAst(
	ref Alloc alloc,
	ref CheckCtx ctx,
	ref immutable StructDeclAst ast,
) {
	immutable Purity defaultPurity = matchStructDeclAstBody!(
		immutable Purity,
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
			Purity.data,
	)(ast.body_);
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
	return matchStructDeclAstBody!(
		immutable TypeKind,
		(ref immutable StructDeclAst.Body.Builtin) => TypeKind.builtin,
		(ref immutable StructDeclAst.Body.Enum) => TypeKind.enum_,
		(ref immutable StructDeclAst.Body.Flags) => TypeKind.flags,
		(ref immutable StructDeclAst.Body.ExternPtr) => TypeKind.externPtr,
		(ref immutable StructDeclAst.Body.Record) => TypeKind.record,
		(ref immutable StructDeclAst.Body.Union) => TypeKind.union_,
	)(a);
}

StructDecl[] checkStructsInitial(
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
			ast.visibility,
			p.purity,
			p.forced);
	});
}

void checkStructAliasTargets(
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
			immutable Type type = typeFromAst(
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
void everyPair(T)(
	ref immutable T[] a,
	scope void delegate(ref immutable T, ref immutable T) @safe @nogc pure nothrow cb,
) {
	foreach (immutable size_t i, ref immutable T x; a)
		foreach (immutable size_t j, ref immutable T y; a[0 .. i])
			cb(x, y);
}

immutable(StructBody.Enum) checkEnum(
	ref Alloc alloc,
	ref CheckCtx ctx,
	ref immutable CommonTypes commonTypes,
	ref immutable StructsAndAliasesDict structsAndAliasesDict,
	immutable RangeWithinFile range,
	ref immutable StructDeclAst.Body.Enum e,
	ref MutArr!(Ptr!StructInst) delayStructInsts,
) {
	immutable EnumTypeAndMembers tm = checkEnumMembers(
		alloc, ctx, commonTypes, structsAndAliasesDict, range, e.typeArg, e.members, delayStructInsts,
		(immutable Opt!EnumValue lastValue, immutable EnumBackingType enumType) =>
			has(lastValue)
				? immutable ValueAndOverflow(
					immutable EnumValue(force(lastValue).value + 1),
					force(lastValue) == maxValue(enumType))
				: immutable ValueAndOverflow(immutable EnumValue(0), false));
	return immutable StructBody.Enum(tm.backingType, tm.memers);
}

immutable(StructBody.Flags) checkFlags(
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

immutable(EnumTypeAndMembers) checkEnumMembers(
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
			alloc, ctx, commonTypes, force(typeAst).deref(), structsAndAliasesDict, typeParamsScope,
			someMut(ptrTrustMe_mut(delayStructInsts)))
		: immutable Type(commonTypes.integrals.nat32);
	immutable EnumBackingType enumType = getEnumTypeFromType(alloc, ctx, range, commonTypes, implementationType);

	immutable StructBody.Enum.Member[] members =
		mapAndFold!(StructBody.Enum.Member, Opt!EnumValue, StructDeclAst.Body.Enum.Member)(
			alloc,
			none!EnumValue,
			toArr(memberAsts),
			(ref immutable StructDeclAst.Body.Enum.Member memberAst, immutable Opt!EnumValue lastValue) {
				immutable ValueAndOverflow valueAndOverflow = () {
					if (has(memberAst.value))
						return isSignedEnumBackingType(enumType)
							? matchLiteralIntOrNat!(
								immutable ValueAndOverflow,
								(ref immutable LiteralAst.Int i) =>
									immutable ValueAndOverflow(immutable EnumValue(i.value), i.overflow),
								(ref immutable LiteralAst.Nat n) =>
									immutable ValueAndOverflow(immutable EnumValue(n.value), n.value > long.max),
							)(force(memberAst.value))
							: matchLiteralIntOrNat!(
								immutable ValueAndOverflow,
								(ref immutable LiteralAst.Int) =>
									todo!(immutable ValueAndOverflow)("signed value in unsigned enum"),
								(ref immutable LiteralAst.Nat n) =>
									immutable ValueAndOverflow(immutable EnumValue(n.value), n.overflow),
							)(force(memberAst.value));
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

immutable(EnumBackingType) getEnumTypeFromType(
	ref Alloc alloc,
	ref CheckCtx ctx,
	ref immutable RangeWithinFile range,
	ref immutable CommonTypes commonTypes,
	immutable Type type,
) {
	immutable IntegralTypes integrals = commonTypes.integrals;
	return matchType!(immutable EnumBackingType)(
		type,
		(immutable Type.Bogus) =>
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

immutable(StructBody.Record) checkRecord(
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
			immutable Type fieldType = typeFromAst(
				alloc,
				ctx,
				commonTypes,
				field.type,
				structsAndAliasesDict,
				TypeParamsScope(struct_.deref().typeParams),
				someMut(ptrTrustMe_mut(delayStructInsts)));
			if (isPurityWorse(bestCasePurity(fieldType), struct_.deref().purity) && !struct_.deref().purityIsForced)
				addDiag(alloc, ctx, field.range, immutable Diag(
					immutable Diag.PurityWorseThanParent(struct_, fieldType)));
			if (field.mutability != FieldMutability.const_) {
				immutable Opt!(Diag.MutFieldNotAllowed.Reason) reason =
					struct_.deref().purity != Purity.mut && !struct_.deref().purityIsForced
						? some(Diag.MutFieldNotAllowed.Reason.recordIsNotMut)
						: forcedByVal
						? some(Diag.MutFieldNotAllowed.Reason.recordIsForcedByVal)
						: none!(Diag.MutFieldNotAllowed.Reason);
				if (has(reason))
					addDiag(alloc, ctx, field.range, immutable Diag(immutable Diag.MutFieldNotAllowed(force(reason))));
			}
			return immutable RecordField(
				rangeInFile(ctx, field.range), field.visibility, field.name, field.mutability, fieldType, index);
		});
	everyPair!RecordField(fields, (ref immutable RecordField a, ref immutable RecordField b) {
		if (symEq(a.name, b.name))
			addDiag(alloc, ctx, b.range,
				immutable Diag(immutable Diag.DuplicateDeclaration(Diag.DuplicateDeclaration.Kind.field, a.name)));
	});
	return immutable StructBody.Record(
		immutable RecordFlags(
			recordNewVisibility(alloc, ctx, struct_.deref(), fields, r.modifiers.explicitNewVisibility),
			has(r.packed),
			forcedByValOrRef),
		fields);
}

immutable(Visibility) recordNewVisibility(
	ref Alloc alloc,
	ref CheckCtx ctx,
	ref immutable StructDecl struct_,
	scope immutable RecordField[] fields,
	immutable Opt!Visibility explicit,
) {
	immutable Visibility default_ = fold(
		struct_.visibility,
		fields,
		(immutable Visibility cur, ref immutable RecordField field) =>
			leastVisibility(cur, field.visibility));
	if (has(explicit)) {
		if (force(explicit) == default_)
			//TODO: better range
			addDiag(alloc, ctx, struct_.range, immutable Diag(
				immutable Diag.RecordNewVisibilityIsRedundant(default_)));
		return force(explicit);
	} else
		return default_;
}

immutable(StructBody.Union) checkUnion(
	ref Alloc alloc,
	ref CheckCtx ctx,
	ref immutable CommonTypes commonTypes,
	ref immutable StructsAndAliasesDict structsAndAliasesDict,
	immutable Ptr!StructDecl struct_,
	ref immutable StructDeclAst.Body.Union un,
	ref MutArr!(Ptr!StructInst) delayStructInsts,
) {
	immutable UnionMember[] members = map!UnionMember(
		alloc,
		un.members,
		(ref immutable StructDeclAst.Body.Union.Member it) {
			immutable Opt!Type type = !has(it.type) ? none!Type : some(typeFromAst(
				alloc,
				ctx,
				commonTypes,
				force(it.type),
				structsAndAliasesDict,
				TypeParamsScope(struct_.deref().typeParams),
				someMut(ptrTrustMe_mut(delayStructInsts))));
			if (has(type) && isPurityWorse(force(type).bestCasePurity, struct_.deref().purity))
				addDiag(alloc, ctx, it.range, immutable Diag(
					immutable Diag.PurityWorseThanParent(struct_, force(type))));
			return immutable UnionMember(rangeInFile(ctx, it.range), it.name, type);
		});
	everyPair!UnionMember(members, (ref immutable UnionMember a, ref immutable UnionMember b) {
		if (symEq(a.name, b.name))
			addDiag(alloc, ctx, b.range, immutable Diag(
				immutable Diag.DuplicateDeclaration(Diag.DuplicateDeclaration.Kind.unionMember, a.name)));
	});
	return immutable StructBody.Union(members);
}

void checkStructBodies(
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
			immutable StructBody body_ = matchStructDeclAstBody!(
				immutable StructBody,
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
					immutable StructBody(checkUnion(
						alloc,
						ctx,
						commonTypes,
						structsAndAliasesDict,
						castImmutable(struct_),
						it,
						delayStructInsts)),
			)(ast.body_);
			setBody(struct_.deref(), body_);
		});
}

immutable(StructsAndAliasesDict) buildStructsAndAliasesDict(
	ref Alloc alloc,
	ref CheckCtx ctx,
	immutable StructDecl[] structs,
	immutable StructAlias[] aliases,
) {
	SymDictBuilder!StructOrAliasAndIndex builder;
	void warnOnDup(immutable Sym name, immutable Opt!StructOrAliasAndIndex opt) {
		if (has(opt))
			addDiag(alloc, ctx, force(opt).structOrAlias.range, immutable Diag(
				immutable Diag.DuplicateDeclaration(Diag.DuplicateDeclaration.Kind.structOrAlias, name)));
	}
	foreach (immutable size_t index; 0 .. structs.length) {
		immutable Ptr!StructDecl decl = ptrAt(structs, index);
		immutable Sym name = decl.deref().name;
		warnOnDup(name, tryAddToDict(alloc, builder, name, immutable StructOrAliasAndIndex(
			immutable StructOrAlias(decl),
			immutable ModuleLocalStructOrAliasIndex(index))));
	}
	foreach (immutable size_t index; 0 .. aliases.length) {
		immutable Ptr!StructAlias alias_ = ptrAt(aliases, index);
		immutable Sym name = alias_.deref().name;
		warnOnDup(name, tryAddToDict(alloc, builder, name, immutable StructOrAliasAndIndex(
			immutable StructOrAlias(alias_),
			immutable ModuleLocalStructOrAliasIndex(index))));
	}
	return finishDict(alloc, builder);
}

struct FunsAndDict {
	immutable FunDecl[] funs;
	immutable Test[] tests;
	immutable FunsDict funsDict;
	immutable CommonFuns commonFuns;
}

immutable(ArrWithSize!(Ptr!SpecInst)) checkSpecUses(
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
			if (!sizeEq(typeArgs, spec.deref().typeParams)) {
				addDiag(alloc, ctx, ast.range, immutable Diag(
					immutable Diag.WrongNumberTypeArgsForSpec(spec, spec.deref().typeParams.length, typeArgs.length)));
				return none!(Ptr!SpecInst);
			} else
				return some(instantiateSpec(alloc, ctx.programState, SpecDeclAndArgs(spec, typeArgs)));
		} else {
			addDiag(alloc, ctx, rangeOfNameAndRange(ast.spec, ctx.allSymbols), immutable Diag(
				immutable Diag.NameNotFound(Diag.NameNotFound.Kind.spec, ast.spec.name)));
			return none!(Ptr!SpecInst);
		}
	});
}

immutable(bool) recordIsAlwaysByVal(ref immutable StructBody.Record record) {
	return empty(record.fields) || record.flags.forcedByValOrRef == ForcedByValOrRefOrNone.byVal;
}

immutable(FunsAndDict) checkFuns(
	ref Alloc alloc,
	ref AllSymbols allSymbols,
	ref CheckCtx ctx,
	ref immutable CommonTypes commonTypes,
	ref immutable Opt!CommonFuns commonFunsFromBootstrap,
	ref immutable SpecsDict specsDict,
	ref immutable StructDecl[] structs,
	ref immutable StructsAndAliasesDict structsAndAliasesDict,
	ref immutable FunDeclAst[] asts,
	ref immutable TestAst[] testAsts,
) {
	ExactSizeArrBuilder!FunDecl funsBuilder = newExactSizeArrBuilder!FunDecl(alloc, countFunsForStruct(asts, structs));
	foreach (ref immutable FunDeclAst funAst; asts) {
		immutable ArrWithSize!TypeParam typeParams = checkTypeParams(alloc, ctx, funAst.typeParams);
		immutable Sig sig = checkSig(
			alloc,
			ctx,
			commonTypes,
			funAst.sig,
			toArr(typeParams),
			structsAndAliasesDict,
			noneMut!(Ptr!(MutArr!(Ptr!StructInst))));
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
			FunDecl(copySafeCStr(alloc, funAst.docComment), funAst.visibility, flags, sig, typeParams, specUses));
	}
	foreach (immutable Ptr!StructDecl struct_; ptrsRange(structs))
		addFunsForStruct(alloc, allSymbols, ctx, funsBuilder, commonTypes, struct_);
	FunDecl[] funs = finish(funsBuilder);
	bool[] usedFuns = fillArr_mut!bool(alloc, funs.length, (immutable size_t) =>
		false);

	immutable FunsDict funsDict = buildMultiDict!(Sym, FunDeclAndIndex, symEq, hashSym, FunDecl)(
		alloc,
		castImmutable(funs),
		(immutable size_t index, immutable Ptr!FunDecl it) =>
			immutable KeyValuePair!(Sym, FunDeclAndIndex)(
				name(it.deref()),
				immutable FunDeclAndIndex(immutable ModuleLocalFunIndex(index), it)));

	foreach (ref const FunDecl f; funs)
		addToMutSymSetOkIfPresent(alloc, ctx.programState.names.funNames, name(f));

	immutable CommonFuns commonFuns = has(commonFunsFromBootstrap)
		? force(commonFunsFromBootstrap)
		: getCommonFuns(alloc, ctx, funsDict);

	FunDecl[] funsWithAsts = funs[0 .. asts.length];
	zipMutPtrFirst!(FunDecl, FunDeclAst)(funsWithAsts, asts, (Ptr!FunDecl fun, ref immutable FunDeclAst funAst) {
		overwriteMemory(&fun.deref().body_, matchFunBodyAst!(
			immutable FunBody,
			(ref immutable FunBodyAst.Builtin) =>
				immutable FunBody(immutable FunBody.Builtin()),
			(ref immutable FunBodyAst.Extern e) {
				if (!fun.deref().noCtx)
					todo!void("'extern' fun must be 'noctx'");
				if (e.isGlobal && arityIsNonZero(arity(fun.deref())))
					todo!void("'global' fun has parameters");
				return immutable FunBody(immutable FunBody.Extern(e.isGlobal, e.libraryName));
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
					paramsArray(params(f.deref())),
					specs(f.deref()),
					f.deref().flags,
					e));
			},
		)(funAst.body_));
	});

	immutable Test[] tests = map!(Test, TestAst)(alloc, testAsts, (ref immutable TestAst ast) {
		immutable Type voidType = immutable Type(commonTypes.void_);
		return immutable Test(checkFunctionBody(
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
			final switch (fun.deref().visibility) {
				case Visibility.public_:
					break;
				case Visibility.private_:
					if (!used && !okIfUnused(fun.deref()))
						addDiag(alloc, ctx, fun.deref().range, immutable Diag(
							immutable Diag.UnusedPrivateFun(fun)));
			}
		});

	return immutable FunsAndDict(castImmutable(funs), tests, funsDict, commonFuns);
}

immutable(CommonFuns) getCommonFuns(
	ref Alloc alloc,
	ref CheckCtx ctx,
	ref immutable FunsDict funsDict,
) {
	immutable(Ptr!FunDecl) commonFunDecl(immutable string name) {
		immutable Sym nameSym = shortSym(name);
		immutable FunDeclAndIndex[] funs = multiDictGetAt(funsDict, nameSym);
		if (funs.length != 1) {
			addDiag(
				alloc,
				ctx,
				immutable FileAndRange(ctx.fileIndex, RangeWithinFile.empty),
				immutable Diag(immutable Diag.CommonFunMissing(nameSym)));
			return castImmutable(allocateMut(alloc, FunDecl(
				safeCStr!"",
				Visibility.public_,
				FunFlags.none,
				immutable Sig(
					immutable FileAndPos(ctx.fileIndex, 0),
					nameSym,
					immutable Type(immutable Type.Bogus()),
					immutable Params(emptyArrWithSize!Param)),
				emptyArrWithSize!TypeParam(),
				emptyArrWithSize!(Ptr!SpecInst)())));
		} else
			return only(funs).decl;
	}

	immutable Ptr!FunDecl noneFun = commonFunDecl("none");
	return immutable CommonFuns(noneFun);
}

immutable(size_t) countFunsForStruct(
	ref immutable FunDeclAst[] asts,
	ref immutable StructDecl[] structs,
) {
	return asts.length + sum!StructDecl(structs, (ref immutable StructDecl s) =>
		matchStructBody!(immutable size_t)(
			body_(s),
			(ref immutable StructBody.Bogus) =>
				immutable size_t(0),
			(ref immutable StructBody.Builtin) =>
				immutable size_t(0),
			(ref immutable StructBody.Enum it) =>
				// '==', 'to-intXX'/'to-natXX', 'enum-members', and a constructor for each member
				3 + it.members.length,
			(ref immutable StructBody.Flags it) =>
				// 'empty', 'all', '==', '~', '|', '&', 'to-intXX'/'to-natXX', 'flags-members',
				// and a constructor for each member
				8 + it.members.length,
			(ref immutable StructBody.ExternPtr) =>
				immutable size_t(0),
			(ref immutable StructBody.Record it) {
				immutable size_t nConstructors = recordIsAlwaysByVal(it) ? 1 : 2;
				immutable size_t nMutableFields = count!RecordField(it.fields, (ref immutable RecordField field) =>
					field.mutability != FieldMutability.const_);
				return nConstructors + it.fields.length + nMutableFields;
			},
			(ref immutable StructBody.Union it) =>
				it.members.length));
}

void addFunsForStruct(
	ref Alloc alloc,
	ref AllSymbols allSymbols,
	ref CheckCtx ctx,
	ref ExactSizeArrBuilder!FunDecl funsBuilder,
	ref immutable CommonTypes commonTypes,
	immutable Ptr!StructDecl struct_,
) {
	matchStructBody!void(
		body_(struct_.deref()),
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
		(ref immutable StructBody.Union it) {
			addFunsForUnion(alloc, allSymbols, ctx, funsBuilder, commonTypes, struct_, it);
		});
}

void addFunsForEnum(
	ref Alloc alloc,
	ref AllSymbols allSymbols,
	ref CheckCtx ctx,
	ref ExactSizeArrBuilder!FunDecl funsBuilder,
	ref immutable CommonTypes commonTypes,
	immutable Ptr!StructDecl struct_,
	ref immutable StructBody.Enum enum_,
) {
	immutable Type enumType =
		immutable Type(instantiateNonTemplateStructDeclNeverDelay(alloc, ctx.programState, struct_));
	immutable Visibility visibility = struct_.deref().visibility;
	immutable FileAndRange range = struct_.deref().range;
	addEnumFlagsCommonFunctions(
		alloc, funsBuilder, ctx.programState, visibility, range, enumType, enum_.backingType, commonTypes,
		shortSym("enum-members"));
	foreach (ref immutable StructBody.Enum.Member member; enum_.members)
		exactSizeArrBuilderAdd(funsBuilder, enumOrFlagsConstructor(alloc, visibility, enumType, member));
}

void addFunsForFlags(
	ref Alloc alloc,
	ref AllSymbols allSymbols,
	ref CheckCtx ctx,
	ref ExactSizeArrBuilder!FunDecl funsBuilder,
	ref immutable CommonTypes commonTypes,
	immutable Ptr!StructDecl struct_,
	ref immutable StructBody.Flags flags,
) {
	immutable Type type =
		immutable Type(instantiateNonTemplateStructDeclNeverDelay(alloc, ctx.programState, struct_));
	immutable Visibility visibility = struct_.deref().visibility;
	immutable FileAndRange range = struct_.deref().range;
	addEnumFlagsCommonFunctions(
		alloc, funsBuilder, ctx.programState, visibility, range, type, flags.backingType, commonTypes,
		symForSpecial(SpecialSym.flags_members));
	exactSizeArrBuilderAdd(funsBuilder, flagsEmptyFunction(alloc, visibility, range, type));
	exactSizeArrBuilderAdd(funsBuilder, flagsAllFunction(alloc, visibility, range, type));
	exactSizeArrBuilderAdd(funsBuilder, flagsNegateFunction(alloc, visibility, range, type));
	exactSizeArrBuilderAdd(funsBuilder, flagsUnionOrIntersectFunction(
		alloc, visibility, range, type, Operator.or1, EnumFunction.union_));
	exactSizeArrBuilderAdd(funsBuilder, flagsUnionOrIntersectFunction(
		alloc, visibility, range, type, Operator.and1, EnumFunction.intersect));

	foreach (ref immutable StructBody.Enum.Member member; flags.members)
		exactSizeArrBuilderAdd(funsBuilder, enumOrFlagsConstructor(alloc, visibility, type, member));
}

void addEnumFlagsCommonFunctions(
	ref Alloc alloc,
	ref ExactSizeArrBuilder!FunDecl funsBuilder,
	ref ProgramState programState,
	immutable Visibility visibility,
	ref immutable FileAndRange range,
	immutable Type type,
	immutable EnumBackingType backingType,
	ref immutable CommonTypes commonTypes,
	immutable Sym membersName,
) {
	exactSizeArrBuilderAdd(funsBuilder, enumEqualFunction(alloc, visibility, range, type, commonTypes));
	exactSizeArrBuilderAdd(
		funsBuilder,
		enumToIntegralFunction(alloc, visibility, range, backingType, type, commonTypes));
	exactSizeArrBuilderAdd(
		funsBuilder,
		enumOrFlagsMembersFunction(alloc, programState, visibility, range, membersName, type, commonTypes));
}

FunDecl enumOrFlagsConstructor(
	ref Alloc alloc,
	immutable Visibility visibility,
	immutable Type enumType,
	ref immutable StructBody.Enum.Member member,
) {
	return FunDecl(
		safeCStr!"",
		visibility,
		FunFlags.generatedNoCtx,
		immutable Sig(
			fileAndPosFromFileAndRange(member.range),
			member.name,
			enumType,
			immutable Params(emptyArrWithSize!Param)),
		emptyArrWithSize!TypeParam,
		emptyArrWithSize!(Ptr!SpecInst),
		immutable FunBody(immutable FunBody.CreateEnum(member.value)));
}

FunDecl enumEqualFunction(
	ref Alloc alloc,
	immutable Visibility visibility,
	immutable FileAndRange fileAndRange,
	immutable Type enumType,
	ref immutable CommonTypes commonTypes,
) {
	return FunDecl(
		safeCStr!"",
		visibility,
		FunFlags.generatedNoCtx,
		immutable Sig(
			fileAndPosFromFileAndRange(fileAndRange),
			symForOperator(Operator.equal),
			immutable Type(commonTypes.bool_),
			immutable Params(arrWithSizeLiteral!Param(alloc, [
				immutable Param(fileAndRange, some(shortSym("a")), enumType, 0),
				immutable Param(fileAndRange, some(shortSym("b")), enumType, 1)]))),
		emptyArrWithSize!TypeParam,
		emptyArrWithSize!(Ptr!SpecInst),
		immutable FunBody(EnumFunction.equal));
}

FunDecl flagsEmptyFunction(
	ref Alloc alloc,
	immutable Visibility visibility,
	immutable FileAndRange fileAndRange,
	immutable Type enumType,
) {
	return FunDecl(
		safeCStr!"",
		visibility,
		FunFlags.generatedNoCtx,
		immutable Sig(
			fileAndPosFromFileAndRange(fileAndRange),
			shortSym("empty"),
			enumType,
			immutable Params(emptyArrWithSize!Param)),
		emptyArrWithSize!TypeParam,
		emptyArrWithSize!(Ptr!SpecInst),
		immutable FunBody(FlagsFunction.empty));
}

FunDecl flagsAllFunction(
	ref Alloc alloc,
	immutable Visibility visibility,
	immutable FileAndRange fileAndRange,
	immutable Type enumType,
) {
	return FunDecl(
		safeCStr!"",
		visibility,
		FunFlags.generatedNoCtx,
		immutable Sig(
			fileAndPosFromFileAndRange(fileAndRange),
			shortSym("all"),
			enumType,
			immutable Params(emptyArrWithSize!Param)),
		emptyArrWithSize!TypeParam,
		emptyArrWithSize!(Ptr!SpecInst),
		immutable FunBody(FlagsFunction.all));
}

FunDecl flagsNegateFunction(
	ref Alloc alloc,
	immutable Visibility visibility,
	immutable FileAndRange fileAndRange,
	immutable Type enumType,
) {
	return FunDecl(
		safeCStr!"",
		visibility,
		FunFlags.generatedNoCtx,
		immutable Sig(
			fileAndPosFromFileAndRange(fileAndRange),
			symForOperator(Operator.tilde),
			enumType,
			immutable Params(arrWithSizeLiteral!Param(alloc, [
				immutable Param(fileAndRange, some(shortSym("a")), enumType, 0)]))),
		emptyArrWithSize!TypeParam,
		emptyArrWithSize!(Ptr!SpecInst),
		immutable FunBody(FlagsFunction.negate));
}

FunDecl enumToIntegralFunction(
	ref Alloc alloc,
	immutable Visibility visibility,
	immutable FileAndRange fileAndRange,
	immutable EnumBackingType enumBackingType,
	immutable Type enumType,
	ref immutable CommonTypes commonTypes,
) {
	return FunDecl(
		safeCStr!"",
		visibility,
		FunFlags.generatedNoCtx,
		immutable Sig(
			fileAndPosFromFileAndRange(fileAndRange),
			enumToIntegralName(enumBackingType),
			immutable Type(getBackingTypeFromEnumType(enumBackingType, commonTypes)),
			immutable Params(arrWithSizeLiteral!Param(alloc, [
				immutable Param(fileAndRange, some(shortSym("a")), enumType, 0)]))),
		emptyArrWithSize!TypeParam,
		emptyArrWithSize!(Ptr!SpecInst),
		immutable FunBody(EnumFunction.toIntegral));
}

FunDecl enumOrFlagsMembersFunction(
	ref Alloc alloc,
	ref ProgramState programState,
	immutable Visibility visibility,
	ref immutable FileAndRange fileAndRange,
	immutable Sym name,
	immutable Type enumType,
	ref immutable CommonTypes commonTypes,
) {
	return FunDecl(
		safeCStr!"",
		visibility,
		FunFlags.generatedNoCtx,
		immutable Sig(
			fileAndPosFromFileAndRange(fileAndRange),
			name,
			immutable Type(makeArrayType(
				alloc,
				programState,
				commonTypes,
				immutable Type(makeNamedValType(alloc, programState, commonTypes, enumType)))),
			immutable Params(emptyArrWithSize!Param)),
		emptyArrWithSize!TypeParam,
		emptyArrWithSize!(Ptr!SpecInst),
		immutable FunBody(EnumFunction.members));
}

FunDecl flagsUnionOrIntersectFunction(
	ref Alloc alloc,
	immutable Visibility visibility,
	immutable FileAndRange fileAndRange,
	immutable Type enumType,
	immutable Operator operator,
	immutable EnumFunction fn,
) {
	return FunDecl(
		safeCStr!"",
		visibility,
		FunFlags.generatedNoCtx,
		immutable Sig(
			fileAndPosFromFileAndRange(fileAndRange),
			symForOperator(operator),
			enumType,
			immutable Params(arrWithSizeLiteral!Param(alloc, [
				immutable Param(fileAndRange, some(shortSym("a")), enumType, 0),
				immutable Param(fileAndRange, some(shortSym("b")), enumType, 0)]))),
		emptyArrWithSize!TypeParam,
		emptyArrWithSize!(Ptr!SpecInst),
		immutable FunBody(fn));
}

//TODO: actually, we should record the type name used,
//so if they had 'e enum<size_t>' we should have 'to-size_t' not 'to-nat64'
immutable(Sym) enumToIntegralName(immutable EnumBackingType a) {
	return shortSym(() {
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

void addFunsForRecord(
	ref Alloc alloc,
	ref AllSymbols allSymbols,
	ref CheckCtx ctx,
	ref ExactSizeArrBuilder!FunDecl funsBuilder,
	ref immutable CommonTypes commonTypes,
	immutable Ptr!StructDecl struct_,
	ref immutable StructBody.Record record,
) {
	immutable ArrWithSize!TypeParam typeParams = struct_.deref().typeParams_;
	immutable Type[] typeArgs = mapPtrs(alloc, toArr(typeParams), (immutable Ptr!TypeParam p) =>
		immutable Type(p));
	immutable Type structType = immutable Type(instantiateStructNeverDelay(
		alloc,
		ctx.programState,
		immutable StructDeclAndArgs(struct_, typeArgs)));
	immutable ArrWithSize!Param ctorParams = mapWithSize(alloc, record.fields, (ref immutable RecordField it) =>
		immutable Param(it.range, some(it.name), it.type, it.index));
	FunDecl constructor(immutable Type returnType, immutable FunFlags flags) {
		return FunDecl(
			safeCStr!"",
			record.flags.newVisibility,
			flags.withOkIfUnused(),
			immutable Sig(
				fileAndPosFromFileAndRange(struct_.deref().range),
				shortSym("new"),
				returnType,
				immutable Params(ctorParams)),
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

	foreach (immutable size_t fieldIndex, ref immutable RecordField field; record.fields) {
		immutable Visibility fieldVisibility = leastVisibility(struct_.deref().visibility, field.visibility);
		exactSizeArrBuilderAdd(funsBuilder, FunDecl(
			safeCStr!"",
			fieldVisibility,
			FunFlags.generatedNoCtx,
			immutable Sig(
				fileAndPosFromFileAndRange(field.range),
				field.name,
				field.type,
				immutable Params(arrWithSizeLiteral!Param(alloc, [
					immutable Param(field.range, some(shortSym("a")), structType, 0)]))),
			typeParams,
			emptyArrWithSize!(Ptr!SpecInst),
			immutable FunBody(immutable FunBody.RecordFieldGet(fieldIndex))));

		immutable Opt!Visibility mutVisibility = visibilityOfFieldMutability(field.mutability);
		if (has(mutVisibility))
			exactSizeArrBuilderAdd(funsBuilder, FunDecl(
				safeCStr!"",
				force(mutVisibility),
				FunFlags.generatedNoCtx,
				immutable Sig(
					fileAndPosFromFileAndRange(field.range),
					prependSet(allSymbols, field.name),
					immutable Type(commonTypes.void_),
					immutable Params(arrWithSizeLiteral!Param(alloc, [
						immutable Param(field.range, some(shortSym("a")), structType, 0),
						immutable Param(field.range, some(field.name), field.type, 1)]))),
				typeParams,
				emptyArrWithSize!(Ptr!SpecInst),
				immutable FunBody(immutable FunBody.RecordFieldSet(fieldIndex))));
	}
}

immutable(Opt!Visibility) visibilityOfFieldMutability(immutable FieldMutability a) {
	final switch (a) {
		case FieldMutability.const_:
			return none!Visibility;
		case FieldMutability.private_:
			return some(Visibility.private_);
		case FieldMutability.public_:
			return some(Visibility.public_);
	}
}

void addFunsForUnion(
	ref Alloc alloc,
	ref AllSymbols allSymbols,
	ref CheckCtx ctx,
	ref ExactSizeArrBuilder!FunDecl funsBuilder,
	ref immutable CommonTypes commonTypes,
	immutable Ptr!StructDecl struct_,
	ref immutable StructBody.Union union_,
) {
	immutable ArrWithSize!TypeParam typeParams = struct_.deref().typeParams_;
	immutable Type[] typeArgs = mapPtrs(alloc, toArr(typeParams), (immutable Ptr!TypeParam p) =>
		immutable Type(p));
	immutable Type structType = immutable Type(instantiateStructNeverDelay(
		alloc,
		ctx.programState,
		immutable StructDeclAndArgs(struct_, typeArgs)));
	foreach (immutable size_t memberIndex, ref immutable UnionMember member; union_.members) {
		immutable ArrWithSize!Param params = has(member.type)
			? arrWithSizeLiteral!Param(alloc, [
				immutable Param(member.range, some(shortSym("a")), force(member.type), 0)])
			: emptyArrWithSize!Param;
		exactSizeArrBuilderAdd(funsBuilder, FunDecl(
			safeCStr!"",
			struct_.deref().visibility,
			FunFlags.generatedNoCtx,
			immutable Sig(
				fileAndPosFromFileAndRange(member.range),
				member.name,
				structType,
				immutable Params(params)),
			typeParams,
			emptyArrWithSize!(Ptr!SpecInst),
			immutable FunBody(immutable FunBody.CreateUnion(memberIndex))));
	}
}

immutable(SpecsDict) buildSpecsDict(
	ref Alloc alloc,
	ref CheckCtx ctx,
	ref immutable SpecDecl[] specs,
) {
	SymDictBuilder!SpecDeclAndIndex res;
	foreach (immutable size_t index; 0 .. specs.length) {
		immutable Ptr!SpecDecl spec = ptrAt(specs, index);
		immutable Sym name = spec.deref().name;
		immutable Opt!SpecDeclAndIndex b =
			tryAddToDict(alloc, res, name, immutable SpecDeclAndIndex(spec, immutable ModuleLocalSpecIndex(index)));
		if (has(b))
			addDiag(alloc, ctx, force(b).decl.deref().range, immutable Diag(
				immutable Diag.DuplicateDeclaration(Diag.DuplicateDeclaration.Kind.spec, name)));
	}
	return finishDict(alloc, res);
}

struct ModuleAndCommonFuns {
	immutable Module module_;
	immutable CommonFuns commonFuns;
}

immutable(ModuleAndCommonFuns) checkWorkerAfterCommonTypes(
	ref Alloc alloc,
	ref AllSymbols allSymbols,
	ref CheckCtx ctx,
	ref immutable CommonTypes commonTypes,
	ref immutable Opt!CommonFuns commonFunsFromBootstrap,
	ref immutable StructsAndAliasesDict structsAndAliasesDict,
	immutable StructAlias[] structAliases,
	ref StructDecl[] structs,
	ref MutArr!(Ptr!StructInst) delayStructInsts,
	immutable FileIndex fileIndex,
	ref immutable ModuleAndNames[] imports,
	ref immutable ModuleAndNames[] reExports,
	ref immutable FileAst ast,
) {
	checkStructBodies(alloc, ctx, commonTypes, structsAndAliasesDict, structs, ast.structs, delayStructInsts);
	immutable StructDecl[] structsImmutable = castImmutable(structs);
	foreach (ref const StructDecl s; structs)
		if (isRecord(s.body_))
			foreach (ref immutable RecordField f; asRecord(s.body_).fields)
				addToMutSymSetOkIfPresent(alloc, ctx.programState.names.recordFieldNames, f.name);

	while (!mutArrIsEmpty(delayStructInsts)) {
		Ptr!StructInst i = mustPop(delayStructInsts);
		setBody(i.deref(), instantiateStructBody(
			alloc,
			ctx.programState,
			i.deref().declAndArgs,
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

	checkForUnused(alloc, ctx, structAliases, castImmutable(structs), specs);

	return immutable ModuleAndCommonFuns(
		immutable Module(
			fileIndex,
			copySafeCStr(alloc, ast.docComment),
			imports, reExports,
			structsImmutable, specs, funsAndDict.funs, funsAndDict.tests,
			getAllExportedNames(
				alloc,
				ctx.diagsBuilder,
				reExports,
				structsAndAliasesDict,
				specsDict,
				funsAndDict.funsDict,
				fileIndex)),
		funsAndDict.commonFuns);
}

immutable(SymDict!NameReferents) getAllExportedNames(
	ref Alloc alloc,
	ref DiagnosticsBuilder diagsBuilder,
	ref immutable ModuleAndNames[] reExports,
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

	foreach (ref immutable ModuleAndNames e; reExports) {
		dictEach!(Sym, NameReferents, symEq, hashSym)(
			e.module_.allExportedNames,
			(immutable Sym name, ref immutable NameReferents value) {
				if (!has(e.names) || containsSym(force(e.names), name))
					addExport(name, value, immutable FileAndRange(
						fileIndex,
						has(e.importSource) ? force(e.importSource) : RangeWithinFile.empty));
			});
	}
	dictEach!(Sym, StructOrAliasAndIndex, symEq, hashSym)(
		structsAndAliasesDict,
		(immutable Sym name, ref immutable StructOrAliasAndIndex it) {
			final switch (visibility(it.structOrAlias)) {
				case Visibility.public_:
					addExport(
						name,
						immutable NameReferents(some(it.structOrAlias), none!(Ptr!SpecDecl), emptyArr!(Ptr!FunDecl)),
						range(it.structOrAlias));
					break;
				case Visibility.private_:
					break;
			}
		});
	dictEach!(Sym, SpecDeclAndIndex, symEq, hashSym)(
		specsDict,
		(immutable Sym name, ref immutable SpecDeclAndIndex it) {
			final switch (it.decl.deref().visibility) {
				case Visibility.public_:
					addExport(
						name,
						immutable NameReferents(none!StructOrAlias, some(it.decl), emptyArr!(Ptr!FunDecl)),
						it.decl.deref().range);
					break;
				case Visibility.private_:
					break;
			}
		});
	multiDictEach!(Sym, FunDeclAndIndex, symEq, hashSym)(
		funsDict,
		(immutable Sym name, immutable FunDeclAndIndex[] funs) {
			immutable Ptr!FunDecl[] funDecls = mapOp!(Ptr!FunDecl)(
				alloc,
				funs,
				(ref immutable FunDeclAndIndex it) {
					final switch (it.decl.deref().visibility) {
						case Visibility.public_:
							return some(it.decl);
						case Visibility.private_:
							return none!(Ptr!FunDecl);
					}
				});
			if (!empty(funDecls))
				addExport(
					name,
					immutable NameReferents(none!StructOrAlias, none!(Ptr!SpecDecl), funDecls),
					// This argument doesn't matter because a function never results in a duplicate export error
					immutable FileAndRange(fileIndex, RangeWithinFile.empty));
		});

	return moveToDict!(Sym, NameReferents, symEq, hashSym)(alloc, res);
}

immutable(BootstrapCheck) checkWorker(
	ref Alloc alloc,
	scope ref Perf perf,
	ref AllSymbols allSymbols,
	ref DiagnosticsBuilder diagsBuilder,
	ref ProgramState programState,
	immutable ModuleAndNames[] imports,
	immutable ModuleAndNames[] reExports,
	ref immutable PathAndAst pathAndAst,
	immutable Opt!CommonFuns commonFunsFromBootstrap,
	scope immutable(CommonTypes) delegate(
		ref CheckCtx,
		ref immutable StructsAndAliasesDict,
		ref MutArr!(Ptr!StructInst),
	) @safe @nogc pure nothrow getCommonTypes,
) {
	checkImportsOrExports(alloc, diagsBuilder, pathAndAst.fileIndex, imports);
	checkImportsOrExports(alloc, diagsBuilder, pathAndAst.fileIndex, reExports);
	immutable FileAst ast = pathAndAst.ast;
	CheckCtx ctx = CheckCtx(
		ptrTrustMe_mut(perf),
		ptrTrustMe_mut(programState),
		ptrTrustMe_mut(allSymbols),
		pathAndAst.fileIndex,
		imports,
		reExports,
		// TODO: use temp alloc
		newUsedImportsAndReExports(alloc, imports, reExports),
		// TODO: use temp alloc
		fillArr_mut(alloc, ast.structAliases.length, (immutable size_t) => false),
		// TODO: use temp alloc
		fillArr_mut(alloc, ast.structs.length, (immutable size_t) => false),
		// TODO: use temp alloc
		fillArr_mut(alloc, ast.specs.length, (immutable size_t) => false),
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

	immutable CommonTypes commonTypes = getCommonTypes(ctx, structsAndAliasesDict, delayStructInsts);

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

void checkImportsOrExports(
	ref Alloc alloc,
	ref DiagnosticsBuilder diags,
	immutable FileIndex thisFile,
	ref immutable ModuleAndNames[] imports,
) {
	foreach (ref immutable ModuleAndNames m; imports)
		if (has(m.names))
			foreach (ref immutable Sym name; force(m.names))
				if (!hasKey(m.module_.allExportedNames, name))
					addDiagnostic(
						alloc,
						diags,
						// TODO: use the range of the particular name
						// (by advancing pos by symSize until we get to this name)
						immutable FileAndRange(thisFile, force(m.importSource)),
						immutable Diag(immutable Diag.ImportRefersToNothing(name)));
}
