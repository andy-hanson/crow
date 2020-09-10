module frontend.check;

@safe @nogc pure nothrow:

import frontend.ast :
	ExplicitByValOrRef,
	ExprAst,
	FileAst,
	FunBodyAst,
	FunDeclAst,
	matchFunBodyAst,
	matchSpecBodyAst,
	matchStructDeclAstBody,
	matchTypeAst,
	ParamAst,
	PuritySpecifier,
	SigAst,
	SpecBodyAst,
	SpecDeclAst,
	SpecUseAst,
	StructAliasAst,
	StructDeclAst,
	TypeAst,
	TypeParamAst;
import frontend.checkCtx : addDiag, CheckCtx, diags, hasDiags;
import frontend.checkExpr : checkFunctionBody;
import frontend.checkUtil : arrAsImmutable, ptrAsImmutable;
import frontend.instantiate :
	DelayStructInsts,
	instantiateSpec,
	instantiateStruct,
	instantiateStructBody,
	TypeParamsScope;
import frontend.programState : ProgramState;
import frontend.typeFromAst : instStructFromAst, tryFindSpec, typeArgsFromAsts, typeFromAst;

import diag : Diag, Diagnostic, Diags, PathAndStorageKindAndRange, TypeKind;

import model :
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
	isPurityWorse,
	isRecord,
	isUnion,
	matchStructBody,
	matchStructOrAlias,
	Module,
	name,
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
import util.collection.arr : Arr, at, empty, emptyArr, ptrsRange, range, size, sizeEq;
import util.collection.arrBuilder : add, ArrBuilder, arrBuilderAsTempArr, arrBuilderSize, finishArr;
import util.collection.arrUtil :
	arrLiteral,
	contains,
	exists,
	map,
	mapOp,
	mapOrNone,
	mapToMut,
	mapWithIndex,
	zip,
	zipFirstMut,
	zipMutPtrFirst;
import util.collection.dict : getAt, KeyValuePair;
import util.collection.dictBuilder : addToDict, DictBuilder, finishDict;
import util.collection.dictUtil : buildDict, buildMultiDict;
import util.collection.mutArr : mustPop, MutArr, mutArrIsEmpty, mutArrRangeMut;
import util.collection.str : copyStr, Str, strLiteral;
import util.memory : DelayInit, delayInit;
import util.opt : force, has, mapOption, none, noneMut, Opt, some, someMut;
import util.path : PathAndStorageKind;
import util.ptr : Ptr, ptrEquals, ptrTrustMe, ptrTrustMe_mut;
import util.result : fail, flatMapSuccess, mapSuccess, Result, success;
import util.sourceRange : SourceRange;
import util.sym : addToMutSymSetOkIfPresent, compareSym, shortSymAlphaLiteral, shortSymAlphaLiteralValue, Sym, symEq;
import util.util : todo;

struct PathAndAst {
	immutable PathAndStorageKind pathAndStorageKind;
	immutable FileAst ast;
}

struct BootstrapCheck {
	immutable Ptr!Module module_;
	immutable CommonTypes commonTypes;
}

immutable(Result!(BootstrapCheck, Diags)) checkBootstrapNz(Alloc)(
	ref Alloc alloc,
	ref ProgramState programState,
	immutable PathAndAst pathAndAst,
) {
	assert(empty(pathAndAst.ast.imports) && empty(pathAndAst.ast.exports));
	return checkWorker(
		alloc,
		programState,
		emptyArr!(Ptr!Module),
		emptyArr!(Ptr!Module),
		pathAndAst,
		(ref CheckCtx ctx,
		ref immutable StructsAndAliasesMap structsAndAliasesMap,
		ref MutArr!(Ptr!StructInst) delayedStructInsts) =>
			getCommonTypes(alloc, ctx, structsAndAliasesMap, delayedStructInsts));
}

immutable(Result!(Ptr!Module, Diags)) check(Alloc)(
	ref Alloc alloc,
	ref ProgramState programState,
	ref immutable Arr!(Ptr!Module) imports,
	ref immutable Arr!(Ptr!Module) exports,
	immutable PathAndAst pathAndAst,
	immutable CommonTypes commonTypes,
) {
	immutable Result!(BootstrapCheck, Diags) res = checkWorker(
		alloc,
		programState,
		imports,
		exports,
		pathAndAst,
		(ref CheckCtx, ref immutable StructsAndAliasesMap, ref MutArr!(Ptr!StructInst)) =>
			success!(CommonTypes, Diags)(commonTypes));
	return mapSuccess(res, (ref immutable BootstrapCheck ic) => ic.module_);
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
	if (!has(opStructOrAlias))
		return none!(Ptr!StructInst);
	else {
		immutable StructOrAlias structOrAlias = force(opStructOrAlias);
		assert(empty(typeParams(structOrAlias)));
		return matchStructOrAlias(
			structOrAlias,
			(immutable Ptr!StructAlias a) => target(a),
			(immutable Ptr!StructDecl s) =>
				some(instantiateStruct(
					alloc,
					ctx.programState,
					immutable StructDeclAndArgs(s, emptyArr!Type),
					someMut(ptrTrustMe_mut(delayedStructInsts)))));
	}
}

immutable(Result!(CommonTypes, Diags)) getCommonTypes(Alloc)(
	ref Alloc alloc,
	ref CheckCtx ctx,
	ref immutable StructsAndAliasesMap structsAndAliasesMap,
	ref MutArr!(Ptr!StructInst) delayedStructInsts,
) {
	ArrBuilder!Str missing = ArrBuilder!Str();

	immutable(Opt!(Ptr!StructInst)) nonTemplate(immutable string name) {
		immutable Opt!(Ptr!StructInst) res = getCommonNonTemplateType(
			alloc,
			ctx,
			structsAndAliasesMap,
			shortSymAlphaLiteral(name),
			delayedStructInsts);
		if (!has(res))
			add(alloc, missing, strLiteral(name));
		return res;
	}

	immutable Opt!(Ptr!StructInst) bool_ = nonTemplate("bool");
	immutable Opt!(Ptr!StructInst) char_ = nonTemplate("char");
	immutable Opt!(Ptr!StructInst) int32 = nonTemplate("int32");
	immutable Opt!(Ptr!StructInst) str = nonTemplate("str");
	immutable Opt!(Ptr!StructInst) void_ = nonTemplate("void");
	immutable Opt!(Ptr!StructInst) anyPtr = nonTemplate("any-ptr");

	immutable(Opt!(Ptr!StructDecl)) com(immutable string name, immutable size_t nTypeParameters) {
		immutable Opt!(Ptr!StructDecl) res = getCommonTemplateType(
			structsAndAliasesMap,
			shortSymAlphaLiteral(name),
			nTypeParameters);
		if (!has(res))
			add(alloc, missing, strLiteral(name));
		return res;
	}

	immutable Opt!(Ptr!StructDecl) opt = com("opt", 1);
	immutable Opt!(Ptr!StructDecl) some = com("some", 1);
	immutable Opt!(Ptr!StructDecl) none = com("none", 0);
	immutable Opt!(Ptr!StructDecl) byVal = com("by-val", 1);
	immutable Opt!(Ptr!StructDecl) arr = com("arr", 1);
	immutable Opt!(Ptr!StructDecl) fut = com("fut", 1);
	immutable Opt!(Ptr!StructDecl) fun0 = com("fun0", 1);
	immutable Opt!(Ptr!StructDecl) fun1 = com("fun1", 2);
	immutable Opt!(Ptr!StructDecl) fun2 = com("fun2", 3);
	immutable Opt!(Ptr!StructDecl) fun3 = com("fun3", 4);
	immutable Opt!(Ptr!StructDecl) funMut0 = com("fun-mut0", 1);
	immutable Opt!(Ptr!StructDecl) funMut1 = com("fun-mut1", 2);
	immutable Opt!(Ptr!StructDecl) funMut2 = com("fun-mut2", 3);
	immutable Opt!(Ptr!StructDecl) funMut3 = com("fun-mut3", 4);
	immutable Opt!(Ptr!StructDecl) funPtr0 = com("fun-ptr0", 1);
	immutable Opt!(Ptr!StructDecl) funPtr1 = com("fun-ptr1", 2);
	immutable Opt!(Ptr!StructDecl) funPtr2 = com("fun-ptr2", 3);
	immutable Opt!(Ptr!StructDecl) funPtr3 = com("fun-ptr3", 4);
	immutable Opt!(Ptr!StructDecl) funPtr4 = com("fun-ptr4", 5);
	immutable Opt!(Ptr!StructDecl) funPtr5 = com("fun-ptr5", 6);
	immutable Opt!(Ptr!StructDecl) funPtr6 = com("fun-ptr6", 7);
	immutable Opt!(Ptr!StructDecl) funRef0 = com("fun-ref0", 1);
	immutable Opt!(Ptr!StructDecl) funRef1 = com("fun-ref1", 2);
	immutable Opt!(Ptr!StructDecl) funRef2 = com("fun-ref2", 3);
	immutable Opt!(Ptr!StructDecl) funRef3 = com("fun-ref3", 4);

	immutable Arr!Str missingArr = finishArr(alloc, missing);

	if (!empty(missingArr)) {
		immutable Diagnostic diag = Diagnostic(
			PathAndStorageKindAndRange(ctx.path, SourceRange.empty),
			immutable Diag(Diag.CommonTypesMissing(missingArr)));
		return fail!(CommonTypes, Diags)(arrLiteral!Diagnostic(alloc, diag));
	} else {
		return success!(CommonTypes, Diags)(
			CommonTypes(
				force(bool_),
				force(char_),
				force(int32),
				force(str),
				force(void_),
				force(anyPtr),
				arrLiteral!(Ptr!StructDecl)(alloc, force(opt), force(some), force(none)),
				force(byVal),
				force(arr),
				force(fut),
				arrLiteral!FunKindAndStructs(
					alloc,
					FunKindAndStructs(FunKind.ptr, arrLiteral!(Ptr!StructDecl)(
						alloc,
						force(funPtr0),
						force(funPtr1),
						force(funPtr2),
						force(funPtr3),
						force(funPtr4),
						force(funPtr5),
						force(funPtr6))),
					FunKindAndStructs(FunKind.plain, arrLiteral!(Ptr!StructDecl)(
						alloc,
						force(fun0),
						force(fun1),
						force(fun2),
						force(fun3))),
					FunKindAndStructs(FunKind.mut, arrLiteral!(Ptr!StructDecl)(
						alloc,
						force(funMut0),
						force(funMut1),
						force(funMut2),
						force(funMut3))),
					FunKindAndStructs(FunKind.ref_, arrLiteral!(Ptr!StructDecl)(
						alloc,
						force(funRef0),
						force(funRef1),
						force(funRef2),
						force(funRef3))))));
	}
}

immutable(Arr!TypeParam) checkTypeParams(Alloc)(
	ref Alloc alloc,
	ref CheckCtx ctx,
	ref immutable Arr!TypeParamAst asts,
) {
	immutable Arr!TypeParam typeParams =
		mapWithIndex(alloc, asts, (immutable size_t index, ref immutable TypeParamAst ast) =>
			immutable TypeParam(ast.range, ast.name, index));
	foreach (immutable size_t i; 0..size(typeParams))
		foreach (immutable size_t prev_i; 0..i) {
			immutable TypeParam tp = at(typeParams, i);
			if (symEq(tp.name, at(typeParams, prev_i).name))
				addDiag(alloc, ctx, tp.range, Diag(
					Diag.ParamShadowsPrevious(Diag.ParamShadowsPrevious.Kind.typeParam, tp.name)));
		}
	return typeParams;
}

void collectTypeParamsInAst(Alloc)(ref Alloc alloc, ref immutable TypeAst ast, ref ArrBuilder!TypeParam res) {
	matchTypeAst(
		ast,
		(ref immutable TypeAst.TypeParam tp) {
			immutable Arr!TypeParam a = arrBuilderAsTempArr(res);
			if (!exists(a, (ref immutable TypeParam it) => symEq(it.name, tp.name))) {
				add(alloc, res, immutable TypeParam(tp.range, tp.name, arrBuilderSize(res)));
			}
		},
		(ref immutable TypeAst.InstStruct i) {
			foreach (ref immutable TypeAst arg; range(i.typeArgs))
				collectTypeParamsInAst(alloc, arg, res);
		});
}

immutable(Arr!TypeParam) collectTypeParams(Alloc)(ref Alloc alloc, ref immutable SigAst ast) {
	ArrBuilder!TypeParam res;
	collectTypeParamsInAst(alloc, ast.returnType, res);
	foreach (ref immutable ParamAst p; range(ast.params))
		collectTypeParamsInAst(alloc, p.type, res);
	return finishArr(alloc, res);
}

immutable(Arr!Param) checkParams(Alloc)(
	ref Alloc alloc,
	ref CheckCtx ctx,
	ref immutable Arr!ParamAst asts,
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
			return immutable Param(ast.range, ast.name, type, index);
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
	ref immutable Arr!TypeParam typeParams,
	ref immutable StructsAndAliasesMap structsAndAliasesMap,
	DelayStructInsts delayStructInsts
) {
	immutable TypeParamsScope typeParamsScope = TypeParamsScope(typeParams);
	immutable Arr!Param params =
		checkParams(alloc, ctx, ast.params, structsAndAliasesMap, typeParamsScope, delayStructInsts);
	immutable Type returnType =
		typeFromAst(alloc, ctx, ast.returnType, structsAndAliasesMap, typeParamsScope, delayStructInsts);
	return Sig(ast.range, ast.name, returnType, params);
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
	ref immutable Arr!TypeParam typeParams,
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
					typeParams,
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
		immutable Arr!TypeParam typeParams = checkTypeParams(alloc, ctx, ast.typeParams);
		immutable SpecBody body_ = checkSpecBody(alloc, ctx, typeParams, structsAndAliasesMap, ast.name, ast.body_);
		return immutable SpecDecl(ast.range, ast.isPublic, ast.name, typeParams, body_);
	});
}

Arr!StructAlias checkStructAliasesInitial(Alloc)(
	ref Alloc alloc,
	ref CheckCtx ctx,
	ref immutable Arr!StructAliasAst asts,
) {
	return mapToMut!StructAlias(alloc, asts, (ref immutable StructAliasAst ast) =>
		immutable StructAlias(ast.range, ast.isPublic, ast.name, checkTypeParams(alloc, ctx, ast.typeParams)));
}

struct PurityAndForceSendable {
	immutable Purity purity;
	immutable Bool forceSendable;
}

immutable(PurityAndForceSendable) getPurityFromAst(Alloc)(
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
		immutable PurityAndForceSendable res = () {
			final switch (force(ast.purity)) {
				case PuritySpecifier.data:
					return PurityAndForceSendable(Purity.data, False);
				case PuritySpecifier.sendable:
					return PurityAndForceSendable(Purity.sendable, False);
				case PuritySpecifier.forceSendable:
					return PurityAndForceSendable(Purity.sendable, True);
				case PuritySpecifier.mut:
					return PurityAndForceSendable(Purity.mut, False);
			}
		}();
		if (res.purity == defaultPurity)
			addDiag(alloc, ctx, ast.range, immutable Diag(
				immutable Diag.PuritySpecifierRedundant(defaultPurity, getTypeKind(ast.body_))));
		return res;
	} else
		return PurityAndForceSendable(defaultPurity, False);
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
		immutable PurityAndForceSendable p = getPurityFromAst(alloc, ctx, ast);
		return immutable StructDecl(
			ast.range,
			ast.isPublic,
			ast.name,
			checkTypeParams(alloc, ctx, ast.typeParams),
			p.purity,
			p.forceSendable);
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
	zipFirstMut(aliases, asts, (ref StructAlias structAlias, ref immutable StructAliasAst ast) {
		setTarget(structAlias, instStructFromAst!Alloc(
			alloc,
			ctx,
			ast.target,
			structsAndAliasesMap,
			TypeParamsScope(structAlias.typeParams),
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

immutable(Opt!ForcedByValOrRef) getForcedByValOrRef(immutable Opt!ExplicitByValOrRef e) {
	if (has(e))
		final switch (force(e)) {
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
			if (isPurityWorse(bestCasePurity(fieldType), struct_.purity) && !struct_.forceSendable)
				addDiag(alloc, ctx, field.range, immutable Diag(Diag.PurityOfFieldWorseThanRecord(struct_, fieldType)));
			if (field.isMutable) {
				immutable Opt!(Diag.MutFieldNotAllowed.Reason) reason =
					struct_.purity != Purity.mut && !struct_.forceSendable
						? some(Diag.MutFieldNotAllowed.Reason.recordIsNotMut)
						: forcedByVal
						? some(Diag.MutFieldNotAllowed.Reason.recordIsForcedByVal)
						: none!(Diag.MutFieldNotAllowed.Reason);
				if (has(reason))
					addDiag(alloc, ctx, field.range, immutable Diag(Diag.MutFieldNotAllowed(force(reason))));
			}
			return immutable RecordField(field.range, field.isMutable, field.name, fieldType, index);
		});
	everyPair(fields, (ref immutable RecordField a, ref immutable RecordField b) {
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
		everyPairWithIndex(
			force(members),
			// Must name the ignored parameter due to https://issues.dlang.org/show_bug.cgi?id=21165
			(ref immutable Ptr!StructInst a,
			ref immutable Ptr!StructInst b,
			immutable size_t _ignoreMe,
			immutable size_t bIndex) {
				if (ptrEquals(decl(a), decl(b))) {
					immutable Diag diag = immutable Diag(
						Diag.DuplicateDeclaration(Diag.DuplicateDeclaration.Kind.unionMember, a.decl.name));
					immutable SourceRange rg = at(un.members, bIndex).range;
					addDiag(alloc, ctx, rg, diag);
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
	zipMutPtrFirst(structs, asts, (Ptr!StructDecl struct_, ref immutable StructDeclAst ast) {
		immutable StructBody body_ = matchStructDeclAstBody!(immutable StructBody)(
			ast.body_,
			(ref immutable StructDeclAst.Body.Builtin) =>
				immutable StructBody(immutable StructBody.Builtin()),
			(ref immutable StructDeclAst.Body.ExternPtr) {
				if (!empty(ast.typeParams))
					addDiag(alloc, ctx, ast.range, immutable Diag(immutable Diag.ExternPtrHasTypeParams()));
				return immutable StructBody(immutable StructBody.ExternPtr());
			},
			(ref immutable StructDeclAst.Body.Record r) =>
				checkRecord(alloc, ctx, structsAndAliasesMap, ptrAsImmutable(struct_), r, delayStructInsts),
			(ref immutable StructDeclAst.Body.Union un) =>
				checkUnion(alloc, ctx, structsAndAliasesMap, ptrAsImmutable(struct_), un, delayStructInsts));
		setBody(struct_, body_);
	});

	foreach (ref immutable StructDecl struct_; range(arrAsImmutable(structs))) {
		matchStructBody!void(
			body_(struct_),
			(ref immutable StructBody.Bogus) {},
			(ref immutable StructBody.Builtin) {},
			(ref immutable StructBody.ExternPtr) {},
			(ref immutable StructBody.Record) {},
			(ref immutable StructBody.Union u) {
				foreach (ref immutable Ptr!StructInst member; range(u.members))
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
		assert(size(decl.typeParams) < 10); //TODO:KILL
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

immutable(Arr!(Ptr!SpecInst)) checkSpecUses(Alloc)(
	ref Alloc alloc,
	ref CheckCtx ctx,
	ref immutable Arr!SpecUseAst asts,
	ref immutable StructsAndAliasesMap structsAndAliasesMap,
	ref immutable SpecsMap specsMap,
	immutable TypeParamsScope typeParamsScope,
) {
	return mapOp!(Ptr!SpecInst)(alloc, asts, (ref immutable SpecUseAst ast) {
		immutable Opt!(Ptr!SpecDecl) opSpec = tryFindSpec(alloc, ctx, ast.spec, ast.range, specsMap);
		if (has(opSpec)) {
			immutable Ptr!SpecDecl spec = force(opSpec);
			immutable Arr!Type typeArgs = typeArgsFromAsts(
				alloc,
				ctx,
				ast.typeArgs,
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
			addDiag(alloc, ctx, ast.range, immutable Diag(Diag.NameNotFound(Diag.NameNotFound.Kind.spec, ast.spec)));
			return none!(Ptr!SpecInst);
		}
	});
}

immutable(FunsAndMap) checkFuns(Alloc)(
	ref Alloc alloc,
	ref CheckCtx ctx,
	immutable Ptr!Module containingModule,
	ref immutable CommonTypes commonTypes,
	ref immutable SpecsMap specsMap,
	ref immutable StructsAndAliasesMap structsAndAliasesMap,
	ref immutable Arr!FunDeclAst asts,
) {
	Arr!FunDecl funs = mapToMut(alloc, asts, (ref immutable FunDeclAst funAst) {
		immutable Arr!TypeParam typeParams = empty(funAst.typeParams)
			? collectTypeParams(alloc, funAst.sig)
			: checkTypeParams(alloc, ctx, funAst.typeParams);
		immutable Sig sig = checkSig(
			alloc,
			ctx,
			funAst.sig,
			typeParams,
			structsAndAliasesMap,
			noneMut!(Ptr!(MutArr!(Ptr!StructInst))));
		immutable Arr!(Ptr!SpecInst) specUses = checkSpecUses(
			alloc,
			ctx,
			funAst.specUses,
			structsAndAliasesMap,
			specsMap,
			TypeParamsScope(typeParams));
		immutable FunFlags flags = FunFlags(funAst.noCtx, funAst.summon, funAst.unsafe, funAst.trusted);
		return immutable FunDecl(containingModule, funAst.isPublic, flags, sig, typeParams, specUses);
	});

	immutable FunsMap funsMap = buildMultiDict!(Sym, Ptr!FunDecl, compareSym, FunDecl, Alloc)(
		alloc,
		arrAsImmutable(funs),
		(immutable Ptr!FunDecl it) =>
			immutable KeyValuePair!(Sym, Ptr!FunDecl)(name(it), it));

	foreach (ref const FunDecl f; range(funs))
		addToMutSymSetOkIfPresent(alloc, ctx.programState.funNames, name(f));

	zipMutPtrFirst(funs, asts, (Ptr!FunDecl fun, ref immutable FunDeclAst funAst) {
		setBody(fun, matchFunBodyAst(
			funAst.body_,
			(ref immutable FunBodyAst.Builtin) =>
				immutable FunBody(FunBody.Builtin()),
			(ref immutable FunBodyAst.Extern e) {
				if (!fun.noCtx)
					todo!void("'extern' fun must be 'noctx'");
				if (e.isGlobal && arity(fun) != 0)
					todo!void("'extern' fun has parameters");
				immutable Opt!Str mangledName = mapOption!Str(e.mangledName, (ref immutable Str s) =>
					copyStr(alloc, s));
				return immutable FunBody(FunBody.Extern(e.isGlobal, mangledName));
			},
			(ref immutable ExprAst e) =>
				immutable FunBody(checkFunctionBody!Alloc(
					alloc, ctx, e, structsAndAliasesMap, funsMap, ptrAsImmutable(fun), commonTypes))));
	});

	return FunsAndMap(arrAsImmutable(funs), funsMap);
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

immutable(Ptr!Module) checkWorkerAfterCommonTypes(Alloc)(
	ref Alloc alloc,
	ref CheckCtx ctx,
	ref immutable CommonTypes commonTypes,
	ref immutable StructsAndAliasesMap structsAndAliasesMap,
	ref Arr!StructDecl structs,
	ref MutArr!(Ptr!StructInst) delayStructInsts,
	ref immutable Arr!(Ptr!Module) imports,
	ref immutable Arr!(Ptr!Module) exports,
	ref immutable FileAst ast,
) {
	checkStructBodies!Alloc(alloc, ctx, structsAndAliasesMap, structs, ast.structs, delayStructInsts);
	foreach (ref const StructDecl s; range(structs))
		if (isRecord(s.body_))
			foreach (ref immutable RecordField f; range(asRecord(s.body_).fields))
				addToMutSymSetOkIfPresent(alloc, ctx.programState.recordFieldNames, f.name);

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
	foreach (ref immutable SpecDecl s; range(specs))
		addToMutSymSetOkIfPresent(alloc, ctx.programState.specNames, s.name);

	DelayInit!Module mod = delayInit!Module(alloc);

	immutable FunsAndMap funsAndMap = checkFuns(
		alloc,
		ctx,
		mod.ptr,
		commonTypes,
		specsMap,
		structsAndAliasesMap,
		ast.funs);

	// Create a module unconditionally so every function will always have containingModule set, even in failure case
	return mod.finish(
		ctx.path,
		imports,
		exports,
		arrAsImmutable(structs),
		specs,
		funsAndMap.funs,
		structsAndAliasesMap,
		specsMap,
		funsAndMap.funsMap);
}

void recurAddImport(Alloc)(
	ref Alloc alloc,
	ref ArrBuilder!(Ptr!Module) res,
	immutable Ptr!Module module_,
) {
	immutable Arr!(Ptr!Module) resTemp = arrBuilderAsTempArr(res);
	if (!contains(resTemp, module_, (ref immutable Ptr!Module a, ref immutable Ptr!Module b) => ptrEquals(a, b))) {
		add(alloc, res, module_);
		foreach (immutable Ptr!Module e; range(module_.exports))
			recurAddImport(alloc, res, e);
	}
}

immutable(Arr!(Ptr!Module)) getFlattenedImports(Alloc)(
	ref Alloc alloc,
	ref immutable Arr!(Ptr!Module) imports,
) {
	ArrBuilder!(Ptr!Module) res;
	foreach (immutable Ptr!Module m; range(imports))
		recurAddImport(alloc, res, m);
	return finishArr(alloc, res);
}

immutable(Result!(BootstrapCheck, Diags)) checkWorker(Alloc)(
	ref Alloc alloc,
	ref ProgramState programState,
	immutable Arr!(Ptr!Module) imports,
	immutable Arr!(Ptr!Module) exports,
	ref immutable PathAndAst pathAndAst,
	scope immutable(Result!(CommonTypes, Diags)) delegate(
		ref CheckCtx,
		ref immutable StructsAndAliasesMap,
		ref MutArr!(Ptr!StructInst),
	) @safe @nogc pure nothrow getCommonTypes,
) {
	CheckCtx ctx = CheckCtx(
		ptrTrustMe_mut(programState),
		pathAndAst.pathAndStorageKind,
		getFlattenedImports(alloc, imports));
	immutable FileAst ast = pathAndAst.ast;

	// Since structs may refer to each other, first get a structsAndAliasesMap, *then* fill in bodies
	Arr!StructDecl structs = checkStructsInitial(alloc, ctx, ast.structs);
	foreach (ref const StructDecl s; range(structs))
		addToMutSymSetOkIfPresent(alloc, programState.structAndAliasNames, s.name);
	Arr!StructAlias structAliases = checkStructAliasesInitial(alloc, ctx, ast.structAliases);
	foreach (ref const StructAlias a; range(structAliases))
		addToMutSymSetOkIfPresent(alloc, programState.structAndAliasNames, a.name);
	immutable StructsAndAliasesMap structsAndAliasesMap =
		buildStructsAndAliasesDict(alloc, ctx, arrAsImmutable(structs), arrAsImmutable(structAliases));

	// We need to create StructInsts when filling in struct bodies.
	// But when creating a StructInst, we usually want to fill in its body.
	// In case the decl body isn't available yet,
	// we'll delay creating the StructInst body, which isn't needed until expr checking.
	MutArr!(Ptr!StructInst) delayStructInsts;
	checkStructAliasTargets!Alloc(alloc, ctx, structsAndAliasesMap, structAliases, ast.structAliases, delayStructInsts);

	if (hasDiags(ctx))
		return fail!(BootstrapCheck, Diags)(diags(alloc, ctx));
	else {
		immutable Result!(CommonTypes, Diags) commonTypesResult =
			getCommonTypes(ctx, structsAndAliasesMap, delayStructInsts);
		return flatMapSuccess!(BootstrapCheck, CommonTypes, Diags)(
			commonTypesResult,
			(ref immutable CommonTypes commonTypes) {
				immutable Ptr!Module mod = checkWorkerAfterCommonTypes(
					alloc,
					ctx,
					commonTypes,
					structsAndAliasesMap,
					structs,
					delayStructInsts,
					imports,
					exports,
					ast);
				return hasDiags(ctx)
					? fail!(BootstrapCheck, Diags)(diags(alloc, ctx))
					: success!(BootstrapCheck, Diags)(BootstrapCheck(mod, commonTypes));
			});
	}
}
