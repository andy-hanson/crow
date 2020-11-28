module frontend.frontendCompile;

@safe @nogc nothrow: // not pure

import model.diag : Diag, Diags, Diagnostic, Diagnostics, FilesInfo;
import model.model :
	asStructDecl,
	CommonTypes,
	comparePathAndStorageKind,
	LineAndColumnGetters,
	Module,
	Program,
	SpecialModules,
	StructDecl,
	StructInst;
import model.parseDiag : ParseDiag, ParseDiagnostic;
import frontend.ast :
	emptyFileAst,
	exports,
	FileAst,
	ImportAst,
	imports,
	ImportsOrExportsAst;
import frontend.check : BootstrapCheck, check, checkBootstrapNz, ModuleAndNames, PathAndAst;
import frontend.instantiate : instantiateNonTemplateStruct;
import frontend.lang : nozeExtension;
import frontend.parse : FileAstAndParseDiagnostics, parseFile;
import frontend.programState : ProgramState;
import util.bools : Bool;
import util.collection.arr : Arr, at, empty, emptyArr, range;
import util.collection.arrBuilder : add, addAll, ArrBuilder, arrBuilderSize, finishArr;
import util.collection.arrUtil : arrLiteral, cat, copyArr, map, mapImpure, mapOrFailWithSoFar, prepend;
import util.collection.dict : mustGetAt;
import util.collection.fullIndexDict : FullIndexDict, fullIndexDictGet, fullIndexDictOfArr;
import util.collection.mutDict : getAt_mut, MutDict, setInDict;
import util.collection.mutIndexDict : mustGetAt;
import util.collection.str : NulTerminatedStr, stripNulTerminator;
import util.late : late, Late, lateGet, lateIsSet, lateSet;
import util.lineAndColumnGetter : LineAndColumnGetter, lineAndColumnGetterForEmptyFile, lineAndColumnGetterForText;
import util.memory : allocate, nu;
import util.opt : force, has, mapOption, Opt, none, some;
import util.path :
	copyPath,
	parent,
	Path,
	PathAndRange,
	PathAndStorageKind,
	RelPath,
	resolvePath,
	rootPath,
	StorageKind;
import util.ptr : Ptr;
import util.result :
	asSuccess,
	fail,
	isSuccess,
	mapFailure,
	mapSuccess,
	Result;
import util.sourceRange : FileAndRange, FileIndex, FilePaths, RangeWithinFile;
import util.sym : AllSymbols, shortSymAlphaLiteral, Sym;
import util.types : safeSizeTToU16;
import util.util : unreachable, verify;

immutable(Result!(Ptr!Program, Diagnostics)) frontendCompile(ModelAlloc, AstsAlloc, SymAlloc, ReadOnlyStorage)(
	ref ModelAlloc modelAlloc,
	ref AstsAlloc astsAlloc,
	ref AllSymbols!SymAlloc allSymbols,
	ref ReadOnlyStorage storage,
	immutable Ptr!Path mainPath,
) {
	immutable PathAndStorageKind main = PathAndStorageKind(mainPath, StorageKind.local);
	immutable ParsedEverything parsed = parseEverything(modelAlloc, allSymbols, storage, main, astsAlloc);
	immutable Ptr!FilesInfo filesInfo =
		nu!FilesInfo(
			modelAlloc,
			parsed.filePaths,
			allocate(modelAlloc, storage.absolutePathsGetter()),
			parsed.lineAndColumnGetters);
	immutable Result!(Ptr!Program, Diags) res = empty(parsed.diagnostics)
		? checkEverything(modelAlloc, allSymbols, parsed.asts, filesInfo, parsed.commonModuleIndices)
		: fail!(Ptr!Program, Diags)(parsed.diagnostics);
	return mapFailure!(Diagnostics, Ptr!Program, Diags)(res, (ref immutable Diags diagnostics) =>
		immutable Diagnostics(diagnostics, filesInfo));
}

private struct FileAstAndArrDiagnosticAndLineAndColumnGetter {
	immutable Ptr!FileAst ast;
	immutable Arr!ParseDiagnostic diagnostics;
	immutable LineAndColumnGetter lineAndColumnGetter;
}

struct FileAstAndDiagnostics {
	immutable FileAst ast;
	immutable Diagnostics diagnostics;
}

immutable(FileAstAndDiagnostics) parseSingleAst(Alloc, SymAlloc, ReadOnlyStorage)(
	ref Alloc alloc,
	ref AllSymbols!SymAlloc allSymbols,
	ref ReadOnlyStorage storage,
	immutable Ptr!Path path,
) {
	// In this case model alloc and AST alloc are the same
	immutable PathAndStorageKind pk = immutable PathAndStorageKind(path, StorageKind.local);
	return storage.withFile!(immutable FileAstAndDiagnostics)(
		pk,
		nozeExtension,
		(ref immutable Opt!NulTerminatedStr opFileContent) {
			immutable PathAndStorageKind pathAndStorageKind = immutable PathAndStorageKind(path, StorageKind.local);
			immutable FileAstAndArrDiagnosticAndLineAndColumnGetter res = parseSingle!(Alloc, Alloc, SymAlloc)(
				alloc,
				alloc,
				allSymbols,
				none!PathAndRange,
				opFileContent);
			immutable LineAndColumnGetters lc =
				fullIndexDictOfArr!(FileIndex, LineAndColumnGetter)(
					arrLiteral!LineAndColumnGetter(alloc, [res.lineAndColumnGetter]));
			immutable FilePaths filePaths = fullIndexDictOfArr!(FileIndex, PathAndStorageKind)(
				arrLiteral!PathAndStorageKind(alloc, [pathAndStorageKind]));
			return immutable FileAstAndDiagnostics(
				res.ast,
				immutable Diagnostics(
					parseDiagnostics(alloc, immutable FileIndex(0), res.diagnostics),
					immutable FilesInfo(filePaths, allocate(alloc, storage.absolutePathsGetter()), lc)));
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
	immutable Arr!AstAndResolvedImports asts;
	immutable Diags diagnostics;
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
immutable(ParsedEverything) parseEverything(ModelAlloc, AstAlloc, SymAlloc, ReadOnlyStorage)(
	ref ModelAlloc modelAlloc,
	ref AllSymbols!SymAlloc allSymbols,
	ref ReadOnlyStorage storage,
	ref immutable PathAndStorageKind mainPath,
	ref AstAlloc astAlloc,
) {
	LineAndColumnGettersBuilder lineAndColumnGetters;
	ArrBuilder!AstAndResolvedImports res;
	ArrBuilder!PathAndStorageKind fileIndexToPath;
	PathToStatus statuses;
	ArrBuilder!Diagnostic diagnostics;

	immutable PathAndStorageKind bootstrapPath = bootstrapPath(modelAlloc);
	immutable PathAndStorageKind stdPath = stdPath(modelAlloc);
	immutable PathAndStorageKind runtimePath = runtimePath(modelAlloc);
	immutable PathAndStorageKind runtimeMainPath = runtimeMainPath(modelAlloc);
	immutable(FileIndex) parsePath(immutable PathAndStorageKind path) {
		immutable Opt!ParseStatus parseStatus = getAt_mut(statuses, path);
		if (has(parseStatus)) {
			return matchParseStatusImpure!(immutable FileIndex)(
				force(parseStatus),
				(ref immutable ParseStatus.Started) =>
					unreachable!(immutable FileIndex),
				(ref immutable ParseStatus.Done it) =>
					it.fileIndex);
		} else
			return parseRecur!(ModelAlloc, AstAlloc, SymAlloc)(
				modelAlloc,
				astAlloc,
				allSymbols,
				storage,
				lineAndColumnGetters,
				res,
				fileIndexToPath,
				diagnostics,
				statuses,
				none!PathAndRange,
				path);
	}
	immutable FileIndex bootstrapIndex = parsePath(bootstrapPath);
	immutable FileIndex allocIndex = parsePath(allocPath(modelAlloc));
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
		finishArr(astAlloc, res),
		finishArr(modelAlloc, diagnostics));
}

immutable(FileIndex) parseRecur(ModelAlloc, AstAlloc, SymAlloc, ReadOnlyStorage)(
	ref ModelAlloc modelAlloc,
	ref AstAlloc astAlloc,
	ref AllSymbols!SymAlloc allSymbols,
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
		immutable Arr!ParseDiagnostic parseDiags,
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
		nozeExtension,
		(ref immutable Opt!NulTerminatedStr opFileContent) {
			immutable FileAstAndArrDiagnosticAndLineAndColumnGetter parseResult =
				parseSingle(modelAlloc, astAlloc, allSymbols, importedFrom, opFileContent);
			if (!empty(parseResult.diagnostics))
				return addFileIndex(
					AstAndResolvedImports.empty,
					parseResult.diagnostics,
					parseResult.lineAndColumnGetter);
			else {
				immutable Ptr!FileAst ast = parseResult.ast;
				immutable ImportAndExportPaths importsAndExports =
					resolveImportAndExportPaths(modelAlloc, astAlloc, path, ast.imports, ast.exports);

				immutable(Arr!FileIndexAndNames) resolveImportsOrExports(
					ref immutable Arr!ResolvedImport importsOrExports,
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
															immutable ParseDiag(
																nu!(ParseDiag.CircularImport)(
																	modelAlloc,
																	path,
																	resolvedPath)))]),
													parseResult.lineAndColumnGetter),
											(ref immutable ParseStatus.Done it) =>
												it.fileIndex);
									else
										return parseRecur!(ModelAlloc, AstAlloc, SymAlloc)(
											modelAlloc,
											astAlloc,
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
							return immutable FileIndexAndNames(fi, import_.importedFrom, import_.names);
						});
				}
				immutable Arr!FileIndexAndNames resolvedImports = resolveImportsOrExports(importsAndExports.imports);
				immutable Arr!FileIndexAndNames resolvedExports = resolveImportsOrExports(importsAndExports.exports);
				return addFileIndex(
					immutable AstAndResolvedImports(ast, path.storageKind, resolvedImports, resolvedExports),
					importsAndExports.parseDiags,
					parseResult.lineAndColumnGetter);
			}
		});
}

pure:

immutable(PathAndStorageKind) pathInInclude(Alloc)(ref Alloc alloc, immutable Sym name) {
	return PathAndStorageKind(rootPath(alloc, name), StorageKind.global);
}

immutable(PathAndStorageKind) bootstrapPath(Alloc)(ref Alloc alloc) {
	return pathInInclude(alloc, shortSymAlphaLiteral("bootstrap"));
}

immutable(PathAndStorageKind) stdPath(Alloc)(ref Alloc alloc) {
	return pathInInclude(alloc, shortSymAlphaLiteral("std"));
}

immutable(PathAndStorageKind) allocPath(Alloc)(ref Alloc alloc) {
	return pathInInclude(alloc, shortSymAlphaLiteral("alloc"));
}

immutable(PathAndStorageKind) runtimePath(Alloc)(ref Alloc alloc) {
	return pathInInclude(alloc, shortSymAlphaLiteral("runtime"));
}

immutable(PathAndStorageKind) runtimeMainPath(Alloc)(ref Alloc alloc) {
	return pathInInclude(alloc, shortSymAlphaLiteral("rt-main"));
}

immutable(Diags) parseDiagnostics(Alloc)(
	ref Alloc modelAlloc,
	immutable FileIndex where,
	immutable Arr!ParseDiagnostic diags,
) {
	return map(modelAlloc, diags, (ref immutable ParseDiagnostic it) =>
		immutable Diagnostic(
			immutable FileAndRange(where, it.range),
			nu!Diag(modelAlloc, allocate(modelAlloc, it.diag))));
}

alias LineAndColumnGettersBuilder = ArrBuilder!LineAndColumnGetter; // TODO: OrderedFullIndexDictBuilder?

immutable(FileAstAndArrDiagnosticAndLineAndColumnGetter) parseSingle(ModelAlloc, AstAlloc, SymAlloc)(
	ref ModelAlloc modelAlloc,
	ref AstAlloc astAlloc,
	ref AllSymbols!SymAlloc allSymbols,
	immutable Opt!PathAndRange importedFrom,
	immutable Opt!NulTerminatedStr opFileContent,
) {
	immutable LineAndColumnGetter lcg = has(opFileContent)
		? lineAndColumnGetterForText(modelAlloc, stripNulTerminator(force(opFileContent)))
		: lineAndColumnGetterForEmptyFile(modelAlloc);

	// File content must go in astAlloc because we refer to strings without copying
	if (has(opFileContent)) {
		immutable NulTerminatedStr text = opFileContent.force;
		immutable FileAstAndParseDiagnostics result = parseFile(astAlloc, allSymbols, text);
		return immutable FileAstAndArrDiagnosticAndLineAndColumnGetter(result.ast, result.diagnostics, lcg);
	} else
		return immutable FileAstAndArrDiagnosticAndLineAndColumnGetter(
			emptyFileAst,
			arrLiteral!ParseDiagnostic(modelAlloc, [
				immutable ParseDiagnostic(
					RangeWithinFile.empty,
					immutable ParseDiag(nu!(ParseDiag.FileDoesNotExist)(modelAlloc, importedFrom)))]),
			lcg);
}

struct ResolvedImport {
	// This is arbitrarily the first module we saw to import this.
	// This is just used for error reporting in case the file can't be read.
	immutable RangeWithinFile importedFrom;
	immutable Opt!PathAndStorageKind resolvedPath;
	immutable Opt!(Arr!Sym) names;
}

struct ResolvedImportAndDiags {
	immutable ResolvedImport resolved;
	immutable Arr!ParseDiagnostic diags;
}

immutable(ResolvedImportAndDiags) tryResolveImport(Alloc)(
	ref Alloc modelAlloc,
	ref immutable PathAndStorageKind fromPath,
	immutable ImportAst ast,
) {
	immutable Ptr!Path path = copyPath(modelAlloc, ast.path); // TODO: shouldn't be necessary to copy?
	immutable Opt!(Arr!Sym) names = mapOption(ast.names, (ref immutable Arr!Sym names) =>
		copyArr(modelAlloc, names));
	immutable(ResolvedImportAndDiags) resolved(immutable PathAndStorageKind pk) {
		return immutable ResolvedImportAndDiags(
			immutable ResolvedImport(ast.range, some(pk), names),
			emptyArr!ParseDiagnostic);
	}
	if (ast.nDots == 0)
		return resolved(immutable PathAndStorageKind(path, StorageKind.global));
	else {
		immutable RelPath relPath = immutable RelPath(cast(ubyte) (ast.nDots - 1), path);
		immutable Opt!(Ptr!Path) rel = resolvePath(modelAlloc, fromPath.path.parent, relPath);
		return has(rel)
			? resolved(immutable PathAndStorageKind(force(rel), fromPath.storageKind))
			: immutable ResolvedImportAndDiags(
				immutable ResolvedImport(ast.range, none!PathAndStorageKind, names),
				arrLiteral!ParseDiagnostic(modelAlloc, [
					immutable ParseDiagnostic(
						ast.range,
						immutable ParseDiag(ParseDiag.RelativeImportReachesPastRoot(relPath)))]));
	}
}

struct ImportAndExportPaths {
	immutable Arr!ResolvedImport imports;
	immutable Arr!ResolvedImport exports;
	immutable Arr!ParseDiagnostic parseDiags;
}

struct ResolvedImportsAndParseDiags {
	immutable Arr!ResolvedImport imports;
	immutable Arr!ParseDiagnostic parseDiags;
}

immutable(ResolvedImportsAndParseDiags) resolveImportOrExportPaths(ModelAlloc, AstAlloc)(
	ref ModelAlloc modelAlloc,
	ref AstAlloc astAlloc,
	ref immutable PathAndStorageKind from,
	ref immutable Opt!ImportsOrExportsAst importsOrExports,
) {
	immutable Arr!ImportAst paths = has(importsOrExports) ? force(importsOrExports).paths : emptyArr!ImportAst;
	ArrBuilder!ParseDiagnostic diags;
	immutable Arr!ResolvedImport resolved = map(astAlloc, paths, (ref immutable ImportAst i) {
		immutable ResolvedImportAndDiags a = tryResolveImport(modelAlloc, from, i);
		addAll(modelAlloc, diags, a.diags);
		return a.resolved;
	});
	return immutable ResolvedImportsAndParseDiags(resolved, finishArr(modelAlloc, diags));
}

immutable(ImportAndExportPaths) resolveImportAndExportPaths(ModelAlloc, AstAlloc)(
	ref ModelAlloc modelAlloc,
	ref AstAlloc astAlloc,
	ref immutable PathAndStorageKind from,
	ref immutable Opt!ImportsOrExportsAst imports,
	ref immutable Opt!ImportsOrExportsAst exports,
) {
	immutable ResolvedImportsAndParseDiags resolvedImports =
		resolveImportOrExportPaths(modelAlloc, astAlloc, from, imports);
	immutable ResolvedImportsAndParseDiags resolvedExports =
		resolveImportOrExportPaths(modelAlloc, astAlloc, from, exports);
	return immutable ImportAndExportPaths(
		resolvedImports.imports,
		resolvedExports.imports,
		cat(modelAlloc, resolvedImports.parseDiags, resolvedExports.parseDiags));
}

struct AstAndResolvedImports {
	immutable Ptr!FileAst ast;
	immutable StorageKind storageKind; // Needed to determine which are in 'include'
	immutable Arr!FileIndexAndNames resolvedImports;
	immutable Arr!FileIndexAndNames resolvedExports;

	static immutable AstAndResolvedImports empty = immutable AstAndResolvedImports(
		emptyFileAst,
		StorageKind.global,
		emptyArr!FileIndexAndNames,
		emptyArr!FileIndexAndNames);
}

struct FileIndexAndNames {
	immutable FileIndex fileIndex;
	immutable RangeWithinFile range;
	immutable Opt!(Arr!Sym) names;
}

//TODO:INLINE
immutable(Arr!ModuleAndNames) mapImportsOrExports(ModelAlloc)(
	ref ModelAlloc modelAlloc,
	ref immutable Arr!FileIndexAndNames paths,
	ref immutable FullIndexDict!(FileIndex, Ptr!Module) compiled,
) {
	return map(modelAlloc, paths, (ref immutable FileIndexAndNames it) =>
		immutable ModuleAndNames(fullIndexDictGet(compiled, it.fileIndex), it.range, it.names));
}

struct ModulesAndCommonTypes {
	immutable Arr!(Ptr!Module) modules;
	immutable Ptr!CommonTypes commonTypes;
}

// Result does not include the 'bootstrap' module.
immutable(Result!(ModulesAndCommonTypes, Diags)) getModules(ModelAlloc, SymAlloc)(
	ref ModelAlloc modelAlloc,
	ref AllSymbols!SymAlloc allSymbols,
	ref ProgramState programState,
	immutable FileIndex stdIndex,
	ref immutable Arr!AstAndResolvedImports fileAsts,
) {
	Late!(immutable Ptr!CommonTypes) commonTypes = late!(immutable Ptr!CommonTypes);
	immutable Result!(Arr!(Ptr!Module), Diags) res = mapOrFailWithSoFar!(Ptr!Module, Diags)(
		modelAlloc,
		fileAsts,
		(ref immutable AstAndResolvedImports ast, ref immutable Arr!(Ptr!Module) soFar, immutable size_t index) {
			immutable FullIndexDict!(FileIndex, Ptr!Module) compiled =
				fullIndexDictOfArr!(FileIndex, Ptr!Module)(soFar);
			immutable PathAndAst pathAndAst = immutable PathAndAst(immutable FileIndex(safeSizeTToU16(index)), ast.ast);
			if (lateIsSet(commonTypes)) {
				immutable Bool isInInclude = Bool(ast.storageKind == StorageKind.global);
				immutable Arr!FileIndexAndNames allImports = isInInclude
					? ast.resolvedImports
					: prepend(
						modelAlloc,
						immutable FileIndexAndNames(stdIndex, RangeWithinFile.empty, none!(Arr!Sym)),
						ast.resolvedImports);
				immutable Arr!ModuleAndNames mappedImports =
					mapImportsOrExports(modelAlloc, allImports, compiled);
				immutable Arr!ModuleAndNames mappedExports =
					mapImportsOrExports(modelAlloc, ast.resolvedExports, compiled);
				return check(
					modelAlloc,
					allSymbols,
					programState,
					mappedImports,
					mappedExports,
					pathAndAst,
					lateGet(commonTypes));
			} else {
				// The first module to check is always 'bootstrap.nz'
				verify(ast.resolvedImports.empty);
				immutable Result!(BootstrapCheck, Diags) res =
					checkBootstrapNz(modelAlloc, allSymbols, programState, pathAndAst);
				if (res.isSuccess)
					lateSet(commonTypes, res.asSuccess.commonTypes);
				return mapSuccess(res, (ref immutable BootstrapCheck c) => c.module_);
			}
		});
	return mapSuccess!(ModulesAndCommonTypes, Arr!(Ptr!Module), Diags)(
		res,
		(ref immutable Arr!(Ptr!Module) modules) => immutable ModulesAndCommonTypes(modules, lateGet(commonTypes)));
}

immutable(Result!(Ptr!Program, Diags)) checkEverything(ModelAlloc, SymAlloc)(
	ref ModelAlloc modelAlloc,
	ref AllSymbols!SymAlloc allSymbols,
	ref immutable Arr!AstAndResolvedImports allAsts,
	immutable Ptr!FilesInfo filesInfo,
	ref immutable CommonModuleIndices moduleIndices,
) {
	ProgramState programState = ProgramState(modelAlloc);
	immutable Result!(ModulesAndCommonTypes, Diags) modulesResult =
		getModules(modelAlloc, allSymbols, programState, moduleIndices.std, allAsts);
	return modulesResult.mapSuccess((ref immutable ModulesAndCommonTypes modulesAndCommonTypes) {
		immutable Arr!(Ptr!Module) modules = modulesAndCommonTypes.modules;
		immutable Ptr!Module bootstrapModule = at(modules, moduleIndices.bootstrap.index);
		immutable Ptr!StructDecl ctxStructDecl =
			mustGetAt(bootstrapModule.structsAndAliasesMap, shortSymAlphaLiteral("ctx")).asStructDecl;
		immutable Ptr!StructInst ctxStructInst = instantiateNonTemplateStruct(modelAlloc, programState, ctxStructDecl);
		return nu!Program(
			modelAlloc,
			filesInfo,
			nu!SpecialModules(
				modelAlloc,
				at(modules, moduleIndices.alloc.index),
				bootstrapModule,
				at(modules, moduleIndices.runtime.index),
				at(modules, moduleIndices.runtimeMain.index),
				at(modules, moduleIndices.main.index)),
			modules,
			modulesAndCommonTypes.commonTypes,
			ctxStructInst);
	});
}

