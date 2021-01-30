module model.reprConcreteModel;

@safe @nogc pure nothrow:

import model.concreteModel :
	body_,
	ConcreteExpr,
	ConcreteExprKind,
	ConcreteField,
	ConcreteFun,
	ConcreteFunBody,
	ConcreteFunExprBody,
	ConcreteFunSource,
	ConcreteLocal,
	ConcreteLocalSource,
	ConcreteParam,
	ConcreteParamSource,
	ConcreteProgram,
	ConcreteStruct,
	ConcreteStructBody,
	ConcreteStructSource,
	ConcreteType,
	defaultIsPointer,
	isSelfMutable,
	matchConcreteExprKind,
	matchConcreteFunBody,
	matchConcreteFunSource,
	matchConcreteLocalSource,
	matchConcreteParamSource,
	matchConcreteStructBody,
	matchConcreteStructSource,
	name,
	returnType,
	symOfBuiltinStructKind;
import model.constant : Constant;
import model.model : FunInst, name, Local, Param;
import model.reprConstant : reprOfConstant;
import util.collection.arrBuilder : add, ArrBuilder, finishArr;
import util.opt : force, has;
import util.ptr : Ptr;
import util.repr :
	NameAndRepr,
	nameAndRepr,
	Repr,
	reprArr,
	reprBool,
	reprNamedRecord,
	reprNat,
	reprOpt,
	reprRecord,
	reprStr,
	reprSym;
import util.sourceRange : reprFileAndRange;
import util.util : todo;

immutable(Repr) reprOfConcreteProgram(Alloc)(ref Alloc alloc, ref immutable ConcreteProgram a) {
	return reprRecord(alloc, "program", [
		reprArr(alloc, a.allStructs, (ref immutable Ptr!ConcreteStruct it) =>
			reprOfConcreteStruct(alloc, it)),
		reprArr(alloc, a.allFuns, (ref immutable Ptr!ConcreteFun it) =>
			reprOfConcreteFun(alloc, it)),
		reprOfConcreteFunRef(alloc, a.rtMain),
		reprOfConcreteFunRef(alloc, a.userMain),
		reprOfConcreteStructRef(alloc, a.ctxType)]);
}

private:

immutable(Repr) reprOfConcreteStruct(Alloc)(ref Alloc alloc, ref immutable ConcreteStruct a) {
	ArrBuilder!NameAndRepr fields;
	add(alloc, fields, nameAndRepr("name", reprOfConcreteStructSource(alloc, a.source)));
	if (isSelfMutable(a))
		add(alloc, fields, nameAndRepr("mut?", reprBool(true)));
	if (defaultIsPointer(a))
		add(alloc, fields, nameAndRepr("ptr?", reprBool(true)));
	add(alloc, fields, nameAndRepr("body", reprOfConcreteStructBody(alloc, body_(a))));
	return reprNamedRecord("struct", finishArr(alloc, fields));
}

immutable(Repr) reprOfConcreteStructSource(Alloc)(ref Alloc alloc, ref immutable ConcreteStructSource a) {
	return matchConcreteStructSource!(immutable Repr)(
		a,
		(ref immutable ConcreteStructSource.Inst it) =>
			reprSym(name(it.inst)),
		(ref immutable ConcreteStructSource.Lambda it) =>
			reprRecord(alloc, "lambda", [reprOfConcreteFunRef(alloc, it.containingFun), reprNat(it.index)]));
}

public immutable(Repr) reprOfConcreteStructRef(Alloc)(ref Alloc alloc, immutable Ptr!ConcreteStruct a) {
	return reprOfConcreteStructSource(alloc, a.source);
}

immutable(Repr) reprOfConcreteStructBody(Alloc)(ref Alloc alloc, ref immutable ConcreteStructBody a) {
	return matchConcreteStructBody(
		a,
		(ref immutable ConcreteStructBody.Builtin it) =>
			reprOfConcreteStructBodyBuiltin(alloc, it),
		(ref immutable ConcreteStructBody.ExternPtr it) =>
			reprSym("extern-ptr"),
		(ref immutable ConcreteStructBody.Record it) =>
			reprOfConcreteStructBodyRecord(alloc, it),
		(ref immutable ConcreteStructBody.Union it) =>
			reprOfConcreteStructBodyUnion(alloc, it));
}

immutable(Repr) reprOfConcreteStructBodyBuiltin(Alloc)(ref Alloc alloc, ref immutable ConcreteStructBody.Builtin a) {
	return reprRecord(alloc, "builtin", [
		reprSym(symOfBuiltinStructKind(a.kind)),
		reprArr(alloc, a.typeArgs, (ref immutable ConcreteType it) =>
			reprOfConcreteType(alloc, it))]);
}

immutable(Repr) reprOfConcreteType(Alloc)(ref Alloc alloc, immutable ConcreteType a) {
	return reprRecord(alloc, "type", [
		reprBool(a.isPointer),
		reprOfConcreteStructRef(alloc, a.struct_)]);
}

immutable(Repr) reprOfConcreteStructBodyRecord(Alloc)(ref Alloc alloc, ref immutable ConcreteStructBody.Record a) {
	return reprRecord(alloc, "record", [reprArr(alloc, a.fields, (ref immutable ConcreteField it) =>
		reprOfConcreteField(alloc, it))]);
}

immutable(Repr) reprOfConcreteField(Alloc)(ref Alloc alloc, ref immutable ConcreteField a) {
	return reprRecord(alloc, "field", [reprSym(name(a)),
		reprBool(a.isMutable),
		reprOfConcreteType(alloc, a.type)]);
}

immutable(Repr) reprOfConcreteStructBodyUnion(Alloc)(ref Alloc alloc, ref immutable ConcreteStructBody.Union a) {
	return reprRecord(alloc, "union", [reprArr(alloc, a.members, (ref immutable ConcreteType it) =>
		reprOfConcreteType(alloc, it))]);
}

immutable(Repr) reprOfConcreteFun(Alloc)(ref Alloc alloc, ref immutable ConcreteFun a) {
	return reprRecord(alloc, "fun", [
		reprBool(a.needsCtx),
		reprOfConcreteFunSource(alloc, a.source),
		reprOfConcreteType(alloc, a.returnType),
		reprOpt(alloc, a.closureParam, (ref immutable Ptr!ConcreteParam it) =>
			reprOfParam(alloc, it)),
		reprArr(alloc, a.paramsExcludingCtxAndClosure, (ref immutable ConcreteParam it) =>
			reprOfParam(alloc, it)),
		reprOfConcreteFunBody(alloc, body_(a))]);
}

immutable(Repr) reprOfConcreteFunSource(Alloc)(ref Alloc alloc, ref immutable ConcreteFunSource a) {
	return matchConcreteFunSource!(immutable Repr)(
		a,
		(immutable Ptr!FunInst it) =>
			reprSym(name(it)),
		(ref immutable ConcreteFunSource.Lambda it) =>
			reprRecord(alloc, "lambda", [
				reprOfConcreteFunRef(alloc, it.containingFun),
				reprNat(it.index)]),
		(ref immutable(ConcreteFunSource.Test)) =>
			todo!(immutable Repr)("!"));
}

public immutable(Repr) reprOfConcreteFunRef(Alloc)(ref Alloc alloc, immutable Ptr!ConcreteFun a) {
	return reprOfConcreteFunSource(alloc, a.source);
}

immutable(Repr) reprOfParam(Alloc)(ref Alloc alloc, ref immutable ConcreteParam a) {
	return reprRecord(alloc, "param", [
		reprOfConcreteParamRef(a),
		reprOfConcreteType(alloc, a.type)]);
}

public immutable(Repr) reprOfConcreteParamRef(ref immutable ConcreteParam a) {
	return matchConcreteParamSource!(immutable Repr)(
		a.source,
		(ref immutable ConcreteParamSource.Closure) =>
			reprStr("<<closure>>"),
		(immutable Ptr!Param a) =>
			has(a.name) ? reprSym(force(a.name)) : reprStr("_"));
}

immutable(Repr) reprOfConcreteFunBody(Alloc)(ref Alloc alloc, ref immutable ConcreteFunBody a) {
	return matchConcreteFunBody!(immutable Repr)(
		a,
		(ref immutable ConcreteFunBody.Builtin it) =>
			reprOfConcreteFunBodyBuiltin(alloc, it),
		(ref immutable ConcreteFunBody.CreateRecord) =>
			reprSym("new-record"),
		(ref immutable ConcreteFunBody.Extern it) =>
			reprRecord(alloc, "extern", [reprBool(it.isGlobal)]),
		(ref immutable ConcreteFunExprBody it) =>
			reprOfConcreteFunExprBody(alloc, it),
		(ref immutable ConcreteFunBody.RecordFieldGet it) =>
			reprRecord(alloc, "field-get", [reprNat(it.fieldIndex)]),
		(ref immutable ConcreteFunBody.RecordFieldSet it) =>
			reprRecord(alloc, "field-set", [reprNat(it.fieldIndex)]));
}

immutable(Repr) reprOfConcreteFunBodyBuiltin(Alloc)(ref Alloc alloc, ref immutable ConcreteFunBody.Builtin a) {
	return reprRecord(alloc, "builtin", [reprArr(alloc, a.typeArgs, (ref immutable ConcreteType it) =>
			reprOfConcreteType(alloc, it))]);
}

immutable(Repr) reprOfConcreteFunExprBody(Alloc)(ref Alloc alloc, ref immutable ConcreteFunExprBody a) {
	return reprRecord(alloc, "expr-body", [reprOfConcreteExpr(alloc, a.expr)]);
}

public immutable(Repr) reprOfConcreteLocalRef(immutable Ptr!ConcreteLocal a) {
	return matchConcreteLocalSource!(immutable Repr)(
		a.source,
		(ref immutable ConcreteLocalSource.Arr) =>
			reprStr("<<arr>>"),
		(immutable Ptr!Local it) =>
			reprSym(it.name),
		(ref immutable ConcreteLocalSource.Matched) =>
			reprStr("<<matched>>"));
}

immutable(Repr) reprOfConcreteExpr(Alloc)(ref Alloc alloc, ref immutable ConcreteExpr a) {
	// TODO: For brevity.. (change back once we have tail recursion and crow can handle long strings)
	return reprOfConcreteExprKind(alloc, a.kind);
	//return reprRecord(alloc, "expr", [
	//	reprOfConcreteType(alloc, a.type),
	//	reprFileAndRange(alloc, a.range),
	//	reprOfConcreteExprKind(alloc, a)]);
}

immutable(Repr) reprOfConcreteExprKind(Alloc)(ref Alloc alloc, ref immutable ConcreteExprKind a) {
	return matchConcreteExprKind!(immutable Repr)(
		a,
		(ref immutable ConcreteExprKind.Alloc it) =>
			reprRecord(alloc, "alloc", [reprOfConcreteExpr(alloc, it.inner)]),
		(ref immutable ConcreteExprKind.Call it) =>
			reprRecord(alloc, "call", [
				reprOfConcreteFunRef(alloc, it.called),
				reprArr(alloc, it.args, (ref immutable ConcreteExpr arg) =>
					reprOfConcreteExpr(alloc, arg))]),
		(ref immutable ConcreteExprKind.Cond it) =>
			reprRecord(alloc, "cond", [
				reprOfConcreteExpr(alloc, it.cond),
				reprOfConcreteExpr(alloc, it.then),
				reprOfConcreteExpr(alloc, it.else_)]),
		(ref immutable Constant it) =>
			reprOfConstant(alloc, it),
		(ref immutable ConcreteExprKind.CreateArr it) =>
			reprRecord(alloc, "create-arr", [
				reprOfConcreteStructRef(alloc, it.arrType),
				reprOfConcreteType(alloc, it.elementType),
				reprArr(alloc, it.args, (ref immutable ConcreteExpr arg) =>
					reprOfConcreteExpr(alloc, arg))]),
		(ref immutable ConcreteExprKind.CreateRecord it) =>
			reprRecord(alloc, "record", [reprArr(alloc, it.args, (ref immutable ConcreteExpr arg) =>
				reprOfConcreteExpr(alloc, arg))]),
		(ref immutable ConcreteExprKind.ConvertToUnion it) =>
			reprRecord(alloc, "to-union", [
				reprNat(it.memberIndex),
				reprOfConcreteExpr(alloc, it.arg)]),
		(ref immutable ConcreteExprKind.Lambda it) =>
			reprRecord(alloc, "lambda", [
				reprNat(it.memberIndex),
				reprOfConcreteExpr(alloc, it.closure)]),
		(ref immutable ConcreteExprKind.LambdaFunPtr it) =>
			reprRecord(alloc, "fun-ptr", [reprOfConcreteFunRef(alloc, it.fun)]),
		(ref immutable ConcreteExprKind.Let it) =>
			reprRecord(alloc, "let", [
				reprOfConcreteLocalRef(it.local),
				reprOfConcreteExpr(alloc, it.value),
				reprOfConcreteExpr(alloc, it.then)]),
		(ref immutable ConcreteExprKind.LocalRef it) =>
			reprRecord(alloc, "local-ref", [reprOfConcreteLocalRef(it.local)]),
		(ref immutable ConcreteExprKind.Match it) =>
			reprRecord(alloc, "match", [
				reprOfConcreteExpr(alloc, it.matchedValue),
				reprArr(alloc, it.cases, (ref immutable ConcreteExprKind.Match.Case case_) =>
					reprRecord(alloc, "case", [
						reprOpt(alloc, case_.local, (ref immutable Ptr!ConcreteLocal local) =>
							reprOfConcreteLocalRef(local)),
						reprOfConcreteExpr(alloc, case_.then)]))]),
		(ref immutable ConcreteExprKind.ParamRef it) =>
			reprRecord(alloc, "param-ref", [reprOfConcreteParamRef(it.param)]),
		(ref immutable ConcreteExprKind.RecordFieldGet it) =>
			reprRecord(alloc, "get-field", [reprOfConcreteExpr(alloc, it.target), reprSym(name(it.field))]),
		(ref immutable ConcreteExprKind.Seq it) =>
			reprRecord(alloc, "seq", [reprOfConcreteExpr(alloc, it.first), reprOfConcreteExpr(alloc, it.then)]));
}
