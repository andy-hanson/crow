module sexprOfConcreteModel;

@safe @nogc pure nothrow:

import concreteModel :
	body_,
	ConcreteExpr,
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
	matchConcreteExpr,
	matchConcreteFunBody,
	matchConcreteFunSource,
	matchConcreteLocalSource,
	matchConcreteParamSource,
	matchConcreteStructBody,
	matchConcreteStructSource,
	name,
	returnType,
	symOfBuiltinStructKind;
import model : FunInst, name, Local, Param;
import util.bools : True;
import util.collection.arrBuilder : add, ArrBuilder, finishArr;
import util.collection.str : strLiteral;
import util.opt : force, has;
import util.ptr : Ptr;
import util.sexpr :
	NameAndSexpr,
	nameAndTata,
	Sexpr,
	tataArr,
	tataBool,
	tataNamedRecord,
	tataNat,
	tataOpt,
	tataRecord,
	tataStr,
	tataSym;
import util.sourceRange : sexprOfFileAndRange;
import util.util : todo, unreachable;

immutable(Sexpr) tataOfConcreteProgram(Alloc)(ref Alloc alloc, ref immutable ConcreteProgram a) {
	return tataRecord(
		alloc,
		"program",
		tataArr(alloc, a.allStructs, (ref immutable Ptr!ConcreteStruct it) =>
			tataOfConcreteStruct(alloc, it)),
		tataArr(alloc, a.allFuns, (ref immutable Ptr!ConcreteFun it) =>
			tataOfConcreteFun(alloc, it)),
		tataOfConcreteFunRef(alloc, a.rtMain),
		tataOfConcreteFunRef(alloc, a.userMain),
		tataOfConcreteStructRef(alloc, a.ctxType));
}

private:

immutable(Sexpr) tataOfConcreteStruct(Alloc)(ref Alloc alloc, ref immutable ConcreteStruct a) {
	ArrBuilder!NameAndSexpr fields;
	add(alloc, fields, nameAndTata("name", tataOfConcreteStructSource(alloc, a.source)));
	if (isSelfMutable(a))
		add(alloc, fields, nameAndTata("mut?", tataBool(True)));
	if (defaultIsPointer(a))
		add(alloc, fields, nameAndTata("ptr?", tataBool(True)));
	add(alloc, fields, nameAndTata("body", tataOfConcreteStructBody(alloc, body_(a))));
	return tataNamedRecord("struct", finishArr(alloc, fields));
}

immutable(Sexpr) tataOfConcreteStructSource(Alloc)(ref Alloc alloc, ref immutable ConcreteStructSource a) {
	return matchConcreteStructSource!(immutable Sexpr)(
		a,
		(ref immutable ConcreteStructSource.Inst it) =>
			tataSym(name(it.inst)),
		(ref immutable ConcreteStructSource.Lambda it) =>
			tataRecord(alloc, "lambda", tataOfConcreteFunRef(alloc, it.containingFun), tataNat(it.index)));
}

public immutable(Sexpr) tataOfConcreteStructRef(Alloc)(ref Alloc alloc, immutable Ptr!ConcreteStruct a) {
	return tataOfConcreteStructSource(alloc, a.source);
}

immutable(Sexpr) tataOfSpecialStructInfo(Alloc)(ref Alloc alloc, ref immutable SpecialStructInfo a) {
	return tataRecord(
		alloc,
		"special",
		tataSym(() {
			final switch (a.kind) {
				case SpecialStructInfo.Kind.arr:
					return "arr";
			}
		}()),
		tataOfConcreteType(alloc, a.elementType));
}

immutable(Sexpr) tataOfConcreteStructBody(Alloc)(ref Alloc alloc, ref immutable ConcreteStructBody a) {
	return matchConcreteStructBody(
		a,
		(ref immutable ConcreteStructBody.Builtin it) =>
			tataOfConcreteStructBodyBuiltin(alloc, it),
		(ref immutable ConcreteStructBody.ExternPtr it) =>
			tataSym("extern-ptr"),
		(ref immutable ConcreteStructBody.Record it) =>
			tataOfConcreteStructBodyRecord(alloc, it),
		(ref immutable ConcreteStructBody.Union it) =>
			tataOfConcreteStructBodyUnion(alloc, it));
}

immutable(Sexpr) tataOfConcreteStructBodyBuiltin(Alloc)(ref Alloc alloc, ref immutable ConcreteStructBody.Builtin a) {
	return tataRecord(
		alloc,
		"builtin",
		tataSym(symOfBuiltinStructKind(a.kind)),
		tataArr(alloc, a.typeArgs, (ref immutable ConcreteType it) =>
			tataOfConcreteType(alloc, it)));
}

immutable(Sexpr) tataOfConcreteType(Alloc)(ref Alloc alloc, ref immutable ConcreteType a) {
	return tataRecord(
		alloc,
		"type",
		tataBool(a.isPointer),
		tataOfConcreteStructRef(alloc, a.struct_));
}

immutable(Sexpr) tataOfConcreteStructBodyRecord(Alloc)(ref Alloc alloc, ref immutable ConcreteStructBody.Record a) {
	return tataRecord(alloc, "record", tataArr(alloc, a.fields, (ref immutable ConcreteField it) =>
		tataOfConcreteField(alloc, it)));
}

immutable(Sexpr) tataOfConcreteField(Alloc)(ref Alloc alloc, ref immutable ConcreteField a) {
	return tataRecord(
		alloc,
		"field",
		tataSym(name(a)),
		tataBool(a.isMutable),
		tataOfConcreteType(alloc, a.type));
}

immutable(Sexpr) tataOfConcreteStructBodyUnion(Alloc)(ref Alloc alloc, ref immutable ConcreteStructBody.Union a) {
	return tataRecord(alloc, "union", tataArr(alloc, a.members, (ref immutable ConcreteType it) =>
		tataOfConcreteType(alloc, it)));
}

immutable(Sexpr) tataOfConcreteFun(Alloc)(ref Alloc alloc, ref immutable ConcreteFun a) {
	return tataRecord(
		alloc,
		"fun",
		tataBool(a.needsCtx),
		tataOfConcreteFunSource(alloc, a.source),
		tataOfConcreteType(alloc, a.returnType),
		tataOpt(alloc, a.closureParam, (ref immutable ConcreteParam it) =>
			tataOfParam(alloc, it)),
		tataArr(alloc, a.paramsExcludingCtxAndClosure, (ref immutable ConcreteParam it) =>
			tataOfParam(alloc, it)),
		tataOfConcreteFunBody(alloc, body_(a)));
}

immutable(Sexpr) tataOfConcreteFunSource(Alloc)(ref Alloc alloc, ref immutable ConcreteFunSource a) {
	return matchConcreteFunSource!(immutable Sexpr)(
		a,
		(immutable Ptr!FunInst it) =>
			tataSym(name(it)),
		(ref immutable ConcreteFunSource.Lambda it) =>
			tataRecord(
				alloc,
				"lambda",
				tataOfConcreteFunRef(alloc, it.containingFun),
				tataNat(it.index)));
}

public immutable(Sexpr) tataOfConcreteFunRef(Alloc)(ref Alloc alloc, immutable Ptr!ConcreteFun a) {
	return tataOfConcreteFunSource(alloc, a.source);
}

immutable(Sexpr) tataOfParam(Alloc)(ref Alloc alloc, ref immutable ConcreteParam a) {
	return tataRecord(
		alloc,
		"param",
		tataOfConcreteParamRef(a),
		tataOfConcreteType(alloc, a.type));
}

public immutable(Sexpr) tataOfConcreteParamRef(ref immutable ConcreteParam a) {
	return matchConcreteParamSource!(immutable Sexpr)(
		a.source,
		(ref immutable ConcreteParamSource.Closure) =>
			tataStr("<<closure>>"),
		(immutable Ptr!Param a) =>
			tataSym(a.name));
}

immutable(Sexpr) tataOfConcreteFunBody(Alloc)(ref Alloc alloc, ref immutable ConcreteFunBody a) {
	return matchConcreteFunBody!(immutable Sexpr)(
		a,
		(ref immutable ConcreteFunBody.Builtin it) =>
			tataOfConcreteFunBodyBuiltin(alloc, it),
		(ref immutable ConcreteFunBody.Extern it) =>
			tataRecord(alloc, "extern", tataBool(it.isGlobal)),
		(ref immutable ConcreteFunExprBody it) =>
			tataOfConcreteFunExprBody(alloc, it));
}

immutable(Sexpr) tataOfConcreteFunBodyBuiltin(Alloc)(ref Alloc alloc, ref immutable ConcreteFunBody.Builtin a) {
	return tataRecord(
		alloc,
		"builtin",
		tataArr(alloc, a.typeArgs, (ref immutable ConcreteType it) =>
			tataOfConcreteType(alloc, it)));
}

immutable(Sexpr) tataOfConcreteFunExprBody(Alloc)(ref Alloc alloc, ref immutable ConcreteFunExprBody a) {
	return tataRecord(
		alloc,
		"expr-body",
		tataArr(alloc, a.allLocals, (ref immutable Ptr!ConcreteLocal it) =>
			tataRecord(
				alloc,
				"local",
				tataOfConcreteLocalRef(it),
				tataOfConcreteType(alloc, it.type))),
		tataOfConcreteExpr(alloc, a.expr));
}

public immutable(Sexpr) tataOfConcreteLocalRef(immutable Ptr!ConcreteLocal a) {
	return matchConcreteLocalSource!(immutable Sexpr)(
		a.source,
		(ref immutable ConcreteLocalSource.Arr) =>
			tataStr("<<arr>>"),
		(immutable Ptr!Local it) =>
			tataSym(it.name),
		(ref immutable ConcreteLocalSource.Matched) =>
			tataStr("<<matched>>"));
}

immutable(Sexpr) tataOfConcreteExpr(Alloc)(ref Alloc alloc, ref immutable ConcreteExpr a) {
	// TODO: For brevity.. (change back once we have tail recursion and noze can handle long strings)
	return tataOfConcreteExprKind(alloc, a);
	//return tataRecord(
	//	alloc,
	//	"expr",
	//	tataOfConcreteType(alloc, a.type),
	//	sexprOfFileAndRange(alloc, a.range),
	//	tataOfConcreteExprKind(alloc, a));
}

immutable(Sexpr) tataOfConcreteExprKind(Alloc)(ref Alloc alloc, ref immutable ConcreteExpr a) {
	return matchConcreteExpr!(immutable Sexpr)(
		a,
		(ref immutable ConcreteExpr.Alloc it) =>
			tataRecord(
				alloc,
				"alloc",
				tataOfConcreteFunRef(alloc, it.alloc),
				tataOfConcreteExpr(alloc, it.inner)),
		(ref immutable ConcreteExpr.Call it) =>
			tataRecord(
				alloc,
				"call",
				tataOfConcreteFunRef(alloc, it.called),
				tataArr(alloc, it.args, (ref immutable ConcreteExpr arg) =>
					tataOfConcreteExpr(alloc, arg))),
		(ref immutable ConcreteExpr.Cond it) =>
			tataRecord(
				alloc,
				"cond",
				tataOfConcreteExpr(alloc, it.cond),
				tataOfConcreteExpr(alloc, it.then),
				tataOfConcreteExpr(alloc, it.else_)),
		(ref immutable ConcreteExpr.CreateArr it) =>
			tataRecord(
				alloc,
				"create-arr",
				tataOfConcreteStructRef(alloc, it.arrType),
				tataOfConcreteType(alloc, it.elementType),
				tataOfConcreteFunRef(alloc, it.alloc),
				tataOfConcreteLocalRef(it.local),
				tataArr(alloc, it.args, (ref immutable ConcreteExpr arg) =>
					tataOfConcreteExpr(alloc, arg))),
		(ref immutable ConcreteExpr.CreateRecord it) =>
			tataRecord(alloc, "record", tataArr(alloc, it.args, (ref immutable ConcreteExpr arg) =>
				tataOfConcreteExpr(alloc, arg))),
		(ref immutable ConcreteExpr.ConvertToUnion it) =>
			tataRecord(
				alloc,
				"to-union",
				tataNat(it.memberIndex),
				tataOfConcreteExpr(alloc, it.arg)),
		(ref immutable ConcreteExpr.Lambda it) =>
			tataRecord(
				alloc,
				"lambda",
				tataOfConcreteFunRef(alloc, it.fun),
				tataOpt(alloc, it.closure, (ref immutable Ptr!ConcreteExpr closure) =>
					tataOfConcreteExpr(alloc, closure))),
		(ref immutable ConcreteExpr.Let it) =>
			tataRecord(
				alloc,
				"let",
				tataOfConcreteLocalRef(it.local),
				tataOfConcreteExpr(alloc, it.value),
				tataOfConcreteExpr(alloc, it.then)),
		(ref immutable ConcreteExpr.LocalRef it) =>
			tataRecord(
				alloc,
				"local-ref",
				tataOfConcreteLocalRef(it.local)),
		(ref immutable ConcreteExpr.Match it) =>
			tataRecord(
				alloc,
				"match",
				tataOfConcreteLocalRef(it.matchedLocal),
				tataOfConcreteExpr(alloc, it.matchedValue),
				tataArr(alloc, it.cases, (ref immutable ConcreteExpr.Match.Case case_) =>
					tataRecord(
						alloc,
						"case",
						tataOpt(alloc, case_.local, (ref immutable Ptr!ConcreteLocal local) =>
							tataOfConcreteLocalRef(local)),
						tataOfConcreteExpr(alloc, case_.then)))),
		(ref immutable ConcreteExpr.ParamRef it) =>
			tataRecord(alloc, "param-ref", tataOfConcreteParamRef(it.param)),
		(ref immutable ConcreteExpr.RecordFieldAccess it) =>
			tataRecord(
				alloc,
				"get-field",
				tataOfConcreteExpr(alloc, it.target),
				tataSym(name(it.field))),
		(ref immutable ConcreteExpr.RecordFieldSet it) =>
			tataRecord(
				alloc,
				"set-field",
				tataOfConcreteExpr(alloc, it.target),
				tataSym(name(it.field)),
				tataOfConcreteExpr(alloc, it.value)),
		(ref immutable ConcreteExpr.Seq it) =>
			tataRecord(
				alloc,
				"seq",
				tataOfConcreteExpr(alloc, it.first),
				tataOfConcreteExpr(alloc, it.then)),
		(ref immutable ConcreteExpr.SpecialConstant it) =>
			tataRecord(
				alloc,
				"special",
				tataSym(() {
					final switch (it.kind) {
						case ConcreteExpr.SpecialConstant.Kind.one:
							return "one";
						case ConcreteExpr.SpecialConstant.Kind.zero:
							return "zero";
					}
				}())),
		(ref immutable ConcreteExpr.SpecialUnary it) =>
			tataRecord(
				alloc,
				"special",
				tataSym(() {
					final switch (it.kind) {
						case ConcreteExpr.SpecialUnary.Kind.deref:
							return "deref";
					}
				}()),
				tataOfConcreteExpr(alloc, it.arg)),
		(ref immutable ConcreteExpr.SpecialBinary it) =>
			tataRecord(
				alloc,
				"special",
				tataStr(strLiteral(() {
					final switch (it.kind) {
						case ConcreteExpr.SpecialBinary.Kind.eqNat64:
							return "eqNat64";
						case ConcreteExpr.SpecialBinary.Kind.less:
							return "less";
						case ConcreteExpr.SpecialBinary.Kind.or:
							return "or";
						case ConcreteExpr.SpecialBinary.Kind.wrapAddNat64:
							return "wrapAddNat64";
						case ConcreteExpr.SpecialBinary.Kind.wrapSubNat64:
							return "wrapSubNat64";
					}
				}())),
				tataOfConcreteExpr(alloc, it.left),
				tataOfConcreteExpr(alloc, it.right)),
		(ref immutable ConcreteExpr.StringLiteral it) =>
			tataRecord(alloc, "str-lit", tataStr(it.literal)));
}
