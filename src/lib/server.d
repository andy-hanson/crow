module lib.server;

@safe @nogc nothrow: // not pure

import lib.compiler : buildAndInterpret;
import frontend.diagnosticsBuilder : diagnosticsForFile;
import frontend.frontendCompile : frontendCompile;
import frontend.ide.getHover : getHoverStr;
import frontend.ide.getPosition : getPosition, Position;
import frontend.ide.getTokens : Token, tokensOfAst;
import frontend.parse.ast : FileAst;
import frontend.parse.parse : parseFile;
import frontend.showDiag : ShowDiagOptions, strOfDiagnostic;
import interpret.extern_ : Extern;
import interpret.fakeExtern : FakeExternResult, FakeStdOutput, withFakeExtern;
import model.diag : Diagnostic, Diagnostics, DiagnosticWithinFile, DiagSeverity, FilesInfo;
import model.model : fakeProgramForDiagnostics, Program;
import util.alloc.alloc : Alloc;
import util.col.arrBuilder : ArrBuilder;
import util.col.arrUtil : arrLiteral, map;
import util.col.dict : dictLiteral;
import util.col.fullIndexDict : fullIndexDictOfArr;
import util.col.mutArr : pushAll;
import util.col.mutDict : getAt_mut, insertOrUpdate, mustDelete, mustGetAt_mut;
import util.col.str : copySafeCStr, freeSafeCStr, SafeCStr, safeCStr, strOfSafeCStr;
import util.dictReadOnlyStorage : withDictReadOnlyStorage, MutFiles;
import util.lineAndColumnGetter : LineAndColumnGetter, lineAndColumnGetterForText;
import util.opt : force, has, none, Opt;
import util.path : AllPaths, childPath, emptyPathsInfo, emptyRootPath, parsePath, Path, PathsInfo;
import util.perf : Perf;
import util.readOnlyStorage : ReadOnlyStorage;
import util.sourceRange : FileIndex, Pos, RangeWithinFile;
import util.sym : AllSymbols, sym;

struct Server {
	@safe @nogc pure nothrow:

	Alloc alloc;
	AllSymbols allSymbols;
	AllPaths allPaths;
	immutable Path includeDir;
	immutable PathsInfo pathsInfo;
	MutFiles files;

	@trusted this(Alloc a) {
		alloc = a.move();
		allSymbols = AllSymbols(&alloc);
		allPaths = AllPaths(&alloc, &allSymbols);
		includeDir = childPath(allPaths, emptyRootPath(allPaths), sym!"include");
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

pure Token[] getTokens(ref Alloc alloc, scope ref Perf perf, ref Server server, in SafeCStr path) {
	SafeCStr text = mustGetAt_mut(server.files, toPath(server, path));
	// diagnostics not used
	ArrBuilder!DiagnosticWithinFile diagnosticsBuilder;
	FileAst ast = parseFile(alloc, perf, server.allPaths, server.allSymbols, diagnosticsBuilder, text);
	return tokensOfAst(alloc, server.allSymbols, ast);
}

immutable struct StrParseDiagnostic {
	RangeWithinFile range;
	string message;
}

pure StrParseDiagnostic[] getParseDiagnostics(
	ref Alloc alloc,
	scope ref Perf perf,
	ref Server server,
	in SafeCStr path,
) {
	Path key = toPath(server, path);
	SafeCStr text = mustGetAt_mut(server.files, key);
	ArrBuilder!DiagnosticWithinFile diagsBuilder;
	// AST not used
	parseFile(alloc, perf, server.allPaths, server.allSymbols, diagsBuilder, text);
	//TODO: use 'scope' to avoid allocating things here
	FilesInfo filesInfo = FilesInfo(
		fullIndexDictOfArr!(FileIndex, Path)(arrLiteral!Path(alloc, [key])),
		dictLiteral!(Path, FileIndex)(alloc, key, FileIndex(0)),
		fullIndexDictOfArr!(FileIndex, LineAndColumnGetter)(
			arrLiteral!LineAndColumnGetter(alloc, [lineAndColumnGetterForText(alloc, text)])));
	Program program = fakeProgramForDiagnostics(filesInfo, Diagnostics(
		DiagSeverity.parseError,
		diagnosticsForFile(alloc, FileIndex(0), diagsBuilder, filesInfo.filePaths).diags));
	return map(alloc, program.diagnostics.diags, (ref Diagnostic x) =>
		StrParseDiagnostic(
			x.where.range,
			strOfDiagnostic(alloc, server.allSymbols, server.allPaths, server.pathsInfo, showDiagOptions, program, x)));
}

SafeCStr getHover(ref Perf perf, ref Alloc alloc, ref Server server, in SafeCStr path, Pos pos) {
	Path key = toPath(server, path);
	Program program = withDictReadOnlyStorage!Program(server.includeDir, server.files, (in ReadOnlyStorage storage) =>
		frontendCompile(alloc, perf, alloc, server.allPaths, server.allSymbols, storage, [key], none!Path));
	return getHoverFromProgram(alloc, server, key, program, pos);
}

private SafeCStr getHoverFromProgram(ref Alloc alloc, ref Server server, Path path, in Program program, Pos pos) {
	Opt!FileIndex fileIndex = program.filesInfo.pathToFile[path];
	if (has(fileIndex)) {
		Opt!Position position = getPosition(server.allSymbols, program.allModules[force(fileIndex).index], pos);
		return has(position)
			? getHoverStr(alloc, alloc, server.allSymbols, server.allPaths, server.pathsInfo, program, force(position))
			: safeCStr!"";
	} else
		return safeCStr!"";
}

FakeExternResult run(ref Perf perf, ref Alloc alloc, ref Server server, in SafeCStr mainPath) {
	Path main = toPath(server, mainPath);
	// TODO: use an arena so anything allocated during interpretation is cleaned up.
	// Or just have interpreter free things.
	SafeCStr[1] allArgs = [safeCStr!"/usr/bin/fakeExecutable"];
	return withDictReadOnlyStorage!FakeExternResult(server.includeDir, server.files, (in ReadOnlyStorage storage) =>
		withFakeExtern(alloc, server.allSymbols, (scope ref Extern extern_, scope ref FakeStdOutput std) =>
			buildAndInterpret(
				alloc, perf, server.allSymbols, server.allPaths, server.pathsInfo, storage, extern_,
				(in SafeCStr x) {
					pushAll(alloc, std.stderr, strOfSafeCStr(x));
				},
				showDiagOptions, main, allArgs)));
}

private:

pure Path toPath(ref Server server, in SafeCStr path) =>
	parsePath(server.allPaths, path);

pure ShowDiagOptions showDiagOptions() =>
	ShowDiagOptions(false);
