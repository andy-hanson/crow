module frontend.storage;

@safe @nogc pure nothrow:

import frontend.config : parseConfig, ParsedConfig;
import frontend.lang : crowConfigBaseName, crowExtension;
import frontend.parse.ast : FileAst;
import frontend.parse.parse : parseFile;
import model.diag : ReadFileDiag;
import util.alloc.alloc : Alloc, AllocAndValue, freeAlloc, MetaAlloc, newAlloc, withAlloc;
import util.col.arr : empty;
import util.col.arrBuilder : add, ArrBuilder, finishArr;
import util.col.arrUtil : copyArr;
import util.col.mutMap : addToMutMap, getOrAdd, mayDelete, MutMap, mutMapEachIn;
import util.col.str : SafeCStr, safeCStrSize;
import util.json : field, Json, jsonObject;
import util.lineAndColumnGetter :
	LineAndCharacter,
	lineAndCharacterAtPos,
	LineAndCharacterRange,
	LineAndColumn,
	lineAndColumnAtPos,
	LineAndColumnGetter,
	lineAndColumnGetterForEmptyFile,
	lineAndColumnGetterForText,
	LineAndColumnRange,
	lineAndColumnRange,
	PosKind,
	toLineAndCharacter,
	UriLineAndCharacter,
	UriLineAndColumn;
import util.memory : allocate;
import util.opt : ConstOpt, force, has, none, MutOpt, Opt, some;
import util.perf : Perf;
import util.ptr : castNonScope_ref;
import util.sourceRange : jsonOfRange, lineAndCharacterRange, Pos, UriAndPos, UriAndRange;
import util.sym : AllSymbols;
import util.union_ : Union;
import util.uri : AllUris, baseName, getExtension, parentOrEmpty, Uri, stringOfUri;
import util.util : verify;

struct Storage {
	@safe @nogc pure nothrow:

	this(MetaAlloc* a, AllSymbols* as, AllUris* au) {
		metaAlloc = a;
		allSymbols = as;
		allUris = au;
		mapAlloc_ = newAlloc(metaAlloc);
	}

	private:
	MetaAlloc* metaAlloc;
	AllSymbols* allSymbols;
	AllUris* allUris;
	Alloc mapAlloc_;
	// Store in separate maps depending on success / diag
	MutMap!(Uri, AllocAndValue!FileInfo) successes;
	MutMap!(Uri, ReadFileDiag) diags;

	public:

	ref Alloc mapAlloc() scope =>
		castNonScope_ref(mapAlloc_);
}

private immutable struct FileInfo {
	FileContent content;
	LineAndColumnGetter lineAndColumnGetter;
	ParseResult parsed;
}

immutable struct ParseResult {
	immutable struct None {}
	mixin Union!(FileAst*, ParsedConfig*, None);
}

@trusted void setFile(scope ref Perf perf, ref Storage a, Uri uri, in ReadFileResult result) {
	mayDelete(a.diags, uri);
	MutOpt!(AllocAndValue!FileInfo) oldContent = mayDelete(a.successes, uri);
	if (has(oldContent))
		freeAlloc(force(oldContent).alloc);

	result.matchIn!void(
		(in FileContent x) @safe {
			addToMutMap(a.mapAlloc, a.successes, uri, getFileInfo(perf, a, uri, x));
		},
		(in ReadFileDiag x) {
			addToMutMap(a.mapAlloc, a.diags, uri, x);
		});
}

private AllocAndValue!FileInfo getFileInfo(scope ref Perf perf, ref Storage storage, Uri uri, in FileContent content) =>
	withAlloc!FileInfo(storage.metaAlloc, (ref Alloc alloc) =>
		FileInfo(
			copyFileContent(alloc, content),
			lineAndColumnGetterForText(alloc, asSafeCStr(content)),
			parseContent(perf, alloc, *storage.allSymbols, *storage.allUris, uri, asSafeCStr(content))));

private ParseResult parseContent(
	scope ref Perf perf,
	ref Alloc alloc,
	scope ref AllSymbols allSymbols,
	scope ref AllUris allUris,
	Uri uri,
	in SafeCStr content,
) =>
	getExtension(allUris, uri) == crowExtension
		? ParseResult(parseFile(perf, alloc, allSymbols, allUris, content))
		: baseName(allUris, uri) == crowConfigBaseName
		? ParseResult(allocate(alloc, parseConfig(alloc, allSymbols, allUris, parentOrEmpty(allUris, uri), content)))
		: ParseResult(ParseResult.None());

bool hasUnknownOrLoadingUris(in Storage a) {
	bool res = false;
	mutMapEachIn!(Uri, ReadFileDiag)(a.diags, (in Uri uri, in ReadFileDiag x) {
		res = res || x == ReadFileDiag.unknown || x == ReadFileDiag.loading;
	});
	return res;
}

Uri[] allStorageUris(ref Alloc alloc, in Storage a) {
	ArrBuilder!Uri res;
	mutMapEachIn!(Uri, AllocAndValue!FileInfo)(a.successes, (in Uri uri, in AllocAndValue!FileInfo _) {
		add(alloc, res, uri);
	});
	mutMapEachIn!(Uri, ReadFileDiag)(a.diags, (in Uri uri, in ReadFileDiag _) {
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

Uri[] allUrisWithFileDiag(ref Alloc alloc, in Storage a, ReadFileDiag diag) {
	ArrBuilder!Uri res;
	mutMapEachIn!(Uri, ReadFileDiag)(a.diags, (in Uri uri, in ReadFileDiag x) {
		if (x == diag)
			add(alloc, res, uri);
	});
	return finishArr(alloc, res);
}

Opt!FileContent getFileNoMarkUnknown(return in Storage a, Uri uri) {
	ConstOpt!(AllocAndValue!FileInfo) res = a.successes[uri];
	return has(res) ? some(force(res).value.content) : none!FileContent;
}

private immutable struct FileInfoOrDiag {
	mixin Union!(FileInfo, ReadFileDiag);
}

private FileInfoOrDiag fileOrDiag(scope ref Storage a, Uri uri) {
	ConstOpt!(AllocAndValue!FileInfo) res = a.successes[uri];
	return has(res)
		? FileInfoOrDiag(force(res).value)
		: FileInfoOrDiag(getOrAdd!(Uri, ReadFileDiag)(a.mapAlloc, a.diags, uri, () => ReadFileDiag.unknown));
}

private immutable struct ParsedOrDiag {
	mixin Union!(ParseResult, ReadFileDiag);
}

ParsedOrDiag getParsedOrDiag(ref Storage a, Uri uri) =>
	fileOrDiag(a, uri).match!ParsedOrDiag(
		(FileInfo x) => ParsedOrDiag(x.parsed),
		(ReadFileDiag x) => ParsedOrDiag(x));

// Storage is mutable, so file content can only be given out temporarily.
ReadFileResult getFileContentOrDiag(ref Storage a, Uri uri) =>
	fileOrDiag(a, uri).match!ReadFileResult(
		(FileInfo x) => ReadFileResult(x.content),
		(ReadFileDiag x) => ReadFileResult(x));

immutable struct ReadFileResult {
	mixin Union!(FileContent, ReadFileDiag);
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

const struct LineAndColumnGetters {
	@safe @nogc pure nothrow:

	private const Storage* storage;

	LineAndColumnGetter opIndex(Uri uri) scope {
		ConstOpt!(AllocAndValue!FileInfo) res = storage.successes[uri];
		return has(res) ? force(res).value.lineAndColumnGetter : lineAndColumnGetterForEmptyFile;
	}

	Pos opIndex(in UriLineAndCharacter x) scope =>
		this[x.uri][x.lineAndCharacter];
}

UriLineAndCharacter toLineAndCharacter(in LineAndColumnGetters a, in UriLineAndColumn x) =>
	UriLineAndCharacter(x.uri, toLineAndCharacter(a[x.uri], x.lineAndColumn));

LineAndColumn lineAndColumnAtPos(in LineAndColumnGetters a, in UriAndPos pos, PosKind kind) =>
	lineAndColumnAtPos(a[pos.uri], pos.pos, kind);

LineAndCharacter lineAndCharacterAtPos(in LineAndColumnGetters a, in UriAndPos pos, PosKind kind) =>
	lineAndCharacterAtPos(a[pos.uri], pos.pos, kind);

LineAndCharacterRange lineAndCharacterRange(in LineAndColumnGetters a, in UriAndRange range) =>
	lineAndCharacterRange(a[range.uri], range.range);

LineAndColumnRange lineAndColumnRange(in LineAndColumnGetters a, in UriAndRange range) =>
	lineAndColumnRange(a[range.uri], range.range);

Json jsonOfUriAndRange(ref Alloc alloc, in AllUris allUris, in LineAndColumnGetters lcg, UriAndRange a) =>
	jsonObject(alloc, [
		field!"uri"(stringOfUri(alloc, allUris, a.uri)),
		field!"range"(jsonOfRange(alloc, lcg, a))]);

Json jsonOfRange(ref Alloc alloc, in LineAndColumnGetters lcg, in UriAndRange a) =>
	jsonOfRange(alloc, lcg[a.uri], a.range);
