module test.testHover;

@safe @nogc nothrow: // not pure

import frontend.frontendCompile : frontendCompile;
import frontend.ide.getDefinition : Definition, getDefinitionForPosition, jsonOfDefinition;
import frontend.ide.getHover : getHoverStr;
import frontend.ide.getPosition : getPosition, Position;
import model.model : Module, Program;
import test.testUtil : Test;
import util.alloc.alloc : Alloc;
import util.cell : Cell, cellGet, cellSet;
import util.col.arrBuilder : add, ArrBuilder, finishArr;
import util.col.mutMap : addToMutMap;
import util.col.str : end, SafeCStr, safeCStr, safeCStrEq, safeCStrIsEmpty, safeCStrSize, strOfSafeCStr;
import util.conv : safeToUint;
import util.json : field, Json, jsonList, jsonObject, jsonToStringPretty, optionalField;
import util.lineAndColumnGetter : LineAndColumn, lineAndColumnAtPos, PosKind;
import util.memoryReadOnlyStorage : withMemoryReadOnlyStorage, MutFiles;
import util.opt : force, has, none, Opt, optEqual, some;
import util.path : AllPaths, emptyPathsInfo, Path, rootPath;
import util.perf : Perf, withNullPerf;
import util.readOnlyStorage : ReadOnlyStorage;
import util.sourceRange : Pos;
import util.sym : AllSymbols, sym;
import util.util : debugLog, verify, verifyFail;

@trusted void testHover(ref Test test) {
	hoverTest!("hover/basic.crow", "hover/basic.json")(test);
	hoverTest!("hover/function.crow", "hover/function.json")(test);
}

private:

void hoverTest(string inputName, string fileName)(ref Test test) {
	SafeCStr content = safeCStr!(import(inputName));
	string expected = import(fileName);
	HoverTest hoverTest = initHoverTest(test, content);
	SafeCStr actual = jsonToStringPretty(
		test.alloc,
		test.allSymbols,
		hoverResult(test.alloc, test.allSymbols, test.allPaths, content, hoverTest));
	if (strOfSafeCStr(actual) != expected) {
		debugLog("Test output was not as expected. File is:");
		debugLog(fileName);
		debugLog("Actual is:");
		debugLog(actual.ptr);
		verifyFail();
	}
}

immutable struct HoverTest {
	Program program;
	Module* mainModule;
}

HoverTest initHoverTest(ref Test test, in SafeCStr content) {
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

immutable struct InfoAtPos {
	@safe @nogc pure nothrow:

	SafeCStr hover;
	Opt!Definition definition;

	bool isEmpty() =>
		safeCStrIsEmpty(hover) && !has(definition);

	bool opEquals(in InfoAtPos b) scope =>
		safeCStrEq(hover, b.hover) &&
			optEqual!Definition(definition, b.definition);
}

Json hoverResult(
	ref Alloc alloc,
	ref AllSymbols allSymbols,
	in AllPaths allPaths,
	in SafeCStr content,
	in HoverTest a,
) {
	ArrBuilder!Json parts;

	// We combine ranges that have the same info.
	Pos curRangeStart = 0;
	Cell!(InfoAtPos) curInfo = Cell!(InfoAtPos)(InfoAtPos(safeCStr!"", none!Definition));

	LineAndColumn lineAndColumnInFile(Pos pos, PosKind kind) {
		return lineAndColumnAtPos(a.program.filesInfo.lineAndColumnGetters[a.mainModule.fileIndex], pos, kind);
	}

	void endRange(Pos end) {
		InfoAtPos info = cellGet(curInfo);
		if (!info.isEmpty()) {
			add(alloc, parts, jsonObject(alloc, [
				field!"start"(jsonOfLineAndColumn(alloc, lineAndColumnInFile(curRangeStart, PosKind.startOfRange))),
				field!"end"(jsonOfLineAndColumn(alloc, lineAndColumnInFile(end, PosKind.endOfRange))),
				field!"hover"(info.hover),
				optionalField!("definition", Definition)(info.definition, (in Definition x) =>
					jsonOfDefinition(alloc, allPaths, x)),
			]));
		}
	}

	Pos endOfFile = safeToUint(safeCStrSize(content));
	foreach (Pos pos; 0 .. endOfFile + 1) {
		Position position = getPosition(allSymbols, a.mainModule, pos);
		InfoAtPos here = InfoAtPos(
			getHoverStr(alloc, alloc, allSymbols, allPaths, emptyPathsInfo, a.program, position),
			getDefinitionForPosition(a.program, position));
		if (here != cellGet(curInfo)) {
			endRange(pos);
			curRangeStart = pos;
			cellSet(curInfo, here);
		}
	}
	endRange(endOfFile);

	return jsonList(finishArr(alloc, parts));
}

Json jsonOfLineAndColumn(ref Alloc alloc, in LineAndColumn a) =>
	jsonObject(alloc, [
		field!"line"(a.line + 1),
		field!"column"(a.column + 1)]);
