module util.writer;

@safe @nogc pure nothrow:

import util.ptr : Ptr;
import util.collection.arr : Arr, at, size;
import util.collection.arrBuilder : ArrBuilder, finishArr;
import util.collection.str : Str, strLiteral;

struct Writer(Alloc) {
	private:
	Ptr!Alloc alloc;
	ArrBuilder!char res;
}

Str finish(Alloc)(ref Writer!Alloc writer) {
	return writer.res.finishArr;
}

CStr finishToCStr(Alloc)(ref Writer!Alloc writer) {
	writer.res.push('\0');
	return writer.res.finishArr.begin;
}

//TODO:KILL
void writeChar(Alloc)(ref Writer!Alloc writer, immutable char c) {
	writer.res.push(c);
}
void writeStr(Alloc)(ref Writer!Alloc writer, immutable Str s) {
	foreach (immutable char c; s)
		writeChar(writer, c);
}
void writeStatic(Alloc)(ref Writer!Alloc writer, immutable char* c) {
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

void writeWithCommas(Alloc, T, alias cb)(ref Writer!Alloc writer, immutable Arr!T a) {
	foreach (immutable size_t i; 0..a.size) {
		if (i != 0)
			writeStatic(writer, ", ");
		cb(a.at(i));
	}
}

void writeWithCommas(Alloc, T, alias cb)(ref Writer!Alloc writer, immutable Arr!T a, immutable Bool leadingComma) {
	foreach (immutable size_t i; 0..a.size) {
		if (leadingComma || i != 0)
			writeStatic(writer, ", ");
		cb(a.at(i));
	}
}

void writeEscapedChar(Alloc)(ref Writer!Alloc writer, immutable char c) {
	switch (c) {
		case '\n':
			writeStatic(writer, "\\n");
			break;
		case '\t':
			writeStatic(writer, "\\t");
			break;
		case '\'':
			writeStatic(writer, "\\\'");
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

struct WriterWithIndent(Alloc) {
	private:
	Ptr!(Writer!Alloc) writer;
	u16 indent = 0;
}

void newline(Alloc)(ref WriterWithIndent!Alloc writer) {
	writer.writeChar('\n');
	foreach (immutable u16 _; 0..writer.indent)
		writeChar(writer, '\t');
}

void decrIndent(Alloc)(ref WriterWithIndent!Alloc writer) {
	assert(writer.indent != 0);
	writer.indent--;
}

void incrIndent(Alloc)(ref WriterWithIndent!Alloc writer) {
	writer.indent++;
}

void indent(Alloc)(ref WriterWithIndent!Alloc writer) {
	writer.incrIndent;
	writer.newline();
}

void dedent(Alloc)(ref WriterWithIndent!Alloc writer) {
	writer.decrIndent;
	writer.newline();
}

void writeChar(Alloc)(ref WriterWithIndent!Alloc writer, immutable char c) {
	writer.writer.writeChar(c);
}

void writeStatic(Alloc)(ref WriterWithIndent!Alloc writer, immutable CStr text) {
	writer.writer.writeStatic(text);
}

void writeStr(Alloc)(ref WriterWithIndent!Alloc writer, immutable Str s) {
	writer.writer.writeStr(s);
}


