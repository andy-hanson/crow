module util.dictReadOnlyStorage;

@safe @nogc nothrow: // not pure

import frontend.lang : crowExtension;
import util.col.mutDict : getAt_mut, MutDict;
import util.col.str : SafeCStr;
import util.opt : asImmutable, force, has, none, Opt;
import util.path : Path;
import util.readOnlyStorage : ReadFileResult, ReadOnlyStorage;
import util.sym : Sym;

immutable(T) withDictReadOnlyStorage(T)(
	immutable Path includeDir,
	scope ref const MutFiles files,
	scope immutable(T) delegate(scope ref const ReadOnlyStorage) @safe @nogc nothrow cb,
) {
	scope const ReadOnlyStorage storage = const ReadOnlyStorage(
		includeDir,
		(
			immutable Path path,
			void delegate(immutable ReadFileResult!(ubyte[])) @safe @nogc pure nothrow cb,
		) =>
			cb(immutable ReadFileResult!(ubyte[])(immutable ReadFileResult!(ubyte[]).NotFound())),
		(
			immutable Path path,
			immutable Sym extension,
			void delegate(immutable ReadFileResult!SafeCStr) @safe @nogc pure nothrow cb,
		) {
			immutable Opt!SafeCStr res = extension == crowExtension
				? asImmutable(getAt_mut(files, path))
				: none!SafeCStr;
			return cb(has(res)
				? immutable ReadFileResult!SafeCStr(force(res))
				: immutable ReadFileResult!SafeCStr(immutable ReadFileResult!SafeCStr.NotFound()));
		});
	return cb(storage);
}

alias MutFiles = MutDict!(immutable Path, immutable SafeCStr);
