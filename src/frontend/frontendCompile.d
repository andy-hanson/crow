module frontend.frontendCompile;

@safe @nogc nothrow: // not pure

import diag : Diag, Diags, Diagnostic, Diagnostics, FilesInfo;

import model :
	AbsolutePathsGetter,
	asStructDecl,
	CommonTypes,
	comparePathAndStorageKind,
	LineAndColumnGetters,
	Module,
	pathAndStorageKindEq,
	Program,
	StructDecl,
	StructInst;
import parseDiag : ParseDiag, ParseDiagnostic;

import frontend.ast :
	emptyFileAst,
	exports,
	FileAst,
	ImportAst,
	imports,
	ImportsOrExportsAst,
	specs,
	structAliases,
	structs;
import frontend.check : BootstrapCheck, check, checkBootstrapNz, PathAndAst;
import frontend.instantiate : instantiateNonTemplateStruct;
import frontend.lang : nozeExtension;
import frontend.parse : FileAstAndParseDiagnostics, parseFile;
import frontend.programState : ProgramState;
import frontend.readOnlyStorage : absolutePathsGetter, choose, ReadOnlyStorage, ReadOnlyStorages, tryReadFile;

import util.alloc.stackAlloc : StackAlloc;
import util.bools : Bool;
import util.collection.arr : Arr, at, empty, emptyArr, range, size;
import util.collection.arrBuilder : add, addAll, ArrBuilder, arrBuilderSize, finishArr;
import util.collection.arrUtil : arrLiteral, cat, find, map, mapOrFail, mapOrFailImpure, mapOrFailWithSoFar, prepend;
import util.collection.dict : mustGetAt;
import util.collection.dictBuilder : addToDict, DictBuilder, finishDictShouldBeNoConflict;
import util.collection.fullIndexDict : FullIndexDict, fullIndexDictGet, fullIndexDictOfArr;
import util.collection.mutDict :
	addToMutDict,
	getAt_mut,
	getOrAddAndDidAdd,
	hasKey_mut,
	mustGetAt_mut,
	MutDict,
	mutDictSize,
	setInDict,
	ValueAndDidAdd;
import util.collection.mutIndexDict : addToMutIndexDict, mustGetAt, MutIndexDict, newMutIndexDict;
import util.collection.mutFullIndexDict : MutFullIndexDict, mutFullIndexDictGet, mutFullIndexDictSet;
import util.collection.str : NulTerminatedStr, Str, stripNulTerminator, strLiteral;
import util.late : late, Late, lateGet, lateIsSet, lateSet;
import util.lineAndColumnGetter : LineAndColumnGetter, lineAndColumnGetterForEmptyFile, lineAndColumnGetterForText;
import util.opt : force, has, Opt, optOr, none, some;
import util.path :
	baseName,
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
	flatMapSuccess,
	isSuccess,
	joinResults,
	mapFailure,
	mapSuccess,
	matchResult,
	matchResultImpure,
	Result,
	success;
import util.sourceRange : FileAndRange, FileIndex, FilePaths, RangeWithinFile;
import util.sym : AllSymbols, shortSymAlphaLiteral, Sym;
import util.types : safeSizeTToU16;
import util.util : unreachable, verify;

immutable(Result!(Program, Diagnostics)) frontendCompile(ModelAlloc, SymAlloc)(
	ref ModelAlloc modelAlloc,
	ref AllSymbols!SymAlloc allSymbols,
	ReadOnlyStorages storages,
	immutable Ptr!Path mainPath,
) {
	StackAlloc!("asts", 4 * 1024 * 1024) astsAlloc;

	immutable PathAndStorageKind main = PathAndStorageKind(mainPath, StorageKind.local);
	immutable ParsedEverything parsed = parseEverything(modelAlloc, allSymbols, storages, main, astsAlloc);
	immutable FilesInfo filesInfo =
		immutable FilesInfo(parsed.filePaths, storages.absolutePathsGetter, parsed.lineAndColumnGetters);
	immutable Result!(Program, Diags) res = empty(parsed.diagnostics)
		? checkEverything(modelAlloc, parsed.asts, filesInfo, parsed.commonModuleIndices)
		: fail!(Program, Diags)(parsed.diagnostics);
	return mapFailure!(Diagnostics, Program, Diags)(res, (ref immutable Diags diagnostics) =>
		immutable Diagnostics(diagnostics, filesInfo));
}

struct FileAstAndArrDiagnostic {
	immutable FileAst ast;
	immutable Arr!ParseDiagnostic diagnostics;
}

struct FileAstAndDiagnostics {
	immutable FileAst ast;
	immutable Diagnostics diagnostics;
}

immutable(FileAstAndDiagnostics) parseSingleAst(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref AllSymbols!SymAlloc allSymbols,
	ref ReadOnlyStorages storages,
	immutable Ptr!Path path,
) {
	StackAlloc!("single file", 1024 * 1024) fileAlloc;
	LineAndColumnGettersBuilder lineAndColumnGetters;
	// In this case model alloc and AST alloc are the same
	immutable Opt!NulTerminatedStr opFileContent =
		getFile(fileAlloc, PathAndStorageKind(path, StorageKind.local), storages);
	immutable PathAndStorageKind pathAndStorageKind = immutable PathAndStorageKind(path, StorageKind.local);
	immutable FileAstAndArrDiagnostic res = parseSingle!(Alloc, Alloc, SymAlloc)(
		alloc,
		alloc,
		allSymbols,
		none!PathAndRange,
		lineAndColumnGetters,
		opFileContent);
	immutable LineAndColumnGetters lc =
		fullIndexDictOfArr!(FileIndex, LineAndColumnGetter)(finishArr(alloc, lineAndColumnGetters));
	immutable FilePaths filePaths =
		fullIndexDictOfArr!(FileIndex, PathAndStorageKind)(arrLiteral!PathAndStorageKind(alloc, pathAndStorageKind));
	return immutable FileAstAndDiagnostics(
		res.ast,
		immutable Diagnostics(
			parseDiagnostics(alloc, immutable FileIndex(0), res.diagnostics),
			immutable FilesInfo(filePaths, storages.absolutePathsGetter, lc)));
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

alias MutPathToFileIndex = MutDict!(PathAndStorageKind, FileIndex, comparePathAndStorageKind);
alias FileToStatus = MutDict!(PathAndStorageKind, ParseStatus, comparePathAndStorageKind);

struct ParsedEverything {
	immutable FilePaths filePaths;
	immutable LineAndColumnGetters lineAndColumnGetters;
	immutable CommonModuleIndices commonModuleIndices;
	immutable Arr!PathAndAstAndResolvedImports asts;
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
immutable(ParsedEverything) parseEverything(ModelAlloc, AstAlloc, SymAlloc)(
	ref ModelAlloc modelAlloc,
	ref AllSymbols!SymAlloc allSymbols,
	ref ReadOnlyStorages storages,
	immutable PathAndStorageKind mainPath,
	ref AstAlloc astAlloc,
) {
	LineAndColumnGettersBuilder lineAndColumnGetters;
	ArrBuilder!PathAndAstAndResolvedImports res;
	MutPathToFileIndex pathToFileIndex;
	ArrBuilder!PathAndStorageKind fileIndexToPath;
	FileToStatus statuses;
	ArrBuilder!Diagnostic diagnostics;

	immutable PathAndStorageKind bootstrapPath = bootstrapPath(modelAlloc);
	immutable PathAndStorageKind stdPath = stdPath(modelAlloc);
	immutable PathAndStorageKind runtimePath = runtimePath(modelAlloc);
	immutable PathAndStorageKind runtimeMainPath = runtimeMainPath(modelAlloc);
	immutable Arr!PathAndStorageKind rootPaths = arrLiteral!PathAndStorageKind(
		astAlloc,
		// Ensure bootstrap.nz is parsed first
		bootstrapPath,
		// Ensure std.nz is available
		stdPath,
		runtimePath,
		runtimeMainPath,
		mainPath);
	//TODO: use mapOfFail here to get the file indices
	foreach (immutable PathAndStorageKind path; range(rootPaths)) {
		immutable Opt!ParseStatus parseStatus = getAt_mut(statuses, path);
		if (has(parseStatus)) {
			matchParseStatusImpure!void(
				force(parseStatus),
				(ref immutable ParseStatus.Started) { unreachable!void(); },
				(ref immutable ParseStatus.Done) {});
		} else {
			immutable Result!(FileIndex, Diags) err = parseRecur(
				modelAlloc,
				astAlloc,
				allSymbols,
				storages,
				lineAndColumnGetters,
				res,
				pathToFileIndex,
				fileIndexToPath,
				statuses,
				none!PathAndRange,
				path);
			matchResult!(void, FileIndex, Diags)(
				err,
				(ref immutable FileIndex) {},
				(ref immutable Diags d) {
					addAll(modelAlloc, diagnostics, d);
				});
		}
	}
	immutable(FileIndex) getIndex(immutable PathAndStorageKind path) {
		return getFileIndex(modelAlloc, pathToFileIndex, fileIndexToPath, path);
	}
	immutable CommonModuleIndices commonModuleIndices = immutable CommonModuleIndices(
		getIndex(allocPath(modelAlloc)),
		getIndex(bootstrapPath),
		getIndex(mainPath),
		getIndex(runtimePath),
		getIndex(runtimeMainPath),
		getIndex(stdPath),
	);
	return immutable ParsedEverything(
		fullIndexDictOfArr!(FileIndex, PathAndStorageKind)(finishArr(modelAlloc, fileIndexToPath)),
		fullIndexDictOfArr!(FileIndex, LineAndColumnGetter)(finishArr(modelAlloc, lineAndColumnGetters)),
		commonModuleIndices,
		finishArr(astAlloc, res),
		finishArr(modelAlloc, diagnostics));
}

immutable(Opt!NulTerminatedStr) getFile(Alloc)(
	ref Alloc fileAlloc,
	immutable PathAndStorageKind pk,
	ref ReadOnlyStorages storages,
) {
	return storages.choose(pk.storageKind).tryReadFile(fileAlloc, pk.path, nozeExtension);
}

//TODO: Diags is an array, just use empty array instead of none?
immutable(Result!(FileIndex, Diags)) parseRecur(ModelAlloc, AstAlloc, SymAlloc)(
	ref ModelAlloc modelAlloc,
	ref AstAlloc astAlloc,
	ref AllSymbols!SymAlloc allSymbols,
	ref ReadOnlyStorages storages,
	ref LineAndColumnGettersBuilder lineAndColumnGetters,
	ref ArrBuilder!PathAndAstAndResolvedImports res,
	ref MutPathToFileIndex pathToFileIndex,
	ref ArrBuilder!PathAndStorageKind fileIndexToPath,
	ref FileToStatus statuses,
	immutable Opt!PathAndRange importedFrom,
	immutable PathAndStorageKind path,
) {
	setInDict(astAlloc, statuses, path, immutable ParseStatus(immutable ParseStatus.Started()));

	// We only add the file index when all dependencies are processed.
	// That way when we process files in index order, all dependencies will be ready.
	immutable(FileIndex) addFileIndex() {
		immutable FileIndex index = immutable FileIndex(safeSizeTToU16(arrBuilderSize(fileIndexToPath)));
		addToMutDict(modelAlloc, pathToFileIndex, path, index);
		add(modelAlloc, fileIndexToPath, path);
		return index;
	}

	immutable Opt!NulTerminatedStr opFileContent = getFile(astAlloc, path, storages);
	immutable FileAstAndArrDiagnostic parseResult =
		parseSingle(modelAlloc, astAlloc, allSymbols, importedFrom, lineAndColumnGetters, opFileContent);
	if (!empty(parseResult.diagnostics)) {
		immutable FileIndex index = addFileIndex();
		return fail!(FileIndex, Diags)(parseDiagnostics(modelAlloc, index, parseResult.diagnostics));
	} else {
		immutable FileAst ast = parseResult.ast;
		immutable Result!(ImportAndExportPaths, Arr!ParseDiagnostic) importsResult = resolveImportsAndExports(
			modelAlloc,
			astAlloc,
			path,
			pathToFileIndex,
			fileIndexToPath,
			ast.imports,
			ast.exports);
		return matchResultImpure(
			importsResult,
			(ref immutable ImportAndExportPaths importsAndExports) {
				// Ensure all imports are added before adding this
				immutable(Result!(Arr!FileIndex, Diags)) resolveImportsOrExports(
					ref immutable Arr!ResolvedImport importsOrExports,
				) {
					return mapOrFailImpure!(FileIndex, Diags, ResolvedImport)(
						modelAlloc,
						importsOrExports,
						(ref immutable ResolvedImport import_) {
							immutable Opt!ParseStatus parseStatus = getAt_mut(statuses, import_.resolvedPath);
							if (has(parseStatus))
								return matchParseStatusImpure!(immutable Result!(FileIndex, Diags))(
									force(parseStatus),
									(ref immutable ParseStatus.Started) {
										immutable FileIndex index = addFileIndex();
										return fail!(FileIndex, Diags)(arrLiteral!Diagnostic(modelAlloc,
											immutable Diagnostic(
												immutable FileAndRange(index, import_.importedFrom),
												immutable Diag(Diag.CircularImport(path, import_.resolvedPath)))));
									},
									(ref immutable ParseStatus.Done it) {
										return success!(FileIndex, Diags)(it.fileIndex);
									});
							else
								return parseRecur(
									modelAlloc,
									astAlloc,
									allSymbols,
									storages,
									lineAndColumnGetters,
									res,
									pathToFileIndex,
									fileIndexToPath,
									statuses,
									some(immutable PathAndRange(path, import_.importedFrom)),
									import_.resolvedPath);
						});
				}
				immutable Result!(Arr!FileIndex, Diags) resolvedImports =
					resolveImportsOrExports(importsAndExports.imports);
				immutable Result!(Arr!FileIndex, Diags) resolvedExports =
					resolveImportsOrExports(importsAndExports.exports);
				return joinResults(
					resolvedImports,
					resolvedExports,
					(ref immutable Arr!FileIndex importIndices, ref immutable Arr!FileIndex exportIndices) {
						immutable FileIndex fileIndex = addFileIndex();
						verify(fileIndex.index == arrBuilderSize(res));
						immutable PathAndAstAndResolvedImports pa = immutable PathAndAstAndResolvedImports(
							path.storageKind,
							ast,
							importIndices,
							exportIndices);
						add(astAlloc, res, pa);
						setInDict(
							astAlloc,
							statuses,
							path,
							immutable ParseStatus(immutable ParseStatus.Done(fileIndex)));
						return fileIndex;
					});
			},
			(ref immutable Arr!ParseDiagnostic d) {
				immutable FileIndex index = addFileIndex();
				return fail!(FileIndex, Diags)(parseDiagnostics(modelAlloc, index, d));
			});
	}
}

immutable(Arr!PathAndStorageKind) stripRange(Alloc)(ref Alloc alloc, immutable Arr!ResolvedImport a) {
	return map(alloc, a, (ref immutable ResolvedImport i) => i.resolvedPath);
}

pure:

immutable(FileIndex) getFileIndex(ModelAlloc)(
	ref ModelAlloc modelAlloc,
	ref MutPathToFileIndex pathToFileIndex,
	//TODO:FullIndexDictBuilder that appends to end
	ref ArrBuilder!PathAndStorageKind fileToPath,
	ref immutable PathAndStorageKind path,
) {
	immutable ValueAndDidAdd!FileIndex v = getOrAddAndDidAdd(
		modelAlloc, pathToFileIndex, path, () => FileIndex(safeSizeTToU16(1 + mutDictSize(pathToFileIndex))));
	if (v.didAdd)
		add(modelAlloc, fileToPath, path);
	return v.value;
}

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
		immutable Diagnostic(immutable FileAndRange(where, it.range), immutable Diag(it.diag)));
}

alias LineAndColumnGettersBuilder = ArrBuilder!LineAndColumnGetter; // TODO: OrderedFullIndexDictBuilder?

void addEmptyLineAndColumnGetter(Alloc)(
	ref Alloc alloc,
	ref LineAndColumnGettersBuilder lineAndColumnGetters,
	immutable PathAndStorageKind where,
) {
	// Even a non-existent path needs LineAndColumnGetter since that's where the diagnostic is
	addToDict(alloc, lineAndColumnGetters, where, lineAndColumnGetterForEmptyFile(alloc));
}

immutable(FileAstAndArrDiagnostic) parseSingle(ModelAlloc, AstAlloc, SymAlloc)(
	ref ModelAlloc modelAlloc,
	ref AstAlloc astAlloc,
	ref AllSymbols!SymAlloc allSymbols,
	immutable Opt!PathAndRange importedFrom,
	ref LineAndColumnGettersBuilder lineAndColumnGetters,
	immutable Opt!NulTerminatedStr opFileContent,
) {
	add(modelAlloc, lineAndColumnGetters, has(opFileContent)
		? lineAndColumnGetterForText(modelAlloc, stripNulTerminator(force(opFileContent)))
		: lineAndColumnGetterForEmptyFile(modelAlloc));

	// File content must go in astAlloc because we refer to strings without copying
	if (has(opFileContent)) {
		immutable NulTerminatedStr text = opFileContent.force;
		immutable FileAstAndParseDiagnostics result = parseFile(astAlloc, allSymbols, text);
		return immutable FileAstAndArrDiagnostic(result.ast, result.diagnostics);
	} else
		return immutable FileAstAndArrDiagnostic(emptyFileAst, arrLiteral!ParseDiagnostic(
			modelAlloc,
			immutable ParseDiagnostic(
				RangeWithinFile.empty,
				immutable ParseDiag(ParseDiag.FileDoesNotExist(importedFrom)))));
}

struct ResolvedImport {
	// This is arbitrarily the first module we saw to import this.
	// This is just used for error reporting in case the file can't be read.
	immutable RangeWithinFile importedFrom;
	immutable PathAndStorageKind resolvedPath;
}

immutable(Result!(ResolvedImport, Arr!ParseDiagnostic)) tryResolveImport(Alloc)(
	ref Alloc modelAlloc,
	ref immutable PathAndStorageKind fromPath,
	ref MutPathToFileIndex pathToFileIndex,
	ref ArrBuilder!PathAndStorageKind fileIndexToPath,
	immutable ImportAst ast,
) {
	immutable Ptr!Path path = copyPath(modelAlloc, ast.path); // TODO: shouldn't be necessary to copy?
	immutable(ResolvedImport) resolved(immutable PathAndStorageKind pk) {
		return immutable ResolvedImport(ast.range, pk);
	}
	if (ast.nDots == 0)
		return success!(ResolvedImport, Arr!ParseDiagnostic)(
			resolved(immutable PathAndStorageKind(path, StorageKind.global)));
	else {
		immutable RelPath relPath = immutable RelPath(cast(ubyte) (ast.nDots - 1), path);
		immutable Opt!(Ptr!Path) rel = resolvePath(modelAlloc, fromPath.path.parent, relPath);
		return has(rel)
			? success!(ResolvedImport, Arr!ParseDiagnostic)(
				resolved(immutable PathAndStorageKind(force(rel), fromPath.storageKind)))
			: fail!(ResolvedImport, Arr!ParseDiagnostic)(arrLiteral!ParseDiagnostic(modelAlloc,
				immutable ParseDiagnostic(
					ast.range,
					immutable ParseDiag(ParseDiag.RelativeImportReachesPastRoot(relPath)))));
	}
}

struct ImportAndExportPaths {
	immutable Arr!ResolvedImport imports;
	immutable Arr!ResolvedImport exports;
}

immutable(Result!(Arr!ResolvedImport, Arr!ParseDiagnostic)) resolveImportsOrExports(ModelAlloc, AstAlloc)(
	ref ModelAlloc modelAlloc,
	ref AstAlloc astAlloc,
	ref immutable PathAndStorageKind from,
	ref MutPathToFileIndex pathToFileIndex,
	ref ArrBuilder!PathAndStorageKind fileIndexToPath,
	ref immutable Opt!ImportsOrExportsAst importsOrExports,
) {
	immutable Arr!ImportAst paths = has(importsOrExports) ? force(importsOrExports).paths : emptyArr!ImportAst;
	return mapOrFail(astAlloc, paths, (ref immutable ImportAst i) =>
		tryResolveImport(modelAlloc, from, pathToFileIndex, fileIndexToPath, i));
}

immutable(Result!(ImportAndExportPaths, Arr!ParseDiagnostic)) resolveImportsAndExports(ModelAlloc, AstAlloc)(
	ref ModelAlloc modelAlloc,
	ref AstAlloc astAlloc,
	ref immutable PathAndStorageKind from,
	ref MutPathToFileIndex pathToFileIndex,
	ref ArrBuilder!PathAndStorageKind fileIndexToPath,
	ref immutable Opt!ImportsOrExportsAst imports,
	ref immutable Opt!ImportsOrExportsAst exports,
) {
	immutable Result!(Arr!ResolvedImport, Arr!ParseDiagnostic) importsResult =
		resolveImportsOrExports(modelAlloc, astAlloc, from, pathToFileIndex, fileIndexToPath, imports);
	immutable Result!(Arr!ResolvedImport, Arr!ParseDiagnostic) exportsResult =
		resolveImportsOrExports(modelAlloc, astAlloc, from, pathToFileIndex, fileIndexToPath, exports);
	return joinResults!(ImportAndExportPaths, Arr!ResolvedImport, Arr!ResolvedImport, Arr!ParseDiagnostic)(
		importsResult,
		exportsResult,
		(ref immutable Arr!ResolvedImport resolvedImports, ref immutable Arr!ResolvedImport resolvedExports) =>
			immutable ImportAndExportPaths(resolvedImports, resolvedExports));
}

struct PathAndAstAndResolvedImports { //TODO:RENAME
	immutable StorageKind storageKind; // Needed to determine which are include
	immutable FileAst ast;
	immutable Arr!FileIndex resolvedImports;
	immutable Arr!FileIndex resolvedExports;
}

struct ImportsAndExports {
	// This includes implicit import of 'std.nz' if this file is not itself in 'include'
	immutable Arr!(Ptr!Module) allImports;
	immutable Arr!(Ptr!Module) exports;
}

//TODO:INLINE
immutable(Arr!(Ptr!Module)) mapImportsOrExports(ModelAlloc)(
	ref ModelAlloc modelAlloc,
	ref immutable Arr!FileIndex paths,
	ref immutable FullIndexDict!(FileIndex, Ptr!Module) compiled,
) {
	return map(
		modelAlloc,
		paths,
		(ref immutable FileIndex importPath) => fullIndexDictGet(compiled, importPath));
}

struct ModulesAndCommonTypes {
	immutable Arr!(Ptr!Module) modules;
	immutable CommonTypes commonTypes;
}

// Result does not include the 'bootstrap' module.
immutable(Result!(ModulesAndCommonTypes, Diags)) getModules(ModelAlloc)(
	ref ModelAlloc modelAlloc,
	ref ProgramState programState,
	immutable FileIndex stdIndex,
	ref immutable Arr!PathAndAstAndResolvedImports fileAsts,
) {
	Late!CommonTypes commonTypes = late!CommonTypes;
	immutable Result!(Arr!(Ptr!Module), Diags) res = mapOrFailWithSoFar!(Ptr!Module, Diags)(
		modelAlloc,
		fileAsts,
		(ref immutable PathAndAstAndResolvedImports ast, ref immutable Arr!(Ptr!Module) soFar, immutable size_t index) {
			immutable FullIndexDict!(FileIndex, Ptr!Module) compiled =
				fullIndexDictOfArr!(FileIndex, Ptr!Module)(soFar);
			immutable PathAndAst pathAndAst = immutable PathAndAst(immutable FileIndex(safeSizeTToU16(index)), ast.ast);
			if (commonTypes.lateIsSet) {
				immutable Bool isInInclude = Bool(ast.storageKind == StorageKind.global);
				immutable Arr!FileIndex allImports = isInInclude
					? ast.resolvedImports
					: prepend(modelAlloc, stdIndex, ast.resolvedImports);
				immutable Arr!(Ptr!Module) mappedImports =
					mapImportsOrExports!ModelAlloc(modelAlloc, allImports, compiled);
				immutable Arr!(Ptr!Module) mappedExports =
					mapImportsOrExports!ModelAlloc(modelAlloc, ast.resolvedExports, compiled);
				return check(
					modelAlloc,
					programState,
					mappedImports,
					mappedExports,
					pathAndAst,
					commonTypes.lateGet);
			} else {
				// The first module to check is always 'bootstrap.nz'
				verify(ast.resolvedImports.empty);
				immutable Result!(BootstrapCheck, Diags) res =
					checkBootstrapNz(modelAlloc, programState, pathAndAst);
				if (res.isSuccess)
					commonTypes.lateSet(res.asSuccess.commonTypes);
				return mapSuccess(res, (ref immutable BootstrapCheck c) => c.module_);
			}
		});
	return mapSuccess!(ModulesAndCommonTypes, Arr!(Ptr!Module), Diags)(
		res,
		(ref immutable Arr!(Ptr!Module) modules) => immutable ModulesAndCommonTypes(modules, commonTypes.lateGet));
}

immutable(Result!(Program, Diags)) checkEverything(ModelAlloc)(
	ref ModelAlloc modelAlloc,
	ref immutable Arr!PathAndAstAndResolvedImports allAsts,
	ref immutable FilesInfo filesInfo,
	ref immutable CommonModuleIndices moduleIndices,
) {
	ProgramState programState;
	immutable Result!(ModulesAndCommonTypes, Diags) modulesResult =
		getModules(modelAlloc, programState, moduleIndices.std, allAsts);
	return modulesResult.mapSuccess((ref immutable ModulesAndCommonTypes modulesAndCommonTypes) {
		immutable Arr!(Ptr!Module) modules = modulesAndCommonTypes.modules;
		immutable Ptr!Module bootstrapModule = at(modules, moduleIndices.bootstrap.index);
		immutable Ptr!StructDecl ctxStructDecl =
			bootstrapModule.structsAndAliasesMap.mustGetAt(shortSymAlphaLiteral("ctx")).asStructDecl;
		immutable Ptr!StructInst ctxStructInst = instantiateNonTemplateStruct(modelAlloc, programState, ctxStructDecl);
		return immutable Program(
			filesInfo,
			at(modules, moduleIndices.alloc.index),
			bootstrapModule,
			at(modules, moduleIndices.runtime.index),
			at(modules, moduleIndices.runtimeMain.index),
			at(modules, moduleIndices.main.index),
			modules,
			modulesAndCommonTypes.commonTypes,
			ctxStructInst);
	});
}

