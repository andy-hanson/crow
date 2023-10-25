module util.memoryReadOnlyStorage;

@safe @nogc nothrow: // not pure

import util.col.mutMap : getAt_mut, MutMap;
import util.col.str : SafeCStr;
import util.opt : force, has, Opt;
import util.readOnlyStorage : ReadFileResult, ReadOnlyStorage;
import util.uri : Uri;

T withMemoryReadOnlyStorage(T)(
	Uri includeDir,
	in MutFiles files,
	in T delegate(in ReadOnlyStorage) @safe @nogc nothrow cb,
) {
	scope ReadOnlyStorage storage = ReadOnlyStorage(
		includeDir,
		(
			Uri uri,
			in void delegate(in ReadFileResult!(ubyte[])) @safe @nogc pure nothrow cb,
		) =>
			cb(ReadFileResult!(ubyte[])(ReadFileResult!(ubyte[]).NotFound())),
		(
			Uri uri,
			in void delegate(in ReadFileResult!SafeCStr) @safe @nogc pure nothrow cb,
		) {
			Opt!SafeCStr res = getAt_mut(files, uri);
			return cb(has(res)
				? ReadFileResult!SafeCStr(force(res))
				: ReadFileResult!SafeCStr(ReadFileResult!SafeCStr.NotFound()));
		});
	return cb(storage);
}

alias MutFiles = MutMap!(Uri, SafeCStr);
