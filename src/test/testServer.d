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
	immutable SafeCStr path = safeCStr!"main";
	immutable SafeCStr content = safeCStr!"content";
	addOrChangeFile(server, path, content);
	immutable SafeCStr res = getFile(server, path);
	verify(safeCStrEq(res, content));
}
