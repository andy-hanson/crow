module util.writer;

@safe @nogc pure nothrow:

import util.bools : Bool, False;
import util.ptr : Ptr;
import util.collection.arr : Arr, at, begin, range, size;
import util.collection.arrBuilder : add, ArrBuilder, finishArr;
import util.collection.str : CStr, Str, strLiteral;
import util.types : u16;

struct Writer(Alloc) {
	private:
	Ptr!Alloc alloc;
	ArrBuilder!char res;
}

immutable(Str) finishWriter(Alloc)(ref Writer!Alloc writer) {
	return finishArr(writer.alloc.deref, writer.res);
}

@trusted immutable(CStr) finishWriterToCStr(Alloc)(ref Writer!Alloc writer) {
	add(writer.alloc, writer.res, '\0');
	return begin(finishArr(writer.alloc, writer.res));
}

//TODO:KILL
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

void writeNat(Alloc)(ref Writer!Alloc writer, immutable size_t n) {
	if (n >= 10)
		writeNat(writer, n / 10);
	writeChar(writer, '0' + n % 10);
}

void writeInt(Alloc)(ref Writer!Alloc writer, immutable ssize_t i) {
	if (i < 0)
		writeChar(writer, '-');
	writeNat(writer, i);
}

void writeBool(Alloc)(ref Writer!Alloc writer, immutable Bool b) {
	writeStatic(writer, b ? "true" : "false");
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
	foreach (immutable size_t i; 0..a.size) {
		if (leadingComma || i != 0)
			writeStatic(writer, ", ");
		cb(a.at(i));
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

private void writeEscapedChar_inner(Alloc)(ref Writer!Alloc writer, immutable char c) {
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
