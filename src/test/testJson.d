module test.testJson;

@safe @nogc pure nothrow:

import test.testUtil : Test;
import util.col.dict : KeyValuePair;
import util.col.str : SafeCStr, safeCStr;
import util.jsonParse : Json, jsonEqual, matchJson, parseJson;
import util.opt : force, has, Opt;
import util.sym : AllSymbols, shortSym, Sym, writeQuotedSym;
import util.util : as, debugLog, verify, verifyFail;
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
	verifyParseJson(test, safeCStr!" \r\nfalse\t", immutable Json(false));
	verifyParseJson(test, safeCStr!"true", immutable Json(true));
}

void testString(ref Test test) {
	verifyParseJson(test, safeCStr!"\"\"", immutable Json(safeCStr!""));
	verifyParseJson(test, safeCStr!"\"abc\"", immutable Json(safeCStr!"abc"));
	verifyParseJson(test, safeCStr!"\"a\\nb\"", immutable Json(safeCStr!"a\\nb"));
}

@trusted void testArray(ref Test test) {
	verifyParseJson(test, safeCStr!"[ ]", immutable Json(as!(immutable Json[])([])));
	scope immutable Json[1] valuesA = [immutable Json(false)];
	verifyParseJson(test, safeCStr!"[ false , ]", immutable Json(valuesA));
	scope immutable Json[4] valuesB = [
		immutable Json(true),
		immutable Json(safeCStr!"foo"),
		immutable Json(valuesA),
		immutable Json(as!(immutable KeyValuePair!(Sym, Json)[])([])),
	];
	verifyParseJson(test, safeCStr!"[true, \"foo\", [false], {}]", immutable Json(valuesB));
}

@trusted void testObject(ref Test test) {
	verifyParseJson(test, safeCStr!"{ }", immutable Json(as!(immutable KeyValuePair!(Sym, Json)[])([])));
	scope immutable KeyValuePair!(Sym, Json)[1] fieldsA = [
		immutable KeyValuePair!(Sym, Json)(shortSym("x"), immutable Json(false)),
	];
	verifyParseJson(test, safeCStr!"{ \"x\": false }", immutable Json(fieldsA));
	scope immutable Json[1] values = [immutable Json(true)];
	scope immutable KeyValuePair!(Sym, Json)[2] fieldsB = [
		immutable KeyValuePair!(Sym, Json)(shortSym("a"), immutable Json(fieldsA)),
		immutable KeyValuePair!(Sym, Json)(shortSym("b"), immutable Json(values)),
	];
	verifyParseJson(test, safeCStr!"{\"a\":{\"x\":false}, \"b\":[true]}", immutable Json(fieldsB));
}

void verifyParseError(ref Test test, immutable SafeCStr source) {
	immutable Opt!Json actual = parseJson(test.alloc, test.allSymbols, source);
	verify(!has(actual));
}

void verifyParseJson(ref Test test, immutable SafeCStr source, scope immutable Json expected) {
	immutable Opt!Json actual = parseJson(test.alloc, test.allSymbols, source);
	verify(has(actual));
	if (!jsonEqual(force(actual), expected)) {
		Writer writer = test.writer;
		writer ~= "actual: ";
		writeJson(writer, test.allSymbols, force(actual));
		writer ~= "\nexpected: ";
		writeJson(writer, test.allSymbols, expected);
		debugLog(finishWriterToSafeCStr(writer).ptr);
		verifyFail();
	}
}

void writeJson(ref Writer writer, ref const AllSymbols allSymbols, scope immutable Json a) {
	matchJson!void(
		a,
		(immutable bool x) {
			writer ~= x ? "true" : "false";
		},
		(immutable SafeCStr x) {
			writer ~= x;
		},
		(immutable Json[] x) {
			writer ~= '[';
			writeWithCommas!Json(writer, x, (scope ref immutable Json y) {
				writeJson(writer, allSymbols, y);
			});
			writer ~= ']';
		},
		(immutable KeyValuePair!(Sym, Json)[] x) {
			writer ~= '{';
			writeWithCommas!(KeyValuePair!(Sym, Json))(writer, x, (scope ref immutable KeyValuePair!(Sym, Json) y) {
				writeQuotedSym(writer, allSymbols, y.key);
				writer ~= ':';
				writeJson(writer, allSymbols, y.value);
			});
		});
}
