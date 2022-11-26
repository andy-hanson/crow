module frontend.check.check;

@safe @nogc pure nothrow:

import frontend.check.checkCtx : addDiag, CheckCtx, checkForUnused, newUsedImportsAndReExports, posInFile, rangeInFile;
import frontend.check.checkExpr : checkFunctionBody;
import frontend.check.checkStructs : checkStructBodies, checkStructsInitial;
import frontend.check.dicts :
	FunDeclAndIndex,
	FunsDict,
	ModuleLocalAliasIndex,
	ModuleLocalFunIndex,
	ModuleLocalSpecIndex,
	ModuleLocalStructIndex,
	ModuleLocalStructOrAliasIndex,
	SpecDeclAndIndex,
	SpecsDict,
	StructsAndAliasesDict,
	StructOrAliasAndIndex;
import frontend.check.funsForStruct : addFunsForStruct, countFunsForStruct;
import frontend.check.instantiate :
	DelayStructInsts, instantiateSpec, instantiateStruct, instantiateStructBody, TypeArgsArray, typeArgsArray;
import frontend.check.typeFromAst :
	checkTypeParams, tryFindSpec, typeArgsFromAsts, typeFromAst, typeFromAstNoTypeParamsNeverDelay;
import frontend.diagnosticsBuilder : addDiagnostic, DiagnosticsBuilder;
import frontend.parse.ast :
	ExprAst,
	ExprAstKind,
	FileAst,
	FunDeclAst,
	FunModifierAst,
	LiteralStringAst,
	NameAndRange,
	ParamAst,
	ParamsAst,
	rangeOfNameAndRange,
	SpecBodyAst,
	SpecDeclAst,
	SpecSigAst,
	StructAliasAst,
	TestAst,
	TypeAst;
import frontend.programState : ProgramState;
import model.diag : Diag;
import model.model :
	arity,
	arityIsNonZero,
	body_,
	CommonTypes,
	decl,
	Expr,
	FileContent,
	FunBody,
	FunDecl,
	FunFlags,
	FunKind,
	FunKindAndStructs,
	ImportFileType,
	ImportOrExport,
	ImportOrExportKind,
	IntegralTypes,
	isLinkageAlwaysCompatible,
	Linkage,
	linkageRange,
	Module,
	name,
	NameReferents,
	okIfUnused,
	Param,
	Params,
	paramsArray,
	Purity,
	range,
	setBody,
	setTarget,
	SpecBody,
	SpecDecl,
	SpecDeclSig,
	SpecInst,
	StructAlias,
	StructBody,
	StructDecl,
	StructInst,
	StructOrAlias,
	target,
	Test,
	Type,
	typeArgs,
	TypeParam,
	typeParams,
	Visibility,
	visibility;
import util.alloc.alloc : Alloc;
import util.col.arr : castImmutable, empty, emptySmallArray, only, ptrsRange, sizeEq, small;
import util.col.arrBuilder : add, ArrBuilder, finishArr;
import util.col.arrUtil : cat, eachPair, map, mapOp, mapToMut, mapWithIndex, zip, zipPtrFirst;
import util.col.dict : Dict, dictEach, hasKey, KeyValuePair;
import util.col.dictBuilder : DictBuilder, finishDict, tryAddToDict;
import util.col.exactSizeArrBuilder : ExactSizeArrBuilder, exactSizeArrBuilderAdd, finish, newExactSizeArrBuilder;
import util.col.fullIndexDict :
	FullIndexDict, fullIndexDictCastImmutable, fullIndexDictOfArr, fullIndexDictZipPtrs, makeFullIndexDict_mut;
import util.col.multiDict : buildMultiDict, multiDictEach;
import util.col.mutArr : mustPop, MutArr, mutArrIsEmpty;
import util.col.mutDict : insertOrUpdate, moveToDict, MutDict;
import util.col.mutMaxArr : MutMaxArr, mutMaxArr, mutMaxArrSize, pushIfUnderMaxSize, tempAsArr;
import util.col.str : copySafeCStr, SafeCStr, safeCStr, strOfSafeCStr;
import util.memory : allocate, allocateMut, overwriteMemory;
import util.opt : force, has, none, noneMut, Opt, some;
import util.perf : Perf;
import util.ptr : castImmutable, ptrTrustMe;
import util.sourceRange : FileAndPos, FileAndRange, FileIndex, RangeWithinFile;
import util.sym : AllSymbols, Sym, sym;
import util.util : unreachable, todo, verify;

struct PathAndAst { //TODO:RENAME
	immutable FileIndex fileIndex;
	immutable FileAst ast;
}

struct BootstrapCheck {
	immutable Module module_;
	immutable CommonTypes commonTypes;
}

immutable(BootstrapCheck) checkBootstrap(
	ref Alloc alloc,
	ref Perf perf,
	ref AllSymbols allSymbols,
	ref DiagnosticsBuilder diagsBuilder,
	ref ProgramState programState,
	immutable PathAndAst pathAndAst,
) {
	static immutable ImportsAndExports emptyImportsAndExports = immutable ImportsAndExports([], [], [], []);
	return checkWorker(
		alloc,
		perf,
		allSymbols,
		diagsBuilder,
		programState,
		emptyImportsAndExports,
		pathAndAst,
		(ref CheckCtx ctx,
		ref immutable StructsAndAliasesDict structsAndAliasesDict,
		ref MutArr!(StructInst*) delayedStructInsts) =>
			getCommonTypes(ctx, structsAndAliasesDict, delayedStructInsts));
}

struct ImportsAndExports {
	immutable ImportOrExport[] moduleImports;
	immutable ImportOrExport[] moduleExports;
	immutable ImportOrExportFile[] fileImports;
	immutable ImportOrExportFile[] fileExports;
}

struct ImportOrExportFile {
	immutable RangeWithinFile range;
	immutable Sym name;
	immutable ImportFileType type;
	immutable FileContent content;
}

immutable(Module) check(
	ref Alloc alloc,
	ref Perf perf,
	ref AllSymbols allSymbols,
	ref DiagnosticsBuilder diagsBuilder,
	ref ProgramState programState,
	ref immutable ImportsAndExports importsAndExports,
	scope ref immutable PathAndAst pathAndAst,
	ref immutable CommonTypes commonTypes,
) =>
	checkWorker(
		alloc,
		perf,
		allSymbols,
		diagsBuilder,
		programState,
		importsAndExports,
		pathAndAst,
		(ref CheckCtx, ref immutable(StructsAndAliasesDict), ref MutArr!(StructInst*)) => commonTypes,
	).module_;

private:

immutable(Opt!(StructDecl*)) getCommonTemplateType(
	ref immutable StructsAndAliasesDict structsAndAliasesDict,
	immutable Sym name,
	immutable size_t expectedTypeParams,
) {
	immutable Opt!StructOrAliasAndIndex res = structsAndAliasesDict[name];
	if (has(res)) {
		// TODO: may fail -- builtin Template should not be an alias
		immutable StructDecl* decl = force(res).structOrAlias.as!(StructDecl*);
		if (decl.typeParams.length != expectedTypeParams)
			todo!void("getCommonTemplateType");
		return some(decl);
	} else
		return none!(StructDecl*);
}

immutable(Opt!(StructInst*)) getCommonNonTemplateType(
	ref Alloc alloc,
	ref ProgramState programState,
	ref immutable StructsAndAliasesDict structsAndAliasesDict,
	immutable Sym name,
	ref MutArr!(StructInst*) delayedStructInsts,
) {
	immutable Opt!StructOrAliasAndIndex opStructOrAlias = structsAndAliasesDict[name];
	return has(opStructOrAlias)
		? instantiateNonTemplateStructOrAlias(
			alloc,
			programState,
			delayedStructInsts,
			force(opStructOrAlias).structOrAlias)
		: none!(StructInst*);
}

immutable(Opt!(StructInst*)) instantiateNonTemplateStructOrAlias(
	ref Alloc alloc,
	ref ProgramState programState,
	ref MutArr!(StructInst*) delayedStructInsts,
	immutable StructOrAlias structOrAlias,
) {
	verify(empty(typeParams(structOrAlias)));
	return structOrAlias.matchWithPointers!(immutable Opt!(StructInst*))(
		(immutable StructAlias* x) =>
			target(*x),
		(immutable StructDecl* x) =>
			some(instantiateNonTemplateStructDecl(alloc, programState, delayedStructInsts, x)));
}

immutable(StructInst*) instantiateNonTemplateStructDecl(
	ref Alloc alloc,
	ref ProgramState programState,
	ref MutArr!(StructInst*) delayedStructInsts,
	immutable StructDecl* structDecl,
) =>
	instantiateStruct(alloc, programState, structDecl, [], some(ptrTrustMe(delayedStructInsts)));

immutable(CommonTypes) getCommonTypes(
	ref CheckCtx ctx,
	ref immutable StructsAndAliasesDict structsAndAliasesDict,
	ref MutArr!(StructInst*) delayedStructInsts,
) {
	void addDiagMissing(immutable Sym name) {
		addDiag(
			ctx,
			immutable FileAndRange(ctx.fileIndex, RangeWithinFile.empty),
			immutable Diag(immutable Diag.CommonTypeMissing(name)));
	}

	immutable(StructInst*) nonTemplateFromSym(immutable Sym name) {
		immutable Opt!(StructInst*) res = getCommonNonTemplateType(
			ctx.alloc,
			ctx.programState,
			structsAndAliasesDict,
			name,
			delayedStructInsts);
		if (has(res))
			return force(res);
		else {
			addDiagMissing(name);
			return instantiateNonTemplateStructDecl(
				ctx.alloc,
				ctx.programState,
				delayedStructInsts,
				bogusStructDecl(ctx.alloc, 0));
		}
	}
	immutable(StructInst*) nonTemplate(immutable string name)() =>
		nonTemplateFromSym(sym!name);

	immutable StructInst* bool_ = nonTemplate!"bool";
	immutable StructInst* char8 = nonTemplate!"char8";
	immutable StructInst* float32 = nonTemplate!"float32";
	immutable StructInst* float64 = nonTemplate!"float64";
	immutable StructInst* int8 = nonTemplate!"int8";
	immutable StructInst* int16 = nonTemplate!"int16";
	immutable StructInst* int32 = nonTemplate!"int32";
	immutable StructInst* int64 = nonTemplate!"int64";
	immutable StructInst* nat8 = nonTemplate!"nat8";
	immutable StructInst* nat16 = nonTemplate!"nat16";
	immutable StructInst* nat32 = nonTemplate!"nat32";
	immutable StructInst* nat64 = nonTemplate!"nat64";
	immutable StructInst* symbol = nonTemplate!"symbol";
	immutable StructInst* void_ = nonTemplate!"void";

	immutable(StructDecl*) getDeclFromSym(immutable Sym name, immutable size_t nTypeParameters) {
		immutable Opt!(StructDecl*) res =
			getCommonTemplateType(structsAndAliasesDict, name, nTypeParameters);
		if (has(res))
			return force(res);
		else {
			addDiagMissing(name);
			return bogusStructDecl(ctx.alloc, nTypeParameters);
		}
	}
	immutable(StructDecl*) getDecl(immutable string name)(immutable size_t nTypeParameters) =>
		getDeclFromSym(sym!name, nTypeParameters);

	immutable StructDecl* byVal = getDecl!"by-val"(1);
	immutable StructDecl* array = getDecl!"array"(1);
	immutable StructDecl* future = getDecl!"future"(1);
	immutable StructDecl* namedVal = getDecl!"named-val"(1);
	immutable StructDecl* opt = getDecl!"option"(1);
	immutable StructDecl* pointerConst = getDecl!"const-pointer"(1);
	immutable StructDecl* pointerMut = getDecl!"mut-pointer"(1);
	immutable StructDecl*[10] funStructs = [
		getDecl!"fun0"(1),
		getDecl!"fun1"(2),
		getDecl!"fun2"(3),
		getDecl!"fun3"(4),
		getDecl!"fun4"(5),
		getDecl!"fun5"(6),
		getDecl!"fun6"(7),
		getDecl!"fun7"(8),
		getDecl!"fun8"(9),
		getDecl!"fun9"(10),
	];
	immutable StructDecl*[10] funActStructs = [
		getDecl!"fun-act0"(1),
		getDecl!"fun-act1"(2),
		getDecl!"fun-act2"(3),
		getDecl!"fun-act3"(4),
		getDecl!"fun-act4"(5),
		getDecl!"fun-act5"(6),
		getDecl!"fun-act6"(7),
		getDecl!"fun-act7"(8),
		getDecl!"fun-act8"(9),
		getDecl!"fun-act9"(10),
	];
	immutable StructDecl*[10] funPointerStructs = [
		getDecl!"fun-pointer0"(1),
		getDecl!"fun-pointer1"(2),
		getDecl!"fun-pointer2"(3),
		getDecl!"fun-pointer3"(4),
		getDecl!"fun-pointer4"(5),
		getDecl!"fun-pointer5"(6),
		getDecl!"fun-pointer6"(7),
		getDecl!"fun-pointer7"(8),
		getDecl!"fun-pointer8"(9),
		getDecl!"fun-pointer9"(10),
	];
	immutable StructDecl*[10] funRefStructs = [
		getDecl!"fun-ref0"(1),
		getDecl!"fun-ref1"(2),
		getDecl!"fun-ref2"(3),
		getDecl!"fun-ref3"(4),
		getDecl!"fun-ref4"(5),
		getDecl!"fun-ref5"(6),
		getDecl!"fun-ref6"(7),
		getDecl!"fun-ref7"(8),
		getDecl!"fun-ref8"(9),
		getDecl!"fun-ref9"(10),
	];

	immutable StructDecl* constPointer = getDecl!"const-pointer"(1);
	immutable StructInst* cStr = instantiateStruct(
		ctx.alloc,
		ctx.programState,
		constPointer,
		[immutable Type(char8)],
		some(ptrTrustMe(delayedStructInsts)));

	return immutable CommonTypes(
		bool_,
		char8,
		cStr,
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
		symbol,
		void_,
		byVal,
		array,
		future,
		namedVal,
		opt,
		pointerConst,
		pointerMut,
		[
			immutable FunKindAndStructs(FunKind.plain, funStructs),
			immutable FunKindAndStructs(FunKind.mut, funActStructs),
			immutable FunKindAndStructs(FunKind.ref_, funRefStructs),
			immutable FunKindAndStructs(FunKind.pointer, funPointerStructs),
		]);
}

immutable(StructDecl*) bogusStructDecl(ref Alloc alloc, immutable size_t nTypeParameters) {
	ArrBuilder!TypeParam typeParams;
	immutable FileAndRange fileAndRange = immutable FileAndRange(immutable FileIndex(0), RangeWithinFile.empty);
	foreach (immutable size_t i; 0 .. nTypeParameters)
		add(alloc, typeParams, immutable TypeParam(fileAndRange, sym!"bogus", i));
	StructDecl* res = allocateMut(alloc, StructDecl(
		fileAndRange,
		safeCStr!"",
		sym!"bogus",
		small(finishArr(alloc, typeParams)),
		Visibility.public_,
		Linkage.internal,
		Purity.data,
		false));
	setBody(*res, immutable StructBody(immutable StructBody.Bogus()));
	return castImmutable(res);
}

immutable(Params) checkParams(
	ref CheckCtx ctx,
	ref immutable CommonTypes commonTypes,
	scope immutable ParamsAst ast,
	scope ref immutable StructsAndAliasesDict structsAndAliasesDict,
	scope immutable TypeParam[] typeParamsScope,
	ref DelayStructInsts delayStructInsts,
) =>
	ast.match!(immutable Params)(
		(immutable ParamAst[] asts) {
			immutable Param[] params = mapWithIndex!(Param, ParamAst)(
				ctx.alloc,
				asts,
				(immutable size_t index, scope ref immutable ParamAst ast) =>
					checkParam(ctx, commonTypes, structsAndAliasesDict, typeParamsScope, delayStructInsts, ast, index));
			eachPair!Param(params, (ref immutable Param x, ref immutable Param y) {
				if (has(x.name) && has(y.name) && force(x.name) == force(y.name))
					addDiag(ctx, y.range, immutable Diag(immutable Diag.DuplicateDeclaration(
						Diag.DuplicateDeclaration.Kind.paramOrLocal, force(y.name))));
			});
			return immutable Params(params);
		},
		(ref immutable ParamsAst.Varargs varargs) {
			immutable Param param = checkParam(
				ctx, commonTypes, structsAndAliasesDict, typeParamsScope, delayStructInsts, varargs.param, 0);
			immutable Type elementType = param.type.match!(immutable Type)(
				(immutable Type.Bogus) =>
					immutable Type(immutable Type.Bogus()),
				(ref immutable(TypeParam)) =>
					todo!(immutable Type)("diagnostic"),
				(ref immutable StructInst x) {
					if (decl(x) == commonTypes.array)
						return only(typeArgs(x));
					else
						return todo!(immutable Type)("diagnostic");
				});
			return immutable Params(allocate(ctx.alloc, immutable Params.Varargs(param, elementType)));
		});

immutable(Param) checkParam(
	ref CheckCtx ctx,
	ref immutable CommonTypes commonTypes,
	scope ref immutable StructsAndAliasesDict structsAndAliasesDict,
	scope immutable TypeParam[] typeParamsScope,
	ref DelayStructInsts delayStructInsts,
	scope ref immutable ParamAst ast,
	immutable size_t index,
) =>
	immutable Param(
		rangeInFile(ctx, ast.range),
		ast.name,
		typeFromAst(ctx, commonTypes, ast.type, structsAndAliasesDict, typeParamsScope, delayStructInsts),
		index);

struct ReturnTypeAndParams {
	immutable Type returnType;
	immutable Params params;
}
immutable(ReturnTypeAndParams) checkReturnTypeAndParams(
	ref CheckCtx ctx,
	ref immutable CommonTypes commonTypes,
	scope immutable TypeAst returnTypeAst,
	scope immutable ParamsAst paramsAst,
	scope immutable TypeParam[] typeParams,
	scope ref immutable StructsAndAliasesDict structsAndAliasesDict,
	DelayStructInsts delayStructInsts
) =>
	immutable ReturnTypeAndParams(
		typeFromAst(ctx, commonTypes, returnTypeAst, structsAndAliasesDict, typeParams, delayStructInsts),
		checkParams(ctx, commonTypes, paramsAst, structsAndAliasesDict, typeParams, delayStructInsts));

immutable(SpecBody.Builtin.Kind) getSpecBodyBuiltinKind(
	ref CheckCtx ctx,
	immutable RangeWithinFile range,
	immutable Sym name,
) {
	switch (name.value) {
		case sym!"is-data".value:
			return SpecBody.Builtin.Kind.data;
		case sym!"is-sendable".value:
			return SpecBody.Builtin.Kind.send;
		default:
			addDiag(ctx, range, immutable Diag(immutable Diag.BuiltinUnsupported(name)));
			return SpecBody.Builtin.Kind.data;
	}
}

immutable(SpecBody) checkSpecBody(
	ref CheckCtx ctx,
	ref immutable CommonTypes commonTypes,
	immutable TypeParam[] typeParams,
	ref immutable StructsAndAliasesDict structsAndAliasesDict,
	immutable RangeWithinFile range,
	immutable Sym name,
	ref immutable SpecBodyAst ast,
) =>
	ast.match!(immutable SpecBody)(
		(immutable SpecBodyAst.Builtin) =>
			immutable SpecBody(SpecBody.Builtin(getSpecBodyBuiltinKind(ctx, range, name))),
		(immutable SpecSigAst[] sigs) =>
			immutable SpecBody(map(ctx.alloc, sigs, (ref immutable SpecSigAst it) {
				immutable ReturnTypeAndParams rp = checkReturnTypeAndParams(
					ctx,
					commonTypes,
					it.returnType,
					it.params,
					typeParams,
					structsAndAliasesDict,
					noneMut!(MutArr!(StructInst*)*));
				return immutable SpecDeclSig(
					it.docComment,
					posInFile(ctx, it.range.start),
					it.name,
					rp.returnType,
					rp.params);
			})));

immutable(SpecDecl[]) checkSpecDecls(
	ref CheckCtx ctx,
	ref immutable CommonTypes commonTypes,
	ref immutable StructsAndAliasesDict structsAndAliasesDict,
	scope immutable SpecDeclAst[] asts,
) =>
	map(ctx.alloc, asts, (ref immutable SpecDeclAst ast) {
		immutable TypeParam[] typeParams = checkTypeParams(ctx, ast.typeParams);
		immutable SpecBody body_ =
			checkSpecBody(ctx, commonTypes, typeParams, structsAndAliasesDict, ast.range, ast.name, ast.body_);
		return immutable SpecDecl(
			rangeInFile(ctx, ast.range),
			copySafeCStr(ctx.alloc, ast.docComment),
			ast.visibility,
			ast.name,
			small(typeParams),
			body_);
	});

StructAlias[] checkStructAliasesInitial(ref CheckCtx ctx, scope immutable StructAliasAst[] asts) =>
	mapToMut!(StructAlias, StructAliasAst)(ctx.alloc, asts, (scope ref immutable StructAliasAst ast) @safe =>
		StructAlias(
			rangeInFile(ctx, ast.range),
			copySafeCStr(ctx.alloc, ast.docComment),
			ast.visibility,
			ast.name,
			small(checkTypeParams(ctx, ast.typeParams))));

void checkStructAliasTargets(
	ref CheckCtx ctx,
	ref immutable CommonTypes commonTypes,
	ref immutable StructsAndAliasesDict structsAndAliasesDict,
	StructAlias[] aliases,
	scope immutable StructAliasAst[] asts,
	ref MutArr!(StructInst*) delayStructInsts,
) {
	zip!(StructAlias, immutable StructAliasAst)(
		aliases,
		asts,
		(ref StructAlias structAlias, ref immutable StructAliasAst ast) {
			immutable Type type = typeFromAst(
				ctx,
				commonTypes,
				ast.target,
				structsAndAliasesDict,
				structAlias.typeParams,
				some!(MutArr!(StructInst*)*)(ptrTrustMe(delayStructInsts)));
			if (type.isA!(StructInst*))
				setTarget(structAlias, some(type.as!(StructInst*)));
			else {
				if (!type.isA!(Type.Bogus))
					todo!void("diagnostic -- alias does not resolve to struct (must be bogus or a type parameter)");
				setTarget(structAlias, none!(StructInst*));
			}
		});
}

immutable(StructsAndAliasesDict) buildStructsAndAliasesDict(
	ref CheckCtx ctx,
	immutable StructDecl[] structs,
	immutable StructAlias[] aliases,
) {
	DictBuilder!(Sym, StructOrAliasAndIndex) builder;
	void warnOnDup(immutable Sym name, immutable FileAndRange range, immutable Opt!StructOrAliasAndIndex opt) {
		if (has(opt))
			addDiag(ctx, range, immutable Diag(
				immutable Diag.DuplicateDeclaration(Diag.DuplicateDeclaration.Kind.structOrAlias, name)));
	}
	foreach (immutable size_t index; 0 .. structs.length) {
		immutable StructDecl* decl = &structs[index];
		immutable Sym name = decl.name;
		warnOnDup(name, decl.range, tryAddToDict(ctx.alloc, builder, name, immutable StructOrAliasAndIndex(
			immutable StructOrAlias(decl),
			immutable ModuleLocalStructOrAliasIndex(index))));
	}
	foreach (immutable size_t index; 0 .. aliases.length) {
		immutable StructAlias* alias_ = &aliases[index];
		immutable Sym name = alias_.name;
		warnOnDup(name, alias_.range, tryAddToDict(ctx.alloc, builder, name, immutable StructOrAliasAndIndex(
			immutable StructOrAlias(alias_),
			immutable ModuleLocalStructOrAliasIndex(index))));
	}
	return finishDict(ctx.alloc, builder);
}

struct FunsAndDict {
	immutable FunDecl[] funs;
	immutable Test[] tests;
	immutable FunsDict funsDict;
}

struct FunFlagsAndSpecs {
	immutable FunFlags flags;
	immutable SpecInst*[] specs;
}

immutable(FunFlagsAndSpecs) checkFunModifiers(
	ref CheckCtx ctx,
	ref immutable CommonTypes commonTypes,
	immutable RangeWithinFile range,
	scope immutable FunModifierAst[] asts,
	scope immutable StructsAndAliasesDict structsAndAliasesDict,
	scope immutable SpecsDict specsDict,
	scope immutable TypeParam[] typeParamsScope,
) {
	FunModifierAst.SpecialFlags allFlags = FunModifierAst.SpecialFlags.none;
	immutable SpecInst*[] specs = mapOp!(SpecInst*)(ctx.alloc, asts, (scope ref immutable FunModifierAst ast) {
		immutable FunModifierAst.SpecialFlags flag = ast.specialFlags;
		if (flag == FunModifierAst.SpecialFlags.none) {
			immutable Opt!(SpecDecl*) opSpec = tryFindSpec(ctx, ast.name, specsDict);
			if (has(opSpec)) {
				immutable SpecDecl* spec = force(opSpec);
				TypeArgsArray typeArgs = typeArgsArray();
				typeArgsFromAsts(
					typeArgs,
					ctx,
					commonTypes,
					ast.typeArgs,
					structsAndAliasesDict,
					typeParamsScope,
					noneMut!(MutArr!(StructInst*)*));
				if (!sizeEq(tempAsArr(typeArgs), spec.typeParams)) {
					addDiag(ctx, rangeOfNameAndRange(ast.name, ctx.allSymbols), immutable Diag(
						immutable Diag.WrongNumberTypeArgsForSpec(
							spec,
							spec.typeParams.length,
							tempAsArr(typeArgs).length)));
					return none!(SpecInst*);
				} else
					return some(instantiateSpec(ctx.alloc, ctx.programState, spec, tempAsArr(typeArgs)));
			} else
				return none!(SpecInst*);
		} else {
			if (!empty(ast.typeArgs) &&
				flag != FunModifierAst.SpecialFlags.extern_ &&
				flag != FunModifierAst.SpecialFlags.global)
				addDiag(ctx, rangeOfNameAndRange(ast.name, ctx.allSymbols), immutable Diag(
					immutable Diag.FunModifierTypeArgs(ast.name.name)));
			if (allFlags & flag)
				todo!void("diag: duplicate flag");
			allFlags |= flag;
			return none!(SpecInst*);
		}
	});
	return immutable FunFlagsAndSpecs(checkFunFlags(ctx, range, allFlags), specs);
}

immutable(FunFlags) checkFunFlags(
	ref CheckCtx ctx,
	immutable RangeWithinFile range,
	immutable FunModifierAst.SpecialFlags flags,
) {
	void warnConflict(immutable Sym modifier0, immutable Sym modifier1) {
		addDiag(ctx, range, immutable Diag(immutable Diag.FunModifierConflict(modifier0, modifier1)));
	}
	void warnRedundant(immutable Sym modifier, immutable Sym redundantModifier) {
		addDiag(ctx, range, immutable Diag(immutable Diag.FunModifierRedundant(modifier, redundantModifier)));
	}

	immutable bool builtin = (flags & FunModifierAst.SpecialFlags.builtin) != 0;
	immutable bool extern_ = (flags & FunModifierAst.SpecialFlags.extern_) != 0;
	immutable bool global = (flags & FunModifierAst.SpecialFlags.global) != 0;
	immutable bool explicitNoctx = (flags & FunModifierAst.SpecialFlags.noctx) != 0;
	immutable bool noDoc = (flags & FunModifierAst.SpecialFlags.no_doc) != 0;
	immutable bool summon = (flags & FunModifierAst.SpecialFlags.summon) != 0;
	immutable bool threadLocal = (flags & FunModifierAst.SpecialFlags.thread_local) != 0;
	immutable bool trusted = (flags & FunModifierAst.SpecialFlags.trusted) != 0;
	immutable bool explicitUnsafe = (flags & FunModifierAst.SpecialFlags.unsafe) != 0;

	immutable bool implicitUnsafe = extern_ || global || threadLocal;
	immutable bool unsafe = explicitUnsafe || implicitUnsafe;
	immutable bool implicitNoctx = extern_ || global || threadLocal;
	immutable bool noctx = explicitNoctx || implicitNoctx;

	immutable(Sym) bodyModifier() =>
		builtin
			? sym!"builtin"
			: extern_
			? sym!"extern"
			: global
			? sym!"global"
			: threadLocal
			? sym!"thread-local"
			: unreachable!(immutable Sym);

	immutable FunFlags.Safety safety = trusted
		? FunFlags.Safety.trusted
		: unsafe
		? FunFlags.Safety.unsafe
		: FunFlags.Safety.safe;
	if (trusted && explicitUnsafe)
		warnConflict(sym!"trusted", sym!"unsafe");
	if (implicitNoctx && explicitNoctx)
		warnRedundant(bodyModifier(), sym!"noctx");
	if (implicitUnsafe && explicitUnsafe)
		warnRedundant(bodyModifier(), sym!"unsafe");
	if (implicitUnsafe && trusted && !extern_)
		warnConflict(bodyModifier(), sym!"trusted");
	immutable FunFlags.SpecialBody specialBody = builtin
		? FunFlags.SpecialBody.builtin
		: extern_
		? FunFlags.SpecialBody.extern_
		: global
		? FunFlags.SpecialBody.global
		: threadLocal
		? FunFlags.SpecialBody.threadLocal
		: FunFlags.SpecialBody.none;
	if (builtin + extern_ + global + threadLocal > 1) {
		MutMaxArr!(2, Sym) bodyModifiers = mutMaxArr!(2, Sym);
		if (builtin) pushIfUnderMaxSize(bodyModifiers, sym!"builtin");
		if (extern_) pushIfUnderMaxSize(bodyModifiers, sym!"extern");
		if (global) pushIfUnderMaxSize(bodyModifiers, sym!"global");
		if (threadLocal) pushIfUnderMaxSize(bodyModifiers, sym!"thread-local");
		verify(mutMaxArrSize(bodyModifiers) == 2);
		addDiag(ctx, range, immutable Diag(immutable Diag.FunModifierConflict(bodyModifiers[0], bodyModifiers[1])));
	}
	return immutable FunFlags(noctx, noDoc, summon, safety, false, false, specialBody);
}

immutable(FunsAndDict) checkFuns(
	ref CheckCtx ctx,
	ref immutable CommonTypes commonTypes,
	scope ref immutable SpecsDict specsDict,
	immutable StructDecl[] structs,
	scope ref immutable StructsAndAliasesDict structsAndAliasesDict,
	immutable ImportOrExportFile[] fileImports,
	immutable ImportOrExportFile[] fileExports,
	scope immutable FunDeclAst[] asts,
	scope immutable TestAst[] testAsts,
) {
	ExactSizeArrBuilder!FunDecl funsBuilder = newExactSizeArrBuilder!FunDecl(
		ctx.alloc,
		asts.length + fileImports.length + fileExports.length + countFunsForStruct(structs));
	foreach (ref immutable FunDeclAst funAst; asts) {
		immutable TypeParam[] typeParams = checkTypeParams(ctx, funAst.typeParams);
		immutable ReturnTypeAndParams rp = checkReturnTypeAndParams(
			ctx,
			commonTypes,
			funAst.returnType,
			funAst.params,
			typeParams,
			structsAndAliasesDict,
			noneMut!(MutArr!(StructInst*)*));
		immutable FunFlagsAndSpecs flagsAndSpecs = checkFunModifiers(
			ctx, commonTypes, funAst.range, funAst.modifiers, structsAndAliasesDict, specsDict, typeParams);
		exactSizeArrBuilderAdd(
			funsBuilder,
			FunDecl(
				copySafeCStr(ctx.alloc, funAst.docComment),
				funAst.visibility,
				posInFile(ctx, funAst.range.start),
				funAst.name,
				typeParams,
				rp.returnType,
				rp.params,
				flagsAndSpecs.flags,
				flagsAndSpecs.specs,
				immutable FunBody(immutable FunBody.Bogus())));
	}
	foreach (ref immutable ImportOrExportFile f; fileImports)
		exactSizeArrBuilderAdd(
			funsBuilder,
			funDeclForFileImportOrExport(ctx, commonTypes, structsAndAliasesDict, f, Visibility.private_));
	foreach (ref immutable ImportOrExportFile f; fileExports)
		exactSizeArrBuilderAdd(
			funsBuilder,
			funDeclForFileImportOrExport(ctx, commonTypes, structsAndAliasesDict, f, Visibility.public_));

	foreach (immutable StructDecl* struct_; ptrsRange(structs))
		addFunsForStruct(ctx, funsBuilder, commonTypes, struct_);
	FunDecl[] funs = finish(funsBuilder);
	FullIndexDict!(ModuleLocalFunIndex, bool) usedFuns =
		makeFullIndexDict_mut!(ModuleLocalFunIndex, bool)(ctx.alloc, funs.length, (immutable size_t) => false);

	immutable FunsDict funsDict = buildMultiDict!(Sym, FunDeclAndIndex, FunDecl)(
		ctx.alloc,
		castImmutable(funs),
		(immutable size_t index, immutable FunDecl* it) =>
			immutable KeyValuePair!(Sym, FunDeclAndIndex)(
				it.name,
				immutable FunDeclAndIndex(immutable ModuleLocalFunIndex(index), it)));

	FunDecl[] funsWithAsts = funs[0 .. asts.length];
	zipPtrFirst!(FunDecl, immutable FunDeclAst)(funsWithAsts, asts, (FunDecl* fun, ref immutable FunDeclAst funAst) {
		overwriteMemory(&fun.body_, () {
			final switch (fun.flags.specialBody) {
				case FunFlags.SpecialBody.none:
					if (!has(funAst.body_)) {
						addDiag(ctx, funAst.range, immutable Diag(immutable Diag.FunMissingBody()));
						return immutable FunBody(immutable FunBody.Bogus());
					} else
						return immutable FunBody(getExprFunctionBody(
							ctx,
							commonTypes,
							structsAndAliasesDict,
							funsDict,
							usedFuns,
							*castImmutable(fun),
							force(funAst.body_)));
				case FunFlags.SpecialBody.builtin:
					if (has(funAst.body_))
						todo!void("diag: builtin fun can't have body");
					return immutable FunBody(immutable FunBody.Builtin());
				case FunFlags.SpecialBody.extern_:
					if (has(funAst.body_))
						todo!void("diag: builtin fun can't have body");
					return immutable FunBody(checkExternOrGlobalBody(
						ctx,
						castImmutable(fun),
						getExternTypeArgs(funAst, FunModifierAst.SpecialFlags.extern_),
						false));
				case FunFlags.SpecialBody.global:
					if (has(funAst.body_))
						todo!void("diag: global fun can't have body");
					return immutable FunBody(checkExternOrGlobalBody(
						ctx,
						castImmutable(fun),
						getExternTypeArgs(funAst, FunModifierAst.SpecialFlags.global),
						true));
				case FunFlags.SpecialBody.threadLocal:
					if (has(funAst.body_))
						todo!void("diag: thraed-local fun can't have body");
					return immutable FunBody(checkThreadLocalBody(ctx, commonTypes, castImmutable(fun)));
			}
		}());
	});
	foreach (immutable size_t i, ref immutable ImportOrExportFile f; fileImports) {
		FunDecl* fun = &funs[asts.length + i];
		overwriteMemory(&fun.body_, getFileImportFunctionBody(
			ctx, commonTypes, structsAndAliasesDict, funsDict, usedFuns, *castImmutable(fun), f));
	}
	foreach (immutable size_t i, ref immutable ImportOrExportFile f; fileExports) {
		FunDecl* fun = &funs[asts.length + fileImports.length + i];
		overwriteMemory(&fun.body_, getFileImportFunctionBody(
			ctx, commonTypes, structsAndAliasesDict, funsDict, usedFuns, *castImmutable(fun), f));
	}

	immutable Test[] tests = map(ctx.alloc, testAsts, (scope ref immutable TestAst ast) {
		immutable Type voidType = immutable Type(commonTypes.void_);
		if (!has(ast.body_))
			todo!void("diag: test needs body");
		return immutable Test(checkFunctionBody(
			ctx,
			structsAndAliasesDict,
			commonTypes,
			funsDict,
			usedFuns,
			voidType,
			[],
			[],
			[],
			FunFlags.unsafeSummon,
			force(ast.body_)));
	});

	fullIndexDictZipPtrs!(ModuleLocalFunIndex, FunDecl, bool)(
		fullIndexDictOfArr!(ModuleLocalFunIndex, FunDecl)(castImmutable(funs)),
		fullIndexDictCastImmutable(usedFuns),
		(immutable(ModuleLocalFunIndex), immutable FunDecl* fun, immutable bool* used) {
			final switch (fun.visibility) {
				case Visibility.public_:
					break;
				case Visibility.private_:
					if (!*used && !okIfUnused(*fun))
						addDiag(ctx, fun.range, immutable Diag(
							immutable Diag.UnusedPrivateFun(fun)));
			}
		});

	return immutable FunsAndDict(castImmutable(funs), tests, funsDict);
}

immutable(TypeAst[]) getExternTypeArgs(scope ref immutable FunDeclAst a, immutable FunModifierAst.SpecialFlags flags) {
	foreach (ref immutable FunModifierAst modifier; a.modifiers)
		if (modifier.specialFlags == flags)
			return modifier.typeArgs;
	return unreachable!(immutable TypeAst[]);
}

immutable(FunBody) getFileImportFunctionBody(
	ref CheckCtx ctx,
	ref immutable CommonTypes commonTypes,
	scope ref immutable StructsAndAliasesDict structsAndAliasesDict,
	ref immutable FunsDict funsDict,
	ref FullIndexDict!(ModuleLocalFunIndex, bool) usedFuns,
	ref immutable FunDecl f,
	ref immutable ImportOrExportFile ie,
) =>
	ie.content.match!(immutable FunBody)(
		(immutable ubyte[] bytes) =>
			immutable FunBody(immutable FunBody.FileBytes(bytes)),
		(immutable SafeCStr str) {
			immutable ExprAst ast = immutable ExprAst(
				f.range.range,
				immutable ExprAstKind(immutable LiteralStringAst(strOfSafeCStr(str))));
			return immutable FunBody(
				getExprFunctionBody(ctx, commonTypes, structsAndAliasesDict, funsDict, usedFuns, f, ast));
		});

immutable(Expr) getExprFunctionBody(
	ref CheckCtx ctx,
	ref immutable CommonTypes commonTypes,
	scope ref immutable StructsAndAliasesDict structsAndAliasesDict,
	ref immutable FunsDict funsDict,
	ref FullIndexDict!(ModuleLocalFunIndex, bool) usedFuns,
	ref immutable FunDecl f,
	ref immutable ExprAst e,
) =>
	checkFunctionBody(
		ctx,
		structsAndAliasesDict,
		commonTypes,
		funsDict,
		usedFuns,
		f.returnType,
		f.typeParams,
		paramsArray(f.params),
		f.specs,
		f.flags,
		e);

FunDecl funDeclForFileImportOrExport(
	ref CheckCtx ctx,
	ref immutable CommonTypes commonTypes,
	scope ref immutable StructsAndAliasesDict structsAndAliasesDict,
	ref immutable ImportOrExportFile a,
	immutable Visibility visibility,
) =>
	FunDecl(
		safeCStr!"",
		visibility,
		immutable FileAndPos(ctx.fileIndex, a.range.start),
		a.name,
		[],
		typeForFileImport(ctx, commonTypes, structsAndAliasesDict, a.range, a.type),
		immutable Params([]),
		FunFlags.generatedNoCtx,
		[],
		immutable FunBody(immutable FunBody.Bogus()));

immutable(Type) typeForFileImport(
	ref CheckCtx ctx,
	ref immutable CommonTypes commonTypes,
	scope ref immutable StructsAndAliasesDict structsAndAliasesDict,
	immutable RangeWithinFile range,
	immutable ImportFileType type,
) {
	final switch (type) {
		case ImportFileType.nat8Array:
			immutable TypeAst nat8 = immutable TypeAst(immutable TypeAst.InstStruct(
				range,
				immutable NameAndRange(range.start, sym!"nat8"),
				emptySmallArray!TypeAst));
			scope immutable TypeAst arrayNat8 = immutable TypeAst(immutable TypeAst.InstStruct(
				range,
				immutable NameAndRange(range.start, sym!"array"),
				small([nat8])));
			return typeFromAstNoTypeParamsNeverDelay(ctx, commonTypes, arrayNat8, structsAndAliasesDict);
		case ImportFileType.str:
			//TODO: this sort of duplicates 'getStrType'
			scope immutable TypeAst ast = immutable TypeAst(immutable TypeAst.InstStruct(
				range,
				immutable NameAndRange(range.start, sym!"string"),
				emptySmallArray!TypeAst));
			return typeFromAstNoTypeParamsNeverDelay(ctx, commonTypes, ast, structsAndAliasesDict);
	}
}

immutable(FunBody.Extern) checkExternOrGlobalBody(
	ref CheckCtx ctx,
	immutable FunDecl* fun,
	immutable TypeAst[] typeArgs,
	immutable bool isGlobal,
) {
	immutable Linkage funLinkage = Linkage.extern_;

	if (!empty(fun.typeParams))
		addDiag(ctx, fun.range, immutable Diag(
			immutable Diag.ExternFunForbidden(fun, Diag.ExternFunForbidden.Reason.hasTypeParams)));
	if (!empty(fun.specs))
		addDiag(ctx, fun.range, immutable Diag(
			immutable Diag.ExternFunForbidden(fun, Diag.ExternFunForbidden.Reason.hasSpecs)));

	if (!isLinkageAlwaysCompatible(funLinkage, linkageRange(fun.returnType)))
		addDiag(ctx, fun.range, immutable Diag(
			immutable Diag.LinkageWorseThanContainingFun(fun, fun.returnType, none!(Param*))));
	fun.params.match!void(
		(immutable Param[] params) {
			foreach (immutable Param* p; ptrsRange(params)) {
				if (!isLinkageAlwaysCompatible(funLinkage, linkageRange(p.type)))
					addDiag(ctx, p.range, immutable Diag(
						immutable Diag.LinkageWorseThanContainingFun(fun, p.type, some(p))));
			}
		},
		(ref immutable Params.Varargs) {
			addDiag(ctx, fun.range, immutable Diag(
				immutable Diag.ExternFunForbidden(fun, Diag.ExternFunForbidden.Reason.variadic)));
		});

	if (isGlobal && arityIsNonZero(arity(*fun)))
		todo!void("'global' fun has parameters");

	immutable Opt!Sym libraryName = typeArgs.length != 1 ? none!Sym : only(typeArgs).match!(immutable Opt!Sym)(
		(ref immutable TypeAst.Dict) =>
			none!Sym,
		(immutable TypeAst.Fun) =>
			none!Sym,
		(immutable TypeAst.InstStruct i) =>
			empty(i.typeArgs) ? some(i.name.name) : none!Sym,
		(ref immutable TypeAst.Suffix) =>
			none!Sym,
		(ref immutable TypeAst.Tuple) =>
			none!Sym);
	if (!has(libraryName))
		addDiag(ctx, fun.range, immutable Diag(
			immutable Diag.ExternFunForbidden(fun, Diag.ExternFunForbidden.Reason.missingLibraryName)));
	return immutable FunBody.Extern(isGlobal, has(libraryName) ? force(libraryName) : sym!"bogus");
}

immutable(FunBody.ThreadLocal) checkThreadLocalBody(
	ref CheckCtx ctx,
	scope ref immutable CommonTypes commonTypes,
	immutable FunDecl* fun,
) {
	void err(immutable Diag.ThreadLocalError.Kind kind) {
		addDiag(ctx, fun.range, immutable Diag(immutable Diag.ThreadLocalError(fun, kind)));
	}
	if (!empty(fun.typeParams))
		err(Diag.ThreadLocalError.Kind.hasTypeParams);
	if (!isPtrMutType(commonTypes, fun.returnType))
		err(Diag.ThreadLocalError.Kind.mustReturnPtrMut);
	if (!paramsIsEmpty(fun.params))
		err(Diag.ThreadLocalError.Kind.hasParams);
	if (!empty(fun.specs))
		err(Diag.ThreadLocalError.Kind.hasSpecs);
	return immutable FunBody.ThreadLocal();
}

immutable(bool) isPtrMutType(scope ref immutable CommonTypes commonTypes, immutable Type a) =>
	a.isA!(StructInst*) && decl(*a.as!(StructInst*)) == commonTypes.ptrMut;

immutable(bool) paramsIsEmpty(scope immutable Params a) =>
	empty(paramsArray(a));

immutable(SpecsDict) buildSpecsDict(ref CheckCtx ctx, immutable SpecDecl[] specs) {
	DictBuilder!(Sym, SpecDeclAndIndex) res;
	foreach (immutable size_t index; 0 .. specs.length) {
		immutable SpecDecl* spec = &specs[index];
		immutable Sym name = spec.name;
		immutable Opt!SpecDeclAndIndex b = tryAddToDict(ctx.alloc, res, name, immutable SpecDeclAndIndex(
			spec,
			immutable ModuleLocalSpecIndex(index)));
		if (has(b))
			addDiag(ctx, force(b).decl.range, immutable Diag(
				immutable Diag.DuplicateDeclaration(Diag.DuplicateDeclaration.Kind.spec, name)));
	}
	return finishDict(ctx.alloc, res);
}

immutable(Module) checkWorkerAfterCommonTypes(
	ref CheckCtx ctx,
	ref immutable CommonTypes commonTypes,
	ref immutable StructsAndAliasesDict structsAndAliasesDict,
	immutable StructAlias[] structAliases,
	StructDecl[] structs,
	ref MutArr!(StructInst*) delayStructInsts,
	immutable FileIndex fileIndex,
	ref immutable ImportsAndExports importsAndExports,
	scope ref immutable FileAst ast,
) {
	checkStructBodies(ctx, commonTypes, structsAndAliasesDict, structs, ast.structs, delayStructInsts);
	immutable StructDecl[] structsImmutable = castImmutable(structs);

	while (!mutArrIsEmpty(delayStructInsts)) {
		StructInst* i = mustPop(delayStructInsts);
		setBody(*i, instantiateStructBody(
			ctx.alloc,
			ctx.programState,
			i.declAndArgs,
			some(ptrTrustMe(delayStructInsts))));
	}

	immutable SpecDecl[] specs = checkSpecDecls(ctx, commonTypes, structsAndAliasesDict, ast.specs);
	immutable SpecsDict specsDict = buildSpecsDict(ctx, specs);
	immutable FunsAndDict funsAndDict = checkFuns(
		ctx,
		commonTypes,
		specsDict,
		structsImmutable,
		structsAndAliasesDict,
		importsAndExports.fileImports,
		importsAndExports.fileExports,
		ast.funs,
		ast.tests);
	checkForUnused(ctx, structAliases, castImmutable(structs), specs);
	return immutable Module(
		fileIndex,
		copySafeCStr(ctx.alloc, ast.docComment),
		importsAndExports.moduleImports,
		importsAndExports.moduleExports,
		structsImmutable, specs, funsAndDict.funs, funsAndDict.tests,
		getAllExportedNames(
			ctx.alloc,
			ctx.diagsBuilder,
			importsAndExports.moduleExports,
			structsAndAliasesDict,
			specsDict,
			funsAndDict.funsDict,
			fileIndex));
}

immutable(Dict!(Sym, NameReferents)) getAllExportedNames(
	ref Alloc alloc,
	scope ref DiagnosticsBuilder diagsBuilder,
	scope immutable ImportOrExport[] reExports,
	ref immutable StructsAndAliasesDict structsAndAliasesDict,
	ref immutable SpecsDict specsDict,
	ref immutable FunsDict funsDict,
	immutable FileIndex fileIndex,
) {
	MutDict!(immutable Sym, immutable NameReferents) res;
	void addExport(immutable Sym name, immutable NameReferents cur, immutable FileAndRange range)
		@safe @nogc pure nothrow {
		insertOrUpdate!(immutable Sym, immutable NameReferents)(
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

	foreach (ref immutable ImportOrExport e; reExports)
		e.kind.match!void(
			(immutable ImportOrExportKind.ModuleWhole m) {
				dictEach!(Sym, NameReferents)(
					m.module_.allExportedNames,
					(immutable Sym name, ref immutable NameReferents value) {
						addExport(name, value, immutable FileAndRange(fileIndex, force(e.importSource)));
					});
			},
			(immutable ImportOrExportKind.ModuleNamed m) {
				foreach (immutable Sym name; m.names) {
					immutable Opt!NameReferents value = m.module_.allExportedNames[name];
					if (has(value))
						addExport(name, force(value), immutable FileAndRange(fileIndex, force(e.importSource)));
				}
			});
	dictEach!(Sym, StructOrAliasAndIndex)(
		structsAndAliasesDict,
		(immutable Sym name, ref immutable StructOrAliasAndIndex it) {
			final switch (visibility(it.structOrAlias)) {
				case Visibility.public_:
					addExport(
						name,
						immutable NameReferents(some(it.structOrAlias), none!(SpecDecl*), []),
						range(it.structOrAlias));
					break;
				case Visibility.private_:
					break;
			}
		});
	dictEach!(Sym, SpecDeclAndIndex)(specsDict, (immutable Sym name, ref immutable SpecDeclAndIndex it) {
		final switch (it.decl.visibility) {
			case Visibility.public_:
				addExport(name, immutable NameReferents(none!StructOrAlias, some(it.decl), []), it.decl.range);
				break;
			case Visibility.private_:
				break;
		}
	});
	multiDictEach!(Sym, FunDeclAndIndex)(funsDict, (immutable Sym name, immutable FunDeclAndIndex[] funs) {
		immutable FunDecl*[] funDecls = mapOp!(FunDecl*)(
			alloc,
			funs,
			(ref immutable FunDeclAndIndex it) {
				final switch (it.decl.visibility) {
					case Visibility.public_:
						return some(it.decl);
					case Visibility.private_:
						return none!(FunDecl*);
				}
			});
		if (!empty(funDecls))
			addExport(
				name,
				immutable NameReferents(none!StructOrAlias, none!(SpecDecl*), funDecls),
				// This argument doesn't matter because a function never results in a duplicate export error
				immutable FileAndRange(fileIndex, RangeWithinFile.empty));
	});

	return moveToDict!(Sym, NameReferents)(alloc, res);
}

immutable(BootstrapCheck) checkWorker(
	ref Alloc alloc,
	scope ref Perf perf,
	scope ref AllSymbols allSymbols,
	ref DiagnosticsBuilder diagsBuilder,
	ref ProgramState programState,
	ref immutable ImportsAndExports importsAndExports,
	scope ref immutable PathAndAst pathAndAst,
	scope immutable(CommonTypes) delegate(
		ref CheckCtx,
		ref immutable StructsAndAliasesDict,
		ref MutArr!(StructInst*),
	) @safe @nogc pure nothrow getCommonTypes,
) {
	checkImportsOrExports(alloc, diagsBuilder, pathAndAst.fileIndex, importsAndExports.moduleImports);
	checkImportsOrExports(alloc, diagsBuilder, pathAndAst.fileIndex, importsAndExports.moduleExports);
	immutable FileAst ast = pathAndAst.ast;
	CheckCtx ctx = CheckCtx(
		ptrTrustMe(alloc),
		ptrTrustMe(perf),
		ptrTrustMe(programState),
		ptrTrustMe(allSymbols),
		pathAndAst.fileIndex,
		importsAndExports.moduleImports,
		importsAndExports.moduleExports,
		// TODO: use temp alloc
		newUsedImportsAndReExports(alloc, importsAndExports.moduleImports, importsAndExports.moduleExports),
		// TODO: use temp alloc
		makeFullIndexDict_mut!(ModuleLocalAliasIndex, bool)(
			alloc, ast.structAliases.length, (immutable(ModuleLocalAliasIndex)) => false),
		// TODO: use temp alloc
		makeFullIndexDict_mut!(ModuleLocalStructIndex, bool)(
			alloc, ast.structs.length, (immutable(ModuleLocalStructIndex)) => false),
		// TODO: use temp alloc
		makeFullIndexDict_mut!(ModuleLocalSpecIndex, bool)(
			alloc, ast.specs.length, (immutable(ModuleLocalSpecIndex)) => false),
		ptrTrustMe(diagsBuilder));

	// Since structs may refer to each other, first get a structsAndAliasesDict, *then* fill in bodies
	StructDecl[] structs = checkStructsInitial(ctx, ast.structs);
	StructAlias[] structAliases = checkStructAliasesInitial(ctx, ast.structAliases);
	immutable StructsAndAliasesDict structsAndAliasesDict =
		buildStructsAndAliasesDict(ctx, castImmutable(structs), castImmutable(structAliases));

	// We need to create StructInsts when filling in struct bodies.
	// But when creating a StructInst, we usually want to fill in its body.
	// In case the decl body isn't available yet,
	// we'll delay creating the StructInst body, which isn't needed until expr checking.
	MutArr!(StructInst*) delayStructInsts;

	immutable CommonTypes commonTypes = getCommonTypes(ctx, structsAndAliasesDict, delayStructInsts);

	checkStructAliasTargets(
		ctx,
		commonTypes,
		structsAndAliasesDict,
		structAliases,
		ast.structAliases,
		delayStructInsts);

	immutable Module res = checkWorkerAfterCommonTypes(
		ctx,
		commonTypes,
		structsAndAliasesDict,
		castImmutable(structAliases),
		structs,
		delayStructInsts,
		pathAndAst.fileIndex,
		importsAndExports,
		ast);
	return immutable BootstrapCheck(res, commonTypes);
}

void checkImportsOrExports(
	ref Alloc alloc,
	ref DiagnosticsBuilder diags,
	immutable FileIndex thisFile,
	immutable ImportOrExport[] imports,
) {
	foreach (ref immutable ImportOrExport x; imports)
		x.kind.match!void(
			(immutable(ImportOrExportKind.ModuleWhole)) {},
			(immutable ImportOrExportKind.ModuleNamed m) {
				foreach (ref immutable Sym name; m.names)
					if (!hasKey(m.module_.allExportedNames, name))
						addDiagnostic(
							alloc,
							diags,
							// TODO: use the range of the particular name
							// (by advancing pos by symSize until we get to this name)
							immutable FileAndRange(thisFile, force(x.importSource)),
							immutable Diag(immutable Diag.ImportRefersToNothing(name)));
			});
}
