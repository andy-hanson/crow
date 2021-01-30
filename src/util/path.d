module util.path;

@safe @nogc pure nothrow:

import util.bools : Bool, False, True;
import util.collection.arr : at, first, size;
import util.collection.arrUtil : slice, sliceFromTo;
import util.collection.mutArr : MutArr, mutArrAt, mutArrRange, mutArrSize, push;
import util.collection.str : asCStr, copyStr, CStr, emptyStr, NulTerminatedStr;
import util.comparison : compareEnum, compareNat16, Comparison, compareOr;
import util.opt : has, flatMapOption, force, forceOrTodo, mapOption, none, Opt, some;
import util.ptr : Ptr;
import util.sourceRange : RangeWithinFile;
import util.sym : AllSymbols, eachCharInSym, getSymFromAlphaIdentifier, Sym, symSize, tryGetSymFromStr;
import util.types : safeSizeTToU16;
import util.util : todo, verify;

struct AllPaths(Alloc) {
	private:
	Ptr!Alloc alloc;
	MutArr!(Opt!Path) pathToParent;
	MutArr!Sym pathToBaseName;
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

immutable(string) parentStr(Alloc, PathAlloc)(
	ref Alloc alloc,
	ref AllPaths!PathAlloc allPaths,
	ref immutable AbsolutePath path,
) {
	immutable Opt!Path p = parent(allPaths, path.path);
	return has(p)
		? pathToStr(alloc, allPaths, path.root, force(p), emptyStr)
		: copyStr(alloc, path.root);
}

immutable(AbsolutePath) withExtension(ref immutable AbsolutePath a, immutable string newExtension) {
	return immutable AbsolutePath(a.root, a.path, newExtension);
}

immutable(Opt!Path) parent(Alloc)(ref const AllPaths!Alloc allPaths, immutable Path a) {
	return mutArrAt(allPaths.pathToParent, a.index);
}

immutable(Sym) baseName(Alloc)(ref const AllPaths!Alloc allPaths, immutable Path a) {
	return mutArrAt(allPaths.pathToBaseName, a.index);
}

private immutable(Path) getOrAddChild(Alloc)(
	ref AllPaths!Alloc allPaths,
	ref MutArr!Path children,
	immutable Opt!Path parent,
	immutable Sym name,
) {
	foreach (immutable Path child; mutArrRange(children))
		if (baseName(allPaths, child) == name)
			return child;

	immutable Path res = immutable Path(safeSizeTToU16(mutArrSize(allPaths.pathToParent)));
	push(allPaths.alloc, children, res);
	push(allPaths.alloc, allPaths.pathToParent, parent);
	push(allPaths.alloc, allPaths.pathToBaseName, name);
	push(allPaths.alloc, allPaths.pathToChildren, MutArr!Path());
	return res;
}

immutable(Path) rootPath(Alloc)(ref AllPaths!Alloc allPaths, immutable Sym name) {
	return getOrAddChild(allPaths, allPaths.rootChildren, none!Path, name);
}

immutable(Path) childPath(Alloc)(ref AllPaths!Alloc allPaths, immutable Path parent, immutable Sym name) {
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

private void walkPathBackwards(Alloc)(
	ref const AllPaths!Alloc allPaths,
	immutable Path a,
	scope void delegate(immutable Sym) @safe @nogc pure nothrow cb,
) {
	cb(baseName(allPaths, a));
	immutable Opt!Path par = parent(allPaths, a);
	if (has(par))
		walkPathBackwards(allPaths, force(par), cb);
}

private size_t pathToStrSize(Alloc)(ref const AllPaths!Alloc allPaths, immutable Path path) {
	size_t sz = 0;
	walkPathBackwards(allPaths, path, (immutable Sym part) {
		// 1 for '/'
		sz += 1 + part.symSize;
	});
	return sz;
}

private @trusted immutable(string) pathToStrWorker(Alloc, PathAlloc)(
	ref Alloc alloc,
	ref const AllPaths!PathAlloc allPaths,
	immutable string root,
	immutable Path path,
	immutable string extension,
	immutable Bool nulTerminated,
) {
	immutable size_t sz = size(root) + pathToStrSize(allPaths, path) + size(extension) + (nulTerminated ? 1 : 0);
	char* begin = cast(char*) alloc.allocateBytes(char.sizeof * sz);
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
	@trusted void onSym(immutable Sym part) {
		cur -= symSize(part);
		char* j = cur;
		@trusted void writeJ(immutable char c) {
			*j = c;
			j++;
		}
		eachCharInSym(part, &writeJ);
		verify(j == cur + symSize(part));
		cur--;
		*cur = '/';
	}
	walkPathBackwards(allPaths, path, &onSym);
	verify(cur == begin + size(root));
	foreach_reverse (immutable char c; root) {
		cur--;
		*cur = c;
	}
	verify(cur == begin);
	return cast(immutable) begin[0..sz];
}

immutable(string) pathToStr(Alloc, PathAlloc)(
	ref Alloc alloc,
	ref const AllPaths!PathAlloc allPaths,
	immutable string root,
	immutable Path path,
	immutable string extension,
) {
	return pathToStrWorker(alloc, allPaths, root, path, extension, False);
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

private immutable(NulTerminatedStr) pathToNulTerminatedStr(Alloc, PathAlloc)(
	ref Alloc alloc,
	ref const AllPaths!PathAlloc allPaths,
	immutable string root,
	immutable Path path,
	immutable string extension,
) {
	return immutable NulTerminatedStr(pathToStrWorker(alloc, allPaths, root, path, extension, True));
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

immutable(Path) parsePath(Alloc, SymAlloc)(
	ref AllPaths!Alloc allPaths,
	ref AllSymbols!SymAlloc symbols,
	scope ref immutable string str,
) {
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
		immutable string part = sliceFromTo(str, begin, i);
		return rootPath(allPaths, getSymFromAlphaIdentifier(symbols, part));
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
		immutable string part = sliceFromTo(str, begin, i);
		return recur(i, childPath(allPaths, path, getSymFromAlphaIdentifier(symbols, part)));
	}
	return recur(i, path);
}

private immutable(RelPath) parseRelPath(Alloc, SymAlloc)(
	ref AllPaths!Alloc allPaths,
	ref AllSymbols!SymAlloc allSymbols,
	immutable string s,
) {
	if (first(s) == '.')
		if (at(s, 1) == '/')
			return parseRelPath(allPaths, allSymbols, s.slice(2));
		else if (at(s, 1) == '.' && at(s, 2) == '/') {
			immutable RelPath r = parseRelPath(allPaths, allSymbols, s.slice(3));
			verify(r.nParents_ < 255);
			return immutable RelPath(cast(ubyte) (r.nParents_ + 1), r.path_);
		} else
			// Path component happens to start with '.' but is not '.' or '..'
			return immutable RelPath(0, parsePath(allPaths, allSymbols, s));
	else
		return immutable RelPath(0, parsePath(allPaths, allSymbols, s));
}

immutable(Opt!AbsolutePath) parent(Alloc)(ref const AllPaths!Alloc allPaths, ref immutable AbsolutePath a) {
	immutable Opt!Path pathParent = parent(allPaths, a.path);
	return has(pathParent)
		? some(immutable AbsolutePath(a.root, force(pathParent), emptyStr))
		: none!AbsolutePath;
}

immutable(Sym) baseName(Alloc)(ref const AllPaths!Alloc allPaths, ref immutable AbsolutePath a) {
	return baseName(allPaths, a.path);
}

immutable(Opt!AbsolutePath) parseAbsoluteOrRelPath(Alloc, SymAlloc)(
	ref AllPaths!Alloc allPaths,
	ref AllSymbols!SymAlloc allSymbols,
	immutable string cwd,
	immutable string s,
) {
	immutable StrAndExtension se = removeExtension(s);
	immutable Opt!RootAndPath rp =
		parseAbsoluteOrRelPathWithoutExtension(allPaths, allSymbols, cwd, se.withoutExtension);
	return mapOption(rp, (ref immutable RootAndPath r) =>
		immutable AbsolutePath(r.root, r.path, se.extension));
}

private immutable(Opt!RootAndPath) parseAbsoluteOrRelPathWithoutExtension(Alloc, SymAlloc)(
	ref AllPaths!Alloc allPaths,
	ref AllSymbols!SymAlloc allSymbols,
	immutable string cwd,
	immutable string s,
) {
	switch (first(s)) {
		case '.':
			//TODO: handle parse error (return none if so)
			immutable RelPath rp = parseRelPath(allPaths, allSymbols, s);
			return some(immutable RootAndPath(dropParents(allPaths, cwd, rp.nParents_), rp.path_));
		case '/':
			return parseAbsolutePathNoExtension(allPaths, allSymbols, s);
		case '\\':
			return todo!(Opt!RootAndPath)("unc path?");
		default:
			// Treat a plain string without '/' in front as a relative path
			return size(s) >= 2 && at(s, 1) == ':'
				? todo!(Opt!RootAndPath)("C:/ ?")
				: some(immutable RootAndPath(cwd, parsePath(allPaths, allSymbols, s)));
	}
}

private immutable(string) dropParents(Alloc)(
	ref const AllPaths!Alloc allPaths,
	ref immutable string path,
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
			return StrAndExtension(s.slice(0, i), s.slice(i));
	return StrAndExtension(s, emptyStr);
}

// AbsolutePath with no extension
private struct RootAndPath {
	immutable string root;
	immutable Path path;
}

private immutable(Opt!RootAndPath) parseAbsolutePathNoExtension(Alloc, SymAlloc)(
	ref AllPaths!Alloc allPaths,
	ref AllSymbols!SymAlloc allSymbols,
	immutable string s,
) {
	return flatMapOption(pathParentAndBaseName(s), (ref immutable ParentAndBaseName pbn) {
		immutable Opt!Sym sym = tryGetSymFromStr(allSymbols, pbn.baseName);
		if (has(sym)) {
			immutable Opt!RootAndPath left = parseAbsolutePathNoExtension(allPaths, allSymbols, pbn.parent);
			return has(left)
				? some(immutable RootAndPath(force(left).root, childPath(allPaths, force(left).path, force(sym))))
				: some(immutable RootAndPath(pbn.parent, rootPath(allPaths, force(sym))));
		} else
			return none!RootAndPath;
	});
}

immutable(AbsolutePath) childPath(Alloc)(
	ref AllPaths!Alloc allPaths,
	ref immutable AbsolutePath parent,
	immutable Sym name,
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

immutable(Opt!string) pathBaseName(return scope ref immutable string s) {
	immutable Opt!ParentAndBaseName o = pathParentAndBaseName(s);
	return mapOption(o, (ref immutable ParentAndBaseName p) => p.baseName);
}
immutable(Opt!string) pathParent(return scope ref immutable string s) {
	immutable Opt!ParentAndBaseName o = pathParentAndBaseName(s);
	return mapOption(o, (ref immutable ParentAndBaseName p) => p.parent);
}

private immutable(Opt!ParentAndBaseName) pathParentAndBaseName(immutable string s) {
	immutable Opt!size_t index = pathSlashIndex(s);
	return has(index)
		? some(immutable ParentAndBaseName(s.slice(0, force(index)), s.slice(force(index) + 1)))
		: none!ParentAndBaseName;
}

immutable(Comparison) comparePath(immutable Path a, immutable Path b) {
	return compareNat16(a.index, b.index);
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
