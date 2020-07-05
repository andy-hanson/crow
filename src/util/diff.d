module util.diff;

@safe @nogc pure nothrow:

import util.collection.arr : Arr;
import util.sym : Sym;
import util.writer : Writer;
import util.util : todo;

void diffSymbols(Alloc)(
	ref Writer!Alloc writer,
	immutable Arr!Sym a,
	immutable Arr!Sym b
) {
	todo!void("diffSymbols");
}
