module util.alloc.alloc;

@nogc nothrow: // not @safe, not pure

import util.alloc.doubleLink :
	DoubleLink,
	eachHereAndPrev,
	eachHereAndNext,
	eachPrevNode,
	existsHereOrPrev,
	findNodeToRight,
	insertToLeft,
	insertToRight,
	isEndOfList,
	isStartOfList,
	isUnlinked,
	next,
	prev,
	removeAllFromListAnd,
	removeFromList;
import util.col.arr : arrOfRange, endPtr;
import util.col.enumMap : EnumMap, enumMapEach;
import util.opt : force, has, MutOpt, noneMut, someMut;
import util.util : clamp, divRoundUp;

T withStaticAlloc(T, alias cb)(word[] memory) {
	scope MetaAlloc metaAlloc = MetaAlloc(memory);
	scope Alloc alloc = newAlloc(AllocKind.static_, &metaAlloc);
	return cb(alloc);
}

// It's safe to use the result immediately after this ends so long as there are no other allocations.
T withTempAllocImpure(T)(AllocKind name, MetaAlloc* a, in T delegate(ref Alloc) @safe @nogc nothrow cb) =>
	withTempAllocAlias!(T, cb)(name, a);

@trusted private T withTempAllocAlias(T, alias cb)(AllocKind name, MetaAlloc* a) {
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

@safe T withTempAlloc(T)(AllocKind name, MetaAlloc* a, in T delegate(ref Alloc) @safe @nogc pure nothrow cb) =>
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
		*firstBlockSentinel = BlockNode(AllocKind.sentinel);
		*lastBlockSentinel = BlockNode(AllocKind.sentinel);
		insertToRight!allBlocksLink(firstBlockSentinel, lastBlockSentinel);
		insertToRight!allocLink(firstBlockSentinel, lastBlockSentinel);

		BlockNode* firstActualBlock = firstBlockSentinel + 1;
		*firstActualBlock = BlockNode(AllocKind.free);
		insertToRight!allBlocksLink(firstBlockSentinel, firstActualBlock);
		insertToRight!allocLink(firstBlockSentinel, firstActualBlock);

		assert(isStartOfList!allBlocksLink(firstBlockSentinel) && isEndOfList!allBlocksLink(lastBlockSentinel));
		assert(isStartOfList!allocLink(firstBlockSentinel) && isEndOfList!allocLink(lastBlockSentinel));

		validate(this);
	}

	private:
	word[] words;

	// This is the sentinel for both 'allBlocksLink' and 'allocLink' for free blocks
	@trusted inout(BlockNode*) firstBlockSentinel() return scope inout =>
		cast(inout BlockNode*) (words.ptr);

	@trusted inout(BlockNode*) lastBlockSentinel() return scope inout =>
		(cast(BlockNode*) endPtr(words)) - 1;
}

private @trusted void validate(in MetaAlloc a) {
	const(BlockNode)* left = a.firstBlockSentinel;
	const(BlockNode)* cur = next!allBlocksLink(left);
	while (true) {
		const BlockNode* right = next!allBlocksLink(cur);
		assert(left < cur && cur < right);
		assert(prev!allBlocksLink(cur) == left);
		if (isFree(cur)) {
			assert(!isFree(left));
			assert(!isFree(right));
		}

		const BlockNode* allocPrev = prev!allocLink(cur);
		if (allocPrev != null) {
			assert(next!allocLink(allocPrev) == cur);
			assert(allocPrev.allocKind == cur.allocKind || (isFree(cur) && isSentinel(allocPrev)));
		}
		const BlockNode* allocNext = next!allocLink(cur);
		if (allocNext != null) {
			assert(prev!allocLink(allocNext) == cur);
			assert(allocNext.allocKind == cur.allocKind || (isFree(cur) && isSentinel(allocNext)));
		}

		if (right == a.lastBlockSentinel)
			break;
		else {
			assert(right != null);
			left = cur;
			cur = right;
		}
	}
}

@trusted MetaMemorySummary summarizeMemory(in MetaAlloc a) {
	EnumMap!(AllocKind, AllocKindMemorySummary) byAlloc;
	eachHereAndNext!allBlocksLink(a.firstBlockSentinel, (in BlockNode* x) {
		byAlloc[x.allocKind] += AllocKindMemorySummary(
			x == a.lastBlockSentinel ? 0 : x.words.length * word.sizeof,
			BlockNode.sizeof);
	});
	MemorySummary total;
	enumMapEach!(AllocKind, AllocKindMemorySummary)(byAlloc, (AllocKind name, in AllocKindMemorySummary x) {
		if (name == AllocKind.sentinel)
			total.overheadBytes += totalBytes(x);
		else if (name == AllocKind.free)
			total.freeBytes += totalBytes(x);
		else
			total += MemorySummary(x.usedAndFreeBytes, 0, x.overheadBytes);
	});
	return MetaMemorySummary(byAlloc, total);
}

@safe Alloc newAlloc(AllocKind name, MetaAlloc* a) {
	return Alloc(name, a, allocateBlock(*a, name, 0));
}

// This is not unique; e.g. there is a 'storage' alloc for each file
enum AllocKind {
	sentinel, // Not an allocator name, this indicates the first/last sentinel block
	free, // Not an allocator name, this indicates a free block
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
	@trusted this(AllocKind kind, MetaAlloc* m, BlockNode* b) {
		allocKind = kind;
		meta = m;
		assert(isStartOfList!allocLink(b));
		curBlock = b;
		cur = b.words.ptr;
	}
	this(AllocKind kind, MetaAlloc* m, BlockNode* b, word* c) {
		allocKind = kind;
		meta = m;
		curBlock = b;
		cur = c;
	}

	AllocKind allocKind;
	MetaAlloc* meta;
	BlockNode* curBlock;
	word* cur;

	public Alloc move() {
		Alloc res = Alloc(allocKind, meta, curBlock, cur);
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
	AllocKind allocKind;
	MetaAlloc* meta;
	BlockNode* lastBlock;
}

@trusted MemorySummary summarizeMemory(in FinishedAlloc a) {
	size_t overheadBytes = FinishedAlloc.sizeof;
	size_t usedWords;
	eachHereAndPrev!(allocLink, BlockNode)(a.lastBlock, (in BlockNode* x) {
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
	existsHereOrPrev!allocLink(a.curBlock, (in BlockNode* b) @trusted => blockOwns(b, values));

struct MemorySummary {
	@safe @nogc pure nothrow:

	size_t usedBytes;
	size_t freeBytes; // memory that is 'free' but reserved in the alloc
	size_t overheadBytes;

	MemorySummary opBinary(string op: "+")(in MemorySummary b) const =>
		MemorySummary(usedBytes + b.usedBytes, freeBytes + b.freeBytes, overheadBytes + b.overheadBytes);

	void opOpAssign(string op: "+")(in MemorySummary b) {
		this = this + b;
	}
}

struct AllocKindMemorySummary {
	@safe @nogc pure nothrow:

	size_t usedAndFreeBytes;
	size_t overheadBytes;

	AllocKindMemorySummary opBinary(string op: "+")(in AllocKindMemorySummary b) const =>
		AllocKindMemorySummary(usedAndFreeBytes + b.usedAndFreeBytes, overheadBytes + b.overheadBytes);

	void opOpAssign(string op: "+")(in AllocKindMemorySummary b) {
		this = this + b;
	}
}
@safe size_t totalBytes(in AllocKindMemorySummary a) =>
	a.usedAndFreeBytes + a.overheadBytes;

struct MetaMemorySummary {
	EnumMap!(AllocKind, AllocKindMemorySummary) byAllocKind;
	MemorySummary total;
}

@safe size_t totalBytes(in MemorySummary a) =>
	a.usedBytes + a.freeBytes + a.overheadBytes;

@trusted MemorySummary summarizeMemory(in Alloc a) {
	size_t overheadBytes = Alloc.sizeof + BlockNode.sizeof;
	size_t wordsUsed = a.cur - a.curBlock.words.ptr;
	size_t wordsFree = endPtr(a.curBlock.words) - a.cur;
	eachPrevNode!allocLink(a.curBlock, (in BlockNode* x) {
		overheadBytes += BlockNode.sizeof;
		wordsUsed += x.words.length;
	});
	return MemorySummary(wordsUsed * word.sizeof, wordsFree * word.sizeof, overheadBytes);
}

@trusted FinishedAlloc finishAlloc(ref Alloc a) {
	freeRestOfBlock(*a.meta, a.curBlock, a.cur);
	return FinishedAlloc(a.allocKind, a.meta, a.curBlock);
}

void freeAlloc(ref FinishedAlloc a) {
	removeAllFromListAnd!allocLink(a.lastBlock, (BlockNode* x) @trusted {
		addToFreeList(*a.meta, x);
	});
}

struct AllocAndValue(T) {
	FinishedAlloc alloc;
	T value;
}

@safe AllocAndValue!T withAlloc(T)(AllocKind kind, MetaAlloc* a, in T delegate(ref Alloc) @safe @nogc pure nothrow cb) {
	Alloc alloc = newAlloc(kind, a);
	T value = cb(alloc);
	FinishedAlloc finished = finishAlloc(alloc);
	return AllocAndValue!T(finished, value);
}

private:

alias word = ulong;

struct BlockNode {
	@safe @nogc pure nothrow:
	// Mostly for debugging, but also indicates whether this is a sentinel or free block
	AllocKind allocKind;
	// Links all blocks, in pointer order.
	DoubleLink!BlockNode allBlocksLink_;
	// For a free block, this links the free blocks (in arbitrary order), including the first/last sentinel.
	// For an allocated block, this links blocks with the same Alloc (in the order they were allocated).
	DoubleLink!BlockNode allocLink_;
	version (WebAssembly) {
		uint padding;
	}

	@trusted inout(word*) end() return scope inout {
		word* res = cast(word*) next!allBlocksLink(&this);
		assert(res != null);
		return res;
	}

	@trusted inout(word[]) words() return scope inout =>
		arrOfRange!word(cast(inout word*) (&this + 1), end);
}

@safe bool isSentinel(in BlockNode* a) =>
	a.allocKind == AllocKind.sentinel;

@safe bool isFree(in BlockNode* a) =>
	a.allocKind == AllocKind.free;

@safe ref inout(DoubleLink!BlockNode) allBlocksLink(inout BlockNode* a) =>
	a.allBlocksLink_;

@safe ref inout(DoubleLink!BlockNode) allocLink(inout BlockNode* a) =>
	a.allocLink_;

@safe BlockNode* allocateBlock(ref MetaAlloc meta, AllocKind allocKind, size_t minWords) {
	MutOpt!(BlockNode*) found = findNodeToRight!allocLink(meta.firstBlockSentinel, (in BlockNode* x) =>
		x.words.length >= minWords);
	if (has(found)) {
		BlockNode* res = force(found);
		assert(isFree(res));
		size_t sizeWords = clamp(preferredBlockWordCount, minWords, res.words.length);
		MutOpt!(BlockNode*) remaining = maybeSplitOffBlock(res, sizeWords);
		if (has(remaining))
			insertToRight!allocLink(res, force(remaining));
		removeFromList!allocLink(res);
		assert(res.words.length >= sizeWords);
		res.allocKind = allocKind;
		validate(meta);
		return res;
	} else
		assert(false, "OOM");
}

// Splits the block and returns the new right half (which is linked to 'allBlocksLink' but not 'allocLink')
@trusted MutOpt!(BlockNode*) maybeSplitOffBlock(BlockNode* left, size_t leftSizeWords) {
	assert(left.words.length >= leftSizeWords);
	size_t remaining = left.words.length - leftSizeWords;
	if (remaining >= blockHeaderSizeWords + minBlockSize) {
		BlockNode* right = cast(BlockNode*) &left.words[leftSizeWords];
		*right = BlockNode(left.allocKind);
		insertToRight!allBlocksLink(left, right);
		return someMut(right);
	} else
		return noneMut!(BlockNode*);
}

void freeRestOfBlock(ref MetaAlloc a, BlockNode* block, word* cur) {
	MutOpt!(BlockNode*) freed = maybeSplitOffBlock(block, cur - block.words.ptr);
	if (has(freed))
		addToFreeList(a, force(freed));
}

void addToFreeList(ref MetaAlloc a, BlockNode* block) {
	validate(a);
	block.allocKind = AllocKind.free;
	assert(!isUnlinked!allBlocksLink(block));
	assert(isUnlinked!allocLink(block));
	BlockNode* left = prev!allBlocksLink(block);
	BlockNode* right = next!allBlocksLink(block);
	if (isFree(left) && isFree(right)) {
		// Remove this and the right block, making 'left' a big free block.
		removeFromList!allBlocksLink(block);
		removeFromList!allBlocksLink(right);
		removeFromList!allocLink(right);
	} else if (isFree(left)) {
		// Remove this block, making 'left' bigger
		removeFromList!allBlocksLink(block);
	} else if (isFree(right)) {
		// Merge the 'right' block into this one
		insertToLeft!allocLink(right, block);
		removeFromList!allocLink(right);
		removeFromList!allBlocksLink(right);
	} else
		findPositionInFreeListAndInsert(a, block);
	validate(a);
}
void findPositionInFreeListAndInsert(ref MetaAlloc a, BlockNode* block) {
	assert(!isFree(prev!allBlocksLink(block)) && !isFree(next!allBlocksLink(block)));
	// Find the free nodes to insert this one between.
	BlockNode* left = a.firstBlockSentinel;
	BlockNode* cur = next!allocLink(left);
	assert(isFree(cur) || isSentinel(cur));
	while (cur < block) {
		left = cur;
		cur = next!allocLink(cur);
	}
	assert(left < block && block < cur);
	insertToRight!allocLink(left, block);
}

// Anything less than this becomes fragmentation.
@safe size_t minBlockSize() =>
	0x100;

@safe size_t preferredBlockWordCount() =>
	0x10000 - blockHeaderSizeWords;

@safe size_t blockHeaderSizeWords() {
	static assert(BlockNode.sizeof % word.sizeof == 0);
	return bytesToWords(BlockNode.sizeof);
}

bool blockOwns(T)(in BlockNode* a, in T[] values) =>
	isSubArray(outerWordRange(values), a.words);
bool isSubArray(T)(in T[] a, in T[] b) =>
	b.ptr <= a.ptr && endPtr(a) <= endPtr(b);

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
	BlockNode* block = allocateBlock(*a.meta, a.allocKind, minWords);
	insertToRight!allocLink(a.curBlock, block);
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
