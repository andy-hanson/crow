module interpret.fakeExtern;

@safe @nogc nothrow: // not pure

import interpret.extern_ : DynCallType, Extern, TimeSpec;
import lib.compiler : ExitCode;
import util.alloc.alloc : Alloc, allocateBytes;
import util.col.mutArr : moveToArr, MutArr, pushAll;
import util.ptr : Ptr;
import util.sym : Sym;
import util.util : todo, verify;

struct FakeExternResult {
	immutable ExitCode err;
	immutable string stdout;
	immutable string stderr;
}

immutable(FakeExternResult) withFakeExtern(
	ref Alloc alloc,
	scope immutable(ExitCode) delegate(scope ref Extern) @safe @nogc nothrow cb,
) {
	MutArr!(immutable char) stdout;
	MutArr!(immutable char) stderr;
	uint monoTime = 0;
	scope Extern extern_ = Extern(
		(immutable int clockId, Ptr!TimeSpec timeSpec) {
			if (clockId == 1) {
				timeSpec.deref() = immutable TimeSpec(monoTime, 0);
				monoTime++;
				return 0;
			} else
				return todo!int("!");
		},
		(ubyte* ptr) {
			// TODO: free
		},
		(immutable size_t size) {
			return allocateBytes(alloc, size);
		},
		(immutable int fd, immutable char* buf, immutable size_t nBytes) {
			immutable char[] arr = buf[0 .. nBytes];
			verify(fd == 1 || fd == 2);
			pushAll!char(alloc, fd == 1 ? stdout : stderr, arr);
			return nBytes;
		},
		(immutable(Sym), immutable(DynCallType), scope immutable ulong[], scope immutable DynCallType[]) =>
			todo!(immutable ulong)("not for fake"));
	immutable ExitCode err = cb(extern_);
	return immutable FakeExternResult(err, moveToArr(alloc, stdout), moveToArr(alloc, stderr));
}
