module frontend.storage;

@safe @nogc pure nothrow:

import frontend.config : parseConfig;
import frontend.lang : crowConfigBaseName, crowExtension;
import frontend.parse.parse : parseFile;
import lib.lsp.lspTypes : TextDocumentContentChangeEvent, TextDocumentPositionParams;
import model.ast : FileAst;
import model.diag : ReadFileDiag;
import model.model : Config;
import util.alloc.alloc :
	Alloc,
	AllocAndValue,
	AllocKind,
	freeAlloc,
	MetaAlloc,
	newAlloc,
	withAlloc,
	withTempAlloc;
import util.col.array : append, contains, isEmpty;
import util.col.arrayBuilder : add, ArrayBuilder, finish;
import util.col.mutMap : getOrAdd, keys, mayDelete, mustAdd, MutMap, values;
import util.memory : allocate;
import util.opt : ConstOpt, force, has, MutOpt;
import util.perf : Perf;
import util.sourceRange :
	LineAndCharacterGetter,
	LineAndColumnGetter,
	lineAndColumnGetterForText,
	Pos,
	PosKind,
	Range,
	UriAndPos,
	UriAndRange,
	UriAndLineAndCharacterRange,
	UriLineAndColumn,
	UriLineAndColumnRange;
import util.string : CString, cStringSize, stringOfCString;
import util.symbol : AllSymbols;
import util.union_ : Union;
import util.uri : AllUris, baseName, getExtension, Uri;
import util.writer : withWriter, Writer;

struct Storage {
	@safe @nogc pure nothrow:

	this(MetaAlloc* a, AllSymbols* as, AllUris* au) {
		metaAlloc = a;
		allSymbolsPtr = as;
		allUrisPtr = au;
		mapAlloc_ = newAlloc(AllocKind.storage, metaAlloc);
	}

	private:
	MetaAlloc* metaAlloc;
	AllSymbols* allSymbolsPtr;
	AllUris* allUrisPtr;
	Alloc* mapAlloc_;
	// Store in separate maps depending on success / diag
	MutMap!(Uri, AllocAndValue!FileInfo) successes;
	MutMap!(Uri, ReadFileDiag) diags;

	ref inout(AllSymbols) allSymbols() return scope inout =>
		*allSymbolsPtr;
	ref inout(AllUris) allUris() return scope inout =>
		*allUrisPtr;
	ref inout(Alloc) mapAlloc() return scope inout =>
		*mapAlloc_;
}

private immutable struct FileInfo {
	@safe @nogc pure nothrow:

	FileContent content;
	LineAndColumnGetter lineAndColumnGetter;
	ParseResult parsed;

	LineAndCharacterGetter lineAndCharacterGetter() =>
		lineAndColumnGetter.lineAndCharacterGetter;
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
@trusted void setFile(scope ref Perf perf, ref Storage a, Uri uri, in string content) {
	setFile(perf, a, uri, cast(ubyte[]) content);
}
void setFile(scope ref Perf perf, ref Storage a, Uri uri, in ubyte[] content) {
	prepareSetFile(a, uri);
	mustAdd(a.mapAlloc, a.successes, uri, getFileInfo(perf, a, uri, content));
}
void setFile(scope ref Perf perf, ref Storage a, Uri uri, ReadFileDiag diag) {
	prepareSetFile(a, uri);
	mustAdd(a.mapAlloc, a.diags, uri, diag);
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
	withTempAlloc(a.metaAlloc, (ref Alloc alloc) {
		CString newContent = applyChange(alloc, asString(info.content), info.lineAndCharacterGetter, change);
		// TODO:PERF This means an unnecessary copy in 'setFile'.
		// Would be better to modify the array in place and force re-parse.
		setFile(perf, a, uri, stringOfCString(newContent));
	});
}

private AllocAndValue!FileInfo getFileInfo(scope ref Perf perf, ref Storage storage, Uri uri, in ubyte[] input) =>
	withAlloc!FileInfo(AllocKind.storageFileInfo, storage.metaAlloc, (ref Alloc alloc) @trusted {
		FileContent content = FileContent(cast(immutable) append(alloc, input, cast(ubyte) '\0'));
		return FileInfo(
			content,
			// TODO: only needed for CrowFile or CrowConfig
			lineAndColumnGetterForText(alloc, asCString(content)),
			parseContent(perf, alloc, storage.allSymbols, storage.allUris, uri, asCString(content)));
	});

private ParseResult parseContent(
	scope ref Perf perf,
	ref Alloc alloc,
	scope ref AllSymbols allSymbols,
	scope ref AllUris allUris,
	Uri uri,
	in CString content,
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
	foreach (ReadFileDiag x; values(a.diags)) {
		final switch (x) {
			case ReadFileDiag.unknown:
				return FilesState.hasUnknown;
			case ReadFileDiag.loading:
				res = FilesState.hasLoading;
				break;
			case ReadFileDiag.notFound:
			case ReadFileDiag.error:
				break;
		}
	}
	return res;
}

Uri[] allStorageUris(ref Alloc alloc, in Storage a) {
	ArrayBuilder!Uri res;
	foreach (Uri uri; keys(a.successes))
		add(alloc, res, uri);
	foreach (Uri uri; keys(a.diags))
		add(alloc, res, uri);
	return finish(alloc, res);
}

Uri[] allKnownGoodCrowUris(ref Alloc alloc, scope ref Storage a) {
	ArrayBuilder!Uri res;
	foreach (Uri uri; keys(a.successes))
		if (fileType(a.allUris, uri) == FileType.crow)
			add(alloc, res, uri);
	return finish(alloc, res);
}

Uri[] allUrisWithFileDiag(ref Alloc alloc, in Storage a, in ReadFileDiag[] searchDiags) {
	ArrayBuilder!Uri res;
	foreach (Uri uri, ReadFileDiag diag; a.diags)
		if (contains(searchDiags, diag))
			add(alloc, res, uri);
	return finish(alloc, res);
}

private immutable struct FileInfoOrDiag {
	mixin Union!(FileInfo, ReadFileDiag);
}

private FileInfoOrDiag fileOrDiag(ref Storage a, Uri uri) {
	ConstOpt!(AllocAndValue!FileInfo) res = a.successes[uri];
	return has(res)
		? FileInfoOrDiag(force(res).value)
		: FileInfoOrDiag(getOrAdd!(Uri, ReadFileDiag)(a.mapAlloc, a.diags, uri, () => ReadFileDiag.unknown));
}

void markUnknownIfNotExist(scope ref Storage a, Uri uri) {
	cast(void) fileOrDiag(a, uri);
}

private immutable struct ParsedOrDiag {
	mixin Union!(ParseResult, ReadFileDiag);
}

ParsedOrDiag getParsedOrDiag(ref Storage a, Uri uri) =>
	fileOrDiag(a, uri).match!ParsedOrDiag(
		(FileInfo x) => ParsedOrDiag(x.parsed),
		(ReadFileDiag x) => ParsedOrDiag(x));


immutable struct SourceAndAst {
	CString source;
	FileAst* ast;
}

private immutable struct SourceAndAstOrDiag {
	mixin Union!(SourceAndAst, ReadFileDiag);
}

SourceAndAstOrDiag getSourceAndAstOrDiag(ref Storage a, Uri uri) {
	assert(fileType(a.allUris, uri) == FileType.crow);
	return fileOrDiag(a, uri).match!SourceAndAstOrDiag(
		(FileInfo x) =>
			SourceAndAstOrDiag(SourceAndAst(asCString(x.content), x.parsed.as!(FileAst*))),
		(ReadFileDiag x) =>
			SourceAndAstOrDiag(x));
}

// Storage is mutable, so file content can only be given out temporarily.
ReadFileResult getFileContentOrDiag(ref Storage a, Uri uri) =>
	fileOrDiag(a, uri).match!ReadFileResult(
		(FileInfo x) => ReadFileResult(x.content),
		(ReadFileDiag x) => ReadFileResult(x));

immutable struct ReadFileResult {
	mixin Union!(FileContent, ReadFileDiag);
}

// File content that could be a string or binary.
// It always has a '\0' at the end just in case it's used as a string.
immutable struct FileContent {
	@safe @nogc pure nothrow:

	this(immutable ubyte[] a) {
		bytes = a;
		assert(!isEmpty(bytes) && bytes[$ - 1] == '\0');
	}
	@trusted this(CString a) {
		static assert(char.sizeof == ubyte.sizeof);
		this((cast(immutable ubyte*) a.ptr)[0 .. cStringSize(a) + 1]);
	}

	// This ends with '\0'
	private ubyte[] bytes;
}

immutable(ubyte[]) asBytes(return scope FileContent a) =>
	a.bytes[0 .. $ - 1];

private @trusted CString asCString(return scope FileContent a) =>
	CString(cast(immutable char*) a.bytes.ptr);

string asString(return scope FileContent a) =>
	cast(string) asBytes(a);

const struct LineAndCharacterGetters {
	@safe @nogc pure nothrow:

	private const Storage* storage;

	LineAndCharacterGetter opIndex(Uri uri) scope {
		ConstOpt!(AllocAndValue!FileInfo) res = storage.successes[uri];
		return has(res) ? force(res).value.lineAndCharacterGetter : LineAndCharacterGetter.empty;
	}

	Pos opIndex(in TextDocumentPositionParams x) scope =>
		this[x.textDocument.uri][x.position];

	UriAndLineAndCharacterRange opIndex(in UriAndRange x) scope =>
		UriAndLineAndCharacterRange(x.uri, this[x.uri][x.range]);
}

const struct LineAndColumnGetters {
	@safe @nogc pure nothrow:

	private const Storage* storage;

	LineAndColumnGetter opIndex(Uri uri) scope {
		ConstOpt!(AllocAndValue!FileInfo) res = storage.successes[uri];
		return has(res) ? force(res).value.lineAndColumnGetter : LineAndColumnGetter.empty;
	}

	UriLineAndColumn opIndex(in UriAndPos pos, PosKind kind) scope =>
		UriLineAndColumn(pos.uri, this[pos.uri][pos.pos, kind]);

	UriLineAndColumnRange opIndex(in UriAndRange x) scope =>
		UriLineAndColumnRange(x.uri, this[x.uri][x.range]);

	LineAndCharacterGetters lineAndCharacterGetters() return scope =>
		LineAndCharacterGetters(storage);
}

private CString applyChange(
	ref Alloc alloc,
	in string input,
	in LineAndCharacterGetter lc,
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
