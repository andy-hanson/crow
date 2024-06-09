module test.testWriter;

@safe @nogc pure nothrow:

import test.testUtil : assertEqual, Test;
import util.writer : withStackWriter, writeFloatLiteral, Writer;

void testWriter(ref Test test) {
	void writes(double value, string expected) {
		withStackWriter!0x1000(
			(scope ref Writer writer) {
				writeFloatLiteral(writer, value);
			},
			(in string actual) {
				assertEqual(actual, expected);
			});
	}

	writes(double.nan, "NAN");
	writes(double.infinity, "INFINITY");
	writes(-double.infinity, "-INFINITY");
	writes(-0.0, "-0");
	writes(0.0, "0");
	writes(123, "123");
	writes(-123, "-123");
	writes(1.2, "1.2");
	writes(-1.2, "-1.2");
	writes(1.23, "0x1.3ae147ae147aep0");
	writes(-1.23, "-0x1.3ae147ae147aep0");
	writes(0.75, "0x1.8000000000000p-1");
	writes(0.001, "0x1.0624dd2f1a9fcp-10");
}
