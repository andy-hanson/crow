module util.writer;

@safe @nogc nothrow:

import util.alloc.alloc : Alloc, withStackAlloc, withStackAllocImpure;
import util.alloc.stackAlloc : StackArrayBuilder, withBuildStackArray;
import util.col.arrayBuilder : Builder, finish;
import util.col.array : castImmutable, reverseInPlace, zip;
import util.conv : bitsOfFloat64, round, safeToUlong;
import util.string : eachChar, CString, stringOfCString;
import util.unicode : isValidUnicodeCharacter, mustUnicodeDecode, mustUnicodeEncode;
import util.util : abs, debugLog, isNan, max, min;

T withStackWriterImpure(T)(
	in void delegate(scope ref Writer) @safe @nogc nothrow cb,
	in T delegate(in string) @safe @nogc nothrow cbRes,
) =>
	withStackAllocImpure!(0x10000, T)((scope ref Alloc alloc) {
		scope Writer writer = Writer(&alloc);
		cb(writer);
		return cbRes(finish(writer.res));
	});

T withStackWriterImpureCString(T)(
	in void delegate(scope ref Writer) @safe @nogc nothrow cb,
	in T delegate(in CString) @safe @nogc nothrow cbRes,
) =>
	withStackAllocImpure!(0x10000, T)((scope ref Alloc alloc) {
		scope Writer writer = Writer(&alloc);
		cb(writer);
		return cbRes(finishCString(writer));
	});

pure:

struct Writer {
	@safe @nogc pure nothrow:

	private:
	Builder!(immutable char) res;

	this(return scope Alloc* allocPtr) {
		res = Builder!(immutable char)(allocPtr);
	}

	void opOpAssign(string op : "~")(bool a) {
		res ~= (a ? "true" : "false");
	}
	void opOpAssign(string op : "~")(char a) {
		res ~= a;
	}
	void opOpAssign(string op : "~")(dchar a) {
		mustUnicodeEncode(res, a);
	}
	void opOpAssign(string op : "~")(in char[] a) {
		res ~= castImmutable(a);
	}
	void opOpAssign(string op : "~")(in CString a) {
		eachChar(a, (char c) {
			this ~= c;
		});
	}
	void opOpAssign(string op : "~")(ubyte a) {
		writeNat(this, a);
	}
	void opOpAssign(string op : "~")(int a) {
		this ~= long(a);
	}
	void opOpAssign(string op : "~")(long a) {
		if (a < 0)
			this ~= '-';
		this ~= abs(a);
	}
	void opOpAssign(string op : "~")(ushort a) {
		writeNat(this, a);
	}
	void opOpAssign(string op : "~")(uint a) {
		writeNat(this, a);
	}
	void opOpAssign(string op : "~")(ulong a) {
		writeNat(this, a);
	}
	void opOpAssign(string op : "~", T)(T a) {
		a.writeTo(this);
	}
}

void debugLogWithWriter(in void delegate(scope ref Writer) @safe @nogc pure nothrow cb) {
	debugLogWithWriter((scope ref Alloc, scope ref Writer writer) {
		cb(writer);
	});
}
void debugLogWithWriter(in void delegate(scope ref Alloc, scope ref Writer) @safe @nogc pure nothrow cb) {
	debug {
		withStackWriter!0x10000((scope ref Alloc alloc, scope ref Writer writer) {
			cb(alloc, writer);
			writer ~= '\0';
		}, (in string x) => debugLog(x.ptr));
	}
}
T withStackWriter(size_t nBytes, T)(
	in void delegate(scope ref Writer) @safe @nogc pure nothrow cb,
	in T delegate(in string) @safe @nogc pure nothrow cbRes,
) =>
	withStackWriter!(nBytes, T)(
		(scope ref Alloc _, scope ref Writer writer) { cb(writer); },
		cbRes);
T withStackWriter(size_t nBytes, T)(
	in void delegate(scope ref Alloc, scope ref Writer) @safe @nogc pure nothrow cb,
	in T delegate(in string) @safe @nogc pure nothrow cbRes,
) =>
	withStackAlloc!nBytes((scope ref Alloc alloc) =>
		cbRes(makeStringWithWriter(alloc, (scope ref Writer writer) {
			cb(alloc, writer);
		})));
T withStackWriterCString(size_t nBytes = 0x10000, T)(
	in void delegate(scope ref Writer) @safe @nogc pure nothrow cb,
	in T delegate(in CString) @safe @nogc pure nothrow cbRes,
) =>
	withStackAlloc!nBytes((scope ref Alloc alloc) =>
		cbRes(withWriter(alloc, (scope ref Writer writer) {
			cb(writer);
		})));

CString withWriter(ref Alloc alloc, in void delegate(scope ref Writer writer) @safe @nogc pure nothrow cb) {
	scope Writer writer = Writer(&alloc);
	cb(writer);
	return finishCString(writer);
}

private @trusted CString finishCString(scope ref Writer writer) {
	writer ~= '\0';
	return CString(finish(writer.res).ptr);
}

string makeStringWithWriter(ref Alloc alloc, in void delegate(scope ref Writer writer) @safe @nogc pure nothrow cb) {
	scope Writer writer = Writer(&alloc);
	cb(writer);
	return finish(writer.res);
}

void writeHex(scope ref Writer writer, ulong a, uint minDigits = 1) {
	writeNat(writer, a, 16, minDigits);
}

void writeHex(scope ref Writer writer, long a) {
	if (a < 0)
		writer ~= '-';
	writeHex(writer, cast(ulong) (a < 0 ? -a : a));
}

void writeFloatLiteral(scope ref Writer writer, double a, in string infinity, in string nan) { // TODO: UNIT TEST! ------------------------------------------------------------------------------
	if (a < 0) {
		writer ~= '-';
		writeFloatLiteral(writer, -a, infinity, nan);
	} else if (isNan(a))
		writer ~= nan;
	else if (a == double.infinity)
		writer ~= infinity;
	else if ((cast(double) (cast(long) a)) == a) {
		// Being careful to handle -0
		if (1.0 / a < 0)
			writer ~= '-';
		writer ~= abs(cast(long) a);
	} else {
		DecimalAndExponent de = toDecimalAndExponent(a);
		ulong dec = de.decimal;
		long exp = de.exponent;
		withBuildStackArray!(void, char)(
			(ref StackArrayBuilder!char out_) {
				while (dec != 0) {
					ulong digit = dec % 10;
					out_ ~= digitChar(digit);
					dec /= 10;
					exp++;
				}
				if (exp <= 0) {
					foreach (ulong i; 0 .. abs(exp))
						out_ ~= '0';
					out_ ~= '.';
					out_ ~= '0';
				}
				reverseInPlace(out_.asTemporaryArray);
				if (exp <= 0) {
					// did before reverse
				} else if (safeToUlong(exp) < out_.sizeSoFar)
					out_.insertAt(safeToUlong(exp), '.');
				else {
					foreach (size_t _; out_.sizeSoFar .. safeToUlong(exp))
						out_ ~= '0';
				}
			},
			(scope char[] xs) {
				writer ~= xs;
			});
	}
}

immutable struct DecimalAndExponent { ulong decimal; long exponent; }
DecimalAndExponent toDecimalAndExponent(double a) {
	assert(a > 0);
	double x = a;
	long exp = 0;
	while (x < 1) {
		x *= 10;
		exp--;
	}

	ulong digits = 0;
	while (!isNearInt(x) && digits < 15) {
		x *= 10;
		exp--;
		digits++;
	}

	ulong dec = safeToUlong(cast(long) round(x));
	while (dec % 10 == 0) {
		dec /= 10;
		exp++;
	}
	return DecimalAndExponent(dec, exp);
}

bool isNearInt(double a) {
	double b = round(a);
	double diff = abs(a - b);
	double epsilon = 2.22e-16;
	return a == b || diff <= epsilon || diff <= epsilon * min(abs(a), abs(b));
}

void writeFloatLiteralForC(scope ref Writer writer, double a) { // TODO: this should only be used from writeToC! JSON can't use it, JS can't use it
	if (isNan(a))
		writer ~= "NAN";
	else if (a == double.infinity)
		writer ~= "INFINITY";
	else if (a == -double.infinity)
		writer ~= "-INFINITY";
	// Print simple floats as decimal
	else if ((cast(double) (cast(long) a)) == a) {
		// Being careful to handle -0
		if (1.0 / a < 0)
			writer ~= '-';
		writer ~= abs(cast(long) a);
	} else if ((cast(double) (cast(long) (a * 10.0))) == a * 10.0) {
		writer ~= cast(long) a;
		writer ~= '.';
		writer ~= (cast(long) (abs(a) * 10)) % 10;
	} else {
		ulong u = bitsOfFloat64(a);
		bool isNegative = u >> (64 - 1);
		ulong exponentPlus1023 = (u >> (64 - 1 - 11)) & ((1 << 11) - 1);
		ulong fraction = u & ((1uL << 52) - 1);
		long exponent = (cast(long) exponentPlus1023) - 1023;
		if (isNegative)
			writer ~= '-';
		writer ~= "0x1.";
		writeHex(writer, fraction, minDigits: 52 / 4);
		writer ~= 'p';
		writer ~= exponent;
	}
}

private void writeNat(scope ref Writer writer, ulong n, ulong base = 10, uint minDigits = 1) {
	assert(minDigits != 0);
	if (n >= base || minDigits > 1)
		writeNat(writer, n / base, base, max(minDigits - 1, 1));
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
	writeWithSeparatorAndFilter!T(writer, a, ", ", filter, cb);
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

void writeWithSpaces(T)(scope ref Writer writer, in T[] a, in void delegate(in T) @safe @nogc pure nothrow cb) {
	writeWithSeparator!T(writer, a, " ", cb);
}

void writeWithNewlines(T)(scope ref Writer writer, in T[] a, in void delegate(in T) @safe @nogc pure nothrow cb) {
	writeWithSeparator!T(writer, a, "\n", cb);
}

void writeWithCommasAndNewlines(T)(scope ref Writer writer, uint indent, in T[] a, in void delegate(in T) @safe @nogc pure nothrow cb) {
	bool first = true;
	foreach (ref T x; a) {
		if (first)
			first = false;
		else {
			writer ~= ',';
			writeNewline(writer, indent);
		}
		cb(x);
	}
}

void writeWithSeparator(T)(
	scope ref Writer writer,
	in T[] a,
	in string separator,
	in void delegate(in T) @safe @nogc pure nothrow cb,
) {
	writeWithSeparatorAndFilter!T(writer, a, separator, (in T _) => true, cb);
}

void writeWithSeparatorAndFilter(T)(
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
	mustUnicodeDecode(s, (dchar x) {
		writeEscapedChar_inner(writer, x);
	});
	writer ~= '"';
}
void writeQuotedString(scope ref Writer writer, in CString s) {
	writeQuotedString(writer, stringOfCString(s));
}

void writeQuotedChar(scope ref Writer writer, dchar c) {
	writer ~= '"';
	writeEscapedChar_inner(writer, c);
	writer ~= '"';
}

void writeEscapedChar(scope ref Writer writer, dchar c) {
	if (c == '\'')
		writer ~= "\\\'";
	else
		writeEscapedChar_inner(writer, c);
}

void writeEscapedChar_inner(scope ref Writer writer, dchar c, bool forC = false) {
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
			writer ~= "\\x1b";
			if (forC)
				// Need two adjacent concatenated strings in case the next character is a valid hex digit
				writer ~= "\"\"";
			break;
		default:
			writer ~= isValidUnicodeCharacter(c) ? c : '�';
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

void writeNewline(scope ref Writer writer, size_t indent) {
	writer ~= '\n';
	foreach (size_t _; 0 .. indent)
		writer ~= '\t';
}
