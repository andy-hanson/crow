module util.storage;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc, AllocAndValue, freeAlloc, MetaAlloc, newAlloc, withAlloc;
import util.col.arr : empty;
import util.col.arrBuilder : add, ArrBuilder, finishArr;
import util.col.arrUtil : copyArr;
import util.col.mutMap : addToMutMap, getAt_mut, getOrAdd, mayDelete, MutMap, mutMapEachIn;
import util.col.str : SafeCStr, safeCStrSize;
import util.opt : ConstOpt, force, has, none, MutOpt, Opt, optOrDefault, some;
import util.ptr : castNonScope,castNonScope_ref;
import util.sym : Sym, sym;
import util.union_ : Union;
import util.uri : Uri;
import util.util : verify;

struct Storage {
	@safe @nogc pure nothrow:

	this(MetaAlloc* a) {
		metaAlloc = a;
		mapAlloc_ = newAlloc(a);
	}

	private:
	MetaAlloc* metaAlloc;
	Alloc mapAlloc_;
	// Store in separate maps depending on success / issue
	MutMap!(Uri, AllocAndValue!FileInfo) successes;
	MutMap!(Uri, ReadFileIssue) issues;

	public:

	ref Alloc mapAlloc() scope =>
		castNonScope_ref(mapAlloc_);
}

private struct FileInfo {
	FileContent content;
	// TODO:
	// LineAndColumnGetter lineAndColumnGetter;
	// FileAst ast;
}

@trusted void setFile(scope ref Storage a, Uri uri, in ReadFileResult result) {
	mayDelete(a.issues, uri);
	MutOpt!(AllocAndValue!FileInfo) oldContent = mayDelete(a.successes, uri);
	if (has(oldContent))
		freeAlloc(force(oldContent).alloc);

	result.matchIn!void(
		(in FileContent x) @safe {
			addToMutMap(a.mapAlloc, a.successes, uri, getFileInfo(castNonScope(a.metaAlloc), x));
		},
		(in ReadFileIssue x) {
			addToMutMap(a.mapAlloc, a.issues, uri, x);
		});
}

private AllocAndValue!FileInfo getFileInfo(MetaAlloc* metaAlloc, in FileContent content) =>
	withAlloc(metaAlloc, (ref Alloc alloc) =>
		FileInfo(copyFileContent(alloc, content)));

bool hasUnknownOrLoadingUris(in Storage a) {
	bool res = false;
	mutMapEachIn!(Uri, ReadFileIssue)(a.issues, (in Uri uri, in ReadFileIssue issue) {
		res = res || issue == ReadFileIssue.unknown || issue == ReadFileIssue.loading;
	});
	return res;
}

Uri[] allStorageUris(ref Alloc alloc, in Storage a) {
	ArrBuilder!Uri res;
	mutMapEachIn!(Uri, AllocAndValue!FileInfo)(a.successes, (in Uri uri, in AllocAndValue!FileInfo _) {
		add(alloc, res, uri);
	});
	mutMapEachIn!(Uri, ReadFileIssue)(a.issues, (in Uri uri, in ReadFileIssue _) {
		add(alloc, res, uri);
	});
	return finishArr(alloc, res);
}

Uri[] allKnownGoodUris(ref Alloc alloc, in Storage a, in bool delegate(Uri) @safe @nogc pure nothrow filter) {
	ArrBuilder!Uri res;
	mutMapEachIn!(Uri, AllocAndValue!FileInfo)(a.successes, (in Uri uri, in AllocAndValue!FileInfo _) {
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

Opt!FileContent getFileNoMarkUnknown(return in Storage a, Uri uri) {
	ConstOpt!(AllocAndValue!FileInfo) res = a.successes[uri];
	return has(res) ? some(force(res).value.content) : none!FileContent;
}

T withFileNoMarkUnknown(T)(in Storage a, Uri uri, in T delegate(in ReadFileResult) @safe @nogc pure nothrow cb) {
	scope Opt!FileContent res = getFileNoMarkUnknown(castNonScope_ref(a), uri);
	return cb(has(res)
		? ReadFileResult(force(res))
		: ReadFileResult(optOrDefault!ReadFileIssue(getAt_mut(a.issues, uri), () => ReadFileIssue.unknown)));
}

// Storage is mutable, so file content can only be given out temporarily.
T withFile(T)(
	scope ref Storage a,
	Uri uri,
	in T delegate(in ReadFileResult) @safe @nogc pure nothrow cb,
) {
	ConstOpt!(AllocAndValue!FileInfo) res = a.successes[uri];
	return cb(has(res)
		? ReadFileResult(force(res).value.content)
		: ReadFileResult(getOrAdd!(Uri, ReadFileIssue)(a.mapAlloc, a.issues, uri, () => ReadFileIssue.unknown)));
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
	mixin Union!(FileContent, ReadFileIssue);
}

immutable struct FileContent {
	@safe @nogc pure nothrow:

	this(immutable ubyte[] a) {
		bytes = a;
		verify(!empty(bytes) && bytes[$ - 1] == '\0');
	}
	@trusted this(SafeCStr a) {
		static assert(char.sizeof == ubyte.sizeof);
		this((cast(immutable ubyte*) a.ptr)[0 .. safeCStrSize(a) + 1]);
	}

	// This ends with '\0'
	private ubyte[] bytes;
}

immutable(ubyte[]) asBytes(return scope FileContent a) =>
	a.bytes[0 .. $ - 1];

@trusted SafeCStr asSafeCStr(return scope FileContent a) =>
	SafeCStr(cast(immutable char*) a.bytes.ptr);

string asString(return scope FileContent a) =>
	cast(string) asBytes(a);

private FileContent copyFileContent(ref Alloc alloc, in FileContent a) =>
	FileContent(copyArr(alloc, a.bytes));
