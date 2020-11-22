module util.writer;

@safe @nogc pure nothrow:

import util.bools : Bool, False;
import util.ptr : Ptr;
import util.collection.arr : Arr, at, range, size;
import util.collection.arrBuilder : add, ArrBuilder, finishArr;
import util.collection.str : Str, strLiteral;
import util.ptr : PtrRange;
import util.types : abs;
import util.util : verify;

struct Writer(Alloc) {
	private:
	//TODO:PRIVATE
	public Ptr!Alloc alloc;
	ArrBuilder!char res;
}

immutable(Str) finishWriter(Alloc)(ref Writer!Alloc writer) {
	return finishArr(writer.alloc.deref, writer.res);
}

void writeChar(Alloc)(ref Writer!Alloc writer, immutable char c) {
	add(writer.alloc, writer.res, c);
}

void writeStr(Alloc)(ref Writer!Alloc writer, immutable Str s) {
	foreach (immutable char c; range(s))
		writeChar(writer, c);
}

void writeStatic(Alloc)(ref Writer!Alloc writer, immutable string c) {
	writeStr(writer, strLiteral(c));
}

void writeHex(Alloc)(ref Writer!Alloc writer, immutable ulong n) {
	writeNat(writer, n, 16);
}

void writePtrRange(Alloc)(ref Writer!Alloc writer, const PtrRange a) {
	writeHex(writer, cast(immutable size_t) a.begin);
	writeChar(writer, '-');
	writeHex(writer, cast(immutable size_t) a.end);
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

void writeInt(Alloc)(ref Writer!Alloc writer, immutable long i, immutable ulong base) {
	if (i < 0)
		writeChar(writer, '-');
	writeNat(writer, abs(i), base);
}

void writeWithCommas(Alloc, T)(
	ref Writer!Alloc writer,
	immutable Arr!T a,
	scope void delegate(ref immutable T) @safe @nogc pure nothrow cb,
) {
	writeWithCommas(writer, a, False, cb);
}

void writeWithCommas(Alloc, T)(
	ref Writer!Alloc writer,
	immutable Arr!T a,
	immutable Bool leadingComma,
	scope void delegate(ref immutable T) @safe @nogc pure nothrow cb,
) {
	foreach (immutable size_t i; 0..size(a)) {
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
	foreach (immutable size_t i; 0..n) {
		if (i != 0)
			writeStatic(writer, ", ");
		cb(i);
	}
}

void writeWithNewlines(Alloc, T)(
	ref Writer!Alloc writer,
	ref immutable Arr!T a,
	scope void delegate(ref immutable T) @safe @nogc pure nothrow cb,
) {
	foreach (immutable size_t i; 0..size(a)) {
		if (i != 0)
			writeStatic(writer, "\n");
		cb(at(a, i));
	}
}

void writeQuotedStr(Alloc)(ref Writer!Alloc writer, ref immutable Str s) {
	writeChar(writer, '"');
	foreach (immutable char c; range(s))
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
			writeStatic(writer, "\\x1b");
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

void writeHyperlink(Alloc)(ref Writer!Alloc writer, immutable Str url, immutable Str text) {
	// documentation: https://gist.github.com/egmontkob/eb114294efbcd5adb1944c9f3cb5feda
	// https://purpleidea.com/blog/2018/06/29/hyperlinks-in-gnome-terminal/
	// TODO: I haven't got this to work on any terminal emulator I have installed. :(
	if (false) {
		writeStatic(writer, "\x1b]8;;");
		writeStr(writer, url);
		writeStatic(writer, "\x1b\\");
		writeStr(writer, text);
		writeStatic(writer, "\x1b]8;;\x1b\\");
	} else {
		writeStr(writer, text);
	}
}

void newline(Alloc)(ref Writer!Alloc writer, immutable size_t indent) {
	writeChar(writer, '\n');
	foreach (immutable size_t _; 0..indent)
		writeChar(writer, '\t');
}
