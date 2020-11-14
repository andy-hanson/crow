module model.sexprOfConstant;

@safe @nogc pure nothrow:

import model.constant : Constant, matchConstant;
import util.sexpr : Sexpr, tataArr, tataBool, tataNat, tataRecord, tataSym;

immutable(Sexpr) tataOfConstant(Alloc)(ref Alloc alloc, ref immutable Constant a) {
	return matchConstant!(immutable Sexpr)(
		a,
		(ref immutable Constant.ArrConstant it) =>
			tataRecord(alloc, "arr", tataNat(it.size), tataNat(it.index)),
		(immutable Constant.BoolConstant it) =>
			tataBool(it.value),
		(immutable Constant.Integral it) =>
			tataNat(it.value),
		(immutable Constant.Null) =>
			tataSym("null"),
		(immutable Constant.Pointer it) =>
			tataRecord(alloc, "pointer", tataNat(it.index)),
		(ref immutable Constant.Record it) =>
			tataRecord(alloc, "record", tataArr(alloc, it.args, (ref immutable Constant arg) =>
				tataOfConstant(alloc, arg))),
		(ref immutable Constant.Union it) =>
			tataRecord(alloc, "union", tataNat(it.memberIndex), tataOfConstant(alloc, it.arg)),
		(immutable Constant.Void) =>
			tataSym("void"));
}
