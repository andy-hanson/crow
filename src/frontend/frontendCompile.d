module frontend.frontendCompile;

@safe @nogc pure nothrow:

import model.diag : Diag, Diagnostic;
import model.model :
	CommonFuns, CommonTypes, Config, emptyModule, ImportFileType, ImportOrExport, ImportOrExportKind, Module, Program;
import model.parseDiag : ParseDiag, ParseDiagnostic;
import frontend.check.check : BootstrapCheck, check, checkBootstrap, FileAndAst, ImportOrExportFile, ImportsAndExports;
import frontend.check.getCommonFuns : CommonModule, getCommonFuns;
import frontend.config : getConfig;
import frontend.lang : crowExtension;
import frontend.parse.ast :
	FileAst, ImportOrExportAst, ImportOrExportAstKind, ImportsOrExportsAst, NameAndRange, pathRange;
import frontend.parse.parse : parseFile;
import frontend.programState : ProgramState;
import util.alloc.alloc : Alloc;
import util.col.arr : empty;
import util.col.arrBuilder : add, ArrBuilder, finishArr;
import util.col.arrUtil : arrLiteral, contains, map, mapOp, mapOrNone, mapPointers, prepend;
import util.col.map : Map;
import util.col.enumMap : EnumMap, enumMapEach, enumMapMapValues;
import util.col.mutMaxArr : isEmpty, mustPeek, mustPop, MutMaxArr, mutMaxArr, push;
import util.col.mutMap : addToMutMap, getAt_mut, hasKey_mut, moveToMap, MutMap, setInMap;
import util.col.str : safeCStr;
import util.late : late, Late, lateGet, lateIsSet, lateSet;
import util.memory : allocate;
import util.opt : force, has, Opt, none, some;
import util.perf : Perf, PerfMeasure, withMeasure;
import util.storage : asSafeCStr, FileContent, ReadFileIssue, ReadFileResult, Storage, withFile;
import util.sourceRange : Range;
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
import util.util : verify;

Program frontendCompile(
	ref Alloc modelAlloc,
	scope ref Perf perf,
	ref Alloc astsAlloc,
	scope ref AllSymbols allSymbols,
	scope ref AllUris allUris,
	scope ref Storage storage,
	in Uri includeDir,
	in Uri[] rootUris,
	in Opt!Uri mainUri,
) {
	Config config = getConfig(modelAlloc, allSymbols, allUris, includeDir, storage, rootUris);
	EnumMap!(CommonModule, Uri) commonUris = commonUris(allUris, config.crowIncludeDir);
	AstAndResolvedImports[] parsed = withMeasure!(AstAndResolvedImports[], () => parseEverything(
		modelAlloc, astsAlloc, perf, allSymbols, allUris, storage, rootUris, mainUri, commonUris, config)
	)(astsAlloc, perf, PerfMeasure.parseEverything);
	return withMeasure!(Program, () =>
		checkEverything(modelAlloc, perf, allSymbols, allUris, config, parsed, rootUris, mainUri, commonUris)
	)(modelAlloc, perf, PerfMeasure.checkEverything);
}

// The purpose of this is to discover unknown files
void parseAllFiles(
	ref Alloc alloc,
	scope ref Perf perf,
	ref AllSymbols allSymbols,
	ref AllUris allUris,
	scope ref Storage storage,
	in Uri includeDir,
	in Uri[] rootUris,
) {
	Config config = getConfig(alloc, allSymbols, allUris, includeDir, storage, rootUris);
	cast(void) parseEverything(
		alloc, alloc, perf, allSymbols, allUris, storage,
		rootUris, none!Uri, commonUris(allUris, config.crowIncludeDir), config);
}

FileAst* parseSingleAst(
	ref Alloc alloc,
	scope ref Perf perf,
	ref AllSymbols allSymbols,
	ref AllUris allUris,
	scope ref Storage storage,
	Uri uri,
) =>
	withFile!(FileAst*)(storage, uri, (in ReadFileResult x) =>
		x.matchIn!(FileAst*)(
			(in FileContent content) =>
				parseFile(alloc, perf, allSymbols, allUris, content.asSafeCStr()),
			(in ReadFileIssue issue) =>
				astForIssue(alloc, issue)));

private:

FileAst* astForIssue(ref Alloc alloc, ReadFileIssue issue) =>
	fileAstForDiags(alloc, arrLiteral(alloc, [ParseDiagnostic(Range.empty, ParseDiag(issue))]));

immutable struct ParseStatus {
	immutable struct Started {}
	immutable struct Done {}
	mixin Union!(Started, Done, ReadFileIssue);
}

alias UriToStatus = MutMap!(Uri, ParseStatus);

struct ParseStackEntry {
	immutable Uri uri;
	immutable FileAst* ast;
	immutable ResolvedImportsAndExports importsAndExports;
}

alias ParseStack = MutMaxArr!(32, ParseStackEntry);

AstAndResolvedImports[] parseEverything(
	ref Alloc modelAlloc,
	ref Alloc astAlloc,
	scope ref Perf perf,
	scope ref AllSymbols allSymbols,
	scope ref AllUris allUris,
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
					astAlloc, perf, allSymbols, allUris, storage, config,
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
			parseAndPush(astAlloc, perf, allSymbols, allUris, storage, config, statuses, stack, uri);
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
	ref Alloc alloc,
	scope ref Perf perf,
	scope ref AllSymbols allSymbols,
	scope ref AllUris allUris,
	scope ref Storage storage,
	in Config config,
	scope ref UriToStatus statuses,
	ref ParseStack stack,
	Uri uri,
) {
	withFile!void(storage, uri, (in ReadFileResult x) {
		ParseStatus status = x.match!ParseStatus(
			(FileContent x) {
				FileAst* ast = parseFile(alloc, perf, allSymbols, allUris, x.asSafeCStr());
				push(stack, ParseStackEntry(uri, ast, resolveImportsAndExports(
					alloc, allUris, config, uri, ast.imports, ast.exports)));
				return ParseStatus(ParseStatus.Started());
			},
			(ReadFileIssue issue) {
				push(stack, ParseStackEntry(uri, astForIssue(alloc, issue), ResolvedImportsAndExports()));
				return ParseStatus(issue);
			});
		addToMutMap(alloc, statuses, uri, status);
	});
}

// returns none if we can't resolve all imported modules yet
Opt!FullyResolvedImport fullyResolveImport(
	ref Alloc alloc,
	scope ref Perf perf,
	scope ref AllSymbols allSymbols,
	scope ref AllUris allUris,
	scope ref Storage storage,
	in Config config,
	ref UriToStatus statuses,
	ref ParseStack stack,
	Uri fromUri,
	ResolvedImport import_,
) {
	Opt!FullyResolvedImportKind kind = import_.resolvedUri.matchIn!(Opt!FullyResolvedImportKind)(
		(in Uri uri) =>
			fullyResolveImportKind(
				alloc, perf, allSymbols, allUris, storage, config, statuses, stack, fromUri, import_, uri),
		(in Diagnostic diag) =>
			some(FullyResolvedImportKind(diag)));
	return has(kind)
		? some(FullyResolvedImport(some(import_.ast), force(kind)))
		: none!FullyResolvedImport;
}

Opt!FullyResolvedImportKind fullyResolveImportKind(
	ref Alloc alloc,
	scope ref Perf perf,
	scope ref AllSymbols allSymbols,
	scope ref AllUris allUris,
	scope ref Storage storage,
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
				alloc, perf, allSymbols, allUris, storage, config, statuses, stack, fromUri,
				*import_.ast, resolvedUri,
				(Uri uri) =>
					FullyResolvedImportKind(FullyResolvedImportKind.ModuleWhole(uri))),
		(in NameAndRange[] names) =>
			fullyResolveImportModule(
				alloc, perf, allSymbols, allUris, storage, config, statuses, stack, fromUri,
				*import_.ast, resolvedUri,
				(Uri uri) =>
					FullyResolvedImportKind(FullyResolvedImportKind.ModuleNamed(
						uri,
						map(alloc, names, (ref NameAndRange name) => name.name)))),
		(in ImportOrExportAstKind.File x) =>
			some(readFileContent(allUris, storage, *import_.ast, x, resolvedUri)));

FullyResolvedImportKind readFileContent(
	in AllUris allUris,
	scope ref Storage storage,
	in ImportOrExportAst ast,
	in ImportOrExportAstKind.File astKind,
	Uri uri,
) =>
	withFile!FullyResolvedImportKind(storage, uri, (in ReadFileResult x) =>
		x.matchIn!FullyResolvedImportKind(
			(in FileContent x) =>
				FullyResolvedImportKind(FullyResolvedImportKind.File(astKind.name.name, astKind.type, x)),
			(in ReadFileIssue x) =>
				FullyResolvedImportKind(Diagnostic(pathRange(allUris, ast), Diag(Diag.ImportFileIssue(uri, x))))));

Opt!FullyResolvedImportKind fullyResolveImportModule(
	ref Alloc alloc,
	scope ref Perf perf,
	scope ref AllSymbols allSymbols,
	scope ref AllUris allUris,
	scope ref Storage storage,
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
			(ParseStatus.Started) =>
				FullyResolvedImportKind(Diagnostic(pathRange(allUris, ast), Diag(Diag.CircularImport(importUri)))),
			(ParseStatus.Done x) =>
				getSuccessKind(importUri),
			(ReadFileIssue issue) =>
				FullyResolvedImportKind(Diagnostic(
					pathRange(allUris, ast),
					Diag(Diag.ImportFileIssue(importUri, issue))))));
	else {
		parseAndPush(alloc, perf, allSymbols, allUris, storage, config, statuses, stack, importUri);
		return none!FullyResolvedImportKind;
	}
}

immutable struct ResolvedImport {
	ImportOrExportAst* ast;
	ResolvedUriOrDiag resolvedUri;
}

immutable struct ResolvedUriOrDiag {
	mixin Union!(Uri, Diagnostic);
}

ResolvedImport tryResolveImport(scope ref AllUris allUris, in Config config, Uri fromUri, ImportOrExportAst* ast) {
	ResolvedImport resolved(Uri uri) =>
		ResolvedImport(ast, ResolvedUriOrDiag(addExtensionIfNone!crowExtension(allUris, uri)));
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
			return has(rel)
				? resolved(force(rel))
				: ResolvedImport(ast, ResolvedUriOrDiag(Diagnostic(pathRange(allUris, *ast), Diag(
					ParseDiag(ParseDiag.RelativeImportReachesPastRoot(relPath))))));
		});
}

immutable struct ResolvedImportsAndExports {
	ResolvedImport[] imports;
	ResolvedImport[] exports;
}

ResolvedImport[] resolveImportOrExportUris(
	ref Alloc alloc,
	scope ref AllUris allUris,
	in Config config,
	Uri fromUri,
	in Opt!ImportsOrExportsAst importsOrExports,
) =>
	mapPointers(alloc, has(importsOrExports) ? force(importsOrExports).paths : [], (ImportOrExportAst* i) =>
		tryResolveImport(allUris, config, fromUri, i));

ResolvedImportsAndExports resolveImportsAndExports(
	ref Alloc alloc,
	scope ref AllUris allUris,
	in Config config,
	Uri fromUri,
	in Opt!ImportsOrExportsAst imports,
	in Opt!ImportsOrExportsAst exports,
) =>
	ResolvedImportsAndExports(
		resolveImportOrExportUris(alloc, allUris, config, fromUri, imports),
		resolveImportOrExportUris(alloc, allUris, config, fromUri, exports));

immutable struct AstAndResolvedImports {
	Uri uri;
	FileAst* ast;
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

	mixin Union!(ModuleWhole, ModuleNamed, File, Diagnostic);
}

immutable struct ImportsOrExports {
	ImportOrExport[] moduleImports;
	ImportOrExportFile[] fileImports;
}

ImportsOrExports mapImportsOrExports(
	ref Alloc alloc,
	scope ref ArrBuilder!Diagnostic diagsBuilder,
	in FullyResolvedImport[] uris,
	ref const MutMap!(Uri, immutable Module*) compiled,
) {
	ArrBuilder!ImportOrExportFile fileImports;
	ImportOrExport[] moduleImports = mapOp!(ImportOrExport, FullyResolvedImport)(
		alloc,
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
					add(alloc, fileImports, ImportOrExportFile(x.source, f.name, f.type, f.content));
					return none!ImportOrExportKind;
				},
				(Diagnostic x) {
					add(alloc, diagsBuilder, x);
					return none!ImportOrExportKind;
				});
			return has(kind) ? some(ImportOrExport(x.source, force(kind))) : none!ImportOrExport;
	});
	return ImportsOrExports(moduleImports, finishArr(alloc, fileImports));
}

struct ModulesAndCommonTypes {
	Map!(Uri, immutable Module*) modules;
	CommonTypes commonTypes;
}

ModulesAndCommonTypes getModules(
	ref Alloc modelAlloc,
	scope ref Perf perf,
	scope ref AllSymbols allSymbols,
	in AllUris allUris,
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
					modelAlloc, perf, allSymbols, allUris, programState, stdUri, ast, compiled, fileAndAst,
					lateGet(commonTypes));
			} else {
				// The first module to check is always 'bootstrap.crow'
				verify(ast.resolvedImports.empty);
				BootstrapCheck res = checkBootstrap(modelAlloc, perf, allSymbols, allUris, programState, fileAndAst);
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
	scope ref Perf perf,
	scope ref AllSymbols allSymbols,
	in AllUris allUris,
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
	ArrBuilder!Diagnostic diagsBuilder;
	ImportsOrExports imports = mapImportsOrExports(modelAlloc, diagsBuilder, allImports, compiled);
	ImportsOrExports exports = mapImportsOrExports(modelAlloc, diagsBuilder, ast.resolvedExports, compiled);
	ImportsAndExports importsAndExports = ImportsAndExports(
		imports.moduleImports,
		exports.moduleImports,
		imports.fileImports,
		exports.fileImports);
	return check(
		modelAlloc, perf, allSymbols, allUris, programState, fileAndAst, diagsBuilder, importsAndExports, commonTypes);
}

Program checkEverything(
	ref Alloc modelAlloc,
	scope ref Perf perf,
	scope ref AllSymbols allSymbols,
	in AllUris allUris,
	Config config,
	in AstAndResolvedImports[] allAsts,
	in Uri[] rootUris,
	in Opt!Uri mainUri,
	in EnumMap!(CommonModule, Uri) commonUris,
) {
	ProgramState programState = ProgramState();
	ModulesAndCommonTypes modulesAndCommonTypes = getModules(
		modelAlloc, perf, allSymbols, allUris, programState, commonUris[CommonModule.std], allAsts);
	Map!(Uri, immutable Module*) modules = modulesAndCommonTypes.modules;
	immutable EnumMap!(CommonModule, Opt!(Module*)) commonModules =
		enumMapMapValues!(CommonModule, Opt!(Module*), Uri)(commonUris, (in Uri uri) =>
			modules[uri]);
	CommonFuns commonFuns = getCommonFuns(
		modelAlloc,
		programState,
		modulesAndCommonTypes.commonTypes,
		has(mainUri) ? modules[force(mainUri)] : none!(Module*),
		commonModules);
	return Program(
		config,
		modules,
		map!(Module*, Uri)(modelAlloc, rootUris, (ref Uri uri) {
			Opt!(Module*) res = modules[uri];
			return has(res) ? force(res) : allocate(modelAlloc, emptyModule(uri, fileAstForDiags(modelAlloc, [])));
		}),
		commonFuns,
		modulesAndCommonTypes.commonTypes);
}

FileAst* fileAstForDiags(ref Alloc alloc, ParseDiagnostic[] diags) =>
	allocate(alloc, FileAst(
		diags,
		safeCStr!"",
		false,
		none!ImportsOrExportsAst,
		none!ImportsOrExportsAst,
		[], [], [], [], [], []));
