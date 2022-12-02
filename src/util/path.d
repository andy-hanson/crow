module util.path;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc, allocateT;
import util.col.arrUtil : reduce;
import util.col.mutArr : MutArr, mutArrRange, mutArrSize, push;
import util.col.str : CStr, end, SafeCStr;
import util.comparison : compareNat16, Comparison;
import util.conv : safeToUshort;
import util.hash : Hasher, hashUshort;
import util.opt : has, force, none, Opt, some;
import util.ptr : ptrTrustMe;
import util.sourceRange : RangeWithinFile;
import util.sym : AllSymbols, eachCharInSym, Sym, sym, symOfStr, symSize, writeSym;
import util.util : todo, verify;
import util.writer : finishWriterToSafeCStr, Writer;

struct AllPaths {
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

immutable struct Path {
	@safe @nogc pure nothrow:

	private ushort index;

	void hash(ref Hasher hasher) scope const {
		hashUshort(hasher, index);
	}
}

Opt!Path parent(in AllPaths allPaths, Path a) =>
	allPaths.pathToParent[a.index];

Path parentOrEmpty(ref AllPaths allPaths, Path a) {
	Opt!Path res = parent(allPaths, a);
	return has(res) ? force(res) : emptyRootPath(allPaths);
}

Sym baseName(in AllPaths allPaths, Path a) =>
	allPaths.pathToBaseName[a.index];

immutable struct PathFirstAndRest {
	Sym first;
	Opt!Path rest;
}

PathFirstAndRest firstAndRest(ref AllPaths allPaths, Path a) {
	Opt!Path par = parent(allPaths, a);
	Sym baseName = baseName(allPaths, a);
	if (has(par)) {
		PathFirstAndRest parentRes = firstAndRest(allPaths, force(par));
		Path rest = has(parentRes.rest)
			? childPath(allPaths, force(parentRes.rest), baseName)
			: rootPath(allPaths, baseName);
		return PathFirstAndRest(parentRes.first, some(rest));
	} else
		return PathFirstAndRest(baseName, none!Path);
}

private Path getOrAddChild(ref AllPaths allPaths, ref MutArr!Path children, Opt!Path parent, Sym name) {
	foreach (Path child; mutArrRange(children))
		if (baseName(allPaths, child) == name)
			return child;

	Path res = Path(safeToUshort(mutArrSize(allPaths.pathToParent)));
	push(*allPaths.alloc, children, res);
	push(*allPaths.alloc, allPaths.pathToParent, parent);
	push(*allPaths.alloc, allPaths.pathToBaseName, name);
	push(*allPaths.alloc, allPaths.pathToChildren, MutArr!Path());
	return res;
}

Path emptyRootPath(ref AllPaths allPaths) =>
	rootPath(allPaths, sym!"");

Path rootPath(ref AllPaths allPaths, Sym name) =>
	getOrAddChild(allPaths, allPaths.rootChildren, none!Path, name);

Path childPath(ref AllPaths allPaths, Path parent, Sym name) =>
	getOrAddChild(allPaths, allPaths.pathToChildren[parent.index], some(parent), name);

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

Opt!Path resolvePath(ref AllPaths allPaths, Opt!Path path, RelPath relPath) =>
	relPath.nParents == 0
		? some(has(path)
			? concatPaths(allPaths, force(path), relPath.path)
			: relPath.path)
		: has(path)
			? resolvePath(
				allPaths,
				parent(allPaths, force(path)),
				RelPath(cast(ushort) (relPath.nParents - 1), relPath.path))
			: none!Path;

Opt!Path resolvePath(ref AllPaths allPaths, Path path, RelPath relPath) =>
	resolvePath(allPaths, some(path), relPath);

Path concatPaths(ref AllPaths allPaths, Path a, Path b) {
	Opt!Path bParent = parent(allPaths, b);
	return childPath(allPaths, has(bParent) ? concatPaths(allPaths, a, force(bParent)) : a, baseName(allPaths, b));
}

private void walkPathBackwards(
	in AllPaths allPaths,
	Path a,
	in void delegate(Sym, bool isFirstPart) @safe @nogc pure nothrow cb,
) {
	Opt!Path par = parent(allPaths, a);
	cb(baseName(allPaths, a), !has(par));
	if (has(par))
		walkPathBackwards(allPaths, force(par), cb);
}

private size_t pathToStrLength(in AllPaths allPaths, string prefix, size_t prefixMultiple, Path path, Sym extension) {
	size_t res = 0;
	if (prefixMultiple != 0)
		res += prefix.length * prefixMultiple + 1;
	walkPathBackwards(allPaths, path, (Sym part, bool isFirstPart) {
		// 1 for '/'
		res += (isFirstPart ? 0 : 1) + symSize(allPaths.allSymbols, part);
	});
	return res + symSize(allPaths.allSymbols, extension) + 1;
}

alias TempStrForPath = char[0x1000];

@trusted SafeCStr pathToTempStr(scope return ref TempStrForPath temp, in AllPaths allPaths, PathAndExtension path) =>
	pathToTempStr(temp, allPaths, path.path, path.extension);

@trusted SafeCStr pathToTempStr(
	scope return ref TempStrForPath temp,
	in AllPaths allPaths,
	Path path,
	Sym extension = sym!"",
) {
	size_t length = pathToStrLength(allPaths, "", 0, path, extension);
	verify(length < temp.length);
	pathToStrWorker2(allPaths, "", 0, path, extension, temp.ptr, temp.ptr + length);
	return SafeCStr(cast(immutable) temp.ptr);
}

private string pathToStrWorker(ref Alloc alloc, in AllPaths allPaths, Path path, Sym extension) =>
	pathToStrWorker(alloc, allPaths, "", 0, path, extension);

private @trusted string pathToStrWorker(
	ref Alloc alloc,
	in AllPaths allPaths,
	in string prefix,
	size_t prefixCount,
	Path path,
	Sym extension,
) {
	size_t length = pathToStrLength(allPaths, prefix, prefixCount, path, extension);
	char* begin = allocateT!char(alloc, length);
	pathToStrWorker2(allPaths, prefix, prefixCount, path, extension, begin, begin + length);
	return cast(immutable) begin[0 .. length];
}

private @system void pathToStrWorker2(
	in AllPaths allPaths,
	in string prefix,
	size_t prefixMultiple,
	Path path,
	Sym extension,
	scope char* begin,
	scope char* end,
) {
	char* cur = end - 1;
	*cur = '\0';
	size_t extensionSize = symSize(allPaths.allSymbols, extension);
	cur -= extensionSize;
	eachCharInSym(allPaths.allSymbols, extension, (char c) @trusted {
		*cur = c;
		cur++;
	});
	cur -= extensionSize;
	verify(cur == end - 1 - extensionSize);
	walkPathBackwards(allPaths, path, (Sym part, bool isFirstPart) @trusted {
		cur -= symSize(allPaths.allSymbols, part);
		char* j = cur;
		eachCharInSym(allPaths.allSymbols, part, (char c) @trusted {
			*j = c;
			j++;
		});
		verify(j == cur + symSize(allPaths.allSymbols, part));
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

SafeCStr pathOrRelPathToStr(ref Alloc alloc, in AllPaths allPaths, PathOrRelPath a) =>
	matchPathOrRelPath(
		a,
		(Path global) =>
			pathToSafeCStr(alloc, allPaths, global, sym!""),
		(RelPath relPath) =>
			relPathToSafeCStr(alloc, allPaths, relPath));

private @trusted SafeCStr relPathToSafeCStr(ref Alloc alloc, in AllPaths allPaths, RelPath a) =>
	SafeCStr(a.nParents == 0
		? pathToStrWorker(alloc, allPaths, "./", 1, a.path, sym!"").ptr
		: pathToStrWorker(alloc, allPaths, "../", a.nParents, a.path, sym!"").ptr);

SafeCStr pathToSafeCStr(ref Alloc alloc, in AllPaths allPaths, PathAndExtension path) =>
	pathToSafeCStr(alloc, allPaths, path.path, path.extension);

@trusted SafeCStr pathToSafeCStr(ref Alloc alloc, in AllPaths allPaths, Path path, Sym extension = sym!"") =>
	immutable SafeCStr(pathToStrWorker(alloc, allPaths, path, extension).ptr);

public SafeCStr pathToSafeCStrPreferRelative(ref Alloc alloc, in AllPaths allPaths, ref PathsInfo pathsInfo, Path a) {
	Writer writer = Writer(ptrTrustMe(alloc));
	writePath(writer, allPaths, pathsInfo, a, sym!"");
	return finishWriterToSafeCStr(writer);
}

@trusted Path parsePath(ref AllPaths allPaths, in SafeCStr str) {
	PathAndExtension pe = parsePathAndExtension(allPaths, str);
	verify(pe.extension == sym!"");
	return pe.path;
}

Path parsePathDropExtension(ref AllPaths allPaths, in SafeCStr str) =>
	parsePathAndExtension(allPaths, str).path;

immutable struct PathAndExtension {
	Path path;
	Sym extension;
}

private @trusted PathAndExtension parsePathAndExtension(ref AllPaths allPaths, in SafeCStr str) {
	immutable(char)* ptr = str.ptr;
	string part = parsePathPart(allPaths, ptr);
	if (*ptr == '\0') {
		StrAndExtension se = removeExtension(allPaths.allSymbols, part.ptr);
		return PathAndExtension(
			rootPath(allPaths, symOfStr(allPaths.allSymbols, se.withoutExtension)),
			se.extension);
	} else
		return parsePathAndExtensionRecur(allPaths, ptr, rootPath(allPaths, symOfStr(allPaths.allSymbols, part)));
}
private @system PathAndExtension parsePathAndExtensionRecur(ref AllPaths allPaths, immutable(char)* ptr, Path path) {
	while (isSlash(*ptr))
		ptr++;

	if (*ptr == '\0')
		return PathAndExtension(path, sym!"");
	else {
		string part = parsePathPart(allPaths, ptr);
		if (*ptr == '\0') {
			StrAndExtension se = removeExtension(allPaths.allSymbols, part.ptr);
			return PathAndExtension(
				childPath(allPaths, path, symOfStr(allPaths.allSymbols, se.withoutExtension)),
				se.extension);
		} else
			return parsePathAndExtensionRecur(
				allPaths,
				ptr,
				childPath(allPaths, path, symOfStr(allPaths.allSymbols, part)));
	}
}
private @system string parsePathPart(ref AllPaths allPaths, ref immutable(char)* ptr) {
	immutable char* begin = ptr;
	while (*ptr != '\0' && !isSlash(*ptr))
		ptr++;
	return begin[0 .. (ptr - begin)];
}

private immutable struct RelPathAndExtension {
	RelPath relPath;
	Sym extension;
}

private @trusted RelPathAndExtension parseRelPathAndExtension(ref AllPaths allPaths, SafeCStr a) =>
	parseRelPathAndExtensionRecur(allPaths, 0, a);
private @system RelPathAndExtension parseRelPathAndExtensionRecur(ref AllPaths allPaths, size_t nParents, SafeCStr a) {
	if (a.ptr[0] == '.' && isSlash(a.ptr[1]))
		return parseRelPathAndExtensionRecur(allPaths, nParents, SafeCStr(a.ptr + 2));
	else if (a.ptr[0] == '.' && a.ptr[1] == '.' && isSlash(a.ptr[2]))
		return parseRelPathAndExtensionRecur(allPaths, nParents + 1, SafeCStr(a.ptr + 3));
	else {
		PathAndExtension pe = parsePathAndExtension(allPaths, a);
		return RelPathAndExtension(RelPath(safeToUshort(nParents), pe.path), pe.extension);
	}
}

Path parseAbsoluteOrRelPath(ref AllPaths allPaths, Path cwd, in SafeCStr a) {
	PathAndExtension res = parseAbsoluteOrRelPathAndExtension(allPaths, cwd, a);
	if (res.extension != sym!"")
		todo!void("!");
	return res.path;
}

@trusted PathAndExtension parseAbsoluteOrRelPathAndExtension(ref AllPaths allPaths, Path cwd, in SafeCStr a) {
	if (looksLikeAbsolutePath(a))
		return parsePathAndExtension(allPaths, a);
	else {
		//TODO: handle parse error (return none if so)
		RelPathAndExtension rp = parseRelPathAndExtension(allPaths, a);
		Opt!Path resolved = resolvePath(allPaths, cwd, rp.relPath);
		return has(resolved)
			? PathAndExtension(force(resolved), rp.extension)
			: todo!PathAndExtension("relative path reaches past file system root");
	}
}

private @trusted bool looksLikeAbsolutePath(SafeCStr a) =>
	*a.ptr == '/' || (a.ptr[0] == 'C' && a.ptr[1] == ':' && isSlash(a.ptr[2]));

private immutable struct StrAndExtension {
	string withoutExtension;
	Sym extension; // Includes the '.' (if it exists)
}

private @system StrAndExtension removeExtension(ref AllSymbols allSymbols, CStr a) {
	CStr end = end(a);
	immutable(char)* ptr = end;
	while (ptr > a && *ptr != '.')
		ptr--;
	return ptr == a
		? StrAndExtension(a[0 .. (end - a)], sym!"")
		: StrAndExtension(a[0 .. (ptr - a)], symOfStr(allSymbols, ptr[0 .. (end - ptr)]));
}

Comparison comparePath(Path a, Path b) =>
	compareNat16(a.index, b.index);

immutable struct PathAndRange {
	Path path;
	RangeWithinFile range;
}

immutable struct PathsInfo {
	@disable this(ref const PathsInfo);
	Opt!Path cwd;
}

PathsInfo emptyPathsInfo() =>
	PathsInfo(none!Path);

Path commonAncestor(in AllPaths allPaths, in Path[] paths) =>
	reduce!Path(paths, (Path x, Path y) =>
		commonAncestorBinary(allPaths, x, y));
private Path commonAncestorBinary(in AllPaths allPaths, Path a, Path b) {
	size_t aParts = countPathParts(allPaths, a);
	size_t bParts = countPathParts(allPaths, b);
	return aParts > bParts
		? commonAncestorRecur(allPaths, removeLastNParts(allPaths, a, aParts - bParts), b)
		: commonAncestorRecur(allPaths, a, removeLastNParts(allPaths, b, bParts - aParts));
}
private Path commonAncestorRecur(in AllPaths allPaths, Path a, Path b) {
	if (a == b)
		return a;
	else {
		Opt!Path parA = parent(allPaths, a);
		Opt!Path parB = parent(allPaths, b);
		return commonAncestorRecur(allPaths, force(parA), force(parB));
	}
}

private:

void eachPartPreferRelative(
	in AllPaths allPaths,
	ref PathsInfo pathsInfo,
	Path a,
	in void delegate(Sym, bool) @safe @nogc pure nothrow cb,
) {
	size_t maxParts = () {
		if (has(pathsInfo.cwd)) {
			Path cwd = force(pathsInfo.cwd);
			size_t cwdParts = countPathParts(allPaths, cwd);
			size_t aParts = countPathParts(allPaths, a);
			return aParts > cwdParts && cwd == removeLastNParts(allPaths, a, aParts - cwdParts)
				? aParts - cwdParts
				: size_t.max;
		} else
			return size_t.max;
	}();
	eachPart(allPaths, a, maxParts, cb);
}

bool isSlash(char a) =>
	a == '/' || a == '\\';

public size_t TEST_countPathParts(in AllPaths allPaths, Path a) =>
	countPathParts(allPaths, a);

size_t countPathParts(in AllPaths allPaths, Path a) =>
	countPathPartsRecur(1, allPaths, a);
size_t countPathPartsRecur(size_t acc, in AllPaths allPaths, Path a) {
	Opt!Path par = parent(allPaths, a);
	return has(par) ? countPathPartsRecur(acc + 1, allPaths, force(par)) : acc;
}

Path removeLastNParts(in AllPaths allPaths, Path a, size_t nToRemove) {
	if (nToRemove == 0)
		return a;
	else {
		Opt!Path par = parent(allPaths, a);
		return removeLastNParts(allPaths, force(par), nToRemove - 1);
	}
}

void eachPart(
	in AllPaths allPaths,
	Path a,
	size_t maxParts,
	in void delegate(Sym, bool) @safe @nogc pure nothrow cb,
) {
	verify(maxParts > 0);
	Opt!Path par = parent(allPaths, a);
	if (has(par))
		eachPartRecur(allPaths, force(par), maxParts - 1, cb);
	cb(baseName(allPaths, a), true);
}

void eachPartRecur(
	in AllPaths allPaths,
	Path a,
	size_t maxParts,
	in void delegate(Sym, bool) @safe @nogc pure nothrow cb,
) {
	if (maxParts != 0) {
		Opt!Path par = parent(allPaths, a);
		if (has(par))
			eachPartRecur(allPaths, force(par), maxParts - 1, cb);
		cb(baseName(allPaths, a), false);
	}
}

public void writePathPlain(ref Writer writer, in AllPaths allPaths, Path p) {
	Opt!Path par = parent(allPaths, p);
	if (has(par)) {
		writePathPlain(writer, allPaths, force(par));
		writer ~= '/';
	}
	writeSym(writer, allPaths.allSymbols, baseName(allPaths, p));
}

public void writePathPlain(ref Writer writer, in AllPaths allPaths, PathAndExtension p) {
	writePathPlain(writer, allPaths, p.path);
	writer ~= '.';
	writeSym(writer, allPaths.allSymbols, p.extension);
}

public void writePath(ref Writer writer, in AllPaths allPaths, ref PathsInfo pathsInfo, Path a, Sym extension) {
	eachPartPreferRelative(allPaths, pathsInfo, a, (Sym part, bool isLast) {
		writeSym(writer, allPaths.allSymbols, part);
		if (!isLast)
			writer ~= '/';
	});
	writeSym(writer, allPaths.allSymbols, extension);
}

public void writeRelPath(ref Writer writer, in AllPaths allPaths, RelPath p, Sym extension) {
	foreach (ushort i; 0 .. p.nParents)
		writer ~= "../";
	writePathPlain(writer, allPaths, p.path);
	writeSym(writer, allPaths.allSymbols, extension);
}
