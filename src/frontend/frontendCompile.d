module frontend.frontendCompile;

@safe @nogc pure nothrow:

import model.diag : Diag, Diagnostics;
import model.model :
	CommonFuns, CommonTypes, Config, emptyModule, ImportFileType, ImportOrExport, ImportOrExportKind, Module, Program;
import model.parseDiag : ParseDiag;
import frontend.check.check : BootstrapCheck, check, checkBootstrap, FileAndAst, ImportOrExportFile, ImportsAndExports;
import frontend.check.getCommonFuns : CommonModule, getCommonFuns;
import frontend.config : getConfig;
import frontend.diagnosticsBuilder :
	addDiagnostic, addDiagnosticForFile, DiagnosticsBuilder, DiagnosticsBuilderForFile, finishDiagnostics;
import frontend.lang : crowExtension;
import frontend.parse.ast :
	FileAst, ImportOrExportAst, ImportOrExportAstKind, ImportsOrExportsAst, NameAndRange, pathRange;
import frontend.parse.parse : parseFile;
import frontend.programState : ProgramState;
import util.alloc.alloc : Alloc;
import util.col.arr : empty;
import util.col.arrBuilder : add, ArrBuilder, finishArr;
import util.col.arrUtil : contains, map, mapOp, mapOrNone, mapPointers, prepend;
import util.col.map : Map;
import util.col.enumMap : EnumMap, enumMapEach, enumMapMapValues;
import util.col.mutMaxArr : isEmpty, mustPeek, mustPop, MutMaxArr, mutMaxArr, push;
import util.col.mutMap : addToMutMap, getAt_mut, hasKey_mut, moveToMap, MutMap, setInMap;
import util.late : late, Late, lateGet, lateIsSet, lateSet;
import util.memory : allocate;
import util.opt : force, has, Opt, none, some;
import util.perf : Perf, PerfMeasure, withMeasure;
import util.ptr : ptrTrustMe;
import util.storage : asSafeCStr, emptyFileContent, FileContent, ReadFileIssue, ReadFileResult, Storage, withFile;
import util.sourceRange : Range, UriAndRange;
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
	Uri,
	PathFirstAndRest,
	RelPath,
	resolveUri;
import util.util : todo, verify;

Program frontendCompile(
	ref Alloc modelAlloc,
	ref Perf perf,
	ref Alloc astsAlloc,
	scope ref AllSymbols allSymbols,
	scope ref AllUris allUris,
	scope ref Storage storage,
	in Uri includeDir,
	in Uri[] rootUris,
	in Opt!Uri mainUri,
) {
	DiagnosticsBuilder diagsBuilder = DiagnosticsBuilder(&modelAlloc);
	Config config = getConfig(modelAlloc, allSymbols, allUris, includeDir, storage, diagsBuilder, rootUris);
	EnumMap!(CommonModule, Uri) commonUris = commonUris(allUris, config.crowIncludeDir);
	AstAndResolvedImports[] parsed = withMeasure!(AstAndResolvedImports[], () => parseEverything(
		modelAlloc, astsAlloc, perf, allSymbols, allUris, diagsBuilder, storage, rootUris, mainUri, commonUris, config)
	)(astsAlloc, perf, PerfMeasure.parseEverything);
	return withMeasure!(Program, () =>
		checkEverything(
			modelAlloc, perf, allSymbols, allUris, diagsBuilder, config, parsed, rootUris, mainUri, commonUris)
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
	DiagnosticsBuilder diagsBuilder = DiagnosticsBuilder(&alloc); // Diagnostics will be ignored
	Config config = getConfig(alloc, allSymbols, allUris, includeDir, storage, diagsBuilder, rootUris);
	cast(void) parseEverything(
		alloc, alloc, perf, allSymbols, allUris, diagsBuilder, storage,
		rootUris, none!Uri, commonUris(allUris, config.crowIncludeDir), config);
}

immutable struct FileAstAndDiagnostics {
	FileAst ast;
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
	withFile!FileAstAndDiagnostics(storage, uri, (in ReadFileResult x) =>
		x.matchIn!FileAstAndDiagnostics(
			(in FileContent content) {
				DiagnosticsBuilder diagsBuilder = DiagnosticsBuilder(&alloc);
				DiagnosticsBuilderForFile diags = DiagnosticsBuilderForFile(&diagsBuilder, uri);
				FileAst ast = parseFile(alloc, perf, allSymbols, allUris, diags, content.asSafeCStr());
				return FileAstAndDiagnostics(ast, finishDiagnostics(diagsBuilder, allUris));
			},
			(in ReadFileIssue issue) =>
				todo!FileAstAndDiagnostics("parseSingleAst with file issue")));

private:

immutable struct ParseStatus {
	immutable struct Started {}
	immutable struct Done {}
	mixin Union!(Started, Done, ReadFileIssue);
}

alias UriToStatus = MutMap!(Uri, ParseStatus);

struct ParseStackEntry {
	immutable Uri uri;
	immutable FileAst ast;
	immutable ResolvedImportsAndExports importsAndExports;
}

alias ParseStack = MutMaxArr!(32, ParseStackEntry);

AstAndResolvedImports[] parseEverything(
	ref Alloc modelAlloc,
	ref Alloc astAlloc,
	scope ref Perf perf,
	scope ref AllSymbols allSymbols,
	scope ref AllUris allUris,
	scope ref DiagnosticsBuilder diags,
	scope ref Storage storage,
	in Uri[] rootUris,
	in Opt!Uri mainUri,
	EnumMap!(CommonModule, Uri) commonUris,
	ref Config config,
) {
	verify(!empty(rootUris));
	if (has(mainUri))
		verify(contains(rootUris, force(mainUri)));

	UriToStatus statuses;
	ArrBuilder!AstAndResolvedImports res;

	ParseStack stack = mutMaxArr!(32, ParseStackEntry)();

	Opt!(FullyResolvedImport[]) resolveImportsOrExports(
		Uri fromUri,
		ResolvedImport[] importsOrExports,
	) {
		return mapOrNone!(FullyResolvedImport, ResolvedImport)(
			modelAlloc, importsOrExports, (ref ResolvedImport import_) =>
				fullyResolveImport(
					modelAlloc, astAlloc, perf, allSymbols, allUris, storage, diags, config,
					statuses, stack, fromUri, import_));
	}

	void process() {
		while (!isEmpty(stack)) {
			Uri uri = mustPeek(stack).uri;
			ResolvedImportsAndExports importsAndExports = mustPeek(stack).importsAndExports;
			Opt!(FullyResolvedImport[]) imports = resolveImportsOrExports(uri, importsAndExports.imports);
			Opt!(FullyResolvedImport[]) exports = has(imports)
				? resolveImportsOrExports(uri, importsAndExports.exports)
				: none!(FullyResolvedImport[]);
			if (has(exports)) {
				ParseStackEntry entry = mustPop(stack);
				add(astAlloc, res, AstAndResolvedImports(uri, entry.ast, force(imports), force(exports)));
				setInMap(astAlloc, statuses, uri, ParseStatus(ParseStatus.Done()));
			}
			// else, we just pushed a dependency to the stack, so repeat.
		}
	}

	void processRootUri(Uri uri) {
		if (!hasKey_mut(statuses, uri)) {
			parseAndPush(modelAlloc, astAlloc, perf, allSymbols, allUris, storage, diags, config, statuses, stack, uri);
			process();
		}
	}

	enumMapEach!(CommonModule, Uri)(commonUris, (CommonModule _, in Uri uri) {
		processRootUri(uri);
	});
	foreach (Uri uri; rootUris)
		processRootUri(uri);

	verify(isEmpty(stack));
	return finishArr(astAlloc, res);
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

void parseAndPush(
	ref Alloc modelAlloc,
	ref Alloc astAlloc,
	scope ref Perf perf,
	scope ref AllSymbols allSymbols,
	scope ref AllUris allUris,
	scope ref Storage storage,
	scope ref DiagnosticsBuilder diags,
	in Config config,
	scope ref UriToStatus statuses,
	ref ParseStack stack,
	Uri uri,
) {
	withFile!void(storage, uri, (in ReadFileResult x) {
		ParseStatus status = x.match!ParseStatus(
			(FileContent x) {
				DiagnosticsBuilderForFile fileDiags = DiagnosticsBuilderForFile(ptrTrustMe(diags), uri);
				FileAst ast = parseFile(astAlloc, perf, allSymbols, allUris, fileDiags, x.asSafeCStr());
				ResolvedImportsAndExports importsAndExports = resolveImportsAndExports(
					modelAlloc, astAlloc, allUris, fileDiags, config, uri, ast.imports, ast.exports);
				push(stack, ParseStackEntry(uri, ast, importsAndExports));
				return ParseStatus(ParseStatus.Started());
			},
			(ReadFileIssue issue) {
				addDiagnostic(diags, UriAndRange(uri, Range.empty), Diag(Diag.FileIssue(uri, issue)));
				return ParseStatus(issue);
			});
		addToMutMap(astAlloc, statuses, uri, status);
	});
}

// returns none if we can't resolve all imported modules yet
Opt!FullyResolvedImport fullyResolveImport(
	ref Alloc modelAlloc,
	ref Alloc astAlloc,
	scope ref Perf perf,
	scope ref AllSymbols allSymbols,
	scope ref AllUris allUris,
	scope ref Storage storage,
	scope ref DiagnosticsBuilder diags,
	in Config config,
	ref UriToStatus statuses,
	ref ParseStack stack,
	Uri fromUri,
	ResolvedImport import_,
) {
	Opt!FullyResolvedImportKind kind = has(import_.resolvedUri)
		? fullyResolveImportKind(
			modelAlloc, astAlloc, perf, allSymbols, allUris, storage, diags, config, statuses, stack, fromUri,
			import_, force(import_.resolvedUri))
		: some(FullyResolvedImportKind(FullyResolvedImportKind.Failed()));
	return has(kind)
		? some(FullyResolvedImport(some(import_.ast), force(kind)))
		: none!FullyResolvedImport;
}

Opt!FullyResolvedImportKind fullyResolveImportKind(
	ref Alloc modelAlloc,
	ref Alloc astAlloc,
	scope ref Perf perf,
	scope ref AllSymbols allSymbols,
	scope ref AllUris allUris,
	scope ref Storage storage,
	scope ref DiagnosticsBuilder diags,
	in Config config,
	scope ref UriToStatus statuses,
	ref ParseStack stack,
	Uri fromUri,
	in ResolvedImport import_,
	Uri resolvedUri,
) =>
	import_.ast.kind.matchIn!(Opt!FullyResolvedImportKind)(
		(in ImportOrExportAstKind.ModuleWhole) =>
			fullyResolveImportModule(
				modelAlloc, astAlloc, perf, allSymbols, allUris, storage, diags, config, statuses, stack, fromUri,
				*import_.ast, resolvedUri,
				(Uri uri) =>
					FullyResolvedImportKind(FullyResolvedImportKind.ModuleWhole(uri))),
		(in NameAndRange[] names) =>
			fullyResolveImportModule(
				modelAlloc, astAlloc, perf, allSymbols, allUris, storage, diags, config, statuses, stack, fromUri,
				*import_.ast, resolvedUri,
				(Uri uri) =>
					FullyResolvedImportKind(FullyResolvedImportKind.ModuleNamed(
						uri,
						map(modelAlloc, names, (ref NameAndRange name) => name.name)))),
		(in ImportOrExportAstKind.File f) =>
			some(FullyResolvedImportKind(FullyResolvedImportKind.File(
				f.name.name,
				f.type,
				readFileContent(modelAlloc, allUris, storage, diags, fromUri, *import_.ast, resolvedUri)))));

FileContent readFileContent(
	ref Alloc modelAlloc,
	in AllUris allUris,
	scope ref Storage storage,
	scope ref DiagnosticsBuilder diags,
	Uri fromUri,
	in ImportOrExportAst ast,
	Uri uri,
) =>
	withFile!FileContent(storage, uri, (in ReadFileResult x) =>
		x.matchIn!FileContent(
			(in FileContent content) =>
				content,
			(in ReadFileIssue issue) {
				addDiagnostic(diags, importDiagRange(allUris, fromUri, ast), Diag(Diag.FileIssue(uri, issue)));
				return emptyFileContent(modelAlloc);
			}));

Opt!FullyResolvedImportKind fullyResolveImportModule(
	ref Alloc modelAlloc,
	ref Alloc astAlloc,
	scope ref Perf perf,
	scope ref AllSymbols allSymbols,
	scope ref AllUris allUris,
	scope ref Storage storage,
	scope ref DiagnosticsBuilder diags,
	in Config config,
	scope ref UriToStatus statuses,
	ref ParseStack stack,
	Uri fromUri,
	in ImportOrExportAst ast,
	Uri importUri,
	in FullyResolvedImportKind delegate(Uri) @safe @nogc pure nothrow getSuccessKind,
) {
	Opt!ParseStatus status = getAt_mut!(Uri, ParseStatus)(statuses, importUri);
	if (has(status))
		return some(force(status).match!FullyResolvedImportKind(
			(ParseStatus.Started) {
				addDiagnostic(diags, importDiagRange(allUris, fromUri, ast), Diag(
					ParseDiag(ParseDiag.CircularImport(fromUri, importUri))));
				return FullyResolvedImportKind(FullyResolvedImportKind.Failed());
			},
			(ParseStatus.Done x) =>
				getSuccessKind(importUri),
			(ReadFileIssue issue) {
				addDiagnostic(diags, importDiagRange(allUris, fromUri, ast), Diag(Diag.FileIssue(importUri, issue)));
				return FullyResolvedImportKind(FullyResolvedImportKind.Failed());
			}));
	else {
		parseAndPush(
			modelAlloc, astAlloc, perf, allSymbols, allUris, storage, diags, config, statuses, stack, importUri);
		return none!FullyResolvedImportKind;
	}
}

UriAndRange importDiagRange(in AllUris allUris, Uri uri, in ImportOrExportAst ast) =>
	UriAndRange(uri, pathRange(allUris, ast));

immutable struct ResolvedImport {
	ImportOrExportAst* ast;
	Opt!Uri resolvedUri;
}

ResolvedImport tryResolveImport(
	ref Alloc modelAlloc,
	scope ref AllUris allUris,
	scope ref DiagnosticsBuilderForFile diags,
	in Config config,
	Uri fromUri,
	ImportOrExportAst* ast,
) {
	ResolvedImport resolved(Uri uri) =>
		ResolvedImport(ast, some(addExtensionIfNone!crowExtension(allUris, uri)));
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
				addDiagnosticForFile(diags, pathRange(allUris, *ast), Diag(
					ParseDiag(ParseDiag.RelativeImportReachesPastRoot(relPath))));
				return ResolvedImport(ast, none!Uri);
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
	scope ref AllUris allUris,
	scope ref DiagnosticsBuilderForFile diagnosticsBuilder,
	in Config config,
	Uri fromUri,
	in Opt!ImportsOrExportsAst importsOrExports,
) =>
	mapPointers(astAlloc, has(importsOrExports) ? force(importsOrExports).paths : [], (ImportOrExportAst* i) =>
		tryResolveImport(modelAlloc, allUris, diagnosticsBuilder, config, fromUri, i));

ResolvedImportsAndExports resolveImportsAndExports(
	ref Alloc modelAlloc,
	ref Alloc astAlloc,
	scope ref AllUris allUris,
	scope ref DiagnosticsBuilderForFile diagnosticsBuilder,
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
	Uri uri;
	FileAst ast;
	FullyResolvedImport[] resolvedImports;
	FullyResolvedImport[] resolvedExports;
}

immutable struct FullyResolvedImport {
	// none for 'std'
	Opt!(ImportOrExportAst*) source;
	FullyResolvedImportKind kind;
}

immutable struct FullyResolvedImportKind {
	immutable struct ModuleWhole {
		Uri uri;
	}
	immutable struct ModuleNamed {
		Uri uri;
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
	ref const MutMap!(Uri, immutable Module*) compiled,
) {
	ArrBuilder!ImportOrExportFile fileImports;
	ImportOrExport[] moduleImports = mapOp!(ImportOrExport, FullyResolvedImport)(
		modelAlloc,
		uris,
		(ref FullyResolvedImport x) {
			Opt!ImportOrExportKind kind = x.kind.match!(Opt!ImportOrExportKind)(
				(FullyResolvedImportKind.ModuleWhole m) {
					Opt!(Module*) module_ = getAt_mut!(Uri, immutable Module*)(compiled, m.uri);
					return has(module_)
						? some(ImportOrExportKind(ImportOrExportKind.ModuleWhole(force(module_))))
						: none!ImportOrExportKind;
				},
				(FullyResolvedImportKind.ModuleNamed m) {
					Opt!(Module*) module_ = getAt_mut!(Uri, immutable Module*)(compiled, m.uri);
					return has(module_)
						? some(ImportOrExportKind(ImportOrExportKind.ModuleNamed(force(module_), m.names)))
						: none!ImportOrExportKind;
				},
				(FullyResolvedImportKind.File f) {
					//TODO: could be a temp alloc
					add(modelAlloc, fileImports, ImportOrExportFile(x.source, f.name, f.type, f.content));
					return none!ImportOrExportKind;
				},
				(FullyResolvedImportKind.Failed) =>
					none!ImportOrExportKind);
			return has(kind) ? some(ImportOrExport(x.source, force(kind))) : none!ImportOrExport;
	});
	return ImportsOrExports(moduleImports, finishArr(modelAlloc, fileImports));
}

struct ModulesAndCommonTypes {
	Map!(Uri, immutable Module*) modules;
	CommonTypes commonTypes;
}

ModulesAndCommonTypes getModules(
	ref Alloc modelAlloc,
	ref Perf perf,
	scope ref AllSymbols allSymbols,
	in AllUris allUris,
	scope ref DiagnosticsBuilder diagsBuilder,
	ref ProgramState programState,
	Uri stdUri,
	in AstAndResolvedImports[] fileAsts,
) {
	verify(!empty(fileAsts));
	Late!CommonTypes commonTypes = late!CommonTypes;

	MutMap!(Uri, immutable Module*) compiled;

	foreach (ref AstAndResolvedImports ast; fileAsts) {
		FileAndAst fileAndAst = FileAndAst(ast.uri, ast.ast);
		Module module_ = () {
			if (lateIsSet(commonTypes)) {
				return checkNonBootstrapModule(
					modelAlloc, perf, allSymbols, allUris, diagsBuilder, programState, stdUri,
					ast, compiled, fileAndAst, lateGet(commonTypes));
			} else {
				// The first module to check is always 'bootstrap.crow'
				verify(ast.resolvedImports.empty);
				BootstrapCheck res =
					checkBootstrap(modelAlloc, perf, allSymbols, allUris, diagsBuilder, programState, fileAndAst);
				lateSet(commonTypes, res.commonTypes);
				return res.module_;
			}
		}();
		addToMutMap(modelAlloc, compiled, ast.uri, allocate(modelAlloc, module_));
	}

	return ModulesAndCommonTypes(moveToMap!(Uri, immutable Module*)(modelAlloc, compiled), lateGet(commonTypes));
}

Module checkNonBootstrapModule(
	ref Alloc modelAlloc,
	ref Perf perf,
	scope ref AllSymbols allSymbols,
	in AllUris allUris,
	scope ref DiagnosticsBuilder diagsBuilder,
	ref ProgramState programState,
	Uri stdUri,
	in AstAndResolvedImports ast,
	ref const MutMap!(Uri, immutable Module*) compiled,
	ref FileAndAst fileAndAst,
	in CommonTypes commonTypes,
) {
	FullyResolvedImport[] allImports = ast.ast.noStd
		? ast.resolvedImports
		: prepend(
			modelAlloc,
			FullyResolvedImport(
				none!(ImportOrExportAst*),
				FullyResolvedImportKind(FullyResolvedImportKind.ModuleWhole(stdUri))),
			ast.resolvedImports);
	ImportsOrExports imports = mapImportsOrExports(modelAlloc, allImports, compiled);
	ImportsOrExports exports = mapImportsOrExports(modelAlloc, ast.resolvedExports, compiled);
	ImportsAndExports importsAndExports = ImportsAndExports(
		imports.moduleImports,
		exports.moduleImports,
		imports.fileImports,
		exports.fileImports);
	return check(
		modelAlloc, perf, allSymbols, allUris, diagsBuilder, programState, importsAndExports, fileAndAst, commonTypes);
}

Program checkEverything(
	ref Alloc modelAlloc,
	ref Perf perf,
	scope ref AllSymbols allSymbols,
	in AllUris allUris,
	scope ref DiagnosticsBuilder diagsBuilder,
	Config config,
	in AstAndResolvedImports[] allAsts,
	in Uri[] rootUris,
	in Opt!Uri mainUri,
	in EnumMap!(CommonModule, Uri) commonUris,
) {
	ProgramState programState = ProgramState();
	ModulesAndCommonTypes modulesAndCommonTypes = getModules(
		modelAlloc, perf, allSymbols, allUris, diagsBuilder, programState, commonUris[CommonModule.std], allAsts);
	Map!(Uri, immutable Module*) modules = modulesAndCommonTypes.modules;
	immutable EnumMap!(CommonModule, Opt!(Module*)) commonModules =
		enumMapMapValues!(CommonModule, Opt!(Module*), Uri)(commonUris, (in Uri uri) =>
			modules[uri]);
	CommonFuns commonFuns = getCommonFuns(
		modelAlloc,
		programState,
		diagsBuilder,
		modulesAndCommonTypes.commonTypes,
		has(mainUri) ? modules[force(mainUri)] : none!(Module*),
		commonModules);
	return Program(
		config,
		modules,
		map!(Module*, Uri)(modelAlloc, rootUris, (ref Uri uri) {
			Opt!(Module*) res = modules[uri];
			return has(res) ? force(res) : allocate(modelAlloc, emptyModule(uri));
		}),
		commonFuns,
		modulesAndCommonTypes.commonTypes,
		finishDiagnostics(diagsBuilder, allUris));
}
