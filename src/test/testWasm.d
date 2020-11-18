module test.testWasm;

@safe @nogc nothrow: // not pure

//import io.io : tryReadFile;
import test.testUtil : Test;
import util.collection.str : asCStr, CStr, emptyStr, NulTerminatedStr, Str, strLiteral;
import util.opt : force, Opt;
import util.path : AbsolutePath, rootPath;
import util.sym : shortSymAlphaLiteral;
import wasmUtils : wasmRun;

void testWasm(Alloc)(ref Test!Alloc test) {
	/*
	immutable AbsolutePath path = immutable AbsolutePath(
		emptyStr,
		rootPath(test.alloc, shortSymAlphaLiteral("test")),
		strLiteral(".json"));
	tryReadFile!void(test.alloc, test.alloc, path, (ref immutable Opt!NulTerminatedStr text) {
		immutable Str result = wasmRun(test.alloc, castMutable(asCStr(force(text))));
		debug {
			import core.stdc.stdio : printf;
			import util.collection.arr : begin, size;
			printf("%.*s\n", cast(int) size(result), begin(result));
		}
	});
	*/
}

@trusted char* castMutable(immutable CStr a) {
	return cast(char*) a;
}
