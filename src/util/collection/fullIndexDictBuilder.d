module util.collection.fullIndexDictBuilder;

@safe @nogc pure nothrow:

import util.bools : Bool, False, True;
import util.collection.arr : Arr;
import util.collection.arrUtil : fillArr_mut, fillArrUninitialized;
import util.collection.fullIndexDict :
	emptyFullIndexDict_mut,
	FullIndexDict,
	fullIndexDictGet,
	fullIndexDictSet,
	fullIndexDictOfArr_mut;
import util.opt : none, Opt, some;
import util.util : verify;

//TODO:MOVE
struct FullIndexDictBuilder(K, V) {
	private:
	FullIndexDict!(K, immutable V) values;
	FullIndexDict!(K, Bool) filled;
}

@trusted immutable(FullIndexDict!(K, V)) finishFullIndexDict(K, V)(ref FullIndexDictBuilder!(K, V) builder) {
	immutable FullIndexDict!(K, V) res = cast(immutable FullIndexDict!(K, V)) builder.values;
	builder.values = emptyFullIndexDict_mut!(K, immutable V);
	builder.filled = emptyFullIndexDict_mut!(K, Bool);
	return res;
}

@trusted FullIndexDictBuilder!(K, V) newFullIndexDictBuilder(K, V, Alloc)(ref Alloc alloc, immutable size_t size) {
	return FullIndexDictBuilder!(K, V)(
		fullIndexDictOfArr_mut!(K, immutable V)(fillArrUninitialized!(immutable V)(alloc, size)),
		fullIndexDictOfArr_mut!(K, Bool)(fillArr_mut!(Bool, Alloc)(alloc, size, (immutable size_t) => Bool(false))));
}

void fullIndexDictBuilderAdd(K, V)(ref FullIndexDictBuilder!(K, V) builder, immutable K key, immutable V value) {
	verify(!fullIndexDictBuilderHas(builder, key));
	fullIndexDictSet(builder.values, key, value);
	fullIndexDictSet(builder.filled, key, True);
	verify(fullIndexDictBuilderHas(builder, key));
}

immutable(Bool) fullIndexDictBuilderHas(K, V)(ref const FullIndexDictBuilder!(K, V) builder, immutable K key) {
	return fullIndexDictGet(builder.filled, key);
}

immutable(Opt!V) fullIndexDictBuilderOptGet(K, V)(ref const FullIndexDictBuilder!(K, V) builder, immutable K key) {
	return fullIndexDictBuilderHas(builder, key)
		? some(fullIndexDictGet(builder.values, key))
		: none!V;
}
