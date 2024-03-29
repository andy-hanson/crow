module model.jsonOfConcreteModel;

@safe @nogc pure nothrow:

import frontend.storage : LineAndColumnGetters;
import model.concreteModel :
	ConcreteClosureRef,
	ConcreteExpr,
	ConcreteExprKind,
	ConcreteField,
	ConcreteFun,
	ConcreteFunBody,
	ConcreteFunKey,
	ConcreteFunSource,
	ConcreteLocal,
	ConcreteLocalSource,
	ConcreteProgram,
	ConcreteStruct,
	ConcreteStructBody,
	ConcreteStructSource,
	ConcreteType,
	ConcreteVar,
	ConcreteVariableRef,
	returnType;
import model.constant : Constant;
import model.jsonOfConstant : jsonOfConstant;
import model.model : EnumFunction, Local;
import util.alloc.alloc : Alloc;
import util.integralValues : IntegralValue, IntegralValues;
import util.json :
	field, Json, jsonObject, optionalArrayField, optionalField, optionalFlagField, jsonList, jsonString, kindField;
import util.sourceRange : jsonOfLineAndColumnRange;
import util.symbol : Symbol, symbol, symbolOfEnum;
import util.util : stringOfEnum;

Json jsonOfConcreteProgram(ref Alloc alloc, in LineAndColumnGetters lcg, in ConcreteProgram a) {
	Ctx ctx = Ctx(lcg);
	return jsonObject(alloc, [
		field!"structs"(jsonList!(ConcreteStruct*)(alloc, a.allStructs, (in ConcreteStruct* x) =>
			jsonOfConcreteStruct(alloc, *x))),
		field!"vars"(jsonList!(ConcreteVar*)(alloc, a.allVars, (in ConcreteVar* x) =>
			jsonOfConcreteVar(alloc, *x))),
		field!"funs"(jsonList!(ConcreteFun*)(alloc, a.allFuns, (in ConcreteFun* x) =>
			jsonOfConcreteFun(alloc, ctx, *x))),
		field!"rt-main"(jsonOfConcreteFunRef(alloc, *a.rtMain)),
		field!"user-main"(jsonOfConcreteFunRef(alloc, *a.userMain))]);
}

private:

const struct Ctx {
	LineAndColumnGetters lineAndColumnGetters;
}

Json jsonOfConcreteStruct(ref Alloc alloc, in ConcreteStruct a) =>
	jsonObject(alloc, [
		field!"name"(jsonOfConcreteStructSource(alloc, a.source)),
		optionalFlagField!"mut"(a.isSelfMutable),
		field!"reference-kind"(stringOfEnum(a.defaultReferenceKind)),
		field!"body"(jsonOfConcreteStructBody(alloc, a.body_))]);

Json jsonOfConcreteStructSource(ref Alloc alloc, in ConcreteStructSource a) =>
	a.matchIn!Json(
		(in ConcreteStructSource.Bogus) =>
			jsonString!"BOGUS",
		(in ConcreteStructSource.Inst x) =>
			jsonString(x.inst.decl.name),
		(in ConcreteStructSource.Lambda x) =>
			jsonObject(alloc, [
				kindField!"lambda",
				field!"containing"(jsonOfConcreteFunRef(alloc, *x.containingFun)),
				field!"index"(x.index)]));

public Json jsonOfConcreteStructRef(ref Alloc alloc, in ConcreteStruct a) =>
	jsonOfConcreteStructSource(alloc, a.source);

Json jsonOfConcreteStructBody(ref Alloc alloc, in ConcreteStructBody a) =>
	a.matchIn!Json(
		(in ConcreteStructBody.Builtin x) =>
			jsonOfConcreteStructBodyBuiltin(alloc, x),
		(in ConcreteStructBody.Enum x) =>
			//TODO:MORE DETAIL
			jsonString!"enum",
		(in ConcreteStructBody.Extern) =>
			jsonString!"extern",
		(in ConcreteStructBody.Flags x) =>
			//TODO:MORE DETAIL
			jsonString!"flags" ,
		(in ConcreteStructBody.Record x) =>
			jsonOfConcreteStructBodyRecord(alloc, x),
		(in ConcreteStructBody.Union x) =>
			jsonOfConcreteStructBodyUnion(alloc, x));

Json jsonOfConcreteStructBodyBuiltin(ref Alloc alloc, in ConcreteStructBody.Builtin a) =>
	jsonObject(alloc, [
		kindField!"builtin",
		field!"name"(stringOfEnum(a.kind)),
		optionalArrayField!("type-args", ConcreteType)(alloc, a.typeArgs, (in ConcreteType x) =>
			jsonOfConcreteType(alloc, x))]);

Json jsonOfConcreteType(ref Alloc alloc, in ConcreteType a) =>
	jsonObject(alloc, [
		field!"reference-kind"(stringOfEnum(a.reference)),
		field!"struct"(jsonOfConcreteStructRef(alloc, *a.struct_))]);

Json jsonOfConcreteStructBodyRecord(ref Alloc alloc, in ConcreteStructBody.Record a) =>
	jsonObject(alloc, [
		kindField!"record",
		field!"fields"(jsonList!ConcreteField(alloc, a.fields, (in ConcreteField x) =>
			jsonOfConcreteField(alloc, x)))]);

Json jsonOfConcreteField(ref Alloc alloc, in ConcreteField a) =>
	jsonObject(alloc, [
		field!"name"(a.debugName),
		field!"mutability"(stringOfEnum(a.mutability)),
		field!"type"(jsonOfConcreteType(alloc, a.type))]);

Json jsonOfConcreteStructBodyUnion(ref Alloc alloc, in ConcreteStructBody.Union a) =>
	jsonObject(alloc, [
		kindField!"union",
		field!"members"(jsonList!ConcreteType(alloc, a.members, (in ConcreteType x) =>
			jsonOfConcreteType(alloc, x)))]);

Json jsonOfConcreteVar(ref Alloc alloc, in ConcreteVar a) =>
	jsonObject(alloc, [
		field!"source"(a.source.name),
		field!"type"(jsonOfConcreteType(alloc, a.type))]);

Json jsonOfConcreteFun(ref Alloc alloc, in Ctx ctx, in ConcreteFun a) =>
	jsonObject(alloc, [
		field!"source"(jsonOfConcreteFunSource(alloc, a.source)),
		field!"return-type"(jsonOfConcreteType(alloc, a.returnType)),
		field!"params"(jsonList!ConcreteLocal(alloc, a.paramsIncludingClosure, (in ConcreteLocal x) =>
			jsonOfConcreteLocalDeclare(alloc, x))),
		field!"body"(jsonOfConcreteFunBody(alloc, ctx, a.body_))]);

Json jsonOfConcreteFunSource(ref Alloc alloc, in ConcreteFunSource a) =>
	a.matchIn!Json(
		(in ConcreteFunKey x) =>
			jsonString(x.decl.name),
		(in ConcreteFunSource.Lambda x) =>
			jsonObject(alloc, [
				kindField!"lambda",
				field!"containing"(jsonOfConcreteFunRef(alloc, *x.containingFun)),
				field!"index"(x.index)]),
		(in ConcreteFunSource.Test) =>
			jsonString!"test",
		(in ConcreteFunSource.WrapMain) =>
			jsonString!"wrap-main");

public Json jsonOfConcreteFunRef(ref Alloc alloc, in ConcreteFun a) =>
	jsonOfConcreteFunSource(alloc, a.source);

Json jsonOfConcreteFunBody(ref Alloc alloc, in Ctx ctx, in ConcreteFunBody a) =>
	a.matchIn!Json(
		(in ConcreteFunBody.Builtin x) =>
			jsonOfConcreteFunBodyBuiltin(alloc, x),
		(in Constant x) =>
			jsonObject(alloc, [
				kindField!"constant",
				field!"value"(jsonOfConstant(alloc, x))]),
		(in ConcreteFunBody.CreateRecord) =>
			jsonString!"new-record",
		(in ConcreteFunBody.CreateUnion) =>
			//TODO: more detail
			jsonString!"new-union",
		(in EnumFunction x) =>
			jsonObject(alloc, [
				kindField!"enum-fn",
				field!"fn"(stringOfEnum(x))]),
		(in ConcreteFunBody.Extern) =>
			jsonString!"extern",
		(in ConcreteExpr x) =>
			jsonOfConcreteExpr(alloc, ctx, x),
		(in ConcreteFunBody.FlagsFn x) =>
			jsonObject(alloc, [
				kindField!"flags-fn",
				field!"all"(x.allValue),
				field!"name"(stringOfEnum(x.fn))]),
		(in ConcreteFunBody.RecordFieldCall x) =>
			jsonObject(alloc, [
				kindField!"field-call",
				field!"field-index"(x.fieldIndex),
				field!"caller"(jsonOfConcreteFunRef(alloc, *x.caller))]),
		(in ConcreteFunBody.RecordFieldGet x) =>
			jsonObject(alloc, [
				kindField!"field-get",
				field!"field-index"(x.fieldIndex)]),
		(in ConcreteFunBody.RecordFieldPointer x) =>
			jsonObject(alloc, [
				kindField!"field-pointer",
				field!"field-index"(x.fieldIndex)]),
		(in ConcreteFunBody.RecordFieldSet x) =>
			jsonObject(alloc, [
				kindField!"field-set",
				field!"field-index"(x.fieldIndex)]),
		(in ConcreteFunBody.VarGet) =>
			jsonString!"var-get",
		(in ConcreteFunBody.VarSet) =>
			jsonString!"var-set");

Json jsonOfConcreteFunBodyBuiltin(ref Alloc alloc, in ConcreteFunBody.Builtin a) =>
	jsonObject(alloc, [
		kindField!"builtin",
		optionalArrayField!("type-args", ConcreteType)(alloc, a.typeArgs, (in ConcreteType x) =>
			jsonOfConcreteType(alloc, x))]);

Json jsonOfConcreteLocalDeclare(ref Alloc alloc, in ConcreteLocal a) =>
	jsonObject(alloc, [
		field!"name"(name(a.source)),
		field!"type"(jsonOfConcreteType(alloc, a.type))]);

Json jsonOfConcreteLocalRef(in ConcreteLocal a) =>
	jsonString(name(a.source));

Symbol name(in ConcreteLocalSource a) =>
	a.matchIn!Symbol(
		(in Local x) =>
			x.name,
		(in ConcreteLocalSource.Closure) =>
			symbol!"closure",
		(in ConcreteLocalSource.Generated x) =>
			symbolOfEnum(x));

Json jsonOfConcreteExpr(ref Alloc alloc, in Ctx ctx, in ConcreteExpr a) =>
	jsonObject(alloc, [
		field!"range"(jsonOfLineAndColumnRange(alloc, ctx.lineAndColumnGetters[a.range].range)),
		field!"type"(jsonOfConcreteType(alloc, a.type)),
		field!"expr-kind"(jsonOfConcreteExprKind(alloc, ctx, a.kind))]);

Json jsonOfConcreteExprs(ref Alloc alloc, in Ctx ctx, in ConcreteExpr[] a) =>
	jsonList!ConcreteExpr(alloc, a, (in ConcreteExpr x) =>
		jsonOfConcreteExpr(alloc, ctx, x));

Json jsonOfConcreteExprKind(ref Alloc alloc, in Ctx ctx, in ConcreteExprKind a) =>
	a.matchIn!Json(
		(in ConcreteExprKind.Alloc x) =>
			jsonObject(alloc, [
				kindField!"alloc",
				field!"arg"(jsonOfConcreteExpr(alloc, ctx, x.arg))]),
		(in ConcreteExprKind.Call x) =>
			jsonObject(alloc, [
				kindField!"call",
				field!"called"(jsonOfConcreteFunRef(alloc, *x.called)),
				field!"args"(jsonOfConcreteExprs(alloc, ctx, x.args))]),
		(in ConcreteExprKind.ClosureCreate x) =>
			jsonObject(alloc, [
				kindField!"new-closure",
				field!"args"(jsonList!ConcreteVariableRef(alloc, x.args, (in ConcreteVariableRef arg) =>
					jsonOfConcreteVariableRef(alloc, arg)))]),
		(in ConcreteExprKind.ClosureGet x) =>
			jsonObject(alloc, [
				kindField!"closure-get",
				field!"closure-ref"(jsonOfConcreteClosureRef(alloc, x.closureRef)),
				field!"reference-kind"(stringOfEnum(x.referenceKind))]),
		(in ConcreteExprKind.ClosureSet x) =>
			jsonObject(alloc, [
				kindField!"closure-set",
				field!"closure-ref"(jsonOfConcreteClosureRef(alloc, x.closureRef)),
				field!"value"(jsonOfConcreteExpr(alloc, ctx, x.value))]),
		(in Constant x) =>
			jsonObject(alloc, [
				kindField!"constant",
				field!"value"(jsonOfConstant(alloc, x))]),
		(in ConcreteExprKind.CreateArray x) =>
			jsonObject(alloc, [
				kindField!"create-array",
				field!"args"(jsonOfConcreteExprs(alloc, ctx, x.args))]),
		(in ConcreteExprKind.CreateRecord x) =>
			jsonObject(alloc, [
				kindField!"create-record",
				field!"args"(jsonOfConcreteExprs(alloc, ctx, x.args))]),
		(in ConcreteExprKind.CreateUnion x) =>
			jsonObject(alloc, [
				kindField!"create-union",
				field!"member-index"(x.memberIndex),
				field!"arg"(jsonOfConcreteExpr(alloc, ctx, x.arg))]),
		(in ConcreteExprKind.Drop x) =>
			jsonObject(alloc, [
				kindField!"drop",
				field!"arg"(jsonOfConcreteExpr(alloc, ctx, x.arg))]),
		(in ConcreteExprKind.If x) =>
			jsonObject(alloc, [
				kindField!"if",
				field!"condition"(jsonOfConcreteExpr(alloc, ctx, x.cond)),
				field!"then"(jsonOfConcreteExpr(alloc, ctx, x.then)),
				field!"else"(jsonOfConcreteExpr(alloc, ctx, x.else_))]),
		(in ConcreteExprKind.Lambda x) =>
			jsonObject(alloc, [
				kindField!"lambda",
				field!"member-index"(x.memberIndex),
				optionalField!("closure", ConcreteExpr*)(x.closure, (in ConcreteExpr* closure) =>
					jsonOfConcreteExpr(alloc, ctx, *closure))]),
		(in ConcreteExprKind.Let x) =>
			jsonObject(alloc, [
				kindField!"let",
				field!"local"(jsonOfConcreteLocalDeclare(alloc, *x.local)),
				field!"value"(jsonOfConcreteExpr(alloc, ctx, x.value)),
				field!"then"(jsonOfConcreteExpr(alloc, ctx, x.then))]),
		(in ConcreteExprKind.LocalGet x) =>
			jsonObject(alloc, [
				kindField!"local-get",
				field!"local"(jsonOfConcreteLocalRef(*x.local))]),
		(in ConcreteExprKind.LocalSet x) =>
			jsonObject(alloc, [
				kindField!"local-set",
				field!"local"(jsonOfConcreteLocalRef(*x.local)),
				field!"value"(jsonOfConcreteExpr(alloc, ctx, x.value))]),
		(in ConcreteExprKind.Loop x) =>
			jsonObject(alloc, [
				kindField!"loop",
				field!"body"(jsonOfConcreteExpr(alloc, ctx, x.body_))]),
		(in ConcreteExprKind.LoopBreak x) =>
			jsonObject(alloc, [
				kindField!"break",
				field!"value"(jsonOfConcreteExpr(alloc, ctx, x.value))]),
		(in ConcreteExprKind.LoopContinue x) =>
			jsonObject(alloc, [kindField!"continue"]),
		(in ConcreteExprKind.MatchEnumOrIntegral x) =>
			jsonObject(alloc, [
				kindField!"match-integral",
				field!"value"(jsonOfConcreteExpr(alloc, ctx, x.matched)),
				field!"case-values"(jsonOfIntegralValues(alloc, x.caseValues)),
				field!"case-exprs"(jsonOfConcreteExprs(alloc, ctx, x.caseExprs)),
				optionalField!("else", immutable ConcreteExpr*)(x.else_, (in immutable ConcreteExpr* else_) =>
					jsonOfConcreteExpr(alloc, ctx, *else_))]),
		(in ConcreteExprKind.MatchStringLike x) =>
			jsonObject(alloc, [
				kindField!"match-string-like",
				field!"value"(jsonOfConcreteExpr(alloc, ctx, x.matched)),
				field!"cases"(jsonList!(ConcreteExprKind.MatchStringLike.Case)(
					alloc,
					x.cases,
					(in ConcreteExprKind.MatchStringLike.Case case_) =>
						jsonObject(alloc, [
							field!"value"(jsonOfConcreteExpr(alloc, ctx, case_.value)),
							field!"then"(jsonOfConcreteExpr(alloc, ctx, case_.then))]))),
				field!"else"(jsonOfConcreteExpr(alloc, ctx, x.else_))]),
		(in ConcreteExprKind.MatchUnion x) =>
			jsonObject(alloc, [
				kindField!"match-union",
				field!"value"(jsonOfConcreteExpr(alloc, ctx, x.matched)),
				field!"cases"(jsonList!(ConcreteExprKind.MatchUnion.Case)(
					alloc,
					x.cases,
					(in ConcreteExprKind.MatchUnion.Case case_) =>
						jsonObject(alloc, [
							optionalField!("local", ConcreteLocal*)(case_.local, (in ConcreteLocal* local) =>
								jsonOfConcreteLocalDeclare(alloc, *local)),
							field!"then"(jsonOfConcreteExpr(alloc, ctx, case_.then))])))]),
		(in ConcreteExprKind.PtrToField x) =>
			jsonObject(alloc, [
				kindField!"pointer-to-field",
				field!"target"(jsonOfConcreteExpr(alloc, ctx, x.target)),
				field!"field-index"(x.fieldIndex)]),
		(in ConcreteExprKind.PtrToLocal x) =>
			jsonObject(alloc, [
				kindField!"pointer-to-local",
				field!"local"(jsonOfConcreteLocalRef(*x.local))]),
		(in ConcreteExprKind.RecordFieldGet x) =>
			jsonObject(alloc, [
				kindField!"field-get",
				field!"record"(jsonOfConcreteExpr(alloc, ctx, *x.record)),
				field!"field-index"(x.fieldIndex)]),
		(in ConcreteExprKind.Seq x) =>
			jsonObject(alloc, [
				kindField!"seq",
				field!"first"(jsonOfConcreteExpr(alloc, ctx, x.first)),
				field!"then"(jsonOfConcreteExpr(alloc, ctx, x.then))]),
		(in ConcreteExprKind.Throw x) =>
			jsonObject(alloc, [
				kindField!"throw",
				field!"thrown"(jsonOfConcreteExpr(alloc, ctx, x.thrown))]),
		(in ConcreteExprKind.UnionAs x) =>
			jsonObject(alloc, [
				kindField!"union-as",
				field!"union"(jsonOfConcreteExpr(alloc, ctx, *x.union_)),
				field!"member-index"(x.memberIndex)]),
		(in ConcreteExprKind.UnionKind x) =>
			jsonObject(alloc, [
				kindField!"union-kind",
				field!"union"(jsonOfConcreteExpr(alloc, ctx, *x.union_))]));

Json jsonOfConcreteClosureRef(ref Alloc alloc, in ConcreteClosureRef a) =>
	jsonObject(alloc, [field!"field-index"(a.fieldIndex)]);

Json jsonOfConcreteVariableRef(ref Alloc alloc, in ConcreteVariableRef a) =>
	a.matchIn!Json(
		(in Constant x) =>
			jsonOfConstant(alloc, x),
		(in ConcreteLocal x) =>
			jsonOfConcreteLocalRef(x),
		(in ConcreteClosureRef x) =>
			jsonOfConcreteClosureRef(alloc, x));

public Json jsonOfIntegralValues(ref Alloc alloc, in IntegralValues a) =>
	a.isRange0ToN
		? Json(a.length)
		: jsonList!IntegralValue(alloc, a, (in IntegralValue x) =>
			Json(x.value));
