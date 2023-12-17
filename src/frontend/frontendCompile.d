module frontend.frontendCompile;

@safe @nogc pure nothrow:

import frontend.check.check : BootstrapCheck, check, checkBootstrap, FileAndAst, ResolvedImport;
import frontend.check.getCommonFuns : CommonFunsAndMain, CommonModule, getCommonFuns;
import frontend.check.instantiate : InstantiateCtx;
import frontend.lang : crowConfigBaseName, crowExtension;
import frontend.allInsts : AllInsts, freeInstantiationsForModule, perfStats;
import frontend.storage :
	FileContent,
	FilesState,
	filesState,
	FileType,
	fileType,
	getFileContentOrDiag,
	getParsedOrDiag,
	markUnknownIfNotExist,
	ParseResult,
	ReadFileResult,
	Storage;
import model.ast : FileAst, fileAstForReadFileDiag, ImportOrExportAst, ImportOrExportAstKind, NameAndRange;
import model.diag : Diag, ReadFileDiag;
import model.model :
	CommonTypes, Config, emptyConfig, getConfigUri, getModuleUri, MainFun, Module, Program, ProgramWithMain;
import util.alloc.alloc :
	Alloc, AllocAndValue, allocateUninitialized, AllocKind, freeAllocAndValue, MetaAlloc, newAlloc, withAlloc;
import util.col.arrayBuilder : add, ArrayBuilder, asTemporaryArray, finish;
import util.col.array : contains, exists, every, findIndex, map;
import util.col.exactSizeArrayBuilder : buildArrayExact, ExactSizeArrayBuilder;
import util.col.hashTable : getOrAdd, HashTable, mapPreservingKeys, moveToImmutable, mustGet, MutHashTable;
import util.col.map : Map;
import util.col.mapBuilder : finishMap, MapBuilder, mustAddToMap;
import util.col.enumMap : EnumMap, enumMapMapValues, makeEnumMap;
import util.col.mutMaxSet : clear, mayDelete, mustAdd, MutMaxSet, popArbitrary;
import util.col.mutSet : mayAddToMutSet, MutSet, mutSetMayDelete, mutSetMustDelete;
import util.json : field, Json, jsonObject;
import util.memory : allocate, initMemory;
import util.opt : ConstOpt, force, has, MutOpt, Opt, none, noneMut, some, someMut;
import util.perf : Perf, PerfMeasure, withMeasure;
import util.symbol : AllSymbols, symbol;
import util.union_ : Union, UnionMutable;
import util.uri :
	addExtension,
	AllUris,
	childUri,
	concatUriAndPath,
	firstAndRest,
	parent,
	parentOrEmpty,
	Path,
	Uri,
	Uri,
	PathFirstAndRest,
	RelPath,
	resolveUri;
import util.util : ptrTrustMe, todo;

struct FrontendCompiler {
	@safe @nogc pure nothrow:
	private:
	MetaAlloc* metaAlloc;
	Alloc* allocPtr;
	AllSymbols* allSymbolsPtr;
	AllUris* allUrisPtr;
	Storage* storagePtr;
	Uri crowIncludeDir;
	EnumMap!(CommonModule, CrowFile*) commonFiles;
	AllInsts allInsts;
	// Set after 'bootstrap' is compiled
	MutOpt!(CommonTypes*) commonTypes;
	MutHashTable!(CrowFile*, Uri, getCrowFileUri) crowFiles;
	size_t countUncompiledCrowFiles; // Number of crowFiles without 'module_'
	MutHashTable!(OtherFile*, Uri, getOtherFileUri) otherFiles;
	// Set of files which are ready to compile immediately.
	// (Parsing and resolving imports is always done immediately.)
	// This doesn't include files whose imports are not yet compiled.
	// If all Uris are resolved but nothing is workable, there must be a circular import.
	MutMaxSet!(0x100, CrowFile*) workable;

	ref inout(Alloc) alloc() return scope inout =>
		*allocPtr;
	ref AllSymbols allSymbols() return scope =>
		*allSymbolsPtr;
	ref inout(AllUris) allUris() return scope inout =>
		*allUrisPtr;
	ref Storage storage() return scope =>
		*storagePtr;
}

FrontendCompiler* initFrontend(
	MetaAlloc* metaAlloc,
	AllSymbols* allSymbols,
	AllUris* allUris,
	Storage* storage,
	Uri crowIncludeDir,
) {
	return () @trusted {
		Alloc* alloc = newAlloc(AllocKind.frontend, metaAlloc);
		FrontendCompiler* res = allocateUninitialized!FrontendCompiler(*alloc);
		initMemory(res, FrontendCompiler(
			metaAlloc, alloc, allSymbols, allUris, storage, crowIncludeDir,
			makeEnumMap!(CommonModule, CrowFile*)((CommonModule _) => null),
			AllInsts(newAlloc(AllocKind.allInsts, metaAlloc))));
		res.commonFiles = enumMapMapValues!(CommonModule, CrowFile*, Uri)(
			commonUris(*allUris, crowIncludeDir), (in Uri uri) =>
				ensureCrowFile(*res, uri));
		return res;
	}();
}

Json perfStats(ref Alloc alloc, in FrontendCompiler a) =>
	jsonObject(alloc, [
		field!"allInsts"(perfStats(alloc, a.allInsts))]);

private struct CrowFile {
	@safe @nogc pure nothrow:

	immutable Uri uri;
	// This needs to be filled in in 3 steps: ast/config, resolvedImports/referencedBy, module

	MutOpt!(Config*) config; // This will be some(defaultConfig) if there is no config file on the path
	MutOpt!(FileAst*) ast;

	MutOpt!(MostlyResolvedImport[]) resolvedImports; // Also includes re-exports. Set once we have config.
	MutSet!(CrowFile*) referencedBy;

	// This will be compiled only after all imports are compiled
	MutOpt!(AllocAndValue!(Module*)) moduleAndAlloc;

	bool hasModule() scope const =>
		has(moduleAndAlloc);

	Module* mustHaveModule() return scope const =>
		force(moduleAndAlloc).value;
}
private Uri getCrowFileUri(in CrowFile* a) =>
	a.uri;

private struct OtherFile {
	immutable Uri uri;
	bool loaded;
	MutSet!(CrowFile*) referencedBy;
}
private Uri getOtherFileUri(in OtherFile* a) =>
	a.uri;

ProgramWithMain makeProgramForMain(scope ref Perf perf, ref Alloc alloc, ref FrontendCompiler a, Uri mainUri) {
	CrowFile* mainFile = mustGet(a.crowFiles, mainUri);
	Common res = makeProgramCommon(perf, alloc, a, [mainUri], some(mainFile.mustHaveModule));
	return ProgramWithMain(force(mainFile.config), force(res.mainFun), res.program);
}

Program makeProgramForRoots(scope ref Perf perf, ref Alloc alloc, ref FrontendCompiler a, in Uri[] roots) =>
	makeProgramCommon(perf, alloc, a, roots, none!(Module*)).program;

private struct Common {
	Program program;
	Opt!MainFun mainFun;
}
private Common makeProgramCommon(
	scope ref Perf perf,
	ref Alloc alloc,
	ref FrontendCompiler a,
	in Uri[] roots,
	Opt!(Module*) mainModule,
) {
	assert(filesState(a.storage) == FilesState.allLoaded);
	EnumMap!(CommonModule, Module*) commonModules = enumMapMapValues!(CommonModule, Module*, CrowFile*)(
		a.commonFiles, (in CrowFile* x) => x.mustHaveModule);
	InstantiateCtx ctx = InstantiateCtx(ptrTrustMe(perf), ptrTrustMe(a.allInsts));
	CommonFunsAndMain commonFuns = getCommonFuns(a.alloc, ctx, *force(a.commonTypes), commonModules, mainModule);
	Program program = Program(
		getAllConfigs(alloc, a),
		mapPreservingKeys!(immutable Module*, getModuleUri, CrowFile*, Uri, getCrowFileUri)(
			alloc, a.crowFiles, (ref const CrowFile* file) => file.mustHaveModule),
		map!(immutable Module*, Uri)(alloc, roots, (ref Uri uri) => mustGet(a.crowFiles, uri).mustHaveModule),
		commonFuns.commonFuns,
		*force(a.commonTypes));
	return Common(program, commonFuns.mainFun);
}

Map!(Uri, ReadFileResult) getFileContents(ref Alloc alloc, scope ref FrontendCompiler a) {
	MapBuilder!(Uri, ReadFileResult) res;
	foreach (OtherFile* x; a.otherFiles)
		mustAddToMap(alloc, res, x.uri, getFileContentOrDiag(a.storage, x.uri));
	return finishMap(alloc, res);
}

void onFileChanged(scope ref Perf perf, ref FrontendCompiler a, Uri uri) {
	withMeasure!(void, () {
		final switch (fileType(a.allUris, uri)) {
			case FileType.crow:
				FileAst* ast = getParsedOrDiag(a.storage, uri).match!(FileAst*)(
					(ParseResult x) =>
						x.as!(FileAst*),
					(ReadFileDiag x) =>
						// TODO: Storage should just store this
						fileAstForReadFileDiag(a.alloc, x));
				CrowFile* file = ensureCrowFile(a, uri);
				file.ast = someMut(ast); // TODO: free old ast
				updatedAstOrConfig(a, file);
				break;
			case FileType.crowConfig:
				foreach (CrowFile* file; a.crowFiles)
					updateFileOnConfigChange(a, file);
				break;
			case FileType.other:
				// TODO: if the file existed before and exists now, no need to re-compile.
				OtherFile* file = ensureOtherFile(a, uri);
				file.loaded = true;
				foreach (CrowFile* x; file.referencedBy)
					addToWorkableIfSo(a, x);
				break;
		}
		doDirtyWork(perf, a);
	})(perf, a.alloc, PerfMeasure.onFileChanged);
}

private:


HashTable!(immutable Config*, Uri, getConfigUri) getAllConfigs(ref Alloc alloc, in FrontendCompiler a) {
	MutHashTable!(immutable Config*, Uri, getConfigUri) res;
	foreach (const CrowFile* file; a.crowFiles) {
		Config* config = force(file.config);
		if (has(config.configUri))
			getOrAdd!(immutable Config*, Uri, getConfigUri)(alloc, res, force(config.configUri), () => config);
	}
	return moveToImmutable(res);
}

CrowFile* ensureCrowFile(ref FrontendCompiler a, Uri uri) {
	assert(fileType(a.allUris, uri) == FileType.crow);
	return getOrAdd!(CrowFile*, Uri, getCrowFileUri)(a.alloc, a.crowFiles, uri, () {
		markUnknownIfNotExist(a.storage, uri);
		a.countUncompiledCrowFiles++;
		return allocate(a.alloc, CrowFile(uri, tryFindConfig(a.storage, a.allUris, parentOrEmpty(a.allUris, uri))));
	});
}

OtherFile* ensureOtherFile(ref FrontendCompiler a, Uri uri) =>
	getOrAdd!(OtherFile*, Uri, getOtherFileUri)(a.alloc, a.otherFiles, uri, () {
		markUnknownIfNotExist(a.storage, uri);
		return allocate(a.alloc, OtherFile(uri));
	});

void doDirtyWork(scope ref Perf perf, ref FrontendCompiler a) {
	CrowFile* bootstrap = a.commonFiles[CommonModule.bootstrap];
	if (mayDelete(a.workable, bootstrap)) {
		FileAndAst fa = FileAndAst(bootstrap.uri, force(bootstrap.ast));
		bootstrap.moduleAndAlloc = someMut(withAlloc!(Module*)(AllocKind.module_, a.metaAlloc, (ref Alloc alloc) {
			BootstrapCheck bs = checkBootstrap(perf, alloc, a.allSymbols, a.allUris, a.allInsts, fa);
			a.commonTypes = someMut(bs.commonTypes);
			return bs.module_;
		}));
		assert(a.countUncompiledCrowFiles > 0);
		a.countUncompiledCrowFiles--;
		markAllNonBootstrapModulesDirty(a, bootstrap); // Since they all use commonTypes
	}

	if (has(a.commonTypes)) {
		while (true) {
			MutOpt!(CrowFile*) opt = popArbitrary(a.workable);
			if (has(opt)) {
				CrowFile* file = force(opt);
				file.moduleAndAlloc = someMut(withAlloc(AllocKind.module_, a.metaAlloc, (ref Alloc alloc) =>
					compileNonBootstrapModule(perf, alloc, a, file)));
				assert(a.countUncompiledCrowFiles > 0);
				a.countUncompiledCrowFiles--;
				foreach (CrowFile* importer; file.referencedBy)
					addToWorkableIfSo(a, importer);
			} else if (filesState(a.storage) == FilesState.allLoaded && a.countUncompiledCrowFiles != 0)
				fixCircularImports(a);
			else
				break;
		}
	}
}

// This may not fix all circular imports, but it's run in a loop
void fixCircularImports(ref FrontendCompiler a) {
	foreach (CrowFile* x; a.crowFiles)
		if (!x.hasModule) {
			ArrayBuilder!Uri cycleBuilder;
			fixCircularImportsRecur(a, cycleBuilder, x);
			return;
		}
}
Uri[] fixCircularImportsRecur(ref FrontendCompiler a, scope ref ArrayBuilder!Uri cycleBuilder, CrowFile* file) {
	assert(!file.hasModule);
	add(a.alloc, cycleBuilder, file.uri);
	Opt!size_t optImportIndex = findIndex!MostlyResolvedImport(
		force(file.resolvedImports), (in MostlyResolvedImport x) =>
			!isImportWorkable(a.allUris, x));
	size_t importIndex = force(optImportIndex);
	CrowFile* next = force(file.resolvedImports)[importIndex].as!(CrowFile*);
	Uri[] cycle = contains(asTemporaryArray(cycleBuilder), next.uri)
		? finish(a.alloc, cycleBuilder)
		: fixCircularImportsRecur(a, cycleBuilder, next);
	force(file.resolvedImports)[importIndex] = MostlyResolvedImport(
		Diag.ImportFileDiag(Diag.ImportFileDiag.CircularImport(cycle)));
	mutSetMayDelete(next.referencedBy, file);
	addToWorkableIfSo(a, file);
	return cycle;
}

Module* compileNonBootstrapModule(scope ref Perf perf, ref Alloc alloc, ref FrontendCompiler a, CrowFile* file) {
	assert(isWorkable(a.allUris, *file));
	assert(has(a.commonTypes)); // bootstrap is always compiled first
	FileAndAst ast = FileAndAst(file.uri, force(file.ast));
	return check(
		perf, alloc, a.allSymbols, a.allUris, a.allInsts, ast,
		fullyResolveImports(a, force(file.resolvedImports)),
		force(a.commonTypes));
}

void updateFileOnConfigChange(ref FrontendCompiler a, CrowFile* file) {
	MutOpt!(Config*) bestConfig = tryFindConfig(a.storage, a.allUris, parentOrEmpty(a.allUris, file.uri));
	if (has(bestConfig)) {
		if (!has(file.config) || force(bestConfig) != force(file.config)) {
			file.config = bestConfig;
			updatedAstOrConfig(a, file);
		}
	}
}

void updatedAstOrConfig(ref FrontendCompiler a, CrowFile* file) {
	if (has(file.ast) && has(file.config))
		recomputeResolvedImports(a, file);
	else
		assert(!has(file.resolvedImports) && !file.hasModule);
}

void recomputeResolvedImports(ref FrontendCompiler a, CrowFile* file) {
	markModuleDirty(a, *file);

	MutOpt!(Uri[]) circularImport = has(file.resolvedImports) ? clearResolvedImports(file) : noneMut!(Uri[]);

	file.resolvedImports = someMut(resolveImports(a, *force(file.ast), *force(file.config), file.uri));
	foreach (MostlyResolvedImport x; force(file.resolvedImports)) {
		MutOpt!(MutSet!(CrowFile*)*) rb = getReferencedBy(x);
		if (has(rb))
			// Not 'mustAdd' because it could be imported twice by the same module
			mayAddToMutSet(a.alloc, *force(rb), file);
	}

	if (has(circularImport) && !hasCircularImport(force(file.resolvedImports)))
		foreach (Uri uri; force(circularImport))
			if (uri != file.uri) {
				CrowFile* other = mustGet(a.crowFiles, uri);
				MutOpt!(Uri[]) ci = clearResolvedImports(other);
				assert(has(ci)); // But ignore it since we've already handled it
				recomputeResolvedImports(a, other);
			}

	addToWorkableIfSo(a, file);
}

MutOpt!(Uri[]) clearResolvedImports(CrowFile* file) {
	MutOpt!(Uri[]) circularImport = noneMut!(Uri[]);
	foreach (ref MostlyResolvedImport import_; force(file.resolvedImports)) {
		MutOpt!(MutSet!(CrowFile*)*) rb = getReferencedBy(import_);
		if (has(rb))
			mutSetMustDelete(*force(rb), file);
		else
			circularImport = asCircularImport(import_);
	}
	file.resolvedImports = noneMut!(MostlyResolvedImport[]); // TODO: free old resolvedImports
	return circularImport;
}

bool hasCircularImport(in MostlyResolvedImport[] a) =>
	exists!MostlyResolvedImport(a, (in MostlyResolvedImport x) => isCircularImport(x));
bool isCircularImport(in MostlyResolvedImport a) =>
	a.isA!(Diag.ImportFileDiag) && a.as!(Diag.ImportFileDiag).isA!(Diag.ImportFileDiag.CircularImport);
MutOpt!(Uri[]) asCircularImport(MostlyResolvedImport a) =>
	isCircularImport(a)
		? someMut(a.as!(Diag.ImportFileDiag).as!(Diag.ImportFileDiag.CircularImport).cycle)
		: noneMut!(Uri[]);

void addToWorkableIfSo(ref FrontendCompiler a, CrowFile* file) {
	if (isWorkable(a.allUris, *file))
		mustAdd(a.workable, file);
}

// Note: File won't actually be worked on until 'CommonTypes' is set, but it still gets marked here.
bool isWorkable(scope ref AllUris allUris, in CrowFile a) {
	assert(!a.hasModule);
	return has(a.ast) &&
		has(a.config) &&
		every!MostlyResolvedImport(force(a.resolvedImports), (in MostlyResolvedImport x) =>
			isImportWorkable(allUris, x));
}

bool isImportWorkable(scope ref AllUris allUris, in MostlyResolvedImport a) =>
	a.matchConst!bool(
		(const CrowFile* x) =>
			x.hasModule,
		(const OtherFile* x) =>
			x.loaded,
		(Diag.ImportFileDiag x) {
			if (x.isA!(Diag.ImportFileDiag.ReadError)) {
				Diag.ImportFileDiag.ReadError read = x.as!(Diag.ImportFileDiag.ReadError);
				// Unknown/loading files still have a CrowFile* or Config*
				assert(!isUnknownOrLoading(read.diag) || fileType(allUris, read.uri) == FileType.other);
			}
			return true;
		});

bool isUnknownOrLoading(ReadFileDiag a) {
	final switch (a) {
		case ReadFileDiag.unknown:
		case ReadFileDiag.loading:
			return true;
		case ReadFileDiag.notFound:
		case ReadFileDiag.error:
			return false;
	}
}

MostlyResolvedImport[] resolveImports(ref FrontendCompiler a, in FileAst ast, in Config config, Uri uri) =>
	buildArrayExact!MostlyResolvedImport(
		a.alloc,
		countImportsAndReExports(ast),
		(scope ref ExactSizeArrayBuilder!MostlyResolvedImport res) {
			if (!ast.noStd)
				res ~= MostlyResolvedImport(a.commonFiles[CommonModule.std]);
			if (has(ast.imports))
				foreach (ImportOrExportAst x; force(ast.imports).paths)
					res ~= tryResolveImport(a, config, uri, x);
			if (has(ast.reExports))
				foreach (ImportOrExportAst x; force(ast.reExports).paths)
					res ~= tryResolveImport(a, config, uri, x);
		});

size_t countImportsAndReExports(in FileAst a) =>
	(a.noStd ? 0 : 1) +
	(has(a.imports) ? force(a.imports).paths.length : 0) +
	(has(a.reExports) ? force(a.reExports).paths.length : 0);

void markAllNonBootstrapModulesDirty(ref FrontendCompiler a, CrowFile* bootstrap) {
	foreach (CrowFile* x; a.crowFiles)
		if (x != bootstrap)
			markModuleDirty(a, *x);
	clear(a.workable);
	foreach (CrowFile* x; a.crowFiles)
		if (x != bootstrap)
			addToWorkableIfSo(a, x);
}

void markModuleDirty(scope ref FrontendCompiler a, scope ref CrowFile file) {
	if (file.hasModule) {
		freeInstantiationsForModule(a.allInsts, *file.mustHaveModule);
		() @trusted {
			freeAllocAndValue(force(file.moduleAndAlloc));
		}();
		file.moduleAndAlloc = noneMut!(AllocAndValue!(Module*));
		a.countUncompiledCrowFiles++;
		foreach (CrowFile* x; file.referencedBy)
			markModuleDirty(a, *x);
	}
}

ResolvedImport[] fullyResolveImports(ref FrontendCompiler a, MostlyResolvedImport[] imports) =>
	map(a.alloc, imports, (ref MostlyResolvedImport x) =>
		x.match!ResolvedImport(
			(CrowFile* x) =>
				ResolvedImport(x.mustHaveModule),
			(OtherFile* file) =>
				getFileContentOrDiag(a.storage, file.uri).match!ResolvedImport(
					(FileContent content) =>
						ResolvedImport(file.uri),
					(ReadFileDiag x) =>
						ResolvedImport(Diag.ImportFileDiag(Diag.ImportFileDiag.ReadError(file.uri, x)))),
			(Diag.ImportFileDiag x) =>
				ResolvedImport(x)));

MutOpt!(Config*) tryFindConfig(scope ref Storage storage, scope ref AllUris allUris, Uri configDir) {
	Uri configUri = childUri(allUris, configDir, crowConfigBaseName);
	return getParsedOrDiag(storage, configUri).match!(MutOpt!(Config*))(
		(ParseResult x) =>
			someMut(x.as!(Config*)),
		(ReadFileDiag x) {
			final switch (x) {
				case ReadFileDiag.notFound:
					Opt!Uri par = parent(allUris, configDir);
					return has(par) ? tryFindConfig(storage, allUris, force(par)) : someMut(&emptyConfig);
				case ReadFileDiag.error:
					// We want Config* to be unique, so can't alloc here. Storage should do that?
					return todo!(MutOpt!(Config*))("!!!");
				case ReadFileDiag.loading:
				case ReadFileDiag.unknown:
					// Query all possible configs to ensure they are loaded early
					Opt!Uri par = parent(allUris, configDir);
					if (has(par))
						tryFindConfig(storage, allUris, force(par));
					return noneMut!(Config*);
			}
		});
}

immutable(EnumMap!(CommonModule, Uri)) commonUris(ref AllUris allUris, Uri includeDir) {
	Uri includeCrow = childUri(allUris, includeDir, symbol!"crow");
	Uri private_ = childUri(allUris, includeCrow, symbol!"private");
	Uri col = childUri(allUris, includeCrow, symbol!"col");
	return enumMapMapValues!(CommonModule, Uri, Uri)(immutable EnumMap!(CommonModule, Uri)([
		childUri(allUris, private_, symbol!"bootstrap"),
		childUri(allUris, private_, symbol!"alloc"),
		childUri(allUris, private_, symbol!"exception-low-level"),
		childUri(allUris, includeCrow, symbol!"fun-util"),
		childUri(allUris, includeCrow, symbol!"future"),
		childUri(allUris, col, symbol!"list"),
		childUri(allUris, includeCrow, symbol!"std"),
		childUri(allUris, includeCrow, symbol!"string"),
		childUri(allUris, private_, symbol!"runtime"),
		childUri(allUris, private_, symbol!"rt-main"),
	]), (in Uri x) => addExtension!crowExtension(allUris, x));
}

immutable struct UriOrDiag {
	mixin Union!(Uri, Diag.ImportFileDiag);
}

struct MostlyResolvedImport {
	// For unknown/loading file, this will still be a CrowFile* or OtherFile*
	mixin UnionMutable!(CrowFile*, OtherFile*, Diag.ImportFileDiag);
}

MutOpt!(MutSet!(CrowFile*)*) getReferencedBy(ref MostlyResolvedImport import_) =>
	import_.match!(MutOpt!(MutSet!(CrowFile*)*))(
		(CrowFile* x) =>
			someMut(&x.referencedBy),
		(OtherFile* x) =>
			someMut(&x.referencedBy),
		(Diag.ImportFileDiag diag) =>
			noneMut!(MutSet!(CrowFile*)*));
@trusted ConstOpt!(MutSet!(CrowFile*)*) getReferencedBy(ref const MostlyResolvedImport import_) =>
	getReferencedBy(cast(MostlyResolvedImport) import_);

MostlyResolvedImport tryResolveImport(ref FrontendCompiler a, in Config config, Uri fromUri, in ImportOrExportAst ast) {
	UriOrDiag base = ast.path.matchIn!UriOrDiag(
		(in Path path) {
			PathFirstAndRest fr = firstAndRest(a.allUris, path);
			Opt!Uri fromConfig = config.include[fr.first];
			return UriOrDiag(has(fromConfig)
				? (has(fr.rest) ? concatUriAndPath(a.allUris, force(fromConfig), force(fr.rest)) : force(fromConfig))
				: concatUriAndPath(a.allUris, a.crowIncludeDir, path));
		},
		(in RelPath relPath) {
			Opt!Uri rel = resolveUri(a.allUris, parentOrEmpty(a.allUris, fromUri), relPath);
			return has(rel)
				? UriOrDiag(force(rel))
				: UriOrDiag(Diag.ImportFileDiag(Diag.ImportFileDiag.RelativeImportReachesPastRoot(relPath)));
		});
	return base.match!MostlyResolvedImport(
		(Uri uri) {
			MostlyResolvedImport crowFile() =>
				MostlyResolvedImport(ensureCrowFile(a, addExtension!crowExtension(a.allUris, uri)));
			return ast.kind.match!MostlyResolvedImport(
				(ImportOrExportAstKind.ModuleWhole) =>
					crowFile(),
				(NameAndRange[]) =>
					crowFile(),
				(ref ImportOrExportAstKind.File) =>
					MostlyResolvedImport(ensureOtherFile(a, uri)));
		},
		(Diag.ImportFileDiag x) =>
			MostlyResolvedImport(x));
}
