module util.col.mutMultiMap;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc, allocateElements;
import util.col.mutMap : addOrChange, mayDelete, MutMap;
import util.memory : initMemory;
import util.opt : force, has, MutOpt, noneMut, someMut;

struct MutMultiMap(K, V) {
	private:
	MutMap!(K, Head!V) heads;
	MutOpt!(Node!V*) freeList;
}

// Use a different struct than 'Node' to ensure this is never pointed to
private struct Head(V) {
	V value;
	MutOpt!(Node!V*) last;
}

private struct Node(T) {
	T value;
	// For a used node, this points to the next node in the list.
	// For a free node, this points to the next free node.
	MutOpt!(Node*) next;
}

void add(K, V)(ref Alloc alloc, ref MutMultiMap!(K, V) a, K key, V value) {
	addOrChange!(K, Head!V)(alloc, a.heads, key, () => Head!V(value, noneMut!(Node!V*)), (ref Head!V head) {
		Node!V* node = newNode(alloc, a, value);
		if (has(head.last))
			force(head.last).next = someMut(node);
		head.last = someMut(node);
	});
}

void mayDeleteAndFree(K, V)(
	ref Alloc alloc,
	ref MutMultiMap!(K, V) a,
	K key,
	in void delegate(V) @safe @nogc pure nothrow cb,
) {
	MutOpt!(Head!V) deleted = mayDelete(a.heads, key);
	if (has(deleted)) {
		cb(force(deleted).value);
		MutOpt!(Node!V*) cur = force(deleted).last;
		while (has(cur)) {
			cb(force(cur).value);
			MutOpt!(Node!V*) next = force(cur).next;
			force(cur).next = a.freeList;
			a.freeList = cur;
			cur = next;
		}
	}
}

private:

@trusted Node!V* newNode(K, V)(ref Alloc alloc, ref MutMultiMap!(K, V) a, V value) {
	if (!has(a.freeList))
		a.freeList = someMut(allocateMoreNodes!V(alloc));
	Node!V* res = force(a.freeList);
	a.freeList = res.next;
	initMemory(&res.value, value);
	res.next = noneMut!(Node!V*);
	return res;
}

@system Node!V* allocateMoreNodes(V)(ref Alloc alloc) {
	Node!V[] nodes = allocateElements!(Node!V)(alloc, 0x100);
	foreach (size_t i; 0 .. nodes.length - 1)
		nodes[i].next = someMut(&nodes[i + 1]);
	nodes[$ - 1].next = noneMut!(Node!V*);
	return &nodes[0];
}
