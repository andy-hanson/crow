module test.testUri;

@safe @nogc pure nothrow:

import test.testUtil : assertEqual, Test;
import util.col.array : zip;
import util.comparison : Comparison;
import util.opt : force, has, none, Opt, optEqual, some;
import util.symbol : Extension, Symbol, symbol, symbolOfString;
import util.uri :
	AllUris,
	asFilePath,
	baseName,
	childFilePath,
	childUri,
	commonAncestor,
	compareUriAlphabetically,
	FilePath,
	getExtension,
	isWindowsPath,
	mustParseUri,
	parent,
	parseFilePath,
	parseUriWithCwd,
	Path,
	stringOfFilePath,
	stringOfUri,
	toUri,
	Uri,
	uriIsFile,
	withComponents;
import util.util : stringOfEnum;

void testUri(ref Test test) {
	testBasic(test, test.allUris);
	testFile(test, test.allUris);
}

private:

void testBasic(ref Test test, scope ref AllUris allUris) {
	Uri a = mustParseUri(allUris, "file:///a");
	verifyUri(test, allUris, a, ["file://", "a"]);
	Uri b = mustParseUri(allUris, "file:///b");
	verifyUri(test, allUris, b, ["file://", "b"]);
	assert(compareUriAlphabetically(allUris, a, a) == Comparison.equal);
	assert(compareUriAlphabetically(allUris, a, b) == Comparison.less);

	assertEqual(stringOfUri(test.alloc, allUris, a), "file:///a");

	Uri aX = childUri(allUris, a, symbol!"x");
	verifyUri(test, allUris, aX, ["file://", "a", "x"]);
	assert(childUri(allUris, a, symbol!"x") == aX);
	Uri aY = childUri(allUris, a, symbol!"y");
	verifyUri(test, allUris, aY, ["file://", "a", "y"]);
	assert(aX != aY);
	assertEqual(stringOfUri(test.alloc, allUris, aX), "file:///a/x");
	assertEqual(stringOfUri(test.alloc, allUris, aY), "file:///a/y");

	Uri zW = parseUriWithCwd(allUris, aX, "/z/w.crow");
	verifyUri(test, allUris, zW, ["file://", "z", "w.crow"]);
	assertEqual(test, baseName(allUris, zW), symbolOfString(test.allSymbols, "w.crow"));
	assertEqual(stringOfUri(test.alloc, allUris, zW), "file:///z/w.crow");
	assertEqual(getExtension(allUris, zW), Extension.crow);
	Uri aXZW = parseUriWithCwd(allUris, aX, "./z/w");
	assertEqual(stringOfUri(test.alloc, allUris, aXZW), "file:///a/x/z/w");
	assertEqual(test, aXZW, parseUriWithCwd(allUris, aX, "z/w"));
	assertEqual(test, aY, parseUriWithCwd(allUris, aX, "../y"));

	Uri crowLang = mustParseUri(allUris, "http://crow-lang.org");
	assert(parseUriWithCwd(allUris, aX, "http://crow-lang.org") == crowLang);

	assertEqual(test, commonAncestor(allUris, [aX, aY]), some(a));
	assertEqual(test, commonAncestor(allUris, [aX, aXZW]), some(aX));
	assertEqual(test, commonAncestor(allUris, [aX, aXZW, aY]), some(a));
	assertEqual(test, commonAncestor(allUris, [aX, crowLang]), none!Uri);

	assertEqual(test, parent(allUris, crowLang), none!Uri);
	assertEqual(getExtension(allUris, crowLang), Extension.none);
}

void assertEqual(ref Test test, Uri a, Uri b) {
	if (a != b) {
		assertEqual(stringOfUri(test.alloc, test.allUris, a), stringOfUri(test.alloc, test.allUris, b));
		assert(false);
	}
}

void assertEqual(ref Test test, Opt!Uri a, Opt!Uri b) {
	if (!optEqual!Uri(a, b)) {
		assertEqual(stringOfOptUri(test, a), stringOfOptUri(test, b));
		assert(false);
	}
}

string stringOfOptUri(ref Test test, Opt!Uri a) =>
	has(a) ? stringOfUri(test.alloc, test.allUris, force(a)) : "<<none>>";

void assertEqual(Extension a, Extension b) {
	if (a != b) {
		assertEqual(stringOfEnum(a), stringOfEnum(b));
		assert(false);
	}
}

void testFile(ref Test test, scope ref AllUris allUris) {
	verifyFile(test, allUris, "file:///home/crow/a.txt", "/home/crow/a.txt", ["home", "crow", "a.txt"]);
	verifyFile(
		test, allUris,
		"file:///C%3A/Users/User/a.txt", "file:///c%3a/users/user/a.txt",
		"C:\\Users\\User\\a.txt", "c:/users/user/a.txt",
		["c:", "users", "user", "a.txt"]);

	Uri aUri = mustParseUri(allUris, "file:///C%3A/Users/User/a");
	assert(isWindowsPath(allUris, aUri));
	Uri booUri = childUri(allUris, aUri, symbol!"BOO");
	assert(stringOfUri(test.alloc, allUris, booUri) == "file:///c%3a/users/user/a/boo");
	assert(isWindowsPath(allUris, booUri));

	FilePath a = parseFilePath(allUris, "C:\\Users\\User\\a");
	assert(a == parseFilePath(allUris, "c:/users/user/a"));
	assert(isWindowsPath(allUris, a));
	FilePath boo = childFilePath(allUris, a, symbol!"BOO");
	assert(stringOfFilePath(test.alloc, allUris, boo) == "c:/users/user/a/boo");
	assert(isWindowsPath(allUris, boo));
}

void verifyFile(
	scope ref Test test,
	scope ref AllUris allUris,
	in string asUriString,
	in string asFilePathString,
	in string[] components,
) {
	verifyFile(test, allUris, asUriString, asUriString, asFilePathString, asFilePathString, components);
}

@trusted void verifyFile(
	scope ref Test test,
	scope ref AllUris allUris,
	in string uriIn,
	in string uriOut,
	in string filePathIn,
	in string filePathOut,
	in string[] components,
) {
	Uri uri = mustParseUri(allUris, uriIn);
	FilePath filePath = parseFilePath(allUris, filePathIn);

	assert(uriIsFile(allUris, uri));
	assert(asFilePath(allUris, uri) == filePath);
	assertEqual(test, toUri(allUris, filePath), uri);

	verifyPath(test, allUris, filePath.path, components);

	assertEqual(stringOfUri(test.alloc, allUris, uri), uriOut);
	assertEqual(stringOfFilePath(test.alloc, allUris, filePath), filePathOut);
}

void verifyUri(ref Test test, in AllUris allUris, Uri a, in string[] expectedParts) {
	verifyPath(test, allUris, a.pathIncludingScheme, expectedParts);
}

void verifyPath(ref Test test, in AllUris allUris, Path a, in string[] expectedComponents) {
	withComponents(allUris, a, (in Symbol[] actual) {
		assert(actual.length == expectedComponents.length);
		zip(actual, expectedComponents, (ref Symbol actualComponent, ref const string expectedComponent) {
			assertEqual(test, actualComponent, symbolOfString(test.allSymbols, expectedComponent));
		});
	});
}
