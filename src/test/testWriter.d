module test.testWriter;

@safe @nogc pure nothrow:

import test.testUtil : Test;
import util.collection.str : strEqLiteral;
import util.util : verify;
import util.writer : finishWriter, writeFloatLiteral, Writer;

@trusted void testWriter(Debug, Alloc)(ref Test!(Debug, Alloc) test) {
	void writes(immutable double value, immutable string expected) {
		Writer!Alloc writer = Writer!Alloc(test.alloc);
		writeFloatLiteral(writer, value);
		immutable string res = finishWriter(writer);
		verify(strEqLiteral(res, expected));
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
}
