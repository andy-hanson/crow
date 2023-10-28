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
import util.col.arr : only;
import util.col.arrBuilder : add, ArrBuilder, finishArr;
import util.col.str : end, SafeCStr, safeCStr, safeCStrEq, safeCStrIsEmpty, safeCStrSize, strOfSafeCStr;
import util.conv : safeToUint;
import util.json : field, Json, jsonList, jsonObject, jsonToStringPretty, optionalField;
import util.lineAndColumnGetter : LineAndColumn, lineAndColumnAtPos, PosKind;
import util.opt : has, none, Opt, optEqual;
import util.uri : AllUris, emptyUrisInfo, parseUri, Uri;
import util.perf : Perf, withNullPerf;
import util.storage : allocateToStorage, ReadFileResult, Storage, setFile;
import util.sourceRange : Pos;
import util.sym : AllSymbols;
import util.util : debugLog, verifyFail;

@trusted void testHover(ref Test test) {
	hoverTest!("basic.crow", "hover/basic.json")(test);
	hoverTest!("function.crow", "hover/function.json")(test);
}

private:

void hoverTest(string crowFileName, string outputFileName)(ref Test test) {
	SafeCStr content = safeCStr!(import("hover/" ~ crowFileName));
	string expected = import(outputFileName);
	HoverTest hoverTest = initHoverTest!crowFileName(test, content);
	SafeCStr actual = jsonToStringPretty(
		test.alloc,
		test.allSymbols,
		hoverResult(test.alloc, test.allSymbols, test.allUris, content, hoverTest));
	if (strOfSafeCStr(actual) != expected) {
		debugLog("Test output was not as expected. File is:");
		debugLog(outputFileName);
		debugLog("Actual is:");
		debugLog(actual.ptr);
		verifyFail();
	}
}

immutable struct HoverTest {
	Program program;
	Module* mainModule;
}

HoverTest initHoverTest(string fileName)(ref Test test, in SafeCStr content) {
	Uri uri = parseUri(test.allUris, "magic:" ~ fileName);
	Storage storage = Storage(test.allocPtr);
	setFile(storage, uri, ReadFileResult(allocateToStorage(storage, content)));
	Program program = withNullPerf!(Program, (ref Perf perf) =>
		frontendCompile(
			test.alloc, perf, test.alloc, test.allSymbols, test.allUris, storage,
			parseUri(test.allUris, "magic:include"), [uri], none!Uri));
	return HoverTest(program, only(program.rootModules));
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
	in AllUris allUris,
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
					jsonOfDefinition(alloc, allUris, x)),
			]));
		}
	}

	Pos endOfFile = safeToUint(safeCStrSize(content));
	foreach (Pos pos; 0 .. endOfFile + 1) {
		Position position = getPosition(allSymbols, a.mainModule, pos);
		InfoAtPos here = InfoAtPos(
			getHoverStr(alloc, alloc, allSymbols, allUris, emptyUrisInfo, a.program, position),
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
