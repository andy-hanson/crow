module util.alloc.doubleLink;

@safe @nogc pure nothrow:

import util.opt : ConstOpt, force, has, MutOpt, noneMut, someMut;

// `link` should be a function from `inout T*`` to `ref inout DoubleLink!T*``.
struct DoubleLink(T) {
	private:
	MutOpt!(T*) prev;
	MutOpt!(T*) next;
}

ref inout(MutOpt!(T*)) prev(alias link, T)(inout T* a) =>
	link(a).prev;
ref inout(MutOpt!(T*)) next(alias link, T)(inout T* a) =>
	link(a).next;

bool isStartOfList(alias link, T)(in T* a) =>
	!has(prev!link(a));
bool isEndOfList(alias link, T)(in T* a) =>
	!has(next!link(a));
bool isUnlinked(alias link, T)(in T* a) =>
	!has(prev!link(a)) && !has(next!link(a));

// Removes nodes from the list (starting from the last) and calls `cb` on each after it is removed.
void removeAllFromListAnd(alias link, T)(T* last, void delegate(T*) @safe @nogc pure nothrow cb) {
	while (true) {
		assert(isEndOfList!link(last));
		MutOpt!(T*) left = prev!link(last);
		prev!link(last) = noneMut!(T*);
		if (has(left))
			next!link(force(left)) = noneMut!(T*);
		assert(isUnlinked!link(last));
		cb(last);
		if (has(left))
			last = force(left);
		else
			break;
	}
}

// Does not consider the current node (or to its left)
MutOpt!(T*) findNodeToRight(alias link, T)(T* a, in bool delegate(in T*) @safe @nogc pure nothrow cb) {
	MutOpt!(T*) next = next!link(a);
	return !has(next)
		? noneMut!(T*)
		: cb(force(next))
		? someMut(force(next))
		: findNodeToRight!link(force(next), cb);
}

bool existsHereOrPrev(alias link, T)(in T* a, in bool delegate(in T*) @safe @nogc pure nothrow cb) =>
	cb(a) || (has(prev!link(a)) && existsHereOrPrev!link(force(prev!link(a)), cb));

void eachHereAndNext(alias link, T)(in T* a, in void delegate(in T*) @safe @nogc pure nothrow cb) {
	cb(a);
	eachNextNode!link(a, cb);
}

void eachPrevNode(alias link, T)(in T* a, in void delegate(in T*) @safe @nogc pure nothrow cb) {
	assert(isEndOfList!link(a));
	const(T)* cur = a;
	while (true) {
		ConstOpt!(T*) left = prev!link(cur);
		if (has(left)) {
			cb(force(left));
			cur = force(left);
		} else
			break;
	}
}

private void eachNextNode(alias link, T)(in T* a, in void delegate(in T*) @safe @nogc pure nothrow cb) {
	assert(isStartOfList!link(a));
	const(T)* cur = a;
	while (true) {
		ConstOpt!(T*) right = next!link(cur);
		if (has(right)) {
			cb(force(right));
			cur = force(right);
		} else
			break;
	}
}

void removeFromList(alias link, T)(T* a) {
	assert(!isUnlinked!link(a));
	if (has(prev!link(a)))
		next!link(force(prev!link(a))) = next!link(a);
	if (has(next!link(a)))
		prev!link(force(next!link(a))) = prev!link(a);
	prev!link(a) = noneMut!(T*);
	next!link(a) = noneMut!(T*);
	assert(isUnlinked!link(a));
}

// Inserts 'new_' between 'left' and 'left.next' (or at the end if 'left' was the end before)
void insertToRight(alias link, T)(T* left, T* new_) {
	assert(isUnlinked!link(new_));
	prev!link(new_) = someMut(left);
	next!link(new_) = next!link(left);
	next!link(left) = someMut(new_);
	if (has(next!link(new_)))
		prev!link(force(next!link(new_))) = someMut(new_);
}

void insertToLeft(alias link, T)(T* right, T* new_) {
	assert(isUnlinked!link(new_));
	next!link(new_) = someMut(right);
	prev!link(new_) = prev!link(right);
	prev!link(right) = someMut(new_);
	if (has(prev!link(new_)))
		next!link(force(prev!link(new_))) = someMut(new_);
}

void assertDoubleLink(alias link, T)(in T* a) {
	assertDoubleLinkLeft!link(a);
	assertDoubleLinkRight!link(a);
}

private void assertDoubleLinkLeft(alias link, T)(in T* a) {
	ConstOpt!(T*) opt = prev!link(a);
	if (has(opt)) {
		const T* left = force(opt);
		assert(force(next!link(left)) == a);
		assertDoubleLinkLeft!link(left);
	}
}

private void assertDoubleLinkRight(alias link, T)(in T* a) {
	ConstOpt!(T*) opt = next!link(a);
	if (has(opt)) {
		const T* right = force(opt);
		assert(force(prev!link(right)) == a);
		assertDoubleLinkRight!link(right);
	}
}
