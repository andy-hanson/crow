module util.alloc.arena;

@safe @nogc pure nothrow:

import util.ptr : Ptr;
import util.util : max, verify;

struct Arena(ParentAlloc, string debugName, size_t minBlockSize = 1024 * 1024) {
	@safe @nogc pure nothrow:

	static assert(minBlockSize > BlockHeader.sizeof);

	@disable this();
	this(Ptr!ParentAlloc parent) {
		parentAlloc_ = parent;
	}

	@trusted ~this() {
		while (curBlock_ != null) {
			BlockHeader* block = curBlock_;
			curBlock_ = block.prevBlock;
			parentAlloc_.free(cast(ubyte*) block, block.sizeBytes);
		}
	}

	@trusted ubyte* allocate(immutable size_t nBytes) {
		if (cur_ + nBytes > endOfBlock_)
			nextBlock(max(BlockHeader.sizeof + nBytes, minBlockSize));
		verify(cur_ + nBytes <= endOfBlock_);
		ubyte* res = cur_;
		cur_ += nBytes;
		return res;
	}

	void freePartial(ubyte*, immutable size_t) {
		// do nothing
	}

	void free(ubyte*, immutable size_t) {
		// do nothing
	}

	private:
	Ptr!ParentAlloc parentAlloc_;
	BlockHeader* curBlock_;
	ubyte* cur_;
	ubyte* endOfBlock_;

	@system void nextBlock(immutable size_t size) {
		BlockHeader* prevBlock = curBlock_;
		curBlock_ = cast(BlockHeader*) parentAlloc_.allocate(size);
		*curBlock_ = BlockHeader(prevBlock, size);
		cur_ = cast(ubyte*) (curBlock_ + 1);
		endOfBlock_ = cur_ + size - BlockHeader.sizeof;
	}
}

private:

struct BlockHeader {
	BlockHeader* prevBlock; // nullable
	size_t sizeBytes;
}
