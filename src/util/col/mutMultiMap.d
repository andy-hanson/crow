module util.col.mutMultiMap;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc, allocateElements;
import util.col.hashTable :
	addOrChange, getOrAddAndDidAdd, mayDelete, mustDelete, mustGet, MutHashTable, size, ValueAndDidAdd;
import util.hash : HashCode, hashPointerAndTaggedPointer, hashUlong, hashUlongs;
import util.memory : ensureMemoryClear, initMemory;
import util.opt : force, has, MutOpt, noneMut, someMut;
import util.symbol : Symbol;

/**
This acts like a MutSet of (K, V) pairs.
In addition, it can iterate all (K, V) pairs for a key.
*/
struct MutMultiMap(K, V) {
	private:
	// Gets the first pair for a key.
	MutHashTable!(Node!(K, V)*, K, getKey) heads;
	// Supports lookup by arbitrary key/value.
	// TODO:PERF We could store nodes here directly, but we'd have to update pointers if the MutHashTable moves them
	MutHashTable!(Node!(K, V)*, Pair!(K, V), getPair) pairs;
	MutOpt!(Node!(K, V)*) freeList;
}

private struct Pair(K, V) {
	@safe @nogc pure nothrow:

	K key;
	V value;

	bool opEquals(in Pair b) const =>
		key == b.key && value == b.value;

	HashCode hash() const {
		static if (is(K == uint) && is(V == uint)) // for test
			return hashUlong(((cast(ulong) key) << 32) | value);
		else static if (is(K == Symbol) && is(V == Symbol))
			return hashUlongs([key.value, value.value]);
		else
			// So far this is only used with pointers
			return hashPointerAndTaggedPointer!(K, V)(key, value);
	}
}

private struct Node(K, V) {
	K key;
	V value;
	// For used nodes, these are both used as a circular linked list.
	// For free nodes, only 'next' is used and it's nullable.
	Node!(K, V)* prev;
	Node!(K, V)* next;
}

private const(K) getKey(K, V)(in Node!(K, V)* a) =>
	a.key;

private const(Pair!(K, V)) getPair(K, V)(in Node!(K, V)* a) =>
	Pair!(K, V)(a.key, a.value);

void add(K, V)(ref Alloc alloc, ref MutMultiMap!(K, V) a, K key, V value) {
	ValueAndDidAdd!(Node!(K, V)*) addedPair = getOrAddAndDidAdd(alloc, a.pairs, Pair!(K, V)(key, value), () =>
		newNode(alloc, a, key, value));
	if (addedPair.didAdd) {
		Node!(K, V)* node = addedPair.value;
		addOrChange(
			alloc, a.heads, key,
			() {
				node.prev = node;
				node.next = node;
				return node;
			},
			(ref Node!(K, V)* curHead) {
				// Add it to the end of the list (before curHead)
				node.next = curHead;
				node.prev = curHead.prev;
				node.prev.next = node;
				node.next.prev = node;
			});
	}
}

size_t countKeys(K, V)(in MutMultiMap!(K, V) a) =>
	size(a.heads);
size_t countPairs(K, V)(in MutMultiMap!(K, V) a) =>
	size(a.pairs);

// Deletes a single value for the key
bool mayDeletePair(K, V)(scope ref MutMultiMap!(K, V) a, K key, V value) {
	MutOpt!(Node!(K, V)*) optDeleted = mayDelete(a.pairs, Pair!(K, V)(key, value));
	if (has(optDeleted)) {
		Node!(K, V)* deleted = force(optDeleted);
		assert((deleted.prev == deleted) == (deleted.next == deleted));
		if (deleted.prev == deleted) {
			assert(mustGet(a.heads, key) == deleted);
			mustDelete(a.heads, key);
		} else {
			deleted.prev.next = deleted.next;
			deleted.next.prev = deleted.prev;
			Node!(K, V)** head = &mustGet(a.heads, key);
			if (*head == deleted) {
				*head = deleted.next;
			}
		}
		returnNodeToFreeList(a, deleted);
		return true;
	} else
		return false;
}

// Deletes a key and all associated values (after calling 'cb' on the value)
void mayDeleteKey(K, V)(ref MutMultiMap!(K, V) a, in K key, in void delegate(V) @safe @nogc pure nothrow cb) {
	MutOpt!(Node!(K, V)*) deleted = mayDelete(a.heads, key);
	if (has(deleted)) {
		Node!(K, V)* head = force(deleted);
		Node!(K, V)* cur = head;
		do {
			assert(cur.key == key);
			cb(cur.value);
			mustDelete(a.pairs, Pair!(K, V)(key, cur.value));
			Node!(K, V)* next = cur.next;
			returnNodeToFreeList(a, cur);
			cur = next;
		} while (cur != head);
	}
}

void eachKey(K, V)(in MutMultiMap!(K, V) a, in void delegate(in K) @safe @nogc pure nothrow cb) {
	foreach (ref const Node!(K, V)* head; a.heads)
		cb(head.key);
}

void eachValueForKey(K, V)(in MutMultiMap!(K, V) a, in K key, in void delegate(in V) @safe @nogc pure nothrow cb) {
	const MutOpt!(Node!(K, V)*) optHead = a.heads[key];
	if (has(optHead)) {
		const Node!(K, V)* head = force(optHead);
		const(Node!(K, V))* cur = head;
		do {
			cb(cur.value);
			cur = cur.next;
		} while (cur != head);
	}
}

private:

@trusted Node!(K, V)* newNode(K, V)(ref Alloc alloc, ref MutMultiMap!(K, V) a, K key, V value) {
	if (!has(a.freeList))
		a.freeList = someMut(allocateMoreNodes!(K, V)(alloc));
	Node!(K, V)* res = force(a.freeList);
	a.freeList = res.next == null ? noneMut!(Node!(K, V)*) : someMut!(Node!(K, V)*)(res.next);
	initMemory(res, Node!(K, V)(key, value, null, null));
	return res;
}

@trusted void returnNodeToFreeList(K, V)(scope ref MutMultiMap!(K, V) a, Node!(K, V)* node) {
	ensureMemoryClear!(Node!(K, V))(node);
	node.next = has(a.freeList) ? force(a.freeList) : null;
	a.freeList = someMut(node);
}

@system Node!(K, V)* allocateMoreNodes(K, V)(ref Alloc alloc) {
	Node!(K, V)[] nodes = allocateElements!(Node!(K, V))(alloc, 0x100);
	foreach (size_t i; 0 .. nodes.length - 1)
		nodes[i].next = &nodes[i + 1];
	nodes[$ - 1].next = null;
	return &nodes[0];
}
