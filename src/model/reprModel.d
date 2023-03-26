module model.reprModel;

@safe @nogc pure nothrow:

import model.model :
	body_,
	Called,
	CalledSpecSig,
	decl,
	Destructure,
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
	Params,
	Purity,
	SpecDecl,
	SpecDeclBody,
	SpecDeclSig,
	specImpls,
	SpecInst,
	StructDecl,
	StructInst,
	symOfAssertOrForbidKind,
	symOfFunKind,
	symOfPurity,
	symOfSpecBodyBuiltinKind,
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
import util.col.str : SafeCStr, safeCStrIsEmpty;
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
	addReprCommon(alloc, fields, a.docComment, a.visibility, a.name, a.typeParams);
	if (a.purity != Purity.data)
		add(alloc, fields, nameAndRepr!"purity"(reprSym(symOfPurity(a.purity))));
	if (a.purityIsForced)
		add(alloc, fields, nameAndRepr!"forced"(reprBool(true)));
	return reprNamedRecord!"struct"(finishArr(alloc, fields));
}

Repr reprSpecDecl(ref Alloc alloc, in Ctx ctx, in SpecDecl a) {
	ArrBuilder!NameAndRepr fields;
	add(alloc, fields, nameAndRepr!"range"(reprFileAndRange(alloc, a.range)));
	addReprCommon(alloc, fields, a.docComment, a.visibility, a.name, a.typeParams);
	add(alloc, fields, nameAndRepr!"parents"(reprSpecInsts(alloc, ctx, a.parents)));
	add(alloc, fields, nameAndRepr!"body"(reprSpecDeclBody(alloc, ctx, a.body_)));
	return reprNamedRecord!"spec"(finishArr(alloc, fields));
}

Repr reprSpecDeclBody(ref Alloc alloc, in Ctx ctx, in SpecDeclBody a) =>
	a.matchIn!Repr(
		(in SpecDeclBody.Builtin x) =>
			reprSym(symOfSpecBodyBuiltinKind(x.kind)),
		(in SpecDeclSig[] xs) =>
			reprArr!SpecDeclSig(alloc, xs, (in SpecDeclSig x) =>
				reprSpecDeclSig(alloc, ctx, x)));

Repr reprSpecDeclSig(ref Alloc alloc, in Ctx ctx, in SpecDeclSig a) =>
	reprRecord!"spec-sig"(alloc, [
		reprStr(alloc, a.docComment),
		reprFileAndPos(alloc, a.fileAndPos),
		reprSym(a.name),
		reprType(alloc, ctx, a.returnType),
		reprDestructures(alloc, ctx, a.params)]);

Repr reprFunDecl(ref Alloc alloc, in Ctx ctx, in FunDecl a) {
	ArrBuilder!NameAndRepr fields;
	add(alloc, fields, nameAndRepr!"pos"(reprFileAndPos(alloc, a.fileAndPos)));
	addReprCommon(alloc, fields, a.docComment, a.visibility, a.name, a.typeParams);
	add(alloc, fields, nameAndRepr!"type"(reprType(alloc, ctx, a.returnType)));
	add(alloc, fields, nameAndRepr!"params"(reprParams(alloc, ctx, a.params)));
	addFunFlags(alloc, fields, a.flags);
	if (!empty(a.specs))
		add(alloc, fields, nameAndRepr!"specs"(reprSpecInsts(alloc, ctx, a.specs)));
	add(alloc, fields, nameAndRepr!"body"(reprFunBody(alloc, ctx, a.body_)));
	return reprNamedRecord!"fun"(finishArr(alloc, fields));
}

void addReprCommon(
	ref Alloc alloc,
	scope ref ArrBuilder!NameAndRepr fields,
	in SafeCStr docComment,
	Visibility visibility,
	Sym name,
	in TypeParam[] typeParams,
) {
	if (!safeCStrIsEmpty(docComment))
		add(alloc, fields, nameAndRepr!"doc"(reprStr(docComment)));
	add(alloc, fields, nameAndRepr!"visibility"(reprVisibility(visibility)));
	add(alloc, fields, nameAndRepr!"name"(reprSym(name)));
	if (!empty(typeParams))
		add(alloc, fields, nameAndRepr!"type-params"(reprArr!TypeParam(alloc, typeParams, (in TypeParam x) =>
			reprTypeParam(alloc, x))));
}

void addFunFlags(ref Alloc alloc, scope ref ArrBuilder!NameAndRepr fields, in FunFlags a) {
	void addFlag(string a)() {
		add(alloc, fields, nameAndRepr!a(reprBool(true)));
	}

	if (a.bare)
		addFlag!"bare";
	if (a.summon)
		addFlag!"summon";
	final switch (a.safety) {
		case FunFlags.Safety.safe:
			break;
		case FunFlags.Safety.unsafe:
			addFlag!"unsafe";
			break;
	}
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
		case FunFlags.SpecialBody.generated:
			addFlag!"generated";
			break;
	}
}

Repr reprTypeParam(ref Alloc alloc, in TypeParam a) =>
	reprRecord!"type-param"(alloc, [reprSym(a.name)]);

Repr reprParams(ref Alloc alloc, in Ctx ctx, in Params a) =>
	a.matchIn!Repr(
		(in Destructure[] params) =>
			reprDestructures(alloc, ctx, params),
		(in Params.Varargs v) =>
			reprRecord!"varargs"(alloc, [reprDestructure(alloc, ctx, v.param)]));

Repr reprDestructures(ref Alloc alloc, in Ctx ctx, in Destructure[] a) =>
	reprArr!Destructure(alloc, a, (in Destructure x) =>
		reprDestructure(alloc, ctx, x));

Repr reprSpecInsts(ref Alloc alloc, in Ctx ctx, in immutable SpecInst*[] specs) =>
	reprArr!(SpecInst*)(alloc, specs, (in SpecInst* x) =>
		reprSpecInst(alloc, ctx, *x));

Repr reprSpecInst(ref Alloc alloc, in Ctx ctx, in SpecInst a) =>
	reprRecord(decl(a).name, map(alloc, typeArgs(a), (ref Type it) =>
		reprType(alloc, ctx, it)));

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
			reprRecord!"extern"(alloc, [reprSym(x.libraryName)]),
		(in FunBody.ExpressionBody x) =>
			reprExpr(alloc, ctx, x.expr),
		(in FunBody.FileBytes) =>
			reprSym!"bytes" ,
		(in FlagsFunction it) =>
			reprRecord!"flags-fn"(alloc, [reprSym(flagsFunctionName(it))]),
		(in FunBody.RecordFieldGet it) =>
			reprRecord!"field-get"(alloc, [reprNat(it.fieldIndex)]),
		(in FunBody.RecordFieldPointer it) =>
			reprRecord!"field-ptr"(alloc, [reprNat(it.fieldIndex)]),
		(in FunBody.RecordFieldSet it) =>
			reprRecord!"field-set"(alloc, [reprNat(it.fieldIndex)]),
		(in FunBody.VarGet) =>
			reprSym!"var-get",
		(in FunBody.VarSet) =>
			reprSym!"var-set");

Repr reprType(ref Alloc alloc, in Ctx ctx, in Type a) =>
	a.matchIn!Repr(
		(in Type.Bogus) =>
			reprSym!"bogus" ,
		(in TypeParam x) =>
			reprRecord!"type-param"(alloc, [reprSym(x.name)]),
		(in StructInst x) =>
			reprStructInst(alloc, ctx, x));

Repr reprStructInst(ref Alloc alloc, in Ctx ctx, in StructInst a) =>
	reprRecord(decl(a).name, map(alloc, typeArgs(a), (ref Type it) =>
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
				reprDestructure(alloc, ctx, it.destructure),
				reprExpr(alloc, ctx, it.option),
				reprExpr(alloc, ctx, it.then),
				reprExpr(alloc, ctx, it.else_)]),
		(in ExprKind.Lambda a) =>
			reprRecord!"lambda"(alloc, [
				reprDestructure(alloc, ctx, a.param),
				reprExpr(alloc, ctx, a.body_),
				reprArr!VariableRef(alloc, a.closure, (in VariableRef x) =>
					reprSym(x.name)),
				reprStructInst(alloc, ctx, *a.funType),
				reprSym(symOfFunKind(a.kind)),
				reprType(alloc, ctx, a.returnType)]),
		(in ExprKind.Let it) =>
			reprRecord!"let"(alloc, [
				reprDestructure(alloc, ctx, it.destructure),
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
				reprArr!(ExprKind.MatchUnion.Case)(alloc, a.cases, (in ExprKind.MatchUnion.Case case_) =>
					reprMatchUnionCase(alloc, ctx, case_))]),
		(in ExprKind.PtrToField it) =>
			reprRecord!"ptr-to-field"(alloc, [
				reprType(alloc, ctx, it.pointerType),
				reprExpr(alloc, ctx, it.target),
				reprNat(it.fieldIndex)]),
		(in ExprKind.PtrToLocal it) =>
			reprRecord!"ptr-to-local"(alloc, [reprSym(it.local.name)]),
		(in ExprKind.Seq a) =>
			reprRecord!"seq"(alloc, [
				reprExpr(alloc, ctx, a.first),
				reprExpr(alloc, ctx, a.then)]),
		(in ExprKind.Throw a) =>
			reprRecord!"throw"(alloc, [reprExpr(alloc, ctx, a.thrown)]));

Repr reprDestructure(ref Alloc alloc, in Ctx ctx, in Destructure a) =>
	a.matchIn!Repr(
		(in Destructure.Ignore _) =>
			reprSym!"_",
		(in Local x) =>
			reprLocal(alloc, ctx, x),
		(in Destructure.Split split) =>
			reprDestructureSplit(alloc, ctx, split));

Repr reprDestructureSplit(ref Alloc alloc, in Ctx ctx, in Destructure.Split a) =>
	reprRecord!"split"(alloc, [
		reprStructInst(alloc, ctx, *a.type),
		reprDestructures(alloc, ctx, a.parts)]);

Repr reprMatchUnionCase(ref Alloc alloc, in Ctx ctx, in ExprKind.MatchUnion.Case a) =>
	reprRecord!"case"(alloc, [
		reprDestructure(alloc, ctx, a.destructure),
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
		(in CalledSpecSig x) =>
			reprCalledSpecSig(alloc, ctx, x));

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

Repr reprCalledSpecSig(ref Alloc alloc, in Ctx ctx, in CalledSpecSig a) =>
	reprRecord!"spec-sig"(alloc, [
		reprSym(name(*a.specInst)),
		reprSym(name(a))]);

public Repr reprVisibility(Visibility a) =>
	reprSym(symOfVisibility(a));
