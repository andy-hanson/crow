module util.writerUtils;

@safe @nogc pure nothrow:

import util.lineAndColumnGetter : LineAndColumn, lineAndColumnAtPos, LineAndColumnGetter;
import util.opt : force, has;
import util.path : baseName, nParents, parent, path, Path, PathAndStorageKind, RelPath;
import util.ptr : Ptr;
import util.sourceRange : Pos, SourceRange;
import util.sym : Sym, writeSym;
import util.util : repeat;
import util.writer : writeChar, writeNat, Writer, writeStatic;

void writePath(Alloc)(ref Writer!Alloc writer, immutable Ptr!Path p) {
	if (has(p.parent)) {
		writePath(writer, force(p.parent));
		writeChar(writer, '/');
	}
	writeSym(writer, p.baseName);
}

void writeRelPath(Alloc)(ref Writer!Alloc writer, ref immutable RelPath p) {
	repeat(nParents(p), {
		writeStatic(writer, "../");
	});
	writePath(writer, p.path);
}

void writePathAndStorageKind(Alloc)(ref Writer!Alloc writer, ref immutable PathAndStorageKind p) {
	writePath(writer, p.path);
}

void writeLineAndColumn(Alloc)(ref Writer!Alloc writer, immutable LineAndColumn lc) {
	writeNat(writer, lc.line + 1);
	writeChar(writer, ':');
	writeNat(writer, lc.column + 1);
}

void writePos(Alloc)(ref Writer!Alloc writer, ref immutable LineAndColumnGetter lc, immutable Pos pos) {
	writeLineAndColumn(writer, lineAndColumnAtPos(lc, pos));
}

void writeRange(Alloc)(ref Writer!Alloc writer, ref immutable LineAndColumnGetter lc, immutable SourceRange range) {
	writePos(writer, lc, range.start);
	writeChar(writer, '-');
	writePos(writer, lc, range.end);
}

void showChar(Alloc)(ref Writer!Alloc writer, immutable char c) {
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

void writeName(Alloc)(ref Writer!Alloc writer, immutable Sym name) {
	writeChar(writer, '\'');
	writeSym(writer, name);
	writeChar(writer, '\'');
}

void writeNl(Alloc)(ref Writer!Alloc writer) {
	writeChar(writer, '\n');
}

void writeSpaces(Alloc)(ref Writer!Alloc writer, immutable size_t nSpaces) {
	repeat(nSpaces, {
		writeChar(writer, ' ');
	});
}

void writeIndent(Alloc)(ref Writer!Alloc writer) {
	writeSpaces(writer, 2);
}

void writeNlIndent(Alloc)(ref Writer!Alloc writer) {
	writeNl(writer);
	writeIndent(writer);
}

void writeSymPadded(Alloc)(ref Writer!Alloc writer, immutable Sym name, immutable size_t size) {
	immutable size_t symSize = writeSymAndGetSize(writer, name);
	if (symSize >= size) todo!void("??");
	writeSpaces(writer, size - symSize);
}
