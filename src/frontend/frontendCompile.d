module frontend.frontendCompile;

@safe @nogc nothrow: // not pure

import model.diag : Diag, Diagnostics, DiagnosticWithinFile, FilesInfo, filesInfoForSingle;
import model.model :
	CommonTypes,
	Config,
	FileContent,
	ImportFileType,
	ImportOrExport,
	ImportOrExportKind,
	Module,
	Program,
	SpecialModules;
import model.parseDiag : ParseDiag;
import frontend.check.check : BootstrapCheck, check, checkBootstrap, ImportOrExportFile, ImportsAndExports, PathAndAst;
import frontend.config : getConfig;
import frontend.diagnosticsBuilder : addDiagnosticsForFile, DiagnosticsBuilder, finishDiagnostics;
import frontend.parse.ast :
	emptyFileAst,
	FileAst,
	ImportOrExportAst,
	ImportOrExportAstKind,
	ImportsOrExportsAst,
	matchImportOrExportAstKindImpure;
import frontend.lang : crowExtension;
import frontend.parse.parse : parseFile;
import frontend.programState : ProgramState;
import util.alloc.alloc : Alloc;
import util.col.arr : empty;
import util.col.arrBuilder : add, ArrBuilder, arrBuilderSize, finishArr;
import util.col.arrUtil : copyArr, map, mapOp, mapOrNoneImpure, mapWithSoFar, prepend;
import util.col.dict : mapValues;
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
import util.readOnlyStorage :
	asOption, matchReadFileResult, ReadFileResult, ReadOnlyStorage, withFileBinary, withFileText;
import util.sourceRange : FileIndex, RangeWithinFile;
import util.sym : AllSymbols, Sym, sym;
import util.util : as, verify;

immutable(Program) frontendCompile(
	ref Alloc modelAlloc,
	ref Perf perf,
	ref Alloc astsAlloc,
	ref AllPaths allPaths,
	ref AllSymbols allSymbols,
	scope ref const ReadOnlyStorage storage,
	scope immutable Path[] rootPaths,
) {
	DiagnosticsBuilder diagsBuilder = DiagnosticsBuilder();
	immutable Config config = getConfig(modelAlloc, allSymbols, allPaths, storage, diagsBuilder, rootPaths);
	immutable ParsedEverything parsed = withMeasure!(immutable ParsedEverything, () =>
		parseEverything(modelAlloc, perf, allPaths, allSymbols, diagsBuilder, storage, rootPaths, config, astsAlloc)
	)(astsAlloc, perf, PerfMeasure.parseEverything);
	return withMeasure!(immutable Program, () =>
		checkEverything(
			modelAlloc, perf, allSymbols, diagsBuilder,
			config, parsed.asts, parsed.filesInfo, parsed.commonModuleIndices)
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
	immutable Path path,
) {
	// In this case model alloc and AST alloc are the same
	return withFileText(storage, path, crowExtension, (immutable ReadFileResult!SafeCStr fileContent) {
		ArrBuilder!DiagnosticWithinFile diags;
		immutable FileAst ast = parseSingle(
			alloc,
			alloc,
			perf,
			allPaths,
			allSymbols,
			diags,
			none!PathAndRange,
			fileContent);
		DiagnosticsBuilder diagsBuilder;
		addDiagnosticsForFile(alloc, diagsBuilder, immutable FileIndex(0), diags);
		immutable FilesInfo filesInfo =
			filesInfoForSingle(alloc, path, lineAndColumnGetterForOptText(alloc, asOption(fileContent)));
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

alias PathToStatus = MutDict!(immutable Path, immutable ParseStatus);

struct ParsedEverything {
	immutable FilesInfo filesInfo;
	immutable CommonModuleIndices commonModuleIndices;
	immutable FullIndexDict!(FileIndex, AstAndResolvedImports) asts;
}

struct CommonModuleIndices {
	immutable FileIndex alloc;
	immutable FileIndex bootstrap;
	immutable FileIndex exceptionLowLevel;
	immutable FileIndex std;
	immutable FileIndex runtime;
	immutable FileIndex runtimeMain;
	immutable FileIndex[] rootPaths;
}

struct ParseStackEntry {
	immutable Path path;
	immutable FileAst ast;
	immutable LineAndColumnGetter lineAndColumnGetter;
	immutable ImportAndExportPaths importsAndExports;
	ArrBuilder!DiagnosticWithinFile diags;
}

alias ParseStack = MutMaxArr!(32, ParseStackEntry);

//TODO: Marked @trusted to avoid initializing stack...
immutable(ParsedEverything) parseEverything(
	ref Alloc modelAlloc,
	scope ref Perf perf,
	ref AllPaths allPaths,
	ref AllSymbols allSymbols,
	ref DiagnosticsBuilder diagsBuilder,
	scope ref const ReadOnlyStorage storage,
	scope immutable Path[] rootPaths,
	ref immutable Config config,
	ref Alloc astAlloc,
) {
	ArrBuilder!Path fileIndexToPath;
	PathToStatus statuses;
	ArrBuilder!AstAndResolvedImports res;
	LineAndColumnGettersBuilder lineAndColumnGetters;

	ParseStack stack = mutMaxArr!(32, ParseStackEntry)();

	immutable(Opt!(FullyResolvedImport[])) resolveImportsOrExports(
		ref ArrBuilder!DiagnosticWithinFile diags,
		immutable Path fromPath,
		immutable ResolvedImport[] importsOrExports,
	) =>
		mapOrNoneImpure(modelAlloc, importsOrExports, (ref immutable ResolvedImport import_) =>
			fullyResolveImport(
				modelAlloc, astAlloc, perf, allSymbols, allPaths, storage, config,
				statuses, stack, diags, fromPath, import_));

	immutable Path includeDir = storage.includeDir;
	immutable Path includeCrow = childPath(allPaths, includeDir, sym!"crow");
	immutable Path private_ = childPath(allPaths, includeCrow, sym!"private");
	immutable Path bootstrapPath = childPath(allPaths, private_, sym!"bootstrap");
	immutable Path allocPath = childPath(allPaths, private_, sym!"alloc");
	immutable Path exceptionLowLevelPath = childPath(allPaths, private_, sym!"exception-low-level");
	immutable Path stdPath = childPath(allPaths, includeCrow, sym!"std");
	immutable Path runtimePath = childPath(allPaths, private_, sym!"runtime");
	immutable Path runtimeMainPath = childPath(allPaths, private_, sym!"rt-main");

	void process() {
		while (!isEmpty(stack)) {
			immutable Path path = mustPeek(stack).path;
			immutable ImportAndExportPaths importsAndExports = mustPeek(stack).importsAndExports;
			immutable Opt!(FullyResolvedImport[]) imports =
				resolveImportsOrExports(mustPeek(stack).diags, path, importsAndExports.imports);
			immutable Opt!(FullyResolvedImport[]) exports =
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

	void processRootPath(immutable Path path) {
		if (!hasKey_mut(statuses, path)) {
			pushIt(
				modelAlloc, astAlloc, perf, allSymbols, allPaths, storage, config,
				statuses, stack, path, none!PathAndRange);
			process();
		}
	}
	immutable Path[6] commonPaths =
		[bootstrapPath, allocPath, exceptionLowLevelPath, stdPath, runtimePath, runtimeMainPath];
	foreach (immutable Path path; commonPaths)
		processRootPath(path);
	foreach (immutable Path path; rootPaths)
		processRootPath(path);

	verify(isEmpty(stack));

	immutable(FileIndex) getIndex(immutable Path path) pure =>
		asDone(mustGetAt_mut(statuses, path));

	immutable CommonModuleIndices commonModuleIndices = immutable CommonModuleIndices(
		getIndex(allocPath),
		getIndex(bootstrapPath),
		getIndex(exceptionLowLevelPath),
		getIndex(stdPath),
		getIndex(runtimePath),
		getIndex(runtimeMainPath),
		map(modelAlloc, rootPaths, (ref immutable Path path) => getIndex(path)));

	return immutable ParsedEverything(
		immutable FilesInfo(
			fullIndexDictOfArr!(FileIndex, Path)(finishArr(modelAlloc, fileIndexToPath)),
			mapValues!(Path, ParseStatus, FileIndex)(
				modelAlloc,
				moveToDict(astAlloc, statuses),
				(immutable(Path), ref immutable ParseStatus x) =>
					asDone(x)),
			fullIndexDictOfArr!(FileIndex, LineAndColumnGetter)(finishArr(modelAlloc, lineAndColumnGetters))),
		commonModuleIndices,
		fullIndexDictOfArr!(FileIndex, AstAndResolvedImports)(finishArr(astAlloc, res)));
}

void pushIt(
	ref Alloc modelAlloc,
	ref Alloc astAlloc,
	scope ref Perf perf,
	ref AllSymbols allSymbols,
	ref AllPaths allPaths,
	scope ref const ReadOnlyStorage storage,
	ref immutable Config config,
	ref PathToStatus statuses,
	ref ParseStack stack,
	immutable Path path,
	immutable Opt!PathAndRange importedFrom,
) {
	withFileText!void(storage, path, crowExtension, (immutable ReadFileResult!SafeCStr fileContent) @safe {
		ArrBuilder!DiagnosticWithinFile diags;
		immutable LineAndColumnGetter lineAndColumnGetter =
			lineAndColumnGetterForOptText(modelAlloc, asOption(fileContent));
		immutable FileAst ast = parseSingle(
			modelAlloc, astAlloc, perf, allPaths, allSymbols, diags, importedFrom, fileContent);
		immutable ImportAndExportPaths importsAndExports = resolveImportAndExportPaths(
			modelAlloc, astAlloc, allPaths, diags, storage.includeDir, config, path, ast.imports, ast.exports);
		addToMutDict(astAlloc, statuses, path, immutable ParseStatus(immutable ParseStatus.Started()));
		push(stack, ParseStackEntry(path, ast, lineAndColumnGetter, importsAndExports, diags));
	});
}

// returns none if we can't resolve all imported modules yet
immutable(Opt!FullyResolvedImport) fullyResolveImport(
	ref Alloc modelAlloc,
	ref Alloc astAlloc,
	scope ref Perf perf,
	ref AllSymbols allSymbols,
	ref AllPaths allPaths,
	scope ref const ReadOnlyStorage storage,
	ref immutable Config config,
	ref PathToStatus statuses,
	ref ParseStack stack,
	ref ArrBuilder!DiagnosticWithinFile diags,
	immutable Path fromPath,
	ref immutable ResolvedImport import_,
) {
	immutable Opt!FullyResolvedImportKind kind = has(import_.resolvedPath)
		? fullyResolveImportKind(
			modelAlloc, astAlloc, perf, allSymbols, allPaths, storage, config, statuses, stack, diags, fromPath,
			import_, force(import_.resolvedPath))
		: some(immutable FullyResolvedImportKind(immutable FullyResolvedImportKind.Failed()));
	return has(kind)
		? some(immutable FullyResolvedImport(some(import_.importedFrom), force(kind)))
		: none!FullyResolvedImport;
}

immutable(Opt!FullyResolvedImportKind) fullyResolveImportKind(
	ref Alloc modelAlloc,
	ref Alloc astAlloc,
	scope ref Perf perf,
	ref AllSymbols allSymbols,
	ref AllPaths allPaths,
	scope ref const ReadOnlyStorage storage,
	ref immutable Config config,
	ref PathToStatus statuses,
	ref ParseStack stack,
	ref ArrBuilder!DiagnosticWithinFile diags,
	immutable Path fromPath,
	ref immutable ResolvedImport import_,
	immutable Path resolvedPath,
) =>
	matchImportOrExportAstKindImpure!(immutable Opt!FullyResolvedImportKind)(
		import_.kind,
		(immutable ImportOrExportAstKind.ModuleWhole m) =>
			fullyResolveImportModule(
				modelAlloc, astAlloc, perf, allSymbols, allPaths, storage, config, statuses, stack, diags, fromPath,
				import_.importedFrom, resolvedPath,
				(immutable FileIndex f) =>
					immutable FullyResolvedImportKind(immutable FullyResolvedImportKind.ModuleWhole(f))),
		(immutable ImportOrExportAstKind.ModuleNamed m) =>
			fullyResolveImportModule(
				modelAlloc, astAlloc, perf, allSymbols, allPaths, storage, config, statuses, stack, diags, fromPath,
				import_.importedFrom, resolvedPath,
				(immutable FileIndex f) =>
					immutable FullyResolvedImportKind(
						immutable FullyResolvedImportKind.ModuleNamed(f, copyArr(modelAlloc, m.names)))),
		(immutable ImportOrExportAstKind.File f) =>
			some(immutable FullyResolvedImportKind(
				immutable FullyResolvedImportKind.File(
					f.name,
					f.type,
					readFileContent(
						modelAlloc, diags, storage,
						some(immutable PathAndRange(fromPath, import_.importedFrom)),
						resolvedPath, f.type)))));

immutable(FileContent) readFileContent(
	ref Alloc modelAlloc,
	ref ArrBuilder!DiagnosticWithinFile diags,
	scope ref const ReadOnlyStorage storage,
	immutable Opt!PathAndRange importedFrom,
	immutable Path path,
	immutable ImportFileType type,
) {
	final switch (type) {
		case ImportFileType.nat8Array:
			return immutable FileContent(withFileBinary!(ubyte[])(
				storage, path,
				(immutable ReadFileResult!(ubyte[]) res) =>
					handleReadFileResult!(immutable ubyte[], ubyte[])(
						modelAlloc, diags, importedFrom, res,
						(scope immutable ubyte[] content) => copyArr(modelAlloc, content),
						() => as!(immutable ubyte[])([]))));
		case ImportFileType.str:
			return immutable FileContent(withFileText!SafeCStr(
				storage, path, sym!"",
				(immutable ReadFileResult!SafeCStr res) =>
					handleReadFileResult!(immutable SafeCStr, SafeCStr)(
						modelAlloc, diags, importedFrom, res,
						(immutable SafeCStr content) => copySafeCStr(modelAlloc, content),
						() => safeCStr!"")));
	}
}

immutable(Opt!FullyResolvedImportKind) fullyResolveImportModule(
	ref Alloc modelAlloc,
	ref Alloc astAlloc,
	scope ref Perf perf,
	ref AllSymbols allSymbols,
	ref AllPaths allPaths,
	scope ref const ReadOnlyStorage storage,
	ref immutable Config config,
	ref PathToStatus statuses,
	ref ParseStack stack,
	ref ArrBuilder!DiagnosticWithinFile diags,
	immutable Path fromPath,
	immutable RangeWithinFile importedFrom,
	immutable Path importPath,
	scope immutable(FullyResolvedImportKind) delegate(immutable FileIndex) @safe @nogc pure nothrow getSuccessKind,
) {
	immutable Opt!ParseStatus status = getAt_mut(statuses, importPath);
	if (has(status))
		return some(matchParseStatus!(immutable FullyResolvedImportKind)(
			force(status),
			(ref immutable ParseStatus.Started) {
				add(modelAlloc, diags, immutable DiagnosticWithinFile(
					importedFrom,
					immutable Diag(immutable ParseDiag(
						immutable ParseDiag.CircularImport(fromPath, importPath)))));
				return immutable FullyResolvedImportKind(immutable FullyResolvedImportKind.Failed());
			},
			(ref immutable ParseStatus.Done x) =>
				getSuccessKind(x.fileIndex)));
	else {
		pushIt(
			modelAlloc, astAlloc, perf, allSymbols, allPaths, storage, config, statuses, stack, importPath,
			some(immutable PathAndRange(fromPath, importedFrom)));
		return none!FullyResolvedImportKind;
	}
}

pure:

alias LineAndColumnGettersBuilder = ArrBuilder!LineAndColumnGetter;

immutable(LineAndColumnGetter) lineAndColumnGetterForOptText(
	ref Alloc modelAlloc,
	immutable Opt!SafeCStr opFileContent,
) =>
	has(opFileContent)
		? lineAndColumnGetterForText(modelAlloc, force(opFileContent))
		: lineAndColumnGetterForEmptyFile(modelAlloc);

immutable(FileAst) parseSingle(
	ref Alloc modelAlloc,
	ref Alloc astAlloc,
	scope ref Perf perf,
	ref AllPaths allPaths,
	ref AllSymbols allSymbols,
	ref ArrBuilder!DiagnosticWithinFile diags,
	immutable Opt!PathAndRange importedFrom,
	immutable ReadFileResult!SafeCStr fileContent,
) =>
	handleReadFileResult!(immutable FileAst, SafeCStr)(
		modelAlloc,
		diags,
		importedFrom,
		fileContent,
		(scope immutable SafeCStr content) => parseFile(astAlloc, perf, allPaths, allSymbols, diags, content),
		() => emptyFileAst);

immutable(T) handleReadFileResult(T, Content)(
	ref Alloc modelAlloc,
	ref ArrBuilder!DiagnosticWithinFile diags,
	immutable Opt!PathAndRange importedFrom,
	immutable ReadFileResult!Content result,
	scope immutable(T) delegate(scope immutable Content) @safe @nogc pure nothrow cbSuccess,
	scope immutable(T) delegate() @safe @nogc pure nothrow cbFail,
) =>
	matchReadFileResult!(immutable T, Content)(
		result,
		(immutable Content content) =>
			cbSuccess(content),
		(immutable(ReadFileResult!Content.NotFound)) {
			add(modelAlloc, diags, immutable DiagnosticWithinFile(RangeWithinFile.empty, immutable Diag(
				immutable ParseDiag(immutable ParseDiag.FileDoesNotExist(importedFrom)))));
			return cbFail();
		},
		(immutable(ReadFileResult!Content.Error)) {
			add(modelAlloc, diags, immutable DiagnosticWithinFile(RangeWithinFile.empty, immutable Diag(
				immutable ParseDiag(immutable ParseDiag.FileReadError(importedFrom)))));
			return cbFail();
		});

struct ResolvedImport {
	// This is arbitrarily the first module we saw to import this.
	// This is just used for error reporting in case the file can't be read.
	immutable RangeWithinFile importedFrom;
	immutable Opt!Path resolvedPath;
	immutable ImportOrExportAstKind kind;
}

immutable(ResolvedImport) tryResolveImport(
	ref Alloc modelAlloc,
	ref AllPaths allPaths,
	ref ArrBuilder!DiagnosticWithinFile diagnosticsBuilder,
	immutable Path includeDir,
	ref immutable Config config,
	immutable Path fromPath,
	ref immutable ImportOrExportAst ast,
) {
	immutable(ResolvedImport) resolved(immutable Path pk) =>
		immutable ResolvedImport(ast.range, some(pk), ast.kind);
	return matchPathOrRelPath!(immutable ResolvedImport)(
		ast.path,
		(immutable Path global) {
			immutable PathFirstAndRest fr = firstAndRest(allPaths, global);
			immutable Opt!Path fromConfig = config.include[fr.first];
			return resolved(has(fromConfig)
				? has(fr.rest) ? concatPaths(allPaths, force(fromConfig), force(fr.rest)) : force(fromConfig)
				: concatPaths(allPaths, includeDir, global));
		},
		(immutable RelPath relPath) {
			immutable Opt!Path rel = resolvePath(allPaths, parent(allPaths, fromPath), relPath);
			if (has(rel))
				return resolved(force(rel));
			else {
				add(modelAlloc, diagnosticsBuilder, immutable DiagnosticWithinFile(ast.range, immutable Diag(
					immutable ParseDiag(immutable ParseDiag.RelativeImportReachesPastRoot(relPath)))));
				return immutable ResolvedImport(ast.range, none!Path, ast.kind);
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
	immutable Path includeDir,
	ref immutable Config config,
	immutable Path fromPath,
	ref immutable Opt!ImportsOrExportsAst importsOrExports,
) {
	immutable ImportOrExportAst[] paths = has(importsOrExports) ? force(importsOrExports).paths : [];
	return map(astAlloc, paths, (ref immutable ImportOrExportAst i) =>
		tryResolveImport(modelAlloc, allPaths, diagnosticsBuilder, includeDir, config, fromPath, i));
}

immutable(ImportAndExportPaths) resolveImportAndExportPaths(
	ref Alloc modelAlloc,
	ref Alloc astAlloc,
	ref AllPaths allPaths,
	ref ArrBuilder!DiagnosticWithinFile diagnosticsBuilder,
	immutable Path includeDir,
	ref immutable Config config,
	immutable Path fromPath,
	ref immutable Opt!ImportsOrExportsAst imports,
	ref immutable Opt!ImportsOrExportsAst exports,
) =>
	immutable ImportAndExportPaths(
		resolveImportOrExportPaths(
			modelAlloc, astAlloc, allPaths, diagnosticsBuilder, includeDir, config, fromPath, imports),
		resolveImportOrExportPaths(
			modelAlloc, astAlloc, allPaths, diagnosticsBuilder, includeDir, config, fromPath, exports));

struct AstAndResolvedImports {
	immutable FileAst ast;
	immutable FullyResolvedImport[] resolvedImports;
	immutable FullyResolvedImport[] resolvedExports;

	static immutable(AstAndResolvedImports) empty() =>
		immutable AstAndResolvedImports(emptyFileAst, [], []);
}

struct FullyResolvedImport {
	// none for 'std'
	immutable Opt!RangeWithinFile range;
	immutable FullyResolvedImportKind kind;
}

struct FullyResolvedImportKind {
	@safe @nogc pure nothrow:

	struct ModuleWhole {
		immutable FileIndex fileIndex;
	}
	struct ModuleNamed {
		immutable FileIndex fileIndex;
		immutable Sym[] names;
	}
	struct File {
		immutable Sym name;
		immutable ImportFileType type;
		immutable FileContent content;
	}
	struct Failed {}

	immutable this(immutable FullyResolvedImportKind.ModuleWhole a) { kind = Kind.moduleWhole; moduleWhole = a; }
	immutable this(immutable FullyResolvedImportKind.ModuleNamed a) { kind = Kind.moduleNamed; moduleNamed = a; }
	immutable this(immutable FullyResolvedImportKind.File a) { kind = Kind.file; file = a; }
	immutable this(immutable FullyResolvedImportKind.Failed a) { kind = Kind.failed; failed = a; }

	private:
	enum Kind { moduleWhole, moduleNamed, file, failed }
	immutable Kind kind;
	union {
		immutable ModuleWhole moduleWhole;
		immutable ModuleNamed moduleNamed;
		immutable File file;
		immutable Failed failed;
	}
}

@trusted immutable(T) matchFullyResolvedImportKind(T)(
	ref immutable FullyResolvedImportKind a,
	scope immutable(T) delegate(immutable FullyResolvedImportKind.ModuleWhole) @safe @nogc pure nothrow cbModuleWhole,
	scope immutable(T) delegate(immutable FullyResolvedImportKind.ModuleNamed) @safe @nogc pure nothrow cbModuleNamed,
	scope immutable(T) delegate(immutable FullyResolvedImportKind.File) @safe @nogc pure nothrow cbFile,
	scope immutable(T) delegate(immutable FullyResolvedImportKind.Failed) @safe @nogc pure nothrow cbFailed,
) {
	final switch (a.kind) {
		case FullyResolvedImportKind.Kind.moduleWhole:
			return cbModuleWhole(a.moduleWhole);
		case FullyResolvedImportKind.Kind.moduleNamed:
			return cbModuleNamed(a.moduleNamed);
		case FullyResolvedImportKind.Kind.file:
			return cbFile(a.file);
		case FullyResolvedImportKind.Kind.failed:
			return cbFailed(a.failed);
	}
}

struct ImportsOrExports {
	immutable ImportOrExport[] moduleImports;
	immutable ImportOrExportFile[] fileImports;
}

immutable(ImportsOrExports) mapImportsOrExports(
	ref Alloc modelAlloc,
	immutable FullyResolvedImport[] paths,
	immutable FullIndexDict!(FileIndex, Module) compiled,
) {
	ArrBuilder!ImportOrExportFile fileImports;
	immutable ImportOrExport[] moduleImports = mapOp(modelAlloc, paths, (ref immutable FullyResolvedImport x) {
		immutable Opt!ImportOrExportKind kind = matchFullyResolvedImportKind(
			x.kind,
			(immutable FullyResolvedImportKind.ModuleWhole m) @safe =>
				m.fileIndex == FileIndex.none
					? none!ImportOrExportKind
					: some(immutable ImportOrExportKind(
						// TODO: Should just be `&compiled[m.fileIndex]``
						immutable ImportOrExportKind.ModuleWhole(&compiled.values[m.fileIndex.index]))),
			(immutable FullyResolvedImportKind.ModuleNamed m) =>
				m.fileIndex == FileIndex.none
					? none!ImportOrExportKind
					: some(immutable ImportOrExportKind(
						// TODO: Should just be `&compiled[m.fileIndex]``
						immutable ImportOrExportKind.ModuleNamed(&compiled.values[m.fileIndex.index], m.names))),
			(immutable FullyResolvedImportKind.File f) @safe {
				//TODO: could be a temp alloc
				add(modelAlloc, fileImports, immutable ImportOrExportFile(force(x.range), f.name, f.type, f.content));
				return none!ImportOrExportKind;
			},
			(immutable FullyResolvedImportKind.Failed) =>
				none!ImportOrExportKind);
		return has(kind) ? some(immutable ImportOrExport(x.range, force(kind))) : none!ImportOrExport;
	});
	return immutable ImportsOrExports(moduleImports, finishArr(modelAlloc, fileImports));
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
	immutable FullIndexDict!(FileIndex, AstAndResolvedImports) fileAsts,
) {
	Late!(immutable CommonTypes) commonTypes = late!(immutable CommonTypes);
	immutable Module[] modules = mapWithSoFar!Module(
		modelAlloc,
		asArray(fileAsts),
		(ref immutable AstAndResolvedImports ast, ref immutable Module[] soFar, immutable size_t index) {
			immutable FullIndexDict!(FileIndex, Module) compiled = fullIndexDictOfArr!(FileIndex, Module)(soFar);
			immutable PathAndAst pathAndAst = immutable PathAndAst(immutable FileIndex(safeToUshort(index)), ast.ast);
			if (lateIsSet(commonTypes))
				return checkNonBootstrapModule(
					modelAlloc, perf, allSymbols, diagsBuilder, programState, stdIndex,
					ast, compiled, pathAndAst, lateGet(commonTypes));
			else {
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

immutable(Module) checkNonBootstrapModule(
	ref Alloc modelAlloc,
	ref Perf perf,
	ref AllSymbols allSymbols,
	ref DiagnosticsBuilder diagsBuilder,
	ref ProgramState programState,
	immutable FileIndex stdIndex,
	ref immutable AstAndResolvedImports ast,
	immutable FullIndexDict!(FileIndex, Module) compiled,
	ref immutable PathAndAst pathAndAst,
	ref immutable CommonTypes commonTypes,
) {
	immutable bool noStd = ast.ast.noStd;
	immutable FullyResolvedImport[] allImports = noStd
		? ast.resolvedImports
		: prepend(
			modelAlloc,
			immutable FullyResolvedImport(
				none!RangeWithinFile,
				immutable FullyResolvedImportKind(immutable FullyResolvedImportKind.ModuleWhole(stdIndex))),
			ast.resolvedImports);
	immutable ImportsOrExports imports = mapImportsOrExports(modelAlloc, allImports, compiled);
	immutable ImportsOrExports exports = mapImportsOrExports(modelAlloc, ast.resolvedExports, compiled);
	immutable ImportsAndExports importsAndExports = immutable ImportsAndExports(
		imports.moduleImports,
		exports.moduleImports,
		imports.fileImports,
		exports.fileImports);
	return check(modelAlloc, perf, allSymbols, diagsBuilder, programState, importsAndExports, pathAndAst, commonTypes);
}

immutable(Program) checkEverything(
	ref Alloc modelAlloc,
	ref Perf perf,
	ref AllSymbols allSymbols,
	ref DiagnosticsBuilder diagsBuilder,
	immutable Config config,
	immutable FullIndexDict!(FileIndex, AstAndResolvedImports) allAsts,
	ref immutable FilesInfo filesInfo,
	ref immutable CommonModuleIndices moduleIndices,
) {
	ProgramState programState;
	immutable ModulesAndCommonTypes modulesAndCommonTypes =
		getModules(modelAlloc, perf, allSymbols, diagsBuilder, programState, moduleIndices.std, allAsts);
	immutable Module[] modules = modulesAndCommonTypes.modules;
	immutable Module* bootstrapModule = &modules[moduleIndices.bootstrap.index];
	return immutable Program(
		filesInfo,
		config,
		immutable SpecialModules(
			&modules[moduleIndices.alloc.index],
			bootstrapModule,
			&modules[moduleIndices.exceptionLowLevel.index],
			&modules[moduleIndices.runtime.index],
			&modules[moduleIndices.runtimeMain.index],
			map!(Module*, immutable FileIndex)(modelAlloc, moduleIndices.rootPaths, (ref immutable FileIndex index) =>
				&modules[index.index])),
		modules,
		modulesAndCommonTypes.commonTypes,
		finishDiagnostics(modelAlloc, diagsBuilder, filesInfo.filePaths));
}
