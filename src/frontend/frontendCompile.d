module frontend.frontendCompile;

@safe @nogc nothrow: // not pure

import model.diag : Diag, Diags, Diagnostic, FilesInfo;
import model.model : CommonTypes, LineAndColumnGetters, Module, ModuleAndNames, Program, SpecialModules;
import model.parseDiag : ParseDiag, ParseDiagnostic;
import frontend.check.check : BootstrapCheck, check, checkBootstrap, PathAndAst;
import frontend.check.inferringType : CommonFuns;
import frontend.parse.ast : emptyFileAst, FileAst, ImportAst, ImportsOrExportsAst;
import frontend.lang : crowExtension;
import frontend.parse.parse : FileAstAndParseDiagnostics, parseFile;
import frontend.programState : ProgramState;
import util.alloc.alloc : Alloc;
import util.collection.arr : at, empty, emptyArr;
import util.collection.arrBuilder : add, addAll, ArrBuilder, arrBuilderSize, finishArr;
import util.collection.arrUtil : arrLiteral, cat, copyArr, map, mapImpure, mapOp, mapWithSoFar, prepend;
import util.collection.fullIndexDict : FullIndexDict, fullIndexDictGet, fullIndexDictOfArr;
import util.collection.mutDict : getAt_mut, MutDict, setInDict;
import util.collection.str : NulTerminatedStr, strOfNulTerminatedStr;
import util.late : late, Late, lateGet, lateIsSet, lateSet;
import util.lineAndColumnGetter : LineAndColumnGetter, lineAndColumnGetterForEmptyFile, lineAndColumnGetterForText;
import util.memory : allocate;
import util.opt : force, has, mapOption, Opt, none, some;
import util.path :
	AllPaths,
	childPath,
	comparePathAndStorageKind,
	matchAbsOrRelPath,
	parent,
	Path,
	PathAndRange,
	PathAndStorageKind,
	RelPath,
	resolvePath,
	rootPath,
	StorageKind;
import util.ptr : Ptr;
import util.sourceRange : FileAndRange, FileIndex, FilePaths, RangeWithinFile;
import util.sym : AllSymbols, Sym;
import util.types : safeSizeTToU16;
import util.util : unreachable, verify;

immutable(Ptr!Program) frontendCompile(Storage)(
	ref Alloc modelAlloc,
	ref Alloc astsAlloc,
	ref AllPaths allPaths,
	ref AllSymbols allSymbols,
	ref Storage storage,
	immutable PathAndStorageKind main,
) {
	ArrBuilder!Diagnostic diagsBuilder;
	immutable ParsedEverything parsed =
		parseEverything(modelAlloc, allPaths, allSymbols, diagsBuilder, storage, main, astsAlloc);
	immutable Ptr!FilesInfo filesInfo = allocate(modelAlloc, immutable FilesInfo(
		parsed.filePaths,
		allocate(modelAlloc, storage.absolutePathsGetter()),
		parsed.lineAndColumnGetters));
	return checkEverything(modelAlloc, allSymbols, diagsBuilder, parsed.asts, filesInfo, parsed.commonModuleIndices);
}

private struct FileAstAndArrDiagnosticAndLineAndColumnGetter {
	immutable Ptr!FileAst ast;
	immutable ParseDiagnostic[] diagnostics;
	immutable LineAndColumnGetter lineAndColumnGetter;
}

struct FileAstAndDiagnostics {
	immutable FileAst ast;
	immutable FilesInfo filesInfo;
	immutable Diags diagnostics;
}

immutable(FileAstAndDiagnostics) parseSingleAst(ReadOnlyStorage)(
	ref Alloc alloc,
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
			immutable FileAstAndArrDiagnosticAndLineAndColumnGetter res = parseSingle(
				alloc,
				alloc,
				allPaths,
				allSymbols,
				none!PathAndRange,
				opFileContent);
			immutable LineAndColumnGetters lc =
				fullIndexDictOfArr!(FileIndex, LineAndColumnGetter)(
					arrLiteral!LineAndColumnGetter(alloc, [res.lineAndColumnGetter]));
			immutable FilePaths filePaths = fullIndexDictOfArr!(FileIndex, PathAndStorageKind)(
				arrLiteral!PathAndStorageKind(alloc, [path]));
			return immutable FileAstAndDiagnostics(
				res.ast,
				immutable FilesInfo(filePaths, allocate(alloc, storage.absolutePathsGetter()), lc),
				parseDiagnostics(alloc, immutable FileIndex(0), res.diagnostics));
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

alias PathToStatus = MutDict!(PathAndStorageKind, ParseStatus, comparePathAndStorageKind);

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
	ref AllPaths allPaths,
	ref AllSymbols allSymbols,
	ref ArrBuilder!Diagnostic diagsBuilder,
	ref ReadOnlyStorage storage,
	ref immutable PathAndStorageKind mainPath,
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
	ref AllPaths allPaths,
	ref AllSymbols allSymbols,
	ref ReadOnlyStorage storage,
	ref LineAndColumnGettersBuilder lineAndColumnGetters,
	ref ArrBuilder!AstAndResolvedImports res,
	ref ArrBuilder!PathAndStorageKind fileIndexToPath,
	ref ArrBuilder!Diagnostic diags,
	ref PathToStatus statuses,
	immutable Opt!PathAndRange importedFrom,
	immutable PathAndStorageKind path,
) {
	setInDict(astAlloc, statuses, path, immutable ParseStatus(immutable ParseStatus.Started()));

	// We only add the file index when all dependencies are processed.
	// That way when we process files in index order, all dependencies will be ready.
	immutable(FileIndex) addFileIndex(
		immutable AstAndResolvedImports result,
		immutable ParseDiagnostic[] parseDiags,
		ref immutable LineAndColumnGetter lineAndColumnGetter,
	) {
		immutable FileIndex index = immutable FileIndex(safeSizeTToU16(arrBuilderSize(fileIndexToPath)));
		verify(index.index == arrBuilderSize(res));
		add(modelAlloc, fileIndexToPath, path);
		add(astAlloc, res, result);
		add(modelAlloc, lineAndColumnGetters, lineAndColumnGetter);
		setInDict(
			astAlloc,
			statuses,
			path,
			immutable ParseStatus(immutable ParseStatus.Done(index)));
		addAll(modelAlloc, diags, parseDiagnostics(modelAlloc, index, parseDiags));
		return index;
	}

	return storage.withFile!(immutable FileIndex)(
		path,
		crowExtension,
		(ref immutable Opt!NulTerminatedStr opFileContent) {
			immutable FileAstAndArrDiagnosticAndLineAndColumnGetter parseResult =
				parseSingle(modelAlloc, astAlloc, allPaths, allSymbols, importedFrom, opFileContent);
			if (!empty(parseResult.diagnostics))
				return addFileIndex(
					AstAndResolvedImports.empty,
					parseResult.diagnostics,
					parseResult.lineAndColumnGetter);
			else {
				immutable Ptr!FileAst ast = parseResult.ast;
				immutable ImportAndExportPaths importsAndExports =
					resolveImportAndExportPaths(modelAlloc, astAlloc, allPaths, path, ast.imports, ast.exports);

				immutable(FileIndexAndNames[]) resolveImportsOrExports(
					ref immutable ResolvedImport[] importsOrExports,
				) {
					return mapImpure!FileIndexAndNames(
						modelAlloc,
						importsOrExports,
						(ref immutable ResolvedImport import_) {
							immutable FileIndex fi = () {
								if (has(import_.resolvedPath)) {
									immutable PathAndStorageKind resolvedPath = force(import_.resolvedPath);
									immutable Opt!ParseStatus parseStatus = getAt_mut(statuses, resolvedPath);
									if (has(parseStatus))
										return matchParseStatusImpure!(immutable FileIndex)(
											force(parseStatus),
											(ref immutable ParseStatus.Started) =>
												addFileIndex(
													AstAndResolvedImports.empty,
													arrLiteral!ParseDiagnostic(modelAlloc, [
														immutable ParseDiagnostic(
															import_.importedFrom,
															immutable ParseDiag(immutable ParseDiag.CircularImport(path, resolvedPath)))]),
													parseResult.lineAndColumnGetter),
											(ref immutable ParseStatus.Done it) =>
												it.fileIndex);
									else
										return parseRecur(
											modelAlloc,
											astAlloc,
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
					importsAndExports.parseDiags,
					parseResult.lineAndColumnGetter);
			}
		});
}

pure:

immutable(PathAndStorageKind) pathInInclude(ref AllPaths allPaths, scope immutable string name) {
	immutable Path crow = rootPath(allPaths, "crow");
	return immutable PathAndStorageKind(childPath(allPaths, crow, name), StorageKind.global);
}

immutable(PathAndStorageKind) pathInIncludePrivate(ref AllPaths allPaths, scope immutable string name) {
	immutable Path crow = rootPath(allPaths, "crow");
	immutable Path private_ = childPath(allPaths, crow, "private");
	return immutable PathAndStorageKind(childPath(allPaths, private_, name), StorageKind.global);
}

immutable(PathAndStorageKind) bootstrapPath(ref AllPaths allPaths) {
	return pathInIncludePrivate(allPaths, "bootstrap");
}

immutable(PathAndStorageKind) stdPath(ref AllPaths allPaths) {
	return pathInInclude(allPaths, "std");
}

immutable(PathAndStorageKind) allocPath(ref AllPaths allPaths) {
	return pathInIncludePrivate(allPaths, "alloc");
}

immutable(PathAndStorageKind) runtimePath(ref AllPaths allPaths) {
	return pathInIncludePrivate(allPaths, "runtime");
}

immutable(PathAndStorageKind) runtimeMainPath(ref AllPaths allPaths) {
	return pathInIncludePrivate(allPaths, "rt-main");
}

immutable(Diags) parseDiagnostics(
	ref Alloc modelAlloc,
	immutable FileIndex where,
	immutable ParseDiagnostic[] diags,
) {
	return map(modelAlloc, diags, (ref immutable ParseDiagnostic it) =>
		immutable Diagnostic(
			immutable FileAndRange(where, it.range),
			allocate(modelAlloc, immutable Diag(it.diag))));
}

alias LineAndColumnGettersBuilder = ArrBuilder!LineAndColumnGetter; // TODO: OrderedFullIndexDictBuilder?

immutable(FileAstAndArrDiagnosticAndLineAndColumnGetter) parseSingle(
	ref Alloc modelAlloc,
	ref Alloc astAlloc,
	ref AllPaths allPaths,
	ref AllSymbols allSymbols,
	immutable Opt!PathAndRange importedFrom,
	immutable Opt!NulTerminatedStr opFileContent,
) {
	immutable LineAndColumnGetter lcg = has(opFileContent)
		? lineAndColumnGetterForText(modelAlloc, strOfNulTerminatedStr(force(opFileContent)))
		: lineAndColumnGetterForEmptyFile(modelAlloc);

	// File content must go in astAlloc because we refer to strings without copying
	if (has(opFileContent)) {
		immutable NulTerminatedStr text = force(opFileContent);
		immutable FileAstAndParseDiagnostics result = parseFile(astAlloc, allPaths, allSymbols, text);
		return immutable FileAstAndArrDiagnosticAndLineAndColumnGetter(result.ast, result.diagnostics, lcg);
	} else
		return immutable FileAstAndArrDiagnosticAndLineAndColumnGetter(
			emptyFileAst,
			arrLiteral!ParseDiagnostic(modelAlloc, [
				immutable ParseDiagnostic(
					RangeWithinFile.empty,
					immutable ParseDiag(immutable ParseDiag.FileDoesNotExist(importedFrom)))]),
			lcg);
}

struct ResolvedImport {
	// This is arbitrarily the first module we saw to import this.
	// This is just used for error reporting in case the file can't be read.
	immutable RangeWithinFile importedFrom;
	immutable Opt!PathAndStorageKind resolvedPath;
	immutable Opt!(Sym[]) names;
}

struct ResolvedImportAndDiags {
	immutable ResolvedImport resolved;
	immutable ParseDiagnostic[] diags;
}

immutable(ResolvedImportAndDiags) tryResolveImport(
	ref Alloc modelAlloc,
	ref AllPaths allPaths,
	ref immutable PathAndStorageKind fromPath,
	immutable ImportAst ast,
) {
	immutable Opt!(Sym[]) names = mapOption!(Sym[], Sym[])(ast.names, (ref immutable Sym[] names) =>
		copyArr(modelAlloc, names));
	immutable(ResolvedImportAndDiags) resolved(immutable PathAndStorageKind pk) {
		return immutable ResolvedImportAndDiags(
			immutable ResolvedImport(ast.range, some(pk), names),
			emptyArr!ParseDiagnostic);
	}
	return matchAbsOrRelPath!(immutable ResolvedImportAndDiags)(
		ast.path,
		(immutable Path global) =>
			resolved(immutable PathAndStorageKind(global, StorageKind.global)),
		(immutable RelPath relPath) {
			immutable Opt!Path rel = resolvePath(allPaths, parent(allPaths, fromPath.path), relPath);
			return has(rel)
				? resolved(immutable PathAndStorageKind(force(rel), fromPath.storageKind))
				: immutable ResolvedImportAndDiags(
					immutable ResolvedImport(ast.range, none!PathAndStorageKind, names),
					arrLiteral!ParseDiagnostic(modelAlloc, [
						immutable ParseDiagnostic(
							ast.range,
							immutable ParseDiag(ParseDiag.RelativeImportReachesPastRoot(relPath)))]));
		});
}

struct ImportAndExportPaths {
	immutable ResolvedImport[] imports;
	immutable ResolvedImport[] exports;
	immutable ParseDiagnostic[] parseDiags;
}

struct ResolvedImportsAndParseDiags {
	immutable ResolvedImport[] imports;
	immutable ParseDiagnostic[] parseDiags;
}

immutable(ResolvedImportsAndParseDiags) resolveImportOrExportPaths(
	ref Alloc modelAlloc,
	ref Alloc astAlloc,
	ref AllPaths allPaths,
	ref immutable PathAndStorageKind from,
	ref immutable Opt!ImportsOrExportsAst importsOrExports,
) {
	immutable ImportAst[] paths = has(importsOrExports) ? force(importsOrExports).paths : emptyArr!ImportAst;
	ArrBuilder!ParseDiagnostic diags;
	immutable ResolvedImport[] resolved = map(astAlloc, paths, (ref immutable ImportAst i) {
		immutable ResolvedImportAndDiags a = tryResolveImport(modelAlloc, allPaths, from, i);
		addAll(modelAlloc, diags, a.diags);
		return a.resolved;
	});
	return immutable ResolvedImportsAndParseDiags(resolved, finishArr(modelAlloc, diags));
}

immutable(ImportAndExportPaths) resolveImportAndExportPaths(
	ref Alloc modelAlloc,
	ref Alloc astAlloc,
	ref AllPaths allPaths,
	ref immutable PathAndStorageKind from,
	ref immutable Opt!ImportsOrExportsAst imports,
	ref immutable Opt!ImportsOrExportsAst exports,
) {
	immutable ResolvedImportsAndParseDiags resolvedImports =
		resolveImportOrExportPaths(modelAlloc, astAlloc, allPaths, from, imports);
	immutable ResolvedImportsAndParseDiags resolvedExports =
		resolveImportOrExportPaths(modelAlloc, astAlloc, allPaths, from, exports);
	return immutable ImportAndExportPaths(
		resolvedImports.imports,
		resolvedExports.imports,
		cat(modelAlloc, resolvedImports.parseDiags, resolvedExports.parseDiags));
}

struct AstAndResolvedImports {
	immutable Ptr!FileAst ast;
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
	ref immutable FullIndexDict!(FileIndex, Ptr!Module) compiled,
) {
	return mapOp(modelAlloc, paths, (ref immutable FileIndexAndNames it) =>
		it.fileIndex == FileIndex.none
			? none!ModuleAndNames
			: some(immutable ModuleAndNames(it.range, fullIndexDictGet(compiled, it.fileIndex), it.names)));
}

struct ModulesAndCommonTypes {
	immutable Ptr!Module[] modules;
	immutable Ptr!CommonTypes commonTypes;
}

immutable(ModulesAndCommonTypes) getModules(
	ref Alloc modelAlloc,
	ref AllSymbols allSymbols,
	ref ArrBuilder!Diagnostic diagsBuilder,
	ref ProgramState programState,
	immutable FileIndex stdIndex,
	ref immutable AstAndResolvedImports[] fileAsts,
) {
	Late!(immutable Ptr!CommonFuns) commonFuns = late!(immutable Ptr!CommonFuns);
	Late!(immutable Ptr!CommonTypes) commonTypes = late!(immutable Ptr!CommonTypes);
	immutable Ptr!Module[] modules = mapWithSoFar!(Ptr!Module)(
		modelAlloc,
		fileAsts,
		(ref immutable AstAndResolvedImports ast, ref immutable Ptr!Module[] soFar, immutable size_t index) {
			immutable FullIndexDict!(FileIndex, Ptr!Module) compiled =
				fullIndexDictOfArr!(FileIndex, Ptr!Module)(soFar);
			immutable PathAndAst pathAndAst = immutable PathAndAst(immutable FileIndex(safeSizeTToU16(index)), ast.ast);
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
					checkBootstrap(modelAlloc, allSymbols, diagsBuilder, programState, pathAndAst);
				lateSet(commonFuns, res.commonFuns);
				lateSet(commonTypes, res.commonTypes);
				return res.module_;
			}
		});
	return immutable ModulesAndCommonTypes(modules, lateGet(commonTypes));
}

immutable(Ptr!Program) checkEverything(
	ref Alloc modelAlloc,
	ref AllSymbols allSymbols,
	ref ArrBuilder!Diagnostic diagsBuilder,
	ref immutable AstAndResolvedImports[] allAsts,
	immutable Ptr!FilesInfo filesInfo,
	ref immutable CommonModuleIndices moduleIndices,
) {
	ProgramState programState = ProgramState(modelAlloc, allSymbols);
	immutable ModulesAndCommonTypes modulesAndCommonTypes =
		getModules(modelAlloc, allSymbols, diagsBuilder, programState, moduleIndices.std, allAsts);
	immutable Ptr!Module[] modules = modulesAndCommonTypes.modules;
	immutable Ptr!Module bootstrapModule = at(modules, moduleIndices.bootstrap.index);
	return allocate(modelAlloc, immutable Program(
		filesInfo,
		allocate(modelAlloc, immutable SpecialModules(
			at(modules, moduleIndices.alloc.index),
			bootstrapModule,
			at(modules, moduleIndices.runtime.index),
			at(modules, moduleIndices.runtimeMain.index),
			at(modules, moduleIndices.main.index))),
		modules,
		modulesAndCommonTypes.commonTypes,
		finishArr(modelAlloc, diagsBuilder)));
}
