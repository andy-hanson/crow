module util.perf;

@safe @nogc nothrow: // not pure

import util.alloc.alloc : Alloc, curBytes;
import util.util : verify;

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

immutable bool perfEnabled = false;

@trusted immutable(T) withMeasure(T)(
	ref Alloc alloc,
	ref Perf perf,
	immutable PerfMeasure measure,
	scope immutable(T) delegate() @safe @nogc nothrow cb,
) {
	PerfMeasurer measurer = startMeasure(alloc, perf, measure);
	immutable T res = cb();
	endMeasure(alloc, perf, measurer);
	return res;
}
@trusted pure immutable(T) withMeasure(T)(
	ref Alloc alloc,
	ref Perf perf,
	immutable PerfMeasure measure,
	scope immutable(T) delegate() @safe @nogc pure nothrow cb,
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

struct PerfMeasurer {
	private:
	immutable PerfMeasure measure;
	size_t bytesBefore;
	ulong nsecBefore;
	bool paused;
}

@trusted pure PerfMeasurer startMeasure(ref Alloc alloc, ref Perf perf, immutable PerfMeasure measure) {
	if (perfEnabled) {
		immutable size_t bytesBefore = curBytes(alloc);
		immutable ulong nsecBefore = perf.cbGetTimeNSec();
		return PerfMeasurer(measure, bytesBefore, nsecBefore, false);
	} else
		return PerfMeasurer(measure, 0, 0, false);
}

@trusted pure void pauseMeasure(ref Alloc alloc, ref Perf perf, ref PerfMeasurer measurer) {
	if (perfEnabled) {
		verify(!measurer.paused);
		addToMeasure(perf, measurer.measure, immutable PerfMeasureResult(
			0,
			curBytes(alloc) - measurer.bytesBefore,
			perf.cbGetTimeNSec() - measurer.nsecBefore));
		measurer.paused = true;
	}
}

@trusted pure void resumeMeasure(ref Alloc alloc, ref Perf perf, ref PerfMeasurer measurer) {
	if (perfEnabled) {
		verify(measurer.paused);
		measurer.bytesBefore = curBytes(alloc);
		measurer.nsecBefore = perf.cbGetTimeNSec();
		measurer.paused = false;
	}
}

@trusted pure void endMeasure(ref Alloc alloc, ref Perf perf, ref PerfMeasurer measurer) {
	if (perfEnabled) {
		verify(!measurer.paused);
		addToMeasure(perf, measurer.measure, immutable PerfMeasureResult(
			1,
			curBytes(alloc) - measurer.bytesBefore,
			perf.cbGetTimeNSec() - measurer.nsecBefore));
	}
}

immutable(T) withNullPerf(T)(scope immutable(T) delegate(scope ref Perf) @safe @nogc pure nothrow cb) {
	scope Perf perf = Perf(() => immutable ulong(0));
	return cb(perf);
}
@system immutable(T) withNullPerfSystem(T)(scope immutable(T) delegate(scope ref Perf) @system @nogc nothrow cb) {
	scope Perf perf = Perf(() => immutable ulong(0));
	return cb(perf);
}

struct PerfMeasureResult {
	uint count;
	size_t bytesAllocated;
	ulong nanoseconds;
}

void eachMeasure(
	scope ref Perf perf,
	scope void delegate(immutable string, immutable PerfMeasureResult) @safe @nogc nothrow cb,
) {
	foreach (immutable uint measure; 0 .. PerfMeasure.max + 1) {
		immutable PerfMeasureResult result = perf.measures[measure];
		if (result.count)
			cb(perfMeasureName(cast(immutable PerfMeasure) measure), result);
	}
}

enum PerfMeasure {
	cCompile,
	checkCall,
	checkCallLastPart,
	checkEverything,
	concretize,
	gccCompile,
	gccCreateProgram,
	gccJit,
	instantiateFun,
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

pure immutable(string) perfMeasureName(immutable PerfMeasure a) {
	final switch (a) {
		case PerfMeasure.cCompile:
			return "cCompile";
		case PerfMeasure.checkCall:
			return "checkCall";
		case PerfMeasure.checkCallLastPart:
			return "checkCallLastPart";
		case PerfMeasure.checkEverything:
			return "checkEverything";
		case PerfMeasure.concretize:
			return "concretize";
		case PerfMeasure.gccCreateProgram:
			return "gccCreateProgram";
		case PerfMeasure.gccCompile:
			return "gccCompile";
		case PerfMeasure.gccJit:
			return "gccJit";
		case PerfMeasure.instantiateFun:
			return "instantiateFun";
		case PerfMeasure.lower:
			return "lower";
		case PerfMeasure.parseEverything:
			return "parseEverything";
		case PerfMeasure.parseFile:
			return "parseFile";
		case PerfMeasure.run:
			return "run";
	}
}

