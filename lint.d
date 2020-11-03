// rdmd lint.d

module lint;

@safe: // not pure, not @nogc, not nothrow

import std.algorithm.sorting : sort;
import std.array : array;
import std.file : dirEntries, DirEntry, isDir, readText, SpanMode;
import std.stdio : writeln;
import std.string : indexOf, indexOfAny;

immutable string SAMPLE = "import x : PathAndRange; none!PathAndRange;";

@trusted void main() {
	foreach (DirEntry entry; dirEntries("src", SpanMode.depth)) {
		if (entry.isFile()) {
			lintFile(entry.name());
		}
	}
}

private:

void lintFile(immutable string path) {
	immutable string s = readText(path);
	ImportsAndRest importsAndRest = findImports(s);

	eachWord(importsAndRest.rest, (immutable string word) {
		if (word in importsAndRest.imports)
			importsAndRest.imports[word] = true;
	});

	foreach (ref const kv; importsAndRest.imports.byKeyValue) {
		if (!kv.value) {
			writeln(path, ": unused import ", kv.key);
		}
	}
}

pure:

struct ImportsAndRest {
	bool[immutable string] imports;
	immutable string rest;
}

ImportsAndRest findImports(immutable string s) {
	bool[immutable string] res;
	size_t lastImport = 0;
	ptrdiff_t i = 0;
	while (true) {
		immutable ptrdiff_t importI = indexOf(s[i..$], "import ");
		if (importI == -1)
			break;
		i += importI;
		if (i != 0 && s[i - 1] != '\n') {
			i += "import ".length;
			continue;
		}
		i += "import ".length;

		immutable ptrdiff_t midI = indexOfAny(s[i..$], ":;");
		if (midI == -1)
			break;
		i += midI;
		if (s[i] == ';')
			continue;
		i++;

		immutable ptrdiff_t endI = indexOf(s[i..$], ';');
		if (endI == -1)
			break;
		eachWord(s[i..i + endI], (immutable string word) {
			res[word] = false;
		});
		i += endI + 1;
		lastImport = i;
	}
	return ImportsAndRest(res, s[lastImport..$]);
}

void eachWord(immutable string s, scope void delegate(immutable string) @safe pure nothrow cb) {
	long wordStart = -1;
	foreach (immutable size_t i; 0..s.length) {
		if (isIdentifierChar(s[i])) {
			if (wordStart == -1) {
				wordStart = i;
			}
		} else {
			if (wordStart != -1) {
				cb(s[wordStart..i]);
				wordStart = -1;
			}
		}
	}
	if (wordStart != -1)
		cb(s[wordStart..$]);
}

immutable(bool) isIdentifierChar(immutable char c) {
	return ('a' <= c && c <= 'z') || ('A' <= c && c <= 'Z') || ('0' <= c && c <= '9') || c == '_';
}


