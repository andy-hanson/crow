module util.path;

@safe @nogc pure nothrow:

import util.bools : Bool, False, True;
import util.collection.arr : at, first, range, size;
import util.collection.arrUtil : slice, sliceFromTo;
import util.collection.str : asCStr, copyStr, CStr, emptyStr, NulTerminatedStr, Str;
import util.comparison : Comparison, compareOr;
import util.memory : nu;
import util.opt : compareOpt, has, flatMapOption, force, forceOrTodo, mapOption, matchOpt, none, Opt, some;
import util.ptr : Ptr;
import util.sourceRange : RangeWithinFile;
import util.sym : AllSymbols, compareSym, eachCharInSym, getSymFromAlphaIdentifier, Sym, symSize, tryGetSymFromStr;
import util.types : u8;
import util.util : todo, verify;

// This is a list of Sym basically. Doesn't have the root or extension.
struct Path {
	private:
	immutable Opt!(Ptr!Path) parent_;
	immutable Sym baseName_;
}

struct AbsolutePath {
	immutable Str root;
	immutable Ptr!Path path;
	immutable Str extension;
}

immutable(Str) parentStr(Alloc)(ref Alloc alloc, ref immutable AbsolutePath path) {
	immutable Opt!(Ptr!Path) p = parent(path.path);
	return has(p)
		? pathToStr(alloc, path.root, force(p), emptyStr)
		: copyStr(alloc, path.root);
}

immutable(AbsolutePath) withExtension(ref immutable AbsolutePath a, immutable Str newExtension) {
	return immutable AbsolutePath(a.root, a.path, newExtension);
}

ref immutable(Opt!(Ptr!Path)) parent(return scope ref immutable Path a) {
	return a.parent_;
}

immutable(Sym) baseName(immutable Path a) {
	return a.baseName_;
}

immutable(Ptr!Path) rootPath(Alloc)(ref Alloc alloc, immutable Sym name) {
	return nu!Path(alloc, none!(Ptr!Path), name);
}

immutable(Ptr!Path) childPath(Alloc)(ref Alloc alloc, immutable Opt!(Ptr!Path) parent, immutable Sym name) {
	return nu!Path(alloc, parent, name);
}

immutable(Ptr!Path) childPath(Alloc)(ref Alloc alloc, immutable Ptr!Path parent, immutable Sym name) {
	return childPath(alloc, some!(Ptr!Path)(parent), name);
}

immutable(Ptr!Path) childPath(Alloc)(
	ref Alloc alloc,
	immutable Ptr!Path parent,
	immutable Sym name0,
	immutable Sym name1,
) {
	return childPath(alloc, childPath(alloc, parent, name0), name1);
}

struct RelPath {
	private:
	immutable u8 nParents_;
	immutable Ptr!Path path_;
}

immutable(u8) nParents(ref immutable RelPath a) {
	return a.nParents_;
}
immutable(Ptr!Path) path(ref immutable RelPath a) {
	return a.path_;
}

immutable(Opt!(Ptr!Path)) resolvePath(Alloc)(
	ref Alloc alloc,
	immutable Opt!(Ptr!Path) path,
	immutable RelPath relPath,
) {
	return matchOpt(
		path,
		(ref immutable Ptr!Path cur) =>
			climbParents(cur, relPath.nParents_).mapOption!(Ptr!Path, Opt!(Ptr!Path))(
				(ref immutable Opt!(Ptr!Path) ancestor) =>
					matchOpt(
						ancestor,
						(ref immutable Ptr!Path a) => addManyChildren(alloc, a, relPath.path_),
						() => relPath.path_)),
		() =>
			relPath.nParents_ == 0
				? some!(Ptr!Path)(relPath.path_)
				: none!(Ptr!Path));
}



// none means can't do it. some(none) means we removed all parents successfully
private immutable(Opt!(Opt!(Ptr!Path))) climbParents(immutable Ptr!Path a, immutable size_t nParents) {
	return nParents == 0
		? some!(Opt!(Ptr!Path))(some!(Ptr!Path)(a))
		: a.parent.has
		? climbParents(a.parent.force, nParents - 1)
		: nParents == 1
		? some!(Opt!(Ptr!Path))(none!(Ptr!Path))
		: none!(Opt!(Ptr!Path));
}

immutable(Opt!(Ptr!Path)) resolvePath(Alloc)(ref Alloc alloc, immutable Ptr!Path path, immutable RelPath relPath) {
	return resolvePath(alloc, some!(Ptr!Path)(path), relPath);
}

private immutable(Ptr!Path) addManyChildren(Alloc)(ref Alloc alloc, immutable Ptr!Path a, immutable Ptr!Path b) {
	immutable Ptr!Path p = matchOpt(
		b.parent,
		(ref immutable Ptr!Path parent) => addManyChildren(alloc, a, parent),
		() => a);
	return childPath(alloc, p, baseName(b));
}

private void walkPathBackwards(immutable Ptr!Path p, scope void delegate(immutable Sym) @safe @nogc pure nothrow cb) {
	cb(baseName(p));
	matchOpt!(void, Ptr!Path)(
		p.parent,
		(ref immutable Ptr!Path parent) { walkPathBackwards(parent, cb); },
		() {},
	);
}

private size_t pathToStrSize(immutable Ptr!Path path) {
	size_t sz = 0;
	walkPathBackwards(path, (immutable Sym part) {
		// 1 for '/'
		sz += 1 + part.symSize;
	});
	return sz;
}

private @trusted immutable(Str) pathToStrWorker(Alloc)(
	ref Alloc alloc,
	immutable Str root,
	immutable Ptr!Path path,
	immutable Str extension,
	immutable Bool nulTerminated,
) {
	immutable size_t sz = root.size + pathToStrSize(path) + extension.size + (nulTerminated ? 1 : 0);
	char* begin = cast(char*) alloc.allocate(char.sizeof * sz);
	char* cur = begin + sz;
	if (nulTerminated) {
		cur--;
		*cur = '\0';
	}
	foreach_reverse (immutable char c; extension.range) {
		cur--;
		*cur = c;
	}
	verify(cur == begin + root.size + pathToStrSize(path));
	@trusted void onSym(immutable Sym part) {
		cur -= part.symSize;
		char* j = cur;
		@trusted void writeJ(immutable char c) {
			*j = c;
			j++;
		}
		part.eachCharInSym(&writeJ);
		verify(j == cur + part.symSize);
		cur--;
		*cur = '/';
	}
	walkPathBackwards(path, &onSym);
	verify(cur == begin + root.size);
	foreach_reverse (immutable char c; root.range) {
		cur--;
		*cur = c;
	}
	verify(cur == begin);
	return immutable Str(cast(immutable) begin, sz);
}

immutable(Str) pathToStr(Alloc)(ref Alloc alloc, immutable Str root, immutable Ptr!Path path, immutable Str extension) {
	return pathToStrWorker(alloc, root, path, extension, False);
}

immutable(CStr) pathToCStr(Alloc)(
	ref Alloc alloc,
	immutable Str root,
	immutable Ptr!Path path,
	immutable Str extension,
) {
	return pathToNulTerminatedStr(alloc, root, path, extension).asCStr();
}

private immutable(NulTerminatedStr) pathToNulTerminatedStr(Alloc)(
	ref Alloc alloc,
	immutable Str root,
	immutable Ptr!Path path,
	immutable Str extension,
) {
	return immutable NulTerminatedStr(pathToStrWorker(alloc, root, path, extension, True));
}

immutable(Str) pathToStr(Alloc)(ref Alloc alloc, immutable AbsolutePath path) {
	return pathToStr(alloc, path.root, path.path, path.extension);
}
immutable(CStr) pathToCStr(Alloc)(ref Alloc alloc, immutable AbsolutePath path) {
	return pathToNulTerminatedStr(alloc, path.root, path.path, path.extension).asCStr();
}

immutable(Ptr!Path) parsePath(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref AllSymbols!SymAlloc symbols,
	immutable Str str,
) {
	immutable size_t len = str.size;
	size_t i = 0;
	if (i < len && str.at(i) == '/')
		// Ignore leading slash
		i++;

	immutable Ptr!Path path = {
		immutable size_t begin = i;
		while (i < len && str.at(i) != '/')
			i++;
		verify(i != begin);
		return rootPath(alloc, getSymFromAlphaIdentifier(symbols, sliceFromTo(str, begin, i)));
	}();

	immutable(Ptr!Path) recur(size_t i, immutable Ptr!Path path) {
		if (i == len)
			return path;
		if (str.at(i) == '/')
			i++;
		if (i == len)
			return path;
		immutable size_t begin = i;
		while (i < len && str.at(i) != '/')
			i++;
		return recur(i, childPath(alloc, path, getSymFromAlphaIdentifier(symbols, sliceFromTo(str, begin, i))));
	}
	return recur(i, path);
}

private immutable(RelPath) parseRelPath(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref AllSymbols!SymAlloc allSymbols,
	immutable Str s,
) {
	if (s.first == '.')
		if (s.at(1) == '/')
			return parseRelPath(alloc, allSymbols, s.slice(2));
		else if (s.at(1) == '.' && s.at(2) == '/') {
			immutable RelPath r = parseRelPath(alloc, allSymbols, s.slice(3));
			verify(r.nParents_ < 255);
			return RelPath(cast(ubyte) (r.nParents_ + 1), r.path_);
		} else
			// Path component happens to start with '.' but is not '.' or '..'
			return RelPath(0, parsePath(alloc, allSymbols, s));
	else
		return RelPath(0, parsePath(alloc, allSymbols, s));
}

immutable(Opt!AbsolutePath) parent(ref immutable AbsolutePath a) {
	immutable Opt!(Ptr!Path) pathParent = parent(a.path);
	return pathParent.has
		? some(immutable AbsolutePath(a.root, pathParent.force, emptyStr))
		: none!AbsolutePath;
}

immutable(Sym) baseName(ref immutable AbsolutePath a) {
	return baseName(a.path);
}

immutable(Opt!AbsolutePath) parseAbsoluteOrRelPath(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref AllSymbols!SymAlloc allSymbols,
	immutable Str cwd,
	immutable Str s,
) {
	immutable StrAndExtension se = removeExtension(s);
	immutable Opt!RootAndPath rp = parseAbsoluteOrRelPathWithoutExtension(alloc, allSymbols, cwd, se.withoutExtension);
	return mapOption(rp, (ref immutable RootAndPath r) =>
		immutable AbsolutePath(r.root, r.path, se.extension));
}

private immutable(Opt!RootAndPath) parseAbsoluteOrRelPathWithoutExtension(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref AllSymbols!SymAlloc allSymbols,
	immutable Str cwd,
	immutable Str s,
) {
	switch (s.first) {
		case '.':
			//TODO: handle parse error (return none if so)
			immutable RelPath rp = parseRelPath(alloc, allSymbols, s);
			return some(immutable RootAndPath(dropParents(cwd, rp.nParents_), rp.path_));
		case '/':
			return parseAbsolutePathNoExtension(alloc, allSymbols, s);
		case '\\':
			return todo!(Opt!RootAndPath)("unc path?");
		default:
			// Treat a plain string without '/' in front as a relative path
			return size(s) >= 2 && s.at(1) == ':'
				? todo!(Opt!RootAndPath)("C:/ ?")
				: some(immutable RootAndPath(cwd, parsePath(alloc, allSymbols, s)));
	}
}

private immutable(Str) dropParents(immutable Str path, immutable u8 nParents) {
	if (nParents == 0)
		return path;
	else {
		immutable Opt!Str p = pathParent(path);
		return dropParents(p.forceOrTodo, cast(u8) (nParents - 1));
	}
}

private struct StrAndExtension {
	immutable Str withoutExtension;
	immutable Str extension; // Includes the '.' (if it exists)
}

private immutable(StrAndExtension) removeExtension(immutable Str s) {
	// Deliberately not allowing i == 0
	for (size_t i = s.size - 1; i > 0; i--)
		if (s.at(i) == '.')
			return StrAndExtension(s.slice(0, i), s.slice(i));
	return StrAndExtension(s, emptyStr);
}

// AbsolutePath with no extension
private struct RootAndPath {
	immutable Str root;
	immutable Ptr!Path path;
}

private immutable(Opt!RootAndPath) parseAbsolutePathNoExtension(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref AllSymbols!SymAlloc allSymbols,
	immutable Str s,
) {
	return flatMapOption(pathParentAndBaseName(s), (ref immutable ParentAndBaseName pbn) {
		immutable Opt!Sym sym = tryGetSymFromStr(allSymbols, pbn.baseName);
		if (sym.has) {
			immutable Opt!RootAndPath left = parseAbsolutePathNoExtension(alloc, allSymbols, pbn.parent);
			return left.has
				? some!RootAndPath(immutable RootAndPath(left.force.root, childPath(alloc, left.force.path, sym.force)))
				: some!RootAndPath(immutable RootAndPath(pbn.parent, rootPath(alloc, sym.force)));
		} else {
			return none!RootAndPath;
		}
	});
}

immutable(AbsolutePath) childPath(Alloc)(ref Alloc alloc, immutable AbsolutePath parent, immutable Sym name) {
	return AbsolutePath(parent.root, childPath(alloc, parent.path, name), parent.extension);
}

private immutable(Opt!size_t) pathSlashIndex(immutable Str s) {
	for (size_t i = s.size - 1; i > 0; i--)
		if (s.at(i) == '/')
			return some(i);
	return none!size_t;
}

private struct ParentAndBaseName {
	immutable Str parent;
	immutable Str baseName;
}

immutable(Opt!Str) pathBaseName(immutable Str s) {
	immutable Opt!ParentAndBaseName o = pathParentAndBaseName(s);
	return mapOption(o, (ref immutable ParentAndBaseName p) => p.baseName);
}
immutable(Opt!Str) pathParent(immutable Str s) {
	immutable Opt!ParentAndBaseName o = pathParentAndBaseName(s);
	return mapOption(o, (ref immutable ParentAndBaseName p) => p.parent);
}

private immutable(Opt!ParentAndBaseName) pathParentAndBaseName(immutable Str s) {
	immutable Opt!size_t index = pathSlashIndex(s);
	return index.has
		? some(immutable ParentAndBaseName(s.slice(0, index.force), s.slice(index.force + 1)))
		: none!ParentAndBaseName;
}

immutable(Comparison) comparePath(immutable Ptr!Path a, immutable Ptr!Path b) {
	return compareOr(
		compareSym(baseName(a), baseName(b)),
		() => compareOpt!(Ptr!Path)(a.parent, b.parent, (ref immutable Ptr!Path x, ref immutable Ptr!Path y) =>
			comparePath(x, y)));
}

enum StorageKind {
	global,
	local,
}

struct PathAndStorageKind {
	immutable Ptr!Path path;
	immutable StorageKind storageKind;
}

struct PathAndRange {
	immutable PathAndStorageKind path;
	immutable RangeWithinFile range;
}

//TODO:KILL?
immutable(Ptr!Path) copyPath(Alloc)(ref Alloc alloc, immutable Ptr!Path a) {
	return nu!Path(
		alloc,
		has(a.parent)
			? some(copyPath(alloc, force(a.parent)))
			: none!(Ptr!Path),
		baseName(a));
}
