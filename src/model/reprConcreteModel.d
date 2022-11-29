module model.reprConcreteModel;

@safe @nogc pure nothrow:

import model.concreteModel :
	body_,
	ConcreteClosureRef,
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
	returnType,
	symOfBuiltinStructKind,
	symOfConcreteMutability,
	symOfReferenceKind;
import model.constant : Constant;
import model.model : EnumFunction, enumFunctionName, flagsFunctionName, FunInst, name, Param, symOfClosureReferenceKind;
import model.reprConstant : reprOfConstant;
import util.alloc.alloc : Alloc;
import util.col.arrBuilder : add, ArrBuilder, finishArr;
import util.opt : force, has, Opt;
import util.repr :
	NameAndRepr, nameAndRepr, Repr, reprArr, reprBool, reprNamedRecord, reprNat, reprOpt, reprRecord, reprStr, reprSym;
import util.sourceRange : reprFileAndRange;
import util.util : todo;

immutable(Repr) reprOfConcreteProgram(ref Alloc alloc, ref immutable ConcreteProgram a) =>
	reprRecord!"program"(alloc, [
		reprArr(alloc, a.allStructs, (ref immutable ConcreteStruct* it) =>
			reprOfConcreteStruct(alloc, *it)),
		reprArr(alloc, a.allFuns, (ref immutable ConcreteFun* it) =>
			reprOfConcreteFun(alloc, *it)),
		reprOfConcreteFunRef(alloc, *a.rtMain),
		reprOfConcreteFunRef(alloc, *a.userMain)]);

private:

immutable(Repr) reprOfConcreteStruct(ref Alloc alloc, ref immutable ConcreteStruct a) {
	ArrBuilder!NameAndRepr fields;
	add(alloc, fields, nameAndRepr!"name"(reprOfConcreteStructSource(alloc, a.source)));
	if (isSelfMutable(a))
		add(alloc, fields, nameAndRepr!"mut"(reprBool(true)));
	add(alloc, fields, nameAndRepr!"reference"(reprSym(symOfReferenceKind(defaultReferenceKind(a)))));
	add(alloc, fields, nameAndRepr!"body"(reprOfConcreteStructBody(alloc, body_(a))));
	return reprNamedRecord!"struct"(finishArr(alloc, fields));
}

immutable(Repr) reprOfConcreteStructSource(ref Alloc alloc, ref immutable ConcreteStructSource a) =>
	a.match!(immutable Repr)(
		(immutable ConcreteStructSource.Inst it) =>
			reprSym(name(*it.inst)),
		(immutable ConcreteStructSource.Lambda it) =>
			reprRecord!"lambda"(alloc, [reprOfConcreteFunRef(alloc, *it.containingFun), reprNat(it.index)]));

public immutable(Repr) reprOfConcreteStructRef(ref Alloc alloc, ref immutable ConcreteStruct a) =>
	reprOfConcreteStructSource(alloc, a.source);

immutable(Repr) reprOfConcreteStructBody(ref Alloc alloc, ref immutable ConcreteStructBody a) =>
	a.match!(immutable Repr)(
		(immutable ConcreteStructBody.Builtin it) =>
			reprOfConcreteStructBodyBuiltin(alloc, it),
		(immutable ConcreteStructBody.Enum it) =>
			//TODO:MORE DETAIL
			reprSym!"enum",
		(immutable ConcreteStructBody.Extern) =>
			reprSym!"extern",
		(immutable ConcreteStructBody.Flags it) =>
			//TODO:MORE DETAIL
			reprSym!"flags" ,
		(immutable ConcreteStructBody.Record it) =>
			reprOfConcreteStructBodyRecord(alloc, it),
		(immutable ConcreteStructBody.Union it) =>
			reprOfConcreteStructBodyUnion(alloc, it));

immutable(Repr) reprOfConcreteStructBodyBuiltin(ref Alloc alloc, ref immutable ConcreteStructBody.Builtin a) =>
	reprRecord!"builtin"(alloc, [
		reprSym(symOfBuiltinStructKind(a.kind)),
		reprArr(alloc, a.typeArgs, (ref immutable ConcreteType it) =>
			reprOfConcreteType(alloc, it))]);

immutable(Repr) reprOfConcreteType(ref Alloc alloc, immutable ConcreteType a) =>
	reprRecord!"type"(alloc, [
		reprSym(symOfReferenceKind(a.reference)),
		reprOfConcreteStructRef(alloc, *a.struct_)]);

immutable(Repr) reprOfConcreteStructBodyRecord(ref Alloc alloc, ref immutable ConcreteStructBody.Record a) =>
	reprRecord!"record"(alloc, [reprArr(alloc, a.fields, (ref immutable ConcreteField it) =>
		reprOfConcreteField(alloc, it))]);

immutable(Repr) reprOfConcreteField(ref Alloc alloc, ref immutable ConcreteField a) =>
	reprRecord!"field"(alloc, [
		reprSym(a.debugName),
		reprSym(symOfConcreteMutability(a.mutability)),
		reprOfConcreteType(alloc, a.type)]);

immutable(Repr) reprOfConcreteStructBodyUnion(ref Alloc alloc, ref immutable ConcreteStructBody.Union a) =>
	reprRecord!"union"(alloc, [reprArr(alloc, a.members, (ref immutable Opt!ConcreteType it) =>
		reprOpt(alloc, it, (ref immutable ConcreteType t) =>
			reprOfConcreteType(alloc, t)))]);

immutable(Repr) reprOfConcreteFun(ref Alloc alloc, ref immutable ConcreteFun a) =>
	reprRecord!"fun"(alloc, [
		reprOfConcreteFunSource(alloc, a.source),
		reprOfConcreteType(alloc, a.returnType),
		reprOpt!(ConcreteParam*)(alloc, a.closureParam, (ref immutable ConcreteParam* it) =>
			reprOfParam(alloc, *it)),
		reprArr(alloc, a.paramsExcludingClosure, (ref immutable ConcreteParam it) =>
			reprOfParam(alloc, it)),
		reprOfConcreteFunBody(alloc, body_(a))]);

immutable(Repr) reprOfConcreteFunSource(ref Alloc alloc, ref immutable ConcreteFunSource a) =>
	a.match!(immutable Repr)(
		(ref immutable FunInst it) =>
			reprSym(it.name),
		(ref immutable ConcreteFunSource.Lambda it) =>
			reprRecord!"lambda"(alloc, [
				reprOfConcreteFunRef(alloc, *it.containingFun),
				reprNat(it.index)]),
		(ref immutable(ConcreteFunSource.Test)) =>
			reprSym!"test");

public immutable(Repr) reprOfConcreteFunRef(ref Alloc alloc, ref immutable ConcreteFun a) =>
	reprOfConcreteFunSource(alloc, a.source);

immutable(Repr) reprOfParam(ref Alloc alloc, ref immutable ConcreteParam a) =>
	reprRecord!"param"(alloc, [
		reprOfConcreteParamGet(a),
		reprOfConcreteType(alloc, a.type)]);

public immutable(Repr) reprOfConcreteParamGet(ref immutable ConcreteParam a) =>
	a.source.match!(immutable Repr)(
		(immutable ConcreteParamSource.Closure) =>
			reprStr("<<closure>>"),
		(ref immutable Param a) =>
			has(a.name) ? reprSym(force(a.name)) : reprStr("_"),
		(immutable ConcreteParamSource.Synthetic) =>
			reprStr("<<synthetic>>"));

immutable(Repr) reprOfConcreteFunBody(ref Alloc alloc, ref immutable ConcreteFunBody a) =>
	a.match!(immutable Repr)(
		(immutable ConcreteFunBody.Builtin x) =>
			reprOfConcreteFunBodyBuiltin(alloc, x),
		(immutable Constant x) =>
			reprRecord!"constant"(alloc, [reprOfConstant(alloc, x)]),
		(immutable ConcreteFunBody.CreateRecord) =>
			reprSym!"new-record" ,
		(immutable ConcreteFunBody.CreateUnion) =>
			//TODO: more detail
			reprSym!"new-union" ,
		(immutable EnumFunction x) =>
			reprRecord!"enum-fn"(alloc, [reprSym(enumFunctionName(x))]),
		(immutable ConcreteFunBody.Extern) =>
			reprSym!"extern" ,
		(immutable ConcreteExpr x) =>
			reprOfConcreteExpr(alloc, x),
		(immutable ConcreteFunBody.FlagsFn x) =>
			reprRecord!"flags-fn"(alloc, [
				reprNat(x.allValue),
				reprSym(flagsFunctionName(x.fn)),
			]),
		(immutable ConcreteFunBody.RecordFieldGet x) =>
			reprRecord!"field-get"(alloc, [reprNat(x.fieldIndex)]),
		(immutable ConcreteFunBody.RecordFieldSet x) =>
			reprRecord!"field-set"(alloc, [reprNat(x.fieldIndex)]),
		(immutable ConcreteFunBody.ThreadLocal x) =>
			reprSym!"thread-local" );

immutable(Repr) reprOfConcreteFunBodyBuiltin(ref Alloc alloc, ref immutable ConcreteFunBody.Builtin a) =>
	reprRecord!"builtin"(alloc, [reprArr(alloc, a.typeArgs, (ref immutable ConcreteType it) =>
			reprOfConcreteType(alloc, it))]);

public immutable(Repr) reprOfConcreteLocalGet(ref immutable ConcreteLocal a) =>
	reprSym(a.source.name);

immutable(Repr) reprOfConcreteExpr(ref Alloc alloc, ref immutable ConcreteExpr a) {
	// TODO: For brevity.. (change back once we have tail recursion and crow can handle long strings)
	return reprOfConcreteExprKind(alloc, a.kind);
	//return reprRecord!"expr"(alloc, [
	//	reprOfConcreteType(alloc, a.type),
	//	reprFileAndRange(alloc, a.range),
	//	reprOfConcreteExprKind(alloc, a)]);
}

immutable(Repr) reprOfConcreteExprKind(ref Alloc alloc, ref immutable ConcreteExprKind a) =>
	a.match!(immutable Repr)(
		(ref immutable ConcreteExprKind.Alloc it) =>
			reprRecord!"alloc"(alloc, [reprOfConcreteExpr(alloc, it.inner)]),
		(immutable ConcreteExprKind.Call it) =>
			reprRecord!"call"(alloc, [
				reprOfConcreteFunRef(alloc, *it.called),
				reprArr(alloc, it.args, (ref immutable ConcreteExpr arg) =>
					reprOfConcreteExpr(alloc, arg))]),
		(immutable ConcreteExprKind.ClosureCreate it) =>
			todo!(immutable Repr)("!"),
		(ref immutable ConcreteExprKind.ClosureGet it) =>
			reprRecord!"closure-get"(alloc, [
				reprConcreteClosureRef(alloc, it.closureRef),
				reprSym(symOfClosureReferenceKind(it.referenceKind))]),
		(ref immutable ConcreteExprKind.ClosureSet it) =>
			reprRecord!"closure-set"(alloc, [
				reprConcreteClosureRef(alloc, it.closureRef),
				reprOfConcreteExpr(alloc, it.value)]),
		(ref immutable ConcreteExprKind.Cond it) =>
			reprRecord!"cond"(alloc, [
				reprOfConcreteExpr(alloc, it.cond),
				reprOfConcreteExpr(alloc, it.then),
				reprOfConcreteExpr(alloc, it.else_)]),
		(immutable Constant it) =>
			reprOfConstant(alloc, it),
		(ref immutable ConcreteExprKind.CreateArr it) =>
			reprRecord!"create-arr"(alloc, [
				reprOfConcreteStructRef(alloc, *it.arrType),
				reprArr(alloc, it.args, (ref immutable ConcreteExpr arg) =>
					reprOfConcreteExpr(alloc, arg))]),
		(immutable ConcreteExprKind.CreateRecord it) =>
			reprRecord!"record"(alloc, [reprArr(alloc, it.args, (ref immutable ConcreteExpr arg) =>
				reprOfConcreteExpr(alloc, arg))]),
		(ref immutable ConcreteExprKind.CreateUnion it) =>
			reprRecord!"union"(alloc, [
				reprNat(it.memberIndex),
				reprOfConcreteExpr(alloc, it.arg)]),
		(ref immutable ConcreteExprKind.Drop it) =>
			reprRecord!"drop"(alloc, [reprOfConcreteExpr(alloc, it.arg)]),
		(immutable ConcreteExprKind.Lambda it) =>
			reprRecord!"lambda"(alloc, [
				reprNat(it.memberIndex),
				reprOpt!(ConcreteExpr*)(alloc, it.closure, (ref immutable ConcreteExpr* closure) =>
					reprOfConcreteExpr(alloc, *closure))]),
		(ref immutable ConcreteExprKind.Let it) =>
			reprRecord!"let"(alloc, [
				reprOfConcreteLocalGet(*it.local),
				reprOfConcreteExpr(alloc, it.value),
				reprOfConcreteExpr(alloc, it.then)]),
		(immutable ConcreteExprKind.LocalGet it) =>
			reprRecord!"local-get"(alloc, [reprOfConcreteLocalGet(*it.local)]),
		(ref immutable ConcreteExprKind.LocalSet it) =>
			reprRecord!"local-set"(alloc, [
				reprOfConcreteLocalGet(*it.local),
				reprOfConcreteExpr(alloc, it.value)]),
		(ref immutable ConcreteExprKind.Loop it) =>
			reprRecord!"loop"(alloc, [reprOfConcreteExpr(alloc, it.body_)]),
		(ref immutable ConcreteExprKind.LoopBreak it) =>
			reprRecord!"break"(alloc, [reprOfConcreteExpr(alloc, it.value)]),
		(immutable ConcreteExprKind.LoopContinue it) =>
			reprSym!"continue" ,
		(ref immutable ConcreteExprKind.MatchEnum it) =>
			reprRecord!"match-enum"(alloc, [
				reprOfConcreteExpr(alloc, it.matchedValue),
				reprArr(alloc, it.cases, (ref immutable ConcreteExpr case_) =>
					reprOfConcreteExpr(alloc, case_))]),
		(ref immutable ConcreteExprKind.MatchUnion it) =>
			reprRecord!"match-union"(alloc, [
				reprOfConcreteExpr(alloc, it.matchedValue),
				reprArr(alloc, it.cases, (ref immutable ConcreteExprKind.MatchUnion.Case case_) =>
					reprRecord!"case"(alloc, [
						reprOpt!(ConcreteLocal*)(alloc, case_.local, (ref immutable ConcreteLocal* local) =>
							reprOfConcreteLocalGet(*local)),
						reprOfConcreteExpr(alloc, case_.then)]))]),
		(immutable ConcreteExprKind.ParamGet it) =>
			reprRecord!"param-get"(alloc, [reprOfConcreteParamGet(*it.param)]),
		(ref immutable ConcreteExprKind.PtrToField it) =>
			reprRecord!"ptr-to-field"(alloc, [reprOfConcreteExpr(alloc, it.target), reprNat(it.fieldIndex)]),
		(immutable ConcreteExprKind.PtrToLocal it) =>
			reprRecord!"ptr-to-local"(alloc, [reprOfConcreteLocalGet(*it.local)]),
		(immutable ConcreteExprKind.PtrToParam it) =>
			reprRecord!"ptr-to-param"(alloc, [reprOfConcreteParamGet(*it.param)]),
		(ref immutable ConcreteExprKind.Seq it) =>
			reprRecord!"seq"(alloc, [reprOfConcreteExpr(alloc, it.first), reprOfConcreteExpr(alloc, it.then)]),
		(ref immutable ConcreteExprKind.Throw it) =>
			reprRecord!"throw"(alloc, [reprOfConcreteExpr(alloc, it.thrown)]));

immutable(Repr) reprConcreteClosureRef(ref Alloc alloc, immutable ConcreteClosureRef a) =>
	reprRecord!"closure-ref"(alloc, [
		reprNat(a.fieldIndex)]);
