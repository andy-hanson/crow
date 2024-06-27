module backend.js.translateToJs;

@safe @nogc pure nothrow:

import backend.js.allUsed :
	AllUsed, allUsed, AnyDecl, bodyIsInlined, isModuleUsed, isUsedAnywhere, isUsedInModule, tryEvalConstantBool;
import backend.js.jsAst :
	genAssign,
	genBool,
	genCall,
	genCallWithSpread,
	genConst,
	genEmptyStatement,
	genEqEqEq,
	genIf,
	genIn,
	genInstanceof,
	genIntegerSigned,
	genIntegerUnsigned,
	genLet,
	genNew,
	genNot,
	genNull,
	genNumber,
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
	genUndefined,
	genVarDecl,
	genWhile,
	JsArrowFunction,
	JsAssignStatement,
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
	JsObjectExpr,
	JsParams,
	JsPropertyAccessExpr,
	JsReturnStatement,
	JsStatement,
	JsSwitchStatement,
	JsTernaryExpr,
	JsThrowStatement,
	JsTryFinallyStatement,
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
	Destructure,
	eachImportOrReExport,
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
	SpecDecl,
	SpecInst,
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
	small,
	SmallArray;
import util.col.arrayBuilder : add, ArrayBuilder, buildArray, Builder, finish;
import util.col.hashTable : mustGet, withSortedKeys;
import util.col.map : KeyValuePair, Map, mustGet;
import util.col.mutArr : MutArr, push;
import util.col.mutMap : addOrChange, getOrAdd, hasKey, mapToArray, moveToMap, mustAdd, mustDelete, mustGet, MutMap;
import util.col.mutMultiMap : add, MutMultiMap;
import util.col.set : Set;
import util.col.sortUtil : sortInPlace;
import util.col.tempSet : TempSet, tryAdd, withTempSet;
import util.integralValues : IntegralValue;
import util.memory : allocate;
import util.opt : force, has, none, Opt, optIf, optOrDefault, some;
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
	in MutMap!(Module*, JsModuleAst) done,
	bool isNodeJs,
) =>
	buildArray!(immutable KeyValuePair!(Path, string))(alloc, (scope ref Builder!(immutable KeyValuePair!(Path, string)) out_) {
		if (isNodeJs)
			out_ ~= immutable KeyValuePair!(Path, string)(parsePath("package.json"), "{\"type\":\"module\"}");
		foreach (const Module* module_, ref JsModuleAst ast; done)
			out_ ~= immutable KeyValuePair!(Path, string)(mustGet(modulePaths, module_.uri), writeJsAst(alloc, ast, module_.uri == mainModuleUri));
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
	MutMap!(Module*, JsModuleAst) done; // TODO: maybe move this outside of TranslateProgramCtx. It's only used in doTranslateModule

	ref Alloc alloc() =>
		*allocPtr;
}

void doTranslateModule(ref TranslateProgramCtx ctx, Module* a) {
	if (!isModuleUsed(ctx.allUsed, a.uri) || hasKey(ctx.done, a)) return;
	foreach (ImportOrExport x; a.imports)
		doTranslateModule(ctx, x.modulePtr);
	foreach (ImportOrExport x; a.reExports)
		doTranslateModule(ctx, x.modulePtr);
	mustAdd(ctx.alloc, ctx.done, a, translateModule(ctx, *a));
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
		out_ ~= JsDecl(JsDecl.Exported.private_, JsName(symbol!"_global"), JsDeclKind(
			genTernary(
				ctx.alloc,
				genEqEqEq(ctx.alloc, genTypeof(ctx.alloc, JsExpr(JsName(symbol!"window"))), genUndefined()), // TODO: helper for JsExpr(JsName(symbol!"foo"))
				JsExpr(JsName(symbol!"window")),
				JsExpr(JsName(symbol!"global"))))); // TODO: have a (D) variable for '_global' to share in all the places it appears
		eachDeclInModule(a, (AnyDecl x) {
			if (isUsedAnywhere(ctx.allUsed, x)) {
				Opt!JsDecl res = translateDecl(moduleCtx, x);
				if (has(res))
					out_ ~= force(res);
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
		RelPath relPath = relativePath(importerPath, mustGet(ctx.modulePaths, x.module_.uri));
		if (isImportModuleWhole(x)) // TODO: I think we still need to track aliases used by a re-exporting module
			return some(JsImport(none!(JsName[]), relPath));
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

Opt!JsDecl translateDecl(ref TranslateModuleCtx ctx, AnyDecl x) =>
	x.matchWithPointers!(Opt!JsDecl)(
		(FunDecl* x) =>
			optIf(!bodyIsInlined(*x), () => translateFunDecl(ctx, x)),
		(SpecDecl* x) =>
			some(translateSpecDecl(ctx, x)),
		(StructAlias* x) =>
			some(translateStructAlias(ctx, x)),
		(StructDecl* x) =>
			translateStructDecl(ctx, x),
		(VarDecl* x) =>
			some(translateVarDecl(ctx, x)));

JsDecl makeDecl(Visibility visibility, JsName name, JsDeclKind value) =>
	JsDecl(visibility == Visibility.private_ ? JsDecl.Exported.private_ : JsDecl.Exported.export_, name, value);

JsDecl translateFunDecl(ref TranslateModuleCtx ctx, FunDecl* a) {
	JsParams params = a.params.match!JsParams(
		(Destructure[] xs) =>
			JsParams(map!(JsDestructure, Destructure)(ctx.alloc, small!Destructure(xs), (ref Destructure x) =>
				translateDestructure(ctx, x))),
		(ref Params.Varargs x) =>
			JsParams(emptySmallArray!JsDestructure, some(translateDestructure(ctx, x.param))));
	JsExpr fun = JsExpr(JsArrowFunction(params, translateFunBody(ctx, a.body_, a.returnType)));
	JsExpr funWithSpecs = isEmpty(a.specs)
		? fun
		: JsExpr(JsArrowFunction(
			JsParams(map!(JsDestructure, immutable SpecInst*)(ctx.alloc, a.specs, (ref immutable SpecInst* x) =>
				JsDestructure(JsName(x.name)))),
			JsExprOrBlockStatement(allocate(ctx.alloc, fun))));
	return makeDecl(a.visibility, funName(ctx, a), JsDeclKind(funWithSpecs));
}
JsDestructure translateDestructure(ref TranslateModuleCtx ctx, in Destructure a) =>
	a.matchIn!JsDestructure(
		(in Destructure.Ignore) =>
			JsDestructure(JsName(symbol!"_")),
		(in Local x) =>
			JsDestructure(JsName(x.name)),
		(in Destructure.Split x) =>
			translateDestructureSplit(ctx, x));
JsDestructure translateDestructureSplit(ref TranslateModuleCtx ctx, in Destructure.Split x) {
	SmallArray!RecordField fields = x.destructuredType.as!(StructInst*).decl.body_.as!(StructBody.Record).fields; // TODO: destructuredType will be Bogus if there's a compile error
	return JsDestructure(JsObjectDestructure(mapZip!(immutable KeyValuePair!(Symbol, JsDestructure), RecordField, Destructure)(
		ctx.alloc, fields, x.parts, (ref RecordField field, ref Destructure part) =>
			immutable KeyValuePair!(Symbol, JsDestructure)(field.name, translateDestructure(ctx, part)))));
}

JsDecl translateSpecDecl(ref TranslateModuleCtx ctx, in SpecDecl* a) =>
	makeDecl(a.visibility, specName(ctx, a), JsDeclKind(JsExpr(JsObjectExpr())));

JsDecl translateStructAlias(ref TranslateModuleCtx ctx, in StructAlias* a) =>
	makeDecl(a.visibility, aliasName(ctx, a), JsDeclKind(JsExpr(JsName(a.target.decl.name))));

Opt!JsDecl translateStructDecl(ref TranslateModuleCtx ctx, in StructDecl* a) {
	bool shouldEmit;
	JsClassMember[] members = buildArray!JsClassMember(ctx.alloc, (scope ref Builder!JsClassMember out_) {
		shouldEmit = a.body_.match!bool(
			(StructBody.Bogus) =>
				false,
			(BuiltinType x) =>
				false,
			(ref StructBody.Enum x) {
				translateEnumDecl(ctx, out_, x);
				return true;
			},
			(StructBody.Extern) =>
				assert(false),
			(StructBody.Flags) =>
				todo!bool("FLAGS"), // ------------------------------------------------------------------------------------------------------
			(StructBody.Record x) {
				translateRecord(ctx, out_, x);
				return true;
			},
			(ref StructBody.Union) {
				translateUnion(ctx, out_);
				return true;
			},
			(StructBody.Variant) =>
				todo!bool("VARIANT")); // ------------------------------------------------------------------------------------------------------

		foreach (ref VariantAndMethodImpls v; a.variants) {
			foreach (Opt!Called impl; v.methodImpls)
				if (has(impl))
					out_ ~= variantMethodImpl(ctx, force(impl));
		}
	});
	return optIf(shouldEmit, () =>
		makeDecl(a.visibility, structName(ctx, a), JsDeclKind(JsClassDecl(members))));
}

JsClassMember variantMethodImpl(ref TranslateModuleCtx ctx, Called a) {
	if (isInlined(a))
		return todo!JsClassMember("Inlined variant method impl"); // ------------------------------------------------------------------------------
	else {
		// foo(...args) { return foo(this, ...args) }
		JsName args = JsName(symbol!"args");
		JsParams params = JsParams(emptySmallArray!JsDestructure, some(JsDestructure(args)));
		JsBlockStatement body_ = JsBlockStatement(newArray(ctx.alloc, [
			genReturn(ctx.alloc, genCallWithSpread(ctx.alloc, calledExpr(ctx, a), [genThis()], JsExpr(args)))]));
		return JsClassMember(JsClassMember.Static.instance, a.name, JsClassMemberKind(JsClassMethod(params, body_)));
	}
}

void translateEnumDecl(ref TranslateModuleCtx ctx, scope ref Builder!JsClassMember out_, ref StructBody.Enum a) {
	/*
	class E {
		constructor(name) { this.name = name }
		static x = new this("x")
	}
	*/
	JsName name = JsName(symbol!"name");
	out_ ~= genConstructor(ctx.alloc, [JsDestructure(name)], [
		genAssign(ctx.alloc, genPropertyAccess(ctx.alloc, genThis(), symbol!"name"), JsExpr(name))]);
	foreach (ref EnumOrFlagsMember member; a.members) {
		out_ ~= JsClassMember(JsClassMember.Static.static_, member.name, JsClassMemberKind(
			genNew(ctx.alloc, genThis(), [genString(stringOfSymbol(ctx.alloc, member.name))])));
	}
}

void translateRecord(ref TranslateModuleCtx ctx, scope ref Builder!JsClassMember out_, ref StructBody.Record a) {
	/*
	class R {
		constructor(x, fooBar) {
			this.x = x
			this["foo-bar"] = fooBar
		}
	}
	*/
	out_ ~= genConstructor(
		map!(JsDestructure, RecordField)(ctx.alloc, a.fields, (ref RecordField x) =>
			JsDestructure(JsName(x.name))),
		map(ctx.alloc, a.fields, (ref RecordField x) =>
			genAssign(ctx.alloc, genPropertyAccess(ctx.alloc, genThis(), x.name), JsExpr(JsName(x.name)))));
}

void translateUnion(ref TranslateModuleCtx ctx, scope ref Builder!JsClassMember out_) {
	/*
	class U {
		constructor(arg) {
			Object.assign(this, arg)
		}
	}
	*/
	JsName arg = JsName(symbol!"arg");
	out_ ~= genConstructor(ctx.alloc, [JsDestructure(arg)], [
		JsStatement(genCall(
			ctx.alloc,
			genPropertyAccess(ctx.alloc, JsExpr(JsName(symbol!"Object")), symbol!"assign"),
			[genThis(), JsExpr(arg)]))]);
}

JsClassMember genConstructor(ref Alloc alloc, in JsDestructure[] params, in JsStatement[] body_) =>
	genConstructor(newSmallArray(alloc, params), newArray(alloc, body_));
JsClassMember genConstructor(SmallArray!JsDestructure params, JsStatement[] body_) =>
	JsClassMember(
		JsClassMember.Static.instance,
		symbol!"constructor",
		JsClassMemberKind(JsClassMethod(JsParams(params), JsBlockStatement(body_))));

JsDecl translateVarDecl(ref TranslateModuleCtx ctx, VarDecl* a) =>
	todo!JsDecl("Use 'let' (same for global / thread-local)");

JsExprOrBlockStatement translateFunBody(ref TranslateModuleCtx ctx, in FunBody x, Type returnType) =>
	x.isA!(FunBody.FileImport)
		? todo!JsExprOrBlockStatement("FileImport body") // -----------------------------------------------------------------------------------------------------
		: translateExprToExprOrBlockStatement(ctx, x.as!Expr, returnType);

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
	mixin Union!(Done, JsExpr, JsStatement[]);

	static ExprResult done() =>
		ExprResult(ExprResult.Done());
}

JsExpr translateExprToExpr(ref TranslateModuleCtx ctx, ExprAndType a) =>
	translateExprToExpr(ctx, a.expr, a.type);
JsExpr translateExprToExpr(ref TranslateModuleCtx ctx, ref Expr a, Type type) =>
	translateExpr(ctx, a, type, ExprPos(ExprPos.Expression())).as!JsExpr;
JsStatement translateToStatement(ref Alloc alloc, in ExprResult delegate(scope ExprPos) @safe @nogc pure nothrow cb) =>
	translateToStatement(alloc, (scope ref ArrayBuilder!JsStatement, scope ExprPos pos) => cb(pos));
alias StatementsCb = ExprResult delegate(scope ref ArrayBuilder!JsStatement, scope ExprPos) @safe @nogc pure nothrow;
JsStatement translateToStatement(ref Alloc alloc, in StatementsCb cb) {
	JsStatement[] statements = translateToStatements(alloc, cb);
	return statements.length == 1 ? only(statements) : JsStatement(JsBlockStatement(statements));
}
JsBlockStatement translateToBlockStatement(ref Alloc alloc, in StatementsCb cb) =>
	JsBlockStatement(translateToStatements(alloc, cb));
JsBlockStatement translateToBlockStatement(ref Alloc alloc, in ExprResult delegate(scope ExprPos) @safe @nogc pure nothrow cb) =>
	translateToBlockStatement(alloc, (scope ref ArrayBuilder!JsStatement, scope ExprPos pos) => cb(pos));
JsStatement[] translateToStatements(ref Alloc alloc, in StatementsCb cb) {
	ExprPos.Statements pos;
	ExprResult res = cb(pos.statements, ExprPos(&pos));
	assert(res.isA!(ExprResult.Done));
	JsStatement[] statements = finish(alloc, pos.statements);
	assert(!isEmpty(statements));
	return statements;
}

JsStatement translateExprToStatement(ref TranslateModuleCtx ctx, ref Expr a, Type type) =>
	translateToStatement(ctx.alloc, (scope ExprPos pos) => translateExpr(ctx, a, type, pos));
JsBlockStatement translateExprToBlockStatement(ref TranslateModuleCtx ctx, ref Expr a, Type type) =>
	translateToBlockStatement(ctx.alloc, (scope ExprPos pos) => translateExpr(ctx, a, type, pos));
JsExprOrBlockStatement translateExprToExprOrBlockStatement(ref TranslateModuleCtx ctx, ref Expr a, Type type) =>
	translateExpr(ctx, a, type, ExprPos(ExprPos.ExpressionOrBlockStatement())).match!JsExprOrBlockStatement(
		(ExprResult.Done) =>
			assert(false),
		(JsExpr x) =>
			JsExprOrBlockStatement(allocate(ctx.alloc, x)),
		(JsStatement[] x) =>
			JsExprOrBlockStatement(JsBlockStatement(x)));

ExprResult forceExpr(ref TranslateModuleCtx ctx, scope ExprPos pos, Type type, JsExpr expr) =>
	pos.match!ExprResult(
		(ExprPos.Expression) =>
			ExprResult(expr),
		(ExprPos.ExpressionOrBlockStatement) =>
			ExprResult(expr),
		(ref ExprPos.Statements x) {
			add(ctx.alloc, x.statements, isVoid(type) ? JsStatement(expr) : genReturn(ctx.alloc, expr));
			return ExprResult.done;
		});

ExprResult forceStatements(ref TranslateModuleCtx ctx, scope ExprPos pos, in ExprResult delegate(scope ref ArrayBuilder!JsStatement, scope ExprPos) @safe @nogc pure nothrow cb) =>
	pos.match!ExprResult(
		(ExprPos.Expression) =>
			todo!ExprResult("USE AN IIFE"),
		(ExprPos.ExpressionOrBlockStatement) {
			ExprPos.Statements res;
			ExprResult inner = cb(res.statements, ExprPos(&res));
			assert(inner.isA!(ExprResult.Done));
			return ExprResult(finish(ctx.alloc, res.statements));
		},
		(ref ExprPos.Statements x) =>
			cb(x.statements, pos));

ExprResult forceStatement(ref TranslateModuleCtx ctx, scope ExprPos pos, JsStatement statement) =>
	pos.match!ExprResult(
		(ExprPos.Expression) =>
			todo!ExprResult("USE AN IIFE"),
		(ExprPos.ExpressionOrBlockStatement) =>
			ExprResult(newArray(ctx.alloc, [statement])),
		(ref ExprPos.Statements x) {
			add(ctx.alloc, x.statements, statement);
			return ExprResult.done;
		});

ExprResult translateExpr(ref TranslateModuleCtx ctx, ref Expr a, Type type, scope ExprPos pos) =>
	a.kind.match!ExprResult(
		(ref AssertOrForbidExpr x) =>
			translateAssertOrForbid(ctx, x, type, pos),
		(BogusExpr x) =>
			todo!ExprResult("BOGUS"),
		(CallExpr x) =>
			translateCall(ctx, x, type, pos),
		(ref CallOptionExpr x) =>
			todo!ExprResult("CALL OPTION"),
		(ClosureGetExpr x) =>
			forceExpr(ctx, pos, type, JsExpr(JsName(x.local.name))),
		(ClosureSetExpr x) =>
			forceStatement(ctx, pos, genAssign(ctx.alloc,  JsName(x.local.name), translateExprToExpr(ctx, *x.value, x.local.type))),
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
			forceExpr(ctx, pos, type, JsExpr(JsName(x.local.name))),
		(LocalPointerExpr x) =>
			todo!ExprResult("LOCAL POINTER -- EMIT BOGUS"),
		(LocalSetExpr x) =>
			forceStatement(ctx, pos, genAssign(ctx.alloc, JsName(x.local.name), translateExprToExpr(ctx, *x.value, x.local.type))),
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

ExprResult translateAssertOrForbid(ref TranslateModuleCtx ctx, ref AssertOrForbidExpr a, Type type, scope ExprPos pos) =>
	forceStatements(ctx, pos, (scope ref ArrayBuilder!JsStatement res, scope ExprPos inner) {
		JsExpr cond = todo!JsExpr("translate condition"); //translateExprToExpr(ctx, x.condition);
		JsExpr cond2 = a.isForbid ? cond : genNot(ctx.alloc, cond);
		JsExpr thrown = has(a.thrown)
			? translateExprToExpr(ctx, *force(a.thrown), todo!Type("Exception type"))
			: todo!JsExpr("default thrown");
		add(ctx.alloc, res, genIf(ctx.alloc, cond2, genThrow(ctx.alloc, thrown), genEmptyStatement()));
		return translateExpr(ctx, a.after, type, inner);
	});

ExprResult translateCall(ref TranslateModuleCtx ctx, ref CallExpr a, Type type, scope ExprPos pos) {
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
		forceExpr(ctx, pos, returnType, value);
	JsExpr onlyArg() {
		assert(nArgs == 1);
		return getArg(0);
	}
	JsExpr[] args() =>
		makeArray(ctx.alloc, nArgs, getArg);
	return body_.matchIn!ExprResult(
		(in FunBody.Bogus) =>
			todo!ExprResult("BOGUS"),
		(in AutoFun) =>
			todo!ExprResult("AUTO"),
		(in BuiltinFun x) =>
			translateCallBuiltin(ctx, returnType, pos, x, nArgs, getArg),
		(in FunBody.CreateEnumOrFlags x) =>
			expr(genPropertyAccess(ctx.alloc, translateStructReference(ctx, returnType.as!(StructInst*).decl), x.member.name)),
		(in FunBody.CreateExtern) =>
			assert(false),
		(in FunBody.CreateRecord) =>
			expr(genNew(ctx.alloc, translateStructReference(ctx, returnType.as!(StructInst*).decl), args())),
		(in FunBody.CreateRecordAndConvertToVariant) =>
			todo!ExprResult("CREATE RECORD AS VARIANT"), // should be identical to CreateRecord
		(in FunBody.CreateUnion) =>
			todo!ExprResult("CREATE UNION"),
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
		(in FunBody.VariantMethod) =>
			// x.foo(...args)
			todo!ExprResult("VARIANT METHOD"),
		(in FunBody.VarSet) =>
			todo!ExprResult("VAR SET"));
}
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
		forceExpr(ctx, pos, returnType, value);
	return a.matchIn!ExprResult(
		(in BuiltinFun.AllTests) =>
			todo!ExprResult("ALL TESTS"), // ----------------------------------------------------------------
		(in BuiltinUnary x) =>
			todo!ExprResult("BUILTIN UNARY"),
		(in BuiltinUnaryMath x) =>
			todo!ExprResult("BUILTIN UNARY MATH"),
		(in BuiltinBinary x) =>
			todo!ExprResult("BUILTIN BINARY"),
		(in BuiltinBinaryLazy x) =>
			todo!ExprResult("BUILTIN BINARY LAZY"),
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
ExprResult translateCallJsFun(
	ref TranslateModuleCtx ctx,
	Type returnType,
	scope ExprPos pos,
	JsFun fun,
	size_t nArgs,
	in JsExpr delegate(size_t) @safe @nogc pure nothrow getArg,
) {
	ExprResult expr(JsExpr value) =>
		forceExpr(ctx, pos, returnType, value);
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
			return expr(JsExpr(JsName(symbol!"_global")));
		case JsFun.set:
			assert(nArgs == 3);
			return forceStatement(ctx, pos, genAssign(ctx.alloc, genPropertyAccessComputed(ctx.alloc, getArg(0), getArg(1)), getArg(2)));
	}
}

ExprResult translateIf(ref TranslateModuleCtx ctx, ref IfExpr a, Type type, scope ExprPos pos) {
	Opt!bool constant = tryEvalConstantBool(ctx.version_, ctx.allExtern, a.condition);
	if (has(constant))
		return translateExpr(ctx, force(constant) ? a.trueBranch : a.falseBranch, type, pos);
	else if (pos.isA!(ExprPos.Expression) && a.condition.isA!(Expr*))
		return ExprResult(genTernary(
			ctx.alloc,
			translateExprToExpr(ctx, *a.condition.as!(Expr*), Type(ctx.commonTypes.bool_)),
			translateExprToExpr(ctx, a.trueBranch, type),
			translateExprToExpr(ctx, a.falseBranch, type)));
	else
		return a.condition.match!ExprResult(
			(ref Expr cond) =>
				forceStatement(ctx, pos, genIf(ctx.alloc,
					translateExprToExpr(ctx, cond, Type(ctx.commonTypes.bool_)),
					translateExprToStatement(ctx, a.trueBranch, type),
					translateExprToStatement(ctx, a.falseBranch, type))),
			(ref Condition.UnpackOption x) =>
				forceStatements(ctx, pos, (scope ref ArrayBuilder!JsStatement out_, scope ExprPos inner) {
					return todo!ExprResult("UNPACK OPTION"); // ---------------------------------------------------------------------
					/*
					For an UnpackOption, compile to:
					const option = someExpr ...
					if ('some' in option) {
						const destructure = option.some
						then
					} else {
						else_
					}
					*/
				}));
}

ExprResult translateLambda(ref TranslateModuleCtx ctx, ref LambdaExpr a, Type type, scope ExprPos pos) =>
	forceExpr(ctx, pos, type, JsExpr(JsArrowFunction(
		JsParams(newSmallArray(ctx.alloc, [translateDestructure(ctx, a.param)])),
		translateExprToExprOrBlockStatement(ctx, a.body_, a.returnType))));

ExprResult translateLet(ref TranslateModuleCtx ctx, ref LetExpr a, Type type, scope ExprPos pos) =>
	translateLetLike(ctx, a.destructure, translateExprToExpr(ctx, a.value, a.destructure.type), a.then, type, pos);
ExprResult translateLetLike(
	ref TranslateModuleCtx ctx,
	ref Destructure destructure,
	JsExpr value,
	ref Expr then,
	Type type,
	scope ExprPos pos,
) =>
	translateLetLikeCb(ctx, destructure, value, pos, (scope ref ArrayBuilder!JsStatement, scope ExprPos inner) =>
		translateExpr(ctx, then, type, inner));
ExprResult translateLetLikeCb(
	ref TranslateModuleCtx ctx,
	ref Destructure destructure,
	JsExpr value,
	scope ExprPos pos,
	in ExprResult delegate(scope ref ArrayBuilder!JsStatement, scope ExprPos) @safe @nogc pure nothrow cb,
) =>
	forceStatements(ctx, pos, (scope ref ArrayBuilder!JsStatement out_, scope ExprPos inner) {
		add(ctx.alloc, out_, destructure.isA!(Destructure.Ignore*)
			? JsStatement(value)
			: genVarDecl(
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

ExprResult translateLoopWhileOrUntil(ref TranslateModuleCtx ctx, ref LoopWhileOrUntilExpr a, Type type, scope ExprPos pos) =>
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

ExprResult translateMatchEnum(ref TranslateModuleCtx ctx, ref MatchEnumExpr a, Type type, scope ExprPos pos) =>
	forceStatement(ctx, pos, genSwitch(
		ctx.alloc,
		translateExprToExpr(ctx, a.matched),
		map(ctx.alloc, a.cases, (ref MatchEnumExpr.Case case_) =>
			JsSwitchStatement.Case(
				translateEnumValue(ctx, case_.member),
				translateExprToBlockStatement(ctx, case_.then, type))),
		translateSwitchDefault(ctx, a.else_, type, "Invalid enum value")));

ExprResult translateMatchIntegral(ref TranslateModuleCtx ctx, ref MatchIntegralExpr a, Type type, scope ExprPos pos) =>
	forceStatement(ctx, pos, genSwitch(
		ctx.alloc,
		translateExprToExpr(ctx, a.matched),
		map(ctx.alloc, a.cases, (ref MatchIntegralExpr.Case case_) =>
			JsSwitchStatement.Case(
				translateIntegralValue(a.kind, case_.value),
				translateExprToBlockStatement(ctx, case_.then, type))),
		translateExprToStatement(ctx, a.else_, type)));

ExprResult translateMatchStringLike(ref TranslateModuleCtx ctx, ref MatchStringLikeExpr a, Type type, scope ExprPos pos) =>
	forceStatement(ctx, pos, genSwitch(
		ctx.alloc,
		translateExprToExpr(ctx, a.matched),
		map(ctx.alloc, a.cases, (ref MatchStringLikeExpr.Case case_) =>
			JsSwitchStatement.Case(genString(case_.value), translateExprToBlockStatement(ctx, case_.then, type))),
		translateExprToStatement(ctx, a.else_, type)));

ExprResult translateMatchUnion(ref TranslateModuleCtx ctx, ref MatchUnionExpr a, Type type, scope ExprPos pos) =>
	withTemp(ctx, symbol!"matched", a.matched, pos, (JsName matched, scope ExprPos inner) =>
		translateMatchUnionOrVariant!(MatchUnionExpr.Case)(
			ctx, matched, a.cases, type, inner,
			translateSwitchDefault(ctx, has(a.else_) ? some(*force(a.else_)) : none!Expr, type, "Invalid union value"),
			(ref MatchUnionExpr.Case case_) =>
				MatchUnionOrVariantCase(
					genIn(ctx.alloc, genString(stringOfSymbol(ctx.alloc, case_.member.name)), JsExpr(matched)),
					genPropertyAccess(ctx.alloc, JsExpr(matched), case_.member.name))));

ExprResult translateMatchVariant(ref TranslateModuleCtx ctx, ref MatchVariantExpr a, Type type, scope ExprPos pos) =>
	withTemp(ctx, symbol!"matched", a.matched, pos, (JsName matched, scope ExprPos inner) =>
		translateMatchVariant(ctx, matched, a.cases, translateExprToStatement(ctx, a.else_, type), type, inner));
ExprResult translateMatchVariant(
	ref TranslateModuleCtx ctx,
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
	ref TranslateModuleCtx ctx,
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
	ref TranslateModuleCtx ctx,
	Symbol name,
	ExprAndType value,
	scope ExprPos pos,
	in ExprResult delegate(JsName temp, scope ExprPos inner) @safe @nogc pure nothrow cb,
) =>
	forceStatements(ctx, pos, (scope ref ArrayBuilder!JsStatement out_, scope ExprPos inner) {
		JsName jsName = JsName(name);
		add(ctx.alloc, out_, genConst(ctx.alloc, JsDestructure(jsName), translateExprToExpr(ctx, value)));
		return cb(jsName, inner);
	});

JsStatement throwError(ref TranslateModuleCtx ctx, string message) =>
	genThrow(ctx.alloc, genNew(ctx.alloc, JsExpr(JsName(symbol!"Error")), [genString(message)]));

JsStatement translateSwitchDefault(ref TranslateModuleCtx ctx, Opt!Expr else_, Type type, string error) =>
	has(else_)
		? translateExprToStatement(ctx, force(else_), type)
		: throwError(ctx, error);

JsExpr translateEnumValue(ref TranslateModuleCtx ctx, EnumOrFlagsMember* a) =>
	genPropertyAccess(ctx.alloc, translateStructReference(ctx, a.containingEnum), a.name);
JsExpr translateIntegralValue(MatchIntegralExpr.Kind kind, IntegralValue value) =>
	genNumber(kind.isSigned ? double(value.asSigned) : double(value.asUnsigned));

ExprResult translateFinally(ref TranslateModuleCtx ctx, ref FinallyExpr a, Type type, scope ExprPos pos) =>
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

ExprResult translateTry(ref TranslateModuleCtx ctx, ref TryExpr a, Type type, scope ExprPos pos) {
	JsName exceptionName = JsName(symbol!"exception");
	JsExpr exn = JsExpr(exceptionName);
	return forceStatement(ctx, pos, genTryCatch(
		ctx.alloc,
		translateExprToBlockStatement(ctx, a.tried, type),
		exceptionName,
		translateToBlockStatement(ctx.alloc, (scope ExprPos inner) =>
			translateMatchVariant(ctx, exceptionName, a.catches, genThrow(ctx.alloc, JsExpr(exceptionName)), type, inner))));
}

ExprResult translateTryLet(ref TranslateModuleCtx ctx, ref TryLetExpr a, Type type, scope ExprPos pos) =>
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
JsExpr calledExpr(ref TranslateModuleCtx ctx, in Called a) =>
	a.match!JsExpr(
		(ref Called.Bogus x) =>
			todo!JsExpr("BOGUS"), // ------------------------------------------------------------------------------------------------------------
		(ref FunInst x) {
			JsExpr fun = translateFunReference(ctx, x.decl);
			return isEmpty(x.specImpls)
				? fun
				: genCall(allocate(ctx.alloc, fun), map(ctx.alloc, x.specImpls, (ref Called x) => calledExpr(ctx, x)));
		},
		(CalledSpecSig x) =>
			genPropertyAccess(ctx.alloc, JsExpr(JsName(x.specInst.decl.name)), x.nonInstantiatedSig.name));
