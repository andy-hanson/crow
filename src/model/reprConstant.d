module model.reprConstant;

@safe @nogc pure nothrow:

import model.concreteModel : name;
import model.constant : Constant, matchConstant;
import util.alloc.alloc : Alloc;
import util.sym : Sym;
import util.repr : Repr, reprArr, reprBool, reprFloat, reprNat, reprOpt, reprRecord, reprSym;

immutable(Repr) reprOfConstant(ref Alloc alloc, ref immutable Constant a) {
	return matchConstant!(immutable Repr)(
		a,
		(ref immutable Constant.ArrConstant it) =>
			reprRecord(alloc, "arr", [reprNat(it.typeIndex), reprNat(it.index)]),
		(immutable Constant.BoolConstant it) =>
			reprBool(it.value),
		(ref immutable Constant.CString it) =>
			reprRecord(alloc, "c-str", [reprNat(it.index)]),
		(immutable double it) =>
			reprFloat(it),
		(immutable Constant.FunPtr it) =>
			reprRecord(alloc, "fun-ptr", [
				reprOpt(alloc, name(it.fun), (ref immutable Sym name) => reprSym(name))]),
		(immutable Constant.Integral it) =>
			reprNat(it.value),
		(immutable Constant.Null) =>
			reprSym("null"),
		(immutable Constant.Pointer it) =>
			reprRecord(alloc, "pointer", [reprNat(it.typeIndex), reprNat(it.index)]),
		(ref immutable Constant.Record it) =>
			reprRecord(alloc, "record", [reprArr(alloc, it.args, (ref immutable Constant arg) =>
				reprOfConstant(alloc, arg))]),
		(ref immutable Constant.Union it) =>
			reprRecord(alloc, "union", [reprNat(it.memberIndex), reprOfConstant(alloc, it.arg)]),
		(immutable Constant.Void) =>
			reprSym("void"));
}
