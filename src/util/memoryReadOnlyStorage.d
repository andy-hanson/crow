module util.memoryReadOnlyStorage;

@safe @nogc nothrow: // not pure

import frontend.lang : crowExtension;
import util.col.mutMap : getAt_mut, MutMap;
import util.col.str : SafeCStr;
import util.opt : force, has, none, Opt;
import util.path : Path;
import util.readOnlyStorage : ReadFileResult, ReadOnlyStorage;
import util.sym : Sym;

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
			Sym extension,
			in void delegate(in ReadFileResult!SafeCStr) @safe @nogc pure nothrow cb,
		) {
			Opt!SafeCStr res = extension == crowExtension
				? getAt_mut(files, path)
				: none!SafeCStr;
			return cb(has(res)
				? ReadFileResult!SafeCStr(force(res))
				: ReadFileResult!SafeCStr(ReadFileResult!SafeCStr.NotFound()));
		});
	return cb(storage);
}

alias MutFiles = MutMap!(Path, SafeCStr);
