module util.dbg;

@safe @nogc pure nothrow:

import util.sym : eachCharInSym, Sym;

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
	if (debugEnabled) {
		dbg.write(a);
		dbg.writeChar('\n');
	}
}

void log(scope ref Debug dbg, immutable string a, immutable size_t b) {
	if (debugEnabled) {
		dbg.write(a);
		dbg.writeChar(' ');
		logNat(dbg, b);
		dbg.writeChar('\n');
	}
}

void log(scope ref Debug dbg, immutable string a, immutable size_t b, immutable size_t c) {
	if (debugEnabled) {
		dbg.write(a);
		dbg.writeChar(' ');
		logNat(dbg, b);
		dbg.writeChar(' ');
		logNat(dbg, c);
		dbg.writeChar('\n');
	}
}

void log(scope ref Debug dbg, immutable string a, immutable string b) {
	if (debugEnabled) {
		dbg.write(a);
		dbg.writeChar(' ');
		dbg.write(b);
		dbg.writeChar('\n');
	}
}

void logSymNoNewline(scope ref Debug dbg, immutable Sym a) {
	if (debugEnabled)
		eachCharInSym(a, (immutable char c) {
			dbg.writeChar(c);
		});
}

void logNoNewline(scope ref Debug dbg, immutable string a) {
	if (debugEnabled)
		dbg.write(a);
}

void logNat(scope ref Debug dbg, immutable size_t a) {
	if (debugEnabled) {
		if (a >= 10)
			logNat(dbg, a / 10);
		dbg.writeChar('0' + (a % 10));
	}
}
