module frontend.storage;

@safe @nogc pure nothrow:

import frontend.config : parseConfig;
import frontend.lang : crowConfigBaseName, crowExtension;
import frontend.parse.ast : FileAst;
import frontend.parse.parse : parseFile;
import lib.lsp.lspTypes : TextDocumentContentChangeEvent, TextDocumentPositionParams;
import model.diag : ReadFileDiag;
import model.model : Config;
import util.alloc.alloc : Alloc, AllocAndValue, AllocName, freeAlloc, MetaAlloc, newAlloc, withAlloc, withTempAlloc;
import util.col.arr : empty;
import util.col.arrBuilder : add, ArrBuilder, finishArr;
import util.col.arrUtil : contains;
import util.col.mutMap : getOrAdd, mayDelete, mustAddToMutMap, MutMap, mutMapEachIn;
import util.col.str : copyToSafeCStr, SafeCStr, safeCStrSize, strOfSafeCStr;
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
import util.opt : ConstOpt, force, has, MutOpt;
import util.perf : Perf;
import util.ptr : castNonScope_ref;
import util.sourceRange : jsonOfRange, lineAndCharacterRange, Pos, Range, UriAndPos, UriAndRange;
import util.sym : AllSymbols;
import util.union_ : Union;
import util.uri : AllUris, baseName, getExtension, Uri, stringOfUri;
import util.writer : withWriter, Writer;

struct Storage {
	@safe @nogc pure nothrow:

	this(MetaAlloc* a, AllSymbols* as, AllUris* au) {
		metaAlloc = a;
		allSymbols = as;
		allUris = au;
		mapAlloc_ = newAlloc(AllocName.storage, metaAlloc);
	}

	private:
	MetaAlloc* metaAlloc;
	AllSymbols* allSymbols;
	AllUris* allUris;
	Alloc mapAlloc_;
	// Store in separate maps depending on success / diag
	MutMap!(Uri, AllocAndValue!FileInfo) successes;
	MutMap!(Uri, ReadFileDiag) diags;

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
	mixin Union!(FileAst*, Config*, None);
}

void setFile(scope ref Perf perf, ref Storage a, Uri uri, in ReadFileResult result) {
	result.matchIn!void(
		(in FileContent x) {
			setFile(perf, a, uri, asString(x));
		},
		(in ReadFileDiag x) {
			setFile(perf, a, uri, x);
		});
}
void setFile(scope ref Perf perf, ref Storage a, Uri uri, in string content) {
	prepareSetFile(a, uri);
	mustAddToMutMap(a.mapAlloc, a.successes, uri, getFileInfo(perf, a, uri, content));
}
void setFile(scope ref Perf perf, ref Storage a, Uri uri, ReadFileDiag diag) {
	prepareSetFile(a, uri);
	mustAddToMutMap(a.mapAlloc, a.diags, uri, diag);
}
private @trusted void prepareSetFile(ref Storage a, Uri uri) {
	mayDelete(a.diags, uri);
	MutOpt!(AllocAndValue!FileInfo) oldContent = mayDelete(a.successes, uri);
	if (has(oldContent))
		freeAlloc(force(oldContent).alloc);
}

void changeFile(scope ref Perf perf, ref Storage a, Uri uri, in TextDocumentContentChangeEvent[] changes) {
	foreach (TextDocumentContentChangeEvent change; changes)
		changeFile(perf, a, uri, change);
}

void changeFile(scope ref Perf perf, ref Storage a, Uri uri, in TextDocumentContentChangeEvent change) {
	FileInfo info = fileOrDiag(a, uri).as!FileInfo;
	withTempAlloc(AllocName.storageChangeFile, a.metaAlloc, (ref Alloc alloc) {
		SafeCStr newContent = applyChange(alloc, asString(info.content), info.lineAndColumnGetter, change);
		// TODO:PERF This means an unnecessary copy in 'setFile'.
		// Would be better to modify the array in place and force re-parse.
		setFile(perf, a, uri, strOfSafeCStr(newContent));
	});
}

private AllocAndValue!FileInfo getFileInfo(scope ref Perf perf, ref Storage storage, Uri uri, in string input) =>
	withAlloc!FileInfo(AllocName.storageFileInfo, storage.metaAlloc, (ref Alloc alloc) {
		SafeCStr content = copyToSafeCStr(alloc, input);
		return FileInfo(
			FileContent(content),
			lineAndColumnGetterForText(alloc, content),
			parseContent(perf, alloc, *storage.allSymbols, *storage.allUris, uri, content));
	});

private ParseResult parseContent(
	scope ref Perf perf,
	ref Alloc alloc,
	scope ref AllSymbols allSymbols,
	scope ref AllUris allUris,
	Uri uri,
	in SafeCStr content,
) {
	final switch (fileType(allUris, uri)) {
		case FileType.crow:
			return ParseResult(parseFile(perf, alloc, allSymbols, allUris, content));
		case FileType.crowConfig:
			return ParseResult(allocate(alloc, parseConfig(alloc, allSymbols, allUris, uri, content)));
		case FileType.other:
			return ParseResult(ParseResult.None());
	}
}

enum FileType {
	crow,
	crowConfig,
	other,
}

FileType fileType(scope ref AllUris allUris, Uri uri) =>
	getExtension(allUris, uri) == crowExtension
		? FileType.crow
		: baseName(allUris, uri) == crowConfigBaseName
		? FileType.crowConfig
		: FileType.other;

enum FilesState {
	hasUnknown,
	hasLoading,
	allLoaded,
}

FilesState filesState(in Storage a) {
	FilesState res = FilesState.allLoaded;
	mutMapEachIn!(Uri, ReadFileDiag)(a.diags, (in Uri uri, in ReadFileDiag x) {
		final switch (x) {
			case ReadFileDiag.unknown:
				res = FilesState.hasUnknown;
				break;
			case ReadFileDiag.loading:
				if (res != FilesState.hasUnknown) res = FilesState.hasLoading;
				break;
			case ReadFileDiag.notFound:
			case ReadFileDiag.error:
				break;
		}
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

Uri[] allKnownGoodCrowUris(ref Alloc alloc, scope ref Storage a) {
	ArrBuilder!Uri res;
	mutMapEachIn!(Uri, AllocAndValue!FileInfo)(a.successes, (in Uri uri, in AllocAndValue!FileInfo _) {
		if (getExtension(*a.allUris, uri) == crowExtension)
			add(alloc, res, uri);
	});
	return finishArr(alloc, res);
}

Uri[] allUrisWithFileDiag(ref Alloc alloc, in Storage a, in ReadFileDiag[] searchDiags) {
	ArrBuilder!Uri res;
	mutMapEachIn!(Uri, ReadFileDiag)(a.diags, (in Uri uri, in ReadFileDiag x) {
		if (contains(searchDiags, x))
			add(alloc, res, uri);
	});
	return finishArr(alloc, res);
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

void markUnknownIfNotExist(scope ref Storage a, Uri uri) {
	cast(void) fileOrDiag(a, uri);
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
		assert(!empty(bytes) && bytes[$ - 1] == '\0');
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

string asString(return scope FileContent a) =>
	cast(string) asBytes(a);

const struct LineAndColumnGetters {
	@safe @nogc pure nothrow:

	private const Storage* storage;

	LineAndColumnGetter opIndex(Uri uri) scope {
		ConstOpt!(AllocAndValue!FileInfo) res = storage.successes[uri];
		return has(res) ? force(res).value.lineAndColumnGetter : lineAndColumnGetterForEmptyFile;
	}

	Pos opIndex(in TextDocumentPositionParams x) scope =>
		this[x.textDocument.uri][x.position];
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

private SafeCStr applyChange(
	ref Alloc alloc,
	in string input,
	in LineAndColumnGetter lc,
	in TextDocumentContentChangeEvent event,
) =>
	withWriter(alloc, (scope ref Writer writer) {
		if (has(event.range)) {
			Range range = lc[force(event.range)];
			writer ~= input[0 .. range.start];
			writer ~= event.text;
			writer ~= input[range.end .. $];
		} else
			writer ~= event.text;
	});