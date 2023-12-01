module test.testServer;

@safe @nogc pure nothrow:

import frontend.storage : FileContent, ReadFileResult;
import lib.server : getProgramForMain, Server, setFile, showDiagnostics;
import model.diag : ReadFileDiag;
import test.testUtil : assertEqual, setupTestServer, Test, withTestServer;
import util.alloc.alloc : Alloc;
import util.col.str : SafeCStr, safeCStr;
import util.uri : parseUri, Uri;

void testServer(ref Test test) {
	testCircularImportFixed(test);
	testFileNotFoundThenAdded(test);
}

private:

void testCircularImportFixed(ref Test test) {
	withTestServer(test, (ref Alloc alloc, ref Server server) {
		Uri uriA = parseUri(server.allUris, "test:///a.crow");
		Uri uriB = parseUri(server.allUris, "test:///b.crow");
		setupTestServer(test, alloc, server, uriA, safeCStr!"");

		SafeCStr showDiags() =>
			showDiagnostics(alloc, server, getProgramForMain(alloc, server, uriA));

		assertEqual(showDiags(), safeCStr!expectedDiags1);

		setFile(test.perf, server, uriA, ReadFileResult(FileContent(
			safeCStr!"main void()\n\tinfo log \"hello, world!\"")));
		assertEqual(showDiags(), safeCStr!"");

		setFile(test.perf, server, uriB, ReadFileResult(FileContent(
			safeCStr!"import\n\t./a")));
		assertEqual(showDiags(), safeCStr!"test:///b.crow 2:5-2:8 imported module 'a.crow' is unused");

		setFile(test.perf, server, uriA, ReadFileResult(FileContent(
			safeCStr!"import\n\t./b\n\nmain void()\n\tinfo log hello")));
		assertEqual(showDiags(), safeCStr!expectedDiags2);

		setFile(test.perf, server, uriB, ReadFileResult(FileContent(
			safeCStr!"hello string()\n\t\"hello\"")));
		assertEqual(showDiags(), safeCStr!"");
	});
}

void testFileNotFoundThenAdded(ref Test test) {
	withTestServer(test, (ref Alloc alloc, ref Server server) {
		Uri uriA = parseUri(server.allUris, "test:///a.crow");
		Uri uriB = parseUri(server.allUris, "test:///b.crow");
		setupTestServer(test, alloc, server, uriA, safeCStr!"import\n\t./b\n\nmain void()\n\tinfo log hello");
		SafeCStr showDiags() =>
			showDiagnostics(alloc, server, getProgramForMain(alloc, server, uriA));

		assertEqual(showDiags(), safeCStr!"test:///b.crow 1:1-1:1 File does not exist");

		setFile(test.perf, server, uriB, ReadFileResult(FileContent(safeCStr!"hello string()\n\t\"hello\"")));
		assertEqual(showDiags(), safeCStr!"");

		setFile(test.perf, server, uriB, ReadFileResult(ReadFileDiag.notFound));
		assertEqual(showDiags(), safeCStr!"test:///b.crow 1:1-1:1 File does not exist");
	});

}

enum expectedDiags1 = "test:///a.crow 1:1-1:1 module should have a function:
	main void()
or:
	main nat64^(args string[])";

enum expectedDiags2 = "test:///a.crow 2:5-2:8 this is part of a circular import:
	test:///a.crow imports
	test:///b.crow imports
	test:///a.crow
test:///b.crow 2:5-2:8 this is part of a circular import:
	test:///a.crow imports
	test:///b.crow imports
	test:///a.crow";
