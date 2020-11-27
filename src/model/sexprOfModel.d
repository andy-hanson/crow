module model.sexprOfModel;

@safe @nogc pure nothrow:

import model.model :
	body_,
	Called,
	ClosureField,
	decl,
	Expr,
	FunBody,
	FunDecl,
	FunInst,
	FunKind,
	Local,
	matchCalled,
	matchExpr,
	matchFunBody,
	matchType,
	Module,
	ModuleAndNameReferents,
	name,
	NameAndReferents,
	noCtx,
	Param,
	Purity,
	Sig,
	SpecDecl,
	specImpls,
	SpecInst,
	specs,
	SpecSig,
	StructDecl,
	StructInst,
	summon,
	symOfPurity,
	trusted,
	Type,
	typeArgs,
	TypeParam,
	typeParams,
	unsafe;
import util.bools : True;
import util.collection.arr : Arr, empty;
import util.collection.arrBuilder : add, ArrBuilder, finishArr;
import util.collection.arrUtil : arrLiteral, map;
import util.ptr : Ptr, ptrTrustMe;
import util.sexpr :
	nameAndTata,
	NameAndSexpr,
	Sexpr,
	tataArr,
	tataBool,
	tataNamedRecord,
	tataNat,
	tataOpt,
	tataRecord,
	tataStr,
	tataSym;
import util.sourceRange : sexprOfFileAndPos, sexprOfFileAndRange;
import util.sym : shortSymAlphaLiteral, Sym;
import util.util : todo;

immutable(Sexpr) sexprOfModule(Alloc)(ref Alloc alloc, ref immutable Module a) {
	Ctx ctx = Ctx(ptrTrustMe(a));
	return tataNamedRecord(
		"module",
		arrLiteral!NameAndSexpr(alloc, [
			nameAndTata("path", tataNat(a.fileIndex.index)),
			nameAndTata("imports", tataArr(alloc, a.imports, (ref immutable ModuleAndNameReferents m) =>
				sexprOfModuleAndNameReferents(alloc, m))),
			nameAndTata("exports", tataArr(alloc, a.exports, (ref immutable ModuleAndNameReferents m) =>
				sexprOfModuleAndNameReferents(alloc, m))),
			nameAndTata("structs", tataArr(alloc, a.structs, (ref immutable StructDecl s) =>
				sexprOfStructDecl(alloc, ctx, s))),
			nameAndTata("specs", tataArr(alloc, a.specs, (ref immutable SpecDecl s) =>
				sexprOfSpecDecl(alloc, ctx, s))),
			nameAndTata("funs", tataArr(alloc, a.funs, (ref immutable FunDecl f) =>
				sexprOfFunDecl(alloc, ctx, f)))]));
}

private:

immutable(Sexpr) sexprOfModuleAndNameReferents(Alloc)(ref Alloc alloc, ref immutable ModuleAndNameReferents a) {
	return tataRecord(alloc, "import", [
		tataNat(a.module_.fileIndex.index),
		tataOpt(alloc, a.namesAndReferents, (ref immutable Arr!NameAndReferents names) =>
			tataArr(alloc, names, (ref immutable NameAndReferents nr) =>
				tataSym(nr.name)))]);
}

struct Ctx {
	immutable Ptr!Module curModule;
}

immutable(Sexpr) sexprOfStructDecl(Alloc)(ref Alloc alloc, ref Ctx ctx, ref immutable StructDecl a) {
	ArrBuilder!NameAndSexpr fields;
	add(alloc, fields, nameAndTata("range", sexprOfFileAndRange(alloc, a.range)));
	add(alloc, fields, nameAndTata("public?", tataBool(a.isPublic)));
	add(alloc, fields, nameAndTata("name", tataSym(a.name)));
	if (!empty(typeParams(a)))
		add(alloc, fields, nameAndTata("typeparams", tataArr(alloc, typeParams(a), (ref immutable TypeParam it) =>
			sexprOfTypeParam(alloc, it))));
	if (a.purity != Purity.data)
		add(alloc, fields, nameAndTata("purity", tataSym(symOfPurity(a.purity))));
	if (a.purityIsForced)
		add(alloc, fields, nameAndTata("forced", tataBool(True)));
	return tataNamedRecord("struct", finishArr(alloc, fields));
}

immutable(Sexpr) sexprOfSpecDecl(Alloc)(ref Alloc alloc, ref Ctx ctx, ref immutable SpecDecl a) {
	return todo!(immutable Sexpr)("sexprOfSpecDecl");
}

immutable(Sexpr) sexprOfFunDecl(Alloc)(ref Alloc alloc, ref Ctx ctx, ref immutable FunDecl a) {
	ArrBuilder!NameAndSexpr fields;
	add(alloc, fields, nameAndTata("public?", tataBool(a.isPublic)));
	if (noCtx(a))
		add(alloc, fields, nameAndTata("no-ctx", tataBool(True)));
	if (summon(a))
		add(alloc, fields, nameAndTata("summon", tataBool(True)));
	if (unsafe(a))
		add(alloc, fields, nameAndTata("unsafe", tataBool(True)));
	if (trusted(a))
		add(alloc, fields, nameAndTata("trusted", tataBool(True)));
	if (a.flags.preferred)
		add(alloc, fields, nameAndTata("preferred", tataBool(True)));
	add(alloc, fields, nameAndTata("sig", sexprOfSig(alloc, ctx, a.sig)));
	if (!empty(typeParams(a)))
		add(alloc, fields, nameAndTata("typeparams", tataArr(alloc, typeParams(a), (ref immutable TypeParam it) =>
			sexprOfTypeParam(alloc, it))));
	if (!empty(specs(a)))
		add(alloc, fields, nameAndTata("specs", tataArr(alloc, specs(a), (ref immutable Ptr!SpecInst it) =>
			sexprOfSpecInst(alloc, ctx, it))));
	add(alloc, fields, nameAndTata("body", sexprOfFunBody(alloc, ctx, a.body_)));
	return tataNamedRecord("fun", finishArr(alloc, fields));
}

immutable(Sexpr) sexprOfTypeParam(Alloc)(ref Alloc alloc, ref immutable TypeParam a) {
	return todo!(immutable Sexpr)("sexprOfTypeParam");
}

immutable(Sexpr) sexprOfSig(Alloc)(ref Alloc alloc, ref Ctx ctx, ref immutable Sig a) {
	return tataRecord(alloc, "sig", [
		sexprOfFileAndPos(alloc, a.fileAndPos),
		tataSym(a.name),
		sexprOfType(alloc, ctx, a.returnType),
		tataArr(alloc, a.params, (ref immutable Param it) =>
			sexprOfParam(alloc, ctx, it))]);
}

immutable(Sexpr) sexprOfParam(Alloc)(ref Alloc alloc, ref Ctx ctx, ref immutable Param a) {
	return tataRecord(alloc, "param", [
		sexprOfFileAndRange(alloc, a.range),
		tataSym(a.name),
		sexprOfType(alloc, ctx, a.type)]);
}

immutable(Sexpr) sexprOfSpecInst(Alloc)(ref Alloc alloc, ref Ctx ctx, ref immutable SpecInst a) {
	return todo!(immutable Sexpr)("sexprOfSpecInst");
}

immutable(Sexpr) sexprOfFunBody(Alloc)(ref Alloc alloc, ref Ctx ctx, ref immutable FunBody a) {
	return matchFunBody!(immutable Sexpr)(
		a,
		(ref immutable FunBody.Builtin) =>
			tataSym("builtin"),
		(ref immutable FunBody.CreateRecord) =>
			tataSym("new-record"),
		(ref immutable FunBody.Extern it) =>
			tataRecord(alloc, "extern", [tataBool(it.isGlobal), tataStr(it.externName)]),
		(immutable Ptr!Expr it) =>
			sexprOfExpr(alloc, ctx, it));
}

immutable(Sexpr) sexprOfType(Alloc)(ref Alloc alloc, ref Ctx ctx, ref immutable Type t) {
	return matchType!(immutable Sexpr)(
		t,
		(ref immutable Type.Bogus) =>
			tataSym("bogus"),
		(immutable Ptr!TypeParam p) =>
			tataRecord(alloc, "?", [tataSym(p.name)]),
		(immutable Ptr!StructInst a) =>
			sexprOfStructInst(alloc, ctx, a));
}

immutable(Sexpr) sexprOfStructInst(Alloc)(ref Alloc alloc, ref Ctx ctx, immutable Ptr!StructInst a) {
	return tataRecord(
		a.declAndArgs.decl.name,
		map(alloc, a.declAndArgs.typeArgs, (ref immutable Type it) =>
			sexprOfType(alloc, ctx, it)));
}

immutable(Sexpr) sexprOfExpr(Alloc)(ref Alloc alloc, ref Ctx ctx, ref immutable Expr expr) {
	return matchExpr(
		expr,
		(ref immutable Expr.Bogus) =>
			tataSym("bogus"),
		(ref immutable Expr.Call e) =>
			tataRecord(alloc, "call", [
				sexprOfCalled(alloc, ctx, e.called),
				tataArr(alloc, e.args, (ref immutable Expr arg) =>
					sexprOfExpr(alloc, ctx, arg))]),
		(ref immutable Expr.ClosureFieldRef a) =>
			tataRecord(alloc, "closure-rf", [tataSym(a.field.name)]),
		(ref immutable Expr.Cond) =>
			todo!(immutable Sexpr)("cond"),
		(ref immutable Expr.CreateArr it) =>
			tataRecord(alloc, "create-arr", [
				sexprOfStructInst(alloc, ctx, it.arrType),
				tataArr(alloc, it.args, (ref immutable Expr arg) =>
					sexprOfExpr(alloc, ctx, arg))]),
		(ref immutable Expr.ImplicitConvertToUnion e) =>
			tataRecord(alloc, "to-union", [
				sexprOfStructInst(alloc, ctx, e.unionType),
				tataNat(e.memberIndex),
				sexprOfExpr(alloc, ctx, e.inner)]),
		(ref immutable Expr.Lambda a) =>
			tataRecord(alloc, "lambda", [
				tataArr(alloc, a.params, (ref immutable Param it) =>
					sexprOfParam(alloc, ctx, it)),
				sexprOfExpr(alloc, ctx, a.body_),
				tataArr(alloc, a.closure, (ref immutable Ptr!ClosureField it) =>
					sexprOfClosureField(alloc, ctx, it)),
				sexprOfStructInst(alloc, ctx, a.type),
				tataSym(symOfFunKind(a.kind)),
				sexprOfType(alloc, ctx, a.returnType)]),
		(ref immutable Expr.Let it) =>
			tataRecord(alloc, "let", [
				sexprOfLocal(alloc, ctx, it.local),
				sexprOfExpr(alloc, ctx, it.value),
				sexprOfExpr(alloc, ctx, it.then)]),
		(ref immutable Expr.LocalRef it) =>
			tataRecord(alloc, "local-ref", [tataSym(it.local.name)]),
		(ref immutable Expr.Match a) =>
			tataRecord(alloc, "match", [
				sexprOfExpr(alloc, ctx, a.matched),
				sexprOfStructInst(alloc, ctx, a.matchedUnion),
				tataArr(alloc, a.cases, (ref immutable Expr.Match.Case case_) =>
					sexprOfMatchCase(alloc, ctx, case_))]),
		(ref immutable Expr.ParamRef it) =>
			tataRecord(alloc, "param-ref", [tataSym(it.param.name)]),
		(ref immutable Expr.RecordFieldAccess a) =>
			tataRecord(alloc, "field-acc", [
				sexprOfExpr(alloc, ctx, a.target),
				sexprOfStructInst(alloc, ctx, a.targetType),
				tataSym(a.field.name)]),
		(ref immutable Expr.RecordFieldSet) =>
			todo!(immutable Sexpr)("recordfieldset"),
		(ref immutable Expr.Seq a) =>
			tataRecord(alloc, "seq", [
				sexprOfExpr(alloc, ctx, a.first),
				sexprOfExpr(alloc, ctx, a.then)]),
		(ref immutable Expr.StringLiteral it) =>
			tataRecord(alloc, "string-lit", [tataStr(it.literal)]));
}

immutable(Sexpr) sexprOfClosureField(Alloc)(ref Alloc alloc, ref Ctx ctx, ref immutable ClosureField a) {
	return tataRecord(alloc, "closure-f", [
		tataSym(a.name),
		sexprOfType(alloc, ctx, a.type),
		sexprOfExpr(alloc, ctx, a.expr)]);
}

immutable(Sym) symOfFunKind(immutable FunKind a) {
	final switch (a) {
		case FunKind.ptr:
			return shortSymAlphaLiteral("ptr");
		case FunKind.plain:
			return shortSymAlphaLiteral("plain");
		case FunKind.mut:
			return shortSymAlphaLiteral("mut");
		case FunKind.ref_:
			return shortSymAlphaLiteral("ref");
	}
}

immutable(Sexpr) sexprOfMatchCase(Alloc)(ref Alloc alloc, ref Ctx ctx, ref immutable Expr.Match.Case a) {
	return tataRecord(alloc, "case", [
		tataOpt(alloc, a.local, (ref immutable Ptr!Local local) =>
			sexprOfLocal(alloc, ctx, local)),
		sexprOfExpr(alloc, ctx, a.then)]);
}

immutable(Sexpr) sexprOfLocal(Alloc)(ref Alloc alloc, ref Ctx ctx, ref immutable Local a) {
	return tataRecord(alloc, "local", [
		sexprOfFileAndRange(alloc, a.range),
		tataSym(a.name),
		sexprOfType(alloc, ctx, a.type)]);
}

immutable(Sexpr) sexprOfCalled(Alloc)(ref Alloc alloc, ref Ctx ctx, ref immutable Called a) {
	return matchCalled(
		a,
		(immutable Ptr!FunInst it) =>
			sexprOfFunInst(alloc, ctx, it),
		(ref immutable SpecSig it) =>
			sexprOfSpecSig(alloc, ctx, it));
}

immutable(Sexpr) sexprOfFunInst(Alloc)(ref Alloc alloc, ref Ctx ctx, ref immutable FunInst a) {
	ArrBuilder!NameAndSexpr args;
	add(alloc, args, nameAndTata("name", tataSym(name(decl(a).deref))));
	if (!empty(typeArgs(a)))
		add(alloc, args, nameAndTata("type-args", tataArr(alloc, typeArgs(a), (ref immutable Type it) =>
			sexprOfType(alloc, ctx, it))));
	if (!empty(specImpls(a)))
		add(alloc, args, nameAndTata("spec-impls", tataArr(alloc, specImpls(a), (ref immutable Called it) =>
			sexprOfCalled(alloc, ctx, it))));
	return tataNamedRecord("fun-inst", finishArr(alloc, args));
}

immutable(Sexpr) sexprOfSpecSig(Alloc)(ref Alloc alloc, ref Ctx ctx, ref immutable SpecSig a) {
	return tataRecord(alloc, "spec-sig", [tataSym(name(a.specInst)), tataSym(a.sig.name)]);
}
