module util.alloc.alloc;

@nogc nothrow: // not @safe, not pure

import util.alloc.doubleLink :
	DoubleLink,
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
import util.col.arr : arrayOfRange, arrayOfSingle, endPtr;
import util.col.enumMap : EnumMap;
import util.opt : ConstOpt, force, has, MutOpt, noneMut, optEqual, someMut;
import util.util : clamp, divRoundUp, max;

T withStaticAlloc(T, alias cb)(word[] memory) {
	scope MetaAlloc metaAlloc = MetaAlloc(memory);
	scope Alloc* alloc = newAlloc(AllocKind.static_, &metaAlloc);
	return cb(*alloc);
}

// It's safe to use the result immediately after this ends so long as there are no other allocations.
T withTempAllocImpure(T)(MetaAlloc* a, in T delegate(ref Alloc) @safe @nogc nothrow cb) =>
	withTempAllocAlias!(T, cb)(a);
T withTempAllocImpure(T)(MetaAlloc* a, AllocKind kind, in T delegate(ref Alloc) @safe @nogc nothrow cb) =>
	withTempAllocAlias!(T, cb)(a, kind);

@trusted private T withTempAllocAlias(T, alias cb)(MetaAlloc* a, AllocKind kind = AllocKind.temp) {
	// TODO:PERF Since this is temporary, an initial block could be on the stack?
	Alloc* alloc = newAlloc(AllocKind.temp, a);
	static if (is(T == void)) {
		cb(*alloc);
	} else {
		T res = cb(*alloc);
	}
	FinishedAlloc* finished = finishAlloc(alloc);
	freeAlloc(finished);
	static if (!is(T == void))
		return res;
}

pure:

@safe T withTempAlloc(T)(MetaAlloc* a, in T delegate(ref Alloc) @safe @nogc pure nothrow cb) =>
	withTempAllocAlias!(T, cb)(a);

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
		*firstBlockSentinel = BlockNode();
		*lastBlockSentinel = BlockNode();
		insertToRight!allBlocksLink(firstBlockSentinel, lastBlockSentinel);
		insertToRight!allocLink(firstBlockSentinel, lastBlockSentinel);

		BlockNode* firstActualBlock = firstBlockSentinel + 1;
		*firstActualBlock = BlockNode();
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
	const(BlockNode)* cur = force(next!allBlocksLink(left));
	while (true) {
		const BlockNode* right = force(next!allBlocksLink(cur));
		assert(left < cur && cur < right);
		assert(force(prev!allBlocksLink(cur)) == left);
		if (isFree(cur)) {
			assert(!isFree(left));
			assert(!isFree(right));
		}

		ConstOpt!(BlockNode*) allocPrev = prev!allocLink(cur);
		if (has(allocPrev)) {
			assert(force(next!allocLink(force(allocPrev))) == cur);
			assert(optEqual!(Alloc*)(force(allocPrev).alloc, cur.alloc));
		}
		ConstOpt!(BlockNode*) allocNext = next!allocLink(cur);
		if (has(allocNext)) {
			assert(force(prev!allocLink(force(allocNext))) == cur);
			assert(optEqual!(Alloc*)(force(allocNext).alloc, cur.alloc));
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
	size_t countFreeBlocks;
	MemorySummary total;

	EnumMap!(AllocKind, AllocKindMemorySummary) byAlloc;
	eachHereAndNext!allBlocksLink(a.firstBlockSentinel, (in BlockNode* x) @trusted {
		if (has(x.alloc)) {
			const Alloc* alloc = force(x.alloc);
			if (x == alloc.curBlock) {
				byAlloc[alloc.allocKind] += AllocKindMemorySummary(1, MemorySummary(
					countBlocks: 1,
					usedBytes: (alloc.curWord - x.words.ptr) * word.sizeof,
					freeBytes: (x.end - alloc.curWord) * word.sizeof,
					overheadBytes: BlockNode.sizeof + Alloc.sizeof));
				// Offset the fact that the first block contained the Alloc.
				assert(byAlloc[alloc.allocKind].summary.usedBytes >= Alloc.sizeof);
				byAlloc[alloc.allocKind].summary.usedBytes -= Alloc.sizeof;
			} else
				byAlloc[alloc.allocKind] += AllocKindMemorySummary(0, MemorySummary(
					countBlocks: 1,
					usedBytes: x.words.length * word.sizeof,
					freeBytes: 0,
					overheadBytes: BlockNode.sizeof));
		} else {
			if (isFree(x)) {
				countFreeBlocks++;
				total.freeBytes += x.words.length * word.sizeof;
			}
			total.overheadBytes += BlockNode.sizeof;
		}
	});

	foreach (AllocKind name, ref const AllocKindMemorySummary x; byAlloc)
		total += x.summary;
	return MetaMemorySummary(countFreeBlocks, byAlloc, total);
}

@trusted Alloc* newAlloc(AllocKind allocKind, MetaAlloc* meta) {
	BlockNode* block = extractFreeBlock(*meta, max(bytesToWords(Alloc.sizeof), minBlockSizeWords));
	assert(isUnlinked!allocLink(block));
	// First thing to allocate is the Alloc itself. Then first useable word comes after that.
	Alloc* alloc = cast(Alloc*) block.words.ptr;
	*alloc = Alloc(allocKind, meta, block, cast(word*) (alloc + 1));
	block.alloc = someMut(alloc);
	validate(*meta);
	return alloc;
}

// This is not unique; e.g. there is a 'storage' alloc for each file
enum AllocKind {
	allSymbols,
	allUris,
	buildToLowProgram,
	extern_,
	frontend,
	interpreter,
	lspState,
	main,
	programState,
	static_,
	storage,
	storageFileInfo,
	temp,
	test,
}

struct Alloc {
	@safe @nogc pure nothrow:

	private:

	@disable this();
	@disable this(ref const Alloc);
	this(AllocKind ak, MetaAlloc* m, BlockNode* b, word* c) {
		allocKind = ak; meta = m; curBlock = b; curWord = c;
	}

	AllocKind allocKind;
	MetaAlloc* meta;
	BlockNode* curBlock;
	word* curWord;
}
alias FinishedAlloc = Alloc;
alias TempAlloc = Alloc;

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

struct AllocKindMemorySummary {
	@safe @nogc pure nothrow:

	size_t countAllocs;
	MemorySummary summary;

	AllocKindMemorySummary opBinary(string op: "+")(in AllocKindMemorySummary b) const =>
		AllocKindMemorySummary(countAllocs + b.countAllocs, summary + b.summary);
	void opOpAssign(string op: "+")(in AllocKindMemorySummary b) {
		this = this + b;
	}
}

struct MemorySummary {
	@safe @nogc pure nothrow:

	size_t countBlocks;
	size_t usedBytes;
	size_t freeBytes; // memory that is 'free' but reserved in the alloc
	size_t overheadBytes;

	MemorySummary opBinary(string op: "+")(in MemorySummary b) const =>
		MemorySummary(
			countBlocks + b.countBlocks,
			usedBytes + b.usedBytes,
			freeBytes + b.freeBytes,
			overheadBytes + b.overheadBytes);
	void opOpAssign(string op: "+")(in MemorySummary b) {
		this = this + b;
	}
}

immutable struct MetaMemorySummary {
	size_t countFreeBlocks;
	EnumMap!(AllocKind, AllocKindMemorySummary) byAllocKind;
	MemorySummary total;
}

@safe size_t totalBytes(in MemorySummary a) =>
	a.usedBytes + a.freeBytes + a.overheadBytes;

@trusted size_t perf_curBytes(in Alloc a) {
	size_t words = a.curWord - a.curBlock.words.ptr;
	eachPrevNode!allocLink(a.curBlock, (in BlockNode* x) {
		words += x.words.length;
	});
	return words * word.sizeof;
}

@trusted FinishedAlloc* finishAlloc(Alloc* a) {
	freeRestOfBlock(*a.meta, a.curBlock, a.curWord);
	return a;
}

void freeAlloc(FinishedAlloc* a) {
	// Since the alloc was allocated into its first block, this frees it too.
	removeAllFromListAnd!allocLink(a.curBlock, (BlockNode* x) @trusted {
		addToFreeList(*a.meta, x);
	});
}

struct AllocAndValue(T) {
	FinishedAlloc* alloc;
	T value;
}

@safe AllocAndValue!T withAlloc(T)(AllocKind kind, MetaAlloc* a, in T delegate(ref Alloc) @safe @nogc pure nothrow cb) {
	Alloc* alloc = newAlloc(kind, a);
	T value = cb(*alloc);
	return AllocAndValue!T(finishAlloc(alloc), value);
}

private:

alias word = ulong;

struct BlockNode {
	@safe @nogc pure nothrow:
	// 'none' indicates a sentinel or free block. Otherwise the value only matters for debugging.
	MutOpt!(Alloc*) alloc;
	// Links all blocks, in pointer order.
	DoubleLink!BlockNode allBlocksLink_;
	// For a free block, this links the free blocks (in arbitrary order), including the first/last sentinel.
	// For an allocated block, this links blocks with the same Alloc (in the order they were allocated).
	DoubleLink!BlockNode allocLink_;
	version (WebAssembly) {
		uint padding;
	}

	@trusted inout(word*) end() return scope inout {
		word* res = cast(word*) force(next!allBlocksLink(&this));
		assert(res != null);
		return res;
	}

	@trusted inout(word[]) words() return scope inout =>
		arrayOfRange!word(cast(inout word*) (&this + 1), end);
}

@safe bool isSentinel(in BlockNode* a) =>
	!has(a.alloc) && (isStartOfList!allBlocksLink(a) || isEndOfList!allBlocksLink(a));

@safe bool isFree(in BlockNode* a) =>
	!has(a.alloc) && !isSentinel(a);

@safe ref inout(DoubleLink!BlockNode) allBlocksLink(inout BlockNode* a) =>
	a.allBlocksLink_;

@safe ref inout(DoubleLink!BlockNode) allocLink(inout BlockNode* a) =>
	a.allocLink_;

// WARN: This brings 'meta' into an invalid state until you use the free block
@safe BlockNode* extractFreeBlock(ref MetaAlloc meta, size_t minWords) {
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
		return res;
	} else
		assert(false, "OOM");
}

// Splits the block and returns the new right half (which is linked to 'allBlocksLink' but not 'allocLink')
@trusted MutOpt!(BlockNode*) maybeSplitOffBlock(BlockNode* left, size_t leftSizeWords) {
	assert(left.words.length >= leftSizeWords);
	size_t remaining = left.words.length - leftSizeWords;
	if (remaining >= blockHeaderSizeWords + minBlockSizeWords) {
		BlockNode* right = cast(BlockNode*) &left.words[leftSizeWords];
		*right = BlockNode(left.alloc);
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
	block.alloc = noneMut!(Alloc*);
	assert(!isUnlinked!allBlocksLink(block));
	assert(isUnlinked!allocLink(block));
	BlockNode* left = force(prev!allBlocksLink(block));
	BlockNode* right = force(next!allBlocksLink(block));
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
	assert(!isFree(force(prev!allBlocksLink(block))) && !isFree(force(next!allBlocksLink(block))));
	// Find the free nodes to insert this one between.
	BlockNode* left = a.firstBlockSentinel;
	BlockNode* cur = force(next!allocLink(left));
	assert(isFree(cur) || isSentinel(cur));
	while (cur < block) {
		left = cur;
		cur = force(next!allocLink(cur));
	}
	assert(left < block && block < cur);
	insertToRight!allocLink(left, block);
}

// Anything less than this becomes fragmentation.
@safe size_t minBlockSizeWords() =>
	0x100;

@safe size_t preferredBlockWordCount() =>
	0x10000 - blockHeaderSizeWords;

@safe size_t blockHeaderSizeWords() {
	static assert(BlockNode.sizeof % word.sizeof == 0);
	return bytesToWords(BlockNode.sizeof);
}

bool blockOwns(T)(in BlockNode* a, in T* value) =>
	blockOwns(a, arrayOfSingle(value));
bool blockOwns(T)(in BlockNode* a, in T[] values) =>
	isSubArray(outerWordRange(values), a.words);
bool isSubArray(T)(in T[] a, in T[] b) =>
	b.ptr <= a.ptr && endPtr(a) <= endPtr(b);

word[] allocateWords(ref Alloc a, size_t nWords) {
	word* newCur = a.curWord + nWords;
	if (newCur > a.curBlock.end) {
		fetchNewBlock(&a, nWords);
		newCur = a.curWord + nWords;
	}
	assert(newCur <= a.curBlock.end);
	word[] res = a.curWord[0 .. nWords];
	a.curWord = newCur;
	assertOwns(a, res);
	return res;
}

void fetchNewBlock(Alloc* a, size_t minWords) {
	BlockNode* block = extractFreeBlock(*a.meta, minWords);
	block.alloc = someMut(a);
	insertToRight!allocLink(a.curBlock, block);
	a.curBlock = block;
	a.curWord = block.words.ptr;
	validate(*a.meta);
}

void freeWords(ref Alloc a, in word[] range) {
	// Do nothing for other frees, they will just be fragmentation within the arena
	if (a.curWord == endPtr(range)) {
		a.curWord = cast(word*) range.ptr;
	}
}

@trusted const(word[]) outerWordRange(T)(return in T[] range) =>
	arrayOfRange(roundDownToWord(cast(ubyte*) range.ptr), roundUpToWord(cast(ubyte*) endPtr(range)));

@trusted const(word[]) innerWordRange(T)(return in T[] range) {
	const word* begin = roundUpToWord(cast(ubyte*) range.ptr);
	const word* end = roundDownToWord(cast(ubyte*) endPtr(range));
	return begin < end ? arrayOfRange(begin, end) : [];
}

@safe size_t bytesToWords(size_t bytes) =>
	divRoundUp(bytes, word.sizeof);

@trusted const(word*) roundUpToWord(return in ubyte* a) {
	size_t rem = (cast(size_t) a) % word.sizeof;
	return cast(word*) (rem == 0 ? a : a - rem + word.sizeof);
}

@trusted const(word*) roundDownToWord(return in ubyte* a) =>
	cast(word*) (a - ((cast(size_t) a) % word.sizeof));
