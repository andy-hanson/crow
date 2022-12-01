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
	FunDecl,
	FunInst,
	FunKind,
	isTemplate,
	Module,
	NameReferents,
	Param,
	Params,
	SpecDeclSig,
	StructInst,
	StructOrAlias,
	StructDecl,
	Type,
	TypeParam;
import util.alloc.alloc : Alloc;
import util.col.arr : empty;
import util.col.arrUtil : arrsCorrespond, mapWithIndex;
import util.col.enumDict : EnumDict;
import util.col.str : safeCStr;
import util.late : late, Late, lateGet, lateIsSet, lateSet;
import util.opt : force, has, none, Opt, some;
import util.ptr : castNonScope_ref;
import util.sourceRange : FileAndPos, FileAndRange, FileIndex, RangeWithinFile;
import util.sym : Sym, sym;
import util.util : unreachable, verify;

// Must be in dependency order (can only reference earlier)
enum CommonPath {
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

immutable(Opt!CommonFuns) getCommonFuns(
	ref Alloc alloc,
	ref ProgramState programState,
	ref DiagnosticsBuilder diagsBuilder,
	ref immutable CommonTypes commonTypes,
	immutable Opt!(Module*) mainModule,
	immutable EnumDict!(CommonPath, Module*) modules,
) {
	ref immutable(Module) getModule(immutable CommonPath path) =>
		*modules[path];
	immutable(Opt!Type) getType(immutable CommonPath module_, immutable Sym name) =>
		getNonTemplateType(alloc, programState, diagsBuilder, getModule(module_), name);
	immutable(Type) instantiateType(immutable StructDecl* decl, scope immutable Type[] typeArgs) =>
		immutable Type(instantiateStructNeverDelay(alloc, programState, decl, typeArgs));
	immutable(Opt!(FunInst*)) getFunInner(
		ref immutable Module module_,
		immutable Sym name,
		immutable Type returnType,
		scope immutable ParamShort[] params,
	) =>
		getCommonFunInst(alloc, programState, diagsBuilder, module_, name, returnType, params);
	immutable(Opt!(FunInst*)) getFun(
		immutable CommonPath module_,
		immutable Sym name,
		immutable Type returnType,
		scope immutable ParamShort[] params,
	) =>
		getFunInner(getModule(module_), name, returnType, params);

	immutable Opt!(StructDecl*) optArrayDecl =
		getStructDeclOrAddDiag(alloc, diagsBuilder, getModule(CommonPath.bootstrap), sym!"array");
	immutable Opt!(StructDecl*) optListDecl =
		getStructDeclOrAddDiag(alloc, diagsBuilder, getModule(CommonPath.list), sym!"list");
	immutable Opt!Type optStringType = getType(CommonPath.string_, sym!"string");
	immutable Opt!Type optMarkCtxType = getType(CommonPath.alloc, sym!"mark-ctx");
	immutable Opt!Type optSymbolType = getType(CommonPath.bootstrap, sym!"symbol");

	if (has(optListDecl) && has(optStringType) && has(optMarkCtxType)) {
		immutable StructDecl* arrayDecl = force(optArrayDecl);
		immutable StructDecl* listDecl = force(optListDecl);
		immutable Type stringType = force(optStringType);
		immutable Type markCtxType = force(optMarkCtxType);
		immutable Type symbolType = force(optSymbolType);

		immutable Type int32Type = immutable Type(commonTypes.integrals.int32);
		immutable Type nat8Type = immutable Type(commonTypes.integrals.nat8);
		immutable Type nat64Type = immutable Type(commonTypes.integrals.nat64);
		immutable Type nat64FutureType = instantiateType(commonTypes.future, [nat64Type]);
		immutable Type voidType = immutable Type(commonTypes.void_);
		immutable Type stringListType = instantiateType(listDecl, [stringType]);
		immutable Type nat8ConstPointerType = instantiateType(commonTypes.ptrConst, [nat8Type]);
		immutable Type nat8MutPointerType = instantiateType(commonTypes.ptrMut, [nat8Type]);
		immutable Type symbolArrayType = instantiateType(arrayDecl, [symbolType]);
		immutable Type cStringType = instantiateType(commonTypes.ptrConst, [immutable Type(commonTypes.char8)]);
		immutable Type cStringConstPointerType = instantiateType(commonTypes.ptrConst, [cStringType]);
		immutable Type mainPointerType =
			instantiateType(commonTypes.funPtrStructs[1], [nat64FutureType, stringListType]);

		immutable Opt!(FunInst*) allocFun =
			getFun(CommonPath.alloc, sym!"alloc", nat8MutPointerType, [param!"size-bytes"(nat64Type)]);
		immutable FunDecl*[] funOrActSubscriptFunDecls =
			// TODO: check signatures
			getFunOrActSubscriptFuns(commonTypes, getFuns(getModule(CommonPath.funUtil), sym!"subscript"));
		immutable Opt!(FunInst*) curExclusion =
			getFun(CommonPath.runtime, sym!"cur-exclusion", nat64Type, []);
		immutable Opt!(FunInst*) main = has(mainModule)
			? getFunInner(*force(mainModule), sym!"main", nat64FutureType, [param!"args"(stringListType)])
			: none!(FunInst*);
		immutable Opt!(FunInst*) mark = getFun(
			CommonPath.alloc,
			sym!"mark",
			immutable Type(commonTypes.bool_),
			[param!"ctx"(markCtxType), param!"pointer"(nat8ConstPointerType), param!"size-bytes"(nat64Type)]);

		immutable TypeParam[1] markVisitTypeParams = [
			immutable TypeParam(
				immutable FileAndRange(getModule(CommonPath.alloc).fileIndex, RangeWithinFile.empty),
				sym!"a",
				0),	
		];
		immutable Opt!(FunDecl*) markVisit = getCommonFunDecl(
			alloc,
			programState,
			diagsBuilder,
			getModule(CommonPath.alloc),
			sym!"mark-visit",
			markVisitTypeParams,
			voidType,
			[
				param!"mark-ctx"(markCtxType),
				param!"value"(immutable Type(&markVisitTypeParams[0])),
			]);
		immutable Opt!(FunInst*) rtMain = getFun(
			CommonPath.runtimeMain,
			sym!"rt-main",
			int32Type,
			[
				param!"argc"(int32Type),
				param!"argv"(cStringConstPointerType),
				param!"main"(mainPointerType),
			]);
		immutable Opt!(FunInst*) staticSymbols =
			getFun(CommonPath.bootstrap, sym!"static-symbols", symbolArrayType, []);
		immutable Opt!(FunInst*) throwImpl = getFun(
			CommonPath.exceptionLowLevel,
			sym!"throw-impl",
			voidType,
			[param!"message"(cStringType)]);

		return has(allocFun) &&
			has(curExclusion) &&
			has(main) &&
			has(mark) &&
			has(markVisit) &&
			has(rtMain) &&
			has(staticSymbols) &&
			has(throwImpl)
			? some(immutable CommonFuns(
				force(allocFun),
				funOrActSubscriptFunDecls,
				force(curExclusion),
				force(main),
				force(mark),
				force(markVisit),
				force(rtMain),
				force(staticSymbols),
				force(throwImpl)))
			: none!CommonFuns;
	} else
		return none!CommonFuns;
}

private:

immutable(FunDecl*[]) getFunOrActSubscriptFuns(ref immutable CommonTypes commonTypes, immutable FunDecl*[] subscripts) {
	size_t cutIndex = size_t.max;
	foreach (immutable size_t index, immutable FunDecl* f; subscripts)
		final switch (firstArgFunKind(commonTypes, f)) {
			case FunKind.fun:
			case FunKind.act:
				if (cutIndex == size_t.max) cutIndex = index;
				break;
			case FunKind.ref_:
				unreachable!void;
				break;
			case FunKind.pointer:
				// pointer subscript should all come first
				verify(cutIndex == size_t.max);
				break;
		}
	// Pointers always come first
	return subscripts[cutIndex .. $];
}

immutable(FunKind) firstArgFunKind(ref immutable CommonTypes commonTypes, immutable FunDecl* f) {
	immutable Param[] params = assertNonVariadic(f.params);
	verify(!empty(params));
	immutable StructDecl* actual = decl(*params[0].type.as!(StructInst*));
	foreach (immutable FunKind kind; [FunKind.fun, FunKind.act, FunKind.pointer])
		foreach (immutable StructDecl* decl; castNonScope_ref(commonTypes.funStructs)[kind])
			if (actual == decl)
				return kind;
	return unreachable!(immutable FunKind);
}

immutable(Opt!Type) getNonTemplateType(
	ref Alloc alloc,
	ref ProgramState programState,
	ref DiagnosticsBuilder diagsBuilder,
	ref immutable Module module_,
	immutable Sym name,
) {
	immutable Opt!(StructDecl*) decl = getStructDeclOrAddDiag(alloc, diagsBuilder, module_, name);
	return has(decl) && !isTemplate(*force(decl))
		? some(immutable Type(instantiateStructNeverDelay(alloc, programState, force(decl), [])))
		: none!Type;
}

immutable(Opt!(StructDecl*)) getStructDeclOrAddDiag(
	ref Alloc alloc,
	ref DiagnosticsBuilder diagsBuilder,
	ref immutable Module module_,
	immutable Sym name,
) {
	immutable Opt!(StructDecl*) res = getStructDecl(module_, name);
	if (!has(res))
		addDiagnostic(
			alloc,
			diagsBuilder,
			immutable FileAndRange(module_.fileIndex, RangeWithinFile.empty),
			immutable Diag(immutable Diag.CommonTypeMissing(name)));
	return res;
}

immutable(Opt!(StructDecl*)) getStructDecl(ref immutable Module a, immutable Sym name) {
	immutable Opt!NameReferents optReferents = a.allExportedNames[name];
	if (has(optReferents)) {
		immutable Opt!StructOrAlias sa = force(optReferents).structOrAlias;
		return has(sa) && force(sa).isA!(StructDecl*)
			? some(force(sa).as!(StructDecl*))
			: none!(StructDecl*);
	} else
		return none!(StructDecl*);
}

struct ParamShort {
	immutable Sym name;
	immutable Type type;
}
immutable(ParamShort) param(immutable string name)(immutable Type type) =>
	immutable ParamShort(sym!name, type);

immutable(bool) signatureMatchesTemplate(
	ref immutable FunDecl actual,
	scope immutable TypeParam[] expectedTypeParams,
	ref immutable SpecDeclSig expected,
) {
	if (!empty(actual.specs))
		return false;
	if (actual.params.isA!(Params.Varargs*))
		return false;
	
	if (actual.typeParams.length != expectedTypeParams.length)
		return false;
	immutable(bool) typesMatch(immutable Type actualType, immutable Type expectedType) {
		if (actualType.isA!(TypeParam*) && expectedType.isA!(TypeParam*)) {
			immutable TypeParam* actualTypeParam = actualType.as!(TypeParam*);
			immutable TypeParam* expectedTypeParam = expectedType.as!(TypeParam*);
			verify(&actual.typeParams[actualTypeParam.index] == actualTypeParam);
			verify(&expectedTypeParams[expectedTypeParam.index] == expectedTypeParam);
			return actualTypeParam.index == expectedTypeParam.index;
		} else
			return actualType == expectedType;
	}
	return typesMatch(actual.returnType, expected.returnType) &&
		arrsCorrespond!(Param, Param)(
			assertNonVariadic(actual.params),
			assertNonVariadic(expected.params),
			(ref immutable Param x, ref immutable Param y) =>
				typesMatch(x.type, y.type));
}

immutable(bool) signatureMatchesNonTemplate(ref immutable FunDecl actual, ref immutable SpecDeclSig expected) =>
	!isTemplate(actual) &&
		actual.returnType == expected.returnType &&
		actual.params.isA!(Param[]) &&
		arrsCorrespond!(Param, Param)(
			assertNonVariadic(actual.params),
			assertNonVariadic(expected.params),
			(ref immutable Param x, ref immutable Param y) =>
				x.type == y.type);

immutable(Opt!(FunDecl*)) getCommonFunDecl(
	ref Alloc alloc,
	ref ProgramState programState,
	ref DiagnosticsBuilder diagsBuilder,
	ref immutable Module module_,
	immutable Sym name,
	scope immutable TypeParam[] typeParams,
	immutable Type returnType,
	scope immutable ParamShort[] params,
) {
	immutable SpecDeclSig expectedSig = toSig(alloc, name, returnType, params);
	return getFunDecl(alloc, diagsBuilder, module_, expectedSig, (ref immutable FunDecl x) =>
		signatureMatchesTemplate(x, typeParams, expectedSig));
}

immutable(Opt!(FunInst*)) getCommonFunInst(
	ref Alloc alloc,
	ref ProgramState programState,
	ref DiagnosticsBuilder diagsBuilder,
	ref immutable Module module_,
	immutable Sym name,
	immutable Type returnType,
	scope immutable ParamShort[] params,
) {
	immutable SpecDeclSig expectedSig = toSig(alloc, name, returnType, params);
	immutable Opt!(FunDecl*) decl = getFunDecl(alloc, diagsBuilder, module_, expectedSig, (ref immutable FunDecl x) =>
		signatureMatchesNonTemplate(x, expectedSig));
	return has(decl)
		? some(instantiateNonTemplateFun(alloc, programState, force(decl)))
		: none!(FunInst*);
}

immutable(Opt!(FunDecl*)) getFunDecl(
	ref Alloc alloc,
	ref DiagnosticsBuilder diagsBuilder,
	ref immutable Module module_,
	immutable SpecDeclSig expectedSig,
	scope immutable(bool) delegate(ref immutable FunDecl) @safe @nogc pure nothrow isMatch,
) {
	Late!(immutable FunDecl*) res = late!(immutable FunDecl*)();
	foreach (immutable FunDecl* x; getFuns(module_, expectedSig.name)) {
		if (isMatch(*x)) {
			if (lateIsSet(res))
				addDiagnostic(alloc, diagsBuilder, x.range, immutable Diag(
					immutable Diag.CommonFunDuplicate(expectedSig.name)));
			else
				lateSet(res, x);
		}
	}
	if (lateIsSet(res))
		return some(lateGet(res));
	else {
		addDiagnostic(
			alloc,
			diagsBuilder,
			immutable FileAndRange(module_.fileIndex, RangeWithinFile.empty),
			immutable Diag(immutable Diag.CommonFunMissing(expectedSig)));
		return none!(FunDecl*);
	}
}

immutable(SpecDeclSig) toSig(
	ref Alloc alloc,
	immutable Sym name,
	immutable Type returnType,
	scope immutable ParamShort[] params,
) =>
	immutable SpecDeclSig(
		safeCStr!"",
		immutable FileAndPos(FileIndex.none, 0),
		name,
		returnType,
		// TODO: avoid alloc since this is temporary
		immutable Params(mapWithIndex(alloc, params, (immutable size_t index, ref immutable ParamShort x) =>
			immutable Param(
				immutable FileAndRange(FileIndex.none, RangeWithinFile.empty),
				some(x.name),
				x.type,
				index))));

immutable(FunDecl*[]) getFuns(ref immutable Module a, immutable Sym name) {
	immutable Opt!NameReferents optReferents = a.allExportedNames[name];
	return has(optReferents) ? force(optReferents).funs : [];
}

immutable(FunInst*) instantiateNonTemplateFun(
	ref Alloc alloc,
	ref ProgramState programState,
	immutable FunDecl* decl,
) =>
	instantiateFun(alloc, programState, decl, [], []);
