module model.reprModel;

@safe @nogc pure nothrow:

import model.model :
	body_,
	Called,
	debugName,
	decl,
	EnumFunction,
	enumFunctionName,
	Expr,
	FlagsFunction,
	flagsFunctionName,
	FunBody,
	FunDecl,
	FunFlags,
	FunInst,
	FunKind,
	ImportOrExport,
	ImportOrExportKind,
	Local,
	matchCalled,
	matchExpr,
	matchFunBody,
	matchImportOrExportKind,
	matchParams,
	matchType,
	Module,
	name,
	noCtx,
	Param,
	Params,
	Purity,
	SpecDecl,
	specImpls,
	SpecInst,
	SpecSig,
	StructDecl,
	StructInst,
	summon,
	symOfAssertOrForbidKind,
	symOfPurity,
	symOfVisibility,
	Type,
	typeArgs,
	TypeParam,
	typeParams,
	VariableRef,
	Visibility;
import model.reprConstant : reprOfConstant;
import util.alloc.alloc : Alloc;
import util.col.arr : empty;
import util.col.arrBuilder : add, ArrBuilder, finishArr;
import util.col.arrUtil : map;
import util.col.str : safeCStrIsEmpty;
import util.opt : force;
import util.ptr : ptrTrustMe;
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
import util.sym : shortSym, Sym;
import util.util : todo;

immutable(Repr) reprModule(ref Alloc alloc, ref immutable Module a) {
	Ctx ctx = Ctx(ptrTrustMe(a));
	ArrBuilder!NameAndRepr fields;
	add(alloc, fields, nameAndRepr("path", reprNat(a.fileIndex.index)));
	if (!safeCStrIsEmpty(a.docComment))
		add(alloc, fields, nameAndRepr("doc", reprStr(a.docComment)));
	if (!empty(a.imports))
		add(alloc, fields, nameAndRepr("imports", reprArr(alloc, a.imports, (ref immutable ImportOrExport x) =>
			reprImportOrExport(alloc, x))));
	if (!empty(a.exports))
		add(alloc, fields, nameAndRepr("exports", reprArr(alloc, a.exports, (ref immutable ImportOrExport x) =>
			reprImportOrExport(alloc, x))));
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

immutable(Repr) reprImportOrExport(ref Alloc alloc, ref immutable ImportOrExport a) =>
	reprRecord(alloc, "import", [
		reprOpt(alloc, a.importSource, (ref immutable RangeWithinFile it) =>
			reprRangeWithinFile(alloc, it)),
		reprImportOrExportKind(alloc, a.kind)]);

immutable(Repr) reprImportOrExportKind(ref Alloc alloc, ref immutable ImportOrExportKind a) =>
	matchImportOrExportKind(
		a,
		(immutable ImportOrExportKind.ModuleWhole m) =>
			reprRecord(alloc, "whole", [reprNat(m.module_.fileIndex.index)]),
		(immutable ImportOrExportKind.ModuleNamed m) =>
			reprRecord(alloc, "named", [
				reprNat(m.module_.fileIndex.index),
				reprArr(alloc, m.names, (ref immutable Sym name) =>
					reprSym(name))]));

struct Ctx {
	immutable Module* curModule;
}

immutable(Repr) reprStructDecl(ref Alloc alloc, scope ref Ctx ctx, ref immutable StructDecl a) {
	ArrBuilder!NameAndRepr fields;
	add(alloc, fields, nameAndRepr("range", reprFileAndRange(alloc, a.range)));
	if (!safeCStrIsEmpty(a.docComment))
		add(alloc, fields, nameAndRepr("doc", reprStr(a.docComment)));
	add(alloc, fields, nameAndRepr("visibility", reprVisibility(a.visibility)));
	add(alloc, fields, nameAndRepr("name", reprSym(a.name)));
	if (!empty(a.typeParams))
		add(alloc, fields, nameAndRepr("typeparams", reprArr(alloc, a.typeParams, (ref immutable TypeParam it) =>
			reprTypeParam(alloc, it))));
	if (a.purity != Purity.data)
		add(alloc, fields, nameAndRepr("purity", reprSym(symOfPurity(a.purity))));
	if (a.purityIsForced)
		add(alloc, fields, nameAndRepr("forced", reprBool(true)));
	return reprNamedRecord("struct", finishArr(alloc, fields));
}

immutable(Repr) reprSpecDecl(ref Alloc alloc, scope ref Ctx ctx, ref immutable SpecDecl a) =>
	todo!(immutable Repr)("reprSpecDecl");

immutable(Repr) reprFunDecl(ref Alloc alloc, scope ref Ctx ctx, ref immutable FunDecl a) {
	ArrBuilder!NameAndRepr fields;
	if (!safeCStrIsEmpty(a.docComment))
		add(alloc, fields, nameAndRepr("doc", reprStr(a.docComment)));
	add(alloc, fields, nameAndRepr("visibility", reprVisibility(a.visibility)));
	add(alloc, fields, nameAndRepr("pos", reprFileAndPos(alloc, a.fileAndPos)));
	add(alloc, fields, nameAndRepr("name", reprSym(a.name)));
	add(alloc, fields, nameAndRepr("type", reprType(alloc, ctx, a.returnType)));
	add(alloc, fields, nameAndRepr("params", reprParams(alloc, ctx, a.params)));
	if (!empty(a.typeParams))
		add(alloc, fields, nameAndRepr("typeparams", reprArr(alloc, a.typeParams, (ref immutable TypeParam it) =>
			reprTypeParam(alloc, it))));
	addFunFlags(alloc, fields, a.flags);
	if (!empty(a.specs))
		add(alloc, fields, nameAndRepr("specs", reprArr(alloc, a.specs, (ref immutable SpecInst* it) =>
			reprSpecInst(alloc, ctx, *it))));
	add(alloc, fields, nameAndRepr("body", reprFunBody(alloc, ctx, a.body_)));
	return reprNamedRecord("fun", finishArr(alloc, fields));
}

void addFunFlags(ref Alloc alloc, scope ref ArrBuilder!NameAndRepr fields, scope ref immutable FunFlags a) {
	void addFlag(immutable string a) {
		add(alloc, fields, nameAndRepr(a, reprBool(true)));
	}

	if (a.noCtx)
		addFlag("no-ctx");
	if (a.noDoc)
		addFlag("no-doc");
	if (a.summon)
		addFlag("summon");
	final switch (a.safety) {
		case FunFlags.Safety.safe:
			break;
		case FunFlags.Safety.unsafe:
			addFlag("unsafe");
			break;
		case FunFlags.Safety.trusted:
			addFlag("trusted");
			break;
	}
	if (a.preferred)
		addFlag("preferred");
	if (a.okIfUnused)
		addFlag("ok-unused");
	final switch (a.specialBody) {
		case FunFlags.SpecialBody.none:
			break;
		case FunFlags.SpecialBody.builtin:
			addFlag("builtin");
			break;
		case FunFlags.SpecialBody.extern_:
			addFlag("extern");
			break;
		case FunFlags.SpecialBody.global:
			addFlag("global");
			break;
		case FunFlags.SpecialBody.threadLocal:
			addFlag("thread-local");
			break;
	}
}

immutable(Repr) reprTypeParam(ref Alloc alloc, immutable TypeParam a) =>
	reprRecord(alloc, "type-param", [reprSym(a.name)]);

immutable(Repr) reprParams(ref Alloc alloc, scope ref Ctx ctx, scope ref immutable Params a) =>
	matchParams!(immutable Repr)(
		a,
		(immutable Param[] params) =>
			reprArr(alloc, params, (ref immutable Param it) =>
				reprParam(alloc, ctx, it)),
		(ref immutable Params.Varargs v) =>
			reprRecord(alloc, "varargs", [reprParam(alloc, ctx, v.param)]));

immutable(Repr) reprParam(ref Alloc alloc, scope ref Ctx ctx, ref immutable Param a) =>
	reprRecord(alloc, "param", [
		reprFileAndRange(alloc, a.range),
		reprOpt(alloc, a.name, (ref immutable Sym it) =>
			reprSym(it)),
		reprType(alloc, ctx, a.type)]);

immutable(Repr) reprSpecInst(ref Alloc alloc, scope ref Ctx ctx, ref immutable SpecInst a) =>
	todo!(immutable Repr)("reprSpecInst");

immutable(Repr) reprFunBody(ref Alloc alloc, scope ref Ctx ctx, ref immutable FunBody a) =>
	matchFunBody!(
		immutable Repr,
		(ref immutable FunBody.Bogus) =>
			reprSym("bogus"),
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
		(ref immutable FunBody.Extern x) =>
			reprRecord(alloc, "extern", [reprBool(x.isGlobal), reprSym(x.libraryName)]),
		(ref immutable Expr it) =>
			reprExpr(alloc, ctx, it),
		(immutable(FunBody.FileBytes)) =>
			reprSym("bytes"),
		(immutable FlagsFunction it) =>
			reprRecord(alloc, "flags-fn", [reprSym(flagsFunctionName(it))]),
		(ref immutable FunBody.RecordFieldGet it) =>
			reprRecord(alloc, "field-get", [reprNat(it.fieldIndex)]),
		(ref immutable FunBody.RecordFieldSet it) =>
			reprRecord(alloc, "field-set", [reprNat(it.fieldIndex)]),
		(ref immutable FunBody.ThreadLocal) =>
			reprSym("thread-local"),
	)(a);

immutable(Repr) reprType(ref Alloc alloc, scope ref Ctx ctx, immutable Type a) =>
	matchType!(immutable Repr)(
		a,
		(immutable Type.Bogus) =>
			reprSym("bogus"),
		(immutable TypeParam* p) =>
			reprRecord(alloc, "type-param", [reprSym(p.name)]),
		(immutable StructInst* a) =>
			reprStructInst(alloc, ctx, *a));

immutable(Repr) reprStructInst(ref Alloc alloc, scope ref Ctx ctx, ref immutable StructInst a) =>
	reprRecord(
		a.declAndArgs.decl.name,
		map(alloc, a.declAndArgs.typeArgs, (ref immutable Type it) =>
			reprType(alloc, ctx, it)));

immutable(Repr) reprExpr(ref Alloc alloc, scope ref Ctx ctx, ref immutable Expr a) =>
	matchExpr!(immutable Repr)(
		a,
		(ref immutable Expr.AssertOrForbid x) =>
			reprRecord(alloc, symOfAssertOrForbidKind(x.kind), [
				reprExpr(alloc, ctx, x.condition),
				reprOpt(alloc, x.thrown, (ref immutable Expr thrown) =>
					reprExpr(alloc, ctx, thrown))]),
		(ref immutable Expr.Bogus) =>
			reprSym("bogus"),
		(ref immutable Expr.Call e) =>
			reprRecord(alloc, "call", [
				reprCalled(alloc, ctx, e.called),
				reprArr(alloc, e.args, (ref immutable Expr arg) =>
					reprExpr(alloc, ctx, arg))]),
		(ref immutable Expr.ClosureGet a) =>
			reprRecord(alloc, "closure-get", [reprNat(a.closureRef.index)]),
		(ref immutable Expr.ClosureSet a) =>
			reprRecord(alloc, "closure-set", [reprNat(a.closureRef.index)]),
		(ref immutable Expr.Cond e) =>
			reprRecord(alloc, "cond", [
				reprExpr(alloc, ctx, e.cond),
				reprExpr(alloc, ctx, e.then),
				reprExpr(alloc, ctx, e.else_)]),
		(ref immutable Expr.Drop x) =>
			reprRecord(alloc, "drop", [reprExpr(alloc, ctx, x.arg)]),
		(ref immutable Expr.FunPtr it) =>
			reprRecord(alloc, "fun-pointer", [
				reprFunInst(alloc, ctx, *it.funInst),
				reprStructInst(alloc, ctx, *it.structInst)]),
		(ref immutable Expr.IfOption it) =>
			reprRecord(alloc, "if", [
				reprExpr(alloc, ctx, it.option),
				reprLocal(alloc, ctx, *it.local),
				reprExpr(alloc, ctx, it.then),
				reprExpr(alloc, ctx, it.else_)]),
		(ref immutable Expr.Lambda a) =>
			reprRecord(alloc, "lambda", [
				reprArr(alloc, a.params, (ref immutable Param it) =>
					reprParam(alloc, ctx, it)),
				reprExpr(alloc, ctx, a.body_),
				reprArr(alloc, a.closure, (ref immutable VariableRef it) =>
					reprSym(debugName(it))),
				reprStructInst(alloc, ctx, *a.funType),
				reprSym(symOfFunKind(a.kind)),
				reprType(alloc, ctx, a.returnType)]),
		(ref immutable Expr.Let it) =>
			reprRecord(alloc, "let", [
				reprLocal(alloc, ctx, *it.local),
				reprExpr(alloc, ctx, it.value),
				reprExpr(alloc, ctx, it.then)]),
		(ref immutable Expr.Literal it) =>
			reprRecord(alloc, "literal", [
				reprStructInst(alloc, ctx, *it.structInst),
				reprOfConstant(alloc, it.value)]),
		(ref immutable Expr.LiteralCString it) =>
			reprRecord(alloc, "c-string-lit", [reprStr(it.value)]),
		(ref immutable Expr.LiteralSymbol it) =>
			reprRecord(alloc, "sym-lit", [reprSym(it.value)]),
		(ref immutable Expr.LocalGet it) =>
			reprRecord(alloc, "local-get", [reprSym(it.local.name)]),
		(ref immutable Expr.LocalSet it) =>
			reprRecord(alloc, "local-set", [reprSym(it.local.name), reprExpr(alloc, ctx, it.value)]),
		(ref immutable Expr.Loop x) =>
			reprRecord(alloc, "loop", [reprExpr(alloc, ctx, x.body_)]),
		(ref immutable Expr.LoopBreak x) =>
			reprRecord(alloc, "break", [reprExpr(alloc, ctx, x.value)]),
		(ref immutable Expr.LoopContinue x) =>
			reprRecord(alloc, "continue", []),
		(ref immutable Expr.LoopUntil x) =>
			reprRecord(alloc, "until", [
				reprExpr(alloc, ctx, x.condition),
				reprExpr(alloc, ctx, x.body_)]),
		(ref immutable Expr.LoopWhile x) =>
			reprRecord(alloc, "while", [
				reprExpr(alloc, ctx, x.condition),
				reprExpr(alloc, ctx, x.body_)]),
		(ref immutable Expr.MatchEnum a) =>
			reprRecord(alloc, "match-enum", [
				reprExpr(alloc, ctx, a.matched),
				reprArr(alloc, a.cases, (ref immutable Expr case_) =>
					reprExpr(alloc, ctx, case_))]),
		(ref immutable Expr.MatchUnion a) =>
			reprRecord(alloc, "match-union", [
				reprExpr(alloc, ctx, a.matched),
				reprStructInst(alloc, ctx, *a.matchedUnion),
				reprArr(alloc, a.cases, (ref immutable Expr.MatchUnion.Case case_) =>
					reprMatchUnionCase(alloc, ctx, case_))]),
		(ref immutable Expr.ParamGet it) =>
			reprRecord(alloc, "param-get", [reprSym(force(it.param.name))]),
		(ref immutable Expr.PtrToField it) =>
			reprRecord(alloc, "ptr-to-field", [
				reprType(alloc, ctx, it.pointerType),
				reprExpr(alloc, ctx, it.target),
				reprNat(it.fieldIndex)]),
		(ref immutable Expr.PtrToLocal it) =>
			reprRecord(alloc, "ptr-to-local", [reprSym(it.local.name)]),
		(ref immutable Expr.PtrToParam it) =>
			reprRecord(alloc, "ptr-to-param", [reprSym(force(it.param.name))]),
		(ref immutable Expr.Seq a) =>
			reprRecord(alloc, "seq", [
				reprExpr(alloc, ctx, a.first),
				reprExpr(alloc, ctx, a.then)]),
		(ref immutable Expr.Throw a) =>
			reprRecord(alloc, "throw", [reprExpr(alloc, ctx, a.thrown)]));

immutable(Sym) symOfFunKind(immutable FunKind a) {
	final switch (a) {
		case FunKind.plain:
			return shortSym("plain");
		case FunKind.mut:
			return shortSym("mut");
		case FunKind.ref_:
			return shortSym("ref");
		case FunKind.pointer:
			return shortSym("pointer");
	}
}

immutable(Repr) reprMatchUnionCase(ref Alloc alloc, scope ref Ctx ctx, ref immutable Expr.MatchUnion.Case a) =>
	reprRecord(alloc, "case", [
		reprOpt!(Local*)(alloc, a.local, (ref immutable Local* local) =>
			reprLocal(alloc, ctx, *local)),
		reprExpr(alloc, ctx, a.then)]);

immutable(Repr) reprLocal(ref Alloc alloc, scope ref Ctx ctx, ref immutable Local a) =>
	reprRecord(alloc, "local", [
		reprFileAndRange(alloc, a.range),
		reprSym(a.name),
		reprType(alloc, ctx, a.type)]);

immutable(Repr) reprCalled(ref Alloc alloc, scope ref Ctx ctx, ref immutable Called a) =>
	matchCalled!(
		immutable Repr,
		(immutable FunInst* it) =>
			reprFunInst(alloc, ctx, *it),
		(ref immutable SpecSig it) =>
			reprSpecSig(alloc, ctx, it),
	)(a);

immutable(Repr) reprFunInst(ref Alloc alloc, scope ref Ctx ctx, ref immutable FunInst a) {
	ArrBuilder!NameAndRepr args;
	add(alloc, args, nameAndRepr("name", reprSym(decl(a).name)));
	if (!empty(typeArgs(a)))
		add(alloc, args, nameAndRepr("type-args", reprArr(alloc, typeArgs(a), (ref immutable Type it) =>
			reprType(alloc, ctx, it))));
	if (!empty(specImpls(a)))
		add(alloc, args, nameAndRepr("spec-impls", reprArr(alloc, specImpls(a), (ref immutable Called it) =>
			reprCalled(alloc, ctx, it))));
	return reprNamedRecord("fun-inst", finishArr(alloc, args));
}

immutable(Repr) reprSpecSig(ref Alloc alloc, scope ref Ctx ctx, ref immutable SpecSig a) =>
	reprRecord(alloc, "spec-sig", [
		reprSym(name(*a.specInst)),
		reprSym(a.sig.name)]);

public immutable(Repr) reprVisibility(immutable Visibility a) =>
	reprSym(symOfVisibility(a));
