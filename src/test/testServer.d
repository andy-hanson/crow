module test.testServer;

@safe @nogc pure nothrow:

import lib.server : addOrChangeFile, getFile, Server;
import test.testUtil : Test;
import util.alloc.rangeAlloc : RangeAlloc;
import util.collection.arr : Arr, begin, size;
import util.collection.arrUtil : fillArrUninitialized;
import util.collection.str : Str, strEq, strLiteral, strOfCStr;
import util.path : StorageKind;
import util.util : verify;

@trusted void testServer(Debug, Alloc)(ref Test!(Debug, Alloc) test) {
	Arr!ubyte bytes = fillArrUninitialized!ubyte(test.alloc, 256);
	Server!RangeAlloc server = Server!RangeAlloc(RangeAlloc(begin(bytes), size(bytes)));
	immutable Str path = strLiteral("main");
	immutable Str content = strLiteral("content");
	addOrChangeFile(test.dbg, server, StorageKind.local, path, content);
	immutable Str res = strOfCStr(getFile(server, StorageKind.local, path));
	verify(strEq(res, content));
}
