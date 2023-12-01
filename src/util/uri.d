module util.uri;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc, allocateElements, AllocName, MetaAlloc, newAlloc;
import util.col.arr : endPtr;
import util.col.arrUtil : indexOf, indexOfStartingAt;
import util.col.mutArr : MutArr, mutArrSize, push, tempAsArr;
import util.col.str : compareSafeCStrAlphabetically, SafeCStr, safeCStr, strOfSafeCStr;
import util.comparison : Comparison;
import util.conv : safeToUshort;
import util.hash : Hasher, hashUshort;
import util.opt : has, force, none, Opt, some;
import util.sourceRange : Range;
import util.sym :
	addExtension,
	alterExtension,
	AllSymbols,
	appendHexExtension,
	eachCharInSym,
	getExtension,
	hasExtension,
	removeExtension,
	Sym,
	sym,
	symOfStr,
	symSize,
	writeSym;
import util.util : todo;
import util.writer : withWriter, Writer;

struct AllUris {
	@safe @nogc pure nothrow:
	private:
	Alloc alloc;
	AllSymbols* allSymbolsPtr;

	// Root path at index 0 will have children, but they won't have it as a parent
	MutArr!(Opt!Path) pathToParent;
	MutArr!Sym pathToBaseName;
	MutArr!(MutArr!Path) pathToChildren;

	public this(MetaAlloc* a, AllSymbols* as) {
		alloc = newAlloc(AllocName.allUris, a);
		allSymbolsPtr = as;

		// 0 must be the empty URI
		push(alloc, pathToParent, none!Path);
		push(alloc, pathToBaseName, sym!"");
		push(alloc, pathToChildren, MutArr!Path());
	}

	ref const(AllSymbols) allSymbols() return scope const =>
		*allSymbolsPtr;
	ref AllSymbols allSymbols() return scope =>
		*allSymbolsPtr;
}

// Uniform Resource Identifier ; does not support query or fragment.
immutable struct Uri {
	@safe @nogc pure nothrow:

	// The first component is the scheme + authority packed into a Sym
	private Path path;

	Path pathIncludingScheme() =>
		path;

	static Uri empty() =>
		Uri(Path.empty);

	void hash(ref Hasher hasher) scope {
		path.hash(hasher);
	}
}

private bool isRootUri(in AllUris allUris, Uri a) =>
	!has(parent(allUris, a));

private Sym fileScheme() =>
	sym!"file://";

bool isFileUri(in AllUris allUris, Uri a) =>
	firstComponent(allUris, a.path) == fileScheme;

FileUri asFileUri(ref AllUris allUris, Uri a) {
	assert(isFileUri(allUris, a));
	return FileUri(skipFirstComponent(allUris, a.path));
}

private Sym firstComponent(in AllUris allUris, Path a) {
	Opt!Path parent = parent(allUris, a);
	return has(parent)
		? firstComponent(allUris, force(parent))
		: baseName(allUris, a);
}

private Path skipFirstComponent(ref AllUris allUris, Path a) {
	Opt!Path parent = parent(allUris, a);
	return has(parent)
		? skipFirstComponent(allUris, force(parent), a)
		: Path.empty;
}

private Path skipFirstComponent(ref AllUris allUris, Path aParent, Path a) {
	Opt!Path grandParent = parent(allUris, aParent);
	Sym name = baseName(allUris, a);
	return has(grandParent)
		? childPath(allUris, skipFirstComponent(allUris, force(grandParent), aParent), name)
		: rootPath(allUris, name);
}

// Uri that is restricted to be a 'file:'
immutable struct FileUri {
	// Unlike for a Uri, this doesn't have "file" as the first component
	Path path;
}

Uri toUri(ref AllUris allUris, FileUri a) =>
	concatUriAndPath(allUris, Uri(rootPath(allUris, fileScheme)), a.path);

// Represents the path part of a URI, e.g. 'a/b/c'
immutable struct Path {
	@safe @nogc pure nothrow:

	private ushort index;

	static Path empty() =>
		Path(0);

	void hash(ref Hasher hasher) scope {
		hashUshort(hasher, index);
	}
}

Opt!Uri parent(in AllUris allUris, Uri a) {
	Opt!Path res = parent(allUris, a.path);
	return has(res) ? some(Uri(force(res))) : none!Uri;
}
Opt!FileUri parent(in AllUris allUris, FileUri a) {
	Opt!Path res = parent(allUris, a.path);
	return has(res) ? some(FileUri(force(res))) : none!FileUri;
}
Opt!Path parent(in AllUris allUris, Path a) =>
	allUris.pathToParent[a.index];

Uri parentOrEmpty(ref AllUris allUris, Uri a) {
	Opt!Uri res = parent(allUris, a);
	return has(res) ? force(res) : a;
}

// Removes an existing extension and adds a new one.
Uri alterExtension(Sym newExtension)(ref AllUris allUris, Uri a) =>
	Uri(alterExtension!newExtension(allUris, a.path));
Path alterExtension(Sym newExtension)(ref AllUris allUris, Path a) =>
	modifyBaseName(allUris, a, (Sym name) =>
		.alterExtension!newExtension(allUris.allSymbols, name));

// Adds an extension after any already existing extension.
Uri addExtension(Sym extension)(ref AllUris allUris, Uri a) =>
	Uri(addExtension!extension(allUris, a.path));
Path addExtension(Sym extension)(ref AllUris allUris, Path a) =>
	modifyBaseName(allUris, a, (Sym name) =>
		.addExtension!extension(allUris.allSymbols, name));

// E.g., changes 'foo.crow' to 'foo.deadbeef.c'
FileUri alterExtensionWithHex(Sym newExtension)(ref AllUris allUris, FileUri a, in ubyte[] bytes) =>
	FileUri(alterExtensionWithHexForPath!newExtension(allUris, a.path, bytes));
private Path alterExtensionWithHexForPath(Sym newExtension)(ref AllUris allUris, Path a, in ubyte[] bytes) =>
	modifyBaseName(allUris, a, (Sym name) =>
		addExtension!newExtension(
			allUris.allSymbols,
			appendHexExtension(allUris.allSymbols, removeExtension(allUris.allSymbols, name), bytes)));

private bool hasExtension(in AllUris allUris, Path a) =>
	hasExtension(allUris.allSymbols, baseName(allUris, a));

private Path modifyBaseName(ref AllUris allUris, Path a, in Sym delegate(Sym) @safe @nogc pure nothrow cb) {
	Sym newBaseName = cb(baseName(allUris, a));
	Opt!Path parent = parent(allUris, a);
	return has(parent) ? childPath(allUris, force(parent), newBaseName) : rootPath(allUris, newBaseName);
}

Sym getExtension(scope ref AllUris allUris, Uri a) =>
	isRootUri(allUris, a)
		? sym!""
		: getExtension(allUris, a.path);
Sym getExtension(scope ref AllUris allUris, Path a) =>
	getExtension(allUris.allSymbols, baseName(allUris, a));

Sym baseName(in AllUris allUris, Uri a) =>
	isRootUri(allUris, a)
		? sym!""
		: baseName(allUris, a.path);
Sym baseName(in AllUris allUris, Path a) =>
	allUris.pathToBaseName[a.index];

immutable struct PathFirstAndRest {
	Sym first;
	Opt!Path rest;
}

PathFirstAndRest firstAndRest(ref AllUris allUris, Path a) {
	Opt!Path par = parent(allUris, a);
	Sym baseName = baseName(allUris, a);
	if (has(par)) {
		PathFirstAndRest parentRes = firstAndRest(allUris, force(par));
		Path rest = has(parentRes.rest)
			? childPath(allUris, force(parentRes.rest), baseName)
			: rootPath(allUris, baseName);
		return PathFirstAndRest(parentRes.first, some(rest));
	} else
		return PathFirstAndRest(baseName, none!Path);
}

private Path getOrAddChild(ref AllUris allUris, ref MutArr!Path children, Opt!Path parent, Sym name) {
	foreach (Path child; tempAsArr(children))
		if (baseName(allUris, child) == name)
			return child;

	Path res = Path(safeToUshort(mutArrSize(allUris.pathToParent)));
	push(allUris.alloc, children, res);
	push(allUris.alloc, allUris.pathToParent, parent);
	push(allUris.alloc, allUris.pathToBaseName, name);
	push(allUris.alloc, allUris.pathToChildren, MutArr!Path());
	return res;
}

Path rootPath(ref AllUris allUris, Sym name) =>
	getOrAddChild(allUris, allUris.pathToChildren[Path.empty.index], none!Path, name);

Uri childUri(ref AllUris allUris, Uri parent, Sym name) =>
	Uri(childPath(allUris, parent.path, name));

FileUri childFileUri(ref AllUris allUris, FileUri parent, Sym name) =>
	FileUri(childPath(allUris, parent.path, name));

Uri bogusUri(ref AllUris allUris) =>
	parseUri(allUris, safeCStr!"bogus:bogus");

Path childPath(ref AllUris allUris, Path parent, Sym name) =>
	getOrAddChild(allUris, allUris.pathToChildren[parent.index], some(parent), name);

immutable struct RelPath {
	ushort nParents;
	Path path;
}

Opt!Uri resolveUri(ref AllUris allUris, Uri base, RelPath relPath) {
	if (relPath.nParents == 0)
		return some(concatUriAndPath(allUris, base, relPath.path));
	else {
		Opt!Uri par = parent(allUris, base);
		return has(par)
			? resolveUri(allUris, force(par), RelPath(cast(ushort) (relPath.nParents - 1), relPath.path))
			: none!Uri;
	}
}

Uri concatUriAndPath(ref AllUris allUris, Uri a, Path b) =>
	Uri(concatPaths(allUris, a.path, b));
private Path concatPaths(ref AllUris allUris, Path a, Path b) {
	Opt!Path bParent = parent(allUris, b);
	return childPath(allUris, has(bParent) ? concatPaths(allUris, a, force(bParent)) : a, baseName(allUris, b));
}

private void walkPathBackwards(
	in AllUris allUris,
	Path a,
	in void delegate(Sym, bool isFirstPart) @safe @nogc pure nothrow cb,
) {
	Opt!Path par = parent(allUris, a);
	cb(baseName(allUris, a), !has(par));
	if (has(par))
		walkPathBackwards(allUris, force(par), cb);
}

size_t pathLength(in AllUris allUris, Path path) =>
	pathToStrLength(allUris, path, PathToStrOptions(false, false));
private size_t pathToStrLength(in AllUris allUris, Path path, in PathToStrOptions options) {
	size_t res = 0;
	walkPathBackwards(allUris, path, (Sym part, bool _) {
		// 1 for '/'
		res += 1 + symSize(allUris.allSymbols, part);
	});
	assert(res > 0);
	// - 1 uncount the leading slash (before maybe adding it back)
	return res - 1 + options.leadingSlash + options.nulTerminate;
}

alias TempStrForPath = char[0x1000];

private @trusted SafeCStr uriToTempStr(return ref TempStrForPath temp, in AllUris allUris, Uri uri) =>
	pathToTempStr(temp, allUris, uri.path, false);
@trusted SafeCStr fileUriToTempStr(return ref TempStrForPath temp, in AllUris allUris, FileUri uri) =>
	pathToTempStr(temp, allUris, uri.path, true);
private @trusted SafeCStr pathToTempStr(
	return ref TempStrForPath temp,
	in AllUris allUris,
	Path path,
	bool leadingSlash,
) {
	PathToStrOptions options = PathToStrOptions(true, true);
	size_t length = pathToStrLength(allUris, path, options);
	assert(length <= temp.length);
	pathToStrWorker(allUris, path, temp[0 .. length], options);
	return SafeCStr(cast(immutable) temp.ptr);
}

private immutable struct PathToStrOptions {
	bool leadingSlash;
	bool nulTerminate;
}
private @system void pathToStrWorker(in AllUris allUris, Path path, char[] outBuf, in PathToStrOptions options) {
	char* cur = endPtr(outBuf);
	if (options.nulTerminate) {
		cur--;
		*cur = '\0';
	}
	walkPathBackwards(allUris, path, (Sym part, bool isFirstPart) @trusted {
		char* partEnd = cur;
		cur -= symSize(allUris.allSymbols, part);
		char* j = cur;
		eachCharInSym(allUris.allSymbols, part, (char c) @trusted {
			*j = c;
			j++;
		});
		assert(j == partEnd);
		if (!isFirstPart || options.leadingSlash) {
			cur--;
			*cur = '/';
		}
	});
	assert(cur == &outBuf[0]);
}

SafeCStr safeCStrOfUri(ref Alloc alloc, in AllUris allUris, Uri a) =>
	pathToSafeCStr(alloc, allUris, a.path, false);
string stringOfUri(ref Alloc alloc, in AllUris allUris, Uri a) =>
	strOfSafeCStr(safeCStrOfUri(alloc, allUris, a));
SafeCStr fileUriToSafeCStr(ref Alloc alloc, in AllUris allUris, FileUri a) =>
	pathToSafeCStr(alloc, allUris, a.path, true);
@trusted SafeCStr pathToSafeCStr(ref Alloc alloc, in AllUris allUris, Path path, bool leadingSlash) {
	PathToStrOptions options = PathToStrOptions(leadingSlash, true);
	size_t length = pathToStrLength(allUris, path, options);
	char[] res = allocateElements!char(alloc, length);
	pathToStrWorker(allUris, path, res, options);
	return SafeCStr(cast(immutable) res.ptr);
}

public SafeCStr uriToSafeCStrPreferRelative(ref Alloc alloc, in AllUris allUris, ref UrisInfo urisInfo, Uri a) =>
	withWriter(alloc, (scope ref Writer writer) {
		writeUriPreferRelative(writer, allUris, urisInfo, a);
	});

Uri parseUri(ref AllUris allUris, in SafeCStr str) =>
	parseUri(allUris, strOfSafeCStr(str));
Uri parseUri(ref AllUris allUris, in string uri) {
	Opt!size_t optColon = indexOf(uri, ':');
	if (has(optColon)) {
		size_t colon = force(optColon);
		size_t start = colon < uri.length - 2 && uri[colon + 1] == '/' && uri[colon + 2] == '/' ? colon + 3 : colon + 1;
		Opt!size_t slash = indexOfStartingAt(uri, '/', start);
		return has(slash)
			? concatUriAndPath(
				allUris,
				rootUri(allUris, uri[0 .. force(slash)]),
				parsePath(allUris, uri[force(slash) + 1 .. $]))
			: rootUri(allUris, uri);
	} else
		return toUri(allUris, FileUri(parsePath(allUris, uri)));
}
private Uri rootUri(ref AllUris allUris, in string schemeAndAuthority) =>
	Uri(rootPath(allUris, symOfStr(allUris.allSymbols, schemeAndAuthority)));

Path parsePath(ref AllUris allUris, in SafeCStr str) =>
	parsePath(allUris, strOfSafeCStr(str));
private Path parsePath(ref AllUris allUris, in string str) {
	StringIter iter = StringIter(str);
	skipWhile(iter, (char x) => x == '/');
	string part = parsePathPart(allUris, iter);
	return parsePathRecur(allUris, iter, rootPath(allUris, symOfStr(allUris.allSymbols, part)));
}
private Path parsePathRecur(ref AllUris allUris, scope ref StringIter iter, Path path) {
	skipWhile(iter, (char x) => isSlash(x));
	if (done(iter))
		return path;
	else {
		string part = parsePathPart(allUris, iter);
		return parsePathRecur(allUris, iter, childPath(allUris, path, symOfStr(allUris.allSymbols, part)));
	}
}
private @trusted string parsePathPart(ref AllUris allUris, return scope ref StringIter iter) {
	immutable char* begin = iter.cur;
	skipWhile(iter, (char x) => !isSlash(x));
	return begin[0 .. (iter.cur - begin)];
}

private @trusted RelPath parseRelPath(ref AllUris allUris, in string a) =>
	parseRelPathRecur(allUris, 0, a);
private @system RelPath parseRelPathRecur(ref AllUris allUris, size_t nParents, in string a) =>
	a.length >= 2 && a[0] == '.' && isSlash(a[1])
		? parseRelPathRecur(allUris, nParents, a[2 .. $])
		: a.length >= 3 && a[0] == '.' && a[1] == '.' && isSlash(a[2])
		? parseRelPathRecur(allUris, nParents + 1, a[3 .. $])
		: RelPath(safeToUshort(nParents), parsePath(allUris, a));

FileUri parseAbsoluteFilePathAsUri(ref AllUris allUris, in SafeCStr a) =>
	FileUri(parsePath(allUris, a));
FileUri parseAbsoluteFilePathAsUri(ref AllUris allUris, in string a) =>
	FileUri(parsePath(allUris, a));

Uri parseUriWithCwd(ref AllUris allUris, Uri cwd, in SafeCStr a) =>
	parseUriWithCwd(allUris, cwd, strOfSafeCStr(a));
Uri parseUriWithCwd(ref AllUris allUris, Uri cwd, in string a) {
	//TODO: handle actual URIs...
	if (looksLikeAbsolutePath(a))
		return toUri(allUris, parseAbsoluteFilePathAsUri(allUris, a));
	else if (looksLikeUri(a))
		return parseUri(allUris, a);
	else {
		//TODO: handle parse error (return none if so)
		RelPath rp = parseRelPath(allUris, a);
		Opt!Uri resolved = resolveUri(allUris, cwd, rp);
		return has(resolved)
			? force(resolved)
			: todo!Uri("relative path reaches past file system root");
	}
}

private @trusted bool looksLikeAbsolutePath(in string a) =>
	(a.length >= 1 && a[0] == '/') ||
	(a.length >= 3 && a[0] == 'C' && a[1] == ':' && isSlash(a[2]));

private bool looksLikeUri(in string a) =>
	containsSubstring(a, "://");

private bool containsSubstring(in string a, in string b) =>
	a.length >= b.length && (a[0 .. b.length] == b || containsSubstring(a[1 .. $], b));

@trusted Comparison compareUriAlphabetically(in AllUris allUris, Uri a, Uri b) {
	//TODO:PERF
	TempStrForPath aBuf;
	TempStrForPath bBuf;
	uriToTempStr(aBuf, allUris, a);
	uriToTempStr(bBuf, allUris, b);
	return compareSafeCStrAlphabetically(SafeCStr(cast(immutable) aBuf.ptr), SafeCStr(cast(immutable) bBuf.ptr));
}

immutable struct UriAndRange {
	Uri uri;
	Range range;
}

immutable struct UrisInfo {
	Opt!Uri cwd;
}

bool isAncestor(in AllUris allUris, Uri a, Uri b) {
	if (a == b)
		return true;
	else {
		Opt!Uri par = parent(allUris, b);
		return has(par) && isAncestor(allUris, a, force(par));
	}
}

Opt!Uri commonAncestor(in AllUris allUris, in Uri[] uris) =>
	uris.length == 0
		? none!Uri
		: commonAncestorRecur(allUris, uris[0], uris[1 .. $]);
private Opt!Uri commonAncestorRecur(in AllUris allUris, Uri cur, in Uri[] uris) {
	if (uris.length == 0)
		return some(cur);
	else {
		Opt!Uri x = commonAncestorBinary(allUris, cur, uris[0]);
		return has(x) ? commonAncestorRecur(allUris, force(x), uris[1 .. $]) : none!Uri;
	}
}
private Opt!Uri commonAncestorBinary(in AllUris allUris, Uri a, Uri b) {
	size_t aParts = countPathParts(allUris, a.path);
	size_t bParts = countPathParts(allUris, b.path);
	return aParts > bParts
		? commonAncestorRecur(allUris, removeLastNParts(allUris, a, aParts - bParts), b)
		: commonAncestorRecur(allUris, a, removeLastNParts(allUris, b, bParts - aParts));
}
private Opt!Uri commonAncestorRecur(in AllUris allUris, Uri a, Uri b) {
	if (a == b)
		return some(a);
	else {
		Opt!Uri parA = parent(allUris, a);
		Opt!Uri parB = parent(allUris, b);
		return has(parA)
			? commonAncestorRecur(allUris, force(parA), force(parB))
			: none!Uri;
	}
}

private:

void eachPartPreferRelative(
	in AllUris allUris,
	ref UrisInfo urisInfo,
	Uri a,
	in void delegate(Sym, bool) @safe @nogc pure nothrow cb,
) {
	size_t maxParts = () {
		if (has(urisInfo.cwd)) {
			Uri cwd = force(urisInfo.cwd);
			size_t cwdParts = countPathParts(allUris, cwd.path);
			size_t aParts = countPathParts(allUris, a.path);
			return aParts > cwdParts && cwd == removeLastNParts(allUris, a, aParts - cwdParts)
				? aParts - cwdParts
				: size_t.max;
		} else
			return size_t.max;
	}();
	eachPart(allUris, a.path, maxParts, cb);
}

bool isSlash(char a) =>
	a == '/' || a == '\\';

size_t countPathParts(in AllUris allUris, Path a) =>
	countPathPartsRecur(1, allUris, a);
size_t countPathPartsRecur(size_t acc, in AllUris allUris, Path a) {
	Opt!Path par = parent(allUris, a);
	return has(par) ? countPathPartsRecur(acc + 1, allUris, force(par)) : acc;
}

Uri removeLastNParts(in AllUris allUris, Uri a, size_t nToRemove) {
	if (nToRemove == 0)
		return a;
	else {
		Opt!Uri par = parent(allUris, a);
		return removeLastNParts(allUris, force(par), nToRemove - 1);
	}
}

public void TEST_eachPart(
	in AllUris allUris,
	Path a,
	in void delegate(Sym) @safe @nogc pure nothrow cb,
) {
	eachPart(allUris, a, size_t.max, (Sym x, bool _) {
		cb(x);
	});
}

void eachPart(
	in AllUris allUris,
	Path a,
	size_t maxParts,
	in void delegate(Sym, bool) @safe @nogc pure nothrow cb,
) {
	assert(maxParts > 0);
	Opt!Path par = parent(allUris, a);
	if (has(par))
		eachPartRecur(allUris, force(par), maxParts - 1, cb);
	cb(baseName(allUris, a), true);
}

void eachPartRecur(
	in AllUris allUris,
	Path a,
	size_t maxParts,
	in void delegate(Sym, bool) @safe @nogc pure nothrow cb,
) {
	if (maxParts != 0) {
		Opt!Path par = parent(allUris, a);
		if (has(par))
			eachPartRecur(allUris, force(par), maxParts - 1, cb);
		cb(baseName(allUris, a), false);
	}
}

public void writeUri(ref Writer writer, in AllUris allUris, Uri a) {
	writePathPlain(writer, allUris, a.path);
}

public void writeFileUri(ref Writer writer, in AllUris allUris, FileUri a) {
	writePathPlain(writer, allUris, a.path);
}

void writePathPlain(ref Writer writer, in AllUris allUris, Path p) {
	Opt!Path par = parent(allUris, p);
	if (has(par)) {
		writePathPlain(writer, allUris, force(par));
		writer ~= '/';
	}
	writeSym(writer, allUris.allSymbols, baseName(allUris, p));
}

public void writeUriPreferRelative(ref Writer writer, in AllUris allUris, in UrisInfo urisInfo, Uri a) {
	eachPartPreferRelative(allUris, urisInfo, a, (Sym part, bool isLast) {
		writeSym(writer, allUris.allSymbols, part);
		if (!isLast)
			writer ~= '/';
	});
}

public size_t relPathLength(in AllUris allUris, in RelPath a) =>
	(a.nParents == 0 ? "./".length : a.nParents * "../".length) + pathLength(allUris, a.path);

public void writeRelPath(ref Writer writer, in AllUris allUris, in RelPath a) {
	foreach (ushort i; 0 .. a.nParents)
		writer ~= "../";
	writePathPlain(writer, allUris, a.path);
}

struct StringIter {
	@safe @nogc pure nothrow:

	immutable(char)* cur;
	immutable(char)* end;

	@trusted this(return scope string a) {
		cur = a.ptr;
		end = a.ptr + a.length;
	}
}
bool done(in StringIter a) =>
	a.cur == a.end;
@trusted void skipWhile(ref StringIter a, in bool delegate(char) @safe @nogc pure nothrow cb) {
	while (!done(a) && cb(*a.cur))
		a.cur++;
}
