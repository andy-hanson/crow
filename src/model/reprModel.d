module model.reprModel;

@safe @nogc pure nothrow:

import model.model :
	body_,
	Called,
	ClosureField,
	decl,
	EnumFunction,
	enumFunctionName,
	Expr,
	FlagsFunction,
	flagsFunctionName,
	FunBody,
	FunDecl,
	FunInst,
	FunKind,
	Local,
	matchCalled,
	matchExpr,
	matchFunBody,
	matchParams,
	matchType,
	Module,
	ModuleAndNames,
	name,
	noCtx,
	Param,
	Params,
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
	symOfVisibility,
	trusted,
	Type,
	typeArgs,
	TypeParam,
	typeParams,
	unsafe,
	Visibility;
import model.reprConstant : reprOfConstant;
import util.alloc.alloc : Alloc;
import util.collection.arr : empty;
import util.collection.arrBuilder : add, ArrBuilder, finishArr;
import util.collection.arrUtil : map;
import util.collection.str : safeCStrIsEmpty;
import util.opt : force;
import util.ptr : Ptr, ptrTrustMe;
import util.repr :
	nameAndRepr,
	NameAndRepr,
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
import util.sourceRange : RangeWithinFile, reprFileAndPos, reprFileAndRange, reprRangeWithinFile;
import util.sym : shortSymAlphaLiteral, Sym;
import util.util : todo;

immutable(Repr) reprModule(ref Alloc alloc, ref immutable Module a) {
	Ctx ctx = Ctx(ptrTrustMe(a));
	ArrBuilder!NameAndRepr fields;
	add(alloc, fields, nameAndRepr("path", reprNat(a.fileIndex.index)));
	if (!safeCStrIsEmpty(a.docComment))
		add(alloc, fields, nameAndRepr("doc", reprStr(a.docComment)));
	if (!empty(a.imports))
		add(alloc, fields, nameAndRepr("imports", reprArr(alloc, a.imports, (ref immutable ModuleAndNames m) =>
			reprModuleAndNames(alloc, m))));
	if (!empty(a.exports))
		add(alloc, fields, nameAndRepr("exports", reprArr(alloc, a.exports, (ref immutable ModuleAndNames m) =>
			reprModuleAndNames(alloc, m))));
	if (!empty(a.structs))
		add(alloc, fields, nameAndRepr("structs", reprArr(alloc, a.structs, (ref immutable StructDecl s) =>
			reprStructDecl(alloc, ctx, s))));
	if (!empty(a.specs))
		add(alloc, fields, nameAndRepr("specs", reprArr(alloc, a.specs, (ref immutable SpecDecl s) =>
			reprSpecDecl(alloc, ctx, s))));
	if (!empty(a.funs))
		add(alloc, fields, nameAndRepr("funs", reprArr(alloc, a.funs, (ref immutable FunDecl f) =>
			reprFunDecl(alloc, ctx, f))));
	return reprNamedRecord("module", finishArr(alloc, fields));
}

private:

immutable(Repr) reprModuleAndNames(ref Alloc alloc, ref immutable ModuleAndNames a) {
	return reprRecord(alloc, "import", [
		reprOpt(alloc, a.importSource, (ref immutable RangeWithinFile it) =>
			reprRangeWithinFile(alloc, it)),
		reprNat(a.module_.fileIndex.index),
		reprOpt!(Sym[])(alloc, a.names, (ref immutable Sym[] names) =>
			reprArr(alloc, names, (ref immutable Sym name) =>
				reprSym(name)))]);
}

struct Ctx {
	immutable Ptr!Module curModule;
}

immutable(Repr) reprStructDecl(ref Alloc alloc, ref Ctx ctx, ref immutable StructDecl a) {
	ArrBuilder!NameAndRepr fields;
	add(alloc, fields, nameAndRepr("range", reprFileAndRange(alloc, a.range)));
	if (!safeCStrIsEmpty(a.docComment))
		add(alloc, fields, nameAndRepr("doc", reprStr(a.docComment)));
	add(alloc, fields, nameAndRepr("visibility", reprVisibility(a.visibility)));
	add(alloc, fields, nameAndRepr("name", reprSym(a.name)));
	if (!empty(typeParams(a)))
		add(alloc, fields, nameAndRepr("typeparams", reprArr(alloc, typeParams(a), (ref immutable TypeParam it) =>
			reprTypeParam(alloc, it))));
	if (a.purity != Purity.data)
		add(alloc, fields, nameAndRepr("purity", reprSym(symOfPurity(a.purity))));
	if (a.purityIsForced)
		add(alloc, fields, nameAndRepr("forced", reprBool(true)));
	return reprNamedRecord("struct", finishArr(alloc, fields));
}

immutable(Repr) reprSpecDecl(ref Alloc alloc, ref Ctx ctx, ref immutable SpecDecl a) {
	return todo!(immutable Repr)("reprSpecDecl");
}

immutable(Repr) reprFunDecl(ref Alloc alloc, ref Ctx ctx, ref immutable FunDecl a) {
	ArrBuilder!NameAndRepr fields;
	if (!safeCStrIsEmpty(a.docComment))
		add(alloc, fields, nameAndRepr("doc", reprStr(a.docComment)));
	add(alloc, fields, nameAndRepr("visibility", reprVisibility(a.visibility)));
	if (noCtx(a))
		add(alloc, fields, nameAndRepr("no-ctx", reprBool(true)));
	if (summon(a))
		add(alloc, fields, nameAndRepr("summon", reprBool(true)));
	if (unsafe(a))
		add(alloc, fields, nameAndRepr("unsafe", reprBool(true)));
	if (trusted(a))
		add(alloc, fields, nameAndRepr("trusted", reprBool(true)));
	if (a.flags.preferred)
		add(alloc, fields, nameAndRepr("preferred", reprBool(true)));
	add(alloc, fields, nameAndRepr("sig", reprSig(alloc, ctx, a.sig)));
	if (!empty(typeParams(a)))
		add(alloc, fields, nameAndRepr("typeparams", reprArr(alloc, typeParams(a), (ref immutable TypeParam it) =>
			reprTypeParam(alloc, it))));
	if (!empty(specs(a)))
		add(alloc, fields, nameAndRepr("specs", reprArr(alloc, specs(a), (ref immutable Ptr!SpecInst it) =>
			reprSpecInst(alloc, ctx, it))));
	add(alloc, fields, nameAndRepr("body", reprFunBody(alloc, ctx, a.body_)));
	return reprNamedRecord("fun", finishArr(alloc, fields));
}

immutable(Repr) reprTypeParam(ref Alloc alloc, immutable TypeParam a) {
	return todo!(immutable Repr)("reprTypeParam");
}

immutable(Repr) reprSig(ref Alloc alloc, ref Ctx ctx, ref immutable Sig a) {
	return reprRecord(alloc, "sig", [
		reprFileAndPos(alloc, a.fileAndPos),
		reprSym(a.name),
		reprType(alloc, ctx, a.returnType),
		matchParams!(immutable Repr)(
			a.params,
			(immutable Param[] params) =>
				reprArr(alloc, params, (ref immutable Param it) =>
					reprParam(alloc, ctx, it)),
			(ref immutable Params.Varargs v) =>
				reprRecord(alloc, "varargs", [reprParam(alloc, ctx, v.param)]))]);
}

immutable(Repr) reprParam(ref Alloc alloc, ref Ctx ctx, ref immutable Param a) {
	return reprRecord(alloc, "param", [
		reprFileAndRange(alloc, a.range),
		reprOpt(alloc, a.name, (ref immutable Sym it) =>
			reprSym(it)),
		reprType(alloc, ctx, a.type)]);
}

immutable(Repr) reprSpecInst(ref Alloc alloc, ref Ctx ctx, ref immutable SpecInst a) {
	return todo!(immutable Repr)("reprSpecInst");
}

immutable(Repr) reprFunBody(ref Alloc alloc, ref Ctx ctx, ref immutable FunBody a) {
	return matchFunBody!(immutable Repr)(
		a,
		(ref immutable FunBody.Builtin) =>
			reprSym("builtin"),
		(ref immutable FunBody.CreateEnum it) =>
			reprRecord(alloc, "new-enum", [reprInt(it.value.value)]),
		(ref immutable FunBody.CreateRecord) =>
			reprSym("new-record"),
		(ref immutable FunBody.CreateUnion) =>
			//TODO: more detail
			reprSym("new-union"),
		(immutable EnumFunction it) =>
			reprRecord(alloc, "enum-fn", [reprSym(enumFunctionName(it))]),
		(ref immutable FunBody.Extern it) =>
			reprRecord(alloc, "extern", [reprBool(it.isGlobal)]),
		(immutable Ptr!Expr it) =>
			reprExpr(alloc, ctx, it),
		(immutable FlagsFunction it) =>
			reprRecord(alloc, "flags-fn", [reprSym(flagsFunctionName(it))]),
		(ref immutable FunBody.RecordFieldGet it) =>
			reprRecord(alloc, "field-get", [reprNat(it.fieldIndex)]),
		(ref immutable FunBody.RecordFieldSet it) =>
			reprRecord(alloc, "field-set", [reprNat(it.fieldIndex)]));
}

immutable(Repr) reprType(ref Alloc alloc, ref Ctx ctx, immutable Type t) {
	return matchType!(immutable Repr)(
		t,
		(immutable Type.Bogus) =>
			reprSym("bogus"),
		(immutable Ptr!TypeParam p) =>
			reprRecord(alloc, "type-param", [reprSym(p.name)]),
		(immutable Ptr!StructInst a) =>
			reprStructInst(alloc, ctx, a));
}

immutable(Repr) reprStructInst(ref Alloc alloc, ref Ctx ctx, immutable Ptr!StructInst a) {
	return reprRecord(
		a.declAndArgs.decl.name,
		map(alloc, a.declAndArgs.typeArgs, (ref immutable Type it) =>
			reprType(alloc, ctx, it)));
}

immutable(Repr) reprExpr(ref Alloc alloc, ref Ctx ctx, ref immutable Expr expr) {
	return matchExpr!(immutable Repr)(
		expr,
		(ref immutable Expr.Bogus) =>
			reprSym("bogus"),
		(ref immutable Expr.Call e) =>
			reprRecord(alloc, "call", [
				reprCalled(alloc, ctx, e.called),
				reprArr(alloc, e.args, (ref immutable Expr arg) =>
					reprExpr(alloc, ctx, arg))]),
		(ref immutable Expr.ClosureFieldRef a) =>
			reprRecord(alloc, "closure-rf", [reprSym(a.field.name)]),
		(ref immutable Expr.Cond) =>
			todo!(immutable Repr)("cond"),
		(ref immutable Expr.FunPtr it) =>
			reprRecord(alloc, "fun-ptr", [
				reprFunInst(alloc, ctx, it.funInst),
				reprStructInst(alloc, ctx, it.structInst)]),
		(ref immutable Expr.IfOption it) =>
			reprRecord(alloc, "if", [
				reprExpr(alloc, ctx, it.option),
				reprLocal(alloc, ctx, it.local),
				reprExpr(alloc, ctx, it.then),
				reprExpr(alloc, ctx, it.else_)]),
		(ref immutable Expr.Lambda a) =>
			reprRecord(alloc, "lambda", [
				reprArr(alloc, a.params, (ref immutable Param it) =>
					reprParam(alloc, ctx, it)),
				reprExpr(alloc, ctx, a.body_),
				reprArr(alloc, a.closure, (ref immutable Ptr!ClosureField it) =>
					reprClosureField(alloc, ctx, it)),
				reprStructInst(alloc, ctx, a.type),
				reprSym(symOfFunKind(a.kind)),
				reprType(alloc, ctx, a.returnType)]),
		(ref immutable Expr.Let it) =>
			reprRecord(alloc, "let", [
				reprLocal(alloc, ctx, it.local),
				reprExpr(alloc, ctx, it.value),
				reprExpr(alloc, ctx, it.then)]),
		(ref immutable Expr.Literal it) =>
			reprRecord(alloc, "literal", [
				reprStructInst(alloc, ctx, it.structInst),
				reprOfConstant(alloc, it.value)]),
		(ref immutable Expr.LocalRef it) =>
			reprRecord(alloc, "local-ref", [reprSym(it.local.name)]),
		(ref immutable Expr.MatchEnum a) =>
			reprRecord(alloc, "match-enum", [
				reprExpr(alloc, ctx, a.matched),
				reprArr(alloc, a.cases, (ref immutable Expr case_) =>
					reprExpr(alloc, ctx, case_))]),
		(ref immutable Expr.MatchUnion a) =>
			reprRecord(alloc, "match-union", [
				reprExpr(alloc, ctx, a.matched),
				reprStructInst(alloc, ctx, a.matchedUnion),
				reprArr(alloc, a.cases, (ref immutable Expr.MatchUnion.Case case_) =>
					reprMatchUnionCase(alloc, ctx, case_))]),
		(ref immutable Expr.ParamRef it) =>
			reprRecord(alloc, "param-ref", [reprSym(force(it.param.name))]),
		(ref immutable Expr.Seq a) =>
			reprRecord(alloc, "seq", [
				reprExpr(alloc, ctx, a.first),
				reprExpr(alloc, ctx, a.then)]),
		(ref immutable Expr.StringLiteral it) =>
			reprRecord(alloc, "string-lit", [reprStr(it.literal)]),
		(ref immutable Expr.SymbolLiteral it) =>
			reprRecord(alloc, "sym-lit", [reprSym(it.value)]));
}

immutable(Repr) reprClosureField(ref Alloc alloc, ref Ctx ctx, ref immutable ClosureField a) {
	return reprRecord(alloc, "closure-f", [
		reprSym(a.name),
		reprType(alloc, ctx, a.type),
		reprExpr(alloc, ctx, a.expr)]);
}

immutable(Sym) symOfFunKind(immutable FunKind a) {
	final switch (a) {
		case FunKind.plain:
			return shortSymAlphaLiteral("plain");
		case FunKind.mut:
			return shortSymAlphaLiteral("mut");
		case FunKind.ref_:
			return shortSymAlphaLiteral("ref");
	}
}

immutable(Repr) reprMatchUnionCase(ref Alloc alloc, ref Ctx ctx, ref immutable Expr.MatchUnion.Case a) {
	return reprRecord(alloc, "case", [
		reprOpt(alloc, a.local, (ref immutable Ptr!Local local) =>
			reprLocal(alloc, ctx, local)),
		reprExpr(alloc, ctx, a.then)]);
}

immutable(Repr) reprLocal(ref Alloc alloc, ref Ctx ctx, ref immutable Local a) {
	return reprRecord(alloc, "local", [
		reprFileAndRange(alloc, a.range),
		reprSym(a.name),
		reprType(alloc, ctx, a.type)]);
}

immutable(Repr) reprCalled(ref Alloc alloc, ref Ctx ctx, ref immutable Called a) {
	return matchCalled(
		a,
		(immutable Ptr!FunInst it) =>
			reprFunInst(alloc, ctx, it),
		(ref immutable SpecSig it) =>
			reprSpecSig(alloc, ctx, it));
}

immutable(Repr) reprFunInst(ref Alloc alloc, ref Ctx ctx, ref immutable FunInst a) {
	ArrBuilder!NameAndRepr args;
	add(alloc, args, nameAndRepr("name", reprSym(name(decl(a).deref))));
	if (!empty(typeArgs(a)))
		add(alloc, args, nameAndRepr("type-args", reprArr(alloc, typeArgs(a), (ref immutable Type it) =>
			reprType(alloc, ctx, it))));
	if (!empty(specImpls(a)))
		add(alloc, args, nameAndRepr("spec-impls", reprArr(alloc, specImpls(a), (ref immutable Called it) =>
			reprCalled(alloc, ctx, it))));
	return reprNamedRecord("fun-inst", finishArr(alloc, args));
}

immutable(Repr) reprSpecSig(ref Alloc alloc, ref Ctx ctx, ref immutable SpecSig a) {
	return reprRecord(alloc, "spec-sig", [reprSym(name(a.specInst)), reprSym(a.sig.name)]);
}

public immutable(Repr) reprVisibility(immutable Visibility a) {
	return reprSym(symOfVisibility(a));
}
