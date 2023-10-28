module frontend.frontendCompile;

@safe @nogc pure nothrow:

import frontend.check.getCommonFuns : CommonModule, getCommonFuns;
import model.diag : Diag, Diagnostics, DiagnosticWithinFile, FilesInfo, filesInfoForSingle;
import model.model :
	CommonFuns, CommonTypes, Config, ImportFileType, ImportOrExport, ImportOrExportKind, Module, Program;
import model.parseDiag : ParseDiag;
import frontend.check.check : BootstrapCheck, check, checkBootstrap, FileAndAst, ImportOrExportFile, ImportsAndExports;
import frontend.config : getConfig;
import frontend.diagnosticsBuilder : addDiagnosticsForFile, DiagnosticsBuilder, finishDiagnostics;
import frontend.parse.ast :
	emptyFileAst, FileAst, ImportOrExportAst, ImportOrExportAstKind, ImportsOrExportsAst;
import frontend.lang : crowExtension;
import frontend.parse.parse : parseFile;
import frontend.programState : ProgramState;
import util.alloc.alloc : Alloc;
import util.col.arr : empty;
import util.col.arrBuilder : add, ArrBuilder, arrBuilderSize, finishArr;
import util.col.arrUtil : contains, copyArr, map, mapOp, mapOrNone, mapWithSoFar, prepend;
import util.col.map : mapValues;
import util.col.enumMap : EnumMap, enumMapMapValues;
import util.col.fullIndexMap : asArray, FullIndexMap, fullIndexMapOfArr;
import util.col.mutMaxArr : isEmpty, mustPeek, mustPop, MutMaxArr, mutMaxArr, push;
import util.col.mutMap : addToMutMap, getAt_mut, hasKey_mut, moveToMap, mustGetAt_mut, MutMap, setInMap;
import util.conv : safeToUshort;
import util.late : late, Late, lateGet, lateIsSet, lateSet;
import util.lineAndColumnGetter : LineAndColumnGetter, lineAndColumnGetterForEmptyFile, lineAndColumnGetterForText;
import util.opt : force, has, Opt, none, some;
import util.perf : Perf, PerfMeasure, withMeasure;
import util.storage :
	asOption, asSafeCStr, copyFileContent, emptyFileContent, FileContent, ReadFileResult, Storage, withFileContent;
import util.sourceRange : FileIndex, RangeWithinFile;
import util.sym : AllSymbols, Sym, sym;
import util.union_ : Union;
import util.uri :
	addExtension,
	addExtensionIfNone,
	AllUris,
	childUri,
	concatUriAndPath,
	firstAndRest,
	parentOrEmpty,
	Path,
	Uri,
	UriAndRange,
	Uri,
	PathFirstAndRest,
	RelPath,
	resolveUri;
import util.util : verify;

Program frontendCompile(
	ref Alloc modelAlloc,
	ref Perf perf,
	ref Alloc astsAlloc,
	ref AllSymbols allSymbols,
	ref AllUris allUris,
	scope ref Storage storage,
	in Uri includeDir,
	in Uri[] rootUris,
	in Opt!Uri mainUri,
) {
	DiagnosticsBuilder diagsBuilder = DiagnosticsBuilder();
	Config config = getConfig(modelAlloc, allSymbols, allUris, includeDir, storage, diagsBuilder, rootUris);
	ParsedEverything parsed = withMeasure!(ParsedEverything, () => parseEverything(
		modelAlloc, astsAlloc, perf, allSymbols, allUris, diagsBuilder, storage, rootUris, mainUri, config)
	)(astsAlloc, perf, PerfMeasure.parseEverything);
	return withMeasure!(Program, () =>
		checkEverything(
			modelAlloc, perf, allSymbols, allUris, diagsBuilder,
			config, parsed.asts, parsed.filesInfo, parsed.commonModuleIndices)
	)(modelAlloc, perf, PerfMeasure.checkEverything);
}

// The purpose of this is to discover unknown files
void parseAllFiles(
	ref Alloc alloc,
	ref Perf perf,
	ref AllSymbols allSymbols,
	ref AllUris allUris,
	scope ref Storage storage,
	in Uri includeDir,
	in Uri[] rootUris,
) {
	DiagnosticsBuilder diagsBuilder = DiagnosticsBuilder();
	Config config = getConfig(alloc, allSymbols, allUris, includeDir, storage, diagsBuilder, rootUris);
	cast(void) parseEverything(
		alloc, alloc,perf, allSymbols, allUris, diagsBuilder, storage, rootUris, none!Uri, config);
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
	ref AllUris allUris,
	scope ref Storage storage,
	Uri uri,
) =>
	// In this case model alloc and AST alloc are the same
	withFileContent!FileAstAndDiagnostics(storage, uri, (in ReadFileResult fileContent) {
		ArrBuilder!DiagnosticWithinFile diags;
		FileAst ast = parseSingle(
			alloc,
			alloc,
			perf,
			allUris,
			allSymbols,
			diags,
			none!UriAndRange,
			fileContent);
		DiagnosticsBuilder diagsBuilder;
		addDiagnosticsForFile(alloc, diagsBuilder, FileIndex(0), diags);
		FilesInfo filesInfo =
			filesInfoForSingle(alloc, uri, lineAndColumnGetterForOptText(alloc, asOption(fileContent)));
		return FileAstAndDiagnostics(
			ast,
			filesInfo,
			finishDiagnostics(alloc, diagsBuilder, allUris, filesInfo.fileUris));
	});

private:

immutable struct ParseStatus {
	immutable struct Started {}
	immutable struct Done { FileIndex fileIndex; }
	mixin Union!(Started, Done);
}

alias UriToStatus = MutMap!(Uri, ParseStatus);

immutable struct ParsedEverything {
	FilesInfo filesInfo;
	CommonModuleIndices commonModuleIndices;
	FullIndexMap!(FileIndex, AstAndResolvedImports) asts;
}

immutable struct CommonModuleIndices {
	Opt!FileIndex main;
	EnumMap!(CommonModule, FileIndex) common;
	FileIndex[] rootUris;
}

struct ParseStackEntry {
	immutable Uri uri;
	immutable FileAst ast;
	immutable LineAndColumnGetter lineAndColumnGetter;
	immutable ResolvedImportsAndExports importsAndExports;
	ArrBuilder!DiagnosticWithinFile diags;
}

alias ParseStack = MutMaxArr!(32, ParseStackEntry);

ParsedEverything parseEverything(
	ref Alloc modelAlloc,
	ref Alloc astAlloc,
	scope ref Perf perf,
	ref AllSymbols allSymbols,
	ref AllUris allUris,
	scope ref DiagnosticsBuilder diagsBuilder,
	scope ref Storage storage,
	in Uri[] rootUris,
	in Opt!Uri mainUri,
	ref Config config,
) {
	if (has(mainUri))
		verify(contains(rootUris, force(mainUri)));

	ArrBuilder!Uri fileIndexToUri;
	UriToStatus statuses;
	ArrBuilder!AstAndResolvedImports res;
	LineAndColumnGettersBuilder lineAndColumnGetters;

	ParseStack stack = mutMaxArr!(32, ParseStackEntry)();

	Opt!(FullyResolvedImport[]) resolveImportsOrExports(
		ref ArrBuilder!DiagnosticWithinFile diags,
		Uri fromUri,
		ResolvedImport[] importsOrExports,
	) {
		return mapOrNone!(FullyResolvedImport, ResolvedImport)(
			modelAlloc, importsOrExports, (in ResolvedImport import_) =>
				fullyResolveImport(
					modelAlloc, astAlloc, perf, allSymbols, allUris, storage, config,
					statuses, stack, diags, fromUri, import_));
	}

	void process() {
		while (!isEmpty(stack)) {
			Uri uri = mustPeek(stack).uri;
			ResolvedImportsAndExports importsAndExports = mustPeek(stack).importsAndExports;
			Opt!(FullyResolvedImport[]) imports =
				resolveImportsOrExports(mustPeek(stack).diags, uri, importsAndExports.imports);
			Opt!(FullyResolvedImport[]) exports = has(imports)
				? resolveImportsOrExports(mustPeek(stack).diags, uri, importsAndExports.exports)
				: none!(FullyResolvedImport[]);
			if (has(exports)) {
				ParseStackEntry entry = mustPop(stack);
				FileIndex fileIndex = FileIndex(safeToUshort(arrBuilderSize(res)));

				addDiagnosticsForFile(modelAlloc, diagsBuilder, fileIndex, entry.diags);
				verify(arrBuilderSize(fileIndexToUri) == fileIndex.index);
				verify(arrBuilderSize(lineAndColumnGetters) == fileIndex.index);
				add(astAlloc, res, AstAndResolvedImports(entry.ast, force(imports), force(exports)));
				add(modelAlloc, fileIndexToUri, uri);
				add(modelAlloc, lineAndColumnGetters, entry.lineAndColumnGetter);
				setInMap(astAlloc, statuses, uri, ParseStatus(ParseStatus.Done(fileIndex)));
			}
			// else, we just pushed a dependency to the stack, so repeat.
		}
	}

	void processRootUri(Uri uri) {
		if (!hasKey_mut(statuses, uri)) {
			pushIt(
				modelAlloc, astAlloc, perf, allSymbols, allUris, storage, config,
				statuses, stack, uri, none!UriAndRange);
			process();
		}
	}

	immutable EnumMap!(CommonModule, Uri) commonUris = commonUris(allUris, config.crowIncludeDir);
	foreach (Uri uri; commonUris)
		processRootUri(uri);
	foreach (Uri uri; rootUris)
		processRootUri(uri);

	verify(isEmpty(stack));

	FileIndex getIndex(Uri uri) {
		return mustGetAt_mut(statuses, uri).as!(ParseStatus.Done).fileIndex;
	}

	CommonModuleIndices commonModuleIndices = CommonModuleIndices(
		has(mainUri) ? some(getIndex(force(mainUri))) : none!FileIndex,
		enumMapMapValues!(CommonModule, FileIndex, Uri)(commonUris, (in Uri uri) => getIndex(uri)),
		map(modelAlloc, rootUris, (ref Uri uri) => getIndex(uri)));

	return ParsedEverything(
		FilesInfo(
			fullIndexMapOfArr!(FileIndex, Uri)(finishArr(modelAlloc, fileIndexToUri)),
			mapValues!(Uri, FileIndex, ParseStatus)(
				modelAlloc,
				moveToMap!(Uri, ParseStatus)(astAlloc, statuses),
				(Uri _, ref ParseStatus x) =>
					x.as!(ParseStatus.Done).fileIndex),
			fullIndexMapOfArr!(FileIndex, LineAndColumnGetter)(finishArr(modelAlloc, lineAndColumnGetters))),
		commonModuleIndices,
		fullIndexMapOfArr!(FileIndex, AstAndResolvedImports)(finishArr(astAlloc, res)));
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

void pushIt(
	ref Alloc modelAlloc,
	ref Alloc astAlloc,
	scope ref Perf perf,
	ref AllSymbols allSymbols,
	ref AllUris allUris,
	scope ref Storage storage,
	in Config config,
	ref UriToStatus statuses,
	ref ParseStack stack,
	Uri uri,
	Opt!UriAndRange importedFrom,
) {
	withFileContent!void(storage, uri, (in ReadFileResult x) {
		ArrBuilder!DiagnosticWithinFile diags;
		LineAndColumnGetter lineAndColumnGetter = lineAndColumnGetterForOptText(modelAlloc, asOption(x));
		FileAst ast = parseSingle(modelAlloc, astAlloc, perf, allUris, allSymbols, diags, importedFrom, x);
		ResolvedImportsAndExports importsAndExports = resolveImportsAndExports(
			modelAlloc, astAlloc, allUris, diags, config, uri, ast.imports, ast.exports);
		addToMutMap(astAlloc, statuses, uri, ParseStatus(ParseStatus.Started()));
		push(stack, ParseStackEntry(uri, ast, lineAndColumnGetter, importsAndExports, diags));
	});
}

// returns none if we can't resolve all imported modules yet
Opt!FullyResolvedImport fullyResolveImport(
	ref Alloc modelAlloc,
	ref Alloc astAlloc,
	scope ref Perf perf,
	ref AllSymbols allSymbols,
	ref AllUris allUris,
	scope ref Storage storage,
	in Config config,
	ref UriToStatus statuses,
	ref ParseStack stack,
	ref ArrBuilder!DiagnosticWithinFile diags,
	Uri fromUri,
	in ResolvedImport import_,
) {
	Opt!FullyResolvedImportKind kind = has(import_.resolvedUri)
		? fullyResolveImportKind(
			modelAlloc, astAlloc, perf, allSymbols, allUris, storage, config, statuses, stack, diags, fromUri,
			import_, force(import_.resolvedUri))
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
	ref AllUris allUris,
	scope ref Storage storage,
	in Config config,
	ref UriToStatus statuses,
	ref ParseStack stack,
	ref ArrBuilder!DiagnosticWithinFile diags,
	Uri fromUri,
	in ResolvedImport import_,
	Uri resolvedUri,
) =>
	import_.kind.matchIn!(Opt!FullyResolvedImportKind)(
		(in ImportOrExportAstKind.ModuleWhole) =>
			fullyResolveImportModule(
				modelAlloc, astAlloc, perf, allSymbols, allUris, storage, config, statuses, stack, diags, fromUri,
				import_.importedFrom, resolvedUri,
				(FileIndex f) =>
					FullyResolvedImportKind(FullyResolvedImportKind.ModuleWhole(f))),
		(in Sym[] names) =>
			fullyResolveImportModule(
				modelAlloc, astAlloc, perf, allSymbols, allUris, storage, config, statuses, stack, diags, fromUri,
				import_.importedFrom, resolvedUri,
				(FileIndex f) =>
					FullyResolvedImportKind(FullyResolvedImportKind.ModuleNamed(f, copyArr(modelAlloc, names)))),
		(in ImportOrExportAstKind.File f) =>
			some(FullyResolvedImportKind(
				FullyResolvedImportKind.File(
					f.name,
					f.type,
					readFileContent(
						modelAlloc, diags, storage,
						some(UriAndRange(fromUri, import_.importedFrom)),
						resolvedUri)))));

FileContent readFileContent(
	ref Alloc modelAlloc,
	ref ArrBuilder!DiagnosticWithinFile diags,
	scope ref Storage storage,
	Opt!UriAndRange importedFrom,
	Uri uri,
) =>
	withFileContent!FileContent(storage, uri, (in ReadFileResult x) =>
		handleReadFileResult!FileContent(modelAlloc, diags, importedFrom, x,
			(in FileContent content) => copyFileContent(modelAlloc, content),
			() => emptyFileContent(modelAlloc)));

Opt!FullyResolvedImportKind fullyResolveImportModule(
	ref Alloc modelAlloc,
	ref Alloc astAlloc,
	scope ref Perf perf,
	ref AllSymbols allSymbols,
	ref AllUris allUris,
	scope ref Storage storage,
	in Config config,
	ref UriToStatus statuses,
	ref ParseStack stack,
	ref ArrBuilder!DiagnosticWithinFile diags,
	Uri fromUri,
	RangeWithinFile importedFrom,
	Uri importUri,
	in FullyResolvedImportKind delegate(FileIndex) @safe @nogc pure nothrow getSuccessKind,
) {
	Opt!ParseStatus status = getAt_mut!(Uri, ParseStatus)(statuses, importUri);
	if (has(status))
		return some(force(status).match!FullyResolvedImportKind(
			(ParseStatus.Started) {
				add(modelAlloc, diags, DiagnosticWithinFile(
					importedFrom,
					Diag(ParseDiag(ParseDiag.CircularImport(fromUri, importUri)))));
				return FullyResolvedImportKind(FullyResolvedImportKind.Failed());
			},
			(ParseStatus.Done x) =>
				getSuccessKind(x.fileIndex)));
	else {
		pushIt(
			modelAlloc, astAlloc, perf, allSymbols, allUris, storage, config, statuses, stack, importUri,
			some(UriAndRange(fromUri, importedFrom)));
		return none!FullyResolvedImportKind;
	}
}

pure:

alias LineAndColumnGettersBuilder = ArrBuilder!LineAndColumnGetter;

LineAndColumnGetter lineAndColumnGetterForOptText(ref Alloc modelAlloc, in Opt!FileContent opFileContent) =>
	has(opFileContent)
		? lineAndColumnGetterForText(modelAlloc, asSafeCStr(force(opFileContent)))
		: lineAndColumnGetterForEmptyFile(modelAlloc);

FileAst parseSingle(
	ref Alloc modelAlloc,
	ref Alloc astAlloc,
	scope ref Perf perf,
	ref AllUris allUris,
	ref AllSymbols allSymbols,
	ref ArrBuilder!DiagnosticWithinFile diags,
	in Opt!UriAndRange importedFrom,
	in ReadFileResult fileContent,
) =>
	handleReadFileResult!FileAst(
		modelAlloc,
		diags,
		importedFrom,
		fileContent,
		(in FileContent content) => parseFile(astAlloc, perf, allUris, allSymbols, diags, content.asSafeCStr()),
		() => emptyFileAst);

T handleReadFileResult(T)(
	ref Alloc modelAlloc,
	ref ArrBuilder!DiagnosticWithinFile diags,
	in Opt!UriAndRange importedFrom,
	in ReadFileResult result,
	in T delegate(in FileContent) @safe @nogc pure nothrow cbSuccess,
	in T delegate() @safe @nogc pure nothrow cbFail,
) =>
	result.matchIn!T(
		(in immutable FileContent content) =>
			cbSuccess(content),
		(in ReadFileResult.NotFound) {
			add(modelAlloc, diags, DiagnosticWithinFile(RangeWithinFile.empty, Diag(
				ParseDiag(ParseDiag.FileDoesNotExist(importedFrom)))));
			return cbFail();
		},
		(in ReadFileResult.Error) {
			add(modelAlloc, diags, DiagnosticWithinFile(RangeWithinFile.empty, Diag(
				ParseDiag(ParseDiag.FileReadError(importedFrom)))));
			return cbFail();
		},
		(in ReadFileResult.Unknown) {
			add(modelAlloc, diags, DiagnosticWithinFile(RangeWithinFile.empty, Diag(
				ParseDiag(ParseDiag.FileLoading(importedFrom)))));
			return cbFail();
		});

immutable struct ResolvedImport {
	// This is arbitrarily the first module we saw to import this.
	// This is just used for error reporting in case the file can't be read.
	RangeWithinFile importedFrom;
	Opt!Uri resolvedUri;
	ImportOrExportAstKind kind;
}

ResolvedImport tryResolveImport(
	ref Alloc modelAlloc,
	ref AllUris allUris,
	ref ArrBuilder!DiagnosticWithinFile diagnosticsBuilder,
	in Config config,
	Uri fromUri,
	in ImportOrExportAst ast,
) {
	ResolvedImport resolved(Uri uri) {
		return ResolvedImport(ast.range, some(addExtensionIfNone!crowExtension(allUris, uri)), ast.kind);
	}
	return ast.path.match!ResolvedImport(
		(Path global) {
			PathFirstAndRest fr = firstAndRest(allUris, global);
			Opt!Uri fromConfig = config.include[fr.first];
			return resolved(has(fromConfig)
				? has(fr.rest) ? concatUriAndPath(allUris, force(fromConfig), force(fr.rest)) : force(fromConfig)
				: concatUriAndPath(allUris, config.crowIncludeDir, global));
		},
		(RelPath relPath) {
			Opt!Uri rel = resolveUri(allUris, parentOrEmpty(allUris, fromUri), relPath);
			if (has(rel))
				return resolved(force(rel));
			else {
				add(modelAlloc, diagnosticsBuilder, DiagnosticWithinFile(ast.range, Diag(
					ParseDiag(ParseDiag.RelativeImportReachesPastRoot(relPath)))));
				return ResolvedImport(ast.range, none!Uri, ast.kind);
			}
		});
}

immutable struct ResolvedImportsAndExports {
	ResolvedImport[] imports;
	ResolvedImport[] exports;
}

ResolvedImport[] resolveImportOrExportUris(
	ref Alloc modelAlloc,
	ref Alloc astAlloc,
	ref AllUris allUris,
	ref ArrBuilder!DiagnosticWithinFile diagnosticsBuilder,
	in Config config,
	Uri fromUri,
	in Opt!ImportsOrExportsAst importsOrExports,
) =>
	map(astAlloc, has(importsOrExports) ? force(importsOrExports).paths : [], (ref ImportOrExportAst i) =>
		tryResolveImport(modelAlloc, allUris, diagnosticsBuilder, config, fromUri, i));

ResolvedImportsAndExports resolveImportsAndExports(
	ref Alloc modelAlloc,
	ref Alloc astAlloc,
	ref AllUris allUris,
	ref ArrBuilder!DiagnosticWithinFile diagnosticsBuilder,
	in Config config,
	Uri fromUri,
	in Opt!ImportsOrExportsAst imports,
	in Opt!ImportsOrExportsAst exports,
) =>
	ResolvedImportsAndExports(
		resolveImportOrExportUris(
			modelAlloc, astAlloc, allUris, diagnosticsBuilder, config, fromUri, imports),
		resolveImportOrExportUris(
			modelAlloc, astAlloc, allUris, diagnosticsBuilder, config, fromUri, exports));

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
	in FullyResolvedImport[] uris,
	in FullIndexMap!(FileIndex, Module) compiled,
) {
	ArrBuilder!ImportOrExportFile fileImports;
	ImportOrExport[] moduleImports = mapOp!(ImportOrExport, FullyResolvedImport)(
		modelAlloc,
		uris,
		(ref FullyResolvedImport x) {
			Opt!ImportOrExportKind kind = x.kind.match!(Opt!ImportOrExportKind)(
				(FullyResolvedImportKind.ModuleWhole m) =>
					m.fileIndex == FileIndex.none
						? none!ImportOrExportKind
						: some(ImportOrExportKind(ImportOrExportKind.ModuleWhole(&compiled[m.fileIndex]))),
				(FullyResolvedImportKind.ModuleNamed m) =>
					m.fileIndex == FileIndex.none
						? none!ImportOrExportKind
						: some(ImportOrExportKind(ImportOrExportKind.ModuleNamed(&compiled[m.fileIndex], m.names))),
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
	in FullIndexMap!(FileIndex, AstAndResolvedImports) fileAsts,
) {
	Late!CommonTypes commonTypes = late!CommonTypes;
	Module[] modules = mapWithSoFar!(Module, AstAndResolvedImports)(
		modelAlloc,
		asArray(fileAsts),
		(in AstAndResolvedImports ast, in Module[] soFar, size_t index) {
			immutable FullIndexMap!(FileIndex, Module) compiled = fullIndexMapOfArr!(FileIndex, Module)(soFar);
			FileAndAst fileAndAst = FileAndAst(FileIndex(safeToUshort(index)), ast.ast);
			if (lateIsSet(commonTypes))
				return checkNonBootstrapModule(
					modelAlloc, perf, allSymbols, diagsBuilder, programState, stdIndex,
					ast, compiled, fileAndAst, lateGet(commonTypes));
			else {
				// The first module to check is always 'bootstrap.crow'
				verify(ast.resolvedImports.empty);
				BootstrapCheck res =
					checkBootstrap(modelAlloc, perf, allSymbols, diagsBuilder, programState, fileAndAst);
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
	in FullIndexMap!(FileIndex, Module) compiled,
	in FileAndAst fileAndAst,
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
	return check(modelAlloc, perf, allSymbols, diagsBuilder, programState, importsAndExports, fileAndAst, commonTypes);
}

Program checkEverything(
	ref Alloc modelAlloc,
	ref Perf perf,
	ref AllSymbols allSymbols,
	in AllUris allUris,
	ref DiagnosticsBuilder diagsBuilder,
	Config config,
	in FullIndexMap!(FileIndex, AstAndResolvedImports) allAsts,
	ref FilesInfo filesInfo,
	in CommonModuleIndices moduleIndices,
) {
	ProgramState programState = ProgramState();
	ModulesAndCommonTypes modulesAndCommonTypes = getModules(
		modelAlloc, perf, allSymbols, diagsBuilder, programState, moduleIndices.common[CommonModule.std], allAsts);
	Module[] modules = modulesAndCommonTypes.modules;
	immutable EnumMap!(CommonModule, Module*) commonModules =
		enumMapMapValues!(CommonModule, Module*, FileIndex)(moduleIndices.common, (in FileIndex index) =>
			&modules[index.index]);
	CommonFuns commonFuns = getCommonFuns(
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
		map!(Module*, FileIndex)(modelAlloc, moduleIndices.rootUris, (ref FileIndex index) =>
			&modules[index.index]),
		commonFuns,
		modulesAndCommonTypes.commonTypes,
		finishDiagnostics(modelAlloc, diagsBuilder, allUris, filesInfo.fileUris));
}
