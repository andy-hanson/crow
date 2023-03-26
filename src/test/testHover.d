module test.testHover;

@safe @nogc nothrow: // not pure

import frontend.frontendCompile : frontendCompile;
import frontend.ide.getHover : getHoverStr;
import frontend.ide.getPosition : getPosition, Position;
import model.model : Module, Program;
import test.testUtil : Test;
import util.col.mutMap : addToMutMap;
import util.col.str : end, SafeCStr, safeCStr, safeCStrEq;
import util.memoryReadOnlyStorage : withMemoryReadOnlyStorage, MutFiles;
import util.opt : force, has, none, Opt;
import util.path : emptyPathsInfo, Path, rootPath;
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

immutable struct HoverTest {
	Program program;
	Module* mainModule;
}

HoverTest initHoverTest(ref Test test, SafeCStr content) {
	Path path = rootPath(test.allPaths, sym!"main");
	MutFiles files;
	addToMutMap(test.alloc, files, path, content);
	Program program = withMemoryReadOnlyStorage!Program(
		rootPath(test.allPaths, sym!"include"),
		files,
		(in ReadOnlyStorage storage) =>
			withNullPerf!(Program, (ref Perf perf) =>
				frontendCompile(
					test.alloc, perf, test.alloc, test.allPaths, test.allSymbols, storage, [path], none!Path)));
	Module* mainModule = &program.allModules[$ - 1];
	return HoverTest(program, mainModule);
}

SafeCStr hover(ref Test test, in HoverTest a, Pos pos) {
	Opt!Position position = getPosition(test.allSymbols, *a.mainModule, pos);
	return has(position)
		? getHoverStr(
			test.alloc, test.alloc, test.allSymbols, test.allPaths, emptyPathsInfo, a.program, force(position))
		: safeCStr!"";
}

void checkHover(ref Test test, ref HoverTest hoverTest, Pos pos, in SafeCStr expected) {
	verifyStrEq(pos, hover(test, hoverTest, pos), expected);
}

void checkHoverRange(ref Test test, ref HoverTest hoverTest, Pos start, Pos end, in SafeCStr expected) {
	foreach (Pos pos; start .. end)
		checkHover(test, hoverTest, pos, expected);
}

@trusted void testBasic(ref Test test) {
	SafeCStr content = safeCStr!`
nat builtin

r record
	fld nat
`;
	HoverTest a = initHoverTest(test, content);

	checkHover(test, a, 0, safeCStr!"");
	checkHoverRange(test, a, 1, 11, safeCStr!"builtin type nat");
	checkHoverRange(test, a, 12, 13, safeCStr!"");
	Pos rStart = 14;
	verify(content.ptr[rStart] == 'r');
	Pos fldStart = rStart + 10;
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

	checkHover(test, a, 0, safeCStr!"function f");
	checkHoverRange(test, a, 1, 5, safeCStr!"TODO: hover for type");
	checkHover(test, a, 6, safeCStr!"parameter a");
	checkHoverRange(test, a, 7, 10, safeCStr!"TODO: hover for type");
	checkHoverRange(test, a, 11, 13, safeCStr!"");
	checkHover(test, a, 13, safeCStr!"parameter b");
	checkHoverRange(test, a, 15, 18, safeCStr!"TODO: hover for type");

	//TODO: hover in function body
}

void verifyStrEq(Pos pos, in SafeCStr actual, in SafeCStr expected) {
	if (!safeCStrEq(actual, expected)) {
		debug {
			import core.stdc.stdio : printf;
			printf("at position %d:\nactual: %s\nexpected: %s\n", pos, actual.ptr, expected.ptr);
		}
		verifyFail();
	}
}
