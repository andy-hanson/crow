module util.uri;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc, allocateT;
import util.col.arrUtil : reduce;
import util.col.mutArr : MutArr, mutArrRange, mutArrSize, push;
import util.col.str : compareSafeCStrAlphabetically, end, SafeCStr, safeCStr, strOfSafeCStr;
import util.comparison : Comparison;
import util.conv : safeToUshort;
import util.hash : Hasher, hashUshort;
import util.opt : has, force, none, Opt, some;
import util.ptr : ptrTrustMe;
import util.sourceRange : RangeWithinFile;
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
import util.util : todo, verify;
import util.writer : finishWriterToSafeCStr, Writer;

alias MutFullIndexMap(K, V) = MutArr!V;

struct AllUris {
	@safe @nogc pure nothrow:
	private:
	Alloc* alloc;
	AllSymbols* allSymbolsPtr;
	MutArr!(Opt!Path) pathToParent;
	MutArr!Sym pathToBaseName;
	MutArr!(MutArr!Path) pathToChildren;
	MutArr!Path rootChildren;

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

	void hash(ref Hasher hasher) scope {
		path.hash(hasher);
	}
}

bool isPathlessUri(in AllUris allUris, Uri a) =>
	!has(parent(allUris, a));

bool isFileUri(in AllUris allUris, Uri a) =>
	todo!bool("isFileUri");

FileUri asFileUri(in AllUris allUris, Uri a) {
	verify(isFileUri(allUris, a));
	// Strip the first component (after asserting that it's `file:`)
	return todo!FileUri("asFileUri");
}

// Uri that is restricted to be a 'file:'
immutable struct FileUri {
	// Unlike for a Uri, this doesn't have "file" as the first component
	private Path path;
}

Uri toUri(in AllUris allUris, FileUri a) =>
	todo!Uri("toUri");

// Represents the path part of a URI, e.g. 'a/b/c'
immutable struct Path {
	@safe @nogc pure nothrow:

	private ushort index;

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

Uri addExtensionIfNone(Sym extension)(ref AllUris allUris, Uri a) =>
	Uri(addExtensionIfNone!extension(allUris, a.path));
Path addExtensionIfNone(Sym extension)(ref AllUris allUris, Path a) =>
	hasExtension(allUris, a) ? a : addExtension!extension(allUris, a);

private bool hasExtension(in AllUris allUris, Path a) =>
	hasExtension(allUris.allSymbols, baseName(allUris, a));

private Path modifyBaseName(ref AllUris allUris, Path a, in Sym delegate(Sym) @safe @nogc pure nothrow cb) {
	Sym newBaseName = cb(baseName(allUris, a));
	Opt!Path parent = parent(allUris, a);
	return has(parent) ? childPath(allUris, force(parent), newBaseName) : rootPath(allUris, newBaseName);
}

Sym getExtension(ref AllUris allUris, Uri a) =>
	isPathlessUri(allUris, a)
		? sym!""
		: getExtension(allUris, a.path);
Sym getExtension(ref AllUris allUris, Path a) =>
	getExtension(allUris.allSymbols, baseName(allUris, a));

Sym baseName(in AllUris allUris, Uri a) =>
	isPathlessUri(allUris, a)
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
	foreach (Path child; mutArrRange(children))
		if (baseName(allUris, child) == name)
			return child;

	Path res = Path(safeToUshort(mutArrSize(allUris.pathToParent)));
	push(*allUris.alloc, children, res);
	push(*allUris.alloc, allUris.pathToParent, parent);
	push(*allUris.alloc, allUris.pathToBaseName, name);
	push(*allUris.alloc, allUris.pathToChildren, MutArr!Path());
	return res;
}

Path emptyRootPath(ref AllUris allUris) =>
	rootPath(allUris, sym!"");

Path rootPath(ref AllUris allUris, Sym name) =>
	getOrAddChild(allUris, allUris.rootChildren, none!Path, name);

Uri childUri(ref AllUris allUris, Uri parent, Sym name) =>
	Uri(childPath(allUris, parent.path, name));

FileUri childFileUri(ref AllUris allUris, FileUri parent, Sym name) =>
	FileUri(childPath(allUris, parent.path, name));

Uri bogusUri(ref AllUris allUris) =>
	parseUri(allUris, safeCStr!"bogus:bogus");

Path childPath(ref AllUris allUris, Path parent, Sym name) =>
	getOrAddChild(allUris, allUris.pathToChildren[parent.index], some(parent), name);

immutable struct PathOrRelPath {
	private:
	Opt!ushort nParents_;
	Path path_;
}

T matchPathOrRelPath(T)(
	PathOrRelPath a,
	in T delegate(Path) @safe @nogc pure nothrow cbGlobal,
	in T delegate(RelPath) @safe @nogc pure nothrow cbRel,
) =>
	has(a.nParents_)
		? cbRel(RelPath(force(a.nParents_), a.path_))
		: cbGlobal(a.path_);

immutable struct RelPath {
	private ushort nParents;
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

private size_t pathToStrLength(in AllUris allUris, string prefix, size_t prefixMultiple, Path path) {
	size_t res = 0;
	if (prefixMultiple != 0)
		res += prefix.length * prefixMultiple + 1;
	walkPathBackwards(allUris, path, (Sym part, bool isFirstPart) {
		// 1 for '/'
		res += (isFirstPart ? 0 : 1) + symSize(allUris.allSymbols, part);
	});
	return res + 1;
}

alias TempStrForPath = char[0x1000];

SafeCStr fileUriToTempStr(scope return ref TempStrForPath temp, in AllUris allUris, FileUri uri) =>
	pathToTempStr(temp, allUris, uri.path);

private @trusted SafeCStr pathToTempStr(scope return ref TempStrForPath temp, in AllUris allUris, Path path) {
	size_t length = pathToStrLength(allUris, "", 0, path);
	verify(length < temp.length);
	pathToStrWorker2(allUris, "", 0, path, temp.ptr, temp.ptr + length);
	return SafeCStr(cast(immutable) temp.ptr);
}

private string pathToStrWorker(ref Alloc alloc, in AllUris allUris, Path path) =>
	pathToStrWorker(alloc, allUris, "", 0, path);

private @trusted string pathToStrWorker(
	ref Alloc alloc,
	in AllUris allUris,
	in string prefix,
	size_t prefixCount,
	Path path,
) {
	size_t length = pathToStrLength(allUris, prefix, prefixCount, path);
	char* begin = allocateT!char(alloc, length);
	pathToStrWorker2(allUris, prefix, prefixCount, path, begin, begin + length);
	return cast(immutable) begin[0 .. length];
}

private @system void pathToStrWorker2(
	in AllUris allUris,
	in string prefix,
	size_t prefixMultiple,
	Path path,
	scope char* begin,
	scope char* end,
) {
	char* cur = end - 1;
	*cur = '\0';
	walkPathBackwards(allUris, path, (Sym part, bool isFirstPart) @trusted {
		cur -= symSize(allUris.allSymbols, part);
		char* j = cur;
		eachCharInSym(allUris.allSymbols, part, (char c) @trusted {
			*j = c;
			j++;
		});
		verify(j == cur + symSize(allUris.allSymbols, part));
		if (!isFirstPart) {
			cur--;
			*cur = '/';
		}
	});
	if (prefixMultiple != 0) {
		cur--;
		*cur = '/';
		const char* rootEnd = cur;
		verify(rootEnd == begin + prefix.length * prefixMultiple);
		cur = begin;
		foreach (size_t i; 0 .. prefixMultiple)
			foreach (char c; prefix) {
				*cur = c;
				cur++;
			}
		verify(cur == rootEnd);
	}
}

SafeCStr pathOrRelPathToStr(ref Alloc alloc, in AllUris allUris, PathOrRelPath a) =>
	matchPathOrRelPath(
		a,
		(Path global) =>
			pathToSafeCStr(alloc, allUris, global),
		(RelPath relPath) =>
			relPathToSafeCStr(alloc, allUris, relPath));

private @trusted SafeCStr relPathToSafeCStr(ref Alloc alloc, in AllUris allUris, RelPath a) =>
	SafeCStr(a.nParents == 0
		? pathToStrWorker(alloc, allUris, ".", 1, a.path).ptr
		: pathToStrWorker(alloc, allUris, "..", a.nParents, a.path).ptr);

SafeCStr uriToSafeCStr(ref Alloc alloc, in AllUris allUris, Uri a) =>
	pathToSafeCStr(alloc, allUris, a.path);
SafeCStr fileUriToSafeCStr(ref Alloc alloc, in AllUris allUris, FileUri a) =>
	pathToSafeCStr(alloc, allUris, a.path);
@trusted SafeCStr pathToSafeCStr(ref Alloc alloc, in AllUris allUris, Path path) =>
	immutable SafeCStr(pathToStrWorker(alloc, allUris, path).ptr);

public SafeCStr uriToSafeCStrPreferRelative(ref Alloc alloc, in AllUris allUris, ref UrisInfo urisInfo, Uri a) {
	Writer writer = Writer(ptrTrustMe(alloc));
	writeUri(writer, allUris, urisInfo, a);
	return finishWriterToSafeCStr(writer);
}

Uri parseUri(ref AllUris allUris, in SafeCStr str) =>
	todo!Uri("parseUri");
Uri parseUri(ref AllUris allUris, in string) =>
	todo!Uri("parseUri");
Path parsePath(ref AllUris allUris, in SafeCStr str) =>
	parsePath(allUris, strOfSafeCStr(str));
Path parsePath(ref AllUris allUris, in string str) {
	StringIter iter = StringIter(str);
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
	parseAbsoluteFilePathAsUri(allUris, strOfSafeCStr(a));
FileUri parseAbsoluteFilePathAsUri(ref AllUris allUris, in string a) =>
	todo!FileUri("parseAbsoluteFilePathAsUri");

Uri parseUriWithCwd(ref AllUris allUris, Uri cwd, in SafeCStr a) =>
	parseUriWithCwd(allUris, cwd, strOfSafeCStr(a));
Uri parseUriWithCwd(ref AllUris allUris, Uri cwd, in string a) {
	//TODO: handle actual URIs...
	if (looksLikeAbsolutePath(a))
		return toUri(allUris, parseAbsoluteFilePathAsUri(allUris, a));
	else {
		//TODO: handle parse error (return none if so)
		RelPath rp = parseRelPath(allUris, a);
		Opt!Uri resolved = resolveUri(allUris, cwd, rp);
		return has(resolved)
			? force(resolved)
			: todo!Uri("relative path reaches past file system root");
	}
}

private @trusted bool looksLikeAbsolutePath(string a) =>
	(a.length >= 1 && a[0] == '/') ||
	(a.length >= 3 && a[0] == 'C' && a[1] == ':' && isSlash(a[2]));

Comparison compareUriAlphabetically(in AllUris allUris, Uri a, Uri b) =>
	comparePathAlphabetically(allUris, a.path, b.path);

@trusted Comparison comparePathAlphabetically(in AllUris allUris, Path a, Path b) {
	//TODO:PERF
	TempStrForPath aBuf;
	TempStrForPath bBuf;
	pathToTempStr(aBuf, allUris, a);
	pathToTempStr(bBuf, allUris, b);
	return compareSafeCStrAlphabetically(SafeCStr(cast(immutable) aBuf.ptr), SafeCStr(cast(immutable) bBuf.ptr));
}

immutable struct UriAndRange {
	Uri uri;
	RangeWithinFile range;
}

immutable struct UrisInfo {
	@disable this(ref const UrisInfo);
	Opt!Uri cwd;
}

UrisInfo emptyUrisInfo() =>
	UrisInfo(none!Uri);

Opt!Uri commonAncestor(in AllUris allUris, in Uri[] uris) =>
	uris.length == 0
		? none!Uri
		: commonAncestorRecur(allUris, uris[0], uris[1 .. $]);
Opt!Uri commonAncestorRecur(in AllUris allUris, Uri cur, in Uri[] uris) {
	if (uris.length == 0)
		return some(cur);
	else {
		Opt!Uri x = commonAncestorBinary(allUris, cur, uris[0]);
		return has(x) ? commonAncestorRecur(allUris, force(x), uris[1 .. $]) : none!Uri;
	}
}
private Opt!Uri commonAncestorBinary(in AllUris allUris, Uri a, Uri b) {
	return todo!(Opt!Uri)("commonAncestorBinary");
}
/*
private Path commonAncestorBinary(in AllUris allUris, Path a, Path b) {
	size_t aParts = countPathParts(allUris, a);
	size_t bParts = countPathParts(allUris, b);
	return aParts > bParts
		? commonAncestorRecur(allUris, removeLastNParts(allUris, a, aParts - bParts), b)
		: commonAncestorRecur(allUris, a, removeLastNParts(allUris, b, bParts - aParts));
}
private Path commonAncestorRecur(in AllUris allUris, Path a, Path b) {
	if (a == b)
		return a;
	else {
		Opt!Path parA = parent(allUris, a);
		Opt!Path parB = parent(allUris, b);
		return commonAncestorRecur(allUris, force(parA), force(parB));
	}
}
*/

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

void eachPart(
	in AllUris allUris,
	Path a,
	size_t maxParts,
	in void delegate(Sym, bool) @safe @nogc pure nothrow cb,
) {
	verify(maxParts > 0);
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

public void writeUri(ref Writer writer, in AllUris allUris, ref UrisInfo urisInfo, Uri a) {
	eachPartPreferRelative(allUris, urisInfo, a, (Sym part, bool isLast) {
		writeSym(writer, allUris.allSymbols, part);
		if (!isLast)
			writer ~= '/';
	});
}

public void writeRelPath(ref Writer writer, in AllUris allUris, RelPath p) {
	foreach (ushort i; 0 .. p.nParents)
		writer ~= "../";
	writePathPlain(writer, allUris, p.path);
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
