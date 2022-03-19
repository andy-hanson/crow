module interpret.fakeExtern;

@safe @nogc nothrow: // not pure

import interpret.extern_ : DynCallType, Extern;
import lib.compiler : ExitCode;
import util.alloc.alloc : Alloc, allocateBytes;
import util.col.mutArr : moveToArr, MutArr, pushAll;
import util.sym : AllSymbols, safeCStrOfSym, Sym;
import util.util : debugLog, todo, verify;

struct FakeExternResult {
	immutable ExitCode err;
	immutable string stdout;
	immutable string stderr;
}

immutable(FakeExternResult) withFakeExtern(
	ref Alloc alloc,
	ref const AllSymbols allSymbols,
	scope immutable(ExitCode) delegate(scope ref Extern) @safe @nogc nothrow cb,
) {
	MutArr!(immutable char) stdout;
	MutArr!(immutable char) stderr;
	scope Extern extern_ = Extern(
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
		(immutable Sym name, immutable(DynCallType), scope immutable ulong[], scope immutable DynCallType[]) {
			version (WebAssembly) {
				debugLog("Can't call extern function from fake extern:");
				debugLog(safeCStrOfSym(alloc, allSymbols, name).ptr);
			}
			return todo!(immutable ulong)("not for fake");
		});
	immutable ExitCode err = cb(extern_);
	return immutable FakeExternResult(err, moveToArr(alloc, stdout), moveToArr(alloc, stderr));
}
