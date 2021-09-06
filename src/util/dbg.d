module util.dbg;

@safe @nogc pure nothrow:

void log(Debug)(ref Debug dbg, immutable string a) {
	dbg.write(a);
	dbg.writeChar('\n');
}

void logNoNewline(Debug)(ref Debug dbg, immutable string a) {
	dbg.write(a);
}

void logNat(Debug)(ref Debug dbg, immutable size_t a) {
	if (a > 10)
		logNat(dbg, a / 10);
	dbg.writeChar('0' + (a % 10));
}
