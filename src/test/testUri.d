module test.testUri;

@safe @nogc pure nothrow:

import test.testUtil : Test;
import util.col.str : SafeCStr, safeCStr, safeCStrEq;
import util.comparison : Comparison;
import util.opt : none, optEqual, some;
import util.sym : Sym, sym, symAsTempBuffer, symOfStr;
import util.uri :
	AllUris,
	asFileUri,
	baseName,
	childUri,
	commonAncestor,
	compareUriAlphabetically,
	FileUri,
	fileUriToTempStr,
	getExtension,
	isFileUri,
	parent,
	parseAbsoluteFilePathAsUri,
	parseUri,
	parseUriWithCwd,
	Path,
	safeCStrOfUri,
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

	assert(safeCStrEq(safeCStrOfUri(test.alloc, allUris, a), safeCStr!"file:///a"));

	Uri aX = childUri(allUris, a, sym!"x");
	verifyUri(test, allUris, aX, ["file://", "a", "x"]);
	assert(childUri(allUris, a, sym!"x") == aX);
	Uri aY = childUri(allUris, a, sym!"y");
	verifyUri(test, allUris, aY, ["file://", "a", "y"]);
	assert(aX != aY);
	assert(safeCStrEq(safeCStrOfUri(test.alloc, allUris, aX), safeCStr!"file:///a/x"));
	assert(safeCStrEq(safeCStrOfUri(test.alloc, allUris, aY), safeCStr!"file:///a/y"));

	Uri zW = parseUriWithCwd(allUris, aX, safeCStr!"/z/w.crow");
	verifyUri(test, allUris, zW, ["file://", "z", "w.crow"]);
	assert(baseName(allUris, zW) == symOfStr(test.allSymbols, "w.crow"));
	assert(safeCStrEq(safeCStrOfUri(test.alloc, allUris, zW), safeCStr!"file:///z/w.crow"));
	assert(getExtension(allUris, zW) == sym!".crow");
	Uri aXZW = parseUriWithCwd(allUris, aX, safeCStr!"./z/w");
	assert(safeCStrEq(safeCStrOfUri(test.alloc, allUris, aXZW), safeCStr!"file:///a/x/z/w"));
	assert(aXZW == parseUriWithCwd(allUris, aX, safeCStr!"z/w"));
	assert(aY == parseUriWithCwd(allUris, aX, safeCStr!"../y"));

	Uri crowLang = parseUri(allUris, "http://crow-lang.org");
	assert(parseUriWithCwd(allUris, aX, "http://crow-lang.org") == crowLang);

	assert(optEqual!Uri(commonAncestor(allUris, [aX, aY]), some(a)));
	assert(optEqual!Uri(commonAncestor(allUris, [aX, aXZW]), some(aX)));
	assert(optEqual!Uri(commonAncestor(allUris, [aX, aXZW, aY]), some(a)));
	assert(optEqual!Uri(commonAncestor(allUris, [aX, crowLang]), none!Uri));

	assert(optEqual!Uri(parent(allUris, crowLang), none!Uri));
	assert(getExtension(allUris, crowLang) == sym!"");

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
	SafeCStr actual = SafeCStr(cast(immutable) pathBuf.ptr);
	assert(safeCStrEq(actual, "/home/crow/a.txt"));

	FileUri ab = parseAbsoluteFilePathAsUri(allUris, "/a/b");
	verifyPath(test, allUris, ab.path, ["a", "b"]);

	assert(toUri(allUris, fileUri) == uri);
}

void verifyUri(ref Test test, in AllUris allUris, Uri a, in string[] expectedParts) {
	verifyPath(test, allUris, a.pathIncludingScheme, expectedParts);
}

void verifyPath(ref Test test, in AllUris allUris, Path a, in string[] expectedParts) {
	size_t i = 0;
	TEST_eachPart(allUris, a, (Sym x) {
		assert(i < expectedParts.length);
		verifyEq(test, x, symOfStr(test.allSymbols, expectedParts[i]));
		i++;
	});
	assert(i == expectedParts.length);
}

void verifyEq(ref Test test, Sym a, Sym b) {
	if (a != b) {
		debug {
			debugLog("Symbols not equal:");
			debugLog(cast(immutable) symAsTempBuffer!64(test.allSymbols, a).ptr);
			debugLog(cast(immutable) symAsTempBuffer!64(test.allSymbols, b).ptr);
		}
		assert(false);
	}
}
