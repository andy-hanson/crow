module util.readOnlyStorage;

@safe @nogc nothrow: // not pure

import util.cell : Cell, cellGet, cellSet;
import util.opt : force, none, Opt, some;
import util.path : Path;
import util.col.str : SafeCStr;

struct ReadOnlyStorage {
	// WARN: The string used may be a temporary
	immutable Path includeDir;
	void delegate(
		immutable Path path,
		immutable SafeCStr extension,
		scope void delegate(immutable Opt!SafeCStr) @safe @nogc pure nothrow cb,
	) @safe @nogc nothrow withFile;
}

immutable(T) withFile(T)(
	scope ref const ReadOnlyStorage storage,
	immutable Path path,
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
