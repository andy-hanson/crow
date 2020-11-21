module test.testWasm;

@safe @nogc nothrow: // not pure

//import io.io : tryReadFile;
import test.testUtil : Test;
import util.collection.str : asCStr, CStr, emptyStr, NulTerminatedStr, Str, strLiteral, strToCStr;
import util.opt : force, Opt;
import util.path : AbsolutePath, rootPath;
import util.sym : shortSymAlphaLiteral;
import wasmUtils : wasmRun;

void testWasm(Alloc)(ref Test!Alloc test) {
    /*
	immutable Str j = strLiteral(theJSON);
	immutable Str res = wasmRun(test.dbg, test.alloc, strToCStr(test.alloc, j));
	debug {
		import core.stdc.stdio : printf;
		import util.collection.arr : begin, size;
		printf("%.*s\n", cast(uint) size(res), begin(res));
	}
    */
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
			printf("%.*s\n", cast(uint) size(result), begin(result));
		}
	});
	*/
}
