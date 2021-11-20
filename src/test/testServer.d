// TODO: commenting out due to https://issues.dlang.org/show_bug.cgi?id=22526
// We get compile errors if more than one `Extern` implementation is used in the same compile.
/*
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

@trusted void testServer(ref Test test) {
	ubyte[] bytes = fillArrUninitialized!ubyte(test.alloc, 256);
	Server server = Server(RangeAlloc(begin(bytes), size(bytes)));
	immutable string path = "main";
	immutable string content = "content";
	addOrChangeFile(test.dbg, server, StorageKind.local, path, content);
	immutable string res = strOfCStr(getFile(server, StorageKind.local, path));
	verify(strEq(res, content));
}
*/