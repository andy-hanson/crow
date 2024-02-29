module test.testUnicode;

@safe @nogc pure nothrow:

import test.testUtil : Test;
import util.col.arrayBuilder : buildArray, Builder;
import util.opt : force, Opt;
import util.string : CString, cString, CStringAndLength, stringOfCString;
import util.unicode : FileContent, unicodeDecodeAssertNoError, mustUnicodeEncode, unicodeValidate;

void testUnicode(ref Test test) {
	assertUnicode(test, cString!"$¥₿𝄮", 10, "$¥₿𝄮", 4);
	assertUnicode(test, cString!"𝄮₿¥$", 10, "𝄮₿¥$", 4);
	assertUnicode(test, cString!"\ue000", 3, "\ue000", 1);
}

private:

void assertUnicode(ref Test test, in CString cString, size_t expectedChar8s, in dchar[] utf32, size_t expectedChar32s) {
	string utf8 = stringOfCString(cString);
	assert(utf8.length == expectedChar8s);
	assert(utf32.length == expectedChar32s);

	Opt!CStringAndLength uni = unicodeValidate(FileContent(CStringAndLength(cString)));
	assert(force(uni).cString == cString && force(uni).length == utf8.length);

	size_t i = 0;
	unicodeDecodeAssertNoError(utf8, (dchar x) {
		assert(x == utf32[i]);
		i++;
	});
	assert(i == utf32.length);

	string encoded = buildArray!(immutable char)(test.alloc, (scope ref Builder!(immutable char) out_) {
		mustUnicodeEncode(out_, utf32);
	});
	assert(encoded == utf8);
}
