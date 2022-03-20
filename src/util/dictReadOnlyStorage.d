module util.dictReadOnlyStorage;

@safe @nogc nothrow: // not pure

import frontend.lang : crowExtension;
import util.col.mutDict : getAt_mut, MutDict;
import util.col.str : SafeCStr, safeCStrEq;
import util.opt : asImmutable, Opt;
import util.path : hashPath, Path, pathEqual;
import util.readOnlyStorage : ReadOnlyStorage;
import util.util : verify;

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
			void delegate(immutable Opt!SafeCStr) @safe @nogc pure nothrow cb,
		) {
			verify(safeCStrEq(extension, crowExtension));
			return cb(asImmutable(getAt_mut(files, path)));
		});
	return cb(storage);
}

alias MutFiles = MutDict!(immutable Path, immutable SafeCStr, pathEqual, hashPath);
