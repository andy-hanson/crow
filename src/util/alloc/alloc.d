module util.alloc.alloc;

@nogc nothrow: // not @safe, not pure

import util.col.arr : arrOfRange, endPtr;
import util.util : clamp, divRoundUp;

T withStaticAlloc(T, alias cb)(word[] memory) {
	scope MetaAlloc metaAlloc = MetaAlloc(memory);
	scope Alloc alloc = newAlloc(AllocName.static_, &metaAlloc);
	return cb(alloc);
}

// It's safe to use the result immediately after this ends so long as there are no other allocations.
T withTempAllocImpure(T)(AllocName name, MetaAlloc* a, in T delegate(ref Alloc) @safe @nogc nothrow cb) =>
	withTempAllocAlias!(T, cb)(name, a);

@trusted private T withTempAllocAlias(T, alias cb)(AllocName name, MetaAlloc* a) {
	// TODO:PERF Since this is temporary, an initial block could be on the stack?
	Alloc alloc = newAlloc(name, a);
	static if (is(T == void)) {
		cb(alloc);
	} else {
		T res = cb(alloc);
	}
	FinishedAlloc finished = finishAlloc(alloc);
	freeAlloc(finished);
	static if (!is(T == void))
		return res;
}

pure:

@safe T withTempAlloc(T)(AllocName name, MetaAlloc* a, in T delegate(ref Alloc) @safe @nogc pure nothrow cb) =>
	withTempAllocAlias!(T, cb)(name, a);

@trusted T withStackAlloc(size_t sizeWords, T)(in T delegate(ref Alloc) @safe @nogc pure nothrow cb) {
	ulong[sizeWords] memory = void;
	return withStaticAlloc!(T, cb)(memory);
}

struct MetaAlloc {
	@safe @nogc pure nothrow:

	@disable this();
	@disable this(ref const MetaAlloc);
	@trusted this(return scope word[] w) {
		assert(w.length > blockHeaderSizeWords * 2);
		words = w;
		BlockHeader* block = freeListSentinel + 1;
		*block = BlockHeader(freeListSentinel, null, endPtr(words));
		freeListSentinel.next = block;
	}

	private:
	word[] words;

	@trusted BlockHeader* freeListSentinel() =>
		cast(BlockHeader*) words.ptr;
}

@safe Alloc newAlloc(AllocName name, MetaAlloc* a) =>
	Alloc(name, a, allocateBlock(*a, 0));

enum AllocName {
	allSymbols,
	allUris,
	frontend,
	handleLspMessage,
	lspState,
	main,
	other,
	programState,
	static_,
	storage,
	storageChangeFile,
	storageFileInfo,
	test,
	wasmNewServer,
}

struct Alloc {
	@safe @nogc pure nothrow:

	private:

	@disable this();
	@disable this(ref const Alloc);
	@trusted this(AllocName name, MetaAlloc* m, BlockHeader* b) {
		debugName = name;
		meta = m;
		assert(b.prev == null);
		curBlock = b;
		cur = b.words.ptr;
	}
	this(AllocName name, MetaAlloc* m, BlockHeader* b, word* c) {
		debugName = name;
		meta = m;
		curBlock = b;
		cur = c;
	}

	AllocName debugName;
	MetaAlloc* meta;
	BlockHeader* curBlock;
	word* cur;

	public Alloc move() {
		Alloc res = Alloc(debugName, meta, curBlock, cur);
		meta = null;
		curBlock = null;
		cur = null;
		return res;
	}
}
alias TempAlloc = Alloc;

// Alloc that we are done allocating to.
struct FinishedAlloc {
	private:
	AllocName debugName;
	MetaAlloc* meta;
	BlockHeader* lastBlock;
}

ubyte[] allocateBytes(ref Alloc a, size_t sizeBytes) =>
	(cast(ubyte*) allocateWords(a, bytesToWords(sizeBytes)).ptr)[0 .. sizeBytes];

T* allocateUninitialized(T)(ref Alloc a) =>
	&allocateElements!T(a, 1)[0];

T[] allocateElements(T)(ref Alloc a, size_t count) =>
	(cast(T*) allocateBytes(a, T.sizeof * count).ptr)[0 .. count];

void freeElements(T)(ref Alloc a, in T[] range) {
	freeWords(a, innerWordRange(range));
}

@trusted void assertOwns(T)(in Alloc a, in T[] values) {
	assert(allocOwns(a, values));
}
bool allocOwns(T)(in Alloc a, in T[] values) =>
	existsBlock(a, (in BlockHeader* b) => blockOwns(b, values));

size_t perf_curBytes(ref Alloc a) {
	size_t words = a.cur - a.curBlock.words.ptr;
	eachPrevBlock(a, (in BlockHeader* x) {
		words += x.words.length;
	});
	return words * word.sizeof;
}

@trusted FinishedAlloc finishAlloc(ref Alloc a) {
	freeRestOfBlock(*a.meta, a.curBlock, a.cur);
	return FinishedAlloc(a.debugName, a.meta, a.curBlock);
}

void freeAlloc(ref FinishedAlloc a) {
	BlockHeader* cur = a.lastBlock;
	do {
		BlockHeader* prev = cur.prev;
		freeBlock(*a.meta, cur);
		cur = prev;
	} while (cur != null);
}

struct AllocAndValue(T) {
	FinishedAlloc alloc;
	T value;
}

@safe AllocAndValue!T withAlloc(T)(AllocName name, MetaAlloc* a, in T delegate(ref Alloc) @safe @nogc pure nothrow cb) {
	Alloc alloc = newAlloc(name, a);
	T value = cb(alloc);
	FinishedAlloc finished = finishAlloc(alloc);
	return AllocAndValue!T(finished, value);
}

private:

alias word = ulong;

struct BlockHeader {
	@safe @nogc pure nothrow:

	// If the block is free, this is the previous free block (or null for the first).
	// Otherwise, this is the previous block in an Alloc's chain of blocks (or null for the first).
	BlockHeader* prev;
	// If the block is free, this is the next free block (or null for the last).
	// Otherwise, this should be null.
	BlockHeader* next;
	// Points after the last word in the block
	word* end;
	version (WebAssembly) {
		word* padding = void;
	}

	@trusted inout(word[]) words() inout return scope =>
		arrOfRange!word(cast(inout word*) (&this + 1), end);
}
static assert(BlockHeader.sizeof % word.sizeof == 0);

@safe BlockHeader* allocateBlock(ref MetaAlloc a, size_t minWords) {
	BlockHeader* cur = a.freeListSentinel.next;
	while (cur != null) {
		if (cur.words.length >= minWords) {
			size_t sizeWords = clamp(preferredBlockWordCount, minWords, cur.words.length);
			cast(void) maybeSplitBlock(cur, sizeWords);
			removeFromList(cur);
			assert(cur.prev == null && cur.next == null && cur.words.length >= sizeWords);
			return cur;
		} else
			cur = cur.next;
	}
	assert(false, "OOM");
}

@trusted bool maybeSplitBlock(BlockHeader* left, size_t leftSizeWords) {
	assert(left.words.length >= leftSizeWords);
	size_t remaining = left.words.length - leftSizeWords;
	if (remaining >= blockHeaderSizeWords + minBlockSize) {
		BlockHeader* right = cast(BlockHeader*) &left.words[leftSizeWords];
		*right = BlockHeader(left, left.next, left.end);
		*left = BlockHeader(left.prev, right, cast(word*) right);
		return true;
	} else
		return false;
}

@safe void removeFromList(BlockHeader* a) {
	if (a.prev != null)
		a.prev.next = a.next;
	if (a.next != null)
		a.next.prev = a.prev;
	a.prev = null;
	a.next = null;
}

void freeRestOfBlock(ref MetaAlloc a, BlockHeader* block, word* cur) {
	if (maybeSplitBlock(block, cur - block.words.ptr)) {
		BlockHeader* freed = block.next;
		removeFromList(block.next);
		freeBlock(a, freed);
	}
}

// TODO: Keep blocks in sorted order and merge adjacent blocks
void freeBlock(ref MetaAlloc a, BlockHeader* block) {
	insertBlockToRight(a.freeListSentinel, block);
}

void insertBlockToRight(BlockHeader* a, BlockHeader* b) {
	if (a.next != null)
		a.next.prev = b;
	*b = BlockHeader(a, a.next, b.end);
	a.next = b;
}

// Anything less than this becomes fragmentation.
@safe size_t minBlockSize() =>
	0x100;

@safe size_t preferredBlockWordCount() =>
	0x100000 - blockHeaderSizeWords;

@safe size_t blockHeaderSizeWords() =>
	bytesToWords(BlockHeader.sizeof);

bool blockOwns(T)(in BlockHeader* a, in T[] values) =>
	isSubArray(outerWordRange(values), a.words);
bool isSubArray(T)(in T[] a, in T[] b) =>
	b.ptr <= a.ptr && endPtr(a) <= endPtr(b);

void eachPrevBlock(in Alloc a, in void delegate(in BlockHeader*) @nogc pure nothrow cb) {
	const(BlockHeader)* block = a.curBlock.prev;
	while (block != null) {
		cb(block);
		block = block.prev;
	}
}

bool existsBlock(in Alloc a, in bool delegate(in BlockHeader*) @nogc pure nothrow cb) {
	const(BlockHeader)* block = a.curBlock;
	do {
		if (cb(block))
			return true;
		block = block.prev;
	} while (block != null);
	return false;
}

word[] allocateWords(ref Alloc a, size_t nWords) {
	word* newCur = a.cur + nWords;
	if (newCur > a.curBlock.end) {
		fetchNewBlock(a, nWords);
		newCur = a.cur + nWords;
	}
	assert(newCur <= a.curBlock.end);
	word[] res = a.cur[0 .. nWords];
	a.cur = newCur;
	assertOwns(a, res);
	return res;
}

void fetchNewBlock(ref Alloc a, size_t minWords) {
	BlockHeader* block = allocateBlock(*a.meta, minWords);
	block.prev = a.curBlock;
	a.curBlock = block;
	a.cur = block.words.ptr;
}

void freeWords(ref Alloc a, in word[] range) {
	// Do nothing for other frees, they will just be fragmentation within the arena
	if (a.cur == endPtr(range)) {
		a.cur = cast(word*) range.ptr;
	}
}

@trusted const(word[]) outerWordRange(T)(return in T[] range) =>
	arrOfRange(roundDownToWord(cast(ubyte*) range.ptr), roundUpToWord(cast(ubyte*) endPtr(range)));

@trusted const(word[]) innerWordRange(T)(return in T[] range) {
	const word* begin = roundUpToWord(cast(ubyte*) range.ptr);
	const word* end = roundDownToWord(cast(ubyte*) endPtr(range));
	return begin < end ? arrOfRange(begin, end) : [];
}

@safe size_t bytesToWords(size_t bytes) =>
	divRoundUp(bytes, word.sizeof);

@trusted const(word*) roundUpToWord(return in ubyte* a) {
	size_t rem = (cast(size_t) a) % word.sizeof;
	return cast(word*) (rem == 0 ? a : a - rem + word.sizeof);
}

@trusted const(word*) roundDownToWord(return in ubyte* a) =>
	cast(word*) (a - ((cast(size_t) a) % word.sizeof));
