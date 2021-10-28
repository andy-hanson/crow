module util.dbg;

@safe @nogc pure nothrow:

struct Debug {
	@safe @nogc pure nothrow:

	private void delegate(immutable char) @safe @nogc nothrow cbWriteChar;
	private void delegate(scope immutable string) @safe @nogc nothrow cbWriteString;

	bool enabled() scope const {
		return debugEnabled;
	}

	void writeChar(immutable char a) scope {
		if (enabled)
			cbWriteChar(a);
	}

	void write(scope immutable string a) scope {
		if (enabled)
			cbWriteString(a);
	}
}

private immutable bool debugEnabled = false;

void log(scope ref Debug dbg, immutable string a) {
	dbg.write(a);
	dbg.writeChar('\n');
}

void logNoNewline(scope ref Debug dbg, immutable string a) {
	dbg.write(a);
}

void logNat(scope ref Debug dbg, immutable size_t a) {
	if (a > 10)
		logNat(dbg, a / 10);
	dbg.writeChar('0' + (a % 10));
}
