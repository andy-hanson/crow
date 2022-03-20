module util.path;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc, allocateT;
import util.col.mutArr : MutArr, mutArrAt, mutArrRange, mutArrSize, push;
import util.col.str : eachChar, end, SafeCStr, safeCStr, safeCStrIsEmpty, safeCStrSize;
import util.col.tempStr : initializeTempStr, TempStr;
import util.comparison : compareNat16, Comparison;
import util.conv : safeToUshort;
import util.hash : Hasher, hashUshort;
import util.opt : has, force, none, Opt, some;
import util.ptr : Ptr;
import util.sourceRange : RangeWithinFile;
import util.sym : AllSymbols, eachCharInSym, emptySym, Sym, symEq, symOfStr, symSize, writeSym;
import util.util : todo, verify;
import util.writer : writeChar, Writer, writeSafeCStr, writeStatic;

struct AllPaths {
	@safe @nogc pure nothrow:
	private:
	Ptr!Alloc alloc;
	Ptr!AllSymbols allSymbolsPtr;
	MutArr!(Opt!Path) pathToParent;
	MutArr!Sym pathToBaseName;
	MutArr!(MutArr!Path) pathToChildren;
	MutArr!Path rootChildren;

	ref const(AllSymbols) allSymbols() return scope const {
		return allSymbolsPtr.deref();
	}
	ref AllSymbols allSymbols() return scope {
		return allSymbolsPtr.deref();
	}
}

struct Path {
	private ushort index;
}

immutable(Opt!Path) parent(ref const AllPaths allPaths, immutable Path a) {
	return mutArrAt(allPaths.pathToParent, a.index);
}

immutable(Sym) baseName(ref const AllPaths allPaths, immutable Path a) {
	return mutArrAt(allPaths.pathToBaseName, a.index);
}

private immutable(Path) getOrAddChild(
	ref AllPaths allPaths,
	ref MutArr!Path children,
	immutable Opt!Path parent,
	immutable Sym name,
) {
	foreach (immutable Path child; mutArrRange(children))
		if (symEq(baseName(allPaths, child), name))
			return child;

	immutable Path res = immutable Path(safeToUshort(mutArrSize(allPaths.pathToParent)));
	push(allPaths.alloc.deref(), children, res);
	push(allPaths.alloc.deref(), allPaths.pathToParent, parent);
	push(allPaths.alloc.deref(), allPaths.pathToBaseName, name);
	push(allPaths.alloc.deref(), allPaths.pathToChildren, MutArr!Path());
	return res;
}

immutable(Path) emptyRootPath(ref AllPaths allPaths) {
	return rootPath(allPaths, emptySym);
}

immutable(Path) rootPath(ref AllPaths allPaths, immutable Sym name) {
	return getOrAddChild(allPaths, allPaths.rootChildren, none!Path, name);
}

immutable(Path) childPath(ref AllPaths allPaths, immutable Path parent, immutable Sym name) {
	return getOrAddChild(allPaths, mutArrAt(allPaths.pathToChildren, parent.index), some(parent), name);
}

struct PathOrRelPath {
	private:
	immutable Opt!ushort nParents_;
	immutable Path path_;
}

immutable(T) matchPathOrRelPath(T)(
	ref immutable PathOrRelPath a,
	scope immutable(T) delegate(immutable Path) @safe @nogc pure nothrow cbGlobal,
	scope immutable(T) delegate(immutable RelPath) @safe @nogc pure nothrow cbRel,
) {
	return has(a.nParents_)
		? cbRel(immutable RelPath(force(a.nParents_), a.path_))
		: cbGlobal(a.path_);
}

struct RelPath {
	private immutable ushort nParents;
	immutable Path path;
}

immutable(Opt!Path) resolvePath(
	ref AllPaths allPaths,
	immutable Opt!Path path,
	immutable RelPath relPath,
) {
	return relPath.nParents == 0
		? some(has(path)
			? concatPaths(allPaths, force(path), relPath.path)
			: relPath.path)
		: has(path)
			? resolvePath(
				allPaths,
				parent(allPaths, force(path)),
				immutable RelPath(cast(ushort) (relPath.nParents - 1), relPath.path))
			: none!Path;
}

immutable(Opt!Path) resolvePath(ref AllPaths allPaths, immutable Path path, immutable RelPath relPath) {
	return resolvePath(allPaths, some(path), relPath);
}

immutable(Path) concatPaths(ref AllPaths allPaths, immutable Path a, immutable Path b) {
	immutable Opt!Path bParent = parent(allPaths, b);
	return childPath(allPaths, has(bParent) ? concatPaths(allPaths, a, force(bParent)) : a, baseName(allPaths, b));
}

private void walkPathBackwards(
	ref const AllPaths allPaths,
	immutable Path a,
	scope void delegate(immutable Sym, immutable bool isFirstPart) @safe @nogc pure nothrow cb,
) {
	immutable Opt!Path par = parent(allPaths, a);
	cb(baseName(allPaths, a), !has(par));
	if (has(par))
		walkPathBackwards(allPaths, force(par), cb);
}

private size_t pathToStrLength(
	ref const AllPaths allPaths,
	immutable string prefix,
	immutable size_t prefixMultiple,
	immutable Path path,
	scope immutable SafeCStr extension,
) {
	size_t res = 0;
	if (prefixMultiple != 0)
		res += prefix.length * prefixMultiple + 1;
	walkPathBackwards(allPaths, path, (immutable Sym part, immutable bool isFirstPart) {
		// 1 for '/'
		res += (isFirstPart ? 0 : 1) + symSize(allPaths.allSymbols, part);
	});
	return res + safeCStrSize(extension) + 1;
}

alias TempStrForPath = TempStr!0x1000;

immutable(TempStrForPath) pathToTempStr(ref const AllPaths allPaths, immutable PathAndExtension path) {
	return pathToTempStr(allPaths, path.path, path.extension);
}

@trusted immutable(TempStrForPath) pathToTempStr(
	ref const AllPaths allPaths,
	immutable Path path,
	scope immutable SafeCStr extension,
) {
	TempStrForPath res = void;
	initializeTempStr(res);
	immutable size_t length = pathToStrLength(allPaths, "", 0, path, extension);
	verify(length < res.capacity);
	pathToStrWorker2(allPaths, "", 0, path, extension, res.ptr, res.ptr + length);
	return res;
}

private immutable(string) pathToStrWorker(
	ref Alloc alloc,
	scope ref const AllPaths allPaths,
	immutable Path path,
	scope immutable SafeCStr extension,
) {
	return pathToStrWorker(alloc, allPaths, "", 0, path, extension);
}

private @trusted immutable(string) pathToStrWorker(
	ref Alloc alloc,
	scope ref const AllPaths allPaths,
	scope immutable string prefix,
	immutable size_t prefixCount,
	immutable Path path,
	scope immutable SafeCStr extension,
) {
	immutable size_t length = pathToStrLength(allPaths, prefix, prefixCount, path, extension);
	char* begin = allocateT!char(alloc, length);
	pathToStrWorker2(allPaths, prefix, prefixCount, path, extension, begin, begin + length);
	return cast(immutable) begin[0 .. length];
}

private @system void pathToStrWorker2(
	scope ref const AllPaths allPaths,
	scope immutable string prefix,
	immutable size_t prefixMultiple,
	immutable Path path,
	scope immutable SafeCStr extension,
	scope char* begin,
	scope char* end,
) {
	char* cur = end - 1;
	*cur = '\0';
	cur -= safeCStrSize(extension);
	eachChar(extension, (immutable char c) @trusted {
		*cur = c;
		cur++;
	});
	cur -= safeCStrSize(extension);
	verify(cur == end - 1 - safeCStrSize(extension));
	walkPathBackwards(allPaths, path, (immutable Sym part, immutable bool isFirstPart) @trusted {
		cur -= symSize(allPaths.allSymbols, part);
		char* j = cur;
		eachCharInSym(allPaths.allSymbols, part, (immutable char c) @trusted {
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
		foreach (immutable size_t i; 0 .. prefixMultiple)
			foreach (immutable char c; prefix) {
				*cur = c;
				cur++;
			}
		verify(cur == rootEnd);
	}
}

immutable(SafeCStr) pathOrRelPathToStr(
	ref Alloc alloc,
	ref const AllPaths allPaths,
	scope ref immutable PathOrRelPath a,
) {
	return matchPathOrRelPath(
		a,
		(immutable Path global) =>
			pathToSafeCStr(alloc, allPaths, global, safeCStr!""),
		(immutable RelPath relPath) =>
			relPathToSafeCStr(alloc, allPaths, relPath));
}

private @trusted immutable(SafeCStr) relPathToSafeCStr(
	ref Alloc alloc,
	ref const AllPaths allPaths,
	immutable RelPath a,
) {
	return immutable SafeCStr(a.nParents == 0
		? pathToStrWorker(alloc, allPaths, "./", 1, a.path, safeCStr!"").ptr
		: pathToStrWorker(alloc, allPaths, "../", a.nParents, a.path, safeCStr!"").ptr);
}

immutable(SafeCStr) pathToSafeCStr(
	ref Alloc alloc,
	scope ref const AllPaths allPaths,
	immutable PathAndExtension path,
) {
	return pathToSafeCStr(alloc, allPaths, path.path, path.extension);
}

@trusted immutable(SafeCStr) pathToSafeCStr(
	ref Alloc alloc,
	scope ref const AllPaths allPaths,
	immutable Path path,
	scope immutable SafeCStr extension = safeCStr!"",
) {
	return immutable SafeCStr(pathToStrWorker(alloc, allPaths, path, extension).ptr);
}

@trusted immutable(Path) parsePath(ref AllPaths allPaths, scope immutable SafeCStr str) {
	immutable PathAndExtension pe = parsePathAndExtension(allPaths, str);
	verify(safeCStrIsEmpty(pe.extension));
	return pe.path;
}

struct PathAndExtension {
	immutable Path path;
	immutable SafeCStr extension;
}

@trusted private immutable(PathAndExtension) parsePathAndExtension(
	ref AllPaths allPaths,
	scope immutable SafeCStr str,
) {
	immutable(char)* ptr = str.ptr;
	immutable string part = parsePathPart(allPaths, ptr);
	if (*ptr == '\0') {
		immutable StrAndExtension se = removeExtension(part.ptr);
		return immutable PathAndExtension(
			rootPath(allPaths, symOfStr(allPaths.allSymbols, se.withoutExtension)),
			se.extension);
	} else
		return parsePathAndExtensionRecur(allPaths, ptr, rootPath(allPaths, symOfStr(allPaths.allSymbols, part)));
}
@system private immutable(PathAndExtension) parsePathAndExtensionRecur(
	ref AllPaths allPaths,
	immutable(char)* ptr,
	immutable Path path,
) {
	while (isSlash(*ptr))
		ptr++;

	if (*ptr == '\0')
		return immutable PathAndExtension(path, safeCStr!"");
	else {
		immutable string part = parsePathPart(allPaths, ptr);
		if (*ptr == '\0') {
			immutable StrAndExtension se = removeExtension(part.ptr);
			return immutable PathAndExtension(
				childPath(allPaths, path, symOfStr(allPaths.allSymbols, se.withoutExtension)),
				se.extension);
		} else
			return parsePathAndExtensionRecur(
				allPaths,
				ptr,
				childPath(allPaths, path, symOfStr(allPaths.allSymbols, part)));
	}
}
private @system immutable(string) parsePathPart(ref AllPaths allPaths, ref immutable(char)* ptr) {
	immutable char* begin = ptr;
	while (*ptr != '\0' && !isSlash(*ptr))
		ptr++;
	return begin[0 .. (ptr - begin)];
}

private struct RelPathAndExtension {
	immutable RelPath relPath;
	immutable SafeCStr extension;
}

private @trusted immutable(RelPathAndExtension) parseRelPathAndExtension(ref AllPaths allPaths, immutable SafeCStr a) {
	return parseRelPathAndExtensionRecur(allPaths, 0, a);
}
private @system immutable(RelPathAndExtension) parseRelPathAndExtensionRecur(
	ref AllPaths allPaths,
	immutable size_t nParents,
	immutable SafeCStr a,
) {
	if (a.ptr[0] == '.' && isSlash(a.ptr[1]))
		return parseRelPathAndExtensionRecur(allPaths, nParents, immutable SafeCStr(a.ptr + 2));
	else if (a.ptr[0] == '.' && a.ptr[1] == '.' && isSlash(a.ptr[2]))
		return parseRelPathAndExtensionRecur(allPaths, nParents + 1, immutable SafeCStr(a.ptr + 3));
	else {
		immutable PathAndExtension pe = parsePathAndExtension(allPaths, a);
		return immutable RelPathAndExtension(immutable RelPath(safeToUshort(nParents), pe.path), pe.extension);
	}
}

@trusted immutable(PathAndExtension) parseAbsoluteOrRelPathAndExtension(
	ref AllPaths allPaths,
	immutable Path cwd,
	scope immutable SafeCStr a,
) {
	if (looksLikeAbsolutePath(a))
		return parsePathAndExtension(allPaths, a);
	else {
		//TODO: handle parse error (return none if so)
		immutable RelPathAndExtension rp = parseRelPathAndExtension(allPaths, a);
		immutable Opt!Path resolved = resolvePath(allPaths, cwd, rp.relPath);
		return has(resolved)
			? immutable PathAndExtension(force(resolved), rp.extension)
			: todo!(immutable PathAndExtension)("relative path reaches past file system root");
	}
}

private @trusted immutable(bool) looksLikeAbsolutePath(immutable SafeCStr a) {
	return *a.ptr == '/' || (a.ptr[0] == 'C' && a.ptr[1] == ':' && isSlash(a.ptr[2]));
}

private struct StrAndExtension {
	immutable string withoutExtension;
	immutable SafeCStr extension; // Includes the '.' (if it exists)
}

private @system immutable(StrAndExtension) removeExtension(immutable char* a) {
	immutable char* end = end(a);
	immutable(char)* ptr = end;
	while (ptr > a && *ptr != '.')
		ptr--;
	return ptr == a
		? immutable StrAndExtension(a[0 .. (end - a)], safeCStr!"")
		: immutable StrAndExtension(a[0 .. (ptr - a)], immutable SafeCStr(ptr));
}

immutable(bool) pathEqual(immutable Path a, immutable Path b) {
	return a.index == b.index;
}

immutable(Comparison) comparePath(immutable Path a, immutable Path b) {
	return compareNat16(a.index, b.index);
}

void hashPath(ref Hasher hasher, immutable Path a) {
	hashUshort(hasher, a.index);
}

struct PathAndRange {
	immutable Path path;
	immutable RangeWithinFile range;
}

struct PathsInfo {
	@disable this(ref const PathsInfo);
	immutable Opt!Path cwd;
}

immutable(PathsInfo) emptyPathsInfo() {
	return immutable PathsInfo(none!Path);
}

private:

void eachPartPreferRelative(
	ref const AllPaths allPaths,
	ref immutable PathsInfo pathsInfo,
	immutable Path a,
	scope void delegate(immutable Sym, immutable bool) @safe @nogc pure nothrow cb,
) {
	immutable size_t maxParts = () {
		if (has(pathsInfo.cwd)) {
			immutable Path cwd = force(pathsInfo.cwd);
			immutable size_t cwdParts = countPathParts(allPaths, cwd);
			immutable size_t aParts = countPathParts(allPaths, a);
			return aParts > cwdParts && pathEqual(cwd, removeLastNParts(allPaths, a, aParts - cwdParts))
				? aParts - cwdParts
				: size_t.max;
		} else
			return size_t.max;
	}();
	eachPart(allPaths, a, maxParts, cb);
}

immutable(bool) isSlash(immutable char a) {
	return a == '/' || a == '\\';
}

public immutable(size_t) TEST_countPathParts(ref const AllPaths allPaths, immutable Path a) {
	return countPathParts(allPaths, a);
}

immutable(size_t) countPathParts(ref const AllPaths allPaths, immutable Path a) {
	return countPathPartsRecur(1, allPaths, a);
}
immutable(size_t) countPathPartsRecur(immutable size_t acc, ref const AllPaths allPaths, immutable Path a) {
	immutable Opt!Path par = parent(allPaths, a);
	return has(par) ? countPathPartsRecur(acc + 1, allPaths, force(par)) : acc;
}

immutable(Path) removeLastNParts(ref const AllPaths allPaths, immutable Path a, immutable size_t nToRemove) {
	if (nToRemove == 0)
		return a;
	else {
		immutable Opt!Path par = parent(allPaths, a);
		return removeLastNParts(allPaths, force(par), nToRemove - 1);
	}
}

void eachPart(
	ref const AllPaths allPaths,
	immutable Path a,
	immutable size_t maxParts,
	scope void delegate(immutable Sym, immutable bool) @safe @nogc pure nothrow cb,
) {
	verify(maxParts > 0);
	immutable Opt!Path par = parent(allPaths, a);
	if (has(par))
		eachPartRecur(allPaths, force(par), maxParts - 1, cb);
	cb(baseName(allPaths, a), true);
}

void eachPartRecur(
	ref const AllPaths allPaths,
	immutable Path a,
	immutable size_t maxParts,
	scope void delegate(immutable Sym, immutable bool) @safe @nogc pure nothrow cb,
) {
	if (maxParts != 0) {
		immutable Opt!Path par = parent(allPaths, a);
		if (has(par))
			eachPartRecur(allPaths, force(par), maxParts - 1, cb);
		cb(baseName(allPaths, a), false);
	}
}

void writePathPlain(
	ref Writer writer,
	ref const AllPaths allPaths,
	immutable Path p,
) {
	immutable Opt!Path par = parent(allPaths, p);
	if (has(par)) {
		writePathPlain(writer, allPaths, force(par));
		writeChar(writer, '/');
	}
	writeSym(writer, allPaths.allSymbols, baseName(allPaths, p));
}

public void writePath(
	ref Writer writer,
	ref const AllPaths allPaths,
	ref immutable PathsInfo pathsInfo,
	immutable Path a,
	immutable SafeCStr extension,
) {
	eachPartPreferRelative(allPaths, pathsInfo, a, (immutable Sym part, immutable bool isLast) {
		writeSym(writer, allPaths.allSymbols, part);
		if (!isLast)
			writeChar(writer, '/');
	});
	writeSafeCStr(writer, extension);
}

public void writeRelPath(
	ref Writer writer,
	ref const AllPaths allPaths,
	immutable RelPath p,
	immutable SafeCStr extension,
) {
	foreach (immutable ushort i; 0 .. p.nParents)
		writeStatic(writer, "../");
	writePathPlain(writer, allPaths, p.path);
	writeSafeCStr(writer, extension);
}
