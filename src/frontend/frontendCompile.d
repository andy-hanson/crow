module frontend.frontendCompile;

@safe @nogc nothrow: // not pure

import frontend.check.getCommonFuns : CommonPath, getCommonFuns;
import model.diag : Diag, Diagnostics, DiagnosticWithinFile, FilesInfo, filesInfoForSingle;
import model.model :
	CommonFuns, CommonTypes, Config, FileContent, ImportFileType, ImportOrExport, ImportOrExportKind, Module, Program;
import model.parseDiag : ParseDiag;
import frontend.check.check : BootstrapCheck, check, checkBootstrap, ImportOrExportFile, ImportsAndExports, PathAndAst;
import frontend.config : getConfig;
import frontend.diagnosticsBuilder : addDiagnosticsForFile, DiagnosticsBuilder, finishDiagnostics;
import frontend.parse.ast : emptyFileAst, FileAst, ImportOrExportAst, ImportOrExportAstKind, ImportsOrExportsAst;
import frontend.lang : crowExtension;
import frontend.parse.parse : parseFile;
import frontend.programState : ProgramState;
import util.alloc.alloc : Alloc;
import util.col.arr : empty;
import util.col.arrBuilder : add, ArrBuilder, arrBuilderSize, finishArr;
import util.col.arrUtil : contains, copyArr, map, mapOp, mapOrNoneImpure, mapWithSoFar, prepend;
import util.col.dict : mapValues;
import util.col.enumDict : EnumDict, enumDictMapValues;
import util.col.fullIndexDict : asArray, FullIndexDict, fullIndexDictOfArr;
import util.col.mutMaxArr : isEmpty, mustPeek, mustPop, MutMaxArr, mutMaxArr, push;
import util.col.mutDict : addToMutDict, getAt_mut, hasKey_mut, moveToDict, mustGetAt_mut, MutDict, setInDict;
import util.col.str : copySafeCStr, SafeCStr, safeCStr;
import util.conv : safeToUshort;
import util.late : late, Late, lateGet, lateIsSet, lateSet;
import util.lineAndColumnGetter : LineAndColumnGetter, lineAndColumnGetterForEmptyFile, lineAndColumnGetterForText;
import util.opt : force, has, Opt, none, some;
import util.path :
	AllPaths,
	childPath,
	concatPaths,
	firstAndRest,
	matchPathOrRelPath,
	parent,
	Path,
	PathAndRange,
	PathFirstAndRest,
	RelPath,
	resolvePath;
import util.perf : Perf, PerfMeasure, withMeasure;
import util.readOnlyStorage : asOption, ReadFileResult, ReadOnlyStorage, withFileBinary, withFileText;
import util.sourceRange : FileIndex, RangeWithinFile;
import util.sym : AllSymbols, Sym, sym;
import util.union_ : Union;
import util.util : typeAs, verify;

Program frontendCompile(
	ref Alloc modelAlloc,
	ref Perf perf,
	ref Alloc astsAlloc,
	ref AllPaths allPaths,
	ref AllSymbols allSymbols,
	in ReadOnlyStorage storage,
	in Path[] rootPaths,
	in Opt!Path mainPath,
) {
	DiagnosticsBuilder diagsBuilder = DiagnosticsBuilder();
	Config config = getConfig(modelAlloc, allSymbols, allPaths, storage, diagsBuilder, rootPaths);
	ParsedEverything parsed = withMeasure!(ParsedEverything, () => parseEverything(
		modelAlloc, perf, allPaths, allSymbols, diagsBuilder, storage, rootPaths, mainPath, config, astsAlloc)
	)(astsAlloc, perf, PerfMeasure.parseEverything);
	return withMeasure!(Program, () =>
		checkEverything(
			modelAlloc, perf, allSymbols, diagsBuilder,
			config, parsed.asts, parsed.filesInfo, parsed.commonModuleIndices)
	)(modelAlloc, perf, PerfMeasure.checkEverything);
}

immutable struct FileAstAndDiagnostics {
	FileAst ast;
	FilesInfo filesInfo;
	Diagnostics diagnostics;
}

FileAstAndDiagnostics parseSingleAst(
	ref Alloc alloc,
	ref Perf perf,
	ref AllSymbols allSymbols,
	ref AllPaths allPaths,
	in ReadOnlyStorage storage,
	Path path,
) {
	// In this case model alloc and AST alloc are the same
	return withFileText!FileAstAndDiagnostics(storage, path, crowExtension, (in ReadFileResult!SafeCStr fileContent) {
		ArrBuilder!DiagnosticWithinFile diags;
		FileAst ast = parseSingle(
			alloc,
			alloc,
			perf,
			allPaths,
			allSymbols,
			diags,
			none!PathAndRange,
			fileContent);
		DiagnosticsBuilder diagsBuilder;
		addDiagnosticsForFile(alloc, diagsBuilder, FileIndex(0), diags);
		FilesInfo filesInfo =
			filesInfoForSingle(alloc, path, lineAndColumnGetterForOptText(alloc, asOption(fileContent)));
		return FileAstAndDiagnostics(
			ast,
			filesInfo,
			finishDiagnostics(alloc, diagsBuilder, filesInfo.filePaths));
	});
}

private:

immutable struct ParseStatus {
	immutable struct Started {}
	immutable struct Done { FileIndex fileIndex; }
	mixin Union!(Started, Done);
}

alias PathToStatus = MutDict!(Path, ParseStatus);

immutable struct ParsedEverything {
	FilesInfo filesInfo;
	CommonModuleIndices commonModuleIndices;
	FullIndexDict!(FileIndex, AstAndResolvedImports) asts;
}

immutable struct CommonModuleIndices {
	Opt!FileIndex main;
	EnumDict!(CommonPath, FileIndex) common;
	FileIndex[] rootPaths;
}

struct ParseStackEntry {
	immutable Path path;
	immutable FileAst ast;
	immutable LineAndColumnGetter lineAndColumnGetter;
	immutable ImportAndExportPaths importsAndExports;
	ArrBuilder!DiagnosticWithinFile diags;
}

alias ParseStack = MutMaxArr!(32, ParseStackEntry);

ParsedEverything parseEverything(
	ref Alloc modelAlloc,
	scope ref Perf perf,
	ref AllPaths allPaths,
	ref AllSymbols allSymbols,
	scope ref DiagnosticsBuilder diagsBuilder,
	in ReadOnlyStorage storage,
	in Path[] rootPaths,
	in Opt!Path mainPath,
	ref Config config,
	ref Alloc astAlloc,
) {
	if (has(mainPath))
		verify(contains(rootPaths, force(mainPath)));

	ArrBuilder!Path fileIndexToPath;
	PathToStatus statuses;
	ArrBuilder!AstAndResolvedImports res;
	LineAndColumnGettersBuilder lineAndColumnGetters;

	ParseStack stack = mutMaxArr!(32, ParseStackEntry)();

	Opt!(FullyResolvedImport[]) resolveImportsOrExports(
		ref ArrBuilder!DiagnosticWithinFile diags,
		Path fromPath,
		ResolvedImport[] importsOrExports,
	) {
		return mapOrNoneImpure!(FullyResolvedImport, ResolvedImport)(
			modelAlloc, importsOrExports, (in ResolvedImport import_) =>
				fullyResolveImport(
					modelAlloc, astAlloc, perf, allSymbols, allPaths, storage, config,
					statuses, stack, diags, fromPath, import_));
	}

	void process() {
		while (!isEmpty(stack)) {
			Path path = mustPeek(stack).path;
			ImportAndExportPaths importsAndExports = mustPeek(stack).importsAndExports;
			Opt!(FullyResolvedImport[]) imports =
				resolveImportsOrExports(mustPeek(stack).diags, path, importsAndExports.imports);
			Opt!(FullyResolvedImport[]) exports =
				resolveImportsOrExports(mustPeek(stack).diags, path, importsAndExports.exports);
			if (has(imports) && has(exports)) {
				ParseStackEntry entry = mustPop(stack);
				FileIndex fileIndex = FileIndex(safeToUshort(arrBuilderSize(res)));

				addDiagnosticsForFile(modelAlloc, diagsBuilder, fileIndex, entry.diags);
				verify(arrBuilderSize(fileIndexToPath) == fileIndex.index);
				verify(arrBuilderSize(lineAndColumnGetters) == fileIndex.index);
				add(astAlloc, res, AstAndResolvedImports(entry.ast, force(imports), force(exports)));
				add(modelAlloc, fileIndexToPath, path);
				add(modelAlloc, lineAndColumnGetters, entry.lineAndColumnGetter);
				setInDict(astAlloc, statuses, path, ParseStatus(ParseStatus.Done(fileIndex)));
			}
			// else, we just pushed a dependency to the stack, so repeat.
		}
	}

	void processRootPath(Path path) {
		if (!hasKey_mut(statuses, path)) {
			pushIt(
				modelAlloc, astAlloc, perf, allSymbols, allPaths, storage, config,
				statuses, stack, path, none!PathAndRange);
			process();
		}
	}

	immutable EnumDict!(CommonPath, Path) commonPaths = commonPaths(allPaths, storage.includeDir);
	foreach (Path path; commonPaths)
		processRootPath(path);
	foreach (Path path; rootPaths)
		processRootPath(path);

	verify(isEmpty(stack));

	FileIndex getIndex(Path path) pure {
		return mustGetAt_mut(statuses, path).as!(ParseStatus.Done).fileIndex;
	}

	CommonModuleIndices commonModuleIndices = CommonModuleIndices(
		has(mainPath) ? some(getIndex(force(mainPath))) : none!FileIndex,
		enumDictMapValues!(CommonPath, FileIndex, Path)(commonPaths, (in Path path) => getIndex(path)),
		map(modelAlloc, rootPaths, (ref Path path) => getIndex(path)));

	return ParsedEverything(
		FilesInfo(
			fullIndexDictOfArr!(FileIndex, Path)(finishArr(modelAlloc, fileIndexToPath)),
			mapValues!(Path, FileIndex, ParseStatus)(
				modelAlloc,
				moveToDict!(Path, ParseStatus)(astAlloc, statuses),
				(Path, ref ParseStatus x) =>
					x.as!(ParseStatus.Done).fileIndex),
			fullIndexDictOfArr!(FileIndex, LineAndColumnGetter)(finishArr(modelAlloc, lineAndColumnGetters))),
		commonModuleIndices,
		fullIndexDictOfArr!(FileIndex, AstAndResolvedImports)(finishArr(astAlloc, res)));
}

immutable(EnumDict!(CommonPath, Path)) commonPaths(ref AllPaths allPaths, Path includeDir) {
	Path includeCrow = childPath(allPaths, includeDir, sym!"crow");
	Path private_ = childPath(allPaths, includeCrow, sym!"private");
	Path col = childPath(allPaths, includeCrow, sym!"col");
	return immutable EnumDict!(CommonPath, Path)([
		childPath(allPaths, private_, sym!"bootstrap"),
		childPath(allPaths, private_, sym!"alloc"),
		childPath(allPaths, private_, sym!"exception-low-level"),
		childPath(allPaths, includeCrow, sym!"fun-util"),
		childPath(allPaths, col, sym!"list"),
		childPath(allPaths, includeCrow, sym!"std"),
		childPath(allPaths, includeCrow, sym!"string"),
		childPath(allPaths, private_, sym!"runtime"),
		childPath(allPaths, private_, sym!"rt-main"),
	]);
}

void pushIt(
	ref Alloc modelAlloc,
	ref Alloc astAlloc,
	scope ref Perf perf,
	ref AllSymbols allSymbols,
	ref AllPaths allPaths,
	in ReadOnlyStorage storage,
	in Config config,
	ref PathToStatus statuses,
	ref ParseStack stack,
	Path path,
	Opt!PathAndRange importedFrom,
) {
	withFileText!void(storage, path, crowExtension, (in ReadFileResult!SafeCStr fileContent) {
		ArrBuilder!DiagnosticWithinFile diags;
		LineAndColumnGetter lineAndColumnGetter = lineAndColumnGetterForOptText(modelAlloc, asOption(fileContent));
		FileAst ast = parseSingle(modelAlloc, astAlloc, perf, allPaths, allSymbols, diags, importedFrom, fileContent);
		ImportAndExportPaths importsAndExports = resolveImportAndExportPaths(
			modelAlloc, astAlloc, allPaths, diags, storage.includeDir, config, path, ast.imports, ast.exports);
		addToMutDict(astAlloc, statuses, path, ParseStatus(ParseStatus.Started()));
		push(stack, ParseStackEntry(path, ast, lineAndColumnGetter, importsAndExports, diags));
	});
}

// returns none if we can't resolve all imported modules yet
Opt!FullyResolvedImport fullyResolveImport(
	ref Alloc modelAlloc,
	ref Alloc astAlloc,
	scope ref Perf perf,
	ref AllSymbols allSymbols,
	ref AllPaths allPaths,
	in ReadOnlyStorage storage,
	in Config config,
	ref PathToStatus statuses,
	ref ParseStack stack,
	ref ArrBuilder!DiagnosticWithinFile diags,
	Path fromPath,
	in ResolvedImport import_,
) {
	Opt!FullyResolvedImportKind kind = has(import_.resolvedPath)
		? fullyResolveImportKind(
			modelAlloc, astAlloc, perf, allSymbols, allPaths, storage, config, statuses, stack, diags, fromPath,
			import_, force(import_.resolvedPath))
		: some(FullyResolvedImportKind(FullyResolvedImportKind.Failed()));
	return has(kind)
		? some(FullyResolvedImport(some(import_.importedFrom), force(kind)))
		: none!FullyResolvedImport;
}

Opt!FullyResolvedImportKind fullyResolveImportKind(
	ref Alloc modelAlloc,
	ref Alloc astAlloc,
	scope ref Perf perf,
	ref AllSymbols allSymbols,
	ref AllPaths allPaths,
	in ReadOnlyStorage storage,
	in Config config,
	ref PathToStatus statuses,
	ref ParseStack stack,
	ref ArrBuilder!DiagnosticWithinFile diags,
	Path fromPath,
	in ResolvedImport import_,
	Path resolvedPath,
) =>
	import_.kind.matchImpure!(Opt!FullyResolvedImportKind)(
		(in ImportOrExportAstKind.ModuleWhole) =>
			fullyResolveImportModule(
				modelAlloc, astAlloc, perf, allSymbols, allPaths, storage, config, statuses, stack, diags, fromPath,
				import_.importedFrom, resolvedPath,
				(FileIndex f) =>
					FullyResolvedImportKind(FullyResolvedImportKind.ModuleWhole(f))),
		(in Sym[] names) =>
			fullyResolveImportModule(
				modelAlloc, astAlloc, perf, allSymbols, allPaths, storage, config, statuses, stack, diags, fromPath,
				import_.importedFrom, resolvedPath,
				(FileIndex f) =>
					FullyResolvedImportKind(FullyResolvedImportKind.ModuleNamed(f, copyArr(modelAlloc, names)))),
		(in ImportOrExportAstKind.File f) =>
			some(FullyResolvedImportKind(
				FullyResolvedImportKind.File(
					f.name,
					f.type,
					readFileContent(
						modelAlloc, diags, storage,
						some(PathAndRange(fromPath, import_.importedFrom)),
						resolvedPath, f.type)))));

FileContent readFileContent(
	ref Alloc modelAlloc,
	ref ArrBuilder!DiagnosticWithinFile diags,
	in ReadOnlyStorage storage,
	Opt!PathAndRange importedFrom,
	Path path,
	ImportFileType type,
) {
	final switch (type) {
		case ImportFileType.nat8Array:
			return FileContent(withFileBinary!(immutable ubyte[])(
				storage, path,
				(in ReadFileResult!(ubyte[]) res) =>
					handleReadFileResult!(immutable ubyte[], ubyte[])(
						modelAlloc, diags, importedFrom, res,
						(in immutable ubyte[] content) => copyArr(modelAlloc, content),
						() => typeAs!(immutable ubyte[])([]))));
		case ImportFileType.str:
			return FileContent(withFileText!SafeCStr(
				storage, path, sym!"",
				(in ReadFileResult!SafeCStr res) =>
					handleReadFileResult!(SafeCStr, SafeCStr)(
						modelAlloc, diags, importedFrom, res,
						(in SafeCStr content) => copySafeCStr(modelAlloc, content),
						() => safeCStr!"")));
	}
}

Opt!FullyResolvedImportKind fullyResolveImportModule(
	ref Alloc modelAlloc,
	ref Alloc astAlloc,
	scope ref Perf perf,
	ref AllSymbols allSymbols,
	ref AllPaths allPaths,
	in ReadOnlyStorage storage,
	in Config config,
	ref PathToStatus statuses,
	ref ParseStack stack,
	ref ArrBuilder!DiagnosticWithinFile diags,
	Path fromPath,
	RangeWithinFile importedFrom,
	Path importPath,
	in FullyResolvedImportKind delegate(FileIndex) @safe @nogc pure nothrow getSuccessKind,
) {
	Opt!ParseStatus status = getAt_mut!(Path, ParseStatus)(statuses, importPath);
	if (has(status))
		return some(force(status).match!FullyResolvedImportKind(
			(ParseStatus.Started) {
				add(modelAlloc, diags, DiagnosticWithinFile(
					importedFrom,
					Diag(ParseDiag(ParseDiag.CircularImport(fromPath, importPath)))));
				return FullyResolvedImportKind(FullyResolvedImportKind.Failed());
			},
			(ParseStatus.Done x) =>
				getSuccessKind(x.fileIndex)));
	else {
		pushIt(
			modelAlloc, astAlloc, perf, allSymbols, allPaths, storage, config, statuses, stack, importPath,
			some(PathAndRange(fromPath, importedFrom)));
		return none!FullyResolvedImportKind;
	}
}

pure:

alias LineAndColumnGettersBuilder = ArrBuilder!LineAndColumnGetter;

LineAndColumnGetter lineAndColumnGetterForOptText(ref Alloc modelAlloc, in Opt!SafeCStr opFileContent) =>
	has(opFileContent)
		? lineAndColumnGetterForText(modelAlloc, force(opFileContent))
		: lineAndColumnGetterForEmptyFile(modelAlloc);

FileAst parseSingle(
	ref Alloc modelAlloc,
	ref Alloc astAlloc,
	scope ref Perf perf,
	ref AllPaths allPaths,
	ref AllSymbols allSymbols,
	ref ArrBuilder!DiagnosticWithinFile diags,
	in Opt!PathAndRange importedFrom,
	in ReadFileResult!SafeCStr fileContent,
) =>
	handleReadFileResult!(FileAst, SafeCStr)(
		modelAlloc,
		diags,
		importedFrom,
		fileContent,
		(in SafeCStr content) => parseFile(astAlloc, perf, allPaths, allSymbols, diags, content),
		() => emptyFileAst);

T handleReadFileResult(T, Content)(
	ref Alloc modelAlloc,
	ref ArrBuilder!DiagnosticWithinFile diags,
	in Opt!PathAndRange importedFrom,
	in ReadFileResult!Content result,
	in T delegate(in immutable Content) @safe @nogc pure nothrow cbSuccess,
	in T delegate() @safe @nogc pure nothrow cbFail,
) =>
	result.matchIn!T(
		(in immutable Content content) =>
			cbSuccess(content),
		(in ReadFileResult!Content.NotFound) {
			add(modelAlloc, diags, DiagnosticWithinFile(RangeWithinFile.empty, Diag(
				ParseDiag(ParseDiag.FileDoesNotExist(importedFrom)))));
			return cbFail();
		},
		(in ReadFileResult!Content.Error) {
			add(modelAlloc, diags, DiagnosticWithinFile(RangeWithinFile.empty, Diag(
				ParseDiag(ParseDiag.FileReadError(importedFrom)))));
			return cbFail();
		});

immutable struct ResolvedImport {
	// This is arbitrarily the first module we saw to import this.
	// This is just used for error reporting in case the file can't be read.
	RangeWithinFile importedFrom;
	Opt!Path resolvedPath;
	ImportOrExportAstKind kind;
}

ResolvedImport tryResolveImport(
	ref Alloc modelAlloc,
	ref AllPaths allPaths,
	ref ArrBuilder!DiagnosticWithinFile diagnosticsBuilder,
	Path includeDir,
	in Config config,
	Path fromPath,
	in ImportOrExportAst ast,
) {
	ResolvedImport resolved(Path pk) {
		return ResolvedImport(ast.range, some(pk), ast.kind);
	}
	return matchPathOrRelPath!ResolvedImport(
		ast.path,
		(Path global) {
			PathFirstAndRest fr = firstAndRest(allPaths, global);
			Opt!Path fromConfig = config.include[fr.first];
			return resolved(has(fromConfig)
				? has(fr.rest) ? concatPaths(allPaths, force(fromConfig), force(fr.rest)) : force(fromConfig)
				: concatPaths(allPaths, includeDir, global));
		},
		(RelPath relPath) {
			Opt!Path rel = resolvePath(allPaths, parent(allPaths, fromPath), relPath);
			if (has(rel))
				return resolved(force(rel));
			else {
				add(modelAlloc, diagnosticsBuilder, DiagnosticWithinFile(ast.range, Diag(
					ParseDiag(ParseDiag.RelativeImportReachesPastRoot(relPath)))));
				return ResolvedImport(ast.range, none!Path, ast.kind);
			}
		});
}

immutable struct ImportAndExportPaths {
	ResolvedImport[] imports;
	ResolvedImport[] exports;
}

ResolvedImport[] resolveImportOrExportPaths(
	ref Alloc modelAlloc,
	ref Alloc astAlloc,
	ref AllPaths allPaths,
	ref ArrBuilder!DiagnosticWithinFile diagnosticsBuilder,
	Path includeDir,
	in Config config,
	Path fromPath,
	in Opt!ImportsOrExportsAst importsOrExports,
) {
	ImportOrExportAst[] paths = has(importsOrExports) ? force(importsOrExports).paths : [];
	return map(astAlloc, paths, (ref ImportOrExportAst i) =>
		tryResolveImport(modelAlloc, allPaths, diagnosticsBuilder, includeDir, config, fromPath, i));
}

ImportAndExportPaths resolveImportAndExportPaths(
	ref Alloc modelAlloc,
	ref Alloc astAlloc,
	ref AllPaths allPaths,
	ref ArrBuilder!DiagnosticWithinFile diagnosticsBuilder,
	Path includeDir,
	in Config config,
	Path fromPath,
	in Opt!ImportsOrExportsAst imports,
	in Opt!ImportsOrExportsAst exports,
) =>
	ImportAndExportPaths(
		resolveImportOrExportPaths(
			modelAlloc, astAlloc, allPaths, diagnosticsBuilder, includeDir, config, fromPath, imports),
		resolveImportOrExportPaths(
			modelAlloc, astAlloc, allPaths, diagnosticsBuilder, includeDir, config, fromPath, exports));

immutable struct AstAndResolvedImports {
	FileAst ast;
	FullyResolvedImport[] resolvedImports;
	FullyResolvedImport[] resolvedExports;

	static AstAndResolvedImports empty() =>
		AstAndResolvedImports(emptyFileAst, [], []);
}

immutable struct FullyResolvedImport {
	// none for 'std'
	Opt!RangeWithinFile range;
	FullyResolvedImportKind kind;
}

immutable struct FullyResolvedImportKind {
	immutable struct ModuleWhole {
		FileIndex fileIndex;
	}
	immutable struct ModuleNamed {
		FileIndex fileIndex;
		Sym[] names;
	}
	immutable struct File {
		Sym name;
		ImportFileType type;
		FileContent content;
	}
	immutable struct Failed {}

	mixin Union!(ModuleWhole, ModuleNamed, File, Failed);
}

immutable struct ImportsOrExports {
	ImportOrExport[] moduleImports;
	ImportOrExportFile[] fileImports;
}

ImportsOrExports mapImportsOrExports(
	ref Alloc modelAlloc,
	in FullyResolvedImport[] paths,
	in FullIndexDict!(FileIndex, Module) compiled,
) {
	ArrBuilder!ImportOrExportFile fileImports;
	ImportOrExport[] moduleImports = mapOp!(ImportOrExport, FullyResolvedImport)(
		modelAlloc,
		paths,
		(ref FullyResolvedImport x) {
			Opt!ImportOrExportKind kind = x.kind.match!(Opt!ImportOrExportKind)(
				(FullyResolvedImportKind.ModuleWhole m) =>
					m.fileIndex == FileIndex.none
						? none!ImportOrExportKind
						// TODO: Should just be `&compiled[m.fileIndex]``
						: some(ImportOrExportKind(
							ImportOrExportKind.ModuleWhole(&compiled.values[m.fileIndex.index]))),
				(FullyResolvedImportKind.ModuleNamed m) =>
					m.fileIndex == FileIndex.none
						? none!ImportOrExportKind
						// TODO: Should just be `&compiled[m.fileIndex]``
						: some(ImportOrExportKind(
							ImportOrExportKind.ModuleNamed(&compiled.values[m.fileIndex.index], m.names))),
				(FullyResolvedImportKind.File f) {
					//TODO: could be a temp alloc
					add(modelAlloc, fileImports, ImportOrExportFile(force(x.range), f.name, f.type, f.content));
					return none!ImportOrExportKind;
				},
				(FullyResolvedImportKind.Failed) =>
					none!ImportOrExportKind);
			return has(kind) ? some(ImportOrExport(x.range, force(kind))) : none!ImportOrExport;
	});
	return ImportsOrExports(moduleImports, finishArr(modelAlloc, fileImports));
}

struct ModulesAndCommonTypes {
	immutable Module[] modules;
	CommonTypes commonTypes;
}

ModulesAndCommonTypes getModules(
	ref Alloc modelAlloc,
	ref Perf perf,
	ref AllSymbols allSymbols,
	scope ref DiagnosticsBuilder diagsBuilder,
	ref ProgramState programState,
	FileIndex stdIndex,
	in FullIndexDict!(FileIndex, AstAndResolvedImports) fileAsts,
) {
	Late!CommonTypes commonTypes = late!CommonTypes;
	Module[] modules = mapWithSoFar!(Module, AstAndResolvedImports)(
		modelAlloc,
		asArray(fileAsts),
		(in AstAndResolvedImports ast, in Module[] soFar, size_t index) {
			immutable FullIndexDict!(FileIndex, Module) compiled = fullIndexDictOfArr!(FileIndex, Module)(soFar);
			PathAndAst pathAndAst = PathAndAst(FileIndex(safeToUshort(index)), ast.ast);
			if (lateIsSet(commonTypes))
				return checkNonBootstrapModule(
					modelAlloc, perf, allSymbols, diagsBuilder, programState, stdIndex,
					ast, compiled, pathAndAst, lateGet(commonTypes));
			else {
				// The first module to check is always 'bootstrap.crow'
				verify(ast.resolvedImports.empty);
				BootstrapCheck res =
					checkBootstrap(modelAlloc, perf, allSymbols, diagsBuilder, programState, pathAndAst);
				lateSet(commonTypes, res.commonTypes);
				return res.module_;
			}
		});
	return ModulesAndCommonTypes(modules, lateGet(commonTypes));
}

Module checkNonBootstrapModule(
	ref Alloc modelAlloc,
	ref Perf perf,
	ref AllSymbols allSymbols,
	scope ref DiagnosticsBuilder diagsBuilder,
	ref ProgramState programState,
	FileIndex stdIndex,
	in AstAndResolvedImports ast,
	in FullIndexDict!(FileIndex, Module) compiled,
	in PathAndAst pathAndAst,
	in CommonTypes commonTypes,
) {
	FullyResolvedImport[] allImports = ast.ast.noStd
		? ast.resolvedImports
		: prepend(
			modelAlloc,
			FullyResolvedImport(
			none!RangeWithinFile,
				FullyResolvedImportKind(FullyResolvedImportKind.ModuleWhole(stdIndex))),
			ast.resolvedImports);
	ImportsOrExports imports = mapImportsOrExports(modelAlloc, allImports, compiled);
	ImportsOrExports exports = mapImportsOrExports(modelAlloc, ast.resolvedExports, compiled);
	ImportsAndExports importsAndExports = ImportsAndExports(
		imports.moduleImports,
		exports.moduleImports,
		imports.fileImports,
		exports.fileImports);
	return check(modelAlloc, perf, allSymbols, diagsBuilder, programState, importsAndExports, pathAndAst, commonTypes);
}

Program checkEverything(
	ref Alloc modelAlloc,
	ref Perf perf,
	ref AllSymbols allSymbols,
	ref DiagnosticsBuilder diagsBuilder,
	Config config,
	in FullIndexDict!(FileIndex, AstAndResolvedImports) allAsts,
	ref FilesInfo filesInfo,
	in CommonModuleIndices moduleIndices,
) {
	ProgramState programState;
	ModulesAndCommonTypes modulesAndCommonTypes = getModules(
		modelAlloc, perf, allSymbols, diagsBuilder, programState, moduleIndices.common[CommonPath.std], allAsts);
	Module[] modules = modulesAndCommonTypes.modules;
	immutable EnumDict!(CommonPath, Module*) commonModules =
		enumDictMapValues!(CommonPath, Module*, FileIndex)(moduleIndices.common, (in FileIndex index) =>
			&modules[index.index]);
	Opt!CommonFuns commonFuns = getCommonFuns(
		modelAlloc,
		programState,
		diagsBuilder,
		modulesAndCommonTypes.commonTypes,
		has(moduleIndices.main) ? some(&modules[force(moduleIndices.main).index]) : none!(Module*),
		commonModules);
	return Program(
		filesInfo,
		config,
		modules,
		map!(Module*, FileIndex)(modelAlloc, moduleIndices.rootPaths, (ref FileIndex index) =>
			&modules[index.index]),
		commonFuns,
		modulesAndCommonTypes.commonTypes,
		finishDiagnostics(modelAlloc, diagsBuilder, filesInfo.filePaths));
}
