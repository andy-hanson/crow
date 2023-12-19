module test.testHover;

@safe @nogc pure nothrow:

import frontend.ide.getDefinition : getDefinitionForPosition;
import frontend.ide.getHover : getHover;
import frontend.ide.getPosition : getPosition;
import frontend.ide.position : Position;
import frontend.showModel : ShowCtx;
import lib.lsp.lspTypes : Hover;
import lib.server : getProgramForAll, getShowDiagCtx, Server;
import model.model : Module, Program;
import test.testUtil : setupTestServer, Test, withTestServer;
import util.alloc.alloc : Alloc;
import util.cell : Cell, cellGet, cellSet;
import util.col.array : arraysEqual, isEmpty;
import util.col.arrayBuilder : add, ArrayBuilder, finish;
import util.col.hashTable : mustGet;
import util.conv : safeToUint;
import util.json : field, Json, jsonList, jsonObject, jsonToStringPretty, optionalArrayField;
import util.opt : force, has, Opt;
import util.uri : parseUri, Uri;
import util.sourceRange :
	jsonOfLineAndCharacterRange, jsonOfUriAndLineAndCharacterRange, LineAndCharacterGetter, Pos, Range, UriAndRange;
import util.string : CString, cString, cStringIsEmpty, stringOfCString;
import util.util : debugLog;

@trusted void testHover(ref Test test) {
	hoverTest!("basic.crow", "hover/basic.json")(test);
	hoverTest!("function.crow", "hover/function.json")(test);
}

private:

void hoverTest(string crowFileName, string outputFileName)(ref Test test) {
	string content = import("hover/" ~ crowFileName);
	string expected = import(outputFileName);
	withHoverTest!crowFileName(test, content, (in ShowCtx ctx, Module* module_) {
		CString actual = jsonToStringPretty(
			test.alloc, test.allSymbols, hoverResult(test.alloc, content, ctx, module_));
		if (stringOfCString(actual) != expected) {
			debugLog("Test output was not as expected. File is:");
			debugLog(outputFileName);
			debugLog("Actual is:");
			debugLog(actual.ptr);
			assert(false);
		}
	});
}

void withHoverTest(string fileName)(
	ref Test test,
	in string content,
	in void delegate(in ShowCtx, Module*) @safe @nogc pure nothrow cb,
) {
	withTestServer(test, (ref Alloc alloc, ref Server server) {
		Uri uri = parseUri(server.allUris, "magic:/" ~ fileName);
		setupTestServer(test, alloc, server, uri, content);
		Program program = getProgramForAll(test.perf, alloc, server);
		cb(getShowDiagCtx(server, program), mustGet(program.allModules, uri));
	});
}

immutable struct InfoAtPos {
	@safe @nogc pure nothrow:

	CString hover;
	UriAndRange[] definition;

	bool isEmpty() scope =>
		cStringIsEmpty(hover) && .isEmpty(definition);

	bool opEquals(in InfoAtPos b) scope =>
		hover == b.hover && arraysEqual(definition, b.definition);
}

Json hoverResult(ref Alloc alloc, in string content, in ShowCtx ctx, Module* mainModule) {
	ArrayBuilder!Json parts;

	// We combine ranges that have the same info.
	Pos curRangeStart = 0;
	Cell!(InfoAtPos) curInfo = Cell!(InfoAtPos)(InfoAtPos(cString!"", []));

	LineAndCharacterGetter lcg = ctx.lineAndCharacterGetters[mainModule.uri];

	void endRange(Pos end) {
		InfoAtPos info = cellGet(curInfo);
		if (!info.isEmpty) {
			add(alloc, parts, jsonObject(alloc, [
				field!"range"(jsonOfLineAndCharacterRange(alloc, lcg[Range(curRangeStart, end)])),
				field!"hover"(info.hover),
				optionalArrayField!("definition", UriAndRange)(alloc, info.definition, (in UriAndRange x) =>
					jsonOfUriAndLineAndCharacterRange(alloc, ctx.allUris, ctx.lineAndCharacterGetters[x])),
			]));
		}
	}

	Pos endOfFile = safeToUint(content.length);
	foreach (Pos pos; 0 .. endOfFile + 1) {
		Position position = getPosition(ctx.allSymbols, ctx.allUris, mainModule, pos);
		Opt!Hover hover = getHover(alloc, ctx, position);
		InfoAtPos here = InfoAtPos(
			has(hover) ? force(hover).contents.value : cString!"",
			getDefinitionForPosition(alloc, ctx.allSymbols, ctx.program, position));
		if (here != cellGet(curInfo)) {
			endRange(pos - 1);
			curRangeStart = pos;
			cellSet(curInfo, here);
		}
	}
	endRange(endOfFile);

	return jsonList(finish(alloc, parts));
}
