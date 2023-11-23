module util.alloc.alloc;

@nogc nothrow: // not @safe, not pure

import util.col.arr : arrOfRange, endPtr;
import util.util : clamp, divRoundUp, verify;

T withStaticAlloc(T, alias cb)(word[] memory) {
	scope MetaAlloc metaAlloc = MetaAlloc(memory);
	scope Alloc alloc = newAlloc(metaAlloc);
	return cb(alloc);
}

pure:

@trusted T withStackAlloc(size_t sizeWords, T)(in T delegate(ref Alloc) @safe @nogc pure nothrow cb) {
	ulong[sizeWords] memory = void;
	return withStaticAlloc!(T, cb)(memory);
}

struct MetaAlloc {
	@safe @nogc pure nothrow:

	@disable this();
	@disable this(ref const MetaAlloc);
	@trusted this(return scope word[] w) {
		verify(w.length > blockHeaderSizeWords * 2);
		words = w;
		BlockHeader* block = freeListSentinel + 1;
		*block = BlockHeader(freeListSentinel, null, endPtr(words));
		freeListSentinel.next = block;
	}

	word[] words;

	@system BlockHeader* freeListSentinel() =>
		cast(BlockHeader*) words.ptr;
}

Alloc newAlloc(return scope ref MetaAlloc a) =>
	Alloc(&a, allocateBlock(a, 0));

struct Alloc {
	@safe @nogc pure nothrow:

	private:

	@disable this();
	@disable this(ref const Alloc);
	@system this(MetaAlloc* m, BlockHeader* b) {
		meta = m;
		verify(b.prev == null);
		curBlock = b;
		cur = b.words.ptr;
	}

	MetaAlloc* meta;
	BlockHeader* curBlock;
	word* cur;
}
alias TempAlloc = Alloc;

// Alloc that we are done allocating to.
private struct FinishedAlloc {
	private:
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

@trusted void verifyOwns(T)(in Alloc a, in T[] values) {
	verify(allocOwns(a, values));
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

private FinishedAlloc finishAlloc(ref Alloc a) =>
	FinishedAlloc(a.meta, a.curBlock);

private void freeAlloc(ref FinishedAlloc a) {
	BlockHeader* cur = a.lastBlock;
	do {
		BlockHeader* prev = cur.prev;
		freeBlock(*a.meta, cur);
		cur = prev;
	} while (cur != null);
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

	@system inout(word[]) words() inout return scope =>
		arrOfRange!word(cast(inout word*) (&this + 1), end);
}
static assert(BlockHeader.sizeof % word.sizeof == 0);

BlockHeader* allocateBlock(ref MetaAlloc a, size_t minWords) {
	BlockHeader* cur = a.freeListSentinel.next;
	while (cur != null) {
		if (cur.words.length >= minWords) {
			size_t sizeWords = clamp(preferredBlockWordCount, minWords, cur.words.length);
			maybeSplitBlock(cur, sizeWords);
			removeFromList(cur);
			verify(cur.prev == null && cur.next == null && cur.words.length >= sizeWords);
			return cur;
		} else
			cur = cur.next;
	}
	assert(false); // OOM
}

void maybeSplitBlock(BlockHeader* left, size_t leftSizeWords) {
	verify(left.words.length >= leftSizeWords);
	size_t remaining = left.words.length - leftSizeWords;
	if (remaining >= blockHeaderSizeWords + minBlockSize) {
		BlockHeader* right = cast(BlockHeader*) &left.words[leftSizeWords];
		*right = BlockHeader(left, left.next, left.end);
		*left = BlockHeader(left.prev, right, cast(word*) right);
	}
}

void removeFromList(BlockHeader* a) {
	if (a.prev != null)
		a.prev.next = a.next;
	if (a.next != null)
		a.next.prev = a.prev;
	a.prev = null;
	a.next = null;
}

// TODO: Keep blocks in sorted order and merge adjacent blocks
void freeBlock(ref MetaAlloc a, BlockHeader* block) {
	insertBlockToRight(a.freeListSentinel, block);
}

void insertBlockToRight(BlockHeader* a, BlockHeader* b) {
	a.next.prev = b;
	*b = BlockHeader(a, a.next, b.end);
	a.next = b;
}

// Anything less than this becomes fragmentation.
size_t minBlockSize() =>
	0x100;

size_t preferredBlockWordCount() =>
	0x100000 - blockHeaderSizeWords;

size_t blockHeaderSizeWords() =>
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
	verify(newCur <= a.curBlock.end);
	word[] res = a.cur[0 .. nWords];
	a.cur = newCur;
	verifyOwns(a, res);
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

const(word[]) outerWordRange(T)(return in T[] range) =>
	arrOfRange(roundDownToWord(cast(ubyte*) range.ptr), roundUpToWord(cast(ubyte*) endPtr(range)));

const(word[]) innerWordRange(T)(return in T[] range) {
	const word* begin = roundUpToWord(cast(ubyte*) range.ptr);
	const word* end = roundDownToWord(cast(ubyte*) endPtr(range));
	return begin < end ? arrOfRange(begin, end) : [];
}

size_t bytesToWords(size_t bytes) =>
	divRoundUp(bytes, word.sizeof);

const(word*) roundUpToWord(return in ubyte* a) {
	size_t rem = (cast(size_t) a) % word.sizeof;
	return cast(word*) (rem == 0 ? a : a - rem + word.sizeof);
}

const(word*) roundDownToWord(return in ubyte* a) =>
	cast(word*) (a - ((cast(size_t) a) % word.sizeof));
