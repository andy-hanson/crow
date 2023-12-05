module frontend.frontendCompile;

@safe @nogc pure nothrow:

import model.diag : Diag, ReadFileDiag;
import model.model : CommonTypes, Config, emptyConfig, Module, Program;
import frontend.check.check : BootstrapCheck, check, checkBootstrap, FileAndAst, ResolvedImport;
import frontend.check.getCommonFuns : CommonModule, getCommonFuns;
import frontend.check.instantiate : InstantiateCtx;
import frontend.lang : crowConfigBaseName, crowExtension;
import frontend.parse.ast : FileAst, fileAstForReadFileDiag, ImportOrExportAst, ImportOrExportAstKind, NameAndRange;
import frontend.programState : ProgramState, summarizeMemory;
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
import util.alloc.alloc : Alloc, allocateUninitialized, AllocKind, MemorySummary, MetaAlloc, newAlloc, summarizeMemory;
import util.col.arrBuilder : add, ArrBuilder, arrBuilderTempAsArr, finishArr;
import util.col.arrUtil : contains, exists, every, findIndex, map;
import util.col.exactSizeArrBuilder : ExactSizeArrBuilder, withExactSizeArrBuilder;
import util.col.map : Map;
import util.col.enumMap : EnumMap, enumMapMapValues, makeEnumMap;
import util.col.mutMap : findInMutMap, getOrAdd, mapToMap, moveToMap, MutMap, mutMapMustGet, values;
import util.col.mutSet :
	mayAddToMutSet,
	mustAddToMutSet,
	MutSet,
	mutSetClearAndKeepMemory,
	mutSetMayDelete,
	mutSetMustDelete,
	mutSetPopArbitrary;
import util.memory : allocate, initMemory;
import util.opt : ConstOpt, force, has, MutOpt, Opt, none, noneMut, some, someMut;
import util.perf : Perf, PerfMeasure, withMeasure;
import util.ptr : ptrTrustMe;
import util.sym : AllSymbols, sym;
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
import util.util : todo;

struct FrontendCompiler {
	@safe @nogc pure nothrow:
	private:
	Alloc* allocPtr;
	AllSymbols* allSymbolsPtr;
	AllUris* allUrisPtr;
	Storage* storagePtr;
	Uri crowIncludeDir;
	EnumMap!(CommonModule, CrowFile*) commonFiles;
	ProgramState programState;
	// Set after 'bootstrap' is compiled
	MutOpt!(CommonTypes*) commonTypes;
	MutMap!(Uri, CrowFile*) crowFiles;
	size_t countUncompiledCrowFiles; // Number of crowFiles without 'module_'
	MutMap!(Uri, OtherFile*) otherFiles;
	// Set of files which are ready to compile immediately.
	// (Parsing and resolving imports is always done immediately.)
	// This doesn't include files whose imports are not yet compiled.
	// If all Uris are resolved but nothing is workable, there must be a circular import.
	MutSet!(CrowFile*) workable;

	ref inout(Alloc) alloc() return scope inout =>
		*allocPtr;
	ref AllSymbols allSymbols() return scope =>
		*allSymbolsPtr;
	ref inout(AllUris) allUris() return scope inout =>
		*allUrisPtr;
	ref Storage storage() return scope =>
		*storagePtr;
}

MemorySummary frontendSummarizeMemory(in FrontendCompiler a) =>
	summarizeMemory(a.alloc) + summarizeMemory(a.programState);

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
			alloc, allSymbols, allUris, storage, crowIncludeDir,
			makeEnumMap!(CommonModule, CrowFile*)((CommonModule _) => null),
			ProgramState(newAlloc(AllocKind.programState, metaAlloc))));
		res.commonFiles = enumMapMapValues!(CommonModule, CrowFile*, Uri)(
			commonUris(*allUris, crowIncludeDir), (in Uri uri) =>
				ensureCrowFile(*res, uri));
		return res;
	}();
}

private struct CrowFile {
	immutable Uri uri;
	// This needs to be filled in in 3 steps: ast/config, resolvedImports/referencedBy, module

	MutOpt!(Config*) config; // This will be some(defaultConfig) if there is no config file on the path
	MutOpt!(FileAst*) ast;

	MutOpt!(MostlyResolvedImport[]) resolvedImports; // Also includes re-exports. Set once we have config.
	MutSet!(CrowFile*) referencedBy;

	// This will be compiled only after all imports are compiled
	MutOpt!(Module*) module_;
}

private struct OtherFile {
	immutable Uri uri;
	bool loaded;
	MutSet!(CrowFile*) referencedBy;
}

Program makeProgramForMain(scope ref Perf perf, ref Alloc alloc, ref FrontendCompiler a, Uri mainUri) =>
	makeProgramCommon(perf, alloc, a, some(mainUri), [mainUri]);

Program makeProgramForRoots(scope ref Perf perf, ref Alloc alloc, ref FrontendCompiler a, in Uri[] roots) =>
	makeProgramCommon(perf, alloc, a, none!Uri, roots);

private Program makeProgramCommon(
	scope ref Perf perf,
	ref Alloc alloc,
	ref FrontendCompiler a,
	in Opt!Uri mainUri,
	in Uri[] roots,
) {
	assert(filesState(a.storage) == FilesState.allLoaded);
	MutOpt!(CrowFile*) mainFile = has(mainUri)
		? someMut(mutMapMustGet(a.crowFiles, force(mainUri)))
		: noneMut!(CrowFile*);
	Opt!(Module*) mainModule = has(mainFile) ? some(force(force(mainFile).module_)) : none!(Module*);
	EnumMap!(CommonModule, Module*) commonModules = enumMapMapValues!(CommonModule, Module*, CrowFile*)(
		a.commonFiles, (in CrowFile* x) =>
			force(x.module_));
	InstantiateCtx ctx = InstantiateCtx(ptrTrustMe(perf), ptrTrustMe(a.programState));
	return Program(
		has(mainFile) ? some(force(force(mainFile).config)) : none!(Config*),
		getAllConfigs(alloc, a),
		mapToMap!(Uri, immutable Module*, CrowFile*)(alloc, a.crowFiles, (ref const CrowFile* file) =>
			force(file.module_)),
		map!(Module*, Uri)(alloc, roots, (ref Uri uri) => force(mutMapMustGet(a.crowFiles, uri).module_)),
		getCommonFuns(a.alloc, ctx, *force(a.commonTypes), mainModule, commonModules),
		*force(a.commonTypes));
}

Map!(Uri, ReadFileResult) getFileContents(ref Alloc alloc, scope ref FrontendCompiler a) =>
	mapToMap!(Uri, ReadFileResult, OtherFile*)(alloc, a.otherFiles, (ref OtherFile* x) =>
		getFileContentOrDiag(a.storage, x.uri));

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
				foreach (CrowFile* file; values(a.crowFiles))
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


Map!(Uri, immutable Config*) getAllConfigs(ref Alloc alloc, in FrontendCompiler a) {
	MutMap!(Uri, immutable Config*) res;
	foreach (const CrowFile* file; values(a.crowFiles)) {
		Config* config = force(file.config);
		if (has(config.configUri))
			getOrAdd!(Uri, immutable Config*)(alloc, res, force(config.configUri), () => config);
	}
	return moveToMap!(Uri, immutable Config*)(alloc, res);
}

CrowFile* ensureCrowFile(ref FrontendCompiler a, Uri uri) {
	assert(fileType(a.allUris, uri) == FileType.crow);
	return getOrAdd!(Uri, CrowFile*)(a.alloc, a.crowFiles, uri, () {
		markUnknownIfNotExist(a.storage, uri);
		a.countUncompiledCrowFiles++;
		return allocate(a.alloc, CrowFile(uri, tryFindConfig(a.storage, a.allUris, parentOrEmpty(a.allUris, uri))));
	});
}

CrowFile* mustGetCrowFile(ref FrontendCompiler a, Uri uri) =>
	mutMapMustGet(a.crowFiles, uri);

OtherFile* ensureOtherFile(ref FrontendCompiler a, Uri uri) {
	return getOrAdd!(Uri, OtherFile*)(a.alloc, a.otherFiles, uri, () {
		markUnknownIfNotExist(a.storage, uri);
		return allocate(a.alloc, OtherFile(uri));
	});
}

void doDirtyWork(scope ref Perf perf, ref FrontendCompiler a) {
	CrowFile* bootstrap = a.commonFiles[CommonModule.bootstrap];
	if (mutSetMayDelete(a.workable, bootstrap)) {
		FileAndAst fa = FileAndAst(bootstrap.uri, force(bootstrap.ast));
		BootstrapCheck bs = checkBootstrap(perf, a.alloc, a.allSymbols, a.allUris, a.programState, fa);
		// TODO: free old commonTypes
		a.commonTypes = someMut(bs.commonTypes);
		bootstrap.module_ = someMut(bs.module_);
		assert(a.countUncompiledCrowFiles > 0);
		a.countUncompiledCrowFiles--;
		markAllNonBootstrapModulesDirty(a, bootstrap); // Since they all use commonTypes
	}

	if (has(a.commonTypes)) {
		while (true) {
			MutOpt!(CrowFile*) opt = mutSetPopArbitrary(a.workable);
			if (has(opt)) {
				CrowFile* file = force(opt);
				file.module_ = someMut(compileNonBootstrapModule(perf, a, file));
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

void fixCircularImports(ref FrontendCompiler a) {
	ArrBuilder!Uri cycleBuilder;
	MutOpt!(CrowFile*) start = findInMutMap!(Uri, CrowFile*)(a.crowFiles, (in Uri _, in CrowFile* x) =>
		!has(x.module_));
	fixCircularImportsRecur(a, cycleBuilder, force(start));
}
Uri[] fixCircularImportsRecur(ref FrontendCompiler a, scope ref ArrBuilder!Uri cycleBuilder, CrowFile* file) {
	assert(!has(file.module_));
	add(a.alloc, cycleBuilder, file.uri);
	Opt!size_t optImportIndex = findIndex!MostlyResolvedImport(
		force(file.resolvedImports), (in MostlyResolvedImport x) =>
			!isImportWorkable(a.allUris, x));
	size_t importIndex = force(optImportIndex);
	CrowFile* next = force(file.resolvedImports)[importIndex].as!(CrowFile*);
	Uri[] cycle = contains(arrBuilderTempAsArr(cycleBuilder), next.uri)
		? finishArr(a.alloc, cycleBuilder)
		: fixCircularImportsRecur(a, cycleBuilder, next);
	force(file.resolvedImports)[importIndex] = MostlyResolvedImport(
		Diag.ImportFileDiag(Diag.ImportFileDiag.CircularImport(cycle)));
	mutSetMayDelete(next.referencedBy, file);
	addToWorkableIfSo(a, file);
	return cycle;
}

Module* compileNonBootstrapModule(scope ref Perf perf, ref FrontendCompiler a, CrowFile* file) {
	assert(isWorkable(a.allUris, *file));
	assert(has(a.commonTypes)); // bootstrap is always compiled first
	FileAndAst ast = FileAndAst(file.uri, force(file.ast));
	return check(
		perf, a.alloc, a.allSymbols, a.allUris, a.programState, ast,
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
		assert(!has(file.resolvedImports) && !has(file.module_));
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
				CrowFile* other = mustGetCrowFile(a, uri);
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
		mustAddToMutSet!(CrowFile*)(a.alloc, a.workable, file);
}

// Note: File won't actually be worked on until 'CommonTypes' is set, but it still gets marked here.
bool isWorkable(scope ref AllUris allUris, in CrowFile a) {
	assert(!has(a.module_));
	return has(a.ast) &&
		has(a.config) &&
		every!MostlyResolvedImport(force(a.resolvedImports), (in MostlyResolvedImport x) =>
			isImportWorkable(allUris, x));
}

bool isImportWorkable(scope ref AllUris allUris, in MostlyResolvedImport a) =>
	a.matchConst!bool(
		(const CrowFile* x) =>
			has(x.module_),
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
	withExactSizeArrBuilder!MostlyResolvedImport(
		a.alloc,
		countImportsAndReExports(ast),
		(scope ref ExactSizeArrBuilder!MostlyResolvedImport res) {
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
	foreach (CrowFile* x; values(a.crowFiles))
		if (x != bootstrap)
			markModuleDirty(a, *x);
	mutSetClearAndKeepMemory(a.workable);
	foreach (CrowFile* x; values(a.crowFiles))
		if (x != bootstrap)
			addToWorkableIfSo(a, x);
}

void markModuleDirty(scope ref FrontendCompiler a, scope ref CrowFile file) {
	if (has(file.module_)) {
		// TODO: free the old module (but programState may reference!)
		file.module_ = noneMut!(Module*);
		a.countUncompiledCrowFiles++;
		foreach (CrowFile* x; file.referencedBy)
			markModuleDirty(a, *x);
	}
}

ResolvedImport[] fullyResolveImports(ref FrontendCompiler a, MostlyResolvedImport[] imports) =>
	map(a.alloc, imports, (ref MostlyResolvedImport x) =>
		x.match!ResolvedImport(
			(CrowFile* x) =>
				ResolvedImport(force(x.module_)),
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
	Uri includeCrow = childUri(allUris, includeDir, sym!"crow");
	Uri private_ = childUri(allUris, includeCrow, sym!"private");
	Uri col = childUri(allUris, includeCrow, sym!"col");
	return enumMapMapValues!(CommonModule, Uri, Uri)(immutable EnumMap!(CommonModule, Uri)([
		childUri(allUris, private_, sym!"bootstrap"),
		childUri(allUris, private_, sym!"alloc"),
		childUri(allUris, private_, sym!"exception-low-level"),
		childUri(allUris, includeCrow, sym!"fun-util"),
		childUri(allUris, includeCrow, sym!"future"),
		childUri(allUris, col, sym!"list"),
		childUri(allUris, includeCrow, sym!"std"),
		childUri(allUris, includeCrow, sym!"string"),
		childUri(allUris, private_, sym!"runtime"),
		childUri(allUris, private_, sym!"rt-main"),
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
