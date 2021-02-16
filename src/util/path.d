module util.path;

@safe @nogc pure nothrow:

import util.alloc.alloc : allocateBytes;
import util.collection.arr : at, first, size;
import util.collection.mutArr : MutArr, mutArrAt, mutArrRange, mutArrSize, push;
import util.collection.str : asCStr, copyStr, CStr, NulTerminatedStr, strEq;
import util.comparison : compareEnum, compareNat16, Comparison, compareOr;
import util.opt : has, force, forceOrTodo, mapOption, none, Opt, some;
import util.ptr : Ptr;
import util.sourceRange : RangeWithinFile;
import util.types : safeSizeTToU16;
import util.util : todo, verify;

struct AllPaths(Alloc) {
	private:
	Ptr!Alloc alloc;
	MutArr!(Opt!Path) pathToParent;
	MutArr!string pathToBaseName;
	MutArr!(MutArr!Path) pathToChildren;
	MutArr!Path rootChildren;
}

struct Path {
	private ushort index;
}

struct AbsolutePath {
	immutable string root;
	immutable Path path;
	immutable string extension;
}

immutable(Opt!Path) parent(Alloc)(ref const AllPaths!Alloc allPaths, immutable Path a) {
	return mutArrAt(allPaths.pathToParent, a.index);
}

immutable(string) baseName(Alloc)(ref const AllPaths!Alloc allPaths, immutable Path a) {
	return mutArrAt(allPaths.pathToBaseName, a.index);
}

immutable(Opt!Path) removeFirstPathComponentIf(Alloc)(
	ref AllPaths!Alloc allPaths,
	immutable Path a,
	immutable string expected,
) {
	immutable Opt!Path parent = parent(allPaths, a);
	return has(parent) ? removeFirstPathComponentIfRecur(allPaths, a, force(parent), expected) : none!Path;
}
private immutable(Opt!Path) removeFirstPathComponentIfRecur(Alloc)(
	ref AllPaths!Alloc allPaths,
	immutable Path a,
	immutable Path par,
	immutable string expected,
) {
	immutable Opt!Path grandParent = parent(allPaths, par);
	if (has(grandParent)) {
		immutable Opt!Path removed = removeFirstPathComponentIfRecur(allPaths, par, force(grandParent), expected);
		return has(removed)
			? some(childPath(allPaths, force(removed), baseName(allPaths, a)))
			: none!Path;
	} else
		return strEq(baseName(allPaths, par), expected)
			? some(rootPath(allPaths, baseName(allPaths, a)))
			: none!Path;
}

private immutable(Path) getOrAddChild(Alloc)(
	ref AllPaths!Alloc allPaths,
	ref MutArr!Path children,
	immutable Opt!Path parent,
	scope immutable string name,
) {
	foreach (immutable Path child; mutArrRange(children))
		if (strEq(baseName(allPaths, child), name))
			return child;

	immutable Path res = immutable Path(safeSizeTToU16(mutArrSize(allPaths.pathToParent)));
	push(allPaths.alloc.deref(), children, res);
	push(allPaths.alloc.deref(), allPaths.pathToParent, parent);
	push(allPaths.alloc.deref(), allPaths.pathToBaseName, copyStr(allPaths.alloc.deref(), name));
	push(allPaths.alloc.deref(), allPaths.pathToChildren, MutArr!Path());
	return res;
}

immutable(Path) rootPath(Alloc)(ref AllPaths!Alloc allPaths, scope immutable string name) {
	return getOrAddChild(allPaths, allPaths.rootChildren, none!Path, name);
}

immutable(Path) childPath(Alloc)(ref AllPaths!Alloc allPaths, immutable Path parent, scope immutable string name) {
	return getOrAddChild(allPaths, mutArrAt(allPaths.pathToChildren, parent.index), some(parent), name);
}

struct RelPath {
	private:
	immutable ubyte nParents_;
	immutable Path path_;
}

immutable(ubyte) nParents(ref immutable RelPath a) {
	return a.nParents_;
}
immutable(Path) path(ref immutable RelPath a) {
	return a.path_;
}

immutable(Opt!Path) resolvePath(Alloc)(
	ref AllPaths!Alloc allPaths,
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
				immutable RelPath(cast(ubyte) (relPath.nParents_ - 1), relPath.path_))
			: none!Path;
}

immutable(Opt!Path) resolvePath(Alloc)(ref AllPaths!Alloc allPaths, immutable Path path, immutable RelPath relPath) {
	return resolvePath(allPaths, some(path), relPath);
}

private immutable(Path) addManyChildren(Alloc)(ref AllPaths!Alloc allPaths, immutable Path a, immutable Path b) {
	immutable Opt!Path bParent = parent(allPaths, b);
	return childPath(allPaths, has(bParent) ? addManyChildren(allPaths, a, force(bParent)) : a, baseName(allPaths, b));
}

public void eachPathPart(PathAlloc)(
	ref const AllPaths!PathAlloc allPaths,
	immutable Path a,
	scope void delegate(immutable string) @safe @nogc pure nothrow cb,
) {
	immutable Opt!Path par = parent(allPaths, a);
	if (has(par))
		eachPathPart(allPaths, force(par), cb);
	cb(baseName(allPaths, a));
}

private void walkPathBackwards(Alloc)(
	ref const AllPaths!Alloc allPaths,
	immutable Path a,
	scope void delegate(immutable string) @safe @nogc pure nothrow cb,
) {
	cb(baseName(allPaths, a));
	immutable Opt!Path par = parent(allPaths, a);
	if (has(par))
		walkPathBackwards(allPaths, force(par), cb);
}

private size_t pathToStrSize(Alloc)(ref const AllPaths!Alloc allPaths, immutable Path path) {
	size_t sz = 0;
	walkPathBackwards(allPaths, path, (immutable string part) {
		// 1 for '/'
		sz += 1 + size(part);
	});
	return sz;
}

private @trusted immutable(string) pathToStrWorker(Alloc, PathAlloc)(
	ref Alloc alloc,
	ref const AllPaths!PathAlloc allPaths,
	immutable string root,
	immutable Path path,
	immutable string extension,
	immutable bool nulTerminated,
) {
	immutable size_t sz = size(root) + pathToStrSize(allPaths, path) + size(extension) + (nulTerminated ? 1 : 0);
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
	verify(cur == begin + size(root) + pathToStrSize(allPaths, path));
	@trusted void onPart(immutable string part) {
		cur -= size(part);
		char* j = cur;
		foreach (immutable char c; part) {
			*j = c;
			j++;
		}
		verify(j == cur + size(part));
		cur--;
		*cur = '/';
	}
	walkPathBackwards(allPaths, path, &onPart);
	verify(cur == begin + size(root));
	foreach_reverse (immutable char c; root) {
		cur--;
		*cur = c;
	}
	verify(cur == begin);
	return cast(immutable) begin[0 .. sz];
}

immutable(string) pathToStr(Alloc, PathAlloc)(
	ref Alloc alloc,
	ref const AllPaths!PathAlloc allPaths,
	immutable string root,
	immutable Path path,
	immutable string extension,
) {
	return pathToStrWorker(alloc, allPaths, root, path, extension, false);
}

immutable(CStr) pathToCStr(Alloc, PathAlloc)(
	ref Alloc alloc,
	ref const AllPaths!PathAlloc allPaths,
	immutable string root,
	immutable Path path,
	immutable string extension,
) {
	return pathToNulTerminatedStr(alloc, allPaths, root, path, extension).asCStr();
}

immutable(NulTerminatedStr) pathToNulTerminatedStr(Alloc, PathAlloc)(
	ref Alloc alloc,
	ref const AllPaths!PathAlloc allPaths,
	ref immutable AbsolutePath path,
) {
	return pathToNulTerminatedStr(alloc, allPaths, path.root, path.path, path.extension);
}

private immutable(NulTerminatedStr) pathToNulTerminatedStr(Alloc, PathAlloc)(
	ref Alloc alloc,
	ref const AllPaths!PathAlloc allPaths,
	immutable string root,
	immutable Path path,
	immutable string extension,
) {
	return immutable NulTerminatedStr(pathToStrWorker(alloc, allPaths, root, path, extension, true));
}

immutable(string) pathToStr(Alloc, PathAlloc)(
	ref Alloc alloc,
	ref const AllPaths!PathAlloc allPaths,
	ref immutable AbsolutePath path,
) {
	return pathToStr(alloc, allPaths, path.root, path.path, path.extension);
}
immutable(CStr) pathToCStr(Alloc, PathAlloc)(
	ref Alloc alloc,
	ref const AllPaths!PathAlloc allPaths,
	ref immutable AbsolutePath path,
) {
	return pathToNulTerminatedStr(alloc, allPaths, path.root, path.path, path.extension).asCStr();
}

immutable(Path) parsePath(Alloc)(ref AllPaths!Alloc allPaths, scope ref immutable string str) {
	immutable size_t len = size(str);
	size_t i = 0;
	if (i < len && at(str, i) == '/')
		// Ignore leading slash
		i++;

	immutable Path path = {
		immutable size_t begin = i;
		while (i < len && at(str, i) != '/')
			i++;
		verify(i != begin);
		immutable string part = str[begin .. i];
		return rootPath(allPaths, part);
	}();

	immutable(Path) recur(size_t i, immutable Path path) {
		if (i == len)
			return path;
		if (at(str, i) == '/')
			i++;
		if (i == len)
			return path;
		immutable size_t begin = i;
		while (i < len && at(str, i) != '/')
			i++;
		immutable string part = str[begin .. i];
		return recur(i, childPath(allPaths, path, part));
	}
	return recur(i, path);
}

private immutable(RelPath) parseRelPath(Alloc)(ref AllPaths!Alloc allPaths, immutable string s) {
	if (first(s) == '.')
		if (at(s, 1) == '/')
			return parseRelPath(allPaths, s[2 .. $]);
		else if (at(s, 1) == '.' && at(s, 2) == '/') {
			immutable RelPath r = parseRelPath(allPaths, s[3 .. $]);
			verify(r.nParents_ < 255);
			return immutable RelPath(cast(ubyte) (r.nParents_ + 1), r.path_);
		} else
			// Path component happens to start with '.' but is not '.' or '..'
			return immutable RelPath(0, parsePath(allPaths, s));
	else
		return immutable RelPath(0, parsePath(allPaths, s));
}

immutable(Opt!AbsolutePath) parent(Alloc)(ref const AllPaths!Alloc allPaths, ref immutable AbsolutePath a) {
	immutable Opt!Path pathParent = parent(allPaths, a.path);
	return has(pathParent)
		? some(immutable AbsolutePath(a.root, force(pathParent), ""))
		: none!AbsolutePath;
}

immutable(string) baseName(Alloc)(ref const AllPaths!Alloc allPaths, ref immutable AbsolutePath a) {
	return baseName(allPaths, a.path);
}

immutable(AbsolutePath) parseAbsoluteOrRelPath(Alloc)(
	ref AllPaths!Alloc allPaths,
	immutable string cwd,
	immutable string s,
) {
	immutable StrAndExtension se = removeExtension(s);
	immutable RootAndPath rp = parseAbsoluteOrRelPathWithoutExtension(allPaths, cwd, se.withoutExtension);
	return immutable AbsolutePath(rp.root, rp.path, se.extension);
}

private immutable(RootAndPath) parseAbsoluteOrRelPathWithoutExtension(Alloc)(
	ref AllPaths!Alloc allPaths,
	immutable string cwd,
	immutable string s,
) {
	switch (first(s)) {
		case '.':
			//TODO: handle parse error (return none if so)
			immutable RelPath rp = parseRelPath(allPaths, s);
			return immutable RootAndPath(dropParents(allPaths, cwd, rp.nParents_), rp.path_);
		case '/':
			immutable Path path = parsePath(allPaths, s);
			return immutable RootAndPath("", path);
		case '\\':
			return todo!(immutable RootAndPath)("unc path?");
		default:
			// Treat a plain string without '/' in front as a relative path
			return size(s) >= 2 && at(s, 1) == ':'
				? todo!(immutable RootAndPath)("C:/ ?")
				: immutable RootAndPath(cwd, parsePath(allPaths, s));
	}
}

private immutable(string) dropParents(Alloc)(
	ref const AllPaths!Alloc allPaths,
	immutable string path,
	immutable ubyte nParents,
) {
	if (nParents == 0)
		return path;
	else {
		immutable Opt!string p = pathParent(path);
		return dropParents(allPaths, forceOrTodo(p), cast(ubyte) (nParents - 1));
	}
}

private struct StrAndExtension {
	immutable string withoutExtension;
	immutable string extension; // Includes the '.' (if it exists)
}

private immutable(StrAndExtension) removeExtension(immutable string s) {
	// Deliberately not allowing i == 0
	for (size_t i = size(s) - 1; i > 0; i--)
		if (at(s, i) == '.')
			return immutable StrAndExtension(s[0 .. i], s[i .. $]);
	return immutable StrAndExtension(s, "");
}

// AbsolutePath with no extension
private struct RootAndPath {
	immutable string root;
	immutable Path path;
}

immutable(AbsolutePath) childPath(Alloc)(
	ref AllPaths!Alloc allPaths,
	ref immutable AbsolutePath parent,
	scope immutable string name,
) {
	return immutable AbsolutePath(parent.root, childPath(allPaths, parent.path, name), parent.extension);
}

private immutable(Opt!size_t) pathSlashIndex(immutable string s) {
	for (size_t i = s.size - 1; i > 0; i--)
		if (at(s, i) == '/')
			return some(i);
	return none!size_t;
}

private struct ParentAndBaseName {
	immutable string parent;
	immutable string baseName;
}

immutable(Opt!string) pathParent(return scope immutable string s) {
	immutable Opt!ParentAndBaseName o = pathParentAndBaseName(s);
	return mapOption(o, (ref immutable ParentAndBaseName p) => p.parent);
}

private immutable(Opt!ParentAndBaseName) pathParentAndBaseName(immutable string s) {
	immutable Opt!size_t index = pathSlashIndex(s);
	return has(index)
		? some(immutable ParentAndBaseName(s[0 .. force(index)], s[force(index) + 1 .. $]))
		: none!ParentAndBaseName;
}

immutable(Comparison) comparePath(immutable Path a, immutable Path b) {
	return compareNat16(a.index, b.index);
}

immutable(uint) nPathComponents(Alloc)(ref const AllPaths!Alloc allPaths, immutable Path a) {
	immutable Opt!Path par = parent(allPaths, a);
	return 1 + (has(par) ? nPathComponents(allPaths, force(par)) : 0);
}

enum StorageKind {
	global,
	local,
}

struct PathAndStorageKind {
	immutable Path path;
	immutable StorageKind storageKind;
}

immutable(Comparison) comparePathAndStorageKind(immutable PathAndStorageKind a, immutable PathAndStorageKind b) {
	return compareOr(
		compareEnum(a.storageKind, b.storageKind),
		() => comparePath(a.path, b.path));
}

struct PathAndRange {
	immutable PathAndStorageKind path;
	immutable RangeWithinFile range;
}
