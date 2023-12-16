module frontend.check.getCommonFuns;

@safe @nogc pure nothrow:

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
import util.col.arr : isEmpty, sizeEq, small;
import util.col.arrBuilder : add, ArrBuilder, finishArr;
import util.col.arrUtil : arraysCorrespond, copyArray, filter, findIndex, makeArray, map;
import util.col.enumMap : EnumMap;
import util.late : late, Late, lateGet, lateIsSet, lateSet;
import util.memory : allocate;
import util.opt : force, has, none, Opt, some;
import util.sourceRange : Range, UriAndRange;
import util.sym : Sym, sym;
import util.util : castNonScope_ref, todo, unreachable;

enum CommonModule {
	bootstrap,
	alloc,
	exceptionLowLevel,
	funUtil,
	future,
	list,
	std,
	string_,
	runtime,
	runtimeMain,
}

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
	ArrBuilder!UriAndDiagnostic diagsBuilder;

	Type getType(CommonModule module_, Sym name) {
		return getNonTemplateType(alloc, ctx, diagsBuilder, *modules[module_], name);
	}
	Type instantiateType(StructDecl* decl, in Type[] typeArgs) {
		return Type(instantiateStructNeverDelay(ctx, decl, typeArgs));
	}
	FunDecl* getFunDeclInner(
		ref Module module_, Sym name, TypeParams typeParams, Type returnType, in ParamShort[] params,
	) {
		return getFunDecl(alloc, diagsBuilder, module_, name, TypeParamsAndSig(typeParams, returnType, params));
	}
	FunInst* getFunInner(ref Module module_, Sym name, Type returnType, in ParamShort[] params) {
		return instantiateNonTemplateFun(ctx, getFunDeclInner(module_, name, emptyTypeParams, returnType, params));
	}
	FunInst* getFun(CommonModule module_, Sym name, Type returnType, in ParamShort[] params) {
		return getFunInner(*modules[module_], name, returnType, params);
	}

	StructDecl* arrayDecl = getStructDeclOrAddDiag(
		alloc, diagsBuilder, *modules[CommonModule.bootstrap], sym!"array", 1);
	StructDecl* listDecl = getStructDeclOrAddDiag(alloc, diagsBuilder, *modules[CommonModule.list], sym!"list", 1);
	Type stringType = getType(CommonModule.string_, sym!"string");
	Type markCtxType = getType(CommonModule.alloc, sym!"mark-ctx");
	Type symbolType = getType(CommonModule.bootstrap, sym!"symbol");
	Type int32Type = Type(commonTypes.integrals.int32);
	Type nat8Type = Type(commonTypes.integrals.nat8);
	Type nat64Type = Type(commonTypes.integrals.nat64);
	Type nat64FutureType = instantiateType(commonTypes.future, [nat64Type]);
	Type voidType = Type(commonTypes.void_);
	Type stringListType = instantiateType(listDecl, [stringType]);
	Type nat8ConstPointerType = instantiateType(commonTypes.ptrConst, [nat8Type]);
	Type nat8MutPointerType = instantiateType(commonTypes.ptrMut, [nat8Type]);
	Type symbolArrayType = instantiateType(arrayDecl, [symbolType]);
	Type char8ArrayType = instantiateType(arrayDecl, [Type(commonTypes.char8)]);
	Type cStringType = instantiateType(commonTypes.ptrConst, [Type(commonTypes.char8)]);
	Type cStringConstPointerType = instantiateType(commonTypes.ptrConst, [cStringType]);
	Type mainPointerType = instantiateType(commonTypes.funPtrStruct, [nat64FutureType, stringListType]);

	FunInst* allocFun = getFun(CommonModule.alloc, sym!"alloc", nat8MutPointerType, [param!"size-bytes"(nat64Type)]);
	immutable FunDecl*[] funOrActSubscriptFunDecls =
		// TODO: check signatures
		getFunOrActSubscriptFuns(alloc, commonTypes, getFuns(*modules[CommonModule.funUtil], sym!"subscript"));
	FunInst* curExclusion =
		getFun(CommonModule.runtime, sym!"cur-exclusion", nat64Type, []);
	Opt!MainFun main = has(mainModule)
		? some(getMainFun(
			alloc, ctx, diagsBuilder, *force(mainModule), nat64FutureType, stringListType, voidType))
		: none!MainFun;
	FunInst* mark = getFun(
		CommonModule.alloc,
		sym!"mark",
		Type(commonTypes.bool_),
		[param!"ctx"(markCtxType), param!"pointer"(nat8ConstPointerType), param!"size-bytes"(nat64Type)]);

	scope ParamShort[] markVisitParams = [
		param!"mark-ctx"(markCtxType),
		param!"value"(singleTypeParamType),
	];
	FunDecl* markVisit = getFunDeclInner(
		*modules[CommonModule.alloc], sym!"mark-visit", singleTypeParams, voidType, castNonScope_ref(markVisitParams));
	scope ParamShort[] newTFutureParams = [param!"value"(singleTypeParamType)];
	Type tFuture = instantiateType(commonTypes.future, [singleTypeParamType]);
	FunDecl* newTFuture = getFunDeclInner(
		*modules[CommonModule.future], sym!"new", singleTypeParams, tFuture, castNonScope_ref(newTFutureParams));
	FunInst* newNat64Future = instantiateFun(ctx, newTFuture, small!Type([nat64Type]), emptySpecImpls);
	FunInst* rtMain = getFun(
		CommonModule.runtimeMain,
		sym!"rt-main",
		int32Type,
		[
			param!"argc"(int32Type),
			param!"argv"(cStringConstPointerType),
			param!"main"(mainPointerType),
		]);
	FunInst* staticSymbols =
		getFun(CommonModule.bootstrap, sym!"static-symbols", symbolArrayType, []);
	FunInst* throwImpl = getFun(
		CommonModule.exceptionLowLevel,
		sym!"throw-impl",
		voidType,
		[param!"message"(cStringType)]);
	FunInst* char8ArrayAsString = getFun(
		CommonModule.string_,
		sym!"as-string",
		stringType,
		[param!"a"(char8ArrayType)]);
	return CommonFunsAndMain(
		CommonFuns(
			finishArr(alloc, diagsBuilder),
			allocFun, funOrActSubscriptFunDecls, curExclusion, mark,
			markVisit, newNat64Future, rtMain, staticSymbols, throwImpl, char8ArrayAsString),
		main);
}

Destructure makeParam(ref Alloc alloc, Sym name, Type type) =>
	Destructure(allocate(alloc, Local(LocalSource(LocalSource.Generated()), name, LocalMutability.immut, type)));

Params makeParams(ref Alloc alloc, in ParamShort[] params) =>
	Params(map(alloc, params, (ref ParamShort x) =>
		makeParam(alloc, x.name, x.type)));

ParamShort param(string name)(Type type) =>
	ParamShort(sym!name, type);

private:

immutable NameAndRange[1] singleTypeParam = [NameAndRange(0, sym!"t")];
TypeParams singleTypeParams() => TypeParams(singleTypeParam);
Type singleTypeParamType() =>
	Type(TypeParamIndex(0));

immutable(FunDecl*[]) getFunOrActSubscriptFuns(
	ref Alloc alloc,
	in CommonTypes commonTypes,
	immutable FunDecl*[] subscripts,
) =>
	filter!(immutable FunDecl*)(alloc, subscripts, (in immutable FunDecl* x) {
		final switch (firstArgFunKind(commonTypes, x)) {
			case FunKind.fun:
			case FunKind.act:
				return true;
			case FunKind.far:
				return unreachable!bool;
			case FunKind.pointer:
				return false;
		}
	});

FunKind firstArgFunKind(in CommonTypes commonTypes, FunDecl* f) {
	Destructure[] params = assertNonVariadic(f.params);
	assert(!isEmpty(params));
	StructDecl* actual = params[0].type.as!(StructInst*).decl;
	foreach (FunKind kind; [FunKind.fun, FunKind.act, FunKind.pointer])
		if (actual == commonTypes.funStructs[kind])
			return kind;
	return unreachable!FunKind;
}

Type getNonTemplateType(
	ref Alloc alloc,
	ref InstantiateCtx ctx,
	scope ref ArrBuilder!UriAndDiagnostic diagsBuilder,
	ref Module module_,
	Sym name,
) {
	StructDecl* decl = getStructDeclOrAddDiag(alloc, diagsBuilder, module_, name, 0);
	if (decl.isTemplate)
		todo!void("diag");
	return Type(instantiateStructNeverDelay(ctx, decl, []));
}

StructDecl* getStructDeclOrAddDiag(
	ref Alloc alloc,
	scope ref ArrBuilder!UriAndDiagnostic diagsBuilder,
	ref Module module_,
	Sym name,
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
					NameAndRange(0, sym!"a")))))),
			module_.uri,
			name,
			Visibility.public_,
			Linkage.extern_,
			Purity.data,
			false,
			late(StructBody(StructBody.Bogus()))));
	}
}

Opt!(StructDecl*) getStructDecl(in Module a, Sym name) {
Opt!NameReferents optReferents = a.allExportedNames[name];
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
	scope ref ArrBuilder!UriAndDiagnostic diagsBuilder,
	ref Module module_,
	Sym name,
	in TypeParamsAndSig expectedSig,
) =>
	getFunDeclMulti(alloc, diagsBuilder, module_, name, [castNonScope_ref(expectedSig)]).decl;

MainFun getMainFun(
	ref Alloc alloc,
	ref InstantiateCtx ctx,
	scope ref ArrBuilder!UriAndDiagnostic diagsBuilder,
	ref Module mainModule,
	Type nat64FutureType,
	Type stringListType,
	Type voidType,
) {
	scope ParamShort[] params = [param!"args"(stringListType)];
	FunDeclAndSigIndex decl = getFunDeclMulti(alloc, diagsBuilder, mainModule, sym!"main", [
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
	scope ref ArrBuilder!UriAndDiagnostic diagsBuilder,
	ref Module module_,
	Sym name,
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

immutable(FunDecl*[]) getFuns(ref Module a, Sym name) {
	Opt!NameReferents optReferents = a.allExportedNames[name];
	return has(optReferents) ? force(optReferents).funs : [];
}

FunInst* instantiateNonTemplateFun(ref InstantiateCtx ctx, FunDecl* decl) =>
	instantiateFun(ctx, decl, emptyTypeArgs, emptySpecImpls);
