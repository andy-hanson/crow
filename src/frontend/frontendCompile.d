module frontend.frontendCompile;

@safe @nogc nothrow: // not pure

import model.diag : Diag, Diagnostics, DiagnosticWithinFile, FilesInfo, filesInfoForSingle;
import model.model :
	CommonTypes,
	copyAbsolutePathsGetter,
	LineAndColumnGetters,
	Module,
	ModuleAndNames,
	Program,
	SpecialModules;
import model.parseDiag : ParseDiag;
import frontend.check.check : BootstrapCheck, check, checkBootstrap, PathAndAst;
import frontend.diagnosticsBuilder : addDiagnosticsForFile, DiagnosticsBuilder, finishDiagnostics;
import frontend.parse.ast : emptyFileAst, FileAst, ImportAst, ImportsOrExportsAst;
import frontend.lang : crowExtension;
import frontend.parse.parse : parseFile;
import frontend.programState : ProgramState;
import util.alloc.alloc : Alloc;
import util.col.arr : empty, emptyArr, ptrAt;
import util.col.arrBuilder : add, ArrBuilder, arrBuilderSize, finishArr;
import util.col.arrUtil : copyArr, map, mapOp, mapOrNoneImpure, mapWithSoFar, prepend;
import util.col.dict : dictSize, mapValues;
import util.col.fullIndexDict : FullIndexDict, fullIndexDictOfArr, fullIndexDictSize, ptrAt;
import util.col.mutMaxArr : isEmpty, mustPeek, mustPop, MutMaxArr, mutMaxArr, push;
import util.col.mutDict : addToMutDict, getAt_mut, hasKey_mut, moveToDict, mustGetAt_mut, MutDict, setInDict;
import util.col.str : SafeCStr;
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
import util.readOnlyStorage : ReadOnlyStorage, withFile;
import util.sourceRange : FileIndex, FilePaths, PathToFile, RangeWithinFile;
import util.sym : AllSymbols, shortSym, Sym;
import util.util : verify;

immutable(Program) frontendCompile(
	ref Alloc modelAlloc,
	scope ref Perf perf,
	ref Alloc astsAlloc,
	ref AllPaths allPaths,
	ref AllSymbols allSymbols,
	scope ref const ReadOnlyStorage storage,
	scope immutable PathAndStorageKind[] rootPaths,
) {
	DiagnosticsBuilder diagsBuilder = DiagnosticsBuilder();
	immutable ParsedEverything parsed = withMeasure!(immutable ParsedEverything, () =>
		parseEverything(modelAlloc, perf, allPaths, allSymbols, diagsBuilder, storage, rootPaths, astsAlloc)
	)(astsAlloc, perf, PerfMeasure.parseEverything);
	immutable FilesInfo filesInfo = immutable FilesInfo(
		parsed.filePaths,
		parsed.pathToFile,
		copyAbsolutePathsGetter(modelAlloc, storage.absolutePathsGetter),
		parsed.lineAndColumnGetters);
	return withMeasure!(immutable Program, () =>
		checkEverything(modelAlloc, perf, allSymbols, diagsBuilder, parsed.asts, filesInfo, parsed.commonModuleIndices)
	)(modelAlloc, perf, PerfMeasure.checkEverything);
}

struct FileAstAndDiagnostics {
	immutable FileAst ast;
	immutable FilesInfo filesInfo;
	immutable Diagnostics diagnostics;
}

immutable(FileAstAndDiagnostics) parseSingleAst(
	ref Alloc alloc,
	ref Perf perf,
	ref AllSymbols allSymbols,
	ref AllPaths allPaths,
	scope ref const ReadOnlyStorage storage,
	immutable PathAndStorageKind path,
) {
	// In this case model alloc and AST alloc are the same
	return withFile(storage, path, crowExtension, (immutable Opt!SafeCStr opFileContent) {
		ArrBuilder!DiagnosticWithinFile diags;
		immutable FileAst ast = parseSingle(
			alloc,
			alloc,
			perf,
			allPaths,
			allSymbols,
			diags,
			none!PathAndRange,
			opFileContent);
		DiagnosticsBuilder diagsBuilder;
		addDiagnosticsForFile(alloc, diagsBuilder, immutable FileIndex(0), diags);
		immutable FilesInfo filesInfo = filesInfoForSingle(
			alloc,
			path,
			lineAndColumnGetterForOptText(alloc, opFileContent),
			copyAbsolutePathsGetter(alloc, storage.absolutePathsGetter));
		return immutable FileAstAndDiagnostics(
			ast,
			filesInfo,
			finishDiagnostics(alloc, diagsBuilder, filesInfo.filePaths));
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

T matchParseStatus(T)(
	ref immutable ParseStatus a,
	scope immutable(T) delegate(ref immutable ParseStatus.Started) @safe @nogc pure nothrow cbStarted,
	scope immutable(T) delegate(ref immutable ParseStatus.Done) @safe @nogc pure nothrow cbDone,
) {
	final switch (a.kind_) {
		case ParseStatus.Kind.started:
			return cbStarted(a.started_);
		case ParseStatus.Kind.done:
			return cbDone(a.done_);
	}
}

pure immutable(FileIndex) asDone(immutable ParseStatus a) {
	verify(a.kind_ == ParseStatus.Kind.done);
	return a.done_.fileIndex;
}

alias PathToStatus = MutDict!(
	immutable PathAndStorageKind,
	immutable ParseStatus,
	pathAndStorageKindEqual,
	hashPathAndStorageKind);

struct ParsedEverything {
	@safe @nogc pure nothrow:

	immutable FilePaths filePaths;
	immutable PathToFile pathToFile;
	immutable LineAndColumnGetters lineAndColumnGetters;
	immutable CommonModuleIndices commonModuleIndices;
	immutable AstAndResolvedImports[] asts;

	immutable this(
		immutable FilePaths fp,
		immutable PathToFile ptf,
		immutable LineAndColumnGetters lcg,
		immutable CommonModuleIndices cmi,
		immutable AstAndResolvedImports[] a,
	) {
		filePaths = fp;
		pathToFile = ptf;
		lineAndColumnGetters = lcg;
		commonModuleIndices = cmi;
		asts = a;

		immutable size_t size = fullIndexDictSize(filePaths);
		verify(dictSize(pathToFile) == size);
		verify(fullIndexDictSize(lineAndColumnGetters) == size);
		verify(asts.length == size);
	}
}

struct CommonModuleIndices {
	immutable FileIndex alloc;
	immutable FileIndex bootstrap;
	immutable FileIndex std;
	immutable FileIndex runtime;
	immutable FileIndex runtimeMain;
	immutable FileIndex[] rootPaths;
}

struct ParseStackEntry {
	immutable PathAndStorageKind path;
	immutable FileAst ast;
	immutable LineAndColumnGetter lineAndColumnGetter;
	immutable ImportAndExportPaths importsAndExports;
	ArrBuilder!DiagnosticWithinFile diags;
}

//TODO: Marked @trusted to avoid initializing stack...
@trusted immutable(ParsedEverything) parseEverything(
	ref Alloc modelAlloc,
	scope ref Perf perf,
	ref AllPaths allPaths,
	ref AllSymbols allSymbols,
	ref DiagnosticsBuilder diagsBuilder,
	scope ref const ReadOnlyStorage storage,
	scope immutable PathAndStorageKind[] rootPaths,
	ref Alloc astAlloc,
) {
	ArrBuilder!PathAndStorageKind fileIndexToPath;
	PathToStatus statuses;
	ArrBuilder!AstAndResolvedImports res;
	LineAndColumnGettersBuilder lineAndColumnGetters;

	MutMaxArr!(32, ParseStackEntry) stack = mutMaxArr!(32, ParseStackEntry)();

	void pushIt(immutable PathAndStorageKind path, immutable Opt!PathAndRange importedFrom) {
		withFile!void(storage, path, crowExtension, (immutable Opt!SafeCStr opFileContent) {
			ArrBuilder!DiagnosticWithinFile diags;
			immutable LineAndColumnGetter lineAndColumnGetter =
				lineAndColumnGetterForOptText(modelAlloc, opFileContent);
			immutable FileAst ast = parseSingle(
				modelAlloc, astAlloc, perf, allPaths, allSymbols, diags, importedFrom, opFileContent);
			immutable ImportAndExportPaths importsAndExports = resolveImportAndExportPaths(
				modelAlloc, astAlloc, allPaths, diags, path, ast.imports, ast.exports);
			addToMutDict(astAlloc, statuses, path, immutable ParseStatus(immutable ParseStatus.Started()));
			push(stack, ParseStackEntry(path, ast, lineAndColumnGetter, importsAndExports, diags));
		});
	}

	immutable(Opt!(FileIndexAndNames[])) resolveImportsOrExports(
		ref ArrBuilder!DiagnosticWithinFile diags,
		immutable PathAndStorageKind fromPath,
		immutable ResolvedImport[] importsOrExports,
	) {
		return mapOrNoneImpure(modelAlloc, importsOrExports, (ref immutable ResolvedImport import_) {
			immutable Opt!FileIndex importIndex = () {
				if (has(import_.resolvedPath)) {
					immutable PathAndStorageKind importPath = force(import_.resolvedPath);
					immutable Opt!(immutable ParseStatus) status = getAt_mut(statuses, importPath);
					if (has(status))
						return some(matchParseStatus!(immutable FileIndex)(
							force(status),
							(ref immutable ParseStatus.Started) {
								add(modelAlloc, diags, immutable DiagnosticWithinFile(
									import_.importedFrom,
									immutable Diag(immutable ParseDiag(
										immutable ParseDiag.CircularImport(fromPath, importPath)))));
								return FileIndex.none;
							},
							(ref immutable ParseStatus.Done x) =>
								x.fileIndex));
					else {
						pushIt(importPath, some(immutable PathAndRange(fromPath, import_.importedFrom)));
						return none!FileIndex;
					}
				} else
					return some(FileIndex.none);
			}();
			return has(importIndex)
				? some(immutable FileIndexAndNames(force(importIndex), some(import_.importedFrom), import_.names))
				: none!FileIndexAndNames;
		});
	}

	immutable PathAndStorageKind bootstrapPath = bootstrapPath(allPaths);
	immutable PathAndStorageKind allocPath = allocPath(allPaths);
	immutable PathAndStorageKind stdPath = stdPath(allPaths);
	immutable PathAndStorageKind runtimePath = runtimePath(allPaths);
	immutable PathAndStorageKind runtimeMainPath = runtimeMainPath(allPaths);

	void process() {
		while (!isEmpty(stack)) {
			immutable PathAndStorageKind path = mustPeek(stack).path;
			immutable ImportAndExportPaths importsAndExports = mustPeek(stack).importsAndExports;
			immutable Opt!(FileIndexAndNames[]) imports =
				resolveImportsOrExports(mustPeek(stack).diags, path, importsAndExports.imports);
			immutable Opt!(FileIndexAndNames[]) exports =
				resolveImportsOrExports(mustPeek(stack).diags, path, importsAndExports.exports);
			if (has(imports) && has(exports)) {
				ParseStackEntry entry = mustPop(stack);
				immutable FileIndex fileIndex = immutable FileIndex(safeToUshort(arrBuilderSize(res)));

				addDiagnosticsForFile(modelAlloc, diagsBuilder, fileIndex, entry.diags);
				verify(arrBuilderSize(fileIndexToPath) == fileIndex.index);
				verify(arrBuilderSize(lineAndColumnGetters) == fileIndex.index);
				add(astAlloc, res, immutable AstAndResolvedImports(entry.ast, force(imports), force(exports)));
				add(modelAlloc, fileIndexToPath, path);
				add(modelAlloc, lineAndColumnGetters, entry.lineAndColumnGetter);
				setInDict(astAlloc, statuses, path, immutable ParseStatus(immutable ParseStatus.Done(fileIndex)));
			}
			// else, we just pushed a dependency to the stack, so repeat.
		}
	}

	void processRootPath(immutable PathAndStorageKind path) {
		if (!hasKey_mut(statuses, path)) {
			pushIt(path, none!PathAndRange);
			process();
		}
	}
	foreach (immutable PathAndStorageKind path; [bootstrapPath, allocPath, stdPath, runtimePath, runtimeMainPath])
		processRootPath(path);
	foreach (immutable PathAndStorageKind path; rootPaths)
		processRootPath(path);

	verify(isEmpty(stack));

	immutable(FileIndex) getIndex(immutable PathAndStorageKind path) pure {
		return asDone(mustGetAt_mut(statuses, path));
	}

	immutable CommonModuleIndices commonModuleIndices = immutable CommonModuleIndices(
		getIndex(allocPath),
		getIndex(bootstrapPath),
		getIndex(stdPath),
		getIndex(runtimePath),
		getIndex(runtimeMainPath),
		map!(FileIndex, PathAndStorageKind)(modelAlloc, rootPaths, (ref immutable PathAndStorageKind path) =>
			getIndex(path)));

	return immutable ParsedEverything(
		fullIndexDictOfArr!(FileIndex, PathAndStorageKind)(finishArr(modelAlloc, fileIndexToPath)),
		mapValues!(PathAndStorageKind, ParseStatus, FileIndex, pathAndStorageKindEqual, hashPathAndStorageKind)(
			modelAlloc,
			moveToDict(astAlloc, statuses),
			(immutable(PathAndStorageKind), ref immutable ParseStatus x) =>
				asDone(x)),
		fullIndexDictOfArr!(FileIndex, LineAndColumnGetter)(finishArr(modelAlloc, lineAndColumnGetters)),
		commonModuleIndices,
		finishArr(astAlloc, res));
}

pure:

immutable(PathAndStorageKind) pathInInclude(ref AllPaths allPaths, immutable Sym name) {
	immutable Path crow = rootPath(allPaths, shortSym("crow"));
	return immutable PathAndStorageKind(childPath(allPaths, crow, name), StorageKind.global);
}

immutable(PathAndStorageKind) pathInIncludePrivate(ref AllPaths allPaths, immutable Sym name) {
	immutable Path crow = rootPath(allPaths, shortSym("crow"));
	immutable Path private_ = childPath(allPaths, crow, shortSym("private"));
	return immutable PathAndStorageKind(childPath(allPaths, private_, name), StorageKind.global);
}

immutable(PathAndStorageKind) bootstrapPath(ref AllPaths allPaths) {
	return pathInIncludePrivate(allPaths, shortSym("bootstrap"));
}

immutable(PathAndStorageKind) stdPath(ref AllPaths allPaths) {
	return pathInInclude(allPaths, shortSym("std"));
}

immutable(PathAndStorageKind) allocPath(ref AllPaths allPaths) {
	return pathInIncludePrivate(allPaths, shortSym("alloc"));
}

immutable(PathAndStorageKind) runtimePath(ref AllPaths allPaths) {
	return pathInIncludePrivate(allPaths, shortSym("runtime"));
}

immutable(PathAndStorageKind) runtimeMainPath(ref AllPaths allPaths) {
	return pathInIncludePrivate(allPaths, shortSym("rt-main"));
}

alias LineAndColumnGettersBuilder = ArrBuilder!LineAndColumnGetter; // TODO: OrderedFullIndexDictBuilder?

immutable(LineAndColumnGetter) lineAndColumnGetterForOptText(
	ref Alloc modelAlloc,
	immutable Opt!SafeCStr opFileContent,
) {
	return has(opFileContent)
		? lineAndColumnGetterForText(modelAlloc, force(opFileContent))
		: lineAndColumnGetterForEmptyFile(modelAlloc);
}

immutable(FileAst) parseSingle(
	ref Alloc modelAlloc,
	ref Alloc astAlloc,
	scope ref Perf perf,
	ref AllPaths allPaths,
	ref AllSymbols allSymbols,
	ref ArrBuilder!DiagnosticWithinFile diags,
	immutable Opt!PathAndRange importedFrom,
	immutable Opt!SafeCStr opFileContent,
) {
	// File content must go in astAlloc because we refer to strings without copying
	if (has(opFileContent))
		return immutable parseFile(astAlloc, perf, allPaths, allSymbols, diags, force(opFileContent));
	else {
		add(modelAlloc, diags, immutable DiagnosticWithinFile(RangeWithinFile.empty, immutable Diag(
			immutable ParseDiag(immutable ParseDiag.FileDoesNotExist(importedFrom)))));
		return emptyFileAst;
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
	ref ArrBuilder!DiagnosticWithinFile diagnosticsBuilder,
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
				add(modelAlloc, diagnosticsBuilder, immutable DiagnosticWithinFile(ast.range, immutable Diag(
					immutable ParseDiag(immutable ParseDiag.RelativeImportReachesPastRoot(relPath)))));
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
	ref ArrBuilder!DiagnosticWithinFile diagnosticsBuilder,
	immutable PathAndStorageKind fromPath,
	ref immutable Opt!ImportsOrExportsAst importsOrExports,
) {
	immutable ImportAst[] paths = has(importsOrExports) ? force(importsOrExports).paths : emptyArr!ImportAst;
	return map(astAlloc, paths, (ref immutable ImportAst i) =>
		tryResolveImport(modelAlloc, allPaths, diagnosticsBuilder, fromPath, i));
}

immutable(ImportAndExportPaths) resolveImportAndExportPaths(
	ref Alloc modelAlloc,
	ref Alloc astAlloc,
	ref AllPaths allPaths,
	ref ArrBuilder!DiagnosticWithinFile diagnosticsBuilder,
	immutable PathAndStorageKind fromPath,
	ref immutable Opt!ImportsOrExportsAst imports,
	ref immutable Opt!ImportsOrExportsAst exports,
) {
	return immutable ImportAndExportPaths(
		resolveImportOrExportPaths(modelAlloc, astAlloc, allPaths, diagnosticsBuilder, fromPath, imports),
		resolveImportOrExportPaths(modelAlloc, astAlloc, allPaths, diagnosticsBuilder, fromPath, exports));
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
	return mapOp!(ModuleAndNames, FileIndexAndNames)(modelAlloc, paths, (ref immutable FileIndexAndNames it) =>
		it.fileIndex == FileIndex.none
			? none!ModuleAndNames
			: some(immutable ModuleAndNames(it.range, ptrAt(compiled, it.fileIndex), it.names)));
}

struct ModulesAndCommonTypes {
	immutable Module[] modules;
	immutable CommonTypes commonTypes;
}

immutable(ModulesAndCommonTypes) getModules(
	ref Alloc modelAlloc,
	scope ref Perf perf,
	ref AllSymbols allSymbols,
	ref DiagnosticsBuilder diagsBuilder,
	ref ProgramState programState,
	immutable FileIndex stdIndex,
	ref immutable AstAndResolvedImports[] fileAsts,
) {
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
					lateGet(commonTypes));
			} else {
				// The first module to check is always 'bootstrap.crow'
				verify(ast.resolvedImports.empty);
				immutable BootstrapCheck res =
					checkBootstrap(modelAlloc, perf, allSymbols, diagsBuilder, programState, pathAndAst);
				lateSet(commonTypes, res.commonTypes);
				return res.module_;
			}
		});
	return immutable ModulesAndCommonTypes(modules, lateGet(commonTypes));
}

immutable(Program) checkEverything(
	ref Alloc modelAlloc,
	scope ref Perf perf,
	ref AllSymbols allSymbols,
	ref DiagnosticsBuilder diagsBuilder,
	ref immutable AstAndResolvedImports[] allAsts,
	ref immutable FilesInfo filesInfo,
	ref immutable CommonModuleIndices moduleIndices,
) {
	ProgramState programState;
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
			map(modelAlloc, moduleIndices.rootPaths, (ref immutable FileIndex index) =>
				ptrAt(modules, index.index))),
		modules,
		modulesAndCommonTypes.commonTypes,
		finishDiagnostics(modelAlloc, diagsBuilder, filesInfo.filePaths));
}
