module util.col.mutMap;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc;
import util.col.hashTable :
	clearAndFreeMemory,
	HashTable,
	getOrAdd,
	getOrAddAndDidAdd,
	hasKey,
	insertOrUpdate,
	isEmpty,
	mapPreservingKeys,
	mapToArray,
	mayDelete,
	mustAdd,
	mustDelete,
	mustGet,
	size;
import util.col.map : Map;
import util.opt : ConstOpt, force, has, MutOpt, none, noneMut, Opt, some, someConst, someMut;
import util.ptr : ptrTrustMe;

public import util.col.hashTable : ValueAndDidAdd;

struct MutMap(K, V) {
	@safe @nogc pure nothrow:

	private HashTable!(KeyValuePair!(K, V), K, getKey) inner;

	Opt!V opIndex(in K key) immutable {
		Opt!(KeyValuePair!(K, V)) res = inner[key];
		return has(res) ? some!V(force(res).value) : none!V;
	}
	ConstOpt!V opIndex(in K key) const {
		ConstOpt!(KeyValuePair!(K, V)) res = inner[key];
		return has(res) ? someConst!V(force(res).value) : noneMut!V;
	}
	MutOpt!V opIndex(in K key) {
		MutOpt!(KeyValuePair!(K, V)) res = inner[key];
		return has(res) ? someMut!V(force(res).value) : noneMut!V;
	}

	int opApply(in int delegate(immutable K, ref immutable V) @safe @nogc pure nothrow cb) scope immutable =>
		inner.opApply((ref immutable KeyValuePair!(K, V) pair) =>
			cb(pair.key, pair.value));
	int opApply(in int delegate(const K, ref const V) @safe @nogc pure nothrow cb) scope const =>
		inner.opApply((ref const KeyValuePair!(K, V) pair) =>
			cb(pair.key, pair.value));
	int opApply(in int delegate(K, ref V) @safe @nogc pure nothrow cb) scope =>
		inner.opApply((ref KeyValuePair!(K, V) pair) =>
			cb(pair.key, pair.value));
}

private inout(K) getKey(K, V)(return scope ref inout KeyValuePair!(K, V) a) =>
	a.key;

private struct MutMapKeys(K, V) {
	@safe @nogc pure nothrow:

	MutMap!(K, V)* inner;

	int opApply(in int delegate(ref const K) @safe @nogc pure nothrow cb) scope const =>
		inner.opApply((const K key, ref const V _) => cb(key));
}
const(MutMapKeys!(K, V)) keys(K, V)(ref const MutMap!(K, V) a) =>
	const MutMapKeys!(K, V)(ptrTrustMe(a));

struct MutMapValues(K, V) {
	@safe @nogc pure nothrow:

	MutMap!(K, V)* inner;

	int opApply(in int delegate(ref immutable V) @safe @nogc pure nothrow cb) scope immutable =>
		inner.opApply((immutable K _, ref immutable V value) => cb(value));
	int opApply(in int delegate(ref const V) @safe @nogc pure nothrow cb) scope const =>
		inner.opApply((const K _, ref const V value) => cb(value));
	int opApply(in int delegate(ref V) @safe @nogc pure nothrow cb) scope =>
		inner.opApply((K _, ref V value) => cb(value));
}
inout(MutMapValues!(K, V)) values(K, V)(return scope inout ref MutMap!(K, V) a) =>
	inout MutMapValues!(K, V)(ptrTrustMe(a));

struct KeyValuePair(K, V) {
	K key;
	V value;
}

bool mutMapIsEmpty(K, V)(in MutMap!(K, V) a) =>
	isEmpty(a.inner);

size_t mutMapSize(K, V)(in MutMap!(K, V) a) =>
	size(a.inner);

bool mutMapHasKey(K, V)(in MutMap!(K, V) a, in K key) =>
	hasKey(a.inner, key);

ref inout(V) mutMapMustGet(K, V)(ref inout MutMap!(K, V) a, in K key) =>
	.mustGet(a.inner, key).value;

void mustAddToMutMap(K, V)(ref Alloc alloc, scope ref MutMap!(K, V) a, K key, V value) {
	mustAdd(alloc, a.inner, KeyValuePair!(K, V)(key, value));
}

// TODO: opIndexAssign
ref KeyValuePair!(K, V) setInMap(K, V)(ref Alloc alloc, scope ref MutMap!(K, V) a, K key, V value) =>
	insertOrUpdate!(K, V)(alloc, a, key, () => value, (in V _) => value);

ValueAndDidAdd!V getOrAddAndDidAdd(K, V)(
	ref Alloc alloc,
	ref MutMap!(K, V) a,
	scope K key,
	in V delegate() @safe @nogc pure nothrow getValue,
) {
	ValueAndDidAdd!(KeyValuePair!(K, V)) res = getOrAddPairAndDidAdd!(K, V)(alloc, a, key, () =>
		KeyValuePair!(K, V)(key, getValue()));
	return ValueAndDidAdd!V(res.value.value, res.didAdd);
}

/*
Useful for when you want to allocate the key only if it is needed.
'getKey' must return a value equivalent to 'key'.
*/
ValueAndDidAdd!(KeyValuePair!(K, V)) getOrAddPairAndDidAdd(K, V)(
	ref Alloc alloc,
	ref MutMap!(K, V) a,
	in K key,
	in KeyValuePair!(K, V) delegate() @safe @nogc pure nothrow getPair,
) =>
	.getOrAddAndDidAdd!(KeyValuePair!(K, V), K, getKey)(alloc, a.inner, key, getPair);

ref V getOrAdd(K, V)(
	ref Alloc alloc,
	return scope ref MutMap!(K, V) a,
	K key,
	in V delegate() @safe @nogc pure nothrow getValue,
) =>
	getOrAddPair(alloc, a, key, () => KeyValuePair!(K, V)(key, getValue())).value;

ref KeyValuePair!(K, V) getOrAddPair(K, V)(
	ref Alloc alloc,
	return scope ref MutMap!(K, V) a,
	scope K key,
	in KeyValuePair!(K, V) delegate() @safe @nogc pure nothrow getPair,
) =>
	getOrAdd(alloc, a.inner, key, getPair);

@trusted ref KeyValuePair!(K, V) insertOrUpdate(K, V)(
	ref Alloc alloc,
	return scope ref MutMap!(K, V) a,
	K key,
	in V delegate() @safe @nogc pure nothrow cbInsert,
	in V delegate(in V) @safe @nogc pure nothrow cbUpdate,
) =>
	.insertOrUpdate!(KeyValuePair!(K, V), K, getKey)(
		alloc, a.inner, key,
		() => KeyValuePair!(K, V)(key, cbInsert()),
		(ref KeyValuePair!(K, V) old) => KeyValuePair!(K, V)(old.key, cbUpdate(old.value)));

MutOpt!V mayDelete(K, V)(scope ref MutMap!(K, V) a, in K key) {
	MutOpt!(KeyValuePair!(K, V)) res = .mayDelete(a.inner, key);
	return has(res) ? someMut(force(res).value) : noneMut!V;
}

V mustDelete(K, V)(ref MutMap!(K, V) a, in K key) =>
	.mustDelete(a.inner, key).value;

Out[] mapToArray(Out, K, V)(
	ref Alloc alloc,
	scope ref immutable MutMap!(K, V) a,
	in Out delegate(immutable K, ref immutable V) @safe @nogc pure nothrow cb,
) =>
	.mapToArray!Out(alloc, a.inner, (ref immutable KeyValuePair!(K, V) x) =>
		cb(x.key, x.value));
private @trusted Out[] mapToArray_const(Out, K, V)(
	ref Alloc alloc,
	in MutMap!(K, V) a,
	in Out delegate(immutable K, ref const V) @safe @nogc pure nothrow cb,
) =>
	mapToArray!(Out, KeyValuePair!(K, V), K, getKey)(alloc, a.inner, (ref const KeyValuePair!(K, V) x) =>
		cb(x.key, x.value));
@trusted Out[] mapToArray_mut(Out, K, V)(
	ref Alloc alloc,
	scope ref MutMap!(K, V) a,
	in Out delegate(immutable K, ref V) @safe @nogc pure nothrow cb,
) =>
	mapToArray!Out(alloc, a.inner, (ref KeyValuePair!(K, V) x) =>
		cb(x.key, x.value));

immutable(V[]) moveToValues(K, V)(ref Alloc alloc, ref MutMap!(immutable K, immutable V) a) {
	immutable V[] res = valuesArray(alloc, a);
	clearAndFreeMemory(alloc, a.inner);
	return res;
}

@trusted immutable(Map!(K, V)) moveToMap(K, V)(ref Alloc alloc, ref MutMap!(K, V) a) {
	immutable Map!(K, V) res = immutable Map!(K, V)(cast(immutable) a);
	a.inner = HashTable!(KeyValuePair!(K, V), K, getKey)();
	return res;
}

@trusted Map!(K, VOut) mapToMap(K, VOut, VIn)(
	ref Alloc alloc,
	scope ref MutMap!(K, VIn) a,
	in immutable(VOut) delegate(ref VIn) @safe @nogc pure nothrow cb,
) {
	HashTable!(KeyValuePair!(K, VOut), K, getKey) out_ =
		mapPreservingKeys!(KeyValuePair!(K, VOut), getKey, KeyValuePair!(K, VIn), K, getKey)(
			alloc,
			a.inner,
			(ref KeyValuePair!(K, VIn) x) => KeyValuePair!(K, VOut)(x.key, cb(x.value)));
	return Map!(K, VOut)(immutable MutMap!(K, VOut)(cast(immutable) out_));
}

immutable(V[]) valuesArray(K, V)(ref Alloc alloc, in MutMap!(K, V) a) =>
	mapToArray_const!(V, K, V)(alloc, a, (immutable(K), ref V v) => v);

MutOpt!V findInMutMap(K, V)(ref MutMap!(K, V) a, in bool delegate(in K, in V) @safe @nogc pure nothrow cb) {
	foreach (K key, ref V value; a)
		if (cb(key, value))
			return someMut(value);
	return noneMut!V;
}
