module test.testUri;

@safe @nogc pure nothrow:

import test.testUtil : Test;
import util.comparison : Comparison;
import util.opt : none, optEqual, some;
import util.string : CString, cString;
import util.symbol : Extension, Symbol, symbol, symbolAsTempBuffer, symbolOfString;
import util.uri :
	AllUris,
	asFileUri,
	baseName,
	childUri,
	commonAncestor,
	compareUriAlphabetically,
	cStringOfUri,
	FileUri,
	fileUriToTempStr,
	getExtension,
	isFileUri,
	parent,
	parseAbsoluteFilePathAsUri,
	parseUri,
	parseUriWithCwd,
	Path,
	TempStrForPath,
	TEST_eachPart,
	toUri,
	Uri;
import util.util : debugLog;

void testUri(ref Test test) {
	ref AllUris allUris() =>
		test.allUris;

	Uri a = parseUri(allUris, "file:///a");
	verifyUri(test, allUris, a, ["file://", "a"]);
	Uri b = parseUri(allUris, "file:///b");
	verifyUri(test, allUris, b, ["file://", "b"]);
	assert(compareUriAlphabetically(allUris, a, a) == Comparison.equal);
	assert(compareUriAlphabetically(allUris, a, b) == Comparison.less);

	assert(cStringOfUri(test.alloc, allUris, a) == "file:///a");

	Uri aX = childUri(allUris, a, symbol!"x");
	verifyUri(test, allUris, aX, ["file://", "a", "x"]);
	assert(childUri(allUris, a, symbol!"x") == aX);
	Uri aY = childUri(allUris, a, symbol!"y");
	verifyUri(test, allUris, aY, ["file://", "a", "y"]);
	assert(aX != aY);
	assert(cStringOfUri(test.alloc, allUris, aX) == "file:///a/x");
	assert(cStringOfUri(test.alloc, allUris, aY) == "file:///a/y");

	Uri zW = parseUriWithCwd(allUris, aX, cString!"/z/w.crow");
	verifyUri(test, allUris, zW, ["file://", "z", "w.crow"]);
	assert(baseName(allUris, zW) == symbolOfString(test.allSymbols, "w.crow"));
	assert(cStringOfUri(test.alloc, allUris, zW) == "file:///z/w.crow");
	assert(getExtension(allUris, zW) == Extension.crow);
	Uri aXZW = parseUriWithCwd(allUris, aX, cString!"./z/w");
	assert(cStringOfUri(test.alloc, allUris, aXZW) == "file:///a/x/z/w");
	assert(aXZW == parseUriWithCwd(allUris, aX, cString!"z/w"));
	assert(aY == parseUriWithCwd(allUris, aX, cString!"../y"));

	Uri crowLang = parseUri(allUris, "http://crow-lang.org");
	assert(parseUriWithCwd(allUris, aX, "http://crow-lang.org") == crowLang);

	assert(optEqual!Uri(commonAncestor(allUris, [aX, aY]), some(a)));
	assert(optEqual!Uri(commonAncestor(allUris, [aX, aXZW]), some(aX)));
	assert(optEqual!Uri(commonAncestor(allUris, [aX, aXZW, aY]), some(a)));
	assert(optEqual!Uri(commonAncestor(allUris, [aX, crowLang]), none!Uri));

	assert(optEqual!Uri(parent(allUris, crowLang), none!Uri));
	assert(getExtension(allUris, crowLang) == Extension.none);

	testFileUri(test);
}

private:

@trusted void testFileUri(ref Test test) {
	ref AllUris allUris() =>
		test.allUris;

	Uri uri = parseUri(allUris, "file:///home/crow/a.txt");
	verifyUri(test, allUris, uri, ["file://", "home", "crow", "a.txt"]);
	assert(isFileUri(allUris, uri));
	TempStrForPath pathBuf = void;
	FileUri fileUri = asFileUri(allUris, uri);
	fileUriToTempStr(pathBuf, allUris, fileUri);
	CString actual = CString(cast(immutable) pathBuf.ptr);
	assert(actual == "/home/crow/a.txt");

	FileUri ab = parseAbsoluteFilePathAsUri(allUris, "/a/b");
	verifyPath(test, allUris, ab.path, ["a", "b"]);

	assert(toUri(allUris, fileUri) == uri);
}

void verifyUri(ref Test test, in AllUris allUris, Uri a, in string[] expectedParts) {
	verifyPath(test, allUris, a.pathIncludingScheme, expectedParts);
}

void verifyPath(ref Test test, in AllUris allUris, Path a, in string[] expectedParts) {
	size_t i = 0;
	TEST_eachPart(allUris, a, (Symbol x) {
		assert(i < expectedParts.length);
		verifyEq(test, x, symbolOfString(test.allSymbols, expectedParts[i]));
		i++;
	});
	assert(i == expectedParts.length);
}

void verifyEq(ref Test test, Symbol a, Symbol b) {
	if (a != b) {
		debug {
			debugLog("Symbols not equal:");
			debugLog(cast(immutable) symbolAsTempBuffer!64(test.allSymbols, a).ptr);
			debugLog(cast(immutable) symbolAsTempBuffer!64(test.allSymbols, b).ptr);
		}
		assert(false);
	}
}
