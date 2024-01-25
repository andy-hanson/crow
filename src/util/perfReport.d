module util.perfReport;

@safe @nogc pure nothrow:

import util.alloc.alloc :
	Alloc,
	AllocKind,
	AllocKindMemorySummary,
	MemorySummary,
	MetaAlloc,
	MetaMemorySummary,
	summarizeMemory,
	totalBytes;
import util.col.arrayBuilder : buildArray, Builder, arrBuilderSort;
import util.col.array : map;
import util.col.enumMap : EnumMap;
import util.col.exactSizeArrayBuilder : buildArrayExact, ExactSizeArrayBuilder;
import util.col.map : KeyValuePair;
import util.comparison : compareUlong, oppositeComparison;
import util.json : field, Json, jsonObject;
import util.opt : force, has, none, Opt, some;
import util.perf : Perf, PerfMeasure, PerfMeasureResult, PerfResult, perfResult;
import util.string : CString;
import util.symbol : symbolOfEnum;
import util.writer : withWriter, Writer;

Json perfReport(ref Alloc alloc, in Perf perf, in MetaAlloc metaAlloc, Json stats) =>
	jsonObject(alloc, [
		field!"memory"(showMemorySummary(alloc, summarizeMemory(metaAlloc))),
		field!"time"(showTimeSummary(alloc, perfResult(perf))),
		field!"stats"(stats)]);

private:

Json showTimeSummary(ref Alloc alloc, in PerfResult a) =>
	jsonObject(alloc, [
		field!"total"(showTimeAmount(alloc, a.totalNanoseconds)),
		field!"byMeasure"(jsonOfEnumMap!(PerfMeasure, PerfMeasureResult)(
			alloc,
			a.byMeasure,
			(in PerfMeasureResult x) => x.nanoseconds,
			(in PerfMeasureResult x) =>
				jsonObject(alloc, [
					field!"time"(showTimeAmount(alloc, x.nanoseconds)),
					field!"bytes"(showMemoryAmount(alloc, x.bytesAllocated)),
					field!"times"(x.count)])))]);

Json showMemorySummary(ref Alloc alloc, in MetaMemorySummary a) =>
	jsonObject(alloc, [
		field!"total"(showMemory(alloc, a.total)),
		field!"mallocs"(a.timesFetchedMemory),
		field!"freeBlocks"(a.countFreeBlocks),
		field!"byAlloc"(jsonOfEnumMap!(AllocKind, AllocKindMemorySummary)(
			alloc,
			a.byAllocKind,
			(in AllocKindMemorySummary x) =>
				totalBytes(x.summary),
			(in AllocKindMemorySummary x) =>
				showMemory(alloc, x)))]);

Json jsonOfEnumMap(E, V)(
	ref Alloc alloc,
	in immutable EnumMap!(E, V) a,
	in ulong delegate(in V) @safe @nogc pure nothrow getQuantity,
	in Json delegate(in V) @safe @nogc pure nothrow cb,
) {
	alias Pair = immutable KeyValuePair!(E, V);
	Pair[] pairs = buildArray!Pair(alloc, (scope ref Builder!Pair res) {
		foreach (E key, ref immutable V value; a)
			if (getQuantity(value) != 0)
				res ~= Pair(key, value);
		arrBuilderSort!(Pair)(res, (in Pair x, in Pair y) =>
			oppositeComparison(compareUlong(getQuantity(x.value), getQuantity(y.value))));
	});
	return Json(map(alloc, pairs, (ref Pair pair) =>
		Json.ObjectField(symbolOfEnum(pair.key), cb(pair.value))));
}

Json showMemory(ref Alloc alloc, in AllocKindMemorySummary a) =>
	showMemoryCommon(alloc, some(a.countAllocs), a.summary);

Json showMemory(ref Alloc alloc, in MemorySummary a) =>
	showMemoryCommon(alloc, none!size_t, a);

Json showMemoryCommon(ref Alloc alloc, Opt!size_t countAllocs, in MemorySummary a) =>
	Json(buildArrayExact!(Json.ObjectField)(
		alloc,
		has(countAllocs) ? 6 : 5,
		(scope ref ExactSizeArrayBuilder!(Json.ObjectField) res) {
			res ~= field!"total"(showMemoryAmount(alloc, totalBytes(a)));
			res ~= field!"used"(showMemoryAmount(alloc, a.usedBytes));
			res ~= field!"free"(showMemoryAmount(alloc, a.freeBytes));
			res ~= field!"overhead"(showMemoryAmount(alloc, a.overheadBytes));
			res ~= field!"countBlocks"(a.countBlocks);
			if (has(countAllocs))
				res ~= field!"countAllocs"(force(countAllocs));
		}));

CString showMemoryAmount(ref Alloc alloc, size_t bytes) =>
	withWriter(alloc, (scope ref Writer writer) {
		size_t KB = 0x400;
		size_t MB = KB * KB;
		if (bytes > MB) {
			writer ~= bytes / MB;
			writer ~= "MB ";
		}
		if (bytes > 1024) {
			writer ~= (bytes % MB) / KB;
			writer ~= "KB ";
		}
		writer ~= (bytes % KB);
		writer ~= "B";
	});

CString showTimeAmount(ref Alloc alloc, ulong nanoseconds) =>
	withWriter(alloc, (scope ref Writer writer) {
		writer ~= divRound(nanoseconds, 1_000_000);
		writer ~= "ms";
	});

ulong divRound(ulong a, ulong b) {
	ulong div = a / b;
	ulong rem = a % b;
	return div + (rem >= b / 2 ? 1 : 0);
}
static assert(divRound(15, 10) == 2);
static assert(divRound(14, 10) == 1);
