module util.alloc.arena;

@safe @nogc pure nothrow:

import util.util : todo, verify;

struct Arena(Allocator) {
	this(Allocator a) {
		allocator_ = a;
	}

	private:

	Allocator allocator_;
	ubyte* begin_;
	ubyte* cur_;
	ubyte* end_;

	~this() {
		if (begin_ != null)
			allocator_.free(begin_, end_ - begin_);
	}

	@trusted ubyte* allocate(immutable size_t nBytes) {
		if (begin_ == null) {
			immutable size_t size = ARENA_SIZE;
			begin_ = allocator_.allocate(size);
			verify(begin_ != null);
			cur_ = begin_;
			end_ = begin_ + size;
			// Fill with 0xff for debugging
			for (ubyte* b = cur_; b < end_; b++)
				*b = 0xff;
		}

		verify(nBytes < 999999);

		ubyte* res = cur_;
		cur_ += nBytes;

		if (cur_ > end_)
			todo!void("Ran out of space!");

		// Since we filled with 0xff, should still be that way!
		for (ubyte* b = res; b < cur_; b++)
			verify(*b == 0xff);

		return res;
	}

	void free(ubyte*, size_t) {
		// do nothing
	}
}

//TODO:Don't hardcode
private immutable size_t ARENA_SIZE = 4 * 1024 * 1024;
