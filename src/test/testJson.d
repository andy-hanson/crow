module test.testJson;

@safe @nogc pure nothrow:

import test.testUtil : Test;
import util.col.str : SafeCStr, safeCStr;
import util.jsonParse : Json, parseJson;
import util.opt : force, has, Opt;
import util.sym : AllSymbols, sym, writeQuotedSym;
import util.util : debugLog, typeAs, verify, verifyFail;
import util.writer : finishWriterToSafeCStr, Writer, writeWithCommas;

void testJson(ref Test test) {
	testBoolean(test);
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

void testString(ref Test test) {
	verifyParseJson(test, safeCStr!"\"\"", Json(safeCStr!""));
	verifyParseJson(test, safeCStr!"\"abc\"", Json(safeCStr!"abc"));
	verifyParseJson(test, safeCStr!"\"a\\nb\"", Json(safeCStr!"a\\nb"));
}

@trusted void testArray(ref Test test) {
	verifyParseJson(test, safeCStr!"[ ]", Json(typeAs!(Json.List)([])));
	scope Json[1] valuesA = [Json(false)];
	verifyParseJson(test, safeCStr!"[ false , ]", Json(valuesA));
	scope Json[4] valuesB = [
		Json(true),
		Json(safeCStr!"foo"),
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
	verify(!has(actual));
}

void verifyParseJson(ref Test test, in SafeCStr source, in Json expected) {
	Opt!Json actual = parseJson(test.alloc, test.allSymbols, source);
	verify(has(actual));
	if (force(actual) != expected) {
		Writer writer = test.writer;
		writer ~= "actual: ";
		writeJson(writer, test.allSymbols, force(actual));
		writer ~= "\nexpected: ";
		writeJson(writer, test.allSymbols, expected);
		debugLog(finishWriterToSafeCStr(writer).ptr);
		verifyFail();
	}
}

void writeJson(scope ref Writer writer, in AllSymbols allSymbols, in Json a) {
	a.matchIn!void(
		(bool x) {
			writer ~= x ? "true" : "false";
		},
		(in SafeCStr x) {
			writer ~= x;
		},
		(in Json.List x) {
			writer ~= '[';
			writeWithCommas!Json(writer, x, (in Json y) {
				writeJson(writer, allSymbols, y);
			});
			writer ~= ']';
		},
		(in Json.Object x) {
			writer ~= '{';
			writeWithCommas!(Json.ObjectField)(writer, x, (in Json.ObjectField y) {
				writeQuotedSym(writer, allSymbols, y.key);
				writer ~= ':';
				writeJson(writer, allSymbols, y.value);
			});
		});
}
