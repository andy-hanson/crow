module util.memoryReadOnlyStorage;

@safe @nogc nothrow: // not pure

import util.col.mutMap : getAt_mut, MutMap;
import util.col.str : SafeCStr;
import util.opt : force, has, Opt;
import util.path : Path;
import util.readOnlyStorage : ReadFileResult, ReadOnlyStorage;

T withMemoryReadOnlyStorage(T)(
	Path includeDir,
	in MutFiles files,
	in T delegate(in ReadOnlyStorage) @safe @nogc nothrow cb,
) {
	scope ReadOnlyStorage storage = ReadOnlyStorage(
		includeDir,
		(
			Path path,
			in void delegate(in ReadFileResult!(ubyte[])) @safe @nogc pure nothrow cb,
		) =>
			cb(ReadFileResult!(ubyte[])(ReadFileResult!(ubyte[]).NotFound())),
		(
			Path path,
			in void delegate(in ReadFileResult!SafeCStr) @safe @nogc pure nothrow cb,
		) {
			Opt!SafeCStr res = getAt_mut(files, path);
			return cb(has(res)
				? ReadFileResult!SafeCStr(force(res))
				: ReadFileResult!SafeCStr(ReadFileResult!SafeCStr.NotFound()));
		});
	return cb(storage);
}

alias MutFiles = MutMap!(Path, SafeCStr);
