module test.testServer;

@safe @nogc pure nothrow:

import frontend.storage : ReadFileResult;
import lib.server : getProgramForMain, Server, setFile, showDiagnostics;
import model.diag : ReadFileDiag;
import test.testUtil : assertEqual, defaultIncludeResult, setupTestServer, Test, withTestServer;
import util.alloc.alloc : Alloc;
import util.col.array : concatenate;
import util.uri : concatUriAndPath, parsePath, mustParseUri, Uri;

void testServer(ref Test test) {
	testCircularImportFixed(test);
	testFileNotFoundThenAdded(test);
	testFileImportNotFound(test);
	testChangeBootstrap(test);
}

private:

void testCircularImportFixed(ref Test test) {
	withTestServer(test, (ref Alloc alloc, ref Server server) {
		Uri uriA = mustParseUri(server.allUris, "test:///a.crow");
		Uri uriB = mustParseUri(server.allUris, "test:///b.crow");
		setupTestServer(test, alloc, server, uriA, "");

		string showDiags() =>
			showDiagnostics(alloc, server, getProgramForMain(test.perf, alloc, server, uriA).program);

		assertEqual(showDiags(), expectedDiags1);

		setFile(test.perf, server, uriA, "main void()\n\tinfo log \"hello, world!\"");
		assertEqual(showDiags(), "");

		setFile(test.perf, server, uriB, "import\n\t./a");
		assertEqual(showDiags(), "test:///b.crow 2:5-2:8 Imported module 'a.crow' is unused.");

		setFile(test.perf, server, uriA, "import\n\t./b\n\nmain void()\n\tinfo log hello");
		assertEqual(showDiags(), expectedDiags2);

		setFile(test.perf, server, uriB, "hello string()\n\t\"hello\"");
		assertEqual(showDiags(), "");
	});
}

void testFileNotFoundThenAdded(ref Test test) {
	withTestServer(test, (ref Alloc alloc, ref Server server) {
		Uri uriA = mustParseUri(server.allUris, "test:///a.crow");
		Uri uriB = mustParseUri(server.allUris, "test:///b.crow");
		setupTestServer(test, alloc, server, uriA, "import\n\t./b\n\nmain void()\n\tinfo log hello");
		string showDiags() =>
			showDiagnostics(alloc, server, getProgramForMain(test.perf, alloc, server, uriA).program);

		string bDoesNotExist = "test:///a.crow 2:5-2:8 Imported file test:///b.crow does not exist.\n" ~
			"test:///b.crow 1:1-1:1 This file does not exist.";
		assertEqual(showDiags(), bDoesNotExist);

		setFile(test.perf, server, uriB, "hello string()\n\t\"hello\"");
		assertEqual(showDiags(), "");

		setFile(test.perf, server, uriB, ReadFileResult(ReadFileDiag.notFound));
		assertEqual(showDiags(), bDoesNotExist);
	});
}

void testFileImportNotFound(ref Test test) {
	withTestServer(test, (ref Alloc alloc, ref Server server) {
		Uri uriA = mustParseUri(server.allUris, "test:///a.crow");
		Uri uriB = mustParseUri(server.allUris, "test:///b.txt");
		Uri uriB2 = mustParseUri(server.allUris, "test:///b2.txt");
		setFile(test.perf, server, uriB, "hello");

		string showDiags() =>
			showDiagnostics(alloc, server, getProgramForMain(test.perf, alloc, server, uriA).program);

		string original = "import\n\t./b.txt as b string\n\nmain void()\n\t()";
		setupTestServer(test, alloc, server, uriA, original);
		assertEqual(showDiags(), "");

		setFile(test.perf, server, uriA, "import\n\t./b2.txt as string\n\nmain void()\n\t()");
		setFile(test.perf, server, uriB2, ReadFileResult(ReadFileDiag.notFound));
		assertEqual(showDiags(), "test:///a.crow 2:5-2:13 Imported file test:///b2.txt does not exist.");

		setFile(test.perf, server, uriA, original);
		assertEqual(showDiags(), "");
	});
}

void testChangeBootstrap(ref Test test) {
	withTestServer(test, (ref Alloc alloc, ref Server server) {
		Uri uriA = mustParseUri(server.allUris, "test:///a.crow");
		setupTestServer(test, alloc, server, uriA, "main void()\n\t()");
		string showDiags() =>
			showDiagnostics(alloc, server, getProgramForMain(test.perf, alloc, server, uriA).program);

		assertEqual(showDiags(), "");

		string bootstrapPath = "crow/private/bootstrap.crow";
		Uri bootstrap = concatUriAndPath(server.allUris, server.includeDir, parsePath(server.allUris, bootstrapPath));
		string defaultBootstrap = defaultIncludeResult(bootstrapPath);
		setFile(test.perf, server, bootstrap, concatenate(alloc, defaultBootstrap, "junk"));
		assertEqual(showDiags(),
			"test:///include/crow/private/bootstrap.crow 371:5-371:5 Unexpected end of file.\n" ~
			"test:///include/crow/private/bootstrap.crow 371:5-371:5 Expected '('.");

		setFile(test.perf, server, bootstrap, defaultBootstrap);
		assertEqual(showDiags(), "");
	});
}

enum expectedDiags1 = "test:///a.crow 1:1-1:1 Module should have a function:
	main void()
Or:
	main nat64^(args string[])";

enum expectedDiags2 = "test:///a.crow 2:5-2:8 This is part of a circular import:
	test:///a.crow imports
	test:///b.crow imports
	test:///a.crow
test:///b.crow 2:5-2:8 This is part of a circular import:
	test:///b.crow imports
	test:///a.crow imports
	test:///b.crow";
