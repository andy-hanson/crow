module model.reprConstant;

@safe @nogc pure nothrow:

import model.concreteModel : name;
import model.constant : Constant;
import util.alloc.alloc : Alloc;
import util.sym : Sym;
import util.repr : Repr, reprArr, reprBool, reprFloat, reprNat, reprOpt, reprRecord, reprSym;

immutable(Repr) reprOfConstant(ref Alloc alloc, immutable Constant a) =>
	a.match!(immutable Repr)(
		(immutable Constant.ArrConstant x) =>
			reprRecord!"arr"(alloc, [reprNat(x.typeIndex), reprNat(x.index)]),
		(immutable Constant.BoolConstant x) =>
			reprBool(x.value),
		(immutable Constant.CString x) =>
			reprRecord!"c-string"(alloc, [reprNat(x.index)]),
		(immutable Constant.ExternZeroed) =>
			reprSym!"extern",
		(immutable Constant.Float x) =>
			reprFloat(x.value),
		(immutable Constant.FunPtr x) =>
			reprRecord!"fun-pointer"(alloc, [
				reprOpt(alloc, name(*x.fun), (ref immutable Sym name) => reprSym(name))]),
		(immutable Constant.Integral x) =>
			reprNat(x.value),
		(immutable Constant.Null) =>
			reprSym!"null" ,
		(immutable Constant.Pointer x) =>
			reprRecord!"pointer"(alloc, [reprNat(x.typeIndex), reprNat(x.index)]),
		(immutable Constant.Record x) =>
			reprRecord!"record"(alloc, [reprArr(alloc, x.args, (ref immutable Constant arg) =>
				reprOfConstant(alloc, arg))]),
		(ref immutable Constant.Union x) =>
			reprRecord!"union"(alloc, [reprNat(x.memberIndex), reprOfConstant(alloc, x.arg)]),
		(immutable Constant.Void) =>
			reprSym!"void");
