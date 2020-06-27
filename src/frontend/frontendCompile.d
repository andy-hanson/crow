module frontend.frontendCompile;

@safe @nogc pure nothrow:

import diag : Diag, Diags, Diagnostic, Diagnostics, FilesInfo, PathAndStorageKindAndRange;

import model :
	asStructDecl,
	CommonTypes,
	comparePathAndStorageKind,
	LineAndColumnGetters,
	Module,
	pathAndStorageKindEq,
	Program,
	StructDecl,
	StructInst;
import parseDiag : ParseDiagnostic;

import frontend.ast : FileAst, ImportAst;
import frontend.check : BootstrapCheck, check, checkBootstrapNz, PathAndAst;
import frontend.instantiate : instantiateNonTemplateStruct;
import frontend.parse : parseFile;
import frontend.programState : ProgramState;
import frontend.readOnlyStorage : absolutePathsGetter, choose, ReadOnlyStorages, tryReadFile;

import util.alloc.stackAlloc : StackAlloc;
import util.bools : Bool;
import util.collection.arr : Arr, empty, range;
import util.collection.arrBuilder : add, ArrBuilder, finishArr;
import util.collection.arrUtil : arrLiteral, cat, find, map, mapOrFail, prepend;
import util.collection.dict : mustGetAt;
import util.collection.dictBuilder : addToDict, DictBuilder, finishDictShouldBeNoConflict;
import util.collection.mutDict : addToMutDict, getAt_mut, hasKey_mut, mustGetAt_mut, MutDict, setInDict;
import util.collection.str : NulTerminatedStr, Str, stripNulTerminator, strLiteral;
import util.late : Late, lateGet, lateIsSet, lateSet;
import util.lineAndColumnGetter : LineAndColumnGetter, lineAndColumnGetterForEmptyFile, lineAndColumnGetterForText;
import util.opt : force, has, Opt, none, some;
import util.path : baseName, copyPath, parent, Path, PathAndStorageKind, RelPath, resolvePath, rootPath, StorageKind;
import util.ptr : Ptr;
import util.result : asSuccess, fail, flatMapSuccess, isSuccess, joinResults, mapFailure, mapSuccess, match, Result, success;
import util.sourceRange : SourceRange;
import util.sym : AllSymbols, shortSymAlphaLiteral, Sym;

immutable(Result!(Program, Diagnostics)) frontendCompile(ModelAlloc, SymAlloc)(
	ref ModelAlloc modelAlloc,
	ref AllSymbols!SymAlloc allSymbols,
	ReadOnlyStorages storages,
	immutable Ptr!Path mainPath,
) {
	StackAlloc astsAlloc;

	immutable PathAndStorageKind main = PathAndStorageKind(mainPath, StorageKind.local);
	immutable LcgsAndAllAsts parsed = parseEverything(modelAlloc, allSymbols, storages, main, astsAlloc);
	immutable Result!(Program, Diags) res = flatMapSuccess!(Program, AllAsts, Diags)(
		parsed.allAsts,
		(ref immutable AllAsts allAsts) => checkEverything(modelAlloc, allAsts, main, parsed.lineAndColumnGetters));
	return mapFailure!(Diagnostics, Program, Diags)(res, (ref immutable Diags diagnostics) =>
		immutable Diagnostics(diagnostics, FilesInfo(storages.absolutePathsGetter, parsed.lineAndColumnGetters)));
}

private:

immutable(PathAndStorageKind) pathInInclude(Alloc)(ref Alloc alloc, immutable Sym name) {
	return PathAndStorageKind(rootPath(alloc, name), StorageKind.global);
}

immutable(PathAndStorageKind) bootstrapPath(Alloc)(ref Alloc alloc) {
	return pathInInclude(alloc, shortSymAlphaLiteral("bootstrap"));
}

immutable(PathAndStorageKind) stdPath(Alloc)(ref Alloc alloc) {
	return pathInInclude(alloc, shortSymAlphaLiteral("std"));
}

immutable(PathAndStorageKind) runtimePath(Alloc)(ref Alloc alloc) {
	return pathInInclude(alloc, shortSymAlphaLiteral("runtime"));
}

immutable(PathAndStorageKind) runtimeMainPath(Alloc)(ref Alloc alloc) {
	return pathInInclude(alloc, shortSymAlphaLiteral("runtime-main"));
}

immutable(Opt!NulTerminatedStr) getFile(Alloc)(
	ref Alloc fileAlloc,
	immutable PathAndStorageKind pk,
	ref ReadOnlyStorages storages,
) {
	return storages.choose(pk.storageKind).tryReadFile(fileAlloc, pk.path);
}

immutable(Diags) parseDiagnostics(Alloc)(
	ref Alloc modelAlloc,
	immutable PathAndStorageKind where,
	immutable ParseDiagnostic p,
) {
	return arrLiteral!Diagnostic(modelAlloc, Diagnostic(PathAndStorageKindAndRange(where, p.range), Diag(p.diag)));
}

alias LineAndColumnGettersBuilder =
	DictBuilder!(PathAndStorageKind, LineAndColumnGetter, comparePathAndStorageKind);

void addEmptyLineAndColumnGetter(Alloc)(
	ref Alloc alloc,
	ref LineAndColumnGettersBuilder lineAndColumnGetters,
	immutable PathAndStorageKind where,
) {
	// Even a non-existent path needs LineAndColumnGetter since that's where the diagnostic is
	lineAndColumnGetters.addToDict(alloc, where, lineAndColumnGetterForEmptyFile(alloc));
}

immutable(Result!(FileAst, Diags)) parseSingle(ModelAlloc, AstAlloc, SymAlloc)(
	ref ModelAlloc modelAlloc,
	ref AstAlloc astAlloc,
	ref AllSymbols!SymAlloc allSymbols,
	immutable Opt!PathAndStorageKindAndRange importedFrom,
	immutable PathAndStorageKind where,
	ref ReadOnlyStorages storages,
	ref LineAndColumnGettersBuilder lineAndColumnGetters
) {
	// File content must go in astAlloc because we refer to strings without copying
	immutable Opt!NulTerminatedStr opFileContent = getFile(astAlloc, where, storages);
	if (opFileContent.has) {
		immutable NulTerminatedStr text = opFileContent.force;
		lineAndColumnGetters.addToDict(modelAlloc, where, lineAndColumnGetterForText(modelAlloc, text.stripNulTerminator));
		immutable Result!(FileAst, ParseDiagnostic) result = parseFile(astAlloc, allSymbols, text);
		return result.mapFailure!(Diags, FileAst, ParseDiagnostic)((ref immutable ParseDiagnostic p) =>
			parseDiagnostics(modelAlloc, where, p));
	} else {
		immutable Bool isImport = importedFrom.has;
		immutable PathAndStorageKindAndRange diagWhere = isImport
			? importedFrom.force
			: PathAndStorageKindAndRange(where, SourceRange.empty);
		if (!isImport)
			addEmptyLineAndColumnGetter(modelAlloc, lineAndColumnGetters, where);
		immutable Diag.FileDoesNotExist.Kind kind = isImport
			? Diag.FileDoesNotExist.Kind.import_
			: Diag.FileDoesNotExist.Kind.root;
		return fail!(FileAst, Diags)(arrLiteral!Diagnostic(
			modelAlloc,
			Diagnostic(diagWhere, Diag(Diag.FileDoesNotExist(kind, where)))));
	}
}

struct ResolvedImport {
	// This is arbitrarily the first module we saw to import this.
	// This is just used for error reporting in case the file can't be read.
	immutable PathAndStorageKindAndRange importedFrom;
	immutable PathAndStorageKind resolvedPath;
}

immutable(Result!(ResolvedImport, Diags)) tryResolveImport(Alloc)(
	ref Alloc modelAlloc,
	immutable PathAndStorageKind from,
	immutable ImportAst ast,
) {
	immutable Ptr!Path path = copyPath(modelAlloc, ast.path); // TODO: shouldn't be necessary to copy?
	immutable PathAndStorageKindAndRange importedFrom = PathAndStorageKindAndRange(from, ast.range);
	if (ast.nDots == 0)
		return success!(ResolvedImport, Diags)(
			ResolvedImport(importedFrom, PathAndStorageKind(path, StorageKind.global)));
	else {
		immutable RelPath relPath = RelPath(cast(ubyte) (ast.nDots - 1), path);
		immutable Opt!(Ptr!Path) rel = resolvePath(modelAlloc, from.path.parent, relPath);
		return rel.has
			? success!(ResolvedImport, Diags)(ResolvedImport(importedFrom, PathAndStorageKind(rel.force, from.storageKind)))
			: fail!(ResolvedImport, Diags)(arrLiteral!Diagnostic(modelAlloc,
				Diagnostic(PathAndStorageKindAndRange(from, ast.range), Diag(Diag.RelativeImportReachesPastRoot(relPath)))));
	}
}

struct ImportAndExportPaths {
	immutable Arr!ResolvedImport imports;
	immutable Arr!ResolvedImport exports;
}

immutable(Result!(Arr!ResolvedImport, Diags)) resolveImportsOrExports(ModelAlloc, AstAlloc)(
	ref ModelAlloc modelAlloc,
	ref AstAlloc astAlloc,
	immutable PathAndStorageKind from,
	immutable Arr!ImportAst importsOrExports,
) {
	return importsOrExports.mapOrFail(astAlloc, (ref immutable ImportAst i) =>
		tryResolveImport(modelAlloc, from, i));
}

immutable(Result!(ImportAndExportPaths, Diags)) resolveImportsAndExports(ModelAlloc, AstAlloc)(
	ref ModelAlloc modelAlloc,
	ref AstAlloc astAlloc,
	immutable PathAndStorageKind from,
	immutable Arr!ImportAst imports,
	immutable Arr!ImportAst exports
) {
	immutable Result!(Arr!ResolvedImport, Diags) a = resolveImportsOrExports(modelAlloc, astAlloc, from, imports);
	immutable Result!(Arr!ResolvedImport, Diags) b = resolveImportsOrExports(modelAlloc, astAlloc, from, exports);
	return joinResults!(ImportAndExportPaths, Arr!ResolvedImport, Arr!ResolvedImport, Diags)(a, b,
		(ref immutable Arr!ResolvedImport resolvedImports, ref immutable Arr!ResolvedImport resolvedExports) =>
			immutable ImportAndExportPaths(resolvedImports, resolvedExports));
}

struct PathAndAstAndResolvedImports {
	immutable PathAndStorageKind pathAndStorageKind;
	immutable FileAst ast;
	immutable Arr!PathAndStorageKind resolvedImports;
	immutable Arr!PathAndStorageKind resolvedExports;
}

immutable(PathAndAst) pathAndAst(ref immutable PathAndAstAndResolvedImports a) {
	return PathAndAst(a.pathAndStorageKind, a.ast);
}

immutable(Arr!PathAndStorageKind) stripRange(Alloc)(ref Alloc alloc, immutable Arr!ResolvedImport a) {
	return a.map(alloc, (ref immutable ResolvedImport i) => i.resolvedPath);
}

enum ParseStatus {
	started,
	finished,
}

//TODO: Diags is an array, just use empty array instead of none?
immutable(Opt!Diags) parseRecur(ModelAlloc, AstAlloc, SymAlloc)(
	ref ModelAlloc modelAlloc,
	ref AstAlloc astAlloc,
	ref AllSymbols!SymAlloc allSymbols,
	ref ReadOnlyStorages storages,
	ref LineAndColumnGettersBuilder lineAndColumnGetters,
	ref ArrBuilder!PathAndAstAndResolvedImports res,
	ref MutDict!(PathAndStorageKind, ParseStatus, comparePathAndStorageKind) statuses,
	immutable Opt!PathAndStorageKindAndRange importedFrom,
	immutable PathAndStorageKind path,
) {
	statuses.setInDict(astAlloc, path, ParseStatus.started);

	immutable Result!(FileAst, Diags) parseResult =
		parseSingle(modelAlloc, astAlloc, allSymbols, importedFrom, path, storages, lineAndColumnGetters);
	return parseResult.match(
		(ref immutable FileAst ast) {
			immutable Result!(ImportAndExportPaths, Diags) importsResult =
				resolveImportsAndExports(modelAlloc, astAlloc, path, ast.imports, ast.exports);
			return importsResult.match(
				(ref immutable ImportAndExportPaths importsAndExports) {
					// Ensure all imports are added before adding this
					immutable Arr!ResolvedImport importsAndExportsArr =
						cat(astAlloc, importsAndExports.imports, importsAndExports.exports);
					foreach (ref immutable ResolvedImport import_; importsAndExportsArr.range) {
						immutable Opt!ParseStatus status = statuses.getAt_mut(import_.resolvedPath);
						if (status.has) {
							final switch (status.force) {
								case ParseStatus.started:
									return some(arrLiteral!Diagnostic(modelAlloc,
										Diagnostic(import_.importedFrom, Diag(Diag.CircularImport(path, import_.resolvedPath)))));
								case ParseStatus.finished:
									break;
							}
						} else {
							immutable Opt!Diags err = parseRecur(
								modelAlloc,
								astAlloc,
								allSymbols,
								storages,
								lineAndColumnGetters,
								res,
								statuses,
								some(import_.importedFrom),
								import_.resolvedPath);
							if (err.has)
								return err;
						}
					}
					immutable PathAndAstAndResolvedImports pa = PathAndAstAndResolvedImports(
						path,
						ast,
						stripRange(astAlloc, importsAndExports.imports));
					res.add(astAlloc, pa);
					statuses.setInDict(astAlloc, path, ParseStatus.finished);
					return none!Diags;
				},
				(ref immutable Diags d) => some(d),
			);
		},
		(ref immutable Diags d) => some(d),
	);
}

alias AllAsts = immutable Arr!PathAndAstAndResolvedImports;

// Starts at 'main' and recursively parses all imports too.
// Result will be in import order -- asts at lower indices are imported by asts at higher indices.
// So, don't have to worry about circularity when checking.
immutable(Result!(AllAsts, Diags)) parseEverythingWorker(ModelAlloc, AstAlloc, SymAlloc)(
	ref ModelAlloc modelAlloc,
	ref AstAlloc astAlloc,
	ref AllSymbols!SymAlloc allSymbols,
	immutable PathAndStorageKind mainPath,
	ref ReadOnlyStorages storages,
	ref LineAndColumnGettersBuilder lineAndColumnGetters,
) {
	ArrBuilder!PathAndAstAndResolvedImports res;
	MutDict!(PathAndStorageKind, ParseStatus, comparePathAndStorageKind) statuses;
	immutable Arr!PathAndStorageKind rootPaths = arrLiteral!PathAndStorageKind(
		astAlloc,
		// Ensure bootstrap.nz is parsed first
		bootstrapPath(modelAlloc),
		// Ensure std.nz is available
		stdPath(modelAlloc),
		runtimePath(modelAlloc),
		runtimeMainPath(modelAlloc),
		mainPath);
	foreach (immutable PathAndStorageKind path; rootPaths.range)
		if (!statuses.hasKey_mut(path)) {
			immutable Opt!Diags err = parseRecur(
				modelAlloc,
				astAlloc,
				allSymbols,
				storages,
				lineAndColumnGetters,
				res,
				statuses,
				none!PathAndStorageKindAndRange,
				path);
			if (err.has)
				return fail!(AllAsts, Diags)(err.force);
		}
	return success!(AllAsts, Diags)(res.finishArr(astAlloc));
}

struct LcgsAndAllAsts {
	immutable LineAndColumnGetters lineAndColumnGetters;
	immutable Result!(AllAsts, Diags) allAsts;
}

LcgsAndAllAsts parseEverything(ModelAlloc, AstAlloc, SymAlloc)(
	ref ModelAlloc modelAlloc,
	ref AllSymbols!SymAlloc allSymbols,
	ref ReadOnlyStorages storages,
	ref immutable PathAndStorageKind mainPath,
	ref AstAlloc astAlloc,
) {
	LineAndColumnGettersBuilder lineAndColumnGetters;
	immutable Result!(AllAsts, Diags) asts =
		parseEverythingWorker(modelAlloc, astAlloc, allSymbols, mainPath, storages, lineAndColumnGetters);
	immutable LineAndColumnGetters lc = lineAndColumnGetters.finishDictShouldBeNoConflict(modelAlloc);
	return LcgsAndAllAsts(lc, asts);
}

struct ImportsAndExports {
	// This includes implicit import of 'std.nz' if this file is not itself in 'include'
	immutable Arr!(Ptr!Module) allImports;
	immutable Arr!(Ptr!Module) exports;
}

immutable(Arr!(Ptr!Module)) mapImportsOrExports(ModelAlloc)(
	ref ModelAlloc modelAlloc,
	immutable Arr!PathAndStorageKind paths,
	ref MutDict!(PathAndStorageKind, immutable Ptr!Module, comparePathAndStorageKind) compiled,
) {
	return paths.map(
		modelAlloc,
		(ref immutable PathAndStorageKind importPath) => compiled.mustGetAt_mut(importPath));
}

struct ModulesAndCommonTypes {
	immutable Arr!(Ptr!Module) modules;
	immutable CommonTypes commonTypes;
}

// Result does not include the 'bootstrap' module.
immutable(Result!(ModulesAndCommonTypes, Diags)) getModules(ModelAlloc)(
	ref ModelAlloc modelAlloc,
	ref ProgramState programState,
	immutable AllAsts fileAsts,
) {
	Late!CommonTypes commonTypes;
	StackAlloc compiledAlloc;
	MutDict!(PathAndStorageKind, immutable Ptr!Module, comparePathAndStorageKind) compiled;
	immutable Result!(Arr!(Ptr!Module), Diags) res = fileAsts.mapOrFail!(Ptr!Module, Diags)(
		modelAlloc,
		(ref immutable PathAndAstAndResolvedImports ast) {
			immutable Result!(Ptr!Module, Diags) res = (() {
				if (commonTypes.lateIsSet) {
					immutable Bool isInInclude = Bool(ast.pathAndStorageKind.storageKind == StorageKind.global);
					immutable Arr!PathAndStorageKind allImports = isInInclude
						? ast.resolvedImports
						: prepend(modelAlloc, stdPath(modelAlloc), ast.resolvedImports);
					immutable Arr!(Ptr!Module) mappedImports = mapImportsOrExports(modelAlloc, allImports, compiled);
					immutable Arr!(Ptr!Module) mappedExports = mapImportsOrExports(modelAlloc, ast.resolvedExports, compiled);
					return check(
						modelAlloc,
						programState,
						mappedImports,
						mappedExports,
						ast.pathAndAst,
						commonTypes.lateGet);
				} else {
					// The first module to check is always 'bootstrap.nz'
					assert(pathAndStorageKindEq(ast.pathAndStorageKind, modelAlloc.bootstrapPath));
					assert(ast.resolvedImports.empty);
					immutable Result!(BootstrapCheck, Diags) res =
						checkBootstrapNz(modelAlloc, programState, ast.pathAndAst);
					if (res.isSuccess)
						commonTypes.lateSet(res.asSuccess.commonTypes);
					return mapSuccess(res, (ref immutable BootstrapCheck c) => c.module_);
				}
			})();
			if (res.isSuccess)
				compiled.addToMutDict!(StackAlloc, PathAndStorageKind, immutable Ptr!Module, comparePathAndStorageKind)(
					compiledAlloc, ast.pathAndStorageKind, res.asSuccess);
			return res;
		});
	return mapSuccess!(ModulesAndCommonTypes, Arr!(Ptr!Module), Diags)(
		res,
		(ref immutable Arr!(Ptr!Module) modules) => immutable ModulesAndCommonTypes(modules, commonTypes.lateGet));
}

immutable(Ptr!Module) findModule(immutable PathAndStorageKind pk, immutable Arr!(Ptr!Module) modules) {
	immutable Opt!(Ptr!Module) op = modules.find!(Ptr!Module)((ref immutable Ptr!Module m) =>
		pathAndStorageKindEq(m.pathAndStorageKind, pk)
	);
	return op.force;
}

immutable(Result!(Program, Diags)) checkEverything(ModelAlloc)(
	ref ModelAlloc modelAlloc,
	ref immutable AllAsts allAsts,
	immutable PathAndStorageKind mainPath,
	immutable LineAndColumnGetters lineAndColumnGetters,
) {
	ProgramState programState;
	immutable Result!(ModulesAndCommonTypes, Diags) modulesResult = getModules(modelAlloc, programState, allAsts);
	return modulesResult.mapSuccess((ref immutable ModulesAndCommonTypes modulesAndCommonTypes) {
		immutable Arr!(Ptr!Module) modules = modulesAndCommonTypes.modules;
		immutable Ptr!Module bootstrapModule = findModule(bootstrapPath(modelAlloc), modules);
		immutable Ptr!StructDecl ctxStructDecl =
			bootstrapModule.structsAndAliasesMap.mustGetAt(shortSymAlphaLiteral("ctx")).asStructDecl;
		immutable Ptr!StructInst ctxStructInst = instantiateNonTemplateStruct(modelAlloc, ctxStructDecl);
		return immutable Program(
			bootstrapModule,
			findModule(runtimePath(modelAlloc), modules),
			findModule(runtimeMainPath(modelAlloc), modules),
			findModule(mainPath, modules),
			modules,
			modulesAndCommonTypes.commonTypes,
			ctxStructInst,
			lineAndColumnGetters);
	});
}

