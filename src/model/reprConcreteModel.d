module model.reprConcreteModel;

@safe @nogc pure nothrow:

import model.concreteModel :
	body_,
	ConcreteExpr,
	ConcreteExprKind,
	ConcreteField,
	ConcreteFun,
	ConcreteFunBody,
	ConcreteFunSource,
	ConcreteLocal,
	ConcreteParam,
	ConcreteParamSource,
	ConcreteProgram,
	ConcreteStruct,
	ConcreteStructBody,
	ConcreteStructSource,
	ConcreteType,
	defaultReferenceKind,
	isSelfMutable,
	matchConcreteExprKind,
	matchConcreteFunBody,
	matchConcreteFunSource,
	matchConcreteParamSource,
	matchConcreteStructBody,
	matchConcreteStructSource,
	NeedsCtx,
	returnType,
	symOfBuiltinStructKind,
	symOfConcreteMutability,
	symOfReferenceKind;
import model.constant : Constant;
import model.model : EnumFunction, enumFunctionName, flagsFunctionName, FunInst, name, Param;
import model.reprConstant : reprOfConstant;
import util.alloc.alloc : Alloc;
import util.col.arrBuilder : add, ArrBuilder, finishArr;
import util.opt : force, has, Opt;
import util.repr :
	NameAndRepr,
	nameAndRepr,
	Repr,
	reprArr,
	reprBool,
	reprInt,
	reprNamedRecord,
	reprNat,
	reprOpt,
	reprRecord,
	reprStr,
	reprSym;
import util.sourceRange : reprFileAndRange;
import util.sym : shortSym;
import util.util : todo;

immutable(Repr) reprOfConcreteProgram(ref Alloc alloc, ref immutable ConcreteProgram a) {
	return reprRecord(alloc, "program", [
		reprArr(alloc, a.allStructs, (ref immutable ConcreteStruct* it) =>
			reprOfConcreteStruct(alloc, *it)),
		reprArr(alloc, a.allFuns, (ref immutable ConcreteFun* it) =>
			reprOfConcreteFun(alloc, *it)),
		reprOfConcreteFunRef(alloc, *a.rtMain),
		reprOfConcreteFunRef(alloc, *a.userMain),
		reprOfConcreteStructRef(alloc, *a.ctxType)]);
}

private:

immutable(Repr) reprOfConcreteStruct(ref Alloc alloc, ref immutable ConcreteStruct a) {
	ArrBuilder!NameAndRepr fields;
	add(alloc, fields, nameAndRepr("name", reprOfConcreteStructSource(alloc, a.source)));
	if (isSelfMutable(a))
		add(alloc, fields, nameAndRepr("mut", reprBool(true)));
	add(alloc, fields, nameAndRepr("reference", reprSym(symOfReferenceKind(defaultReferenceKind(a)))));
	add(alloc, fields, nameAndRepr("body", reprOfConcreteStructBody(alloc, body_(a))));
	return reprNamedRecord("struct", finishArr(alloc, fields));
}

immutable(Repr) reprOfConcreteStructSource(ref Alloc alloc, ref immutable ConcreteStructSource a) {
	return matchConcreteStructSource!(
		immutable Repr,
		(ref immutable ConcreteStructSource.Inst it) =>
			reprSym(name(*it.inst)),
		(ref immutable ConcreteStructSource.Lambda it) =>
			reprRecord(alloc, "lambda", [reprOfConcreteFunRef(alloc, *it.containingFun), reprNat(it.index)]),
	)(a);
}

public immutable(Repr) reprOfConcreteStructRef(ref Alloc alloc, ref immutable ConcreteStruct a) {
	return reprOfConcreteStructSource(alloc, a.source);
}

immutable(Repr) reprOfConcreteStructBody(ref Alloc alloc, ref immutable ConcreteStructBody a) {
	return matchConcreteStructBody!(immutable Repr)(
		a,
		(ref immutable ConcreteStructBody.Builtin it) =>
			reprOfConcreteStructBodyBuiltin(alloc, it),
		(ref immutable ConcreteStructBody.Enum it) =>
			//TODO:MORE DETAIL
			reprSym("enum"),
		(ref immutable ConcreteStructBody.Flags it) =>
			//TODO:MORE DETAIL
			reprSym("flags"),
		(ref immutable ConcreteStructBody.ExternPtr it) =>
			reprSym("extern-ptr"),
		(ref immutable ConcreteStructBody.Record it) =>
			reprOfConcreteStructBodyRecord(alloc, it),
		(ref immutable ConcreteStructBody.Union it) =>
			reprOfConcreteStructBodyUnion(alloc, it));
}

immutable(Repr) reprOfConcreteStructBodyBuiltin(ref Alloc alloc, ref immutable ConcreteStructBody.Builtin a) {
	return reprRecord(alloc, "builtin", [
		reprSym(symOfBuiltinStructKind(a.kind)),
		reprArr(alloc, a.typeArgs, (ref immutable ConcreteType it) =>
			reprOfConcreteType(alloc, it))]);
}

immutable(Repr) reprOfConcreteType(ref Alloc alloc, immutable ConcreteType a) {
	return reprRecord(alloc, "type", [
		reprSym(symOfReferenceKind(a.reference)),
		reprOfConcreteStructRef(alloc, *a.struct_)]);
}

immutable(Repr) reprOfConcreteStructBodyRecord(ref Alloc alloc, ref immutable ConcreteStructBody.Record a) {
	return reprRecord(alloc, "record", [reprArr(alloc, a.fields, (ref immutable ConcreteField it) =>
		reprOfConcreteField(alloc, it))]);
}

immutable(Repr) reprOfConcreteField(ref Alloc alloc, ref immutable ConcreteField a) {
	return reprRecord(alloc, "field", [
		reprSym(a.debugName),
		reprSym(symOfConcreteMutability(a.mutability)),
		reprOfConcreteType(alloc, a.type)]);
}

immutable(Repr) reprOfConcreteStructBodyUnion(ref Alloc alloc, ref immutable ConcreteStructBody.Union a) {
	return reprRecord(alloc, "union", [reprArr(alloc, a.members, (ref immutable Opt!ConcreteType it) =>
		reprOpt(alloc, it, (ref immutable ConcreteType t) =>
			reprOfConcreteType(alloc, t)))]);
}

immutable(Repr) reprOfConcreteFun(ref Alloc alloc, ref immutable ConcreteFun a) {
	return reprRecord(alloc, "fun", [
		reprSym(() {
			final switch (a.needsCtx) {
				case NeedsCtx.no:
					return shortSym("noctx");
				case NeedsCtx.yes:
					return shortSym("ctx");
			}
		}()),
		reprOfConcreteFunSource(alloc, a.source),
		reprOfConcreteType(alloc, a.returnType),
		reprOpt!(ConcreteParam*)(alloc, a.closureParam, (ref immutable ConcreteParam* it) =>
			reprOfParam(alloc, *it)),
		reprArr(alloc, a.paramsExcludingCtxAndClosure, (ref immutable ConcreteParam it) =>
			reprOfParam(alloc, it)),
		reprOfConcreteFunBody(alloc, body_(a))]);
}

immutable(Repr) reprOfConcreteFunSource(ref Alloc alloc, ref immutable ConcreteFunSource a) {
	return matchConcreteFunSource!(
		immutable Repr,
		(ref immutable FunInst it) =>
			reprSym(name(it)),
		(ref immutable ConcreteFunSource.Lambda it) =>
			reprRecord(alloc, "lambda", [
				reprOfConcreteFunRef(alloc, *it.containingFun),
				reprNat(it.index)]),
		(ref immutable(ConcreteFunSource.Test)) =>
			todo!(immutable Repr)("!"),
	)(a);
}

public immutable(Repr) reprOfConcreteFunRef(ref Alloc alloc, ref immutable ConcreteFun a) {
	return reprOfConcreteFunSource(alloc, a.source);
}

immutable(Repr) reprOfParam(ref Alloc alloc, ref immutable ConcreteParam a) {
	return reprRecord(alloc, "param", [
		reprOfConcreteParamRef(a),
		reprOfConcreteType(alloc, a.type)]);
}

public immutable(Repr) reprOfConcreteParamRef(ref immutable ConcreteParam a) {
	return matchConcreteParamSource!(immutable Repr)(
		a.source,
		(ref immutable ConcreteParamSource.Closure) =>
			reprStr("<<closure>>"),
		(ref immutable Param a) =>
			has(a.name) ? reprSym(force(a.name)) : reprStr("_"),
		(ref immutable ConcreteParamSource.Synthetic) =>
			reprStr("<<synthetic>>"));
}

immutable(Repr) reprOfConcreteFunBody(ref Alloc alloc, ref immutable ConcreteFunBody a) {
	return matchConcreteFunBody!(immutable Repr)(
		a,
		(ref immutable ConcreteFunBody.Builtin it) =>
			reprOfConcreteFunBodyBuiltin(alloc, it),
		(ref immutable ConcreteFunBody.CreateEnum it) =>
			reprRecord(alloc, "create-enum", [reprInt(it.value.value)]),
		(ref immutable ConcreteFunBody.CreateRecord) =>
			reprSym("new-record"),
		(ref immutable ConcreteFunBody.CreateUnion) =>
			//TODO: more detail
			reprSym("new-union"),
		(immutable EnumFunction it) =>
			reprRecord(alloc, "enum-fn", [reprSym(enumFunctionName(it))]),
		(ref immutable ConcreteFunBody.Extern it) =>
			reprSym("extern"),
		(ref immutable ConcreteExpr it) =>
			reprOfConcreteExpr(alloc, it),
		(ref immutable ConcreteFunBody.FlagsFn it) =>
			reprRecord(alloc, "flags-fn", [
				reprNat(it.allValue),
				reprSym(flagsFunctionName(it.fn)),
			]),
		(ref immutable ConcreteFunBody.RecordFieldGet it) =>
			reprRecord(alloc, "field-get", [reprNat(it.fieldIndex)]),
		(ref immutable ConcreteFunBody.RecordFieldSet it) =>
			reprRecord(alloc, "field-set", [reprNat(it.fieldIndex)]));
}

immutable(Repr) reprOfConcreteFunBodyBuiltin(ref Alloc alloc, ref immutable ConcreteFunBody.Builtin a) {
	return reprRecord(alloc, "builtin", [reprArr(alloc, a.typeArgs, (ref immutable ConcreteType it) =>
			reprOfConcreteType(alloc, it))]);
}

public immutable(Repr) reprOfConcreteLocalRef(ref immutable ConcreteLocal a) {
	return reprSym(a.source.name);
}

immutable(Repr) reprOfConcreteExpr(ref Alloc alloc, ref immutable ConcreteExpr a) {
	// TODO: For brevity.. (change back once we have tail recursion and crow can handle long strings)
	return reprOfConcreteExprKind(alloc, a.kind);
	//return reprRecord(alloc, "expr", [
	//	reprOfConcreteType(alloc, a.type),
	//	reprFileAndRange(alloc, a.range),
	//	reprOfConcreteExprKind(alloc, a)]);
}

immutable(Repr) reprOfConcreteExprKind(ref Alloc alloc, ref immutable ConcreteExprKind a) {
	return matchConcreteExprKind!(immutable Repr)(
		a,
		(ref immutable ConcreteExprKind.Alloc it) =>
			reprRecord(alloc, "alloc", [reprOfConcreteExpr(alloc, it.inner)]),
		(ref immutable ConcreteExprKind.Call it) =>
			reprRecord(alloc, "call", [
				reprOfConcreteFunRef(alloc, *it.called),
				reprArr(alloc, it.args, (ref immutable ConcreteExpr arg) =>
					reprOfConcreteExpr(alloc, arg))]),
		(ref immutable ConcreteExprKind.Cond it) =>
			reprRecord(alloc, "cond", [
				reprOfConcreteExpr(alloc, it.cond),
				reprOfConcreteExpr(alloc, it.then),
				reprOfConcreteExpr(alloc, it.else_)]),
		(immutable Constant it) =>
			reprOfConstant(alloc, it),
		(ref immutable ConcreteExprKind.CreateArr it) =>
			reprRecord(alloc, "create-arr", [
				reprOfConcreteStructRef(alloc, *it.arrType),
				reprArr(alloc, it.args, (ref immutable ConcreteExpr arg) =>
					reprOfConcreteExpr(alloc, arg))]),
		(ref immutable ConcreteExprKind.CreateRecord it) =>
			reprRecord(alloc, "record", [reprArr(alloc, it.args, (ref immutable ConcreteExpr arg) =>
				reprOfConcreteExpr(alloc, arg))]),
		(ref immutable ConcreteExprKind.CreateUnion it) =>
			reprRecord(alloc, "union", [
				reprNat(it.memberIndex),
				reprOfConcreteExpr(alloc, it.arg)]),
		(ref immutable ConcreteExprKind.Drop it) =>
			reprRecord(alloc, "drop", [reprOfConcreteExpr(alloc, it.arg)]),
		(ref immutable ConcreteExprKind.Lambda it) =>
			reprRecord(alloc, "lambda", [
				reprNat(it.memberIndex),
				reprOpt!(ConcreteExpr*)(alloc, it.closure, (ref immutable ConcreteExpr* closure) =>
					reprOfConcreteExpr(alloc, *closure))]),
		(ref immutable ConcreteExprKind.Let it) =>
			reprRecord(alloc, "let", [
				reprOfConcreteLocalRef(*it.local),
				reprOfConcreteExpr(alloc, it.value),
				reprOfConcreteExpr(alloc, it.then)]),
		(ref immutable ConcreteExprKind.LocalRef it) =>
			reprRecord(alloc, "local-ref", [reprOfConcreteLocalRef(*it.local)]),
		(ref immutable ConcreteExprKind.LocalSet it) =>
			reprRecord(alloc, "local-set", [
				reprOfConcreteLocalRef(*it.local),
				reprOfConcreteExpr(alloc, it.value)]),
		(ref immutable ConcreteExprKind.Loop it) =>
			reprRecord(alloc, "loop", [reprOfConcreteExpr(alloc, it.body_)]),
		(ref immutable ConcreteExprKind.LoopBreak it) =>
			reprRecord(alloc, "break", [reprOfConcreteExpr(alloc, it.value)]),
		(ref immutable ConcreteExprKind.MatchEnum it) =>
			reprRecord(alloc, "match-enum", [
				reprOfConcreteExpr(alloc, it.matchedValue),
				reprArr(alloc, it.cases, (ref immutable ConcreteExpr case_) =>
					reprOfConcreteExpr(alloc, case_))]),
		(ref immutable ConcreteExprKind.MatchUnion it) =>
			reprRecord(alloc, "match-union", [
				reprOfConcreteExpr(alloc, it.matchedValue),
				reprArr(alloc, it.cases, (ref immutable ConcreteExprKind.MatchUnion.Case case_) =>
					reprRecord(alloc, "case", [
						reprOpt!(ConcreteLocal*)(alloc, case_.local, (ref immutable ConcreteLocal* local) =>
							reprOfConcreteLocalRef(*local)),
						reprOfConcreteExpr(alloc, case_.then)]))]),
		(ref immutable ConcreteExprKind.ParamRef it) =>
			reprRecord(alloc, "param-ref", [reprOfConcreteParamRef(*it.param)]),
		(ref immutable ConcreteExprKind.RecordFieldGet it) =>
			reprRecord(alloc, "get-field", [
				reprOfConcreteExpr(alloc, it.target),
				reprNat(it.fieldIndex)]),
		(ref immutable ConcreteExprKind.Seq it) =>
			reprRecord(alloc, "seq", [reprOfConcreteExpr(alloc, it.first), reprOfConcreteExpr(alloc, it.then)]));
}
