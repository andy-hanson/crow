module test.testJson;

@safe @nogc pure nothrow:

import test.testUtil : Test;
import util.col.str : SafeCStr, safeCStr;
import util.json : Json, writeJson;
import util.jsonParse : parseJson;
import util.opt : force, has, Opt;
import util.sym : sym;
import util.util : typeAs;
import util.writer : debugLogWithWriter, Writer;

void testJson(ref Test test) {
	testBoolean(test);
	testNumber(test);
	testString(test);
	testObject(test);
	testArray(test);
}

private:

void testBoolean(ref Test test) {
	verifyParseError(test, safeCStr!"falser");
	verifyParseJson(test, safeCStr!" \r\nfalse\t", Json(false));
	verifyParseJson(test, safeCStr!"true", Json(true));
}

void testNumber(ref Test test) {
	verifyParseJson(test, safeCStr!"123", Json(123));
}

void testString(ref Test test) {
	verifyParseJson(test, safeCStr!"\"\"", Json(""));
	verifyParseJson(test, safeCStr!"\"abc\"", Json("abc"));
	verifyParseJson(test, safeCStr!"\"a\\nb\"", Json("a\nb"));
}

@trusted void testArray(ref Test test) {
	verifyParseJson(test, safeCStr!"[ ]", Json(typeAs!(Json.List)([])));
	scope Json[1] valuesA = [Json(false)];
	verifyParseJson(test, safeCStr!"[ false , ]", Json(valuesA));
	scope Json[4] valuesB = [
		Json(true),
		Json("foo"),
		Json(valuesA),
		Json(typeAs!(Json.Object)([])),
	];
	verifyParseJson(test, safeCStr!"[true, \"foo\", [false], {}]", Json(valuesB));
}

@trusted void testObject(ref Test test) {
	verifyParseJson(test, safeCStr!"{ }", Json(typeAs!(Json.Object)([])));
	scope Json.ObjectField[1] fieldsA = [Json.ObjectField(sym!"x", Json(false))];
	verifyParseJson(test, safeCStr!"{ \"x\": false }", Json(fieldsA));
	scope Json[1] values = [Json(true)];
	scope Json.ObjectField[2] fieldsB = [
		Json.ObjectField(sym!"a", Json(fieldsA)),
		Json.ObjectField(sym!"b", Json(values)),
	];
	verifyParseJson(test, safeCStr!"{\"a\":{\"x\":false}, \"b\":[true]}", Json(fieldsB));
}

void verifyParseError(ref Test test, in SafeCStr source) {
	Opt!Json actual = parseJson(test.alloc, test.allSymbols, source);
	assert(!has(actual));
}

void verifyParseJson(ref Test test, in SafeCStr source, in Json expected) {
	Opt!Json actual = parseJson(test.alloc, test.allSymbols, source);
	assert(has(actual));
	if (force(actual) != expected) {
		debugLogWithWriter((ref Writer writer) {
			writer ~= "actual: ";
			writeJson(writer, test.allSymbols, force(actual));
			writer ~= "\nexpected: ";
			writeJson(writer, test.allSymbols, expected);
		});
		assert(false);
	}
}
