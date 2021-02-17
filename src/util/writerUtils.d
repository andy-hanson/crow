module util.writerUtils;

@safe @nogc pure nothrow:

import util.collection.arr : size;
import util.collection.str : startsWith;
import util.lineAndColumnGetter : LineAndColumn, lineAndColumnAtPos, LineAndColumnGetter;
import util.opt : force, has, Opt;
import util.path : AbsolutePath, AllPaths, baseName, nParents, parent, path, Path, PathAndStorageKind, RelPath;
import util.sourceRange : Pos, RangeWithinFile;
import util.sym : Sym, writeSym, writeSymAndGetSize;
import util.util : repeat, todo;
import util.writer : writeChar, writeNat, Writer, writeStatic, writeStr;

private void writePath(Alloc, PathAlloc)(
	ref Writer!Alloc writer,
	ref const AllPaths!PathAlloc allPaths,
	immutable Path p,
) {
	immutable Opt!Path par = parent(allPaths, p);
	if (has(par)) {
		writePath(writer, allPaths, force(par));
		writeChar(writer, '/');
	}
	writeStr(writer, baseName(allPaths, p));
}

void writePathRelativeToCwd(Alloc, PathAlloc)(
	ref Writer!Alloc writer,
	ref const AllPaths!PathAlloc allPaths,
	immutable string cwd,
	ref immutable AbsolutePath path,
) {
	if (startsWith(path.root, cwd) &&
		(size(path.root) == size(cwd) || (size(path.root) > size(cwd) + 1 && path.root[size(cwd)] == '/'))) {
		writeStatic(writer, "./");
		if (size(path.root) != size(cwd)) {
			writeStr(writer, path.root[size(cwd) + 1 .. $]);
			writeChar(writer, '/');
		}
	} else {
		writeStr(writer, path.root);
		writeChar(writer, '/');
	}
	writePath(writer, allPaths, path.path);
	writeStr(writer, path.extension);
}

void writeRelPath(Alloc, PathAlloc)(
	ref Writer!Alloc writer,
	ref const AllPaths!PathAlloc allPaths,
	ref immutable RelPath p,
) {
	repeat(nParents(p), {
		writeStatic(writer, "../");
	});
	writePath(writer, allPaths, p.path);
}

void writePathAndStorageKind(Alloc, PathAlloc)(
	ref Writer!Alloc writer,
	ref const AllPaths!PathAlloc allPaths,
	ref immutable PathAndStorageKind p,
) {
	writePath(writer, allPaths, p.path);
}

private void writeLineAndColumn(Alloc)(ref Writer!Alloc writer, immutable LineAndColumn lc) {
	writeNat(writer, lc.line + 1);
	writeChar(writer, ':');
	writeNat(writer, lc.column + 1);
}

void writePos(Alloc)(ref Writer!Alloc writer, ref immutable LineAndColumnGetter lc, immutable Pos pos) {
	writeLineAndColumn(writer, lineAndColumnAtPos(lc, pos));
}

void writeRangeWithinFile(Alloc)(
	ref Writer!Alloc writer,
	ref immutable LineAndColumnGetter lc,
	immutable RangeWithinFile range,
) {
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

void writeNlIndent(Alloc)(ref Writer!Alloc writer) {
	writeNl(writer);
	writeSpaces(writer, 2);
}

void writeSymPadded(Alloc)(ref Writer!Alloc writer, immutable Sym name, immutable size_t size) {
	immutable size_t symSize = writeSymAndGetSize(writer, name);
	if (symSize >= size) todo!void("??");
	writeSpaces(writer, size - symSize);
}
