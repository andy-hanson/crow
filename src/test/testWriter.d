module test.testWriter;

@safe @nogc pure nothrow:

import test.testUtil : Test;
import util.string : stringsEqual;
import util.writer : makeStringWithWriter, writeFloatLiteral, Writer;

@trusted void testWriter(ref Test test) {
	void writes(double value, string expected) {
		string actual = makeStringWithWriter(test.alloc, (scope ref Writer writer) {
			writeFloatLiteral(writer, value);
		});
		assert(stringsEqual(actual, expected));
	}

	writes(-0.0, "-0");
	writes(0.0, "0");
	writes(123, "123");
	writes(-123, "-123");
	writes(1.2, "1.2");
	writes(-1.2, "-1.2");
	writes(1.23, "0x1.3ae147ae147aep0");
	writes(-1.23, "-0x1.3ae147ae147aep0");
	writes(0.75, "0x1.8000000000000p-1");
	writes(0.001, "0x1.624dd2f1a9fcp-10");
}
