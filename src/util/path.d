module util.path;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc, allocateBytes;
import util.collection.mutArr : MutArr, mutArrAt, mutArrRange, mutArrSize, push;
import util.collection.str : copyToSafeCStr, SafeCStr, safeCStr, strOfSafeCStr;
import util.comparison : compareEnum, compareNat16, Comparison, compareOr;
import util.conv : safeToUshort;
import util.hash : Hasher, hashUshort;
import util.opt : has, force, forceOrTodo, none, Opt, some;
import util.ptr : Ptr;
import util.sourceRange : RangeWithinFile;
import util.sym : AllSymbols, eachCharInSym, Sym, symEq, symOfStr, symSize;
import util.util : todo, verify;

struct AllPaths {
	private:
	Ptr!Alloc alloc;
	Ptr!AllSymbols allSymbols;
	MutArr!(Opt!Path) pathToParent;
	MutArr!Sym pathToBaseName;
	MutArr!(MutArr!Path) pathToChildren;
	MutArr!Path rootChildren;
}

struct Path {
	private ushort index;
}

struct AbsolutePath {
	immutable SafeCStr root;
	immutable Path path;
	immutable string extension;
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

public void eachPathPart(
	ref const AllPaths allPaths,
	immutable Path a,
	scope void delegate(immutable Sym) @safe @nogc pure nothrow cb,
) {
	immutable Opt!Path par = parent(allPaths, a);
	if (has(par))
		eachPathPart(allPaths, force(par), cb);
	cb(baseName(allPaths, a));
}

private void walkPathBackwards(
	ref const AllPaths allPaths,
	immutable Path a,
	scope void delegate(immutable Sym) @safe @nogc pure nothrow cb,
) {
	cb(baseName(allPaths, a));
	immutable Opt!Path par = parent(allPaths, a);
	if (has(par))
		walkPathBackwards(allPaths, force(par), cb);
}

private size_t pathToStrSize(ref const AllPaths allPaths, immutable Path path) {
	size_t sz = 0;
	walkPathBackwards(allPaths, path, (immutable Sym part) {
		// 1 for '/'
		sz += 1 + symSize(part);
	});
	return sz;
}

private @trusted immutable(string) pathToStrWorker(
	ref Alloc alloc,
	ref const AllPaths allPaths,
	immutable SafeCStr rootCStr,
	immutable uint rootMultiple,
	immutable Path path,
	immutable string extension,
	immutable bool nulTerminated,
) {
	immutable string root = strOfSafeCStr(rootCStr);
	immutable size_t sz = root.length * rootMultiple +
		pathToStrSize(allPaths, path) +
		extension.length +
		(nulTerminated ? 1 : 0);
	char* begin = cast(char*) allocateBytes(alloc, char.sizeof * sz);
	char* cur = begin + sz;
	if (nulTerminated) {
		cur--;
		*cur = '\0';
	}
	foreach_reverse (immutable char c; extension) {
		cur--;
		*cur = c;
	}
	verify(cur == begin + root.length * rootMultiple + pathToStrSize(allPaths, path));
	walkPathBackwards(allPaths, path, (immutable Sym part) @trusted {
		cur -= symSize(part);
		char* j = cur;
		eachCharInSym(part, (immutable char c) @trusted {
			*j = c;
			j++;
		});
		verify(j == cur + symSize(part));
		cur--;
		*cur = '/';
	});
	verify(cur == begin + root.length * rootMultiple);
	foreach (immutable size_t i; 0 .. rootMultiple) {
		foreach_reverse (immutable char c; root) {
			cur--;
			*cur = c;
		}
	}
	verify(cur == begin);
	return cast(immutable) begin[0 .. sz];
}

immutable(string) absOrRelPathToStr(
	ref Alloc alloc,
	ref const AllPaths allPaths,
	ref immutable AbsOrRelPath a,
) {
	return matchAbsOrRelPath(
		a,
		(immutable Path global) =>
			pathToStr(alloc, allPaths, safeCStr!"", global, ""),
		(immutable RelPath relPath) =>
			relPathToStr(alloc, allPaths, relPath));
}

private immutable(string) relPathToStr(
	ref Alloc alloc,
	ref const AllPaths allPaths,
	ref immutable RelPath a,
) {
	return a.nParents_ == 0
		? pathToStrWorker(alloc, allPaths, safeCStr!"./", 1, a.path_, "", false)
		: pathToStrWorker(alloc, allPaths, safeCStr!"../", a.nParents_, a.path_, "", false);
}

immutable(string) pathToStr(
	ref Alloc alloc,
	ref const AllPaths allPaths,
	immutable SafeCStr root,
	immutable Path path,
	immutable string extension,
) {
	return pathToStrWorker(alloc, allPaths, root, 1, path, extension, false);
}

@trusted immutable(SafeCStr) pathToSafeCStr(
	ref Alloc alloc,
	ref const AllPaths allPaths,
	immutable SafeCStr root,
	immutable Path path,
	immutable string extension,
) {
	return immutable SafeCStr(pathToStrWorker(alloc, allPaths, root, 1, path, extension, true).ptr);
}

immutable(string) pathToStr(
	ref Alloc alloc,
	ref const AllPaths allPaths,
	ref immutable AbsolutePath path,
) {
	return pathToStr(alloc, allPaths, path.root, path.path, path.extension);
}

immutable(SafeCStr) pathToSafeCStr(
	ref Alloc alloc,
	ref const AllPaths allPaths,
	ref immutable AbsolutePath path,
) {
	return pathToSafeCStr(alloc, allPaths, path.root, path.path, path.extension);
}

immutable(Path) parsePath(ref AllPaths allPaths, scope ref immutable string str) {
	immutable size_t len = str.length;
	size_t i = 0;
	if (i < len && str[i] == '/')
		// Ignore leading slash
		i++;

	immutable Path path = {
		immutable size_t begin = i;
		while (i < len && str[i] != '/')
			i++;
		verify(i != begin);
		return rootPath(allPaths, symOfStr(allPaths.allSymbols.deref(), str[begin .. i]));
	}();

	immutable(Path) recur(size_t i, immutable Path path) {
		if (i == len)
			return path;
		if (str[i] == '/')
			i++;
		if (i == len)
			return path;
		immutable size_t begin = i;
		while (i < len && str[i] != '/')
			i++;
		return recur(i, childPath(allPaths, path, symOfStr(allPaths.allSymbols.deref(), str[begin .. i])));
	}
	return recur(i, path);
}

private immutable(RelPath) parseRelPath(ref AllPaths allPaths, immutable string a) {
	if (a[0] == '.')
		if (a.length > 1 && a[1] == '/')
			return parseRelPath(allPaths, a[2 .. $]);
		else if (a.length > 2 && a[1] == '.' && a[2] == '/') {
			immutable RelPath r = parseRelPath(allPaths, a[3 .. $]);
			return immutable RelPath(safeToUshort(r.nParents_ + 1), r.path_);
		} else
			// Path component happens to start with '.' but is not '.' or '..'
			return immutable RelPath(0, parsePath(allPaths, a));
	else
		return immutable RelPath(0, parsePath(allPaths, a));
}

immutable(Opt!AbsolutePath) parent(ref const AllPaths allPaths, ref immutable AbsolutePath a) {
	immutable Opt!Path pathParent = parent(allPaths, a.path);
	return has(pathParent)
		? some(immutable AbsolutePath(a.root, force(pathParent), ""))
		: none!AbsolutePath;
}

immutable(Sym) baseName(ref const AllPaths allPaths, ref immutable AbsolutePath a) {
	return baseName(allPaths, a.path);
}

immutable(AbsolutePath) parseAbsoluteOrRelPath(
	ref Alloc alloc,
	ref AllPaths allPaths,
	immutable SafeCStr cwd,
	immutable SafeCStr s,
) {
	immutable StrAndExtension se = removeExtension(strOfSafeCStr(s));
	immutable RootAndPath rp = parseAbsoluteOrRelPathWithoutExtension(alloc, allPaths, cwd, se.withoutExtension);
	return immutable AbsolutePath(rp.root, rp.path, se.extension);
}

private immutable(RootAndPath) parseAbsoluteOrRelPathWithoutExtension(
	ref Alloc alloc,
	ref AllPaths allPaths,
	immutable SafeCStr cwd,
	immutable string a,
) {
	switch (a[0]) {
		case '.':
			//TODO: handle parse error (return none if so)
			immutable RelPath rp = parseRelPath(allPaths, a);
			return immutable RootAndPath(
				copyToSafeCStr(alloc, dropParents(allPaths, strOfSafeCStr(cwd), rp.nParents_)),
				rp.path_);
		case '/':
			immutable Path path = parsePath(allPaths, a);
			return immutable RootAndPath(safeCStr!"", path);
		case '\\':
			return todo!(immutable RootAndPath)("unc path?");
		default:
			// Treat a plain string without '/' in front as a relative path
			return a.length >= 2 && a[1] == ':'
				? todo!(immutable RootAndPath)("C:/ ?")
				: immutable RootAndPath(cwd, parsePath(allPaths, a));
	}
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
	immutable string extension; // Includes the '.' (if it exists)
}

private immutable(StrAndExtension) removeExtension(immutable string a) {
	// Deliberately not allowing i == 0
	for (size_t i = a.length - 1; i > 0; i--)
		if (a[i] == '.')
			return immutable StrAndExtension(a[0 .. i], a[i .. $]);
	return immutable StrAndExtension(a, "");
}

// AbsolutePath with no extension
private struct RootAndPath {
	immutable SafeCStr root;
	immutable Path path;
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

immutable(uint) nPathComponents(ref const AllPaths allPaths, immutable Path a) {
	immutable Opt!Path par = parent(allPaths, a);
	return 1 + (has(par) ? nPathComponents(allPaths, force(par)) : 0);
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
