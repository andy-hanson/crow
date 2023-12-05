module util.alloc.doubleLink;

@safe @nogc pure nothrow:

import util.opt : MutOpt, noneMut, someMut;

// `link` should be a function from `inout T*`` to `ref inout DoubleLink!T*``.
struct DoubleLink(T) {
	private:
	// These will be null for the ends of the list
	T* prev;
	T* next;
}

// May be null
ref inout(T*) prev(alias link, T)(inout T* a) =>
	link(a).prev;
// May be null
ref inout(T*) next(alias link, T)(inout T* a) =>
	link(a).next;

bool isStartOfList(alias link, T)(in T* a) =>
	prev!link(a) == null;
bool isEndOfList(alias link, T)(in T* a) =>
	next!link(a) == null;
bool isUnlinked(alias link, T)(in T* a) =>
	prev!link(a) == null && next!link(a) == null;

// Removes nodes from the list (starting from the last) and calls `cb`` on each after it is removed.
void removeAllFromListAnd(alias link, T)(T* last, void delegate(T*) @safe @nogc pure nothrow cb) {
	while (true) {
		assert(isEndOfList!link(last));
		T* left = prev!link(last);
		prev!link(last) = null;
		assert(isUnlinked!link(last));
		if (left == null)
			break;
		else {
			next!link(left) = null;
			cb(last);
			last = left;
		}
	}
}

// Does not consider the current node (or to its left)
MutOpt!(T*) findNodeToRight(alias link, T)(T* a, in bool delegate(in T*) @safe @nogc pure nothrow cb) {
	T* next = next!link(a);
	return next == null
		? noneMut!(T*)
		: cb(next)
		? someMut(next)
		: findNodeToRight!link(next, cb);
}

bool existsHereOrPrev(alias link, T)(in T* a, in bool delegate(in T*) @safe @nogc pure nothrow cb) =>
	cb(a) || (prev!link(a) != null && existsHereOrPrev!link(prev!link(a), cb));

void eachHereAndNext(alias link, T)(in T* a, in void delegate(in T*) @safe @nogc pure nothrow cb) {
	cb(a);
	eachNextNode!link(a, cb);
}

void eachPrevNode(alias link, T)(in T* a, in void delegate(in T*) @safe @nogc pure nothrow cb) {
	assert(isEndOfList!link(a));
	const(T)* node = prev!link(a);
	while (node != null) {
		cb(node);
		node = prev!link(node);
	}
}

private void eachNextNode(alias link, T)(in T* a, in void delegate(in T*) @safe @nogc pure nothrow cb) {
	assert(isStartOfList!link(a));
	const(T)* node = next!link(a);
	while (node != null) {
		cb(node);
		node = next!link(node);
	}
}

void removeFromList(alias link, T)(T* a) {
	assert(!isUnlinked!link(a));
	if (prev!link(a) != null)
		next!link(prev!link(a)) = next!link(a);
	if (next!link(a) != null)
		prev!link(next!link(a)) = prev!link(a);
	prev!link(a) = null;
	next!link(a) = null;
	assert(isUnlinked!link(a));
}

// Inserts 'new_' between 'left' and 'left.next' (or at the end if 'left' was the end before)
void insertToRight(alias link, T)(T* left, T* new_) {
	assert(isUnlinked!link(new_));
	prev!link(new_) = left;
	next!link(new_) = next!link(left);
	next!link(left) = new_;
	if (next!link(new_) != null)
		prev!link(next!link(new_)) = new_;
}

void insertToLeft(alias link, T)(T* right, T* new_) {
	assert(isUnlinked!link(new_));
	prev!link(new_) = prev!link(right);
	next!link(new_) = right;
	prev!link(right) = new_;
	if (prev!link(new_) != null)
		next!link(prev!link(new_)) = new_;
}
