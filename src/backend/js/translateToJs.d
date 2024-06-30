module backend.js.translateToJs;

@safe @nogc pure nothrow:

import backend.js.allUsed :
	AllUsed, allUsed, AnyDecl, bodyIsInlined, isModuleUsed, isUsedAnywhere, isUsedInModule, tryEvalConstantBool;
import backend.js.jsAst :
	genArrowFunction,
	genAssign,
	genBinary,
	genBlockStatement,
	genBool,
	genCall,
	genCallWithSpread,
	genConst,
	genEmptyStatement,
	genEqEqEq,
	genIf,
	genIife,
	genIn,
	genInstanceof,
	genIntegerLarge,
	genIntegerSigned,
	genIntegerUnsigned,
	genLet,
	genNew,
	genNot,
	genNull,
	genNumber,
	genObject,
	genOr,
	genPropertyAccess,
	genPropertyAccessComputed,
	genReturn,
	genString,
	genSwitch,
	genTernary,
	genThis,
	genThrow,
	genTryCatch,
	genTypeof,
	genUnary,
	genUndefined,
	genVarDecl,
	genWhile,
	JsArrowFunction,
	JsAssignStatement,
	JsBinaryExpr,
	JsBlockStatement,
	JsBreakStatement,
	JsCallExpr,
	JsClassDecl,
	JsClassMember,
	JsClassMemberKind,
	JsClassMethod,
	JsContinueStatement,
	JsDecl,
	JsDeclKind,
	JsDestructure,
	JsEmptyStatement,
	JsExpr,
	JsExprOrBlockStatement,
	JsIfStatement,
	JsImport,
	JsLiteralBool,
	JsLiteralNumber,
	JsLiteralString,
	JsModuleAst,
	JsName,
	JsObjectDestructure,
	JsParams,
	JsPropertyAccessExpr,
	JsReturnStatement,
	JsStatement,
	JsSwitchStatement,
	JsTernaryExpr,
	JsThrowStatement,
	JsTryFinallyStatement,
	JsUnaryExpr,
	JsVarDecl,
	JsWhileStatement;
import backend.js.writeJsAst : writeJsAst;
import frontend.ide.ideUtil : eachDescendentExprIncluding;
import model.ast : addExtension, ImportOrExportAstKind, PathOrRelPath;
import model.constant : asBool, Constant;
import model.model :
	asExtern,
	AssertOrForbidExpr,
	AutoFun,
	BogusExpr,
	Builtin4ary,
	BuiltinBinary,
	BuiltinBinaryLazy,
	BuiltinBinaryMath,
	BuiltinFun,
	BuiltinTernary,
	BuiltinType,
	BuiltinUnary,
	BuiltinUnaryMath,
	Called,
	CalledSpecSig,
	CallExpr,
	CallOptionExpr,
	ClosureGetExpr,
	ClosureSetExpr,
	CommonTypes,
	Condition,
	Config,
	countSigs,
	Destructure,
	eachImportOrReExport,
	emptySpecs,
	EnumFunction,
	EnumOrFlagsMember,
	Expr,
	ExprAndType,
	ExprKind,
	ExternExpr,
	FinallyExpr,
	FlagsFunction,
	FunBody,
	FunDecl,
	FunInst,
	FunPointerExpr,
	IfExpr,
	ImportOrExport,
	isVoid,
	JsFun,
	LambdaExpr,
	LetExpr,
	LiteralExpr,
	LiteralStringLikeExpr,
	Local,
	LocalGetExpr,
	LocalPointerExpr,
	LocalSetExpr,
	LoopExpr,
	LoopBreakExpr,
	LoopContinueExpr,
	LoopWhileOrUntilExpr,
	MatchEnumExpr,
	MatchIntegralExpr,
	MatchStringLikeExpr,
	MatchUnionExpr,
	MatchVariantExpr,
	Module,
	nameFromNameReferentsPointer,
	NameReferents,
	Params,
	paramTypeAt,
	Program,
	ProgramWithMain,
	RecordField,
	RecordFieldPointerExpr,
	SeqExpr,
	Signature,
	SpecDecl,
	SpecInst,
	Specs,
	StructAlias,
	StructBody,
	StructDecl,
	StructInst,
	ThrowExpr,
	TrustedExpr,
	TryExpr,
	TryLetExpr,
	Type,
	TypedExpr,
	TypeParamIndex,
	UnionMember,
	VarDecl,
	VariantAndMethodImpls,
	Visibility;
import util.alloc.alloc : Alloc;
import util.cell : Cell, cellGet, cellSet;
import util.col.array :
	concatenate,
	emptySmallArray,
	exists,
	foldReverse,
	isEmpty,
	makeArray,
	map,
	mapOp,
	mapWithIndex,
	mapZip,
	newArray,
	newSmallArray,
	only,
	prepend,
	small,
	SmallArray;
import util.col.arrayBuilder : add, ArrayBuilder, buildArray, Builder, buildSmallArray, finish, sizeSoFar;
import util.col.hashTable : mustGet, withSortedKeys;
import util.col.map : KeyValuePair, Map, mustGet;
import util.col.mutArr : MutArr, push;
import util.col.mutMap : addOrChange, getOrAdd, hasKey, mapToArray, moveToMap, mustAdd, mustDelete, mustGet, MutMap;
import util.col.mutMultiMap : add, MutMultiMap;
import util.col.set : Set;
import util.col.sortUtil : sortInPlace;
import util.col.tempSet : TempSet, tryAdd, withTempSet;
import util.conv : safeToUshort;
import util.integralValues : IntegralValue;
import util.memory : allocate;
import util.opt : force, has, MutOpt, none, Opt, optIf, optFromMut, optOrDefault, some, someMut;
import util.symbol : compareSymbolsAlphabetically, Extension, stringOfSymbol, Symbol, symbol;
import util.symbolSet : MutSymbolSet, SymbolSet, symbolSet;
import util.union_ : TaggedUnion, Union;
import util.uri :
	alterExtension,
	countComponents,
	firstNComponents,
	isAncestor,
	parent,
	parsePath,
	Path,
	pathFromAncestor,
	prefixPathComponent,
	RelPath,
	relativePath,
	resolvePath,
	Uri;
import util.util : min, ptrTrustMe, stringOfEnum, todo, typeAs;
import versionInfo : isVersion, OS, VersionFun, VersionInfo, versionInfoForBuildToJS;

immutable struct TranslateToJsResult {
	KeyValuePair!(Path, string)[] outputFiles;
}
TranslateToJsResult translateToJs(ref Alloc alloc, ref ProgramWithMain program, OS os, bool isNodeJs) {
	// TODO: Start with the 'main' function to determine everything that is actually used. ------------------------------------------------
	// We need to start with the modules with no dependencies and work down...
	VersionInfo version_ = versionInfoForBuildToJS(os, isNodeJs);
	SymbolSet allExtern = allExternForJs(isNodeJs: isNodeJs);
	AllUsed allUsed = allUsed(alloc, program, version_, allExtern);
	Map!(Uri, Path) modulePaths = modulePaths(alloc, program);
	TranslateProgramCtx ctx = TranslateProgramCtx(
		ptrTrustMe(alloc),
		program.program.commonTypes,
		version_,
		allExtern,
		allUsed,
		modulePaths,
		moduleExportMangledNames(alloc, program.program, allUsed));
	
	foreach (Module* module_; program.program.rootModules)
		doTranslateModule(ctx, module_);
	return TranslateToJsResult(getOutputFiles(alloc, modulePaths, program.mainFun.fun.decl.moduleUri, ctx.done, isNodeJs: isNodeJs));
}

private:

Map!(Uri, Path) modulePaths(ref Alloc alloc, in ProgramWithMain program) {
	Module* main = only(program.program.rootModules);
	Uri mainCommon = findCommonMainDirectory(main);
	MutMap!(Uri, Path) res;
	void recur(in Module x, Opt!Path fromPath, PathOrRelPath pr) @safe @nogc nothrow {
		if (!hasKey(res, x.uri)) {
			Path path = pr.match!Path(
				(Path x) => x,
				(RelPath x) => force(resolvePath(force(parent(force(fromPath))), x)));
			mustAdd(alloc, res, x.uri, alterExtension(path, Extension.js));
			eachImportOrReExport(x, (ref ImportOrExport im) @safe nothrow {
				recur(im.module_, some(path), has(im.source) ? force(im.source).path : PathOrRelPath(parsePath("crow/std")));
			});
		}
	}
	recur(*main, none!Path, PathOrRelPath(prefixPathComponent(symbol!"main", pathFromAncestor(mainCommon, main.uri))));
	return moveToMap(alloc, res);
}
Uri findCommonMainDirectory(in Module* main) {
	// First: Find the common URI for all modules accessible from 'main' through relative imports.
	size_t minComponents = countComponents(main.uri);
	eachRelativeImportModule(main, (Module* x) {
		minComponents = min(minComponents, countComponents(x.uri));
	});

	assert(minComponents > 0);
	Uri res = firstNComponents(main.uri, minComponents - 1);
	eachRelativeImportModule(main, (Module* x) {
		assert(isAncestor(res, x.uri));
	});
	return res;
}

Opt!Path optPath(PathOrRelPath a) =>
	a.match!(Opt!Path)(
		(Path x) => some(x),
		(RelPath _) => none!Path);

void eachRelativeImportModule(Module* main, in void delegate(Module*) @safe @nogc pure nothrow cb) {
	// TODO: imports aren't recursive, so why did I think I needed a set? ---------------------------------------------------------
	withTempSet!(void, Module*)(0x100, (scope ref TempSet!(Module*) seen) {
		void recur(Module* x) @safe @nogc nothrow {
			if (tryAdd(seen, x)) {
				cb(x);
				eachImportOrReExport(*x, (ref ImportOrExport im) @safe nothrow {
					if (has(im.source) && force(im.source).path.isA!RelPath) {
						recur(im.modulePtr);
					}
				});
			}
		}
		recur(main);
	});
}

SymbolSet allExternForJs(bool isNodeJs) { // TODO: we'll eventually want to have 'browser' exclusive functions? ---------------------------------
	MutSymbolSet res = symbolSet(symbol!"js");
	return isNodeJs
		// TODO: I don't know about adding e.g. 'windows' here. node.js is supposed to be cross-platform... ---------------------
		? res.add(symbol!"node-js")
		: res.add(symbol!"browser");
}

immutable(KeyValuePair!(Path, string)[]) getOutputFiles(
	ref Alloc alloc,
	in Map!(Uri, Path) modulePaths,
	Uri mainModuleUri,
	in MutMap!(Module*, Opt!JsModuleAst) done,
	bool isNodeJs,
) =>
	buildArray!(immutable KeyValuePair!(Path, string))(alloc, (scope ref Builder!(immutable KeyValuePair!(Path, string)) out_) {
		if (isNodeJs)
			out_ ~= immutable KeyValuePair!(Path, string)(parsePath("package.json"), "{\"type\":\"module\"}");
		foreach (const Module* module_, ref Opt!JsModuleAst ast; done)
			if (has(ast))
				out_ ~= immutable KeyValuePair!(Path, string)(
					mustGet(modulePaths, module_.uri),
					writeJsAst(alloc, force(ast), module_.uri == mainModuleUri));
	});

struct TranslateProgramCtx {
	@safe @nogc pure nothrow:

	Alloc* allocPtr;
	immutable CommonTypes* commonTypes;
	immutable VersionInfo version_;
	immutable SymbolSet allExtern;
	immutable AllUsed allUsed;
	immutable Map!(Uri, Path) modulePaths;
	immutable ModuleExportMangledNames exportMangledNames;
	// None for unused modules
	MutMap!(Module*, Opt!JsModuleAst) done; // TODO: maybe move this outside of TranslateProgramCtx. It's only used in doTranslateModule

	ref Alloc alloc() =>
		*allocPtr;
}

void doTranslateModule(ref TranslateProgramCtx ctx, Module* a) {
	if (hasKey(ctx.done, a)) return;
	foreach (ImportOrExport x; a.imports)
		doTranslateModule(ctx, x.modulePtr);
	foreach (ImportOrExport x; a.reExports)
		doTranslateModule(ctx, x.modulePtr);
	// Test 'isModuleUsed' last, because an unused module can still have used re-exports
	mustAdd(ctx.alloc, ctx.done, a, optIf(isModuleUsed(ctx.allUsed, a.uri), () =>
		translateModule(ctx, *a)));
}

JsModuleAst translateModule(ref TranslateProgramCtx ctx, ref Module a) {
	MutMap!(StructDecl*, StructAlias*) aliases;
	JsImport[] imports = translateImports(ctx, a, aliases);
	JsImport[] reExports = translateReExports(ctx, a);
	TranslateModuleCtx moduleCtx = TranslateModuleCtx(
		ctx.allocPtr,
		ctx.commonTypes,
		ctx.version_,
		ctx.allExtern,
		ptrTrustMe(ctx.allUsed),
		ptrTrustMe(ctx.exportMangledNames),
		modulePrivateMangledNames(ctx.alloc, a, ctx.exportMangledNames, ctx.allUsed),
		moveToMap(ctx.alloc, aliases));
	JsDecl[] decls = buildArray!JsDecl(ctx.alloc, (scope ref Builder!JsDecl out_) {
		eachDeclInModule(a, (AnyDecl x) {
			if (isUsedAnywhere(ctx.allUsed, x)) {
				out_ ~= translateDecl(moduleCtx, x);
			}
		});
	});
	return JsModuleAst(a.uri, imports, reExports, decls);
}

struct TranslateModuleCtx {
	@safe @nogc pure nothrow:
	Alloc* allocPtr;
	immutable CommonTypes* commonTypesPtr;
	immutable VersionInfo version_;
	immutable SymbolSet allExtern;
	immutable AllUsed* allUsedPtr;
	immutable ModuleExportMangledNames* exportMangledNames;
	immutable Map!(AnyDecl, ushort) privateMangledNames;
	immutable Map!(StructDecl*, StructAlias*) aliases;

	ref Alloc alloc() =>
		*allocPtr;
	ref CommonTypes commonTypes() =>
		*commonTypesPtr;
	ref AllUsed allUsed() =>
		*allUsedPtr;

	bool isBrowser() =>
		allExtern.has(symbol!"browser");
}

struct TranslateExprCtx {
	@safe @nogc pure nothrow:
	TranslateModuleCtx* ctxPtr;
	FunDecl* curFun;

	ref TranslateModuleCtx ctx() =>
		*ctxPtr;
	alias ctx this; // -------------------------------------------------------------------------------------------------------------------------------
}

JsName mangledNameForDecl(in TranslateModuleCtx ctx, in AnyDecl a) =>
	JsName(
		a.name,
		(a.visibility == Visibility.private_ ? ctx.privateMangledNames : ctx.exportMangledNames.mangledNames)[a]);
JsName aliasName(in TranslateModuleCtx ctx, in StructAlias* a) =>
	mangledNameForDecl(ctx, AnyDecl(a));
JsName funName(in TranslateModuleCtx ctx, in FunDecl* a) =>
	mangledNameForDecl(ctx, AnyDecl(a));
JsExpr translateFunReference(in TranslateModuleCtx ctx, in FunDecl* a) =>
	JsExpr(funName(ctx, a));
JsName specName(in TranslateModuleCtx ctx, in SpecDecl* a) =>
	mangledNameForDecl(ctx, AnyDecl(a));
JsName structName(in TranslateModuleCtx ctx, in StructDecl* a) =>
	mangledNameForDecl(ctx, AnyDecl(a));
JsExpr translateStructReference(in TranslateModuleCtx ctx, in StructDecl* a) =>
	JsExpr(structName(ctx, a));
JsName varName(in TranslateModuleCtx ctx, in VarDecl* a) =>
	mangledNameForDecl(ctx, AnyDecl(a));
JsExpr translateVarReference(in TranslateModuleCtx ctx, in VarDecl* a) =>
	JsExpr(varName(ctx, a));

immutable struct ModuleExportMangledNames {
	// Maps any kind of declaration to its name index.
	// So 'foo' will be renamed 'foo__1'
	// If no mangling is necessary, it won't be in here.
	// This is used to get the first index for local names.
	Map!(Symbol, ushort) indexForName;
	// Key is some decl, e.g. StructDecl*.
	// If it's not in the map, don't mangle it.
	Map!(AnyDecl, ushort) mangledNames;
}
ModuleExportMangledNames moduleExportMangledNames(ref Alloc alloc, in Program program, in AllUsed used) {
	MutMap!(Symbol, ushort) indexForName;
	MutMap!(AnyDecl, ushort) res;
	eachExportDeclInProgram(program, (AnyDecl decl) {
		if (isUsedAnywhere(used, decl)) {
			ushort index = addOrChange!(Symbol, ushort)(alloc, indexForName, decl.name, () => ushort(0), (ref ushort x) { x++; });
			mustAdd(alloc, res, decl, index);
		}
	});
	// For uniquely identified decls, don't mangle
	eachExportDeclInProgram(program, (AnyDecl decl) {
		if (isUsedAnywhere(used, decl) && mustGet(indexForName, decl.name) == 0)
			mustDelete(res, decl);
	});
	return ModuleExportMangledNames(moveToMap(alloc, indexForName), moveToMap(alloc, res));
}

Map!(AnyDecl, ushort) modulePrivateMangledNames(ref Alloc alloc, in Module module_, in ModuleExportMangledNames exports_, in AllUsed used) {
	MutMap!(Symbol, ushort) indexForName;
	MutMap!(AnyDecl, ushort) res; // TODO: share code with 'moduleExportMangledNames'? ---------------------------------------
	eachPrivateDeclInModule(module_, (AnyDecl decl) {
		if (isUsedInModule(used, module_.uri, decl)) {
			ushort index = addOrChange!(Symbol, ushort)(alloc, indexForName, decl.name, () => optOrDefault!ushort(exports_.indexForName[decl.name], () => typeAs!ushort(0)), (ref ushort x) { x++; });
			mustAdd(alloc, res, decl, index);
		}
	});
	eachPrivateDeclInModule(module_, (AnyDecl decl) {
		if (isUsedInModule(used, module_.uri, decl) && mustGet(indexForName, decl.name) == 0)
			mustDelete(res, decl);
	});
	return moveToMap(alloc, res);
}
JsName localName(in Local a) =>
	JsName(a.name, some!ushort(99));

void eachExportDeclInProgram(ref Program a, in void delegate(AnyDecl) @safe @nogc pure nothrow cb) {
	foreach (ref immutable Module* x; a.allModules)
		eachNonPrivateDeclInModule(*x, cb);
}
void eachNameReferent(NameReferents a, in void delegate(AnyDecl) @safe @nogc pure nothrow cb) {
	if (has(a.structOrAlias))
		cb(force(a.structOrAlias).matchWithPointers!AnyDecl(
			(StructAlias* x) => AnyDecl(x),
			(StructDecl* x) => AnyDecl(x)));
	if (has(a.spec))
		cb(AnyDecl(force(a.spec)));
	foreach (FunDecl* x; a.funs)
		cb(AnyDecl(x));
}

void eachPrivateDeclInModule(ref Module a, in void delegate(AnyDecl) @safe @nogc pure nothrow cb) {
	eachDeclInModule(a, (AnyDecl x) {
		if (x.visibility == Visibility.private_)
			cb(x);
	});
}
void eachNonPrivateDeclInModule(ref Module a, in void delegate(AnyDecl) @safe @nogc pure nothrow cb) {
	eachDeclInModule(a, (AnyDecl x) {
		if (x.visibility != Visibility.private_)
			cb(x);
	});
}
void eachDeclInModule(ref Module a, in void delegate(AnyDecl) @safe @nogc pure nothrow cb) {
	foreach (ref StructAlias x; a.aliases)
		cb(AnyDecl(&x));
	foreach (ref StructDecl x; a.structs)
		cb(AnyDecl(&x));
	foreach (ref VarDecl x; a.vars)
		cb(AnyDecl(&x));
	foreach (ref SpecDecl x; a.specs)
		cb(AnyDecl(&x));
	foreach (ref FunDecl x; a.funs)
		cb(AnyDecl(&x));
	// TODO: tests ---------------------------------------------------------------------------------------------------------
}

JsImport[] translateImports(
	ref TranslateProgramCtx ctx,
	in Module module_,
	scope ref MutMap!(StructDecl*, StructAlias*) aliases,
) {
	// TODO: do this in a separate function? -----------------------------------------------------------------------------
	eachImportOrReExport(module_, (ref ImportOrExport x) {
		if (!x.hasImported) return;
		foreach (ref immutable NameReferents* refs; x.imported) {
			eachNameReferent(*refs, (AnyDecl decl) {
				if (decl.isA!(StructAlias*)) {
					StructAlias* alias_ = decl.as!(StructAlias*);
					StructDecl* target = alias_.target.decl;
					if (isUsedInModule(ctx.allUsed, module_.uri, AnyDecl(target))) {
						// If multiple aliases, just use the first
						getOrAdd!(StructDecl*, StructAlias*)(ctx.alloc, aliases, target, () => alias_);
					}
				}
			});
		}
	});

	Opt!(Set!AnyDecl) opt = ctx.allUsed.usedByModule[module_.uri];	
	if (has(opt)) {
		Path importerPath = mustGet(ctx.modulePaths, module_.uri);
		// TODO: PERF ---------------------------------------------------------------------------------------------------------------------------
		MutMap!(Uri, MutArr!AnyDecl) byModule;
		foreach (AnyDecl x; force(opt))
			if (x.moduleUri != module_.uri) { // TODO: maybe it shouldn't be added to usedByModule in that case ------------------
				push(ctx.alloc, getOrAdd(ctx.alloc, byModule, x.moduleUri, () => MutArr!AnyDecl()), x);
			}
		return buildArray!JsImport(ctx.alloc, (scope ref Builder!JsImport outImports) {
			foreach (Uri importedUri, ref MutArr!AnyDecl decls; byModule) {
				JsName[] names = buildArray!JsName(ctx.alloc, (scope ref Builder!JsName out_) {
					foreach (ref const AnyDecl decl; decls)
						out_ ~= JsName(decl.name, ctx.exportMangledNames.mangledNames[decl]);
				});
				sortInPlace!JsName(names, (in JsName x, in JsName y) =>
					compareSymbolsAlphabetically(x.crowName, y.crowName)); // TODO: also compare by mangleIndex --------------------
				outImports ~= JsImport(some(names), relativePath(importerPath, mustGet(ctx.modulePaths, importedUri)));
			}
		});
	} else
		return [];
}

JsImport[] translateReExports(ref TranslateProgramCtx ctx, in Module module_) {
	Path importerPath = mustGet(ctx.modulePaths, module_.uri);
	return mapOp!(JsImport, ImportOrExport)(ctx.alloc, module_.reExports, (ref ImportOrExport x) {
		RelPath relPath() => relativePath(importerPath, mustGet(ctx.modulePaths, x.module_.uri));
		if (isImportModuleWhole(x)) // TODO: I think we still need to track aliases used by a re-exporting module
			return optIf(isModuleUsed(ctx.allUsed, x.module_.uri), () =>
				JsImport(none!(JsName[]), relPath));
		else {
			JsName[] names = buildArray(ctx.alloc, (scope ref Builder!JsName out_) {
				withSortedKeys!(void, NameReferents*, Symbol, nameFromNameReferentsPointer)(
					x.imported,
					(in Symbol x, in Symbol y) => compareSymbolsAlphabetically(x, y),
					(in Symbol[] names) {
						foreach (Symbol name; names) {
							eachNameReferent(*mustGet(x.imported, name), (AnyDecl decl) {
								if (isUsedAnywhere(ctx.allUsed, decl))
									out_ ~= JsName(name, ctx.exportMangledNames.mangledNames[decl]);
								else if (decl.isA!(StructAlias*)) {
									StructAlias* alias_ = decl.as!(StructAlias*);
									StructDecl* target = alias_.target.decl;
									if (isUsedAnywhere(ctx.allUsed, AnyDecl(target)))
										out_ ~= JsName(name, ctx.exportMangledNames.mangledNames[decl]);
								}
							});
						}
					});
			});
			return optIf(!isEmpty(names), () => JsImport(some(names), relPath));
		}
	});
}
bool isImportModuleWhole(in ImportOrExport x) =>
	!has(x.source) || force(x.source).kind.isA!(ImportOrExportAstKind.ModuleWhole);

JsDecl translateDecl(ref TranslateModuleCtx ctx, AnyDecl x) =>
	x.matchWithPointers!JsDecl(
		(FunDecl* x) =>
			translateFunDecl(ctx, x),
		(SpecDecl* x) =>
			translateSpecDecl(ctx, x),
		(StructAlias* x) =>
			translateStructAlias(ctx, x),
		(StructDecl* x) =>
			translateStructDecl(ctx, x),
		(VarDecl* x) =>
			translateVarDecl(ctx, x));

JsDecl makeDecl(Visibility visibility, JsName name, JsDeclKind value) =>
	JsDecl(visibility == Visibility.private_ ? JsDecl.Exported.private_ : JsDecl.Exported.export_, name, value);

JsDecl translateFunDecl(ref TranslateModuleCtx ctx, FunDecl* a) {
	JsParams params = translateFunParams(ctx, a.params);
	JsExpr fun = genArrowFunction(params, translateFunBody(ctx, a));
	JsExpr funWithSpecs = isEmpty(a.specs)
		? fun
		: genArrowFunction(JsParams(specParams(ctx.alloc, *a)), JsExprOrBlockStatement(allocate(ctx.alloc, fun)));
	return makeDecl(a.visibility, funName(ctx, a), JsDeclKind(funWithSpecs));
}
SmallArray!JsDestructure specParams(ref Alloc alloc, in FunDecl a) =>
	buildSmallArray!JsDestructure(alloc, (scope ref Builder!JsDestructure out_) {
		eachSpecInFunIncludingParents(a, (SpecInst* spec) {
			foreach (ref Signature x; spec.decl.sigs)
				out_ ~= JsDestructure(JsName(x.name, some(safeToUshort(sizeSoFar(out_)))));
		});
	});
void eachSpecInFunIncludingParents(in FunDecl a, in void delegate(SpecInst*) @safe @nogc pure nothrow cb) {
	foreach (SpecInst* spec; a.specs)
		eachSpecIncludingParents(spec, cb);
}
void eachSpecIncludingParents(SpecInst* a, in void delegate(SpecInst*) @safe @nogc pure nothrow cb) { // todo: move ?-----------------
	foreach (SpecInst* parent; a.parents)
		eachSpecIncludingParents(parent, cb);
	cb(a);
}

JsParams translateFunParams(ref TranslateModuleCtx ctx, in Params a) =>
	a.match!JsParams(
		(Destructure[] xs) =>
			JsParams(map!(JsDestructure, Destructure)(ctx.alloc, small!Destructure(xs), (ref Destructure x) =>
				translateDestructure(ctx, x))),
		(ref Params.Varargs x) =>
			JsParams(emptySmallArray!JsDestructure, some(translateDestructure(ctx, x.param))));
JsDestructure translateDestructure(ref TranslateModuleCtx ctx, in Destructure a) =>
	a.matchIn!JsDestructure(
		(in Destructure.Ignore) =>
			JsDestructure(JsName(symbol!"_")),
		(in Local x) =>
			JsDestructure(localName(x)),
		(in Destructure.Split x) =>
			translateDestructureSplit(ctx, x));
JsDestructure translateDestructureSplit(ref TranslateModuleCtx ctx, in Destructure.Split x) {
	SmallArray!RecordField fields = x.destructuredType.as!(StructInst*).decl.body_.as!(StructBody.Record).fields; // TODO: destructuredType will be Bogus if there's a compile error
	return JsDestructure(JsObjectDestructure(mapZip!(immutable KeyValuePair!(Symbol, JsDestructure), RecordField, Destructure)(
		ctx.alloc, fields, x.parts, (ref RecordField field, ref Destructure part) =>
			immutable KeyValuePair!(Symbol, JsDestructure)(field.name, translateDestructure(ctx, part)))));
}

JsDecl translateSpecDecl(ref TranslateModuleCtx ctx, in SpecDecl* a) =>
	makeDecl(a.visibility, specName(ctx, a), JsDeclKind(genNull()));

JsDecl translateStructAlias(ref TranslateModuleCtx ctx, in StructAlias* a) =>
	makeDecl(a.visibility, aliasName(ctx, a), JsDeclKind(JsExpr(JsName(a.target.decl.name))));

JsDecl translateStructDecl(ref TranslateModuleCtx ctx, in StructDecl* a) {
	if (a.body_.isA!BuiltinType)
		return makeDecl(a.visibility, structName(ctx, a), JsDeclKind(genNull()));

	MutOpt!(JsExpr*) extends;
	JsClassMember[] members = buildArray!JsClassMember(ctx.alloc, (scope ref Builder!JsClassMember out_) {
		foreach (ref VariantAndMethodImpls v; a.variants) {
			if (v.variant == ctx.commonTypes.exception)
				extends = someMut(allocate(ctx.alloc, translateStructReference(ctx, v.variant.decl)));
		}
		bool needSuper = has(extends);

		a.body_.match!void(
			(StructBody.Bogus) =>
				todo!void("BOGUS TYPE"),
			(BuiltinType x) =>
				assert(false),
			(ref StructBody.Enum x) {
				translateEnumDecl(ctx, out_, needSuper, x);
			},
			(StructBody.Extern) =>
				assert(false),
			(StructBody.Flags) =>
				todo!void("FLAGS"), // ------------------------------------------------------------------------------------------------------
			(StructBody.Record x) {
				translateRecord(ctx, out_, needSuper, x);
			},
			(ref StructBody.Union x) {
				translateUnion(ctx, out_, needSuper, x);
			},
			(StructBody.Variant) {
				if (a == ctx.commonTypes.exception.decl)
					extends = someMut(allocate(ctx.alloc, JsExpr(JsName(symbol!"Error"))));
			});

		foreach (ref VariantAndMethodImpls v; a.variants)
			foreach (Opt!Called impl; v.methodImpls)
				if (has(impl))
					out_ ~= variantMethodImpl(ctx, force(impl));
	});
	return makeDecl(a.visibility, structName(ctx, a), JsDeclKind(JsClassDecl(optFromMut!(JsExpr*)(extends), members)));
}

JsClassMember variantMethodImpl(ref TranslateModuleCtx ctx, Called a) {
	JsClassMethod method = () {
		if (isInlined(a)) {
			FunDecl* decl = a.as!(FunInst*).decl;
			return JsClassMethod(
				translateFunParams(ctx, decl.params),
				translateToBlockStatement(ctx.alloc, (scope ExprPos pos) =>
					translateInlineCall(ctx, a.returnType, pos, decl.body_, a.paramTypes, a.arity.as!uint, (size_t i) =>
						JsExpr(localName(*decl.params.as!(Destructure[])[i].as!(Local*))))));
		} else {
			// foo(...args) { return foo(this, ...args) }
			JsName args = JsName(symbol!"args");
			JsParams params = JsParams(emptySmallArray!JsDestructure, some(JsDestructure(args)));
			JsBlockStatement body_ = genBlockStatement(ctx.alloc, [
				genReturn(ctx.alloc, genCallWithSpread(ctx.alloc, calledExpr(ctx, none!(FunDecl*), a), [genThis()], JsExpr(args)))]);
			return JsClassMethod(params, body_);
		}
	}();
	return JsClassMember(JsClassMember.Static.instance, a.name, JsClassMemberKind(method));
}

void translateEnumDecl(ref TranslateModuleCtx ctx, scope ref Builder!JsClassMember out_, bool needSuper, ref StructBody.Enum a) {
	/*
	class E {
		constructor(name) { this.name = name }
		static x = new this("x")
	}
	*/
	JsName name = JsName(symbol!"name");
	out_ ~= genConstructorIn(ctx.alloc, [JsDestructure(name)], needSuper, [
		genAssign(ctx.alloc, genPropertyAccess(ctx.alloc, genThis(), symbol!"name"), JsExpr(name))]);
	foreach (ref EnumOrFlagsMember member; a.members) {
		out_ ~= JsClassMember(JsClassMember.Static.static_, member.name, JsClassMemberKind(
			genNew(ctx.alloc, genThis(), [genString(stringOfSymbol(ctx.alloc, member.name))])));
	}
}

void translateRecord(ref TranslateModuleCtx ctx, scope ref Builder!JsClassMember out_, bool needSuper, ref StructBody.Record a) {
	/*
	class R {
		constructor(x, fooBar) {
			this.x = x
			this["foo-bar"] = fooBar
		}
	}
	*/
	out_ ~= genConstructor(
		ctx.alloc,
		map!(JsDestructure, RecordField)(ctx.alloc, a.fields, (ref RecordField x) =>
			JsDestructure(JsName(x.name))), 
		needSuper,
		// TODO: use temp alloc (since needSuper is prepended) -----------------------------------------------------------------
		map(ctx.alloc, a.fields, (ref RecordField x) =>
			genAssign(ctx.alloc, genPropertyAccess(ctx.alloc, genThis(), x.name), JsExpr(JsName(x.name)))));
}

void translateUnion(ref TranslateModuleCtx ctx, scope ref Builder!JsClassMember out_, bool needSuper, ref StructBody.Union a) {
	/*
	class U {
		constructor(arg) {
			Object.assign(this, arg)
		}
		static foo = new this({foo:null})
		static bar(value) {
			return new this({bar:value})
		}
	}
	*/
	JsName arg = JsName(symbol!"arg");
	out_ ~= genConstructorIn(ctx.alloc, [JsDestructure(arg)], needSuper, [
		JsStatement(genCall(
			ctx.alloc,
			genPropertyAccess(ctx.alloc, JsExpr(JsName(symbol!"Object")), symbol!"assign"),
			[genThis(), JsExpr(arg)]))]);
	
	foreach (ref UnionMember member; a.members) {
		JsClassMemberKind kind = () {
			if (member.hasValue) {
				JsName value = JsName(symbol!"value");
				JsParams params = JsParams(newSmallArray!JsDestructure(ctx.alloc, [JsDestructure(value)]));
				return JsClassMemberKind(JsClassMethod( // TODO: use a 'gen...' helper ----------------------------------------------------------------
					params,
					genBlockStatement(ctx.alloc, [
						genReturn(ctx.alloc, genNew(ctx.alloc, genThis(), [genObject(ctx.alloc, member.name, JsExpr(value))]))])));
			} else
				return JsClassMemberKind(genNew(ctx.alloc, genThis(), [genObject(ctx.alloc, member.name, genNull())]));
		}();
		out_ ~= JsClassMember(JsClassMember.Static.static_, member.name, kind);
	}
}

JsClassMember genConstructorIn(ref Alloc alloc, in JsDestructure[] params, bool needSuper, in JsStatement[] body_) =>
	genConstructor(alloc, newSmallArray(alloc, params), needSuper, newArray(alloc, body_));
JsClassMember genConstructor(ref Alloc alloc, SmallArray!JsDestructure params, bool needSuper, JsStatement[] body_) =>
	JsClassMember(
		JsClassMember.Static.instance,
		symbol!"constructor",
		JsClassMemberKind(JsClassMethod(
			JsParams(params),
			JsBlockStatement(needSuper ? prepend(alloc, genSuper(), body_) : body_))));

JsExpr super_ = JsExpr(JsName(symbol!"super"));
JsStatement genSuper() => JsStatement(genCall(&super_, []));

JsDecl translateVarDecl(ref TranslateModuleCtx ctx, VarDecl* a) =>
	todo!JsDecl("Use 'let' (same for global / thread-local)");

JsExprOrBlockStatement translateFunBody(ref TranslateModuleCtx ctx, FunDecl* fun) {
	if (fun.body_.isA!(FunBody.FileImport))
		return todo!JsExprOrBlockStatement("FileImport body"); // -----------------------------------------------------------------------------------------------------
	else {
		if (fun.body_.isA!Expr) {
			TranslateExprCtx exprCtx = TranslateExprCtx(ptrTrustMe(ctx), fun);
			return translateExprToExprOrBlockStatement(exprCtx, fun.body_.as!Expr, fun.returnType);
		} else {
			Destructure[] params = fun.params.as!(Destructure[]);
			Type[] paramTypes = map(ctx.alloc, params, (ref Destructure x) => x.type); // TODO: NO ALLOC ---------------------------
			return translateToExprOrBlockStatement(ctx.alloc, (scope ExprPos pos) =>
				translateInlineCall(ctx, fun.returnType, pos, fun.body_, paramTypes, params.length, (size_t i) =>
					translateLocalGet(params[i].as!(Local*))));
		}
	}
}

struct ExprPos {
	immutable struct Expression {}
	immutable struct ExpressionOrBlockStatement {} // Used for return from a function (since an arrow function can be an expression or a block)
	// If the expression is non-void, the statement should 'return'
	struct Statements { ArrayBuilder!JsStatement statements; }
	mixin TaggedUnion!(Expression, ExpressionOrBlockStatement, Statements*);
}
immutable struct ExprResult {
	@safe @nogc pure nothrow:

	immutable struct Done {}
	mixin Union!(Done, JsExpr, JsBlockStatement);

	static ExprResult done() =>
		ExprResult(ExprResult.Done());
}

JsExpr translateExprToExpr(ref TranslateExprCtx ctx, ExprAndType a) =>
	translateExprToExpr(ctx, a.expr, a.type);
JsExpr translateExprToExpr(ref TranslateExprCtx ctx, ref Expr a, Type type) =>
	translateExpr(ctx, a, type, ExprPos(ExprPos.Expression())).as!JsExpr;
alias TranslateCb = ExprResult delegate(scope ExprPos) @safe @nogc pure nothrow;
JsExpr translateToExpr(in TranslateCb cb) =>
	cb(ExprPos(ExprPos.Expression())).as!JsExpr;
JsStatement translateToStatement(ref Alloc alloc, in TranslateCb cb) =>
	translateToStatement(alloc, (scope ref ArrayBuilder!JsStatement, scope ExprPos pos) => cb(pos));
alias StatementsCb = ExprResult delegate(scope ref ArrayBuilder!JsStatement, scope ExprPos) @safe @nogc pure nothrow;
JsStatement translateToStatement(ref Alloc alloc, in StatementsCb cb) {
	JsStatement[] statements = translateToStatements(alloc, cb);
	return statements.length == 1 ? only(statements) : JsStatement(JsBlockStatement(statements));
}
JsBlockStatement translateToBlockStatement(ref Alloc alloc, in StatementsCb cb) =>
	JsBlockStatement(translateToStatements(alloc, cb));
JsBlockStatement translateToBlockStatement(ref Alloc alloc, in TranslateCb cb) =>
	translateToBlockStatement(alloc, (scope ref ArrayBuilder!JsStatement, scope ExprPos pos) => cb(pos));
JsStatement[] translateToStatements(ref Alloc alloc, in StatementsCb cb) {
	ExprPos.Statements pos;
	ExprResult res = cb(pos.statements, ExprPos(&pos));
	assert(res.isA!(ExprResult.Done));
	JsStatement[] statements = finish(alloc, pos.statements);
	assert(!isEmpty(statements));
	return statements;
}

JsStatement translateExprToStatement(ref TranslateExprCtx ctx, ref Expr a, Type type) =>
	translateToStatement(ctx.alloc, (scope ExprPos pos) => translateExpr(ctx, a, type, pos));
JsBlockStatement translateExprToBlockStatement(ref TranslateExprCtx ctx, ref Expr a, Type type) =>
	translateToBlockStatement(ctx.alloc, (scope ExprPos pos) => translateExpr(ctx, a, type, pos));
JsExprOrBlockStatement translateExprToExprOrBlockStatement(ref TranslateExprCtx ctx, ref Expr a, Type type) =>
	toExprOrBlockStatement(ctx.alloc, translateExpr(ctx, a, type, ExprPos(ExprPos.ExpressionOrBlockStatement())));
JsExprOrBlockStatement translateToExprOrBlockStatement(ref Alloc alloc, in TranslateCb cb) =>
	toExprOrBlockStatement(alloc, cb(ExprPos(ExprPos.ExpressionOrBlockStatement())));
JsExprOrBlockStatement toExprOrBlockStatement(ref Alloc alloc, ExprResult result) =>
	result.match!JsExprOrBlockStatement(
		(ExprResult.Done) =>
			assert(false),
		(JsExpr x) =>
			JsExprOrBlockStatement(allocate(alloc, x)),
		(JsBlockStatement x) =>
			JsExprOrBlockStatement(x));

ExprResult forceExpr(ref TranslateExprCtx ctx, scope ExprPos pos, Type type, JsExpr expr) =>
	forceExpr(ctx.alloc, pos, type, expr);
ExprResult forceExpr(ref Alloc alloc, scope ExprPos pos, Type type, JsExpr expr) =>
	pos.match!ExprResult(
		(ExprPos.Expression) =>
			ExprResult(expr),
		(ExprPos.ExpressionOrBlockStatement) =>
			ExprResult(expr),
		(ref ExprPos.Statements x) {
			add(alloc, x.statements, isVoid(type) ? JsStatement(expr) : genReturn(alloc, expr));
			return ExprResult.done;
		});
ExprResult forceStatements(ref TranslateExprCtx ctx, scope ExprPos pos, in ExprResult delegate(scope ref ArrayBuilder!JsStatement, scope ExprPos) @safe @nogc pure nothrow cb) =>
	pos.match!ExprResult(
		(ExprPos.Expression) =>
			ExprResult(genIife(ctx.alloc, makeBlockStatement(ctx.alloc, cb))),
		(ExprPos.ExpressionOrBlockStatement) =>
			ExprResult(makeBlockStatement(ctx.alloc, cb)),
		(ref ExprPos.Statements x) =>
			cb(x.statements, pos));
JsBlockStatement makeBlockStatement(ref Alloc alloc, in ExprResult delegate(scope ref ArrayBuilder!JsStatement, scope ExprPos) @safe @nogc pure nothrow cb) {
	ExprPos.Statements res;
	ExprResult inner = cb(res.statements, ExprPos(&res));
	assert(inner.isA!(ExprResult.Done));
	return JsBlockStatement(finish(alloc, res.statements));
}

ExprResult forceStatement(ref TranslateExprCtx ctx, scope ExprPos pos, JsStatement statement) =>
	forceStatement(ctx.alloc, pos, statement);
ExprResult forceStatement(ref Alloc alloc, scope ExprPos pos, JsStatement statement) =>
	pos.match!ExprResult(
		(ExprPos.Expression) =>
			todo!ExprResult("USE AN IIFE"),
		(ExprPos.ExpressionOrBlockStatement) =>
			ExprResult(genBlockStatement(alloc, [statement])),
		(ref ExprPos.Statements x) {
			add(alloc, x.statements, statement);
			return ExprResult.done;
		});

ExprResult translateExpr(ref TranslateExprCtx ctx, ref Expr a, Type type, scope ExprPos pos) =>
	a.kind.match!ExprResult(
		(ref AssertOrForbidExpr x) =>
			translateAssertOrForbid(ctx, x, type, pos),
		(BogusExpr x) =>
			forceStatement(ctx, pos, genThrowError(ctx.ctx, "Reached compile error")),
		(CallExpr x) =>
			translateCall(ctx, x, type, pos),
		(ref CallOptionExpr x) =>
			todo!ExprResult("CALL OPTION"),
		(ClosureGetExpr x) =>
			forceExpr(ctx, pos, type, JsExpr(localName(*x.local))),
		(ClosureSetExpr x) =>
			forceStatement(ctx, pos, genAssign(ctx.alloc,  localName(*x.local), translateExprToExpr(ctx, *x.value, x.local.type))),
		(ExternExpr x) =>
			todo!ExprResult("EXTERN EXPR"),
		(ref FinallyExpr x) =>
			translateFinally(ctx, x, type, pos),
		(FunPointerExpr x) =>
			forceExpr(ctx, pos, type, calledExpr(ctx, x.called)),
		(ref IfExpr x) =>
			translateIf(ctx, x, type, pos),
		(ref LambdaExpr x) =>
			translateLambda(ctx, x, type, pos),
		(ref LetExpr x) =>
			translateLet(ctx, x, type, pos),
		(LiteralExpr x) =>
			forceExpr(ctx, pos, type, translateConstant(ctx, x.value, type)),
		(LiteralStringLikeExpr x) =>
			forceExpr(ctx, pos, type, genString(x.value)),
		(LocalGetExpr x) =>
			forceExpr(ctx, pos, type, translateLocalGet(x.local)),
		(LocalPointerExpr x) =>
			todo!ExprResult("LOCAL POINTER -- EMIT BOGUS"),
		(LocalSetExpr x) =>
			forceStatement(ctx, pos, genAssign(ctx.alloc, localName(*x.local), translateExprToExpr(ctx, *x.value, x.local.type))),
		(ref LoopExpr x) =>
			forceStatement(ctx, pos, genWhile(ctx.alloc, genBool(true), translateExprToStatement(ctx, x.body_, type))),
		(ref LoopBreakExpr x) {
			assert(pos.isA!(ExprPos.Statements*));
			ExprResult res = translateExpr(ctx, x.value, type, pos);
			assert(res.isA!(ExprResult.Done));
			if (isVoid(type))
				add(ctx.alloc, pos.as!(ExprPos.Statements*).statements, JsStatement(JsBreakStatement()));
			return res;
		},
		(LoopContinueExpr x) {
			assert(pos.isA!(ExprPos.Statements*));
			return forceStatement(ctx, pos, JsStatement(JsContinueStatement()));
		},
		(ref LoopWhileOrUntilExpr x) =>
			translateLoopWhileOrUntil(ctx, x, type, pos),
		(ref MatchEnumExpr x) =>
			translateMatchEnum(ctx, x, type, pos),
		(ref MatchIntegralExpr x) =>
			translateMatchIntegral(ctx, x, type, pos),
		(ref MatchStringLikeExpr x) =>
			translateMatchStringLike(ctx, x, type, pos),
		(ref MatchUnionExpr x) =>
			translateMatchUnion(ctx, x, type, pos),
		(ref MatchVariantExpr x) =>
			translateMatchVariant(ctx, x, type, pos),
		(ref RecordFieldPointerExpr x) =>
			todo!ExprResult("RECORD FIELD POINTER -- EMIT BOGUS"),
		(ref SeqExpr x) =>
			forceStatements(ctx, pos, (scope ref ArrayBuilder!JsStatement, scope ExprPos inner) {
				ExprResult first = translateExpr(ctx, x.first, Type(ctx.commonTypes.void_), inner);
				assert(first.isA!(ExprResult.Done));
				return translateExpr(ctx, x.then, type, inner);
			}),
		(ref ThrowExpr x) =>
			forceStatement(ctx, pos, genThrow(ctx.alloc, translateExprToExpr(ctx, x.thrown, Type(ctx.commonTypes.exception)))),
		(ref TrustedExpr x) =>
			translateExpr(ctx, x.inner, type, pos),
		(ref TryExpr x) =>
			translateTry(ctx, x, type, pos),
		(ref TryLetExpr x) =>
			translateTryLet(ctx, x, type, pos),
		(ref TypedExpr x) =>
			translateExpr(ctx, x.inner, type, pos));

ExprResult translateAssertOrForbid(ref TranslateExprCtx ctx, ref AssertOrForbidExpr a, Type type, scope ExprPos pos) {
	ExprResult throw_(scope ExprPos inner) =>
		forceStatement(ctx, inner, genThrow(ctx.alloc, has(a.thrown)
			? translateExprToExpr(ctx, *force(a.thrown), Type(ctx.commonTypes.exception))
			: genNewError(ctx, "Assert or forbid failed"))); // TODO: use same message that concretize uses ----------------------
	ExprResult after(scope ExprPos inner) =>
		translateExpr(ctx, a.after, type, inner);
	return translateIfCb(
		ctx, type, pos, a.condition,
		cbTrueBranch: (scope ExprPos inner) => a.isForbid ? throw_(inner) : after(inner),
		cbFalseBranch: (scope ExprPos inner) => a.isForbid ? after(inner) : throw_(inner));
}

ExprResult translateCall(ref TranslateExprCtx ctx, ref CallExpr a, Type type, scope ExprPos pos) {
	assert(type == a.called.returnType);
	return isInlined(a.called)
		? translateInlineCall(ctx, type, pos, a.called.as!(FunInst*).decl.body_, a.called.as!(FunInst*).paramTypes, a.args.length, (size_t argIndex) =>
			translateExprToExpr(ctx, a.args[argIndex], paramTypeAt(a.called, argIndex)))
		: forceExpr(ctx, pos, type, genCall(
			allocate(ctx.alloc, calledExpr(ctx, a.called)),
			mapWithIndex!(JsExpr, Expr)(ctx.alloc, a.args, (size_t argIndex, ref Expr arg) =>
				translateExprToExpr(ctx, arg, paramTypeAt(a.called, argIndex)))));
}
bool isInlined(in Called a) =>
	a.isA!(FunInst*) && bodyIsInlined(*a.as!(FunInst*).decl);

ExprResult translateInlineCall(
	ref TranslateModuleCtx ctx,
	Type returnType,
	scope ExprPos pos,
	in FunBody body_,
	Type[] paramTypes,
	size_t nArgs,
	in JsExpr delegate(size_t) @safe @nogc pure nothrow getArg,
) {
	ExprResult expr(JsExpr value) =>
		forceExpr(ctx.alloc, pos, returnType, value);
	JsExpr onlyArg() {
		assert(nArgs == 1);
		return getArg(0);
	}
	JsExpr[] args(size_t skip = 0) {
		assert(nArgs >= skip);
		return makeArray(ctx.alloc, nArgs - skip, (size_t i) => getArg(i + skip));
	}
	ExprResult createRecord(StructInst* record) =>
		expr(genNew(ctx.alloc, translateStructReference(ctx, record.decl), args()));
	JsExpr returnTypeRef() =>
		translateStructReference(ctx, returnType.as!(StructInst*).decl);
	return body_.matchIn!ExprResult(
		(in FunBody.Bogus) =>
			todo!ExprResult("BOGUS"),
		(in AutoFun) =>
			todo!ExprResult("AUTO"),
		(in BuiltinFun x) =>
			translateCallBuiltin(ctx, returnType, pos, x, nArgs, getArg),
		(in FunBody.CreateEnumOrFlags x) =>
			expr(genPropertyAccess(ctx.alloc, returnTypeRef, x.member.name)),
		(in FunBody.CreateExtern) =>
			assert(false),
		(in FunBody.CreateRecord) =>
			createRecord(returnType.as!(StructInst*)),
		(in FunBody.CreateRecordAndConvertToVariant x) =>
			createRecord(x.member),
		(in FunBody.CreateUnion x) {
			JsExpr member = genPropertyAccess(ctx.alloc, returnTypeRef, x.member.name);
			assert(nArgs == 0 || nArgs == 1);
			return expr(nArgs == 0 ? member : genCall(ctx.alloc, member, [getArg(0)]));
		},
		(in FunBody.CreateVariant) =>
			todo!ExprResult("CREATE VARIANT"), // This should pass the arg through unmodified
		(in EnumFunction) =>
			todo!ExprResult("ENUM FUNCTION"),
		(in Expr _) =>
			assert(false),
		(in FunBody.Extern) =>
			todo!ExprResult("JS EXTERN"),
		(in FunBody.FileImport) =>
			assert(false),
		(in FlagsFunction) =>
			todo!ExprResult("FLAGS FUNCTION"),
		(in FunBody.RecordFieldCall x) {
			assert(nArgs == 2);
			return expr(genCall(ctx.alloc, genPropertyAccess(ctx.alloc, getArg(0), recordFieldName(paramTypes[0], x.fieldIndex)), [getArg(1)]));
		},
		(in FunBody.RecordFieldGet x) =>
			expr(genPropertyAccess(ctx.alloc, onlyArg(), recordFieldName(paramTypes[0], x.fieldIndex))),
		(in FunBody.RecordFieldPointer) =>
			assert(false),
		(in FunBody.RecordFieldSet x) {
			assert(nArgs == 2);
			return todo!ExprResult("RECORD FIELD SET");
		},
		(in FunBody.UnionMemberGet x) =>
			todo!ExprResult("UNION MEMBER GET"),
		(in FunBody.VarGet x) =>
			expr(translateVarReference(ctx, x.var)),
		(in FunBody.VariantMemberGet) =>
			// x instanceof Foo ? some(x) : none
			todo!ExprResult("VARIANT MEMBER GET"),
		(in FunBody.VariantMethod x) =>
			expr(genCall(
				allocate(ctx.alloc, genPropertyAccess(
					ctx.alloc,
					getArg(0),
					variantMethodName(paramTypes[0], x.methodIndex))),
				args(skip: 1))),
		(in FunBody.VarSet) =>
			todo!ExprResult("VAR SET"));
}
// TODO Maybe I should have used a direct pointer to the method here instead of an index ........................................
Symbol variantMethodName(Type variant, size_t methodIndex) =>
	variant.as!(StructInst*).decl.body_.as!(StructBody.Variant).methods[methodIndex].name;
// TODO Maybe I should have used a direct pointer to the field here instead of an index ........................................
Symbol recordFieldName(Type record, size_t fieldIndex) =>
	record.as!(StructInst*).decl.body_.as!(StructBody.Record).fields[fieldIndex].name;

ExprResult translateCallBuiltin(
	ref TranslateModuleCtx ctx,
	Type returnType,
	scope ExprPos pos,
	in BuiltinFun a,
	size_t nArgs,
	in JsExpr delegate(size_t) @safe @nogc pure nothrow getArg,
) {
	ExprResult expr(JsExpr value) =>
		forceExpr(ctx.alloc, pos, returnType, value);
	return a.matchIn!ExprResult(
		(in BuiltinFun.AllTests) =>
			todo!ExprResult("ALL TESTS"), // ----------------------------------------------------------------
		(in BuiltinUnary x) {
			assert(nArgs == 1);
			return expr(translateBuiltinUnary(ctx.alloc, x, getArg(0)));
		},
		(in BuiltinUnaryMath x) =>
			todo!ExprResult("BUILTIN UNARY MATH"),
		(in BuiltinBinary x) {
			assert(nArgs == 2);
			return expr(translateBuiltinBinary(ctx.alloc, x, getArg(0), getArg(1)));
		},
		(in BuiltinBinaryLazy x) {
			assert(nArgs == 2);
			return translateBuiltinBinaryLazy(ctx.alloc, returnType, pos, x, getArg(0), getArg(1));
		},
		(in BuiltinBinaryMath x) =>
			todo!ExprResult("BUILTIN BINARY MATH"),
		(in BuiltinTernary x) =>
			todo!ExprResult("BUILTIN TERNARY"),
		(in Builtin4ary x) =>
			todo!ExprResult("BUILTIN 4ary"),
		(in BuiltinFun.CallLambda) =>
			expr(genCall(allocate(ctx.alloc, getArg(0)), makeArray(ctx.alloc, nArgs - 1, (size_t i) => getArg(i + 1)))),
		(in BuiltinFun.CallFunPointer) =>
			assert(false),
		(in Constant x) =>
			expr(translateConstant(ctx, x, returnType)),
		(in BuiltinFun.Init) =>
			assert(false),
		(in JsFun x) =>
			translateCallJsFun(ctx, returnType, pos, x, nArgs, getArg),
		(in BuiltinFun.MarkRoot) =>
			assert(false),
		(in BuiltinFun.MarkVisit) =>
			assert(false),
		(in BuiltinFun.PointerCast) =>
			assert(false),
		(in BuiltinFun.SizeOf) =>
			assert(false),
		(in BuiltinFun.StaticSymbols) =>
			assert(false),
		(in VersionFun x) =>
			expr(genBool(isVersion(ctx.version_, x))));
}
JsExpr translateBuiltinUnary(ref Alloc alloc, BuiltinUnary a, JsExpr arg) {
	final switch (a) {
		case BuiltinUnary.arrayPointer:
		case BuiltinUnary.asAnyPointer:
		case BuiltinUnary.deref:
		case BuiltinUnary.drop:
		case BuiltinUnary.isNanFloat32:
		case BuiltinUnary.jumpToCatch:
		case BuiltinUnary.referenceFromPointer:
		case BuiltinUnary.setupCatch:
		case BuiltinUnary.toFloat32FromFloat64:
		case BuiltinUnary.toFloat64FromFloat32:
		case BuiltinUnary.toNat64FromPtr:
		case BuiltinUnary.toPtrFromNat64:
			assert(false);
		case BuiltinUnary.arraySize:
			return genCall(alloc, JsExpr(JsName(symbol!"BigInt")), [genPropertyAccess(alloc, arg, symbol!"length")]);
		case BuiltinUnary.bitwiseNotNat8:
		case BuiltinUnary.bitwiseNotNat16:
		case BuiltinUnary.bitwiseNotNat32:
		case BuiltinUnary.bitwiseNotNat64:
			return genUnary(alloc, JsUnaryExpr.Kind.bitwiseNot, arg);
		case BuiltinUnary.countOnesNat64:
			return todo!JsExpr("popcount");
		case BuiltinUnary.enumToIntegral:
			return todo!JsExpr("Enum to integral value");
		case BuiltinUnary.isNanFloat64:
			return genCall(alloc, genPropertyAccess(alloc, JsExpr(JsName(symbol!"Number")), symbol!"isNaN"), [arg]);
		case BuiltinUnary.toChar8FromNat8:
		case BuiltinUnary.toInt64FromInt8:
		case BuiltinUnary.toInt64FromInt16:
		case BuiltinUnary.toInt64FromInt32:
		case BuiltinUnary.toNat8FromChar8:
		case BuiltinUnary.toNat32FromChar32:
		case BuiltinUnary.toNat64FromNat8:
		case BuiltinUnary.toNat64FromNat16:
		case BuiltinUnary.toNat64FromNat32:
		case BuiltinUnary.unsafeToChar32FromChar8:
		case BuiltinUnary.unsafeToChar32FromNat32:
		case BuiltinUnary.unsafeToNat32FromInt32:
		case BuiltinUnary.unsafeToInt8FromInt64:
		case BuiltinUnary.unsafeToInt16FromInt64:
		case BuiltinUnary.unsafeToInt32FromInt64:
		case BuiltinUnary.unsafeToNat64FromInt64:
		case BuiltinUnary.unsafeToInt64FromNat64:
		case BuiltinUnary.unsafeToNat8FromNat64:
		case BuiltinUnary.unsafeToNat16FromNat64:
		case BuiltinUnary.unsafeToNat32FromNat64:
			// These are all represented as JS integers
			return arg;
		case BuiltinUnary.toFloat64FromInt64:
		case BuiltinUnary.toFloat64FromNat64:
			return genCall(alloc, JsExpr(JsName(symbol!"Number")), [arg]);
		case BuiltinUnary.truncateToInt64FromFloat64:
			return todo!JsExpr("trucate float");
	}
}
JsExpr translateBuiltinBinary(ref Alloc alloc, BuiltinBinary a, JsExpr left, JsExpr right) {
	JsExpr binary(JsBinaryExpr.Kind kind) =>
		genBinary(alloc, kind, left, right);
	JsExpr wrapAdd(string modulo) =>
		genBinary(alloc, JsBinaryExpr.Kind.modulo, binary(JsBinaryExpr.Kind.plus), genIntegerLarge(modulo));
	JsExpr wrapMul(string modulo) =>
		genBinary(alloc, JsBinaryExpr.Kind.modulo, binary(JsBinaryExpr.Kind.times), genIntegerLarge(modulo));
	final switch (a) {
		case BuiltinBinary.addFloat64:
		case BuiltinBinary.unsafeAddInt8:
		case BuiltinBinary.unsafeAddInt16:
		case BuiltinBinary.unsafeAddInt32:
		case BuiltinBinary.unsafeAddInt64:
			return binary(JsBinaryExpr.Kind.plus);
		case BuiltinBinary.bitwiseAndInt8:
		case BuiltinBinary.bitwiseAndInt16:
		case BuiltinBinary.bitwiseAndInt32:
		case BuiltinBinary.bitwiseAndInt64:
		case BuiltinBinary.bitwiseAndNat8:
		case BuiltinBinary.bitwiseAndNat16:
		case BuiltinBinary.bitwiseAndNat32:
		case BuiltinBinary.bitwiseAndNat64:
			return binary(JsBinaryExpr.Kind.bitwiseAnd);
		case BuiltinBinary.bitwiseOrInt8:
		case BuiltinBinary.bitwiseOrInt16:
		case BuiltinBinary.bitwiseOrInt32:
		case BuiltinBinary.bitwiseOrInt64:
		case BuiltinBinary.bitwiseOrNat8:
		case BuiltinBinary.bitwiseOrNat16:
		case BuiltinBinary.bitwiseOrNat32:
		case BuiltinBinary.bitwiseOrNat64:
			return binary(JsBinaryExpr.Kind.bitwiseOr);
		case BuiltinBinary.bitwiseXorInt8:
		case BuiltinBinary.bitwiseXorInt16:
		case BuiltinBinary.bitwiseXorInt32:
		case BuiltinBinary.bitwiseXorInt64:
		case BuiltinBinary.bitwiseXorNat8:
		case BuiltinBinary.bitwiseXorNat16:
		case BuiltinBinary.bitwiseXorNat32:
		case BuiltinBinary.bitwiseXorNat64:
			return binary(JsBinaryExpr.Kind.bitwiseXor);
		case BuiltinBinary.eqChar8:
		case BuiltinBinary.eqChar32:
		case BuiltinBinary.eqFloat64:
		case BuiltinBinary.eqInt8:
		case BuiltinBinary.eqInt16:
		case BuiltinBinary.eqInt32:
		case BuiltinBinary.eqInt64:
		case BuiltinBinary.eqNat8:
		case BuiltinBinary.eqNat16:
		case BuiltinBinary.eqNat32:
		case BuiltinBinary.eqNat64:
			return binary(JsBinaryExpr.Kind.eqEqEq);
		case BuiltinBinary.lessChar8:
		case BuiltinBinary.lessFloat64:
		case BuiltinBinary.lessInt8:
		case BuiltinBinary.lessInt16:
		case BuiltinBinary.lessInt32:
		case BuiltinBinary.lessInt64:
		case BuiltinBinary.lessNat8:
		case BuiltinBinary.lessNat16:
		case BuiltinBinary.lessNat32:
		case BuiltinBinary.lessNat64:
			return binary(JsBinaryExpr.Kind.less);
		case BuiltinBinary.mulFloat64:
		case BuiltinBinary.unsafeMulInt8:
		case BuiltinBinary.unsafeMulInt16:
		case BuiltinBinary.unsafeMulInt32:
		case BuiltinBinary.unsafeMulInt64:
			return binary(JsBinaryExpr.Kind.times);
		case BuiltinBinary.subFloat64:
		case BuiltinBinary.unsafeSubInt8:
		case BuiltinBinary.unsafeSubInt16:
		case BuiltinBinary.unsafeSubInt32:
		case BuiltinBinary.unsafeSubInt64:
			return binary(JsBinaryExpr.Kind.minus);
		case BuiltinBinary.unsafeBitShiftLeftNat64:
		case BuiltinBinary.unsafeBitShiftRightNat64:
			return todo!JsExpr("bit shift left. Is this << or <<< ?");
		case BuiltinBinary.unsafeDivFloat64:
		case BuiltinBinary.unsafeDivInt8:
		case BuiltinBinary.unsafeDivInt16:
		case BuiltinBinary.unsafeDivInt32:
		case BuiltinBinary.unsafeDivInt64:
		case BuiltinBinary.unsafeDivNat8:
		case BuiltinBinary.unsafeDivNat16:
		case BuiltinBinary.unsafeDivNat32:
		case BuiltinBinary.unsafeDivNat64:
			return binary(JsBinaryExpr.Kind.divide);
		case BuiltinBinary.unsafeModNat64:
			return binary(JsBinaryExpr.Kind.modulo);
		case BuiltinBinary.wrapAddNat8:
			return wrapAdd("0x100n");
		case BuiltinBinary.wrapAddNat16:
			return wrapAdd("0x10000n");
		case BuiltinBinary.wrapAddNat32:
			return wrapAdd("0x100000000n");
		case BuiltinBinary.wrapAddNat64:
			// TODO: there should probably be separate 'unsafe-add' and 'wrap-add' functions, to keep the JS simple when we are checking for overflow anyway
			return wrapAdd("0x10000000000000000n");
		case BuiltinBinary.wrapMulNat8:
			return wrapMul("0x100n");
		case BuiltinBinary.wrapMulNat16:
			return wrapMul("0x10000n");
		case BuiltinBinary.wrapMulNat32:
			return wrapMul("0x100000000n");
		case BuiltinBinary.wrapMulNat64:
			return wrapMul("0x10000000000000000n");
		case BuiltinBinary.wrapSubNat8:
		case BuiltinBinary.wrapSubNat16:
		case BuiltinBinary.wrapSubNat32:
		case BuiltinBinary.wrapSubNat64:
			return todo!JsExpr("Need to wrap negative values to positive. But js '%' is not really a mod!");
		case BuiltinBinary.addFloat32:
		case BuiltinBinary.addPointerAndNat64:
		case BuiltinBinary.eqFloat32:
		case BuiltinBinary.eqPointer:
		case BuiltinBinary.lessFloat32:
		case BuiltinBinary.lessPointer:
		case BuiltinBinary.mulFloat32:
		case BuiltinBinary.newArray:
		case BuiltinBinary.seq:
		case BuiltinBinary.subFloat32:
		case BuiltinBinary.subPointerAndNat64:
		case BuiltinBinary.switchFiber:
		case BuiltinBinary.unsafeDivFloat32:
		case BuiltinBinary.writeToPointer:
			assert(false);
	}
}
ExprResult translateBuiltinBinaryLazy(ref Alloc alloc, Type type, scope ExprPos pos, BuiltinBinaryLazy kind, JsExpr left, JsExpr right) {
	final switch (kind) {
		case BuiltinBinaryLazy.boolAnd:
			return forceExpr(alloc, pos, type, genBinary(alloc, JsBinaryExpr.Kind.and, left, right));
		case BuiltinBinaryLazy.boolOr:
			return forceExpr(alloc, pos, type, genBinary(alloc, JsBinaryExpr.Kind.or, left, right));
		case BuiltinBinaryLazy.optionOr:
			return todo!ExprResult("option or");
		case BuiltinBinaryLazy.optionQuestion2:
			return todo!ExprResult("option or default");
	}
}

ExprResult translateCallJsFun(
	ref TranslateModuleCtx ctx,
	Type returnType,
	scope ExprPos pos,
	JsFun fun,
	size_t nArgs,
	in JsExpr delegate(size_t) @safe @nogc pure nothrow getArg,
) {
	ExprResult expr(JsExpr value) =>
		forceExpr(ctx.alloc, pos, returnType, value);
	final switch (fun) {
		case JsFun.asJsAny:
		case JsFun.jsAnyAsT:
			assert(nArgs == 1);
			return expr(getArg(0));
		case JsFun.callProperty:
			assert(nArgs >= 2);
			return expr(genCall(
				allocate(ctx.alloc, genPropertyAccessComputed(ctx.alloc, getArg(0), getArg(1))),
				makeArray(ctx.alloc, nArgs - 2, (size_t i) => getArg(i + 2))));
		case JsFun.get:
			assert(nArgs == 2);
			return expr(genPropertyAccessComputed(ctx.alloc, getArg(0), getArg(1)));
		case JsFun.jsGlobal:
			assert(nArgs == 0);
			return expr(JsExpr(JsName(ctx.isBrowser ? symbol!"window" : symbol!"global")));
		case JsFun.set:
			assert(nArgs == 3);
			return forceStatement(ctx.alloc, pos, genAssign(ctx.alloc, genPropertyAccessComputed(ctx.alloc, getArg(0), getArg(1)), getArg(2)));
	}
}

ExprResult translateIf(ref TranslateExprCtx ctx, ref IfExpr a, Type type, scope ExprPos pos) =>
	translateIfCb(
		ctx, type, pos, a.condition,
		(scope ExprPos inner) => translateExpr(ctx, a.trueBranch, type, inner),
		(scope ExprPos inner) => translateExpr(ctx, a.falseBranch, type, inner));

ExprResult translateIfCb(ref TranslateExprCtx ctx, Type type, scope ExprPos pos, in Condition condition, in TranslateCb cbTrueBranch, in TranslateCb cbFalseBranch) {
	Opt!bool constant = tryEvalConstantBool(ctx.version_, ctx.allExtern, condition);
	if (has(constant)) // TODO: TERNARY -----------------------------------------------------------------------------------------------
		return (force(constant) ? cbTrueBranch : cbFalseBranch)(pos);
	else if (pos.isA!(ExprPos.Expression) && condition.isA!(Expr*))
		return ExprResult(genTernary(
			ctx.alloc,
			translateExprToExpr(ctx, *condition.as!(Expr*), Type(ctx.commonTypes.bool_)),
			translateToExpr(cbTrueBranch),
			translateToExpr(cbFalseBranch)));
	else
		return condition.match!ExprResult(
			(ref Expr cond) =>
				forceStatement(ctx, pos, genIf(
					ctx.alloc,
					translateExprToExpr(ctx, cond, Type(ctx.commonTypes.bool_)),
					translateToStatement(ctx.alloc, cbTrueBranch),
					translateToStatement(ctx.alloc, cbFalseBranch))),
			(ref Condition.UnpackOption x) =>
				translateUnpackOption(ctx, type, pos, x, cbTrueBranch, cbFalseBranch));
}
ExprResult translateUnpackOption(ref TranslateExprCtx ctx, Type type, scope ExprPos pos, ref Condition.UnpackOption unpack, in TranslateCb cbTrueBranch, in TranslateCb cbFalseBranch) =>
	/*
	const option = <<option>>
	if ('some' in option) {
		const <<destructure>> = option.some
		<<true branch>>
	} else {
		<<false branch>>
	}
	*/
	withTemp(ctx, symbol!"option", unpack.option, pos, (JsName option, scope ExprPos inner) =>
		forceStatement(ctx, inner, genIf(
			ctx.alloc,
			genIn(ctx.alloc, genString("some"), JsExpr(option)),
			translateToStatement(ctx.alloc, (scope ExprPos inner2) =>
				translateLetLikeCb(
					ctx, unpack.destructure, genPropertyAccess(ctx.alloc, JsExpr(option), symbol!"some"), inner2,
					(scope ref ArrayBuilder!JsStatement, scope ExprPos inner3) =>
						cbTrueBranch(inner3))),
			translateToStatement(ctx.alloc, cbFalseBranch))));

ExprResult translateLambda(ref TranslateExprCtx ctx, ref LambdaExpr a, Type type, scope ExprPos pos) =>
	forceExpr(ctx, pos, type, JsExpr(JsArrowFunction(
		JsParams(newSmallArray(ctx.alloc, [translateDestructure(ctx, a.param)])),
		translateExprToExprOrBlockStatement(ctx, a.body_, a.returnType))));

ExprResult translateLet(ref TranslateExprCtx ctx, ref LetExpr a, Type type, scope ExprPos pos) =>
	translateLetLike(ctx, a.destructure, translateExprToExpr(ctx, a.value, a.destructure.type), a.then, type, pos);
ExprResult translateLetLike(
	ref TranslateExprCtx ctx,
	ref Destructure destructure,
	JsExpr value,
	ref Expr then,
	Type type,
	scope ExprPos pos,
) =>
	translateLetLikeCb(ctx, destructure, value, pos, (scope ref ArrayBuilder!JsStatement, scope ExprPos inner) =>
		translateExpr(ctx, then, type, inner));
ExprResult translateLetLikeCb(
	ref TranslateExprCtx ctx,
	in Destructure destructure,
	JsExpr value,
	scope ExprPos pos,
	in ExprResult delegate(scope ref ArrayBuilder!JsStatement, scope ExprPos) @safe @nogc pure nothrow cb,
) =>
	forceStatements(ctx, pos, (scope ref ArrayBuilder!JsStatement out_, scope ExprPos inner) {
		if (destructure.isA!(Destructure.Ignore*)) {
			if (!value.isA!JsName)
				add(ctx.alloc, out_, JsStatement(value));
		} else
			add(ctx.alloc, out_, genVarDecl(
				ctx.alloc,
				hasAnyMutable(destructure) ? JsVarDecl.Kind.let : JsVarDecl.Kind.const_,
				translateDestructure(ctx, destructure),
				value));
		return cb(out_, inner);
	});

JsExpr translateConstant(ref TranslateModuleCtx ctx, in Constant value, in Type type) {
	if (type.isA!TypeParamIndex) {
		assert(value.isA!(Constant.Zero));
		return genNull();
	} else {
		switch (type.as!(StructInst*).decl.body_.as!BuiltinType) {
			case BuiltinType.bool_:
				return genBool(asBool(value));
			case BuiltinType.float32: // TODO: we probably shouldn't allow float32 in JS -------------------------------------------
			case BuiltinType.float64:
				return genNumber(value.as!(Constant.Float).value);
			case BuiltinType.int8:
			case BuiltinType.int16:
			case BuiltinType.int32:
			case BuiltinType.int64:
				return genIntegerSigned(value.as!IntegralValue.asSigned);
			case BuiltinType.char8:
			case BuiltinType.char32:
			case BuiltinType.nat8:
			case BuiltinType.nat16:
			case BuiltinType.nat32:
			case BuiltinType.nat64:
				return genIntegerUnsigned(value.as!IntegralValue.asUnsigned);
			case BuiltinType.void_:
				return genUndefined();
			default:
				import util.writer : debugLogWithWriter, Writer; // ---------------------------------------------------------------------------------------
				debugLogWithWriter((scope ref Writer writer) {
					writer ~= "THE CONSTANT BUILTIN TYPE IS ";
					writer ~= stringOfEnum(type.as!(StructInst*).decl.body_.as!BuiltinType);
				});
				assert(false);
		}
	}
}

JsExpr translateLocalGet(in Local* local) =>
	JsExpr(localName(*local));

ExprResult translateLoopWhileOrUntil(ref TranslateExprCtx ctx, ref LoopWhileOrUntilExpr a, Type type, scope ExprPos pos) =>
	a.condition.match!ExprResult(
		(ref Expr cond) {
			JsExpr condition = translateExprToExpr(ctx, cond, Type(ctx.commonTypes.bool_));
			JsExpr condition2 = a.isUntil ? genNot(ctx.alloc, condition) : condition;
			return forceStatements(ctx, pos, (scope ref ArrayBuilder!JsStatement res, scope ExprPos inner) {
				add(ctx.alloc, res, genWhile(ctx.alloc, condition2, translateExprToStatement(ctx, a.body_, Type(ctx.commonTypes.void_))));
				return translateExpr(ctx, a.after, type, inner);
			});
		},
		(ref Condition.UnpackOption) =>
			todo!ExprResult("UNPACK OPTION IN LOOP"));

ExprResult translateMatchEnum(ref TranslateExprCtx ctx, ref MatchEnumExpr a, Type type, scope ExprPos pos) =>
	forceStatement(ctx, pos, genSwitch(
		ctx.alloc,
		translateExprToExpr(ctx, a.matched),
		map(ctx.alloc, a.cases, (ref MatchEnumExpr.Case case_) =>
			JsSwitchStatement.Case(
				translateEnumValue(ctx, case_.member),
				translateExprToBlockStatement(ctx, case_.then, type))),
		translateSwitchDefault(ctx, a.else_, type, "Invalid enum value")));

ExprResult translateMatchIntegral(ref TranslateExprCtx ctx, ref MatchIntegralExpr a, Type type, scope ExprPos pos) =>
	forceStatement(ctx, pos, genSwitch(
		ctx.alloc,
		translateExprToExpr(ctx, a.matched),
		map(ctx.alloc, a.cases, (ref MatchIntegralExpr.Case case_) =>
			JsSwitchStatement.Case(
				translateIntegralValue(a.kind, case_.value),
				translateExprToBlockStatement(ctx, case_.then, type))),
		translateExprToStatement(ctx, a.else_, type)));

ExprResult translateMatchStringLike(ref TranslateExprCtx ctx, ref MatchStringLikeExpr a, Type type, scope ExprPos pos) =>
	forceStatement(ctx, pos, genSwitch(
		ctx.alloc,
		translateExprToExpr(ctx, a.matched),
		map(ctx.alloc, a.cases, (ref MatchStringLikeExpr.Case case_) =>
			JsSwitchStatement.Case(genString(case_.value), translateExprToBlockStatement(ctx, case_.then, type))),
		translateExprToStatement(ctx, a.else_, type)));

ExprResult translateMatchUnion(ref TranslateExprCtx ctx, ref MatchUnionExpr a, Type type, scope ExprPos pos) =>
	withTemp(ctx, symbol!"matched", a.matched, pos, (JsName matched, scope ExprPos inner) =>
		translateMatchUnionOrVariant!(MatchUnionExpr.Case)(
			ctx, matched, a.cases, type, inner,
			translateSwitchDefault(ctx, has(a.else_) ? some(*force(a.else_)) : none!Expr, type, "Invalid union value"),
			(ref MatchUnionExpr.Case case_) =>
				MatchUnionOrVariantCase(
					genIn(ctx.alloc, genString(stringOfSymbol(ctx.alloc, case_.member.name)), JsExpr(matched)),
					genPropertyAccess(ctx.alloc, JsExpr(matched), case_.member.name))));

ExprResult translateMatchVariant(ref TranslateExprCtx ctx, ref MatchVariantExpr a, Type type, scope ExprPos pos) =>
	withTemp(ctx, symbol!"matched", a.matched, pos, (JsName matched, scope ExprPos inner) =>
		translateMatchVariant(ctx, matched, a.cases, translateExprToStatement(ctx, a.else_, type), type, inner));
ExprResult translateMatchVariant(
	ref TranslateExprCtx ctx,
	JsName matched,
	MatchVariantExpr.Case[] cases,
	JsStatement else_,
	Type type,
	scope ExprPos pos,
) =>
	translateMatchUnionOrVariant!(MatchVariantExpr.Case)(ctx, matched, cases, type, pos, else_, (ref MatchVariantExpr.Case case_) =>
		MatchUnionOrVariantCase(
			genInstanceof(ctx.alloc, JsExpr(matched), translateStructReference(ctx, case_.member.decl)),
			JsExpr(matched)));

immutable struct MatchUnionOrVariantCase {
	JsExpr isMatch;
	JsExpr destructured;
}
ExprResult translateMatchUnionOrVariant(Case)(
	ref TranslateExprCtx ctx,
	JsName matched,
	Case[] cases,
	Type type,
	scope ExprPos pos,
	JsStatement default_,
	in MatchUnionOrVariantCase delegate(ref Case) @safe @nogc pure nothrow cbCase,
) =>
	forceStatement(ctx, pos, foldReverse!(JsStatement, Case)(default_, cases, (JsStatement else_, ref Case case_) {
		MatchUnionOrVariantCase x = cbCase(case_);
		return genIf(ctx.alloc,
			x.isMatch,
			translateToStatement(ctx.alloc, (scope ExprPos pos) =>
				translateLetLike(ctx, case_.destructure, x.destructured, case_.then, type, pos)),
			else_);
	}));

ExprResult withTemp(
	ref TranslateExprCtx ctx,
	Symbol name,
	ExprAndType value,
	scope ExprPos pos,
	in ExprResult delegate(JsName temp, scope ExprPos inner) @safe @nogc pure nothrow cb,
) =>
	forceStatements(ctx, pos, (scope ref ArrayBuilder!JsStatement out_, scope ExprPos inner) {
		JsName jsName = JsName(name); // TODO: give it a temp index ---------------------------------------------------------
		add(ctx.alloc, out_, genConst(ctx.alloc, JsDestructure(jsName), translateExprToExpr(ctx, value)));
		return cb(jsName, inner);
	});

JsStatement genThrowError(ref TranslateModuleCtx ctx, string message) =>
	genThrow(ctx.alloc, genNewError(ctx, message));
JsExpr genNewError(ref TranslateModuleCtx ctx, string message) =>
	genNew(ctx.alloc, JsExpr(JsName(symbol!"Error")), [genString(message)]);

JsStatement translateSwitchDefault(ref TranslateExprCtx ctx, Opt!Expr else_, Type type, string error) =>
	has(else_)
		? translateExprToStatement(ctx, force(else_), type)
		: genThrowError(ctx, error);

JsExpr translateEnumValue(ref TranslateModuleCtx ctx, EnumOrFlagsMember* a) =>
	genPropertyAccess(ctx.alloc, translateStructReference(ctx, a.containingEnum), a.name);
JsExpr translateIntegralValue(MatchIntegralExpr.Kind kind, IntegralValue value) =>
	genNumber(kind.isSigned ? double(value.asSigned) : double(value.asUnsigned));

ExprResult translateFinally(ref TranslateExprCtx ctx, ref FinallyExpr a, Type type, scope ExprPos pos) =>
	/*
	finally right
	below
	==>
	try {
		below
	} finally {
		right
	}
	*/
	forceStatement(ctx, pos, JsStatement(JsTryFinallyStatement(
		translateExprToBlockStatement(ctx, a.below, type),
		translateExprToBlockStatement(ctx, a.right, Type(ctx.commonTypes.void_)))));

ExprResult translateTry(ref TranslateExprCtx ctx, ref TryExpr a, Type type, scope ExprPos pos) {
	JsName exceptionName = JsName(symbol!"exception");
	JsExpr exn = JsExpr(exceptionName);
	return forceStatement(ctx, pos, genTryCatch(
		ctx.alloc,
		translateExprToBlockStatement(ctx, a.tried, type),
		exceptionName,
		translateToBlockStatement(ctx.alloc, (scope ExprPos inner) =>
			translateMatchVariant(ctx, exceptionName, a.catches, genThrow(ctx.alloc, JsExpr(exceptionName)), type, inner))));
}

ExprResult translateTryLet(ref TranslateExprCtx ctx, ref TryLetExpr a, Type type, scope ExprPos pos) =>
	/*
	try destructure = value catch foo f : handler
	then
	==>
	let catching = true
	try {
		const destructure = value
		catching = false
		then
	} catch (exception) {
		if (!catching || !(exception instanceof Foo)) throw exception
		const f = exception
		handler
	}
	*/
	forceStatements(ctx, pos, (scope ref ArrayBuilder!JsStatement out_, scope ExprPos inner) {
		JsName catching = JsName(symbol!"catching"); // TODO: make sure to increment temp index...
		add(ctx.alloc, out_, genLet(ctx.alloc, JsDestructure(catching), genBool(true)));
		JsBlockStatement tryBlock = translateToBlockStatement(ctx.alloc, (scope ExprPos tryPos) =>
			translateLetLikeCb(ctx, a.destructure, translateExprToExpr(ctx, a.value, a.destructure.type), tryPos, (scope ref ArrayBuilder!JsStatement tryOut, scope ExprPos tryInner) {
				add(ctx.alloc, tryOut, genAssign(ctx.alloc, catching, genBool(false)));
				return translateExpr(ctx, a.then, type, tryInner);
			}));
		JsName exceptionName = JsName(symbol!"exception");
		JsBlockStatement catchBlock = translateToBlockStatement(ctx.alloc, (scope ref ArrayBuilder!JsStatement catchOut, scope ExprPos catchPos) {
			JsExpr cond = genOr(
				ctx.alloc,
				genNot(ctx.alloc, JsExpr(catching)),
				genNot(
					ctx.alloc,
					genInstanceof(ctx.alloc, JsExpr(exceptionName),
					translateStructReference(ctx, a.catch_.member.decl))));
			add(ctx.alloc, catchOut, genIf(ctx.alloc, cond, genThrow(ctx.alloc, JsExpr(exceptionName)), genEmptyStatement()));
			return translateLetLike(ctx, a.catch_.destructure, JsExpr(exceptionName), a.catch_.then, type, pos);
		});
		add(ctx.alloc, out_, genTryCatch(ctx.alloc, tryBlock, exceptionName, catchBlock));
		return ExprResult.done;
	});

bool hasAnyMutable(in Destructure a) =>
	a.matchIn!bool(
		(in Destructure.Ignore) =>
			false,
		(in Local x) =>
			!x.mutability.isImmutable,
		(in Destructure.Split x) =>
			exists!Destructure(x.parts, (in Destructure part) => hasAnyMutable(part)));


// For a function with specs, it is a double-arrow function with a parameter for each member of the spec.
// E.g.: const f = (spec0, spec1) => (arg0, arg1) => ...
JsExpr calledExpr(ref TranslateExprCtx ctx, in Called a) =>
	calledExpr(ctx.ctx, some(ctx.curFun), a);
JsExpr calledExpr(ref TranslateModuleCtx ctx, Opt!(FunDecl*) curFun, in Called a) =>
	a.match!JsExpr(
		(ref Called.Bogus x) =>
			todo!JsExpr("BOGUS"), // ------------------------------------------------------------------------------------------------------------
		(ref FunInst x) {
			JsExpr fun = translateFunReference(ctx, x.decl);
			return isEmpty(x.specImpls)
				? fun
				: genCall(allocate(ctx.alloc, fun), map(ctx.alloc, x.specImpls, (ref Called x) => calledExpr(ctx, curFun, x)));
		},
		(CalledSpecSig x) =>
			JsExpr(JsName(x.nonInstantiatedSig.name, some(safeToUshort(findSigIndex(*force(curFun), x))))));

size_t findSigIndex(in FunDecl curFun, in CalledSpecSig called) {
	size_t res = 0;
	bool done = false;
	eachSpecInFunIncludingParents(curFun, (SpecInst* spec) { // TODO: this could return the first output...-------------------------
		if (done) return;
		if (spec == called.specInst) {
			res += called.sigIndex;
			done = true;
		} else
			res += countSigs(*spec);
	});
	assert(done);
	return res;
}
