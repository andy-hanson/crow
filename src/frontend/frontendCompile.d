module frontend.frontendCompile;

@safe @nogc nothrow: // not pure

import model.diag : Diag, Diagnostics, FilesInfo;
import model.model : CommonTypes, LineAndColumnGetters, Module, ModuleAndNames, Program, SpecialModules;
import model.parseDiag : ParseDiag;
import frontend.check.check : BootstrapCheck, check, checkBootstrap, PathAndAst;
import frontend.check.inferringType : CommonFuns;
import frontend.diagnosticsBuilder : addDiagnostic, DiagnosticsBuilder, finishDiagnostics;
import frontend.parse.ast : emptyFileAst, FileAst, ImportAst, ImportsOrExportsAst;
import frontend.lang : crowExtension;
import frontend.parse.parse : parseFile;
import frontend.programState : ProgramState;
import util.alloc.alloc : Alloc;
import util.collection.arr : empty, emptyArr, ptrAt;
import util.collection.arrBuilder : add, ArrBuilder, arrBuilderSize, finishArr;
import util.collection.arrUtil : arrLiteral, copyArr, map, mapImpure, mapOp, mapWithSoFar, prepend;
import util.collection.fullIndexDict : FullIndexDict, fullIndexDictGetPtr, fullIndexDictOfArr;
import util.collection.mutDict : getAt_mut, MutDict, setInDict;
import util.collection.str : NulTerminatedStr, strOfNulTerminatedStr;
import util.conv : safeToUshort;
import util.late : late, Late, lateGet, lateIsSet, lateSet;
import util.lineAndColumnGetter : LineAndColumnGetter, lineAndColumnGetterForEmptyFile, lineAndColumnGetterForText;
import util.opt : force, has, mapOption, Opt, none, some;
import util.path :
	AllPaths,
	childPath,
	hashPathAndStorageKind,
	matchAbsOrRelPath,
	parent,
	Path,
	PathAndRange,
	PathAndStorageKind,
	pathAndStorageKindEqual,
	RelPath,
	resolvePath,
	rootPath,
	StorageKind;
import util.perf : Perf, PerfMeasure, withMeasure;
import util.ptr : Ptr;
import util.sourceRange : FileAndRange, FileIndex, FilePaths, RangeWithinFile;
import util.sym : AllSymbols, shortSymAlphaLiteral, Sym;
import util.util : unreachable, verify;

immutable(Program) frontendCompile(Storage)(
	ref Alloc modelAlloc,
	ref Perf perf,
	ref Alloc astsAlloc,
	ref AllPaths allPaths,
	ref AllSymbols allSymbols,
	ref Storage storage,
	immutable PathAndStorageKind main,
) {
	DiagnosticsBuilder diagsBuilder = DiagnosticsBuilder();
	immutable ParsedEverything parsed = withMeasure!(immutable ParsedEverything, () =>
		parseEverything(modelAlloc, perf, allPaths, allSymbols, diagsBuilder, storage, main, astsAlloc)
	)(astsAlloc, perf, PerfMeasure.parseEverything);
	immutable FilesInfo filesInfo = immutable FilesInfo(
		parsed.filePaths,
		storage.absolutePathsGetter(),
		parsed.lineAndColumnGetters);
	return withMeasure!(immutable Program, () =>
		checkEverything(modelAlloc, perf, allSymbols, diagsBuilder, parsed.asts, filesInfo, parsed.commonModuleIndices)
	)(modelAlloc, perf, PerfMeasure.checkEverything);
}

private struct FileAstAndLineAndColumnGetter {
	immutable FileAst ast;
	immutable LineAndColumnGetter lineAndColumnGetter;
}

struct FileAstAndDiagnostics {
	immutable FileAst ast;
	immutable FilesInfo filesInfo;
	immutable Diagnostics diagnostics;
}

immutable(FileAstAndDiagnostics) parseSingleAst(ReadOnlyStorage)(
	ref Alloc alloc,
	ref Perf perf,
	ref AllPaths allPaths,
	ref AllSymbols allSymbols,
	ref ReadOnlyStorage storage,
	immutable PathAndStorageKind path,
) {
	// In this case model alloc and AST alloc are the same
	return storage.withFile!(immutable FileAstAndDiagnostics)(
		path,
		crowExtension,
		(ref immutable Opt!NulTerminatedStr opFileContent) {
			DiagnosticsBuilder diags = DiagnosticsBuilder();
			immutable FileAstAndLineAndColumnGetter res = parseSingle(
				alloc,
				alloc,
				perf,
				allPaths,
				allSymbols,
				diags,
				immutable FileIndex(0),
				none!PathAndRange,
				opFileContent);
			immutable LineAndColumnGetters lc =
				fullIndexDictOfArr!(FileIndex, LineAndColumnGetter)(
					arrLiteral!LineAndColumnGetter(alloc, [res.lineAndColumnGetter]));
			immutable FilePaths filePaths = fullIndexDictOfArr!(FileIndex, PathAndStorageKind)(
				arrLiteral!PathAndStorageKind(alloc, [path]));
			return immutable FileAstAndDiagnostics(
				res.ast,
				immutable FilesInfo(filePaths, storage.absolutePathsGetter(), lc),
				finishDiagnostics(alloc, diags, filePaths));
		});
}

private:

struct ParseStatus {
	@safe @nogc pure nothrow:

	struct Started {}
	struct Done {
		immutable FileIndex fileIndex;
	}
	private:
	enum Kind {
		started,
		done,
	}
	immutable Kind kind_;
	union {
		immutable Started started_;
		immutable Done done_;
	}
	public:
	immutable this(immutable Started a) { kind_ = Kind.started; started_ = a; }
	immutable this(immutable Done a) { kind_ = Kind.done; done_ = a; }
}

T matchParseStatusImpure(T)(
	ref immutable ParseStatus a,
	scope immutable(T) delegate(ref immutable ParseStatus.Started) @safe @nogc nothrow cbStarted,
	scope immutable(T) delegate(ref immutable ParseStatus.Done) @safe @nogc nothrow cbDone,
) {
	final switch (a.kind_) {
		case ParseStatus.Kind.started:
			return cbStarted(a.started_);
		case ParseStatus.Kind.done:
			return cbDone(a.done_);
	}
}

alias PathToStatus = MutDict!(PathAndStorageKind, ParseStatus, pathAndStorageKindEqual, hashPathAndStorageKind);

struct ParsedEverything {
	immutable FilePaths filePaths;
	immutable LineAndColumnGetters lineAndColumnGetters;
	immutable CommonModuleIndices commonModuleIndices;
	immutable AstAndResolvedImports[] asts;
}

struct CommonModuleIndices {
	immutable FileIndex alloc;
	immutable FileIndex bootstrap;
	immutable FileIndex main;
	immutable FileIndex runtime;
	immutable FileIndex runtimeMain;
	immutable FileIndex std;
}

// Starts at 'main' and recursively parses all imports too.
// Result will be in import order -- asts at lower indices are imported by asts at higher indices.
// So, don't have to worry about circularity when checking.
immutable(ParsedEverything) parseEverything(ReadOnlyStorage)(
	ref Alloc modelAlloc,
	ref Perf perf,
	ref AllPaths allPaths,
	ref AllSymbols allSymbols,
	ref DiagnosticsBuilder diagsBuilder,
	ref ReadOnlyStorage storage,
	immutable PathAndStorageKind mainPath,
	ref Alloc astAlloc,
) {
	LineAndColumnGettersBuilder lineAndColumnGetters;
	ArrBuilder!AstAndResolvedImports res;
	ArrBuilder!PathAndStorageKind fileIndexToPath;
	PathToStatus statuses;

	immutable PathAndStorageKind bootstrapPath = bootstrapPath(allPaths);
	immutable PathAndStorageKind stdPath = stdPath(allPaths);
	immutable PathAndStorageKind runtimePath = runtimePath(allPaths);
	immutable PathAndStorageKind runtimeMainPath = runtimeMainPath(allPaths);
	immutable(FileIndex) parsePath(immutable PathAndStorageKind path) {
		immutable Opt!ParseStatus parseStatus = getAt_mut(statuses, path);
		return has(parseStatus)
			? matchParseStatusImpure!(immutable FileIndex)(
				force(parseStatus),
				(ref immutable ParseStatus.Started) =>
					unreachable!(immutable FileIndex),
				(ref immutable ParseStatus.Done it) =>
					it.fileIndex)
			: parseRecur(
				modelAlloc,
				astAlloc,
				perf,
				allPaths,
				allSymbols,
				storage,
				lineAndColumnGetters,
				res,
				fileIndexToPath,
				diagsBuilder,
				statuses,
				none!PathAndRange,
				path);
	}
	immutable FileIndex bootstrapIndex = parsePath(bootstrapPath);
	immutable FileIndex allocIndex = parsePath(allocPath(allPaths));
	immutable FileIndex stdIndex = parsePath(stdPath);
	immutable FileIndex runtimeIndex = parsePath(runtimePath);
	immutable FileIndex runtimeMainIndex = parsePath(runtimeMainPath);
	immutable FileIndex mainIndex = parsePath(mainPath);

	immutable CommonModuleIndices commonModuleIndices = immutable CommonModuleIndices(
		allocIndex,
		bootstrapIndex,
		mainIndex,
		runtimeIndex,
		runtimeMainIndex,
		stdIndex,
	);
	return immutable ParsedEverything(
		fullIndexDictOfArr!(FileIndex, PathAndStorageKind)(finishArr(modelAlloc, fileIndexToPath)),
		fullIndexDictOfArr!(FileIndex, LineAndColumnGetter)(finishArr(modelAlloc, lineAndColumnGetters)),
		commonModuleIndices,
		finishArr(astAlloc, res));
}

immutable(FileIndex) parseRecur(ReadOnlyStorage)(
	ref Alloc modelAlloc,
	ref Alloc astAlloc,
	ref Perf perf,
	ref AllPaths allPaths,
	ref AllSymbols allSymbols,
	ref ReadOnlyStorage storage,
	ref LineAndColumnGettersBuilder lineAndColumnGetters,
	ref ArrBuilder!AstAndResolvedImports res,
	ref ArrBuilder!PathAndStorageKind fileIndexToPath,
	ref DiagnosticsBuilder diags,
	ref PathToStatus statuses,
	immutable Opt!PathAndRange importedFrom,
	immutable PathAndStorageKind path,
) {
	setInDict(astAlloc, statuses, path, immutable ParseStatus(immutable ParseStatus.Started()));

	immutable(FileIndex) previewFileIndex() {
		return immutable FileIndex(safeToUshort(arrBuilderSize(fileIndexToPath)));
	}

	// We only add the file index when all dependencies are processed.
	// That way when we process files in index order, all dependencies will be ready.
	immutable(FileIndex) addFileIndex(
		immutable AstAndResolvedImports result,
		ref immutable LineAndColumnGetter lineAndColumnGetter,
	) {
		immutable FileIndex index = previewFileIndex();
		verify(index.index == arrBuilderSize(res));
		add(modelAlloc, fileIndexToPath, path);
		add(astAlloc, res, result);
		add(modelAlloc, lineAndColumnGetters, lineAndColumnGetter);
		setInDict(
			astAlloc,
			statuses,
			path,
			immutable ParseStatus(immutable ParseStatus.Done(index)));
		return index;
	}

	return storage.withFile(path, crowExtension, (ref immutable Opt!NulTerminatedStr opFileContent) {
		immutable FileAstAndLineAndColumnGetter parseResult = parseSingle(
			modelAlloc, astAlloc, perf, allPaths, allSymbols, diags, previewFileIndex(), importedFrom, opFileContent);
		immutable FileAst ast = parseResult.ast;
		immutable ImportAndExportPaths importsAndExports = resolveImportAndExportPaths(
			modelAlloc, astAlloc, allPaths, diags, previewFileIndex(), path, ast.imports, ast.exports);

		immutable(FileIndexAndNames[]) resolveImportsOrExports(ref immutable ResolvedImport[] importsOrExports) {
			return mapImpure!FileIndexAndNames(modelAlloc, importsOrExports, (ref immutable ResolvedImport import_) {
				immutable FileIndex fi = () {
					if (has(import_.resolvedPath)) {
						immutable PathAndStorageKind resolvedPath = force(import_.resolvedPath);
						immutable Opt!ParseStatus parseStatus = getAt_mut(statuses, resolvedPath);
						if (has(parseStatus))
							return matchParseStatusImpure!(immutable FileIndex)(
								force(parseStatus),
								(ref immutable ParseStatus.Started) {
									addDiagnostic(
										modelAlloc,
										diags,
										immutable FileAndRange(previewFileIndex(), import_.importedFrom),
										immutable Diag(immutable ParseDiag(
											immutable ParseDiag.CircularImport(path, resolvedPath))));
									return addFileIndex(AstAndResolvedImports.empty, parseResult.lineAndColumnGetter);
								},
								(ref immutable ParseStatus.Done it) =>
									it.fileIndex);
						else
							return parseRecur(
								modelAlloc,
								astAlloc,
								perf,
								allPaths,
								allSymbols,
								storage,
								lineAndColumnGetters,
								res,
								fileIndexToPath,
								diags,
								statuses,
								some(immutable PathAndRange(path, import_.importedFrom)),
								resolvedPath);
					} else
						// We should have already added a parse diagnostic when resolving the import
						return FileIndex.none;
				}();
				return immutable FileIndexAndNames(fi, some(import_.importedFrom), import_.names);
			});
		}
		immutable FileIndexAndNames[] resolvedImports = resolveImportsOrExports(importsAndExports.imports);
		immutable FileIndexAndNames[] resolvedExports = resolveImportsOrExports(importsAndExports.exports);
		return addFileIndex(
			immutable AstAndResolvedImports(ast, resolvedImports, resolvedExports),
			parseResult.lineAndColumnGetter);
	});
}

pure:

immutable(PathAndStorageKind) pathInInclude(ref AllPaths allPaths, immutable Sym name) {
	immutable Path crow = rootPath(allPaths, shortSymAlphaLiteral("crow"));
	return immutable PathAndStorageKind(childPath(allPaths, crow, name), StorageKind.global);
}

immutable(PathAndStorageKind) pathInIncludePrivate(ref AllPaths allPaths, immutable Sym name) {
	immutable Path crow = rootPath(allPaths, shortSymAlphaLiteral("crow"));
	immutable Path private_ = childPath(allPaths, crow, shortSymAlphaLiteral("private"));
	return immutable PathAndStorageKind(childPath(allPaths, private_, name), StorageKind.global);
}

immutable(PathAndStorageKind) bootstrapPath(ref AllPaths allPaths) {
	return pathInIncludePrivate(allPaths, shortSymAlphaLiteral("bootstrap"));
}

immutable(PathAndStorageKind) stdPath(ref AllPaths allPaths) {
	return pathInInclude(allPaths, shortSymAlphaLiteral("std"));
}

immutable(PathAndStorageKind) allocPath(ref AllPaths allPaths) {
	return pathInIncludePrivate(allPaths, shortSymAlphaLiteral("alloc"));
}

immutable(PathAndStorageKind) runtimePath(ref AllPaths allPaths) {
	return pathInIncludePrivate(allPaths, shortSymAlphaLiteral("runtime"));
}

immutable(PathAndStorageKind) runtimeMainPath(ref AllPaths allPaths) {
	return pathInIncludePrivate(allPaths, shortSymAlphaLiteral("rt-main"));
}

alias LineAndColumnGettersBuilder = ArrBuilder!LineAndColumnGetter; // TODO: OrderedFullIndexDictBuilder?

immutable(FileAstAndLineAndColumnGetter) parseSingle(
	ref Alloc modelAlloc,
	ref Alloc astAlloc,
	ref Perf perf,
	ref AllPaths allPaths,
	ref AllSymbols allSymbols,
	ref DiagnosticsBuilder diags,
	immutable FileIndex fileIndex,
	immutable Opt!PathAndRange importedFrom,
	immutable Opt!NulTerminatedStr opFileContent,
) {
	immutable LineAndColumnGetter lcg = has(opFileContent)
		? lineAndColumnGetterForText(modelAlloc, strOfNulTerminatedStr(force(opFileContent)))
		: lineAndColumnGetterForEmptyFile(modelAlloc);

	// File content must go in astAlloc because we refer to strings without copying
	if (has(opFileContent))
		return immutable FileAstAndLineAndColumnGetter(
			parseFile(astAlloc, perf, allPaths, allSymbols, diags, fileIndex, force(opFileContent)),
			lcg);
	else {
		addDiagnostic(modelAlloc, diags, immutable FileAndRange(fileIndex, RangeWithinFile.empty), immutable Diag(
			immutable ParseDiag(immutable ParseDiag.FileDoesNotExist(importedFrom))));
		return immutable FileAstAndLineAndColumnGetter(emptyFileAst, lcg);
	}
}

struct ResolvedImport {
	// This is arbitrarily the first module we saw to import this.
	// This is just used for error reporting in case the file can't be read.
	immutable RangeWithinFile importedFrom;
	immutable Opt!PathAndStorageKind resolvedPath;
	immutable Opt!(Sym[]) names;
}

immutable(ResolvedImport) tryResolveImport(
	ref Alloc modelAlloc,
	ref AllPaths allPaths,
	ref DiagnosticsBuilder diagnosticsBuilder,
	immutable FileIndex fromIndex,
	immutable PathAndStorageKind fromPath,
	immutable ImportAst ast,
) {
	immutable Opt!(Sym[]) names = mapOption!(Sym[], Sym[])(ast.names, (ref immutable Sym[] names) =>
		copyArr(modelAlloc, names));
	immutable(ResolvedImport) resolved(immutable PathAndStorageKind pk) {
		return immutable ResolvedImport(ast.range, some(pk), names);
	}
	return matchAbsOrRelPath!(immutable ResolvedImport)(
		ast.path,
		(immutable Path global) =>
			resolved(immutable PathAndStorageKind(global, StorageKind.global)),
		(immutable RelPath relPath) {
			immutable Opt!Path rel = resolvePath(allPaths, parent(allPaths, fromPath.path), relPath);
			if (has(rel))
				return resolved(immutable PathAndStorageKind(force(rel), fromPath.storageKind));
			else {
				addDiagnostic(
					modelAlloc,
					diagnosticsBuilder,
					immutable FileAndRange(fromIndex, ast.range),
					immutable Diag(immutable ParseDiag(ParseDiag.RelativeImportReachesPastRoot(relPath))));
				return immutable ResolvedImport(ast.range, none!PathAndStorageKind, names);
			}
		});
}

struct ImportAndExportPaths {
	immutable ResolvedImport[] imports;
	immutable ResolvedImport[] exports;
}

immutable(ResolvedImport[]) resolveImportOrExportPaths(
	ref Alloc modelAlloc,
	ref Alloc astAlloc,
	ref AllPaths allPaths,
	ref DiagnosticsBuilder diagnosticsBuilder,
	immutable FileIndex fromIndex,
	immutable PathAndStorageKind fromPath,
	ref immutable Opt!ImportsOrExportsAst importsOrExports,
) {
	immutable ImportAst[] paths = has(importsOrExports) ? force(importsOrExports).paths : emptyArr!ImportAst;
	return map(astAlloc, paths, (ref immutable ImportAst i) =>
		tryResolveImport(modelAlloc, allPaths, diagnosticsBuilder, fromIndex, fromPath, i));
}

immutable(ImportAndExportPaths) resolveImportAndExportPaths(
	ref Alloc modelAlloc,
	ref Alloc astAlloc,
	ref AllPaths allPaths,
	ref DiagnosticsBuilder diagnosticsBuilder,
	immutable FileIndex fromIndex,
	immutable PathAndStorageKind fromPath,
	ref immutable Opt!ImportsOrExportsAst imports,
	ref immutable Opt!ImportsOrExportsAst exports,
) {
	return immutable ImportAndExportPaths(
		resolveImportOrExportPaths(modelAlloc, astAlloc, allPaths, diagnosticsBuilder, fromIndex, fromPath, imports),
		resolveImportOrExportPaths(modelAlloc, astAlloc, allPaths, diagnosticsBuilder, fromIndex, fromPath, exports));
}

struct AstAndResolvedImports {
	immutable FileAst ast;
	immutable FileIndexAndNames[] resolvedImports;
	immutable FileIndexAndNames[] resolvedExports;

	static immutable AstAndResolvedImports empty =
		immutable AstAndResolvedImports(emptyFileAst, emptyArr!FileIndexAndNames, emptyArr!FileIndexAndNames);
}

struct FileIndexAndNames {
	immutable FileIndex fileIndex;
	immutable Opt!RangeWithinFile range;
	immutable Opt!(Sym[]) names;
}

//TODO:INLINE
immutable(ModuleAndNames[]) mapImportsOrExports(
	ref Alloc modelAlloc,
	ref immutable FileIndexAndNames[] paths,
	ref immutable FullIndexDict!(FileIndex, Module) compiled,
) {
	return mapOp(modelAlloc, paths, (ref immutable FileIndexAndNames it) =>
		it.fileIndex == FileIndex.none
			? none!ModuleAndNames
			: some(immutable ModuleAndNames(it.range, fullIndexDictGetPtr(compiled, it.fileIndex), it.names)));
}

struct ModulesAndCommonTypes {
	immutable Module[] modules;
	immutable CommonTypes commonTypes;
}

immutable(ModulesAndCommonTypes) getModules(
	ref Alloc modelAlloc,
	ref Perf perf,
	ref AllSymbols allSymbols,
	ref DiagnosticsBuilder diagsBuilder,
	ref ProgramState programState,
	immutable FileIndex stdIndex,
	ref immutable AstAndResolvedImports[] fileAsts,
) {
	Late!(immutable CommonFuns) commonFuns = late!(immutable CommonFuns);
	Late!(immutable CommonTypes) commonTypes = late!(immutable CommonTypes);
	immutable Module[] modules = mapWithSoFar!Module(
		modelAlloc,
		fileAsts,
		(ref immutable AstAndResolvedImports ast, ref immutable Module[] soFar, immutable size_t index) {
			immutable FullIndexDict!(FileIndex, Module) compiled = fullIndexDictOfArr!(FileIndex, Module)(soFar);
			immutable PathAndAst pathAndAst = immutable PathAndAst(immutable FileIndex(safeToUshort(index)), ast.ast);
			if (lateIsSet(commonTypes)) {
				immutable bool noStd = ast.ast.noStd;
				immutable FileIndexAndNames[] allImports = noStd
					? ast.resolvedImports
					: prepend(
						modelAlloc,
						immutable FileIndexAndNames(stdIndex, none!RangeWithinFile, none!(Sym[])),
						ast.resolvedImports);
				immutable ModuleAndNames[] mappedImports =
					mapImportsOrExports(modelAlloc, allImports, compiled);
				immutable ModuleAndNames[] mappedExports =
					mapImportsOrExports(modelAlloc, ast.resolvedExports, compiled);
				return check(
					modelAlloc,
					perf,
					allSymbols,
					diagsBuilder,
					programState,
					mappedImports,
					mappedExports,
					pathAndAst,
					lateGet(commonFuns),
					lateGet(commonTypes));
			} else {
				// The first module to check is always 'bootstrap.crow'
				verify(ast.resolvedImports.empty);
				immutable BootstrapCheck res =
					checkBootstrap(modelAlloc, perf, allSymbols, diagsBuilder, programState, pathAndAst);
				lateSet(commonFuns, res.commonFuns);
				lateSet(commonTypes, res.commonTypes);
				return res.module_;
			}
		});
	return immutable ModulesAndCommonTypes(modules, lateGet(commonTypes));
}

immutable(Program) checkEverything(
	ref Alloc modelAlloc,
	ref Perf perf,
	ref AllSymbols allSymbols,
	ref DiagnosticsBuilder diagsBuilder,
	ref immutable AstAndResolvedImports[] allAsts,
	immutable FilesInfo filesInfo,
	ref immutable CommonModuleIndices moduleIndices,
) {
	ProgramState programState = ProgramState(allSymbols);
	immutable ModulesAndCommonTypes modulesAndCommonTypes =
		getModules(modelAlloc, perf, allSymbols, diagsBuilder, programState, moduleIndices.std, allAsts);
	immutable Module[] modules = modulesAndCommonTypes.modules;
	immutable Ptr!Module bootstrapModule = ptrAt(modules, moduleIndices.bootstrap.index);
	return immutable Program(
		filesInfo,
		immutable SpecialModules(
			ptrAt(modules, moduleIndices.alloc.index),
			bootstrapModule,
			ptrAt(modules, moduleIndices.runtime.index),
			ptrAt(modules, moduleIndices.runtimeMain.index),
			ptrAt(modules, moduleIndices.main.index)),
		modules,
		modulesAndCommonTypes.commonTypes,
		finishDiagnostics(modelAlloc, diagsBuilder, filesInfo.filePaths));
}
