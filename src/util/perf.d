module util.perf;

@safe @nogc nothrow: // not pure

import util.alloc.alloc : Alloc, perf_curBytes;
import util.col.enumMap : EnumMap;

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
	Perf perf = Perf();
	return cb(perf);
}

struct Perf {
	@safe @nogc pure nothrow:

	ulong delegate() @safe @nogc pure nothrow cbGetTimeNSec; // nullable
	ulong nsecStart;
	private EnumMap!(PerfMeasure, PerfMeasureResult) measures;

	this(bool) {} // for disabled perf
	this(return scope ulong delegate() @safe @nogc pure nothrow cb) {
		cbGetTimeNSec = cb;
		nsecStart = cb();
	}
}

pure:

void disablePerf(scope ref Perf a) {
	a.cbGetTimeNSec = null;
}

bool isEnabled(in Perf a) =>
	a.cbGetTimeNSec != null;

private struct PerfMeasurerNoAlloc {
	private:
	immutable PerfMeasure measure;
	ulong nsecBefore;
}

private pure PerfMeasurerNoAlloc startMeasureNoAlloc(ref Perf perf, PerfMeasure measure) =>
	isEnabled(perf) ? PerfMeasurerNoAlloc(measure, perf.cbGetTimeNSec()) : PerfMeasurerNoAlloc(measure, 0);

private pure void endMeasureNoAlloc(ref Perf perf, ref PerfMeasurerNoAlloc measurer) {
	if (isEnabled(perf))
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
	if (isEnabled(perf)) {
		size_t bytesBefore = perf_curBytes(alloc);
		ulong nsecBefore = perf.cbGetTimeNSec();
		return PerfMeasurer(measure, bytesBefore, nsecBefore, false);
	} else
		return PerfMeasurer(measure, 0, 0, false);
}

@trusted pure void pauseMeasure(scope ref Perf perf, ref Alloc alloc, scope ref PerfMeasurer measurer) {
	if (isEnabled(perf)) {
		assert(!measurer.paused);
		addToMeasure(perf, measurer.measure, PerfMeasureResult(
			0,
			perf_curBytes(alloc) - measurer.bytesBefore,
			perf.cbGetTimeNSec() - measurer.nsecBefore));
		measurer.paused = true;
	}
}

@trusted pure void resumeMeasure(scope ref Perf perf, ref Alloc alloc, scope ref PerfMeasurer measurer) {
	if (isEnabled(perf)) {
		assert(measurer.paused);
		measurer.bytesBefore = perf_curBytes(alloc);
		measurer.nsecBefore = perf.cbGetTimeNSec();
		measurer.paused = false;
	}
}

@trusted pure void endMeasure(scope ref Perf perf, ref Alloc alloc, scope ref PerfMeasurer measurer) {
	if (isEnabled(perf)) {
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

immutable struct PerfResult {
	ulong totalNanoseconds;
	EnumMap!(PerfMeasure, PerfMeasureResult) byMeasure;
}

PerfResult perfResult(in Perf perf) =>
	PerfResult(isEnabled(perf) ? perf.cbGetTimeNSec() - perf.nsecStart : 0, perf.measures);

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
