module sexprOfLowModel;

@safe @nogc pure nothrow:

import lowModel :
	LowProgram;
import util.sexpr : Sexpr, tataSym;
import util.util : todo;

immutable(Sexpr) tataOfLowProgram(Alloc)(ref Alloc alloc, ref immutable LowProgram a) {
	return tataSym("todo");
}
