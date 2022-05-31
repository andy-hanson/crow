module util.writerUtils;

@safe @nogc pure nothrow:

import util.lineAndColumnGetter : LineAndColumn, lineAndColumnAtPos, LineAndColumnGetter;
import util.sourceRange : Pos, RangeWithinFile;
import util.sym : AllSymbols, Sym, writeSym, writeSymAndGetSize;
import util.util : todo;
import util.writer : Writer;

private void writeLineAndColumn(ref Writer writer, immutable LineAndColumn lc) {
	writer ~= lc.line + 1;
	writer ~= ':';
	writer ~= lc.column + 1;
}

void writePos(ref Writer writer, scope ref immutable LineAndColumnGetter lc, immutable Pos pos) {
	writeLineAndColumn(writer, lineAndColumnAtPos(lc, pos));
}

void writeRangeWithinFile(
	ref Writer writer,
	ref immutable LineAndColumnGetter lc,
	immutable RangeWithinFile range,
) {
	writePos(writer, lc, range.start);
	writer ~= '-';
	writePos(writer, lc, range.end);
}

void showChar(ref Writer writer, immutable char c) {
	switch (c) {
		case '\0':
			writer ~= "\\0";
			break;
		case '\n':
			writer ~= "\\n";
			break;
		case '\t':
			writer ~= "\\t";
			break;
		default:
			writer ~= c;
			break;
	}
}

void writeName(ref Writer writer, ref const AllSymbols allSymbols, immutable Sym name) {
	writer ~= '\'';
	writeSym(writer, allSymbols, name);
	writer ~= '\'';
}

void writeNl(ref Writer writer) {
	writer ~= '\n';
}

void writeSpaces(ref Writer writer, immutable size_t nSpaces) {
	foreach (immutable size_t i; 0 .. nSpaces)
		writer ~= ' ';
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
