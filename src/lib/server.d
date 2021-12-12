module lib.server;

@safe @nogc nothrow: // not pure

import lib.compiler : buildAndInterpret;
import frontend.diagnosticsBuilder : DiagnosticsBuilder, finishDiagnosticsNoSort;
import frontend.frontendCompile : frontendCompile;
import frontend.ide.getHover : getHoverStr;
import frontend.ide.getPosition : getPosition, Position;
import frontend.ide.getTokens : Token, tokensOfAst;
import frontend.parse.ast : FileAst;
import frontend.parse.parse : parseFile;
import frontend.showDiag : ShowDiagOptions, strOfDiagnostic;
import interpret.extern_ : Extern;
import interpret.fakeExtern : FakeExternResult,withFakeExtern;
import model.diag : Diagnostic, FilesInfo;
import model.model : AbsolutePathsGetter, Program;
import util.alloc.alloc : Alloc;
import util.collection.arr : freeArr;
import util.collection.arrUtil : arrLiteral, map;
import util.collection.fullIndexDict : FullIndexDict, fullIndexDictOfArr, fullIndexDictSize;
import util.collection.mutDict : getAt_mut, insertOrUpdate, mustDelete, mustGetAt_mut;
import util.collection.str :
	asSafeCStr,
	copyToNulTerminatedStr,
	CStr,
	cStrOfNulTerminatedStr,
	NulTerminatedStr,
	SafeCStr,
	safeCStr;
import util.conv : safeToUshort;
import util.dbg : Debug;
import util.dictReadOnlyStorage : DictReadOnlyStorage, MutFiles;
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
import util.ptr : Ptr, ptrTrustMe_const;
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
	immutable NulTerminatedStr contentCopy = copyToNulTerminatedStr(server.alloc, content);
	insertOrUpdate!(
		immutable PathAndStorageKind,
		immutable NulTerminatedStr,
		pathAndStorageKindEqual,
		hashPathAndStorageKind,
	)(
		server.alloc,
		server.files,
		key,
		() => contentCopy,
		(ref immutable NulTerminatedStr old) {
			trustedFree(server.alloc, old.str);
			return contentCopy;
		});
}

void deleteFile(ref Server server, immutable StorageKind storageKind, immutable string path) {
	immutable PathAndStorageKind key = immutable PathAndStorageKind(toPath(server, path), storageKind);
	immutable(NulTerminatedStr) deleted = mustDelete(server.files, key);
	trustedFree(server.alloc, deleted.str);
}

pure immutable(CStr) getFile(
	ref Server server,
	immutable StorageKind storageKind,
	immutable string path,
) {
	immutable PathAndStorageKind key = immutable PathAndStorageKind(toPath(server, path), storageKind);
	immutable Opt!(immutable NulTerminatedStr) text = getAt_mut(server.files, key);
	return has(text) ? cStrOfNulTerminatedStr(force(text)) : "";
}

immutable(Token[]) getTokens(
	ref Alloc alloc,
	ref Perf perf,
	ref Server server,
	immutable StorageKind storageKind,
	immutable string path,
) {
	immutable PathAndStorageKind key = immutable PathAndStorageKind(toPath(server, path), storageKind);
	immutable SafeCStr text = asSafeCStr(mustGetAt_mut(server.files, key));
	// diagnostics not used
	DiagnosticsBuilder diagnosticsBuilder = DiagnosticsBuilder();
	immutable FileAst ast =
		parseFile(alloc, perf, server.allPaths, server.allSymbols, diagnosticsBuilder, immutable FileIndex(0), text);
	return tokensOfAst(alloc, ast);
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
	immutable SafeCStr text = asSafeCStr(mustGetAt_mut(server.files, key));
	DiagnosticsBuilder diagsBuilder = DiagnosticsBuilder();
	// AST not used
	parseFile(alloc, perf, server.allPaths, server.allSymbols, diagsBuilder, immutable FileIndex(0), text);
	immutable FilesInfo filesInfo = immutable FilesInfo(
		fullIndexDictOfArr!(FileIndex, PathAndStorageKind)(arrLiteral!PathAndStorageKind(alloc, [key])),
		immutable AbsolutePathsGetter(safeCStr!"", safeCStr!"", safeCStr!""),
		fullIndexDictOfArr!(FileIndex, LineAndColumnGetter)(
			arrLiteral!LineAndColumnGetter(alloc, [lineAndColumnGetterForText(alloc, text)])));
	return map!StrParseDiagnostic(
		alloc,
		finishDiagnosticsNoSort(alloc, diagsBuilder).diags,
		(ref immutable Diagnostic it) =>
			immutable StrParseDiagnostic(
				it.where.range,
				strOfDiagnostic(alloc, server.allPaths, showDiagOptions, filesInfo, it)));
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
	DictReadOnlyStorage storage = DictReadOnlyStorage(ptrTrustMe_const(server.files));
	immutable Program program = frontendCompile(alloc, perf, alloc, server.allPaths, server.allSymbols, storage, pk);
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
		immutable Opt!Position position = getPosition(program.allModules[force(fileIndex).index], pos);
		return has(position) ? getHoverStr(alloc, alloc, server.allPaths, program, force(position)) : "";
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
	DictReadOnlyStorage storage = DictReadOnlyStorage(ptrTrustMe_const(server.files));
	return withFakeExtern(alloc, (scope ref Extern extern_) =>
		buildAndInterpret(
			alloc, dbg, perf, server.allSymbols, server.allPaths, storage, extern_, showDiagOptions, main, allArgs));
}

private:

pure @trusted void trustedFree(ref Alloc alloc, immutable string a) {
	freeArr(alloc, a);
}

pure immutable(Path) toPath(ref Server server, scope immutable string path) {
	return parsePath(server.allPaths, path);
}

immutable ShowDiagOptions showDiagOptions = immutable ShowDiagOptions(false);
