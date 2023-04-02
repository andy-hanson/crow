module test.testServer;

@safe @nogc pure nothrow:

import lib.server : addOrChangeFile, getFile, Server;
import test.testUtil : Test;
import util.alloc.alloc : Alloc, withStackAlloc;
import util.col.str : SafeCStr, safeCStr, safeCStrEq;
import util.util : verify;

@trusted void testServer(ref Test test) {
	withStackAlloc!0x1000((ref Alloc alloc) {
		Server server = Server(alloc.move());
		SafeCStr path = safeCStr!"main";
		SafeCStr content = safeCStr!"content";
		addOrChangeFile(server, path, content);
		SafeCStr res = getFile(server, path);
		verify(safeCStrEq(res, content));
	});
}
