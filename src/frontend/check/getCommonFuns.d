module frontend.check.getCommonFuns;

@safe @nogc pure nothrow:

import frontend.check.checkCtx : CommonModule;
import frontend.check.funsForStruct : funDeclWithBody;
import frontend.check.getCommonTypes : bogusStructDecl;
import frontend.check.inferringType : typesAreCorrespondingStructInsts;
import frontend.check.instantiate : InstantiateCtx, instantiateFun, instantiateStructNeverDelay;
import model.ast : ModifierAst, NameAndRange, VarDeclAst, TypeAst;
import model.diag : Diag, UriAndDiagnostic;
import model.model :
	assertNonVariadic,
	CommonFuns,
	CommonFunsAndDiagnostics,
	CommonTypes,
	Destructure,
	emptySpecImpls,
	emptyTypeArgs,
	emptyTypeParams,
	FunBody,
	FunDecl,
	FunDeclSource,
	FunFlags,
	FunInst,
	FunKind,
	Local,
	LocalMutability,
	LocalSource,
	MainFun,
	MainFunAndDiagnostics,
	Module,
	moduleAtUri,
	NameReferents,
	Params,
	ParamShort,
	ParamsShort,
	Program,
	StructInst,
	StructOrAlias,
	StructDecl,
	Type,
	TypeParamIndex,
	TypeParams,
	TypeParamsAndSig,
	VarDecl,
	VarKind,
	Visibility;
import util.alloc.alloc : Alloc;
import util.col.array :
	arraysCorrespond, copyArray, emptySmallArray, findIndex, isEmpty, map, sizeEq, small;
import util.col.arrayBuilder : add, ArrayBuilder, smallFinish;
import util.col.enumMap : EnumMap, enumMapMapValues;
import util.late : late, Late, lateGet, lateIsSet, lateSet;
import util.memory : allocate;
import util.opt : force, has, none, MutOpt, Opt, some, someMut;
import util.sourceRange : Range, UriAndRange;
import util.string : emptySmallString;
import util.symbol : Symbol, symbol;
import util.symbolSet : SymbolSet, symbolSetDifference;
import util.uri : Uri;
import util.util : castNonScope_ref;

CommonFunsAndDiagnostics getCommonFuns(
	ref Alloc alloc,
	InstantiateCtx ctx,
	ref CommonTypes commonTypes,
	in EnumMap!(CommonModule, Module*) modules,
) {
	ArrayBuilder!UriAndDiagnostic diagsBuilder;

	Type getType(CommonModule module_, Symbol name) =>
		getNonTemplateType(alloc, ctx, diagsBuilder, *modules[module_], name);
	Type instantiateType(StructDecl* decl, in Type[] typeArgs) =>
		Type(instantiateStructNeverDelay(ctx, decl, typeArgs));
	FunDecl* getFunDeclInner(
		ref Module module_,
		Symbol name,
		TypeParams typeParams,
		Type returnType,
		in ParamShort[] params,
		uint countSpecs,
	) =>
		getFunDecl(
			alloc, diagsBuilder, module_, name,
			TypeParamsAndSig(typeParams, returnType, ParamsShort(small!ParamShort(params)), countSpecs));
	FunInst* getFunInner(ref Module module_, Symbol name, Type returnType, in ParamShort[] params) =>
		instantiateNonTemplateFun(ctx, getFunDeclInner(module_, name, emptyTypeParams, returnType, params, 0));
	FunInst* getFun(CommonModule module_, Symbol name, Type returnType, in ParamShort[] params) =>
		getFunInner(*modules[module_], name, returnType, params);
	VarDecl* getVar(CommonModule module_, Symbol name, VarKind kind) =>
		getVarDecl(alloc, diagsBuilder, *modules[module_], name, kind);

	StructDecl* arrayDecl = getStructDeclOrAddDiag(
		alloc, diagsBuilder, *modules[CommonModule.bootstrap], symbol!"array", 1);
	StructDecl* tuple2Decl = getStructDeclOrAddDiag(
		alloc, diagsBuilder, *modules[CommonModule.bootstrap], symbol!"tuple2", 2);
	Type markCtxType = getType(CommonModule.bootstrap, symbol!"mark-ctx");
	Type boolType = Type(commonTypes.bool_);
	Type int32Type = Type(commonTypes.integrals.int32);
	Type nat8Type = Type(commonTypes.integrals.nat8);
	Type nat64Type = Type(commonTypes.integrals.nat64);
	Type voidType = Type(commonTypes.void_);
	Type stringType = Type(commonTypes.string_);
	Type stringArrayType = instantiateType(arrayDecl, [stringType]);
	Type nat8ConstPointerType = instantiateType(commonTypes.pointerConst, [nat8Type]);
	Type nat8MutPointerType = instantiateType(commonTypes.pointerMut, [nat8Type]);
	Type cStringType = Type(commonTypes.cString);
	Type cStringConstPointerType = instantiateType(commonTypes.pointerConst, [cStringType]);
	Type mainPointerType = instantiateType(commonTypes.funPointerStruct, [nat64Type, stringArrayType]);
	Type jsonType = getType(CommonModule.json, symbol!"json");

	Type rSharedOfP = instantiateType(commonTypes.funStructs[FunKind.shared_], [typeParam0, typeParam1]);
	Type rMutOfP = instantiateType(commonTypes.funStructs[FunKind.mut], [typeParam0, typeParam1]);
	Type symbolType = Type(commonTypes.symbol);
	Type symbolJsonTuple = instantiateType(tuple2Decl, [symbolType, jsonType]);
	Type symbolJsonTupleArray = instantiateType(arrayDecl, [symbolJsonTuple]);

	Type catchPoint = getType(CommonModule.bootstrap, symbol!"catch-point");
	Type catchPointConstPointer = instantiateType(commonTypes.pointerConst, [catchPoint]);

	Type gcRoot = getType(CommonModule.bootstrap, symbol!"gc-root");
	Type gcRootMutPointer = instantiateType(commonTypes.pointerMut, [gcRoot]);

	Type fiber = getType(CommonModule.bootstrap, symbol!"fiber");
	Type globalCtx = getType(CommonModule.runtime, symbol!"global-ctx");
	Type globalCtxMutPointer = instantiateType(commonTypes.pointerMut, [globalCtx]);

	Type jsAny = getType(CommonModule.js, symbol!"js-any");

	ParamsShort.Variadic newJsonPairsParams = ParamsShort.Variadic(
		param!"pairs"(symbolJsonTupleArray), symbolJsonTuple);
	CommonFuns commonFuns = CommonFuns(
		jsAwait: getFun(CommonModule.js,symbol!"await", jsAny, [param!"a"(jsAny)]),
		curCatchPoint: getFun(CommonModule.exceptionLowLevel, symbol!"cur-catch-point", catchPointConstPointer, []),
		setCurCatchPoint: getFun(
			CommonModule.exceptionLowLevel, symbol!"set-cur-catch-point",
			voidType, [param!"value"(catchPointConstPointer)]),
		curThrown: getVar(CommonModule.exceptionLowLevel, symbol!"cur-thrown", VarKind.threadLocal),
		allocate: getFun(CommonModule.alloc, symbol!"allocate", nat8MutPointerType, [param!"size-bytes"(nat64Type)]),
		and: getFun(CommonModule.boolLowLevel, symbol!"&&", boolType, [param!"a"(boolType), param!"b"(boolType)]),
		createError: getFun(
			CommonModule.exceptionLowLevel, symbol!"error", Type(commonTypes.exception), [param!"a"(stringType)]),
		lambdaSubscript: getLambdaSubscriptFuns(
			alloc, commonTypes, *modules[CommonModule.funUtil]),
		sharedOfMutLambda: getFunDeclInner(
			*modules[CommonModule.runtime],
			symbol!"shared-of-mut-lambda",
			twoTypeParams,
			rSharedOfP,
			[param!"a"(rMutOfP)],
			countSpecs: 2),
		mark: getFun(
			CommonModule.alloc,
			symbol!"mark",
			boolType,
			[param!"ctx"(markCtxType), param!"pointer"(nat8ConstPointerType), param!"size-bytes"(nat64Type)]),
		newJsonFromPairs: instantiateNonTemplateFun(ctx, getFunDecl(
			alloc, diagsBuilder, *modules[CommonModule.json], symbol!"new",
			TypeParamsAndSig(emptyTypeParams, jsonType, ParamsShort(&newJsonPairsParams), countSpecs: 0))),
		runFiber: getFun(
			CommonModule.runtime, symbol!"run-fiber",
			Type(commonTypes.void_),
			[param!"gctx"(globalCtxMutPointer), param!"fiber"(fiber)]),
		rtMain: getFun(
			CommonModule.runtimeMain,
			symbol!"rt-main",
			int32Type,
			[
				param!"argc"(int32Type),
				param!"argv"(cStringConstPointerType),
				param!"main"(mainPointerType),
			]),
		throwImpl: getFun(
			CommonModule.exceptionLowLevel,
			symbol!"throw-impl",
			voidType,
			[param!"a"(Type(commonTypes.exception))]),
		equalNat64: getFun(
			CommonModule.numberLowLevel,
			symbol!"==",
			boolType,
			[param!"a"(nat64Type), param!"b"(nat64Type)]),
		lessNat64: getFun(
			CommonModule.numberLowLevel, symbol!"is-less", boolType, [param!"a"(nat64Type), param!"b"(nat64Type)]),
		rethrowCurrentException: getFun(
			CommonModule.exceptionLowLevel, symbol!"rethrow-current-exception", voidType, []),
		gcRoot: getFun(CommonModule.alloc, symbol!"gc-root", gcRootMutPointer, []),
		setGcRoot: getFun(CommonModule.alloc, symbol!"set-gc-root", voidType, [
			param!"value"(gcRootMutPointer)]),
		popGcRoot: getFun(CommonModule.alloc, symbol!"pop-gc-root", voidType, []));
	return CommonFunsAndDiagnostics(commonFuns, smallFinish(alloc, diagsBuilder));
}

MainFunAndDiagnostics getMainFunAndDiagnostics(
	ref Alloc alloc,
	InstantiateCtx ctx,
	ref Program program,
	Uri mainUri,
	SymbolSet allExterns,
) {
	ArrayBuilder!UriAndDiagnostic diagsBuilder;
	ref CommonTypes commonTypes() => program.commonTypes;
	Type stringArrayType = Type(instantiateStructNeverDelay(ctx, commonTypes.array, [Type(commonTypes.string_)]));
	MainFun res = getMainFun(
		alloc, ctx, diagsBuilder, *moduleAtUri(program, mainUri),
		Type(commonTypes.integrals.nat64), stringArrayType, Type(commonTypes.void_));
	SymbolSet mainExterns = res.fun.decl.externs;
	if (!allExterns.containsAll(mainExterns))
		add(alloc, diagsBuilder, UriAndDiagnostic(
			res.fun.decl.range,
			Diag(Diag.MainMissingExterns(symbolSetDifference(alloc, mainExterns, allExterns)))));
	return MainFunAndDiagnostics(res, smallFinish(alloc, diagsBuilder));
}

Destructure makeParam(ref Alloc alloc, ParamShort param) =>
	Destructure(allocate(alloc, Local(
		LocalSource(allocate(alloc, LocalSource.Generated(param.name))), LocalMutability.immutable_, param.type)));

Params makeParams(ref Alloc alloc, in ParamsShort params) =>
	params.match!Params(
		(ParamShort[] x) =>
			makeParams(alloc, x),
		(ref ParamsShort.Variadic x) =>
			Params(allocate(alloc, Params.Varargs(makeParam(alloc, x.param), x.elementType))));
Params makeParams(ref Alloc alloc, in ParamShort[] params) =>
	Params(map(alloc, params, (ref ParamShort x) => makeParam(alloc, x)));

ParamShort param(string name)(Type type) =>
	ParamShort(symbol!name, type);

private:

immutable NameAndRange[2] twoTypeParamsArray = [NameAndRange(0, symbol!"r"), NameAndRange(0, symbol!"p")];
TypeParams twoTypeParams() => TypeParams(twoTypeParamsArray);
Type typeParam0() => Type(TypeParamIndex(0));
Type typeParam1() => Type(TypeParamIndex(1));

immutable(EnumMap!(FunKind, FunDecl*)) getLambdaSubscriptFuns(
	ref Alloc alloc,
	in CommonTypes commonTypes,
	in Module funUtil,
) {
	EnumMap!(FunKind, MutOpt!(FunDecl*)) res;
	foreach (FunDecl* x; getFuns(funUtil, symbol!"subscript")) {
		// TODO: check the type more thoroughly
		FunKind funKind = firstArgFunKind(commonTypes, x);
		assert(!has(res[funKind]));
		res[funKind] = someMut(x);
	}
	return enumMapMapValues!(FunKind, FunDecl*, MutOpt!(FunDecl*))(res, (const MutOpt!(FunDecl*) x) => force(x));
}

FunKind firstArgFunKind(in CommonTypes commonTypes, FunDecl* f) {
	Destructure[] params = assertNonVariadic(f.params);
	assert(!isEmpty(params));
	StructDecl* actual = params[0].type.as!(StructInst*).decl;
	foreach (FunKind kind; [FunKind.data, FunKind.shared_, FunKind.mut, FunKind.function_])
		if (actual == commonTypes.funStructs[kind])
			return kind;
	assert(false);
}

Type getNonTemplateType(
	ref Alloc alloc,
	InstantiateCtx ctx,
	scope ref ArrayBuilder!UriAndDiagnostic diagsBuilder,
	ref Module module_,
	Symbol name,
) {
	StructDecl* decl = getStructDeclOrAddDiag(alloc, diagsBuilder, module_, name, 0);
	assert(!decl.isTemplate);
	return Type(instantiateStructNeverDelay(ctx, decl, []));
}

StructDecl* getStructDeclOrAddDiag(
	ref Alloc alloc,
	scope ref ArrayBuilder!UriAndDiagnostic diagsBuilder,
	ref Module module_,
	Symbol name,
	size_t nTypeParams,
) {
	Opt!(StructDecl*) res = getStructDecl(module_, name);
	if (has(res) && force(res).typeParams.length == nTypeParams)
		return force(res);
	else {
		add(alloc, diagsBuilder, UriAndDiagnostic(
			UriAndRange(module_.uri, Range.empty),
			Diag(Diag.CommonTypeMissing(name))));
		return bogusStructDecl(alloc, name, nTypeParams);
	}
}

Opt!(StructDecl*) getStructDecl(in Module a, Symbol name) {
	Opt!NameReferents optReferents = a.exports[name];
	if (has(optReferents)) {
		Opt!StructOrAlias sa = force(optReferents).structOrAlias;
		return has(sa) && force(sa).isA!(StructDecl*)
			? some(force(sa).as!(StructDecl*))
			: none!(StructDecl*);
	} else
		return none!(StructDecl*);
}

bool signatureMatchesTemplate(in FunDecl actual, in TypeParamsAndSig expected) =>
	actual.specs.length == expected.countSpecs &&
		sizeEq(actual.typeParams, expected.typeParams) &&
		typesMatch(actual.returnType, actual.typeParams, expected.returnType, expected.typeParams) &&
		expected.params.matchIn!bool(
			(in ParamShort[] params) =>
				!actual.isVariadic && arraysCorrespond!(Destructure, ParamShort)(
					assertNonVariadic(actual.params),
					params,
					(ref Destructure x, ref ParamShort y) =>
						typesMatch(x.type, actual.typeParams, y.type, expected.typeParams)),
			(in ParamsShort.Variadic x) =>
				actual.isVariadic && typesMatch(
					actual.params.as!(Params.Varargs*).param.type, actual.typeParams,
					x.param.type, expected.typeParams));

bool typesMatch(in Type a, in TypeParams typeParamsA, in Type b, in TypeParams typeParamsB) =>
	a == b
	|| a.isA!(TypeParamIndex) && b.isA!(TypeParamIndex) && a.as!(TypeParamIndex).index == b.as!(TypeParamIndex).index
	|| typesAreCorrespondingStructInsts(a, b, (ref Type x, ref Type y) =>
		typesMatch(x, typeParamsA, y, typeParamsB));

VarDecl* getVarDecl(
	ref Alloc alloc,
	scope ref ArrayBuilder!UriAndDiagnostic diagsBuilder,
	ref Module module_,
	Symbol name,
	VarKind kind,
) {
	Late!(VarDecl*) res = late!(VarDecl*);
	foreach (ref VarDecl x; module_.vars)
		if (x.name == name && x.kind == kind)
			lateSet(res, &x);
	if (lateIsSet(res))
		return lateGet(res);
	else {
		add(alloc, diagsBuilder, UriAndDiagnostic(
			UriAndRange(module_.uri, Range.empty),
			Diag(Diag.CommonVarMissing(kind, name))));
		VarDeclAst* ast = allocate(alloc, VarDeclAst(
			Range.empty,
			emptySmallString,
			none!Visibility,
			NameAndRange(0, name),
			emptySmallArray!NameAndRange,
			0,
			kind,
			TypeAst(TypeAst.Bogus(Range.empty)),
			emptySmallArray!ModifierAst));
		return allocate(alloc, VarDecl(ast, module_.uri, Visibility.public_, Type.bogus, none!Symbol));
	}
}

FunDecl* getFunDecl(
	ref Alloc alloc,
	scope ref ArrayBuilder!UriAndDiagnostic diagsBuilder,
	ref Module module_,
	Symbol name,
	in TypeParamsAndSig expectedSig,
) =>
	getFunDeclMulti(alloc, diagsBuilder, module_, name, [castNonScope_ref(expectedSig)]).decl;

MainFun getMainFun(
	ref Alloc alloc,
	InstantiateCtx ctx,
	scope ref ArrayBuilder!UriAndDiagnostic diagsBuilder,
	ref Module mainModule,
	Type nat64Type,
	Type stringArrayType,
	Type voidType,
) {
	scope ParamShort[] argsParamsInner = [param!"args"(stringArrayType)];
	ParamsShort argsParams = ParamsShort(small!ParamShort(castNonScope_ref(argsParamsInner)));
	FunDeclAndSigIndex decl = getFunDeclMulti(alloc, diagsBuilder, mainModule, symbol!"main", [
		TypeParamsAndSig(emptyTypeParams, voidType, ParamsShort(emptySmallArray!ParamShort), countSpecs: 0),
		TypeParamsAndSig(emptyTypeParams, nat64Type, argsParams, countSpecs: 0)]);
	FunInst* inst = instantiateNonTemplateFun(ctx, decl.decl);
	final switch (decl.sigIndex) {
		case 0:
			return MainFun(MainFun.Void(stringArrayType.as!(StructInst*), inst));
		case 1:
			return MainFun(MainFun.Nat64OfArgs(inst));
	}
}

immutable struct FunDeclAndSigIndex {
	FunDecl* decl;
	size_t sigIndex;
}

FunDeclAndSigIndex getFunDeclMulti(
	ref Alloc alloc,
	scope ref ArrayBuilder!UriAndDiagnostic diagsBuilder,
	ref Module module_,
	Symbol name,
	in TypeParamsAndSig[] expectedSigs,
) {
	Late!FunDeclAndSigIndex res = late!FunDeclAndSigIndex();
	foreach (FunDecl* x; getFuns(module_, name)) {
		Opt!size_t index = findIndex!TypeParamsAndSig(expectedSigs, (in TypeParamsAndSig sig) =>
			signatureMatchesTemplate(*x, sig));
		if (has(index)) {
			if (lateIsSet(res))
				add(alloc, diagsBuilder, UriAndDiagnostic(x.range, Diag(Diag.CommonFunDuplicate(name))));
			else
				lateSet(res, FunDeclAndSigIndex(x, force(index)));
		}
	}
	if (lateIsSet(res))
		return lateGet(res);
	else {
		FunDecl* decl = allocate(alloc, funDeclWithBody(
			FunDeclSource(FunDeclSource.Bogus(module_.uri, expectedSigs[0].typeParams)),
			Visibility.public_,
			name,
			expectedSigs[0].returnType,
			makeParams(alloc, expectedSigs[0].params),
			FunFlags.generatedBare,
			[],
			FunBody(FunBody.Bogus())));
		add(alloc, diagsBuilder, UriAndDiagnostic(
			UriAndRange(module_.uri, Range.empty),
			Diag(Diag.CommonFunMissing(decl, map(alloc, expectedSigs, (ref TypeParamsAndSig sig) =>
				TypeParamsAndSig(
					TypeParams(copyArray(alloc, sig.typeParams)),
					sig.returnType,
					copyParams(alloc, sig.params)))))));
		return FunDeclAndSigIndex(decl, 0);
	}
}

ParamsShort copyParams(ref Alloc alloc, in ParamsShort a) =>
	a.match!ParamsShort(
		(ParamShort[] x) =>
			ParamsShort(copyArray(alloc, x)),
		(ref ParamsShort.Variadic x) =>
			ParamsShort(allocate(alloc, x)));

immutable(FunDecl*[]) getFuns(ref Module a, Symbol name) {
	Opt!NameReferents optReferents = a.exports[name];
	return has(optReferents) ? force(optReferents).funs : [];
}

FunInst* instantiateNonTemplateFun(InstantiateCtx ctx, FunDecl* decl) =>
	instantiateFun(ctx, decl, emptyTypeArgs, emptySpecImpls);
