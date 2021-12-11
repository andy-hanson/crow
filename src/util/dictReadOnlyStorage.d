module util.dictReadOnlyStorage;

@safe @nogc pure nothrow:

import frontend.lang : crowExtension;
import model.model : AbsolutePathsGetter;
import util.collection.mutDict : getAt_mut, MutDict;
import util.collection.str : SafeCStr, NulTerminatedStr, strEq;
import util.opt : asImmutable, Opt;
import util.path : hashPathAndStorageKind, PathAndStorageKind, pathAndStorageKindEqual;
import util.ptr : Ptr;
import util.util : verify;

struct DictReadOnlyStorage {
	@safe @nogc nothrow: // not pure

	pure immutable(AbsolutePathsGetter) absolutePathsGetter() const {
		return immutable AbsolutePathsGetter(immutable SafeCStr("include"), immutable SafeCStr("user"));
	}

	immutable(T) withFile(T)(
		immutable PathAndStorageKind pk,
		immutable string extension,
		scope immutable(T) delegate(ref immutable Opt!NulTerminatedStr) @safe @nogc nothrow cb,
	) const {
		verify(strEq(extension, crowExtension));
		immutable Opt!NulTerminatedStr content = asImmutable(getAt_mut(files.deref(), pk));
		return cb(content);
	}

	private:
	const Ptr!MutFiles files;
}

alias MutFiles = MutDict!(
	immutable PathAndStorageKind,
	immutable NulTerminatedStr,
	pathAndStorageKindEqual,
	hashPathAndStorageKind,
);
