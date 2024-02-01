module test.testUri;

@safe @nogc pure nothrow:

import test.testUtil : assertEqual, Test;
import util.col.array : zip;
import util.comparison : Comparison;
import util.opt : force, has, none, Opt, optEqual, some;
import util.string : CString;
import util.symbol : Extension, Symbol, symbol, symbolOfString;
import util.uri :
	AllUris,
	asFileUri,
	baseName,
	childUri,
	commonAncestor,
	compareUriAlphabetically,
	FileUri,
	getExtension,
	isFileUri,
	mustParseUri,
	parent,
	parseFileUri,
	parseUriWithCwd,
	Path,
	stringOfFileUri,
	stringOfUri,
	toUri,
	Uri,
	withPathComponents,
	writeFileUri,
	writeUri;
import util.util : stringOfEnum;
import versionInfo : OS;

void testUri(ref Test test) {
	testBasic(test, test.allUris);
	testFileUri(test, test.allUris);
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

void testFileUri(ref Test test, scope ref AllUris allUris) {
	verifyFileUri(test, allUris, OS.linux, "file:///home/crow/a.txt", "/home/crow/a.txt", ["home", "crow", "a.txt"]);
	verifyFileUri(
		test, allUris, OS.windows,
		"file:///C%3A/Users/User/a.txt", "file:///c%3a/users/user/a.txt",
		"C:\\Users\\User\\a.txt", "c:/users/user/a.txt",
		["c:", "users", "user", "a.txt"]);
	assert(parseFileUri(allUris, "C:\\Users\\User\\a.txt") == parseFileUri(allUris, "C:/Users/User/a.txt"));
}

void verifyFileUri(
	scope ref Test test,
	scope ref AllUris allUris,
	OS os,
	in string asUriString,
	in string asFileUriString,
	in string[] components,
) {
	verifyFileUri(test, allUris, os, asUriString, asUriString, asFileUriString, asFileUriString, components);
}

@trusted void verifyFileUri(
	scope ref Test test,
	scope ref AllUris allUris,
	OS os, // TODO:KILL ----------------------------------------------------------------------------------------------------------------
	in string uriIn,
	in string uriOut,
	in string fileUriIn,
	in string fileUriOut,
	in string[] components,
) {
	Uri uri = mustParseUri(allUris, uriIn);
	FileUri fileUri = parseFileUri(allUris, fileUriIn);

	assert(isFileUri(allUris, uri));
	assert(asFileUri(allUris, uri) == fileUri);
	assertEqual(test, toUri(allUris, fileUri), uri);

	verifyPath(test, allUris, fileUri.path, components);

	assertEqual(stringOfUri(test.alloc, allUris, uri), uriOut);
	assertEqual(stringOfFileUri(test.alloc, allUris, os, fileUri), fileUriOut);
}

void verifyUri(ref Test test, in AllUris allUris, Uri a, in string[] expectedParts) {
	verifyPath(test, allUris, a.pathIncludingScheme, expectedParts);
}

void verifyPath(ref Test test, in AllUris allUris, Path a, in string[] expectedComponents) {
	withPathComponents(allUris, a, (in Symbol[] actual) {
		assert(actual.length == expectedComponents.length);
		zip(actual, expectedComponents, (ref Symbol actualComponent, ref const string expectedComponent) {
			assertEqual(test, actualComponent, symbolOfString(test.allSymbols, expectedComponent));
		});
	});
}
