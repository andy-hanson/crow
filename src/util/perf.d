module util.perf;

@safe @nogc nothrow: // not pure

import util.alloc.alloc : Alloc, perf_curBytes;
import util.col.enumMap : EnumMap, enumMapEach;
import util.col.sortUtil : sortInPlace;
import util.col.str : SafeCStr;
import util.comparison : compareUlong, oppositeComparison;
import util.util : safeCStrOfEnum;

T withMeasureNoAlloc(T, alias cb)(ref Perf perf, PerfMeasure measure) {
	PerfMeasurerNoAlloc measurer = startMeasureNoAlloc(perf, measure);
	T res = cb();
	endMeasureNoAlloc(perf, measurer);
	return res;
}

T withMeasure(T, alias cb)(scope ref Perf perf, ref Alloc alloc, PerfMeasure measure) {
	PerfMeasurer measurer = startMeasure(perf, alloc, measure);
	static if (is(T == void))
		cb();
	else
		T res = cb();
	endMeasure(perf, alloc, measurer);
	static if (!is(T == void))
		return res;
}

T withNullPerf(T, alias cb)() {
	Perf perf = Perf(() => 0);
	return cb(perf);
}

struct Perf {
	@safe @nogc pure nothrow:

	ulong delegate() @safe @nogc pure nothrow cbGetTimeNSec;
	ulong nsecStart;
	private EnumMap!(PerfMeasure, PerfMeasureResult) measures;

	this(return scope ulong delegate() @safe @nogc pure nothrow cb) {
		cbGetTimeNSec = cb;
		if (perfEnabled)
			nsecStart = cb();
	}
}

pure bool perfEnabled() =>
	false;

private struct PerfMeasurerNoAlloc {
	private:
	immutable PerfMeasure measure;
	ulong nsecBefore;
}

private pure PerfMeasurerNoAlloc startMeasureNoAlloc(ref Perf perf, PerfMeasure measure) =>
	perfEnabled ? PerfMeasurerNoAlloc(measure, perf.cbGetTimeNSec()) : PerfMeasurerNoAlloc(measure, 0);

private pure void endMeasureNoAlloc(ref Perf perf, ref PerfMeasurerNoAlloc measurer) {
	if (perfEnabled)
		addToMeasure(perf, measurer.measure, PerfMeasureResult(1, 0, perf.cbGetTimeNSec() - measurer.nsecBefore));
}

struct PerfMeasurer {
	private:
	immutable PerfMeasure measure;
	size_t bytesBefore;
	ulong nsecBefore;
	bool paused;
}

@trusted pure PerfMeasurer startMeasure(scope ref Perf perf, ref Alloc alloc, PerfMeasure measure) {
	if (perfEnabled) {
		size_t bytesBefore = perf_curBytes(alloc);
		ulong nsecBefore = perf.cbGetTimeNSec();
		return PerfMeasurer(measure, bytesBefore, nsecBefore, false);
	} else
		return PerfMeasurer(measure, 0, 0, false);
}

@trusted pure void pauseMeasure(scope ref Perf perf, ref Alloc alloc, scope ref PerfMeasurer measurer) {
	if (perfEnabled) {
		assert(!measurer.paused);
		addToMeasure(perf, measurer.measure, PerfMeasureResult(
			0,
			perf_curBytes(alloc) - measurer.bytesBefore,
			perf.cbGetTimeNSec() - measurer.nsecBefore));
		measurer.paused = true;
	}
}

@trusted pure void resumeMeasure(scope ref Perf perf, ref Alloc alloc, scope ref PerfMeasurer measurer) {
	if (perfEnabled) {
		assert(measurer.paused);
		measurer.bytesBefore = perf_curBytes(alloc);
		measurer.nsecBefore = perf.cbGetTimeNSec();
		measurer.paused = false;
	}
}

@trusted pure void endMeasure(scope ref Perf perf, ref Alloc alloc, scope ref PerfMeasurer measurer) {
	if (perfEnabled) {
		assert(!measurer.paused);
		addToMeasure(perf, measurer.measure, PerfMeasureResult(
			1,
			perf_curBytes(alloc) - measurer.bytesBefore,
			perf.cbGetTimeNSec() - measurer.nsecBefore));
	}
}

struct PerfMeasureResult {
	uint count;
	size_t bytesAllocated;
	ulong nanoseconds;
}

private struct PerfResultWithMeasure {
	PerfMeasure measure;
	PerfMeasureResult result;
}

void eachMeasure(in Perf perf, in void delegate(in SafeCStr, in PerfMeasureResult) @safe @nogc nothrow cb) {
	PerfResultWithMeasure[PerfMeasure.max + 1] results;
	enumMapEach!(PerfMeasure, PerfMeasureResult)(
		perf.measures,
		(PerfMeasure measure, in PerfMeasureResult result) {
			results[measure] = PerfResultWithMeasure(measure, perf.measures[measure]);
		});
	sortInPlace!PerfResultWithMeasure(results, (in PerfResultWithMeasure a, in PerfResultWithMeasure b) =>
		oppositeComparison(compareUlong(a.result.nanoseconds, b.result.nanoseconds)));
	foreach (ref const PerfResultWithMeasure m; results) {
		if (m.result.count)
			cb(safeCStrOfEnum(m.measure), m.result);
	}
}

ulong perfTotal(in Perf perf) =>
	perfEnabled ? perf.cbGetTimeNSec() - perf.nsecStart : 0;

enum PerfMeasure {
	cCompile,
	check,
	checkCall,
	concretize,
	gccCompile,
	gccCreateProgram,
	gccJit,
	generateBytecode,
	instantiateFun,
	instantiateSpec,
	instantiateStruct,
	lower,
	parseFile,
	run,
	onFileChanged, // This includes all type-checking
}

private:

pure void addToMeasure(ref Perf perf, PerfMeasure measure, PerfMeasureResult result) {
	perf.measures[measure] = add(perf.measures[measure], result);
}

pure PerfMeasureResult add(PerfMeasureResult a, PerfMeasureResult b) =>
	PerfMeasureResult(
		a.count + b.count,
		a.bytesAllocated + b.bytesAllocated,
		a.nanoseconds + b.nanoseconds);
