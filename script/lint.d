@safe: // not pure, not @nogc, not nothrow

import std.algorithm.searching : any;
import std.algorithm.sorting : sort;
import std.array : array;
import std.file : dirEntries, DirEntry, isDir, readText, SpanMode;
import std.process : execute;
import std.stdio : writeln;
import std.string : indexOf, indexOfAny, splitLines;

@trusted int main() {
	immutable File[] files = allFiles();

	foreach (ref immutable File file; files) {
		foreach (immutable string publicExport; file.members.public_) {
			if (!any!(otherFile => publicExport in otherFile.imports)(files)) {
				if (publicExport != "derefConstantPointer" &&
					publicExport != "diffSymbols" &&
					publicExport != "test") // TODO
					writeln(file.path, " export not used: ", publicExport);
			}
		}
	}

	foreach (ref immutable File file; files) {
		foreach (immutable string privateMember; file.members.private_) {
			final switch (file.uses[privateMember]) {
				case Uses.none:
					writeln("Shouldn't get here?");
					assert(0);
					break;
				case Uses.one:
					// TODO: adding these exceptions for now
					if (privateMember != "matchOperationImpureAndMeasure" &&
						privateMember != "writeFieldName" &&
						privateMember != "writeLocalName" &&
						// TODO: this isn't even private. Probably a bug due to recursive imports
						privateMember != "asConcreteFun")
						writeln(file.path, " private member not used: ", privateMember);
					break;
				case Uses.many:
					break;
			}
		}
	}

	bool anyErrors = false;
	foreach (ref immutable File file; files) {
		anyErrors = anyErrors | lintImportsInFile(file);
	}
	return anyErrors ? 1 : 0;
}

private:

struct Void {}

struct File {
	immutable string path;
	immutable Members members;
	immutable Void[immutable string] imports;
	immutable Uses[immutable string] uses;
}

struct Members {
	immutable string[] public_;
	immutable string[] private_;
}

@trusted immutable(File[]) allFiles() {
	immutable(File)[] res;
	foreach (DirEntry entry; dirEntries("src", SpanMode.depth)) {
		if (entry.isFile()) {
			immutable string path = entry.name();
			immutable Members members = getMembers(path);
			immutable string text = readText(path);
			immutable ImportsAndRest importsAndRest = findImports(text);
			res ~= immutable File(path, members, importsAndRest.imports, getUses(importsAndRest.rest));
		}
	}
	return res;
}

immutable(Members) getMembers(immutable string path) {
	immutable auto res = execute(["dub", "run", "dscanner", "--", "--ctags", path]);
	if (res.status != 0) writeln("FAILED?");

	immutable string lookFor = "!_TAG_PROGRAM_URL	https://github.com/dlang-community/D-Scanner/\n";
	immutable ptrdiff_t index = indexOf(res.output, lookFor);
	if (index == -1) {
		writeln("Didn't find it?");
		assert(0);
	}

	immutable(string)[] public_;
	immutable(string)[] private_;

	foreach (immutable string line; splitLines(res.output[index + lookFor.length .. $])) {
		if (!(contains(line, "enum:") || contains(line, "struct:"))) {
			immutable ptrdiff_t space = indexOfAny(line, " \t");
			if (space == -1) {
				writeln("No space in line?");
				writeln(line);
				assert(0);
			}
			immutable string name = line[0 .. space];
			if (contains(line, "access:public")) {
				public_ ~= name;
				// For some reason dscanner doesn't give non-nested unions like Converter64 access:private
			} else if (contains(line, "access:private")
				|| name == "Converter32"
				|| name == "Converter64"
				|| name == "DoubleToUlong"
			) {
				private_ ~= name;
			} else {
				// extern is neither public nor private
				if (path != "src/app.d" && path != "src/wasm.d") {
					writeln("Unexpected non-public, non-private member ", name, " in ", path);
					assert(0);
				}
			}
		}
	}

	return immutable Members(public_, private_);
}

immutable(bool) contains(immutable string a, immutable string b) {
	return indexOf(a, b) != -1;
}

immutable(bool) lintImportsInFile(ref immutable File file) {
	immutable(Void)[immutable string] importsNotUsed = file.imports.dup;

	foreach (immutable string key; file.uses.byKey)
		importsNotUsed.remove(key);

	foreach (ref const key; importsNotUsed.byKey)
		writeln(file.path, ": unused import ", key);
	return importsNotUsed.length != 0;
}

pure:

enum Uses {
	none,
	one,
	many,
}

struct ImportsAndRest {
	immutable Void[immutable string] imports;
	immutable string rest;
}

immutable(ImportsAndRest) findImports(immutable string s) {
	Void[immutable string] res;
	size_t lastImport = 0;
	ptrdiff_t i = 0;
	while (true) {
		immutable ptrdiff_t importI = indexOf(s[i .. $], "import ");
		if (importI == -1)
			break;
		i += importI;
		if (i != 0 && s[i - 1] != '\n') {
			i += "import ".length;
			continue;
		}
		i += "import ".length;

		immutable ptrdiff_t midI = indexOfAny(s[i .. $], ":;");
		if (midI == -1)
			break;
		i += midI;
		if (s[i] == ';')
			continue;
		i++;

		immutable ptrdiff_t endI = indexOf(s[i .. $], ';');
		if (endI == -1)
			break;
		eachWord(s[i .. i + endI], (immutable string word) {
			res[word] = immutable Void();
		});
		i += endI + 1;
		lastImport = i;
	}

	return immutable ImportsAndRest(castImmutable(res), s[lastImport .. $]);
}

@trusted immutable(Void[immutable string]) castImmutable(Void[immutable string] a) {
	return cast(immutable) a;
}

immutable(Uses) incr(immutable Uses a) {
	final switch (a) {
		case Uses.none:
			return Uses.one;
		case Uses.one:
		case Uses.many:
			return Uses.many;
	}
}

immutable(Uses[immutable string]) getUses(immutable string s) {
	Uses[immutable string] res;
	eachWord(s, (immutable string word) {
		res[word] = incr(res.get(word, Uses.none));
	});
	return res;
}

void eachWord(immutable string s, scope void delegate(immutable string) @safe pure cb) {
	long wordStart = -1;
	foreach (immutable size_t i; 0 .. s.length) {
		if (isIdentifierChar(s[i])) {
			if (wordStart == -1) {
				wordStart = i;
			}
		} else {
			if (wordStart != -1) {
				cb(s[wordStart .. i]);
				wordStart = -1;
			}
		}
	}
	if (wordStart != -1)
		cb(s[wordStart .. $]);
}

immutable(bool) isIdentifierChar(immutable char c) {
	return ('a' <= c && c <= 'z') || ('A' <= c && c <= 'Z') || ('0' <= c && c <= '9') || c == '_';
}
