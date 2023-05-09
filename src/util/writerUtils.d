module util.writerUtils;

@safe @nogc pure nothrow:

import util.lineAndColumnGetter : LineAndColumn, lineAndColumnAtPos, LineAndColumnGetter, PosKind;
import util.sourceRange : Pos, RangeWithinFile;
import util.sym : AllSymbols, Sym, writeSym, writeSymAndGetSize;
import util.util : todo;
import util.writer : Writer;

private void writeLineAndColumn(ref Writer writer, LineAndColumn lc) {
	writer ~= lc.line + 1;
	writer ~= ':';
	writer ~= lc.column + 1;
}

void writePos(ref Writer writer, in LineAndColumnGetter lc, Pos pos, PosKind kind) {
	writeLineAndColumn(writer, lineAndColumnAtPos(lc, pos, kind));
}

void writeRangeWithinFile(scope ref Writer writer, in LineAndColumnGetter lc, RangeWithinFile range) {
	writePos(writer, lc, range.start, PosKind.startOfRange);
	writer ~= '-';
	writePos(writer, lc, range.end, PosKind.endOfRange);
}

void showChar(scope ref Writer writer, char c) {
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

void writeName(scope ref Writer writer, in AllSymbols allSymbols, Sym name) {
	writer ~= '\'';
	writeSym(writer, allSymbols, name);
	writer ~= '\'';
}

void writeNl(scope ref Writer writer) {
	writer ~= '\n';
}

void writeSpaces(scope ref Writer writer, size_t nSpaces) {
	foreach (size_t i; 0 .. nSpaces)
		writer ~= ' ';
}

void writeNlIndent(scope ref Writer writer) {
	writeNl(writer);
	writeSpaces(writer, 2);
}

void writeSymPadded(scope ref Writer writer, in AllSymbols allSymbols, Sym name, size_t size) {
	size_t symSize = writeSymAndGetSize(writer, allSymbols, name);
	if (symSize >= size) todo!void("??");
	writeSpaces(writer, size - symSize);
}
