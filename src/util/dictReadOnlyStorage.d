module util.dictReadOnlyStorage;

@safe @nogc pure nothrow:

import frontend.lang : crowExtension;
import model.model : AbsolutePathsGetter;
import util.collection.mutDict : getAt_mut, MutDict;
import util.collection.str : asSafeCStr, NulTerminatedStr, SafeCStr, safeCStr, strEq;
import util.opt : force, has, Opt, none, some;
import util.path : hashPathAndStorageKind, PathAndStorageKind, pathAndStorageKindEqual;
import util.ptr : Ptr;
import util.util : verify;

struct DictReadOnlyStorage {
	@safe @nogc nothrow: // not pure

	pure immutable(AbsolutePathsGetter) absolutePathsGetter() const {
		return immutable AbsolutePathsGetter(safeCStr!"include", safeCStr!"user");
	}

	immutable(T) withFile(T)(
		immutable PathAndStorageKind pk,
		immutable string extension,
		scope immutable(T) delegate(immutable Opt!SafeCStr) @safe @nogc nothrow cb,
	) const {
		verify(strEq(extension, crowExtension));
		const Opt!(immutable NulTerminatedStr) content = getAt_mut(files.deref(), pk);
		return cb(has(content) ? some(asSafeCStr(force(content))) : none!SafeCStr);
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
