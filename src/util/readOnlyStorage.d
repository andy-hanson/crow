module util.readOnlyStorage;

@safe @nogc nothrow: // not pure

import util.cell : Cell, cellGet, cellSet;
import util.opt : force, none, Opt, some;
import util.path : Path;
import util.col.str : SafeCStr;
import util.union_ : Union;

immutable struct ReadOnlyStorage {
	// WARN: The string used may be a temporary
	Path includeDir;
	private void delegate(
		Path path,
		in void delegate(in ReadFileResult!(ubyte[])) @safe @nogc pure nothrow cb,
	) @safe @nogc nothrow withFileBinary_;
	private void delegate(
		Path,
		in void delegate(in ReadFileResult!SafeCStr) @safe @nogc pure nothrow cb,
	) @safe @nogc nothrow withFileText_;
}

immutable struct ReadFileResult(T) {
	immutable struct NotFound {}
	immutable struct Error {}
	mixin Union!(T, NotFound, Error);
}

pure Opt!T asOption(T)(ReadFileResult!T a) =>
	a.match!(Opt!T)(
		(T x) =>
			some(x),
		(ReadFileResult!T.NotFound) =>
			none!SafeCStr,
		(ReadFileResult!T.Error) =>
			none!SafeCStr);

T withFileBinary(T)(
	in ReadOnlyStorage storage,
	Path path,
	in T delegate(in ReadFileResult!(ubyte[])) @safe @nogc pure nothrow cb,
) {
	Cell!(Opt!T) res = Cell!(Opt!T)(none!T);
	storage.withFileBinary_(path, (in ReadFileResult!(ubyte[]) content) {
		cellSet!(Opt!T)(res, some(cb(content)));
	});
	return force(cellGet(res));
}

T withFileText(T)(
	in ReadOnlyStorage storage,
	Path path,
	in T delegate(in ReadFileResult!SafeCStr) @safe @nogc pure nothrow cb,
) {
	static if (is(T == void)) {
		storage.withFileText_(path, (in ReadFileResult!SafeCStr content) {
			cb(content);
		});
	} else {
		Cell!(Opt!T) res = Cell!(Opt!(T))(none!T);
		storage.withFileText_(path, (in ReadFileResult!SafeCStr content) {
			cellSet!(Opt!T)(res, some(cb(content)));
		});
		return force(cellGet(res));
	}
}
