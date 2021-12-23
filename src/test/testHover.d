module test.testHover;

@safe @nogc nothrow: // not pure

import frontend.frontendCompile : frontendCompile;
import frontend.ide.getHover : getHoverStr;
import frontend.ide.getPosition : getPosition, Position;
import model.model : Module, Program;
import test.testUtil : Test;
import util.col.arr : lastPtr;
import util.col.mutDict : addToMutDict;
import util.col.str : end, SafeCStr, safeCStr, safeCStrEq;
import util.dictReadOnlyStorage : withDictReadOnlyStorage, MutFiles;
import util.opt : force, has, Opt;
import util.path : Path, PathAndStorageKind, rootPath, StorageKind;
import util.perf : Perf, withNullPerf;
import util.ptr : Ptr;
import util.readOnlyStorage : ReadOnlyStorage;
import util.sourceRange : Pos;
import util.sym : shortSym;
import util.util : verify, verifyFail;

@trusted void testHover(ref Test test) {
	immutable Path path = rootPath(test.allPaths, shortSym("main"));
	immutable PathAndStorageKind key = immutable PathAndStorageKind(path, StorageKind.local);
	MutFiles files;
	addToMutDict(test.alloc, files, key, content);
	immutable Program program = withDictReadOnlyStorage!(immutable Program)(
		files,
		(scope ref const ReadOnlyStorage storage) =>
			withNullPerf!(immutable Program, (scope ref Perf perf) =>
				frontendCompile(test.alloc, perf, test.alloc, test.allPaths, test.allSymbols, storage, [key])));
	immutable Ptr!Module mainModule = lastPtr(program.allModules);

	immutable(SafeCStr) hover(immutable Pos pos) {
		immutable Opt!Position position = getPosition(test.allSymbols, mainModule.deref(), pos);
		return has(position)
			? getHoverStr(test.alloc, test.alloc, test.allSymbols, test.allPaths, program, force(position))
			: safeCStr!"";
	}

	void checkHover(immutable Pos pos, immutable SafeCStr expected) {
		verifyStrEq(pos, hover(pos), expected);
	}
	void checkHoverRange(immutable Pos start, immutable Pos end, immutable SafeCStr expected) {
		foreach (immutable Pos pos; start .. end)
			checkHover(pos, expected);
	}

	checkHover(0, safeCStr!"");
	checkHoverRange(1, 11, safeCStr!"builtin type nat");
	checkHoverRange(12, 13, safeCStr!"");
	immutable Pos rStart = 14;
	verify(content.ptr[rStart] == 'r');
	immutable Pos fldStart = rStart + 10;
	checkHoverRange(rStart, fldStart, safeCStr!"record r");
	verify(content.ptr[fldStart] == 'f');
	checkHoverRange(fldStart, fldStart + 3, safeCStr!"field r.fld (nat)");
	checkHoverRange(fldStart + 3, fldStart + 7, safeCStr!"builtin type nat");
	checkHoverRange(fldStart + 7, fldStart + 8, safeCStr!"record r");
	verify(content.ptr + fldStart + 8 == end(content.ptr));

	// TODO: TEST:
	// * imports (have these be actually working!)
	// * unions
	// * specs
	// * every expression
}

private:

void verifyStrEq(immutable Pos pos, immutable SafeCStr actual, immutable SafeCStr expected) {
	if (!safeCStrEq(actual, expected)) {
		debug {
			import core.stdc.stdio : printf;
			printf("at position %d:\nactual: %s\nexpected: %s\n", pos, actual.ptr, expected.ptr);
		}
		verifyFail();
	}
}

immutable SafeCStr content = safeCStr!`
nat builtin

r record
	fld nat
`;
