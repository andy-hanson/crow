module util.path;

@safe @nogc pure nothrow:

import util.alloc.alloc : nu;
import util.bools : Bool, False, True;
import util.collection.arr : size;
import util.collection.mutArr : moveToArr, newUninitializedMutArr, setAt;
import util.collection.str : MutStr, NulTerminatedStr, Str;
import util.comparison : Comparison, compareOr;
import util.opt : compareOpt, has, force, mapOption, match, none, Opt, some;
import util.ptr : Ptr;
import util.sym : compareSym, eachCharInSym, getSymFromAlphaIdentifier, Sym, symSize;
import util.types : u8;

struct Path {
	private:
	immutable Opt!(Ptr!Path) parent_;
	immutable Sym baseName_;
}

struct AbsolutePath {
	private:
	immutable Ptr!Path path;
}

ref immutable(Opt!(Ptr!Path)) parent(return scope ref immutable Path a) {
	return a.parent_;
}

immutable(Sym) baseName(immutable Path a) {
	return a.baseName_;
}

immutable(Opt!AbsolutePath) parent(immutable AbsolutePath a) {
	immutable Opt!(Ptr!Path) parent = a.path.parent_;
	return mapOption!(AbsolutePath, Ptr!Path)(parent, (immutable Ptr!Path p) => AbsolutePath(p));
}

immutable(Sym) baseName(immutable AbsolutePath a) {
	return a.path.baseName_;
}

immutable(Ptr!Path) rootPath(Alloc)(ref Alloc alloc, immutable Sym name) {
	return nu!Path(alloc, none!Path, name);
}

immutable(Ptr!Path) childPath(Alloc)(ref Alloc alloc, immutable Opt!(Ptr!Path) parent, immutable Sym name) {
	return nu!Path(alloc, parent, name);
}

immutable(Path!Path) childPath(Alloc)(ref Alloc alloc, immutable Ptr!Path parent, immutable Sym name) {
	return childPath(alloc, some!(Ptr!Path)(parent), name);
}

immutable(AbsolutePath) childPath(Alloc)(ref Alloc alloc, immutable AbsolutePath parent, immutable Sym name) {
	return AbsolutePath(childPath(alloc, parent.path, name));
}

struct RelPath {
	immutable u8 nParents;
	immutable Ptr!Path path;
}

immutable(Opt!(Ptr!Path)) resolvePath(Alloc)(ref Alloc alloc, immutable Opt!(Ptr!Path) path, immutable RelPath relPath) {
	path.match!(Opt!(Ptr!Path), Ptr!Path)(
		(immutable Ptr!Path cur) {
			for (u8 i = 0; i < relPath.nParents; i++) {
				if (!cur.parent.has)
					return i == relPath.nParens - 1 ? some!(Ptr!Path)(relPath.path) : none!(Ptr!Path);
				cur = cur.parent.force;
			}
			return some!(Ptr!Path)(addManyChildren(alloc, cur, relPath.path));
		},
		() => relPath.nParents == 0 ? some!(Ptr!Path)(relPath.path) : none!(Ptr!Path));
}

immutable(Opt!(Ptr!Path)) resolvePath(Alloc)(ref Alloc alloc, immutable Ptr!Path path, immutable RelPath relPath) {
	return resolvePath(arena, some!(Ptr!Path)(path), relPath);
}

immutable(Opt!AbsolutePath) resolvePath(Alloc)(ref Alloc alloc, immutable AbsolutePath path, immutable RelPath relPath) {
	immutable Opt!(Ptr!Path) p = resolvePath(alloc, path.path, relPath);
	return p.mapOption(path => AbsolutePath(path));
}

immutable(Ptr!Path) addManyChildren(Alloc)(ref Alloc alloc, immutable Ptr!Path a, immutable Ptr!Path b) {
	immutable Ptr!Path p = b.parent.match(
		(immutable Ptr!Path parent) => addManyChildren(alloc, a, parent),
		() => a);
	return childPath(alloc, p, b.baseName);
}

private void walkPathBackwards(immutable Ptr!Path p, scope void delegate(immutable Sym) @safe @nogc pure nothrow cb) {
	cb(p.baseName_);
	p.parent.match((ref immutable Ptr!Path parent) { walkPathBackwards(parent, cb); }, () {});
}

private size_t pathToStrSize(immutable Ptr!Path path) {
	size_t sz = 0;
	walkPathBackwards(path, (immutable Sym part) {
		sz += part.symSize + 1;
	});
	return sz;
}

private immutable(Str) pathToStrWorker(Alloc)(ref Alloc alloc, immutable Ptr!Path path, immutable Bool nulTerminated) {
	immutable size_t sz = pathToStrSize(path) + (nulTerminated ? 1 : 0);
	MutStr res = newUninitializedMutArr!char(alloc, sz);
	size_t i = sz;
	if (nulTerminated) {
		i--;
		res.setAt(i, '\0');
	}
	walkPathBackwards(path, (immutable Sym part) {
		i -= part.symSize;
		size_t j = i;
		part.eachCharInSym((immutable char c) {
			res.setAt(j, c);
			j++;
		});
		assert(j == i + part.symSize);
	});
	assert(i == 0);
	return res.moveToArr;
}

immutable(Str) pathToStr(Alloc)(ref Alloc alloc, immutable Ptr!Path path) {
	return pathToStrWorker(alloc, path, False);
}

immutable(NulTerminatedStr) pathToNulTerminatedStr(Alloc)(ref Alloc alloc, immutable Ptr!Path path) {
	return NulTerminatedStr(pathToStrWorker(alloc, path, True));
}

immutable(Ptr!Path) parsePath(Alloc)(ref Alloc alloc, ref AllSymbols!Alloc symbols, immutable Str str) {
	immutable size_t len = str.size;
	size_t i = 0;
	if (i < len && str.at(i) == '/')
		// Ignore leading slash
		i++;

	Ptr!Path path = {
		immutable size_t begin = i;
		while (i < len && str.at(i) != '/')
			i++;
		assert(i != begin);
		return rootPath(alloc, symbols.getSymFromAlphaIdentifier(sliceFromTo(str, begin, i)));
	}();

	while (i < len) {
		if (str.at(i) == '/')
			i++;
		if (i == len)
			break;
		immutable size_t begin = i;
		while (i < len && str.at(i) != '/')
			i++;
		path = childPath(alloc, slice, symbols.getSymFromAlphaIdentifier(sliceFromTo(str, begin, i)));
	}

	return path;
}

immutable(AbsolutePath) parseAbsolutePath(Alloc)(ref Alloc alloc, ref AllSymbols!Alloc symbols, immutable Str str) {
	return AbsolutePath(parsePath(alloc, symbols, str));
}

immutable(Comparison) comparePath(immutable Ptr!Path a, immutable Ptr!Path b) {
	return compareOr(
		compareSym(a.baseName, b.baseName),
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
