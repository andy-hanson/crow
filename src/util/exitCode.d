module util.exitCode;

@safe @nogc nothrow: // not pure

immutable struct ExitCode {
	@safe @nogc pure nothrow:
	int value;

	uint asUintForTaggedUnion() =>
		cast(uint) value;
	static ExitCode fromUintForTaggedUnion(uint a) =>
		ExitCode(cast(int) a);

	static ExitCode ok() =>
		ExitCode(0);
	static ExitCode error() =>
		ExitCode(1);
}

pure ExitCode exitCodeCombine(ExitCode a, ExitCode b) =>
	a == ExitCode.ok ? b : a;

ExitCode okAnd(ExitCode a, in ExitCode delegate() @safe @nogc nothrow cb) =>
	a == ExitCode.ok ? cb() : a;

ExitCode onError(ExitCode a, in ExitCode delegate() @safe @nogc nothrow cb) =>
	a == ExitCode.ok ? a : cb();
