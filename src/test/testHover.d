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
import util.path : emptyPathsInfo, Path, PathsInfo, rootPath;
import util.perf : Perf, withNullPerf;
import util.ptr : Ptr, ptrTrustMe_mut;
import util.readOnlyStorage : ReadOnlyStorage;
import util.sourceRange : Pos;
import util.sym : shortSym;
import util.util : verify, verifyFail;

@trusted void testHover(ref Test test) {
	testBasic(test);
	testFunction(test);
}

private:

struct HoverTest {
	@safe @nogc pure nothrow:

	Ptr!Test testPtr;
	immutable Program program;
	immutable Ptr!Module mainModule;

	ref Test test() return scope {
		return testPtr.deref();
	}
}

HoverTest initHoverTest(ref Test test, immutable SafeCStr content) {
	immutable Path path = rootPath(test.allPaths, shortSym("main"));
	MutFiles files;
	addToMutDict(test.alloc, files, path, content);
	immutable Program program = withDictReadOnlyStorage!(immutable Program)(
		rootPath(test.allPaths, shortSym("include")),
		files,
		(scope ref const ReadOnlyStorage storage) =>
			withNullPerf!(immutable Program, (scope ref Perf perf) =>
				frontendCompile(test.alloc, perf, test.alloc, test.allPaths, test.allSymbols, storage, [path])));
	immutable Ptr!Module mainModule = lastPtr(program.allModules);
	return HoverTest(ptrTrustMe_mut(test), program, mainModule);
}

immutable(SafeCStr) hover(ref HoverTest a, immutable Pos pos) {
	immutable Opt!Position position = getPosition(a.test.allSymbols, a.mainModule.deref(), pos);
	immutable PathsInfo pathsInfo = emptyPathsInfo;
	return has(position)
		? getHoverStr(
			a.test.alloc, a.test.alloc, a.test.allSymbols, a.test.allPaths, pathsInfo, a.program, force(position))
		: safeCStr!"";
}

void checkHover(ref HoverTest test, immutable Pos pos, immutable SafeCStr expected) {
	verifyStrEq(pos, hover(test, pos), expected);
}

void checkHoverRange(ref HoverTest test, immutable Pos start, immutable Pos end, immutable SafeCStr expected) {
	foreach (immutable Pos pos; start .. end)
		checkHover(test, pos, expected);
}

@trusted void testBasic(ref Test test) {
	immutable SafeCStr content = safeCStr!`
nat builtin

r record
	fld nat
`;
	HoverTest a = initHoverTest(test, content);

	checkHover(a, 0, safeCStr!"");
	checkHoverRange(a, 1, 11, safeCStr!"builtin type nat");
	checkHoverRange(a, 12, 13, safeCStr!"");
	immutable Pos rStart = 14;
	verify(content.ptr[rStart] == 'r');
	immutable Pos fldStart = rStart + 10;
	checkHoverRange(a, rStart, fldStart, safeCStr!"record r");
	verify(content.ptr[fldStart] == 'f');
	checkHoverRange(a, fldStart, fldStart + 3, safeCStr!"field r.fld (nat)");
	checkHoverRange(a, fldStart + 3, fldStart + 7, safeCStr!"builtin type nat");
	checkHoverRange(a, fldStart + 7, fldStart + 8, safeCStr!"record r");
	verify(content.ptr + fldStart + 8 == end(content.ptr));

	// TODO: TEST:
	// * imports (have these be actually working!)
	// * unions
	// * specs
	// * every expression
}

void testFunction(ref Test test) {
	HoverTest a = initHoverTest(test, safeCStr!`f nat(a str, b nat)
	a[b]
`);

	checkHover(a, 0, safeCStr!"fun f");
	checkHoverRange(a, 1, 5, safeCStr!"TODO: hover for type");
	checkHover(a, 6, safeCStr!"param a");
	checkHoverRange(a, 7, 10, safeCStr!"TODO: hover for type");
	checkHoverRange(a, 11, 13, safeCStr!"");
	checkHover(a, 13, safeCStr!"param b");
	checkHoverRange(a, 15, 18, safeCStr!"TODO: hover for type");

	//TODO: hover in function body
}

void verifyStrEq(immutable Pos pos, immutable SafeCStr actual, immutable SafeCStr expected) {
	if (!safeCStrEq(actual, expected)) {
		debug {
			import core.stdc.stdio : printf;
			printf("at position %d:\nactual: %s\nexpected: %s\n", pos, actual.ptr, expected.ptr);
		}
		verifyFail();
	}
}
