module util.perf;

@safe @nogc nothrow:

import util.alloc.alloc : Alloc, curBytes;
import util.col.sortUtil : sortInPlace;
import util.col.str : SafeCStr, safeCStr;
import util.comparison : compareUlong, oppositeComparison;
import util.util : verify;

immutable(T) withMeasureNoAlloc(T, alias cb)(
	ref Perf perf,
	immutable PerfMeasure measure,
) {
	PerfMeasurerNoAlloc measurer = startMeasureNoAlloc(perf, measure);
	immutable T res = cb();
	endMeasureNoAlloc(perf, measurer);
	return res;
}

immutable(T) withMeasure(T, alias cb)(
	ref Alloc alloc,
	scope ref Perf perf,
	immutable PerfMeasure measure,
) {
	PerfMeasurer measurer = startMeasure(alloc, perf, measure);
	static if (is(T == void))
		cb();
	else
		immutable T res = cb();
	endMeasure(alloc, perf, measurer);
	static if (!is(T == void))
		return res;
}

immutable(T) withNullPerf(T, alias cb)() {
	Perf perf = Perf(() => immutable ulong(0));
	return cb(perf);
}

@safe @nogc nothrow: // not pure

struct Perf {
	@safe pure @nogc nothrow:

	// TODO: this dummy constructor is apparently needed to prevent DMD from calling a function '_memsetn'
	this(return scope immutable(ulong) delegate() @safe @nogc pure nothrow cb) scope {
		cbGetTimeNSec = cb;
	}

	immutable(ulong) delegate() @safe @nogc pure nothrow cbGetTimeNSec;
	private:
	PerfMeasureResult[PerfMeasure.max + 1] measures;
}

immutable bool perfEnabled = true;

private struct PerfMeasurerNoAlloc {
	private:
	immutable PerfMeasure measure;
	ulong nsecBefore;
}

private pure PerfMeasurerNoAlloc startMeasureNoAlloc(ref Perf perf, immutable PerfMeasure measure) {
	return perfEnabled ? PerfMeasurerNoAlloc(measure, perf.cbGetTimeNSec()) : PerfMeasurerNoAlloc(measure, 0);
}

private void endMeasureNoAlloc(ref Perf perf, ref PerfMeasurerNoAlloc measurer) {
	if (perfEnabled)
		addToMeasure(
			perf,
			measurer.measure,
			immutable PerfMeasureResult(1, 0, perf.cbGetTimeNSec() - measurer.nsecBefore));
}

struct PerfMeasurer {
	private:
	immutable PerfMeasure measure;
	size_t bytesBefore;
	ulong nsecBefore;
	bool paused;
}

@trusted pure PerfMeasurer startMeasure(ref Alloc alloc, scope ref Perf perf, immutable PerfMeasure measure) {
	if (perfEnabled) {
		immutable size_t bytesBefore = curBytes(alloc);
		immutable ulong nsecBefore = perf.cbGetTimeNSec();
		return PerfMeasurer(measure, bytesBefore, nsecBefore, false);
	} else
		return PerfMeasurer(measure, 0, 0, false);
}

@trusted pure void pauseMeasure(ref Alloc alloc, scope ref Perf perf, ref PerfMeasurer measurer) {
	if (perfEnabled) {
		verify(!measurer.paused);
		addToMeasure(perf, measurer.measure, immutable PerfMeasureResult(
			0,
			curBytes(alloc) - measurer.bytesBefore,
			perf.cbGetTimeNSec() - measurer.nsecBefore));
		measurer.paused = true;
	}
}

@trusted pure void resumeMeasure(ref Alloc alloc, scope ref Perf perf, ref PerfMeasurer measurer) {
	if (perfEnabled) {
		verify(measurer.paused);
		measurer.bytesBefore = curBytes(alloc);
		measurer.nsecBefore = perf.cbGetTimeNSec();
		measurer.paused = false;
	}
}

@trusted pure void endMeasure(ref Alloc alloc, scope ref Perf perf, ref PerfMeasurer measurer) {
	if (perfEnabled) {
		verify(!measurer.paused);
		addToMeasure(perf, measurer.measure, immutable PerfMeasureResult(
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

void eachMeasure(
	scope ref Perf perf,
	scope void delegate(immutable SafeCStr, immutable PerfMeasureResult) @safe @nogc nothrow cb,
) {
	PerfResultWithMeasure[PerfMeasure.max + 1] results;
	foreach (immutable uint measure; 0 .. PerfMeasure.max + 1)
		results[measure] = PerfResultWithMeasure(cast(immutable PerfMeasure) measure, perf.measures[measure]);
	sortInPlace!PerfResultWithMeasure(results, (ref const PerfResultWithMeasure a, ref const PerfResultWithMeasure b) =>
		oppositeComparison(compareUlong(a.result.nanoseconds, b.result.nanoseconds)));
	foreach (ref const PerfResultWithMeasure m; results) {
		if (m.result.count)
			cb(perfMeasureName(m.measure), m.result);
	}
}

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

pure void addToMeasure(ref Perf perf, immutable PerfMeasure measure, immutable PerfMeasureResult result) {
	perf.measures[measure] = add(perf.measures[measure], result);
}

pure immutable(PerfMeasureResult) add(immutable PerfMeasureResult a, immutable PerfMeasureResult b) {
	return immutable PerfMeasureResult(
		a.count + b.count,
		a.bytesAllocated + b.bytesAllocated,
		a.nanoseconds + b.nanoseconds);
}

pure immutable(SafeCStr) perfMeasureName(immutable PerfMeasure a) {
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

