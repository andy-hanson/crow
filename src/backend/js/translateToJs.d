module backend.js.translateToJs;

@safe @nogc pure nothrow:

import backend.js.allUsed :
	AllUsed,
	allUsed,
	AnyDecl,
	eachNameReferent,
	eachStructAliasInImports,
	isModuleUsed,
	isUsedAnywhere,
	isUsedInModule;
import backend.js.jsAst :
	compareJsName,
	exprStatement,
	genArray,
	genArrowFunction,
	genAssign,
	genBinary,
	genBitwiseAnd,
	genBitwiseNot,
	genBlockStatement,
	genCall,
	genCallPropertySync,
	genCallSync,
	genConst,
	genField,
	genGlobal,
	genIf,
	genInstanceMethod,
	genInteger,
	genIntegerUnsigned,
	genLocalGet,
	genNew,
	genNotEqEq,
	genNull,
	genNumber,
	genObject,
	genPlus,
	genPropertyAccess,
	genReturn,
	genStaticMethod,
	genString,
	genStringFromSymbol,
	genThis,
	genThrow,
	JsBinaryExpr,
	JsBlockStatement,
	JsClassDecl,
	JsClassMember,
	JsDecl,
	JsDeclKind,
	JsDestructure,
	JsExpr,
	JsImport,
	JsMemberName,
	JsModuleAst,
	JsName,
	JsParams,
	JsScriptAst,
	JsStatement,
	Shebang,
	SyncOrAsync;
import backend.js.sourceMap : JsAndMap, ModulePaths, noSource, Source;
import backend.js.translateExpr : genAssertType, genNewPair, translateFunDecl, translateTest, variantMethodImpl;
import backend.js.translateModuleCtx :
	aliasSource,
	funSource,
	jsNameForDecl,
	makeDecl,
	ModuleExportMangledNames,
	structSource,
	translateFunReference,
	TranslateProgramCtx,
	TranslateModuleCtx,
	translateStructReference;
import backend.js.writeJsAst : writeJsModuleAst, writeJsScriptAst;
import frontend.showModel : ShowTypeCtx;
import frontend.storage : FileContentGetters, LineAndCharacterGetters;
import model.ast : ImportOrExportAstKind, PathOrRelPath;
import model.model :
	allExterns,
	BuildTarget,
	BuiltinType,
	Called,
	eachImportOrReExport,
	EnumOrFlagsMember,
	FunDecl,
	FunDeclSource,
	getAllFlagsValue,
	hasFatalDiagnostics,
	ImportOrExport,
	isSigned,
	isTuple,
	MainFun,
	Module,
	nameFromNameReferentsPointer,
	NameReferents,
	Program,
	ProgramWithMain,
	RecordField,
	Signature,
	SpecDecl,
	StructAlias,
	StructBody,
	StructDecl,
	Test,
	UnionMember,
	VarDecl,
	VariantAndMethodImpls,
	Visibility;
import util.alloc.alloc : Alloc;
import util.col.array :
	emptySmallArray, isEmpty, map, mapOp, newArray, newSmallArray, SmallArray, zipPointers;
import util.col.arrayBuilder : add, addAll, ArrayBuilder, buildArray, Builder, finish;
import util.col.hashTable : mustGet, withSortedKeys;
import util.col.map : Map, mustGet;
import util.col.mutArr : MutArr, push;
import util.col.mutMap : addOrChange, deleteWhere, getOrAdd, moveToMap, mustAdd, mustDelete, mustGet, MutMap;
import util.col.set : Set;
import util.col.sortUtil : sortInPlace;
import util.col.tempSet : mustAdd, TempSet, tryAdd, withTempSet;
import util.conv : safeToUshort;
import util.memory : allocate;
import util.opt : force, has, MutOpt, none, Opt, optIf, optFromMut, some, someMut;
import util.symbol : compareSymbolsAlphabetically, Symbol, symbol;
import util.symbolSet : SymbolSet;
import util.union_ : Union;
import util.uri :
	countComponents,
	FilePermissions,
	firstNComponents,
	isAncestor,
	parent,
	parsePath,
	Path,
	PathAndContent,
	pathFromAncestor,
	prefixPathComponent,
	RelPath,
	relativePath,
	resolvePath,
	Uri;
import util.util : castNonScope_ref, min, ptrTrustMe, typeAs;
import versionInfo : JsTarget, VersionInfo, versionInfoForBuildToJS;

JsAndMap translateToJsScript(
	ref Alloc alloc,
	ref ProgramWithMain program,
	in ShowTypeCtx showCtx,
	in LineAndCharacterGetters lineAndCharacterGetters,
	in FileContentGetters fileContentGetters,
	JsTarget jsTarget,
	Opt!Symbol sourceMapName,
) =>
	withTranslateProgram(alloc, program, showCtx, lineAndCharacterGetters, fileContentGetters, jsTarget, true, (ref TranslateProgramCtx ctx) =>
		writeJsScriptAst(alloc, showCtx, fileContentGetters, modulePaths(alloc, program), translateProgramToScript(ctx), sourceMapName));

immutable struct JsModules {
	Path mainJs;
	PathAndContent[] outputFiles;
}
JsModules translateToJsModules(
	ref Alloc alloc,
	ref ProgramWithMain program,
	in ShowTypeCtx showCtx,
	in LineAndCharacterGetters lineAndCharacterGetters,
	in FileContentGetters fileContentGetters,
	JsTarget jsTarget,
) =>
	withTranslateProgram(alloc, program, showCtx, lineAndCharacterGetters, fileContentGetters, jsTarget, false, (ref TranslateProgramCtx ctx) {
		ModulePaths modulePaths = modulePaths(alloc, program);
		// None for unused modules
		MutMap!(Module*, Opt!JsModuleAst) done;
		doTranslateModule(ctx, modulePaths, done, program.mainModule);
		return JsModules(
			modulePaths.jsPath(program.mainUri),
			getOutputFiles(alloc, showCtx, fileContentGetters, modulePaths, done, jsTarget));
	});

private:

Out withTranslateProgram(Out)(
	ref Alloc alloc,
	ref ProgramWithMain program,
	in ShowTypeCtx showCtx,
	in LineAndCharacterGetters lineAndCharacterGetters,
	in FileContentGetters fileContentGetters,
	JsTarget jsTarget,
	bool isScript,
	in Out delegate(ref TranslateProgramCtx) @safe @nogc pure nothrow cb,
) {
	assert(!hasFatalDiagnostics(program));
	VersionInfo version_ = versionInfoForBuildToJS(jsTarget);
	SymbolSet allExterns = allExterns(program, BuildTarget.js);
	AllUsed allUsed = allUsed(alloc, program, version_, allExterns);
	TranslateProgramCtx ctx = TranslateProgramCtx(
		ptrTrustMe(alloc),
		castNonScope_ref(showCtx),
		castNonScope_ref(lineAndCharacterGetters),
		ptrTrustMe(fileContentGetters),
		ptrTrustMe(program),
		version_,
		jsTarget,
		allExterns,
		allUsed,
		optIf(!isScript, () =>
			moduleExportMangledNames(alloc, program.program, allUsed)));
	return cb(ctx);
}

ModulePaths modulePaths(ref Alloc alloc, in ProgramWithMain program) {
	Module* main = program.mainModule;
	Uri mainCommon = findCommonMainDirectory(main);
	MutMap!(Uri, Path) res;
	void recur(in Module x, Opt!Path fromPath, PathOrRelPath pr) @safe @nogc nothrow {
		if (x.uri !in res) {
			Path path = pr.match!Path(
				(Path x) => x,
				(RelPath x) => force(resolvePath(force(parent(force(fromPath))), x)));
			mustAdd(alloc, res, x.uri, path);
			eachImportOrReExport(x, (ref ImportOrExport im) @safe nothrow {
				recur(
					im.module_,
					some(path),
					has(im.source) ? force(im.source).path : PathOrRelPath(parsePath("crow/std")));
			});
		}
	}
	recur(*main, none!Path, PathOrRelPath(prefixPathComponent(symbol!"main", pathFromAncestor(mainCommon, main.uri))));
	return ModulePaths(moveToMap(alloc, res));
}
Uri findCommonMainDirectory(Module* main) =>
	withTempSet!(Uri, Module*)(0x100, (scope ref TempSet!(Module*) globalImports) @safe {
		fillGlobalImportModules(globalImports, main);

		// First: Find the common URI for all modules accessible from 'main' through relative imports.
		size_t minComponents = countComponents(main.uri);
		eachRelativeImportModule(main, (Module* x) {
			if (!globalImports.has(x))
				minComponents = min(minComponents, countComponents(x.uri));
		});

		assert(minComponents > 0);
		Uri res = firstNComponents(main.uri, minComponents - 1);
		eachRelativeImportModule(main, (Module* x) {
			if (!globalImports.has(x))
				assert(isAncestor(res, x.uri));
		});
		return res;
	});

void fillGlobalImportModules(scope ref TempSet!(Module*) res, Module* main) {
	withTempSet!(void, Module*)(0x100, (scope ref TempSet!(Module*) seen) {
		void recur(Module* a, bool inGlobal) @safe @nogc nothrow {
			if (tryAdd(seen, a)) {
				if (inGlobal)
					mustAdd(res, a);
				eachImportOrReExport(*a, (ref ImportOrExport x) @safe nothrow {
					recur(x.modulePtr, inGlobal || !x.isRelativeImport);
				});
			}
		}
		recur(main, false);
	});
}

void eachRelativeImportModule(Module* main, in void delegate(Module*) @safe @nogc pure nothrow cb) {
	withTempSet!(void, Module*)(0x100, (scope ref TempSet!(Module*) seen) {
		void recur(Module* x) @safe @nogc nothrow {
			if (tryAdd(seen, x)) {
				cb(x);
				eachImportOrReExport(*x, (ref ImportOrExport im) @safe nothrow {
					if (im.isRelativeImport) {
						recur(im.modulePtr);
					}
				});
			}
		}
		recur(main);
	});
}

PathAndContent[] getOutputFiles(
	ref Alloc alloc,
	in ShowTypeCtx showCtx,
	in FileContentGetters fileContentGetters,
	in ModulePaths modulePaths,
	in MutMap!(Module*, Opt!JsModuleAst) done,
	JsTarget target,
) =>
	buildArray!PathAndContent(alloc, (scope ref Builder!PathAndContent out_) {
		if (target == JsTarget.node)
			out_ ~= PathAndContent(parsePath("package.json"), FilePermissions.regular, "{\"type\":\"module\"}");
		foreach (const Module* module_, ref Opt!JsModuleAst ast; done)
			if (has(ast))
				out_ ~= PathAndContent(
					modulePaths.jsPath(module_.uri),
					force(ast).shebang == Shebang.none ? FilePermissions.regular : FilePermissions.executable,
					writeJsModuleAst(alloc, showCtx, fileContentGetters, modulePaths, module_.uri, force(ast)));
	});

void doTranslateModule(
	ref TranslateProgramCtx ctx,
	in ModulePaths modulePaths,
	scope ref MutMap!(Module*, Opt!JsModuleAst) done,
	Module* a,
) {
	if (a in done) return;
	foreach (ImportOrExport x; a.imports)
		doTranslateModule(ctx, modulePaths, done, x.modulePtr);
	foreach (ImportOrExport x; a.reExports)
		doTranslateModule(ctx, modulePaths, done, x.modulePtr);
	// Test 'isModuleUsed' last, because an unused module can still have used re-exports
	mustAdd(ctx.alloc, done, a, optIf(isModuleUsed(ctx.allUsed, a), () =>
		translateModule(ctx, modulePaths, *a)));
}

JsModuleAst translateModule(ref TranslateProgramCtx ctx, in ModulePaths modulePaths, ref Module a) {
	MutMap!(StructDecl*, StructAlias*) aliases;
	JsImport[] imports = translateImports(ctx, modulePaths, a, aliases);
	JsImport[] reExports = translateReExports(ctx, modulePaths, a);
	TranslateModuleCtx moduleCtx = TranslateModuleCtx(
		ptrTrustMe(ctx),
		modulePrivateMangledNames(ctx.alloc, a, ctx.exportMangledNames, ctx.allUsed),
		moveToMap(ctx.alloc, aliases));
	JsDecl[] decls = buildArray!JsDecl(ctx.alloc, (scope ref Builder!JsDecl out_) {
		eachDeclInModule(a, (AnyDecl x) {
			if (isUsedAnywhere(ctx.allUsed, x)) {
				out_ ~= translateDecl(moduleCtx, x);
			}
		});
	});
	bool isMain = a.uri == ctx.programWithMainPtr.mainFun.fun.decl.moduleUri;
	JsStatement[] statements = isMain
		? callMain(moduleCtx)
		: [];
	return JsModuleAst(
		isMain && !moduleCtx.isBrowser ? Shebang.node : Shebang.none,
		a.uri, imports, reExports, decls, statements);
}

JsScriptAst translateProgramToScript(ref TranslateProgramCtx ctx) {
	TranslateModuleCtx moduleCtx = TranslateModuleCtx(
		ptrTrustMe(ctx),
		bundlePrivateMangledNames(ctx.alloc, ctx.allUsed),
		Map!(StructDecl*, StructAlias*)());
	JsDecl[] decls = buildArray!JsDecl(ctx.alloc, (scope ref Builder!JsDecl out_) {
		// Emit variants first, because their members need to 'extend' them.
		// Also 'tuple2' since it is used in enum/flags 'members'.
		// Emit aliases last.
		foreach (AnyDecl decl; ctx.allUsed.usedDecls)
			if (isVariantOrTuple(ctx, decl))
				out_ ~= translateDecl(moduleCtx, decl);
		foreach (AnyDecl decl; ctx.allUsed.usedDecls)
			if (!isVariantOrTuple(ctx, decl) && !decl.isA!(StructAlias*))
				out_ ~= translateDecl(moduleCtx, decl);
		foreach (AnyDecl decl; ctx.allUsed.usedDecls)
			if (decl.isA!(StructAlias*))
				out_ ~= translateDecl(moduleCtx, decl);
	});
	JsStatement[] statements = callMain(moduleCtx);
	return JsScriptAst(ctx.isBrowser ? Shebang.none : Shebang.node, decls, statements);
}
bool isVariantOrTuple(in TranslateProgramCtx ctx, in AnyDecl a) =>
	a.isA!(StructDecl*) && (
		a.as!(StructDecl*).body_.isA!(StructBody.Variant) ||
		isTuple(ctx.commonTypes, a.as!(StructDecl*)));

JsStatement[] callMain(ref TranslateModuleCtx ctx) {
	FunDecl* main = ctx.ctx.programWithMainPtr.mainFun.fun.decl;
	Source source = funSource(ctx, main);
	JsExpr mainRef = translateFunReference(ctx, source, main);
	return ctx.ctx.programWithMainPtr.mainFun.matchIn!(JsStatement[])(
		(in MainFun.Nat64OfArgs) {
			JsName exitCode = JsName.specialLocal(symbol!"exitCode");
			JsExpr exitCodeNotZero = genNotEqEq(ctx.alloc, source, genLocalGet(source, exitCode), genIntegerUnsigned(source, 0));
			if (ctx.isBrowser) {
				/*
				const exit = await main(newList([]))
				if (exit !== 0n)
					throw new Error("Exited with code " + exit)
				*/
				JsExpr callMain = genCall(ctx.alloc, source, SyncOrAsync.async, mainRef, [genArray(source, [])]);
				return newArray(ctx.alloc, [
					genConst(ctx.alloc, source, exitCode, callMain),
					genIf(
						ctx.alloc,
						source,
						exitCodeNotZero,
						genThrow(ctx.alloc, source, genNew(ctx.alloc, source, genGlobal(source, symbol!"Error"), [
							genPlus(ctx.alloc, source, genString(source, "Exited with code "), genLocalGet(source, exitCode))])))]);
			} else {
				/*
				main(newList(process.argv.slice(2))).then(exitCode => {
					if (exitCode !== 0n)
						process.exit(Number(exitCode))
				})
				*/
				JsExpr process = genGlobal(source, symbol!"process");
				// process.argv.slice(2)
				JsExpr args = genCallPropertySync(
					ctx.alloc,
					source,
					genPropertyAccess(ctx.alloc, source, process, JsMemberName.noPrefix(symbol!"argv")),
					JsMemberName.noPrefix(symbol!"slice"),
					[genNumber(source, 2)]);
				JsExpr callMain = genCall(ctx.alloc, source, SyncOrAsync.sync, mainRef, [args]);
				JsExpr arg = genArrowFunction(ctx.alloc, source, SyncOrAsync.sync, [JsDestructure(exitCode)], [
					genIf(
						ctx.alloc,
						source,
						exitCodeNotZero,
						exprStatement(genCallPropertySync(ctx.alloc, source, process, JsMemberName.noPrefix(symbol!"exit"), [
							genCallSync(ctx.alloc, source, genGlobal(source, symbol!"Number"), [genLocalGet(source, exitCode)])])))]);
				return newArray(ctx.alloc, [
					exprStatement(genCallPropertySync(
						ctx.alloc, source, callMain, JsMemberName.noPrefix(symbol!"then"), [arg]))]);
			}
		},
		(in MainFun.Void) =>
			newArray(ctx.alloc, [exprStatement(genCallSync(ctx.alloc, source, mainRef, []))]));
}

ModuleExportMangledNames moduleExportMangledNames(ref Alloc alloc, in Program program, in AllUsed used) {
	MutMap!(Symbol, ushort) lastIndexForName;
	MutMap!(AnyDecl, ushort) res;

	eachExportOrTestInProgram(program, (AnyDecl decl) {
		if (isUsedAnywhere(used, decl)) {
			ushort index = addOrChange!(Symbol, ushort)(
				alloc,
				lastIndexForName,
				decl.name,
				() => ushort(0),
				(ref ushort x) { x++; });
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

Map!(AnyDecl, ushort) bundlePrivateMangledNames(ref Alloc alloc, in AllUsed allUsed) {
	PrivateMangledNamesBuilder builder;
	foreach (AnyDecl decl; allUsed.usedDecls)
		add(alloc, builder, none!ModuleExportMangledNames, decl);
	return finish(alloc, builder);
}

Map!(AnyDecl, ushort) modulePrivateMangledNames(
	ref Alloc alloc,
	in Module module_,
	in Opt!ModuleExportMangledNames exports,
	in AllUsed used,
) {
	PrivateMangledNamesBuilder builder;
	eachPrivateDeclInModule(module_, (AnyDecl decl) {
		if (isUsedInModule(used, module_.uri, decl)) {
			add(alloc, builder, exports, decl);
		}
	});
	return finish(alloc, builder);
}

struct PrivateMangledNamesBuilder {
	MutMap!(Symbol, ushort) lastIndexForName;
	MutMap!(AnyDecl, ushort) res;
}
void add(
	ref Alloc alloc,
	ref PrivateMangledNamesBuilder builder,
	in Opt!ModuleExportMangledNames exports,
	AnyDecl decl,
) {
	ushort index = addOrChange!(Symbol, ushort)(
		alloc, builder.lastIndexForName, decl.name,
		() {
			Opt!ushort x = has(exports) ? force(exports).lastIndexForName[decl.name] : none!ushort;
			return has(x) ? safeToUshort(force(x) + 1) : typeAs!ushort(0);
		},
		(ref ushort x) { x++; });
	mustAdd(alloc, builder.res, decl, index);
}
Map!(AnyDecl, ushort) finish(ref Alloc alloc, ref PrivateMangledNamesBuilder builder) {
	deleteWhere!(AnyDecl, ushort)(builder.res, (in AnyDecl decl, in ushort value) =>
		mustGet(builder.lastIndexForName, decl.name) == 0);
	return moveToMap(alloc, builder.res);
}

void eachExportOrTestInProgram(ref Program a, in void delegate(AnyDecl) @safe @nogc pure nothrow cb) {
	foreach (ref immutable Module* x; a.allModules)
		eachExportOrTestInModule(*x, cb);
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
	in ModulePaths modulePaths,
	in Module module_,
	scope ref MutMap!(StructDecl*, StructAlias*) aliases,
) {
	eachStructAliasInImports(module_, (StructAlias* alias_, StructDecl* target) {
		if (isUsedInModule(ctx.allUsed, module_.uri, AnyDecl(target)))
			// If multiple aliases, just use the first
			getOrAdd!(StructDecl*, StructAlias*)(ctx.alloc, aliases, target, () => alias_);
	});

	Opt!(Set!AnyDecl) opt = ctx.allUsed.usedByModule[module_.uri];
	if (has(opt)) {
		Path importerPath = modulePaths.jsPath(module_.uri);
		MutMap!(Uri, MutArr!AnyDecl) byModule;
		foreach (AnyDecl x; force(opt))
			if (x.moduleUri != module_.uri)
				push(ctx.alloc, getOrAdd(ctx.alloc, byModule, x.moduleUri, () => MutArr!AnyDecl()), x);
		return buildArray!JsImport(ctx.alloc, (scope ref Builder!JsImport outImports) {
			foreach (Uri importedUri, ref MutArr!AnyDecl decls; byModule) {
				JsName[] names = buildArray!JsName(ctx.alloc, (scope ref Builder!JsName out_) {
					foreach (ref const AnyDecl decl; decls)
						out_ ~= jsNameForDecl(decl, force(ctx.exportMangledNames).mangledNames[decl]);
				});
				sortInPlace!(JsName, compareJsName)(names);
				outImports ~= JsImport(some(names), relativePath(importerPath, modulePaths.jsPath(importedUri)));
			}
		});
	} else
		return [];
}

JsImport[] translateReExports(ref TranslateProgramCtx ctx, in ModulePaths modulePaths, in Module module_) {
	Path importerPath = modulePaths.jsPath(module_.uri);
	return mapOp!(JsImport, ImportOrExport)(ctx.alloc, module_.reExports, (ref ImportOrExport x) {
		RelPath relPath() => relativePath(importerPath, modulePaths.jsPath(x.module_.uri));
		if (isImportModuleWhole(x))
			return optIf(isModuleUsed(ctx.allUsed, x.modulePtr), () =>
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
									out_ ~= jsNameForDecl(decl, force(ctx.exportMangledNames).mangledNames[decl]);
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
			assert(false),
		(StructAlias* x) =>
			translateStructAlias(ctx, x),
		(StructDecl* x) =>
			translateStructDecl(ctx, x),
		(Test* x) =>
			translateTest(ctx, x),
		(VarDecl* x) =>
			translateVarDecl(ctx, x));

JsDecl translateStructAlias(ref TranslateModuleCtx ctx, StructAlias* a) =>
	makeDecl(ctx, AnyDecl(a), JsDeclKind(translateStructReference(ctx, aliasSource(ctx, a), a.target.decl)));

JsDecl translateStructDecl(ref TranslateModuleCtx ctx, StructDecl* a) {
	Source source = structSource(ctx, a);
	// Normally we don't bother to inherit from variants
	// (which is not always doable since there may be more than one variant).
	// However, it's important to inherit from Error so it can set the stack trace.
	MutOpt!(JsExpr*) extends;
	JsClassMember[] members = buildArray!JsClassMember(ctx.alloc, (scope ref Builder!JsClassMember out_) {
		foreach (ref VariantAndMethodImpls v; a.variants) {
			if (v.variant == ctx.commonTypes.exception)
				extends = someMut(allocate(ctx.alloc, translateStructReference(ctx, source, v.variant.decl)));
		}
		Opt!Super super_ = optIf(has(extends), () => Super(emptySmallArray!JsExpr, callFinishConstructor: true));

		a.body_.match!void(
			(StructBody.Bogus) =>
				assert(false),
			(BuiltinType x) =>
				assert(false),
			(ref StructBody.Enum x) {
				translateEnumDecl(ctx, source, out_, super_, x);
			},
			(StructBody.Extern) {},
			(StructBody.Flags x) =>
				translateFlagsDecl(ctx, source, out_, a, super_, x),
			(StructBody.Record x) {
				translateRecordDecl(ctx, source, out_, super_, x);
			},
			(ref StructBody.Union x) {
				translateUnionDecl(ctx, source, out_, super_, x);
			},
			(StructBody.Variant) {
				if (a == ctx.commonTypes.exception.decl) {
					extends = someMut(allocate(ctx.alloc, genGlobal(source, symbol!"Error")));
					translateExceptionClass(ctx, source, out_);
				}
			});

		foreach (ref VariantAndMethodImpls v; a.variants)
			zipPointers(v.variantDeclMethods, v.methodImpls, (Signature* sig, Opt!Called* impl) {
				out_ ~= variantMethodImpl(ctx, FunDeclSource.VariantMethod(v.variant.decl, sig), *impl);
			});
	});
	return makeDecl(ctx, AnyDecl(a), JsDeclKind(JsClassDecl(optFromMut!(JsExpr*)(extends), members)));
}

void translateExceptionClass(ref TranslateModuleCtx ctx, in Source source, scope ref Builder!JsClassMember out_) {
	// constructor() { super("<<message>>") }
	JsMemberName messageName = JsMemberName.noPrefix(symbol!"message");
	JsExpr messagePlaceholder = genString(source, "<<message>>");
	out_ ~= genConstructor(ctx.alloc, source, [], some(Super(newSmallArray!JsExpr(ctx.alloc, [messagePlaceholder]))), []);

	/*:
	"finish-constructor"() {
		this.message = this.v_show()
		this.stack = this.stack.replace("<<message>>", this.message)
	}
	*/
	JsExpr this_ = genThis(source);
	JsExpr callDescribe = genCallPropertySync(ctx.alloc, source, this_, JsMemberName.variantMethod(symbol!"show"), []);
	JsExpr this_message = genPropertyAccess(ctx.alloc, source, this_, messageName);
	JsExpr this_stack = genPropertyAccess(ctx.alloc, source, this_, JsMemberName.noPrefix(symbol!"stack"));
	out_ ~= genInstanceMethod(
		ctx.alloc,
		SyncOrAsync.sync,
		finishConstructorName,
		[],
		[
			genAssign(ctx.alloc, source, this_message, callDescribe),
			genAssign(
				ctx.alloc, source, this_stack,
				genCallPropertySync(
					ctx.alloc,
					source,
					this_stack,
					JsMemberName.noPrefix(symbol!"replace"),
					[messagePlaceholder, this_message])),
		]);
}

JsMemberName finishConstructorName = JsMemberName.special(symbol!"finish-constructor");

void translateEnumDecl(
	ref TranslateModuleCtx ctx,
	in Source source,
	scope ref Builder!JsClassMember out_,
	Opt!Super super_,
	in StructBody.Enum a,
) {
	/*
	class E {
		constructor(value) {
			this.value = value
		}
		static x = new this(0n)
		static _members = [new_pair("x", this.x)]
	}
	*/
	JsName value = JsName.specialLocal(symbol!"value");
	out_ ~= genConstructor(ctx.alloc, source, [JsDestructure(value)], super_, [
		genAssignToThis(ctx.alloc, source, JsMemberName.special(symbol!"value"), genLocalGet(source, value))]);
	foreach (ref EnumOrFlagsMember member; a.members)
		out_ ~= genField(
			JsClassMember.Static.static_,
			JsMemberName.enumMember(member.name),
			genNew(ctx.alloc, source, genThis(source), [genInteger(source, isSigned(a.storage), member.value)]));
	out_ ~= enumOrFlagsMembers(ctx, source, a.members);
}
JsStatement genAssignToThis(ref Alloc alloc, Source source, JsMemberName name, JsExpr value) =>
	genAssign(alloc, source, genPropertyAccess(alloc, source, genThis(source), name), value);
JsClassMember enumOrFlagsMembers(ref TranslateModuleCtx ctx, in Source source, in EnumOrFlagsMember[] members) =>
	genField(
		JsClassMember.Static.static_,
		JsMemberName.special(symbol!"members"),
		genArray(source, map(ctx.alloc, members, (ref EnumOrFlagsMember member) =>
			genNewPair(
				ctx,
				source,
				genStringFromSymbol(source, member.name),
				genPropertyAccess(ctx.alloc, source, genThis(source), JsMemberName.enumMember(member.name))))));

void translateFlagsDecl(
	ref TranslateModuleCtx ctx,
	in Source source,
	scope ref Builder!JsClassMember out_,
	in StructDecl* struct_,
	Opt!Super super_,
	in StructBody.Flags a,
) {
	/*
	class F {
		constructor(value) {
			this._value = value
		}
		static x = new this(1n)
		static y = new this(2n)
		static _none = new this(0n)
		static _members = [new_pair("x", this.x), new_pair("y", this.y)]

		_intersect(b) {
			return new F(this._value & b._value)
		}
		_union(b) {
			return new F(this._value | b._value)
		}
		_negate() {
			return new F(~this._value & 3n)
		}
	}
	*/
	JsName value = JsName.specialLocal(symbol!"value");
	out_ ~= genConstructor(ctx.alloc, source, [JsDestructure(value)], super_, [
		genAssignToThis(ctx.alloc, source, JsMemberName.special(symbol!"value"), genLocalGet(source, value))]);
	foreach (ref EnumOrFlagsMember member; a.members) {
		out_ ~= genField(
			JsClassMember.Static.static_,
			JsMemberName.enumMember(member.name),
			genNew(ctx.alloc, source, genThis(source), [genIntegerUnsigned(source, member.value.asUnsigned())]));
	}
	out_ ~= genField(
		JsClassMember.Static.static_,
		JsMemberName.special(symbol!"none"),
		genNew(ctx.alloc, source, genThis(source), [genIntegerUnsigned(source, 0)]));
	out_ ~= enumOrFlagsMembers(ctx, source, a.members);
	out_ ~= intersectOrUnionMethod(
		ctx, source, struct_, JsMemberName.special(symbol!"intersect"), JsBinaryExpr.Kind.bitwiseAnd);
	out_ ~= intersectOrUnionMethod(
		ctx, source, struct_, JsMemberName.special(symbol!"union"), JsBinaryExpr.Kind.bitwiseOr);
	out_ ~= negateMethod(ctx, source, struct_, getAllFlagsValue(a));
}
JsClassMember intersectOrUnionMethod(
	ref TranslateModuleCtx ctx,
	in Source source,
	in StructDecl* struct_,
	JsMemberName name,
	JsBinaryExpr.Kind kind,
) {
	JsName b = JsName.specialLocal(symbol!"b");
	return genInstanceMethod(
		ctx.alloc,
		structSource(ctx, struct_),
		SyncOrAsync.sync,
		name,
		[JsDestructure(b)],
		genNew(ctx.alloc, source, translateStructReference(ctx, source, struct_), [
			genBinary(
				ctx.alloc, source, kind,
				getValue(ctx.alloc, genThis(source)),
				getValue(ctx.alloc, genLocalGet(source, b)))]));
}
JsClassMember negateMethod(ref TranslateModuleCtx ctx, in Source source, in StructDecl* struct_, ulong allFlagsValue) =>
	genInstanceMethod(
		ctx.alloc,
		source,
		SyncOrAsync.sync,
		JsMemberName.special(symbol!"negate"),
		[],
		genNew(ctx.alloc, source, translateStructReference(ctx, source, struct_), [
			genBitwiseAnd(
				ctx.alloc,
				source,
				genBitwiseNot(ctx.alloc, source, getValue(ctx.alloc, genThis(source))),
				genIntegerUnsigned(source, allFlagsValue))]));
JsExpr getValue(ref Alloc alloc, JsExpr arg) =>
	genPropertyAccess(alloc, arg.source, arg, JsMemberName.special(symbol!"value"));

void translateRecordDecl(
	ref TranslateModuleCtx ctx,
	in Source source,
	scope ref Builder!JsClassMember out_,
	Opt!Super super_,
	in StructBody.Record a,
) {
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
		source,
		map!(JsDestructure, RecordField)(ctx.alloc, a.fields, (ref RecordField x) =>
			JsDestructure(JsName.local(x.name))),
		super_,
		(scope ref ArrayBuilder!JsStatement out_) {
			foreach (ref RecordField x; a.fields) {
				JsExpr value = genLocalGet(source, JsName.local(x.name));
				genAssertType(out_, ctx, source, x.type, value);
				add(ctx.alloc, out_, genAssignToThis(ctx.alloc, source, JsMemberName.recordField(x.name), value));
			}
		});
}

void translateUnionDecl(
	ref TranslateModuleCtx ctx,
	in Source source,
	scope ref Builder!JsClassMember out_,
	Opt!Super super_,
	in StructBody.Union a,
) {
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
	JsName arg = JsName.specialLocal(symbol!"arg");
	out_ ~= genConstructor(ctx.alloc, source, [JsDestructure(arg)], super_, [
		exprStatement(genCallPropertySync(
			ctx.alloc,
			source,
			genGlobal(source, symbol!"Object"),
			JsMemberName.noPrefix(symbol!"assign"),
			[genThis(source), genLocalGet(source, arg)]))]);

	foreach (ref UnionMember member; a.members) {
		out_ ~= () {
			if (member.hasValue) {
				JsName value = JsName.specialLocal(symbol!"value");
				JsParams params = JsParams(newSmallArray!JsDestructure(ctx.alloc, [JsDestructure(value)]));
				ArrayBuilder!JsStatement out_;
				genAssertType(out_, ctx, source, member.type, genLocalGet(source, value));
				add(ctx.alloc, out_, genReturn(
					ctx.alloc,
					source,
					genNew(ctx.alloc, source, genThis(source), [
						genObject(ctx.alloc, source, JsMemberName.unionMember(member.name), genLocalGet(source, value))])));
				return genStaticMethod(
					SyncOrAsync.sync,
					JsMemberName.unionConstructor(member.name),
					params,
					genBlockStatement(ctx.alloc, finish(ctx.alloc, out_)));
			} else
				return genField(
					JsClassMember.Static.static_,
					JsMemberName.unionConstructor(member.name),
					genNew(ctx.alloc, source, genThis(source), [
						genObject(ctx.alloc, source, JsMemberName.unionMember(member.name), genNull(source))]));
		}();
	}
}

JsClassMember genConstructor(
	ref Alloc alloc,
	in Source source,
	in JsDestructure[] params,
	Opt!Super super_,
	in JsStatement[] statements,
) =>
	genConstructor(alloc, source, newSmallArray(alloc, params), super_, (scope ref ArrayBuilder!JsStatement out_) {
		addAll(alloc, out_, statements);
	});
JsClassMember genConstructor(
	ref Alloc alloc,
	in Source source,
	SmallArray!JsDestructure params,
	Opt!Super super_,
	in void delegate(scope ref ArrayBuilder!JsStatement) @safe @nogc pure nothrow cb,
) {
	ArrayBuilder!JsStatement out_;
	if (has(super_))
		add(alloc, out_, genSuper(source, force(super_).args));
	cb(out_);
	if (has(super_) && force(super_).callFinishConstructor)
		add(alloc, out_, exprStatement(genCallPropertySync(alloc, source, genThis(source), finishConstructorName, [])));
	return genInstanceMethod(
		SyncOrAsync.sync,
		JsMemberName.noPrefix(symbol!"constructor"),
		JsParams(params),
		JsBlockStatement(finish(alloc, out_)));
}

immutable struct Super {
	SmallArray!JsExpr args;
	bool callFinishConstructor;
}

JsExpr super_ = genGlobal(noSource, symbol!"super");
JsStatement genSuper(in Source source, SmallArray!JsExpr args) =>
	exprStatement(genCallSync(source, &super_, args));

JsDecl translateVarDecl(ref TranslateModuleCtx ctx, VarDecl* a) =>
	makeDecl(ctx, AnyDecl(a), JsDeclKind(JsDeclKind.Let()));
