module test.testUtil;

@safe @nogc nothrow: // not pure

import std.meta : AliasSeq, staticMap;

import frontend.lang : crowExtension;
import frontend.showModel : ShowCtx, ShowOptions;
import frontend.storage : FileContent, FileType, fileType, LineAndColumnGetters, ReadFileResult, Storage;
import interpret.bytecode : ByteCode, ByteCodeIndex, Operation;
import interpret.debugInfo : showDataArr;
import interpret.stacks : dataTempAsArr, returnTempAsArrReverse, Stacks;
import lib.server : allUnknownUris, Server, setCwd, setFile, setIncludeDir;
import model.diag : ReadFileDiag;
import model.model : Program;
import util.alloc.alloc : Alloc, allocateElements, AllocKind, MetaAlloc, newAlloc, withTempAlloc, word;
import util.col.array : arraysEqual, arraysCorrespond, indexOf, isEmpty, makeArray, map;
import util.opt : force, has, none, Opt;
import util.perf : Perf;
import util.string : CString, stringOfCString;
import util.symbol : AllSymbols;
import util.uri : AllUris, concatUriAndPath, cStringOfUri, getExtension, isAncestor, parsePath, parseUri, Uri, UrisInfo;
import util.util : ptrTrustMe;
import util.writer : debugLogWithWriter, Writer;

struct Test {
	@safe @nogc pure nothrow:

	MetaAlloc* metaAlloc;
	Perf* perfPtr;
	Alloc* allocPtr;
	AllSymbols allSymbols;
	AllUris allUris;

	@trusted this(MetaAlloc* m, return scope Perf* p) {
		metaAlloc = m;
		perfPtr = p;
		allocPtr = newAlloc(AllocKind.test, m);
		allSymbols = AllSymbols(allocPtr);
		allUris = AllUris(allocPtr, &allSymbols);
	}

	ref Perf perf() return scope =>
		*perfPtr;
	ref Alloc alloc() return scope =>
		*allocPtr;
}

void withShowDiagCtxForTestImpure(
	scope ref Test test,
	scope ref Storage storage,
	in Program program,
	in void delegate(in ShowCtx) @safe @nogc nothrow cb,
) {
	withShowDiagCtxForTestImpl!cb(test, storage, program);
}

private void withShowDiagCtxForTestImpl(alias cb)(
	scope ref Test test,
	in Storage storage,
	in Program program,
) =>
	cb(ShowCtx(
		ptrTrustMe(test.allSymbols),
		ptrTrustMe(test.allUris),
		LineAndColumnGetters(ptrTrustMe(storage)),
		UrisInfo(none!Uri),
		ShowOptions(false),
		ptrTrustMe(program)));

@trusted void expectDataStack(ref Test test, in Stacks stacks, in immutable ulong[] expected) {
	scope immutable ulong[] stack = dataTempAsArr(stacks);
	if (!arraysEqual(stack, expected)) {
		debugLogWithWriter((ref Writer writer) {
			writer ~= "expected:\n";
			showDataArr(writer, expected);
			writer ~= "\nactual:\n";
			showDataArr(writer, stack);
		});
		assert(false);
	}
}

@trusted void expectReturnStack(
	ref Test test,
	in ByteCode byteCode,
	in Stacks stacks,
	in ByteCodeIndex[] expected,
) {
	// Ignore first entry (which is opStopInterpretation)
	scope immutable(Operation*)[] stack = reverse(test.alloc, returnTempAsArrReverse(stacks)[0 .. $ - 1]);
	bool eq = arraysCorrespond!(Operation*, ByteCodeIndex)(
		stack,
		expected,
		(ref const Operation* a, ref ByteCodeIndex b) @trusted =>
			ByteCodeIndex(a - byteCode.byteCode.ptr) == b);
	if (!eq) {
		debugLogWithWriter((ref Writer writer) @trusted {
			writer ~= "expected:\nreturn:";
			foreach (ByteCodeIndex index; expected) {
				writer ~= ' ';
				writer ~= index.index;
			}
			writer ~= "\nactual:\nreturn:";
			foreach (Operation* ptr; stack) {
				writer ~= ' ';
				writer ~= ptr - byteCode.byteCode.ptr;
			}
			writer ~= '\n';
		});
		assert(false);
	}
}

pure:

void assertEqual(in CString actual, in CString expected) {
	if (actual != expected) {
		debugLogWithWriter((scope ref Writer writer) {
			writer ~= "Actual: ";
			writer ~= actual;
			writer ~= "\nExpected: ";
			writer ~= expected;
		});
		assert(false);
	}
}

void withTestServer(
	ref Test test,
	in void delegate(ref Alloc, ref Server) @safe @nogc pure nothrow cb,
) {
	withTempAlloc!void(test.metaAlloc, (ref Alloc alloc) @trusted {
		scope Server server = Server((size_t sizeWords, size_t _) =>
			allocateElements!word(alloc, sizeWords));
		setIncludeDir(&server, parseUri(server.allUris, "test:///include"));
		setCwd(server, parseUri(server.allUris, "test:///"));
		return cb(alloc, server);
	});
}

void setupTestServer(ref Test test, ref Alloc alloc, ref Server server, Uri mainUri, in string mainContent) {
	assert(getExtension(server.allUris, mainUri) == crowExtension);
	setFile(test.perf, server, mainUri, mainContent);
	Uri[] testUris = map(alloc, testIncludePaths, (ref immutable string path) =>
		concatUriAndPath(server.allUris, server.includeDir, parsePath(server.allUris, path)));
	while (true) {
		Uri[] unknowns = allUnknownUris(alloc, server);
		if (isEmpty(unknowns))
			break;
		else
			foreach (Uri unknown; unknowns)
				setFile(test.perf, server, unknown, defaultFileResult(alloc, server, testUris, unknown));
	}
}

string defaultIncludeResult(string path) {
	Opt!size_t index = indexOf(testIncludePaths, path);
	return stringOfCString(testIncludeContents[force(index)]);
}

private:

ReadFileResult defaultFileResult(ref Alloc alloc, scope ref Server server, in Uri[] testUris, Uri uri) {
	final switch (fileType(server.allUris, uri)) {
		case FileType.crow:
			Opt!size_t index = indexOf(testUris, uri);
			if (has(index))
				return ReadFileResult(FileContent(testIncludeContents[force(index)]));
			else if (isAncestor(server.allUris, server.includeDir, uri)) {
				debug {
					import core.stdc.stdio : printf;
					printf("Missing URI: %s\n", cStringOfUri(alloc, server.allUris, uri).ptr);
				}
				assert(false);
			} else
				return ReadFileResult(ReadFileDiag.notFound);
		case FileType.crowConfig:
			return ReadFileResult(ReadFileDiag.notFound);
		case FileType.other:
			assert(false);
	}
}

alias testIncludePathsSeq = AliasSeq!(
	"crow/bits.crow",
	"crow/bool.crow",
	"crow/col/array.crow",
	"crow/col/collection.crow",
	"crow/col/experimental/frozen-map.crow",
	"crow/col/experimental/frozen-set.crow",
	"crow/col/experimental/index-set.crow",
	"crow/col/list.crow",
	"crow/col/map.crow",
	"crow/col/mut-array.crow",
	"crow/col/mut-list.crow",
	"crow/col/mut-map.crow",
	"crow/col/mut-set.crow",
	"crow/col/set.crow",
	"crow/col/sort.crow",
	"crow/col/private/array-low-level.crow",
	"crow/col/private/build.crow",
	"crow/col/private/list-low-level.crow",
	"crow/compare.crow",
	"crow/c-types.crow",
	"crow/enum-util.crow",
	"crow/exception.crow",
	"crow/flags-util.crow",
	"crow/fun-util.crow",
	"crow/future.crow",
	"crow/hash.crow",
	"crow/io/print.crow",
	"crow/io/private/time-low-level.crow",
	"crow/io/win32-util.crow",
	"crow/json.crow",
	"crow/log.crow",
	"crow/misc.crow",
	"crow/number.crow",
	"crow/option.crow",
	"crow/parse.crow",
	"crow/pointer.crow",
	"crow/private/alloc.crow",
	"crow/private/backtrace.crow",
	"crow/private/bare-map.crow",
	"crow/private/bare-priority-queue.crow",
	"crow/private/bare-queue.crow",
	"crow/private/bool-low-level.crow",
	"crow/private/bootstrap.crow",
	"crow/private/c-string-util.crow",
	"crow/private/exception-low-level.crow",
	"crow/private/exclusion-queue.crow",
	"crow/private/future-low-level.crow",
	"crow/private/libunwind.crow",
	"crow/private/number-low-level.crow",
	"crow/private/range-low-level.crow",
	"crow/private/runtime.crow",
	"crow/private/rt-main.crow",
	"crow/private/symbol-low-level.crow",
	"crow/private/task-queue.crow",
	"crow/private/thread-utils.crow",
	"crow/range.crow",
	"crow/result.crow",
	"crow/std.crow",
	"crow/string.crow",
	"crow/symbol.crow",
	"crow/test-util.crow",
	"crow/tuple.crow",
	"crow/version.crow",
	"errno.crow",
	"pthread.crow",
	"setjmp.crow",
	"stdio.crow",
	"stdlib.crow",
	"string.crow",
	"sys/sysinfo.crow",
	"sys/types.crow",
	"time.crow",
	"unistd.crow",
	"win32.crow",
	"windows/DbgHelp.crow",
);
immutable string[] testIncludePaths = [testIncludePathsSeq];
immutable CString[testIncludePaths.length] testIncludeContents = [staticMap!(getIncludeText, testIncludePathsSeq)];
enum getIncludeText(string path) = CString(import(path));

T[] reverse(T)(ref Alloc alloc, scope T[] xs) =>
	makeArray(alloc, xs.length, (size_t i) =>
		xs[xs.length - 1 - i]);
