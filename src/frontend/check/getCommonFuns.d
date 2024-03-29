module frontend.check.getCommonFuns;

@safe @nogc pure nothrow:

import frontend.check.checkCtx : CommonModule;
import frontend.check.funsForStruct : funDeclWithBody;
import frontend.check.inferringType : typesAreCorrespondingStructInsts;
import frontend.check.instantiate : InstantiateCtx, instantiateFun, instantiateStructNeverDelay;
import model.ast : NameAndRange;
import model.diag : Diag, UriAndDiagnostic;
import model.model :
	assertNonVariadic,
	CommonFuns,
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
	Linkage,
	Local,
	LocalMutability,
	LocalSource,
	MainFun,
	Module,
	NameReferents,
	Params,
	ParamShort,
	ParamsShort,
	Purity,
	StructBody,
	StructInst,
	StructOrAlias,
	StructDecl,
	StructDeclSource,
	Type,
	TypeParamIndex,
	TypeParams,
	TypeParamsAndSig,
	Visibility;
import util.alloc.alloc : Alloc;
import util.col.array :
	arraysCorrespond, copyArray, emptySmallArray, findIndex, isEmpty, makeArray, map, sizeEq, small, SmallArray;
import util.col.arrayBuilder : add, ArrayBuilder, smallFinish;
import util.col.enumMap : EnumMap, enumMapMapValues;
import util.late : late, Late, lateGet, lateIsSet, lateSet;
import util.memory : allocate;
import util.opt : force, has, none, MutOpt, Opt, some, someMut;
import util.sourceRange : Range, UriAndRange;
import util.symbol : Symbol, symbol;
import util.util : castNonScope_ref;

struct CommonFunsAndMain {
	SmallArray!UriAndDiagnostic diagnostics;
	CommonFuns commonFuns;
	Opt!MainFun mainFun;
}

CommonFunsAndMain getCommonFuns(
	ref Alloc alloc,
	InstantiateCtx ctx,
	ref CommonTypes commonTypes,
	in EnumMap!(CommonModule, Module*) modules,
	Opt!(Module*) mainModule,
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

	StructDecl* arrayDecl = getStructDeclOrAddDiag(
		alloc, diagsBuilder, *modules[CommonModule.bootstrap], symbol!"array", 1);
	StructDecl* listDecl = getStructDeclOrAddDiag(alloc, diagsBuilder, *modules[CommonModule.list], symbol!"list", 1);
	StructDecl* tuple2Decl = getStructDeclOrAddDiag(
		alloc, diagsBuilder, *modules[CommonModule.bootstrap], symbol!"tuple2", 2);
	Type markCtxType = getType(CommonModule.alloc, symbol!"mark-ctx");
	Type boolType = Type(commonTypes.bool_);
	Type int32Type = Type(commonTypes.integrals.int32);
	Type nat8Type = Type(commonTypes.integrals.nat8);
	Type nat64Type = Type(commonTypes.integrals.nat64);
	Type nat64FutureType = instantiateType(commonTypes.future, [nat64Type]);
	Type voidType = Type(commonTypes.void_);
	Type stringType = Type(commonTypes.string_);
	Type stringListType = instantiateType(listDecl, [stringType]);
	Type nat8ConstPointerType = instantiateType(commonTypes.ptrConst, [nat8Type]);
	Type nat8MutPointerType = instantiateType(commonTypes.ptrMut, [nat8Type]);
	Type char8ArrayType = instantiateType(arrayDecl, [Type(commonTypes.char8)]);
	Type cStringType = Type(commonTypes.cString);
	Type cStringConstPointerType = instantiateType(commonTypes.ptrConst, [cStringType]);
	Type mainPointerType = instantiateType(commonTypes.funPtrStruct, [nat64FutureType, stringListType]);
	Type jsonType = getType(CommonModule.json, symbol!"json");

	scope ParamShort[] newTFutureParams = [param!"value"(typeParam0)];
	Type tFuture = instantiateType(commonTypes.future, [typeParam0]);
	Type tList = instantiateType(commonTypes.list, [typeParam0]);
	Type tArray = instantiateType(commonTypes.array, [typeParam0]);

	Type rFutureSharedOfP = instantiateType(commonTypes.funStructs[FunKind.shared_], [tFuture, typeParam1]);
	Type rFutureMutOfP = instantiateType(commonTypes.funStructs[FunKind.mut], [tFuture, typeParam1]);
	Type symbolType = Type(commonTypes.symbol);
	Type symbolJsonTuple = instantiateType(tuple2Decl, [symbolType, jsonType]);
	Type symbolJsonTupleArray = instantiateType(arrayDecl, [symbolJsonTuple]);
	ParamsShort.Variadic newJsonPairsParams = ParamsShort.Variadic(
		param!"pairs"(symbolJsonTupleArray), symbolJsonTuple);
	ParamsShort.Variadic newTListParams = ParamsShort.Variadic(
		param!"value"(tArray), typeParam0);
	CommonFuns commonFuns = CommonFuns(
		alloc: getFun(CommonModule.alloc, symbol!"alloc", nat8MutPointerType, [param!"size-bytes"(nat64Type)]),
		and: getFun(CommonModule.boolLowLevel, symbol!"&&", boolType, [param!"a"(boolType), param!"b"(boolType)]),
		lambdaSubscript: getLambdaSubscriptFuns(
			alloc, commonTypes, *modules[CommonModule.funUtil], *modules[CommonModule.future]),
		sharedOfMutLambda: getFunDeclInner(
			*modules[CommonModule.future],
			symbol!"shared-of-mut-lambda",
			twoTypeParams,
			rFutureSharedOfP,
			[param!"a"(rFutureMutOfP)],
			countSpecs: 2),
		mark: getFun(
			CommonModule.alloc,
			symbol!"mark",
			Type(commonTypes.bool_),
			[param!"ctx"(markCtxType), param!"pointer"(nat8ConstPointerType), param!"size-bytes"(nat64Type)]),
		newJsonFromPairs: instantiateNonTemplateFun(ctx, getFunDecl(
			alloc, diagsBuilder, *modules[CommonModule.json], symbol!"new",
			TypeParamsAndSig(emptyTypeParams, jsonType, ParamsShort(&newJsonPairsParams), countSpecs: 0))),
		newTFuture: getFunDeclInner(
			*modules[CommonModule.future],
			symbol!"new", singleTypeParams, tFuture, newTFutureParams, countSpecs: 0),
		newTList: getFunDecl(
			alloc, diagsBuilder, *modules[CommonModule.list], symbol!"new",
			TypeParamsAndSig(singleTypeParams, tList, ParamsShort(&newTListParams), countSpecs: 0)),
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
			[param!"message"(stringType)]),
		char8ArrayTrustAsString: getFun(
			CommonModule.string_,
			symbol!"trust-as-string",
			stringType,
			[param!"a"(char8ArrayType)]),
		equalNat64: getFun(
			CommonModule.numberLowLevel,
			symbol!"==",
			boolType,
			[param!"a"(nat64Type), param!"b"(nat64Type)]),
		lessNat64: getFun(
			CommonModule.numberLowLevel, symbol!"is-less", boolType, [param!"a"(nat64Type), param!"b"(nat64Type)]));
	Opt!MainFun main = has(mainModule)
		? some(getMainFun(alloc, ctx, diagsBuilder, *force(mainModule), nat64FutureType, stringListType, voidType))
		: none!MainFun;
	return CommonFunsAndMain(smallFinish(alloc, diagsBuilder), commonFuns, main);
}

Destructure makeParam(ref Alloc alloc, ParamShort param) =>
	Destructure(allocate(alloc, Local(
		LocalSource(allocate(alloc, LocalSource.Generated(param.name))), LocalMutability.immut, param.type)));

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

immutable NameAndRange[1] singleTypeParamsArray = [NameAndRange(0, symbol!"t")];
TypeParams singleTypeParams() => TypeParams(singleTypeParamsArray);
immutable NameAndRange[2] twoTypeParamsArray = [NameAndRange(0, symbol!"r"), NameAndRange(0, symbol!"p")];
TypeParams twoTypeParams() => TypeParams(twoTypeParamsArray);
Type typeParam0() => Type(TypeParamIndex(0));
Type typeParam1() => Type(TypeParamIndex(1));

immutable(EnumMap!(FunKind, FunDecl*)) getLambdaSubscriptFuns(
	ref Alloc alloc,
	in CommonTypes commonTypes,
	in Module funUtil,
	in Module future,
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
	ref InstantiateCtx ctx,
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
		return allocate(alloc, StructDecl(
			StructDeclSource(allocate(alloc, StructDeclSource.Bogus(
				name,
				TypeParams(makeArray!NameAndRange(alloc, nTypeParams, (size_t index) =>
					NameAndRange(0, symbol!"a")))))),
			module_.uri,
			Visibility.public_,
			Linkage.extern_,
			Purity.data,
			false,
			late(StructBody(StructBody.Bogus()))));
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
	ref InstantiateCtx ctx,
	scope ref ArrayBuilder!UriAndDiagnostic diagsBuilder,
	ref Module mainModule,
	Type nat64FutureType,
	Type stringListType,
	Type voidType,
) {
	scope ParamShort[] argsParamsInner = [param!"args"(stringListType)];
	ParamsShort argsParams = ParamsShort(small!ParamShort(castNonScope_ref(argsParamsInner)));
	FunDeclAndSigIndex decl = getFunDeclMulti(alloc, diagsBuilder, mainModule, symbol!"main", [
		TypeParamsAndSig(emptyTypeParams, voidType, ParamsShort(emptySmallArray!ParamShort), countSpecs: 0),
		TypeParamsAndSig(emptyTypeParams, nat64FutureType, argsParams, countSpecs: 0)]);
	FunInst* inst = instantiateNonTemplateFun(ctx, decl.decl);
	final switch (decl.sigIndex) {
		case 0:
			return MainFun(MainFun.Void(stringListType.as!(StructInst*), inst));
		case 1:
			return MainFun(MainFun.Nat64Future(inst));
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

FunInst* instantiateNonTemplateFun(ref InstantiateCtx ctx, FunDecl* decl) =>
	instantiateFun(ctx, decl, emptyTypeArgs, emptySpecImpls);
