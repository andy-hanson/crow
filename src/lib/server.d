module lib.server;

@safe @nogc nothrow: // not pure

import lib.compiler : buildAndInterpret, ExitCode;
import frontend.frontendCompile : frontendCompile;
import frontend.ide.getHover : getHoverStr;
import frontend.ide.getPosition : getPosition, Position;
import frontend.ide.getTokens : Token, tokensOfAst;
import frontend.parse.parse : FileAstAndParseDiagnostics, parseFile;
import frontend.showDiag : ShowDiagOptions, strOfParseDiag;
import interpret.fakeExtern : FakeExtern;
import model.parseDiag : ParseDiagnostic;
import model.model : Program;
import util.alloc.alloc : Alloc;
import util.collection.arr : at, freeArr;
import util.collection.arrUtil : map;
import util.collection.fullIndexDict : FullIndexDict, fullIndexDictSize;
import util.collection.mutDict : getAt_mut, insertOrUpdate, mustDelete, mustGetAt_mut;
import util.collection.str : copyToNulTerminatedStr, CStr, cStrOfNulTerminatedStr, NulTerminatedStr, SafeCStr;
import util.comparison : Comparison;
import util.dbg : Debug;
import util.dictReadOnlyStorage : DictReadOnlyStorage, MutFiles;
import util.opt : force, has, none, Opt, some;
import util.path : AllPaths, comparePathAndStorageKind, parsePath, Path, PathAndStorageKind, StorageKind;
import util.perf : Perf;
import util.ptr : Ptr, ptrTrustMe_const, ptrTrustMe_mut;
import util.sourceRange : FileIndex, Pos, RangeWithinFile;
import util.sym : AllSymbols;
import util.types : safeSizeTToU16;

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
	insertOrUpdate!(immutable PathAndStorageKind, immutable NulTerminatedStr, comparePathAndStorageKind)(
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
	immutable NulTerminatedStr text = mustGetAt_mut(server.files, key);
	immutable FileAstAndParseDiagnostics ast = parseFile(alloc, perf, server.allPaths, server.allSymbols, text);
	return tokensOfAst(alloc, ast.ast);
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
	immutable NulTerminatedStr text = mustGetAt_mut(server.files, key);
	immutable FileAstAndParseDiagnostics ast = parseFile(alloc, perf, server.allPaths, server.allSymbols, text);
	return map!StrParseDiagnostic(alloc, ast.diagnostics, (ref immutable ParseDiagnostic it) =>
		immutable StrParseDiagnostic(it.range, strOfParseDiag(alloc, server.allPaths, showDiagOptions, it.diag)));
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
	ref immutable PathAndStorageKind pk,
	ref immutable Program program,
	immutable Pos pos,
) {
	immutable Opt!FileIndex fileIndex = getFileIndex(program.filesInfo.filePaths, pk);
	if (has(fileIndex)) {
		immutable Opt!Position position = getPosition(at(program.allModules, force(fileIndex).index), pos);
		return has(position) ? getHoverStr(alloc, alloc, server.allPaths, program, force(position)) : "";
	} else
		return "";
}

//TODO:KILL, use a reverse lookup
private pure immutable(Opt!FileIndex) getFileIndex(
	scope ref immutable FullIndexDict!(FileIndex, PathAndStorageKind) filePaths,
	scope ref immutable PathAndStorageKind search,
) {
	foreach (immutable size_t i; 0 .. fullIndexDictSize(filePaths))
		if (comparePathAndStorageKind(at(filePaths.values, i), search) == Comparison.equal)
			return some(immutable FileIndex(safeSizeTToU16(i)));
	return none!FileIndex;
}

struct RunResult {
	immutable ExitCode err;
	immutable string stdout;
	immutable string stderr;
}

immutable(RunResult) run(
	scope ref Debug dbg,
	ref Perf perf,
	ref Alloc alloc,
	ref Server server,
	immutable string mainPathStr,
) {
	immutable PathAndStorageKind main = immutable PathAndStorageKind(toPath(server, mainPathStr), StorageKind.local);
	// TODO: use an arena so anything allocated during interpretation is cleaned up.
	// Or just have interpreter free things.
	scope immutable SafeCStr[1] allArgs = [immutable SafeCStr("/usr/bin/fakeExecutable")];
	FakeExtern extern_ = FakeExtern(ptrTrustMe_mut(alloc));
	DictReadOnlyStorage storage = DictReadOnlyStorage(ptrTrustMe_const(server.files));
	immutable ExitCode err = buildAndInterpret(
		alloc, dbg, perf, server.allSymbols, server.allPaths, storage, extern_, showDiagOptions, main, allArgs);
	return immutable RunResult(err, extern_.moveStdout(), extern_.moveStderr());
}

private:

pure @trusted void trustedFree(ref Alloc alloc, immutable string a) {
	freeArr(alloc, a);
}

pure immutable(Path) toPath(ref Server server, scope immutable string path) {
	return parsePath(server.allPaths, path);
}

immutable ShowDiagOptions showDiagOptions = immutable ShowDiagOptions(false);
