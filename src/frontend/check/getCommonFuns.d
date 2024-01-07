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
import util.col.array : arraysCorrespond, copyArray, filter, findIndex, isEmpty, makeArray, map, only, sizeEq, small;
import util.col.arrayBuilder : add, ArrayBuilder, finish;
import util.col.enumMap : EnumMap, enumMapMapValues;
import util.late : late, Late, lateGet, lateIsSet, lateSet;
import util.memory : allocate;
import util.opt : force, has, none, MutOpt, Opt, some, someMut;
import util.sourceRange : Range, UriAndRange;
import util.symbol : Symbol, symbol;
import util.util : castNonScope_ref, todo;

struct CommonFunsAndMain {
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

	Type getType(CommonModule module_, Symbol name) {
		return getNonTemplateType(alloc, ctx, diagsBuilder, *modules[module_], name);
	}
	Type instantiateType(StructDecl* decl, in Type[] typeArgs) {
		return Type(instantiateStructNeverDelay(ctx, decl, typeArgs));
	}
	FunDecl* getFunDeclInner(
		ref Module module_, Symbol name, TypeParams typeParams, Type returnType, in ParamShort[] params,
	) {
		return getFunDecl(alloc, diagsBuilder, module_, name, TypeParamsAndSig(typeParams, returnType, params));
	}
	FunInst* getFunInner(ref Module module_, Symbol name, Type returnType, in ParamShort[] params) {
		return instantiateNonTemplateFun(ctx, getFunDeclInner(module_, name, emptyTypeParams, returnType, params));
	}
	FunInst* getFun(CommonModule module_, Symbol name, Type returnType, in ParamShort[] params) {
		return getFunInner(*modules[module_], name, returnType, params);
	}

	StructDecl* arrayDecl = getStructDeclOrAddDiag(
		alloc, diagsBuilder, *modules[CommonModule.bootstrap], symbol!"array", 1);
	StructDecl* listDecl = getStructDeclOrAddDiag(alloc, diagsBuilder, *modules[CommonModule.list], symbol!"list", 1);
	Type stringType = getType(CommonModule.string_, symbol!"string");
	Type markCtxType = getType(CommonModule.alloc, symbol!"mark-ctx");
	Type int32Type = Type(commonTypes.integrals.int32);
	Type nat8Type = Type(commonTypes.integrals.nat8);
	Type nat64Type = Type(commonTypes.integrals.nat64);
	Type nat64FutureType = instantiateType(commonTypes.future, [nat64Type]);
	Type voidType = Type(commonTypes.void_);
	Type stringListType = instantiateType(listDecl, [stringType]);
	Type nat8ConstPointerType = instantiateType(commonTypes.ptrConst, [nat8Type]);
	Type nat8MutPointerType = instantiateType(commonTypes.ptrMut, [nat8Type]);
	Type char8ArrayType = instantiateType(arrayDecl, [Type(commonTypes.char8)]);
	Type cStringType = Type(commonTypes.cString);
	Type cStringConstPointerType = instantiateType(commonTypes.ptrConst, [cStringType]);
	Type mainPointerType = instantiateType(commonTypes.funPtrStruct, [nat64FutureType, stringListType]);

	FunInst* allocFun = getFun(CommonModule.alloc, symbol!"alloc", nat8MutPointerType, [param!"size-bytes"(nat64Type)]);
	immutable EnumMap!(FunKind, FunDecl*) lambdaSubscriptFuns = getLambdaSubscriptFuns(
		alloc, commonTypes, *modules[CommonModule.funUtil], *modules[CommonModule.future]);
	FunInst* curExclusion =
		getFun(CommonModule.runtime, symbol!"cur-exclusion", nat64Type, []);
	Opt!MainFun main = has(mainModule)
		? some(getMainFun(
			alloc, ctx, diagsBuilder, *force(mainModule), nat64FutureType, stringListType, voidType))
		: none!MainFun;
	FunInst* mark = getFun(
		CommonModule.alloc,
		symbol!"mark",
		Type(commonTypes.bool_),
		[param!"ctx"(markCtxType), param!"pointer"(nat8ConstPointerType), param!"size-bytes"(nat64Type)]);

	scope ParamShort[] markVisitParams = [
		param!"mark-ctx"(markCtxType),
		param!"value"(singleTypeParamType),
	];
	FunDecl* markVisit = getFunDeclInner(
		*modules[CommonModule.alloc], symbol!"mark-visit", singleTypeParams, voidType, markVisitParams);
	scope ParamShort[] newTFutureParams = [param!"value"(singleTypeParamType)];
	Type tFuture = instantiateType(commonTypes.future, [singleTypeParamType]);
	FunDecl* newTFuture = getFunDeclInner(
		*modules[CommonModule.future], symbol!"new", singleTypeParams, tFuture, newTFutureParams);
	FunInst* newNat64Future = instantiateFun(ctx, newTFuture, small!Type([nat64Type]), emptySpecImpls);
	FunInst* newVoidFuture = instantiateFun(ctx, newTFuture, small!Type([voidType]), emptySpecImpls);
	FunInst* rtMain = getFun(
		CommonModule.runtimeMain,
		symbol!"rt-main",
		int32Type,
		[
			param!"argc"(int32Type),
			param!"argv"(cStringConstPointerType),
			param!"main"(mainPointerType),
		]);
	FunInst* throwImpl = getFun(
		CommonModule.exceptionLowLevel,
		symbol!"throw-impl",
		voidType,
		[param!"message"(cStringType)]);
	FunInst* char8ArrayAsString = getFun(
		CommonModule.string_,
		symbol!"as-string",
		stringType,
		[param!"a"(char8ArrayType)]);
	return CommonFunsAndMain(
		CommonFuns(
			finish(alloc, diagsBuilder),
			allocFun, lambdaSubscriptFuns, curExclusion, mark,
			markVisit, newNat64Future, newVoidFuture, rtMain, throwImpl, char8ArrayAsString),
		main);
}

Destructure makeParam(ref Alloc alloc, Symbol name, Type type) =>
	Destructure(allocate(alloc, Local(LocalSource(LocalSource.Generated()), name, LocalMutability.immut, type)));

Params makeParams(ref Alloc alloc, in ParamShort[] params) =>
	Params(map(alloc, params, (ref ParamShort x) =>
		makeParam(alloc, x.name, x.type)));

ParamShort param(string name)(Type type) =>
	ParamShort(symbol!name, type);

private:

immutable NameAndRange[1] singleTypeParam = [NameAndRange(0, symbol!"t")];
TypeParams singleTypeParams() => TypeParams(singleTypeParam);
Type singleTypeParamType() =>
	Type(TypeParamIndex(0));

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
		final switch (funKind) {
			case FunKind.fun:
			case FunKind.act:
			case FunKind.pointer:
				assert(!has(res[funKind]));
				res[funKind] = someMut(x);
				break;
			case FunKind.far:
				assert(false);
		}
	}
	// TODO: check signature
	res[FunKind.far] = someMut(only(getFuns(future, symbol!"subscript")));
	return enumMapMapValues!(FunKind, FunDecl*, MutOpt!(FunDecl*))(res, (const MutOpt!(FunDecl*) x) => force(x));
}

FunKind firstArgFunKind(in CommonTypes commonTypes, FunDecl* f) {
	Destructure[] params = assertNonVariadic(f.params);
	assert(!isEmpty(params));
	StructDecl* actual = params[0].type.as!(StructInst*).decl;
	foreach (FunKind kind; [FunKind.fun, FunKind.act, FunKind.pointer])
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
	if (decl.isTemplate)
		todo!void("diag");
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
				TypeParams(makeArray!NameAndRange(alloc, nTypeParams, (size_t index) =>
					NameAndRange(0, symbol!"a")))))),
			module_.uri,
			name,
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
	isEmpty(actual.specs) &&
		!actual.params.isA!(Params.Varargs*) &&
		sizeEq(actual.typeParams, expected.typeParams) &&
		typesMatch(actual.returnType, actual.typeParams, expected.returnType, expected.typeParams) &&
		arraysCorrespond!(Destructure, ParamShort)(
			assertNonVariadic(actual.params),
			expected.params,
			(ref Destructure x, ref ParamShort y) =>
				typesMatch(x.type, actual.typeParams, y.type, expected.typeParams));

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
	scope ParamShort[] params = [param!"args"(stringListType)];
	FunDeclAndSigIndex decl = getFunDeclMulti(alloc, diagsBuilder, mainModule, symbol!"main", [
		TypeParamsAndSig(emptyTypeParams, voidType, []),
		TypeParamsAndSig(emptyTypeParams, nat64FutureType, castNonScope_ref(params))]);
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
					copyArray(alloc, sig.params)))))));
		return FunDeclAndSigIndex(decl, 0);
	}
}

immutable(FunDecl*[]) getFuns(ref Module a, Symbol name) {
	Opt!NameReferents optReferents = a.exports[name];
	return has(optReferents) ? force(optReferents).funs : [];
}

FunInst* instantiateNonTemplateFun(ref InstantiateCtx ctx, FunDecl* decl) =>
	instantiateFun(ctx, decl, emptyTypeArgs, emptySpecImpls);
