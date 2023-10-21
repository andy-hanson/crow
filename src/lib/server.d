module lib.server;

@safe @nogc nothrow: // not pure

import lib.compiler : buildAndInterpret, ExitCode;
import frontend.diagnosticsBuilder : diagnosticsForFile;
import frontend.frontendCompile : frontendCompile;
import frontend.ide.getDefinition : Definition, getDefinitionForPosition;
import frontend.ide.getHover : getHoverStr;
import frontend.ide.getPosition : getPosition, Position;
import frontend.ide.getTokens : Token, tokensOfAst;
import frontend.parse.ast : FileAst;
import frontend.parse.parse : parseFile;
import frontend.showDiag : ShowDiagOptions, strOfDiagnostic;
import interpret.extern_ : Extern;
import interpret.fakeExtern : Pipe, withFakeExtern, WriteCb;
import model.diag : Diagnostic, Diagnostics, DiagnosticWithinFile, DiagSeverity, FilesInfo;
import model.model : fakeProgramForDiagnostics, Program;
import util.alloc.alloc : Alloc;
import util.col.arrBuilder : ArrBuilder;
import util.col.arrUtil : arrLiteral, map;
import util.col.map : mapLiteral;
import util.col.fullIndexMap : fullIndexMapOfArr;
import util.col.mutMap : getAt_mut, insertOrUpdate, mustDelete, mustGetAt_mut;
import util.col.str : copySafeCStr, freeSafeCStr, SafeCStr, safeCStr, strOfSafeCStr;
import util.lineAndColumnGetter : LineAndColumnGetter, lineAndColumnGetterForText;
import util.memoryReadOnlyStorage : withMemoryReadOnlyStorage, MutFiles;
import util.opt : force, has, none, Opt;
import util.path : AllPaths, emptyPathsInfo, parsePath, Path, PathsInfo;
import util.perf : Perf;
import util.readOnlyStorage : ReadOnlyStorage;
import util.sourceRange : FileIndex, Pos, RangeWithinFile;
import util.sym : AllSymbols;

struct Server {
	@safe @nogc pure nothrow:

	Alloc alloc;
	AllSymbols allSymbols;
	AllPaths allPaths;
	immutable Path includeDir;
	immutable PathsInfo pathsInfo;
	MutFiles files;

	@trusted this(Alloc a, in SafeCStr include) {
		alloc = a.move();
		allSymbols = AllSymbols(&alloc);
		allPaths = AllPaths(&alloc, &allSymbols);
		includeDir = parsePath(allPaths, include);
		pathsInfo = emptyPathsInfo;
		files = MutFiles.init;
	}
}

pure void addOrChangeFile(ref Server server, in SafeCStr path, in SafeCStr content) {
	SafeCStr contentCopy = copySafeCStr(server.alloc, content);
	insertOrUpdate!(Path, SafeCStr)(
		server.alloc,
		server.files,
		toPath(server, path),
		() => contentCopy,
		(ref SafeCStr old) @trusted {
			freeSafeCStr(server.alloc, old);
			return contentCopy;
		});
}

@trusted pure void deleteFile(ref Server server, in SafeCStr path) {
	SafeCStr deleted = mustDelete(server.files, toPath(server, path));
	freeSafeCStr(server.alloc, deleted);
}

pure SafeCStr getFile(ref Server server, in SafeCStr path) {
	Opt!SafeCStr text = getAt_mut(server.files, toPath(server, path));
	return has(text) ? force(text) : safeCStr!"";
}

immutable struct TokensAndParseDiagnostics {
	Token[] tokens;
	StrParseDiagnostic[] parseDiagnostics;
}

immutable struct StrParseDiagnostic {
	RangeWithinFile range;
	string message;
}

pure TokensAndParseDiagnostics getTokensAndParseDiagnostics(
	ref Alloc alloc,
	scope ref Perf perf,
	ref Server server,
	in Path path,
) {
	SafeCStr text = mustGetAt_mut(server.files, path);
	ArrBuilder!DiagnosticWithinFile diagnosticsBuilder;
	FileAst ast = parseFile(alloc, perf, server.allPaths, server.allSymbols, diagnosticsBuilder, text);
	//TODO: use 'scope' to avoid allocating things here
	FilesInfo filesInfo = FilesInfo(
		fullIndexMapOfArr!(FileIndex, Path)(arrLiteral!Path(alloc, [path])),
		mapLiteral!(Path, FileIndex)(alloc, path, FileIndex(0)),
		fullIndexMapOfArr!(FileIndex, LineAndColumnGetter)(
			arrLiteral!LineAndColumnGetter(alloc, [lineAndColumnGetterForText(alloc, text)])));
	Program program = fakeProgramForDiagnostics(filesInfo, Diagnostics(
		DiagSeverity.parseError,
		diagnosticsForFile(alloc, FileIndex(0), diagnosticsBuilder, filesInfo.filePaths).diags));
	return TokensAndParseDiagnostics(
		tokensOfAst(alloc, server.allSymbols, ast),
		map(alloc, program.diagnostics.diags, (ref Diagnostic x) =>
			StrParseDiagnostic(
				x.where.range,
				strOfDiagnostic(
					alloc, server.allSymbols, server.allPaths, server.pathsInfo, showDiagOptions, program, x))));
}

Opt!Definition getDefinition(ref Perf perf, ref Alloc alloc, ref Server server, in Path path, Pos pos) {
	Program program = getProgram(perf, alloc, server, path);
	Opt!Position position = getPosition(server, program, path, pos);
	return has(position)
		? getDefinitionForPosition(program, force(position))
		: none!Definition;
}

SafeCStr getHover(ref Perf perf, ref Alloc alloc, ref Server server, in Path path, Pos pos) {
	Program program = getProgram(perf, alloc, server, path);
	Opt!Position position = getPosition(server, program, path, pos);
	return has(position)
		? getHoverStr(alloc, alloc, server.allSymbols, server.allPaths, server.pathsInfo, program, force(position))
		: safeCStr!"";
}

private Program getProgram(ref Perf perf, ref Alloc alloc, ref Server server, Path rootPath) =>
	withMemoryReadOnlyStorage!Program(server.includeDir, server.files, (in ReadOnlyStorage storage) =>
		frontendCompile(alloc, perf, alloc, server.allPaths, server.allSymbols, storage, [rootPath], none!Path));

private Opt!Position getPosition(in Server server, in Program program, Path path, Pos pos) {
	Opt!FileIndex fileIndex = program.filesInfo.pathToFile[path];
	return has(fileIndex)
		? getPosition(server.allSymbols, program.allModules[force(fileIndex).index], pos)
		: none!Position;
}

ExitCode run(
	ref Perf perf,
	ref Alloc alloc,
	ref Server server,
	in Path main,
	in WriteCb writeCb,
) {
	// TODO: use an arena so anything allocated during interpretation is cleaned up.
	// Or just have interpreter free things.
	SafeCStr[1] allArgs = [safeCStr!"/usr/bin/fakeExecutable"];
	return withMemoryReadOnlyStorage!ExitCode(server.includeDir, server.files, (in ReadOnlyStorage storage) =>
		withFakeExtern(alloc, server.allSymbols, writeCb, (scope ref Extern extern_) =>
			buildAndInterpret(
				alloc, perf, server.allSymbols, server.allPaths, server.pathsInfo, storage, extern_,
				(in SafeCStr x) {
					writeCb(Pipe.stderr, strOfSafeCStr(x));
				},
				showDiagOptions, main, allArgs)));
}

pure Path toPath(ref Server server, in SafeCStr path) =>
	parsePath(server.allPaths, path);

private pure ShowDiagOptions showDiagOptions() =>
	ShowDiagOptions(false);
