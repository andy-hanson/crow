module util.uri;

@safe @nogc nothrow: // not pure

import frontend.parse.lexUtil : decodeHexDigit;
import util.alloc.alloc : Alloc;
import util.cell : Cell, cellGet, cellSet;
import util.col.array : fold, indexOf, indexOfStartingAt, isEmpty, sum;
import util.col.mutArr : MutArr, mutArrSize, push;
import util.col.mutMaxArr : asTemporaryArray, isEmpty, MutMaxArr, mutMaxArr, reverseInPlace;
import util.comparison : Comparison;
import util.conv : uintOfUshorts, ushortsOfUint, safeToUshort;
import util.hash : HashCode;
import util.opt : has, force, none, Opt, optIf, some;
import util.string : compareStringsAlphabetically, CString, stringOfCString;
import util.symbol :
	addExtension,
	alterExtension,
	alterExtensionCb,
	AllSymbols,
	asLongSymbol,
	eachCharInSymbol,
	Extension,
	getExtension,
	hasExtension,
	isLongSymbol,
	Symbol,
	symbol,
	symbolOfString,
	symbolSize,
	toLowerCase,
	writeSymbol;
import util.util : stringOfEnum, todo, typeAs;
import util.writer : digitChar, makeStringWithWriter, withStackWriter, withStackWriterImpureCString, withWriter, Writer;

T withCStringOfFilePath(T)(in AllUris allUris, FilePath path, in T delegate(in CString) @safe @nogc nothrow cb) =>
	withStackWriterImpureCString!T((scope ref Writer writer) {
		writeFilePath(writer, allUris, path);
	}, cb);

pure:

struct AllUris {
	@safe @nogc pure nothrow:
	private:
	Alloc* allocPtr;
	AllSymbols* allSymbolsPtr;

	// Root path at index 0 will have children, but they won't have it as a parent
	MutArr!(Opt!Path) pathToParent;
	MutArr!Symbol pathToBaseName;
	MutArr!(MutArr!Path) pathToChildren;
	MutArr!PathInfo pathToInfo;

	public this(Alloc* a, AllSymbols* as) {
		allocPtr = a;
		allSymbolsPtr = as;

		// 0 must be the empty URI
		push(alloc, pathToParent, none!Path);
		push(alloc, pathToBaseName, symbol!"");
		push(alloc, pathToChildren, MutArr!Path());
		push(alloc, pathToInfo, PathInfo(false, false));
	}

	ref inout(Alloc) alloc() return scope inout =>
		*allocPtr;
	public ref const(AllSymbols) allSymbols() return scope const =>
		*allSymbolsPtr;
	public ref AllSymbols allSymbols() return scope =>
		*allSymbolsPtr;
}

// This information could be derived from the first two components, but this is easier
private immutable struct PathInfo {
	// First component is 'file://'
	bool isUriFile;
	// First component is 'c:' (or 'd:' etc), or first component is 'file://' and second component is 'c:'.
	// If so, all components will be converted to lower-case to enforce case-insensitivity.
	bool isWindowsPath;
}

// Uniform Resource Identifier ; does not support query or fragment.
immutable struct Uri {
	@safe @nogc pure nothrow:

	// The first component is the scheme + authority packed into a Symbol
	private Path path;

	Path pathIncludingScheme() =>
		path;

	static Uri empty() =>
		Uri(Path.empty);

	HashCode hash() =>
		path.hash();

	uint asUintForTaggedUnion() =>
		path.asUintForTaggedUnion;
	static Uri fromUintForTaggedUnion(uint a) =>
		Uri(Path.fromUintForTaggedUnion(a));
}

private bool isRootUri(in AllUris allUris, Uri a) =>
	!has(parent(allUris, a));

private Symbol fileScheme() =>
	symbol!"file://";

bool uriIsFile(in AllUris allUris, Uri a) =>
	allUris.pathToInfo[a.path.index].isUriFile;

FilePath asFilePath(ref AllUris allUris, Uri a) {
	assert(uriIsFile(allUris, a));
	return withComponents(allUris, a.path, (in Symbol[] components) {
		assert(components[0] == fileScheme);
		return FilePath(descendentPath(allUris,
			rootPath(allUris, components[1], PathInfo(isUriFile: true, isWindowsPath(allUris, a))),
			components[2 .. $]));
	});
}

// Uri that is restricted to be a 'file:'
immutable struct FilePath {
	// Unlike for a Uri, this doesn't have "file" as the first component
	Path path;
}

Uri toUri(ref AllUris allUris, FilePath a) =>
	concatUriAndPath(
		allUris,
		Uri(rootPath(allUris, fileScheme, PathInfo(isUriFile: true, isWindowsPath: isWindowsPath(allUris, a)))),
		a.path);

// Represents the path part of a URI, e.g. 'a/b/c'
immutable struct Path {
	@safe @nogc pure nothrow:

	private ushort index;

	static Path empty() =>
		Path(0);

	HashCode hash() =>
		HashCode(index);

	uint asUintForTaggedUnion() =>
		index;
	static Path fromUintForTaggedUnion(uint a) =>
		Path(safeToUshort(a));
}

Opt!Uri parent(in AllUris allUris, Uri a) {
	Opt!Path res = parent(allUris, a.path);
	return has(res) ? some(Uri(force(res))) : none!Uri;
}
Opt!FilePath parent(in AllUris allUris, FilePath a) {
	Opt!Path res = parent(allUris, a.path);
	return has(res) ? some(FilePath(force(res))) : none!FilePath;
}
Opt!Path parent(in AllUris allUris, Path a) =>
	allUris.pathToParent[a.index];

Uri parentOrEmpty(ref AllUris allUris, Uri a) {
	Opt!Uri res = parent(allUris, a);
	return has(res) ? force(res) : a;
}

// Removes an existing extension and adds a new one.
FilePath alterExtension(scope ref AllUris allUris, FilePath a, Extension newExtension) =>
	FilePath(alterExtension(allUris, a.path, newExtension));
private Path alterExtension(scope ref AllUris allUris, Path a, Extension newExtension) =>
	modifyBaseName(allUris, a, (Symbol name) =>
		.alterExtension(allUris.allSymbols, name, newExtension));

// Adds an extension after any already existing extension.
Uri addExtension(scope ref AllUris allUris, Uri a, Extension extension) =>
	Uri(addExtension(allUris, a.path, extension));
private Path addExtension(scope ref AllUris allUris, Path a, Extension extension) =>
	modifyBaseName(allUris, a, (Symbol name) =>
		.addExtension(allUris.allSymbols, name, extension));

// E.g., changes 'foo.crow' to 'foo.deadbeef.c'
FilePath alterExtensionWithHex(ref AllUris allUris, FilePath a, in ubyte[] bytes, Extension newExtension) =>
	FilePath(alterExtensionWithHexForPath(allUris, a.path, bytes, newExtension));
private Path alterExtensionWithHexForPath(ref AllUris allUris, Path a, in ubyte[] bytes, Extension newExtension) =>
	modifyBaseName(allUris, a, (Symbol name) =>
		alterExtensionCb(allUris.allSymbols, name, (scope ref Writer writer) {
			writer ~= '.';
			foreach (ubyte x; bytes) {
				writer ~= digitChar(x / 16);
				writer ~= digitChar(x % 16);
			}
			writer ~= '.';
			writer ~= stringOfEnum(newExtension);
		}));

private bool hasExtension(in AllUris allUris, Path a) =>
	hasExtension(allUris.allSymbols, baseName(allUris, a));

private Path modifyBaseName(ref AllUris allUris, Path a, in Symbol delegate(Symbol) @safe @nogc pure nothrow cb) {
	Symbol newBaseName = cb(baseName(allUris, a));
	Opt!Path parent = parent(allUris, a);
	return has(parent)
		? childPath(allUris, force(parent), newBaseName)
		: rootPath(allUris, newBaseName, pathInfo(allUris, a));
}

// This will either be "" or start with a "."
Extension getExtension(scope ref AllUris allUris, Uri a) =>
	isRootUri(allUris, a)
		? Extension.none
		: getExtension(allUris, a.path);
Extension getExtension(scope ref AllUris allUris, FilePath a) =>
	getExtension(allUris, a.path);
Extension getExtension(scope ref AllUris allUris, Path a) =>
	getExtension(allUris.allSymbols, baseName(allUris, a));

Symbol baseName(in AllUris allUris, Uri a) =>
	isRootUri(allUris, a)
		? symbol!""
		: baseName(allUris, a.path);
Symbol baseName(in AllUris allUris, FilePath a) =>
	baseName(allUris, a.path);
Symbol baseName(in AllUris allUris, Path a) =>
	allUris.pathToBaseName[a.index];

immutable struct PathFirstAndRest {
	Symbol first;
	Opt!Path rest;
}

PathFirstAndRest firstAndRest(ref AllUris allUris, Path a) {
	Opt!Path par = parent(allUris, a);
	Symbol baseName = baseName(allUris, a);
	if (has(par)) {
		PathFirstAndRest parentRes = firstAndRest(allUris, force(par));
		Path rest = has(parentRes.rest)
			? childPath(allUris, force(parentRes.rest), baseName)
			: rootPathPlain(allUris, baseName);
		return PathFirstAndRest(parentRes.first, some(rest));
	} else
		return PathFirstAndRest(baseName, none!Path);
}

private Path getOrAddChild(
	ref AllUris allUris,
	ref MutArr!Path children,
	Opt!Path parent,
	Symbol namePre,
	PathInfo info,
) {
	Symbol name = info.isWindowsPath ? toLowerCase(allUris.allSymbols, namePre) : namePre;
	foreach (Path child; children)
		if (baseName(allUris, child) == name)
			return child;

	Path res = Path(safeToUshort(mutArrSize(allUris.pathToParent)));
	push(allUris.alloc, children, res);
	push(allUris.alloc, allUris.pathToParent, parent);
	push(allUris.alloc, allUris.pathToBaseName, name);
	push(allUris.alloc, allUris.pathToChildren, MutArr!Path());
	push(allUris.alloc, allUris.pathToInfo, info);
	return res;
}

private PathInfo pathInfo(in AllUris allUris, Path a) =>
	allUris.pathToInfo[a.index];
bool isWindowsPath(in AllUris allUris, Uri a) =>
	isWindowsPath(allUris, a.path);
bool isWindowsPath(in AllUris allUris, FilePath a) =>
	isWindowsPath(allUris, a.path);
bool isWindowsPath(in AllUris allUris, Path a) =>
	pathInfo(allUris, a).isWindowsPath;

Path rootPathPlain(ref AllUris allUris, Symbol name) =>
	rootPath(allUris, name, PathInfo(isUriFile: false, isWindowsPath: false));
private Path rootPath(ref AllUris allUris, Symbol name, PathInfo info) =>
	getOrAddChild(allUris, allUris.pathToChildren[Path.empty.index], none!Path, name, info);

Uri childUri(ref AllUris allUris, Uri parent, Symbol name) =>
	Uri(childPath(allUris, parent.path, name));

FilePath childFilePath(ref AllUris allUris, FilePath parent, Symbol name) =>
	FilePath(childPath(allUris, parent.path, name));

Uri bogusUri(ref AllUris allUris) =>
	mustParseUri(allUris, "bogus:bogus");

Path childPath(ref AllUris allUris, Path parent, Symbol name) =>
	childPathWithInfo(allUris, parent, name, pathInfo(allUris, parent));
private Path childPathWithInfo(ref AllUris allUris, Path parent, Symbol name, PathInfo info) =>
	getOrAddChild(allUris, allUris.pathToChildren[parent.index], some(parent), name, info);
private Path descendentPath(ref AllUris allUris, Path parent, in Symbol[] childComponentNames) =>
	fold!(Path, Symbol)(parent, childComponentNames, (Path acc, in Symbol component) =>
		childPath(allUris, acc, component));

immutable struct RelPath {
	@safe @nogc pure nothrow:

	ushort nParents;
	Path path;

	uint asUintForTaggedUnion() =>
		uintOfUshorts([nParents, path.index]);
	static RelPath fromUintForTaggedUnion(uint a) {
		ushort[2] xs = ushortsOfUint(a);
		return RelPath(xs[0], Path(xs[1]));
	}
}

Opt!Uri resolveUri(ref AllUris allUris, Uri base, RelPath relPath) {
	if (relPath.nParents == 0)
		return some(concatUriAndPath(allUris, base, relPath.path));
	else {
		Opt!Uri par = parent(allUris, base);
		return has(par)
			? resolveUri(allUris, force(par), RelPath(cast(ushort) (relPath.nParents - 1), relPath.path))
			: none!Uri;
	}
}

Uri concatUriAndPath(ref AllUris allUris, Uri a, Path b) =>
	withComponents(allUris, b, (in Symbol[] components) =>
		Uri(descendentPath(allUris, a.path, components)));

T withComponents(T)(in AllUris allUris, Path a, in T delegate(in Symbol[]) @safe @nogc pure nothrow cb) =>
	withComponentsPreferRelative!T(allUris, none!Path, a, (bool isRelative, in Symbol[] components) {
		assert(!isRelative);
		return cb(components);
	});

private T withComponentsPreferRelative(T)(
	in AllUris allUris,
	in Opt!Path cwd,
	Path a,
	in T delegate(bool isRelative, in Symbol[]) @safe @nogc pure nothrow cb,
) {
	MutMaxArr!(0x100, Symbol) stack = mutMaxArr!(0x100, Symbol);
	Cell!Path cur = Cell!Path(a);
	bool isRelative = false;
	while (true) {
		stack ~= baseName(allUris, cellGet(cur));
		Opt!Path par = parent(allUris, cellGet(cur));
		if (!has(par))
			break;
		else if (has(cwd) && force(cwd) == force(par)) {
			isRelative = true;
			break;
		} else {
			cellSet(cur, force(par));
			continue;
		}
	}
	reverseInPlace(stack);
	return cb(isRelative, asTemporaryArray(stack));
}

size_t pathLength(in AllUris allUris, Path path) =>
	withComponents(allUris, path, (in Symbol[] components) {
		assert(!isEmpty(components));
		size_t slashes = components.length - 1;
		return sum!Symbol(components, (in Symbol component) => symbolSize(allUris.allSymbols, component)) + slashes;
	});

CString cStringOfUriPreferRelative(ref Alloc alloc, in AllUris allUris, in UrisInfo urisInfo, Uri a) =>
	withWriter(alloc, (scope ref Writer writer) {
		writeUriPreferRelative(writer, allUris, urisInfo, a);
	});
string stringOfUri(ref Alloc alloc, in AllUris allUris, Uri a) =>
	makeStringWithWriter(alloc, (scope ref Writer writer) {
		writeUri(writer, allUris, a);
	});
string stringOfFilePath(ref Alloc alloc, in AllUris allUris, FilePath a) =>
	makeStringWithWriter(alloc, (scope ref Writer writer) {
		writeFilePath(writer, allUris, a);
	});

private T withStringOfUri(T)(in AllUris allUris, Uri a, in T delegate(in string) @safe @nogc pure nothrow cb) =>
	withStackWriter!(0x1000, T)((scope ref Alloc _, scope ref Writer writer) {
		writeUri(writer, allUris, a);
	}, cb);

Symbol symbolOfUri(scope ref AllUris allUris, Uri a) =>
	withStringOfUri(allUris, a, (in string x) => symbolOfString(allUris.allSymbols, x));

CString cStringOfFilePath(ref Alloc alloc, in AllUris allUris, FilePath a) =>
	withWriter(alloc, (scope ref Writer writer) {
		writeFilePath(writer, allUris, a);
	});
string stringOfPath(ref Alloc alloc, in AllUris allUris, Path a) =>
	makeStringWithWriter(alloc, (scope ref Writer writer) {
		writePath(writer, allUris, a);
	});

public CString cStringOfUriPreferRelative(ref Alloc alloc, in AllUris allUris, ref UrisInfo urisInfo, Uri a) =>
	withWriter(alloc, (scope ref Writer writer) {
		writeUriPreferRelative(writer, allUris, urisInfo, a);
	});

Uri mustParseUri(ref AllUris allUris, in string str) {
	Opt!Uri res = parseUri(allUris, str);
	return force(res);
}
private Opt!Uri parseUri(ref AllUris allUris, in CString str) =>
	parseUri(allUris, stringOfCString(str));
private Opt!Uri parseUri(ref AllUris allUris, in string uri) {
	Opt!size_t optColon = indexOf(uri, ':');
	if (has(optColon)) {
		size_t colon = force(optColon);
		size_t start = colon < uri.length - 2 && uri[colon + 1] == '/' && uri[colon + 2] == '/' ? colon + 3 : colon + 1;
		Opt!size_t slash = indexOfStartingAt(uri, '/', start);
		if (has(slash)) {
			Uri root = rootUri(allUris, uri[0 .. force(slash)]);
			return some(Uri(parsePathInner(
				allUris,
				uri[force(slash) + 1 .. $],
				ParsePathOptions(uriDecode: true, isUriFile: uriIsFile(allUris, root)),
				(Symbol rootSymbol) =>
					childPathWithInfo(allUris, root.path, rootSymbol, PathInfo(
						isUriFile: uriIsFile(allUris, root),
						isWindowsPath: isWindowsPathStart(allUris.allSymbols, rootSymbol))))));
		} else
			return some(rootUri(allUris, uri));
	} else
		return none!Uri;
}
private Uri rootUri(ref AllUris allUris, in string schemeAndAuthority) {
	Symbol schemeSymbol = symbolOfString(allUris.allSymbols, schemeAndAuthority);
	return Uri(rootPath(allUris, schemeSymbol, PathInfo(isUriFile: schemeSymbol == fileScheme, isWindowsPath: false)));
}

Path parsePath(ref AllUris allUris, in string str) =>
	parsePathInner(allUris, str, ParsePathOptions(uriDecode: false, isUriFile: false), (Symbol rootSymbol) =>
		rootPath(allUris, rootSymbol, PathInfo(isUriFile: false, isWindowsPath: false)));
private immutable struct ParsePathOptions {
	bool uriDecode;
	bool isUriFile;
}
private Path parsePathInner(
	ref AllUris allUris,
	in string str,
	in ParsePathOptions options,
	in Path delegate(Symbol) @safe @nogc pure nothrow cbRoot,
) {
	StringIter iter = StringIter(str);
	Cell!Path res = Cell!Path(cbRoot(parsePathComponent(allUris.allSymbols, iter, options.uriDecode)));
	while (!done(iter))
		cellSet(res, childPath(allUris, cellGet(res), parsePathComponent(allUris.allSymbols, iter, options.uriDecode)));
	return cellGet(res);
}
private @trusted Symbol parsePathComponent(
	scope ref AllSymbols allSymbols,
	scope ref StringIter iter,
	bool uriDecode,
) =>
	withStackWriter!0x1000((scope ref Alloc _, scope ref Writer writer) {
		while (!done(iter)) {
			char x = next(iter);
			if (x == '%' && uriDecode) {
				Opt!ubyte x0 = decodeHexDigit(nextOrDefault(iter, 'x'));
				Opt!ubyte x1 = decodeHexDigit(nextOrDefault(iter, 'x'));
				if (has(x0) && has(x1)) {
					char decoded = cast(char) ((force(x0) << 4) | force(x1));
					writer ~= toLowerCase(decoded);
				} else
					writer ~= "�";
				continue;
			} else if (x == '/' || x == '\\')
				break;
			else {
				writer ~= x;
				continue;
			}
		}
	}, (in string x) => symbolOfString(allSymbols, x));

private void encodePathComponent(scope ref Writer writer, in AllSymbols allSymbols, Symbol component) {
	eachCharInSymbol(allSymbols, component, (char x) {
		if (!isUriSafeChar(x)) {
			writer ~= '%';
			writer ~= typeAs!string(encodeAsHex(x));
		} else
			writer ~= x;
	});
}

private bool isWindowsPathStart(in AllSymbols allSymbols, Symbol a) =>
	isLongSymbol(a) && isWindowsPathStart(asLongSymbol(allSymbols, a));
private bool isWindowsPathStart(in string a) =>
	a.length == 2 && isLetter(a[0]) && a[1] == ':';
private bool isLetter(char a) =>
	('a' <= a && a <= 'z') ||
	('A' <= a && a <= 'Z');

private bool isUriSafeChar(char x) =>
	('a' <= x && x <= 'z') ||
	('A' <= x && x <= 'Z') ||
	('0' <= x && x <= '9') ||
	x == '-' || x == '_' || x == '.' || x == '~';
private char[2] encodeAsHex(ubyte a) =>
	[encodeAsHexDigit(a >> 4), encodeAsHexDigit(a & 0xf)];
private char encodeAsHexDigit(ubyte a) {
	assert(a <= 0xf);
	char res = a <= 9 ? cast(char) ('0' + a) : cast(char) ('a' + (a - 10));
	Opt!ubyte decoded = decodeHexDigit(res);
	assert(force(decoded) == a);
	return res;
}

private @trusted RelPath parseRelPath(ref AllUris allUris, in string a) =>
	parseRelPathRecur(allUris, 0, a);
private @system RelPath parseRelPathRecur(ref AllUris allUris, size_t nParents, in string a) =>
	a.length >= 2 && a[0] == '.' && isSlash(a[1])
		? parseRelPathRecur(allUris, nParents, a[2 .. $])
		: a.length >= 3 && a[0] == '.' && a[1] == '.' && isSlash(a[2])
		? parseRelPathRecur(allUris, nParents + 1, a[3 .. $])
		: RelPath(safeToUshort(nParents), parsePath(allUris, a));

FilePath parseFilePath(ref AllUris allUris, in CString a) =>
	parseFilePath(allUris, stringOfCString(a));
FilePath parseFilePath(ref AllUris allUris, in string a) =>
	FilePath(parsePathInner(
		allUris,
		!isEmpty(a) && a[0] == '/' ? a[1 .. $] : a,
		ParsePathOptions(uriDecode: false, isUriFile: false),
		(Symbol firstComponent) =>
			rootPath(
				allUris, firstComponent,
				PathInfo(isUriFile: false, isWindowsPath: isWindowsPathStart(allUris.allSymbols, firstComponent)))));

Opt!FilePath parseFilePathWithCwd(ref AllUris allUris, FilePath cwd, in CString a) {
	Uri res = parseUriWithCwd(allUris, cwd, stringOfCString(a));
	return optIf(uriIsFile(allUris, res), () => asFilePath(allUris, res));
}

Uri parseUriWithCwd(ref AllUris allUris, FilePath cwd, in string a) =>
	parseUriWithCwd(allUris, toUri(allUris, cwd), a);

Uri parseUriWithCwd(ref AllUris allUris, Uri cwd, in string a) {
	//TODO: handle actual URIs...
	if (looksLikeAbsolutePath(a))
		return toUri(allUris, parseFilePath(allUris, a));
	else if (looksLikeUri(a))
		return mustParseUri(allUris, a);
	else {
		//TODO: handle parse error (return none if so)
		RelPath rp = parseRelPath(allUris, a);
		Opt!Uri resolved = resolveUri(allUris, cwd, rp);
		return has(resolved)
			? force(resolved)
			: todo!Uri("relative path reaches past file system root");
	}
}

private @trusted bool looksLikeAbsolutePath(in string a) =>
	(a.length >= 1 && a[0] == '/') ||
	(a.length >= 3 && isWindowsPathStart(a[0 .. 2]) && isSlash(a[2]));

private bool looksLikeUri(in string a) =>
	containsSubstring(a, "://");

private bool containsSubstring(in string a, in string b) =>
	a.length >= b.length && (a[0 .. b.length] == b || containsSubstring(a[1 .. $], b));

@trusted Comparison compareUriAlphabetically(in AllUris allUris, Uri a, Uri b) =>
	withStringOfUri(allUris, a, (in string aStr) =>
		withStringOfUri(allUris, b, (in string bStr) =>
			compareStringsAlphabetically(aStr, bStr)));

immutable struct UrisInfo {
	Opt!Uri cwd;
}

bool isAncestor(in AllUris allUris, Uri a, Uri b) {
	if (a == b)
		return true;
	else {
		Opt!Uri par = parent(allUris, b);
		return has(par) && isAncestor(allUris, a, force(par));
	}
}

Opt!Uri commonAncestor(in AllUris allUris, in Uri[] uris) =>
	uris.length == 0
		? none!Uri
		: commonAncestorRecur(allUris, uris[0], uris[1 .. $]);
private Opt!Uri commonAncestorRecur(in AllUris allUris, Uri cur, in Uri[] uris) {
	if (uris.length == 0)
		return some(cur);
	else {
		Opt!Uri x = commonAncestorBinary(allUris, cur, uris[0]);
		return has(x) ? commonAncestorRecur(allUris, force(x), uris[1 .. $]) : none!Uri;
	}
}
private Opt!Uri commonAncestorBinary(in AllUris allUris, Uri a, Uri b) {
	size_t aParts = countPathParts(allUris, a.path);
	size_t bParts = countPathParts(allUris, b.path);
	return aParts > bParts
		? commonAncestorRecur(allUris, removeLastNParts(allUris, a, aParts - bParts), b)
		: commonAncestorRecur(allUris, a, removeLastNParts(allUris, b, bParts - aParts));
}
private Opt!Uri commonAncestorRecur(in AllUris allUris, Uri a, Uri b) {
	if (a == b)
		return some(a);
	else {
		Opt!Uri parA = parent(allUris, a);
		Opt!Uri parB = parent(allUris, b);
		return has(parA)
			? commonAncestorRecur(allUris, force(parA), force(parB))
			: none!Uri;
	}
}

private:

bool isSlash(char a) =>
	a == '/' || a == '\\';

size_t countPathParts(in AllUris allUris, Path a) =>
	countPathPartsRecur(1, allUris, a);
size_t countPathPartsRecur(size_t acc, in AllUris allUris, Path a) {
	Opt!Path par = parent(allUris, a);
	return has(par) ? countPathPartsRecur(acc + 1, allUris, force(par)) : acc;
}

Uri removeLastNParts(in AllUris allUris, Uri a, size_t nToRemove) {
	if (nToRemove == 0)
		return a;
	else {
		Opt!Uri par = parent(allUris, a);
		return removeLastNParts(allUris, force(par), nToRemove - 1);
	}
}

public void writeUri(scope ref Writer writer, in AllUris allUris, Uri a) {
	writePath(writer, allUris, a.path, uriEncode: true);
}

public void writeFilePath(scope ref Writer writer, in AllUris allUris, FilePath a) {
	if (!isWindowsPath(allUris, a))
		writer ~= '/';
	writePath(writer, allUris, a.path);
}

void writePath(scope ref Writer writer, in AllUris allUris, Path a, bool uriEncode = false) {
	withComponents(allUris, a, (in Symbol[] components) {
		writeComponents(writer, allUris.allSymbols, components, uriEncode);
	});
}

void writeComponents(scope ref Writer writer, in AllSymbols allSymbols, in Symbol[] components, bool uriEncode) {
	foreach (size_t index, Symbol component; components) {
		if (uriEncode && index != 0) // First component or a Uri is the scheme, which is not encoded
			encodePathComponent(writer, allSymbols, component);
		else
			writeSymbol(writer, allSymbols, component);
		if (index != components.length - 1)
			writer ~= '/';
	}
}

public void writeUriPreferRelative(ref Writer writer, in AllUris allUris, in UrisInfo urisInfo, Uri a) {
	withComponentsPreferRelative(
		allUris, has(urisInfo.cwd) ? some(force(urisInfo.cwd).path) : none!Path, a.path,
		(bool isRelative, in Symbol[] components) {
			writeComponents(writer, allUris.allSymbols, components, uriEncode: !isRelative);
		});
}

public size_t relPathLength(in AllUris allUris, in RelPath a) =>
	(a.nParents == 0 ? "./".length : a.nParents * "../".length) + pathLength(allUris, a.path);

public void writeRelPath(ref Writer writer, in AllUris allUris, in RelPath a) {
	foreach (ushort i; 0 .. a.nParents)
		writer ~= "../";
	writePath(writer, allUris, a.path);
}

struct StringIter {
	@safe @nogc pure nothrow:

	immutable(char)* cur;
	immutable(char)* end;

	@trusted this(return scope string a) {
		cur = a.ptr;
		end = a.ptr + a.length;
	}
}
bool done(in StringIter a) {
	assert(a.cur <= a.end);
	return a.cur == a.end;
}
@trusted char next(scope ref StringIter a) {
	assert(!done(a));
	char res = *a.cur;
	a.cur++;
	return res;
}
char nextOrDefault(scope ref StringIter a, char default_) =>
	done(a) ? default_ : next(a);
