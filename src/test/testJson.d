module test.testJson;

@safe @nogc pure nothrow:

import test.testUtil : Test;
import util.json : Json;
import util.jsonParse : parseJson;
import util.opt : force, has, Opt;
import util.string : CString, cString;
import util.symbol : symbol;
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
	verifyParseError(test, cString!"falser");
	verifyParseJson(test, cString!" \r\nfalse\t", Json(false));
	verifyParseJson(test, cString!"true", Json(true));
}

void testNumber(ref Test test) {
	verifyParseJson(test, cString!"123", Json(123));
}

void testString(ref Test test) {
	verifyParseJson(test, cString!"\"\"", Json(""));
	verifyParseJson(test, cString!"\"abc\"", Json("abc"));
	verifyParseJson(test, cString!"\"a\\nb\"", Json("a\nb"));
}

@trusted void testArray(ref Test test) {
	verifyParseJson(test, cString!"[ ]", Json(typeAs!(Json.List)([])));
	scope Json[1] valuesA = [Json(false)];
	verifyParseJson(test, cString!"[ false , ]", Json(valuesA));
	scope Json[4] valuesB = [
		Json(true),
		Json("foo"),
		Json(valuesA),
		Json(typeAs!(Json.Object)([])),
	];
	verifyParseJson(test, cString!"[true, \"foo\", [false], {}]", Json(valuesB));
}

@trusted void testObject(ref Test test) {
	verifyParseJson(test, cString!"{ }", Json(typeAs!(Json.Object)([])));
	scope Json.ObjectField[1] fieldsA = [Json.ObjectField(symbol!"x", Json(false))];
	verifyParseJson(test, cString!"{ \"x\": false }", Json(fieldsA));
	scope Json[1] values = [Json(true)];
	scope Json.ObjectField[2] fieldsB = [
		Json.ObjectField(symbol!"a", Json(fieldsA)),
		Json.ObjectField(symbol!"b", Json(values)),
	];
	verifyParseJson(test, cString!"{\"a\":{\"x\":false}, \"b\":[true]}", Json(fieldsB));
}

void verifyParseError(ref Test test, in CString source) {
	Opt!Json actual = parseJson(test.alloc, source);
	assert(!has(actual));
}

void verifyParseJson(ref Test test, in CString source, in Json expected) {
	Opt!Json actual = parseJson(test.alloc, source);
	assert(has(actual));
	if (force(actual) != expected) {
		debugLogWithWriter((ref Writer writer) {
			writer ~= "actual: ";
			writer ~= force(actual);
			writer ~= "\nexpected: ";
			writer ~= expected;
		});
		assert(false);
	}
}
