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
		scope void delegate(immutable ReadFileResult) @safe @nogc pure nothrow cb,
	) @safe @nogc nothrow withFile;
}

struct ReadFileResult {
	@safe @nogc pure nothrow:

	struct NotFound {}
	struct Error {}

	immutable this(immutable SafeCStr a) { kind = Kind.text; text = a; }
	immutable this(immutable NotFound a) { kind = Kind.notFound; notFound = a; }
	immutable this(immutable Error a) { kind = Kind.error; error = a; }

	private:
	enum Kind { text, notFound, error }
	immutable Kind kind;
	union {
		immutable SafeCStr text;
		immutable NotFound notFound;
		immutable Error error;
	}
}

@trusted pure immutable(T) matchReadFileResult(T)(
	immutable ReadFileResult a,
	scope immutable(T) delegate(immutable SafeCStr) @safe @nogc pure nothrow cbText,
	scope immutable(T) delegate(immutable ReadFileResult.NotFound) @safe @nogc pure nothrow cbNotFound,
	scope immutable(T) delegate(immutable ReadFileResult.Error) @safe @nogc pure nothrow cbError,
) {
	final switch (a.kind) {
		case ReadFileResult.Kind.text:
			return cbText(a.text);
		case ReadFileResult.Kind.notFound:
			return cbNotFound(a.notFound);
		case ReadFileResult.Kind.error:
			return cbError(a.error);
	}
}

pure immutable(Opt!SafeCStr) asOption(immutable ReadFileResult a) {
	return matchReadFileResult!(immutable Opt!SafeCStr)(
		a,
		(immutable SafeCStr x) =>
			some(x),
		(immutable(ReadFileResult.NotFound)) =>
			none!SafeCStr,
		(immutable(ReadFileResult.Error)) =>
			none!SafeCStr);
}

immutable(T) withFile(T)(
	scope ref const ReadOnlyStorage storage,
	immutable Path path,
	immutable SafeCStr extension,
	immutable(T) delegate(immutable ReadFileResult) @safe @nogc pure nothrow cb,
) {
	static if (is(T == void)) {
		storage.withFile(path, extension, (immutable ReadFileResult content) {
			cb(content);
		});
	} else {
		Cell!(immutable Opt!T) res = Cell!(immutable Opt!T)(none!T);
		storage.withFile(path, extension, (immutable ReadFileResult content) {
			cellSet!(immutable Opt!T)(res, some(cb(content)));
		});
		return force(cellGet(res));
	}
}
