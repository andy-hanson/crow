module test.testServer;

@safe @nogc pure nothrow:

import lib.server : addOrChangeFile, getFile, Server;
import test.testUtil : Test;
import util.alloc.alloc : Alloc;
import util.col.arrUtil : allocateUninitialized;
import util.col.str : SafeCStr, safeCStr, safeCStrEq;
import util.util : verify;

@trusted void testServer(ref Test test) {
	ubyte[] bytes = allocateUninitialized!ubyte(test.alloc, 0x4000);
	Server server = Server(Alloc(bytes.ptr, bytes.length));
	SafeCStr path = safeCStr!"main";
	SafeCStr content = safeCStr!"content";
	addOrChangeFile(server, path, content);
	SafeCStr res = getFile(server, path);
	verify(safeCStrEq(res, content));
}
