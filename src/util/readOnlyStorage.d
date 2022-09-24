module util.readOnlyStorage;

@safe @nogc nothrow: // not pure

import util.cell : Cell, cellGet, cellSet;
import util.opt : force, none, Opt, some;
import util.path : Path;
import util.col.str : SafeCStr;
import util.sym : Sym;

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
	@safe @nogc pure nothrow:

	struct NotFound {}
	struct Error {}

	immutable this(immutable T a) { kind = Kind.content; content = a; }
	immutable this(immutable NotFound a) { kind = Kind.notFound; notFound = a; }
	immutable this(immutable Error a) { kind = Kind.error; error = a; }

	private:
	enum Kind { content, notFound, error }
	immutable Kind kind;
	union {
		immutable T content;
		immutable NotFound notFound;
		immutable Error error;
	}
}

@trusted pure immutable(T) matchReadFileResult(T, Content)(
	immutable ReadFileResult!Content a,
	scope immutable(T) delegate(immutable Content) @safe @nogc pure nothrow cbContent,
	scope immutable(T) delegate(immutable ReadFileResult!Content.NotFound) @safe @nogc pure nothrow cbNotFound,
	scope immutable(T) delegate(immutable ReadFileResult!Content.Error) @safe @nogc pure nothrow cbError,
) {
	final switch (a.kind) {
		case ReadFileResult!Content.Kind.content:
			return cbContent(a.content);
		case ReadFileResult!Content.Kind.notFound:
			return cbNotFound(a.notFound);
		case ReadFileResult!Content.Kind.error:
			return cbError(a.error);
	}
}

pure immutable(Opt!T) asOption(T)(immutable ReadFileResult!T a) =>
	matchReadFileResult!(immutable Opt!T, T)(
		a,
		(immutable SafeCStr x) =>
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
	Cell!(immutable Opt!(immutable T)) res = Cell!(immutable Opt!(immutable T))(none!(immutable T));
	storage.withFileBinary_(path, (immutable ReadFileResult!(ubyte[]) content) {
		cellSet!(immutable Opt!T)(res, some!(immutable T)(cb(content)));
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
		Cell!(immutable Opt!(immutable T)) res = Cell!(immutable Opt!(immutable T))(none!(immutable T));
		storage.withFileText_(path, extension, (immutable ReadFileResult!SafeCStr content) {
			cellSet!(immutable Opt!(immutable T))(res, some!(immutable T)(cb(content)));
		});
		return force(cellGet(res));
	}
}
