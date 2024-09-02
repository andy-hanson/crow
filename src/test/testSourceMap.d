module test.testSourceMap;

@safe @nogc pure nothrow:

import backend.js.sourceMap : finish, SingleSourceMapping, Source, SourceMapBuilder;
import test.testUtil : assertEqual, Test;
import util.sourceRange : LineAndColumn;
import util.symbol : symbol;
import util.uri : mustParseUri;

void testSourceMap(ref Test test) {
	SourceMapBuilder map = SourceMapBuilder(test.allocPtr);
	map ~= SingleSourceMapping(
		Source(mustParseUri("file://a.crow"), symbol!"foo", LineAndColumn(1, 1)),
		LineAndColumn(1, 1));
	assertEqual(finish(map), q"({"version":3,"sources":["file://a.crow"],"names":["foo"],"mappings":";CACCA"})");
}
