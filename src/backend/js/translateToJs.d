module backend.js.translateToJs;

@safe @nogc pure nothrow:

import backend.js.allUsed :
	AllUsed, allUsed, AnyDecl, bodyIsInlined, isModuleUsed, isUsedAnywhere, isUsedInModule, tryEvalConstantBool;
import backend.js.jsAst :
	genAnd,
	genArray,
	genArrowFunction,
	genAssign,
	genBinary,
	genBlockStatement,
	genBool,
	genBreak,
	genBreakNoLabel,
	genCall,
	genCallProperty,
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
	genNotEqEq,
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
	genWhileTrue,
	JsArrowFunction,
	JsAssignStatement,
	JsBinaryExpr,
	JsBlockStatement,
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
import frontend.showModel : ShowCtx, ShowTypeCtx, writeCalled, writeTypeUnquoted; // ---------------------------------------------------------------------------------
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
	eachLocal,
	eachTest,
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
	paramsArray,
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
	Test,
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
	foldRange,
	foldReverse,
	foldReverseWithIndex,
	isEmpty,
	makeArray,
	map,
	mapOp,
	mapReduce,
	mapWithIndex,
	mapZip,
	newArray,
	newSmallArray,
	only,
	prepend,
	small,
	SmallArray;
import util.col.arrayBuilder : add, addAll, ArrayBuilder, buildArray, Builder, buildSmallArray, finish, sizeSoFar;
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
import util.unicode : mustUnicodeDecode;
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
TranslateToJsResult translateToJs(ref Alloc alloc, ref ProgramWithMain program, in ShowTypeCtx showCtx, OS os, bool isNodeJs) {
	// TODO: Start with the 'main' function to determine everything that is actually used. ------------------------------------------------
	// We need to start with the modules with no dependencies and work down...
	VersionInfo version_ = versionInfoForBuildToJS(os, isNodeJs);
	SymbolSet allExterns = allExternsForJs(isNodeJs: isNodeJs);
	AllUsed allUsed = allUsed(alloc, program, version_, allExterns);
	Map!(Uri, Path) modulePaths = modulePaths(alloc, program);
	TranslateProgramCtx ctx = TranslateProgramCtx(
		ptrTrustMe(alloc),
		showCtx,
		ptrTrustMe(program.program),
		version_,
		allExterns,
		allUsed,
		modulePaths,
		moduleExportMangledNames(alloc, program.program, allUsed));
	
	foreach (Module* module_; program.program.rootModules)
		doTranslateModule(ctx, module_);
	return TranslateToJsResult(getOutputFiles(alloc, showCtx, modulePaths, program.mainFun.fun.decl.moduleUri, ctx.done, isNodeJs: isNodeJs));
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

SymbolSet allExternsForJs(bool isNodeJs) { // TODO: we'll eventually want to have 'browser' exclusive functions? ---------------------------------
	MutSymbolSet res = symbolSet(symbol!"js");
	return isNodeJs
		// TODO: I don't know about adding e.g. 'windows' here. node.js is supposed to be cross-platform... ---------------------
		? res.add(symbol!"node-js")
		: res.add(symbol!"browser");
}

immutable(KeyValuePair!(Path, string)[]) getOutputFiles(
	ref Alloc alloc,
	in ShowTypeCtx showCtx,
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
					writeJsAst(alloc, showCtx, module_.uri, force(ast), module_.uri == mainModuleUri));
	});

struct TranslateProgramCtx {
	@safe @nogc pure nothrow:

	Alloc* allocPtr;
	ShowCtx showCtx; // ----------------------------------------------------------------------------------------------------------------
	immutable Program* programPtr;
	immutable VersionInfo version_;
	immutable SymbolSet allExterns;
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
		ctx.showCtx,
		ctx.programPtr,
		ctx.version_,
		ctx.allExterns,
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
	ShowCtx showCtx; // ----------------------------------------------------------------------------------------------------------------
	immutable Program* programPtr;
	immutable VersionInfo version_;
	immutable SymbolSet allExterns;
	immutable AllUsed* allUsedPtr;
	immutable ModuleExportMangledNames* exportMangledNames;
	immutable Map!(AnyDecl, ushort) privateMangledNames;
	immutable Map!(StructDecl*, StructAlias*) aliases;

	ref Alloc alloc() =>
		*allocPtr;
	ref Program program() =>
		*programPtr;
	CommonTypes* commonTypes() =>
		program.commonTypes;
	ref AllUsed allUsed() =>
		*allUsedPtr;

	bool isBrowser() =>
		allExterns.has(symbol!"browser");
}

struct TranslateExprCtx {
	@safe @nogc pure nothrow:
	TranslateModuleCtx* ctxPtr;
	Opt!(FunDecl*) curFun;
	uint nextTempIndex;

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
JsName testName(in TranslateModuleCtx ctx, in Test* a) =>
	mangledNameForDecl(ctx, AnyDecl(a));
JsExpr translateTestReference(in TranslateModuleCtx ctx, in Test* a) =>
	JsExpr(testName(ctx, a));
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
	Map!(Symbol, ushort) lastIndexForName;
	// Key is some decl, e.g. StructDecl*.
	// If it's not in the map, don't mangle it.
	Map!(AnyDecl, ushort) mangledNames;
}
ModuleExportMangledNames moduleExportMangledNames(ref Alloc alloc, in Program program, in AllUsed used) {
	MutMap!(Symbol, ushort) lastIndexForName;
	MutMap!(AnyDecl, ushort) res;
	eachExportOrTestInProgram(program, (AnyDecl decl) {
		if (isUsedAnywhere(used, decl)) {
			ushort index = addOrChange!(Symbol, ushort)(alloc, lastIndexForName, decl.name, () => ushort(0), (ref ushort x) { x++; });
			mustAdd(alloc, res, decl, index);
		}
	});
	// For uniquely identified decls, don't mangle
	eachExportOrTestInProgram(program, (AnyDecl decl) {
		if (isUsedAnywhere(used, decl) && mustGet(lastIndexForName, decl.name) == 0)
			mustDelete(res, decl);
	});
	return ModuleExportMangledNames(moveToMap(alloc, lastIndexForName), moveToMap(alloc, res));
}

Map!(AnyDecl, ushort) modulePrivateMangledNames(ref Alloc alloc, in Module module_, in ModuleExportMangledNames exports_, in AllUsed used) {
	MutMap!(Symbol, ushort) lastIndexForName;
	MutMap!(AnyDecl, ushort) res; // TODO: share code with 'moduleExportMangledNames'? ---------------------------------------
	eachPrivateDeclInModule(module_, (AnyDecl decl) {
		if (isUsedInModule(used, module_.uri, decl)) {
			ushort index = addOrChange!(Symbol, ushort)(
				alloc, lastIndexForName, decl.name,
				() {
					Opt!ushort x = exports_.lastIndexForName[decl.name];
					return has(x) ? safeToUshort(force(x) + 1) : typeAs!ushort(0);
				},
				(ref ushort x) { x++; });
			mustAdd(alloc, res, decl, index);
		}
	});
	eachPrivateDeclInModule(module_, (AnyDecl decl) {
		if (isUsedInModule(used, module_.uri, decl) && mustGet(lastIndexForName, decl.name) == 0)
			mustDelete(res, decl);
	});
	return moveToMap(alloc, res);
}
JsName localName(in Local a) =>
	localName(a.name);
JsName localName(Symbol a) =>
	JsName(a, some!ushort(99));

void eachExportOrTestInProgram(ref Program a, in void delegate(AnyDecl) @safe @nogc pure nothrow cb) {
	foreach (ref immutable Module* x; a.allModules)
		eachExportOrTestInModule(*x, cb);
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
void eachExportOrTestInModule(ref Module a, in void delegate(AnyDecl) @safe @nogc pure nothrow cb) {
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
	foreach (ref Test x; a.tests)
		cb(AnyDecl(&x));
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
		(Test* x) =>
			translateTest(ctx, x),
		(VarDecl* x) =>
			translateVarDecl(ctx, x));

JsDecl makeDecl(AnyDecl source, Visibility visibility, JsName name, JsDeclKind value) =>
	JsDecl(source, visibility == Visibility.private_ ? JsDecl.Exported.private_ : JsDecl.Exported.export_, name, value);

JsDecl translateTest(ref TranslateModuleCtx ctx, Test* a) {
	TranslateExprCtx exprCtx = TranslateExprCtx(ptrTrustMe(ctx), none!(FunDecl*));
	return makeDecl(AnyDecl(a), Visibility.public_, testName(ctx, a), JsDeclKind(genArrowFunction(
		JsParams(),
		translateExprToExprOrBlockStatement(exprCtx, a.body_, Type(ctx.commonTypes.void_)))));
}
JsDecl translateFunDecl(ref TranslateModuleCtx ctx, FunDecl* a) {
	TranslateExprCtx exprCtx = TranslateExprCtx(ptrTrustMe(ctx), some(a));
	JsParams params = translateFunParams(exprCtx, a.params);
	JsExpr fun = genArrowFunction(params, translateFunBody(exprCtx, a));
	JsExpr funWithSpecs = isEmpty(a.specs)
		? fun
		: genArrowFunction(JsParams(specParams(ctx.alloc, *a)), JsExprOrBlockStatement(allocate(ctx.alloc, fun)));
	return makeDecl(AnyDecl(a), a.visibility, funName(ctx, a), JsDeclKind(funWithSpecs));
}
SmallArray!JsDestructure specParams(ref Alloc alloc, in FunDecl a) =>
	buildSmallArray!JsDestructure(alloc, (scope ref Builder!JsDestructure out_) {
		eachSpecInFunIncludingParents(a, (SpecInst* spec) {
			foreach (ref Signature x; spec.decl.sigs)
				out_ ~= JsDestructure(JsName(x.name, some(specMangleIndex(sizeSoFar(out_)))));
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

JsParams translateFunParams(ref TranslateExprCtx ctx, in Params a) =>
	a.match!JsParams(
		(Destructure[] xs) =>
			JsParams(map!(JsDestructure, Destructure)(ctx.alloc, small!Destructure(xs), (ref Destructure x) =>
				translateDestructure(ctx, x))),
		(ref Params.Varargs x) =>
			JsParams(emptySmallArray!JsDestructure, some(translateDestructure(ctx, x.param))));
JsDestructure translateDestructure(ref TranslateExprCtx ctx, in Destructure a) =>
	a.matchIn!JsDestructure(
		(in Destructure.Ignore) =>
			JsDestructure(tempName(ctx, symbol!"ignore")),
		(in Local x) =>
			JsDestructure(localName(x)),
		(in Destructure.Split x) =>
			translateDestructureSplit(ctx, x));
JsDestructure translateDestructureSplit(ref TranslateExprCtx ctx, in Destructure.Split x) {
	SmallArray!RecordField fields = x.destructuredType.as!(StructInst*).decl.body_.as!(StructBody.Record).fields; // TODO: destructuredType will be Bogus if there's a compile error
	return JsDestructure(JsObjectDestructure(mapZip!(immutable KeyValuePair!(Symbol, JsDestructure), RecordField, Destructure)(
		ctx.alloc, fields, x.parts, (ref RecordField field, ref Destructure part) =>
			immutable KeyValuePair!(Symbol, JsDestructure)(field.name, translateDestructure(ctx, part)))));
}

JsDecl translateSpecDecl(ref TranslateModuleCtx ctx, SpecDecl* a) =>
	makeDecl(AnyDecl(a), a.visibility, specName(ctx, a), JsDeclKind(genNull())); // TODO: remove, we don't use these anywhere .-----------------

JsDecl translateStructAlias(ref TranslateModuleCtx ctx, StructAlias* a) =>
	makeDecl(AnyDecl(a), a.visibility, aliasName(ctx, a), JsDeclKind(JsExpr(JsName(a.target.decl.name))));

JsDecl translateStructDecl(ref TranslateModuleCtx ctx, StructDecl* a) {
	if (a.body_.isA!BuiltinType)
		return makeDecl(AnyDecl(a), a.visibility, structName(ctx, a), JsDeclKind(genNull()));

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
	return makeDecl(AnyDecl(a), a.visibility, structName(ctx, a), JsDeclKind(JsClassDecl(optFromMut!(JsExpr*)(extends), members)));
}

JsClassMember variantMethodImpl(ref TranslateModuleCtx ctx, Called a) {
	JsClassMethod method = () {
		if (isInlined(a)) {
			FunDecl* decl = a.as!(FunInst*).decl;
			TranslateExprCtx exprCtx = TranslateExprCtx(&ctx, none!(FunDecl*));
			return JsClassMethod(
				translateFunParams(exprCtx, decl.params),
				translateToBlockStatement(ctx.alloc, (scope ExprPos pos) =>
					translateInlineCall(exprCtx, a.returnType, pos, decl.body_, a.paramTypes, a.arity.as!uint, (size_t i) =>
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
		static members = [this.x]
	}
	*/
	JsName name = JsName(symbol!"name");
	out_ ~= genConstructor(ctx.alloc, [JsDestructure(name)], needSuper, [
		genAssign(ctx.alloc, genPropertyAccess(ctx.alloc, genThis(), symbol!"name"), JsExpr(name))]);
	foreach (ref EnumOrFlagsMember member; a.members) {
		out_ ~= JsClassMember(JsClassMember.Static.static_, member.name, JsClassMemberKind(
			genNew(ctx.alloc, genThis(), [genString(member.name)])));
	}
	out_ ~= JsClassMember(JsClassMember.Static.static_, symbol!"members", JsClassMemberKind(
		genArray(map(ctx.alloc, a.members, (ref EnumOrFlagsMember member) =>
			genPropertyAccess(ctx.alloc, genThis(), member.name))))); // TODO: what if a member is named 'members'? ----------------------
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
			JsDestructure(localName(x.name))), 
		needSuper,
		(scope ref ArrayBuilder!JsStatement out_) {
			foreach (ref RecordField x; a.fields) {
				genAssertType(out_, ctx, x.type, JsExpr(localName(x.name))); // TODO: make type assertions optional ----------------------------------------------------------------------------
				add(ctx.alloc, out_, genAssign(ctx.alloc, genPropertyAccess(ctx.alloc, genThis(), x.name), JsExpr(localName(x.name))));
			}
		});
}

void genAssertTypesForDestructure(scope ref ArrayBuilder!JsStatement out_, ref TranslateModuleCtx ctx, Destructure destructure) {
	eachLocal(destructure, (Local* x) {
		genAssertType(out_, ctx, x.type, translateLocalGet(x));
	});
}
void genAssertType(scope ref ArrayBuilder!JsStatement out_, ref TranslateModuleCtx ctx, Type type, JsExpr get) { //TODO:MOVE -----------------------------------------------------------------------------------------------------------------
	type.matchIn!void(
		(in Type.Bogus) {},
		(in TypeParamIndex _) {},
		(in StructInst x) {
			Opt!JsExpr notOk = x.decl.body_.isA!BuiltinType
				? genIsNotBuiltinType(ctx, x.decl.body_.as!BuiltinType, get)
				: some(genNot(ctx.alloc, genInstanceof(ctx.alloc, get, translateStructReference(ctx, x.decl))));
			if (has(notOk))
				add(ctx.alloc, out_, genIf(ctx.alloc, force(notOk), genThrowError(ctx, "Value did not have expected type")));
		});
}
Opt!JsExpr genIsNotBuiltinType(ref TranslateModuleCtx ctx, BuiltinType type, JsExpr get) {
	Opt!JsExpr typeof_(string expected) =>
		some(genNotEqEq(ctx.alloc, genTypeof(ctx.alloc, get), genString(expected)));
	final switch (type) {
		case BuiltinType.array:
		case BuiltinType.mutArray:
			return some(genNot(ctx.alloc, genInstanceof(ctx.alloc, get, JsExpr(JsName(symbol!"Array")))));
		case BuiltinType.bool_:
			return typeof_("boolean");
		case BuiltinType.catchPoint:
		case BuiltinType.float32:
		case BuiltinType.pointerConst:
		case BuiltinType.pointerMut:
			import util.writer : debugLogWithWriter, Writer;
			debugLogWithWriter((scope ref Writer writer) { // ------------------------------------------------------------------------------
				writer ~= "We should not use type ";
				writer ~= stringOfEnum(type);
			});
			return some(genBool(true));
			//assert(false);
		case BuiltinType.char8:
		case BuiltinType.char32:
		case BuiltinType.int8:
		case BuiltinType.int16:
		case BuiltinType.int32:
		case BuiltinType.int64:
		case BuiltinType.nat8:
		case BuiltinType.nat16:
		case BuiltinType.nat32:
		case BuiltinType.nat64:
			return typeof_("bigint");
		case BuiltinType.float64:
			return typeof_("number");
		case BuiltinType.funPointer:
			return typeof_("function");
		case BuiltinType.jsAny:
			return none!JsExpr;
		case BuiltinType.lambda:
			return typeof_("function");
		case BuiltinType.string_:
		case BuiltinType.symbol:
			return typeof_("string");
		case BuiltinType.void_:
			return typeof_("undefined");
	}
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
	out_ ~= genConstructor(ctx.alloc, [JsDestructure(arg)], needSuper, [
		JsStatement(genCallProperty(ctx.alloc, JsExpr(JsName(symbol!"Object")), symbol!"assign", [genThis(), JsExpr(arg)]))]);
	
	foreach (ref UnionMember member; a.members) {
		JsClassMemberKind kind = () {
			if (member.hasValue) {
				JsName value = JsName(symbol!"value");
				JsParams params = JsParams(newSmallArray!JsDestructure(ctx.alloc, [JsDestructure(value)]));
				ArrayBuilder!JsStatement out_;
				genAssertType(out_, ctx, member.type, JsExpr(value));
				add(ctx.alloc, out_, genReturn(ctx.alloc, genNew(ctx.alloc, genThis(), [genObject(ctx.alloc, member.name, JsExpr(value))])));
				// TODO: use a 'gen...' helper ---------------------------------------------------------------------------------------
				return JsClassMemberKind(JsClassMethod(params, genBlockStatement(ctx.alloc, finish(ctx.alloc, out_))));
			} else
				return JsClassMemberKind(genNew(ctx.alloc, genThis(), [genObject(ctx.alloc, member.name, genNull())]));
		}();
		out_ ~= JsClassMember(JsClassMember.Static.static_, member.name, kind);
	}
}

JsClassMember genConstructor(ref Alloc alloc, in JsDestructure[] params, bool needSuper, in JsStatement[] statements) =>
	genConstructor(alloc, newSmallArray(alloc, params), needSuper, (scope ref ArrayBuilder!JsStatement out_) {
		addAll(alloc, out_, statements);
	});
JsClassMember genConstructor(
	ref Alloc alloc,
	SmallArray!JsDestructure params,
	bool needSuper,
	in void delegate(scope ref ArrayBuilder!JsStatement) @safe @nogc pure nothrow cb,
) {
	ArrayBuilder!JsStatement out_;
	if (needSuper)
		add(alloc, out_, genSuper());
	cb(out_);
	JsBlockStatement body_ = JsBlockStatement(finish(alloc, out_));
	return JsClassMember(
		JsClassMember.Static.instance,
		symbol!"constructor",
		JsClassMemberKind(JsClassMethod(JsParams(params), body_)));
}

JsExpr super_ = JsExpr(JsName(symbol!"super"));
JsStatement genSuper() => JsStatement(genCall(&super_, []));

JsDecl translateVarDecl(ref TranslateModuleCtx ctx, VarDecl* a) =>
	todo!JsDecl("Use 'let' (same for global / thread-local)");

JsExprOrBlockStatement translateFunBody(ref TranslateExprCtx ctx, FunDecl* fun) {
	if (fun.body_.isA!(FunBody.FileImport))
		return todo!JsExprOrBlockStatement("FileImport body"); // -----------------------------------------------------------------------------------------------------
	else {
		if (fun.body_.isA!AutoFun)
			return translateAutoFun(ctx, fun, fun.body_.as!AutoFun);
		else if (fun.body_.isA!Expr) {
			if (true) { // TODO: make type assertions optional ----------------------------------------------------------------------------
				return JsExprOrBlockStatement(JsBlockStatement(translateToStatements(ctx.alloc, (scope ref ArrayBuilder!JsStatement out_, scope ExprPos pos) {
					foreach (ref Destructure param; paramsArray(fun.params))
						genAssertTypesForDestructure(out_, ctx, param);
					return translateExpr(ctx, fun.body_.as!Expr, fun.returnType, pos);
				})));
			} else
				return translateExprToExprOrBlockStatement(ctx, fun.body_.as!Expr, fun.returnType);
		} else {
			Destructure[] params = fun.params.as!(Destructure[]);
			Type[] paramTypes = map(ctx.alloc, params, (ref Destructure x) => x.type); // TODO: NO ALLOC ---------------------------
			return translateToExprOrBlockStatement(ctx.alloc, (scope ExprPos pos) =>
				translateInlineCall(ctx, fun.returnType, pos, fun.body_, paramTypes, params.length, (size_t i) =>
					translateLocalGet(params[i].as!(Local*))));
		}
	}
}

JsExprOrBlockStatement translateAutoFun(ref TranslateExprCtx ctx, FunDecl* fun, in AutoFun auto_) { // TODO: this is a lot like concretizeAutoFun...
	Destructure[] params = fun.params.as!(Destructure[]);
	JsExpr param(size_t i) =>
		translateLocalGet(params[i].as!(Local*));
	final switch (auto_.kind) {
		case AutoFun.Kind.compare:
			assert(params.length == 2);
			StructDecl* struct_ = params[0].type.as!(StructInst*).decl;
			StructDecl* comparison = fun.returnType.as!(StructInst*).decl;
			return struct_.body_.isA!(StructBody.Record)
				? translateCompareRecord(ctx, auto_, comparison, struct_.body_.as!(StructBody.Record).fields, param(0), param(1))
				: translateCompareUnion(ctx, auto_, comparison, struct_.body_.as!(StructBody.Union*).members, param(0), param(1));
		case AutoFun.Kind.equals:
			assert(params.length == 2);
			StructDecl* struct_ = params[0].type.as!(StructInst*).decl;
			return struct_.body_.isA!(StructBody.Record)
				? translateEqualRecord(ctx, auto_, struct_.body_.as!(StructBody.Record).fields, param(0), param(1))
				: translateEqualUnion(ctx, auto_, struct_.body_.as!(StructBody.Union*).members, param(0), param(1));
		case AutoFun.Kind.toJson:
			assert(params.length == 1);
			return todo!JsExprOrBlockStatement("to json"); // --------------------------------------------------------------------------------------
			// TODO: do I want to use the object itself as the JSON? Or still use the compiled union type?
			//return JsExprOrBlockStatement(translateLocalGet(param(0));
	}
}
JsExprOrBlockStatement translateCompareRecord(ref TranslateExprCtx ctx, in AutoFun auto_, StructDecl* comparison, RecordField[] fields, JsExpr p0, JsExpr p1) {
	return JsExprOrBlockStatement(genBlockStatement(ctx.alloc, [genThrowError(ctx, "TODO: COMPARE RECORD")])); // -----------------------------------------------------------------------------)
	// see 'genCompareOr' in generate.d
	/*
	const compareFoo = (p0, p1) => {
		const x = compareX(p0.x, p1.x)
		if (x != Comparison.equal)
			return x
		else {
			const y = compareY(p0.y, p1.y)
			if (y != Comparison.equal)
				return y
			else {
				return compareZ(p0.z, p1.z)
			}
		}
	}
	*/
}
JsExprOrBlockStatement translateCompareUnion(ref TranslateExprCtx ctx, in AutoFun auto_, StructDecl* comparison, UnionMember[] members, JsExpr p0, JsExpr p1) =>
	/*
	if ("x" in a)
		return "x" in b
			? compare(a.x, b.x)
			: less
	else if ("y" in a)
		return "y" in b
			? compare(a.y, b.y)
			// This needs to have a case for each preceding kind
			: "x" in b ? greater : less
	else
		throw
	*/
	JsExprOrBlockStatement(genBlockStatement(ctx.alloc, [
		// TODO: share code with translateEqualUnion ----------------------------------------------------------------------------
		foldReverseWithIndex!(JsStatement, UnionMember)(genThrowError(ctx, "Invalid union value"), members, (JsStatement else_, size_t index, ref UnionMember member) =>			genIf(
			ctx.alloc,
			genIn(ctx.alloc, member.name, p0),
			genReturn(ctx.alloc, translateCompareUnionPart(ctx, auto_, comparison, members, index, member, p0, p1)),
			else_))]));
JsExpr translateCompareUnionPart(ref TranslateExprCtx ctx, in AutoFun auto_, StructDecl* comparison, UnionMember[] members, size_t memberIndex, ref UnionMember member, JsExpr p0, JsExpr p1) {
	JsExpr comparisonRef = translateStructReference(ctx, comparison);
	JsExpr greater = genPropertyAccess(ctx.alloc, comparisonRef, symbol!"greater");
	JsExpr less = genPropertyAccess(ctx.alloc, comparisonRef, symbol!"less");
	JsExpr then = genCallCompareProperty(ctx, auto_.members[memberIndex], p0, p1, member.name);
	JsExpr else_ = memberIndex == 0
		? less
		: genTernary(
			ctx.alloc,
			combineWithOr!UnionMember(ctx.alloc, members[0 .. memberIndex], (ref UnionMember x) => genIn(ctx.alloc, x.name, p1)),
			greater, less);
	return genTernary(ctx.alloc, genIn(ctx.alloc, member.name, p1), then, else_);
}
JsExpr combineWithOr(T)(ref Alloc alloc, in T[] xs, in JsExpr delegate(ref T) @safe @nogc pure nothrow cb) =>
	mapReduce!(JsExpr, T)(xs, cb, (JsExpr x, JsExpr y) => genOr(alloc, x, y));

JsExprOrBlockStatement translateEqualRecord(ref TranslateExprCtx ctx, in AutoFun auto_, RecordField[] fields, JsExpr p0, JsExpr p1) =>
	JsExprOrBlockStatement(allocate(ctx.alloc, isEmpty(fields)
		? genBool(true)
		: foldRange!JsExpr(
			fields.length,
			(size_t i) =>
				genCallCompareProperty(ctx, auto_.members[i], p0, p1, fields[i].name),
			(JsExpr x, JsExpr y) => genAnd(ctx.alloc, x, y))));
JsExprOrBlockStatement translateEqualUnion(ref TranslateExprCtx ctx, in AutoFun auto_, UnionMember[] members, JsExpr p0, JsExpr p1) =>
	JsExprOrBlockStatement(genBlockStatement(ctx.alloc, [
		foldReverseWithIndex!(JsStatement, UnionMember)(genThrowError(ctx, "Invalid union value"), members, (JsStatement else_, size_t index, ref UnionMember member) =>
			// if ("foo" in a) return "foo" in b && eq(a.foo, b.foo) else <<else>>
			genIf(
				ctx.alloc,
				genIn(ctx.alloc, member.name, p0),
				genReturn(ctx.alloc, genAnd(
					ctx.alloc,
					genIn(ctx.alloc, member.name, p1),
					genCallCompareProperty(ctx, auto_.members[index], p0, p1, member.name))),
				else_))]));
JsExpr genCallCompareProperty(ref TranslateExprCtx ctx, Called called, JsExpr p0, JsExpr p1, Symbol name) =>
	isInlined(called)
		? translateToExpr((scope ExprPos pos) =>
			translateInlineCall(ctx, called.returnType, pos, called.as!(FunInst*).decl.body_, called.paramTypes, 2, (size_t i) {
				final switch (i) {
					case 0:
						return p0;
					case 1:
						return p1;
				}
			}))
		: genCall(ctx.alloc, calledExpr(ctx, called), [
			genPropertyAccess(ctx.alloc, p0, name),
			genPropertyAccess(ctx.alloc, p1, name)]);

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

JsBlockStatement translateExprToSwitchBlockStatement(ref TranslateExprCtx ctx, ref Expr a, Type type) =>
	isVoid(type)
		? translateToBlockStatement(ctx.alloc, (scope ExprPos pos) =>
			forceStatements(ctx.alloc, pos, (scope ref ArrayBuilder!JsStatement out_, scope ExprPos inner) {
				ExprResult result = translateExpr(ctx, a, type, inner);
				assert(result.isA!(ExprResult.Done));
				add(ctx.alloc, out_, genBreakNoLabel());
				return result;
			}))
		: translateExprToBlockStatement(ctx, a, type);

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
ExprResult forceStatements(ref TranslateExprCtx ctx, scope ExprPos pos, in StatementsCb cb) =>
	forceStatements(ctx.alloc, pos, cb);
ExprResult forceStatements(ref Alloc alloc, scope ExprPos pos, in StatementsCb cb) =>
	pos.match!ExprResult(
		(ExprPos.Expression) =>
			ExprResult(genIife(alloc, makeBlockStatement(alloc, cb))),
		(ExprPos.ExpressionOrBlockStatement) =>
			ExprResult(makeBlockStatement(alloc, cb)),
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
			ExprResult(genIife(alloc, genBlockStatement(alloc, [statement]))),
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
			translateCallOption(ctx, x, type, pos),
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
			forceExpr(ctx, pos, type, translateLiteralStringLike(ctx.alloc, x)),
		(LocalGetExpr x) {
			assert(type == x.local.type);
			return forceExpr(ctx, pos, type, translateLocalGet(x.local));
		},
		(LocalPointerExpr x) =>
			todo!ExprResult("LOCAL POINTER -- EMIT BOGUS"),
		(LocalSetExpr x) =>
			forceStatement(ctx, pos, genAssign(ctx.alloc, localName(*x.local), translateExprToExpr(ctx, *x.value, x.local.type))),
		(ref LoopExpr x) =>
			forceStatement(ctx, pos, genWhileTrue(ctx.alloc, some(JsName(symbol!"loop")), translateExprToBlockStatement(ctx, x.body_, type))),
		(ref LoopBreakExpr x) {
			assert(pos.isA!(ExprPos.Statements*));
			ExprResult res = translateExpr(ctx, x.value, type, pos);
			assert(res.isA!(ExprResult.Done));
			if (isVoid(type))
				add(ctx.alloc, pos.as!(ExprPos.Statements*).statements, genBreak(JsName(symbol!"loop")));
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
	import model.diag : TypeContainer, TypeWithContainer;
	import util.writer : debugLogWithWriter, Writer;
	assert(type == a.called.returnType);
	return isInlined(a.called)
		? translateInlineCall(ctx, type, pos, a.called.as!(FunInst*).decl.body_, a.called.as!(FunInst*).paramTypes, a.args.length, (size_t argIndex) =>
			translateExprToExpr(ctx, a.args[argIndex], paramTypeAt(a.called, argIndex)))
		: forceExpr(ctx, pos, type, genCall(
			allocate(ctx.alloc, calledExpr(ctx, a.called)),
			mapWithIndex!(JsExpr, Expr)(ctx.alloc, a.args, (size_t argIndex, ref Expr arg) =>
				translateExprToExpr(ctx, arg, paramTypeAt(a.called, argIndex)))));
}
ExprResult translateCallOption(ref TranslateExprCtx ctx, ref CallOptionExpr a, Type type, scope ExprPos pos) =>
	/*
	x?.f
	==>
	const option = x
	return "some" in option
		// 'Option.some' will be omitted if 'f' already returns an option
		? Option.some(f(option.some))
		: Option.none
	*/
	withTemp(ctx, symbol!"option", a.firstArg, pos, (JsName option, scope ExprPos inner) {
		JsExpr forceIt = genOptionForce(ctx.alloc, JsExpr(option));
		JsExpr call = isInlined(a.called)
			// TODO: share code with translateCall? -----------------------------------------------------------------------------------
			? translateToExpr((scope ExprPos callPos) =>
				translateInlineCall(ctx, a.called.returnType, callPos, a.called.as!(FunInst*).decl.body_, a.called.as!(FunInst*).paramTypes, 1 + a.restArgs.length, (size_t argIndex) =>
					argIndex == 0 ? forceIt : translateExprToExpr(ctx, a.restArgs[argIndex - 1], paramTypeAt(a.called, argIndex))))
			: genCall(allocate(ctx.alloc, calledExpr(ctx, a.called)),
				buildArray!JsExpr(ctx.alloc, (scope ref Builder!JsExpr out_) {
					out_ ~= forceIt;
					foreach (size_t index, ref Expr arg; a.restArgs)
						out_ ~= translateExprToExpr(ctx, arg, paramTypeAt(a.called, 1 + index));
				}));
		JsExpr then = a.called.returnType == type
			? call
			: genOptionSome(ctx, type, call);
		return forceExpr(ctx, inner, type, genTernary(
			ctx.alloc,
			genOptionHas(ctx.alloc, JsExpr(option)),
			then,
			genOptionNone(ctx, type)));
	});

bool isInlined(in Called a) =>
	a.isA!(FunInst*) && bodyIsInlined(*a.as!(FunInst*).decl);

ExprResult translateInlineCall(
	ref TranslateExprCtx ctx,
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
	JsExpr recordField(size_t fieldIndex) =>
		genPropertyAccess(ctx.alloc, getArg(0), recordFieldName(paramTypes[0], fieldIndex));
	return body_.matchIn!ExprResult(
		(in FunBody.Bogus) =>
			todo!ExprResult("BOGUS"),
		(in AutoFun x) =>
			assert(false),
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
		(in EnumFunction x) =>
			expr(translateEnumFunction(ctx, returnType, x, nArgs, getArg)),
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
			return expr(genCall(ctx.alloc, recordField(x.fieldIndex), [getArg(1)]));
		},
		(in FunBody.RecordFieldGet x) =>
			expr(recordField(x.fieldIndex)),
		(in FunBody.RecordFieldPointer) =>
			assert(false),
		(in FunBody.RecordFieldSet x) {
			assert(nArgs == 2);
			return forceStatement(ctx, pos, genAssign(ctx.alloc, recordField(x.fieldIndex), getArg(1)));
		},
		(in FunBody.UnionMemberGet x) =>
			withTemp2(ctx, symbol!"member", onlyArg(), pos, (JsName member, scope ExprPos inner) {
				Symbol memberName = unionMemberName(paramTypes[0], x.memberIndex);
				return forceExpr(ctx.alloc, inner, returnType, genTernary(
					ctx.alloc,
					genIn(ctx.alloc, memberName, JsExpr(member)),
					genOptionSome(ctx, returnType, genPropertyAccess(ctx.alloc, JsExpr(member), memberName)),
					genOptionNone(ctx, returnType)));
			}),
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
// TODO Maybe I should have used a direct pointer to the member here instead of an index ........................................
Symbol unionMemberName(Type union_, size_t memberIndex) =>
	union_.as!(StructInst*).decl.body_.as!(StructBody.Union*).members[memberIndex].name;

ExprResult translateCallBuiltin(
	ref TranslateExprCtx ctx,
	Type returnType,
	scope ExprPos pos,
	in BuiltinFun a,
	size_t nArgs,
	in JsExpr delegate(size_t) @safe @nogc pure nothrow getArg,
) {
	ExprResult expr(JsExpr value) =>
		forceExpr(ctx.alloc, pos, returnType, value);
	ExprResult call() =>
		expr(genCall(allocate(ctx.alloc, getArg(0)), makeArray(ctx.alloc, nArgs - 1, (size_t i) => getArg(i + 1))));
	return a.matchIn!ExprResult(
		(in BuiltinFun.AllTests) {
			assert(nArgs == 0);
			return expr(translateAllTests(ctx));
		},
		(in BuiltinUnary x) {
			assert(nArgs == 1);
			return expr(translateBuiltinUnary(ctx.alloc, x, getArg(0)));
		},
		(in BuiltinUnaryMath x) {
			assert(nArgs == 1);
			return expr(translateBuiltinUnaryMath(ctx.alloc, x, getArg(0)));
		},
		(in BuiltinBinary x) {
			assert(nArgs == 2);
			return translateBuiltinBinary(ctx, returnType, pos, x, getArg(0), getArg(1));
		},
		(in BuiltinBinaryLazy x) {
			assert(nArgs == 2);
			return translateBuiltinBinaryLazy(ctx, returnType, pos, x, getArg(0), getArg(1));
		},
		(in BuiltinBinaryMath x) =>
			todo!ExprResult("BUILTIN BINARY MATH"),
		(in BuiltinTernary x) =>
			todo!ExprResult("BUILTIN TERNARY"),
		(in Builtin4ary x) =>
			todo!ExprResult("BUILTIN 4ary"),
		(in BuiltinFun.CallLambda) =>
			call(),
		(in BuiltinFun.CallFunPointer) =>
			call(),
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
JsExpr translateEnumFunction(
	ref TranslateExprCtx ctx,
	Type returnType,
	EnumFunction a,
	size_t nArgs,
	in JsExpr delegate(size_t) @safe @nogc pure nothrow getArg,
) {
	JsExpr binary(JsBinaryExpr.Kind kind) {
		assert(nArgs == 2);
		return genBinary(ctx.alloc, kind, getArg(0), getArg(1));
	}

	final switch (a) {
		case EnumFunction.equal:
			return binary(JsBinaryExpr.Kind.eqEqEq);
		case EnumFunction.intersect:
			return binary(JsBinaryExpr.Kind.bitwiseAnd);
		case EnumFunction.members:
			assert(nArgs == 0);
			return genPropertyAccess(
				ctx.alloc,
				translateStructReference(ctx, returnType.as!(StructInst*).decl),
				symbol!"members");
		case EnumFunction.toIntegral:
			assert(nArgs == 1);
			return getArg(0);
		case EnumFunction.union_:
			return binary(JsBinaryExpr.Kind.bitwiseOr);
	}
}

JsExpr translateAllTests(ref TranslateExprCtx ctx) =>
	genArray(buildArray!JsExpr(ctx.alloc, (scope ref Builder!JsExpr out_) {
		eachTest(ctx.program, ctx.allExterns, (Test* test) {
			out_ ~= translateTestReference(ctx, test);
		});
	}));

JsExpr translateBuiltinUnary(ref Alloc alloc, BuiltinUnary a, JsExpr arg) {
	JsExpr BigInt = JsExpr(JsName(symbol!"BigInt"));
	JsExpr Number = JsExpr(JsName(symbol!"Number"));
	final switch (a) {
		case BuiltinUnary.arrayPointer:
		case BuiltinUnary.asAnyPointer:
		case BuiltinUnary.cStringOfSymbol:
		case BuiltinUnary.deref:
		case BuiltinUnary.drop:
		case BuiltinUnary.isNanFloat32:
		case BuiltinUnary.jumpToCatch:
		case BuiltinUnary.referenceFromPointer:
		case BuiltinUnary.setupCatch:
		case BuiltinUnary.symbolOfCString:
		case BuiltinUnary.toFloat32FromFloat64:
		case BuiltinUnary.toFloat64FromFloat32:
		case BuiltinUnary.toNat64FromPtr:
		case BuiltinUnary.toPtrFromNat64:
			// These are 'native extern'
			assert(false);
		case BuiltinUnary.arraySize:
			return genCall(alloc, BigInt, [genPropertyAccess(alloc, arg, symbol!"length")]);
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
			return genCallProperty(alloc, Number, symbol!"isNaN", [arg]);
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
			return genCall(alloc, Number, [arg]);
		case BuiltinUnary.toChar8ArrayFromString:
			// Array.from(new TextEncoder().encode(arg)).map(BigInt)
			return genCallProperty(
				alloc,
				genArrayFrom(
					alloc,
					genCallProperty(
						alloc,
						genNew(alloc, JsExpr(JsName(symbol!"TextEncoder")), []),
						symbol!"encode",
						[arg])),
				symbol!"map",
				[BigInt]);
		case BuiltinUnary.truncateToInt64FromFloat64:
			return genCall(alloc, BigInt, [callMath(alloc, symbol!"trunc", arg)]);
		case BuiltinUnary.trustAsString:
			// new TextDecoder().decode(new Uint8Array(arg.map(Number)))
			return genCallProperty(
				alloc,
				genNew(alloc, JsExpr(JsName(symbol!"TextDecoder")), []),
				symbol!"decode",
				[genNew(alloc, JsExpr(JsName(symbol!"Uint8Array")), [genCallProperty(alloc, arg, symbol!"map", [Number])])]);
	}
}
JsExpr genArrayFrom(ref Alloc alloc, JsExpr arg) =>
	genCallProperty(alloc, JsExpr(JsName(symbol!"Array")), symbol!"from", [arg]);

JsExpr translateBuiltinUnaryMath(ref Alloc alloc, BuiltinUnaryMath a, JsExpr arg) =>
	callMath(alloc, builtinUnaryMathName(a), arg);
JsExpr callMath(ref Alloc alloc, Symbol name, JsExpr arg) =>
	genCallProperty(alloc, JsExpr(JsName(symbol!"Math")), name, [arg]);
Symbol builtinUnaryMathName(BuiltinUnaryMath a) {
	final switch (a) {
		case BuiltinUnaryMath.acosFloat32:
		case BuiltinUnaryMath.acoshFloat32:
		case BuiltinUnaryMath.asinFloat32:
		case BuiltinUnaryMath.asinhFloat32:
		case BuiltinUnaryMath.atanFloat32:
		case BuiltinUnaryMath.atanhFloat32:
		case BuiltinUnaryMath.cosFloat32:
		case BuiltinUnaryMath.coshFloat32:
		case BuiltinUnaryMath.roundFloat32:
		case BuiltinUnaryMath.sinFloat32:
		case BuiltinUnaryMath.sinhFloat32:
		case BuiltinUnaryMath.sqrtFloat32:
		case BuiltinUnaryMath.tanFloat32:
		case BuiltinUnaryMath.tanhFloat32:
		case BuiltinUnaryMath.unsafeLogFloat32:
			assert(false);
		case BuiltinUnaryMath.acosFloat64:
			return symbol!"acos";
		case BuiltinUnaryMath.acoshFloat64:
			return symbol!"acosh";
		case BuiltinUnaryMath.asinFloat64:
			return symbol!"asin";
		case BuiltinUnaryMath.asinhFloat64:
			return symbol!"asinh";
		case BuiltinUnaryMath.atanFloat64:
			return symbol!"atan";
		case BuiltinUnaryMath.atanhFloat64:
			return symbol!"atanh";
		case BuiltinUnaryMath.cosFloat64:
			return symbol!"cos";
		case BuiltinUnaryMath.coshFloat64:
			return symbol!"cosh";
		case BuiltinUnaryMath.roundFloat64:
			return symbol!"round";
		case BuiltinUnaryMath.sinFloat64:
			return symbol!"sin";
		case BuiltinUnaryMath.sinhFloat64:
			return symbol!"sinh";
		case BuiltinUnaryMath.sqrtFloat64:
			return symbol!"sqrt";
		case BuiltinUnaryMath.tanFloat64:
			return symbol!"tan";
		case BuiltinUnaryMath.tanhFloat64:
			return symbol!"tanh";
		case BuiltinUnaryMath.unsafeLogFloat64:
			return symbol!"log";
	}
}

JsExpr genModulo(ref Alloc alloc, JsExpr left, JsExpr right) =>
	genBinary(alloc, JsBinaryExpr.Kind.modulo, left, right);
JsExpr moduloNat8(ref Alloc alloc, JsExpr arg) =>
	genModulo(alloc, arg, genIntegerUnsigned(0x100));
JsExpr moduloNat16(ref Alloc alloc, JsExpr arg) =>
	genModulo(alloc, arg, genIntegerUnsigned(0x10000));
JsExpr moduloNat32(ref Alloc alloc, JsExpr arg) =>
	genModulo(alloc, arg, genIntegerUnsigned(0x100000000));
JsExpr moduloNat64(ref Alloc alloc, JsExpr arg) =>
	genModulo(alloc, arg, genIntegerLarge("0x10000000000000000"));

ExprResult translateBuiltinBinary(ref TranslateExprCtx ctx, Type type, scope ExprPos pos, BuiltinBinary a, JsExpr left, JsExpr right) {
	ExprResult expr(JsExpr value) =>
		forceExpr(ctx.alloc, pos, type, value);
	JsExpr binary(JsBinaryExpr.Kind kind) =>
		genBinary(ctx.alloc, kind, left, right);
	JsExpr add() =>
		binary(JsBinaryExpr.Kind.plus);
	JsExpr mul() =>
		binary(JsBinaryExpr.Kind.times);
	final switch (a) {
		case BuiltinBinary.addFloat64:
		case BuiltinBinary.unsafeAddInt8:
		case BuiltinBinary.unsafeAddInt16:
		case BuiltinBinary.unsafeAddInt32:
		case BuiltinBinary.unsafeAddInt64:
		case BuiltinBinary.unsafeAddNat8:
		case BuiltinBinary.unsafeAddNat16:
		case BuiltinBinary.unsafeAddNat32:
		case BuiltinBinary.unsafeAddNat64:
			return expr(add());
		case BuiltinBinary.bitwiseAndInt8:
		case BuiltinBinary.bitwiseAndInt16:
		case BuiltinBinary.bitwiseAndInt32:
		case BuiltinBinary.bitwiseAndInt64:
		case BuiltinBinary.bitwiseAndNat8:
		case BuiltinBinary.bitwiseAndNat16:
		case BuiltinBinary.bitwiseAndNat32:
		case BuiltinBinary.bitwiseAndNat64:
			return expr(binary(JsBinaryExpr.Kind.bitwiseAnd));
		case BuiltinBinary.bitwiseOrInt8:
		case BuiltinBinary.bitwiseOrInt16:
		case BuiltinBinary.bitwiseOrInt32:
		case BuiltinBinary.bitwiseOrInt64:
		case BuiltinBinary.bitwiseOrNat8:
		case BuiltinBinary.bitwiseOrNat16:
		case BuiltinBinary.bitwiseOrNat32:
		case BuiltinBinary.bitwiseOrNat64:
			return expr(binary(JsBinaryExpr.Kind.bitwiseOr));
		case BuiltinBinary.bitwiseXorInt8:
		case BuiltinBinary.bitwiseXorInt16:
		case BuiltinBinary.bitwiseXorInt32:
		case BuiltinBinary.bitwiseXorInt64:
		case BuiltinBinary.bitwiseXorNat8:
		case BuiltinBinary.bitwiseXorNat16:
		case BuiltinBinary.bitwiseXorNat32:
		case BuiltinBinary.bitwiseXorNat64:
			return expr(binary(JsBinaryExpr.Kind.bitwiseXor));
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
		case BuiltinBinary.referenceEqual:
			return expr(binary(JsBinaryExpr.Kind.eqEqEq));
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
			return expr(binary(JsBinaryExpr.Kind.less));
		case BuiltinBinary.mulFloat64:
		case BuiltinBinary.unsafeMulInt8:
		case BuiltinBinary.unsafeMulInt16:
		case BuiltinBinary.unsafeMulInt32:
		case BuiltinBinary.unsafeMulInt64:
		case BuiltinBinary.unsafeMulNat8:
		case BuiltinBinary.unsafeMulNat16:
		case BuiltinBinary.unsafeMulNat32:
		case BuiltinBinary.unsafeMulNat64:
			return expr(mul());
		case BuiltinBinary.subFloat64:
		case BuiltinBinary.unsafeSubInt8:
		case BuiltinBinary.unsafeSubInt16:
		case BuiltinBinary.unsafeSubInt32:
		case BuiltinBinary.unsafeSubInt64:
		case BuiltinBinary.unsafeSubNat8:
		case BuiltinBinary.unsafeSubNat16:
		case BuiltinBinary.unsafeSubNat32:
		case BuiltinBinary.unsafeSubNat64:
			return expr(binary(JsBinaryExpr.Kind.minus));
		case BuiltinBinary.unsafeBitShiftLeftNat64:
			return expr(moduloNat64(ctx.alloc, binary(JsBinaryExpr.Kind.bitShiftLeft)));
		case BuiltinBinary.unsafeBitShiftRightNat64:
			return expr(moduloNat64(ctx.alloc, binary(JsBinaryExpr.Kind.bitShiftRight)));
		case BuiltinBinary.unsafeDivFloat64:
		case BuiltinBinary.unsafeDivInt8:
		case BuiltinBinary.unsafeDivInt16:
		case BuiltinBinary.unsafeDivInt32:
		case BuiltinBinary.unsafeDivInt64:
		case BuiltinBinary.unsafeDivNat8:
		case BuiltinBinary.unsafeDivNat16:
		case BuiltinBinary.unsafeDivNat32:
		case BuiltinBinary.unsafeDivNat64:
			return expr(binary(JsBinaryExpr.Kind.divide));
		case BuiltinBinary.unsafeModNat64:
			return expr(binary(JsBinaryExpr.Kind.modulo));
		case BuiltinBinary.wrapAddNat8:
			return expr(moduloNat8(ctx.alloc, add()));
		case BuiltinBinary.wrapAddNat16:
			return expr(moduloNat16(ctx.alloc, add()));
		case BuiltinBinary.wrapAddNat32:
			return expr(moduloNat32(ctx.alloc, add()));
		case BuiltinBinary.wrapAddNat64:
			return expr(moduloNat64(ctx.alloc, add()));
		case BuiltinBinary.wrapMulNat8:
			return expr(moduloNat8(ctx.alloc, mul()));
		case BuiltinBinary.wrapMulNat16:
			return expr(moduloNat16(ctx.alloc, mul()));
		case BuiltinBinary.wrapMulNat32:
			return expr(moduloNat32(ctx.alloc, mul()));
		case BuiltinBinary.wrapMulNat64:
			return expr(moduloNat64(ctx.alloc, mul()));
		case BuiltinBinary.wrapSubNat8:
		case BuiltinBinary.wrapSubNat16:
		case BuiltinBinary.wrapSubNat32:
		case BuiltinBinary.wrapSubNat64:
			return todo!ExprResult("Need to wrap negative values to positive. But js '%' is not really a mod!");
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
			return forceStatement(ctx.alloc, pos, genThrowError(ctx, "Called a builtin function not implemented in JS")); // this should not be possible, since thse functions are 'native extern'? ----------
	}
}
ExprResult translateBuiltinBinaryLazy(ref TranslateExprCtx ctx, Type type, scope ExprPos pos, BuiltinBinaryLazy kind, JsExpr left, JsExpr right) {
	final switch (kind) {
		case BuiltinBinaryLazy.boolAnd:
			return forceExpr(ctx.alloc, pos, type, genBinary(ctx.alloc, JsBinaryExpr.Kind.and, left, right));
		case BuiltinBinaryLazy.boolOr:
			return forceExpr(ctx.alloc, pos, type, genBinary(ctx.alloc, JsBinaryExpr.Kind.or, left, right));
		case BuiltinBinaryLazy.optionOr:
			return todo!ExprResult("option or");
		case BuiltinBinaryLazy.optionQuestion2:
			return withTemp2(ctx, symbol!"option", left, pos, (JsName option, scope ExprPos inner) =>
				forceExpr(ctx.alloc, inner, type, genTernary(
					ctx.alloc,
					genOptionHas(ctx.alloc, JsExpr(option)),
					genOptionForce(ctx.alloc, JsExpr(option)),
					right)));
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
	ExprResult binary(JsBinaryExpr.Kind kind) {
		assert(nArgs == 2);
		return expr(genBinary(ctx.alloc, kind, getArg(0), getArg(1)));
	}
	final switch (fun) {
		case JsFun.asJsAny:
		case JsFun.jsAnyAsT:
			assert(nArgs == 1);
			return expr(getArg(0));
		case JsFun.call:
			return expr(genCall(
				allocate(ctx.alloc, getArg(0)),
				makeArray(ctx.alloc, nArgs - 1, (size_t i) => getArg(i + 1))));
		case JsFun.cast_:
			assert(nArgs == 1);
			return expr(getArg(0));
		case JsFun.callProperty:
			assert(nArgs >= 2);
			return expr(genCall(
				allocate(ctx.alloc, genPropertyAccessComputed(ctx.alloc, getArg(0), getArg(1))),
				makeArray(ctx.alloc, nArgs - 2, (size_t i) => getArg(i + 2))));
		case JsFun.callPropertySpread:
			assert(nArgs == 3);
			return expr(genCallWithSpread(
				ctx.alloc,
				genPropertyAccessComputed(ctx.alloc, getArg(0), getArg(1)),
				[],
				getArg(2)));
		case JsFun.eqEqEq:
			return binary(JsBinaryExpr.Kind.eqEqEq);
		case JsFun.get:
			assert(nArgs == 2);
			return expr(genPropertyAccessComputed(ctx.alloc, getArg(0), getArg(1)));
		case JsFun.jsGlobal:
			assert(nArgs == 0);
			return expr(JsExpr(JsName(ctx.isBrowser ? symbol!"window" : symbol!"global")));
		case JsFun.less:
			return binary(JsBinaryExpr.Kind.less);
		case JsFun.null_:
			return expr(genNull());
		case JsFun.plus:
			return binary(JsBinaryExpr.Kind.plus);
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
	Opt!bool constant = tryEvalConstantBool(ctx.version_, ctx.allExterns, condition);
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
			genOptionHas(ctx.alloc, JsExpr(option)),
			translateToStatement(ctx.alloc, (scope ExprPos inner2) =>
				translateLetLikeCb(
					ctx, unpack.destructure, genOptionForce(ctx.alloc, JsExpr(option)), inner2,
					(scope ref ArrayBuilder!JsStatement, scope ExprPos inner3) =>
						cbTrueBranch(inner3))),
			translateToStatement(ctx.alloc, cbFalseBranch))));

//TODO:MOVE --------------------------------------------------------------------------------------------------------------------------------
JsExpr genOptionHas(ref Alloc alloc, JsExpr option) =>
	genIn(alloc, symbol!"some", option);
JsExpr genOptionForce(ref Alloc alloc, JsExpr option) =>
	genPropertyAccess(alloc, option, symbol!"some");
JsExpr genOptionSome(ref TranslateExprCtx ctx, Type option, JsExpr arg) =>
	genCallProperty(
		ctx.alloc,
		translateStructReference(ctx, option.as!(StructInst*).decl),
		symbol!"some",
		[arg]);
JsExpr genOptionNone(ref TranslateExprCtx ctx, Type option) =>
	genPropertyAccess(ctx.alloc, translateStructReference(ctx, option.as!(StructInst*).decl), symbol!"none");

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
	in StatementsCb cb,
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
JsExpr translateLiteralStringLike(ref Alloc alloc, ref LiteralStringLikeExpr a) {
	final switch (a.kind) {
		case LiteralStringLikeExpr.Kind.char8Array:
			return genArray(map(alloc, a.value, (ref immutable char x) =>
				genIntegerUnsigned(x)));
		case LiteralStringLikeExpr.Kind.char8List:
			return todo!JsExpr("Need to wrap as list"); // ----------------------------------------------------------------------
		case LiteralStringLikeExpr.Kind.char32Array:
			return genArray(buildArray!JsExpr(alloc, (scope ref Builder!JsExpr out_) {
				mustUnicodeDecode(a.value, (dchar x) {
					out_ ~= genIntegerUnsigned(x);
				});
			}));
		case LiteralStringLikeExpr.Kind.char32List:
			return todo!JsExpr("Need to wrap as list"); // ----------------------------------------------------------------------
		case LiteralStringLikeExpr.Kind.cString:
			assert(false);
		case LiteralStringLikeExpr.Kind.string_:
		case LiteralStringLikeExpr.Kind.symbol:
			return genString(a.value);
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
				add(ctx.alloc, res, genWhile(ctx.alloc, none!JsName, condition2, translateExprToBlockStatement(ctx, a.body_, Type(ctx.commonTypes.void_))));
				return translateExpr(ctx, a.after, type, inner);
			});
		},
		(ref Condition.UnpackOption unpack) {
			if (a.isUntil) {
				/*
				For an 'until':
				let option
				while (true) {
					option = <<option>>
					if ("some" in option) break
					<<body>>
				}
				const <<destructure>> = option.some
				<<after>>
				*/
				return todo!ExprResult("translate 'until x ?= option'"); // ----------------------------------------------------
			} else
				/*
				For a 'while':
				while (true) {
					const option = <<option>>
					if ("some" in option) {
						const <<destructure>> = option.some
						<<body>>
					} else
						break
				}
				<<after>>
				*/
				return forceStatements(ctx, pos, (scope ref ArrayBuilder!JsStatement outerOut, scope ExprPos outerPos) =>
					withTemp(ctx, symbol!"option", unpack.option, outerPos, (JsName option, scope ExprPos tempPos) {
						JsBlockStatement body_ = translateToBlockStatement(ctx.alloc, (scope ref ArrayBuilder!JsStatement out_, scope ExprPos bodyPos) =>
							translateUnpackOption(
								ctx, Type(ctx.commonTypes.void_), bodyPos, unpack,
								(scope ExprPos thenPos) =>
									translateExpr(ctx, a.body_, Type(ctx.commonTypes.void_), thenPos),
								(scope ExprPos elsePos) =>
									forceStatement(ctx, elsePos, genBreakNoLabel())));
						add(ctx.alloc, outerOut, genWhileTrue(ctx.alloc, none!JsName, body_));
						return translateExpr(ctx, a.after, type, tempPos);
					}));
		});

ExprResult translateMatchEnum(ref TranslateExprCtx ctx, ref MatchEnumExpr a, Type type, scope ExprPos pos) =>
	forceStatement(ctx, pos, genSwitch(
		ctx.alloc,
		translateExprToExpr(ctx, a.matched),
		map(ctx.alloc, a.cases, (ref MatchEnumExpr.Case case_) =>
			JsSwitchStatement.Case(
				translateEnumValue(ctx, case_.member),
				translateExprToSwitchBlockStatement(ctx, case_.then, type))),
		translateSwitchDefault(ctx, a.else_, type, "Invalid enum value")));

ExprResult translateMatchIntegral(ref TranslateExprCtx ctx, ref MatchIntegralExpr a, Type type, scope ExprPos pos) =>
	forceStatement(ctx, pos, genSwitch(
		ctx.alloc,
		translateExprToExpr(ctx, a.matched),
		map(ctx.alloc, a.cases, (ref MatchIntegralExpr.Case case_) =>
			JsSwitchStatement.Case(
				translateIntegralValue(a.kind, case_.value),
				translateExprToSwitchBlockStatement(ctx, case_.then, type))),
		translateExprToSwitchBlockStatement(ctx, a.else_, type)));

ExprResult translateMatchStringLike(ref TranslateExprCtx ctx, ref MatchStringLikeExpr a, Type type, scope ExprPos pos) =>
	forceStatement(ctx, pos, genSwitch(
		ctx.alloc,
		translateExprToExpr(ctx, a.matched),
		map(ctx.alloc, a.cases, (ref MatchStringLikeExpr.Case case_) =>
			JsSwitchStatement.Case(genString(case_.value), translateExprToSwitchBlockStatement(ctx, case_.then, type))),
		translateExprToSwitchBlockStatement(ctx, a.else_, type)));

ExprResult translateMatchUnion(ref TranslateExprCtx ctx, ref MatchUnionExpr a, Type type, scope ExprPos pos) =>
	withTemp(ctx, symbol!"matched", a.matched, pos, (JsName matched, scope ExprPos inner) =>
		translateMatchUnionOrVariant!(MatchUnionExpr.Case)(
			ctx, matched, a.cases, type, inner,
			translateSwitchDefault(ctx, has(a.else_) ? some(*force(a.else_)) : none!Expr, type, "Invalid union value"),
			(ref MatchUnionExpr.Case case_) =>
				MatchUnionOrVariantCase(
					genIn(ctx.alloc, case_.member.name, JsExpr(matched)),
					genPropertyAccess(ctx.alloc, JsExpr(matched), case_.member.name))));

ExprResult translateMatchVariant(ref TranslateExprCtx ctx, ref MatchVariantExpr a, Type type, scope ExprPos pos) =>
	withTemp(ctx, symbol!"matched", a.matched, pos, (JsName matched, scope ExprPos inner) =>
		translateMatchVariant(ctx, matched, a.cases, translateExprToBlockStatement(ctx, a.else_, type), type, inner));
ExprResult translateMatchVariant(
	ref TranslateExprCtx ctx,
	JsName matched,
	MatchVariantExpr.Case[] cases,
	JsBlockStatement else_,
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
	JsBlockStatement default_,
	in MatchUnionOrVariantCase delegate(ref Case) @safe @nogc pure nothrow cbCase,
) =>
	forceStatement(ctx, pos, foldReverse!(JsStatement, Case)(JsStatement(default_), cases, (JsStatement else_, ref Case case_) {
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
	withTemp2(ctx, name, translateExprToExpr(ctx, value), pos, cb);
ExprResult withTemp2(
	ref TranslateExprCtx ctx,
	Symbol name,
	JsExpr value,
	scope ExprPos pos,
	in ExprResult delegate(JsName temp, scope ExprPos inner) @safe @nogc pure nothrow cb,
) =>
	forceStatements(ctx, pos, (scope ref ArrayBuilder!JsStatement out_, scope ExprPos inner) {
		JsName jsName = tempName(ctx, name);
		add(ctx.alloc, out_, genConst(ctx.alloc, JsDestructure(jsName), value));
		return cb(jsName, inner);
	});
JsName tempName(ref TranslateExprCtx ctx, Symbol base) =>
	JsName(base, some(safeToUshort(ctx.nextTempIndex++)));

JsStatement genThrowError(ref TranslateModuleCtx ctx, string message) =>
	genThrow(ctx.alloc, genNewError(ctx, message));
JsExpr genNewError(ref TranslateModuleCtx ctx, string message) =>
	genNew(ctx.alloc, JsExpr(JsName(symbol!"Error")), [genString(message)]);

JsBlockStatement translateSwitchDefault(ref TranslateExprCtx ctx, Opt!Expr else_, Type type, string error) =>
	has(else_)
		? translateExprToSwitchBlockStatement(ctx, force(else_), type)
		: genBlockStatement(ctx.alloc, [genThrowError(ctx, error)]);

JsExpr translateEnumValue(ref TranslateModuleCtx ctx, EnumOrFlagsMember* a) =>
	genPropertyAccess(ctx.alloc, translateStructReference(ctx, a.containingEnum), a.name);
JsExpr translateIntegralValue(MatchIntegralExpr.Kind kind, IntegralValue value) => // TODO: maybe rename this to 'genInteger' and move to jsAst.d
	kind.isSigned ? genIntegerSigned(value.asSigned) : genIntegerUnsigned(value.asUnsigned);

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
			translateMatchVariant(
				ctx, exceptionName, a.catches,
				genBlockStatement(ctx.alloc, [genThrow(ctx.alloc, JsExpr(exceptionName))]),
				type, inner))));
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
	calledExpr(ctx.ctx, ctx.curFun, a);
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
			JsExpr(JsName(x.nonInstantiatedSig.name, some(specMangleIndex(findSigIndex(*force(curFun), x))))));

ushort specMangleIndex(size_t sigIndex) => // TODO: maybe mangling should take the 'kind' into account. Could store in 2 bits and leave rest for index.
	safeToUshort(1000 + sigIndex);

size_t findSigIndex(in FunDecl curFun, in CalledSpecSig called) {
	size_t res = 0;
	bool done = false;
	eachSpecInFunIncludingParents(curFun, (SpecInst* spec) { // TODO: this could return the first output...-------------------------
		if (done) return;
		if (spec == called.specInst) {
			res += called.sigIndex;
			done = true;
		} else
			res += spec.sigTypes.length;
	});
	assert(done);
	return res;
}
