module test.testServer;

@safe @nogc pure nothrow:

import frontend.storage : FileContent, ReadFileResult;
import lib.server : getProgramForMain, Server, setFile, showDiagnostics;
import test.testUtil : assertEqual, setupTestServer, Test, withTestServer;
import util.alloc.alloc : Alloc;
import util.col.str : SafeCStr, safeCStr;
import util.uri : parseUri, Uri;

void testServer(ref Test test) {
	withTestServer(test, (ref Alloc alloc, ref Server server) {
		Uri mainUri = parseUri(server.allUris, "test:///main.crow");
		setupTestServer(test, alloc, server, mainUri, safeCStr!"");

		SafeCStr showDiags() =>
			showDiagnostics(alloc, server, getProgramForMain(alloc, server, mainUri));

		assertEqual(showDiags(), safeCStr!expectedDiags1);

		setFile(test.perf, server, mainUri, ReadFileResult(FileContent(safeCStr!newContent)));
		assertEqual(showDiags(), safeCStr!"");
	});
}

private:

enum expectedDiags1 = "test:///main.crow 1:1-1:1 module should have a function:
	main void()
or:
	main nat64^(args string[])";

enum newContent = "main void()
	info log \"hello, world!\"";

