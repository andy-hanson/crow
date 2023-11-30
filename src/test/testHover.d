module test.testHover;

@safe @nogc pure nothrow:

import frontend.ide.getDefinition : getDefinitionForPosition;
import frontend.ide.getHover : getHover;
import frontend.ide.getPosition : getPosition;
import frontend.ide.position : Position;
import frontend.lang : crowExtension;
import frontend.showModel : ShowCtx;
import frontend.storage : FileContent, jsonOfUriAndRange, ReadFileResult, setFile;
import lib.lsp.lspTypes : Hover;
import lib.server : allUnknownUris, getProgramForAll, getShowDiagCtx, Server, setFile;
import model.diag : ReadFileDiag;
import model.model : Module, Program;
import test.testUtil : Test, withTestServer;
import util.alloc.alloc : Alloc;
import util.cell : Cell, cellGet, cellSet;
import util.col.arr : empty;
import util.col.arrBuilder : add, ArrBuilder, finishArr;
import util.col.arrUtil : arrEqual;
import util.col.map : mustGetAt;
import util.col.str : SafeCStr, safeCStr, safeCStrEq, safeCStrIsEmpty, safeCStrSize, strOfSafeCStr;
import util.conv : safeToUint;
import util.json : field, Json, jsonList, jsonObject, jsonToStringPretty, optionalArrayField;
import util.lineAndColumnGetter : LineAndColumnGetter, PosKind;
import util.opt : force, has, Opt;
import util.uri : getExtension, parseUri, Uri;
import util.sourceRange : jsonOfPosWithinFile, Pos, UriAndRange;
import util.util : debugLog;

@trusted void testHover(ref Test test) {
	hoverTest!("basic.crow", "hover/basic.json")(test);
	hoverTest!("function.crow", "hover/function.json")(test);
}

private:

void hoverTest(string crowFileName, string outputFileName)(ref Test test) {
	SafeCStr content = safeCStr!(import("hover/" ~ crowFileName));
	string expected = import(outputFileName);
	withHoverTest!crowFileName(test, content, (in ShowCtx ctx, Module* module_) {
		SafeCStr actual = jsonToStringPretty(
			test.alloc, test.allSymbols, hoverResult(test.alloc, content, ctx, module_));
		if (strOfSafeCStr(actual) != expected) {
			debugLog("Test output was not as expected. File is:");
			debugLog(outputFileName);
			debugLog("Actual is:");
			debugLog(actual.ptr);
			assert(false);
		}
	});
}

SafeCStr bootstrapContent = SafeCStr(import("crow/private/bootstrap.crow"));

void withHoverTest(string fileName)(
	ref Test test,
	in SafeCStr content,
	in void delegate(in ShowCtx, Module*) @safe @nogc pure nothrow cb,
) {
	withTestServer(test, (ref Alloc alloc, ref Server server) {
		Uri uri = parseUri(server.allUris, "magic:/" ~ fileName);
		assert(getExtension(server.allUris, uri) == crowExtension);
		setFile(test.perf, server, uri, ReadFileResult(FileContent(content)));
		while (true) {
			Uri[] unknowns = allUnknownUris(alloc, server);
			if (empty(unknowns))
				break;
			else
				foreach (Uri unknown; unknowns)
					setFile(
						test.perf, server, unknown,
						unknown == parseUri(server.allUris, "test:///include/crow/private/bootstrap.crow")
							? ReadFileResult(FileContent(bootstrapContent))
							: ReadFileResult(ReadFileDiag.notFound));
		}

		Program program = getProgramForAll(alloc, server);
		cb(getShowDiagCtx(server, program), mustGetAt(program.allModules, uri));
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

Json hoverResult(ref Alloc alloc, in SafeCStr content, in ShowCtx ctx, Module* mainModule) {
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
		Opt!Hover hover = getHover(alloc, ctx, position);
		InfoAtPos here = InfoAtPos(
			has(hover) ? force(hover).contents.value : safeCStr!"",
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
