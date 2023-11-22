module util.storage;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc, freeElements, verifyOwns;
import util.col.arr : empty;
import util.col.arrBuilder : add, ArrBuilder, finishArr;
import util.col.arrUtil : copyArr, makeArr;
import util.col.mutMap : addToMutMap, getAt_mut, getOrAdd, mayDelete, MutMap, mutMapEachIn;
import util.col.str : SafeCStr, strOfSafeCStr;
import util.opt : force, has, none, Opt, optOrDefault, some;
import util.sym : Sym, sym;
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
	// Store in separate maps depending on success / issue
	MutMap!(Uri, FileContent) successes;
	MutMap!(Uri, ReadFileIssue) issues;

	public:

	ref Alloc alloc() return scope =>
		*allocPtr;
}

FileContent allocateToStorage(ref Storage a, in SafeCStr content) {
	string s = strOfSafeCStr(content);
	return FileContent(makeArr!(immutable ubyte)(a.alloc, s.length + 1, (size_t i) =>
		i == s.length ? ubyte(0) : ubyte(s[i])));
}

@trusted void setFile(scope ref Storage a, Uri uri, ReadFileResult result) {
	mayDelete(a.issues, uri);
	Opt!FileContent oldContent = mayDelete(a.successes, uri);
	if (has(oldContent))
		force(oldContent).free(a.alloc);

	result.match!void(
		(FileContent x) {
			verifyOwns(a.alloc, x.bytes);
			addToMutMap(a.alloc, a.successes, uri, x);
		},
		(ReadFileIssue x) {
			addToMutMap(a.alloc, a.issues, uri, x);
		});
}

bool hasUnknownOrLoadingUris(in Storage a) {
	bool res = false;
	mutMapEachIn!(Uri, ReadFileIssue)(a.issues, (in Uri uri, in ReadFileIssue issue) {
		res = res || issue == ReadFileIssue.unknown || issue == ReadFileIssue.loading;
	});
	return res;
}

Uri[] allStorageUris(ref Alloc alloc, in Storage a) {
	ArrBuilder!Uri res;
	mutMapEachIn!(Uri, FileContent)(a.successes, (in Uri uri, in FileContent _) {
		add(alloc, res, uri);
	});
	mutMapEachIn!(Uri, ReadFileIssue)(a.issues, (in Uri uri, in ReadFileIssue _) {
		add(alloc, res, uri);
	});
	return finishArr(alloc, res);
}

Uri[] allKnownGoodUris(ref Alloc alloc, in Storage a, in bool delegate(Uri) @safe @nogc pure nothrow filter) {
	ArrBuilder!Uri res;
	mutMapEachIn!(Uri, FileContent)(a.successes, (in Uri uri, in FileContent _) {
		if (filter(uri))
			add(alloc, res, uri);
	});
	return finishArr(alloc, res);
}

Uri[] allUrisWithIssue(ref Alloc alloc, in Storage a, ReadFileIssue issue) {
	ArrBuilder!Uri res;
	mutMapEachIn!(Uri, ReadFileIssue)(a.issues, (in Uri uri, in ReadFileIssue x) {
		if (x == issue)
			add(alloc, res, uri);
	});
	return finishArr(alloc, res);
}

Opt!FileContent getFileNoMarkUnknown(ref Alloc alloc, in Storage a, Uri uri) {
	Opt!FileContent res = getAt_mut(a.successes, uri);
	return has(res) ? some(copyFileContent(alloc, force(res))) : none!FileContent;
}

T withFileNoMarkUnknown(T)(in Storage a, Uri uri, in T delegate(in ReadFileResult) @safe @nogc pure nothrow cb) {
	Opt!FileContent res = getAt_mut(a.successes, uri);
	return cb(has(res)
		? ReadFileResult(force(res))
		: () {
			return ReadFileResult(optOrDefault!ReadFileIssue(getAt_mut(a.issues, uri), () => ReadFileIssue.unknown));
		}());
}

// Storage is mutable, so file content can only be given out temporarily.
T withFile(T)(
	scope ref Storage a,
	Uri uri,
	in T delegate(in ReadFileResult) @safe @nogc pure nothrow cb,
) {
	Opt!FileContent res = getAt_mut(a.successes, uri);
	return cb(has(res)
		? ReadFileResult(force(res))
		: ReadFileResult(getOrAdd!(Uri, ReadFileIssue)(a.alloc, a.issues, uri, () => ReadFileIssue.unknown)));
}

private enum ReadFileIssue_ { notFound, unknown, loading, error }
alias ReadFileIssue = immutable ReadFileIssue_;

ReadFileIssue readFileIssueOfSym(Sym a) {
	final switch (a.value) {
		case sym!"notFound".value:
			return ReadFileIssue.notFound;
		case sym!"unknown".value:
			return ReadFileIssue.unknown;
		case sym!"loading".value:
			return ReadFileIssue.loading;
		case sym!"error".value:
			return ReadFileIssue.error;
	}
}

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
		freeElements(alloc, bytes);
	}
}

immutable(ubyte[]) asBytes(return scope FileContent a) =>
	a.bytes[0 .. $ - 1];

@trusted SafeCStr asSafeCStr(return scope FileContent a) =>
	SafeCStr(cast(immutable char*) a.bytes.ptr);

string asString(return scope FileContent a) =>
	cast(string) asBytes(a);

private FileContent copyFileContent(ref Alloc alloc, in FileContent a) =>
	FileContent(copyArr(alloc, a.bytes));
