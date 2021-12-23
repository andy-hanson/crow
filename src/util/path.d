module util.path;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc, allocateT;
import util.col.mutArr : MutArr, mutArrAt, mutArrRange, mutArrSize, push;
import util.col.str : copyToSafeCStr, eachChar, end, SafeCStr, safeCStr, safeCStrIsEmpty, safeCStrSize, strOfSafeCStr;
import util.col.tempStr : TempStr;
import util.comparison : compareEnum, compareNat16, Comparison, compareOr;
import util.conv : safeToUshort;
import util.hash : Hasher, hashUshort;
import util.opt : has, force, forceOrTodo, none, Opt, some;
import util.ptr : Ptr;
import util.sourceRange : RangeWithinFile;
import util.sym : AllSymbols, eachCharInSym, Sym, symEq, symOfStr, symSize;
import util.util : todo, verify;

struct AllPaths {
	@safe @nogc pure nothrow:
	private:
	Ptr!Alloc alloc;
	Ptr!AllSymbols allSymbolsPtr;
	MutArr!(Opt!Path) pathToParent;
	MutArr!Sym pathToBaseName;
	MutArr!(MutArr!Path) pathToChildren;
	MutArr!Path rootChildren;

	// TODO:PRIVATE
	public ref const(AllSymbols) allSymbols() return scope const {
		return allSymbolsPtr.deref();
	}
	ref AllSymbols allSymbols() return scope {
		return allSymbolsPtr.deref();
	}
}

struct Path {
	private ushort index;
}

struct AbsolutePath {
	immutable SafeCStr root;
	immutable Path path;
	immutable SafeCStr extension;
}

immutable(Opt!Path) parent(ref const AllPaths allPaths, immutable Path a) {
	return mutArrAt(allPaths.pathToParent, a.index);
}

immutable(Sym) baseName(ref const AllPaths allPaths, immutable Path a) {
	return mutArrAt(allPaths.pathToBaseName, a.index);
}

immutable(Opt!Path) removeFirstPathComponentIf(
	ref AllPaths allPaths,
	immutable Path a,
	immutable Sym expected,
) {
	immutable Opt!Path parent = parent(allPaths, a);
	return has(parent) ? removeFirstPathComponentIfRecur(allPaths, a, force(parent), expected) : none!Path;
}
private immutable(Opt!Path) removeFirstPathComponentIfRecur(
	ref AllPaths allPaths,
	immutable Path a,
	immutable Path par,
	immutable Sym expected,
) {
	immutable Opt!Path grandParent = parent(allPaths, par);
	if (has(grandParent)) {
		immutable Opt!Path removed = removeFirstPathComponentIfRecur(allPaths, par, force(grandParent), expected);
		return has(removed)
			? some(childPath(allPaths, force(removed), baseName(allPaths, a)))
			: none!Path;
	} else
		return symEq(baseName(allPaths, par), expected)
			? some(rootPath(allPaths, baseName(allPaths, a)))
			: none!Path;
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

immutable(Path) rootPath(ref AllPaths allPaths, immutable Sym name) {
	return getOrAddChild(allPaths, allPaths.rootChildren, none!Path, name);
}

immutable(Path) childPath(ref AllPaths allPaths, immutable Path parent, immutable Sym name) {
	return getOrAddChild(allPaths, mutArrAt(allPaths.pathToChildren, parent.index), some(parent), name);
}

struct AbsOrRelPath {
	private:
	immutable Opt!ushort nParents_;
	immutable Path path_;
}

immutable(T) matchAbsOrRelPath(T)(
	ref immutable AbsOrRelPath a,
	scope immutable(T) delegate(immutable Path) @safe @nogc pure nothrow cbGlobal,
	scope immutable(T) delegate(immutable RelPath) @safe @nogc pure nothrow cbRel,
) {
	return has(a.nParents_)
		? cbRel(immutable RelPath(force(a.nParents_), a.path_))
		: cbGlobal(a.path_);
}

struct RelPath {
	private:
	immutable ushort nParents_;
	immutable Path path_;
}

immutable(ushort) nParents(ref immutable RelPath a) {
	return a.nParents_;
}
immutable(Path) path(ref immutable RelPath a) {
	return a.path_;
}

immutable(Opt!Path) resolvePath(
	ref AllPaths allPaths,
	immutable Opt!Path path,
	immutable RelPath relPath,
) {
	return relPath.nParents_ == 0
		? some(has(path)
			? addManyChildren(allPaths, force(path), relPath.path_)
			: relPath.path_)
		: has(path)
			? resolvePath(
				allPaths,
				parent(allPaths, force(path)),
				immutable RelPath(cast(ushort) (relPath.nParents_ - 1), relPath.path_))
			: none!Path;
}

immutable(Opt!Path) resolvePath(ref AllPaths allPaths, immutable Path path, immutable RelPath relPath) {
	return resolvePath(allPaths, some(path), relPath);
}

private immutable(Path) addManyChildren(ref AllPaths allPaths, immutable Path a, immutable Path b) {
	immutable Opt!Path bParent = parent(allPaths, b);
	return childPath(allPaths, has(bParent) ? addManyChildren(allPaths, a, force(bParent)) : a, baseName(allPaths, b));
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
	immutable SafeCStr root,
	immutable uint rootMultiple,
	immutable Path path,
	immutable SafeCStr extension,
) {
	size_t res = 0;
	if (!safeCStrIsEmpty(root))
		res += safeCStrSize(root) * rootMultiple + 1;
	walkPathBackwards(allPaths, path, (immutable Sym part, immutable bool isFirstPart) {
		// 1 for '/'
		res += (isFirstPart ? 0 : 1) + symSize(allPaths.allSymbols, part);
	});
	return res + safeCStrSize(extension) + 1;
}

alias TempStrForPath = TempStr!0x1000;

@trusted immutable(TempStrForPath) pathToTempStr(ref const AllPaths allPaths, immutable AbsolutePath path) {
	TempStrForPath res;
	immutable size_t length = pathToStrLength(allPaths, path.root, 1, path.path, path.extension);
	verify(length < res.capacity);
	pathToStrWorker2(allPaths, path.root, 1, path.path, path.extension, res.ptr, res.ptr + length);
	return res;
}

private @trusted immutable(string) pathToStrWorker(
	ref Alloc alloc,
	scope ref const AllPaths allPaths,
	scope immutable SafeCStr root,
	immutable uint rootMultiple,
	immutable Path path,
	scope immutable SafeCStr extension,
) {
	immutable size_t length = pathToStrLength(allPaths, root, rootMultiple, path, extension);
	char* begin = allocateT!char(alloc, length);
	pathToStrWorker2(allPaths, root, rootMultiple, path, extension, begin, begin + length);
	return cast(immutable) begin[0 .. length];
}

private @system void pathToStrWorker2(
	scope ref const AllPaths allPaths,
	scope immutable SafeCStr root,
	immutable uint rootMultiple,
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
	if (!safeCStrIsEmpty(root)) {
		cur--;
		*cur = '/';
		const char* rootEnd = cur;
		verify(rootEnd == begin + safeCStrSize(root) * rootMultiple);
		cur = begin;
		foreach (immutable size_t i; 0 .. rootMultiple)
			eachChar(root, (immutable char c) @trusted {
				*cur = c;
				cur++;
			});
		verify(cur == rootEnd);
	}
}

immutable(SafeCStr) absOrRelPathToStr(
	ref Alloc alloc,
	ref const AllPaths allPaths,
	scope ref immutable AbsOrRelPath a,
) {
	return matchAbsOrRelPath(
		a,
		(immutable Path global) =>
			pathToSafeCStr(alloc, allPaths, safeCStr!"", global, safeCStr!""),
		(immutable RelPath relPath) =>
			relPathToSafeCStr(alloc, allPaths, relPath));
}

private @trusted immutable(SafeCStr) relPathToSafeCStr(
	ref Alloc alloc,
	ref const AllPaths allPaths,
	ref immutable RelPath a,
) {
	return immutable SafeCStr(a.nParents_ == 0
		? pathToStrWorker(alloc, allPaths, safeCStr!"./", 1, a.path_, safeCStr!"").ptr
		: pathToStrWorker(alloc, allPaths, safeCStr!"../", a.nParents_, a.path_, safeCStr!"").ptr);
}

@trusted immutable(SafeCStr) pathToSafeCStr(
	ref Alloc alloc,
	scope ref const AllPaths allPaths,
	scope immutable SafeCStr root,
	immutable Path path,
	scope immutable SafeCStr extension,
) {
	return immutable SafeCStr(pathToStrWorker(alloc, allPaths, root, 1, path, extension).ptr);
}

immutable(SafeCStr) pathToSafeCStr(
	ref Alloc alloc,
	scope ref const AllPaths allPaths,
	scope ref immutable AbsolutePath path,
) {
	return pathToSafeCStr(alloc, allPaths, path.root, path.path, path.extension);
}

@trusted immutable(Path) parsePath(ref AllPaths allPaths, scope immutable SafeCStr str) {
	immutable PathAndExtension pe = parsePathAndExtension(allPaths, str);
	verify(safeCStrIsEmpty(pe.extension));
	return pe.path;
}

private struct PathAndExtension {
	immutable Path path;
	immutable SafeCStr extension;
}

@trusted private immutable(PathAndExtension) parsePathAndExtension(
	ref AllPaths allPaths,
	scope immutable SafeCStr str,
) {
	immutable(char)* ptr = str.ptr;
	if (*ptr == '/')
		// Ignore leading slash
		ptr++;
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
	while (*ptr == '/')
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
	while (*ptr != '\0' && *ptr != '/')
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
	immutable char* ptr = a.ptr;
	if (ptr[0] == '.') {
		if (ptr[1] == '/')
			return parseRelPathAndExtensionRecur(allPaths, nParents, immutable SafeCStr(ptr + 2));
		else if (ptr[1] == '.' && ptr[2] == '/')
			return parseRelPathAndExtensionRecur(allPaths, nParents + 1, immutable SafeCStr(ptr + 3));
	}
	immutable PathAndExtension pe = parsePathAndExtension(allPaths, a);
	return immutable RelPathAndExtension(immutable RelPath(0, pe.path), pe.extension);
}

immutable(Opt!AbsolutePath) parent(ref const AllPaths allPaths, ref immutable AbsolutePath a) {
	immutable Opt!Path pathParent = parent(allPaths, a.path);
	return has(pathParent)
		? some(immutable AbsolutePath(a.root, force(pathParent), safeCStr!""))
		: none!AbsolutePath;
}

immutable(Sym) baseName(ref const AllPaths allPaths, ref immutable AbsolutePath a) {
	return baseName(allPaths, a.path);
}

@trusted immutable(AbsolutePath) parseAbsoluteOrRelPath(
	ref Alloc alloc,
	ref AllPaths allPaths,
	immutable SafeCStr cwd,
	immutable SafeCStr a,
) {
	switch (*a.ptr) {
		case '.':
			//TODO: handle parse error (return none if so)
			immutable RelPathAndExtension rp = parseRelPathAndExtension(allPaths, a);
			return immutable AbsolutePath(
				copyToSafeCStr(alloc, dropParents(allPaths, strOfSafeCStr(cwd), rp.relPath.nParents_)),
				rp.relPath.path_,
				rp.extension);
		case '/':
			return absolutePath(safeCStr!"", parsePathAndExtension(allPaths, a));
		case '\\':
			return todo!(immutable AbsolutePath)("unc path?");
		default:
			verify(*a.ptr != '\0');
			// Treat a plain string without '/' in front as a relative path
			return a.ptr[1] == ':'
				? todo!(immutable AbsolutePath)("C:/ ?")
				: absolutePath(cwd, parsePathAndExtension(allPaths, a));
	}
}
private immutable(AbsolutePath) absolutePath(immutable SafeCStr root, immutable PathAndExtension pe) {
	return immutable AbsolutePath(root, pe.path, pe.extension);
}

private immutable(string) dropParents(
	ref const AllPaths allPaths,
	immutable string path,
	immutable ushort nParents,
) {
	if (nParents == 0)
		return path;
	else {
		immutable Opt!string p = pathParent(path);
		return dropParents(allPaths, forceOrTodo(p), cast(ushort) (nParents - 1));
	}
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

immutable(AbsolutePath) childPath(
	ref AllPaths allPaths,
	ref immutable AbsolutePath parent,
	immutable Sym name,
) {
	return immutable AbsolutePath(parent.root, childPath(allPaths, parent.path, name), parent.extension);
}

private immutable(Opt!size_t) pathSlashIndex(immutable string a) {
	for (size_t i = a.length - 1; i > 0; i--)
		if (a[i] == '/')
			return some(i);
	return none!size_t;
}

private struct ParentAndBaseName {
	immutable string parent;
	immutable string baseName;
}

immutable(Opt!string) pathParent(return scope immutable string s) {
	immutable Opt!ParentAndBaseName o = pathParentAndBaseName(s);
	return has(o) ? some(force(o).parent) : none!string;
}

private immutable(Opt!ParentAndBaseName) pathParentAndBaseName(return scope immutable string s) {
	immutable Opt!size_t index = pathSlashIndex(s);
	return has(index)
		? some(immutable ParentAndBaseName(s[0 .. force(index)], s[force(index) + 1 .. $]))
		: none!ParentAndBaseName;
}

private immutable(bool) pathEqual(immutable Path a, immutable Path b) {
	return a.index == b.index;
}

immutable(Comparison) comparePath(immutable Path a, immutable Path b) {
	return compareNat16(a.index, b.index);
}

enum StorageKind : ushort {
	global,
	local,
}

struct PathAndStorageKind {
	immutable Path path;
	immutable StorageKind storageKind;
}

immutable(bool) pathAndStorageKindEqual(immutable PathAndStorageKind a, immutable PathAndStorageKind b) {
	return pathEqual(a.path, b.path) && a.storageKind == b.storageKind;
}

immutable(Comparison) comparePathAndStorageKind(immutable PathAndStorageKind a, immutable PathAndStorageKind b) {
	return compareOr(
		compareEnum(a.storageKind, b.storageKind),
		() => comparePath(a.path, b.path));
}

void hashPathAndStorageKind(ref Hasher hasher, immutable PathAndStorageKind a) {
	hashUshort(hasher, a.path.index);
	hashUshort(hasher, a.storageKind);
}

struct PathAndRange {
	immutable PathAndStorageKind path;
	immutable RangeWithinFile range;
}
