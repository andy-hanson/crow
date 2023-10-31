module util.writerUtils;

@safe @nogc pure nothrow:

import util.lineAndColumnGetter : LineAndColumn, LineAndColumnRange;
import util.sym : AllSymbols, Sym, writeSymAndGetSize;
import util.util : todo;
import util.writer : Writer;

void writeLineAndColumnRange(ref Writer writer, in LineAndColumnRange a) {
	writeLineAndColumn(writer, a.start);
	writer ~= '-';
	writeLineAndColumn(writer, a.end);
}

void writeLineAndColumn(ref Writer writer, LineAndColumn lc) {
	writer ~= lc.line + 1;
	writer ~= ':';
	writer ~= lc.column + 1;
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
