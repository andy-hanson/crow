module test.testWriter;

@safe @nogc pure nothrow:

import test.testUtil : Test;
import util.col.str : strEq;
import util.util : verify;
import util.writer : finishWriter, writeFloatLiteral, Writer;

@trusted void testWriter(ref Test test) {
	void writes(double value, string expected) {
		Writer writer = Writer(test.allocPtr);
		writeFloatLiteral(writer, value);
		string res = finishWriter(writer);
		verify(strEq(res, expected));
	}

	writes(-0.0, "-0.0");
	writes(0.0, "0.0");
	writes(123, "123.0");
	writes(-123, "-123.0");
	writes(1.2, "1.2");
	writes(-1.2, "-1.2");
	writes(1.23, "0x1.3ae147ae147aep0");
	writes(-1.23, "-0x1.3ae147ae147aep0");
	writes(0.75, "0x1.8000000000000p-1");
	writes(0.001, "0x1.624dd2f1a9fcp-10");
}
