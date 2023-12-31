module app.backtrace;

@safe @nogc nothrow: // not pure

import core.stdc.stdint : uintptr_t;
import core.stdc.stdio : fprintf;
import app.fileSystem : stderr;

@system void printBacktrace() {
	version (Windows) {} else {
		unw_cursor_t cursor;
		unw_context_t context;
		int err = unw_getcontext(&context);
		err = err || unw_init_local(&cursor, &context);
		bool step() {
			if (err == 0) {
				int res = unw_step(&cursor);
				if (res < 0)
					err = -res;
				return res > 0;
			} else
				return false;
		}
		// skip '__assert' and 'printBacktrace'
		foreach (size_t i; 0 .. 2)
			step();
		while (step()) {
			unw_word_t offset = 0;
			char[1024] buf;
			err = err || unw_get_proc_name(&cursor, buf.ptr, buf.length, &offset);
			if (err == 0)
				fprintf(stderr, "\tat %s\n", buf.ptr);
		}
		if (err != 0)
			fprintf(stderr, "\terror getting backtrace\n");
	}
}

private:

version (Windows) {} else {
	alias unw_word_t = uintptr_t;
	struct unw_context_t {
		ulong[1024] data = void;
	}
	struct unw_cursor_t {
		ulong[1024] data = void;
	}

	@system:
	int unw_getcontext(unw_context_t* a) =>
		_Ux86_64_getcontext(a);
	extern(C) int _Ux86_64_getcontext(unw_context_t*);
	int unw_init_local(unw_cursor_t* a, unw_context_t* b) =>
		_ULx86_64_init_local(a, b);
	extern(C) int _ULx86_64_init_local(unw_cursor_t*, unw_context_t*);
	int unw_step(unw_cursor_t* a) =>
		_ULx86_64_step(a);
	extern(C) int _ULx86_64_step(unw_cursor_t*);
	int unw_get_proc_name(unw_cursor_t* a, char* b, size_t c, unw_word_t* d) =>
		_ULx86_64_get_proc_name(a, b, c, d);
	extern(C) int _ULx86_64_get_proc_name(unw_cursor_t*, char*, size_t, unw_word_t*);
}
