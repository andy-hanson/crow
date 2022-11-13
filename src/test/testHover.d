module test.testHover;

@safe @nogc nothrow: // not pure

import frontend.frontendCompile : frontendCompile;
import frontend.ide.getHover : getHoverStr;
import frontend.ide.getPosition : getPosition, Position;
import model.model : Module, Program;
import test.testUtil : Test;
import util.col.mutDict : addToMutDict;
import util.col.str : end, SafeCStr, safeCStr, safeCStrEq;
import util.dictReadOnlyStorage : withDictReadOnlyStorage, MutFiles;
import util.opt : force, has, Opt;
import util.path : emptyPathsInfo, Path, PathsInfo, rootPath;
import util.perf : Perf, withNullPerf;
import util.readOnlyStorage : ReadOnlyStorage;
import util.sourceRange : Pos;
import util.sym : sym;
import util.util : verify, verifyFail;

@trusted void testHover(ref Test test) {
	testBasic(test);
	testFunction(test);
}

private:

struct HoverTest {
	immutable Program program;
	immutable Module* mainModule;
}

HoverTest initHoverTest(ref Test test, immutable SafeCStr content) {
	immutable Path path = rootPath(test.allPaths, sym!"main");
	MutFiles files;
	addToMutDict(test.alloc, files, path, content);
	immutable Program program = withDictReadOnlyStorage!(immutable Program)(
		rootPath(test.allPaths, sym!"include"),
		files,
		(scope ref const ReadOnlyStorage storage) @safe =>
			withNullPerf!(immutable Program, (ref Perf perf) @safe =>
				frontendCompile(test.alloc, perf, test.alloc, test.allPaths, test.allSymbols, storage, [path])));
	immutable Module* mainModule = &program.allModules[$ - 1];
	return HoverTest(program, mainModule);
}

immutable(SafeCStr) hover(ref Test test, ref HoverTest a, immutable Pos pos) {
	immutable Opt!Position position = getPosition(test.allSymbols, *a.mainModule, pos);
	immutable PathsInfo pathsInfo = emptyPathsInfo;
	return has(position)
		? getHoverStr(test.alloc, test.alloc, test.allSymbols, test.allPaths, pathsInfo, a.program, force(position))
		: safeCStr!"";
}

void checkHover(ref Test test, ref HoverTest hoverTest, immutable Pos pos, immutable SafeCStr expected) {
	verifyStrEq(pos, hover(test, hoverTest, pos), expected);
}

void checkHoverRange(
	ref Test test,
	ref HoverTest hoverTest,
	immutable Pos start,
	immutable Pos end,
	immutable SafeCStr expected,
) {
	foreach (immutable Pos pos; start .. end)
		checkHover(test, hoverTest, pos, expected);
}

@trusted void testBasic(ref Test test) {
	immutable SafeCStr content = safeCStr!`
nat builtin

r record
	fld nat
`;
	HoverTest a = initHoverTest(test, content);

	checkHover(test, a, 0, safeCStr!"");
	checkHoverRange(test, a, 1, 11, safeCStr!"builtin type nat");
	checkHoverRange(test, a, 12, 13, safeCStr!"");
	immutable Pos rStart = 14;
	verify(content.ptr[rStart] == 'r');
	immutable Pos fldStart = rStart + 10;
	checkHoverRange(test, a, rStart, fldStart, safeCStr!"record r");
	verify(content.ptr[fldStart] == 'f');
	checkHoverRange(test, a, fldStart, fldStart + 3, safeCStr!"field r.fld (nat)");
	checkHoverRange(test, a, fldStart + 3, fldStart + 7, safeCStr!"builtin type nat");
	checkHoverRange(test, a, fldStart + 7, fldStart + 8, safeCStr!"record r");
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

	checkHover(test, a, 0, safeCStr!"fun f");
	checkHoverRange(test, a, 1, 5, safeCStr!"TODO: hover for type");
	checkHover(test, a, 6, safeCStr!"param a");
	checkHoverRange(test, a, 7, 10, safeCStr!"TODO: hover for type");
	checkHoverRange(test, a, 11, 13, safeCStr!"");
	checkHover(test, a, 13, safeCStr!"param b");
	checkHoverRange(test, a, 15, 18, safeCStr!"TODO: hover for type");

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
