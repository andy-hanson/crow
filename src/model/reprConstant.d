module model.reprConstant;

@safe @nogc pure nothrow:

import model.concreteModel : name;
import model.constant : Constant;
import util.alloc.alloc : Alloc;
import util.sym : Sym;
import util.repr : Repr, reprArr, reprFloat, reprNat, reprOpt, reprRecord, reprSym;

Repr reprOfConstant(ref Alloc alloc, in Constant a) =>
	a.matchIn!Repr(
		(in Constant.ArrConstant x) =>
			reprRecord!"arr"(alloc, [reprNat(x.typeIndex), reprNat(x.index)]),
		(in Constant.CString x) =>
			reprRecord!"c-string"(alloc, [reprNat(x.index)]),
		(in Constant.Float x) =>
			reprFloat(x.value),
		(in Constant.FunPtr x) =>
			reprRecord!"fun-pointer"(alloc, [
				reprOpt!Sym(alloc, name(*x.fun), (in Sym name) => reprSym(name))]),
		(in Constant.Integral x) =>
			reprNat(x.value),
		(in Constant.Pointer x) =>
			reprRecord!"pointer"(alloc, [reprNat(x.typeIndex), reprNat(x.index)]),
		(in Constant.Record x) =>
			reprRecord!"record"(alloc, [reprArr!Constant(alloc, x.args, (in Constant arg) =>
				reprOfConstant(alloc, arg))]),
		(in Constant.Union x) =>
			reprRecord!"union"(alloc, [reprNat(x.memberIndex), reprOfConstant(alloc, x.arg)]),
		(in Constant.Zero) =>
			reprSym!"zero");
