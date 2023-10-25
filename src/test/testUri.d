module test.testUri;

@safe @nogc pure nothrow:

import test.testUtil : Test;
import util.col.str : safeCStr, safeCStrEq;
import util.comparison : Comparison;
import util.opt : force, has, none, Opt, some;
import util.ptr : ptrTrustMe;
import util.sym : sym;
import util.uri :
	AllUris,
	childUri,
	commonAncestor,
	compareUriAlphabetically,
	getExtension,
	Path,
	parseUri,
	parseUriWithCwd,
	rootPath,
	Uri,
	uriToSafeCStr;
import util.util : verify;

void testUri(ref Test test) {
	AllUris allUris = AllUris(test.allocPtr, ptrTrustMe(test.allSymbols));
	Uri a = parseUri(allUris, "file:/a");
	Uri b = parseUri(allUris, "file:/b");
	verify(compareUriAlphabetically(allUris, a, a) == Comparison.equal);
	verify(compareUriAlphabetically(allUris, a, b) == Comparison.less);

	verify(safeCStrEq(uriToSafeCStr(test.alloc, allUris, a), safeCStr!"file:/a"));

	Uri aX = childUri(allUris, a, sym!"x");
	verify(childUri(allUris, a, sym!"x") == aX);
	Uri aY = childUri(allUris, a, sym!"y");
	verify(aX != aY);
	verify(safeCStrEq(uriToSafeCStr(test.alloc, allUris, aX), safeCStr!"file:/a/x"));
	verify(safeCStrEq(uriToSafeCStr(test.alloc, allUris, aY), safeCStr!"file:/a/y"));

	Uri zW = parseUriWithCwd(allUris, aX, safeCStr!"/z/w.crow");
	verify(safeCStrEq(uriToSafeCStr(test.alloc, allUris, zW), safeCStr!"/z/w.crow"));
	verify(getExtension(allUris, zW) == sym!".crow");
	Uri aXZW = parseUriWithCwd(allUris, aX, safeCStr!"./z/w");
	verify(safeCStrEq(uriToSafeCStr(test.alloc, allUris, aXZW), safeCStr!"a/x/z/w"));
	verify(aXZW == parseUriWithCwd(allUris, aX, safeCStr!"z/w"));
	verify(aY == parseUriWithCwd(allUris, aX, safeCStr!"../y"));

	verify(eq(commonAncestor(allUris, [aX, aY]), some(a)));
	verify(eq(commonAncestor(allUris, [aX, aXZW]), some(aX)));
	verify(eq(commonAncestor(allUris, [aX, aXZW, aY]), some(a)));
	verify(eq(commonAncestor(allUris, [aX, parseUri(allUris, "http://crow-lang.org")]), none!Uri));
}

bool eq(in Opt!Uri a, in Opt!Uri b) =>
	has(a)
		? has(b) && force(a) == force(b)
		: !has(b);
