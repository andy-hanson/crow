module util.alloc.dlList;

@safe @nogc pure nothrow:

struct DLListNode(T) {
	DLListNode!T* prev;
	DLListNode!T* next;
	T value;
}

// Removes nodes from the list (starting from the last) and calls 'cb' on each after it is removed.
void removeAllFromListAnd(T)(DLListNode!T* last, void delegate(DLListNode!T*) @safe @nogc pure nothrow cb) {
	do {
		assert(last.next == null);
		DLListNode!T* prev = last.prev;
		last.prev = null;
		if (prev != null) prev.next = null;
		assert(isUnlinked(last));
		cb(last);
		last = prev;
	} while (last != null);
}

bool isUnlinked(T)(in DLListNode!T* a) =>
	a.prev == null && a.next == null;

bool existsHereAndPrev(T)(in DLListNode!T* a, in bool delegate(in DLListNode!T*) @safe @nogc pure nothrow cb) =>
	cb(a) || (a.prev != null && existsHereAndPrev(a.prev, cb));

void eachHereAndPrev(T)(in DLListNode!T* a, in void delegate(in DLListNode!T*) @safe @nogc pure nothrow cb) {
	cb(a);
	eachPrevNode(a, cb);
}

void eachNextNode(T)(in DLListNode!T* a, in void delegate(in DLListNode!T*) @safe @nogc pure nothrow cb) {
	const(DLListNode!T)* node = a.next;
	while (node != null) {
		cb(node);
		node = node.next;
	}
}

void eachPrevNode(T)(in DLListNode!T* a, in void delegate(in DLListNode!T*) @safe @nogc pure nothrow cb) {
	const(DLListNode!T)* node = a.prev;
	while (node != null) {
		cb(node);
		node = node.prev;
	}
}

void removeFromList(T)(DLListNode!T* a) {
	assert(!isUnlinked(a));
	if (a.prev != null)
		a.prev.next = a.next;
	if (a.next != null)
		a.next.prev = a.prev;
	a.prev = null;
	a.next = null;
}

void insertToRight(T)(DLListNode!T* left, DLListNode!T* new_) {
	assert(isUnlinked(new_));
	new_.prev = left;
	new_.next = left.next;
	left.next = new_;
	if (new_.next != null)
		new_.next.prev = new_;
}
