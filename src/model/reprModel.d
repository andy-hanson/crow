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
	FunKind,
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

immutable(Repr) reprModule(ref Alloc alloc, ref immutable Module a) {
	Ctx ctx = Ctx(ptrTrustMe(a));
	ArrBuilder!NameAndRepr fields;
	add(alloc, fields, nameAndRepr!"path"(reprNat(a.fileIndex.index)));
	if (!safeCStrIsEmpty(a.docComment))
		add(alloc, fields, nameAndRepr!"doc"(reprStr(a.docComment)));
	if (!empty(a.imports))
		add(alloc, fields, nameAndRepr!"imports"(reprArr(alloc, a.imports, (ref immutable ImportOrExport x) =>
			reprImportOrExport(alloc, x))));
	if (!empty(a.reExports))
		add(alloc, fields, nameAndRepr!"re-exports"(reprArr(alloc, a.reExports, (ref immutable ImportOrExport x) =>
			reprImportOrExport(alloc, x))));
	if (!empty(a.structs))
		add(alloc, fields, nameAndRepr!"structs"(reprArr(alloc, a.structs, (ref immutable StructDecl s) =>
			reprStructDecl(alloc, ctx, s))));
	if (!empty(a.specs))
		add(alloc, fields, nameAndRepr!"specs"(reprArr(alloc, a.specs, (ref immutable SpecDecl s) =>
			reprSpecDecl(alloc, ctx, s))));
	if (!empty(a.funs))
		add(alloc, fields, nameAndRepr!"funs"(reprArr(alloc, a.funs, (ref immutable FunDecl f) =>
			reprFunDecl(alloc, ctx, f))));
	return reprNamedRecord!"module"(finishArr(alloc, fields));
}

private:

immutable(Repr) reprImportOrExport(ref Alloc alloc, ref immutable ImportOrExport a) =>
	reprRecord!"import"(alloc, [
		reprOpt(alloc, a.importSource, (ref immutable RangeWithinFile it) =>
			reprRangeWithinFile(alloc, it)),
		reprImportOrExportKind(alloc, a.kind)]);

immutable(Repr) reprImportOrExportKind(ref Alloc alloc, ref immutable ImportOrExportKind a) =>
	a.match!(immutable Repr)(
		(immutable ImportOrExportKind.ModuleWhole m) =>
			reprRecord!"whole"(alloc, [reprNat(m.module_.fileIndex.index)]),
		(immutable ImportOrExportKind.ModuleNamed m) =>
			reprRecord!"named"(alloc, [
				reprNat(m.module_.fileIndex.index),
				reprArr(alloc, m.names, (ref immutable Sym name) =>
					reprSym(name))]));

struct Ctx {
	immutable Module* curModule;
}

immutable(Repr) reprStructDecl(ref Alloc alloc, scope ref Ctx ctx, ref immutable StructDecl a) {
	ArrBuilder!NameAndRepr fields;
	add(alloc, fields, nameAndRepr!"range"(reprFileAndRange(alloc, a.range)));
	if (!safeCStrIsEmpty(a.docComment))
		add(alloc, fields, nameAndRepr!"doc"(reprStr(a.docComment)));
	add(alloc, fields, nameAndRepr!"visibility"(reprVisibility(a.visibility)));
	add(alloc, fields, nameAndRepr!"name"(reprSym(a.name)));
	if (!empty(a.typeParams))
		add(alloc, fields, nameAndRepr!"typeparams"(reprArr(alloc, a.typeParams, (ref immutable TypeParam it) =>
			reprTypeParam(alloc, it))));
	if (a.purity != Purity.data)
		add(alloc, fields, nameAndRepr!"purity"(reprSym(symOfPurity(a.purity))));
	if (a.purityIsForced)
		add(alloc, fields, nameAndRepr!"forced"(reprBool(true)));
	return reprNamedRecord!"struct"(finishArr(alloc, fields));
}

immutable(Repr) reprSpecDecl(ref Alloc alloc, scope ref Ctx ctx, ref immutable SpecDecl a) =>
	todo!(immutable Repr)("reprSpecDecl");

immutable(Repr) reprFunDecl(ref Alloc alloc, scope ref Ctx ctx, ref immutable FunDecl a) {
	ArrBuilder!NameAndRepr fields;
	if (!safeCStrIsEmpty(a.docComment))
		add(alloc, fields, nameAndRepr!"doc"(reprStr(a.docComment)));
	add(alloc, fields, nameAndRepr!"visibility"(reprVisibility(a.visibility)));
	add(alloc, fields, nameAndRepr!"pos"(reprFileAndPos(alloc, a.fileAndPos)));
	add(alloc, fields, nameAndRepr!"name"(reprSym(a.name)));
	add(alloc, fields, nameAndRepr!"type"(reprType(alloc, ctx, a.returnType)));
	add(alloc, fields, nameAndRepr!"params"(reprParams(alloc, ctx, a.params)));
	if (!empty(a.typeParams))
		add(alloc, fields, nameAndRepr!"typeparams"(reprArr(alloc, a.typeParams, (ref immutable TypeParam it) =>
			reprTypeParam(alloc, it))));
	addFunFlags(alloc, fields, a.flags);
	if (!empty(a.specs))
		add(alloc, fields, nameAndRepr!"specs"(reprArr(alloc, a.specs, (ref immutable SpecInst* it) =>
			reprSpecInst(alloc, ctx, *it))));
	add(alloc, fields, nameAndRepr!"body"(reprFunBody(alloc, ctx, a.body_)));
	return reprNamedRecord!"fun"(finishArr(alloc, fields));
}

void addFunFlags(ref Alloc alloc, scope ref ArrBuilder!NameAndRepr fields, scope ref immutable FunFlags a) {
	void addFlag(immutable string a)() {
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
		case FunFlags.Safety.trusted:
			addFlag!"trusted";
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

immutable(Repr) reprTypeParam(ref Alloc alloc, immutable TypeParam a) =>
	reprRecord!"type-param"(alloc, [reprSym(a.name)]);

immutable(Repr) reprParams(ref Alloc alloc, scope ref Ctx ctx, scope ref immutable Params a) =>
	a.match!(immutable Repr)(
		(immutable Param[] params) =>
			reprArr(alloc, params, (ref immutable Param it) =>
				reprParam(alloc, ctx, it)),
		(ref immutable Params.Varargs v) =>
			reprRecord!"varargs"(alloc, [reprParam(alloc, ctx, v.param)]));

immutable(Repr) reprParam(ref Alloc alloc, scope ref Ctx ctx, ref immutable Param a) =>
	reprRecord!"param"(alloc, [
		reprFileAndRange(alloc, a.range),
		reprOpt(alloc, a.name, (ref immutable Sym it) =>
			reprSym(it)),
		reprType(alloc, ctx, a.type)]);

immutable(Repr) reprSpecInst(ref Alloc alloc, scope ref Ctx ctx, ref immutable SpecInst a) =>
	todo!(immutable Repr)("reprSpecInst");

immutable(Repr) reprFunBody(ref Alloc alloc, scope ref Ctx ctx, ref immutable FunBody a) =>
	a.match!(immutable Repr)(
		(immutable FunBody.Bogus) =>
			reprSym!"bogus" ,
		(immutable FunBody.Builtin) =>
			reprSym!"builtin" ,
		(immutable FunBody.CreateEnum it) =>
			reprRecord!"new-enum"(alloc, [reprInt(it.value.value)]),
		(immutable FunBody.CreateExtern) =>
			reprSym!"new-extern",
		(immutable FunBody.CreateRecord) =>
			reprSym!"new-record" ,
		(immutable FunBody.CreateUnion) =>
			//TODO: more detail
			reprSym!"new-union" ,
		(immutable EnumFunction it) =>
			reprRecord!"enum-fn"(alloc, [reprSym(enumFunctionName(it))]),
		(immutable FunBody.Extern x) =>
			reprRecord!"extern"(alloc, [reprBool(x.isGlobal), reprSym(x.libraryName)]),
		(immutable Expr it) =>
			reprExpr(alloc, ctx, it),
		(immutable(FunBody.FileBytes)) =>
			reprSym!"bytes" ,
		(immutable FlagsFunction it) =>
			reprRecord!"flags-fn"(alloc, [reprSym(flagsFunctionName(it))]),
		(immutable FunBody.RecordFieldGet it) =>
			reprRecord!"field-get"(alloc, [reprNat(it.fieldIndex)]),
		(immutable FunBody.RecordFieldSet it) =>
			reprRecord!"field-set"(alloc, [reprNat(it.fieldIndex)]),
		(immutable FunBody.ThreadLocal) =>
			reprSym!"thread-local");

immutable(Repr) reprType(ref Alloc alloc, scope ref Ctx ctx, immutable Type a) =>
	a.match!(immutable Repr)(
		(immutable Type.Bogus) =>
			reprSym!"bogus" ,
		(ref immutable TypeParam x) =>
			reprRecord!"type-param"(alloc, [reprSym(x.name)]),
		(ref immutable StructInst x) =>
			reprStructInst(alloc, ctx, x));

immutable(Repr) reprStructInst(ref Alloc alloc, scope ref Ctx ctx, ref immutable StructInst a) =>
	reprRecord(
		a.declAndArgs.decl.name,
		map(alloc, a.declAndArgs.typeArgs, (ref immutable Type it) =>
			reprType(alloc, ctx, it)));

immutable(Repr) reprExpr(ref Alloc alloc, scope ref Ctx ctx, ref immutable Expr a) =>
	a.kind.match!(immutable Repr)(
		(immutable ExprKind.AssertOrForbid x) =>
			reprRecord(alloc, symOfAssertOrForbidKind(x.kind), [
				reprExpr(alloc, ctx, *x.condition),
				reprOpt!(Expr*)(alloc, x.thrown, (ref immutable Expr* thrown) =>
					reprExpr(alloc, ctx, *thrown))]),
		(immutable ExprKind.Bogus) =>
			reprSym!"bogus" ,
		(immutable ExprKind.Call e) =>
			reprRecord!"call"(alloc, [
				reprCalled(alloc, ctx, e.called),
				reprArr(alloc, e.args, (ref immutable Expr arg) =>
					reprExpr(alloc, ctx, arg))]),
		(immutable ExprKind.ClosureGet a) =>
			reprRecord!"closure-get"(alloc, [reprNat(a.closureRef.index)]),
		(immutable ExprKind.ClosureSet a) =>
			reprRecord!"closure-set"(alloc, [reprNat(a.closureRef.index)]),
		(ref immutable ExprKind.Cond e) =>
			reprRecord!"cond"(alloc, [
				reprExpr(alloc, ctx, e.cond),
				reprExpr(alloc, ctx, e.then),
				reprExpr(alloc, ctx, e.else_)]),
		(ref immutable ExprKind.Drop x) =>
			reprRecord!"drop"(alloc, [reprExpr(alloc, ctx, x.arg)]),
		(immutable ExprKind.FunPtr it) =>
			reprRecord!"fun-pointer"(alloc, [
				reprFunInst(alloc, ctx, *it.funInst),
				reprStructInst(alloc, ctx, *it.structInst)]),
		(ref immutable ExprKind.IfOption it) =>
			reprRecord!"if"(alloc, [
				reprExpr(alloc, ctx, it.option),
				reprLocal(alloc, ctx, *it.local),
				reprExpr(alloc, ctx, it.then),
				reprExpr(alloc, ctx, it.else_)]),
		(ref immutable ExprKind.Lambda a) =>
			reprRecord!"lambda"(alloc, [
				reprArr(alloc, a.params, (ref immutable Param it) =>
					reprParam(alloc, ctx, it)),
				reprExpr(alloc, ctx, a.body_),
				reprArr(alloc, a.closure, (ref immutable VariableRef it) =>
					reprSym(debugName(it))),
				reprStructInst(alloc, ctx, *a.funType),
				reprSym(symOfFunKind(a.kind)),
				reprType(alloc, ctx, a.returnType)]),
		(ref immutable ExprKind.Let it) =>
			reprRecord!"let"(alloc, [
				reprLocal(alloc, ctx, *it.local),
				reprExpr(alloc, ctx, it.value),
				reprExpr(alloc, ctx, it.then)]),
		(ref immutable ExprKind.Literal it) =>
			reprRecord!"literal"(alloc, [
				reprStructInst(alloc, ctx, *it.structInst),
				reprOfConstant(alloc, it.value)]),
		(immutable ExprKind.LiteralCString it) =>
			reprRecord!"c-string-lit"(alloc, [reprStr(it.value)]),
		(immutable ExprKind.LiteralSymbol it) =>
			reprRecord!"sym-lit"(alloc, [reprSym(it.value)]),
		(immutable ExprKind.LocalGet it) =>
			reprRecord!"local-get"(alloc, [reprSym(it.local.name)]),
		(ref immutable ExprKind.LocalSet it) =>
			reprRecord!"local-set"(alloc, [reprSym(it.local.name), reprExpr(alloc, ctx, it.value)]),
		(ref immutable ExprKind.Loop x) =>
			reprRecord!"loop"(alloc, [reprExpr(alloc, ctx, x.body_)]),
		(ref immutable ExprKind.LoopBreak x) =>
			reprRecord!"break"(alloc, [reprExpr(alloc, ctx, x.value)]),
		(immutable ExprKind.LoopContinue x) =>
			reprRecord!"continue"(alloc, []),
		(ref immutable ExprKind.LoopUntil x) =>
			reprRecord!"until"(alloc, [
				reprExpr(alloc, ctx, x.condition),
				reprExpr(alloc, ctx, x.body_)]),
		(ref immutable ExprKind.LoopWhile x) =>
			reprRecord!"while"(alloc, [
				reprExpr(alloc, ctx, x.condition),
				reprExpr(alloc, ctx, x.body_)]),
		(ref immutable ExprKind.MatchEnum a) =>
			reprRecord!"match-enum"(alloc, [
				reprExpr(alloc, ctx, a.matched),
				reprArr(alloc, a.cases, (ref immutable Expr case_) =>
					reprExpr(alloc, ctx, case_))]),
		(ref immutable ExprKind.MatchUnion a) =>
			reprRecord!"match-union"(alloc, [
				reprExpr(alloc, ctx, a.matched),
				reprStructInst(alloc, ctx, *a.matchedUnion),
				reprArr(alloc, a.cases, (ref immutable ExprKind.MatchUnion.Case case_) =>
					reprMatchUnionCase(alloc, ctx, case_))]),
		(immutable ExprKind.ParamGet it) =>
			reprRecord!"param-get"(alloc, [reprSym(force(it.param.name))]),
		(ref immutable ExprKind.PtrToField it) =>
			reprRecord!"ptr-to-field"(alloc, [
				reprType(alloc, ctx, it.pointerType),
				reprExpr(alloc, ctx, it.target),
				reprNat(it.fieldIndex)]),
		(immutable ExprKind.PtrToLocal it) =>
			reprRecord!"ptr-to-local"(alloc, [reprSym(it.local.name)]),
		(immutable ExprKind.PtrToParam it) =>
			reprRecord!"ptr-to-param"(alloc, [reprSym(force(it.param.name))]),
		(ref immutable ExprKind.Seq a) =>
			reprRecord!"seq"(alloc, [
				reprExpr(alloc, ctx, a.first),
				reprExpr(alloc, ctx, a.then)]),
		(ref immutable ExprKind.Throw a) =>
			reprRecord!"throw"(alloc, [reprExpr(alloc, ctx, a.thrown)]));

immutable(Sym) symOfFunKind(immutable FunKind a) {
	final switch (a) {
		case FunKind.plain:
			return sym!"plain";
		case FunKind.mut:
			return sym!"mut";
		case FunKind.ref_:
			return sym!"ref";
		case FunKind.pointer:
			return sym!"pointer";
	}
}

immutable(Repr) reprMatchUnionCase(ref Alloc alloc, scope ref Ctx ctx, ref immutable ExprKind.MatchUnion.Case a) =>
	reprRecord!"case"(alloc, [
		reprOpt!(Local*)(alloc, a.local, (ref immutable Local* local) =>
			reprLocal(alloc, ctx, *local)),
		reprExpr(alloc, ctx, a.then)]);

immutable(Repr) reprLocal(ref Alloc alloc, scope ref Ctx ctx, ref immutable Local a) =>
	reprRecord!"local"(alloc, [
		reprFileAndRange(alloc, a.range),
		reprSym(a.name),
		reprType(alloc, ctx, a.type)]);

immutable(Repr) reprCalled(ref Alloc alloc, scope ref Ctx ctx, ref immutable Called a) =>
	a.match!(immutable Repr)(
		(ref immutable FunInst x) =>
			reprFunInst(alloc, ctx, x),
		(ref immutable SpecSig x) =>
			reprSpecSig(alloc, ctx, x));

immutable(Repr) reprFunInst(ref Alloc alloc, scope ref Ctx ctx, ref immutable FunInst a) {
	ArrBuilder!NameAndRepr args;
	add(alloc, args, nameAndRepr!"name"(reprSym(decl(a).name)));
	if (!empty(typeArgs(a)))
		add(alloc, args, nameAndRepr!"type-args"(reprArr(alloc, typeArgs(a), (ref immutable Type it) =>
			reprType(alloc, ctx, it))));
	if (!empty(specImpls(a)))
		add(alloc, args, nameAndRepr!"spec-impls"(reprArr(alloc, specImpls(a), (ref immutable Called it) =>
			reprCalled(alloc, ctx, it))));
	return reprNamedRecord!"fun-inst"(finishArr(alloc, args));
}

immutable(Repr) reprSpecSig(ref Alloc alloc, scope ref Ctx ctx, ref immutable SpecSig a) =>
	reprRecord!"spec-sig"(alloc, [
		reprSym(name(*a.specInst)),
		reprSym(a.sig.name)]);

public immutable(Repr) reprVisibility(immutable Visibility a) =>
	reprSym(symOfVisibility(a));
