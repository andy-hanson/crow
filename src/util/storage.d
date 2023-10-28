module util.storage;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc, freeT, verifyOwns;
import util.col.arr : empty;
import util.col.arrUtil : arrLiteral, copyArr, makeArr;
import util.col.mutArr : mutArrIsEmpty, MutArr, push, removeUnordered;
import util.col.mutMap : getAt_mut, getOrAddAndDidAdd, insertOrUpdate, MutMap, setInMap, ValueAndDidAdd;
import util.col.str : SafeCStr, strOfSafeCStr;
import util.opt : force, has, none, Opt, some;
import util.union_ : Union;
import util.uri : Uri;
import util.util : verify, verifyFail;

struct Storage {
	@safe @nogc pure nothrow:

	this(Alloc* a) {
		allocPtr = a;
	}

	private:
	Alloc* allocPtr;
	MutMap!(Uri, ReadFileResult) fileContents;
	// Set of keys in 'fileContents' for which the value is Unknown
	MutArr!Uri unknownUris;

	public:

	ref Alloc alloc() return scope =>
		*allocPtr;
}

FileContent allocateToStorage(ref Storage a, in SafeCStr content) {
	string s = strOfSafeCStr(content);
	return FileContent(makeArr!(immutable ubyte)(a.alloc, s.length + 1, (size_t i) =>
		i == s.length ? ubyte(0) : ubyte(s[i])));
}

void setFile(scope ref Storage a, Uri uri, ReadFileResult result) {
	result.match!void(
		(FileContent x) {
			verifyOwns(a.alloc, x.bytes);
		},
		(ReadFileResult.NotFound) {},
		(ReadFileResult.Error) {},
		(ReadFileResult.Unknown) {
			verifyFail();
		});
	deleteFile(a, uri);
	setInMap(a.alloc, a.fileContents, uri, result);
}

void deleteFile(scope ref Storage a, Uri uri) {
	removeUnordered(a.unknownUris, uri);
	insertOrUpdate!(Uri, ReadFileResult)(
		a.alloc, a.fileContents, uri,
		() => ReadFileResult(ReadFileResult.NotFound()),
		(ref const ReadFileResult old) @trusted {
			old.free(a.alloc);
			return ReadFileResult(ReadFileResult.NotFound());
		});
}

bool hasUnknownUris(in Storage a) =>
	!mutArrIsEmpty(a.unknownUris);

// Written this way to avoid GC
Opt!Uri getOneUnknownUri(in Storage a) =>
	mutArrIsEmpty(a.unknownUris)
		? none!Uri
		: some(a.unknownUris[0]);

Opt!FileContent getFileNoMarkUnknown(ref Alloc alloc, in Storage a, Uri uri) {
	Opt!ReadFileResult result = getAt_mut(a.fileContents, uri);
	Opt!FileContent content = has(result) ? asOption(force(result)) : none!FileContent;
	return has(content)
		? some(copyFileContent(alloc, force(content)))
		: none!FileContent;
}

// Storage is mutable, so file content can only be given out temporarily.
T withFileContent(T)(
	scope ref Storage storage,
	Uri uri,
	in T delegate(in ReadFileResult) @safe @nogc pure nothrow cb,
) {
	ValueAndDidAdd!ReadFileResult res = getOrAddAndDidAdd(storage.alloc, storage.fileContents, uri, () =>
		ReadFileResult(ReadFileResult.Unknown()));
	if (res.didAdd)
		push(storage.alloc, storage.unknownUris, uri);
	return cb(res.value);
}

immutable struct ReadFileResult {
	@safe @nogc pure nothrow:

	immutable struct NotFound {}
	immutable struct Error {}
	immutable struct Unknown {}
	mixin Union!(FileContent, NotFound, Error, Unknown);

	@system void free(ref Alloc alloc) {
		if (isA!FileContent)
			as!FileContent.free(alloc);
	}
}

Opt!FileContent asOption(ReadFileResult a) =>
	a.isA!FileContent ? some(a.as!FileContent) : none!FileContent;

immutable struct FileContent {
	@safe @nogc pure nothrow:

	this(immutable ubyte[] b) {
		bytes = b;
		verify(!empty(bytes) && bytes[$ - 1] == '\0');
	}

	// This ends with '\0'
	private ubyte[] bytes;

	@system void free(ref Alloc alloc) {
		freeT(alloc, bytes.ptr, bytes.length);
	}
}

immutable(ubyte[]) asBytes(return scope FileContent a) =>
	a.bytes[0 .. $ - 1];

@trusted SafeCStr asSafeCStr(return scope FileContent a) =>
	SafeCStr(cast(immutable char*) a.bytes.ptr);

string asString(return scope FileContent a) =>
	cast(string) asBytes(a);

// Due to a compiler bug, isn't emitting this function, so force it with extern
FileContent emptyFileContent(ref Alloc alloc) {
	return FileContent(arrLiteral!(immutable ubyte)(alloc, [0]));
	/*
	TODO: somehow this causes linker errors
	immutable ubyte[] bytes = [0];
	return FileContent(bytes);
	*/
}

FileContent copyFileContent(ref Alloc alloc, in FileContent a) =>
	FileContent(copyArr(alloc, a.bytes));
