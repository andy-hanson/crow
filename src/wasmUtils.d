module wasmUtils;

@safe @nogc nothrow: // not pure

import compiler : buildAndInterpret;
import frontend.lang : nozeExtension;
import frontend.showDiag : ShowDiagOptions;
import interpret.fakeExtern : FakeExtern;
import model.model : AbsolutePathsGetter;
import util.bools : Bool, False, True;
import util.collection.arr : Arr, arrOfRange, emptyArr, range;
import util.collection.arrBuilder : add, ArrBuilder, finishArr;
import util.collection.dict : Dict, getAt, KeyValuePair;
import util.collection.dictBuilder : addToDict, DictBuilder, finishDictShouldBeNoConflict;
import util.collection.str :
	CStr,
	emptyStr,
	NulTerminatedStr,
	Str,
	strEq,
	strEqLiteral,
	strLiteral,
	strOfNulTerminatedStr;
import util.opt : some, Opt;
import util.path : childPath, comparePath, parsePath, Path, PathAndStorageKind, pathToCStr, rootPath, StorageKind;
import util.ptr : Ptr, ptrTrustMe_mut;
import util.sym : AllSymbols, shortSymAlphaLiteral;
import util.util : todo, verify;
import util.writer : finishWriter, writeChar, writeNat, writeQuotedStr, Writer, writeStatic;

immutable(Str) wasmRun(Debug, Alloc)(ref Debug dbg, ref Alloc alloc, immutable CStr input) {
	AllSymbols!Alloc allSymbols = AllSymbols!Alloc(ptrTrustMe_mut(alloc));
	Reader reader = Reader(input);
	immutable AllFiles allFiles = parseAllFilesJson(alloc, allSymbols, reader);
	DictReadOnlyStorage storage = DictReadOnlyStorage(allFiles);
	immutable Ptr!Path mainPath = rootPath(alloc, shortSymAlphaLiteral("main"));
	FakeExtern!Alloc extern_ = FakeExtern!Alloc(ptrTrustMe_mut(alloc));
	immutable Arr!Str programArgs = emptyArr!Str;
	immutable ShowDiagOptions showDiagOptions = immutable ShowDiagOptions(False);
	immutable int err = buildAndInterpret!(Debug, Alloc, Alloc, DictReadOnlyStorage, FakeExtern!Alloc)(
		dbg, alloc, allSymbols, storage, extern_, showDiagOptions, mainPath, programArgs);
	return writeErrorCodeStdoutStderr(alloc, err, extern_.getStdoutTemp(), extern_.getStderrTemp());
}

private:

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

@trusted immutable(AllFiles) parseAllFilesJson(Alloc)(
	ref Alloc alloc,
	ref AllSymbols!Alloc allSymbols,
	ref Reader reader,
) {
	skipWhitespace(reader);
	eat(reader, '{');
	skipWhitespace(reader);
	verify(strEqLiteral(eatStr(alloc, reader), "include"));
	skipWhitespace(reader);
	eat(reader, ':');
	skipWhitespace(reader);
	immutable FilesDict include = parseFilesDictJson(alloc, allSymbols, reader);
	skipWhitespace(reader);
	eat(reader, ',');
	skipWhitespace(reader);
	verify(strEqLiteral(eatStr(alloc, reader), "user"));
	skipWhitespace(reader);
	eat(reader, ':');
	skipWhitespace(reader);
	immutable FilesDict user = parseFilesDictJson(alloc, allSymbols, reader);
	skipWhitespace(reader);
	eat(reader, '}');
	skipWhitespace(reader);
	eat(reader, '\0');
	return immutable AllFiles(include, user);
}

@system immutable(FilesDict) parseFilesDictJson(Alloc)(
	ref Alloc alloc,
	ref AllSymbols!Alloc allSymbols,
	ref Reader reader,
) {
	DictBuilder!(Ptr!Path, NulTerminatedStr, comparePath) res;

	skipWhitespace(reader);
	eat(reader, '{');
	while (true) {
		skipWhitespace(reader);
		immutable Ptr!Path key = parsePath(alloc, allSymbols, eatStr(alloc, reader));
		skipWhitespace(reader);
		eat(reader, ':');
		skipWhitespace(reader);
		immutable NulTerminatedStr value = eatStrAndAddNulTerminator(alloc, reader);
		skipWhitespace(reader);
		addToDict(alloc, res, key, value);
		if (peek(reader) == ',')
			eat(reader, ',');
		else
			break;
	}
	skipWhitespace(reader);
	eat(reader, '}');
	skipWhitespace(reader);

	return finishDictShouldBeNoConflict(alloc, res);
}

struct Reader {
	immutable(char)* ptr;
}

void skipWhitespace(ref Reader a) {
	while (isWhitespace(peek(a)))
		skip(a);
}

immutable(Bool) isWhitespace(immutable char c) {
	switch (c) {
		case ' ':
		case '\n':
		case '\t':
			return True;
		default:
			return False;
	}
}

void eat(ref Reader a, immutable char c) {
	verify(next(a) == c);
}

@trusted immutable(char) next(ref Reader a) {
	immutable(char) res = *a.ptr;
	a.ptr++;
	return res;
}

@trusted void skip(ref Reader a) {
	verify(*a.ptr != '\0');
	a.ptr++;
}

@trusted immutable(char) peek(ref const Reader a) {
	return *a.ptr;
}

immutable(Str) eatStr(Alloc)(ref Alloc alloc, ref Reader a) {
	return strOfNulTerminatedStr(eatStrAndAddNulTerminator(alloc, a));
}

@trusted immutable(NulTerminatedStr) eatStrAndAddNulTerminator(Alloc)(ref Alloc alloc, ref Reader a) {
	eat(a, '"');
	ArrBuilder!char res;
	while (true) {
		immutable char c = next(a);
		if (c == '"')
			break;
		add(alloc, res, () {
			if (c == '\\') {
				immutable char c2 = next(a);
				switch (c2) {
					case '\\':
						return '\\';
					case '"':
						return '"';
					case 'n':
						return '\n';
					case 't':
						return '\t';
					default:
						return todo!(immutable char)("unexpected escape");
				}
			} else
				return c;
		}());
	}
	add(alloc, res, '\0');
	return immutable NulTerminatedStr(finishArr(alloc, res));
}

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
