module test.testServer;

@safe @nogc pure nothrow:

import lib.server : setFileFromTemp, getFile, Server;
import test.testUtil : Test;
import util.alloc.alloc : Alloc, withStackAlloc;
import util.col.str : SafeCStr, safeCStr, safeCStrEq;
import util.opt : force, Opt;
import util.storage : asSafeCStr, FileContent;
import util.uri : parseUri, Uri;
import util.util : verify;

@trusted void testServer(ref Test test) {
	withStackAlloc!0x1000((ref Alloc alloc) {
		Server server = Server(alloc.move());
		Uri uri = parseUri(server.allUris, "main.crow");
		SafeCStr content = safeCStr!"content";
		setFileFromTemp(server, uri, content);
		Opt!FileContent res = getFile(test.alloc, server, uri);
		verify(safeCStrEq(asSafeCStr(force(res)), content));
	});
}
