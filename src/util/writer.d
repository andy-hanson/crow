module util.writer;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc, withStackAlloc;
import util.col.arrayBuilder : add, ArrayBuilder, finish;
import util.col.array : zip;
import util.string : eachChar, CString;
import util.util : abs, debugLog;

struct Writer {
	private:
	Alloc* alloc;
	ArrayBuilder!char res;

	void opOpAssign(string op, T)(in T a) scope if (op == "~") {
		static if (is(T == char))
			add(*alloc, res, a);
		else static if (is(T == string)) {
			foreach (char c; a)
				this ~= c;
		} else static if (is(immutable T == CString))
			eachChar(a, (char c) {
				this ~= c;
			});
		else static if (is(T == bool))
			this ~= (a ? "true" : "false");
		else static if (is(T == int) || is(T == long)) {
			if (a < 0)
				this ~= '-';
			this ~= abs(a);
		} else static if (is(T == ushort) || is(T == uint) || is(T == ulong))
			writeNat(this, a);
		else
			static assert(false, "not writeable");
	}
}

void debugLogWithWriter(in void delegate(scope ref Writer) @safe @nogc pure nothrow cb) {
	debugLogWithWriter((scope ref Alloc, scope ref Writer writer) {
		cb(writer);
	});
}
void debugLogWithWriter(in void delegate(scope ref Alloc, scope ref Writer) @safe @nogc pure nothrow cb) {
	debug {
		debugLog(withStackWriter(cb).ptr);
	}
}
// Result is temporary
CString withStackWriter(in void delegate(scope ref Alloc, scope ref Writer) @safe @nogc pure nothrow cb) =>
	withStackAlloc!0x1000((scope ref Alloc alloc) =>
		withWriter(alloc, (scope ref Writer writer) {
			cb(alloc, writer);
		}));

@trusted CString withWriter(ref Alloc alloc, in void delegate(scope ref Writer writer) @safe @nogc pure nothrow cb) {
	scope Writer writer = Writer(&alloc);
	cb(writer);
	writer ~= '\0';
	return CString(finish(*writer.alloc, writer.res).ptr);
}

string makeStringWithWriter(ref Alloc alloc, in void delegate(scope ref Writer writer) @safe @nogc pure nothrow cb) {
	scope Writer writer = Writer(&alloc);
	cb(writer);
	return finish(*writer.alloc, writer.res);
}

void writeHex(scope ref Writer writer, ulong a) {
	writeNat(writer, a, 16);
}

void writeHex(scope ref Writer writer, long a) {
	if (a < 0)
		writer ~= '-';
	writeHex(writer, cast(ulong) (a < 0 ? -a : a));
}

void writeFloatLiteral(scope ref Writer writer, double a) {
	// TODO: assert(!isNaN(a)); (needs an isnan function)

	// Print simple floats as decimal
	if ((cast(double) (cast(long) a)) == a) {
		// Being careful to handle -0
		if (1.0 / a < 0)
			writer ~= '-';
		writer ~= abs(cast(long) a);
	} else if ((cast(double) (cast(long) (a * 10.0))) == a * 10.0) {
		writer ~= cast(long) a;
		writer ~= '.';
		writer ~= (cast(long) (abs(a) * 10)) % 10;
	} else {
		DoubleToUlong conv;
		conv.double_ = a;
		ulong u = conv.ulong_;
		bool isNegative = u >> (64 - 1);
		ulong exponentPlus1023 = (u >> (64 - 1 - 11)) & ((1 << 11) - 1);
		ulong fraction = u & ((1uL << 52) - 1);
		long exponent = (cast(long) exponentPlus1023) - 1023;
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

private void writeNat(scope ref Writer writer, ulong n, ulong base = 10) {
	if (n >= base)
		writeNat(writer, n / base, base);
	writer ~= digitChar(n % base);
}

char digitChar(ulong digit) {
	assert(digit < 16);
	return digit < 10 ? cast(char) ('0' + digit) : cast(char) ('a' + (digit - 10));
}

void writeWithCommas(T)(scope ref Writer writer, in T[] a, in void delegate(in T) @safe @nogc pure nothrow cb) {
	writeWithSeparator!T(writer, a, ", ", cb);
}

void writeWithCommasCompact(T)(scope ref Writer writer, in T[] a, in void delegate(in T) @safe @nogc pure nothrow cb) {
	writeWithSeparator!T(writer, a, ",", cb);
}

void writeWithCommas(T)(
	scope ref Writer writer,
	in T[] a,
	in bool delegate(in T) @safe @nogc pure nothrow filter,
	in void delegate(in T) @safe @nogc pure nothrow cb,
) {
	writeWithSeparator!T(writer, a, ", ", filter, cb);
}

void writeWithCommasZip(T, U)(
	scope ref Writer writer,
	in T[] a,
	in U[] b,
	in void delegate(in T, in U) @safe @nogc pure nothrow cb,
) {
	writeWithCommasZip!(T, U)(writer, a, b, (in T x, in U y) => true, cb);
}

void writeWithCommasZip(T, U)(
	scope ref Writer writer,
	in T[] a,
	in U[] b,
	in bool delegate(in T, in U) @safe @nogc pure nothrow filter,
	in void delegate(in T, in U) @safe @nogc pure nothrow cb,
) {
	bool needsComma = false;
	zip!(const T, const U)(a, b, (ref const T x, ref const U y) {
		if (filter(x, y)) {
			if (needsComma)
				writer ~= ", ";
			else
				needsComma = true;
			cb(x, y);
		}
	});
}

void writeWithNewlines(T)(scope ref Writer writer, in T[] a, in void delegate(in T) @safe @nogc pure nothrow cb) {
	writeWithSeparator!T(writer, a, "\n", cb);
}

void writeWithSeparator(T)(
	scope ref Writer writer,
	in T[] a,
	in string separator,
	in void delegate(in T) @safe @nogc pure nothrow cb,
) {
	writeWithSeparator!T(writer, a, separator, (in T _) => true, cb);
}

private void writeWithSeparator(T)(
	scope ref Writer writer,
	in T[] a,
	in string separator,
	in bool delegate(in T) @safe @nogc pure nothrow filter,
	in void delegate(in T) @safe @nogc pure nothrow cb,
) {
	bool first = true;
	foreach (size_t i, ref const T x; a)
		if (filter(x)) {
			if (first)
				first = false;
			else
				writer ~= separator;
			cb(x);
		}
}

void writeQuotedString(scope ref Writer writer, in string s) {
	writer ~= '"';
	foreach (char c; s)
		writeEscapedChar_inner(writer, c);
	writer ~= '"';
}

void writeEscapedChar(scope ref Writer writer, char c) {
	if (c == '\'')
		writer ~= "\\\'";
	else
		writeEscapedChar_inner(writer, c);
}

void writeEscapedChar_inner(scope ref Writer writer, char c) {
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

void writeBold(scope ref Writer writer) {
	version (Windows) { } else {
		writer ~= "\x1b[1m";
	}
}

void writeRed(scope ref Writer writer) {
	version (Windows) { } else {
		writer ~= "\x1b[31m";
	}
}

// Undo bold, color, etc
void writeReset(scope ref Writer writer) {
	version (Windows) { } else {
		writer ~= "\x1b[m";
	}
}

void writeHyperlink(
	scope ref Writer writer,
	in void delegate() @safe @nogc pure nothrow writeUrl,
	in void delegate() @safe @nogc pure nothrow writeText,
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

private bool canWriteHyperlink() {
	version (Windows) {
		return false;
	} else {
		// TODO: I haven't got this to work on any terminal emulator I have installed. :(
		return false;
	}
}

void writeSpaces(scope ref Writer writer, size_t nSpaces) {
	foreach (size_t i; 0 .. nSpaces)
		writer ~= ' ';
}

void writeNewline(scope ref Writer writer, size_t indent) {
	writer ~= '\n';
	foreach (size_t _; 0 .. indent)
		writer ~= '\t';
}
