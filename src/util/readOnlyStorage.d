module util.readOnlyStorage;

@safe @nogc nothrow: // not pure

import model.model : AbsolutePathsGetter;
import util.cell : Cell, cellGet, cellSet;
import util.opt : force, none, Opt, some;
import util.path : PathAndStorageKind;
import util.col.str : SafeCStr;

struct ReadOnlyStorage {
	immutable AbsolutePathsGetter absolutePathsGetter;
	// WARN: The string used may be a temporary
	void delegate(
		immutable PathAndStorageKind path,
		immutable SafeCStr extension,
		scope void delegate(immutable Opt!SafeCStr) @safe @nogc pure nothrow cb,
	) @safe @nogc nothrow withFile;
}

immutable(T) withFile(T)(
	scope ref const ReadOnlyStorage storage,
	immutable PathAndStorageKind path,
	immutable SafeCStr extension,
	immutable(T) delegate(immutable Opt!SafeCStr) @safe @nogc pure nothrow cb,
) {
	static if (is(T == void)) {
		storage.withFile(path, extension, (immutable Opt!SafeCStr content) {
			cb(content);
		});
	} else {
		Cell!(immutable Opt!T) res = Cell!(immutable Opt!T)(none!T);
		storage.withFile(path, extension, (immutable Opt!SafeCStr content) {
			cellSet!(immutable Opt!T)(res, some(cb(content)));
		});
		return force(cellGet(res));
	}
}
