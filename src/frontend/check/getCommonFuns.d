module frontend.check.getCommonFuns;

@safe @nogc pure nothrow:

import frontend.check.instantiate : instantiateFun, instantiateStructNeverDelay;
import frontend.diagnosticsBuilder : addDiagnostic, DiagnosticsBuilder;
import frontend.programState : ProgramState;
import model.diag : Diag;
import model.model :
	assertNonVariadic,
	CommonFuns,
	CommonTypes,
	decl,
	Destructure,
	FunBody,
	FunDecl,
	FunFlags,
	FunInst,
	FunKind,
	isTemplate,
	Linkage,
	Local,
	LocalMutability,
	Module,
	NameReferents,
	Params,
	Purity,
	SpecDeclSig,
	StructBody,
	StructInst,
	StructOrAlias,
	StructDecl,
	Type,
	TypeParam,
	Visibility;
import util.alloc.alloc : Alloc;
import util.col.arr : empty, small;
import util.col.arrUtil : arrsCorrespond, filter, makeArr, map;
import util.col.enumMap : EnumMap;
import util.col.str : safeCStr;
import util.late : late, Late, lateGet, lateIsSet, lateSet;
import util.memory : allocate;
import util.opt : force, has, none, Opt, some;
import util.sourceRange : FileAndPos, FileAndRange, FileIndex, RangeWithinFile;
import util.sym : Sym, sym;
import util.util : todo, unreachable, verify;

// Must be in dependency order (can only reference earlier)
alias CommonPath = immutable CommonPath_;
private enum CommonPath_ {
	bootstrap,
	alloc,
	exceptionLowLevel,
	funUtil,
	list,
	std,
	string_,
	runtime,
	runtimeMain,
}

CommonFuns getCommonFuns(
	ref Alloc alloc,
	ref ProgramState programState,
	scope ref DiagnosticsBuilder diagsBuilder,
	ref CommonTypes commonTypes,
	Opt!(Module*) mainModule,
	ref immutable EnumMap!(CommonPath, Module*) modules,
) {
	ref Module getModule(CommonPath path) {
		return *modules[path];
	}
	Type getType(CommonPath module_, Sym name) {
		return getNonTemplateType(alloc, programState, diagsBuilder, getModule(module_), name);
	}
	Type instantiateType(StructDecl* decl, in Type[] typeArgs) {
		return Type(instantiateStructNeverDelay(alloc, programState, decl, typeArgs));
	}
	FunInst* getFunInner(ref Module module_, Sym name, Type returnType, in ParamShort[] params) {
		return getCommonFunInst(alloc, programState, diagsBuilder, module_, name, returnType, params);
	}
	FunInst* getFun(CommonPath module_, Sym name, Type returnType, in ParamShort[] params) {
		return getFunInner(getModule(module_), name, returnType, params);
	}

	StructDecl* arrayDecl = getStructDeclOrAddDiag(
		alloc, diagsBuilder, getModule(CommonPath.bootstrap), sym!"array", 1);
	StructDecl* listDecl = getStructDeclOrAddDiag(alloc, diagsBuilder, getModule(CommonPath.list), sym!"list", 1);
	Type stringType = getType(CommonPath.string_, sym!"string");
	Type markCtxType = getType(CommonPath.alloc, sym!"mark-ctx");
	Type symbolType = getType(CommonPath.bootstrap, sym!"symbol");
	Type int32Type = Type(commonTypes.integrals.int32);
	Type nat8Type = Type(commonTypes.integrals.nat8);
	Type nat64Type = Type(commonTypes.integrals.nat64);
	Type nat64FutureType = instantiateType(commonTypes.future, [nat64Type]);
	Type voidType = Type(commonTypes.void_);
	Type stringListType = instantiateType(listDecl, [stringType]);
	Type nat8ConstPointerType = instantiateType(commonTypes.ptrConst, [nat8Type]);
	Type nat8MutPointerType = instantiateType(commonTypes.ptrMut, [nat8Type]);
	Type symbolArrayType = instantiateType(arrayDecl, [symbolType]);
	Type cStringType = instantiateType(commonTypes.ptrConst, [Type(commonTypes.char8)]);
	Type cStringConstPointerType = instantiateType(commonTypes.ptrConst, [cStringType]);
	Type mainPointerType = instantiateType(commonTypes.funPtrStruct, [nat64FutureType, stringListType]);

	FunInst* allocFun = getFun(CommonPath.alloc, sym!"alloc", nat8MutPointerType, [param!"size-bytes"(nat64Type)]);
	immutable FunDecl*[] funOrActSubscriptFunDecls =
		// TODO: check signatures
		getFunOrActSubscriptFuns(alloc, commonTypes, getFuns(getModule(CommonPath.funUtil), sym!"subscript"));
	FunInst* curExclusion =
		getFun(CommonPath.runtime, sym!"cur-exclusion", nat64Type, []);
	Opt!(FunInst*) main = has(mainModule)
		? some(getFunInner(*force(mainModule), sym!"main", nat64FutureType, [param!"args"(stringListType)]))
		: none!(FunInst*);
	FunInst* mark = getFun(
		CommonPath.alloc,
		sym!"mark",
		Type(commonTypes.bool_),
		[param!"ctx"(markCtxType), param!"pointer"(nat8ConstPointerType), param!"size-bytes"(nat64Type)]);

	TypeParam[1] markVisitTypeParams = [
		TypeParam(FileAndRange(getModule(CommonPath.alloc).fileIndex, RangeWithinFile.empty), sym!"a", 0),
	];
	FunDecl* markVisit = getCommonFunDecl(
		alloc,
		programState,
		diagsBuilder,
		getModule(CommonPath.alloc),
		sym!"mark-visit",
		markVisitTypeParams,
		voidType,
		[
			param!"mark-ctx"(markCtxType),
			param!"value"(Type(&markVisitTypeParams[0])),
		]);
	FunInst* rtMain = getFun(
		CommonPath.runtimeMain,
		sym!"rt-main",
		int32Type,
		[
			param!"argc"(int32Type),
			param!"argv"(cStringConstPointerType),
			param!"main"(mainPointerType),
		]);
	FunInst* staticSymbols =
		getFun(CommonPath.bootstrap, sym!"static-symbols", symbolArrayType, []);
	FunInst* throwImpl = getFun(
		CommonPath.exceptionLowLevel,
		sym!"throw-impl",
		voidType,
		[param!"message"(cStringType)]);
	return CommonFuns(
		allocFun, funOrActSubscriptFunDecls, curExclusion, main, mark, markVisit, rtMain, staticSymbols, throwImpl);
}

Destructure makeParam(ref Alloc alloc, FileAndRange range, Sym name, Type type) =>
	Destructure(allocate(alloc, Local(range, name, LocalMutability.immut, type)));

Params makeParams(ref Alloc alloc, FileAndRange range, in ParamShort[] params) =>
	Params(makeParamDestructures(alloc, range, params));

private Destructure[] makeParamDestructures(ref Alloc alloc, FileAndRange range, in ParamShort[] params) =>
	map(alloc, params, (ref ParamShort x) =>
		makeParam(alloc, range, x.name, x.type));

immutable struct ParamShort {
	Sym name;
	Type type;
}
ParamShort param(string name)(Type type) =>
	ParamShort(sym!name, type);

private:

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
	verify(!empty(params));
	StructDecl* actual = decl(*params[0].type.as!(StructInst*));
	foreach (FunKind kind; [FunKind.fun, FunKind.act, FunKind.pointer])
		if (actual == commonTypes.funStructs[kind])
			return kind;
	return unreachable!FunKind;
}

Type getNonTemplateType(
	ref Alloc alloc,
	ref ProgramState programState,
	scope ref DiagnosticsBuilder diagsBuilder,
	ref Module module_,
	Sym name,
) {
	StructDecl* decl = getStructDeclOrAddDiag(alloc, diagsBuilder, module_, name, 0);
	if (isTemplate(*decl))
		todo!void("diag");
	return Type(instantiateStructNeverDelay(alloc, programState, decl, []));
}

StructDecl* getStructDeclOrAddDiag(
	ref Alloc alloc,
	scope ref DiagnosticsBuilder diagsBuilder,
	ref Module module_,
	Sym name,
	size_t nTypeParams,
) {
	Opt!(StructDecl*) res = getStructDecl(module_, name);
	if (has(res) && force(res).typeParams.length == nTypeParams)
		return force(res);
	else {
		addDiagnostic(
			alloc,
			diagsBuilder,
			FileAndRange(module_.fileIndex, RangeWithinFile.empty),
			Diag(Diag.CommonTypeMissing(name)));
		return allocate(alloc, StructDecl(
			FileAndRange.empty,
			safeCStr!"",
			name,
			small(makeArr!TypeParam(alloc, nTypeParams, (size_t idx) =>
				TypeParam(FileAndRange.empty, sym!"a", 0))),
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

bool signatureMatchesTemplate(
	in FunDecl actual,
	in TypeParam[] expectedTypeParams,
	in SpecDeclSig expected,
) {
	if (!empty(actual.specs))
		return false;
	if (actual.params.isA!(Params.Varargs*))
		return false;

	if (actual.typeParams.length != expectedTypeParams.length)
		return false;
	bool typesMatch(in Type actualType, in Type expectedType) {
		if (actualType.isA!(TypeParam*) && expectedType.isA!(TypeParam*)) {
			TypeParam* actualTypeParam = actualType.as!(TypeParam*);
			TypeParam* expectedTypeParam = expectedType.as!(TypeParam*);
			verify(&actual.typeParams[actualTypeParam.index] == actualTypeParam);
			verify(&expectedTypeParams[expectedTypeParam.index] == expectedTypeParam);
			return actualTypeParam.index == expectedTypeParam.index;
		} else
			return actualType == expectedType;
	}
	return typesMatch(actual.returnType, expected.returnType) &&
		arrsCorrespond!(Destructure, Destructure)(
			assertNonVariadic(actual.params),
			expected.params,
			(in Destructure x, in Destructure y) =>
				typesMatch(x.type, y.type));
}

bool signatureMatchesNonTemplate(ref FunDecl actual, ref SpecDeclSig expected) =>
	!isTemplate(actual) &&
		actual.returnType == expected.returnType &&
		actual.params.isA!(Destructure[]) &&
		arrsCorrespond!(Destructure, Destructure)(
			assertNonVariadic(actual.params),
			expected.params,
			(in Destructure x, in Destructure y) =>
				x.type == y.type);

FunDecl* getCommonFunDecl(
	ref Alloc alloc,
	ref ProgramState programState,
	scope ref DiagnosticsBuilder diagsBuilder,
	ref Module module_,
	Sym name,
	in TypeParam[] typeParams,
	Type returnType,
	in ParamShort[] params,
) {
	SpecDeclSig expectedSig = toSig(alloc, name, returnType, params);
	return getFunDecl(alloc, diagsBuilder, module_, expectedSig, (ref FunDecl x) =>
		signatureMatchesTemplate(x, typeParams, expectedSig));
}

FunInst* getCommonFunInst(
	ref Alloc alloc,
	ref ProgramState programState,
	scope ref DiagnosticsBuilder diagsBuilder,
	ref Module module_,
	Sym name,
	Type returnType,
	in ParamShort[] params,
) {
	SpecDeclSig expectedSig = toSig(alloc, name, returnType, params);
	FunDecl* decl = getFunDecl(alloc, diagsBuilder, module_, expectedSig, (ref FunDecl x) =>
		signatureMatchesNonTemplate(x, expectedSig));
	return instantiateNonTemplateFun(alloc, programState, decl);
}

FunDecl* getFunDecl(
	ref Alloc alloc,
	scope ref DiagnosticsBuilder diagsBuilder,
	ref Module module_,
	SpecDeclSig expectedSig,
	in bool delegate(ref FunDecl) @safe @nogc pure nothrow isMatch,
) {
	Late!(FunDecl*) res = late!(FunDecl*)();
	foreach (FunDecl* x; getFuns(module_, expectedSig.name)) {
		if (isMatch(*x)) {
			if (lateIsSet(res))
				addDiagnostic(alloc, diagsBuilder, x.range, Diag(Diag.CommonFunDuplicate(expectedSig.name)));
			else
				lateSet(res, x);
		}
	}
	if (lateIsSet(res))
		return lateGet(res);
	else {
		addDiagnostic(
			alloc,
			diagsBuilder,
			FileAndRange(module_.fileIndex, RangeWithinFile.empty),
			Diag(Diag.CommonFunMissing(expectedSig)));
		return allocate(alloc, FunDecl(
			safeCStr!"",
			Visibility.public_,
			FileAndPos.empty,
			expectedSig.name,
			[],
			expectedSig.returnType,
			Params(expectedSig.params),
			FunFlags.generatedBare,
			[],
			FunBody(FunBody.Bogus())));
	}
}

SpecDeclSig toSig(ref Alloc alloc, Sym name, Type returnType, in ParamShort[] params) =>
	SpecDeclSig(
		safeCStr!"",
		FileAndPos(FileIndex.none, 0),
		name,
		returnType,
		// TODO: avoid alloc since this is temporary
		small(makeParamDestructures(alloc, FileAndRange.empty, params)));

immutable(FunDecl*[]) getFuns(ref Module a, Sym name) {
	Opt!NameReferents optReferents = a.allExportedNames[name];
	return has(optReferents) ? force(optReferents).funs : [];
}

FunInst* instantiateNonTemplateFun(ref Alloc alloc, ref ProgramState programState, FunDecl* decl) =>
	instantiateFun(alloc, programState, decl, [], []);
