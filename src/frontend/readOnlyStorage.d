module frontend.readOnlyStorage;

@safe @nogc nothrow: // not pure

import model : AbsolutePathsGetter;

import util.collection.str : NulTerminatedStr;
import util.io : ioTryReadFile = tryReadFile;
import util.opt : Opt;
import util.path : AbsolutePath, addManyChildren, Path, StorageKind;
import util.ptr : Ptr;

struct ReadOnlyStorage {
	immutable AbsolutePath root;
}

immutable(Opt!NulTerminatedStr) tryReadFile(Alloc)(
	ref ReadOnlyStorage storage,
	ref Alloc alloc,
	immutable Ptr!Path path,
	immutable string extension,
) {
	return ioTryReadFile(alloc, addManyChildren!Alloc(alloc, storage.root, path), extension);
}

pure:

struct ReadOnlyStorages {
	ReadOnlyStorage include;
	ReadOnlyStorage user;
}

immutable(AbsolutePathsGetter) absolutePathsGetter(ref const ReadOnlyStorages a) {
	return AbsolutePathsGetter(a.include.root, a.user.root);
}

ref ReadOnlyStorage choose(return scope ref ReadOnlyStorages a, immutable StorageKind storageKind) {
	final switch (storageKind) {
		case StorageKind.global:
			return a.include;
		case StorageKind.local:
			return a.user;
	}
}
