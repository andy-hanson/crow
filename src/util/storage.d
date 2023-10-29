module util.storage;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc, freeT, verifyOwns;
import util.col.arr : empty;
import util.col.arrBuilder : add, ArrBuilder, finishArr;
import util.col.arrUtil : arrLiteral, copyArr, makeArr;
import util.col.mutArr : mutArrIsEmpty, MutArr, push, removeUnordered, tempAsArr;
import util.col.mutMap : getAt_mut, getOrAddAndDidAdd, insertOrUpdate, MutMap, mutMapEach, ValueAndDidAdd;
import util.col.str : SafeCStr, strOfSafeCStr;
import util.opt : force, has, none, Opt, some;
import util.union_ : Union;
import util.uri : Uri;
import util.util : verify;

struct Storage {
	@safe @nogc pure nothrow:

	this(Alloc* a) {
		allocPtr = a;
	}

	private:
	Alloc* allocPtr;
	// This doesn't store 'Unknown' values since that's redundant
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
	result.matchIn!void(
		(in FileContent x) {
			verifyOwns(a.alloc, x.bytes);
		},
		(in ReadFileIssue x) {
			verify(x != ReadFileIssue.unknown);
		});

	removeUnordered(a.unknownUris, uri);
	setResult(a, uri, result);
}

void deleteFile(scope ref Storage a, Uri uri) {
	removeUnordered(a.unknownUris, uri);
	setResult(a, uri, ReadFileResult(ReadFileIssue.notFound));
}

private void setResult(scope ref Storage a, Uri uri, ReadFileResult result) {
	insertOrUpdate!(Uri, ReadFileResult)(
		a.alloc, a.fileContents, uri,
		() => result,
		(ref const ReadFileResult old) @trusted {
			old.free(a.alloc);
			return result;
		});
}

bool hasUnknownUris(in Storage a) =>
	!mutArrIsEmpty(a.unknownUris);

Uri[] allKnownGoodUris(ref Alloc alloc, in Storage a) {
	ArrBuilder!Uri res;
	mutMapEach!(Uri, ReadFileResult)(a.fileContents, (Uri uri, ref ReadFileResult x) {
		if (x.isA!FileContent)
			add(alloc, res, uri);
	});
	return finishArr(alloc, res);
}

Uri[] allUnknownUris(ref Alloc alloc, in Storage a) =>
	copyArr(alloc, tempAsArr(a.unknownUris));

Opt!FileContent getFileNoMarkUnknown(ref Alloc alloc, in Storage a, Uri uri) {
	Opt!ReadFileResult result = getAt_mut(a.fileContents, uri);
	return has(result) && force(result).isA!FileContent
		? some(copyFileContent(alloc, force(result).as!FileContent))
		: none!FileContent;
}

// Storage is mutable, so file content can only be given out temporarily.
T withFileContent(T)(
	scope ref Storage storage,
	Uri uri,
	in T delegate(in ReadFileResult) @safe @nogc pure nothrow cb,
) {
	ValueAndDidAdd!ReadFileResult res = getOrAddAndDidAdd(storage.alloc, storage.fileContents, uri, () =>
		ReadFileResult(ReadFileIssue.unknown));
	if (res.didAdd)
		push(storage.alloc, storage.unknownUris, uri);
	return cb(res.value);
}

private enum ReadFileIssue_ { notFound, error, unknown }
alias ReadFileIssue = immutable ReadFileIssue_;

immutable struct ReadFileResult {
	@safe @nogc pure nothrow:

	mixin Union!(FileContent, ReadFileIssue);

	@system void free(ref Alloc alloc) {
		if (isA!FileContent)
			as!FileContent.free(alloc);
	}
}

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
