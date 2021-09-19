module util.writer;

@safe @nogc pure nothrow:

import util.ptr : Ptr;
import util.collection.arr : at, size;
import util.collection.arrBuilder : add, ArrBuilder, finishArr;
import util.collection.str : CStr, cStrOfNulTerminatedStr, NulTerminatedStr;
import util.ptr : PtrRange;
import util.types : abs, IntN, NatN;
import util.util : verify;

struct Writer(Alloc) {
	private:
	//TODO:PRIVATE
	public Ptr!Alloc alloc;
	ArrBuilder!char res;
}

immutable(string) finishWriter(Alloc)(ref Writer!Alloc writer) {
	return finishArr(writer.alloc.deref, writer.res);
}

immutable(CStr) finishWriterToCStr(Alloc)(ref Writer!Alloc writer) {
	writeChar(writer, '\0');
	return cStrOfNulTerminatedStr(immutable NulTerminatedStr(finishWriter(writer)));
}

void writeChar(Alloc)(ref Writer!Alloc writer, immutable char c) {
	add(writer.alloc.deref(), writer.res, c);
}

void writeStr(Alloc)(ref Writer!Alloc writer, immutable string s) {
	foreach (immutable char c; s)
		writeChar(writer, c);
}

void writeStatic(Alloc)(ref Writer!Alloc writer, immutable string c) {
	writeStr(writer, c);
}

void writeHex(Alloc)(ref Writer!Alloc writer, immutable ulong a) {
	writeNat(writer, a, 16);
}

void writeHex(Alloc)(ref Writer!Alloc writer, immutable long a) {
	if (a < 0)
		writeChar(writer, '-');
	writeHex(writer, cast(immutable ulong) (a < 0 ? -a : a));
}

void writeFloatLiteral(Alloc)(ref Writer!Alloc writer, immutable double a) {
	// TODO: verify(!isNaN(a)); (needs an isnan function)

	// Print simple floats as decimal
	if ((cast(double) (cast(long) a)) == a) {
		// Being careful to handle -0
		if (1.0 / a < 0)
			writeChar(writer, '-');
		writeNat(writer, abs(cast(long) a));
		writeStatic(writer, ".0");
	} else if ((cast(double) (cast(long) (a * 10.0))) == a * 10.0) {
		writeInt(writer, cast(long) a);
		writeChar(writer, '.');
		writeNat(writer, (cast(long) (abs(a) * 10)) % 10);
	} else {
		DoubleToUlong conv;
		conv.double_ = a;
		immutable ulong u = conv.ulong_;
		immutable bool isNegative = u >> (64 - 1);
		immutable ulong exponentPlus1023 = (u >> (64 - 1 - 11)) & ((1 << 11) - 1);
		immutable ulong fraction = u & ((1uL << 52) - 1);
		immutable long exponent = (cast(long) exponentPlus1023) - 1023;
		if (isNegative) writeChar(writer, '-');
		writeStatic(writer, "0x1.");
		writeHex(writer, fraction);
		writeChar(writer, 'p');
		writeHex(writer, exponent);
	}
}

private union DoubleToUlong {
	double double_;
	ulong ulong_;
}

void writePtrRange(Alloc)(ref Writer!Alloc writer, const PtrRange a) {
	writeHex(writer, cast(immutable ulong) a.begin);
	writeChar(writer, '-');
	writeHex(writer, cast(immutable ulong) a.end);
}

void writeNat(Alloc, T)(ref Writer!Alloc writer, immutable NatN!T n, immutable ulong base = 10) {
	writeNat(writer, n.raw(), base);
}

void writeNat(Alloc)(ref Writer!Alloc writer, immutable ulong n, immutable ulong base = 10) {
	if (n >= base)
		writeNat(writer, n / base, base);
	writeChar(writer, digitChar(n % base));
}

private immutable(char) digitChar(immutable ulong digit) {
	verify(digit < 16);
	return digit < 10 ? cast(char) ('0' + digit) : cast(char) ('a' + (digit - 10));
}

void writeInt(Alloc, T)(ref Writer!Alloc writer, immutable IntN!T a, immutable ulong base = 10) {
	writeInt(writer, a.raw(), base);
}

void writeInt(Alloc)(ref Writer!Alloc writer, immutable long i, immutable ulong base = 10) {
	if (i < 0)
		writeChar(writer, '-');
	writeNat(writer, abs(i), base);
}

void writeWithCommas(T, Alloc)(
	ref Writer!Alloc writer,
	immutable T[] a,
	scope void delegate(ref immutable T) @safe @nogc pure nothrow cb,
) {
	writeWithCommas!(T, Alloc)(writer, a, false, cb);
}

void writeWithCommas(T, Alloc)(
	ref Writer!Alloc writer,
	immutable T[] a,
	immutable bool leadingComma,
	scope void delegate(ref immutable T) @safe @nogc pure nothrow cb,
) {
	foreach (immutable size_t i; 0 .. size(a)) {
		if (leadingComma || i != 0)
			writeStatic(writer, ", ");
		cb(at(a, i));
	}
}

void writeWithCommas(Alloc)(
	ref Writer!Alloc writer,
	immutable size_t n,
	scope void delegate(immutable size_t) @safe @nogc pure nothrow cb,
) {
	foreach (immutable size_t i; 0 .. n) {
		if (i != 0)
			writeStatic(writer, ", ");
		cb(i);
	}
}

void writeWithNewlines(T, Alloc)(
	ref Writer!Alloc writer,
	ref immutable T[] a,
	scope void delegate(ref immutable T) @safe @nogc pure nothrow cb,
) {
	foreach (immutable size_t i; 0 .. size(a)) {
		if (i != 0)
			writeStatic(writer, "\n");
		cb(at(a, i));
	}
}

void writeQuotedStr(Alloc)(ref Writer!Alloc writer, ref immutable string s) {
	writeChar(writer, '"');
	foreach (immutable char c; s)
		writeEscapedChar_inner(writer, c);
	writeChar(writer, '"');
}

void writeEscapedChar(Alloc)(ref Writer!Alloc writer, immutable char c) {
	if (c == '\'')
		writeStatic(writer, "\\\'");
	else
		writeEscapedChar_inner(writer, c);
}

void writeEscapedChar_inner(Alloc)(ref Writer!Alloc writer, immutable char c) {
	switch (c) {
		case '\n':
			writeStatic(writer, "\\n");
			break;
		case '\r':
			writeStatic(writer, "\\r");
			break;
		case '\t':
			writeStatic(writer, "\\t");
			break;
		case '"':
			writeStatic(writer, "\\\"");
			break;
		case '\\':
			writeStatic(writer, "\\\\");
			break;
		case '\0':
			writeStatic(writer, "\\0");
			break;
		// TODO: handle other special characters like this one
		case '\x1b':
			// NOTE: need two adjacent concatenated strings
			// in case the next character is a valid hex digit
			writeStatic(writer, "\\x1b\"\"");
			break;
		default:
			writeChar(writer, c);
			break;
	}
}

void writeBold(Alloc)(ref Writer!Alloc writer) {
	writeStatic(writer, "\x1b[1m");
}

void writeRed(Alloc)(ref Writer!Alloc writer) {
	writeStatic(writer, "\x1b[31m");
}

// Undo bold, color, etc
void writeReset(Alloc)(ref Writer!Alloc writer) {
	writeStatic(writer, "\x1b[m");
}

void writeHyperlink(Alloc)(
	ref Writer!Alloc writer,
	scope void delegate() @safe @nogc pure nothrow writeUrl,
	scope void delegate() @safe @nogc pure nothrow writeText,
) {
	// documentation: https://gist.github.com/egmontkob/eb114294efbcd5adb1944c9f3cb5feda
	// https://purpleidea.com/blog/2018/06/29/hyperlinks-in-gnome-terminal/
	// TODO: I haven't got this to work on any terminal emulator I have installed. :(
	if (false) {
		writeStatic(writer, "\x1b]8;;");
		writeUrl();
		writeStatic(writer, "\x1b\\");
		writeText();
		writeStatic(writer, "\x1b]8;;\x1b\\");
	} else {
		writeText();
	}
}

void writeNewline(Alloc)(ref Writer!Alloc writer, immutable size_t indent) {
	writeChar(writer, '\n');
	foreach (immutable size_t _; 0 .. indent)
		writeChar(writer, '\t');
}
