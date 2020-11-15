@safe @nogc nothrow: // not pure

import compiler : buildAndInterpret;
import frontend.ast : sexprOfAst;
import frontend.getTokens : tokensOfAst, sexprOfTokens, Token;
import frontend.lang : nozeExtension;
import frontend.parse : FileAstAndParseDiagnostics, parseFile;
import frontend.showDiag : strOfParseDiag;
import interpret.fakeExtern : FakeExtern;
import model.model : AbsolutePathsGetter;
import model.parseDiag : ParseDiagnostic;
import util.alloc.globalAlloc : GlobalAlloc;
import util.collection.arr : Arr, arrOfRange, at, emptyArr, size;
import util.collection.dict : Dict, getAt;
import util.collection.dictBuilder : addToDict, DictBuilder, finishDictShouldBeNoConflict;
import util.collection.str :
	NulTerminatedStr,
	nulTerminatedStrOfCStr,
	Str,
	strEq,
	strEqLiteral,
	strLiteral,
	strOfNulTerminatedStr;
import util.opt : Opt, some;
import util.path : childPath, comparePath, parsePath, Path, PathAndStorageKind, rootPath, StorageKind;
import util.ptr : Ptr, ptrTrustMe_mut;
import util.sexpr : Sexpr, tataArr, tataNamedRecord, tataStr, writeSexprJSON;
import util.sourceRange : sexprOfRangeWithinFile;
import util.sym : AllSymbols, shortSymAlphaLiteral;
import util.util : verify;
import util.writer : finishWriter, writeChar, writeNat, writeQuotedStr, Writer, writeStatic;

// seems to be the required entry point
extern(C) void _start() {}

extern(C) immutable(size_t) getBufferSize() {
	return bufferSize;
}

@system extern(C) char* getBuffer() {
	return buffer.ptr;
}

@system extern(C) void getTokens() {
	alias Alloc = GlobalAlloc!("getTokens");
	Alloc alloc;
	immutable NulTerminatedStr str = nulTerminatedStrOfCStr(cast(immutable) buffer.ptr);
	immutable Str result = getTokensAndDiagnosticsJSON(alloc, str);
	writeResult(result);
}

@system extern(C) void getAst() {
	alias Alloc = GlobalAlloc!("getAst");
	Alloc alloc;
	AllSymbols!Alloc allSymbols = AllSymbols!Alloc(ptrTrustMe_mut(alloc));
	immutable NulTerminatedStr str = nulTerminatedStrOfCStr(cast(immutable) buffer.ptr);
	immutable FileAstAndParseDiagnostics ast = parseFile(alloc, allSymbols, str);
	writeAstResult(alloc, ast);
}

@system extern(C) void run() {
	alias Alloc = GlobalAlloc!("run");
	Alloc alloc;
	AllSymbols!Alloc allSymbols = AllSymbols!Alloc(ptrTrustMe_mut(alloc));
	Reader reader = Reader(buffer.ptr);
	immutable AllFiles allFiles = parseAllFilesJson(alloc, allSymbols, reader);
	DictReadOnlyStorage storage = DictReadOnlyStorage(allFiles);
	immutable Ptr!Path mainPath =
		childPath(alloc, some(rootPath(allSymbols, shortSymAlphaLiteral("user"))), shortSymAlphaLiteral("main"));
	FakeExtern!Alloc extern_ = FakeExtern!Alloc(ptrTrustMe_mut(alloc));
	immutable Arr!Str programArgs = emptyArr!Str;
	immutable int err = buildAndInterpret!(Alloc, Alloc, DictReadOnlyStorage, FakeExtern!Alloc)(
		alloc, allSymbols, storage, extern_, mainPath, programArgs);
	immutable Str result = writeErrorCodeStdoutStderr(alloc, err, extern_.getStdoutTemp(), extern_.getStderrTemp());
	writeResult(result);
}

private:

immutable(Str) writeErrorCodeStdoutStderr(Alloc)(
	ref Alloc alloc,
	immutable int err,
	immutable Str stdout,
	immutable Str stderr,
) {
	Writer!Alloc writer = Writer!Alloc(ptrTrustMe_mut(alloc));
	writeStatic(writer, "{\"err\":");
	writeNat(writer, err);
	writeStatic(writer, ",\"stdout\":");
	writeQuotedStr(writer, stdout);
	writeStatic(writer, ",\"stderr\":");
	writeQuotedStr(writer, stderr);
	writeChar(writer, '}');
	return finishWriter(writer);
}

struct AllFiles {
	immutable FilesDict include;
	immutable FilesDict user;
}

alias FilesDict = Dict!(Ptr!Path, NulTerminatedStr, comparePath);

struct DictReadOnlyStorage {
	@safe @nogc nothrow: // not pure

	pure immutable(AbsolutePathsGetter) absolutePathsGetter() const {
		return immutable AbsolutePathsGetter(strLiteral("include"), strLiteral("user"));
	}

	immutable(T) withFile(T)(
		ref immutable PathAndStorageKind pk,
		immutable Str extension,
		scope immutable(T) delegate(ref immutable Opt!NulTerminatedStr) @safe @nogc nothrow cb,
	) const {
		verify(strEq(extension, nozeExtension));
		immutable FilesDict dict = () {
			final switch (pk.storageKind) {
				case StorageKind.global:
					return allFiles.include;
				case StorageKind.local:
					return allFiles.user;
			}
		}();
		immutable Opt!NulTerminatedStr content = getAt(dict, pk.path);
		return cb(content);
	}

	private:
	immutable AllFiles allFiles;
}

@system immutable(AllFiles) parseAllFilesJson(Alloc)(
	ref Alloc alloc,
	ref AllSymbols!Alloc allSymbols,
	ref Reader reader,
) {
	eat(reader, '{');
	verify(strEqLiteral(eatStr(reader), "include"));
	eat(reader, ':');
	immutable FilesDict include = parseFilesDictJson(alloc, allSymbols, reader);
	eat(reader, ',');
	verify(strEqLiteral(eatStr(reader), "user"));
	eat(reader, ':');
	immutable FilesDict user = parseFilesDictJson(alloc, allSymbols, reader);
	eat(reader, '}');
	return immutable AllFiles(include, user);
}

@system immutable(FilesDict) parseFilesDictJson(Alloc)(
	ref Alloc alloc,
	ref AllSymbols!Alloc allSymbols,
	ref Reader reader,
) {
	DictBuilder!(Ptr!Path, NulTerminatedStr, comparePath) res;

	eat(reader, '{');
	while (true) {
		immutable Ptr!Path key = parsePath(alloc, allSymbols, eatStr(reader));
		eat(reader, ':');
		immutable NulTerminatedStr value = eatStrAndAddNulTerminator(reader);
		addToDict(alloc, res, key, value);
		if (peek(reader) == ',')
			eat(reader, ',');
		else
			break;
	}
	eat(reader, '}');
	eat(reader, '\0');

	return finishDictShouldBeNoConflict(alloc, res);
}

struct Reader {
	char* ptr;
}

void eat(ref Reader a, immutable char c) {
	verify(next(a) == c);
}

@trusted immutable(char) next(ref Reader a) {
	immutable(char) res = *a.ptr;
	verify(res != '\0');
	a.ptr++;
	return res;
}

void skip(ref Reader a) {
	a.ptr++;
}

@system immutable(char) peek(ref const Reader a) {
	return *a.ptr;
}

immutable(Str) eatStr(ref Reader a) {
	return strOfNulTerminatedStr(eatStrAndAddNulTerminator(a));
}

@trusted immutable(NulTerminatedStr) eatStrAndAddNulTerminator(ref Reader a) {
	eat(a, '"');
	const char* begin = a.ptr;
	while (peek(a) != '"')
		skip(a);
	verify(*a.ptr == '"');
	*a.ptr = '\0';
	a.ptr++;
	return immutable NulTerminatedStr(arrOfRange(cast(immutable) begin, cast(immutable) a.ptr));
}


immutable(Sexpr) sexprOfParseDiagnostic(Alloc)(ref Alloc alloc, ref immutable ParseDiagnostic a) {
	return tataNamedRecord(
		alloc,
		"diagnostic",
		"range", sexprOfRangeWithinFile(alloc, a.range),
		"message", tataStr(strOfParseDiag(alloc, a.diag)));
}

immutable(Str) getTokensAndDiagnosticsJSON(Alloc)(ref Alloc alloc, ref immutable NulTerminatedStr str) {
	AllSymbols!Alloc allSymbols = AllSymbols!Alloc(ptrTrustMe_mut(alloc));
	immutable FileAstAndParseDiagnostics ast = parseFile(alloc, allSymbols, str);
	immutable Arr!Token tokens = tokensOfAst(alloc, ast.ast);
	immutable Sexpr sexpr = tataNamedRecord(
		alloc,
		"tkns-diags",
		"tokens", sexprOfTokens(alloc, tokens),
		"diags", tataArr(alloc, ast.diagnostics, (ref immutable ParseDiagnostic it) =>
			sexprOfParseDiagnostic(alloc, it)));
	Writer!Alloc writer = Writer!Alloc(ptrTrustMe_mut(alloc));
	writeSexprJSON(writer, sexpr);
	return finishWriter(writer);
}

immutable size_t bufferSize = 1024 * 1024;
char[bufferSize] buffer;

//TODO: not trusted
@trusted void writeAstResult(Alloc)(ref Alloc alloc, ref immutable FileAstAndParseDiagnostics ast) {
	immutable Sexpr sexpr = sexprOfAstAndParseDiagnostics(alloc, ast);
	Writer!Alloc writer = Writer!Alloc(ptrTrustMe_mut(alloc));
	writeSexprJSON(writer, sexpr);
	writeResult(finishWriter(writer));
}

immutable(Sexpr) sexprOfAstAndParseDiagnostics(Alloc)(ref Alloc alloc, ref immutable FileAstAndParseDiagnostics a) {
	return tataNamedRecord(
		alloc,
		"ast-diags",
		"ast", sexprOfAst(alloc, a.ast),
		"diags", tataArr(alloc, a.diagnostics, (ref immutable ParseDiagnostic it) =>
			sexprOfParseDiagnostic(alloc, it)));
}

@system void writeResult(immutable Str str) {
	verify(size(str) < bufferSize);
	foreach (immutable size_t i; 0..size(str)) {
		buffer[i] = at(str, i);
	}
	buffer[size(str) + 1] = '\0';
}
