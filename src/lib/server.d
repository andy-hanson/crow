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
import interpret.fakeExtern : FakeExternResult,withFakeExtern;
import model.diag : Diagnostic, DiagnosticWithinFile, FilesInfo;
import model.model : AbsolutePathsGetter, Program;
import util.alloc.alloc : Alloc;
import util.col.arrBuilder : ArrBuilder;
import util.col.arrUtil : arrLiteral, map;
import util.col.fullIndexDict : FullIndexDict, fullIndexDictOfArr, fullIndexDictSize;
import util.col.mutDict : getAt_mut, insertOrUpdate, mustDelete, mustGetAt_mut;
import util.col.str : copyToSafeCStr, freeSafeCStr, SafeCStr, safeCStr;
import util.conv : safeToUshort;
import util.dbg : Debug;
import util.dictReadOnlyStorage : withDictReadOnlyStorage, MutFiles;
import util.lineAndColumnGetter : LineAndColumnGetter, lineAndColumnGetterForText;
import util.opt : force, has, none, Opt, some;
import util.path :
	AllPaths,
	hashPathAndStorageKind,
	parsePath,
	Path,
	PathAndStorageKind,
	pathAndStorageKindEqual,
	StorageKind;
import util.perf : Perf;
import util.ptr : Ptr;
import util.readOnlyStorage : ReadOnlyStorage;
import util.sourceRange : FileIndex, Pos, RangeWithinFile;
import util.sym : AllSymbols;

struct Server {
	@safe @nogc pure nothrow:

	Alloc alloc;
	AllSymbols allSymbols;
	AllPaths allPaths;
	MutFiles files;

	this(Alloc a) {
		alloc = a.move();
		allSymbols = AllSymbols(Ptr!Alloc(&alloc));
		allPaths = AllPaths(Ptr!Alloc(&alloc), Ptr!AllSymbols(&allSymbols));
		files = MutFiles.init;
	}
}

pure void addOrChangeFile(
	ref Debug,
	ref Server server,
	immutable StorageKind storageKind,
	scope immutable string path,
	scope immutable string content,
) {
	immutable PathAndStorageKind key = immutable PathAndStorageKind(toPath(server, path), storageKind);
	immutable SafeCStr contentCopy = copyToSafeCStr(server.alloc, content);
	insertOrUpdate!(
		immutable PathAndStorageKind,
		immutable SafeCStr,
		pathAndStorageKindEqual,
		hashPathAndStorageKind,
	)(
		server.alloc,
		server.files,
		key,
		() => contentCopy,
		(ref immutable SafeCStr old) @trusted {
			freeSafeCStr(server.alloc, old);
			return contentCopy;
		});
}

@trusted pure void deleteFile(ref Server server, immutable StorageKind storageKind, immutable string path) {
	immutable PathAndStorageKind key = immutable PathAndStorageKind(toPath(server, path), storageKind);
	immutable(SafeCStr) deleted = mustDelete(server.files, key);
	freeSafeCStr(server.alloc, deleted);
}

pure immutable(SafeCStr) getFile(
	ref Server server,
	immutable StorageKind storageKind,
	immutable string path,
) {
	immutable PathAndStorageKind key = immutable PathAndStorageKind(toPath(server, path), storageKind);
	immutable Opt!(immutable SafeCStr) text = getAt_mut(server.files, key);
	return has(text) ? force(text) : safeCStr!"";
}

immutable(Token[]) getTokens(
	ref Alloc alloc,
	ref Perf perf,
	ref Server server,
	immutable StorageKind storageKind,
	immutable string path,
) {
	immutable PathAndStorageKind key = immutable PathAndStorageKind(toPath(server, path), storageKind);
	immutable SafeCStr text = mustGetAt_mut(server.files, key);
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
	ref Perf perf,
	ref Server server,
	immutable StorageKind storageKind,
	immutable string path,
) {
	immutable PathAndStorageKind key = immutable PathAndStorageKind(toPath(server, path), storageKind);
	immutable SafeCStr text = mustGetAt_mut(server.files, key);
	ArrBuilder!DiagnosticWithinFile diagsBuilder;
	// AST not used
	parseFile(alloc, perf, server.allPaths, server.allSymbols, diagsBuilder, text);
	immutable FilesInfo filesInfo = immutable FilesInfo(
		fullIndexDictOfArr!(FileIndex, PathAndStorageKind)(arrLiteral!PathAndStorageKind(alloc, [key])),
		immutable AbsolutePathsGetter(safeCStr!"", safeCStr!"", safeCStr!""),
		fullIndexDictOfArr!(FileIndex, LineAndColumnGetter)(
			arrLiteral!LineAndColumnGetter(alloc, [lineAndColumnGetterForText(alloc, text)])));
	return map!StrParseDiagnostic(
		alloc,
		diagnosticsForFile(alloc, immutable FileIndex(0), diagsBuilder, filesInfo.filePaths).diags,
		(ref immutable Diagnostic it) =>
			immutable StrParseDiagnostic(
				it.where.range,
				strOfDiagnostic(alloc, server.allSymbols, server.allPaths, showDiagOptions, filesInfo, it)));
}

immutable(string) getHover(
	scope ref Debug dbg,
	ref Perf perf,
	ref Alloc alloc,
	ref Server server,
	immutable StorageKind storageKind,
	immutable string path,
	immutable Pos pos,
) {
	immutable PathAndStorageKind pk = immutable PathAndStorageKind(toPath(server, path), storageKind);
	immutable Program program = withDictReadOnlyStorage!(immutable Program)(
		server.files,
		(scope ref const ReadOnlyStorage storage) =>
			frontendCompile(alloc, perf, alloc, server.allPaths, server.allSymbols, storage, [pk]));
	return getHoverFromProgram(alloc, server, pk, program, pos);
}

private pure immutable(string) getHoverFromProgram(
	ref Alloc alloc,
	ref Server server,
	immutable PathAndStorageKind pk,
	ref immutable Program program,
	immutable Pos pos,
) {
	immutable Opt!FileIndex fileIndex = getFileIndex(program.filesInfo.filePaths, pk);
	if (has(fileIndex)) {
		immutable Opt!Position position =
			getPosition(server.allSymbols, program.allModules[force(fileIndex).index], pos);
		return has(position)
			? getHoverStr(alloc, alloc, server.allSymbols, server.allPaths, program, force(position))
			: "";
	} else
		return "";
}

//TODO:KILL, use a reverse lookup
private pure immutable(Opt!FileIndex) getFileIndex(
	scope ref immutable FullIndexDict!(FileIndex, PathAndStorageKind) filePaths,
	immutable PathAndStorageKind search,
) {
	foreach (immutable size_t i; 0 .. fullIndexDictSize(filePaths))
		if (pathAndStorageKindEqual(filePaths.values[i], search))
			return some(immutable FileIndex(safeToUshort(i)));
	return none!FileIndex;
}

immutable(FakeExternResult) run(
	scope ref Debug dbg,
	ref Perf perf,
	ref Alloc alloc,
	ref Server server,
	immutable string mainPathStr,
) {
	immutable PathAndStorageKind main = immutable PathAndStorageKind(toPath(server, mainPathStr), StorageKind.local);
	// TODO: use an arena so anything allocated during interpretation is cleaned up.
	// Or just have interpreter free things.
	scope immutable SafeCStr[1] allArgs = [safeCStr!"/usr/bin/fakeExecutable"];
	return withDictReadOnlyStorage(server.files, (scope ref const ReadOnlyStorage storage) =>
		withFakeExtern(alloc, (scope ref Extern extern_) =>
			buildAndInterpret(
				alloc, dbg, perf, server.allSymbols, server.allPaths, storage, extern_,
				showDiagOptions, main, allArgs)));
}

private:

pure immutable(Path) toPath(ref Server server, scope immutable string path) {
	return parsePath(server.allPaths, path);
}

immutable ShowDiagOptions showDiagOptions = immutable ShowDiagOptions(false);
