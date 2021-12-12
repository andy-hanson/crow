module test.testHover;

@safe @nogc nothrow: // not pure

import frontend.frontendCompile : frontendCompile;
import frontend.ide.getHover : getHoverStr;
import frontend.ide.getPosition : getPosition, Position;
import model.model : Module, Program;
import test.testUtil : Test;
import util.collection.arr : lastPtr;
import util.collection.mutDict : addToMutDict;
import util.collection.str : end, SafeCStr, safeCStr, strEq;
import util.dbg : Debug, log, logNat, logNoNewline;
import util.dictReadOnlyStorage : DictReadOnlyStorage, MutFiles;
import util.opt : force, has, Opt;
import util.path : Path, PathAndStorageKind, rootPath, StorageKind;
import util.perf : Perf, withNullPerf;
import util.ptr : Ptr, ptrTrustMe_const;
import util.sourceRange : Pos;
import util.sym : shortSymAlphaLiteral;
import util.util : verify, verifyFail;

@trusted void testHover(ref Test test) {
	immutable Path path = rootPath(test.allPaths, shortSymAlphaLiteral("main"));
	immutable PathAndStorageKind key = immutable PathAndStorageKind(path, StorageKind.local);
	MutFiles files;
	addToMutDict(test.alloc, files, key, content);
	const DictReadOnlyStorage storage = const DictReadOnlyStorage(ptrTrustMe_const(files));
	immutable Program program = withNullPerf!(immutable Program, (scope ref Perf perf) =>
		frontendCompile(test.alloc, perf, test.alloc, test.allPaths, test.allSymbols, storage, key));
	immutable Ptr!Module mainModule = lastPtr(program.allModules);

	immutable(string) hover(immutable Pos pos) {
		immutable Opt!Position position = getPosition(mainModule.deref(), pos);
		return has(position)
			? getHoverStr(test.alloc, test.alloc, test.allPaths, program, force(position))
			: "";
	}

	void checkHover(immutable Pos pos, immutable string expected) {
		verifyStrEq(test.dbg, pos, hover(pos), expected);
	}
	void checkHoverRange(immutable Pos start, immutable Pos end, immutable string expected) {
		foreach (immutable Pos pos; start .. end)
			checkHover(pos, expected);
	}

	checkHover(0, "");
	checkHoverRange(1, 11, "builtin type nat");
	checkHoverRange(12, 13, "");
	immutable Pos rStart = 14;
	verify(content.ptr[rStart] == 'r');
	immutable Pos fldStart = rStart + 10;
	checkHoverRange(rStart, fldStart, "record r");
	verify(content.ptr[fldStart] == 'f');
	checkHoverRange(fldStart, fldStart + 3, "field r.fld (nat)");
	checkHoverRange(fldStart + 3, fldStart + 7, "builtin type nat");
	checkHoverRange(fldStart + 7, fldStart + 8, "record r");
	verify(content.ptr + fldStart + 8 == end(content.ptr));

	// TODO: TEST:
	// * imports (have these be actually working!)
	// * unions
	// * specs
	// * every expression
}

private:

void verifyStrEq(scope ref Debug dbg, immutable Pos pos, immutable string actual, immutable string expected) {
	if (!strEq(actual, expected)) {
		logNoNewline(dbg, "at position ");
		logNat(dbg, pos);
		log(dbg, "\nactual:");
		log(dbg, actual);
		log(dbg, "expected:");
		log(dbg, expected);
		verifyFail();
	}
}

immutable SafeCStr content = safeCStr!`
nat builtin

r record
	fld nat
`;
