module util.perf;

@safe @nogc nothrow: // not pure

import util.alloc.alloc : Alloc, curBytes;
import util.col.enumMap : EnumMap, enumMapEach;
import util.col.sortUtil : sortInPlace;
import util.col.str : SafeCStr, safeCStr;
import util.comparison : compareUlong, oppositeComparison;
import util.util : verify;

T withMeasureNoAlloc(T, alias cb)(ref Perf perf, PerfMeasure measure) {
	PerfMeasurerNoAlloc measurer = startMeasureNoAlloc(perf, measure);
	T res = cb();
	endMeasureNoAlloc(perf, measurer);
	return res;
}

T withMeasure(T, alias cb)(ref Alloc alloc, scope ref Perf perf, PerfMeasure measure) {
	PerfMeasurer measurer = startMeasure(alloc, perf, measure);
	static if (is(T == void))
		cb();
	else
		T res = cb();
	endMeasure(alloc, perf, measurer);
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

@trusted pure PerfMeasurer startMeasure(ref Alloc alloc, scope ref Perf perf, PerfMeasure measure) {
	if (perfEnabled) {
		size_t bytesBefore = curBytes(alloc);
		ulong nsecBefore = perf.cbGetTimeNSec();
		return PerfMeasurer(measure, bytesBefore, nsecBefore, false);
	} else
		return PerfMeasurer(measure, 0, 0, false);
}

@trusted pure void pauseMeasure(ref Alloc alloc, scope ref Perf perf, scope ref PerfMeasurer measurer) {
	if (perfEnabled) {
		verify(!measurer.paused);
		addToMeasure(perf, measurer.measure, PerfMeasureResult(
			0,
			curBytes(alloc) - measurer.bytesBefore,
			perf.cbGetTimeNSec() - measurer.nsecBefore));
		measurer.paused = true;
	}
}

@trusted pure void resumeMeasure(ref Alloc alloc, scope ref Perf perf, scope ref PerfMeasurer measurer) {
	if (perfEnabled) {
		verify(measurer.paused);
		measurer.bytesBefore = curBytes(alloc);
		measurer.nsecBefore = perf.cbGetTimeNSec();
		measurer.paused = false;
	}
}

@trusted pure void endMeasure(ref Alloc alloc, scope ref Perf perf, scope ref PerfMeasurer measurer) {
	if (perfEnabled) {
		verify(!measurer.paused);
		addToMeasure(perf, measurer.measure, PerfMeasureResult(
			1,
			curBytes(alloc) - measurer.bytesBefore,
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
			cb(perfMeasureName(m.measure), m.result);
	}
}

ulong perfTotal(in Perf perf) =>
	perf.cbGetTimeNSec() - perf.nsecStart;

enum PerfMeasure {
	cCompile,
	checkCall,
	checkEverything,
	concretize,
	gccCompile,
	gccCreateProgram,
	gccJit,
	generateBytecode,
	lower,
	parseEverything,
	parseFile,
	run,
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

pure SafeCStr perfMeasureName(PerfMeasure a) {
	final switch (a) {
		case PerfMeasure.cCompile:
			return safeCStr!"cCompile";
		case PerfMeasure.checkCall:
			return safeCStr!"checkCall";
		case PerfMeasure.checkEverything:
			return safeCStr!"checkEverything";
		case PerfMeasure.concretize:
			return safeCStr!"concretize";
		case PerfMeasure.gccCreateProgram:
			return safeCStr!"gccCreateProgram";
		case PerfMeasure.gccCompile:
			return safeCStr!"gccCompile";
		case PerfMeasure.gccJit:
			return safeCStr!"gccJit";
		case PerfMeasure.generateBytecode:
			return safeCStr!"generateBytecode";
		case PerfMeasure.lower:
			return safeCStr!"lower";
		case PerfMeasure.parseEverything:
			return safeCStr!"parseEverything";
		case PerfMeasure.parseFile:
			return safeCStr!"parseFile";
		case PerfMeasure.run:
			return safeCStr!"run";
	}
}
