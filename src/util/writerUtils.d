module util.writerUtils;

@safe @nogc pure nothrow:

import util.col.str : SafeCStr, startsWith, strOfSafeCStr;
import util.lineAndColumnGetter : LineAndColumn, lineAndColumnAtPos, LineAndColumnGetter;
import util.opt : force, has, Opt;
import util.path : AbsolutePath, AllPaths, baseName, nParents, parent, path, Path, PathAndStorageKind, RelPath;
import util.sourceRange : Pos, RangeWithinFile;
import util.sym : AllSymbols, Sym, writeSym, writeSymAndGetSize;
import util.util : todo;
import util.writer : writeChar, writeNat, Writer, writeStatic, writeSafeCStr, writeStr;

private void writePath(
	ref Writer writer,
	ref const AllPaths allPaths,
	immutable Path p,
) {
	immutable Opt!Path par = parent(allPaths, p);
	if (has(par)) {
		writePath(writer, allPaths, force(par));
		writeChar(writer, '/');
	}
	writeSym(writer, allPaths.allSymbols, baseName(allPaths, p));
}

void writePathRelativeToCwd(
	ref Writer writer,
	ref const AllPaths allPaths,
	immutable SafeCStr cwdCStr,
	ref immutable AbsolutePath path,
) {
	immutable string cwd = strOfSafeCStr(cwdCStr);
	immutable string root = strOfSafeCStr(path.root);
	if (startsWith(root, cwd) &&
		(root.length == cwd.length || (root.length > cwd.length + 1 && root[cwd.length] == '/'))) {
		writeStatic(writer, "./");
		if (root.length != cwd.length) {
			writeStr(writer, root[cwd.length + 1 .. $]);
			writeChar(writer, '/');
		}
	} else {
		writeStr(writer, root);
		writeChar(writer, '/');
	}
	writePath(writer, allPaths, path.path);
	writeSafeCStr(writer, path.extension);
}

void writeRelPath(
	ref Writer writer,
	ref const AllPaths allPaths,
	ref immutable RelPath p,
) {
	foreach (immutable ushort i; 0 .. nParents(p))
		writeStatic(writer, "../");
	writePath(writer, allPaths, p.path);
}

void writePathAndStorageKind(
	ref Writer writer,
	ref const AllPaths allPaths,
	immutable PathAndStorageKind p,
) {
	writePath(writer, allPaths, p.path);
}

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
