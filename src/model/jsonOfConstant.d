module model.jsonOfConstant;

@safe @nogc pure nothrow:

import model.concreteModel : name;
import model.constant : Constant;
import util.alloc.alloc : Alloc;
import util.json : field, jsonObject, optionalField, Json, jsonList, jsonString, kindField;
import util.symbol : Symbol;

Json jsonOfConstant(ref Alloc alloc, in Constant a) =>
	a.matchIn!Json(
		(in Constant.ArrConstant x) =>
			jsonObject(alloc, [
				kindField!"array",
				field!"type-index"(x.typeIndex),
				field!"index"(x.index)]),
		(in Constant.CString x) =>
			jsonObject(alloc, [
				kindField!"c-string",
				field!"index"(x.index)]),
		(in Constant.Float x) =>
			jsonObject(alloc, [
				kindField!"float",
				field!"value"(x.value)]),
		(in Constant.FunPtr x) =>
			jsonObject(alloc, [
				kindField!"fun-pointer",
				optionalField!("fun-name", Symbol)(name(*x.fun), (in Symbol name) => jsonString(name))]),
		(in Constant.Integral x) =>
			jsonObject(alloc, [
				kindField!"integral",
				field!"value"(x.value)]),
		(in Constant.Pointer x) =>
			jsonObject(alloc, [
				kindField!"pointer",
				field!"type-index"(x.typeIndex),
				field!"index"(x.index)]),
		(in Constant.Record x) =>
			jsonObject(alloc, [
				kindField!"record",
				field!"args"(jsonList!Constant(alloc, x.args, (in Constant arg) =>
					jsonOfConstant(alloc, arg)))]),
		(in Constant.Union x) =>
			jsonObject(alloc, [
				kindField!"union",
				field!"member-index"(x.memberIndex),
				field!"value"(jsonOfConstant(alloc, x.arg))]),
		(in Constant.Zero) =>
			jsonObject(alloc, [kindField!"zero"]));
