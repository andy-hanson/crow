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
	TempStrForPath,
	TEST_eachPart,
	toUri,
	Uri,
	uriToSafeCStr;
import util.util : debugLog, verify, verifyFail;

void testUri(ref Test test) {
	ref AllUris allUris() =>
		test.allUris;

	Uri a = parseUri(allUris, "file:///a");
	verifyUri(test, allUris, a, ["file://", "a"]);
	Uri b = parseUri(allUris, "file:///b");
	verifyUri(test, allUris, b, ["file://", "b"]);
	verify(compareUriAlphabetically(allUris, a, a) == Comparison.equal);
	verify(compareUriAlphabetically(allUris, a, b) == Comparison.less);

	verify(safeCStrEq(uriToSafeCStr(test.alloc, allUris, a), safeCStr!"file:///a"));

	Uri aX = childUri(allUris, a, sym!"x");
	verifyUri(test, allUris, aX, ["file://", "a", "x"]);
	verify(childUri(allUris, a, sym!"x") == aX);
	Uri aY = childUri(allUris, a, sym!"y");
	verifyUri(test, allUris, aY, ["file://", "a", "y"]);
	verify(aX != aY);
	verify(safeCStrEq(uriToSafeCStr(test.alloc, allUris, aX), safeCStr!"file:///a/x"));
	verify(safeCStrEq(uriToSafeCStr(test.alloc, allUris, aY), safeCStr!"file:///a/y"));

	Uri zW = parseUriWithCwd(allUris, aX, safeCStr!"/z/w.crow");
	verifyUri(test, allUris, zW, ["file://", "z", "w.crow"]);
	verify(baseName(allUris, zW) == symOfStr(test.allSymbols, "w.crow"));
	verify(safeCStrEq(uriToSafeCStr(test.alloc, allUris, zW), safeCStr!"file:///z/w.crow"));
	verify(getExtension(allUris, zW) == sym!".crow");
	Uri aXZW = parseUriWithCwd(allUris, aX, safeCStr!"./z/w");
	verify(safeCStrEq(uriToSafeCStr(test.alloc, allUris, aXZW), safeCStr!"file:///a/x/z/w"));
	verify(aXZW == parseUriWithCwd(allUris, aX, safeCStr!"z/w"));
	verify(aY == parseUriWithCwd(allUris, aX, safeCStr!"../y"));

	Uri crowLang = parseUri(allUris, "http://crow-lang.org");
	verify(parseUriWithCwd(allUris, aX, "http://crow-lang.org") == crowLang);

	verify(optEqual!Uri(commonAncestor(allUris, [aX, aY]), some(a)));
	verify(optEqual!Uri(commonAncestor(allUris, [aX, aXZW]), some(aX)));
	verify(optEqual!Uri(commonAncestor(allUris, [aX, aXZW, aY]), some(a)));
	verify(optEqual!Uri(commonAncestor(allUris, [aX, crowLang]), none!Uri));

	verify(optEqual!Uri(parent(allUris, crowLang), none!Uri));
	verify(getExtension(allUris, crowLang) == sym!"");

	testFileUri(test);
}

private:

@trusted void testFileUri(ref Test test) {
	ref AllUris allUris() =>
		test.allUris;

	Uri uri = parseUri(allUris, "file:///home/crow/a.txt");
	verifyUri(test, allUris, uri, ["file://", "home", "crow", "a.txt"]);
	verify(isFileUri(allUris, uri));
	TempStrForPath pathBuf = void;
	FileUri fileUri = asFileUri(allUris, uri);
	fileUriToTempStr(pathBuf, allUris, fileUri);
	SafeCStr actual = SafeCStr(cast(immutable) pathBuf.ptr);
	verify(safeCStrEq(actual, "/home/crow/a.txt"));

	FileUri ab = parseAbsoluteFilePathAsUri(allUris, "/a/b");
	verifyPath(test, allUris, ab.path, ["a", "b"]);

	verify(toUri(allUris, fileUri) == uri);
}

void verifyUri(ref Test test, in AllUris allUris, Uri a, in string[] expectedParts) {
	verifyPath(test, allUris, a.pathIncludingScheme, expectedParts);
}

void verifyPath(ref Test test, in AllUris allUris, Path a, in string[] expectedParts) {
	size_t i = 0;
	TEST_eachPart(allUris, a, (Sym x) {
		verify(i < expectedParts.length);
		verifyEq(test, x, symOfStr(test.allSymbols, expectedParts[i]));
		i++;
	});
	verify(i == expectedParts.length);
}

void verifyEq(ref Test test, Sym a, Sym b) {
	if (a != b) {
		debug {
			debugLog("Symbols not equal:");
			debugLog(cast(immutable) symAsTempBuffer!64(test.allSymbols, a).ptr);
			debugLog(cast(immutable) symAsTempBuffer!64(test.allSymbols, b).ptr);
		}
		verifyFail();
	}
}
