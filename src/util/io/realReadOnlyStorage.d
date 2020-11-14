module util.io.realReadOnlyStorage;

@safe @nogc nothrow: // not pure

import model.model : AbsolutePathsGetter;
import util.collection.str : NulTerminatedStr, Str;
import util.io.io : tryReadFile;
import util.opt : Opt;
import util.path : AbsolutePath, PathAndStorageKind, StorageKind;
import util.ptr : Ptr;

struct RealReadOnlyStorage(Alloc) {
	@safe @nogc nothrow: // not pure

	immutable(AbsolutePathsGetter) absolutePathsGetter() const {
		return immutable AbsolutePathsGetter(include, user);
	}

	immutable(T) withFile(T)(
		ref immutable PathAndStorageKind pk,
		immutable Str extension,
		scope immutable(T) delegate(ref immutable Opt!NulTerminatedStr) @safe @nogc nothrow cb,
	) {
		immutable Str root = () {
			final switch (pk.storageKind) {
				case StorageKind.global:
					return include;
				case StorageKind.local:
					return user;
			}
		}();
		immutable AbsolutePath ap = immutable AbsolutePath(root, pk.path, extension);
		return tryReadFile(alloc, alloc, ap, cb);
	}

	private:
	Ptr!Alloc alloc;
	immutable Str include;
	immutable Str user;
}
