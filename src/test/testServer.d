module test.testServer;

@safe @nogc pure nothrow:

import lib.server : addOrChangeFile, getFile, Server;
import test.testUtil : Test;
import util.alloc.rangeAlloc : RangeAlloc;
import util.collection.arrUtil : fillArrUninitialized;
import util.collection.str : SafeCStr, safeCStr, safeCStrEq, strOfSafeCStr;
import util.path : StorageKind;
import util.util : verify;

@trusted void testServer(ref Test test) {
	ubyte[] bytes = fillArrUninitialized!ubyte(test.alloc, 256);
	Server server = Server(RangeAlloc(bytes.ptr, bytes.length));
	immutable string path = "main";
	immutable SafeCStr content = safeCStr!"content";
	addOrChangeFile(test.dbg, server, StorageKind.local, path, strOfSafeCStr(content));
	immutable SafeCStr res = getFile(server, StorageKind.local, path);
	verify(safeCStrEq(res, content));
}
