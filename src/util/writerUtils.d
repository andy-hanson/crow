module util.writerUtils;

@safe @nogc pure nothrow:

import util.lineAndColumnGetter : LineAndColumn, lineAndColumnAtPos, LineAndColumnGetter;
import util.sourceRange : Pos, RangeWithinFile;
import util.sym : AllSymbols, Sym, writeSym, writeSymAndGetSize;
import util.util : todo;
import util.writer : writeChar, writeNat, Writer, writeStatic;

private void writeLineAndColumn(ref Writer writer, immutable LineAndColumn lc) {
	writeNat(writer, lc.line + 1);
	writeChar(writer, ':');
	writeNat(writer, lc.column + 1);
}

void writePos(ref Writer writer, ref immutable LineAndColumnGetter lc, immutable Pos pos) {
	writeLineAndColumn(writer, lineAndColumnAtPos(lc, pos));
}

void writeRangeWithinFile(
	ref Writer writer,
	ref immutable LineAndColumnGetter lc,
	immutable RangeWithinFile range,
) {
	writePos(writer, lc, range.start);
	writeChar(writer, '-');
	writePos(writer, lc, range.end);
}

void showChar(ref Writer writer, immutable char c) {
	switch (c) {
		case '\0':
			writeStatic(writer, "\\0");
			break;
		case '\n':
			writeStatic(writer, "\\n");
			break;
		case '\t':
			writeStatic(writer, "\\t");
			break;
		default:
			writeChar(writer, c);
			break;
	}
}

void writeName(ref Writer writer, ref const AllSymbols allSymbols, immutable Sym name) {
	writeChar(writer, '\'');
	writeSym(writer, allSymbols, name);
	writeChar(writer, '\'');
}

void writeNl(ref Writer writer) {
	writeChar(writer, '\n');
}

void writeSpaces(ref Writer writer, immutable size_t nSpaces) {
	foreach (immutable size_t i; 0 .. nSpaces)
		writeChar(writer, ' ');
}

void writeNlIndent(ref Writer writer) {
	writeNl(writer);
	writeSpaces(writer, 2);
}

void writeSymPadded(ref Writer writer, ref const AllSymbols allSymbols, immutable Sym name, immutable size_t size) {
	immutable size_t symSize = writeSymAndGetSize(writer, allSymbols, name);
	if (symSize >= size) todo!void("??");
	writeSpaces(writer, size - symSize);
}
