module util.readOnlyStorage;

@safe @nogc nothrow: // not pure

import util.cell : Cell, cellGet, cellSet;
import util.opt : force, none, Opt, some;
import util.path : Path;
import util.col.str : SafeCStr;
import util.sym : Sym;
import util.union_ : Union;

struct ReadOnlyStorage {
	// WARN: The string used may be a temporary
	immutable Path includeDir;
	private void delegate(
		immutable Path path,
		scope void delegate(immutable ReadFileResult!(ubyte[])) @safe @nogc pure nothrow cb,
	) @safe @nogc nothrow withFileBinary_;
	private void delegate(
		immutable Path path,
		immutable Sym extension,
		scope void delegate(immutable ReadFileResult!SafeCStr) @safe @nogc pure nothrow cb,
	) @safe @nogc nothrow withFileText_;
}

struct ReadFileResult(T) {
	struct NotFound {}
	struct Error {}
	mixin Union!(immutable T, immutable NotFound, immutable Error);
}

pure immutable(Opt!T) asOption(T)(immutable ReadFileResult!T a) =>
	a.match!(immutable Opt!T)(
		(immutable T x) =>
			some(x),
		(immutable(ReadFileResult!T.NotFound)) =>
			none!SafeCStr,
		(immutable(ReadFileResult!T.Error)) =>
			none!SafeCStr);

immutable(T) withFileBinary(T)(
	scope ref const ReadOnlyStorage storage,
	immutable Path path,
	immutable(T) delegate(immutable ReadFileResult!(ubyte[])) @safe @nogc pure nothrow cb,
) {
	Cell!(immutable Opt!T) res = Cell!(immutable Opt!T)(none!T);
	storage.withFileBinary_(path, (immutable ReadFileResult!(ubyte[]) content) {
		cellSet!(immutable Opt!T)(res, some(cb(content)));
	});
	return force(cellGet(res));
}

immutable(T) withFileText(T)(
	scope ref const ReadOnlyStorage storage,
	immutable Path path,
	immutable Sym extension,
	immutable(T) delegate(immutable ReadFileResult!SafeCStr) @safe @nogc pure nothrow cb,
) {
	static if (is(T == void)) {
		storage.withFileText_(path, extension, (immutable ReadFileResult!SafeCStr content) {
			cb(content);
		});
	} else {
		Cell!(immutable Opt!T) res = Cell!(immutable Opt!T)(none!T);
		storage.withFileText_(path, extension, (immutable ReadFileResult!SafeCStr content) {
			cellSet!(immutable Opt!T)(res, some(cb(content)));
		});
		return force(cellGet(res));
	}
}
