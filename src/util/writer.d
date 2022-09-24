module util.writer;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc;
import util.col.arrBuilder : add, ArrBuilder, finishArr;
import util.col.arrUtil : zip;
import util.col.str : CStr, eachChar, SafeCStr;
import util.util : abs, verify;

struct Writer {
	private:
	//TODO:PRIVATE
	public Alloc* alloc;
	ArrBuilder!char res;

	void opOpAssign(string op, T)(scope immutable T a) scope if (op == "~") {
		static if (is(T == char))
			add(*alloc, res, a);
		else static if (is(T == string)) {
			foreach (immutable char c; a)
				this ~= c;
		} else static if (is(T == SafeCStr))
			eachChar(a, (immutable char c) {
				this ~= c;
			});
		else static if (is(T == int) || is(T == long)) {
			if (a < 0)
				this ~= '-';
			this ~= abs(a);
		} else static if (is(T == uint) || is(T == ulong))
			writeNat(this, a);
		else
			static assert(false, "not writeable");
	}
}

immutable(string) finishWriter(scope ref Writer writer) =>
	finishArr(*writer.alloc, writer.res);

@trusted immutable(CStr) finishWriterToCStr(ref Writer writer) {
	writer ~= '\0';
	return finishWriter(writer).ptr;
}

@trusted immutable(SafeCStr) finishWriterToSafeCStr(scope ref Writer writer) =>
	immutable SafeCStr(finishWriterToCStr(writer));

void writeHex(ref Writer writer, immutable ulong a) {
	writeNat(writer, a, 16);
}

void writeHex(scope ref Writer writer, immutable long a) {
	if (a < 0)
		writer ~= '-';
	writeHex(writer, cast(immutable ulong) (a < 0 ? -a : a));
}

void writeFloatLiteral(ref Writer writer, immutable double a) {
	// TODO: verify(!isNaN(a)); (needs an isnan function)

	// Print simple floats as decimal
	if ((cast(double) (cast(long) a)) == a) {
		// Being careful to handle -0
		if (1.0 / a < 0)
			writer ~= '-';
		writer ~= abs(cast(long) a);
		writer ~= ".0";
	} else if ((cast(double) (cast(long) (a * 10.0))) == a * 10.0) {
		writer ~= cast(long) a;
		writer ~= '.';
		writer ~= (cast(long) (abs(a) * 10)) % 10;
	} else {
		DoubleToUlong conv;
		conv.double_ = a;
		immutable ulong u = conv.ulong_;
		immutable bool isNegative = u >> (64 - 1);
		immutable ulong exponentPlus1023 = (u >> (64 - 1 - 11)) & ((1 << 11) - 1);
		immutable ulong fraction = u & ((1uL << 52) - 1);
		immutable long exponent = (cast(long) exponentPlus1023) - 1023;
		if (isNegative)
			writer ~= '-';
		writer ~= "0x1.";
		writeHex(writer, fraction);
		writer ~= 'p';
		writer ~= exponent;
	}
}

private union DoubleToUlong {
	double double_;
	ulong ulong_;
}

private void writeNat(ref Writer writer, immutable ulong n, immutable ulong base = 10) {
	if (n >= base)
		writeNat(writer, n / base, base);
	writer ~= digitChar(n % base);
}

private immutable(char) digitChar(immutable ulong digit) {
	verify(digit < 16);
	return digit < 10 ? cast(char) ('0' + digit) : cast(char) ('a' + (digit - 10));
}

void writeJoin(T)(
	ref Writer writer,
	immutable T[] a,
	immutable string joiner,
	scope void delegate(ref immutable T) @safe @nogc pure nothrow cb,
) {
	foreach (immutable size_t i, ref immutable T x; a) {
		if (i != 0)
			writer ~= joiner;
		cb(x);
	}
}

void writeWithCommas(T)(
	ref Writer writer,
	scope immutable T[] a,
	scope void delegate(scope ref immutable T) @safe @nogc pure nothrow cb,
) {
	writeWithCommas!T(writer, a, (ref immutable T) => true, cb);
}

void writeWithCommas(T)(
	ref Writer writer,
	scope immutable T[] a,
	scope immutable(bool) delegate(scope ref immutable T) @safe @nogc pure nothrow filter,
	scope void delegate(scope ref immutable T) @safe @nogc pure nothrow cb,
) {
	bool needsComma = false;
	foreach (ref immutable T x; a) {
		if (filter(x)) {
			if (needsComma)
				writer ~= ", ";
			else
				needsComma = true;
			cb(x);
		}
	}
}

void writeWithCommasZip(T, U)(
	ref Writer writer,
	scope immutable T[] a,
	scope immutable U[] b,
	scope immutable(bool) delegate(scope ref immutable T, scope ref immutable U) @safe @nogc pure nothrow filter,
	scope void delegate(scope ref immutable T, scope ref immutable U) @safe @nogc pure nothrow cb,
) {
	bool needsComma = false;
	zip!(T, U)(a, b, (ref immutable T x, ref immutable U y) {
		if (filter(x, y)) {
			if (needsComma)
				writer ~= ", ";
			else
				needsComma = true;
			cb(x, y);
		}
	});
}

void writeWithNewlines(T)(
	ref Writer writer,
	ref immutable T[] a,
	scope void delegate(ref immutable T) @safe @nogc pure nothrow cb,
) {
	foreach (immutable size_t i, ref immutable T x; a) {
		if (i != 0)
			writer ~= "\n";
		cb(x);
	}
}

void writeQuotedStr(ref Writer writer, ref immutable string s) {
	writer ~= '"';
	foreach (immutable char c; s)
		writeEscapedChar_inner(writer, c);
	writer ~= '"';
}

void writeEscapedChar(ref Writer writer, immutable char c) {
	if (c == '\'')
		writer ~= "\\\'";
	else
		writeEscapedChar_inner(writer, c);
}

void writeEscapedChar_inner(ref Writer writer, immutable char c) {
	switch (c) {
		case '\n':
			writer ~= "\\n";
			break;
		case '\r':
			writer ~= "\\r";
			break;
		case '\t':
			writer ~= "\\t";
			break;
		case '"':
			writer ~= "\\\"";
			break;
		case '\\':
			writer ~= "\\\\";
			break;
		case '\0':
			writer ~= "\\0";
			break;
		// TODO: handle other special characters like this one
		case '\x1b':
			// NOTE: need two adjacent concatenated strings
			// in case the next character is a valid hex digit
			writer ~= "\\x1b\"\"";
			break;
		default:
			writer ~= c;
			break;
	}
}

void writeBold(ref Writer writer) {
	version (Windows) { } else {
		writer ~= "\x1b[1m";
	}
}

void writeRed(ref Writer writer) {
	version (Windows) { } else {
		writer ~= "\x1b[31m";
	}
}

// Undo bold, color, etc
void writeReset(ref Writer writer) {
	version (Windows) { } else {
		writer ~= "\x1b[m";
	}
}

void writeHyperlink(
	ref Writer writer,
	scope void delegate() @safe @nogc pure nothrow writeUrl,
	scope void delegate() @safe @nogc pure nothrow writeText,
) {
	// documentation: https://gist.github.com/egmontkob/eb114294efbcd5adb1944c9f3cb5feda
	// https://purpleidea.com/blog/2018/06/29/hyperlinks-in-gnome-terminal/
	if (canWriteHyperlink()) {
		writer ~= "\x1b]8;;";
		writeUrl();
		writer ~= "\x1b\\";
		writeText();
		writer ~= "\x1b]8;;\x1b\\";
	} else {
		writeText();
	}
}

private immutable(bool) canWriteHyperlink() {
	version (Windows) {
		return false;
	} else {
		// TODO: I haven't got this to work on any terminal emulator I have installed. :(
		return false;
	}
}

void writeNewline(ref Writer writer, immutable size_t indent) {
	writer ~= '\n';
	foreach (immutable size_t _; 0 .. indent)
		writer ~= '\t';
}
