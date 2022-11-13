module model.reprConstant;

@safe @nogc pure nothrow:

import model.concreteModel : name;
import model.constant : Constant, matchConstant;
import util.alloc.alloc : Alloc;
import util.sym : Sym;
import util.repr : Repr, reprArr, reprBool, reprFloat, reprNat, reprOpt, reprRecord, reprSym;

immutable(Repr) reprOfConstant(ref Alloc alloc, ref immutable Constant a) =>
	matchConstant!(immutable Repr)(
		a,
		(ref immutable Constant.ArrConstant it) =>
			reprRecord!"arr"(alloc, [reprNat(it.typeIndex), reprNat(it.index)]),
		(immutable Constant.BoolConstant it) =>
			reprBool(it.value),
		(ref immutable Constant.CString it) =>
			reprRecord!"c-string"(alloc, [reprNat(it.index)]),
		(immutable Constant.Float it) =>
			reprFloat(it.value),
		(immutable Constant.FunPtr it) =>
			reprRecord!"fun-pointer"(alloc, [
				reprOpt(alloc, name(*it.fun), (ref immutable Sym name) => reprSym(name))]),
		(immutable Constant.Integral it) =>
			reprNat(it.value),
		(immutable Constant.Null) =>
			reprSym!"null" ,
		(immutable Constant.Pointer it) =>
			reprRecord!"pointer"(alloc, [reprNat(it.typeIndex), reprNat(it.index)]),
		(ref immutable Constant.Record it) =>
			reprRecord!"record"(alloc, [reprArr(alloc, it.args, (ref immutable Constant arg) =>
				reprOfConstant(alloc, arg))]),
		(ref immutable Constant.Union it) =>
			reprRecord!"union"(alloc, [reprNat(it.memberIndex), reprOfConstant(alloc, it.arg)]),
		(immutable Constant.Void) =>
			reprSym!"void" );
