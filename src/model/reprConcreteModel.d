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
	ConcreteLocalSource,
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
import model.model : EnumFunction, enumFunctionName, flagsFunctionName, FunInst, Local, name, symOfClosureReferenceKind;
import model.reprConstant : reprOfConstant;
import util.alloc.alloc : Alloc;
import util.col.arrBuilder : add, ArrBuilder, finishArr;
import util.repr :
	NameAndRepr, nameAndRepr, Repr, reprArr, reprBool, reprNamedRecord, reprNat, reprOpt, reprRecord, reprSym;
import util.sourceRange : reprFileAndRange;
import util.sym : Sym, sym;
import util.util : todo;

Repr reprOfConcreteProgram(ref Alloc alloc, in ConcreteProgram a) =>
	reprRecord!"program"(alloc, [
		reprArr!(ConcreteStruct*)(alloc, a.allStructs, (in ConcreteStruct* it) =>
			reprOfConcreteStruct(alloc, *it)),
		reprArr!(ConcreteFun*)(alloc, a.allFuns, (in ConcreteFun* it) =>
			reprOfConcreteFun(alloc, *it)),
		reprOfConcreteFunRef(alloc, *a.rtMain),
		reprOfConcreteFunRef(alloc, *a.userMain)]);

private:

Repr reprOfConcreteStruct(ref Alloc alloc, in ConcreteStruct a) {
	ArrBuilder!NameAndRepr fields;
	add(alloc, fields, nameAndRepr!"name"(reprOfConcreteStructSource(alloc, a.source)));
	if (isSelfMutable(a))
		add(alloc, fields, nameAndRepr!"mut"(reprBool(true)));
	add(alloc, fields, nameAndRepr!"reference"(reprSym(symOfReferenceKind(defaultReferenceKind(a)))));
	add(alloc, fields, nameAndRepr!"body"(reprOfConcreteStructBody(alloc, body_(a))));
	return reprNamedRecord!"struct"(finishArr(alloc, fields));
}

Repr reprOfConcreteStructSource(ref Alloc alloc, in ConcreteStructSource a) =>
	a.matchIn!Repr(
		(in ConcreteStructSource.Inst it) =>
			reprSym(name(*it.inst)),
		(in ConcreteStructSource.Lambda it) =>
			reprRecord!"lambda"(alloc, [reprOfConcreteFunRef(alloc, *it.containingFun), reprNat(it.index)]));

public Repr reprOfConcreteStructRef(ref Alloc alloc, in ConcreteStruct a) =>
	reprOfConcreteStructSource(alloc, a.source);

Repr reprOfConcreteStructBody(ref Alloc alloc, in ConcreteStructBody a) =>
	a.matchIn!Repr(
		(in ConcreteStructBody.Builtin it) =>
			reprOfConcreteStructBodyBuiltin(alloc, it),
		(in ConcreteStructBody.Enum it) =>
			//TODO:MORE DETAIL
			reprSym!"enum",
		(in ConcreteStructBody.Extern) =>
			reprSym!"extern",
		(in ConcreteStructBody.Flags it) =>
			//TODO:MORE DETAIL
			reprSym!"flags" ,
		(in ConcreteStructBody.Record it) =>
			reprOfConcreteStructBodyRecord(alloc, it),
		(in ConcreteStructBody.Union it) =>
			reprOfConcreteStructBodyUnion(alloc, it));

Repr reprOfConcreteStructBodyBuiltin(ref Alloc alloc, in ConcreteStructBody.Builtin a) =>
	reprRecord!"builtin"(alloc, [
		reprSym(symOfBuiltinStructKind(a.kind)),
		reprArr!ConcreteType(alloc, a.typeArgs, (in ConcreteType it) =>
			reprOfConcreteType(alloc, it))]);

Repr reprOfConcreteType(ref Alloc alloc, in ConcreteType a) =>
	reprRecord!"type"(alloc, [
		reprSym(symOfReferenceKind(a.reference)),
		reprOfConcreteStructRef(alloc, *a.struct_)]);

Repr reprOfConcreteStructBodyRecord(ref Alloc alloc, in ConcreteStructBody.Record a) =>
	reprRecord!"record"(alloc, [reprArr!ConcreteField(alloc, a.fields, (in ConcreteField it) =>
		reprOfConcreteField(alloc, it))]);

Repr reprOfConcreteField(ref Alloc alloc, in ConcreteField a) =>
	reprRecord!"field"(alloc, [
		reprSym(a.debugName),
		reprSym(symOfConcreteMutability(a.mutability)),
		reprOfConcreteType(alloc, a.type)]);

Repr reprOfConcreteStructBodyUnion(ref Alloc alloc, in ConcreteStructBody.Union a) =>
	reprRecord!"union"(alloc, [reprArr!ConcreteType(alloc, a.members, (in ConcreteType x) =>
		reprOfConcreteType(alloc, x))]);

Repr reprOfConcreteFun(ref Alloc alloc, in ConcreteFun a) =>
	reprRecord!"fun"(alloc, [
		reprOfConcreteFunSource(alloc, a.source),
		reprOfConcreteType(alloc, a.returnType),
		reprArr!ConcreteLocal(alloc, a.paramsIncludingClosure, (in ConcreteLocal x) =>
			reprOfConcreteLocalDeclare(alloc, x)),
		reprOfConcreteFunBody(alloc, body_(a))]);

Repr reprOfConcreteFunSource(ref Alloc alloc, in ConcreteFunSource a) =>
	a.matchIn!Repr(
		(in FunInst it) =>
			reprSym(it.name),
		(in ConcreteFunSource.Lambda it) =>
			reprRecord!"lambda"(alloc, [
				reprOfConcreteFunRef(alloc, *it.containingFun),
				reprNat(it.index)]),
		(in ConcreteFunSource.Test) =>
			reprSym!"test");

public Repr reprOfConcreteFunRef(ref Alloc alloc, in ConcreteFun a) =>
	reprOfConcreteFunSource(alloc, a.source);

Repr reprOfConcreteFunBody(ref Alloc alloc, in ConcreteFunBody a) =>
	a.matchIn!Repr(
		(in ConcreteFunBody.Builtin x) =>
			reprOfConcreteFunBodyBuiltin(alloc, x),
		(in Constant x) =>
			reprRecord!"constant"(alloc, [reprOfConstant(alloc, x)]),
		(in ConcreteFunBody.CreateRecord) =>
			reprSym!"new-record" ,
		(in ConcreteFunBody.CreateUnion) =>
			//TODO: more detail
			reprSym!"new-union" ,
		(in EnumFunction x) =>
			reprRecord!"enum-fn"(alloc, [reprSym(enumFunctionName(x))]),
		(in ConcreteFunBody.Extern) =>
			reprSym!"extern" ,
		(in ConcreteExpr x) =>
			reprOfConcreteExpr(alloc, x),
		(in ConcreteFunBody.FlagsFn x) =>
			reprRecord!"flags-fn"(alloc, [
				reprNat(x.allValue),
				reprSym(flagsFunctionName(x.fn)),
			]),
		(in ConcreteFunBody.RecordFieldGet x) =>
			reprRecord!"field-get"(alloc, [reprNat(x.fieldIndex)]),
		(in ConcreteFunBody.RecordFieldSet x) =>
			reprRecord!"field-set"(alloc, [reprNat(x.fieldIndex)]),
		(in ConcreteFunBody.VarGet) =>
			reprSym!"var-get",
		(in ConcreteFunBody.VarSet) =>
			reprSym!"var-set");

Repr reprOfConcreteFunBodyBuiltin(ref Alloc alloc, in ConcreteFunBody.Builtin a) =>
	reprRecord!"builtin"(alloc, [reprArr!ConcreteType(alloc, a.typeArgs, (in ConcreteType it) =>
			reprOfConcreteType(alloc, it))]);

Repr reprOfConcreteLocalDeclare(ref Alloc alloc, in ConcreteLocal a) =>
	reprRecord!"local"(alloc, [
		reprSym(name(a.source)),
		reprOfConcreteType(alloc, a.type)]);

Repr reprOfConcreteLocalRef(in ConcreteLocal a) =>
	reprSym(name(a.source));

Sym name(in ConcreteLocalSource a) =>
	a.matchIn!Sym(
		(in Local x) =>
			x.name,
		(in ConcreteLocalSource.Closure) =>
			sym!"closure",
		(in ConcreteLocalSource.Generated x) =>
			x.name);

Repr reprOfConcreteExpr(ref Alloc alloc, in ConcreteExpr a) {
	// TODO: For brevity.. (change back once we have tail recursion and crow can handle long strings)
	return reprOfConcreteExprKind(alloc, a.kind);
	//return reprRecord!"expr"(alloc, [
	//	reprOfConcreteType(alloc, a.type),
	//	reprFileAndRange(alloc, a.range),
	//	reprOfConcreteExprKind(alloc, a)]);
}

Repr reprOfConcreteExprs(ref Alloc alloc, in ConcreteExpr[] a) =>
	reprArr!ConcreteExpr(alloc, a, (in ConcreteExpr x) =>
		reprOfConcreteExpr(alloc, x));

Repr reprOfConcreteExprKind(ref Alloc alloc, in ConcreteExprKind a) =>
	a.matchIn!Repr(
		(in ConcreteExprKind.Alloc it) =>
			reprRecord!"alloc"(alloc, [reprOfConcreteExpr(alloc, it.inner)]),
		(in ConcreteExprKind.Call it) =>
			reprRecord!"call"(alloc, [
				reprOfConcreteFunRef(alloc, *it.called),
				reprOfConcreteExprs(alloc, it.args)]),
		(in ConcreteExprKind.ClosureCreate it) =>
			todo!Repr("!"),
		(in ConcreteExprKind.ClosureGet it) =>
			reprRecord!"closure-get"(alloc, [
				reprConcreteClosureRef(alloc, it.closureRef),
				reprSym(symOfClosureReferenceKind(it.referenceKind))]),
		(in ConcreteExprKind.ClosureSet it) =>
			reprRecord!"closure-set"(alloc, [
				reprConcreteClosureRef(alloc, it.closureRef),
				reprOfConcreteExpr(alloc, it.value)]),
		(in ConcreteExprKind.Cond it) =>
			reprRecord!"cond"(alloc, [
				reprOfConcreteExpr(alloc, it.cond),
				reprOfConcreteExpr(alloc, it.then),
				reprOfConcreteExpr(alloc, it.else_)]),
		(in Constant it) =>
			reprOfConstant(alloc, it),
		(in ConcreteExprKind.CreateArr it) =>
			reprRecord!"create-arr"(alloc, [
				reprOfConcreteStructRef(alloc, *it.arrType),
				reprOfConcreteExprs(alloc, it.args)]),
		(in ConcreteExprKind.CreateRecord it) =>
			reprRecord!"record"(alloc, [reprOfConcreteExprs(alloc, it.args)]),
		(in ConcreteExprKind.CreateUnion it) =>
			reprRecord!"union"(alloc, [
				reprNat(it.memberIndex),
				reprOfConcreteExpr(alloc, it.arg)]),
		(in ConcreteExprKind.Drop it) =>
			reprRecord!"drop"(alloc, [reprOfConcreteExpr(alloc, it.arg)]),
		(in ConcreteExprKind.Lambda it) =>
			reprRecord!"lambda"(alloc, [
				reprNat(it.memberIndex),
				reprOpt!(ConcreteExpr*)(alloc, it.closure, (in ConcreteExpr* closure) =>
					reprOfConcreteExpr(alloc, *closure))]),
		(in ConcreteExprKind.Let it) =>
			reprRecord!"let"(alloc, [
				reprOfConcreteLocalDeclare(alloc, *it.local),
				reprOfConcreteExpr(alloc, it.value),
				reprOfConcreteExpr(alloc, it.then)]),
		(in ConcreteExprKind.LocalGet it) =>
			reprRecord!"local-get"(alloc, [reprOfConcreteLocalRef(*it.local)]),
		(in ConcreteExprKind.LocalSet it) =>
			reprRecord!"local-set"(alloc, [
				reprOfConcreteLocalRef(*it.local),
				reprOfConcreteExpr(alloc, it.value)]),
		(in ConcreteExprKind.Loop it) =>
			reprRecord!"loop"(alloc, [reprOfConcreteExpr(alloc, it.body_)]),
		(in ConcreteExprKind.LoopBreak it) =>
			reprRecord!"break"(alloc, [reprOfConcreteExpr(alloc, it.value)]),
		(in ConcreteExprKind.LoopContinue it) =>
			reprSym!"continue" ,
		(in ConcreteExprKind.MatchEnum it) =>
			reprRecord!"match-enum"(alloc, [
				reprOfConcreteExpr(alloc, it.matchedValue),
				reprOfConcreteExprs(alloc, it.cases)]),
		(in ConcreteExprKind.MatchUnion it) =>
			reprRecord!"match-union"(alloc, [
				reprOfConcreteExpr(alloc, it.matchedValue),
				reprArr!(ConcreteExprKind.MatchUnion.Case)(
					alloc,
					it.cases,
					(in ConcreteExprKind.MatchUnion.Case case_) =>
						reprRecord!"case"(alloc, [
							reprOpt!(ConcreteLocal*)(alloc, case_.local, (in ConcreteLocal* local) =>
								reprOfConcreteLocalDeclare(alloc, *local)),
							reprOfConcreteExpr(alloc, case_.then)]))]),
		(in ConcreteExprKind.PtrToField it) =>
			reprRecord!"ptr-to-field"(alloc, [reprOfConcreteExpr(alloc, it.target), reprNat(it.fieldIndex)]),
		(in ConcreteExprKind.PtrToLocal it) =>
			reprRecord!"ptr-to-local"(alloc, [reprOfConcreteLocalRef(*it.local)]),
		(in ConcreteExprKind.RecordFieldGet x) =>
			reprRecord!"field-get"(alloc, [
				reprOfConcreteExpr(alloc, *x.record),
				reprNat(x.fieldIndex)]),
		(in ConcreteExprKind.Seq it) =>
			reprRecord!"seq"(alloc, [reprOfConcreteExpr(alloc, it.first), reprOfConcreteExpr(alloc, it.then)]),
		(in ConcreteExprKind.Throw it) =>
			reprRecord!"throw"(alloc, [reprOfConcreteExpr(alloc, it.thrown)]));

Repr reprConcreteClosureRef(ref Alloc alloc, in ConcreteClosureRef a) =>
	reprRecord!"closure-ref"(alloc, [
		reprNat(a.fieldIndex)]);
