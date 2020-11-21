module test.testDebug;

@safe @nogc nothrow: // not pure

import test.testUtil : Test;
import util.collection.arr : at, size;
import util.collection.str : Str, strEqLiteral;
//import util.util : debugLog, debugLogSize, getDebugLog, resetDebugLog, verify;

void testDebug(Alloc)(ref Test!Alloc test) {
	/*
	verify(strEqLiteral(getDebugLog(test.alloc), ""));
	debugLog("abc");
	verify(strEqLiteral(getDebugLog(test.alloc), "abc"));
	resetDebugLog();
	verify(strEqLiteral(getDebugLog(test.alloc), ""));

	foreach (immutable size_t i; 0..3)
		debugLog("a");
	foreach (immutable size_t i; 0..debugLogSize())
		debugLog("b");
	foreach (immutable size_t i; 0..3)
		debugLog("c");
	immutable Str actual = getDebugLog(test.alloc);
	verify(size(actual) == debugLogSize());

	foreach (immutable size_t i; 0..debugLogSize() - 3)
		verify(at(actual, i) == 'b');
	foreach (immutable size_t i; 0..3)
		verify(at(actual, debugLogSize() - 3 + i) == 'c');
	*/
}
