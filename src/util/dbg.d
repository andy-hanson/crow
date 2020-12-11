module util.dbg;

@safe @nogc nothrow: // not pure

import util.collection.str : Str, strLiteral;

void log(Debug)(ref Debug dbg, immutable string a) {
	log(dbg, strLiteral(a));
}

void log(Debug)(ref Debug dbg, immutable Str a) {
	dbg.write(a);
	dbg.writeChar('\n');
}

void logNoNewline(Debug)(ref Debug dbg, immutable string a) {
	logNoNewline(dbg, strLiteral(a));
}

void logNoNewline(Debug)(ref Debug dbg, immutable Str a) {
	dbg.write(a);
}

void logNat(Debug)(ref Debug dbg, immutable size_t n) {
	if (n > 10)
		logNat(dbg, n / 10);
	dbg.writeChar('0' + (n % 10));
}
