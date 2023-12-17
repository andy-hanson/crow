module util.exitCode;

@safe @nogc nothrow: // not pure

immutable struct ExitCode {
	@safe @nogc pure nothrow:
	int value;

	static ExitCode ok() =>
		ExitCode(0);
	static ExitCode error() =>
		ExitCode(1);
}

ExitCode okAnd(ExitCode a, in ExitCode delegate() @safe @nogc nothrow cb) =>
	a == ExitCode.ok ? cb() : a;
