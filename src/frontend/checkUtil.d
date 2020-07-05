module frontend.checkUtil;

@safe @nogc pure nothrow:

import util.collection.arr : Arr;
import util.ptr : Ptr;

@trusted immutable(Ptr!T) ptrAsImmutable(T)(Ptr!T a) {
	return cast(immutable) a;
}

@trusted immutable(Arr!T) arrAsImmutable(T)(Arr!T a) {
	return cast(immutable) a;
}
