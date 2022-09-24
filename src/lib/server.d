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
import model.diag : Diagnostic, DiagnosticWithinFile, FilesInfo;
import model.model : Program;
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
import util.opt : force, has, Opt;
import util.path : AllPaths, childPath, emptyPathsInfo, emptyRootPath, parsePath, Path, PathsInfo;
import util.perf : Perf;
import util.readOnlyStorage : ReadOnlyStorage;
import util.sourceRange : FileIndex, Pos, RangeWithinFile;
import util.sym : AllSymbols, shortSym;

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
		includeDir = childPath(allPaths, emptyRootPath(allPaths), shortSym("include"));
		pathsInfo = emptyPathsInfo;
		files = MutFiles.init;
	}
}

pure void addOrChangeFile(
	ref Server server,
	scope immutable SafeCStr path,
	scope immutable SafeCStr content,
) {
	immutable SafeCStr contentCopy = copySafeCStr(server.alloc, content);
	insertOrUpdate!(immutable Path, immutable SafeCStr)(
		server.alloc,
		server.files,
		toPath(server, path),
		() => contentCopy,
		(ref immutable SafeCStr old) @trusted {
			freeSafeCStr(server.alloc, old);
			return contentCopy;
		});
}

@trusted pure void deleteFile(ref Server server, scope immutable SafeCStr path) {
	immutable(SafeCStr) deleted = mustDelete(server.files, toPath(server, path));
	freeSafeCStr(server.alloc, deleted);
}

pure immutable(SafeCStr) getFile(ref Server server, scope immutable SafeCStr path) {
	immutable Opt!(immutable SafeCStr) text = getAt_mut(server.files, toPath(server, path));
	return has(text) ? force(text) : safeCStr!"";
}

immutable(Token[]) getTokens(ref Alloc alloc, scope ref Perf perf, ref Server server, scope immutable SafeCStr path) {
	immutable SafeCStr text = mustGetAt_mut(server.files, toPath(server, path));
	// diagnostics not used
	ArrBuilder!DiagnosticWithinFile diagnosticsBuilder;
	immutable FileAst ast = parseFile(alloc, perf, server.allPaths, server.allSymbols, diagnosticsBuilder, text);
	return tokensOfAst(alloc, server.allSymbols, ast);
}

struct StrParseDiagnostic {
	immutable RangeWithinFile range;
	immutable string message;
}

immutable(StrParseDiagnostic[]) getParseDiagnostics(
	ref Alloc alloc,
	scope ref Perf perf,
	ref Server server,
	scope immutable SafeCStr path,
) {
	immutable Path key = toPath(server, path);
	immutable SafeCStr text = mustGetAt_mut(server.files, key);
	ArrBuilder!DiagnosticWithinFile diagsBuilder;
	// AST not used
	parseFile(alloc, perf, server.allPaths, server.allSymbols, diagsBuilder, text);
	//TODO: use 'scope' to avoid allocating things here
	immutable FilesInfo filesInfo = immutable FilesInfo(
		fullIndexDictOfArr!(FileIndex, Path)(arrLiteral!Path(alloc, [key])),
		dictLiteral!(Path, FileIndex)(alloc, key, immutable FileIndex(0)),
		fullIndexDictOfArr!(FileIndex, LineAndColumnGetter)(
			arrLiteral!LineAndColumnGetter(alloc, [lineAndColumnGetterForText(alloc, text)])));
	return map!StrParseDiagnostic(
		alloc,
		diagnosticsForFile(alloc, immutable FileIndex(0), diagsBuilder, filesInfo.filePaths).diags,
		(ref immutable Diagnostic it) =>
			immutable StrParseDiagnostic(
				it.where.range,
				strOfDiagnostic(
					alloc, server.allSymbols, server.allPaths, server.pathsInfo, showDiagOptions, filesInfo, it)));
}

immutable(SafeCStr) getHover(
	ref Perf perf,
	ref Alloc alloc,
	ref Server server,
	scope immutable SafeCStr path,
	immutable Pos pos,
) {
	immutable Path key = toPath(server, path);
	immutable Program program = withDictReadOnlyStorage!(immutable Program)(
		server.includeDir,
		server.files,
		(scope ref const ReadOnlyStorage storage) =>
			frontendCompile(alloc, perf, alloc, server.allPaths, server.allSymbols, storage, [key]));
	return getHoverFromProgram(alloc, server, key, program, pos);
}

private pure immutable(SafeCStr) getHoverFromProgram(
	ref Alloc alloc,
	ref Server server,
	immutable Path path,
	ref immutable Program program,
	immutable Pos pos,
) {
	immutable Opt!FileIndex fileIndex = program.filesInfo.pathToFile[path];
	if (has(fileIndex)) {
		immutable Opt!Position position =
			getPosition(server.allSymbols, program.allModules[force(fileIndex).index], pos);
		return has(position)
			? getHoverStr(alloc, alloc, server.allSymbols, server.allPaths, server.pathsInfo, program, force(position))
			: safeCStr!"";
	} else
		return safeCStr!"";
}

immutable(FakeExternResult) run(
	ref Perf perf,
	ref Alloc alloc,
	ref Server server,
	scope immutable SafeCStr mainPath,
) {
	immutable Path main = toPath(server, mainPath);
	// TODO: use an arena so anything allocated during interpretation is cleaned up.
	// Or just have interpreter free things.
	immutable SafeCStr[1] allArgs = [safeCStr!"/usr/bin/fakeExecutable"];
	return withDictReadOnlyStorage(server.includeDir, server.files, (scope ref const ReadOnlyStorage storage) =>
		withFakeExtern(alloc, server.allSymbols, (scope ref Extern extern_, scope ref FakeStdOutput std) =>
			buildAndInterpret(
				alloc, perf, server.allSymbols, server.allPaths, server.pathsInfo, storage, extern_,
				(immutable SafeCStr x) {
					pushAll(alloc, std.stderr, strOfSafeCStr(x));
				},
				showDiagOptions, main, allArgs)));
}

private:

pure immutable(Path) toPath(ref Server server, scope immutable SafeCStr path) =>
	parsePath(server.allPaths, path);

immutable ShowDiagOptions showDiagOptions = immutable ShowDiagOptions(false);
