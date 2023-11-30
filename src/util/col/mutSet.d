module util.col.mutSet;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc;
import util.col.map : KeyValuePair;
import util.col.mutMap :
	mustAddToMutMap, mayDelete, mustDelete, MutMap, mutMapEachKey, mutMapHasKey, mutMapPopArbitrary, setInMap;
import util.opt : force, has, MutOpt, noneMut, someMut;

struct MutSet(T) {
	private MutMap!(T, ubyte[0]) inner;

	int opApply(in int delegate(T) @safe @nogc pure nothrow cb) scope {
		mutMapEachKey!(T, ubyte[0])(inner, (T key) {
			int x = cb(key);
			assert(x == 0);
		});
		return 0;
	}
	int opApply(in int delegate(const T) @safe @nogc pure nothrow cb) scope const {
		mutMapEachKey!(T, ubyte[0])(inner, (const T key) {
			int x = cb(key);
			assert(x == 0);
		});
		return 0;
	}
}

bool mutSetHas(T)(in MutSet!T a, in T value) {
	return mutMapHasKey(a.inner, value);
}

MutOpt!T mutSetPopArbitrary(T)(ref MutSet!T a) {
	MutOpt!(KeyValuePair!(T, ubyte[0])) res = mutMapPopArbitrary(a.inner);
	return has(res) ? someMut(force(res).key) : noneMut!T;
}

void mayAddToMutSet(T)(ref Alloc alloc, scope ref MutSet!T a, T value) {
	setInMap(alloc, a.inner, value, []);
}

void mustAddToMutSet(T)(ref Alloc alloc, scope ref MutSet!T a, T value) {
	mustAddToMutMap(alloc, a.inner, value, []);
}

bool mutSetMayDelete(T)(scope ref MutSet!T a, T value) {
	MutOpt!(ubyte[0]) res = mayDelete(a.inner, value);
	return has(res);
}

void mutSetMustDelete(T)(scope ref MutSet!T a, T value) {
	mustDelete(a.inner, value);
}
