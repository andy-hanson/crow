module util.io.realReadOnlyStorage;

@safe @nogc nothrow: // not pure

import model.model : AbsolutePathsGetter;
import util.collection.str : NulTerminatedStr, Str;
import util.io.io : ioTryReadFile = tryReadFile;
import util.opt : Opt;
import util.path : AbsolutePath, PathAndStorageKind, StorageKind;

struct RealReadOnlyStorage {
	@safe @nogc nothrow: // not pure

	immutable(AbsolutePathsGetter) absolutePathsGetter() immutable {
		return immutable AbsolutePathsGetter(include, user);
	}

	immutable(Opt!NulTerminatedStr) tryReadFile(Alloc)(
		ref Alloc alloc,
		ref immutable PathAndStorageKind pk,
		immutable Str extension,
	) immutable {
		immutable Str root = () {
			final switch (pk.storageKind) {
				case StorageKind.global:
					return include;
				case StorageKind.local:
					return user;
			}
		}();
		return ioTryReadFile(alloc, AbsolutePath(root, pk.path, extension));
	}

	private:
	immutable Str include;
	immutable Str user;
}
