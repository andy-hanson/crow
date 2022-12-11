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
	ExprKind,
	FlagsFunction,
	flagsFunctionName,
	FunBody,
	FunDecl,
	FunFlags,
	FunInst,
	ImportOrExport,
	ImportOrExportKind,
	Local,
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
	symOfFunKind,
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
import util.sym : Sym, sym;
import util.util : todo;

Repr reprModule(ref Alloc alloc, in Module a) {
	Ctx ctx = Ctx(ptrTrustMe(a));
	ArrBuilder!NameAndRepr fields;
	add(alloc, fields, nameAndRepr!"path"(reprNat(a.fileIndex.index)));
	if (!safeCStrIsEmpty(a.docComment))
		add(alloc, fields, nameAndRepr!"doc"(reprStr(a.docComment)));
	if (!empty(a.imports))
		add(alloc, fields, nameAndRepr!"imports"(reprArr!ImportOrExport(alloc, a.imports, (in ImportOrExport x) =>
			reprImportOrExport(alloc, x))));
	if (!empty(a.reExports))
		add(alloc, fields, nameAndRepr!"re-exports"(reprArr!ImportOrExport(alloc, a.reExports, (in ImportOrExport x) =>
			reprImportOrExport(alloc, x))));
	if (!empty(a.structs))
		add(alloc, fields, nameAndRepr!"structs"(reprArr!StructDecl(alloc, a.structs, (in StructDecl s) =>
			reprStructDecl(alloc, ctx, s))));
	if (!empty(a.specs))
		add(alloc, fields, nameAndRepr!"specs"(reprArr!SpecDecl(alloc, a.specs, (in SpecDecl s) =>
			reprSpecDecl(alloc, ctx, s))));
	if (!empty(a.funs))
		add(alloc, fields, nameAndRepr!"funs"(reprArr!FunDecl(alloc, a.funs, (in FunDecl f) =>
			reprFunDecl(alloc, ctx, f))));
	return reprNamedRecord!"module"(finishArr(alloc, fields));
}

private:

Repr reprImportOrExport(ref Alloc alloc, in ImportOrExport a) =>
	reprRecord!"import"(alloc, [
		reprOpt!RangeWithinFile(alloc, a.importSource, (in RangeWithinFile it) =>
			reprRangeWithinFile(alloc, it)),
		reprImportOrExportKind(alloc, a.kind)]);

Repr reprImportOrExportKind(ref Alloc alloc, in ImportOrExportKind a) =>
	a.matchIn!Repr(
		(in ImportOrExportKind.ModuleWhole m) =>
			reprRecord!"whole"(alloc, [reprNat(m.module_.fileIndex.index)]),
		(in ImportOrExportKind.ModuleNamed m) =>
			reprRecord!"named"(alloc, [
				reprNat(m.module_.fileIndex.index),
				reprArr!Sym(alloc, m.names, (in Sym name) =>
					reprSym(name))]));

immutable struct Ctx {
	Module* curModule;
}

Repr reprStructDecl(ref Alloc alloc, in Ctx ctx, in StructDecl a) {
	ArrBuilder!NameAndRepr fields;
	add(alloc, fields, nameAndRepr!"range"(reprFileAndRange(alloc, a.range)));
	if (!safeCStrIsEmpty(a.docComment))
		add(alloc, fields, nameAndRepr!"doc"(reprStr(a.docComment)));
	add(alloc, fields, nameAndRepr!"visibility"(reprVisibility(a.visibility)));
	add(alloc, fields, nameAndRepr!"name"(reprSym(a.name)));
	if (!empty(a.typeParams))
		add(alloc, fields, nameAndRepr!"typeparams"(reprArr!TypeParam(alloc, a.typeParams, (in TypeParam it) =>
			reprTypeParam(alloc, it))));
	if (a.purity != Purity.data)
		add(alloc, fields, nameAndRepr!"purity"(reprSym(symOfPurity(a.purity))));
	if (a.purityIsForced)
		add(alloc, fields, nameAndRepr!"forced"(reprBool(true)));
	return reprNamedRecord!"struct"(finishArr(alloc, fields));
}

Repr reprSpecDecl(ref Alloc alloc, in Ctx ctx, in SpecDecl a) =>
	todo!Repr("reprSpecDecl");

Repr reprFunDecl(ref Alloc alloc, in Ctx ctx, in FunDecl a) {
	ArrBuilder!NameAndRepr fields;
	if (!safeCStrIsEmpty(a.docComment))
		add(alloc, fields, nameAndRepr!"doc"(reprStr(a.docComment)));
	add(alloc, fields, nameAndRepr!"visibility"(reprVisibility(a.visibility)));
	add(alloc, fields, nameAndRepr!"pos"(reprFileAndPos(alloc, a.fileAndPos)));
	add(alloc, fields, nameAndRepr!"name"(reprSym(a.name)));
	add(alloc, fields, nameAndRepr!"type"(reprType(alloc, ctx, a.returnType)));
	add(alloc, fields, nameAndRepr!"params"(reprParams(alloc, ctx, a.params)));
	if (!empty(a.typeParams))
		add(alloc, fields, nameAndRepr!"typeparams"(reprArr!TypeParam(alloc, a.typeParams, (in TypeParam it) =>
			reprTypeParam(alloc, it))));
	addFunFlags(alloc, fields, a.flags);
	if (!empty(a.specs))
		add(alloc, fields, nameAndRepr!"specs"(reprArr!(SpecInst*)(alloc, a.specs, (in SpecInst* it) =>
			reprSpecInst(alloc, ctx, *it))));
	add(alloc, fields, nameAndRepr!"body"(reprFunBody(alloc, ctx, a.body_)));
	return reprNamedRecord!"fun"(finishArr(alloc, fields));
}

void addFunFlags(ref Alloc alloc, scope ref ArrBuilder!NameAndRepr fields, in FunFlags a) {
	void addFlag(string a)() {
		add(alloc, fields, nameAndRepr!a(reprBool(true)));
	}

	if (a.noCtx)
		addFlag!"no-ctx";
	if (a.noDoc)
		addFlag!"no-doc";
	if (a.summon)
		addFlag!"summon";
	final switch (a.safety) {
		case FunFlags.Safety.safe:
			break;
		case FunFlags.Safety.unsafe:
			addFlag!"unsafe";
			break;
	}
	if (a.preferred)
		addFlag!"preferred";
	if (a.okIfUnused)
		addFlag!"ok-unused";
	final switch (a.specialBody) {
		case FunFlags.SpecialBody.none:
			break;
		case FunFlags.SpecialBody.builtin:
			addFlag!"builtin";
			break;
		case FunFlags.SpecialBody.extern_:
			addFlag!"extern";
			break;
		case FunFlags.SpecialBody.global:
			addFlag!"global";
			break;
		case FunFlags.SpecialBody.threadLocal:
			addFlag!"thread-local";
			break;
	}
}

Repr reprTypeParam(ref Alloc alloc, in TypeParam a) =>
	reprRecord!"type-param"(alloc, [reprSym(a.name)]);

Repr reprParams(ref Alloc alloc, in Ctx ctx, in Params a) =>
	a.matchIn!Repr(
		(in Param[] params) =>
			reprArr!Param(alloc, params, (in Param it) =>
				reprParam(alloc, ctx, it)),
		(in Params.Varargs v) =>
			reprRecord!"varargs"(alloc, [reprParam(alloc, ctx, v.param)]));

Repr reprParam(ref Alloc alloc, in Ctx ctx, in Param a) =>
	reprRecord!"param"(alloc, [
		reprFileAndRange(alloc, a.range),
		reprOpt!Sym(alloc, a.name, (in Sym it) =>
			reprSym(it)),
		reprType(alloc, ctx, a.type)]);

Repr reprSpecInst(ref Alloc alloc, in Ctx ctx, in SpecInst a) =>
	todo!Repr("reprSpecInst");

Repr reprFunBody(ref Alloc alloc, in Ctx ctx, in FunBody a) =>
	a.matchIn!Repr(
		(in FunBody.Bogus) =>
			reprSym!"bogus" ,
		(in FunBody.Builtin) =>
			reprSym!"builtin" ,
		(in FunBody.CreateEnum it) =>
			reprRecord!"new-enum"(alloc, [reprInt(it.value.value)]),
		(in FunBody.CreateExtern) =>
			reprSym!"new-extern",
		(in FunBody.CreateRecord) =>
			reprSym!"new-record" ,
		(in FunBody.CreateUnion) =>
			//TODO: more detail
			reprSym!"new-union" ,
		(in EnumFunction it) =>
			reprRecord!"enum-fn"(alloc, [reprSym(enumFunctionName(it))]),
		(in FunBody.Extern x) =>
			reprRecord!"extern"(alloc, [reprBool(x.isGlobal), reprSym(x.libraryName)]),
		(in Expr it) =>
			reprExpr(alloc, ctx, it),
		(in FunBody.FileBytes) =>
			reprSym!"bytes" ,
		(in FlagsFunction it) =>
			reprRecord!"flags-fn"(alloc, [reprSym(flagsFunctionName(it))]),
		(in FunBody.RecordFieldGet it) =>
			reprRecord!"field-get"(alloc, [reprNat(it.fieldIndex)]),
		(in FunBody.RecordFieldSet it) =>
			reprRecord!"field-set"(alloc, [reprNat(it.fieldIndex)]),
		(in FunBody.ThreadLocal) =>
			reprSym!"thread-local");

Repr reprType(ref Alloc alloc, in Ctx ctx, in Type a) =>
	a.matchIn!Repr(
		(in Type.Bogus) =>
			reprSym!"bogus" ,
		(in TypeParam x) =>
			reprRecord!"type-param"(alloc, [reprSym(x.name)]),
		(in StructInst x) =>
			reprStructInst(alloc, ctx, x));

Repr reprStructInst(ref Alloc alloc, in Ctx ctx, in StructInst a) =>
	reprRecord(
		a.declAndArgs.decl.name,
		map(alloc, a.declAndArgs.typeArgs, (ref Type it) =>
			reprType(alloc, ctx, it)));

Repr reprExprs(ref Alloc alloc, in Ctx ctx, in Expr[] a) =>
	reprArr!Expr(alloc, a, (in Expr x) =>
		reprExpr(alloc, ctx, x));

Repr reprExpr(ref Alloc alloc, in Ctx ctx, in Expr a) =>
	a.kind.matchIn!Repr(
		(in ExprKind.AssertOrForbid x) =>
			reprRecord(alloc, symOfAssertOrForbidKind(x.kind), [
				reprExpr(alloc, ctx, *x.condition),
				reprOpt!(Expr*)(alloc, x.thrown, (in Expr* thrown) =>
					reprExpr(alloc, ctx, *thrown))]),
		(in ExprKind.Bogus) =>
			reprSym!"bogus" ,
		(in ExprKind.Call e) =>
			reprRecord!"call"(alloc, [
				reprCalled(alloc, ctx, e.called),
				reprExprs(alloc, ctx, e.args)]),
		(in ExprKind.ClosureGet a) =>
			reprRecord!"closure-get"(alloc, [reprNat(a.closureRef.index)]),
		(in ExprKind.ClosureSet a) =>
			reprRecord!"closure-set"(alloc, [reprNat(a.closureRef.index)]),
		(in ExprKind.Cond e) =>
			reprRecord!"cond"(alloc, [
				reprExpr(alloc, ctx, e.cond),
				reprExpr(alloc, ctx, e.then),
				reprExpr(alloc, ctx, e.else_)]),
		(in ExprKind.Drop x) =>
			reprRecord!"drop"(alloc, [reprExpr(alloc, ctx, x.arg)]),
		(in ExprKind.FunPtr it) =>
			reprRecord!"fun-pointer"(alloc, [
				reprFunInst(alloc, ctx, *it.funInst),
				reprStructInst(alloc, ctx, *it.structInst)]),
		(in ExprKind.IfOption it) =>
			reprRecord!"if"(alloc, [
				reprExpr(alloc, ctx, it.option),
				reprLocal(alloc, ctx, *it.local),
				reprExpr(alloc, ctx, it.then),
				reprExpr(alloc, ctx, it.else_)]),
		(in ExprKind.Lambda a) =>
			reprRecord!"lambda"(alloc, [
				reprArr!Param(alloc, a.params, (in Param it) =>
					reprParam(alloc, ctx, it)),
				reprExpr(alloc, ctx, a.body_),
				reprArr!VariableRef(alloc, a.closure, (in VariableRef it) =>
					reprSym(debugName(it))),
				reprStructInst(alloc, ctx, *a.funType),
				reprSym(symOfFunKind(a.kind)),
				reprType(alloc, ctx, a.returnType)]),
		(in ExprKind.Let it) =>
			reprRecord!"let"(alloc, [
				reprLocal(alloc, ctx, *it.local),
				reprExpr(alloc, ctx, it.value),
				reprExpr(alloc, ctx, it.then)]),
		(in ExprKind.Literal it) =>
			reprRecord!"literal"(alloc, [
				reprStructInst(alloc, ctx, *it.structInst),
				reprOfConstant(alloc, it.value)]),
		(in ExprKind.LiteralCString it) =>
			reprRecord!"c-string-lit"(alloc, [reprStr(alloc, it.value)]),
		(in ExprKind.LiteralSymbol it) =>
			reprRecord!"sym-lit"(alloc, [reprSym(it.value)]),
		(in ExprKind.LocalGet it) =>
			reprRecord!"local-get"(alloc, [reprSym(it.local.name)]),
		(in ExprKind.LocalSet it) =>
			reprRecord!"local-set"(alloc, [reprSym(it.local.name), reprExpr(alloc, ctx, it.value)]),
		(in ExprKind.Loop x) =>
			reprRecord!"loop"(alloc, [reprExpr(alloc, ctx, x.body_)]),
		(in ExprKind.LoopBreak x) =>
			reprRecord!"break"(alloc, [reprExpr(alloc, ctx, x.value)]),
		(in ExprKind.LoopContinue x) =>
			reprRecord!"continue"(alloc, []),
		(in ExprKind.LoopUntil x) =>
			reprRecord!"until"(alloc, [
				reprExpr(alloc, ctx, x.condition),
				reprExpr(alloc, ctx, x.body_)]),
		(in ExprKind.LoopWhile x) =>
			reprRecord!"while"(alloc, [
				reprExpr(alloc, ctx, x.condition),
				reprExpr(alloc, ctx, x.body_)]),
		(in ExprKind.MatchEnum a) =>
			reprRecord!"match-enum"(alloc, [
				reprExpr(alloc, ctx, a.matched),
				reprExprs(alloc, ctx, a.cases)]),
		(in ExprKind.MatchUnion a) =>
			reprRecord!"match-union"(alloc, [
				reprExpr(alloc, ctx, a.matched),
				reprStructInst(alloc, ctx, *a.matchedUnion),
				reprArr!(ExprKind.MatchUnion.Case)(alloc, a.cases, (in ExprKind.MatchUnion.Case case_) =>
					reprMatchUnionCase(alloc, ctx, case_))]),
		(in ExprKind.ParamGet it) =>
			reprRecord!"param-get"(alloc, [reprSym(force(it.param.name))]),
		(in ExprKind.PtrToField it) =>
			reprRecord!"ptr-to-field"(alloc, [
				reprType(alloc, ctx, it.pointerType),
				reprExpr(alloc, ctx, it.target),
				reprNat(it.fieldIndex)]),
		(in ExprKind.PtrToLocal it) =>
			reprRecord!"ptr-to-local"(alloc, [reprSym(it.local.name)]),
		(in ExprKind.PtrToParam it) =>
			reprRecord!"ptr-to-param"(alloc, [reprSym(force(it.param.name))]),
		(in ExprKind.Seq a) =>
			reprRecord!"seq"(alloc, [
				reprExpr(alloc, ctx, a.first),
				reprExpr(alloc, ctx, a.then)]),
		(in ExprKind.Throw a) =>
			reprRecord!"throw"(alloc, [reprExpr(alloc, ctx, a.thrown)]));

Repr reprMatchUnionCase(ref Alloc alloc, in Ctx ctx, in ExprKind.MatchUnion.Case a) =>
	reprRecord!"case"(alloc, [
		reprOpt!(Local*)(alloc, a.local, (in Local* local) =>
			reprLocal(alloc, ctx, *local)),
		reprExpr(alloc, ctx, a.then)]);

Repr reprLocal(ref Alloc alloc, in Ctx ctx, in Local a) =>
	reprRecord!"local"(alloc, [
		reprFileAndRange(alloc, a.range),
		reprSym(a.name),
		reprType(alloc, ctx, a.type)]);

Repr reprCalled(ref Alloc alloc, in Ctx ctx, in Called a) =>
	a.matchIn!Repr(
		(in FunInst x) =>
			reprFunInst(alloc, ctx, x),
		(in SpecSig x) =>
			reprSpecSig(alloc, ctx, x));

Repr reprFunInst(ref Alloc alloc, in Ctx ctx, in FunInst a) {
	ArrBuilder!NameAndRepr args;
	add(alloc, args, nameAndRepr!"name"(reprSym(decl(a).name)));
	if (!empty(typeArgs(a)))
		add(alloc, args, nameAndRepr!"type-args"(reprArr!Type(alloc, typeArgs(a), (in Type it) =>
			reprType(alloc, ctx, it))));
	if (!empty(specImpls(a)))
		add(alloc, args, nameAndRepr!"spec-impls"(reprArr!Called(alloc, specImpls(a), (in Called it) =>
			reprCalled(alloc, ctx, it))));
	return reprNamedRecord!"fun-inst"(finishArr(alloc, args));
}

Repr reprSpecSig(ref Alloc alloc, in Ctx ctx, in SpecSig a) =>
	reprRecord!"spec-sig"(alloc, [
		reprSym(name(*a.specInst)),
		reprSym(a.sig.name)]);

public Repr reprVisibility(Visibility a) =>
	reprSym(symOfVisibility(a));
