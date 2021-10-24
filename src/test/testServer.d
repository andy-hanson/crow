module test.testServer;

@safe @nogc pure nothrow:

import lib.server : addOrChangeFile, getFile, Server;
import test.testUtil : Test;
import util.alloc.rangeAlloc : RangeAlloc;
import util.collection.arr : begin, size;
import util.collection.arrUtil : fillArrUninitialized;
import util.collection.str : strEq, strOfCStr;
import util.path : StorageKind;
import util.util : verify;

@trusted void testServer(Debug)(ref Test!Debug test) {
	ubyte[] bytes = fillArrUninitialized!ubyte(test.alloc.deref(), 256);
	Server server = Server(RangeAlloc(begin(bytes), size(bytes)));
	immutable string path = "main";
	immutable string content = "content";
	addOrChangeFile(test.dbg, server, StorageKind.local, path, content);
	immutable string res = strOfCStr(getFile(server, StorageKind.local, path));
	verify(strEq(res, content));
}
