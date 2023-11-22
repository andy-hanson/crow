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

struct MetaAlloc {
	@safe @nogc pure nothrow:

	@disable this();
	@disable this(ref const MetaAlloc);
	@trusted this(return scope word[] w) {
		words = w;
		cur = words.ptr;
	}

	word[] words;
	word* cur;
}

Alloc newAlloc(return scope ref MetaAlloc a) =>
	Alloc(&a, allocateBlock(a, 0));

private size_t wordsLeft(in MetaAlloc a) =>
	endPtr(a.words) - a.cur;

private BlockHeader* allocateBlock(ref MetaAlloc a, size_t minWords) {
	verify(minWords <= wordsLeft(a) - blockHeaderSizeWords);
	BlockHeader* res = cast(BlockHeader*) a.cur;
	size_t sizeWords = clamp(preferredBlockWordCount, minWords, wordsLeft(a) - blockHeaderSizeWords);
	a.cur = (cast(word*) (res + 1)) + sizeWords;
	verify(a.cur <= endPtr(a.words));
	res.allocPrev = null;
	res.end = a.cur;
	verify(countWords(res) == sizeWords);
	return res;
}

private size_t preferredBlockWordCount() =>
	0x100000 - blockHeaderSizeWords;

private size_t blockHeaderSizeWords() =>
	bytesToWords(BlockHeader.sizeof);

private struct BlockHeader {
	// For use by Alloc, MetaAlloc will ignore
	BlockHeader* allocPrev;
	// Points after the last word in the block
	word* end;
}
static assert(BlockHeader.sizeof % word.sizeof == 0);

private inout(word*) firstWord(return scope inout BlockHeader* a) =>
	// First word in the block comes after the header
	cast(word*) (a + 1);

// Number of words in the block, not including the header
private size_t countWords(in BlockHeader* a) =>
	a.end - firstWord(a);

struct Alloc {
	@safe @nogc pure nothrow:

	private:

	@disable this();
	@disable this(ref const Alloc);
	@system this(MetaAlloc* m, BlockHeader* b) {
		meta = m;
		verify(b.allocPrev == null);
		curBlock = b;
		cur = firstWord(b);
	}

	MetaAlloc* meta;
	BlockHeader* curBlock;
	word* cur;
}

alias TempAlloc = Alloc;

@trusted void verifyOwns(T)(in Alloc alloc, in T[] values) {
	verify(allocOwns(alloc, values));
}
private bool allocOwns(T)(in Alloc alloc, in T[] values) =>
	existsBlock(alloc, (in BlockHeader* b) => blockOwns(b, values));
private bool blockOwns(T)(in BlockHeader* a, in T[] values) =>
	firstWord(a) <= cast(ulong*) values.ptr && cast(ulong*) endPtr(values) <= a.end;

private void eachPrevBlock(in Alloc a, in void delegate(in BlockHeader*) @nogc pure nothrow cb) {
	const(BlockHeader)* block = a.curBlock.allocPrev;
	while (block != null) {
		cb(block);
		block = block.allocPrev;
	}
}

private bool existsBlock(in Alloc a, in bool delegate(in BlockHeader*) @nogc pure nothrow cb) {
	const(BlockHeader)* block = a.curBlock;
	do {
		if (cb(block))
			return true;
		block = block.allocPrev;
	} while (block != null);
	return false;
}

size_t perf_curBytes(ref Alloc alloc) {
	size_t words = alloc.cur - firstWord(alloc.curBlock);
	size_t n = 0;
	eachPrevBlock(alloc, (in BlockHeader* x) {
		words += countWords(x);
		n++;
		verify(n < 100);
	});
	return words * word.sizeof;
}

ubyte[] allocateBytes(ref Alloc alloc, size_t sizeBytes) =>
	(cast(ubyte*) allocateWords(alloc, bytesToWords(sizeBytes)).ptr)[0 .. sizeBytes];

@trusted T withStackAlloc(size_t sizeWords, T)(in T delegate(ref Alloc) @safe @nogc pure nothrow cb) {
	ulong[sizeWords] memory = void;
	return withStaticAlloc!(T, cb)(memory);
}

private word[] allocateWords(ref Alloc alloc, size_t nWords) {
	word* newCur = alloc.cur + nWords;
	if (newCur > alloc.curBlock.end) {
		fetchNewBlock(alloc, nWords);
		newCur = alloc.cur + nWords;
	}
	verify(newCur <= alloc.curBlock.end);
	word[] res = alloc.cur[0 .. nWords];
	alloc.cur = newCur;
	verifyOwns(alloc, res);
	return res;
}

private void fetchNewBlock(ref Alloc alloc, size_t minWords) {
	BlockHeader* newBlock = allocateBlock(*alloc.meta, minWords);
	verify(countWords(newBlock) >= minWords);
	verify(newBlock.allocPrev == null);
	newBlock.allocPrev = alloc.curBlock;
	alloc.curBlock = newBlock;
	alloc.cur = firstWord(newBlock);
}

T* allocateUninitialized(T)(ref Alloc alloc) =>
	&allocateElements!T(alloc, 1)[0];

T[] allocateElements(T)(ref Alloc alloc, size_t count) =>
	(cast(T*) allocateBytes(alloc, T.sizeof * count).ptr)[0 .. count];

void freeElements(T)(ref Alloc alloc, in T[] range) {
	freeWords(alloc, innerWordRange(range));
}

private:

void freeWords(ref Alloc alloc, in word[] range) {
	// Do nothing for other frees, they will just be fragmentation within the arena
	if (alloc.cur == endPtr(range)) {
		alloc.cur = cast(word*) range.ptr;
	}
}

const(word[]) innerWordRange(T)(return in T[] range) {
	const word* begin = roundUpToWord(cast(ubyte*) range.ptr);
	const word* end = roundDownToWord(cast(ubyte*) endPtr(range));
	return begin < end ? arrOfRange(begin, end) : [];
}

alias word = ulong;

size_t bytesToWords(size_t bytes) =>
	divRoundUp(bytes, word.sizeof);

const(word*) roundUpToWord(return in ubyte* a) {
	size_t rem = (cast(size_t) a) % word.sizeof;
	return cast(word*) (rem == 0 ? a : a - rem + word.sizeof);
}

const(word*) roundDownToWord(return in ubyte* a) =>
	cast(word*) (a - ((cast(size_t) a) % word.sizeof));
