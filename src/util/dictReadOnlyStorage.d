module util.dictReadOnlyStorage;

@safe @nogc nothrow: // not pure

import frontend.lang : crowExtension;
import util.col.mutDict : getAt_mut, MutDict;
import util.col.str : SafeCStr, safeCStrEq;
import util.opt : asImmutable, force, has, none, Opt;
import util.path : hashPath, Path, pathEqual;
import util.readOnlyStorage : ReadFileResult, ReadOnlyStorage;

immutable(T) withDictReadOnlyStorage(T)(
	immutable Path includeDir,
	scope ref const MutFiles files,
	scope immutable(T) delegate(scope ref const ReadOnlyStorage) @safe @nogc nothrow cb,
) {
	scope const ReadOnlyStorage storage = const ReadOnlyStorage(
		includeDir,
		(
			immutable Path path,
			immutable SafeCStr extension,
			void delegate(immutable ReadFileResult) @safe @nogc pure nothrow cb,
		) {
			immutable Opt!SafeCStr res = safeCStrEq(extension, crowExtension)
				? asImmutable(getAt_mut(files, path))
				: none!SafeCStr;
			return cb(has(res)
				? immutable ReadFileResult(force(res))
				: immutable ReadFileResult(immutable ReadFileResult.NotFound()));
		});
	return cb(storage);
}

alias MutFiles = MutDict!(immutable Path, immutable SafeCStr, pathEqual, hashPath);
