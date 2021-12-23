module util.dictReadOnlyStorage;

@safe @nogc nothrow: // not pure

import frontend.lang : crowExtension;
import model.model : AbsolutePathsGetter;
import util.col.mutDict : getAt_mut, MutDict;
import util.col.str : SafeCStr, safeCStr, safeCStrEq;
import util.opt : asImmutable, Opt;
import util.path : hashPathAndStorageKind, PathAndStorageKind, pathAndStorageKindEqual;
import util.readOnlyStorage : ReadOnlyStorage;
import util.util : verify;

immutable(T) withDictReadOnlyStorage(T)(
	scope ref const MutFiles files,
	scope immutable(T) delegate(scope ref const ReadOnlyStorage) @safe @nogc nothrow cb,
) {
	scope const ReadOnlyStorage storage = const ReadOnlyStorage(
		immutable AbsolutePathsGetter(safeCStr!"cwd", safeCStr!"include", safeCStr!"user"),
		(
			immutable PathAndStorageKind path,
			immutable SafeCStr extension,
			void delegate(immutable Opt!SafeCStr) @safe @nogc pure nothrow cb,
		) {
			verify(safeCStrEq(extension, crowExtension));
			cb(asImmutable(getAt_mut(files, path)));
		});
	return cb(storage);
}

alias MutFiles = MutDict!(
	immutable PathAndStorageKind,
	immutable SafeCStr,
	pathAndStorageKindEqual,
	hashPathAndStorageKind,
);
