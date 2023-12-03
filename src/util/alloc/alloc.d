module util.alloc.alloc;

@nogc nothrow: // not @safe, not pure

import util.alloc.dlList :
	DLListNode,
	eachHereAndPrev,
	eachNextNode,
	eachPrevNode,
	existsHereAndPrev,
	insertToRight,
	isUnlinked,
	removeAllFromListAnd,
	removeFromList;
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
		BlockNode* block = freeListSentinel + 1;
		*block = BlockNode(freeListSentinel, null, BlockHeaderContent(endPtr(words)));
		// This is just the sentinel, so it's missing a valid 'end'
		*freeListSentinel = BlockNode(null, block, BlockHeaderContent(null));
	}

	private:
	word[] words;

	@trusted inout(BlockNode*) freeListSentinel() inout =>
		cast(inout BlockNode*) (words.ptr);
}

// This includes the allocation overhead
@trusted size_t totalBytesAllocated(in MetaAlloc a) {
	size_t freeWords = 0;
	eachNextNode(a.freeListSentinel, (in BlockNode* b) {
		freeWords += b.words.length;
	});
	return (a.words.length - freeWords) * word.sizeof;
}


@safe Alloc newAlloc(AllocName name, MetaAlloc* a) {
	return Alloc(name, a, allocateBlock(*a, 0));
}

// This is not unique; e.g. there is a 'storage' alloc for each file
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
	@trusted this(AllocName name, MetaAlloc* m, BlockNode* b) {
		debugName = name;
		meta = m;
		assert(b.prev == null);
		curBlock = b;
		cur = b.words.ptr;
	}
	this(AllocName name, MetaAlloc* m, BlockNode* b, word* c) {
		debugName = name;
		meta = m;
		curBlock = b;
		cur = c;
	}

	AllocName debugName;
	MetaAlloc* meta;
	BlockNode* curBlock;
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
	BlockNode* lastBlock;
}

@trusted MemorySummary summarizeMemory(in FinishedAlloc a) {
	size_t overheadBytes = FinishedAlloc.sizeof;
	size_t usedWords;
	eachHereAndPrev(a.lastBlock, (in BlockNode* x) {
		overheadBytes += BlockNode.sizeof;
		usedWords += x.words.length;
	});
	return MemorySummary(usedWords * word.sizeof, 0, overheadBytes);
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
	existsHereAndPrev!BlockHeaderContent(a.curBlock, (in BlockNode* b) @trusted => blockOwns(b, values));

struct MemorySummary {
	@safe @nogc pure nothrow:

	size_t usedBytes;
	size_t freeBytes; // memory that is 'free' but reserved in the alloc
	size_t overheadBytes;

	MemorySummary opBinary(string op: "+")(MemorySummary b) const =>
		MemorySummary(usedBytes + b.usedBytes, freeBytes + b.freeBytes, overheadBytes + b.overheadBytes);

	void opOpAssign(string op: "+")(MemorySummary b) {
		usedBytes += b.usedBytes;
		freeBytes += b.freeBytes;
		overheadBytes += b.overheadBytes;
	}
}

@trusted MemorySummary summarizeMemory(in Alloc a) {
	size_t overheadBytes = Alloc.sizeof + BlockNode.sizeof;
	size_t wordsUsed = a.cur - a.curBlock.words.ptr;
	size_t wordsFree = endPtr(a.curBlock.words) - a.cur;
	eachPrevNode(a.curBlock, (in BlockNode* x) {
		overheadBytes += BlockNode.sizeof;
		wordsUsed += x.words.length;
	});
	return MemorySummary(wordsUsed * word.sizeof, wordsFree * word.sizeof, overheadBytes);
}

@trusted FinishedAlloc finishAlloc(ref Alloc a) {
	freeRestOfBlock(*a.meta, a.curBlock, a.cur);
	return FinishedAlloc(a.debugName, a.meta, a.curBlock);
}

void freeAlloc(ref FinishedAlloc a) {
	removeAllFromListAnd!BlockHeaderContent(a.lastBlock, (BlockNode* x) @trusted {
		addToFreeList(*a.meta, x);
	});
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

// A free block will be on the list of free blocks.
// A used block will be in an allocator's list of blocks.
alias BlockNode = DLListNode!BlockHeaderContent;

struct BlockHeaderContent {
	@safe @nogc pure nothrow:
	// Points after the last word in the block
	word* end;
	version (WebAssembly) {
		word* padding = void;
	}

	@trusted inout(word[]) words() inout return scope =>
		arrOfRange!word(cast(inout word*) (&this + 1), end);
}
static assert(BlockNode.sizeof % word.sizeof == 0);

@safe inout(word[]) words(return scope inout BlockNode* node) =>
	node.value.words;

@safe BlockNode* allocateBlock(ref MetaAlloc a, size_t minWords) {
	BlockNode* cur = a.freeListSentinel.next;
	while (cur != null) {
		if (cur.words.length >= minWords) {
			size_t sizeWords = clamp(preferredBlockWordCount, minWords, cur.words.length);
			cast(void) maybeSplitBlock(cur, sizeWords);
			removeFromList(cur);
			assert(isUnlinked(cur) && cur.words.length >= sizeWords);
			return cur;
		} else
			cur = cur.next;
	}
	assert(false, "OOM");
}

@trusted bool maybeSplitBlock(BlockNode* left, size_t leftSizeWords) {
	assert(left.words.length >= leftSizeWords);
	size_t remaining = left.words.length - leftSizeWords;
	if (remaining >= blockHeaderSizeWords + minBlockSize) {
		BlockNode* right = cast(BlockNode*) &left.words[leftSizeWords];
		*right = BlockNode(null, null, left.value);
		left.value = BlockHeaderContent(cast(word*) right);
		insertToRight(left, right);
		return true;
	} else
		return false;
}

void freeRestOfBlock(ref MetaAlloc a, BlockNode* block, word* cur) {
	if (maybeSplitBlock(block, cur - block.words.ptr)) {
		BlockNode* freed = block.next;
		removeFromList(block.next);
		addToFreeList(a, freed);
	}
}

// TODO: Keep blocks in sorted order and merge adjacent blocks
void addToFreeList(ref MetaAlloc a, BlockNode* block) {
	insertToRight(a.freeListSentinel, block);
}

// Anything less than this becomes fragmentation.
@safe size_t minBlockSize() =>
	0x100;

@safe size_t preferredBlockWordCount() =>
	0x100000 - blockHeaderSizeWords;

@safe size_t blockHeaderSizeWords() =>
	bytesToWords(BlockNode.sizeof);

bool blockOwns(T)(in BlockNode* a, in T[] values) =>
	isSubArray(outerWordRange(values), a.words);
bool isSubArray(T)(in T[] a, in T[] b) =>
	b.ptr <= a.ptr && endPtr(a) <= endPtr(b);

word[] allocateWords(ref Alloc a, size_t nWords) {
	word* newCur = a.cur + nWords;
	if (newCur > a.curBlock.value.end) {
		fetchNewBlock(a, nWords);
		newCur = a.cur + nWords;
	}
	assert(newCur <= a.curBlock.value.end);
	word[] res = a.cur[0 .. nWords];
	a.cur = newCur;
	assertOwns(a, res);
	return res;
}

void fetchNewBlock(ref Alloc a, size_t minWords) {
	BlockNode* block = allocateBlock(*a.meta, minWords);
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
