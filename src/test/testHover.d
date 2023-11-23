module test.testHover;

@safe @nogc pure nothrow:

import frontend.frontendCompile : frontendCompile;
import frontend.ide.getDefinition : getDefinitionForPosition;
import frontend.ide.getHover : getHoverStr;
import frontend.ide.getPosition : getPosition;
import frontend.ide.position : Position;
import frontend.showModel : ShowCtx;
import model.model : Module, Program;
import test.testUtil : Test, withShowDiagCtxForTest;
import util.alloc.alloc : Alloc;
import util.cell : Cell, cellGet, cellSet;
import util.col.arr : empty, only;
import util.col.arrBuilder : add, ArrBuilder, finishArr;
import util.col.arrUtil : arrEqual;
import util.col.str : end, SafeCStr, safeCStr, safeCStrEq, safeCStrIsEmpty, safeCStrSize, strOfSafeCStr;
import util.conv : safeToUint;
import util.json : field, Json, jsonList, jsonObject, jsonToStringPretty, optionalArrayField;
import util.lineAndColumnGetter : LineAndColumnGetter, PosKind;
import util.opt : none;
import util.uri : parseUri, Uri;
import util.perf : Perf, withNullPerf;
import util.storage : FileContent, ReadFileResult, Storage, setFile;
import util.sourceRange : jsonOfPosWithinFile, jsonOfUriAndRange, Pos, UriAndRange;
import util.util : debugLog, verifyFail;

@trusted void testHover(ref Test test) {
	hoverTest!("basic.crow", "hover/basic.json")(test);
	hoverTest!("function.crow", "hover/function.json")(test);
}

private:

void hoverTest(string crowFileName, string outputFileName)(ref Test test) {
	SafeCStr content = safeCStr!(import("hover/" ~ crowFileName));
	string expected = import(outputFileName);
	withHoverTest!crowFileName(test, content, (ref ShowCtx ctx, Module* module_) {
		SafeCStr actual = jsonToStringPretty(
			test.alloc, test.allSymbols, hoverResult(test.alloc, content, ctx, module_));
		if (strOfSafeCStr(actual) != expected) {
			debugLog("Test output was not as expected. File is:");
			debugLog(outputFileName);
			debugLog("Actual is:");
			debugLog(actual.ptr);
			verifyFail();
		}
	});
}

void withHoverTest(string fileName)(
	ref Test test,
	in SafeCStr content,
	in void delegate(ref ShowCtx, Module*) @safe @nogc pure nothrow cb,
) {
	Uri uri = parseUri(test.allUris, "magic:" ~ fileName);
	Storage storage = Storage(test.metaAlloc);
	setFile(storage, uri, ReadFileResult(FileContent(content)));
	Program program = withNullPerf!(Program, (ref Perf perf) =>
		frontendCompile(
			test.alloc, perf, test.alloc, test.allSymbols, test.allUris, storage,
			parseUri(test.allUris, "magic:include"), [uri], none!Uri));
	withShowDiagCtxForTest(test, storage, program, (ref ShowCtx ctx) {
		cb(ctx, only(program.rootModules));
	});
}

immutable struct InfoAtPos {
	@safe @nogc pure nothrow:

	SafeCStr hover;
	UriAndRange[] definition;

	bool isEmpty() scope =>
		safeCStrIsEmpty(hover) && empty(definition);

	bool opEquals(in InfoAtPos b) scope =>
		safeCStrEq(hover, b.hover) && arrEqual(definition, b.definition);
}

Json hoverResult(ref Alloc alloc, in SafeCStr content, ref ShowCtx ctx, Module* mainModule) {
	ArrBuilder!Json parts;

	// We combine ranges that have the same info.
	Pos curRangeStart = 0;
	Cell!(InfoAtPos) curInfo = Cell!(InfoAtPos)(InfoAtPos(safeCStr!"", []));

	LineAndColumnGetter lcg = ctx.lineAndColumnGetters[mainModule.uri];

	void endRange(Pos end) {
		InfoAtPos info = cellGet(curInfo);
		if (!info.isEmpty()) {
			add(alloc, parts, jsonObject(alloc, [
				field!"start"(jsonOfPosWithinFile(alloc, lcg, curRangeStart, PosKind.startOfRange)),
				field!"end"(jsonOfPosWithinFile(alloc, lcg, end, PosKind.endOfRange)),
				field!"hover"(info.hover),
				optionalArrayField!("definition", UriAndRange)(alloc, info.definition, (in UriAndRange x) =>
					jsonOfUriAndRange(alloc, ctx.allUris, ctx.lineAndColumnGetters, x)),
			]));
		}
	}

	Pos endOfFile = safeToUint(safeCStrSize(content));
	foreach (Pos pos; 0 .. endOfFile + 1) {
		Position position = getPosition(ctx.allSymbols, ctx.allUris, mainModule, pos);
		InfoAtPos here = InfoAtPos(
			getHoverStr(alloc, ctx, position),
			getDefinitionForPosition(alloc, ctx.allSymbols, ctx.program, position));
		if (here != cellGet(curInfo)) {
			endRange(pos - 1);
			curRangeStart = pos;
			cellSet(curInfo, here);
		}
	}
	endRange(endOfFile);

	return jsonList(finishArr(alloc, parts));
}
